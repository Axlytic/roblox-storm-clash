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
local evNinjutsu = combatEvents and combatEvents:WaitForChild("NinjutsuEvent") :: RemoteEvent?

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
		evAnim:Fire("ChakraLoad", 999)
	end
end

local function stopChakraCharge()
	if not isChargingChakra then return end
	isChargingChakra = false
	LocalPlayer:SetAttribute("IsChakraCharging", false)

	if evAnim then
		evAnim:Fire("Idle", 0.2)
	end

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
-- CHAKRA LOAD AURA (Storm 4 Flashing Blue State)
-- =========================================================
local chakraLoadPart: Part? = nil
local chakraLoadTimeoutThread: thread? = nil

local function activateChakraLoad()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local curVal = LocalPlayer:GetAttribute("ChakraValue") or 60
	if curVal < 15 then
		print(">> [Chakra Load] Not enough chakra to load! <<")
		return
	end

	LocalPlayer:SetAttribute("IsChakraLoaded", true)
	print(">> [Chakra Load] CHAKRA LOADED! Press Dash for Chakra Dash, Melee for Ninjutsu! <<")
	if evAnim then
		evAnim:Fire("ChakraLoad", 0.45)
	end

	-- Visual Flashing Blue Chakra Aura Part
	if chakraLoadPart then chakraLoadPart:Destroy() end
	local aura = Instance.new("Part")
	aura.Name = "ChakraLoadAura"
	aura.Shape = Enum.PartType.Ball
	aura.Size = Vector3.new(4.5, 4.5, 4.5)
	aura.CFrame = root.CFrame
	aura.Material = Enum.Material.ForceField
	aura.Color = Color3.fromRGB(0, 240, 255)
	aura.Transparency = 0.35
	aura.CanCollide = false
	aura.Anchored = false
	aura.Parent = char
	chakraLoadPart = aura

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = aura
	weld.Parent = aura

	local att = Instance.new("Attachment", aura)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(80, 180, 255))
	pe.Size = NumberSequence.new(1.8, 0)
	pe.Rate = 75
	pe.Speed = NumberRange.new(5, 12)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Parent = att

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		snd.PlaybackSpeed = 1.4
		snd.Volume = 0.9
		snd.Parent = root
		snd:Play()
		task.delay(0.5, function() pcall(function() snd:Destroy() end) end)
	end)

	if chakraLoadTimeoutThread then task.cancel(chakraLoadTimeoutThread) end
	chakraLoadTimeoutThread = task.delay(2.2, function()
		LocalPlayer:SetAttribute("IsChakraLoaded", false)
		if chakraLoadPart then
			chakraLoadPart:Destroy()
			chakraLoadPart = nil
		end
	end)
end

local function deactivateChakraLoad()
	LocalPlayer:SetAttribute("IsChakraLoaded", false)
	if chakraLoadPart then
		chakraLoadPart:Destroy()
		chakraLoadPart = nil
	end
end

LocalPlayer:GetAttributeChangedSignal("IsChakraLoaded"):Connect(function()
	if LocalPlayer:GetAttribute("IsChakraLoaded") == false and chakraLoadPart then
		chakraLoadPart:Destroy()
		chakraLoadPart = nil
	end
end)

-- =========================================================
-- INPUT LISTENERS: [I] Chakra Load (Tap) / Charge & Ult (Hold)
-- =========================================================
local isHoldingI = false
local iPressStartTime = 0

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- 1. [I] Key (Naruto Storm: Chakra Load on Tap / Charge & Ult on Hold)
	if input.KeyCode == Enum.KeyCode.I then
		isHoldingI = true
		iPressStartTime = os.clock()
		startChakraCharge()

		-- Hold watcher: If held >= 0.60s and Chakra is full (100%), unleash Ultimate!
		task.spawn(function()
			while isHoldingI do
				task.wait(0.05)
				local heldDuration = os.clock() - iPressStartTime
				if isHoldingI and chakra >= 100 and heldDuration >= 0.60 and not isExecutingUltimate then
					print(">> [StormUltimate] [I] Key Hold threshold reached with 100% Chakra! Unleashing Ultimate! <<")
					stopChakraCharge()
					deactivateChakraLoad()
					executeUltimateJutsu()
					break
				end
			end
		end)

	-- 2. [J] Key while Chakra Loaded = NINJUTSU!
	elseif input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.ButtonX then
		if LocalPlayer:GetAttribute("IsChakraLoaded") == true then
			local curVal = LocalPlayer:GetAttribute("ChakraValue") or 60
			if curVal >= 25 then
				deactivateChakraLoad()
				local target = findTarget()
				if evAnim then
					evAnim:Fire("NinjutsuRush", 0.65)
				end
				if evNinjutsu then
					evNinjutsu:FireServer(target)
				end
			end
		end

	-- 3. Secondary/Fallback keys
	elseif input.KeyCode == Enum.KeyCode.O then
		executeUltimateJutsu()
	elseif input.KeyCode == Enum.KeyCode.C then
		startChakraCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.I then
		local pressDuration = os.clock() - iPressStartTime
		isHoldingI = false
		stopChakraCharge()

		-- If quick tap (< 0.28s), toggle Chakra Loaded state!
		if pressDuration < 0.28 and not isExecutingUltimate then
			if LocalPlayer:GetAttribute("IsChakraLoaded") == true then
				deactivateChakraLoad()
			else
				activateChakraLoad()
			end
		end
	elseif input.KeyCode == Enum.KeyCode.C then
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

