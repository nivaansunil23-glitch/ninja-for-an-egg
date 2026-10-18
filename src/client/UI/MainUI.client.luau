-- Builds the main UI: HUD plus the Shop, Inventory and Pet Index windows.
-- Talking to a shopkeeper on the map (TalkToShop) runs their conversation in
-- ShopTalk, which opens their shop. OpenShop opens a shop tab straight away.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local ShopPanel = require(script.Parent:WaitForChild("ShopPanel"))
local InventoryPanel = require(script.Parent:WaitForChild("InventoryPanel"))
local IndexPanel = require(script.Parent:WaitForChild("IndexPanel"))
local ShopTalk = require(script.Parent:WaitForChild("ShopTalk"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MainUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local shop = ShopPanel.new(gui)
local inventory = InventoryPanel.new(gui)
local index = IndexPanel.new(gui)
local windows = { shop, inventory, index }

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
	TweenService:Create(blur, TweenInfo.new(0.25), { Size = if anyOpen then 6 else 0 }):Play()
end
for _, panel in windows do
	panel.Window.Frame:GetPropertyChangedSignal("Visible"):Connect(updateBlur)
end

Hud.Build(gui, {
	Shop = function()
		toggle(shop)
	end,
	Index = function()
		toggle(index)
	end,
	IndexReady = index.ReadyCount,
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
