
local placedObjects = {
    laptop    = nil,
    printer   = nil,
    generator = nil,
}

local generatorFuel  = 0
local currentFuelText = false   -- true while the fuel TextUI is visible
local cardclone      = false
local isPlacing      = {}       -- guard: prevents double-triggering PlaceItem
local generatorZone  = nil      -- ox_lib zone reference, removed on generator pickup

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function IsItemPlaced(itemType)
    return placedObjects[itemType] ~= nil and DoesEntityExist(placedObjects[itemType])
end

local function AreItemsProperlyPlaced()
    if not (IsItemPlaced(Config.Items.laptop) and IsItemPlaced(Config.Items.printer) and IsItemPlaced(Config.Items.generator)) then
        return false
    end

    local lc = GetEntityCoords(placedObjects[Config.Items.laptop])
    local pc = GetEntityCoords(placedObjects[Config.Items.printer])
    local gc = GetEntityCoords(placedObjects[Config.Items.generator])

    local d = Config.ProximityDistance
    local ok = #(lc - pc) <= d and #(lc - gc) <= d and #(pc - gc) <= d

    if Config.Debug then
        print(("laptop-printer: %.2f  laptop-gen: %.2f  printer-gen: %.2f  (max: %.2f)"):format(
            #(lc - pc), #(lc - gc), #(pc - gc), d))
    end
    return ok
end

-- ─── Placement helpers ────────────────────────────────────────────────────────

-- Converts camera rotation euler angles to a normalised direction vector3.
local function RotationToDirection(rotation)
    local rx = math.rad(rotation.x)
    local rz = math.rad(rotation.z)
    return vec3(
        -math.sin(rz) * math.abs(math.cos(rx)),
         math.cos(rz) * math.abs(math.cos(rx)),
         math.sin(rx)
    )
end

-- Projects 'distance' metres from the camera and snaps the result to the ground
-- surface using GetGroundZFor_3dCoord, so objects land on terrain rather than
-- floating at the raw ray endpoint.
local function GetPlacementPosition(distance)
    local camPos = GetGameplayCamCoord()
    local dir    = RotationToDirection(GetGameplayCamRot())
    local target = camPos + dir * distance
    local found, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z + 5.0, false)
    return vec3(target.x, target.y, found and groundZ or target.z)
end

-- Sets up the generator proximity zone that shows fuel percentage TextUI.
-- Stored in generatorZone so it can be removed when the generator is picked up.
local function CreateGeneratorZone(obj)
    local coords = GetEntityCoords(obj)
    generatorZone = lib.zones.box({
        coords   = coords,
        size     = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug    = Config.Debug,
        onEnter  = function()
            local pct = math.floor((generatorFuel / Config.RequiredFuel) * 100)
            lib.showTextUI(locale('fuel_percentage', pct))
            currentFuelText = true
        end,
        onExit = function()
            lib.hideTextUI()
            currentFuelText = false
        end,
    })
end

-- Called once the player confirms placement in either gizmo or manual mode.
local function FinalizeObjectPlacement(obj, itemType)
    FreezeEntityPosition(obj, true)
    SetEntityAlpha(obj, 255, false)
    SetEntityCollision(obj, true, true)
    placedObjects[itemType] = obj

    if itemType == Config.Items.generator then
        CreateGeneratorZone(obj)
    end

    Framework_AddTargetToEntity(obj, itemType)
    TriggerEvent('pl_fraud:notification', locale('itemPlaced', itemType), 'success')
end

-- Deletes a placed object and cleans up any associated state (zone, fuel, etc.).
local function CleanupObject(itemType)
    if placedObjects[itemType] and DoesEntityExist(placedObjects[itemType]) then
        DeleteEntity(placedObjects[itemType])
    end
    placedObjects[itemType] = nil

    if itemType == Config.Items.generator then
        generatorFuel = 0
        if generatorZone then
            generatorZone:remove()
            generatorZone = nil
        end
        if currentFuelText then
            lib.hideTextUI()
            currentFuelText = false
        end
    end
end

-- ─── PlaceItem ────────────────────────────────────────────────────────────────

local function PlaceItem(itemType)
    if IsItemPlaced(itemType) then
        TriggerEvent('pl_fraud:notification', locale('already_placed'), 'error')
        return
    end
    if isPlacing[itemType] then return end
    isPlacing[itemType] = true

    local model = GetHashKey(Config.Props[itemType])
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local spawnPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.5, 0.0)
    local obj      = CreateObject(model, spawnPos.x, spawnPos.y, spawnPos.z, true, false, true)
    SetEntityAlpha(obj, 180, false)
    SetEntityCollision(obj, false, false)
    SetEntityAsMissionEntity(obj, true, true)

    local function onConfirm()
        lib.hideTextUI()
        FinalizeObjectPlacement(obj, itemType)
        SetModelAsNoLongerNeeded(model)
        isPlacing[itemType] = false
    end

    local function onCancel()
        lib.hideTextUI()
        DeleteEntity(obj)
        isPlacing[itemType] = false
    end

    local hintOpts = {
        position = 'top-center',
        icon     = 'cube',
        style    = { borderRadius = 4, backgroundColor = '#4C51BF', color = 'white' },
    }

    -- ── Gizmo mode ──────────────────────────────────────────────────────────
    -- object_gizmo moves the entity interactively; the player just confirms or
    -- cancels when satisfied.  We must NOT freeze or enable collision until
    -- confirmation — the gizmo needs the entity to be unfrozen.
    if Config.UseObjectGizmo and GetResourceState('object_gizmo') == 'started' then
        exports.object_gizmo:useGizmo(obj)
        lib.showTextUI(locale('object_control'), hintOpts)
        CreateThread(function()
            while true do
                Wait(0)
                if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                    onConfirm(); break
                end
                if IsControlJustPressed(0, 177) then
                    onCancel(); break
                end
            end
        end)
        return
    end

    -- ── Manual placement mode ────────────────────────────────────────────────
    -- Controls:
    --   ← →          Arrow keys          Rotate (Config.Placing.RotationSpeed °/frame)
    --   ↑ ↓          Arrow keys          Height (Config.Placing.HeightStep m/frame)
    --   [E] / [Enter]                    Confirm placement
    --   [Backspace]                       Cancel
    local heading = GetEntityHeading(obj)
    local zOffset = 0.0
    local active  = true

    lib.showTextUI(locale('object_control'), hintOpts)

    CreateThread(function()
        while active do
            Wait(0)

            local pos = GetPlacementPosition(Config.Placing.Distance)
            SetEntityCoords(obj, pos.x, pos.y, pos.z + zOffset, false, false, false, false)
            SetEntityHeading(obj, heading)

            -- Prevent GTA default actions that fight placement input
            DisableControlAction(0, 24, true)   -- Attack
            DisableControlAction(0, 25, true)   -- Aim
            DisableControlAction(0, 37, true)   -- Select weapon (blocks scroll→weapon-wheel)

            -- Rotation — left / right arrows
            if IsControlPressed(0, 174) then
                heading = (heading - Config.Placing.RotationSpeed) % 360
            end
            if IsControlPressed(0, 175) then
                heading = (heading + Config.Placing.RotationSpeed) % 360
            end

            -- Coarse rotation — scroll wheel (15° per tick)
            if IsControlJustPressed(0, 14) then
                heading = (heading - 15.0) % 360
            end
            if IsControlJustPressed(0, 15) then
                heading = (heading + 15.0) % 360
            end

            -- Height — up / down arrows, clamped to avoid clipping into ground
            if IsControlPressed(0, 172) then
                zOffset = math.min(zOffset + Config.Placing.HeightStep, 2.0)
            end
            if IsControlPressed(0, 173) then
                zOffset = math.max(zOffset - Config.Placing.HeightStep, -0.3)
            end

            -- Confirm: E or Enter/numpad-Enter
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                active = false
                onConfirm()
            end

            -- Cancel: Backspace
            if IsControlJustPressed(0, 177) then
                active = false
                onCancel()
            end
        end
    end)
