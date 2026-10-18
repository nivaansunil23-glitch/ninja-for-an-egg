-- Trampoline jump training (like Jump for Phonk / Jump to Steal) and the big
-- launch trampoline.
--
-- Training: step onto a trampoline and you start bouncing by yourself. Every
-- bounce gives Jump XP, and clicking (tap, Space, or A / R2 on a controller)
-- while you bounce gives more. XP fills the level bar at the top and every
-- level adds jump power. Walk away or press STOP to get off.
-- Launch: landing on the launch trampoline throws you
-- JumpBalance.LaunchHeightMultiplier times as high as your normal jump.
--
-- The bouncing runs here because a character's physics belong to its client.
-- Training/TrainingService on the server checks every bounce and click before
-- it gives XP. Trampolines also show your tier's themed skin from
-- ReplicatedStorage.TrampolineSkins when the map has one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local Trampolines = require(Shared:WaitForChild("Trampolines"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local Bubbly = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Bubbly"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local startRemote = Net.Event("TrainStart")
local stopRemote = Net.Event("TrainStop")
local bounceRemote = Net.Event("TrainBounce")
local clickRemote = Net.Event("TrainClick")
local gainRemote = Net.Event("TrainGain")
local stoppedRemote = Net.Event("TrainStopped")

local CENTERING = 8 -- pull back over your spot, per stud you drift off it
local MAX_CENTERING_SPEED = 24
local BOUNCE_COOLDOWN = 0.25
local CLICK_GAP = 1 / 12 -- client-side throttle, the server has its own limit
local BAR_LINGER = 3 -- seconds the level bar stays up after you stop
local STAND_ABOVE_PAD = 7 -- how far over the pad's top your root can be and count as on it
local LAUNCH_COOLDOWN = 0.8
local REFRESH_SECONDS = 1
local SKIN_FOLDER = "TrampolineSkins"
local UPGRADE_PROMPT = "TrampolineUpgrade"

local GREEN = Color3.fromRGB(120, 255, 140)
local GOLD = Color3.fromRGB(255, 225, 90)

local session = nil -- { Trampoline, Anchor, LastBounce } while bouncing
local mustLeave = false -- after getting off, step off the pad before it starts again
local lastClick = 0
local lastLaunch = 0
local barToken = 0

local function getCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root :: BasePart
	end
	return nil, nil, nil
end

local function bounceSpeed(): number
	return math.sqrt(2 * Workspace.Gravity * JumpBalance.BounceHeight)
end

-- UI ------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 5
gui.Parent = playerGui

-- Level bar, top middle like the video: "Level 3 [=====   ] 2 / 6".
local bar = Instance.new("Frame")
bar.Name = "LevelBar"
bar.BackgroundTransparency = 1
bar.Size = UDim2.fromScale(0.34, 0.05)
bar.Position = UDim2.fromScale(0.5, 0.145)
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Visible = false
bar.Parent = gui
local barLimits = Instance.new("UISizeConstraint")
barLimits.MinSize = Vector2.new(280, 36)
barLimits.MaxSize = Vector2.new(560, 54)
barLimits.Parent = bar

local track = Bubbly.Box({
	Name = "Track",
	Parent = bar,
	Colors = Bubbly.Colors.Track,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 3,
})
local fill = Bubbly.Box({
	Name = "Fill",
	Parent = track,
	Size = UDim2.fromScale(0, 1),
	Colors = Bubbly.Colors.Yellow,
	CornerRadius = UDim.new(1, 0),
	StrokeThickness = 0,
})
local levelText = Bubbly.Label({
	Text = "Level 1",
	Parent = track,
	Size = UDim2.fromScale(0.5, 0.72),
	Position = UDim2.fromScale(0.05, 0.14),
	XAlign = Enum.TextXAlignment.Left,
	MaxTextSize = 30,
	ZIndex = 2,
})
local countText = Bubbly.Label({
	Text = "0 / 10",
	Parent = track,
	Size = UDim2.fromScale(0.45, 0.72),
	Position = UDim2.fromScale(0.5, 0.14),
	XAlign = Enum.TextXAlignment.Right,
	MaxTextSize = 30,
	ZIndex = 2,
})
local jumpText = Bubbly.Label({
	Text = "",
	Parent = bar,
	Size = UDim2.fromScale(0.6, 0.62),
	Position = UDim2.new(0.5, 0, 1, 6),
	AnchorPoint = Vector2.new(0.5, 0),
	Color = GREEN,
	MaxTextSize = 26,
})
local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local hint = Bubbly.Label({
	Text = if touchOnly then "Tap to train faster!" else "Click to train faster!",
	Parent = bar,
	Size = UDim2.fromScale(0.8, 0.5),
	Position = UDim2.new(0.5, 0, 1.62, 10),
	AnchorPoint = Vector2.new(0.5, 0),
	MaxTextSize = 22,
})

local stopButton = Bubbly.Button({
	Name = "Stop",
	Text = "STOP",
	Parent = gui,
	Size = UDim2.fromOffset(170, 60),
	Position = UDim2.fromScale(0.5, 0.86),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Colors = Bubbly.Colors.Red,
	CornerRadius = UDim.new(0, 18),
	StrokeThickness = 4,
	MaxTextSize = 34,
})
stopButton.Visible = false

local shownLevel = nil
local function refreshBar()
	local level = player:GetAttribute("JumpLevel") or 1
	local xp = player:GetAttribute("JumpXP") or 0
	local need = JumpBalance.XpForLevel(level)
	levelText.Text = "Level " .. level
	countText.Text = Format.Short(xp) .. " / " .. Format.Short(need)
	jumpText.Text = tostring(player:GetAttribute("TrainedJump") or JumpBalance.JumpForLevel(level)) .. " Jump"
	if shownLevel ~= level then
		-- New level: restart the fill from empty instead of sliding backwards.
		fill.Size = UDim2.fromScale(0, 1)
		shownLevel = level
	end
	TweenService:Create(fill, TweenInfo.new(0.15), { Size = UDim2.fromScale(math.clamp(xp / need, 0, 1), 1) }):Play()
end
player:GetAttributeChangedSignal("JumpLevel"):Connect(refreshBar)
player:GetAttributeChangedSignal("JumpXP"):Connect(refreshBar)
player:GetAttributeChangedSignal("TrainedJump"):Connect(refreshBar)
refreshBar()

local function showBar()
	barToken += 1
	bar.Visible = true
	if session then
		return
	end
	local token = barToken
	task.delay(BAR_LINGER, function()
		if token == barToken and not session then
			bar.Visible = false
		end
	end)
end

-- "+1 Jump XP" popups floating up from your character.
local popups = Instance.new("BillboardGui")
popups.Name = "TrainPopups"
popups.Size = UDim2.fromOffset(300, 220)
popups.StudsOffset = Vector3.new(0, 3.5, 0)
popups.AlwaysOnTop = true
popups.LightInfluence = 0
popups.ResetOnSpawn = false
popups.Parent = playerGui

local function popup(text: string, color: Color3, width: number, height: number, x: number)
	local _, _, root = getCharacter()
	if not root then
		return
	end
	popups.Adornee = root
	local label = Bubbly.Label({
		Text = text,
		Parent = popups,
		Color = color,
		Size = UDim2.fromScale(width, height),
		Position = UDim2.fromScale(x, 0.72),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 40,
		StrokeThickness = 3,
	})
	Bubbly.Pop(label, 0.5)
	Bubbly.FloatAway(label, UDim2.fromScale(0, -0.55), 0.9)
end

local function sparkle(root: BasePart)
	local emitter = root:FindFirstChild("JumpSparkles") :: ParticleEmitter?
	if not emitter then
		emitter = Instance.new("ParticleEmitter")
		emitter.Name = "JumpSparkles"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 150, 210))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
		emitter.Lifetime = NumberRange.new(0.6, 1)
		emitter.Speed = NumberRange.new(10, 18)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.LightEmission = 0.8
		emitter.Rate = 0
		emitter.Parent = root
	end
	emitter:Emit(30)
