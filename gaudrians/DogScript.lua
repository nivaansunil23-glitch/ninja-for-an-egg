--[[
  Blocky Dog — paste into a Script in ServerScriptService.
  Builds the dog from Parts (no import needed) and animates it:
    • no player within SLEEP_DIST  → sleeps (lies down, head on paws, eyes shut, floating Z's)
    • player within SLEEP_DIST     → idle (crouched, snarling, hackles up, glaring red eyes)
    • player within CHASE_DIST     → charges the nearest player; at their feet it lunges and snaps
  Optional: put a Part named "DogSpawn" in Workspace to set where it spawns.
]]

local CFG = {
	SCALE = 4,          -- studs per model unit (4 ≈ 3-stud-tall dog)
	SLEEP_DIST = 70,
	CHASE_DIST = 40,
	STOP_DIST = 6,
	SPEED = 18,         -- studs/sec (player walk speed is 16, so it can catch you)
	LEASH = 150,        -- max distance from spawn
	DAMAGE = 10,        -- per bite; set 0 for harmless
	BITE_COOLDOWN = 1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local S = CFG.SCALE

local spawnMarker = workspace:FindFirstChild("DogSpawn")
local home = spawnMarker and spawnMarker.Position or Vector3.new(0, 0, 0)

local model = Instance.new("Model")
model.Name = "Dog"

local COL = {
	fur = Color3.fromRGB(110, 76, 50),
	dark = Color3.fromRGB(36, 24, 15),
	white = Color3.fromRGB(185, 138, 92),
	nose = Color3.fromRGB(17, 17, 17),
	tongue = Color3.fromRGB(142, 42, 46),
	collar = Color3.fromRGB(138, 28, 20),
	tag = Color3.fromRGB(201, 206, 210),
	fang = Color3.fromRGB(247, 244, 234),
	red = Color3.fromRGB(255, 42, 26),
}

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
	table.insert(parts, { part = p, node = n, offset = CFrame.new(x * S, y * S, z * S) * CFrame.Angles(0, 0, rz or 0) })
	return p
end

local HIP = 0.3
local root = node("root", nil, 0, 0, 0)
local body = node("body", root, 0, HIP, 0)
local tail = node("tail", body, 0, 0.24, -0.32)
local head = node("head", body, 0, 0.26, 0.32)
local jaw = node("jaw", head, 0, 0.04, 0.2)
local tongue = node("tongue", jaw, 0, 0.005, 0.06)
local earL = node("earL", head, 0.16, 0.26, 0.02)
local earR = node("earR", head, -0.16, 0.26, 0.02)
local hackles = node("hackles", body, 0, 0.29, 0)
local legs = {}
for _, l in ipairs({ { 1, 0.22, "FL" }, { -1, 0.22, "FR" }, { 1, -0.22, "BL" }, { -1, -0.22, "BR" } }) do
	local n = node("leg" .. l[3], root, l[1] * 0.11, HIP, l[2])
	n.front, n.side, n.z = l[2] > 0, l[1], l[2]
	box("Leg" .. l[3], n, COL.fur, 0.1, 0.34, 0.1, 0, -0.12, 0)
	box("Paw" .. l[3], n, COL.white, 0.12, 0.05, 0.15, 0, -0.275, 0.02)
	table.insert(legs, n)
end

local torso = box("Torso", body, COL.fur, 0.34, 0.3, 0.66, 0, 0.13, 0)
box("BackPatch", body, COL.dark, 0.26, 0.02, 0.3, 0, 0.285, -0.06)
box("ChestBib", body, COL.white, 0.24, 0.2, 0.04, 0, 0.1, 0.34)
box("Collar", body, COL.collar, 0.3, 0.07, 0.12, 0, 0.22, 0.3)
for i, x in ipairs({ -0.11, 0, 0.11 }) do box("CollarSpike" .. i, body, COL.tag, 0.035, 0.035, 0.05, x, 0.22, 0.38) end
box("CollarSpikeL", body, COL.tag, 0.05, 0.035, 0.035, 0.17, 0.22, 0.3)
box("CollarSpikeR", body, COL.tag, 0.05, 0.035, 0.035, -0.17, 0.22, 0.3)
for i, z in ipairs({ 0.2, 0.08, -0.04, -0.16 }) do
	box("Hackle" .. i, hackles, COL.dark, 0.05, 0.08 - (i - 1) * 0.01, 0.05, 0, 0, z)
end
box("Tail", tail, COL.fur, 0.07, 0.07, 0.26, 0, 0, -0.12)
box("TailTip", tail, COL.white, 0.075, 0.075, 0.06, 0, 0, -0.26)
local headPart = box("Head", head, COL.fur, 0.3, 0.28, 0.28, 0, 0.14, 0.06)
box("Snout", head, COL.white, 0.17, 0.1, 0.16, 0, 0.09, 0.26)
box("Nose", head, COL.nose, 0.08, 0.06, 0.04, 0, 0.135, 0.35)
box("EyePatch", head, COL.dark, 0.11, 0.12, 0.008, 0.08, 0.19, 0.202)
box("Jaw", jaw, COL.white, 0.15, 0.05, 0.13, 0, -0.015, 0.065)
box("Mouth", tongue, COL.tongue, 0.08, 0.015, 0.14, 0, 0.005, 0.07)
box("EarL", earL, COL.dark, 0.05, 0.2, 0.13, 0.005, -0.09, 0)
box("EarR", earR, COL.dark, 0.05, 0.2, 0.13, -0.005, -0.09, 0)

local eyesOpen, eyesShut, brows = {}, {}, {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	table.insert(eyesOpen, box("Eye" .. n, head, COL.nose, 0.06, 0.07, 0.012, s * 0.08, 0.19, 0.21))
	local glow = box("EyeGlow" .. n, head, COL.red, 0.03, 0.03, 0.006, s * 0.08, 0.185, 0.218)
	glow.Material = Enum.Material.Neon
	table.insert(eyesOpen, glow)
	table.insert(brows, box("Brow" .. n, head, COL.dark, 0.1, 0.03, 0.02, s * 0.08, 0.235, 0.214, s * 0.5))
	box("FangUp" .. n, head, COL.fang, 0.025, 0.05, 0.025, s * 0.05, 0.03, 0.32)
	box("FangLow" .. n, jaw, COL.fang, 0.022, 0.04, 0.022, s * 0.045, 0.025, 0.11)
	table.insert(eyesShut, box("EyeShut" .. n, head, COL.nose, 0.07, 0.014, 0.012, s * 0.08, 0.18, 0.21))
end

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

local function lerp(a, b, f) return a + (b - a) * f end
local function angLerp(a, b, f) return a + math.atan2(math.sin(b - a), math.cos(b - a)) * f end
local function pulse(x, p) return math.max(0, math.sin(x)) ^ p end
local function setVisible(list, on)
	for _, p in ipairs(list) do p.Transparency = on and 0 or 1 end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function nearestPlayer(from)
	local best, bestD
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
			if not bestD or d < bestD then best, bestD = { hrp = hrp, hum = hum }, d end
		end
	end
	return best, bestD
end

local pos = home
local heading = 0
local mode = "sleep"
local W = { idle = 0, sleep = 1, run = 0 }
local t, phase, speed, lastBite = 0, 0, 0, 0

RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.05)
	t += dt

	local target, dist = nearestPlayer(pos)
	if target and dist < CFG.CHASE_DIST and (pos - home).Magnitude < CFG.LEASH then
		mode = "run"
	elseif target and dist < CFG.SLEEP_DIST then
		mode = "idle"
	else
		mode = "sleep"
	end
	for k in pairs(W) do W[k] = lerp(W[k], k == mode and 1 or 0, 1 - math.exp(-5 * dt)) end

	local want = 0
	if mode == "run" then
		local d = target.hrp.Position - pos
		heading = angLerp(heading, math.atan2(d.X, d.Z), 1 - math.exp(-8 * dt))
		want = dist > CFG.STOP_DIST and CFG.SPEED or 0
		if CFG.DAMAGE > 0 and dist <= CFG.STOP_DIST + 1 and t - lastBite > CFG.BITE_COOLDOWN then
			lastBite = t
			target.hum:TakeDamage(CFG.DAMAGE)
		end
	elseif mode == "idle" and target then
		local d = target.hrp.Position - pos
		heading = angLerp(heading, math.atan2(d.X, d.Z), 1 - math.exp(-1.5 * dt))
	end
	speed = lerp(speed, want, 1 - math.exp(-6 * dt))
	pos += Vector3.new(math.sin(heading), 0, math.cos(heading)) * speed * dt

	local exclude = { model }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(exclude, plr.Character) end
	end
	rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -60, 0), rayParams)
	if hit then pos = Vector3.new(pos.X, lerp(pos.Y, hit.Position.Y, 1 - math.exp(-20 * dt)), pos.Z) end

	-- pose (same curves as the web preview)
	local run, sl, id = W.run, W.sleep, W.idle
	local stride = math.min(1, speed / CFG.SPEED)
	phase += dt * (5 + 12 * stride)
	local s, c = math.sin(phase), math.cos(phase)
	local ex = run * (1 - stride)
	local lunge = pulse(t * 6, 3)
	local breath = math.sin(t * 1.5)
	local growl = math.sin(t * 47) * 0.5 + math.sin(t * 31) * 0.5
	local mad = (id + run) * (1 - sl)
	local crouch = 0.06 * id + 0.04 * ex
	local pitch = c * 0.1 * run * stride + 0.08 * id + lunge * 0.1 * ex

	body.pos = Vector3.new(0, HIP - 0.22 * sl - crouch + math.abs(s) * 0.05 * run * stride + breath * 0.006 * sl + growl * 0.004 * mad, lunge * 0.12 * ex)
	body.rot = Vector3.new(pitch, 0, 0)
	torso.Size = Vector3.new(0.34 * (1 + breath * 0.03 * sl), 0.3 * (1 + breath * 0.04 * sl + growl * 0.01 * mad), 0.66) * S
	hackles.pos = Vector3.new(0, 0.24 + 0.05 * mad + growl * 0.004 * mad, 0)

	for _, l in ipairs(legs) do
		local ph = (l.front and phase or phase + math.pi * 0.9) + l.side * 0.35
		local ly = HIP - crouch - math.sin(pitch) * l.z
		local brace = math.acos(math.min(1, ly / HIP))
		l.pos = Vector3.new(l.side * 0.11, ly - 0.22 * sl, l.z + (l.front and lunge * 0.12 * ex or 0))
		l.rot = Vector3.new(math.sin(ph) * 0.85 * run * stride - (l.front and brace or -brace) - 1.5 * sl, 0, 0)
	end

	head.rot = Vector3.new(
		0.25 * sl + c * 0.08 * run * stride + 0.18 * id + 0.1 * ex - lunge * 0.15 * ex + growl * 0.01 * id,
		math.sin(t * 0.5) * 0.15 * id,
		0.15 * sl
	)
	head.pos = Vector3.new(0, 0.26 - 0.14 * sl - 0.03 * id, 0.32 + 0.04 * sl + 0.04 * run * stride + 0.03 * id)

	jaw.rot = Vector3.new((0.12 + growl * 0.03) * id + (0.35 + 0.1 * s) * run * stride + 0.5 * (1 - lunge) * ex, 0, 0)

	for i, e in ipairs({ earL, earR }) do
		local sg = i == 1 and 1 or -1
		e.rot = Vector3.new(1.1 * mad + math.sin(phase * 2) * 0.15 * run * stride, 0, sg * (0.08 + 0.25 * sl - 0.1 * mad))
	end

	tail.rot = Vector3.new(0.35 * id + 0.25 * run - 0.2 * sl, growl * 0.05 * mad + 1.3 * sl, 0)

	setVisible(eyesOpen, sl < 0.5)
	setVisible(eyesShut, sl >= 0.5)
	setVisible(brows, sl < 0.5)

	for i, z in ipairs(zLabels) do
		local u = (t * 0.35 + (i - 1) / 3) % 1
		z.gui.StudsOffset = Vector3.new(0.6 + u * 1.0 + math.sin(u * 6 + i) * 0.15, 1.5 + u * 2.4, 0)
		z.gui.Size = UDim2.new(0.8 + u * 1.2, 0, 0.8 + u * 1.2, 0)
		local a = math.sin(u * math.pi) * math.max(0, sl * 1.4 - 0.4)
		z.label.TextTransparency = 1 - a
		z.label.TextStrokeTransparency = 1 - a
		z.gui.Enabled = a > 0.01
	end

	local world = {}
	local function solve(n)
		if world[n] then return world[n] end
		local cf
		if n == root then
			cf = CFrame.new(pos + n.pos * S) * CFrame.Angles(0, heading, 0)
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
