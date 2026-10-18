-- Lizard's look (from gaudrians/LizardScript.lua, made in Claude Design). Preview: gaudrians/Lizard.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 3.4,
	WalkSpeed = 5,
	C = {
		belly = { 217, 196, 107 },
		dark = { 90, 100, 40 },
		skin = { 159, 168, 74 },
	},
	Anim = { Bob = 0.005, Leg = 0.6, Stride = 0.3, Wag = 0.4, WagSpeed = 4 },
	Eyes = { node = "head", s = 0.035, x = 0.05, y = 0.05, z = 0.142 },
	Nodes = {
		{ "body", "root", 0, 0.08, 0 },
		{ "head", "body", 0, 0.01, 0.2 },
		{ "legFL", "body", 0.09, -0.02, 0.12, m = true, rz = -0.4 },
		{ "legBL", "body", 0.09, -0.02, -0.12, m = true, rz = -0.4 },
		{ "tail", "body", 0, 0, -0.18 },
		{ "tail2", "tail", 0, 0, -0.2 },
		{ "tail3", "tail2", 0, 0, -0.2 },
	},
	Parts = {
		{ "body", "skin", 0.18, 0.1, 0.36, 0, 0, 0 },
		{ "body", "belly", 0.14, 0.02, 0.3, 0, -0.05, 0 },
		{ "body", "dark", 0.04, 0.02, 0.04, 0, 0.055, 0.08 },
		{ "body", "dark", 0.04, 0.02, 0.04, 0, 0.055, -0.04 },
		{ "head", "skin", 0.16, 0.1, 0.16, 0, 0.01, 0.06 },
		{ "legFL", "skin", 0.14, 0.04, 0.05, 0.07, 0, 0, m = true },
		{ "legBL", "skin", 0.14, 0.04, 0.05, 0.07, 0, 0, m = true },
		{ "tail", "skin", 0.1, 0.07, 0.2, 0, 0, -0.1 },
		{ "tail2", "skin", 0.06, 0.05, 0.2, 0, 0, -0.1 },
		{ "tail3", "dark", 0.035, 0.035, 0.14, 0, 0, -0.07 },
	},
}

SPEC.Name = "Lizard"

return SPEC
