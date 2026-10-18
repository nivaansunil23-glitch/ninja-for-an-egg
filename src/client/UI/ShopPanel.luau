-- Shop window. Talking to a shopkeeper opens just their shop (Gear, Sell or
-- Vertex) under that shop's name; the Shop button on the HUD opens all three
-- as tabs. Gear and vertices are cards with a price button. On the Sell page
-- your pets are cards you tap to pick, then sell.
--
--   panel.Open(tab, context?)  -- context = { Title, Colors, Hint, Conversation } from ShopTalk
--   panel.Closed:Connect(function(context) end)
--   panel.Purchased:Connect(function(kind) end)  -- "Gear", "Vertex" or "Sell"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local player = Players.LocalPlayer

local GOOD = Color3.fromRGB(140, 255, 170)
local BAD = Color3.fromRGB(255, 130, 130)
local TOP_BAR = 52
local CONFIRM_SECONDS = 3

local TABS = {
	{ Id = "Vertex", Text = "Vertices" },
	{ Id = "Gear", Text = "Gear" },
	{ Id = "Sell", Text = "Sell" },
}

local function shopColors(id: string)
	local shop = ShopConfig.Shops[id]
	return shop and Theme.Colors[shop.Color] or Theme.Colors.Pink
end

local function powerText(entry): string
	return `⬆️ {VertexConfig.PerkText(entry)}`
end

local function gearStat(gear): string?
	if gear.JumpMultiplier then
		return `⬆️ +{math.floor((gear.JumpMultiplier - 1) * 100 + 0.5)}% Jump`
	elseif gear.Fuel then
		return `⛽ {gear.Fuel}s of flight`
	end
	return nil
end

-- A vertex: a chunky glossy gem in the tier's colour.
local function makeGem(parent: GuiObject, size: number, color: Color3, position: UDim2)
	local gem = Components.Box({
		Name = "Gem",
		Parent = parent,
		Size = UDim2.fromOffset(size, size),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Colors = Theme.FromColor(color),
		CornerRadius = UDim.new(0, math.floor(size * 0.24)),
		StrokeThickness = 3,
	})
	gem.Rotation = 45
	Components.Shine(gem, 0.5)
	return gem
end

local ShopPanel = {}

