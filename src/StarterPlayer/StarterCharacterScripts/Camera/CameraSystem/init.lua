--> Forked from FastCameraModule by 4thAxis (thx btw)

local Module = {}
Module.Connections = {}


local CameraModes = require(script:WaitForChild("CameraModes"))

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")


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

--> Shift Lock
function Module.EnableShiftLockCamera()
	Module.Connections.LockMousePress = UserInputService.InputBegan:Connect(_LockMousePress)
	Module.Connections.LockMouseRelease = UserInputService.InputEnded:Connect(_LockMouseRelease)
	ContextActionService:BindAction("MouseMovementTrack", _MouseMovementTrack, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
	RunService:BindToRenderStep("ShiftLock", Enum.RenderPriority.Camera.Value, CameraModes.OverTheShoulder)
end

function Module.DisableShiftLockCamera()
	if not Module.Connections.LockCenter then return end

	Module.Connections.LockMousePress:Disconnect();
	Module.Connections.LockMouseRelease:Disconnect();
	ContextActionService:UnbindAction("MouseMovementTrack");
	RunService:UnbindFromRenderStep("ShiftLock");
end

--> Isometric Camera
function Module.EnableIsometricCamera()
	RunService:BindToRenderStep("IsometricCamera", Enum.RenderPriority.Camera.Value, CameraModes.IsometricCamera)

end

function Module.DisableIsometricCamera()
	RunService:UnbindFromRenderStep("IsometricCamera")
end

--> Top Down Camera
function Module.EnableTopDownCamera()
	RunService:BindToRenderStep("TopDown", Enum.RenderPriority.Camera.Value, CameraModes.TopDownCamera)

end 

function Module.DisableTopDownCamera()
	RunService:UnbindFromRenderStep("TopDown")

end

--> SideScrollCamera
function Module.EnableSideScrollingCamera()
	RunService:BindToRenderStep("SideScroll", Enum.RenderPriority.Camera.Value, CameraModes.SideScrollingCamera)
end

function Module.DisableSideScrollingCamera()
	RunService:UnbindFromRenderStep("SideScroll")
end

--> Face Mouse
function Module.FaceCharacterToMouse()
	RunService:BindToRenderStep("FaceCharacterToMouse", Enum.RenderPriority.Character.Value, CameraModes.FaceCharacterToMouse)
end

function Module.StopFacingMouse()
	RunService:UnbindFromRenderStep("FaceCharacterToMouse")
end

return Module
