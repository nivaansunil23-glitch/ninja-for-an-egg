-- Inventory window: every pet you own. Tap a pet to equip it; equipped pets
-- earn money every second. "Equip Best" picks the top earners.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local player = Players.LocalPlayer

local BAD = Color3.fromRGB(255, 130, 130)
local GOOD = Color3.fromRGB(140, 255, 170)

-- Placeholder pet art until pet models/icons exist.
local RARITY_ICON = {
	Common = "🐣",
	Uncommon = "🐥",
	Rare = "🐾",
	Epic = "🦄",
	Legendary = "🐉",
	Secret = "👾",
}

local STARS = { Epic = 1, Legendary = 2, Secret = 3 }

-- Paint-splash blob behind a pet icon (a few overlapping circles), like the
-- item grid in Pet Sim 99.
local function splash(parent: GuiObject, color: Color3)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.25)
	for _, blob in {
		{ 84, 0.5, 40, 1 },
		{ 34, 0.22, 20, 2 },
		{ 28, 0.8, 66, 3 },
		{ 18, 0.84, 14, 4 },
	} do
		local circle = Instance.new("Frame")
		circle.Name = "Splash"
		circle.BackgroundColor3 = if blob[4] == 1 then color else light
		circle.BorderSizePixel = 0
		circle.ZIndex = 0
		circle.Size = UDim2.fromOffset(blob[1], blob[1])
		circle.Position = UDim2.new(blob[2], 0, 0, blob[3])
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		Components.Corner(circle, UDim.new(1, 0))
		circle.Parent = parent
	end
end

local InventoryPanel = {}

function InventoryPanel.new(gui: ScreenGui)
	local window = Components.Window({
		Name = "Inventory",
		Title = "Inventory!",
		Icon = "🎒",
		Parent = gui,
		Colors = Theme.Colors.Sky,
	})
	local content = window.Content
	local busy = false

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Parent = content

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

	Components.Button({
		Text = "⭐ Equip Best",
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
		Parent = content,
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -58),
		Grid = true,
		CellSize = UDim2.fromOffset(122, 146),
	})

	local function makeCard(id: string, pet, order: number)
		local rarityColor = SellConfig.RarityColors[pet.Rarity] or SellConfig.RarityColors.Common
		local card = Instance.new("TextButton")
		card.Text = ""
		card.AutoButtonColor = false
		card.LayoutOrder = order
		-- No box: just a color splash behind a big icon.
		card.BackgroundTransparency = 1
		splash(card, rarityColor)
		local scale = Instance.new("UIScale")
		scale.Parent = card
		card.MouseEnter:Connect(function()
			scale.Scale = 1.06
		end)
		card.MouseLeave:Connect(function()
			scale.Scale = 1
		end)

		local icon = Components.Label({
			Text = RARITY_ICON[pet.Rarity] or "🐣",
			Parent = card,
			Size = UDim2.fromOffset(70, 64),
			Position = UDim2.new(0.5, 0, 0, 6),
			AnchorPoint = Vector2.new(0.5, 0),
			MaxTextSize = 60,
			StrokeThickness = 0,
			ZIndex = 2,
		})
		icon.Rotation = -6
		if STARS[pet.Rarity] then
			Components.Label({
				Name = "Stars",
				Text = string.rep("⭐", STARS[pet.Rarity]),
				Parent = card,
				Size = UDim2.fromOffset(60, 20),
				Position = UDim2.fromOffset(2, 0),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 18,
				StrokeThickness = 0,
				ZIndex = 2,
			})
		end
		Components.Label({
			Text = pet.Name,
			Parent = card,
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.new(0.5, 0, 0, 64),
			AnchorPoint = Vector2.new(0.5, 0),
			MaxTextSize = 20,
		})
		Components.Label({
			Text = Format.Weight(pet.Weight),
			Parent = card,
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0.5, 0, 0, 90),
			AnchorPoint = Vector2.new(0.5, 0),
			MaxTextSize = 17,
		})
		Components.Label({
			Text = "+" .. Format.Money(SellConfig.GetIncome(pet)) .. "/s",
			Parent = card,
			Size = UDim2.new(1, -10, 0, 22),
			Position = UDim2.new(0.5, 0, 0, 114),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = Theme.Colors.Yellow[1],
			MaxTextSize = 19,
		})
		if pet.Equipped then
			local badge = Components.Box({
				Parent = card,
				Size = UDim2.fromOffset(34, 34),
				Position = UDim2.new(1, 8, 0, -8),
				AnchorPoint = Vector2.new(1, 0),
				Colors = Theme.Colors.Mint,
				CornerRadius = UDim.new(1, 0),
				ZIndex = 2,
			})
			Components.Label({
				Text = "✔",
				Parent = badge,
				Size = UDim2.fromScale(0.7, 0.7),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 2,
			})
		end

		card.Activated:Connect(function()
			invoke("EquipPet", id, not pet.Equipped)
		end)
		card.Parent = grid
	end

	local function refresh()
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
			makeCard(id, pets[id], order)
		end

		equippedLabel.Text = `Equipped {equipped}/{PlayerConfig.MaxEquippedPets}`
		incomeLabel.Text = if income > 0 then "+" .. Format.Money(income) .. "/s" else ""

		if #ids == 0 then
			Components.Label({
				Text = "No pets yet!\nGrab an egg from the islands.",
				Parent = grid,
				Wrapped = true,
				MaxTextSize = 22,
				Color = Theme.Colors.Purple[1],
			})
		end
	end

	ClientState.Changed:Connect(function()
		if window.IsOpen() then
			refresh()
		end
	end)

	local panel = { Window = window }

	function panel.Open()
		refresh()
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
