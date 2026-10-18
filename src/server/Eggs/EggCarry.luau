--!nonstrict
-- World eggs, carrying, stealing and fall cracks.
--
-- Everything is decided on the server: clients only trigger ProximityPrompts,
-- and every trigger is re-checked here (alive, distance, already carrying,
-- cooldowns) before an egg moves.
--
-- Other systems can read these attributes on the Player while an egg is carried:
--   CarryingEgg (EggId), CarryingEggKg, CarryingEggCracks
-- and can set a "NoFallCrack" attribute (true) on the Player or Character to
-- skip fall cracks, for example while a jetpack or parachute is active.
--
-- A crack knocks you flat for a few seconds (Knockdown) and the egg falls out
-- of your hands onto the ground beside you, wobbles and cracks ("CRACK!"); only
-- you can pick it back up for a moment. The crack that breaks it smashes it
-- into shell bits instead ("SMASH!").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EggConfig = require(ReplicatedStorage.Shared.EggConfig)
local EggRemotes = require(ReplicatedStorage.Shared.EggRemotes)
local EggFactory = require(script.Parent.EggFactory)
local Knockdown = require(script.Parent.Knockdown)
local JumpBalance = require(ReplicatedStorage.Shared.Config.JumpBalance)
local CloudConfig = require(ReplicatedStorage.Shared.Config.CloudConfig)

local S = EggConfig.Settings
local KNOCK_SECONDS = S.CrackKnockSeconds or 4
local rng = Random.new()

local EggCarry = {}

-- [Player] = { Data, Part, ProtectedUntil, AirPeak }
local carried = {}
-- [Player] = os.clock() of their last steal
local lastSteal = {}

local eggFolder = Instance.new("Folder")
eggFolder.Name = "Eggs"
eggFolder.Parent = workspace
EggCarry.Folder = eggFolder

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

local function notify(player, kind, info)
	EggRemotes.EggNotify:FireClient(player, kind, info)
end

local function getAlive(player)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end
	return root, humanoid
end

local function setCarryAttributes(player, data)
	player:SetAttribute("CarryingEgg", data and data.EggId or nil)
	player:SetAttribute("CarryingEggKg", data and data.Kg or nil)
	player:SetAttribute("CarryingEggCracks", data and data.Cracks or nil)
end

local function findGround(position, ignore)
	groundParams.FilterDescendantsInstances = ignore
	return workspace:Raycast(position, Vector3.new(0, -200, 0), groundParams)
end

local trySteal

-- Puts the egg above the player's head. Fails if they're dead or already carrying.
local function attach(player, data)
	local root = getAlive(player)
	if not root or carried[player] then
		return false
	end

	local part = EggFactory.Build(data)
	part.Anchored = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(0, S.CarryHeight + part.Size.Y / 2, 0)
	part:SetAttribute("State", "Carried")
	part:SetAttribute("CarrierUserId", player.UserId)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part

	local egg = EggConfig.Eggs[data.EggId]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = string.format("%s (%.1f kg)", egg.DisplayName, data.Kg)
	prompt.HoldDuration = S.StealHoldSeconds
	prompt.MaxActivationDistance = S.StealDistance
	prompt.RequiresLineOfSight = false
	-- The client script hides this prompt for the carrier.
	prompt:SetAttribute("HideForUserId", player.UserId)
	prompt.Triggered:Connect(function(thief)
		trySteal(thief, player)
	end)
	prompt.Parent = part

	part.Parent = eggFolder

	carried[player] = {
		Data = data,
		Part = part,
		ProtectedUntil = os.clock() + S.StealProtectSeconds,
		AirPeak = nil,
	}
	setCarryAttributes(player, data)
	return true
end

-- Removes the carried egg and returns its data.
local function detach(player)
	local entry = carried[player]
	if not entry then
		return nil
	end
	carried[player] = nil
	entry.Part:Destroy()
	setCarryAttributes(player, nil)
	return entry.Data
end

function trySteal(thief, victim)
	if thief == victim then
		return
	end
	local entry = carried[victim]
	if not entry then
		return
	end
	if carried[thief] then
		notify(thief, "Info", { Text = "You're already carrying an egg." })
		return
	end
	if Knockdown.IsDown(thief) then
		return
	end
	local thiefRoot = getAlive(thief)
	local victimRoot = getAlive(victim)
	if not thiefRoot or not victimRoot then
		return
	end
	if (thiefRoot.Position - victimRoot.Position).Magnitude > S.StealDistance + 4 then
		return
	end
	local now = os.clock()
	if now < entry.ProtectedUntil then
		notify(thief, "Info", { Text = "That egg was just grabbed. Try again in a moment." })
		return
	end
	if lastSteal[thief] and now - lastSteal[thief] < S.StealCooldownSeconds then
		notify(thief, "Info", { Text = "You need to wait before stealing again." })
		return
	end

	lastSteal[thief] = now
	local data = detach(victim)
	attach(thief, data)

	local info = EggFactory.Info(data)
	info.Other = thief.DisplayName
	notify(victim, "Stolen", info)
	local thiefInfo = EggFactory.Info(data)
	thiefInfo.Other = victim.DisplayName
	notify(thief, "StoleEgg", thiefInfo)
