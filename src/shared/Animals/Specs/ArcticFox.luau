-- ArcticFox's look (from gaudrians/ArcticFoxScript.lua, made in Claude Design). Preview: gaudrians/ArcticFox.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.2,
	WalkSpeed = 6,
	C = {
		dark = { 50, 55, 62 },
		fur = { 243, 245, 247 },
		shade = { 185, 199, 211 },
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
		{ "body", "fur", 0.34, 0.28, 0.56, 0, 0.05, 0, r = 0.35 },
		{ "body", "fur", 0.32, 0.24, 0.12, 0, 0.02, 0.27, r = 0.4 },
		{ "head", "fur", 0.36, 0.3, 0.3, 0, 0.08, 0.08, r = 0.35 },
		{ "head", "fur", 0.42, 0.12, 0.2, 0, -0.02, 0.08, r = 0.4 },
		{ "head", "fur", 0.16, 0.1, 0.14, 0, 0, 0.27, r = 0.3 },
		{ "head", "dark", 0.06, 0.05, 0.03, 0, 0.04, 0.35, r = 0.2 },
		{ "earL", "fur", 0.1, 0.12, 0.05, 0, 0.05, 0, m = true, r = 0.2 },
		{ "earL", "shade", 0.06, 0.08, 0.012, 0, 0.05, 0.028, m = true },
		{ "legFL", "fur", 0.08, 0.18, 0.08, 0, -0.08, 0, m = true, r = 0.3 },
		{ "legFL", "shade", 0.09, 0.07, 0.1, 0, -0.2, 0.01, m = true, r = 0.3 },
		{ "legBL", "fur", 0.08, 0.18, 0.08, 0, -0.08, 0, m = true, r = 0.3 },
		{ "legBL", "shade", 0.09, 0.07, 0.1, 0, -0.2, 0.01, m = true, r = 0.3 },
		{ "tail", "fur", 0.22, 0.22, 0.38, 0, 0, -0.19, r = 0.4 },
		{ "tail", "shade", 0.225, 0.225, 0.1, 0, 0, -0.34, r = 0.4 },
	},
}

SPEC.Name = "ArcticFox"

return SPEC
