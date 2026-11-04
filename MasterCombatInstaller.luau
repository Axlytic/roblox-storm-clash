--!strict
-- ============================================================
-- ★ STORM CLASH: HYBRID ANIME COMBAT ENGINE (v2.0) ★
-- Pillars: Naruto Storm 4 + Tekken + MUGEN 14
-- Controls: WASD (Move) + IJKL (Combat) + Mobile Touch + Gamepad
-- Jalankan script ini SEKALI di Command Bar Roblox Studio:
-- Paste seluruh isi script ini ke Command Bar dan tekan Enter
-- ============================================================

local RS  = game:GetService('ReplicatedStorage')
local SSS = game:GetService('ServerScriptService')
local SPS = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')

-- 1. Ensure CombatEvents folder and Remotes
local combatEvents = RS:FindFirstChild('CombatEvents') :: Folder?
if not combatEvents then
    combatEvents = Instance.new('Folder')
    combatEvents.Name = 'CombatEvents'
    combatEvents.Parent = RS
end

local remoteNames = { 'NinjaDashEvent', 'SidestepEvent', 'BlockEvent', 'ParryEvent', 'AttackEvent', 'AssistEvent', 'LeaderSwapEvent', 'UltimateEvent', 'WeaponStanceEvent' }
for _, name in remoteNames do
    if not combatEvents:FindFirstChild(name) then
        local ev = Instance.new('RemoteEvent')
        ev.Name = name
        ev.Parent = combatEvents
        print('[Installer] ✅ RemoteEvent created: ' .. name)
    end
end

local function installScript(name: string, scriptType: string, parent: Instance, sourceCode: string)
    local existing = parent:FindFirstChild(name)
    if existing then existing:Destroy() end
    local s = Instance.new(scriptType)
    s.Name = name
    s.Source = sourceCode
    s.Parent = parent
    print('[Installer] ✅ Installed ' .. scriptType .. ': ' .. name .. ' -> ' .. parent:GetFullName())
end

-- ============================================================
-- INSTALL: CombatConfig (ModuleScript)
-- ============================================================
do
    local src = [=====[--!strict
-- CombatConfig.luau
-- Shared configuration for Naruto Storm 4 Camera + Movement + Tekken Defense + Jump Force MUGEN 14 Architecture

local CombatConfig = {}

-- =========================================================
-- 1. CAMERA SETTINGS (Naruto Storm 4 Dual-Target Framing)
-- =========================================================
CombatConfig.Camera = {
	MinDistance     = 14,    -- Minimum camera zoom distance (close combat)
	MaxDistance     = 46,    -- Maximum camera zoom distance (far apart)
	BaseHeight      = 6.2,   -- Default camera height above ground
	HeightFactor    = 0.38,  -- How much camera raises when fighters jump in air
	SideOffset      = 3.4,   -- Over-the-shoulder offset for cinematic arena view
	SmoothSpeed     = 12,    -- Camera lerp responsiveness (higher = snappier)
	FOV_Default     = 65,    -- Standard combat field-of-view
	FOV_Dashing     = 76,    -- Dynamic FOV increase during high-speed Ninja Dash
}

-- =========================================================
-- 2. MOVEMENT & DASH SETTINGS (Storm 4 Mobility & Tekken Sidestep)
-- =========================================================
CombatConfig.Movement = {
	NormalWalkSpeed  = 16,
	CombatRunSpeed   = 24,
	NinjaDashSpeed   = 85,    -- High-speed homing dash toward opponent
	NinjaDashRange   = 80,    -- Max distance to lock and dash
	DashDuration     = 0.70,  -- Max duration of a single dash
	StopDistance     = 6.5,   -- Stop dash when within melee strike range
	
	-- Tekken 3D Sidestep
	DoubleTapWindow  = 0.28,  -- Seconds between key presses to trigger sidestep
	SidestepDistance = 16,    -- Studs traveled in sidestep arc
	SidestepVelocity = 58,    -- Fast snappy lateral evasion impulse
	SidestepDuration = 0.24,
	SidestepCooldown = 0.65,
}

-- =========================================================
-- 3. DEFENSE & PARRY SETTINGS (Tekken Technical Defense)
-- =========================================================
CombatConfig.Defense = {
	MaxGuardHealth     = 100,
	GuardRegenRate     = 15,    -- HP regenerated per second when not blocking
	GuardDamageAbsorb  = 22,    -- Guard meter absorbed on high/mid hit
	GuardBreakStunTime = 2.2,   -- Stun duration if guard bar breaks (Guard Crush)
	
	-- Tekken Just-Frame Parry
	ParryWindow        = 0.18,  -- 180ms window from pressing Guard (F) to achieve Perfect Parry
	ParryStaggerTime   = 1.15,  -- Attacker stagger duration on being parried
}

-- =========================================================
-- 4. ATTACK & COMBO SETTINGS (Core Fighting Strings)
-- =========================================================
CombatConfig.Combo = {
	ComboResetTime   = 0.85,  -- Seconds before combo counter resets to 1
	MaxMeleeRange    = 7.5,   -- Max range for basic melee hits
	LungeDistance    = 4.5,   -- Forward step distance toward target on strike

	-- 4-Hit M1 Attack String
	Hits = {
		[1] = {
			Damage = 8,
			Hitstun = 0.32,
			Knockback = 3,
			AttackType = "High", -- High attack (can be blocked by High Guard)
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Pitch = 1.3,
		},
		[2] = {
			Damage = 10,
			Hitstun = 0.35,
			Knockback = 4,
			AttackType = "Mid",  -- Mid attack (blocked by High Guard)
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Pitch = 1.1,
		},
		[3] = {
			Damage = 14,
			Hitstun = 0.42,
			Knockback = 6,
			LiftY = 6,           -- Launches opponent slightly into the air
			AttackType = "High",
			Sound = "rbxasset://sounds/volume_slider.ogg",
			Pitch = 1.5,
		},
		[4] = {
			Damage = 24,
			Hitstun = 1.1,
			Knockback = 48,      -- Heavy finisher blow: launches opponent flying
			LiftY = 8,
			AttackType = "Mid",
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Pitch = 1.0,
		},
	},

	-- Crouch M1: Low Shinobi Sweep
	CrouchSweep = {
		Damage = 16,
		Hitstun = 0.75,
		Knockback = 12,
		AttackType = "Low",   -- LOW attack (Bypasses High Guard! Must use Low Guard to block!)
		Sound = "rbxasset://sounds/action_jump.mp3",
		Pitch = 1.4,
	},
}

-- =========================================================
-- 5. SUPPORT ASSIST & LEADER SWAP (Storm 4 Tag-Team Mechanics)
-- =========================================================
CombatConfig.Assist = {
	AssistCooldown   = 20,    -- Seconds cooldown after calling assist
	AssistDuration   = 2.8,   -- Seconds striker stays in arena before leaping out
	LeaderSwapWindow = 0.4,   -- Time window to swap leader during attack
	StrikerTypes = {
		["FireballStriker"] = {
			Name = "Fireball Striker",
			Jutsu = "Flame Bullet",
			Damage = 22,
			Range = 60,
			Color = Color3.fromRGB(255, 80, 20),
		},
		["ChidoriStriker"] = {
			Name = "Lightning Striker",
			Jutsu = "Lightning Thrust",
			Damage = 26,
			Range = 40,
			Color = Color3.fromRGB(80, 200, 255),
		},
	},
}

-- =========================================================
-- 6. JUMP FORCE MUGEN 14 ARCHETYPES (Scalable Class Framework)
-- =========================================================
CombatConfig.Archetypes = {
	["Rushdown"] = {
		DisplayName = "Rushdown (e.g. Naruto / Luffy)",
		WalkSpeed = 18,
		NinjaDashSpeed = 92,
		GuardHealth = 90,
		Description = "High mobility and rapid combo strings, excels at close-quarters pressure.",
	},
	["Zoner"] = {
		DisplayName = "Zoner (e.g. Sasuke / Goku)",
		WalkSpeed = 15,
		NinjaDashSpeed = 80,
		GuardHealth = 85,
		Description = "Long-range jutsu projectiles and defensive spacing.",
	},
	["Grappler"] = {
		DisplayName = "Grappler (e.g. Broly / All Might)",
		WalkSpeed = 14,
		NinjaDashSpeed = 75,
		GuardHealth = 130,
		Description = "High defense, heavy armor, and crushing unblockable throws.",
	},
	["Sword"] = {
		DisplayName = "Sword Specialist (e.g. Zoro / Ichigo)",
		WalkSpeed = 16,
		NinjaDashSpeed = 86,
		GuardHealth = 100,
		Description = "Disjointed weapon hitboxes, extended melee reach, and sweeping slashes.",
	},
	["Trickster"] = {
		DisplayName = "Trickster (e.g. Killua / Minato)",
		WalkSpeed = 17,
		NinjaDashSpeed = 98,
		GuardHealth = 80,
		Description = "Instant teleport evasion, deceptive feints, and swift counter-attacks.",
	},
}

-- =========================================================
-- 7. ULTIMATE SECRET TECHNIQUE (Storm 4 Cinematic Finisher)
-- =========================================================
CombatConfig.Ultimate = {
	MaxChakra           = 100,
	ChakraGainPerHit    = 12,     -- Gained per successful M1 strike
	ChakraGainOnHit     = 8,      -- Gained when taking damage
	ChakraChargeRate    = 35,     -- Points charged per second while holding [C]
	RushSpeed           = 125,    -- Initial supersonic rush speed
	RushMaxDuration     = 0.85,   -- Max duration to connect with target
	RushConnectDistance = 7.0,    -- Distance to trigger cinematic cutscene
	UltimateDamage      = 52,     -- Massive cinematic finisher damage
	CutsceneDuration    = 2.6,    -- Seconds of dynamic multihit cinematic
}

-- =========================================================
-- 8. AWAKENING / TEKKEN RAGE MODE
-- =========================================================
CombatConfig.Awakening = {
	HealthThreshold  = 0.30,   -- Activates when character HP drops below 30%
	DamageMultiplier = 1.25,   -- +25% attack damage boost in Rage state
	SpeedMultiplier  = 1.20,   -- +20% walk and dash speed boost
	AuraColor        = Color3.fromRGB(255, 45, 45),
}

-- =========================================================
-- 9. MATCH & ROUND SYSTEM (Storm 4 Dual Top Screen HUD)
-- =========================================================
CombatConfig.Match = {
	RoundDuration    = 99,     -- Standard fighting game 99 second timer
	RoundsToWin      = 2,      -- Best of 3 rounds
	IntroDelay       = 3.2,    -- Duration of "ROUND 1... FIGHT!" sequence
	OutroDelay       = 4.0,    -- Duration of "K.O.! VICTORY!" sequence
}

-- =========================================================
-- 10. WEAPON & SLASH VISUALS (Stylized Katana)
-- =========================================================
CombatConfig.Weapon = {
	BladeLength   = 3.8,
	TrailColor    = Color3.fromRGB(0, 240, 255),
	TrailLifetime = 0.22,
	SheathOffset  = CFrame.new(0.8, -0.2, 0.6) * CFrame.Angles(0, 0, math.rad(-140)),
	WieldOffset   = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(-90), 0, 0),
}

-- =========================================================
-- 11. PLAYABLE CHARACTER ROSTER (Jump Force & Storm 4 Roster)
-- =========================================================
CombatConfig.Characters = {
	["Naruto"] = {
		Id = "Naruto",
		Name = "Naruto Uzumaki",
		Anime = "Naruto Shippuden",
		Title = "Hero of the Hidden Leaf",
		Icon = "🦊",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(255, 130, 20),
		AccentColor = Color3.fromRGB(0, 220, 255),
		WalkSpeed = 18,
		NinjaDashSpeed = 92,
		GuardHealth = 90,
		Stats = { Speed = 90, Power = 85, Defense = 75, Jutsu = 88 },
		M1Name = "Shinobi Taijutsu Barrage",
		SweepName = "Uzumaki Low Sweep",
		AssistName = "Shadow Clone Rasengan",
		UltimateName = "Wind Style: Rasenshuriken Blast",
		Quote = "I never go back on my word! That's my ninja way!",
	},
	["Sasuke"] = {
		Id = "Sasuke",
		Name = "Sasuke Uchiha",
		Anime = "Naruto Shippuden",
		Title = "Avenger of the Uchiha",
		Icon = "⚡",
		Archetype = "Zoner",
		PrimaryColor = Color3.fromRGB(150, 70, 255),
		AccentColor = Color3.fromRGB(80, 200, 255),
		WalkSpeed = 16,
		NinjaDashSpeed = 88,
		GuardHealth = 95,
		Stats = { Speed = 85, Power = 88, Defense = 80, Jutsu = 96 },
		M1Name = "Kusanagi Sword Flurry",
		SweepName = "Chidori Stream Sweep",
		AssistName = "Fireball Jutsu / Flame Bullet",
		UltimateName = "Kirin: Heavenly Lightning Strike",
		Quote = "My dream doesn't exist in the future. It lies in the past.",
	},
	["Luffy"] = {
		Id = "Luffy",
		Name = "Monkey D. Luffy",
		Anime = "One Piece",
		Title = "Captain of the Straw Hats",
		Icon = "🍖",
		Archetype = "Grappler",
		PrimaryColor = Color3.fromRGB(240, 40, 40),
		AccentColor = Color3.fromRGB(255, 215, 0),
		WalkSpeed = 15,
		NinjaDashSpeed = 82,
		GuardHealth = 125,
		Stats = { Speed = 78, Power = 95, Defense = 98, Jutsu = 70 },
		M1Name = "Gum-Gum Pistol Combo",
		SweepName = "Gum-Gum Whip Sweep",
		AssistName = "Gum-Gum Bazooka Striker",
		UltimateName = "Gear Fourth: King Kong Gun",
		Quote = "I'm gonna be King of the Pirates!",
	},
	["Zoro"] = {
		Id = "Zoro",
		Name = "Roronoa Zoro",
		Anime = "One Piece",
		Title = "Pirate Hunter / Santoryu",
		Icon = "⚔️",
		Archetype = "Sword",
		PrimaryColor = Color3.fromRGB(30, 220, 110),
		AccentColor = Color3.fromRGB(240, 255, 255),
		WalkSpeed = 16,
		NinjaDashSpeed = 86,
		GuardHealth = 105,
		Stats = { Speed = 82, Power = 94, Defense = 88, Jutsu = 80 },
		M1Name = "Three-Sword Style Onigiri",
		SweepName = "Dragon Twister Sweep",
		AssistName = "1080 Pound Ho Cannon",
		UltimateName = "Billion-Fold World Trichiliocosm",
		Quote = "Scars on the back are a swordsman's shame.",
	},
	["Killua"] = {
		Id = "Killua",
		Name = "Killua Zoldyck",
		Anime = "Hunter x Hunter",
		Title = "Assassin Prodigy",
		Icon = "⚡",
		Archetype = "Trickster",
		PrimaryColor = Color3.fromRGB(0, 255, 230),
		AccentColor = Color3.fromRGB(180, 100, 255),
		WalkSpeed = 18,
		NinjaDashSpeed = 100,
		GuardHealth = 80,
		Stats = { Speed = 99, Power = 80, Defense = 70, Jutsu = 92 },
		M1Name = "Assassin Claws & Palm Strike",
		SweepName = "Rhythm Echo Sweep",
		AssistName = "Thunderbolt Striker",
		UltimateName = "Godspeed: Whirlwind Execution",
		Quote = "If I don't defeat you right now... I can't protect anyone!",
	},
}

return CombatConfig
]=====]
    installScript('CombatConfig', 'ModuleScript', game:GetService('ReplicatedStorage'), src)