end

--[[
Puts an egg on the ground that anyone can pick up.
cframe is where the bottom of the egg sits.
options:
	Lifetime        seconds before it disappears (nil = stays)
	OwnerUserId     with ProtectedUntil: only this player can pick it up until then
	ProtectedUntil  os.clock() time
Returns the egg part. Listen to part.Destroying to know when it's gone.
]]
function EggCarry.SpawnWorldEgg(data, cframe, options)
	options = options or {}
	local egg = EggConfig.Eggs[data.EggId]

	local part = EggFactory.Build(data)
	part.Anchored = true
	part.CFrame = cframe * CFrame.new(0, part.Size.Y / 2, 0)
	part:SetAttribute("State", "World")

	local taken = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = string.format("%s (%.1f kg)", egg.DisplayName, data.Kg)
	prompt.HoldDuration = S.PickupHoldSeconds
	prompt.MaxActivationDistance = S.PickupDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		if taken or not part.Parent then
			return
		end
		if carried[player] then
			notify(player, "Info", { Text = "You can only carry one egg at a time." })
			return
		end
		if Knockdown.IsDown(player) then
			return
		end
		if options.ProtectedUntil and os.clock() < options.ProtectedUntil and player.UserId ~= options.OwnerUserId then
			notify(player, "Info", { Text = "Someone just dropped that egg. Give them a second!" })
			return
		end
		local root = getAlive(player)
		if not root or (root.Position - part.Position).Magnitude > S.PickupDistance + 4 then
			return
		end
		taken = true
		part:Destroy()
		attach(player, data)
		notify(player, "PickedUp", EggFactory.Info(data))
	end)
	prompt.Parent = part

	part.Parent = eggFolder

	if options.Lifetime then
		task.delay(options.Lifetime, function()
			if not taken and part.Parent then
				taken = true
				part:Destroy()
			end
		end)
	end
	return part
end

-- Drops the carried egg on the ground under the player (used on death/respawn).
local function dropEgg(player)
	local entry = carried[player]
	if not entry then
		return
	end
	local position = entry.Part.Position
	local data = detach(player)
	if position.Y < workspace.FallenPartsDestroyHeight + 20 then
		notify(player, "EggBroke", EggFactory.Info(data))
		return
	end
	local ignore = { eggFolder }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local hit = findGround(position, ignore)
	if not hit then
		notify(player, "EggBroke", EggFactory.Info(data))
		return
	end
	EggCarry.SpawnWorldEgg(data, CFrame.new(hit.Position), { Lifetime = S.DroppedEggLifetime })
	notify(player, "EggDropped", EggFactory.Info(data))
end

-- Drops the carried egg on the ground under the player (the Drop Egg button).
function EggCarry.DropCarried(player)
	dropEgg(player)
end

function EggCarry.IsCarrying(player)
	return carried[player] ~= nil
end

-- Returns the carried egg's data table (don't edit it), or nil.
function EggCarry.GetCarried(player)
	local entry = carried[player]
	return entry and entry.Data
end

-- Takes the carried egg away (for example into a pen) and returns its data.
function EggCarry.TakeCarried(player)
	return detach(player)
end

-- Hands an egg straight to a player. Returns false if they can't take it.
function EggCarry.GiveEgg(player, data)
	return attach(player, data)
end

-- Runs fn(alpha) every frame for `seconds`.
local function animate(seconds, fn)
	local t = 0
	while t < seconds do
		t += task.wait()
		fn(math.min(t / seconds, 1))
	end
end

