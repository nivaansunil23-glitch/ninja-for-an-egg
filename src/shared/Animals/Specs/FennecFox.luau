-- FennecFox's look (from gaudrians/FennecFoxScript.lua, made in Claude Design). Preview: gaudrians/FennecFox.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 6,
	C = {
		cream = { 246, 233, 211 },
		dark = { 70, 50, 40 },
		fur = { 232, 195, 143 },
		pink = { 240, 190, 170 },
	},
	Anim = { Wag = 0.25 },
	Eyes = { node = "head", s = 0.055, x = 0.08, y = 0.1, z = 0.232 },
	Nodes = {
		{ "body", "root", 0, 0.26, 0 },
		{ "head", "body", 0, 0.18, 0.22 },
		{ "earL", "head", 0.1, 0.2, 0.06, m = true, rz = -0.35 },
		{ "legFL", "root", 0.09, 0.2, 0.16, m = true },
		{ "legBL", "root", 0.09, 0.2, -0.16, m = true },
		{ "tail", "body", 0, 0.06, -0.24, rx = 0.3 },
	},
	Parts = {
		{ "body", "fur", 0.28, 0.22, 0.46, 0, 0.04, 0 },
		{ "body", "cream", 0.22, 0.16, 0.05, 0, 0.02, 0.23 },
		{ "head", "fur", 0.34, 0.28, 0.3, 0, 0.08, 0.08 },
		{ "head", "cream", 0.14, 0.09, 0.12, 0, -0.01, 0.27 },
		{ "head", "dark", 0.05, 0.04, 0.03, 0, 0.03, 0.34 },
		{ "earL", "fur", 0.14, 0.28, 0.05, 0, 0.12, 0, m = true },
		{ "earL", "pink", 0.09, 0.2, 0.012, 0, 0.12, 0.028, m = true },
		{ "legFL", "fur", 0.07, 0.2, 0.07, 0, -0.1, 0, m = true },
		{ "legBL", "fur", 0.07, 0.2, 0.07, 0, -0.1, 0, m = true },
		{ "tail", "fur", 0.14, 0.14, 0.3, 0, 0, -0.15 },
		{ "tail", "dark", 0.145, 0.145, 0.07, 0, 0, -0.3 },
	},
}

SPEC.Name = "FennecFox"

return SPEC
