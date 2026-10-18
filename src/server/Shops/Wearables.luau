--!nonstrict
-- Puts your best Shoes on your feet and your best Coil on your back
-- (GearConfig), built from smooth Parts welded to the character so everyone
-- sees them. Works on R15 (LeftFoot / RightFoot, UpperTorso) and R6 (the
-- bottom of Left Leg / Right Leg, Torso). Also sets the player attributes the
-- rest of the game reads:
--   ShoeTier, ShoeSafeFall   (EggCarry adds SafeFall to the safe drop before a crack)
--   CoilTier, CoilMultiplier (JumpPower multiplies jump power by it)
-- Call Wearables.Refresh(player) after the profile loads, on every respawn and
-- after buying gear.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GearConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GearConfig"))
local PlayerData = require(script.Parent.Parent:WaitForChild("Player"):WaitForChild("PlayerData"))

local Wearables = {}

local FOLDER = "WornGear"

local function part(parent, name, size, color, cframe, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = cframe
	p.Parent = parent
	return p
end

local function weldAll(model, to)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = to
			weld.Part1 = p
			weld.Parent = p
		end
	end
end

-- One shoe around a foot. `bottom` is the CFrame of the middle of the foot's
-- sole (facing the way the character faces), w/d = foot width/length.
local function buildShoe(model, item, bottom: CFrame, w: number, d: number, side: number)
	local c = item.Colors
	local style = item.Style or {}
	local neon = if style.Glow then Enum.Material.Neon else nil
	local h = 0.55

	-- sole, a bit wider and longer than the foot
	part(model, "Sole", Vector3.new(w + 0.2, 0.2, d + 0.3), c.Sole, bottom * CFrame.new(0, 0.1, -0.05), neon)
	if style.Cloud then
		for i = -1, 1 do
			part(model, "Puff", Vector3.new(w + 0.35, 0.3, 0.45), c.Sole, bottom * CFrame.new(0, 0.12, i * (d / 3)))
		end
	end
	-- the shoe body and a rounded toe cap
	part(model, "Upper", Vector3.new(w + 0.12, h, d + 0.12), c.Main, bottom * CFrame.new(0, 0.2 + h / 2, 0.05))
	part(model, "Toe", Vector3.new(w + 0.14, h * 0.6, 0.35), c.Main:Lerp(Color3.new(1, 1, 1), 0.15), bottom * CFrame.new(0, 0.2 + h * 0.3, -d / 2 - 0.05))
	-- side stripe and laces
	part(model, "Stripe", Vector3.new(w + 0.16, 0.08, d * 0.75), c.Accent, bottom * CFrame.new(0, 0.2 + h * 0.45, 0))
	for i = 0, 2 do
		part(model, "Lace", Vector3.new(w * 0.6, 0.05, 0.07), c.Accent, bottom * CFrame.new(0, 0.2 + h + 0.02, -d * 0.25 + i * 0.2))
	end

	if style.Springs then
		for i = 0, 2 do
			part(model, "Spring", Vector3.new(w * 0.7, 0.07, 0.4), c.Sole, bottom * CFrame.new(0, -0.02 - i * 0.09, 0.1), Enum.Material.Metal)
		end
	end
	if style.Wings then
		-- little wings on the outer heel
		for i, len in { 0.75, 0.55 } do
			part(model, "Wing", Vector3.new(0.06, 0.16, len), c.Accent,
				bottom * CFrame.new(side * (w / 2 + 0.12), 0.35 + i * 0.16, d * 0.25) * CFrame.Angles(-0.5 - i * 0.15, side * 0.4, 0), neon)
		end
	end
	if style.Fins then
		part(model, "Fin", Vector3.new(0.08, 0.35, 0.35), c.Accent, bottom * CFrame.new(0, 0.45, d / 2 + 0.12) * CFrame.Angles(0.6, 0, 0), Enum.Material.Neon)
		part(model, "Flame", Vector3.new(0.25, 0.12, 0.25), Color3.fromRGB(255, 220, 90), bottom * CFrame.new(0, 0.12, d / 2 + 0.2), Enum.Material.Neon)
	end
	if style.Glow then
		for i = 0, 1 do
			part(model, "Star", Vector3.new(0.12, 0.12, 0.04), c.Accent,
				bottom * CFrame.new(side * (w / 2 + 0.07), 0.3 + i * 0.2, -0.2 + i * 0.35) * CFrame.Angles(0, side * math.pi / 2, 0.785), Enum.Material.Neon)
		end
	end
end

-- A spring standing on the lower back, like a backpack.
local function buildCoil(model, item, torso: BasePart)
	local c = item.Colors
	local style = item.Style or {}
	local neon = if style.Glow then Enum.Material.Neon else nil
	local back = torso.CFrame * CFrame.new(0, -torso.Size.Y * 0.05, torso.Size.Z / 2 + 0.38)
	local rings = 6
	local gap = 0.22
	local base = back * CFrame.new(0, -(rings - 1) * gap / 2 - 0.2, 0)
	part(model, "Base", Vector3.new(0.9, 0.12, 0.6), c.Accent, base)
	for i = 0, rings - 1 do
		-- each ring a thin flat cylinder, tilted a little like a real spring coil
		part(model, "Ring", Vector3.new(0.1, 0.72, 0.72), if i % 2 == 0 then c.Main else c.Main:Lerp(c.Accent, 0.35),
			base * CFrame.new(0, 0.2 + i * gap, 0) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(0.12 * (if i % 2 == 0 then 1 else -1), 0, 0),
			if i == rings - 1 then neon else nil).Shape = Enum.PartType.Cylinder
	end
	part(model, "Cap", Vector3.new(0.85, 0.14, 0.55), c.Accent, base * CFrame.new(0, 0.2 + rings * gap, 0), neon)
	-- straps over the shoulders
	for _, x in { -0.35, 0.35 } do
		part(model, "Strap", Vector3.new(0.12, torso.Size.Y * 0.8, 0.06), c.Accent, torso.CFrame * CFrame.new(x * torso.Size.X / 1.6, 0, torso.Size.Z / 2 + 0.03))
	end
end

local function feet(character)
	local list = {}
	for _, side in { { "Left", -1 }, { "Right", 1 } } do
		local foot = character:FindFirstChild(side[1] .. "Foot")
		if foot then
			local size = foot.Size
			table.insert(list, { foot, foot.CFrame * CFrame.new(0, -size.Y / 2, 0), size.X, size.Z, side[2] })
		else
			local leg = character:FindFirstChild(side[1] .. " Leg")
			if leg then
				local size = leg.Size
				table.insert(list, { leg, leg.CFrame * CFrame.new(0, -size.Y / 2, 0), size.X, size.Z, side[2] })
			end
		end
	end
	return list
end

-- Rebuilds what the character wears and the stat attributes.
function Wearables.Refresh(player: Player)
	local data = PlayerData.Get(player)
	local owned = data and data.Gear or {}
	local shoeTier = GearConfig.BestTier(owned, "Shoes")
	local coilTier = GearConfig.BestTier(owned, "Coil")
	local shoe = GearConfig.Get("Shoes", shoeTier)
	local coil = GearConfig.Get("Coil", coilTier)
	player:SetAttribute("ShoeTier", shoeTier)
	player:SetAttribute("ShoeSafeFall", if shoe then shoe.SafeFall else 0)
	player:SetAttribute("CoilTier", coilTier)
	player:SetAttribute("CoilMultiplier", if coil then coil.JumpMultiplier else 1)

	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild(FOLDER)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER

	if shoe then
		for _, f in feet(character) do
			local model = Instance.new("Model")
			model.Name = "Shoe"
			buildShoe(model, shoe, f[2], f[3], f[4], f[5])
			weldAll(model, f[1])
			model.Parent = folder
		end
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if coil and torso then
		local model = Instance.new("Model")
		model.Name = "Coil"
		buildCoil(model, coil, torso)
		weldAll(model, torso)
		model.Parent = folder
	end
	folder.Parent = character
end

local function onCharacter(player, character)
	-- wait for the body (and the avatar's own shoes / accessories) to load
	character:WaitForChild("HumanoidRootPart", 10)
	for _ = 1, 60 do
		if player:HasAppearanceLoaded() then
			break
		end
		task.wait(0.1)
	end
	if player.Character == character then
		Wearables.Refresh(player)
	end
end

function Wearables.Start()
	local function watch(player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
end

return Wearables
