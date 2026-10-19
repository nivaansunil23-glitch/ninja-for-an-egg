-- The climbing clouds between the islands (started by World/CloudSpawner,
-- rebuilt by the admin panel). Every box in Workspace.Map.CloudZones (Gap1,
-- Gap2, ...) gets CloudConfig.Paths cloud paths that wind up from the island
-- below to just off the edge of the island above, crossing each other on the
-- way, so it's clear which way is up. A gap is built for one jump power
-- (JumpBalance, or a RequiredJump attribute on the box): each step up is a
-- share of that jump's height and each sideways gap a share of how far you get
-- in the air, so every cloud is reachable with that jump power without
-- sprinting.
--
-- How a gap is built:
--   1. Each path's top cloud goes just off the edge of the island above (path 1
--      by its LandingSpot, the others round the island), one short hop below
--      its top.
--   2. Each path gets a guide that winds round the middle of the gap (path 1
--      one way, path 2 the other, path 3 half as far) from a start on the
--      ground below to its top cloud, and a walk follows it up one reachable
--      step at a time. Every step is checked against jump physics and the map:
--      no cloud inside an island or right under something.
--   3. Clouds in the bottom half of the gap look like the island below, the top
--      half like the island above (CloudConfig.Themes).
-- Clouds are one-way: the visible mesh never collides, an invisible Floor does,
-- and each client turns Floors off for its own character while it's under them
-- (client World/OneWayClouds). Clouds go in Workspace.Map.Clouds.<GapName>.
-- The jump power each gap was built for is written on the island above it
-- (RequiredJump, RequiredLevel) so the HUD and JumpBalance.GetIslands() match.

local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Trampolines = require(Shared:WaitForChild("Trampolines"))
local Config = Shared:WaitForChild("Config")
local CloudConfig = require(Config:WaitForChild("CloudConfig"))
local JumpBalance = require(Config:WaitForChild("JumpBalance"))

local Clouds = {}

local FONT = Enum.Font.FredokaOne
local OUTLINE = Color3.fromRGB(45, 25, 70)
local TAU = math.pi * 2

local map = Workspace:WaitForChild("Map", math.huge)
local zonesFolder = map:WaitForChild("CloudZones", math.huge)

local cloudsFolder = map:FindFirstChild("Clouds")
if not cloudsFolder then
	cloudsFolder = Instance.new("Folder")
	cloudsFolder.Name = "Clouds"
	cloudsFolder.Parent = map
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.RespectCanCollide = false

-- Used to check a cloud's space against the real shapes of the map.
local probe = Instance.new("Part")
probe.Name = "CloudSpaceCheck"
probe.Anchored = true
probe.CanCollide = false
probe.CanTouch = false
probe.CastShadow = false
probe.Transparency = 1

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function flatUnit(v: Vector3): Vector3?
	local f = flat(v)
	return if f.Magnitude > 1e-3 then f.Unit else nil
end

local function rotateY(v: Vector3, angle: number): Vector3
	local c, s = math.cos(angle), math.sin(angle)
	return Vector3.new(v.X * c - v.Z * s, 0, v.X * s + v.Z * c)
end

local function angleOf(v: Vector3): number
	return math.atan2(v.Z, v.X)
end

local function wrapPi(a: number): number
	return (a + math.pi) % TAU - math.pi
end

local function numberAttribute(instance: Instance?, name: string): number?
	local value = instance and instance:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

local function groundY(): number
	return numberAttribute(Workspace, "GroundY") or 0
end

-- Cloud mesh --------------------------------------------------------------------

local template: BasePart? = nil
local templateChecked = false

local function getTemplate(): BasePart?
	if templateChecked then
		return template
	end
	templateChecked = true
	local folder = ServerStorage:FindFirstChild("CloudTemplates")
	local custom = folder and folder:FindFirstChildWhichIsA("BasePart", true)
	if custom then
		template = custom
		return template
	end
	local assets = ServerStorage:FindFirstChild("ToolboxAssets")
	local asset = assets and assets:FindFirstChild("Cloud")
	if asset then
		template = if asset:IsA("BasePart") then asset else asset:FindFirstChildWhichIsA("BasePart", true)
		if template then
			return template
		end
	end
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(CloudConfig.MeshId)
	end)
	if not ok then
		ok, part = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromUri(CloudConfig.MeshId))
		end)
	end
	if ok and part then
		template = part
	else
		warn("[Clouds] Cloud mesh not found, using block clouds")
	end
	return template
end

-- A see-only part: never collides, never hit by raycasts.
local function decor(part: BasePart, color: Color3, material: Enum.Material?)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function makeMesh(name: string, size: Vector3, cframe: CFrame, color: Color3): BasePart
	local source = getTemplate()
	local part: BasePart
	if source then
		part = source:Clone()
		for _, child in part:GetChildren() do
			child:Destroy()
		end
	else
		part = Instance.new("Part")
	end
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Transparency = 0
	decor(part, color)
	part.CastShadow = true
	return part
end

-- Map lookups -------------------------------------------------------------------