end

-- ============================================================
-- INSTALL: CombatServerMaster (Script)
-- ============================================================
do
    local src = [=====[--!strict
-- CombatServerMaster.luau
-- SERVER SCRIPT: Authoritative Combat Server Master
-- Features:
--   • Authoritative Hitbox & Distance Validation
--   • Tekken Defense & Just-Frame Parry Counter Verification
--   • Floating Combat Damage Indicators & Visual Block Feedback
--   • Naruto Storm 4 Assist Striker NPC Spawner & Jutsu Projectile Handler
--   • Full Integration with Training Dummy & Multiplayer PvP

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- =========================================================
-- 1. ENSURE COMBAT REMOTES
-- =========================================================
local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents") :: Folder?
if not combatEvents then
	combatEvents = Instance.new("Folder")
	combatEvents.Name = "CombatEvents"
	combatEvents.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evNinjaDash  = ensureRemote("NinjaDashEvent")
local evSidestep   = ensureRemote("SidestepEvent")
local evBlock      = ensureRemote("BlockEvent")
local evParry      = ensureRemote("ParryEvent")
local evAttack     = ensureRemote("AttackEvent")
local evAssist     = ensureRemote("AssistEvent")
local evLeaderSwap = ensureRemote("LeaderSwapEvent")

-- =========================================================
-- 2. PLAYER COMBAT STATE TRACKING
-- =========================================================
type PlayerCombatState = {
	isBlocking: boolean,
	blockType: string,
	blockStartTime: number,
	guardHealth: number,
	lastParriedTime: number,
}

local playerCombatStates: { [number]: PlayerCombatState } = {}

local function setupPlayer(player: Player)
	playerCombatStates[player.UserId] = {
		isBlocking = false,
		blockType = "None",
		blockStartTime = 0,
		guardHealth = 100,
		lastParriedTime = 0,
	}
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerCombatStates[player.UserId] = nil
end)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

-- =========================================================
-- 3. FLOATING COMBAT TEXT
-- =========================================================
local function spawnFloatingText(pos: Vector3, text: string, color: Color3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = pos + Vector3.new(math.random(-1, 1), 2.5, math.random(-1, 1))
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 45)
	bb.AlwaysOnTop = true
	bb.Parent = part

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb

	local tween = TweenService:Create(part, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = part.Position + Vector3.new(0, 3, 0),
	})
	tween:Play()

	task.delay(0.75, function()
		part:Destroy()
	end)
end

-- =========================================================
-- 4. BLOCK & PARRY LISTENERS
-- =========================================================
evBlock.OnServerEvent:Connect(function(player: Player, isBlocking: boolean, blockType: string, blockStartTime: number)
	local state = playerCombatStates[player.UserId]
	if state then
		state.isBlocking = isBlocking
		state.blockType = blockType or "None"
		state.blockStartTime = blockStartTime or os.clock()
		-- Broadcast to other clients for stance visuals
		evBlock:FireAllClients(player, isBlocking, blockType)
	end
end)

-- =========================================================
-- 5. ATTACK HANDLER (High/Mid/Low Guard & Parry Logic)
-- =========================================================
evAttack.OnServerEvent:Connect(function(attacker: Player, targetModel: Model, comboStep: number, attackType: string, damage: number, knockback: number)
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local aRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aRoot then return end

	if not targetModel or not targetModel.Parent then return end
	local tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tHum = targetModel:FindFirstChildOfClass("Humanoid")
	if not tRoot or not tHum or tHum.Health <= 0 then return end

	-- 1. Anti-Exploit Range Check (max 18 studs)
	local dist = (tRoot.Position - aRoot.Position).Magnitude
	if dist > 18 then
		return
	end

	-- 2. Determine Defender's Guard State
	local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
	local targetState = targetPlayer and playerCombatStates[targetPlayer.UserId]
	
	local isTargetBlocking = false
	local targetBlockType = "None"
	local targetBlockStartTime = 0

	if targetState then
		isTargetBlocking = targetState.isBlocking
		targetBlockType = targetState.blockType
		targetBlockStartTime = targetState.blockStartTime
	elseif targetModel:GetAttribute("DummyGuardMode") then
		-- Training Dummy configured guard mode
		local dMode = tostring(targetModel:GetAttribute("DummyGuardMode"))
		if dMode == "High" or dMode == "Low" or dMode == "Parry" then
			isTargetBlocking = true
			targetBlockType = dMode
			targetBlockStartTime = os.clock() -- always fresh for testing
		end
	end

	local now = os.clock()

	-- 3. Check for TEKKEN JUST-FRAME PARRY (180ms window)
	local isParry = isTargetBlocking and (targetBlockType == "Parry" or (now - targetBlockStartTime <= 0.18))
	if isParry then
		print(string.format(">> [TEKKEN PERFECT PARRY] %s counter-parried %s! <<", targetModel.Name, attacker.Name))
		spawnFloatingText(tRoot.Position, "⚡ PERFECT PARRY!", Color3.fromRGB(255, 220, 50))

		-- Stagger attacker
		if targetPlayer then
			evParry:FireClient(targetPlayer, targetPlayer, attacker)
		end
		evParry:FireClient(attacker, targetPlayer or attacker, attacker)
		return
	end

	-- 4. Check for HIGH / MID / LOW GUARD
	local isBlocked = false
	if isTargetBlocking then
		if attackType == "High" and targetBlockType == "High" then
			isBlocked = true
		elseif attackType == "Mid" and targetBlockType == "High" then
			isBlocked = true
		elseif attackType == "Low" and targetBlockType == "Low" then
			isBlocked = true
		end
	end

	if isBlocked then
		-- Attack BLOCKED!
		print(string.format(">> [GUARD BLOCKED] %s blocked %s's %s attack! <<", targetModel.Name, attacker.Name, attackType))
		spawnFloatingText(tRoot.Position, "🛡️ BLOCKED", Color3.fromRGB(0, 220, 255))

		-- Spark block visual
		local blkPart = Instance.new("Part")
		blkPart.Size = Vector3.new(2, 2, 0.2)
		blkPart.CFrame = CFrame.lookAt((aRoot.Position + tRoot.Position) * 0.5, aRoot.Position)
		blkPart.Material = Enum.Material.ForceField
		blkPart.Color = Color3.fromRGB(0, 255, 255)
		blkPart.Anchored = true
		blkPart.CanCollide = false
		blkPart.Parent = Workspace
		Debris:AddItem(blkPart, 0.2)
		return
	end

	-- 5. CLEAN HIT!
	local isAwakening = attacker:GetAttribute("IsAwakening") == true
	local finalDamage = if isAwakening then math.floor(damage * 1.25) else damage
	tHum:TakeDamage(finalDamage)
	local dmgColor = if isAwakening then Color3.fromRGB(255, 30, 30) elseif attackType == "Low" then Color3.fromRGB(255, 170, 0) elseif comboStep == 4 then Color3.fromRGB(255, 50, 50) else Color3.fromRGB(255, 255, 255)
	spawnFloatingText(tRoot.Position, string.format("💥 -%d%s", finalDamage, isAwakening and " [RAGE]" or ""), dmgColor)

	-- Apply Knockback
	local hitDir = (tRoot.Position - aRoot.Position).Unit
	local flatHitDir = Vector3.new(hitDir.X, 0, hitDir.Z).Unit
	local liftY = if comboStep == 4 then 12 elseif comboStep == 3 then 6 else 0
	tRoot.AssemblyLinearVelocity = (flatHitDir * knockback) + Vector3.new(0, liftY, 0)
end)

-- =========================================================
-- 6. STORM 4 ASSIST STRIKER JUTSU
-- =========================================================
evAssist.OnServerEvent:Connect(function(player: Player, strikerType: string)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Find Target to aim jutsu at
	local targetRoot: BasePart? = nil
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:FindFirstChild("HumanoidRootPart") then
		targetRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				targetRoot = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart
				break
			end
		end
	end

	-- 1. Spawn Striker Companion NPC beside player
	local strikerModel = Instance.new("Model")
	strikerModel.Name = "AssistStriker_" .. player.Name

	local sRoot = Instance.new("Part")
	sRoot.Name = "HumanoidRootPart"
	sRoot.Size = Vector3.new(2, 2, 1)
	sRoot.CFrame = root.CFrame * CFrame.new(3.5, 0, 1.5)
	sRoot.Color = Color3.fromRGB(40, 50, 80)
	sRoot.Material = Enum.Material.SmoothPlastic
	sRoot.Anchored = true
	sRoot.CanCollide = false
	sRoot.Parent = strikerModel

	local sHead = Instance.new("Part")
	sHead.Name = "Head"
	sHead.Size = Vector3.new(1.2, 1.2, 1.2)
	sHead.CFrame = sRoot.CFrame * CFrame.new(0, 1.6, 0)
	sHead.Color = Color3.fromRGB(220, 180, 140)
	sHead.Anchored = true
	sHead.CanCollide = false
	sHead.Parent = strikerModel

	-- Tag Billboard
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 140, 0, 35)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = sHead

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⚡ STRIKER JUTSU!"
	lbl.TextColor3 = Color3.fromRGB(0, 255, 200)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb

	strikerModel.Parent = Workspace

	-- 2. Fire Jutsu Projectile toward target
	if targetRoot then
		local startPos = sRoot.Position + Vector3.new(0, 1.5, 0)
		local endPos = targetRoot.Position + Vector3.new(0, 1.5, 0)
		local jutsuDir = (endPos - startPos).Unit

		local orb = Instance.new("Part")
		orb.Name = "JutsuOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(2.5, 2.5, 2.5)
		orb.Position = startPos
		orb.Color = Color3.fromRGB(0, 220, 255)
		orb.Material = Enum.Material.Neon
		orb.CanCollide = false
		orb.Anchored = false
		orb.Parent = Workspace

		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
		pe.Size = NumberSequence.new(1.5, 0)
		pe.Rate = 50
		pe.Speed = NumberRange.new(5, 12)
		pe.Lifetime = NumberRange.new(0.3, 0.5)
		pe.Parent = orb

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = jutsuDir * 80
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bv.Parent = orb

		orb.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			if model and model ~= char and model ~= strikerModel then
				local hum = model:FindFirstChildOfClass("Humanoid")
				local r = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hum and r then
					hum:TakeDamage(22)
					spawnFloatingText(r.Position, "⚡ JUTSU IMPACT -22", Color3.fromRGB(0, 255, 255))
					r.AssemblyLinearVelocity = jutsuDir * 40 + Vector3.new(0, 10, 0)
					orb:Destroy()
				end
			end
		end)

		Debris:AddItem(orb, 2.5)
	end

	-- Despawn Striker after 2.8 seconds
	task.delay(2.8, function()
		strikerModel:Destroy()
	end)
