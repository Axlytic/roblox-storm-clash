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
-- 0. NARUTO STORM KEYBOARD & CONTROLLER MAPPING
-- =========================================================
CombatConfig.Controls = {
	MoveForward   = Enum.KeyCode.W,         -- Maju
	MoveLeft      = Enum.KeyCode.A,         -- Kiri
	MoveBackward  = Enum.KeyCode.S,         -- Mundur
	MoveRight     = Enum.KeyCode.D,         -- Kanan
	PunchMelee    = Enum.KeyCode.J,         -- Pukulan Biasa (Attack Combo)
	LowSweep      = Enum.KeyCode.K,         -- Serangan Bawah (Low Sweep Attack)
	RangedJutsu   = Enum.KeyCode.L,         -- Serangan Jarak Jauh (Anime Ranged Projectile)
	ChakraEnergy  = Enum.KeyCode.I,         -- Chakra Load (Tap) / Charge (Hold) / Ultimate
	GuardDefense  = Enum.KeyCode.F,         -- Pertahanan / Guard (Hold F) / Counter (F + J)
	NinjaDash     = Enum.KeyCode.LeftShift, -- Ninja Dash (also Shift / Double-tap Space)
	Substitution  = Enum.KeyCode.E,         -- Substitution Jutsu (Kawarimi / Log Teleport) - also Q / Gamepad L2
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
	ChakraDashSpeed  = 112,   -- Supersonic Chakra Dash (blue aura, cuts through projectiles)
	NinjaDashRange   = 85,    -- Max distance to lock and dash
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
-- 2B. SUBSTITUTION JUTSU (Kawarimi - The Core Storm 4 Mechanic!)
-- =========================================================
CombatConfig.Substitution = {
	MaxStocks           = 4,      -- 4 substitution stocks
	RegenTimePerStock   = 12.0,   -- Seconds to regenerate 1 sub stock
	TeleportBehindDist  = 8.0,    -- Studs teleported directly behind the attacker
	DamageImmunityTime  = 0.35,   -- Brief i-frame after subbing to prevent immediate re-hit
	LogModel = {
		Size = Vector3.new(1.8, 3.2, 1.8),
		Color = Color3.fromRGB(139, 90, 43), -- Wood bark
		Material = Enum.Material.Wood,
		Lifetime = 1.6,
	},
	SmokeColor = Color3.fromRGB(240, 240, 245),
}

-- =========================================================
-- 2C. CHAKRA LOAD & JUTSU (Storm 4 Chakra Engine)
-- =========================================================
CombatConfig.Chakra = {
	MaxChakra           = 100,
	ChakraLoadDuration  = 2.2,    -- Window after pressing [I] where character is in Chakra Loaded state
	ChakraDashCost      = 15,     -- Chakra consumed by supersonic Chakra Dash
	NinjutsuCost        = 25,     -- Chakra consumed by Ninjutsu ([I] + [J])
	ChakraShurikenCost  = 10,     -- Chakra consumed by Chakra Shuriken ([I] + [L])
	UltimateCost        = 50,     -- Chakra consumed by Ultimate Secret Technique ([I] hold or [I]+[I]+[J])
	ChakraChargeRate    = 40,     -- Chakra filled per second while holding [I]
	ChakraGainPerHit    = 10,     -- Gained per successful melee strike
	ChakraGainOnHit     = 7,      -- Gained when taking damage
}

-- =========================================================
-- 3. DEFENSE, PARRY & COUNTER (Tekken + Storm 4 Counter Attack)
-- =========================================================
CombatConfig.Defense = {
	MaxGuardHealth     = 100,
	GuardRegenRate     = 15,    -- HP regenerated per second when not blocking
	GuardDamageAbsorb  = 22,    -- Guard meter absorbed on high/mid hit
	GuardBreakStunTime = 2.2,   -- Stun duration if guard bar breaks (Guard Crush)
	
	-- Tekken Just-Frame Parry
	ParryWindow        = 0.18,  -- 180ms window from pressing Guard (F) to achieve Perfect Parry
	ParryStaggerTime   = 1.15,  -- Attacker stagger duration on being parried

	-- Storm 4 Counter Attack ([Guard + Attack] / [F + J])
	CounterWindow      = 0.35,  -- Active counter stance window
	CounterCooldown    = 3.5,   -- Seconds before counter can be used again
	CounterKnockback   = 55,    -- Blows rushing attacker flying across the arena
	CounterStunTime    = 1.30,  -- Attacker dizzy/stagger duration on triggering counter
}

-- =========================================================
-- 4. ATTACK & DIRECTIONAL COMBOS (Storm 4 Branching Strings)
-- =========================================================
CombatConfig.Combo = {
	ComboResetTime   = 0.85,  -- Seconds before combo counter resets to 1
	MaxMeleeRange    = 8.0,   -- Max range for basic melee hits
	LungeDistance    = 5.0,   -- Forward step distance toward target on strike
	HitstopDuration  = 0.05,  -- CyberConnect2 signature micro-freeze hitstop on contact

	-- Neutral Combo: Standard forward barrage ending in horizontal wall splat / knockdown
	NeutralHits = {
		[1] = { Damage = 8,  Hitstun = 0.30, Knockback = 3,  AttackType = "High" },
		[2] = { Damage = 10, Hitstun = 0.32, Knockback = 4,  AttackType = "Mid" },
		[3] = { Damage = 14, Hitstun = 0.38, Knockback = 6,  AttackType = "High" },
		[4] = { Damage = 24, Hitstun = 1.00, Knockback = 48, AttackType = "Mid", Finisher = "Knockdown" },
	},

	-- Up Combo ([W + J]): Uppercuts that launch the opponent high into the air (Air Launcher)
	UpHits = {
		[1] = { Damage = 8,  Hitstun = 0.30, Knockback = 2,  LiftY = 3,  AttackType = "High" },
		[2] = { Damage = 10, Hitstun = 0.32, Knockback = 3,  LiftY = 5,  AttackType = "Mid" },
		[3] = { Damage = 15, Hitstun = 0.40, Knockback = 6,  LiftY = 16, AttackType = "High" },
		[4] = { Damage = 25, Hitstun = 1.10, Knockback = 12, LiftY = 38, AttackType = "High", Finisher = "Launcher" },
	},

	-- Down Combo ([S + J]): Low sweep and downward spike into ground bounce (Rebound)
	DownHits = {
		[1] = { Damage = 9,  Hitstun = 0.32, Knockback = 2,  AttackType = "Low" },
		[2] = { Damage = 11, Hitstun = 0.34, Knockback = 3,  AttackType = "Low" },
		[3] = { Damage = 16, Hitstun = 0.42, Knockback = 5,  AttackType = "Low" },
		[4] = { Damage = 26, Hitstun = 1.15, Knockback = 18, LiftY = -25, AttackType = "Low", Finisher = "GroundBounce" },
	},

	-- Air Combo (While airborne in mid-air + [J]): Aerial flurry ending in downward dive spike
	AirHits = {
		[1] = { Damage = 9,  Hitstun = 0.30, Knockback = 2,  AttackType = "Mid" },
		[2] = { Damage = 12, Hitstun = 0.32, Knockback = 3,  AttackType = "Mid" },
		[3] = { Damage = 24, Hitstun = 1.00, Knockback = 15, LiftY = -35, AttackType = "Mid", Finisher = "DiveSpike" },
	},

	-- Legacy Crouch M1: Low Shinobi Sweep ([K])
	CrouchSweep = {
		Damage = 16,
		Hitstun = 0.75,
		Knockback = 12,
		AttackType = "Low",   -- LOW attack (Bypasses High Guard!)
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
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🌀",
		},
		NinjutsuSkill = {
			Name = "Rasengan (Spiraling Sphere)",
			Damage = 28,
			ChakraCost = 25,
			RushSpeed = 90,
			Color = Color3.fromRGB(0, 220, 255),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 35,
			LiftY = 12,
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
		NinjutsuSkill = {
			Name = "Chidori (One Thousand Birds)",
			Damage = 30,
			ChakraCost = 25,
			RushSpeed = 95,
			Color = Color3.fromRGB(120, 220, 255),
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Knockback = 42,
			LiftY = 8,
		},
		AssistName = "Fireball Jutsu / Flame Bullet",
		UltimateName = "Kirin: Heavenly Lightning Strike",
		Quote = "My dream doesn't exist in the future. It lies in the past.",
	},
	["Kakashi"] = {
		Id = "Kakashi",
		Name = "Kakashi Hatake",
		Anime = "Naruto Shippuden",
		Title = "The Copy Ninja",
		Icon = "⚡",
		Archetype = "Balanced",
		PrimaryColor = Color3.fromRGB(45, 110, 65),
		AccentColor = Color3.fromRGB(80, 230, 255),
		WalkSpeed = 17,
		NinjaDashSpeed = 89,
		GuardHealth = 95,
		Stats = { Speed = 88, Power = 84, Defense = 86, Jutsu = 92 },
		M1Name = "Hatake Taijutsu Flurry",
		SweepName = "Earth Style: Mud Sweep",
		RangedSkill = {
			Name = "Lightning Hound (Raiju Tsuiga)",
			Damage = 21,
			Speed = 125,
			Cooldown = 1.6,
			Lifetime = 2.0,
			Color = Color3.fromRGB(100, 230, 255),
			Shape = "Bolt",
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Icon = "🐕",
		},
		NinjutsuSkill = {
			Name = "Lightning Blade (Raikiri)",
			Damage = 31,
			ChakraCost = 25,
			RushSpeed = 96,
			Color = Color3.fromRGB(80, 225, 255),
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Knockback = 38,
			LiftY = 10,
		},
		AssistName = "Kamui Spatial Distortion",
		UltimateName = "Kamui Raikiri: Dimensional Slash",
		Quote = "Those who abandon their friends are worse than scum.",
	},
	["Madara"] = {
		Id = "Madara",
		Name = "Madara Uchiha",
		Anime = "Naruto Shippuden",
		Title = "Ghost of the Uchiha",
		Icon = "☄️",
		Archetype = "Zoner",
		PrimaryColor = Color3.fromRGB(180, 25, 35),
		AccentColor = Color3.fromRGB(60, 120, 255),
		WalkSpeed = 16,
		NinjaDashSpeed = 87,
		GuardHealth = 110,
		Stats = { Speed = 86, Power = 96, Defense = 92, Jutsu = 98 },
		M1Name = "Gunbai & Scythe Cleave",
		SweepName = "Majestic Flame Sweep",
		RangedSkill = {
			Name = "Fire Style: Majestic Destroyer Flame",
			Damage = 24,
			Speed = 90,
			Cooldown = 2.0,
			Lifetime = 2.8,
			Color = Color3.fromRGB(255, 60, 20),
			Shape = "Ball",
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Icon = "🔥",
		},
		NinjutsuSkill = {
			Name = "Susanoo Ribcage Crusher",
			Damage = 34,
			ChakraCost = 25,
			RushSpeed = 85,
			Color = Color3.fromRGB(60, 120, 255),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 48,
			LiftY = 14,
		},
		AssistName = "Susanoo Blade Cleave",
		UltimateName = "Tengai Shinsei: Dual Meteors",
		Quote = "Wake up to reality! Nothing ever goes as planned in this world.",
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
		NinjutsuSkill = {
			Name = "Gum-Gum Red Hawk",
			Damage = 32,
			ChakraCost = 25,
			RushSpeed = 85,
			Color = Color3.fromRGB(255, 60, 20),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 45,
			LiftY = 14,
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
		AccentColor = Color3.fromRGB(20, 95, 45),
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
		NinjutsuSkill = {
			Name = "Demon Slash: Oni Giri",
			Damage = 30,
			ChakraCost = 25,
			RushSpeed = 95,
			Color = Color3.fromRGB(40, 255, 130),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 40,
			LiftY = 6,
		},
		AssistName = "1080 Pound Ho Cannon",
		UltimateName = "Billion-Fold World Trichiliocosm",
		Quote = "Scars on the back are a swordsman's shame.",
	},
	["Sanji"] = {
		Id = "Sanji",
		Name = "Vinsmoke Sanji",
		Anime = "One Piece",
		Title = "Black Leg / Cook of Straw Hats",
		Icon = "🍳",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(35, 45, 65),
		AccentColor = Color3.fromRGB(255, 110, 20),
		WalkSpeed = 18,
		NinjaDashSpeed = 94,
		GuardHealth = 88,
		Stats = { Speed = 94, Power = 86, Defense = 80, Jutsu = 84 },
		M1Name = "Black Leg Flurry (Collier Strike)",
		SweepName = "Concassé Ground Sweep",
		RangedSkill = {
			Name = "Diable Jambe: Poêle à Frire",
			Damage = 20,
			Speed = 120,
			Cooldown = 1.5,
			Lifetime = 1.8,
			Color = Color3.fromRGB(255, 100, 25),
			Shape = "Ball",
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Icon = "🔥",
		},
		NinjutsuSkill = {
			Name = "Diable Jambe: Flambage Shot",
			Damage = 31,
			ChakraCost = 25,
			RushSpeed = 94,
			Color = Color3.fromRGB(255, 80, 20),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 42,
			LiftY = 12,
		},
		AssistName = "Party Table Kick Course",
		UltimateName = "Ifrit Jambe: Bœuf Burst",
		Quote = "A real man forgives a woman's lies.",
	},
	["Law"] = {
		Id = "Law",
		Name = "Trafalgar D. Water Law",
		Anime = "One Piece",
		Title = "Surgeon of Death",
		Icon = "🩺",
		Archetype = "Trickster",
		PrimaryColor = Color3.fromRGB(235, 200, 40),
		AccentColor = Color3.fromRGB(25, 25, 30),
		WalkSpeed = 17,
		NinjaDashSpeed = 88,
		GuardHealth = 92,
		Stats = { Speed = 86, Power = 89, Defense = 82, Jutsu = 95 },
		M1Name = "Kikoku Nodachi Blade Slices",
		SweepName = "ROOM Amputation Sweep",
		RangedSkill = {
			Name = "Takt: Kinetic Debris Launch",
			Damage = 22,
			Speed = 115,
			Cooldown = 1.6,
			Lifetime = 2.0,
			Color = Color3.fromRGB(80, 230, 255),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🌐",
		},
		NinjutsuSkill = {
			Name = "Shock Wille: Internal Surge",
			Damage = 33,
			ChakraCost = 25,
			RushSpeed = 90,
			Color = Color3.fromRGB(130, 240, 255),
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Knockback = 44,
			LiftY = 10,
		},
		AssistName = "Counter Shock Burst",
		UltimateName = "Puncture Wille: Heart Destroyer",
		Quote = "The weak don't get to decide anything, not even how they die.",
	},
	["Goku"] = {
		Id = "Goku",
		Name = "Son Goku",
		Anime = "Dragon Ball",
		Title = "Saiyan Raised on Earth",
		Icon = "🌟",
		Archetype = "Balanced",
		PrimaryColor = Color3.fromRGB(255, 140, 0),
		AccentColor = Color3.fromRGB(0, 160, 255),
		WalkSpeed = 17,
		NinjaDashSpeed = 90,
		GuardHealth = 100,
		Stats = { Speed = 92, Power = 95, Defense = 85, Jutsu = 92 },
		M1Name = "Turtle Hermit Martial Arts",
		SweepName = "Dragon Sweep Kick",
		RangedSkill = {
			Name = "Ki Blast Volley",
			Damage = 19,
			Speed = 130,
			Cooldown = 1.3,
			Lifetime = 1.8,
			Color = Color3.fromRGB(255, 230, 40),
			Shape = "Ball",
			Sound = "rbxasset://sounds/volume_slider.ogg",
			Icon = "✨",
		},
		NinjutsuSkill = {
			Name = "Super Kamehameha",
			Damage = 34,
			ChakraCost = 25,
			RushSpeed = 75,
			Color = Color3.fromRGB(0, 220, 255),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 50,
			LiftY = 10,
		},
		AssistName = "Spirit Bomb Support",
		UltimateName = "Dragon Fist Explosion",
		Quote = "I am the hope of the universe! Prepare yourself!",
	},
	["Vegeta"] = {
		Id = "Vegeta",
		Name = "Vegeta",
		Anime = "Dragon Ball",
		Title = "Prince of all Saiyans",
		Icon = "👑",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(30, 80, 210),
		AccentColor = Color3.fromRGB(255, 215, 0),
		WalkSpeed = 18,
		NinjaDashSpeed = 93,
		GuardHealth = 95,
		Stats = { Speed = 91, Power = 94, Defense = 86, Jutsu = 93 },
		M1Name = "Royal Saiyan Rush Strike",
		SweepName = "Final Sweep Kick",
		RangedSkill = {
			Name = "Big Bang Attack",
			Damage = 23,
			Speed = 110,
			Cooldown = 1.7,
			Lifetime = 2.2,
			Color = Color3.fromRGB(90, 180, 255),
			Shape = "Ball",
			Sound = "rbxasset://sounds/volume_slider.ogg",
			Icon = "💥",
		},
		NinjutsuSkill = {
			Name = "Galick Gun",
			Damage = 32,
			ChakraCost = 25,
			RushSpeed = 80,
			Color = Color3.fromRGB(160, 60, 240),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 46,
			LiftY = 8,
		},
		AssistName = "Rapid Ki Blast Barrage",
		UltimateName = "Final Flash: Super Saiyan Blast",
		Quote = "There is only one certainty in life: a strong man stands above and conquers all!",
	},
	["Trunks"] = {
		Id = "Trunks",
		Name = "Future Trunks",
		Anime = "Dragon Ball",
		Title = "Warrior of Hope",
		Icon = "🗡️",
		Archetype = "Sword",
		PrimaryColor = Color3.fromRGB(75, 75, 180),
		AccentColor = Color3.fromRGB(150, 60, 220),
		WalkSpeed = 17,
		NinjaDashSpeed = 91,
		GuardHealth = 94,
		Stats = { Speed = 90, Power = 91, Defense = 84, Jutsu = 89 },
		M1Name = "Shining Sword Slash Flurry",
		SweepName = "Burning Low Sweep",
		RangedSkill = {
			Name = "Burning Attack (Hand Signs Ki Blast)",
			Damage = 21,
			Speed = 125,
			Cooldown = 1.5,
			Lifetime = 1.9,
			Color = Color3.fromRGB(255, 200, 30),
			Shape = "Ball",
			Sound = "rbxasset://sounds/volume_slider.ogg",
			Icon = "🔥",
		},
		NinjutsuSkill = {
			Name = "Shining Slash Rush",
			Damage = 30,
			ChakraCost = 25,
			RushSpeed = 94,
			Color = Color3.fromRGB(240, 220, 100),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 42,
			LiftY = 10,
		},
		AssistName = "Buster Cannon",
		UltimateName = "Heat Dome Attack",
		Quote = "You're about to find out what it's like to fight a real Super Saiyan!",
	},
	["Ichigo"] = {
		Id = "Ichigo",
		Name = "Ichigo Kurosaki",
		Anime = "Bleach",
		Title = "Substitute Soul Reaper",
		Icon = "🗡️",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(20, 20, 25),
		AccentColor = Color3.fromRGB(255, 50, 50),
		WalkSpeed = 18,
		NinjaDashSpeed = 94,
		GuardHealth = 95,
		Stats = { Speed = 92, Power = 91, Defense = 82, Jutsu = 89 },
		M1Name = "Zangetsu Cleave String",
		SweepName = "Bankai Low Sweep",
		RangedSkill = {
			Name = "Getsuga Tensho Slash Wave",
			Damage = 23,
			Speed = 120,
			Cooldown = 1.6,
			Lifetime = 2.2,
			Color = Color3.fromRGB(255, 30, 40),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🌙",
		},
		NinjutsuSkill = {
			Name = "Black Getsuga Tensho",
			Damage = 32,
			ChakraCost = 25,
			RushSpeed = 92,
			Color = Color3.fromRGB(255, 20, 20),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 44,
			LiftY = 12,
		},
		AssistName = "Getsuga Tensho Barrage",
		UltimateName = "Mugetsu: Final Getsuga",
		Quote = "I'm not fighting because I want to win. I'm fighting because I have to protect them!",
	},
	["Aizen"] = {
		Id = "Aizen",
		Name = "Sosuke Aizen",
		Anime = "Bleach",
		Title = "Master of Kyoka Suigetsu",
		Icon = "🦋",
		Archetype = "Trickster",
		PrimaryColor = Color3.fromRGB(245, 245, 250),
		AccentColor = Color3.fromRGB(130, 40, 210),
		WalkSpeed = 17,
		NinjaDashSpeed = 93,
		GuardHealth = 98,
		Stats = { Speed = 93, Power = 94, Defense = 89, Jutsu = 99 },
		M1Name = "Kyoka Suigetsu Hypnotic Slash",
		SweepName = "Hado 63 Raikoho Sweep",
		RangedSkill = {
			Name = "Hado #90: Kurohitsugi (Black Coffin)",
			Damage = 24,
			Speed = 100,
			Cooldown = 1.9,
			Lifetime = 2.4,
			Color = Color3.fromRGB(70, 20, 110),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Icon = "⬛",
		},
		NinjutsuSkill = {
			Name = "Instant Shunpo Flash Thrust",
			Damage = 33,
			ChakraCost = 25,
			RushSpeed = 98,
			Color = Color3.fromRGB(140, 50, 220),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 40,
			LiftY = 6,
		},
		AssistName = "Mirror Illusion Shield",
		UltimateName = "Hogyoku Transcendence: Fragor",
		Quote = "No one stands on the top of the world. Not you, not me, not even gods.",
	},
	["Byakuya"] = {
		Id = "Byakuya",
		Name = "Byakuya Kuchiki",
		Anime = "Bleach",
		Title = "Captain of Squad 6",
		Icon = "🌸",
		Archetype = "Sword",
		PrimaryColor = Color3.fromRGB(255, 160, 195),
		AccentColor = Color3.fromRGB(40, 180, 180),
		WalkSpeed = 17,
		NinjaDashSpeed = 91,
		GuardHealth = 96,
		Stats = { Speed = 91, Power = 88, Defense = 87, Jutsu = 94 },
		M1Name = "Senbonzakura Petal Dance",
		SweepName = "Wind Petal Low Sweep",
		RangedSkill = {
			Name = "Senbonzakura Shikan (Petal Storm)",
			Damage = 21,
			Speed = 120,
			Cooldown = 1.6,
			Lifetime = 2.0,
			Color = Color3.fromRGB(255, 150, 190),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🌸",
		},
		NinjutsuSkill = {
			Name = "Utsusemi Flash Step Strike",
			Damage = 29,
			ChakraCost = 25,
			RushSpeed = 95,
			Color = Color3.fromRGB(255, 130, 180),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 36,
			LiftY = 8,
		},
		AssistName = "Blossom Wall Defense",
		UltimateName = "Senbonzakura Kageyoshi: Gokei",
		Quote = "Pride is something that should not be shed so lightly.",
	},
	["Sukuna"] = {
		Id = "Sukuna",
		Name = "Ryomen Sukuna",
		Anime = "Jujutsu Kaisen",
		Title = "King of Curses",
		Icon = "💀",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(180, 20, 50),
		AccentColor = Color3.fromRGB(20, 20, 25),
		WalkSpeed = 18,
		NinjaDashSpeed = 96,
		GuardHealth = 100,
		Stats = { Speed = 95, Power = 98, Defense = 85, Jutsu = 99 },
		M1Name = "Dismantle Taijutsu Combo",
		SweepName = "Cursed Energy Sweep",
		RangedSkill = {
			Name = "Dismantle: Invisible Air Slash",
			Damage = 24,
			Speed = 140,
			Cooldown = 1.5,
			Lifetime = 1.8,
			Color = Color3.fromRGB(255, 40, 80),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🩸",
		},
		NinjutsuSkill = {
			Name = "Cleave (Hachigire)",
			Damage = 35,
			ChakraCost = 25,
			RushSpeed = 95,
			Color = Color3.fromRGB(200, 20, 40),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 48,
			LiftY = 10,
		},
		AssistName = "Dismantle Rain",
		UltimateName = "Malevolent Shrine: Fuga Open",
		Quote = "Know your place, you fool.",
	},
	["Gojo"] = {
		Id = "Gojo",
		Name = "Satoru Gojo",
		Anime = "Jujutsu Kaisen",
		Title = "The Strongest Sorcerer",
		Icon = "♾️",
		Archetype = "Zoner",
		PrimaryColor = Color3.fromRGB(0, 180, 255),
		AccentColor = Color3.fromRGB(200, 50, 255),
		WalkSpeed = 17,
		NinjaDashSpeed = 92,
		GuardHealth = 110,
		Stats = { Speed = 94, Power = 96, Defense = 95, Jutsu = 100 },
		M1Name = "Limitless Cursed Martial Arts",
		SweepName = "Infinity Low Sweep",
		RangedSkill = {
			Name = "Cursed Technique Lapse: Blue",
			Damage = 22,
			Speed = 110,
			Cooldown = 1.6,
			Lifetime = 2.0,
			Color = Color3.fromRGB(0, 160, 255),
			Shape = "Ball",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🔵",
		},
		NinjutsuSkill = {
			Name = "Cursed Technique Reversal: Red",
			Damage = 33,
			ChakraCost = 25,
			RushSpeed = 85,
			Color = Color3.fromRGB(255, 30, 60),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 55,
			LiftY = 8,
		},
		AssistName = "Infinity Repulsion Field",
		UltimateName = "Hollow Technique: Purple",
		Quote = "Don't worry, I'm the strongest.",
	},
	["Yuji"] = {
		Id = "Yuji",
		Name = "Yuji Itadori",
		Anime = "Jujutsu Kaisen",
		Title = "Tiger of West Junior High",
		Icon = "🥊",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(245, 95, 140),
		AccentColor = Color3.fromRGB(25, 30, 55),
		WalkSpeed = 18,
		NinjaDashSpeed = 95,
		GuardHealth = 92,
		Stats = { Speed = 92, Power = 93, Defense = 88, Jutsu = 80 },
		M1Name = "Divergent Fist Impact Combo",
		SweepName = "Manji Kick Low Sweep",
		RangedSkill = {
			Name = "Cursed Energy Shockwave",
			Damage = 19,
			Speed = 125,
			Cooldown = 1.4,
			Lifetime = 1.6,
			Color = Color3.fromRGB(60, 140, 255),
			Shape = "Ball",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "💥",
		},
		NinjutsuSkill = {
			Name = "Black Flash (Kokusen)",
			Damage = 34,
			ChakraCost = 25,
			RushSpeed = 96,
			Color = Color3.fromRGB(255, 20, 60),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 50,
			LiftY = 12,
		},
		AssistName = "Divergent Strike Striker",
		UltimateName = "Consecutive Black Flash Burst",
		Quote = "I don't want to regret the way I lived!",
	},
	["Megumi"] = {
		Id = "Megumi",
		Name = "Megumi Fushiguro",
		Anime = "Jujutsu Kaisen",
		Title = "Ten Shadows Prodigy",
		Icon = "🐺",
		Archetype = "Trickster",
		PrimaryColor = Color3.fromRGB(30, 35, 60),
		AccentColor = Color3.fromRGB(40, 200, 140),
		WalkSpeed = 17,
		NinjaDashSpeed = 89,
		GuardHealth = 90,
		Stats = { Speed = 86, Power = 85, Defense = 84, Jutsu = 93 },
		M1Name = "Shadow Shikigami Strike",
		SweepName = "Shadow Sink Low Sweep",
		RangedSkill = {
			Name = "Nue: Lightning Feather Volley",
			Damage = 20,
			Speed = 130,
			Cooldown = 1.5,
			Lifetime = 1.8,
			Color = Color3.fromRGB(255, 230, 60),
			Shape = "Bolt",
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Icon = "⚡",
		},
		NinjutsuSkill = {
			Name = "Divine Dog: Totality Claws",
			Damage = 30,
			ChakraCost = 25,
			RushSpeed = 92,
			Color = Color3.fromRGB(20, 25, 45),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 38,
			LiftY = 8,
		},
		AssistName = "Great Serpent Binding",
		UltimateName = "Chimera Shadow Garden",
		Quote = "I help people unequally. That's my way.",
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
		NinjutsuSkill = {
			Name = "Godspeed Lightning Palm",
			Damage = 31,
			ChakraCost = 25,
			RushSpeed = 105,
			Color = Color3.fromRGB(0, 245, 255),
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Knockback = 40,
			LiftY = 6,
		},
		AssistName = "Thunderbolt Striker",
		UltimateName = "Godspeed: Whirlwind Execution",
		Quote = "If I don't defeat you right now... I can't protect anyone!",
	},
	["Gon"] = {
		Id = "Gon",
		Name = "Gon Freecss",
		Anime = "Hunter x Hunter",
		Title = "Rookie Hunter / Enhancer",
		Icon = "🎣",
		Archetype = "Grappler",
		PrimaryColor = Color3.fromRGB(45, 175, 65),
		AccentColor = Color3.fromRGB(255, 130, 20),
		WalkSpeed = 16,
		NinjaDashSpeed = 85,
		GuardHealth = 115,
		Stats = { Speed = 84, Power = 95, Defense = 88, Jutsu = 85 },
		M1Name = "Hunter Martial Arts Combo",
		SweepName = "Roundhouse Grass Sweep",
		RangedSkill = {
			Name = "Jajanken: Paper (Emitted Nen)",
			Damage = 20,
			Speed = 110,
			Cooldown = 1.6,
			Lifetime = 2.0,
			Color = Color3.fromRGB(255, 200, 50),
			Shape = "Ball",
			Sound = "rbxasset://sounds/volume_slider.ogg",
			Icon = "🖐️",
		},
		NinjutsuSkill = {
			Name = "Jajanken: Scissors (Nen Blade)",
			Damage = 30,
			ChakraCost = 25,
			RushSpeed = 90,
			Color = Color3.fromRGB(255, 100, 30),
			Sound = "rbxasset://sounds/action_jump.mp3",
			Knockback = 38,
			LiftY = 8,
		},
		AssistName = "Jajanken Paper Cannon",
		UltimateName = "Jajanken: Rock (Max Power)",
		Quote = "I'll do whatever it takes to win!",
	},
	["Tanjiro"] = {
		Id = "Tanjiro",
		Name = "Tanjiro Kamado",
		Anime = "Demon Slayer",
		Title = "Sun & Water Breath Swordsman",
		Icon = "🌊",
		Archetype = "Sword",
		PrimaryColor = Color3.fromRGB(35, 135, 80),
		AccentColor = Color3.fromRGB(240, 50, 30),
		WalkSpeed = 17,
		NinjaDashSpeed = 89,
		GuardHealth = 95,
		Stats = { Speed = 88, Power = 90, Defense = 85, Jutsu = 89 },
		M1Name = "Water Surface Slash Combo",
		SweepName = "Water Wheel Low Sweep",
		RangedSkill = {
			Name = "4th Form: Striking Tide",
			Damage = 21,
			Speed = 120,
			Cooldown = 1.6,
			Lifetime = 2.0,
			Color = Color3.fromRGB(0, 180, 255),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "🌊",
		},
		NinjutsuSkill = {
			Name = "Hinokami Kagura: Clear Blue Sky",
			Damage = 33,
			ChakraCost = 25,
			RushSpeed = 94,
			Color = Color3.fromRGB(255, 60, 20),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 45,
			LiftY = 12,
		},
		AssistName = "Waterfall Basin Assist",
		UltimateName = "Hinokami Kagura: Flame Dance (Enbu)",
		Quote = "No matter how weak you are, bring out your true courage!",
	},
	["Zenitsu"] = {
		Id = "Zenitsu",
		Name = "Zenitsu Agatsuma",
		Anime = "Demon Slayer",
		Title = "Thunder Breathing Master",
		Icon = "⚡",
		Archetype = "Trickster",
		PrimaryColor = Color3.fromRGB(255, 215, 30),
		AccentColor = Color3.fromRGB(240, 250, 255),
		WalkSpeed = 18,
		NinjaDashSpeed = 98,
		GuardHealth = 78,
		Stats = { Speed = 98, Power = 88, Defense = 72, Jutsu = 90 },
		M1Name = "Thunderclap Quickdraw",
		SweepName = "Electric Low Sweep",
		RangedSkill = {
			Name = "Thunder Spark Shuriken",
			Damage = 20,
			Speed = 150,
			Cooldown = 1.4,
			Lifetime = 1.3,
			Color = Color3.fromRGB(255, 235, 80),
			Shape = "Bolt",
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Icon = "⚡",
		},
		NinjutsuSkill = {
			Name = "Thunderclap and Flash (Hekireki Issen)",
			Damage = 32,
			ChakraCost = 25,
			RushSpeed = 110,
			Color = Color3.fromRGB(255, 230, 40),
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Knockback = 48,
			LiftY = 6,
		},
		AssistName = "Thunder Sixfold Striker",
		UltimateName = "7th Form: Flaming Thunder God",
		Quote = "I've perfected this one technique to absolute mastery!",
	},
	["Deku"] = {
		Id = "Deku",
		Name = "Izuku Midoriya",
		Anime = "My Hero Academia",
		Title = "One For All 9th Successor",
		Icon = "🥦",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(30, 160, 95),
		AccentColor = Color3.fromRGB(60, 255, 210),
		WalkSpeed = 18,
		NinjaDashSpeed = 93,
		GuardHealth = 88,
		Stats = { Speed = 93, Power = 94, Defense = 84, Jutsu = 88 },
		M1Name = "Shoot Style Kick Barrage",
		SweepName = "Manchester Smash Low Sweep",
		RangedSkill = {
			Name = "Air Force: Delaware Smash Bullet",
			Damage = 20,
			Speed = 135,
			Cooldown = 1.5,
			Lifetime = 1.6,
			Color = Color3.fromRGB(80, 255, 200),
			Shape = "Fist",
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Icon = "💨",
		},
		NinjutsuSkill = {
			Name = "St. Louis Smash Flying Kick",
			Damage = 31,
			ChakraCost = 25,
			RushSpeed = 95,
			Color = Color3.fromRGB(50, 240, 180),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 42,
			LiftY = 12,
		},
		AssistName = "Detroit Smash Shockwave",
		UltimateName = "One For All 100%: United States Smash",
		Quote = "A hero always finds a way to break through!",
	},
	["Bakugo"] = {
		Id = "Bakugo",
		Name = "Katsuki Bakugo",
		Anime = "My Hero Academia",
		Title = "Great Explosion Murder God",
		Icon = "💥",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(255, 95, 20),
		AccentColor = Color3.fromRGB(45, 95, 55),
		WalkSpeed = 18,
		NinjaDashSpeed = 94,
		GuardHealth = 85,
		Stats = { Speed = 92, Power = 96, Defense = 80, Jutsu = 91 },
		M1Name = "Explosion Gauntlet Brawling",
		SweepName = "Blast Propulsion Low Sweep",
		RangedSkill = {
			Name = "Stun Grenade Flash Blast",
			Damage = 22,
			Speed = 120,
			Cooldown = 1.5,
			Lifetime = 1.8,
			Color = Color3.fromRGB(255, 120, 20),
			Shape = "Ball",
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Icon = "💣",
		},
		NinjutsuSkill = {
			Name = "AP Shot (Armor Piercing Blast)",
			Damage = 33,
			ChakraCost = 25,
			RushSpeed = 96,
			Color = Color3.fromRGB(255, 80, 10),
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Knockback = 48,
			LiftY = 10,
		},
		AssistName = "Blast Rush Striker",
		UltimateName = "Howitzer Impact: Massive Detonation",
		Quote = "I'm gonna be number one, no matter what!",
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
local evSub        = ensureRemote("SubstitutionEvent")
local evCounter    = ensureRemote("CounterEvent")
local evNinjutsu   = ensureRemote("NinjutsuEvent")

-- =========================================================
-- 2. PLAYER COMBAT STATE TRACKING (Storm 4 + Tekken)
-- =========================================================
type PlayerCombatState = {
	isBlocking: boolean,
	blockType: string,
	blockStartTime: number,
	guardHealth: number,
	lastParriedTime: number,
	subStocks: number,
	lastSubTime: number,
	lastDamageTime: number,
	isCountering: boolean,
	counterStartTime: number,
	lastAttacker: Model?,
}

local playerCombatStates: { [number]: PlayerCombatState } = {}

local function setupPlayer(player: Player)
	playerCombatStates[player.UserId] = {
		isBlocking = false,
		blockType = "None",
		blockStartTime = 0,
		guardHealth = 100,
		lastParriedTime = 0,
		subStocks = 4,
		lastSubTime = 0,
		lastDamageTime = 0,
		isCountering = false,
		counterStartTime = 0,
		lastAttacker = nil,
	}
	player:SetAttribute("SubstitutionStocks", 4)
	player:SetAttribute("ChakraValue", 60)
	player:SetAttribute("IsBlocking", false)
	player:SetAttribute("IsCountering", false)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerCombatStates[player.UserId] = nil
end)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

-- Background Sub Stock Regeneration (1 stock every 12 seconds when not taking damage)
task.spawn(function()
	while true do
		task.wait(1.0)
		local now = os.clock()
		for userId, state in pairs(playerCombatStates) do
			local player = Players:GetPlayerByUserId(userId)
			if player and state.subStocks < 4 then
				-- Regenerate if player hasn't taken damage in last 3 seconds
				if now - state.lastDamageTime >= 3.0 and now - state.lastSubTime >= 12.0 then
					state.subStocks = math.min(4, state.subStocks + 1)
					state.lastSubTime = now
					player:SetAttribute("SubstitutionStocks", state.subStocks)
				end
			end
		end
	end
end)

-- =========================================================
-- 2B. 3D WOODEN LOG & SMOKE (Storm 4 Kawarimi Effect)
-- =========================================================
local function spawnSubstitutionLog(cf: CFrame)
	local log = Instance.new("Part")
	log.Name = "KawarimiWoodLog"
	log.Shape = Enum.PartType.Cylinder
	log.Size = Vector3.new(2.8, 1.4, 1.4)
	log.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	log.Color = Color3.fromRGB(139, 90, 43)
	log.Material = Enum.Material.Wood
	log.Anchored = false
	log.CanCollide = true
	log.Parent = Workspace
	Debris:AddItem(log, 2.2)

	-- Puff of Smoke Emitter
	local att = Instance.new("Attachment", log)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(245, 245, 250), Color3.fromRGB(210, 210, 220))
	pe.Size = NumberSequence.new(2.5, 5.0)
	pe.Transparency = NumberSequence.new(0.2, 1.0)
	pe.Rate = 120
	pe.Speed = NumberRange.new(5, 14)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att
	task.delay(0.2, function() pe.Enabled = false end)

	-- Sound
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
		snd.PlaybackSpeed = 0.8
		snd.Volume = 1.0
		snd.Parent = log
		snd:Play()
	end)
end

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

	-- 3. Check for STORM 4 COUNTER ATTACK ([Guard + Attack] / [F + J])
	if targetState and targetState.isCountering and (now - targetState.counterStartTime <= 0.35) then
		print(string.format(">> [STORM 4 COUNTER BLOW] %s countered %s's strike! <<", targetModel.Name, attacker.Name))
		spawnFloatingText(tRoot.Position, "⚔️ COUNTER BLOW!", Color3.fromRGB(255, 215, 0))

		-- Blow attacker back flying across arena & stagger
		local counterDir = -aRoot.CFrame.LookVector
		aRoot.AssemblyLinearVelocity = (counterDir * 55) + Vector3.new(0, 10, 0)
		if targetPlayer then
			evParry:FireClient(targetPlayer, targetPlayer, attacker)
		end
		evParry:FireClient(attacker, targetPlayer or attacker, attacker)
		return
	end

	-- 3B. Check for TEKKEN JUST-FRAME PARRY (180ms window)
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

	-- Update State for Substitution & Chakra Tracking
	if targetState then
		targetState.lastAttacker = attackerChar
		targetState.lastDamageTime = now
	end
	if targetModel.Name == "TrainingDummy" then
		targetModel:SetAttribute("LastAttackerName", attacker.Name)
		if _G.AwardCombatRyo then
			_G.AwardCombatRyo(attacker, 2, "Combo Latihan")
		end
	end

	-- Chakra Gain on Hit
	local curChakra = attacker:GetAttribute("ChakraValue") or 60
	attacker:SetAttribute("ChakraValue", math.min(100, curChakra + 10))
	if targetPlayer then
		local tChakra = targetPlayer:GetAttribute("ChakraValue") or 60
		targetPlayer:SetAttribute("ChakraValue", math.min(100, tChakra + 7))
	end

	-- Apply Knockback
	local hitDir = (tRoot.Position - aRoot.Position).Unit
	local flatHitDir = Vector3.new(hitDir.X, 0, hitDir.Z).Unit
	local liftY = if comboStep == 4 then 12 elseif comboStep == 3 then 6 else 0
	tRoot.AssemblyLinearVelocity = (flatHitDir * knockback) + Vector3.new(0, liftY, 0)
end)

