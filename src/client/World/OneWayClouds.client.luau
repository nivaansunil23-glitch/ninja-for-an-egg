-- One-way clouds: jump up through a cloud from below, land on it from above.
-- Every solid cloud (tagged CloudConfig.OneWayTag, built by server
-- World/Clouds) is solid on the server. Here, just for this player's own
-- character (which this client simulates), a Floor turns off while your feet
-- are under its top and back on once they're up at it. The change is local,
-- so other players and the server aren't affected.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CloudConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("CloudConfig"))

local player = Players.LocalPlayer
local ON_TOLERANCE = CloudConfig.OnTolerance
local OFF_BELOW = CloudConfig.OffBelow

-- [floor] = { Top = its top's height, Solid = what we last set }
local floors: { [BasePart]: { Top: number, Solid: boolean } } = {}

local function add(instance: Instance)
	if instance:IsA("BasePart") then
		local top = instance:GetAttribute("Top")
		floors[instance] = {
			Top = if type(top) == "number" then top else instance.Position.Y + instance.Size.X / 2,
			Solid = instance.CanCollide,
		}
	end
end

for _, instance in CollectionService:GetTagged(CloudConfig.OneWayTag) do
	add(instance)
end
CollectionService:GetInstanceAddedSignal(CloudConfig.OneWayTag):Connect(add)
CollectionService:GetInstanceRemovedSignal(CloudConfig.OneWayTag):Connect(function(instance)
	floors[instance :: BasePart] = nil
end)

-- Height of the character's feet.
local function feetY(): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return nil
	end
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return root.Position.Y - root.Size.Y / 2 - 2 -- R6 legs are 2 studs
	end
	return root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
end

RunService.PreSimulation:Connect(function()
	local feet = feetY()
	if not feet then
		return
	end
	for floor, entry in floors do
		-- Hysteresis: once you're on it, it stays solid until you're well under it.
		local solid = if entry.Solid then feet >= entry.Top - OFF_BELOW else feet >= entry.Top - ON_TOLERANCE
		if solid ~= entry.Solid then
			entry.Solid = solid
			floor.CanCollide = solid
		end
	end
end)
