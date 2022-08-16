--> Forked from FastCameraModule by 4thAxis (thx btw)

local Module = {};

local Configs = require(script.Parent:WaitForChild("Configurations"));

local UserInputService = game:GetService("UserInputService");
local Players = game:GetService("Players");

--> Constants
local DownVector = Vector3.new(0,-1,0);
Module.Epsilon = 1e-5;
Module.CameraAngleX = 0;
Module.CameraAngleY = 0;

Module.MouseSensitivity = 0.5;


local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Camera = workspace.CurrentCamera
local ScreenSize = Camera.ViewportSize
local ScreenSizeX, ScreenSizeY = ScreenSize.X, ScreenSize.Y
local PixelCoordinateRatioX, PixelCoordinateRatioY = 1/ScreenSizeX, 1/ScreenSizeY

local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("RootPart")

--------------------------------------------------------------------
--------------------------  Privates  ------------------------------
--------------------------------------------------------------------

local function _DisableRobloxCamera()
	if Camera.CameraType ~= Enum.CameraType.Scriptable then
		Camera.CameraType = Enum.CameraType.Scriptable
	end
end


local function _GetRotationXY(X, Y)
	X = X or Module.CameraAngleX
	Y = Y or Module.CameraAngleY
	
	local Cosy, Siny = math.cos(X),  math.sin(X)
	local Cosx, Sinx = math.cos(Y), math.sin(Y)
	return CFrame.new(
		0, 0, 0, 
		Cosy, Siny*Sinx, Siny*Cosx, 
		0, Cosx, -Sinx,
		-Siny, Cosy*Sinx, Cosy*Cosx
	)
end


local function _GetPositionToWorldByOffset(OriginCF, XOffset, YOffset, ZOffset)
	-- Perserve rotational matrix, only transform position to world instead rather than naively transforming origin cframe to world space
	XOffset = XOffset or Configs.CamLockOffset.X
	YOffset = YOffset or Configs.CamLockOffset.Y
	ZOffset = ZOffset or Configs.CamLockOffset.Z

	local X, Y, Z, M11, M12, M13, M21, M22, M23, M31, M32, M33 = OriginCF:GetComponents()
	return Vector3.new (
		M11*XOffset+M12*YOffset+M13*ZOffset+X,
		M21*XOffset+M22*YOffset+M23*ZOffset+Y,
		M31*XOffset+M32*YOffset+M33*ZOffset+Z
	)
end

local function GetViewMatrix(Eye, Focus)
	-- Faster alternative to cframe.lookat for our case since we are more commonly prone to special cases such as: when focus is facing up/down or if focus and eye are colinear vectors
	local XAxis = Focus-Eye -- Lookvector
	if (XAxis:Dot(XAxis) <= Module.Epsilon) then 
		return CFrame.new(Eye.X, Eye.Y, Eye.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1) 
	end
	XAxis = XAxis.Unit
	local Xx, Xy, Xz = XAxis.X, XAxis.Y, XAxis.Z
	local RNorm = (((Xz*Xz)+(Xx*Xx))) -- R:Dot(R), our right vector
	if RNorm <= Module.Epsilon and math.abs(XAxis.Y) > 0 then
 		return CFrame.fromMatrix(Eye, -math.sign(XAxis.Y)*Vector3.zAxis, Vector3.xAxis)
	end
	RNorm = 1/(RNorm^0.5) -- take the root of our squared norm and inverse division
	local Rx, Rz = -(Xz*RNorm), (Xx*RNorm) -- cross y-axis with right and normalize
	local Ux, Uy, Uz = -Rz*(Rz*Xx-Rx*Xz), -(Rz*Rz)*Xy-(Rx*Rx)*Xy, Rx*(Rz*Xx-Rx*Xz) -- cross right and up and normalize.
	local UNorm = 1/((Ux*Ux)+(Uy*Uy)+(Uz*Uz))^0.5 -- inverse division and multiply this ratio rather than dividing each component
	return CFrame.new(
		Eye.X,Eye.Y,Eye.Z,
		Rx, -Xy*Rz, Ux*UNorm, 
		0, (Rz*Xx)-Rx*Xz, Uy*UNorm,
		Rz, Xy*Rx, Uz*UNorm
	)