print("[StormUltimateController] ✅ Loaded — Storm 4 Chakra Load [Tap I], Ninjutsu [I+J], Ultimate [Hold I at 100% / O].")
]=====]
    install('StormUltimateController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- StormAssistController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Assist Striker Summon & Leader Swap
-- Features:
--   • Assist System:
--       [T] Key or Gamepad L1: Summon Assist Partner (Flame Bullet / Lightning Jutsu)
--       [U] Key or [G] or Gamepad L2: Leader Swap (Tag-out partner combo continuation)
--   • Note: [I] is strictly reserved for Chakra Charge & Ultimate Jutsu!
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
nameLabel.Text = "ASSIST [T / L1]: SHADOW STRIKER"
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
	-- 1. Assist Summon with [T] or Gamepad ButtonL1 (Note: [I] is reserved for Chakra/Ult)
	if input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.ButtonL1 then
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

print("[StormAssistController] ✅ Loaded — Assist [T] / Gamepad (L1), Leader Swap [U] / [G] / Gamepad (L2).")
]=====]
    install('StormAssistController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- StormAnimationController.luau
-- CLIENT SCRIPT: Master Procedural Anime Combat Animation Engine
-- Features:
--   • 100% Asset-Independent: Zero asset load failures or HTTP 403 permission errors
--   • Multi-Keyframe Sequence Engine with Sub-Frame Hermite Smoothstep Easing:
--       - Phase 0: Anticipation / Energy Windup (Coiling joints)
--       - Phase 1: Explosive Release / Strike Snap (Acceleration)
--       - Phase 2: Micro Hitstop / Impact Frame (Freeze at peak extension)
--       - Phase 3: Recoil / Follow-through & Settle
--   • Complete Naruto Storm 4 Move List:
--       - Idle: Dynamic breathing sway with shinobi guard posture
--       - Neutral Combo (4-Hit): Right Jab -> Left Hook -> Roundhouse Kick -> Twin Palm Blast
--       - Up Combo (4-Hit): Rising Chin Jab -> Crescent Kick -> Backflip -> Skyward Leaping Uppercut (Launcher)
--       - Down Combo (4-Hit): Shin Kick -> 360 Low Sweep -> Overhead Heel Drop -> Heavy Ground Slam (Bounce)
--       - Air Combo (3-Hit): Air Thrust -> 360 Helicopter Kick -> Meteor Dive Spike
--       - Storm 4 Counter Stance: Cross-arm X-Guard -> Explosive Deflection Repel
--       - Chakra Load: Iconic Naruto Ram Hand Seal with pulsing aura
--       - Ninjutsu Rush: Low forward sprint thrusting Rasengan / Chidori palm forward
--       - Kawarimi: Flash Vanish Seal gesture
--       - Ninja Dash: 52° forward aerodynamic dive with trailing arms
--       - Hit Reactions: High Head Snap, Mid Gut Flinch, Stagger Stun (Dizzy Wobble)
--   • Real-Time Katana & Weapon Trail Synchronization

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- TYPES & DATA STRUCTURES
-- =========================================================
type JointOffsets = { [string]: CFrame }

type Keyframe = {
	t: number, -- Time fraction (0.0 to 1.0)
	offsets: JointOffsets,
}

type AnimationSequence = {
	duration: number,
	loop: boolean?,
	keyframes: { Keyframe },
}

-- Universal Joint Cache (AnimationConstraint & Motor6D)
local joints: { [string]: Instance } = {}
local baseC0: { [string]: CFrame } = {}
local katanaTrail: Trail? = nil

-- Animation State
local currentAnimName = "Idle"
local animStartTime = 0
local animDuration = 1.0
local isLooping = true
local currentSequence: AnimationSequence? = nil

-- Forward declaration of triggerCombatAnimation
local triggerCombatAnimation: (animName: string, durationOverride: number?) -> ()

-- Hit Flinch State
local flinchEndTime = 0
local flinchOffsets: JointOffsets = {}

-- =========================================================
-- EASING HELPERS (Hermite Smoothstep & Overshoot Snap)
-- =========================================================
local function smoothstep(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function snapEase(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * x * (x * (x * 6 - 15) + 10) -- Smootherstep
end

-- =========================================================
-- JOINT FINDER (Supports full R15 AnimationConstraint, Motor6D, and R6 fallback)
-- =========================================================
local function setupCharacter(char: Model)
	table.clear(joints)
	table.clear(baseC0)

	local function findJoint(name: string): Instance?
		for _, desc in ipairs(char:GetDescendants()) do
			if (desc:IsA("AnimationConstraint") or desc:IsA("Motor6D")) and (desc.Name == name or desc.Name:lower() == name:lower()) then
				return desc
			end
		end
		return nil
	end

	-- Universal R15 & R6 Joint Mapping
	joints["RootJoint"]     = findJoint("RootJoint") or findJoint("Root")
	joints["Waist"]         = findJoint("Waist")
	joints["Neck"]          = findJoint("Neck")
	joints["RightShoulder"] = findJoint("RightShoulder") or findJoint("Right Shoulder")
	joints["LeftShoulder"]  = findJoint("LeftShoulder") or findJoint("Left Shoulder")
	joints["RightElbow"]    = findJoint("RightElbow")
	joints["LeftElbow"]     = findJoint("LeftElbow")
	joints["RightWrist"]    = findJoint("RightWrist")
	joints["LeftWrist"]     = findJoint("LeftWrist")
	joints["RightHip"]      = findJoint("RightHip") or findJoint("Right Hip")
	joints["LeftHip"]       = findJoint("LeftHip") or findJoint("Left Hip")
	joints["RightKnee"]     = findJoint("RightKnee")
	joints["LeftKnee"]      = findJoint("LeftKnee")
	joints["RightAnkle"]    = findJoint("RightAnkle")
	joints["LeftAnkle"]     = findJoint("LeftAnkle")

	-- Cache default C0 for Motor6D fallback
	for key, joint in pairs(joints) do
		if joint and joint:IsA("Motor6D") then
			baseC0[key] = (joint :: Motor6D).C0
		end
	end

	-- Katana Slash Trail lookup
	task.delay(0.4, function()
		local katana = char:FindFirstChild("StormKatana")
		if katana then
			local blade = katana:FindFirstChild("Blade")
			if blade then
				katanaTrail = blade:FindFirstChild("SlashTrail") :: Trail?
			end
		end
	end)

	-- Dynamic Hit Reaction Listener
	local hum = char:WaitForChild("Humanoid", 3) :: Humanoid?
	if hum then
		local lastHealth = hum.Health
		hum.HealthChanged:Connect(function(newHealth)
			if newHealth < lastHealth and newHealth > 0 then
				local diff = lastHealth - newHealth
				if currentAnimName ~= "Ultimate" and currentAnimName ~= "StaggerStun" and currentAnimName ~= "CounterStance" then
					local hitAnim = if diff >= 18 then "HitHead" else "HitGut"
					if triggerCombatAnimation then
						triggerCombatAnimation(hitAnim, 0.22)
					end
				end
			end
			lastHealth = newHealth
		end)
	end
end

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- =========================================================
-- DEFINING DETAILED ANIME ANIMATION SEQUENCES
-- =========================================================
local ANIMATIONS: { [string]: AnimationSequence } = {}

-- ---------------------------------------------------------
-- [0] IDLE: Shinobi Combat Stance (Natural Breathing + Boxing Guard)
-- ---------------------------------------------------------
ANIMATIONS["Idle"] = {
	duration = 1.8,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, math.rad(-18), 0),
				Waist         = CFrame.Angles(0, math.rad(18), 0),
				Neck          = CFrame.Angles(math.rad(2), math.rad(4), 0),
				RightShoulder = CFrame.new(-0.05, -0.05, -0.1) * CFrame.Angles(math.rad(38), math.rad(-22), math.rad(18)),
				LeftShoulder  = CFrame.new(0.05, -0.02, 0.1) * CFrame.Angles(math.rad(48), math.rad(32), math.rad(-22)),
				RightElbow    = CFrame.Angles(math.rad(52), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(68), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-8), 0, math.rad(12)),
				LeftHip       = CFrame.Angles(math.rad(12), 0, math.rad(-10)),
				RightKnee     = CFrame.Angles(math.rad(15), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(18), 0, 0),
			}
		},
		{
			t = 0.5,
			offsets = {
				RootJoint     = CFrame.new(0, 0.02, 0) * CFrame.Angles(0, math.rad(-18), 0),
				Waist         = CFrame.Angles(math.rad(2), math.rad(18), 0),
				Neck          = CFrame.Angles(math.rad(-1), math.rad(4), 0),
				RightShoulder = CFrame.new(-0.05, -0.02, -0.1) * CFrame.Angles(math.rad(42), math.rad(-22), math.rad(18)),
				LeftShoulder  = CFrame.new(0.05, 0.01, 0.1) * CFrame.Angles(math.rad(52), math.rad(32), math.rad(-22)),
				RightElbow    = CFrame.Angles(math.rad(48), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(64), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-8), 0, math.rad(12)),
				LeftHip       = CFrame.Angles(math.rad(12), 0, math.rad(-10)),
				RightKnee     = CFrame.Angles(math.rad(12), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(14), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, math.rad(-18), 0),
				Waist         = CFrame.Angles(0, math.rad(18), 0),
				Neck          = CFrame.Angles(math.rad(2), math.rad(4), 0),
				RightShoulder = CFrame.new(-0.05, -0.05, -0.1) * CFrame.Angles(math.rad(38), math.rad(-22), math.rad(18)),
				LeftShoulder  = CFrame.new(0.05, -0.02, 0.1) * CFrame.Angles(math.rad(48), math.rad(32), math.rad(-22)),
				RightElbow    = CFrame.Angles(math.rad(52), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(68), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-8), 0, math.rad(12)),
				LeftHip       = CFrame.Angles(math.rad(12), 0, math.rad(-10)),
				RightKnee     = CFrame.Angles(math.rad(15), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(18), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [1] NEUTRAL COMBO (4-Hit Iconic Martial Flurry)
-- ---------------------------------------------------------
-- Hit 1: Fast Right Straight Jab (Windup -> Explosive Snap -> Recoil)
ANIMATIONS["Neutral1"] = {
	duration = 0.26,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-15), 0),
				Waist         = CFrame.Angles(0, math.rad(15), 0),
				RightShoulder = CFrame.new(0, 0, 0.2) * CFrame.Angles(math.rad(30), math.rad(-45), 0),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(55), math.rad(35), 0),
				LeftElbow     = CFrame.Angles(math.rad(70), 0, 0),
			}
		},
		{
			t = 0.42, -- Snap Strike!
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, -0.4) * CFrame.Angles(0, math.rad(32), 0),
				Waist         = CFrame.Angles(0, math.rad(-30), 0),
				Neck          = CFrame.Angles(0, math.rad(-10), 0),
				RightShoulder = CFrame.new(0.1, 0.1, -0.8) * CFrame.Angles(math.rad(88), math.rad(15), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(10), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(45), math.rad(40), 0),
				LeftElbow     = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(15), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-25), 0, 0),
			}
		},
		{
			t = 1.0, -- Settle
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-10), 0),
				Waist         = CFrame.Angles(0, math.rad(10), 0),
				RightShoulder = CFrame.new(0, 0, -0.1) * CFrame.Angles(math.rad(40), math.rad(-20), 0),
				RightElbow    = CFrame.Angles(math.rad(55), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(50), math.rad(30), 0),
				LeftElbow     = CFrame.Angles(math.rad(65), 0, 0),
			}
		}
	}
}