end

-- ─── RemoveItem ───────────────────────────────────────────────────────────────

local function RemoveItem(itemType)
    if not IsItemPlaced(itemType) then return end
    CleanupObject(itemType)
    TriggerEvent('pl_fraud:notification', locale('itemRemoved', itemType), 'info')
end

-- ─── FuelGenerator ───────────────────────────────────────────────────────────

local function FuelGenerator(entity)
    if not IsItemPlaced(Config.Items.generator) then
        TriggerEvent('pl_fraud:notification', locale('noGeneratorFound'), 'error')
        return
    end
    if generatorFuel >= Config.RequiredFuel then
        TriggerEvent('pl_fraud:notification', locale('alreadyFueled'), 'error')
        return
    end
    TriggerServerEvent('pl_fraud:server:removeFuelCan', entity)
end

-- ─── ProcessCard ─────────────────────────────────────────────────────────────

local function ProcessCard(entity)
    if not (IsItemPlaced(Config.Items.laptop) and IsItemPlaced(Config.Items.printer) and IsItemPlaced(Config.Items.generator)) then
        TriggerEvent('pl_fraud:notification', locale('itemsNotClose'), 'error')
        return
    end
    if not AreItemsProperlyPlaced() then
        TriggerEvent('pl_fraud:notification', locale('itemsNotClose'), 'error')
        return
    end
    if generatorFuel < Config.RequiredFuel then
        TriggerEvent('pl_fraud:notification', locale('generatorNotFueled'), 'error')
        return
    end

    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    Wait(1000)

    if lib.progressBar({
        duration    = Config.ProcessTime,
        label       = locale('processingCard'),
        useWhileDead = false,
        canCancel   = true,
        disable     = { car = true, move = true, combat = true },
    }) then
        local function handleResult(success)
            if Config.Dispatch.enable then DispatchAlert() end
            if success then
                cardclone = true
                ClearPedTasksImmediately(PlayerPedId())
                TriggerServerEvent('pl_fraud:server:minigameResult', true)
                if generatorFuel > 0 then
                    generatorFuel = generatorFuel - 10
                end
            else
                TriggerEvent('pl_fraud:notification', locale('failed_cloning'), 'error')
                TriggerServerEvent('pl_fraud:server:minigameResult', false)
            end
        end

        if Config.Hacking.Minigame == 'datacrack' then
            TriggerEvent('datacrack:start', 2, function(output) handleResult(output) end)
        elseif Config.Hacking.Minigame == 'ps-ui-circle' then
            exports['ps-ui']:Circle(function(success) handleResult(success) end, 4, 60)
        elseif Config.Hacking.Minigame == 'ps-ui-maze' then
            exports['ps-ui']:Maze(function(success) handleResult(success) end, 120)
        elseif Config.Hacking.Minigame == 'ps-ui-scrambler' then
            exports['ps-ui']:Scrambler(function(success) handleResult(success) end, 'numeric', 120, 1)
        else
            TriggerEvent('pl_fraud:notification', 'Invalid minigame configuration.', 'error')
        end
    else
        TriggerEvent('pl_fraud:notification', locale('process_cancelled'), 'error')
    end
