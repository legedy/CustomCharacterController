local Camera = workspace.CurrentCamera;

local RunService = game:GetService('RunService');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local VisualDebug = require(ReplicatedStorage.VisualDebug);

local Controller = {};

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

Controller._movementValue = {
	_isJumping = false,

	forward = 0,
	backward = 0,
	left = 0,
	right = 0
};

Controller._moveVector = Vector2.zero;
Controller._velocity = Vector3.zero;

Controller._Events = {};
Controller._Settings = {};
Controller._Character = nil;
Controller._Remote = nil;

Controller._RaycastParams = nil;
Controller._DEBUG_MODE = false;
Controller._Debug = {};

Controller._PreviousLookVector = Vector3.zAxis;
Controller._PreviousCFrameRot = CFrame.new();

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
			Controller:UpdateJump(inputState ~= Enum.UserInputState.End);

			return Enum.ContextActionResult.Pass
		end
	}
};

function Controller:Init(Character, Position, Events, Prop)
	self.Init = nil;

	local RaycastParam = RaycastParams.new();
	RaycastParam.IgnoreWater = true;
	RaycastParam.FilterDescendantsInstances = {Character};
	RaycastParam.FilterType = Enum.RaycastFilterType.Blacklist;

	self._Events = Events;
	self._Settings = Prop;
	self._Character = Character;
	self._Remote = Position;

	self._RaycastParams = RaycastParam;
	self._DEBUG_MODE = Prop.DEBUG_MODE or false;
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

	local Character = self._Character;
	local Root = Character.RootPart;

	local RayResult = workspace:Raycast(
		Root.Position,
		-Vector3.yAxis * (3 - self._velocity.Y),
		self._RaycastParams
	);

	if (RayResult) then
		self._velocity = Vector3.zero;

		if (self._movementValue._isJumping) then
			self._velocity += Vector3.yAxis * Settings.JumpSpeed;
			--self:UpdateJump(false);
		end
	else
		self._velocity -= Vector3.yAxis * (Vector3.yAxis * (workspace.Gravity/100) * deltaTime);
	end

	local Angle = math.atan2(CamLookVector.X, CamLookVector.Z);
	local Vertical = Vector3.new(math.sin(Angle), 0, math.cos(Angle));
	local Horizontal = Vertical:Cross(Vector3.yAxis);

	local RelativeMoveVector = Normalize(
		(Vertical * self._moveVector.Y) +
		(Horizontal * self._moveVector.X)
	);

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

	(Character :: Model):PivotTo(
		(CFrame.new(Root.Position) * self._PreviousCFrameRot) +
		self._velocity +
		RelativeMoveVector *
		(Settings.WalkSpeed * deltaTime)
	);

	-- Character:TranslateBy(
	-- 	self._velocity +
	-- 	RelativeMoveVector *
	-- 	(Settings.WalkSpeed * deltaTime)
	-- );

	if (self._DEBUG_MODE) then
		self._Debug.GroundRaycast:UpdateLength(3 - self._velocity.Y);

		self._Debug.Direction:UpdatePosition(
			Root.Position + Vector3.yAxis * 2
		);

		if (self._moveVector ~= Vector2.zero) then
			self._Debug.Direction:UpdateVector('MoveDirection',
				RelativeMoveVector
			);
			self._Debug.Direction:UpdateVector('CharacterDirection',
				self._PreviousCFrameRot.LookVector
			);
		end
	end

	self._Remote:Fire(Root.Position);
end

return Controller;