-- Hit 2: High Horizontal Left Hook / Shinobi Palm Strike
ANIMATIONS["Neutral2"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(30), 0),
				Waist         = CFrame.Angles(0, math.rad(-30), 0),
				LeftShoulder  = CFrame.new(0, 0, 0.3) * CFrame.Angles(math.rad(40), math.rad(50), 0),
				LeftElbow     = CFrame.Angles(math.rad(90), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(55), math.rad(-30), 0),
			}
		},
		{
			t = 0.45, -- Hook Impact!
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, -0.4) * CFrame.Angles(0, math.rad(-42), 0),
				Waist         = CFrame.Angles(0, math.rad(40), 0),
				Neck          = CFrame.Angles(0, math.rad(12), 0),
				LeftShoulder  = CFrame.new(-0.2, 0.15, -0.7) * CFrame.Angles(math.rad(92), math.rad(-45), math.rad(35)),
				LeftElbow     = CFrame.Angles(math.rad(50), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(60), math.rad(-25), 0),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-20), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(25), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-15), 0),
				Waist         = CFrame.Angles(0, math.rad(15), 0),
				LeftShoulder  = CFrame.Angles(math.rad(45), math.rad(30), 0),
				RightShoulder = CFrame.Angles(math.rad(40), math.rad(-20), 0),
			}
		}
	}
}

