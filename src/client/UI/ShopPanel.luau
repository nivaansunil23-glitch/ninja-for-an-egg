-- Shop window with three tabs: Vertices (jump power), Gear and Sell.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local player = Players.LocalPlayer

local GOOD = Color3.fromRGB(140, 255, 170)
local BAD = Color3.fromRGB(255, 130, 130)

local TABS = {
	{ Id = "Vertex", Text = "⬆️ Vertices", Colors = Theme.Colors.Sky },
	{ Id = "Gear", Text = "🚀 Gear", Colors = Theme.Colors.Pink },
	{ Id = "Sell", Text = "💰 Sell", Colors = Theme.Colors.Yellow },
}

local ShopPanel = {}

function ShopPanel.new(gui: ScreenGui)
	local window = Components.Window({ Name = "Shop", Title = "Shop", Parent = gui, Colors = Theme.Colors.Pink })
	local content = window.Content
	local busy = false

	local function notify(ok: boolean, message: string?)
		if message then
			Components.Notify(gui, message, if ok then GOOD else BAD)
		end
	end

	local function money(): number
		return player:GetAttribute("Money") or 0
	end

	-- Calls a shop remote once at a time and shows the result.
	local function purchase(remoteName: string, ...)
		if busy then
			return
		end
		busy = true
		local ok, success, message = pcall(Net.Function(remoteName).InvokeServer, Net.Function(remoteName), ...)
		busy = false
		if not ok then
			notify(false, "Something went wrong, try again")
		else
			notify(success, message)
		end
	end

	-- Tab bar ----------------------------------------------------------------
	local tabBar = Instance.new("Frame")
	tabBar.Name = "Tabs"
	tabBar.BackgroundTransparency = 1
	tabBar.Size = UDim2.new(1, 0, 0, 50)
	tabBar.Parent = content
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 12)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar

	local pages = {}
	local tabButtons = {}
	local currentTab = "Vertex"
	local refreshers = {}

	local function makePage(id: string)
		local page = Instance.new("Frame")
		page.Name = id
		page.BackgroundTransparency = 1
		page.Position = UDim2.fromOffset(0, 60)
		page.Size = UDim2.new(1, 0, 1, -60)
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
		for tabId, button in tabButtons do
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness = if tabId == id then 5 else 3
				stroke.Color = if tabId == id then Color3.new(1, 1, 1) else Theme.Outline
			end
		end
		if refreshers[id] then
			refreshers[id]()
		end
	end

	for order, tab in TABS do
		tabButtons[tab.Id] = Components.Button({
			Name = tab.Id,
			Text = tab.Text,
			Parent = tabBar,
			Size = UDim2.fromOffset(190, 46),
			Colors = tab.Colors,
			LayoutOrder = order,
			MaxTextSize = 26,
			OnClick = function()
				setTab(tab.Id)
			end,
		})
	end

	-- Vertices tab -------------------------------------------------------------
	do
		local page = makePage("Vertex")
		local list = Components.ScrollList({ Parent = page })
		local rows = {}

		for tier, entry in VertexConfig.Tiers do
			local row = Components.Box({ Parent = list, Size = UDim2.new(1, -16, 0, 76), LayoutOrder = tier })

			-- The vertex itself: a chunky glossy gem in the tier's colour.
			local gem = Components.Box({
				Name = "Gem",
				Parent = row,
				Size = UDim2.fromOffset(42, 42),
				Position = UDim2.new(0, 40, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Colors = Theme.FromColor(entry.Color),
				CornerRadius = UDim.new(0, 10),
			})
			gem.Rotation = 45

			Components.Label({
				Text = entry.Name,
				Parent = row,
				Size = UDim2.new(0.5, 0, 0, 32),
				Position = UDim2.fromOffset(78, 8),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 28,
			})
			Components.Label({
				Text = `⬆️ {entry.JumpPower} Jump Power`,
				Parent = row,
				Size = UDim2.new(0.5, 0, 0, 24),
				Position = UDim2.fromOffset(78, 42),
				XAlign = Enum.TextXAlignment.Left,
				Color = Theme.Colors.Sky[1],
				MaxTextSize = 22,
			})

			local button, label = Components.Button({
				Parent = row,
				Size = UDim2.fromOffset(170, 50),
				Position = UDim2.new(1, -14, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				MaxTextSize = 26,
				OnClick = function()
					purchase("BuyVertex", tier)
				end,
			})
			rows[tier] = { Button = button, Label = label, Entry = entry }
		end

		refreshers.Vertex = function()
			local owned = ClientState.Data and ClientState.Data.VertexTier or 1
			for tier, row in rows do
				local price = row.Entry.Price
				if tier == owned then
					row.Label.Text = "Equipped"
					Components.SetColors(row.Button, Theme.Colors.Mint)
				elseif tier < owned then
					row.Label.Text = "Owned"
					Components.SetColors(row.Button, Theme.Colors.Gray)
				elseif tier == owned + 1 then
					row.Label.Text = Format.Money(price)
					Components.SetColors(row.Button, if money() >= price then Theme.Colors.Yellow else Theme.Colors.Red)
				else
					row.Label.Text = "🔒 " .. Format.Money(price)
					Components.SetColors(row.Button, Theme.Colors.Gray)
				end
			end
		end
	end

	-- Gear tab -------------------------------------------------------------------
	do
		local page = makePage("Gear")
		local list = Components.ScrollList({ Parent = page })
		local rows = {}

		for order, gear in GearConfig.List() do
			local row = Components.Box({ Parent = list, Size = UDim2.new(1, -16, 0, 90), LayoutOrder = order })
			local iconBox = Components.Box({
				Parent = row,
				Size = UDim2.fromOffset(66, 66),
				Position = UDim2.new(0, 12, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Colors = Theme.FromColor(gear.Color),
				CornerRadius = UDim.new(0, 16),
			})
			Components.Label({
				Text = gear.Icon,
				Parent = iconBox,
				Size = UDim2.fromScale(0.75, 0.75),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				MaxTextSize = 44,
			})
			Components.Label({
				Text = gear.Name,
				Parent = row,
				Size = UDim2.new(0.5, 0, 0, 32),
				Position = UDim2.fromOffset(92, 10),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 28,
			})
			Components.Label({
				Text = gear.Description,
				Parent = row,
				Size = UDim2.new(0.5, 0, 0, 36),
				Position = UDim2.fromOffset(92, 44),
				XAlign = Enum.TextXAlignment.Left,
				Wrapped = true,
				Color = Theme.Colors.Pink[1],
				MaxTextSize = 20,
			})
			local button, label = Components.Button({
				Parent = row,
				Size = UDim2.fromOffset(170, 50),
				Position = UDim2.new(1, -14, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				MaxTextSize = 26,
				OnClick = function()
					purchase("BuyGear", gear.Id)
				end,
			})
			rows[gear.Id] = { Button = button, Label = label, Gear = gear }
		end

		refreshers.Gear = function()
			local owned = ClientState.Data and ClientState.Data.Gear or {}
			for gearId, row in rows do
				if owned[gearId] then
					row.Label.Text = "Owned"
					Components.SetColors(row.Button, Theme.Colors.Gray)
				else
					row.Label.Text = Format.Money(row.Gear.Price)
					Components.SetColors(row.Button, if money() >= row.Gear.Price then Theme.Colors.Yellow else Theme.Colors.Red)
				end
			end
		end
	end

	-- Sell tab ---------------------------------------------------------------------
	do
		local page = makePage("Sell")
		local filter = "All"
		local sortBy = "Weight"
		local selected = {} -- [petId] = true
		local shownIds = {}

		local filterBar = Instance.new("Frame")
		filterBar.BackgroundTransparency = 1
		filterBar.Size = UDim2.new(1, 0, 0, 38)
		filterBar.Parent = page
		local filterLayout = Instance.new("UIListLayout")
		filterLayout.FillDirection = Enum.FillDirection.Horizontal
		filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		filterLayout.Padding = UDim.new(0, 6)
		filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
		filterLayout.Parent = filterBar

		local list = Components.ScrollList({
			Parent = page,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 1, -44 - 62),
		})

		local actionBar = Instance.new("Frame")
		actionBar.BackgroundTransparency = 1
		actionBar.Size = UDim2.new(1, 0, 0, 54)
		actionBar.Position = UDim2.fromScale(0, 1)
		actionBar.AnchorPoint = Vector2.new(0, 1)
		actionBar.Parent = page

		local refreshSell

		local chips = {}
		local function styleChips()
			for name, chip in chips do
				local stroke = chip:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = if name == filter then Color3.new(1, 1, 1) else Theme.Outline
					stroke.Thickness = if name == filter then 4 else 2
				end
			end
		end

		local filterNames = { "All" }
		for _, rarity in SellConfig.Rarities do
			table.insert(filterNames, rarity)
		end
		for order, name in filterNames do
			chips[name] = Components.Button({
				Text = name,
				Parent = filterBar,
				Size = UDim2.fromOffset(if name == "All" then 54 else 78, 34),
				Colors = if name == "All" then Theme.Colors.Purple else Theme.FromColor(SellConfig.RarityColors[name]),
				LayoutOrder = order,
				StrokeThickness = 2,
				MaxTextSize = 18,
				OnClick = function()
					filter = name
					styleChips()
					refreshSell()
				end,
			})
		end
		local _, sortLabel = Components.Button({
			Text = "Sort: Weight",
			Parent = filterBar,
			Size = UDim2.fromOffset(104, 34),
			Colors = Theme.Colors.Sky,
			LayoutOrder = 100,
			StrokeThickness = 2,
			MaxTextSize = 18,
			OnClick = function()
				sortBy = if sortBy == "Weight" then "Value" else "Weight"
				refreshSell()
			end,
		})

		local sellSelectedButton, sellSelectedLabel = Components.Button({
			Parent = actionBar,
			Size = UDim2.new(0.48, 0, 1, -4),
			Position = UDim2.fromScale(0, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Colors = Theme.Colors.Mint,
			MaxTextSize = 26,
		})
		local sellAllButton, sellAllLabel = Components.Button({
			Parent = actionBar,
			Size = UDim2.new(0.48, 0, 1, -4),
			Position = UDim2.fromScale(1, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			Colors = Theme.Colors.Yellow,
			MaxTextSize = 26,
		})

		local function sell(ids)
			if #ids == 0 then
				notify(false, "Pick some pets to sell first")
				return
			end
			purchase("SellPets", ids)
			table.clear(selected)
		end
		sellSelectedButton.Activated:Connect(function()
			local ids = {}
			for id in selected do
				table.insert(ids, id)
			end
			sell(ids)
		end)
		sellAllButton.Activated:Connect(function()
			sell(table.clone(shownIds))
		end)

		local function updateTotals()
			local pets = ClientState.Data and ClientState.Data.Pets or {}
			local selectedTotal, shownTotal = 0, 0
			for id in selected do
				if pets[id] then
					selectedTotal += SellConfig.GetPrice(pets[id])
				end
			end
			for _, id in shownIds do
				shownTotal += SellConfig.GetPrice(pets[id])
			end
			sellSelectedLabel.Text = "Sell Selected " .. Format.Money(selectedTotal)
			sellAllLabel.Text = `Sell All {if filter == "All" then "" else filter .. " "}{Format.Money(shownTotal)}`
		end

		local function makeRow(id: string, pet, order: number)
			local rarityColor = SellConfig.RarityColors[pet.Rarity] or SellConfig.RarityColors.Common
			local row = Instance.new("TextButton")
			row.Text = ""
			row.AutoButtonColor = false
			row.Size = UDim2.new(1, -16, 0, 56)
			row.LayoutOrder = order
			row.BackgroundColor3 = Color3.new(1, 1, 1)
			Components.Corner(row)
			local stroke = Components.Stroke(row, 3)
			Components.Gradient(row, Theme.Colors.Row)

			local stripe = Components.Box({
				Parent = row,
				Size = UDim2.new(0, 14, 1, -14),
				Position = UDim2.new(0, 8, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Colors = Theme.FromColor(rarityColor),
				CornerRadius = UDim.new(1, 0),
				StrokeThickness = 2,
			})
			stripe.Name = "Rarity"

			local check = Components.Label({
				Text = "",
				Parent = row,
				Size = UDim2.fromOffset(36, 36),
				Position = UDim2.new(0, 30, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				MaxTextSize = 30,
			})
			Components.Label({
				Text = pet.Name,
				Parent = row,
				Size = UDim2.new(0.42, 0, 0, 28),
				Position = UDim2.fromOffset(74, 4),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 24,
			})
			Components.Label({
				Text = `{pet.Rarity} · {Format.Weight(pet.Weight)}`,
				Parent = row,
				Size = UDim2.new(0.42, 0, 0, 20),
				Position = UDim2.fromOffset(74, 32),
				XAlign = Enum.TextXAlignment.Left,
				Color = rarityColor:Lerp(Color3.new(1, 1, 1), 0.3),
				MaxTextSize = 18,
			})
			Components.Label({
				Text = Format.Money(SellConfig.GetPrice(pet)),
				Parent = row,
				Size = UDim2.new(0.3, 0, 0, 32),
				Position = UDim2.new(1, -16, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				XAlign = Enum.TextXAlignment.Right,
				Color = Theme.Colors.Yellow[1],
				MaxTextSize = 28,
			})

			local function style()
				local isSelected = selected[id] == true
				check.Text = if isSelected then "✅" else "⬜"
				stroke.Color = if isSelected then Theme.Colors.Mint[2] else Theme.Outline
				stroke.Thickness = if isSelected then 5 else 3
			end
			style()
			row.Activated:Connect(function()
				selected[id] = if selected[id] then nil else true
				style()
				updateTotals()
			end)
			row.Parent = list
		end

		refreshSell = function()
			sortLabel.Text = "Sort: " .. sortBy
			Components.ClearList(list)
			table.clear(shownIds)

			local pets = ClientState.Data and ClientState.Data.Pets or {}
			local hiddenEquipped = 0
			for id, pet in pets do
				if pet.Equipped then
					hiddenEquipped += 1
				elseif filter == "All" or pet.Rarity == filter then
					table.insert(shownIds, id)
				end
			end
			-- Forget selections for pets that are gone or filtered out.
			for id in selected do
				if not table.find(shownIds, id) then
					selected[id] = nil
				end
			end

			table.sort(shownIds, function(a, b)
				local petA, petB = pets[a], pets[b]
				if sortBy == "Value" then
					return SellConfig.GetPrice(petA) > SellConfig.GetPrice(petB)
				end
				return (petA.Weight or 0) > (petB.Weight or 0)
			end)

			for order, id in shownIds do
				makeRow(id, pets[id], order)
			end

			local note = nil
			if #shownIds == 0 then
				note = if next(pets) then "No pets here to sell." else "No pets yet! Grab an egg from the islands."
			end
			if hiddenEquipped > 0 then
				note = (if note then note .. "\n" else "")
					.. `{hiddenEquipped} equipped pet{if hiddenEquipped == 1 then " is" else "s are"} hidden. Unequip in your Inventory to sell.`
			end
			if note then
				Components.Label({
					Text = note,
					Parent = list,
					Size = UDim2.new(1, -16, 0, 50),
					LayoutOrder = if #shownIds == 0 then 0 else 100000,
					Wrapped = true,
					MaxTextSize = 20,
					Color = Theme.Colors.Purple[1],
				})
			end
			updateTotals()
		end

		refreshers.Sell = refreshSell
		styleChips()
	end

	-- Refresh the open tab when data or money changes. The sell list only
	-- rebuilds on data changes so ticking income doesn't reset it.
	ClientState.Changed:Connect(function()
		if window.IsOpen() and refreshers[currentTab] then
			refreshers[currentTab]()
		end
	end)
	player:GetAttributeChangedSignal("Money"):Connect(function()
		if window.IsOpen() and currentTab ~= "Sell" then
			refreshers[currentTab]()
		end
	end)

	local panel = { Window = window }

	function panel.Open(tab: string?)
		setTab(tab or currentTab)
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

return ShopPanel
