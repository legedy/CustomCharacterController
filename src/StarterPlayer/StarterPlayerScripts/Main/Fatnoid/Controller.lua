--> Imports all types
local Types = require(script.Parent._TypeDefinition);

local Camera = workspace.CurrentCamera;

--> Get services
local RunService = game:GetService('RunService');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

--> Require visual debug library
local VisualDebug: Types.VisualDebug = require(ReplicatedStorage.VisualDebug);

local Controller: {
	--> Methods
	Init: (
		Types.self,
		Character: Model,
		Remotes: Types.Remotes,
		Events: Types.Events,
		Properties: Types.Settings
	) -> (),
	BindContextActions: (Types.self) -> (),
	UnbindContextActions: (Types.self) -> (),
	UpdateMovement: (Types.self, InputState: Enum.UserInputState) -> (),
	UpdateJump: (Types.self, Jumping: boolean) -> (),
	Step: (Types.self, DeltaTime: number) -> (),

	--> Private properties
	_DEBUG_MODE: boolean;

	_moveVector: Vector2,
	_velocity: Vector3,

	_Events: Types.Events;
	_Settings: Types.Settings;
	_Character: Model;
	_Remotes: Types.Remotes;

	_RaycastParams: RaycastParams;
	_Debug: {
		GroundRaycast: Types.DebugLineObject,
		Direction: Types.DebugVectorObject
	};

	_EventProperties: {
		IsFalling: boolean
	},

	_MovementValues: {
		isJumping: boolean,
	
		forward: number,
		backward: number,
		left: number,
		right: number
	},

	_PreviousLookVector: Vector3;
	_PreviousCFrameRot: CFrame;
} = {};

--> Spherical linear interpolation
local function Slerp(v1, v2, t)
	local r = math.acos(v1:Dot(v2));

	if (math.abs(r) >= 0.001) then
		return (
			v1*math.sin((1 - t)*r) +
			v2*math.sin(t*r)
		) / math.sin(r)
	end

	return v1;
end

--> Normalizes a vector. Similar to Vector3.Unit, but handles division by zero error.
local function Normalize(vec3: Vector3)
	if (vec3 ~= Vector3.zero) then
		return vec3.Unit;
	end
	return Vector3.zero;
end

--> Assign each KeyCode with Name and Callback method
local Keybinds = {
	[Enum.KeyCode.W] = {
		Name = 'moveForwardAction',
		Callback = function(_, inputState, _)
			Controller._MovementValues.forward = (inputState == Enum.UserInputState.Begin) and 1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.S] = {
		Name = 'moveBackwardAction',
		Callback = function(_, inputState, _)
			Controller._MovementValues.backward = (inputState == Enum.UserInputState.Begin) and -1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.A] = {
		Name = 'moveLeftAction',
		Callback = function(_, inputState, _)
			Controller._MovementValues.left = (inputState == Enum.UserInputState.Begin) and -1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.D] = {
		Name = 'moveRightAction',
		Callback = function(_, inputState, _)
			Controller._MovementValues.right = (inputState == Enum.UserInputState.Begin) and 1 or 0
			Controller:UpdateMovement(inputState);
			
			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.Space] = {
		Name = 'jumpAction',
		Callback = function(_, inputState, _)
			Controller:UpdateJump(inputState == Enum.UserInputState.Begin);

			return Enum.ContextActionResult.Pass
		end
	}
};