end)

-- =========================================================
-- 7. ULTIMATE SECRET TECHNIQUE (Storm 4 Finisher)
-- =========================================================
local evUltimate = ensureRemote("UltimateEvent")
evUltimate.OnServerEvent:Connect(function(attacker: Player, targetModel: Model)
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local aRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aRoot then return end

	if not targetModel or not targetModel.Parent then return end
	local tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tHum = targetModel:FindFirstChildOfClass("Humanoid")
	if not tRoot or not tHum or tHum.Health <= 0 then return end

	local dist = (tRoot.Position - aRoot.Position).Magnitude
	if dist > 25 then return end

	local isAwakening = attacker:GetAttribute("IsAwakening") == true
	local ultDmg = if isAwakening then 65 else 52
	tHum:TakeDamage(ultDmg)
	spawnFloatingText(tRoot.Position, string.format("⚡ ULTIMATE FINISH -%d!", ultDmg), Color3.fromRGB(255, 220, 50))
	local hitDir = (tRoot.Position - aRoot.Position).Unit
	tRoot.AssemblyLinearVelocity = hitDir * 75 + Vector3.new(0, 20, 0)
end)

print("[CombatServerMaster] ✅ Authoritative Combat Server Master fully initialized.")
]=====]
    installScript('CombatServerMaster', 'Script', game:GetService('ServerScriptService'), src)
end

-- ============================================================
-- INSTALL: TrainingDummySpawner (Script)
-- ============================================================
do
    local src = [=====[--!strict
-- TrainingDummySpawner.luau
-- SERVER SCRIPT: Interactive Fighting Lab Training Dummy NPC
-- Features:
--   • Tagged with "IsCombatTarget" for automatic Storm 4 lock-on
--   • Interactive ProximityPrompt to switch Defense Modes:
--       [1] Neutral (Stand Still) -> Test Combos & Ninja Dash
--       [2] High Guard Active -> Test Low Sweep Guard Piercing
--       [3] Low Guard Active -> Test High/Mid Hits
--       [4] Practice Parry -> Test Tekken Just-Frame Parry Counter
--   • Realtime Billboard HUD with HP bar and current Defense Mode
--   • Auto HP regeneration so testing is seamless

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local MODES = { "Neutral", "High", "Low", "Parry" }
local MODE_COLORS = {
	["Neutral"] = Color3.fromRGB(0, 255, 200),
	["High"]    = Color3.fromRGB(0, 200, 255),
	["Low"]     = Color3.fromRGB(255, 180, 0),
	["Parry"]   = Color3.fromRGB(255, 220, 50),
}

local function createTrainingDummy(pos: Vector3): Model
	local existing = Workspace:FindFirstChild("TrainingDummy")
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = "TrainingDummy"

	-- Humanoid & RootPart
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = pos + Vector3.new(0, 3, 0)
	root.Anchored = true
	root.CanCollide = true
	root.Transparency = 1
	root.Parent = model
	model.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = root.CFrame
	torso.Color = Color3.fromRGB(60, 65, 80)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(220, 180, 140)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Visual Gi / Shinobi Belt
	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Size = Vector3.new(2.1, 0.4, 1.1)
	belt.CFrame = torso.CFrame * CFrame.new(0, -0.6, 0)
	belt.Color = Color3.fromRGB(220, 30, 30)
	belt.Material = Enum.Material.Fabric
	belt.Anchored = true
	belt.CanCollide = false
	belt.Parent = model

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 1000
	hum.Health = 1000
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	-- Overhead Tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "DummyTag"
	bb.Size = UDim2.new(0, 200, 0, 55)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.fromScale(1, 0.45)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⚔️ TRAINING DUMMY LAB"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextScaled = true
	titleLabel.Parent = bb

	local modeLabel = Instance.new("TextLabel")
	modeLabel.Size = UDim2.fromScale(1, 0.38)
	modeLabel.Position = UDim2.new(0, 0, 0.5, 0)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "[ MODE: NEUTRAL (STAND STILL) ]"
	modeLabel.TextColor3 = MODE_COLORS["Neutral"]
	modeLabel.Font = Enum.Font.GothamBold
	modeLabel.TextScaled = true
	modeLabel.Parent = bb

	-- ProximityPrompt to switch Guard Modes
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ganti Mode Latihan"
	prompt.ObjectText = "Training Dummy"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = torso

	local currentModeIdx = 1
	model:SetAttribute("DummyGuardMode", "Neutral")

	prompt.Triggered:Connect(function(player)
		currentModeIdx = (currentModeIdx % #MODES) + 1
		local newMode = MODES[currentModeIdx]
		model:SetAttribute("DummyGuardMode", newMode)

		modeLabel.Text = string.format("[ MODE: %s ]", string.upper(newMode))
		modeLabel.TextColor3 = MODE_COLORS[newMode] or Color3.fromRGB(255, 255, 255)
		print(string.format(">> [Training Lab] %s changed Dummy Mode to: %s <<", player.Name, newMode))
	end)

	-- Auto HP regeneration
	hum.HealthChanged:Connect(function(newHealth)
		if newHealth < 300 then
			hum.Health = 1000
		end
	end)

	-- Tag as combat target
	model:SetAttribute("IsCombatTarget", true)
	model.Parent = Workspace
	print(">> [TrainingDummy] Lab Dummy spawned successfully at " .. tostring(pos) .. " <<")
	return model
end

-- Spawn Dummy in arena center (Y=52 matches DilemmaArena floor)
task.delay(1.5, function()
	createTrainingDummy(Vector3.new(0, 50, 15))
end)
]=====]
    installScript('TrainingDummySpawner', 'Script', game:GetService('ServerScriptService'), src)
end

-- ============================================================
-- INSTALL: StormWeaponServer (Script)
-- ============================================================
do
    local src = [=====[--!strict
-- StormWeaponServer.luau
-- SERVER SCRIPT: Stylized Anime Katana & Slash Trail System
-- Features:
--   • Procedural high-polish anime Katana model (no external mesh asset IDs needed!)
--   • Dynamic Motor6D/Weld attachment (Hip Sheath vs. RightHand Combat Grip)
--   • Vibrant Neon Slash Trail for strikes, dashes, and ultimate finishers
--   • Auto-equips upon Player Character spawn or Training Dummy creation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 5) :: Folder
if not combatEvents then
	combatEvents = Instance.new("Folder")
	combatEvents.Name = "CombatEvents"
	combatEvents.Parent = ReplicatedStorage
end

local evWeaponStance = combatEvents:FindFirstChild("WeaponStanceEvent") :: RemoteEvent?
if not evWeaponStance then
	evWeaponStance = Instance.new("RemoteEvent")
	evWeaponStance.Name = "WeaponStanceEvent"
	evWeaponStance.Parent = combatEvents
end

-- =========================================================
-- PROCEDURAL KATANA MODEL BUILDER
-- =========================================================
local function createKatanaModel(): Model
	local model = Instance.new("Model")
	model.Name = "StormKatana"

	-- 1. Handle (Core Motor part)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 1.2, 0.25)
	handle.Color = Color3.fromRGB(24, 26, 32)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = model
	model.PrimaryPart = handle

	-- 2. Pommel (Kashira)
	local pommel = Instance.new("Part")
	pommel.Name = "Pommel"
	pommel.Size = Vector3.new(0.3, 0.15, 0.3)
	pommel.Color = Color3.fromRGB(255, 215, 0)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Massless = true
	pommel.CFrame = handle.CFrame * CFrame.new(0, -0.65, 0)
	pommel.Parent = model

	local wPommel = Instance.new("WeldConstraint")
	wPommel.Part0 = handle
	wPommel.Part1 = pommel
	wPommel.Parent = handle

	-- 3. Guard (Tsuba)
	local tsuba = Instance.new("Part")
	tsuba.Name = "Tsuba"
	tsuba.Size = Vector3.new(0.65, 0.1, 0.65)
	tsuba.Color = Color3.fromRGB(255, 215, 0)
	tsuba.Material = Enum.Material.Metal
	tsuba.CanCollide = false
	tsuba.Massless = true
	tsuba.CFrame = handle.CFrame * CFrame.new(0, 0.62, 0)
	tsuba.Parent = model

	local wTsuba = Instance.new("WeldConstraint")
	wTsuba.Part0 = handle
	wTsuba.Part1 = tsuba
	wTsuba.Parent = handle

	-- 4. Blade (Katana Steel + Neon Cutting Edge)
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.12, 3.4, 0.32)
	blade.Color = Color3.fromRGB(230, 240, 255)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, 2.35, 0.04)
	blade.Parent = model

	local wBlade = Instance.new("WeldConstraint")
	wBlade.Part0 = handle
	wBlade.Part1 = blade
	wBlade.Parent = handle

	-- Glowing Edge Line
	local edge = Instance.new("Part")
	edge.Name = "NeonEdge"
	edge.Size = Vector3.new(0.06, 3.38, 0.08)
	edge.Color = Color3.fromRGB(0, 240, 255)
	edge.Material = Enum.Material.Neon
	edge.CanCollide = false
	edge.Massless = true
	edge.CFrame = blade.CFrame * CFrame.new(0, 0, 0.15)
	edge.Parent = model

	local wEdge = Instance.new("WeldConstraint")
	wEdge.Part0 = blade
	wEdge.Part1 = edge
	wEdge.Parent = blade

	-- 5. Slash Trail Attachments
	local attBase = Instance.new("Attachment")
	attBase.Name = "TrailBase"
	attBase.Position = Vector3.new(0, -1.6, 0.12)
	attBase.Parent = blade

	local attTip = Instance.new("Attachment")
	attTip.Name = "TrailTip"
	attTip.Position = Vector3.new(0, 1.7, 0.12)
	attTip.Parent = blade

	local trail = Instance.new("Trail")
	trail.Name = "SlashTrail"
	trail.Attachment0 = attTip
	trail.Attachment1 = attBase
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.22
	trail.MinLength = 0.1
	trail.Enabled = false -- Enabled only during swings/dashes
	trail.Parent = blade

	return model
end

