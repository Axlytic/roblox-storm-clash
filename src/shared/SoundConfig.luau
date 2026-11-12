--!strict
-- SoundConfig.luau
-- Shared Anime Audio FX & Sound Design Library
-- Contains standardized Roblox native audio assets and curated SFX for impact feedback

export type SoundEntry = {
	Id: string,
	FallbackId: string,
	DefaultVolume: number,
	PitchRange: { min: number, max: number },
}

local SoundConfig = {
	-- 1. MELEE & IMPACT SFX
	Combat = {
		PunchSwing = {
			Id = "rbxasset://sounds/action_swish.mp3",
			FallbackId = "rbxasset://sounds/action_swish.mp3",
			DefaultVolume = 0.75,
			PitchRange = { min = 1.05, max = 1.30 },
		},
		HeavySwing = {
			Id = "rbxasset://sounds/sword_swing_fast.wav",
			FallbackId = "rbxasset://sounds/action_swish.mp3",
			DefaultVolume = 0.85,
			PitchRange = { min = 0.90, max = 1.10 },
		},
		HitImpactLight = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/impact_explosion_03.mp3",
			DefaultVolume = 0.65,
			PitchRange = { min = 1.35, max = 1.60 },
		},
		HitImpactHeavy = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/impact_explosion_03.mp3",
			DefaultVolume = 0.90,
			PitchRange = { min = 0.85, max = 1.05 },
		},
		CriticalShatter = {
			Id = "rbxasset://sounds/shattered.mp3",
			FallbackId = "rbxasset://sounds/shattered.mp3",
			DefaultVolume = 0.95,
			PitchRange = { min = 1.10, max = 1.25 },
		},
		GroundSlam = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/impact_explosion_03.mp3",
			DefaultVolume = 1.00,
			PitchRange = { min = 0.65, max = 0.80 },
		},
	},

	-- 2. DEFENSE & UTILITY SFX
	Defense = {
		ParryBell = {
			Id = "rbxasset://sounds/bell.wav",
			FallbackId = "rbxasset://sounds/electronicpingshort.wav",
			DefaultVolume = 1.00,
			PitchRange = { min = 1.25, max = 1.40 },
		},
		BlockThud = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/impact_explosion_03.mp3",
			DefaultVolume = 0.60,
			PitchRange = { min = 0.55, max = 0.70 },
		},
		KawarimiPoof = {
			Id = "rbxasset://sounds/action_jump.mp3",
			FallbackId = "rbxasset://sounds/action_jump.mp3",
			DefaultVolume = 0.90,
			PitchRange = { min = 0.65, max = 0.75 },
		},
		NinjaDash = {
			Id = "rbxasset://sounds/action_falling.mp3",
			FallbackId = "rbxasset://sounds/action_swish.mp3",
			DefaultVolume = 0.70,
			PitchRange = { min = 1.40, max = 1.65 },
		},
		ChakraCharge = {
			Id = "rbxasset://sounds/electronicpingshort.wav",
			FallbackId = "rbxasset://sounds/electronicpingshort.wav",
			DefaultVolume = 0.80,
			PitchRange = { min = 1.30, max = 1.50 },
		},
		AwakeningRoar = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/bell.wav",
			DefaultVolume = 1.00,
			PitchRange = { min = 0.50, max = 0.65 },
		},
	},

	-- 3. JUTSU & ENERGY SFX
	Jutsu = {
		RasenganSpin = {
			Id = "rbxasset://sounds/electronicpingshort.wav",
			FallbackId = "rbxasset://sounds/electronicpingshort.wav",
			DefaultVolume = 0.85,
			PitchRange = { min = 1.60, max = 1.85 },
		},
		ChidoriSparks = {
			Id = "rbxasset://sounds/shattered.mp3",
			FallbackId = "rbxasset://sounds/electronicpingshort.wav",
			DefaultVolume = 0.90,
			PitchRange = { min = 1.50, max = 1.70 },
		},
		SwordSlash = {
			Id = "rbxasset://sounds/sword_swing_fast.wav",
			FallbackId = "rbxasset://sounds/sword_swing_fast.wav",
			DefaultVolume = 0.85,
			PitchRange = { min = 1.00, max = 1.20 },
		},
	},

	-- 4. BATTLE BGM SOUNDTRACKS
	BGM = {
		DefaultBattle = "rbxassetid://1843528859", -- Epic Anime Battle Theme
		IntenseClash  = "rbxassetid://1843404009", -- High BPM Shinobi Showdown
		LobbyVillage  = "rbxassetid://1843403867", -- Serene Hidden Leaf Village
		DuelFinalRound = "rbxassetid://1837849233", -- Dramatic Championship Climax
	},

	-- 5. MATCH & ANNOUNCER CHIMES
	Announcer = {
		RoundStart = {
			Id = "rbxasset://sounds/bell.wav",
			FallbackId = "rbxasset://sounds/bell.wav",
			DefaultVolume = 1.00,
			PitchRange = { min = 1.00, max = 1.00 },
		},
		Fight = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/impact_explosion_03.mp3",
			DefaultVolume = 1.00,
			PitchRange = { min = 1.10, max = 1.10 },
		},
		Victory = {
			Id = "rbxasset://sounds/electronicpingshort.wav",
			FallbackId = "rbxasset://sounds/bell.wav",
			DefaultVolume = 0.95,
			PitchRange = { min = 1.20, max = 1.20 },
		},
		Defeat = {
			Id = "rbxasset://sounds/impact_explosion_03.mp3",
			FallbackId = "rbxasset://sounds/impact_explosion_03.mp3",
			DefaultVolume = 0.80,
			PitchRange = { min = 0.50, max = 0.50 },
		},
	},
}

return SoundConfig

