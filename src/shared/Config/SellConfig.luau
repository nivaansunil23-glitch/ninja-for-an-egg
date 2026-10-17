-- Pet values: what the Selling shop pays and what equipped pets earn per second.
-- Pets the egg code knows (Shared.PetData) sell for PetData.GetValue(pet).
-- Anything else falls back to a rarity base value scaled by weight.
-- Numbers are placeholders.

local SellConfig = {}

SellConfig.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret" }

SellConfig.RarityColors = {
	Common = Color3.fromRGB(175, 175, 190),
	Uncommon = Color3.fromRGB(95, 220, 110),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(175, 95, 255),
	Legendary = Color3.fromRGB(255, 170, 40),
	Secret = Color3.fromRGB(45, 40, 60),
}

SellConfig.BaseValue = {
	Common = 10,
	Uncommon = 35,
	Rare = 120,
	Epic = 450,
	Legendary = 1800,
	Secret = 12000,
}

-- A pet of this weight (kg) sells for exactly its base value; heavier sells for more.
SellConfig.WeightBaseline = 1
SellConfig.MinWeightMultiplier = 0.25
-- Equipped pets earn this share of their sell price every second.
SellConfig.IncomeRatio = 0.02

-- Optional per-pet values from the egg code: ReplicatedStorage.Shared.PetData[petName].Value
local petData = nil
local function getPetData()
	if petData == nil then
		petData = false
		local module = script.Parent.Parent:FindFirstChild("PetData")
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			if ok and type(result) == "table" then
				petData = result
			end
		end
	end
	return petData or nil
end

function SellConfig.GetBaseValue(pet): number
	if type(pet.Value) == "number" then
		return pet.Value
	end
	local data = getPetData()
	local entry = data and data[pet.Name]
	if type(entry) == "table" and type(entry.Value) == "number" then
		return entry.Value
	end
	return SellConfig.BaseValue[pet.Rarity] or SellConfig.BaseValue.Common
end

function SellConfig.GetPrice(pet): number
	-- Prefer the egg code's own weighted value so both sides agree on a pet's worth.
	local data = getPetData()
	if data and type(data.GetValue) == "function" and type(data[pet.Name]) == "table" then
		local ok, value = pcall(data.GetValue, pet)
		if ok and type(value) == "number" and value > 0 then
			return math.floor(value)
		end
	end

	local weight = tonumber(pet.Weight) or SellConfig.WeightBaseline
	local multiplier = math.max(SellConfig.MinWeightMultiplier, weight / SellConfig.WeightBaseline)
	return math.max(1, math.floor(SellConfig.GetBaseValue(pet) * multiplier + 0.5))
end

function SellConfig.GetIncome(pet): number
	return math.max(1, math.floor(SellConfig.GetPrice(pet) * SellConfig.IncomeRatio + 0.5))
end

function SellConfig.RarityIndex(rarity: string?): number
	for index, name in SellConfig.Rarities do
		if name == rarity then
			return index
		end
	end
	return 1
end

return SellConfig
