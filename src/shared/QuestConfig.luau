--!strict
-- QuestConfig.luau
-- SHARED CONFIGURATION: Daily Quests, 7-Day Login Streak, and Retention Economy Engine

local QuestConfig = {}

-- =========================================================
-- 1. DAILY LOGIN CALENDAR (7-DAY STREAK)
-- =========================================================
QuestConfig.LoginStreakDays = {
	[1] = { Day = 1, Ryo = 150, Shards = 0,  Label = "Day 1: Shinobi Arrival", Icon = "🪙" },
	[2] = { Day = 2, Ryo = 250, Shards = 10, Label = "Day 2: Chakra Spark",    Icon = "💎" },
	[3] = { Day = 3, Ryo = 400, Shards = 15, Label = "Day 3: Ninja Pouch",     Icon = "🪙" },
	[4] = { Day = 4, Ryo = 600, Shards = 25, Label = "Day 4: Secret Scroll",   Icon = "📜" },
	[5] = { Day = 5, Ryo = 800, Shards = 40, Label = "Day 5: Jonin Tribute",   Icon = "🪙" },
	[6] = { Day = 6, Ryo = 1200, Shards = 60, Label = "Day 6: Shadow Stash",   Icon = "💎" },
	[7] = { Day = 7, Ryo = 2000, Shards = 100, Label = "Day 7: Mythic Blessing", Icon = "🔥" },
}

-- Cooldown between daily claims in seconds (20 hours for friendly leeway, standard in games)
QuestConfig.DailyClaimCooldown = 20 * 3600

-- =========================================================
-- 2. DAILY COMBAT QUESTS
-- =========================================================
export type QuestDef = {
	Id: string,
	Title: string,
	Description: string,
	Category: string,
	TargetGoal: number,
	RyoReward: number,
	ShardsReward: number,
	Icon: string,
}

QuestConfig.DailyQuests = {
	{
		Id = "ShinobiRush",
		Title = "⚡ Shinobi Combo Rush",
		Description = "Lakukan 50 Combo Hits di arena pertarungan",
		Category = "Combat",
		TargetGoal = 50,
		RyoReward = 150,
		ShardsReward = 10,
		Icon = "🥊",
	},
	{
		Id = "DojoDemolisher",
		Title = "💥 Dojo Demolisher",
		Description = "Hancurkan 3 Tiang Latihan di Grand Arena",
		Category = "Arena",
		TargetGoal = 3,
		RyoReward = 200,
		ShardsReward = 15,
		Icon = "🪵",
	},
	{
		Id = "ChakraBurst",
		Title = "🔥 Mode Kebangkitan",
		Description = "Aktifkan Awakening Mode [G] 1 kali",
		Category = "Awakening",
		TargetGoal = 1,
		RyoReward = 250,
		ShardsReward = 20,
		Icon = "⚡",
	},
	{
		Id = "ArenaVictor",
		Title = "🏆 Pemenang Duel",
		Description = "Kalahkan 2 Training Dummy atau Musuh di Arena",
		Category = "Mastery",
		TargetGoal = 2,
		RyoReward = 350,
		ShardsReward = 30,
		Icon = "⚔️",
	},
}

-- =========================================================
-- 3. SOUND EFFECTS
-- =========================================================
QuestConfig.Sounds = {
	ClaimReward = "rbxasset://sounds/electronicpingshort.wav",
	QuestComplete = "rbxasset://sounds/victory.mp3",
	TabClick = "rbxasset://sounds/action_jump.mp3",
}

return QuestConfig

