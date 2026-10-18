--!nonstrict
-- Turtle Egg (Beach island, tier 2 of 8: two-tone and patterns).
-- Green shell with darker hex plates and a sandy base.
-- From the Claude Design egg pack (eggs/TurtleEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 78, 154, 91 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, -0.4045, 0, 1.9081, 1.8271, 1.9081, 0, 0, 0, 232, 214, 150, nil },
		{ "cyl", 0, 0.6535, 0.8739, 0.048, 0.4, 0.4, 1.1528, 0, 1.5708, 52, 112, 66, nil },
		{ "cyl", 0.7568, 0.6535, 0.437, 0.048, 0.4, 0.4, 1.3523, 0.3592, 0.5634, 52, 112, 66, nil },
		{ "cyl", 0.7568, 0.6535, -0.437, 0.048, 0.4, 0.4, 1.7893, 0.3592, -0.5634, 52, 112, 66, nil },
		{ "cyl", 0, 0.6535, -0.8739, 0.048, 0.4, 0.4, 1.9887, 0, -1.5708, 52, 112, 66, nil },
		{ "cyl", -0.7568, 0.6535, -0.437, 0.048, 0.4, 0.4, 1.7893, -0.3592, -2.5782, 52, 112, 66, nil },
		{ "cyl", -0.7568, 0.6535, 0.437, 0.048, 0.4, 0.4, 1.3523, -0.3592, 2.5782, 52, 112, 66, nil },
		{ "cyl", 0.5043, 0, 0.8735, 0.048, 0.4, 0.4, 1.5708, 0, 1.0472, 52, 112, 66, nil },
		{ "cyl", 1.0086, 0, 0, 0.048, 0.4, 0.4, 1.5708, 0, 0, 52, 112, 66, nil },
		{ "cyl", 0.5043, 0, -0.8735, 0.048, 0.4, 0.4, 1.5708, 0, -1.0472, 52, 112, 66, nil },
		{ "cyl", -0.5043, 0, -0.8735, 0.048, 0.4, 0.4, 1.5708, 0, -2.0944, 52, 112, 66, nil },
		{ "cyl", -1.0086, 0, 0, 0.048, 0.4, 0.4, 1.5708, 0, -3.1416, 52, 112, 66, nil },
		{ "cyl", -0.5043, 0, 0.8735, 0.048, 0.4, 0.4, 1.5708, 0, 2.0944, 52, 112, 66, nil },
		{ "cyl", 0, 1.2294, 0.3457, 0.048, 0.4, 0.4, 0.4419, 0, 1.5708, 52, 112, 66, nil },
	},
	Light = nil,
	Sparkles = nil,
}
