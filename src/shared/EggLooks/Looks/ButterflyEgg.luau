--!nonstrict
-- Butterfly Egg (Cherry Blossom island, tier 3 of 8: patterns and little accessories).
-- Lilac shell with butterfly wings and softly glowing dots.
-- From the Claude Design egg pack (eggs/ButterflyEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 205, 185, 240 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 1.2094, 0.6762, -0.0628, 0.95, 0.5225, 0.08, 0, 0.2287, 0.6963, 155, 111, 214, nil },
		{ "ell", 1.1838, -0.3805, -0.0505, 0.6, 0.33, 0.08, 0, 0.2278, -0.1946, 180, 140, 230, nil },
		{ "ell", -1.2699, 0.3205, -0.0769, 0.95, 0.5225, 0.08, -3.1416, 0.2287, 2.7907, 155, 111, 214, nil },
		{ "ell", -1.1761, -0.2628, -0.0487, 0.6, 0.33, 0.08, -3.1416, 0.2278, -2.8126, 180, 140, 230, nil },
		{ "ell", 0, 0.6536, 0.8741, 0.14, 0.049, 0.14, 1.1528, 0, 0, 255, 225, 110, "Neon" },
		{ "ell", 0.6386, -0.2269, 0.7611, 0.14, 0.049, 0.14, 1.6743, -0.0865, -0.6936, 255, 225, 110, "Neon" },
		{ "ell", -0.6386, -0.2269, 0.7611, 0.14, 0.049, 0.14, 1.6743, 0.0865, 0.6936, 255, 225, 110, "Neon" },
		{ "ell", 0, 0.447, -0.9482, 0.14, 0.049, 0.14, 1.8438, 0, -3.1416, 255, 225, 110, "Neon" },
		{ "ell", 0.4974, 1.0018, -0.4174, 0.14, 0.049, 0.14, 2.1033, 0.5441, -2.4208, 255, 225, 110, "Neon" },
		{ "ell", -0.4974, 1.0018, -0.4174, 0.14, 0.049, 0.14, 2.1033, -0.5441, 2.4208, 255, 225, 110, "Neon" },
	},
	Light = { Color = { 210, 170, 255 }, Brightness = 0.6, Range = 6, Pulse = false },
	Sparkles = nil,
}
