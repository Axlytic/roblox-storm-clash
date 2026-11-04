local function installScript(name: string, scriptType: string, parent: Instance, sourceCode: string)
    local existing = parent:FindFirstChild(name)
    if existing then existing:Destroy() end
    local s = Instance.new(scriptType)
    s.Name = name
    s.Source = sourceCode
    s.Parent = parent
    print('[Installer] Installed ' .. scriptType .. ': ' .. name)
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
    installScript('StormCameraController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
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
-- NINJA / CHAKRA DASH ([L] Key or Double-Tap Space)
-- =========================================================
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

	isNinjaDashing = true
	LocalPlayer:SetAttribute("IsNinjaDashing", true)

	-- Sonic Boom Sparkle Particles
	local burstAtt = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(1.3, 0)
	pe.Rate = 60
	pe.Speed = NumberRange.new(8, 20)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Parent = burstAtt

	-- Sound
	local dashSound: Sound? = nil
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_jump.mp3"
		snd.PlaybackSpeed = 1.7
		snd.Volume = 0.9
		snd.Parent = root
		snd:Play()
		dashSound = snd
	end)

	local startTime = os.clock()
	local maxDuration = 0.70

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
			return
		end

		-- Homing direction toward target
		local dir = (targetRoot.Position - root.Position).Unit
		root.AssemblyLinearVelocity = dir * 85
	end)

	print(">> [Ninja Dash] Homing toward target! <<")
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
    installScript('StormMovementController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
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
end

-- =========================================================
-- GUARD CRUSH (Break)
-- =========================================================
local function triggerGuardCrush()
	isGuardCrushed = true
	stopGuard()

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
    installScript('TekkenDefenseController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- CombatComboController.luau
-- CLIENT SCRIPT: Core Fighting Game M1 Combo String & Low Shinobi Sweep
-- Features:
--   • WASD Movement + IJKL Combat System:
--       [J] Key or Left-Click: 4-Hit Attack Combo String
--       [S + J] or [Ctrl + J]: Low Shinobi Sweep (Bypasses High Guard)
--   • Full Controller / Gamepad Support: ButtonX (Square / X)
--   • Mobile Touch Screen Support via Custom BindableEvent
--   • Forward lunging momentum on each hit (Storm 4 feeling)
--   • Hitbox detection with OverlapParams, VFX, and Stagger Counter-hit reaction

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera

-- Configuration
local COMBO_RESET_TIME = 0.85
local MAX_MELEE_RANGE = 8.0
local LUNGE_FORCE = 32

local currentComboIndex = 0
local lastAttackTime = 0
local isAttacking = false
local isStaggered = false

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local evAttack = combatEvents and combatEvents:FindFirstChild("AttackEvent") :: RemoteEvent?
local evParry  = combatEvents and combatEvents:FindFirstChild("ParryEvent") :: RemoteEvent?

-- Mobile/UI Bindable Integration
local evMobileAttack = ReplicatedStorage:FindFirstChild("MobileAttackAction") :: BindableEvent?
if not evMobileAttack then
	evMobileAttack = Instance.new("BindableEvent")
	evMobileAttack.Name = "MobileAttackAction"
	evMobileAttack.Parent = ReplicatedStorage
end

-- Sounds (Verified local engine assets)
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
		task.delay(0.5, function()
			pcall(function() snd:Destroy() end)
		end)
	end)
end

-- =========================================================
-- VISUAL SLASH / IMPACT EFFECT
-- =========================================================
local function playAttackFX(root: BasePart, isHeavy: boolean, isLow: boolean)
	local fxPart = Instance.new("Part")
	fxPart.Size = Vector3.new(3, 3, 0.2)
	fxPart.CFrame = root.CFrame * CFrame.new(0, isLow and -1.2 or 0.2, -2.5) * CFrame.Angles(0, 0, math.random(-30, 30))
	fxPart.Material = Enum.Material.Neon
	fxPart.Color = if isHeavy then Color3.fromRGB(255, 100, 30) elseif isLow then Color3.fromRGB(255, 200, 40) else Color3.fromRGB(0, 230, 255)
	fxPart.Transparency = 0.3
	fxPart.Anchored = true
	fxPart.CanCollide = false
	fxPart.Parent = Workspace

	local tween = TweenService:Create(fxPart, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(4.5, 4.5, 0.2),
	})
	tween:Play()
	tween.Completed:Connect(function()
		fxPart:Destroy()
	end)

	-- Safe Sound Playback
	local sId = if isHeavy then SOUND_HEAVY elseif isLow then SOUND_SWEEP else SOUND_PUNCH
	local sPitch = if isHeavy then 1.1 elseif isLow then 1.4 else 1.2 + (currentComboIndex * 0.1)
	playSafeSound(sId, root, sPitch, 0.9)
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
	local hitParts = Workspace:GetPartBoundsInBox(hitBoxCFrame, Vector3.new(5, 5, 6), overlap)

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
-- EXECUTE ATTACK: [J] Pukulan Biasa / [K] Serangan Bawah
-- =========================================================
local function executeAttack(forceLow: boolean?)
	if isAttacking or isStaggered then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	-- Block attack if currently holding Guard
	if LocalPlayer:GetAttribute("IsBlocking") == true then
		return
	end

	local now = os.clock()
	if now - lastAttackTime > COMBO_RESET_TIME then
		currentComboIndex = 0
	end

	-- Naruto Storm Attack Standard:
	-- [J]: 4-Hit Normal Taijutsu Punch Combo String
	-- [K]: Dedicated Low Shinobi Sweep (Bypasses High Guard)
	local isLowSweep = (forceLow == true)
	local isHeavyFinisher = false

	if isLowSweep then
		-- Dedicated Low Shinobi Sweep
		currentComboIndex = 1
	else
		currentComboIndex = (currentComboIndex % 4) + 1
		isHeavyFinisher = (currentComboIndex == 4)
	end

	lastAttackTime = now
	isAttacking = true

	-- Procedural Anime Combat Animation Trigger
	local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
	if evAnim then
		local animName = if isLowSweep then "LowSweep" else ("Attack" .. tostring(currentComboIndex))
		local animDur = if isLowSweep then 0.45 elseif isHeavyFinisher then 0.55 else 0.30
		evAnim:Fire(animName, animDur)
	end

	-- Storm 4 Forward Lunge
	local forwardDir = root.CFrame.LookVector
	local lungeSpeed = if isHeavyFinisher then 40 else (if isLowSweep then 22 else LUNGE_FORCE)
	root.AssemblyLinearVelocity = Vector3.new(forwardDir.X * lungeSpeed, root.AssemblyLinearVelocity.Y, forwardDir.Z * lungeSpeed)

	-- Visual & Sound
	playAttackFX(root, isHeavyFinisher, isLowSweep)

	-- Hit detection
	local hitTarget = findHitTarget(root)
	local attackType = if isLowSweep then "Low" elseif (currentComboIndex == 2 or currentComboIndex == 4) then "Mid" else "High"
	local damage = if isLowSweep then 16 elseif isHeavyFinisher then 24 elseif currentComboIndex == 3 then 14 elseif currentComboIndex == 2 then 10 else 8
	local knockback = if isHeavyFinisher then 48 elseif isLowSweep then 12 else 4

	if hitTarget and evAttack then
		evAttack:FireServer(hitTarget, currentComboIndex, attackType, damage, knockback)
	end

	-- Attack recovery cooldown
	local recoveryTime = if isHeavyFinisher then 0.50 elseif isLowSweep then 0.40 else 0.22
	task.delay(recoveryTime, function()
		isAttacking = false
	end)
