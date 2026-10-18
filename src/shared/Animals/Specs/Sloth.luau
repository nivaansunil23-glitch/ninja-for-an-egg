-- Sloth's look (from gaudrians/SlothScript.lua, made in Claude Design). Preview: gaudrians/Sloth.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3,
	WalkSpeed = 1.2,
	C = {
		dark = { 60, 50, 40 },
		face = { 217, 203, 180 },
		fur = { 154, 134, 112 },
		stripe = { 120, 96, 74 },
	},
	Anim = { Bob = 0.01, Leg = 0.35, Stride = 0.3 },
	Eyes = { node = "head", s = 0.04, x = 0.065, y = 0.08, z = 0.184 },
	Nodes = {
		{ "body", "root", 0, 0.26, 0 },
		{ "head", "body", 0, 0.16, 0.26 },
		{ "legFL", "root", 0.15, 0.22, 0.18, m = true },
		{ "legBL", "root", 0.13, 0.22, -0.18, m = true },
	},
	Parts = {
		{ "body", "fur", 0.36, 0.3, 0.46, 0, 0.06, 0 },
		{ "head", "fur", 0.3, 0.26, 0.24, 0, 0.06, 0.04 },
		{ "head", "face", 0.22, 0.16, 0.02, 0, 0.05, 0.165 },
		{ "head", "stripe", 0.09, 0.045, 0.012, 0.065, 0.08, 0.177, 0, 0, -0.3, m = true },
		{ "head", "dark", 0.06, 0.04, 0.02, 0, 0.02, 0.18 },
		{ "legFL", "fur", 0.08, 0.24, 0.08, 0, -0.1, 0, m = true },
		{ "legFL", "dark", 0.09, 0.03, 0.1, 0, -0.21, 0.03, m = true },
		{ "legBL", "fur", 0.08, 0.24, 0.08, 0, -0.1, 0, m = true },
		{ "legBL", "dark", 0.09, 0.03, 0.1, 0, -0.21, 0.03, m = true },
	},
}

SPEC.Name = "Sloth"

return SPEC
