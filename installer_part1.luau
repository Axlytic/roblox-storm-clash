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
-- CombatConfig.luau
-- Shared configuration for Naruto Storm 4 Camera + Movement + Tekken Defense + Jump Force MUGEN 14 Architecture

local CombatConfig = {}

-- =========================================================
-- 0. NARUTO STORM KEYBOARD & CONTROLLER MAPPING
-- =========================================================
CombatConfig.Controls = {
	MoveForward   = Enum.KeyCode.W,         -- Maju
	MoveLeft      = Enum.KeyCode.A,         -- Kiri
	MoveBackward  = Enum.KeyCode.S,         -- Mundur
	MoveRight     = Enum.KeyCode.D,         -- Kanan
	PunchMelee    = Enum.KeyCode.J,         -- Pukulan Biasa (4-Hit Attack Combo)
	LowSweep      = Enum.KeyCode.K,         -- Serangan Bawah (Low Sweep Attack)
	RangedJutsu   = Enum.KeyCode.L,         -- Serangan Jarak Jauh (Anime Ranged Projectile)
	ChakraEnergy  = Enum.KeyCode.I,         -- Mengisi Energi / Hold untuk Ultimate Ougi
	GuardDefense  = Enum.KeyCode.F,         -- Pertahanan / Tekken High & Low Guard
	NinjaDash     = Enum.KeyCode.LeftShift, -- Ninja Dash (also Q / Double-tap Space)
}

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
		RangedSkill = {
			Name = "Wind Style: Rasen-Shuriken",
			Damage = 20,
			Speed = 110,
			Cooldown = 1.6,
			Lifetime = 2.2,
			Color = Color3.fromRGB(0, 235, 255),
			Shape = "Disc",
			Sound = "rbxasset://sounds/action_whoosh.mp3",
			Icon = "🌀",
		},
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
		RangedSkill = {
			Name = "Fire Style: Fireball Jutsu (Goukakyuu)",
			Damage = 22,
			Speed = 95,
			Cooldown = 1.8,
			Lifetime = 2.5,
			Color = Color3.fromRGB(255, 75, 20),
			Shape = "Ball",
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Icon = "🔥",
		},
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
		RangedSkill = {
			Name = "Gum-Gum Pistol (Gomu Gomu no Pistol)",
			Damage = 18,
			Speed = 135,
			Cooldown = 1.4,
			Lifetime = 1.2,
			Color = Color3.fromRGB(245, 185, 140),
			Shape = "Fist",
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Icon = "👊",
		},
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
		RangedSkill = {
			Name = "36 Pound Phoenix (Flying Slash)",
			Damage = 21,
			Speed = 115,
			Cooldown = 1.7,
			Lifetime = 2.0,
			Color = Color3.fromRGB(40, 255, 110),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "⚔️",
		},
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
		RangedSkill = {
			Name = "Thunderbolt: Narukami Strike",
			Damage = 20,
			Speed = 145,
			Cooldown = 1.5,
			Lifetime = 1.4,
			Color = Color3.fromRGB(150, 230, 255),
			Shape = "Bolt",
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Icon = "⚡",
		},
		AssistName = "Thunderbolt Striker",
		UltimateName = "Godspeed: Whirlwind Execution",
		Quote = "If I don't defeat you right now... I can't protect anyone!",
	},
}

return CombatConfig
]=====]
    installScript('CombatConfig', 'ModuleScript', game:GetService('ReplicatedStorage'), src)
end

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

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

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
local evRanged     = ensureRemote("RangedAttackEvent")

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

