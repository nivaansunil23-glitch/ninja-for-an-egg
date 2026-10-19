-- Builds the BGSI-style cliff ring round the base island (Workspace.Map.Base.Mountains).
-- Not part of the game: paste it into Studio's command bar (or run it through the
-- Studio MCP) in Edit mode. It deletes and rebuilds Map.Base.Mountains, so tweak a
-- number and run it again. Same seed = same layout.
--
-- Look (from the Bubble Gum Simulator INFINITY Overworld): chunky low poly rock
-- pillars with puffy grass caps, three rows stepping up from the island edge,
-- six low "windows" where the base Rim has its gaps so you still see out.
-- Needs ServerStorage.ToolboxAssets.CliffPillarA / CliffPillarB (Creator Store
-- "LOW-POLY Mountain-Border" 6865341186 and "Low-Poly Mountain Wall" 6865334143,
-- scripts stripped) and IslandChunk (grass cap + rock cone for the ledges).
--
-- Kept clear: pens, shops, trampolines, spawn and ponds (+8 studs), the base's
-- floating islets, and the Gap1 cloud zone (pillars poke in 10 studs at most).
-- Tops stay under Y 140, below Island1 and the Gap2 cloud zone.

local ServerStorage = game:GetService("ServerStorage")

local kitA = ServerStorage.ToolboxAssets.CliffPillarA
local kitB = ServerStorage.ToolboxAssets.CliffPillarB
local chunk = ServerStorage.ToolboxAssets.IslandChunk
local map = workspace.Map
local base = map.Base

local old = base:FindFirstChild("Mountains")
if old then
	old:Destroy()
end

local rng = Random.new(1018)

-- Island edge radius per degree.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { base.Ground, base.SpawnArea }
local E = {}
for d = 0, 359 do
	local a = math.rad(d)
	local cx, cz = math.cos(a), math.sin(a)
	local last, miss = 0, 0
	for r = 100, 340 do
		local hit = workspace:Raycast(Vector3.new(cx * r, 40, cz * r), Vector3.new(0, -80, 0), groundParams)
		if hit and hit.Position.Y > -4 then
			last, miss = r, 0
		else
			miss += 1
			if miss > 4 then
				break
			end
		end
	end
	E[d] = last
end
task.wait()

-- How far out the things we must not cover reach, per degree.
local protected = { map.Pens, map.Shops, map.LaunchTrampoline, base.SpawnArea }
for _, c in base.Scatter:GetChildren() do
	if c.Name == "Pond" or c.Name == "WaterfallPond" then
		table.insert(protected, c)
	end
end
local protParams = RaycastParams.new()
protParams.FilterType = Enum.RaycastFilterType.Include
protParams.FilterDescendantsInstances = protected
local P = {}
for d = 0, 359 do
	local a = math.rad(d)
	local cx, cz = math.cos(a), math.sin(a)
	local maxR = 0
	for r = 60, 262, 1.5 do
		if workspace:Raycast(Vector3.new(cx * r, 80, cz * r), Vector3.new(0, -100, 0), protParams) then
			maxR = r
		end
	end
	P[d] = maxR
end
task.wait()

local function wrap(d)
	return math.floor(d + 0.5) % 360
end
local function edgeAt(d) -- smoothed
	local s = 0
	for k = -3, 3 do
		s += E[wrap(d + k)]
	end
	return s / 7
end
local function protectedAt(d, span)
	local m = 0
	for k = math.floor(-span - 1), math.ceil(span + 1) do
		m = math.max(m, P[wrap(d + k)])
	end
	return m
end
-- Inner face of the cliff ring: hugs the pens, shops and ponds (+8) so the open
-- middle stays small (user, 2026-10-19), never past the island edge.
local MIN_FRONT = 140
local function frontLine(d, span)
	local p = 0
	for k = -6, 6 do
		p = math.max(p, protectedAt(d + k, span))
	end
	return math.min(edgeAt(d) - 5, math.max(MIN_FRONT, p + 8))
end

