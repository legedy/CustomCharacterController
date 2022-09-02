local Types = require(script.Parent._TypeDefinition);

local Animator = {};

--> Initialize the module
function Animator:Init(Character, Events: Types.Events, Settings)
	local AnimatorInstance = Character:WaitForChild('Animator');

	self._Events = Events;
	self._Settings = Settings;
	self._AnimatorInstance = AnimatorInstance;
	self._LoadedAnimations = self:LoadAnimations(
		AnimatorInstance, Settings
	);

	self:BindAnimations(self._LoadedAnimations, Events);
end

--> Loads animations to a dictionary and returns it
function Animator:LoadAnimations(AnimatorInstance, Settings)
	local LoadedAnimations = {};

	for Name, AnimationId in Settings.Animations do
		local Animation = Instance.new('Animation');
		Animation.Name = Name;
		Animation.AnimationId = AnimationId;

		LoadedAnimations[Name] = AnimatorInstance:LoadAnimation(Animation);
	end

	return LoadedAnimations;
end

--> Binds animations to events
function Animator:BindAnimations(Animations, Events: Types.Events)

	Events.Jumping:Connect(function()
		Animations.Jump:Play();
		print('Jumped')
	end);

	Events.FreeFalling:Connect(function(IsFalling)
		print('Freefalling', IsFalling)
		if (IsFalling) then
			Animations.Fall:Play(.2);
		else
			Animations.Fall:Stop();
		end
	end);

	Events.Walking:Connect(function(isWalking)
		if (isWalking) then
			Animations.Walk:Play(0.1);
		else
			Animations.Walk:Stop(0.1);
		end
	end);
end

return Animator;