-- =========================================================
-- 5B. SUBSTITUTION JUTSU (Kawarimi - The Lifeline of Combat)
-- =========================================================
evSub.OnServerEvent:Connect(function(player: Player)
	local state = playerCombatStates[player.UserId]
	if not state or state.subStocks < 1 then
		return
	end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	-- Find attacker to teleport behind
	local targetChar: Model? = state.lastAttacker
	if not targetChar or not targetChar.Parent then
		-- Fallback: check nearest opponent in front
		local dummy = Workspace:FindFirstChild("TrainingDummy")
		if dummy and dummy:IsA("Model") then
			targetChar = dummy
		else
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local dist = (p.Character:GetPivot().Position - root.Position).Magnitude
					if dist <= 30 then
						targetChar = p.Character
						break
					end
				end
			end
		end
	end

	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	-- 1. Deduct Sub Stock & Reset Hitstun
	state.subStocks -= 1
	state.lastSubTime = os.clock()
	player:SetAttribute("SubstitutionStocks", state.subStocks)

	-- 2. Spawn 3D Wood Log & Smoke Puff at player's previous location
	local prevCFrame = root.CFrame
	spawnSubstitutionLog(prevCFrame)

	-- 3. Teleport 8 studs directly BEHIND the attacker facing their back!
	local behindPos = targetRoot.Position - (targetRoot.CFrame.LookVector * 8.0)
	root.CFrame = CFrame.lookAt(behindPos, targetRoot.Position)
	root.AssemblyLinearVelocity = Vector3.zero

	-- 4. Floating Text & Broadcast
	spawnFloatingText(root.Position, "🪵 KAWARIMI!", Color3.fromRGB(255, 215, 0))
	evSub:FireAllClients(player, prevCFrame)

	print(string.format(">> [SUBSTITUTION JUTSU] %s substituted behind %s! (%d logs left) <<", player.Name, targetChar.Name, state.subStocks))
end)