end

local function showLevelUp(level: number, jump: number?)
	local banner = Bubbly.Label({
		Text = `LEVEL {level}!`,
		Parent = gui,
		Size = UDim2.fromScale(0.5, 0.09),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = GOLD,
		MaxTextSize = 64,
		StrokeThickness = 4,
		ZIndex = 5,
	})
	local jumpLine = Bubbly.Label({
		Text = `{jump or JumpBalance.JumpForLevel(level)} Jump`,
		Parent = banner,
		Size = UDim2.fromScale(0.7, 0.55),
		Position = UDim2.fromScale(0.5, 1.05),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = GREEN,
		MaxTextSize = 34,
		StrokeThickness = 3,
		ZIndex = 5,
	})
	Bubbly.Pop(banner, 0.4)
	task.delay(1.1, function()
		Bubbly.FloatAway(jumpLine, UDim2.new(), 0.5)
		Bubbly.FloatAway(banner, UDim2.fromScale(0, -0.05), 0.5)
	end)
	local _, _, root = getCharacter()
	if root then
		sparkle(root)
	end
end

-- A ring where you clicked, so every click feels like it did something.
local function ripple(position: Vector2)
	local ring = Instance.new("Frame")
	ring.BackgroundTransparency = 1
	ring.Size = UDim2.fromOffset(18, 18)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromOffset(position.X, position.Y)
	ring.ZIndex = 4
	Bubbly.Corner(ring, UDim.new(1, 0))
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = GOLD
	stroke.Parent = ring
	ring.Parent = gui
	local info = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(70, 70) }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	task.delay(0.35, function()
		ring:Destroy()
	end)
