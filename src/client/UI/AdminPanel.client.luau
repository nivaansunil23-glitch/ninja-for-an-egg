-- Admin panel for the game owner (server checks it: server/Player/Admin).
-- A small gear button on the right (or press F4) opens a window to give yourself
-- jump levels or money. Only shows up when the server marks you "IsAdmin".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
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
	Size = UDim2.fromOffset(520, 400),
	Colors = Theme.Colors.Purple,
})
local content = window.Content

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

local status = Components.Label({
	Name = "Status",
	Text = "",
	Parent = content,
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.fromOffset(0, 14),
	StrokeThickness = 2.5,
	MaxTextSize = 26,
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

local function sectionTitle(text: string, y: number)
	Components.Label({
		Text = text,
		Parent = content,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, y),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 24,
		StrokeThickness = 2.5,
	})
end

-- A row of equal buttons: { { Text, Colors, OnClick }, ... }
local function buttonRow(y: number, buttons)
	local width = 1 / #buttons
	for i, info in buttons do
		Components.Button({
			Text = info[1],
			Parent = content,
			Size = UDim2.new(width, -10, 0, 52),
			Position = UDim2.new(width * (i - 1), 5, 0, y),
			Colors = info[2],
			CornerRadius = UDim.new(0, 16),
			MaxTextSize = 24,
			OnClick = info[3],
		})
	end
end

sectionTitle("Jump", 56)
buttonRow(88, {
	{ "+10 Lv", Theme.Colors.Sky, function() run("AddLevels", 10) end },
	{ "+100 Lv", Theme.Colors.Sky, function() run("AddLevels", 100) end },
	{ "Max", Theme.Colors.Purple, function() run("SetLevel", 1e6) end },
	{ "Reset", Theme.Colors.Red, function() run("SetLevel", 1) end },
})

-- Type a level and press Set.
local box = Instance.new("TextBox")
box.Name = "LevelBox"
box.PlaceholderText = "Level..."
box.Text = ""
box.Font = Theme.Font
box.TextScaled = true
box.TextColor3 = Theme.DarkText
box.PlaceholderColor3 = Color3.fromRGB(160, 140, 190)
box.ClearTextOnFocus = false
box.Size = UDim2.new(0.66, -10, 0, 50)
box.Position = UDim2.new(0, 5, 0, 152)
box.BackgroundColor3 = Color3.new(1, 1, 1)
Components.Corner(box, UDim.new(0, 16))
Components.Stroke(box, 3)
local boxPadding = Instance.new("UIPadding")
boxPadding.PaddingLeft = UDim.new(0, 14)
boxPadding.PaddingRight = UDim.new(0, 14)
boxPadding.PaddingTop = UDim.new(0, 8)
boxPadding.PaddingBottom = UDim.new(0, 8)
boxPadding.Parent = box
box.Parent = content
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
	Parent = content,
	Size = UDim2.new(0.34, -10, 0, 52),
	Position = UDim2.new(0.66, 5, 0, 151),
	Colors = Theme.Colors.Mint,
	CornerRadius = UDim.new(0, 16),
	MaxTextSize = 24,
	OnClick = setTyped,
})

sectionTitle("Money", 220)
buttonRow(252, {
	{ "+1K", Theme.Colors.Yellow, function() run("AddMoney", 1e3) end },
	{ "+1M", Theme.Colors.Yellow, function() run("AddMoney", 1e6) end },
	{ "+1B", Theme.Colors.Orange, function() run("AddMoney", 1e9) end },
})

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
