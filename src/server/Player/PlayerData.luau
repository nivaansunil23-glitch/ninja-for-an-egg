-- The one saved profile per player (DataStore). Every system that needs saved
-- player state goes through this module instead of opening its own DataStore.
--
-- API:
--   PlayerData.Get(player) -> data | nil
--   PlayerData.WaitForData(player) -> data | nil (nil if they left first)
--   PlayerData.AddMoney(player, amount) -> bool
--   PlayerData.SpendMoney(player, amount) -> bool
--   PlayerData.SetStat(player, key, value)  -- simple values like BestHeight, no full resync
--   PlayerData.AddPet(player, { Name, Rarity, Weight, Egg?, Value?, ... }) -> petId
--   PlayerData.RemovePet(player, petId) -> pet | nil
--   PlayerData.MarkDirty(player)  -- call after editing data tables directly; saves + resyncs the client
--   PlayerData.Loaded:Connect(function(player, data) end)
--   PlayerData.Changed:Connect(function(player, data) end)  -- after any MarkDirty

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local PlayerConfig = require(Shared:WaitForChild("Config"):WaitForChild("PlayerConfig"))

local TEMPLATE = {
	Money = 0,
	VertexTier = 1,
	BestHeight = 0,
	-- Jump training (Training/TrainingService, numbers in Shared.Config.JumpBalance)
	JumpLevel = 1,
	JumpXP = 0, -- XP into the current level
	TrampolineTier = 1,
	IslandReached = 0, -- highest island stood on (0 = base)
	Gear = {}, -- [gearId] = true
	Pets = {}, -- [petId] = { Name, Rarity, Weight, Egg, Value, Equipped }
	Eggs = {}, -- free space for the egg systems (pens, growing eggs)
	Stats = {
		PetsSold = 0,
		MoneyEarned = 0,
	},
}

-- Values mirrored onto the player as attributes and leaderstats.
local LEADERSTATS = {
	Money = "Money",
	BestHeight = "Best Height",
}

local PlayerData = {}

local loadedEvent = Instance.new("BindableEvent")
local changedEvent = Instance.new("BindableEvent")
PlayerData.Loaded = loadedEvent.Event
PlayerData.Changed = changedEvent.Event

local syncRemote = Net.Event("DataSync")
local getDataRemote = Net.Function("GetData")

-- [Player] = { Data, CanSave, Dirty, SyncQueued }
local sessions = {}

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(PlayerConfig.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore unavailable, progress will not save:", result)
	end
end

local function keyFor(userId: number): string
	return "Player_" .. userId
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in value do
		copy[key] = deepCopy(item)
	end
	return copy
end

-- Fill in any fields added to TEMPLATE since the save was made.
local function reconcile(data, template)
	for key, value in template do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
end

-- What the client gets. Eggs stay server-side; the egg systems sync their own UI.
local function snapshot(data)
	return {
		Money = data.Money,
		VertexTier = data.VertexTier,
		BestHeight = data.BestHeight,
		JumpLevel = data.JumpLevel,
		JumpXP = data.JumpXP,
		TrampolineTier = data.TrampolineTier,
		IslandReached = data.IslandReached,
		Gear = data.Gear,
		Pets = data.Pets,
	}
end

local function setMirrored(player: Player, key: string, value)
	player:SetAttribute(key, value)
	local statName = LEADERSTATS[key]
	local leaderstats = statName and player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	if stat then
		stat.Value = value
	end
end

local function applyAttributes(player: Player, data)
	setMirrored(player, "Money", data.Money)
	setMirrored(player, "BestHeight", data.BestHeight)
	setMirrored(player, "VertexTier", data.VertexTier)
	setMirrored(player, "JumpLevel", data.JumpLevel)
	setMirrored(player, "JumpXP", data.JumpXP)
	setMirrored(player, "TrampolineTier", data.TrampolineTier)
	setMirrored(player, "IslandReached", data.IslandReached)
end

local function queueSync(player: Player)
	local session = sessions[player]
	if not session or session.SyncQueued then
		return
	end
	session.SyncQueued = true
	task.defer(function()
		session.SyncQueued = false
		if sessions[player] ~= session then
			return
		end
		applyAttributes(player, session.Data)
		syncRemote:FireClient(player, snapshot(session.Data))
		changedEvent:Fire(player, session.Data)
	end)
end

local function save(player: Player, session)
	if not store or not session.CanSave or not session.Dirty then
		return
	end
	session.Dirty = false
	local data = session.Data
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player.UserId), function()
			return data
		end)
	end)
	if not ok then
		session.Dirty = true
		warn("[PlayerData] Save failed for", player.Name, err)
	end
