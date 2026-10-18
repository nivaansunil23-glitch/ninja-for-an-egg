-- Squirrel's look (from gaudrians/SquirrelScript.lua, made in Claude Design). Preview: gaudrians/Squirrel.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 6,
	C = {
		cream = { 244, 224, 196 },
		dark = { 60, 40, 30 },
		fur = { 194, 96, 46 },
		light = { 232, 168, 107 },
	},
	Anim = { Bob = 0.06, Leg = 0.8, Stride = 0.5, Wag = 0.2, WagSpeed = 5 },
	Eyes = { node = "head", s = 0.05, x = 0.07, y = 0.13, z = 0.172 },
	Nodes = {
		{ "body", "root", 0, 0.2, 0 },
		{ "head", "body", 0, 0.2, 0.16 },
		{ "earL", "head", 0.08, 0.22, 0, m = true },
		{ "legFL", "root", 0.07, 0.12, 0.12, m = true },
		{ "legBL", "root", 0.09, 0.14, -0.1, m = true },
		{ "tail", "body", 0, 0.04, -0.18, rx = 1.1 },
		{ "tail2", "tail", 0, 0, -0.28, rx = -1 },
	},
	Parts = {
		{ "body", "fur", 0.26, 0.26, 0.36, 0, 0.06, 0 },
		{ "body", "cream", 0.18, 0.18, 0.03, 0, 0.05, 0.18 },
		{ "head", "fur", 0.28, 0.26, 0.26, 0, 0.1, 0.04 },
		{ "head", "cream", 0.12, 0.07, 0.04, 0, 0.04, 0.18 },
		{ "head", "dark", 0.04, 0.03, 0.02, 0, 0.075, 0.2 },
		{ "earL", "fur", 0.06, 0.1, 0.04, 0, 0.04, 0, m = true },
		{ "legFL", "fur", 0.06, 0.12, 0.07, 0, -0.06, 0, m = true },
		{ "legBL", "fur", 0.09, 0.13, 0.14, 0, -0.07, 0.02, m = true },
		{ "tail", "light", 0.2, 0.2, 0.3, 0, 0, -0.14 },
		{ "tail2", "fur", 0.24, 0.24, 0.22, 0, 0, -0.1 },
	},
}

SPEC.Name = "Squirrel"

return SPEC