end

-- Signs over the trampolines ("+1 Jump XP" like the video) --------------------------

local signs = {} -- [trampoline] = { Gui, Title, Sub }

local function makeSign(titleColor: Color3)
	local sign = Instance.new("BillboardGui")
	sign.Name = "TrampolineSign"
	sign.Size = UDim2.fromOffset(240, 90)
	sign.StudsOffset = Vector3.new(0, 7, 0)
	sign.MaxDistance = 120
	sign.LightInfluence = 0
	sign.ResetOnSpawn = false
	local title = Bubbly.Label({ Name = "Title", Parent = sign, Size = UDim2.fromScale(1, 0.6), Color = titleColor, MaxTextSize = 40, StrokeThickness = 3 })
	local sub = Bubbly.Label({ Name = "Sub", Parent = sign, Size = UDim2.fromScale(1, 0.38), Position = UDim2.fromScale(0, 0.62), MaxTextSize = 24 })
	sign.Parent = playerGui
	return { Gui = sign, Title = title, Sub = sub }
end

-- A trampoline inside a claimed plot uses its owner's tier, any other uses yours.
local function tierFor(trampoline: Instance): number
	local node = trampoline.Parent
	while node and node ~= Workspace do
		local owner = node:GetAttribute("OwnerUserId")
		if type(owner) == "number" and owner > 0 then
			local ownerPlayer = Players:GetPlayerByUserId(owner)
			return ownerPlayer and ownerPlayer:GetAttribute("TrampolineTier") or 1
		end
		node = node.Parent
	end
	return player:GetAttribute("TrampolineTier") or 1
end

local function refreshSigns()
	local tier = JumpBalance.Tier(player:GetAttribute("TrampolineTier"))
	local seen = {}
	for _, kind in { Trampolines.Training, Trampolines.Launch } do
		for _, trampoline in Trampolines.GetAll(kind) do
			seen[trampoline] = true
			local sign = signs[trampoline]
			if not sign then
				sign = makeSign(if kind == Trampolines.Launch then GOLD else GREEN)
				signs[trampoline] = sign
			end
			local pad = Trampolines.GetPad(trampoline)
			sign.Gui.Adornee = pad
			if kind == Trampolines.Launch then
				sign.Gui.Enabled = pad ~= nil
				sign.Title.Text = "LAUNCH"
				sign.Sub.Text = `Jump {JumpBalance.LaunchHeightMultiplier}x higher!`
			else
				local own = JumpBalance.Tier(tierFor(trampoline))
				local owner = Trampolines.OwnerUserId(trampoline)
				sign.Gui.Enabled = pad ~= nil and session == nil
				if Trampolines.CanUse(trampoline, player.UserId) then
					sign.Title.Text = `+{Format.Short(tier.XpPerBounce)} Jump XP`
					sign.Sub.Text = `Tier {tierFor(trampoline)}: {own.Name}`
				else
					local ownerPlayer = owner and owner > 0 and Players:GetPlayerByUserId(owner)
					sign.Title.Text = if ownerPlayer then `{ownerPlayer.DisplayName}'s Trampoline` else "Empty Plot"
					sign.Sub.Text = `Tier {tierFor(trampoline)}: {own.Name}`
				end
			end
		end
	end
	for trampoline, sign in signs do
		if not seen[trampoline] then
			sign.Gui:Destroy()
			signs[trampoline] = nil
		end
	end
