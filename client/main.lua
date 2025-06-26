
local placedObjects = {
    laptop = nil,
    printer = nil,
    generator = nil
}

local generatorFuel = 0
local currentFuelText = nil
local cardclone = false

local function IsItemPlaced(itemType)
    return placedObjects[itemType] ~= nil and DoesEntityExist(placedObjects[itemType])
end

local function AreItemsProperlyPlaced()
    if not IsItemPlaced(Config.Items.laptop) or not IsItemPlaced(Config.Items.printer) or not IsItemPlaced(Config.Items.generator) then
        return false
    end

    local laptopCoords = GetEntityCoords(placedObjects[Config.Items.laptop])
    local printerCoords = GetEntityCoords(placedObjects[Config.Items.printer])
    local generatorCoords = GetEntityCoords(placedObjects[Config.Items.generator])

    local distLaptopPrinter = #(laptopCoords - printerCoords)
    local distLaptopGenerator = #(laptopCoords - generatorCoords)
    local distPrinterGenerator = #(printerCoords - generatorCoords)

    if Config.Debug then
        print("Distance laptop-printer: " .. distLaptopPrinter)
        print("Distance laptop-generator: " .. distLaptopGenerator)
        print("Distance printer-generator: " .. distPrinterGenerator)
    end

    return distLaptopPrinter <= Config.ProximityDistance and
           distLaptopGenerator <= Config.ProximityDistance and
           distPrinterGenerator <= Config.ProximityDistance
end

local function rotationToDirection(rotation)
	local adjustedRotation = { x = (math.pi / 180) * rotation.x, y = (math.pi / 180) * rotation.y, z = (math.pi / 180) * rotation.z }
	local direction = { x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), z = math.sin(adjustedRotation.x) }
	return direction
end
local function rayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = rotationToDirection(cameraRotation)
	local destination = { x = cameraCoord.x + direction.x * distance, y = cameraCoord.y + direction.y * distance, z = cameraCoord.z + direction.z * distance }
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, cache.ped, 0))
	return destination
end