-- Hit 3: High Spinning Roundhouse Kick (Body Pivot + Full Leg Extension)
ANIMATIONS["Neutral3"] = {
	duration = 0.34,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-40), 0),
				Waist         = CFrame.Angles(0, math.rad(40), 0),
				RightHip      = CFrame.Angles(math.rad(25), 0, math.rad(20)),
				RightKnee     = CFrame.Angles(math.rad(70), 0, 0),
			}
		},
		{
			t = 0.48, -- Roundhouse Whip!
			offsets = {
				RootJoint     = CFrame.new(0, 0.1, -0.3) * CFrame.Angles(math.rad(10), math.rad(75), 0),
				Waist         = CFrame.Angles(math.rad(-15), math.rad(-55), 0),
				Neck          = CFrame.Angles(0, math.rad(-30), 0),
				RightHip      = CFrame.Angles(0, math.rad(80), math.rad(75)),
				RightKnee     = CFrame.Angles(math.rad(10), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-25), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(35), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(35)),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, math.rad(-45)),
			}
		},
		{
			t = 1.0, -- Plant Foot Down
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, 0) * CFrame.Angles(0, math.rad(15), 0),
				Waist         = CFrame.Angles(0, math.rad(-15), 0),
				RightHip      = CFrame.Angles(math.rad(15), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-15), 0, 0),
			}
		}
	}
}

-- Hit 4: Heavy Twin Dragon Palms Finisher (Wall Splat / Knockdown)
ANIMATIONS["Neutral4"] = {
	duration = 0.52,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, 0.1) * CFrame.Angles(math.rad(15), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.2, 0.4) * CFrame.Angles(math.rad(-25), math.rad(-35), 0),
				LeftShoulder  = CFrame.new(0.1, -0.2, 0.4) * CFrame.Angles(math.rad(-25), math.rad(35), 0),
				RightElbow    = CFrame.Angles(math.rad(95), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(95), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-35), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(-35), 0, math.rad(-10)),
			}
		},
		{
			t = 0.50, -- Massive Twin Thrust!
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, -0.7) * CFrame.Angles(math.rad(28), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				Neck          = CFrame.Angles(math.rad(-20), 0, 0),
				RightShoulder = CFrame.new(-0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(-15), math.rad(10)),
				LeftShoulder  = CFrame.new(0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(15), math.rad(-10)),
				RightElbow    = CFrame.Angles(math.rad(12), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(12), 0, 0),
				RightHip      = CFrame.Angles(math.rad(30), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(45), 0, 0),
			}
		},
		{
			t = 0.72, -- Impact Hold (Hitstop pose)
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, -0.7) * CFrame.Angles(math.rad(28), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				RightShoulder = CFrame.new(-0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(-15), math.rad(10)),
				LeftShoulder  = CFrame.new(0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(15), math.rad(-10)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.identity,
				Waist         = CFrame.identity,
				RightShoulder = CFrame.Angles(math.rad(40), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(40), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [2] UP COMBO (Air Launcher Strings - W + J)
-- ---------------------------------------------------------
ANIMATIONS["Up1"] = {
	duration = 0.26,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(-15), math.rad(-20), 0),
				RightShoulder = CFrame.new(0, -0.2, 0.1) * CFrame.Angles(math.rad(-10), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(80), 0, 0),
			}
		},
		{
			t = 0.45, -- Rising Chin Uppercut!
			offsets = {
				RootJoint     = CFrame.new(0, 0.15, -0.2) * CFrame.Angles(math.rad(15), math.rad(25), 0),
				Waist         = CFrame.Angles(math.rad(15), math.rad(-20), 0),
				Neck          = CFrame.Angles(math.rad(15), 0, 0),
				RightShoulder = CFrame.new(0.1, 0.4, -0.5) * CFrame.Angles(math.rad(125), math.rad(-25), math.rad(15)),
				RightElbow    = CFrame.Angles(math.rad(35), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(-30), 0, math.rad(-25)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.identity,
			}
		}
	}
}

ANIMATIONS["Up2"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.Angles(0, math.rad(25), 0),
				LeftHip   = CFrame.Angles(math.rad(-20), 0, 0),
			}
		},
		{
			t = 0.46, -- Vertical Crescent Upkick!
			offsets = {
				RootJoint     = CFrame.new(0, 0.2, 0) * CFrame.Angles(math.rad(-25), math.rad(-35), 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(115), 0, math.rad(-15)),
				LeftKnee      = CFrame.Angles(math.rad(10), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(35)),
				LeftShoulder  = CFrame.Angles(math.rad(-45), 0, math.rad(-35)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

ANIMATIONS["Up3"] = {
	duration = 0.32,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(35), 0, 0),
			}
		},
		{
			t = 0.50, -- Somersault Kick Flip!
			offsets = {
				RootJoint     = CFrame.new(0, 0.5, -0.2) * CFrame.Angles(math.rad(-85), 0, 0),
				Waist         = CFrame.Angles(math.rad(30), 0, 0),
				RightHip      = CFrame.Angles(math.rad(120), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(90), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(160), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(160), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(15), 0, 0),
			}
		}
	}
}

