-- Vulture's look (from gaudrians/VultureScript.lua, made in Claude Design). Preview: gaudrians/Vulture.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "bird",
	Scale = 3.2,
	WalkSpeed = 4,
	C = {
		beak = { 230, 210, 160 },
		collar = { 236, 228, 218 },
		dark = { 74, 58, 54 },
		legs = { 120, 110, 105 },
		pink = { 217, 169, 160 },
	},
	Anim = { Leg = 0.5 },
	Eyes = { node = "head", s = 0.03, x = 0.045, y = 0.07, z = 0.102 },
	Nodes = {
		{ "body", "root", 0, 0.22, 0 },
		{ "neck", "body", 0, 0.32, 0.14, rx = 0.5 },
		{ "head", "neck", 0, 0.14, 0.02, rx = -0.5 },
		{ "wingL", "body", 0.2, 0.3, -0.02, m = true },
		{ "legL", "root", 0.08, 0.22, 0.02, m = true },
		{ "tail", "body", 0, 0.06, -0.24, rx = 0.3 },
	},
	Parts = {
		{ "body", "dark", 0.38, 0.34, 0.44, 0, 0.14, -0.02 },
		{ "body", "collar", 0.3, 0.1, 0.3, 0, 0.32, 0.08 },
		{ "neck", "pink", 0.07, 0.14, 0.07, 0, 0.06, 0 },
		{ "head", "pink", 0.16, 0.14, 0.16, 0, 0.04, 0.02 },
		{ "head", "beak", 0.06, 0.06, 0.1, 0, 0.02, 0.14 },
		{ "head", "dark", 0.06, 0.05, 0.03, 0, -0.01, 0.18 },
		{ "wingL", "dark", 0.05, 0.32, 0.42, 0.02, -0.12, -0.04, m = true },
		{ "legL", "legs", 0.04, 0.16, 0.04, 0, -0.11, 0, m = true },
		{ "legL", "legs", 0.1, 0.03, 0.11, 0, -0.2, 0.03, m = true },
		{ "tail", "dark", 0.24, 0.05, 0.14, 0, 0, -0.07 },
	},
}

SPEC.Name = "Vulture"

return SPEC
