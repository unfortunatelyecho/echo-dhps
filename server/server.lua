local activeHeists = {}
local cooldowns = {}
local playerReputation = {}

-- Initialize database
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS heist_reputation (
            identifier VARCHAR(50) PRIMARY KEY,
            reputation INT DEFAULT 0,
            total_heists INT DEFAULT 0,
            successful_heists INT DEFAULT 0,
            failed_heists INT DEFAULT 0,
            last_heist BIGINT DEFAULT 0
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS heist_cooldowns (
            id INT AUTO_INCREMENT PRIMARY KEY,
            heist_id VARCHAR(50) NOT NULL,
            cooldown_until BIGINT NOT NULL,
            INDEX idx_heist_id (heist_id)
        )
    ]])
    
    if Config.Debug then
        print('^2[Dynamic Heist System]^7 Database tables initialized')
    end
end)

-- Utility Functions
local function GetPlayerReputation(identifier)
    if playerReputation[identifier] then
        return playerReputation[identifier]
    end
    
    local result = MySQL.query.await('SELECT * FROM heist_reputation WHERE identifier = ?', {identifier})
    if result[1] then
        playerReputation[identifier] = result[1].reputation
        return result[1].reputation
    else
        MySQL.insert('INSERT INTO heist_reputation (identifier, reputation) VALUES (?, ?)', {identifier, 0})
        playerReputation[identifier] = 0
        return 0
    end
end

local function UpdateReputation(identifier, amount, success)
    local current = GetPlayerReputation(identifier)
    local new = math.max(0, current + amount)
    playerReputation[identifier] = new
    
    if success then
        MySQL.update('UPDATE heist_reputation SET reputation = ?, successful_heists = successful_heists + 1, total_heists = total_heists + 1, last_heist = ? WHERE identifier = ?', 
            {new, os.time(), identifier})
    else
        MySQL.update('UPDATE heist_reputation SET reputation = ?, failed_heists = failed_heists + 1, total_heists = total_heists + 1, last_heist = ? WHERE identifier = ?', 
            {new, os.time(), identifier})
    end
    
    return new
end

local function GetAvailableHeists(identifier)
    local rep = GetPlayerReputation(identifier)
    local available = {}
    
    for _, level in ipairs(Config.Reputation.levels) do
        if rep >= level.min and rep <= level.max then
            for _, heistId in ipairs(level.unlocks) do
                for _, heist in ipairs(Config.HeistLocations) do
                    if heist.id == heistId then
                        table.insert(available, heist)
                    end
                end
            end
            break
        end
    end
    
    return available
end

local function IsOnCooldown(heistId)
    if cooldowns[heistId] then
        if os.time() < cooldowns[heistId] then
            return true, math.ceil((cooldowns[heistId] - os.time()) / 60)
        else
            cooldowns[heistId] = nil
            MySQL.execute('DELETE FROM heist_cooldowns WHERE heist_id = ?', {heistId})
        end
    end
    return false, 0
end

local function SetCooldown(heistId, duration)
    local cooldownUntil = os.time() + duration
    cooldowns[heistId] = cooldownUntil
    MySQL.insert('INSERT INTO heist_cooldowns (heist_id, cooldown_until) VALUES (?, ?) ON DUPLICATE KEY UPDATE cooldown_until = ?', 
        {heistId, cooldownUntil, cooldownUntil})
end

local function GetPoliceCount()
    local count = 0
    local players = Framework.GetPlayers()
    
    for _, Player in pairs(players) do
        local jobName, onDuty
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            jobName = Player.PlayerData.job.name
            onDuty = Player.PlayerData.job.onduty
        elseif Framework.Type == 'esx' then
            jobName = Player.job.name
            onDuty = true
        end
        
        if jobName == Config.PoliceJobName and onDuty then
            count = count + 1
        end
    end
    
    return count
end

local function GetHeistById(heistId)
    for _, heist in ipairs(Config.HeistLocations) do
        if heist.id == heistId then
            return heist
        end
    end
    return nil
end

local function AlertPolice(coords, heistName)
    local players = Framework.GetPlayers()
    
    for _, Player in pairs(players) do
        local src
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            src = Player.PlayerData.source
        elseif Framework.Type == 'esx' then
            src = Player.source
        end
        
        local jobName = Framework.GetPlayerJob(src)
        if jobName == Config.PoliceJobName then
            TriggerClientEvent('heist-system:client:policeAlert', src, coords, heistName)
        end
    end
end