-- Hit 4: Skyward Leaping Uppercut (Shoryu Dragon Launcher -> LiftY = +38)
ANIMATIONS["Up4"] = {
	duration = 0.55,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.5, 0.2) * CFrame.Angles(math.rad(25), math.rad(-30), 0),
				RightShoulder = CFrame.new(0, -0.4, 0.2) * CFrame.Angles(math.rad(-45), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(90), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-45), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
			}
		},
		{
			t = 0.45, -- Skyward Leaping Apex Launcher!
			offsets = {
				RootJoint     = CFrame.new(0, 1.2, -0.3) * CFrame.Angles(math.rad(-20), math.rad(25), 0),
				Waist         = CFrame.Angles(math.rad(-15), math.rad(-20), 0),
				Neck          = CFrame.Angles(math.rad(-35), 0, 0), -- Head tracking skyward!
				RightShoulder = CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(175), math.rad(-10), math.rad(15)),
				RightElbow    = CFrame.Angles(math.rad(10), 0, 0),
				LeftShoulder  = CFrame.new(0, -0.2, 0.3) * CFrame.Angles(math.rad(-55), 0, math.rad(-25)),
				LeftHip       = CFrame.Angles(math.rad(75), 0, 0), -- High knee drive
				LeftKnee      = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-20), 0, 0),
			}
		},
		{
			t = 0.70, -- Apex Freeze (Skyward Pose)
			offsets = {
				RootJoint     = CFrame.new(0, 1.2, -0.3) * CFrame.Angles(math.rad(-20), math.rad(25), 0),
				RightShoulder = CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(175), math.rad(-10), math.rad(15)),
				LeftHip       = CFrame.Angles(math.rad(75), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.identity,
			}
		}
	}
}

-- ---------------------------------------------------------
-- [3] DOWN COMBO (Ground Bounce Strings - S + J / K)
-- ---------------------------------------------------------
ANIMATIONS["Down1"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(15), 0, 0),
			}
		},
		{
			t = 0.45, -- Shin Kick!
			offsets = {
				RootJoint     = CFrame.new(0, -0.6, -0.2) * CFrame.Angles(math.rad(25), math.rad(-35), 0),
				RightHip      = CFrame.Angles(math.rad(65), math.rad(45), math.rad(30)),
				RightKnee     = CFrame.Angles(math.rad(15), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-55), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(65), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(45), 0, math.rad(30)),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, math.rad(-30)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- Down2: 360° Low Shinobi Spin Sweep
ANIMATIONS["Down2"] = {
	duration = 0.32,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(25), 0, 0),
			}
		},
		{
			t = 0.48, -- Full Low Sweep Arc!
			offsets = {
				RootJoint     = CFrame.new(0, -1.3, 0) * CFrame.Angles(math.rad(35), math.rad(-85), 0),
				Waist         = CFrame.Angles(0, math.rad(75), 0),
				RightHip      = CFrame.Angles(0, math.rad(90), math.rad(80)),
				RightKnee     = CFrame.Angles(math.rad(5), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-80), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(95), 0, 0),
				LeftShoulder  = CFrame.new(0, -0.3, -0.4) * CFrame.Angles(math.rad(75), 0, 0), -- Left hand planted on floor
				RightShoulder = CFrame.Angles(math.rad(-35), 0, math.rad(45)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.3, 0),
			}
		}
	}
}

ANIMATIONS["Down3"] = {
	duration = 0.35,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-15), 0, 0),
				RightHip  = CFrame.Angles(math.rad(110), 0, 0),
			}
		},
		{
			t = 0.52, -- Overhead Axe Heel Drop!
			offsets = {
				RootJoint     = CFrame.new(0, -0.6, -0.3) * CFrame.Angles(math.rad(45), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				RightHip      = CFrame.Angles(math.rad(45), 0, 0),
				RightKnee     = CFrame.Angles(math.rad(10), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(45)),
				LeftShoulder  = CFrame.Angles(math.rad(-45), 0, math.rad(-45)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- Down4: Heavy Meteor Ground Slam (Rebound Bounce)
ANIMATIONS["Down4"] = {
	duration = 0.54,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(-45), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(165), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(165), 0, 0),
			}
		},
		{
			t = 0.46, -- Ground Impact Crater Slam!
			offsets = {
				RootJoint     = CFrame.new(0, -1.2, -0.6) * CFrame.Angles(math.rad(55), 0, 0),
				Waist         = CFrame.Angles(math.rad(25), 0, 0),
				Neck          = CFrame.Angles(math.rad(-25), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.3, -0.8) * CFrame.Angles(math.rad(85), 0, 0),
				LeftShoulder  = CFrame.new(0.1, -0.3, -0.8) * CFrame.Angles(math.rad(85), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(25), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(25), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-55), 0, math.rad(25)),
				LeftHip       = CFrame.Angles(math.rad(-55), 0, math.rad(-25)),
				RightKnee     = CFrame.Angles(math.rad(75), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(75), 0, 0),
			}
		},
		{
			t = 0.72, -- Impact Hold
			offsets = {
				RootJoint = CFrame.new(0, -1.2, -0.6) * CFrame.Angles(math.rad(55), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [4] AIR COMBO (Mid-Air Aerial Strings)
-- ---------------------------------------------------------
ANIMATIONS["Air1"] = {
	duration = 0.26,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(math.rad(20), math.rad(-25), 0),
				RightShoulder = CFrame.Angles(math.rad(30), math.rad(-30), 0),
			}
		},
		{
			t = 0.45,
			offsets = {
				RootJoint     = CFrame.new(0, 0, -0.3) * CFrame.Angles(math.rad(25), math.rad(35), 0),
				Waist         = CFrame.Angles(0, math.rad(-35), 0),
				RightShoulder = CFrame.new(0, 0.1, -0.7) * CFrame.Angles(math.rad(95), math.rad(15), 0),
				LeftShoulder  = CFrame.Angles(math.rad(-45), 0, math.rad(-30)),
				RightHip      = CFrame.Angles(math.rad(35), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-35), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.Angles(math.rad(15), 0, 0) }
		}
	}
}

ANIMATIONS["Air2"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.Angles(0, math.rad(-60), 0),
			}
		},
		{
			t = 0.50, -- 360 Mid-Air Helicopter Spin Kick!
			offsets = {
				RootJoint     = CFrame.Angles(math.rad(15), math.rad(120), 0),
				Waist         = CFrame.Angles(0, math.rad(-30), 0),
				RightHip      = CFrame.Angles(0, math.rad(85), math.rad(70)),
				LeftHip       = CFrame.Angles(0, math.rad(-65), math.rad(-50)),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(45)),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, math.rad(-45)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.Angles(math.rad(15), 0, 0) }
		}
	}
}

