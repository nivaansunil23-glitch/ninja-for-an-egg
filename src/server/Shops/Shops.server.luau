-- Hooks the shops up to the client and to the shop spots on the map.
--
-- Map spots: every child of Workspace.Map.Shops is a shop. The shop type comes
-- from a "ShopType" attribute ("Vertex", "Gear" or "Sell"), or else from the
-- child's name containing "vert", "gear" or "sell".
--
-- Shopkeepers: the Model named "Shopkeeper" inside a shop (else one named
-- "NPC", else any Model with a Humanoid) gets a "Talk" prompt. Talking opens
-- the conversation on the client (UI/ShopTalk), which then opens the shop.
-- The keeper's root is anchored so it stays put, its idle animation plays
-- here so everyone sees it breathe, and the client does the rest (turning to
-- face you, waving, the name tag).
-- With no shopkeeper, the prompt goes on a part named "PromptPart", else the
-- model's PrimaryPart, else its first part.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local ShopConfig = require(Shared:WaitForChild("Config"):WaitForChild("ShopConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))
local VertexShop = require(script.Parent:WaitForChild("VertexShop"))
local GearShop = require(script.Parent:WaitForChild("GearShop"))
local Wearables = require(script.Parent:WaitForChild("Wearables"))
Wearables.Start()
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

-- TalkToShop starts the conversation; OpenShop opens a shop tab straight away.
local talkToShop = Net.Event("TalkToShop")
Net.Event("OpenShop")

local KEEPER_TAG = "Shopkeeper"

-- Roblox's default idle animations, which any game can use.
local IDLE_ANIMATION = {
	[Enum.HumanoidRigType.R15] = "rbxassetid://507766666",
	[Enum.HumanoidRigType.R6] = "rbxassetid://180435571",
}

local function shopTypeFor(spot: Instance): string?
	local attribute = spot:GetAttribute("ShopType")
	if type(attribute) == "string" and ShopConfig.Shops[attribute] then
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

local function findKeeper(spot: Instance): Model?
	for _, name in { "Shopkeeper", "NPC" } do
		local found = spot:FindFirstChild(name, true)
		if found and found:IsA("Model") and found:FindFirstChildOfClass("Humanoid") then
			return found
		end
	end
	for _, descendant in spot:GetDescendants() do
		if descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then
			return descendant.Parent
		end
	end
	return nil
end

local function keeperRoot(keeper: Model): BasePart?
	local root = keeper:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	if keeper.PrimaryPart then
		return keeper.PrimaryPart
	end
	local head = keeper:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	return keeper:FindFirstChildWhichIsA("BasePart", true)
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

-- Unanchor every part joined to the root (limbs, hats) so animations can move
-- them. Parts that aren't joined to anything stay as they are.
local function freeJointedParts(keeper: Model, root: BasePart)
	local links = {}
	local function link(a: Instance?, b: Instance?)
		if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
			links[a] = links[a] or {}
			links[b] = links[b] or {}
			table.insert(links[a], b)
			table.insert(links[b], a)
		end
	end
	for _, descendant in keeper:GetDescendants() do
		if descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			link(descendant.Part0, descendant.Part1)
		elseif descendant:IsA("AnimationConstraint") or descendant:IsA("RigidConstraint") then
			local a0, a1 = descendant.Attachment0, descendant.Attachment1
			link(a0 and a0.Parent, a1 and a1.Parent)
		end
	end

	local seen = { [root] = true }
	local queue = { root }
	while #queue > 0 do
		local part = table.remove(queue)
		for _, other in links[part] or {} do
			if not seen[other] and other:IsDescendantOf(keeper) then
				seen[other] = true
				other.Anchored = false
				table.insert(queue, other)
			end
		end
	end
end

local function playIdle(humanoid: Humanoid, animator: Animator)
	if humanoid:GetAttribute("NoIdle") or #animator:GetPlayingAnimationTracks() > 0 then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = IDLE_ANIMATION[humanoid.RigType] or IDLE_ANIMATION[Enum.HumanoidRigType.R15]
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Idle
		track.Looped = true
		track:Play()
	end
end

local function prepareKeeper(keeper: Model, shopType: string, spot: Instance)
	local root = keeperRoot(keeper)
	if root then
		root.Anchored = true
		freeJointedParts(keeper, root)
	end

	local humanoid = keeper:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- The client draws a proper name tag; hide the default "Shopkeeper" one.
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		playIdle(humanoid, animator)
	end

	-- One name attribute for the client: the one set in Studio, else the default.
	local name = keeper:GetAttribute("KeeperName") or keeper:GetAttribute("DisplayName") or spot:GetAttribute("KeeperName")
	keeper:SetAttribute("KeeperName", if type(name) == "string" and name ~= "" then name else ShopConfig.Shops[shopType].Keeper)
	keeper:SetAttribute("ShopType", shopType)
	CollectionService:AddTag(keeper, KEEPER_TAG)
end

local function makePrompt(part: BasePart, shopType: string, objectText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = ShopConfig.TalkDistance
	prompt.RequiresLineOfSight = false
	-- The client swaps in its own bubbly prompt for anything with this attribute.
	prompt:SetAttribute("ShopType", shopType)
	prompt.Parent = part
	return prompt
end

local spots = {} -- [spot] = { Prompt = ProximityPrompt, Keeper = Model? }

local function setupSpot(spot: Instance)
	local shopType = shopTypeFor(spot)
	if not shopType then
		return
	end

	local keeper = findKeeper(spot)
	local state = spots[spot]
	if state and state.Keeper == keeper and state.Prompt:IsDescendantOf(spot) then
		return
	end
	if state then
		state.Prompt:Destroy()
		spots[spot] = nil
	end

	local shop = ShopConfig.Shops[shopType]
	local part, objectText = nil, shop.Title
	if keeper then
		prepareKeeper(keeper, shopType, spot)
		part = keeperRoot(keeper)
		objectText = keeper:GetAttribute("KeeperName") or shop.Keeper
	end
	if not part then
		keeper = nil
		part = promptPartFor(spot)
	end
	if not part then
		return
	end

	local prompt = makePrompt(part, shopType, objectText)
	prompt.Triggered:Connect(function(player)
		talkToShop:FireClient(player, shopType, keeper, spot)
	end)
	spots[spot] = { Prompt = prompt, Keeper = keeper }
end

-- Shopkeepers can be added or swapped after the shop exists.
local function watchSpot(spot: Instance)
	setupSpot(spot)

	local queued = false
	local function refreshSoon()
		if queued then
			return
		end
		queued = true
		task.delay(0.5, function()
			queued = false
			if spot.Parent then
				setupSpot(spot)
			end
		end)
	end

	spot.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Humanoid") then
			refreshSoon()
		end
	end)
	spot.DescendantRemoving:Connect(function(descendant)
		local state = spots[spot]
		if state and (descendant == state.Keeper or descendant == state.Prompt) then
			refreshSoon()
		end
	end)
end

-- The map may be built after this runs, so wait for it without a timeout warning.
task.spawn(function()
	local map = Workspace:WaitForChild("Map", math.huge)
	local shops = map:WaitForChild("Shops", math.huge)
	for _, spot in shops:GetChildren() do
		watchSpot(spot)
	end
	shops.ChildAdded:Connect(function(spot)
		task.wait(0.5) -- let the model's parts arrive
		watchSpot(spot)
	end)
	shops.ChildRemoved:Connect(function(spot)
		spots[spot] = nil
	end)
end)