-- Events
RegisterNetEvent('heist-system:server:openPlanningBoard', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    if not identifier then return end
    
    local reputation = GetPlayerReputation(identifier)
    local availableHeists = GetAvailableHeists(identifier)
    
    -- Get reputation level info
    local repLevel = "Novice Thief"
    for _, level in ipairs(Config.Reputation.levels) do
        if reputation >= level.min and reputation <= level.max then
            repLevel = level.label
            break
        end
    end
    
    TriggerClientEvent('heist-system:client:openPlanningMenu', src, availableHeists, reputation, repLevel)
end)

RegisterNetEvent('heist-system:server:startHeistPlanning', function(heistId, approach)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    if not identifier then return end
    
    local heist = GetHeistById(heistId)
    if not heist then return end
    
    -- Check cooldown
    local onCooldown, timeLeft = IsOnCooldown(heistId)
    if onCooldown then
        Framework.NotifyPlayer(src, string.format(Config.Language["heist_cooldown"], timeLeft), 'error')
        return
    end
    
    -- Check police
    local policeCount = GetPoliceCount()
    if policeCount < Config.MinPolice then
        Framework.NotifyPlayer(src, string.format(Config.Language["not_enough_police"], policeCount, Config.MinPolice), 'error')
        return
    end
    
    -- Check reputation
    local reputation = GetPlayerReputation(identifier)
    local hasAccess = false
    for _, level in ipairs(Config.Reputation.levels) do
        if reputation >= level.min and reputation <= level.max then
            for _, unlocked in ipairs(level.unlocks) do
                if unlocked == heistId then
                    hasAccess = true
                    break
                end
            end
            break
        end
    end
    
    if not hasAccess then
        Framework.NotifyPlayer(src, Config.Language["insufficient_rep"], 'error')
        return
    end
    
    -- Validate approach
    local validApproach = false
    for _, validApp in ipairs(heist.approaches) do
        if validApp == approach then
            validApproach = true
            break
        end
    end
    
    if not validApproach then return end
    
    -- Create heist instance
    local heistInstanceId = #activeHeists + 1
    activeHeists[heistInstanceId] = {
        id = heistInstanceId,
        heistId = heistId,
        heist = heist,
        leader = src,
        crew = {src},
        approach = approach,
        purchasedEquipment = {},
        status = "planning",
        startTime = os.time()
    }
    
    Framework.NotifyPlayer(src, Config.Language["heist_planning_started"], 'success')
    TriggerClientEvent('heist-system:client:heistCreated', src, heistInstanceId, heist, approach)
end)

RegisterNetEvent('heist-system:server:inviteToCrew', function(heistInstanceId, targetId)
    local src = source
    if not activeHeists[heistInstanceId] then return end
    if activeHeists[heistInstanceId].leader ~= src then return end
    
    local heist = activeHeists[heistInstanceId]
    
    -- Check if crew is full
    if #heist.crew >= Config.MaximumCrew then
        Framework.NotifyPlayer(src, Config.Language["crew_full"], 'error')
        return
    end
    
    -- Check if already in crew
    for _, member in ipairs(heist.crew) do
        if member == targetId then
            Framework.NotifyPlayer(src, "Player is already in the crew", 'error')
            return
        end
    end
    
    TriggerClientEvent('heist-system:client:heistInvite', targetId, heistInstanceId, heist.heist.label, src)
    Framework.NotifyPlayer(src, Config.Language["invite_sent"], 'success')
end)

RegisterNetEvent('heist-system:server:acceptInvite', function(heistInstanceId)
    local src = source
    if not activeHeists[heistInstanceId] then return end
    
    local heist = activeHeists[heistInstanceId]
    
    -- Check if crew is full
    if #heist.crew >= Config.MaximumCrew then
        Framework.NotifyPlayer(src, Config.Language["crew_full"], 'error')
        return
    end
    
    -- Check if already in crew
    for _, member in ipairs(heist.crew) do
        if member == src then
            return
        end
    end
    
    table.insert(heist.crew, src)
    
    -- Get player name
    local Player = Framework.GetPlayer(src)
    local playerName = "Unknown"
    if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
        playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    elseif Framework.Type == 'esx' then
        playerName = Player.getName()
    end
    
    Framework.NotifyPlayer(src, Config.Language["joined_crew"], 'success')
    
    -- Notify all crew members
    for _, crewMember in ipairs(heist.crew) do
        if crewMember ~= src then
            Framework.NotifyPlayer(crewMember, string.format(Config.Language["crew_member_joined"], playerName), 'success')
        end
        TriggerClientEvent('heist-system:client:updateCrew', crewMember, heist.crew)
    end
end)

