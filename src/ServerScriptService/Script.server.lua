local Players = game:GetService('Players');

Players.PlayerAdded:Connect(function(player)
	workspace.Dummy.PrimaryPart:SetNetworkOwner(player);
	player.Character = workspace.Dummy;
end)