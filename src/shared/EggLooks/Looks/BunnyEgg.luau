--!nonstrict
-- Bunny Egg (Forest island, tier 1 of 8: soft matte colours).
-- Cream shell with floppy bunny ears and soft spots.
-- From the Claude Design egg pack (eggs/BunnyEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 242, 236, 226 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0.501, 0.2281, 0.8677, 0.32, 0.096, 0.32, 1.4539, 0.0673, -0.5197, 246, 205, 214, nil },
		{ "ell", -0.7067, -0.5552, 0.593, 0.32, 0.096, 0.32, 1.7974, 0.2616, 0.8427, 246, 205, 214, nil },
		{ "ell", 0.4782, 0.4493, -0.8282, 0.32, 0.096, 0.32, 1.8087, 0.1352, -2.6342, 246, 205, 214, nil },
		{ "ell", 0.7687, -0.845, -0.1355, 0.32, 0.096, 0.32, 1.4592, -0.5634, -1.7777, 246, 205, 214, nil },
		{ "ell", -0.8777, 0.1145, -0.5067, 0.32, 0.096, 0.32, 1.6044, -0.0582, 2.0954, 246, 205, 214, nil },
		{ "ell", 0.224, 1.3183, 0.3184, 0.22, 0.75, 0.12, 0.5, 0.469, -0.5562, 242, 236, 226, nil },
		{ "ell", -0.224, 1.3183, 0.3184, 0.22, 0.75, 0.12, 0.5, -0.469, 0.5562, 242, 236, 226, nil },
		{ "ell", 0.2487, 1.3634, 0.3288, 0.12, 0.55, 0.13, 0.5, 0.469, -0.5562, 246, 165, 186, nil },
		{ "ell", -0.2487, 1.3634, 0.3288, 0.12, 0.55, 0.13, 0.5, -0.469, 0.5562, 246, 165, 186, nil },
	},
	Light = nil,
	Sparkles = nil,
}
