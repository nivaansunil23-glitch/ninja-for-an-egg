-- A bobbing "YOUR PEN" arrow over your own pen, so you can find it from
-- anywhere on the base. Only you see it. Follows the PlotName attribute that
-- PenService sets when you claim a plot.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local HEIGHT = 22 -- studs above the pen floor
local BOB = 1.5
local GREEN = Color3.fromRGB(110, 230, 120)

local gui = Instance.new("BillboardGui")
gui.Name = "YourPenArrow"
gui.Size = UDim2.fromOffset(150, 120)
gui.AlwaysOnTop = true
gui.LightInfluence = 0
gui.MaxDistance = 2000
gui.ResetOnSpawn = false
gui.Enabled = false

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, 0, 0.35, 0)
label.Font = Enum.Font.FredokaOne
label.Text = "YOUR PEN"
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = gui
local labelStroke = Instance.new("UIStroke")
labelStroke.Thickness = 3
labelStroke.Color = Color3.fromRGB(30, 80, 40)
labelStroke.Parent = label

local arrow = Instance.new("TextLabel")
arrow.BackgroundTransparency = 1
arrow.Position = UDim2.fromScale(0, 0.32)
arrow.Size = UDim2.new(1, 0, 0.68, 0)
arrow.Font = Enum.Font.FredokaOne
arrow.Text = "▼"
arrow.TextScaled = true
arrow.TextColor3 = GREEN
arrow.Parent = gui
local arrowStroke = Instance.new("UIStroke")
arrowStroke.Thickness = 3
arrowStroke.Color = Color3.fromRGB(30, 80, 40)
arrowStroke.Parent = arrow

gui.Parent = player:WaitForChild("PlayerGui")

-- The part the arrow floats over: the pen floor, or any part of the plot.
local function anchorFor(plotName: string?): BasePart?
	local map = Workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Pens")
	local plot = pens and plotName and pens:FindFirstChild(plotName)
	if not plot then
		return nil
	end
	local pen = plot:FindFirstChild("Pen")
	local floor = pen and (pen.PrimaryPart or pen:FindFirstChild("Floor", true))
	if floor and floor:IsA("BasePart") then
		return floor
	end
	return plot:FindFirstChildWhichIsA("BasePart", true)
end

local function refresh()
	local anchor = anchorFor(player:GetAttribute("PlotName"))
	gui.Adornee = anchor
	gui.Enabled = anchor ~= nil
end

player:GetAttributeChangedSignal("PlotName"):Connect(refresh)

-- Re-check now and then in case the pen streamed in or out.
task.spawn(function()
	while true do
		if not (gui.Adornee and gui.Adornee.Parent) then
			refresh()
		end
		task.wait(2)
	end
end)

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		gui.StudsOffsetWorldSpace = Vector3.new(0, HEIGHT + math.sin(os.clock() * 3) * BOB, 0)
	end
end)
