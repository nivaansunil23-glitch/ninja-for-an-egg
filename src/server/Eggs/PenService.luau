--!nonstrict
-- Pens: every player automatically claims a free plot from Workspace.Map.Pens
-- when they join, and frees it when they leave. Each plot has one big fenced
-- pen. Walk inside your pen while carrying an egg and press Place Egg (the
-- Drop Egg button turns into it, G on PC) to set it down right where you
-- stand, wait out the grow countdown, then hold E on the egg to hatch it.
-- Your equipped pets (up to PlayerConfig.MaxEquippedPets) live in the pen and
-- earn money; the client draws them wandering (Client.World.PenPets) from the
-- plot's PenPets attribute, each with its $/s above its head, and the plot
-- sign shows the pen's total $/s.
--
-- Plot setup (done in the map):
--   Workspace.Map.Pens.<PlotName>       one Model per player plot (PlotId attribute sorts them)
--     Pen.Floor (BasePart)              the pen's floor; eggs go anywhere on it
--     ...Sign (BasePart)                its SurfaceGui text shows the owner's name and
--                                       $/s ("Empty Plot" when free); no text = billboard
--     ...UpgradeSign (with a "Board" part) gets an "Upgrade Pen" prompt and its
--                                       SurfaceGui text shows the next level and price
--
-- Pen upgrades (EggConfig.PenLevels): each level raises the owner's cash
-- multiplier (player attribute CashMultiplier). Saved as data.Eggs.PenLevel.
--
-- Set on the plot: OwnerUserId (0 when free), OwnerName, PenLevel,
--   PenPets (JSON list of { Id, Name, Rarity, Weight, Income }), PenIncome,
--   LastHatch (JSON { Id, X, Z }: where the newest pet hopped out, floor space).
-- Set on the Player: PlotName, PenLevel, CashMultiplier, InOwnPen attributes.
-- Players spawn (and respawn) at their plot's PlotSpawn marker.
-- Growing eggs are saved in PlayerData (data.Eggs.Pens[key]) with a real-time
-- ReadyAt and Spot = { X, Z } on the floor, so they keep growing offline.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggConfig = require(ReplicatedStorage.Shared.EggConfig)
local EggRemotes = require(ReplicatedStorage.Shared.EggRemotes)
local Format = require(ReplicatedStorage.Shared.Format)
local PlayerConfig = require(ReplicatedStorage.Shared.Config.PlayerConfig)
local SellConfig = require(ReplicatedStorage.Shared.Config.SellConfig)
local EggCarry = require(script.Parent.EggCarry)
local EggFactory = require(script.Parent.EggFactory)
local EggMap = require(script.Parent.EggMap)
local EggSave = require(script.Parent.EggSave)
local Hatching = require(script.Parent.Hatching)

local S = EggConfig.Settings
local MAX_EGGS = S.MaxPenEggs or 6
local EDGE = S.PenEdgeMargin or 3 -- studs eggs (and the player) must stay inside the fence
local EGG_GAP = S.PenEggSpacing or 4 -- studs between two eggs

local PenService = {}

local plots = {} -- [Model] = { Model, Owner, Floor, Eggs = { [key] = slot } }
local playerPlot = {} -- [Player] = plot state
local pensFolder = nil

-- slot = { Key, Egg, Visual, Prompt, Timer }

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

local function findFloor(plotModel)
	local pen = plotModel:FindFirstChild("Pen")
	local floor = pen and pen:FindFirstChild("Floor")
	if not (floor and floor:IsA("BasePart")) then
		floor = plotModel:FindFirstChild("Floor", true)
	end
	return if floor and floor:IsA("BasePart") then floor else nil
end

local function addPlot(plotModel)
	if plots[plotModel] or not plotModel:IsA("Model") then
		return
	end
	plots[plotModel] = { Model = plotModel, Owner = nil, Floor = findFloor(plotModel), Eggs = {} }
end

-- Floor-space X/Z of a world position, and whether it's inside the fence.
local function floorSpot(plot, position)
	local p = plot.Floor.CFrame:PointToObjectSpace(position)
	return Vector2.new(p.X, p.Z)
end

local function insideFloor(plot, spot, margin)
	local half = plot.Floor.Size / 2
	return math.abs(spot.X) <= half.X - margin and math.abs(spot.Y) <= half.Z - margin
end

-- Where an egg's bottom sits for a saved Spot.
local function spotCFrame(plot, spot)
	return plot.Floor.CFrame * CFrame.new(spot.X, plot.Floor.Size.Y / 2, spot.Z)
end

