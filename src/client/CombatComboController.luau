--!strict
-- CombatComboController.luau
-- CLIENT SCRIPT: Naruto x Boruto Ultimate Ninja Storm Connections Combat Engine
-- Features:
--   • Ultra-Responsive Input Buffering (0.32s Window) for Butter-Smooth Mashing
--   • Multi-Frame Active Hitbox Window (Heartbeat scanning during strike snap)
--   • Smooth Slerp Auto-Face & Magnetic Glide Tracking (No instant teleport rotation)
--   • Hit-Confirmation Early Canceling (Next combo hit triggers the millisecond a strike connects)
--   • Storm Connections Directional Combos:
--       [J]: Neutral Combo (4-Hit Flurry -> Heavy Knockdown Blast)
--       [W + J]: Up Combo (4-Hit Launcher -> Launches Opponent 50+ studs into the sky!)
--       [S + J] / [K]: Down Combo (4-Hit Low String -> Ground Slam & Ground Bounce OTG)
--       [Air + J]: Air Combo (3-Hit Aerial Dogfight -> Meteor Dive Spike)
--   • Air Chase System:
--       When an opponent is launched into the air, pressing Dash or Attack triggers
--       a supersonic sonic-boom Air Chase straight to their airborne position!
--   • Chakra Dash Cancel (CDC - Infinite Combo Loop Engine):
--       Cancel attack recovery at ANY millisecond by pressing Dash (consumes 15 Chakra),
--       instantly homing back into the enemy to reset combo strings!
--   • CyberConnect2 Impact Juice:
--       Two-Way Micro Hitstop (0.06s freeze) + Directional Slashes + Radial Sparks + Dutch Angle Shake!
--   • Storm 4 Counter Stance ([Guard + Attack] / [F + J]):
--       Deflects rushing strikes and blows attackers flying across the arena.

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
local COMBO_RESET_TIME = 0.65 -- Snappy reset window matching Storm 4
local CHAKRA_CDC_COST = 15
local BUFFER_WINDOW = 0.32 -- 320ms input buffer window for seamless combo mashing

-- State Variables
local currentComboIndex = 0
local currentBranch = "Neutral" -- "Neutral" | "Up" | "Down" | "Air"
local lastAttackTime = 0
local isAttacking = false
local canChainNext = false -- Opens early on hit confirmation!
local isStaggered = false
local isAirChasing = false
local lastCounterTime = 0

-- Input Buffer Structure
type BufferedAction = {
	action: string, -- "Attack" | "Low"
	forceLow: boolean,
	timestamp: number,
}
local bufferedInput: BufferedAction? = nil

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evAttack    = combatEvents:WaitForChild("AttackEvent") :: RemoteEvent
local evParry     = combatEvents:WaitForChild("ParryEvent") :: RemoteEvent
local evCounter   = combatEvents:WaitForChild("CounterEvent") :: RemoteEvent
local evNinjaDash = combatEvents:WaitForChild("NinjaDashEvent") :: RemoteEvent

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
local evMobileDash    = getOrMakeBindable("MobileDashAction")
local evCDC           = getOrMakeBindable("ChakraDashCancelAction")
local evAnim          = getOrMakeBindable("StormCombatAnimationEvent")
local evCamImpact     = getOrMakeBindable("StormCameraImpactEvent")

-- Universal High-Quality Audio Engine (Meaty Crunchy Anime Impacts)
local SOUND_SNAP    = "rbxasset://sounds/sword_hit.wav"
local SOUND_THUMP   = "rbxasset://sounds/splat.wav"
local SOUND_HEAVY   = "rbxasset://sounds/impact_explosion_03.mp3"
local SOUND_SWISH   = "rbxasset://sounds/action_swish.mp3"
local SOUND_CLANG   = "rbxasset://sounds/sword_slash.wav"
local SOUND_SHATTER = "rbxasset://sounds/shattered.mp3"

local function playSafeSound(soundId: string, parent: Instance, pitch: number, volume: number)
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId
		snd.PlaybackSpeed = pitch
		snd.Volume = volume
		snd.Parent = parent
		snd:Play()
		task.delay(0.6, function() pcall(function() snd:Destroy() end) end)
	end)
end

-- =========================================================
-- FLOATING 3D DAMAGE POPUPS (TSB / Anime Battlegrounds Style)
-- =========================================================
local function spawnDamagePopup(worldPos: Vector3, damageNum: number, isHeavy: boolean, attackType: string)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	local spreadX = (math.random() - 0.5) * 2.2
	local spreadZ = (math.random() - 0.5) * 2.2
	part.Position = worldPos + Vector3.new(spreadX, 2.8, spreadZ)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = isHeavy and UDim2.new(0, 200, 0, 70) or UDim2.new(0, 150, 0, 50)
	bb.AlwaysOnTop = true
	bb.Parent = part

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextColor3 = isHeavy and Color3.fromRGB(255, 65, 30) or Color3.fromRGB(255, 230, 60)
	lbl.Text = isHeavy and string.format("🔥 %d CRIT!", damageNum) or string.format("💥 %d", damageNum)
	lbl.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = isHeavy and 3 or 2
	stroke.Parent = lbl

	-- Pop & Float Up Tween
	local targetPos = part.Position + Vector3.new(0, isHeavy and 4.2 or 3.0, 0)
	TweenService:Create(part, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPos,
	}):Play()

	task.delay(0.4, function()
		TweenService:Create(lbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
		}):Play()
	end)
	Debris:AddItem(part, 0.75)
