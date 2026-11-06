local function install(name, sType, parent, src)
    local ex = parent:FindFirstChild(name)
    if ex then ex:Destroy() end
    local s = Instance.new(sType)
    s.Name = name
    s.Source = src
    s.Parent = parent
    print('[Installed] ' .. sType .. ': ' .. name)
end

do
    local src = [=====[--!strict
-- StormCameraController.luau
-- CLIENT SCRIPT: Dynamic 3D Lock-On Arena Camera (Naruto Shippuden: Ultimate Ninja Storm 4 Style)
-- Features:
--   • Dual-Target Dynamic Midpoint Framing (Player & Opponent framed simultaneously)
--   • Adaptive Zoom based on distance
--   • Vertical tilt compensation for airborne combos
--   • Dynamic FOV expansion during Ninja Dash
--   • Cyber-Anime Lock-On Crosshair HUD Reticle
--   • Toggle Lock-On with 'Z' key or Middle Click

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera

-- Camera Parameters
local MIN_DIST = 14
local MAX_DIST = 46
local BASE_HEIGHT = 6.2
local HEIGHT_AIR_FACTOR = 0.38
local SIDE_OFFSET = 3.4
local SMOOTH_SPEED = 12
local FOV_DEFAULT = 65
local FOV_DASHING = 76

local isLockOnActive = true
local currentTarget: Model? = nil

-- =========================================================
-- CYBER-ANIME LOCK-ON RETICLE HUD
-- =========================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local reticleGui = Instance.new("ScreenGui")
reticleGui.Name = "StormReticleGUI"
reticleGui.ResetOnSpawn = false
reticleGui.Parent = playerGui

local reticleFrame = Instance.new("Frame")
reticleFrame.Name = "ReticleContainer"
reticleFrame.Size = UDim2.new(0, 56, 0, 56)
reticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
reticleFrame.BackgroundTransparency = 1
reticleFrame.Visible = false
reticleFrame.Parent = reticleGui

-- Outer Ring
local outerRing = Instance.new("Frame")
outerRing.Size = UDim2.fromScale(1, 1)
outerRing.BackgroundTransparency = 1
outerRing.Parent = reticleFrame
Instance.new("UICorner", outerRing).CornerRadius = UDim.new(1, 0)
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(0, 240, 255)
outerStroke.Thickness = 2
outerStroke.Parent = outerRing

-- Inner Diamond
local innerDiamond = Instance.new("Frame")
innerDiamond.Size = UDim2.fromScale(0.35, 0.35)
innerDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
innerDiamond.Position = UDim2.fromScale(0.5, 0.5)
innerDiamond.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
innerDiamond.BackgroundTransparency = 0.2
innerDiamond.Rotation = 45
innerDiamond.BorderSizePixel = 0
innerDiamond.Parent = reticleFrame
Instance.new("UICorner", innerDiamond).CornerRadius = UDim.new(0, 3)

-- 4 Crosshair Ticks
local function createTick(angle: number)
	local tick = Instance.new("Frame")
	tick.Size = UDim2.new(0, 2, 0, 8)
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
	tick.BorderSizePixel = 0
	local rad = math.rad(angle)
	tick.Position = UDim2.new(0.5 + math.cos(rad) * 0.58, 0, 0.5 + math.sin(rad) * 0.58, 0)
	tick.Parent = reticleFrame
end
createTick(0)
createTick(90)
createTick(180)
createTick(270)

-- =========================================================
-- TARGET ACQUISITION
-- =========================================================
local function findNearestTarget(): Model?
	local myChar = LocalPlayer.Character
	if not myChar then return nil end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return nil end

	local bestTarget: Model? = nil
	local closestDist = 120

	-- 1. Check Training Dummy
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") and dummy:FindFirstChild("HumanoidRootPart") then
		local dRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
		local dist = (dRoot.Position - myRoot.Position).Magnitude
		if dist < closestDist then
			closestDist = dist
			bestTarget = dummy
		end
	end

	-- 2. Check Other Players
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local root = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = (root.Position - myRoot.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					bestTarget = p.Character
				end
			end
		end
	end

	return bestTarget
end

-- Update Reticle Screen Position
local function updateReticle(target: Model?)
	if not target or not isLockOnActive then
		reticleFrame.Visible = false
		return
	end

	local root = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		reticleFrame.Visible = false
		return
	end

	local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 1.2, 0))
	if onScreen then
		reticleFrame.Visible = true
		reticleFrame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
		outerRing.Rotation = (outerRing.Rotation + 1.5) % 360
		innerDiamond.Rotation = (innerDiamond.Rotation - 2) % 360
	else
		reticleFrame.Visible = false
	end
end

-- =========================================================
-- DYNAMIC CAMERA UPDATE
-- =========================================================
local currentCamPos = Vector3.zero
local currentCamFocus = Vector3.zero

local function onRenderStep(dt: number)
	local myChar = LocalPlayer.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return end

	-- Find or retain target
	if not currentTarget or not currentTarget.Parent then
		currentTarget = findNearestTarget()
	end

	updateReticle(currentTarget)

	if not isLockOnActive or not currentTarget then
		if Camera.CameraType == Enum.CameraType.Scriptable then
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = FOV_DEFAULT
		end
		return
	end

	local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		Camera.CameraType = Enum.CameraType.Custom
		return
	end

	-- Activate Scriptable Camera for Storm 4 Dynamic Dual Framing
	if Camera.CameraType ~= Enum.CameraType.Scriptable then
		Camera.CameraType = Enum.CameraType.Scriptable
		currentCamPos = Camera.CFrame.Position
		currentCamFocus = myRoot.Position
	end

	local pPos = myRoot.Position
	local tPos = targetRoot.Position

	-- 1. Midpoint between Player and Opponent
	local midpoint = (pPos + tPos) * 0.5

	-- 2. Distance and adaptive zoom
	local diff = (tPos - pPos)
	local dist = diff.Magnitude
	local clampedDist = math.clamp(dist * 0.95 + 8, MIN_DIST, MAX_DIST)

	-- 3. Direction vectors
	local lookDir = if dist > 0.1 then diff.Unit else Vector3.new(0, 0, -1)
	local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
	local rightDir = Vector3.new(-flatDir.Z, 0, flatDir.X) -- Perpendicular lateral vector

	-- 4. Vertical air height compensation
	local verticalOffset = math.max(0, math.max(pPos.Y, tPos.Y) - 50) * HEIGHT_AIR_FACTOR

	-- 5. Calculate ideal Camera Position (behind Player, offset laterally for over-shoulder cinematic view)
	local targetCamPos = pPos - (flatDir * clampedDist) + Vector3.new(0, BASE_HEIGHT + verticalOffset, 0) + (rightDir * SIDE_OFFSET)

	-- 6. Calculate ideal Camera Focus (looking slightly toward midpoint and target)
	local targetFocus = midpoint + Vector3.new(0, 1.5 + verticalOffset * 0.5, 0)

	-- 7. Smooth Interpolation (Lerp)
	local lerpFactor = math.clamp(dt * SMOOTH_SPEED, 0, 1)
	currentCamPos = currentCamPos:Lerp(targetCamPos, lerpFactor)
	currentCamFocus = currentCamFocus:Lerp(targetFocus, lerpFactor)

	Camera.CFrame = CFrame.lookAt(currentCamPos, currentCamFocus)

	-- Dynamic FOV adjustment during Ninja Dash
	local isDashing = LocalPlayer:GetAttribute("IsNinjaDashing") == true
	local targetFOV = isDashing and FOV_DASHING or FOV_DEFAULT
	Camera.FieldOfView = Camera.FieldOfView + (targetFOV - Camera.FieldOfView) * math.clamp(dt * 8, 0, 1)
end

RunService:BindToRenderStep("StormLockOnCamera", Enum.RenderPriority.Camera.Value + 1, onRenderStep)

-- Toggle Lock-On with Key 'Z' or Middle Click
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Z or input.UserInputType == Enum.UserInputType.MouseButton3 then
		isLockOnActive = not isLockOnActive
		if isLockOnActive then
			currentTarget = findNearestTarget()
		else
			currentTarget = nil
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = FOV_DEFAULT
		end
		print(">> [Storm Camera] Lock-On:", isLockOnActive and "ON" or "OFF", "<<")
	end
end)