-- =========================================================
-- EQUIP / SHEATH LOGIC
-- =========================================================
local function attachKatanaToChar(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local upperTorso = character:FindFirstChild("UpperTorso") :: BasePart? or character:FindFirstChild("Torso") :: BasePart?
	local rightHand = character:FindFirstChild("RightHand") :: BasePart? or character:FindFirstChild("Right Arm") :: BasePart?
	if not root or not upperTorso or not rightHand then return end

	local existing = character:FindFirstChild("StormKatana")
	if existing then existing:Destroy() end

	local katana = createKatanaModel()
	local handle = katana.PrimaryPart
	if not handle then return end

	-- Create Motor6D for animated smooth draw/sheath
	local katanaMotor = Instance.new("Motor6D")
	katanaMotor.Name = "KatanaWeld"
	katanaMotor.Part0 = rightHand -- default in combat hand
	katanaMotor.Part1 = handle
	katanaMotor.C0 = CFrame.new(0, -0.9, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	katanaMotor.Parent = rightHand

	katana.Parent = character
end

-- Handle character spawning
local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		attachKatanaToChar(char)
	end)
	if player.Character then
		attachKatanaToChar(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

-- Also attach katana to Training Dummy if present
task.spawn(function()
	task.wait(1)
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		local torso = dummy:FindFirstChild("Torso") :: BasePart?
		if torso and not dummy:FindFirstChild("StormKatana") then
			local katana = createKatanaModel()
			local handle = katana.PrimaryPart
			if handle then
				local w = Instance.new("WeldConstraint")
				w.Part0 = torso
				w.Part1 = handle
				w.Parent = torso
				handle.CFrame = torso.CFrame * CFrame.new(0.9, -0.2, 0.7) * CFrame.Angles(0, 0, math.rad(-135))
				katana.Parent = dummy
			end
		end
	end
end)

print("[StormWeaponServer] ✅ Anime Katana & Slash Trail System active.")

]=====]
    installScript('StormWeaponServer', 'Script', game:GetService('ServerScriptService'), src)
end

-- ============================================================
-- INSTALL: LobbyManagerServer (Script)
-- ============================================================
do
    local src = [=====[--!strict
-- LobbyManagerServer.luau
-- SERVER SCRIPT: Anime Staging Lobby & Character Roster Management
-- Features:
--   • Procedural Shinobi Staging Lobby (separate from Combat Arena)
--   • SpawnLocation situated in the Lobby courtyard
--   • Interactive Gateways (Teleport to 1v1 Arena & Return to Lobby)
--   • Character Select Pedestal & Terminal
--   • Authoritative Character Roster & Attribute Replication

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- Positions
local LOBBY_CENTER = Vector3.new(0, 50, -160)
local ARENA_SPAWN  = Vector3.new(0, 52.5, 0)
local LOBBY_SPAWN  = Vector3.new(0, 52.5, -160)

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evCharSelect   = ensureRemote("CharacterSelectEvent")
local evOpenRoster   = ensureRemote("OpenRosterEvent")
local evTeleportGate = ensureRemote("TeleportGateEvent")

-- =========================================================
-- BUILD PROCEDURAL SHINOBI LOBBY
-- =========================================================
local function buildLobby()
	-- Remove any old default SpawnLocations outside Lobby
	for _, desc in ipairs(Workspace:GetChildren()) do
		if desc:IsA("SpawnLocation") and desc.Name ~= "LobbySpawnLocation" then
			desc:Destroy()
		end
	end

	local existing = Workspace:FindFirstChild("StormClashLobby")
	if existing then existing:Destroy() end

	local lobbyModel = Instance.new("Model")
	lobbyModel.Name = "StormClashLobby"

	-- 1. Main Floor Platform (Diameter 70)
	local floor = Instance.new("Part")
	floor.Name = "LobbyFloor"
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(4, 70, 70)
	floor.CFrame = CFrame.new(LOBBY_CENTER) * CFrame.Angles(0, 0, math.rad(90))
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(32, 35, 46)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Parent = lobbyModel

	-- Inner Ring
	local ring = Instance.new("Part")
	ring.Name = "InnerRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(4.1, 40, 40)
	ring.CFrame = CFrame.new(LOBBY_CENTER) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.WoodPlanks
	ring.Color = Color3.fromRGB(75, 45, 30)
	ring.Anchored = true
	ring.CanCollide = true
	ring.Parent = lobbyModel

	-- 2. SpawnLocation in Lobby
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawnLocation"
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.Position = LOBBY_SPAWN + Vector3.new(0, -1.8, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(0, 200, 255)
	spawn.Transparency = 0.6
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = lobbyModel

	-- 3. Japanese Torii Gate at Arena Entrance
	local gatePos = LOBBY_CENTER + Vector3.new(0, 0, 30)

	local function createPillar(offset: Vector3)
		local p = Instance.new("Part")
		p.Size = Vector3.new(1.8, 16, 1.8)
		p.Position = gatePos + offset
		p.Color = Color3.fromRGB(180, 25, 25)
		p.Material = Enum.Material.Wood
		p.Anchored = true
		p.CanCollide = true
		p.Parent = lobbyModel
	end
	createPillar(Vector3.new(-7, 8, 0))
	createPillar(Vector3.new(7, 8, 0))

	-- Torii Header
	local header = Instance.new("Part")
	header.Size = Vector3.new(18, 1.6, 2.4)
	header.Position = gatePos + Vector3.new(0, 16, 0)
	header.Color = Color3.fromRGB(24, 24, 28)
	header.Material = Enum.Material.Wood
	header.Anchored = true
	header.CanCollide = true
	header.Parent = lobbyModel

	-- 4. Gateway Portal to Combat Arena
	local portal = Instance.new("Part")
	portal.Name = "ArenaPortalGate"
	portal.Size = Vector3.new(12, 14, 0.5)
	portal.Position = gatePos + Vector3.new(0, 7, 0)
	portal.Material = Enum.Material.ForceField
	portal.Color = Color3.fromRGB(0, 240, 255)
	portal.Transparency = 0.5
	portal.Anchored = true
	portal.CanCollide = false
	portal.Parent = lobbyModel

	local portalPe = Instance.new("ParticleEmitter")
	portalPe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	portalPe.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 255, 255))
	portalPe.Size = NumberSequence.new(1.5, 0)
	portalPe.Rate = 35
	portalPe.Speed = NumberRange.new(4, 8)
	portalPe.Parent = portal

	-- Portal Prompt
	local portalPrompt = Instance.new("ProximityPrompt")
	portalPrompt.ActionText = "Masuk ke Arena Pertarungan"
	portalPrompt.ObjectText = "⚔️ COMBAT ARENA"
	portalPrompt.HoldDuration = 0
	portalPrompt.MaxActivationDistance = 14
	portalPrompt.Parent = portal

	portalPrompt.Triggered:Connect(function(player)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(ARENA_SPAWN)
				print(string.format(">> [Lobby] %s entered the Combat Arena! <<", player.Name))
			end
		end
	end)

	-- 5. Character Select Pedestal (Center of Lobby)
	local pedPos = LOBBY_CENTER + Vector3.new(0, 0, -10)
	local pedestal = Instance.new("Part")
	pedestal.Name = "RosterPedestal"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Size = Vector3.new(2.4, 6, 6)
	pedestal.CFrame = CFrame.new(pedPos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pedestal.Color = Color3.fromRGB(255, 215, 0)
	pedestal.Material = Enum.Material.Neon
	pedestal.Anchored = true
	pedestal.CanCollide = true
	pedestal.Parent = lobbyModel

	local pedPrompt = Instance.new("ProximityPrompt")
	pedPrompt.ActionText = "Pilih Karakter Anime"
	pedPrompt.ObjectText = "👥 ROSTER FIGHTER"
	pedPrompt.HoldDuration = 0
	pedPrompt.MaxActivationDistance = 12
	pedPrompt.Parent = pedestal

	pedPrompt.Triggered:Connect(function(player)
		evOpenRoster:FireClient(player)
	end)

	-- 6. Arena Return Portal (Back from Arena to Lobby)
	local arenaReturn = Instance.new("Part")
	arenaReturn.Name = "ArenaReturnPad"
	arenaReturn.Size = Vector3.new(6, 0.4, 6)
	arenaReturn.Position = Vector3.new(0, 50.3, 56)
	arenaReturn.Color = Color3.fromRGB(255, 140, 0)
	arenaReturn.Material = Enum.Material.Neon
	arenaReturn.Transparency = 0.4
	arenaReturn.Anchored = true
	arenaReturn.CanCollide = true
	arenaReturn.Parent = Workspace

	local retPrompt = Instance.new("ProximityPrompt")
	retPrompt.ActionText = "Kembali ke Lobi"
	retPrompt.ObjectText = "🏯 LOBI UTAMA"
	retPrompt.HoldDuration = 0
	retPrompt.MaxActivationDistance = 10
	retPrompt.Parent = arenaReturn

	retPrompt.Triggered:Connect(function(player)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(LOBBY_SPAWN)
				print(string.format(">> [Lobby] %s returned to the Lobby! <<", player.Name))
			end
		end
	end)

	lobbyModel.Parent = Workspace
	print(">> [LobbyManager] Shinobi Lobby Courtyard & Gateways built successfully! <<")
end

-- =========================================================
-- CHARACTER SELECTION & APPLICATION
-- =========================================================
local function applyCharacter(player: Player, charId: string)
	local charData = CombatConfig.Characters[charId]
	if not charData then return end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- 1. Set Attributes
	player:SetAttribute("SelectedCharacter", charId)
	player:SetAttribute("CharacterName", charData.Name)
	player:SetAttribute("CharacterTitle", charData.Title)
	player:SetAttribute("CharacterIcon", charData.Icon)
	player:SetAttribute("CharacterArchetype", charData.Archetype)

	-- 2. Apply Speeds & Health
	hum.WalkSpeed = charData.WalkSpeed
	player:SetAttribute("NinjaDashSpeed", charData.NinjaDashSpeed)
	player:SetAttribute("MaxGuardHealth", charData.GuardHealth)

	-- 3. Update Katana / Blade Visuals with Character Palette
	local katana = char:FindFirstChild("StormKatana")
	if katana then
		local edge = katana:FindFirstChild("NeonEdge") :: BasePart?
		if edge then
			edge.Color = charData.PrimaryColor
		end

		local blade = katana:FindFirstChild("Blade") :: BasePart?
		if blade then
			local trail = blade:FindFirstChild("SlashTrail") :: Trail?
			if trail then
				trail.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, charData.PrimaryColor),
					ColorSequenceKeypoint.new(0.6, charData.AccentColor),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				})
			end
		end
	end

	-- 4. Replicate to all clients
	evCharSelect:FireAllClients(player, charId, charData)
	print(string.format(">> [Roster] %s chose: %s [%s]! <<", player.Name, charData.Name, charData.Archetype))
end

evCharSelect.OnServerEvent:Connect(function(player: Player, charId: string)
	applyCharacter(player, charId)
end)

-- Default setup for new players
local function onCharacter(player: Player, char: Model)
	task.wait(0.2)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = CFrame.new(LOBBY_SPAWN)
	end
	local current = player:GetAttribute("SelectedCharacter") or "Naruto"
	applyCharacter(player, tostring(current))
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		onCharacter(p, p.Character)
	end
end

-- Build lobby on server start
buildLobby()

print("[LobbyManagerServer] ✅ Lobby & Character Roster Server active.")
]=====]
    installScript('LobbyManagerServer', 'Script', game:GetService('ServerScriptService'), src)
end

-- ============================================================
-- INSTALL: StormCameraController (LocalScript)
-- ============================================================
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

-- ============================================================
-- INSTALL: StormMovementController (LocalScript)
-- ============================================================
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

	-- 1. Direct Ninja Dash with [L] Key or Gamepad ButtonB (Circle / B)
	if input.KeyCode == Enum.KeyCode.L or input.KeyCode == Enum.KeyCode.ButtonB then
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

print("[StormMovementController] ✅ Loaded — Movement [WASD], Sidestep [A/D x2], Ninja Dash [L] / [Space x2] / Gamepad (B).")
]=====]
    installScript('StormMovementController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: TekkenDefenseController (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- TekkenDefenseController.luau
-- CLIENT SCRIPT: Tekken-Style Technical Defense System
-- Features:
--   • WASD Movement + IJKL Defense:
--       [K] Hold: Standing High/Mid Guard (Cyan Shield)
--       [S + K] or [Ctrl + K]: Crouched Low Guard (Amber Shield)
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
	return key == Enum.KeyCode.K or key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonR1 or key == Enum.KeyCode.ButtonR2
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

print("[TekkenDefenseController] ✅ Loaded — Guard [K] / [F] / Gamepad (R1/R2), Low Guard [S+K].")
]=====]
    installScript('TekkenDefenseController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: CombatComboController (LocalScript)
-- ============================================================
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
-- EXECUTE ATTACK (J / Left Click / Mobile / Gamepad)
-- =========================================================
local function executeAttack()
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

	-- Low Sweep check: S key (retreating/crouch in fighting games) OR Ctrl / C
	local isSHeld = UserInputService:IsKeyDown(Enum.KeyCode.S)
	local isCtrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C)
	local isLowSweep = isSHeld or isCtrlHeld
	local isHeavyFinisher = false

	if isLowSweep then
		-- Low Shinobi Sweep
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
	local lungeSpeed = if isHeavyFinisher then 40 else LUNGE_FORCE
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
	-- 1. Keyboard [J] or Left-Click
	if input.KeyCode == Enum.KeyCode.J or input.UserInputType == Enum.UserInputType.MouseButton1 then
		executeAttack()
	-- 2. Gamepad Controller (Square on PS, X on Xbox)
	elseif input.KeyCode == Enum.KeyCode.ButtonX then
		executeAttack()
	end
