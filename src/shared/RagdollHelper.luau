--!strict
-- RagdollHelper.luau
-- SHARED UTILITY: Universal High-Fidelity Physics Ragdoll Engine (Supports R6 & R15 & Custom Dummies)
-- Features:
--   • Seamless transition from animated pose to momentum-conserving physics ragdoll
--   • Realistic BallSocketConstraint joint limits (avoids glitchy hyper-extensions)
--   • Limb collision management with NoCollisionConstraints
--   • Unanchored physics velocity inheritance for dramatic K.O. flight!

local RagdollHelper = {}

-- =========================================================
-- 1. R15 MOTOR6D TO BALLSOCKET CONVERSION
-- =========================================================
local function ragdollR15(char: Model, fatalVel: Vector3?)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end

	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Name ~= "RootJoint" then
			local p0 = desc.Part0
			local p1 = desc.Part1
			if p0 and p1 then
				local att0 = Instance.new("Attachment")
				att0.Name = "RagdollAtt0_" .. desc.Name
				att0.CFrame = desc.C0
				att0.Parent = p0

				local att1 = Instance.new("Attachment")
				att1.Name = "RagdollAtt1_" .. desc.Name
				att1.CFrame = desc.C1
				att1.Parent = p1

				local socket = Instance.new("BallSocketConstraint")
				socket.Name = "RagdollSocket_" .. desc.Name
				socket.Attachment0 = att0
				socket.Attachment1 = att1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true
				socket.UpperAngle = 45
				socket.TwistLowerAngle = -45
				socket.TwistUpperAngle = 45
				socket.Parent = p0

				local noCol = Instance.new("NoCollisionConstraint")
				noCol.Part0 = p0
				noCol.Part1 = p1
				noCol.Parent = p0

				desc.Enabled = false
			end
		end

		if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
			desc.CanCollide = true
			desc.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.4, 0.2, 1, 1)
		end
	end

	-- Apply fatal momentum
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") :: BasePart?
	local targetPart = torso or root
	if targetPart and fatalVel then
		targetPart.AssemblyLinearVelocity = fatalVel
		targetPart.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-10, 10), math.random(-15, 15))
	end
end

-- =========================================================
-- 2. R6 & CUSTOM TRAINING DUMMY RAGDOLL CONVERSION
-- =========================================================
local function ragdollR6OrDummy(char: Model, fatalVel: Vector3?)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end

	-- Disable upright physics gyro / AlignOrientation if present
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("AlignOrientation") or child:IsA("BodyGyro") then
				child:Destroy()
			end
		end
	end

	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") :: BasePart?
	if not torso then return end

	-- Joint configurations: { LimbName, OffsetOnTorso, OffsetOnLimb, UpperAngle }
	local jointConfigs = {
		{ name = "Head",       p0 = Vector3.new(0, 1.0, 0),    p1 = Vector3.new(0, -0.6, 0), angle = 35 },
		{ name = "LeftArm",    p0 = Vector3.new(-1.5, 0.5, 0), p1 = Vector3.new(0, 0.5, 0),  angle = 65 },
		{ name = "Left Arm",   p0 = Vector3.new(-1.5, 0.5, 0), p1 = Vector3.new(0, 0.5, 0),  angle = 65 },
		{ name = "RightArm",   p0 = Vector3.new(1.5, 0.5, 0),  p1 = Vector3.new(0, 0.5, 0),  angle = 65 },
		{ name = "Right Arm",  p0 = Vector3.new(1.5, 0.5, 0),  p1 = Vector3.new(0, 0.5, 0),  angle = 65 },
		{ name = "LeftLeg",    p0 = Vector3.new(-0.5, -1.0, 0), p1 = Vector3.new(0, 1.0, 0), angle = 55 },
		{ name = "Left Leg",   p0 = Vector3.new(-0.5, -1.0, 0), p1 = Vector3.new(0, 1.0, 0), angle = 55 },
		{ name = "RightLeg",   p0 = Vector3.new(0.5, -1.0, 0),  p1 = Vector3.new(0, 1.0, 0), angle = 55 },
		{ name = "Right Leg",  p0 = Vector3.new(0.5, -1.0, 0),  p1 = Vector3.new(0, 1.0, 0), angle = 55 },
	}

	-- Remove rigid welds and create ball-and-socket ragdoll joints
	for _, cfg in ipairs(jointConfigs) do
		local limb = char:FindFirstChild(cfg.name) :: BasePart?
		if limb and limb ~= torso then
			-- Remove any existing rigid welds/motor6D
			for _, w in ipairs(char:GetDescendants()) do
				if (w:IsA("WeldConstraint") or w:IsA("Weld") or w:IsA("Motor6D")) and (w.Part0 == limb or w.Part1 == limb) then
					w:Destroy()
				end
			end

			local att0 = Instance.new("Attachment")
			att0.Name = "RagdollAtt0_" .. cfg.name
			att0.Position = cfg.p0
			att0.Parent = torso

			local att1 = Instance.new("Attachment")
			att1.Name = "RagdollAtt1_" .. cfg.name
			att1.Position = cfg.p1
			att1.Parent = limb

			local socket = Instance.new("BallSocketConstraint")
			socket.Name = "RagdollSocket_" .. cfg.name
			socket.Attachment0 = att0
			socket.Attachment1 = att1
			socket.LimitsEnabled = true
			socket.UpperAngle = cfg.angle
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle = -35
			socket.TwistUpperAngle = 35
			socket.Parent = torso

			local noCol = Instance.new("NoCollisionConstraint")
			noCol.Part0 = torso
			noCol.Part1 = limb
			noCol.Parent = torso

			limb.CanCollide = true
			limb.CustomPhysicalProperties = PhysicalProperties.new(0.65, 0.35, 0.25, 1, 1)
		end
	end

	torso.CanCollide = true
	torso.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.4, 0.2, 1, 1)

	-- Apply fatal momentum
	if fatalVel then
		torso.AssemblyLinearVelocity = fatalVel
		torso.AssemblyAngularVelocity = Vector3.new(math.random(-18, 18), math.random(-12, 12), math.random(-18, 18))
	end
end

-- =========================================================
-- 3. PUBLIC ENTRYPOINT
-- =========================================================
function RagdollHelper.EnableRagdoll(char: Model, fatalVelocity: Vector3?)
	if not char or not char.Parent then return end
	if char:GetAttribute("IsRagdolled") == true then return end
	char:SetAttribute("IsRagdolled", true)

	local hum = char:FindFirstChildOfClass("Humanoid")
	local isR15 = hum and hum.RigType == Enum.HumanoidRigType.R15

	if isR15 then
		ragdollR15(char, fatalVelocity)
	else
		ragdollR6OrDummy(char, fatalVelocity)
	end
end

return RagdollHelper
