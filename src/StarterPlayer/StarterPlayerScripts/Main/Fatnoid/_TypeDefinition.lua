--> Type definitions for Modules
export type self = {};

export type Callback = (...any) -> ();

--> SuperClasses
export type Controller = {
	Init: (
		self,
		Character: Model,
		Remotes: Remotes,
		Events: Events,
		Properties: Settings
	) -> (),
	BindContextActions: (self) -> (),
	UnbindContextActions: (self) -> (),
	UpdateMovement: (self, InputState: Enum.UserInputState) -> (),
	UpdateJump: (self, Jumping: boolean) -> (),
	Step: (self, DeltaTime: number) -> (),
};

--> Classes
export type SignalClass = {
	new: () -> SignalObject,
};

export type RemoteClass = {
	new: () -> SignalObject,
};

export type VisualDebug = {
	Line: DebugLineClass,
	Vector: DebugVectorClass
};

export type DebugLineClass = {
	new: () -> DebugLineObject,
};

export type DebugVectorClass = {
	new: () -> DebugVectorObject,
};

--> Object of classes
export type SignalObject = {
	Connect: (self, Callback: Callback) ->  SignalConnection,
	Once: (self, Callback: Callback) ->  SignalConnection,
	Wait: (self, Callback: Callback) -> (...any),
	Fire: (self, ...any) -> (),
	DisconnectAll: (self) -> ()
};

export type RemoteObject = {
	Connect: (self, Callback: Callback) -> (),
	Destroy: (self) -> (),
	Fire: (self, ...any) -> ()
};

export type SignalConnection = {
	Disconnect: (self) -> ()
};

export type DebugLineObject = {
	UpdateCF: (self, CFrame: CFrame) -> (),
	UpdateLength: (self, Length: number) -> (),
	Enable: (self) -> (),
	Disable: (self) -> ()
};

export type DebugVectorObject = {
	UpdatePosition: (self, Position: Vector3) -> (),
	UpdateVector: (self, Name: string, Vector: Vector3) -> (),
	Enable: (self) -> (),
	Disable: (self) -> ()
};

--> Misc
export type Events = {
	CharacterAdded: SignalObject,
	CharacterRemoved: SignalObject,

	Walking: SignalObject,
	Jumping: SignalObject,
	FreeFalling: SignalObject
};

export type Remotes = {
	Position: RemoteObject
};

export type CameraSettings = {
	--> Regular Camera
	CamLockOffset: Vector3,

	--> Isometric Camera
	IsometricCameraDepth: number,
	IsometricHeightOffset: number,
	IsometricFieldOfView: number,

	--> Side Scrolling Camera
	SideCameraDepth: number,
	SideHeightOffset: number,
	SideFieldOfView: number,

	--> Top Down Camera
	TopDownMouseSensitivity: number,
	TopDownDistance: Vector3,
	TopDownDirection: Vector3,
	TopDownOffset: Vector3,
	TopDownFaceMouse: boolean,

	--> Face Character To Mouse
	FaceCharacterAlpha: number
};

export type Settings = {
	DEBUG_MODE: boolean,

	FloorClampThreshold: number,
	FreeFallThreshold: number,

	HipHeight: number,
	WalkSpeed: number,
	JumpSpeed: number,

	CameraSettings: CameraSettings,

	Animations: {
		Walk: 'rbxassetid://180426354',
		Jump: 'rbxassetid://125750702',
		Fall: 'rbxassetid://180436148'
	}
};

return {};