end

-- Themed skins: a trampoline in a claimed plot shows its owner's tier, any
-- other trampoline shows yours. Only changes what you see: the trampoline's
-- own mesh (its "Skin" attribute says which look it already has, Basic if
-- unset) is hidden and the skin model is shown in its place. Skins have their
-- pivot at the bottom centre and get scaled to the trampoline's width.

local skins = {} -- [trampoline] = { Name, Model }

-- The trampoline's visible parts (not the invisible pads).
local function lookParts(trampoline: Instance): { BasePart }
	local list = {}
	local parts = if trampoline:IsA("BasePart") then { trampoline } else trampoline:GetDescendants()
	for _, part in parts do
		if part:IsA("BasePart") and part.Transparency < 1 and part.Name ~= "BouncePad" and part.Name ~= "UpgradePad" then
			table.insert(list, part)
		end
	end
	return list
end

local function hideOriginal(trampoline: Instance, hidden: boolean)
	for _, part in lookParts(trampoline) do
		part.LocalTransparencyModifier = if hidden then 1 else 0
	end
end

local function applySkin(trampoline: Instance)
	local folder = ReplicatedStorage:FindFirstChild(SKIN_FOLDER)
	local skinName = JumpBalance.Tier(tierFor(trampoline)).Skin
	local builtIn = trampoline:GetAttribute("Skin") or "Basic"
	local source = folder and folder:FindFirstChild(skinName)
	local wanted = if skinName ~= builtIn and source then skinName else nil

	local current = skins[trampoline]
	if current and current.Name == wanted and current.Model.Parent then
		hideOriginal(trampoline, true) -- parts that streamed back in would show again
		return
	end
	if current then
		current.Model:Destroy()
		skins[trampoline] = nil
		hideOriginal(trampoline, false)
	end
	if not wanted or not (source:IsA("Model") or source:IsA("BasePart")) then
		return
	end

	local width = 0
	for _, part in lookParts(trampoline) do
		width = math.max(width, part.Size.X, part.Size.Z)
	end
	if width < 1 then
		return -- not streamed in yet
	end
	local skin = source:Clone()
	if skin:IsA("BasePart") then
		local holder = Instance.new("Model")
		holder.WorldPivot = skin:GetPivot()
		skin.Parent = holder
		skin = holder
	end
	skin.Name = "TrampolineSkin"
	for _, part in skin:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	local _, skinSize = skin:GetBoundingBox()
	local skinWidth = math.max(skinSize.X, skinSize.Z)
	if skinWidth > 0.01 then
		skin:ScaleTo(skin:GetScale() * width / skinWidth)
	end
	skin:PivotTo(trampoline:GetPivot())
	skin.Parent = Workspace
	skins[trampoline] = { Name = wanted, Model = skin }
	hideOriginal(trampoline, true)
end

local function refreshSkins()
	local alive = {}
	for _, trampoline in Trampolines.GetAll(Trampolines.Training) do
		alive[trampoline] = true
		applySkin(trampoline)
	end
	for trampoline, skin in skins do
		if not alive[trampoline] then
			skin.Model:Destroy()
			skins[trampoline] = nil
		end
	end
end

