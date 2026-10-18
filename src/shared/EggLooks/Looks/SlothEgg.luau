--!nonstrict
-- Sloth Egg (Jungle island, tier 6 of 8: vines, moss and glowing gems).
-- Mossy shell with glowing mushrooms, moss patches and a sleepy face.
-- From the Claude Design egg pack (eggs/SlothEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 154, 134, 112 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, 0.4577, 0, 1.8379, 1.7206, 1.8379, 0, 0, 0, 90, 140, 70, nil },
		{ "ell", 0.8594, 0.2268, 0.4961, 0.35, 0.042, 0.35, 1.5031, 0.1167, -1.0432, 100, 150, 80, nil },
		{ "ell", -0.9326, -0.4467, -0.1644, 0.35, 0.042, 0.35, 1.5222, 0.2687, 1.7519, 100, 150, 80, nil },
		{ "ell", 0.2824, -0.7492, -0.776, 0.35, 0.042, 0.35, 1.1023, -0.1629, -2.8315, 100, 150, 80, nil },
		{ "ell", 0.2642, -0.8397, 0.7258, 0.35, 0.042, 0.35, 2.116, -0.1866, -0.2968, 100, 150, 80, nil },
		{ "cyl", 0.3215, 1.1923, 0.3832, 0.06, 0.18, 0.06, 0.7341, 0.5571, -0.4452, 230, 220, 200, nil },
		{ "ell", 0.3456, 1.2465, 0.4119, 0.2, 0.08, 0.2, 0.7341, 0.5571, -0.4452, 90, 255, 200, "Neon" },
		{ "cyl", -0.4884, 1.1444, 0.282, 0.06, 0.18, 0.06, 1.019, -0.7372, 0.8294, 230, 220, 200, nil },
		{ "ell", -0.5244, 1.1956, 0.3028, 0.2, 0.08, 0.2, 1.019, -0.7372, 0.8294, 90, 255, 200, "Neon" },
		{ "cyl", 0.1059, 1.1048, -0.6007, 0.06, 0.18, 0.06, 2.3955, 0.1288, -3.0235, 230, 220, 200, nil },
		{ "ell", 0.1136, 1.1536, -0.6444, 0.2, 0.08, 0.2, 2.3955, 0.1288, -3.0235, 90, 255, 200, "Neon" },
		{ "ell", 0, 0, 0.3983, 1.6463, 2.1402, 1.2393, 0, 0, 0, 217, 203, 180, nil },
		{ "ell", 0.2965, 0.4038, 0.9125, 0.192, 0.048, 0.12, 1.2143, -0.3061, -0.3198, 90, 70, 55, nil },
		{ "ell", -0.2965, 0.4038, 0.9125, 0.192, 0.048, 0.12, 1.2143, 0.3061, 0.3198, 90, 70, 55, nil },
	},
	Light = { Color = { 100, 255, 200 }, Brightness = 1.1, Range = 9, Pulse = false },
	Sparkles = nil,
}
