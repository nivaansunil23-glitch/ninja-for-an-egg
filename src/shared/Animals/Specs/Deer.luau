-- Deer's look (from gaudrians/DeerScript.lua, made in Claude Design). Preview: gaudrians/Deer.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.4,
	WalkSpeed = 7,
	C = {
		antler = { 226, 200, 150 },
		dark = { 70, 50, 38 },
		fur = { 176, 122, 74 },
		light = { 236, 214, 176 },
	},
	Anim = { Leg = 0.5, NeckSleep = 0.6, Wag = 0.5, WagSpeed = 6 },
	Eyes = { node = "head", s = 0.045, x = 0.07, y = 0.1, z = 0.162 },
	Nodes = {
		{ "body", "root", 0, 0.5, 0 },
		{ "neck", "body", 0, 0.1, 0.24, rx = 0.35 },
		{ "head", "neck", 0, 0.26, 0.02, rx = -0.35 },
		{ "earL", "head", 0.11, 0.12, -0.04, m = true, rz = -0.9 },
		{ "legFL", "root", 0.09, 0.4, 0.2, m = true },
		{ "legBL", "root", 0.09, 0.4, -0.2, m = true },
		{ "tail", "body", 0, 0.08, -0.28, rx = 0.8 },
	},
	Parts = {
		{ "body", "fur", 0.3, 0.26, 0.56, 0, 0, 0 },
		{ "body", "light", 0.26, 0.04, 0.4, 0, -0.13, 0 },
		{ "body", "light", 0.06, 0.012, 0.06, 0.08, 0.131, 0.1, m = true },
		{ "body", "light", 0.06, 0.012, 0.06, 0.06, 0.131, -0.12, m = true },
		{ "neck", "fur", 0.14, 0.3, 0.14, 0, 0.12, 0 },
		{ "head", "fur", 0.24, 0.22, 0.24, 0, 0.06, 0.04 },
		{ "head", "light", 0.16, 0.13, 0.16, 0, 0.01, 0.2 },
		{ "head", "dark", 0.06, 0.04, 0.02, 0, 0.05, 0.285 },
		{ "head", "antler", 0.03, 0.16, 0.03, 0.07, 0.25, -0.02, m = true },
		{ "head", "antler", 0.03, 0.03, 0.09, 0.07, 0.27, 0.02, m = true },
		{ "earL", "fur", 0.06, 0.16, 0.04, 0, 0.08, 0, m = true },
		{ "legFL", "fur", 0.07, 0.36, 0.07, 0, -0.18, 0, m = true },
		{ "legFL", "dark", 0.075, 0.05, 0.08, 0, -0.375, 0, m = true },
		{ "legBL", "fur", 0.07, 0.36, 0.07, 0, -0.18, 0, m = true },
		{ "legBL", "dark", 0.075, 0.05, 0.08, 0, -0.375, 0, m = true },
		{ "tail", "light", 0.08, 0.06, 0.1, 0, 0, -0.04 },
	},
}

SPEC.Name = "Deer"

return SPEC