local function PlaceItem(itemType)
    local playerPed = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)

    if IsItemPlaced(itemType) then
        TriggerEvent("pl_fraud:notification",locale("already_placed"), "error")
        return
    end
    local model = GetHashKey(Config.Props[itemType])
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, false, true)
    SetEntityAlpha(obj, 150, false)
    SetEntityCollision(obj, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    if Config.UseObjectGizmo then
        exports.object_gizmo:useGizmo(obj)
        FreezeEntityPosition(obj, true)
        SetEntityAlpha(obj, 255, false)
        SetEntityCollision(obj, true, true)
        placedObjects[itemType] = obj

        if itemType == Config.Items.generator then
            local generatorCoords = GetEntityCoords(obj)
            lib.zones.box({
                coords = generatorCoords,
                size = vec3(2.0, 2.0, 2.0),
                rotation = 0,
                debug = false,
                onEnter = function()
                    local percentage = math.floor((generatorFuel / Config.RequiredFuel) * 100)
                    currentFuelText = lib.showTextUI("Fuel: " .. percentage .. "%")
                end,
                onExit = function()
                    lib.hideTextUI()
                    currentFuelText = nil
                end,
            })
        end

        if itemType == Config.Items.laptop or itemType == Config.Items.generator or itemType == Config.Items.printer then
            Framework_AddTargetToEntity(obj, itemType)
        end
        TriggerEvent("pl_fraud:notification",locale("itemPlaced", itemType), "success")
        SetModelAsNoLongerNeeded(model)
    else
    local heading = GetEntityHeading(obj)
    local zOffset = 0.0

    lib.showTextUI(locale("object_control"), {
        position = "top-center",
        icon = 'cube',
        style = {
            borderRadius = 4,
            backgroundColor = '#4C51BF',
            color = 'white'
        }
    })
    CreateThread(function()
        while true do
            Wait(0)
            local camCoords = rayCastGamePlayCamera(4.0)
            SetEntityCoords(obj, camCoords.x, camCoords.y, camCoords.z + zOffset, false, false, false, false)
            SetEntityHeading(obj, heading)

            if IsControlPressed(0, 15) then heading += 1.0 end     -- Scroll Up
            if IsControlPressed(0, 14) then heading -= 1.0 end     -- Scroll Down

            if IsControlPressed(0, 10) then zOffset += 0.01 end    -- Page Up
            if IsControlPressed(0, 11) then zOffset -= 0.01 end    -- Page Down

            if IsControlJustPressed(0, 176) then
                FreezeEntityPosition(obj, true)
                SetEntityAlpha(obj, 255, false)
                SetEntityCollision(obj, true, true)
                placedObjects[itemType] = obj
                lib.hideTextUI()

                if itemType == Config.Items.generator then
                    local generatorCoords = GetEntityCoords(obj)
                    lib.zones.box({
                        coords = generatorCoords,
                        size = vec3(2.0, 2.0, 2.0),
                        rotation = 0,
                        debug = false,
                        onEnter = function()
                            local percentage = math.floor((generatorFuel / Config.RequiredFuel) * 100)
                            currentFuelText = lib.showTextUI("Fuel: " .. percentage .. "%")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                            currentFuelText = nil
                        end,
                    })
                end

                if itemType == Config.Items.laptop or itemType == Config.Items.generator or itemType == Config.Items.printer then
                    Framework_AddTargetToEntity(obj, itemType)
                end

                TriggerEvent("pl_fraud:notification",locale("itemPlaced", itemType), "success")
                SetModelAsNoLongerNeeded(model)
                break
            end
            -- Cancel
            if IsControlJustPressed(0, 177) then
                DeleteObject(obj)
                DeleteEntity(obj)
                lib.hideTextUI()
                break
            end
        end
    end)
    end
end


local function RemoveItem(itemType)
    if not IsItemPlaced(itemType) then
        return
    end
    DeleteEntity(placedObjects[itemType])
    placedObjects[itemType] = nil
    if itemType == Config.Items.generator then
        generatorFuel = 0
    end
    TriggerEvent("pl_fraud:notification",locale("itemRemoved", itemType), "info")
end

local function FuelGenerator(entity)
    if not IsItemPlaced(Config.Items.generator) then
        TriggerEvent("pl_fraud:notification",locale("noGeneratorFound"), "error")
        return
    end
    if generatorFuel >= Config.RequiredFuel then
        TriggerEvent("pl_fraud:notification",locale("alreadyFueled"), "error")
        return
    end
    TriggerServerEvent('pl_fraud:server:removeFuelCan',entity)
end

local function ProcessCard(entity)
    if not IsItemPlaced(Config.Items.laptop) or not IsItemPlaced(Config.Items.printer) or not IsItemPlaced(Config.Items.generator) then
        TriggerEvent("pl_fraud:notification",locale("itemsNotClose"), "error")
        return
    end
    if not AreItemsProperlyPlaced() then
        TriggerEvent("pl_fraud:notification",locale("itemsNotClose"), "error")
        return
    end
    
     if generatorFuel < Config.RequiredFuel then
        TriggerEvent("pl_fraud:notification",locale("generatorNotFueled"), "error")
        return
    end
    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    Wait(1000)
    if lib.progressBar({
        duration = Config.ProcessTime,
        label = locale("processingCard"),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    })then
            local function handleResult(success)
                if Config.Dispatch.enable then
                        DispatchAlert()
                end
                if success then
                    cardclone = true
                    ClearPedTasksImmediately(PlayerPedId())
                    TriggerServerEvent("pl_fraud:server:minigameResult", true)
                else
                    TriggerEvent("pl_fraud:notification", locale("failed_cloning"), "error")
                    TriggerServerEvent("pl_fraud:server:minigameResult", false)
                end
            end
            if Config.Hacking.Minigame == 'datacrack' then
                TriggerEvent("datacrack:start", 2, function(output)
                    handleResult(output)
                end)
            elseif Config.Hacking.Minigame == 'ps-ui-circle' then
                exports['ps-ui']:Circle(function(success)
                    handleResult(success)
                end, 4, 60)
            elseif Config.Hacking.Minigame == 'ps-ui-maze' then
                exports['ps-ui']:Maze(function(success)
                    handleResult(success)
                end, 120)
            elseif Config.Hacking.Minigame == 'ps-ui-scrambler' then
                exports['ps-ui']:Scrambler(function(success)
                    handleResult(success)
                end, 'numeric', 120, 1)
            else
                TriggerEvent('pl_atmrobbery:notification', 'Invalid minigame configuration.', 'error')
            end
        else
            TriggerEvent("pl_fraud:notification",locale("process_cancelled"), "error")
        end
end


local function GiveCloneCard(entity)
    if not IsItemPlaced(Config.Items.laptop) or not IsItemPlaced(Config.Items.printer) or not IsItemPlaced(Config.Items.generator) then
        TriggerEvent("pl_fraud:notification",locale("itemsNotClose"), "error")
        return
    end
    if not AreItemsProperlyPlaced() then
        TriggerEvent("pl_fraud:notification",locale("itemsNotClose"), "error")
        return
    end
    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    Wait(1000)
    if cardclone then
        if lib.progressBar({
            duration = Config.ProcessTime,
            label = locale("processingCard"),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
        })then
            TriggerServerEvent('pl_fraud:server:giveCloneCard')
            ClearPedTasksImmediately(playerPed)
            cardclone = false
            TriggerEvent("pl_fraud:notification",locale("cardCreated"), "success")
        else
            TriggerEvent("pl_fraud:notification",locale("process_cancelled"), "error")
        end
    end
end

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
AddEventHandler('pl_fraud:client:fuelGenerator', function(entity)
    FuelGenerator(entity)
end)

RegisterNetEvent('pl_fraud:client:fuelAdded', function(amount, entity)
    local playerPed = PlayerPedId()
    TaskTurnPedToFaceEntity(playerPed, entity, -1)
    Wait(1000)
    local dict = "timetable@gardener@filling_can"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
    TaskPlayAnim(playerPed, dict, "gar_ig_5_filling_can", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(4000)
    ClearPedTasks(playerPed)
    generatorFuel = generatorFuel + amount
    if generatorFuel > Config.RequiredFuel then
        generatorFuel = Config.RequiredFuel
    end
    local percentage = math.floor((generatorFuel / Config.RequiredFuel) * 100)
    TriggerEvent("pl_fraud:notification", locale("addedFuel", percentage), "success")

    if currentFuelText then
        lib.showTextUI("Fuel: " .. percentage .. "%")
    end
end)


RegisterNetEvent('pl_fraud:client:processCard')
AddEventHandler('pl_fraud:client:processCard', function(entity)
    ProcessCard(entity)
end)

RegisterNetEvent('pl_fraud:client:collectCard')
AddEventHandler('pl_fraud:client:collectCard', function(entity)
    if cardclone then
        GiveCloneCard(entity)
    else
        TriggerEvent("pl_fraud:notification",locale("process_card_first"), "error")
    end
end)


function Framework_AddTargetToEntity(entity, type)
    if Config.Target == 'ox-target' then
        local options = {
            {
                name = 'fraud_' .. type,
                icon = Config.TargetOptions[type].icon,
                label = Config.TargetOptions[type].label,
                distance = 1.5,
                onSelect = function()
                    if type == 'laptop' then
                        TriggerEvent('pl_fraud:client:processCard', entity)
                    elseif type == 'generator' then
                        TriggerEvent('pl_fraud:client:fuelGenerator', entity)
                    elseif type == 'printer' then
                        TriggerEvent('pl_fraud:client:collectCard', entity)
                    end
                end,
                canInteract = function()
                    return true
                end
            },
            {
                name = 'fraud_remove_' .. type,
                icon = "fas fa-trash", -- Trash icon for remove
                label = locale("target_remove_icon"),
                onSelect = function()
                    DeleteEntity(entity)
                    placedObjects[type] = nil
                    TriggerServerEvent('pl_fraud:server:removeobject',type)
                end,
                canInteract = function()
                    return true
                end
            }
        }
        exports['ox_target']:addLocalEntity(entity, options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    icon = Config.TargetOptions[type].icon,
                    label = Config.TargetOptions[type].label,
                    action = function()
                        if type == 'laptop' then
                            TriggerEvent('pl_fraud:client:processCard', entity)
                        elseif type == 'generator' then
                            TriggerEvent('pl_fraud:client:fuelGenerator', entity)
                        elseif type == 'printer' then
                            TriggerEvent('pl_fraud:client:collectCard', entity)
                        end
                    end,
                    canInteract = function()
                        return true
                    end
                },
                {
                    icon = "fas fa-trash",
                    label = locale("target_remove_icon"),
                    action = function()
                        DeleteEntity(entity)
                        placedObjects[type] = nil
                        TriggerServerEvent('pl_fraud:server:removeobject',type)
                    end,
                    canInteract = function()
                        return true
                    end
                }
            },
            distance = 1.5
        })
    end
