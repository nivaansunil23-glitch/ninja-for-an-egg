-- Always-on HUD: money and jump power pills, side menu buttons, the height
-- tracker on the right and the jetpack fuel bar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local PlayerConfig = require(Shared:WaitForChild("Config"):WaitForChild("PlayerConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))

local player = Players.LocalPlayer

local Hud = {}

local function makePill(parent: Instance, icon: string, colors, position: UDim2)
	local pill = Components.Box({
		Name = "Pill",
		Parent = parent,
		Size = UDim2.fromScale(0.15, 0.07),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = colors,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
	})
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 3.8
	aspect.Parent = pill
	local minimum = Instance.new("UISizeConstraint")
	minimum.MinSize = Vector2.new(140, 37)
	minimum.Parent = pill

	Components.Label({
		Text = icon,
		Parent = pill,
		Size = UDim2.fromScale(0.24, 0.85),
		Position = UDim2.fromScale(0.04, 0.075),
	})
	local value = Components.Label({
		Name = "Value",
		Text = "0",
		Parent = pill,
		Size = UDim2.fromScale(0.66, 0.7),
		Position = UDim2.fromScale(0.3, 0.15),
		XAlign = Enum.TextXAlignment.Left,
		StrokeThickness = 2.5,
	})
	return pill, value
end

local function makeSideButton(parent: Instance, icon: string, text: string, colors, order: number, onClick)
	local button = Components.Button({
		Name = text,
		Text = icon,
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		Colors = colors,
		CornerRadius = UDim.new(0.28, 0),
		StrokeThickness = 4,
		LayoutOrder = order,
		LabelSize = UDim2.fromScale(0.7, 0.55),
		LabelPosition = UDim2.fromScale(0.5, 0.38),
		MaxTextSize = 60,
		OnClick = onClick,
	})
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = button
	Components.Label({
		Text = text,
		Parent = button,
		Size = UDim2.fromScale(0.94, 0.26),
		Position = UDim2.fromScale(0.5, 0.82),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 24,
	})
	return button
end

-- Floating "+$123" that drifts up from the money pill.
local function popMoney(parent: Instance, pill: GuiObject, amount: number)
	local label = Components.Label({
		Text = "+" .. Format.Money(amount),
		Parent = parent,
		Color = Theme.Colors.Yellow[1],
		Size = UDim2.fromScale(0.12, 0.05),
		Position = pill.Position + UDim2.fromScale(0, 0.08),
		AnchorPoint = Vector2.new(0.5, 0),
		MaxTextSize = 30,
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

local function groundY(): number
	local value = Workspace:GetAttribute("GroundY")
	return if type(value) == "number" then value else PlayerConfig.GroundY
end

local function buildHeightTracker(parent: Instance)
	local holder = Instance.new("Frame")
	holder.Name = "HeightTracker"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(0.07, 0.58)
	holder.Position = UDim2.fromScale(0.99, 0.55)
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Parent = parent

	local heightLabel = Components.Label({
		Text = "0m",
		Parent = holder,
		Size = UDim2.fromScale(1, 0.08),
		MaxTextSize = 30,
	})

	local bar = Components.Box({
		Name = "Bar",
		Parent = holder,
		Size = UDim2.fromScale(0.36, 0.8),
		Position = UDim2.fromScale(0.5, 0.1),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = { Color3.fromRGB(70, 60, 150), Color3.fromRGB(140, 220, 255) },
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
	})

	local fill = Components.Box({
		Name = "Fill",
		Parent = bar,
		Size = UDim2.fromScale(1, 0),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
		Colors = Theme.Colors.Pink,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 0,
	})

	local bestMarker = Components.Box({
		Name = "Best",
		Parent = bar,
		Size = UDim2.new(1.8, 0, 0, 6),
		Position = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Colors = Theme.Colors.Yellow,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		ZIndex = 2,
	})

	local you = Instance.new("ImageLabel")
	you.Name = "You"
	you.Size = UDim2.fromScale(1.9, 1.9)
	you.SizeConstraint = Enum.SizeConstraint.RelativeXX
	you.AnchorPoint = Vector2.new(0.5, 0.5)
	you.Position = UDim2.fromScale(0.5, 1)
	you.BackgroundColor3 = Color3.new(1, 1, 1)
	you.ZIndex = 3
	Components.Corner(you, UDim.new(1, 0))
	Components.Stroke(you, 3)
	you.Parent = bar
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok then
			you.Image = image
		end
	end)

	local bestLabel = Components.Label({
		Text = "🏆 0m",
		Parent = holder,
		Size = UDim2.fromScale(1, 0.07),
		Position = UDim2.fromScale(0, 0.93),
		Color = Theme.Colors.Yellow[1],
		MaxTextSize = 26,
	})

	local shownHeight = -1
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local height = if root then math.max(0, math.floor(root.Position.Y - groundY())) else 0
		local best = player:GetAttribute("BestHeight") or 0
		local maxHeight = math.max(PlayerConfig.HeightTrackerMax, best * 1.1, 1)

		local ratio = math.clamp(height / maxHeight, 0, 1)
		fill.Size = UDim2.fromScale(1, ratio)
		you.Position = UDim2.fromScale(0.5, 1 - ratio)
		bestMarker.Position = UDim2.fromScale(0.5, 1 - math.clamp(best / maxHeight, 0, 1))

		if height ~= shownHeight then
			shownHeight = height
			heightLabel.Text = Format.Short(height) .. "m"
		end
		bestLabel.Text = "🏆 " .. Format.Short(best) .. "m"
	end)
end

local function buildFuelBar(parent: Instance)
	local holder = Components.Box({
		Name = "JetpackFuel",
		Parent = parent,
		Size = UDim2.fromScale(0.22, 0.03),
		Position = UDim2.fromScale(0.5, 0.84),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Colors = Theme.Colors.Gray,
		CornerRadius = UDim.new(1, 0),
	})
	holder.Visible = false
	local fill = Components.Box({
		Name = "Fill",
		Parent = holder,
		Colors = Theme.Colors.Yellow,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 0,
	})
	Components.Label({
		Text = "🚀 Fuel",
		Parent = holder,
		Size = UDim2.fromScale(0.5, 1.6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 22,
		ZIndex = 2,
	})

	RunService.RenderStepped:Connect(function()
		local equipped = player:GetAttribute("JetpackEquipped") == true
		holder.Visible = equipped
		if equipped then
			fill.Size = UDim2.fromScale(math.clamp(player:GetAttribute("JetpackFuel") or 0, 0, 1), 1)
		end
	end)
end

-- actions = { Shop = fn, Pets = fn, Inventory = fn }
function Hud.Build(gui: ScreenGui, actions)
	-- Money and jump power, top middle.
	local moneyPill, moneyValue = makePill(gui, "💰", Theme.Colors.Yellow, UDim2.fromScale(0.41, 0.015))
	local jumpPill, jumpValue = makePill(gui, "⬆️", Theme.Colors.Sky, UDim2.fromScale(0.59, 0.015))

	local incomeLabel = Components.Label({
		Text = "",
		Parent = gui,
		Size = UDim2.fromScale(0.12, 0.035),
		Position = UDim2.fromScale(0.41, 0.095),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = Theme.Colors.Mint[1],
		MaxTextSize = 24,
	})

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
		incomeLabel.Text = if income > 0 then "+" .. Format.Money(income) .. "/s" else ""
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
	side.Size = UDim2.fromScale(0.075, 0.5)
	side.Position = UDim2.fromScale(0.012, 0.5)
	side.AnchorPoint = Vector2.new(0, 0.5)
	side.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.04, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = side
	local minimum = Instance.new("UISizeConstraint")
	minimum.MinSize = Vector2.new(64, 0)
	minimum.Parent = side

	makeSideButton(side, "🛒", "Shop", Theme.Colors.Pink, 1, actions.Shop)
	makeSideButton(side, "🐾", "Pets", Theme.Colors.Mint, 2, actions.Pets)
	makeSideButton(side, "🎒", "Inventory", Theme.Colors.Sky, 3, actions.Inventory)

	buildHeightTracker(gui)
	buildFuelBar(gui)
end

return Hud