print("[StormCameraController] ✅ Loaded — Press 'Z' to toggle Naruto Storm 4 Lock-On Camera.")
]=====]
    install('StormCameraController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- StormMovementController.luau
-- CLIENT SCRIPT: Naruto Storm 4 3D Arena Movement + Tekken Sidestep Evasion
-- Features:
--   • WASD Movement + IJKL Mobility System:
--       [W, A, S, D]: 3D Orbital strafing around opponent
--       [A x2 / D x2]: Tekken 3D Sidestep Evasion with cyan blur trail
--       [L] Key or Double-Tap [Space]: Instant Homing Ninja Dash
--   • Full Controller Support: Gamepad ButtonB (Circle / B)
--   • Mobile Touch Support via Custom BindableEvent
--   • Dynamic character orientation toward locked target

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Double Tap Tracking for Sidestep & Dash
local lastKeyTime: { [Enum.KeyCode]: number } = {}
local DOUBLE_TAP_WINDOW = 0.28
local isSidestepping = false
local isNinjaDashing = false

-- Mobile/UI Bindable Integration
local evMobileDash = ReplicatedStorage:FindFirstChild("MobileDashAction") :: BindableEvent?
if not evMobileDash then
	evMobileDash = Instance.new("BindableEvent")
	evMobileDash.Name = "MobileDashAction"
	evMobileDash.Parent = ReplicatedStorage
end

local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?

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
-- TEKKEN SIDESTEP (Double-Tap A or D)
-- =========================================================
local function executeTekkenSidestep(direction: "Left" | "Right")
	local char = LocalPlayer.Character
	if not char or isSidestepping or isNinjaDashing then return end
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
	local lateral = Vector3.new(-flatToTarget.Z, 0, flatToTarget.X) -- Right direction
	if direction == "Left" then
		lateral = -lateral
	end

	-- Visual Trail / Ghosting Blur
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

	-- Fast snappy lateral impulse (Tekken feel)
	local sidestepVelocity = lateral * 58
	root.AssemblyLinearVelocity = Vector3.new(sidestepVelocity.X, root.AssemblyLinearVelocity.Y, sidestepVelocity.Z)

	-- Sound
	pcall(function()
		local dodgeSound = Instance.new("Sound")
		dodgeSound.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
		dodgeSound.PlaybackSpeed = 1.8
		dodgeSound.Volume = 0.9
		dodgeSound.Parent = root
		dodgeSound:Play()
		task.delay(0.3, function() pcall(function() dodgeSound:Destroy() end) end)
	end)

	print(string.format(">> [Tekken Sidestep] Evasion %s executed! <<", direction))

	task.delay(0.24, function()
		trail:Destroy()
		trailAtt0:Destroy()
		trailAtt1:Destroy()
		isSidestepping = false
	end)
end

-- =========================================================
-- NINJA DASH / CHAKRA DASH (Storm 4 Supersonic Homing Dash & CDC)
-- =========================================================
local evCDC = ReplicatedStorage:FindFirstChild("ChakraDashCancelAction") :: BindableEvent?
if not evCDC then
	evCDC = Instance.new("BindableEvent")
	evCDC.Name = "ChakraDashCancelAction"
	evCDC.Parent = ReplicatedStorage
end

local function executeNinjaDash()
	local char = LocalPlayer.Character
	if not char or isNinjaDashing or isSidestepping then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local target = getTarget()
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	-- Check for Chakra Dash (Storm 4 Chakra Load active)
	local isChakraLoaded = LocalPlayer:GetAttribute("IsChakraLoaded") == true
	local curChakra = LocalPlayer:GetAttribute("ChakraValue") or 60
	local isChakraDash = isChakraLoaded and (curChakra >= 15)

	if isChakraDash then
		-- Deduct 15 Chakra & Clear Loaded State
		LocalPlayer:SetAttribute("ChakraValue", curChakra - 15)
		LocalPlayer:SetAttribute("IsChakraLoaded", false)
		-- Trigger Chakra Dash Cancel (CDC) to cancel any active attack recovery
		if evCDC then evCDC:Fire() end
		print(">> [CHAKRA DASH] Supersonic 112 studs/s Chakra Dash unleashed! (CDC active) <<")
	else
		print(">> [Ninja Dash] Homing toward target! <<")
	end

	isNinjaDashing = true
	LocalPlayer:SetAttribute("IsNinjaDashing", true)

	-- Sonic Boom Sparkle Particles
	local burstAtt = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = if isChakraDash
		then ColorSequence.new(Color3.fromRGB(0, 240, 255), Color3.fromRGB(80, 180, 255))
		else ColorSequence.new(Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(isChakraDash and 2.0 or 1.3, 0)
	pe.Rate = isChakraDash and 120 or 60
	pe.Speed = NumberRange.new(8, 24)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Parent = burstAtt

	-- Sound
	local dashSound: Sound? = nil
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_jump.mp3"
		snd.PlaybackSpeed = isChakraDash and 1.9 or 1.7
		snd.Volume = 0.95
		snd.Parent = root
		snd:Play()
		dashSound = snd
	end)

	local startTime = os.clock()
	local maxDuration = isChakraDash and 0.85 or 0.70
	local targetSpeed = isChakraDash and 112 or 85

	if evAnim then
		evAnim:Fire("NinjaDash", maxDuration)
	end

	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local currentDist = (targetRoot.Position - root.Position).Magnitude

		-- Stop dash when close enough (melee range) or timed out
		if currentDist <= 6.5 or elapsed >= maxDuration or not isNinjaDashing then
			if conn then conn:Disconnect() end
			isNinjaDashing = false
			LocalPlayer:SetAttribute("IsNinjaDashing", false)
			burstAtt:Destroy()
			if dashSound then pcall(function() dashSound:Destroy() end) end
			if evAnim then evAnim:Fire("Idle", 0.2) end
			return
		end

		-- Homing direction toward target
		local dir = (targetRoot.Position - root.Position).Unit
		root.AssemblyLinearVelocity = dir * targetSpeed
	end)