local function findIsland(number: number?): Instance?
	if number == nil then
		return nil
	end
	if number == 0 then
		return map:FindFirstChild("Base")
	end
	local islands = map:FindFirstChild("Islands")
	if not islands then
		return nil
	end
	for _, island in islands:GetChildren() do
		if island:GetAttribute("IslandNumber") == number then
			return island
		end
	end
	return islands:FindFirstChild("Island" .. number)
end

local function themeOf(island: Instance?): string
	if not island or island == map:FindFirstChild("Base") then
		return "Base"
	end
	local id = island:GetAttribute("IslandId") or island:GetAttribute("Theme")
	return if type(id) == "string" and CloudConfig.Themes[id] then id else "Base"
end

local function islandCenter(island: Instance): Vector3
	local center = island:FindFirstChild("Center")
	if center and center:IsA("BasePart") then
		return center.Position
	end
	if island:IsA("Model") then
		return island:GetPivot().Position
	end
	local spawnLocation = island:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		return spawnLocation.Position
	end
	local ground = island:FindFirstChild("Ground")
	return if ground and ground:IsA("PVInstance") then ground:GetPivot().Position else Vector3.zero
end

-- The standable ground of an island (not its trees and props).
local function groundOf(island: Instance): { Instance }
	local list = {}
	for _, name in { "Ground", "SpawnArea" } do
		local child = island:FindFirstChild(name)
		if child then
			table.insert(list, child)
		end
	end
	if #list == 0 then
		table.insert(list, island)
	end
	return list
end

-- Height of an island's ground at (x, z) if it's near the island's top.
local function surfaceAt(ground: { Instance }, x: number, z: number, topY: number): number?
	rayParams.FilterDescendantsInstances = ground
	local result = Workspace:Raycast(Vector3.new(x, topY + 30, z), Vector3.new(0, -60, 0), rayParams)
	if result and math.abs(result.Position.Y - topY) <= 8 then
		return result.Position.Y
	end
	return nil
end

-- How far the island's ground carries on from `from` along `dir`, and the
-- ground height at that edge.
local function edgeAlong(ground: { Instance }, from: Vector3, dir: Vector3, topY: number): (number, number)
	local lastDistance, lastY = 0, topY
	local misses = 0
	for distance = 0, 300 do
		local point = from + dir * distance
		local y = surfaceAt(ground, point.X, point.Z, topY)
		if y then
			lastDistance, lastY = distance, y
			misses = 0
		else
			misses += 1
			if misses > 5 then
				break
			end
		end
	end
	return lastDistance, lastY
end

-- Places clouds must leave alone: a column over the launch trampoline all the
-- way up, and some room over the training trampolines and spawn points.
-- { Center (Vector3), Radius, Bottom, Top }
local function keepOutZones()
	local zones = {}
	for _, trampoline in Trampolines.GetAll(Trampolines.Launch) do
		local info = Trampolines.GetPadInfo(trampoline)
		if info then
			table.insert(zones, {
				Center = info.Center,
				Radius = info.Radius + CloudConfig.LaunchClearance,
				Bottom = info.Bottom - 5,
				Top = math.huge,
			})
		end
	end
	for _, trampoline in Trampolines.GetAll(Trampolines.Training) do
		local info = Trampolines.GetPadInfo(trampoline)
		if info then
			table.insert(zones, {
				Center = info.Center,
				Radius = info.Radius + 6,
				Bottom = info.Bottom - 5,
				Top = info.Top + JumpBalance.BounceHeight + 15,
			})
		end
	end
	for _, spawnLocation in map:GetDescendants() do
		if spawnLocation:IsA("SpawnLocation") then
			table.insert(zones, {
				Center = spawnLocation.Position,
				Radius = math.max(spawnLocation.Size.X, spawnLocation.Size.Z) / 2 + 8,
				Bottom = spawnLocation.Position.Y - 5,
				Top = spawnLocation.Position.Y + 25,
			})
		end
	end
	return zones
end

-- Planning one gap ----------------------------------------------------------------

type Plan = {
	Pos: Vector3, -- middle of the cloud's top (where you stand)
	Inner: number, -- half its width
	Outer: number, -- half its length
	Thickness: number,
	Yaw: number,
	Ground: boolean?,
	Path: number?, -- which path it's on
}

