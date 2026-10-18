-- Monkey's look (from gaudrians/MonkeyScript.lua, made in Claude Design). Preview: gaudrians/Monkey.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "biped",
	Scale = 2.8,
	WalkSpeed = 5,
	C = {
		dark = { 80, 50, 35 },
		face = { 230, 196, 158 },
		fur = { 138, 90, 58 },
	},
	Anim = { Arm = 0.6, Leg = 0.6, Wag = 0.3 },
	Eyes = { node = "head", s = 0.045, x = 0.06, y = 0.17, z = 0.172 },
	Nodes = {
		{ "legL", "root", 0.08, 0.16, 0, m = true },
		{ "body", "root", 0, 0.16, 0 },
		{ "head", "body", 0, 0.3, 0.02 },
		{ "earL", "head", 0.19, 0.15, 0, m = true },
		{ "armL", "body", 0.17, 0.27, 0, m = true },
		{ "tail", "body", 0, 0.06, -0.12, rx = 1.2 },
		{ "tail2", "tail", 0, 0, -0.24, rx = -1.4 },
	},
	Parts = {
		{ "legL", "fur", 0.08, 0.16, 0.08, 0, -0.08, 0, m = true },
		{ "legL", "face", 0.09, 0.03, 0.12, 0, -0.145, 0.02, m = true },
		{ "body", "fur", 0.3, 0.3, 0.24, 0, 0.15, 0 },
		{ "body", "face", 0.2, 0.2, 0.02, 0, 0.13, 0.12 },
		{ "head", "fur", 0.34, 0.3, 0.28, 0, 0.15, 0.02 },
		{ "head", "face", 0.26, 0.2, 0.02, 0, 0.13, 0.16 },
		{ "head", "face", 0.16, 0.08, 0.05, 0, 0.06, 0.17 },
		{ "head", "dark", 0.04, 0.02, 0.012, 0, 0.08, 0.196 },
		{ "earL", "face", 0.06, 0.1, 0.08, 0, 0, 0, m = true },
		{ "armL", "fur", 0.07, 0.28, 0.07, 0, -0.14, 0, m = true },
		{ "armL", "face", 0.08, 0.05, 0.08, 0, -0.29, 0, m = true },
		{ "tail", "fur", 0.04, 0.04, 0.24, 0, 0, -0.12 },
		{ "tail2", "fur", 0.04, 0.04, 0.14, 0, 0, -0.07 },
	},
}

SPEC.Name = "Monkey"

return SPEC