--> Initialize the module
function Controller:Init(Character: Model, Remotes: Types.Remotes, Events: Types.Events, Settings: Types.Settings)
	self.Init = nil;

	--> Create new raycast parameters
	local RaycastParam = RaycastParams.new();
	RaycastParam.IgnoreWater = true;
	RaycastParam.FilterDescendantsInstances = {Character};
	RaycastParam.FilterType = Enum.RaycastFilterType.Blacklist;

	--> Move vector is the keybind input in the X and Z axis
	self._moveVector = Vector2.zero;
	--> Velocity is the current velocity of the character
	self._velocity = Vector3.zero;

	--> Set all parameters to the controller
	self._Events = Events;
	self._Settings = Settings;
	self._Character = Character;
	self._Remotes = Remotes;

	--> Set raycast parameter
	self._RaycastParams = RaycastParam;
	--> Set debug mode, if DEBUG_MODE is nil, it will default to false
	self._DEBUG_MODE = Settings.DEBUG_MODE or false;
	self._Debug = { --> Create debug objects to visualize the controller
		--> Creates a LineHandleAdornment to visualize the raycast
		GroundRaycast = VisualDebug.Line.new{
			Adornee = Character.RootPart,
			Color = Color3.fromRGB(255, 0, 0),
			LookVector = -Vector3.yAxis,
			Length = 3,
		},
		--> Creates circle and vectors to visualize the vectors given
		Direction = VisualDebug.Vector.new({
			Position = Vector3.zero + Vector3.yAxis * 2,
			CircleColor = Color3.fromRGB(0, 0, 255),
			Radius = 5,
			Thickness = 5
		}, {
			MoveDirection = {
				Color = Color3.fromRGB(50, 255, 50),
				Vector = Vector3.new(1, 0, 0)
			},
			CharacterDirection = {
				Color = Color3.fromRGB(255, 50, 50),
				Vector = Vector3.new(0, 0, 1)
			}
		})
	};

	--> Set event properties
	self._EventProperties = {
		IsFalling = false
	}

	--> Set movement values for the controller
	self._MovementValues = {
		isJumping = false,
	
		forward = 0,
		backward = 0,
		left = 0,
		right = 0
	};

	--> Set previous look vector to the current look vector for the Step method to interpolate them
	self._PreviousLookVector = Vector3.zAxis;
	self._PreviousCFrameRot = CFrame.new();

	--> Anchor and set position so the character doesn't go crazy due to physics and always spawns at the same position
	Character.RootPart.Anchored = true;
	Character.RootPart.Position = Vector3.yAxis * 3;

	self:BindContextActions();
	--> Call the Step method so it actually runs duh
	RunService:BindToRenderStep('characterMovement', 200, function(deltaTime)
		self:Step(deltaTime);
	end);
end

--> Bind the keybinds to the ContextActionService
function Controller:BindContextActions()
	for EnumKeyCode, Properties in Keybinds do
		ContextActionService:BindActionAtPriority(Properties.Name, Properties.Callback, false,
			Enum.RenderPriority.Input.Value, EnumKeyCode
		);
	end
end

--> Unbind the keybinds
function Controller:UnbindContextActions()
	for _, Properties in Keybinds do
		ContextActionService:UnbindAction(Properties.Name);
	end
end

--> Update the move vector (Keybind inputs to vector2)
function Controller:UpdateMovement(inputState: Enum.UserInputState)
	local MovementValues = self._MovementValues; --> Current movement values
	local PreviousMoving = (self._moveVector ~= Vector2.zero); --> Was moving previously

	--> If the state is cancelled, set moveVector to 0
	if (inputState == Enum.UserInputState.Cancel) then
		self._moveVector = Vector2.zero;
	else
		--> If state wasn't cancelled, convert the 4 keybind values to a vector2
		self._moveVector = Vector2.new(
			MovementValues.left + MovementValues.right,
			MovementValues.forward + MovementValues.backward
		);
	end

	--> If the character wasn't moving before or moving now, fire the signal
	if (PreviousMoving ~= (self._moveVector ~= Vector2.zero)) then
		self._Events.Walking:Fire(self._moveVector ~= Vector2.zero);
	end
end

--> Update the jump state
function Controller:UpdateJump(Jumping)
	self._MovementValues._isJumping = Jumping;
end

