-- Works out a player's jump power: the jump trained on the trampoline (their
-- level, JumpBalance), times their vertex, times the Coil they wear (and old
-- held gear like the Jump Coil).
-- Players can pick a lower jump (HUD Jump control, data.JumpChoice, 0 = max);
-- it's clamped between JumpBalance.BaseJump and the max. Anything that
-- changes one of those calls JumpPower.Refresh(player).
--
-- Player attributes it keeps up to date:
--   JumpPower     the jump the character really has
--   MaxJump       the most jump you can pick
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

-- The most jump you can have: level x vertex x coil (x old held gear).
function JumpPower.Max(player: Player): number
	local data = PlayerData.Get(player)
	local vertex = VertexConfig.UsedTier(data and data.VertexTier, data and data.EquippedVertex)
	local power = JumpPower.Trained(player) * VertexConfig.Multiplier(vertex)

	-- the Coil you wear (Shops/Wearables sets this)
	power *= player:GetAttribute("CoilMultiplier") or 1

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
	return math.max(JumpBalance.BaseJump, math.floor(power + 0.5))
end

-- A picked jump clamped between the starting jump and the max (0 or more
-- than the max = the max).
function JumpPower.Clamp(player: Player, choice: number?): number
	local max = JumpPower.Max(player)
	if type(choice) ~= "number" or choice ~= choice or choice <= 0 or choice >= max then
		return max
	end
	return math.clamp(math.floor(choice + 0.5), JumpBalance.BaseJump, max)
end

-- The jump the character gets: the jump you picked (data.JumpChoice, the HUD
-- Jump control) capped at your max.
function JumpPower.Get(player: Player): number
	if player:GetAttribute("JumpBoost") == false then
		return JumpBalance.BaseJump
	end
	local data = PlayerData.Get(player)
	return JumpPower.Clamp(player, data and data.JumpChoice)
end

function JumpPower.Refresh(player: Player)
	local data = PlayerData.Get(player)
	local level = data and data.JumpLevel or 1
	player:SetAttribute("TrainedJump", JumpBalance.JumpForLevel(level))
	player:SetAttribute("JumpXPNeeded", JumpBalance.XpForLevel(level))

	local power = JumpPower.Get(player)
	player:SetAttribute("MaxJump", JumpPower.Max(player))
	player:SetAttribute("JumpPower", power)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = power
	end
end

return JumpPower