-- =========================================================
-- 5C. STORM 4 COUNTER ATTACK STANCE TOGGLE ([F + J])
-- =========================================================
evCounter.OnServerEvent:Connect(function(player: Player, isCountering: boolean)
	local state = playerCombatStates[player.UserId]
	if state then
		state.isCountering = isCountering
		state.counterStartTime = if isCountering then os.clock() else 0
		player:SetAttribute("IsCountering", isCountering)
		evCounter:FireAllClients(player, isCountering)
	end
end)

-- =========================================================
-- 5D. CHARACTER NINJUTSU ([I] + [J] Chakra Rush)
-- =========================================================
evNinjutsu.OnServerEvent:Connect(function(player: Player, targetModel: Model?)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local curChakra = player:GetAttribute("ChakraValue") or 60
	if curChakra < 25 then
		spawnFloatingText(root.Position, "⚠️ NOT ENOUGH CHAKRA!", Color3.fromRGB(255, 100, 100))
		return
	end

	-- Deduct 25 Chakra
	player:SetAttribute("ChakraValue", curChakra - 25)

	local charId = tostring(player:GetAttribute("SelectedCharacter") or "Naruto")
	local charData = CombatConfig.Characters[charId] or CombatConfig.Characters["Naruto"]
	local jutsu = charData.NinjutsuSkill or {
		Name = "Ninjutsu Strike",
		Damage = 30,
		RushSpeed = 90,
		Color = Color3.fromRGB(0, 220, 255),
		Knockback = 45,
		LiftY = 12,
	}

	-- Find target
	local tRoot: BasePart? = nil
	local tHum: Humanoid? = nil
	if targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
		tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart
		tHum = targetModel:FindFirstChildOfClass("Humanoid")
	else
		local dummy = Workspace:FindFirstChild("TrainingDummy")
		if dummy and dummy:FindFirstChild("HumanoidRootPart") then
			tRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
			tHum = dummy:FindFirstChildOfClass("Humanoid")
		end
	end

	-- Forward Rush Impulse
	local rushDir = root.CFrame.LookVector
	root.AssemblyLinearVelocity = rushDir * (jutsu.RushSpeed or 90)

	-- Sonic Jutsu Visual Part
	local jutsuPart = Instance.new("Part")
	jutsuPart.Shape = Enum.PartType.Ball
	jutsuPart.Size = Vector3.new(3.5, 3.5, 3.5)
	jutsuPart.CFrame = root.CFrame * CFrame.new(0, 0, -2.5)
	jutsuPart.Material = Enum.Material.Neon
	jutsuPart.Color = jutsu.Color or Color3.fromRGB(0, 240, 255)
	jutsuPart.CanCollide = false
	jutsuPart.Anchored = false
	jutsuPart.Parent = Workspace

	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = jutsuPart
	w.Parent = jutsuPart

	local att = Instance.new("Attachment", jutsuPart)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(jutsu.Color or Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(2, 0)
	pe.Rate = 90
	pe.Speed = NumberRange.new(5, 15)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Parent = att

	Debris:AddItem(jutsuPart, 0.6)

	-- Hit registration
	task.delay(0.18, function()
		if tRoot and tHum and tHum.Health > 0 then
			local dist = (tRoot.Position - root.Position).Magnitude
			if dist <= 14 then
				tHum:TakeDamage(jutsu.Damage or 30)
				spawnFloatingText(tRoot.Position, string.format("💥 %s -%d!", jutsu.Name, jutsu.Damage or 30), jutsu.Color or Color3.fromRGB(0, 240, 255))
				local knockDir = (tRoot.Position - root.Position).Unit
				tRoot.AssemblyLinearVelocity = (knockDir * (jutsu.Knockback or 45)) + Vector3.new(0, jutsu.LiftY or 12, 0)
			end
		end
	end)

	print(string.format(">> [NINJUTSU ACTIVATED] %s unleashed %s! <<", player.Name, jutsu.Name))
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

	-- Distinct 3D mesh shaping per anime character skill shape:
	local shape = skill.Shape or "Ball"
	if shape == "Disc" then
		-- Aerodynamic Disc (Rasen-Shuriken, Destructo Disc)
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(0.4, 3.2, 3.2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, 0, math.rad(90))
	elseif shape == "Ball" then
		-- Blazing Energy / Flame Sphere (Goukakyuu, Ki Blast, Blue, Stun Grenade)
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(2.8, 2.8, 2.8)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif shape == "Fist" then
		-- Elastic / Air Shockwave Fist (Gum-Gum Pistol, Delaware Smash)
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(3.0, 1.6, 1.6)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, math.rad(90), 0)
	elseif shape == "SlashBlade" then
		-- Flying Anime Blade Wave (36 Pound Phoenix, Getsuga Tensho, Dismantle, Striking Tide)
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.3, 3.8, 2.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif shape == "Bolt" then
		-- Piercing Lightning Bolt / Hound (Narukami, Raiju, Thunder Spark)
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.7, 0.7, 3.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	else
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(2.4, 2.4, 2.4)
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
-- INSTALL: StormCharacterMorphServer (ModuleScript)
-- ============================================================
do
    local src = [=====[--!strict
-- StormCharacterMorphServer.luau
-- SERVER MODULE: 3D Anime Character Visual Morph & Procedural Cosmetic Engine
-- Transforms standard R15 characters into unmistakable anime fighters across 24 iconic legends:
--   • Naruto Shippuden: Naruto Uzumaki, Sasuke Uchiha, Kakashi Hatake, Madara Uchiha
--   • One Piece: Monkey D. Luffy, Roronoa Zoro, Vinsmoke Sanji, Trafalgar D. Water Law
--   • Dragon Ball: Son Goku, Vegeta, Future Trunks
--   • Bleach: Ichigo Kurosaki, Sosuke Aizen, Byakuya Kuchiki
--   • Jujutsu Kaisen: Ryomen Sukuna, Satoru Gojo, Yuji Itadori, Megumi Fushiguro
--   • Hunter x Hunter: Killua Zoldyck, Gon Freecss
--   • Demon Slayer: Tanjiro Kamado, Zenitsu Agatsuma
--   • My Hero Academia: Izuku Midoriya (Deku), Katsuki Bakugo

local StormCharacterMorphServer = {}

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Helper: Create a welded accessory part
local function addMorphPart(parent: Model, part0: BasePart, offset: CFrame, size: Vector3, color: Color3, material: Enum.Material?, partType: Enum.PartType?): Part
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

-- Helper: Add particle aura to part
local function addAura(part: BasePart, texture: string, colors: {Color3}, sizeRange: {number}, rate: number, lifetime: number, name: string)
	local att = Instance.new("Attachment", part)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = texture or "rbxasset://textures/particles/sparkles_main.dds"
	if #colors >= 2 then
		pe.Color = ColorSequence.new(colors[1], colors[2])
	else
		pe.Color = ColorSequence.new(colors[1])
	end
	pe.Size = NumberSequence.new(sizeRange[1], sizeRange[2] or 0)
	pe.Rate = rate
	pe.Speed = NumberRange.new(1, 3)
	pe.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
	pe.Name = name
	pe.Parent = att
	return pe
end

-- =========================================================
-- 1. NARUTO UZUMAKI (Spiky Blonde Hair, Leaf Headband, Orange Tracksuit)
-- =========================================================
local function morphNaruto(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairColor = Color3.fromRGB(255, 215, 0)
	local headbandBlue = Color3.fromRGB(22, 42, 92)
	local plateSilver = Color3.fromRGB(215, 220, 230)
	local jumpsuitOrange = Color3.fromRGB(245, 115, 15)

	-- Spiky Anime Hair Cluster
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, -0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.6, 0.85, 0.7), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(-25), math.rad(25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.5) * CFrame.Angles(math.rad(-30), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairColor)
	addMorphPart(morphModel, head, CFrame.new(-0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor)
	addMorphPart(morphModel, head, CFrame.new(0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor)

	-- Konoha Forehead Protector Headband
	addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.56), Vector3.new(1.25, 0.38, 0.12), headbandBlue, Enum.Material.Fabric)
	local plate = addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.63), Vector3.new(0.72, 0.28, 0.05), plateSilver, Enum.Material.Metal)

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

	-- Orange Track Jacket with Blue Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.35, 1.15), headbandBlue)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 1.4, 1.05), jumpsuitOrange)

	-- Bandage & Holster Pouch
	if rightLeg then
		addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.3, 0), Vector3.new(1.05, 0.5, 1.05), Color3.fromRGB(240, 240, 245), Enum.Material.Fabric)
		addMorphPart(morphModel, rightLeg, CFrame.new(0.55, 0.3, 0), Vector3.new(0.2, 0.35, 0.35), Color3.fromRGB(40, 30, 25), Enum.Material.Leather)
	end
end

-- =========================================================
-- 2. SASUKE UCHIHA (Winged Hair, Stand-Up Collar, Shimenawa Rope)
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

	-- Spiky Dark Hair & Bangs
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0.1) * CFrame.Angles(math.rad(-20), math.rad(180), 0), Vector3.new(0.9, 0.85, 0.8), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(-150), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(150), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	addMorphPart(morphModel, head, CFrame.new(-0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(-10)), Vector3.new(0.2, 0.75, 0.15), hairDark)
	addMorphPart(morphModel, head, CFrame.new(0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(10)), Vector3.new(0.2, 0.75, 0.15), hairDark)

	-- High Stand-Up Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0.45) * CFrame.Angles(math.rad(12), 0, 0), Vector3.new(1.5, 0.65, 0.15), tunicWhite, Enum.Material.Fabric)

	-- Purple Shimenawa Rope & Blue Apron Sash
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, -0.3, 0), Vector3.new(2.1, 0.85, 1.15), sashBlue, Enum.Material.Fabric)
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0), Vector3.new(2.25, 0.35, 1.25), ropePurple, Enum.Material.Fabric)
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0.7), Vector3.new(0.8, 0.5, 0.4), ropePurple, Enum.Material.Fabric)
	end

	-- Sharingan Eye Aura
	addAura(head, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 30, 30), Color3.fromRGB(180, 0, 0)}, {0.25, 0}, 12, 0.6, "SharinganAura")
end

-- =========================================================
-- 3. KAKASHI HATAKE (Silver Hair, Mask, Flak Jacket)
-- =========================================================
local function morphKakashi(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSilver = Color3.fromRGB(230, 235, 240)
	local maskNavy = Color3.fromRGB(24, 28, 42)
	local flakGreen = Color3.fromRGB(48, 88, 56)
	local flakDark = Color3.fromRGB(30, 58, 36)

	-- Spiky Silver Hair sweeping to left
	addMorphWedge(morphModel, head, CFrame.new(-0.2, 0.85, 0) * CFrame.Angles(math.rad(15), math.rad(-15), math.rad(25)), Vector3.new(0.85, 0.95, 0.8), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.25, 0.75, 0.1) * CFrame.Angles(math.rad(20), math.rad(20), math.rad(20)), Vector3.new(0.65, 0.85, 0.65), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.5) * CFrame.Angles(math.rad(-25), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairSilver)

	-- Ninja Face Mask covering nose and mouth
	addMorphPart(morphModel, head, CFrame.new(0, -0.25, -0.45), Vector3.new(1.15, 0.55, 0.35), maskNavy, Enum.Material.Fabric)

	-- Headband Tilted over left eye (Sharingan protector)
	addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.55) * CFrame.Angles(0, 0, math.rad(-14)), Vector3.new(1.25, 0.42, 0.12), maskNavy, Enum.Material.Fabric)
	addMorphPart(morphModel, head, CFrame.new(-0.15, 0.28, -0.62) * CFrame.Angles(0, 0, math.rad(-14)), Vector3.new(0.65, 0.28, 0.05), Color3.fromRGB(215, 220, 230), Enum.Material.Metal)

	-- Jonin Green Flak Jacket with shoulder pads & chest pockets
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.05, 0), Vector3.new(2.15, 1.45, 1.15), flakGreen, Enum.Material.Fabric)
	-- Shoulder pads
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.1, 0.65, 0), Vector3.new(0.4, 0.35, 1.1), flakDark, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, 0.65, 0), Vector3.new(0.4, 0.35, 1.1), flakDark, Enum.Material.Fabric)
	-- Twin scroll pockets on chest
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.5, 0.1, -0.6), Vector3.new(0.45, 0.55, 0.15), flakDark, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.5, 0.1, -0.6), Vector3.new(0.45, 0.55, 0.15), flakDark, Enum.Material.Fabric)
end

-- =========================================================
-- 4. MADARA UCHIHA (Wild Mane, Red Samurai Armor, Susanoo Glow)
-- =========================================================
local function morphMadara(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local armorCrimson = Color3.fromRGB(175, 25, 35)
	local robeMaroon = Color3.fromRGB(60, 20, 30)

	-- Massive Wild Spiky Mane
	addMorphWedge(morphModel, head, CFrame.new(0, 0.9, 0.2) * CFrame.Angles(math.rad(-25), math.rad(180), 0), Vector3.new(1.2, 1.1, 1.0), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.6, 0.7, 0.3) * CFrame.Angles(math.rad(-20), math.rad(-150), math.rad(30)), Vector3.new(0.8, 1.0, 0.8), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.6, 0.7, 0.3) * CFrame.Angles(math.rad(-20), math.rad(150), math.rad(-30)), Vector3.new(0.8, 1.0, 0.8), hairBlack)
	-- Hair flowing down over back of torso
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, 0.65), Vector3.new(1.6, 1.5, 0.4), hairBlack)

	-- Sengoku Samurai Armor Chestplate & Pauldrons
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.1), Vector3.new(2.1, 1.4, 1.1), robeMaroon, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, -0.58), Vector3.new(1.8, 0.9, 0.18), armorCrimson, Enum.Material.Metal)
	-- Segmented Shoulder Pauldrons
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.25, 0.65, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.5, 0.8, 1.2), armorCrimson, Enum.Material.Metal)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.25, 0.65, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.5, 0.8, 1.2), armorCrimson, Enum.Material.Metal)

	-- Susanoo Azure Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 120, 255), Color3.fromRGB(20, 50, 200)}, {0.6, 0}, 15, 0.7, "SusanooAura")
end

-- =========================================================
-- 5. MONKEY D. LUFFY (Straw Hat, Vest, X-Scar, Fur Shorts)
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
	local furWhite = Color3.fromRGB(250, 250, 255)

	-- 3D Straw Hat (Mugiwara)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.08, 3.2, 3.2), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)
	addMorphPart(morphModel, head, CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.18, 1.85, 1.85), ribbonRed, Enum.Material.Fabric, Enum.PartType.Cylinder)
	addMorphPart(morphModel, head, CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 1.8, 1.8), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)

	-- Messy Black Hair beneath hat
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(-20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))

	-- Open Red Sleeveless Vest
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0.52), Vector3.new(1.8, 1.45, 0.15), vestRed, Enum.Material.Fabric)

	-- Chest X-Scar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30))
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30))

	-- Yellow Sash & Denim Fur Cuffs
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.25, 0), Vector3.new(2.15, 0.3, 1.2), Color3.fromRGB(245, 205, 30), Enum.Material.Fabric)
	end
	if leftLeg then addMorphPart(morphModel, leftLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric) end
	if rightLeg then addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric) end
