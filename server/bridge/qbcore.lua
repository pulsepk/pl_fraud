local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

function getPlayer(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    return xPlayer
end

function getPlayers()
    return QBCore.Functions.GetPlayers()
end

function GetJob(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    return xPlayer.PlayerData.job.name
end

function GetPlayerIdentifier(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    return xPlayer.PlayerData.citizenid
end

function getPlayerName(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)

    return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
end

function AddItem(player, itemName, amount,totalWorth)
    local source = player.PlayerData.source
    if GetResourceState("ox_inventory") == "started" then
        exports.ox_inventory:AddItem(source, itemName, amount, false)
        return true
    elseif GetResourceState('qb-inventory') == "started" then
        if lib.checkDependency('qb-inventory', '2.0.0') then
            exports['qb-inventory']:AddItem(source, itemName, amount, false, {worth = totalWorth})
            TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'add')
            return true
        else
            player.Functions.AddItem(itemName, amount, false, {worth = totalWorth})
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "add")
            return true
        end
    end
    return false
end

function RemoveItem(player, itemName, amount)
    local source = player.PlayerData.source
    if GetResourceState("ox_inventory") == "started" then
        exports.ox_inventory:RemoveItem(source, itemName, amount, false)
        return true
    else
        if lib.checkDependency('qb-inventory', '2.0.0') then
            exports['qb-inventory']:RemoveItem(source, itemName, amount, false)
            TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove')
            return true
        else
            player.Functions.RemoveItem(itemName, amount)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "remove")
            return true
        end
    end
    return false
end

function AddMoney(player, amount)
    if Config.Rewards.EnableBlackMoney then
        local totalWorth = amount
        if Config.Rewards.moneytype == 'markedbills' then
            AddItem(player,Config.Rewards.moneytype,amount,totalWorth)
        else
            AddItem(player,Config.Rewards.moneytype,amount)
        end
    else
        player.Functions.AddMoney('cash', amount)
    end
end

function HasItem(playerSource,itemName)
    local xPlayer = getPlayer(playerSource)
    if not xPlayer then return false end
    local item = xPlayer.Functions.GetItemByName(itemName)?.amount or 0
    if item >= 1 then
        return true
    else
        return false
    end
end