end

-- =========================================================
-- DYNAMIC SCREEN COMBO COUNTER UI
-- =========================================================
local comboHits = 0
local lastComboHitTime = 0

local comboGui = Instance.new("ScreenGui")
comboGui.Name = "StormComboDisplayHUD"
comboGui.ResetOnSpawn = false
comboGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local comboFrame = Instance.new("Frame")
comboFrame.Name = "ComboFrame"
comboFrame.Size = UDim2.new(0, 240, 0, 85)
comboFrame.Position = UDim2.new(0.08, 0, 0.42, 0)
comboFrame.BackgroundTransparency = 1
comboFrame.Visible = false
comboFrame.Parent = comboGui

local comboHitsLabel = Instance.new("TextLabel")
comboHitsLabel.Name = "ComboHits"
comboHitsLabel.Size = UDim2.new(1, 0, 0.65, 0)
comboHitsLabel.BackgroundTransparency = 1
comboHitsLabel.Font = Enum.Font.GothamBlack
comboHitsLabel.TextSize = 46
comboHitsLabel.TextColor3 = Color3.fromRGB(255, 230, 40)
comboHitsLabel.TextXAlignment = Enum.TextXAlignment.Left
comboHitsLabel.Text = "4 HITS"
comboHitsLabel.Parent = comboFrame

local hitsStroke = Instance.new("UIStroke")
hitsStroke.Color = Color3.fromRGB(20, 20, 20)
hitsStroke.Thickness = 3
hitsStroke.Parent = comboHitsLabel

local comboSubLabel = Instance.new("TextLabel")
comboSubLabel.Name = "ComboSub"
comboSubLabel.Size = UDim2.new(1, 0, 0.35, 0)
comboSubLabel.Position = UDim2.new(0, 0, 0.65, 0)
comboSubLabel.BackgroundTransparency = 1
comboSubLabel.Font = Enum.Font.GothamBold
comboSubLabel.TextSize = 18
comboSubLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
comboSubLabel.TextXAlignment = Enum.TextXAlignment.Left
comboSubLabel.Text = "★ SHINOBI RUSH ★"
comboSubLabel.Parent = comboFrame

local function registerComboHit()
	comboHits += 1
	lastComboHitTime = os.clock()
	comboFrame.Visible = true

	local color = Color3.fromRGB(255, 230, 40)
	local subText = "★ SHINOBI RUSH ★"
	if comboHits >= 8 then
		color = Color3.fromRGB(255, 40, 40)
		subText = "⚡ ULTRA STORM FINISHER! ⚡"
	elseif comboHits >= 4 then
		color = Color3.fromRGB(255, 140, 20)
		subText = "🔥 HEAVY COMBO! 🔥"
	end

	comboHitsLabel.Text = string.format("%d HITS", comboHits)
	comboHitsLabel.TextColor3 = color
	comboSubLabel.Text = subText

	comboHitsLabel.TextSize = 56
	TweenService:Create(comboHitsLabel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 46,
	}):Play()
end

task.spawn(function()
	while true do
		task.wait(0.2)
		if comboHits > 0 and (os.clock() - lastComboHitTime > 2.2) then
			comboHits = 0
			TweenService:Create(comboHitsLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
			}):Play()
			task.delay(0.35, function()
				if comboHits == 0 then
					comboFrame.Visible = false
					comboHitsLabel.TextTransparency = 0
				end
			end)
		end
	end
end)

-- =========================================================
-- DESTRUCTIBLE GROUND CRATER & PHYSICS DEBRIS (TSB / JJS)
-- =========================================================
local function spawnGroundCrater(pos: Vector3, isMassive: boolean)
	task.spawn(function()
		local crater = Instance.new("Part")
		crater.Name = "ImpactCrater"
		crater.Shape = Enum.PartType.Cylinder
		crater.Size = Vector3.new(0.15, isMassive and 14 or 8, isMassive and 14 or 8)
		crater.CFrame = CFrame.new(pos.X, 2.05, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		crater.Material = Enum.Material.Slate
		crater.Color = Color3.fromRGB(45, 45, 50)
		crater.Anchored = true
		crater.CanCollide = false
		crater.Parent = Workspace

		local debrisCount = isMassive and 8 or 5
		for i = 1, debrisCount do
			local rock = Instance.new("Part")
			rock.Name = "RockDebris"
			local s = math.random(8, 16) / 10
			rock.Size = Vector3.new(s, s, s)
			rock.Position = pos + Vector3.new(math.random(-2, 2), 0.5, math.random(-2, 2))
			rock.Material = Enum.Material.Cobblestone
			rock.Color = Color3.fromRGB(80, 78, 85)
			rock.Anchored = false
			rock.CanCollide = true
			rock.Parent = Workspace

			local randAngle = math.rad(math.random(0, 360))
			local forceDir = Vector3.new(math.cos(randAngle), math.random(12, 22) / 10, math.sin(randAngle)).Unit
			rock.AssemblyLinearVelocity = forceDir * math.random(25, 48)
			rock.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))

			Debris:AddItem(rock, 2.2)
		end

		task.delay(3.5, function()
			local tw = TweenService:Create(crater, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
			})
			tw:Play()
			tw.Completed:Connect(function() crater:Destroy() end)
		end)
	end)
