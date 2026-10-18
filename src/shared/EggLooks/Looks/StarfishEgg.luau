--!nonstrict
-- Starfish Egg (Beach island, tier 2 of 8: two-tone and patterns).
-- Sea-blue shell with an orange starfish stuck on the front.
-- From the Claude Design egg pack (eggs/StarfishEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 130, 205, 220 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, 0.4491, 0.9949, 0.2, 0.08, 0.42, -1.7056, 0, -3.1416, 240, 138, 60, nil },
		{ "ell", 0.2092, 0.2985, 1.0153, 0.2, 0.08, 0.42, -1.7056, 1.2566, -3.1416, 240, 138, 60, nil },
		{ "ell", 0.1293, 0.0548, 1.0484, 0.2, 0.08, 0.42, 1.436, 0.6283, 0, 240, 138, 60, nil },
		{ "ell", -0.1293, 0.0548, 1.0484, 0.2, 0.08, 0.42, 1.436, -0.6283, 0, 240, 138, 60, nil },
		{ "ell", -0.2092, 0.2985, 1.0153, 0.2, 0.08, 0.42, -1.7056, -1.2566, -3.1416, 240, 138, 60, nil },
		{ "ell", 0, 0.2311, 1.0244, 0.26, 0.1, 0.26, 1.436, 0, 0, 247, 194, 107, nil },
		{ "ell", 0.8752, -0.6541, 0, 0.14, 0.056, 0.14, 1.5708, -0.4179, -1.5708, 255, 255, 255, nil },
		{ "ell", -0.8921, 0.4473, -0.3247, 0.14, 0.056, 0.14, 1.6663, -0.2561, 1.9322, 255, 255, 255, nil },
		{ "ell", 0.1345, 0.8411, -0.7627, 0.14, 0.056, 0.14, 2.137, 0.0943, -2.9945, 255, 255, 255, nil },
		{ "ell", 0.4978, -0.8411, -0.5933, 0.14, 0.056, 0.14, 1.1116, -0.3561, -2.5275, 255, 255, 255, nil },
	},
	Light = nil,
	Sparkles = nil,
}
