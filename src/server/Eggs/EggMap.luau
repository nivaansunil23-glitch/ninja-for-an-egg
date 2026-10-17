--!nonstrict
-- Finds the map folders the Studio map build provides:
--   Workspace.Map.Islands  one model per island
--   Workspace.Map.Pens     one plot model per player

local EggMap = {}

local function waitForChildQuietly(parent, name)
	local child = parent:FindFirstChild(name)
	while not child do
		parent.ChildAdded:Wait()
		child = parent:FindFirstChild(name)
	end
	return child
end

-- Yields until Workspace.Map[name] exists. Warns once if it takes a while.
function EggMap.WaitForFolder(name)
	local warned = false
	task.delay(10, function()
		local map = workspace:FindFirstChild("Map")
		if not (map and map:FindFirstChild(name)) and not warned then
			warned = true
			warn(`[Eggs] Still waiting for Workspace.Map.{name}. Egg systems that need it are paused.`)
		end
	end)
	local map = waitForChildQuietly(workspace, "Map")
	return waitForChildQuietly(map, name)
end

return EggMap
