-- Hand-made cartoon icons built from rounded frames (no emoji, no images):
-- flat bright colours with thick dark outlines, Steal an Egg style.
--
--   Icons.Make("Cart", parent, { Size = UDim2.fromOffset(48, 48), Position = ..., AnchorPoint = ..., ZIndex = 3 })
--   Icons.Make("Paw", parent, { Size = ..., Color = rarityColor })   -- some icons take a colour
--   Icons.Make("Paw", parent, { Size = ..., Silhouette = true })      -- dark locked look
--
-- Names: Cash, Coin, Shoe, Cart, Book, Paw, Trophy, Egg, Bag, Gear, Lock,
-- Star, Rocket, Check. Sizes are in pixels so the outlines can match the icon size.

local Theme = require(script.Parent:WaitForChild("Theme"))

local Icons = {}

local OUTLINE = Color3.fromRGB(20, 22, 40)
local SILHOUETTE = Color3.fromRGB(28, 32, 52)
local WHITE = Color3.new(1, 1, 1)

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Context for one icon: knows its outline thickness and silhouette mode.
local function painter(root: Frame, pixels: number, silhouette: boolean, z: number)
	local line = math.max(1.5, pixels / 20)
	local paint = {}

	-- A rounded shape. x, y = centre (0..1), w, h = size (0..1), radius = 0..1 of the short side.
	function paint.Shape(x, y, w, h, color: Color3, radius: number?, options)
		options = options or {}
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(x, y)
		frame.Size = UDim2.fromScale(w, h)
		frame.Rotation = options.Rotation or 0
		frame.BackgroundColor3 = if silhouette then SILHOUETTE else color
		frame.BackgroundTransparency = if options.Hollow then 1 else 0
		frame.ZIndex = z + (options.Layer or 0)
		if radius and radius > 0 then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = if radius >= 0.5 then UDim.new(0.5, 0) else UDim.new(radius, 0)
			corner.Parent = frame
		end
		if options.Stroke ~= false then
			local stroke = Instance.new("UIStroke")
			stroke.Color = if silhouette then rgb(60, 66, 100) else OUTLINE
			stroke.Thickness = (options.StrokeScale or 1) * line
			stroke.LineJoinMode = Enum.LineJoinMode.Round
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = frame
		end
		if options.Shade and not silhouette then
			-- Lighter top, slightly darker bottom: reads as a chunky 3D shape.
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Color = ColorSequence.new(color:Lerp(WHITE, 0.3), color:Lerp(Color3.new(), 0.12))
			gradient.Parent = frame
		end
		frame.Parent = options.Parent or root
		return frame
	end

	-- Small white gloss blob, hidden on silhouettes.
	function paint.Gloss(x, y, w, h, layer)
		if silhouette then
			return
		end
		local gloss = paint.Shape(x, y, w, h, WHITE, 0.5, { Stroke = false, Layer = layer or 5 })
		gloss.BackgroundTransparency = 0.35
		return gloss
	end

	-- Bold outlined text inside an icon (for "$").
	function paint.Text(text: string, x, y, w, h, color: Color3, layer)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(x, y)
		label.Size = UDim2.fromScale(w, h)
		label.Font = Theme.TitleFont or Theme.Font
		label.Text = text
		label.TextScaled = true
		label.TextColor3 = if silhouette then rgb(60, 66, 100) else color
		label.ZIndex = z + (layer or 4)
		local stroke = Instance.new("UIStroke")
		stroke.Color = OUTLINE
		stroke.Thickness = line * 0.7
		stroke.Transparency = if silhouette then 1 else 0
		stroke.Parent = label
		label.Parent = root
		return label
	end

	return paint
end

local DRAW = {}

function DRAW.Cash(p)
	local green = rgb(95, 210, 90)
	p.Shape(0.42, 0.55, 0.78, 0.5, green:Lerp(Color3.new(), 0.2), 0.18, { Rotation = -14 })
	p.Shape(0.54, 0.46, 0.78, 0.5, green, 0.18, { Rotation = -14, Layer = 1, Shade = true })
	p.Shape(0.54, 0.46, 0.3, 0.34, rgb(170, 240, 150), 0.5, { Rotation = -14, Layer = 2, StrokeScale = 0.6 })
	p.Text("$", 0.54, 0.46, 0.26, 0.3, rgb(60, 150, 60), 3)
end

function DRAW.Coin(p)
	p.Shape(0.5, 0.54, 0.82, 0.82, rgb(225, 150, 20), 0.5)
	p.Shape(0.5, 0.48, 0.82, 0.82, rgb(255, 205, 50), 0.5, { Layer = 1, Shade = true })
	p.Shape(0.5, 0.48, 0.56, 0.56, rgb(255, 225, 110), 0.5, { Layer = 2, StrokeScale = 0.6 })
	p.Text("$", 0.5, 0.48, 0.42, 0.46, rgb(230, 150, 20), 3)
	p.Gloss(0.32, 0.28, 0.18, 0.12)
