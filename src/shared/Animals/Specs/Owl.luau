-- Owl's look (from gaudrians/OwlScript.lua, made in Claude Design). Preview: gaudrians/Owl.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 2.8,
	WalkSpeed = 4,
	C = {
		beak = { 245, 166, 35 },
		fur = { 138, 106, 74 },
		light = { 240, 226, 196 },
		tan = { 232, 199, 122 },
	},
	Anim = { HeadSleep = 0.2, Leg = 0.5 },
	Eyes = { node = "head", s = 0.075, x = 0.09, y = 0.18, z = 0.202 },
	Nodes = {
		{ "body", "root", 0, 0.14, 0 },
		{ "head", "body", 0, 0.42, 0.02 },
		{ "earL", "head", 0.15, 0.33, 0, m = true, rz = -0.3 },
		{ "wingL", "body", 0.22, 0.38, -0.02, m = true },
		{ "legL", "root", 0.09, 0.14, 0.03, m = true },
		{ "tail", "body", 0, 0.1, -0.19, rx = 0.4 },
	},
	Parts = {
		{ "body", "fur", 0.42, 0.42, 0.38, 0, 0.2, 0 },
		{ "body", "light", 0.3, 0.3, 0.03, 0, 0.17, 0.19 },
		{ "head", "fur", 0.46, 0.34, 0.38, 0, 0.17, 0 },
		{ "head", "tan", 0.38, 0.24, 0.02, 0, 0.16, 0.19 },
		{ "head", "beak", 0.07, 0.08, 0.05, 0, 0.09, 0.215 },
		{ "earL", "fur", 0.08, 0.1, 0.08, 0, 0.04, 0, m = true },
		{ "wingL", "fur", 0.05, 0.32, 0.3, 0.02, -0.15, 0, m = true },
		{ "legL", "beak", 0.05, 0.1, 0.05, 0, -0.07, 0, m = true },
		{ "legL", "beak", 0.1, 0.035, 0.12, 0, -0.12, 0.03, m = true },
		{ "tail", "fur", 0.22, 0.06, 0.12, 0, 0, -0.06 },
	},
}

SPEC.Name = "Owl"

return SPEC
