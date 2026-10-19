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
--   "GrowEggs"   every egg in your pen jumps halfway to ready (they grow bigger)
--   "CrackEgg"   cracks the egg you're carrying (knocks you down, egg falls out)
--   "EggLineup"  every island egg in rows in front of you (one row per island) for LINEUP_SECONDS
--   "AllGear" / "NoGear"   own every shoe and coil tier / none (amount = tier to keep, 0 = none)
--   "AllTrampolines"  own every trampoline tier (to try equipping them)
--   "TrampolineUp" / "TrampolineReset"  trampoline tier +1 (bought and equipped) / back to Basic
--   "AllItems" / "NoItems"  own every shoe, coil, vertex and trampoline / back to
--                the starting ones (also clears Inventory picks and the jump choice)
--   "JumpChoice" amount = jump power to pick (0 = max), same as the HUD Jump control
--   "Teleport"   amount = island number (1-8) to stand on it, 0 = back to your pen
--   "RebuildClouds"  amount = seed; rebuilds every gap's cloud paths (World/Clouds)
--   "CloudPaths" amount = 1 show / 0 hide neon lines along the cloud paths

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
local GearShop = require(Server:WaitForChild("Shops"):WaitForChild("GearShop"))
local EggConfig = require(Shared:WaitForChild("EggConfig"))
local VertexConfig = require(Shared:WaitForChild("Config"):WaitForChild("VertexConfig"))

local MAX_MONEY_PER_CLICK = 1e12
local LINEUP_SECONDS = 25
local LINEUP_KG = 5

-- Every island egg built by EggFactory (so it looks exactly like in the game),
-- in front of the player: one row per island, the front of each egg facing them.
local function eggLineup(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "No character"
	end
	local old = workspace:FindFirstChild("AdminEggLineup")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "AdminEggLineup"
	local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local forward = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
	local right = forward:Cross(Vector3.yAxis)
	local feet = root.Position - Vector3.new(0, 3, 0)
	local count, plain = 0, {}
	for row, island in EggConfig.Islands do
		local n = #island.Animals
		for col, animal in island.Animals do
			local eggId = EggConfig.EggIdFor(animal.Name)
			local ok, part = pcall(EggFactory.Build, EggFactory.NewData(eggId, LINEUP_KG))
			if ok then
				local pos = feet + forward * (10 + (row - 1) * 6) + right * ((col - (n + 1) / 2) * 5.5)
				pos += Vector3.new(0, part.Size.Y / 2, 0)
				part.Anchored = true
				part.CanQuery = false
				part.CanTouch = false
				part.CFrame = CFrame.lookAt(pos, pos + forward) -- +Z (the design's front) faces the player
				part.Parent = folder
				count += 1
				if not part:FindFirstChildWhichIsA("BasePart") then
					table.insert(plain, eggId)
				end
			else
				warn(`[Admin] EggLineup: {eggId} failed: {part}`)
				table.insert(plain, eggId .. " (error)")
			end
		end
	end
	folder.Parent = workspace
	task.delay(LINEUP_SECONDS, function()
		if folder.Parent then
			folder:Destroy()
		end
	end)
	if #plain > 0 then
		warn("[Admin] EggLineup: no design for " .. table.concat(plain, ", "))
		return true, `{count} eggs, {#plain} without a design (see Output)`
	end
	return true, `{count} eggs for {LINEUP_SECONDS}s`
end

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
	elseif action == "EggLineup" then
		return eggLineup(player)
	elseif action == "TrampolineUp" then
		local tier = math.min((data.TrampolineTier or 1) + 1, #JumpBalance.TrampolineTiers)
		PlayerData.SetStat(player, "TrampolineTier", tier)
		PlayerData.SetStat(player, "EquippedTrampoline", tier)
		return true, `Trampoline tier {tier}: {JumpBalance.Tier(tier).Name}`
	elseif action == "TrampolineReset" then
		PlayerData.SetStat(player, "TrampolineTier", 1)
		PlayerData.SetStat(player, "EquippedTrampoline", 1)
		return true, "Trampoline back to Basic"
	elseif action == "AllTrampolines" then
		PlayerData.SetStat(player, "TrampolineTier", #JumpBalance.TrampolineTiers)
		return true, "You own every trampoline: equip one in the trampoline shop"
	elseif action == "AllItems" or action == "NoItems" then
		local own = action == "AllItems"
		data.VertexTier = if own then #VertexConfig.Tiers else 1
		data.TrampolineTier = if own then #JumpBalance.TrampolineTiers else 1
		if not own then
			data.EquippedTrampoline = 0
			data.EquippedShoes = 0
			data.EquippedCoil = 0
			data.EquippedVertex = 0
			data.JumpChoice = 0
		end
		GearShop.SetAll(player, own) -- marks dirty, refreshes worn gear and jump
		return true, if own then "You own every shop item: see your Inventory" else "Shop items back to the starting ones"
	elseif action == "JumpChoice" then
		data.JumpChoice = if amount <= 0 then 0 else math.floor(amount)
		PlayerData.MarkDirty(player)
		JumpPower.Refresh(player)
		return true, "Jump " .. tostring(player:GetAttribute("JumpPower"))
	elseif action == "AllGear" then
		GearShop.SetAll(player, true)
		return true, "You own every shoe and coil"
	elseif action == "NoGear" then
		GearShop.SetAll(player, false)
		return true, "Shoes and coils removed"
	elseif action == "GrowEggs" then
		local n = PenService.GrowHalf(player)
		return n > 0, if n > 0 then n .. " eggs halfway closer to hatching" else "No eggs in your pen"
	elseif action == "ReadyEggs" then
		local n = PenService.ReadyAll(player)
		return n > 0, if n > 0 then n .. " eggs ready to hatch" else "No eggs in your pen"
	end
	elseif action == "RebuildClouds" or action == "CloudPaths" then
		-- Required here so a missing map never stops the admin panel loading.
		local Clouds = require(Server:WaitForChild("World"):WaitForChild("Clouds"))
		if action == "CloudPaths" then
			Clouds.SetShowPaths(amount ~= 0)
			return true, if amount ~= 0 then "Showing cloud paths (red, green, blue)" else "Cloud paths hidden"
		end
		if Clouds.IsBuilding() then
			return false, "Clouds are already building"
		end
		local seed = math.floor(amount)
		task.spawn(Clouds.BuildAll, seed)
		return true, `Rebuilding clouds (seed {seed}), takes a few seconds`
	end
	return false, "Unknown action"
end
