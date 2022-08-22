local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerStorage = game:GetService('ServerStorage');

local BridgeNet = require(ReplicatedStorage.BridgeNet);

BridgeNet.Start{
	[BridgeNet.DefaultReceive] = 60,
	[BridgeNet.DefaultSend] = 60
};

local Remote = BridgeNet.CreateBridge("Position")

Remote:Connect(function(player: Player, pos: Vector3)
	workspace[player.Name]:PivotTo(CFrame.new(pos))
end)


Players.PlayerAdded:Connect(function(player)
	local Character = ServerStorage.Dummy:Clone();
	Character.Name = player.Name;
	Character.PrimaryPart.Anchored = true;
	Character.Parent = workspace;
end)