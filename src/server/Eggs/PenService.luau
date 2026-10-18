--!nonstrict
-- Pens: every player automatically claims a free plot from Workspace.Map.Pens
-- when they join, and frees it when they leave. Each plot has one big pen with
-- several "Nest" parts; every Nest holds one egg. Bring a carried egg to one of
-- your nests to place it, wait out the grow countdown, then hatch it into a pet.
--
-- Plot setup (done in the map):
--   Workspace.Map.Pens.<PlotName>       one Model per player plot (PlotId attribute sorts them)
--     ...Nest (BasePart)                one per egg slot, any depth inside the plot.
--                                       Optional "NestIndex" attribute keeps saves stable.
--       EggSpot (optional sibling or child) where the egg's bottom sits
--     ...Sign (BasePart)                its SurfaceGui text shows the owner's name
--                                       ("Empty Plot" when free); no text = billboard
--
--     ...UpgradeSign (with a "Board" part) gets an "Upgrade Pen" prompt and its
--                                       SurfaceGui text shows the next level and price
--
-- Pen upgrades (EggConfig.PenLevels): each level raises the owner's cash
-- multiplier (player attribute CashMultiplier). All nests are always open.
-- Saved as data.Eggs.PenLevel.
--
-- Set on the plot: OwnerUserId (0 when free), OwnerName, PenLevel attributes.
-- Set on the Player: PlotName, PenLevel, CashMultiplier attributes.
-- Players spawn (and respawn) at their plot's PlotSpawn marker.
-- Growing eggs are saved in PlayerData (data.Eggs.Pens) with a real-time
-- ReadyAt, so they keep growing while the player is offline.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggConfig = require(ReplicatedStorage.Shared.EggConfig)
local EggRemotes = require(ReplicatedStorage.Shared.EggRemotes)
local Format = require(ReplicatedStorage.Shared.Format)
local EggCarry = require(script.Parent.EggCarry)
local EggFactory = require(script.Parent.EggFactory)
local EggMap = require(script.Parent.EggMap)
local EggSave = require(script.Parent.EggSave)
local Hatching = require(script.Parent.Hatching)

local S = EggConfig.Settings

local PenService = {}

local plots = {} -- [Model] = { Model, Owner, Nests = { nest } }
local playerPlot = {} -- [Player] = plot state
local pensFolder = nil

-- nest = { Key, Part, Prompt, Egg, Visual, Timer }

local function notify(player, kind, info)
	EggRemotes.EggNotify:FireClient(player, kind, info)
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d = seconds // 86400
	local h = (seconds % 86400) // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	end
	return string.format("%ds", s)
end