end

if Config.Target == 'ox-target' then
    exports.ox_target:addModel(Config.atmModels, {
        {
            name = 'insert_clonecard',
            icon = 'fas fa-credit-card',
            label = locale("insert_card"),
            items = {Config.Items.cloneCard},
            distance = 1.5,
            onSelect = function(data)
                local entity = data.entity
                local playerPed = PlayerPedId()
                TaskTurnPedToFaceEntity(playerPed, entity, -1)
                RequestAnimDict("amb@prop_human_atm@male@idle_a")
                while not HasAnimDictLoaded("amb@prop_human_atm@male@idle_a") do
                    Wait(0)
                end
                if lib.progressBar({
                    duration = 4000,
                    label = locale("inserting_card"),
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                    },
                    anim = {
                        dict = 'amb@prop_human_atm@male@idle_a',
                        clip = 'idle_a'
                    }
                })then
                        ClearPedTasksImmediately(playerPed)
                        local atmcoords = GetEntityCoords(entity)
                        TriggerServerEvent('pl_fraud:server:CloneCard', atmcoords)
                    else
                        ClearPedTasksImmediately(playerPed)
                end
            end
        }
    })
elseif Config.Target == 'qb-target' then
    exports['qb-target']:AddTargetModel(Config.atmModels, {
        options = {
            {
                icon = 'fas fa-credit-card',
                label = locale("insert_card"),
                item = Config.Items.cloneCard,
                action = function(entity)
                    local playerPed = PlayerPedId()
                    TaskTurnPedToFaceEntity(playerPed, entity, -1)
                    RequestAnimDict("amb@prop_human_atm@male@idle_a")
                    while not HasAnimDictLoaded("amb@prop_human_atm@male@idle_a") do Wait(0) end

                    if lib.progressBar({
                        duration = 4000,
                        label = locale("inserting_card"),
                        useWhileDead = false,
                        canCancel = false,
                        disable = {
                            car = true,
                            move = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'amb@prop_human_atm@male@idle_a',
                            clip = 'idle_a'
                        }
                    }) then
                        ClearPedTasksImmediately(playerPed)
                        local atmcoords = GetEntityCoords(entity)
                        TriggerServerEvent('pl_fraud:server:CloneCard', atmcoords)
                    else
                        ClearPedTasksImmediately(playerPed)
                    end
                end
            }
        },
        distance = 1.5
    })
