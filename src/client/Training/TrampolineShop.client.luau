-- Trampoline upgrade window. Opens from the "Upgrade" prompt next to a
-- trampoline. Shows every tier (themed after the islands), what it gives per
-- bounce, and buys the next one. The server checks the price and that you've
-- reached the tier's island (Training/TrainingService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local Bubbly = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Bubbly"))

local player = Players.LocalPlayer

local openRemote = Net.Event("OpenTrampolineShop")
local buyRemote = Net.Function("BuyTrampoline")

local WINDOW_SIZE = Vector2.new(600, 460)
local ROW_HEIGHT = 74
local CLOSE_DISTANCE = 30 -- walk this far from where you opened it and it closes
local POP_IN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local gui = Instance.new("ScreenGui")
gui.Name = "TrampolineShopUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")

local window = Bubbly.Box({
	Name = "Window",
	Parent = gui,
	Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y),
	Position = UDim2.fromScale(0.5, 0.53),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Colors = Bubbly.Colors.Panel,
	CornerRadius = UDim.new(0, 28),
	StrokeThickness = 5,
	ZIndex = 10,
})
window.Visible = false
local windowScale = Instance.new("UIScale")
windowScale.Parent = window

local ribbon = Bubbly.Box({
	Name = "Title",
	Parent = window,
	Size = UDim2.fromOffset(320, 60),
	Position = UDim2.new(0.5, 0, 0, -26),
	AnchorPoint = Vector2.new(0.5, 0),
	Colors = Bubbly.Colors.Pink,
	CornerRadius = UDim.new(0, 20),
	StrokeThickness = 4,
	ZIndex = 11,
})
Bubbly.Label({
	Text = "Trampolines",
	Parent = ribbon,
	Size = UDim2.fromScale(0.85, 0.72),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	MaxTextSize = 38,
	StrokeThickness = 3,
	ZIndex = 11,
})

local subtitle = Bubbly.Label({
	Text = "",
	Parent = window,
	Size = UDim2.new(1, -60, 0, 26),
	Position = UDim2.fromOffset(30, 44),
	Color = Color3.fromRGB(255, 225, 90),
	MaxTextSize = 24,
	ZIndex = 11,
})

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Position = UDim2.fromOffset(20, 80)
list.Size = UDim2.new(1, -40, 1, -100)
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollBarThickness = 8
list.ScrollBarImageColor3 = Bubbly.Outline
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ZIndex = 11
list.Parent = window
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = list
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = list

local toast = Bubbly.Label({
	Text = "",
	Parent = window,
	Size = UDim2.new(1, -40, 0, 30),
	Position = UDim2.new(0, 20, 1, 8),
	MaxTextSize = 28,
	StrokeThickness = 3,
	ZIndex = 12,
})

local openedAt: Vector3? = nil
local busy = false
local rows = {}

local function fitScale(): number
	local camera = Workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return math.min(1.2, viewport.X * 0.94 / WINDOW_SIZE.X, viewport.Y * 0.8 / WINDOW_SIZE.Y)
end

local function islandName(number: number): string
	for _, island in JumpBalance.GetIslands() do
		if island.Number == number then
			return island.Name
		end
	end
	return "Island " .. number
end

local function showToast(text: string, color: Color3)
	toast.Text = text
	toast.TextColor3 = color
	toast.TextTransparency = 0
	Bubbly.Pop(toast, 0.6)
	local shown = text
	task.delay(2.5, function()
		if toast.Text == shown then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end
	end)
end

local function refresh()
	local owned = player:GetAttribute("TrampolineTier") or 1
	local reached = player:GetAttribute("IslandReached") or 0
	local money = player:GetAttribute("Money") or 0
	local current = JumpBalance.Tier(owned)
	subtitle.Text = `You have the {current.Name}: +{Format.Short(current.XpPerBounce)} Jump XP every bounce and click`

	for tier, row in rows do
		local entry = row.Entry
		local text, colors
		if tier < owned then
			text, colors = "Owned", Bubbly.Colors.Gray
		elseif tier == owned then
			text, colors = "Using", Bubbly.Colors.Mint
		elseif tier == owned + 1 then
			if reached < entry.Island then
				text, colors = `Reach {islandName(entry.Island)}`, Bubbly.Colors.Gray
			else
				text = Format.Money(entry.Price)
				colors = if money >= entry.Price then Bubbly.Colors.Yellow else Bubbly.Colors.Red
			end
		else
			text, colors = Format.Money(entry.Price), Bubbly.Colors.Gray
		end
		row.Label.Text = text
		Bubbly.SetColors(row.Button, colors)
	end
