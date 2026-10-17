-- Random cloud platforms between the islands, like Bubble Gum Sim, Ninja
-- Legends and Jump for Phonk. Every box in Workspace.Map.CloudZones (Gap1,
-- Gap2, ...) gets a new random climb each server. A gap is built for one jump
-- power (JumpBalance, or a RequiredJump attribute on the box): each step up is
-- a share of that jump's height and each sideways gap a share of how far you
-- get in the air, so every cloud is reachable with that jump power without
-- sprinting. Higher gaps need more jump power, so their steps are taller,
-- wider apart and their clouds bigger.
--
-- How a gap is built:
--   1. The top cloud goes just off the edge of the island above, next to its
--      LandingSpot, one short hop below its top.
--   2. A random walk climbs to it from the island below, or from the peak of a
--      launch from the launch trampoline if that's in this zone. Every step is
--      checked against jump physics and the map: no cloud inside an island or
--      right under something you'd bonk your head on.
--   3. Side clouds branch off the climb so it reads as a random cloud field,
--      and every cloud gets a few puffs tucked under it.
-- Clouds go in Workspace.Map.Clouds.<GapName>. The jump power each gap was
-- built for is written on the island above it (RequiredJump, RequiredLevel)
-- so the HUD and JumpBalance.GetIslands() show the same numbers.

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Trampolines = require(Shared:WaitForChild("Trampolines"))
local Config = Shared:WaitForChild("Config")
local CloudConfig = require(Config:WaitForChild("CloudConfig"))
local JumpBalance = require(Config:WaitForChild("JumpBalance"))

local FONT = Enum.Font.FredokaOne
local OUTLINE = Color3.fromRGB(45, 25, 70)

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

local function makeCloudPart(size: Vector3, cframe: CFrame, color: Color3, solid: boolean): BasePart
	local source = getTemplate()
	local part: BasePart
	if source then
		part = source:Clone()
		for _, child in part:GetChildren() do
			child:Destroy()
		end
	else
		part = Instance.new("Part")
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
	end
	part.Name = if solid then "Cloud" else "Puff"
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = solid
	part.CanQuery = solid
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Transparency = 0
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
	Pos: Vector3, -- middle of the cloud's top
	Inner: number, -- half its width
	Outer: number, -- half its length
	Thickness: number,
	Yaw: number,
	Side: boolean?,
	Ground: boolean?,
}

