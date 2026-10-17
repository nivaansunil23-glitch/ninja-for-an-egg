-- Gear shop: buy gear once, keep it forever. Owned gear is given as Tools
-- (Backpack now, StarterGear for every respawn). Tool behaviour lives in
-- PlayerService (Jump Coil) and the client Jetpack script.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GearConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))

local GearShop = {}

-- Placeholder look until we have real models.
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

function GearShop.Give(player: Player, gearId: string)
	local gear = GearConfig.Items[gearId]
	if not gear then
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
end

function GearShop.Buy(player: Player, gearId): (boolean, string)
	if type(gearId) ~= "string" then
		return false, "Invalid gear"
	end
	local gear = GearConfig.Items[gearId]
	if not gear then
		return false, "Unknown gear"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again"
	end
	if data.Gear[gearId] then
		return false, "You already own this"
	end
	if not PlayerData.SpendMoney(player, gear.Price) then
		return false, "Not enough money"
	end

	data.Gear[gearId] = true
	PlayerData.MarkDirty(player)
	GearShop.Give(player, gearId)
	return true, `Bought the {gear.Name}! Check your hotbar`
end

return GearShop
