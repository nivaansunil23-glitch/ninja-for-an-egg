-- Drop Egg button: shows while you carry an egg and puts it down on the ground
-- under you (server: Player/DropEgg). Inside your own pen it turns into a green
-- "Place Egg" button that sets the egg in the pen to grow. PC: press F (or G),
-- no button (user, 2026-10-19). Phones: a button on the right above the jump controls.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Bubbly = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Bubbly"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dropRemote = Net.Event("DropEgg")

local gui = Instance.new("ScreenGui")
gui.Name = "DropEggUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local button, buttonLabel = Bubbly.Button({
	Name = "DropEgg",
	Text = "Drop Egg",
	Parent = gui,
	Size = UDim2.fromOffset(190, 46),
	Colors = Bubbly.Colors.Red,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
	MaxTextSize = 24,
})

local function touchControlsOn(): boolean
	local touchGui = playerGui:FindFirstChild("TouchGui")
	return touchGui ~= nil and touchGui:IsA("ScreenGui") and touchGui.Enabled
end

local function layout()
	if touchControlsOn() then
		button.AnchorPoint = Vector2.new(1, 1)
		button.Size = UDim2.fromOffset(160, 40)
		button.Position = UDim2.new(1, -20, 1, -230)
	else
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Size = UDim2.fromOffset(190, 46)
		button.Position = UDim2.new(1, -116, 1, -118)
	end
end

local inPen = nil
local function refresh()
	-- keyboards use F, so the button only shows on touch screens
	button.Visible = player:GetAttribute("CarryingEgg") ~= nil and touchControlsOn()
	local nowInPen = player:GetAttribute("InOwnPen") == true
	if nowInPen ~= inPen then
		inPen = nowInPen
		buttonLabel.Text = if inPen then "Place Egg" else "Drop Egg"
		Bubbly.SetColors(button, if inPen then Bubbly.Colors.Mint else Bubbly.Colors.Red)
	end
	layout()
end

local function drop()
	if player:GetAttribute("CarryingEgg") ~= nil then
		dropRemote:FireServer()
	end
end

button.Activated:Connect(drop)
ContextActionService:BindAction("DropEgg", function(_, state)
	if state == Enum.UserInputState.Begin then
		drop()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F, Enum.KeyCode.G)

player:GetAttributeChangedSignal("CarryingEgg"):Connect(refresh)
player:GetAttributeChangedSignal("InOwnPen"):Connect(refresh)
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "TouchGui" then
		task.defer(refresh)
	end
end)
refresh()