-- The upgrade prompt would pop up the whole time you bounce, so hide it then.
-- Other players' trampolines never show it: you can only upgrade your own.
local function setUpgradePrompts(enabled: boolean)
	for _, trampoline in Trampolines.GetAll(Trampolines.Training) do
		local mine = Trampolines.CanUse(trampoline, player.UserId)
		for _, prompt in trampoline:GetDescendants() do
			if prompt:IsA("ProximityPrompt") and prompt.Name == UPGRADE_PROMPT then
				prompt.Enabled = enabled and mine
			end
		end
	end
end

-- Tricks: a flip or spin in the air on every bounce. Turns the root joint
-- (LowerTorso.Root on R15, RootJoint on R6), so physics isn't touched.
local TRICK_AXES = { Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1) }
local trick = nil -- { Joint, Base, Token }

local function rootJoint(character: Model): Motor6D?
	local lower = character:FindFirstChild("LowerTorso")
	local joint = lower and lower:FindFirstChild("Root")
	if not joint then
		local root = character:FindFirstChild("HumanoidRootPart")
		joint = root and root:FindFirstChild("RootJoint")
	end
	return if joint and joint:IsA("Motor6D") then joint else nil
end

local function endTrick()
	if trick then
		if trick.Joint.Parent then
			trick.Joint.C0 = trick.Base
		end
		trick = nil
	end
end

