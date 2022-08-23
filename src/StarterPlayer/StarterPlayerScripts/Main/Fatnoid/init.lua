local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Player = Players.LocalPlayer;

local Clone = ReplicatedStorage.Dummy:Clone();
Clone.Name = Player.Name;
Clone.Parent = workspace;
Clone.PrimaryPart.Anchored = true;

Player.Character = Clone;

local BridgeNet = require(ReplicatedStorage.BridgeNet);
local Signal = require(ReplicatedStorage.Signal);

local Camera = require(script.Camera);
local Controller = require(script.Controller);
local Animator = require(script.Animator);

local Events = require(script.Events);
local Settings = require(script.Settings);

BridgeNet.Start({
	[BridgeNet.DefaultReceive] = 60,
	[BridgeNet.DefaultSend] = 60
});

local Remotes = {
	Position = BridgeNet.CreateBridge('Position')
};

local Fatnoid = {};

function Fatnoid:Init()
	Camera:Init(Clone, Events, Settings);
	Camera:EnableShiftLockCamera();
	Controller:Init(Clone, Remotes, Events, Settings);
	Animator:Init(Clone, Events, Settings);
end

return Fatnoid;