-- Pet Index areas and rewards. One area per egg, in island order (lowest
-- grow time first = Forest, Beach, Blossom...). Finding every pet of an area
-- lets you claim its reward once: money plus some jump levels.
-- Reward numbers are placeholders until the balance pass.

local EggConfig = require(script.Parent.Parent:WaitForChild("EggConfig"))

local IndexConfig = {}

IndexConfig.MoneyPerValue = 20 -- reward money = this x the sum of the area's pet values
IndexConfig.JumpLevelsPerArea = 5 -- reward jump levels = this x the area number

IndexConfig.Areas = {}
for eggId, egg in EggConfig.Eggs do
	local valueSum = 0
	for _, pet in egg.Pets do
		valueSum += pet.Value
	end
	table.insert(IndexConfig.Areas, {
		Id = eggId,
		Name = (egg.DisplayName:gsub(" Egg$", "")),
		Color = egg.Color,
		Pets = egg.Pets,
		GrowSeconds = egg.GrowSeconds or 0,
		ValueSum = valueSum,
	})
end
table.sort(IndexConfig.Areas, function(a, b)
	if a.GrowSeconds ~= b.GrowSeconds then
		return a.GrowSeconds < b.GrowSeconds
	end
	return a.Id < b.Id
end)
for number, area in IndexConfig.Areas do
	area.Number = number
	area.RewardMoney = area.ValueSum * IndexConfig.MoneyPerValue
	area.RewardJumpLevels = number * IndexConfig.JumpLevelsPerArea
end

function IndexConfig.GetArea(eggId: string)
	for _, area in IndexConfig.Areas do
		if area.Id == eggId then
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