local function nestPath(plotModel, nestPart)
	return string.sub(nestPart:GetFullName(), #plotModel:GetFullName() + 2)
end

-- Several nests in one big pen can share the name "Nest", so keys come from a
-- NestIndex attribute when there is one, otherwise the path plus a number
-- counted in a fixed order (left to right, front to back) inside the plot.
local function findNests(plotModel)
	local nests = {}
	for _, d in plotModel:GetDescendants() do
		-- "NestSpot" = an empty slot (invisible marker) that gets a nest when the pen is upgraded.
		if d:IsA("BasePart") and (d.Name == "Nest" or d.Name == "NestSpot") then
			table.insert(nests, { Path = nestPath(plotModel, d), Part = d, IsSpot = d.Name == "NestSpot" })
		end
	end
	local pivot = plotModel:GetPivot()
	for _, nest in nests do
		nest.Local = pivot:PointToObjectSpace(nest.Part.Position)
	end
	table.sort(nests, function(a, b)
		if a.Path ~= b.Path then
			return a.Path < b.Path
		end
		if math.abs(a.Local.X - b.Local.X) > 0.5 then
			return a.Local.X < b.Local.X
		end
		return a.Local.Z < b.Local.Z
	end)
	local seen = {}
	for order, nest in nests do
		local index = nest.Part:GetAttribute("NestIndex")
		if type(index) == "number" then
			nest.Key = "Nest" .. tostring(index)
			nest.Index = index
		else
			seen[nest.Path] = (seen[nest.Path] or 0) + 1
			nest.Key = nest.Path .. "#" .. seen[nest.Path]
			nest.Index = order
		end
		nest.Local = nil
	end
	-- Nests unlock in NestIndex order as the pen is upgraded.
	table.sort(nests, function(a, b)
		return a.Index < b.Index
	end)
	return nests
end

-- Where the egg's bottom sits: an EggSpot next to or inside the nest, else the nest top.
local function eggBase(nest)
	local base = nest.Shell or nest.Part
	local spot = nest.Part:FindFirstChild("EggSpot")
		or (nest.Part.Parent and nest.Part.Parent:FindFirstChild("EggSpot"))
	if spot and spot:IsA("BasePart") then
		-- Only trust a sibling spot when it's actually above this nest.
		local offset = spot.Position - base.Position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude < math.max(base.Size.X, base.Size.Z, 4) then
			return CFrame.new(spot.Position) * base.CFrame.Rotation
		end
	end
	return base.CFrame * CFrame.new(0, base.Size.Y / 2, 0)
end

-- Unlocked NestSpots get a copy of one of the pen's real nests; locked ones lose it.
local function setShell(plot, nest)
	if not nest.IsSpot then
		return
	end
	if not nest.Unlocked then
		if nest.Shell then
			nest.Shell:Destroy()
			nest.Shell = nil
		end
		return
	end
	if nest.Shell and nest.Shell.Parent then
		return
	end
	local template
	for _, other in plot.Nests do
		if not other.IsSpot then
			template = other.Part
			break
		end
	end
	if not template then
		return
	end
	local shell = template:Clone()
	shell:ClearAllChildren()
	for name in shell:GetAttributes() do
		shell:SetAttribute(name, nil)
	end
	shell.Name = "UpgradedNest"
	shell.Anchored = true
	local spot = nest.Part
	shell.CFrame = spot.CFrame * CFrame.new(0, -spot.Size.Y / 2 + template.Size.Y / 2, 0)
	shell.Parent = spot.Parent
	nest.Shell = shell
end

-- Slot models carry an Unlocked attribute the map (and UI) can read.
local function setSlotUnlocked(nest, unlocked)
	local slot = nest.Part.Parent
	if slot and slot:GetAttribute("SlotIndex") ~= nil then
		slot:SetAttribute("Unlocked", unlocked)
	end
end

local function addPlot(plotModel)
	if plots[plotModel] or not plotModel:IsA("Model") then
		return
	end
	plots[plotModel] = { Model = plotModel, Owner = nil, Nests = findNests(plotModel) }
end

local function clearVisual(nest)
	if nest.Visual then
		nest.Visual:Destroy()
		nest.Visual = nil
		nest.Timer = nil
	end
end

-- Glowing, steaming egg sitting on the nest with a countdown above it.
local function showVisual(nest)
	clearVisual(nest)
	local data = nest.Egg
	local part = EggFactory.Build(data)
	part.Anchored = true
	part.CFrame = eggBase(nest) * CFrame.new(0, part.Size.Y / 2, 0)
	part:SetAttribute("State", "Pen")
	part:SetAttribute("ReadyAt", data.ReadyAt)

	local light = Instance.new("PointLight")
	light.Brightness = 1.5
	light.Range = 10
	light.Color = Color3.new(1, 1, 1)
	light.Parent = part

	local steam = Instance.new("Smoke")
	steam.Color = Color3.new(1, 1, 1)
	steam.Opacity = 0.08
	steam.RiseVelocity = 2
	steam.Size = 1
	steam.Parent = part

	local gui = Instance.new("BillboardGui")
	gui.Name = "Timer"
	gui.Size = UDim2.fromOffset(160, 36)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 3.2, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 255, 140)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui

	part.Parent = nest.Part
	nest.Visual = part
	nest.Timer = label
end

-- "Locked" label over nests the pen level hasn't unlocked yet.
local function setLockLabel(nest, text)
	local old = nest.Part:FindFirstChild("LockLabel")
	if not text then
		if old then
			old:Destroy()
		end
		return
	end
	if old then
		old.Text.Text = text
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "LockLabel"
	gui.Size = UDim2.fromOffset(150, 34)
	gui.StudsOffset = Vector3.new(0, nest.Part.Size.Y / 2 + 2.5, 0)
	gui.MaxDistance = 60
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 210, 120)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	gui.Parent = nest.Part
end