end)

-- Mobile Touch Integration
if evMobileAttack then
	evMobileAttack.Event:Connect(function()
		executeAttack()
	end)
end

print("[CombatComboController] ✅ Loaded — Attack [J] / Left-Click / Gamepad (Square/X), Low Sweep [S+J].")
]=====]
    installScript('CombatComboController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormAssistController (LocalScript)
-- ============================================================
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

-- ============================================================
-- INSTALL: StormAnimationController (LocalScript)
-- ============================================================
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
    installScript('StormAnimationController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormMatchHUD (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- StormMatchHUD.luau
-- CLIENT SCRIPT: Naruto Storm 4 Dual Top Screen Fighting HUD & Match Announcer System
-- Features:
--   • Top Symmetrical Angled Health Bars (Player 1 Left vs Opponent Right)
--   • Delayed "Ghost" Damage Bar animation (fighting game standard)
--   • Guard Gauge & Chakra / Ultimate Energy Meters
--   • Center 99s Hexagonal Round Countdown Timer
--   • Full Match Announcer System:
--       - "ROUND 1 / 2" -> "READY..." -> "FIGHT!" with cinematic pulse & screen shake
--       - "K.O.!" -> "PLAYER 1 WINS! / VICTORY!"
--   • Dynamic tracking of Target (Opponent Player or Training Dummy Lab)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local evCharSelect = combatEvents:WaitForChild("CharacterSelectEvent", 10) :: RemoteEvent?

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Match State
local roundTimer = 99
local isMatchActive = true
local playerWins = 0
local opponentWins = 0

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormMatchHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Main Top Container
local topContainer = Instance.new("Frame")
topContainer.Name = "TopHUDContainer"
topContainer.Size = UDim2.new(1, 0, 0, 110)
topContainer.Position = UDim2.new(0, 0, 0, 0)
topContainer.BackgroundTransparency = 1
topContainer.Parent = screenGui

-- =========================================================
-- CENTER TIMER & ROUND INDICATORS
-- =========================================================
local centerFrame = Instance.new("Frame")
centerFrame.Name = "CenterTimer"
centerFrame.Size = UDim2.new(0, 90, 0, 75)
centerFrame.Position = UDim2.new(0.5, 0, 0, 10)
centerFrame.AnchorPoint = Vector2.new(0.5, 0)
centerFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
centerFrame.BackgroundTransparency = 0.2
centerFrame.Parent = topContainer
Instance.new("UICorner", centerFrame).CornerRadius = UDim.new(0, 8)

local cStroke = Instance.new("UIStroke")
cStroke.Color = Color3.fromRGB(0, 240, 255)
cStroke.Thickness = 2
cStroke.Parent = centerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerText"
timerLabel.Size = UDim2.new(1, 0, 0.7, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 2)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextSize = 34
timerLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
timerLabel.Text = "99"
timerLabel.Parent = centerFrame

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundText"
roundLabel.Size = UDim2.new(1, 0, 0.3, 0)
roundLabel.Position = UDim2.new(0, 0, 0.68, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.Font = Enum.Font.GothamBold
roundLabel.TextSize = 11
roundLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
roundLabel.Text = "ROUND 1"
roundLabel.Parent = centerFrame

-- ROSTER BUTTON [B]
local rosterBtn = Instance.new("TextButton")
rosterBtn.Name = "OpenRosterHUDButton"
rosterBtn.Size = UDim2.new(0, 110, 0, 22)
rosterBtn.Position = UDim2.new(0.5, 0, 0, 88)
rosterBtn.AnchorPoint = Vector2.new(0.5, 0)
rosterBtn.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
rosterBtn.BackgroundTransparency = 0.2
rosterBtn.Font = Enum.Font.GothamBold
rosterBtn.TextSize = 10
rosterBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
rosterBtn.Text = "👥 ROSTER [B]"
rosterBtn.Parent = topContainer
Instance.new("UICorner", rosterBtn).CornerRadius = UDim.new(0, 6)
local rStroke = Instance.new("UIStroke")
rStroke.Color = Color3.fromRGB(0, 240, 255)
rStroke.Thickness = 1.2
rStroke.Parent = rosterBtn

rosterBtn.MouseButton1Click:Connect(function()
	local hud = PlayerGui:FindFirstChild("StormCharacterSelectHUD")
	if hud then
		local bindable = hud:FindFirstChild("ToggleRosterUI") :: BindableFunction?
		if bindable then
			bindable:Invoke(true)
		else
			hud.Enabled = not hud.Enabled
		end
	end
end)

-- =========================================================
-- FIGHTER 1 (LEFT SIDE - LOCAL PLAYER)
-- =========================================================
local p1Frame = Instance.new("Frame")
p1Frame.Name = "Fighter1_Left"
p1Frame.Size = UDim2.new(0.40, -55, 0, 70)
p1Frame.Position = UDim2.new(0.5, -55, 0, 12)
p1Frame.AnchorPoint = Vector2.new(1, 0)
p1Frame.BackgroundTransparency = 1
p1Frame.Parent = topContainer

-- P1 Avatar Portrait
local p1Avatar = Instance.new("ImageLabel")
p1Avatar.Name = "P1Avatar"
p1Avatar.Size = UDim2.new(0, 56, 0, 56)
p1Avatar.Position = UDim2.new(0, 0, 0, 5)
p1Avatar.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
p1Avatar.Parent = p1Frame
Instance.new("UICorner", p1Avatar).CornerRadius = UDim.new(1, 0)
local p1Stroke = Instance.new("UIStroke")
p1Stroke.Color = Color3.fromRGB(0, 255, 200)
p1Stroke.Thickness = 2.5
p1Stroke.Parent = p1Avatar

-- Load Local Player Thumbnail
task.spawn(function()
	local thumb, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	if isReady then
		p1Avatar.Image = thumb
	end
end)

-- P1 Name & Archetype
local p1Name = Instance.new("TextLabel")
p1Name.Name = "P1Name"
p1Name.Size = UDim2.new(1, -70, 0, 18)
p1Name.Position = UDim2.new(0, 66, 0, 2)
p1Name.BackgroundTransparency = 1
p1Name.Font = Enum.Font.GothamBlack
p1Name.TextSize = 13
p1Name.TextColor3 = Color3.fromRGB(255, 255, 255)
p1Name.TextXAlignment = Enum.TextXAlignment.Left
p1Name.Text = string.upper(LocalPlayer.DisplayName) .. " [SHINOBI]"
p1Name.Parent = p1Frame

local function updateLocalFighterUI(charId: string)
	local char = CombatConfig.Characters[charId]
	if char then
		p1Name.Text = string.format("%s // %s [%s]", string.upper(char.Name), string.upper(LocalPlayer.DisplayName), string.upper(char.Archetype))
		p1Stroke.Color = char.PrimaryColor
	else
		p1Name.Text = string.upper(LocalPlayer.DisplayName) .. " [SHINOBI]"
	end
end

LocalPlayer:GetAttributeChangedSignal("SelectedCharacter"):Connect(function()
	local cur = LocalPlayer:GetAttribute("SelectedCharacter")
	if cur then
		updateLocalFighterUI(tostring(cur))
	end
end)

if evCharSelect then
	evCharSelect.OnClientEvent:Connect(function(player: Player, charId: string, charData: any)
		if player == LocalPlayer then
			updateLocalFighterUI(charId)
		end
	end)
end

task.spawn(function()
	task.wait(0.5)
	local initChar = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
	updateLocalFighterUI(tostring(initChar))
end)

-- P1 Health Bar Container
local p1HealthBg = Instance.new("Frame")
p1HealthBg.Name = "P1HealthBg"
p1HealthBg.Size = UDim2.new(1, -70, 0, 18)
p1HealthBg.Position = UDim2.new(0, 66, 0, 22)
p1HealthBg.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
p1HealthBg.Parent = p1Frame
Instance.new("UICorner", p1HealthBg).CornerRadius = UDim.new(0, 4)

-- Delayed Ghost Bar (white/red decay)
local p1GhostBar = Instance.new("Frame")
p1GhostBar.Name = "P1GhostBar"
p1GhostBar.Size = UDim2.new(1, 0, 1, 0)
p1GhostBar.BackgroundColor3 = Color3.fromRGB(255, 230, 200)
p1GhostBar.BorderSizePixel = 0
p1GhostBar.Parent = p1HealthBg
Instance.new("UICorner", p1GhostBar).CornerRadius = UDim.new(0, 4)

-- Actual Green/Yellow HP Bar
local p1HealthFill = Instance.new("Frame")
p1HealthFill.Name = "P1HealthFill"
p1HealthFill.Size = UDim2.new(1, 0, 1, 0)
p1HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
p1HealthFill.BorderSizePixel = 0
p1HealthFill.Parent = p1HealthBg
Instance.new("UICorner", p1HealthFill).CornerRadius = UDim.new(0, 4)

-- P1 Sub-bars: Chakra & Guard
local p1ChakraBg = Instance.new("Frame")
p1ChakraBg.Name = "P1ChakraBg"
p1ChakraBg.Size = UDim2.new(0.65, 0, 0, 8)
p1ChakraBg.Position = UDim2.new(0, 66, 0, 44)
p1ChakraBg.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
p1ChakraBg.Parent = p1Frame
Instance.new("UICorner", p1ChakraBg).CornerRadius = UDim.new(0, 3)

local p1ChakraFill = Instance.new("Frame")
p1ChakraFill.Name = "P1ChakraFill"
p1ChakraFill.Size = UDim2.new(0.3, 0, 1, 0)
p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
p1ChakraFill.BorderSizePixel = 0
p1ChakraFill.Parent = p1ChakraBg
Instance.new("UICorner", p1ChakraFill).CornerRadius = UDim.new(0, 3)

local p1GuardBg = Instance.new("Frame")
p1GuardBg.Name = "P1GuardBg"
p1GuardBg.Size = UDim2.new(0.30, 0, 0, 8)
p1GuardBg.Position = UDim2.new(0, 66 + (p1HealthBg.AbsoluteSize.X * 0.7), 0, 44)
p1GuardBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
p1GuardBg.Parent = p1Frame
Instance.new("UICorner", p1GuardBg).CornerRadius = UDim.new(0, 3)

local p1GuardFill = Instance.new("Frame")
p1GuardFill.Name = "P1GuardFill"
p1GuardFill.Size = UDim2.new(1, 0, 1, 0)
p1GuardFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
p1GuardFill.BorderSizePixel = 0
p1GuardFill.Parent = p1GuardBg
Instance.new("UICorner", p1GuardFill).CornerRadius = UDim.new(0, 3)

-- =========================================================
-- FIGHTER 2 (RIGHT SIDE - OPPONENT / TRAINING DUMMY)
-- =========================================================
local p2Frame = Instance.new("Frame")
p2Frame.Name = "Fighter2_Right"
p2Frame.Size = UDim2.new(0.40, -55, 0, 70)
p2Frame.Position = UDim2.new(0.5, 55, 0, 12)
p2Frame.AnchorPoint = Vector2.new(0, 0)
p2Frame.BackgroundTransparency = 1
p2Frame.Parent = topContainer

-- P2 Avatar Portrait (Far Right)
local p2Avatar = Instance.new("ImageLabel")
p2Avatar.Name = "P2Avatar"
p2Avatar.Size = UDim2.new(0, 56, 0, 56)
p2Avatar.Position = UDim2.new(1, -56, 0, 5)
p2Avatar.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
p2Avatar.Parent = p2Frame
Instance.new("UICorner", p2Avatar).CornerRadius = UDim.new(1, 0)
local p2Stroke = Instance.new("UIStroke")
p2Stroke.Color = Color3.fromRGB(255, 80, 80)
p2Stroke.Thickness = 2.5
p2Stroke.Parent = p2Avatar

-- P2 Name
local p2Name = Instance.new("TextLabel")
p2Name.Name = "P2Name"
p2Name.Size = UDim2.new(1, -70, 0, 18)
p2Name.Position = UDim2.new(0, 4, 0, 2)
p2Name.BackgroundTransparency = 1
p2Name.Font = Enum.Font.GothamBlack
p2Name.TextSize = 13
p2Name.TextColor3 = Color3.fromRGB(255, 255, 255)
p2Name.TextXAlignment = Enum.TextXAlignment.Right
p2Name.Text = "TRAINING DUMMY LAB"
p2Name.Parent = p2Frame

-- P2 Health Bar Container (Mirrored from right to left)
local p2HealthBg = Instance.new("Frame")
p2HealthBg.Name = "P2HealthBg"
p2HealthBg.Size = UDim2.new(1, -70, 0, 18)
p2HealthBg.Position = UDim2.new(0, 4, 0, 22)
p2HealthBg.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
p2HealthBg.Parent = p2Frame
Instance.new("UICorner", p2HealthBg).CornerRadius = UDim.new(0, 4)

local p2GhostBar = Instance.new("Frame")
p2GhostBar.Name = "P2GhostBar"
p2GhostBar.Size = UDim2.new(1, 0, 1, 0)
p2GhostBar.AnchorPoint = Vector2.new(1, 0)
p2GhostBar.Position = UDim2.new(1, 0, 0, 0)
p2GhostBar.BackgroundColor3 = Color3.fromRGB(255, 230, 200)
p2GhostBar.BorderSizePixel = 0
p2GhostBar.Parent = p2HealthBg
Instance.new("UICorner", p2GhostBar).CornerRadius = UDim.new(0, 4)

local p2HealthFill = Instance.new("Frame")
p2HealthFill.Name = "P2HealthFill"
p2HealthFill.Size = UDim2.new(1, 0, 1, 0)
p2HealthFill.AnchorPoint = Vector2.new(1, 0)
p2HealthFill.Position = UDim2.new(1, 0, 0, 0)
p2HealthFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
p2HealthFill.BorderSizePixel = 0
p2HealthFill.Parent = p2HealthBg
Instance.new("UICorner", p2HealthFill).CornerRadius = UDim.new(0, 4)

-- =========================================================
-- ANNOUNCER OVERLAY BANNER
-- =========================================================
local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "AnnouncerBanner"
bannerFrame.Size = UDim2.new(1, 0, 0, 130)
bannerFrame.Position = UDim2.new(0, 0, 0.40, 0)
bannerFrame.AnchorPoint = Vector2.new(0, 0.5)
bannerFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
bannerFrame.BackgroundTransparency = 1
bannerFrame.Visible = false
bannerFrame.Parent = screenGui

local bannerText = Instance.new("TextLabel")
bannerText.Name = "BannerText"
bannerText.Size = UDim2.fromScale(1, 1)
bannerText.BackgroundTransparency = 1
bannerText.Font = Enum.Font.GothamBlack
bannerText.TextSize = 54
bannerText.TextColor3 = Color3.fromRGB(255, 220, 50)
bannerText.Text = "ROUND 1"
bannerText.Parent = bannerFrame

local function playAnnouncer(text: string, color: Color3, duration: number)
	bannerText.Text = text
	bannerText.TextColor3 = color
	bannerFrame.Visible = true
	bannerFrame.BackgroundTransparency = 0.35
	bannerText.TextTransparency = 0
	bannerText.TextSize = 68

	-- Punch in tween
	TweenService:Create(bannerText, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 52,
	}):Play()

	-- Sound cue
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
		snd.PlaybackSpeed = 1.3
		snd.Volume = 1
		snd.Parent = bannerFrame
		snd:Play()
		task.delay(1, function() pcall(function() snd:Destroy() end) end)
	end)

	task.delay(duration, function()
		local fade = TweenService:Create(bannerFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		local fadeText = TweenService:Create(bannerText, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fadeText:Play()
		fade.Completed:Connect(function()
			bannerFrame.Visible = false
		end)
	end)
end

-- Start Match Intro Sequence
task.spawn(function()
	task.wait(1.2)
	playAnnouncer("ROUND 1", Color3.fromRGB(255, 220, 50), 1.2)
	task.wait(1.5)
	playAnnouncer("READY...", Color3.fromRGB(0, 240, 255), 1.0)
	task.wait(1.1)
	playAnnouncer("FIGHT!", Color3.fromRGB(255, 50, 50), 1.4)
end)

-- =========================================================
-- RUNTIME HEALTH & TIMER UPDATER
-- =========================================================
local lastP1HP = 100
local lastP2HP = 100
local timerAccumulator = 0

RunService.RenderStepped:Connect(function(dt: number)
	-- 1. Round Timer countdown
	if isMatchActive then
		timerAccumulator = timerAccumulator + dt
		if timerAccumulator >= 1.0 then
			timerAccumulator = timerAccumulator - 1.0
			roundTimer = math.max(0, roundTimer - 1)
			timerLabel.Text = tostring(roundTimer)
			if roundTimer <= 15 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
			end
			if roundTimer == 0 then
				isMatchActive = false
				playAnnouncer("TIME UP!", Color3.fromRGB(255, 180, 0), 2.5)
			end
		end
	end

	-- 2. Local Player (P1) Health
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			p1HealthFill.Size = UDim2.new(hpRatio, 0, 1, 0)

			-- Smooth delayed ghost bar
			if hpRatio < lastP1HP then
				TweenService:Create(p1GhostBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(hpRatio, 0, 1, 0),
				}):Play()
				lastP1HP = hpRatio
			elseif hpRatio > lastP1HP then
				p1GhostBar.Size = UDim2.new(hpRatio, 0, 1, 0)
				lastP1HP = hpRatio
			end

			-- Dynamic HP color
			p1HealthFill.BackgroundColor3 = if hpRatio > 0.5 then Color3.fromRGB(0, 255, 140)
				elseif hpRatio > 0.25 then Color3.fromRGB(255, 200, 40)
				else Color3.fromRGB(255, 50, 50)
		end
	end

	-- 3. Opponent (P2) Health (Training Dummy or nearest player)
	local targetModel: Model? = nil
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		targetModel = dummy
		p2Name.Text = "TRAINING DUMMY LAB [BOT]"
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				targetModel = p.Character
				local oppCharId = p:GetAttribute("SelectedCharacter")
				local oppData = oppCharId and CombatConfig.Characters[oppCharId]
				if oppData then
					p2Name.Text = string.format("%s // %s [%s]", string.upper(oppData.Name), string.upper(p.DisplayName), string.upper(oppData.Archetype))
					p2Stroke.Color = oppData.PrimaryColor
				else
					p2Name.Text = string.upper(p.DisplayName)
				end
				break
			end
		end
	end

	if targetModel then
		local tHum = targetModel:FindFirstChildOfClass("Humanoid")
		if tHum then
			local tRatio = math.clamp(tHum.Health / tHum.MaxHealth, 0, 1)
			p2HealthFill.Size = UDim2.new(tRatio, 0, 1, 0)

			if tRatio < lastP2HP then
				TweenService:Create(p2GhostBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(tRatio, 0, 1, 0),
				}):Play()
				lastP2HP = tRatio
			elseif tRatio > lastP2HP then
				p2GhostBar.Size = UDim2.new(tRatio, 0, 1, 0)
				lastP2HP = tRatio
			end

			if tRatio <= 0 and isMatchActive then
				isMatchActive = false
				playAnnouncer("K.O.!", Color3.fromRGB(255, 40, 40), 2.5)
				task.delay(2.6, function()
					playAnnouncer("VICTORY!", Color3.fromRGB(255, 220, 50), 3.0)
				end)
			end
		end
	end

	-- 4. Local Chakra Gauge
	local chakraVal = LocalPlayer:GetAttribute("ChakraValue") or 50
	local chakraRatio = math.clamp(tonumber(chakraVal) :: number / 100, 0, 1)
	p1ChakraFill.Size = UDim2.new(chakraRatio, 0, 1, 0)
	if chakraRatio >= 1.0 then
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(255, 220, 50) -- glowing gold when ready
	else
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	end
end)

print("[StormMatchHUD] ✅ Naruto Storm 4 Dual Top Screen Fighting HUD & Announcer active.")
]=====]
    installScript('StormMatchHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormUltimateController (LocalScript)
-- ============================================================
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
]=====]
    installScript('StormUltimateController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: MobileCombatHUD (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- MobileCombatHUD.luau
-- CLIENT SCRIPT: Modern Cyber-Anime Mobile Touch Controls HUD
-- Features:
--   • Auto-activates on Mobile / Tablet touch screens (or toggleable on PC)
--   • Ergonomic Right-Thumb Combat Layout:
--       [ATTACK] Button (Primary M1 / J Key)
--       [GUARD]  Button (Hold for K Key High/Low Guard, tap for Parry)
--       [DASH]   Button (L Key Homing Ninja Dash)
--       [ASSIST] Button (I Key Jutsu Striker)
--       [SWAP]   Button (U Key Tag Swap)
--       [LOCK]   Button (Z Key Camera Lock-on)
--   • Tactile spring-back animations on button press & neon glow

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Bindable Events for Client Communication
local function getOrMakeBindable(name: string): BindableEvent
	local be = ReplicatedStorage:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = ReplicatedStorage
	end
	return be
end

local evMobileAttack   = getOrMakeBindable("MobileAttackAction")
local evMobileGuard    = getOrMakeBindable("MobileGuardAction")
local evMobileDash     = getOrMakeBindable("MobileDashAction")
local evMobileAssist   = getOrMakeBindable("MobileAssistAction")
local evMobileSwap     = getOrMakeBindable("MobileSwapAction")
local evMobileUltimate = getOrMakeBindable("MobileUltimateAction")
local evMobileChakra   = getOrMakeBindable("MobileChakraAction")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormMobileCombatHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Visibility check: TouchEnabled OR PC manual toggle button
local isTouchDevice = UserInputService.TouchEnabled
local hudContainer = Instance.new("Frame")
hudContainer.Name = "ActionCluster"
hudContainer.Size = UDim2.new(0, 260, 0, 260)
hudContainer.Position = UDim2.new(1, -270, 1, -270)
hudContainer.BackgroundTransparency = 1
hudContainer.Visible = isTouchDevice -- Auto-shows on Mobile
hudContainer.Parent = screenGui

-- =========================================================
-- BUTTON BUILDER HELPER
-- =========================================================
local function createActionButton(
	name: string,
	icon: string,
	keyHint: string,
	color: Color3,
	pos: UDim2,
	size: UDim2
): (TextButton, UIStroke)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size
	btn.Position = pos
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	btn.BackgroundTransparency = 0.25
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = hudContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2.5
	stroke.Parent = btn

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 0.55, 0)
	iconLabel.Position = UDim2.new(0, 0, 0.12, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextSize = 22
	iconLabel.TextColor3 = color
	iconLabel.Parent = btn

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.Size = UDim2.new(1, 0, 0.35, 0)
	hintLabel.Position = UDim2.new(0, 0, 0.60, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = keyHint
	hintLabel.Font = Enum.Font.GothamBlack
	hintLabel.TextSize = 10
	hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	hintLabel.Parent = btn

	-- Press Animation
	local origSize = size
	local smallSize = UDim2.new(size.X.Scale, size.X.Offset * 0.90, size.Y.Scale, size.Y.Offset * 0.90)

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(btn, TweenInfo.new(0.08), { Size = smallSize, BackgroundTransparency = 0.05 }):Play()
		end
	end)

	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(btn, TweenInfo.new(0.12), { Size = origSize, BackgroundTransparency = 0.25 }):Play()
		end
	end)

	return btn, stroke
