local resourceName = 'pl_fraud'
lib.versionCheck('pulsepk/pl_fraud')
lib.locale()

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
            if not exports['qb-inventory']:RemoveItem(source, item.name, 1, item.slot) then return end
            TriggerClientEvent('pl_fraud:client:placeItem', source, 'laptop')
        end)
        QBCore.Functions.CreateUseableItem(Config.Items.printer, function(source, item)
            if not exports['qb-inventory']:RemoveItem(source, item.name, 1, item.slot) then return end
            TriggerClientEvent('pl_fraud:client:placeItem', source, 'printer')
        end)
        QBCore.Functions.CreateUseableItem(Config.Items.generator, function(source, item)
            if not exports['qb-inventory']:RemoveItem(source, item.name, 1, item.slot) then return end
            TriggerClientEvent('pl_fraud:client:placeItem', source, 'generator')
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

-- Event to give a clone card
RegisterNetEvent('pl_fraud:server:giveCloneCard')
AddEventHandler('pl_fraud:server:giveCloneCard', function()
    local src = source
    local player = getPlayer(src)
    if AddItem(player, Config.Items.cloneCard, 1) then
    else
        if src then
            TriggerClientEvent("pl_fraud:notification", src, locale("cant_give_card"), "error")
        end
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

RegisterNetEvent('pl_fraud:server:removeobject')
AddEventHandler('pl_fraud:server:removeobject', function(coords,type)
    local src = source
    local player = getPlayer(src)
    local Identifier = GetPlayerIdentifier(src)
    local PlayerName = getPlayerName(src)
    local ped = GetPlayerPed(src)
    local distance = GetEntityCoords(ped)
    if #(distance - coords) <= 5 then
        if Player then
            AddItem(player, type, 1)
        end
    else
        print('**Name:** '..PlayerName..'\n**Identifier:** '..Identifier..'** Attempted Exploit : Possible Hacker**')
    end
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

WaterMark()