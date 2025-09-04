local Inventory = {};
Inventory.__index = Inventory;

local Component = require(script.Parent.Parent.__Component);
setmetatable(Inventory, Component) 

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- / Imports:
local DebugManager = require(ReplicatedStorage.Modules.DebugManager);   
local RPGs = require(script.Parent.Parent.Parent.Systems.Tools.RPGs);
local RPG_Schema = require(ReplicatedStorage.Schematics.RPGs)

-- / Functions
function Inventory.Construct(entity)
    local self = Component.Construct(entity, 'Inventory')
    setmetatable(self, Inventory)

    self.replicator = entity.Components.Replicator

    self.items = {};
    self.maxSlots = 30;
    self.equippedTool = nil;
    
    self.callable_functions = {
        'EquipItem',
        'UnequipItem',
        'GetInventoryData',
        'AddItem',
        'RemoveItem'
    };

    return self
end

--[=[
    function Inventory:LoadFromProfileData
    Loads inventory items from ProfileService data
    
    @param profileData table The profile data from ProfileService
]=]

function Inventory:LoadFromProfileData(profileData)
    DebugManager.print('INVENTORY',"Loading inventory from profile data")
    
    if not profileData or not profileData.Inventory or not profileData.Inventory.Items then
        DebugManager.warn('INVENTORY',"No inventory data found in profile")
        return
    end
    
    local itemsData = profileData.Inventory.Items
    DebugManager.print('INVENTORY',"Found", #itemsData, "items in profile data")
    
    self.items = {}
    
    -- Load each item from profile
    for i, itemData in ipairs(itemsData) do
        DebugManager.print('INVENTORY',"Loading item:", itemData.id, "Class:", itemData.Class)
        
        if self:ValidateItem(itemData) then
            table.insert(self.items, itemData)
            DebugManager.print('INVENTORY',"Successfully loaded item:", itemData.id)
        else
            DebugManager.warn('INVENTORY',"Failed to load item from profile:", itemData.id)
        end
    end
    
    -- Update max slots if specified in profile
    if profileData.Inventory.MaxSlots then
        self.maxSlots = profileData.Inventory.MaxSlots
    end
    
    DebugManager.print('INVENTORY',"Finished loading inventory. Total items:", #self.items)
end

--[=[
    function Inventory:ValidateItem
    Validates an item data structure
    
    @param itemData table The item data to validate
    @return boolean Whether the item is valid
]=]

function Inventory:ValidateItem(itemData)
    -- Validate basic item data
    if not itemData.id or not itemData.type then
        DebugManager.warn('INVENTORY',"Invalid item data provided - missing id or type")
        return false
    end
    
    if itemData.category == "rpg" and itemData.Class then
        local rpgData = RPG_Schema[itemData.Class]
        if not rpgData then
            DebugManager.warn('INVENTORY',"Invalid RPG class:", itemData.Class)
            return false
        end
        -- Merge schema data with item data
        itemData.schemaData = rpgData
    end
    
    return true
end

function Inventory:Initialize()
    DebugManager.print('INVENTORY',"Initializing inventory for:", self.Player.Name)
    
    -- Load inventory data from ProfileService
    if self.entity.Components.Data then
        local profileData = self.entity.Components.Data:GetData()
        if profileData then
            self:LoadFromProfileData(profileData)
        else
            DebugManager.warn('INVENTORY',"No profile data available during initialization")
        end
    else
        DebugManager.warn('INVENTORY',"No Data component found - cannot load inventory from profile")
    end
    
    DebugManager.print('INVENTORY',"Total items after Initialize:", #self.items)
    
    for i, item in ipairs(self.items) do
        DebugManager.print('INVENTORY',"Item", i, ":", item.id, "Class:", item.Class, "Category:", item.category)
    end
end

function Inventory:Deploy()
   DebugManager.print('INVENTORY',"Deploying inventory for:", self.Player.Name)
    
    -- DEBUG: Print inventory status at deploy
    DebugManager.print('INVENTORY',"Items in inventory at Deploy:", #self.items)
    for i, item in ipairs(self.items) do
        DebugManager.print('INVENTORY',"Deploy Item", i, ":", item.id, "Class:", item.Class)
    end
    
    -- Set up network bridge for inventory operations
    if self.entity.Components.Replicator then
        self:SetupNetworkStream('Inventory')
    end
    
    -- Send initial inventory data to client
    self:SendInventoryUpdate()
    
    -- Remove auto-equip logic - let player manually equip when they want
    DebugManager.print('INVENTORY',"Inventory deployed without auto-equipping weapons")
end

--[=[
    function Inventory:AddItem
    Adds an item to the inventory
    
    @param itemData table The item data to add
    @return boolean Whether the item was added successfully
]=]

function Inventory:AddItem(itemData)
    DebugManager.print('INVENTORY',"Attempting to add item:", itemData.id, "Class:", itemData.Class)
    
    if #self.items >= self.maxSlots then
        DebugManager.warn('INVENTORY',"Inventory full for player:", self.Player.Name)
        return false
    end
    
    -- Validate item data
    if not self:ValidateItem(itemData) then
        return false
    end
    
    table.insert(self.items, itemData)
    DebugManager.print('INVENTORY',"Added item:", itemData.id, "to", self.Player.Name)
    DebugManager.print('INVENTORY',"Total items now:", #self.items)
    
    self:SendInventoryUpdate()
    return true
end

--[=[
    function Inventory:RemoveItem
    Removes an item from the inventory by ID
    
    @param itemId string The ID of the item to remove
    @return boolean Whether the item was removed successfully
]=]

function Inventory:RemoveItem(itemId)
    DebugManager.print('INVENTORY',"Attempting to remove item:", itemId)
    
    for i, item in ipairs(self.items) do
        if item.id == itemId then
            -- If item is currently equipped, unequip it first
            if self.equippedTool and self.equippedTool.ItemData.id == itemId then
                DebugManager.print('INVENTORY',"Unequipping item before removal:", itemId)
                self:UnequipItem()
            end
            
            table.remove(self.items, i)
            DebugManager.print('INVENTORY',"Removed item:", itemId, "from", self.Player.Name)
            DebugManager.print('INVENTORY',"Total items now:", #self.items)
            
            if self.entity.Components.Data then
                self.entity.Components.Data:RemoveFromInventory(itemId)
            end
            
            self:SendInventoryUpdate()
            return true
        end
    end
    
    DebugManager.warn('INVENTORY',"Item not found:", itemId)
    return false
end

--[=[
    function Inventory:GetItem
    Gets an item from inventory by ID
    
    @param itemId string The ID of the item to get
    @return table? The item data or nil if not found
]=]

function Inventory:GetItem(itemId)
    for _, item in ipairs(self.items) do
        if item.id == itemId then
            return item
        end
    end
    return nil
end

--[=[
    function Inventory:EquipItem
    Equips an item (networked function callable from client)
    
    @param itemId string The ID of the item to equip
]=]

function Inventory:EquipItem(itemId)
    
    local item = self:GetItem(itemId)
    if not item then
        DebugManager.warn('INVENTORY',"Cannot equip - item not found:", itemId)
        for _, availableItem in ipairs(self.items) do
            DebugManager.print('INVENTORY',"-", availableItem.id, "Class:", availableItem.Class)
        end
        return
    end
    
    DebugManager.print('INVENTORY',"Found item to equip:", item.Class, "Category:", item.category)
    
    -- Currently only support RPG tools
    if item.category ~= "rpg" then
        DebugManager.warn('INVENTORY',"Cannot equip - unsupported item type:", item.type)
        return
    end
    
    if self.equippedTool then

        self:UnequipItem()
    end
    
    -- Equip the RPG tool via the RPGs system
    
    local toolData = RPGs.EquipTool(self.entity, item)
    if toolData then
        self.equippedTool = toolData
        DebugManager.print('INVENTORY',"Successfully equipped:", itemId, "for", self.Player.Name)
        self:SendInventoryUpdate()
    else
        DebugManager.warn('INVENTORY',"Failed to equip item:", itemId)
        DebugManager.print('INVENTORY',"RPGs.EquipTool returned nil - check RPG system")
    end
end

--[=[
    function Inventory:UnequipItem
    Unequips the currently equipped item (networked function)
]=]

function Inventory:UnequipItem()
    if not self.equippedTool then
        DebugManager.warn('INVENTORY',"No item equipped to unequip")
        return
    end
    
    RPGs.UnequipTool(self.entity, self.equippedTool)
    self.equippedTool = nil
    DebugManager.print('INVENTORY',"Unequipped item for", self.Player.Name)
    self:SendInventoryUpdate()
end

--[=[
    function Inventory:GetInventoryData
    Gets the current inventory data (networked function)
    
    @return table The inventory data to send to client
]=]

function Inventory:GetInventoryData()
    local data = {
        items = self.items,
        maxSlots = self.maxSlots,
        equippedTool = self.equippedTool and {
            id = self.equippedTool.ItemData.id,
            class = self.equippedTool.ItemData.Class,
            currentAmmo = self.equippedTool.CurrentAmmo,
            maxAmmo = self.equippedTool.RPGData.MaxAmmo,
            isReloading = self.equippedTool.IsReloading
        } or nil
    }
    
    DebugManager.print('INVENTORY',"GetInventoryData - Items:", #data.items, "Equipped:", data.equippedTool and data.equippedTool.class or "None")
    return data
end

--[=[
    function Inventory:SendInventoryUpdate
    Sends inventory update to the client
]=]
function Inventory:SendInventoryUpdate()
    if self.entity.Components.Replicator then
        local inventoryData = self:GetInventoryData()
        self.entity.Components.Replicator:StreamToClient("Inventory", "InventoryUpdate", inventoryData)
    else
    end
end

-- DEBUG: Add a function to print current inventory state
function Inventory:DebugPrintInventory()
    DebugManager.print('INVENTORY',"Player:", self.Player.Name)
    DebugManager.print('INVENTORY',"Total Items:", #self.items)
    DebugManager.print('INVENTORY',"Max Slots:", self.maxSlots)
    DebugManager.print('INVENTORY',"Equipped Tool:", self.equippedTool and self.equippedTool.ItemData.Class or "None")
    
    for i, item in ipairs(self.items) do
        print(string.format("[Inventory DEBUG] Item %d: ID=%s, Class=%s, Category=%s", 
            i, item.id, item.Class or "Unknown", item.category or "Unknown"))
    end
end

return Inventory