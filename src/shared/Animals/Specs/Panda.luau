-- Panda's look (from gaudrians/PandaScript.lua, made in Claude Design). Preview: gaudrians/Panda.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.4,
	WalkSpeed = 4,
	C = {
		black = { 43, 43, 43 },
		white = { 244, 244, 242 },
	},
	Anim = { Bob = 0.03, Leg = 0.5 },
	Eyes = { c = { 255, 255, 255 }, node = "head", s = 0.05, x = 0.1, y = 0.15, z = 0.244 },
	Nodes = {
		{ "body", "root", 0, 0.3, 0 },
		{ "head", "body", 0, 0.2, 0.3 },
		{ "earL", "head", 0.15, 0.28, 0, m = true },
		{ "legFL", "root", 0.13, 0.2, 0.18, m = true },
		{ "legBL", "root", 0.13, 0.2, -0.18, m = true },
		{ "tail", "body", 0, 0.1, -0.3 },
	},
	Parts = {
		{ "body", "white", 0.46, 0.36, 0.6, 0, 0.06, 0 },
		{ "body", "black", 0.47, 0.37, 0.18, 0, 0.06, 0.16 },
		{ "head", "white", 0.42, 0.36, 0.34, 0, 0.12, 0.06 },
		{ "head", "white", 0.18, 0.12, 0.06, 0, 0.04, 0.25 },
		{ "head", "black", 0.07, 0.04, 0.02, 0, 0.075, 0.285 },
		{ "head", "black", 0.11, 0.12, 0.012, 0.1, 0.15, 0.236, 0, 0, -0.3, m = true },
		{ "earL", "black", 0.11, 0.1, 0.06, 0, 0, 0, m = true },
		{ "legFL", "black", 0.14, 0.22, 0.14, 0, -0.1, 0, m = true },
		{ "legBL", "black", 0.14, 0.22, 0.14, 0, -0.1, 0, m = true },
		{ "tail", "white", 0.1, 0.08, 0.06, 0, 0, 0 },
	},
}

SPEC.Name = "Panda"

return SPEC
