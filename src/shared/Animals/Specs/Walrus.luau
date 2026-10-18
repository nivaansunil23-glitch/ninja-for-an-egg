-- Walrus's look (from gaudrians/WalrusScript.lua, made in Claude Design). Preview: gaudrians/Walrus.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 3.6,
	WalkSpeed = 2,
	C = {
		brown = { 138, 106, 85 },
		dark = { 60, 44, 36 },
		light = { 200, 160, 130 },
		tusk = { 239, 230, 210 },
	},
	Anim = { Bob = 0.06, Leg = 0.6, Stride = 0.4 },
	Eyes = { node = "head", s = 0.045, x = 0.1, y = 0.13, z = 0.202 },
	Nodes = {
		{ "body", "root", 0, 0.22, 0 },
		{ "head", "body", 0, 0.2, 0.28 },
		{ "finL", "body", 0.24, -0.12, 0.14, m = true, ph = 1 },
		{ "tail", "body", 0, -0.12, -0.58 },
	},
	Parts = {
		{ "body", "brown", 0.52, 0.4, 0.66, 0, 0.04, -0.04, r = 0.4 },
		{ "body", "brown", 0.38, 0.28, 0.26, 0, -0.04, -0.46, r = 0.4 },
		{ "head", "brown", 0.4, 0.32, 0.32, 0, 0.06, 0.04, r = 0.4 },
		{ "head", "light", 0.15, 0.14, 0.1, 0.07, -0.02, 0.21, m = true, r = 0.4 },
		{ "head", "dark", 0.06, 0.04, 0.02, 0, 0.055, 0.265 },
		{ "head", "tusk", 0.04, 0.2, 0.04, 0.07, -0.15, 0.23, m = true, r = 0.2 },
		{ "finL", "brown", 0.18, 0.05, 0.14, 0.06, -0.03, 0.02, 0, 0, -0.3, m = true, r = 0.3 },
		{ "tail", "brown", 0.3, 0.05, 0.14, 0, 0, -0.05, r = 0.3 },
	},
}

SPEC.Name = "Walrus"

return SPEC
