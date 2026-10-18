--!nonstrict
-- Walrus Egg (Snow island, tier 4 of 8: icy shine and a soft glow).
-- Brown shell with tusks, a whiskery muzzle and an ice crystal crown.
-- From the Claude Design egg pack (eggs/WalrusEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 138, 106, 85 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0.2423, 0.1822, 0.972, 0.32, 0.064, 0.32, 1.4663, 0.026, -0.243, 200, 160, 130, nil },
		{ "ell", -0.2423, 0.1822, 0.972, 0.32, 0.064, 0.32, 1.4663, -0.026, 0.243, 200, 160, 130, nil },
		{ "ell", 0.2192, -0.2028, 1.0313, 0.1, 0.6, 0.1, 2.8742, -0.2022, -0.055, 239, 230, 210, nil },
		{ "ell", -0.2192, -0.2028, 1.0313, 0.1, 0.6, 0.1, 2.8742, 0.2022, 0.055, 239, 230, 210, nil },
		{ "box", -0.0093, 1.3216, 0.212, 0.12, 0.34, 0.12, 3.0507, -0.7468, 2.8909, 180, 225, 255, "Glass" },
		{ "box", 0.2014, 1.3222, 0.059, 0.12, 0.34, 0.12, 3.1102, -0.7869, -3.0387, 180, 225, 255, "Glass" },
		{ "box", 0.1204, 1.3186, -0.188, 0.12, 0.34, 0.12, 2.7053, -0.8253, 3.0903, 180, 225, 255, "Glass" },
		{ "box", -0.1388, 1.3156, -0.188, 0.12, 0.34, 0.12, 2.4545, -0.6514, 2.7212, 180, 225, 255, "Glass" },
		{ "box", -0.2194, 1.3175, 0.059, 0.12, 0.34, 0.12, 2.6615, -0.6508, 2.5787, 180, 225, 255, "Glass" },
	},
	Light = { Color = { 170, 220, 255 }, Brightness = 0.6, Range = 6, Pulse = false },
	Sparkles = nil,
}
