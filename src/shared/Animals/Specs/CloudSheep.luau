-- CloudSheep's look (from gaudrians/CloudSheepScript.lua, made in Claude Design). Preview: gaudrians/CloudSheep.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 4,
	C = {
		face = { 150, 160, 190 },
		shade = { 207, 224, 242 },
		wool = { 255, 255, 255 },
	},
	Anim = { Bob = 0.05, Leg = 0.6 },
	Eyes = { node = "head", s = 0.04, x = 0.055, y = 0.05, z = 0.162 },
	Nodes = {
		{ "body", "root", 0, 0.28, 0 },
		{ "head", "body", 0, 0.12, 0.3 },
		{ "earL", "head", 0.13, 0.06, 0.04, m = true, rz = -1.2 },
		{ "legFL", "root", 0.12, 0.16, 0.16, m = true },
		{ "legBL", "root", 0.12, 0.16, -0.16, m = true },
	},
	Parts = {
		{ "body", "wool", 0.46, 0.36, 0.52, 0, 0.06, 0 },
		{ "body", "wool", 0.2, 0.2, 0.2, 0.16, 0.18, 0.12, m = true },
		{ "body", "wool", 0.22, 0.2, 0.22, 0, 0.26, -0.06 },
		{ "body", "shade", 0.2, 0.18, 0.2, 0.17, 0.14, -0.16, m = true },
		{ "body", "wool", 0.2, 0.18, 0.2, 0, 0.2, 0.18 },
		{ "head", "face", 0.22, 0.22, 0.2, 0, 0.02, 0.06 },
		{ "head", "wool", 0.24, 0.1, 0.18, 0, 0.15, 0.04 },
		{ "earL", "face", 0.1, 0.05, 0.06, 0.04, 0, 0, m = true },
		{ "legFL", "face", 0.07, 0.16, 0.07, 0, -0.08, 0, m = true },
		{ "legBL", "face", 0.07, 0.16, 0.07, 0, -0.08, 0, m = true },
	},
}

SPEC.Name = "CloudSheep"

return SPEC
