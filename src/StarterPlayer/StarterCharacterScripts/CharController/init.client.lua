local Fatnoid = require(script.Fatnoid);

local Player = game:GetService('Players').LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();

print('Initialized!')
Fatnoid:Init(Character);