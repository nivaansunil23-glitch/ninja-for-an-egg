--!nonstrict
-- Every number for eggs lives here: which eggs spawn on which island, how big
-- they get, how long they grow, what pets come out and how cracks hurt luck.
-- Times and chances are first guesses. Tune them freely.

local EggConfig = {}

-- Same rarity names the player/shop code uses (SellConfig).
EggConfig.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret" }

EggConfig.RarityRank = {}
for rank, name in EggConfig.Rarities do
	EggConfig.RarityRank[name] = rank
end

EggConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(90, 220, 110),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(175, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Secret = Color3.fromRGB(255, 70, 120),
}

EggConfig.Settings = {
	-- Cracks
	MaxCracks = 3, -- the 3rd crack breaks the egg
	CrackFallStuds = 18, -- falling at least this far gives 1 crack
	BigCrackFallStuds = 45, -- falling at least this far gives 2 cracks
	CrackLuckMultiplier = 0.6, -- each crack multiplies the chance of every non-Common pet by this
	GroundCheckDistance = 4.5, -- studs below HumanoidRootPart that still count as standing

	-- Carrying and stealing
	CarryHeight = 2.7, -- studs above HumanoidRootPart where the egg's bottom sits (above the head)
	PickupDistance = 10,
	PickupHoldSeconds = 0.3,
	StealDistance = 8,
	StealHoldSeconds = 0.6,
	StealCooldownSeconds = 8, -- a thief has to wait this long between steals
	StealProtectSeconds = 5, -- a freshly grabbed or stolen egg can't be stolen for this long
	DroppedEggLifetime = 60, -- eggs dropped on death vanish after this many seconds

	-- Island spawning
	MaxEggsPerIsland = 4, -- an island can override with a "MaxEggs" attribute
	IslandRespawnSeconds = 20,

	-- Look
	EggBaseSize = Vector3.new(2, 2.6, 2),
	EggSizePerKg = 0.08, -- each kg makes the egg 8% bigger

	-- Pens
	PenPromptDistance = 10,
	PetShowSeconds = 6, -- how long the hatched pet stands in the pen
}

-- Pen upgrade levels. Nests = how many nests are unlocked at that level (in
-- NestIndex order). Price = money to reach that level. Prices are placeholders.
-- A level can only be bought if the plot's pen has enough Nest parts for it.
EggConfig.PenLevels = {
	{ Nests = 2, Price = 0 },
	{ Nests = 3, Price = 1000 },
	{ Nests = 4, Price = 5000 },
	{ Nests = 5, Price = 25000 },
	{ Nests = 6, Price = 100000 },
	{ Nests = 7, Price = 500000 },
	{ Nests = 8, Price = 2000000 },
}

