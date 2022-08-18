local ReplicatedStorage = game:GetService('ReplicatedStorage');

local BridgeNet = require(ReplicatedStorage.BridgeNet);
local Signal = require(ReplicatedStorage.Signal);

local Camera = require(script.Camera);
local Controller = require(script.Controller);
local Animator = require(script.Animator);

local Events = require(script.Events);
local Settings = require(script.Settings);

local Fatnoid = {};

function Fatnoid:Init(Character)
	Camera.EnableShiftLockCamera();
	Controller:Init(Character, Events, Settings);
	Animator:Init(Character, Events, Settings);
end

return Fatnoid;