end

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
local lastJumpTime = 0

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local now = os.clock()

	-- 1. Direct Ninja Dash with [LeftShift], [Q], or Gamepad ButtonB (Circle / B)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
		executeNinjaDash()

	-- 2. Sidestep detection (Double tap A or D)
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

	-- 3. Ninja Dash detection (Double tap Space or Shift + Space)
	elseif input.KeyCode == Enum.KeyCode.Space then
		local isShiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		if isShiftHeld or (now - lastJumpTime <= DOUBLE_TAP_WINDOW) then
			executeNinjaDash()
			lastJumpTime = 0
		else
			lastJumpTime = now
		end
	end
end)

-- Mobile Touch Integration
if evMobileDash then
	evMobileDash.Event:Connect(function()
		executeNinjaDash()
	end)
end

-- Smooth Target Orientation and AutoRotate Management
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	local target = getTarget()
	if target and target:FindFirstChild("HumanoidRootPart") then
		local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart
		local look = Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z)
		
		-- Turn off AutoRotate to prevent Roblox default camera fight
		hum.AutoRotate = false
		
		-- Orient player smoothly toward target
		root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, look), 0.22)
	else
		hum.AutoRotate = true
	end
end)

print("[StormMovementController] ✅ Loaded — Movement [WASD], Sidestep [A/D x2], Ninja Dash [Shift/Q] / [Space x2] / Gamepad (B).")
]=====]
    install('StormMovementController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- TekkenDefenseController.luau
-- CLIENT SCRIPT: Tekken-Style Technical Defense System
-- Features:
--   • WASD Movement + Guard Defense:
--       [F] Hold: Standing High/Mid Guard (Cyan Shield)
--       [S + F] or [Ctrl + F]: Crouched Low Guard (Amber Shield)
--   • Just-Frame Parry (180ms window for counter stagger)
--   • Full Controller Support: R1 / R2 Bumpers
--   • Mobile Touch Support via Custom BindableEvent
--   • Guard Health Meter HUD and Guard Crush Stun

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Guard State
local isBlocking = false
local blockType = "None" -- "High" | "Low"
local guardHealth = 100
local MAX_GUARD = 100
local blockStartTime = 0
local PARRY_WINDOW = 0.18 -- 180ms
local isGuardCrushed = false

-- Visual Guard Shield Part
local currentShieldPart: Part? = nil

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local evBlock = combatEvents and combatEvents:FindFirstChild("BlockEvent") :: RemoteEvent?
local evParry = combatEvents and combatEvents:FindFirstChild("ParryEvent") :: RemoteEvent?

-- Mobile/UI Bindable Integration
local evMobileGuard = ReplicatedStorage:FindFirstChild("MobileGuardAction") :: BindableEvent?
if not evMobileGuard then
	evMobileGuard = Instance.new("BindableEvent")
	evMobileGuard.Name = "MobileGuardAction"
	evMobileGuard.Parent = ReplicatedStorage
end

-- =========================================================
-- GUARD HEALTH HUD
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TekkenGuardHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local barContainer = Instance.new("Frame")
barContainer.Name = "GuardContainer"
barContainer.Size = UDim2.new(0, 240, 0, 24)
barContainer.Position = UDim2.new(0.5, -120, 0.82, 0)
barContainer.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
barContainer.BackgroundTransparency = 0.2
barContainer.BorderSizePixel = 0
barContainer.Visible = false
barContainer.Parent = screenGui
Instance.new("UICorner", barContainer).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 220, 255)
stroke.Thickness = 2
stroke.Parent = barContainer

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(1, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
fill.BorderSizePixel = 0
fill.Parent = barContainer
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 12)

