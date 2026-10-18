-- Admin panel actions (client side: client/UI/AdminPanel). Only the game's
-- owner (or a group owner, rank 255) can use them, plus anyone testing in Studio.
-- Admins get the "IsAdmin" attribute so their client shows the panel.
--
-- AdminAction:InvokeServer(action, amount) -> ok, message
--   "AddLevels"  amount = jump levels to add
--   "SetLevel"   amount = jump level to set (1..MaxLevel)
--   "AddMoney"   amount = money to add

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local JumpPower = require(script.Parent:WaitForChild("JumpPower"))

local MAX_MONEY_PER_CLICK = 1e12

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
	return ok and rank >= 255
end

local function setLevel(player: Player, level: number)
	level = math.clamp(math.floor(level), 1, JumpBalance.MaxLevel)
	PlayerData.SetStat(player, "JumpLevel", level)
	PlayerData.SetStat(player, "JumpXP", 0)
	JumpPower.Refresh(player)
	return level
end

local admins = {}

Players.PlayerAdded:Connect(function(player)
	if isAdmin(player) then
		admins[player] = true
		player:SetAttribute("IsAdmin", true)
	end
end)
for _, player in Players:GetPlayers() do
	if isAdmin(player) then
		admins[player] = true
		player:SetAttribute("IsAdmin", true)
	end
end
Players.PlayerRemoving:Connect(function(player)
	admins[player] = nil
end)

Net.Function("AdminAction").OnServerInvoke = function(player, action, amount)
	if not admins[player] then
		return false, "Not an admin"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Data not loaded yet"
	end
	if type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then
		return false, "Bad number"
	end

	if action == "AddLevels" then
		local level = setLevel(player, (data.JumpLevel or 1) + amount)
		return true, "Jump level " .. level
	elseif action == "SetLevel" then
		local level = setLevel(player, amount)
		return true, "Jump level " .. level
	elseif action == "AddMoney" then
		amount = math.clamp(math.floor(amount), 0, MAX_MONEY_PER_CLICK)
		PlayerData.AddMoney(player, amount)
		return true, "Added money"
	end
	return false, "Unknown action"
end
