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
	-- Both crack heights are measured past a safe drop that grows with the gaps:
	-- CrackSafeJumps x your jump height + CrackSafeSteps x the biggest cloud step
	-- of the gap you land in. So normal cloud hops never crack, real falls do.
	CrackSafeJumps = 1,
	CrackSafeSteps = 1,
	CrackKnockSeconds = 4, -- a crack knocks you flat this long and the egg falls out of your hands
	CrackLuckMultiplier = 0.6, -- each crack multiplies the chance of every non-Common pet by this
	GroundCheckDistance = 4.5, -- studs below HumanoidRootPart that still count as standing

	-- Carrying and stealing
	CarryHeight = 2.7, -- studs above HumanoidRootPart where the egg's bottom sits (above the head)
	PickupDistance = 10,
	PickupHoldSeconds = 0, -- one press (only Hatch is held, user 2026-10-19)
	StealDistance = 8,
	StealHoldSeconds = 0, -- one press
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
	MaxPenEggs = 6, -- eggs growing in one pen at once (placed anywhere on the floor)
	PenEdgeMargin = 3, -- studs eggs must stay inside the fence
	PenEggSpacing = 4, -- studs between two eggs in a pen
	PenEggGrowTo = 1.7, -- a pen egg grows from 1x to this size as it gets ready to hatch
}

-- Pen upgrade levels. CashMultiplier multiplies all money you earn (pet
-- income and selling). Price = money to reach that level (placeholders).
-- Every pen has the same 6 nests at every level.
EggConfig.PenLevels = {
	{ CashMultiplier = 1, Price = 0 },
	{ CashMultiplier = 1.25, Price = 5000 },
	{ CashMultiplier = 1.5, Price = 25000 },
	{ CashMultiplier = 2, Price = 100000 },
	{ CashMultiplier = 2.5, Price = 500000 },
	{ CashMultiplier = 3, Price = 2000000 },
	{ CashMultiplier = 4, Price = 10000000 },
}