end

-- =========================================================
-- CREATE COMBAT BUTTONS
-- =========================================================
-- 1. ATTACK [J] (Big Central Action Button)
local btnAttack = createActionButton(
	"BtnAttack", "⚔️", "ATTACK [J]", Color3.fromRGB(0, 240, 255),
	UDim2.new(0.65, 0, 0.65, 0), UDim2.new(0, 78, 0, 78)
)
btnAttack.MouseButton1Click:Connect(function()
	evMobileAttack:Fire()
end)

-- 2. GUARD [K] (Right side button with hold support)
local btnGuard = createActionButton(
	"BtnGuard", "🛡️", "GUARD [K]", Color3.fromRGB(255, 215, 0),
	UDim2.new(0.88, 0, 0.32, 0), UDim2.new(0, 56, 0, 56)
)
btnGuard.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		evMobileGuard:Fire(true)
	end
end)
btnGuard.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		evMobileGuard:Fire(false)
	end
end)

-- 3. DASH [L] (Left bottom button)
local btnDash = createActionButton(
	"BtnDash", "💨", "DASH [L]", Color3.fromRGB(0, 255, 170),
	UDim2.new(0.28, 0, 0.82, 0), UDim2.new(0, 58, 0, 58)
)
btnDash.MouseButton1Click:Connect(function()
	evMobileDash:Fire()
end)

