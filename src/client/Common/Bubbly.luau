-- Bubble Gum Sim style helpers for the jump training, trampoline upgrade and
-- movement UI: chunky font, thick dark outlines, bright gradients. Same look as
-- UI/Theme and UI/Components, kept separate so these screens don't depend on
-- the shop UI files.

local TweenService = game:GetService("TweenService")

local FitText = require(script.Parent:WaitForChild("FitText"))

local Bubbly = {}

Bubbly.Font = Enum.Font.FredokaOne
Bubbly.Outline = Color3.fromRGB(45, 25, 70)
Bubbly.Text = Color3.fromRGB(255, 255, 255)

-- { top, bottom } gradient pairs
Bubbly.Colors = {
	Pink = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(240, 80, 165) },
	Mint = { Color3.fromRGB(130, 245, 190), Color3.fromRGB(35, 200, 135) },
	Sky = { Color3.fromRGB(130, 210, 255), Color3.fromRGB(50, 140, 245) },
	Yellow = { Color3.fromRGB(255, 230, 105), Color3.fromRGB(255, 170, 35) },
	Purple = { Color3.fromRGB(205, 155, 255), Color3.fromRGB(140, 80, 235) },
	Red = { Color3.fromRGB(255, 135, 135), Color3.fromRGB(230, 65, 90) },
	Gray = { Color3.fromRGB(205, 205, 215), Color3.fromRGB(140, 140, 160) },
	Panel = { Color3.fromRGB(255, 250, 253), Color3.fromRGB(236, 225, 255) },
	Track = { Color3.fromRGB(70, 55, 110), Color3.fromRGB(45, 35, 80) },
}

local BOUNCE = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Gradient pair for a single colour (lighter top, the colour at the bottom).
function Bubbly.FromColor(color: Color3)
	return { color:Lerp(Color3.new(1, 1, 1), 0.35), color }
end

function Bubbly.Corner(parent: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 14)
	corner.Parent = parent
	return corner
end

function Bubbly.Stroke(parent: GuiObject, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 3
	stroke.Color = Bubbly.Outline
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

-- Gradient with a darker band along the bottom, so buttons look chunky (same
-- as Theme.LipSequence).
local function lipSequence(colors): ColorSequence
	local lip = colors[2]:Lerp(Color3.new(0, 0, 0), 0.22)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, colors[1]),
		ColorSequenceKeypoint.new(0.74, colors[2]),
		ColorSequenceKeypoint.new(0.78, lip),
		ColorSequenceKeypoint.new(1, lip),
	})
end

function Bubbly.Gradient(parent: GuiObject, colors, lip: boolean?)
	local gradient = Instance.new("UIGradient")
	gradient.Color = if lip then lipSequence(colors) else ColorSequence.new(colors[1], colors[2])
	gradient.Rotation = 90
	gradient:SetAttribute("Lip", lip == true)
	gradient.Parent = parent
	return gradient
end

function Bubbly.SetColors(object: GuiObject, colors)
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = if gradient:GetAttribute("Lip")
			then lipSequence(colors)
			else ColorSequence.new(colors[1], colors[2])
	end
end

-- Glossy highlight across the top of a box or button.
function Bubbly.Shine(parent: GuiObject, strength: number?)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 1 - (strength or 0.35)
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromScale(0.86, 0.34)
	shine.Position = UDim2.fromScale(0.07, 0.07)
	shine.ZIndex = parent.ZIndex
	Bubbly.Corner(shine, UDim.new(1, 0))
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new(0, 1)
	fade.Parent = shine
	shine.Parent = parent
	return shine
end

-- Rounded box with an outline and a gradient.
function Bubbly.Box(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Box"
	frame.Size = props.Size or UDim2.fromScale(1, 1)
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.ZIndex = props.ZIndex or 1
	Bubbly.Corner(frame, props.CornerRadius)
	if (props.StrokeThickness or 3) > 0 then
		Bubbly.Stroke(frame, props.StrokeThickness)
	end
	Bubbly.Gradient(frame, props.Colors or Bubbly.Colors.Panel)
	frame.Parent = props.Parent
	return frame
end

-- White cartoon text with a dark outline that scales to fit its box.
function Bubbly.Label(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.BackgroundTransparency = 1
	label.Font = Bubbly.Font
	label.Text = props.Text or ""
	label.TextColor3 = props.Color or Bubbly.Text
	label.TextScaled = true
	label.TextWrapped = props.Wrapped == true
	label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Center
	label.Size = props.Size or UDim2.fromScale(1, 1)
	label.Position = props.Position or UDim2.new()
	label.AnchorPoint = props.AnchorPoint or Vector2.zero
	label.ZIndex = props.ZIndex or 1

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = props.StrokeThickness or 2
	stroke.Color = Bubbly.Outline
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = props.MaxTextSize or 40
	limit.Parent = label

	label.Parent = props.Parent
	FitText.Attach(label)
	return label
end

-- Bubbly button that grows on hover and squishes when pressed.
-- Returns the button and its text label.
function Bubbly.Button(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.Size = props.Size or UDim2.fromOffset(160, 50)
	button.Position = props.Position or UDim2.new()
	button.AnchorPoint = props.AnchorPoint or Vector2.zero
	button.ZIndex = props.ZIndex or 1
	Bubbly.Corner(button, props.CornerRadius)
	Bubbly.Stroke(button, props.StrokeThickness or 3)
	Bubbly.Gradient(button, props.Colors or Bubbly.Colors.Pink, true)
	Bubbly.Shine(button)

	local scale = Instance.new("UIScale")
	scale.Parent = button

	local label = Bubbly.Label({
		Name = "Text",
		Text = props.Text,
		Parent = button,
		Size = props.LabelSize or UDim2.fromScale(0.86, 0.62),
		Position = props.LabelPosition or UDim2.fromScale(0.5, 0.44),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = props.MaxTextSize or 32,
		StrokeThickness = props.TextStroke or 2.5,
		ZIndex = button.ZIndex,
	})

	local function bounceTo(target: number)
		TweenService:Create(scale, BOUNCE, { Scale = target }):Play()
	end
	button.MouseEnter:Connect(function()
		bounceTo(1.06)
	end)
	button.MouseLeave:Connect(function()
		bounceTo(1)
	end)
	button.MouseButton1Down:Connect(function()
		bounceTo(0.9)
	end)
	button.MouseButton1Up:Connect(function()
		bounceTo(1)
	end)
	if props.OnClick then
		button.Activated:Connect(props.OnClick)
	end

	button.Parent = props.Parent
	return button, label
end

-- Quick squash-and-stretch on any GuiObject.
function Bubbly.Pop(object: GuiObject, amount: number?)
	local scale = object:FindFirstChild("PopScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "PopScale"
		scale.Parent = object
	end
	scale.Scale = amount or 1.15
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
end

-- Floats a label upward while fading it out, then removes it.
function Bubbly.FloatAway(label: TextLabel, rise: UDim2, seconds: number)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, { Position = label.Position + rise, TextTransparency = 1 }):Play()
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
	task.delay(seconds, function()
		label:Destroy()
	end)
end

return Bubbly
