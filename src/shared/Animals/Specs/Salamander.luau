-- Salamander's look (from gaudrians/SalamanderScript.lua, made in Claude Design). Preview: gaudrians/Salamander.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 3.2,
	WalkSpeed = 4,
	C = {
		belly = { 245, 180, 90 },
		skin = { 232, 116, 46 },
		spot = { 46, 46, 46 },
	},
	Anim = { Bob = 0.005, Leg = 0.6, Stride = 0.3, Wag = 0.4, WagSpeed = 4 },
	Eyes = { node = "head", s = 0.04, x = 0.06, y = 0.06, z = 0.142 },
	Nodes = {
		{ "body", "root", 0, 0.09, 0 },
		{ "head", "body", 0, 0.01, 0.2 },
		{ "legFL", "body", 0.1, -0.02, 0.12, m = true, rz = -0.4 },
		{ "legBL", "body", 0.1, -0.02, -0.12, m = true, rz = -0.4 },
		{ "tail", "body", 0, 0, -0.18 },
		{ "tail2", "tail", 0, 0, -0.2 },
		{ "tail3", "tail2", 0, 0, -0.18 },
	},
	Parts = {
		{ "body", "skin", 0.2, 0.12, 0.36, 0, 0, 0 },
		{ "body", "belly", 0.16, 0.02, 0.3, 0, -0.06, 0 },
		{ "body", "spot", 0.05, 0.02, 0.05, 0.05, 0.065, 0.08, m = true },
		{ "body", "spot", 0.05, 0.02, 0.05, -0.04, 0.065, -0.08, m = true },
		{ "head", "skin", 0.2, 0.11, 0.16, 0, 0.01, 0.06 },
		{ "head", "spot", 0.04, 0.02, 0.04, 0, 0.07, 0.04 },
		{ "legFL", "skin", 0.14, 0.05, 0.06, 0.07, 0, 0, m = true },
		{ "legBL", "skin", 0.14, 0.05, 0.06, 0.07, 0, 0, m = true },
		{ "tail", "skin", 0.12, 0.09, 0.2, 0, 0, -0.1 },
		{ "tail", "spot", 0.05, 0.02, 0.05, 0, 0.05, -0.1 },
		{ "tail2", "skin", 0.08, 0.06, 0.2, 0, 0, -0.1 },
		{ "tail3", "skin", 0.05, 0.04, 0.12, 0, 0, -0.06 },
	},
}

SPEC.Name = "Salamander"

return SPEC