local function planZone(zone: BasePart, rng: Random, keepOut)
	local base = map:FindFirstChild("Base")
	local fromIsland = findIsland(numberAttribute(zone, "FromIsland"))
	local toIsland = findIsland(numberAttribute(zone, "ToIsland"))
	local boxCFrame, boxSize = zone.CFrame, zone.Size

	local fromTop = if fromIsland and fromIsland ~= base then numberAttribute(fromIsland, "TopY") else nil
	fromTop = fromTop or numberAttribute(zone, "BottomY") or groundY()
	local toTop = numberAttribute(toIsland, "TopY") or numberAttribute(zone, "TopY") or (boxCFrame.Position.Y + boxSize.Y / 2)

	local jump = numberAttribute(zone, "RequiredJump")
		or numberAttribute(toIsland, "RequiredJump")
		or JumpBalance.RequiredJumpForGap(toTop - fromTop)

	local gravity = Workspace.Gravity
	local maxHeight = JumpBalance.MaxJumpHeight(jump)
	local stepMin = CloudConfig.StepMin * maxHeight
	local stepMax = CloudConfig.StepMax * maxHeight
	local headroom = math.min(maxHeight, CloudConfig.MaxHeadroom) + CloudConfig.PlayerHeight
	local baseInner = math.clamp(
		CloudConfig.SizeBase + CloudConfig.SizePerHeight * maxHeight,
		CloudConfig.SizeMin,
		CloudConfig.SizeMax
	)
	-- Clouds on the same path closer than this in height must not overlap from
	-- above (so a path never folds back over itself). Clouds on different paths
	-- only need room to stand: they're one-way, so you jump up through them.
	local band = maxHeight + CloudConfig.PlayerHeight + baseInner

	-- How far apart (edge to edge) a cloud dy higher can be and still be reachable
	-- at walking speed.
	local function reach(dy: number): number
		local disc = jump * jump - 2 * gravity * math.max(dy, 0)
		if disc < 0 then
			return 0
		end
		return CloudConfig.WalkSpeed * (jump + math.sqrt(disc)) / gravity * CloudConfig.ReachFactor
	end

	local exclude = { probe, Workspace.Terrain, cloudsFolder }
	local eggs = Workspace:FindFirstChild("Eggs")
	if eggs then
		table.insert(exclude, eggs)
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(exclude, other.Character)
		end
	end

	local function newCloud(): Plan
		local inner = baseInner * rng:NextNumber(CloudConfig.SizeJitterMin, CloudConfig.SizeJitterMax)
		return {
			Pos = Vector3.zero,
			Inner = inner,
			Outer = inner * CloudConfig.Elongation,
			Thickness = math.clamp(inner * CloudConfig.ThicknessRatio, CloudConfig.ThicknessMin, CloudConfig.ThicknessMax),
			Yaw = rng:NextNumber(0, TAU),
		}
	end

	local function inBox(pos: Vector3, outer: number): boolean
		local localPos = boxCFrame:PointToObjectSpace(pos)
		return math.abs(localPos.X) <= boxSize.X / 2 - outer and math.abs(localPos.Z) <= boxSize.Z / 2 - outer
	end

	local function apart(cloud: Plan, others: { Plan }): boolean
		for _, other in others do
			local within = if other.Path == cloud.Path then band else headroom
			if other ~= cloud and math.abs(cloud.Pos.Y - other.Pos.Y) < within then
				if flat(cloud.Pos - other.Pos).Magnitude < cloud.Outer + other.Outer + CloudConfig.MinGap then
					return false
				end
			end
		end
		return true
	end

	local function outsideKeepOut(cloud: Plan): boolean
		for _, area in keepOut do
			if
				flat(cloud.Pos - area.Center).Magnitude < area.Radius + cloud.Outer
				and cloud.Pos.Y + headroom > area.Bottom
				and cloud.Pos.Y - cloud.Thickness < area.Top
			then
				return false
			end
		end
		return true
	end

	-- Is the cloud's space (and the headroom above it) free of map parts?
	local function clear(cloud: Plan): boolean
		if not outsideKeepOut(cloud) then
			return false
		end
		local width = (cloud.Outer + CloudConfig.WorldMargin) * 2
		local height = cloud.Thickness + headroom
		local cframe = CFrame.new(cloud.Pos.X, cloud.Pos.Y - cloud.Thickness + height / 2, cloud.Pos.Z)
		local size = Vector3.new(width, height, width)
		overlapParams.FilterDescendantsInstances = exclude
		if #Workspace:GetPartBoundsInBox(cframe, size, overlapParams) == 0 then
			return true
		end
		-- Something's nearby: compare against its real shape, not its bounding box.
		probe.Size = size
		probe.CFrame = cframe
		probe.Parent = Workspace
		return #Workspace:GetPartsInPart(probe, overlapParams) == 0
	end

	local all: { Plan } = {} -- every cloud placed in this gap so far

	-- 1. Each path's top cloud, just off the island above.
	local toCenter = if toIsland then islandCenter(toIsland) else boxCFrame.Position
	local landing = toIsland and toIsland:FindFirstChild("LandingSpot", true)
	local landingPos = if landing and landing:IsA("BasePart") then landing.Position else toCenter
	local outward = flatUnit(landingPos - toCenter) or flatUnit(boxCFrame.Position - toCenter) or Vector3.xAxis
	local finals: { Plan } = {}
	for index = 1, CloudConfig.Paths do
		local final = newCloud()
		final.Path = index
		local finalStep = maxHeight * rng:NextNumber(CloudConfig.FinalStepMin, CloudConfig.FinalStepMax)
		local endAngle = math.rad(CloudConfig.EndAngles[index] or (index - 1) * 360 / CloudConfig.Paths)
		local placed = false
		if toIsland then
			local toGround = groundOf(toIsland)
			for _, swing in { 0, 15, -15, 30, -30, 50, -50, 75, -75 } do
				local dir = rotateY(outward, endAngle + math.rad(swing))
				local edge, edgeY = edgeAlong(toGround, toCenter, dir, toTop)
				local gap = CloudConfig.MinGap
				while gap <= reach(finalStep) do
					local point = toCenter + dir * (edge + gap + final.Inner)
					final.Pos = Vector3.new(point.X, edgeY - finalStep, point.Z)
					if inBox(final.Pos, final.Outer) and apart(final, finals) and clear(final) then
						placed = true
						break
					end
					gap += 1
				end
				if placed then
					break
				end
			end
		end
		if not placed then
			local dir = rotateY(outward, endAngle)
			local edge = if toIsland then edgeAlong(groundOf(toIsland), toCenter, dir, toTop) else 0
			local point = toCenter + dir * (edge + CloudConfig.MinGap + final.Inner)
			final.Pos = Vector3.new(point.X, toTop - finalStep, point.Z)
			if toIsland then
				warn(`[Clouds] {zone.Name} path {index}: no clear spot by the top island, placed its last cloud anyway`)
			end
		end
		table.insert(finals, final)
		table.insert(all, final)
	end

	-- 2. The middle the paths wind round: between the two islands, or under the
	-- island above when the island below is the (huge) base.
	local axis = flat(toCenter)
	if fromIsland and fromIsland ~= base then
		axis = (axis + flat(islandCenter(fromIsland))) / 2
	end

	-- How far round a path can wind and still keep up with its steps.
	local averageStep = (stepMin + stepMax) / 2
	local steps = math.max((toTop - fromTop) / averageStep, 1)
	local budget = steps * (2 * baseInner + 0.6 * reach(averageStep))
	local radius = 0
	for _, final in finals do
		radius += flat(final.Pos - axis).Magnitude / #finals
	end
	radius = math.max(radius, 20)
	local sweep = math.clamp(
		budget * CloudConfig.SweepFactor / radius,
		math.rad(CloudConfig.SweepMin),
		math.rad(CloudConfig.SweepMax)
	)
	local spin = if rng:NextNumber() < 0.5 then 1 else -1
	local sweeps = { sweep * spin, -sweep * spin, sweep * 0.5 * spin }

	local fromGround = if fromIsland then groundOf(fromIsland) else nil
	local fromCenter = if fromIsland and fromIsland ~= base then flat(islandCenter(fromIsland)) else axis

	-- Start on the ground below, at the edge of the island below in the
	-- direction of where the path's guide begins (on the base: right under it).
	local function findStart(angle: number, r: number): Plan
		local start: Plan = { Pos = Vector3.zero, Inner = 0, Outer = 0, Thickness = 0, Yaw = 0, Ground = true }
		local target = axis + Vector3.new(math.cos(angle), 0, math.sin(angle)) * r
		start.Pos = Vector3.new(fromCenter.X, fromTop, fromCenter.Z)
		if fromGround and fromIsland ~= base then
			local dir = flatUnit(target - fromCenter) or Vector3.xAxis
			local edge, edgeY = edgeAlong(fromGround, fromCenter, dir, fromTop)
			local point = fromCenter + dir * math.max(edge - 3, 0)
			start.Pos = Vector3.new(point.X, edgeY, point.Z)
		elseif fromGround then
			local dir = flatUnit(axis - target)
			local distance = flat(axis - target).Magnitude
			for step = 0, distance + 4, 2 do
				local point = if dir then target + dir * step else target
				local y = surfaceAt(fromGround, point.X, point.Z, fromTop)
				if y and inBox(point, 4) and outsideKeepOut({ Pos = Vector3.new(point.X, y, point.Z), Outer = 4, Thickness = 0 } :: any) then
					start.Pos = Vector3.new(point.X, y, point.Z)
					break
				end
			end
		end
		return start
	end

	-- Walks one path up from its start to its top cloud. shift (radians) moves
	-- the start round a bit when an earlier try got stuck.
	local function walk(index: number, final: Plan, shift: number)
		local endAngle = angleOf(final.Pos - axis)
		local endRadius = flat(final.Pos - axis).Magnitude
		local start = findStart(endAngle - sweeps[index] + shift, endRadius)
		local startAngle = angleOf(start.Pos - axis)
		local startRadius = flat(start.Pos - axis).Magnitude
		-- Wind the planned way round, ending exactly at the top cloud.
		local turn = sweeps[index] + wrapPi(endAngle - startAngle - sweeps[index])
		local bulge = CloudConfig.PathBulge * (startRadius + endRadius) / 2

		local function guide(t: number): Vector3
			local angle = startAngle + turn * t
			local r = startRadius + (endRadius - startRadius) * t + bulge * math.sin(math.pi * t)
			return axis + Vector3.new(math.cos(angle), 0, math.sin(angle)) * r
		end

		local climbHeight = math.max(final.Pos.Y - start.Pos.Y, 1)
		local main: { Plan } = {}

		local function tryStep(from: Plan): Plan?
			local remaining = final.Pos.Y - from.Pos.Y
			for attempt = 1, CloudConfig.Attempts do
				local relax = attempt / CloudConfig.Attempts -- get less picky the longer it takes
				local cloud = newCloud()
				cloud.Path = index
				local high = math.min(stepMax, remaining)
				local low = if remaining > stepMin and relax < 0.5 then stepMin else 0
				if relax > 0.8 and not from.Ground then
					low = -stepMin * 0.5 -- stuck under something: allow a small drop
				end
				low = math.min(low, high)
				local dy = low + (high - low) * rng:NextNumber() ^ CloudConfig.RiseSkew

				local minGap = if from.Ground
					then 1
					else (from.Outer + cloud.Outer + CloudConfig.MinGap) - (from.Inner + cloud.Inner) + 0.05
				local maxGap = reach(dy)
				if maxGap > minGap then
					-- Head for where the guide is at the new height.
					local t = math.clamp((from.Pos.Y + dy - start.Pos.Y) / climbHeight, 0, 1)
					local toGuide = flat(guide(t) - from.Pos)
					local lowSpan = from.Inner + cloud.Inner + minGap
					local highSpan = from.Inner + cloud.Inner + minGap + (maxGap - minGap) * rng:NextNumber(0.6, 1)
					local span = math.clamp(toGuide.Magnitude, lowSpan, highSpan)
					local angle = if toGuide.Magnitude > 1e-3 then angleOf(toGuide) else rng:NextNumber(0, TAU)
					angle += (rng:NextNumber() * 2 - 1) * (0.3 + relax * 2.6)
					cloud.Pos = from.Pos + Vector3.new(math.cos(angle) * span, dy, math.sin(angle) * span)
					if
						cloud.Pos.Y - cloud.Thickness > fromTop + 0.5
						and inBox(cloud.Pos, cloud.Outer)
						and apart(cloud, all)
						and clear(cloud)
					then
						return cloud
					end
				end
			end
			return nil
		end

		local current = start
		local backtracks, loops = 0, 0
		local finished = false
		while loops < 3000 do
			loops += 1
			local remaining = final.Pos.Y - current.Pos.Y
			local edgeGap = flat(final.Pos - current.Pos).Magnitude - current.Inner - final.Inner
			if remaining >= 0 and remaining <= stepMax and edgeGap <= reach(remaining) then
				finished = true
				break
			end
			local nextCloud = tryStep(current)
			if nextCloud then
				table.insert(main, nextCloud)
				table.insert(all, nextCloud)
				current = nextCloud
			elseif #main > 0 and backtracks < CloudConfig.MaxBacktracks then
				backtracks += 1
				local dropped = table.remove(main)
				table.remove(all, table.find(all, dropped))
				current = main[#main] or start
			else
				break
			end
			if loops % 15 == 0 then
				task.wait()
			end
		end
		return main, start, finished
	end

	local paths = {}
	for index, final in finals do
		local main, start, finished
		for _, shift in { 0, 30, -30, 60, -60, 90 } do
			main, start, finished = walk(index, final, math.rad(shift))
			if finished then
				break
			end
			-- Stuck: take this try's clouds away and start somewhere else.
			for _, cloud in main do
				table.remove(all, table.find(all, cloud))
			end
		end
		if not finished then
			warn(`[Clouds] {zone.Name} path {index}: couldn't finish the climb, left it out`)
		else
			table.insert(main, final)
			table.insert(paths, { Start = start, Clouds = main, Finished = finished })
		end
	end

	return {
		Paths = paths,
		Jump = jump,
		ToIsland = toIsland,
		MidY = (fromTop + toTop) / 2,
		LowTheme = themeOf(fromIsland),
		HighTheme = themeOf(toIsland),
	}
end

-- Building -----------------------------------------------------------------------

local function pick(list, rng: Random)
	return list[rng:NextInteger(1, #list)]
end

-- A point on the cloud's top at `frac` of the way out to its edge, in the
-- direction `angle` (in the cloud's own frame), and the top's height there.
local function onTop(cloud: Plan, angle: number, frac: number): Vector3
	local offset = rotateY(Vector3.new(math.cos(angle) * cloud.Inner, 0, math.sin(angle) * cloud.Outer) * frac, -cloud.Yaw)
	local y = cloud.Pos.Y + CloudConfig.MeshLift - frac * frac * cloud.Thickness * 0.45
	return Vector3.new(cloud.Pos.X + offset.X, y, cloud.Pos.Z + offset.Z)
end

local function spin(rng: Random): CFrame
	return CFrame.Angles(0, rng:NextNumber(0, TAU), 0)
end

-- Small low poly decorations for a themed cloud (CloudConfig.Themes Bits).
local bitMakers = {}

function bitMakers.Moss(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	local d = cloud.Inner * rng:NextNumber(0.3, 0.45)
	local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.45, 0.8))
	local moss = decor(Instance.new("Part"), color)
	moss.Shape = Enum.PartType.Cylinder
	moss.Size = Vector3.new(0.6, d, d)
	moss.CFrame = CFrame.new(at) * spin(rng) * CFrame.Angles(0, 0, math.pi / 2)
	moss.Parent = parent
end

function bitMakers.Leaf(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	for _ = 1, 2 do
		local s = cloud.Inner * rng:NextNumber(0.12, 0.2)
		local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.5, 0.9))
		local leaf = decor(Instance.new("WedgePart"), color)
		leaf.Size = Vector3.new(s, 0.25, s * 1.7)
		leaf.CFrame = CFrame.new(at + Vector3.new(0, 0.15, 0)) * spin(rng) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), 0, 0)
		leaf.Parent = parent
	end
