--!strict
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

	-- Legacy Crouch M1: Low Shinobi Sweep ([S + J])
	CrouchSweep = {
		Damage = 16,
		Hitstun = 0.75,
		Knockback = 12,
		AttackType = "Low",   -- LOW attack (Bypasses High Guard!)
		Sound = "rbxasset://sounds/action_swish.mp3",
		Pitch = 1.25,
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
			Sound = "rbxasset://sounds/action_swish.mp3",
			Icon = "🌀",
		},
		NinjutsuSkill = {
			Name = "Rasengan (Spiraling Sphere)",
			Damage = 28,
			ChakraCost = 25,
			RushSpeed = 90,
			Color = Color3.fromRGB(0, 220, 255),
			Sound = "rbxasset://sounds/electronicpingshort.wav",
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
			Sound = "rbxasset://sounds/action_swish.mp3",
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
			Sound = "rbxasset://sounds/sword_swing_fast.wav",
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
			Sound = "rbxasset://sounds/electronicpingshort.wav",
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
			Sound = "rbxasset://sounds/electronicpingshort.wav",
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
			Sound = "rbxasset://sounds/electronicpingshort.wav",
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
			Sound = "rbxasset://sounds/electronicpingshort.wav",
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
			Sound = "rbxasset://sounds/action_swish.mp3",
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
