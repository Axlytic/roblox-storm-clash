local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormMovementController')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormMovementController'
s.Source = [=====[--!strict
-- StormMovementController.luau
-- CLIENT SCRIPT: Naruto x Boruto Storm Connections Movement Engine + Chakra Charging
-- Features:
--   • WASD 3D Orbital Movement + Smooth Target Orientation
--   • Tekken 3D Sidestep Evasion (Double tap A or D) with Cyan Blur Trails
--   • Supersonic Homing Ninja Dash & Chakra Dash (115 studs/s) with Sonic Boom
--   • Chakra Dash Cancel (CDC) Execution:
--       Instantly responds to CDC bindable event to launch high-speed cancel dashes!
--   • Chakra Charging System (Iconic Storm Ram Seal):
--       Hold [U] or [C] or Mobile Chakra to gather chakra with swirling blue aura (+40/s)!
--   • Multi-Platform: PC (WASD/Shift/U), Mobile Touch, and Gamepad (Left Stick / Circle / B).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

-- Double Tap Tracking for Sidestep & Dash
local lastKeyTime: { [Enum.KeyCode]: number } = {}
local DOUBLE_TAP_WINDOW = 0.28
local isSidestepping = false
local isNinjaDashing = false
local isChargingChakra = false

-- Bindable Events
local function getOrMakeBindable(name: string): BindableEvent
	local be = ReplicatedStorage:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = ReplicatedStorage
	end
	return be
end

local evMobileDash   = getOrMakeBindable("MobileDashAction")
local evMobileChakra = getOrMakeBindable("MobileChakraAction")
local evCDC          = getOrMakeBindable("ChakraDashCancelAction")
local evAnim         = getOrMakeBindable("StormCombatAnimationEvent")
local evCamImpact    = getOrMakeBindable("StormCameraImpactEvent")

local function getTarget(): Model?
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") and dummy:FindFirstChild("HumanoidRootPart") then
		return dummy
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			return p.Character
		end
	end
	return nil
end

-- =========================================================
-- TEKKEN 3D SIDESTEP (Double-Tap A or D)
-- =========================================================
local function executeTekkenSidestep(direction: "Left" | "Right")
	local char = LocalPlayer.Character
	if not char or isSidestepping or isNinjaDashing or isChargingChakra then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local target = getTarget()
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	isSidestepping = true

	-- Calculate lateral vector perpendicular to target vector
	local diff = (targetRoot.Position - root.Position)
	local toTarget = if diff.Magnitude > 0.1 then diff.Unit else Vector3.new(0, 0, -1)
	local flatToTarget = Vector3.new(toTarget.X, 0, toTarget.Z).Unit
	local lateral = Vector3.new(-flatToTarget.Z, 0, flatToTarget.X)
	if direction == "Left" then
		lateral = -lateral
	end

	-- Ghosting Blur Trails
	local trailAtt0 = Instance.new("Attachment", root)
	local trailAtt1 = Instance.new("Attachment", root)
	trailAtt0.Position = Vector3.new(0, 1.4, 0)
	trailAtt1.Position = Vector3.new(0, -1.4, 0)

	local trail = Instance.new("Trail")
	trail.Attachment0 = trailAtt0
	trail.Attachment1 = trailAtt1
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new(0.15, 1)
	trail.Lifetime = 0.28
	trail.Parent = root

	local sidestepVelocity = lateral * 62
	root.AssemblyLinearVelocity = Vector3.new(sidestepVelocity.X, root.AssemblyLinearVelocity.Y, sidestepVelocity.Z)

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
		snd.PlaybackSpeed = 1.85
		snd.Volume = 0.9
		snd.Parent = root
		snd:Play()
		task.delay(0.3, function() pcall(function() snd:Destroy() end) end)
	end)

	task.delay(0.24, function()
		trail:Destroy()
		trailAtt0:Destroy()
		trailAtt1:Destroy()
		isSidestepping = false
	end)
end

-- =========================================================
-- NINJA DASH & CHAKRA DASH (Storm Connections Homing System)
-- =========================================================
local function executeNinjaDash(forceChakraDash: boolean?)
	local char = LocalPlayer.Character
	if not char or isSidestepping or isChargingChakra then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local target = getTarget()
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	local isChakraLoaded = LocalPlayer:GetAttribute("IsChakraLoaded") == true or forceChakraDash == true
	local curChakra = LocalPlayer:GetAttribute("ChakraValue") or 60
	local isChakraDash = isChakraLoaded and (curChakra >= 15 or forceChakraDash == true)

	if isChakraDash and not forceChakraDash then
		LocalPlayer:SetAttribute("ChakraValue", math.max(0, curChakra - 15))
		LocalPlayer:SetAttribute("IsChakraLoaded", false)
	end

	isNinjaDashing = true
	LocalPlayer:SetAttribute("IsNinjaDashing", true)

	-- Dynamic Camera FOV push
	evCamImpact:Fire("Dash", isChakraDash and 0.8 or 0.6)

	-- Sonic Boom Sparkle & Ring FX
	local burstAtt = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = if isChakraDash
		then ColorSequence.new(Color3.fromRGB(0, 240, 255), Color3.fromRGB(90, 190, 255))
		else ColorSequence.new(Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(isChakraDash and 2.2 or 1.4, 0)
	pe.Rate = isChakraDash and 130 or 65
	pe.Speed = NumberRange.new(10, 26)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Parent = burstAtt

	local dashSound: Sound? = nil
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_jump.mp3"
		snd.PlaybackSpeed = isChakraDash and 1.95 or 1.70
		snd.Volume = 0.95
		snd.Parent = root
		snd:Play()
		dashSound = snd
	end)

	local startTime = os.clock()
	local maxDuration = isChakraDash and 0.90 or 0.70
	local targetSpeed = isChakraDash and 115 or 85

	if evAnim then
		evAnim:Fire("NinjaDash", maxDuration)
	end

	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local currentDist = (targetRoot.Position - root.Position).Magnitude

		if currentDist <= 5.8 or elapsed >= maxDuration or not isNinjaDashing then
			if conn then conn:Disconnect() end
			isNinjaDashing = false
			LocalPlayer:SetAttribute("IsNinjaDashing", false)
			burstAtt:Destroy()
			if dashSound then pcall(function() dashSound:Destroy() end) end
			if evAnim then evAnim:Fire("Idle", 0.2) end
			return
		end

		local dir = (targetRoot.Position - root.Position).Unit
		root.AssemblyLinearVelocity = dir * targetSpeed
	end)
