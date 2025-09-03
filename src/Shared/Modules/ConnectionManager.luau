local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager;

-- // Functions:

function ConnectionManager.Construct(uuid : string)
    return setmetatable({ uuid = uuid; registries = {} }, ConnectionManager)
end

-- ? Creates a new registry of connections

function ConnectionManager:CreateRegistry(registry : string)
    self.registries[registry] = {} :: RBXScriptConnection;
end

-- ? Disconnects all connecitons in registry and removes it

function ConnectionManager:RemoveRegistry(registry : string)
    self:DisconnectAll(registry); self.registries[registry] = nil;
end

-- ? Disconnects all connections in a registry

function ConnectionManager:DisconnectAll(registry : string)

    if not self.registries[registry] then print(`debug: registry: {registry} not found in connection manager`) return end

    for _, connection : RBXScriptConnection in self.registries[registry] do
        connection:Disconnect();
    end

    self.registries[registry] = {};

end

-- ? Adds a connection to a registry

function ConnectionManager:AddConnection(registry : string, identifier : string, connection : RBXScriptConnection)

    local registry = self.registries[registry]
    if not registry then print('registry not found') return end

    registry[identifier] = connection

end

-- ? Remove connection

function ConnectionManager:DisconnectConnection(registry : string, identifier : string)

    local registry = self.registries[registry]

    if not registry then print('registry not found') return end
    if not registry[identifier] then print('identifier not found') return end

    registry[identifier]:Disconnect()
    registry[identifier] = nil;

end

function ConnectionManager:GetConnection(registry : string, identifier : string)

    local registry = self.registries[registry]

    if not registry then print('registry not found') return end
    if not registry[identifier] then print('identifier not found') return end

    return registry[identifier]
    
end


return ConnectionManager