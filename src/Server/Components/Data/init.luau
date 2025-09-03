local DataComponent = {}
DataComponent.__index = DataComponent;

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

-- / Imports:
local Component = require(script.Parent.__Component);
setmetatable(DataComponent, Component);

local ProfileService = require(script.ProfileService);
local schematic = require(script.Schematic);

-- ProfileStore with your specified version
local Store = ProfileService.GetProfileStore(`v/taf/dev_02|A`, schematic)

-- / Functions:
function DataComponent.Construct(entity)
    local self = setmetatable(Component.Construct(entity, 'Data'), DataComponent)
    
    self.profile = {};
    self.replica = {};
    self.data_loaded = false;
    
    return self
end

function DataComponent:_Initialize()
    local player = self.Player;
    
    print("[DataComponent] Loading profile for player:", player.Name, "UserId:", player.UserId)
    
    -- Load the player's profile
    local profile = Store:LoadProfileAsync("Player_" .. tostring(player.UserId))
    
    -- Check if profile loaded successfully and player is still in game
    if not profile then
        warn("[DataComponent] Failed to load profile for:", player.Name)
        player:Kick("Failed to load data. Please rejoin.")
        return
    end
    
    if not player.Parent then -- Player left during loading
        profile:Release()
        return
    end
    
    -- Reconcile profile data with schema (adds missing keys, removes obsolete ones)
    profile:Reconcile()
    
    -- Set up profile release handler
    profile:ListenToRelease(function()
        player:Kick("Data session ended. Please rejoin.")
    end)
    
    -- Store profile and data references
    self.profile = profile
    self.replica = profile.Data
    self.data_loaded = true
    
    -- Update last joined time
    self.replica.lastjoined = os.time()
    
    print("[DataComponent] Profile loaded successfully for:", player.Name)
    print("[DataComponent] Current Cash:", self.replica.Currencies.Cash)
    print("[DataComponent] Current Gems:", self.replica.Currencies.Gems)
    print("[DataComponent] Inventory items:", #self.replica.Inventory)
    
    return 'Loaded'
end

function DataComponent:Initialize()
    print("[DataComponent] Component initialized for:", self.Player.Name)
end

function DataComponent:Deploy()
    print("[DataComponent] Component deployed for:", self.Player.Name)
end

function DataComponent:EditCurrency(currency, operation, difference)
    if not self.data_loaded then
        warn("[DataComponent] Data not loaded yet for player:", self.Player.Name)
        return
    end
    
    if not self.replica.Currencies[currency] then
        warn("[DataComponent] Currency not found:", currency)
        return
    end
    
    local current = self.replica.Currencies[currency]
    local replicator = self.entity:GetComponents('Replicator')
    
    if not replicator then
        warn("[DataComponent] No replicator found")
        return
    end
    
    local operations = {
        Add = function()
            current = current + difference
        end,
        Deduct = function()
            current = current - difference
        end
    }
    
    if not operations[operation] then
        warn("[DataComponent] Invalid operation:", operation)
        return
    end
    
    operations[operation]()
    
    -- Ensure non-negative values and update replica
    current = math.max(0, current)
    self.replica.Currencies[currency] = math.ceil(current)
    
    print(string.format("[DataComponent] %s %s %d. New balance: %d", 
        operation, currency, difference, self.replica.Currencies[currency]))
    
    -- Update the client via replicator
    replicator:StreamToClient('_self', {
        Controller = 'Currency',
        Function = 'UpdateCurrency',
        Args = {currency, self.replica.Currencies[currency]}
    })
end

function DataComponent:AddToInventory(item)
    if not self.data_loaded then
        warn("[DataComponent] Data not loaded yet")
        return
    end
    
    -- Ensure inventory exists
    if not self.replica.Inventory then
        self.replica.Inventory = {}
    end
    
    -- Add UUID if not present
    if not item.UUID then
        item.UUID = game:GetService("HttpService"):GenerateGUID(false)
    end
    
    -- Add index
    item.Index = #self.replica.Inventory + 1
    
    table.insert(self.replica.Inventory, item)
    print("[DataComponent] Added item to inventory:", item.Name or item.UUID)
    
    -- Notify inventory component if it exists
    local inventoryComponent = self.entity:GetComponent('Inventory')
    if inventoryComponent and inventoryComponent.AddItem then
        inventoryComponent:AddItem(item)
    end
end

function DataComponent:RemoveFromInventory(index)
    if not self.data_loaded then
        warn("[DataComponent] Data not loaded yet")
        return
    end
    
    if not self.replica.Inventory[index] then
        warn("[DataComponent] No item at inventory index:", index)
        return
    end
    
    local removedItem = table.remove(self.replica.Inventory, index)
    
    -- Update indices for remaining items
    for i = index, #self.replica.Inventory do
        self.replica.Inventory[i].Index = i
    end
    
    print("[DataComponent] Removed item from inventory:", removedItem.Name or removedItem.UUID)
    
    return removedItem
end

function DataComponent:GetCurrency(currency)
    if not self.data_loaded then
        return 0
    end
    return self.replica.Currencies and self.replica.Currencies[currency] or 0
end

function DataComponent:GetInventory()
    if not self.data_loaded then
        return {}
    end
    return self.replica.Inventory or {}
end

function DataComponent:GetLevel()
    if not self.data_loaded then
        return 1
    end
    return self.replica.Level or 1
end

function DataComponent:AddExperience(amount)
    if not self.data_loaded then
        return
    end
    
    self.replica.Experience = (self.replica.Experience or 0) + amount
    print("[DataComponent] Added", amount, "experience. Total:", self.replica.Experience)
    
    -- You can add level-up logic here
end

-- Generates data tuple to send to client
function DataComponent:_GenerateReplicableTuple()
    if not self.data_loaded then
        warn("[DataComponent] Trying to generate tuple but data not loaded")
        return {}
    end
    
    print("[DataComponent] Generating replicable data for:", self.Player.Name)
    print("[DataComponent] Cash:", self.replica.Currencies.Cash)
    print("[DataComponent] Gems:", self.replica.Currencies.Gems)
    print("[DataComponent] Inventory items:", #self.replica.Inventory)
    
    return self.replica
end

function DataComponent:Release()
    print("[DataComponent] Releasing profile for:", self.Player.Name)
    
    -- Release the ProfileService profile (this saves the data)
    if self.profile and self.profile.Release then
        self.profile:Release()
    end
    
    self.data_loaded = false
    self.replica = {}
    self.profile = {}
end

return DataComponent