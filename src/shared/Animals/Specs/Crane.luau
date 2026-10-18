-- Crane's look (from gaudrians/CraneScript.lua, made in Claude Design). Preview: gaudrians/Crane.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 3.6,
	WalkSpeed = 4,
	C = {
		beak = { 210, 190, 120 },
		black = { 38, 38, 40 },
		legs = { 70, 70, 70 },
		red = { 200, 49, 46 },
		white = { 246, 246, 244 },
	},
	Anim = { HeadSleep = 0.5, Leg = 0.45, LegFold = 0, NeckSleep = 1.2, SleepDrop = 0, Stride = 0.6 },
	Eyes = { node = "head", s = 0.028, x = 0.035, y = 0.06, z = 0.092 },
	Nodes = {
		{ "legL", "root", 0.05, 0.46, 0.02, m = true },
		{ "body", "root", 0, 0.46, 0 },
		{ "neck", "body", 0, 0.14, 0.16, rx = 0.15 },
		{ "head", "neck", 0, 0.3, 0.02, rx = -0.15 },
		{ "wingL", "body", 0.12, 0.16, -0.02, m = true },
	},
	Parts = {
		{ "legL", "legs", 0.03, 0.46, 0.03, 0, -0.23, 0, m = true },
		{ "legL", "legs", 0.08, 0.02, 0.09, 0, -0.45, 0.03, m = true },
		{ "body", "white", 0.24, 0.22, 0.4, 0, 0.08, -0.02 },
		{ "body", "black", 0.2, 0.12, 0.14, 0, 0.1, -0.26, 0.3, 0, 0 },
		{ "neck", "black", 0.07, 0.3, 0.07, 0, 0.15, 0 },
		{ "head", "white", 0.12, 0.1, 0.14, 0, 0.04, 0.02 },
		{ "head", "red", 0.122, 0.03, 0.08, 0, 0.09, 0 },
		{ "head", "beak", 0.04, 0.04, 0.16, 0, 0.02, 0.16 },
		{ "wingL", "white", 0.04, 0.16, 0.32, 0.01, -0.06, 0, m = true },
		{ "wingL", "black", 0.042, 0.06, 0.1, 0.01, -0.1, -0.16, m = true },
	},
}

SPEC.Name = "Crane"

return SPEC
