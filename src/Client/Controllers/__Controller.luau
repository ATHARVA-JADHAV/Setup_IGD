local Controller = {}
Controller.__index = Controller;

-- / Services:

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Player = game.Players.LocalPlayer;

-- / Imports:

local TestCont = require(script.TestCont);
local network = require(ReplicatedStorage.Packages.bridgenet2);

-- / Functions:
function Controller:Construct(container, name)
    local self = setmetatable({}, Controller);

    self.controllers = container.controllers;
    self.container = container;
    self.name = name;
    self.replicator = network.ReferenceBridge(`{ string.gsub(tostring(Player.UserId), '-', '')}_{self.name}`);
    self.children = {};

    return self

end

function Controller:Initialize()
    self:_SetupNetworkStream();
end

function Controller:Load()
    self.children['TestCont'] = TestCont.Construct(self) -- Use self.children, not self._controllers
    
    for _, v in self.children do -- Use self.children
        if v.Initialize then v:Initialize() end
    end
    
    for _, v in self.children do -- Use self.children  
        if v.Deploy then v:Deploy() end
    end
end

function Controller:_SetupNetworkStream()
    self.replicator:Connect(function(args)

        warn(args)

        local func = args.Function;
        local kwargs = args.Args;

        if self[func] then
            self[func](self, table.unpack(kwargs))
        else
            warn('[Controller] Function not found:', func, 'in controller:', self.name);
        end

    end)
end

function Controller:GetController(cname)
    return self.children[cname];
end

function Controller:Activate(starterTab)
    
end

function Controller:Deactivate()
  
end

return Controller 