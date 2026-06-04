lib.versionCheck('pulsepk/pl_fraud')
lib.locale()
local minigameSuccess = {}

local function AddMoney(src, amount)
    if Config.Rewards.moneytype == 'money' then
        exports.pl_lib:AddPlayerMoney(src, 'money', amount)
    else
        -- 'black_money' and 'markedbills' both map to the 'dirty' account in pl_lib
        exports.pl_lib:AddPlayerMoney(src, 'dirty', amount)
    end
end

function RegisterUsable(itemName, oxName)
    if GetResourceState('ox_inventory') == 'started' then
        exports(itemName, function(event, item, inventory, slot, data)
            if event == 'usedItem' then
                TriggerClientEvent('pl_fraud:client:placeItem', inventory.id, oxName)
                exports.ox_inventory:RemoveItem(inventory.id, oxName, 1)
            end
        end)
    else
        exports.pl_lib:RegisterUsableItem(itemName, function(src)
            exports.pl_lib:RemoveItem(src, oxName, 1)
            TriggerClientEvent('pl_fraud:client:placeItem', src, oxName)
        end)
    end
end

function RegisterItems()
    RegisterUsable(Config.Items.laptop, 'laptop')
    RegisterUsable(Config.Items.printer, 'printer')
    RegisterUsable(Config.Items.generator, 'generator')
end

RegisterNetEvent('pl_fraud:server:removeFuelCan')
AddEventHandler('pl_fraud:server:removeFuelCan', function(entity)
    local src = source
    if exports.pl_lib:HasItem(src, Config.Items.fuelCan) > 0 then
        if exports.pl_lib:RemoveItem(src, Config.Items.fuelCan, 1) then
            TriggerClientEvent('pl_fraud:client:fuelAdded', src, Config.RequiredFuel * 1.0, entity)
        end
    else
        TriggerClientEvent('pl_fraud:notification', src, locale('no_fuel_can'), 'error')
    end
end)

RegisterNetEvent('pl_fraud:server:minigameResult')
AddEventHandler('pl_fraud:server:minigameResult', function(success)
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

RegisterNetEvent('pl_fraud:server:giveCloneCard')
AddEventHandler('pl_fraud:server:giveCloneCard', function()
    local src = source
    if not minigameSuccess[src] then
        print(('[SECURITY] Player %s tried to clone card without valid minigame result'):format(src))
        TriggerClientEvent('pl_fraud:notification', src, locale('failed_cloning'), 'error')
        return
    end
    if exports.pl_lib:AddItem(src, Config.Items.cloneCard, 1) then
        print(('[FRAUD]: Clone card given to player %s'):format(src))
        minigameSuccess[src] = nil
    else
        TriggerClientEvent('pl_fraud:notification', src, locale('cant_give_card'), 'error')
        print(('[FRAUD]: Failed to give card to player %s'):format(src))
    end
end)

RegisterNetEvent('pl_fraud:server:CloneCard')
AddEventHandler('pl_fraud:server:CloneCard', function()
    local src = source
    if exports.pl_lib:HasItem(src, Config.Items.cloneCard) < 1 then return end
    exports.pl_lib:RemoveItem(src, Config.Items.cloneCard, 1)
    AddMoney(src, Config.Rewards.amount)
end)

RegisterNetEvent('pl_fraud:server:removeobject')
AddEventHandler('pl_fraud:server:removeobject', function(type)
    local src = source
    local identifier = exports.pl_lib:GetPlayerIdentifier(src) or 'unknown'
    local playerName = exports.pl_lib:GetPlayerName(src) or 'unknown'

    if not Config.Items[type] then
        print(('[PL_FRAUD] %s (%s) attempted invalid type "%s"'):format(playerName, identifier, tostring(type)))
        return
    end

    exports.pl_lib:AddItem(src, Config.Items[type], 1)
    TriggerClientEvent('pl_fraud:notification', src, locale('object_removed', type), 'success')
    print(('[PL_FRAUD] Returned item "%s" to %s (%s)'):format(type, playerName, identifier))
end)

local WaterMark = function()
    SetTimeout(1500, function()
        print("^3💡 Tip:^7 Outgrow pl_fraud? Upgrade with ^5spoodyFraud^7 (advanced features & progression).")
        print("🎟️  Use code ^2PULSE^7 (enter in creator code section) for ^220% OFF^7")
        print("🎬  Preview: ^4https://www.youtube.com/watch?v=fux1-zGhzEs^0")
        print("🛒  Purchase: ESX: ^4https://spoody.store/package/5938806^0 ^3|^0 QB/QBX: ^4https://spoody.store/package/6087850^0")
    end)
end

local function CheckMinigameDependency()
    local minigame = Config.Hacking.Minigame
    local resourceMap = {
        ['datacrack']       = 'datacrack',
        ['ps-ui-circle']    = 'ps-ui',
        ['ps-ui-maze']      = 'ps-ui',
        ['ps-ui-scrambler'] = 'ps-ui',
    }
    local required = resourceMap[minigame]
    if not required then
        print(("^1[pl_fraud] Unknown minigame '%s' in Config.Hacking.Minigame — check your config.^0"):format(minigame))
        return
    end
    if GetResourceState(required) ~= 'started' then
        print(("^1[pl_fraud] WARNING: Minigame '%s' requires resource '^3%s^1' but it is not started. "
            .. "Players will see an error when trying to clone cards. "
            .. "Install/start '%s' or change Config.Hacking.Minigame.^0"):format(minigame, required, required))
    end
end

RegisterServerEvent('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('^1['..resourceName..'] ^2Resource started successfully!^0')
        RegisterItems()
        CheckMinigameDependency()
        Wait(1000)
        if Config.WaterMark then
            WaterMark()
        end
    end
end)
