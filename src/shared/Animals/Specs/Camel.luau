-- Camel's look (from gaudrians/CamelScript.lua, made in Claude Design). Preview: gaudrians/Camel.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 4.2,
	WalkSpeed = 5,
	C = {
		dark = { 110, 80, 50 },
		fur = { 201, 154, 94 },
		light = { 232, 207, 163 },
	},
	Anim = { Bob = 0.03, Leg = 0.45, Wag = 0.2 },
	Eyes = { node = "head", s = 0.04, x = 0.06, y = 0.09, z = 0.232 },
	Nodes = {
		{ "body", "root", 0, 0.56, 0 },
		{ "neck", "body", 0, 0.04, 0.28, rx = 0.6 },
		{ "head", "neck", 0, 0.3, 0, rx = -0.6 },
		{ "earL", "head", 0.08, 0.12, -0.04, m = true },
		{ "legFL", "root", 0.1, 0.46, 0.22, m = true },
		{ "legBL", "root", 0.1, 0.46, -0.22, m = true },
		{ "tail", "body", 0, 0.06, -0.3, rx = -0.5 },
	},
	Parts = {
		{ "body", "fur", 0.32, 0.3, 0.6, 0, 0, 0 },
		{ "body", "fur", 0.24, 0.18, 0.26, 0, 0.22, -0.02 },
		{ "body", "light", 0.26, 0.04, 0.4, 0, -0.15, 0 },
		{ "neck", "fur", 0.13, 0.32, 0.13, 0, 0.14, 0 },
		{ "head", "fur", 0.2, 0.18, 0.3, 0, 0.04, 0.08 },
		{ "head", "light", 0.16, 0.13, 0.12, 0, 0, 0.24 },
		{ "head", "dark", 0.08, 0.02, 0.02, 0, 0.04, 0.3 },
		{ "earL", "fur", 0.04, 0.06, 0.04, 0, 0, 0, m = true },
		{ "legFL", "fur", 0.08, 0.42, 0.08, 0, -0.21, 0, m = true },
		{ "legFL", "light", 0.1, 0.04, 0.12, 0, -0.44, 0.01, m = true },
		{ "legBL", "fur", 0.08, 0.42, 0.08, 0, -0.21, 0, m = true },
		{ "legBL", "light", 0.1, 0.04, 0.12, 0, -0.44, 0.01, m = true },
		{ "tail", "dark", 0.04, 0.04, 0.16, 0, 0, -0.08 },
	},
}

SPEC.Name = "Camel"

return SPEC
