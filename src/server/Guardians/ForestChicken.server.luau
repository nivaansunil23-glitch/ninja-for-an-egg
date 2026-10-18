--[[
  Forest Island guardian: the blocky chicken (the user's ChickenScript).
  Builds the chicken from smooth Parts and animates it:
    • sleeps on its pad (squats, eyes shut, floating Z's)
    • someone takes an egg from its island → wakes up angry and chases them
      while they carry the egg and stay near its pad
    • then walks back to its pad and falls asleep again
  It stands at the part named "ChickenSpawn" (in Map.Islands.Island1.Guardian);
  that part's GuardsIsland attribute says whose eggs it guards. DAMAGE is 0.
]]

local CFG = {
	SCALE = 4,          -- studs per model unit (4 ≈ 3.5-stud-tall chicken)
	GUARDS = "Forest",  -- island id whose eggs it guards (ChickenSpawn's GuardsIsland wins)
	THIEF_DIST = 20,    -- how close to the egg the player who took it must be
	STOP_DIST = 5,
	SPEED = 16,         -- studs/sec (player walk speed is 16)
	HOME_SPEED = 8,     -- waddling back to its pad
	LEASH = 90,         -- gives up when the thief is this far from its pad
	DAMAGE = 0,         -- set >0 to make pecks hurt
	PECK_COOLDOWN = 1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local S = CFG.SCALE

local spawnMarker = workspace:FindFirstChild("ChickenSpawn", true)
while not spawnMarker do
	task.wait(1)
	spawnMarker = workspace:FindFirstChild("ChickenSpawn", true)
end
local home = spawnMarker.Position
local guards = spawnMarker:GetAttribute("GuardsIsland") or CFG.GUARDS

local model = Instance.new("Model")
model.Name = "ForestChicken"

local COL = {
	feather = Color3.fromRGB(246, 243, 234),
	beak = Color3.fromRGB(245, 166, 35),
	comb = Color3.fromRGB(217, 43, 43),
	eye = Color3.fromRGB(22, 22, 22),
	shine = Color3.fromRGB(255, 255, 255),
}

-- tiny rig: nodes have local pos (model units) + rot (radians); parts hang off nodes
local nodes, parts = {}, {}
local function node(name, parent, x, y, z)
	local n = { name = name, parent = parent, pos = Vector3.new(x, y, z), rot = Vector3.zero }
	nodes[name] = n
	return n
end
local function box(name, n, color, w, h, d, x, y, z, rz)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = Vector3.new(w, h, d) * S
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = model
	table.insert(parts, { part = p, node = n, offset = CFrame.new(x * S, y * S, z * S) * CFrame.Angles(0, 0, rz or 0), size = p.Size })
	return p
end

local HIP = 0.24
local root = node("root", nil, 0, 0, 0)
local body = node("body", root, 0, HIP, 0)
local tail = node("tail", body, 0, 0.34, -0.26)
local wingL = node("wingL", body, 0.23, 0.36, -0.02)
local wingR = node("wingR", body, -0.23, 0.36, -0.02)
local head = node("head", body, 0, 0.36, 0.18)
local legL = node("legL", root, 0.11, HIP, 0.02)
local legR = node("legR", root, -0.11, HIP, 0.02)

local torso = box("Torso", body, COL.feather, 0.46, 0.4, 0.56, 0, 0.2, 0)
box("Chest", body, COL.feather, 0.4, 0.3, 0.1, 0, 0.24, 0.3)
box("Tail", tail, COL.feather, 0.34, 0.3, 0.12, 0, 0.12, -0.04)
box("TailTip", tail, COL.feather, 0.22, 0.14, 0.1, 0, 0.3, -0.06)
box("WingL", wingL, COL.feather, 0.06, 0.28, 0.38, 0.03, -0.13, 0)
box("WingR", wingR, COL.feather, 0.06, 0.28, 0.38, -0.03, -0.13, 0)
local headPart = box("Head", head, COL.feather, 0.34, 0.36, 0.32, 0, 0.2, 0.08)
box("BeakUpper", head, COL.beak, 0.13, 0.06, 0.12, 0, 0.19, 0.3)
box("BeakLower", head, COL.beak, 0.11, 0.04, 0.09, 0, 0.145, 0.285)
box("Wattle", head, COL.comb, 0.07, 0.1, 0.05, 0, 0.08, 0.265)
box("CombFront", head, COL.comb, 0.07, 0.1, 0.08, 0, 0.42, 0.16)
box("CombMid", head, COL.comb, 0.07, 0.14, 0.08, 0, 0.44, 0.08)
box("CombBack", head, COL.comb, 0.07, 0.09, 0.08, 0, 0.415, 0.0)

local eyesOpen, eyesShut, brows = {}, {}, {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	table.insert(eyesOpen, box("Eye" .. n, head, COL.eye, 0.065, 0.075, 0.012, s * 0.09, 0.27, 0.246))
	table.insert(eyesOpen, box("EyeShine" .. n, head, COL.shine, 0.02, 0.02, 0.006, s * 0.09 + 0.015, 0.29, 0.254))
	table.insert(eyesShut, box("EyeShut" .. n, head, COL.eye, 0.075, 0.016, 0.012, s * 0.09, 0.26, 0.246))
	table.insert(brows, box("Brow" .. n, head, COL.eye, 0.09, 0.022, 0.012, s * 0.09, 0.325, 0.248, s * 0.45))
end
for _, l in ipairs({ { legL, "L" }, { legR, "R" } }) do
	box("Shin" .. l[2], l[1], COL.beak, 0.05, 0.2, 0.05, 0, -0.1, 0)
	box("Foot" .. l[2], l[1], COL.beak, 0.13, 0.035, 0.16, 0, -0.2225, 0.04)
end

-- floating Z's while asleep
local zLabels = {}
for i = 1, 3 do
	local bb = Instance.new("BillboardGui")
	bb.Adornee = headPart
	bb.Size = UDim2.new(1.6, 0, 1.6, 0)
	bb.LightInfluence = 0
	bb.Parent = headPart
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = "Z"
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.fromRGB(58, 111, 216)
	t.TextStrokeColor3 = Color3.new(1, 1, 1)
	t.Parent = bb
	zLabels[i] = { gui = bb, label = t }
end

model.PrimaryPart = torso
model.Parent = workspace

-- helpers
local function lerp(a, b, f) return a + (b - a) * f end
local function angLerp(a, b, f) return a + math.atan2(math.sin(b - a), math.cos(b - a)) * f end
local function setVisible(list, on)
	for _, p in ipairs(list) do p.Transparency = on and 0 or 1 end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

-- The player who took an egg from the guarded island. World eggs live in
-- Workspace.Eggs with an Island attribute; picking one up destroys it and puts
-- CarryingEgg on the player who took it.
local thief = nil
local function watchEgg(egg)
	task.defer(function()
		if not egg:IsA("BasePart") or egg:GetAttribute("Island") ~= guards then return end
		egg.Destroying:Connect(function()
			local at = egg.Position
			task.defer(function()
				local best, bestD
				for _, plr in ipairs(Players:GetPlayers()) do
					local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp and plr:GetAttribute("CarryingEgg") then
						local d = (hrp.Position - at).Magnitude
						if d < CFG.THIEF_DIST and (not bestD or d < bestD) then best, bestD = plr, d end
					end
				end
				if best then thief = best end
			end)
		end)
	end)
end
task.spawn(function()
	local eggs = workspace:WaitForChild("Eggs")
	for _, egg in ipairs(eggs:GetChildren()) do watchEgg(egg) end
	eggs.ChildAdded:Connect(watchEgg)
end)

local function thiefTarget()
	if not thief then return nil end
	local char = thief.Parent and thief.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 or not thief:GetAttribute("CarryingEgg")
		or flat(hrp.Position - home).Magnitude > CFG.LEASH then
		thief = nil
		return nil
	end
	return { hrp = hrp, hum = hum }
end

-- state
local pos = home
local heading = 0
local mode = "sleep"
local W = { idle = 0, sleep = 1, run = 0 }
local t, phase, speed, lastPeck = 0, 0, 0, 0

RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.05)
	t += dt

	-- pick behaviour: chase the egg thief, else waddle home, else sleep
	local target = thiefTarget()
	local dist = target and flat(target.hrp.Position - pos).Magnitude
	local toHome = flat(home - pos)
	if target then
		mode = "run"
	elseif toHome.Magnitude > 1.5 then
		mode = "home"
	else
		mode = "sleep"
	end
	local animMode = mode == "home" and "run" or mode
	for k in pairs(W) do W[k] = lerp(W[k], k == animMode and 1 or 0, 1 - math.exp(-5 * dt)) end

	-- movement
	local want = 0
	if mode == "run" then
		local d = target.hrp.Position - pos
		heading = angLerp(heading, math.atan2(d.X, d.Z), 1 - math.exp(-8 * dt))
		want = dist > CFG.STOP_DIST and CFG.SPEED or 0
		if CFG.DAMAGE > 0 and dist <= CFG.STOP_DIST + 1 and t - lastPeck > CFG.PECK_COOLDOWN then
			lastPeck = t
			target.hum:TakeDamage(CFG.DAMAGE)
		end
	elseif mode == "home" then
		heading = angLerp(heading, math.atan2(toHome.X, toHome.Z), 1 - math.exp(-6 * dt))
		want = CFG.HOME_SPEED
	end
	speed = lerp(speed, want, 1 - math.exp(-6 * dt))
	local before = pos
	pos += Vector3.new(math.sin(heading), 0, math.cos(heading)) * speed * dt

	-- stick to the ground, and never walk off the island's edge
	local exclude = { model }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(exclude, plr.Character) end
	end
	local eggs = workspace:FindFirstChild("Eggs")
	if eggs then table.insert(exclude, eggs) end
	rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), rayParams)
	if hit then
		pos = Vector3.new(pos.X, lerp(pos.Y, hit.Position.Y, 1 - math.exp(-20 * dt)), pos.Z)
	else
		pos = before
		speed = 0
	end

	-- pose (same curves as the web preview)
	local run, sl, id = W.run, W.sleep, W.idle
	local stride = math.min(1, speed / CFG.SPEED)
	phase += dt * (6 + 12 * stride) * (run > 0.3 and 1 or 0.3)
	local s = math.sin(phase)
	local angry = (mode == "run" and run or 0) * (1 - stride)
	local breath = math.sin(t * 1.6)
	local drop = -0.185 * sl
	local bob = math.abs(math.cos(phase)) * 0.05 * run * stride + angry * math.abs(math.sin(t * 14)) * 0.04

	body.pos = Vector3.new(0, HIP + drop + bob + breath * 0.006 * sl, 0)
	body.rot = Vector3.new(0.28 * run * stride + 0.06 * sl, 0, s * 0.06 * run * stride)
	torso.Size = Vector3.new(0.46 * (1 + breath * 0.025 * sl), 0.4 * (1 + breath * 0.035 * sl), 0.56) * S

	legL.pos = Vector3.new(0.11, HIP + drop, 0.02)
	legR.pos = Vector3.new(-0.11, HIP + drop, 0.02)
	legL.rot = Vector3.new(s * 0.9 * run * stride - 1.35 * sl, 0, 0)
	legR.rot = Vector3.new(-s * 0.9 * run * stride - 1.35 * sl, 0, 0)

	local peck = math.max(0, math.sin(t * 1.7)) ^ 12 * id
	head.rot = Vector3.new(
		peck * 0.9 + 0.55 * sl + math.sin(phase * 2) * 0.08 * run * stride - 0.2 * angry,
		math.sin(t * 0.8) * 0.55 * id * (1 - peck),
		0.32 * sl + breath * 0.02 * sl
	)
	head.pos = Vector3.new(0, 0.36 - 0.05 * sl, 0.18 + 0.05 * run * stride - 0.06 * sl)

	local flap = run * (stride * (0.5 + math.sin(t * 26) * 0.45) + angry * (0.9 + math.sin(t * 30) * 0.6))
		+ id * math.max(0, math.sin(t * 0.9 + 2)) ^ 30 * 0.8
	wingL.rot = Vector3.new(0, 0, flap)
	wingR.rot = Vector3.new(0, 0, -flap)
	tail.rot = Vector3.new(-0.45 - 0.25 * run + math.sin(t * 3) * 0.04 * id, 0, 0)

	setVisible(eyesOpen, sl < 0.5)
	setVisible(eyesShut, sl >= 0.5)
	setVisible(brows, mode == "run" and run > 0.5)

	for i, z in ipairs(zLabels) do
		local u = (t * 0.35 + (i - 1) / 3) % 1
		z.gui.StudsOffset = Vector3.new(0.6 + u * 1.0 + math.sin(u * 6 + i) * 0.15, 1.4 + u * 2.4, 0)
		z.gui.Size = UDim2.new(0.8 + u * 1.2, 0, 0.8 + u * 1.2, 0)
		local a = math.sin(u * math.pi) * math.max(0, sl * 1.4 - 0.4)
		z.label.TextTransparency = 1 - a
		z.label.TextStrokeTransparency = 1 - a
		z.gui.Enabled = a > 0.01
	end

	-- solve the rig and move every part in one call
	local world = {}
	local function solve(n)
		if world[n] then return world[n] end
		local cf
		if n == root then
			cf = CFrame.new(pos) * CFrame.Angles(0, heading, 0)
		else
			cf = solve(n.parent) * CFrame.new(n.pos * S) * CFrame.Angles(n.rot.X, n.rot.Y, n.rot.Z)
		end
		world[n] = cf
		return cf
	end
	local list, cfs = table.create(#parts), table.create(#parts)
	for i, p in ipairs(parts) do
		list[i] = p.part
		cfs[i] = solve(p.node) * p.offset
	end
	workspace:BulkMoveTo(list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end)
