-- Egg hatch animation (redone 2026-10-18): when EggNotify says "Hatched", a 3D
-- egg in its own colour drops onto the screen, shakes harder and harder while
-- cracks spread and shell chips fly off, glows white, then bursts into shell
-- shards with a flash. The real animal (Shared.Animals) jumps out, spins,
-- lands and looks around on rays and a glow in its rarity colour, with its
-- name, rarity and weight below. Rarer = more shakes, more rays, more bursts.
-- Tap anywhere to skip ahead / close. Several hatches queue up.
-- The admin panel can play it for any egg through the PreviewHatch event.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EggConfig = require(Shared:WaitForChild("EggConfig"))
local EggRemotes = require(Shared:WaitForChild("EggRemotes"))
local Animals = require(Shared:WaitForChild("Animals"))
local EggLooks = require(Shared:WaitForChild("EggLooks"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local Icons = require(script.Parent:WaitForChild("Icons"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HatchUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Admin preview: PreviewHatch:Fire({ EggId = ..., Pet = { Name, Rarity, Weight } })
local previewEvent = Instance.new("BindableEvent")
previewEvent.Name = "PreviewHatch"
previewEvent.Parent = gui

local SHOW_TIME = 6
local EGG_SIZE = Vector3.new(4, 5.2, 4)
local ANIMAL_HEIGHT = 5 -- studs the hatched animal is scaled to in the viewport
local GRAVITY = Vector3.new(0, -70, 0)
local WHITE = Color3.new(1, 1, 1)
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 235, 140)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 110, 255)),
})

local rng = Random.new()

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
	frame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	frame.ZIndex = z
	Components.Corner(frame, UDim.new(1, 0))
	frame.Parent = parent
	return frame
end

local function smoothPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	return p
end

-- A point on the egg's surface (an ellipsoid), and the way out of it there.
local function eggSurface(yaw: number, pitch: number): (Vector3, Vector3)
	local h = EGG_SIZE / 2
	local dir = Vector3.new(math.cos(pitch) * math.sin(yaw), math.sin(pitch), math.cos(pitch) * math.cos(yaw))
	local point = Vector3.new(dir.X * h.X, dir.Y * h.Y, dir.Z * h.Z)
	local normal = Vector3.new(dir.X / h.X, dir.Y / h.Y, dir.Z / h.Z).Unit
	return point, normal
end

-- Runs fn(alpha 0..1, dt) every frame for `seconds` (stops early if skip() says so).
local function animate(seconds: number, fn, skip)
	local t = 0
	while t < seconds do
		local dt = RunService.RenderStepped:Wait()
		t += dt
		fn(math.min(t / seconds, 1), dt)
		if skip and skip() then
			break
		end
	end
	fn(1, 0)
end

