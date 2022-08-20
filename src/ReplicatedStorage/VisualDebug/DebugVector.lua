local EXCLUDE_YAXIS = Vector3.new(1, 0, 1);

local DebugLine = {};
DebugLine.__index = DebugLine;

local function getPos(angle, scale)
	angle = math.rad(angle);
	return Vector3.new(
		math.cos(angle),
		0,
		math.sin(angle)
	) * scale;
end

local function Circle(adornee: BasePart, color: Color3, alwaysOnTop: boolean, resolution: number, scale: number)
	local Folder = Instance.new('Folder');
	Folder.Name = 'Circle';

	for angle = 0, 360 - (360/resolution), 360/resolution do
		local currentPos, nextPos = getPos(angle, scale), getPos(angle + (360/resolution), scale);

		local Line = Instance.new('LineHandleAdornment');
		Line.Color3 = color;
		Line.Adornee = adornee;
		Line.AlwaysOnTop = alwaysOnTop
		Line.ZIndex = 0;
		Line.Length = (currentPos - nextPos).Magnitude;
		Line.CFrame = CFrame.lookAt(currentPos, nextPos);
		Line.Thickness = 5;
		Line.Parent = Folder;
	end

	return Folder;
end

--[[
	```lua
	-- Adornee: BasePart?
	-- Radius: number?
	-- Vector: Vector3?
	-- Offset: Vector3?
	-- CircleColor: Color3?
	-- VectorColor: Color3?
	-- Thickness: number?
	```
]]
function DebugLine.new(properties)
	local Radius = properties.Radius or 5;
	local AlwaysOnTop = properties.AlwaysOnTop or false;
	local Position = properties.Position or Vector3.zero;
	local CircleColor = properties.CircleColor or Color3.new(1, 0, 0);
	local VectorColor = properties.VectorColor or Color3.new(0, 1, 0);
	local Vector = properties.Vector or Vector3.xAxis;

	local AdorneePart = Instance.new('Part');
	AdorneePart.Anchored = true;
	AdorneePart.CanCollide = false;
	AdorneePart.Position = Position;
	AdorneePart.Size = Vector3.zero;
	AdorneePart.Transparency = 1;

	local lineDebug = Instance.new('LineHandleAdornment');
	lineDebug.Adornee = AdorneePart;
	lineDebug.CFrame = CFrame.lookAt(Vector3.zero, (Vector.Unit * EXCLUDE_YAXIS * Radius));
	lineDebug.Color3 = VectorColor;
	lineDebug.Thickness = properties.Thickness or 5;
	lineDebug.Length = Radius;
	lineDebug.AlwaysOnTop = AlwaysOnTop;
	lineDebug.ZIndex = 0;
	lineDebug.Parent = AdorneePart;

	local CircleFolder = Circle(
		AdorneePart,
		CircleColor,
		AlwaysOnTop,
		40,
		Radius
	);
	CircleFolder.Parent = AdorneePart;
	AdorneePart.Parent = workspace.VisualDebug;
	
	return setmetatable({
		_BasePart = AdorneePart,
		_Line = lineDebug;
		_Position = Position;
		_Radius = Radius;
	}, DebugLine);
end

function DebugLine:UpdatePosition(position: Vector3)
	self._Position = position;
	self._BasePart.Position = position;
end

function DebugLine:UpdateVector(vector: Vector3)
	self._Line.CFrame = CFrame.lookAt(Vector3.zero,
		(vector.Unit * EXCLUDE_YAXIS * self._Radius)
	);
end

function DebugLine:Enable()
	self.Instance.Visible = true;
end

function DebugLine:Disable()
	self.Instance.Visible = false;
end

return DebugLine;