end

function bitMakers.Sand(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	local d = cloud.Inner * rng:NextNumber(0.4, 0.6)
	local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.3, 0.6))
	local sand = decor(Instance.new("Part"), color)
	sand.Shape = Enum.PartType.Cylinder
	sand.Size = Vector3.new(0.4, d, d)
	sand.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2)
	sand.Parent = parent
end

function bitMakers.Shell(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	local s = math.clamp(cloud.Inner * 0.12, 0.6, 2)
	local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.55, 0.85))
	local shell = decor(Instance.new("WedgePart"), color)
	shell.Size = Vector3.new(s, s * 0.5, s * 0.9)
	shell.CFrame = CFrame.new(at + Vector3.new(0, s * 0.25, 0)) * spin(rng)
	shell.Parent = parent
end

function bitMakers.Petal(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	for _ = 1, 4 do
		local s = math.clamp(cloud.Inner * 0.1, 0.5, 1.6)
		local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.2, 0.9))
		local petal = decor(Instance.new("Part"), color)
		petal.Size = Vector3.new(s, 0.15, s * 1.4)
		petal.CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * spin(rng) * CFrame.Angles(math.rad(rng:NextNumber(-15, 15)), 0, 0)
		petal.Parent = parent
	end
end

function bitMakers.SnowCap(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0, 0.25))
	local cap = decor(Instance.new("Part"), color)
	cap.Shape = Enum.PartType.Cylinder
	local d = cloud.Inner * rng:NextNumber(0.8, 1.1)
	cap.Size = Vector3.new(0.5, d, d)
	cap.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2)
	cap.Parent = parent