local function eggCount(plot)
	local n = 0
	for _ in plot.Eggs do
		n += 1
	end
	return n
end

-- A free spot for an old saved egg that has none (used to sit on a nest):
-- the first point of a grid over the floor that's clear of other eggs.
local function defaultSpot(plot)
	local half = plot.Floor.Size / 2
	for row = 0, 3 do
		for col = 0, 5 do
			local x = -half.X + EDGE + 2 + col * (half.X * 2 - 2 * EDGE - 4) / 5
			local z = -half.Z + EDGE + 2 + row * (half.Z * 2 - 2 * EDGE - 4) / 3
			local free = true
			for _, slot in plot.Eggs do
				local s = slot.Egg.Spot
				if s and (Vector2.new(s.X, s.Z) - Vector2.new(x, z)).Magnitude < EGG_GAP then
					free = false
					break
				end
			end
			if free then
				return { X = x, Z = z }
			end
		end
	end
	return { X = 0, Z = 0 }
end

local function clearVisual(slot)
	if slot.Visual then
		slot.Visual:Destroy()
	end
	slot.Visual, slot.Prompt, slot.Timer = nil, nil, nil
end

-- Pets ---------------------------------------------------------------------

local function equippedPets(data)
	local list = {}
	for id, pet in data.Pets do
		if pet.Equipped then
			table.insert(list, { id, pet })
		end
	end
	table.sort(list, function(a, b)
		return a[1] < b[1]
	end)
	return list
end

-- Writes the owner's name and pen income on the plot sign (nil = free plot).
-- Uses the sign's own SurfaceGui labels if it has them, otherwise floats a label above it.
local EMPTY_SIGN_TEXT = "Empty Plot"

local function setSign(plot, text)
	local sign = plot.Model:FindFirstChild("Sign", true)
	if sign and not sign:IsA("BasePart") then
		sign = sign:FindFirstChildWhichIsA("BasePart", true)
	end
	sign = sign or plot.Model.PrimaryPart
	if not sign then
		return
	end

	local found = false
	for _, d in sign:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextBox")) and d:FindFirstAncestorWhichIsA("SurfaceGui") then
			d.Text = text or EMPTY_SIGN_TEXT
			found = true
		end
	end
	if found then
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
	gui.Size = UDim2.fromOffset(220, 56)
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

-- Puts the owner's equipped pets on the plot for the clients to draw, and
-- the total $/s on the sign. Cheap to call often: only writes on changes.
local function publishPets(plot)
	local owner = plot.Owner
	local data = owner and EggSave.WaitForData(owner)
	if not data then
		return
	end
	local multiplier = owner:GetAttribute("CashMultiplier") or 1
	local list, total = {}, 0
	for _, entry in equippedPets(data) do
		local pet = entry[2]
		local income = math.floor(SellConfig.GetIncome(pet) * multiplier + 0.5)
		total += income
		table.insert(list, { Id = entry[1], Name = pet.Name, Rarity = pet.Rarity, Weight = pet.Weight, Income = income })
	end
	local json = HttpService:JSONEncode(list)
	if plot.Model:GetAttribute("PenPets") ~= json then
		plot.Model:SetAttribute("PenPets", json)
	end
	if plot.Model:GetAttribute("PenIncome") ~= total or plot.SignText == nil then
		plot.Model:SetAttribute("PenIncome", total)
		plot.SignText = string.format("%s's Pen\n%s/s", owner.DisplayName, Format.Money(total))
		setSign(plot, plot.SignText)
	end
end

-- Eggs in the pen ----------------------------------------------------------

local function refreshSlot(slot)
	if not slot.Prompt then
		return
	end
	local left = slot.Egg.ReadyAt - os.time()
	if slot.Timer then
		slot.Timer.Text = left > 0 and ("Egg " .. formatTime(left)) or "Ready to hatch!"
	end
	slot.Prompt.Enabled = left <= 0
end

local hatchEgg

-- Glowing, steaming egg sitting on the pen floor with a countdown above it,
-- and the Hatch prompt on it (shown to the owner only, by the client).
local function showVisual(plot, slot)
	clearVisual(slot)
	local data = slot.Egg
	local part = EggFactory.Build(data)
	part.Anchored = true
	part.CFrame = spotCFrame(plot, data.Spot) * CFrame.new(0, part.Size.Y / 2, 0)
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

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PenPrompt"
	prompt.ActionText = "Hatch"
	prompt.ObjectText = EggConfig.Eggs[data.EggId] and EggConfig.Eggs[data.EggId].DisplayName or "Egg"
	prompt.MaxActivationDistance = S.PenPromptDistance
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	-- The client script hides this prompt for everyone but the owner.
	prompt:SetAttribute("OwnerUserId", plot.Owner and plot.Owner.UserId or 0)
	prompt.Triggered:Connect(function(who)
		if who == plot.Owner then
			hatchEgg(who, plot, slot)
		end
	end)
	prompt.Parent = part

	part.Parent = plot.Model:FindFirstChild("Pen") or plot.Model
	slot.Visual, slot.Timer, slot.Prompt = part, label, prompt
	refreshSlot(slot)