--[[
Islands and their animals (2026-10-18, from the vault's "Island Animals and
Guardians" list). Every animal has its own egg, and that egg always hatches
that animal. Animals are listed from most common to rarest: the rarity and
how often the egg spawns come from the animal's place in the list
(RarityLadders / SpawnLadders below), so to make an animal rarer, move it
further down its island's list.

Island fields:
	Id                the island's IslandId attribute in Workspace.Map.Islands
	Number            IslandNumber (1 = lowest)
	Name              shown in the Pet Index
	Color             Pet Index area colour
	KgMin, KgMax      egg size range for every egg on this island
	GrowSeconds       pen grow time: 5s on Forest, x2.5 per island up
	GrowSecondsPerKg  extra grow time for every kg
	BaseValue         a Common pet's value here; rarer pets get x RarityValue
	Animals           { Name, Color = egg colour, SizeMul? }
]]
EggConfig.Islands = {
	{
		Id = "Forest", Number = 1, Name = "Forest", Color = Color3.fromRGB(110, 190, 90),
		KgMin = 1, KgMax = 6, GrowSeconds = 5, GrowSecondsPerKg = 0.5, BaseValue = 10,
		Animals = {
			{ Name = "Bunny", Color = Color3.fromRGB(242, 238, 230), SizeMul = 0.8 },
			{ Name = "Fox", Color = Color3.fromRGB(232, 120, 44) },
			{ Name = "Deer", Color = Color3.fromRGB(176, 122, 74), SizeMul = 1.3 },
			{ Name = "Owl", Color = Color3.fromRGB(138, 106, 74), SizeMul = 0.8 },
			{ Name = "Squirrel", Color = Color3.fromRGB(194, 96, 46), SizeMul = 0.7 },
			{ Name = "Hedgehog", Color = Color3.fromRGB(122, 92, 69), SizeMul = 0.7 },
		},
	},
	{
		Id = "Beach", Number = 2, Name = "Beach", Color = Color3.fromRGB(245, 205, 120),
		KgMin = 1.5, KgMax = 8, GrowSeconds = 13, GrowSecondsPerKg = 1.3, BaseValue = 20,
		Animals = {
			{ Name = "Turtle", Color = Color3.fromRGB(52, 112, 66) },
			{ Name = "Seagull", Color = Color3.fromRGB(244, 245, 243), SizeMul = 0.8 },
			{ Name = "Starfish", Color = Color3.fromRGB(240, 138, 60), SizeMul = 0.7 },
			{ Name = "Seal", Color = Color3.fromRGB(142, 153, 163), SizeMul = 1.2 },
			{ Name = "Flamingo", Color = Color3.fromRGB(232, 110, 140), SizeMul = 1.1 },
			{ Name = "Dolphin", Color = Color3.fromRGB(110, 159, 196), SizeMul = 1.4 },
		},
	},
	{
		Id = "CherryBlossom", Number = 3, Name = "Cherry Blossom", Color = Color3.fromRGB(255, 170, 210),
		KgMin = 2, KgMax = 10, GrowSeconds = 31, GrowSecondsPerKg = 3, BaseValue = 40,
		Animals = {
			{ Name = "Koi", Color = Color3.fromRGB(245, 130, 60), SizeMul = 0.8 },
			{ Name = "Panda", Color = Color3.fromRGB(244, 244, 242), SizeMul = 1.4 },
			{ Name = "Crane", Color = Color3.fromRGB(245, 245, 245), SizeMul = 1.1 },
			{ Name = "Red Panda", Color = Color3.fromRGB(194, 80, 42) },
			{ Name = "Tanuki", Color = Color3.fromRGB(126, 100, 80) },
			{ Name = "Butterfly", Color = Color3.fromRGB(255, 150, 200), SizeMul = 0.6 },
		},
	},
	{
		Id = "Snow", Number = 4, Name = "Snow", Color = Color3.fromRGB(170, 230, 255),
		KgMin = 2.5, KgMax = 12, GrowSeconds = 78, GrowSecondsPerKg = 8, BaseValue = 80,
		Animals = {
			{ Name = "Penguin", Color = Color3.fromRGB(40, 45, 60), SizeMul = 0.9 },
			{ Name = "Polar Bear", Color = Color3.fromRGB(245, 242, 234), SizeMul = 1.6 },
			{ Name = "Arctic Fox", Color = Color3.fromRGB(243, 245, 247) },
			{ Name = "Snowy Owl", Color = Color3.fromRGB(247, 247, 244), SizeMul = 0.8 },
			{ Name = "Walrus", Color = Color3.fromRGB(138, 106, 85), SizeMul = 1.7 },
		},
	},
	{
		Id = "Desert", Number = 5, Name = "Desert", Color = Color3.fromRGB(235, 190, 110),
		KgMin = 3, KgMax = 14, GrowSeconds = 195, GrowSecondsPerKg = 20, BaseValue = 160,
		Animals = {
			{ Name = "Camel", Color = Color3.fromRGB(201, 154, 94), SizeMul = 1.6 },
			{ Name = "Scorpion", Color = Color3.fromRGB(58, 46, 40), SizeMul = 0.7 },
			{ Name = "Fennec Fox", Color = Color3.fromRGB(232, 195, 143), SizeMul = 0.8 },
			{ Name = "Lizard", Color = Color3.fromRGB(159, 168, 74), SizeMul = 0.8 },
			{ Name = "Vulture", Color = Color3.fromRGB(74, 58, 54), SizeMul = 1.2 },
		},
	},
	{
		Id = "Jungle", Number = 6, Name = "Jungle", Color = Color3.fromRGB(70, 170, 80),
		KgMin = 3.5, KgMax = 16, GrowSeconds = 490, GrowSecondsPerKg = 50, BaseValue = 320,
		Animals = {
			{ Name = "Monkey", Color = Color3.fromRGB(138, 90, 58) },
			{ Name = "Toucan", Color = Color3.fromRGB(35, 35, 35), SizeMul = 0.8 },
			{ Name = "Parrot", Color = Color3.fromRGB(217, 58, 48), SizeMul = 0.8 },
			{ Name = "Jaguar", Color = Color3.fromRGB(227, 163, 62), SizeMul = 1.4 },
			{ Name = "Sloth", Color = Color3.fromRGB(154, 134, 112), SizeMul = 1.1 },
		},
	},
	{
		Id = "Volcano", Number = 7, Name = "Volcano", Color = Color3.fromRGB(200, 40, 30),
		KgMin = 4, KgMax = 18, GrowSeconds = 1220, GrowSecondsPerKg = 120, BaseValue = 640,
		Animals = {
			{ Name = "Salamander", Color = Color3.fromRGB(232, 116, 46), SizeMul = 0.9 },
			{ Name = "Fire Bat", Color = Color3.fromRGB(74, 42, 46), SizeMul = 0.8 },
			{ Name = "Lava Lizard", Color = Color3.fromRGB(255, 110, 40), SizeMul = 1.2 },
			{ Name = "Phoenix Chick", Color = Color3.fromRGB(232, 67, 46), SizeMul = 1.1 },
		},
	},
	{
		-- The top island (summit). Its boss and rebirth tie-in are still to be decided with Kichu.
		Id = "CandySky", Number = 8, Name = "Candy Sky", Color = Color3.fromRGB(255, 140, 210),
		KgMin = 5, KgMax = 25, GrowSeconds = 3050, GrowSecondsPerKg = 300, BaseValue = 1280,
		Animals = {
			{ Name = "Unicorn", Color = Color3.fromRGB(251, 247, 255), SizeMul = 1.4 },
			{ Name = "Cloud Sheep", Color = Color3.fromRGB(255, 255, 255), SizeMul = 1.1 },
			{ Name = "Rainbow Cat", Color = Color3.fromRGB(242, 138, 178) },
			{ Name = "Griffin Chick", Color = Color3.fromRGB(230, 192, 106), SizeMul = 1.2 },
		},
	},
}

-- Rarity of each spot in an island's list, by how many animals it has
-- (first = most common).
EggConfig.RarityLadders = {
	[4] = { "Common", "Rare", "Epic", "Legendary" },
	[5] = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },
	[6] = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret" },
}