-- 4. ASSIST [I] (Top mid button)
local btnAssist = createActionButton(
	"BtnAssist", "⚡", "ASSIST [I]", Color3.fromRGB(255, 100, 50),
	UDim2.new(0.48, 0, 0.22, 0), UDim2.new(0, 52, 0, 52)
)
btnAssist.MouseButton1Click:Connect(function()
	evMobileAssist:Fire()
end)

-- 5. LEADER SWAP [U] (Left button)
local btnSwap = createActionButton(
	"BtnSwap", "🔄", "SWAP [U]", Color3.fromRGB(200, 100, 255),
	UDim2.new(0.18, 0, 0.40, 0), UDim2.new(0, 48, 0, 48)
)
btnSwap.MouseButton1Click:Connect(function()
	evMobileSwap:Fire()
end)

-- 6. ULTIMATE JUTSU [O] (Top-right special finisher button)
local btnUltimate = createActionButton(
	"BtnUltimate", "🔥", "ULT [O]", Color3.fromRGB(255, 60, 40),
	UDim2.new(0.85, 0, 0.12, 0), UDim2.new(0, 56, 0, 56)
)
btnUltimate.MouseButton1Click:Connect(function()
	evMobileUltimate:Fire()
end)

-- 7. CHAKRA CHARGE [C] (Far left charge button)
local btnChakra = createActionButton(
	"BtnChakra", "🌀", "CHAKRA [C]", Color3.fromRGB(0, 190, 255),
	UDim2.new(0.08, 0, 0.65, 0), UDim2.new(0, 52, 0, 52)
)
btnChakra.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		evMobileChakra:Fire(true)
	end
end)
btnChakra.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		evMobileChakra:Fire(false)
	end
end)

-- =========================================================
-- TOGGLE BUTTON FOR PC TESTING
-- =========================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MobileHUDToggle"
toggleBtn.Size = UDim2.new(0, 95, 0, 26)
toggleBtn.Position = UDim2.new(1, -110, 0, 50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 10
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
toggleBtn.Text = isTouchDevice and "📱 TOUCH: ON" or "📱 TOUCH: OFF"
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
local tStroke = Instance.new("UIStroke")
tStroke.Color = Color3.fromRGB(0, 255, 200)
tStroke.Thickness = 1
tStroke.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
	hudContainer.Visible = not hudContainer.Visible
	toggleBtn.Text = hudContainer.Visible and "📱 TOUCH: ON" or "📱 TOUCH: OFF"
	tStroke.Color = hudContainer.Visible and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(150, 150, 150)
end)

print("[MobileCombatHUD] ✅ Loaded — Touch controls auto-configured for worldwide mobile & tablet players.")

]=====]
    installScript('MobileCombatHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: PerformanceSettingsManager (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- PerformanceSettingsManager.luau
-- CLIENT SCRIPT: Low-GFX & High-Performance Mode for Worldwide Devices
-- Features:
--   • Single-click toggle between [⚡ GFX: HIGH] and [⚡ GFX: LOW]
--   • Optimizes performance for budget Android, low-end PCs, and battery saving:
--       - Toggles Post-Processing (Bloom & SunRays)
--       - Toggles Dynamic Global Shadows
--       - Reduces particle clutter
--   • Locks FPS at smooth 60 FPS across all global regions

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isLowGfxActive = false

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormPerformanceGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Toggle Button (Top Right)
local btnGfx = Instance.new("TextButton")
btnGfx.Name = "GfxModeToggle"
btnGfx.Size = UDim2.new(0, 100, 0, 26)
btnGfx.Position = UDim2.new(1, -110, 0, 16)
btnGfx.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
btnGfx.BackgroundTransparency = 0.25
btnGfx.Font = Enum.Font.GothamBold
btnGfx.TextSize = 10
btnGfx.TextColor3 = Color3.fromRGB(0, 240, 255)
btnGfx.Text = "⚡ GFX: HIGH"
btnGfx.Parent = screenGui
Instance.new("UICorner", btnGfx).CornerRadius = UDim.new(0, 6)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 240, 255)
stroke.Thickness = 1.2
stroke.Parent = btnGfx

-- =========================================================
-- APPLY GRAPHICS SETTINGS
-- =========================================================
local function setLowGfxMode(enableLow: boolean)
	isLowGfxActive = enableLow

	-- 1. Lighting PostEffects
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then bloom.Enabled = not enableLow end

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then sunRays.Enabled = not enableLow end

	-- 2. Shadows
	Lighting.GlobalShadows = not enableLow

	-- 3. Update Button Visual
	if enableLow then
		btnGfx.Text = "⚡ GFX: LOW (60FPS)"
		btnGfx.TextColor3 = Color3.fromRGB(255, 200, 50)
		stroke.Color = Color3.fromRGB(255, 200, 50)
		print(">> [Storm Performance] Low-GFX Performance Mode Enabled (Optimized for Mobile/Budget Devices). <<")
	else
		btnGfx.Text = "⚡ GFX: HIGH"
		btnGfx.TextColor3 = Color3.fromRGB(0, 240, 255)
		stroke.Color = Color3.fromRGB(0, 240, 255)
		print(">> [Storm Performance] High Quality Anime Visuals Restored. <<")
	end
end

btnGfx.MouseButton1Click:Connect(function()
	setLowGfxMode(not isLowGfxActive)
end)

print("[PerformanceSettingsManager] ✅ Loaded — Low-GFX / 60FPS Performance Toggle active.")

]=====]
    installScript('PerformanceSettingsManager', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormCharacterSelectHUD (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- StormCharacterSelectHUD.luau
-- CLIENT SCRIPT: Jump Force & Naruto Storm 4 Character Selection Modal & Roster HUD
-- Features:
--   • 5-Fighter Roster Grid: Naruto, Sasuke, Luffy, Zoro, Killua
--   • Dynamic Archetype Badges (Rushdown, Zoner, Grappler, Sword, Trickster)
--   • Detailed Character Dossier: 4 Stat Bars (Speed, Power, Defense, Jutsu)
--   • Technique Arsenal Showcase (M1, Low Sweep, Ninja Assist, Secret Technique)
--   • Interactive Selection with Sound Effects and Visual Glow
--   • Toggleable via [B] Key, Lobby Pedestal, or Top-Left HUD Button

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local evCharSelect = combatEvents:WaitForChild("CharacterSelectEvent", 10) :: RemoteEvent
local evOpenRoster = combatEvents:WaitForChild("OpenRosterEvent", 10) :: RemoteEvent

-- State
local isOpen = false
local currentSelectedId = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
local previewSelectedId = currentSelectedId

-- Sounds helper
local function playUiSound(soundName: string, pitch: number)
	task.spawn(function()
		pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/" .. soundName
			sound.Volume = 0.5
			sound.PlaybackSpeed = pitch or 1.0
			sound.Parent = SoundService
			sound:Play()
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end)
	end)
end

-- =========================================================
-- SCREEN GUI CREATION
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormCharacterSelectHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Dark Vignette Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "ModalBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Position = UDim2.new(0, 0, 0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = screenGui

-- Main Modal Window
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainModal"
mainFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = backdrop
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(0, 240, 255)
modalStroke.Thickness = 2
modalStroke.Parent = mainFrame

-- Header Bar
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderBar"
headerFrame.Size = UDim2.new(1, 0, 0, 56)
headerFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
headerFrame.BackgroundTransparency = 0.2
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame
Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 24, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "⚡ SHINOBI ROSTER // CHOOSE YOUR FIGHTER"
titleLabel.Parent = headerFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(240, 40, 40)
closeBtn.BackgroundTransparency = 0.2
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- CONTENT SPLIT: LEFT GRID & RIGHT PREVIEW
-- =========================================================
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -40, 1, -80)
contentFrame.Position = UDim2.new(0, 20, 0, 68)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- LEFT PANEL: ROSTER CARDS (Width: 42%)
local rosterList = Instance.new("ScrollingFrame")
rosterList.Name = "RosterList"
rosterList.Size = UDim2.new(0.42, 0, 1, 0)
rosterList.Position = UDim2.new(0, 0, 0, 0)
rosterList.BackgroundTransparency = 1
rosterList.ScrollBarThickness = 6
rosterList.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
rosterList.CanvasSize = UDim2.new(0, 0, 0, 5 * 84)
rosterList.Parent = contentFrame

local rosterLayout = Instance.new("UIListLayout")
rosterLayout.SortOrder = Enum.SortOrder.LayoutOrder
rosterLayout.Padding = UDim.new(0, 10)
rosterLayout.Parent = rosterList

-- RIGHT PANEL: DETAILED DOSSIER (Width: 56%)
local previewPanel = Instance.new("Frame")
previewPanel.Name = "PreviewPanel"
previewPanel.Size = UDim2.new(0.56, 0, 1, 0)
previewPanel.Position = UDim2.new(0.44, 0, 0, 0)
previewPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
previewPanel.BackgroundTransparency = 0.4
previewPanel.Parent = contentFrame
Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 10)

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(40, 50, 70)
previewStroke.Thickness = 1.5
previewStroke.Parent = previewPanel

-- Scroll container for preview details
local previewScroll = Instance.new("ScrollingFrame")
previewScroll.Name = "PreviewScroll"
previewScroll.Size = UDim2.new(1, 0, 1, -54)
previewScroll.Position = UDim2.new(0, 0, 0, 0)
previewScroll.BackgroundTransparency = 1
previewScroll.ScrollBarThickness = 4
previewScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
previewScroll.CanvasSize = UDim2.new(0, 0, 0, 360)
previewScroll.Parent = previewPanel

-- Top Info: Large Icon + Name + Title
local pIcon = Instance.new("TextLabel")
pIcon.Name = "PreviewIcon"
pIcon.Size = UDim2.new(0, 68, 0, 68)
pIcon.Position = UDim2.new(0, 16, 0, 16)
pIcon.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
pIcon.Font = Enum.Font.GothamBold
pIcon.TextSize = 36
pIcon.Text = "🦊"
pIcon.Parent = previewScroll
Instance.new("UICorner", pIcon).CornerRadius = UDim.new(0, 10)
local pIconStroke = Instance.new("UIStroke")
pIconStroke.Color = Color3.fromRGB(255, 130, 20)
pIconStroke.Thickness = 2.5
pIconStroke.Parent = pIcon

local pName = Instance.new("TextLabel")
pName.Name = "PreviewName"
pName.Size = UDim2.new(1, -100, 0, 26)
pName.Position = UDim2.new(0, 96, 0, 16)
pName.BackgroundTransparency = 1
pName.Font = Enum.Font.GothamBlack
pName.TextSize = 20
pName.TextColor3 = Color3.fromRGB(255, 255, 255)
pName.TextXAlignment = Enum.TextXAlignment.Left
pName.Text = "NARUTO UZUMAKI"
pName.Parent = previewScroll

local pTitle = Instance.new("TextLabel")
pTitle.Name = "PreviewTitle"
pTitle.Size = UDim2.new(1, -100, 0, 18)
pTitle.Position = UDim2.new(0, 96, 0, 44)
pTitle.BackgroundTransparency = 1
pTitle.Font = Enum.Font.GothamMedium
pTitle.TextSize = 12
pTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
pTitle.TextXAlignment = Enum.TextXAlignment.Left
pTitle.Text = "Hero of the Hidden Leaf • RUSHDOWN"
pTitle.Parent = previewScroll

local pQuote = Instance.new("TextLabel")
pQuote.Name = "PreviewQuote"
pQuote.Size = UDim2.new(1, -32, 0, 32)
pQuote.Position = UDim2.new(0, 16, 0, 92)
pQuote.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
pQuote.BackgroundTransparency = 0.5
pQuote.Font = Enum.Font.GothamMedium
pQuote.TextSize = 12
pQuote.RichText = true
pQuote.TextColor3 = Color3.fromRGB(220, 220, 230)
pQuote.TextWrapped = true
pQuote.Text = '"I never go back on my word! That\'s my ninja way!"'
pQuote.Parent = previewScroll
Instance.new("UICorner", pQuote).CornerRadius = UDim.new(0, 6)

