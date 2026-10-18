-- Unicorn's look (from gaudrians/UnicornScript.lua, made in Claude Design). Preview: gaudrians/Unicorn.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.6,
	WalkSpeed = 6,
	C = {
		hoof = { 200, 180, 220 },
		horn = { 245, 205, 90 },
		mane = { 242, 166, 211 },
		mane2 = { 180, 150, 240 },
		white = { 251, 247, 255 },
	},
	Anim = { Leg = 0.5, Wag = 0.25 },
	Eyes = { node = "head", s = 0.05, side = true, x = 0.101, y = 0.08, z = 0.12 },
	Nodes = {
		{ "body", "root", 0, 0.46, 0 },
		{ "neck", "body", 0, 0.08, 0.24, rx = 0.4 },
		{ "head", "neck", 0, 0.28, 0.02, rx = -0.4 },
		{ "earL", "head", 0.07, 0.15, 0, m = true },
		{ "legFL", "root", 0.09, 0.38, 0.22, m = true },
		{ "legBL", "root", 0.09, 0.38, -0.22, m = true },
		{ "tail", "body", 0, 0.06, -0.29, rx = -0.2 },
		{ "tail2", "tail", 0, 0, -0.14, rx = -0.5 },
	},
	Parts = {
		{ "body", "white", 0.3, 0.28, 0.58, 0, 0, 0 },
		{ "neck", "white", 0.16, 0.3, 0.16, 0, 0.12, 0 },
		{ "neck", "mane", 0.06, 0.32, 0.12, 0, 0.14, -0.08 },
		{ "head", "white", 0.2, 0.2, 0.32, 0, 0.04, 0.08 },
		{ "head", "hoof", 0.18, 0.14, 0.08, 0, -0.01, 0.26 },
		{ "head", "mane2", 0.12, 0.06, 0.08, 0, 0.15, 0 },
		{ "head", "horn", 0.05, 0.18, 0.05, 0, 0.22, 0.1, 0.3, 0, 0 },
		{ "head", "horn", 0.03, 0.06, 0.03, 0, 0.33, 0.13, 0.3, 0, 0 },
		{ "earL", "white", 0.05, 0.08, 0.04, 0, 0, 0, m = true },
		{ "legFL", "white", 0.08, 0.34, 0.08, 0, -0.17, 0, m = true },
		{ "legFL", "hoof", 0.09, 0.05, 0.09, 0, -0.355, 0, m = true },
		{ "legBL", "white", 0.08, 0.34, 0.08, 0, -0.17, 0, m = true },
		{ "legBL", "hoof", 0.09, 0.05, 0.09, 0, -0.355, 0, m = true },
		{ "tail", "mane", 0.1, 0.1, 0.14, 0, 0, -0.07 },
		{ "tail2", "mane2", 0.1, 0.1, 0.18, 0, 0, -0.09 },
	},
}

SPEC.Name = "Unicorn"

return SPEC