end

local function buy(tier: number)
	if busy then
		return
	end
	busy = true
	local ok, success, message = pcall(function()
		return buyRemote:InvokeServer(tier)
	end)
	busy = false
	if not ok then
		showToast("Couldn't reach the server, try again", Bubbly.Colors.Red[1])
	elseif success then
		showToast(message or "Unlocked!", Bubbly.Colors.Mint[1])
	else
		showToast(message or "Can't buy that yet", Bubbly.Colors.Red[1])
	end
	refresh()
end

for tier, entry in JumpBalance.TrampolineTiers do
	local row = Bubbly.Box({
		Name = entry.Skin,
		Parent = list,
		Size = UDim2.new(1, -16, 0, ROW_HEIGHT),
		Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(242, 234, 255) },
		ZIndex = 11,
	})
	row.LayoutOrder = tier

	-- A round trampoline badge in the tier's colour.
	local badge = Bubbly.Box({
		Name = "Badge",
		Parent = row,
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.new(0, 38, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Colors = Bubbly.FromColor(entry.Color),
		CornerRadius = UDim.new(1, 0),
		ZIndex = 12,
	})
	Bubbly.Label({
		Text = tostring(tier),
		Parent = badge,
		Size = UDim2.fromScale(0.6, 0.6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 26,
		ZIndex = 13,
	})

	Bubbly.Label({
		Text = entry.Name,
		Parent = row,
		Size = UDim2.new(0.55, 0, 0, 30),
		Position = UDim2.fromOffset(76, 8),
		XAlign = Enum.TextXAlignment.Left,
		Color = Bubbly.Outline,
		StrokeThickness = 0,
		MaxTextSize = 26,
		ZIndex = 12,
	})
	local need = if entry.Island > 0 then ` · from {islandName(entry.Island)}` else ""
	Bubbly.Label({
		Text = `+{Format.Short(entry.XpPerBounce)} Jump XP{need}`,
		Parent = row,
		Size = UDim2.new(0.55, 0, 0, 22),
		Position = UDim2.fromOffset(76, 42),
		XAlign = Enum.TextXAlignment.Left,
		Color = Bubbly.Colors.Sky[2],
		StrokeThickness = 0,
		MaxTextSize = 20,
		ZIndex = 12,
	})

	local button, label = Bubbly.Button({
		Name = "Buy",
		Parent = row,
		Size = UDim2.fromOffset(170, 50),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		MaxTextSize = 24,
		ZIndex = 12,
		OnClick = function()
			buy(tier)
		end,
	})
	rows[tier] = { Button = button, Label = label, Entry = entry }
end

local function close()
	window.Visible = false
	openedAt = nil
end

Bubbly.Button({
	Name = "Close",
	Text = "X",
	Parent = window,
	Size = UDim2.fromOffset(58, 58),
	Position = UDim2.new(1, 16, 0, -16),
	AnchorPoint = Vector2.new(1, 0),
	Colors = Bubbly.Colors.Red,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 4,
	MaxTextSize = 36,
	ZIndex = 12,
	OnClick = close,
})

local function open()
	refresh()
	toast.Text = ""
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	openedAt = if root then root.Position else nil
	local target = fitScale()
	windowScale.Scale = target * 0.6
	window.Visible = true
	TweenService:Create(windowScale, POP_IN, { Scale = target }):Play()
end

openRemote.OnClientEvent:Connect(open)
for _, attribute in { "TrampolineTier", "IslandReached", "Money" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if window.Visible then
			refresh()
		end
	end)
end

-- Close it once you walk away from the trampoline.
task.spawn(function()
	while true do
		task.wait(0.5)
		if window.Visible and openedAt then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - openedAt).Magnitude > CLOSE_DISTANCE then
				close()
			end
		end
	end
end)