ANIMATIONS["Air3"] = {
	duration = 0.52,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(-35), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(165), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(165), 0, 0),
			}
		},
		{
			t = 0.45, -- Dive Spike Crash Slam!
			offsets = {
				RootJoint     = CFrame.new(0, -0.6, -0.8) * CFrame.Angles(math.rad(75), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				RightShoulder = CFrame.new(0, 0, -0.8) * CFrame.Angles(math.rad(95), 0, 0),
				LeftShoulder  = CFrame.new(0, 0, -0.8) * CFrame.Angles(math.rad(95), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-45), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [5] STORM 4 COUNTER ATTACK (Cross-Arm Stance -> Deflection Shockwave)
-- ---------------------------------------------------------
ANIMATIONS["CounterStance"] = {
	duration = 0.38,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(15), math.rad(-20), 0),
				Waist         = CFrame.Angles(0, math.rad(20), 0),
				RightShoulder = CFrame.new(-0.25, 0.15, -0.5) * CFrame.Angles(math.rad(75), math.rad(-40), math.rad(25)),
				LeftShoulder  = CFrame.new(0.25, 0.15, -0.5) * CFrame.Angles(math.rad(75), math.rad(40), math.rad(-25)),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-20), 0, math.rad(15)),
				LeftHip       = CFrame.Angles(math.rad(15), 0, math.rad(-15)),
			}
		},
		{
			t = 0.50, -- Deflection Outward Burst!
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, -0.4) * CFrame.Angles(math.rad(10), 0, 0),
				Waist         = CFrame.Angles(math.rad(15), 0, 0),
				RightShoulder = CFrame.new(0.3, 0.2, -0.8) * CFrame.Angles(math.rad(90), math.rad(45), math.rad(-25)),
				LeftShoulder  = CFrame.new(-0.3, 0.2, -0.8) * CFrame.Angles(math.rad(90), math.rad(-45), math.rad(25)),
				RightElbow    = CFrame.Angles(math.rad(15), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(15), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [6] CHAKRA LOAD (Naruto Ram Hand Seal)
-- ---------------------------------------------------------
ANIMATIONS["ChakraLoad"] = {
	duration = 0.45,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(10), 0, 0),
				Waist         = CFrame.Angles(math.rad(10), 0, 0),
				RightShoulder = CFrame.new(-0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(-35), math.rad(15)),
				LeftShoulder  = CFrame.new(0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(35), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(-15), 0, math.rad(-10)),
			}
		},
		{
			t = 0.50, -- Pulsing Seal
			offsets = {
				RootJoint     = CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(12), 0, 0),
				Waist         = CFrame.Angles(math.rad(12), 0, 0),
				RightShoulder = CFrame.new(-0.25, -0.1, -0.4) * CFrame.Angles(math.rad(48), math.rad(-35), math.rad(15)),
				LeftShoulder  = CFrame.new(0.25, -0.1, -0.4) * CFrame.Angles(math.rad(48), math.rad(35), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(80), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(80), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(10), 0, 0),
				RightShoulder = CFrame.new(-0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(-35), math.rad(15)),
				LeftShoulder  = CFrame.new(0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(35), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [7] NINJUTSU RUSH (Rasengan / Chidori Sprint Thrust)
-- ---------------------------------------------------------
ANIMATIONS["NinjutsuRush"] = {
	duration = 0.60,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(35), math.rad(-25), 0),
				RightShoulder = CFrame.new(0, -0.2, 0.4) * CFrame.Angles(math.rad(-25), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
			}
		},
		{
			t = 0.35, -- Full Forward Sprint Thrust!
			offsets = {
				RootJoint     = CFrame.new(0, -0.45, -0.8) * CFrame.Angles(math.rad(48), 0, 0),
				Waist         = CFrame.Angles(math.rad(15), 0, 0),
				Neck          = CFrame.Angles(math.rad(-35), 0, 0),
				RightShoulder = CFrame.new(0, 0.2, -0.95) * CFrame.Angles(math.rad(95), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(10), 0, 0),
				LeftShoulder  = CFrame.new(0, 0, 0.6) * CFrame.Angles(math.rad(-65), 0, math.rad(-25)),
				RightHip      = CFrame.Angles(math.rad(-45), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(35), 0, 0),
			}
		},
		{
			t = 0.85, -- Hold thrust
			offsets = {
				RootJoint     = CFrame.new(0, -0.45, -0.8) * CFrame.Angles(math.rad(48), 0, 0),
				RightShoulder = CFrame.new(0, 0.2, -0.95) * CFrame.Angles(math.rad(95), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [8] NINJA DASH (Naruto 52° Aerodynamic Flight)
-- ---------------------------------------------------------
ANIMATIONS["NinjaDash"] = {
	duration = 0.50,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, -0.6) * CFrame.Angles(math.rad(52), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				Neck          = CFrame.Angles(math.rad(-38), 0, 0),
				RightShoulder = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(22)),
				LeftShoulder  = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(-22)),
				RightHip      = CFrame.Angles(math.rad(-25), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(25), 0, 0),
			}
		},
		{
			t = 0.5,
			offsets = {
				RootJoint     = CFrame.new(0, -0.42, -0.6) * CFrame.Angles(math.rad(55), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				Neck          = CFrame.Angles(math.rad(-40), 0, 0),
				RightShoulder = CFrame.new(0, 0, 0.55) * CFrame.Angles(math.rad(-68), 0, math.rad(24)),
				LeftShoulder  = CFrame.new(0, 0, 0.55) * CFrame.Angles(math.rad(-68), 0, math.rad(-24)),
				RightHip      = CFrame.Angles(math.rad(25), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-25), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, -0.6) * CFrame.Angles(math.rad(52), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				Neck          = CFrame.Angles(math.rad(-38), 0, 0),
				RightShoulder = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(22)),
				LeftShoulder  = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(-22)),
				RightHip      = CFrame.Angles(math.rad(-25), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(25), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [9] DEFENSE POSES (High Guard, Low Guard, Parry)
-- ---------------------------------------------------------
ANIMATIONS["HighGuard"] = {
	duration = 0.20,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-20), 0),
				Waist         = CFrame.Angles(0, math.rad(20), 0),
				RightShoulder = CFrame.new(-0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(-35), math.rad(25)),
				LeftShoulder  = CFrame.new(0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(35), math.rad(-25)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(15), 0, math.rad(-10)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-20), 0),
				Waist         = CFrame.Angles(0, math.rad(20), 0),
				RightShoulder = CFrame.new(-0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(-35), math.rad(25)),
				LeftShoulder  = CFrame.new(0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(35), math.rad(-25)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(15), 0, math.rad(-10)),
			}
		}
	}
}

