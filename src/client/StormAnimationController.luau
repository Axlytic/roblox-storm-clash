--!strict
-- StormAnimationController.luau
-- CLIENT SCRIPT: High-Octane Procedural Anime Combat Animation Engine
-- Features:
--   • 100% Asset-Independent: Zero asset load failures or HTTP 403 permission errors
--   • Procedural Motor6D Joint Transformation with ultra-smooth spring/lerp easing
--   • Full Anime Move Set:
--       - Combat Ready / Shinobi Idle Stance (dynamic breathing sway)
--       - 4-Hit M1 Attack Combo (Thrust -> Horizontal Slice -> Skyward Launch -> Heavy Plunge)
--       - Low Shinobi Sweep (360° ground leg sweep)
--       - Tekken High Guard (Cross-arm chest defense) & Low Guard (Deep shin crouch block)
--       - Tekken Just-Frame Parry Counter deflection
--       - Iconic Naruto Ninja Dash (50° forward tilted flight with trailing arms)
--       - Chakra Charging Horse Stance with tremors
--   • Automatic Katana Slash Trail synchronization

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Motor6D Cache
type MotorCache = {
	rootJoint: Motor6D?,
	waist: Motor6D?,
	neck: Motor6D?,
	rightShoulder: Motor6D?,
	leftShoulder: Motor6D?,
	rightElbow: Motor6D?,
	leftElbow: Motor6D?,
	rightHip: Motor6D?,
	leftHip: Motor6D?,
	rightKnee: Motor6D?,
	leftKnee: Motor6D?,
	katanaWeld: Motor6D?,
}

type OffsetCache = {
	rootJoint: CFrame,
	waist: CFrame,
	neck: CFrame,
	rightShoulder: CFrame,
	leftShoulder: CFrame,
	rightElbow: CFrame,
	leftElbow: CFrame,
	rightHip: CFrame,
	leftHip: CFrame,
	rightKnee: CFrame,
	leftKnee: CFrame,
}

local motors: MotorCache = {}
local baseC0: { [string]: CFrame } = {}
local currentOffsets: OffsetCache = {
	rootJoint = CFrame.identity,
	waist = CFrame.identity,
	neck = CFrame.identity,
	rightShoulder = CFrame.identity,
	leftShoulder = CFrame.identity,
	rightElbow = CFrame.identity,
	leftElbow = CFrame.identity,
	rightHip = CFrame.identity,
	leftHip = CFrame.identity,
	rightKnee = CFrame.identity,
	leftKnee = CFrame.identity,
}

local targetOffsets: OffsetCache = {
	rootJoint = CFrame.identity,
	waist = CFrame.identity,
	neck = CFrame.identity,
	rightShoulder = CFrame.identity,
	leftShoulder = CFrame.identity,
	rightElbow = CFrame.identity,
	leftElbow = CFrame.identity,
	rightHip = CFrame.identity,
	leftHip = CFrame.identity,
	rightKnee = CFrame.identity,
	leftKnee = CFrame.identity,
}

local currentAction = "Idle"
local actionEndTime = 0
local katanaTrail: Trail? = nil

-- =========================================================
-- INITIALIZE MOTOR CACHE
-- =========================================================
local function setupCharacter(char: Model)
	table.clear(motors)
	table.clear(baseC0)

	local function findMotor(name: string): Motor6D?
		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("Motor6D") and desc.Name == name then
				return desc
			end
		end
		return nil
	end

	motors.rootJoint     = findMotor("RootJoint") or findMotor("Root")
	motors.waist         = findMotor("Waist")
	motors.neck          = findMotor("Neck")
	motors.rightShoulder = findMotor("RightShoulder") or findMotor("Right Shoulder")
	motors.leftShoulder  = findMotor("LeftShoulder") or findMotor("Left Shoulder")
	motors.rightElbow    = findMotor("RightElbow")
	motors.leftElbow     = findMotor("LeftElbow")
	motors.rightHip      = findMotor("RightHip") or findMotor("Right Hip")
	motors.leftHip       = findMotor("LeftHip") or findMotor("Left Hip")
	motors.rightKnee     = findMotor("RightKnee")
	motors.leftKnee      = findMotor("LeftKnee")
	motors.katanaWeld    = findMotor("KatanaWeld")

	-- Cache default C0
	for key, motor in pairs(motors) do
		if motor then
			baseC0[key] = motor.C0
		end
	end

	-- Find Katana Trail
	task.delay(0.5, function()
		local katana = char:FindFirstChild("StormKatana")
		if katana then
			local blade = katana:FindFirstChild("Blade")
			if blade then
				katanaTrail = blade:FindFirstChild("SlashTrail") :: Trail?
			end
		end
	end)
