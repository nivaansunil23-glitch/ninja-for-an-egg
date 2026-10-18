--!nonstrict
-- Fox Egg (Forest island, tier 1 of 8: soft matte colours).
-- Orange shell with a white belly and pointy dark-tipped ears.
-- From the Claude Design egg pack (eggs/FoxEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 232, 120, 44 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, -0.379, 0, 1.9397, 1.8781, 1.9397, 0, 0, 0, 248, 242, 232, nil },
		{ "box", 0.3182, 1.215, 0.3863, 0.34, 0.5, 0.14, 1.502, 1.1536, -1.2874, 232, 120, 44, nil },
		{ "box", 0.4096, 1.4253, 0.4377, 0.2, 0.2, 0.15, 1.502, 1.1536, -1.2874, 58, 40, 34, nil },
		{ "box", -0.3311, 1.2004, 0.4029, 0.34, 0.5, 0.14, 0.4247, 0.1954, 0.6092, 232, 120, 44, nil },
		{ "box", -0.4631, 1.3653, 0.5061, 0.2, 0.2, 0.15, 0.4247, 0.1954, 0.6092, 58, 40, 34, nil },
		{ "ell", 0, -0.7106, -0.8957, 0.3, 0.45, 0.3, 0.4547, 0, -3.1416, 248, 242, 232, nil },
	},
	Light = nil,
	Sparkles = nil,
}
