-- Parrot's look (from gaudrians/ParrotScript.lua, made in Claude Design). Preview: gaudrians/Parrot.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 2.6,
	WalkSpeed = 4,
	C = {
		beak = { 240, 232, 220 },
		blue = { 46, 127, 209 },
		dark = { 60, 60, 60 },
		face = { 250, 246, 240 },
		red = { 217, 58, 48 },
		yellow = { 245, 200, 50 },
	},
	Anim = { Leg = 0.5 },
	Eyes = { node = "head", s = 0.04, x = 0.07, y = 0.14, z = 0.162 },
	Nodes = {
		{ "body", "root", 0, 0.14, 0 },
		{ "head", "body", 0, 0.38, 0.02 },
		{ "wingL", "body", 0.15, 0.32, 0, m = true },
		{ "legL", "root", 0.07, 0.14, 0.02, m = true },
		{ "tail", "body", 0, 0.04, -0.14, rx = -0.5 },
	},
	Parts = {
		{ "body", "red", 0.28, 0.36, 0.28, 0, 0.18, 0 },
		{ "head", "red", 0.28, 0.26, 0.26, 0, 0.12, 0.02 },
		{ "head", "face", 0.18, 0.12, 0.02, 0, 0.12, 0.15 },
		{ "head", "beak", 0.1, 0.1, 0.1, 0, 0.06, 0.18 },
		{ "head", "dark", 0.08, 0.05, 0.06, 0, 0.01, 0.16 },
		{ "wingL", "blue", 0.04, 0.28, 0.24, 0.01, -0.12, -0.02, m = true },
		{ "wingL", "yellow", 0.042, 0.06, 0.24, 0.01, -0.02, -0.02, m = true },
		{ "legL", "dark", 0.04, 0.1, 0.04, 0, -0.07, 0, m = true },
		{ "legL", "dark", 0.08, 0.03, 0.1, 0, -0.125, 0.02, m = true },
		{ "tail", "blue", 0.12, 0.04, 0.34, 0, 0, -0.17 },
		{ "tail", "red", 0.122, 0.042, 0.08, 0, 0, -0.32 },
	},
}

SPEC.Name = "Parrot"

return SPEC
