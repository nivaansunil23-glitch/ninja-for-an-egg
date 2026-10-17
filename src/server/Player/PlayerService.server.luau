-- Applies jump power (trained level x vertex x held gear, see JumpPower),
-- tracks best height and the highest island stood on, and pays out income
-- from equipped pets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local JumpPower = require(script.Parent:WaitForChild("JumpPower"))

local HEIGHT_CHECK_SECONDS = 0.5
local INCOME_SECONDS = 1
local ISLAND_CHECK_DISTANCE = 7 -- studs below the root that still counts as standing on it

local function onCharacter(player: Player, character: Model)
	if not character:WaitForChild("Humanoid", 10) then
		return
	end
	JumpPower.Refresh(player)
	-- Holding or putting away gear (e.g. the Jump Coil) changes jump power.
	local function onToolChanged(child)
		if child:IsA("Tool") then
			JumpPower.Refresh(player)
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
PlayerData.Loaded:Connect(JumpPower.Refresh)
PlayerData.Changed:Connect(JumpPower.Refresh)
for _, player in Players:GetPlayers() do
	if PlayerData.Get(player) then
		JumpPower.Refresh(player)
	end
end

local function groundY(): number
	local value = Workspace:GetAttribute("GroundY")
	return if type(value) == "number" then value else PlayerConfig.GroundY
end

local islandRay = RaycastParams.new()
islandRay.FilterType = Enum.RaycastFilterType.Exclude

-- The island number of whatever this part belongs to (nil if not an island).
local function islandNumberOf(part: Instance): number?
	local map = Workspace:FindFirstChild("Map")
	local islands = map and map:FindFirstChild("Islands")
	if not islands or not part:IsDescendantOf(islands) then
		return nil
	end
	local node = part
	while node.Parent ~= islands do
		node = node.Parent
	end
	local number = node:GetAttribute("IslandNumber")
	return if type(number) == "number" then number else nil
end

-- Best height and the highest island stood on, checked on the server so they
-- can't be faked by the client.
task.spawn(function()
	while true do
		task.wait(HEIGHT_CHECK_SECONDS)
		local base = groundY()
		for _, player in Players:GetPlayers() do
			local data = PlayerData.Get(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if data and root then
				local height = math.max(0, math.floor(root.Position.Y - base))
				if height > data.BestHeight then
					PlayerData.SetStat(player, "BestHeight", height)
				end

				islandRay.FilterDescendantsInstances = { character }
				local hit = Workspace:Raycast(root.Position, Vector3.new(0, -ISLAND_CHECK_DISTANCE, 0), islandRay)
				local island = hit and islandNumberOf(hit.Instance)
				if island and island > data.IslandReached then
					PlayerData.SetStat(player, "IslandReached", island)
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
