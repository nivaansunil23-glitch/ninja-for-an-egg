-- Random cloud platforms between the islands (World/Clouds, started by
-- World/CloudSpawner). How far apart they are comes from the jump power each
-- gap is built for (JumpBalance); this file is the cloud look and the safety
-- margins.

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

-- Space kept free around and above every cloud so you don't bonk your head.
CloudConfig.PlayerHeight = 6
CloudConfig.MaxHeadroom = 24
CloudConfig.WorldMargin = 1

-- Every platform gets a few smaller puffs tucked under its edge so the clouds
-- read as puffy clusters, and side clouds branch off the climb so it isn't one
-- line (BranchRatio side clouds per path cloud).
CloudConfig.PuffsMin = 1
CloudConfig.PuffsMax = 3
CloudConfig.BranchRatio = 0.6 -- was 1.3; fewer clouds (user, 2026-10-19)

-- Keep the climb from looking like an obby: each step turns at least MinTurn
-- degrees from the last one while the top is still far off (urgency below
-- WanderUntil), rises are uneven (RiseSkew > 1 = more small hops, a few big
-- ones) and cloud sizes vary by SizeJitter.
CloudConfig.MinTurn = 50
CloudConfig.WanderUntil = 0.6
CloudConfig.RiseSkew = 1.4
CloudConfig.SizeJitterMin = 0.7
CloudConfig.SizeJitterMax = 1.4

-- Rescue clouds: extra clouds all over each gap so you can save yourself after
-- the guardian flings you off an island. RescueRatio per climb cloud;
-- RescueNearIsland of them crowd around/under the island above, out to
-- RescueRing studs past its edge.
CloudConfig.RescueRatio = 1.0 -- was 2.5; fewer clouds (user, 2026-10-19)
CloudConfig.RescueNearIsland = 0.5
CloudConfig.RescueRing = 60

-- Smooth flat colours, no textures.
CloudConfig.Color = Color3.fromRGB(248, 249, 255)
CloudConfig.PuffColor = Color3.fromRGB(232, 237, 250)
-- "Beach Island / Needs 77 Jump" sign at the bottom of each climb.
CloudConfig.ShowSigns = true

-- The cloud mesh: ServerStorage.CloudTemplates (any part in it), else
-- ServerStorage.ToolboxAssets.Cloud, else this mesh id.
CloudConfig.MeshId = "rbxassetid://5515652172"

-- Studs kept clear around the launch trampoline's column, all the way up.
CloudConfig.LaunchClearance = 3

-- On the base no cloud's bottom is lower than this many studs off the ground,
-- so none hang at head height (user, 2026-10-19).
CloudConfig.HeadClearance = 8

-- One-way clouds (client World/OneWayClouds): every solid cloud is tagged
-- OneWayTag with a Top attribute; your own client turns its collision off while
-- your feet are under its top, back on once they're within OnTolerance of it,
-- off again once they drop OffBelow under it.
CloudConfig.OneWayTag = "OneWayCloud"
CloudConfig.OnTolerance = 0.75
CloudConfig.OffBelow = 3

-- Search limits for the random walk.
CloudConfig.Attempts = 40
CloudConfig.MaxBacktracks = 80

return CloudConfig
