-- Always-on HUD, Steal an Egg style. It stays visible around open windows.
--   * left middle: wide Shop and Index buttons (icon + label)
--   * right middle: square orange Pets button with a pet-count badge
--   * bottom left: jump power and money in big outlined numbers with icons
--   * the height bar along the top (HeightBar) and the jetpack fuel bar
-- All icons are drawn by Icons (no emoji).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local Icons = require(script.Parent:WaitForChild("Icons"))
local HeightBar = require(script.Parent:WaitForChild("HeightBar"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local player = Players.LocalPlayer

local Hud = {}

local MONEY_GREEN = Color3.fromRGB(120, 255, 110)
local JUMP_BLUE = Color3.fromRGB(130, 220, 255)
local ORANGE = { Color3.fromRGB(255, 190, 80), Color3.fromRGB(245, 130, 30) }
local CYAN = { Color3.fromRGB(120, 235, 255), Color3.fromRGB(30, 180, 230) }
local GREEN = { Color3.fromRGB(130, 240, 110), Color3.fromRGB(50, 190, 70) }

-- Small red circle with a number, top-right of a button. Returns a setter.
local function badge(parent: GuiObject)
	local circle = Components.Box({
		Name = "Badge",
		Parent = parent,
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, 8, 0, -8),
		AnchorPoint = Vector2.new(1, 0),
		Colors = Theme.Colors.Red,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
		ZIndex = 5,
	})
	circle.Visible = false
	local text = Components.Label({
		Text = "",
		Parent = circle,
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 20,
		ZIndex = 5,
	})
	return function(count: number)
		circle.Visible = count > 0
		text.Text = if count > 99 then "99+" else tostring(count)
	end
end

-- Wide left-side button: drawn icon on the left, outlined label.
local function wideButton(parent: Instance, iconName: string, text: string, colors, order: number, onClick)
	local button, label = Components.Button({
		Name = text,
		Text = text,
		Parent = parent,
		Size = UDim2.fromOffset(190, 62),
		Colors = colors,
		CornerRadius = UDim.new(0, 14),
		StrokeThickness = 4,
		LayoutOrder = order,
		LabelSize = UDim2.new(1, -78, 0.6, 0),
		LabelPosition = UDim2.new(0.5, 30, 0.45, 0),
		MaxTextSize = 32,
		TextStroke = 3,
		OnClick = onClick,
	})
	label.Font = Theme.TitleFont
	label.TextXAlignment = Enum.TextXAlignment.Left
	Icons.Make(iconName, button, {
		Size = UDim2.fromOffset(56, 56),
		Position = UDim2.new(0, -6, 0.5, -2),
		AnchorPoint = Vector2.new(0, 0.5),
		Rotation = -8,
		ZIndex = 3,
	})
	return button
end

-- Square right-side button with a big drawn icon and a small label.
local function squareButton(parent: Instance, iconName: string, text: string, order: number, onClick)
	local button, label = Components.Button({
		Name = text,
		Text = text,
		Parent = parent,
		Size = UDim2.fromOffset(84, 84),
		Colors = ORANGE,
		CornerRadius = UDim.new(0, 16),
		StrokeThickness = 4,
		LayoutOrder = order,
		LabelSize = UDim2.new(1, -8, 0, 22),
		LabelPosition = UDim2.new(0.5, 0, 1, -16),
		MaxTextSize = 20,
		TextStroke = 3,
		OnClick = onClick,
	})
	label.Font = Theme.TitleFont
	Icons.Make(iconName, button, {
		Size = UDim2.fromOffset(56, 56),
		Position = UDim2.new(0.5, 0, 0, 4),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 3,
	})
	return button
end

-- Big icon with a big outlined number next to it.
local function stat(parent: Instance, iconName: string, color: Color3, order: number, textSize: number)
	local row = Instance.new("Frame")
	row.Name = iconName .. "Stat"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, textSize + 12)
	row.LayoutOrder = order
	row.Parent = parent
	Icons.Make(iconName, row, {
		Size = UDim2.fromOffset(textSize + 12, textSize + 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Rotation = -10,
		ZIndex = 2,
	})
	local value = Components.Label({
		Name = "Value",
		Text = "0",
		Parent = row,
		Size = UDim2.new(1, -(textSize + 20), 0, textSize),
		Position = UDim2.new(0, textSize + 18, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = Enum.TextXAlignment.Left,
		Color = color,
		MaxTextSize = textSize,
		StrokeThickness = 4,
	})
	value.Font = Theme.TitleFont
	return row, value
end

-- Floating "+$123" that drifts up from the money number.
local function popMoney(gui: ScreenGui, value: GuiObject, amount: number)
	local at = value.AbsolutePosition
	local label = Components.Label({
		Text = "+" .. Format.Money(amount),
		Parent = gui,
		Color = MONEY_GREEN,
		Size = UDim2.fromOffset(200, 36),
		Position = UDim2.fromOffset(at.X, at.Y - 40),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 34,
		StrokeThickness = 3.5,
		ZIndex = 5,
	})
	label.Font = Theme.TitleFont
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, {
		Position = label.Position - UDim2.fromOffset(0, 50),
		TextTransparency = 1,
	}):Play()
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
	task.delay(1, function()
		label:Destroy()
	end)
end

local function buildFuelBar(parent: Instance)
	local holder = Instance.new("Frame")
	holder.Name = "JetpackFuel"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(260, 28)
	holder.Position = UDim2.new(0.5, 0, 1, -150)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Visible = false
	holder.Parent = parent

	local track = Components.Box({
		Name = "Track",
		Parent = holder,
		Colors = { Color3.fromRGB(26, 30, 56), Color3.fromRGB(18, 20, 40) },
		CornerRadius = UDim.new(0, 10),
		StrokeThickness = 4,
	})
	local fill = Components.Box({
		Name = "Fill",
		Parent = track,
		Colors = Theme.Colors.Orange,
		CornerRadius = UDim.new(0, 8),
		StrokeThickness = 0,
	})
	Components.Shine(fill, 0.4)
	Icons.Make("Rocket", holder, {
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, -10, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 20,
		ZIndex = 3,
	})
	local percent = Components.Label({
		Text = "Fuel",
		Parent = track,
		Size = UDim2.fromScale(0.6, 0.8),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 20,
		ZIndex = 3,
	})

	RunService.RenderStepped:Connect(function()
		local equipped = player:GetAttribute("JetpackEquipped") == true
		holder.Visible = equipped
		if equipped then
			local amount = math.clamp(player:GetAttribute("JetpackFuel") or 0, 0, 1)
			fill.Size = UDim2.fromScale(math.max(amount, 0.05), 1)
			fill.Visible = amount > 0
			percent.Text = string.format("Fuel %d%%", math.floor(amount * 100 + 0.5))
		end
	end)
end

-- actions = { Shop = fn, Index = fn, Inventory = fn, IndexReady = fn -> number }
function Hud.Build(gui: ScreenGui, actions)
	local scales = {}
	local function fitted(frame: GuiObject)
		local scale = Instance.new("UIScale")
		scale.Parent = frame
		table.insert(scales, scale)
	end

	-- Left: Shop and Index.
	local left = Instance.new("Frame")
	left.Name = "LeftButtons"
	left.BackgroundTransparency = 1
	left.Size = UDim2.fromOffset(200, 150)
	left.Position = UDim2.new(0, 14, 0.42, 0)
	left.AnchorPoint = Vector2.new(0, 0.5)
	left.Parent = gui
	local leftLayout = Instance.new("UIListLayout")
	leftLayout.Padding = UDim.new(0, 14)
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Parent = left
	fitted(left)

	wideButton(left, "Cart", "Shop", GREEN, 1, actions.Shop)
	local indexButton = wideButton(left, "Book", "Index", CYAN, 2, actions.Index)
	local setIndexBadge = badge(indexButton)

	-- Right: Pets.
	local right = Instance.new("Frame")
	right.Name = "RightButtons"
	right.BackgroundTransparency = 1
	right.Size = UDim2.fromOffset(90, 200)
	right.Position = UDim2.new(1, -14, 0.42, 0)
	right.AnchorPoint = Vector2.new(1, 0.5)
	right.Parent = gui
	local rightLayout = Instance.new("UIListLayout")
	rightLayout.Padding = UDim.new(0, 14)
	rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Parent = right
	fitted(right)

	local petsButton = squareButton(right, "Paw", "Pets", 1, actions.Inventory)
	local setPetBadge = badge(petsButton)

	local function updateBadges()
		local pets = ClientState.Data and ClientState.Data.Pets or {}
		local count = 0
		for _ in pets do
			count += 1
		end
		setPetBadge(count)
		setIndexBadge(if actions.IndexReady then actions.IndexReady() else 0)
	end
	ClientState.Changed:Connect(updateBadges)
	updateBadges()

	-- Bottom left: jump and money.
	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.BackgroundTransparency = 1
	stats.Size = UDim2.fromOffset(330, 150)
	stats.Position = UDim2.new(0, 16, 1, -14)
	stats.AnchorPoint = Vector2.new(0, 1)
	stats.Parent = gui
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	statsLayout.Padding = UDim.new(0, 0)
	statsLayout.Parent = stats
	fitted(stats)

	local _, jumpValue = stat(stats, "Shoe", JUMP_BLUE, 1, 34)
	local _, moneyValue = stat(stats, "Cash", MONEY_GREEN, 2, 48)
	local incomeLabel = Components.Label({
		Name = "Income",
		Text = "",
		Parent = stats,
		Size = UDim2.new(1, 0, 0, 24),
		XAlign = Enum.TextXAlignment.Left,
		Color = MONEY_GREEN,
		MaxTextSize = 22,
		StrokeThickness = 3,
		LayoutOrder = 3,
	})
	local incomePad = Instance.new("UIPadding")
	incomePad.PaddingLeft = UDim.new(0, 68)
	incomePad.Parent = incomeLabel

	local lastMoney = player:GetAttribute("Money")
	local function updateMoney()
		local money = player:GetAttribute("Money") or 0
		moneyValue.Text = Format.Money(money)
		if lastMoney and money > lastMoney then
			local gained = money - lastMoney
			-- Skip the every-second pet income so it doesn't spam the screen.
			if gained ~= player:GetAttribute("Income") then
				popMoney(gui, moneyValue, gained)
				Components.Pop(moneyValue, 1.15)
			end
		end
		lastMoney = money
	end

	local function updateJump()
		jumpValue.Text = tostring(player:GetAttribute("JumpPower") or 50) .. " Jump"
		Components.Pop(jumpValue, 1.12)
	end

	local function updateIncome()
		local income = player:GetAttribute("Income") or 0
		incomeLabel.Text = if income > 0 then "+" .. Format.Money(income) .. "/s" else ""
	end

	player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
	player:GetAttributeChangedSignal("JumpPower"):Connect(updateJump)
	player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
	updateMoney()
	updateJump()
	updateIncome()

	-- Shrink everything a bit on small (phone) screens.
	local function fit()
		local size = gui.AbsoluteSize
		local s = math.clamp(math.min(size.X / 1200, size.Y / 720), 0.6, 1.1)
		for _, scale in scales do
			scale.Scale = s
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	HeightBar.Build(gui)
	buildFuelBar(gui)
end

return Hud
