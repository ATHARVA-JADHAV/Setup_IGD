local DataComponent = {}
DataComponent.__index = DataComponent;

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');

-- / Imports:
local DebugManager = require(ReplicatedStorage.Modules.DebugManager);
local Component = require(script.Parent.__Component);
setmetatable(DataComponent, Component);

local ProfileService = require(script.ProfileService);
local schematic = require(script.Schematic);

local Store = ProfileService.GetProfileStore(`v/taf/dev_04|A`, schematic)

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
    
    DebugManager.print('DATA', "Loading profile for player:", player.Name, "UserId:", player.UserId)    

    local profile = Store:LoadProfileAsync("Player_" .. tostring(player.UserId))
    
    if not profile then
        DebugManager.warn('DATA', "Failed to load profile for:", player.Name)
        player:Kick("Failed to load data. Please rejoin.")
        return
    end
     
    if not player.Parent then 
        profile:Release()
        return
    end
    
    -- Reconcile profile data with schema (adds missing keys, removes obsolete ones)
    profile:Reconcile()
    
    -- Set up profile release handler
    profile:ListenToRelease(function()
        player:Kick("Data session ended. Please rejoin.")
    end)
    
    self.profile = profile
    self.replica = profile.Data
    self.data_loaded = true
    
    -- Update last joined time
    self.replica.Timestamps.LastJoined = os.time()
    
    DebugManager.print('DATA', "Profile loaded successfully for:", player.Name)
    DebugManager.print('DATA', "Current Cash:", self.replica.Currencies.Cash)
    DebugManager.print('DATA', "Current Gems:", self.replica.Currencies.Gems)
    DebugManager.print('DATA', "Inventory items:", #self.replica.Inventory.Items) -- Fixed: Access Items array
    
    return 'Loaded'
end

function DataComponent:Initialize()
    DebugManager.print('DATA',"Component initialized for:", self.Player.Name)
end

function DataComponent:Deploy()
   DebugManager.print('DATA',"Component deployed for:", self.Player.Name)
end

function DataComponent:GetData()
    if not self.data_loaded then
        return nil
    end
    return self.replica
end

function DataComponent:EditCurrency(currency, operation, difference)
    if not self.data_loaded then
        DebugManager.warn('DATA',"Data not loaded yet for player:", self.Player.Name)
        return
    end
    
    if not self.replica.Currencies[currency] then
        DebugManager.warn('DATA',"Currency not found:", currency)
        return
    end
    
    local current = self.replica.Currencies[currency]
    local replicator = self.entity:GetComponents('Replicator')
    
    if not replicator then
        DebugManager.warn('DATA',"No replicator found")
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
    
    if not self.replica.Inventory or not self.replica.Inventory.Items then
        if not self.replica.Inventory then
            self.replica.Inventory = {}
        end
        self.replica.Inventory.Items = {}
    end
    
    if not item.id then
        self.replica.Inventory.LastItemId = (self.replica.Inventory.LastItemId or 0) + 1
        item.id = string.format("item_%03d", self.replica.Inventory.LastItemId)
    end
    
    table.insert(self.replica.Inventory.Items, item)
    DebugManager.print('DATA',"Added item to inventory:", item.id, "Class:", item.Class)
    
    -- Notify inventory component if it exists
    local inventoryComponent = self.entity:GetComponent('Inventory')
    if inventoryComponent and inventoryComponent.AddItem then
        inventoryComponent:AddItem(item)
    end
end

function DataComponent:RemoveFromInventory(itemId)
    if not self.data_loaded then
        warn("[DataComponent] Data not loaded yet")
        return
    end
    
    if not self.replica.Inventory or not self.replica.Inventory.Items then
        warn("[DataComponent] No inventory items to remove")
        return
    end
    
    for i, item in ipairs(self.replica.Inventory.Items) do
        if item.id == itemId then
            local removedItem = table.remove(self.replica.Inventory.Items, i)
            DebugManager.print('DATA',"Removed item from inventory:", removedItem.id)
            return removedItem
        end
    end
    
    warn("[DataComponent] Item not found in inventory:", itemId)
    return nil
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
    return self.replica.Inventory and self.replica.Inventory.Items or {}
end

function DataComponent:GetLevel()
    if not self.data_loaded then
        return 1
    end
    return self.replica.Stats and self.replica.Stats.Level or 1
end

function DataComponent:AddExperience(amount)
    if not self.data_loaded then
        return
    end
    
    if not self.replica.Stats then
        self.replica.Stats = {Level = 1, Experience = 0}
    end
    
    self.replica.Stats.Experience = (self.replica.Stats.Experience or 0) + amount
    DebugManager.print('DATA',"Added", amount, "experience. Total:", self.replica.Stats.Experience)
    
    -- can add level-up logic here
end

-- Generates data tuple to send to client
function DataComponent:_GenerateReplicableTuple()
    if not self.data_loaded then
        warn("[DataComponent] Trying to generate tuple but data not loaded")
        return {}
    end
    
    DebugManager.print('DATA',"Generating replicable data for:", self.Player.Name)
    DebugManager.print('DATA',"Cash:", self.replica.Currencies.Cash)
    DebugManager.print('DATA',"Gems:", self.replica.Currencies.Gems)
    DebugManager.print('DATA',"Inventory items:", self.replica.Inventory and #self.replica.Inventory.Items or 0)
    
    return self.replica
end

function DataComponent:Release()
    DebugManager.print('DATA',"Releasing profile for:", self.Player.Name)
    
    -- Release the ProfileService profile 
    if self.profile and self.profile.Release then
        self.profile:Release()
    end
    
    self.data_loaded = false
    self.replica = {}
    self.profile = {}
end

return DataComponent