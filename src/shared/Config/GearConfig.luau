-- Items sold in the Gear shop (the Gear Guy). Prices are placeholders ("can be
-- discussed later").
--
-- Two upgrade lines, bought in order (tier 2 needs tier 1 and so on), kept
-- forever, and worn automatically (your best one of each, or the one you
-- picked in the Inventory: data.EquippedShoes / EquippedCoil), no holding:
--   Shoes  go on your feet. Each tier lets you fall further while carrying an
--          egg before it cracks (SafeFall studs added to the safe drop, EggCarry).
--   Coil   a spring on your back. Each tier adds jump power (JumpMultiplier).
-- Looks per tier are in Colors / Style (server Shops/Wearables builds them).
-- The Jetpack is kept for later but isn't sold (Hidden).

local GearConfig = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

GearConfig.Lines = {
	Shoes = { Name = "Shoes", Order = 1, Icon = "Shoe" },
	Coil = { Name = "Coils", Order = 2, Icon = "Coil" },
}

GearConfig.Items = {
	-- Shoes ------------------------------------------------------------------
	Shoes1 = {
		Line = "Shoes", Tier = 1, Name = "Sneakers", Rarity = "Common", Price = 150, SafeFall = 6,
		Colors = { Main = rgb(245, 245, 250), Sole = rgb(70, 140, 255), Accent = rgb(70, 140, 255) },
	},
	Shoes2 = {
		Line = "Shoes", Tier = 2, Name = "Trail Runners", Rarity = "Common", Price = 800, SafeFall = 14,
		Colors = { Main = rgb(90, 200, 110), Sole = rgb(60, 60, 70), Accent = rgb(255, 230, 90) },
	},
	Shoes3 = {
		Line = "Shoes", Tier = 3, Name = "Spring Boots", Rarity = "Uncommon", Price = 4000, SafeFall = 28,
		Colors = { Main = rgb(255, 150, 60), Sole = rgb(190, 195, 210), Accent = rgb(255, 255, 255) },
		Style = { Springs = true },
	},
	Shoes4 = {
		Line = "Shoes", Tier = 4, Name = "Cloud Hoppers", Rarity = "Rare", Price = 20000, SafeFall = 50,
		Colors = { Main = rgb(150, 210, 255), Sole = rgb(255, 255, 255), Accent = rgb(255, 255, 255) },
		Style = { Cloud = true },
	},
	Shoes5 = {
		Line = "Shoes", Tier = 5, Name = "Feather Boots", Rarity = "Epic", Price = 90000, SafeFall = 80,
		Colors = { Main = rgb(255, 205, 70), Sole = rgb(170, 110, 40), Accent = rgb(255, 255, 255) },
		Style = { Wings = true },
	},
	Shoes6 = {
		Line = "Shoes", Tier = 6, Name = "Rocket Kicks", Rarity = "Legendary", Price = 400000, SafeFall = 130,
		Colors = { Main = rgb(225, 50, 50), Sole = rgb(40, 40, 50), Accent = rgb(255, 160, 40) },
		Style = { Fins = true },
	},
	Shoes7 = {
		Line = "Shoes", Tier = 7, Name = "Galaxy Boots", Rarity = "Secret", Price = 1800000, SafeFall = 200,
		Colors = { Main = rgb(90, 50, 170), Sole = rgb(30, 20, 60), Accent = rgb(150, 230, 255) },
		Style = { Wings = true, Glow = true },
	},

	-- Coils ------------------------------------------------------------------
	Coil1 = {
		Line = "Coil", Tier = 1, Name = "Copper Coil", Rarity = "Common", Price = 120, JumpMultiplier = 1.05,
		Colors = { Main = rgb(205, 125, 70), Accent = rgb(120, 70, 40) },
	},
	Coil2 = {
		Line = "Coil", Tier = 2, Name = "Steel Coil", Rarity = "Common", Price = 600, JumpMultiplier = 1.1,
		Colors = { Main = rgb(190, 200, 215), Accent = rgb(90, 100, 120) },
	},
	Coil3 = {
		Line = "Coil", Tier = 3, Name = "Mint Coil", Rarity = "Uncommon", Price = 3000, JumpMultiplier = 1.15,
		Colors = { Main = rgb(110, 235, 170), Accent = rgb(40, 140, 100) },
	},
	Coil4 = {
		Line = "Coil", Tier = 4, Name = "Sky Coil", Rarity = "Rare", Price = 15000, JumpMultiplier = 1.22,
		Colors = { Main = rgb(110, 190, 255), Accent = rgb(255, 255, 255) },
	},
	Coil5 = {
		Line = "Coil", Tier = 5, Name = "Golden Coil", Rarity = "Epic", Price = 70000, JumpMultiplier = 1.3,
		Colors = { Main = rgb(255, 205, 60), Accent = rgb(200, 130, 30) },
	},
	Coil6 = {
		Line = "Coil", Tier = 6, Name = "Ruby Coil", Rarity = "Legendary", Price = 300000, JumpMultiplier = 1.4,
		Colors = { Main = rgb(235, 50, 80), Accent = rgb(255, 180, 190) },
		Style = { Glow = true },
	},
	Coil7 = {
		Line = "Coil", Tier = 7, Name = "Galaxy Coil", Rarity = "Secret", Price = 1500000, JumpMultiplier = 1.5,
		Colors = { Main = rgb(120, 70, 220), Accent = rgb(150, 230, 255) },
		Style = { Glow = true },
	},

	-- Kept for later, not sold -------------------------------------------------
	Jetpack = {
		Id = "Jetpack",
		Name = "Jetpack",
		Rarity = "Epic",
		Hidden = true,
		Price = 500,
		Description = "Hold jump in the air to blast upward.",
		Color = rgb(255, 120, 130),
		HandleSize = Vector3.new(1.2, 1.6, 0.8),
		Fuel = 2.5, -- seconds of thrust
		ThrustSpeed = 45, -- upward speed while thrusting
		RefuelPerSecond = 1.25, -- fuel seconds regained per second on the ground
	},
	JumpCoil = {
		-- The old one-off held coil. Not sold; old saves just keep the tool.
		Id = "JumpCoil",
		Name = "Jump Coil",
		Rarity = "Rare",
		Hidden = true,
		Price = 300,
		Description = "Hold it for +30% jump power.",
		Color = rgb(120, 220, 255),
		HandleSize = Vector3.new(1.4, 1, 1),
		JumpMultiplier = 1.3,
	},
}

-- Fill in the shared fields for the shoe and coil tiers.
for id, item in GearConfig.Items do
	item.Id = id
	if item.Line then
		item.Color = item.Colors.Main
		item.Icon = GearConfig.Lines[item.Line].Icon
		if item.Line == "Shoes" then
			item.Description = `Fall {item.SafeFall} studs further with an egg before it cracks.`
		else
			item.Description = `+{math.floor((item.JumpMultiplier - 1) * 100 + 0.5)}% jump power, worn on your back.`
		end
	end
end

-- Everything sold, shoes first then coils, each in tier order.
function GearConfig.List()
	local list = {}
	for _, item in GearConfig.Items do
		if not item.Hidden then
			table.insert(list, item)
		end
	end
	table.sort(list, function(a, b)
		local la, lb = GearConfig.Lines[a.Line].Order, GearConfig.Lines[b.Line].Order
		if la ~= lb then
			return la < lb
		end
		return a.Tier < b.Tier
	end)
	return list
end

-- The item of a line at a tier (nil if there isn't one).
function GearConfig.Get(line: string, tier: number)
	for _, item in GearConfig.Items do
		if item.Line == line and item.Tier == tier then
			return item
		end
	end
	return nil
end

-- Best tier owned in a line (0 = none). owned = data.Gear ({ [id] = true }).
function GearConfig.BestTier(owned, line: string): number
	local best = 0
	for id, has in owned or {} do
		local item = GearConfig.Items[id]
		if has and item and item.Line == line and item.Tier > best then
			best = item.Tier
		end
	end
	return best
end

-- The tier you wear in a line: the one you picked (equipped, from the
-- Inventory) if you own it, else your best (0 = none).
function GearConfig.UsedTier(owned, line: string, equipped: number?): number
	local item = type(equipped) == "number" and equipped >= 1 and GearConfig.Get(line, equipped)
	if item and owned and owned[item.Id] then
		return equipped :: number
	end
	return GearConfig.BestTier(owned, line)
end

return GearConfig