end

-- =========================================================
-- ATTACKER STAGGER (Triggered if Opponent Parries this attack)
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

	-- Stagger Sparkles
	local att = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 80, 80))
	pe.Size = NumberSequence.new(1.2, 0)
	pe.Rate = 50
	pe.Speed = NumberRange.new(4, 10)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att

	print(">> [COUNTERED!] Your attack was Parried! Staggered for 1.1s! <<")

	task.delay(1.15, function()
		att:Destroy()
		if hum then hum.WalkSpeed = 16 end
		isStaggered = false
	end)
end

if evParry then
	evParry.OnClientEvent:Connect(function(_defender: Player, attacker: Player)
		if attacker == LocalPlayer then
			triggerAttackerParriedStagger()
		end
	end)
end

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- 1. Keyboard [J] (Pukulan Biasa) or Left-Click or Gamepad (Square / X)
	if input.KeyCode == Enum.KeyCode.J or input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonX then
		executeAttack(false)
	-- 2. Keyboard [K] (Serangan Bawah / Low Sweep) or Gamepad DPadDown
	elseif input.KeyCode == Enum.KeyCode.K or input.KeyCode == Enum.KeyCode.DPadDown then
		executeAttack(true)
	end
end)

-- Mobile Touch Integration
if evMobileAttack then
	evMobileAttack.Event:Connect(function(isLow: any)
		executeAttack(isLow == true)
	end)