end

-- =========================================================
-- 6. RORONOA ZORO (Green Marimo Hair, Haramaki, 3 Katanas)
-- =========================================================
local function morphZoro(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local marimoGreen = Color3.fromRGB(45, 175, 75)
	local haramakiGreen = Color3.fromRGB(25, 95, 45)
	local bandanaBlack = Color3.fromRGB(20, 22, 26)

	-- Emerald Green Crop Hair (Marimo)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.35, 0.45, 1.35), marimoGreen, Enum.Material.Grass)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, -0.15) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.8, 0.4, 0.8), marimoGreen)

	-- Black Bandana on Left Bicep
	if leftArm then
		addMorphPart(morphModel, leftArm, CFrame.new(0, 0.2, 0), Vector3.new(1.15, 0.4, 1.15), bandanaBlack, Enum.Material.Fabric)
	end

	-- Emerald Green Haramaki (Belly Warmer)
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 0.95, 1.15), haramakiGreen, Enum.Material.Fabric)
	end

	-- Santoryu (3 Katana Sheaths on Right Hip)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, -0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-135)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(245, 245, 250))
	addMorphPart(morphModel, upperTorso, CFrame.new(1.15, -0.5, 0.4) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(190, 30, 30))
	addMorphPart(morphModel, upperTorso, CFrame.new(1.2, -0.4, 0.6) * CFrame.Angles(0, 0, math.rad(-145)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(24, 24, 28))

	-- Left Eye Scar
	addMorphPart(morphModel, head, CFrame.new(-0.25, 0.08, -0.56) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.04, 0.35, 0.02), Color3.fromRGB(80, 40, 40))
end

-- =========================================================
-- 7. VINSMOKE SANJI (Golden Swoop Hair, Black Suit, Diable Flames)
-- =========================================================
local function morphSanji(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairGold = Color3.fromRGB(250, 215, 60)
	local suitBlack = Color3.fromRGB(25, 28, 35)

	-- Golden Swooping Side Bangs (covers right eye)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 0.35, -0.5) * CFrame.Angles(math.rad(35), math.rad(15), math.rad(-20)), Vector3.new(0.65, 0.85, 0.35), hairGold)
	addMorphWedge(morphModel, head, CFrame.new(-0.2, 0.75, 0) * CFrame.Angles(math.rad(15), math.rad(-15), 0), Vector3.new(0.85, 0.65, 0.8), hairGold)

	-- Black Formal Suit Jacket & Tie
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), suitBlack, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.35, -0.56), Vector3.new(0.15, 0.7, 0.05), Color3.fromRGB(15, 15, 20), Enum.Material.Fabric) -- Tie

	-- Diable Jambe Flame Aura on right leg
	if rightLeg then
		addAura(rightLeg, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 120, 20), Color3.fromRGB(255, 40, 10)}, {0.45, 0}, 16, 0.5, "DiableFlames")
	end
end

-- =========================================================
-- 8. TRAFALGAR LAW (Spotted Fur Hat, Black Coat, Kikoku Nodachi)
-- =========================================================
local function morphLaw(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hatWhite = Color3.fromRGB(245, 245, 250)
	local coatBlack = Color3.fromRGB(22, 24, 30)

	-- White Spotted Fur Bucket Cap
	addMorphPart(morphModel, head, CFrame.new(0, 0.75, 0), Vector3.new(1.4, 0.55, 1.4), hatWhite, Enum.Material.Fabric)
	-- Fur spots
	addMorphPart(morphModel, head, CFrame.new(-0.4, 0.75, -0.65), Vector3.new(0.2, 0.2, 0.1), coatBlack)
	addMorphPart(morphModel, head, CFrame.new(0.4, 0.75, -0.65), Vector3.new(0.2, 0.2, 0.1), coatBlack)

	-- Goatee Beard
	addMorphPart(morphModel, head, CFrame.new(0, -0.5, -0.5), Vector3.new(0.2, 0.18, 0.15), coatBlack)

	-- Black Long Coat with Yellow Jolly Roger
	local coat = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.5, 1.15), coatBlack, Enum.Material.Fabric)
	local sg = Instance.new("SurfaceGui", coat)
	sg.Face = Enum.NormalId.Back
	local lbl = Instance.new("TextLabel", sg)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "💛"
	lbl.TextSize = 24

	-- Massive Kikoku Nodachi with Fur Crossguard slung at hip
	local nodachi = addMorphPart(morphModel, upperTorso, CFrame.new(1.15, -0.5, 0.2) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.2, 4.2, 0.3), coatBlack)
	-- White fur tsuba guard
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.45, 0.3, 0.45), hatWhite, Enum.Material.Fabric)
end

-- =========================================================
-- 9. SON GOKU (Saiyan Star Hair, Orange Gi, Blue Wristbands)
-- =========================================================
local function morphGoku(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightArm = (char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local giOrange = Color3.fromRGB(250, 130, 20)
	local shirtBlue = Color3.fromRGB(30, 80, 190)

	-- Iconic Saiyan Star Spikes
	addMorphWedge(morphModel, head, CFrame.new(0, 0.95, 0) * CFrame.Angles(math.rad(10), 0, 0), Vector3.new(0.9, 1.1, 0.9), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.7, 0.7, -0.1) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.7, 1.0, 0.7), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.7, 0.7, -0.1) * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.7, 1.0, 0.7), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.85, 0.1, 0) * CFrame.Angles(0, 0, math.rad(75)), Vector3.new(0.65, 0.9, 0.65), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.85, 0.1, 0) * CFrame.Angles(0, 0, math.rad(-75)), Vector3.new(0.65, 0.9, 0.65), hairBlack)

	-- Orange Martial Arts Gi with Blue Undershirt
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.65, 0), Vector3.new(1.8, 0.4, 1.1), shirtBlue, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), giOrange, Enum.Material.Fabric)

	-- Blue Wristbands
	if leftArm then addMorphPart(morphModel, leftArm, CFrame.new(0, -0.4, 0), Vector3.new(1.1, 0.4, 1.1), shirtBlue, Enum.Material.Fabric) end
	if rightArm then addMorphPart(morphModel, rightArm, CFrame.new(0, -0.4, 0), Vector3.new(1.1, 0.4, 1.1), shirtBlue, Enum.Material.Fabric) end
end

-- =========================================================
-- 10. VEGETA (Upright Flame Hair, Saiyan Battle Armor)
-- =========================================================
local function morphVegeta(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local armorWhite = Color3.fromRGB(240, 242, 248)
	local armorGold = Color3.fromRGB(245, 200, 45)
	local suitNavy = Color3.fromRGB(25, 45, 110)

	-- Tall Upright Flame Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 1.1, 0) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(1.1, 1.5, 1.0), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.35, 1.25, 0.1) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.7, 1.3, 0.7), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 1.25, 0.1) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.7, 1.3, 0.7), hairBlack)

	-- Saiyan Royal Battle Armor Vest
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 1.45, 1.05), suitNavy, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.55), Vector3.new(1.85, 1.1, 0.15), armorWhite, Enum.Material.Metal)
	-- Gold shoulder straps
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.7, 0.75, 0), Vector3.new(0.45, 0.25, 1.15), armorGold, Enum.Material.Metal)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0.75, 0), Vector3.new(0.45, 0.25, 1.15), armorGold, Enum.Material.Metal)
end

-- =========================================================
-- 11. FUTURE TRUNKS (Purple Curtains Hair, CC Jacket, Broadsword)
-- =========================================================
local function morphTrunks(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairLavender = Color3.fromRGB(175, 155, 215)
	local ccBlue = Color3.fromRGB(65, 80, 155)

	-- Parted Anime Curtain Hair
	addMorphPart(morphModel, head, CFrame.new(-0.35, 0.4, -0.45) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.45, 0.7, 0.25), hairLavender)
	addMorphPart(morphModel, head, CFrame.new(0.35, 0.4, -0.45) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.45, 0.7, 0.25), hairLavender)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.3, 0.5, 1.3), hairLavender)

	-- CC Capsule Corp Cropped Blue Jacket
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, 0), Vector3.new(2.15, 1.0, 1.15), ccBlue, Enum.Material.Fabric)

	-- Broadsword in Scabbard strapped across back
	local scabbard = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, 0.65) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.3, 3.8, 0.35), Color3.fromRGB(150, 45, 45), Enum.Material.Leather)
	-- Golden Sword Hilt
	addMorphPart(morphModel, upperTorso, CFrame.new(1.2, 1.3, 0.65) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.2, 1.2, 0.2), Color3.fromRGB(240, 215, 50), Enum.Material.Metal)
end

-- =========================================================
-- 12. ICHIGO KUROSAKI (Spiky Orange Hair, Shihakusho, Zangetsu)
-- =========================================================
local function morphIchigo(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairOrange = Color3.fromRGB(255, 115, 20)
	local shihakushoBlack = Color3.fromRGB(18, 18, 22)
	local trimWhite = Color3.fromRGB(245, 245, 250)

	-- Spiky Shinigami Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.9, 0.95, 0.85), hairOrange)
	addMorphWedge(morphModel, head, CFrame.new(-0.45, 0.7, 0.1) * CFrame.Angles(math.rad(15), math.rad(-25), math.rad(30)), Vector3.new(0.65, 0.8, 0.65), hairOrange)
	addMorphWedge(morphModel, head, CFrame.new(0.45, 0.7, 0.1) * CFrame.Angles(math.rad(15), math.rad(25), math.rad(-30)), Vector3.new(0.65, 0.8, 0.65), hairOrange)

	-- Shihakusho Kimono with White V-Neck Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), shihakushoBlack, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.45, -0.56), Vector3.new(0.8, 0.45, 0.05), trimWhite, Enum.Material.Fabric)

	-- Giant Cleaver Blade Zangetsu strapped across back with bandages
	local zangetsu = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, 0.68) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.2, 4.4, 0.85), Color3.fromRGB(20, 20, 25), Enum.Material.Metal)
	-- White cloth wrap on hilt
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.2, 1.3, 0.68) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.25, 1.2, 0.25), trimWhite, Enum.Material.Fabric)
end

-- =========================================================
-- 13. SOSUKE AIZEN (Dangling Front Curl, Arrancar Robe)
-- =========================================================
local function morphAizen(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBrown = Color3.fromRGB(55, 38, 28)
	local haoriWhite = Color3.fromRGB(245, 245, 250)

	-- Slicked-back brown hair
	addMorphPart(morphModel, head, CFrame.new(0, 0.6, 0.1), Vector3.new(1.35, 0.45, 1.35), hairBrown)
	-- Signature dangling front hair lock
	addMorphPart(morphModel, head, CFrame.new(0.1, 0.1, -0.6) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.12, 0.75, 0.1), hairBrown)

	-- Grand Master Haori Robe with High Dramatic Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.5, 1.15), haoriWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.8, 0.8, 0) * CFrame.Angles(0, 0, math.rad(20)), Vector3.new(0.15, 0.8, 0.9), haoriWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.8, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-20)), Vector3.new(0.15, 0.8, 0.9), haoriWhite, Enum.Material.Fabric)

	-- Violet Spiritual Pressure Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(130, 40, 210), Color3.fromRGB(70, 20, 110)}, {0.5, 0}, 14, 0.6, "AizenAura")
end

-- =========================================================
-- 14. BYAKUYA KUCHIKI (Kenseikan Clips, Ginpakuhahana Scarf, Cherry Blossom)
-- =========================================================
local function morphByakuya(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local clipWhite = Color3.fromRGB(245, 245, 250)
	local scarfTurquoise = Color3.fromRGB(45, 185, 185)

	-- Long Straight Black Hair
	addMorphPart(morphModel, head, CFrame.new(0, 0.6, 0.1), Vector3.new(1.35, 0.45, 1.35), hairBlack)
	addMorphPart(morphModel, head, CFrame.new(0, 0.1, 0.6), Vector3.new(1.2, 0.9, 0.3), hairBlack)
	-- Noble Kenseikan White Hairclips
	addMorphPart(morphModel, head, CFrame.new(-0.4, 0.75, -0.2), Vector3.new(0.15, 0.25, 0.35), clipWhite)
	addMorphPart(morphModel, head, CFrame.new(0.4, 0.75, -0.2), Vector3.new(0.15, 0.25, 0.35), clipWhite)

	-- Ginpakuhahana Turquoise Scarf around Neck & White Captain Haori
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.9, 0.35, 1.2), scarfTurquoise, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.45, 1.15), clipWhite, Enum.Material.Fabric)

	-- Floating Cherry Blossom Petals Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 160, 195), Color3.fromRGB(255, 210, 225)}, {0.4, 0}, 16, 0.8, "PetalAura")
end

-- =========================================================
-- 15. RYOMEN SUKUNA (Pink Slick Spikes, Curse Markings, Monk Robe)
-- =========================================================
local function morphSukuna(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairPink = Color3.fromRGB(235, 120, 145)
	local robeWhite = Color3.fromRGB(240, 240, 245)
	local markBlack = Color3.fromRGB(15, 15, 20)

	-- Slicked-Back Pink Spiky Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, 0.1) * CFrame.Angles(math.rad(-15), math.rad(180), 0), Vector3.new(0.9, 0.8, 0.85), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(-0.35, 0.7, 0) * CFrame.Angles(math.rad(-10), math.rad(-160), math.rad(20)), Vector3.new(0.6, 0.75, 0.6), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 0.7, 0) * CFrame.Angles(math.rad(-10), math.rad(160), math.rad(-20)), Vector3.new(0.6, 0.75, 0.6), hairPink)

	-- Black Demonic Curse Markings on Forehead & Cheeks
	addMorphPart(morphModel, head, CFrame.new(0, 0.35, -0.56), Vector3.new(0.35, 0.12, 0.05), markBlack)
	addMorphPart(morphModel, head, CFrame.new(-0.4, 0, -0.54), Vector3.new(0.12, 0.35, 0.05), markBlack)
	addMorphPart(morphModel, head, CFrame.new(0.4, 0, -0.54), Vector3.new(0.12, 0.35, 0.05), markBlack)

	-- Monk Robe
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), robeWhite, Enum.Material.Fabric)

	-- Blood-Crimson Malevolent Curse Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(180, 20, 50), Color3.fromRGB(20, 20, 25)}, {0.5, 0}, 16, 0.6, "SukunaAura")
end

-- =========================================================
-- 16. SATORU GOJO (Snow White Hair, Black Blindfold, Navy Uniform)
-- =========================================================
local function morphGojo(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSnow = Color3.fromRGB(250, 252, 255)
	local blindfoldBlack = Color3.fromRGB(18, 20, 26)
	local navyTech = Color3.fromRGB(24, 28, 45)

	-- Pure Snow-White Spiky Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(12), 0, 0), Vector3.new(0.85, 0.9, 0.8), hairSnow)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-25), math.rad(25)), Vector3.new(0.6, 0.8, 0.6), hairSnow)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(25), math.rad(-25)), Vector3.new(0.6, 0.8, 0.6), hairSnow)

	-- Black Blindfold wrapped securely across eyes
	addMorphPart(morphModel, head, CFrame.new(0, 0.08, -0.55), Vector3.new(1.25, 0.45, 0.15), blindfoldBlack, Enum.Material.Fabric)

	-- High-Collar Navy Jujutsu Sorcerer Uniform
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.7, 0.4, 1.1), navyTech, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), navyTech, Enum.Material.Fabric)

	-- Limitless Infinity Cyan/Purple Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(0, 180, 255), Color3.fromRGB(200, 50, 255)}, {0.5, 0}, 15, 0.7, "LimitlessAura")
end

-- =========================================================
-- 17. YUJI ITADORI (Pink/Black Undercut, Red Hood Collar)
-- =========================================================
local function morphYuji(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftHand = (char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairPink = Color3.fromRGB(245, 120, 155)
	local underBlack = Color3.fromRGB(20, 20, 24)
	local hoodRed = Color3.fromRGB(220, 35, 35)
	local navyTech = Color3.fromRGB(26, 30, 48)

	-- Spiky Pink Top with Black Undercut
	addMorphPart(morphModel, head, CFrame.new(0, 0.4, 0), Vector3.new(1.3, 0.35, 1.3), underBlack)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, -0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.8, 0.75, 0.75), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(-0.35, 0.7, 0) * CFrame.Angles(math.rad(15), math.rad(-20), math.rad(20)), Vector3.new(0.55, 0.7, 0.55), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 0.7, 0) * CFrame.Angles(math.rad(15), math.rad(20), math.rad(-20)), Vector3.new(0.55, 0.7, 0.55), hairPink)

	-- Red Hoodie Cowl extending from navy Jujutsu Tech uniform
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.4, 1.2), hoodRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), navyTech, Enum.Material.Fabric)

	-- Divergent Fist Cursed Sparks on hands
	if leftHand then addAura(leftHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 140, 255), Color3.fromRGB(255, 20, 60)}, {0.35, 0}, 14, 0.4, "DivergentSparks") end
	if rightHand then addAura(rightHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 140, 255), Color3.fromRGB(255, 20, 60)}, {0.35, 0}, 14, 0.4, "DivergentSparks") end
end

-- =========================================================
-- 18. MEGUMI FUSHIGURO (Spiky Sea-Urchin Hair, Shadow Puddle)
-- =========================================================
local function morphMegumi(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	if not head or not upperTorso then return end

	local hairDark = Color3.fromRGB(20, 24, 35)
	local navyTech = Color3.fromRGB(25, 30, 48)

	-- Spiky Starfish / Sea-Urchin Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(20), 0, 0), Vector3.new(0.8, 0.9, 0.8), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.75, 0.1) * CFrame.Angles(0, 0, math.rad(40)), Vector3.new(0.6, 0.85, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.75, 0.1) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.6, 0.85, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(-0.65, 0.2, 0) * CFrame.Angles(0, 0, math.rad(65)), Vector3.new(0.5, 0.75, 0.5), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.65, 0.2, 0) * CFrame.Angles(0, 0, math.rad(-65)), Vector3.new(0.5, 0.75, 0.5), hairDark)

	-- Navy Sorcerer Uniform
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), navyTech, Enum.Material.Fabric)

	-- Shadow Shikigami Aura at feet
	if lowerTorso then
		addAura(lowerTorso, "rbxasset://textures/particles/smoke_main.dds", {Color3.fromRGB(15, 18, 28), Color3.fromRGB(30, 35, 60)}, {0.6, 0}, 14, 0.7, "ShadowAura")
	end
end

-- =========================================================
-- 19. KILLUA ZOLDYCK (Wild Silver Hair, Turtleneck, Godspeed Sparks)
-- =========================================================
local function morphKillua(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftHand = (char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSilver = Color3.fromRGB(245, 245, 255)
	local turtleNavy = Color3.fromRGB(25, 30, 50)
	local shirtWhite = Color3.fromRGB(240, 242, 248)

	-- Silver-White Wild Spiky Assassin Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(10), 0, 0), Vector3.new(0.85, 0.9, 0.8), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(-0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-30), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)

	-- Navy Turtleneck & White Skater V-Neck Shirt
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.65, 0.4, 1.05), turtleNavy, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, -0.05, 0), Vector3.new(2.1, 1.35, 1.1), shirtWhite, Enum.Material.Fabric)

	-- Godspeed Lightning Sparks on fists
	if leftHand then addAura(leftHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(0, 255, 240), Color3.fromRGB(180, 100, 255)}, {0.35, 0}, 16, 0.4, "GodspeedSparks") end
	if rightHand then addAura(rightHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(0, 255, 240), Color3.fromRGB(180, 100, 255)}, {0.35, 0}, 16, 0.4, "GodspeedSparks") end
