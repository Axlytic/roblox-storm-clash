--!strict
-- StormUltimateController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Ultimate Secret Technique & Tekken Awakening (Rage) Mode
-- Features:
--   • Chakra Charging System (Hold [C] or Mobile [CHAKRA] button)
--   • Full Cinematic Ultimate Jutsu (Press [O] / Mobile [ULTIMATE] when Chakra = 100%):
--       - Cinematic 21:9 Letterbox Black Bars slide in
--       - Dramatic close-up camera zoom & sonic rush towards target
--       - 5-Hit Anime Multihit Barrage with orbital camera & screen shake
--       - Supermassive energy explosion dealing 52 Ultimate Finisher Damage
--   • Tekken Awakening / Rage Mode (Auto-triggers when HP < 30%):
--       - Blazing crimson flame aura & heartbeat screen vignette
--       - +25% Attack Damage & +20% Dash Speed boost

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder?
local evAttack = combatEvents and combatEvents:FindFirstChild("AttackEvent") :: RemoteEvent?

-- Ensure Ultimate Remote
local evUltimate = combatEvents and combatEvents:FindFirstChild("UltimateEvent") :: RemoteEvent?
if not evUltimate and combatEvents then
	evUltimate = Instance.new("RemoteEvent")
	evUltimate.Name = "UltimateEvent"
	evUltimate.Parent = combatEvents
end

-- Mobile Bindables
local evMobileUltimate = ReplicatedStorage:FindFirstChild("MobileUltimateAction") :: BindableEvent?
if not evMobileUltimate then
	evMobileUltimate = Instance.new("BindableEvent")
	evMobileUltimate.Name = "MobileUltimateAction"
	evMobileUltimate.Parent = ReplicatedStorage
end

local evMobileChakra = ReplicatedStorage:FindFirstChild("MobileChakraAction") :: BindableEvent?
if not evMobileChakra then
	evMobileChakra = Instance.new("BindableEvent")
	evMobileChakra.Name = "MobileChakraAction"
	evMobileChakra.Parent = ReplicatedStorage
end

local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?

-- State
local chakra = 60
local isChargingChakra = false
local isExecutingUltimate = false
local isAwakeningActive = false

LocalPlayer:SetAttribute("ChakraValue", chakra)
LocalPlayer:SetAttribute("IsAwakening", false)

-- =========================================================
-- CINEMATIC LETTERBOX GUI & RAGE VIGNETTE
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormCinematicGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Top Letterbox Bar
local barTop = Instance.new("Frame")
barTop.Name = "LetterboxTop"
barTop.Size = UDim2.new(1, 0, 0, 0)
barTop.Position = UDim2.new(0, 0, 0, 0)
barTop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barTop.BorderSizePixel = 0
barTop.Parent = screenGui

-- Bottom Letterbox Bar
local barBottom = Instance.new("Frame")
barBottom.Name = "LetterboxBottom"
barBottom.Size = UDim2.new(1, 0, 0, 0)
barBottom.Position = UDim2.new(0, 0, 1, 0)
barBottom.AnchorPoint = Vector2.new(0, 1)
barBottom.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barBottom.BorderSizePixel = 0
barBottom.Parent = screenGui

-- Rage Vignette Frame
local rageVignette = Instance.new("Frame")
rageVignette.Name = "RageVignette"
rageVignette.Size = UDim2.fromScale(1, 1)
rageVignette.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
rageVignette.BackgroundTransparency = 1
rageVignette.BorderSizePixel = 0
rageVignette.Parent = screenGui

local function toggleLetterbox(show: boolean)
	local targetHeight = show and 68 or 0
	TweenService:Create(barTop, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, targetHeight),
	}):Play()
	TweenService:Create(barBottom, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, targetHeight),
	}):Play()
end

-- =========================================================
-- SCREEN SHAKE HELPER
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

-- =========================================================
-- FIND TARGET
-- =========================================================
local function findTarget(): Model?
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		return dummy
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			return p.Character
		end
	end
	return nil
end

-- =========================================================
-- CHAKRA CHARGING (Hold [C] or Mobile Button)
-- =========================================================
local chargeEmitter: ParticleEmitter? = nil

