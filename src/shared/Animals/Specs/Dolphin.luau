-- Dolphin's look (from gaudrians/DolphinScript.lua, made in Claude Design). Preview: gaudrians/Dolphin.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "swim",
	Scale = 3.4,
	WalkSpeed = 7,
	C = {
		blue = { 110, 159, 196 },
		dark = { 60, 90, 120 },
		light = { 217, 230, 239 },
	},
	Anim = { Wag = 0.35 },
	Eyes = { node = "head", s = 0.05, side = true, x = 0.131, y = 0.05, z = 0.06 },
	Nodes = {
		{ "body", "root", 0, 0.08, 0 },
		{ "head", "body", 0, 0.02, 0.36 },
		{ "finL", "body", 0.15, -0.08, 0.15, m = true },
		{ "tail", "body", 0, 0, -0.35 },
		{ "tail2", "tail", 0, 0, -0.26 },
	},
	Parts = {
		{ "body", "blue", 0.3, 0.28, 0.7, 0, 0, 0 },
		{ "body", "light", 0.24, 0.06, 0.5, 0, -0.13, 0.02 },
		{ "body", "dark", 0.04, 0.18, 0.14, 0, 0.2, -0.04, -0.4, 0, 0 },
		{ "head", "blue", 0.26, 0.24, 0.18, 0, 0.02, 0.06 },
		{ "head", "light", 0.12, 0.08, 0.16, 0, -0.04, 0.2 },
		{ "finL", "dark", 0.16, 0.03, 0.1, 0.06, 0, 0, 0, 0, -0.3, m = true },
		{ "tail", "blue", 0.18, 0.16, 0.26, 0, 0, -0.13 },
		{ "tail2", "dark", 0.34, 0.04, 0.12, 0, 0, -0.04 },
	},
}

SPEC.Name = "Dolphin"

return SPEC
