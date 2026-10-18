-- Bubble Gum Sim style: chunky font, thick dark outlines, bright gradients.

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.Outline = Color3.fromRGB(45, 25, 70)
Theme.Text = Color3.fromRGB(255, 255, 255)
-- Small text on light panels (descriptions, dialogue) that reads without an outline.
Theme.DarkText = Color3.fromRGB(70, 45, 110)

-- { top, bottom } gradient pairs
Theme.Colors = {
	Pink = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(240, 80, 165) },
	Mint = { Color3.fromRGB(130, 245, 190), Color3.fromRGB(35, 200, 135) },
	Sky = { Color3.fromRGB(130, 210, 255), Color3.fromRGB(50, 140, 245) },
	Yellow = { Color3.fromRGB(255, 230, 105), Color3.fromRGB(255, 170, 35) },
	Orange = { Color3.fromRGB(255, 190, 110), Color3.fromRGB(255, 120, 45) },
	Purple = { Color3.fromRGB(205, 155, 255), Color3.fromRGB(140, 80, 235) },
	Red = { Color3.fromRGB(255, 135, 135), Color3.fromRGB(230, 65, 90) },
	Gray = { Color3.fromRGB(205, 205, 215), Color3.fromRGB(140, 140, 160) },
	Panel = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(238, 238, 248) },
	Row = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(242, 234, 255) },
}

-- Placeholder pet art until pet models/icons exist.
Theme.RarityIcon = {
	Common = "🐣",
	Uncommon = "🐥",
	Rare = "🐾",
	Epic = "🦄",
	Legendary = "🐉",
	Secret = "👾",
}

-- Soft drop shadow under panels and buttons.
Theme.Shadow = Color3.fromRGB(30, 15, 55)

-- Gradient with a darker "lip" along the bottom edge, so buttons look chunky
-- and pressable (like BGSI buttons) without any extra frames.
function Theme.LipSequence(colors): ColorSequence
	local top, bottom = colors[1], colors[2]
	local lip = bottom:Lerp(Color3.new(0, 0, 0), 0.22)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.74, bottom),
		ColorSequenceKeypoint.new(0.78, lip),
		ColorSequenceKeypoint.new(1, lip),
	})
end

-- Gradient pair for a single color (lighter top, the color at the bottom).
function Theme.FromColor(color: Color3)
	return { color:Lerp(Color3.new(1, 1, 1), 0.35), color }
end

-- Very light tint of a color, for card backgrounds.
function Theme.Tint(color: Color3)
	return { Color3.new(1, 1, 1), color:Lerp(Color3.new(1, 1, 1), 0.72) }
end

return Theme
