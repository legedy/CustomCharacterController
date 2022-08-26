local Workspace = game:GetService("Workspace")
--> h=v²/(2g)

return {
	DEBUG_MODE = true,

	FreeFallThreshold = -0.05,
	FloorClampThreshold = 0.01,
	HipHeight = 3,
	WalkSpeed = 16,
	JumpSpeed = math.sqrt(2*(Workspace.Gravity) * 7.2),

	CameraSettings = {
		--> Regular Camera
		CamLockOffset = Vector3.new(0, 2, 13),

		--> Isometric Camera
		IsometricCameraDepth = 64,
		IsometricHeightOffset = 2,
		IsometricFieldOfView = 20,

		--> Side Scrolling Camera
		SideCameraDepth = 64,
		SideHeightOffset = 2,
		SideFieldOfView = 20,

		--> Top Down Camera
		TopDownMouseSensitivity = 20,
		TopDownDistance = Vector3.new(0,25,0),
		TopDownDirection = Vector3.new(0, -1, 0),
		TopDownOffset = Vector3.new(0,0,3),
		TopDownFaceMouse = true,

		--> Head Follow Camera
		HeadFollowAlpha = 0.5,

		--> Face Character To Mouse
		FaceCharacterAlpha = 0.5,

		--> Follow Mouse Camera
		MouseCameraEasingStyle = nil, --> If left nil, this will default to a fast quint fallback
		MouseCameraEasingDirection = nil, --> If left nil, this will default to enum.easing.out direction
		MouseCameraSmoothness = 0.03,
		AspectRatio = Vector2int16.new(15, 5), --> X, Y
		MouseAlpha = 0.5,
		MouseYOffset = 1,
		MouseXOffset = 270
	},

	Animations = {
		Walk = 'rbxassetid://180426354',
		Jump = 'rbxassetid://125750702',
		Fall = 'rbxassetid://180436148'
	}
};