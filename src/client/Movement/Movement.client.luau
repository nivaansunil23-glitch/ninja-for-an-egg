-- Sprint and Jump Boost buttons, bottom right (next to the jump button on phones).
--
-- Sprint: hold Left Shift on PC, or tap the Sprint button / click L3 on a
-- controller to switch it on and off. Right Shift still toggles shift lock.
-- Jump Boost (like Jump to Steal): switch your trained jump off for a normal
-- jump, e.g. to walk around the base or carry an egg without flying sky high.
-- The server applies it (Player/JumpPower).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local MovementConfig = require(Shared:WaitForChild("Config"):WaitForChild("MovementConfig"))
local Bubbly = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Bubbly"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local boostRemote = Net.Event("SetJumpBoost")

local WALK_SPEED = StarterPlayer.CharacterWalkSpeed
local LAYOUT_SECONDS = 0.5

local toggled = false -- Sprint button / L3
local held = false -- Left Shift
local fovTarget = nil

local function sprinting(): boolean
	return toggled or held
end

-- UI ------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "MovementUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Full-screen frame used to line the buttons up with the touch jump button.
local screen = Instance.new("Frame")
screen.Name = "Screen"
screen.BackgroundTransparency = 1
screen.Size = UDim2.fromScale(1, 1)
screen.Parent = gui

local sprintButton = Bubbly.Button({
	Name = "Sprint",
	Text = "🏃",
	Parent = screen,
	Size = UDim2.fromOffset(84, 84),
	Colors = Bubbly.Colors.Sky,
	CornerRadius = UDim.new(0.28, 0),
	StrokeThickness = 4,
	LabelSize = UDim2.fromScale(0.62, 0.5),
	LabelPosition = UDim2.fromScale(0.5, 0.38),
	MaxTextSize = 48,
})
local sprintLabel = Bubbly.Label({
	Text = "Sprint",
	Parent = sprintButton,
	Size = UDim2.fromScale(0.94, 0.26),
	Position = UDim2.fromScale(0.5, 0.8),
	AnchorPoint = Vector2.new(0.5, 0.5),
	MaxTextSize = 22,
})

local boostButton, boostLabel = Bubbly.Button({
	Name = "JumpBoost",
	Text = "Jump Boost: ON",
	Parent = screen,
	Size = UDim2.fromOffset(190, 46),
	Colors = Bubbly.Colors.Mint,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
	MaxTextSize = 24,
})

local function findJumpButton(): GuiObject?
	local touchGui = playerGui:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	if touchGui and touchGui:IsA("ScreenGui") and touchGui.Enabled and jump and jump:IsA("GuiObject") and jump.Visible then
		return jump
	end
	return nil
end

-- Phones: Sprint sits left of the jump button with Jump Boost above it.
-- PC: both in the bottom right corner.
local function layout()
	local jump = findJumpButton()
	if jump then
		local origin = screen.AbsolutePosition
		local jumpPosition = jump.AbsolutePosition - origin
		local jumpSize = jump.AbsoluteSize
		local size = math.max(56, math.floor(jumpSize.X * 0.8))
		local sprintTop = jumpPosition.Y + jumpSize.Y - size
		sprintButton.AnchorPoint = Vector2.zero
		sprintButton.Size = UDim2.fromOffset(size, size)
		sprintButton.Position = UDim2.fromOffset(jumpPosition.X - size - 12, sprintTop)
		boostButton.AnchorPoint = Vector2.new(1, 1)
		boostButton.Size = UDim2.fromOffset(160, 40)
		boostButton.Position = UDim2.fromOffset(jumpPosition.X - 12, sprintTop - 10)
	else
		sprintButton.AnchorPoint = Vector2.new(1, 1)
		sprintButton.Size = UDim2.fromOffset(84, 84)
		sprintButton.Position = UDim2.new(1, -20, 1, -20)
		boostButton.AnchorPoint = Vector2.new(1, 0.5)
		boostButton.Size = UDim2.fromOffset(190, 46)
		boostButton.Position = UDim2.new(1, -116, 1, -62)
	end
end

-- Sprint --------------------------------------------------------------------------

local function applySpeed()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if sprinting() then MovementConfig.SprintSpeed else WALK_SPEED
	end
	Bubbly.SetColors(sprintButton, if sprinting() then Bubbly.Colors.Yellow else Bubbly.Colors.Sky)
	sprintLabel.Text = if sprinting() then "Sprinting" else "Sprint"
end

sprintButton.Activated:Connect(function()
	toggled = not toggled
	applySpeed()
	Bubbly.Pop(sprintButton, 1.12)
end)

-- Left Shift beats shift lock (which is still on Right Shift).
ContextActionService:BindActionAtPriority("SprintHold", function(_, state)
	if state == Enum.UserInputState.Begin then
		held = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		held = false
	end
	applySpeed()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftShift)

ContextActionService:BindAction("SprintToggle", function(_, state)
	if state == Enum.UserInputState.Begin then
		toggled = not toggled
		applySpeed()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonL3)

player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid", 10)
	applySpeed()
end)
applySpeed()

-- The camera widens a little while you're actually running with sprint on.
RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not camera or not humanoid then
		return
	end
	local running = sprinting() and humanoid.MoveDirection.Magnitude > 0.1
	local wanted = if running then MovementConfig.SprintFov else 70
	if wanted ~= fovTarget then
		fovTarget = wanted
		TweenService:Create(camera, TweenInfo.new(MovementConfig.FovTweenSeconds), { FieldOfView = wanted }):Play()
	end
end)

-- Jump Boost ------------------------------------------------------------------------

local function boostOn(): boolean
	return player:GetAttribute("JumpBoost") ~= false
end

local function refreshBoost()
	local trained = player:GetAttribute("TrainedJump")
	if boostOn() then
		boostLabel.Text = "Jump Boost: ON"
		Bubbly.SetColors(boostButton, Bubbly.Colors.Mint)
	else
		boostLabel.Text = if trained then `Jump Boost: OFF ({trained})` else "Jump Boost: OFF"
		Bubbly.SetColors(boostButton, Bubbly.Colors.Red)
	end
end

boostButton.Activated:Connect(function()
	boostRemote:FireServer(not boostOn())
	Bubbly.Pop(boostButton, 1.1)
end)
player:GetAttributeChangedSignal("JumpBoost"):Connect(refreshBoost)
player:GetAttributeChangedSignal("TrainedJump"):Connect(refreshBoost)
refreshBoost()

task.spawn(function()
	while true do
		layout()
		task.wait(LAYOUT_SECONDS)
	end
end)
