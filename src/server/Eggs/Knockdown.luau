--!nonstrict
-- Knocks a player flat for a few seconds: no ragdoll, they slide into lying
-- face down on the ground (arms out, legs straight) and stay there, then get
-- back up smoothly. PlatformStand turns the humanoid off, and AlignPosition /
-- AlignOrientation on the root hold the body in place (the owning client
-- simulates them, everyone else sees the root through replication). The limb
-- pose is in Client.Movement.JumpPose (the lying block), driven by the
-- character's LieAt / LieUntil attributes (server times).
-- The player gets a "KnockedDown" attribute while they're down.

local Knockdown = {}

local RISE_TIME = 0.45 -- last part of the knockdown: rising back to standing

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

local function groundBelow(position: Vector3, character: Model): Vector3?
	groundParams.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), groundParams)
	return hit and hit.Position
end

function Knockdown.IsDown(player: Player): boolean
	return player:GetAttribute("KnockedDown") == true
end

-- Knocks the player down for `seconds`. They lie face down at `spot` (a point
-- on the ground, head pointing along `facing`), or where they stand if it's
-- missing or has no ground. Does nothing if they're already down.
function Knockdown.Fall(player: Player, seconds: number, spot: Vector3?, facing: Vector3?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 or Knockdown.IsDown(player) then
		return
	end

	local forward = facing or root.CFrame.LookVector
	forward = Vector3.new(forward.X, 0, forward.Z)
	forward = if forward.Magnitude > 0.1 then forward.Unit else Vector3.new(0, 0, -1)
	local ground = spot and groundBelow(spot, character)
	if not ground or math.abs(ground.Y - root.Position.Y) > 10 then
		ground = groundBelow(root.Position, character) or (root.Position - Vector3.new(0, 3, 0))
	end

	-- Face down: head points forward, face points at the ground.
	local right = forward:Cross(Vector3.yAxis)
	local lie = CFrame.fromMatrix(ground + Vector3.new(0, root.Size.Z / 2 + 0.1, 0), right, forward, Vector3.yAxis)
	local standY = if humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight + root.Size.Y / 2 else 3
	local stand = CFrame.lookAt(ground + Vector3.new(0, standY, 0), ground + Vector3.new(0, standY, 0) + forward)

	player:SetAttribute("KnockedDown", true)
	local now = workspace:GetServerTimeNow()
	character:SetAttribute("LieAt", now)
	character:SetAttribute("LieUntil", now + seconds)
	humanoid.PlatformStand = true

	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockLie"
	attachment.Parent = root
	local hold = Instance.new("AlignPosition")
	hold.Name = "KnockLie"
	hold.Mode = Enum.PositionAlignmentMode.OneAttachment
	hold.Attachment0 = attachment
	hold.MaxForce = 1e6
	hold.MaxVelocity = 40
	hold.Responsiveness = 25
	hold.Position = lie.Position
	hold.Parent = root
	local turn = Instance.new("AlignOrientation")
	turn.Name = "KnockLie"
	turn.Mode = Enum.OrientationAlignmentMode.OneAttachment
	turn.Attachment0 = attachment
	turn.MaxTorque = 1e6
	turn.MaxAngularVelocity = 14
	turn.Responsiveness = 20
	turn.CFrame = lie.Rotation
	turn.Parent = root

	-- Get back up: swing upright over the last moment, then let go.
	task.delay(math.max(seconds - RISE_TIME, 0), function()
		if hold.Parent then
			hold.Position = stand.Position
			turn.CFrame = stand.Rotation
		end
	end)
	task.delay(seconds, function()
		hold:Destroy()
		turn:Destroy()
		attachment:Destroy()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if character.Parent then
			character:SetAttribute("LieAt", nil)
			character:SetAttribute("LieUntil", nil)
		end
		player:SetAttribute("KnockedDown", nil)
	end)
end

return Knockdown
