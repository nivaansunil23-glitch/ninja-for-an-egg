-- Small UI building blocks shared by the HUD and the popup windows.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent:WaitForChild("Theme"))
local FitText = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("FitText"))

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

-- lip = true adds a darker band along the bottom (see Theme.LipSequence).
function Components.Gradient(parent: GuiObject, colors, lip: boolean?)
	local gradient = Instance.new("UIGradient")
	gradient.Color = if lip then Theme.LipSequence(colors) else ColorSequence.new(colors[1], colors[2])
	gradient.Rotation = 90
	gradient:SetAttribute("Lip", lip == true)
	gradient.Parent = parent
	return gradient
end

function Components.SetColors(object: GuiObject, colors)
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = if gradient:GetAttribute("Lip")
			then Theme.LipSequence(colors)
			else ColorSequence.new(colors[1], colors[2])
	end
end

-- Soft shadow just under a GuiObject. It has to be a sibling (children always
-- draw on top of their parent), so it follows the object's size, position,
-- visibility and parent.
function Components.Shadow(object: GuiObject, offset: number?)
	local shadow = Instance.new("Frame")
	shadow.Name = object.Name .. "Shadow"
	shadow.BackgroundColor3 = Theme.Shadow
	shadow.BackgroundTransparency = 0.55
	shadow.BorderSizePixel = 0
	shadow.ZIndex = math.max(object.ZIndex - 1, 0)
	local corner = object:FindFirstChildOfClass("UICorner")
	if corner then
		Components.Corner(shadow, corner.CornerRadius)
	end
	local drop = offset or 6
	local function sync()
		shadow.Size = object.Size
		shadow.AnchorPoint = object.AnchorPoint
		shadow.Position = object.Position + UDim2.fromOffset(0, drop)
		shadow.Visible = object.Visible
		shadow.Rotation = object.Rotation
	end
	for _, property in { "Size", "Position", "AnchorPoint", "Visible", "Rotation" } do
		object:GetPropertyChangedSignal(property):Connect(sync)
	end
	object.AncestryChanged:Connect(function()
		if object.Parent then
			shadow.Parent = object.Parent
		else
			shadow:Destroy()
		end
	end)
	sync()
	shadow.Parent = object.Parent
	return shadow
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
	Components.Gradient(frame, props.Colors or Theme.Colors.Row, props.Lip)
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
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = props.MaxTextSize or 40
	limit.Parent = label

	label.Parent = props.Parent
	if props.AutoFit ~= false then
		FitText.Attach(label)
	end
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
	Components.Gradient(button, props.Colors or Theme.Colors.Pink, props.Lip ~= false)
	if props.Shine ~= false then
		Components.Shine(button, 0.35)
	end

	local scale = Instance.new("UIScale")
	scale.Parent = button

	local label = Components.Label({
		Name = "Text",
		Text = props.Text,
		Parent = button,
		Size = props.LabelSize or UDim2.fromScale(0.86, 0.62),
		-- Nudged up so the text sits above the darker lip.
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

-- Glossy highlight across the top of a box or button. Only one per object.
function Components.Shine(parent: GuiObject, strength: number?)
	local existing = parent:FindFirstChild("Shine")
	if existing and existing:IsA("Frame") then
		existing.BackgroundTransparency = 1 - (strength or 0.45)
		return existing
	end
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
		Lip = true,
	})
	tag.Rotation = props.Rotation or 0
	local label = Components.Label({
		Name = "Text",
		Text = props.Text,
		Parent = tag,
		Size = UDim2.fromScale(0.84, 0.66),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = props.MaxTextSize or 18,
		ZIndex = props.ZIndex,
	})
	return tag, label
end

