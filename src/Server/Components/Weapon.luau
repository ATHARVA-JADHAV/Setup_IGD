
local Weapon = {};
Weapon.__index = Weapon;

local Component = require(script.Parent.__Component);
setmetatable(Weapon, Component) 

-- / Imports:

local RPGs = require(script.Parent.Parent.Systems.Tools.RPGs);

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage')


-- / Functions
function Weapon.Construct(entity)
    local self = Component.Construct(entity, 'Weapon');
    setmetatable(self, Weapon);

    -- Weapon specific properties
    self.equippedWeapon = nil;
    self.weaponType = nil; -- "rpg", "gun", etc.
    
    self.replicator = entity.Components and entity.Components.Replicator or nil

    -- Add callable functions for networking
    self.callable_functions = {
        'Fire',
        'Reload',
        'GetWeaponStatus'
    };

    return self
end

function Weapon:Initialize()
    print("[Weapon] Initializing weapon component for:", self.Player.Name)
end

function Weapon:Deploy()
    print("[Weapon] Deploying weapon component for:", self.Player.Name)
    
    -- Set up network bridge for weapon operations
    if self.entity.Components.Replicator then
        self:SetupNetworkStream('Weapon')
    end
end

--[=[
    function Weapon:EquipWeapon
    Equips a weapon based on item data
    
    @param itemData table The weapon item data
    @return boolean Whether the weapon was equipped successfully
]=]
function Weapon:EquipWeapon(itemData)
    -- Unequip current weapon if any
    if self.equippedWeapon then
        self:UnequipWeapon()
    end
    
    local success = false
    
    -- Handle different weapon types
    if itemData.category == "rpg" then
        local toolData = RPGs.EquipTool(self.entity, itemData)
        if toolData then
            self.equippedWeapon = toolData
            self.weaponType = "rpg"
            success = true
        end
    end
    -- Add more weapon types here (guns, melee, etc.)
    
    if success then
        print("[Weapon] Equipped", itemData.Class, "for", self.Player.Name)
    else
        warn("[Weapon] Failed to equip weapon:", itemData.Class)
    end
    
    return success
end

--[=[
    function Weapon:UnequipWeapon
    Unequips the currently equipped weapon
    
    @return boolean Whether the weapon was unequipped successfully
]=]
function Weapon:UnequipWeapon()
    if not self.equippedWeapon then
        return true -- Already unequipped
    end
    
    local success = false
    
    -- Handle different weapon types
    if self.weaponType == "rpg" then
        RPGs.UnequipTool(self.entity, self.equippedWeapon)
        success = true
    end
    -- Add more weapon types here
    
    if success then
        self.equippedWeapon = nil
        self.weaponType = nil
        print("[Weapon] Unequipped weapon for", self.Player.Name)
    end
    
    return success
end

--[=[
    function Weapon:Fire
    Fires the currently equipped weapon (networked function)
    
    @return boolean Whether the weapon was fired successfully
]=]
function Weapon:Fire()
    if not self.equippedWeapon then
        return false
    end
    
    local success = false
    
    -- Handle different weapon types
    if self.weaponType == "rpg" then
        success = RPGs.FireRPG(self.entity)
    end
    -- Add more weapon types here
    
    return success
end

--[=[
    function Weapon:Reload
    Reloads the currently equipped weapon (networked function)
    
    @return boolean Whether the reload was started successfully
]=]
function Weapon:Reload()
    if not self.equippedWeapon then
        return false
    end
    
    local success = false
    
    -- Handle different weapon types
    if self.weaponType == "rpg" then
        success = RPGs.ReloadRPG(self.entity)
    end
    -- Add more weapon types here
    
    return success
end

--[=[
    function Weapon:GetWeaponStatus
    Gets the current weapon status (networked function)
    
    @return table The weapon status data
]=]
function Weapon:GetWeaponStatus()
    if not self.equippedWeapon then
        return {
            equipped = false
        }
    end
    
    local status = {
        equipped = true,
        weaponType = self.weaponType,
        itemData = self.equippedWeapon.ItemData
    }
    
    -- Add weapon-specific status info
    if self.weaponType == "rpg" then
        status.currentAmmo = self.equippedWeapon.CurrentAmmo
        status.maxAmmo = self.equippedWeapon.RPGData.MaxAmmo
        status.isReloading = self.equippedWeapon.IsReloading
        status.damage = self.equippedWeapon.RPGData.Damage
        status.reloadTime = self.equippedWeapon.RPGData.ReloadTime
    end
    
    return status
end

--[=[
    function Weapon:HasWeaponEquipped
    Checks if the player has a weapon equipped
    
    @return boolean Whether a weapon is equipped
]=]
function Weapon:HasWeaponEquipped()
    return self.equippedWeapon ~= nil
end

--[=[
    function Weapon:GetWeaponType
    Gets the type of currently equipped weapon
    
    @return string? The weapon type or nil if none equipped
]=]
function Weapon:GetWeaponType()
    return self.weaponType
end

return Weapon