local function playTrick(character: Model, duration: number)
	local joint = rootJoint(character)
	if not joint then
		return
	end
	endTrick()
	local base = joint.C0
	local axis = TRICK_AXES[math.random(#TRICK_AXES)]
	local token = {}
	trick = { Joint = joint, Base = base, Token = token }
	local start = os.clock()
	task.spawn(function()
		while trick and trick.Token == token and joint.Parent do
			local t = math.clamp((os.clock() - start) / duration, 0, 1)
			local eased = TweenService:GetValue(t, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			joint.C0 = base * CFrame.fromAxisAngle(axis, eased * 2 * math.pi)
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if trick and trick.Token == token then
			endTrick()
		end
	end)
end

-- Training --------------------------------------------------------------------

local function startTraining(trampoline: Instance, info, humanoid: Humanoid, root: BasePart)
	-- Bounce where you landed, but not right on the edge.
	local offset = Vector3.new(root.Position.X - info.Center.X, 0, root.Position.Z - info.Center.Z)
	local maxOffset = info.Radius * 0.5
	if offset.Magnitude > maxOffset then
		offset = if offset.Magnitude > 0.01 then offset.Unit * maxOffset else Vector3.zero
	end
	session = { Trampoline = trampoline, Anchor = info.Center + offset, LastBounce = 0 }
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	startRemote:FireServer(trampoline)
	stopButton.Visible = true
	hint.Visible = true
	refreshBar()
	showBar()
	setUpgradePrompts(false)
	refreshSigns()
end

local function stopTraining(tellServer: boolean, hopOff: boolean)
	if not session then
		return
	end
	local trampoline = session.Trampoline
	session = nil
	mustLeave = true
	endTrick()
	stopButton.Visible = false
	hint.Visible = false
	showBar()
	setUpgradePrompts(true)
	refreshSigns()

	local _, humanoid, root = getCharacter()
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	if hopOff and root then
		-- Hop off the side you're on (or backwards from the middle).
		local info = Trampolines.GetPadInfo(trampoline)
		local away = if info then Vector3.new(root.Position.X - info.Center.X, 0, root.Position.Z - info.Center.Z) else Vector3.zero
		if away.Magnitude < 0.5 then
			away = Vector3.new(-root.CFrame.LookVector.X, 0, -root.CFrame.LookVector.Z)
		end
		away = if away.Magnitude > 0.01 then away.Unit else Vector3.xAxis
		root.AssemblyLinearVelocity = away * 32 + Vector3.new(0, 45, 0)
	end
	if tellServer then
		stopRemote:FireServer()
	end
end

stopButton.Activated:Connect(function()
	stopTraining(true, true)
end)

local function launch(humanoid: Humanoid, root: BasePart)
	-- v = jump * sqrt(k) reaches k times the normal jump height.
	local jump = player:GetAttribute("JumpPower") or humanoid.JumpPower
	local velocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X * 0.3, jump * math.sqrt(JumpBalance.LaunchHeightMultiplier), velocity.Z * 0.3)
	popup("LAUNCH!", GOLD, 0.9, 0.24, 0.5)
	sparkle(root)
end

RunService.Heartbeat:Connect(function()
	local character, humanoid, root = getCharacter()
	if not character then
		if session then
			stopTraining(false, false)
		end
		return
	end
	local now = os.clock()
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

	if session then
		local info = session.Trampoline.Parent and Trampolines.GetPadInfo(session.Trampoline)
		if not info or not Trampolines.IsOver(info, root.Position, 4, JumpBalance.BounceHeight + 8) then
			stopTraining(true, false)
			return
		end
		if humanoid.MoveDirection.Magnitude > 0.1 then
			stopTraining(true, false) -- walking away gets you off
			return
		end
		local offset = session.Anchor - root.Position
		local pull = Vector3.new(offset.X, 0, offset.Z) * CENTERING
		if pull.Magnitude > MAX_CENTERING_SPEED then
			pull = pull.Unit * MAX_CENTERING_SPEED
		end
		local velocity = root.AssemblyLinearVelocity
		if grounded and velocity.Y < 2 and now - session.LastBounce > BOUNCE_COOLDOWN then
			session.LastBounce = now
			root.AssemblyLinearVelocity = Vector3.new(pull.X, bounceSpeed(), pull.Z)
			bounceRemote:FireServer()
			-- Flip through most of the time in the air.
			playTrick(character, math.clamp(2 * bounceSpeed() / Workspace.Gravity * 0.8, 0.35, 1.2))
		else
			root.AssemblyLinearVelocity = Vector3.new(pull.X, velocity.Y, pull.Z)
		end
		return
	end

	if grounded and now - lastLaunch > LAUNCH_COOLDOWN then
		if Trampolines.FindAt(root.Position, Trampolines.Launch, 0, STAND_ABOVE_PAD) then
			lastLaunch = now
			launch(humanoid, root)
			return
		end
	end

	-- Land on your own training trampoline to start bouncing.
	local trampoline, info = Trampolines.FindAt(root.Position, Trampolines.Training, 0, STAND_ABOVE_PAD)
	if not trampoline or not Trampolines.CanUse(trampoline, player.UserId) then
		mustLeave = false
		return
	end
	if mustLeave or not grounded or humanoid.Sit then
		return
	end
	startTraining(trampoline, info, humanoid, root)
end)

-- Clicking while you bounce ---------------------------------------------------------

local function trainClick(screenPosition: Vector2?)
	if not session then
		return
	end
	local now = os.clock()
	if now - lastClick < CLICK_GAP then
		return
	end
	lastClick = now
	clickRemote:FireServer()
	if screenPosition then
		ripple(screenPosition)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not session then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not processed then
			trainClick(Vector2.new(input.Position.X, input.Position.Y))
		end
	elseif
		input.KeyCode == Enum.KeyCode.Space
		or input.KeyCode == Enum.KeyCode.ButtonA
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		if not UserInputService:GetFocusedTextBox() then
			trainClick(nil)
		end
	end
end)

UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
	if not processedByUI then
		trainClick(position)
	end
end)

-- Server messages -------------------------------------------------------------------

gainRemote.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	local amount = tonumber(info.Amount) or 0
	if info.Kind == "Click" then
		popup("+" .. Format.Short(amount), GOLD, 0.35, 0.16, 0.25 + math.random() * 0.5)
	else
		popup("+" .. Format.Short(amount) .. " Jump XP", GREEN, 0.9, 0.2, 0.5)
	end
	if type(info.Level) == "number" then
		showLevelUp(info.Level, info.Jump)
	end
	showBar()
end)

stoppedRemote.OnClientEvent:Connect(function()
	stopTraining(false, false)
end)

player.CharacterAdded:Connect(function()
	if session then
		stopTraining(false, false)
	end
	mustLeave = false
end)

player:GetAttributeChangedSignal("TrampolineTier"):Connect(function()
	refreshSigns()
	refreshSkins()
end)

task.spawn(function()
	while true do
		refreshSigns()
		refreshSkins()
		setUpgradePrompts(session == nil) -- plots change owners
		task.wait(REFRESH_SECONDS)
	end
end)
