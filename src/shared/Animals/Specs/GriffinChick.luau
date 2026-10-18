-- GriffinChick's look (from gaudrians/GriffinChickScript.lua, made in Claude Design). Preview: gaudrians/GriffinChick.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.6,
	WalkSpeed = 5,
	C = {
		beak = { 245, 180, 50 },
		dark = { 90, 70, 50 },
		feather = { 244, 239, 230 },
		fur = { 230, 192, 106 },
	},
	Anim = { Wag = 0.3 },
	Eyes = { node = "head", s = 0.05, x = 0.08, y = 0.12, z = 0.182 },
	Nodes = {
		{ "body", "root", 0, 0.24, 0 },
		{ "head", "body", 0, 0.22, 0.22 },
		{ "earL", "head", 0.1, 0.22, -0.04, m = true, rz = -0.3 },
		{ "wingL", "body", 0.15, 0.12, 0.04, m = true },
		{ "legFL", "root", 0.09, 0.18, 0.15, m = true },
		{ "legBL", "root", 0.09, 0.18, -0.15, m = true },
		{ "tail", "body", 0, 0.08, -0.22, rx = 0.5 },
	},
	Parts = {
		{ "body", "fur", 0.3, 0.26, 0.44, 0, 0.04, 0 },
		{ "body", "feather", 0.28, 0.24, 0.14, 0, 0.08, 0.18 },
		{ "head", "feather", 0.3, 0.28, 0.28, 0, 0.08, 0.04 },
		{ "head", "beak", 0.1, 0.08, 0.1, 0, 0.04, 0.21 },
		{ "head", "beak", 0.08, 0.05, 0.04, 0, -0.01, 0.25 },
		{ "earL", "feather", 0.05, 0.1, 0.05, 0, 0.04, 0, m = true },
		{ "wingL", "feather", 0.04, 0.16, 0.2, 0.01, -0.04, 0, m = true },
		{ "legFL", "beak", 0.07, 0.18, 0.07, 0, -0.09, 0, m = true },
		{ "legBL", "fur", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "tail", "fur", 0.05, 0.05, 0.2, 0, 0, -0.1 },
		{ "tail", "dark", 0.09, 0.09, 0.08, 0, 0, -0.22 },
	},
}

SPEC.Name = "GriffinChick"

return SPEC
