-- General player settings. Numbers are placeholders until we balance the game.

return {
	-- Bump the version suffix to wipe everyone's save (e.g. before release).
	DataStoreName = "PlayerData_v1",
	AutosaveSeconds = 120,
	StartingMoney = 0,

	-- Height tracker counts from this Y level. Set a "GroundY" attribute on Workspace to override.
	GroundY = 0,
	-- Height the tracker bar treats as "full" until the player's best goes past it.
	HeightTrackerMax = 1500,

	MaxEquippedPets = 4,
	MaxSellPerRequest = 200,
}
