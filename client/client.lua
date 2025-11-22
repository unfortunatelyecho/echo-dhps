local currentHeist = nil
local inHeist = false
local playerReputation = 0
local currentCrewMembers = {}

-- Initialize
CreateThread(function()
    Wait(1000) -- Wait for framework to load
    
    -- Create blips for planning boards
    for _, board in ipairs(Config.PlanningBoards) do
        if board.blip.enabled then
            local blip = AddBlipForCoord(board.coords.x, board.coords.y, board.coords.z)
            SetBlipSprite(blip, board.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, board.blip.scale)
            SetBlipColour(blip, board.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(board.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
    
    -- Setup interactions
    if Config.UseTarget then
        SetupTargetInteractions()
    else
        SetupDrawTextInteractions()
    end
    
    -- Get initial reputation
    Framework.TriggerCallback('heist-system:server:getReputation', function(rep)
        playerReputation = rep
    end)
    
    if Config.Debug then
        print('^2[Heist System]^7 Client initialized')
    end
end)

-- Setup Target Interactions
function SetupTargetInteractions()
    for i, board in ipairs(Config.PlanningBoards) do
        if GetResourceState('qb-target') == 'started' then
            exports['qb-target']:AddBoxZone("heistboard_" .. i, board.coords, 1.5, 1.5, {
                name = "heistboard_" .. i,
                heading = board.heading,
                debugPoly = Config.Debug,
                minZ = board.coords.z - 1,
                maxZ = board.coords.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "heist-system:client:openBoard",
                        icon = "fas fa-mask",
                        label = Config.Language["open_board"],
                    },
                },
                distance = 2.5
            })
        elseif GetResourceState('ox_target') == 'started' then
            exports.ox_target:addBoxZone({
                coords = board.coords,
                size = vec3(1.5, 1.5, 1.5),
                rotation = board.heading,
                debug = Config.Debug,
                options = {
                    {
                        name = 'heist_planning_board',
                        event = 'heist-system:client:openBoard',
                        icon = 'fas fa-mask',
                        label = Config.Language["open_board"],
                    }
                }
            })
        end
    end
end