end

local function makeLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for key, statName in LEADERSTATS do
		local stat = Instance.new("IntValue")
		stat.Name = statName
		stat.Value = data[key]
		stat.Parent = leaderstats
	end
	leaderstats.Parent = player
end

local function load(player: Player)
	local data = nil
	local canSave = store ~= nil

	if store then
		local ok, result
		for attempt = 1, 3 do
			ok, result = pcall(function()
				return store:GetAsync(keyFor(player.UserId))
			end)
			-- Studio without API access fails every time, so don't keep retrying.
			if ok or tostring(result):find("Studio") then
				break
			end
			task.wait(attempt * 2)
		end
		if ok then
			data = result
		else
			-- Never overwrite a real save with a blank profile.
			canSave = false
			warn("[PlayerData] Could not load", player.Name, "- this session will not save:", result)
		end
	end

	if type(data) ~= "table" then
		data = deepCopy(TEMPLATE)
		data.Money = PlayerConfig.StartingMoney
	end
	reconcile(data, TEMPLATE)

	if player.Parent ~= Players then
		return
	end

	makeLeaderstats(player, data)
	sessions[player] = {
		Data = data,
		CanSave = canSave,
		Dirty = false,
		SyncQueued = false,
	}
	applyAttributes(player, data)
	loadedEvent:Fire(player, data)
	queueSync(player)
end

function PlayerData.Get(player: Player)
	local session = sessions[player]
	return session and session.Data
end

function PlayerData.WaitForData(player: Player)
	while player.Parent == Players and not sessions[player] do
		task.wait(0.1)
	end
	return PlayerData.Get(player)
end

function PlayerData.MarkDirty(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	session.Dirty = true
	queueSync(player)
end

function PlayerData.SetStat(player: Player, key: string, value)
	local session = sessions[player]
	if not session then
		return
	end
	session.Data[key] = value
	session.Dirty = true
	setMirrored(player, key, value)
end

function PlayerData.AddMoney(player: Player, amount: number): boolean
	local session = sessions[player]
	if not session or type(amount) ~= "number" or amount ~= amount then
		return false
	end
	local data = session.Data
	if amount > 0 then
		data.Stats.MoneyEarned += math.floor(amount)
	end
	PlayerData.SetStat(player, "Money", math.max(0, math.floor(data.Money + amount)))
	return true
end

function PlayerData.SpendMoney(player: Player, amount: number): boolean
	local session = sessions[player]
	if not session or type(amount) ~= "number" or amount ~= amount or amount < 0 then
		return false
	end
	if session.Data.Money < amount then
		return false
	end
	PlayerData.SetStat(player, "Money", math.floor(session.Data.Money - amount))
	return true
end

function PlayerData.AddPet(player: Player, pet): string?
	local session = sessions[player]
	if not session or type(pet) ~= "table" then
		return nil
	end
	local entry = deepCopy(pet)
	entry.Name = tostring(pet.Name or "Pet")
	entry.Rarity = pet.Rarity or "Common"
	entry.Weight = tonumber(pet.Weight) or 1
	entry.Equipped = false

	local id = HttpService:GenerateGUID(false)
	session.Data.Pets[id] = entry
	PlayerData.MarkDirty(player)
	return id
end

function PlayerData.RemovePet(player: Player, petId: string)
	local session = sessions[player]
	local pet = session and session.Data.Pets[petId]
	if not pet then
		return nil
	end
	session.Data.Pets[petId] = nil
	PlayerData.MarkDirty(player)
	return pet
end

getDataRemote.OnServerInvoke = function(player)
	local data = PlayerData.WaitForData(player)
	return data and snapshot(data)
end

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	save(player, session)
end)

task.spawn(function()
	while true do
		task.wait(PlayerConfig.AutosaveSeconds)
		for player, session in sessions do
			task.spawn(save, player, session)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player, session in sessions do
		pending += 1
		task.spawn(function()
			save(player, session)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)

return PlayerData
