local resourceName = 'pl_fraud'
lib.versionCheck('pulsepk/pl_fraud')
lib.locale()
local minigameSuccess = {}
local recentRequests = {}

if GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Register item use events
local function RegisterItems()
    if GetResourceState('es_extended') == 'started' then
        ESX.RegisterUsableItem(Config.Items.laptop, function(source)
            local player = getPlayer(source)
            TriggerClientEvent('pl_fraud:client:placeItem', source, 'laptop')
            RemoveItem(player, 'laptop', 1)
        end)
        ESX.RegisterUsableItem(Config.Items.printer, function(source)
            local player = getPlayer(source)
            TriggerClientEvent('pl_fraud:client:placeItem', source, 'printer')
            RemoveItem(player, 'printer', 1)
        end)
        ESX.RegisterUsableItem(Config.Items.generator, function(source)
            local player = getPlayer(source)
            TriggerClientEvent('pl_fraud:client:placeItem', source, 'generator')
            RemoveItem(player, 'generator', 1)
        end)
    elseif GetResourceState('qb-core') == 'started' then
        QBCore.Functions.CreateUseableItem(Config.Items.laptop, function(source, item)
            local player = getPlayer(source)
            if lib.checkDependency('qb-inventory', '2.0.0') then
                if not exports['qb-inventory']:RemoveItem(source, item.name, 1, item.slot) then return end
                TriggerClientEvent('pl_fraud:client:placeItem', source, 'laptop')
            else
                player.Functions.RemoveItem(item.name, 1)
                TriggerClientEvent('pl_fraud:client:placeItem', source, 'laptop')
            end
        end)
        QBCore.Functions.CreateUseableItem(Config.Items.printer, function(source, item)
            local player = getPlayer(source)
            if lib.checkDependency('qb-inventory', '2.0.0') then
                if not exports['qb-inventory']:RemoveItem(source, item.name, 1, item.slot) then return end
                TriggerClientEvent('pl_fraud:client:placeItem', source, 'printer')
            else
                player.Functions.RemoveItem(item.name, 1)
                TriggerClientEvent('pl_fraud:client:placeItem', source, 'printer')
            end
        end)
        QBCore.Functions.CreateUseableItem(Config.Items.generator, function(source, item)
            local player = getPlayer(source)
            if lib.checkDependency('qb-inventory', '2.0.0') then
                if not exports['qb-inventory']:RemoveItem(source, item.name, 1, item.slot) then return end
                TriggerClientEvent('pl_fraud:client:placeItem', source, 'generator')
            else
                player.Functions.RemoveItem(item.name, 1)
                TriggerClientEvent('pl_fraud:client:placeItem', source, 'generator')
            end
        end)
    end
end

RegisterNetEvent('pl_fraud:server:removeFuelCan')
AddEventHandler('pl_fraud:server:removeFuelCan', function(entity)
    local src = source
    
    if HasItem(src, Config.Items.fuelCan) then
        local player = getPlayer(src)
        if RemoveItem(player, Config.Items.fuelCan,1) then
            local fuelAmount = Config.RequiredFuel * 1.0
            TriggerClientEvent('pl_fraud:client:fuelAdded', src, fuelAmount,entity)
        end
    else
        if src then
            TriggerClientEvent("pl_fraud:notification", src, locale("no_fuel_can"), "error")
        end
    end
end)

RegisterNetEvent("pl_fraud:server:minigameResult", function(success)
    local src = source

    if success then
        minigameSuccess[src] = true
        SetTimeout(15000, function()
            minigameSuccess[src] = nil
        end)
    else
        minigameSuccess[src] = nil
    end
end)


RegisterNetEvent('pl_fraud:server:giveCloneCard', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end
    if not minigameSuccess[src] then
        print(("[SECURITY] Player %s tried to clone card without valid minigame result"):format(src))
        TriggerClientEvent("pl_fraud:notification", src, locale("failed_cloning"), "error")
        return
    end

    local nearbyProps = GetEntityCoords(GetPlayerPed(src))
    local requiredItems = {
        Config.Props.laptop,
        Config.Props.printer,
        Config.Props.generator,
    }

    local function hasNearbyObject(item)
        local objects = GetGamePool("CObject")
        for _, obj in pairs(objects) do
            if DoesEntityExist(obj) then
                local model = GetEntityModel(obj)
                if model == GetHashKey(item) then
                    local objCoords = GetEntityCoords(obj)
                    if #(objCoords - nearbyProps) < 5.0 then
                        return true
                    end
                end
            end
        end
        return false
    end

    for _, item in ipairs(requiredItems) do
        if not hasNearbyObject(item) then
            TriggerClientEvent("pl_fraud:notification", src, locale("itemsNotClose"), "error")
            print(("[FRAUD]: Player %s missing required object '%s' nearby"):format(src, item))
            return
        end
    end
    if AddItem(player, Config.Items.cloneCard, 1) then
        print(("[FRAUD]: Clone card given to player %s"):format(src))
        minigameSuccess[src] = nil
    else
        TriggerClientEvent("pl_fraud:notification", src, locale("cant_give_card"), "error")
        print(("[FRAUD]: Failed to give card to player %s"):format(src))
    end
end)


RegisterNetEvent('pl_fraud:server:CloneCard')
AddEventHandler('pl_fraud:server:CloneCard', function(atmcoords)
    local src = source
    local ped = GetPlayerPed(src)
    local distance = GetEntityCoords(ped)
    local player = getPlayer(src)
    local Identifier = GetPlayerIdentifier(src)
    local PlayerName = getPlayerName(src)
    local hasItem = HasItem(src, Config.Items.cloneCard)
    if not hasItem then return end
    if #(distance - atmcoords) <= 5 then
        RemoveItem(player, Config.Items.cloneCard, 1)
        AddMoney(player, Config.Rewards.amount)
    else
        print('**Name:** '..PlayerName..'\n**Identifier:** '..Identifier..'** Attempted Exploit : Possible Hacker**')
    end
end)

RegisterNetEvent('pl_fraud:server:removeobject', function(type)
    local src = source
    local player = getPlayer(src)
    local identifier = GetPlayerIdentifier(src)
    local playerName = getPlayerName(src)

    if not Config.Items[type] then
        print(('[PL_FRAUD] ⚠️ %s (%s) attempted invalid type "%s"'):format(playerName, identifier, tostring(type)))
        return
    end

    AddItem(player, Config.Items[type], 1)
    TriggerClientEvent("pl_fraud:notification", src, locale("object_removed", type), "success")
    print(('[PL_FRAUD] ✅ Returned item "%s" to %s (%s)'):format(type, playerName, identifier))
end)


RegisterItems()

local WaterMark = function()
    SetTimeout(1500, function()
        print('^1['..resourceName..'] ^2Thank you for Downloading the Script^0')
        print('^1['..resourceName..'] ^2If you encounter any issues please Join the discord https://discord.gg/c6gXmtEf3H to get support..^0')
        print('^1['..resourceName..'] ^2Enjoy a secret 20% OFF any script of your choice on https://pulsescripts.tebex.io/freescript^0')
        print('^1['..resourceName..'] ^2Using the coupon code: SPECIAL20 (one-time use coupon, choose wisely)^0')
    
    end)
end

if Config.WaterMark then
    WaterMark()
end