-- =========================================================
-- 8. AUTHENTIC ANIME RANGED ATTACK HANDLER ([L] Key)
-- =========================================================
evRanged.OnServerEvent:Connect(function(attacker: Player, aimDir: Vector3?, requestedCharId: string?)
	local char = attacker.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local charId = tostring(attacker:GetAttribute("SelectedCharacter") or requestedCharId or "Naruto")
	local charData = CombatConfig.Characters[charId] or CombatConfig.Characters["Naruto"]
	local skill = charData.RangedSkill or {
		Name = "Chakra Projectile",
		Damage = 18,
		Speed = 110,
		Lifetime = 2.0,
		Color = Color3.fromRGB(0, 230, 255),
	}

	local finalAimDir = if typeof(aimDir) == "Vector3" and aimDir.Magnitude > 0.1 then aimDir.Unit else root.CFrame.LookVector
	local startPos = root.Position + Vector3.new(0, 1.2, 0) + (finalAimDir * 2.5)

	-- 1. Create Anime Themed Projectile Model / Part
	local proj = Instance.new("Part")
	proj.Name = "AnimeProjectile_" .. charId
	proj.CanCollide = false
	proj.Anchored = false
	proj.Material = Enum.Material.Neon
	proj.Color = skill.Color or Color3.fromRGB(0, 230, 255)

	-- Distinct 3D mesh shaping per anime character:
	if charId == "Naruto" then
		-- Rasen-Shuriken: Aerodynamic Disc
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(0.4, 3.2, 3.2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, 0, math.rad(90))
	elseif charId == "Sasuke" then
		-- Goukakyuu Fireball: Giant Blazing Sphere
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(3.0, 3.0, 3.0)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif charId == "Luffy" then
		-- Gum-Gum Pistol: Elastic Fist Cylinder
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(3.2, 1.6, 1.6)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, math.rad(90), 0)
	elseif charId == "Zoro" then
		-- 36 Pound Phoenix: Vertical Flying Wind Blade
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.3, 3.8, 2.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif charId == "Killua" then
		-- Thunderbolt Narukami: Piercing Lightning Wedge
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.8, 0.8, 3.2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	else
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(2, 2, 2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	end

	-- 2. Anime Particle Emitter
	local att = Instance.new("Attachment", proj)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(skill.Color or Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(1.4, 0)
	pe.Rate = 50
	pe.Speed = NumberRange.new(3, 8)
	pe.Lifetime = NumberRange.new(0.25, 0.45)
	pe.Parent = att

	-- 3. High-Speed Propulsion
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = finalAimDir * (skill.Speed or 110)
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Parent = proj

	proj.Parent = Workspace
	Debris:AddItem(proj, skill.Lifetime or 2.2)

	-- 4. Authoritative Collision & Damage
	local hitProcessed = false
	proj.Touched:Connect(function(hit)
		if hitProcessed then return end
		local targetModel = hit:FindFirstAncestorOfClass("Model")
		if not targetModel or targetModel == char or targetModel.Name:find("AssistStriker") then
			return
		end

		local tHum = targetModel:FindFirstChildOfClass("Humanoid")
		local tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not tHum or not tRoot or tHum.Health <= 0 then
			return
		end

		hitProcessed = true

		-- Guard Check for Defender
		local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
		local targetState = targetPlayer and playerCombatStates[targetPlayer.UserId]
		local isGuarding = false
		if targetState then
			isGuarding = targetState.isBlocking and targetState.blockType == "High"
		elseif targetModel:GetAttribute("DummyGuardMode") == "High" then
			isGuarding = true
		end

		local isAwakening = attacker:GetAttribute("IsAwakening") == true
		local baseDmg = skill.Damage or 20
		local finalDmg = if isAwakening then math.floor(baseDmg * 1.25) else baseDmg

		if isGuarding then
			-- Projectile Guarded! Reduced chip damage
			local chipDmg = math.max(2, math.floor(finalDmg * 0.25))
			tHum:TakeDamage(chipDmg)
			spawnFloatingText(tRoot.Position, string.format("🛡️ BLOCKED (-%d)", chipDmg), Color3.fromRGB(0, 220, 255))
			tRoot.AssemblyLinearVelocity = finalAimDir * 12
		else
			-- Clean Anime Jutsu Hit!
			tHum:TakeDamage(finalDmg)
			local hitColor = skill.Color or Color3.fromRGB(255, 120, 30)
			spawnFloatingText(tRoot.Position, string.format("💥 %s -%d!", skill.Name, finalDmg), hitColor)
			tRoot.AssemblyLinearVelocity = finalAimDir * 42 + Vector3.new(0, 8, 0)
		end

		-- Hit burst particle
		pcall(function()
			local burst = Instance.new("Part")
			burst.Shape = Enum.PartType.Ball
			burst.Size = Vector3.new(3, 3, 3)
			burst.Position = proj.Position
			burst.Material = Enum.Material.Neon
			burst.Color = skill.Color or Color3.fromRGB(255, 200, 50)
			burst.Anchored = true
			burst.CanCollide = false
			burst.Parent = Workspace
			TweenService:Create(burst, TweenInfo.new(0.22), {
				Size = Vector3.new(5, 5, 5),
				Transparency = 1,
			}):Play()
			Debris:AddItem(burst, 0.25)
		end)

		proj:Destroy()
	end)
end)

print("[CombatServerMaster] ✅ Authoritative Combat Server Master fully initialized.")
]=====]
    installScript('CombatServerMaster', 'Script', game:GetService('ServerScriptService'), src)
