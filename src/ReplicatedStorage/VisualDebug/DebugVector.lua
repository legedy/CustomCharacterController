local DebugLine = {};
DebugLine.__index = DebugLine;

function DebugLine.new(properties)
	local Radius = properties.Radius or 5;
	local Axis = properties.DebugAxis;
	local Offset = properties.Offset or Vector3.zero;

	local topImage = Instance.new("ImageHandleAdornment")
	topImage.Adornee = properties.Adornee;
	topImage.Image = "rbxassetid://4653037680"
	topImage.Color3 = Color3.fromRGB(255, 255, 255)
	topImage.Size = Vector2.one * Radius;
	topImage.CFrame = CFrame.lookAt(
		Offset, properties.DebugAxis
	);

	local bottomImage = Instance.new("ImageHandleAdornment")
	bottomImage.Adornee = properties.Adornee;
	bottomImage.Image = "rbxassetid://4653037680"
	bottomImage.Color3 = Color3.fromRGB(255, 255, 255)
	bottomImage.Size = Vector2.one * Radius;
	bottomImage.CFrame = CFrame.lookAt(
		Vector3.zero, -properties.DebugAxis
	);

	local lineDebug = Instance.new('LineHandleAdornment');
	lineDebug.Adornee = properties.Adornee;
	lineDebug.CFrame = CFrame.lookAt(
		lineDebug.CFrame.Position,
		lineDebug.CFrame.Position + properties.LookVector
	);
	lineDebug.Color3 = properties.Color or Color3.new(1, 1, 1);
	lineDebug.Thickness = properties.Thickness or 5;
	lineDebug.Length = properties.Length or error('Length arg is required.');
	lineDebug.AlwaysOnTop = true;
	lineDebug.ZIndex = 0;

	if (properties.Adornee == nil) then
		lineDebug.Adornee = workspace.Terrain;

		if (properties.Position and properties.LookVector) then
			lineDebug.CFrame = CFrame.lookAt(
				properties.Position,
				properties.Position + properties.LookVector
			);
		else
			error('No Position or LookVector specified.');
		end
	end

	lineDebug.Parent = workspace.VisualDebug;

	return setmetatable({
		Instance = lineDebug;
	}, DebugLine);
end

function DebugLine:UpdateCF(cframe: CFrame)
	self.Instance.CFrame = cframe;
end

function DebugLine:UpdateLength(length: number)
	self.Instance.Length = length;
end

function DebugLine:Enable()
	self.Instance.Visible = true;
end

function DebugLine:Disable()
	self.Instance.Visible = false;
end

return DebugLine;