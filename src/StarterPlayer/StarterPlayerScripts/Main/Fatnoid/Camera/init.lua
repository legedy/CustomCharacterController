--> Forked from FastCameraModule by 4thAxis (thx btw)

local Module = {}
Module.Connections = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");

local Maid = require(ReplicatedStorage.Maid).new();
local CameraModes = require(script:WaitForChild("CameraModes"));

local function _LockMousePress(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end

local function _LockMouseRelease(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end


local function _MouseMovementTrack(_, Input, Object)
	if Input == Enum.UserInputState.Change then
		CameraModes.OverTheShoulder(nil,
			CameraModes.CameraAngleX-(Object.Delta.X * CameraModes.MouseSensitivity),
			math.clamp(
				CameraModes.CameraAngleY-(Object.Delta.Y * CameraModes.MouseSensitivity),
				-75, 75
			)
		);
	end
end


--------------------------------------------------------------------
-------------------------  Functions  ------------------------------
--------------------------------------------------------------------

function Module:Init(Character, Events, Settings)

	local CharacterAdded = Events.CharacterAdded:Connect(function(Char)
		
	end);
	local CharacterRemoved = Events.CharacterRemoved:Connect(function()
		
	end);

	Maid:GiveTask(function()
		
	end)

	Maid
end

--> Shift Lock
function Module:EnableShiftLockCamera()
	self.Connections.LockMousePress = UserInputService.InputBegan:Connect(_LockMousePress)
	self.Connections.LockMouseRelease = UserInputService.InputEnded:Connect(_LockMouseRelease)
	ContextActionService:BindAction("MouseMovementTrack", _MouseMovementTrack, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
	RunService:BindToRenderStep("ShiftLock", 300, CameraModes.OverTheShoulder)
end

function Module:DisableShiftLockCamera()
	if not self.Connections.LockCenter then return end

	self.Connections.LockMousePress:Disconnect();
	self.Connections.LockMouseRelease:Disconnect();
	ContextActionService:UnbindAction("MouseMovementTrack");
	RunService:UnbindFromRenderStep("ShiftLock");
end

--> Isometric Camera
function Module:EnableIsometricCamera()
	RunService:BindToRenderStep("IsometricCamera", Enum.RenderPriority.Camera.Value, CameraModes.IsometricCamera)

end

function Module:DisableIsometricCamera()
	RunService:UnbindFromRenderStep("IsometricCamera")
end

--> Top Down Camera
function Module:EnableTopDownCamera()
	RunService:BindToRenderStep("TopDown", Enum.RenderPriority.Camera.Value, CameraModes.TopDownCamera)

end 

function Module:DisableTopDownCamera()
	RunService:UnbindFromRenderStep("TopDown")

end

--> SideScrollCamera
function Module:EnableSideScrollingCamera()
	RunService:BindToRenderStep("SideScroll", Enum.RenderPriority.Camera.Value, CameraModes.SideScrollingCamera)
end

function Module:DisableSideScrollingCamera()
	RunService:UnbindFromRenderStep("SideScroll")
end

--> Face Mouse
function Module:FaceCharacterToMouse()
	RunService:BindToRenderStep("FaceCharacterToMouse", Enum.RenderPriority.Character.Value, CameraModes.FaceCharacterToMouse)
end

function Module:StopFacingMouse()
	RunService:UnbindFromRenderStep("FaceCharacterToMouse")
end

return Module