end

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

do
    local src = [=====[--!strict
-- StormCharacterMorphServer.luau
-- SERVER MODULE: 3D Anime Character Visual Morph & Cosmetic Engine
-- Transforms standard R15 characters into unmistakable anime fighters:
--   • Naruto Uzumaki: Spiky Yellow Hair + Leaf Shinobi Headband + Orange Jumpsuit + Cheek Whiskers
--   • Sasuke Uchiha: Spiky Dark Hair & Bangs + High Collar + Purple Shimenawa Rope + Sharingan Eyes
--   • Monkey D. Luffy: 3D Straw Hat (Mugiwara) + Red Open Vest + Chest X-Scar + Blue Denim Shorts
--   • Roronoa Zoro: Green Crop Hair + Arm Bandana + Emerald Haramaki + Santoryu (3 Hip Katanas)
--   • Killua Zoldyck: Silver-White Wild Hair + Navy Turtle-Neck & White V-Neck + Electric Godspeed Aura

local StormCharacterMorphServer = {}

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Helper: Create a welded accessory part
local function addMorphPart(parent: Model, part0: BasePart, offset: CFrame, size: Vector3, color: Color3, material: Enum.Material, partType: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = "MorphPart"
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = partType or Enum.PartType.Block
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = false

	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = p
	w.Parent = p

	p.CFrame = part0.CFrame * offset
	p.Parent = parent
	return p
end

-- Helper: Create a wedge part
local function addMorphWedge(parent: Model, part0: BasePart, offset: CFrame, size: Vector3, color: Color3): WedgePart
	local wPart = Instance.new("WedgePart")
	wPart.Name = "MorphWedge"
	wPart.Size = size
	wPart.Color = color
	wPart.Material = Enum.Material.SmoothPlastic
	wPart.CanCollide = false
	wPart.Massless = true
	wPart.CastShadow = false

	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = wPart
	w.Parent = wPart

	wPart.CFrame = part0.CFrame * offset
	wPart.Parent = parent
	return wPart
end

-- =========================================================
-- 1. NARUTO UZUMAKI VISUAL MORPH
-- =========================================================
local function morphNaruto(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftLeg = (char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairColor = Color3.fromRGB(255, 215, 0) -- Blonde/Yellow
	local headbandBlue = Color3.fromRGB(22, 42, 92)
	local plateSilver = Color3.fromRGB(215, 220, 230)
	local jumpsuitOrange = Color3.fromRGB(245, 115, 15)

	-- 1. Spiky Anime Hair Cluster
	-- Center Top Spike
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, -0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.6, 0.85, 0.7), hairColor)
	-- Left & Right Upper Spikes
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(-25), math.rad(25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	-- Back Spikes
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.5) * CFrame.Angles(math.rad(-30), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairColor)
	-- Sideburns
	addMorphPart(morphModel, head, CFrame.new(-0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor, Enum.Material.SmoothPlastic)
	addMorphPart(morphModel, head, CFrame.new(0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor, Enum.Material.SmoothPlastic)

	-- 2. Konoha Forehead Protector Headband
	addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.56), Vector3.new(1.25, 0.38, 0.12), headbandBlue, Enum.Material.Fabric)
	-- Metal Plate
	local plate = addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.63), Vector3.new(0.72, 0.28, 0.05), plateSilver, Enum.Material.Metal)
	-- Engraved Spiral Emblem
	local emblem = Instance.new("SurfaceGui")
	emblem.Face = Enum.NormalId.Front
	local symLbl = Instance.new("TextLabel")
	symLbl.Size = UDim2.fromScale(1, 1)
	symLbl.BackgroundTransparency = 1
	symLbl.Font = Enum.Font.GothamBlack
	symLbl.TextSize = 14
	symLbl.TextColor3 = Color3.fromRGB(40, 45, 55)
	symLbl.Text = "🌀"
	symLbl.Parent = emblem
	emblem.Parent = plate

	-- 3. Orange Track Jacket with Blue Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.35, 1.15), headbandBlue, Enum.Material.SmoothPlastic) -- Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 1.4, 1.05), jumpsuitOrange, Enum.Material.SmoothPlastic)

	-- 4. Thigh Bandage & Ninja Pouch
	if rightLeg then
		addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.3, 0), Vector3.new(1.05, 0.5, 1.05), Color3.fromRGB(240, 240, 245), Enum.Material.Fabric) -- White bandage
		addMorphPart(morphModel, rightLeg, CFrame.new(0.55, 0.3, 0), Vector3.new(0.2, 0.35, 0.35), Color3.fromRGB(40, 30, 25), Enum.Material.Leather) -- Holster pouch
	end
