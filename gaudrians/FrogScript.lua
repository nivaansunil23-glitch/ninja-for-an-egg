--[[
  Blocky Frog — paste into a Script in ServerScriptService.
  Builds the frog from Parts (no import needed) and animates it:
    • no player within SLEEP_DIST  → sleeps (flattens, eyes shut, slow breathing, floating Z's)
    • player within SLEEP_DIST     → idle (throat pulses, blinks, flicks its tongue, watches you)
    • player within CHASE_DIST     → hops after the nearest player; at their feet it croaks and lashes its tongue
  Optional: put a Part named "FrogSpawn" in Workspace to set where it spawns.
]]

local CFG = {
	SCALE = 5,          -- studs per model unit
	SLEEP_DIST = 70,
	CHASE_DIST = 40,
	STOP_DIST = 6,
	SPEED = 18,         -- studs/sec (player walk speed is 16)
	HOP_HEIGHT = 0.35,  -- model units
	LEASH = 150,
	DAMAGE = 0,         -- per tongue lash; set >0 to make it hurt
	LASH_COOLDOWN = 1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local S = CFG.SCALE

local spawnMarker = workspace:FindFirstChild("FrogSpawn")
local home = spawnMarker and spawnMarker.Position or Vector3.new(0, 0, 0)

local model = Instance.new("Model")
model.Name = "Frog"

local COL = {
	skin = Color3.fromRGB(95, 174, 58),
	spot = Color3.fromRGB(47, 106, 30),
	belly = Color3.fromRGB(230, 223, 160),
	eye = Color3.fromRGB(245, 242, 232),
	pupil = Color3.fromRGB(20, 20, 20),
	mouth = Color3.fromRGB(36, 64, 26),
	tongue = Color3.fromRGB(232, 96, 122),
}

local parts = {}
local function node(parent, x, y, z)
	return { parent = parent, pos = Vector3.new(x, y, z), rot = Vector3.zero }
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
	local e = { part = p, node = n, offset = CFrame.new(x * S, y * S, z * S) * CFrame.Angles(0, 0, rz or 0) }
	table.insert(parts, e)
	return p, e
end

local BY, BZ, ARM_Y, ARM_Z = 0.06, -0.16, 0.02, 0.36
local root = node(nil, 0, 0, 0)
local body = node(root, 0, BY, BZ)
local head = node(body, 0, 0.12, 0.44)
local tongueN = node(head, 0, -0.025, 0.2)
local tipN = node(head, 0, -0.025, 0.2)

local torso = box("Torso", body, COL.skin, 0.5, 0.2, 0.48, 0, 0.08, 0.22)
box("Belly", body, COL.belly, 0.42, 0.02, 0.42, 0, -0.02, 0.24)
for i, sp in ipairs({ { 0.1, 0.12, 0.1 }, { -0.12, 0.26, 0.08 }, { 0.06, 0.34, 0.06 } }) do
	box("Spot" .. i, body, COL.spot, sp[3], 0.012, sp[3], sp[1], 0.185, sp[2])
end
local headPart = box("Head", head, COL.skin, 0.46, 0.14, 0.24, 0, 0.02, 0.08)
box("MouthLine", head, COL.mouth, 0.4, 0.012, 0.006, 0, -0.035, 0.2)
local throat = box("Throat", head, COL.belly, 0.26, 0.04, 0.16, 0, -0.06, 0.06)
local tonguePart, tongueE = box("Tongue", tongueN, COL.tongue, 0.07, 0.02, 0.01, 0, 0, 0.005)
local tipPart = box("TongueTip", tipN, COL.tongue, 0.1, 0.04, 0.06, 0, 0, 0)

local lids, brows = {}, {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	local eyeN = node(head, s * 0.14, 0.1, 0.06)
	box("Eyeball" .. n, eyeN, COL.eye, 0.13, 0.13, 0.13, 0, 0.04, 0)
	box("Pupil" .. n, eyeN, COL.pupil, 0.06, 0.07, 0.01, 0, 0.04, 0.066)
	local lidN = node(eyeN, 0, 0.106, 0)
	local lp, le = box("Lid" .. n, lidN, COL.skin, 0.14, 0.01, 0.14, 0, -0.005, 0)
	table.insert(lids, { part = lp, entry = le })
	table.insert(brows, box("Brow" .. n, head, COL.spot, 0.12, 0.025, 0.02, s * 0.14, 0.215, 0.135, s * 0.4))
end

local arms = {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	local a = node(root, s * 0.17, 0, 0)
	a.x = s * 0.17
	box("Arm" .. n, a, COL.skin, 0.06, 0.16, 0.06, 0, -0.08, 0)
	box("Hand" .. n, a, COL.skin, 0.11, 0.025, 0.11, 0, -0.1475, 0.03)
	table.insert(arms, a)
end
local backLegs = {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	local l = node(root, s * 0.26, 0.1, -0.1)
	box("Thigh" .. n, l, COL.skin, 0.1, 0.12, 0.26, 0, -0.02, 0.08)
	box("Foot" .. n, l, COL.skin, 0.14, 0.03, 0.22, 0, -0.085, 0.14)
	table.insert(backLegs, l)
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
local t, phase, speed, lastLash = 0, 0, 0, 0

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
		if CFG.DAMAGE > 0 and dist <= CFG.STOP_DIST + 1 and t - lastLash > CFG.LASH_COOLDOWN then
			lastLash = t
			target.hum:TakeDamage(CFG.DAMAGE)
		end
	elseif mode == "idle" and target then
		local d = target.hrp.Position - pos
		heading = angLerp(heading, math.atan2(d.X, d.Z), 1 - math.exp(-1.5 * dt))
	end
	speed = lerp(speed, want, 1 - math.exp(-6 * dt))

	local run, sl, id = W.run, W.sleep, W.idle
	local stride = math.min(1, speed / CFG.SPEED)
	phase += dt * (2 + 5 * stride)
	local h = math.abs(math.sin(phase)) * stride
	pos += Vector3.new(math.sin(heading), 0, math.cos(heading)) * speed * dt * (0.3 + 1.4 * h)

	local exclude = { model }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(exclude, plr.Character) end
	end
	rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -60, 0), rayParams)
	if hit then pos = Vector3.new(pos.X, lerp(pos.Y, hit.Position.Y, 1 - math.exp(-20 * dt)), pos.Z) end

	-- pose (same curves as the web preview)
	local ex = run * (1 - stride)
	local breath = math.sin(t * 1.4)
	root.pos = Vector3.new(0, h * CFG.HOP_HEIGHT, 0)
	local p = (-0.2 + 0.25 * h - 0.06 * ex) * (1 - sl) + 0.05 * sl
	local by = BY - 0.03 * sl + breath * 0.004 * sl
	body.pos = Vector3.new(0, by, BZ)
	body.rot = Vector3.new(p, 0, 0)
	torso.Size = Vector3.new(0.5 * (1 + breath * 0.03 * sl), 0.2 * (1 + breath * 0.05 * sl), 0.48) * S

	local cp, sp = math.cos(p), math.sin(p)
	for _, a in ipairs(arms) do
		a.pos = Vector3.new(a.x, by + ARM_Y * cp - ARM_Z * sp, BZ + ARM_Y * sp + ARM_Z * cp)
		a.rot = Vector3.new(-0.8 * h - 1.4 * sl, 0, 0)
	end
	for _, l in ipairs(backLegs) do l.rot = Vector3.new(1.3 * h, 0, 0) end

	head.rot = Vector3.new(0.15 * sl + 0.1 * h - 0.1 * ex, math.sin(t * 0.5) * 0.25 * id, 0)

	local croak = pulse(t * 4, 4) * ex
	local ts = 1 + 0.5 * pulse(t * 7, 2) * id + 1.2 * croak + 0.2 * breath * sl
	throat.Size = Vector3.new(0.26 * (1 + 0.3 * (ts - 1)), 0.04 * ts, 0.16 * (1 + 0.4 * (ts - 1))) * S

	local L = 0.5 * pulse(t * 0.7, 30) * id + 0.9 * pulse(t * 5 + 2, 3) * ex
	local showT = L > 0.01
	L = math.max(0.01, L)
	tonguePart.Size = Vector3.new(0.07, 0.02, L) * S
	tongueE.offset = CFrame.new(0, 0, L / 2 * S)
	tipN.pos = Vector3.new(0, -0.025, 0.2 + L)
	tonguePart.Transparency = showT and 0 or 1
	tipPart.Transparency = showT and 0 or 1

	local blink = pulse(t * 0.9, 80) * id
	local lid = math.min(1, math.max(sl, blink, 0.35 * run))
	local lh = math.max(0.005, lid * 0.135)
	for _, l in ipairs(lids) do
		l.part.Size = Vector3.new(0.14, lh, 0.14) * S
		l.entry.offset = CFrame.new(0, -lh / 2 * S, 0)
		l.part.Transparency = lid > 0.02 and 0 or 1
	end
	for _, b in ipairs(brows) do b.Transparency = run > 0.5 and 0 or 1 end

	for i, z in ipairs(zLabels) do
		local u = (t * 0.35 + (i - 1) / 3) % 1
		z.gui.StudsOffset = Vector3.new(0.6 + u * 1.0 + math.sin(u * 6 + i) * 0.15, 1.2 + u * 2.4, 0)
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
	for i, e in ipairs(parts) do
		list[i] = e.part
		cfs[i] = solve(e.node) * e.offset
	end
	workspace:BulkMoveTo(list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end)
