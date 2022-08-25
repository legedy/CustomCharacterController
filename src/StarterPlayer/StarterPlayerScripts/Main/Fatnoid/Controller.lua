local Types = require(script.Parent._TypeDefinition);

local Camera = workspace.CurrentCamera;

local RunService = game:GetService('RunService');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

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

	_movementValue: {
		isJumping: boolean,
	
		forward: number,
		backward: number,
		left: number,
		right: number
	},

	_PreviousLookVector: Vector3;
	_PreviousCFrameRot: CFrame;
} = {};

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

local function Normalize(vec3: Vector3)
	if (vec3 ~= Vector3.zero) then
		return vec3.Unit;
	end
	return Vector3.zero;
end

local Keybinds = {
	[Enum.KeyCode.W] = {
		Name = 'moveForwardAction',
		Callback = function(_, inputState, _)
			Controller._movementValue.forward = (inputState == Enum.UserInputState.Begin) and 1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.S] = {
		Name = 'moveBackwardAction',
		Callback = function(_, inputState, _)
			Controller._movementValue.backward = (inputState == Enum.UserInputState.Begin) and -1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.A] = {
		Name = 'moveLeftAction',
		Callback = function(_, inputState, _)
			Controller._movementValue.left = (inputState == Enum.UserInputState.Begin) and -1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.D] = {
		Name = 'moveRightAction',
		Callback = function(_, inputState, _)
			Controller._movementValue.right = (inputState == Enum.UserInputState.Begin) and 1 or 0
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

function Controller:Init(Character: Model, Remotes: Types.Remotes, Events: Types.Events, Settings: Types.Settings)
	self.Init = nil;

	local RaycastParam = RaycastParams.new();
	RaycastParam.IgnoreWater = true;
	RaycastParam.FilterDescendantsInstances = {Character};
	RaycastParam.FilterType = Enum.RaycastFilterType.Blacklist;

	self._moveVector = Vector2.zero;
	self._velocity = Vector3.zero;

	self._Events = Events;
	self._Settings = Settings;
	self._Character = Character;
	self._Remotes = Remotes;

	self._RaycastParams = RaycastParam;
	self._DEBUG_MODE = Settings.DEBUG_MODE or false;
	self._Debug = {
		GroundRaycast = VisualDebug.Line.new{
			Adornee = Character.RootPart,
			Color = Color3.fromRGB(255, 0, 0),
			LookVector = -Vector3.yAxis,
			Length = 3,
		},
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

	self._movementValue = {
		isJumping = false,
	
		forward = 0,
		backward = 0,
		left = 0,
		right = 0
	};

	self._PreviousLookVector = Vector3.zAxis;
	self._PreviousCFrameRot = CFrame.new();

	Character.RootPart.Anchored = true;
	Character.RootPart.Position = Vector3.yAxis * 3;

	self:BindContextActions();
	RunService:BindToRenderStep('characterMovement', 200, function(deltaTime)
		self:Step(deltaTime);
	end);
end

function Controller:BindContextActions()
	for EnumKeyCode, Properties in Keybinds do
		ContextActionService:BindActionAtPriority(Properties.Name, Properties.Callback, false,
			Enum.RenderPriority.Input.Value, EnumKeyCode
		);
	end
end

function Controller:UnbindContextActions()
	for _, Properties in Keybinds do
		ContextActionService:UnbindAction(Properties.Name);
	end
end

function Controller:UpdateMovement(inputState: Enum.UserInputState)
	local MovementValues = self._movementValue;
	local PreviousMoving = (self._moveVector ~= Vector2.zero);

	if (inputState == Enum.UserInputState.Cancel) then
		self._moveVector = Vector2.zero;
	else
		self._moveVector = Vector2.new(
			MovementValues.left + MovementValues.right,
			MovementValues.forward + MovementValues.backward
		);
	end

	if (PreviousMoving ~= (self._moveVector ~= Vector2.zero)) then
		self._Events.Walking:Fire(self._moveVector ~= Vector2.zero);
	end
end

function Controller:UpdateJump(Jumping)
	self._movementValue._isJumping = Jumping;
end

function Controller:Step(deltaTime)
	local Settings = self._Settings;
	local CamLookVector = Camera.CFrame.LookVector;

	local Character: Model = self._Character;
	local Root: BasePart = Character.RootPart;

	--> Settings
	local DEBUG = self._Debug;

	local WalkSpeed = Settings.WalkSpeed;
	local JumpSpeed = Settings.JumpSpeed;
	local FloorClampThreshold = Settings.FloorClampThreshold;
	local HipHeight = Settings.HipHeight;

	--[[>
		Raycast downwards with the velocity,
		to prevent the character from phasing
		through the floor when falling at
		high speeds.
	<]]
	local RayResult = workspace:Raycast(
		Root.Position,
		-Vector3.yAxis * (HipHeight - self._velocity.Y),
		self._RaycastParams
	);

	if (RayResult) then
		self._velocity = Vector3.zero;

		local Displacement = (HipHeight - RayResult.Distance);

		if (math.abs(Displacement) > FloorClampThreshold) then
			Character:TranslateBy(
				Vector3.yAxis * (Displacement - FloorClampThreshold)
			);
		elseif (Displacement < 0) then
			Character:TranslateBy(Vector3.yAxis * -Displacement);
		end

		if (self._movementValue._isJumping) then
			self._velocity += Vector3.yAxis * JumpSpeed * deltaTime;
			self._Events.Jumping:Fire();
		end
	else
		self._velocity -= Vector3.yAxis * (Vector3.yAxis * (workspace.Gravity/100*deltaTime));
	end

	local Angle = math.atan2(CamLookVector.X, CamLookVector.Z);
	local Vertical = Vector3.new(math.sin(Angle), 0, math.cos(Angle));
	local Horizontal = Vertical:Cross(Vector3.yAxis);

	local RelativeMoveVector = Normalize(
		(Vertical * self._moveVector.Y) +
		(Horizontal * self._moveVector.X)
	);

	if (self._velocity.Y < 0) then
		self._Events.FreeFalling:Fire(true);
	else
		self._Events.FreeFalling:Fire(false);
	end

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

	if (self._DEBUG_MODE) then
		DEBUG.GroundRaycast:UpdateLength(HipHeight - self._velocity.Y);

		DEBUG.Direction:UpdatePosition(
			Root.Position + Vector3.yAxis * 2
		);

		if (self._moveVector ~= Vector2.zero) then
			DEBUG.Direction:UpdateVector('MoveDirection',
				RelativeMoveVector
			);
			DEBUG.Direction:UpdateVector('CharacterDirection',
				self._PreviousCFrameRot.LookVector
			);
		end
	end

	self._Remotes.Position:Fire(Root.CFrame);
end

return Controller;