end

-- =========================================================
-- AWAKENING PROGRESS METER ENGINE ([G] KEY)
-- =========================================================
local evAwakening = combatEvents:WaitForChild("AwakeningEvent", 5) :: RemoteEvent?
if not evAwakening then
	evAwakening = Instance.new("RemoteEvent")
	evAwakening.Name = "AwakeningEvent"
	evAwakening.Parent = combatEvents
end
local evPostHit = combatEvents:WaitForChild("TrainingPostHitEvent", 5) :: RemoteEvent?
if not evPostHit then
	evPostHit = Instance.new("RemoteEvent")
	evPostHit.Name = "TrainingPostHitEvent"
	evPostHit.Parent = combatEvents
end

local awakeningProgress = 0
local isAwakeningActive = false

local awkGui = Instance.new("ScreenGui")
awkGui.Name = "StormAwakeningHUD"
awkGui.ResetOnSpawn = false
awkGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local awkFrame = Instance.new("Frame")
awkFrame.Name = "AwakeningMeterFrame"
awkFrame.Size = UDim2.new(0, 260, 0, 32)
awkFrame.Position = UDim2.new(0.5, 0, 1, -48)
awkFrame.AnchorPoint = Vector2.new(0.5, 1)
awkFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
awkFrame.BackgroundTransparency = 0.2
awkFrame.Parent = awkGui
Instance.new("UICorner", awkFrame).CornerRadius = UDim.new(0, 6)

local awkStroke = Instance.new("UIStroke")
awkStroke.Color = Color3.fromRGB(60, 65, 80)
awkStroke.Thickness = 2
awkStroke.Parent = awkFrame

local awkFill = Instance.new("Frame")
awkFill.Name = "Fill"
awkFill.Size = UDim2.new(0, 0, 1, 0)
awkFill.BackgroundColor3 = Color3.fromRGB(255, 60, 20)
awkFill.BorderSizePixel = 0
awkFill.Parent = awkFrame
Instance.new("UICorner", awkFill).CornerRadius = UDim.new(0, 6)

local awkLabel = Instance.new("TextLabel")
awkLabel.Name = "Label"
awkLabel.Size = UDim2.fromScale(1, 1)
awkLabel.BackgroundTransparency = 1
awkLabel.Font = Enum.Font.GothamBlack
awkLabel.TextSize = 13
awkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
awkLabel.Text = "AWAKENING [G] : 0%"
awkLabel.Parent = awkFrame

local function updateAwakeningHUD()
	local ratio = math.clamp(awakeningProgress / 100, 0, 1)
	TweenService:Create(awkFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0),
	}):Play()

	if isAwakeningActive then
		awkLabel.Text = "⚡ AWAKENING ACTIVE! ⚡"
		awkLabel.TextColor3 = Color3.fromRGB(255, 240, 120)
		awkStroke.Color = Color3.fromRGB(255, 40, 40)
	elseif awakeningProgress >= 100 then
		awkLabel.Text = "🔥 PRESS [G] TO AWAKEN! 🔥"
		awkLabel.TextColor3 = Color3.fromRGB(255, 230, 40)
		awkStroke.Color = Color3.fromRGB(255, 215, 0)
	else
		awkLabel.Text = string.format("AWAKENING [G] : %d%%", math.floor(awakeningProgress))
		awkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		awkStroke.Color = Color3.fromRGB(60, 65, 80)
	end
end

local function addAwakeningCharge(amount: number)
	if isAwakeningActive then return end
	awakeningProgress = math.clamp(awakeningProgress + amount, 0, 100)
	updateAwakeningHUD()
end

local function triggerClientAwakening()
	if isAwakeningActive or awakeningProgress < 100 then return end
	isAwakeningActive = true
	awakeningProgress = 0
	updateAwakeningHUD()

	if evAwakening then
		evAwakening:FireServer()
	end

	screenShake(0.65, 0.5, 5.0)
	playSafeSound(SOUND_HEAVY, Camera, 0.9, 1.0)

	task.delay(22, function()
		isAwakeningActive = false
		updateAwakeningHUD()
	end)
