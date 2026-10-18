--!nonstrict
-- Dolphin Egg (Beach island, tier 2 of 8: two-tone and patterns).
-- Ocean blue shell with white wave stripes and a dorsal fin.
-- From the Claude Design egg pack (eggs/DolphinEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 110, 159, 196 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, -0.4045, 0, 1.9081, 1.8271, 1.9081, 0, 0, 0, 217, 230, 239, nil },
		{ "ell", 0, 0.1818, 0.998, 0.72, 0.0432, 0.36, 1.4631, 0, 0, 230, 242, 250, nil },
		{ "ell", 0.6915, 0.3159, 0.6915, 0.72, 0.0432, 0.36, 1.436, 0.1336, -0.7764, 230, 242, 250, nil },
		{ "ell", 0.9988, 0.1739, 0, 0.72, 0.0432, 0.36, 1.5708, 0.103, -1.5708, 230, 242, 250, nil },
		{ "ell", 0.7122, 0.0461, -0.7122, 0.72, 0.0432, 0.36, 1.59, 0.0192, -2.3564, 230, 242, 250, nil },
		{ "ell", 0, 0.1975, -0.9962, 0.72, 0.0432, 0.36, 1.688, 0, -3.1416, 230, 242, 250, nil },
		{ "ell", -0.6917, 0.3146, -0.6917, 0.72, 0.0432, 0.36, 1.705, -0.133, 2.3651, 230, 242, 250, nil },
		{ "ell", -1.0004, 0.1581, 0, 0.72, 0.0432, 0.36, 1.5708, -0.0935, 1.5708, 230, 242, 250, nil },
		{ "ell", -0.7121, 0.0484, 0.7121, 0.72, 0.0432, 0.36, 1.5506, -0.0202, 0.7852, 230, 242, 250, nil },
		{ "box", 0, 0.7993, -0.8522, 0.07, 0.42, 0.3, 2.5885, 0, -3.1416, 60, 90, 120, nil },
	},
	Light = nil,
	Sparkles = nil,
}