ANIMATIONS["LowGuard"] = {
	duration = 0.20,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(22), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(-25), 0),
				LeftShoulder  = CFrame.new(0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(25), 0),
				RightHip      = CFrame.Angles(math.rad(-50), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-50), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(22), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(-25), 0),
				LeftShoulder  = CFrame.new(0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(25), 0),
				RightHip      = CFrame.Angles(math.rad(-50), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-50), 0, 0),
			}
		}
	}
}

ANIMATIONS["Parry"] = {
	duration = 0.30,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(35), 0),
				Waist         = CFrame.Angles(0, math.rad(-35), 0),
				RightShoulder = CFrame.new(0.2, 0.2, -0.6) * CFrame.Angles(math.rad(88), math.rad(65), math.rad(-30)),
				LeftShoulder  = CFrame.Angles(math.rad(-20), 0, math.rad(-30)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [10] HIT REACTIONS & STAGGER STUN
-- ---------------------------------------------------------
ANIMATIONS["HitHead"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, 0, 0.2) * CFrame.Angles(math.rad(-25), math.rad(-10), 0),
				Waist         = CFrame.Angles(math.rad(-15), 0, 0),
				Neck          = CFrame.Angles(math.rad(-35), math.rad(-15), 0), -- Head snaps back
				RightShoulder = CFrame.Angles(math.rad(-35), 0, math.rad(35)),
				LeftShoulder  = CFrame.Angles(math.rad(-35), 0, math.rad(-35)),
			}
		},
		{
			t = 0.6,
			offsets = {
				RootJoint = CFrame.new(0, 0, 0.1) * CFrame.Angles(math.rad(-10), 0, 0),
				Neck      = CFrame.Angles(math.rad(-15), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

ANIMATIONS["HitGut"] = {
	duration = 0.30,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0.1) * CFrame.Angles(math.rad(35), 0, 0),
				Waist         = CFrame.Angles(math.rad(25), 0, 0),
				Neck          = CFrame.Angles(math.rad(-15), 0, 0),
				RightShoulder = CFrame.new(0, -0.1, -0.2) * CFrame.Angles(math.rad(35), math.rad(-25), 0),
				LeftShoulder  = CFrame.new(0, -0.1, -0.2) * CFrame.Angles(math.rad(35), math.rad(25), 0),
				RightHip      = CFrame.Angles(math.rad(-30), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-30), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- Stagger Stun (When parried / countered - dizzy wobble)
ANIMATIONS["StaggerStun"] = {
	duration = 1.30,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(10), math.rad(15), math.rad(8)),
				Neck          = CFrame.Angles(math.rad(15), math.rad(-10), math.rad(-12)),
				RightShoulder = CFrame.Angles(math.rad(10), 0, math.rad(15)),
				LeftShoulder  = CFrame.Angles(math.rad(10), 0, math.rad(-15)),
			}
		},
		{
			t = 0.5,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(12), math.rad(-15), math.rad(-8)),
				Neck          = CFrame.Angles(math.rad(15), math.rad(10), math.rad(12)),
				RightShoulder = CFrame.Angles(math.rad(5), 0, math.rad(20)),
				LeftShoulder  = CFrame.Angles(math.rad(5), 0, math.rad(-20)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(10), math.rad(15), math.rad(8)),
				Neck          = CFrame.Angles(math.rad(15), math.rad(-10), math.rad(-12)),
			}
		}
	}
}

-- Backward compatibility aliases
ANIMATIONS["Attack1"] = ANIMATIONS["Neutral1"]
ANIMATIONS["Attack2"] = ANIMATIONS["Neutral2"]
ANIMATIONS["Attack3"] = ANIMATIONS["Neutral3"]
ANIMATIONS["Attack4"] = ANIMATIONS["Neutral4"]
ANIMATIONS["LowSweep"] = ANIMATIONS["Down2"]
ANIMATIONS["ChakraCharge"] = ANIMATIONS["ChakraLoad"]
ANIMATIONS["Hit"] = ANIMATIONS["HitGut"]
ANIMATIONS["Stagger"] = ANIMATIONS["StaggerStun"]
ANIMATIONS["Block"] = ANIMATIONS["HighGuard"]
ANIMATIONS["Guard"] = ANIMATIONS["HighGuard"]

