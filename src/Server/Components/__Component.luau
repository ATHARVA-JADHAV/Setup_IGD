local Component = {};
Component.__index = Component;

-- / Services:
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- / Imports:
local ConnectionManager = require(ReplicatedStorage.Modules.ConnectionManager);
-- Functions

function Component.Construct(entity, component_name)

    local self = setmetatable({}, Component);

    self.entity = entity;
    self.Player = entity.Player;
    self.name = component_name;

    self.callable_functions = {};
    self.components = {};

    self.Connections = ConnectionManager.Construct(component_name);
    self.threads = {};
    return self
end

function Component:Initialize()

end
function Component:Deploy()

end
function Component:GetAll(cname)
    return self.components[cname];
end

function Component:SetupNetworkStream(bridge_name, func_name, func)
    self.replicator.bridges[self.name]:Connect(function(player, args)
        if player ~= self.Player then
            return
        end
        local func = args.Function
        local kwargs = args.Args
        if not table.find(self.callable_functions, func) then
            self.Player:Kick('byebye');
            return
        end

        self[func](self, table.unpack(kwargs))

    end)
end

return Component