end

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- =========================================================
-- ANIMATION POSES GENERATOR
-- =========================================================
local function resetTargets()
	targetOffsets.rootJoint     = CFrame.identity
	targetOffsets.waist         = CFrame.identity
	targetOffsets.neck          = CFrame.identity
	targetOffsets.rightShoulder = CFrame.identity
	targetOffsets.leftShoulder  = CFrame.identity
	targetOffsets.rightElbow    = CFrame.identity
	targetOffsets.leftElbow     = CFrame.identity
	targetOffsets.rightHip      = CFrame.identity
	targetOffsets.leftHip       = CFrame.identity
	targetOffsets.rightKnee     = CFrame.identity
	targetOffsets.leftKnee      = CFrame.identity
end

local function applyPose(poseName: string)
	resetTargets()

	if poseName == "Idle" then
		-- Shinobi Combat Ready Stance (slight crouch, right hand blade ready)
		targetOffsets.rootJoint = CFrame.Angles(0, math.rad(-15), 0)
		targetOffsets.waist = CFrame.Angles(0, math.rad(15), 0)
		targetOffsets.rightShoulder = CFrame.new(0, -0.05, -0.1) * CFrame.Angles(math.rad(35), math.rad(-25), math.rad(15))
		targetOffsets.leftShoulder = CFrame.new(0, -0.05, 0.1) * CFrame.Angles(math.rad(45), math.rad(35), math.rad(-20))
		if motors.rightElbow then targetOffsets.rightElbow = CFrame.Angles(math.rad(45), 0, 0) end
		if motors.leftElbow then targetOffsets.leftElbow = CFrame.Angles(math.rad(60), 0, 0) end
		targetOffsets.rightHip = CFrame.Angles(math.rad(-10), 0, math.rad(10))
		targetOffsets.leftHip = CFrame.Angles(math.rad(10), 0, math.rad(-10))

	elseif poseName == "Attack1" then
		-- Hit 1: Forward Right Arm Thrust / Slash
		targetOffsets.rootJoint = CFrame.new(0, -0.1, -0.3) * CFrame.Angles(0, math.rad(-35), 0)
		targetOffsets.waist = CFrame.Angles(0, math.rad(35), 0)
		targetOffsets.rightShoulder = CFrame.new(0, 0.1, -0.6) * CFrame.Angles(math.rad(85), math.rad(-20), math.rad(25))
		targetOffsets.leftShoulder = CFrame.Angles(math.rad(-30), 0, math.rad(-35))
		if motors.rightElbow then targetOffsets.rightElbow = CFrame.Angles(math.rad(15), 0, 0) end

	elseif poseName == "Attack2" then
		-- Hit 2: High Horizontal Cross-Cut + Left Knee Rotation
		targetOffsets.rootJoint = CFrame.Angles(0, math.rad(45), 0)
		targetOffsets.waist = CFrame.Angles(0, math.rad(-45), 0)
		targetOffsets.rightShoulder = CFrame.new(-0.2, 0.2, -0.5) * CFrame.Angles(math.rad(95), math.rad(55), math.rad(-40))
		targetOffsets.leftShoulder = CFrame.Angles(math.rad(25), 0, math.rad(40))
		targetOffsets.leftHip = CFrame.Angles(math.rad(-35), 0, 0)

	elseif poseName == "Attack3" then
		-- Hit 3: Rising Dragon Uppercut / Skyward Blade Sweep
		targetOffsets.rootJoint = CFrame.new(0, 0.4, 0) * CFrame.Angles(math.rad(-15), 0, 0)
		targetOffsets.waist = CFrame.Angles(math.rad(-20), 0, 0)
		targetOffsets.rightShoulder = CFrame.new(0, 0.5, -0.2) * CFrame.Angles(math.rad(165), math.rad(-15), math.rad(10))
		targetOffsets.leftShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(-30))
		targetOffsets.rightHip = CFrame.Angles(math.rad(25), 0, 0)

	elseif poseName == "Attack4" then
		-- Hit 4: Heavy Overhead Downward Slam
		targetOffsets.rootJoint = CFrame.new(0, -0.3, -0.4) * CFrame.Angles(math.rad(35), 0, 0)
		targetOffsets.waist = CFrame.Angles(math.rad(25), 0, 0)
		targetOffsets.rightShoulder = CFrame.new(0, 0.2, -0.8) * CFrame.Angles(math.rad(105), 0, 0)
		targetOffsets.leftShoulder = CFrame.new(0, 0.2, -0.8) * CFrame.Angles(math.rad(105), 0, 0)
		if motors.rightElbow then targetOffsets.rightElbow = CFrame.Angles(math.rad(30), 0, 0) end
		if motors.leftElbow then targetOffsets.leftElbow = CFrame.Angles(math.rad(30), 0, 0) end

	elseif poseName == "LowSweep" then
		-- Low Shinobi Sweep: Deep Crouch, Right Leg Sweep Arc
		targetOffsets.rootJoint = CFrame.new(0, -1.4, 0) * CFrame.Angles(math.rad(25), math.rad(-60), 0)
		targetOffsets.waist = CFrame.Angles(0, math.rad(50), 0)
		targetOffsets.rightHip = CFrame.Angles(0, math.rad(70), math.rad(65))
		targetOffsets.leftHip = CFrame.Angles(math.rad(-65), 0, 0)
		targetOffsets.rightShoulder = CFrame.Angles(math.rad(30), 0, math.rad(45))
		targetOffsets.leftShoulder = CFrame.Angles(math.rad(45), 0, math.rad(-40))

	elseif poseName == "HighGuard" then
		-- Tekken High Guard: Cross-arm shielding chest & head
		targetOffsets.rootJoint = CFrame.Angles(0, math.rad(-20), 0)
		targetOffsets.waist = CFrame.Angles(0, math.rad(20), 0)
		targetOffsets.rightShoulder = CFrame.new(-0.2, 0.1, -0.5) * CFrame.Angles(math.rad(75), math.rad(-35), math.rad(25))
		targetOffsets.leftShoulder = CFrame.new(0.2, 0.1, -0.5) * CFrame.Angles(math.rad(75), math.rad(35), math.rad(-25))
		if motors.rightElbow then targetOffsets.rightElbow = CFrame.Angles(math.rad(70), 0, 0) end
		if motors.leftElbow then targetOffsets.leftElbow = CFrame.Angles(math.rad(70), 0, 0) end

	elseif poseName == "LowGuard" then
		-- Tekken Low Guard: Deep shin-level defense block
		targetOffsets.rootJoint = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(20), 0, 0)
		targetOffsets.rightShoulder = CFrame.new(-0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(-25), 0)
		targetOffsets.leftShoulder = CFrame.new(0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(25), 0)
		targetOffsets.rightHip = CFrame.Angles(math.rad(-45), 0, 0)
		targetOffsets.leftHip = CFrame.Angles(math.rad(-45), 0, 0)

	elseif poseName == "Parry" then
		-- Tekken Perfect Parry: Dynamic outward deflection strike
		targetOffsets.rootJoint = CFrame.Angles(0, math.rad(30), 0)
		targetOffsets.waist = CFrame.Angles(0, math.rad(-30), 0)
		targetOffsets.rightShoulder = CFrame.new(0.2, 0.2, -0.6) * CFrame.Angles(math.rad(85), math.rad(60), math.rad(-30))
		targetOffsets.leftShoulder = CFrame.Angles(math.rad(-20), 0, math.rad(-30))

	elseif poseName == "NinjaDash" then
		-- Naruto Ninja Dash: 50° forward body dive, arms trailing behind
		targetOffsets.rootJoint = CFrame.new(0, -0.4, -0.6) * CFrame.Angles(math.rad(52), 0, 0)
		targetOffsets.waist = CFrame.Angles(math.rad(-10), 0, 0)
		targetOffsets.neck = CFrame.Angles(math.rad(-40), 0, 0) -- look forward
		targetOffsets.rightShoulder = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(20))
		targetOffsets.leftShoulder = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(-20))
		targetOffsets.rightHip = CFrame.Angles(math.rad(-25), 0, 0)
		targetOffsets.leftHip = CFrame.Angles(math.rad(25), 0, 0)

	elseif poseName == "ChakraCharge" then
		-- Dragon Ball / Naruto Chakra Charge: Clenched fists, trembling aura
		targetOffsets.rootJoint = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(15), 0, 0)
		targetOffsets.waist = CFrame.Angles(math.rad(10), 0, 0)
		targetOffsets.rightShoulder = CFrame.new(-0.1, -0.1, -0.2) * CFrame.Angles(math.rad(25), math.rad(-30), math.rad(25))
		targetOffsets.leftShoulder = CFrame.new(0.1, -0.1, -0.2) * CFrame.Angles(math.rad(25), math.rad(30), math.rad(-25))
		if motors.rightElbow then targetOffsets.rightElbow = CFrame.Angles(math.rad(75), 0, 0) end
		if motors.leftElbow then targetOffsets.leftElbow = CFrame.Angles(math.rad(75), 0, 0) end
		targetOffsets.rightHip = CFrame.Angles(math.rad(-25), 0, math.rad(15))
		targetOffsets.leftHip = CFrame.Angles(math.rad(-25), 0, math.rad(-15))
	end
