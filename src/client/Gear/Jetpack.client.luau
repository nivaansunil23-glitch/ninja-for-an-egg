-- Jetpack: while it's held, keep holding jump in the air to fly upward until
-- the fuel runs out. Fuel refills on the ground. Runs on the client because
-- the player's own character physics are client-owned.
-- No lift at night (DayNightConfig); the server also puts the jetpack away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local GearConfig = require(Config:WaitForChild("GearConfig"))
local DayNightConfig = require(Config:WaitForChild("DayNightConfig"))

local JETPACK = GearConfig.Items.Jetpack
local HOLD_WINDOW = 0.15 -- JumpRequest repeats while jump is held

local player = Players.LocalPlayer
local fuel = JETPACK.Fuel
local lastJumpRequest = 0

UserInputService.JumpRequest:Connect(function()
	lastJumpRequest = os.clock()
end)

local function findJetpack(character: Model): Tool?
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("GearId") == "Jetpack" then
			return child
		end
	end
	return nil
end

local function getFlame(tool: Tool): ParticleEmitter?
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return nil
	end
	local flame = handle:FindFirstChild("JetFlame")
	if not flame then
		flame = Instance.new("ParticleEmitter")
		flame.Name = "JetFlame"
		flame.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 110, 140))
		flame.Size = NumberSequence.new(0.6, 0)
		flame.Lifetime = NumberRange.new(0.25, 0.4)
		flame.Rate = 60
		flame.Speed = NumberRange.new(8, 12)
		flame.EmissionDirection = Enum.NormalId.Bottom
		flame.LightEmission = 0.6
		flame.Enabled = false
		flame.Parent = handle
	end
	return flame
end

RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local tool = character and findJetpack(character)

	if not (humanoid and root and tool) or humanoid.Health <= 0 then
		player:SetAttribute("JetpackEquipped", false)
		return
	end
	player:SetAttribute("JetpackEquipped", true)

	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local holding = os.clock() - lastJumpRequest < HOLD_WINDOW or UserInputService:IsKeyDown(Enum.KeyCode.Space)
	local thrusting = holding and not grounded and fuel > 0 and not DayNightConfig.IsNight()

	if thrusting then
		fuel = math.max(0, fuel - dt)
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, JETPACK.ThrustSpeed), velocity.Z)
	elseif grounded then
		fuel = math.min(JETPACK.Fuel, fuel + JETPACK.RefuelPerSecond * dt)
	end

	local flame = getFlame(tool)
	if flame then
		flame.Enabled = thrusting
	end
	player:SetAttribute("JetpackFuel", fuel / JETPACK.Fuel)
end)
