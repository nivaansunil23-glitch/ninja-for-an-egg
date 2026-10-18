--!nonstrict
--[[
  Fennec Fox (Desert island animal). Built from smooth Parts in code, nothing to import.
  It wanders around its spawn part with a walk cycle and stands still now and then.

  Script type: LocalScript, in StarterPlayer > StarterPlayerScripts > Client > Animals.
  It runs on each player's own client because island animals are only for looks;
  41 animals moving every frame on the server would lag the game and the network.

  Setup: put a Part named "FennecFoxSpawn" on the island (Anchored, CanCollide off,
  Transparency 1). You can place several. Optional attributes on each:
    Count  (number) how many Fennec Foxs at that spot (default 2)
    Radius (number) how far they wander from it, in studs (default 30)

  Look: change SPEC below (colours in C, parts in Parts). Preview: FennecFox.html
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CFG = {
	SPAWN_NAME = "FennecFoxSpawn",
	COUNT = 2, -- per spawn part, unless it has a Count attribute
	RADIUS = 30, -- unless the spawn part has a Radius attribute
	IDLE_MIN = 2, -- seconds it stands still between walks
	IDLE_MAX = 6,
	MAX_STEP = 3, -- won't walk up/down a ledge taller than this (studs)
	MAX_DROP = 20, -- wander spots must be within this height of the spawn part
	NEAR = 120, -- full-rate animation inside this distance from the camera
	FAR = 280, -- frozen beyond this distance
}

local SPEC = {
	Kind = "quad",
	Scale = 2.8,
	WalkSpeed = 6,
	C = {
		cream = { 246, 233, 211 },
		dark = { 70, 50, 40 },
		fur = { 232, 195, 143 },
		pink = { 240, 190, 170 },
	},
	Anim = { Wag = 0.25 },
	Eyes = { node = "head", s = 0.055, x = 0.08, y = 0.1, z = 0.232 },
	Nodes = {
		{ "body", "root", 0, 0.26, 0 },
		{ "head", "body", 0, 0.18, 0.22 },
		{ "earL", "head", 0.1, 0.2, 0.06, m = true, rz = -0.35 },
		{ "legFL", "root", 0.09, 0.2, 0.16, m = true },
		{ "legBL", "root", 0.09, 0.2, -0.16, m = true },
		{ "tail", "body", 0, 0.06, -0.24, rx = 0.3 },
	},
	Parts = {
		{ "body", "fur", 0.28, 0.22, 0.46, 0, 0.04, 0 },
		{ "body", "cream", 0.22, 0.16, 0.05, 0, 0.02, 0.23 },
		{ "head", "fur", 0.34, 0.28, 0.3, 0, 0.08, 0.08 },
		{ "head", "cream", 0.14, 0.09, 0.12, 0, -0.01, 0.27 },
		{ "head", "dark", 0.05, 0.04, 0.03, 0, 0.03, 0.34 },
		{ "earL", "fur", 0.14, 0.28, 0.05, 0, 0.12, 0, m = true },
		{ "earL", "pink", 0.09, 0.2, 0.012, 0, 0.12, 0.028, m = true },
		{ "legFL", "fur", 0.07, 0.2, 0.07, 0, -0.1, 0, m = true },
		{ "legBL", "fur", 0.07, 0.2, 0.07, 0, -0.1, 0, m = true },
		{ "tail", "fur", 0.14, 0.14, 0.3, 0, 0, -0.15 },
		{ "tail", "dark", 0.145, 0.145, 0.07, 0, 0, -0.3 },
	},
}

------------------------------------------------------------------------------
-- AnimalRig: builds the model from SPEC and animates it (same in every animal script)
------------------------------------------------------------------------------
--[[
  AnimalRig: builds a low poly animal out of smooth Parts from a spec table
  (see the modules in Shared.Animals.Specs) and animates it in code, the same
  way the Chicken, Frog and Crab guardians work: every Part is Anchored and
  moved each frame with workspace:BulkMoveTo. No Humanoid, no Animation
  Editor, no meshes.

  Usage:
    local rig = AnimalRig.Build(spec, { Parent = workspace, Zs = true })
    -- every frame:
    rig:Step(dt, mode, speed, position, heading)
      mode     "idle" | "walk" | "run" | "sleep"
      speed    studs/sec it is moving right now (drives the leg cycle)
      position Vector3 where its feet are
      heading  radians, 0 = facing +Z

  Spec format (units: 1 unit = spec.Scale studs, about the animal's height):
    Kind   "quad" 4 legs | "biped" 2 legs + arms | "bird" | "fly" (hovers)
           | "swim" (no legs) | "snake" | "crawl" (low, legs sweep sideways)
    Nodes  { name, parent, x, y, z, rx=, ry=, rz=, ph=, m= }
           Joints. Their name decides how they move:
             body, head, neck, jaw, tail*, seg* (snake body), leg*, arm*,
             wing*, ear*, fin*, hood*. "L" in a name = left (+X) side.
           m = true also makes the mirrored right-side node (L -> R).
           ph = leg phase (+1 / -1) when the name doesn't say it.
    Parts  { node, colorKey, w, h, d, x, y, z, rx, ry, rz, m=, mat=, tr= }
           A box of size w,h,d placed at x,y,z (rotated rx,ry,rz radians)
           relative to its node. m = true mirrors it to the other side.
           r = 0..0.5 rounds the box's edges (softer, less cubey look).
    C      colours by key: { fur = { r, g, b }, ... }
    Eyes   { node, x, y, z, s, side = bool, c = {r,g,b}, mat = "Neon" } adds eyes (+ shut eyes for
           sleeping and angry brows for chasing).
    Anim   optional tweaks: Leg, Arm, Bob, Lean, Wag, WagSpeed, HeadSleep,
           Flap ("bird" | "big" | "fly" | "none"), SleepDrop, Stride
]]

local AnimalRig = {}
AnimalRig.__index = AnimalRig

local PHASE = { legFL = 1, legFR = -1, legBL = -1, legBR = 1, legL = 1, legR = -1, armL = -1, armR = 1 }
local ROLES = { "body", "head", "neck", "jaw", "tail", "seg", "leg", "arm", "wing", "ear", "fin", "hood" }

local EYE = Color3.fromRGB(22, 22, 22)
local SHINE = Color3.fromRGB(255, 255, 255)

local function swapSide(name: string): string
	for k = #name, 1, -1 do
		if string.sub(name, k, k) == "L" then
			return string.sub(name, 1, k - 1) .. "R" .. string.sub(name, k + 1)
		end
	end
	return name
end

local function roleOf(name: string): string
	for _, r in ROLES do
		if string.sub(name, 1, #r) == r then
			return r
		end
	end
	return "other"
end

-- +1 for left-side joints, -1 for right-side, 0 for the middle
local function sideOf(name: string): number
	for k = #name, 1, -1 do
		local ch = string.sub(name, k, k)
		if ch == "L" then
			return 1
		elseif ch == "R" then
			return -1
		end
	end
	return 0
end

local function lerp(a, b, f)
	return a + (b - a) * f
end

function AnimalRig.Build(spec, opts)
	opts = opts or {}
	local S = (spec.Scale or 3) * (opts.Scale or 1)
	local self = setmetatable({}, AnimalRig)
	self.spec = spec
	self.S = S
	self.anim = spec.Anim or {}
	self.nodes, self.parts, self.list = {}, {}, {}
	self.eyesOpen, self.eyesShut, self.brows = {}, {}, {}
	self.t = math.random() * 10
	self.seed = math.random() * 6.28
	self.phase = 0
	self.W = { idle = 1, walk = 0, run = 0, sleep = 0 }
	self.mode = "idle"

	local model = Instance.new("Model")
	model.Name = opts.Name or spec.Name or "Animal"
	self.Model = model

	-- nodes
	local root = { name = "root", base = Vector3.zero, rest = Vector3.zero, pos = Vector3.zero, rot = Vector3.zero }
	self.root = root
	self.nodes.root = root
	local order = {}
	local function addNode(n, mirror)
		local name = if mirror then swapSide(n[1]) else n[1]
		local x = if mirror then -n[3] else n[3]
		local ry = if mirror then -(n.ry or 0) else (n.ry or 0)
		local rz = if mirror then -(n.rz or 0) else (n.rz or 0)
		local ph = n.ph and (if mirror then -n.ph else n.ph) or PHASE[name] or 0
		local node = {
			name = name,
			parentName = if mirror then swapSide(n[2]) else n[2],
			base = Vector3.new(x, n[4], n[5]),
			rest = Vector3.new(n.rx or 0, ry, rz),
			role = roleOf(name),
			side = sideOf(name),
			ph = ph,
			index = tonumber(string.match(name, "%d+")) or 1,
		}
		node.pos, node.rot = node.base, Vector3.zero
		self.nodes[name] = node
		table.insert(order, node)
	end
	for _, n in spec.Nodes do
		addNode(n, false)
		if n.m then
			addNode(n, true)
		end
	end
	for _, node in order do
		node.parent = self.nodes[node.parentName] or root
	end
	self.order = order

	-- parts
	local colors = {}
	for key, c in spec.C do
		colors[key] = Color3.fromRGB(c[1], c[2], c[3])
	end
	local function addPart(name, nodeName, color, w, h, d, x, y, z, rx, ry, rz, extra)
		local node = self.nodes[nodeName] or root
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = (extra and extra.mat) or Enum.Material.SmoothPlastic
		p.Color = color
		p.Transparency = (extra and extra.tr) or 0
		p.Size = Vector3.new(math.max(w * S, 0.05), math.max(h * S, 0.05), math.max(d * S, 0.05))
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		table.insert(self.parts, {
			part = p,
			node = node,
			offset = CFrame.new(x * S, y * S, z * S) * CFrame.Angles(rx or 0, ry or 0, rz or 0),
		})
		table.insert(self.list, p)
		return p
	end
	-- r = 0..0.5 rounds a box off: it becomes 3 overlapping boxes, each
	-- shrunk on two axes, so every edge gets a soft step instead of a sharp corner.
	local function addShape(name, nodeName, color, w, h, d, x, y, z, rx, ry, rz, extra, r)
		if not r or r <= 0 then
			return addPart(name, nodeName, color, w, h, d, x, y, z, rx, ry, rz, extra)
		end
		local k = 1 - r
		addPart(name .. "a", nodeName, color, w, h * k, d * k, x, y, z, rx, ry, rz, extra)
		addPart(name .. "b", nodeName, color, w * k, h, d * k, x, y, z, rx, ry, rz, extra)
		return addPart(name .. "c", nodeName, color, w * k, h * k, d, x, y, z, rx, ry, rz, extra)
	end
	for i, q in spec.Parts do
		local color = colors[q[2]] or Color3.fromRGB(255, 0, 255)
		local extra = { mat = q.mat and Enum.Material[q.mat], tr = q.tr }
		local base = q[1] .. "_" .. i
		addShape(base, q[1], color, q[3], q[4], q[5], q[6], q[7], q[8], q[9], q[10], q[11], extra, q.r)
		if q.m then
			addShape(base .. "M", swapSide(q[1]), color, q[3], q[4], q[5], -q[6], q[7], q[8], q[9], -(q[10] or 0), -(q[11] or 0), extra, q.r)
		end
	end

	-- eyes: open eyes + shine, shut lines for sleeping, brows for chasing
	local e = spec.Eyes
	if e and opts.Face ~= false then
		local s = e.s or 0.05
		local eyeColor = e.c and Color3.fromRGB(e.c[1], e.c[2], e.c[3]) or EYE
		local glow = e.mat and { mat = Enum.Material[e.mat] } or nil -- e.g. mat = "Neon" for glowing eyes
		for _, side in { 1, -1 } do
			local x = side * e.x
			if e.side then
				local fx = x + side * 0.006
				table.insert(self.eyesOpen, addPart("Eye", e.node, eyeColor, 0.012, s * 1.15, s, fx, e.y, e.z, nil, nil, nil, glow))
				table.insert(self.eyesOpen, addPart("EyeShine", e.node, SHINE, 0.006, s * 0.3, s * 0.3, fx + side * 0.008, e.y + s * 0.25, e.z + s * 0.2))
				table.insert(self.eyesShut, addPart("EyeShut", e.node, eyeColor, 0.012, s * 0.22, s * 1.1, fx, e.y - s * 0.1, e.z, nil, nil, nil, glow))
				table.insert(self.brows, addPart("Brow", e.node, EYE, 0.012, s * 0.3, s * 1.3, fx, e.y + s * 0.85, e.z, side * 0.45, 0, 0))
			else
				table.insert(self.eyesOpen, addPart("Eye", e.node, eyeColor, s, s * 1.15, 0.012, x, e.y, e.z, nil, nil, nil, glow))
				table.insert(self.eyesOpen, addPart("EyeShine", e.node, SHINE, s * 0.3, s * 0.3, 0.006, x + s * 0.2, e.y + s * 0.25, e.z + 0.008))
				table.insert(self.eyesShut, addPart("EyeShut", e.node, eyeColor, s * 1.1, s * 0.22, 0.012, x, e.y - s * 0.1, e.z, nil, nil, nil, glow))
				table.insert(self.brows, addPart("Brow", e.node, EYE, s * 1.3, s * 0.3, 0.012, x, e.y + s * 0.85, e.z + 0.002, 0, 0, side * 0.45))
			end
		end
	end

	-- floating Z's while asleep (guardians)
	self.zs = {}
	if opts.Zs then
		local head = nil
		for _, p in self.parts do
			if p.node.role == "head" then
				head = p.part
				break
			end
		end
		head = head or self.list[1]
		for i = 1, 3 do
			local bb = Instance.new("BillboardGui")
			bb.Adornee = head
			bb.Size = UDim2.new(1.6, 0, 1.6, 0)
			bb.LightInfluence = 0
			bb.Enabled = false
			bb.Parent = head
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Text = "Z"
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.TextColor3 = Color3.fromRGB(58, 111, 216)
			label.TextStrokeColor3 = Color3.new(1, 1, 1)
			label.Parent = bb
			self.zs[i] = { gui = bb, label = label }
		end
	end

	self:_setFace(false, false)
	model.PrimaryPart = self.list[1]
	model.Parent = opts.Parent or workspace
	return self
end

function AnimalRig:_setFace(asleep, angry)
	for _, p in self.eyesOpen do
		p.Transparency = if asleep then 1 else 0
	end
	for _, p in self.eyesShut do
		p.Transparency = if asleep then 0 else 1
	end
	for _, p in self.brows do
		p.Transparency = if angry then 0 else 1
	end
	self.asleep, self.angry = asleep, angry
end

-- Works out every joint's position/rotation for this frame.
function AnimalRig:_pose(dt, speed)
	local spec, A, W = self.spec, self.anim, self.W
	local kind = spec.Kind or "quad"
	local t = self.t
	local walkSpeed = spec.WalkSpeed or (self.S * 1.8)
	local stride = math.clamp(speed / walkSpeed, 0, 1.6)
	local strideLen = (A.Stride or 0.7) * self.S
	self.phase += dt * math.max(speed, 0) / strideLen * math.pi

	local g = W.walk + W.run
	local amp = g * math.min(stride, 1.25)
	local ph = self.phase
	local s, c = math.sin(ph), math.cos(ph)
	local sl, id, run = W.sleep, W.idle, W.run
	local breath = math.sin(t * 1.6)
	local awake = 1 - sl
	local bodyNode = self.nodes.body
	local drop = (A.SleepDrop or (bodyNode and bodyNode.base.Y * 0.55) or 0) * sl

	for _, n in self.order do
		local role, side = n.role, n.side
		local px, py, pz = 0, 0, 0
		local rx, ry, rz = 0, 0, 0

		if role == "body" then
			local bob = math.abs(c) * (A.Bob or 0.04) * amp
			py = bob - drop + breath * 0.008 * sl
			if kind == "fly" then
				py += math.sin(t * 2.6 + self.seed) * 0.05
			elseif kind == "swim" then
				py += math.sin(t * 1.4 + self.seed) * 0.015
				ry = math.sin(t * (2 + 4 * g)) * 0.12 * (0.4 + g)
			end
			if kind ~= "snake" and kind ~= "swim" then
				rx = (A.Lean or 0.12) * run * math.min(stride, 1) + (A.SleepLean or 0) * sl
				rz = s * 0.04 * amp
			end
		elseif role == "head" then
			local look = math.sin(t * 0.7 + self.seed) * 0.45 * id * awake
			local peek = math.max(0, math.sin(t * 0.5 + self.seed * 2)) ^ 10 * 0.35 * id
			rx = math.sin(ph * 2) * 0.06 * amp + (A.HeadSleep or 0.35) * sl + peek - 0.12 * run
			if n.parent and n.parent.role == "neck" then
				-- keep the head level while the neck lowers or rears up
				rx -= (A.NeckSleep or 0.5) * sl - (A.NeckRun or 0) * run
			end
			ry = look
			rz = 0.18 * sl
		elseif role == "neck" then
			rx = (A.NeckSleep or 0.5) * sl - (A.NeckRun or 0) * run + math.sin(ph * 2) * 0.05 * amp
		elseif role == "jaw" then
			rx = run * (0.25 + 0.2 * math.sin(t * 12)) + id * math.max(0, math.sin(t * 0.6)) ^ 20 * 0.3
		elseif role == "tail" then
			local i = n.index
			local wag = A.Wag or 0.3
			ry = math.sin(t * (A.WagSpeed or 3) * (1 + g) - i * 0.6) * wag * (0.35 + 0.65 * awake)
				+ math.sin(ph - i * 0.5) * 0.15 * amp
				+ 0.5 * sl
			rx = -0.15 * run
			if kind == "swim" then
				ry = math.sin(t * (4 + 6 * g) - i * 0.8) * (A.Wag or 0.45)
			end
		elseif role == "seg" then
			local i = n.index
			ry = math.sin(ph * 0.8 - i * 0.9) * 0.42 * amp
				+ math.sin(t * 1.3 - i * 0.7) * 0.07 * id
				+ (A.Coil or 0.55) * sl
		elseif role == "leg" then
			local swing = n.ph * s * (A.Leg or 0.6) * amp
			if kind == "crawl" then
				ry = swing * 0.9
				rz = side * math.max(0, n.ph * c) * 0.35 * amp
			elseif kind == "fly" then
				rx = 0.35 + math.sin(t * 2 + n.ph) * 0.1
			else
				rx = swing
				local front = string.find(n.name, "F") ~= nil
				local back = string.find(n.name, "B") ~= nil
				local fold = if front then -1.3 elseif back then 1.3 else -1.35
				rx = rx * awake + fold * sl * (A.LegFold or 1)
			end
		elseif role == "arm" then
			rx = n.ph * s * (A.Arm or 0.5) * amp - 0.25 * sl + math.sin(t * 1.1 + side) * 0.05 * id
			rz = side * (0.08 * run + 0.15 * sl)
			if A.ArmsUp then
				rx -= 1.6 * run -- arms up while chasing (Yeti)
			end
		elseif role == "wing" then
			local mode = A.Flap or (if kind == "fly" then "fly" else "bird")
			local flap
			if mode == "fly" then
				flap = 0.25 + 0.95 * math.abs(math.sin(t * (A.FlapSpeed or 18)))
			elseif mode == "big" then
				flap = run * (0.9 + math.sin(t * 9) * 0.6)
					+ W.walk * math.sin(ph) * 0.12
					+ id * math.max(0, math.sin(t * 0.5 + 1)) ^ 20 * 0.6
					- 0.25 * sl
			elseif mode == "none" then
				flap = 0
			else
				flap = run * (0.5 + math.sin(t * 26) * 0.45)
					+ W.walk * stride * (0.12 + math.sin(ph * 2) * 0.08)
					+ id * math.max(0, math.sin(t * 0.9 + 2)) ^ 30 * 0.8
			end
			rz = side * flap
		elseif role == "ear" then
			local twitch = math.max(0, math.sin(t * 1.3 + self.seed + side)) ^ 40 * 0.4
			rz = side * twitch * awake
			rx = -0.1 * run + (A.EarSleep or 0.35) * sl
		elseif role == "fin" then
			if kind == "swim" then
				rz = side * math.sin(t * 5 + side) * 0.3
			else
				rx = n.ph * s * (A.Leg or 0.5) * amp
				ry = side * 0.2 * sl
			end
		elseif role == "hood" then
			ry = side * (0.15 + 0.55 * run - 0.3 * sl)
		end

		if n.parent == self.root and n.role ~= "body" then
			py -= drop -- legs on the root follow the body down
		end
		n.pos = n.base + Vector3.new(px, py, pz)
		n.rot = Vector3.new(rx, ry, rz)
	end
end

-- Call every frame. Blends between moods, poses the joints, moves the parts.
function AnimalRig:Step(dt, mode, speed, pos, heading)
	dt = math.min(dt, 0.1)
	self.t += dt
	self.mode = mode
	local W = self.W
	local f = 1 - math.exp(-5 * dt)
	for k in W do
		W[k] = lerp(W[k], if k == mode then 1 else 0, f)
	end
	self:_pose(dt, speed or 0)

	local asleep = W.sleep > 0.5
	local angry = mode == "run" and W.run > 0.5
	if asleep ~= self.asleep or angry ~= self.angry then
		self:_setFace(asleep, angry)
	end

	for i, z in self.zs do
		local u = (self.t * 0.35 + (i - 1) / 3) % 1
		local a = math.sin(u * math.pi) * math.max(0, W.sleep * 1.4 - 0.4)
		z.gui.Enabled = a > 0.01
		if z.gui.Enabled then
			local k = self.spec.ZScale or self.S / 4
			z.gui.StudsOffset = Vector3.new((0.6 + u + math.sin(u * 6 + i) * 0.15) * k, (1.4 + u * 2.4) * k, 0)
			z.gui.Size = UDim2.new((0.8 + u * 1.2) * k, 0, (0.8 + u * 1.2) * k, 0)
			z.label.TextTransparency = 1 - a
			z.label.TextStrokeTransparency = 1 - a
		end
	end

	self:Place(pos, heading)
end

-- Solves the joints and moves every part in one BulkMoveTo call.
function AnimalRig:Place(pos, heading)
	local S = self.S
	local world = {}
	local root = self.root
	local function solve(n)
		local cf = world[n]
		if cf then
			return cf
		end
		if n == root then
			cf = CFrame.new(pos) * CFrame.Angles(0, heading, 0)
		else
			local r = n.rest + n.rot
			cf = solve(n.parent) * CFrame.new(n.pos * S) * CFrame.Angles(r.X, r.Y, r.Z)
		end
		world[n] = cf
		return cf
	end
	local cfs = table.create(#self.parts)
	for i, p in self.parts do
		cfs[i] = solve(p.node) * p.offset
	end
	workspace:BulkMoveTo(self.list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

function AnimalRig:Destroy()
	self.Model:Destroy()
end

------------------------------------------------------------------------------
-- Wandering
------------------------------------------------------------------------------
local folder = workspace:FindFirstChild("IslandAnimals")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "IslandAnimals"
	folder.Parent = workspace
end

local animals = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function refreshFilter()
	local list = { folder }
	for _, plr in Players:GetPlayers() do
		if plr.Character then
			table.insert(list, plr.Character)
		end
	end
	local eggs = workspace:FindFirstChild("Eggs")
	if eggs then
		table.insert(list, eggs)
	end
	rayParams.FilterDescendantsInstances = list
end

local function groundAt(p: Vector3): Vector3?
	local hit = workspace:Raycast(p + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rayParams)
	return hit and hit.Position
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function angLerp(a, b, f)
	return a + math.atan2(math.sin(b - a), math.cos(b - a)) * f
end

local SWIMS = SPEC.Kind == "swim"

-- a random spot in its area that has ground (or water level for swimmers)
local function pickTarget(a): Vector3?
	for _ = 1, 6 do
		local ang = math.random() * math.pi * 2
		local r = a.radius * math.sqrt(math.random())
		local p = a.home + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
		if SWIMS then
			return p
		end
		local g = groundAt(p)
		if g and math.abs(g.Y - a.home.Y) < CFG.MAX_DROP then
			return g
		end
	end
	return nil
end

local function spawnAt(marker: BasePart)
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanQuery = false
	refreshFilter()
	local count = marker:GetAttribute("Count") or CFG.COUNT
	local radius = marker:GetAttribute("Radius") or CFG.RADIUS
	for _ = 1, count do
		local rig = AnimalRig.Build(SPEC, { Name = "FennecFox", Parent = folder, Scale = 0.9 + math.random() * 0.2 })
		local a = {
			rig = rig,
			home = marker.Position,
			radius = radius,
			mode = "idle",
			timer = math.random() * CFG.IDLE_MAX,
			heading = math.random() * math.pi * 2,
			speed = 0,
			walkSpeed = (SPEC.WalkSpeed or rig.S * 1.8) * (0.85 + math.random() * 0.3),
			acc = 0,
			slot = #animals % 4,
		}
		a.pos = pickTarget(a) or marker.Position
		rig:Step(0, "idle", 0, a.pos, a.heading)
		table.insert(animals, a)
	end
end

local function update(a, dt)
	if a.mode == "idle" then
		a.timer -= dt
		if a.timer <= 0 then
			a.target = pickTarget(a)
			if a.target then
				a.mode = "walk"
			else
				a.timer = 1
			end
		end
	end

	local want = 0
	if a.mode == "walk" then
		local to = flat(a.target - a.pos)
		if to.Magnitude < 1 then
			a.mode = "idle"
			a.timer = CFG.IDLE_MIN + math.random() * (CFG.IDLE_MAX - CFG.IDLE_MIN)
		else
			a.heading = angLerp(a.heading, math.atan2(to.X, to.Z), 1 - math.exp(-4 * dt))
			want = a.walkSpeed
		end
	end
	a.speed = lerp(a.speed, want, 1 - math.exp(-5 * dt))

	local nextPos = a.pos + Vector3.new(math.sin(a.heading), 0, math.cos(a.heading)) * a.speed * dt
	if SWIMS then
		a.pos = Vector3.new(nextPos.X, a.home.Y, nextPos.Z)
	elseif a.speed > 0.01 then
		local g = groundAt(nextPos)
		if not g or math.abs(g.Y - a.pos.Y) > CFG.MAX_STEP then
			-- island edge or a wall: stop and pick somewhere else
			a.speed = 0
			a.mode = "idle"
			a.timer = 0.5
		else
			a.pos = Vector3.new(nextPos.X, lerp(a.pos.Y, g.Y, 1 - math.exp(-20 * dt)), nextPos.Z)
		end
	end

	local draw = a.pos
	if SPEC.Hover then
		draw += Vector3.new(0, SPEC.Hover, 0)
	end
	a.rig:Step(dt, if a.mode == "walk" then "walk" else "idle", a.speed, draw, a.heading)
end

for _, d in workspace:GetDescendants() do
	if d:IsA("BasePart") and d.Name == CFG.SPAWN_NAME then
		spawnAt(d)
	end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d.Name == CFG.SPAWN_NAME then
		task.defer(spawnAt, d)
	end
end)

local frame = 0
RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.1)
	frame += 1
	if frame % 30 == 0 then
		refreshFilter()
	end
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for _, a in animals do
		a.acc += dt
		local d = (a.pos - camPos).Magnitude
		if d < CFG.NEAR or (d < CFG.FAR and frame % 4 == a.slot) then
			update(a, math.min(a.acc, 0.2))
			a.acc = 0
		end
	end
end)
