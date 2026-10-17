-- Dialogue box at the bottom of the screen, like talking to a shopkeeper in
-- Grow a Garden: their portrait and name, their line typed out letter by
-- letter (click the box to skip ahead), then numbered answers to pick (click
-- one or press 1-4).
--
--   dialogue.Open({ Name = "Gear Guy", Colors = Theme.Colors.Pink, Icon = "🛠️", Portrait = keeperModel })
--   dialogue.Say("Hi there!")                                        -- yields until it's typed out
--   local picked = dialogue.Choose({ { Text = "Buy" }, { Text = "Bye" } })  -- yields, returns 1 or 2
--   dialogue.Close()
--
-- If the box closes while Say or Choose is waiting, they throw Dialogue.Closed,
-- so a conversation running inside pcall just stops there (see ShopTalk).

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))

local LETTERS_PER_SECOND = 45
local PUNCTUATION_PAUSE = { ["."] = 0.2, ["!"] = 0.2, ["?"] = 0.2, [","] = 0.08 }
local BLIP_EVERY = 3 -- letters between talking blips
local BLIP_SOUND = "rbxasset://sounds/volume_slider.ogg"
local BOX_SIZE = Vector2.new(700, 150)
local OPTION_SIZE = Vector2.new(340, 52)
local KEY_ACTION = "DialoguePickOption"

local NUMBER_KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
}
local KEY_LIST = {}
for keyCode in NUMBER_KEYS do
	table.insert(KEY_LIST, keyCode)
end

local POP_IN = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_OUT = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Dialogue = {}

Dialogue.Closed = setmetatable({}, {
	__tostring = function()
		return "Dialogue closed"
	end,
})

-- Head-and-shoulders picture of the shopkeeper, from a copy in a ViewportFrame.
local function buildPortrait(viewport: ViewportFrame, keeper: Model): boolean
	local head = keeper:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return false
	end

	local archivable = keeper.Archivable
	keeper.Archivable = true
	local ok, copy = pcall(keeper.Clone, keeper)
	keeper.Archivable = archivable
	if not ok or not copy then
		return false
	end
	for _, descendant in copy:GetDescendants() do
		if
			descendant:IsA("LuaSourceContainer")
			or descendant:IsA("ProximityPrompt")
			or descendant:IsA("BillboardGui")
			or descendant:IsA("Sound")
			or descendant:IsA("ParticleEmitter")
		then
			descendant:Destroy()
		end
	end

	local world = Instance.new("WorldModel")
	copy.Parent = world
	world.Parent = viewport

	local copyHead = copy:FindFirstChild("Head") :: BasePart
	local root = copy:FindFirstChild("HumanoidRootPart")
	local facing = if root and root:IsA("BasePart") then root.CFrame.LookVector else copyHead.CFrame.LookVector
	local size = copyHead.Size.Magnitude
	local focus = copyHead.Position - Vector3.new(0, size * 0.2, 0)

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(focus + facing * size * 2.5 + Vector3.new(0, size * 0.15, 0), focus)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return true
end