function ShopPanel.new(gui: ScreenGui)
	local closedEvent = Instance.new("BindableEvent")
	local purchasedEvent = Instance.new("BindableEvent")

	local panel = {
		Closed = closedEvent.Event,
		Purchased = purchasedEvent.Event,
		Context = nil,
	}

	local window = Components.Window({
		Name = "Shop",
		Title = "Shop!",
		Icon = "🛒",
		Parent = gui,
		Colors = Theme.Colors.Pink,
		Size = UDim2.fromOffset(780, 500),
		OnClose = function()
			local context = panel.Context
			panel.Context = nil
			closedEvent:Fire(context)
		end,
	})
	panel.Window = window
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
	local function purchase(kind: string, remoteName: string, button: GuiObject?, ...): boolean
		if busy then
			return false
		end
		busy = true
		local remote = Net.Function(remoteName)
		local ok, success, message = pcall(remote.InvokeServer, remote, ...)
		busy = false
		if not ok then
			notify(false, "Something went wrong, try again")
			return false
		end
		notify(success, message)
		if success then
			if button and button.Parent then
				Components.Burst(gui, Components.CenterOf(button))
			end
			purchasedEvent:Fire(kind)
		end
		return success == true
	end

	-- Top bar: tabs (or the shop's tip) on the left, your money on the right.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.BackgroundTransparency = 1
	topBar.Size = UDim2.new(1, 0, 0, TOP_BAR)
	topBar.Parent = content

	local tabBar = Instance.new("Frame")
	tabBar.Name = "Tabs"
	tabBar.BackgroundTransparency = 1
	tabBar.Size = UDim2.new(1, -200, 1, 0)
	tabBar.Parent = topBar
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar

	local hint = Components.Label({
		Name = "Hint",
		Text = "",
		Parent = topBar,
		Size = UDim2.new(1, -214, 0, 30),
		Position = UDim2.new(0, 6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = Enum.TextXAlignment.Left,
		Color = Theme.DarkText,
		StrokeThickness = 0,
		MaxTextSize = 22,
	})
	hint.Visible = false

	local moneyPill = Components.Box({
		Name = "Money",
		Parent = topBar,
		Size = UDim2.fromOffset(186, 44),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Colors = Theme.Colors.Yellow,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
	})
	Components.Shine(moneyPill, 0.35)
	local moneyLabel = Components.Label({
		Text = "💰 $0",
		Parent = moneyPill,
		Size = UDim2.fromScale(0.84, 0.66),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 28,
	})
	local function updateMoney()
		moneyLabel.Text = "💰 " .. Format.Money(money())
	end
	updateMoney()

	local pages = {}
	local tabButtons = {}
	local refreshers = {}
	local onShow = {}
	local currentTab = "Vertex"

	local function makePage(id: string)
		local page = Instance.new("Frame")
		page.Name = id
		page.BackgroundTransparency = 1
		page.Position = UDim2.fromOffset(0, TOP_BAR + 6)
		page.Size = UDim2.new(1, 0, 1, -(TOP_BAR + 6))
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
			Components.SetColors(button, if tabId == id then shopColors(tabId) else Theme.Colors.Gray)
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness = if tabId == id then 4 else 3
			end
		end
		if refreshers[id] then
			refreshers[id]()
		end
	end

	for order, tab in TABS do
		local shop = ShopConfig.Shops[tab.Id]
		tabButtons[tab.Id] = Components.Button({
			Name = tab.Id,
			Text = `{shop.Icon} {tab.Text}`,
			Parent = tabBar,
			Size = UDim2.fromOffset(162, 44),
			Colors = shopColors(tab.Id),
			LayoutOrder = order,
			MaxTextSize = 24,
			OnClick = function()
				setTab(tab.Id)
			end,
		})
	end

	-- Things that wobble and pulse while the window is open.
	local wobblers = {} -- GuiObjects that rock gently
	local pulsers = {} -- UIScales that breathe

	-- Gear page ------------------------------------------------------------------
	do
		local page = makePage("Gear")
		local grid = Components.ScrollList({
			Parent = page,
			Grid = true,
			CellSize = UDim2.fromOffset(226, 356),
		})
		local cards = {}

		for order, gear in GearConfig.List() do
			local card = Components.Box({
				Name = gear.Id,
				Parent = grid,
				Colors = Theme.Tint(gear.Color),
				CornerRadius = UDim.new(0, 24),
				StrokeThickness = 4,
				LayoutOrder = order,
			})

			-- Big picture tile with the rarity and stock stickers.
			local tile = Components.Box({
				Name = "Tile",
				Parent = card,
				Size = UDim2.new(1, -24, 0, 128),
				Position = UDim2.new(0.5, 0, 0, 12),
				AnchorPoint = Vector2.new(0.5, 0),
				Colors = Theme.FromColor(gear.Color),
				CornerRadius = UDim.new(0, 20),
				StrokeThickness = 3,
			})
			Components.Shine(tile)
			local icon = Components.Label({
				Name = "Icon",
				Text = gear.Icon,
				Parent = tile,
				Size = UDim2.fromOffset(92, 92),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				MaxTextSize = 84,
				StrokeThickness = 0,
			})
			table.insert(wobblers, icon)
			if gear.Rarity then
				Components.Tag({
					Text = string.upper(gear.Rarity),
					Parent = tile,
					Size = UDim2.fromOffset(88, 26),
					Position = UDim2.fromOffset(-8, -10),
					Colors = Theme.FromColor(SellConfig.RarityColors[gear.Rarity] or gear.Color),
					Rotation = -6,
					MaxTextSize = 16,
					ZIndex = 2,
				})
			end
			local stock, stockLabel = Components.Tag({
				Name = "Stock",
				Text = "IN STOCK",
				Parent = tile,
				Size = UDim2.fromOffset(100, 26),
				Position = UDim2.new(1, 8, 1, 10),
				AnchorPoint = Vector2.new(1, 1),
				Colors = Theme.Colors.Mint,
				Rotation = 4,
				MaxTextSize = 16,
				ZIndex = 2,
			})

			Components.Label({
				Text = gear.Name,
				Parent = card,
				Size = UDim2.new(1, -20, 0, 34),
				Position = UDim2.new(0.5, 0, 0, 148),
				AnchorPoint = Vector2.new(0.5, 0),
				MaxTextSize = 32,
			})
			Components.Label({
				Text = gear.Description,
				Parent = card,
				Size = UDim2.new(1, -28, 0, 42),
				Position = UDim2.new(0.5, 0, 0, 184),
				AnchorPoint = Vector2.new(0.5, 0),
				Wrapped = true,
				Color = Theme.DarkText,
				StrokeThickness = 0,
				MaxTextSize = 19,
			})
			local stat = gearStat(gear)
			if stat then
				Components.Tag({
					Text = stat,
					Parent = card,
					Size = UDim2.fromOffset(172, 30),
					Position = UDim2.new(0.5, 0, 0, 232),
					AnchorPoint = Vector2.new(0.5, 0),
					Colors = Theme.Colors.Purple,
					MaxTextSize = 19,
				})
			end
			local note = Components.Label({
				Name = "Note",
				Text = "",
				Parent = card,
				Size = UDim2.new(1, -20, 0, 22),
				Position = UDim2.new(0.5, 0, 1, -72),
				AnchorPoint = Vector2.new(0.5, 1),
				Color = Theme.DarkText,
				StrokeThickness = 0,
				MaxTextSize = 18,
			})

			local button, label
			button, label = Components.Button({
				Name = "Buy",
				Parent = card,
				Size = UDim2.new(1, -24, 0, 54),
				Position = UDim2.new(0.5, 0, 1, -12),
				AnchorPoint = Vector2.new(0.5, 1),
				MaxTextSize = 30,
				OnClick = function()
					local owned = ClientState.Data and ClientState.Data.Gear or {}
					if owned[gear.Id] then
						notify(true, `You already have the {gear.Name}! It's in your hotbar.`)
						return
					end
					purchase("Gear", "BuyGear", button, gear.Id)
				end,
			})
			Components.Shine(button, 0.3)
			cards[gear.Id] = {
				Gear = gear,
				Button = button,
				Label = label,
				Stock = stock,
				StockLabel = stockLabel,
				Note = note,
			}
		end

		refreshers.Gear = function()
			local owned = ClientState.Data and ClientState.Data.Gear or {}
			local cash = money()
			for gearId, entry in cards do
				local price = entry.Gear.Price
				if owned[gearId] then
					entry.Label.Text = "✔ Owned"
					Components.SetColors(entry.Button, Theme.Colors.Mint)
					entry.StockLabel.Text = "YOURS!"
					Components.SetColors(entry.Stock, Theme.Colors.Sky)
					entry.Note.Text = "In your hotbar"
					entry.Note.TextColor3 = Theme.DarkText
				else
					entry.Label.Text = "💰 " .. Format.Money(price)
					entry.StockLabel.Text = "IN STOCK"
					Components.SetColors(entry.Stock, Theme.Colors.Mint)
					if cash >= price then
						Components.SetColors(entry.Button, Theme.Colors.Yellow)
						entry.Note.Text = ""
					else
						Components.SetColors(entry.Button, Theme.Colors.Red)
						entry.Note.Text = `Need {Format.Money(price - cash)} more`
						entry.Note.TextColor3 = Theme.Colors.Red[2]
					end
				end
			end
		end
	end

	-- Vertex page ------------------------------------------------------------------
	do
		local page = makePage("Vertex")
		local cards = {}

		local function buyTier(tier: number, button: GuiObject?)
			local owned = ClientState.Data and ClientState.Data.VertexTier or 1
			if tier == owned then
				notify(true, "That's your vertex right now!")
				return
			elseif tier < owned then
				notify(true, "You already have a better vertex!")
				return
			elseif tier > owned + 1 then
				local needed = VertexConfig.Get(owned + 1)
				notify(false, `Buy the {needed and needed.Name or "next vertex"} first!`)
				return
			end
			purchase("Vertex", "BuyVertex", button, tier)
		end

		-- Banner: the vertex you have, and a one-tap upgrade to the next one.
		local banner = Components.Box({
			Name = "Current",
			Parent = page,
			Size = UDim2.new(1, -8, 0, 92),
			Position = UDim2.fromOffset(4, 4),
			Colors = Theme.Colors.Row,
			CornerRadius = UDim.new(0, 22),
			StrokeThickness = 4,
		})
		local bannerGem = makeGem(banner, 52, VertexConfig.Tiers[1].Color, UDim2.new(0, 50, 0.5, 0))
		table.insert(wobblers, bannerGem)
		Components.Label({
			Text = "Your vertex",
			Parent = banner,
			Size = UDim2.new(0, 220, 0, 22),
			Position = UDim2.fromOffset(96, 12),
			XAlign = Enum.TextXAlignment.Left,
			Color = Theme.DarkText,
			StrokeThickness = 0,
			MaxTextSize = 20,
		})
		local bannerName = Components.Label({
			Text = "",
			Parent = banner,
			Size = UDim2.new(0, 240, 0, 34),
			Position = UDim2.fromOffset(96, 34),
			XAlign = Enum.TextXAlignment.Left,
			MaxTextSize = 32,
		})
		local _, bannerPower = Components.Tag({
			Text = "",
			Parent = banner,
			Size = UDim2.fromOffset(150, 30),
			Position = UDim2.new(0, 346, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Colors = Theme.Colors.Sky,
			MaxTextSize = 20,
		})
		local nextLabel = Components.Label({
			Text = "",
			Parent = banner,
			Size = UDim2.new(0, 220, 0, 22),
			Position = UDim2.new(1, -14, 0, 4),
			AnchorPoint = Vector2.new(1, 0),
			Color = Theme.DarkText,
			StrokeThickness = 0,
			MaxTextSize = 18,
		})
		local upgradeButton, upgradeLabel
		upgradeButton, upgradeLabel = Components.Button({
			Name = "Upgrade",
			Parent = banner,
			Size = UDim2.fromOffset(214, 54),
			Position = UDim2.new(1, -14, 1, -8),
			AnchorPoint = Vector2.new(1, 1),
			MaxTextSize = 26,
			OnClick = function()
				local owned = ClientState.Data and ClientState.Data.VertexTier or 1
				if VertexConfig.Get(owned + 1) then
					buyTier(owned + 1, upgradeButton)
				else
					notify(true, "You already have the best vertex!")
				end
			end,
		})
		Components.Shine(upgradeButton, 0.3)
		local upgradeScale = Instance.new("UIScale")
		upgradeScale.Name = "Pulse"
		upgradeScale.Parent = upgradeLabel
		table.insert(pulsers, upgradeScale)

		local grid = Components.ScrollList({
			Parent = page,
			Position = UDim2.fromOffset(0, 104),
			Size = UDim2.new(1, 0, 1, -104),
			Grid = true,
			CellSize = UDim2.fromOffset(170, 220),
		})

		for tier, entry in VertexConfig.Tiers do
			local card = Components.Box({
				Name = "Tier" .. tier,
				Parent = grid,
				Colors = Theme.Tint(entry.Color),
				CornerRadius = UDim.new(0, 22),
				StrokeThickness = 4,
				LayoutOrder = tier,
			})
			Components.Tag({
				Text = tostring(tier),
				Parent = card,
				Size = UDim2.fromOffset(34, 34),
				Position = UDim2.fromOffset(8, 8),
				Colors = Theme.Colors.Purple,
				MaxTextSize = 20,
				ZIndex = 2,
			})
			local gem = makeGem(card, 58, entry.Color, UDim2.new(0.5, 0, 0, 56))
			local nextTag = Components.Tag({
				Text = "NEXT!",
				Parent = card,
				Size = UDim2.fromOffset(70, 26),
				Position = UDim2.new(1, 6, 0, -4),
				AnchorPoint = Vector2.new(1, 0),
				Colors = Theme.Colors.Orange,
				Rotation = 8,
				MaxTextSize = 16,
				ZIndex = 3,
			})
			nextTag.Visible = false
			local nextScale = Instance.new("UIScale")
			nextScale.Parent = nextTag
			table.insert(pulsers, nextScale)

			Components.Label({
				Text = entry.Name,
				Parent = card,
				Size = UDim2.new(1, -16, 0, 26),
				Position = UDim2.new(0.5, 0, 0, 100),
				AnchorPoint = Vector2.new(0.5, 0),
				MaxTextSize = 24,
			})
			Components.Tag({
				Text = powerText(entry),
				Parent = card,
				Size = UDim2.fromOffset(134, 28),
				Position = UDim2.new(0.5, 0, 0, 130),
				AnchorPoint = Vector2.new(0.5, 0),
				Colors = Theme.Colors.Sky,
				MaxTextSize = 18,
			})
			local button, label
			button, label = Components.Button({
				Parent = card,
				Size = UDim2.new(1, -20, 0, 42),
				Position = UDim2.new(0.5, 0, 1, -10),
				AnchorPoint = Vector2.new(0.5, 1),
				MaxTextSize = 22,
				OnClick = function()
					buyTier(tier, button)
				end,
			})
			cards[tier] = {
				Entry = entry,
				Card = card,
				Stroke = card:FindFirstChildOfClass("UIStroke"),
				Gem = gem,
				Next = nextTag,
				Button = button,
				Label = label,
			}
		end

		refreshers.Vertex = function()
			local owned = ClientState.Data and ClientState.Data.VertexTier or 1
			local cash = money()
			local current = VertexConfig.Get(owned) or VertexConfig.Tiers[1]
			local nextEntry = VertexConfig.Get(owned + 1)

			Components.SetColors(bannerGem, Theme.FromColor(current.Color))
			bannerName.Text = current.Name
			bannerPower.Text = powerText(current)
			if nextEntry then
				nextLabel.Text = `Next: {nextEntry.Name}`
				upgradeLabel.Text = "⬆️ " .. Format.Money(nextEntry.Price)
				Components.SetColors(upgradeButton, if cash >= nextEntry.Price then Theme.Colors.Yellow else Theme.Colors.Red)
			else
				nextLabel.Text = "You have the best vertex!"
				upgradeLabel.Text = "✨ Maxed"
				Components.SetColors(upgradeButton, Theme.Colors.Purple)
			end

			for tier, card in cards do
				local price = card.Entry.Price
				card.Next.Visible = tier == owned + 1
				if card.Stroke then
					card.Stroke.Color = if tier == owned
						then Theme.Colors.Mint[2]
						elseif tier == owned + 1 then Theme.Colors.Orange[2]
						else Theme.Outline
					card.Stroke.Thickness = if tier == owned or tier == owned + 1 then 5 else 4
				end
				if tier == owned then
					card.Label.Text = "✔ Equipped"
					Components.SetColors(card.Button, Theme.Colors.Mint)
				elseif tier < owned then
					card.Label.Text = "Owned"
					Components.SetColors(card.Button, Theme.Colors.Gray)
				elseif tier == owned + 1 then
					card.Label.Text = Format.Money(price)
					Components.SetColors(card.Button, if cash >= price then Theme.Colors.Yellow else Theme.Colors.Red)
				else
					card.Label.Text = "🔒 " .. Format.Money(price)
					Components.SetColors(card.Button, Theme.Colors.Gray)
				end
			end
		end

		-- Scroll so the next vertex to buy is in view (4 cards fit in a row).
		onShow.Vertex = function()
			local owned = ClientState.Data and ClientState.Data.VertexTier or 1
			local row = math.floor(math.min(owned, #VertexConfig.Tiers - 1) / 4)
			grid.CanvasPosition = Vector2.new(0, row * 230)
		end
	end

	-- Sell page ---------------------------------------------------------------------
	do
		local page = makePage("Sell")
		local filter = "All"
		local sortBy = "Value"
		local selected = {} -- [petId] = true
		local shownIds = {}
		local confirmUntil = 0

		local filterBar = Instance.new("Frame")
		filterBar.Name = "Filters"
		filterBar.BackgroundTransparency = 1
		filterBar.Size = UDim2.new(1, 0, 0, 36)
		filterBar.Parent = page
		local filterLayout = Instance.new("UIListLayout")
		filterLayout.FillDirection = Enum.FillDirection.Horizontal
		filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		filterLayout.Padding = UDim.new(0, 6)
		filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
		filterLayout.Parent = filterBar

		local grid = Components.ScrollList({
			Parent = page,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 1, -44 - 66),
			Grid = true,
			CellSize = UDim2.fromOffset(130, 156),
		})

		local actionBar = Instance.new("Frame")
		actionBar.Name = "Actions"
		actionBar.BackgroundTransparency = 1
		actionBar.Size = UDim2.new(1, 0, 0, 58)
		actionBar.Position = UDim2.fromScale(0, 1)
		actionBar.AnchorPoint = Vector2.new(0, 1)
		actionBar.Parent = page
		local actionLayout = Instance.new("UIListLayout")
		actionLayout.FillDirection = Enum.FillDirection.Horizontal
		actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		actionLayout.Padding = UDim.new(0, 10)
		actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
		actionLayout.Parent = actionBar

		local refreshSell, updateTotals

		local chips = {}
		local function styleChips()
			for name, chip in chips do
				local stroke = chip:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = if name == filter then Theme.Colors.Mint[2] else Theme.Outline
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
				Name = name,
				Text = name,
				Parent = filterBar,
				Size = UDim2.fromOffset(if name == "All" then 56 else 82, 32),
				Colors = if name == "All" then Theme.Colors.Purple else Theme.FromColor(SellConfig.RarityColors[name]),
				LayoutOrder = order,
				StrokeThickness = 2,
				MaxTextSize = 17,
				OnClick = function()
					filter = name
					styleChips()
					refreshSell()
				end,
			})
		end
		local _, sortLabel = Components.Button({
			Name = "Sort",
			Text = "",
			Parent = filterBar,
			Size = UDim2.fromOffset(112, 32),
			Colors = Theme.Colors.Sky,
			LayoutOrder = 100,
			StrokeThickness = 2,
			MaxTextSize = 17,
			OnClick = function()
				sortBy = if sortBy == "Weight" then "Value" else "Weight"
				refreshSell()
			end,
		})

		local selectAllButton, selectAllLabel = Components.Button({
			Name = "SelectAll",
			Text = "Select All",
			Parent = actionBar,
			Size = UDim2.fromOffset(150, 52),
			Colors = Theme.Colors.Purple,
			LayoutOrder = 1,
			MaxTextSize = 24,
		})
		local sellSelectedButton, sellSelectedLabel = Components.Button({
			Name = "SellSelected",
			Parent = actionBar,
			Size = UDim2.fromOffset(276, 52),
			Colors = Theme.Colors.Mint,
			LayoutOrder = 2,
			MaxTextSize = 24,
		})
		local sellAllButton, sellAllLabel = Components.Button({
			Name = "SellAll",
			Parent = actionBar,
			Size = UDim2.fromOffset(276, 52),
			Colors = Theme.Colors.Yellow,
			LayoutOrder = 3,
			MaxTextSize = 24,
		})
		for _, button in { selectAllButton, sellSelectedButton, sellAllButton } do
			Components.Shine(button, 0.3)
		end

		local function selectedIds(): { string }
			local ids = {}
			for id in selected do
				table.insert(ids, id)
			end
			return ids
		end

		local function sell(ids: { string }, button: GuiObject)
			if #ids == 0 then
				notify(false, "Tap some pets to pick them first")
				return
			end
			if purchase("Sell", "SellPets", button, ids) then
				table.clear(selected)
				updateTotals()
			end
		end

		selectAllButton.Activated:Connect(function()
			local allPicked = #shownIds > 0 and #selectedIds() == #shownIds
			table.clear(selected)
			if not allPicked then
				for _, id in shownIds do
					selected[id] = true
				end
			end
			refreshSell()
		end)
		sellSelectedButton.Activated:Connect(function()
			sell(selectedIds(), sellSelectedButton)
		end)
		-- Selling everything takes a second tap, so nobody does it by accident.
		sellAllButton.Activated:Connect(function()
			if #shownIds == 0 then
				notify(false, "No pets here to sell")
				return
			end
			if os.clock() > confirmUntil then
				confirmUntil = os.clock() + CONFIRM_SECONDS
				updateTotals()
				task.delay(CONFIRM_SECONDS + 0.05, updateTotals)
				return
			end
			confirmUntil = 0
			sell(table.clone(shownIds), sellAllButton)
		end)

		updateTotals = function()
			local pets = ClientState.Data and ClientState.Data.Pets or {}
			local count, selectedTotal, shownTotal = 0, 0, 0
			for id in selected do
				local pet = pets[id]
				if pet then
					count += 1
					selectedTotal += SellConfig.GetPrice(pet)
				end
			end
			for _, id in shownIds do
				local pet = pets[id]
				if pet then
					shownTotal += SellConfig.GetPrice(pet)
				end
			end
			sellSelectedLabel.Text = `Sell {count} · {Format.Money(selectedTotal)}`
			if os.clock() < confirmUntil then
				sellAllLabel.Text = `Tap again to sell {#shownIds}!`
				Components.SetColors(sellAllButton, Theme.Colors.Red)
			else
				local what = if filter == "All" then "All" else `All {filter}`
				sellAllLabel.Text = `Sell {what} · {Format.Money(shownTotal)}`
				Components.SetColors(sellAllButton, Theme.Colors.Yellow)
			end
			selectAllLabel.Text = if #shownIds > 0 and count == #shownIds then "Clear" else "Select All"
		end

		local function makeCard(id: string, pet, order: number)
			local rarityColor = SellConfig.RarityColors[pet.Rarity] or SellConfig.RarityColors.Common
			local card = Instance.new("TextButton")
			card.Name = "Pet"
			card.Text = ""
			card.AutoButtonColor = false
			card.LayoutOrder = order
			card.BackgroundColor3 = Color3.new(1, 1, 1)
			Components.Corner(card, UDim.new(0, 18))
			local stroke = Components.Stroke(card, 3)
			Components.Gradient(card, Theme.FromColor(rarityColor))
			Components.Shine(card, 0.3)
			local cardScale = Instance.new("UIScale")
			cardScale.Parent = card

			Components.Label({
				Text = Theme.RarityIcon[pet.Rarity] or "🐣",
				Parent = card,
				Size = UDim2.fromOffset(58, 50),
				Position = UDim2.new(0.5, 0, 0, 8),
				AnchorPoint = Vector2.new(0.5, 0),
				MaxTextSize = 46,
				StrokeThickness = 0,
			})
			Components.Label({
				Text = pet.Name,
				Parent = card,
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.new(0.5, 0, 0, 60),
				AnchorPoint = Vector2.new(0.5, 0),
				MaxTextSize = 20,
			})
			Components.Label({
				Text = `{pet.Rarity} · {Format.Weight(pet.Weight)}`,
				Parent = card,
				Size = UDim2.new(1, -12, 0, 18),
				Position = UDim2.new(0.5, 0, 0, 86),
				AnchorPoint = Vector2.new(0.5, 0),
				MaxTextSize = 15,
			})
			Components.Tag({
				Text = Format.Money(SellConfig.GetPrice(pet)),
				Parent = card,
				Size = UDim2.new(1, -18, 0, 30),
				Position = UDim2.new(0.5, 0, 1, -8),
				AnchorPoint = Vector2.new(0.5, 1),
				Colors = Theme.Colors.Yellow,
				MaxTextSize = 20,
			})
			local check = Components.Tag({
				Text = "✔",
				Parent = card,
				Size = UDim2.fromOffset(32, 32),
				Position = UDim2.new(1, 6, 0, -6),
				AnchorPoint = Vector2.new(1, 0),
				Colors = Theme.Colors.Mint,
				MaxTextSize = 20,
				ZIndex = 3,
			})

			local function style()
				local isSelected = selected[id] == true
				check.Visible = isSelected
				stroke.Color = if isSelected then Theme.Colors.Mint[2] else Theme.Outline
				stroke.Thickness = if isSelected then 5 else 3
				cardScale.Scale = if isSelected then 1.04 else 1
			end
			style()
			card.MouseEnter:Connect(function()
				if not selected[id] then
					cardScale.Scale = 1.03
				end
			end)
			card.MouseLeave:Connect(style)
			card.Activated:Connect(function()
				selected[id] = if selected[id] then nil else true
				style()
				updateTotals()
			end)
			card.Parent = grid
		end

		refreshSell = function()
			sortLabel.Text = if sortBy == "Value" then "Sort: $" else "Sort: kg"
			Components.ClearList(grid)
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
			-- Forget picks for pets that are gone or filtered out.
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
				makeCard(id, pets[id], order)
			end

			local equippedText = `{hiddenEquipped} equipped pet{if hiddenEquipped == 1 then " is" else "s are"} kept safe`
			local layout = grid:FindFirstChildOfClass("UIGridLayout")
			if #shownIds == 0 then
				-- Nothing to show: one wide message instead of cards.
				if layout then
					layout.CellSize = UDim2.new(1, -16, 0, 130)
				end
				local message = if next(pets) then "No pets here to sell." else "🥚 No pets yet! Grab an egg from the islands and hatch it."
				if hiddenEquipped > 0 then
					message ..= `\n🔒 {equippedText}. Unequip them in your Inventory to sell them.`
				end
				local holder = Instance.new("Frame")
				holder.Name = "Empty"
				holder.BackgroundTransparency = 1
				holder.Parent = grid
				Components.Label({
					Text = message,
					Parent = holder,
					Wrapped = true,
					Color = Theme.DarkText,
					StrokeThickness = 0,
					MaxTextSize = 24,
				})
			else
				if layout then
					layout.CellSize = UDim2.fromOffset(130, 156)
				end
				if hiddenEquipped > 0 then
					-- A grey card at the end saying equipped pets are left out.
					local card = Components.Box({
						Name = "Equipped",
						Parent = grid,
						Colors = Theme.Colors.Row,
						CornerRadius = UDim.new(0, 18),
						StrokeThickness = 3,
						LayoutOrder = 100000,
					})
					Components.Label({
						Text = "🔒",
						Parent = card,
						Size = UDim2.fromOffset(50, 46),
						Position = UDim2.new(0.5, 0, 0, 12),
						AnchorPoint = Vector2.new(0.5, 0),
						MaxTextSize = 40,
						StrokeThickness = 0,
					})
					Components.Label({
						Text = equippedText .. " (unequip to sell)",
						Parent = card,
						Size = UDim2.new(1, -16, 0, 80),
						Position = UDim2.new(0.5, 0, 0, 64),
						AnchorPoint = Vector2.new(0.5, 0),
						Wrapped = true,
						Color = Theme.DarkText,
						StrokeThickness = 0,
						MaxTextSize = 18,
					})
				end
			end
			updateTotals()
		end

		refreshers.Sell = refreshSell
		styleChips()
	end

	-- Refresh the open page when data or money changes. The sell page only
	-- rebuilds on data changes so ticking income doesn't reset it.
	ClientState.Changed:Connect(function()
		if window.IsOpen() and refreshers[currentTab] then
			refreshers[currentTab]()
		end
	end)
	player:GetAttributeChangedSignal("Money"):Connect(function()
		updateMoney()
		if window.IsOpen() and currentTab ~= "Sell" then
			refreshers[currentTab]()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not window.IsOpen() then
			return
		end
		local t = os.clock()
		for index, object in wobblers do
			object.Rotation = (if object.Name == "Gem" then 45 else 0) + math.sin(t * 2 + index) * 7
		end
		local pulse = 1 + math.abs(math.sin(t * 3)) * 0.08
		for _, scale in pulsers do
			scale.Scale = pulse
		end
	end)

	function panel.Open(tab: string?, context)
		local id = if tab and pages[tab] then tab else currentTab
		panel.Context = context
		if context then
			local shop = ShopConfig.Shops[id]
			window.SetTitle((context.Title or shop.Title) .. "!", context.Colors or shopColors(id), shop.Icon)
			tabBar.Visible = false
			hint.Text = context.Hint or shop.Hint or ""
			hint.Visible = true
		else
			window.SetTitle("Shop!", Theme.Colors.Pink, "🛒")
			tabBar.Visible = true
			hint.Visible = false
		end
		updateMoney()
		setTab(id)
		window.Open()
		if onShow[id] then
			task.defer(onShow[id])
		end
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
