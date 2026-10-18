-- Works out a player's jump power: the jump trained on the trampoline (their
-- level, JumpBalance), times their vertex, times held gear like the Jump Coil.
-- With Jump Boost switched off it's the plain starting jump. Anything that
-- changes one of those calls JumpPower.Refresh(player).
--
-- Player attributes it keeps up to date:
--   JumpPower     the jump the character really has
--   TrainedJump   jump power from the level alone
--   JumpXPNeeded  XP to finish the current level

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local GearConfig = require(Config:WaitForChild("GearConfig"))
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local JumpBalance = require(Config:WaitForChild("JumpBalance"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local JumpPower = {}

-- Jump power from the trained level alone.
function JumpPower.Trained(player: Player): number
	local data = PlayerData.Get(player)
	return JumpBalance.JumpForLevel(data and data.JumpLevel or 1)
end

function JumpPower.Get(player: Player): number
	if player:GetAttribute("JumpBoost") == false then
		return JumpBalance.BaseJump
	end
	local data = PlayerData.Get(player)
	local power = JumpPower.Trained(player) * VertexConfig.Multiplier(data and data.VertexTier)

	local character = player.Character
	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") then
				local gear = GearConfig.Items[child:GetAttribute("GearId")]
				if gear and gear.JumpMultiplier then
					power *= gear.JumpMultiplier
				end
			end
		end
	end
	return math.floor(power + 0.5)
end

function JumpPower.Refresh(player: Player)
	local data = PlayerData.Get(player)
	local level = data and data.JumpLevel or 1
	player:SetAttribute("TrainedJump", JumpBalance.JumpForLevel(level))
	player:SetAttribute("JumpXPNeeded", JumpBalance.XpForLevel(level))

	local power = JumpPower.Get(player)
	player:SetAttribute("JumpPower", power)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = power
	end
end

return JumpPower
