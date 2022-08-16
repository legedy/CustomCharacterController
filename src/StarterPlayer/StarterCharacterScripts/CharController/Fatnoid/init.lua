local Camera = require(script.Camera);
local Controller = require(script.Controller);
local Animator = require(script.Animator);

local Fatnoid = {};

function Fatnoid:Init(Character)
	Camera.EnableShiftLockCamera();
	Controller:Init(Character, {}, {});
end

return Fatnoid;