-- STATS SECTION (4 Horizontal Bars)
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, -32, 0, 110)
statsContainer.Position = UDim2.new(0, 16, 0, 132)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = previewScroll

local statFills: { [string]: Frame } = {}
local statLabels: { [string]: TextLabel } = {}

local statDefs = {
	{ key = "Speed",   label = "SPEED",   y = 0,   color = Color3.fromRGB(0, 255, 200) },
	{ key = "Power",   label = "POWER",   y = 28,  color = Color3.fromRGB(255, 80, 80) },
	{ key = "Defense", label = "DEFENSE", y = 56,  color = Color3.fromRGB(255, 215, 0) },
	{ key = "Jutsu",   label = "JUTSU",   y = 84,  color = Color3.fromRGB(180, 100, 255) },
}

for _, def in ipairs(statDefs) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.Position = UDim2.new(0, 0, 0, def.y)
	row.BackgroundTransparency = 1
	row.Parent = statsContainer

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 75, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(180, 190, 210)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = def.label
	lbl.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -120, 0, 10)
	barBg.Position = UDim2.new(0, 80, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
	barBg.Parent = row
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = def.color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)
	statFills[def.key] = barFill

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(0, 35, 1, 0)
	valLbl.Position = UDim2.new(1, -35, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = Enum.Font.GothamBlack
	valLbl.TextSize = 12
	valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Text = "85"
	valLbl.Parent = row
	statLabels[def.key] = valLbl
end

-- SKILLS ARSENAL BOX
local skillsBox = Instance.new("Frame")
skillsBox.Name = "SkillsBox"
skillsBox.Size = UDim2.new(1, -32, 0, 84)
skillsBox.Position = UDim2.new(0, 16, 0, 248)
skillsBox.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
skillsBox.BackgroundTransparency = 0.4
skillsBox.Parent = previewScroll
Instance.new("UICorner", skillsBox).CornerRadius = UDim.new(0, 8)

local sListLayout = Instance.new("UIListLayout")
sListLayout.Padding = UDim.new(0, 3)
sListLayout.Parent = skillsBox

local function createSkillRow(prefix: string, name: string): TextLabel
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -12, 0, 18)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 11
	row.TextColor3 = Color3.fromRGB(200, 210, 230)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = "  " .. prefix .. ": " .. name
	row.Parent = skillsBox
	return row
end

local m1SkillLbl   = createSkillRow("🥊 Combo M1", "Shinobi Taijutsu Barrage")
local sweepSkillLbl = createSkillRow("⚡ Sweep", "Uzumaki Low Sweep")
local assistSkillLbl = createSkillRow("👥 Assist", "Shadow Clone Rasengan")
local ultSkillLbl  = createSkillRow("💥 Ultimate", "Wind Style: Rasenshuriken")

-- BOTTOM ACTION BUTTON (Docked at base of PreviewPanel)
local selectBtn = Instance.new("TextButton")
selectBtn.Name = "SelectFighterButton"
selectBtn.Size = UDim2.new(1, -32, 0, 42)
selectBtn.Position = UDim2.new(0, 16, 1, -48)
selectBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
selectBtn.Font = Enum.Font.GothamBlack
selectBtn.TextSize = 14
selectBtn.TextColor3 = Color3.fromRGB(12, 18, 24)
selectBtn.Text = "⚔️ PILIH KARAKTER SHINOBI (SELECT)"
selectBtn.Parent = previewPanel
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 8)

local selStroke = Instance.new("UIStroke")
selStroke.Color = Color3.fromRGB(255, 255, 255)
selStroke.Thickness = 1.5
selStroke.Parent = selectBtn

-- =========================================================
-- ROSTER CARD CREATION & SELECTION LOGIC
-- =========================================================
local cardStrokes: { [string]: UIStroke } = {}
local cardFrames: { [string]: TextButton } = {}

local function updatePreview(charId: string)
	local char = CombatConfig.Characters[charId]
	if not char then return end

	previewSelectedId = charId

	-- Update preview text & visuals
	pIcon.Text = char.Icon
	pIconStroke.Color = char.PrimaryColor
	pName.Text = string.upper(char.Name)
	pName.TextColor3 = char.PrimaryColor
	pTitle.Text = char.Title .. " • " .. string.upper(char.Archetype)
	pTitle.TextColor3 = char.AccentColor
	pQuote.Text = '"' .. char.Quote .. '"'

	-- Update Stats
	local stats = char.Stats or { Speed = 80, Power = 80, Defense = 80, Jutsu = 80 }
	for key, fill in pairs(statFills) do
		local val = stats[key] or 80
		local ratio = math.clamp(val / 100, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ratio, 0, 1, 0),
		}):Play()
		if statLabels[key] then
			statLabels[key].Text = tostring(val)
		end
	end

	-- Update Skill Names
	m1SkillLbl.Text    = "  🥊 Combo [J]: " .. char.M1Name
	sweepSkillLbl.Text = "  ⚡ Sweep [S+J]: " .. char.SweepName
	assistSkillLbl.Text = "  👥 Assist [U]: " .. char.AssistName
	ultSkillLbl.Text   = "  💥 Ultimate [I]: " .. char.UltimateName

	-- Update Button State
	if charId == currentSelectedId then
		selectBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
		selectBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		selectBtn.Text = "✓ KARAKTER TERPILIH (CURRENT)"
	else
		selectBtn.BackgroundColor3 = char.PrimaryColor
		selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectBtn.Text = "⚔️ PILIH " .. string.upper(char.Name) .. " (SELECT)"
	end

	-- Highlight active card
	for id, stroke in pairs(cardStrokes) do
		if id == charId then
			stroke.Color = Color3.fromRGB(255, 215, 0)
			stroke.Thickness = 3
		else
			stroke.Color = Color3.fromRGB(45, 55, 75)
			stroke.Thickness = 1.5
		end
	end
end

-- Build Card for each fighter
local charOrder = { "Naruto", "Sasuke", "Luffy", "Zoro", "Killua" }
for idx, charId in ipairs(charOrder) do
	local char = CombatConfig.Characters[charId]
	if not char then continue end

	local card = Instance.new("TextButton")
	card.Name = "Card_" .. charId
	card.Size = UDim2.new(1, -6, 0, 74)
	card.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
	card.BackgroundTransparency = 0.2
	card.Text = ""
	card.AutoButtonColor = false
	card.LayoutOrder = idx
	card.Parent = rosterList
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(45, 55, 75)
	cStroke.Thickness = 1.5
	cStroke.Parent = card
	cardStrokes[charId] = cStroke
	cardFrames[charId] = card

	-- Fighter Icon
	local cIcon = Instance.new("TextLabel")
	cIcon.Size = UDim2.new(0, 50, 0, 50)
	cIcon.Position = UDim2.new(0, 12, 0.5, 0)
	cIcon.AnchorPoint = Vector2.new(0, 0.5)
	cIcon.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	cIcon.Font = Enum.Font.GothamBold
	cIcon.TextSize = 26
	cIcon.Text = char.Icon
	cIcon.Parent = card
	Instance.new("UICorner", cIcon).CornerRadius = UDim.new(0, 8)

	-- Name
	local cName = Instance.new("TextLabel")
	cName.Size = UDim2.new(1, -74, 0, 20)
	cName.Position = UDim2.new(0, 70, 0, 14)
	cName.BackgroundTransparency = 1
	cName.Font = Enum.Font.GothamBlack
	cName.TextSize = 14
	cName.TextColor3 = Color3.fromRGB(255, 255, 255)
	cName.TextXAlignment = Enum.TextXAlignment.Left
	cName.Text = char.Name
	cName.Parent = card

	-- Archetype Tag
	local cTag = Instance.new("TextLabel")
	cTag.Size = UDim2.new(0, 90, 0, 18)
	cTag.Position = UDim2.new(0, 70, 0, 38)
	cTag.BackgroundColor3 = char.PrimaryColor
	cTag.BackgroundTransparency = 0.3
	cTag.Font = Enum.Font.GothamBold
	cTag.TextSize = 10
	cTag.TextColor3 = Color3.fromRGB(255, 255, 255)
	cTag.Text = string.upper(char.Archetype)
	cTag.Parent = card
	Instance.new("UICorner", cTag).CornerRadius = UDim.new(0, 4)

	-- Click handler
	card.MouseButton1Click:Connect(function()
		playUiSound("volume_slider.ogg", 1.2)
		updatePreview(charId)
	end)
end

-- =========================================================
-- CONFIRM SELECTION
-- =========================================================
local function selectCharacter(charId: string)
	local char = CombatConfig.Characters[charId]
	if not char then return end

	currentSelectedId = charId
	playUiSound("action_footsteps_plastic.mp3", 1.5)

	-- Fire to server
	evCharSelect:FireServer(charId)

	-- Visual feedback
	updatePreview(charId)

	-- Close modal smoothly after short delay
	task.delay(0.3, function()
		screenGui.Enabled = false
		isOpen = false
	end)
end

selectBtn.MouseButton1Click:Connect(function()
	selectCharacter(previewSelectedId)
end)

-- =========================================================
-- MODAL TOGGLE & CONTROLS
-- =========================================================
local function toggleRoster(state: boolean?)
	if state ~= nil then
		isOpen = state
	else
		isOpen = not isOpen
	end

	screenGui.Enabled = isOpen
	if isOpen then
		playUiSound("volume_slider.ogg", 1.0)
		local current = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
		currentSelectedId = tostring(current)
		updatePreview(currentSelectedId)

		-- Animated Entrance
		mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
		mainFrame.BackgroundTransparency = 1
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0.1,
		}):Play()
	end
end

closeBtn.MouseButton1Click:Connect(function()
	toggleRoster(false)
end)

-- Keybind [B] to toggle roster
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleRoster()
	end
end)

-- Listen to Lobby Pedestal remote trigger
evOpenRoster.OnClientEvent:Connect(function()
	toggleRoster(true)
end)

-- Listen to character changes replicated from server
evCharSelect.OnClientEvent:Connect(function(player: Player, charId: string, charData: any)
	if player == LocalPlayer then
		currentSelectedId = charId
		updatePreview(charId)
	end
end)

-- Expose to global/other scripts via bindable if needed
local bindable = Instance.new("BindableFunction")
bindable.Name = "ToggleRosterUI"
bindable.OnInvoke = function(state)
	toggleRoster(state)
	return isOpen
end
bindable.Parent = screenGui

print("[StormCharacterSelectHUD] ✅ Shinobi Roster UI loaded. Press [B] or visit Lobby Pedestal.")
]=====]
    installScript('StormCharacterSelectHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

print('====================================================')
print('🎉 [STORM CLASH v2.0] INSTALLED SUCCESSFULLY!')
print('Controls (PC / Laptop):')
print('  • W, A, S, D: Orbital Movement & 3D Strafing')
print('  • J / Left-Click: 4-Hit Attack Combo String')
print('  • S + J: Low Shinobi Sweep (Pierces High Guard)')
print('  • K / F (Hold): Standing High/Mid Guard')
print('  • S + K (Hold): Crouched Low Guard')
print('  • Just-Frame K (180ms): Tekken Perfect Parry Stagger Counter')
print('  • L / Double-Tap Space: Naruto Storm 4 Homing Ninja Dash')
print('  • Double-Tap A / D: Tekken 3D Sidestep Evasion')
print('  • I / T: Summon Assist Partner (Jutsu Projectile Strike)')
print('  • U / G: Storm 4 Leader Swap')
print('  • O: Ultimate Secret Technique (Cinematic Finisher when Chakra=100%)')
print('  • C: Charge Chakra / Energy (Hold to Charge)')
print('  • Z: Toggle Dynamic Dual-Target Lock-On Camera')
print('  • Tekken Awakening / Rage: Auto-triggers when HP < 30% (+25% Damage Boost)')
print('Multi-Platform & Worldwide Features:')
print('  • ⚔️ Procedural Anime Katana Model with Glowing Slash Trail')
print('  • 🥋 100% Asset-Independent Procedural Anime Motor6D Combat Animations')
print('  • 📊 Storm 4 Dual Top Fighting Healthbars & 99s Round Announcer')
print('  • 📱 Mobile Touch Controls HUD (Right-Thumb Action Cluster)')
print('  • 🎮 Gamepad Support (PlayStation & Xbox Controller)')
print('  • ⚡ Low-GFX / 60FPS Performance Mode Toggle')
print('====================================================')