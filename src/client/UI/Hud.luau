-- Always-on HUD, Pet Simulator 99 style:
--   * money and jump on the left side: a big icon with bold outlined numbers
--   * a hotbar of big chunky icon buttons (no boxes) along the bottom middle
--   * the height bar along the top (HeightBar) and the jetpack fuel bar
-- The hotbar moves up out of the way when Roblox's tool bar is showing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local HeightBar = require(script.Parent:WaitForChild("HeightBar"))

local player = Players.LocalPlayer

local Hud = {}

local BOUNCE = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLIDE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Big icon with a bold number next to it, e.g. 💰 1.2K.
local function makeCounter(parent: Instance, icon: string, color: Color3, order: number)
	local row = Instance.new("Frame")
	row.Name = "Counter"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 62)
	row.LayoutOrder = order
	row.Parent = parent

	local iconLabel = Components.Label({
		Name = "Icon",
		Text = icon,
		Parent = row,
		Size = UDim2.fromOffset(62, 62),
		MaxTextSize = 56,
		StrokeThickness = 0,
	})
	iconLabel.Rotation = -8
	local value = Components.Label({
		Name = "Value",
		Text = "0",
		Parent = row,
		Size = UDim2.new(1, -70, 0, 46),
		Position = UDim2.new(0, 68, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = Enum.TextXAlignment.Left,
		Color = color,
		MaxTextSize = 44,
		StrokeThickness = 4,
	})
	return row, value
end

-- Hotbar button: a big icon with no box, its name underneath, and a red
-- notification badge (hidden until SetBadge).
local function makeHotbarButton(parent: Instance, icon: string, text: string, order: number, onClick)
	local button = Instance.new("TextButton")
	button.Name = text
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromOffset(86, 92)
	button.LayoutOrder = order
	button.Parent = parent
	local scale = Instance.new("UIScale")
	scale.Parent = button

	local iconLabel = Components.Label({
		Name = "Icon",
		Text = icon,
		Parent = button,
		Size = UDim2.fromOffset(72, 72),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		MaxTextSize = 64,
		StrokeThickness = 0,
	})
	Components.Label({
		Name = "Name",
		Text = text,
		Parent = button,
		Size = UDim2.new(1, 8, 0, 26),
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		MaxTextSize = 22,
		StrokeThickness = 3,
	})

	local badge = Components.Box({
		Name = "Badge",
		Parent = button,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -6, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Colors = Theme.Colors.Red,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
		ZIndex = 3,
	})
	badge.Visible = false
	local badgeText = Components.Label({
		Text = "!",
		Parent = badge,
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 20,
		ZIndex = 3,
	})

	button.MouseEnter:Connect(function()
		TweenService:Create(scale, BOUNCE, { Scale = 1.1 }):Play()
		TweenService:Create(iconLabel, BOUNCE, { Rotation = -8 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, BOUNCE, { Scale = 1 }):Play()
		TweenService:Create(iconLabel, BOUNCE, { Rotation = 0 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, BOUNCE, { Scale = 0.88 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, BOUNCE, { Scale = 1 }):Play()
	end)
	button.Activated:Connect(function()
		Components.Burst(button:FindFirstAncestorOfClass("ScreenGui"), Components.CenterOf(iconLabel), { "✨", "⭐" })
		onClick()
	end)

	local entry = { Button = button }
	function entry.SetBadge(value)
		badge.Visible = value ~= nil and value ~= 0 and value ~= false
		badgeText.Text = if type(value) == "number" then tostring(value) else "!"
	end
	return entry
end

-- Floating "+$123" that drifts up from the money counter.
local function popMoney(row: GuiObject, amount: number)
	local gui = row:FindFirstAncestorOfClass("ScreenGui")
	if not gui then
		return
	end
	local at = row.AbsolutePosition
	local label = Components.Label({
		Text = "+" .. Format.Money(amount),
		Parent = gui,
		Color = Theme.Colors.Mint[1],
		Size = UDim2.fromOffset(180, 34),
		Position = UDim2.fromOffset(at.X + 68, at.Y - 6),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 32,
		StrokeThickness = 3.5,
		ZIndex = 5,
	})
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, {
		Position = label.Position - UDim2.fromOffset(0, 40),
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
	holder.Position = UDim2.new(0.5, 0, 1, -190)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Visible = false
	holder.Parent = parent

	local track = Components.Box({
		Name = "Track",
		Parent = holder,
		Colors = { Color3.fromRGB(80, 65, 120), Color3.fromRGB(50, 35, 85) },
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 4,
	})
	local fill = Components.Box({
		Name = "Fill",
		Parent = track,
		Colors = Theme.Colors.Orange,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 0,
	})
	Components.Shine(fill, 0.4)
	Components.Label({
		Text = "🚀",
		Parent = holder,
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.new(0, -14, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 44,
		StrokeThickness = 0,
		ZIndex = 3,
	})
	local percent = Components.Label({
		Text = "Fuel",
		Parent = track,
		Size = UDim2.fromScale(0.6, 0.85),
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
			fill.Size = UDim2.fromScale(math.max(amount, 0.06), 1)
			fill.Visible = amount > 0
			percent.Text = string.format("Fuel %d%%", math.floor(amount * 100 + 0.5))
		end
	end)
end

-- True while Roblox's own tool bar is on screen (the player owns a tool).
local function hasTools(): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChildOfClass("Tool") then
		return true
	end
	local character = player.Character
	return character ~= nil and character:FindFirstChildOfClass("Tool") ~= nil
end

-- actions = { Shop = fn, Pets = fn, Inventory = fn }
function Hud.Build(gui: ScreenGui, actions)
	-- Money and jump, left middle.
	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.BackgroundTransparency = 1
	stats.Size = UDim2.fromOffset(260, 190)
	stats.Position = UDim2.new(0, 16, 0.42, 0)
	stats.AnchorPoint = Vector2.new(0, 0.5)
	stats.Parent = gui
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Padding = UDim.new(0, 4)
	statsLayout.Parent = stats

	local moneyRow, moneyValue = makeCounter(stats, "💰", Theme.Colors.Yellow[1], 1)
	local incomeLabel = Components.Label({
		Name = "Income",
		Text = "",
		Parent = stats,
		Size = UDim2.new(1, 0, 0, 26),
		XAlign = Enum.TextXAlignment.Left,
		Color = Theme.Colors.Mint[1],
		MaxTextSize = 24,
		StrokeThickness = 3,
		LayoutOrder = 2,
	})
	local incomePad = Instance.new("UIPadding")
	incomePad.PaddingLeft = UDim.new(0, 70)
	incomePad.Parent = incomeLabel
	local _, jumpValue = makeCounter(stats, "⬆️", Theme.Colors.Sky[1], 3)

	-- Phones: shrink the counters on small screens.
	local statsScale = Instance.new("UIScale")
	statsScale.Parent = stats

	local lastMoney = player:GetAttribute("Money")
	local function updateMoney()
		local money = player:GetAttribute("Money") or 0
		moneyValue.Text = Format.Money(money)
		if lastMoney and money > lastMoney then
			local gained = money - lastMoney
			-- Skip the every-second pet income so it doesn't spam the screen.
			if gained ~= player:GetAttribute("Income") then
				popMoney(moneyRow, gained)
				Components.Pop(moneyValue, 1.18)
			end
		end
		lastMoney = money
	end

	local function updateJump()
		jumpValue.Text = tostring(player:GetAttribute("JumpPower") or 50) .. " Jump"
		Components.Pop(jumpValue, 1.15)
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

	-- Hotbar, bottom middle.
	local hotbar = Instance.new("Frame")
	hotbar.Name = "Hotbar"
	hotbar.BackgroundTransparency = 1
	hotbar.AutomaticSize = Enum.AutomaticSize.X
	hotbar.Size = UDim2.fromOffset(0, 92)
	hotbar.Position = UDim2.new(0.5, 0, 1, -10)
	hotbar.AnchorPoint = Vector2.new(0.5, 1)
	hotbar.Parent = gui
	local hotbarLayout = Instance.new("UIListLayout")
	hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
	hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hotbarLayout.Padding = UDim.new(0, 14)
	hotbarLayout.Parent = hotbar
	local hotbarScale = Instance.new("UIScale")
	hotbarScale.Parent = hotbar

	makeHotbarButton(hotbar, "🎒", "Items", 1, actions.Inventory)
	makeHotbarButton(hotbar, "🛒", "Shop", 2, actions.Shop)
	makeHotbarButton(hotbar, "🐾", "Pets", 3, actions.Pets)

	local function fit()
		local size = gui.AbsoluteSize
		local s = math.clamp(math.min(size.X / 1100, size.Y / 700), 0.65, 1.1)
		statsScale.Scale = s
		hotbarScale.Scale = s
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	-- Move up above Roblox's tool bar while it's showing.
	local raised = nil
	task.spawn(function()
		while hotbar.Parent do
			local want = hasTools()
			if want ~= raised then
				raised = want
				TweenService:Create(hotbar, SLIDE, {
					Position = UDim2.new(0.5, 0, 1, if want then -78 else -10),
				}):Play()
			end
			task.wait(0.5)
		end
	end)

	HeightBar.Build(gui)
	buildFuelBar(gui)
end

return Hud
