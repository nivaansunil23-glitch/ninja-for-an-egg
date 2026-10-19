-- The climbing clouds between the islands (server World/Clouds, client
-- World/OneWayClouds). How far apart they are comes from the jump power each
-- gap is built for (JumpBalance); this file is the paths, the look and the
-- safety margins.

local CloudConfig = {}

-- Each step up is this share of the max jump height for the gap.
-- JumpBalance.AverageStep is the middle of these two.
CloudConfig.StepMin = 0.45
CloudConfig.StepMax = 0.72
-- The last hop from the top cloud onto the island.
CloudConfig.FinalStepMin = 0.35
CloudConfig.FinalStepMax = 0.55

-- Sideways gaps use this share of how far you really get in the air at walking
-- speed, so every jump works without sprinting (sprinting makes them easier).
CloudConfig.ReachFactor = 0.7
CloudConfig.WalkSpeed = 16
CloudConfig.MinGap = 1.5 -- studs between neighbouring clouds' edges

-- Cloud size grows with the jump height of its gap:
-- inner radius = SizeBase + SizePerHeight * max jump height.
CloudConfig.SizeBase = 3.6
CloudConfig.SizePerHeight = 0.085
CloudConfig.SizeMin = 4
CloudConfig.SizeMax = 18
CloudConfig.Elongation = 1.2 -- clouds are this much longer than wide
CloudConfig.ThicknessRatio = 0.6
CloudConfig.ThicknessMin = 2.5
CloudConfig.ThicknessMax = 8
CloudConfig.SizeJitterMin = 0.8
CloudConfig.SizeJitterMax = 1.3
CloudConfig.RiseSkew = 1.4 -- > 1 = more small hops, a few big ones

-- Space kept free above every cloud so you don't land with your head in the
-- next one, and around the map.
CloudConfig.PlayerHeight = 6
CloudConfig.MaxHeadroom = 24
CloudConfig.WorldMargin = 1

-- Paths: every gap gets Paths cloud paths that wind round the space between
-- the island below and the island above, from its ground to just off its edge.
-- Path 1 sweeps one way, path 2 the other way and path 3 half as far, so they
-- cross each other on the way up. Sweep = how far round they wind (degrees),
-- worked out from how far the gap's steps can carry you (SweepFactor of it),
-- kept between SweepMin and SweepMax. PathBulge = how far the paths swing out
-- in the middle (share of their radius).
CloudConfig.Paths = 3
CloudConfig.SweepMin = 90
CloudConfig.SweepMax = 300
CloudConfig.SweepFactor = 0.6
CloudConfig.PathBulge = 0.15
-- Where each path ends round the island above (degrees from its LandingSpot).
CloudConfig.EndAngles = { 0, 120, -120 }
-- Colours of the path lines the admin panel's Show Paths draws.
CloudConfig.PathColors = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 220, 110),
	Color3.fromRGB(90, 160, 255),
}

-- Every cloud gets a few smaller puffs tucked under its edge so the clouds
-- read as puffy clusters, and a few themed bits.
CloudConfig.PuffsMin = 1
CloudConfig.PuffsMax = 2
CloudConfig.BitsMin = 3
CloudConfig.BitsMax = 5

-- One-way clouds: you jump up through them and land on them from above.
-- The visible mesh never collides; an invisible flat Floor (a cylinder
-- ColliderRadius x the cloud's half width, ColliderThickness thick, top at the
-- standing height) does. The server leaves Floors solid (eggs, raycasts); each
-- client turns them off just for its own character while its feet are under
-- the top (World/OneWayClouds): on once the feet are within OnTolerance of the
-- top, off again once they drop OffBelow under it.
CloudConfig.ColliderRadius = 0.95
CloudConfig.ColliderThickness = 2
CloudConfig.MeshLift = 0.5 -- the mesh sits this far above the Floor's top
CloudConfig.OneWayTag = "OneWayCloud"
CloudConfig.OnTolerance = 0.75
CloudConfig.OffBelow = 3