-- Windows line up with the base Rim's six gaps.
local WINDOWS = { 0, 60.5, 120.5, 180, 239.5, 299.5 }
local WIN_HALF = 5
local function angDist(a, b)
	local d = (a - b) % 360
	return if d > 180 then 360 - d else d
end
local function nearestWindow(t)
	local best = 999
	for _, w in WINDOWS do
		best = math.min(best, angDist(t, w))
	end
	return best
end
local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
-- Lower on the sun's side (sun comes from about 150 degrees) so shadows stay off the pens.
local function sunMul(t)
	return 1 - 0.26 * math.max(0, math.cos(math.rad(t - 150)))
end
-- Step down towards each window.
local function windowMul(t)
	return 0.55 + 0.45 * smooth((nearestWindow(t) - WIN_HALF) / 16)
end

-- Gap1 cloud zone (base to Island1), X -198..122, Z -160..160.
local BOX_MIN, BOX_MAX = Vector2.new(-198, -160), Vector2.new(122, 160)
local function boxIntrusion(x, z, radius)
	local dx = math.max(BOX_MIN.X - x, 0, x - BOX_MAX.X)
	local dz = math.max(BOX_MIN.Y - z, 0, z - BOX_MAX.Y)
	local signed
	if dx > 0 or dz > 0 then
		signed = math.sqrt(dx * dx + dz * dz)
	else
		signed = -math.min(x - BOX_MIN.X, BOX_MAX.X - x, z - BOX_MIN.Y, BOX_MAX.Y - z)
	end
	return radius - signed
end

local islets = {}
for _, m in base.Surroundings:GetChildren() do
	local cf, s = m:GetBoundingBox()
	local mn, mx = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local p = cf:PointToWorldSpace(Vector3.new(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2))
				mn, mx = mn:Min(p), mx:Max(p)
			end
		end
	end
	table.insert(islets, { mn = mn - Vector3.one * 6, mx = mx + Vector3.one * 6 })
end
local function hitsIslet(x, z, radius, y0, y1)
	for _, b in islets do
		if x + radius > b.mn.X and x - radius < b.mx.X and z + radius > b.mn.Z and z - radius < b.mx.Z and y1 > b.mn.Y and y0 < b.mx.Y then
			return true
		end
	end
	return false
end

-- Warm brown that still reads brown under the purple Cartoon Lighting ambient.
local ROCK = {
	Color3.fromRGB(128, 106, 74),
	Color3.fromRGB(120, 100, 70),
	Color3.fromRGB(136, 112, 78),
	Color3.fromRGB(124, 104, 73),
	Color3.fromRGB(131, 108, 76),
}
local GRASS = {
	Color3.fromRGB(115, 215, 95), -- base island grass
	Color3.fromRGB(108, 207, 88),
	Color3.fromRGB(122, 222, 101),
	Color3.fromRGB(112, 211, 92),
}
local A_CAP = 0.1852 * 1.35 -- pillar A's cap, a bit puffier than the kit

