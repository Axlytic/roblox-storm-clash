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
    install('CombatConfig', 'ModuleScript', game:GetService('ReplicatedStorage'), src)
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
    install('CombatServerMaster', 'Script', game:GetService('ServerScriptService'), src)
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
    install('TrainingDummySpawner', 'Script', game:GetService('ServerScriptService'), src)
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
    install('StormWeaponServer', 'Script', game:GetService('ServerScriptService'), src)
end

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
    install('GachaConfig', 'ModuleScript', game:GetService('ReplicatedStorage'), src)
end

return 'Batch 1 OK (5 scripts)'