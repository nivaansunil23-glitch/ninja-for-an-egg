-- Jump Balance: how high you can jump and how far apart everything is, kept in
-- one place so it all lines up. Vault note: "Jump Balance".
--
-- Leveling (like Jump for Phonk): bounce on the trampoline, and click while you
-- bounce, to earn Jump XP. XP fills levels and every level adds jump power.
-- Your trampoline tier sets the XP per bounce and click. Your vertex
-- (VertexConfig) multiplies the jump power you trained.
--
-- Gaps: the island gaps grow exponentially. Each gap is built for the jump
-- power that crosses it in about CloudsPerGap cloud jumps, so a bigger gap
-- needs more jump power and its clouds sit higher and further apart.

local Workspace = game:GetService("Workspace")

local JumpBalance = {}

-- Leveling --------------------------------------------------------------------

JumpBalance.BaseJump = 50 -- jump power at level 1 (Roblox's default)
JumpBalance.JumpPerLevel = 3
JumpBalance.MaxLevel = 500

-- XP needed to finish a level = floor(XpBase * XpGrowth ^ (level - 1)):
-- level 1 takes 15 XP and every level after takes 10% more.
JumpBalance.XpBase = 15
JumpBalance.XpGrowth = 1.1

function JumpBalance.XpForLevel(level: number): number
	return math.max(1, math.floor(JumpBalance.XpBase * JumpBalance.XpGrowth ^ (math.max(level, 1) - 1)))
end

function JumpBalance.JumpForLevel(level: number): number
	return JumpBalance.BaseJump + (math.max(level, 1) - 1) * JumpBalance.JumpPerLevel
end

-- The lowest level whose jump power reaches `jump`.
function JumpBalance.LevelForJump(jump: number): number
	return math.max(1, math.ceil((jump - JumpBalance.BaseJump) / JumpBalance.JumpPerLevel) + 1)
end

-- All the XP it takes to get from level 1 up to `level`.
function JumpBalance.TotalXpToLevel(level: number): number
	local total = 0
	for step = 1, level - 1 do
		total += JumpBalance.XpForLevel(step)
	end
	return total
end

-- How many studs a jump power lifts you (Roblox: JumpPower^2 / (2 * gravity)).
function JumpBalance.MaxJumpHeight(jumpPower: number): number
	return jumpPower * jumpPower / (2 * Workspace.Gravity)
end

-- Training --------------------------------------------------------------------

JumpBalance.BounceHeight = 9 -- studs the training trampoline throws you
JumpBalance.MinBounceSeconds = 0.3 -- the server ignores faster bounces
JumpBalance.MaxClicksPerSecond = 10 -- the server ignores extra clicks
JumpBalance.PadSlack = 8 -- studs off the pad that still count (lag)

-- Trampoline upgrades. Everyone starts on the Basic one; every island you
-- reach unlocks a trampoline themed after it, which you train on for the next
-- gap. XpPerBounce is the Jump XP for every bounce and every click. Island =
-- the IslandNumber you must have stood on. Skin = the model in
-- ReplicatedStorage.TrampolineSkins the trampoline shows.
JumpBalance.TrampolineTiers = {
	{ Name = "Basic Trampoline", Skin = "Basic", XpPerBounce = 1, Price = 0, Island = 0, Color = Color3.fromRGB(255, 140, 205) },
	{ Name = "Forest Trampoline", Skin = "Forest", XpPerBounce = 2, Price = 250, Island = 1, Color = Color3.fromRGB(120, 205, 95) },
	{ Name = "Beach Trampoline", Skin = "Beach", XpPerBounce = 3, Price = 1000, Island = 2, Color = Color3.fromRGB(255, 205, 110) },
	{ Name = "Cherry Blossom Trampoline", Skin = "CherryBlossom", XpPerBounce = 5, Price = 4000, Island = 3, Color = Color3.fromRGB(255, 160, 205) },
	-- Islands 4-8 became Snow, Desert, Jungle, Volcano, Candy Sky (2026-10-18).
	{ Name = "Snow Trampoline", Skin = "Ice", XpPerBounce = 10, Price = 15000, Island = 4, Color = Color3.fromRGB(150, 220, 255) },
	{ Name = "Desert Trampoline", Skin = "Desert", XpPerBounce = 20, Price = 50000, Island = 5, Color = Color3.fromRGB(235, 190, 110) },
	{ Name = "Jungle Trampoline", Skin = "Jungle", XpPerBounce = 50, Price = 150000, Island = 6, Color = Color3.fromRGB(70, 170, 80) },
	{ Name = "Volcano Trampoline", Skin = "Volcano", XpPerBounce = 120, Price = 500000, Island = 7, Color = Color3.fromRGB(255, 115, 55) },
	{ Name = "Candy Sky Trampoline", Skin = "Candy", XpPerBounce = 250, Price = 2000000, Island = 8, Color = Color3.fromRGB(255, 115, 185) },
}

function JumpBalance.Tier(tier: number?)
	return JumpBalance.TrampolineTiers[tier or 1] or JumpBalance.TrampolineTiers[1]
end

-- The trampoline you use: the one you equipped if you own it, else your best.
-- owned = TrampolineTier (you own every tier up to it), equipped = EquippedTrampoline.
function JumpBalance.UsedTier(owned: number?, equipped: number?): number
	owned = owned or 1
	if type(equipped) == "number" and equipped >= 1 and equipped <= owned then
		return equipped
	end
	return owned
end

-- Launch trampoline (Workspace.Map.LaunchTrampoline): throws you this many
-- times as high as your normal jump to kick off the climb.
JumpBalance.LaunchHeightMultiplier = 3

-- Gaps ------------------------------------------------------------------------

-- Cloud jumps it takes to cross a gap. A cloud step averages AverageStep times
-- your max jump height (the middle of CloudConfig.StepMin/StepMax), so a gap of
-- height H is built for jump power sqrt(2 * gravity * H / (AverageStep *
-- CloudsPerGap)), rounded up to a whole level.
JumpBalance.CloudsPerGap = 18
JumpBalance.AverageStep = 0.585

-- Island tops from the vault's Map Layout (gap n = 150 x 1.45^(n-1)), only
-- used if the map isn't loaded.
JumpBalance.FallbackIslands = {
	{ Number = 1, Id = "Forest", TopY = 150 },
	{ Number = 2, Id = "Beach", TopY = 367 },
	{ Number = 3, Id = "CherryBlossom", TopY = 682 },
	{ Number = 4, Id = "Snow", TopY = 1139 },
	{ Number = 5, Id = "Desert", TopY = 1802 },
	{ Number = 6, Id = "Jungle", TopY = 2763 },
	{ Number = 7, Id = "Volcano", TopY = 4157 },
	{ Number = 8, Id = "CandySky", TopY = 6178 },
}

function JumpBalance.RequiredJumpForGap(gapHeight: number): number
	local divisor = JumpBalance.AverageStep * JumpBalance.CloudsPerGap
	local raw = math.sqrt(2 * Workspace.Gravity * math.max(gapHeight, 0) / divisor)
	return JumpBalance.JumpForLevel(JumpBalance.LevelForJump(math.max(raw, JumpBalance.BaseJump)))
end

local function groundY(): number
	local value = Workspace:GetAttribute("GroundY")
	return if type(value) == "number" then value else 0
end

-- Height above the base island, the same number BestHeight and the height bar use.
function JumpBalance.HeightOf(y: number): number
	return y - groundY()
end

local function prettyName(id: string): string
	return (id:gsub("(%l)(%u)", "%1 %2"))
end

-- Every island in order with what it takes to reach it:
-- { Number, Id, Name, TopY, Height, Gap, RequiredJump, RequiredLevel, Model }.
-- Reads the live map (Workspace.Map.Islands) when it's there. The cloud
-- spawner writes the RequiredJump it built each gap for onto the island, and
-- that wins over the formula.
function JumpBalance.GetIslands()
	local list = {}
	local map = Workspace:FindFirstChild("Map")
	local islands = map and map:FindFirstChild("Islands")
	if islands then
		for _, island in islands:GetChildren() do
			local number = island:GetAttribute("IslandNumber")
			local top = island:GetAttribute("TopY")
			if type(number) == "number" and type(top) == "number" then
				local id = island:GetAttribute("IslandId") or island:GetAttribute("Theme") or island.Name
				table.insert(list, { Number = number, Id = tostring(id), TopY = top, Model = island })
			end
		end
	end
	if #list == 0 then
		for _, entry in JumpBalance.FallbackIslands do
			table.insert(list, table.clone(entry))
		end
	end
	table.sort(list, function(a, b)
		return a.Number < b.Number
	end)

	local below = groundY()
	for _, island in list do
		island.Name = prettyName(island.Id)
		island.Height = island.TopY - groundY()
		island.Gap = island.TopY - below
		local built = island.Model and island.Model:GetAttribute("RequiredJump")
		island.RequiredJump = if type(built) == "number" then built else JumpBalance.RequiredJumpForGap(island.Gap)
		island.RequiredLevel = JumpBalance.LevelForJump(island.RequiredJump)
		below = island.TopY
	end
	return list
end

-- Height bar milestones, one per island. A milestone is unlocked once the
-- player's BestHeight reaches its Height (or IslandReached reaches its Number).
function JumpBalance.Milestones()
	local list = {}
	for _, island in JumpBalance.GetIslands() do
		table.insert(list, {
			Number = island.Number,
			Name = island.Name,
			Height = island.Height,
			RequiredJump = island.RequiredJump,
			RequiredLevel = island.RequiredLevel,
		})
	end
	return list
end

return JumpBalance
