-- Talking to a shopkeeper. When the server says you pressed Talk, this runs
-- that shop's conversation in the dialogue box: the shopkeeper turns to you,
-- waves and says hi, then you pick what to do. The buy option opens their
-- shop. Walking away (or closing the shop) ends it, and they wave goodbye in
-- a speech bubble. They cheer when you buy something.
--
-- The lines live in Shared.Config.ShopConfig; the numbers (prices, what your
-- pets are worth, your vertex) are filled in here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local Format = require(Shared:WaitForChild("Format"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local VertexConfig = require(Config:WaitForChild("VertexConfig"))
local SellConfig = require(Config:WaitForChild("SellConfig"))
local PlayerConfig = require(Config:WaitForChild("PlayerConfig"))
local Theme = require(script.Parent:WaitForChild("Theme"))
local Dialogue = require(script.Parent:WaitForChild("Dialogue"))
local Shopkeepers = require(script.Parent:WaitForChild("Shopkeepers"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local player = Players.LocalPlayer

local MONEY_COLOR = "#E8890C"

local function pick(list)
	return list[math.random(#list)]
end

local function money(amount: number): string
	return `<font color="{MONEY_COLOR}">{Format.Money(amount)}</font>`
end

-- Names go into rich text, so keep its special characters out.
local function safe(name: string): string
	return (string.gsub(tostring(name), "[<>&]", ""))
end

local function powerText(entry): string
	return VertexConfig.PerkText(entry)
end

-- Pets the Sell shop would buy right now (equipped ones are never sold).
local function sellable()
	local pets = ClientState.Data and ClientState.Data.Pets or {}
	local summary = { Ids = {}, Total = 0, Best = nil, BestPrice = 0, Equipped = 0 }
	for id, pet in pets do
		if pet.Equipped then
			summary.Equipped += 1
		elseif #summary.Ids < PlayerConfig.MaxSellPerRequest then
			table.insert(summary.Ids, id)
			local price = SellConfig.GetPrice(pet)
			summary.Total += price
			if price > summary.BestPrice then
				summary.Best, summary.BestPrice = pet, price
			end
		end
	end
	return summary
end

local function noPetsLine(summary): string
	if summary.Equipped > 0 then
		return "All your pets are equipped, and I never buy those! Unequip some in your Inventory first."
	end
	return "You don't have any pets yet! Grab an egg from the islands and hatch it in your pen."
end

-- Conversations ------------------------------------------------------------------
-- Each one gets `talk` (see ShopTalk.new) and runs until it returns. Say and
-- Choose throw if the dialogue closes, which simply ends the conversation.

local Conversations = {}

function Conversations.Gear(talk)
	local shop = talk.Shop
	talk.Say(pick(shop.Greetings), "Wave")
	while true do
		local choice = talk.Choose({
			{ Text = shop.Browse, Colors = talk.Colors },
			{ Text = shop.Ask, Colors = Theme.Colors.Sky },
			talk.NeverMind,
		})
		if choice == 1 then
			talk.Say(shop.BrowseReply, "Point")
			return talk.OpenShop()
		elseif choice == 2 then
			local lines = {
				`Shoes go on your feet: better shoes let you fall further with an egg before it cracks.`,
				`Coils go on your back: each one adds jump power, from +5% up to +{math.floor((GearConfig.Get("Coil", 7).JumpMultiplier - 1) * 100 + 0.5)}%.`,
			}
			table.insert(lines, shop.AskReply)
			talk.Say(table.concat(lines, "\n"))
		else
			return talk.Leave()
		end
	end
end

function Conversations.Sell(talk)
	local shop = talk.Shop
	talk.Say(pick(shop.Greetings), "Wave")
	while true do
		local choice = talk.Choose({
			{ Text = shop.Browse, Colors = talk.Colors },
			{ Text = shop.SellAll, Colors = Theme.Colors.Mint },
			{ Text = shop.Worth, Colors = Theme.Colors.Sky },
			talk.NeverMind,
		})
		if choice == 1 then
			talk.Say(shop.BrowseReply, "Point")
			return talk.OpenShop()
		elseif choice == 2 then
			local summary = sellable()
			if #summary.Ids == 0 then
				talk.Say(noPetsLine(summary))
			else
				local count = #summary.Ids
				local what = if count == 1 then "1 pet" else `{count} pets`
				local kept = if summary.Equipped > 0 then " Your equipped pets stay with you." else ""
				talk.Say(`That's {what} for {money(summary.Total)}.{kept} Deal?`)
				local answer = talk.Choose({
					{ Text = shop.Deal, Colors = Theme.Colors.Mint },
					{ Text = shop.NoDeal, Colors = Theme.Colors.Red },
				})
				if answer == 1 then
					local ok, message, earned = talk.Invoke("SellPets", summary.Ids)
					if ok then
						talk.Say(`{pick(shop.Thanks)} Here's {money(earned or summary.Total)}!`, "Cheer")
					else
						talk.Say(message or "Hmm, something went wrong. Try again!")
					end
				else
					talk.Say("No problem! Take your time.")
				end
			end
		elseif choice == 3 then
			local summary = sellable()
			if #summary.Ids == 0 then
				talk.Say(noPetsLine(summary))
			else
				local line = if #summary.Ids == 1
					then `Your pet is worth {money(summary.Total)}!`
					else `Your {#summary.Ids} pets are worth {money(summary.Total)} in total!`
				if summary.Best and #summary.Ids > 1 then
					line ..= ` The best one is your {safe(summary.Best.Name)}, worth {money(summary.BestPrice)}.`
				end
				talk.Say(line, "Point")
			end
		else
			return talk.Leave()
		end
	end
end

function Conversations.Vertex(talk)
	local shop = talk.Shop
	talk.Say(pick(shop.Greetings), "Wave")
	while true do
		local tier = ClientState.Data and ClientState.Data.VertexTier or 1
		local current = VertexConfig.Get(tier) or VertexConfig.Tiers[1]
		local nextTier = VertexConfig.Get(tier + 1)
		local options = {
			{ Text = shop.Browse, Colors = talk.Colors },
			{ Text = shop.Ask, Colors = Theme.Colors.Purple },
			talk.NeverMind,
		}
		-- One-tap upgrade to the next tier, while there is one.
		if nextTier then
			table.insert(options, 2, { Text = shop.Upgrade, Colors = Theme.Colors.Mint })
		end
		local choice = talk.Choose(options)
		local picked = options[choice]
		if choice == 1 then
			talk.Say(shop.BrowseReply, "Point")
			return talk.OpenShop()
		elseif nextTier and picked.Text == shop.Upgrade then
			local cash = player:GetAttribute("Money") or 0
			if cash < nextTier.Price then
				talk.Say(`The {nextTier.Name} costs {money(nextTier.Price)}. You need {money(nextTier.Price - cash)} more!`)
			else
				talk.Say(`The {nextTier.Name} gives {powerText(nextTier)} for {money(nextTier.Price)}. Want it?`, "Point")
				local answer = talk.Choose({
					{ Text = shop.Deal, Colors = Theme.Colors.Mint },
					{ Text = shop.NoDeal, Colors = Theme.Colors.Red },
				})
				if answer == 1 then
					local ok, message = talk.Invoke("BuyVertex", tier + 1)
					if ok then
						talk.Say(`{pick(shop.Thanks)} You now have the {nextTier.Name}!`, "Cheer")
					else
						talk.Say(message or "Hmm, something went wrong. Try again!")
					end
				else
					talk.Say("Come back when you're ready!")
				end
			end
		elseif picked.Text == shop.Ask then
			local line = `A vertex multiplies the jump power you train on the trampoline, so you reach higher islands. You have the {current.Name}, with {powerText(current)}.`
			if nextTier then
				line ..= ` Next is the {nextTier.Name}: {powerText(nextTier)} for {money(nextTier.Price)}!`
			else
				line ..= " That's the strongest one there is!"
			end
			talk.Say(line)
		else
			return talk.Leave()
		end
	end
end

-- Controller ----------------------------------------------------------------------

local ShopTalk = {}

-- hooks = {
--   OpenShop = function(shopType, context),  -- opens the shop window for this talk
--   CloseWindows = function(),               -- closes any open window
--   Shop = ShopPanel,                        -- for its Closed/Purchased events
-- }
function ShopTalk.new(gui: ScreenGui, hooks)
	local dialogue = Dialogue.new(gui)
	local current = nil -- the conversation going on now

	local controller = {}

	local function finish(conversation, farewell: boolean?)
		if current ~= conversation then
			return
		end
		current = nil
		dialogue.Close()
		if conversation.Shopping and hooks.Shop.IsOpen() and hooks.Shop.Context and hooks.Shop.Context.Conversation == conversation then
			hooks.Shop.Close()
		end
		local keeper = conversation.Keeper
		if farewell and keeper then
			Shopkeepers.Play(keeper, "Wave")
			Shopkeepers.Bubble(keeper, pick(conversation.Shop.Bye))
		end
		Shopkeepers.SetTalking(keeper, false)
		Shopkeepers.EndTalk(keeper)
		if conversation.Prompt then
			conversation.Prompt.Enabled = true
		end
	end

	local function anchorOf(keeper: Model?, spot: Instance?): Vector3?
		local target = keeper or spot
		if not target then
			return nil
		end
		if target:IsA("BasePart") then
			return target.Position
		elseif target:IsA("Model") then
			return target:GetPivot().Position
		end
		local part = target:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position
	end

	function controller.Start(shopType: string, keeper: Model?, spot: Instance?)
		local shop = ShopConfig.Shops[shopType]
		if not shop or current then
			return
		end
		if keeper and not keeper:IsA("Model") then
			keeper = nil
		end
		hooks.CloseWindows()

		local colors = Theme.Colors[shop.Color] or Theme.Colors.Pink
		local keeperName = keeper and keeper:GetAttribute("KeeperName") or shop.Keeper
		local conversation = {
			ShopType = shopType,
			Shop = shop,
			Keeper = keeper,
			Anchor = anchorOf(keeper, spot),
			Prompt = nil,
			Shopping = false,
		}
		current = conversation

		-- No talking to them twice at once.
		local promptHolder = keeper or spot
		local prompt = promptHolder and promptHolder:FindFirstChild("ShopPrompt", true)
		if prompt and prompt:IsA("ProximityPrompt") then
			conversation.Prompt = prompt
			prompt.Enabled = false
		end

		Shopkeepers.BeginTalk(keeper)
		dialogue.Open({ Name = keeperName, Colors = colors, Icon = shop.Icon, Portrait = keeper })

		local talk = {
			Shop = shop,
			Colors = colors,
			NeverMind = { Text = ShopConfig.NeverMind, Colors = Theme.Colors.Gray },
		}

		function talk.Say(line: string, animation: string?)
			Shopkeepers.SetTalking(keeper, true)
			if animation then
				Shopkeepers.Play(keeper, animation)
			end
			local ok, err = pcall(dialogue.Say, line)
			Shopkeepers.SetTalking(keeper, false)
			if not ok then
				error(err, 0)
			end
		end

		function talk.Choose(options): number
			return dialogue.Choose(options)
		end

		function talk.OpenShop()
			conversation.Shopping = true
			dialogue.Close()
			hooks.OpenShop(shopType, {
				Conversation = conversation,
				Title = shop.Title,
				Colors = colors,
				Hint = shop.Hint,
			})
		end

		function talk.Leave()
			talk.Say(pick(shop.Bye), "Wave")
			task.wait(1.2)
			finish(conversation)
		end

		function talk.Invoke(remoteName: string, ...)
			local remote = Net.Function(remoteName)
			local ok, success, message, extra = pcall(remote.InvokeServer, remote, ...)
			if not ok then
				return false, "Something went wrong, try again!"
			end
			return success, message, extra
		end

		task.spawn(function()
			local ok, err = pcall(Conversations[shopType], talk)
			if not ok and err ~= Dialogue.Closed then
				warn("[ShopTalk]", err)
			end
			if not conversation.Shopping then
				finish(conversation)
			end
		end)
	end

	-- Ends whatever conversation is going on (e.g. you opened another menu).
	function controller.Cancel()
		if current then
			finish(current)
		end
	end

	function controller.IsTalking(): boolean
		return current ~= nil
	end

	-- The X on the dialogue box is the same as "Never mind".
	dialogue.CloseRequested:Connect(function()
		if current and not current.Shopping then
			finish(current, true)
		end
	end)

	-- Closing the shop window ends the visit.
	hooks.Shop.Closed:Connect(function(context)
		if current and context and context.Conversation == current then
			finish(current, true)
		end
	end)

	-- They cheer when you buy something.
	hooks.Shop.Purchased:Connect(function()
		local conversation = current
		if conversation and conversation.Shopping and conversation.Keeper then
			Shopkeepers.Play(conversation.Keeper, "Cheer")
			Shopkeepers.Bubble(conversation.Keeper, pick(conversation.Shop.Thanks))
		end
	end)

	-- Walking away (or dying) ends the conversation.
	RunService.Heartbeat:Connect(function()
		local conversation = current
		if not conversation then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and humanoid) or humanoid.Health <= 0 then
			finish(conversation)
		elseif conversation.Anchor and (root.Position - conversation.Anchor).Magnitude > ShopConfig.LeaveDistance then
			finish(conversation, true)
		end
	end)

	return controller
end

return ShopTalk
