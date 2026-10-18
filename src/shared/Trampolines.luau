-- Finds the trampolines on the map and where their bouncy pad is. Used by the
-- client (bouncing, launching) and the server (checking bounces).
--   Training trampolines: any Model or Part named "Trampoline" under Workspace.Map.
--   Launch trampoline: one named "LaunchTrampoline" (Workspace.Map.LaunchTrampoline).
-- Tagging something "Trampoline" or "LaunchTrampoline" works too.
-- The pad is a part named "BouncePad" inside it (or "Mat" / "Pad"), otherwise
-- the model's PrimaryPart, otherwise its widest part.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Trampolines = {}

Trampolines.Training = "Trampoline"
Trampolines.Launch = "LaunchTrampoline"

local PAD_NAMES = { "BouncePad", "Mat", "Pad" }

-- [kind] = { [instance] = true }
local found = {
	[Trampolines.Training] = {},
	[Trampolines.Launch] = {},
}
local watching = false

local function kindOf(instance: Instance): string?
	if not (instance:IsA("Model") or instance:IsA("BasePart")) then
		return nil
	end
	if found[instance.Name] then
		return instance.Name
	end
	for kind in found do
		if CollectionService:HasTag(instance, kind) then
			return kind
		end
	end
	return nil
end

local function add(instance: Instance)
	local kind = kindOf(instance)
	if kind then
		found[kind][instance] = true
	end
end

local function remove(instance: Instance)
	for _, set in found do
		set[instance] = nil
	end
end

local function watchMap(map: Instance)
	for _, descendant in map:GetDescendants() do
		add(descendant)
	end
	map.DescendantAdded:Connect(add)
	map.DescendantRemoving:Connect(remove)
end

local function watch()
	if watching then
		return
	end
	watching = true
	for kind in found do
		for _, tagged in CollectionService:GetTagged(kind) do
			add(tagged)
		end
		CollectionService:GetInstanceAddedSignal(kind):Connect(add)
		CollectionService:GetInstanceRemovedSignal(kind):Connect(remove)
	end
	local map = Workspace:FindFirstChild("Map")
	if map then
		watchMap(map)
	else
		task.spawn(function()
			watchMap(Workspace:WaitForChild("Map", math.huge))
		end)
	end
end

-- Every trampoline of a kind (Trampolines.Training by default) on the map.
function Trampolines.GetAll(kind: string?): { Instance }
	watch()
	local list = {}
	for instance in found[kind or Trampolines.Training] do
		if instance.Parent then
			table.insert(list, instance)
		end
	end
	return list
end

-- For checking what a client sent: is this really a trampoline of that kind?
function Trampolines.IsTrampoline(instance: any, kind: string?): boolean
	return typeof(instance) == "Instance"
		and instance:IsDescendantOf(Workspace)
		and kindOf(instance) == (kind or Trampolines.Training)
end

function Trampolines.GetPad(trampoline: Instance): BasePart?
	if trampoline:IsA("BasePart") then
		return trampoline
	end
	for _, name in PAD_NAMES do
		local pad = trampoline:FindFirstChild(name, true)
		if pad and pad:IsA("BasePart") then
			return pad
		end
	end
	if trampoline:IsA("Model") and trampoline.PrimaryPart then
		return trampoline.PrimaryPart
	end
	local widest, widestArea = nil, 0
	for _, part in trampoline:GetDescendants() do
		if part:IsA("BasePart") and part.Size.X * part.Size.Z > widestArea then
			widest, widestArea = part, part.Size.X * part.Size.Z
		end
	end
	return widest
end

-- The UserId of the plot owner a trampoline belongs to: nil when it isn't in
-- a plot, 0 when the plot is free.
function Trampolines.OwnerUserId(trampoline: Instance): number?
	local node = trampoline.Parent
	while node and node ~= Workspace do
		local owner = node:GetAttribute("OwnerUserId")
		if type(owner) == "number" then
			return owner
		end
		node = node.Parent
	end
	return nil
end

-- Training trampolines in a plot only work for the plot's owner.
function Trampolines.CanUse(trampoline: Instance, userId: number): boolean
	local owner = Trampolines.OwnerUserId(trampoline)
	return owner == nil or owner == userId
end

-- Where the pad is in the world: { Pad, Center, Radius, Top, Bottom }.
function Trampolines.GetPadInfo(trampoline: Instance)
	local pad = Trampolines.GetPad(trampoline)
	if not pad then
		return nil
	end
	local cframe, half = pad.CFrame, pad.Size / 2
	local right, up, back = cframe.RightVector, cframe.UpVector, -cframe.LookVector
	-- Half size of the pad's world-space bounding box (the pad may be rotated).
	local halfX = math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(back.X) * half.Z
	local halfY = math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(back.Y) * half.Z
	local halfZ = math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(back.Z) * half.Z
	local center = cframe.Position
	return {
		Pad = pad,
		Center = center,
		Radius = math.min(halfX, halfZ),
		Top = center.Y + halfY,
		Bottom = center.Y - halfY,
	}
end

-- Is this position (a HumanoidRootPart) over the pad? `slack` widens the
-- check sideways and `above` is how far over the pad's top still counts.
function Trampolines.IsOver(info, position: Vector3, slack: number?, above: number?): boolean
	local dx, dz = position.X - info.Center.X, position.Z - info.Center.Z
	local reach = info.Radius + (slack or 0)
	return dx * dx + dz * dz <= reach * reach
		and position.Y >= info.Bottom - 3 - (slack or 0)
		and position.Y <= info.Top + (above or 8)
end

-- The trampoline of a kind this position is over, and its pad info.
function Trampolines.FindAt(position: Vector3, kind: string?, slack: number?, above: number?)
	for _, trampoline in Trampolines.GetAll(kind) do
		local info = Trampolines.GetPadInfo(trampoline)
		if info and Trampolines.IsOver(info, position, slack, above) then
			return trampoline, info
		end
	end
	return nil, nil
end

return Trampolines
