-- Bunny's look (from gaudrians/BunnyScript.lua, made in Claude Design). Preview: gaudrians/Bunny.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 5,
	C = {
		fur = { 242, 238, 230 },
		nose = { 232, 104, 140 },
		paw = { 222, 214, 202 },
		pink = { 246, 160, 182 },
	},
	Anim = { Bob = 0.07, Leg = 0.8, Stride = 0.45 },
	Eyes = { node = "head", s = 0.055, x = 0.08, y = 0.13, z = 0.212 },
	Nodes = {
		{ "body", "root", 0, 0.22, 0 },
		{ "head", "body", 0, 0.18, 0.18 },
		{ "earL", "head", 0.08, 0.26, -0.02, m = true, rz = -0.12 },
		{ "legFL", "root", 0.1, 0.12, 0.14, m = true },
		{ "legBL", "root", 0.11, 0.14, -0.13, m = true },
		{ "tail", "body", 0, 0.14, -0.24 },
	},
	Parts = {
		{ "body", "fur", 0.36, 0.3, 0.46, 0, 0.08, 0 },
		{ "head", "fur", 0.34, 0.32, 0.3, 0, 0.12, 0.06 },
		{ "head", "paw", 0.16, 0.08, 0.04, 0, 0.04, 0.22 },
		{ "head", "nose", 0.05, 0.035, 0.02, 0, 0.085, 0.24 },
		{ "earL", "fur", 0.08, 0.28, 0.05, 0, 0.13, 0, m = true },
		{ "earL", "pink", 0.045, 0.2, 0.012, 0, 0.14, 0.028, m = true },
		{ "legFL", "paw", 0.09, 0.12, 0.09, 0, -0.06, 0, m = true },
		{ "legBL", "fur", 0.12, 0.12, 0.16, 0, -0.07, 0, m = true },
		{ "legBL", "paw", 0.11, 0.04, 0.2, 0, -0.12, 0.04, m = true },
		{ "tail", "fur", 0.13, 0.13, 0.1, 0, 0, -0.03 },
	},
}

SPEC.Name = "Bunny"

return SPEC