local function refreshNest(nest)
	local prompt = nest.Prompt
	if not prompt then
		return
	end
	if not nest.Egg then
		if nest.Unlocked then
			setLockLabel(nest, nil)
			prompt.ActionText = "Place Egg"
			prompt.ObjectText = "Empty Nest"
			prompt.Enabled = true
		else
			-- Nests unlock in order, so this one comes with the next level that has enough nests.
			setLockLabel(nest, "🔒 Upgrade pen")
			prompt.Enabled = false
		end
		return
	end
	setLockLabel(nest, nil)
	local left = nest.Egg.ReadyAt - os.time()
	if nest.Timer then
		nest.Timer.Text = left > 0 and ("Egg " .. formatTime(left)) or "Ready to hatch!"
	end
	if left > 0 then
		prompt.Enabled = false
	else
		prompt.ActionText = "Hatch"
		prompt.ObjectText = EggConfig.Eggs[nest.Egg.EggId].DisplayName
		prompt.Enabled = true
	end
end

local function nearNest(player, nest)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - nest.Part.Position).Magnitude <= S.PenPromptDistance + 6
end

-- A placeholder pet (glowing ball in its rarity color) until pet models exist.
local function showPet(nest, pet)
	local ball = Instance.new("Part")
	ball.Name = "HatchedPet"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * math.clamp(2 + pet.Weight * 0.15, 2, 8)
	ball.Material = Enum.Material.Neon
	ball.Color = EggConfig.RarityColors[pet.Rarity] or Color3.new(1, 1, 1)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CFrame = eggBase(nest) * CFrame.new(0, ball.Size.Y / 2 + 1, 0)

	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = ball.Color
	sparkles.Parent = ball

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, ball.Size.Y / 2 + 1.5, 0)
	gui.LightInfluence = 0
	gui.Parent = ball
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.RichText = true
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = ball.Color
	label.TextStrokeTransparency = 0.2
	label.Text = string.format("<b>%s</b>\n%s · %.2f kg", pet.Name, pet.Rarity, pet.Weight)
	label.Parent = gui

	ball.Parent = nest.Part
	task.delay(S.PetShowSeconds, function()
		ball:Destroy()
	end)
end

local function placeEgg(player, plot, nest)
	if nest.Egg or not nearNest(player, nest) then
		return
	end
	if not EggCarry.IsCarrying(player) then
		notify(player, "Info", { Text = "Bring an egg here to grow it." })
		return
	end
	if not nest.Unlocked then
		notify(player, "Info", { Text = "Upgrade your pen to use this nest." })
		return
	end
	local data = EggSave.WaitForData(player)
	if not data or plot.Owner ~= player or nest.Egg then
		return
	end
	local egg = EggCarry.TakeCarried(player)
	if not egg then
		return
	end
	local def = EggConfig.Eggs[egg.EggId]
	egg.ReadyAt = os.time() + math.floor(def.GrowSeconds + def.GrowSecondsPerKg * egg.Kg)
	nest.Egg = egg
	data.Eggs.Pens[nest.Key] = egg
	EggSave.MarkDirty(player)
	showVisual(nest)
	refreshNest(nest)
	local info = EggFactory.Info(egg)
	info.ReadyAt = egg.ReadyAt
	notify(player, "EggPlaced", info)
end

local function hatchEgg(player, plot, nest)
	local egg = nest.Egg
	if not egg or os.time() < egg.ReadyAt or not nearNest(player, nest) then
		return
	end
	local data = EggSave.WaitForData(player)
	if not data or plot.Owner ~= player or nest.Egg ~= egg then
		return
	end
	-- Clear the pen before anything else so it can't hatch twice.
	nest.Egg = nil
	data.Eggs.Pens[nest.Key] = nil
	clearVisual(nest)
	refreshNest(nest)

	local pet = Hatching.Roll(egg)
	pet.Id = EggSave.AddPet(player, pet)
	EggSave.MarkDirty(player)
	showPet(nest, pet)
	notify(player, "Hatched", { Pet = pet, EggId = egg.EggId, Name = EggConfig.Eggs[egg.EggId].DisplayName })
