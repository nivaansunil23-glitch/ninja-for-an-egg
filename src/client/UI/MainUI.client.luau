-- Builds the main UI: HUD plus the Shop and Inventory windows.
-- Shop spots on the map open the matching shop tab through OpenShop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local ShopPanel = require(script.Parent:WaitForChild("ShopPanel"))
local InventoryPanel = require(script.Parent:WaitForChild("InventoryPanel"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MainUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local shop = ShopPanel.new(gui)
local inventory = InventoryPanel.new(gui)
local windows = { shop, inventory }

-- Only one window open at a time.
local function show(panel, ...)
	for _, other in windows do
		if other ~= panel and other.IsOpen() then
			other.Close()
		end
	end
	panel.Open(...)
end

local function toggle(panel, ...)
	if panel.IsOpen() then
		panel.Close()
	else
		show(panel, ...)
	end
end

Hud.Build(gui, {
	Shop = function()
		toggle(shop)
	end,
	Pets = function()
		-- Logo only for now; the pet index comes later.
		Components.Notify(gui, "🐾 Pet Index coming soon!", Theme.Colors.Mint[1])
	end,
	Inventory = function()
		toggle(inventory)
	end,
})

Net.Event("OpenShop").OnClientEvent:Connect(function(shopType)
	show(shop, shopType)
end)
