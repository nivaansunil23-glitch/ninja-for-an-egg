--!nonstrict
-- Client side of eggs: hides prompts that aren't for you (your own steal
-- prompt, other players' pens) and shows simple egg notifications until the
-- real UI is built. The UI can listen to ReplicatedStorage.EggRemotes.EggNotify too.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local EggRemotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EggRemotes"))

local player = Players.LocalPlayer

local function notMine(prompt)
	local hideFor = prompt:GetAttribute("HideForUserId")
	local owner = prompt:GetAttribute("OwnerUserId")
	return hideFor == player.UserId or (owner ~= nil and owner ~= player.UserId)
end

local function check(prompt)
	if prompt:IsA("ProximityPrompt") and notMine(prompt) then
		prompt.Enabled = false
	end
end

for _, d in workspace:GetDescendants() do
	check(d)
end
workspace.DescendantAdded:Connect(check)
-- The server re-enables pen prompts when their state changes; hide them again.
ProximityPromptService.PromptShown:Connect(check)

local function toast(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
	end)
end

local MESSAGES = {
	PickedUp = function(i)
		return "Egg grabbed", string.format("%s · %.1f kg", i.Name, i.Kg)
	end,
	StoleEgg = function(i)
		return "Stolen!", string.format("You took %s's %s", i.Other, i.Name)
	end,
	Stolen = function(i)
		return "Egg stolen!", string.format("%s took your %s", i.Other, i.Name)
	end,
	EggCracked = function(i)
		return "Crack!", string.format("%s cracked (%d/%d)", i.Name, i.Cracks, i.MaxCracks)
	end,
	EggBroke = function(i)
		return "Egg broke!", string.format("Your %s smashed", i.Name)
	end,
	EggDropped = function(i)
		return "Egg dropped", string.format("Your %s fell where you were", i.Name)
	end,
	EggPlaced = function(i)
		return "Egg growing", string.format("%s placed in your pen", i.Name)
	end,
	-- "Hatched" plays the hatch animation (UI/HatchReveal) instead of a toast.
	PenUpgraded = function(i)
		return "Pen upgraded!", string.format("Level %d · x%s cash", i.Level, tostring(i.Multiplier))
	end,
	Info = function(i)
		return "Eggs", i.Text
	end,
}

EggRemotes.EggNotify.OnClientEvent:Connect(function(kind, info)
	local make = MESSAGES[kind]
	if make then
		toast(make(info))
	end
end)
