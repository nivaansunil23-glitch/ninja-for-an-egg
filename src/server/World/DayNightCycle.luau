-- Runs the day/night loop (lengths in Shared.Config.DayNightConfig) and puts
-- the phase on Workspace (IsNight, DayNightEndsAt) for everything else:
--   * Eggs/EggSpawner clears island eggs at night and refills them at day.
--   * Player/JumpPower gives everyone 0 jump at night.
--   * Training/TrainingService stops bouncing and gives no XP at night.
--   * Here: anyone holding a jetpack at night has it put back in their backpack.
--   * The client fades the lighting and shows the HUD timer.
-- Started by World/DayNight. The admin panel calls SetPhase / Skip.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DayNightConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DayNightConfig"))
local JumpPower = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("JumpPower"))

local CHECK_SECONDS = 0.25

local DayNightCycle = {}

local started = false

-- Switches to day or night now, with a full-length phase from here.
function DayNightCycle.SetPhase(night: boolean)
	local seconds = if night then DayNightConfig.NightSeconds else DayNightConfig.DaySeconds
	Workspace:SetAttribute("DayNightEndsAt", Workspace:GetServerTimeNow() + seconds)
	Workspace:SetAttribute("IsNight", night)
	for _, player in Players:GetPlayers() do
		task.spawn(JumpPower.Refresh, player)
	end
end

-- Jumps straight to the next phase.
function DayNightCycle.Skip()
	DayNightCycle.SetPhase(not DayNightConfig.IsNight())
end

-- No jetpack lift at night: put it away if someone holds it.
local function putAwayJetpacks()
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

function DayNightCycle.Start()
	if started then
		return
	end
	started = true
	DayNightCycle.SetPhase(false)
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			if DayNightConfig.SecondsLeft() <= 0 then
				DayNightCycle.Skip()
			end
			if DayNightConfig.IsNight() then
				putAwayJetpacks()
			end
		end
	end)
end

return DayNightCycle
