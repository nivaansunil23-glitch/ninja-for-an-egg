-- Client side of the shopkeepers: the name tag over each one, the bubbly
-- "Talk" prompt, and the acting while you talk to them (turning to face you,
-- a little bounce while they speak, wave/point/cheer animations and speech
-- bubbles). It all runs on your screen only, so every player sees the
-- shopkeeper turn to them.
--
-- The server tags each shopkeeper "Shopkeeper" and sets its ShopType and
-- KeeperName attributes (Shops.server).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("ShopConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local KEEPER_TAG = "Shopkeeper"
local TURN_SPEED = 9
local BOB_HEIGHT = 0.14
local LOOK_BACK_DELAY = 1.5 -- seconds they keep looking at you after you're done

-- Roblox's own emote animations, which any game can use.
local ANIMATIONS = {
	R15 = { Wave = "507770239", Point = "507770453", Cheer = "507770677", Laugh = "507770818" },
	R6 = { Wave = "128777973", Point = "128853357", Cheer = "129423030", Laugh = "129423131" },
}

local POP_IN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local Shopkeepers = {}

local function keeperRoot(keeper: Model): BasePart?
	local root = keeper:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return keeper.PrimaryPart or keeper:FindFirstChildWhichIsA("BasePart", true)
end

local function shopColors(shopType: any)
	local shop = ShopConfig.Shops[shopType]
	return shop and Theme.Colors[shop.Color] or Theme.Colors.Pink
end

local function yawOf(cframe: CFrame): number
	local look = cframe.LookVector
	return math.atan2(-look.X, -look.Z)
end

-- Name tags and speech bubbles ------------------------------------------------------
-- One billboard per shopkeeper, sitting on top of their head: their name at the
-- bottom (the stall already has the shop's title) and room above for a speech
-- bubble.

local tags = {} -- [keeper] = { Gui, Speech, Text, Scale, Token }

local function addNameTag(keeper: Model)
	local shop = ShopConfig.Shops[keeper:GetAttribute("ShopType")]
	if not shop or tags[keeper] then
		return
	end
	local head = keeper:WaitForChild("Head", 5)
	local adornee = if head and head:IsA("BasePart") then head else keeperRoot(keeper)
	if not adornee or not keeper:IsDescendantOf(Workspace) or tags[keeper] then
		return
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "ShopkeeperTag"
	tag.Adornee = adornee
	tag.Size = UDim2.fromOffset(280, 150)
	tag.SizeOffset = Vector2.new(0, 0.5) -- bottom edge sits on top of the head
	tag.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + 0.4, 0)
	tag.AlwaysOnTop = true -- the stall roof shouldn't hide it
	tag.MaxDistance = 90
	tag.LightInfluence = 0
	tag.ResetOnSpawn = false

	local name = Components.Label({
		Name = "KeeperName",
		Text = keeper:GetAttribute("KeeperName") or shop.Keeper,
		Parent = tag,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0.5, 0, 1, -4),
		AnchorPoint = Vector2.new(0.5, 1),
		Color = shopColors(keeper:GetAttribute("ShopType"))[1],
		MaxTextSize = 32,
		StrokeThickness = 3,
	})
	keeper:GetAttributeChangedSignal("KeeperName"):Connect(function()
		name.Text = keeper:GetAttribute("KeeperName") or shop.Keeper
	end)

	-- Speech bubble with a little tail, hidden until they say something.
	local speech = Instance.new("Frame")
	speech.Name = "Speech"
	speech.BackgroundTransparency = 1
	speech.Size = UDim2.fromOffset(260, 96)
	speech.Position = UDim2.new(0.5, 0, 1, -44)
	speech.AnchorPoint = Vector2.new(0.5, 1)
	speech.Visible = false
	speech.Parent = tag
	local speechScale = Instance.new("UIScale")
	speechScale.Parent = speech
	local tail = Components.Box({
		Name = "Tail",
		Parent = speech,
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(0.5, 0, 1, -12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Colors = { Theme.Colors.Row[2], Theme.Colors.Row[2] },
		CornerRadius = UDim.new(0, 4),
		StrokeThickness = 3,
		ZIndex = 1,
	})
	tail.Rotation = 45
	local bubble = Components.Box({
		Name = "Bubble",
		Parent = speech,
		Size = UDim2.new(1, 0, 1, -12),
		Colors = Theme.Colors.Row,
		CornerRadius = UDim.new(0, 18),
		StrokeThickness = 3,
		ZIndex = 2,
	})
	local text = Components.Label({
		Name = "Text",
		Text = "",
		Parent = bubble,
		Size = UDim2.new(1, -22, 1, -14),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Wrapped = true,
		Color = Theme.DarkText,
		StrokeThickness = 0,
		MaxTextSize = 24,
		ZIndex = 2,
	})

	tag.Parent = playerGui
	tags[keeper] = { Gui = tag, Speech = speech, Text = text, Scale = speechScale, Token = 0 }
end

local function removeNameTag(keeper: Instance)
	local entry = tags[keeper]
	if entry then
		entry.Gui:Destroy()
		tags[keeper] = nil
	end
end

CollectionService:GetInstanceAddedSignal(KEEPER_TAG):Connect(function(keeper)
	if keeper:IsA("Model") then
		task.spawn(addNameTag, keeper)
	end
end)
CollectionService:GetInstanceRemovedSignal(KEEPER_TAG):Connect(removeNameTag)
for _, keeper in CollectionService:GetTagged(KEEPER_TAG) do
	if keeper:IsA("Model") then
		task.spawn(addNameTag, keeper)
	end
end

-- Talk prompt -------------------------------------------------------------------
-- Shop prompts come from the server in the default style. Once the handler
-- below is hooked up they switch to our own bubbly look, so if anything here
-- breaks they just stay as normal Roblox prompts.

local function isShopPrompt(instance: Instance): boolean
	return instance:IsA("ProximityPrompt") and instance:GetAttribute("ShopType") ~= nil
end

local function keyText(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "👆"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return (string.gsub(prompt.GamepadKeyCode.Name, "^Button", ""))
	end
	local text = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	return if text ~= "" then text else prompt.KeyboardKeyCode.Name
end

local function buildPrompt(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TalkPrompt"
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.Size = UDim2.fromOffset(176, 66)
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Adornee = prompt.Parent

	local button = Instance.new("TextButton")
	button.Name = "Talk"
	button.Text = ""
	button.Active = true -- billboard buttons need Active on both the gui and the button
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.Size = UDim2.new(1, -10, 1, -10)
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	Components.Corner(button, UDim.new(1, 0))
	Components.Stroke(button, 4)
	Components.Gradient(button, shopColors(prompt:GetAttribute("ShopType")))
	Components.Shine(button, 0.35)
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = button
	button.Parent = billboard

	local key = Components.Box({
		Name = "Key",
		Parent = button,
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(0, 7, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Colors = { Color3.new(1, 1, 1), Color3.fromRGB(228, 220, 248) },
		CornerRadius = UDim.new(0, 12),
		StrokeThickness = 3,
	})
	Components.Label({
		Text = keyText(prompt, inputType),
		Parent = key,
		Size = UDim2.fromScale(0.72, 0.72),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = Theme.DarkText,
		StrokeThickness = 0,
		MaxTextSize = 28,
	})
	Components.Label({
		Text = "💬 " .. prompt.ActionText,
		Parent = button,
		Size = UDim2.new(1, -66, 0.6, 0),
		Position = UDim2.new(0, 56, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		MaxTextSize = 28,
		StrokeThickness = 2.5,
	})

	-- Tapping or clicking the bubble talks too (touch screens need this).
	local pressing = false
	button.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if (kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1) and input.UserInputState ~= Enum.UserInputState.Change then
			pressing = true
			prompt:InputHoldBegin()
		end
	end)
	button.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if (kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1) and pressing then
			pressing = false
			prompt:InputHoldEnd()
		end
	end)

	billboard.Parent = playerGui
	TweenService:Create(scale, POP_IN, { Scale = 1 }):Play()
	return billboard
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom or not isShopPrompt(prompt) then
		return
	end
	local ok, billboard = pcall(buildPrompt, prompt, inputType)
	if not ok then
		warn("[Shopkeepers] Talk prompt failed, using the default one:", billboard)
		prompt.Style = Enum.ProximityPromptStyle.Default
		return
	end
	prompt.PromptHidden:Once(function()
		billboard:Destroy()
	end)
end)

local function useCustomStyle(instance: Instance)
	if isShopPrompt(instance) then
		local prompt = instance :: ProximityPrompt
		prompt.Style = Enum.ProximityPromptStyle.Custom
	end
end
Workspace.DescendantAdded:Connect(useCustomStyle)
for _, descendant in Workspace:GetDescendants() do
	useCustomStyle(descendant)
end

-- Acting -------------------------------------------------------------------------

-- [keeper] = { Home, HomeYaw, Yaw, Rest, Engaged, Talking, Bob, ReturnAt }
local acting = {}
local tracks = setmetatable({}, { __mode = "k" }) -- [keeper] = { [name] = AnimationTrack }

-- Start facing the player. Only works when the keeper's root is anchored
-- (the server anchors it), since turning is done on this screen only.
function Shopkeepers.BeginTalk(keeper: Model?)
	if not keeper then
		return
	end
	local root = keeperRoot(keeper)
	if not root or not root.Anchored then
		return
	end
	local state = acting[keeper]
	if not state then
		local home = keeper:GetPivot()
		local yaw = yawOf(home)
		state = {
			Home = home,
			HomeYaw = yaw,
			Yaw = yaw,
			Rest = CFrame.Angles(0, -yaw, 0) * home.Rotation,
			Bob = 0,
		}
		acting[keeper] = state
	end
	state.Engaged = true
	state.ReturnAt = nil
end

-- Done talking: look at the player a moment longer, then turn back.
function Shopkeepers.EndTalk(keeper: Model?)
	local state = keeper and acting[keeper]
	if state then
		state.Engaged = false
		state.Talking = false
		state.ReturnAt = os.clock() + LOOK_BACK_DELAY
	end
end

-- A little bounce while their line is being typed out.
function Shopkeepers.SetTalking(keeper: Model?, talking: boolean)
	local state = keeper and acting[keeper]
	if state then
		state.Talking = talking
	end
end

-- Plays "Wave", "Point", "Cheer" or "Laugh" once.
function Shopkeepers.Play(keeper: Model?, name: string)
	local humanoid = keeper and keeper:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not (keeper and humanoid and animator) then
		return
	end
	local rig = if humanoid.RigType == Enum.HumanoidRigType.R6 then "R6" else "R15"
	local id = ANIMATIONS[rig][name]
	if not id then
		return
	end

	local cache = tracks[keeper]
	if not cache then
		cache = {}
		tracks[keeper] = cache
	end
	local track = cache[name]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. id
		local ok, result = pcall(animator.LoadAnimation, animator, animation)
		if not ok then
			return
		end
		track = result
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		cache[name] = track
	end
	for otherName, other in cache do
		if otherName ~= name and other.IsPlaying then
			other:Stop(0.2)
		end
	end
	track:Play(0.15)
end

-- Speech bubble over a shopkeeper's head for a few seconds, only on this screen.
function Shopkeepers.Bubble(keeper: Model?, text: string)
	local entry = keeper and tags[keeper]
	if not entry then
		return
	end
	entry.Token += 1
	local token = entry.Token
	entry.Text.Text = string.gsub(text, "<[^>]->", "")
	entry.Speech.Visible = true
	entry.Scale.Scale = 0.3
	TweenService:Create(entry.Scale, POP_IN, { Scale = 1 }):Play()
	task.delay(2.5 + #text * 0.03, function()
		if entry.Token == token then
			entry.Speech.Visible = false
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	if next(acting) == nil then
		return
	end
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart")
	local now = os.clock()

	for keeper, state in acting do
		if not keeper:IsDescendantOf(Workspace) then
			acting[keeper] = nil
			continue
		end

		local watching = state.Engaged or now < (state.ReturnAt or 0)
		local targetYaw = state.HomeYaw
		if watching and myRoot then
			local offset = myRoot.Position - state.Home.Position
			if offset.X * offset.X + offset.Z * offset.Z > 0.25 then
				targetYaw = math.atan2(-offset.X, -offset.Z)
			end
		end
		local turn = (targetYaw - state.Yaw + math.pi) % (2 * math.pi) - math.pi
		state.Yaw += turn * math.min(1, dt * TURN_SPEED)
		state.Bob += ((if state.Talking then 1 else 0) - state.Bob) * math.min(1, dt * 10)

		if not watching and math.abs(turn) < 0.003 and state.Bob < 0.02 then
			keeper:PivotTo(state.Home)
			acting[keeper] = nil
		else
			local lift = math.abs(math.sin(now * 12)) * BOB_HEIGHT * state.Bob
			keeper:PivotTo(CFrame.new(state.Home.Position + Vector3.new(0, lift, 0)) * CFrame.Angles(0, state.Yaw, 0) * state.Rest)
		end
	end
end)

return Shopkeepers
