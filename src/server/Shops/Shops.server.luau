-- Hooks the shops up to the client and to the shop spots on the map.
--
-- Map spots: every child of Workspace.Map.Shops gets an "Open" prompt.
-- The shop type comes from a "ShopType" attribute ("Vertex", "Gear" or "Sell"),
-- or else from the child's name containing "vert", "gear" or "sell".
-- The prompt goes on a part named "PromptPart" if there is one, else the
-- model's PrimaryPart, else its first part.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))
local VertexShop = require(script.Parent:WaitForChild("VertexShop"))
local GearShop = require(script.Parent:WaitForChild("GearShop"))
local SellShop = require(script.Parent:WaitForChild("SellShop"))

Net.Function("BuyVertex").OnServerInvoke = VertexShop.Buy
Net.Function("BuyGear").OnServerInvoke = GearShop.Buy
Net.Function("SellPets").OnServerInvoke = SellShop.Sell

-- Hand out owned gear when a profile loads.
PlayerData.Loaded:Connect(GearShop.GiveOwned)
for _, player in Players:GetPlayers() do
	local data = PlayerData.Get(player)
	if data then
		GearShop.GiveOwned(player, data)
	end
end

local openShop = Net.Event("OpenShop")

local PROMPT_TEXT = {
	Vertex = "Vertex Shop",
	Gear = "Gear Shop",
	Sell = "Sell Pets",
}

local function shopTypeFor(spot: Instance): string?
	local attribute = spot:GetAttribute("ShopType")
	if PROMPT_TEXT[attribute] then
		return attribute
	end
	local name = spot.Name:lower()
	if name:find("vert") then
		return "Vertex"
	elseif name:find("gear") then
		return "Gear"
	elseif name:find("sell") then
		return "Sell"
	end
	return nil
end

local function promptPartFor(spot: Instance): BasePart?
	if spot:IsA("BasePart") then
		return spot
	end
	local named = spot:FindFirstChild("PromptPart", true)
	if named and named:IsA("BasePart") then
		return named
	end
	if spot:IsA("Model") and spot.PrimaryPart then
		return spot.PrimaryPart
	end
	return spot:FindFirstChildWhichIsA("BasePart", true)
end

local function setupSpot(spot: Instance)
	local shopType = shopTypeFor(spot)
	local part = shopType and promptPartFor(spot)
	if not part or part:FindFirstChild("ShopPrompt") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = PROMPT_TEXT[shopType]
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		openShop:FireClient(player, shopType)
	end)
end

-- The map may be built after this runs, so wait for it without a timeout warning.
task.spawn(function()
	local map = Workspace:WaitForChild("Map", math.huge)
	local shops = map:WaitForChild("Shops", math.huge)
	for _, spot in shops:GetChildren() do
		setupSpot(spot)
	end
	shops.ChildAdded:Connect(function(spot)
		task.wait(0.5) -- let the model's parts arrive
		setupSpot(spot)
	end)
end)
