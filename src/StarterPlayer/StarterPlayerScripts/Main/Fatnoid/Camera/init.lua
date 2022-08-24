--> Forked from FastCameraModule by 4thAxis (thx btw)

local Module = {};
Module._Sensitivity = .5;
Module._CurrentCameraMode = nil;

local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");

local Maid = require(ReplicatedStorage.Maid).new();
local CameraModes = require(script:WaitForChild("CameraModes"));

local function _LockMouse(Began: boolean, Input: InputObject)
	if (Input.UserInputType == Enum.UserInputType.MouseButton1) then
		UserInputService.MouseBehavior = (Began) and
			Enum.MouseBehavior.LockCurrentPosition or
			Enum.MouseBehavior.Default
	end
end


local function _MouseMovementTrack(_, Input: Enum.UserInputState, Object: InputObject)
	if (Input == Enum.UserInputState.Change) then
		CameraModes:UpdateCameraAngle(
			Object.Delta.X * Module._Sensitivity,
			Object.Delta.Y * Module._Sensitivity
		);
	end
end

--------------------------------------------------------------------
-------------------------  Functions  ------------------------------
--------------------------------------------------------------------

function Module:Init(Character, Events, Settings)

	Events.CharacterAdded:Connect(function(Char)

	end);
	Events.CharacterRemoved:Connect(function()
		self:Disable();
	end);

	Maid:GiveTask(function()
		
	end)
end

function Module:Enable(CameraType)
	if (self._CurrentCameraMode) then
		error('Camera already enabled.');
	else
		self._CurrentCameraMode = CameraType;
	end

	RunService:BindToRenderStep(CameraType..'Camera',
		Enum.RenderPriority.Camera.Value,
		CameraModes[CameraType]
	);

	if (CameraType == 'Regular') then
		
		ContextActionService:BindAction('MouseMovementTrack',
			_MouseMovementTrack,
			false,
			Enum.UserInputType.MouseMovement,
			Enum.UserInputType.Touch
		);

		Maid:GiveTask(UserInputService.InputBegan:Connect(function(...)
			_LockMouse(true, ...);
		end));
		Maid:GiveTask(UserInputService.InputEnded:Connect(function(...)
			_LockMouse(false, ...);
		end));
		Maid:GiveTask(function()
			ContextActionService:UnBindAction('MouseMovementTrack');
		end);

	end

	Maid:GiveTask(function()
		RunService:UnbindFromRenderStep(CameraType..'Camera');
	end);
end

function Module:Disable()
	Maid:Destroy();
end

return Module
