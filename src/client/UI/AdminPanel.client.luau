-- Admin panel for the game owner (server checks it: server/Player/Admin).
-- A small gear button on the right (or press F4) opens a window to give yourself
-- jump levels or money, test day/night, get any animal's egg and teleport to islands. Only shows up when the server marks you "IsAdmin".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local EggConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EggConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local Icons = require(script.Parent:WaitForChild("Icons"))

local player = Players.LocalPlayer

-- Wait until the server says we're an admin (it may set it a moment after join).
while player:GetAttribute("IsAdmin") ~= true do
	player:GetAttributeChangedSignal("IsAdmin"):Wait()
end

local remote = Net.Function("AdminAction")

local gui = Instance.new("ScreenGui")
gui.Name = "AdminUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local window = Components.Window({
	Name = "Admin",
	Title = "Admin",
	Icon = "Gear",
	Parent = gui,
	Size = UDim2.fromOffset(540, 740),
	Colors = Theme.Colors.Purple,
})
-- The cards scroll inside the window so it stays a sensible size.
local content = Instance.new("ScrollingFrame")
content.Name = "Cards"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Size = UDim2.fromScale(1, 1)
content.CanvasSize = UDim2.new()
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
content.ScrollBarThickness = 8
content.ScrollBarImageColor3 = Theme.PanelOutline
content.ZIndex = 10
content.Parent = window.Content

local busy = false
local function run(action: string, amount: number)
	if busy then
		return
	end
	busy = true
	local ok, success, message = pcall(remote.InvokeServer, remote, action, amount)
	busy = false
	if not ok then
		Components.Notify(gui, "Admin request failed", Theme.Colors.Red[1])
	elseif success then
		Components.Notify(gui, tostring(message), Theme.Colors.Mint[1])
	else
		Components.Notify(gui, tostring(message), Theme.Colors.Red[1])
	end
end