local guardLabel = Instance.new("TextLabel")
guardLabel.Size = UDim2.new(1, 0, 1, 0)
guardLabel.BackgroundTransparency = 1
guardLabel.Font = Enum.Font.GothamBlack
guardLabel.TextSize = 12
guardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
guardLabel.Text = "🛡️ HIGH GUARD: 100%"
guardLabel.Parent = barContainer

-- =========================================================
-- VISUAL GUARD SHIELD
-- =========================================================
local function spawnShield(char: Model, bType: string)
	if currentShieldPart then currentShieldPart:Destroy() end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local shield = Instance.new("Part")
	shield.Name = "GuardShieldVisual"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(4.2, 5.2, 4.2)
	shield.CFrame = root.CFrame * (bType == "Low" and CFrame.new(0, -1, 1.2) or CFrame.new(0, 0.5, 1.2))
	shield.Color = bType == "Low" and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(0, 230, 255)
	shield.Material = Enum.Material.ForceField
	shield.Transparency = 0.45
	shield.Anchored = false
	shield.CanCollide = false
	shield.Massless = true
	shield.Parent = char

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = shield
	weld.Parent = shield

	currentShieldPart = shield
end

local function removeShield()
	if currentShieldPart then
		currentShieldPart:Destroy()
		currentShieldPart = nil
	end
