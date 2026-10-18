-- Jaguar's look (from gaudrians/JaguarScript.lua, made in Claude Design). Preview: gaudrians/Jaguar.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.4,
	WalkSpeed = 6,
	C = {
		cream = { 244, 226, 190 },
		gold = { 227, 163, 62 },
		spot = { 58, 42, 30 },
	},
	Anim = { Leg = 0.55, Wag = 0.35 },
	Eyes = { node = "head", s = 0.045, x = 0.08, y = 0.1, z = 0.202 },
	Nodes = {
		{ "body", "root", 0, 0.3, 0 },
		{ "head", "body", 0, 0.18, 0.34 },
		{ "earL", "head", 0.11, 0.19, 0.04, m = true },
		{ "legFL", "root", 0.1, 0.24, 0.24, m = true },
		{ "legBL", "root", 0.1, 0.24, -0.24, m = true },
		{ "tail", "body", 0, 0.1, -0.34, rx = 0.2 },
	},
	Parts = {
		{ "body", "gold", 0.32, 0.28, 0.66, 0, 0.04, 0 },
		{ "body", "cream", 0.26, 0.04, 0.5, 0, -0.1, 0.02 },
		{ "body", "spot", 0.06, 0.012, 0.06, 0.07, 0.186, 0.2, m = true },
		{ "body", "spot", 0.06, 0.012, 0.06, 0, 0.186, 0.04 },
		{ "body", "spot", 0.06, 0.012, 0.06, 0.08, 0.186, -0.12, m = true },
		{ "body", "spot", 0.06, 0.012, 0.06, 0, 0.186, -0.26 },
		{ "body", "spot", 0.012, 0.06, 0.06, 0.161, 0.06, 0.12, m = true },
		{ "body", "spot", 0.012, 0.06, 0.06, 0.161, 0.02, -0.06, m = true },
		{ "body", "spot", 0.012, 0.06, 0.06, 0.161, 0.07, -0.22, m = true },
		{ "head", "gold", 0.32, 0.26, 0.28, 0, 0.06, 0.06 },
		{ "head", "cream", 0.16, 0.1, 0.08, 0, 0, 0.22 },
		{ "head", "spot", 0.05, 0.035, 0.02, 0, 0.04, 0.265 },
		{ "earL", "gold", 0.08, 0.07, 0.05, 0, 0, 0, m = true },
		{ "legFL", "gold", 0.09, 0.24, 0.09, 0, -0.12, 0, m = true },
		{ "legFL", "cream", 0.1, 0.04, 0.11, 0, -0.22, 0.01, m = true },
		{ "legBL", "gold", 0.09, 0.24, 0.09, 0, -0.12, 0, m = true },
		{ "legBL", "cream", 0.1, 0.04, 0.11, 0, -0.22, 0.01, m = true },
		{ "tail", "gold", 0.07, 0.07, 0.36, 0, 0, -0.18 },
		{ "tail", "spot", 0.072, 0.072, 0.08, 0, 0, -0.34 },
	},
}

SPEC.Name = "Jaguar"

return SPEC
