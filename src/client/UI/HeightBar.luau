-- Height progress bar along the bottom, like Jump for Phonk: a big height
-- counter above a green > yellow > orange > red bar, your face riding along it,
-- and a locked "?" bubble for every island that unlocks once you've climbed
-- that high (BestHeight) or stood on it (IslandReached).
-- Islands sit evenly along the bar, so the first ones aren't squashed together.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local JumpBalance = require(Shared:WaitForChild("Config"):WaitForChild("JumpBalance"))
local PlayerConfig = require(Shared:WaitForChild("Config"):WaitForChild("PlayerConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))

local player = Players.LocalPlayer

local HeightBar = {}

local BAR_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 230, 110)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 225, 70)),
	ColorSequenceKeypoint.new(0.68, Color3.fromRGB(255, 150, 45)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 60, 70)),
})
local LOCKED = { Color3.fromRGB(60, 80, 130), Color3.fromRGB(25, 35, 70) } -- dark navy "?" like Jump for Phonk
local UNLOCK_POP = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function groundY(): number
	local value = Workspace:GetAttribute("GroundY")
	return if type(value) == "number" then value else PlayerConfig.GroundY
end

-- 0..1 along the bar: milestone i sits at i / #milestones.
local function barRatio(milestones, height: number): number
	local count = #milestones
	if count == 0 then
		return 0
	end
	local below = 0
	for i, milestone in milestones do
		if height < milestone.Height then
			local span = math.max(milestone.Height - below, 1)
			return (i - 1 + (height - below) / span) / count
		end
		below = milestone.Height
	end
	return 1
end

local function isUnlocked(milestone): boolean
	local best = player:GetAttribute("BestHeight") or 0
	local reached = player:GetAttribute("IslandReached") or 0
	return best >= milestone.Height or reached >= milestone.Number
end

