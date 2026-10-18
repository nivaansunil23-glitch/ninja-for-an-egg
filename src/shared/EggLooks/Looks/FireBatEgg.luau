--!nonstrict
-- Fire Bat Egg (Volcano island, tier 7 of 8: glowing lava, embers and a pulsing light).
-- Dark shell with blazing neon bat wings, fangs and ember sparks.
-- From the Claude Design egg pack (eggs/FireBatEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 60, 34, 40 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 1.2728, 0.549, -0.0712, 1, 0.55, 0.08, 0, 0.2278, 0.5936, 255, 120, 30, "Neon" },
		{ "box", 0.2047, 1.2563, 0.3283, 0.2, 0.36, 0.1, 1.0414, 1.1778, -1.0014, 60, 34, 40, nil },
		{ "ell", 0.2835, 0.5534, 0.8724, 0.13, 0.065, 0.13, 1.242, 0.1045, -0.2968, 255, 230, 80, "Neon" },
		{ "ell", -1.3218, 0.2318, -0.0825, 1, 0.55, 0.08, -3.1416, 0.2278, 2.8625, 255, 120, 30, "Neon" },
		{ "box", -0.2162, 1.2442, 0.3482, 0.2, 0.36, 0.1, 0.3532, 0.2988, 0.5948, 60, 34, 40, nil },
		{ "ell", -0.2835, 0.5534, 0.8724, 0.13, 0.065, 0.13, 1.242, -0.1045, 0.2968, 255, 230, 80, "Neon" },
		{ "ell", 0.1043, 0.2275, 0.9922, 0.06, 0.072, 0.06, 1.4367, 0.014, -0.1038, 255, 255, 255, nil },
		{ "ell", -0.1043, 0.2275, 0.9922, 0.06, 0.072, 0.06, 1.4367, -0.014, 0.1038, 255, 255, 255, nil },
	},
	Light = { Color = { 255, 120, 40 }, Brightness = 1.8, Range = 10, Pulse = true },
	Sparkles = { Color = { 255, 140, 40 }, Rate = 8, Size = 0.25, Speed = 1.5, Lifetime = 1.4 },
}
