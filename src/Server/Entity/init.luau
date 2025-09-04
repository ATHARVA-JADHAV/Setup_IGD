local Entity = {};
Entity.__index = Entity;

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- / Imports:
local GlobalReplicator = require(ReplicatedStorage.Modules.GlobalReplicator);
local Replicator = require(script.Parent.Components.Replicator);
local Inventory = require(script.Parent.Components.Inventory.Inventory);
local Weapon = require(script.Parent.Components.Weapon);

local TestComp = require(script.Parent.Components.TestComp);
local DebugManager = require(ReplicatedStorage.Modules.DebugManager);

-- / Functions:
function Entity.Construct(player : Player)

    local self = setmetatable({}, Entity);

    self.Player = player;
    self.name = player.Name;
    self.character = player.Character or player.CharacterAdded:Wait();

    self.Components = {};
    
    DebugManager.print('ENTITY', "Constructed components:", table.concat((function()
    local keys = {}
    for k,_ in pairs(self.Components) do table.insert(keys, k) end
    return keys
    end)(), ", "))   
     return self
    

end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         

function Entity:Initialize()
    -- Initialize components here
    local Data = require(script.Parent.Components.Data);
    self.Components.Replicator = Replicator.Construct(self)
    self.Components.Data = Data.Construct(self);
    self.Components.Data:_Initialize();

    self.Components.Inventory = Inventory.Construct(self);
    self.Components.Weapon = Weapon.Construct(self); -- Add Weapon component
    self.Components.TestComp = TestComp.Construct(self)
    
        DebugManager.print('ENTITY', "Initialized components:", table.concat((function()
        local keys = {}
        for k,_ in pairs(self.Components) do table.insert(keys, k) end
        return keys
        end)(), ", "))
    
    for name, component in pairs(self.Components) do
        if component.Initialize then
            DebugManager.print('ENTITY', "Initializing component:", name)
            component:Initialize()
        end
    end
end

function Entity:Deploy()
    DebugManager.print('ENTITY', "Deploying components for:", self.name)
    for name, component in pairs(self.Components) do
        if component.Deploy then
            DebugManager.print('ENTITY', "Deploying component:", name)
            component:Deploy()
        end
    end
end

function Entity:GetComponents(cname)
    return self.Components[cname];
end

function Entity:Release()
    
end

return Entity