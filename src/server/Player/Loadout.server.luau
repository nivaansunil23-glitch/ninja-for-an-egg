-- Picks from the Inventory: which owned Shoes / Coil / Vertex you use, and
-- the jump power you want (HUD Jump control).
--
-- Remotes:
--   EquipItem (Function)   kind = "Shoes" | "Coil" | "Vertex", tier (0 = your best)
--   SetJumpChoice (Event)  power (0 or anything at/above your max = always max)
-- Saved in data.EquippedShoes / EquippedCoil / EquippedVertex / JumpChoice.
-- Trampolines use TrainingService's EquipTrampoline.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local JumpBalance = require(Config:WaitForChild("JumpBalance"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local JumpPower = require(script.Parent:WaitForChild("JumpPower"))
local Wearables = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Shops"):WaitForChild("Wearables"))

local equipRemote = Net.Function("EquipItem")
local jumpRemote = Net.Event("SetJumpChoice")

local function whole(n): boolean
	return type(n) == "number" and n == n and n % 1 == 0
end

equipRemote.OnServerInvoke = function(player, kind, tier)
	if not whole(tier) then
		return false, "Invalid item"
	end
	local data = PlayerData.Get(player)
	if not data then
		return false, "Still loading, try again"
	end

	if kind == "Shoes" or kind == "Coil" then
		local item = GearConfig.Get(kind, tier)
		if tier ~= 0 and not (item and data.Gear[item.Id]) then
			return false, "Buy it first"
		end
		data["Equipped" .. kind] = tier
		PlayerData.MarkDirty(player)
		Wearables.Refresh(player)
		JumpPower.Refresh(player)
		if not item then
			return true, "Wearing your best " .. GearConfig.Lines[kind].Name:lower()
		end
		return true, if kind == "Shoes" then `{item.Name} on your feet` else `{item.Name} on your back`
	elseif kind == "Vertex" then
		local entry = VertexConfig.Get(tier)
		if tier ~= 0 and not (entry and tier <= data.VertexTier) then
			return false, "Buy it first"
		end
		data.EquippedVertex = tier
		PlayerData.MarkDirty(player)
		JumpPower.Refresh(player)
		return true, if entry then `Using the {entry.Name}: {VertexConfig.PerkText(entry)}` else "Using your best vertex"
	end
	return false, "Invalid item"
end

jumpRemote.OnServerEvent:Connect(function(player, power)
	if type(power) ~= "number" or power ~= power then
		return
	end
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local max = JumpPower.Max(player)
	local choice = if power <= 0 or power >= max then 0 else math.clamp(math.floor(power + 0.5), JumpBalance.BaseJump, max)
	if data.JumpChoice == choice then
		return
	end
	data.JumpChoice = choice
	PlayerData.MarkDirty(player)
	JumpPower.Refresh(player)
end)