end

-- ─── GiveCloneCard ───────────────────────────────────────────────────────────

local function GiveCloneCard(entity)
    if not (IsItemPlaced(Config.Items.laptop) and IsItemPlaced(Config.Items.printer) and IsItemPlaced(Config.Items.generator)) then
        TriggerEvent('pl_fraud:notification', locale('itemsNotClose'), 'error')
        return
    end
    if not AreItemsProperlyPlaced() then
        TriggerEvent('pl_fraud:notification', locale('itemsNotClose'), 'error')
        return
    end

    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    Wait(1000)

    if not cardclone then return end

    if lib.progressBar({
        duration    = Config.ProcessTime,
        label       = locale('processingCard'),
        useWhileDead = false,
        canCancel   = true,
        disable     = { car = true, move = true, combat = true },
    }) then
        TriggerServerEvent('pl_fraud:server:giveCloneCard')
        ClearPedTasksImmediately(playerPed)
        cardclone = false
        TriggerEvent('pl_fraud:notification', locale('cardCreated'), 'success')
    else
        TriggerEvent('pl_fraud:notification', locale('process_cancelled'), 'error')
    end
end

-- ─── Network events ──────────────────────────────────────────────────────────

RegisterNetEvent('pl_fraud:client:placeItem')
AddEventHandler('pl_fraud:client:placeItem', function(itemType)
    if Config.Props[itemType] then
        PlaceItem(itemType)
    end
end)

RegisterNetEvent('pl_fraud:client:removeItem')
AddEventHandler('pl_fraud:client:removeItem', function(itemType)
    if placedObjects[itemType] then
        RemoveItem(itemType)
    end
end)

RegisterNetEvent('pl_fraud:client:fuelGenerator')
AddEventHandler('pl_fraud:client:fuelGenerator', function(data)
    local entity = type(data) == 'table' and data.entity or data
    FuelGenerator(entity)
end)