function Dialogue.new(gui: ScreenGui)
	local closeRequested = Instance.new("BindableEvent")

	local box = Instance.new("TextButton")
	box.Name = "Dialogue"
	box.Text = ""
	box.AutoButtonColor = false
	box.Size = UDim2.fromOffset(BOX_SIZE.X, BOX_SIZE.Y)
	-- Sits above the hotbar.
	box.Position = UDim2.new(0.5, 0, 1, -84)
	box.AnchorPoint = Vector2.new(0.5, 1)
	box.BackgroundColor3 = Color3.new(1, 1, 1)
	box.Visible = false
	box.ZIndex = 30
	Components.Corner(box, UDim.new(0, 26))
	Components.Stroke(box, 5)
	Components.Gradient(box, Theme.Colors.Panel)
	local scale = Instance.new("UIScale")
	scale.Parent = box

	-- Portrait: a round frame on the left with the shopkeeper's face.
	local portrait = Components.Box({
		Name = "Portrait",
		Parent = box,
		Size = UDim2.fromOffset(132, 132),
		Position = UDim2.new(0, -26, 0.5, -8),
		AnchorPoint = Vector2.new(0, 0.5),
		Colors = Theme.Colors.Pink,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 5,
		ZIndex = 31,
	})
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Face"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Color3.fromRGB(200, 195, 210)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
	viewport.ZIndex = 32
	Components.Corner(viewport, UDim.new(1, 0))
	viewport.Parent = portrait
	local portraitIcon = Components.Label({
		Name = "Icon",
		Text = "",
		Parent = portrait,
		Size = UDim2.fromScale(0.62, 0.62),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 72,
		StrokeThickness = 0,
		ZIndex = 32,
	})

	-- Name ribbon over the top edge.
	local ribbon = Components.Box({
		Name = "NameTag",
		Parent = box,
		Size = UDim2.fromOffset(250, 46),
		Position = UDim2.fromOffset(118, -26),
		Colors = Theme.Colors.Pink,
		CornerRadius = UDim.new(0, 16),
		StrokeThickness = 4,
		ZIndex = 31,
	})
	Components.Shine(ribbon, 0.3)
	local nameLabel = Components.Label({
		Name = "Name",
		Text = "",
		Parent = ribbon,
		Size = UDim2.fromScale(0.86, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		MaxTextSize = 30,
		StrokeThickness = 2.5,
		ZIndex = 32,
	})

	-- The line being said.
	local line = Components.Label({
		Name = "Line",
		Text = "",
		Parent = box,
		Size = UDim2.new(1, -154, 1, -44),
		Position = UDim2.fromOffset(124, 28),
		XAlign = Enum.TextXAlignment.Left,
		YAlign = Enum.TextYAlignment.Top,
		Wrapped = true,
		RichText = true,
		Color = Theme.DarkText,
		StrokeThickness = 0,
		MaxTextSize = 28,
		ZIndex = 31,
	})
	local lineSize = line:FindFirstChildOfClass("UITextSizeConstraint")
	if lineSize then
		lineSize.MinTextSize = 14
	end

	Components.Button({
		Name = "Close",
		Text = "X",
		Parent = box,
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.new(1, 14, 0, -14),
		AnchorPoint = Vector2.new(1, 0),
		Colors = Theme.Colors.Red,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 4,
		MaxTextSize = 26,
		ZIndex = 33,
		OnClick = function()
			closeRequested:Fire()
		end,
	})

	-- Answers stack up above the right side of the box.
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Size = UDim2.fromOffset(OPTION_SIZE.X + 20, 4 * (OPTION_SIZE.Y + 10) + 10)
	optionsFrame.Position = UDim2.new(1, -4, 0, -24)
	optionsFrame.AnchorPoint = Vector2.new(1, 1)
	optionsFrame.ZIndex = 34
	optionsFrame.Parent = box
	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	optionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	optionsLayout.Padding = UDim.new(0, 10)
	optionsLayout.Parent = optionsFrame

	local blip = Instance.new("Sound")
	blip.Name = "Blip"
	blip.SoundId = BLIP_SOUND
	blip.Volume = 0.3
	blip.Parent = box

	box.Parent = gui

	local dialogue = {
		CloseRequested = closeRequested.Event,
	}

	local token = 0 -- bumps on open/close so stale waits know to stop
	local isOpen = false
	local typing = false
	local skip = false
	local waiting: thread? = nil
	local optionButtons = {}
	local pickers = {}
	local portraitKeeper: Model? = nil

	local function fitScale(): number
		local camera = Workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		return math.min(1.1, size.X * 0.9 / (BOX_SIZE.X + 60), size.Y * 0.28 / BOX_SIZE.Y)
	end

	local function playBlip()
		blip.PlaybackSpeed = 1.2 + math.random() * 0.35
		blip.TimePosition = 0
		blip:Play()
	end

	local function unbindKeys()
		ContextActionService:UnbindAction(KEY_ACTION)
	end

	local function bindKeys()
		ContextActionService:BindActionAtPriority(KEY_ACTION, function(_, state, input)
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			local number = NUMBER_KEYS[input.KeyCode]
			local picker = number and pickers[number]
			if picker then
				picker()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.ContextActionPriority.High.Value, table.unpack(KEY_LIST))
	end

	local function clearOptions()
		unbindKeys()
		table.clear(pickers)
		for _, button in optionButtons do
			button:Destroy()
		end
		table.clear(optionButtons)
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(box) then
			GuiService.SelectedObject = nil
		end
	end

	local function makeOption(index: number, option, onPick)
		local button = Components.Button({
			Name = "Option" .. index,
			Text = option.Text,
			Parent = optionsFrame,
			Size = UDim2.fromOffset(OPTION_SIZE.X, OPTION_SIZE.Y),
			Colors = option.Colors or Theme.Colors.Purple,
			CornerRadius = UDim.new(0, 18),
			LabelSize = UDim2.new(1, -66, 0.6, 0),
			LabelPosition = UDim2.new(0.5, 24, 0.5, 0),
			MaxTextSize = 24,
			LayoutOrder = index,
			ZIndex = 35,
			OnClick = onPick,
		})
		Components.Shine(button, 0.3)
		local badge = Components.Box({
			Name = "Number",
			Parent = button,
			Size = UDim2.fromOffset(34, 34),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Colors = { Color3.new(1, 1, 1), Color3.fromRGB(230, 222, 248) },
			CornerRadius = UDim.new(1, 0),
			StrokeThickness = 3,
			ZIndex = 36,
		})
		Components.Label({
			Text = tostring(index),
			Parent = badge,
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Color = Theme.DarkText,
			StrokeThickness = 0,
			MaxTextSize = 24,
			ZIndex = 36,
		})

		-- Pop in one after another.
		local buttonScale = button:FindFirstChildOfClass("UIScale")
		if buttonScale then
			buttonScale.Scale = 0
			task.delay((index - 1) * 0.06, function()
				TweenService:Create(buttonScale, POP_IN, { Scale = 1 }):Play()
			end)
		end
		return button
	end

	local function setPortrait(keeper: Model?, icon: string?)
		local hasFace = false
		if keeper then
			if portraitKeeper == keeper and viewport:FindFirstChildOfClass("WorldModel") then
				hasFace = true
			else
				for _, child in viewport:GetChildren() do
					if child:IsA("WorldModel") or child:IsA("Camera") then
						child:Destroy()
					end
				end
				local ok, built = pcall(buildPortrait, viewport, keeper)
				hasFace = ok and built == true
				portraitKeeper = if hasFace then keeper else nil
			end
		end
		viewport.Visible = hasFace
		portraitIcon.Text = if hasFace then "" else (icon or "💬")
	end

	-- info = { Name, Colors, Icon, Portrait = Model? }
	function dialogue.Open(info)
		token += 1
		isOpen = true
		typing = false
		clearOptions()
		local stale = waiting
		waiting = nil
		if stale then
			task.spawn(stale, nil)
		end
		local colors = info.Colors or Theme.Colors.Pink
		nameLabel.Text = info.Name or "???"
		Components.SetColors(ribbon, colors)
		Components.SetColors(portrait, colors)
		setPortrait(info.Portrait, info.Icon)
		line.Text = ""

		box.Visible = true
		local target = fitScale()
		scale.Scale = target * 0.5
		TweenService:Create(scale, POP_IN, { Scale = target }):Play()
	end

	function dialogue.Say(text: string)
		if not isOpen then
			error(Dialogue.Closed, 0)
		end
		local myToken = token
		clearOptions()

		line.Text = text
		-- Count what's visible (rich text tags don't show).
		local plain = string.gsub(text, "<[^>]->", "")
		local letters = {}
		pcall(function()
			for first, last in utf8.graphemes(plain) do
				table.insert(letters, string.sub(plain, first, last))
			end
		end)

		skip = false
		typing = true
		line.MaxVisibleGraphemes = 0
		local shown, budget, sinceBlip = 0, 0, BLIP_EVERY
		while shown < #letters do
			local dt = task.wait()
			if token ~= myToken then
				typing = false
				error(Dialogue.Closed, 0)
			end
			if skip then
				break
			end
			budget += dt * LETTERS_PER_SECOND
			while budget >= 1 and shown < #letters do
				budget -= 1
				shown += 1
				local letter = letters[shown]
				if letter ~= " " then
					sinceBlip += 1
				end
				local pause = PUNCTUATION_PAUSE[letter]
				if pause and shown < #letters then
					budget -= pause * LETTERS_PER_SECOND
				end
			end
			line.MaxVisibleGraphemes = shown
			if sinceBlip >= BLIP_EVERY then
				sinceBlip = 0
				playBlip()
			end
		end
		line.MaxVisibleGraphemes = -1
		typing = false
	end

	-- options = { { Text = string, Colors = { Color3, Color3 }? }, ... } (up to 4)
	function dialogue.Choose(options): number
		if not isOpen then
			error(Dialogue.Closed, 0)
		end
		local myToken = token
		clearOptions()

		local thread = coroutine.running()
		for index, option in options do
			local function pickThis()
				if waiting ~= thread then
					return
				end
				waiting = nil
				task.spawn(thread, index)
			end
			pickers[index] = pickThis
			table.insert(optionButtons, makeOption(index, option, pickThis))
		end
		bindKeys()
		local lastInput = UserInputService:GetLastInputType()
		if optionButtons[1] and lastInput.Name:find("Gamepad") then
			GuiService.SelectedObject = optionButtons[1]
		end

		waiting = thread
		local picked = coroutine.yield()
		clearOptions()
		if token ~= myToken or type(picked) ~= "number" then
			error(Dialogue.Closed, 0)
		end
		return picked
	end

	function dialogue.Close()
		if not isOpen then
			return
		end
		isOpen = false
		typing = false
		token += 1
		clearOptions()

		-- Wake up a Choose that's waiting so its conversation can stop.
		local thread = waiting
		waiting = nil
		if thread then
			task.spawn(thread, nil)
		end

		local myToken = token
		local tween = TweenService:Create(scale, POP_OUT, { Scale = scale.Scale * 0.6 })
		tween:Play()
		tween.Completed:Once(function()
			if token == myToken and not isOpen then
				box.Visible = false
			end
		end)
	end

	function dialogue.IsOpen(): boolean
		return isOpen
	end

	-- Click the box to show the whole line at once.
	box.Activated:Connect(function()
		if typing then
			skip = true
		end
	end)

	-- The portrait bobs while they talk.
	local bob = 0
	RunService.RenderStepped:Connect(function(dt)
		if not box.Visible then
			return
		end
		bob += ((if typing then 1 else 0) - bob) * math.min(1, dt * 10)
		local offset = math.abs(math.sin(os.clock() * 12)) * 5 * bob
		portrait.Position = UDim2.new(0, -26, 0.5, -8 - offset)
	end)

	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if isOpen then
				scale.Scale = fitScale()
			end
		end)
	end

	return dialogue
end

return Dialogue
