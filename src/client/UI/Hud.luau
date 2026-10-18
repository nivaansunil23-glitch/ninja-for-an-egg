-- Always-on HUD: money and jump power pills, side menu buttons, the height
-- bar along the bottom (HeightBar) and the jetpack fuel bar.
-- BGSI style: chunky pills with a round icon badge breaking out of the left
-- edge, square menu buttons with a name ribbon, soft shadows under everything.

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

-- Transparent holder with a soft shadow inside it, so size limits on the
-- holder apply to the shadow and the piece on top alike.
local function shadowHolder(parent: Instance, name: string, radius: UDim, drop: number)
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = Theme.Shadow
	shadow.BackgroundTransparency = 0.55
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, drop)
	Components.Corner(shadow, radius)
	shadow.Parent = holder
	return holder
end

-- Round icon badge, e.g. the coin on the money pill.
local function badge(parent: Instance, icon: string, colors, size: UDim2, position: UDim2, anchor: Vector2)
	local circle = Components.Box({
		Name = "Badge",
		Parent = parent,
		Size = size,
		Position = position,
		AnchorPoint = anchor,
		Colors = colors,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3.5,
		ZIndex = 3,
		Lip = true,
	})
	circle.SizeConstraint = Enum.SizeConstraint.RelativeYY
	Components.Shine(circle, 0.45)
	Components.Label({
		Name = "Icon",
		Text = icon,
		Parent = circle,
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.5, 0.47),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 40,
		StrokeThickness = 0,
		ZIndex = 4,
	})
	return circle
end

local function makePill(parent: Instance, icon: string, colors, badgeColors, position: UDim2)
	local holder = shadowHolder(parent, "Pill", UDim.new(1, 0), 5)
	holder.Size = UDim2.fromScale(0.16, 0.07)
	holder.Position = position
	holder.AnchorPoint = Vector2.new(0.5, 0)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 3.6
	aspect.Parent = holder
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(150, 42)
	limits.MaxSize = Vector2.new(300, 84)
	limits.Parent = holder

	local pill = Components.Box({
		Name = "Body",
		Parent = holder,
		Colors = colors,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3.5,
		ZIndex = 2,
		Lip = true,
	})
	Components.Shine(pill, 0.4)

	badge(holder, icon, badgeColors, UDim2.fromScale(1.25, 1.25), UDim2.new(0, -6, 0.5, 0), Vector2.new(0.25, 0.5))

	local value = Components.Label({
		Name = "Value",
		Text = "0",
		Parent = pill,
		Size = UDim2.fromScale(0.68, 0.62),
		Position = UDim2.fromScale(0.27, 0.13),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 36,
		StrokeThickness = 3,
		ZIndex = 3,
	})
	return holder, value
end

local function makeSideButton(parent: Instance, icon: string, text: string, colors, order: number, onClick)
	local holder = shadowHolder(parent, text, UDim.new(0.28, 0), 6)
	holder.Size = UDim2.fromScale(1, 1)
	holder.LayoutOrder = order
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = holder

	local button
	button = Components.Button({
		Name = "Button",
		Text = icon,
		Parent = holder,
		Size = UDim2.fromScale(1, 1),
		Colors = colors,
		CornerRadius = UDim.new(0.28, 0),
		StrokeThickness = 4,
		ZIndex = 2,
		LabelSize = UDim2.fromScale(0.66, 0.56),
		LabelPosition = UDim2.fromScale(0.5, 0.4),
		MaxTextSize = 64,
		TextStroke = 0,
		OnClick = function()
			Components.Burst(button:FindFirstAncestorOfClass("ScreenGui"), Components.CenterOf(button), { "✨", "💖", "⭐" })
			onClick()
		end,
	})

	-- Name ribbon across the bottom edge.
	local ribbon = Components.Tag({
		Name = "NameTag",
		Text = text,
		Parent = button,
		Size = UDim2.fromScale(1.08, 0.32),
		Position = UDim2.fromScale(0.5, 1.06),
		AnchorPoint = Vector2.new(0.5, 1),
		Colors = { Color3.fromRGB(95, 70, 150), Theme.Outline },
		StrokeThickness = 3,
		MaxTextSize = 22,
		ZIndex = 3,
	})
	ribbon.Rotation = order % 2 == 0 and 2 or -2

	-- Icon gently bobs and tilts, each button a little out of step.
	local iconLabel = button:FindFirstChild("Text")
	if iconLabel then
		task.spawn(function()
			local t = order * 0.7
			while button.Parent do
				t += task.wait()
				iconLabel.Rotation = math.sin(t * 2.2) * 6
				iconLabel.Position = UDim2.fromScale(0.5, 0.4 + math.sin(t * 3) * 0.02)
			end
		end)
	end
	return holder
