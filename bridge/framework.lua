Framework = {}
Framework.Type = nil

-- Auto-detect framework
local function DetectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    
    if GetResourceState('qbx_core') == 'started' or GetResourceState('qbox_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qbcore'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    end
    
    return 'qbcore' -- Default fallback
end

Framework.Type = DetectFramework()

if Framework.Type == 'qbcore' then
    Framework.Core = exports['qb-core']:GetCoreObject()
elseif Framework.Type == 'qbx' then
    Framework.Core = exports.qbx_core
elseif Framework.Type == 'esx' then
    Framework.Core = exports['es_extended']:getSharedObject()
end

-- Print framework detection
if Config.Debug then
    print('^2[Dynamic Heist System]^7 Framework detected: ^3' .. Framework.Type .. '^7')
end

-- CLIENT SIDE FUNCTIONS
if IsDuplicityVersion() == 0 then -- Client side
    
    -- Get Player Data
    function Framework.GetPlayerData()
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Framework.Core.Functions.GetPlayerData()
        elseif Framework.Type == 'esx' then
            return Framework.Core.GetPlayerData()
        end
    end
    
    -- Show Notification
    function Framework.Notify(message, type, duration)
        duration = duration or Config.NotificationDuration
        
        if Config.UseOxLib then
            lib.notify({
                title = 'Heist System',
                description = message,
                type = type or 'inform',
                duration = duration
            })
        else
            if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
                Framework.Core.Functions.Notify(message, type, duration)
            elseif Framework.Type == 'esx' then
                Framework.Core.ShowNotification(message)
            end
        end
    end
    
    -- Progress Bar
    function Framework.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
        if Config.UseOxLib then
            if lib.progressBar({
                duration = duration,
                label = label,
                useWhileDead = useWhileDead,
                canCancel = canCancel,
                disable = disableControls,
                anim = animation,
                prop = prop,
            }) then
                if onFinish then onFinish() end
            else
                if onCancel then onCancel() end
            end
        else
            if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
                Framework.Core.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
            elseif Framework.Type == 'esx' then
                Framework.Core.Progressbar(label, duration, {
                    FreezePlayer = disableControls and disableControls.disableMovement or false,
                    animation = animation,
                    onFinish = onFinish,
                    onCancel = onCancel
                })
            end
        end
    end
    
    -- Trigger Callback
    function Framework.TriggerCallback(name, cb, ...)
        if Framework.Type == 'qbcore' then
            Framework.Core.Functions.TriggerCallback(name, cb, ...)
        elseif Framework.Type == 'qbx' then
            Framework.Core.Functions.TriggerCallback(name, function(result)
                cb(result)
            end, ...)
        elseif Framework.Type == 'esx' then
            Framework.Core.TriggerServerCallback(name, cb, ...)
        end
    end
    
    -- Get Closest Player
    function Framework.GetClosestPlayer()
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Framework.Core.Functions.GetClosestPlayer()
        elseif Framework.Type == 'esx' then
            return Framework.Core.Game.GetClosestPlayer()
        end
    end
    
    -- Draw 3D Text
    function Framework.Draw3DText(coords, text)
        local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
        local pCoords = GetEntityCoords(PlayerPedId())
        local distance = #(pCoords - coords)
        
        local scale = (1 / distance) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        
        if onScreen then
            SetTextScale(0.0 * scale, 0.55 * scale)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 215)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(1)
            AddTextComponentString(text)
            DrawText(x, y)
        end
    end

-- SERVER SIDE FUNCTIONS
else -- Server side
    
    -- Get Player
    function Framework.GetPlayer(source)
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Framework.Core.Functions.GetPlayer(source)
        elseif Framework.Type == 'esx' then
            return Framework.Core.GetPlayerFromId(source)
        end
    end
    
    -- Get Player Identifier
    function Framework.GetIdentifier(source)
        local Player = Framework.GetPlayer(source)
        if not Player then return nil end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.PlayerData.citizenid
        elseif Framework.Type == 'esx' then
            return Player.identifier
        end
    end
    
    -- Get All Players
    function Framework.GetPlayers()
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Framework.Core.Functions.GetQBPlayers()
        elseif Framework.Type == 'esx' then
            return Framework.Core.GetExtendedPlayers()
        end
    end
    
    -- Get Player Job
    function Framework.GetPlayerJob(source)
        local Player = Framework.GetPlayer(source)
        if not Player then return nil end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.PlayerData.job.name, Player.PlayerData.job.onduty
        elseif Framework.Type == 'esx' then
            return Player.job.name, true
        end
    end
    
    -- Add Money
    function Framework.AddMoney(source, account, amount, reason)
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.Functions.AddMoney(account, amount, reason)
        elseif Framework.Type == 'esx' then
            Player.addAccountMoney(account, amount)
            return true
        end
    end
    
    -- Remove Money
    function Framework.RemoveMoney(source, account, amount, reason)
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.Functions.RemoveMoney(account, amount, reason)
        elseif Framework.Type == 'esx' then
            Player.removeAccountMoney(account, amount)
            return true
        end
    end
    
    -- Get Money
    function Framework.GetMoney(source, account)
        local Player = Framework.GetPlayer(source)
        if not Player then return 0 end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.Functions.GetMoney(account)
        elseif Framework.Type == 'esx' then
            return Player.getAccount(account).money
        end
    end
    
    -- Add Item
    function Framework.AddItem(source, item, amount, slot, info)
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.Functions.AddItem(item, amount, slot, info)
        elseif Framework.Type == 'esx' then
            Player.addInventoryItem(item, amount)
            return true
        end
    end
    
    -- Remove Item
    function Framework.RemoveItem(source, item, amount, slot)
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            return Player.Functions.RemoveItem(item, amount, slot)
        elseif Framework.Type == 'esx' then
            Player.removeInventoryItem(item, amount)
            return true
        end
    end
    
    -- Has Item
    function Framework.HasItem(source, item, amount)
        local Player = Framework.GetPlayer(source)
        if not Player then return false end
        
        amount = amount or 1
        
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            local itemData = Player.Functions.GetItemByName(item)
            return itemData and itemData.amount >= amount
        elseif Framework.Type == 'esx' then
            local itemData = Player.getInventoryItem(item)
            return itemData and itemData.count >= amount
        end
    end
    
    -- Create Callback
    function Framework.CreateCallback(name, cb)
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            Framework.Core.Functions.CreateCallback(name, cb)
        elseif Framework.Type == 'esx' then
            Framework.Core.RegisterServerCallback(name, cb)
        end
    end
    
    -- Show Notification (Server -> Client)
    function Framework.NotifyPlayer(source, message, type, duration)
        if Framework.Type == 'qbcore' or Framework.Type == 'qbx' then
            TriggerClientEvent('QBCore:Notify', source, message, type, duration)
        elseif Framework.Type == 'esx' then
            TriggerClientEvent('esx:showNotification', source, message)
        end
    end
end

return Framework