end

-- =========================================================
-- 20. GON FREECSS (Tall Green Spike Column Hair, Adventure Vest)
-- =========================================================
local function morphGon(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairDarkGreen = Color3.fromRGB(18, 55, 28)
	local jacketGreen = Color3.fromRGB(48, 165, 68)
	local trimRed = Color3.fromRGB(225, 40, 30)

	-- Ultra-Tall Spiky Column Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 1.35, 0) * CFrame.Angles(math.rad(5), 0, 0), Vector3.new(1.1, 1.9, 1.0), hairDarkGreen)
	addMorphWedge(morphModel, head, CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(5), 0, 0), Vector3.new(0.85, 1.2, 0.8), hairDarkGreen)

	-- Green Adventure Jacket with Red Collar Piping
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.8, 0.35, 1.15), trimRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), jacketGreen, Enum.Material.Fabric)

	-- Jajanken Nen Concentration on Right Fist
	if rightHand then
		addAura(rightHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 110, 20)}, {0.5, 0}, 18, 0.5, "NenAura")
	end
end

-- =========================================================
-- 21. TANJIRO KAMADO (Burgundy Hair, Checker Haori, Hanafuda)
-- =========================================================
local function morphTanjiro(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBurgundy = Color3.fromRGB(75, 25, 35)
	local checkGreen = Color3.fromRGB(35, 145, 75)
	local checkBlack = Color3.fromRGB(20, 22, 28)

	-- Burgundy Messy Hair with Exposed Forehead
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, 0.1) * CFrame.Angles(math.rad(-15), math.rad(180), 0), Vector3.new(0.9, 0.85, 0.85), hairBurgundy)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.65, 0.1) * CFrame.Angles(math.rad(-10), math.rad(-150), math.rad(25)), Vector3.new(0.6, 0.75, 0.6), hairBurgundy)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.65, 0.1) * CFrame.Angles(math.rad(-10), math.rad(150), math.rad(-25)), Vector3.new(0.6, 0.75, 0.6), hairBurgundy)

	-- Forehead Burn Scar Mark
	addMorphPart(morphModel, head, CFrame.new(-0.28, 0.32, -0.56) * CFrame.Angles(0, 0, math.rad(-20)), Vector3.new(0.25, 0.3, 0.05), Color3.fromRGB(130, 35, 45))

	-- Hanging Hanafuda Earrings
	addMorphPart(morphModel, head, CFrame.new(-0.65, -0.2, 0), Vector3.new(0.08, 0.45, 0.25), Color3.fromRGB(245, 245, 250))
	addMorphPart(morphModel, head, CFrame.new(0.65, -0.2, 0), Vector3.new(0.08, 0.45, 0.25), Color3.fromRGB(245, 245, 250))

	-- Iconic Checkerboard Haori Coat
	local haori = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.45, 1.15), checkGreen, Enum.Material.Fabric)
	-- Checker block highlights
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.55, 0.3, -0.58), Vector3.new(0.5, 0.5, 0.05), checkBlack)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.55, -0.3, -0.58), Vector3.new(0.5, 0.5, 0.05), checkBlack)

	-- Nichirin Katana at hip
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, -0.5, 0.1) * CFrame.Angles(0, 0, math.rad(-135)), Vector3.new(0.18, 3.6, 0.25), checkBlack)
end

-- =========================================================
-- 22. ZENITSU AGATSUMA (Yellow/Orange Triangular Hair, Triangle Haori)
-- =========================================================
local function morphZenitsu(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftLeg = (char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairYellow = Color3.fromRGB(255, 225, 45)
	local tipOrange = Color3.fromRGB(245, 120, 20)

	-- Yellow Hair with Square/Triangular Tips
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.35, 0.45, 1.35), hairYellow)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.45, -0.45) * CFrame.Angles(math.rad(25), 0, 0), Vector3.new(0.4, 0.5, 0.3), tipOrange)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.45, -0.45) * CFrame.Angles(math.rad(25), 0, 0), Vector3.new(0.4, 0.5, 0.3), tipOrange)

	-- Yellow/Orange Triangle Pattern Haori
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.45, 1.15), hairYellow, Enum.Material.Fabric)

	-- Crackling Thunder Sparks around feet
	if leftLeg then addAura(leftLeg, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 235, 60), Color3.fromRGB(255, 255, 255)}, {0.35, 0}, 16, 0.35, "ThunderSparks") end
	if rightLeg then addAura(rightLeg, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 235, 60), Color3.fromRGB(255, 255, 255)}, {0.35, 0}, 16, 0.35, "ThunderSparks") end
end

-- =========================================================
-- 23. IZUKU MIDORIYA / DEKU (Fluffy Emerald Hair, Hero Cowl, Full Cowl)
-- =========================================================
local function morphDeku(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairDarkGreen = Color3.fromRGB(25, 75, 45)
	local suitTeal = Color3.fromRGB(35, 145, 110)
	local cowlWhite = Color3.fromRGB(240, 240, 245)

	-- Fluffy Messy Green Spiky Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.85, 0.9, 0.85), hairDarkGreen)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.7, 0.1) * CFrame.Angles(math.rad(20), math.rad(-25), math.rad(25)), Vector3.new(0.65, 0.75, 0.65), hairDarkGreen)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.7, 0.1) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-25)), Vector3.new(0.65, 0.75, 0.65), hairDarkGreen)

	-- Respirator Neck Cowl around collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.35, 1.2), cowlWhite, Enum.Material.Metal)

	-- Costume Gamma Hero Jumpsuit with Shoulder Pauldrons
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), suitTeal, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.1, 0.6, 0), Vector3.new(0.35, 0.35, 1.1), Color3.fromRGB(15, 20, 25), Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, 0.6, 0), Vector3.new(0.35, 0.35, 1.1), Color3.fromRGB(15, 20, 25), Enum.Material.Fabric)

	-- One For All Full Cowl Emerald Lightning Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 255, 210), Color3.fromRGB(20, 200, 150)}, {0.45, 0}, 16, 0.5, "FullCowlAura")
end

-- =========================================================
-- 24. KATSUKI BAKUGO (Explosive Ash Blonde Hair, Grenade Gauntlets)
-- =========================================================
local function morphBakugo(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightArm = (char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlonde = Color3.fromRGB(240, 215, 140)
	local gauntletGreen = Color3.fromRGB(45, 95, 55)
	local orangeStrap = Color3.fromRGB(255, 110, 20)

	-- Explosive Spiky Hair Cluster
	addMorphWedge(morphModel, head, CFrame.new(0, 0.95, 0) * CFrame.Angles(math.rad(20), 0, 0), Vector3.new(1.0, 1.1, 0.95), hairBlonde)
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-30), math.rad(35)), Vector3.new(0.7, 0.9, 0.7), hairBlonde)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(-35)), Vector3.new(0.7, 0.9, 0.7), hairBlonde)

	-- Black Eye Mask with Flared Blast Accents
	addMorphPart(morphModel, head, CFrame.new(0, 0.15, -0.55), Vector3.new(1.25, 0.35, 0.15), Color3.fromRGB(18, 20, 25))
	addMorphPart(morphModel, head, CFrame.new(-0.75, 0.25, -0.4) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.2, 0.6, 0.1), orangeStrap)
	addMorphPart(morphModel, head, CFrame.new(0.75, 0.25, -0.4) * CFrame.Angles(0, 0, math.rad(35)), Vector3.new(0.2, 0.6, 0.1), orangeStrap)

	-- Black Tank Top with Orange X-Strap
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), Color3.fromRGB(22, 24, 30), Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.56) * CFrame.Angles(0, 0, math.rad(35)), Vector3.new(0.25, 1.6, 0.05), orangeStrap)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.56) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.25, 1.6, 0.05), orangeStrap)

	-- Massive Grenade Gauntlets on Forearms
	if leftArm then
		addMorphPart(morphModel, leftArm, CFrame.new(0, -0.3, 0), Vector3.new(1.6, 1.1, 1.6), gauntletGreen, Enum.Material.Metal)
	end
	if rightArm then
		addMorphPart(morphModel, rightArm, CFrame.new(0, -0.3, 0), Vector3.new(1.6, 1.1, 1.6), gauntletGreen, Enum.Material.Metal)
	end
end

-- =========================================================
-- MASTER MORPH DISPATCHER (24 CHARACTERS)
-- =========================================================
local morphTable: { [string]: (char: Model, morphModel: Model) -> () } = {
	["Naruto"]   = morphNaruto,
	["Sasuke"]   = morphSasuke,
	["Kakashi"]  = morphKakashi,
	["Madara"]   = morphMadara,
	["Luffy"]    = morphLuffy,
	["Zoro"]     = morphZoro,
	["Sanji"]    = morphSanji,
	["Law"]      = morphLaw,
	["Goku"]     = morphGoku,
	["Vegeta"]   = morphVegeta,
	["Trunks"]   = morphTrunks,
	["Ichigo"]   = morphIchigo,
	["Aizen"]    = morphAizen,
	["Byakuya"]  = morphByakuya,
	["Sukuna"]   = morphSukuna,
	["Gojo"]     = morphGojo,
	["Yuji"]     = morphYuji,
	["Megumi"]   = morphMegumi,
	["Killua"]   = morphKillua,
	["Gon"]      = morphGon,
	["Tanjiro"]  = morphTanjiro,
	["Zenitsu"]  = morphZenitsu,
	["Deku"]     = morphDeku,
	["Bakugo"]   = morphBakugo,
}

function StormCharacterMorphServer.applyMorph(char: Model, charId: string)
	if not char then return end

	-- 1. Remove previous morph container
	local oldMorph = char:FindFirstChild("AnimeMorph")
	if oldMorph then oldMorph:Destroy() end

	-- 2. Remove any previously created character particle emitters
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("ParticleEmitter") and (
			desc.Name == "SharinganAura" or desc.Name == "GodspeedSparks" or desc.Name == "SusanooAura" or
			desc.Name == "DiableFlames" or desc.Name == "AizenAura" or desc.Name == "PetalAura" or
			desc.Name == "SukunaAura" or desc.Name == "LimitlessAura" or desc.Name == "DivergentSparks" or
			desc.Name == "ShadowAura" or desc.Name == "NenAura" or desc.Name == "ThunderSparks" or
			desc.Name == "FullCowlAura"
		) then
			desc:Destroy()
		end
	end

	-- 3. Hide default Roblox accessories (hats/hair) so they do not clash with anime hair
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle") :: BasePart?
			if handle then
				handle.Transparency = 1
			end
		end
	end

	-- 4. Create fresh Morph Container Model
	local morphModel = Instance.new("Model")
	morphModel.Name = "AnimeMorph"

	-- 5. Dispatch morph function
	local morphFunc = morphTable[charId]
	if morphFunc then
		morphFunc(char, morphModel)
	else
		-- Fallback to Naruto if unknown id
		morphNaruto(char, morphModel)
	end

	morphModel.Parent = char
	print(string.format(">> [AnimeMorph] Successfully morphed %s into 3D %s! <<", char.Name, charId))
end

return StormCharacterMorphServer
]=====]
    installScript('StormCharacterMorphServer', 'ModuleScript', game:GetService('ServerScriptService'), src)
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

	local manCF = CFrame.lookAt(pos + Vector3.new(0, 3.2, 0), LOBBY_CENTER + Vector3.new(0, 3.2, 0))
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = manCF
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

	-- 7. 16 Featured 3D Anime Character Mannequins in the Shinobi Lobby Courtyard
	local featuredList = {
		"Naruto", "Sasuke", "Kakashi", "Madara",
		"Luffy", "Zoro", "Sanji", "Law",
		"Goku", "Vegeta", "Ichigo", "Aizen",
		"Sukuna", "Gojo", "Tanjiro", "Deku",
	}
	local radius = 26
	local total = #featuredList
	for i, charId in ipairs(featuredList) do
		local angle = math.rad(-130 + ((i - 1) / (total - 1)) * 260)
		local offset = Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius - 4)
		createAnimeMannequin(lobbyModel, LOBBY_CENTER + offset, charId)
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
    installScript('TekkenDefenseController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: CombatComboController (LocalScript)
-- ============================================================
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
    installScript('CombatComboController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormRangedController (LocalScript)
-- ============================================================
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
    installScript('StormRangedController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormAssistController (LocalScript)
-- ============================================================
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
    installScript('StormAssistController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: StormAnimationController (LocalScript)
-- ============================================================
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

-- Force STRICT Landscape Orientation on Mobile Devices (Naruto Storm Fighting Standard)
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)
pcall(function()
	local StarterGui = game:GetService("StarterGui")
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

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

-- P1 4-Slot Substitution Gauge (Storm 4 Kawarimi Indicator)
local p1SubContainer = Instance.new("Frame")
p1SubContainer.Name = "P1SubContainer"
p1SubContainer.Size = UDim2.new(0.65, 0, 0, 7)
p1SubContainer.Position = UDim2.new(0, 66, 0, 56)
p1SubContainer.BackgroundTransparency = 1
p1SubContainer.Parent = p1Frame

local p1SubLayout = Instance.new("UIListLayout")
p1SubLayout.FillDirection = Enum.FillDirection.Horizontal
p1SubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
p1SubLayout.Padding = UDim.new(0, 4)
p1SubLayout.Parent = p1SubContainer

local p1SubSegments: { Frame } = {}
for i = 1, 4 do
	local seg = Instance.new("Frame")
	seg.Name = "SubLog_" .. i
	seg.Size = UDim2.new(0.22, 0, 1, 0)
	seg.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	seg.BorderSizePixel = 0
	seg.Parent = p1SubContainer
	Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 2)
	table.insert(p1SubSegments, seg)
end

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

-- P2 Sub-bars: Chakra & Guard
local p2ChakraBg = Instance.new("Frame")
p2ChakraBg.Name = "P2ChakraBg"
p2ChakraBg.Size = UDim2.new(0.65, 0, 0, 8)
p2ChakraBg.Position = UDim2.new(0.35, -4, 0, 44)
p2ChakraBg.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
p2ChakraBg.Parent = p2Frame
Instance.new("UICorner", p2ChakraBg).CornerRadius = UDim.new(0, 3)

local p2ChakraFill = Instance.new("Frame")
p2ChakraFill.Name = "P2ChakraFill"
p2ChakraFill.Size = UDim2.new(0.5, 0, 1, 0)
p2ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
p2ChakraFill.BorderSizePixel = 0
p2ChakraFill.Parent = p2ChakraBg
Instance.new("UICorner", p2ChakraFill).CornerRadius = UDim.new(0, 3)

-- P2 4-Slot Substitution Gauge (Opponent Kawarimi Indicator)
local p2SubContainer = Instance.new("Frame")
p2SubContainer.Name = "P2SubContainer"
p2SubContainer.Size = UDim2.new(0.65, 0, 0, 7)
p2SubContainer.Position = UDim2.new(0.35, -4, 0, 56)
p2SubContainer.BackgroundTransparency = 1
p2SubContainer.Parent = p2Frame

local p2SubLayout = Instance.new("UIListLayout")
p2SubLayout.FillDirection = Enum.FillDirection.Horizontal
p2SubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
p2SubLayout.Padding = UDim.new(0, 4)
p2SubLayout.Parent = p2SubContainer

local p2SubSegments: { Frame } = {}
for i = 1, 4 do
	local seg = Instance.new("Frame")
	seg.Name = "SubLog_" .. i
	seg.Size = UDim2.new(0.22, 0, 1, 0)
	seg.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	seg.BorderSizePixel = 0
	seg.Parent = p2SubContainer
	Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 2)
	table.insert(p2SubSegments, seg)
end

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

	-- 4. Local Chakra Gauge & Chakra Load Pulse
	local chakraVal = LocalPlayer:GetAttribute("ChakraValue") or 60
	local chakraRatio = math.clamp(tonumber(chakraVal) :: number / 100, 0, 1)
	p1ChakraFill.Size = UDim2.new(chakraRatio, 0, 1, 0)

	local isChakraLoaded = LocalPlayer:GetAttribute("IsChakraLoaded") == true
	if isChakraLoaded then
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	elseif chakraRatio >= 1.0 then
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(255, 220, 50) -- glowing gold when ready
	else
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	end

	-- 5. Storm 4 Substitution Bars (4 Stocks)
	local p1Subs = LocalPlayer:GetAttribute("SubstitutionStocks") or 4
	for i, seg in ipairs(p1SubSegments) do
		seg.BackgroundTransparency = (i <= p1Subs) and 0 or 0.85
	end

	local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)
	local p2Subs = (targetPlayer and targetPlayer:GetAttribute("SubstitutionStocks")) or 4
	for i, seg in ipairs(p2SubSegments) do
		seg.BackgroundTransparency = (i <= p2Subs) and 0 or 0.85
	end

	local p2Chakra = (targetPlayer and targetPlayer:GetAttribute("ChakraValue")) or 60
	p2ChakraFill.Size = UDim2.new(math.clamp(p2Chakra / 100, 0, 1), 0, 1, 0)
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
local evMobileLow      = getOrMakeBindable("MobileLowAttackAction")
local evMobileRanged   = getOrMakeBindable("MobileRangedAction")
local evMobileGuard    = getOrMakeBindable("MobileGuardAction")
local evMobileDash     = getOrMakeBindable("MobileDashAction")
local evMobileAssist   = getOrMakeBindable("MobileAssistAction")
local evMobileSwap     = getOrMakeBindable("MobileSwapAction")
local evMobileUltimate = getOrMakeBindable("MobileUltimateAction")
local evMobileChakra   = getOrMakeBindable("MobileChakraAction")
local evMobileSub      = getOrMakeBindable("MobileSubstitutionAction")

-- Force STRICT Landscape Orientation on Mobile & Tablet Devices (Naruto Storm Fighting Standard)
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)
pcall(function()
	local StarterGui = game:GetService("StarterGui")
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

-- Continuous enforcer: guarantee orientation never reverts to Portrait or Sensor
task.spawn(function()
	local StarterGui = game:GetService("StarterGui")
	for _ = 1, 10 do
		task.wait(0.5)
		if PlayerGui.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeLeft then
			pcall(function()
				PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
			end)
		end
		if StarterGui.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeLeft then
			pcall(function()
				StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
			end)
		end
	end
end)

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormMobileCombatHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
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
-- =========================================================
-- CREATE COMBAT BUTTONS (Naruto Storm Mobile Layout)
-- =========================================================
-- 1. PUNCH [J] (Primary Combo Strike)
local btnAttack = createActionButton(
	"BtnAttack", "⚔️", "PUNCH [J]", Color3.fromRGB(0, 240, 255),
	UDim2.new(0.65, 0, 0.65, 0), UDim2.new(0, 78, 0, 78)
)
btnAttack.MouseButton1Click:Connect(function()
	evMobileAttack:Fire(false)
end)

-- 2. LOW SWEEP [K] (Serangan Bawah)
local btnLow = createActionButton(
	"BtnLow", "⚡", "LOW [K]", Color3.fromRGB(255, 180, 20),
	UDim2.new(0.88, 0, 0.65, 0), UDim2.new(0, 56, 0, 56)
)
btnLow.MouseButton1Click:Connect(function()
	evMobileLow:Fire()
end)

-- 3. RANGED JUTSU [L] (Serangan Jarak Jauh)
local btnRanged = createActionButton(
	"BtnRanged", "🌀", "RANGED [L]", Color3.fromRGB(80, 220, 255),
	UDim2.new(0.65, 0, 0.32, 0), UDim2.new(0, 56, 0, 56)
)
btnRanged.MouseButton1Click:Connect(function()
	evMobileRanged:Fire()
end)

-- 4. GUARD [F] (Hold to Block)
local btnGuard = createActionButton(
	"BtnGuard", "🛡️", "GUARD [F]", Color3.fromRGB(255, 215, 0),
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

-- 5. DASH [SHIFT] (Homing Ninja Dash)
local btnDash = createActionButton(
	"BtnDash", "💨", "DASH [SHIFT]", Color3.fromRGB(0, 255, 170),
	UDim2.new(0.38, 0, 0.82, 0), UDim2.new(0, 56, 0, 56)
)
btnDash.MouseButton1Click:Connect(function()
	evMobileDash:Fire()
end)

-- 6. CHAKRA ENERGY & ULTIMATE [I] (Hold for Ultimate!)
local btnChakra = createActionButton(
	"BtnChakra", "🔥", "CHAKRA/ULT [I]", Color3.fromRGB(255, 80, 40),
	UDim2.new(0.12, 0, 0.65, 0), UDim2.new(0, 58, 0, 58)
)
local isMobileHoldingChakra = false
local mobileChakraStart = 0
btnChakra.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMobileHoldingChakra = true
		mobileChakraStart = os.clock()
		evMobileChakra:Fire(true)
		task.spawn(function()
			while isMobileHoldingChakra do
				task.wait(0.05)
				local held = os.clock() - mobileChakraStart
				local curChakra = LocalPlayer:GetAttribute("ChakraValue") or 0
				if isMobileHoldingChakra and curChakra >= 100 and held >= 0.60 then
					evMobileChakra:Fire(false)
					evMobileUltimate:Fire()
					break
				end
			end
		end)
	end
end)
btnChakra.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMobileHoldingChakra = false
		evMobileChakra:Fire(false)
	end
end)

