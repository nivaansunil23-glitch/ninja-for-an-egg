-- Vertex tiers sold in the Vertex shop. Jump power comes from training on the
-- trampoline (JumpBalance); a vertex multiplies it, so a better vertex jumps
-- higher at the same level. Tier 1 is owned from the start.
-- Prices and multipliers are placeholders.

local VertexConfig = {}

VertexConfig.Tiers = {
	{ Name = "Wooden Vertex", Price = 0, Multiplier = 1, Color = Color3.fromRGB(205, 150, 95) },
	{ Name = "Bubble Vertex", Price = 250, Multiplier = 1.04, Color = Color3.fromRGB(255, 140, 205) },
	{ Name = "Mint Vertex", Price = 1000, Multiplier = 1.08, Color = Color3.fromRGB(110, 235, 175) },
	{ Name = "Sky Vertex", Price = 5000, Multiplier = 1.12, Color = Color3.fromRGB(100, 190, 255) },
	{ Name = "Crystal Vertex", Price = 20000, Multiplier = 1.16, Color = Color3.fromRGB(175, 120, 255) },
	{ Name = "Sunburst Vertex", Price = 75000, Multiplier = 1.2, Color = Color3.fromRGB(255, 190, 60) },
	{ Name = "Galaxy Vertex", Price = 250000, Multiplier = 1.25, Color = Color3.fromRGB(70, 60, 150) },
}

function VertexConfig.Get(tier: number?)
	return if tier then VertexConfig.Tiers[tier] else nil
end

-- Jump power multiplier for a tier (1 if unknown).
function VertexConfig.Multiplier(tier: number?): number
	local entry = VertexConfig.Get(tier)
	return if entry then entry.Multiplier else 1
end

-- Short text for the shop, e.g. "x1.08 Jump".
function VertexConfig.PerkText(entry): string
	return `x{entry.Multiplier} Jump`
end

return VertexConfig