end

function bitMakers.Icicle(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	for _ = 1, 2 do
		local s = math.clamp(cloud.Inner * 0.1, 0.5, 1.8)
		local long = s * rng:NextNumber(2.5, 4)
		local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.5, 0.75))
		local bottom = cloud.Pos.Y - cloud.Thickness + CloudConfig.MeshLift
		local icicle = decor(Instance.new("WedgePart"), color)
		icicle.Size = Vector3.new(s, long, s)
		-- Upside down: the point hangs under the cloud.
		icicle.CFrame = CFrame.new(at.X, bottom - long / 2 + 0.3, at.Z) * spin(rng) * CFrame.Angles(math.pi, 0, 0)
		icicle.Parent = parent
	end
end

function bitMakers.Dust(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	for _ = 1, 3 do
		local s = math.clamp(cloud.Inner * 0.08, 0.4, 1.4)
		local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.85, 1.1))
		local dust = decor(Instance.new("Part"), color)
		dust.Size = Vector3.new(s, s, s)
		dust.CFrame = CFrame.new(at + Vector3.new(0, rng:NextNumber(0.3, 2), 0))
			* CFrame.Angles(rng:NextNumber(0, TAU), rng:NextNumber(0, TAU), 0)
		dust.Parent = parent
	end
end

function bitMakers.Vine(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.55, 0.8))
	local bottom = cloud.Pos.Y - cloud.Thickness + CloudConfig.MeshLift
	local long = cloud.Thickness + cloud.Inner * rng:NextNumber(0.4, 1)
	local width = math.clamp(cloud.Inner * 0.05, 0.3, 0.9)
	local vine = decor(Instance.new("Part"), color)
	vine.Size = Vector3.new(width, long, width)
	vine.CFrame = CFrame.new(at.X, bottom + cloud.Thickness * 0.6 - long / 2, at.Z) * spin(rng)
	vine.Parent = parent
	local leaf = decor(Instance.new("WedgePart"), color)
	leaf.Size = Vector3.new(width * 3, 0.25, width * 4)
	leaf.CFrame = CFrame.new(at.X, bottom + cloud.Thickness * 0.6 - long, at.Z) * spin(rng)
	leaf.Parent = parent
