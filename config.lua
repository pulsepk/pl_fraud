lib.locale()

Config = {}

Config.WaterMark = true

Config.Debug = false -- Set to true to enable debug messages

Config.UseObjectGizmo = false -- Set to true to use object gizmo for placing items Download: https://github.com/DemiAutomatic/object_gizmo

Config.Target = 'ox-target' --'qb-target', 'ox-target'

Config.Notify = 'ox' --'ox', 'esx', 'okok','qb','wasabi','brutal_notify','mythic_notify','custom'

-- Item names (can be modified to match your server's item names)
Config.Items = {
    laptop = "laptop",
    printer = "printer",
    generator = "generator",
    fuelCan = "fuelcan",
    cloneCard = "clone_card"
}

Config.Hacking = {
    Minigame = 'datacrack', --'datacrack','ps-ui-circle','ps-ui-maze','ps-ui-scrambler'
}

Config.Rewards = {
    EnableBlackMoney = true,
    amount = 100,
    moneytype = 'black_money', -- Can be 'money','black_money','markedbills'
}

-- General settings
Config.RequiredFuel = 100 -- Amount of fuel needed for the generator
Config.ProximityDistance = 2.0 -- Maximum distance between items to be considered "close"
Config.ProcessTime = 3000

-- Prop names when placing items on the ground
Config.Props = {
    laptop = "prop_laptop_01a",
    printer = "prop_printer_01",
    generator = "prop_generator_01a"
}

Config.Police= {
    Job = 'police', -- Job name for police
}

Config.atmModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}
-- Target options
Config.TargetOptions = {
    laptop = {
        icon = "fas fa-laptop-code",
        label = "Use Laptop"
    },
    generator = {
        icon = "fas fa-bolt",
        label = "Fuel Generator"
    },
    printer = {
        icon = "fas fa-bolt",
        label = "Collect Card"
    },
    remove = {
        icon = "fas fa-trash",
        label = "Remove Object"
    }
}

--'ps' for ps-dispatch
--'aty' for aty_disptach | Free https://github.com/atiysuu/aty_dispatch
--'qs' for qausar dispatch
--'rcore' for rcore dispatch
--'op' for op-dispatch | Free https://github.com/ErrorMauw/op-dispatch
--custom for your own

Config.Dispatch= {
    enable = false,
    script = 'op'
}

