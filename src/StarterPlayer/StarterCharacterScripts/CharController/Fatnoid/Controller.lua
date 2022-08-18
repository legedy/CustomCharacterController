local Camera = workspace.CurrentCamera;

local RunService = game:GetService('RunService');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');

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

	self._Events = Events;
	self._Settings = Prop;
	self._Character = Character;

	self._RaycastParams = RaycastParams.new();
	self._RaycastParams.IgnoreWater = true;
	self._RaycastParams.FilterDescendantsInstances = {Character};
	self._RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;

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

	local RayResult = workspace:Raycast(Root.Position, -Vector3.yAxis*3, self._RaycastParams);

	if (RayResult) then
		if (self._movementValue._isJumping) then
			Character:MoveTo(Root.Position + (Vector3.yAxis * 10));
			self:UpdateJump(false);
		end
	else
		Character:MoveTo(Root.Position - (Vector3.yAxis * 9.807) * deltaTime);
	end

	local Angle = math.atan2(CamLookVector.X, CamLookVector.Z);
	local Vertical = Vector3.new(math.sin(Angle), 0, math.cos(Angle));
	local Horizontal = Vertical:Cross(Vector3.yAxis);

	Character:MoveTo(
		Root.Position + Normalize(
			(Vertical   * self._moveVector.Y) +
			(Horizontal * self._moveVector.X)
		) * Settings.WalkSpeed * deltaTime
	);
end

return Controller;