end

-- =========================================================
-- START & STOP GUARD
-- =========================================================
local function startGuard()
	if isGuardCrushed then return end
	local char = LocalPlayer.Character
	if not char or guardHealth <= 0 then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	-- Check for Low Guard: S key (retreating/crouch) OR LeftControl / C
	local isSHeld = UserInputService:IsKeyDown(Enum.KeyCode.S)
	local isCtrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C)
	local isCrouched = isSHeld or isCtrlHeld

	blockType = isCrouched and "Low" or "High"
	isBlocking = true
	blockStartTime = os.clock()

	LocalPlayer:SetAttribute("IsBlocking", true)
	LocalPlayer:SetAttribute("BlockType", blockType)
	LocalPlayer:SetAttribute("BlockStartTime", blockStartTime)

	barContainer.Visible = true
	stroke.Color = blockType == "Low" and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(0, 220, 255)
	fill.BackgroundColor3 = stroke.Color
	guardLabel.Text = string.format("🛡️ %s GUARD: %d%%", string.upper(blockType), math.floor(guardHealth))

	spawnShield(char, blockType)

	if evBlock then
		evBlock:FireServer(true, blockType, blockStartTime)
	end

	local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
	if evAnim then
		evAnim:Fire(blockType == "Low" and "LowGuard" or "HighGuard", 999)
	end

	print(string.format(">> [Tekken Guard] %s Guard Active! <<", blockType))
end

local function stopGuard()
	if not isBlocking then return end
	isBlocking = false
	blockType = "None"
	barContainer.Visible = false
	removeShield()

	LocalPlayer:SetAttribute("IsBlocking", false)
	LocalPlayer:SetAttribute("BlockType", "None")

	if evBlock then
		evBlock:FireServer(false, "None", 0)
	end

	local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
	if evAnim then
		evAnim:Fire("Idle", 0.2)
	end
end

