--!nonstrict
-- Penguin Egg (Snow island, tier 4 of 8: icy shine and a soft glow).
-- Glossy black shell, white tummy, orange beak and blush cheeks.
-- From the Claude Design egg pack (eggs/PenguinEgg.html is the preview).
-- Built by Shared.EggLooks; units and fields are explained there.
return {
	Shell = { 37, 48, 58 },
	ShellMaterial = "SmoothPlastic",
	-- { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material }
	--   shape "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
	Parts = {
		{ "ell", 0, 0, 0.3183, 1.8186, 2.3641, 1.3994, 0, 0, 0, 244, 244, 242, nil },
		{ "ell", 0, 0.6779, 0.9288, 0.169, 0.104, 0.13, 1.1528, 0, 0, 245, 160, 50, nil },
		{ "ell", 0.412, 0.5018, 0.8836, 0.14, 0.028, 0.14, 1.2962, 0.1258, -0.4189, 245, 170, 180, nil },
		{ "ell", -0.412, 0.5018, 0.8836, 0.14, 0.028, 0.14, 1.2962, -0.1258, 0.4189, 245, 170, 180, nil },
		{ "box", 0, 1.345, 0, 0.18, 0.3, 0.18, -3.1416, -0.78, -3.1416, 120, 200, 255, "Glass" },
	},
	Light = { Color = { 150, 210, 255 }, Brightness = 0.5, Range = 6, Pulse = false },
	Sparkles = nil,
}