--[[
	Step method which handles the movement of the character every post-render.
]]
function Controller:Step(deltaTime)
	local Settings = self._Settings;
	local EventProperties = self._EventProperties;
	local CamLookVector = Camera.CFrame.LookVector;

	local Character: Model = self._Character;
	local Root: BasePart = Character.RootPart;

	--> Settings
	local DEBUG = self._Debug;

	local WalkSpeed = Settings.WalkSpeed;
	local JumpSpeed = Settings.JumpSpeed;
	local HipHeight = Settings.HipHeight;

	local FloorClampThreshold = Settings.FloorClampThreshold;
	local FreeFallThreshold = Settings.FreeFallThreshold;

	--[[>
		Raycast downwards with the velocity,
		to prevent the character from phasing
		through the floor when falling at
		high speeds.
	<]]
	local RayResult = workspace:Raycast(
		Root.Position,
		-Vector3.yAxis * (HipHeight + 1 - self._velocity.Y),
		self._RaycastParams
	);

	if (RayResult) then
		self._velocity = Vector3.zero;

		--> Gets distance from HipHeight to the floor
		local Displacement = (HipHeight - RayResult.Distance);

		if (math.abs(Displacement) > FloorClampThreshold) then
			--> If the character is falling at a high speed, clamp to nearest floor
			Character:TranslateBy(
				Vector3.yAxis * (Displacement - FloorClampThreshold)
			);
		elseif (Displacement < 0) then
			--> If the character is below the floor, clamp to the floor
			Character:TranslateBy(Vector3.yAxis * -Displacement);
		end

		--> If the character is on the ground and is jumping, set the velocity to the jump speed
		if (self._MovementValues._isJumping) then
			self._velocity += Vector3.yAxis * JumpSpeed * deltaTime;
			self._Events.Jumping:Fire();
		end
	else
		--> Apply gravity to the character
		self._velocity -= Vector3.yAxis * (Vector3.yAxis * (workspace.Gravity/100*deltaTime));
	end

	--> Get camera Y angle
	local Angle = math.atan2(CamLookVector.X, CamLookVector.Z);
	--> Get the LookVector of the camera
	local Vertical = Vector3.new(math.sin(Angle), 0, math.cos(Angle));
	--> Get the RightVector of the camera
	local Horizontal = Vertical:Cross(Vector3.yAxis);

	--> Final movement vector relative to camera
	local RelativeMoveVector = Normalize(
		(Vertical * self._moveVector.Y) +
		(Horizontal * self._moveVector.X)
	);

	--> Handle jump state
	if (self._velocity.Y < FreeFallThreshold and not EventProperties.IsFalling) then
		self._Events.FreeFalling:Fire(true);
		EventProperties.IsFalling = true;
	elseif (self._velocity.Y >= FreeFallThreshold and EventProperties.IsFalling) then
		self._Events.FreeFalling:Fire(false);
		EventProperties.IsFalling = false;
	end

	--> Smoothly rotate the character to the direction it's moving
	if (self._moveVector ~= Vector2.zero) then
		local CurrentLookVector = Slerp(
			self._PreviousLookVector,
			RelativeMoveVector:Cross(Vector3.yAxis),
			.15
		);

		self._PreviousCFrameRot = CFrame.fromMatrix(
			Vector3.zero,
			CurrentLookVector,
			Vector3.yAxis
		);

		self._PreviousLookVector = CurrentLookVector;
	end

	--> Translate the character by the velocity and move vector
	Character:PivotTo(
		(CFrame.new(Root.Position) * self._PreviousCFrameRot) +
		self._velocity +
		RelativeMoveVector *
		(WalkSpeed * deltaTime)
	);

	-- Character:TranslateBy(
	-- 	self._velocity +
	-- 	RelativeMoveVector *
	-- 	(WalkSpeed * deltaTime)
	-- );

	--> Debug module
	if (self._DEBUG_MODE) then
		--> Display raycast length
		DEBUG.GroundRaycast:UpdateLength(HipHeight - self._velocity.Y);

		--> Update the visual debug position
		DEBUG.Direction:UpdatePosition(
			Root.Position + Vector3.yAxis * 2
		);

		--> Update the direction of the debug ray when vector's magnitude isn't 0 to avoid visual bugs with LineHandleAdornment
		if (self._moveVector ~= Vector2.zero) then
			DEBUG.Direction:UpdateVector('MoveDirection',
				RelativeMoveVector
			);
			DEBUG.Direction:UpdateVector('CharacterDirection',
				self._PreviousCFrameRot.LookVector
			);
		end
	end

	--> Send character's cframe so server can replicate it
	self._Remotes.Position:Fire(Root.CFrame);
end

return Controller;