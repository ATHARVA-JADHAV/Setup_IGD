-- Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports

local Replicator = require(ReplicatedStorage.Modules.GlobalReplicator)
local Class = require(script.Controllers);
local Util = require(ReplicatedStorage.Modules.Util);

local Controllers = Class.Construct();

Replicator.Bridges.Loader:Connect(function(data_replica : {})
    Controllers:Initialize(data_replica[1]);
end)

Replicator.Bridges.Loader:Connect(function(request)
    local path = request.Path
    local func = request.Function
    local kwargs = request.Args

    local mod = nil
    if not string.find(path, '/') then
        mod = script.Interfaces:FindFirstChild(path);
    else
         mod = Util.ParsePath(script.Interfaces, path)
    end

    local m = require(mod)
    m[func](table.unpack(kwargs))

end)

