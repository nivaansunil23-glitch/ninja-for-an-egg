-- Pet inventory actions from the client: equip/unequip and "Equip Best".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local PlayerConfig = require(Shared.Config:WaitForChild("PlayerConfig"))
local SellConfig = require(Shared.Config:WaitForChild("SellConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local function countEquipped(data): number
	local count = 0
	for _, pet in data.Pets do
		if pet.Equipped then
			count += 1
		end
	end
	return count
end

Net.Function("EquipPet").OnServerInvoke = function(player, petId, equipped)
	if type(petId) ~= "string" then
		return false, "Invalid pet"
	end
	local data = PlayerData.Get(player)
	local pet = data and data.Pets[petId]
	if not pet then
		return false, "Pet not found"
	end

	equipped = equipped == true
	if equipped and not pet.Equipped and countEquipped(data) >= PlayerConfig.MaxEquippedPets then
		return false, `You can only equip {PlayerConfig.MaxEquippedPets} pets`
	end
	pet.Equipped = equipped
	PlayerData.MarkDirty(player)
	return true
end

Net.Function("EquipBest").OnServerInvoke = function(player)
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading"
	end

	local ids = {}
	for id in data.Pets do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return SellConfig.GetIncome(data.Pets[a]) > SellConfig.GetIncome(data.Pets[b])
	end)
	for index, id in ids do
		data.Pets[id].Equipped = index <= PlayerConfig.MaxEquippedPets
	end
	PlayerData.MarkDirty(player)
	return true, "Equipped your best pets!"
end
