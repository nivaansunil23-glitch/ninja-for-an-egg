-- Scorpion's look (from gaudrians/ScorpionScript.lua, made in Claude Design). Preview: gaudrians/Scorpion.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 2.8,
	WalkSpeed = 4,
	C = {
		dark = { 58, 46, 40 },
		orange = { 181, 101, 46 },
		sting = { 230, 170, 60 },
	},
	Anim = { Arm = 0.15, Bob = 0.005, Leg = 0.5, Stride = 0.25, Wag = 0.15 },
	Eyes = { c = { 255, 255, 255 }, node = "body", s = 0.04, x = 0.05, y = 0.04, z = 0.312 },
	Nodes = {
		{ "body", "root", 0, 0.1, 0 },
		{ "armL", "body", 0.12, 0, 0.28, m = true, ry = 0.5 },
		{ "legL1", "body", 0.13, -0.02, 0.12, m = true, ph = 1, rz = -0.4 },
		{ "legL2", "body", 0.13, -0.02, 0.04, m = true, ph = -1, rz = -0.4 },
		{ "legL3", "body", 0.13, -0.02, -0.04, m = true, ph = 1, rz = -0.4 },
		{ "legL4", "body", 0.13, -0.02, -0.12, m = true, ph = -1, rz = -0.4 },
		{ "tail", "body", 0, 0.02, -0.2, rx = 1 },
		{ "tail2", "tail", 0, 0, -0.14, rx = 0.8 },
		{ "tail3", "tail2", 0, 0, -0.12, rx = 0.8 },
		{ "tail4", "tail3", 0, 0, -0.1, rx = 0.6 },
	},
	Parts = {
		{ "body", "dark", 0.26, 0.1, 0.4, 0, 0, 0 },
		{ "body", "dark", 0.2, 0.08, 0.12, 0, 0, 0.25 },
		{ "armL", "dark", 0.05, 0.05, 0.18, 0, 0, 0.09, m = true },
		{ "armL", "orange", 0.1, 0.06, 0.12, 0, 0, 0.22, m = true },
		{ "legL1", "dark", 0.16, 0.03, 0.03, 0.08, 0, 0, m = true },
		{ "legL2", "dark", 0.16, 0.03, 0.03, 0.08, 0, 0, m = true },
		{ "legL3", "dark", 0.16, 0.03, 0.03, 0.08, 0, 0, m = true },
		{ "legL4", "dark", 0.16, 0.03, 0.03, 0.08, 0, 0, m = true },
		{ "tail", "dark", 0.08, 0.08, 0.14, 0, 0, -0.07 },
		{ "tail2", "dark", 0.07, 0.07, 0.12, 0, 0, -0.06 },
		{ "tail3", "dark", 0.06, 0.06, 0.1, 0, 0, -0.05 },
		{ "tail4", "sting", 0.05, 0.05, 0.08, 0, 0, -0.04 },
	},
}

SPEC.Name = "Scorpion"

return SPEC
