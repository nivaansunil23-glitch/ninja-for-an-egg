-- Fox's look (from gaudrians/FoxScript.lua, made in Claude Design). Preview: gaudrians/Fox.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.2,
	WalkSpeed = 6,
	C = {
		dark = { 58, 40, 34 },
		fur = { 232, 120, 44 },
		white = { 248, 242, 232 },
	},
	Anim = { Wag = 0.25 },
	Eyes = { node = "head", s = 0.05, x = 0.08, y = 0.12, z = 0.232 },
	Nodes = {
		{ "body", "root", 0, 0.3, 0 },
		{ "head", "body", 0, 0.2, 0.26 },
		{ "earL", "head", 0.1, 0.22, 0.06, m = true, rz = -0.2 },
		{ "legFL", "root", 0.1, 0.24, 0.2, m = true },
		{ "legBL", "root", 0.1, 0.24, -0.2, m = true },
		{ "tail", "body", 0, 0.1, -0.28, rx = 0.5 },
	},
	Parts = {
		{ "body", "fur", 0.32, 0.26, 0.56, 0, 0.05, 0 },
		{ "body", "white", 0.26, 0.18, 0.06, 0, 0.02, 0.29 },
		{ "head", "fur", 0.36, 0.3, 0.3, 0, 0.08, 0.08 },
		{ "head", "white", 0.37, 0.1, 0.22, 0, -0.04, 0.12 },
		{ "head", "white", 0.16, 0.1, 0.14, 0, 0, 0.27 },
		{ "head", "dark", 0.06, 0.05, 0.03, 0, 0.04, 0.35 },
		{ "earL", "fur", 0.11, 0.16, 0.05, 0, 0.07, 0, m = true },
		{ "earL", "dark", 0.112, 0.05, 0.052, 0, 0.13, 0, m = true },
		{ "legFL", "fur", 0.08, 0.18, 0.08, 0, -0.08, 0, m = true },
		{ "legFL", "dark", 0.09, 0.07, 0.1, 0, -0.2, 0.01, m = true },
		{ "legBL", "fur", 0.08, 0.18, 0.08, 0, -0.08, 0, m = true },
		{ "legBL", "dark", 0.09, 0.07, 0.1, 0, -0.2, 0.01, m = true },
		{ "tail", "fur", 0.16, 0.16, 0.34, 0, 0, -0.17 },
		{ "tail", "white", 0.165, 0.165, 0.1, 0, 0, -0.37 },
	},
}

SPEC.Name = "Fox"

return SPEC
