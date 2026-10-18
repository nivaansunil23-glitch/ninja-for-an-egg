-- LavaLizard's look (from gaudrians/LavaLizardScript.lua, made in Claude Design). Preview: gaudrians/LavaLizard.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 3.4,
	WalkSpeed = 4.5,
	C = {
		belly = { 80, 60, 55 },
		lava = { 242, 138, 46 },
		rock = { 46, 42, 42 },
	},
	Anim = { Bob = 0.005, Leg = 0.6, Stride = 0.3, Wag = 0.4, WagSpeed = 4 },
	Eyes = { c = { 255, 200, 60 }, node = "head", s = 0.04, x = 0.06, y = 0.06, z = 0.152 },
	Nodes = {
		{ "body", "root", 0, 0.1, 0 },
		{ "head", "body", 0, 0.01, 0.21 },
		{ "legFL", "body", 0.11, -0.02, 0.13, m = true, rz = -0.4 },
		{ "legBL", "body", 0.11, -0.02, -0.13, m = true, rz = -0.4 },
		{ "tail", "body", 0, 0, -0.2 },
		{ "tail2", "tail", 0, 0, -0.22 },
		{ "tail3", "tail2", 0, 0, -0.18 },
	},
	Parts = {
		{ "body", "rock", 0.22, 0.13, 0.4, 0, 0, 0 },
		{ "body", "belly", 0.18, 0.02, 0.34, 0, -0.07, 0 },
		{ "body", "lava", 0.04, 0.02, 0.32, 0, 0.07, 0, mat = "Neon" },
		{ "body", "lava", 0.06, 0.02, 0.025, 0.06, 0.07, 0.08, m = true, mat = "Neon" },
		{ "body", "lava", 0.06, 0.02, 0.025, 0.06, 0.07, -0.08, m = true, mat = "Neon" },
		{ "head", "rock", 0.18, 0.11, 0.18, 0, 0.01, 0.06 },
		{ "head", "lava", 0.04, 0.02, 0.1, 0, 0.07, 0.04, mat = "Neon" },
		{ "legFL", "rock", 0.15, 0.05, 0.06, 0.075, 0, 0, m = true },
		{ "legBL", "rock", 0.15, 0.05, 0.06, 0.075, 0, 0, m = true },
		{ "tail", "rock", 0.12, 0.09, 0.22, 0, 0, -0.11 },
		{ "tail", "lava", 0.03, 0.02, 0.2, 0, 0.05, -0.11, mat = "Neon" },
		{ "tail2", "rock", 0.08, 0.06, 0.22, 0, 0, -0.11 },
		{ "tail3", "lava", 0.05, 0.04, 0.12, 0, 0, -0.06, mat = "Neon" },
	},
}

SPEC.Name = "LavaLizard"

return SPEC