end

-- Click to trigger on mobile / PC
local awkBtn = Instance.new("TextButton")
awkBtn.Size = UDim2.fromScale(1, 1)
awkBtn.BackgroundTransparency = 1
awkBtn.Text = ""
awkBtn.Parent = awkFrame
awkBtn.MouseButton1Click:Connect(triggerClientAwakening)

-- Hook taking damage to charge Awakening
task.spawn(function()
	local function hookHumanoid(hum: Humanoid)
		local lastHp = hum.Health
		hum.HealthChanged:Connect(function(newHp)
			if newHp < lastHp and newHp > 0 then
				addAwakeningCharge(12)
			end
			lastHp = newHp
		end)
	end
	if LocalPlayer.Character then
		local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h then hookHumanoid(h) end
	end
	LocalPlayer.CharacterAdded:Connect(function(char)
		local h = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if h then hookHumanoid(h) end
	end)
end)

-- =========================================================
-- CYBERCONNECT2 IMPACT JUICE: HITSTOP & DIRECTIONAL FX
-- =========================================================
local function screenShake(intensity: number, duration: number, tiltRoll: number?)
	task.spawn(function()
		local startTime = os.clock()
		local roll = tiltRoll or (math.random(-1, 1) * 1.5)
		while os.clock() - startTime < duration do
			local alpha = 1 - ((os.clock() - startTime) / duration)
			local offset = Vector3.new(
				(math.random() - 0.5) * intensity * alpha,
				(math.random() - 0.5) * intensity * alpha,
				(math.random() - 0.5) * intensity * alpha
			)
			Camera.CFrame = Camera.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(roll * alpha))
			RunService.RenderStepped:Wait()
		end
	end)
end

local function triggerHitstop(duration: number, attackerRoot: BasePart, targetRoot: BasePart?)
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")

	-- Micro freeze velocities for authentic crunchy fighting game impact
	local origAttackerVel = attackerRoot.AssemblyLinearVelocity
	attackerRoot.AssemblyLinearVelocity = Vector3.zero
	if targetRoot then
		targetRoot.AssemblyLinearVelocity = Vector3.zero
	end

	if hum then
		local origSpeed = hum.WalkSpeed
		hum.WalkSpeed = 0
		task.delay(duration, function()
			if hum then hum.WalkSpeed = origSpeed end
			if attackerRoot and attackerRoot.Parent then
				attackerRoot.AssemblyLinearVelocity = origAttackerVel * 0.35
			end
		end)
	end
end

-- Visual Impact Slashing FX & Radial Shockwave
local function playAttackFX(root: BasePart, isHeavy: boolean, branch: string, index: number, targetPos: Vector3?)
	local impactPos = targetPos or (root.Position + root.CFrame.LookVector * 3.5 + Vector3.new(0, 0.4, 0))

	-- 1. Directional Comic Slash Ribbon Part
	local fxPart = Instance.new("Part")
	fxPart.Size = Vector3.new(isHeavy and 5.5 or 4.0, isHeavy and 5.5 or 4.0, 0.15)
	local slashAngle = math.rad(index % 2 == 0 and 45 or -45)
	fxPart.CFrame = CFrame.new(impactPos) * CFrame.Angles(0, root.Orientation.Y, slashAngle)
	fxPart.Material = Enum.Material.Neon

	local fxColor = Color3.fromRGB(0, 240, 255)
	if isHeavy then
		fxColor = Color3.fromRGB(255, 110, 30)
	elseif branch == "Up" then
		fxColor = Color3.fromRGB(190, 110, 255)
	elseif branch == "Down" then
		fxColor = Color3.fromRGB(255, 210, 40)
	elseif branch == "Air" then
		fxColor = Color3.fromRGB(0, 255, 180)
	end

	fxPart.Color = fxColor
	fxPart.Transparency = 0.15
	fxPart.Anchored = true
	fxPart.CanCollide = false
	fxPart.Parent = Workspace

	local tween = TweenService:Create(fxPart, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = fxPart.Size * 1.6,
	})
	tween:Play()
	tween.Completed:Connect(function() fxPart:Destroy() end)

	-- 2. Radial Spark Particles
	local sparkPart = Instance.new("Part")
	sparkPart.Size = Vector3.new(0.5, 0.5, 0.5)
	sparkPart.CFrame = CFrame.new(impactPos)
	sparkPart.Transparency = 1
	sparkPart.Anchored = true
	sparkPart.CanCollide = false
	sparkPart.Parent = Workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(fxColor, Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(2.2, 0)
	pe.Rate = 0
	pe.Speed = NumberRange.new(14, 32)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.22, 0.40)
	pe.Parent = sparkPart

	pe:Emit(isHeavy and 32 or 20)
	Debris:AddItem(sparkPart, 0.45)

	-- 3. Expanding Shockwave Ring on Heavy Hits
	if isHeavy then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.2, 2.5, 2.5)
		ring.CFrame = CFrame.new(impactPos) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = fxColor
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.25
		ring.Anchored = true
		ring.CanCollide = false
		ring.Parent = Workspace

		TweenService:Create(ring, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.2, 11, 11),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, 0.24)
	end

	-- Meaty Anime Audio & Ground Destruction
	if isHeavy then
		playSafeSound(SOUND_HEAVY, root, 1.0, 1.0)
		playSafeSound(SOUND_SHATTER, root, 1.15, 0.8)
		if branch == "Down" or branch == "Air" then
			spawnGroundCrater(impactPos, true)
		end
	else
		playSafeSound(SOUND_SNAP, root, 1.15 + (index * 0.1), 0.95)
		playSafeSound(SOUND_THUMP, root, 0.88, 0.75)
		if branch == "Down" then
			playSafeSound(SOUND_SWISH, root, 0.85, 0.9)
		end
	end
