-- RedPanda's look (from gaudrians/RedPandaScript.lua, made in Claude Design). Preview: gaudrians/RedPanda.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 5,
	C = {
		dark = { 58, 42, 36 },
		red = { 194, 80, 42 },
		white = { 246, 240, 230 },
	},
	Anim = { Wag = 0.3 },
	Eyes = { node = "head", s = 0.045, x = 0.08, y = 0.1, z = 0.208 },
	Nodes = {
		{ "body", "root", 0, 0.24, 0 },
		{ "head", "body", 0, 0.18, 0.24 },
		{ "earL", "head", 0.13, 0.24, 0.04, m = true },
		{ "legFL", "root", 0.1, 0.18, 0.16, m = true },
		{ "legBL", "root", 0.1, 0.18, -0.16, m = true },
		{ "tail", "body", 0, 0.08, -0.24, rx = 0.4 },
	},
	Parts = {
		{ "body", "red", 0.3, 0.24, 0.46, 0, 0.04, 0 },
		{ "head", "red", 0.36, 0.28, 0.28, 0, 0.08, 0.06 },
		{ "head", "white", 0.16, 0.1, 0.06, 0, 0.02, 0.22 },
		{ "head", "dark", 0.05, 0.035, 0.02, 0, 0.055, 0.255 },
		{ "head", "white", 0.06, 0.08, 0.012, 0.14, 0.04, 0.206, m = true },
		{ "head", "white", 0.06, 0.03, 0.012, 0.08, 0.17, 0.206, m = true },
		{ "earL", "red", 0.1, 0.1, 0.05, 0, 0, 0, m = true },
		{ "earL", "white", 0.06, 0.06, 0.012, 0, 0, 0.028, m = true },
		{ "legFL", "dark", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "legBL", "dark", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "tail", "red", 0.15, 0.15, 0.4, 0, 0, -0.2 },
		{ "tail", "dark", 0.152, 0.152, 0.06, 0, 0, -0.14 },
		{ "tail", "dark", 0.152, 0.152, 0.06, 0, 0, -0.3 },
	},
}

SPEC.Name = "RedPanda"

return SPEC
