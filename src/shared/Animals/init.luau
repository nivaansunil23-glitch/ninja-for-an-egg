--!nonstrict
-- The animals that hatch out of eggs. Each one's look is a spec module in
-- Specs (named like the pet without spaces: "Red Panda" -> Specs.RedPanda),
-- built from smooth Parts and animated by AnimalRig.
--
--   Animals.GetSpec("Red Panda")          -> spec table or nil
--   Animals.Build("Red Panda", opts)      -> AnimalRig (opts as AnimalRig.Build) or nil

local AnimalRig = require(script:WaitForChild("AnimalRig"))
local Specs = script:WaitForChild("Specs")

local Animals = {}
Animals.Rig = AnimalRig

local cache = {}

function Animals.GetSpec(petName: string)
	local key = (petName:gsub("%s", ""))
	if cache[key] == nil then
		local module = Specs:FindFirstChild(key)
		cache[key] = if module then require(module) else false
	end
	return cache[key] or nil
end

function Animals.Build(petName: string, opts)
	local spec = Animals.GetSpec(petName)
	if not spec then
		return nil
	end
	opts = opts or {}
	opts.Name = opts.Name or petName
	return AnimalRig.Build(spec, opts)
end

return Animals
