-- Admin panel actions (client side: client/UI/AdminPanel). Only the game's
-- owner (or a group owner, rank 255) can use them, plus anyone testing in Studio.
-- Admins get the "IsAdmin" attribute so their client shows the panel.
--
-- AdminAction:InvokeServer(action, amount) -> ok, message
--   "AddLevels"  amount = jump levels to add
--   "SetLevel"   amount = jump level to set (1..MaxLevel)
--   "AddMoney"   amount = money to add
--   "ForceDay", "ForceNight", "SkipPhase"   day/night (World/DayNightCycle)
--   "ResetEggs"  clear every island's eggs and spawn a fresh set (none at night)
--   "GiveEgg"    amount = index into EggConfig.EggOrder; puts that egg in your hands

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local JumpPower = require(script.Parent:WaitForChild("JumpPower"))
local Server = script.Parent.Parent
local DayNightConfig = require(Shared:WaitForChild("Config"):WaitForChild("DayNightConfig"))
local DayNightCycle = require(Server:WaitForChild("World"):WaitForChild("DayNightCycle"))
local EggSpawner = require(Server:WaitForChild("Eggs"):WaitForChild("EggSpawner"))
local EggCarry = require(Server:WaitForChild("Eggs"):WaitForChild("EggCarry"))
local EggFactory = require(Server:WaitForChild("Eggs"):WaitForChild("EggFactory"))
local EggConfig = require(Shared:WaitForChild("EggConfig"))

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
	elseif action == "ForceDay" then
		DayNightCycle.SetPhase(false)
		return true, "It's day"
	elseif action == "ForceNight" then
		DayNightCycle.SetPhase(true)
		return true, "It's night"
	elseif action == "SkipPhase" then
		DayNightCycle.Skip()
		return true, if DayNightConfig.IsNight() then "Skipped to night" else "Skipped to day"
	elseif action == "ResetEggs" then
		EggSpawner.ClearAll()
		EggSpawner.FillAll()
		return true, if DayNightConfig.IsNight() then "Eggs cleared (new ones come at day)" else "Eggs reset"
	elseif action == "GiveEgg" then
		local eggId = EggConfig.EggOrder[math.floor(amount)]
		local egg = eggId and EggConfig.Eggs[eggId]
		if not egg then
			return false, "No such egg"
		end
		if EggCarry.IsCarrying(player) then
			return false, "Drop your egg first (G)"
		end
		if not EggCarry.GiveEgg(player, EggFactory.NewData(eggId, EggFactory.RollKg(egg))) then
			return false, "Can't carry an egg right now"
		end
		return true, "Got a " .. egg.DisplayName
	end
	return false, "Unknown action"
end
