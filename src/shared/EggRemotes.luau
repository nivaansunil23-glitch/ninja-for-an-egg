--!nonstrict
-- Remotes for the egg systems, kept in ReplicatedStorage.EggRemotes.
-- The server creates them; clients wait for them.
--
-- EggNotify (server -> client): (kind, info)
--   kind is one of "PickedUp", "Stolen", "StoleEgg", "EggCracked", "EggBroke",
--   "EggDropped", "EggPlaced", "Hatched", "PenUpgraded" ({ Level, Multiplier }), "Info".
--   info has Name, EggId, Kg, Cracks, MaxCracks for egg events, Pet for "Hatched",
--   Other (player name) for steals, and Text for "Info".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "EggRemotes"
local REMOTES = {
	EggNotify = "RemoteEvent",
}

local EggRemotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for name, className in REMOTES do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
		EggRemotes[name] = remote
	end
else
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	for name in REMOTES do
		EggRemotes[name] = folder:WaitForChild(name)
	end
end

return EggRemotes
