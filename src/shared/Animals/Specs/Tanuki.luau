-- Tanuki's look (from gaudrians/TanukiScript.lua, made in Claude Design). Preview: gaudrians/Tanuki.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 4.5,
	C = {
		brown = { 126, 100, 80 },
		cream = { 226, 206, 180 },
		dark = { 58, 47, 40 },
	},
	Anim = { Wag = 0.25 },
	Eyes = { c = { 255, 255, 255 }, node = "head", s = 0.045, x = 0.09, y = 0.1, z = 0.214 },
	Nodes = {
		{ "body", "root", 0, 0.24, 0 },
		{ "head", "body", 0, 0.2, 0.24 },
		{ "earL", "head", 0.12, 0.24, 0.03, m = true },
		{ "legFL", "root", 0.11, 0.18, 0.16, m = true },
		{ "legBL", "root", 0.11, 0.18, -0.16, m = true },
		{ "tail", "body", 0, 0.06, -0.24, rx = 0.5 },
	},
	Parts = {
		{ "body", "brown", 0.36, 0.28, 0.46, 0, 0.05, 0 },
		{ "body", "cream", 0.28, 0.04, 0.3, 0, -0.1, 0.02 },
		{ "head", "brown", 0.36, 0.28, 0.28, 0, 0.08, 0.06 },
		{ "head", "dark", 0.12, 0.09, 0.012, 0.09, 0.1, 0.206, m = true },
		{ "head", "cream", 0.16, 0.1, 0.06, 0, 0.01, 0.22 },
		{ "head", "dark", 0.05, 0.035, 0.02, 0, 0.045, 0.255 },
		{ "earL", "dark", 0.09, 0.08, 0.05, 0, 0, 0, m = true },
		{ "legFL", "dark", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "legBL", "dark", 0.08, 0.18, 0.08, 0, -0.09, 0, m = true },
		{ "tail", "brown", 0.18, 0.18, 0.3, 0, 0, -0.15 },
		{ "tail", "dark", 0.182, 0.182, 0.08, 0, 0, -0.28 },
	},
}

SPEC.Name = "Tanuki"

return SPEC