local function planZone(zone: BasePart, gapNumber: number, rng: Random, keepOut)
	local fromIsland = findIsland(numberAttribute(zone, "FromIsland"))
	local toIsland = findIsland(numberAttribute(zone, "ToIsland"))
	local boxCFrame, boxSize = zone.CFrame, zone.Size

	local fromTop = if fromIsland and fromIsland ~= map:FindFirstChild("Base")
		then numberAttribute(fromIsland, "TopY")
		else nil
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
	-- Clouds closer than this in height must not overlap from above.
	local band = maxHeight + CloudConfig.PlayerHeight + baseInner

	-- How far apart (edge to edge) a cloud dy higher can be and still be reachable
	-- at walking speed with launch speed `speed` (the gap's jump unless given).
	local function reach(dy: number, speed: number?): number
		local v = speed or jump
		local disc = v * v - 2 * gravity * math.max(dy, 0)
		if disc < 0 then
			return 0
		end
		return CloudConfig.WalkSpeed * (v + math.sqrt(disc)) / gravity * CloudConfig.ReachFactor
	end

	local exclude = { probe, Workspace.Terrain }
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
		local inner = baseInner * rng:NextNumber(0.85, 1.15)
		return {
			Pos = Vector3.zero,
			Inner = inner,
			Outer = inner * CloudConfig.Elongation,
			Thickness = math.clamp(inner * CloudConfig.ThicknessRatio, CloudConfig.ThicknessMin, CloudConfig.ThicknessMax),
			Yaw = rng:NextNumber(0, math.pi * 2),
		}
	end

	local function inBox(cloud: Plan): boolean
		local localPos = boxCFrame:PointToObjectSpace(cloud.Pos)
		return math.abs(localPos.X) <= boxSize.X / 2 - cloud.Outer and math.abs(localPos.Z) <= boxSize.Z / 2 - cloud.Outer
	end

	local function apart(cloud: Plan, others: { Plan }): boolean
		for _, other in others do
			if math.abs(cloud.Pos.Y - other.Pos.Y) < band then
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

	-- 1. The top cloud, just off the island above.
	local final = newCloud()
	local finalStep = maxHeight * rng:NextNumber(CloudConfig.FinalStepMin, CloudConfig.FinalStepMax)
	local placed = false
	if toIsland then
		local toGround = groundOf(toIsland)
		local center = islandCenter(toIsland)
		local spot = toIsland:FindFirstChild("LandingSpot", true)
		local base = if spot and spot:IsA("BasePart") then spot.Position else center
		local outward = flatUnit(base - center) or flatUnit(boxCFrame.Position - center) or Vector3.xAxis
		for _, swing in { 0, 25, -25, 50, -50, 80, -80, 120, -120, 180 } do
			local dir = rotateY(outward, math.rad(swing))
			local edge, edgeY = edgeAlong(toGround, base, dir, toTop)
			local gap = CloudConfig.MinGap
			while gap <= reach(finalStep) do
				local point = base + dir * (edge + gap + final.Inner)
				final.Pos = Vector3.new(point.X, edgeY - finalStep, point.Z)
				if clear(final) then
					placed = true
					break
				end
				gap += 1
			end
			if placed then
				break
			end
		end
		if not placed then
			-- Nowhere clear: put it by the landing spot anyway so the climb still ends there.
			local point = base + outward * (edgeAlong(toGround, base, outward, toTop) + CloudConfig.MinGap + final.Inner)
			final.Pos = Vector3.new(point.X, toTop - finalStep, point.Z)
			warn(`[Clouds] {zone.Name}: no clear spot by the top island, placed the last cloud anyway`)
		end
	else
		final.Pos = Vector3.new(boxCFrame.Position.X, toTop - finalStep, boxCFrame.Position.Z)
	end

	local main: { Plan } = {}

	-- 2a. Start: the launch trampoline's peak if it's on this zone's bottom
	-- island, otherwise the ground of the island below nearest the top cloud.
	local start: Plan = { Pos = Vector3.zero, Inner = 0, Outer = 0, Thickness = 0, Yaw = 0, Ground = true }
	local launched = false
	for _, trampoline in Trampolines.GetAll(Trampolines.Launch) do
		local info = Trampolines.GetPadInfo(trampoline)
		if not launched and info and math.abs(info.Top - fromTop) < 20 and inBox({ Pos = info.Center, Outer = 0 } :: any) then
			local launchSpeed = jump * math.sqrt(JumpBalance.LaunchHeightMultiplier)
			local launchHeight = JumpBalance.LaunchHeightMultiplier * maxHeight
			for _ = 1, CloudConfig.Attempts do
				local cloud = newCloud()
				local dy = launchHeight * rng:NextNumber(0.55, 0.8)
				local nearest = info.Radius + CloudConfig.LaunchClearance + cloud.Outer + 0.5
				local farthest = info.Radius + cloud.Inner + reach(dy, launchSpeed)
				if farthest > nearest then
					local distance = nearest + (farthest - nearest) * rng:NextNumber(0, 0.6)
					local angle = rng:NextNumber(0, math.pi * 2)
					cloud.Pos = Vector3.new(
						info.Center.X + math.cos(angle) * distance,
						info.Top + dy,
						info.Center.Z + math.sin(angle) * distance
					)
					if cloud.Pos.Y < final.Pos.Y and inBox(cloud) and apart(cloud, { final }) and clear(cloud) then
						table.insert(main, cloud)
						launched = true
						break
					end
				end
			end
		end
	end

	if not launched and fromIsland then
		local fromGround = groundOf(fromIsland)
		local center = islandCenter(fromIsland)
		-- Aim for ground near the top cloud, pushed out from under the island above.
		local target = final.Pos
		if toIsland then
			local away = flatUnit(final.Pos - islandCenter(toIsland))
			if away then
				target += away * (final.Outer + 6)
			end
		end
		local dir = flatUnit(center - target)
		local distance = flat(center - target).Magnitude
		start.Pos = Vector3.new(center.X, fromTop, center.Z)
		for step = 0, distance + 4, 2 do
			local point = if dir then target + dir * step else target
			local y = surfaceAt(fromGround, point.X, point.Z, fromTop)
			if y and inBox({ Pos = point, Outer = 4 } :: any) then
				start.Pos = Vector3.new(point.X, y, point.Z)
				break
			end
		end
	elseif not launched then
		start.Pos = Vector3.new(boxCFrame.Position.X, fromTop, boxCFrame.Position.Z)
	end

	-- 2b. Random walk up to the top cloud.
	local averageStep = (stepMin + stepMax) / 2
	local averageSpan = 2 * baseInner + (CloudConfig.MinGap + reach(averageStep)) / 2

	local function tryStep(from: Plan): Plan?
		local remaining = final.Pos.Y - from.Pos.Y
		for attempt = 1, CloudConfig.Attempts do
			local relax = attempt / CloudConfig.Attempts -- get less picky the longer it takes
			local cloud = newCloud()
			local high = math.min(stepMax, remaining)
			local low = if remaining > stepMin and relax < 0.5 then stepMin else 0
			if relax > 0.8 and not from.Ground then
				low = -stepMin -- stuck under something: allow a small drop
			end
			low = math.min(low, high)
			local dy = low + (high - low) * rng:NextNumber()

			local minGap = if from.Ground
				then 1
				else (from.Outer + cloud.Outer + CloudConfig.MinGap) - (from.Inner + cloud.Inner) + 0.05
			local maxGap = reach(math.abs(dy))
			if maxGap > minGap then
				local gap = minGap + (maxGap - minGap) * rng:NextNumber()
				local span = from.Inner + cloud.Inner + gap
				-- Wander while there's height to spare, head for the top cloud when there isn't.
				local toFinal = flat(final.Pos - from.Pos)
				local stepsLeft = math.max(remaining - dy, 0) / averageStep + 1
				local urgency = math.clamp(toFinal.Magnitude / (stepsLeft * averageSpan * 0.8), 0, 1)
				local spread = math.pi * math.max(1 - urgency, relax * 0.75)
				local angle = math.atan2(toFinal.Z, toFinal.X) + (rng:NextNumber() * 2 - 1) * spread
				cloud.Pos = from.Pos + Vector3.new(math.cos(angle) * span, dy, math.sin(angle) * span)
				if
					cloud.Pos.Y - cloud.Thickness > fromTop + 0.5
					and inBox(cloud)
					and apart(cloud, main)
					and apart(cloud, { final })
					and clear(cloud)
				then
					return cloud
				end
			end
		end
		return nil
	end

	local current = main[#main] or start
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
			current = nextCloud
		elseif #main > (if launched then 1 else 0) and backtracks < CloudConfig.MaxBacktracks then
			backtracks += 1
			table.remove(main)
			current = main[#main] or start
		else
			break
		end
		if loops % 15 == 0 then
			task.wait()
		end
	end
	if not finished then
		warn(`[Clouds] {zone.Name}: couldn't finish the climb ({#main} clouds placed)`)
	end

	-- 3. Side clouds branching off the climb.
	local all = table.clone(main)
	table.insert(all, final)
	local wanted = math.floor(#main * CloudConfig.BranchRatio + 0.5)
	local branches, tries = 0, 0
	while branches < wanted and tries < wanted * 15 do
		tries += 1
		local anchor = all[rng:NextInteger(1, #all)]
		local cloud = newCloud()
		local dy = (rng:NextNumber() * 2 - 1) * stepMax
		local minGap = (anchor.Outer + cloud.Outer + CloudConfig.MinGap) - (anchor.Inner + cloud.Inner) + 0.05
		local maxGap = reach(math.abs(dy))
		if maxGap > minGap then
			local span = anchor.Inner + cloud.Inner + minGap + (maxGap - minGap) * rng:NextNumber()
			local angle = rng:NextNumber(0, math.pi * 2)
			cloud.Pos = anchor.Pos + Vector3.new(math.cos(angle) * span, dy, math.sin(angle) * span)
			if
				cloud.Pos.Y - cloud.Thickness > fromTop + 0.5
				and cloud.Pos.Y < toTop - 1
				and inBox(cloud)
				and apart(cloud, all)
				and clear(cloud)
			then
				cloud.Side = true
				table.insert(all, cloud)
				branches += 1
			end
		end
		if tries % 20 == 0 then
			task.wait()
		end
	end

	return {
		Clouds = all,
		PathCount = #main + 1,
		Branches = branches,
		Jump = jump,
		ToIsland = toIsland,
		First = main[1] or final,
		Launched = launched,
	}
end

-- Building -----------------------------------------------------------------------

local function addPuffs(cloud: Plan, parent: Instance, rng: Random)
	for _ = 1, rng:NextInteger(CloudConfig.PuffsMin, CloudConfig.PuffsMax) do
		local inner = cloud.Inner * rng:NextNumber(0.35, 0.55)
		local outer = inner * CloudConfig.Elongation
		local thickness = math.max(cloud.Thickness * rng:NextNumber(0.6, 0.9), 1.5)
		-- Keep each puff inside the cloud's footprint and below its top.
		local distance = math.max(cloud.Outer - outer, 0) * rng:NextNumber(0.6, 1)
		local angle = rng:NextNumber(0, math.pi * 2)
		local top = cloud.Pos.Y - cloud.Thickness * rng:NextNumber(0.35, 0.7)
		local center = Vector3.new(
			cloud.Pos.X + math.cos(angle) * distance,
			top - thickness / 2,
			cloud.Pos.Z + math.sin(angle) * distance
		)
		local puff = makeCloudPart(
			Vector3.new(inner * 2, thickness, outer * 2),
			CFrame.new(center) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
			CloudConfig.PuffColor,
			false
		)
		puff.Parent = parent
	end
end

local function addSign(part: BasePart, jump: number, island: Instance?)
	local id = island and (island:GetAttribute("IslandId") or island:GetAttribute("Theme")) or "Next"
	local name = (tostring(id):gsub("(%l)(%u)", "%1 %2"))
	local sign = Instance.new("BillboardGui")
	sign.Name = "ClimbSign"
	sign.Size = UDim2.fromOffset(240, 80)
	sign.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 5, 0)
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

local function buildZone(zone: BasePart, gapNumber: number, plan, rng: Random)
	local old = cloudsFolder:FindFirstChild(zone.Name)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = zone.Name
	folder:SetAttribute("Gap", gapNumber)
	folder:SetAttribute("RequiredJump", plan.Jump)

	local color = zone:GetAttribute("CloudColor")
	if typeof(color) ~= "Color3" then
		color = CloudConfig.Color
	end
	for index, cloud in plan.Clouds do
		local part = makeCloudPart(
			Vector3.new(cloud.Inner * 2, cloud.Thickness, cloud.Outer * 2),
			CFrame.new(cloud.Pos - Vector3.new(0, cloud.Thickness / 2, 0)) * CFrame.Angles(0, cloud.Yaw, 0),
			color,
			true
		)
		part:SetAttribute("Gap", gapNumber)
		if not cloud.Side then
			part:SetAttribute("Step", index)
		end
		part.Parent = folder
		addPuffs(cloud, folder, rng)
		if CloudConfig.ShowSigns and cloud == plan.First then
			addSign(part, plan.Jump, plan.ToIsland)
		end
	end
	folder.Parent = cloudsFolder
end

local function gapNumberOf(zone: Instance): number
	return numberAttribute(zone, "Gap") or tonumber(string.match(zone.Name, "%d+")) or 1
end

local function generate(zone: Instance, keepOut)
	if not zone:IsA("BasePart") then
		return
	end
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	zone.Transparency = 1

	local gapNumber = gapNumberOf(zone)
	local seed = numberAttribute(zone, "Seed")
	local rng = if seed then Random.new(seed) else Random.new()
	local started = os.clock()
	local ok, plan = pcall(planZone, zone, gapNumber, rng, keepOut)
	if not ok then
		warn(`[Clouds] {zone.Name} failed: {plan}`)
		return
	end
	buildZone(zone, gapNumber, plan, rng)

	-- Tell the island above what this gap was built for (HUD, JumpBalance).
	local island = plan.ToIsland
	if island and island ~= map:FindFirstChild("Base") then
		island:SetAttribute("RequiredJump", plan.Jump)
		island:SetAttribute("RequiredLevel", JumpBalance.LevelForJump(plan.Jump))
	end
	print(
		`[Clouds] {zone.Name}: {#plan.Clouds} clouds ({plan.PathCount} on the climb, {plan.Branches} side),`
			.. ` built for {plan.Jump} jump{if plan.Launched then ", starts from the launch trampoline" else ""}`
			.. string.format(" (%.1fs)", os.clock() - started)
	)
end

task.spawn(function()
	task.wait(1) -- let the map settle
	local keepOut = keepOutZones()
	local zones = {}
	for _, zone in zonesFolder:GetChildren() do
		if zone:IsA("BasePart") then
			table.insert(zones, zone)
		end
	end
	-- Lowest gap first, so higher gaps steer clear of the clouds already built.
	table.sort(zones, function(a, b)
		return gapNumberOf(a) < gapNumberOf(b)
	end)
	for _, zone in zones do
		generate(zone, keepOut)
	end
	probe.Parent = nil

	zonesFolder.ChildAdded:Connect(function(zone)
		task.wait(1)
		generate(zone, keepOutZones())
		probe.Parent = nil
	end)
end)