end

function bitMakers.Ember(cloud: Plan, color: Color3, rng: Random, parent: Instance)
	for _ = 1, 2 do
		local s = math.clamp(cloud.Inner * 0.07, 0.35, 1.2)
		local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.6, 1.1))
		local ember = decor(Instance.new("Part"), color, Enum.Material.Neon)
		ember.Size = Vector3.new(s, s, s)
		ember.CFrame = CFrame.new(at + Vector3.new(0, rng:NextNumber(0.5, 3), 0))
			* CFrame.Angles(rng:NextNumber(0, TAU), rng:NextNumber(0, TAU), 0)
		ember.Parent = parent
	end
end

function bitMakers.Sprinkle(cloud: Plan, _color: Color3, rng: Random, parent: Instance, colors: { Color3 })
	for _ = 1, 4 do
		local s = math.clamp(cloud.Inner * 0.12, 0.6, 2)
		local at = onTop(cloud, rng:NextNumber(0, TAU), rng:NextNumber(0.2, 0.85))
		local sprinkle = decor(Instance.new("Part"), pick(colors, rng))
		sprinkle.Shape = Enum.PartType.Cylinder
		sprinkle.Size = Vector3.new(s, s * 0.3, s * 0.3)
		sprinkle.CFrame = CFrame.new(at + Vector3.new(0, s * 0.15, 0)) * spin(rng)
		sprinkle.Parent = parent
	end
