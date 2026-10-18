-- Egg hatch animation, Steal an Egg style: when EggNotify says "Hatched", the
-- egg pops onto the screen, wobbles harder and harder while it cracks, bursts
-- in a white flash with the halves flying apart, then the pet spins in on a
-- glow and rays in its rarity color with its name, rarity and weight.
-- Tap anywhere (or wait) to close. Several hatches queue up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EggConfig = require(Shared:WaitForChild("EggConfig"))
local EggRemotes = require(Shared:WaitForChild("EggRemotes"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HatchUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local SHOW_TIME = 5
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 235, 140)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 110, 255)),
})
-- Zigzag cracks, one list per crack stage: { x, y, length, angle } on the egg.
local CRACKS = {
	{ { 0.3, 0.42, 0.22, 35 }, { 0.48, 0.47, 0.2, -40 } },
	{ { 0.62, 0.38, 0.2, 30 }, { 0.72, 0.5, 0.18, -50 }, { 0.38, 0.6, 0.16, 60 } },
	{ { 0.2, 0.52, 0.18, -30 }, { 0.5, 0.3, 0.2, 75 }, { 0.6, 0.62, 0.2, -20 }, { 0.8, 0.44, 0.14, 40 } },
}

local function tween(object: Instance, seconds: number, goal, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

local function circle(parent: Instance, size: UDim2, color: Color3, transparency: number, z: number)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 0
	frame.Size = size
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.ZIndex = z
	Components.Corner(frame, UDim.new(1, 0))
	frame.Parent = parent
	return frame
end

-- One whole egg drawing (body, spots, shine) filling its parent.
local function drawEgg(parent: Instance, color: Color3)
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Color3.new(1, 1, 1)
	body.Size = UDim2.fromScale(1, 1)
	body.ZIndex = 3
	Components.Corner(body, UDim.new(0.5, 0))
	Components.Stroke(body, 5)
	Components.Gradient(body, { color:Lerp(Color3.new(1, 1, 1), 0.4), color })
	body.Parent = parent
	local spot = color:Lerp(Color3.new(1, 1, 1), 0.65)
	for _, s in { { 0.3, 0.3, 0.2 }, { 0.68, 0.55, 0.26 }, { 0.36, 0.75, 0.16 } } do
		local dot = circle(body, UDim2.fromScale(s[3], s[3] * 0.78), spot, 0.1, 3)
		dot.Position = UDim2.fromScale(s[1], s[2])
	end
	Components.Shine(body, 0.5).Size = UDim2.fromScale(0.5, 0.3)
	return body
end

-- The egg as a top and bottom half (each clips a whole egg drawing) so it can
-- split when it bursts.
local function buildEgg(parent: Instance, color: Color3)
	local egg = Instance.new("Frame")
	egg.Name = "Egg"
	egg.BackgroundTransparency = 1
	egg.Size = UDim2.fromScale(0.26, 0.26)
	egg.SizeConstraint = Enum.SizeConstraint.RelativeYY
	egg.Position = UDim2.fromScale(0.5, 0.48)
	egg.AnchorPoint = Vector2.new(0.5, 0.5)
	egg.ZIndex = 3
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.8
	aspect.Parent = egg
	egg.Parent = parent

	local halves = {}
	for i, part in { "Top", "Bottom" } do
		local clip = Instance.new("Frame")
		clip.Name = part
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(1, 0.5)
		clip.Position = UDim2.fromScale(0, (i - 1) * 0.5)
		clip.ZIndex = 3
		clip.Parent = egg
		local inner = Instance.new("Frame")
		inner.BackgroundTransparency = 1
		inner.Size = UDim2.fromScale(1, 2)
		inner.Position = UDim2.fromScale(0, -(i - 1))
		inner.Parent = clip
		drawEgg(inner, color)
		halves[part] = clip
	end

	local cracks = Instance.new("Frame")
	cracks.Name = "Cracks"
	cracks.BackgroundTransparency = 1
	cracks.Size = UDim2.fromScale(1, 1)
	cracks.ZIndex = 4
	cracks.Parent = egg
	return egg, halves, cracks
end

local function addCracks(cracks: Frame, stage: number)
	for _, c in CRACKS[stage] do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Theme.Outline
		line.BorderSizePixel = 0
		line.Size = UDim2.new(c[3], 0, 0, 5)
		line.Position = UDim2.fromScale(c[1], c[2])
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Rotation = c[4]
		line.ZIndex = 4
		Components.Corner(line, UDim.new(1, 0))
		line.Parent = cracks
	end
end

local function wobble(egg: GuiObject, strength: number, times: number)
	for _ = 1, times do
		tween(egg, 0.07, { Rotation = strength }, Enum.EasingStyle.Sine).Completed:Wait()
		tween(egg, 0.07, { Rotation = -strength }, Enum.EasingStyle.Sine).Completed:Wait()
	end
	tween(egg, 0.06, { Rotation = 0 }).Completed:Wait()
end

local function play(info)
	local pet = info.Pet
	local eggData = EggConfig.Eggs[info.EggId]
	local eggColor = if eggData and eggData.Color then eggData.Color else Color3.fromRGB(255, 240, 210)
	local rarityColor = EggConfig.RarityColors[pet.Rarity] or Color3.new(1, 1, 1)
	local rank = EggConfig.RarityRank[pet.Rarity] or 1

	local screen = Instance.new("TextButton")
	screen.Name = "Hatch"
	screen.Text = ""
	screen.AutoButtonColor = false
	screen.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	screen.BackgroundTransparency = 1
	screen.Size = UDim2.fromScale(1, 1)
	screen.Parent = gui
	tween(screen, 0.3, { BackgroundTransparency = 0.4 })

	-- 1. Egg bounces in and wobbles, cracking a little more each time.
	local egg, halves, cracks = buildEgg(screen, eggColor)
	local eggScale = Instance.new("UIScale")
	eggScale.Scale = 0
	eggScale.Parent = egg
	tween(eggScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back).Completed:Wait()
	task.wait(0.25)
	for stage = 1, #CRACKS do
		wobble(egg, 8 + stage * 6, 2 + stage)
		addCracks(cracks, stage)
		Components.Pop(egg, 1.1)
		task.wait(0.3 - stage * 0.05)
	end
	-- Fast rattle and swell before the pop.
	tween(eggScale, 0.35, { Scale = 1.2 })
	wobble(egg, 5, 4)

	-- 2. Burst: white flash, halves fly apart, sparkles.
	local flash = Instance.new("Frame")
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BorderSizePixel = 0
	flash.Size = UDim2.fromScale(1, 1)
	flash.ZIndex = 10
	flash.Parent = screen
	tween(flash, 0.6, { BackgroundTransparency = 1 })
	cracks:Destroy()
	tween(halves.Top, 0.5, { Position = UDim2.fromScale(-0.4, -0.9), Rotation = -40 })
	tween(halves.Bottom, 0.5, { Position = UDim2.fromScale(0.4, 1.4), Rotation = 30 })
	for _, half in halves do
		for _, d in half:GetDescendants() do
			if d:IsA("Frame") then
				tween(d, 0.5, { BackgroundTransparency = 1 })
			elseif d:IsA("UIStroke") then
				tween(d, 0.5, { Transparency = 1 })
			end
		end
	end
	local center = Components.CenterOf(egg)
	Components.Burst(gui, center, { "✨", "⭐", "💥" })

	-- 3. Reveal: rays and glow in the rarity color, the pet spins in.
	local reveal = Instance.new("Frame")
	reveal.Name = "Reveal"
	reveal.BackgroundTransparency = 1
	reveal.Size = UDim2.fromScale(0.6, 0.6)
	reveal.SizeConstraint = Enum.SizeConstraint.RelativeYY
	reveal.Position = UDim2.fromScale(0.5, 0.45)
	reveal.AnchorPoint = Vector2.new(0.5, 0.5)
	reveal.ZIndex = 2
	reveal.Parent = screen

	local rays = Instance.new("Frame")
	rays.Name = "Rays"
	rays.BackgroundTransparency = 1
	rays.Size = UDim2.fromScale(1, 1)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Parent = reveal
	local rayCount = 6 + rank * 2
	for i = 1, rayCount do
		local ray = Instance.new("Frame")
		ray.BackgroundColor3 = rarityColor:Lerp(Color3.new(1, 1, 1), 0.3)
		ray.BorderSizePixel = 0
		ray.Size = UDim2.fromScale(1.1, 0.07)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Rotation = (i / rayCount) * 180
		ray.ZIndex = 2
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		if pet.Rarity == "Secret" then
			fade.Color = RAINBOW
		end
		fade.Parent = ray
		ray.Parent = rays
	end
	for i, t in { 0.82, 0.65, 0.4 } do
		circle(reveal, UDim2.fromScale(0.75 - i * 0.15, 0.75 - i * 0.15), rarityColor, t, 2)
	end
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * (20 + rank * 8)
	end)

	local revealScale = Instance.new("UIScale")
	revealScale.Scale = 0
	revealScale.Parent = reveal
	tween(revealScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)

	local petIcon = Components.Label({
		Name = "Pet",
		Text = Theme.RarityIcon[pet.Rarity] or "🐣",
		Parent = reveal,
		Size = UDim2.fromScale(0.42, 0.42),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 200,
		StrokeThickness = 0,
		ZIndex = 5,
	})
	petIcon.Rotation = -200
	tween(petIcon, 0.6, { Rotation = 0 }, Enum.EasingStyle.Back)

	-- 4. "You hatched!" banner on top, and a card with name, rarity and weight.
	local banner, bannerText = Components.Tag({
		Name = "Banner",
		Text = "🎉 YOU HATCHED! 🎉",
		Parent = screen,
		Size = UDim2.fromOffset(420, 70),
		Position = UDim2.fromScale(0.5, 0.06),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = Theme.Colors.Yellow,
		StrokeThickness = 5,
		MaxTextSize = 44,
		ZIndex = 6,
	})
	banner.Rotation = -2
	Components.Shine(banner, 0.4)
	bannerText:FindFirstChildOfClass("UIStroke").Thickness = 3.5

	local card = Components.Box({
		Name = "Info",
		Parent = screen,
		Size = UDim2.fromOffset(380, 150),
		Position = UDim2.fromScale(0.5, 0.72),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = Theme.Tint(rarityColor),
		CornerRadius = UDim.new(0, 26),
		StrokeThickness = 5,
		ZIndex = 6,
	})
	Components.Shine(card, 0.5)
	-- Phones: shrink the fixed-size card and banner to fit.
	local fit = Instance.new("UIScale")
	fit.Parent = card
	local bannerFit = Instance.new("UIScale")
	bannerFit.Parent = banner
	local viewport = gui.AbsoluteSize
	fit.Scale = math.min(1, viewport.X * 0.9 / 380, viewport.Y * 0.24 / 150)
	bannerFit.Scale = math.min(1, viewport.X * 0.9 / 420)

	local tag, tagText = Components.Tag({
		Text = string.upper(pet.Rarity),
		Parent = card,
		Size = UDim2.fromOffset(170, 42),
		Position = UDim2.new(0.5, 0, 0, -22),
		AnchorPoint = Vector2.new(0.5, 0),
		Colors = Theme.FromColor(rarityColor),
		StrokeThickness = 4,
		MaxTextSize = 28,
		ZIndex = 7,
	})
	Components.Shine(tag, 0.35)
	local nameLabel = Components.Label({
		Text = pet.Name,
		Parent = card,
		Size = UDim2.new(1, -30, 0, 54),
		Position = UDim2.fromOffset(15, 28),
		MaxTextSize = 50,
		StrokeThickness = 4,
		ZIndex = 7,
	})
	if pet.Rarity == "Secret" then
		local gradient = tag:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Color = RAINBOW
			gradient.Rotation = 0
			task.spawn(function()
				while tag.Parent do
					gradient.Offset = Vector2.new(math.sin(os.clock() * 2) * 0.4, 0)
					task.wait()
				end
			end)
		end
	end
	Components.Tag({
		Name = "Weight",
		Text = string.format("⚖️ %.2f kg", pet.Weight or 0),
		Parent = card,
		Size = UDim2.fromOffset(180, 40),
		Position = UDim2.new(0.5, 0, 1, -16),
		AnchorPoint = Vector2.new(0.5, 1),
		Colors = Theme.Colors.Sky,
		StrokeThickness = 3.5,
		MaxTextSize = 26,
		ZIndex = 7,
	})
	local hint = Components.Label({
		Text = "Tap to continue",
		Parent = screen,
		Size = UDim2.fromScale(0.3, 0.04),
		Position = UDim2.fromScale(0.5, 0.97),
		AnchorPoint = Vector2.new(0.5, 1),
		MaxTextSize = 24,
		StrokeThickness = 3,
	})
	for _, label in { nameLabel, tagText } do
		Components.Pop(label, 0.3)
	end
	Components.Pop(tag, 0.3)
	-- Pop the card and banner in on their fit scales (no second UIScale).
	for _, pair in { { fit, fit.Scale }, { bannerFit, bannerFit.Scale } } do
		pair[1].Scale = pair[2] * 0.4
		tween(pair[1], 0.35, { Scale = pair[2] }, Enum.EasingStyle.Back)
	end
	task.delay(0.2, function()
		Components.Burst(gui, center, { "⭐", "✨", "🎉", Theme.RarityIcon[pet.Rarity] or "🐣" })
		if rank >= 4 then
			task.wait(0.25)
			Components.Burst(gui, center, { "⭐", "💎", "🎉" })
		end
	end)

	-- Close on tap or after a while.
	task.wait(0.6)
	local closed = false
	local signal = Instance.new("BindableEvent")
	local function close()
		if not closed then
			closed = true
			signal:Fire()
		end
	end
	screen.Activated:Connect(close)
	task.delay(SHOW_TIME + rank * 0.5, close)
	if not closed then
		signal.Event:Wait()
	end
	signal:Destroy()
	hint.Visible = false
	tween(revealScale, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(screen, 0.3, { BackgroundTransparency = 1 })
	card.Visible = false
	banner.Visible = false
	task.wait(0.3)
	spin:Disconnect()
	screen:Destroy()
end

local queue = {}
local playing = false

EggRemotes.EggNotify.OnClientEvent:Connect(function(kind, info)
	if kind ~= "Hatched" or type(info) ~= "table" or type(info.Pet) ~= "table" then
		return
	end
	table.insert(queue, info)
	if playing then
		return
	end
	playing = true
	while #queue > 0 do
		local ok, err = pcall(play, table.remove(queue, 1))
		if not ok then
			warn("Hatch animation failed:", err)
			for _, child in gui:GetChildren() do
				child:Destroy()
			end
		end
	end
	playing = false
end)
