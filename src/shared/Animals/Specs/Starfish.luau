-- Starfish's look (from gaudrians/StarfishScript.lua, made in Claude Design). Preview: gaudrians/Starfish.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "crawl",
	Scale = 3,
	WalkSpeed = 1.5,
	C = {
		light = { 247, 194, 107 },
		orange = { 240, 138, 60 },
	},
	Anim = { Bob = 0.005, Leg = 0.35, SleepDrop = 0.01, Stride = 0.3 },
	Eyes = { node = "body", s = 0.035, x = 0.04, y = 0.02, z = 0.121 },
	Nodes = {
		{ "body", "root", 0, 0.05, 0 },
		{ "leg1", "root", 0, 0.04, 0, ph = 1, ry = 0.63 },
		{ "leg2", "root", 0, 0.04, 0, ph = -1, ry = 1.88 },
		{ "leg3", "root", 0, 0.04, 0, ph = 1, ry = 3.14 },
		{ "leg4", "root", 0, 0.04, 0, ph = -1, ry = 4.4 },
		{ "leg5", "root", 0, 0.04, 0, ph = 1, ry = 5.65 },
	},
	Parts = {
		{ "body", "orange", 0.24, 0.1, 0.24, 0, 0, 0 },
		{ "body", "light", 0.08, 0.02, 0.08, 0, 0.055, 0 },
		{ "leg1", "orange", 0.13, 0.07, 0.26, 0, 0, 0.17 },
		{ "leg2", "orange", 0.13, 0.07, 0.26, 0, 0, 0.17 },
		{ "leg3", "orange", 0.13, 0.07, 0.26, 0, 0, 0.17 },
		{ "leg4", "orange", 0.13, 0.07, 0.26, 0, 0, 0.17 },
		{ "leg5", "orange", 0.13, 0.07, 0.26, 0, 0, 0.17 },
		{ "leg1", "light", 0.04, 0.02, 0.04, 0, 0.04, 0.2 },
		{ "leg2", "light", 0.04, 0.02, 0.04, 0, 0.04, 0.2 },
		{ "leg3", "light", 0.04, 0.02, 0.04, 0, 0.04, 0.2 },
		{ "leg4", "light", 0.04, 0.02, 0.04, 0, 0.04, 0.2 },
		{ "leg5", "light", 0.04, 0.02, 0.04, 0, 0.04, 0.2 },
	},
}

SPEC.Name = "Starfish"

return SPEC
