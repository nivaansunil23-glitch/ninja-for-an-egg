-- Hedgehog's look (from gaudrians/HedgehogScript.lua, made in Claude Design). Preview: gaudrians/Hedgehog.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "quad",
	Scale = 3.2,
	WalkSpeed = 3.5,
	C = {
		dark = { 84, 62, 48 },
		face = { 230, 210, 181 },
		nose = { 40, 30, 30 },
		spikes = { 122, 92, 69 },
	},
	Anim = { Bob = 0.02, HeadSleep = 0.08, Leg = 0.9, SleepDrop = 0.07, Stride = 0.35 },
	Eyes = { node = "head", s = 0.04, x = 0.06, y = 0.05, z = 0.152 },
	Nodes = {
		{ "body", "root", 0, 0.12, 0 },
		{ "head", "body", 0, 0.06, 0.2 },
		{ "earL", "head", 0.1, 0.12, 0.04, m = true },
		{ "legFL", "root", 0.11, 0.08, 0.13, m = true },
		{ "legBL", "root", 0.11, 0.08, -0.13, m = true },
	},
	Parts = {
		{ "body", "spikes", 0.44, 0.32, 0.5, 0, 0.13, -0.02 },
		{ "body", "dark", 0.12, 0.12, 0.12, 0.12, 0.3, 0.06, 0.6, 0.6, 0, m = true },
		{ "body", "dark", 0.12, 0.12, 0.12, 0, 0.32, -0.07, 0.6, 0.6, 0 },
		{ "body", "dark", 0.12, 0.12, 0.12, 0.15, 0.25, -0.18, 0.6, 0.6, 0, m = true },
		{ "body", "dark", 0.1, 0.1, 0.1, 0, 0.28, 0.14, 0.6, 0.6, 0 },
		{ "body", "dark", 0.1, 0.1, 0.1, 0, 0.22, -0.26, 0.6, 0.6, 0 },
		{ "head", "face", 0.26, 0.22, 0.18, 0, 0.02, 0.06 },
		{ "head", "face", 0.12, 0.1, 0.12, 0, -0.02, 0.18 },
		{ "head", "nose", 0.05, 0.045, 0.03, 0, 0, 0.25 },
		{ "earL", "face", 0.05, 0.05, 0.03, 0, 0, 0, m = true },
		{ "legFL", "dark", 0.07, 0.08, 0.07, 0, -0.04, 0, m = true },
		{ "legBL", "dark", 0.07, 0.08, 0.07, 0, -0.04, 0, m = true },
	},
}

SPEC.Name = "Hedgehog"

return SPEC