-- Layout (pixels inside the window's content area, which is 504 x 642).
local GAP = 12
local CARD_PAD = 12
local HEADER_H = 26
local ROW_H = 50

-- Status pill: current level and jump power.
local statusPill = Components.Box({
	Name = "StatusPill",
	Parent = content,
	Size = UDim2.new(1, 0, 0, 40),
	Colors = Theme.Colors.NavyCard,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
	ZIndex = 11,
})
statusPill:FindFirstChildOfClass("UIStroke").Color = Theme.PanelOutline
local status = Components.Label({
	Name = "Status",
	Text = "",
	Parent = statusPill,
	Size = UDim2.new(1, -32, 1, -10),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	StrokeThickness = 2.5,
	MaxTextSize = 24,
	ZIndex = 12,
})
local function updateStatus()
	status.Text = string.format(
		"Level %s  ·  %s Jump",
		tostring(player:GetAttribute("JumpLevel") or 1),
		tostring(player:GetAttribute("JumpPower") or 50)
	)
end
for _, name in { "JumpLevel", "JumpPower" } do
	player:GetAttributeChangedSignal(name):Connect(updateStatus)
end
updateStatus()

-- A darker card with a small heading in its top-left corner.
-- rows = how many button rows it holds. Returns the card and the y where its
-- first row starts.
local function card(name: string, heading: string, y: number, rows: number)
	local height = CARD_PAD + HEADER_H + 6 + rows * ROW_H + (rows - 1) * 10 + CARD_PAD
	local frame = Components.Box({
		Name = name,
		Parent = content,
		Size = UDim2.new(1, 0, 0, height),
		Position = UDim2.fromOffset(0, y),
		Colors = Theme.Colors.NavyCard,
		CornerRadius = UDim.new(0, 14),
		StrokeThickness = 3,
		ZIndex = 11,
	})
	frame:FindFirstChildOfClass("UIStroke").Color = Theme.PanelOutline
	local title = Components.Label({
		Name = "Heading",
		Text = heading,
		Parent = frame,
		Size = UDim2.new(1, -2 * CARD_PAD, 0, HEADER_H),
		Position = UDim2.fromOffset(CARD_PAD, CARD_PAD - 2),
		XAlign = Enum.TextXAlignment.Left,
		StrokeThickness = 2.5,
		MaxTextSize = 24,
		ZIndex = 12,
	})
	title.Font = Theme.TitleFont
	return frame, height
end

local function rowY(index: number): number
	return CARD_PAD + HEADER_H + 6 + (index - 1) * (ROW_H + 10)
end

-- A row of equal buttons: { { Text, Colors, OnClick }, ... }
local function buttonRow(parent: GuiObject, y: number, buttons)
	local count = #buttons
	local gap = 10
	for i, info in buttons do
		Components.Button({
			Text = info[1],
			Parent = parent,
			-- Equal widths with a 10px gap between, inside the card padding.
			Size = UDim2.new(1 / count, -(2 * CARD_PAD + gap * (count - 1)) / count, 0, ROW_H),
			Position = UDim2.new(
				(i - 1) / count,
				CARD_PAD - (i - 1) * (2 * CARD_PAD + gap * (count - 1)) / count + (i - 1) * gap,
				0,
				y
			),
			Colors = info[2],
			CornerRadius = UDim.new(0, 14),
			MaxTextSize = 24,
			ZIndex = 13,
			OnClick = info[3],
		})
	end
end

-- Jump card: quick level buttons, then type a level and press Set.
local jumpY = 40 + GAP
local jumpCard, jumpHeight = card("JumpCard", "Jump", jumpY, 2)
buttonRow(jumpCard, rowY(1), {
	{ "+10 Lv", Theme.Colors.Sky, function() run("AddLevels", 10) end },
	{ "+100 Lv", Theme.Colors.Sky, function() run("AddLevels", 100) end },
	{ "Max", Theme.Colors.Purple, function() run("SetLevel", 1e6) end },
	{ "Reset", Theme.Colors.Red, function() run("SetLevel", 1) end },
})

local box = Instance.new("TextBox")
box.Name = "LevelBox"
box.PlaceholderText = "Type a level..."
box.Text = ""
box.Font = Theme.Font
box.TextScaled = false
box.TextSize = 24
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextColor3 = Theme.Text
box.PlaceholderColor3 = Color3.fromRGB(150, 160, 205)
box.ClearTextOnFocus = false
box.BackgroundColor3 = Theme.PanelOutline
box.BackgroundTransparency = 0.25
box.Size = UDim2.new(0.62, -CARD_PAD - 5, 0, ROW_H)
box.Position = UDim2.fromOffset(CARD_PAD, rowY(2))
box.ZIndex = 13
Components.Corner(box, UDim.new(0, 14))
Components.Stroke(box, 3, Theme.PanelOutline)
local boxPadding = Instance.new("UIPadding")
boxPadding.PaddingLeft = UDim.new(0, 16)
boxPadding.PaddingRight = UDim.new(0, 16)
boxPadding.Parent = box
box.Parent = jumpCard

local function setTyped()
	local level = tonumber(box.Text)
	if level then
		run("SetLevel", level)
	else
		Components.Notify(gui, "Type a number first", Theme.Colors.Yellow[1])
	end
end
box.FocusLost:Connect(function(enter)
	if enter then
		setTyped()
	end
end)
Components.Button({
	Text = "Set Level",
	Parent = jumpCard,
	Size = UDim2.new(0.38, -CARD_PAD - 5, 0, ROW_H),
	Position = UDim2.new(0.62, 5, 0, rowY(2)),
	Colors = Theme.Colors.Mint,
	CornerRadius = UDim.new(0, 14),
	MaxTextSize = 24,
	ZIndex = 13,
	OnClick = setTyped,
})

-- Money card.
local moneyY = jumpY + jumpHeight + GAP
local moneyCard, moneyHeight = card("MoneyCard", "Money", moneyY, 1)
buttonRow(moneyCard, rowY(1), {
	{ "+1K", Theme.Colors.Yellow, function() run("AddMoney", 1e3) end },
	{ "+1M", Theme.Colors.Yellow, function() run("AddMoney", 1e6) end },
	{ "+1B", Theme.Colors.Orange, function() run("AddMoney", 1e9) end },
})

-- Day/night card: force a phase, skip to the next one, or reset island eggs.
local dayNightY = moneyY + moneyHeight + GAP
local dayNightCard, dayNightHeight = card("DayNightCard", "Day / Night", dayNightY, 1)
buttonRow(dayNightCard, rowY(1), {
	{ "Force Day", Theme.Colors.Sky, function() run("ForceDay", 0) end },
	{ "Force Night", Theme.Colors.Purple, function() run("ForceNight", 0) end },
	{ "Skip Phase", Theme.Colors.Mint, function() run("SkipPhase", 0) end },
	{ "Reset Eggs", Theme.Colors.Orange, function() run("ResetEggs", 0) end },
})

-- Eggs card: pick any animal's egg with the arrows and get it in your hands,
-- play its hatch animation right away (only on your screen, nothing saved),
-- make every egg in your pen ready to hatch, or crack the egg you're carrying.
local eggY = dayNightY + dayNightHeight + GAP
local eggCard, eggHeight = card("EggCard", "Eggs", eggY, 2)
local eggIndex = 1
local eggName = Components.Label({
	Name = "EggName",
	Text = "",
	Parent = eggCard,
	Size = UDim2.new(1, -(2 * CARD_PAD + 2 * 56 + 160 + 30), 0, ROW_H),
	Position = UDim2.fromOffset(CARD_PAD + 56 + 10, rowY(1)),
	Wrapped = true,
	StrokeThickness = 2.5,
	MaxTextSize = 20,
	ZIndex = 13,
})
local function showEgg()
	local egg = EggConfig.Eggs[EggConfig.EggOrder[eggIndex]]
	eggName.Text = string.format("%s\n%s · %s", egg.DisplayName, egg.Rarity, egg.Island)
	eggName.TextColor3 = EggConfig.RarityColors[egg.Rarity] or Theme.Text
end
local function stepEgg(by: number)
	eggIndex = (eggIndex - 1 + by) % #EggConfig.EggOrder + 1
	showEgg()
end
Components.Button({
	Text = "<",
	Parent = eggCard,
	Size = UDim2.fromOffset(56, ROW_H),
	Position = UDim2.fromOffset(CARD_PAD, rowY(1)),
	Colors = Theme.Colors.Sky,
	CornerRadius = UDim.new(0, 14),
	MaxTextSize = 28,
	ZIndex = 13,
	OnClick = function() stepEgg(-1) end,
})
Components.Button({
	Text = ">",
	Parent = eggCard,
	Size = UDim2.fromOffset(56, ROW_H),
	Position = UDim2.new(1, -(CARD_PAD + 160 + 10 + 56), 0, rowY(1)),
	Colors = Theme.Colors.Sky,
	CornerRadius = UDim.new(0, 14),
	MaxTextSize = 28,
	ZIndex = 13,
	OnClick = function() stepEgg(1) end,
})
Components.Button({
	Text = "Give Egg",
	Parent = eggCard,
	Size = UDim2.fromOffset(160, ROW_H),
	Position = UDim2.new(1, -(CARD_PAD + 160), 0, rowY(1)),
	Colors = Theme.Colors.Mint,
	CornerRadius = UDim.new(0, 14),
	MaxTextSize = 24,
	ZIndex = 13,
	OnClick = function() run("GiveEgg", eggIndex) end,
})
buttonRow(eggCard, rowY(2), {
	{ "Test Hatch", Theme.Colors.Purple, function()
		local hatchUI = player.PlayerGui:FindFirstChild("HatchUI")
		local preview = hatchUI and hatchUI:FindFirstChild("PreviewHatch")
		if not preview then
			Components.Notify(gui, "Hatch screen isn't loaded yet", Theme.Colors.Red[1])
			return
		end
		local eggId = EggConfig.EggOrder[eggIndex]
		local egg = EggConfig.Eggs[eggId]
		local pet = egg.Pets[1]
		window.Close()
		preview:Fire({
			EggId = eggId,
			Pet = { Name = pet.Name, Rarity = pet.Rarity, Weight = math.floor(egg.KgMin * (pet.SizeMul or 1) * 100) / 100 },
		})
	end },
	{ "Ready Eggs", Theme.Colors.Orange, function() run("ReadyEggs", 0) end },
	{ "Crack Egg", Theme.Colors.Red, function() run("CrackEgg", 0) end },
})
showEgg()

-- Teleport card: jump to the base (your pen) or straight onto any island.
local teleportCard = card("TeleportCard", "Teleport", eggY + eggHeight + GAP, 1)
local teleportButtons = { { "Base", Theme.Colors.Mint, function() run("Teleport", 0) end } }
for n = 1, 8 do
	table.insert(teleportButtons, { tostring(n), Theme.Colors.Sky, function() run("Teleport", n) end })
end
buttonRow(teleportCard, rowY(1), teleportButtons)

-- Small gear button on the right edge, under the HUD's Pets button.
local adminButton = Components.Button({
	Name = "AdminButton",
	Text = "",
	Parent = gui,
	Size = UDim2.fromOffset(54, 54),
	Position = UDim2.new(1, -14, 0.42, 120),
	AnchorPoint = Vector2.new(1, 0),
	Colors = Theme.Colors.Purple,
	CornerRadius = UDim.new(0, 16),
	StrokeThickness = 3.5,
	MaxTextSize = 34,
	TextStroke = 0,
	OnClick = function()
		if window.IsOpen() then
			window.Close()
		else
			window.Open()
		end
	end,
})

Icons.Make("Gear", adminButton, {
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.fromScale(0.5, 0.46),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ZIndex = 3,
})

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F4 then
		if window.IsOpen() then
			window.Close()
		else
			window.Open()
		end
	end
end)
