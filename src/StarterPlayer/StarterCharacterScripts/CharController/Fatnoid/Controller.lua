local Camera = workspace.CurrentCamera;

local RunService = game:GetService('RunService');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local VisualDebug = require(ReplicatedStorage.VisualDebug);

local Controller = {};

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

function Controller:Init(Character, Events, Prop)
	self.Init = nil;

	local RaycastParam = RaycastParams.new();
	RaycastParam.IgnoreWater = true;
	RaycastParam.FilterDescendantsInstances = {Character};
	RaycastParam.FilterType = Enum.RaycastFilterType.Blacklist;

	self._Events = Events;
	self._Settings = Prop;
	self._Character = Character;

	self._RaycastParams = RaycastParam;
	self._Debug = {
		GroundRaycast = VisualDebug.Line.new{
			Adornee = Character.RootPart,
			Color = Color3.fromRGB(255, 0, 0),
			LookVector = -Vector3.yAxis,
			Length = 3,
		},
		Direction = VisualDebug.Vector.new{
			Position = Character.RootPart.Position + Vector3.yAxis * 2,
			Radius = 5,
			Thickness = 5,
			Offset = Vector3.yAxis * .5
		}
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
	self._Debug.GroundRaycast:UpdateLength(3 - self._velocity.Y);

	if (RayResult) then
		self._velocity = Vector3.zero;

		if (self._movementValue._isJumping) then
			self._velocity += Vector3.yAxis * Settings.JumpSpeed * deltaTime;
			self:UpdateJump(false);
		end
	else
		self._velocity -= Vector3.yAxis * (Vector3.yAxis * 0.9807 * deltaTime);
	end

	local Angle = math.atan2(CamLookVector.X, CamLookVector.Z);
	local Vertical = Vector3.new(math.sin(Angle), 0, math.cos(Angle));
	local Horizontal = Vertical:Cross(Vector3.yAxis);

	Character:MoveTo(
		Root.Position + self._velocity + Normalize(
			(Vertical   * self._moveVector.Y) +
			(Horizontal * self._moveVector.X)
		) * Settings.WalkSpeed * deltaTime
	);

	if (self._moveVector ~= Vector2.zero) then
		self._Debug.Direction:UpdateVector(
			(Vertical * self._moveVector.Y) + (Horizontal * self._moveVector.X),
			Root.Position + Vector3.yAxis * 2
		);
	end
end

return Controller;