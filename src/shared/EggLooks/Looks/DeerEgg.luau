--!nonstrict
-- Deer Egg (Forest island, tier 1 of 8: soft matte colours).
-- Brown shell with fawn spots and little antlers.
-- From the Claude Design egg pack (eggs/DeerEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 176, 122, 74 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0.3253, 0.4478, 0.8938, 0.22, 0.066, 0.22, 1.3135, 0.0923, -0.3371, 240, 222, 190, nil },
		{ "ell", 0.8763, 0, 0.5059, 0.22, 0.066, 0.22, 1.5708, 0, -1.0472, 240, 222, 190, nil },
		{ "ell", -0.4983, -0.2273, 0.8631, 0.22, 0.066, 0.22, 1.6877, 0.0673, 0.5197, 240, 222, 190, nil },
		{ "ell", 0.824, 0.6548, -0.2999, 0.22, 0.066, 0.22, 1.7215, 0.3913, -1.9498, 240, 222, 190, nil },
		{ "ell", -0.9175, 0.5534, 0, 0.22, 0.066, 0.22, 1.5708, -0.3444, 1.5708, 240, 222, 190, nil },
		{ "ell", 0.3343, -0.3389, -0.9186, 0.22, 0.066, 0.22, 1.3795, -0.0691, -2.7992, 240, 222, 190, nil },
		{ "ell", -0.4983, 0.2273, -0.8631, 0.22, 0.066, 0.22, 1.6877, -0.0673, 2.6219, 240, 222, 190, nil },
		{ "ell", 0, -0.7513, 0.8296, 0.22, 0.066, 0.22, 2.0649, 0, 0, 240, 222, 190, nil },
		{ "box", 0.1532, 1.3078, 0.3039, 0.07, 0.55, 0.07, 0.4275, 0.3523, -0.505, 226, 200, 150, nil },
		{ "box", 0.3718, 1.3315, 0.3188, 0.06, 0.25, 0.06, 0.9592, 0.2279, -1.2717, 226, 200, 150, nil },
		{ "box", -0.1532, 1.3078, 0.3039, 0.07, 0.55, 0.07, 0.4275, -0.3523, 0.505, 226, 200, 150, nil },
		{ "box", -0.3718, 1.3315, 0.3188, 0.06, 0.25, 0.06, 0.9592, -0.2279, 1.2717, 226, 200, 150, nil },
	},
	Light = nil,
	Sparkles = nil,
}
