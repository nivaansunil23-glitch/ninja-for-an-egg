--!nonstrict
-- Phoenix Chick Egg (Volcano island, tier 7 of 8: glowing lava, embers and a pulsing light).
-- Blazing red-gold shell with a flame crest, fire feathers and embers.
-- From the Claude Design egg pack (eggs/PhoenixChickEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 232, 67, 46 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, -0.4045, 0, 1.9081, 1.8271, 1.9081, 0, 0, 0, 255, 190, 60, "Neon" },
		{ "ell", -0.0432, 1.3507, 0.0738, 0.12, 0.42, 0.08, -3.0521, -0.0013, 2.6038, 255, 120, 30, "Neon" },
		{ "ell", -0.0181, 1.3762, 0.0769, 0.12, 0.54, 0.08, -3.0511, -0.0004, 2.9623, 255, 200, 60, "Neon" },
		{ "ell", 0.0181, 1.3762, 0.0769, 0.12, 0.54, 0.08, -3.0511, 0.0004, -2.9623, 255, 120, 30, "Neon" },
		{ "ell", 0.0432, 1.3507, 0.0738, 0.12, 0.42, 0.08, -3.0521, 0.0013, -2.6038, 255, 200, 60, "Neon" },
		{ "ell", 1.2924, 0.27, -0.0684, 0.9, 0.495, 0.1, 0, 0.2269, 0.476, 255, 150, 50, "Neon" },
		{ "ell", 1.3597, 0.1742, -0.0839, 0.765, 0.18, 0.11, 0, 0.2269, 0.1618, 255, 220, 90, "Neon" },
		{ "ell", 1.3256, 0.0614, -0.076, 0.675, 0.18, 0.11, 0, 0.2269, -0.1523, 255, 220, 90, "Neon" },
		{ "ell", 1.2625, -0.0243, -0.0615, 0.585, 0.18, 0.11, 0, 0.2269, -0.4665, 255, 220, 90, "Neon" },
		{ "ell", -1.3212, 0.0379, -0.075, 0.9, 0.495, 0.1, -3.1416, 0.2269, 2.9194, 255, 150, 50, "Neon" },
		{ "ell", -1.3629, 0.148, -0.0847, 0.765, 0.18, 0.11, -3.1416, 0.2269, -3.0496, 255, 220, 90, "Neon" },
		{ "ell", -1.3023, 0.2484, -0.0707, 0.675, 0.18, 0.11, -3.1416, 0.2269, -2.7354, 255, 220, 90, "Neon" },
		{ "ell", -1.2203, 0.3151, -0.0517, 0.585, 0.18, 0.11, -3.1416, 0.2269, -2.4213, 255, 220, 90, "Neon" },
		{ "ell", 0, 0.5552, 0.9226, 0.12, 0.096, 0.12, 1.2264, 0, 0, 255, 220, 90, "Neon" },
	},
	Light = { Color = { 255, 150, 50 }, Brightness = 2.2, Range = 12, Pulse = true },
	Sparkles = { Color = { 255, 190, 70 }, Rate = 12, Size = 0.3, Speed = 1.5, Lifetime = 1.4 },
}
