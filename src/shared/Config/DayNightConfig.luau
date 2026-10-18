-- Day/night cycle. The server (World/DayNight) runs the loop and puts the
-- phase on Workspace so every script can read it:
--   IsNight          true at night, false in the day
--   DayNightEndsAt   Workspace:GetServerTimeNow() when the phase switches
--
-- At night: every island's world eggs are cleared (fresh ones come back at
-- day), and nobody can jump (jump, trampoline bounces, launch pad, jetpack).

local Workspace = game:GetService("Workspace")

local DayNightConfig = {}

-- Placeholder lengths, in seconds. Change to taste.
DayNightConfig.DaySeconds = 8 * 60
DayNightConfig.NightSeconds = 2 * 60

-- How long the sky takes to fade between day and night.
DayNightConfig.FadeSeconds = 8

-- Night look. The day look is whatever Lighting is set to in the place
-- (the Cartoon Lighting settings), so it's never overwritten.
-- ClockTime fades forward through sunset to midnight, then on through sunrise.
DayNightConfig.Night = {
	ClockTime = 0,
	Brightness = 1,
	Ambient = Color3.fromRGB(110, 100, 170),
	OutdoorAmbient = Color3.fromRGB(80, 70, 140),
	ColorShift_Top = Color3.fromRGB(120, 130, 210),
	FogColor = Color3.fromRGB(45, 45, 100),
	-- ColorCorrectionEffect in Lighting (if there is one)
	CorrectionBrightness = -0.02,
	CorrectionSaturation = 0.05,
}

function DayNightConfig.IsNight(): boolean
	return Workspace:GetAttribute("IsNight") == true
end

-- Seconds until the next switch (0 if unknown).
function DayNightConfig.SecondsLeft(): number
	local endsAt = Workspace:GetAttribute("DayNightEndsAt")
	if type(endsAt) ~= "number" then
		return 0
	end
	return math.max(0, endsAt - Workspace:GetServerTimeNow())
end

return DayNightConfig
