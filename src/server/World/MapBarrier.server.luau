-- Invisible walls around the whole map (the base, every island and every cloud
-- zone) so nobody can fly or get flung off the edge of the world. Built at
-- runtime from Map.CloudZones and Map.Base, so they follow the map if it grows.

local Workspace = game:GetService("Workspace")

local MARGIN = 30 -- studs past the outermost cloud zone / island
local BOTTOM = -400 -- below the base's rocks
local EXTRA_TOP = 300 -- above the highest zone
local THICKNESS = 4

local map = Workspace:WaitForChild("Map", math.huge)
task.wait(1) -- let the map settle

local minX, maxX, minZ, maxZ, topY = math.huge, -math.huge, math.huge, -math.huge, 0

local function include(cframe: CFrame, size: Vector3)
	-- Axis-aligned bounds of a (possibly rotated) box.
	local half = size / 2
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local corner = cframe:PointToWorldSpace(Vector3.new(half.X * sx, 0, half.Z * sz))
			minX, maxX = math.min(minX, corner.X), math.max(maxX, corner.X)
			minZ, maxZ = math.min(minZ, corner.Z), math.max(maxZ, corner.Z)
		end
	end
	topY = math.max(topY, cframe.Position.Y + half.Y)
end

local zones = map:FindFirstChild("CloudZones")
if zones then
	for _, zone in zones:GetChildren() do
		if zone:IsA("BasePart") then
			include(zone.CFrame, zone.Size)
		end
	end
end
for _, name in { "Base", "Islands" } do
	local folder = map:FindFirstChild(name)
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				local cframe, size = child:GetBoundingBox()
				include(cframe, size)
			elseif child:IsA("BasePart") then
				include(child.CFrame, child.Size)
			end
		end
	end
end

if minX == math.huge then
	warn("[MapBarrier] No map found, no walls built")
	return
end

minX -= MARGIN
maxX += MARGIN
minZ -= MARGIN
maxZ += MARGIN
local top = topY + EXTRA_TOP
local height = top - BOTTOM
local midY = (top + BOTTOM) / 2
local midX, midZ = (minX + maxX) / 2, (minZ + maxZ) / 2
local width, depth = maxX - minX, maxZ - minZ

local folder = Instance.new("Folder")
folder.Name = "MapBarrier"

local function wall(name: string, position: Vector3, size: Vector3)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Material = Enum.Material.SmoothPlastic
	part.Size = size
	part.Position = position
	part.Parent = folder
end

wall("North", Vector3.new(midX, midY, minZ - THICKNESS / 2), Vector3.new(width + THICKNESS * 2, height, THICKNESS))
wall("South", Vector3.new(midX, midY, maxZ + THICKNESS / 2), Vector3.new(width + THICKNESS * 2, height, THICKNESS))
wall("West", Vector3.new(minX - THICKNESS / 2, midY, midZ), Vector3.new(THICKNESS, height, depth))
wall("East", Vector3.new(maxX + THICKNESS / 2, midY, midZ), Vector3.new(THICKNESS, height, depth))
wall("Ceiling", Vector3.new(midX, top + THICKNESS / 2, midZ), Vector3.new(width + THICKNESS * 2, THICKNESS, depth + THICKNESS * 2))

folder.Parent = map
print(string.format("[MapBarrier] Walls around X %.0f..%.0f, Z %.0f..%.0f, up to Y %.0f", minX, maxX, minZ, maxZ, top))
