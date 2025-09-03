--Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Imports
local Entity = require(script.Entity)
local Registry = require(script.Entity.Registry)
local Util = require(ReplicatedStorage.Modules.Util)
local GReplicator = require(ReplicatedStorage.Modules.GlobalReplicator)

--Fuctions

function OnPlayerAdded(player)
    player.CharacterAdded:connect(function(character)
        task.delay(1, function()
            local entity = Entity.Construct(player)
            entity:Initialize()
            entity:Deploy()

            Registry[player.UserId] = entity
        end)
    end)
  
end

function OnPlayerRemoving(player)
    local entity = Registry[player.UserId]
    if entity then entity:Release() end
    
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

GReplicator.Bridges.Systems:Connect(function(player : Player, kwargs : { Path : string; Function : string; Args : {} })

    local path = kwargs.Path
    local func = kwargs.Function;
    local args = kwargs.Args;

    local mod = nil;
    print(path)
    print(Util.ParsePath(script.Systems, path))

    if not string.find(path, '/') then

        if not script.Systems:FindFirstChild(path) then player:Kick('404: endpoint not found'); return end
        mod = script.Systems:FindFirstChild(path);

    else
        print(path)
        mod = Util.ParsePath(script.Systems, path)
        print(mod)
        if not mod then player:Kick('404: endpoint not found') return end

    end

    local mod = require(mod)

    if not table.find(mod.permitted_callables, func) then
        player:Kick('[AUTHORIZATION] level 0 required to request unpermitted system callbacks: '..func); return
    end

    mod[func](player, table.unpack(args));

end)

-- Load all systems:

for _, sysmodule  in script.Systems:GetChildren() do

    local m = require(sysmodule);
    m.Initialize();

end