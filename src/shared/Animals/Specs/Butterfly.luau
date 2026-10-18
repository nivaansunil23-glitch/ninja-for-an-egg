-- Butterfly's look (from gaudrians/ButterflyScript.lua, made in Claude Design). Preview: gaudrians/Butterfly.html
-- Parts are { joint, colour, w, h, d, x, y, z, rx, ry, rz }, see Animals/AnimalRig for the format.

local SPEC = {
	Kind = "fly",
	Scale = 2.2,
	WalkSpeed = 3,
	Hover = 3,
	C = {
		dark = { 50, 40, 60 },
		purple = { 155, 111, 214 },
		yellow = { 242, 193, 78 },
	},
	Anim = { FlapSpeed = 9 },
	Eyes = { c = { 255, 255, 255 }, node = "head", s = 0.025, x = 0.02, y = 0.01, z = 0.042 },
	Nodes = {
		{ "body", "root", 0, 0.1, 0 },
		{ "head", "body", 0, 0.02, 0.14 },
		{ "wingL", "body", 0.03, 0.02, 0, m = true },
	},
	Parts = {
		{ "body", "dark", 0.06, 0.06, 0.26, 0, 0, 0 },
		{ "head", "dark", 0.08, 0.08, 0.08, 0, 0, 0 },
		{ "head", "dark", 0.012, 0.1, 0.012, 0.02, 0.08, 0.02, 0, 0, -0.3, m = true },
		{ "wingL", "purple", 0.36, 0.02, 0.24, 0.18, 0, 0.06, m = true },
		{ "wingL", "yellow", 0.1, 0.022, 0.08, 0.24, 0, 0.08, m = true },
		{ "wingL", "purple", 0.24, 0.02, 0.18, 0.13, 0, -0.12, m = true },
	},
}

SPEC.Name = "Butterfly"

return SPEC
