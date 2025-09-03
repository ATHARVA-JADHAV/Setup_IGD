local ReplicatorComponent = {};
ReplicatorComponent.__index = ReplicatorComponent;

-- / Services:

local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- / Imports:

local bridgenet2 = require(ReplicatedStorage.Packages.bridgenet2);

-- / Functions:

function ReplicatorComponent.Construct(entity)
    local self = setmetatable({}, ReplicatorComponent)

    self.Player = entity.Player  -- uppercase P, consistent

    if not self.Player then
        warn("No Player found for ReplicatorComponent")
        return self
    end

    local uuid = string.gsub(tostring(self.Player.UserId), '-', '')

    
    self.bridges = {
    _self = bridgenet2.ReferenceBridge(`{uuid}_self`),
    TestCont = bridgenet2.ReferenceBridge(`{uuid}_TestCont`),
    -- Inventory = bridgenet2.ReferenceBridge(`{uuid}_Inventory`);
    }
        
    self.bridges._self:Connect(function(player, content)
    -- Optionally just log or handle commands from the client
    warn("[Replicator] _self bridge received:", content)
    end)
    return self
end


function ReplicatorComponent:StreamToClient(bridge , ...)
    self.bridges[bridge]:Fire(bridgenet2.Players({ self.Player }), ...)
end

return ReplicatorComponent