-- Setup Draw Text Interactions
function SetupDrawTextInteractions()
    CreateThread(function()
        while true do
            local sleep = 1000
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            
            for _, board in ipairs(Config.PlanningBoards) do
                local dist = #(pos - board.coords)
                if dist < 10.0 then
                    sleep = 0
                    if dist < 2.5 then
                        Framework.Draw3DText(board.coords, Config.Language["press_to_interact"])
                        if IsControlJustReleased(0, 38) then -- E key
                            TriggerEvent('heist-system:client:openBoard')
                        end
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

-- Open Planning Board
RegisterNetEvent('heist-system:client:openBoard', function()
    TriggerServerEvent('heist-system:server:openPlanningBoard')
end)

-- Open Planning Menu
RegisterNetEvent('heist-system:client:openPlanningMenu', function(availableHeists, reputation, repLevel)
    playerReputation = reputation
    
    if Config.UseOxLib then
        OpenOxLibPlanningMenu(availableHeists, reputation, repLevel)
    else
        OpenQBMenuPlanningMenu(availableHeists, reputation, repLevel)
    end
end)

-- OxLib Menu System
function OpenOxLibPlanningMenu(availableHeists, reputation, repLevel)
    local options = {}
    
    for _, heist in ipairs(availableHeists) do
        local difficultyStars = "⭐"
        if heist.difficulty == "medium" then difficultyStars = "⭐⭐"
        elseif heist.difficulty == "hard" then difficultyStars = "⭐⭐⭐"
        elseif heist.difficulty == "extreme" then difficultyStars = "⭐⭐⭐⭐" end
        
        table.insert(options, {
            title = heist.label,
            description = string.format("%s | Crew: %d+ | Payout: $%d-$%d", 
                difficultyStars, heist.requiredCrew, heist.rewards.min, heist.rewards.max),
            icon = 'fa-solid fa-building-columns',
            onSelect = function()
                OpenHeistApproachMenu(heist)
            end
        })
    end
    
    lib.registerContext({
        id = 'heist_planning_menu',
        title = '🎭 ' .. Config.Language["planning_board"],
        description = string.format(Config.Language["reputation_display"], repLevel, reputation),
        options = options
    })
    
    lib.showContext('heist_planning_menu')
end

-- QB Menu System
function OpenQBMenuPlanningMenu(availableHeists, reputation, repLevel)
    local menuItems = {}
    
    table.insert(menuItems, {
        header = "🎭 " .. Config.Language["planning_board"],
        txt = string.format(Config.Language["reputation_display"], repLevel, reputation),
        isMenuHeader = true
    })
    
    for _, heist in ipairs(availableHeists) do
        local difficultyStars = "⭐"
        if heist.difficulty == "medium" then difficultyStars = "⭐⭐"
        elseif heist.difficulty == "hard" then difficultyStars = "⭐⭐⭐"
        elseif heist.difficulty == "extreme" then difficultyStars = "⭐⭐⭐⭐" end
        
        table.insert(menuItems, {
            header = heist.label,
            txt = string.format("%s | Crew: %d+ | Payout: $%d-$%d", 
                difficultyStars, heist.requiredCrew, heist.rewards.min, heist.rewards.max),
            params = {
                event = "heist-system:client:selectHeist",
                args = {heist = heist}
            }
        })
    end
    
    table.insert(menuItems, {
        header = Config.Language["close"],
        params = {event = "qb-menu:client:closeMenu"}
    })
    
    exports['qb-menu']:openMenu(menuItems)
end

-- Select Heist
RegisterNetEvent('heist-system:client:selectHeist', function(data)
    OpenHeistApproachMenu(data.heist)
end)

-- Heist Approach Menu
function OpenHeistApproachMenu(heist)
    if Config.UseOxLib then
        local options = {}
        
        for _, approach in ipairs(heist.approaches) do
            local approachData = Config.ApproachModifiers[approach]
            table.insert(options, {
                title = approachData.icon .. " " .. approachData.label,
                description = approachData.description,
                icon = 'fa-solid fa-chess-knight',
                onSelect = function()
                    OpenEquipmentMenu(heist, approach)
                end
            })
        end
        
        lib.registerContext({
            id = 'heist_approach_menu',
            title = heist.label,
            description = Config.Language["select_approach"],
            menu = 'heist_planning_menu',
            options = options
        })
        
        lib.showContext('heist_approach_menu')
    else
        local menuItems = {}
        
        table.insert(menuItems, {
            header = Config.Language["back"],
            params = {event = "heist-system:client:openBoard"}
        })
        
        table.insert(menuItems, {
            header = "📋 " .. heist.label,
            txt = Config.Language["select_approach"],
            isMenuHeader = true
        })
        
        for _, approach in ipairs(heist.approaches) do
            local approachData = Config.ApproachModifiers[approach]
            table.insert(menuItems, {
                header = approachData.icon .. " " .. approachData.label,
                txt = approachData.description,
                params = {
                    event = "heist-system:client:openEquipmentMenu",
                    args = {heist = heist, approach = approach}
                }
            })
        end
        
        exports['qb-menu']:openMenu(menuItems)
    end
end

-- Open Equipment Menu
RegisterNetEvent('heist-system:client:openEquipmentMenu', function(data)
    OpenEquipmentMenu(data.heist, data.approach)
end)

function OpenEquipmentMenu(heist, approach)
    if Config.UseOxLib then
        local options = {}
        
        -- Equipment options
        for _, equipment in ipairs(heist.equipment) do
            local required = equipment.required and " (REQUIRED)" or " (Optional)"
            table.insert(options, {
                title = equipment.label .. required,
                description = "$" .. equipment.price,
                icon = 'fa-solid fa-shopping-cart',
                disabled = currentHeist == nil,
                onSelect = function()
                    if currentHeist then
                        TriggerServerEvent('heist-system:server:purchaseEquipment', currentHeist.id, equipment.item)
                    end
                end
            })
        end
        
        -- Start planning option
        table.insert(options, {
            title = "✅ " .. Config.Language["confirm"],
            description = "Begin heist preparation",
            icon = 'fa-solid fa-check',
            onSelect = function()
                TriggerServerEvent('heist-system:server:startHeistPlanning', heist.id, approach)
            end
        })
        
        lib.registerContext({
            id = 'heist_equipment_menu',
            title = Config.Language["equipment_shop"],
            description = heist.label,
            menu = 'heist_approach_menu',
            options = options
        })
        
        lib.showContext('heist_equipment_menu')
    else
        local menuItems = {}
        
        table.insert(menuItems, {
            header = Config.Language["back"],
            params = {
                event = "heist-system:client:selectHeist",
                args = {heist = heist}
            }
        })
        
        table.insert(menuItems, {
            header = "🛠 " .. Config.Language["equipment_shop"],
            txt = heist.label,
            isMenuHeader = true
        })
        
        for _, equipment in ipairs(heist.equipment) do
            local required = equipment.required and " (REQUIRED)" or " (Optional)"
            table.insert(menuItems, {
                header = equipment.label .. required,
                txt = "Price: $" .. equipment.price,
                params = {
                    event = "heist-system:client:buyEquipment",
                    args = {heist = heist, approach = approach, equipment = equipment}
                }
            })
        end
        
        table.insert(menuItems, {
            header = "✅ " .. Config.Language["confirm"],
            txt = "Begin heist preparation",
            params = {
                event = "heist-system:client:beginPlanning",
                args = {heist = heist, approach = approach}
            }
        })
        
        exports['qb-menu']:openMenu(menuItems)
    end
end

-- Buy Equipment
RegisterNetEvent('heist-system:client:buyEquipment', function(data)
    if currentHeist then
        TriggerServerEvent('heist-system:server:purchaseEquipment', currentHeist.id, data.equipment.item)
    else
        Framework.Notify("Start planning first!", 'error')
    end
end)

-- Begin Planning
RegisterNetEvent('heist-system:client:beginPlanning', function(data)
    TriggerServerEvent('heist-system:server:startHeistPlanning', data.heist.id, data.approach)
end)

-- Heist Created
RegisterNetEvent('heist-system:client:heistCreated', function(heistId, heist, approach)
    currentHeist = {
        id = heistId,
        heist = heist,
        approach = approach
    }
    
    Framework.Notify(Config.Language["heist_planning_started"], 'success')
    OpenCrewMenu()
end)

-- Crew Management Menu
function OpenCrewMenu()
    if not currentHeist then return end
    
    if Config.UseOxLib then
        lib.registerContext({
            id = 'crew_management_menu',
            title = '👥 ' .. Config.Language["crew_management"],
            description = string.format("Crew Members: %d/%d", #currentCrewMembers, Config.MaximumCrew),
            options = {
                {
                    title = Config.Language["invite_player"],
                    description = "Invite nearby players to your crew",
                    icon = 'fa-solid fa-user-plus',
                    onSelect = function()
                        InviteNearbyPlayer()
                    end
                },
                {
                    title = Config.Language["start_heist"],
                    description = "Begin the heist with current crew",
                    icon = 'fa-solid fa-flag-checkered',
                    onSelect = function()
                        TriggerServerEvent('heist-system:server:startHeist', currentHeist.id)
                    end
                },
                {
                    title = Config.Language["cancel_heist"],
                    description = "Cancel heist planning",
                    icon = 'fa-solid fa-times',
                    onSelect = function()
                        TriggerServerEvent('heist-system:server:cancelHeist', currentHeist.id)
                        currentHeist = nil
                    end
                }
            }
        })
        
        lib.showContext('crew_management_menu')
    else
        local menuItems = {}
        
        table.insert(menuItems, {
            header = "👥 " .. Config.Language["crew_management"],
            txt = string.format("Crew Members: %d/%d", #currentCrewMembers, Config.MaximumCrew),
            isMenuHeader = true
        })
        
        table.insert(menuItems, {
            header = Config.Language["invite_player"],
            txt = "Invite nearby players to your crew",
            params = {event = "heist-system:client:invitePlayer"}
        })
        
        table.insert(menuItems, {
            header = Config.Language["start_heist"],
            txt = "Begin the heist with current crew",
            params = {event = "heist-system:client:executeHeist"}
        })
        
        table.insert(menuItems, {
            header = Config.Language["cancel_heist"],
            txt = "Cancel heist planning",
            params = {event = "heist-system:client:cancelHeist"}
        })
        
        exports['qb-menu']:openMenu(menuItems)
    end
end

-- Invite Player
RegisterNetEvent('heist-system:client:invitePlayer', function()
    InviteNearbyPlayer()
end)

function InviteNearbyPlayer()
    local player, distance = Framework.GetClosestPlayer()
    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent('heist-system:server:inviteToCrew', currentHeist.id, playerId)
    else
        Framework.Notify(Config.Language["no_player_nearby"], 'error')
    end
end

-- Heist Invite
RegisterNetEvent('heist-system:client:heistInvite', function(heistId, heistName, leaderId)
    if Config.UseOxLib then
        local alert = lib.alertDialog({
            header = '🎭 Heist Invitation',
            content = 'You have been invited to: ' .. heistName,
            centered = true,
            cancel = true,
            labels = {
                confirm = 'Accept',
                cancel = 'Decline'
            }
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('heist-system:server:acceptInvite', heistId)
        end
    else
        -- Use QB-Core's input system or standard
        local dialog = exports['qb-input']:ShowInput({
            header = "🎭 Heist Invitation",
            submitText = "Accept",
            inputs = {
                {
                    text = "You've been invited to: " .. heistName,
                    name = "confirm",
                    type = "text",
                    isRequired = false,
                }
            }
        })
        
        if dialog then
            TriggerServerEvent('heist-system:server:acceptInvite', heistId)
        end
    end
end)

-- Update Crew
RegisterNetEvent('heist-system:client:updateCrew', function(crew)
    currentCrewMembers = crew
end)

-- Execute Heist
RegisterNetEvent('heist-system:client:executeHeist', function()
    if currentHeist then
        TriggerServerEvent('heist-system:server:startHeist', currentHeist.id)
    end
end)

-- Cancel Heist
RegisterNetEvent('heist-system:client:cancelHeist', function()
    if currentHeist then
        TriggerServerEvent('heist-system:server:cancelHeist', currentHeist.id)
        currentHeist = nil
    end
end)

-- Heist Cancelled
RegisterNetEvent('heist-system:client:heistCancelled', function()
    currentHeist = nil
    inHeist = false
    currentCrewMembers = {}
end)

-- Start Heist
RegisterNetEvent('heist-system:client:startHeist', function(heistData)
    inHeist = true
    currentHeist = heistData
    
    Framework.Notify(Config.Language["heist_started"], 'success')
    
    -- Set GPS waypoint
    SetNewWaypoint(heistData.heist.coords.x, heistData.heist.coords.y)
    
    -- Create heist blip
    local blip = AddBlipForCoord(heistData.heist.coords.x, heistData.heist.coords.y, heistData.heist.coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Heist Location")
    EndTextCommandSetBlipName(blip)
    
    -- Heist location thread
    CreateThread(function()
        while inHeist do
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local dist = #(pos - heistData.heist.coords)
            
            if dist < 100.0 then
                DrawMarker(1, heistData.heist.coords.x, heistData.heist.coords.y, heistData.heist.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 255, 0, 0, 150, false, true, 2, false, nil, nil, false)
                
                if dist < 3.0 then
                    Framework.Draw3DText(heistData.heist.coords, "[E] Start Heist")
                    if IsControlJustReleased(0, 38) then
                        StartHeistActivity(heistData)
                        RemoveBlip(blip)
                        break
                    end
                end
            end
            
            Wait(0)
        end
    end)
end)

-- Start Heist Activity
function StartHeistActivity(heistData)
    local difficulty = heistData.heist.difficulty
    local approach = Config.ApproachModifiers[heistData.approach]
    
    -- Example minigame sequence
    Framework.Notify("Starting " .. approach.label .. "...", 'primary')
    
    -- Step 1: Hacking
    local hackSuccess = PerformHackMinigame(difficulty)
    if not hackSuccess then
        Framework.Notify("Hacking failed!", 'error')
        TriggerServerEvent('heist-system:server:completeHeist', currentHeist.id, false)
        inHeist = false
        currentHeist = nil
        return
    end
    
    Wait(1000)
    
    -- Step 2: Drilling/Thermite
    local drillSuccess = PerformDrillMinigame(difficulty, heistData.heist.drillTime)
    if not drillSuccess then
        Framework.Notify("Breaching failed!", 'error')
        TriggerServerEvent('heist-system:server:completeHeist', currentHeist.id, false)
        inHeist = false
        currentHeist = nil
        return
    end
    
    Wait(1000)
    
    -- Step 3: Loot Collection
    local lootSuccess = PerformLootCollection(heistData.heist.grabTime or 60)
    if not lootSuccess then
        Framework.Notify("Looting interrupted!", 'error')
        TriggerServerEvent('heist-system:server:completeHeist', currentHeist.id, false)
        inHeist = false
        currentHeist = nil
        return
    end
    
    -- Success!
    TriggerServerEvent('heist-system:server:completeHeist', currentHeist.id, true)
    inHeist = false
    currentHeist = nil
end

-- Hack Minigame
function PerformHackMinigame(difficulty)
    Framework.Notify("Hacking security system...", 'primary')
    
    if Config.UseOxLib then
        local settings = Config.Minigames.hack.difficulty[difficulty]
        local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1.5}, 'hard'}, {'w', 'a', 's', 'd'})
        return success
    else
        -- Fallback to progress bar
        local success = true
        Framework.Progressbar("hacking", Config.Language["hacking_system"], 30000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "anim@heists@prison_heistig1_p1_guard_checks_bus",
            anim = "loop",
            flags = 49,
        }, {}, {}, function()
            success = true
        end, function()
            success = false
        end)
        
        Wait(30000)
        return success
    end
end

-- Drill Minigame
function PerformDrillMinigame(difficulty, duration)
    Framework.Notify("Drilling vault...", 'primary')
    
    local success = true
    local settings = Config.Minigames.drill.difficulty[difficulty]
    
    Framework.Progressbar("drilling", Config.Language["drilling_vault"], settings.duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "anim@heists@fleeca_bank@drilling",
        anim = "drill_straight_idle",
        flags = 49,
    }, {}, {}, function()
        success = true
    end, function()
        success = false
    end)
    
    Wait(settings.duration)
    return success
end

-- Loot Collection
function PerformLootCollection(duration)
    Framework.Notify("Collecting loot...", 'primary')
    
    local success = true
    local durationMs = (duration or 60) * 1000
    
    Framework.Progressbar("looting", Config.Language["grabbing_loot"], durationMs, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "anim@heists@ornate_bank@grab_cash",
        anim = "grab",
        flags = 49,
    }, {}, {}, function()
        success = true
    end, function()
        success = false
    end)
    
    Wait(durationMs)
    return success
end

-- Police Alert
RegisterNetEvent('heist-system:client:policeAlert', function(coords, heistName)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    Framework.Notify(string.format(Config.Language["police_alert_message"], heistName), 'police', 10000)
    
    -- Create fading blip
    local alpha = 300
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 2.0)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, alpha)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("🚨 " .. heistName)
    EndTextCommandSetBlipName(blip)
    
    -- Fade out
    CreateThread(function()
        while alpha > 0 do
            Wait(500)
            alpha = alpha - 15
            SetBlipAlpha(blip, alpha)
        end
        RemoveBlip(blip)
    end)
end)

-- Update Reputation
RegisterNetEvent('heist-system:client:updateReputation', function(newRep)
    playerReputation = newRep
end)