--!nonstrict
-- Starts the egg systems: island spawning, carrying/stealing/cracks, pens and hatching.
-- Other server code can require the child modules (EggCarry, PenService,
-- Hatching, EggFactory) to read egg state.

local EggCarry = require(script.EggCarry)
local EggSpawner = require(script.EggSpawner)
local PenService = require(script.PenService)

EggCarry.Start()
EggSpawner.Start()
PenService.Start()
