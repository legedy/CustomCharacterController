local Camera = workspace.CurrentCamera;

local RunService = game:GetService('RunService');
local UserInputService = game:GetService('UserInputService');
local ContextActionService = game:GetService('ContextActionService');

local Controller = {};

Controller._forwardValue = 0;
Controller._backwardValue = 0;
Controller._leftValue = 0;
Controller._rightValue = 0;

Controller._isJumping = false;
Controller._moveVector = Vector3.zero;

local Keybinds = {
	[Enum.KeyCode.W] = {
		Name = 'moveForwardAction',
		Callback = function(_, inputState, _)
			Controller._forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.S] = {
		Name = 'moveBackwardAction',
		Callback = function(_, inputState, _)
			Controller._backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.A] = {
		Name = 'moveLeftAction',
		Callback = function(_, inputState, _)
			Controller._leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
			Controller:UpdateMovement(inputState);

			return Enum.ContextActionResult.Pass
		end
	},

	[Enum.KeyCode.D] = {
		Name = 'moveRightAction',
		Callback = function(_, inputState, _)
			Controller._rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
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

function Controller:Init(Character, Signals, Prop)
	self.Init = nil;

	self._Signals = Signals;
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
	if inputState == Enum.UserInputState.Cancel then
		self._moveVector = Vector3.zero;
	else
		local CamLookVector = Camera.CFrame.LookVector;

		self._moveVector = Vector3.new(
			self._leftValue + self._rightValue,
			0,
			self._forwardValue + self._backwardValue
		);
	end
end

function Controller:UpdateJump(Jumping)
	self._isJumping = Jumping;
end

function Controller:Step(deltaTime)
	local CamLookVector = Camera.CFrame.LookVector;
	local Character = self._Character;
	local Root = Character.RootPart;

	local RayResult = workspace:Raycast(Root.Position, -Vector3.yAxis*2, self._RaycastParams);

	if (RayResult) then
		if (self._isJumping) then
			Character:MoveTo(Root.Position + (Vector3.yAxis * 10));
			self:UpdateJump(false);
		end
	else
		Character:MoveTo(Root.Position - (Vector3.yAxis * 9.807) * deltaTime);
		--> Root.Position -= (Vector3.yAxis * workspace.Gravity) * deltaTime;
	end
	Character:MoveTo(Root.Position + ((Vector3.new(CamLookVector.X, 0, CamLookVector.Y).Unit * self._moveVector) * 16) * deltaTime);
	print(Vector3.new(CamLookVector.X, 0, CamLookVector.Y))
	--> Root.Position += (self._moveVector * 16) * deltaTime;
end

return Controller;