-- Koi's look (from gaudrians/KoiScript.lua, made in Claude Design). Preview: gaudrians/Koi.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "swim",
	Scale = 2.4,
	WalkSpeed = 3,
	C = {
		fin = { 245, 200, 180 },
		orange = { 232, 86, 46 },
		white = { 243, 241, 236 },
	},
	Anim = { Wag = 0.5 },
	Eyes = { node = "head", s = 0.035, side = true, x = 0.101, y = 0.03, z = 0.06 },
	Nodes = {
		{ "body", "root", 0, 0.04, 0 },
		{ "head", "body", 0, 0, 0.22 },
		{ "finL", "body", 0.11, -0.04, 0.1, m = true },
		{ "tail", "body", 0, 0, -0.21 },
		{ "tail2", "tail", 0, 0, -0.12 },
	},
	Parts = {
		{ "body", "white", 0.22, 0.18, 0.42, 0, 0, 0 },
		{ "body", "orange", 0.224, 0.13, 0.14, 0, 0.03, 0.06 },
		{ "body", "orange", 0.224, 0.08, 0.1, 0, 0.055, -0.12 },
		{ "body", "fin", 0.02, 0.06, 0.16, 0, 0.11, 0 },
		{ "head", "white", 0.2, 0.16, 0.12, 0, 0, 0.04 },
		{ "head", "orange", 0.202, 0.06, 0.1, 0, 0.06, 0.04 },
		{ "finL", "fin", 0.08, 0.02, 0.07, 0.04, 0, 0, m = true },
		{ "tail", "white", 0.1, 0.1, 0.12, 0, 0, -0.06 },
		{ "tail2", "fin", 0.03, 0.2, 0.14, 0, 0, -0.07 },
	},
}

SPEC.Name = "Koi"

return SPEC
