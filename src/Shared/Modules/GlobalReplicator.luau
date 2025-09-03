--[=[

    Filename: Replicator.lua
    Description: Just handles the replication using bridgenet, bridgenet api seems kinda
    retarded.

]=]

local Replicator = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Packages = ReplicatedStorage.Packages
local Network = require(Packages.bridgenet2)

Replicator.Bridges = {

    Systems = Network.ReferenceBridge("Systems");
    Loader = Network.ReferenceBridge("Loader");
    
}

-- // FUNCTIONS;

--[=[ 

    @function Replicator.StreamClient
    Description: Send data from Server -> Client to a single player

]=]

function Replicator.StreamClient(client : Player, Bridge, data : any?)
    Replicator.Bridges[Bridge]:Fire(Network.Players({ client }), data)
end

--[=[

    @function Replicator.StreamToClients
    Description: Send data from Server -> Client to certain players.

]=]

function Replicator.StreamToClients(clients : {Player}, Bridge : string, data : any?)
    Replicator.Bridges[Bridge]:Fire(Network.Players(clients), data)
end

--[=[

    @function Replicator.StreamToServer
    Description: Send data from client to server (if any)

]=]

function Replicator.StreamToServer(bridge : string, data : any?)
    Replicator.Bridges[bridge]:Fire(data);
end

return Replicator