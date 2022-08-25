--> Forked from FastCameraModule by 4thAxis (thx btw)
local Types = require(script.Parent.Parent._TypeDefinition);

local UserInputService = game:GetService("UserInputService");
local Players = game:GetService("Players");

local Module: {Settings: Types.CameraSettings} = {};


--> Constants
local Epsilon = 1e-5;

--> Camera property
Module.CameraAngleX = 0;
Module.CameraAngleY = 0;

local Player = Players.LocalPlayer;
local Mouse = Player:GetMouse();

local Camera = workspace.CurrentCamera;
local ScreenSize = Camera.ViewportSize;
local ScreenSizeX, ScreenSizeY = ScreenSize.X, ScreenSize.Y;
local PixelCoordinateRatioX, PixelCoordinateRatioY = 1/ScreenSizeX, 1/ScreenSizeY;

local Root = nil;

--------------------------------------------------------------------
--------------------------  Privates  ------------------------------
--------------------------------------------------------------------

local function _ClampAngle(Angle: number)
	if (Angle > 360) then
		Angle -= 360;
	elseif (Angle < 0) then
		Angle += 360;
	end

	return Angle;
end

local function _GetRotationXY(X, Y)
	local Cosy, Siny = math.cos(X), math.sin(X);
	local Cosx, Sinx = math.cos(Y), math.sin(Y);
	return CFrame.new(
		0, 0, 0,
		Cosy, Siny*Sinx, Siny*Cosx,
		0, Cosx, -Sinx,
		-Siny, Cosy*Sinx, Cosy*Cosx
	)
end


local function _GetPositionToWorldByOffset(OriginCF, XOffset, YOffset, ZOffset)
	-- Perserve rotational matrix, only transform position to world instead rather than naively transforming origin cframe to world space
	XOffset = XOffset or Module.Settings.CamLockOffset.X
	YOffset = YOffset or Module.Settings.CamLockOffset.Y
	ZOffset = ZOffset or Module.Settings.CamLockOffset.Z

	local X, Y, Z, M11, M12, M13, M21, M22, M23, M31, M32, M33 = OriginCF:GetComponents()
	return Vector3.new (
		M11*XOffset+M12*YOffset+M13*ZOffset+X,
		M21*XOffset+M22*YOffset+M23*ZOffset+Y,
		M31*XOffset+M32*YOffset+M33*ZOffset+Z
	)
end

-- Faster alternative to cframe.lookat for our case since we are more commonly prone to special cases such as: when focus is facing up/down or if focus and eye are colinear vectors.
local function _GetViewMatrix(Eye, Focus)
	local XAxis = Focus-Eye -- Lookvector
	if (XAxis:Dot(XAxis) <= Epsilon) then 
		return CFrame.new(Eye.X, Eye.Y, Eye.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1) 
	end
	XAxis = XAxis.Unit
	local Xx, Xy, Xz = XAxis.X, XAxis.Y, XAxis.Z
	local RNorm = (((Xz*Xz)+(Xx*Xx))) -- R:Dot(R), our right vector
	if RNorm <= Epsilon and math.abs(XAxis.Y) > 0 then
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

function Module:Init(Char, Settings: Types.Settings)
	Camera.CameraType = Enum.CameraType.Scriptable;

	self:UpdateCharacter(Char);

	self.Settings = Settings.CameraSettings;
end

function Module:UpdateCharacter(NewChar)
	Root = NewChar:WaitForChild("RootPart");
end

function Module:UpdateCameraAngle(X, Y)
	self.CameraAngleX = _ClampAngle(self.CameraAngleX - X);
	self.CameraAngleY = math.clamp(self.CameraAngleY - Y, -75, 75);
end

function Module.Regular()

	local Origin = CFrame.new((Root.CFrame.Position)) *
		_GetRotationXY(
			math.rad(Module.CameraAngleX),
			math.rad(Module.CameraAngleY));

	local Eye = _GetPositionToWorldByOffset(Origin);

	local Focus = _GetPositionToWorldByOffset(
		Origin,
		Module.Settings.CamLockOffset.X,
		Module.Settings.CamLockOffset.Y,
		-10000
	);

	Camera.CFrame = _GetViewMatrix(Eye, Focus);
end


function Module.Isometric()
	local CameraDepth = Module.Settings.IsometricCameraDepth;
	local HeightOffset = Module.Settings.IsometricHeightOffset;

	Camera.FieldOfView = Module.Settings.IsometricFieldOfView;

	local Root = Root.Position + Vector3.new(0, HeightOffset, 0);
	local Eye = Root + Vector3.new(CameraDepth, CameraDepth, CameraDepth);
	Camera.CFrame = _GetViewMatrix(Eye, Root);
end

function Module.SideScroll()
	local CameraDepth = Module.Settings.SideCameraDepth;
	local HeightOffset = Module.Settings.SideHeightOffset;

	Camera.FieldOfView = Module.Settings.SideFieldOfView;

	local Focus = Root.Position + Vector3.new(0, HeightOffset, 0);
	local Eye = Vector3.new(Focus.X, Focus.Y, CameraDepth);

	Camera.CFrame = _GetViewMatrix(Eye, Focus);
end


function Module.TopDown()
	local MouseSensitivity = Module.Settings.TopDownMouseSensitivity;
	local FaceMouse = Module.Settings.TopDownFaceMouse;
	local Distance = Module.Settings.TopDownDistance;
	local Direction = -Vector3.yAxis;
	local Offset = Module.Settings.TopDownOffset;

	local M = UserInputService:GetMouseLocation();
	local Axis = Vector3.new(
		-((M.Y-ScreenSizeY*0.5)*PixelCoordinateRatioY),
		0,
		((M.Y-ScreenSizeX*0.5)*PixelCoordinateRatioX)
	);
	
	local Eye = (Distance + (Root.Position+Offset)) + Axis * MouseSensitivity;
	local Focus = (Eye + Direction);
	Camera.CFrame = _GetViewMatrix(Eye, Focus)
	
	if FaceMouse then
		local Forward = (Root.Position - Mouse.Hit.Position).Unit
		local Right = Vector3.new(-Forward.Z, 0, Forward.X) -- Forward:Cross(YAxis)
		Root.CFrame = CFrame.fromMatrix(Root.Position, -Right, Vector3.yAxis)
	end
end

Module.CharacterToMouse = function()
	Root.CFrame = Root.CFrame:Lerp(
		_GetViewMatrix(Root.Position,
			Vector3.new(
				Mouse.Hit.Position.X,
				Root.Position.Y,
				Mouse.Hit.Position.Z
			)
		), Module.Settings.FaceCharacterAlpha
	);
end

return Module
