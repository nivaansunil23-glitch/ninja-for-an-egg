-- Fades the lighting between day and night (Workspace IsNight, set by the
-- server's World/DayNight). The day look is whatever Lighting is set to in the
-- place (the Cartoon Lighting settings); the night look is in
-- Shared.Config.DayNightConfig.Night. The clock always runs forward: through
-- sunset into midnight, then through sunrise back to the day time.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local DayNightConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("DayNightConfig"))

local NIGHT = DayNightConfig.Night
local PROPS = { "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "FogColor" }

local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
local dayClock = Lighting.ClockTime
local day = {}
for _, prop in PROPS do
	day[prop] = Lighting[prop]
end
local dayCorrection = correction and { Brightness = correction.Brightness, Saturation = correction.Saturation }
local nightCorrection = { Brightness = NIGHT.CorrectionBrightness, Saturation = NIGHT.CorrectionSaturation }

local function goalFor(night: boolean)
	local goal = {}
	for _, prop in PROPS do
		goal[prop] = if night then NIGHT[prop] else day[prop]
	end
	return goal
end

-- The clock as a number that only goes up, so tweens never run backwards.
local clock = Instance.new("NumberValue")
clock.Value = dayClock
clock.Changed:Connect(function(value)
	Lighting.ClockTime = value % 24
end)

local tweens = {}
local function apply(night: boolean, seconds: number)
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local from = clock.Value % 24
	local target = if night then NIGHT.ClockTime else dayClock
	local forward = (target - from) % 24
	clock.Value = from
	table.insert(tweens, TweenService:Create(clock, info, { Value = from + forward }))
	table.insert(tweens, TweenService:Create(Lighting, info, goalFor(night)))
	if correction and dayCorrection then
		table.insert(tweens, TweenService:Create(correction, info, if night then nightCorrection else dayCorrection))
	end
	for _, tween in tweens do
		tween:Play()
	end
end

Workspace:GetAttributeChangedSignal("IsNight"):Connect(function()
	apply(DayNightConfig.IsNight(), DayNightConfig.FadeSeconds)
end)
-- Joining at night: go straight to the night look.
if DayNightConfig.IsNight() then
	apply(true, 0)
end
