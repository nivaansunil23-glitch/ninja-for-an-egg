-- Seagull's look (from gaudrians/SeagullScript.lua, made in Claude Design). Preview: gaudrians/Seagull.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 2.6,
	WalkSpeed = 4.5,
	C = {
		beak = { 245, 190, 40 },
		black = { 40, 40, 44 },
		grey = { 154, 166, 174 },
		legs = { 240, 150, 60 },
		white = { 244, 245, 243 },
	},
	Anim = { Leg = 0.6 },
	Eyes = { node = "head", s = 0.045, x = 0.07, y = 0.14, z = 0.172 },
	Nodes = {
		{ "body", "root", 0, 0.2, 0 },
		{ "head", "body", 0, 0.3, 0.18 },
		{ "wingL", "body", 0.15, 0.24, 0.02, m = true },
		{ "legL", "root", 0.07, 0.2, 0.02, m = true },
		{ "tail", "body", 0, 0.16, -0.25, rx = 0.3 },
	},
	Parts = {
		{ "body", "white", 0.28, 0.28, 0.48, 0, 0.12, 0 },
		{ "head", "white", 0.26, 0.24, 0.26, 0, 0.1, 0.04 },
		{ "head", "beak", 0.06, 0.06, 0.16, 0, 0.07, 0.24 },
		{ "wingL", "grey", 0.04, 0.22, 0.42, 0.01, -0.08, -0.04, m = true },
		{ "wingL", "black", 0.042, 0.1, 0.1, 0.01, -0.06, -0.3, m = true },
		{ "legL", "legs", 0.035, 0.16, 0.035, 0, -0.1, 0, m = true },
		{ "legL", "legs", 0.08, 0.025, 0.1, 0, -0.19, 0.03, m = true },
		{ "tail", "white", 0.18, 0.04, 0.12, 0, 0, -0.05 },
	},
}

SPEC.Name = "Seagull"

return SPEC