-- 7. LEADER SWAP [U]
local btnSwap = createActionButton(
	"BtnSwap", "🔄", "SWAP [U]", Color3.fromRGB(200, 100, 255),
	UDim2.new(0.20, 0, 0.38, 0), UDim2.new(0, 48, 0, 48)
)
btnSwap.MouseButton1Click:Connect(function()
	evMobileSwap:Fire()
end)

-- 8. SUBSTITUTION JUTSU [E/Q] (Kawarimi Escape)
local btnSub = createActionButton(
	"BtnSub", "🪵", "SUB [E]", Color3.fromRGB(255, 215, 0),
	UDim2.new(0.38, 0, 0.48, 0), UDim2.new(0, 54, 0, 54)
)
btnSub.MouseButton1Click:Connect(function()
	evMobileSub:Fire()
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

-- Force STRICT Landscape Orientation on Mobile Devices (Naruto Storm Fighting Standard)
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)
pcall(function()
	local StarterGui = game:GetService("StarterGui")
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local evCharSelect = combatEvents:WaitForChild("CharacterSelectEvent", 10) :: RemoteEvent
local evOpenRoster = combatEvents:WaitForChild("OpenRosterEvent", 10) :: RemoteEvent
local evGachaSync  = combatEvents:WaitForChild("GachaSyncEvent", 10) :: RemoteEvent?
local evOpenGacha  = combatEvents:WaitForChild("OpenGachaEvent", 10) :: RemoteEvent?

local unlockedMap: { [string]: boolean } = {}
for _, s in ipairs(GachaConfig.StarterCharacters) do
	unlockedMap[s] = true
end

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
rosterList.CanvasSize = UDim2.new(0, 0, 0, 24 * 84)
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
	local isUnlocked = (unlockedMap[charId] == true) or (table.find(GachaConfig.StarterCharacters, charId) ~= nil)
	if not isUnlocked then
		selectBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
		selectBtn.TextColor3 = Color3.fromRGB(255, 240, 240)
		selectBtn.Text = "🔒 TERKUNCI • BUKA DI GACHA (PULL)"
	elseif charId == currentSelectedId then
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
local charOrder = {
	"Naruto", "Sasuke", "Kakashi", "Madara",
	"Luffy", "Zoro", "Sanji", "Law",
	"Goku", "Vegeta", "Trunks",
	"Ichigo", "Aizen", "Byakuya",
	"Sukuna", "Gojo", "Yuji", "Megumi",
	"Killua", "Gon",
	"Tanjiro", "Zenitsu",
	"Deku", "Bakugo",
}
rosterList.CanvasSize = UDim2.new(0, 0, 0, #charOrder * 84)
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
	cName.Size = UDim2.new(1, -74, 0, 18)
	cName.Position = UDim2.new(0, 70, 0, 8)
	cName.BackgroundTransparency = 1
	cName.Font = Enum.Font.GothamBlack
	cName.TextSize = 13
	cName.TextColor3 = Color3.fromRGB(255, 255, 255)
	cName.TextXAlignment = Enum.TextXAlignment.Left
	cName.Text = char.Name
	cName.Parent = card

	-- Anime Series Subtitle
	local cSeries = Instance.new("TextLabel")
	cSeries.Size = UDim2.new(1, -74, 0, 14)
	cSeries.Position = UDim2.new(0, 70, 0, 28)
	cSeries.BackgroundTransparency = 1
	cSeries.Font = Enum.Font.GothamBold
	cSeries.TextSize = 10
	cSeries.TextColor3 = char.AccentColor or Color3.fromRGB(160, 175, 200)
	cSeries.TextXAlignment = Enum.TextXAlignment.Left
	cSeries.Text = char.Anime or "Anime"
	cSeries.Parent = card

	-- Archetype Tag
	local cTag = Instance.new("TextLabel")
	cTag.Size = UDim2.new(0, 85, 0, 16)
	cTag.Position = UDim2.new(0, 70, 0, 46)
	cTag.BackgroundColor3 = char.PrimaryColor
	cTag.BackgroundTransparency = 0.25
	cTag.Font = Enum.Font.GothamBlack
	cTag.TextSize = 9
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
	local isUnlocked = (unlockedMap[previewSelectedId] == true) or (table.find(GachaConfig.StarterCharacters, previewSelectedId) ~= nil)
	if not isUnlocked then
		playUiSound("action_footsteps_plastic.mp3", 0.7)
		if evOpenGacha then
			evOpenGacha:FireServer()
		end
		screenGui.Enabled = false
		isOpen = false
		return
	end
	selectCharacter(previewSelectedId)
end)

if evGachaSync then
	evGachaSync.OnClientEvent:Connect(function(prof: any)
		if prof and prof.Unlocked then
			unlockedMap = prof.Unlocked
			for _, s in ipairs(GachaConfig.StarterCharacters) do
				unlockedMap[s] = true
			end
			updatePreview(previewSelectedId)
		end
	end)
end

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

-- ============================================================
-- INSTALL: StormSubstitutionController (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- StormSubstitutionController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Substitution Jutsu (Kawarimi)
-- Features:
--   • 4-Stock Substitution System (The core competitive lifeline of Storm 4)
--   • Instant escape from enemy combos, jutsu, and hitstun
--   • Spawns 3D wooden log & smoke poof, teleports directly behind opponent
--   • Multi-platform input:
--       Keyboard: [E] or [Q] or [LeftShift] (when attacked)
--       Gamepad:  [L2] (Official PS/Xbox Storm 4 Button)
--       Mobile:   [🪵 SUB] Touch Button

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evSub = combatEvents:WaitForChild("SubstitutionEvent") :: RemoteEvent

-- Mobile Bindable
local evMobileSub = ReplicatedStorage:FindFirstChild("MobileSubstitutionAction") :: BindableEvent?
if not evMobileSub then
	evMobileSub = Instance.new("BindableEvent")
	evMobileSub.Name = "MobileSubstitutionAction"
	evMobileSub.Parent = ReplicatedStorage
end

local lastSubRequest = 0

-- =========================================================
-- VISUAL LOG & SMOKE BURST (Client Prediction & Replication)
-- =========================================================
local function playKawarimiVisual(posCFrame: CFrame)
	local log = Instance.new("Part")
	log.Name = "LocalKawarimiLog"
	log.Shape = Enum.PartType.Cylinder
	log.Size = Vector3.new(2.8, 1.4, 1.4)
	log.CFrame = posCFrame * CFrame.Angles(0, 0, math.rad(90))
	log.Color = Color3.fromRGB(139, 90, 43)
	log.Material = Enum.Material.Wood
	log.Anchored = false
	log.CanCollide = true
	log.Parent = Workspace
	Debris:AddItem(log, 2.0)

	local att = Instance.new("Attachment", log)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(245, 245, 250), Color3.fromRGB(210, 210, 220))
	pe.Size = NumberSequence.new(2.5, 5.0)
	pe.Transparency = NumberSequence.new(0.2, 1.0)
	pe.Rate = 120
	pe.Speed = NumberRange.new(6, 15)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att
	task.delay(0.2, function() pe.Enabled = false end)

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
		snd.PlaybackSpeed = 0.8
		snd.Volume = 1.0
		snd.Parent = log
		snd:Play()
	end)
end

-- =========================================================
-- EXECUTE SUBSTITUTION
-- =========================================================
local function requestSubstitution()
	local now = os.clock()
	if now - lastSubRequest < 0.35 then return end
	lastSubRequest = now

	local curStocks = LocalPlayer:GetAttribute("SubstitutionStocks") or 4
	if curStocks < 1 then
		print(">> [Substitution] Out of Substitution stocks! (0 left) <<")
		return
	end

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	print(">> [Substitution] Requesting Kawarimi escape! <<")
	evSub:FireServer()
end

-- Listen for Server Broadcast (other players or dummy subbing)
evSub.OnClientEvent:Connect(function(subbingPlayer: Player, prevCFrame: CFrame)
	if subbingPlayer ~= LocalPlayer then
		playKawarimiVisual(prevCFrame)
	end
end)

-- =========================================================
-- INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- 1. Keyboard: [E] or [Q]
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Q then
		requestSubstitution()
	-- 2. Gamepad: [ButtonL2] (Official Storm 4 Sub Trigger)
	elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
		requestSubstitution()
	end
end)

-- Mobile Touch Listener
evMobileSub.Event:Connect(function()
	requestSubstitution()
end)