end

-- =========================================================
-- 2. SASUKE UCHIHA VISUAL MORPH
-- =========================================================
local function morphSasuke(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	if not head or not upperTorso then return end

	local hairDark = Color3.fromRGB(18, 22, 32)
	local tunicWhite = Color3.fromRGB(235, 238, 245)
	local ropePurple = Color3.fromRGB(145, 65, 215)
	local sashBlue = Color3.fromRGB(30, 45, 80)

	-- 1. Winged Spiky Dark Hair & Long Front Bangs
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0.1) * CFrame.Angles(math.rad(-20), math.rad(180), 0), Vector3.new(0.9, 0.85, 0.8), hairDark)
	-- Winged Side Spikes
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(-150), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(150), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	-- Front Bangs framing cheeks
	addMorphPart(morphModel, head, CFrame.new(-0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(-10)), Vector3.new(0.2, 0.75, 0.15), hairDark, Enum.Material.SmoothPlastic)
	addMorphPart(morphModel, head, CFrame.new(0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(10)), Vector3.new(0.2, 0.75, 0.15), hairDark, Enum.Material.SmoothPlastic)

	-- 2. High Stand-Up Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0.45) * CFrame.Angles(math.rad(12), 0, 0), Vector3.new(1.5, 0.65, 0.15), tunicWhite, Enum.Material.Fabric)

	-- 3. Purple Shimenawa Knotted Rope Belt & Blue Apron Sash
	if lowerTorso then
		-- Blue Apron Sash
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, -0.3, 0), Vector3.new(2.1, 0.85, 1.15), sashBlue, Enum.Material.Fabric)
		-- Thick Purple Rope Ring
		local rope = addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0), Vector3.new(2.25, 0.35, 1.25), ropePurple, Enum.Material.Fabric)
		-- Rope Bow Knot at back
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0.7), Vector3.new(0.8, 0.5, 0.4), ropePurple, Enum.Material.Fabric)
	end

	-- 4. Sharingan Eye Aura Particles
	local eyeAura = Instance.new("ParticleEmitter")
	eyeAura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	eyeAura.Color = ColorSequence.new(Color3.fromRGB(255, 30, 30), Color3.fromRGB(180, 0, 0))
	eyeAura.Size = NumberSequence.new(0.25, 0)
	eyeAura.Rate = 12
	eyeAura.Speed = NumberRange.new(0.5, 1.5)
	eyeAura.Lifetime = NumberRange.new(0.4, 0.7)
	eyeAura.Parent = head
	eyeAura.Name = "SharinganAura"
end

-- =========================================================
-- 3. MONKEY D. LUFFY VISUAL MORPH
-- =========================================================
local function morphLuffy(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftLeg = (char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local strawYellow = Color3.fromRGB(230, 190, 95)
	local ribbonRed = Color3.fromRGB(220, 25, 25)
	local vestRed = Color3.fromRGB(225, 30, 30)
	local denimBlue = Color3.fromRGB(45, 90, 175)
	local furWhite = Color3.fromRGB(250, 250, 255)
	local skinTone = Color3.fromRGB(255, 220, 185)

	-- 1. Authentic 3D Straw Hat (Mugiwara)
	-- Wide Brim (Cylinder)
	local brim = addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.08, 3.2, 3.2), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)
	-- Red Ribbon Band
	local ribbon = addMorphPart(morphModel, head, CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.18, 1.85, 1.85), ribbonRed, Enum.Material.Fabric, Enum.PartType.Cylinder)
	-- Dome Crown
	local dome = addMorphPart(morphModel, head, CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 1.8, 1.8), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)

	-- 2. Messy Black Anime Hair beneath hat
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(-20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))

	-- 3. Open Red Sleeveless Vest
	-- Left & Right Vest panels (leaving center chest exposed)
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0.52), Vector3.new(1.8, 1.45, 0.15), vestRed, Enum.Material.Fabric) -- Back of vest

	-- 4. Iconic Chest X-Scar
	local scar1 = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30), Enum.Material.SmoothPlastic)
	local scar2 = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30), Enum.Material.SmoothPlastic)

	-- 5. Denim Shorts with White Fur Cuffs & Yellow Sash
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.25, 0), Vector3.new(2.15, 0.3, 1.2), Color3.fromRGB(245, 205, 30), Enum.Material.Fabric) -- Yellow Sash
	end
	if leftLeg then
		addMorphPart(morphModel, leftLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric)
	end
	if rightLeg then
		addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric)
	end