end

-- =========================================================
-- HIT DETECTION & TARGET ACQUISITION
-- =========================================================
local function findHitTarget(myRoot: BasePart): Model?
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	if LocalPlayer.Character then
		overlap.FilterDescendantsInstances = { LocalPlayer.Character }
	end

	-- Generous 3D active hitbox volume (7w x 7h x 9.5d)
	local hitBoxCFrame = myRoot.CFrame * CFrame.new(0, 0, -4.5)
	local hitParts = Workspace:GetPartBoundsInBox(hitBoxCFrame, Vector3.new(7.0, 7.0, 9.5), overlap)

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

local function checkHitTrainingPost(myRoot: BasePart): BasePart?
	local hitBoxCFrame = myRoot.CFrame * CFrame.new(0, 0, -4.5)
	local arena = Workspace:FindFirstChild("StormClashArena")
	if not arena then return nil end
	for _, child in ipairs(arena:GetChildren()) do
		if child.Name:find("TrainingPost") and child:IsA("BasePart") then
			if (child.Position - hitBoxCFrame.Position).Magnitude <= 8.5 then
				return child
			end
		end
	end
	return nil
end

local function getLockedTarget(myRoot: BasePart): Model?
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") and dummy:FindFirstChild("HumanoidRootPart") then
		local dRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
		if (dRoot.Position - myRoot.Position).Magnitude <= 55 then
			return dummy
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local root = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				if (root.Position - myRoot.Position).Magnitude <= 55 then
					return p.Character
				end
			end
		end
	end
	return nil
end

-- Smooth Slerp Orient toward Target (over 0.08s, no jarring snap)
local function smoothFaceTarget(myRoot: BasePart, target: Model?)
	if not target then return end
	local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not tRoot then return end

	local flatTargetPos = Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
	local desiredCFrame = CFrame.lookAt(myRoot.Position, flatTargetPos)

	task.spawn(function()
		local startTime = os.clock()
		while os.clock() - startTime < 0.08 do
			local alpha = math.clamp((os.clock() - startTime) / 0.08, 0, 1)
			if myRoot and myRoot.Parent then
				myRoot.CFrame = myRoot.CFrame:Lerp(desiredCFrame, alpha * 0.7)
			end
			RunService.Heartbeat:Wait()
		end
		if myRoot and myRoot.Parent then
			myRoot.CFrame = desiredCFrame
		end
	end)
end

-- Forward declaration of executeAttack
local executeAttack: (forceLow: boolean?) -> ()

-- Check and Consume Buffered Input
local function tryConsumeBufferedInput()
	if bufferedInput then
		local now = os.clock()
		if now - bufferedInput.timestamp <= BUFFER_WINDOW then
			local b = bufferedInput
			bufferedInput = nil
			executeAttack(b.forceLow)
			return true
		else
			bufferedInput = nil
		end
	end
	return false
end

-- =========================================================
-- STORM 4 COUNTER ATTACK ([Guard + Attack] / [F + J])
-- =========================================================
local function triggerCounterAttack(root: BasePart)
	local now = os.clock()
	if now - lastCounterTime < 3.0 then
		return
	end
	lastCounterTime = now

	print(">> [Storm 4 Counter] Stance activated! Deflecting incoming strikes! <<")
	evCounter:FireServer(true)
	evAnim:Fire("CounterStance", 0.38)

	-- Visual Counter Flash Shield
	local counterPart = Instance.new("Part")
	counterPart.Shape = Enum.PartType.Ball
	counterPart.Size = Vector3.new(5.5, 5.5, 5.5)
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
	pe.Size = NumberSequence.new(2.0, 0)
	pe.Rate = 100
	pe.Speed = NumberRange.new(10, 24)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Parent = att

	TweenService:Create(counterPart, TweenInfo.new(0.35), { Size = Vector3.new(8.0, 8.0, 8.0), Transparency = 1 }):Play()
	Debris:AddItem(counterPart, 0.40)

	playSafeSound(SOUND_HEAVY, root, 1.6, 1.0)

	task.delay(0.35, function()
		evCounter:FireServer(false)
	end)
end

