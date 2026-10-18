--!nonstrict
-- Panda Egg (Cherry Blossom island, tier 3 of 8: patterns and little accessories).
-- White shell with panda ears, eye patches and a bamboo leaf.
-- From the Claude Design egg pack (eggs/PandaEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 244, 244, 242 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, -0.4577, 0, 1.8379, 1.7206, 1.8379, 0, 0, 0, 43, 43, 43, nil },
		{ "ell", 0.3506, 0.4897, 0.8678, 0.425, 0.051, 0.34, 1.4971, 0.5729, -0.4397, 43, 43, 43, nil },
		{ "ell", 0.346, 0.5323, 0.8565, 0.1, 0.06, 0.1, 1.2633, 0.1217, -0.3651, 255, 255, 255, nil },
		{ "ell", 0.2297, 1.2541, 0.2738, 0.28, 0.24, 0.16, 0.5533, 0.62, -0.3446, 43, 43, 43, nil },
		{ "ell", -0.3506, 0.4897, 0.8678, 0.425, 0.051, 0.34, 1.4971, -0.5729, 0.4397, 43, 43, 43, nil },
		{ "ell", -0.346, 0.5323, 0.8565, 0.1, 0.06, 0.1, 1.2633, -0.1217, 0.3651, 255, 255, 255, nil },
		{ "ell", -0.2297, 1.2541, 0.2738, 0.28, 0.24, 0.16, 0.5533, -0.62, 0.3446, 43, 43, 43, nil },
		{ "ell", -0.1259, 1.3495, 0.0716, 0.06, 0.5, 0.18, 2.9089, 0.0458, -2.8086, 110, 200, 90, nil },
	},
	Light = nil,
	Sparkles = nil,
}