-- The egg tumbles out of the player's hands onto the ground beside them,
-- bounces and wobbles, then cracks (and lies there to be picked back up) or smashes.
local function fallOutOfHands(player, data, from, broken)
	local egg = EggConfig.Eggs[data.EggId]
	local root = getAlive(player)
	local side = if root then root.Position + root.CFrame.RightVector * 3 else from.Position
	local ignore = { eggFolder }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local hit = findGround(side + Vector3.new(0, 3, 0), ignore)
	if not hit or hit.Position.Y < from.Position.Y - 40 then
		-- Nothing to land on beside you: it's gone.
		EggFactory.BreakEffect(from.Position, egg.Color)
		notify(player, "EggBroke", EggFactory.Info(data))
		return
	end
	local ground = hit.Position

	local display = EggFactory.Build(data)
	display.Name = "FallingEgg"
	display.Anchored = true
	display.CanQuery = false
	display.CanTouch = false
	display:SetAttribute("State", "Falling")
	display.CFrame = from
	display.Parent = workspace
	local half = display.Size.Y / 2
	local landAt = ground + Vector3.new(0, half, 0)
	local axis = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
	axis = if axis.Magnitude > 0.1 then axis.Unit else Vector3.xAxis

	-- 1. Tumble out in an arc.
	local start = from.Position
	animate(0.5, function(a)
		local p = start:Lerp(landAt, a) + Vector3.new(0, math.sin(a * math.pi) * 2.5, 0)
		display.CFrame = CFrame.new(p) * CFrame.fromAxisAngle(axis, a * math.pi * 1.5 * (1 - a))
	end)
	-- 2. Land: a little bounce and wobble.
	animate(0.45, function(a)
		local hop = math.abs(math.sin(a * math.pi * 2)) * (1 - a) * 0.8
		local wobble = math.sin(a * math.pi * 5) * 0.35 * (1 - a)
		display.CFrame = CFrame.new(landAt + Vector3.new(0, hop, 0)) * CFrame.Angles(0, 0, wobble)
	end)

	if broken then
		-- 3a. Shakes hard, then smashes.
		animate(0.35, function(a)
			display.CFrame = CFrame.new(landAt + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * 0.15 * a)
		end)
		display:Destroy()
		EggFactory.BreakEffect(landAt, egg.Color, 14)
		EggFactory.PopText(landAt + Vector3.new(0, 2, 0), "SMASH!", Color3.fromRGB(255, 80, 80))
		notify(player, "EggBroke", EggFactory.Info(data))
		return
	end

	-- 3b. Cracks: a few chips fly off and it stays there for you to grab again.
	EggFactory.BreakEffect(landAt, egg.Color, 3)
	EggFactory.PopText(landAt + Vector3.new(0, 2, 0), "CRACK!", Color3.fromRGB(255, 220, 90))
	display:Destroy()
	EggCarry.SpawnWorldEgg(data, CFrame.new(ground) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), {
		Lifetime = S.DroppedEggLifetime,
		OwnerUserId = player.UserId,
		ProtectedUntil = os.clock() + KNOCK_SECONDS + 3,
	})
	notify(player, "EggCracked", EggFactory.Info(data))
end

-- Cracks the carried egg: the player is knocked down and the egg falls out
-- of their hands (see fallOutOfHands). Enough cracks smash it.
function EggCarry.AddCracks(player, amount)
	local entry = carried[player]
	if not entry then
		return
	end
	local data = entry.Data
	data.Cracks += amount
	local from = entry.Part.CFrame
	local broken = data.Cracks >= S.MaxCracks
	detach(player)
	Knockdown.Fall(player, KNOCK_SECONDS)
	task.spawn(fallOutOfHands, player, data, from, broken)
end

-- Cloud steps grow with each gap (60-140 studs near the top), so a normal hop
-- there would crack the egg with fixed heights. The crack heights start above a
-- "safe" drop: one of your own jumps plus the biggest cloud step of the gap you
-- land in. Only falls past that (skipping clouds, falling off an island) crack.
local islandCache, islandCacheAt = nil, 0

local function safeDrop(player, y)
	if os.clock() - islandCacheAt > 10 or not islandCache then
		islandCache = JumpBalance.GetIslands()
		islandCacheAt = os.clock()
	end
	local gap
	for _, island in islandCache do
		gap = island
		if y <= island.TopY + 5 then
			break
		end
	end
	local step = 0
	if gap then
		step = JumpBalance.MaxJumpHeight(gap.RequiredJump) * CloudConfig.StepMax
	end
	local power = player:GetAttribute("JumpPower")
	local ownJump = if type(power) == "number" then JumpBalance.MaxJumpHeight(power) else 0
	return S.CrackSafeJumps * ownJump + S.CrackSafeSteps * step
end

-- Measures each carrier's fall from the highest point of their time in the air.
local function checkFalls()
	for player, entry in carried do
		local root = getAlive(player)
		if root then
			groundParams.FilterDescendantsInstances = { player.Character, eggFolder }
			local grounded = workspace:Raycast(root.Position, Vector3.new(0, -S.GroundCheckDistance, 0), groundParams) ~= nil
			local y = root.Position.Y
			if not grounded then
				entry.AirPeak = math.max(entry.AirPeak or y, y)
			elseif entry.AirPeak then
				local drop = entry.AirPeak - y
				entry.AirPeak = nil
				local skip = player:GetAttribute("NoFallCrack") or player.Character:GetAttribute("NoFallCrack")
				if not skip then
					drop -= safeDrop(player, y)
					if drop >= S.BigCrackFallStuds then
						EggCarry.AddCracks(player, 2)
					elseif drop >= S.CrackFallStuds then
						EggCarry.AddCracks(player, 1)
					end
				end
			end
		end
	end
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(function()
			dropEgg(player)
		end)
	end
end

local function onPlayerAdded(player)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		dropEgg(player)
	end)
end

function EggCarry.Start()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		dropEgg(player)
		detach(player)
		lastSteal[player] = nil
	end)
	RunService.Heartbeat:Connect(checkFalls)
end

return EggCarry
