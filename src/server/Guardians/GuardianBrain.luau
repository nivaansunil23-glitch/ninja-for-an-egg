--[[
  Shared brain for the island guardian animals (Dog, Frog, ...). The animal
  script builds and poses its body; this decides what it does:
    • sleeps on its pad
    • someone takes an egg from its island → chases them while they carry it
      and stay within LEASH of the pad
    • catches them → takes the egg off them, ragdolls them and flings them
      up and out past the island's edge to fall (they can save themselves on
      the rescue clouds)
    • carries the egg back to one of its island's EggSpawns, puts it down,
      then walks back to its pad and falls asleep again
  The pad is a part named <SpawnName> (e.g. "DogSpawn") somewhere in the map,
  normally Map.Islands.IslandN.Guardian. Its GuardsIsland attribute is the
  island id whose eggs it guards (falls back to the island's IslandId).
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local EggsFolder = ServerScriptService:WaitForChild("Server"):WaitForChild("Eggs")
local EggCarry = require(EggsFolder:WaitForChild("EggCarry"))
local EggFactory = require(EggsFolder:WaitForChild("EggFactory"))

local GuardianBrain = {}
GuardianBrain.__index = GuardianBrain

local DEFAULTS = {
	THIEF_DIST = 20, -- how close to the egg the player who took it must be
	CATCH_DIST = 5, -- this close to the thief = caught
	HOME_SPEED = 8, -- walking back to its pad
	LEASH = 90, -- gives up when the thief is this far from its pad
	FLING_OUT = 85, -- sideways speed away from the island's middle
	FLING_UP = 45, -- small hop up before they fall
	FLING_TIME = 0.35, -- seconds the fling push lasts
	STUN_TIME = 1.5, -- seconds they're ragdolled after the fling
	CARRY_HEIGHT = 5, -- studs above the animal's feet where it holds a taken egg
	CARRY_SPEED = 10, -- walking an egg back
}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function islandOf(part: Instance): Instance?
	local island = part.Parent
	while island and island.Parent and island.Parent.Name ~= "Islands" do
		island = island.Parent
	end
	return if island and island.Parent then island else nil
end

-- Waits for the spawn part, then returns a brain. cfg can override DEFAULTS.
function GuardianBrain.new(spawnName: string, cfg)
	local marker = workspace:FindFirstChild(spawnName, true)
	while not marker do
		task.wait(1)
		marker = workspace:FindFirstChild(spawnName, true)
	end

	local self = setmetatable({}, GuardianBrain)
	self.cfg = setmetatable(cfg or {}, { __index = DEFAULTS })
	self.home = marker.Position
	self.middle = marker.Position
	self.thief = nil
	self.carrying = nil -- { Data, Part, To (Vector3 egg spot) }

	local island = islandOf(marker)
	self.island = island
	local center = island and island:FindFirstChild("Center")
	if center and center:IsA("BasePart") then
		self.middle = center.Position
	end
	self.guards = marker:GetAttribute("GuardsIsland") or (island and (island:GetAttribute("IslandId") or island.Name))

	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Exclude

	task.spawn(function()
		local eggs = workspace:WaitForChild("Eggs")
		for _, egg in eggs:GetChildren() do
			self:_watchEgg(egg)
		end
		eggs.ChildAdded:Connect(function(egg)
			self:_watchEgg(egg)
		end)
	end)
	return self
end

-- World eggs live in Workspace.Eggs with an Island attribute; picking one up
-- destroys it and puts CarryingEgg on the player who took it.
function GuardianBrain:_watchEgg(egg: Instance)
	task.defer(function()
		if not egg:IsA("BasePart") or egg:GetAttribute("Island") ~= self.guards then
			return
		end
		egg.Destroying:Connect(function()
			local at = egg.Position
			task.defer(function()
				local best, bestD
				for _, plr in Players:GetPlayers() do
					local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp and plr:GetAttribute("CarryingEgg") then
						local d = (hrp.Position - at).Magnitude
						if d < self.cfg.THIEF_DIST and (not bestD or d < bestD) then
							best, bestD = plr, d
						end
					end
				end
				if best then
					self.thief = best
				end
			end)
		end)
	end)
end

function GuardianBrain:_thiefTarget()
	local thief = self.thief
	if not thief then
		return nil
	end
	local char = thief.Parent and thief.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if
		not hrp
		or not hum
		or hum.Health <= 0
		or not thief:GetAttribute("CarryingEgg")
		or flat(hrp.Position - self.home).Magnitude > self.cfg.LEASH
	then
		self.thief = nil
		return nil
	end
	return { hrp = hrp, hum = hum }
end

-- Swaps the character's joints for ball sockets for a while so they flop
-- around. Joint changes replicate, so the owning client simulates the flop.
local function ragdoll(character: Model, seconds: number)
	local made = {}
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") and motor.Name ~= "Root" and motor.Part0 and motor.Part1 then
			local a0 = Instance.new("Attachment")
			a0.Name = "RagdollA0"
			a0.CFrame = motor.C0
			a0.Parent = motor.Part0
			local a1 = Instance.new("Attachment")
			a1.Name = "RagdollA1"
			a1.CFrame = motor.C1
			a1.Parent = motor.Part1
			local socket = Instance.new("BallSocketConstraint")
			socket.Name = "Ragdoll"
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.UpperAngle = 60
			socket.TwistLowerAngle = -45
			socket.TwistUpperAngle = 45
			socket.Parent = motor.Part0
			motor.Enabled = false
			table.insert(made, { motor, a0, a1, socket })
		end
	end
	task.delay(seconds, function()
		for _, entry in made do
			if entry[1].Parent then
				entry[1].Enabled = true
			end
			entry[2]:Destroy()
			entry[3]:Destroy()
			entry[4]:Destroy()
		end
	end)
end

-- Where to put a taken egg back: a free EggSpawn on its island (the nearest
-- one if they're all taken), else its pad.
function GuardianBrain:_eggSpot(): Vector3
	local spots = {}
	if self.island then
		for _, d in self.island:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "EggSpawn" then
				table.insert(spots, d)
			end
		end
	end
	local eggs = workspace:FindFirstChild("Eggs")
	local best, bestD
	for _, spot in spots do
		local free = true
		if eggs then
			for _, egg in eggs:GetChildren() do
				if egg:IsA("BasePart") and flat(egg.Position - spot.Position).Magnitude < 3 then
					free = false
					break
				end
			end
		end
		local d = flat(spot.Position - self.home).Magnitude + (if free then 0 else 1e4)
		if not bestD or d < bestD then
			best, bestD = spot, d
		end
	end
	return if best then best.Position - Vector3.new(0, best.Size.Y / 2, 0) else self.home
end

-- Takes the egg off the thief and holds it.
function GuardianBrain:_takeEgg(player: Player)
	local data = EggCarry.TakeCarried(player)
	if not data then
		return
	end
	local part = EggFactory.Build(data)
	for _, d in part:GetDescendants() do
		if d:IsA("ProximityPrompt") or d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	part.Name = "GuardianHeldEgg"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = workspace
	self.carrying = { Data = data, Part = part, To = self:_eggSpot() }
end

-- Puts the held egg back down on its island for anyone to take again.
function GuardianBrain:_placeEgg()
	local held = self.carrying
	self.carrying = nil
	held.Part:Destroy()
	local egg = EggCarry.SpawnWorldEgg(held.Data, CFrame.new(held.To) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	egg:SetAttribute("Island", self.guards)
end

-- Caught! Throw them out past the island's edge. The character is owned by
-- the player's client, so the push is a LinearVelocity on their root part
-- (constraints replicate) and PlatformStand makes them tumble.
function GuardianBrain:_fling(target)
	local cfg = self.cfg
	local hrp, hum = target.hrp, target.hum
	local out = flat(hrp.Position - self.middle)
	out = if out.Magnitude > 0.1 then out.Unit else Vector3.xAxis
	local attachment = Instance.new("Attachment")
	attachment.Name = "GuardianFling"
	attachment.Parent = hrp
	local push = Instance.new("LinearVelocity")
	push.Name = "GuardianFling"
	push.Attachment0 = attachment
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.MaxForce = math.huge
	push.VectorVelocity = out * cfg.FLING_OUT + Vector3.new(0, cfg.FLING_UP, 0)
	push.Parent = hrp
	hum.PlatformStand = true
	if hrp.Parent then
		ragdoll(hrp.Parent, cfg.STUN_TIME)
	end
	task.delay(cfg.FLING_TIME, function()
		push:Destroy()
		attachment:Destroy()
	end)
	task.delay(cfg.STUN_TIME, function()
		if hum.Parent then
			hum.PlatformStand = false
		end
	end)
end

-- Call every frame. Returns mode ("run" chasing, "home" walking back or
-- carrying a taken egg back, "sleep"),
-- the direction to face (Vector3 or nil) and the speed it wants.
function GuardianBrain:Think(pos: Vector3, runSpeed: number)
	local target = self:_thiefTarget()
	if target then
		local d = flat(target.hrp.Position - pos)
		if d.Magnitude <= self.cfg.CATCH_DIST then
			self:_takeEgg(self.thief)
			self:_fling(target)
			self.thief = nil
		else
			return "run", d, runSpeed
		end
	end
	local held = self.carrying
	if held then
		held.Part.CFrame = CFrame.new(pos + Vector3.new(0, self.cfg.CARRY_HEIGHT + held.Part.Size.Y / 2, 0))
		local toSpot = flat(held.To - pos)
		if toSpot.Magnitude > 2 then
			return "home", toSpot, self.cfg.CARRY_SPEED
		end
		self:_placeEgg()
	end
	local toHome = flat(self.home - pos)
	if toHome.Magnitude > 1.5 then
		return "home", toHome, self.cfg.HOME_SPEED
	end
	return "sleep", nil, 0
end

-- Sticks pos to the ground under it. If there's no ground (island edge), stays
-- at `before` instead so it never walks off. Returns the new pos and whether it
-- had to stop.
function GuardianBrain:Ground(pos: Vector3, before: Vector3, model: Instance, dt: number): (Vector3, boolean)
	local exclude = { model }
	for _, plr in Players:GetPlayers() do
		if plr.Character then
			table.insert(exclude, plr.Character)
		end
	end
	local eggs = workspace:FindFirstChild("Eggs")
	if eggs then
		table.insert(exclude, eggs)
	end
	self.rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), self.rayParams)
	if not hit then
		return before, true
	end
	local y = pos.Y + (hit.Position.Y - pos.Y) * (1 - math.exp(-20 * dt))
	return Vector3.new(pos.X, y, pos.Z), false
end

return GuardianBrain
