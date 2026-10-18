--!nonstrict
-- Arctic Fox Egg (Snow island, tier 4 of 8: icy shine and a soft glow).
-- Frosty white shell, ice-blue tipped ears and glowing snowflakes.
-- From the Claude Design egg pack (eggs/ArcticFoxEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 238, 244, 250 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "box", 0.3182, 1.215, 0.3863, 0.34, 0.5, 0.14, 1.502, 1.1536, -1.2874, 238, 244, 250, nil },
		{ "box", 0.4096, 1.4253, 0.4377, 0.2, 0.2, 0.15, 1.502, 1.1536, -1.2874, 150, 200, 245, nil },
		{ "box", -0.3311, 1.2004, 0.4029, 0.34, 0.5, 0.14, 0.4247, 0.1954, 0.6092, 238, 244, 250, nil },
		{ "box", -0.4631, 1.3653, 0.5061, 0.2, 0.2, 0.15, 0.4247, 0.1954, 0.6092, 150, 200, 245, nil },
		{ "box", 0, 0.2268, 0.9928, 0.18, 0.045, 0.18, 1.436, 0.78, 0, 150, 215, 255, "Neon" },
		{ "box", 0.7765, 0.7495, 0.2826, 0.18, 0.045, 0.18, 2.2877, 0.5912, -1.6555, 150, 215, 255, "Neon" },
		{ "box", -0.7765, 0.7495, 0.2826, 0.18, 0.045, 0.18, 0.6786, -0.0763, 0.9786, 150, 215, 255, "Neon" },
		{ "box", 0.4964, -0.2268, -0.8598, 0.18, 0.045, 0.18, 1.9354, -0.7166, -2.4247, 150, 215, 255, "Neon" },
		{ "box", -0.4964, -0.2268, -0.8598, 0.18, 0.045, 0.18, 1.0182, -0.5959, 2.4998, 150, 215, 255, "Neon" },
		{ "box", 0.7262, -0.84, -0.2643, 0.18, 0.045, 0.18, 2.2956, -0.647, -1.4259, 150, 215, 255, "Neon" },
		{ "box", -0.3568, -0.9242, 0.6179, 0.18, 0.045, 0.18, 1.6129, 0.9716, 0.7792, 150, 215, 255, "Neon" },
	},
	Light = { Color = { 150, 210, 255 }, Brightness = 0.8, Range = 8, Pulse = false },
	Sparkles = nil,
}
