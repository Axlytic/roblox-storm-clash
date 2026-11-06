--!strict
-- CombatComboController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Directional Combo Engine & Counter Attack
-- Features:
--   • Storm 4 Directional Combos:
--       [J]: Neutral Combo (Forward horizontal strikes -> Heavy Knockdown)
--       [W + J]: Up Combo (Air Launcher -> Opponent launched high for Air Chase)
--       [S + J] / [K]: Down Combo (Low sweeps & downward strikes -> Ground Bounce)
--       [Air + J]: Air Combo (Mid-air homing strikes -> Dive Spike crash)
--   • Storm 4 Counter Attack ([Guard + Attack] / [F + J]):
--       High-risk counter stance that blows rushing attackers flying across arena!
--   • Chakra Dash Cancel (CDC):
--       Cancel attack recovery mid-combo with Chakra Dash to extend infinite strings!
--   • CyberConnect2 Impact Juice:
--       Micro Hitstop (0.05s pause) + Dynamic Camera Shake on heavy hits

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera

-- Configuration
local COMBO_RESET_TIME = 0.85
local MAX_MELEE_RANGE = 8.5
local LUNGE_FORCE = 34

local currentComboIndex = 0
local currentBranch = "Neutral" -- "Neutral" | "Up" | "Down" | "Air"
local lastAttackTime = 0
local isAttacking = false
local isStaggered = false
local lastCounterTime = 0

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evAttack  = combatEvents:WaitForChild("AttackEvent") :: RemoteEvent
local evParry   = combatEvents:WaitForChild("ParryEvent") :: RemoteEvent
local evCounter = combatEvents:WaitForChild("CounterEvent") :: RemoteEvent

-- Bindables
local function getOrMakeBindable(name: string): BindableEvent
	local be = ReplicatedStorage:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = ReplicatedStorage
	end
	return be
end

local evMobileAttack  = getOrMakeBindable("MobileAttackAction")
local evMobileLow     = getOrMakeBindable("MobileLowAttackAction")
local evCDC           = getOrMakeBindable("ChakraDashCancelAction")
local evAnim          = getOrMakeBindable("StormCombatAnimationEvent")

-- Sounds
local SOUND_PUNCH = "rbxasset://sounds/action_footsteps_plastic.mp3"
local SOUND_HEAVY = "rbxasset://sounds/impact_explosion_03.mp3"
local SOUND_SWEEP = "rbxasset://sounds/action_jump.mp3"

local function playSafeSound(soundId: string, parent: Instance, pitch: number, volume: number)
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId
		snd.PlaybackSpeed = pitch
		snd.Volume = volume
		snd.Parent = parent
		snd:Play()
		task.delay(0.5, function() pcall(function() snd:Destroy() end) end)
	end)
end

-- =========================================================
-- SCREEN SHAKE & HITSTOP (CyberConnect2 Impact Juice)
-- =========================================================
local function screenShake(intensity: number, duration: number)
	task.spawn(function()
		local startTime = os.clock()
		while os.clock() - startTime < duration do
			local offset = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity
			)
			Camera.CFrame = Camera.CFrame * CFrame.new(offset)
			RunService.RenderStepped:Wait()
		end
	end)
end

local function triggerHitstop(duration: number)
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local origSpeed = hum.WalkSpeed
		hum.WalkSpeed = 0
		task.delay(duration, function()
			if hum then hum.WalkSpeed = origSpeed end
		end)
	end
end

-- =========================================================
-- VISUAL SLASH / IMPACT EFFECT
-- =========================================================
local function playAttackFX(root: BasePart, isHeavy: boolean, branch: string, index: number)
	local fxPart = Instance.new("Part")
	fxPart.Size = Vector3.new(3.5, 3.5, 0.2)
	local yOffset = if branch == "Down" then -1.2 elseif branch == "Up" then 1.2 else 0.2
	fxPart.CFrame = root.CFrame * CFrame.new(0, yOffset, -2.5) * CFrame.Angles(0, 0, math.random(-35, 35))
	fxPart.Material = Enum.Material.Neon
	
	local fxColor = Color3.fromRGB(0, 235, 255)
	if isHeavy then
		fxColor = Color3.fromRGB(255, 110, 30)
	elseif branch == "Up" then
		fxColor = Color3.fromRGB(180, 100, 255)
	elseif branch == "Down" then
		fxColor = Color3.fromRGB(255, 200, 30)
	elseif branch == "Air" then
		fxColor = Color3.fromRGB(0, 255, 170)
	end

	fxPart.Color = fxColor
	fxPart.Transparency = 0.25
	fxPart.Anchored = true
	fxPart.CanCollide = false
	fxPart.Parent = Workspace

	local tween = TweenService:Create(fxPart, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(5.2, 5.2, 0.2),
	})
	tween:Play()
	tween.Completed:Connect(function() fxPart:Destroy() end)

	local sId = if isHeavy then SOUND_HEAVY elseif branch == "Down" then SOUND_SWEEP else SOUND_PUNCH
	local sPitch = if isHeavy then 1.05 else 1.2 + (index * 0.1)
	playSafeSound(sId, root, sPitch, 0.95)
