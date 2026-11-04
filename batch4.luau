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
-- INPUT LISTENERS: [I] Mengisi Energi / Hold untuk Ultimate
-- =========================================================
local isHoldingI = false
local iPressStartTime = 0

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- Primary Key: [I] (Naruto Storm: Energy Charge & Hold for Ultimate)
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
					executeUltimateJutsu()
					break
				end
			end
		end)

	-- Secondary/Fallback keys
	elseif input.KeyCode == Enum.KeyCode.O then
		executeUltimateJutsu()
	elseif input.KeyCode == Enum.KeyCode.C then
		startChakraCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.I then
		isHoldingI = false
		stopChakraCharge()
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

print("[StormUltimateController] ✅ Ultimate Secret Technique & Tekken Awakening active — [I] Charge / Hold for Ultimate.")
]=====]
    install('StormUltimateController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
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
    install('StormAssistController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
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

]=====]
    install('StormAnimationController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

return 'Batch 4 OK (3 scripts)'