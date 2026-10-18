-- Drop Egg button: shows while you carry an egg and puts it down on the ground
-- under you (server: Player/DropEgg). PC: above Jump Boost in the bottom right,
-- or press G. Phones: on the right side above the jump controls.

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

local button = Bubbly.Button({
	Name = "DropEgg",
	Text = "🥚 Drop Egg",
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

local function refresh()
	button.Visible = player:GetAttribute("CarryingEgg") ~= nil
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
end, false, Enum.KeyCode.G)

player:GetAttributeChangedSignal("CarryingEgg"):Connect(refresh)
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "TouchGui" then
		task.defer(refresh)
	end
end)
refresh()