end

local function addPuffs(cloud: Plan, parent: Instance, color: Color3, rng: Random)
	for _ = 1, rng:NextInteger(CloudConfig.PuffsMin, CloudConfig.PuffsMax) do
		local inner = cloud.Inner * rng:NextNumber(0.35, 0.55)
		local outer = inner * CloudConfig.Elongation
		local thickness = math.max(cloud.Thickness * rng:NextNumber(0.6, 0.9), 1.5)
		-- Keep each puff inside the cloud's footprint and below its top.
		local distance = math.max(cloud.Outer - outer, 0) * rng:NextNumber(0.6, 1)
		local angle = rng:NextNumber(0, TAU)
		local top = cloud.Pos.Y - cloud.Thickness * rng:NextNumber(0.35, 0.7)
		local center = Vector3.new(
			cloud.Pos.X + math.cos(angle) * distance,
			top - thickness / 2,
			cloud.Pos.Z + math.sin(angle) * distance
		)
		makeMesh("Puff", Vector3.new(inner * 2, thickness, outer * 2), CFrame.new(center) * spin(rng), color).Parent =
			parent
	end
end

local function addSign(part: BasePart, jump: number, island: Instance?)
	local id = island and (island:GetAttribute("IslandId") or island:GetAttribute("Theme")) or "Next"
	local name = (tostring(id):gsub("(%l)(%u)", "%1 %2"))
	local sign = Instance.new("BillboardGui")
	sign.Name = "ClimbSign"
	sign.Size = UDim2.fromOffset(240, 80)
	sign.StudsOffset = Vector3.new(0, 6, 0)
	sign.MaxDistance = 160
	sign.LightInfluence = 0
	local lines = {
		{ Text = `⬆️ {name} Island`, Color = Color3.new(1, 1, 1), Y = 0, Height = 0.55 },
		{ Text = `Needs {jump} Jump`, Color = Color3.fromRGB(255, 225, 90), Y = 0.55, Height = 0.45 },
	}
	for _, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Font = FONT
		label.Text = line.Text
		label.TextColor3 = line.Color
		label.TextScaled = true
		label.Size = UDim2.fromScale(1, line.Height)
		label.Position = UDim2.fromScale(0, line.Y)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = OUTLINE
		stroke.Parent = label
		label.Parent = sign
	end
	sign.Parent = part
end

