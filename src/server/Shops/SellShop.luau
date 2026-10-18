-- Selling shop: sell pets for money. Price depends on rarity and weight
-- (see SellConfig). Equipped pets are skipped so nobody sells their best by accident.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local SellConfig = require(Config:WaitForChild("SellConfig"))
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))

local SellShop = {}

function SellShop.Sell(player: Player, petIds): (boolean, string, number)
	if type(petIds) ~= "table" then
		return false, "Nothing selected", 0
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again", 0
	end

	local total, count = 0, 0
	for index = 1, math.min(#petIds, PlayerConfig.MaxSellPerRequest) do
		local id = petIds[index]
		local pet = type(id) == "string" and data.Pets[id]
		if pet and not pet.Equipped then
			total += SellConfig.GetPrice(pet)
			data.Pets[id] = nil
			count += 1
		end
	end

	if count == 0 then
		return false, "Nothing to sell (equipped pets are skipped)", 0
	end

	data.Stats.PetsSold += count
	total = math.floor(total * (player:GetAttribute("CashMultiplier") or 1)) -- pen upgrades
	PlayerData.AddMoney(player, total)
	PlayerData.MarkDirty(player)
	return true, `Sold {count} pet{if count == 1 then "" else "s"} for ${total}!`, total
end

return SellShop
