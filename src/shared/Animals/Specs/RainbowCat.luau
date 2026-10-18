-- RainbowCat's look (from gaudrians/RainbowCatScript.lua, made in Claude Design). Preview: gaudrians/RainbowCat.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 5,
	C = {
		blue = { 127, 201, 242 },
		green = { 120, 210, 130 },
		orange = { 245, 170, 80 },
		pink = { 242, 138, 178 },
		purple = { 170, 130, 230 },
		white = { 255, 250, 252 },
		yellow = { 245, 225, 90 },
	},
	Anim = { Wag = 0.3 },
	Eyes = { node = "head", s = 0.05, x = 0.08, y = 0.1, z = 0.202 },
	Nodes = {
		{ "body", "root", 0, 0.24, 0 },
		{ "head", "body", 0, 0.18, 0.22 },
		{ "earL", "head", 0.11, 0.22, 0.06, m = true },
		{ "legFL", "root", 0.09, 0.18, 0.16, m = true },
		{ "legBL", "root", 0.09, 0.18, -0.16, m = true },
		{ "tail", "body", 0, 0.1, -0.22, rx = 1 },
		{ "tail2", "tail", 0, 0, -0.2, rx = -0.6 },
	},
	Parts = {
		{ "body", "pink", 0.3, 0.24, 0.46, 0, 0.04, 0 },
		{ "body", "orange", 0.31, 0.25, 0.06, 0, 0.04, 0.14 },
		{ "body", "yellow", 0.31, 0.25, 0.06, 0, 0.04, 0.04 },
		{ "body", "green", 0.31, 0.25, 0.06, 0, 0.04, -0.06 },
		{ "body", "blue", 0.31, 0.25, 0.06, 0, 0.04, -0.16 },
		{ "head", "pink", 0.34, 0.28, 0.28, 0, 0.08, 0.06 },
		{ "head", "white", 0.14, 0.08, 0.04, 0, 0.02, 0.21 },
		{ "head", "purple", 0.04, 0.03, 0.02, 0, 0.05, 0.235 },
		{ "earL", "purple", 0.1, 0.1, 0.06, 0, 0.04, 0, m = true },
		{ "legFL", "pink", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "legFL", "white", 0.09, 0.04, 0.1, 0, -0.16, 0.01, m = true },
		{ "legBL", "pink", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "legBL", "white", 0.09, 0.04, 0.1, 0, -0.16, 0.01, m = true },
		{ "tail", "purple", 0.06, 0.06, 0.2, 0, 0, -0.1 },
		{ "tail2", "blue", 0.06, 0.06, 0.16, 0, 0, -0.08 },
	},
}

SPEC.Name = "RainbowCat"

return SPEC
