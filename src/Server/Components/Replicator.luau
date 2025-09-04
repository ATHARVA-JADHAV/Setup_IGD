local ReplicatorComponent = {};
ReplicatorComponent.__index = ReplicatorComponent;

-- / Services:

local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- / Imports:
local DebugManager = require(ReplicatedStorage.Modules.DebugManager);
local bridgenet2 = require(ReplicatedStorage.Packages.bridgenet2);

-- / Functions:

function ReplicatorComponent.Construct(entity)
    local self = setmetatable({}, ReplicatorComponent)

    self.Player = entity.Player  -- uppercase P

    if not self.Player then
        DebugManager.warn('REPLICATOR', "No Player found for ReplicatorComponent")
        return self
    end

    local uuid = string.gsub(tostring(self.Player.UserId), '-', '')

    
    self.bridges = {
    _self = bridgenet2.ReferenceBridge(`{uuid}_self`),
    TestCont = bridgenet2.ReferenceBridge(`{uuid}_TestCont`),
    Inventory = bridgenet2.ReferenceBridge(`{uuid}_Inventory`);
    Weapon = bridgenet2.ReferenceBridge(`{uuid}_Weapon`) 

    }
        
    self.bridges._self:Connect(function(player, content)
    DebugManager.warn('REPLICATOR', "_self bridge received:", content)
    end)
    return self
end


function ReplicatorComponent:StreamToClient(bridge , ...)
    self.bridges[bridge]:Fire(bridgenet2.Players({ self.Player }), ...)
end

return ReplicatorComponent