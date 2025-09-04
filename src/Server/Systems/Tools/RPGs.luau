local RPGs = {};    
RPGs.__index = RPGs;

--/ Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')

--/ Assets
local RPG_Assets = ReplicatedStorage.Assets.Tools;

--/ Imports
local RPG_Schema = require(ReplicatedStorage.Schematics.RPGs);

-- / System State
RPGs.equippedTools = {}; -- Track equipped tools per player
RPGs.initialized = false;

-- / Functions:

--[=[
    function RPGs.Initialize
    Initializes the RPG system - called by server script
]=]
function RPGs.Initialize()
    if RPGs.initialized then
        warn("[RPGs] System already initialized")
        return
    end
    
    print("[RPGs] Initializing RPG Tool System...")
    
    -- Validate RPG assets exist
    RPGs._ValidateAssets()
    
    -- Set up cleanup for player leaving
    game.Players.PlayerRemoving:Connect(function(player)
        RPGs._CleanupPlayer(player)
    end)
    
    RPGs.initialized = true
    print("[RPGs] RPG Tool System initialized successfully")
end

--[=[
    function RPGs._ValidateAssets
    Private function to validate that all RPG assets exist
]=]
function RPGs._ValidateAssets()
    local missingAssets = {}
    
    for className, data in pairs(RPG_Schema) do
        local assetModel = RPG_Assets:FindFirstChild(data.ModelName)
        if not assetModel then
            table.insert(missingAssets, data.ModelName)
        end
    end
    
    if #missingAssets > 0 then
        warn("[RPGs] Missing RPG assets:", table.concat(missingAssets, ", "))
    else
        print("[RPGs] All RPG assets validated successfully")
    end
end

--[=[
    function RPGs._CleanupPlayer
    Private function to clean up player data when they leave
    
    @param player Player The player leaving
]=]
function RPGs._CleanupPlayer(player)
    if RPGs.equippedTools[player.UserId] then
        print("[RPGs] Cleaning up equipped tools for player:", player.Name)
        RPGs.equippedTools[player.UserId] = nil
    end
end

--[=[
    function RPGs.GetRPGData
    Gets RPG data from schema by class name
    
    @param className string The RPG class name
    @return table? The RPG data or nil if not found
]=]
function RPGs.GetRPGData(className)
    return RPG_Schema[className]
end

--[=[
    function RPGs.EquipTool
    Equips an RPG tool to a player by attaching it to their right hand

    @param entity table The player entity
    @param itemData table The RPG item data containing Class field
    @return table? The equipped tool data or nil if failed
]=]
function RPGs.EquipTool(entity, itemData)
    local player = entity.Player
    local character = player.Character
    if not character then
        warn("[RPGs] No character found for player:", player.Name)
        return nil
    end

    -- Check if player already has an RPG equipped
    local playerId = player.UserId
    if RPGs.equippedTools[playerId] then
        warn("[RPGs] Player", player.Name, "already has an RPG equipped")
        return nil
    end

    -- Find the right hand for RPG attachment
    local rightHand = character:FindFirstChild('Right Arm') or character:FindFirstChild('RightHand')
    if not rightHand then
        warn("[RPGs] No right hand found in character")
        return nil
    end

    -- Get the RPG model and data
    local RPGClass = itemData.Class
    local rpgData = RPG_Schema[RPGClass]
    if not rpgData then
        warn("[RPGs] No RPG data found for class:", RPGClass)
        return nil
    end
    
    local RPGModel = RPG_Assets:FindFirstChild(rpgData.ModelName)
    if not RPGModel then
        warn("[RPGs] No RPG model found for class:", RPGClass, "Model name:", rpgData.ModelName)
        return nil
    end

    -- Clone and position the RPG
    local clonedRPG = RPGModel:Clone()
    clonedRPG.Name = '__EQUIPPED_RPG'
    clonedRPG.Parent = character

    -- Position the RPG at the right hand (fixed the variable name bug)
    local handle = clonedRPG:WaitForChild("Handle") -- every Tool should have one

    -- Position the handle instead of the tool itself
    handle.CFrame = rightHand.CFrame * CFrame.new(0, -rightHand.Size.Y/2 - handle.Size.Y/2, 0)

    -- Weld it to the hand
    local weldConstraint = Instance.new("WeldConstraint")
    weldConstraint.Name = "RPGWeld"
    weldConstraint.Part0 = rightHand
    weldConstraint.Part1 = handle
    weldConstraint.Parent = handle

    -- Set collision group (you might want to set this to a specific group)
    -- CollectionService:AddTag(clonedRPG, "EquippedRPG")
    
    local toolData = {
        ToolInstance = clonedRPG,
        WeldConstraint = weldConstraint,
        ItemData = itemData,
        RPGData = rpgData,
        CurrentAmmo = rpgData.MaxAmmo,
        IsReloading = false,
        EquipTime = tick()
    }

    -- Store the equipped tool
    RPGs.equippedTools[playerId] = toolData

    print("[RPGs] Equipped RPG", RPGClass, "to", player.Name .. "'s right hand")
    return toolData
