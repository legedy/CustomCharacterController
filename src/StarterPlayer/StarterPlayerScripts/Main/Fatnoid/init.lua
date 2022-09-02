local Types = require(script._TypeDefinition);

local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Player = Players.LocalPlayer;

--> Require the dependencies
local BridgeNet = require(ReplicatedStorage.BridgeNet);
local Signal = require(ReplicatedStorage.Signal);

local Camera = require(script.Camera);
local Controller: Types.Controller = require(script.Controller);
local Animator = require(script.Animator);

local Events = require(script.Events);
local Settings = require(script.Settings);

--> Start the connection to the server
BridgeNet.Start({
	[BridgeNet.DefaultReceive] = 60,
	[BridgeNet.DefaultSend] = 60
});

--> Create a dictionary with list of events
local Remotes = {
	Position = BridgeNet.CreateBridge('Position')
};

--> Create table and return it with the Init method
local Fatnoid = {};

function Fatnoid:Init()
	--> Create the character before passing it to the modules
	local Clone = ReplicatedStorage.Dummy:Clone();
	Clone.Name = Player.Name;
	Clone.Parent = workspace;
	Clone.PrimaryPart.Anchored = true;

	--> Initialize the modules
	Camera:Init(Clone, Events, Settings);
	Controller:Init(Clone, Remotes, Events, Settings);
	Animator:Init(Clone, Events, Settings);

	--> Fire the event to set new character for modules
	Events.CharacterAdded:Fire(Clone);

	--> Select camera mode
	Camera:Enable('Regular');
end

return Fatnoid;