end

local function nearSlot(player, slot)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and slot.Visual and (root.Position - slot.Visual.Position).Magnitude <= S.PenPromptDistance + 6
end

function hatchEgg(player, plot, slot)
	local egg = slot.Egg
	if not egg or os.time() < egg.ReadyAt or not nearSlot(player, slot) then
		return
	end
	local data = EggSave.WaitForData(player)
	if not data or plot.Owner ~= player or plot.Eggs[slot.Key] ~= slot then
		return
	end
	-- Clear it before anything else so it can't hatch twice.
	plot.Eggs[slot.Key] = nil
	data.Eggs.Pens[slot.Key] = nil
	clearVisual(slot)

	local pet = Hatching.Roll(egg)
	pet.Id = EggSave.AddPet(player, pet)
	-- New pets go straight into the pen while it has room.
	local saved = pet.Id and data.Pets[pet.Id]
	local inPen = false
	if saved and #equippedPets(data) < PlayerConfig.MaxEquippedPets then
		saved.Equipped = true
		inPen = true
		plot.Model:SetAttribute("LastHatch", HttpService:JSONEncode({ Id = pet.Id, X = egg.Spot.X, Z = egg.Spot.Z }))
	end
	EggSave.MarkDirty(player)
	publishPets(plot)
	notify(player, "Hatched", { Pet = pet, EggId = egg.EggId, Name = EggConfig.Eggs[egg.EggId].DisplayName })
	if not inPen then
		task.delay(6, function()
			notify(player, "Info", {
				Text = `Your pen is full ({PlayerConfig.MaxEquippedPets} pets). Unequip a pet in your inventory to put {pet.Name} in.`,
			})
		end)
	end
end

