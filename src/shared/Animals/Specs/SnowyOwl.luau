-- SnowyOwl's look (from gaudrians/SnowyOwlScript.lua, made in Claude Design). Preview: gaudrians/SnowyOwl.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 3,
	WalkSpeed = 4,
	C = {
		beak = { 60, 60, 64 },
		face = { 255, 255, 255 },
		spot = { 120, 124, 130 },
		white = { 247, 247, 244 },
	},
	Anim = { HeadSleep = 0.2, Leg = 0.5 },
	Eyes = { c = { 240, 190, 30 }, node = "head", s = 0.07, x = 0.085, y = 0.15, z = 0.212 },
	Nodes = {
		{ "body", "root", 0, 0.12, 0 },
		{ "head", "body", 0, 0.38, 0.01 },
		{ "wingL", "body", 0.22, 0.32, -0.02, m = true },
		{ "legL", "root", 0.09, 0.12, 0.04, m = true },
		{ "tail", "body", 0, 0.06, -0.19, rx = 0.4 },
	},
	Parts = {
		{ "body", "white", 0.44, 0.4, 0.4, 0, 0.18, 0, r = 0.4 },
		{ "body", "spot", 0.05, 0.03, 0.012, 0.08, 0.24, 0.201, m = true },
		{ "body", "spot", 0.05, 0.03, 0.012, 0, 0.14, 0.201 },
		{ "head", "white", 0.46, 0.32, 0.4, 0, 0.14, 0, r = 0.4 },
		{ "head", "face", 0.36, 0.22, 0.04, 0, 0.13, 0.19, r = 0.4 },
		{ "head", "spot", 0.05, 0.012, 0.05, 0.09, 0.3, -0.04, m = true },
		{ "head", "beak", 0.06, 0.07, 0.05, 0, 0.07, 0.22, r = 0.2 },
		{ "wingL", "white", 0.06, 0.3, 0.32, 0.02, -0.13, -0.01, m = true, r = 0.4 },
		{ "wingL", "spot", 0.012, 0.04, 0.05, 0.052, -0.1, -0.06, m = true },
		{ "wingL", "spot", 0.012, 0.04, 0.05, 0.052, -0.18, 0.05, m = true },
		{ "legL", "face", 0.1, 0.1, 0.12, 0, -0.07, 0.02, m = true, r = 0.4 },
		{ "legL", "beak", 0.08, 0.02, 0.03, 0, -0.11, 0.08, m = true },
		{ "tail", "white", 0.22, 0.06, 0.12, 0, 0, -0.06, r = 0.3 },
	},
}

SPEC.Name = "SnowyOwl"

return SPEC
