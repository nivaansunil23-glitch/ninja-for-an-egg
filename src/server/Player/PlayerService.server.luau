-- Applies jump power (vertex tier + held gear), tracks best height and pays
-- out income from equipped pets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local HEIGHT_CHECK_SECONDS = 0.5
local INCOME_SECONDS = 1

local function getJumpPower(player: Player): number
	local data = PlayerData.Get(player)
	local tier = VertexConfig.Get(data and data.VertexTier or 1)
	local power = if tier then tier.JumpPower else VertexConfig.DefaultJumpPower

	local character = player.Character
	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") then
				local gear = GearConfig.Items[child:GetAttribute("GearId")]
				if gear and gear.JumpMultiplier then
					power *= gear.JumpMultiplier
				end
			end
		end
	end
	return math.floor(power + 0.5)
end

local function refreshJump(player: Player)
	local power = getJumpPower(player)
	player:SetAttribute("JumpPower", power)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = power
	end
end

local function onCharacter(player: Player, character: Model)
	if not character:WaitForChild("Humanoid", 10) then
		return
	end
	refreshJump(player)
	-- Holding or putting away gear (e.g. the Jump Coil) changes jump power.
	local function onToolChanged(child)
		if child:IsA("Tool") then
			refreshJump(player)
		end
	end
	character.ChildAdded:Connect(onToolChanged)
	character.ChildRemoved:Connect(onToolChanged)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

-- Buying a vertex goes through MarkDirty, which fires Changed.
PlayerData.Loaded:Connect(refreshJump)
PlayerData.Changed:Connect(refreshJump)
for _, player in Players:GetPlayers() do
	if PlayerData.Get(player) then
		refreshJump(player)
	end
end

local function groundY(): number
	local value = Workspace:GetAttribute("GroundY")
	return if type(value) == "number" then value else PlayerConfig.GroundY
end

-- Best height, checked on the server so it can't be faked by the client.
task.spawn(function()
	while true do
		task.wait(HEIGHT_CHECK_SECONDS)
		local base = groundY()
		for _, player in Players:GetPlayers() do
			local data = PlayerData.Get(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if data and root then
				local height = math.max(0, math.floor(root.Position.Y - base))
				if height > data.BestHeight then
					PlayerData.SetStat(player, "BestHeight", height)
				end
			end
		end
	end
end)

-- Equipped pets earn money every second.
task.spawn(function()
	while true do
		task.wait(INCOME_SECONDS)
		for _, player in Players:GetPlayers() do
			local data = PlayerData.Get(player)
			if data then
				local income = 0
				for _, pet in data.Pets do
					if pet.Equipped then
						income += SellConfig.GetIncome(pet)
					end
				end
				player:SetAttribute("Income", income)
				if income > 0 then
					PlayerData.AddMoney(player, income)
				end
			end
		end
	end
end)