end

local function makePrompt(player, plot, nest)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PenPrompt"
	prompt.MaxActivationDistance = S.PenPromptDistance
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	-- The client script hides this prompt for everyone but the owner.
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt.Triggered:Connect(function(who)
		if who ~= plot.Owner then
			return
		end
		if nest.Egg then
			hatchEgg(who, plot, nest)
		else
			placeEgg(who, plot, nest)
		end
	end)
	prompt.Parent = nest.Part
	nest.Prompt = prompt
end

local EMPTY_SIGN_TEXT = "Empty Plot"

-- Writes the owner's name on the plot sign (nil = free plot). Uses the sign's
-- own SurfaceGui text if it has one, otherwise floats a label above it.
local function setSign(plot, text)
	local sign = plot.Model:FindFirstChild("Sign", true)
	if sign and not sign:IsA("BasePart") then
		sign = sign:FindFirstChildWhichIsA("BasePart", true)
	end
	sign = sign or plot.Model.PrimaryPart
	if not sign then
		return
	end

	local surfaceText = nil
	for _, d in sign:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextBox")) and d:FindFirstAncestorWhichIsA("SurfaceGui") then
			surfaceText = d
			break
		end
	end
	if surfaceText then
		surfaceText.Text = text or EMPTY_SIGN_TEXT
		return
	end

	local old = sign:FindFirstChild("OwnerLabel")
	if old then
		old:Destroy()
	end
	if not text then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "OwnerLabel"
	gui.Size = UDim2.fromOffset(220, 40)
	gui.StudsOffset = Vector3.new(0, sign.Size.Y / 2 + 2, 0)
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
end

-- Pen upgrades ---------------------------------------------------------------