end

function DispatchAlert()
    if Config.Dispatch.script == 'ps' then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street1name = GetStreetNameFromHashKey(street1)
        local street2name = GetStreetNameFromHashKey(street2)
        local alert = {
            coords = coords,
            message = locale('dispatch_message')..street1name.. ' ' ..street2name,
            dispatchCode = '10-99',
            description = locale('dispatch_message'),
            radius = 0,
            sprite = 431,
            color = 1,
            scale = 1.0,
            length = 3
        }
        exports["ps-dispatch"]:CustomAlert(alert)
    elseif Config.Dispatch.script == 'qs' then
        local playerData = exports['qs-dispatch']:GetPlayerInfo()
        TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = Config.Police.Job,
            callLocation = playerData.coords,
            callCode = { code = '10-99', snippet = locale('dispatch_message') },
            message = "street_1: ".. playerData.street_1.. " street_2: ".. playerData.street_2.."",
            flashes = false, -- No flashing icon
            image = nil,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 1,
                flashes = true,
                text = locale('dispatch_message'),
                time = (30 * 1000), 
            }
        })
    elseif Config.Dispatch.script == 'aty' then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street1name = GetStreetNameFromHashKey(street1)
        local street2name = GetStreetNameFromHashKey(street2)
        TriggerServerEvent("aty_dispatch:server:customDispatch",
            "Card Cloning Activity Reported",          -- title
            "10-99",                -- code
            street1name ' ' ..street2name, -- location
            coords,      -- coords (vector3)
            nil,         -- gender
            nil, -- vehicle name
            nil, -- vehicle object (optional)
            nil, -- weapon (not needed for ATM robbery)
            431, -- blip sprite (robbery icon)
            Config.Police.Job -- jobs to notify
            )

    elseif Config.Dispatch.script == 'rcore_disptach' then
        local playerData = exports['rcore_dispatch']:GetPlayerData()
        exports['screenshot-basic']:requestScreenshotUpload('InsertWebhookLinkHERE', "files[]", function(val)
            local image = json.decode(val)
            local alert = {
                code = '10-99',
                default_priority = 'low',
                coords = playerData.coords,
                job = Config.Police.Job,
                text = 'Card Cloning Activity Reported in progress on ' ..playerData.street_1,
                type = 'alerts',
                blip_time = 30,
                image = image.attachments[1].proxy_url,
                blip = {
                    sprite = 431,
                    colour = 1,
                    scale = 1.0,
                    text = '10-99 - Card Cloning Activity Reported',
                    flashes = false,
                    radius = 0,
                }
            }
        TriggerServerEvent('rcore_dispatch:server:sendAlert', alert)
    end)
    elseif Config.Dispatch.script == 'op' then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street1name = GetStreetNameFromHashKey(street1)
        local street2name = GetStreetNameFromHashKey(street2)
            
        local job = Config.Police.Job -- Jobs that will receive the alert
        local title = "Card Cloning" -- Main title alert
        local id = GetPlayerServerId(PlayerId()) -- Player that triggered the alert
        local panic = false -- Allow/Disable panic effect
            
        local locationText = street2name and (street1name .. " and " .. street2name) or street1name
        local text = "Card Cloning Activity Reported in progress on " .. locationText -- Main text alert
            
        TriggerServerEvent('Opto_dispatch:Server:SendAlert', job, title, text, coords, panic, id)
    elseif Config.Dispatch.script == 'custom' then

    end