end

-- =========================================================
-- CHAKRA CHARGING SYSTEM (Iconic Storm Ram Hand Seal)
-- =========================================================
local chakraAuraPart: Part? = nil
local chakraChargeSound: Sound? = nil

local function startChakraCharge()
	if isChargingChakra or isNinjaDashing or isSidestepping then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	isChargingChakra = true
	hum.WalkSpeed = 0

	print(">> [CHAKRA CHARGE] Ram Hand Seal active! Rapidly gathering chakra! <<")

	-- 1. Anime Ram Seal Stance
	if evAnim then
		evAnim:Fire("ChakraLoad", 999)
	end

	-- 2. Swirling Vertical Chakra Tornado Aura at feet
	local aura = Instance.new("Part")
	aura.Name = "ChakraChargeAura"
	aura.Shape = Enum.PartType.Cylinder
	aura.Size = Vector3.new(0.5, 5.5, 5.5)
	aura.CFrame = root.CFrame * CFrame.new(0, -2.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	aura.Material = Enum.Material.Neon
	aura.Color = Color3.fromRGB(0, 240, 255)
	aura.Transparency = 0.5
	aura.Anchored = false
	aura.CanCollide = false
	aura.Parent = char

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = aura
	weld.Parent = aura

	local att = Instance.new("Attachment", aura)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(2.5, 0.4)
	pe.Rate = 95
	pe.Speed = NumberRange.new(8, 18)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.SpreadAngle = Vector2.new(15, 15)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att

	chakraAuraPart = aura

	-- 3. Audio hum
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_jump.mp3"
		snd.PlaybackSpeed = 0.65
		snd.Volume = 0.65
		snd.Looped = true
		snd.Parent = root
		snd:Play()
		chakraChargeSound = snd
	end)

	-- 4. Background regeneration loop (+40/sec)
	task.spawn(function()
		while isChargingChakra do
			task.wait(0.05)
			if not isChargingChakra then break end
			local cur = LocalPlayer:GetAttribute("ChakraValue") or 60
			local newChakra = math.min(100, cur + 2.0)
			LocalPlayer:SetAttribute("ChakraValue", newChakra)
			if newChakra >= 100 then
				LocalPlayer:SetAttribute("IsChakraLoaded", true)
			end
		end
	end)
