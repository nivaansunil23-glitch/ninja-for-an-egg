-- Sprint button and the Jump control, bottom right (next to the jump button on phones).
--
-- Sprint: hold Left Shift on PC, or tap the Sprint button / click L3 on a
-- controller to switch it on and off. Right Shift still toggles shift lock.
-- Jump control (replaced the Jump Boost on/off button): pick any jump power
-- from the starting jump up to your max with - / + (hold to keep going) or by
-- dragging the bar; tap the number to flip between the starting jump and max.
-- Handy to walk around the base or carry an egg without flying sky high.
-- The server clamps and saves it (Player/Loadout, Player/JumpPower).

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local MovementConfig = require(Shared:WaitForChild("Config"):WaitForChild("MovementConfig"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local Bubbly = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Bubbly"))
local Icons = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Icons"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local jumpRemote = Net.Event("SetJumpChoice")

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
	Text = "",
	Parent = screen,
	Size = UDim2.fromOffset(84, 84),
	Colors = Bubbly.Colors.Sky,
	CornerRadius = UDim.new(0.28, 0),
	StrokeThickness = 4,
	LabelSize = UDim2.fromScale(0.62, 0.5),
	LabelPosition = UDim2.fromScale(0.5, 0.38),
	MaxTextSize = 48,
})
Icons.Make("Shoe", sprintButton, {
	Size = UDim2.fromOffset(48, 48),
	Position = UDim2.fromScale(0.5, 0.4),
	AnchorPoint = Vector2.new(0.5, 0.5),
	ZIndex = 3,
})
local sprintLabel = Bubbly.Label({
	Text = "Sprint",
	Parent = sprintButton,
	Size = UDim2.fromScale(0.94, 0.26),
	Position = UDim2.fromScale(0.5, 0.8),
	AnchorPoint = Vector2.new(0.5, 0.5),
	MaxTextSize = 22,
})

