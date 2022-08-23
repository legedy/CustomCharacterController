local Animator = {};

function Animator:Init(Character, Events, Settings)
	local AnimatorInstance = Character:WaitForChild('Animator');

	self._Events = Events;
	self._Settings = Settings;
	self._AnimatorInstance = AnimatorInstance;
	self._LoadedAnimations = self:LoadAnimations(
		AnimatorInstance, Settings
	);

	self:BindAnimations(self._LoadedAnimations, Events);
end

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

function Animator:BindAnimations(Animations, Events)
	Events.Walking:Connect(function(isWalking)
		if (isWalking) then
			Animations.Walk:Play(0.1);
		else
			Animations.Walk:Stop(0.1);
		end
	end);
end

return Animator;