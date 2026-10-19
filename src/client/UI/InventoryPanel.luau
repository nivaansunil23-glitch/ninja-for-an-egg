-- Inventory window: everything you own, one tab per kind.
--   Pets         tap a pet to equip it; equipped pets earn money every second.
--                "Equip Best" picks the top earners.
--   Shoes/Coils  the gear tiers you bought (Gear shop). Tap one to wear it,
--                "Wear Best" goes back to your best (server Player/Loadout).
--   Vertex       the vertices you bought. Tap one to use it.
--   Trampolines  the trampolines you bought. Tap one to use it (TrainingService).
-- Only owned things show up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local JumpBalance = require(Config:WaitForChild("JumpBalance"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))
local Icons = require(script.Parent:WaitForChild("Icons"))

local player = Players.LocalPlayer

local BAD = Color3.fromRGB(255, 130, 130)
local GOOD = Color3.fromRGB(140, 255, 170)

local STARS = { Epic = 1, Legendary = 2, Secret = 3 }

local TAB_BAR = 48
local HEADER = 50

local TABS = {
	{ Id = "Pets", Text = "Pets", Colors = Theme.Colors.Sky },
	{ Id = "Shoes", Text = "Shoes", Colors = Theme.Colors.Red },
	{ Id = "Coil", Text = "Coils", Colors = Theme.Colors.Orange },
	{ Id = "Vertex", Text = "Vertex", Colors = Theme.Colors.Purple },
	{ Id = "Trampoline", Text = "Trampolines", Colors = Theme.Colors.Pink },
}

local EMPTY = {
	Shoes = "No shoes yet!\nThe Gear Guy sells them.",
	Coil = "No coils yet!\nThe Gear Guy sells them.",
}

local InventoryPanel = {}

