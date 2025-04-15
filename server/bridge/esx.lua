local ESX = GetResourceState('es_extended'):find('start') and exports['es_extended']:getSharedObject() or nil

if not ESX then return end

function getPlayer(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    return xPlayer
end

function getPlayers()
    return ESX.GetExtendedPlayers()
end

function GetJob(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    return xPlayer.getJob().name
end

function GetPlayerIdentifier(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    return xPlayer.getIdentifier()
end

function getPlayerName(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    return xPlayer.getName()
end

function AddItem(player, itemName, amount)
    if player then
        player.addInventoryItem(itemName, amount)
        return true
    end

    return false
end

function RemoveItem(player, itemName, amount)
    if player then
        player.removeInventoryItem(itemName, amount)
        return true
    end
    return false
end

function AddMoney(player, amount)
    if Config.Rewards.EnableBlackMoney then
        player.addAccountMoney('black_money', amount)
    else
        player.addMoney(amount)
    end
end

function HasItem(playerSource,itemName)
    local xPlayer = ESX.GetPlayerFromId(playerSource)
    if not xPlayer then return false end
    local item = xPlayer.getInventoryItem(itemName)
    if item and item.count >= 1 then
        return true
    else
        return false
    end
end