function HeightBar.Build(gui: ScreenGui)
	local holder = Instance.new("Frame")
	holder.Name = "HeightBar"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(0.46, 0.13)
	holder.Position = UDim2.new(0.5, 0, 1, -8)
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(300, 70)
	limits.MaxSize = Vector2.new(760, 120)
	limits.Parent = holder

	-- Height counter, above the bar.
	local heightLabel = Components.Label({
		Name = "Height",
		Text = "0m",
		Parent = holder,
		Size = UDim2.fromScale(0.3, 0.36),
		Position = UDim2.fromScale(0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		MaxTextSize = 40,
		StrokeThickness = 3,
	})
	local bestLabel = Components.Label({
		Name = "Best",
		Text = "🏆 0m",
		Parent = holder,
		Size = UDim2.fromScale(0.2, 0.24),
		Position = UDim2.fromScale(0, 0.08),
		XAlign = Enum.TextXAlignment.Left,
		Color = Theme.Colors.Yellow[1],
		MaxTextSize = 24,
	})
	local nextLabel = Components.Label({
		Name = "Next",
		Text = "",
		Parent = holder,
		Size = UDim2.fromScale(0.32, 0.24),
		Position = UDim2.fromScale(1, 0.08),
		AnchorPoint = Vector2.new(1, 0),
		XAlign = Enum.TextXAlignment.Right,
		MaxTextSize = 22,
	})

	-- The bar: a dark track, and a fill that shows the full rainbow up to where you are.
	local track = Components.Box({
		Name = "Track",
		Parent = holder,
		Size = UDim2.fromScale(1, 0.26),
		Position = UDim2.fromScale(0, 0.7),
		Colors = { Color3.fromRGB(80, 65, 120), Color3.fromRGB(50, 35, 85) },
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 3,
	})
	local fillClip = Instance.new("Frame")
	fillClip.Name = "Fill"
	fillClip.BackgroundTransparency = 1
	fillClip.ClipsDescendants = true
	fillClip.Size = UDim2.fromScale(0, 1)
	fillClip.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Colors"
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	Components.Corner(fill, UDim.new(1, 0))
	local gradient = Instance.new("UIGradient")
	gradient.Color = BAR_COLORS
	gradient.Parent = fill
	fill.Parent = fillClip
	Components.Shine(track, 0.3)

	-- Your face riding the bar, and a gold tick for your best.
	local bestTick = Components.Box({
		Name = "BestTick",
		Parent = track,
		Size = UDim2.new(0, 6, 1.5, 0),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Colors = Theme.Colors.Yellow,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		ZIndex = 3,
	})
	local you = Instance.new("ImageLabel")
	you.Name = "You"
	you.Size = UDim2.fromScale(1.9, 1.9)
	you.SizeConstraint = Enum.SizeConstraint.RelativeYY
	you.AnchorPoint = Vector2.new(0.5, 0.5)
	you.Position = UDim2.fromScale(0, 0.5)
	you.BackgroundColor3 = Color3.new(1, 1, 1)
	you.ZIndex = 5
	Components.Corner(you, UDim.new(1, 0))
	Components.Stroke(you, 3)
	you.Parent = track
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok then
			you.Image = image
		end
	end)

	-- Milestone bubbles sit on the bar; they're rebuilt if the islands change
	-- (the map can stream in after the UI starts).
	local milestones = {}
	local bubbles = {}
	local signature = ""

	local function styleBubble(entry, unlocked: boolean)
		local milestone = entry.Milestone
		Components.SetColors(entry.Bubble, if unlocked then Theme.Colors.Mint else LOCKED)
		entry.Icon.Text = if unlocked then tostring(milestone.Number) else "?"
		entry.Name.Text = Format.Short(milestone.Height) .. "m"
		entry.Unlocked = unlocked
	end

	local function rebuild(list)
		for _, entry in bubbles do
			entry.Bubble:Destroy()
		end
		table.clear(bubbles)
		milestones = list
		for i, milestone in list do
			local bubble = Components.Box({
				Name = "Milestone" .. milestone.Number,
				Parent = track,
				Size = UDim2.fromScale(1.75, 1.75),
				Position = UDim2.fromScale(i / #list, 0.5),
				AnchorPoint = Vector2.new(if i == #list then 0.75 else 0.5, 0.5),
				Colors = LOCKED,
				CornerRadius = UDim.new(1, 0),
				StrokeThickness = 3,
				ZIndex = 4,
			})
			bubble.SizeConstraint = Enum.SizeConstraint.RelativeYY
			local icon = Components.Label({
				Name = "Icon",
				Text = "?",
				Parent = bubble,
				Size = UDim2.fromScale(0.7, 0.7),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				MaxTextSize = 30,
				ZIndex = 4,
			})
			local name = Components.Label({
				Name = "IslandName",
				Text = "",
				Parent = bubble,
				Size = UDim2.fromScale(2.2, 0.6),
				Position = UDim2.fromScale(0.5, -0.05),
				AnchorPoint = Vector2.new(0.5, 1),
				MaxTextSize = 16,
				ZIndex = 4,
			})
			local entry = { Bubble = bubble, Icon = icon, Name = name, Milestone = milestone }
			styleBubble(entry, isUnlocked(milestone))
			table.insert(bubbles, entry)
		end
	end

	local function refreshMilestones()
		local list = JumpBalance.Milestones()
		table.sort(list, function(a, b)
			return a.Height < b.Height
		end)
		local parts = {}
		for _, milestone in list do
			table.insert(parts, milestone.Name .. "@" .. math.floor(milestone.Height))
		end
		local newSignature = table.concat(parts, ",")
		if newSignature ~= signature then
			signature = newSignature
			rebuild(list)
		end
	end

	local function checkUnlocks()
		for _, entry in bubbles do
			local unlocked = isUnlocked(entry.Milestone)
			if unlocked and not entry.Unlocked then
				styleBubble(entry, true)
				local scale = entry.Bubble:FindFirstChild("PopScale") or Instance.new("UIScale")
				scale.Name = "PopScale"
				scale.Scale = 0.2
				scale.Parent = entry.Bubble
				TweenService:Create(scale, UNLOCK_POP, { Scale = 1 }):Play()
				Components.Burst(gui, Components.CenterOf(entry.Bubble), { "⭐", "✨", "🎉" })
				Components.Notify(gui, "🏝️ " .. entry.Milestone.Name .. " unlocked!", Theme.Colors.Mint[1])
			elseif not unlocked and entry.Unlocked then
				styleBubble(entry, false)
			end
		end
	end

	local function nextMilestone()
		for _, milestone in milestones do
			if not isUnlocked(milestone) then
				return milestone
			end
		end
		return nil
	end

	local function updateNext()
		local milestone = nextMilestone()
		-- Only the next locked island shows its height, so labels never overlap.
		for _, entry in bubbles do
			entry.Name.Visible = entry.Milestone == milestone
		end
		if not milestone then
			nextLabel.Text = "👑 Top reached!"
			nextLabel.TextColor3 = Theme.Colors.Yellow[1]
			return
		end
		local level = player:GetAttribute("JumpLevel") or 1
		local ready = level >= milestone.RequiredLevel
		nextLabel.Text = string.format("Next: %s · Lv %d", milestone.Name, milestone.RequiredLevel)
		nextLabel.TextColor3 = if ready then Theme.Colors.Mint[1] else Theme.Text
	end

	refreshMilestones()
	checkUnlocks()
	updateNext()
	for _, name in { "BestHeight", "IslandReached" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			checkUnlocks()
			updateNext()
		end)
	end
	player:GetAttributeChangedSignal("JumpLevel"):Connect(updateNext)
	task.spawn(function()
		while holder.Parent do
			task.wait(5)
			refreshMilestones()
			checkUnlocks()
			updateNext()
		end
	end)

	local shownHeight = -1
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local height = if root then math.max(0, math.floor(root.Position.Y - groundY())) else 0
		local best = player:GetAttribute("BestHeight") or 0

		local ratio = barRatio(milestones, height)
		fillClip.Size = UDim2.fromScale(ratio, 1)
		-- Keep the rainbow fixed to the whole bar while the clip grows.
		fill.Size = UDim2.fromScale(if ratio > 0 then 1 / ratio else 1, 1)
		you.Position = UDim2.fromScale(ratio, 0.5)
		bestTick.Position = UDim2.fromScale(barRatio(milestones, best), 0.5)

		if height ~= shownHeight then
			shownHeight = height
			heightLabel.Text = Format.Short(height) .. "m"
		end
		bestLabel.Text = "🏆 " .. Format.Short(best) .. "m"
	end)

	return holder
end

return HeightBar
