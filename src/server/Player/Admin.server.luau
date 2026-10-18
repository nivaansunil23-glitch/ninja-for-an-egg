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
--   "ReadyEggs"  every egg growing in your pen is ready to hatch right now
--   "CrackEgg"   cracks the egg you're carrying (knocks you down, egg falls out)
--   "Teleport"   amount = island number (1-8) to stand on it, 0 = back to your pen

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
local PenService = require(Server:WaitForChild("Eggs"):WaitForChild("PenService"))
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
	elseif action == "Teleport" then
		local n = math.floor(amount)
		if n == 0 then
			return PenService.SendHome(player), "Back at your pen"
		end
		local character = player.Character
		local islands = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Islands")
		if not character or not islands then
			return false, "Can't teleport right now"
		end
		for _, island in islands:GetChildren() do
			if island:GetAttribute("IslandNumber") == n then
				local spot = island:FindFirstChild("LandingSpot", true) or island:FindFirstChild("Center")
				local at = if spot and spot:IsA("BasePart") then spot.Position else island:GetPivot().Position
				player:SetAttribute("NoFallCrack", true) -- don't crack a carried egg on arrival
				character:PivotTo(CFrame.new(at + Vector3.new(0, 5, 0)))
				task.delay(1, function()
					player:SetAttribute("NoFallCrack", nil)
				end)
				local name = island:GetAttribute("IslandId") or island.Name
				return true, "Teleported to " .. tostring(name):gsub("(%l)(%u)", "%1 %2")
			end
		end
		return false, "No island " .. n
	elseif action == "CrackEgg" then
		if not EggCarry.IsCarrying(player) then
			return false, "Carry an egg first (Give Egg)"
		end
		EggCarry.AddCracks(player, 1)
		return true, "Crack!"
	elseif action == "ReadyEggs" then
		local n = PenService.ReadyAll(player)
		return n > 0, if n > 0 then n .. " eggs ready to hatch" else "No eggs in your pen"
	end
	return false, "Unknown action"
end
