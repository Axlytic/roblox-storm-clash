--!strict
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