RegisterNetEvent('pl_fraud:client:fuelAdded')
AddEventHandler('pl_fraud:client:fuelAdded', function(amount, entity)
    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    Wait(1000)

    local dict = 'timetable@gardener@filling_can'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(playerPed, dict, 'gar_ig_5_filling_can', 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(4000)
    ClearPedTasks(playerPed)

    generatorFuel = math.min(generatorFuel + amount, Config.RequiredFuel)
    local pct = math.floor((generatorFuel / Config.RequiredFuel) * 100)
    TriggerEvent('pl_fraud:notification', locale('addedFuel', pct), 'success')

    -- Refresh the in-zone fuel TextUI if the player is standing next to the generator
    if currentFuelText then
        lib.showTextUI(locale('fuel_percentage', pct))
    end
end)

RegisterNetEvent('pl_fraud:client:processCard')
AddEventHandler('pl_fraud:client:processCard', function(data)
    local entity = type(data) == 'table' and data.entity or data
    ProcessCard(entity)
end)

RegisterNetEvent('pl_fraud:client:collectCard')
AddEventHandler('pl_fraud:client:collectCard', function(data)
    local entity = type(data) == 'table' and data.entity or data
    if cardclone then
        GiveCloneCard(entity)
    else
        TriggerEvent('pl_fraud:notification', locale('process_card_first'), 'error')
    end
end)

-- Fired by pl_lib target when the player selects Remove on a placed prop
AddEventHandler('pl_fraud:internal:removeTarget', function(data)
    CleanupObject(data.args)
    TriggerServerEvent('pl_fraud:server:removeobject', data.args)
end)

-- Fired by pl_lib model target when the player inserts a clone card at an ATM
AddEventHandler('pl_fraud:internal:atmInsertCard', function(data)
    local entity    = data.entity
    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    RequestAnimDict('amb@prop_human_atm@male@idle_a')
    while not HasAnimDictLoaded('amb@prop_human_atm@male@idle_a') do Wait(0) end

    if lib.progressBar({
        duration    = 4000,
        label       = locale('inserting_card'),
        useWhileDead = false,
        canCancel   = false,
        disable     = { car = true, move = true, combat = true },
        anim        = { dict = 'amb@prop_human_atm@male@idle_a', clip = 'idle_a' },
    }) then
        ClearPedTasksImmediately(playerPed)
        TriggerServerEvent('pl_fraud:server:CloneCard')
    else
        ClearPedTasksImmediately(playerPed)
    end
end)

-- ─── Target setup ─────────────────────────────────────────────────────────────

function Framework_AddTargetToEntity(entity, itemType)
    local actionEvents = {
        laptop    = 'pl_fraud:client:processCard',
        generator = 'pl_fraud:client:fuelGenerator',
        printer   = 'pl_fraud:client:collectCard',
    }
    exports.pl_lib:AddEntityTarget(entity, {
        name     = 'fraud_' .. itemType,
        icon     = Config.TargetOptions[itemType].icon,
        label    = Config.TargetOptions[itemType].label,
        distance = 1.5,
        event    = actionEvents[itemType],
    })
    exports.pl_lib:AddEntityTarget(entity, {
        name     = 'fraud_remove_' .. itemType,
        icon     = 'fas fa-trash',
        label    = locale('target_remove_icon'),
        distance = 1.5,
        event    = 'pl_fraud:internal:removeTarget',
        args     = itemType,
    })
end

exports.pl_lib:AddModelTarget(Config.atmModels, {
    {
        name     = 'insert_clonecard',
        icon     = 'fas fa-credit-card',
        label    = locale('insert_card'),
        item     = Config.Items.cloneCard,
        distance = 1.5,
        event    = 'pl_fraud:internal:atmInsertCard',
    }
})

-- ─── Dispatch ─────────────────────────────────────────────────────────────────

function DispatchAlert()
    exports.pl_lib:SendDispatch({
        title   = locale('dispatch_message'),
        code    = '10-99',
        message = locale('dispatch_message'),
        jobs    = { Config.Police.Job },
        sprite  = 431,
        color   = 1,
    })
end

-- ─── Debug commands ───────────────────────────────────────────────────────────

if Config.Debug then
    RegisterCommand('place_laptop',    function() PlaceItem(Config.Items.laptop)    end, false)
    RegisterCommand('place_printer',   function() PlaceItem(Config.Items.printer)   end, false)
    RegisterCommand('place_generator', function() PlaceItem(Config.Items.generator) end, false)
    RegisterCommand('remove_laptop',   function() RemoveItem(Config.Items.laptop)   end, false)
    RegisterCommand('remove_printer',  function() RemoveItem(Config.Items.printer)  end, false)
    RegisterCommand('remove_generator',function() RemoveItem(Config.Items.generator)end, false)
end

-- ─── Notifications ────────────────────────────────────────────────────────────

RegisterNetEvent('pl_fraud:notification')
AddEventHandler('pl_fraud:notification', function(message, ntype)
    exports.pl_lib:Notify('Fraud', message, ntype or 'success')
end)

-- ─── Cleanup on resource stop ─────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for itemType, obj in pairs(placedObjects) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    if generatorZone then
        generatorZone:remove()
        generatorZone = nil
    end
end)
