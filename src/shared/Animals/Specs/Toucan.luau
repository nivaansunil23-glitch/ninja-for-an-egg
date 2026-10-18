-- Toucan's look (from gaudrians/ToucanScript.lua, made in Claude Design). Preview: gaudrians/Toucan.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 2.6,
	WalkSpeed = 4,
	C = {
		beak = { 242, 154, 46 },
		black = { 35, 35, 35 },
		chest = { 250, 236, 180 },
		legs = { 90, 130, 200 },
		ring = { 80, 150, 230 },
		tip = { 40, 40, 40 },
	},
	Anim = { Leg = 0.5 },
	Eyes = { node = "head", s = 0.04, x = 0.08, y = 0.13, z = 0.152 },
	Nodes = {
		{ "body", "root", 0, 0.14, 0 },
		{ "head", "body", 0, 0.4, 0.02 },
		{ "wingL", "body", 0.15, 0.34, 0, m = true },
		{ "legL", "root", 0.07, 0.14, 0.02, m = true },
		{ "tail", "body", 0, 0.04, -0.15, rx = -0.3 },
	},
	Parts = {
		{ "body", "black", 0.28, 0.38, 0.3, 0, 0.18, 0 },
		{ "body", "chest", 0.2, 0.16, 0.02, 0, 0.26, 0.15 },
		{ "head", "black", 0.26, 0.24, 0.24, 0, 0.1, 0.02 },
		{ "head", "chest", 0.2, 0.08, 0.02, 0, 0.04, 0.14 },
		{ "head", "beak", 0.12, 0.14, 0.26, 0, 0.08, 0.26 },
		{ "head", "tip", 0.121, 0.06, 0.06, 0, 0.05, 0.38 },
		{ "head", "ring", 0.08, 0.08, 0.012, 0.08, 0.13, 0.146, m = true },
		{ "wingL", "black", 0.04, 0.26, 0.24, 0.01, -0.11, -0.02, m = true },
		{ "legL", "legs", 0.04, 0.1, 0.04, 0, -0.07, 0, m = true },
		{ "legL", "legs", 0.08, 0.03, 0.1, 0, -0.125, 0.02, m = true },
		{ "tail", "black", 0.14, 0.04, 0.24, 0, 0, -0.12 },
	},
}

SPEC.Name = "Toucan"

return SPEC
