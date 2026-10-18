--!nonstrict
-- Each animal egg's own look (designs from Claude Design, 2026-10-19). One data
-- module per egg in Looks, named after the egg id ("Red Panda" -> Looks.RedPandaEgg).
-- Used by the server's EggFactory (world, carried, pen, falling and guardian eggs)
-- and the client's hatch screen. Eggs without a look (the Legacy ones) return nil
-- and stay a plain coloured sphere.
--
--   EggLooks.Get(eggId)               -> look table or nil
--   EggLooks.ShellColor(eggId)        -> Color3 or nil
--   EggLooks.Build(eggId, size, opts) -> shell Part with the decorations as children, or nil
--     size: the egg's size in studs (EggFactory.SizeFor). opts:
--       Loose = true    decorations anchored and not welded (the caller places every part)
--       Effects = false no glow light or sparkles (a ViewportFrame can't show them)
--
-- Look table:
--   Shell = { r, g, b }, ShellMaterial = "SmoothPlastic"
--   Parts = { { shape, x, y, z, width, height, depth, rotX, rotY, rotZ, r, g, b, material? }, ... }
--     units: 1 = half the egg's width (the shell is 2 x 2.6 x 2 units)
--     shape: "ell" = sphere stretched to the size, "box", "cyl" = cylinder along X
--     material: nil (SmoothPlastic), "Neon" or "Glass" (35% see-through)
--   Light = { Color, Brightness, Range (units), Pulse } or nil
--   Sparkles = { Color, Rate, Size (units), Speed, Lifetime } or nil

local TweenService = game:GetService("TweenService")

local Looks = script:WaitForChild("Looks")

local EggLooks = {}

local cache = {}

function EggLooks.Get(eggId: string)
	if cache[eggId] == nil then
		local module = Looks:FindFirstChild(eggId)
		local ok, look = false, nil
		if module and module:IsA("ModuleScript") then
			ok, look = pcall(require, module)
			if not ok then
				warn(`[EggLooks] {eggId} failed to load: {look}`)
			end
		end
		cache[eggId] = if ok and type(look) == "table" and look.Parts then look else false
	end
	return cache[eggId] or nil
end

function EggLooks.ShellColor(eggId: string): Color3?
	local look = EggLooks.Get(eggId)
	return look and Color3.fromRGB(look.Shell[1], look.Shell[2], look.Shell[3])
end

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function smooth(p: BasePart)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
end

local function decor(shell: BasePart, u: number, d, i: number, loose: boolean)
	local p = Instance.new("Part")
	p.Name = "Decor" .. i
	p.Size = Vector3.new(math.max(d[5] * u, 0.02), math.max(d[6] * u, 0.02), math.max(d[7] * u, 0.02))
	p.Color = Color3.fromRGB(d[11], d[12], d[13])
	p.Material = if d[14] then Enum.Material[d[14]] else Enum.Material.SmoothPlastic
	if d[14] == "Glass" then
		p.Transparency = 0.35
	end
	smooth(p)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	if d[1] == "ell" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif d[1] == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	local offset = CFrame.new(d[2] * u, d[3] * u, d[4] * u) * CFrame.Angles(d[8], d[9], d[10])
	p.CFrame = shell.CFrame * offset
	if loose then
		p.Anchored = true
	else
		-- a Weld (not a WeldConstraint) keeps its offset even though the shell is
		-- moved before it's parented to the world
		local weld = Instance.new("Weld")
		weld.Part0 = shell
		weld.Part1 = p
		weld.C0 = offset
		weld.Parent = p
	end
	p.Parent = shell
	return p
end

function EggLooks.Build(eggId: string, size: Vector3, opts): BasePart?
	local look = EggLooks.Get(eggId)
	if not look then
		return nil
	end
	opts = opts or {}
	local u = size.X / 2

	local shell = Instance.new("Part")
	shell.Name = "Egg"
	shell.Size = size
	shell.Color = rgb(look.Shell)
	shell.Material = Enum.Material[look.ShellMaterial or "SmoothPlastic"]
	smooth(shell)
	shell.CanCollide = false
	shell.CFrame = CFrame.new()
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = shell

	for i, d in look.Parts do
		decor(shell, u, d, i, opts.Loose == true)
	end

	if opts.Effects ~= false and look.Light then
		local l = look.Light
		local light = Instance.new("PointLight")
		light.Name = "EggGlow"
		light.Color = rgb(l.Color)
		light.Brightness = l.Brightness
		light.Range = l.Range * u
		light.Parent = shell
		if l.Pulse then
			TweenService:Create(light, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Brightness = l.Brightness * 0.4,
			}):Play()
		end
	end

	if opts.Effects ~= false and look.Sparkles then
		local s = look.Sparkles
		local fx = Instance.new("ParticleEmitter")
		fx.Name = "EggSparkles"
		fx.Color = ColorSequence.new(rgb(s.Color))
		fx.LightEmission = 1
		fx.Rate = s.Rate
		fx.Lifetime = NumberRange.new(s.Lifetime * 0.6, s.Lifetime)
		fx.Speed = NumberRange.new(s.Speed * 0.4, s.Speed)
		fx.SpreadAngle = Vector2.new(180, 180)
		fx.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, s.Size * u),
			NumberSequenceKeypoint.new(1, 0),
		})
		fx.Transparency = NumberSequence.new(0.1, 1)
		fx.Parent = shell
	end

	return shell
end

return EggLooks
