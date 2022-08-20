local Players = game:GetService("Players")
local function getPos(angle, scale)
	angle = math.rad(angle);
	return Vector3.new(
		math.cos(angle),
		0,
		math.sin(angle)
	) * scale;
end

local function circle(parent: BasePart, resolution: number, scale: number)
	local Instances = {};

	for angle = 0, 360 - (360/resolution), 360/resolution do
		local currentPos, nextPos = getPos(angle, scale), getPos(angle + (360/resolution), scale);

		local Line = Instance.new('LineHandleAdornment');
		Line.Adornee = parent;
		Line.AlwaysOnTop = true
		Line.ZIndex = 0;
		Line.Length = (currentPos - nextPos).Magnitude;
		Line.CFrame = CFrame.lookAt(currentPos, nextPos);
		Line.Thickness = 5;
		Line.Parent = parent;
		table.insert(Instances, {
			pos = currentPos,
			nextPos = nextPos,
			line = Line
		});
	end

	return Instances;
end

local part = Instance.new('Part');
part.Anchored = true;
part.Position = Vector3.yAxis * 10;
part.Size = Vector3.new(1,0,1) * 20;
part.Parent = workspace;

local e = circle(part, 40, 10);