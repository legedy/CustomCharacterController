local DebugLine = {};
DebugLine.__index = DebugLine;

function DebugLine.new(properties)
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