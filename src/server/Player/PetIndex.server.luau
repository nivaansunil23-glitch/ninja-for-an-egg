-- Pet Index rewards (client: client/UI/IndexPanel). Found pets are saved in
-- data.Index by PlayerData.AddPet; this claims an area's reward once every pet
-- of that egg has been found.
--
-- ClaimIndex:InvokeServer(eggId) -> ok, message

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local Config = Shared:WaitForChild("Config")
local IndexConfig = require(Config:WaitForChild("IndexConfig"))
local JumpBalance = require(Config:WaitForChild("JumpBalance"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local JumpPower = require(script.Parent:WaitForChild("JumpPower"))

local busy = {}

Net.Function("ClaimIndex").OnServerInvoke = function(player, eggId)
	if busy[player] or type(eggId) ~= "string" then
		return false, "Try again"
	end
	local area = IndexConfig.GetArea(eggId)
	local data = PlayerData.Get(player)
	if not area or not data then
		return false, "Try again"
	end
	if data.IndexClaimed[eggId] then
		return false, "Already claimed"
	end
	if IndexConfig.FoundIn(area, data.Index) < #area.Pets then
		return false, "Find every " .. area.Name .. " pet first!"
	end

	busy[player] = true
	data.IndexClaimed[eggId] = true
	PlayerData.AddMoney(player, area.RewardMoney)
	local level = math.min((data.JumpLevel or 1) + area.RewardJumpLevels, JumpBalance.MaxLevel)
	PlayerData.SetStat(player, "JumpLevel", level)
	PlayerData.MarkDirty(player)
	JumpPower.Refresh(player)
	busy[player] = nil
	return true, string.format("Claimed %s and +%d jump levels!", Format.Money(area.RewardMoney), area.RewardJumpLevels)
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	busy[player] = nil
end)