-- =========================================================
-- GUARD CRUSH (Break)
-- =========================================================
local function triggerGuardCrush()
	isGuardCrushed = true
	stopGuard()

	local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
	if evAnim then
		evAnim:Fire("StaggerStun", 2.2)
	end

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if root and hum then
		hum.WalkSpeed = 4

		-- Sparkle burst
		local att = Instance.new("Attachment", root)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 200, 50))
		pe.Size = NumberSequence.new(2, 0)
		pe.Rate = 80
		pe.Speed = NumberRange.new(12, 24)
		pe.Lifetime = NumberRange.new(0.4, 0.6)
		pe.Parent = att

		-- Sound
		pcall(function()
			local crackSound = Instance.new("Sound")
			crackSound.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
			crackSound.PlaybackSpeed = 1.4
			crackSound.Volume = 0.9
			crackSound.Parent = root
			crackSound:Play()
			task.delay(0.6, function() pcall(function() crackSound:Destroy() end) end)
		end)

		print(">> [GUARD CRUSH] Defender Guard Broken! <<")

		task.delay(2.2, function()
			att:Destroy()
			if hum then hum.WalkSpeed = 16 end
			guardHealth = 50
			isGuardCrushed = false
		end)
	end
end

-- =========================================================
-- JUST-FRAME PARRY EFFECT
-- =========================================================
local function triggerParryVFX()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Gold Sparkles & Bell Chime
	local att = Instance.new("Attachment", root)

	-- Procedural Parry Animation Trigger
	local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
	if evAnim then
		evAnim:Fire("Parry", 0.45)
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(1.8, 0)
	pe.Rate = 70
	pe.Speed = NumberRange.new(12, 22)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Parent = att

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/volume_slider.ogg"
		snd.PlaybackSpeed = 1.6
		snd.Volume = 1
		snd.Parent = root
		snd:Play()
		task.delay(0.5, function() pcall(function() snd:Destroy() end) end)
	end)

	-- Floating UI Banner
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 200, 0, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = root

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⚡ PERFECT PARRY!"
	lbl.TextColor3 = Color3.fromRGB(255, 225, 50)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb

	task.delay(0.6, function()
		att:Destroy()
		bb:Destroy()
	end)

	print(">> [TEKKEN PERFECT PARRY] Perfect Defense Executed! <<")
end

if evParry then
	evParry.OnClientEvent:Connect(function(defenderPlayer: Player)
		if defenderPlayer == LocalPlayer then
			triggerParryVFX()
		end
	end)
end

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
local function isGuardKey(key: Enum.KeyCode): boolean
	return key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonR1 or key == Enum.KeyCode.ButtonR2
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if isGuardKey(input.KeyCode) then
		startGuard()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if isGuardKey(input.KeyCode) then
		stopGuard()
	end
end)

-- Mobile Touch Integration
if evMobileGuard then
	evMobileGuard.Event:Connect(function(start: boolean)
		if start then
			startGuard()
		else
			stopGuard()
		end
	end)
end

-- Regenerate Guard Health when not blocking
RunService.Heartbeat:Connect(function(dt)
	if not isBlocking and not isGuardCrushed and guardHealth < MAX_GUARD then
		guardHealth = math.min(MAX_GUARD, guardHealth + (15 * dt))
		fill.Size = UDim2.new(guardHealth / MAX_GUARD, 0, 1, 0)
		guardLabel.Text = string.format("🛡️ %s GUARD: %d%%", string.upper(blockType == "None" and "HIGH" or blockType), math.floor(guardHealth))
	end
end)

