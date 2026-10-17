-- Bubble Gum Sim style: chunky font, thick dark outlines, bright gradients.

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.Outline = Color3.fromRGB(45, 25, 70)
Theme.Text = Color3.fromRGB(255, 255, 255)

-- { top, bottom } gradient pairs
Theme.Colors = {
	Pink = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(240, 80, 165) },
	Mint = { Color3.fromRGB(130, 245, 190), Color3.fromRGB(35, 200, 135) },
	Sky = { Color3.fromRGB(130, 210, 255), Color3.fromRGB(50, 140, 245) },
	Yellow = { Color3.fromRGB(255, 230, 105), Color3.fromRGB(255, 170, 35) },
	Purple = { Color3.fromRGB(205, 155, 255), Color3.fromRGB(140, 80, 235) },
	Red = { Color3.fromRGB(255, 135, 135), Color3.fromRGB(230, 65, 90) },
	Gray = { Color3.fromRGB(205, 205, 215), Color3.fromRGB(140, 140, 160) },
	Panel = { Color3.fromRGB(255, 250, 253), Color3.fromRGB(236, 225, 255) },
	Row = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(242, 234, 255) },
}

-- Gradient pair for a single color (lighter top, the color at the bottom).
function Theme.FromColor(color: Color3)
	return { color:Lerp(Color3.new(1, 1, 1), 0.35), color }
end

return Theme
