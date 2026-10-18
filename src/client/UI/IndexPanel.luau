-- Pet Index window, like Steal an Egg's: area tiles on the left (one per
-- egg), that area's progress bar and pet cards in the middle, the picked
-- pet's details and the area reward on the right, and total progress along
-- the bottom. Pets you've never owned show as dark silhouettes with "???".
-- Found pets come from ClientState.Data.Index; rewards are claimed through
-- ClaimIndex (server/Player/PetIndex).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local IndexConfig = require(Config:WaitForChild("IndexConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local Icons = require(script.Parent:WaitForChild("Icons"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local GOOD = Color3.fromRGB(140, 255, 170)
local BAD = Color3.fromRGB(255, 130, 130)
local SELECTED = Color3.fromRGB(255, 220, 60)
local GREEN_BAR = { Color3.fromRGB(140, 245, 110), Color3.fromRGB(60, 200, 70) }
local BLUE_BAR = { Color3.fromRGB(120, 210, 255), Color3.fromRGB(50, 140, 240) }
local GREY_BUTTON = { Color3.fromRGB(225, 228, 238), Color3.fromRGB(160, 165, 185) }
local TRACK = { Color3.fromRGB(26, 30, 56), Color3.fromRGB(18, 20, 40) }

local IndexPanel = {}

local function rarityColors(rarity: string)
	local color = SellConfig.RarityColors[rarity] or SellConfig.RarityColors.Common
	return { color:Lerp(Color3.new(1, 1, 1), 0.3), color }
end

-- Dark track with a bright fill, the count written across it and an icon at one end.
local function progressBar(parent: Instance, name: string, colors, iconName: string, iconAtEnd: boolean)
	local track = Components.Box({
		Name = name,
		Parent = parent,
		Colors = TRACK,
		CornerRadius = UDim.new(0, 10),
		StrokeThickness = 4,
	})
	track.Size = UDim2.new(1, -24, 1, 0)
	track.Position = if iconAtEnd then UDim2.new() else UDim2.fromOffset(24, 0)
	track.Parent = parent
	local fill = Components.Box({
		Name = "Fill",
		Parent = track,
		Colors = colors,
		CornerRadius = UDim.new(0, 8),
		StrokeThickness = 0,
	})
	Components.Shine(fill, 0.35)
	local text = Components.Label({
		Name = "Count",
		Text = "0/0",
		Parent = track,
		Size = UDim2.new(1, -20, 0.8, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 28,
		StrokeThickness = 3,
		ZIndex = 3,
	})
	text.Font = Theme.TitleFont
	Icons.Make(iconName, parent, {
		Size = UDim2.fromOffset(52, 52),
		Position = if iconAtEnd then UDim2.new(1, 4, 0.5, 0) else UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = if iconAtEnd then 10 else -10,
		ZIndex = 4,
	})

	return function(have: number, total: number, label: string?)
		local ratio = if total > 0 then have / total else 0
		fill.Visible = ratio > 0
		TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(math.max(ratio, 0.04), 1) }):Play()
		text.Text = (label or "") .. have .. "/" .. total
	end
end

function IndexPanel.new(gui: ScreenGui)
	local window = Components.Window({
		Name = "Index",
		Title = "Pet Index",
		Icon = "Book",
		Parent = gui,
		Size = UDim2.fromOffset(940, 560),
	})
	local content = window.Content
	local busy = false
	local currentArea = IndexConfig.Areas[1]
	local selectedPet = nil

	-- Left: area tiles.
	local areaList = Components.ScrollList({
		Name = "Areas",
		Parent = content,
		Size = UDim2.new(0, 150, 1, -50),
	})
	areaList.ScrollBarThickness = 6

	-- Middle: this area's progress and the pet grid.
	local middle = Instance.new("Frame")
	middle.Name = "Middle"
	middle.BackgroundTransparency = 1
	middle.Position = UDim2.fromOffset(162, 0)
	middle.Size = UDim2.new(1, -162 - 262, 1, -50)
	middle.Parent = content

	local areaBarHolder = Instance.new("Frame")
	areaBarHolder.BackgroundTransparency = 1
	areaBarHolder.Size = UDim2.new(1, -20, 0, 36)
	areaBarHolder.Position = UDim2.fromOffset(4, 4)
	areaBarHolder.Parent = middle
	local setAreaBar = progressBar(areaBarHolder, "AreaProgress", GREEN_BAR, "Paw", true)

	local grid = Components.ScrollList({
		Name = "Pets",
		Parent = middle,
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		Grid = true,
		CellSize = UDim2.fromOffset(100, 112),
	})
	grid.ScrollBarThickness = 6

	-- Right: picked pet and the area reward.
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(1, -250, 0, 0)
	right.Size = UDim2.new(0, 250, 1, -50)
	right.Parent = content

	local detail = Components.Box({
		Name = "Detail",
		Parent = right,
		Size = UDim2.new(1, 0, 0, 228),
		Colors = Theme.Colors.NavyCard,
		CornerRadius = UDim.new(0, 12),
		StrokeThickness = 4,
	})
	local detailArt = Components.Box({
		Name = "Art",
		Parent = detail,
		Size = UDim2.fromOffset(118, 118),
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = TRACK,
		CornerRadius = UDim.new(0, 12),
		StrokeThickness = 4,
	})
	local detailName = Components.Label({
		Name = "PetName",
		Text = "???",
		Parent = detail,
		Size = UDim2.new(1, -16, 0, 30),
		Position = UDim2.new(0.5, 0, 0, 134),
		AnchorPoint = Vector2.new(0.5, 0),
		MaxTextSize = 28,
		StrokeThickness = 3,
	})
	detailName.Font = Theme.TitleFont
	local detailTag, detailTagText = Components.Tag({
		Name = "Rarity",
		Text = "",
		Parent = detail,
		Size = UDim2.fromOffset(130, 28),
		Position = UDim2.new(0.5, 0, 0, 166),
		AnchorPoint = Vector2.new(0.5, 0),
		StrokeThickness = 3,
		MaxTextSize = 20,
	})
	local detailIncome = Components.Label({
		Name = "Income",
		Text = "",
		Parent = detail,
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0.5, 0, 0, 198),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = GOOD,
		MaxTextSize = 24,
		StrokeThickness = 3,
	})

	local rewards = Components.Box({
		Name = "Rewards",
		Parent = right,
		Size = UDim2.new(1, 0, 1, -240),
		Position = UDim2.fromOffset(0, 240),
		Colors = Theme.Colors.NavyCard,
		CornerRadius = UDim.new(0, 12),
		StrokeThickness = 4,
	})
	rewards:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(90, 220, 100)
	Components.Label({
		Text = "Rewards:",
		Parent = rewards,
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.fromOffset(10, 6),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 24,
		StrokeThickness = 3,
	}).Font = Theme.TitleFont

	local function rewardTile(x: number, iconName: string)
		local tile = Components.Box({
			Parent = rewards,
			Size = UDim2.new(0.5, -15, 0, 52),
			Position = UDim2.new(x, if x == 0 then 10 else 5, 0, 36),
			Colors = TRACK,
			CornerRadius = UDim.new(0, 10),
			StrokeThickness = 3,
		})
		Icons.Make(iconName, tile, {
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(0, 4, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = 2,
		})
		return Components.Label({
			Parent = tile,
			Size = UDim2.new(1, -50, 0.6, 0),
			Position = UDim2.new(0, 46, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			XAlign = Enum.TextXAlignment.Left,
			MaxTextSize = 20,
			StrokeThickness = 2.5,
			ZIndex = 2,
		})
	end
	local rewardMoney = rewardTile(0, "Cash")
	local rewardJump = rewardTile(0.5, "Shoe")

	local claimButton, claimText = Components.Button({
		Name = "Claim",
		Text = "CLAIM!",
		Parent = rewards,
		Size = UDim2.new(1, -20, 0, 54),
		Position = UDim2.new(0.5, 0, 1, -10),
		AnchorPoint = Vector2.new(0.5, 1),
		Colors = GREY_BUTTON,
		CornerRadius = UDim.new(0, 12),
		StrokeThickness = 4,
		MaxTextSize = 34,
		TextStroke = 3,
	})
	claimText.Font = Theme.TitleFont

	-- Bottom: total progress.
	local totalHolder = Instance.new("Frame")
	totalHolder.BackgroundTransparency = 1
	totalHolder.Size = UDim2.new(1, -190, 0, 38)
	totalHolder.Position = UDim2.new(0, 186, 1, -38)
	totalHolder.Parent = content
	local setTotalBar = progressBar(totalHolder, "TotalProgress", BLUE_BAR, "Book", false)

	local function found()
		return ClientState.Data and ClientState.Data.Index or {}
	end
	local function claimed()
		return ClientState.Data and ClientState.Data.IndexClaimed or {}
	end

	local function showPet(pet)
		selectedPet = pet
		for _, child in detailArt:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		if not pet then
			detailName.Text = "Pick a pet"
			detailTag.Visible = false
			detailIncome.Text = ""
			return
		end
		local isFound = found()[pet.Name] == true
		Components.SetColors(detailArt, if isFound then rarityColors(pet.Rarity) else TRACK)
		Icons.Make("Paw", detailArt, {
			Size = UDim2.fromOffset(86, 86),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = Color3.new(1, 1, 1),
			Silhouette = not isFound,
			ZIndex = 2,
		})
		detailName.Text = if isFound then pet.Name else "???"
		detailTag.Visible = true
		detailTagText.Text = string.upper(pet.Rarity)
		Components.SetColors(detailTag, rarityColors(pet.Rarity))
		if isFound then
			local ok, income = pcall(SellConfig.GetIncome, { Name = pet.Name, Rarity = pet.Rarity, Weight = 1 })
			detailIncome.Text = if ok then Format.Money(income) .. "/s" else ""
		else
			detailIncome.Text = "???"
		end
	end

	local function updateReward()
		local area = currentArea
		local have = IndexConfig.FoundIn(area, found())
		rewardMoney.Text = Format.Money(area.RewardMoney)
		rewardJump.Text = "+" .. area.RewardJumpLevels .. " Lv"
		if claimed()[area.Id] then
			claimText.Text = "CLAIMED!"
			Components.SetColors(claimButton, GREY_BUTTON)
		elseif have >= #area.Pets then
			claimText.Text = "CLAIM!"
			Components.SetColors(claimButton, Theme.Colors.Mint)
		else
			claimText.Text = "CLAIM!"
			Components.SetColors(claimButton, GREY_BUTTON)
		end
	end

	local function petCard(pet, order: number)
		local isFound = found()[pet.Name] == true
		local card = Instance.new("TextButton")
		card.Name = pet.Name
		card.Text = ""
		card.AutoButtonColor = false
		card.LayoutOrder = order
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		Components.Corner(card, UDim.new(0, 10))
		local stroke = Components.Stroke(card, 4)
		if selectedPet == pet then
			stroke.Color = SELECTED
		end
		Components.Gradient(card, if isFound then rarityColors(pet.Rarity) else Theme.Colors.NavyCard)
		Components.Shine(card, 0.25)
		Icons.Make("Paw", card, {
			Size = UDim2.fromOffset(62, 62),
			Position = UDim2.new(0.5, 0, 1, -8),
			AnchorPoint = Vector2.new(0.5, 1),
			Color = Color3.new(1, 1, 1),
			Silhouette = not isFound,
			ZIndex = 2,
		})
		Components.Label({
			Text = if isFound then pet.Name else "???",
			Parent = card,
			Size = UDim2.new(1, -10, 0, 30),
			Position = UDim2.fromOffset(5, 4),
			XAlign = Enum.TextXAlignment.Left,
			Wrapped = true,
			MaxTextSize = 16,
			StrokeThickness = 2.5,
			ZIndex = 3,
		})
		card.Activated:Connect(function()
			showPet(pet)
			for _, other in grid:GetChildren() do
				local otherStroke = other:IsA("TextButton") and other:FindFirstChildOfClass("UIStroke")
				if otherStroke then
					otherStroke.Color = if other == card then SELECTED else Theme.Outline
				end
			end
		end)
		card.Parent = grid
	end

	local refresh

	local function areaTile(area)
		local have = IndexConfig.FoundIn(area, found())
		local tile = Instance.new("TextButton")
		tile.Name = area.Id
		tile.Text = ""
		tile.AutoButtonColor = false
		tile.Size = UDim2.new(1, -14, 0, 92)
		tile.LayoutOrder = area.Number
		tile.BackgroundColor3 = Color3.new(1, 1, 1)
		Components.Corner(tile, UDim.new(0, 12))
		local stroke = Components.Stroke(tile, if area == currentArea then 5 else 4)
		if area == currentArea then
			stroke.Color = SELECTED
		end
		Components.Gradient(tile, { area.Color:Lerp(Color3.new(1, 1, 1), 0.25), area.Color:Lerp(Color3.new(), 0.25) })
		Components.Shine(tile, 0.3)
		Icons.Make("Egg", tile, {
			Size = UDim2.fromOffset(50, 50),
			Position = UDim2.new(0.5, 0, 0, 4),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = area.Color:Lerp(Color3.new(1, 1, 1), 0.45),
			ZIndex = 2,
		})
		local name = Components.Label({
			Text = area.Name,
			Parent = tile,
			Size = UDim2.new(1, -10, 0, 22),
			Position = UDim2.new(0.5, 0, 1, -24),
			AnchorPoint = Vector2.new(0.5, 0),
			MaxTextSize = 20,
			StrokeThickness = 2.5,
			ZIndex = 3,
		})
		name.Font = Theme.TitleFont
		if have >= #area.Pets then
			Icons.Make(if claimed()[area.Id] then "Check" else "Star", tile, {
				Size = UDim2.fromOffset(28, 28),
				Position = UDim2.new(1, -4, 0, 4),
				AnchorPoint = Vector2.new(1, 0),
				ZIndex = 3,
			})
		end
		tile.Activated:Connect(function()
			if currentArea ~= area then
				currentArea = area
				selectedPet = nil
				refresh()
			end
		end)
		tile.Parent = areaList
	end

	function refresh()
		Components.ClearList(areaList)
		for _, area in IndexConfig.Areas do
			areaTile(area)
		end

		Components.ClearList(grid)
		for order, pet in currentArea.Pets do
			petCard(pet, order)
		end
		setAreaBar(IndexConfig.FoundIn(currentArea, found()), #currentArea.Pets, currentArea.Name .. "  ")

		local totalFound = 0
		for _, area in IndexConfig.Areas do
			totalFound += IndexConfig.FoundIn(area, found())
		end
		setTotalBar(totalFound, IndexConfig.TotalPets(), "Unlocked: ")

		showPet(selectedPet or currentArea.Pets[1])
		updateReward()
	end

	claimButton.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		local remote = Net.Function("ClaimIndex")
		local ok, success, message = pcall(remote.InvokeServer, remote, currentArea.Id)
		busy = false
		if not ok then
			Components.Notify(gui, "Something went wrong, try again", BAD)
		else
			Components.Notify(gui, tostring(message), if success then GOOD else BAD)
			if success then
				Components.Burst(gui, Components.CenterOf(claimButton))
			end
		end
	end)

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

	-- How many areas are ready to claim (for the HUD badge).
	function panel.ReadyCount(): number
		local count = 0
		for _, area in IndexConfig.Areas do
			if not claimed()[area.Id] and IndexConfig.FoundIn(area, found()) >= #area.Pets then
				count += 1
			end
		end
		return count
	end

	return panel
end

return IndexPanel
