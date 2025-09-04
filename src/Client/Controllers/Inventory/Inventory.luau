-- Client-side inventory handler
local Inventory = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- /Imports
local DebugManager = require(ReplicatedStorage.Modules.DebugManager)


function Inventory:Initialize()
    DebugManager:Log("Inventory system initialized.")
end

function Inventory.UpdateItemState(itemIndex, isEquipped)
    -- Update UI to show item as equipped/unequipped
    -- Change button appearance, add glow effects, etc.
end

function Inventory.AddItem(itemData)
    -- Add new item to client inventory UI
    -- Create inventory slot, set up click handlers
end

function Inventory.RemoveItem(index)
    -- Remove item from client UI
    -- Shift remaining items, update indices
end

return Inventory