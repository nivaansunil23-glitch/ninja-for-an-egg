--!nonstrict
-- Lookup of every pet by name, built from EggConfig. The sell shop reads
-- PetData[petName].Value; use PetData.GetValue(pet) for a pet's weighted value.

local EggConfig = require(script.Parent.EggConfig)

local PetData = {}

for eggId, egg in EggConfig.Eggs do
	for _, pet in egg.Pets do
		PetData[pet.Name] = {
			Name = pet.Name,
			Rarity = pet.Rarity,
			Egg = eggId,
			Value = pet.Value,
			SizeMul = pet.SizeMul,
		}
	end
end

-- Heavier pets are worth more. pet is a saved pet table with Name and Weight.
function PetData.GetValue(pet)
	local info = PetData[pet.Name]
	if type(info) ~= "table" then
		return 0
	end
	return math.floor(info.Value * math.max(1, pet.Weight or 1) ^ 0.5)
end

return PetData
