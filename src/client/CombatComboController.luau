--!strict
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
