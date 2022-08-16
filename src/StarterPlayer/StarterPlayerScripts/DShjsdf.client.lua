local Player = game:GetService('Players').LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();

for _, v in game:GetService('StarterPlayer').StarterCharacterScripts:GetChildren() do
	local clone = v:Clone();
	clone.Parent = Character;
end