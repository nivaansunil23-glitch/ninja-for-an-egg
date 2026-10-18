--[[
  Blocky Crab — paste into a Script in ServerScriptService.
  Builds the crab from Parts (no import needed) and animates it:
    • no player within SLEEP_DIST  → sleeps (sinks low, eye stalks fold back, slow breathing, floating Z's)
    • player within SLEEP_DIST     → idle (eye stalks swivel, claws click, occasional claw wave, watches you)
    • player within CHASE_DIST     → scuttles sideways at the nearest player; at their feet it turns and snaps both claws
  Optional: put a Part named "CrabSpawn" in Workspace to set where it spawns.
]]

local CFG = {
	SCALE = 5,          -- studs per model unit
	SLEEP_DIST = 70,
	CHASE_DIST = 40,
	STOP_DIST = 6,
	SPEED = 17,         -- studs/sec (player walk speed is 16)
	LEASH = 150,
	DAMAGE = 0,         -- per pinch; set >0 to make it hurt
	PINCH_COOLDOWN = 1,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local S = CFG.SCALE

local spawnMarker = workspace:FindFirstChild("CrabSpawn")
local home = spawnMarker and spawnMarker.Position or Vector3.new(0, 0, 0)

local model = Instance.new("Model")
model.Name = "Crab"

local COL = {
	shell = Color3.fromRGB(216, 69, 43),
	top = Color3.fromRGB(168, 50, 29),
	belly = Color3.fromRGB(240, 210, 168),
	eye = Color3.fromRGB(20, 20, 20),
	shine = Color3.fromRGB(255, 255, 255),
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
	table.insert(parts, { part = p, node = n, offset = CFrame.new(x * S, y * S, z * S) * CFrame.Angles(0, 0, rz or 0) })
	return p
end

local HIP = 0.16
local root = node(nil, 0, 0, 0)
local body = node(root, 0, HIP, 0)

local shell = box("Shell", body, COL.shell, 0.6, 0.16, 0.42, 0, 0.04, 0)
box("ShellTop", body, COL.top, 0.5, 0.04, 0.34, 0, 0.14, 0)
box("Belly", body, COL.belly, 0.5, 0.03, 0.34, 0, -0.05, 0)
box("Mouth", body, COL.eye, 0.12, 0.02, 0.006, 0, 0, 0.212)

local stalks, brows = {}, {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	local g = node(body, s * 0.08, 0.1, 0.16)
	box("Stalk" .. n, g, COL.shell, 0.035, 0.16, 0.035, 0, 0.08, 0)
	box("Eye" .. n, g, COL.eye, 0.07, 0.07, 0.07, 0, 0.18, 0)
	box("EyeShine" .. n, g, COL.shine, 0.02, 0.02, 0.006, 0.015, 0.195, 0.036)
	table.insert(brows, box("Brow" .. n, g, COL.eye, 0.08, 0.018, 0.018, 0, 0.23, 0.02, s * 0.5))
	table.insert(stalks, g)
end

local claws = {}
for _, s in ipairs({ 1, -1 }) do
	local n = s > 0 and "L" or "R"
	local arm = node(body, s * 0.28, 0.02, 0.14)
	box("Arm" .. n, arm, COL.shell, 0.07, 0.07, 0.2, 0, 0, 0.1)
	local claw = node(arm, 0, 0.02, 0.2)
	box("Palm" .. n, claw, COL.shell, 0.14, 0.12, 0.14, 0, 0, 0.07)
	box("FingerLow" .. n, claw, COL.top, 0.06, 0.04, 0.12, 0, -0.04, 0.18)
	local pincer = node(claw, 0, 0.03, 0.12)
	box("FingerTop" .. n, pincer, COL.top, 0.06, 0.05, 0.12, 0, 0.01, 0.06)
	table.insert(claws, { s = s, arm = arm, claw = claw, pincer = pincer })
end

local legs = {}
for _, s in ipairs({ 1, -1 }) do
	for i, z in ipairs({ 0.1, -0.02, -0.14 }) do
		local n = (s > 0 and "L" or "R") .. i
		local l = node(body, s * 0.29, 0, z)
		l.s, l.i = s, i - 1
		box("Thigh" .. n, l, COL.shell, 0.192, 0.04, 0.04, s * 0.085, 0.045, 0, s * 0.487)
		box("Shin" .. n, l, COL.shell, 0.266, 0.04, 0.04, s * 0.215, -0.035, 0, -s * 1.225)
		table.insert(legs, l)
	end
end

local zLabels = {}
for i = 1, 3 do
	local bb = Instance.new("BillboardGui")
	bb.Adornee = shell
	bb.Size = UDim2.new(1.6, 0, 1.6, 0)
	bb.LightInfluence = 0
	bb.Parent = shell
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

model.PrimaryPart = shell
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
local t, phase, speed, side, lastPinch = 0, 0, 0, 0, 0

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
		want = dist > CFG.STOP_DIST and CFG.SPEED or 0
		if CFG.DAMAGE > 0 and dist <= CFG.STOP_DIST + 1 and t - lastPinch > CFG.PINCH_COOLDOWN then
			lastPinch = t
			target.hum:TakeDamage(CFG.DAMAGE)
		end
	end
	side = lerp(side, want > 0 and 1 or 0, 1 - math.exp(-4 * dt))
	if mode ~= "sleep" and target then
		local d = target.hrp.Position - pos
		local face = math.atan2(d.X, d.Z)
		heading = angLerp(heading, face - side * math.pi / 2, 1 - math.exp(-(mode == "run" and 6 or 1.5) * dt))
	end
	speed = lerp(speed, want, 1 - math.exp(-6 * dt))
	pos += Vector3.new(math.cos(heading), 0, -math.sin(heading)) * speed * dt -- sideways (local +X)

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
	phase += dt * (4 + 10 * stride)
	local ex = run * (1 - stride)
	local breath = math.sin(t * 1.3)
	local thump = pulse(t * 8, 2)

	body.pos = Vector3.new(0, HIP - 0.1 * sl + math.abs(math.sin(phase * 2)) * 0.015 * stride + breath * 0.004 * sl + thump * 0.012 * ex, 0)
	body.rot = Vector3.new(-0.06 * ex, 0, math.sin(phase) * 0.05 * stride)
	shell.Size = Vector3.new(0.6, 0.16 * (1 + breath * 0.03 * sl), 0.42) * S

	for _, l in ipairs(legs) do
		local ph = phase + l.i * 2.1 + (l.s > 0 and 0 or math.pi)
		l.rot = Vector3.new(
			0,
			math.cos(ph) * 0.25 * stride + l.s * (l.i - 1) * 0.15,
			l.s * (math.max(0, math.sin(ph)) * 0.35 * stride + 0.4 * sl + thump * 0.05 * ex)
		)
	end

	for i, c in ipairs(claws) do
		local k = i - 1
		local jab = pulse(t * 8 + k * math.pi, 2) * ex
		local wave = pulse(t * 0.5 + k * 2.5, 20) * id
		c.arm.rot = Vector3.new(
			-0.35 * run * stride - 0.9 * ex - 0.7 * wave + 0.2 * sl + jab * 0.3 + math.sin(t * 1.2 + k) * 0.05 * id,
			c.s * (0.45 - 0.3 * sl - 0.15 * ex),
			0
		)
		c.arm.pos = Vector3.new(c.s * 0.28, 0.02, 0.14 + jab * 0.06)
		c.claw.rot = Vector3.new(-0.4 * ex + 0.3 * wave, 0, c.s * math.sin(t * 2 + k) * 0.1 * id)
		local click = pulse(t * 1.1 + k * 1.7, 8) * id + pulse(t * 4 + k, 4) * wave
		c.pincer.rot = Vector3.new(-(0.7 * click + (0.25 + 0.25 * math.sin(t * 10 + k * 2)) * run * stride
			+ 0.8 * (1 - pulse(t * 8 + k * math.pi + 0.6, 2)) * ex) * (1 - sl), 0, 0)
	end

	for i, g in ipairs(stalks) do
		local k = i - 1
		local sg = i == 1 and 1 or -1
		g.rot = Vector3.new(
			-1.4 * sl - 0.1 * ex,
			math.sin(t * (0.9 + k * 0.37) + k * 2) * 0.6 * id,
			sg * (0.15 * run + math.sin(t * 1.3 + k) * 0.12 * id) + sg * 0.3 * sl
		)
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