end

if Config.Debug then
    RegisterCommand('place_laptop', function()
        PlaceItem(Config.Items.laptop)
    end, false)
    
    RegisterCommand('place_printer', function()
        PlaceItem(Config.Items.printer)
    end, false)
    
    RegisterCommand('place_generator', function()
        PlaceItem(Config.Items.generator)
    end, false)
    
    RegisterCommand('remove_laptop', function()
        RemoveItem(Config.Items.laptop)
    end, false)
    
    RegisterCommand('remove_printer', function()
        RemoveItem(Config.Items.printer)
    end, false)
    
    RegisterCommand('remove_generator', function()
        RemoveItem(Config.Items.generator)
    end, false)
end

RegisterNetEvent('pl_fraud:notification')
AddEventHandler('pl_fraud:notification', function(message, type)
    if Config.Notify == 'ox' then
        TriggerEvent('ox_lib:notify', {description = message, type = type or "success"})
    elseif Config.Notify == 'esx' then
        TriggerEvent("esx:showNotification", message)
    elseif Config.Notify == 'okok' then
        TriggerEvent('okokNotify:Alert', message, 6000, type)
    elseif Config.Notify == 'qb' then
        TriggerEvent("QBCore:Notify", message, type, 6000)
    elseif Config.Notify == 'wasabi' then
        exports.wasabi_notify:notify("Fraud Script", message, 6000, type, false, 'fas fa-ghost')
    elseif Config.Notify == 'brutal_notify' then
        exports['brutal_notify']:SendAlert('Notify', message, 6000, type, false)
    elseif Config.Notify == 'mythic_notify' then
        exports['mythic_notify']:SendAlert(type, message)
    elseif Config.Notify == 'custom' then
        -- Add your custom notifications here
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for itemType, obj in pairs(placedObjects) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
end)