-- Jump control: dark pill with - [Jump N over a bar] +
local jumpPill = Bubbly.Box({
	Name = "JumpControl",
	Parent = screen,
	Size = UDim2.fromOffset(250, 58),
	Colors = Bubbly.Colors.Track,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
})
local minusButton = Bubbly.Button({
	Name = "Minus",
	Text = "-",
	Parent = jumpPill,
	Size = UDim2.new(0, 44, 1, -10),
	Position = UDim2.new(0, 5, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Colors = Bubbly.Colors.Red,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
	MaxTextSize = 34,
})
local plusButton = Bubbly.Button({
	Name = "Plus",
	Text = "+",
	Parent = jumpPill,
	Size = UDim2.new(0, 44, 1, -10),
	Position = UDim2.new(1, -5, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	Colors = Bubbly.Colors.Mint,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
	MaxTextSize = 34,
})
local jumpLabel = Bubbly.Label({
	Text = "Jump",
	Parent = jumpPill,
	Size = UDim2.new(1, -112, 0.48, 0),
	Position = UDim2.new(0.5, 0, 0, 5),
	AnchorPoint = Vector2.new(0.5, 0),
	MaxTextSize = 22,
})
local flipButton = Instance.new("TextButton") -- tap the number: starting jump <-> max
flipButton.Name = "Flip"
flipButton.Text = ""
flipButton.BackgroundTransparency = 1
flipButton.Size = jumpLabel.Size
flipButton.Position = jumpLabel.Position
flipButton.AnchorPoint = jumpLabel.AnchorPoint
flipButton.ZIndex = 3
flipButton.Parent = jumpPill
local barTrack = Instance.new("TextButton") -- drag along it to pick a jump
barTrack.Name = "Bar"
barTrack.Text = ""
barTrack.AutoButtonColor = false
barTrack.BackgroundColor3 = Color3.fromRGB(28, 22, 52)
barTrack.Size = UDim2.new(1, -116, 0, 12)
barTrack.Position = UDim2.new(0.5, 0, 1, -10)
barTrack.AnchorPoint = Vector2.new(0.5, 1)
Bubbly.Corner(barTrack, UDim.new(1, 0))
Bubbly.Stroke(barTrack, 2)
barTrack.Parent = jumpPill
local barFill = Bubbly.Box({
	Name = "Fill",
	Parent = barTrack,
	Size = UDim2.fromScale(1, 1),
	Colors = Bubbly.Colors.Yellow,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 0,
})
local barKnob = Bubbly.Box({
	Name = "Knob",
	Parent = barTrack,
	Size = UDim2.fromOffset(18, 18),
	Position = UDim2.fromScale(1, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Colors = Bubbly.Colors.Panel,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 2,
	ZIndex = 2,
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

-- Phones: Sprint sits left of the jump button with the Jump control above it.
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
		jumpPill.AnchorPoint = Vector2.new(1, 1)
		jumpPill.Size = UDim2.fromOffset(210, 50)
		jumpPill.Position = UDim2.fromOffset(jumpPosition.X - 12, sprintTop - 10)
	else
		sprintButton.AnchorPoint = Vector2.new(1, 1)
		sprintButton.Size = UDim2.fromOffset(84, 84)
		sprintButton.Position = UDim2.new(1, -20, 1, -20)
		jumpPill.AnchorPoint = Vector2.new(1, 0.5)
		jumpPill.Size = UDim2.fromOffset(250, 58)
		jumpPill.Position = UDim2.new(1, -116, 1, -62)
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

-- Jump control ----------------------------------------------------------------------

local BASE = JumpBalance.BaseJump
local SEND_DELAY = 0.2
local REPEAT_START, REPEAT_EVERY = 0.35, 0.06

local pending = nil -- a picked jump the server hasn't confirmed yet
local sendToken = 0
local dragging = false

local function maxJump(): number
	return math.max(BASE, player:GetAttribute("MaxJump") or player:GetAttribute("JumpPower") or BASE)
end

local function shownJump(): number
	local max = maxJump()
	if pending then
		return math.min(pending, max)
	end
	local choice = player:GetAttribute("JumpChoice")
	if type(choice) ~= "number" or choice <= 0 or choice >= max then
		return max
	end
	return math.clamp(choice, BASE, max)
end

local function refreshJump()
	local max = maxJump()
	local value = shownJump()
	local atMax = value >= max
	jumpLabel.Text = if atMax then `Jump {value} MAX` else `Jump {value}/{max}`
	local fraction = math.clamp(if max > BASE then (value - BASE) / (max - BASE) else 1, 0, 1)
	barFill.Size = UDim2.fromScale(fraction, 1)
	barKnob.Position = UDim2.fromScale(fraction, 0.5)
	Bubbly.SetColors(barFill, if atMax then Bubbly.Colors.Mint else Bubbly.Colors.Yellow)
end

-- Shows the pick right away and sends it once the player stops changing it.
local function pick(value: number)
	local max = maxJump()
	pending = math.clamp(math.floor(value + 0.5), BASE, max)
	refreshJump()
	sendToken += 1
	local token = sendToken
	task.delay(SEND_DELAY, function()
		if token ~= sendToken or dragging or not pending then
			return
		end
		jumpRemote:FireServer(if pending >= max then 0 else pending)
		task.delay(1, function()
			if token == sendToken then
				pending = nil
				refreshJump()
			end
		end)
	end)
end

local function step(): number
	return math.max(1, math.floor((maxJump() - BASE) / 20 + 0.5))
end

-- Tap to move one step, hold to keep going.
local function holdToStep(button: GuiButton, direction: number)
	local holding = 0
	button.MouseButton1Down:Connect(function()
		holding += 1
		local id = holding
		pick(shownJump() + direction * step())
		task.wait(REPEAT_START)
		while holding == id do
			pick(shownJump() + direction * step())
			task.wait(REPEAT_EVERY)
		end
	end)
	local function stop()
		holding += 1
	end
	button.MouseButton1Up:Connect(stop)
	button.MouseLeave:Connect(stop)
end
holdToStep(minusButton, -1)
holdToStep(plusButton, 1)

flipButton.Activated:Connect(function()
	pick(if shownJump() >= maxJump() then BASE else maxJump())
	Bubbly.Pop(jumpPill, 1.06)
end)

local function dragTo(x: number)
	local width = math.max(1, barTrack.AbsoluteSize.X)
	local fraction = math.clamp((x - barTrack.AbsolutePosition.X) / width, 0, 1)
	pick(BASE + fraction * (maxJump() - BASE))
end
barTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragTo(input.Position.X)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		dragTo(input.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		dragging = false
		pick(shownJump()) -- send where the drag stopped
	end
end)

for _, name in { "MaxJump", "JumpPower", "JumpChoice" } do
	player:GetAttributeChangedSignal(name):Connect(refreshJump)
end
refreshJump()

task.spawn(function()
	while true do
		layout()
		task.wait(LAYOUT_SECONDS)
	end
end)