end

-- Floating "+$123" that drifts up from the money pill.
local function popMoney(parent: Instance, pill: GuiObject, amount: number)
	local label = Components.Label({
		Text = "+" .. Format.Money(amount),
		Parent = parent,
		Color = Theme.Colors.Yellow[1],
		Size = UDim2.fromScale(0.12, 0.05),
		Position = pill.Position + UDim2.fromScale(0, 0.09),
		AnchorPoint = Vector2.new(0.5, 0),
		MaxTextSize = 32,
		StrokeThickness = 3,
		ZIndex = 5,
	})
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, {
		Position = label.Position + UDim2.fromScale(0, 0.06),
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
	local holder = shadowHolder(parent, "JetpackFuel", UDim.new(1, 0), 4)
	holder.Size = UDim2.fromScale(0.22, 0.035)
	holder.Position = UDim2.fromScale(0.5, 0.82)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Visible = false
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(200, 24)
	limits.Parent = holder

	local track = Components.Box({
		Name = "Track",
		Parent = holder,
		Colors = { Color3.fromRGB(80, 65, 120), Color3.fromRGB(50, 35, 85) },
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3.5,
		ZIndex = 2,
	})
	local fill = Components.Box({
		Name = "Fill",
		Parent = track,
		Colors = Theme.Colors.Orange,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 0,
		ZIndex = 2,
	})
	Components.Shine(fill, 0.4)
	badge(holder, "🚀", Theme.Colors.Orange, UDim2.fromScale(1.7, 1.7), UDim2.new(0, -4, 0.5, 0), Vector2.new(0.5, 0.5))
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

-- actions = { Shop = fn, Pets = fn, Inventory = fn }
function Hud.Build(gui: ScreenGui, actions)
	-- Money and jump power, top middle.
	local moneyPill, moneyValue = makePill(gui, "💰", Theme.Colors.Yellow, Theme.Colors.Orange, UDim2.fromScale(0.4, 0.018))
	local jumpPill, jumpValue = makePill(gui, "⬆️", Theme.Colors.Sky, Theme.Colors.Purple, UDim2.fromScale(0.6, 0.018))

	-- "+$5/s" chip under the money pill.
	local incomeChip, incomeLabel = Components.Tag({
		Name = "Income",
		Text = "",
		Parent = gui,
		Size = UDim2.fromScale(0.09, 0.034),
		Position = UDim2.fromScale(0.41, 0.1),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = Theme.Colors.Mint,
		StrokeThickness = 3,
		MaxTextSize = 22,
	})
	local chipLimits = Instance.new("UISizeConstraint")
	chipLimits.MinSize = Vector2.new(90, 24)
	chipLimits.Parent = incomeChip
	incomeChip.Visible = false

	local lastMoney = player:GetAttribute("Money")
	local function updateMoney()
		local money = player:GetAttribute("Money") or 0
		moneyValue.Text = Format.Money(money)
		if lastMoney and money > lastMoney then
			local gained = money - lastMoney
			-- Skip the every-second pet income so it doesn't spam the screen.
			if gained ~= player:GetAttribute("Income") then
				popMoney(gui, moneyPill, gained)
				Components.Pop(moneyPill, 1.12)
			end
		end
		lastMoney = money
	end

	local function updateJump()
		jumpValue.Text = tostring(player:GetAttribute("JumpPower") or 50) .. " Jump"
		Components.Pop(jumpPill, 1.12)
	end

	local function updateIncome()
		local income = player:GetAttribute("Income") or 0
		incomeChip.Visible = income > 0
		incomeLabel.Text = "+" .. Format.Money(income) .. "/s"
	end

	player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
	player:GetAttributeChangedSignal("JumpPower"):Connect(updateJump)
	player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
	updateMoney()
	updateJump()
	updateIncome()

	-- Big side buttons, left middle.
	local side = Instance.new("Frame")
	side.Name = "SideButtons"
	side.BackgroundTransparency = 1
	side.Size = UDim2.fromScale(0.075, 0.52)
	side.Position = UDim2.fromScale(0.014, 0.5)
	side.AnchorPoint = Vector2.new(0, 0.5)
	side.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.06, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = side
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(66, 0)
	limits.MaxSize = Vector2.new(104, math.huge)
	limits.Parent = side

	makeSideButton(side, "🛒", "Shop", Theme.Colors.Pink, 1, actions.Shop)
	makeSideButton(side, "🐾", "Pets", Theme.Colors.Mint, 2, actions.Pets)
	makeSideButton(side, "🎒", "Items", Theme.Colors.Sky, 3, actions.Inventory)

	HeightBar.Build(gui)
	buildFuelBar(gui)
end

return Hud