end

function DRAW.Shoe(p)
	local red = rgb(240, 70, 70)
	p.Shape(0.5, 0.8, 0.9, 0.16, WHITE, 0.5) -- sole
	p.Shape(0.4, 0.5, 0.44, 0.5, red, 0.35, { Layer = 1, Shade = true }) -- ankle
	p.Shape(0.6, 0.66, 0.74, 0.3, red, 0.5, { Layer = 1, Shade = true }) -- toe
	p.Shape(0.5, 0.56, 0.3, 0.07, WHITE, 0.5, { Layer = 2, StrokeScale = 0.5, Rotation = -20 }) -- laces
	p.Shape(0.56, 0.48, 0.24, 0.07, WHITE, 0.5, { Layer = 2, StrokeScale = 0.5, Rotation = -20 })
	-- little speed wings
	p.Shape(0.14, 0.42, 0.26, 0.1, rgb(140, 220, 255), 0.5, { Rotation = 20 })
	p.Shape(0.12, 0.56, 0.22, 0.09, rgb(140, 220, 255), 0.5, { Rotation = 8 })
	p.Gloss(0.36, 0.36, 0.14, 0.1)
end

function DRAW.Cart(p)
	local body = rgb(255, 215, 70)
	p.Shape(0.16, 0.3, 0.26, 0.09, rgb(120, 125, 150), 0.5, { Rotation = 20 }) -- handle
	p.Shape(0.54, 0.47, 0.7, 0.4, body, 0.22, { Layer = 1, Shade = true })
	for i = 0, 2 do
		p.Shape(0.36 + i * 0.18, 0.47, 0.07, 0.26, body:Lerp(Color3.new(), 0.25), 0.5, { Layer = 2, Stroke = false })
	end
	p.Shape(0.38, 0.82, 0.18, 0.18, rgb(60, 65, 90), 0.5, { Layer = 1 })
	p.Shape(0.72, 0.82, 0.18, 0.18, rgb(60, 65, 90), 0.5, { Layer = 1 })
	p.Gloss(0.4, 0.34, 0.24, 0.08)
end

function DRAW.Book(p)
	local cover = rgb(70, 160, 255)
	p.Shape(0.52, 0.53, 0.72, 0.8, rgb(240, 240, 250), 0.12) -- pages
	p.Shape(0.47, 0.48, 0.72, 0.8, cover, 0.14, { Layer = 1, Shade = true })
	p.Shape(0.18, 0.48, 0.12, 0.8, cover:Lerp(Color3.new(), 0.3), 0.3, { Layer = 2 }) -- spine
	p.Shape(0.53, 0.38, 0.38, 0.22, rgb(255, 215, 70), 0.3, { Layer = 2, StrokeScale = 0.7 }) -- label
	p.Gloss(0.44, 0.18, 0.3, 0.07)
end

function DRAW.Paw(p, color: Color3?)
	local c = color or rgb(255, 160, 60)
	p.Shape(0.5, 0.64, 0.5, 0.42, c, 0.5, { Shade = true })
	p.Shape(0.2, 0.42, 0.2, 0.25, c, 0.5, { Rotation = -25, Shade = true })
	p.Shape(0.38, 0.22, 0.2, 0.26, c, 0.5, { Rotation = -8, Shade = true })
	p.Shape(0.62, 0.22, 0.2, 0.26, c, 0.5, { Rotation = 8, Shade = true })
	p.Shape(0.8, 0.42, 0.2, 0.25, c, 0.5, { Rotation = 25, Shade = true })
	p.Gloss(0.42, 0.55, 0.16, 0.08)
end

function DRAW.Trophy(p)
	local gold = rgb(255, 200, 50)
	p.Shape(0.2, 0.36, 0.26, 0.28, gold, 0.5, { Hollow = true, StrokeScale = 1.6 }) -- handles
	p.Shape(0.8, 0.36, 0.26, 0.28, gold, 0.5, { Hollow = true, StrokeScale = 1.6 })
	p.Shape(0.5, 0.36, 0.56, 0.52, gold, 0.4, { Layer = 1, Shade = true }) -- cup
	p.Shape(0.5, 0.68, 0.14, 0.2, gold:Lerp(Color3.new(), 0.15), 0.2, { Layer = 1 }) -- stem
	p.Shape(0.5, 0.84, 0.5, 0.14, rgb(140, 90, 60), 0.3, { Layer = 2 }) -- base
	p.Gloss(0.38, 0.24, 0.12, 0.18)
end