-- =========================================================
-- AIR CHASE SYSTEM (Signature Storm Connections Mechanic)
-- =========================================================
local function triggerAirChase(myRoot: BasePart, target: Model)
	if isAirChasing then return end
	local tRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not tRoot then return end

	isAirChasing = true
	isAttacking = true
	canChainNext = false
	currentBranch = "Air"
	currentComboIndex = 0

	print(">> [AIR CHASE] Supersonic Leap toward launched opponent! <<")
	playSafeSound("rbxasset://sounds/action_jump.mp3", myRoot, 1.85, 1.0)
	playSafeSound(SOUND_HEAVY, myRoot, 1.4, 0.8)

	-- Sonic Boom burst
	local burstAtt = Instance.new("Attachment", myRoot)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(2.5, 0)
	pe.Rate = 90
	pe.Speed = NumberRange.new(16, 34)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Parent = burstAtt
	pe:Emit(40)

	-- Notify Camera of Air Chase & Launcher Tracking
	evCamImpact:Fire("AirChase", 0.6)
	evAnim:Fire("NinjaDash", 0.5)

	local startTime = os.clock()
	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		if not target.Parent or not tRoot or elapsed > 0.65 or not isAirChasing then
			if conn then conn:Disconnect() end
			isAirChasing = false
			isAttacking = false
			burstAtt:Destroy()
			return
		end

		local targetAirPos = tRoot.Position + Vector3.new(0, 0.5, 0)
		local dir = (targetAirPos - myRoot.Position)
		local dist = dir.Magnitude

		if dist <= 5.5 then
			-- Arrived at target in mid-air! Seamlessly transition into Air Combo 1!
			if conn then conn:Disconnect() end
			isAirChasing = false
			isAttacking = false
			burstAtt:Destroy()
			myRoot.AssemblyLinearVelocity = Vector3.new(0, 4, 0) -- Hover briefly for air string

			task.spawn(function()
				executeAttack(false)
			end)
		else
			-- Rocket straight toward airborne target at 105 studs/s
			local moveVel = dir.Unit * 105
			myRoot.AssemblyLinearVelocity = moveVel
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, targetAirPos)
		end
	end)
end

-- =========================================================
-- CHAKRA DASH CANCEL (CDC) - Storm Connections Endless Strings!
-- =========================================================
local function triggerChakraDashCancel(myRoot: BasePart)
	local curChakra = LocalPlayer:GetAttribute("ChakraValue") or 60
	if curChakra < CHAKRA_CDC_COST then
		print(">> [CDC] Not enough Chakra for cancel! Need 15. <<")
		return false
	end

	-- Deduct Chakra
	LocalPlayer:SetAttribute("ChakraValue", curChakra - CHAKRA_CDC_COST)

	-- Immediately reset attack recovery, buffered input & combo step
	isAttacking = false
	canChainNext = false
	currentComboIndex = 0
	isAirChasing = false
	bufferedInput = nil

	print(">> [CHAKRA DASH CANCEL] Recovery cancelled into Supersonic Dash! <<")
	playSafeSound(SOUND_HEAVY, myRoot, 1.8, 0.9)
	playSafeSound("rbxasset://sounds/action_jump.mp3", myRoot, 1.9, 1.0)

	-- Blue Chakra Sonic Shockwave Ring
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 3, 3)
	ring.CFrame = myRoot.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(0, 240, 255)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.2
	ring.Anchored = true
	ring.CanCollide = false
	ring.Parent = Workspace

	TweenService:Create(ring, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, 14, 14),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.25)

	-- Fire CDC Bindable to notify Movement Controller to execute high-speed homing dash
	evCDC:Fire()
	evCamImpact:Fire("CDC", 0.3)
	return true
end

