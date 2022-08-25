local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local ServerStorage = game:GetService('ServerStorage');

local BridgeNet = require(ReplicatedStorage.BridgeNet);

BridgeNet.Start{
	[BridgeNet.DefaultReceive] = 60,
	[BridgeNet.DefaultSend] = 60
};

local PlayerPositionUpdate = BridgeNet.CreateBridge('Position');

PlayerPositionUpdate:Connect(function(player: Player, cframe: CFrame)
	-- PlayerPositionUpdate:FireToAllExcept(player, cframe);
	-- workspace[player.Name]:PivotTo(cframe);
end)


Players.PlayerAdded:Connect(function(player)
	local Character = ServerStorage.Dummy:Clone();
	Character.Name = player.Name;
	Character.PrimaryPart.Anchored = true;
	Character.Parent = workspace;
end)