end

--------------------------------------------------------------------
-------------------------  Functions  ------------------------------
--------------------------------------------------------------------

Module.OverTheShoulder = function(_, CameraAngleX, CameraAngleY, Lerp)
	Module.CameraAngleX = CameraAngleX or Module.CameraAngleX
	Module.CameraAngleY = CameraAngleY or Module.CameraAngleY
	_DisableRobloxCamera()

	local Origin = CFrame.new((Root.CFrame.Position)) * _GetRotationXY(math.rad(Module.CameraAngleX), math.rad(Module.CameraAngleY))
	local Eye = _GetPositionToWorldByOffset(Origin)
	local Focus = _GetPositionToWorldByOffset(Origin, Configs.CamLockOffset.X, Configs.CamLockOffset.Y, -10000)

	Camera.CFrame = GetViewMatrix(Eye, Focus)
end


Module.IsometricCamera = function(_, CameraDepth, HeightOffset, FOV)
	CameraDepth = CameraDepth or Configs.IsometricCameraDepth
	HeightOffset = HeightOffset or Configs.IsometricHeightOffset
	Camera.FieldOfView = FOV or Configs.IsometricFieldOfView
	_DisableRobloxCamera()

	local Root = Root.Position + Vector3.new(0, HeightOffset, 0)
	local Eye = Root + Vector3.new(CameraDepth, CameraDepth, CameraDepth)	
	Camera.CFrame = GetViewMatrix(Eye, Root)
end


Module.SideScrollingCamera = function(_, CameraDepth, HeightOffset, FOV)
	CameraDepth = CameraDepth or Configs.SideCameraDepth
	HeightOffset = HeightOffset or Configs.SideHeightOffset
	Camera.FieldOfView = FOV or Configs.SideFieldOfView
	_DisableRobloxCamera()

	local Focus = Root.Position + Vector3.new(0, HeightOffset, 0)
	local Eye = Vector3.new(Focus.X, Focus.Y, CameraDepth)
	Camera.CFrame =  GetViewMatrix(Eye, Focus)
end


Module.TopDownCamera = function(_, FaceMouse, MouseSensitivity, Offset, Direction, Distance)
	FaceMouse = FaceMouse or Configs.TopDownFaceMouse
	MouseSensitivity = MouseSensitivity or Configs.TopDownMouseSensitivity
	Distance = Distance or Configs.TopDownDistance
	Direction = Direction or DownVector
	Offset = Offset or Configs.TopDownOffset
	_DisableRobloxCamera()

	local M = UserInputService:GetMouseLocation()
	local Axis = Vector3.new(-((M.Y-ScreenSizeY*0.5)*PixelCoordinateRatioY),0,((M.Y-ScreenSizeX*0.5)*PixelCoordinateRatioX))
	
	local Eye = (Distance + (Root.Position+Offset)) + Axis * MouseSensitivity 
	local Focus = Eye + Direction
	Camera.CFrame = GetViewMatrix(Eye, Focus)
	
	if FaceMouse then
		local Forward = (Root.Position - Mouse.Hit.Position).Unit
		local Right = Vector3.new(-Forward.Z, 0, Forward.X) -- Forward:Cross(YAxis)
		Root.CFrame = CFrame.fromMatrix(Root.Position, -Right, Vector3.yAxis)
	end
end

Module.FaceCharacterToMouse = function(_, Alpha, GoalCF)
	GoalCF = GoalCF or GetViewMatrix(Root.Position, Vector3.new(Mouse.Hit.Position.X, Root.Position.Y, Mouse.Hit.Position.Z))
	Root.CFrame = Root.CFrame:Lerp(GoalCF, Alpha or Configs.FaceCharacterAlpha)
end

return Module
