local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormRangedController')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormRangedController'
s.Source = [=====[--!strict
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
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormRangedController'
