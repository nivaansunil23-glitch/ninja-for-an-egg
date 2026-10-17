-- The three shops: what they're called, who runs them and what they say.
-- The conversation itself lives in the client (UI/ShopTalk); prices, pet
-- values and vertex numbers in it are filled in live.
--
-- A shopkeeper's name comes from the "DisplayName" (or "KeeperName") attribute
-- on its Shopkeeper model in Studio; Keeper below is only the fallback.

local ShopConfig = {}

-- How close you have to be to see the Talk prompt (measured to the
-- shopkeeper, who stands behind the counter), and how far you can walk away
-- before the conversation (and the shop it opened) closes.
ShopConfig.TalkDistance = 16
ShopConfig.LeaveDistance = 28

ShopConfig.NeverMind = "👋 Never mind"

ShopConfig.Shops = {
	Gear = {
		Title = "Gear Shop",
		Keeper = "Gear Guy",
		Icon = "🛠️",
		Color = "Pink", -- a Theme.Colors name
		Greetings = {
			"Hey there, ninja! Need some gear for the climb?",
			"Welcome to the Gear Shop! Everything's freshly polished.",
			"Ooh, a customer! Want to see my gadgets?",
		},
		Browse = "🛒 Show me your gear!",
		BrowseReply = "Here's what I've got. Take a look!",
		Ask = "❓ What does gear do?",
		AskReply = "Gear helps you climb higher. Buy it once and it's yours forever!",
		Hint = "Gear is yours forever and goes in your hotbar.",
		Bye = { "Come back anytime!", "Happy climbing!", "See ya, ninja!" },
		Thanks = { "Great pick!", "Pleasure doing business!", "Enjoy your new gear!" },
	},
	Sell = {
		Title = "Sell Shop",
		Keeper = "Seller",
		Icon = "💰",
		Color = "Yellow",
		Greetings = {
			"Got any pets to sell? I pay top dollar!",
			"Welcome! Heavier pets are worth way more, you know.",
			"Pets for cash! What have you got for me?",
		},
		Browse = "🐾 Let me pick what to sell",
		BrowseReply = "Sure thing! Tap the pets you want to sell.",
		SellAll = "💸 Sell all my pets!",
		Worth = "🤔 How much are my pets worth?",
		Deal = "✅ Deal!",
		NoDeal = "❌ Wait, no!",
		Hint = "Tap pets to pick them. Equipped pets are never sold.",
		Bye = { "Come back with more pets!", "Bye bye!", "See you soon!" },
		Thanks = { "Pleasure doing business!", "Ka-ching!", "Thanks a bunch!" },
	},
	Vertex = {
		Title = "Vertex Shop",
		Keeper = "Vertex Wizard",
		Icon = "💎",
		Color = "Sky",
		Greetings = {
			"Want to jump higher, young ninja?",
			"A better vertex gets you to higher islands!",
			"Ah, a climber! Ready to power up your jump?",
		},
		Browse = "💎 Show me the vertices!",
		BrowseReply = "Choose wisely. Each one is stronger than the last!",
		Ask = "❓ What's a vertex?",
		Hint = "Buy vertices in order. Each one jumps higher!",
		Bye = { "Keep climbing!", "Jump high, ninja!", "Train hard!" },
		Thanks = { "Feel that power!", "Now you'll fly!", "A fine choice!" },
	},
}

return ShopConfig
