local Players = game:GetService('Players');
local ServerStorage = game:GetService('ServerStorage');

Players.PlayerAdded:Connect(function(player)
	local Character = ServerStorage.Dummy:Clone();
	Character.Name = player.Name;
	Character.Parent = workspace;

	Character.PrimaryPart:SetNetworkOwner(player);
	Character.PrimaryPart.Anchored = true;

	player.Character = Character;
end)