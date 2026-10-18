--!nonstrict
-- Knocks a player flat for a few seconds: their joints turn into ball sockets
-- (same trick as the guardians' catch) and PlatformStand lets them tip over,
-- with a little shove so they fall onto their back. Then they get back up.
-- The player gets a "KnockedDown" attribute while they're down.

local Knockdown = {}

local function ragdoll(character: Model)
	local made = {}
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") and motor.Name ~= "Root" and motor.Name ~= "RootJoint" and motor.Part0 and motor.Part1 then
			local a0 = Instance.new("Attachment")
			a0.Name = "KnockA0"
			a0.CFrame = motor.C0
			a0.Parent = motor.Part0
			local a1 = Instance.new("Attachment")
			a1.Name = "KnockA1"
			a1.CFrame = motor.C1
			a1.Parent = motor.Part1
			local socket = Instance.new("BallSocketConstraint")
			socket.Name = "Knock"
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.UpperAngle = 50
			socket.TwistLowerAngle = -40
			socket.TwistUpperAngle = 40
			socket.Parent = motor.Part0
			motor.Enabled = false
			table.insert(made, { motor, a0, a1, socket })
		end
	end
	return made
end

function Knockdown.IsDown(player: Player): boolean
	return player:GetAttribute("KnockedDown") == true
end

-- Knocks the player down for `seconds`. Does nothing if they're already down.
function Knockdown.Fall(player: Player, seconds: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 or Knockdown.IsDown(player) then
		return
	end
	player:SetAttribute("KnockedDown", true)
	humanoid.PlatformStand = true
	local made = ragdoll(character)

	-- Tip over backwards: a short spin around the character's right axis.
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockTip"
	attachment.Parent = root
	local tip = Instance.new("AngularVelocity")
	tip.Name = "KnockTip"
	tip.Attachment0 = attachment
	tip.RelativeTo = Enum.ActuatorRelativeTo.World
	tip.MaxTorque = 1e6
	tip.AngularVelocity = root.CFrame.RightVector * 6
	tip.Parent = root
	task.delay(0.35, function()
		tip:Destroy()
		attachment:Destroy()
	end)

	task.delay(seconds, function()
		for _, entry in made do
			if entry[1].Parent then
				entry[1].Enabled = true
			end
			entry[2]:Destroy()
			entry[3]:Destroy()
			entry[4]:Destroy()
		end
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		player:SetAttribute("KnockedDown", nil)
	end)
end

return Knockdown