local function play(info)
	local pet = info.Pet
	local eggData = EggConfig.Eggs[info.EggId]
	local eggColor = if eggData and eggData.Color then eggData.Color else Color3.fromRGB(255, 240, 210)
	local rarityColor = EggConfig.RarityColors[pet.Rarity] or WHITE
	local rank = EggConfig.RarityRank[pet.Rarity] or 1

	local skipping = false
	local function skip()
		return skipping
	end

	local screen = Instance.new("TextButton")
	screen.Name = "Hatch"
	screen.Text = ""
	screen.AutoButtonColor = false
	screen.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	screen.BackgroundTransparency = 1
	screen.Size = UDim2.fromScale(1, 1)
	screen.Parent = gui
	screen.Activated:Connect(function()
		skipping = true
	end)
	tween(screen, 0.3, { BackgroundTransparency = 0.35 })

	-- Glow behind the egg: grows with every shake, then holds the rays.
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.BackgroundTransparency = 1
	back.Size = UDim2.fromScale(0.62, 0.62)
	back.SizeConstraint = Enum.SizeConstraint.RelativeYY
	back.Position = UDim2.fromScale(0.5, 0.44)
	back.AnchorPoint = Vector2.new(0.5, 0.5)
	back.ZIndex = 2
	back.Parent = screen
	local glows = {}
	for i, t in { 0.85, 0.7, 0.5 } do
		local g = circle(back, UDim2.fromScale(0.75 - i * 0.15, 0.75 - i * 0.15), rarityColor, 1, 2)
		g:SetAttribute("Target", t)
		glows[i] = g
	end
	local function setGlow(amount: number)
		for _, g in glows do
			local target = g:GetAttribute("Target")
			tween(g, 0.25, { BackgroundTransparency = 1 - (1 - target) * amount })
		end
	end

	-- 3D stage.
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Stage"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Color3.fromRGB(190, 180, 210)
	viewport.LightColor = Color3.fromRGB(255, 250, 235)
	viewport.LightDirection = Vector3.new(-0.6, -1, -0.8)
	viewport.ZIndex = 4
	viewport.Parent = screen
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local eggFocus = Vector3.new(0, EGG_SIZE.Y / 2, 0)
	local function frameOn(focus: Vector3, distance: number)
		camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, distance * 0.18, distance), focus)
	end
	frameOn(eggFocus, 24)

	local shadow = smoothPart({
		Name = "Shadow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.1, 4.6, 4.6),
		CFrame = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(30, 20, 50),
		Transparency = 1,
		Parent = world,
	})

	-- The egg: its own design (Shared.EggLooks) if it has one, else a smooth
	-- ellipsoid with lighter spots. One model; placeEgg moves every part.
	local egg = Instance.new("Model")
	egg.Name = "Egg"
	local eggBase = CFrame.new(0, EGG_SIZE.Y / 2, 0)
	local shell = EggLooks.Build(info.EggId, EGG_SIZE, { Loose = true, Effects = false })
	local spotColor
	if shell then
		shell.Name = "Shell"
		shell.Anchored = true
		shell.CanQuery = false
		shell.CanTouch = false
		eggColor = shell.Color
		local first = shell:FindFirstChildWhichIsA("BasePart")
		spotColor = if first then first.Color else eggColor:Lerp(WHITE, 0.6)
		for _, p in shell:GetChildren() do
			if p:IsA("BasePart") then
				p.Parent = egg
			end
		end
	else
		shell = smoothPart({ Name = "Shell", Size = EGG_SIZE, Color = eggColor, CFrame = eggBase })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = shell
		spotColor = eggColor:Lerp(WHITE, 0.6)
		if (eggColor.R + eggColor.G + eggColor.B) / 3 > 0.8 then
			spotColor = eggColor:Lerp(rarityColor, 0.55) -- white eggs get rarity-tinted spots
		end
		for _, s in { { 0.4, 0.5, 1.3 }, { 2.3, 0.1, 1.1 }, { 4.1, 0.65, 1.2 }, { 5.3, -0.25, 0.9 }, { 1.2, -0.45, 1 }, { 3.2, -0.6, 0.8 } } do
			local point, normal = eggSurface(s[1], s[2])
			local spot = smoothPart({
				Name = "Spot",
				Size = Vector3.new(s[3], s[3], 0.35),
				Color = spotColor,
				CFrame = CFrame.lookAt(shell.Position + point - normal * 0.12, shell.Position + point + normal),
			})
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Sphere
			m.Parent = spot
			spot.Parent = egg
		end
	end
	shell.Parent = egg
	egg.PrimaryPart = shell
	local eggOffsets = {}
	for _, p in egg:GetChildren() do
		if p:IsA("BasePart") then
			eggOffsets[p] = { Offset = shell.CFrame:ToObjectSpace(p.CFrame), Color = p.Color, Size = p.Size }
		end
	end
	local function placeEgg(cf: CFrame, scale: number?)
		scale = scale or 1
		for p, o in eggOffsets do
			local off = o.Offset
			p.CFrame = cf * CFrame.new(off.Position * scale) * off.Rotation
			p.Size = o.Size * scale
		end
	end
	placeEgg(eggBase)
	egg.Parent = world
	local function tintEgg(amount: number)
		for p, o in eggOffsets do
			p.Color = o.Color:Lerp(WHITE, amount)
		end
	end

	-- Flying bits (chips and shards) with simple gravity.
	local flying = {}
	local function fling(part: BasePart, velocity: Vector3, life: number)
		part.Parent = world
		table.insert(flying, { Part = part, Vel = velocity, Spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)), Life = life, Age = 0 })
	end
	local flyConn = RunService.RenderStepped:Connect(function(dt)
		for i = #flying, 1, -1 do
			local f = flying[i]
			f.Age += dt
			f.Vel += GRAVITY * dt
			f.Part.CFrame = (f.Part.CFrame + f.Vel * dt) * CFrame.Angles(f.Spin.X * dt, f.Spin.Y * dt, f.Spin.Z * dt)
			f.Part.Transparency = math.clamp((f.Age - f.Life * 0.6) / (f.Life * 0.4), 0, 1)
			if f.Age >= f.Life then
				f.Part:Destroy()
				table.remove(flying, i)
			end
		end
	end)
	local function chip(color: Color3, size: number, from: Vector3, out: Vector3, speed: number, life: number)
		local part = smoothPart({
			Name = "Chip",
			Size = Vector3.new(size, size * 0.3, size * 0.8),
			Color = color,
			CFrame = CFrame.new(from) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0),
		})
		fling(part, out * speed + Vector3.new(0, speed * 0.6, 0), life)
	end

	-- Cracks: dark zigzags stuck to the egg surface.
	local cracksDone = 0
	local function addCrack()
		cracksDone += 1
		local yaw = rng:NextNumber(-0.9, 0.9) -- keep them on the side facing the camera
		local pitch = rng:NextNumber(-0.3, 0.55)
		for k = 0, 3 do
			local point, normal = eggSurface(yaw + k * 0.16, pitch + (if k % 2 == 0 then 0.1 else -0.1))
			local line = smoothPart({
				Name = "Crack",
				Size = Vector3.new(0.13, 0.75, 0.05),
				Color = Color3.fromRGB(40, 25, 30),
			})
			-- offset from the egg's centre, like the spots
			local offset = CFrame.lookAt(point + normal * 0.02, point + normal * 2) * CFrame.Angles(0, 0, (if k % 2 == 0 then 0.7 else -0.7))
			eggOffsets[line] = { Offset = offset, Color = line.Color, Size = line.Size }
			line.Parent = egg
		end
	end

	-- 1. Drop in with a bounce.
	local dropFrom = eggBase + Vector3.new(0, 14, 0)
	tween(shadow, 0.5, { Transparency = 0.6 })
	animate(0.55, function(a)
		local bounce = TweenService:GetValue(a, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		placeEgg(dropFrom:Lerp(eggBase, bounce))
	end)
	task.wait(0.2)

	-- 2. Shakes: harder each time, a crack and some chips after each.
	local shakes = 3 + (if rank >= 4 then 1 else 0) + (if rank >= 6 then 1 else 0)
	for i = 1, shakes do
		if skipping then
			break
		end
		local strength = math.rad(7 + i * 6)
		local duration = 0.32 + i * 0.05
		animate(duration, function(a, _)
			local wave = math.sin(a * math.pi * (3 + i)) * strength * (1 - a * 0.3)
			local hop = math.sin(a * math.pi) * (0.25 + i * 0.12)
			placeEgg(eggBase * CFrame.new(0, hop - EGG_SIZE.Y / 2, 0) * CFrame.Angles(0, 0, wave) * CFrame.new(0, EGG_SIZE.Y / 2, 0))
		end, skip)
		placeEgg(eggBase)
		addCrack()
		placeEgg(eggBase)
		for _ = 1, 2 + i do
			local point, normal = eggSurface(rng:NextNumber(-1.2, 1.2), rng:NextNumber(-0.2, 0.7))
			chip(eggColor, rng:NextNumber(0.35, 0.6), eggBase.Position + point, normal, rng:NextNumber(10, 16), 0.9)
		end
		setGlow(i / shakes)
		animate(0.12, function(a)
			placeEgg(eggBase, 1 + math.sin(a * math.pi) * 0.07)
		end)
		task.wait(math.max(0.08, 0.3 - i * 0.05))
	end

	-- 3. Charge up: fast rattle, swell, glow white.
	animate(if skipping then 0.1 else 0.55, function(a)
		local jitter = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * 0.12 * a
		placeEgg(eggBase + jitter, 1 + a * 0.22)
		tintEgg(a * 0.85)
	end)

	-- 4. Burst: shards everywhere, flash, ring, confetti.
	for p in eggOffsets do
		p.Transparency = 1
	end
	local center = eggBase.Position
	for _ = 1, 16 + rank * 2 do
		local point, normal = eggSurface(rng:NextNumber(0, 6.28), rng:NextNumber(-1.2, 1.4))
		local color = if rng:NextNumber() < 0.3 then spotColor else eggColor
		chip(color, rng:NextNumber(0.7, 1.4), center + point * 1.1, normal, rng:NextNumber(14, 26), 1.3)
	end
	tween(shadow, 0.4, { Transparency = 0.75 })
	local flash = Instance.new("Frame")
	flash.BackgroundColor3 = WHITE
	flash.BorderSizePixel = 0
	flash.Size = UDim2.fromScale(1, 1)
	flash.ZIndex = 10
	flash.Parent = screen
	tween(flash, 0.7, { BackgroundTransparency = 1 })
	local ring = circle(screen, UDim2.fromScale(0.12, 0.12), WHITE, 1, 5)
	ring.Position = back.Position
	local ringStroke = Components.Stroke(ring, 10, rarityColor)
	tween(ring, 0.6, { Size = UDim2.fromScale(0.9, 0.9) })
	tween(ringStroke, 0.6, { Transparency = 1, Thickness = 2 })
	local burstAt = back.AbsolutePosition + back.AbsoluteSize / 2
	Components.Burst(gui, burstAt)

	-- Rays in the rarity colour (rainbow for Secret).
	local rays = Instance.new("Frame")
	rays.Name = "Rays"
	rays.BackgroundTransparency = 1
	rays.Size = UDim2.fromScale(1.2, 1.2)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.ZIndex = 1
	rays.Parent = back
	local rayCount = 6 + rank * 2
	for i = 1, rayCount do
		local ray = Instance.new("Frame")
		ray.BackgroundColor3 = rarityColor:Lerp(WHITE, 0.3)
		ray.BorderSizePixel = 0
		ray.Size = UDim2.fromScale(1.1, 0.07)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Rotation = (i / rayCount) * 180
		ray.ZIndex = 1
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		if pet.Rarity == "Secret" then
			fade.Color = RAINBOW
		end
		fade.Parent = ray
		ray.Parent = rays
	end
	local raysScale = Instance.new("UIScale")
	raysScale.Scale = 0
	raysScale.Parent = rays
	tween(raysScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	local spin = RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * (18 + rank * 8)
	end)

	-- 5. The animal jumps out, spins once, lands and looks around.
	local rig, pawIcon
	local spec = Animals.GetSpec(pet.Name)
	if spec then
		rig = Animals.Build(pet.Name, { Parent = world, World = world, Scale = ANIMAL_HEIGHT / (spec.Scale or 3) })
	end
	local animalConn
	if rig then
		-- heading 0 faces the camera (+Z)
		local heading, pos, mode, speed = 0, Vector3.zero, "walk", 6
		local t = 0
		rig:Step(0, "idle", 0, pos, heading)
		local _, size = rig.Model:GetBoundingBox()
		local focus = Vector3.new(0, size.Y * 0.5, 0)
		local distance = math.max(size.X, size.Y * 1.25, size.Z * 0.8) / (2 * math.tan(math.rad(camera.FieldOfView / 2))) * 1.35
		local camFrom = camera.CFrame
		local jumpTime, nextHop = 0.75, 3
		animalConn = RunService.RenderStepped:Connect(function(dt)
			t += dt
			if t < jumpTime then
				local a = t / jumpTime
				pos = Vector3.new(0, math.sin(a * math.pi) * 5, 0)
				heading = a * math.pi * 2 -- one full spin, ends facing the camera
				mode, speed = "walk", 8
				local camGoal = CFrame.lookAt(focus + Vector3.new(0, distance * 0.18, distance), focus)
				camera.CFrame = camFrom:Lerp(camGoal, TweenService:GetValue(a, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
			else
				local since = t - jumpTime
				-- a happy hop every few seconds, otherwise idle and look around
				local hopA = (since - nextHop) / 0.45
				if hopA >= 0 and hopA <= 1 then
					pos = Vector3.new(0, math.sin(hopA * math.pi) * 1.6, 0)
					mode, speed = "walk", 5
				else
					if hopA > 1 then
						nextHop += 2.6
					end
					pos = Vector3.zero
					mode, speed = "idle", 0
				end
				heading = math.pi * 2 + math.sin(since * 0.9) * 0.45
			end
			rig:Step(dt, mode, speed, pos, heading)
		end)
	else
		-- No model for this pet (old pets): the drawn paw like before.
		pawIcon = Icons.Make("Paw", back, {
			Name = "Pet",
			Size = UDim2.fromScale(0.42, 0.42),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = rarityColor:Lerp(WHITE, 0.35),
			Pixels = 180,
			ZIndex = 5,
		})
		pawIcon.Rotation = -200
		tween(pawIcon, 0.6, { Rotation = 0 }, Enum.EasingStyle.Back)
	end
	task.wait(0.55)

	-- 6. "You hatched!" banner on top, and a card with name, rarity and weight.
	local banner, bannerText = Components.Tag({
		Name = "Banner",
		Text = "YOU HATCHED!",
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
	bannerText.Font = Theme.TitleFont

	local card = Components.Box({
		Name = "Info",
		Parent = screen,
		Size = UDim2.fromOffset(380, 150),
		Position = UDim2.fromScale(0.5, 0.74),
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
	local screenSize = gui.AbsoluteSize
	fit.Scale = math.min(1, screenSize.X * 0.9 / 380, screenSize.Y * 0.22 / 150)
	bannerFit.Scale = math.min(1, screenSize.X * 0.9 / 420)

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
		Text = string.format("%.2f kg", pet.Weight or 0),
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
		Position = UDim2.fromScale(0.5, 0.98),
		AnchorPoint = Vector2.new(0.5, 1),
		MaxTextSize = 24,
		StrokeThickness = 3,
		ZIndex = 6,
	})
	for _, label in { nameLabel, tagText } do
		Components.Pop(label, 0.3)
	end
	Components.Pop(tag, 0.3)
	for _, pair in { { fit, fit.Scale }, { bannerFit, bannerFit.Scale } } do
		pair[1].Scale = pair[2] * 0.4
		tween(pair[1], 0.35, { Scale = pair[2] }, Enum.EasingStyle.Back)
	end
	task.delay(0.15, function()
		for _ = 1, if rank >= 5 then 3 elseif rank >= 4 then 2 else 1 do
			if not screen.Parent then
				return
			end
			Components.Burst(gui, burstAt)
			task.wait(0.25)
		end
	end)

	-- Close on tap or after a while.
	skipping = false
	task.wait(0.5)
	local closeAt = os.clock() + SHOW_TIME + rank * 0.5
	while not skipping and os.clock() < closeAt do
		task.wait()
	end
	hint.Visible = false
	card.Visible = false
	banner.Visible = false
	tween(raysScale, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(screen, 0.3, { BackgroundTransparency = 1 })
	tween(viewport, 0.25, { ImageTransparency = 1 })
	for _, g in glows do
		tween(g, 0.25, { BackgroundTransparency = 1 })
	end
	task.wait(0.3)
	spin:Disconnect()
	flyConn:Disconnect()
	if animalConn then
		animalConn:Disconnect()
	end
	screen:Destroy()
end

local queue = {}
local playing = false

local function enqueue(info)
	if type(info) ~= "table" or type(info.Pet) ~= "table" then
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
				if child ~= previewEvent then
					child:Destroy()
				end
			end
		end
	end
	playing = false
end

EggRemotes.EggNotify.OnClientEvent:Connect(function(kind, info)
	if kind == "Hatched" then
		enqueue(info)
	end
end)
previewEvent.Event:Connect(enqueue)