--[[
Egg fields:
	DisplayName       shown on the egg
	Island            name of the island model in Workspace.Map.Islands (or its "IslandId" attribute)
	Color             egg color
	KgMin, KgMax      random size range; heavy eggs are rarer
	SpawnWeight       how often this egg is picked among the eggs of the same island
	GrowSeconds       pen grow time before hatching
	GrowSecondsPerKg  extra grow time for every kg
	Pets              list of { Name, Rarity, Chance, SizeMul, Value }
	                  Chance is a weight (they don't need to add up to 100)
	                  Value is the base sell/money value, scaled by weight in PetData
]]
EggConfig.Eggs = {
	ForestEgg = {
		DisplayName = "Forest Egg",
		Island = "Forest",
		Color = Color3.fromRGB(110, 190, 90),
		KgMin = 1,
		KgMax = 6,
		SpawnWeight = 100,
		GrowSeconds = 120,
		GrowSecondsPerKg = 10,
		Pets = {
			{ Name = "Mossy Pup", Rarity = "Common", Chance = 55, SizeMul = 1, Value = 10 },
			{ Name = "Acorn Owl", Rarity = "Uncommon", Chance = 28, SizeMul = 0.8, Value = 25 },
			{ Name = "Mushroom Toad", Rarity = "Rare", Chance = 12, SizeMul = 1.1, Value = 60 },
			{ Name = "Leaf Fox", Rarity = "Epic", Chance = 4, SizeMul = 1.2, Value = 150 },
			{ Name = "Ancient Treant", Rarity = "Legendary", Chance = 1, SizeMul = 1.6, Value = 500 },
		},
	},
	BeachEgg = {
		DisplayName = "Beach Egg",
		Island = "Beach",
		Color = Color3.fromRGB(245, 205, 120),
		KgMin = 1.5,
		KgMax = 8,
		SpawnWeight = 100,
		GrowSeconds = 240,
		GrowSecondsPerKg = 15,
		Pets = {
			{ Name = "Sandy Crab", Rarity = "Common", Chance = 55, SizeMul = 0.9, Value = 20 },
			{ Name = "Coconut Parrot", Rarity = "Uncommon", Chance = 28, SizeMul = 0.8, Value = 50 },
			{ Name = "Surf Turtle", Rarity = "Rare", Chance = 12, SizeMul = 1.2, Value = 120 },
			{ Name = "Coral Seal", Rarity = "Epic", Chance = 4, SizeMul = 1.3, Value = 300 },
			{ Name = "Tide Serpent", Rarity = "Legendary", Chance = 1, SizeMul = 1.8, Value = 1000 },
		},
	},
	BlossomEgg = {
		DisplayName = "Blossom Egg",
		Island = "CherryBlossom",
		Color = Color3.fromRGB(255, 170, 210),
		KgMin = 2,
		KgMax = 10,
		SpawnWeight = 100,
		GrowSeconds = 420,
		GrowSecondsPerKg = 20,
		Pets = {
			{ Name = "Petal Bunny", Rarity = "Common", Chance = 55, SizeMul = 0.9, Value = 40 },
			{ Name = "Koi Kitten", Rarity = "Uncommon", Chance = 28, SizeMul = 1, Value = 100 },
			{ Name = "Lantern Tanuki", Rarity = "Rare", Chance = 12, SizeMul = 1.1, Value = 240 },
			{ Name = "Zen Panda", Rarity = "Epic", Chance = 4, SizeMul = 1.4, Value = 600 },
			{ Name = "Sakura Kitsune", Rarity = "Legendary", Chance = 1, SizeMul = 1.5, Value = 2000 },
		},
	},
	CandyEgg = {
		DisplayName = "Candy Egg",
		Island = "Candy",
		Color = Color3.fromRGB(255, 120, 200),
		KgMin = 2.5,
		KgMax = 12,
		SpawnWeight = 100,
		GrowSeconds = 600,
		GrowSecondsPerKg = 25,
		Pets = {
			{ Name = "Gummy Bear", Rarity = "Common", Chance = 55, SizeMul = 1, Value = 80 },
			{ Name = "Lollipop Lamb", Rarity = "Uncommon", Chance = 28, SizeMul = 1, Value = 200 },
			{ Name = "Cupcake Corgi", Rarity = "Rare", Chance = 12, SizeMul = 1.1, Value = 480 },
			{ Name = "Cotton Candy Unicorn", Rarity = "Epic", Chance = 4, SizeMul = 1.4, Value = 1200 },
			{ Name = "Chocolate Dragon", Rarity = "Legendary", Chance = 1, SizeMul = 1.8, Value = 4000 },
		},
	},
	IceEgg = {
		DisplayName = "Ice Egg",
		Island = "Ice",
		Color = Color3.fromRGB(170, 230, 255),
		KgMin = 3,
		KgMax = 14,
		SpawnWeight = 100,
		GrowSeconds = 900,
		GrowSecondsPerKg = 30,
		Pets = {
			{ Name = "Snow Penguin", Rarity = "Common", Chance = 55, SizeMul = 0.9, Value = 160 },
			{ Name = "Frost Fox", Rarity = "Uncommon", Chance = 28, SizeMul = 1, Value = 400 },
			{ Name = "Polar Cub", Rarity = "Rare", Chance = 12, SizeMul = 1.3, Value = 960 },
			{ Name = "Ice Yeti", Rarity = "Epic", Chance = 4, SizeMul = 1.6, Value = 2400 },
			{ Name = "Glacier Phoenix", Rarity = "Legendary", Chance = 1, SizeMul = 1.5, Value = 8000 },
		},
	},
	CrystalEgg = {
		DisplayName = "Crystal Egg",
		Island = "Crystal",
		Color = Color3.fromRGB(140, 110, 255),
		KgMin = 3.5,
		KgMax = 16,
		SpawnWeight = 100,
		GrowSeconds = 1200,
		GrowSecondsPerKg = 40,
		Pets = {
			{ Name = "Gem Beetle", Rarity = "Common", Chance = 55, SizeMul = 0.8, Value = 320 },
			{ Name = "Quartz Bat", Rarity = "Uncommon", Chance = 28, SizeMul = 0.9, Value = 800 },
			{ Name = "Amethyst Golem", Rarity = "Rare", Chance = 12, SizeMul = 1.5, Value = 1900 },
			{ Name = "Prism Wolf", Rarity = "Epic", Chance = 4, SizeMul = 1.3, Value = 4800 },
			{ Name = "Diamond Wyrm", Rarity = "Legendary", Chance = 1, SizeMul = 1.8, Value = 16000 },
		},
	},
	SpaceEgg = {
		DisplayName = "Space Egg",
		Island = "Space",
		Color = Color3.fromRGB(60, 40, 120),
		KgMin = 4,
		KgMax = 18,
		SpawnWeight = 100,
		GrowSeconds = 1800,
		GrowSecondsPerKg = 50,
		Pets = {
			{ Name = "Moon Mouse", Rarity = "Common", Chance = 55, SizeMul = 0.8, Value = 640 },
			{ Name = "Comet Cat", Rarity = "Uncommon", Chance = 28, SizeMul = 1, Value = 1600 },
			{ Name = "Astro Axolotl", Rarity = "Rare", Chance = 12, SizeMul = 1.1, Value = 3800 },
			{ Name = "Nebula Jelly", Rarity = "Epic", Chance = 4, SizeMul = 1.4, Value = 9600 },
			{ Name = "Galaxy Whale", Rarity = "Legendary", Chance = 0.9, SizeMul = 2, Value = 32000 },
			{ Name = "Void Watcher", Rarity = "Secret", Chance = 0.1, SizeMul = 1.7, Value = 100000 },
		},
	},
	VolcanoEgg = {
		-- The top egg. Its guardian/boss and rebirth tie-in are still to be decided with Kichu.
		DisplayName = "Volcano Egg",
		Island = "Volcano",
		Color = Color3.fromRGB(200, 40, 30),
		KgMin = 5,
		KgMax = 25,
		SpawnWeight = 100,
		GrowSeconds = 3600,
		GrowSecondsPerKg = 60,
		Pets = {
			{ Name = "Ember Lizard", Rarity = "Uncommon", Chance = 50, SizeMul = 0.9, Value = 3000 },
			{ Name = "Magma Hound", Rarity = "Rare", Chance = 32, SizeMul = 1.2, Value = 7500 },
			{ Name = "Ash Griffin", Rarity = "Epic", Chance = 13, SizeMul = 1.5, Value = 19000 },
			{ Name = "Inferno Dragon", Rarity = "Legendary", Chance = 4.5, SizeMul = 2, Value = 64000 },
			{ Name = "Molten King", Rarity = "Secret", Chance = 0.5, SizeMul = 2.2, Value = 250000 },
		},
	},
}

-- EggIds grouped by island, built from Island fields above.
EggConfig.EggsByIsland = {}
for eggId, egg in EggConfig.Eggs do
	local list = EggConfig.EggsByIsland[egg.Island]
	if not list then
		list = {}
		EggConfig.EggsByIsland[egg.Island] = list
	end
	table.insert(list, eggId)
end

function EggConfig.GetEgg(eggId)
	return EggConfig.Eggs[eggId]
end

return EggConfig
