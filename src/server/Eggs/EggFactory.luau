--!nonstrict
-- Builds egg data and the egg parts players see.
--
-- Egg data is a plain table that moves between the world, a carrier and a pen:
--   { Uid, EggId, Kg, Cracks, ReadyAt? }

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggConfig = require(ReplicatedStorage.Shared.EggConfig)

local S = EggConfig.Settings
local CRACKED_TINT = Color3.fromRGB(70, 50, 35)

local EggFactory = {}

local rng = Random.new()

function EggFactory.NewData(eggId, kg)
	return {
		Uid = HttpService:GenerateGUID(false),
		EggId = eggId,
		Kg = kg,
		Cracks = 0,
	}
end

-- Random size in kg. Squaring the roll makes heavy eggs rarer.
function EggFactory.RollKg(egg)
	local roll = rng:NextNumber()
	local kg = egg.KgMin + (egg.KgMax - egg.KgMin) * roll * roll
	return math.floor(kg * 10 + 0.5) / 10
end

function EggFactory.SizeFor(data)
	return S.EggBaseSize * (1 + data.Kg * S.EggSizePerKg)
end

-- Info table sent to clients with egg events.
function EggFactory.Info(data)
	local egg = EggConfig.Eggs[data.EggId]
	return {
		EggId = data.EggId,
		Name = egg and egg.DisplayName or data.EggId,
		Kg = data.Kg,
		Cracks = data.Cracks,
		MaxCracks = S.MaxCracks,
	}
end

local function labelText(egg, data)
	local text = string.format("<b>%s</b>\n%.1f kg", egg.DisplayName, data.Kg)
	if data.Cracks > 0 then
		text ..= string.format('\n<font color="#ff6b6b">Cracks %d/%d</font>', data.Cracks, S.MaxCracks)
	end
	return text
end

function EggFactory.Build(data)
	local egg = EggConfig.Eggs[data.EggId]

	local part = Instance.new("Part")
	part.Name = "Egg"
	part.Size = EggFactory.SizeFor(data)
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part:SetAttribute("EggUid", data.Uid)
	part:SetAttribute("EggId", data.EggId)
	part:SetAttribute("Kg", data.Kg)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part

	local gui = Instance.new("BillboardGui")
	gui.Name = "EggLabel"
	gui.Size = UDim2.fromOffset(170, 64)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 1.4, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.RichText = true
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui

	EggFactory.Refresh(part, data)
	return part
end

-- A big word that pops up over a spot and floats away ("CRACK!", "SMASH!").
function EggFactory.PopText(position, text, color)
	local anchor = Instance.new("Part")
	anchor.Name = "PopText"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 60)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.LuckiestGuy
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(30, 15, 20)
	label.TextStrokeTransparency = 0
	label.Rotation = rng:NextNumber(-12, 12)
	label.Parent = gui
	anchor.Parent = workspace
	task.spawn(function()
		local t = 0
		while t < 1.1 do
			t += task.wait()
			gui.StudsOffset = Vector3.new(0, t * 3, 0)
			local fade = math.clamp((t - 0.6) / 0.5, 0, 1)
			label.TextTransparency = fade
			label.TextStrokeTransparency = fade
		end
		anchor:Destroy()
	end)
end

-- Updates color and label after cracks change.
function EggFactory.Refresh(part, data)
	local egg = EggConfig.Eggs[data.EggId]
	local damage = math.min(data.Cracks / S.MaxCracks, 1)
	part.Color = egg.Color:Lerp(CRACKED_TINT, damage * 0.6)
	part:SetAttribute("Cracks", data.Cracks)
	local gui = part:FindFirstChild("EggLabel")
	if gui then
		gui.Text.Text = labelText(egg, data)
	end
end

-- Shell bits flying out when an egg breaks (count = how many, default 8;
-- a few for a crack).
function EggFactory.BreakEffect(position, color, count)
	for _ = 1, count or 8 do
		local bit = Instance.new("Part")
		bit.Name = "EggShell"
		bit.Size = Vector3.new(0.5, 0.15, 0.5) * rng:NextNumber(0.7, 1.4)
		bit.Color = color
		bit.Material = Enum.Material.SmoothPlastic
		bit.CanCollide = false
		bit.CanQuery = false
		bit.CanTouch = false
		bit.CFrame = CFrame.new(position) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0)
		bit.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-12, 12), rng:NextNumber(15, 28), rng:NextNumber(-12, 12))
		bit.Parent = workspace
		Debris:AddItem(bit, 1.5)
	end
end

return EggFactory