end

-- =========================================================
-- HIT DETECTION
-- =========================================================
local function findHitTarget(myRoot: BasePart): Model?
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	if LocalPlayer.Character then
		overlap.FilterDescendantsInstances = { LocalPlayer.Character }
	end

	local hitBoxCFrame = myRoot.CFrame * CFrame.new(0, 0, -3.8)
	local hitParts = Workspace:GetPartBoundsInBox(hitBoxCFrame, Vector3.new(5.5, 5.5, 7.0), overlap)

	for _, part in ipairs(hitParts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model ~= LocalPlayer.Character then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				return model
			end
		end
	end
	return nil
end

-- =========================================================
-- STORM 4 COUNTER ATTACK ([Guard + Attack] / [F + J])
-- =========================================================
local function triggerCounterAttack(root: BasePart)
	local now = os.clock()
	if now - lastCounterTime < 3.5 then
		print(">> [Counter Attack] On cooldown! <<")
		return
	end
	lastCounterTime = now

	print(">> [Storm 4 Counter] Stance activated! (0.35s window) <<")
	evCounter:FireServer(true)
	evAnim:Fire("CounterStance", 0.38)

	-- Visual Counter Flash Shield
	local counterPart = Instance.new("Part")
	counterPart.Shape = Enum.PartType.Ball
	counterPart.Size = Vector3.new(5, 5, 5)
	counterPart.CFrame = root.CFrame
	counterPart.Color = Color3.fromRGB(0, 255, 240)
	counterPart.Material = Enum.Material.ForceField
	counterPart.Transparency = 0.2
	counterPart.Anchored = true
	counterPart.CanCollide = false
	counterPart.Parent = Workspace

	local att = Instance.new("Attachment", counterPart)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 230, 80), Color3.fromRGB(0, 240, 255))
	pe.Size = NumberSequence.new(1.8, 0)
	pe.Rate = 90
	pe.Speed = NumberRange.new(8, 20)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Parent = att

	TweenService:Create(counterPart, TweenInfo.new(0.35), { Size = Vector3.new(7.5, 7.5, 7.5), Transparency = 1 }):Play()
	Debris:AddItem(counterPart, 0.40)

	playSafeSound(SOUND_HEAVY, root, 1.6, 1.0)

	task.delay(0.35, function()
		evCounter:FireServer(false)
	end)
end