RegisterNetEvent('heist-system:server:purchaseEquipment', function(heistInstanceId, equipmentItem)
    local src = source
    if not activeHeists[heistInstanceId] then return end
    
    local heist = activeHeists[heistInstanceId]
    if heist.leader ~= src then return end
    
    -- Find equipment
    local equipment = nil
    for _, eq in ipairs(heist.heist.equipment) do
        if eq.item == equipmentItem then
            equipment = eq
            break
        end
    end
    
    if not equipment then return end
    
    -- Check if already purchased
    if heist.purchasedEquipment[equipmentItem] then
        Framework.NotifyPlayer(src, "Equipment already purchased", 'error')
        return
    end
    
    -- Check money
    local hasMoney = Framework.GetMoney(src, 'cash') >= equipment.price or 
                     Framework.GetMoney(src, 'bank') >= equipment.price
    
    if not hasMoney then
        Framework.NotifyPlayer(src, Config.Language["not_enough_money"], 'error')
        return
    end
    
    -- Remove money (try cash first, then bank)
    local success = false
    if Framework.GetMoney(src, 'cash') >= equipment.price then
        success = Framework.RemoveMoney(src, 'cash', equipment.price, "heist-equipment")
    else
        success = Framework.RemoveMoney(src, 'bank', equipment.price, "heist-equipment")
    end
    
    if success then
        Framework.AddItem(src, equipment.item, 1)
        heist.purchasedEquipment[equipmentItem] = true
        
        Framework.NotifyPlayer(src, string.format(Config.Language["equipment_purchased"], equipment.label), 'success')
        
        -- Notify item add (framework specific)
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            TriggerClientEvent('inventory:client:ItemBox', src, equipment.item, "add", 1)
        end
    end
end)

