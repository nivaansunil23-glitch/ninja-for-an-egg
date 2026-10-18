-- PolarBear's look (from gaudrians/PolarBearScript.lua, made in Claude Design). Preview: gaudrians/PolarBear.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.8,
	WalkSpeed = 5,
	C = {
		dark = { 40, 40, 44 },
		fur = { 245, 242, 234 },
		shade = { 215, 210, 196 },
	},
	Anim = { Bob = 0.03, Leg = 0.5 },
	Eyes = { node = "head", s = 0.045, x = 0.08, y = 0.11, z = 0.212 },
	Nodes = {
		{ "body", "root", 0, 0.3, 0 },
		{ "head", "body", 0, 0.14, 0.34 },
		{ "earL", "head", 0.12, 0.2, 0.04, m = true },
		{ "legFL", "root", 0.14, 0.24, 0.22, m = true },
		{ "legBL", "root", 0.14, 0.24, -0.22, m = true },
	},
	Parts = {
		{ "body", "fur", 0.48, 0.38, 0.68, 0, 0.06, 0, r = 0.35 },
		{ "body", "fur", 0.4, 0.12, 0.24, 0, 0.22, 0.16, r = 0.4 },
		{ "body", "fur", 0.44, 0.3, 0.24, 0, 0.04, -0.26, r = 0.4 },
		{ "body", "fur", 0.1, 0.08, 0.06, 0, 0.12, -0.36, r = 0.3 },
		{ "head", "fur", 0.34, 0.28, 0.3, 0, 0.06, 0.06, r = 0.35 },
		{ "head", "shade", 0.2, 0.14, 0.14, 0, -0.01, 0.24, r = 0.35 },
		{ "head", "dark", 0.08, 0.05, 0.03, 0, 0.04, 0.31, r = 0.3 },
		{ "earL", "fur", 0.09, 0.08, 0.06, 0, 0, 0, m = true, r = 0.3 },
		{ "legFL", "fur", 0.15, 0.24, 0.15, 0, -0.12, 0, m = true, r = 0.3 },
		{ "legFL", "shade", 0.16, 0.05, 0.18, 0, -0.215, 0.01, m = true, r = 0.3 },
		{ "legBL", "fur", 0.15, 0.24, 0.15, 0, -0.12, 0, m = true, r = 0.3 },
		{ "legBL", "shade", 0.16, 0.05, 0.18, 0, -0.215, 0.01, m = true, r = 0.3 },
	},
}

SPEC.Name = "PolarBear"

return SPEC
