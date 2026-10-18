-- Flamingo's look (from gaudrians/FlamingoScript.lua, made in Claude Design). Preview: gaudrians/Flamingo.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 3.6,
	WalkSpeed = 4,
	C = {
		beak = { 250, 236, 220 },
		black = { 40, 36, 40 },
		legs = { 232, 110, 140 },
		light = { 249, 194, 211 },
		pink = { 240, 127, 166 },
	},
	Anim = { HeadSleep = 0.5, Leg = 0.45, LegFold = 0, NeckSleep = 1.2, SleepDrop = 0, Stride = 0.6 },
	Eyes = { node = "head", s = 0.03, x = 0.04, y = 0.07, z = 0.102 },
	Nodes = {
		{ "legL", "root", 0.05, 0.5, 0.02, m = true },
		{ "body", "root", 0, 0.5, 0 },
		{ "neck", "body", 0, 0.14, 0.14, rx = 0.1 },
		{ "head", "neck", 0, 0.3, 0.02, rx = -0.1 },
		{ "wingL", "body", 0.12, 0.16, -0.02, m = true },
	},
	Parts = {
		{ "legL", "legs", 0.03, 0.5, 0.03, 0, -0.25, 0, m = true },
		{ "legL", "legs", 0.08, 0.02, 0.09, 0, -0.49, 0.03, m = true },
		{ "body", "pink", 0.24, 0.22, 0.36, 0, 0.08, -0.02 },
		{ "body", "light", 0.16, 0.1, 0.12, 0, 0.12, -0.24, 0.4, 0, 0 },
		{ "neck", "pink", 0.07, 0.3, 0.07, 0, 0.15, 0 },
		{ "head", "pink", 0.14, 0.12, 0.16, 0, 0.04, 0.02 },
		{ "head", "beak", 0.06, 0.05, 0.08, 0, 0.02, 0.13 },
		{ "head", "black", 0.06, 0.07, 0.05, 0, -0.01, 0.19, 0.5, 0, 0 },
		{ "wingL", "light", 0.04, 0.16, 0.28, 0.01, -0.06, 0, m = true },
	},
}

SPEC.Name = "Flamingo"

return SPEC