function DRAW.Egg(p, color: Color3?)
	local c = color or rgb(255, 245, 220)
	p.Shape(0.5, 0.52, 0.66, 0.86, c, 0.5, { Shade = true })
	if color == nil then
		p.Shape(0.36, 0.6, 0.16, 0.14, rgb(120, 200, 110), 0.5, { Layer = 1, StrokeScale = 0.6 })
		p.Shape(0.62, 0.42, 0.14, 0.12, rgb(120, 200, 110), 0.5, { Layer = 1, StrokeScale = 0.6 })
		p.Shape(0.6, 0.72, 0.12, 0.1, rgb(120, 200, 110), 0.5, { Layer = 1, StrokeScale = 0.6 })
	end
	p.Gloss(0.38, 0.28, 0.14, 0.18)
end

function DRAW.Bag(p)
	local brown = rgb(200, 120, 70)
	p.Shape(0.5, 0.2, 0.36, 0.22, brown, 0.5, { Hollow = true, StrokeScale = 1.6 }) -- handle
	p.Shape(0.5, 0.58, 0.76, 0.66, brown, 0.3, { Layer = 1, Shade = true })
	p.Shape(0.5, 0.42, 0.76, 0.24, brown:Lerp(Color3.new(), 0.18), 0.3, { Layer = 2 }) -- flap
	p.Shape(0.5, 0.52, 0.16, 0.14, rgb(255, 210, 70), 0.3, { Layer = 3, StrokeScale = 0.6 }) -- clasp
	p.Gloss(0.34, 0.66, 0.1, 0.16)
end

function DRAW.Gear(p)
	local gray = rgb(175, 180, 205)
	for i = 0, 3 do
		p.Shape(0.5, 0.5, 0.22, 0.92, gray, 0.25, { Rotation = i * 45 })
	end
	p.Shape(0.5, 0.5, 0.7, 0.7, gray, 0.5, { Layer = 1, Shade = true })
	p.Shape(0.5, 0.5, 0.28, 0.28, rgb(60, 65, 95), 0.5, { Layer = 2 })
end

function DRAW.Lock(p)
	p.Shape(0.5, 0.34, 0.46, 0.5, WHITE, 0.5, { Hollow = true, StrokeScale = 2.2 }) -- shackle
	p.Shape(0.5, 0.64, 0.7, 0.5, rgb(235, 235, 245), 0.22, { Layer = 1, Shade = true })
	p.Shape(0.5, 0.62, 0.12, 0.2, rgb(60, 65, 95), 0.5, { Layer = 2, Stroke = false })
end

function DRAW.Star(p, color: Color3?)
	local c = color or rgb(255, 210, 50)
	p.Shape(0.5, 0.52, 0.62, 0.62, c, 0.18, { Rotation = 0, Shade = true })
	p.Shape(0.5, 0.52, 0.62, 0.62, c, 0.18, { Rotation = 45, Layer = 1, Shade = true })
	p.Gloss(0.4, 0.38, 0.16, 0.1, 3)
end

function DRAW.Rocket(p)
	p.Shape(0.3, 0.72, 0.2, 0.3, rgb(240, 70, 70), 0.4, { Rotation = 30 }) -- fins
	p.Shape(0.7, 0.72, 0.2, 0.3, rgb(240, 70, 70), 0.4, { Rotation = -30 })
	p.Shape(0.5, 0.88, 0.2, 0.18, rgb(255, 170, 40), 0.5) -- flame
	p.Shape(0.5, 0.45, 0.36, 0.76, rgb(235, 235, 245), 0.5, { Layer = 1, Shade = true })
	p.Shape(0.5, 0.38, 0.18, 0.18, rgb(90, 180, 255), 0.5, { Layer = 2, StrokeScale = 0.7 })
end

function DRAW.Check(p)
	local green = rgb(90, 220, 110)
	p.Shape(0.34, 0.6, 0.16, 0.42, green, 0.5, { Rotation = -45 })
	p.Shape(0.6, 0.48, 0.16, 0.74, green, 0.5, { Rotation = 38 })
end

function Icons.Make(name: string, parent: Instance, props)
	props = props or {}
	local root = Instance.new("Frame")
	root.Name = props.Name or (name .. "Icon")
	root.BackgroundTransparency = 1
	root.Size = props.Size or UDim2.fromOffset(48, 48)
	root.Position = props.Position or UDim2.new()
	root.AnchorPoint = props.AnchorPoint or Vector2.zero
	root.Rotation = props.Rotation or 0
	root.ZIndex = props.ZIndex or 1
	root.LayoutOrder = props.LayoutOrder or 0
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = root

	local pixels = props.Pixels or root.Size.Y.Offset
	if pixels <= 0 then
		pixels = 48
	end
	local draw = DRAW[name] or DRAW.Star
	draw(painter(root, pixels, props.Silhouette == true, root.ZIndex), props.Color)

	root.Parent = parent
	return root
end

return Icons
