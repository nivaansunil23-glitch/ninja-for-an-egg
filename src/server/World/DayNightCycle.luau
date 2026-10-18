-- Runs the day/night loop (lengths in Shared.Config.DayNightConfig) and puts
-- the phase on Workspace (IsNight, DayNightEndsAt) for everything else:
--   * Eggs/EggSpawner clears island eggs at night and refills them at day.
--   * The client blocks the launch pad and jetpack lift, fades the lighting
--     and shows the HUD timer.
--   * Here: nobody goes up at night. An invisible ceiling (Map.NightCeiling,
--     NightCeilingHeight over the base, as wide as Map.MapBarrier) turns solid.
--     When night starts, anyone above NightMaxHeight is sent to their plot,
--     and during the night anyone standing on a cloud or sky island is too.
--     A held jetpack is put away.
--     Jumping and trampoline training still work.
-- Started by World/DayNight. The admin panel calls SetPhase / Skip.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local DayNightConfig = require(Config:WaitForChild("DayNightConfig"))
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local PenService = require(script.Parent.Parent:WaitForChild("Eggs"):WaitForChild("PenService"))

local CHECK_SECONDS = 0.25
local STAND_CHECK = 8 -- studs below the root that count as standing on something
local NO_CRACK_SECONDS = 3 -- the trip down never cracks a carried egg
local CEILING_THICKNESS = 4
local CEILING_TILE = 2000 -- parts can't be bigger than 2048 studs a side

local DayNightCycle = {}

local started = false
local noCrack = {} -- [Player] = token of their latest trip down
local standRay = RaycastParams.new()
standRay.FilterType = Enum.RaycastFilterType.Exclude

local function groundY(): number
	local value = Workspace:GetAttribute("GroundY")
	return if type(value) == "number" then value else PlayerConfig.GroundY
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root :: BasePart
	end
	return nil
end

-- Back to their plot (or the spawn if they have none), egg and all.
local function sendDown(player: Player)
	local token = {}
	player:SetAttribute("NoFallCrack", true)
	noCrack[player] = token
	task.delay(NO_CRACK_SECONDS, function()
		if noCrack[player] == token then
			noCrack[player] = nil
			player:SetAttribute("NoFallCrack", nil)
		end
	end)
	if not PenService.SendHome(player) then
		local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if spawn and player.Character then
			player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
		end
	end
end

-- Is this player standing on a cloud or a sky island?
local function upHigh(player: Player, root: BasePart): boolean
	local map = Workspace:FindFirstChild("Map")
	if not map then
		return false
	end
	standRay.FilterDescendantsInstances = { player.Character }
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -STAND_CHECK, 0), standRay)
	if not hit then
		return false
	end
	for _, name in { "Clouds", "Islands" } do
		local folder = map:FindFirstChild(name)
		if folder and hit.Instance:IsDescendantOf(folder) then
			return true
		end
	end
	return false
end

-- No jetpack lift at night: put it away if someone holds it.
local function putAwayJetpack(player: Player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if character and backpack then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("GearId") == "Jetpack" then
				child.Parent = backpack
			end
		end
	end
end

-- The night ceiling: invisible tiles over the whole map, only solid at night.
local ceiling: Folder? = nil

local function setCeiling(night: boolean)
	if ceiling then
		for _, part in ceiling:GetChildren() do
			if part:IsA("BasePart") then
				part.CanCollide = night
			end
		end
	end
end

local function buildCeiling()
	local map = Workspace:WaitForChild("Map", math.huge)
	local barrier = map:WaitForChild("MapBarrier", math.huge)
	local minX, maxX = barrier:GetAttribute("MinX"), barrier:GetAttribute("MaxX")
	local minZ, maxZ = barrier:GetAttribute("MinZ"), barrier:GetAttribute("MaxZ")
	if type(minX) ~= "number" or type(maxX) ~= "number" or type(minZ) ~= "number" or type(maxZ) ~= "number" then
		warn("[DayNight] Map.MapBarrier has no bounds, no night ceiling")
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "NightCeiling"
	local y = groundY() + DayNightConfig.NightCeilingHeight + CEILING_THICKNESS / 2
	local countX = math.ceil((maxX - minX) / CEILING_TILE)
	local countZ = math.ceil((maxZ - minZ) / CEILING_TILE)
	local sizeX, sizeZ = (maxX - minX) / countX, (maxZ - minZ) / countZ
	for i = 1, countX do
		for j = 1, countZ do
			local part = Instance.new("Part")
			part.Name = "Ceiling"
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Transparency = 1
			part.Material = Enum.Material.SmoothPlastic
			part.Size = Vector3.new(sizeX, CEILING_THICKNESS, sizeZ)
			part.Position = Vector3.new(minX + (i - 0.5) * sizeX, y, minZ + (j - 0.5) * sizeZ)
			part.Parent = folder
		end
	end
	folder.Parent = map
	ceiling = folder
	setCeiling(DayNightConfig.IsNight())
end

-- Switches to day or night now, with a full-length phase from here.
function DayNightCycle.SetPhase(night: boolean)
	local seconds = if night then DayNightConfig.NightSeconds else DayNightConfig.DaySeconds
	Workspace:SetAttribute("DayNightEndsAt", Workspace:GetServerTimeNow() + seconds)
	Workspace:SetAttribute("IsNight", night)
	setCeiling(night)
	if night then
		local cap = groundY() + DayNightConfig.NightMaxHeight
		for _, player in Players:GetPlayers() do
			local root = getRoot(player)
			if root and root.Position.Y > cap then
				task.spawn(sendDown, player)
			end
		end
	end
end

-- Jumps straight to the next phase.
function DayNightCycle.Skip()
	DayNightCycle.SetPhase(not DayNightConfig.IsNight())
end

function DayNightCycle.Start()
	if started then
		return
	end
	started = true
	DayNightCycle.SetPhase(false)
	task.spawn(buildCeiling)
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			if DayNightConfig.SecondsLeft() <= 0 then
				DayNightCycle.Skip()
			end
			if DayNightConfig.IsNight() then
				for _, player in Players:GetPlayers() do
					putAwayJetpack(player)
					local root = getRoot(player)
					if root and upHigh(player, root) then
						sendDown(player)
					end
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	noCrack[player] = nil
end)

return DayNightCycle
