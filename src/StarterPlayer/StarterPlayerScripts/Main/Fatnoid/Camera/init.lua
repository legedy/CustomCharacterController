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

	CameraModes:Init(Character, Settings);

	Events.CharacterAdded:Connect(function(Char)
		CameraModes:UpdateCharacter(Char);
	end);
	Events.CharacterRemoved:Connect(function()
		self:Disable();
	end);

end

--[[
	Toggles a camera mode.
	Note that this will error if the camera mode has already been selected.
	To select another mode, call Disable method first.
]]
function Module:Enable(CameraType: 'Regular' | 'Isometric' | 'SideScroll' | 'TopDown' | 'CharacterToMouse')
	--> Handle unexpected input and calls
	CameraType = CameraModes[CameraType] and CameraType or error('Invalid camera mode: '..tostring(CameraType));
	self._CurrentCameraMode = self._CurrentCameraMode and error('Camera mode already selected') or CameraType;

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
			ContextActionService:UnbindAction('MouseMovementTrack');
		end);

	end

	Maid:GiveTask(function()
		RunService:UnbindFromRenderStep(CameraType..'Camera');
	end);
end

function Module:Disable()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
	self._CurrentCameraMode = nil;
	Maid:Destroy();
end

return Module