local function startChakraCharge()
	if isExecutingUltimate or isChargingChakra then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	isChargingChakra = true
	LocalPlayer:SetAttribute("IsChakraCharging", true)

	-- Spawning swirling blue chakra particles
	local att = Instance.new("Attachment", root)
	att.Name = "ChakraAtt"
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255), Color3.fromRGB(0, 100, 255))
	pe.Size = NumberSequence.new(1.8, 0)
	pe.Rate = 50
	pe.Speed = NumberRange.new(4, 10)
	pe.SpreadAngle = Vector2.new(360, 360)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Parent = att
	chargeEmitter = pe

	-- Sound
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/volume_slider.ogg"
		snd.PlaybackSpeed = 0.8
		snd.Volume = 0.8
		snd.Parent = root
		snd:Play()
		task.delay(1, function() pcall(function() snd:Destroy() end) end)
	end)

	if evAnim then
		evAnim:Fire("ChakraCharge", 999)
	end
end

local function stopChakraCharge()
	if not isChargingChakra then return end
	isChargingChakra = false
	LocalPlayer:SetAttribute("IsChakraCharging", false)

	if chargeEmitter then
		local att = chargeEmitter.Parent :: Attachment?
		chargeEmitter:Destroy()
		chargeEmitter = nil
		if att then att:Destroy() end
	end
end

-- Charging Loop
RunService.Heartbeat:Connect(function(dt: number)
	if isChargingChakra then
		chakra = math.clamp(chakra + (35 * dt), 0, 100)
		LocalPlayer:SetAttribute("ChakraValue", chakra)
	end
end)

-- =========================================================
-- ULTIMATE SECRET TECHNIQUE (Press [O] when Chakra = 100)
-- =========================================================
local function executeUltimateJutsu()
	if isExecutingUltimate or chakra < 100 then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local target = findTarget()
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHum = target:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not targetHum or targetHum.Health <= 0 then return end

	isExecutingUltimate = true
	chakra = 0
	LocalPlayer:SetAttribute("ChakraValue", chakra)

	-- 1. Cinematic Phase 1: Letterbox & Slow-mo Focus
	toggleLetterbox(true)

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/volume_slider.ogg"
		snd.PlaybackSpeed = 1.8
		snd.Volume = 1
		snd.Parent = root
		snd:Play()
		task.delay(0.6, function() pcall(function() snd:Destroy() end) end)
	end)

	if evAnim then
		evAnim:Fire("Attack3", 0.6)
	end

	-- 2. Supersonic Rush toward target
	local rushDir = (targetRoot.Position - root.Position).Unit
	root.AssemblyLinearVelocity = rushDir * 125

	local rushStart = os.clock()
	local connected = false

	while os.clock() - rushStart < 0.85 do
		RunService.Heartbeat:Wait()
		local dist = (targetRoot.Position - root.Position).Magnitude
		if dist <= 7.0 then
			connected = true
			break
		end
		root.AssemblyLinearVelocity = (targetRoot.Position - root.Position).Unit * 125
	end

	if not connected then
		-- Missed
		isExecutingUltimate = false
		toggleLetterbox(false)
		return
	end

	-- 3. Cinematic Phase 2: Multihit Flurry Sequence
	root.AssemblyLinearVelocity = Vector3.zero
	targetRoot.AssemblyLinearVelocity = Vector3.zero

	-- Dynamic Orbit Camera during cinematic
	local origCamType = Camera.CameraType
	Camera.CameraType = Enum.CameraType.Scriptable

	local cutsceneStart = os.clock()
	local multihitCount = 0

	task.spawn(function()
		while os.clock() - cutsceneStart < 1.8 do
			local elapsed = os.clock() - cutsceneStart
			multihitCount = multihitCount + 1

			-- Orbit camera angle
			local angle = elapsed * 3.5
			local camOffset = Vector3.new(math.cos(angle) * 11, 4.5, math.sin(angle) * 11)
			Camera.CFrame = CFrame.lookAt(targetRoot.Position + camOffset, targetRoot.Position + Vector3.new(0, 1.5, 0))

			-- Impact burst & sound
			screenShake(0.8, 0.08)
			pcall(function()
				local snd = Instance.new("Sound")
				snd.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
				snd.PlaybackSpeed = 1.4 + (multihitCount * 0.1)
				snd.Volume = 0.9
				snd.Parent = targetRoot
				snd:Play()
				task.delay(0.3, function() pcall(function() snd:Destroy() end) end)
			end)

			if evAnim then
				local animChoice = if multihitCount % 2 == 0 then "Attack1" else "Attack2"
				evAnim:Fire(animChoice, 0.2)
			end

			task.wait(0.18)
		end

		-- 4. Cinematic Phase 3: Supermassive Finisher Blast!
		screenShake(2.5, 0.4)

		-- Giant Neon Explosion Ball
		local blast = Instance.new("Part")
		blast.Shape = Enum.PartType.Ball
		blast.Size = Vector3.new(2, 2, 2)
		blast.Position = targetRoot.Position
		blast.Color = Color3.fromRGB(0, 240, 255)
		blast.Material = Enum.Material.Neon
		blast.Anchored = true
		blast.CanCollide = false
		blast.Parent = Workspace

		TweenService:Create(blast, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(18, 18, 18),
			Transparency = 1,
		}):Play()
		task.delay(0.5, function() blast:Destroy() end)

		-- Heavy Explosion Sound
		pcall(function()
			local heavySnd = Instance.new("Sound")
			heavySnd.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
			heavySnd.PlaybackSpeed = 0.9
			heavySnd.Volume = 1
			heavySnd.Parent = targetRoot
			heavySnd:Play()
			task.delay(1, function() pcall(function() heavySnd:Destroy() end) end)
		end)

		-- Deal 52 Ultimate Finisher Damage
		if evAttack then
			evAttack:FireServer(target, 4, "High", 52, 65)
		else
			targetHum:TakeDamage(52)
		end

		-- Knock opponent flying
		local knockDir = (targetRoot.Position - root.Position).Unit
		targetRoot.AssemblyLinearVelocity = knockDir * 65 + Vector3.new(0, 18, 0)

		if evAnim then
			evAnim:Fire("Attack4", 0.6)
		end

		task.wait(0.5)
		Camera.CameraType = origCamType
		toggleLetterbox(false)
		isExecutingUltimate = false
	end)
