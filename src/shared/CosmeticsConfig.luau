--!strict
-- CosmeticsConfig.luau
-- SHARED CONFIGURATION: Shinobi Titles & Dramatic K.O. Kill Effects

local CosmeticsConfig = {}

-- =========================================================
-- 1. SHINOBI TITLES (Overhead Billboards & Prestiges)
-- =========================================================
export type TitleDef = {
	Id: string,
	Name: string,
	Category: string,
	Color: Color3,
	GlowColor: Color3,
	ReqDesc: string,
	DefaultUnlocked: boolean,
}

CosmeticsConfig.Titles = {
	{
		Id = "GeninRookie",
		Name = "⚔️ Genin Rookie",
		Category = "Rank",
		Color = Color3.fromRGB(180, 195, 215),
		GlowColor = Color3.fromRGB(120, 140, 170),
		ReqDesc = "Tersedia dari awal untuk seluruh Shinobi",
		DefaultUnlocked = true,
	},
	{
		Id = "ComboProdigy",
		Name = "⚡ Combo Prodigy",
		Category = "Combat",
		Color = Color3.fromRGB(255, 215, 0),
		GlowColor = Color3.fromRGB(255, 180, 30),
		ReqDesc = "Capai rekor 25+ Combo Streak",
		DefaultUnlocked = false,
	},
	{
		Id = "BossSlayer",
		Name = "👹 Akatsuki Boss Slayer",
		Category = "Mastery",
		Color = Color3.fromRGB(255, 40, 80),
		GlowColor = Color3.fromRGB(180, 20, 50),
		ReqDesc = "Tamatkan Gelombang 3 Akatsuki Shadow Boss",
		DefaultUnlocked = false,
	},
	{
		Id = "ShinobiWarlord",
		Name = "👑 Hokage Warlord",
		Category = "PvP",
		Color = Color3.fromRGB(0, 240, 255),
		GlowColor = Color3.fromRGB(0, 160, 220),
		ReqDesc = "Kumpulkan minimal 25 K.O. Eliminasi",
		DefaultUnlocked = false,
	},
	{
		Id = "AscendedMythic",
		Name = "🌌 Ascended Shinobi Legend",
		Category = "Prestige",
		Color = Color3.fromRGB(190, 80, 255),
		GlowColor = Color3.fromRGB(140, 40, 220),
		ReqDesc = "Tingkatkan salah satu karakter ke Bintang 5★",
		DefaultUnlocked = false,
	},
}

-- =========================================================
-- 2. K.O. KILL EFFECTS (Triggered at victim death location)
-- =========================================================
export type KillEffectDef = {
	Id: string,
	Name: string,
	Color: Color3,
	SoundId: string,
	SoundPitch: number,
	ReqDesc: string,
	DefaultUnlocked: boolean,
}

CosmeticsConfig.KillEffects = {
	{
		Id = "ClassicSmoke",
		Name = "💨 Classic Ninja Smoke",
		Color = Color3.fromRGB(220, 220, 230),
		SoundId = "rbxasset://sounds/shattered.mp3",
		SoundPitch = 1.0,
		ReqDesc = "Efek K.O. standar seluruh Shinobi",
		DefaultUnlocked = true,
	},
	{
		Id = "RaikiriLightning",
		Name = "⚡ Raikiri Thunder Burst",
		Color = Color3.fromRGB(0, 240, 255),
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		SoundPitch = 0.7,
		ReqDesc = "Beli di Toko / Hadiah Misi Mingguan (100 💎)",
		DefaultUnlocked = false,
	},
	{
		Id = "SakuraBlossom",
		Name = "🌸 Sakura Blossom Explosion",
		Color = Color3.fromRGB(255, 130, 180),
		SoundId = "rbxasset://sounds/action_jump.mp3",
		SoundPitch = 1.3,
		ReqDesc = "Beli di Toko / Hadiah Misi Mingguan (150 💎)",
		DefaultUnlocked = false,
	},
	{
		Id = "AmaterasuFlames",
		Name = "🔥 Amaterasu Black Flame",
		Color = Color3.fromRGB(40, 20, 30),
		SoundId = "rbxasset://sounds/impact_explosion_03.mp3",
		SoundPitch = 0.8,
		ReqDesc = "Miliki karakter Madara atau Sasuke Bintang 3★+",
		DefaultUnlocked = false,
	},
}

return CosmeticsConfig

