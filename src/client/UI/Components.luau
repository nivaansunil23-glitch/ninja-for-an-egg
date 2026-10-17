-- Small UI building blocks shared by the HUD and the popup windows.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent:WaitForChild("Theme"))

local Components = {}

local BOUNCE = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_IN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function Components.Corner(parent: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 14)
	corner.Parent = parent
	return corner
end

function Components.Stroke(parent: GuiObject, thickness: number?, color: Color3?)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 3
	stroke.Color = color or Theme.Outline
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

function Components.Gradient(parent: GuiObject, colors)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colors[1], colors[2])
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

function Components.SetColors(object: GuiObject, colors)
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(colors[1], colors[2])
	end
end

-- A rounded box with outline and gradient.
function Components.Box(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Box"
	frame.Size = props.Size or UDim2.fromScale(1, 1)
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.LayoutOrder = props.LayoutOrder or 0
	frame.ZIndex = props.ZIndex or 1
	Components.Corner(frame, props.CornerRadius)
	Components.Stroke(frame, props.StrokeThickness)
	Components.Gradient(frame, props.Colors or Theme.Colors.Row)
	frame.Parent = props.Parent
	return frame
end

-- White cartoon text with a dark outline. Scales to fit its box.
function Components.Label(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.BackgroundTransparency = 1
	label.Font = Theme.Font
	label.Text = props.Text or ""
	label.TextColor3 = props.Color or Theme.Text
	label.TextScaled = true
	label.TextWrapped = props.Wrapped == true
	label.RichText = props.RichText == true
	label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Center
	label.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
	label.Size = props.Size or UDim2.fromScale(1, 1)
	label.Position = props.Position or UDim2.new()
	label.AnchorPoint = props.AnchorPoint or Vector2.zero
	label.LayoutOrder = props.LayoutOrder or 0
	label.ZIndex = props.ZIndex or 1

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = props.StrokeThickness or 2
	stroke.Color = Theme.Outline
	stroke.Parent = label

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = props.MaxTextSize or 40
	limit.Parent = label

	label.Parent = props.Parent
	return label
end

-- Bubbly button that grows on hover and squishes on press.
-- Returns the button and its text label.
function Components.Button(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.Size = props.Size or UDim2.fromOffset(160, 50)
	button.Position = props.Position or UDim2.new()
	button.AnchorPoint = props.AnchorPoint or Vector2.zero
	button.LayoutOrder = props.LayoutOrder or 0
	button.ZIndex = props.ZIndex or 1
	Components.Corner(button, props.CornerRadius)
	Components.Stroke(button, props.StrokeThickness or 3)
	Components.Gradient(button, props.Colors or Theme.Colors.Pink)

	local scale = Instance.new("UIScale")
	scale.Parent = button

	local label = Components.Label({
		Name = "Text",
		Text = props.Text,
		Parent = button,
		Size = props.LabelSize or UDim2.fromScale(0.86, 0.7),
		Position = props.LabelPosition or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = props.MaxTextSize or 32,
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

-- Glossy highlight across the top of a box or button.
function Components.Shine(parent: GuiObject, strength: number?)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 1 - (strength or 0.45)
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromScale(0.86, 0.36)
	shine.Position = UDim2.fromScale(0.07, 0.07)
	shine.ZIndex = parent.ZIndex
	Components.Corner(shine, UDim.new(1, 0))
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new(0, 1)
	fade.Parent = shine
	shine.Parent = parent
	return shine
end

-- Small rounded tag like "EPIC" or "NEXT!".
function Components.Tag(props)
	local tag = Components.Box({
		Name = props.Name or "Tag",
		Parent = props.Parent,
		Size = props.Size or UDim2.fromOffset(80, 26),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Colors = props.Colors,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = props.StrokeThickness or 2.5,
		ZIndex = props.ZIndex,
	})
	tag.Rotation = props.Rotation or 0
	local label = Components.Label({
		Name = "Text",
		Text = props.Text,
		Parent = tag,
		Size = UDim2.fromScale(0.84, 0.72),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = props.MaxTextSize or 18,
		ZIndex = props.ZIndex,
	})
	return tag, label
end

-- A few sparkles that fly out from a point on the screen and fade away.
function Components.Burst(gui: LayerCollector, at: Vector2, icons: { string }?)
	icons = icons or { "✨", "⭐", "💫" }
	for i = 1, 7 do
		local angle = (i / 7) * math.pi * 2 + math.random() * 0.6
		local distance = math.random(60, 110)
		local spark = Components.Label({
			Text = icons[math.random(#icons)],
			Parent = gui,
			Size = UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(at.X, at.Y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			MaxTextSize = 30,
			StrokeThickness = 0,
			ZIndex = 60,
		})
		local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(spark, info, {
			Position = UDim2.fromOffset(at.X + math.cos(angle) * distance, at.Y + math.sin(angle) * distance),
			TextTransparency = 1,
			Rotation = math.random(-90, 90),
		}):Play()
		task.delay(0.65, function()
			spark:Destroy()
		end)
	end
end

-- Center of a GuiObject in its ScreenGui's space (for Burst).
function Components.CenterOf(object: GuiObject): Vector2
	return object.AbsolutePosition + object.AbsoluteSize / 2
end

-- Quick squash-and-stretch on any GuiObject that has (or gets) a UIScale.
function Components.Pop(object: GuiObject, amount: number?)
	local scale = object:FindFirstChild("PopScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "PopScale"
		scale.Parent = object
	end
	scale.Scale = amount or 1.15
	TweenService:Create(scale, POP_IN, { Scale = 1 }):Play()
end

-- Vertical scrolling list sized in pixels.
function Components.ScrollList(props)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = props.Name or "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = props.Size or UDim2.fromScale(1, 1)
	scroll.Position = props.Position or UDim2.new()
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = Theme.Outline
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y

	if props.Grid then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = props.CellSize or UDim2.fromOffset(120, 140)
		grid.CellPadding = UDim2.fromOffset(10, 10)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		grid.Parent = scroll
	else
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Parent = scroll
	end

	-- Room for row outlines so they don't get clipped.
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = scroll

	scroll.Parent = props.Parent
	return scroll
end

function Components.ClearList(scroll: Instance)
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Popup window with a title ribbon and close button. Sized in pixels and
-- scaled to fit the screen, so it looks the same on PC and phones.
function Components.Window(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Window"
	frame.Size = props.Size or UDim2.fromOffset(720, 470)
	frame.Position = UDim2.fromScale(0.5, 0.53)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Visible = false
	frame.ZIndex = 10
	Components.Corner(frame, UDim.new(0, 28))
	Components.Stroke(frame, 5)
	Components.Gradient(frame, Theme.Colors.Panel)

	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local function fitScale(): number
		local camera = Workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		return math.min(1.2, viewport.X * 0.94 / frame.Size.X.Offset, viewport.Y * 0.8 / frame.Size.Y.Offset)
	end

	local ribbon = Components.Box({
		Name = "Title",
		Parent = frame,
		Size = UDim2.fromOffset(300, 60),
		Position = UDim2.new(0.5, 0, 0, -26),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = props.Colors or Theme.Colors.Pink,
		CornerRadius = UDim.new(0, 20),
		StrokeThickness = 4,
	})
	local title = Components.Label({
		Text = props.Title,
		Parent = ribbon,
		Size = UDim2.fromScale(0.85, 0.72),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 38,
		StrokeThickness = 3,
	})

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(20, 50)
	content.Size = UDim2.new(1, -40, 1, -66)
	content.Parent = frame

	local window = {
		Frame = frame,
		Content = content,
		Title = title,
		Ribbon = ribbon,
	}

	function window.SetTitle(text: string, colors)
		title.Text = text
		if colors then
			Components.SetColors(ribbon, colors)
		end
	end

	function window.Open()
		local target = fitScale()
		scale.Scale = target * 0.6
		frame.Visible = true
		TweenService:Create(scale, POP_IN, { Scale = target }):Play()
	end

	function window.Close()
		frame.Visible = false
		if props.OnClose then
			props.OnClose()
		end
	end

	function window.IsOpen(): boolean
		return frame.Visible
	end

	Components.Button({
		Name = "Close",
		Text = "X",
		Parent = frame,
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.new(1, 16, 0, -16),
		AnchorPoint = Vector2.new(1, 0),
		Colors = Theme.Colors.Red,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 4,
		MaxTextSize = 36,
		OnClick = window.Close,
	})

	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if frame.Visible then
				scale.Scale = fitScale()
			end
		end)
	end

	frame.Parent = props.Parent
	return window
end

-- Pop-up message near the top of the screen ("Not enough money", "Bought!").
function Components.Notify(gui: ScreenGui, text: string, color: Color3?)
	local holder = gui:FindFirstChild("Notifications")
	if not holder then
		holder = Instance.new("Frame")
		holder.Name = "Notifications"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(0.5, 0.3)
		holder.Position = UDim2.fromScale(0.5, 0.14)
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.ZIndex = 20
		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
		layout.Parent = holder
		holder.Parent = gui
	end

	local label = Components.Label({
		Text = text,
		Parent = holder,
		Size = UDim2.new(1, 0, 0.2, 0),
		Color = color,
		MaxTextSize = 34,
		StrokeThickness = 3,
		LayoutOrder = math.floor(os.clock() * 100),
	})
	Components.Pop(label, 0.3)

	task.delay(2.2, function()
		local fadeInfo = TweenInfo.new(0.4)
		TweenService:Create(label, fadeInfo, { TextTransparency = 1 }):Play()
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
		end
		task.wait(0.4)
		label:Destroy()
	end)
end

return Components