RegisterNetEvent('heist-system:server:startHeist', function(heistInstanceId)
    local src = source
    if not activeHeists[heistInstanceId] then return end
    
    local heist = activeHeists[heistInstanceId]
    if heist.leader ~= src then return end
    
    -- Check crew size
    if #heist.crew < heist.heist.requiredCrew then
        Framework.NotifyPlayer(src, string.format(Config.Language["need_more_crew"], heist.heist.requiredCrew), 'error')
        return
    end
    
    -- Check required equipment
    for _, equipment in ipairs(heist.heist.equipment) do
        if equipment.required and not heist.purchasedEquipment[equipment.item] then
            Framework.NotifyPlayer(src, "Missing required equipment: " .. equipment.label, 'error')
            return
        end
    end
    
    -- Set status
    heist.status = "active"
    
    -- Notify all crew members
    for _, crewMember in ipairs(heist.crew) do
        TriggerClientEvent('heist-system:client:startHeist', crewMember, heist)
        Framework.NotifyPlayer(crewMember, Config.Language["heist_started"], 'success')
    end
    
    -- Set cooldown
    SetCooldown(heist.heistId, heist.heist.cooldown)
    
    if Config.Debug then
        print(string.format('^2[Heist System]^7 Heist started: %s with %d crew members', heist.heist.label, #heist.crew))
    end
end)

RegisterNetEvent('heist-system:server:completeHeist', function(heistInstanceId, success)
    local src = source
    if not activeHeists[heistInstanceId] then return end
    
    local heist = activeHeists[heistInstanceId]
    if heist.leader ~= src then return end
    
    -- Calculate cop alert
    local approach = Config.ApproachModifiers[heist.approach]
    local alertChance = heist.heist.copAlertChance + (approach.copAlertModifier or 0)
    
    if math.random(100) <= alertChance then
        AlertPolice(heist.heist.coords, heist.heist.label)
    end
    
    if success then
        -- Calculate rewards with approach modifier
        local rewardMod = approach.rewardModifier or 1.0
        local cashReward = math.random(heist.heist.rewards.min, heist.heist.rewards.max) * rewardMod
        local perPersonCash = math.floor(cashReward / #heist.crew)
        
        -- Distribute rewards
        for _, crewMember in ipairs(heist.crew) do
            local memberIdentifier = Framework.GetIdentifier(crewMember)
            if memberIdentifier then
                -- Give money
                Framework.AddMoney(crewMember, 'cash', perPersonCash, "heist-reward")
                
                -- Give items
                for _, itemReward in ipairs(heist.heist.rewards.items) do
                    if math.random(100) <= itemReward.chance then
                        local amount = math.random(itemReward.min, itemReward.max)
                        Framework.AddItem(crewMember, itemReward.item, amount)
                        
                        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
                            TriggerClientEvent('inventory:client:ItemBox', crewMember, itemReward.item, "add", amount)
                        end
                    end
                end
                
                -- Update reputation
                local repGain = Config.Reputation.gainOnSuccess[heist.heist.difficulty] or 25
                local newRep = UpdateReputation(memberIdentifier, repGain, true)
                
                Framework.NotifyPlayer(crewMember, string.format(Config.Language["heist_success"], perPersonCash), 'success')
                Framework.NotifyPlayer(crewMember, string.format(Config.Language["rep_gained"], repGain, newRep), 'success')
                TriggerClientEvent('heist-system:client:updateReputation', crewMember, newRep)
            end
        end
        
        if Config.Debug then
            print(string.format('^2[Heist System]^7 Heist completed successfully: %s - Payout: $%d', heist.heist.label, cashReward))
        end
    else
        -- Failed heist - lose reputation
        for _, crewMember in ipairs(heist.crew) do
            local memberIdentifier = Framework.GetIdentifier(crewMember)
            if memberIdentifier then
                local repLoss = Config.Reputation.loseOnFail[heist.heist.difficulty] or 10
                local newRep = UpdateReputation(memberIdentifier, -repLoss, false)
                
                Framework.NotifyPlayer(crewMember, Config.Language["heist_failed"], 'error')
                Framework.NotifyPlayer(crewMember, string.format(Config.Language["rep_lost"], repLoss, newRep), 'error')
                TriggerClientEvent('heist-system:client:updateReputation', crewMember, newRep)
            end
        end
        
        if Config.Debug then
            print(string.format('^1[Heist System]^7 Heist failed: %s', heist.heist.label))
        end
    end
    
    -- Clean up
    activeHeists[heistInstanceId] = nil
end)

RegisterNetEvent('heist-system:server:cancelHeist', function(heistInstanceId)
    local src = source
    if not activeHeists[heistInstanceId] then return end
    
    local heist = activeHeists[heistInstanceId]
    if heist.leader ~= src then return end
    
    -- Notify all crew members
    for _, crewMember in ipairs(heist.crew) do
        Framework.NotifyPlayer(crewMember, "Heist has been cancelled", 'error')
        TriggerClientEvent('heist-system:client:heistCancelled', crewMember)
    end
    
    activeHeists[heistInstanceId] = nil
end)

-- Callbacks
Framework.CreateCallback('heist-system:server:getReputation', function(source, cb)
    local identifier = Framework.GetIdentifier(source)
    if not identifier then 
        cb(0) 
        return 
    end
    
    local rep = GetPlayerReputation(identifier)
    cb(rep)
end)

Framework.CreateCallback('heist-system:server:getHeistData', function(source, cb, heistInstanceId)
    if activeHeists[heistInstanceId] then
        cb(activeHeists[heistInstanceId])
    else
        cb(nil)
    end
end)

Framework.CreateCallback('heist-system:server:canStartHeist', function(source, cb, heistId)
    local identifier = Framework.GetIdentifier(source)
    if not identifier then 
        cb(false, "Invalid player") 
        return 
    end
    
    local heist = GetHeistById(heistId)
    if not heist then 
        cb(false, "Invalid heist") 
        return 
    end
    
    -- Check cooldown
    local onCooldown, timeLeft = IsOnCooldown(heistId)
    if onCooldown then
        cb(false, string.format("Cooldown: %d minutes remaining", timeLeft))
        return
    end
    
    -- Check police
    local policeCount = GetPoliceCount()
    if policeCount < Config.MinPolice then
        cb(false, string.format("Not enough police (%d/%d)", policeCount, Config.MinPolice))
        return
    end
    
    cb(true, "OK")
end)

-- Clean up disconnected players from crews
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    for heistId, heist in pairs(activeHeists) do
        for i, member in ipairs(heist.crew) do
            if member == src then
                table.remove(heist.crew, i)
                
                -- Notify remaining crew
                for _, remainingMember in ipairs(heist.crew) do
                    Framework.NotifyPlayer(remainingMember, "A crew member has disconnected", 'error')
                    TriggerClientEvent('heist-system:client:updateCrew', remainingMember, heist.crew)
                end
                
                -- Cancel heist if leader left
                if heist.leader == src then
                    for _, crewMember in ipairs(heist.crew) do
                        Framework.NotifyPlayer(crewMember, "Heist cancelled - Leader disconnected", 'error')
                        TriggerClientEvent('heist-system:client:heistCancelled', crewMember)
                    end
                    activeHeists[heistId] = nil
                end
                
                break
            end
        end
    end
end)

-- Load cooldowns on resource start
CreateThread(function()
    local result = MySQL.query.await('SELECT * FROM heist_cooldowns')
    if result then
        for _, data in ipairs(result) do
            if data.cooldown_until > os.time() then
                cooldowns[data.heist_id] = data.cooldown_until
            else
                MySQL.execute('DELETE FROM heist_cooldowns WHERE id = ?', {data.id})
            end
        end
        
        if Config.Debug then
            print(string.format('^2[Heist System]^7 Loaded %d active cooldowns', #result))
        end
    end
end)