--!nonstrict
-- Jump animation for every character, R15 or R6, worked out from how fast it's
-- going up or down (normal jumps, trampoline bounces, launches, falls):
--   going up    -> stretched out, arms up over the head
--   at the top  -> tucked: knees up to the chest, arms hugging
--   coming down -> arms out to the sides, legs ready to land
-- It turns the shoulder / hip (and on R15 elbow / knee) joints on top of
-- Roblox's own animations, blending in when you leave the ground and out when
-- you land. Runs on every client for every nearby character, so everyone sees
-- everyone's jumps (joint changes made on a client don't replicate).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX_DISTANCE = 160 -- characters further than this from the camera aren't posed
local SPEED_RANGE = 28 -- studs/s of vertical speed for a full rise or fall pose
local AIR_DELAY = 0.08 -- seconds in the air before the pose starts (skips tiny bumps)

-- Rotations in the torso's frame (X right, Y up, Z back), as radians.
-- +X on an arm or leg swings it forward/up; +Z swings it out to the right.
local POSES = {
	Rise = {
		ArmL = Vector3.new(2.75, 0, -0.25), ArmR = Vector3.new(2.75, 0, 0.25),
		ElbowL = Vector3.new(0.15, 0, 0), ElbowR = Vector3.new(0.15, 0, 0),
		LegL = Vector3.new(-0.12, 0, -0.06), LegR = Vector3.new(-0.12, 0, 0.06),
		KneeL = Vector3.new(-0.1, 0, 0), KneeR = Vector3.new(-0.1, 0, 0),
	},
	Tuck = {
		ArmL = Vector3.new(1.0, 0, -0.45), ArmR = Vector3.new(1.0, 0, 0.45),
		ElbowL = Vector3.new(1.3, 0, 0), ElbowR = Vector3.new(1.3, 0, 0),
		LegL = Vector3.new(1.45, 0, -0.12), LegR = Vector3.new(1.45, 0, 0.12),
		KneeL = Vector3.new(-1.9, 0, 0), KneeR = Vector3.new(-1.9, 0, 0),
	},
	Fall = {
		ArmL = Vector3.new(0.35, 0, -1.55), ArmR = Vector3.new(0.35, 0, 1.55),
		ElbowL = Vector3.new(0.35, 0, 0), ElbowR = Vector3.new(0.35, 0, 0),
		LegL = Vector3.new(0.4, 0, -0.18), LegR = Vector3.new(0.4, 0, 0.18),
		KneeL = Vector3.new(-0.6, 0, 0), KneeR = Vector3.new(-0.6, 0, 0),
	},
}

-- Joint names per rig: R15 joints sit in the limb, R6 joints in the Torso.
local R15_JOINTS = {
	ArmL = { "LeftUpperArm", "LeftShoulder" }, ArmR = { "RightUpperArm", "RightShoulder" },
	ElbowL = { "LeftLowerArm", "LeftElbow" }, ElbowR = { "RightLowerArm", "RightElbow" },
	LegL = { "LeftUpperLeg", "LeftHip" }, LegR = { "RightUpperLeg", "RightHip" },
	KneeL = { "LeftLowerLeg", "LeftKnee" }, KneeR = { "RightLowerLeg", "RightKnee" },
}
local R6_JOINTS = {
	ArmL = { "Torso", "Left Shoulder" }, ArmR = { "Torso", "Right Shoulder" },
	LegL = { "Torso", "Left Hip" }, LegR = { "Torso", "Right Hip" },
}

local rigs = {} -- [character] = { Humanoid, Root, Joints = { role = { Motor, Base } }, Air, AirTime, Posed }

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function setup(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		return
	end
	local names = if humanoid.RigType == Enum.HumanoidRigType.R15 then R15_JOINTS else R6_JOINTS
	local joints = {}
	for role, where in names do
		local part = character:WaitForChild(where[1], 5)
		local motor = part and part:WaitForChild(where[2], 5)
		if motor and motor:IsA("Motor6D") then
			joints[role] = { Motor = motor, Base = motor.C0 }
		end
	end
	rigs[character] = { Humanoid = humanoid, Root = root, Joints = joints, Air = 0, AirTime = 0, Posed = false }
end

local function watchPlayer(p: Player)
	if p.Character then
		task.spawn(setup, p.Character)
	end
	p.CharacterAdded:Connect(function(character)
		task.spawn(setup, character)
	end)
	p.CharacterRemoving:Connect(function(character)
		rigs[character] = nil
	end)
end

for _, p in Players:GetPlayers() do
	watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)

local function restore(rig)
	for _, j in rig.Joints do
		if j.Motor.Parent then
			j.Motor.C0 = j.Base
		end
	end
	rig.Posed = false
end

local function grounded(character, rig): boolean
	local reach = rig.Humanoid.HipHeight + rig.Root.Size.Y / 2 + 1.2
	if rig.Humanoid.RigType == Enum.HumanoidRigType.R6 then
		reach = 4.2
	end
	rayParams.FilterDescendantsInstances = { character }
	return workspace:Raycast(rig.Root.Position, Vector3.new(0, -reach, 0), rayParams) ~= nil
end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for character, rig in rigs do
		if not character.Parent or not rig.Root.Parent then
			rigs[character] = nil
			continue
		end
		local owner = Players:GetPlayerFromCharacter(character)
		local skip = rig.Humanoid.Health <= 0
			or rig.Humanoid.Sit
			or (owner and owner:GetAttribute("KnockedDown"))
			or (rig.Root.Position - camPos).Magnitude > MAX_DISTANCE
		if skip then
			if rig.Posed then
				restore(rig)
			end
			rig.Air = 0
			continue
		end

		local inAir = not grounded(character, rig)
		rig.AirTime = if inAir then rig.AirTime + dt else 0
		local target = if rig.AirTime > AIR_DELAY then 1 else 0
		-- blend in fast, snap out a bit faster on landing
		rig.Air += (target - rig.Air) * (1 - math.exp(-(if target > rig.Air then 12 else 18) * dt))
		if rig.Air < 0.01 then
			if rig.Posed then
				restore(rig)
			end
			continue
		end

		local vy = rig.Root.AssemblyLinearVelocity.Y
		local rise = math.clamp((vy - 4) / SPEED_RANGE, 0, 1)
		local fall = math.clamp((-vy - 4) / SPEED_RANGE, 0, 1)
		local tuck = math.max(0, 1 - rise - fall)
		for role, j in rig.Joints do
			if j.Motor.Parent then
				local angles = (POSES.Rise[role] * rise + POSES.Tuck[role] * tuck + POSES.Fall[role] * fall) * rig.Air
				-- rotate about the joint in the torso's frame, keeping the joint's own offset
				j.Motor.C0 = CFrame.new(j.Base.Position) * CFrame.Angles(angles.X, angles.Y, angles.Z) * j.Base.Rotation
			end
		end
		rig.Posed = true
	end
end)
