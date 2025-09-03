local TestComp = {};
TestComp.__index = TestComp;

-- / Imports:

local Component = require(script.Parent.__Component);

-- / Functions

function TestComp.Construct(entity)
    local self = setmetatable(Component.Construct(entity, 'TestComp'), TestComp);

    self.callable_functions = {'TestFunction'}
    print('TestComp Constructed for', entity.name)
    return self
end

function TestComp:Initialize()
    print("[TestComp] Starting initialization")
    self.replicator = self.entity:GetComponents('Replicator');
    print("[TestComp] Got replicator:", self.replicator)
    print("[TestComp] Initialized")
end

function TestComp:Deploy()
    print("[TestComp] Deploying - starting trigger")
    self:Trigger()
end

function TestComp:TestCurrency()
    local dataComponent = self.entity:GetComponents('Data')
    if dataComponent then
        -- Test currency operations
        dataComponent:EditCurrency('Cash', 'Add', 100)
        task.wait(1)
        dataComponent:EditCurrency('Cash', 'Deduct', 50)
        task.wait(1)
        dataComponent:EditCurrency('Gems', 'Add', 10)
    end
end

function TestComp:Trigger()
    print("[TestComp] Trigger method called")

    self:TestCurrency()

    task.spawn(function()
        for i = 1, 10 do
            self.count = i
            print("[TestComp] Sending count:", i)
            
            local uuid = tostring(self.entity.Player.UserId)
            self.replicator:StreamToClient('TestCont', {
                Function = "UpdateCount",
                Args = { self.count }
            })

            task.wait(1)
        end
    end)
end

return TestComp