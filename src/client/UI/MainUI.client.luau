-- Builds the main UI: HUD plus the Shop and Inventory windows.
-- Talking to a shopkeeper on the map (TalkToShop) runs their conversation in
-- ShopTalk, which opens their shop. OpenShop opens a shop tab straight away.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Components = require(script.Parent:WaitForChild("Components"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local ShopPanel = require(script.Parent:WaitForChild("ShopPanel"))
local InventoryPanel = require(script.Parent:WaitForChild("InventoryPanel"))
local ShopTalk = require(script.Parent:WaitForChild("ShopTalk"))

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
local function closeWindows(except)
	for _, other in windows do
		if other ~= except and other.IsOpen() then
			other.Close()
		end
	end
end

local function show(panel, ...)
	closeWindows(panel)
	panel.Open(...)
end

local talk = ShopTalk.new(gui, {
	Shop = shop,
	CloseWindows = function()
		closeWindows(nil)
	end,
	OpenShop = function(shopType, context)
		show(shop, shopType, context)
	end,
})

local function toggle(panel, ...)
	if panel.IsOpen() then
		panel.Close()
	else
		talk.Cancel()
		show(panel, ...)
	end
end

-- Soft blur on the world behind open windows.
local blur = Instance.new("BlurEffect")
blur.Name = "MenuBlur"
blur.Size = 0
blur.Parent = Lighting
local function updateBlur()
	local anyOpen = false
	for _, panel in windows do
		anyOpen = anyOpen or panel.IsOpen()
	end
	TweenService:Create(blur, TweenInfo.new(0.25), { Size = if anyOpen then 12 else 0 }):Play()
end
for _, panel in windows do
	panel.Window.Frame:GetPropertyChangedSignal("Visible"):Connect(updateBlur)
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

Net.Event("TalkToShop").OnClientEvent:Connect(function(shopType, keeper, spot)
	talk.Start(shopType, keeper, spot)
end)

Net.Event("OpenShop").OnClientEvent:Connect(function(shopType)
	talk.Cancel()
	show(shop, shopType)
end)