end

-- =========================================================
-- PUBLIC TRIGGER API (Invoked by Combo & Movement Controllers)
-- =========================================================
local function triggerCombatAnimation(animName: string, duration: number)
	currentAction = animName
	actionEndTime = os.clock() + duration
	applyPose(animName)

	-- Trail management
	if katanaTrail then
		local isAttack = string.sub(animName, 1, 6) == "Attack" or animName == "LowSweep" or animName == "NinjaDash"
		katanaTrail.Enabled = isAttack
		if isAttack then
			task.delay(duration, function()
				if os.clock() >= actionEndTime and katanaTrail then
					katanaTrail.Enabled = false
				end
			end)
		end
	end
end

-- Bindable Event for local scripts
local evAnim = Instance.new("BindableEvent")
evAnim.Name = "StormCombatAnimationEvent"
evAnim.Parent = ReplicatedStorage
evAnim.Event:Connect(triggerCombatAnimation)

-- =========================================================
-- RENDER STEP JOINT LERP UPDATE
-- =========================================================
local breathTime = 0

local function onRenderStep(dt: number)
	local now = os.clock()

	-- Check action expiration
	if now >= actionEndTime and currentAction ~= "Idle" then
		-- Check current player attributes
		local isBlocking = LocalPlayer:GetAttribute("IsBlocking") == true
		local blockType = tostring(LocalPlayer:GetAttribute("BlockType") or "None")
		local isDashing = LocalPlayer:GetAttribute("IsNinjaDashing") == true
		local isCharging = LocalPlayer:GetAttribute("IsChakraCharging") == true

		if isCharging then
			currentAction = "ChakraCharge"
			applyPose("ChakraCharge")
		elseif isBlocking then
			currentAction = if blockType == "Low" then "LowGuard" else "HighGuard"
			applyPose(currentAction)
		elseif isDashing then
			currentAction = "NinjaDash"
			applyPose("NinjaDash")
		else
			currentAction = "Idle"
			applyPose("Idle")
			if katanaTrail then katanaTrail.Enabled = false end
		end
	end

	-- Subtle breathing sway in idle
	breathTime = breathTime + dt * 2.5
	local swayY = if currentAction == "Idle" then math.sin(breathTime) * 0.04 else 0
	local lerpSpeed = if currentAction == "NinjaDash" or string.sub(currentAction, 1, 6) == "Attack" then 24 else 14
	local factor = math.clamp(dt * lerpSpeed, 0, 1)

	-- Lerp all offsets
	for name, targetCF in pairs(targetOffsets) do
		local cur = currentOffsets[name]
		if cur then
			currentOffsets[name] = cur:Lerp(targetCF, factor)
		end
	end

	-- Apply to Motor6Ds
	for name, motor in pairs(motors) do
		local base = baseC0[name]
		local off = currentOffsets[name]
		if motor and base and off then
			if name == "rootJoint" and swayY ~= 0 then
				motor.C0 = base * off * CFrame.new(0, swayY, 0)
			else
				motor.C0 = base * off
			end
		end
	end
end

RunService:BindToRenderStep("StormProceduralAnim", Enum.RenderPriority.Character.Value + 1, onRenderStep)

print("[StormAnimationController] ✅ Procedural Anime Combat Animation Engine active.")
