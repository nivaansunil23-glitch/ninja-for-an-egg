--!nonstrict
-- Draws every plot's pen pets: the owner's equipped pets (server: Eggs/PenService
-- writes them to the plot's PenPets attribute) wander around on the pen floor
-- and stop now and then, with how much money they make per second above their
-- head. A freshly hatched pet hops out where its egg was (LastHatch).
-- Runs on each client because the pets are only for looks; the server does the money.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Animals = require(Shared:WaitForChild("Animals"))
local EggConfig = require(Shared:WaitForChild("EggConfig"))
local Format = require(Shared:WaitForChild("Format"))

local EDGE = 3.5 -- studs pets keep from the fence
local IDLE_MIN, IDLE_MAX = 1.5, 5
local WALK_SPEED = 5
local NEAR, FAR = 140, 320 -- full-rate animation inside NEAR, frozen beyond FAR

local folder = Instance.new("Folder")
folder.Name = "PenPets"
folder.Parent = workspace

local pens = {} -- [plotModel] = { Floor, Pets = { [id] = pet } }
local rng = Random.new()

local function lerp(a, b, f)
	return a + (b - a) * f
end

local function angLerp(a, b, f)
	return a + math.atan2(math.sin(b - a), math.cos(b - a)) * f
end

-- A glowing ball standing in for old pets that have no animal model.
local function ballRig(info, height)
	local ball = Instance.new("Part")
	ball.Name = info.Name
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * height * 0.6
	ball.Material = Enum.Material.Neon
	ball.Color = EggConfig.RarityColors[info.Rarity] or Color3.new(1, 1, 1)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	local model = Instance.new("Model")
	model.Name = info.Name
	ball.Parent = model
	model.PrimaryPart = ball
	model.Parent = folder
	local rig = { Model = model, t = 0 }
	function rig:Step(dt, _, speed, pos)
		self.t += dt
		local bob = math.abs(math.sin(self.t * 8)) * 0.4 * math.min(speed, 1)
		ball.CFrame = CFrame.new(pos + Vector3.new(0, ball.Size.Y / 2 + bob, 0))
	end
	function rig:Destroy()
		model:Destroy()
	end
	return rig
end

local function makeLabel(pet, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Income"
	gui.Size = UDim2.fromOffset(150, 44)
	gui.StudsOffset = Vector3.new(0, height + 1.2, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Adornee = pet.Rig.Model.PrimaryPart
	gui.Parent = pet.Rig.Model.PrimaryPart

	local money = Instance.new("TextLabel")
	money.Name = "Money"
	money.Size = UDim2.fromScale(1, 0.62)
	money.BackgroundTransparency = 1
	money.TextScaled = true
	money.Font = Enum.Font.LuckiestGuy
	money.TextColor3 = Color3.fromRGB(120, 255, 120)
	money.TextStrokeColor3 = Color3.fromRGB(20, 40, 20)
	money.TextStrokeTransparency = 0
	money.Parent = gui

	local name = Instance.new("TextLabel")
	name.Name = "PetName"
	name.Size = UDim2.fromScale(1, 0.38)
	name.Position = UDim2.fromScale(0, 0.62)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.Font = Enum.Font.FredokaOne
	name.TextColor3 = EggConfig.RarityColors[pet.Info.Rarity] or Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.2
	name.Text = pet.Info.Name
	name.Parent = gui
	pet.MoneyLabel = money
end

local function setIncome(pet)
	pet.MoneyLabel.Text = Format.Money(pet.Info.Income or 0) .. "/s"
end

-- Big pets keep further from the fence so they don't poke through it.
local function randomSpot(pen, height: number?)
	local half = pen.Floor.Size / 2
	local edge = math.min(EDGE + (height or 0) * 0.35, half.X - 1, half.Z - 1)
	return Vector2.new(
		rng:NextNumber(-half.X + edge, half.X - edge),
		rng:NextNumber(-half.Z + edge, half.Z - edge)
	)
end

local function worldAt(pen, spot: Vector2): Vector3
	return (pen.Floor.CFrame * CFrame.new(spot.X, pen.Floor.Size.Y / 2, spot.Y)).Position
end

local function addPet(pen, info, hatchSpot: Vector2?)
	-- island animals: the higher their island, the bigger (EggConfig.PenPetHeight)
	local height = EggConfig.PenPetHeight(info.Name) or math.clamp(2.5 + (info.Weight or 1) * 0.1, 2.5, 6)
	local spec = Animals.GetSpec(info.Name)
	local rig = if spec
		then Animals.Build(info.Name, { Parent = folder, Scale = height / (spec.Scale or 3) })
		else ballRig(info, height)
	local pet = {
		Info = info,
		Rig = rig,
		Spot = hatchSpot or randomSpot(pen, height),
		Height = height,
		Heading = rng:NextNumber(0, math.pi * 2),
		Speed = 0,
		Mode = "idle",
		Timer = rng:NextNumber(0, IDLE_MAX),
		Hop = if hatchSpot then 0 else nil, -- seconds into the hatch hop
		Acc = 0,
		Slot = rng:NextInteger(0, 3),
	}
	makeLabel(pet, height)
	setIncome(pet)
	rig:Step(0, "idle", 0, worldAt(pen, pet.Spot), pet.Heading)
	pen.Pets[info.Id] = pet
end

local function sync(plotModel)
	local pen = pens[plotModel]
	if not pen then
		return
	end
	local ok, list = pcall(HttpService.JSONDecode, HttpService, plotModel:GetAttribute("PenPets") or "[]")
	if not ok or type(list) ~= "table" then
		list = {}
	end
	local hatch = nil
	local okHatch, last = pcall(HttpService.JSONDecode, HttpService, plotModel:GetAttribute("LastHatch") or "null")
	if okHatch and type(last) == "table" then
		hatch = last
	end

	local keep = {}
	for _, info in list do
		if type(info) == "table" and info.Id then
			keep[info.Id] = true
			local pet = pen.Pets[info.Id]
			if pet then
				if pet.Info.Income ~= info.Income then
					pet.Info = info
					setIncome(pet)
				end
			else
				local spot = if hatch and hatch.Id == info.Id then Vector2.new(hatch.X, hatch.Z) else nil
				addPet(pen, info, spot)
			end
		end
	end
	for id, pet in pen.Pets do
		if not keep[id] then
			pet.Rig:Destroy()
			pen.Pets[id] = nil
		end
	end
end

local function watchPlot(plotModel)
	if pens[plotModel] or not plotModel:IsA("Model") then
		return
	end
	local penModel = plotModel:WaitForChild("Pen", 10)
	local floor = penModel and penModel:WaitForChild("Floor", 10)
	if not floor then
		return
	end
	pens[plotModel] = { Floor = floor, Pets = {} }
	plotModel:GetAttributeChangedSignal("PenPets"):Connect(function()
		sync(plotModel)
	end)
	sync(plotModel)
end

local function update(pen, pet, dt)
	local walkSpeed = WALK_SPEED * math.sqrt(math.max(pet.Height or 3, 3) / 3) -- big pets take bigger steps
	local hopY = 0
	if pet.Hop then
		-- just hatched: a big hop with a spin where the egg was
		pet.Hop += dt
		local a = pet.Hop / 0.7
		if a >= 1 then
			pet.Hop = nil
		else
			hopY = math.sin(a * math.pi) * 3
			pet.Heading += dt * math.pi * 2 / 0.7
		end
	end

	if pet.Mode == "idle" then
		pet.Timer -= dt
		if pet.Timer <= 0 and not pet.Hop then
			pet.Target = randomSpot(pen, pet.Height)
			pet.Mode = "walk"
		end
	end
	local want = 0
	if pet.Mode == "walk" then
		local to = pet.Target - pet.Spot
		if to.Magnitude < 0.6 then
			pet.Mode = "idle"
			pet.Timer = rng:NextNumber(IDLE_MIN, IDLE_MAX)
		else
			-- heading in world space from the floor-space direction
			local worldDir = pen.Floor.CFrame:VectorToWorldSpace(Vector3.new(to.X, 0, to.Y))
			pet.Heading = angLerp(pet.Heading, math.atan2(worldDir.X, worldDir.Z), 1 - math.exp(-4 * dt))
			want = walkSpeed
		end
	end
	pet.Speed = lerp(pet.Speed, want, 1 - math.exp(-5 * dt))
	if pet.Speed > 0.01 and pet.Target then
		local dir = (pet.Target - pet.Spot)
		if dir.Magnitude > 0 then
			pet.Spot += dir.Unit * math.min(pet.Speed * dt, dir.Magnitude)
		end
	end
	local pos = worldAt(pen, pet.Spot) + Vector3.new(0, hopY, 0)
	pet.Rig:Step(dt, if pet.Mode == "walk" or pet.Hop then "walk" else "idle", if pet.Hop then 6 else pet.Speed, pos, pet.Heading)
end

local frame = 0
RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.1)
	frame += 1
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for _, pen in pens do
		local d = (pen.Floor.Position - camPos).Magnitude
		for _, pet in pen.Pets do
			pet.Acc += dt
			if d < NEAR or (d < FAR and frame % 4 == pet.Slot) then
				update(pen, pet, math.min(pet.Acc, 0.2))
				pet.Acc = 0
			end
		end
	end
end)

task.spawn(function()
	local map = workspace:WaitForChild("Map")
	local pensFolder = map:WaitForChild("Pens")
	for _, plotModel in pensFolder:GetChildren() do
		task.spawn(watchPlot, plotModel)
	end
	pensFolder.ChildAdded:Connect(watchPlot)
end)
