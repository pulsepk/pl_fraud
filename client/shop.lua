if not Config.Shop.Enable then return end

local shopped

local targetResource = GetTarget()

print(("^2[Shop] Initializing shop: ^7%s"):format(Config.Shop.name))

CreateThread(function()
    -- Spawn Ped
    RequestModel(Config.Shop.pedModel)
    while not HasModelLoaded(Config.Shop.pedModel) do Wait(0) end

    shopped = CreatePed(0, Config.Shop.pedModel, Config.Shop.coords.x, Config.Shop.coords.y, Config.Shop.coords.z - 1.0, Config.Shop.heading, false, true)
    SetEntityInvincible(shopped, true)
    FreezeEntityPosition(shopped, true)
    SetBlockingOfNonTemporaryEvents(shopped, true)

    -- Add Blip
    if Config.Shop.blip.enabled then
        local blip = AddBlipForCoord(Config.Shop.coords.x, Config.Shop.coords.y, Config.Shop.coords.z)
        SetBlipSprite(blip, Config.Shop.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Shop.blip.scale)
        SetBlipColour(blip, Config.Shop.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Shop.name)
        EndTextCommandSetBlipName(blip)
    end

    -- Add Target Option
    local openShopAction = function()
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:openInventory('shop', { type = Config.Shop.id, id = 1 })
        elseif GetResourceState('qb-inventory') == 'started' then
            TriggerServerEvent('pl_fraud:server:OpenShopQB')
        end
    end

    if targetResource == 'ox_target' then
        exports.ox_target:addLocalEntity(shopped, {
            {
                label = "Open Shop",
                icon = "fa-solid fa-shop",
                onSelect = openShopAction
            }
        })

    elseif targetResource == 'qb-target' then
        exports['qb-target']:AddTargetEntity(shopped, {
            options = {
                {
                    type = "client",
                    event = "custom:openShop",
                    icon = "fa-solid fa-shop",
                    label = "Open Shop"
                }
            },
            distance = 2.0
        })

        RegisterNetEvent("custom:openShop", function()
            openShopAction()
        end)
    end
end)

-- Clean up on stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if DoesEntityExist(shopped) then
        DeleteEntity(shopped)
    end
end)