-- Place Egg (the Drop Egg button inside your own pen). Returns "notInPen"
-- when the player isn't standing in their own pen (then the egg just drops),
-- true when placed, or false + a reason.
function PenService.PlaceHere(player)
	local plot = playerPlot[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not plot.Floor or not root then
		return "notInPen"
	end
	local spot = floorSpot(plot, root.Position)
	local height = plot.Floor.CFrame:PointToObjectSpace(root.Position).Y
	if not insideFloor(plot, spot, 0) or height > 12 then
		return "notInPen"
	end
	if not EggCarry.IsCarrying(player) then
		return false, "You're not carrying an egg."
	end
	if not insideFloor(plot, spot, EDGE) then
		return false, "Move away from the fence a bit."
	end
	if eggCount(plot) >= MAX_EGGS then
		return false, `Your pen holds {MAX_EGGS} eggs. Hatch one first.`
	end
	for _, slot in plot.Eggs do
		local s = slot.Egg.Spot
		if (Vector2.new(s.X, s.Z) - spot).Magnitude < EGG_GAP then
			return false, "Too close to another egg."
		end
	end
	local data = EggSave.WaitForData(player)
	if not data or plot.Owner ~= player then
		return false, "Still loading."
	end
	local egg = EggCarry.TakeCarried(player)
	if not egg then
		return false, "You're not carrying an egg."
	end
	local def = EggConfig.Eggs[egg.EggId]
	egg.ReadyAt = os.time() + math.floor(def.GrowSeconds + def.GrowSecondsPerKg * egg.Kg)
	egg.Spot = { X = spot.X, Z = spot.Y }
	local slot = { Key = egg.Uid or HttpService:GenerateGUID(false), Egg = egg }
	plot.Eggs[slot.Key] = slot
	data.Eggs.Pens[slot.Key] = egg
	EggSave.MarkDirty(player)
	showVisual(plot, slot)
	local info = EggFactory.Info(egg)
	info.ReadyAt = egg.ReadyAt
	notify(player, "EggPlaced", info)
	return true
end

-- Admin: every egg in the player's pen is ready to hatch now.
function PenService.ReadyAll(player)
	local plot = playerPlot[player]
	if not plot then
		return 0
	end
	local now, n = os.time(), 0
	for _, slot in plot.Eggs do
		slot.Egg.ReadyAt = now
		if slot.Visual then
			slot.Visual:SetAttribute("ReadyAt", now)
		end
		refreshSlot(slot)
		n += 1
	end
	EggSave.MarkDirty(player)
	return n
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

	local pen = plot.Model:FindFirstChild("Pen")
	if pen then
		pen:SetAttribute("Level", level)
	end
	plot.Model:SetAttribute("PenLevel", level)
	if plot.Owner then
		plot.Owner:SetAttribute("PenLevel", level)
		plot.Owner:SetAttribute("CashMultiplier", multiplier)
		publishPets(plot)
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

	plot.Floor = findFloor(plot.Model)
	plot.Owner = player
	plot.Eggs = {}
	plot.SignText = nil
	playerPlot[player] = plot
	plot.Model:SetAttribute("OwnerUserId", player.UserId)
	plot.Model:SetAttribute("OwnerName", player.DisplayName)
	player:SetAttribute("PlotName", plot.Model.Name)
	setSign(plot, player.DisplayName .. "'s Pen")
	notify(player, "Info", { Text = `You claimed {plot.Model.Name}! Bring eggs into your pen.` })
	if not plot.Floor then
		warn(`[Eggs] {plot.Model:GetFullName()} has no Pen.Floor part, so eggs can't be placed there.`)
	end

	-- Put saved eggs back. Old eggs from the nest days (no Spot, or a spot off
	-- the floor) get a free spot on a grid.
	if plot.Floor then
		local keys = {}
		for key in data.Eggs.Pens do
			table.insert(keys, key)
		end
		table.sort(keys)
		for _, key in keys do
			local egg = data.Eggs.Pens[key]
			if type(egg) == "table" and EggConfig.Eggs[egg.EggId] then
				local s = egg.Spot
				if type(s) ~= "table" or type(s.X) ~= "number" or not insideFloor(plot, Vector2.new(s.X, s.Z or 0), 0) then
					egg.Spot = defaultSpot(plot)
				end
				local slot = { Key = key, Egg = egg }
				plot.Eggs[key] = slot
				showVisual(plot, slot)
			end
		end
	end
	setupUpgradeSign(player, plot)
	applyLevel(plot, getPenLevel(data))
	publishPets(plot)

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
	plot.Model:SetAttribute("PenPets", "[]")
	plot.Model:SetAttribute("PenIncome", 0)
	plot.Model:SetAttribute("LastHatch", nil)
	plot.SignText = nil
	player:SetAttribute("CashMultiplier", nil)
	local pen = plot.Model:FindFirstChild("Pen")
	if pen then
		pen:SetAttribute("Level", 1)
	end
	setSign(plot, nil)
	clearUpgradeSign(plot)
	for _, slot in plot.Eggs do
		clearVisual(slot)
	end
	plot.Eggs = {}
end

-- Sends the player to their plot's entrance. Returns false if they have no plot.
function PenService.SendHome(player)
	local plot = playerPlot[player]
	if not plot then
		return false
	end
	sendToPlot(player, plot)
	return true
end

-- The plot a player owns, or nil.
function PenService.GetPlot(player)
	local plot = playerPlot[player]
	return plot and plot.Model
end

-- Seconds left on each egg in the player's pen, for a pen timer UI.
-- Returns { { Key, EggId, Name, ReadyAt, SecondsLeft } }
function PenService.GetPenEggs(player)
	local result = {}
	local plot = playerPlot[player]
	if not plot then
		return result
	end
	for key, slot in plot.Eggs do
		table.insert(result, {
			Key = key,
			EggId = slot.Egg.EggId,
			Name = EggConfig.Eggs[slot.Egg.EggId].DisplayName,
			ReadyAt = slot.Egg.ReadyAt,
			SecondsLeft = math.max(0, slot.Egg.ReadyAt - os.time()),
		})
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

	-- InOwnPen (turns the Drop Egg button into Place Egg) four times a second;
	-- countdowns, ready prompts and pen pets every second.
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(0.25)
			tick += 1
			for _, plot in plots do
				local owner = plot.Owner
				if owner and plot.Floor then
					local character = owner.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local inPen = false
					if root then
						local height = plot.Floor.CFrame:PointToObjectSpace(root.Position).Y
						inPen = height < 12 and insideFloor(plot, floorSpot(plot, root.Position), 0)
					end
					if owner:GetAttribute("InOwnPen") ~= inPen then
						owner:SetAttribute("InOwnPen", inPen)
					end
					if tick % 4 == 0 then
						for _, slot in plot.Eggs do
							refreshSlot(slot)
						end
						publishPets(plot)
					end
				end
			end
		end
	end)
end

return PenService