-- A few drawn stars that fly out from a point on the screen and shrink away.
-- The third argument (old emoji list) is ignored.
local STAR_COLORS = {
	Color3.fromRGB(255, 215, 60),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(130, 230, 255),
}
function Components.Burst(gui: LayerCollector, at: Vector2, _icons)
	local Icons = require(script.Parent:WaitForChild("Icons"))
	for i = 1, 7 do
		local angle = (i / 7) * math.pi * 2 + math.random() * 0.6
		local distance = math.random(60, 110)
		local spark = Icons.Make("Star", gui, {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.fromOffset(at.X, at.Y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = STAR_COLORS[math.random(#STAR_COLORS)],
			ZIndex = 60,
		})
		local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(spark, info, {
			Position = UDim2.fromOffset(at.X + math.cos(angle) * distance, at.Y + math.sin(angle) * distance),
			Size = UDim2.fromOffset(6, 6),
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

-- Popup window, Steal an Egg style: dark navy body with a thick dark border,
-- a light blue striped title bar with an icon and a big chunky title, and a
-- square red close button. Sized in pixels and scaled to fit the screen while
-- leaving room for the HUD on both sides, so the HUD stays visible around it.
--   props.Icon = an Icons name ("Cart", "Book", ...)
function Components.Window(props)
	local Icons = require(script.Parent:WaitForChild("Icons"))

	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Window"
	frame.Size = props.Size or UDim2.fromOffset(720, 470)
	frame.Position = UDim2.fromScale(0.5, 0.52)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Visible = false
	frame.ZIndex = 10
	Components.Corner(frame, UDim.new(0, 16))
	Components.Stroke(frame, 6, Theme.PanelOutline)
	Components.Gradient(frame, Theme.Colors.Navy)

	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local function fitScale(): number
		local camera = Workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		-- Keep ~150px free on each side for the HUD buttons.
		local room = math.max(viewport.X - 300, viewport.X * 0.8)
		return math.max(0.3, math.min(1.15, room / frame.Size.X.Offset, viewport.Y * 0.78 / frame.Size.Y.Offset))
	end

	-- Title bar.
	local bar = Instance.new("Frame")
	bar.Name = "TitleBar"
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.Size = UDim2.new(1, -12, 0, 62)
	bar.Position = UDim2.fromOffset(6, 6)
	bar.ZIndex = 11
	Components.Corner(bar, UDim.new(0, 12))
	Components.Stroke(bar, 4, Theme.PanelOutline)
	-- Always the same light blue, whatever the window (colors are ignored).
	Components.Gradient(bar, Theme.Colors.TitleBlue)
	bar.Parent = frame

	-- Faint diagonal stripes across the bar.
	local stripes = Instance.new("Frame")
	stripes.Name = "Stripes"
	stripes.BackgroundColor3 = Color3.new(1, 1, 1)
	stripes.Size = UDim2.fromScale(1, 1)
	stripes.ZIndex = 11
	Components.Corner(stripes, UDim.new(0, 12))
	local stripeGradient = Instance.new("UIGradient")
	stripeGradient.Rotation = 20
	local keys = { NumberSequenceKeypoint.new(0, 1) }
	for i = 0, 3 do
		local a = 0.08 + i * 0.24
		table.insert(keys, NumberSequenceKeypoint.new(a, 1))
		table.insert(keys, NumberSequenceKeypoint.new(a + 0.001, 0.8))
		table.insert(keys, NumberSequenceKeypoint.new(a + 0.09, 0.8))
		table.insert(keys, NumberSequenceKeypoint.new(a + 0.091, 1))
	end
	table.insert(keys, NumberSequenceKeypoint.new(1, 1))
	stripeGradient.Transparency = NumberSequence.new(keys)
	stripeGradient.Parent = stripes
	stripes.Parent = bar

	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "IconHolder"
	iconHolder.BackgroundTransparency = 1
	iconHolder.Size = UDim2.fromOffset(58, 58)
	iconHolder.Position = UDim2.new(0, 10, 0.5, 0)
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.ZIndex = 12
	iconHolder.Parent = bar
	local function setIcon(name: string?)
		iconHolder:ClearAllChildren()
		if name then
			Icons.Make(name, iconHolder, { Size = UDim2.fromOffset(54, 54), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = -8, ZIndex = 12 })
		end
	end
	setIcon(props.Icon)

	local title = Components.Label({
		Name = "Title",
		Text = props.Title,
		Parent = bar,
		Size = UDim2.new(1, -150, 0, 46),
		Position = UDim2.new(0, 76, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 46,
		StrokeThickness = 4,
		ZIndex = 12,
	})
	title.Font = Theme.TitleFont

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(18, 82)
	content.Size = UDim2.new(1, -36, 1, -98)
	content.ZIndex = 10
	content.Parent = frame

	local window = {
		Frame = frame,
		Content = content,
		Title = title,
		Ribbon = bar,
	}

	-- The colors argument is kept for callers but no longer used.
	function window.SetTitle(text: string, _colors, iconName: string?)
		title.Text = text
		if iconName then
			setIcon(iconName)
		end
	end

	function window.Open()
		local target = fitScale()
		scale.Scale = target * 0.6
		frame.Visible = true
		TweenService:Create(scale, POP_IN, { Scale = target }):Play()
	end

	-- Shadow under the whole window, scaled along with it.
	local shadow = Components.Shadow(frame, 10)
	local shadowScale = Instance.new("UIScale")
	shadowScale.Parent = shadow
	scale:GetPropertyChangedSignal("Scale"):Connect(function()
		shadowScale.Scale = scale.Scale
	end)

	function window.Close()
		frame.Visible = false
		if props.OnClose then
			props.OnClose()
		end
	end

	function window.IsOpen(): boolean
		return frame.Visible
	end

	-- Square red close button inside the title bar.
	local _, closeText = Components.Button({
		Name = "Close",
		Text = "X",
		Parent = bar,
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(1, -7, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Colors = Theme.Colors.Red,
		CornerRadius = UDim.new(0, 10),
		StrokeThickness = 4,
		MaxTextSize = 36,
		TextStroke = 3,
		ZIndex = 13,
		OnClick = window.Close,
	})
	closeText.Font = Theme.TitleFont

	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if frame.Visible then
				scale.Scale = fitScale()
			end
		end)
	end

	frame.Parent = props.Parent
	shadow.Parent = props.Parent
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

	-- Text on a dark rounded plate so it reads over any background.
	local plate = Instance.new("Frame")
	plate.Name = "Toast"
	plate.BackgroundColor3 = Theme.Shadow
	plate.BackgroundTransparency = 0.2
	plate.AutomaticSize = Enum.AutomaticSize.X
	plate.Size = UDim2.fromOffset(0, 42)
	plate.LayoutOrder = math.floor(os.clock() * 100)
	plate.ZIndex = 20
	Components.Corner(plate, UDim.new(1, 0))
	local plateStroke = Components.Stroke(plate, 3, color or Theme.Colors.Pink[1])
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 22)
	padding.PaddingRight = UDim.new(0, 22)
	padding.Parent = plate
	plate.Parent = holder

	local label = Components.Label({
		Text = text,
		Parent = plate,
		Color = color,
		StrokeThickness = 2.5,
		ZIndex = 21,
		AutoFit = false,
	})
	label.TextScaled = false
	label.TextSize = 26
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromScale(0, 1)
	Components.Pop(plate, 0.4)

	task.delay(2.2, function()
		local fadeInfo = TweenInfo.new(0.4)
		TweenService:Create(label, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(plate, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(plateStroke, fadeInfo, { Transparency = 1 }):Play()
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
		end
		task.wait(0.4)
		plate:Destroy()
	end)
end

return Components
