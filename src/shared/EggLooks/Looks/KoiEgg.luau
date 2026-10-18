--!nonstrict
-- Koi Egg (Cherry Blossom island, tier 3 of 8: patterns and little accessories).
-- Pearl-white shell with koi patches and a flowing tail fin on top.
-- From the Claude Design egg pack (eggs/KoiEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 243, 241, 236 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0.2978, 0.652, 0.8181, 0.46, 0.0276, 0.46, 1.1754, 0.1393, -0.3211, 232, 86, 46, nil },
		{ "ell", -0.9404, -0.1136, 0.3423, 0.42, 0.0252, 0.42, 1.5938, 0.0631, 1.221, 232, 86, 46, nil },
		{ "ell", 0.7234, 0.4459, -0.607, 0.44, 0.0264, 0.44, 1.7489, 0.208, -2.2876, 232, 86, 46, nil },
		{ "ell", -0.2975, -0.6518, -0.8175, 0.4, 0.024, 0.4, 1.1754, 0.1393, 2.8205, 232, 86, 46, nil },
		{ "ell", 0.6659, -0.8375, 0.3845, 0.32, 0.0192, 0.32, 1.883, -0.4889, -0.9687, 232, 86, 46, nil },
		{ "ell", -0.1974, 1.0689, 0.5424, 0.3, 0.03, 0.3, 0.7695, -0.2557, 0.2403, 30, 30, 30, nil },
		{ "ell", 0, 1.3279, -0.2384, 0.06, 0.5, 0.4, -2.8659, 0, 3.1416, 245, 200, 180, nil },
		{ "ell", 1.039, 0, -0.0225, 0.05, 0.3, 0.25, 1.5708, 0, -2.0944, 245, 200, 180, nil },
		{ "ell", -1.039, 0, -0.0225, 0.05, 0.3, 0.25, 1.5708, 0, 2.0944, 245, 200, 180, nil },
	},
	Light = nil,
	Sparkles = nil,
}
