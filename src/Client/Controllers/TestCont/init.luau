local TestCont = {}
TestCont.__index = TestCont

function TestCont.Construct(container)
    local self = setmetatable({}, TestCont)
    self.container = container
    print("[TestCont] Constructed Test Controller")
    return self
end

function TestCont:Initialize()
    print("[TestCont] Initialized")
     self:_SetupNetworkStream()
end

function TestCont:Load()
    print("[TestCont] Loaded")
end

function TestCont:_SetupNetworkStream()
    local uuid = tostring(game.Players.LocalPlayer.UserId)
    local bridge = require(game.ReplicatedStorage.Packages.bridgenet2).ReferenceBridge(uuid .. "_TestCont")

    bridge:Connect(function(content)
        local func = content.Function
        local args = content.Args

        if self[func] then
            self[func](self, table.unpack(args))
        else
            warn("[TestCont] No handler for function:", func)
        end
    end)
end

function TestCont:UpdateCount(count)
    print("[TestCont] Count updated to:", count)
end

return TestCont
