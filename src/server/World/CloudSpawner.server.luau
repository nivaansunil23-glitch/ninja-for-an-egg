-- Builds the climbing clouds when the server starts (the work is in
-- World/Clouds, which the admin panel also uses to rebuild them). A zone box
-- added to Workspace.Map.CloudZones later gets its clouds too.

local Clouds = require(script.Parent:WaitForChild("Clouds"))

local map = workspace:WaitForChild("Map", math.huge)
local zonesFolder = map:WaitForChild("CloudZones", math.huge)

task.wait(1) -- let the map settle
Clouds.BuildAll()

zonesFolder.ChildAdded:Connect(function(zone)
	task.wait(1)
	Clouds.BuildZone(zone)
end)
