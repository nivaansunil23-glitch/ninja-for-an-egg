--!nonstrict
-- Thin bridge to the shared player profile (src/server/Player/PlayerData.luau,
-- owned by the player/shop code). Eggs never open their own DataStore.
--
-- Uses from PlayerData:
--   WaitForData(player) -> data     data.Eggs is our saved table for pen eggs
--   AddPet(player, pet) -> petId
--   MarkDirty(player)
--
-- If PlayerData isn't in the place yet, eggs keep working with in-memory data
-- that isn't saved, so the egg code can be tried on its own.

local ServerScriptService = game:GetService("ServerScriptService")

local EggSave = {}

local playerData = nil
local fallback = {} -- [Player] = data, only used without PlayerData

local function getPlayerData()
	if playerData ~= nil then
		return playerData or nil
	end
	local server = ServerScriptService:FindFirstChild("Server")
	local folder = server and server:WaitForChild("Player", 5)
	local module = folder and folder:WaitForChild("PlayerData", 5)
	if module then
		playerData = require(module)
	else
		warn("[Eggs] PlayerData module not found. Pets and pen eggs will NOT be saved.")
		playerData = false
	end
	return playerData or nil
end

-- Returns the player's saved data with a .Eggs table, or nil if they left.
function EggSave.WaitForData(player)
	local pd = getPlayerData()
	local data
	if pd then
		data = pd.WaitForData(player)
	else
		data = fallback[player] or { Pets = {} }
		fallback[player] = data
	end
	if not data then
		return nil
	end
	if type(data.Eggs) ~= "table" then
		data.Eggs = {}
	end
	-- data.Eggs.Pens[nestKey] = egg data with ReadyAt
	if type(data.Eggs.Pens) ~= "table" then
		data.Eggs.Pens = {}
	end
	return data
end

function EggSave.AddPet(player, pet)
	local pd = getPlayerData()
	if pd then
		return pd.AddPet(player, pet)
	end
	local data = EggSave.WaitForData(player)
	if data then
		table.insert(data.Pets, pet)
	end
	return nil
end

function EggSave.MarkDirty(player)
	local pd = getPlayerData()
	if pd and pd.MarkDirty then
		pd.MarkDirty(player)
	end
end

function EggSave.Forget(player)
	fallback[player] = nil
end

return EggSave
