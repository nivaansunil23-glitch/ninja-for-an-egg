-- Stops your character tripping over and flying off when it bumps into things.
-- Roblox's FallingDown and Ragdoll states kick in on hard bumps; we never want
-- them. Being caught by a guardian still ragdolls you (GuardianBrain does that
-- with PlatformStand and ball sockets, not these states).

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
end

if player.Character then
	onCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacter)