local function getPenLevel(data)
	local level = tonumber(data.Eggs.PenLevel) or 1
	return math.clamp(math.floor(level), 1, #EggConfig.PenLevels)
end

-- The next pen level and its info, or nil at max.
local function nextLevel(_plot, level)
	local nextInfo = EggConfig.PenLevels[level + 1]
	if nextInfo then
		return level + 1, nextInfo
	end
	return nil
end

local function formatMultiplier(value)
	local text = string.format("%.2f", value):gsub("%.?0+$", "")
	return "x" .. text
end

local function findUpgradeBoard(plot)
	local sign = plot.Model:FindFirstChild("UpgradeSign", true)
	if not sign then
		return nil
	end
	if sign:IsA("BasePart") then
		return sign
	end
	local board = sign:FindFirstChild("Board")
	if board and board:IsA("BasePart") then
		return board
	end
	return sign:FindFirstChildWhichIsA("BasePart", true)
end

local function setBoardText(board, text)
	for _, d in board:GetDescendants() do
		if d:IsA("TextLabel") and d:FindFirstAncestorWhichIsA("SurfaceGui") then
			d.Text = text
			return
		end
	end
end

-- Sets the owner's cash multiplier and updates the upgrade sign for the plot's level.
local function applyLevel(plot, level)
	plot.Level = level
	local multiplier = EggConfig.PenLevels[level].CashMultiplier
	for _, nest in plot.Nests do
		nest.Unlocked = true
		setShell(plot, nest)
		setSlotUnlocked(nest, nest.Unlocked)
		refreshNest(nest)
	end

	local pen = plot.Model:FindFirstChild("Pen")
	if pen then
		pen:SetAttribute("Level", level)
	end
	plot.Model:SetAttribute("PenLevel", level)
	if plot.Owner then
		plot.Owner:SetAttribute("PenLevel", level)
		plot.Owner:SetAttribute("CashMultiplier", multiplier)
	end

	local board = plot.UpgradeBoard
	if not board then
		return
	end
	local nextLvl, nextInfo = nextLevel(plot, level)
	local prompt = plot.UpgradePrompt
	if nextLvl then
		local price = Format.Money(nextInfo.Price)
		local nextMul = formatMultiplier(nextInfo.CashMultiplier)
		setBoardText(board, string.format("Upgrade Pen\n%s > %s Cash\n%s", formatMultiplier(multiplier), nextMul, price))
		if prompt then
			prompt.ActionText = "Upgrade Pen"
			prompt.ObjectText = string.format("Lv %d > %d · %s cash · %s", level, nextLvl, nextMul, price)
			prompt.Enabled = true
		end
	else
		setBoardText(board, string.format("Pen Level %d\n%s Cash\nMAX", level, formatMultiplier(multiplier)))
		if prompt then
			prompt.Enabled = false
		end
	end
end

local function buyUpgrade(player, plot)
	if plot.Owner ~= player then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not plot.UpgradeBoard or (root.Position - plot.UpgradeBoard.Position).Magnitude > S.PenPromptDistance + 8 then
		return
	end
	local data = EggSave.WaitForData(player)
	if not data or plot.Owner ~= player then
		return
	end
	local level = getPenLevel(data)
	local nextLvl, nextInfo = nextLevel(plot, level)
	if not nextLvl then
		notify(player, "Info", { Text = "Your pen is already max level." })
		return
	end
	if not EggSave.SpendMoney(player, nextInfo.Price) then
		notify(player, "Info", { Text = `You need {Format.Money(nextInfo.Price)} to upgrade your pen.` })
		return
	end
	data.Eggs.PenLevel = nextLvl
	EggSave.MarkDirty(player)
	applyLevel(plot, nextLvl)
	notify(player, "PenUpgraded", { Level = nextLvl, Multiplier = nextInfo.CashMultiplier })
end

local function setupUpgradeSign(player, plot)
	local board = findUpgradeBoard(plot)
	plot.UpgradeBoard = board
	if not board then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.MaxActivationDistance = S.PenPromptDistance
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt.Triggered:Connect(function(who)
		buyUpgrade(who, plot)
	end)
	prompt.Parent = board
	plot.UpgradePrompt = prompt
end

local function clearUpgradeSign(plot)
	if plot.UpgradePrompt then
		plot.UpgradePrompt:Destroy()
		plot.UpgradePrompt = nil
	end
	if plot.UpgradeBoard then
		setBoardText(plot.UpgradeBoard, "Upgrade Pen\nx1 Cash")
	end
	plot.UpgradeBoard = nil
end

-- Put the player at their plot's entrance (PlotSpawn marker), facing the pen.
local function sendToPlot(player, plot)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local marker = plot.Model:FindFirstChild("PlotSpawn", true)
	if not root or not marker or not marker:IsA("BasePart") or playerPlot[player] ~= plot then
		return
	end
	local pen = plot.Model:FindFirstChild("Pen")
	local spot = marker.Position + Vector3.new(0, 4, 0)
	local look = if pen then pen:GetPivot().Position else spot + marker.CFrame.LookVector
	look = Vector3.new(look.X, spot.Y, look.Z)
	character:PivotTo(if (look - spot).Magnitude > 0.1 then CFrame.lookAt(spot, look) else CFrame.new(spot))
end

local function assignPlot(player)
	local data = EggSave.WaitForData(player)
	if not data or not player.Parent or playerPlot[player] then
		return
	end

	local free = {}
	for _, plot in plots do
		if not plot.Owner then
			table.insert(free, plot)
		end
	end
	table.sort(free, function(a, b)
		local ia = a.Model:GetAttribute("PlotId")
		local ib = b.Model:GetAttribute("PlotId")
		if type(ia) == "number" and type(ib) == "number" and ia ~= ib then
			return ia < ib
		end
		return a.Model.Name < b.Model.Name
	end)
	local plot = free[1]
	if not plot then
		warn(`[Eggs] No free pen plot for {player.Name}.`)
		notify(player, "Info", { Text = "No free pen right now. Your eggs are safe." })
		return
	end

	-- Re-read the nests in case the map changed since the server started.
	plot.Nests = findNests(plot.Model)
	plot.Owner = player
	playerPlot[player] = plot
	plot.Model:SetAttribute("OwnerUserId", player.UserId)
	plot.Model:SetAttribute("OwnerName", player.DisplayName)
	player:SetAttribute("PlotName", plot.Model.Name)
	setSign(plot, player.DisplayName .. "'s Pen")
	notify(player, "Info", { Text = `You claimed {plot.Model.Name}! Bring eggs to your pen.` })
	if #plot.Nests == 0 then
		warn(`[Eggs] {plot.Model:GetFullName()} has no parts named "Nest", so eggs can't be placed there.`)
	end

	-- Put saved eggs back in their nests. Eggs whose nest no longer exists
	-- (map changed) move to any empty nest; if none, they stay saved.
	local saved = data.Eggs.Pens
	local homeless = {}
	local byKey = {}
	for _, nest in plot.Nests do
		byKey[nest.Key] = nest
	end
	for key, egg in saved do
		local nest = byKey[key]
		if nest then
			nest.Egg = egg
		elseif EggConfig.Eggs[egg.EggId] then
			table.insert(homeless, key)
		end
	end
	for _, key in homeless do
		for _, nest in plot.Nests do
			if not nest.Egg then
				nest.Egg = saved[key]
				saved[nest.Key] = saved[key]
				saved[key] = nil
				break
			end
		end
	end

	for _, nest in plot.Nests do
		makePrompt(player, plot, nest)
		if nest.Egg then
			showVisual(nest)
		end
	end
	setupUpgradeSign(player, plot)
	applyLevel(plot, getPenLevel(data))

	-- Start (and respawn) at your own pen.
	plot.SpawnConnection = player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		sendToPlot(player, plot)
	end)
	sendToPlot(player, plot)
