-- Data schema for ProfileService
-- This defines the default structure and values for player data

local schematic = {
    Currencies = {
        Cash = 1000,    -- Starting cash
        Gems = 50       -- Starting gems
    },
    
    Inventory = {
        Items = {       -- Default items every new player gets
            {
                id = "default_rpg_001",
                Class = "BasicRPG",  
                type = "tool",
                category = "rpg",
                quantity = 1,
                data = {}
            }
        },     
        MaxSlots = 30,  -- Maximum inventory slots
        LastItemId = 1  
    },
    
    Equipment = {
        EquippedWeapon = nil 
    },
    
    Stats = {
        Level = 1,          -- Player level
        Experience = 0,     -- Current experience points
        TotalKills = 0,     -- Total enemy kills
        TotalDeaths = 0,    -- Total deaths
        PlayTime = 0        -- Total play time in seconds
    },
    
    Weapons = {
        UnlockedWeapons = { -- List of unlocked weapon classes
            "BasicRPG"      -- Starting weapon - always unlocked
        },
        WeaponStats = {}    -- Per-weapon statistics {[weaponClass] = {kills, shots, accuracy}}
    },
    
    -- Session data (not saved, reset each session)
    Session = {
        JoinTime = 0,       -- When player joined this session
        SessionKills = 0,   -- Kills this session
        SessionDeaths = 0   -- Deaths this session
    },
    
    -- Timestamps
    Timestamps = {
        LastJoined = 0,     -- Last join timestamp
        Created = 0,        -- Account creation timestamp
        LastSave = 0        -- Last data save timestamp
    }
}

return schematic