end

local function stopChakraCharge()
	if not isChargingChakra then return end
	isChargingChakra = false

	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 16
		end
	end

	if chakraAuraPart then
		chakraAuraPart:Destroy()
		chakraAuraPart = nil
	end

	if chakraChargeSound then
		chakraChargeSound:Stop()
		chakraChargeSound:Destroy()
		chakraChargeSound = nil
	end

	if evAnim then
		evAnim:Fire("Idle", 0.25)
	end
	print(">> [CHAKRA CHARGE] Stance ended. <<")
end

-- =========================================================
-- CDC BINDABLE LISTENER (Fired by CombatComboController)
-- =========================================================
evCDC.Event:Connect(function()
	executeNinjaDash(true)
end)

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
local lastJumpTime = 0

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local now = os.clock()

	-- 1. Direct Ninja Dash with [LeftShift], [Q], or Gamepad ButtonB (Circle / B)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
		executeNinjaDash(false)

	-- 2. Chakra Charge Hold: [U] or [C] or Gamepad ButtonY
	elseif input.KeyCode == Enum.KeyCode.U or input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonY then
		startChakraCharge()

	-- 3. Sidestep detection (Double tap A or D)
	elseif input.KeyCode == Enum.KeyCode.A then
		local prev = lastKeyTime[Enum.KeyCode.A] or 0
		if now - prev <= DOUBLE_TAP_WINDOW then
			executeTekkenSidestep("Left")
			lastKeyTime[Enum.KeyCode.A] = 0
		else
			lastKeyTime[Enum.KeyCode.A] = now
		end
	elseif input.KeyCode == Enum.KeyCode.D then
		local prev = lastKeyTime[Enum.KeyCode.D] or 0
		if now - prev <= DOUBLE_TAP_WINDOW then
			executeTekkenSidestep("Right")
			lastKeyTime[Enum.KeyCode.D] = 0
		else
			lastKeyTime[Enum.KeyCode.D] = now
		end

	-- 4. Ninja Dash detection (Double tap Space or Shift + Space)
	elseif input.KeyCode == Enum.KeyCode.Space then
		local isShiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		if isShiftHeld or (now - lastJumpTime <= DOUBLE_TAP_WINDOW) then
			executeNinjaDash(false)
			lastJumpTime = 0
		else
			lastJumpTime = now
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.U or input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonY then
		stopChakraCharge()
	end
end)

-- Mobile Touch Integration
evMobileDash.Event:Connect(function()
	executeNinjaDash(false)
end)

evMobileChakra.Event:Connect(function(isHolding: any)
	if isHolding == true then
		startChakraCharge()
	else
		stopChakraCharge()
	end
end)

-- Smooth Target Orientation and Dynamic Shinobi Speed
RunService.RenderStepped:Connect(function(dt: number)
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	local isBlocking = LocalPlayer:GetAttribute("IsBlocking") == true
	local isHitstunned = LocalPlayer:GetAttribute("IsHitstunned") == true

	if not isChargingChakra and not isBlocking and not isHitstunned and hum.WalkSpeed > 0 and hum.WalkSpeed < 22 then
		hum.WalkSpeed = 22 -- Snappy ninja mobility
	end

	local target = getTarget()
	if target and target:FindFirstChild("HumanoidRootPart") then
		local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart
		local look = Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z)
		hum.AutoRotate = false
		local trackAlpha = math.clamp(dt * 16, 0.15, 0.5)
		root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, look), trackAlpha)
	else
		hum.AutoRotate = true
	end
end)

print("[StormMovementController] ✅ Storm Connections Movement Engine Active: 115 studs/s CDC, Chakra Charge Aura [U/C], Tekken Sidestep [A/D x2] ready.")
]=====]
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormMovementController'
