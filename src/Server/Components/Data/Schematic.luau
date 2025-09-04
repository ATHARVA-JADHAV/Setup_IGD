-- Data schema for ProfileService
-- This defines the default structure and values for player data

local schematic = {
    Currencies = {
        Cash = 1000,    -- Starting cash
        Gems = 50       -- Starting gems
    },
    
    Inventory = {},     -- Array of inventory items
    
    Level = 1,          -- Player level
    Experience = 0,     -- Current experience points
    
    -- Timestamps
    lastjoined = 0,     -- Last join timestamp
    created = 0,        -- Account creation timestamp
    
}

return schematic