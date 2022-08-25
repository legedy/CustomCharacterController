local Workspace = game:GetService("Workspace")
--> h=v²/(2g)

return {
	DEBUG_MODE = true,

	FloorClampThreshold = 0.01,
	HipHeight = 3,
	WalkSpeed = 16,
	JumpSpeed = math.sqrt(2*(Workspace.Gravity) * 7.2),

	Animations = {
		Walk = 'rbxassetid://180426354',
		Jump = 'rbxassetid://125750702',
		Fall = 'rbxassetid://180436148'
	}
};