end

-- =========================================================
-- 4. RORONOA ZORO VISUAL MORPH
-- =========================================================
local function morphZoro(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local marimoGreen = Color3.fromRGB(45, 175, 75)
	local haramakiGreen = Color3.fromRGB(25, 95, 45)
	local coatGreen = Color3.fromRGB(18, 60, 32)
	local bandanaBlack = Color3.fromRGB(20, 22, 26)

	-- 1. Emerald Green Crop Hair (Marimo)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.35, 0.45, 1.35), marimoGreen, Enum.Material.Grass)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, -0.15) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.8, 0.4, 0.8), marimoGreen)

	-- 2. Black Pirate Bandana tied around Left Bicep
	if leftArm then
		addMorphPart(morphModel, leftArm, CFrame.new(0, 0.2, 0), Vector3.new(1.15, 0.4, 1.15), bandanaBlack, Enum.Material.Fabric)
		-- Knot tail
		addMorphPart(morphModel, leftArm, CFrame.new(-0.6, 0.1, 0), Vector3.new(0.2, 0.5, 0.3), bandanaBlack, Enum.Material.Fabric)
	end

	-- 3. Emerald Green Haramaki (Belly Warmer)
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 0.95, 1.15), haramakiGreen, Enum.Material.Fabric)
	end

	-- 4. Santoryu (3 Katana Sheaths on Right Hip)
	-- Sword 1: Wado Ichimonji (White)
	local s1 = addMorphPart(morphModel, upperTorso, CFrame.new(1.1, -0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-135)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(245, 245, 250), Enum.Material.SmoothPlastic)
	-- Sword 2: Sandai Kitetsu (Red)
	local s2 = addMorphPart(morphModel, upperTorso, CFrame.new(1.15, -0.5, 0.4) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(190, 30, 30), Enum.Material.SmoothPlastic)
	-- Sword 3: Shusui (Black & Gold)
	local s3 = addMorphPart(morphModel, upperTorso, CFrame.new(1.2, -0.4, 0.6) * CFrame.Angles(0, 0, math.rad(-145)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(24, 24, 28), Enum.Material.SmoothPlastic)

	-- 5. Left Eye Scar Line
	addMorphPart(morphModel, head, CFrame.new(-0.25, 0.08, -0.56) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.04, 0.35, 0.02), Color3.fromRGB(80, 40, 40), Enum.Material.SmoothPlastic)
end

-- =========================================================
-- 5. KILLUA ZOLDYCK VISUAL MORPH
-- =========================================================
local function morphKillua(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftHand = (char:FindFirstChild("LeftHand") or char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSilver = Color3.fromRGB(245, 245, 255)
	local turtleNavy = Color3.fromRGB(25, 30, 50)
	local shirtWhite = Color3.fromRGB(240, 242, 248)
	local shortsViolet = Color3.fromRGB(40, 35, 65)

	-- 1. Silver-White Wild Spiky Assassin Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(10), 0, 0), Vector3.new(0.85, 0.9, 0.8), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(-0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-30), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.55) * CFrame.Angles(math.rad(-25), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairSilver)
	-- Fluffy front bangs
	addMorphWedge(morphModel, head, CFrame.new(-0.25, 0.45, -0.55) * CFrame.Angles(math.rad(35), 0, math.rad(-15)), Vector3.new(0.35, 0.5, 0.25), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.25, 0.45, -0.55) * CFrame.Angles(math.rad(35), 0, math.rad(15)), Vector3.new(0.35, 0.5, 0.25), hairSilver)

	-- 2. Navy Blue Turtle-Neck Undershirt with White V-Neck Skater Shirt
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.65, 0.4, 1.05), turtleNavy, Enum.Material.Fabric) -- High turtle-neck
	addMorphPart(morphModel, upperTorso, CFrame.new(0, -0.05, 0), Vector3.new(2.1, 1.35, 1.1), shirtWhite, Enum.Material.Fabric) -- Baggy white shirt

	-- 3. Indigo Assassin Shorts
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 0.9, 1.05), shortsViolet, Enum.Material.Fabric)
	end

	-- 4. Godspeed Electric Lightning Sparks (Active aura on fists)
	local function addLightning(hand: BasePart)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 240)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		sparks.Size = NumberSequence.new(0.3, 0)
		sparks.Rate = 18
		sparks.Speed = NumberRange.new(1, 3)
		sparks.Lifetime = NumberRange.new(0.2, 0.45)
		sparks.Name = "GodspeedSparks"
		sparks.Parent = hand
	end
	if leftHand then addLightning(leftHand) end
	if rightHand then addLightning(rightHand) end