-- =========================================================
-- EXECUTE DIRECTIONAL ATTACK (Storm 4 Branching Strings)
-- =========================================================
local function executeAttack(forceLow: boolean?)
	if isAttacking or isStaggered then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	-- Check for Storm 4 Counter Attack ([Guard + Attack])
	if LocalPlayer:GetAttribute("IsBlocking") == true then
		triggerCounterAttack(root)
		return
	end

	local now = os.clock()
	if now - lastAttackTime > COMBO_RESET_TIME then
		currentComboIndex = 0
		currentBranch = "Neutral"
	end

	-- Determine Branch: Air, Up (W / Analog Stick Up), Down (S / K / Analog Stick Down), or Neutral
	local isAirborne = hum.FloorMaterial == Enum.Material.Air or math.abs(root.AssemblyLinearVelocity.Y) > 3.0
	local isWHeld = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.DPadUp)
	local isSHeld = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.DPadDown)
	
	-- Mobile Virtual Thumbstick & Gamepad Left Stick Analog Projection
	local moveDir = hum.MoveDirection
	local isAnalogForward = (moveDir.Magnitude > 0.25 and root.CFrame.LookVector:Dot(moveDir.Unit) > 0.45)
	local isAnalogBackward = (moveDir.Magnitude > 0.25 and root.CFrame.LookVector:Dot(moveDir.Unit) < -0.45)

	if isAirborne then
		currentBranch = "Air"
	elseif forceLow or isSHeld or isAnalogBackward then
		currentBranch = "Down"
	elseif isWHeld or isAnalogForward then
		currentBranch = "Up"
	else
		currentBranch = "Neutral"
	end

	local maxHits = if currentBranch == "Air" then 3 else 4
	currentComboIndex = (currentComboIndex % maxHits) + 1
	local isHeavyFinisher = (currentComboIndex == maxHits)

	lastAttackTime = now
	isAttacking = true

	-- Procedural Anime Animation Trigger: Directional Combo (Neutral1..4, Up1..4, Down1..4, Air1..3)
	local animName = currentBranch .. tostring(currentComboIndex)
	local animDur = if isHeavyFinisher then 0.50 else 0.28
	evAnim:Fire(animName, animDur)

	-- Storm 4 Forward Lunge
	local forwardDir = root.CFrame.LookVector
	local lungeSpeed = if isHeavyFinisher then 42 else (if currentBranch == "Down" then 24 else LUNGE_FORCE)
	root.AssemblyLinearVelocity = Vector3.new(forwardDir.X * lungeSpeed, root.AssemblyLinearVelocity.Y, forwardDir.Z * lungeSpeed)

	-- Visual & Sound
	playAttackFX(root, isHeavyFinisher, currentBranch, currentComboIndex)

	-- Hit detection
	local hitTarget = findHitTarget(root)
	local attackType = if currentBranch == "Down" then "Low" elseif currentBranch == "Up" then "High" else "Mid"
	local damage = if isHeavyFinisher then 25 elseif currentComboIndex == 3 then 15 elseif currentComboIndex == 2 then 11 else 8
	local knockback = if isHeavyFinisher then 48 else 4

	if hitTarget then
		-- CyberConnect2 Impact Juice: Hitstop & Camera Shake
		triggerHitstop(0.05)
		if isHeavyFinisher then
			screenShake(0.35, 0.22)
		else
			screenShake(0.12, 0.10)
		end

		evAttack:FireServer(hitTarget, currentComboIndex, attackType, damage, knockback)
	end

	-- Attack recovery cooldown
	local recoveryTime = if isHeavyFinisher then 0.48 else 0.22
	task.delay(recoveryTime, function()
		isAttacking = false
	end)
end

-- =========================================================
-- CHAKRA DASH CANCEL (CDC) - Storm 4 Combo Extensions!
-- =========================================================
evCDC.Event:Connect(function()
	if isAttacking then
		-- Immediately cancel attack recovery!
		isAttacking = false
		currentComboIndex = 0
		print(">> [CDC] Chakra Dash Cancel! Combo recovery cancelled! <<")
	end
end)

-- =========================================================
-- ATTACKER STAGGER (Triggered if Opponent Parries / Counters)
-- =========================================================
local function triggerAttackerParriedStagger()
	isStaggered = true
	isAttacking = false
	currentComboIndex = 0

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	hum.WalkSpeed = 0
	evAnim:Fire("StaggerStun", 1.30)

	local att = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 80, 80))
	pe.Size = NumberSequence.new(1.4, 0)
	pe.Rate = 60
	pe.Speed = NumberRange.new(5, 12)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att

	print(">> [COUNTERED!] Your attack was countered / parried! Staggered for 1.3s! <<")
	screenShake(0.4, 0.3)

	task.delay(1.30, function()
		att:Destroy()
		if hum then hum.WalkSpeed = 16 end
		isStaggered = false
	end)
end

evParry.OnClientEvent:Connect(function(_defender: Player, attacker: Player)
	if attacker == LocalPlayer then
		triggerAttackerParriedStagger()
	end
end)

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- 1. Keyboard [J] (Melee) or Left-Click or Gamepad (Square / X)
	if input.KeyCode == Enum.KeyCode.J or input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonX then
		executeAttack(false)
	-- 2. Keyboard [K] (Dedicated Low Shinobi Sweep) or Gamepad DPadDown
	elseif input.KeyCode == Enum.KeyCode.K or input.KeyCode == Enum.KeyCode.DPadDown then
		executeAttack(true)
	end
end)

-- Mobile Touch Integration
evMobileAttack.Event:Connect(function(isLow: any)
	executeAttack(isLow == true)
end)
evMobileLow.Event:Connect(function()
	executeAttack(true)
end)

print("[CombatComboController] ✅ Loaded — Storm 4 Directional Combos [J / W+J / S+J / Air+J], Counter [F+J], CDC Extension active.")
