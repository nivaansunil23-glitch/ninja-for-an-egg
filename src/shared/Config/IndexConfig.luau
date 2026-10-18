-- Pet Index areas and rewards. One area per island (EggConfig.Islands), in
-- island order, holding that island's animals from most common to rarest.
-- Finding every pet of an area lets you claim its reward once: money plus
-- some jump levels. Reward numbers are placeholders until the balance pass.

local EggConfig = require(script.Parent.Parent:WaitForChild("EggConfig"))

local IndexConfig = {}

IndexConfig.MoneyPerValue = 20 -- reward money = this x the sum of the area's pet values
IndexConfig.JumpLevelsPerArea = 5 -- reward jump levels = this x the area number

IndexConfig.Areas = {}
for _, island in EggConfig.Islands do
	local pets, valueSum = {}, 0
	for _, animal in island.Animals do
		local egg = EggConfig.Eggs[EggConfig.EggIdFor(animal.Name)]
		local pet = egg.Pets[1]
		table.insert(pets, pet)
		valueSum += pet.Value
	end
	table.insert(IndexConfig.Areas, {
		Id = island.Id,
		Name = island.Name,
		Color = island.Color,
		Pets = pets,
		ValueSum = valueSum,
		Number = island.Number,
	})
end
table.sort(IndexConfig.Areas, function(a, b)
	return a.Number < b.Number
end)
for number, area in IndexConfig.Areas do
	area.Number = number
	area.RewardMoney = area.ValueSum * IndexConfig.MoneyPerValue
	area.RewardJumpLevels = number * IndexConfig.JumpLevelsPerArea
end

function IndexConfig.GetArea(id: string)
	for _, area in IndexConfig.Areas do
		if area.Id == id then
			return area
		end
	end
	return nil
end

function IndexConfig.TotalPets(): number
	local total = 0
	for _, area in IndexConfig.Areas do
		total += #area.Pets
	end
	return total
end

-- How many of an area's pets are in a found-set ({ [petName] = true }).
function IndexConfig.FoundIn(area, found): number
	local count = 0
	for _, pet in area.Pets do
		if found and found[pet.Name] then
			count += 1
		end
	end
	return count
end

return IndexConfig
