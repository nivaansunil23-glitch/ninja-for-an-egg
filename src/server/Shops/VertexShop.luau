-- Vertex shop: buy the next vertex tier to multiply your trained jump power.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VertexConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("VertexConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))

local VertexShop = {}

function VertexShop.Buy(player: Player, tier): (boolean, string)
	if type(tier) ~= "number" then
		return false, "Invalid vertex"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again"
	end
	local entry = VertexConfig.Get(tier)
	if not entry then
		return false, "Unknown vertex"
	end
	if tier <= data.VertexTier then
		return false, "You already own this vertex"
	end
	if tier ~= data.VertexTier + 1 then
		return false, `Buy the {VertexConfig.Get(data.VertexTier + 1).Name} first`
	end
	if not PlayerData.SpendMoney(player, entry.Price) then
		return false, "Not enough money"
	end

	data.VertexTier = tier
	PlayerData.MarkDirty(player)
	return true, `Unlocked the {entry.Name}! {VertexConfig.PerkText(entry)}`
end

return VertexShop
