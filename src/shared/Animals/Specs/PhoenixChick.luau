-- PhoenixChick's look (from gaudrians/PhoenixChickScript.lua, made in Claude Design). Preview: gaudrians/PhoenixChick.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 2.4,
	WalkSpeed = 4,
	C = {
		beak = { 250, 210, 90 },
		flame = { 255, 150, 40 },
		flame2 = { 255, 220, 80 },
		red = { 232, 67, 46 },
		yellow = { 242, 179, 58 },
	},
	Anim = { Leg = 0.6 },
	Eyes = { node = "head", s = 0.045, x = 0.07, y = 0.15, z = 0.162 },
	Nodes = {
		{ "body", "root", 0, 0.14, 0 },
		{ "head", "body", 0, 0.32, 0.03 },
		{ "wingL", "body", 0.17, 0.28, 0, m = true },
		{ "legL", "root", 0.07, 0.14, 0.02, m = true },
		{ "tail", "body", 0, 0.12, -0.17, rx = 0.6 },
	},
	Parts = {
		{ "body", "red", 0.34, 0.32, 0.34, 0, 0.16, 0 },
		{ "body", "yellow", 0.24, 0.2, 0.02, 0, 0.14, 0.17 },
		{ "head", "red", 0.3, 0.26, 0.28, 0, 0.12, 0.02 },
		{ "head", "beak", 0.08, 0.06, 0.06, 0, 0.1, 0.18 },
		{ "head", "flame", 0.06, 0.14, 0.06, 0, 0.3, 0, mat = "Neon" },
		{ "head", "flame2", 0.05, 0.1, 0.05, 0.05, 0.27, -0.04, 0, 0, -0.4, m = true, mat = "Neon" },
		{ "wingL", "red", 0.04, 0.18, 0.18, 0.01, -0.08, 0, m = true },
		{ "wingL", "yellow", 0.042, 0.05, 0.18, 0.01, -0.15, 0, m = true },
		{ "legL", "beak", 0.04, 0.1, 0.04, 0, -0.07, 0, m = true },
		{ "legL", "beak", 0.08, 0.03, 0.1, 0, -0.125, 0.02, m = true },
		{ "tail", "flame", 0.14, 0.05, 0.16, 0, 0, -0.08, mat = "Neon" },
	},
}

SPEC.Name = "PhoenixChick"

return SPEC
