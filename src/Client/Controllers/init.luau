local Controllers = {};
Controllers.__index = Controllers;  
Controllers.Current = nil;

--Services 
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Imports   
local Player = game.Players.LocalPlayer;
Player:WaitForChild('PlayerGui');

local bridgenet2 = require(ReplicatedStorage.Packages.bridgenet2);

--Controllers
local TestCont = require(script.TestCont);

--Functions

function Controllers.Construct()
    local self = setmetatable({}, Controllers)
    local uuid : string = string.gsub(tostring(Player.UserId), '-', '');

    self.controllers = {};

    bridgenet2.ReferenceBridge(`{uuid}_self`):Connect(function(content)

        local controller = content.Controller;
        local func = content.Function;
        local args = content.Args;

        if not self.controllers[controller] then return end
        local contbase = self.controllers[controller]

        if contbase[func] then
            contbase[func](contbase, table.unpack(args))
        else
            warn('[Controllers] Function not found:', func, 'in controller:', controller);
        end

    end)

    self.controllers = {};
    
    return self
end

function Controllers:Initialize(data_replica : {})

    Controllers.Current = self;
    self.controllers = {};

    self.controllers.TestCont = TestCont.Construct(self)

    for _, controller in self.controllers do 
        if controller.Initialize then controller:Initialize() end
    end

    for _, controller in self.controllers do 
        if controller.Load then controller:Load() end
    end
end

return Controllers