-- How often each rarity's egg spawns, as a weight among the island's eggs.
-- With 5 animals: 55 / 28 / 12 / 4 / 1 out of 100.
EggConfig.SpawnWeights = {
	Common = 55,
	Uncommon = 28,
	Rare = 12,
	Epic = 4,
	Legendary = 1,
	Secret = 0.25,
}

-- Pet value = island BaseValue x this.
EggConfig.RarityValue = {
	Common = 1,
	Uncommon = 2.5,
	Rare = 6,
	Epic = 15,
	Legendary = 50,
	Secret = 150,
}

-- "Red Panda" -> "RedPandaEgg"
function EggConfig.EggIdFor(animalName: string): string
	return (animalName:gsub("%s", "")) .. "Egg"
end

--[[
Egg fields (built from EggConfig.Islands below; the old eggs further down are
kept only so eggs and pets in old saves still work):
	DisplayName       shown on the egg
	Island            name of the island model in Workspace.Map.Islands (or its "IslandId" attribute)
	Color             egg color
	KgMin, KgMax      random size range; heavy eggs are rarer
	SpawnWeight       how often this egg is picked among the eggs of the same island
	GrowSeconds       pen grow time before hatching: 5s on Forest, x2.5 per island up
	GrowSecondsPerKg  extra grow time for every kg
	Pets              list of { Name, Rarity, Chance, SizeMul, Value }
	                  Chance is a weight (they don't need to add up to 100)
	                  Value is the base sell/money value, scaled by weight in PetData
	Legacy            true = old egg, never spawns and isn't in the Pet Index
]]
EggConfig.Eggs = {
	ForestEgg = {
		DisplayName = "Forest Egg",
		Island = "Forest",
		Color = Color3.fromRGB(110, 190, 90),
		KgMin = 1,
		KgMax = 6,
		SpawnWeight = 100,
		GrowSeconds = 5,
		GrowSecondsPerKg = 0.5,
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
		GrowSeconds = 13,
		GrowSecondsPerKg = 1.3,
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
		GrowSeconds = 31,
		GrowSecondsPerKg = 3,
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
		GrowSeconds = 78,
		GrowSecondsPerKg = 8,
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
		GrowSeconds = 195,
		GrowSecondsPerKg = 20,
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
		GrowSeconds = 490,
		GrowSecondsPerKg = 50,
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
		GrowSeconds = 1220,
		GrowSecondsPerKg = 120,
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
		GrowSeconds = 3050,
		GrowSecondsPerKg = 300,
		Pets = {
			{ Name = "Ember Lizard", Rarity = "Uncommon", Chance = 50, SizeMul = 0.9, Value = 3000 },
			{ Name = "Magma Hound", Rarity = "Rare", Chance = 32, SizeMul = 1.2, Value = 7500 },
			{ Name = "Ash Griffin", Rarity = "Epic", Chance = 13, SizeMul = 1.5, Value = 19000 },
			{ Name = "Inferno Dragon", Rarity = "Legendary", Chance = 4.5, SizeMul = 2, Value = 64000 },
			{ Name = "Molten King", Rarity = "Secret", Chance = 0.5, SizeMul = 2.2, Value = 250000 },
		},
	},
}

-- Old one-egg-per-island eggs: kept for saves, never spawned.
for _, egg in EggConfig.Eggs do
	egg.Legacy = true
end

-- One egg per animal. EggOrder lists their ids lowest island first, most
-- common first (the admin panel's egg picker uses it).
EggConfig.EggOrder = {}
for _, island in EggConfig.Islands do
	local ladder = EggConfig.RarityLadders[#island.Animals] or EggConfig.RarityLadders[5]
	for i, animal in island.Animals do
		local rarity = ladder[math.min(i, #ladder)]
		local value = math.floor(island.BaseValue * EggConfig.RarityValue[rarity])
		table.insert(EggConfig.EggOrder, EggConfig.EggIdFor(animal.Name))
		EggConfig.Eggs[EggConfig.EggIdFor(animal.Name)] = {
			DisplayName = animal.Name .. " Egg",
			Island = island.Id,
			Color = animal.Color,
			KgMin = island.KgMin,
			KgMax = island.KgMax,
			SpawnWeight = EggConfig.SpawnWeights[rarity],
			GrowSeconds = island.GrowSeconds,
			GrowSecondsPerKg = island.GrowSecondsPerKg,
			Rarity = rarity,
			Pets = {
				{ Name = animal.Name, Rarity = rarity, Chance = 100, SizeMul = animal.SizeMul or 1, Value = value },
			},
		}
	end
end

-- EggIds grouped by island, built from Island fields above (new eggs only).
EggConfig.EggsByIsland = {}
for eggId, egg in EggConfig.Eggs do
	if egg.Legacy then
		continue
	end
	local list = EggConfig.EggsByIsland[egg.Island]
	if not list then
		list = {}
		EggConfig.EggsByIsland[egg.Island] = list
	end
	table.insert(list, eggId)
end

-- How tall (studs) pets stand in the pen, by island number: higher islands =
-- way bigger pets. Each animal's SizeMul changes it a bit (square root, so a
-- 1.6 polar bear is 1.26x and a 0.6 butterfly 0.77x).
EggConfig.PenPetHeights = { 3, 3.8, 4.8, 6, 7.5, 9.5, 12, 15 }

local islandOfAnimal = {}
for _, island in EggConfig.Islands do
	for _, animal in island.Animals do
		islandOfAnimal[animal.Name] = { Number = island.Number, SizeMul = animal.SizeMul or 1 }
	end
end

-- Pen height for an island animal, or nil for old (Legacy) pets.
function EggConfig.PenPetHeight(petName: string): number?
	local found = islandOfAnimal[petName]
	if not found then
		return nil
	end
	local base = EggConfig.PenPetHeights[found.Number] or EggConfig.PenPetHeights[#EggConfig.PenPetHeights]
	return base * math.sqrt(found.SizeMul)
end

function EggConfig.GetEgg(eggId)
	return EggConfig.Eggs[eggId]
end

return EggConfig