end

-- =========================================================
-- MASTER MORPH DISPATCHER
-- =========================================================
function StormCharacterMorphServer.applyMorph(char: Model, charId: string)
	if not char then return end

	-- 1. Remove previous morph
	local oldMorph = char:FindFirstChild("AnimeMorph")
	if oldMorph then oldMorph:Destroy() end

	-- Remove any old particle effects attached to limbs
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("ParticleEmitter") and (desc.Name == "SharinganAura" or desc.Name == "GodspeedSparks") then
			desc:Destroy()
		end
	end

	-- 2. Hide default Roblox accessories (hats/hair) so they don't clash with anime hair
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle") :: BasePart?
			if handle then
				handle.Transparency = 1
			end
		end
	end

	-- 3. Create fresh Morph Container Model
	local morphModel = Instance.new("Model")
	morphModel.Name = "AnimeMorph"

	-- 4. Apply Character-Specific Anime Sculpt & Clothing
	if charId == "Naruto" then
		morphNaruto(char, morphModel)
	elseif charId == "Sasuke" then
		morphSasuke(char, morphModel)
	elseif charId == "Luffy" then
		morphLuffy(char, morphModel)
	elseif charId == "Zoro" then
		morphZoro(char, morphModel)
	elseif charId == "Killua" then
		morphKillua(char, morphModel)
	end

	morphModel.Parent = char
	print(string.format(">> [AnimeMorph] Successfully morphed %s into 3D %s! <<", char.Name, charId))
end

return StormCharacterMorphServer
]=====]
    installScript('StormCharacterMorphServer', 'ModuleScript', game:GetService('ServerScriptService'), src)