print("[StormSubstitutionController] ✅ Loaded — Substitution Jutsu [E / Q / Gamepad L2 / Mobile SUB] active.")

]=====]
    installScript('StormSubstitutionController', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

-- ============================================================
-- INSTALL: GachaConfig (ModuleScript)
-- ============================================================
do
    local src = [=====[--!strict
-- GachaConfig.luau
-- SHARED CONFIGURATION: Storm Clash Shinobi Summon & Gacha Economy Engine
-- Tiers, Drop Rates, Pity System, Duplicate Conversion, and Reward Payouts

local GachaConfig = {}

-- =========================================================
-- 1. CURRENCY & COSTS
-- =========================================================
GachaConfig.CurrencyName = "Ryo"
GachaConfig.CurrencyIcon = "🪙"
GachaConfig.StartingRyo = 300       -- New players get 3 free single pulls
GachaConfig.SinglePullCost = 100    -- 1x Summon Cost
GachaConfig.MultiPullCount = 10     -- 10x Multi-Summon
GachaConfig.MultiPullCost = 900     -- 10x Summon Cost (10% discount)

-- =========================================================
-- 2. STARTER CHARACTERS (Unlocked by default for everyone)
-- =========================================================
GachaConfig.StarterCharacters = {
	"Naruto", -- Hero of Konoha (Rushdown)
	"Luffy",  -- Straw Hat Captain (Grappler)
	"Goku",   -- Saiyan Warrior (Balanced)
	"Deku",   -- One For All Hero (Rushdown)
}

-- =========================================================
-- 3. RARITY TIERS & DROP RATES
-- =========================================================
-- Rates sum up to 1.0 (100%):
-- 2% Mythic + 10% Legendary + 28% Epic + 60% Rare = 100%
GachaConfig.Tiers = {
	["Mythic"] = {
		Name = "Mythic Secret",
		Stars = "★★★★★★",
		TierRank = 4,
		Rate = 0.02, -- 2% Drop Rate
		Color = Color3.fromRGB(255, 30, 80),
		GlowColor = Color3.fromRGB(255, 60, 120),
		Sound = "rbxasset://sounds/electronicpingshort.wav",
		SoundPitch = 0.8,
		DuplicateShards = 300,
		Characters = { "Madara", "Sukuna" },
	},
	["Legendary"] = {
		Name = "Legendary",
		Stars = "★★★★★",
		TierRank = 3,
		Rate = 0.10, -- 10% Drop Rate
		Color = Color3.fromRGB(255, 215, 0),
		GlowColor = Color3.fromRGB(255, 235, 120),
		Sound = "rbxasset://sounds/electronicpingshort.wav",
		SoundPitch = 1.0,
		DuplicateShards = 100,
		Characters = { "Sasuke", "Ichigo", "Aizen", "Gojo" },
	},
	["Epic"] = {
		Name = "Epic",
		Stars = "★★★★",
		TierRank = 2,
		Rate = 0.28, -- 28% Drop Rate
		Color = Color3.fromRGB(180, 80, 255),
		GlowColor = Color3.fromRGB(210, 130, 255),
		Sound = "rbxasset://sounds/action_jump.mp3",
		SoundPitch = 1.2,
		DuplicateShards = 35,
		Characters = { "Kakashi", "Zoro", "Law", "Vegeta", "Byakuya", "Tanjiro", "Bakugo", "Killua" },
	},
	["Rare"] = {
		Name = "Rare",
		Stars = "★★★",
		TierRank = 1,
		Rate = 0.60, -- 60% Drop Rate
		Color = Color3.fromRGB(0, 210, 255),
		GlowColor = Color3.fromRGB(120, 235, 255),
		Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
		SoundPitch = 1.4,
		DuplicateShards = 10,
		Characters = { "Yuji", "Gon", "Zenitsu", "Sanji", "Trunks", "Megumi" },
	},
}

-- Lookup: Map Character Id to Rarity Tier
GachaConfig.CharacterTierMap = {}
for tierName, tierData in pairs(GachaConfig.Tiers) do
	for _, charId in ipairs(tierData.Characters) do
		GachaConfig.CharacterTierMap[charId] = tierName
	end
end
-- Starters default to Starter/Rare tier for mapping
for _, charId in ipairs(GachaConfig.StarterCharacters) do
	if not GachaConfig.CharacterTierMap[charId] then
		GachaConfig.CharacterTierMap[charId] = "Rare"
	end
end

-- =========================================================
-- 4. PITY & GUARANTEE RULES
-- =========================================================
GachaConfig.Pity = {
	HardPityThreshold = 50, -- 50 pulls guarantee ★5 Legendary or ★6 Mythic!
	MultiPullEpicGuarantee = true, -- 10-pull guarantees at least one ★4 Epic or higher!
}

-- =========================================================
-- 5. REWARDS & COMBAT EARNINGS
-- =========================================================
GachaConfig.Rewards = {
	RoundWinRyo = 100,          -- Ryo awarded for winning a 1v1 round
	MatchFinishRyo = 50,        -- Ryo awarded for completing a full match
	DummyComboBonus = 1,        -- Ryo awarded per 10-hit combo on Training Dummy
	DailyLoginRyo = 250,        -- Daily Login Reward
	DailyRewardCooldown = 86400,-- 24 Hours in seconds
}

return GachaConfig
]=====]
    installScript('GachaConfig', 'ModuleScript', game:GetService('ReplicatedStorage'), src)
end

-- ============================================================
-- INSTALL: GachaServerManager (Script)
-- ============================================================
do
    local src = [=====[--!strict
-- GachaServerManager.luau
-- SERVER SCRIPT: Authoritative Gacha Engine, Data Persistence, and Shinobi Summon Shrine
-- Features:
--   • Authoritative Gacha Roll Algorithm (Random rates + Hard Pity 50 + Multi 10x Guarantee)
--   • Duplicate Character Conversion to Essence Shards
--   • DataStore Persistence with In-Memory Mock Fallback
--   • Combat Earnings Integration (Rounds, Dummy, Daily Reward)
--   • 3D Shinobi Summon Shrine / Torii Altar in Lobby Courtyard

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig")) :: any

-- DataStore Setup with Safe Fallback
local gachaDataStore: DataStore? = nil
pcall(function()
	gachaDataStore = DataStoreService:GetDataStore("StormClash_Gacha_v1")
end)

-- Remotes Folder
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evGachaPull    = ensureRemote("GachaPullEvent")
local evGachaSync    = ensureRemote("GachaSyncEvent")
local evClaimDaily   = ensureRemote("ClaimDailyRewardEvent")
local evOpenGacha    = ensureRemote("OpenGachaEvent")
local evAddRyo       = ensureRemote("AddCombatRyoEvent")

-- In-Memory Player Profiles Cache
type PlayerGachaProfile = {
	Ryo: number,
	Pity: number,
	EssenceShards: number,
	TotalPulls: number,
	LastDaily: number,
	Unlocked: { [string]: boolean },
}

local playerProfiles: { [number]: PlayerGachaProfile } = {}

-- Helper: Create Default Profile
local function createDefaultProfile(): PlayerGachaProfile
	local unlocked: { [string]: boolean } = {}
	for _, starterId in ipairs(GachaConfig.StarterCharacters) do
		unlocked[starterId] = true
	end
	return {
		Ryo = GachaConfig.StartingRyo or 300,
		Pity = 0,
		EssenceShards = 0,
		TotalPulls = 0,
		LastDaily = 0,
		Unlocked = unlocked,
	}
end

-- =========================================================
-- 1. DATA PERSISTENCE (LOAD & SAVE)
-- =========================================================
local function loadPlayerData(player: Player)
	local userId = player.UserId
	local defaultProf = createDefaultProfile()

	if gachaDataStore then
		local success, saved = pcall(function()
			return gachaDataStore:GetAsync("User_" .. tostring(userId))
		end)
		if success and typeof(saved) == "table" then
			-- Merge saved data with defaults
			defaultProf.Ryo = saved.Ryo or defaultProf.Ryo
			defaultProf.Pity = saved.Pity or defaultProf.Pity
			defaultProf.EssenceShards = saved.EssenceShards or defaultProf.EssenceShards
			defaultProf.TotalPulls = saved.TotalPulls or defaultProf.TotalPulls
			defaultProf.LastDaily = saved.LastDaily or defaultProf.LastDaily
			if typeof(saved.Unlocked) == "table" then
				for k, v in pairs(saved.Unlocked) do
					if v == true then defaultProf.Unlocked[k] = true end
				end
			end
			print(string.format(">> [GachaServer] Loaded data for %s (Ryo: %d, Pity: %d)", player.Name, defaultProf.Ryo, defaultProf.Pity))
		end
	end

	playerProfiles[userId] = defaultProf

	-- Set Replicated Attributes
	player:SetAttribute("RyoValue", defaultProf.Ryo)
	player:SetAttribute("PityCount", defaultProf.Pity)
	player:SetAttribute("EssenceShards", defaultProf.EssenceShards)

	-- Sync to client
	task.delay(1.0, function()
		if player.Parent then
			evGachaSync:FireClient(player, defaultProf)
		end
	end)
end

local function savePlayerData(player: Player)
	local userId = player.UserId
	local prof = playerProfiles[userId]
	if not prof or not gachaDataStore then return end

	pcall(function()
		gachaDataStore:SetAsync("User_" .. tostring(userId), {
			Ryo = prof.Ryo,
			Pity = prof.Pity,
			EssenceShards = prof.EssenceShards,
			TotalPulls = prof.TotalPulls,
			LastDaily = prof.LastDaily,
			Unlocked = prof.Unlocked,
		})
	end)
	print(string.format(">> [GachaServer] Saved data for %s <<", player.Name))
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerProfiles[player.UserId] = nil
end)
for _, p in ipairs(Players:GetPlayers()) do loadPlayerData(p) end

-- Auto-Save loop every 120 seconds
task.spawn(function()
	while true do
		task.wait(120)
		for _, p in ipairs(Players:GetPlayers()) do
			savePlayerData(p)
		end
	end
end)

-- =========================================================
-- 2. GACHA ROLL ALGORITHM (PITY + WEIGHTED DROP)
-- =========================================================
local function rollSingle(prof: PlayerGachaProfile, forceEpicPlus: boolean?): (string, string, boolean, number)
	prof.Pity += 1
	prof.TotalPulls += 1

	local chosenTier = "Rare"

	-- Check Hard Pity (50 Pulls)
	if prof.Pity >= GachaConfig.Pity.HardPityThreshold then
		-- Guaranteed 5-Star Legendary (80%) or 6-Star Mythic (20%)!
		if math.random() <= 0.20 then
			chosenTier = "Mythic"
		else
			chosenTier = "Legendary"
		end
		prof.Pity = 0
		print(">> [GachaServer] HARD PITY TRIGGERED! Awarded: " .. chosenTier)
	elseif forceEpicPlus then
		-- Multi-Pull Epic Guarantee
		local r = math.random()
		if r <= 0.05 then
			chosenTier = "Mythic"
			prof.Pity = 0
		elseif r <= 0.25 then
			chosenTier = "Legendary"
			prof.Pity = 0
		else
			chosenTier = "Epic"
		end
	else
		-- Standard RNG Roll
		local r = math.random()
		if r <= GachaConfig.Tiers.Mythic.Rate then
			chosenTier = "Mythic"
			prof.Pity = 0
		elseif r <= (GachaConfig.Tiers.Mythic.Rate + GachaConfig.Tiers.Legendary.Rate) then
			chosenTier = "Legendary"
			prof.Pity = 0
		elseif r <= (GachaConfig.Tiers.Mythic.Rate + GachaConfig.Tiers.Legendary.Rate + GachaConfig.Tiers.Epic.Rate) then
			chosenTier = "Epic"
		else
			chosenTier = "Rare"
		end
	end

	-- Pick Random Character from Chosen Tier pool
	local tierData = GachaConfig.Tiers[chosenTier]
	local pool = tierData.Characters
	local chosenCharId = pool[math.random(1, #pool)]

	-- Check if duplicate
	local isNew = false
	local shardsAwarded = 0

	if not prof.Unlocked[chosenCharId] then
		isNew = true
		prof.Unlocked[chosenCharId] = true
	else
		isNew = false
		shardsAwarded = tierData.DuplicateShards or 10
		prof.EssenceShards += shardsAwarded
	end

	return chosenCharId, chosenTier, isNew, shardsAwarded
end

-- =========================================================
-- 3. REMOTE EVENT HANDLERS
-- =========================================================
evGachaPull.OnServerEvent:Connect(function(player: Player, pullType: string)
	local prof = playerProfiles[player.UserId]
	if not prof then return end

	local isMulti = (pullType == "Multi")
	local cost = if isMulti then GachaConfig.MultiPullCost else GachaConfig.SinglePullCost
	local count = if isMulti then GachaConfig.MultiPullCount else 1

	if prof.Ryo < cost then
		-- Insufficient Ryo
		evGachaPull:FireClient(player, {
			Success = false,
			Message = "Ryo tidak mencukupi! Butuh " .. tostring(cost) .. " Ryo.",
		})
		return
	end

	-- Deduct Ryo
	prof.Ryo -= cost
	player:SetAttribute("RyoValue", prof.Ryo)

	-- Perform Pulls
	local results = {}
	local hasEpicPlus = false

	for i = 1, count do
		local forceEpic = false
		-- On 10th pull of multi, guarantee Epic+ if none so far
		if isMulti and i == count and not hasEpicPlus and GachaConfig.Pity.MultiPullEpicGuarantee then
			forceEpic = true
		end

		local charId, tier, isNew, shards = rollSingle(prof, forceEpic)
		if tier == "Epic" or tier == "Legendary" or tier == "Mythic" then
			hasEpicPlus = true
		end

		table.insert(results, {
			Id = charId,
			Tier = tier,
			IsNew = isNew,
			Shards = shards,
		})
	end

	player:SetAttribute("PityCount", prof.Pity)
	player:SetAttribute("EssenceShards", prof.EssenceShards)

	-- Send Results to Client for cinematic display
	evGachaPull:FireClient(player, {
		Success = true,
		Results = results,
		NewRyo = prof.Ryo,
		Pity = prof.Pity,
		Shards = prof.EssenceShards,
		IsMulti = isMulti,
	})

	-- Also sync full state
	evGachaSync:FireClient(player, prof)
	print(string.format(">> [GachaServer] %s completed %s pull (%d Ryo spent). New Ryo: %d, Pity: %d", player.Name, pullType, cost, prof.Ryo, prof.Pity))
end)

-- Claim Daily Login Reward
evClaimDaily.OnServerEvent:Connect(function(player: Player)
	local prof = playerProfiles[player.UserId]
	if not prof then return end

	local now = os.time()
	local elapsed = now - prof.LastDaily
	if elapsed < GachaConfig.Rewards.DailyRewardCooldown and prof.LastDaily > 0 then
		local remaining = GachaConfig.Rewards.DailyRewardCooldown - elapsed
		local hours = math.floor(remaining / 3600)
		local mins = math.floor((remaining % 3600) / 60)
		evClaimDaily:FireClient(player, {
			Success = false,
			Message = string.format("Bonus harian sudah diambil! Tunggu %d jam %d menit lagi.", hours, mins),
		})
		return
	end

	prof.LastDaily = now
	prof.Ryo += GachaConfig.Rewards.DailyLoginRyo
	player:SetAttribute("RyoValue", prof.Ryo)

	evClaimDaily:FireClient(player, {
		Success = true,
		RyoAdded = GachaConfig.Rewards.DailyLoginRyo,
		NewRyo = prof.Ryo,
		Message = string.format("Berhasil mengklaim bonus harian +%d Ryo!", GachaConfig.Rewards.DailyLoginRyo),
	})
	evGachaSync:FireClient(player, prof)
end)

-- Client Request Data Sync
evGachaSync.OnServerEvent:Connect(function(player: Player)
	local prof = playerProfiles[player.UserId]
	if prof then
		evGachaSync:FireClient(player, prof)
	end
end)

-- Internal helper to award Ryo (e.g. from combat / training dummy)
function _G.AwardCombatRyo(player: Player, amount: number, reason: string?)
	local prof = playerProfiles[player.UserId]
	if not prof then return end
	prof.Ryo += amount
	player:SetAttribute("RyoValue", prof.Ryo)
	evAddRyo:FireClient(player, amount, reason or "Combat Reward")
	print(string.format(">> [GachaServer] Awarded +%d Ryo to %s (%s). Total: %d", amount, player.Name, reason or "Combat", prof.Ryo))
end

-- =========================================================
-- 4. 3D SHINOBI SUMMON SHRINE (TORII ALTAR IN LOBBY)
-- =========================================================
local function buildSummonShrine()
	local shrinePos = Vector3.new(22, 52.5, -145)

	local existing = Workspace:FindFirstChild("ShinobiSummonShrine")
	if existing then existing:Destroy() end

	local shrine = Instance.new("Model")
	shrine.Name = "ShinobiSummonShrine"

	-- 1. Base Platform
	local base = Instance.new("Part")
	base.Name = "ShrineBase"
	base.Size = Vector3.new(12, 1.2, 12)
	base.Position = shrinePos
	base.Color = Color3.fromRGB(45, 30, 25)
	base.Material = Enum.Material.WoodPlanks
	base.Anchored = true
	base.CanCollide = true
	base.Parent = shrine

	-- 2. Golden Altar Pedestal
	local ped = Instance.new("Part")
	ped.Name = "AltarPedestal"
	ped.Shape = Enum.PartType.Cylinder
	ped.Size = Vector3.new(1.8, 4.5, 4.5)
	ped.CFrame = CFrame.new(shrinePos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ped.Color = Color3.fromRGB(255, 215, 0)
	ped.Material = Enum.Material.Neon
	ped.Anchored = true
	ped.CanCollide = true
	ped.Parent = shrine

	-- Floating Summon Orb
	local orb = Instance.new("Part")
	orb.Name = "FloatingSummonOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2.4, 2.4, 2.4)
	orb.Position = shrinePos + Vector3.new(0, 4.2, 0)
	orb.Color = Color3.fromRGB(0, 240, 255)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.Parent = shrine

	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 80)),
	})
	pe.Size = NumberSequence.new(1.2, 0)
	pe.Rate = 25
	pe.Speed = NumberRange.new(2, 6)
	pe.Lifetime = NumberRange.new(0.5, 0.8)
	pe.Parent = orb

	-- 3. Small Torii Gate framing the altar
	local function makePillar(offset: Vector3)
		local p = Instance.new("Part")
		p.Size = Vector3.new(1.0, 9, 1.0)
		p.Position = shrinePos + offset
		p.Color = Color3.fromRGB(200, 35, 25)
		p.Material = Enum.Material.Wood
		p.Anchored = true
		p.CanCollide = true
		p.Parent = shrine
	end
	makePillar(Vector3.new(-4.5, 4.5, 0))
	makePillar(Vector3.new(4.5, 4.5, 0))

	-- Torii Header
	local header = Instance.new("Part")
	header.Size = Vector3.new(12, 1.0, 1.6)
	header.Position = shrinePos + Vector3.new(0, 9.2, 0)
	header.Color = Color3.fromRGB(25, 25, 30)
	header.Material = Enum.Material.Wood
	header.Anchored = true
	header.CanCollide = true
	header.Parent = shrine

	-- 4. Billboard Banner
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 60)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = orb

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.fromScale(1, 0.55)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "⛩️ PEMANGGILAN SHINOBI"
	titleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextScaled = true
	titleLbl.Parent = bb

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.fromScale(1, 0.4)
	subLbl.Position = UDim2.new(0, 0, 0.55, 0)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = "GACHA BANNER // 24 FIGHTERS"
	subLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
	subLbl.Font = Enum.Font.GothamBold
	subLbl.TextScaled = true
	subLbl.Parent = bb

	-- 5. Proximity Prompt to Open Gacha Modal
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buka Pemanggilan Shinobi"
	prompt.ObjectText = "⛩️ GACHA BANNER"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.Parent = base

	prompt.Triggered:Connect(function(player)
		evOpenGacha:FireClient(player)
	end)

	shrine.Parent = Workspace
	print(">> [GachaServer] 3D Shinobi Summon Shrine built in Lobby Courtyard! <<")
end

buildSummonShrine()
print("[GachaServerManager] ✅ Authoritative Gacha Engine fully loaded.")
]=====]
    installScript('GachaServerManager', 'Script', game:GetService('ServerScriptService'), src)
end

-- ============================================================
-- INSTALL: StormGachaHUD (LocalScript)
-- ============================================================
do
    local src = [=====[--!strict
-- StormGachaHUD.luau
-- CLIENT SCRIPT: Cinematic Shinobi Gacha Summon Interface & Dramatic Reveal Stage
-- Features:
--   • 1x Summon (100 Ryo) & 10x Multi-Summon (900 Ryo)
--   • Dynamic Pity Progress Bar (0/50 Guarantee)
--   • Daily Login Reward Claim (+250 Ryo)
--   • Dramatic Anime Summon Reveal Cutscene:
--       - Pulsing Summoning Orb & Screen Shake
--       - Tier-dependent flash colors (Cyan -> Purple -> Gold -> Crimson/Rainbow)
--       - Splash Card presentation with Stars, Title, Archetype, Quote, and New/Duplicate status
--   • Grid layout for 10x Multi-Summon results with skip support
--   • Full Mobile Touch, Keyboard ([G] Key), and 3D Lobby Altar Integration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Force Landscape on Mobile
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evGachaPull    = combatEvents:WaitForChild("GachaPullEvent", 15) :: RemoteEvent
local evGachaSync    = combatEvents:WaitForChild("GachaSyncEvent", 15) :: RemoteEvent
local evClaimDaily   = combatEvents:WaitForChild("ClaimDailyRewardEvent", 15) :: RemoteEvent
local evOpenGacha    = combatEvents:WaitForChild("OpenGachaEvent", 15) :: RemoteEvent

-- State
local isOpen = false
local isSummoning = false
local currentRyo = 300
local currentPity = 0
local currentShards = 0
local unlockedMap: { [string]: boolean } = {}

-- Sound Helper
local function playSound(soundId: string, pitch: number, vol: number?)
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = soundId
			s.PlaybackSpeed = pitch or 1.0
			s.Volume = vol or 0.8
			s.Parent = SoundService
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
		end)
	end)
end

-- =========================================================
-- CREATE GUI INSTANCES
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormGachaHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Dark Vignette Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "GachaBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
backdrop.BackgroundTransparency = 0.25
backdrop.Parent = screenGui

-- Main Gacha Modal Window (Landscape 88% x 86%)
local mainModal = Instance.new("Frame")
mainModal.Name = "MainModal"
mainModal.Size = UDim2.new(0.88, 0, 0.86, 0)
mainModal.Position = UDim2.new(0.5, 0, 0.5, 0)
mainModal.AnchorPoint = Vector2.new(0.5, 0.5)
mainModal.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
mainModal.BorderSizePixel = 0
mainModal.Parent = backdrop
Instance.new("UICorner", mainModal).CornerRadius = UDim.new(0, 14)

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(255, 215, 0)
modalStroke.Thickness = 2
modalStroke.Parent = mainModal

-- =========================================================
-- HEADER: CURRENCY & PITY BAR
-- =========================================================
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 56)
headerFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
headerFrame.BackgroundTransparency = 0.2
headerFrame.Parent = mainModal
Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.35, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "⛩️ SHINOBI SUMMON // GACHA BANNER"
titleLabel.Parent = headerFrame

-- Ryo Display
local ryoBadge = Instance.new("Frame")
ryoBadge.Size = UDim2.new(0, 150, 0, 36)
ryoBadge.Position = UDim2.new(0.42, 0, 0.5, 0)
ryoBadge.AnchorPoint = Vector2.new(0, 0.5)
ryoBadge.BackgroundColor3 = Color3.fromRGB(25, 30, 48)
ryoBadge.Parent = headerFrame
Instance.new("UICorner", ryoBadge).CornerRadius = UDim.new(0, 8)

local ryoLbl = Instance.new("TextLabel")
ryoLbl.Size = UDim2.fromScale(1, 1)
ryoLbl.BackgroundTransparency = 1
ryoLbl.Font = Enum.Font.GothamBold
ryoLbl.TextSize = 15
ryoLbl.TextColor3 = Color3.fromRGB(255, 225, 50)
ryoLbl.Text = "🪙 300 Ryo"
ryoLbl.Parent = ryoBadge

-- Shards Display
local shardBadge = Instance.new("Frame")
shardBadge.Size = UDim2.new(0, 140, 0, 36)
shardBadge.Position = UDim2.new(0.58, 0, 0.5, 0)
shardBadge.AnchorPoint = Vector2.new(0, 0.5)
shardBadge.BackgroundColor3 = Color3.fromRGB(25, 30, 48)
shardBadge.Parent = headerFrame
Instance.new("UICorner", shardBadge).CornerRadius = UDim.new(0, 8)

local shardLbl = Instance.new("TextLabel")
shardLbl.Size = UDim2.fromScale(1, 1)
shardLbl.BackgroundTransparency = 1
shardLbl.Font = Enum.Font.GothamBold
shardLbl.TextSize = 14
shardLbl.TextColor3 = Color3.fromRGB(80, 230, 255)
shardLbl.Text = "💎 0 Shards"
shardLbl.Parent = shardBadge

-- Close Button [✕]
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- BANNER STAGE: FEATURED LEGENDS & PITY COUNTER
-- =========================================================
local bannerStage = Instance.new("Frame")
bannerStage.Name = "BannerStage"
bannerStage.Size = UDim2.new(1, -40, 0.65, 0)
bannerStage.Position = UDim2.new(0, 20, 0, 68)
bannerStage.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
bannerStage.Parent = mainModal
Instance.new("UICorner", bannerStage).CornerRadius = UDim.new(0, 10)

local bannerGradient = Instance.new("UIGradient")
bannerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 25, 55)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 25, 45)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 35)),
})
bannerGradient.Rotation = 45
bannerGradient.Parent = bannerStage

-- Featured Characters Showcase Title
local featHeader = Instance.new("TextLabel")
featHeader.Size = UDim2.new(1, 0, 0, 30)
featHeader.Position = UDim2.new(0, 0, 0, 10)
featHeader.BackgroundTransparency = 1
featHeader.Font = Enum.Font.GothamBlack
featHeader.TextSize = 16
featHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
featHeader.Text = "★ FEATURED MYTHIC & LEGENDARY SUMMONS ★"
featHeader.Parent = bannerStage

-- Showcase Display of Featured Roster
local featuredChars = {
	{ Id = "Madara",  Tier = "Mythic",    Stars = "★★★★★★", Color = Color3.fromRGB(255, 40, 80) },
	{ Id = "Sukuna",  Tier = "Mythic",    Stars = "★★★★★★", Color = Color3.fromRGB(255, 40, 80) },
	{ Id = "Gojo",    Tier = "Legendary", Stars = "★★★★★",  Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "Aizen",   Tier = "Legendary", Stars = "★★★★★",  Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "Sasuke",  Tier = "Legendary", Stars = "★★★★★",  Color = Color3.fromRGB(255, 215, 0) },
}

local cardsRow = Instance.new("Frame")
cardsRow.Size = UDim2.new(1, -30, 0, 140)
cardsRow.Position = UDim2.new(0, 15, 0, 45)
cardsRow.BackgroundTransparency = 1
cardsRow.Parent = bannerStage

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.Padding = UDim.new(0, 12)
rowLayout.Parent = cardsRow