end

local function releasePlot(player)
	local plot = playerPlot[player]
	if not plot then
		return
	end
	playerPlot[player] = nil
	plot.Owner = nil
	if plot.SpawnConnection then
		plot.SpawnConnection:Disconnect()
		plot.SpawnConnection = nil
	end
	plot.Model:SetAttribute("OwnerUserId", 0)
	plot.Model:SetAttribute("OwnerName", nil)
	plot.Model:SetAttribute("PenLevel", nil)
	player:SetAttribute("CashMultiplier", nil)
	local pen = plot.Model:FindFirstChild("Pen")
	if pen then
		pen:SetAttribute("Level", 1)
	end
	setSign(plot, nil)
	clearUpgradeSign(plot)
	for _, nest in plot.Nests do
		clearVisual(nest)
		setLockLabel(nest, nil)
		if nest.Prompt then
			nest.Prompt:Destroy()
			nest.Prompt = nil
		end
		nest.Egg = nil
		nest.Unlocked = false
		setShell(plot, nest)
		setSlotUnlocked(nest, not nest.IsSpot)
	end
end

-- The plot a player owns, or nil.
-- Sends the player to their plot's entrance. Returns false if they have no plot.
function PenService.SendHome(player)
	local plot = playerPlot[player]
	if not plot then
		return false
	end
	sendToPlot(player, plot)
	return true
end

function PenService.GetPlot(player)
	local plot = playerPlot[player]
	return plot and plot.Model
end

-- Seconds left on each of the player's pens, for a pen timer UI.
-- Returns { { Key, EggId, Name, ReadyAt, SecondsLeft } }
function PenService.GetPenEggs(player)
	local result = {}
	local plot = playerPlot[player]
	if not plot then
		return result
	end
	for _, nest in plot.Nests do
		if nest.Egg then
			table.insert(result, {
				Key = nest.Key,
				EggId = nest.Egg.EggId,
				Name = EggConfig.Eggs[nest.Egg.EggId].DisplayName,
				ReadyAt = nest.Egg.ReadyAt,
				SecondsLeft = math.max(0, nest.Egg.ReadyAt - os.time()),
			})
		end
	end
	return result
end

function PenService.Start()
	task.spawn(function()
		pensFolder = EggMap.WaitForFolder("Pens")
		for _, plotModel in pensFolder:GetChildren() do
			addPlot(plotModel)
		end
		pensFolder.ChildAdded:Connect(function(plotModel)
			addPlot(plotModel)
		end)

		for _, player in Players:GetPlayers() do
			task.spawn(assignPlot, player)
		end
		Players.PlayerAdded:Connect(assignPlot)
	end)

	Players.PlayerRemoving:Connect(function(player)
		releasePlot(player)
		EggSave.Forget(player)
	end)

	-- Countdown labels and "ready" prompts.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, plot in plots do
				if plot.Owner then
					for _, nest in plot.Nests do
						if nest.Egg then
							refreshNest(nest)
						end
					end
				end
			end
		end
	end)
end

return PenService
