--!nonstrict
-- Rolls which pet comes out of an egg. Every crack lowers the chance of
-- anything better than Common, or on one-animal eggs makes the pet lighter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggConfig = require(ReplicatedStorage.Shared.EggConfig)

local S = EggConfig.Settings
local rng = Random.new()

local Hatching = {}

local function weightsFor(egg, cracks)
	local luck = S.CrackLuckMultiplier ^ cracks
	local weights, total = {}, 0
	for i, pet in egg.Pets do
		local weight = pet.Chance
		if EggConfig.RarityRank[pet.Rarity] > 1 then
			weight *= luck
		end
		weights[i] = weight
		total += weight
	end
	return weights, total
end

-- Chance of each pet in percent, for egg info / index UI.
function Hatching.GetOdds(eggId, cracks)
	local egg = EggConfig.Eggs[eggId]
	local weights, total = weightsFor(egg, cracks or 0)
	local odds = {}
	for i, pet in egg.Pets do
		table.insert(odds, { Name = pet.Name, Rarity = pet.Rarity, Percent = weights[i] / total * 100 })
	end
	return odds
end

-- Returns a pet table ready for PlayerData.AddPet.
function Hatching.Roll(eggData)
	local egg = EggConfig.Eggs[eggData.EggId]
	local weights, total = weightsFor(egg, eggData.Cracks)

	local chosen = egg.Pets[#egg.Pets]
	local roll = rng:NextNumber() * total
	for i, pet in egg.Pets do
		roll -= weights[i]
		if roll <= 0 then
			chosen = pet
			break
		end
	end

	local weight = eggData.Kg * (chosen.SizeMul or 1) * rng:NextNumber(0.85, 1.25)
	if #egg.Pets == 1 then
		-- One-animal eggs can't roll a worse pet, so cracks shrink the pet
		-- instead (lighter pet = worth less and earns less).
		weight *= S.CrackLuckMultiplier ^ (eggData.Cracks or 0)
	end
	return {
		Name = chosen.Name,
		Rarity = chosen.Rarity,
		Weight = math.floor(weight * 100 + 0.5) / 100,
		Egg = eggData.EggId,
		Value = chosen.Value,
		Cracks = eggData.Cracks,
		HatchedAt = os.time(),
	}
end

return Hatching