print("[TekkenDefenseController] ✅ Loaded — Guard [F] / Gamepad (R1/R2), Low Guard [S+F].")
]=====]
    install('TekkenDefenseController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
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
]=====]
    install('CombatComboController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- StormRangedController.luau
-- CLIENT SCRIPT: Naruto Storm Authentic Anime Ranged Attack System ([L] Key)
-- Features:
--   • [L] Key: Fires character-specific anime projectile jutsu:
--       - Naruto: Wind Style: Rasen-Shuriken (Spinning aerodynamic chakra shuriken)
--       - Sasuke: Fire Style: Fireball Jutsu / Goukakyuu (Explosive flame sphere)
--       - Luffy: Gum-Gum Pistol / Gomu Gomu no Pistol (Stretching punch fist)
--       - Zoro: 36 Pound Phoenix / Tobu Zangeki (Emerald flying wind blade)
--       - Killua: Thunderbolt / Narukami (High-speed lightning spark strike)
--   • Procedural anime casting pose & particle aura
--   • Target lock-on aiming & cooldown management
--   • Full Gamepad (ButtonY / Triangle) and Mobile Touch support

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- Cooldown tracking
local lastRangedTime = 0
local isFiring = false

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local function getRemote(name: string): RemoteEvent?
	return combatEvents and combatEvents:FindFirstChild(name) :: RemoteEvent?
end

local evRanged = getRemote("RangedAttackEvent")
if not evRanged and combatEvents then
	local r = Instance.new("RemoteEvent")
	r.Name = "RangedAttackEvent"
	r.Parent = combatEvents
	evRanged = r
end

-- Mobile Bindable
local evMobileRanged = ReplicatedStorage:FindFirstChild("MobileRangedAction") :: BindableEvent?
if not evMobileRanged then
	evMobileRanged = Instance.new("BindableEvent")
	evMobileRanged.Name = "MobileRangedAction"
	evMobileRanged.Parent = ReplicatedStorage
end

local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?

-- Target helper
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
-- EXECUTE RANGED ANIME ATTACK ([L] Key)
-- =========================================================
local function executeRangedAttack()
	if isFiring then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	-- Block ranged attack while guarding
	if LocalPlayer:GetAttribute("IsBlocking") == true then
		return
	end

	local charId = tostring(LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto")
	local charData = CombatConfig.Characters[charId] or CombatConfig.Characters["Naruto"]
	local rangedData = charData.RangedSkill or {
		Name = "Chakra Shuriken",
		Damage = 18,
		Speed = 100,
		Cooldown = 1.6,
		Color = Color3.fromRGB(0, 230, 255),
		Sound = "rbxasset://sounds/action_jump.mp3",
	}

	local now = os.clock()
	if now - lastRangedTime < (rangedData.Cooldown or 1.5) then
		return
	end

	lastRangedTime = now
	isFiring = true

	-- Determine Aim Direction
	local target = getTarget()
	local aimDir = root.CFrame.LookVector
	if target and target:FindFirstChild("HumanoidRootPart") then
		local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart
		local diff = (tRoot.Position - (root.Position + Vector3.new(0, 1.2, 0)))
		if diff.Magnitude > 0.1 then
			aimDir = diff.Unit
		end
	end

	-- Procedural Animation: Cast Pose
	if evAnim then
		evAnim:Fire("Attack2", 0.35)
	end

	-- Hands Energy Charge Flash
	local flashPart = Instance.new("Part")
	flashPart.Shape = Enum.PartType.Ball
	flashPart.Size = Vector3.new(1.8, 1.8, 1.8)
	flashPart.CFrame = root.CFrame * CFrame.new(0, 0.4, -2.2)
	flashPart.Material = Enum.Material.Neon
	flashPart.Color = rangedData.Color or Color3.fromRGB(0, 240, 255)
	flashPart.Transparency = 0.2
	flashPart.CanCollide = false
	flashPart.Anchored = true
	flashPart.Parent = Workspace

	local tween = TweenService:Create(flashPart, TweenInfo.new(0.18), {
		Size = Vector3.new(0.4, 0.4, 0.4),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		flashPart:Destroy()
	end)

	-- Sound
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = rangedData.Sound or "rbxasset://sounds/action_jump.mp3"
		snd.PlaybackSpeed = 1.3
		snd.Volume = 0.9
		snd.Parent = root
		snd:Play()
		task.delay(0.6, function() pcall(function() snd:Destroy() end) end)
	end)

	-- Fire Server
	if evRanged then
		evRanged:FireServer(aimDir, charId)
	end

	print(string.format(">> [StormRanged] %s fired: %s! <<", charData.Name, rangedData.Name))

	task.delay(0.35, function()
		isFiring = false
	end)
end

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- [L] Key: Serangan Jarak Jauh (Naruto Storm Standard)
	if input.KeyCode == Enum.KeyCode.L or input.KeyCode == Enum.KeyCode.ButtonY then
		executeRangedAttack()
	end
end)

-- Mobile Touch Listener
if evMobileRanged then
	evMobileRanged.Event:Connect(function()
		executeRangedAttack()
	end)
end

print("[StormRangedController] ✅ Loaded — Serangan Jarak Jauh [L] / Gamepad (Triangle/Y) active.")

]=====]
    install('StormRangedController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

return 'Batch 3 OK (5 scripts)'