end

local evMobileLow = ReplicatedStorage:FindFirstChild("MobileLowAttackAction") :: BindableEvent?
if not evMobileLow then
	evMobileLow = Instance.new("BindableEvent")
	evMobileLow.Name = "MobileLowAttackAction"
	evMobileLow.Parent = ReplicatedStorage
end
evMobileLow.Event:Connect(function()
	executeAttack(true)
end)

print("[CombatComboController] ✅ Loaded — Pukulan Biasa [J], Serangan Bawah [K], Gamepad (Square=Punch / DPadDown=Low).")
]=====]
    installScript('CombatComboController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
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
		Sound = "rbxasset://sounds/action_whoosh.mp3",
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
		snd.SoundId = rangedData.Sound or "rbxasset://sounds/action_whoosh.mp3"
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
    installScript('StormRangedController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- StormAssistController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Assist Striker Summon & Leader Swap
-- Features:
--   • WASD Movement + IJKL Assist System:
--       [I] Key or [T]: Summon Assist Partner (Flame Bullet / Lightning Jutsu)
--       [U] Key or [G]: Leader Swap (Tag-out partner combo continuation)
--   • Full Controller Support: Gamepad L1 (Assist) & L2 (Leader Swap)
--   • Mobile Touch Support via Custom BindableEvent
--   • Assist Gauge HUD with real-time countdown & speedline flash on tag

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera :: Camera

-- Configuration
local ASSIST_COOLDOWN = 20
local lastAssistTime = -ASSIST_COOLDOWN
local isAssistAvailable = true

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local evAssist = combatEvents and combatEvents:FindFirstChild("AssistEvent") :: RemoteEvent?
local evLeaderSwap = combatEvents and combatEvents:FindFirstChild("LeaderSwapEvent") :: RemoteEvent?

-- Mobile/UI Bindable Integration
local evMobileAssist = ReplicatedStorage:FindFirstChild("MobileAssistAction") :: BindableEvent?
if not evMobileAssist then
	evMobileAssist = Instance.new("BindableEvent")
	evMobileAssist.Name = "MobileAssistAction"
	evMobileAssist.Parent = ReplicatedStorage
end

local evMobileSwap = ReplicatedStorage:FindFirstChild("MobileSwapAction") :: BindableEvent?
if not evMobileSwap then
	evMobileSwap = Instance.new("BindableEvent")
	evMobileSwap.Name = "MobileSwapAction"
	evMobileSwap.Parent = ReplicatedStorage
end

-- =========================================================
-- ASSIST GAUGE HUD
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormAssistHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local card = Instance.new("Frame")
card.Name = "AssistCard"
card.Size = UDim2.new(0, 195, 0, 52)
card.Position = UDim2.new(0, 24, 0.88, -26)
card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
card.BackgroundTransparency = 0.15
card.BorderSizePixel = 0
card.Parent = screenGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(0, 255, 200)
cardStroke.Thickness = 2
cardStroke.Parent = card

-- Portrait Box
local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 40, 0, 40)
iconBox.Position = UDim2.new(0, 6, 0.5, -20)
iconBox.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
iconBox.BorderSizePixel = 0
iconBox.Parent = card
Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 8)

local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.fromScale(1, 1)
iconText.BackgroundTransparency = 1
iconText.Text = "⚡"
iconText.TextSize = 22
iconText.Parent = iconBox

-- Assist Name & Key Hint
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -55, 0, 18)
nameLabel.Position = UDim2.new(0, 52, 0, 6)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "ASSIST [I / T]: SHADOW STRIKER"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 9.5
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = card