-- Everything owned of one kind, best first:
-- { Tier, Name, Perk, Color, Rarity?, Icon }, plus the tier in use.
local function ownedItems(kind: string)
	local data = ClientState.Data or {}
	local list = {}
	local used = 0
	if kind == "Shoes" or kind == "Coil" then
		local owned = data.Gear or {}
		used = GearConfig.UsedTier(owned, kind, data["Equipped" .. kind])
		for _, item in GearConfig.List() do
			if item.Line == kind and owned[item.Id] then
				table.insert(list, {
					Tier = item.Tier,
					Name = item.Name,
					Perk = if kind == "Shoes"
						then `+{item.SafeFall} safe fall`
						else `+{math.floor((item.JumpMultiplier - 1) * 100 + 0.5)}% jump`,
					Color = item.Color,
					Rarity = item.Rarity,
					Icon = item.Icon,
				})
			end
		end
	elseif kind == "Vertex" then
		local best = data.VertexTier or 1
		used = VertexConfig.UsedTier(best, data.EquippedVertex)
		for tier = 1, math.min(best, #VertexConfig.Tiers) do
			local entry = VertexConfig.Tiers[tier]
			table.insert(list, { Tier = tier, Name = entry.Name, Perk = VertexConfig.PerkText(entry), Color = entry.Color, Icon = "Gem" })
		end
	elseif kind == "Trampoline" then
		local best = player:GetAttribute("TrampolineTier") or data.TrampolineTier or 1
		used = JumpBalance.UsedTier(best, player:GetAttribute("EquippedTrampoline") or data.EquippedTrampoline)
		for tier = 1, math.min(best, #JumpBalance.TrampolineTiers) do
			local entry = JumpBalance.TrampolineTiers[tier]
			table.insert(list, {
				Tier = tier,
				Name = entry.Name:gsub(" Trampoline$", ""),
				Perk = `+{entry.XpPerBounce} XP/bounce`,
				Color = entry.Color,
				Icon = "Trampoline",
			})
		end
	end
	table.sort(list, function(a, b)
		return a.Tier > b.Tier
	end)
	return list, used
end

function InventoryPanel.new(gui: ScreenGui)
	local window = Components.Window({
		Name = "Inventory",
		Title = "Inventory",
		Icon = "Bag",
		Parent = gui,
		Colors = Theme.Colors.Sky,
	})
	local content = window.Content
	local busy = false

	local function invoke(remoteName: string, ...)
		if busy then
			return
		end
		busy = true
		local remote = Net.Function(remoteName)
		local ok, success, message = pcall(remote.InvokeServer, remote, ...)
		busy = false
		if not ok then
			Components.Notify(gui, "Something went wrong, try again", BAD)
		elseif message then
			Components.Notify(gui, message, if success then GOOD else BAD)
		end
	end

	-- Tabs ---------------------------------------------------------------------------
	local tabBar = Instance.new("Frame")
	tabBar.Name = "Tabs"
	tabBar.BackgroundTransparency = 1
	tabBar.Size = UDim2.new(1, 0, 0, TAB_BAR)
	tabBar.Parent = content
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar

	local pages, tabButtons, refreshers = {}, {}, {}
	local currentTab = "Pets"

	local function makePage(id: string)
		local page = Instance.new("Frame")
		page.Name = id
		page.BackgroundTransparency = 1
		page.Position = UDim2.fromOffset(0, TAB_BAR + 6)
		page.Size = UDim2.new(1, 0, 1, -(TAB_BAR + 6))
		page.Visible = false
		page.Parent = content
		pages[id] = page
		return page
	end

	local function setTab(id: string)
		currentTab = id
		for tabId, page in pages do
			page.Visible = tabId == id
		end
		for _, tab in TABS do
			local button = tabButtons[tab.Id]
			Components.SetColors(button, if tab.Id == id then tab.Colors else Theme.Colors.Gray)
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness = if tab.Id == id then 4 else 3
			end
		end
		refreshers[id]()
	end

	for order, tab in TABS do
		tabButtons[tab.Id] = Components.Button({
			Name = tab.Id,
			Text = tab.Text,
			Parent = tabBar,
			Size = UDim2.new(if tab.Id == "Trampoline" then 0.24 else 0.175, -7, 0, 42),
			Colors = tab.Colors,
			LayoutOrder = order,
			MaxTextSize = 22,
			OnClick = function()
				setTab(tab.Id)
			end,
		})
	end

	-- Shared card look: square card in a colour, icon on top, three lines of text
	-- and a green tick on the one in use.
	local function makeCard(grid: GuiObject, order: number, color: Color3, inUse: boolean, onClick)
		local card = Instance.new("TextButton")
		card.Text = ""
		card.AutoButtonColor = false
		card.LayoutOrder = order
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		Components.Corner(card, UDim.new(0, 12))
		local stroke = Components.Stroke(card, if inUse then 5 else 4)
		if inUse then
			stroke.Color = Theme.Colors.Mint[2]
		end
		Components.Gradient(card, { color:Lerp(Color3.new(1, 1, 1), 0.3), color })
		Components.Shine(card, 0.25)
		local scale = Instance.new("UIScale")
		scale.Parent = card
		card.MouseEnter:Connect(function()
			scale.Scale = 1.05
		end)
		card.MouseLeave:Connect(function()
			scale.Scale = 1
		end)
		if inUse then
			local badge = Components.Box({
				Parent = card,
				Size = UDim2.fromOffset(34, 34),
				Position = UDim2.new(1, 8, 0, -8),
				AnchorPoint = Vector2.new(1, 0),
				Colors = Theme.Colors.Mint,
				CornerRadius = UDim.new(1, 0),
				ZIndex = 2,
			})
			Icons.Make("Check", badge, {
				Size = UDim2.fromOffset(26, 26),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 3,
			})
		end
		card.Activated:Connect(onClick)
		card.Parent = grid
		return card
	end

	local function cardText(card: GuiObject, text: string, y: number, height: number, color: Color3?)
		Components.Label({
			Text = text,
			Parent = card,
			Size = UDim2.new(1, -10, 0, height),
			Position = UDim2.new(0.5, 0, 0, y),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = color,
			MaxTextSize = height - 3,
		})
	end

	local function stars(card: GuiObject, rarity: string?)
		for i = 1, STARS[rarity or ""] or 0 do
			Icons.Make("Star", card, {
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.fromOffset(4 + (i - 1) * 16, 4),
				ZIndex = 3,
			})
		end
	end

	-- Pets page ------------------------------------------------------------------------
	do
		local page = makePage("Pets")
		local header = Instance.new("Frame")
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, 0, 0, HEADER)
		header.Parent = page

		local equippedLabel = Components.Label({
			Text = "Equipped 0/" .. PlayerConfig.MaxEquippedPets,
			Parent = header,
			Size = UDim2.new(0.35, 0, 0, 34),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			XAlign = Enum.TextXAlignment.Left,
			MaxTextSize = 28,
		})
		local incomeLabel = Components.Label({
			Text = "",
			Parent = header,
			Size = UDim2.new(0.25, 0, 0, 30),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = Theme.Colors.Mint[1],
			MaxTextSize = 26,
		})
		Components.Button({
			Text = "Equip Best",
			Parent = header,
			Size = UDim2.fromOffset(190, 46),
			Position = UDim2.new(1, -6, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Colors = Theme.Colors.Mint,
			MaxTextSize = 26,
			OnClick = function()
				invoke("EquipBest")
			end,
		})

		local grid = Components.ScrollList({
			Parent = page,
			Position = UDim2.fromOffset(0, HEADER + 8),
			Size = UDim2.new(1, 0, 1, -(HEADER + 8)),
			Grid = true,
			CellSize = UDim2.fromOffset(122, 146),
		})

		local function petCard(id: string, pet, order: number)
			local rarityColor = SellConfig.RarityColors[pet.Rarity] or SellConfig.RarityColors.Common
			local card = makeCard(grid, order, rarityColor, pet.Equipped == true, function()
				invoke("EquipPet", id, not pet.Equipped)
			end)
			Icons.Make("Paw", card, {
				Size = UDim2.fromOffset(56, 56),
				Position = UDim2.new(0.5, 0, 0, 8),
				AnchorPoint = Vector2.new(0.5, 0),
				Color = Color3.new(1, 1, 1),
				ZIndex = 2,
			})
			stars(card, pet.Rarity)
			cardText(card, pet.Name, 64, 24)
			cardText(card, Format.Weight(pet.Weight), 90, 20)
			cardText(card, "+" .. Format.Money(SellConfig.GetIncome(pet)) .. "/s", 114, 22, Theme.Colors.Yellow[1])
		end

		refreshers.Pets = function()
			Components.ClearList(grid)
			local pets = ClientState.Data and ClientState.Data.Pets or {}

			local ids = {}
			local equipped, income = 0, 0
			for id, pet in pets do
				table.insert(ids, id)
				if pet.Equipped then
					equipped += 1
					income += SellConfig.GetIncome(pet)
				end
			end
			table.sort(ids, function(a, b)
				local petA, petB = pets[a], pets[b]
				if petA.Equipped ~= petB.Equipped then
					return petA.Equipped == true
				end
				return SellConfig.GetIncome(petA) > SellConfig.GetIncome(petB)
			end)

			for order, id in ids do
				petCard(id, pets[id], order)
			end

			equippedLabel.Text = `Equipped {equipped}/{PlayerConfig.MaxEquippedPets}`
			incomeLabel.Text = if income > 0 then "+" .. Format.Money(income) .. "/s" else ""

			if #ids == 0 then
				Components.Label({
					Text = "No pets yet!\nGrab an egg from the islands.",
					Parent = grid,
					Wrapped = true,
					MaxTextSize = 22,
					Color = Theme.Text,
				})
			end
		end
	end

	-- Shop item pages (Shoes, Coils, Vertex, Trampolines) -------------------------------
	local function equip(kind: string, tier: number)
		if kind == "Trampoline" then
			invoke("EquipTrampoline", tier)
		else
			invoke("EquipItem", kind, tier)
		end
	end

	for _, kind in { "Shoes", "Coil", "Vertex", "Trampoline" } do
		local page = makePage(kind)
		local header = Instance.new("Frame")
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, 0, 0, HEADER)
		header.Parent = page

		local usingLabel = Components.Label({
			Text = "",
			Parent = header,
			Size = UDim2.new(1, -220, 0, 32),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			XAlign = Enum.TextXAlignment.Left,
			MaxTextSize = 26,
		})
		Components.Button({
			Text = if kind == "Shoes" or kind == "Coil" then "Wear Best" else "Use Best",
			Parent = header,
			Size = UDim2.fromOffset(190, 46),
			Position = UDim2.new(1, -6, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Colors = Theme.Colors.Mint,
			MaxTextSize = 26,
			OnClick = function()
				local list = ownedItems(kind)
				if #list == 0 then
					return
				end
				-- 0 = always your best (gear / vertex); trampolines take the tier.
				equip(kind, if kind == "Trampoline" then list[1].Tier else 0)
			end,
		})

		local grid = Components.ScrollList({
			Parent = page,
			Position = UDim2.fromOffset(0, HEADER + 8),
			Size = UDim2.new(1, 0, 1, -(HEADER + 8)),
			Grid = true,
			CellSize = UDim2.fromOffset(122, 146),
		})

		refreshers[kind] = function()
			Components.ClearList(grid)
			local list, used = ownedItems(kind)
			local wearWord = if kind == "Shoes" or kind == "Coil" then "Wearing" else "Using"
			usingLabel.Text = "Tap one to use it"
			for order, item in list do
				local inUse = item.Tier == used
				if inUse then
					usingLabel.Text = `{wearWord}: {item.Name}`
				end
				local color = if item.Rarity then SellConfig.RarityColors[item.Rarity] else item.Color
				local card = makeCard(grid, order, color, inUse, function()
					if inUse then
						Components.Notify(gui, `You're already {wearWord:lower()} it`, GOOD)
					else
						equip(kind, item.Tier)
					end
				end)
				Icons.Make(item.Icon, card, {
					Size = UDim2.fromOffset(56, 56),
					Position = UDim2.new(0.5, 0, 0, 8),
					AnchorPoint = Vector2.new(0.5, 0),
					Color = item.Color,
					ZIndex = 2,
				})
				stars(card, item.Rarity)
				cardText(card, item.Name, 64, 24)
				cardText(card, item.Perk, 90, 20, Theme.Colors.Yellow[1])
				cardText(card, if inUse then wearWord else "Tap to use", 114, 22, if inUse then Theme.Colors.Mint[1] else nil)
			end
			if #list == 0 then
				usingLabel.Text = ""
				Components.Label({
					Text = EMPTY[kind] or "Nothing yet!",
					Parent = grid,
					Wrapped = true,
					MaxTextSize = 22,
					Color = Theme.Text,
				})
			end
		end
	end

	local function refreshCurrent()
		if window.IsOpen() then
			refreshers[currentTab]()
		end
	end
	ClientState.Changed:Connect(refreshCurrent)
	for _, name in { "TrampolineTier", "EquippedTrampoline" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			if currentTab == "Trampoline" then
				refreshCurrent()
			end
		end)
	end

	local panel = { Window = window }

	-- tab = "Pets" | "Shoes" | "Coil" | "Vertex" | "Trampoline" (default: the last one open)
	function panel.Open(tab: string?)
		setTab(if tab and pages[tab] then tab else currentTab)
		window.Open()
	end

	function panel.Close()
		window.Close()
	end

	function panel.IsOpen(): boolean
		return window.IsOpen()
	end

	return panel
end

return InventoryPanel