end

-- =========================================================
-- TEKKEN AWAKENING / RAGE MONITOR (HP < 30%)
-- =========================================================
local rageEmitter: ParticleEmitter? = nil

local function updateAwakening(hum: Humanoid, root: BasePart)
	local hpRatio = hum.Health / hum.MaxHealth

	if hpRatio <= 0.30 and hum.Health > 0 and not isAwakeningActive then
		isAwakeningActive = true
		LocalPlayer:SetAttribute("IsAwakening", true)
		print(">> [TEKKEN AWAKENING / RAGE] Health Critical! Rage Mode Active (+25% Damage)! <<")

		-- Blazing crimson flame aura
		local att = Instance.new("Attachment", root)
		att.Name = "RageAuraAtt"
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 120, 20))
		pe.Size = NumberSequence.new(2.2, 0)
		pe.Rate = 55
		pe.Speed = NumberRange.new(5, 12)
		pe.Lifetime = NumberRange.new(0.3, 0.5)
		pe.Parent = att
		rageEmitter = pe

		-- Screen edge red vignette pulse
		TweenService:Create(rageVignette, TweenInfo.new(0.4), { BackgroundTransparency = 0.85 }):Play()

		pcall(function()
			local snd = Instance.new("Sound")
			snd.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
			snd.PlaybackSpeed = 1.6
			snd.Volume = 0.9
			snd.Parent = root
			snd:Play()
			task.delay(0.6, function() pcall(function() snd:Destroy() end) end)
		end)

	elseif (hpRatio > 0.30 or hum.Health <= 0) and isAwakeningActive then
		isAwakeningActive = false
		LocalPlayer:SetAttribute("IsAwakening", false)
		if rageEmitter then
			local att = rageEmitter.Parent :: Attachment?
			rageEmitter:Destroy()
			rageEmitter = nil
			if att then att:Destroy() end
		end
		TweenService:Create(rageVignette, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	end
end

-- Setup Health Listener
local function monitorCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	local root = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hum or not root then return end

	hum.HealthChanged:Connect(function()
		updateAwakening(hum, root)
	end)
end

if LocalPlayer.Character then
	monitorCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(monitorCharacter)

-- =========================================================
-- INPUT LISTENERS (Key [O] for Ultimate, Key [C] for Chakra)
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.O then
		executeUltimateJutsu()
	elseif input.KeyCode == Enum.KeyCode.C then
		startChakraCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.C then
		stopChakraCharge()
	end
end)

-- Mobile Bindable Events
evMobileUltimate.Event:Connect(executeUltimateJutsu)
evMobileChakra.Event:Connect(function(isDown: boolean)
	if isDown then
		startChakraCharge()
	else
		stopChakraCharge()
	end
end)

print("[StormUltimateController] ✅ Ultimate Secret Technique & Tekken Awakening active.")
