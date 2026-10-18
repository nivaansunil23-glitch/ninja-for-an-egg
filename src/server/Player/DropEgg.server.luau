-- Drop Egg button (client UI/DropEggButton): puts the egg you're carrying down
-- on the ground under you. Dropped eggs disappear after a while like any other
-- dropped egg (EggCarry). Inside your own pen the button is "Place Egg": the
-- egg goes into the pen right where you stand and starts growing (PenService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local EggRemotes = require(ReplicatedStorage.Shared:WaitForChild("EggRemotes"))
local Eggs = ServerScriptService:WaitForChild("Server"):WaitForChild("Eggs")
local EggCarry = require(Eggs:WaitForChild("EggCarry"))
local PenService = require(Eggs:WaitForChild("PenService"))

local lastDrop = {}

Net.Event("DropEgg").OnServerEvent:Connect(function(player)
	local now = os.clock()
	if lastDrop[player] and now - lastDrop[player] < 0.5 then
		return
	end
	lastDrop[player] = now
	local placed, reason = PenService.PlaceHere(player)
	if placed == "notInPen" then
		EggCarry.DropCarried(player)
	elseif not placed and reason then
		EggRemotes.EggNotify:FireClient(player, "Info", { Text = reason })
	end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastDrop[player] = nil
end)