end

--[=[
    function RPGs.UnequipTool
    Unequips an RPG tool from a player

    @param entity table The player entity
    @param toolData table? Optional tool data, if nil will find equipped tool
]=]
function RPGs.UnequipTool(entity, toolData)
    local player = entity.Player
    local playerId = player.UserId
    
    -- If no toolData provided, get from equipped tools
    if not toolData then
        toolData = RPGs.equippedTools[playerId]
    end
    
    if not toolData or not toolData.ToolInstance then
        warn("[RPGs] No equipped RPG found for player:", player.Name)
        return
    end

    -- Destroy the RPG instance
    if toolData.ToolInstance then
        toolData.ToolInstance:Destroy()
    end

    -- Remove from equipped tools
    RPGs.equippedTools[playerId] = nil

    print("[RPGs] Unequipped RPG from", player.Name)
end

--[=[
    function RPGs.GetEquippedTool
    Gets the currently equipped RPG tool for a player
    
    @param entity table The player entity
    @return table? The equipped tool data or nil
]=]
function RPGs.GetEquippedTool(entity)
    return RPGs.equippedTools[entity.Player.UserId]
end

--[=[
    function RPGs.FireRPG
    Fires the equipped RPG
    
    @param entity table The player entity
    @return boolean Whether the RPG was fired successfully
]=]
function RPGs.FireRPG(entity)
    local toolData = RPGs.GetEquippedTool(entity)
    if not toolData then
        warn("[RPGs] No equipped RPG to fire for player:", entity.Player.Name)
        return false
    end
    
    if toolData.CurrentAmmo <= 0 then
        warn("[RPGs] No ammo remaining for player:", entity.Player.Name)
        return false
    end
    
    if toolData.IsReloading then
        warn("[RPGs] Cannot fire while reloading")
        return false
    end
    
    -- TODO: Implement actual firing logic here
    -- This would include creating projectiles, applying damage, etc.
    
    toolData.CurrentAmmo = toolData.CurrentAmmo - 1
    print("[RPGs] Fired RPG! Remaining ammo:", toolData.CurrentAmmo)
    
    return true
end

--[=[
    function RPGs.ReloadRPG
    Reloads the equipped RPG
    
    @param entity table The player entity
    @return boolean Whether the reload was started successfully
]=]
function RPGs.ReloadRPG(entity)
    local toolData = RPGs.GetEquippedTool(entity)
    if not toolData then
        warn("[RPGs] No equipped RPG to reload for player:", entity.Player.Name)
        return false
    end
    
    if toolData.CurrentAmmo >= toolData.RPGData.MaxAmmo then
        warn("[RPGs] RPG already fully loaded")
        return false
    end
    
    if toolData.IsReloading then
        warn("[RPGs] Already reloading")
        return false
    end
    
    toolData.IsReloading = true
    print("[RPGs] Starting reload for", entity.Player.Name)
    
    -- TODO: Implement actual reload logic with animations and timing
    
    return true
end

return RPGs