-- =========================================================
-- EXECUTE ATTACK (Storm Connections Branching Combos)
-- =========================================================
executeAttack = function(forceLow: boolean?)
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	-- 1. Check for Storm 4 Counter Attack ([Guard + Attack])
	if LocalPlayer:GetAttribute("IsBlocking") == true then
		triggerCounterAttack(root)
		return
	end

	-- 2. Check for AIR CHASE opportunity
	local lockedTarget = getLockedTarget(root)
	if lockedTarget then
		local isTargetLaunched = lockedTarget:GetAttribute("IsAirborneLaunched") == true
		local tRoot = lockedTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
		if isTargetLaunched and tRoot and tRoot.Position.Y - root.Position.Y > 5.5 then
			triggerAirChase(root, lockedTarget)
			return
		end
	end

	-- 3. If currently attacking:
	-- If hit already landed and canChainNext is true, allow immediate combo advance!
	-- Otherwise, buffer the attack input so it fires the exact millisecond recovery finishes!
	if isAttacking then
		if canChainNext then
			-- Hit confirmed! Proceed immediately to next hit without delay!
		else
			-- Buffer this input!
			bufferedInput = {
				action = "Attack",
				forceLow = forceLow == true,
				timestamp = os.clock(),
			}
			return
		end
	end

	if isStaggered then return end

	local now = os.clock()
	if now - lastAttackTime > COMBO_RESET_TIME then
		currentComboIndex = 0
		currentBranch = "Neutral"
	end

	-- Smooth auto-orient to face opponent before lunging (no snapping!)
	smoothFaceTarget(root, lockedTarget)

	-- Determine Branch: Air, Up (Launcher), Down (Ground Bounce), or Neutral
	local isAirborne = hum.FloorMaterial == Enum.Material.Air or math.abs(root.AssemblyLinearVelocity.Y) > 3.0
	local isWHeld = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.DPadUp)
	local isSHeld = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.DPadDown)

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
	canChainNext = false -- Reset until hit confirms or recovery opens!

	-- Procedural Animation Trigger: Neutral1..4, Up1..4, Down1..4, Air1..3
	local animName = currentBranch .. tostring(currentComboIndex)
	local animDur = if isHeavyFinisher then 0.42 else 0.22
	evAnim:Fire(animName, animDur)

	-- Dynamic Camera Combo framing
	evCamImpact:Fire("ComboHit", currentComboIndex, isHeavyFinisher, currentBranch)

	-- =========================================================
	-- SMOOTH MAGNETIC GLIDE (CyberConnect2 Homing Track)
	-- =========================================================
	local tRoot = lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
	if tRoot then
		local toTarget = tRoot.Position - root.Position
		local dist = toTarget.Magnitude
		local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z).Unit

		if dist > 4.2 and dist <= 24 then
			-- Smooth magnetic slide towards target sweet spot (4.0 studs away)
			local glideSpeed = math.clamp(dist * 3.8, 30, isHeavyFinisher and 48 or 40)
			root.AssemblyLinearVelocity = Vector3.new(flatDir.X * glideSpeed, root.AssemblyLinearVelocity.Y, flatDir.Z * glideSpeed)
		else
			-- Already in melee pocket: slight forward punch impulse
			local fwd = root.CFrame.LookVector
			root.AssemblyLinearVelocity = Vector3.new(fwd.X * 12, root.AssemblyLinearVelocity.Y, fwd.Z * 12)
		end
	else
		-- No locked target: standard directional lunge
		local forwardDir = root.CFrame.LookVector
		local lungeSpeed = if isHeavyFinisher then 40 else 28
		root.AssemblyLinearVelocity = Vector3.new(forwardDir.X * lungeSpeed, root.AssemblyLinearVelocity.Y, forwardDir.Z * lungeSpeed)
	end

	-- =========================================================
	-- MULTI-FRAME ACTIVE HITBOX SCANNER (Active Strike Window)
	-- =========================================================
	local hitLanded = false
	local attackStartTime = os.clock()
	local scanWindow = if isHeavyFinisher then 0.20 else 0.14
	local hitScanConn: RBXScriptConnection?

	local function onHitConfirmed(hitTarget: Model)
		if hitLanded then return end
		hitLanded = true
		if hitScanConn then hitScanConn:Disconnect() end

		local targetRoot = hitTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
		local attackType = if currentBranch == "Down" then "Low" elseif currentBranch == "Up" then "High" else "Mid"
		local damage = if isHeavyFinisher then 28 elseif currentComboIndex == 3 then 16 elseif currentComboIndex == 2 then 12 else 8
		local knockback = if isHeavyFinisher then 54 else 8

		-- Visual & Sound FX
		playAttackFX(root, isHeavyFinisher, currentBranch, currentComboIndex, targetRoot and targetRoot.Position or nil)

		-- Two-way CC2 Micro Hitstop
		local hitstopTime = isHeavyFinisher and 0.09 or 0.05
		triggerHitstop(hitstopTime, root, targetRoot)

		-- Floating Damage & Combo Counter
		local impactPos = (targetRoot and targetRoot.Position) or (root.Position + root.CFrame.LookVector * 4)
		spawnDamagePopup(impactPos, damage, isHeavyFinisher, attackType)
		registerComboHit()
		addAwakeningCharge(isHeavyFinisher and 14 or 8)

		if isHeavyFinisher then
			screenShake(0.38, 0.22, currentBranch == "Up" and 2.5 or -2.5)
			if currentBranch == "Up" then
				evCamImpact:Fire("Launcher", 1.2)
			elseif currentBranch == "Down" or currentBranch == "Air" then
				evCamImpact:Fire("GroundSlam", 0.6)
			end
		else
			screenShake(0.12, 0.08)
		end

		-- Authoritative Server Damage & Reaction
		evAttack:FireServer(hitTarget, currentComboIndex, attackType, damage, knockback)

		-- HIT CONFIRMED! Open chain window immediately for next combo hit!
		if not isHeavyFinisher then
			canChainNext = true
			-- If player was already mashing, execute buffered attack immediately!
			tryConsumeBufferedInput()
		end
	end

	local function onTrainingPostHit(post: BasePart)
		if hitLanded then return end
		hitLanded = true
		if hitScanConn then hitScanConn:Disconnect() end

		-- Wobble Animation
		local origCf = post.CFrame
		local tiltDir = (post.Position - root.Position).Unit
		local twTilt = TweenService:Create(post, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = origCf * CFrame.Angles(math.rad(tiltDir.Z * 14), 0, math.rad(-tiltDir.X * 14)),
		})
		twTilt:Play()
		twTilt.Completed:Connect(function()
			TweenService:Create(post, TweenInfo.new(0.28, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
				CFrame = origCf,
			}):Play()
		end)

		-- Wood Splinter Particles
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(180, 130, 80), Color3.fromRGB(120, 80, 40))
		pe.Size = NumberSequence.new(0.8, 0.1)
		pe.Speed = NumberRange.new(8, 16)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Lifetime = NumberRange.new(0.3, 0.5)
		pe.Parent = post
		pe:Emit(16)
		Debris:AddItem(pe, 0.6)

		playSafeSound(SOUND_SNAP, root, 1.25, 1.0)
		playSafeSound(SOUND_THUMP, root, 0.9, 0.8)
		spawnDamagePopup(post.Position + Vector3.new(0, 2.5, 0), 15, isHeavyFinisher, "Wood")
		registerComboHit()
		addAwakeningCharge(12)
		if evPostHit then
			evPostHit:FireServer(post.Name)
		end

		if not isHeavyFinisher then
			canChainNext = true
			tryConsumeBufferedInput()
		end
	end

	-- Active Hitbox Scanning Loop
	hitScanConn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - attackStartTime
		if elapsed > scanWindow or hitLanded or not isAttacking then
			if hitScanConn then hitScanConn:Disconnect() end
			return
		end

		-- Active frames start at 0.03s (after wind-up anticipation)
		if elapsed >= 0.03 then
			local hitTarget = findHitTarget(root)
			if hitTarget then
				onHitConfirmed(hitTarget)
			else
				local post = checkHitTrainingPost(root)
				if post then
					onTrainingPostHit(post)
				end
			end
		end
	end)

	-- Attack recovery timer
	local recoveryTime = if isHeavyFinisher then 0.38 else 0.18
	task.delay(recoveryTime, function()
		if hitScanConn then hitScanConn:Disconnect() end
		if not isAirChasing then
			isAttacking = false
			canChainNext = false
			-- Check buffered input on recovery exit
			tryConsumeBufferedInput()
		end
	end)
