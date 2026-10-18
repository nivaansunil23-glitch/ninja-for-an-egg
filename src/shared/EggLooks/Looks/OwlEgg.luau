--!nonstrict
-- Owl Egg (Forest island, tier 1 of 8: soft matte colours).
-- Feathery brown shell with a pale face patch and ear tufts.
-- From the Claude Design egg pack (eggs/OwlEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 138, 106, 74 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, 0, 0.3545, 1.7479, 2.2723, 1.3269, 0, 0, 0, 232, 199, 122, nil },
		{ "ell", 0.2845, 0.6743, 0.8757, 0.22, 0.055, 0.22, 1.1711, 0.1258, -0.2887, 40, 30, 24, nil },
		{ "ell", -0.2845, 0.6743, 0.8757, 0.22, 0.055, 0.22, 1.1711, -0.1258, 0.2887, 40, 30, 24, nil },
		{ "ell", 0, 0.3494, 1.0286, 0.13, 0.078, 0.13, 1.3675, 0, 0, 245, 166, 35, nil },
		{ "ell", 0.8213, -0.4471, 0.4742, 0.28, 0.05, 0.2, 1.7099, -0.2357, -1.0307, 110, 84, 60, nil },
		{ "ell", 0.934, -0.4471, -0.1647, 0.28, 0.05, 0.2, 1.5222, -0.2687, -1.7519, 110, 84, 60, nil },
		{ "ell", 0.6096, -0.4471, -0.7265, 0.28, 0.05, 0.2, 1.3595, -0.1742, -2.462, 110, 84, 60, nil },
		{ "ell", 0, -0.4471, -0.9484, 0.28, 0.05, 0.2, 1.2978, 0, -3.1416, 110, 84, 60, nil },
		{ "ell", -0.6096, -0.4471, -0.7265, 0.28, 0.05, 0.2, 1.3595, 0.1742, 2.462, 110, 84, 60, nil },
		{ "ell", -0.934, -0.4471, -0.1647, 0.28, 0.05, 0.2, 1.5222, 0.2687, 1.7519, 110, 84, 60, nil },
		{ "ell", -0.8213, -0.4471, 0.4742, 0.28, 0.05, 0.2, 1.7099, 0.2357, 1.0307, 110, 84, 60, nil },
		{ "box", 0.2051, 1.2547, 0.3237, 0.16, 0.35, 0.16, 1.0414, 1.1778, -1.0887, 110, 84, 60, nil },
		{ "box", -0.2189, 1.2402, 0.3477, 0.16, 0.35, 0.16, 0.3532, 0.2988, 0.6821, 110, 84, 60, nil },
	},
	Light = nil,
	Sparkles = nil,
}
