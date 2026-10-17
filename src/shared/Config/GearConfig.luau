-- Items sold in the Gear shop. Prices are placeholders ("can be discussed later").

local GearConfig = {}

GearConfig.Items = {
	Jetpack = {
		Id = "Jetpack",
		Name = "Jetpack",
		Icon = "🚀",
		Order = 1,
		Price = 500,
		Description = "Hold jump in the air to blast upward.",
		Color = Color3.fromRGB(255, 120, 130),
		HandleSize = Vector3.new(1.2, 1.6, 0.8),
		Fuel = 2.5, -- seconds of thrust
		ThrustSpeed = 45, -- upward speed while thrusting
		RefuelPerSecond = 1.25, -- fuel seconds regained per second on the ground
	},
	JumpCoil = {
		Id = "JumpCoil",
		Name = "Jump Coil",
		Icon = "🌀",
		Order = 2,
		Price = 300,
		Description = "Hold it for +30% jump power.",
		Color = Color3.fromRGB(120, 220, 255),
		HandleSize = Vector3.new(1.4, 1, 1),
		JumpMultiplier = 1.3,
	},
}

function GearConfig.List()
	local list = {}
	for _, item in GearConfig.Items do
		table.insert(list, item)
	end
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

return GearConfig
