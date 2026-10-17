--!nonstrict
-- Spawns eggs on every island in Workspace.Map.Islands.
--
-- Island setup (done in the map):
--   * The island model's name (or its "IslandId" attribute) picks which eggs
--     spawn there, using the Island field in EggConfig.Eggs.
--   * Spawn spots are BaseParts named "EggSpawn" (or tagged "EggSpawn") inside
--     the island. The egg's bottom sits at the bottom of the spot part.
--     Without spots, eggs land on random ground spots of the island.
--   * Optional "MaxEggs" attribute on the island overrides the egg limit.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggConfig = require(ReplicatedStorage.Shared.EggConfig)
local EggCarry = require(script.Parent.EggCarry)
local EggFactory = require(script.Parent.EggFactory)
local EggMap = require(script.Parent.EggMap)

local S = EggConfig.Settings
local rng = Random.new()

local EggSpawner = {}

local running = {} -- [island] = true

local function pickEgg(pool)
	local total = 0
	for _, eggId in pool do
		total += EggConfig.Eggs[eggId].SpawnWeight or 1
	end
	local roll = rng:NextNumber() * total
	for _, eggId in pool do
		roll -= EggConfig.Eggs[eggId].SpawnWeight or 1
		if roll <= 0 then
			return eggId
		end
	end
	return pool[#pool]
end

local function getSpawnSpots(island)
	local spots = {}
	for _, d in island:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "EggSpawn" or CollectionService:HasTag(d, "EggSpawn")) then
			table.insert(spots, d)
		end
	end
	return spots
end

-- Picks a random flat spot on top of the island by raycasting down onto it.
local function randomGroundSpot(island)
	local cframe, size
	if island:IsA("Model") then
		cframe, size = island:GetBoundingBox()
	elseif island:IsA("BasePart") then
		cframe, size = island.CFrame, island.Size
	else
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { island }
	for _ = 1, 10 do
		local offset = Vector3.new(rng:NextNumber(-0.4, 0.4) * size.X, size.Y / 2 + 5, rng:NextNumber(-0.4, 0.4) * size.Z)
		local origin = cframe.Position + offset
		local hit = workspace:Raycast(origin, Vector3.new(0, -(size.Y + 10), 0), params)
		if hit and hit.Normal.Y > 0.7 then
			return CFrame.new(hit.Position)
		end
	end
	return nil
end

local function runIsland(island)
	if running[island] then
		return
	end
	local key = island:GetAttribute("IslandId") or island.Name
	local pool = EggConfig.EggsByIsland[key]
	if not pool then
		-- Base island and decoration have no eggs.
		return
	end
	running[island] = true

	local spots = getSpawnSpots(island)
	local used = {} -- [spot] = true
	local count = 0

	local function spawnOne()
		local maxEggs = island:GetAttribute("MaxEggs") or S.MaxEggsPerIsland
		if count >= maxEggs then
			return
		end

		local cframe, slot
		if #spots > 0 then
			local free = {}
			for _, spot in spots do
				if not used[spot] and spot.Parent then
					table.insert(free, spot)
				end
			end
			if #free == 0 then
				return
			end
			slot = free[rng:NextInteger(1, #free)]
			cframe = CFrame.new(slot.Position - Vector3.new(0, slot.Size.Y / 2, 0))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		else
			cframe = randomGroundSpot(island)
			if not cframe then
				return
			end
			slot = {}
		end

		local eggId = pickEgg(pool)
		local data = EggFactory.NewData(eggId, EggFactory.RollKg(EggConfig.Eggs[eggId]))
		local part = EggCarry.SpawnWorldEgg(data, cframe)
		part:SetAttribute("Island", key)
		used[slot] = true
		count += 1
		part.Destroying:Connect(function()
			used[slot] = nil
			count -= 1
		end)
	end

	task.spawn(function()
		local maxEggs = island:GetAttribute("MaxEggs") or S.MaxEggsPerIsland
		for _ = 1, maxEggs do
			spawnOne()
		end
		while island.Parent do
			task.wait(S.IslandRespawnSeconds)
			spawnOne()
		end
		running[island] = nil
	end)
end

function EggSpawner.Start()
	task.spawn(function()
		local islands = EggMap.WaitForFolder("Islands")
		for _, island in islands:GetChildren() do
			runIsland(island)
		end
		islands.ChildAdded:Connect(runIsland)
	end)
end

return EggSpawner