-- Themes: the bottom half of a gap looks like the island below, the top half
-- like the island above (by IslandId; the base island is "Base"). Smooth flat
-- colours only. Bits = kinds of small low poly decorations (World/Clouds).
CloudConfig.Themes = {
	Base = {
		Color = Color3.fromRGB(248, 249, 255),
		PuffColor = Color3.fromRGB(226, 231, 243),
		Bits = {},
	},
	Forest = {
		Color = Color3.fromRGB(232, 246, 226),
		PuffColor = Color3.fromRGB(200, 228, 194),
		Bits = {
			{ Kind = "Moss", Colors = { Color3.fromRGB(98, 170, 80), Color3.fromRGB(124, 192, 96) } },
			{ Kind = "Leaf", Colors = { Color3.fromRGB(70, 150, 70), Color3.fromRGB(150, 205, 90) } },
		},
	},
	Beach = {
		Color = Color3.fromRGB(255, 249, 234),
		PuffColor = Color3.fromRGB(244, 230, 202),
		Bits = {
			{ Kind = "Sand", Colors = { Color3.fromRGB(238, 214, 160), Color3.fromRGB(245, 224, 175) } },
			{ Kind = "Shell", Colors = { Color3.fromRGB(250, 185, 185), Color3.fromRGB(255, 228, 196) } },
		},
	},
	CherryBlossom = {
		Color = Color3.fromRGB(255, 237, 245),
		PuffColor = Color3.fromRGB(248, 212, 230),
		Bits = {
			{ Kind = "Petal", Colors = { Color3.fromRGB(255, 165, 205), Color3.fromRGB(255, 205, 228) } },
		},
	},
	Snow = {
		Color = Color3.fromRGB(251, 253, 255),
		PuffColor = Color3.fromRGB(212, 230, 250),
		Bits = {
			{ Kind = "SnowCap", Colors = { Color3.fromRGB(255, 255, 255) } },
			{ Kind = "Icicle", Colors = { Color3.fromRGB(185, 222, 250), Color3.fromRGB(210, 236, 255) } },
		},
	},
	Desert = {
		Color = Color3.fromRGB(252, 241, 222),
		PuffColor = Color3.fromRGB(234, 212, 176),
		Bits = {
			{ Kind = "Dust", Colors = { Color3.fromRGB(225, 190, 130), Color3.fromRGB(240, 210, 160) } },
			{ Kind = "Sand", Colors = { Color3.fromRGB(230, 200, 145) } },
		},
	},
	Jungle = {
		Color = Color3.fromRGB(226, 243, 224),
		PuffColor = Color3.fromRGB(188, 218, 186),
		Bits = {
			{ Kind = "Vine", Colors = { Color3.fromRGB(60, 130, 60), Color3.fromRGB(82, 150, 52) } },
			{ Kind = "Leaf", Colors = { Color3.fromRGB(50, 140, 70), Color3.fromRGB(110, 180, 70) } },
		},
	},
	Volcano = {
		Color = Color3.fromRGB(156, 146, 150),
		PuffColor = Color3.fromRGB(100, 90, 96),
		Bits = {
			{ Kind = "Ember", Colors = { Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 196, 60) } },
		},
	},
	CandySky = {
		Color = Color3.fromRGB(255, 234, 248),
		PuffColor = Color3.fromRGB(226, 214, 255),
		Bits = {
			{
				Kind = "Sprinkle",
				Colors = {
					Color3.fromRGB(255, 90, 150),
					Color3.fromRGB(90, 200, 255),
					Color3.fromRGB(255, 220, 80),
					Color3.fromRGB(140, 230, 140),
				},
			},
		},
	},
}

-- "Beach Island / Needs 77 Jump" sign on the first cloud of every path.
CloudConfig.ShowSigns = true

-- The cloud mesh: ServerStorage.CloudTemplates (any part in it), else
-- ServerStorage.ToolboxAssets.Cloud, else this mesh id.
CloudConfig.MeshId = "rbxassetid://5515652172"

-- Studs kept clear around the launch trampoline's column, all the way up.
CloudConfig.LaunchClearance = 3

-- Search limits for each path's walk.
CloudConfig.Attempts = 40
CloudConfig.MaxBacktracks = 80

return CloudConfig
