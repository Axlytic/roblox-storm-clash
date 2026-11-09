--!strict
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