-- One cloud: an invisible flat Floor you stand on (one-way, see CloudConfig),
-- the mesh you see, puffs under it and its theme's bits.
local function buildCloud(cloud: Plan, themeName: string, parent: Instance, rng: Random): BasePart
	local theme = CloudConfig.Themes[themeName] or CloudConfig.Themes.Base
	local model = Instance.new("Model")
	model.Name = "Cloud"
	model:SetAttribute("Theme", themeName)

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Shape = Enum.PartType.Cylinder
	floor.Anchored = true
	floor.CanCollide = true
	floor.CanQuery = true
	floor.CanTouch = false
	floor.CastShadow = false
	floor.Transparency = 1
	local thickness = CloudConfig.ColliderThickness
	local diameter = cloud.Inner * 2 * CloudConfig.ColliderRadius
	floor.Size = Vector3.new(thickness, diameter, diameter)
	floor.CFrame = CFrame.new(cloud.Pos - Vector3.new(0, thickness / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	floor:SetAttribute("Top", cloud.Pos.Y)
	CollectionService:AddTag(floor, CloudConfig.OneWayTag)
	floor.Parent = model
	model.PrimaryPart = floor

	local meshTop = cloud.Pos.Y + CloudConfig.MeshLift
	makeMesh(
		"CloudMesh",
		Vector3.new(cloud.Inner * 2, cloud.Thickness, cloud.Outer * 2),
		CFrame.new(cloud.Pos.X, meshTop - cloud.Thickness / 2, cloud.Pos.Z) * CFrame.Angles(0, cloud.Yaw, 0),
		theme.Color
	).Parent = model
	addPuffs(cloud, model, theme.PuffColor, rng)

	if #theme.Bits > 0 then
		for _ = 1, rng:NextInteger(CloudConfig.BitsMin, CloudConfig.BitsMax) do
			local bit = pick(theme.Bits, rng)
			local maker = bitMakers[bit.Kind]
			if maker then
				maker(cloud, pick(bit.Colors, rng), rng, model, bit.Colors)
			end
		end
	end
	model.Parent = parent
	return floor
end

-- Built gaps, for the admin panel's Show Paths: [zone name] = plan
local plans = {}
local showPaths = false

local function drawPaths()
	local old = cloudsFolder:FindFirstChild("PathLines")
	if old then
		old:Destroy()
	end
	if not showPaths then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "PathLines"
	for _, plan in plans do
		for index, path in plan.Paths do
			local color = CloudConfig.PathColors[index] or Color3.new(1, 1, 1)
			local last = path.Start.Pos
			for _, cloud in path.Clouds do
				local from, to = last + Vector3.new(0, 1, 0), cloud.Pos + Vector3.new(0, 1, 0)
				local length = (to - from).Magnitude
				if length > 0.1 then
					local line = decor(Instance.new("Part"), color, Enum.Material.Neon)
					line.Size = Vector3.new(0.6, 0.6, length)
					line.CFrame = CFrame.lookAt((from + to) / 2, to)
					line.Parent = folder
				end
				last = cloud.Pos
			end
		end
	end
	folder.Parent = cloudsFolder
end

local function buildZone(zone: BasePart, gapNumber: number, plan, rng: Random)
	local old = cloudsFolder:FindFirstChild(zone.Name)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = zone.Name
	folder:SetAttribute("Gap", gapNumber)
	folder:SetAttribute("RequiredJump", plan.Jump)

	for index, path in plan.Paths do
		local pathFolder = Instance.new("Folder")
		pathFolder.Name = "Path" .. index
		for step, cloud in path.Clouds do
			local themeName = if cloud.Pos.Y < plan.MidY then plan.LowTheme else plan.HighTheme
			local floor = buildCloud(cloud, themeName, pathFolder, rng)
			floor:SetAttribute("Gap", gapNumber)
			floor:SetAttribute("Path", index)
			floor:SetAttribute("Step", step)
			if CloudConfig.ShowSigns and step == 1 then
				addSign(floor, plan.Jump, plan.ToIsland)
			end
		end
		pathFolder.Parent = folder
		task.wait()
	end
	folder.Parent = cloudsFolder
end

local function gapNumberOf(zone: Instance): number
	return numberAttribute(zone, "Gap") or tonumber(string.match(zone.Name, "%d+")) or 1
end

local function generate(zone: Instance, keepOut, seed: number?)
	if not zone:IsA("BasePart") then
		return
	end
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	zone.Transparency = 1

	local gapNumber = gapNumberOf(zone)
	local zoneSeed = numberAttribute(zone, "Seed")
	local rng = if seed then Random.new(seed * 31 + gapNumber) elseif zoneSeed then Random.new(zoneSeed) else Random.new()
	local started = os.clock()
	local ok, plan = pcall(planZone, zone, rng, keepOut)
	probe.Parent = nil
	if not ok then
		warn(`[Clouds] {zone.Name} failed: {plan}`)
		return
	end
	buildZone(zone, gapNumber, plan, rng)
	plans[zone.Name] = plan

	-- Tell the island above what this gap was built for (HUD, JumpBalance).
	local island = plan.ToIsland
	if island and island ~= map:FindFirstChild("Base") then
		island:SetAttribute("RequiredJump", plan.Jump)
		island:SetAttribute("RequiredLevel", JumpBalance.LevelForJump(plan.Jump))
	end
	local counts = {}
	for _, path in plan.Paths do
		table.insert(counts, tostring(#path.Clouds) .. (if path.Finished then "" else "!"))
	end
	print(
		`[Clouds] {zone.Name}: {#plan.Paths} paths ({table.concat(counts, " + ")} clouds, {plan.LowTheme} -> {plan.HighTheme}),`
			.. ` built for {plan.Jump} jump`
			.. string.format(" (%.1fs)", os.clock() - started)
	)
end

local building = false

-- Builds (or rebuilds) every gap's clouds, lowest gap first. seed = nil uses
-- each zone's Seed attribute or a random layout; a number gives the same
-- layout every time. Returns false if a build is already running.
function Clouds.BuildAll(seed: number?): boolean
	if building then
		return false
	end
	building = true
	local okAll, err = pcall(function()
		local keepOut = keepOutZones()
		local zones = {}
		for _, zone in zonesFolder:GetChildren() do
			if zone:IsA("BasePart") then
				table.insert(zones, zone)
			end
		end
		table.sort(zones, function(a, b)
			return gapNumberOf(a) < gapNumberOf(b)
		end)
		for _, zone in zones do
			generate(zone, keepOut, seed)
		end
		drawPaths()
	end)
	building = false
	if not okAll then
		warn("[Clouds] build failed: " .. tostring(err))
	end
	return true
end

function Clouds.BuildZone(zone: Instance)
	generate(zone, keepOutZones())
	drawPaths()
end

function Clouds.IsBuilding(): boolean
	return building
end

-- Admin: neon lines along every path (red = 1, green = 2, blue = 3).
function Clouds.SetShowPaths(on: boolean)
	showPaths = on
	drawPaths()
end

function Clouds.ShowingPaths(): boolean
	return showPaths
end

return Clouds
