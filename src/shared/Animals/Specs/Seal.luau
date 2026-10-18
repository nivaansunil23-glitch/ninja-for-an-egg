-- Seal's look (from gaudrians/SealScript.lua, made in Claude Design). Preview: gaudrians/Seal.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 3,
	WalkSpeed = 2.5,
	C = {
		dark = { 50, 50, 56 },
		grey = { 142, 153, 163 },
		light = { 201, 208, 214 },
	},
	Anim = { Bob = 0.07, Leg = 0.6, Stride = 0.4 },
	Eyes = { node = "head", s = 0.055, x = 0.08, y = 0.12, z = 0.202 },
	Nodes = {
		{ "body", "root", 0, 0.18, 0 },
		{ "head", "body", 0, 0.18, 0.24 },
		{ "finL", "body", 0.18, -0.08, 0.12, m = true, ph = 1 },
		{ "tail", "body", 0, -0.1, -0.52 },
	},
	Parts = {
		{ "body", "grey", 0.34, 0.3, 0.6, 0, 0.02, -0.05 },
		{ "body", "light", 0.28, 0.04, 0.44, 0, -0.13, 0 },
		{ "body", "grey", 0.24, 0.2, 0.2, 0, -0.04, -0.42 },
		{ "head", "grey", 0.3, 0.26, 0.28, 0, 0.08, 0.06 },
		{ "head", "light", 0.16, 0.1, 0.08, 0, 0.02, 0.22 },
		{ "head", "dark", 0.06, 0.04, 0.02, 0, 0.06, 0.265 },
		{ "finL", "grey", 0.14, 0.04, 0.12, 0.05, -0.04, 0.02, 0, 0, -0.3, m = true },
		{ "tail", "grey", 0.24, 0.04, 0.12, 0, 0, -0.05 },
	},
}

SPEC.Name = "Seal"

return SPEC