-- topY is the top of the grass cap. Cap offsets are measured from the kit models.
local function makePillar(kind, x, z, bottomY, topY, W)
	local kit = if kind == "A" then kitA else kitB
	local model = Instance.new("Model")
	model.Name = "Cliff"
	local rock, cap = kit.Rock:Clone(), kit.Grass:Clone()
	local rockSize, capSize, capOffset
	if kind == "A" then
		local capT = W * A_CAP
		local rh = topY - 0.233 * capT - bottomY
		rockSize = Vector3.new(W, rh, W * 0.9838)
		capSize = Vector3.new(W, capT, W * 0.984)
		capOffset = Vector3.new(0.0162 * W, rh / 2 - 0.267 * capT, -0.0014 * W)
	else
		local capT = W * 0.4109
		local rh = topY - 0.7636 * capT - bottomY
		rockSize = Vector3.new(W, rh, W * 0.981)
		capSize = Vector3.new(W * 1.110, capT, W * 1.123)
		capOffset = Vector3.new(-0.0009 * W, rh / 2 + 0.2636 * capT, -0.0106 * W)
	end
	local t = rng:NextNumber(0, math.pi * 2)
	local tiltAxis = Vector3.new(math.cos(t), 0, math.sin(t))
	local baseCFrame = CFrame.new(x, bottomY, z)
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		* CFrame.fromAxisAngle(tiltAxis, math.rad(rng:NextNumber(0, 2.2)))
	rock.Size = rockSize
	rock.CFrame = baseCFrame * CFrame.new(0, rockSize.Y / 2, 0)
	cap.Size = capSize
	cap.CFrame = rock.CFrame * CFrame.new(capOffset)
	rock.Color = ROCK[rng:NextInteger(1, #ROCK)]
	cap.Color = GRASS[rng:NextInteger(1, #GRASS)]
	rock.Parent = model
	cap.Parent = model
	-- Tall pillars stretch the rock's notched top below the cap, so sky shows through.
	-- A short unstretched copy of the rock fills the top under the cap.
	if rockSize.Y > 40 then
		local collarH = math.min(rockSize.Y * 0.5, W * 0.7)
		local collar = rock:Clone()
		collar.Name = "RockTop"
		collar.Size = Vector3.new(rockSize.X * 0.96, collarH, rockSize.Z * 0.96)
		collar.CFrame = rock.CFrame * CFrame.new(0, rockSize.Y / 2 - 0.2 - collarH / 2, 0)
		collar.Parent = model
	end
	model.PrimaryPart = rock
	return model
end

-- Front row low and chunky, back row tall. inner = studs past the front line.
local ROWS = {
	{ name = "Front", kind = function() return "A" end, W = { 20, 30 }, top = { 24, 46 }, inner = { -1, 2 }, bottom = -8, step = 0.68 },
	{ name = "Mid", kind = function() return if rng:NextNumber() < 0.5 then "A" else "B" end, W = { 26, 38 }, top = { 46, 86 }, inner = { 8, 14 }, bottom = -14, step = 0.72 },
	{ name = "Back", kind = function() return "B" end, W = { 34, 48 }, top = { 70, 132 }, inner = { 20, 28 }, bottom = -24, step = 0.75 },
}

local plan = {}
for rowIndex, row in ROWS do
	local start = rng:NextNumber(0, 10)
	local th = start
	while th < start + 360 do
		local d = th % 360
		local kind = row.kind()
		local W = rng:NextNumber(row.W[1], row.W[2])
		if kind == "B" and rowIndex == 2 then
			W *= 0.88
		end
		local inner = rng:NextNumber(row.inner[1], row.inner[2])
		local span = math.deg(math.asin(math.min(1, (W / 2) / math.max(edgeAt(d), 120))))
		local r = frontLine(d, span) + inner + W / 2
		span = math.deg(math.asin(math.min(1, (W / 2) / r)))
		local top = rng:NextNumber(row.top[1], row.top[2])
		if rowIndex == 3 and rng:NextNumber() < 0.18 then
			top += 22 -- the odd taller peak
		end
		top = math.clamp(top * sunMul(d) * windowMul(d), 16, 140)
		if nearestWindow(d) - span >= WIN_HALF then
			local x, z = math.cos(math.rad(d)) * r, math.sin(math.rad(d)) * r
			local tries = 0
			while boxIntrusion(x, z, W / 2) > 10 and tries < 40 do
				r += 2
				tries += 1
				x, z = math.cos(math.rad(d)) * r, math.sin(math.rad(d)) * r
			end
			if not hitsIslet(x, z, W * 0.56, row.bottom, top) then
				table.insert(plan, { kind = kind, x = x, z = z, bottom = row.bottom, top = top, W = W, d = d, row = row.name })
			end
		end
		th += math.deg((W * row.step) / r) * rng:NextNumber(0.9, 1.1)
	end
end

local mountains = Instance.new("Model")
mountains.Name = "Mountains"
mountains.Parent = base

local function arcOf(d)
	for k = 1, #WINDOWS do
		local a, b = WINDOWS[k], WINDOWS[k % #WINDOWS + 1]
		if (d - a) % 360 < (b - a) % 360 then
			return k
		end
	end
	return 1
end
local ranges = {}
for k = 1, #WINDOWS do
	local range = Instance.new("Model")
	range.Name = "Range" .. k
	range.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	range.Parent = mountains
	ranges[k] = range
end
for i, p in plan do
	local cliff = makePillar(p.kind, p.x, p.z, p.bottom, p.top, p.W)
	cliff:SetAttribute("Row", p.row)
	cliff.Parent = ranges[arcOf(p.d)]
	if i % 25 == 0 then
		task.wait()
	end
end

-- Ledges: island ground (grass cap + rock cone) under the cliffs, so they stand
-- on the floating island instead of hanging in the air.
local ledges = Instance.new("Model")
ledges.Name = "Ledges"
ledges.Parent = mountains
local nLedge = 0
for k = 1, #WINDOWS do
	local a = WINDOWS[k] + WIN_HALF + 3
	local b = WINDOWS[k % #WINDOWS + 1] - WIN_HALF - 3
	local len = (b - a) % 360
	local n = math.max(2, math.ceil(len / 9) + 1)
	for j = 0, n - 1 do
		local d = (a + len * j / (n - 1)) % 360
		local D = rng:NextNumber(96, 112)
		local r = frontLine(d, 12) + 30
		local x, z = math.cos(math.rad(d)) * r, math.sin(math.rad(d)) * r
		local capY = -0.22 - 0.08 * (nLedge % 4) -- staggered so overlapping caps don't flicker
		local tries = 0
		while hitsIslet(x, z, D / 2, capY - 0.9 * D, capY) and tries < 6 do
			D *= 0.85
			tries += 1
		end
		if not hitsIslet(x, z, D / 2, capY - 0.9 * D, capY) then
			local ledge = Instance.new("Model")
			ledge.Name = "Ledge"
			local cap, cone = chunk.Cap:Clone(), chunk.Cone:Clone()
			local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			cone.Size = Vector3.new(D, 0.9 * D, D)
			cone.CFrame = CFrame.new(x, capY + 0.01 - 0.45 * D, z) * yaw
			cap.Size = Vector3.new(D, math.max(0.1, 0.002 * D), D * 1.002)
			cap.CFrame = CFrame.new(x, capY, z) * yaw
			cap.Color = Color3.fromRGB(115, 215, 95)
			cone.Color = Color3.fromRGB(122, 98, 72)
			for _, part in { cap, cone } do
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.CanTouch = false
			end
			cone.Parent = ledge
			cap.Parent = ledge
			ledge.PrimaryPart = cap
			ledge.Parent = ledges
			nLedge += 1
		end
	end
	task.wait()
end

-- Trees and flowers that ended up inside a cliff walk inwards until they're clear.
local cliffParts = {}
for _, d in mountains:GetDescendants() do
	if d:IsA("BasePart") and (d.Name == "Rock" or d.Name == "Grass") then
		table.insert(cliffParts, d)
	end
end
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances = cliffParts
local moved = 0
for _, item in base.Scatter:GetChildren() do
	if item.Name ~= "Pond" and item.Name ~= "WaterfallPond" and item.Name ~= "Waterfall" and item.Name ~= "AmbientFX" then
		local function blocked()
			for _, p in if item:IsA("BasePart") then { item } else item:GetDescendants() do
				if p:IsA("BasePart") and #workspace:GetPartsInPart(p, overlap) > 0 then
					return true
				end
			end
			return false
		end
		local pos = item:GetPivot().Position
		local inward = Vector3.new(-pos.X, 0, -pos.Z).Unit
		local steps = 0
		while blocked() and steps < 30 do
			item:PivotTo(item:GetPivot() + inward * 2)
			steps += 1
		end
		if steps > 0 then
			moved += 1
		end
	end
end

print(`[Mountains] {#plan} cliffs, {nLedge} ledges, {moved} scatter items moved`)
