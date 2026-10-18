-- FireBat's look (from gaudrians/FireBatScript.lua, made in Claude Design). Preview: gaudrians/FireBat.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "fly",
	Scale = 2.6,
	WalkSpeed = 5,
	Hover = 5,
	C = {
		body = { 74, 42, 46 },
		fang = { 250, 245, 235 },
		glow = { 255, 170, 60 },
		wing = { 240, 106, 46 },
	},
	Anim = { FlapSpeed = 14 },
	Eyes = { c = { 255, 220, 80 }, node = "head", s = 0.04, x = 0.05, y = 0.06, z = 0.102 },
	Nodes = {
		{ "body", "root", 0, 0.1, 0 },
		{ "head", "body", 0, 0.12, 0.04 },
		{ "earL", "head", 0.07, 0.12, 0, m = true, rz = -0.2 },
		{ "wingL", "body", 0.1, 0.04, 0, m = true },
		{ "legL", "body", 0.05, -0.1, 0, m = true },
	},
	Parts = {
		{ "body", "body", 0.2, 0.2, 0.18, 0, 0, 0 },
		{ "head", "body", 0.2, 0.16, 0.16, 0, 0.04, 0.02 },
		{ "head", "fang", 0.02, 0.03, 0.01, 0.03, -0.02, 0.105, m = true },
		{ "earL", "body", 0.06, 0.1, 0.04, 0, 0.05, 0, m = true },
		{ "wingL", "wing", 0.3, 0.02, 0.18, 0.15, 0, -0.02, m = true },
		{ "wingL", "glow", 0.14, 0.022, 0.1, 0.33, 0, -0.04, m = true, mat = "Neon" },
		{ "legL", "body", 0.03, 0.06, 0.03, 0, -0.03, 0, m = true },
	},
}

SPEC.Name = "FireBat"

return SPEC
