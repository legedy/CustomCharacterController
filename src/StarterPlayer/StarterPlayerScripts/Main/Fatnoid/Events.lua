local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Signal = require(ReplicatedStorage.Signal);

return {
	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new(),

	Walking = Signal.new(),
};