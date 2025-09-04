local Inventory = {};
Inventory.__index = Inventory;

local Component = require(script.Parent.Parent.__Component);
setmetatable(Inventory, Component) 

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- / Imports:
local RPGs = require(script.Parent.Parent.Parent.Systems.Tools.RPGs);
local RPG_Schema = require(ReplicatedStorage.Schematics.RPGs)

-- / Functions
function Inventory.Construct(entity)
    local self = Component.Construct(entity, 'Inventory')
    setmetatable(self, Inventory)

    self.replicator = entity.Components.Replicator

    -- Inventory specific properties
    self.items = {};
    self.maxSlots = 30;
    self.equippedTool = nil;
    

    -- Add callable functions for networking
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
    print("[Inventory DEBUG] Loading inventory from profile data")
    
    if not profileData or not profileData.Inventory or not profileData.Inventory.Items then
        warn("[Inventory] No inventory data found in profile")
        return
    end
    
    local itemsData = profileData.Inventory.Items
    print("[Inventory DEBUG] Found", #itemsData, "items in profile data")
    
    -- Clear existing items (if any)
    self.items = {}
    
    -- Load each item from profile
    for i, itemData in ipairs(itemsData) do
        print("[Inventory DEBUG] Loading item:", itemData.id, "Class:", itemData.Class)
        
        -- Add the item directly without calling AddItem to avoid double validation
        -- and network updates during initialization
        if self:ValidateItem(itemData) then
            table.insert(self.items, itemData)
            print("[Inventory DEBUG] Successfully loaded item:", itemData.id)
        else
            warn("[Inventory] Failed to load item from profile:", itemData.id)
        end
    end
    
    -- Update max slots if specified in profile
    if profileData.Inventory.MaxSlots then
        self.maxSlots = profileData.Inventory.MaxSlots
    end
    
    print("[Inventory DEBUG] Finished loading inventory. Total items:", #self.items)
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
        warn("[Inventory] Invalid item data provided - missing id or type")
        return false
    end
    
    -- Check if it's an RPG and validate against schema
    if itemData.category == "rpg" and itemData.Class then
        local rpgData = RPG_Schema[itemData.Class]
        if not rpgData then
            warn("[Inventory] Invalid RPG class:", itemData.Class)
            return false
        end
        -- Merge schema data with item data
        itemData.schemaData = rpgData
    end
    
    return true
end

function Inventory:Initialize()
    print("[Inventory] Initializing inventory for:", self.Player.Name)
    
    -- Load inventory data from ProfileService
    if self.entity.Components.Data then
        local profileData = self.entity.Components.Data:GetData()
        if profileData then
            self:LoadFromProfileData(profileData)
        else
            warn("[Inventory] No profile data available during initialization")
        end
    else
        warn("[Inventory] No Data component found - cannot load inventory from profile")
    end
    
    -- DEBUG: Print final state
    print("[Inventory DEBUG] Total items after Initialize:", #self.items)
    
    -- DEBUG: Print all items
    for i, item in ipairs(self.items) do
        print("[Inventory DEBUG] Item", i, ":", item.id, "Class:", item.Class, "Category:", item.category)
    end
end

function Inventory:Deploy()
    print("[Inventory] Deploying inventory for:", self.Player.Name)
    
    -- DEBUG: Print inventory status at deploy
    print("[Inventory DEBUG] Items in inventory at Deploy:", #self.items)
    for i, item in ipairs(self.items) do
        print("[Inventory DEBUG] Deploy Item", i, ":", item.id, "Class:", item.Class)
    end
    
    -- Set up network bridge for inventory operations
    if self.entity.Components.Replicator then
        self:SetupNetworkStream('Inventory')
    end
    
    -- Send initial inventory data to client
    self:SendInventoryUpdate()
    
    -- Remove auto-equip logic - let player manually equip when they want
    print("[Inventory DEBUG] Inventory deployed without auto-equipping weapons")
end

--[=[
    function Inventory:AddItem
    Adds an item to the inventory
    
    @param itemData table The item data to add
    @return boolean Whether the item was added successfully
]=]
function Inventory:AddItem(itemData)
    print("[Inventory DEBUG] Attempting to add item:", itemData.id, "Class:", itemData.Class)
    
    if #self.items >= self.maxSlots then
        warn("[Inventory] Inventory full for player:", self.Player.Name)
        return false
    end
    
    -- Validate item data
    if not self:ValidateItem(itemData) then
        return false
    end
    
    table.insert(self.items, itemData)
    print("[Inventory] Added item:", itemData.id, "to", self.Player.Name)
    print("[Inventory DEBUG] Total items now:", #self.items)
    
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
    print("[Inventory DEBUG] Attempting to remove item:", itemId)
    
    for i, item in ipairs(self.items) do
        if item.id == itemId then
            -- If this item is currently equipped, unequip it first
            if self.equippedTool and self.equippedTool.ItemData.id == itemId then
                print("[Inventory DEBUG] Unequipping item before removal:", itemId)
                self:UnequipItem()
            end
            
            table.remove(self.items, i)
            print("[Inventory] Removed item:", itemId, "from", self.Player.Name)
            print("[Inventory DEBUG] Total items now:", #self.items)
            
            -- Also remove from ProfileService data
            if self.entity.Components.Data then
                self.entity.Components.Data:RemoveFromInventory(itemId)
            end
            
            self:SendInventoryUpdate()
            return true
        end
    end
    
    warn("[Inventory] Item not found:", itemId)
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
    print("[Inventory DEBUG] Attempting to equip item:", itemId)
    
    local item = self:GetItem(itemId)
    if not item then
        warn("[Inventory] Cannot equip - item not found:", itemId)
        print("[Inventory DEBUG] Available items:")
        for _, availableItem in ipairs(self.items) do
            print("  -", availableItem.id, "Class:", availableItem.Class)
        end
        return
    end
    
    print("[Inventory DEBUG] Found item to equip:", item.Class, "Category:", item.category)
    
    -- Currently only support RPG tools
    if item.category ~= "rpg" then
        warn("[Inventory] Cannot equip - unsupported item type:", item.type)
        return
    end
    
    -- Unequip current tool if any
    if self.equippedTool then
        print("[Inventory DEBUG] Unequipping current tool first")
        self:UnequipItem()
    end
    
    -- Equip the RPG using the RPGs system
    print("[Inventory DEBUG] Calling RPGs.EquipTool for:", item.Class)
    local toolData = RPGs.EquipTool(self.entity, item)
    if toolData then
        self.equippedTool = toolData
        print("[Inventory] Successfully equipped:", itemId, "for", self.Player.Name)
        print("[Inventory DEBUG] Equipped tool data:", toolData.ItemData.Class, "Ammo:", toolData.CurrentAmmo)
        self:SendInventoryUpdate()
    else
        warn("[Inventory] Failed to equip item:", itemId)
        print("[Inventory DEBUG] RPGs.EquipTool returned nil - check RPG system")
    end
end

--[=[
    function Inventory:UnequipItem
    Unequips the currently equipped item (networked function)
]=]
function Inventory:UnequipItem()
    if not self.equippedTool then
        warn("[Inventory] No item equipped to unequip")
        return
    end
    
    print("[Inventory DEBUG] Unequipping:", self.equippedTool.ItemData.id)
    RPGs.UnequipTool(self.entity, self.equippedTool)
    self.equippedTool = nil
    print("[Inventory] Unequipped item for", self.Player.Name)
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
    
    print("[Inventory DEBUG] GetInventoryData - Items:", #data.items, "Equipped:", data.equippedTool and data.equippedTool.class or "None")
    return data
end

--[=[
    function Inventory:SendInventoryUpdate
    Sends inventory update to the client
]=]
function Inventory:SendInventoryUpdate()
    if self.entity.Components.Replicator then
        local inventoryData = self:GetInventoryData()
        print("[Inventory DEBUG] Sending inventory update to client")
        self.entity.Components.Replicator:StreamToClient("Inventory", "InventoryUpdate", inventoryData)
    else
        print("[Inventory DEBUG] No Replicator component found - cannot send update")
    end
end

-- DEBUG: Add a function to print current inventory state
function Inventory:DebugPrintInventory()
    print("[Inventory DEBUG] ========== INVENTORY STATE ==========")
    print("[Inventory DEBUG] Player:", self.Player.Name)
    print("[Inventory DEBUG] Total Items:", #self.items)
    print("[Inventory DEBUG] Max Slots:", self.maxSlots)
    print("[Inventory DEBUG] Equipped Tool:", self.equippedTool and self.equippedTool.ItemData.Class or "None")
    
    for i, item in ipairs(self.items) do
        print(string.format("[Inventory DEBUG] Item %d: ID=%s, Class=%s, Category=%s", 
            i, item.id, item.Class or "Unknown", item.category or "Unknown"))
    end
    print("[Inventory DEBUG] =======================================")
end

return Inventory