-- Runs the day/night loop (lengths in Shared.Config.DayNightConfig) and puts
-- the phase on Workspace (IsNight, DayNightEndsAt) for everything else:
--   * Eggs/EggSpawner clears island eggs at night and refills them at day.
--   * Player/JumpPower gives everyone 0 jump at night.
--   * Training/TrainingService stops bouncing and gives no XP at night.
--   * Here: anyone holding a jetpack at night has it put back in their backpack.
--   * The client fades the lighting and shows the HUD timer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DayNightConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DayNightConfig"))
local JumpPower = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("JumpPower"))

local JETPACK_CHECK_SECONDS = 0.25

local function setPhase(night: boolean, seconds: number)
	Workspace:SetAttribute("DayNightEndsAt", Workspace:GetServerTimeNow() + seconds)
	Workspace:SetAttribute("IsNight", night)
	for _, player in Players:GetPlayers() do
		task.spawn(JumpPower.Refresh, player)
	end
end

task.spawn(function()
	while true do
		setPhase(false, DayNightConfig.DaySeconds)
		task.wait(DayNightConfig.DaySeconds)
		setPhase(true, DayNightConfig.NightSeconds)
		task.wait(DayNightConfig.NightSeconds)
	end
end)

-- No jetpack lift at night: put it away if someone holds it.
task.spawn(function()
	while true do
		task.wait(JETPACK_CHECK_SECONDS)
		if DayNightConfig.IsNight() then
			for _, player in Players:GetPlayers() do
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
		end
	end
end)
