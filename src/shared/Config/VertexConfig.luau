-- Vertex tiers sold in the Vertex shop. Each tier sets the player's jump power,
-- which is what lets them reach higher islands. Tier 1 is owned from the start.
-- Prices and jump powers are placeholders until the island heights are final.

local VertexConfig = {}

VertexConfig.DefaultJumpPower = 50

VertexConfig.Tiers = {
	{ Name = "Wooden Vertex", Price = 0, JumpPower = 50, Color = Color3.fromRGB(205, 150, 95) },
	{ Name = "Bubble Vertex", Price = 250, JumpPower = 70, Color = Color3.fromRGB(255, 140, 205) },
	{ Name = "Mint Vertex", Price = 1000, JumpPower = 95, Color = Color3.fromRGB(110, 235, 175) },
	{ Name = "Sky Vertex", Price = 5000, JumpPower = 125, Color = Color3.fromRGB(100, 190, 255) },
	{ Name = "Crystal Vertex", Price = 20000, JumpPower = 160, Color = Color3.fromRGB(175, 120, 255) },
	{ Name = "Sunburst Vertex", Price = 75000, JumpPower = 200, Color = Color3.fromRGB(255, 190, 60) },
	{ Name = "Galaxy Vertex", Price = 250000, JumpPower = 250, Color = Color3.fromRGB(70, 60, 150) },
}

function VertexConfig.Get(tier: number?)
	return if tier then VertexConfig.Tiers[tier] else nil
end

return VertexConfig
