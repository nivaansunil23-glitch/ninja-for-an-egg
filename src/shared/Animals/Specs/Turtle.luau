-- Turtle's look (from gaudrians/TurtleScript.lua, made in Claude Design). Preview: gaudrians/Turtle.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 2.8,
	WalkSpeed = 2.5,
	C = {
		belly = { 232, 214, 150 },
		blush = { 240, 160, 170 },
		dark = { 52, 112, 66 },
		plate = { 122, 190, 110 },
		shell = { 78, 154, 91 },
		skin = { 176, 196, 108 },
	},
	Anim = { Bob = 0.01, Leg = 0.7, Stride = 0.35 },
	Eyes = { node = "head", s = 0.04, x = 0.055, y = 0.055, z = 0.182 },
	Nodes = {
		{ "body", "root", 0, 0.14, 0 },
		{ "head", "body", 0, 0.03, 0.3 },
		{ "legFL", "body", 0.2, -0.06, 0.18, m = true },
		{ "legBL", "body", 0.2, -0.06, -0.18, m = true },
		{ "tail", "body", 0, -0.02, -0.28 },
	},
	Parts = {
		{ "body", "dark", 0.52, 0.1, 0.58, 0, 0.02, 0, r = 0.4 },
		{ "body", "shell", 0.44, 0.12, 0.5, 0, 0.11, 0, r = 0.4 },
		{ "body", "shell", 0.3, 0.08, 0.34, 0, 0.19, 0, r = 0.4 },
		{ "body", "plate", 0.1, 0.02, 0.1, 0, 0.234, 0.07, r = 0.3 },
		{ "body", "plate", 0.1, 0.02, 0.1, 0, 0.234, -0.08, r = 0.3 },
		{ "body", "plate", 0.08, 0.02, 0.08, 0.13, 0.175, 0, 0, 0, -0.5, m = true, r = 0.3 },
		{ "body", "belly", 0.46, 0.05, 0.52, 0, -0.05, 0, r = 0.4 },
		{ "head", "skin", 0.12, 0.1, 0.12, 0, 0, -0.02, r = 0.3 },
		{ "head", "skin", 0.2, 0.17, 0.2, 0, 0.03, 0.08, r = 0.4 },
		{ "head", "blush", 0.035, 0.02, 0.012, 0.065, 0.01, 0.182, m = true },
		{ "legFL", "skin", 0.15, 0.07, 0.13, 0.05, -0.02, 0, m = true, r = 0.4 },
		{ "legBL", "skin", 0.13, 0.07, 0.12, 0.04, -0.02, 0, m = true, r = 0.4 },
		{ "tail", "skin", 0.07, 0.05, 0.1, 0, 0, -0.04, r = 0.3 },
	},
}

SPEC.Name = "Turtle"

return SPEC
