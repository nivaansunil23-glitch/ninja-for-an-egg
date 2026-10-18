-- Drop Egg button (client UI/DropEggButton): puts the egg you're carrying down
-- on the ground under you. Dropped eggs disappear after a while like any other
-- dropped egg (EggCarry).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local EggCarry = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Eggs"):WaitForChild("EggCarry"))

local lastDrop = {}

Net.Event("DropEgg").OnServerEvent:Connect(function(player)
	local now = os.clock()
	if lastDrop[player] and now - lastDrop[player] < 0.5 then
		return
	end
	lastDrop[player] = now
	EggCarry.DropCarried(player)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastDrop[player] = nil
end)
