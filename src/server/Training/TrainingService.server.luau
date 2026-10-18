-- Jump training on the trampoline, like Jump for Phonk / Jump to Steal.
-- The client bounces the player (a character's physics belong to its client)
-- and reports every bounce and click. Here we check the player really is on a
-- trampoline, rate-limit, and hand out Jump XP: XP per bounce and click comes
-- from the player's trampoline tier, XP fills levels, and every level adds
-- jump power. All the numbers are in Shared.Config.JumpBalance.
--
-- Also here: buying trampoline tiers (the Upgrade prompt on each trampoline,
-- or a part named "UpgradePad" inside it) and the Jump Boost on/off switch.
--
-- Player attributes: JumpLevel, JumpXP, TrampolineTier, EquippedTrampoline (saved, mirrored by
-- PlayerData), Training (true while bouncing), JumpBoost (false when off).

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local Trampolines = require(Shared:WaitForChild("Trampolines"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local PlayerFolder = script.Parent.Parent:WaitForChild("Player")
local PlayerData = require(PlayerFolder:WaitForChild("PlayerData"))
local JumpPower = require(PlayerFolder:WaitForChild("JumpPower"))

local COLLISION_GROUP = "JumpTrainers" -- people bouncing pass through each other
local CHECK_SECONDS = 0.5
local PROMPT_NAME = "TrampolineUpgrade"
local PROMPT_SCAN_SECONDS = 5

local startRemote = Net.Event("TrainStart")
local stopRemote = Net.Event("TrainStop")
local bounceRemote = Net.Event("TrainBounce")
local clickRemote = Net.Event("TrainClick")
local gainRemote = Net.Event("TrainGain")
local stoppedRemote = Net.Event("TrainStopped")
local boostRemote = Net.Event("SetJumpBoost")
local openShopRemote = Net.Event("OpenTrampolineShop")
local buyRemote = Net.Function("BuyTrampoline")
local equipRemote = Net.Function("EquipTrampoline")

local groupReady = pcall(function()
	if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP) then
		PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
	end
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)
end)

-- [Player] = { Trampoline, Character, LastBounce, WindowStart, Clicks, Groups, SetNoCrack }
local sessions = {}

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root :: BasePart
	end
	return nil
end

local function isOnPad(trampoline: Instance, root: BasePart): boolean
	local info = Trampolines.GetPadInfo(trampoline)
	return info ~= nil
		and Trampolines.IsOver(info, root.Position, JumpBalance.PadSlack, JumpBalance.BounceHeight + 10)
end

local function stop(player: Player, tellClient: boolean)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	player:SetAttribute("Training", nil)
	local character = session.Character
	if session.SetNoCrack and character and character.Parent then
		character:SetAttribute("NoFallCrack", nil)
	end
	for part, group in session.Groups do
		if part.Parent then
			part.CollisionGroup = group
		end
	end
	if tellClient then
		stoppedRemote:FireClient(player)
	end
end

local function begin(player: Player, trampoline: Instance)
	if not Trampolines.CanUse(trampoline, player.UserId) then
		return nil -- only your own pen's trampoline trains you
	end
	local root = getRoot(player)
	if not root or not isOnPad(trampoline, root) then
		return nil
	end
	local character = player.Character
	local session = sessions[player]
	if session and session.Trampoline == trampoline and session.Character == character then
		return session
	end
	if session then
		stop(player, false)
	end

	session = {
		Trampoline = trampoline,
		Character = character,
		LastBounce = 0,
		WindowStart = 0,
		Clicks = 0,
		Groups = {},
		SetNoCrack = false,
	}
	sessions[player] = session
	player:SetAttribute("Training", true)

	-- Bouncing never cracks a carried egg (EggCarry checks this attribute).
	if character:GetAttribute("NoFallCrack") == nil then
		character:SetAttribute("NoFallCrack", true)
		session.SetNoCrack = true
	end
	if groupReady then
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				session.Groups[part] = part.CollisionGroup
				part.CollisionGroup = COLLISION_GROUP
			end
		end
	end
	return session
end

-- The session of someone bouncing right now. A bounce from someone on a
-- trampoline starts one even if their start message got lost.
local function current(player: Player)
	local session = sessions[player]
	if session then
		return session
	end
	local root = getRoot(player)
	if not root then
		return nil
	end
	local trampoline = Trampolines.FindAt(root.Position, Trampolines.Training, JumpBalance.PadSlack, JumpBalance.BounceHeight + 10)
	return if trampoline then begin(player, trampoline) else nil
end

local function xpPerHit(player: Player): number
	local data = PlayerData.Get(player)
	return JumpBalance.Tier(data and JumpBalance.UsedTier(data.TrampolineTier, data.EquippedTrampoline)).XpPerBounce
end

local function addXp(player: Player, amount: number, kind: string)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local level, xp = data.JumpLevel, data.JumpXP + amount
	local leveled = false
	while level < JumpBalance.MaxLevel and xp >= JumpBalance.XpForLevel(level) do
		xp -= JumpBalance.XpForLevel(level)
		level += 1
		leveled = true
	end
	if level >= JumpBalance.MaxLevel then
		xp = math.min(xp, JumpBalance.XpForLevel(level))
	end

	if leveled then
		PlayerData.SetStat(player, "JumpLevel", level)
	end
	PlayerData.SetStat(player, "JumpXP", xp)
	if leveled then
		JumpPower.Refresh(player)
	end
	gainRemote:FireClient(player, {
		Amount = amount,
		Kind = kind,
		Level = if leveled then level else nil,
		Jump = if leveled then JumpBalance.JumpForLevel(level) else nil,
	})
end

startRemote.OnServerEvent:Connect(function(player, trampoline)
	if Trampolines.IsTrampoline(trampoline, Trampolines.Training) then
		-- If this misses because of lag, the first bounce starts it instead.
		begin(player, trampoline)
	end
end)

stopRemote.OnServerEvent:Connect(function(player)
	stop(player, false)
end)

bounceRemote.OnServerEvent:Connect(function(player)
	local session = current(player)
	if not session then
		return
	end
	local root = getRoot(player)
	if not root or not isOnPad(session.Trampoline, root) then
		return
	end
	local now = os.clock()
	if now - session.LastBounce < JumpBalance.MinBounceSeconds then
		return
	end
	session.LastBounce = now
	addXp(player, xpPerHit(player), "Bounce")
end)

clickRemote.OnServerEvent:Connect(function(player)
	local session = sessions[player]
	if not session then
		return
	end
	local now = os.clock()
	if now - session.WindowStart >= 1 then
		session.WindowStart = now
		session.Clicks = 0
	end
	if session.Clicks >= JumpBalance.MaxClicksPerSecond then
		return
	end
	session.Clicks += 1
	local root = getRoot(player)
	if root and isOnPad(session.Trampoline, root) then
		addXp(player, xpPerHit(player), "Click")
	end
end)

boostRemote.OnServerEvent:Connect(function(player, on)
	if type(on) ~= "boolean" then
		return
	end
	player:SetAttribute("JumpBoost", on)
	JumpPower.Refresh(player)
end)

-- Trampoline upgrades ----------------------------------------------------------

local function islandName(number: number): string
	for _, island in JumpBalance.GetIslands() do
		if island.Number == number then
			return island.Name .. " Island"
		end
	end
	return "island " .. number
end

-- Buying only works standing by a trampoline you own (your pen's).
local BUY_DISTANCE = 30
local function nearOwnTrampoline(player: Player): boolean
	local root = getRoot(player)
	if not root then
		return false
	end
	for _, trampoline in Trampolines.GetAll(Trampolines.Training) do
		local info = Trampolines.CanUse(trampoline, player.UserId) and Trampolines.GetPadInfo(trampoline)
		if info and (info.Center - root.Position).Magnitude <= BUY_DISTANCE + info.Radius then
			return true
		end
	end
	return false
end

buyRemote.OnServerInvoke = function(player, tier)
	if type(tier) ~= "number" then
		return false, "Invalid trampoline"
	end
	if not nearOwnTrampoline(player) then
		return false, "Go to your own trampoline to upgrade it"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again"
	end
	local entry = JumpBalance.TrampolineTiers[tier]
	if not entry then
		return false, "Unknown trampoline"
	end
	if tier <= data.TrampolineTier then
		return false, "You already have this trampoline"
	end
	if tier ~= data.TrampolineTier + 1 then
		return false, `Get the {JumpBalance.Tier(data.TrampolineTier + 1).Name} first`
	end
	if data.IslandReached < entry.Island then
		return false, `Reach {islandName(entry.Island)} first`
	end
	if not PlayerData.SpendMoney(player, entry.Price) then
		return false, `Not enough money ({Format.Money(entry.Price)})`
	end
	PlayerData.SetStat(player, "TrampolineTier", tier)
	PlayerData.SetStat(player, "EquippedTrampoline", tier) -- a new one is put on straight away
	return true, `Unlocked the {entry.Name}! +{entry.XpPerBounce} Jump XP every bounce`
end

-- Use any trampoline you've bought (you own every tier up to TrampolineTier).
equipRemote.OnServerInvoke = function(player, tier)
	if type(tier) ~= "number" or tier ~= tier or tier % 1 ~= 0 then
		return false, "Invalid trampoline"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again"
	end
	local entry = JumpBalance.TrampolineTiers[tier]
	if not entry then
		return false, "Unknown trampoline"
	end
	if tier > data.TrampolineTier then
		return false, "Buy it first"
	end
	PlayerData.SetStat(player, "EquippedTrampoline", tier)
	return true, `Using the {entry.Name}: +{entry.XpPerBounce} Jump XP every bounce`
end

local function promptPartFor(trampoline: Instance): BasePart?
	local upgradePad = trampoline:FindFirstChild("UpgradePad", true)
	if upgradePad and upgradePad:IsA("BasePart") then
		return upgradePad
	end
	if trampoline:IsA("BasePart") then
		return trampoline
	end
	if trampoline:IsA("Model") and trampoline.PrimaryPart then
		return trampoline.PrimaryPart
	end
	return Trampolines.GetPad(trampoline)
end

local function addPrompt(trampoline: Instance)
	local part = promptPartFor(trampoline)
	if not part or part:FindFirstChild(PROMPT_NAME) then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = "Upgrade"
	prompt.ObjectText = "Trampoline"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if not Trampolines.CanUse(trampoline, player.UserId) then
			return -- only the plot owner can upgrade their trampoline
		end
		openShopRemote:FireClient(player)
	end)
end

task.spawn(function()
	while true do
		for _, trampoline in Trampolines.GetAll(Trampolines.Training) do
			addPrompt(trampoline)
		end
		task.wait(PROMPT_SCAN_SECONDS)
	end
end)

-- Stop anyone who left their trampoline without saying so (fell off, died,
-- respawned, got launched away).
task.spawn(function()
	while true do
		task.wait(CHECK_SECONDS)
		for player, session in sessions do
			local root = getRoot(player)
			if
				not root
				or player.Character ~= session.Character
				or not session.Trampoline.Parent
				or not isOnPad(session.Trampoline, root)
			then
				stop(player, true)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)
