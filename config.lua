lib.locale()

Config = {}

Config.WaterMark = true

Config.Debug = false -- Set to true to enable debug messages

Config.UseObjectGizmo = false -- Set to true to use object gizmo for placing items Download: https://github.com/DemiAutomatic/object_gizmo

Config.Shop = {
    Enable = true,
    id = "frauditems", -- Shop identifier
    name = "Fraud Market", -- Display name
    coords = vec3(430.1993, -1559.3730, 32.8),
    heading = 319.6178,
    pedModel = "a_m_m_og_boss_01", -- Change to any ped model
    blip = {
        enabled = true,
        sprite = 59, -- Shop blip icon
        color = 2,  -- Green
        scale = 0.8
    }
}

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
    amount = 100,
    moneytype = 'black_money', -- Can be 'money','black_money','markedbills'
}

-- General settings
Config.RequiredFuel = 10          -- Amount of fuel needed for the generator
Config.ProximityDistance = 2.0    -- Maximum distance between items to be considered "close"
Config.ProcessTime = 3000

-- Object placement controls (manual mode only — not used when UseObjectGizmo = true)
-- Controls: [← →] Rotate  [↑ ↓] Height  [Scroll] Coarse rotate  [E/Enter] Place  [Backspace] Cancel
Config.Placing = {
    Distance      = 4.0,    -- max forward distance the object can be placed (metres)
    RotationSpeed = 2.0,    -- degrees rotated per frame while holding ← or →
    HeightStep    = 0.015,  -- metres moved per frame while holding ↑ or ↓
}

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

-- Dispatch script is auto-detected by pl_lib (ps-dispatch, aty_dispatch, qs-dispatch, rcore_dispatch, op-dispatch, etc.)
Config.Dispatch = {
    enable = false,
}