-- Cooldown Bar
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -58, 0, 8)
barBg.Position = UDim2.new(0, 52, 0, 26)
barBg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
barBg.BorderSizePixel = 0
barBg.Parent = card
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

local swapLabel = Instance.new("TextLabel")
swapLabel.Size = UDim2.new(1, -55, 0, 12)
swapLabel.Position = UDim2.new(0, 52, 0, 36)
swapLabel.BackgroundTransparency = 1
swapLabel.Text = "TAG SWAP [U / G] READY"
swapLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
swapLabel.Font = Enum.Font.GothamMedium
swapLabel.TextSize = 9
swapLabel.TextXAlignment = Enum.TextXAlignment.Left
swapLabel.Parent = card

-- =========================================================
-- CALL ASSIST STRIKER
-- =========================================================
local function callAssistStriker()
	local now = os.clock()
	if now - lastAssistTime < ASSIST_COOLDOWN then
		print(">> [Assist] On cooldown! <<")
		return
	end

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	lastAssistTime = now
	isAssistAvailable = false

	-- Animate Assist HUD Cooldown
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	cardStroke.Color = Color3.fromRGB(100, 100, 100)

	-- Fire to server
	if evAssist then
		evAssist:FireServer("FireballStriker")
	end

	-- Sound
	pcall(function()
		local callSnd = Instance.new("Sound")
		callSnd.SoundId = "rbxasset://sounds/volume_slider.ogg"
		callSnd.PlaybackSpeed = 1.8
		callSnd.Volume = 0.9
		callSnd.Parent = root
		callSnd:Play()
		task.delay(0.5, function() pcall(function() callSnd:Destroy() end) end)
	end)

	print(">> [Storm Assist] Sasuke / Shadow Striker summoned! <<")

	-- Cooldown restoration loop
	task.spawn(function()
		while true do
			task.wait(0.1)
			local elapsed = os.clock() - lastAssistTime
			local progress = math.clamp(elapsed / ASSIST_COOLDOWN, 0, 1)
			barFill.Size = UDim2.new(progress, 0, 1, 0)

			if progress >= 1 then
				barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
				cardStroke.Color = Color3.fromRGB(0, 255, 200)
				isAssistAvailable = true
				break
			end
		end
	end)
end

-- =========================================================
-- LEADER SWAP (Press U / G / Gamepad L2)
-- =========================================================
local function executeLeaderSwap()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Screen Flash / Speedline effect
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.4
	flash.BorderSizePixel = 0
	flash.Parent = screenGui

	local tw = TweenService:Create(flash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function() flash:Destroy() end)

	-- Swap Sound
	pcall(function()
		local swapSnd = Instance.new("Sound")
		swapSnd.SoundId = "rbxasset://sounds/action_jump.mp3"
		swapSnd.PlaybackSpeed = 1.6
		swapSnd.Volume = 1
		swapSnd.Parent = root
		swapSnd:Play()
		task.delay(0.5, function() pcall(function() swapSnd:Destroy() end) end)
	end)

	if evLeaderSwap then
		evLeaderSwap:FireServer()
	end

	print(">> [Storm 4 LEADER SWAP] Tagged in Partner! Combo Synergy active! <<")
end

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- 1. Assist Summon with [I] or [T] or Gamepad ButtonL1
	if input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.ButtonL1 then
		callAssistStriker()
	-- 2. Leader Swap with [U] or [G] or Gamepad ButtonL2
	elseif input.KeyCode == Enum.KeyCode.U or input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonL2 then
		executeLeaderSwap()
	end
end)

-- Mobile Touch Integration
if evMobileAssist then
	evMobileAssist.Event:Connect(function()
		callAssistStriker()
	end)
end

if evMobileSwap then
	evMobileSwap.Event:Connect(function()
		executeLeaderSwap()
	end)
end

print("[StormAssistController] ✅ Loaded — Assist [I] / [T] / Gamepad (L1), Leader Swap [U] / [G] / Gamepad (L2).")
]=====]
    installScript('StormAssistController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

return 'Part 2 Installed Successfully (6 scripts)'