end

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
local ServerScriptService = game:GetService("ServerScriptService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local StormCharacterMorphServer = require(ServerScriptService:WaitForChild("StormCharacterMorphServer")) :: any

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

-- Forward declaration
local applyCharacter: (player: Player, charId: string) -> ()

-- =========================================================
-- CREATE 3D ANIME DISPLAY MANNEQUIN
-- =========================================================
local function createAnimeMannequin(parent: Instance, pos: Vector3, charId: string)
	local charData = CombatConfig.Characters[charId]
	if not charData then return end

	-- Pedestal
	local ped = Instance.new("Part")
	ped.Name = "Pedestal_" .. charId
	ped.Shape = Enum.PartType.Cylinder
	ped.Size = Vector3.new(0.8, 5, 5)
	ped.CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ped.Color = charData.PrimaryColor
	ped.Material = Enum.Material.Neon
	ped.Transparency = 0.35
	ped.Anchored = true
	ped.CanCollide = true
	ped.Parent = parent

	-- Mannequin Model
	local man = Instance.new("Model")
	man.Name = "Mannequin_" .. charId

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(pos + Vector3.new(0, 3.2, 0)) * CFrame.Angles(0, math.rad(180), 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = man
	man.PrimaryPart = root

	local upperTorso = Instance.new("Part")
	upperTorso.Name = "UpperTorso"
	upperTorso.Size = Vector3.new(1.8, 1.4, 1.0)
	upperTorso.CFrame = root.CFrame * CFrame.new(0, 0.4, 0)
	upperTorso.Color = Color3.fromRGB(240, 210, 180)
	upperTorso.Anchored = true
	upperTorso.CanCollide = false
	upperTorso.Parent = man

	local lowerTorso = Instance.new("Part")
	lowerTorso.Name = "LowerTorso"
	lowerTorso.Size = Vector3.new(1.7, 0.8, 0.9)
	lowerTorso.CFrame = root.CFrame * CFrame.new(0, -0.6, 0)
	lowerTorso.Color = Color3.fromRGB(30, 35, 45)
	lowerTorso.Anchored = true
	lowerTorso.CanCollide = false
	lowerTorso.Parent = man

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(240, 210, 180)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = man

	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftUpperArm"
	leftArm.Size = Vector3.new(0.8, 1.4, 0.8)
	leftArm.CFrame = root.CFrame * CFrame.new(-1.3, 0.3, 0)
	leftArm.Color = Color3.fromRGB(240, 210, 180)
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.Parent = man

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightUpperArm"
	rightArm.Size = Vector3.new(0.8, 1.4, 0.8)
	rightArm.CFrame = root.CFrame * CFrame.new(1.3, 0.3, 0)
	rightArm.Color = Color3.fromRGB(240, 210, 180)
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.Parent = man

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLowerLeg"
	leftLeg.Size = Vector3.new(0.8, 1.5, 0.8)
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.5, -1.5, 0)
	leftLeg.Color = Color3.fromRGB(35, 40, 50)
	leftLeg.Anchored = true
	leftLeg.CanCollide = false
	leftLeg.Parent = man

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLowerLeg"
	rightLeg.Size = Vector3.new(0.8, 1.5, 0.8)
	rightLeg.CFrame = root.CFrame * CFrame.new(0.5, -1.5, 0)
	rightLeg.Color = Color3.fromRGB(35, 40, 50)
	rightLeg.Anchored = true
	rightLeg.CanCollide = false
	rightLeg.Parent = man

	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = man

	-- Morph into authentic 3D Anime Fighter
	pcall(function()
		StormCharacterMorphServer.applyMorph(man, charId)
	end)

	-- Overhead Billboard
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 180, 0, 50)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 0.5)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = string.format("%s %s", charData.Icon, charData.Name)
	nameLbl.TextColor3 = charData.PrimaryColor
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.TextScaled = true
	nameLbl.Parent = bb

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.fromScale(1, 0.45)
	subLbl.Position = UDim2.new(0, 0, 0.5, 0)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = string.format("%s • %s", charData.Title, charData.Archetype)
	subLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
	subLbl.Font = Enum.Font.GothamBold
	subLbl.TextScaled = true
	subLbl.Parent = bb

	-- Instant Select Proximity Prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pilih " .. charData.Name
	prompt.ObjectText = "⚡ ROSTER"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = root

	prompt.Triggered:Connect(function(player)
		if applyCharacter then
			applyCharacter(player, charId)
		end
	end)

	man.Parent = parent
end

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

	-- 7. 5 3D Anime Character Mannequins standing in the Shinobi Lobby Courtyard
	local rosterList = {
		{ Id = "Naruto", Pos = LOBBY_CENTER + Vector3.new(0, 0, -22) },
		{ Id = "Sasuke", Pos = LOBBY_CENTER + Vector3.new(-12, 0, -18) },
		{ Id = "Luffy",  Pos = LOBBY_CENTER + Vector3.new(12, 0, -18) },
		{ Id = "Zoro",   Pos = LOBBY_CENTER + Vector3.new(-22, 0, -10) },
		{ Id = "Killua", Pos = LOBBY_CENTER + Vector3.new(22, 0, -10) },
	}

	for _, entry in ipairs(rosterList) do
		createAnimeMannequin(lobbyModel, entry.Pos, entry.Id)
	end

	lobbyModel.Parent = Workspace
	print(">> [LobbyManager] Shinobi Lobby Courtyard, Anime Mannequins & Gateways built successfully! <<")
end

-- =========================================================
-- CHARACTER SELECTION & APPLICATION
-- =========================================================
applyCharacter = function(player: Player, charId: string)
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

	-- 4. Apply 3D Anime Character Visual Morph (Naruto / Sasuke / Luffy / Zoro / Killua)
	pcall(function()
		StormCharacterMorphServer.applyMorph(char, charId)
	end)

	-- 5. Replicate to all clients
	evCharSelect:FireAllClients(player, charId, charData)
	print(string.format(">> [Roster] %s chose & morphed into: %s [%s]! <<", player.Name, charData.Name, charData.Archetype))
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

return 'Part 1 Installed Successfully (6 scripts)'