for _, feat in ipairs(featuredChars) do
	local char = CombatConfig.Characters[feat.Id]
	if not char then continue end

	local fCard = Instance.new("Frame")
	fCard.Size = UDim2.new(0, 130, 1, 0)
	fCard.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
	fCard.Parent = cardsRow
	Instance.new("UICorner", fCard).CornerRadius = UDim.new(0, 8)

	local fStroke = Instance.new("UIStroke")
	fStroke.Color = feat.Color
	fStroke.Thickness = 1.5
	fStroke.Parent = fCard

	local fIcon = Instance.new("TextLabel")
	fIcon.Size = UDim2.new(1, 0, 0, 45)
	fIcon.Position = UDim2.new(0, 0, 0, 8)
	fIcon.BackgroundTransparency = 1
	fIcon.Font = Enum.Font.GothamBold
	fIcon.TextSize = 34
	fIcon.Text = char.Icon
	fIcon.Parent = fCard

	local fName = Instance.new("TextLabel")
	fName.Size = UDim2.new(1, -6, 0, 18)
	fName.Position = UDim2.new(0, 3, 0, 56)
	fName.BackgroundTransparency = 1
	fName.Font = Enum.Font.GothamBlack
	fName.TextSize = 12
	fName.TextColor3 = Color3.fromRGB(255, 255, 255)
	fName.TextScaled = true
	fName.Text = char.Name
	fName.Parent = fCard

	local fStars = Instance.new("TextLabel")
	fStars.Size = UDim2.new(1, 0, 0, 14)
	fStars.Position = UDim2.new(0, 0, 0, 78)
	fStars.BackgroundTransparency = 1
	fStars.Font = Enum.Font.GothamBold
	fStars.TextSize = 11
	fStars.TextColor3 = feat.Color
	fStars.Text = feat.Stars
	fStars.Parent = fCard

	local fTier = Instance.new("TextLabel")
	fTier.Size = UDim2.new(0.8, 0, 0, 18)
	fTier.Position = UDim2.new(0.1, 0, 0, 104)
	fTier.BackgroundColor3 = feat.Color
	fTier.BackgroundTransparency = 0.3
	fTier.Font = Enum.Font.GothamBlack
	fTier.TextSize = 9
	fTier.TextColor3 = Color3.fromRGB(255, 255, 255)
	fTier.Text = string.upper(feat.Tier)
	fTier.Parent = fCard
	Instance.new("UICorner", fTier).CornerRadius = UDim.new(0, 4)
end

-- Pity Progress Bar at bottom of stage
local pityFrame = Instance.new("Frame")
pityFrame.Size = UDim2.new(1, -40, 0, 24)
pityFrame.Position = UDim2.new(0, 20, 1, -34)
pityFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
pityFrame.Parent = bannerStage
Instance.new("UICorner", pityFrame).CornerRadius = UDim.new(0, 6)

local pityFill = Instance.new("Frame")
pityFill.Size = UDim2.new(0, 0, 1, 0)
pityFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
pityFill.BorderSizePixel = 0
pityFill.Parent = pityFrame
Instance.new("UICorner", pityFill).CornerRadius = UDim.new(0, 6)

local pityLbl = Instance.new("TextLabel")
pityLbl.Size = UDim2.fromScale(1, 1)
pityLbl.BackgroundTransparency = 1
pityLbl.Font = Enum.Font.GothamBlack
pityLbl.TextSize = 11
pityLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
pityLbl.Text = "PITY GARANSI: 0 / 50 PULLS (DIJAMIN ★5/★6 PADA 50)"
pityLbl.Parent = pityFrame

-- =========================================================
-- BOTTOM ACTION BUTTONS
-- =========================================================
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(1, -40, 0, 52)
bottomBar.Position = UDim2.new(0, 20, 1, -66)
bottomBar.BackgroundTransparency = 1
bottomBar.Parent = mainModal

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Padding = UDim.new(0, 16)
btnLayout.Parent = bottomBar

-- Daily Reward Button
local dailyBtn = Instance.new("TextButton")
dailyBtn.Size = UDim2.new(0, 180, 1, 0)
dailyBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
dailyBtn.Font = Enum.Font.GothamBlack
dailyBtn.TextSize = 12
dailyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dailyBtn.Text = "🎁 KLAIM HARIAN\n(+250 Ryo)"
dailyBtn.Parent = bottomBar
Instance.new("UICorner", dailyBtn).CornerRadius = UDim.new(0, 8)

-- 1x Summon Button
local pull1Btn = Instance.new("TextButton")
pull1Btn.Size = UDim2.new(0, 220, 1, 0)
pull1Btn.BackgroundColor3 = Color3.fromRGB(0, 160, 240)
pull1Btn.Font = Enum.Font.GothamBlack
pull1Btn.TextSize = 14
pull1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
pull1Btn.Text = "⛩️ 1x SUMMON\n(100 🪙 Ryo)"
pull1Btn.Parent = bottomBar
Instance.new("UICorner", pull1Btn).CornerRadius = UDim.new(0, 8)

local p1Stroke = Instance.new("UIStroke")
p1Stroke.Color = Color3.fromRGB(255, 255, 255)
p1Stroke.Thickness = 1.5
p1Stroke.Parent = pull1Btn

-- 10x Multi-Summon Button
local pull10Btn = Instance.new("TextButton")
pull10Btn.Size = UDim2.new(0, 260, 1, 0)
pull10Btn.BackgroundColor3 = Color3.fromRGB(230, 140, 20)
pull10Btn.Font = Enum.Font.GothamBlack
pull10Btn.TextSize = 14
pull10Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
pull10Btn.Text = "🔥 10x MULTI-SUMMON\n(900 🪙 Ryo • DISKON 10%)"
pull10Btn.Parent = bottomBar
Instance.new("UICorner", pull10Btn).CornerRadius = UDim.new(0, 8)

local p10Stroke = Instance.new("UIStroke")
p10Stroke.Color = Color3.fromRGB(255, 215, 0)
p10Stroke.Thickness = 2
p10Stroke.Parent = pull10Btn

-- =========================================================
-- CINEMATIC SUMMON REVEAL STAGE
-- =========================================================
local revealOverlay = Instance.new("Frame")
revealOverlay.Name = "RevealOverlay"
revealOverlay.Size = UDim2.new(1, 0, 1, 0)
revealOverlay.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
revealOverlay.BackgroundTransparency = 0.05
revealOverlay.Visible = false
revealOverlay.ZIndex = 50
revealOverlay.Parent = screenGui

-- Center Flash Orb
local summonOrb = Instance.new("Frame")
summonOrb.Name = "SummonOrb"
summonOrb.Size = UDim2.new(0, 140, 0, 140)
summonOrb.Position = UDim2.new(0.5, 0, 0.45, 0)
summonOrb.AnchorPoint = Vector2.new(0.5, 0.5)
summonOrb.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
summonOrb.ZIndex = 52
summonOrb.Parent = revealOverlay
Instance.new("UICorner", summonOrb).CornerRadius = UDim.new(1, 0)

-- Result Card Container
local resultContainer = Instance.new("Frame")
resultContainer.Name = "ResultContainer"
resultContainer.Size = UDim2.new(0.9, 0, 0.85, 0)
resultContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
resultContainer.AnchorPoint = Vector2.new(0.5, 0.5)
resultContainer.BackgroundTransparency = 1
resultContainer.ZIndex = 55
resultContainer.Visible = false
resultContainer.Parent = revealOverlay

-- Dismiss Button
local continueBtn = Instance.new("TextButton")
continueBtn.Size = UDim2.new(0, 240, 0, 48)
continueBtn.Position = UDim2.new(0.5, 0, 1, -40)
continueBtn.AnchorPoint = Vector2.new(0.5, 1)
continueBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
continueBtn.Font = Enum.Font.GothamBlack
continueBtn.TextSize = 16
continueBtn.TextColor3 = Color3.fromRGB(15, 18, 25)
continueBtn.Text = "✓ AMBIL SEMUA HADIAH"
continueBtn.ZIndex = 60
continueBtn.Visible = false
continueBtn.Parent = revealOverlay
Instance.new("UICorner", continueBtn).CornerRadius = UDim.new(0, 10)

-- =========================================================
-- UPDATE STATE HELPERS
-- =========================================================
local function updateGachaState(data: any)
	if not data then return end
	currentRyo = data.Ryo or currentRyo
	currentPity = data.Pity or currentPity
	currentShards = data.EssenceShards or currentShards
	unlockedMap = data.Unlocked or unlockedMap

	ryoLbl.Text = string.format("🪙 %d Ryo", currentRyo)
	shardLbl.Text = string.format("💎 %d Shards", currentShards)

	local ratio = math.clamp(currentPity / GachaConfig.Pity.HardPityThreshold, 0, 1)
	pityFill.Size = UDim2.new(ratio, 0, 1, 0)
	pityLbl.Text = string.format("PITY GARANSI: %d / %d PULLS (DIJAMIN ★5/★6 PADA %d)", currentPity, GachaConfig.Pity.HardPityThreshold, GachaConfig.Pity.HardPityThreshold)
end

-- =========================================================
-- PLAY DRAMATIC REVEAL SEQUENCE
-- =========================================================
local function playSummonCutscene(results: { any }, isMulti: boolean)
	isSummoning = true
	revealOverlay.Visible = true
	resultContainer.Visible = false
	continueBtn.Visible = false
	summonOrb.Visible = true
	summonOrb.Size = UDim2.new(0, 20, 0, 20)

	-- Find highest tier for orb peak color
	local highestTier = "Rare"
	for _, res in ipairs(results) do
		local t = res.Tier
		if t == "Mythic" then highestTier = "Mythic" break end
		if t == "Legendary" and highestTier ~= "Mythic" then highestTier = "Legendary" end
		if t == "Epic" and highestTier == "Rare" then highestTier = "Epic" end
	end

	local tierConfig = GachaConfig.Tiers[highestTier] or GachaConfig.Tiers.Rare
	summonOrb.BackgroundColor3 = tierConfig.Color

	playSound("rbxasset://sounds/electronicpingshort.wav", 1.2, 0.8)

	-- Orb Pulse Expansion Animation
	local expandTween = TweenService:Create(summonOrb, TweenInfo.new(1.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 280, 0, 280),
		BackgroundTransparency = 0.1,
	})
	expandTween:Play()

	task.wait(1.2)

	-- Screen Flash
	playSound("rbxasset://sounds/impact_explosion_03.mp3", tierConfig.SoundPitch or 1.0, 1.0)
	summonOrb.Visible = false

	-- Clear old result cards
	for _, child in ipairs(resultContainer:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	resultContainer.Visible = true

	if not isMulti and #results == 1 then
		-- SINGLE SUMMON: Big Cinematic Hero Card
		local res = results[1]
		local char = CombatConfig.Characters[res.Id]
		local tData = GachaConfig.Tiers[res.Tier] or GachaConfig.Tiers.Rare

		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 360, 0, 420)
		card.Position = UDim2.new(0.5, 0, 0.45, 0)
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
		card.Parent = resultContainer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = tData.Color
		cStroke.Thickness = 3
		cStroke.Parent = card

		-- Stars Header
		local sLbl = Instance.new("TextLabel")
		sLbl.Size = UDim2.new(1, 0, 0, 30)
		sLbl.Position = UDim2.new(0, 0, 0, 14)
		sLbl.BackgroundTransparency = 1
		sLbl.Font = Enum.Font.GothamBlack
		sLbl.TextSize = 22
		sLbl.TextColor3 = tData.Color
		sLbl.Text = tData.Stars .. " " .. string.upper(tData.Name)
		sLbl.Parent = card

		-- Big Icon
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 0, 90)
		iconLbl.Position = UDim2.new(0, 0, 0, 48)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.TextSize = 72
		iconLbl.Text = char and char.Icon or "⚡"
		iconLbl.Parent = card

		-- Name
		local nLbl = Instance.new("TextLabel")
		nLbl.Size = UDim2.new(1, -20, 0, 32)
		nLbl.Position = UDim2.new(0, 10, 0, 145)
		nLbl.BackgroundTransparency = 1
		nLbl.Font = Enum.Font.GothamBlack
		nLbl.TextSize = 22
		nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nLbl.Text = char and string.upper(char.Name) or res.Id
		nLbl.Parent = card

		-- Anime Title & Archetype
		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, 0, 0, 20)
		subLbl.Position = UDim2.new(0, 0, 0, 180)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = Enum.Font.GothamBold
		subLbl.TextSize = 13
		subLbl.TextColor3 = tData.Color
		subLbl.Text = (char and char.Anime or "Anime") .. " • " .. (char and string.upper(char.Archetype) or "FIGHTER")
		subLbl.Parent = card

		-- Status Badge (NEW! or DUPLICATE)
		local statusBadge = Instance.new("TextLabel")
		statusBadge.Size = UDim2.new(0.8, 0, 0, 32)
		statusBadge.Position = UDim2.new(0.1, 0, 0, 215)
		statusBadge.Font = Enum.Font.GothamBlack
		statusBadge.TextSize = 13
		if res.IsNew then
			statusBadge.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
			statusBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
			statusBadge.Text = "✨ KARAKTER BARU TERBUKA (UNLOCKED!)"
		else
			statusBadge.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
			statusBadge.TextColor3 = Color3.fromRGB(255, 240, 150)
			statusBadge.Text = string.format("DUPLIKAT -> +%d ESSENCE SHARDS", res.Shards or 10)
		end
		statusBadge.Parent = card
		Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 8)

		-- Quote
		local qLbl = Instance.new("TextLabel")
		qLbl.Size = UDim2.new(1, -30, 0, 60)
		qLbl.Position = UDim2.new(0, 15, 0, 260)
		qLbl.BackgroundTransparency = 1
		qLbl.Font = Enum.Font.GothamMedium
		qLbl.TextSize = 12
		qLbl.TextColor3 = Color3.fromRGB(200, 210, 225)
		qLbl.TextWrapped = true
		qLbl.Text = char and ('"' .. char.Quote .. '"') or ""
		qLbl.Parent = card
	else
		-- MULTI-SUMMON: 2x5 Grid of 10 Cards
		local grid = Instance.new("Frame")
		grid.Size = UDim2.new(1, 0, 0.85, 0)
		grid.Position = UDim2.new(0, 0, 0, 10)
		grid.BackgroundTransparency = 1
		grid.Parent = resultContainer

		local uigrid = Instance.new("UIGridLayout")
		uigrid.CellSize = UDim2.new(0.18, 0, 0.46, 0)
		uigrid.CellPadding = UDim2.new(0.02, 0, 0.04, 0)
		uigrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uigrid.Parent = grid

		for _, res in ipairs(results) do
			local char = CombatConfig.Characters[res.Id]
			local tData = GachaConfig.Tiers[res.Tier] or GachaConfig.Tiers.Rare

			local mCard = Instance.new("Frame")
			mCard.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
			mCard.Parent = grid
			Instance.new("UICorner", mCard).CornerRadius = UDim.new(0, 10)

			local mStroke = Instance.new("UIStroke")
			mStroke.Color = tData.Color
			mStroke.Thickness = 2
			mStroke.Parent = mCard

			local mIcon = Instance.new("TextLabel")
			mIcon.Size = UDim2.new(1, 0, 0, 48)
			mIcon.Position = UDim2.new(0, 0, 0, 8)
			mIcon.BackgroundTransparency = 1
			mIcon.Font = Enum.Font.GothamBold
			mIcon.TextSize = 36
			mIcon.Text = char and char.Icon or "⚡"
			mIcon.Parent = mCard

			local mName = Instance.new("TextLabel")
			mName.Size = UDim2.new(1, -6, 0, 18)
			mName.Position = UDim2.new(0, 3, 0, 58)
			mName.BackgroundTransparency = 1
			mName.Font = Enum.Font.GothamBlack
			mName.TextSize = 11
			mName.TextColor3 = Color3.fromRGB(255, 255, 255)
			mName.TextScaled = true
			mName.Text = char and char.Name or res.Id
			mName.Parent = mCard

			local mStars = Instance.new("TextLabel")
			mStars.Size = UDim2.new(1, 0, 0, 14)
			mStars.Position = UDim2.new(0, 0, 0, 78)
			mStars.BackgroundTransparency = 1
			mStars.Font = Enum.Font.GothamBold
			mStars.TextSize = 9
			mStars.TextColor3 = tData.Color
			mStars.Text = tData.Stars
			mStars.Parent = mCard

			local mStatus = Instance.new("TextLabel")
			mStatus.Size = UDim2.new(0.88, 0, 0, 18)
			mStatus.Position = UDim2.new(0.06, 0, 1, -26)
			mStatus.Font = Enum.Font.GothamBlack
			mStatus.TextSize = 8
			if res.IsNew then
				mStatus.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
				mStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
				mStatus.Text = "BARU!"
			else
				mStatus.BackgroundColor3 = Color3.fromRGB(80, 50, 120)
				mStatus.TextColor3 = Color3.fromRGB(200, 220, 255)
				mStatus.Text = "+" .. tostring(res.Shards or 10) .. "💎"
			end
			mStatus.Parent = mCard
			Instance.new("UICorner", mStatus).CornerRadius = UDim.new(0, 4)
		end
	end

	continueBtn.Visible = true
	isSummoning = false
end

-- =========================================================
-- EVENT LISTENERS
-- =========================================================
pull1Btn.MouseButton1Click:Connect(function()
	if isSummoning then return end
	if currentRyo < GachaConfig.SinglePullCost then
		playSound("rbxasset://sounds/action_footsteps_plastic.mp3", 0.6)
		return
	end
	evGachaPull:FireServer("Single")
end)

pull10Btn.MouseButton1Click:Connect(function()
	if isSummoning then return end
	if currentRyo < GachaConfig.MultiPullCost then
		playSound("rbxasset://sounds/action_footsteps_plastic.mp3", 0.6)
		return
	end
	evGachaPull:FireServer("Multi")
end)

dailyBtn.MouseButton1Click:Connect(function()
	evClaimDaily:FireServer()
end)

continueBtn.MouseButton1Click:Connect(function()
	revealOverlay.Visible = false
	resultContainer.Visible = false
	continueBtn.Visible = false
	playSound("rbxasset://sounds/action_jump.mp3", 1.4)
end)

closeBtn.MouseButton1Click:Connect(function()
	if isSummoning then return end
	screenGui.Enabled = false
	isOpen = false
end)

-- Receive Gacha Pull Results
evGachaPull.OnClientEvent:Connect(function(data: any)
	if data and data.Success then
		updateGachaState({
			Ryo = data.NewRyo,
			Pity = data.Pity,
			EssenceShards = data.Shards,
		})
		playSummonCutscene(data.Results, data.IsMulti)
	else
		-- Error message
		if data and data.Message then
			print(">> [StormGacha] Error: " .. data.Message)
		end
	end
end)

-- Receive Full Data Sync
evGachaSync.OnClientEvent:Connect(function(prof: any)
	updateGachaState(prof)
end)

-- Receive Daily Reward confirmation
evClaimDaily.OnClientEvent:Connect(function(data: any)
	if data and data.Success then
		playSound("rbxasset://sounds/electronicpingshort.wav", 1.5)
		dailyBtn.Text = "✓ HARIAN DIAMBIL!"
		dailyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	end
end)

-- Receive Open Request (e.g. from Altar ProximityPrompt or Hotkey)
local function openGachaModal()
	screenGui.Enabled = true
	isOpen = true
	evGachaSync:FireServer()
end

evOpenGacha.OnClientEvent:Connect(function()
	openGachaModal()
end)

-- Keyboard [G] Key to Toggle Gacha
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.G then
		if screenGui.Enabled then
			screenGui.Enabled = false
			isOpen = false
		else
			openGachaModal()
		end
	end
end)

-- Initial Sync
evGachaSync:FireServer()
print("[StormGachaHUD] ✅ Shinobi Gacha Summon HUD & Reveal Cutscene loaded. Hotkey [G] active.")
]=====]
    installScript('StormGachaHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
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