end

-- =========================================================
-- ATTACKER STAGGER (Parried / Countered)
-- =========================================================
local function triggerAttackerParriedStagger()
	isStaggered = true
	isAttacking = false
	canChainNext = false
	currentComboIndex = 0
	bufferedInput = nil

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	hum.WalkSpeed = 0
	evAnim:Fire("StaggerStun", 1.25)

	local att = Instance.new("Attachment", root)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 60, 60))
	pe.Size = NumberSequence.new(1.6, 0)
	pe.Rate = 60
	pe.Speed = NumberRange.new(5, 14)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att

	print(">> [COUNTERED!] Strike countered! Staggered for 1.25s! <<")
	screenShake(0.45, 0.35)

	task.delay(1.25, function()
		att:Destroy()
		if hum then hum.WalkSpeed = 16 end
		isStaggered = false
		tryConsumeBufferedInput()
	end)
end

evParry.OnClientEvent:Connect(function(_defender: Player, attacker: Player)
	if attacker == LocalPlayer then
		triggerAttackerParriedStagger()
	end
end)

-- =========================================================
-- INPUT CONTROLLERS & DASH-CANCEL BINDINGS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- 1. Melee Strike: [J], Left-Click, Gamepad ButtonX (Square)
	if input.KeyCode == Enum.KeyCode.J or input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonX then
		executeAttack(false)

	-- 2. Dedicated Low Sweep: [K], Gamepad DPadDown
	elseif input.KeyCode == Enum.KeyCode.K or input.KeyCode == Enum.KeyCode.DPadDown then
		executeAttack(true)

	-- 3. Dash Button / Shift: If attacking, triggers CHAKRA DASH CANCEL (CDC)!
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.L or input.KeyCode == Enum.KeyCode.ButtonA then
		if isAttacking then
			local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				triggerChakraDashCancel(root)
			end
		end

	-- 4. Awakening Transformation: [G], Gamepad ButtonY (Triangle)
	elseif input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonY then
		triggerClientAwakening()
	end
end)

-- Mobile Touch Integration
evMobileAttack.Event:Connect(function(isLow: any)
	executeAttack(isLow == true)
end)

evMobileLow.Event:Connect(function()
	executeAttack(true)
end)

evMobileDash.Event:Connect(function()
	if isAttacking then
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			triggerChakraDashCancel(root)
		end
	end
end)

print("[CombatComboController] ✅ Naruto Storm Connections Engine Active: Buffered Combos, Multi-Frame Hitbox, Magnetic Glide & CDC ready.")
