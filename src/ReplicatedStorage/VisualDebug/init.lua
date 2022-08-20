local LocalizationService = game:GetService("LocalizationService")
local DebugFolder = Instance.new('Folder');
DebugFolder.Name = 'VisualDebug';
DebugFolder.Parent = workspace;

return {
	Line = require(script.DebugLine),
	Vector = require(script.DebugVector)
};