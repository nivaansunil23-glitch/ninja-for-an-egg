-- Gear shop: Shoes and Coils, each a line of tiers bought in order and kept
-- forever (data.Gear[itemId] = true). Your best of each is worn automatically
-- (Shops/Wearables puts them on and sets the stat attributes). Old one-off gear
-- (Jetpack, the held Jump Coil) isn't sold any more; anyone who owns it still
-- gets it as a Tool (Backpack now, StarterGear for every respawn).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GearConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))
local JumpPower = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("JumpPower"))
local Wearables = require(script.Parent:WaitForChild("Wearables"))

local GearShop = {}

-- Placeholder look for the old held tools.
local function buildTool(gear): Tool
	local tool = Instance.new("Tool")
	tool.Name = gear.Name
	tool.ToolTip = gear.Description
	tool.CanBeDropped = false
	tool:SetAttribute("GearId", gear.Id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = gear.HandleSize
	handle.Color = gear.Color
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	if gear.Id == "JumpCoil" then
		handle.Shape = Enum.PartType.Cylinder
	end
	handle.Parent = tool

	return tool
end

local function hasGear(container: Instance?, gearId: string): boolean
	if not container then
		return false
	end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("GearId") == gearId then
			return true
		end
	end
	return false
end

-- Gives an owned held tool (only the old gear has one).
function GearShop.Give(player: Player, gearId: string)
	local gear = GearConfig.Items[gearId]
	if not gear or not gear.HandleSize then
		return
	end
	local starterGear = player:FindFirstChild("StarterGear")
	if starterGear and not hasGear(starterGear, gearId) then
		buildTool(gear).Parent = starterGear
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack and not hasGear(backpack, gearId) and not hasGear(player.Character, gearId) then
		buildTool(gear).Parent = backpack
	end
end

function GearShop.GiveOwned(player: Player, data)
	for gearId, owned in data.Gear do
		if owned then
			GearShop.Give(player, gearId)
		end
	end
	Wearables.Refresh(player)
	JumpPower.Refresh(player)
end

function GearShop.Buy(player: Player, gearId): (boolean, string)
	if type(gearId) ~= "string" then
		return false, "Invalid gear"
	end
	local gear = GearConfig.Items[gearId]
	if not gear or gear.Hidden then
		return false, "That isn't sold here"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again"
	end
	if data.Gear[gearId] then
		return false, "You already own this"
	end
	if gear.Tier > 1 then
		local before = GearConfig.Get(gear.Line, gear.Tier - 1)
		if before and not data.Gear[before.Id] then
			return false, `Get the {before.Name} first`
		end
	end
	if not PlayerData.SpendMoney(player, gear.Price) then
		return false, "Not enough money"
	end

	data.Gear[gearId] = true
	PlayerData.MarkDirty(player)
	Wearables.Refresh(player)
	JumpPower.Refresh(player)
	return true, if gear.Line == "Shoes" then `Bought {gear.Name}! They're on your feet` else `Bought the {gear.Name}! It's on your back`
end

-- Admin: own every tier (true) or none (false).
function GearShop.SetAll(player: Player, own: boolean)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	for id, item in GearConfig.Items do
		if item.Line then
			data.Gear[id] = if own then true else nil
		end
	end
	PlayerData.MarkDirty(player)
	Wearables.Refresh(player)
	JumpPower.Refresh(player)
end

return GearShop