-- =========================================================
-- ANIMATION PLAYBACK & INTERPOLATION ENGINE
-- =========================================================
triggerCombatAnimation = function(animName: string, durationOverride: number?)
	local seq = ANIMATIONS[animName]
	if not seq then
		print(string.format(">> [StormAnimation] Unknown anim: %s, falling back to Idle <<", animName))
		seq = ANIMATIONS["Idle"]
		animName = "Idle"
	end

	currentAnimName = animName
	currentSequence = seq
	animStartTime = os.clock()
	animDuration = durationOverride or seq.duration
	isLooping = seq.loop == true

	-- Weapon trail
	if katanaTrail then
		local isAttack = string.sub(animName, 1, 7) == "Neutral"
			or string.sub(animName, 1, 2) == "Up"
			or string.sub(animName, 1, 4) == "Down"
			or string.sub(animName, 1, 3) == "Air"
			or animName == "NinjaDash"
			or animName == "NinjutsuRush"
		katanaTrail.Enabled = isAttack
	end
end

-- Remote & Bindable Listeners
local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
if not evAnim then
	evAnim = Instance.new("BindableEvent")
	evAnim.Name = "StormCombatAnimationEvent"
	evAnim.Parent = ReplicatedStorage
end
evAnim.Event:Connect(triggerCombatAnimation)

-- =========================================================
-- RENDER STEP: JOINT INTERPOLATION & MOTOR6D APPLICATION
-- =========================================================
local function evaluateKeyframeOffsets(seq: AnimationSequence, progress: number): JointOffsets
	local keyframes = seq.keyframes
	if #keyframes == 1 then
		return keyframes[1].offsets
	end

	-- Find surrounding keyframes
	local kfA = keyframes[1]
	local kfB = keyframes[#keyframes]

	for i = 1, #keyframes - 1 do
		if progress >= keyframes[i].t and progress <= keyframes[i + 1].t then
			kfA = keyframes[i]
			kfB = keyframes[i + 1]
			break
		end
	end

	local span = kfB.t - kfA.t
	local alpha = if span > 0.0001 then math.clamp((progress - kfA.t) / span, 0, 1) else 0
	local easedAlpha = snapEase(alpha)

	-- Interpolate all joints in kfB
	local interpolated: JointOffsets = {}
	for jointName, cfB in pairs(kfB.offsets) do
		local cfA = kfA.offsets[jointName] or CFrame.identity
		interpolated[jointName] = cfA:Lerp(cfB, easedAlpha)
	end

	-- Copy any joints present in kfA but missing in kfB
	for jointName, cfA in pairs(kfA.offsets) do
		if not interpolated[jointName] then
			interpolated[jointName] = cfA
		end
	end

	return interpolated
end

local function onRenderStep(dt: number)
	local now = os.clock()
	local elapsed = now - animStartTime
	local seq = currentSequence or ANIMATIONS["Idle"]

	-- Progress calculation
	local progress = 0
	if isLooping then
		progress = (elapsed % animDuration) / animDuration
	else
		progress = math.clamp(elapsed / animDuration, 0, 1)
		-- Check completion of non-looping animation
		if progress >= 1.0 and currentAnimName ~= "Idle" then
			-- Evaluate player attributes for next state
			local isBlocking = LocalPlayer:GetAttribute("IsBlocking") == true
			local blockType = tostring(LocalPlayer:GetAttribute("BlockType") or "None")
			local isDashing = LocalPlayer:GetAttribute("IsNinjaDashing") == true
			local isCharging = LocalPlayer:GetAttribute("IsChakraCharging") == true
			local isCountering = LocalPlayer:GetAttribute("IsCountering") == true

			if isCountering then
				triggerCombatAnimation("CounterStance", 0.35)
			elseif isCharging then
				triggerCombatAnimation("ChakraLoad", 0.45)
			elseif isBlocking then
				triggerCombatAnimation(if blockType == "Low" then "LowGuard" else "HighGuard", 0.20)
			elseif isDashing then
				triggerCombatAnimation("NinjaDash", 0.50)
			else
				triggerCombatAnimation("Idle", 1.8)
				if katanaTrail then katanaTrail.Enabled = false end
			end
			seq = currentSequence or ANIMATIONS["Idle"]
			progress = 0
		end
	end

	-- Evaluate offsets from sequence
	local offsets = evaluateKeyframeOffsets(seq, progress)

	-- Apply offsets to cached joints (AnimationConstraint & Motor6D compatible)
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local isMoving = hum and hum.MoveDirection.Magnitude > 0.1

	for jointName, joint in pairs(joints) do
		if joint then
			local off = offsets[jointName]

			-- Shinobi Run blend: if Idle and character is running, perform Naruto Ninja Run!
			if currentAnimName == "Idle" and isMoving then
				if jointName == "RootJoint" then
					off = CFrame.Angles(math.rad(28), 0, 0)
				elseif jointName == "Waist" then
					off = CFrame.Angles(math.rad(8), 0, 0)
				elseif jointName == "Neck" then
					off = CFrame.Angles(math.rad(-22), 0, 0)
				elseif jointName == "RightShoulder" then
					off = CFrame.Angles(math.rad(-65), math.rad(-10), math.rad(-15))
				elseif jointName == "LeftShoulder" then
					off = CFrame.Angles(math.rad(-65), math.rad(10), math.rad(15))
				elseif jointName == "RightElbow" then
					off = CFrame.Angles(math.rad(18), 0, 0)
				elseif jointName == "LeftElbow" then
					off = CFrame.Angles(math.rad(18), 0, 0)
				elseif jointName:find("Hip") or jointName:find("Knee") or jointName:find("Ankle") then
					-- Let default Roblox walk/run animation cycle legs naturally!
					off = nil
				end
			end

			if off then
				if joint:IsA("AnimationConstraint") then
					(joint :: AnimationConstraint).Transform = off
				elseif joint:IsA("Motor6D") then
					local m = joint :: Motor6D
					local base = baseC0[jointName]
					if base then
						m.C0 = base * off
					else
						m.Transform = off
					end
				end
			end
		end
	end
end

RunService:BindToRenderStep("StormProceduralAnim", Enum.RenderPriority.Character.Value + 1, onRenderStep)

print("[StormAnimationController] ✅ Master Procedural Anime Animation Engine active — 60FPS Multi-Keyframe Sequencer with Hermite Smoothstep ready.")
]=====]
    install('StormAnimationController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

return 'Batch 4 OK (3 scripts)'