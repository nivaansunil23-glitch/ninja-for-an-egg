-- Random cloud platforms between the islands (World/CloudSpawner). How far
-- apart they are comes from the jump power each gap is built for
-- (JumpBalance); this file is the cloud look and the safety margins.

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
CloudConfig.BranchRatio = 0.5

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

-- Search limits for the random walk.
CloudConfig.Attempts = 40
CloudConfig.MaxBacktracks = 80

return CloudConfig
