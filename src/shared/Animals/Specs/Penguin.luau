-- Penguin's look (from gaudrians/PenguinScript.lua, made in Claude Design). Preview: gaudrians/Penguin.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "biped",
	Scale = 2.8,
	WalkSpeed = 3,
	C = {
		black = { 37, 48, 58 },
		blush = { 245, 170, 180 },
		orange = { 245, 160, 50 },
		white = { 244, 244, 242 },
	},
	Anim = { Arm = 0.4, Bob = 0.03, Leg = 0.5, Stride = 0.3 },
	Eyes = { node = "head", s = 0.045, x = 0.065, y = 0.14, z = 0.192 },
	Nodes = {
		{ "legL", "root", 0.08, 0.06, 0.04, m = true },
		{ "body", "root", 0, 0.06, 0 },
		{ "head", "body", 0, 0.5, 0 },
		{ "armL", "body", 0.23, 0.42, 0, m = true, rz = -0.12 },
	},
	Parts = {
		{ "legL", "orange", 0.12, 0.04, 0.15, 0, -0.04, 0.05, m = true, r = 0.2 },
		{ "body", "black", 0.44, 0.5, 0.38, 0, 0.25, 0, r = 0.2 },
		{ "body", "white", 0.32, 0.4, 0.04, 0, 0.22, 0.19, r = 0.2 },
		{ "body", "black", 0.12, 0.05, 0.08, 0, 0.03, -0.2, r = 0.2 },
		{ "head", "black", 0.38, 0.3, 0.34, 0, 0.14, 0, r = 0.2 },
		{ "head", "white", 0.28, 0.18, 0.04, 0, 0.12, 0.17, r = 0.2 },
		{ "head", "orange", 0.09, 0.05, 0.09, 0, 0.08, 0.21, r = 0.2 },
		{ "head", "blush", 0.05, 0.03, 0.012, 0.105, 0.08, 0.191, m = true },
		{ "armL", "black", 0.05, 0.3, 0.15, 0.01, -0.14, 0, m = true, r = 0.2 },
	},
}

SPEC.Name = "Penguin"

return SPEC
