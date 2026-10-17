-- Bubbly loading screen. Lives in ReplicatedFirst so it shows before anything
-- else, which also means it can't use the shared UI modules (they may not have
-- arrived yet), so the styling is written out here.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MIN_SECONDS = 2.5
local MAX_SECONDS = 25 -- never trap anyone on the loading screen
local SKIP_AFTER = 8

local FONT = Enum.Font.FredokaOne
local OUTLINE = Color3.fromRGB(45, 25, 70)

local TIPS = {
	"Bounce on the trampoline to train your jump!",
	"Click while you bounce to train even faster!",
	"Every island you reach unlocks a better trampoline.",
	"Hold Shift (or tap Sprint) to run faster!",
	"The big launch trampoline throws you 3x higher!",
	"Better vertices make every jump higher.",
	"Careful! Falling while holding an egg cracks it.",
	"Heavier pets sell for more money.",
	"Equip your best pets to earn money every second.",
	"Higher islands have rarer eggs.",
}

local player = Players.LocalPlayer
local started = os.clock()

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local function outline(object: GuiObject, thickness: number, border: boolean?)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = OUTLINE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	if border then
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	stroke.Parent = object
	return stroke
end

local function gradient(object: GuiObject, top: Color3, bottom: Color3, rotation: number?)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = rotation or 90
	g.Parent = object
	return g
end

local function corner(object: GuiObject, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = object
end

local function label(text: string, size: UDim2, position: UDim2, maxSize: number, parent: Instance)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = text
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextScaled = true
	l.Size = size
	l.Position = position
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = l
	outline(l, 3)
	l.Parent = parent
	return l
end

-- Background: candy sky gradient that slowly shifts.
local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.new(1, 1, 1)
background.Parent = gui
local backgroundGradient = gradient(background, Color3.fromRGB(255, 170, 220), Color3.fromRGB(130, 210, 255), 45)

-- Floating bubbles drifting up behind everything.
local bubbles = {}
for i = 1, 14 do
	local bubble = Instance.new("Frame")
	local size = math.random(30, 90)
	bubble.Size = UDim2.fromOffset(size, size)
	bubble.Position = UDim2.fromScale(math.random(), math.random())
	bubble.AnchorPoint = Vector2.new(0.5, 0.5)
	bubble.BackgroundColor3 = Color3.new(1, 1, 1)
	bubble.BackgroundTransparency = 0.65
	corner(bubble, UDim.new(1, 0))
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = bubble
	bubble.Parent = background
	bubbles[i] = { Frame = bubble, Speed = math.random(4, 10) / 100 }
end

-- Wobbling egg (placeholder art).
local egg = label("🥚", UDim2.fromScale(0.2, 0.25), UDim2.fromScale(0.5, 0.36), 200, background)
egg:FindFirstChildOfClass("UIStroke"):Destroy()
local eggRatio = Instance.new("UIAspectRatioConstraint")
eggRatio.Parent = egg

local title = label("NINJA FOR AN EGG", UDim2.fromScale(0.8, 0.12), UDim2.fromScale(0.5, 0.58), 90, background)
title:FindFirstChildOfClass("UIStroke").Thickness = 5
gradient(title, Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 150, 210))

-- Progress bar pill.
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0.45, 0.045)
bar.Position = UDim2.fromScale(0.5, 0.7)
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.BackgroundColor3 = Color3.new(1, 1, 1)
corner(bar, UDim.new(1, 0))
outline(bar, 4, true)
gradient(bar, Color3.fromRGB(240, 230, 255), Color3.fromRGB(200, 185, 235))
bar.Parent = background
local barSize = Instance.new("UISizeConstraint")
barSize.MinSize = Vector2.new(260, 28)
barSize.Parent = bar

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
corner(fill, UDim.new(1, 0))
gradient(fill, Color3.fromRGB(130, 245, 190), Color3.fromRGB(35, 200, 135))
fill.Parent = bar

local status = label("Loading", UDim2.fromScale(0.4, 0.05), UDim2.fromScale(0.5, 0.77), 34, background)
local tip = label(TIPS[math.random(#TIPS)], UDim2.fromScale(0.7, 0.045), UDim2.fromScale(0.5, 0.9), 28, background)

local skip = Instance.new("TextButton")
skip.Text = "Skip"
skip.Font = FONT
skip.TextScaled = true
skip.TextColor3 = Color3.new(1, 1, 1)
skip.Size = UDim2.fromOffset(120, 48)
skip.Position = UDim2.new(1, -24, 1, -24)
skip.AnchorPoint = Vector2.new(1, 1)
skip.BackgroundColor3 = Color3.new(1, 1, 1)
skip.AutoButtonColor = false
skip.Visible = false
corner(skip, UDim.new(0, 16))
outline(skip, 3, true)
gradient(skip, Color3.fromRGB(255, 150, 210), Color3.fromRGB(240, 80, 165))
local skipPadding = Instance.new("UIPadding")
skipPadding.PaddingTop = UDim.new(0, 8)
skipPadding.PaddingBottom = UDim.new(0, 8)
skipPadding.Parent = skip
skip.Parent = background

local skipped = false
skip.Activated:Connect(function()
	skipped = true
end)

-- Animate everything while we wait.
local shownProgress = 0
local animation = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock() - started
	egg.Rotation = math.sin(t * 6) * 12
	egg.Position = UDim2.fromScale(0.5, 0.36 + math.sin(t * 3) * 0.015)
	title.Rotation = math.sin(t * 2) * 2
	backgroundGradient.Rotation = 45 + math.sin(t * 0.5) * 20
	status.Text = "Loading" .. string.rep(".", math.floor(t * 2) % 4)
	for _, bubble in bubbles do
		local position = bubble.Frame.Position
		local y = position.Y.Scale - bubble.Speed * dt
		if y < -0.1 then
			y = 1.1
		end
		bubble.Frame.Position = UDim2.fromScale(position.X.Scale + math.sin(t + y * 6) * 0.0005, y)
	end
	fill.Size = UDim2.fromScale(shownProgress, 1)
end)

local function setProgress(progress: number)
	shownProgress = math.max(shownProgress, math.clamp(progress, 0, 1))
end

local function timedOut(): boolean
	local elapsed = os.clock() - started
	if elapsed > SKIP_AFTER then
		skip.Visible = true
	end
	return skipped or elapsed > MAX_SECONDS
end

-- 1. Wait for the game to arrive.
while not game:IsLoaded() and not timedOut() do
	setProgress(0.3 * math.min(1, (os.clock() - started) / 5))
	task.wait()
end
setProgress(0.35)

-- 2. Let queued assets finish (roughly).
local startQueue = math.max(1, ContentProvider.RequestQueueSize)
while ContentProvider.RequestQueueSize > 0 and not timedOut() do
	setProgress(0.35 + 0.4 * (1 - ContentProvider.RequestQueueSize / startQueue))
	task.wait()
end
setProgress(0.75)

-- 3. Wait for this player's save to load (the server sets "Money" when it does).
while player:GetAttribute("Money") == nil and not timedOut() do
	task.wait()
end
setProgress(0.9)

while os.clock() - started < MIN_SECONDS and not skipped do
	task.wait()
end
setProgress(1)
status.Text = "Let's go!"
task.wait(0.3)

-- Slide away and clean up.
animation:Disconnect()
local out = TweenService:Create(
	background,
	TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
	{ Position = UDim2.fromScale(0, -1.1) }
)
out:Play()
out.Completed:Wait()
gui:Destroy()
