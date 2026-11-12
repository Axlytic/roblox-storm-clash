--!strict
-- DuelConfig.luau
-- Shared Ranked 1v1 PvP Matchmaking & Duel Arena Rules

export type RankTier = {
	MinElo: number,
	Name: string,
	Color: Color3,
	Badge: string,
}

local DuelConfig = {
	-- Match Progression Rules
	Match = {
		RoundTimeLimit = 90,        -- Seconds per round
		RoundsToWin = 2,            -- Best of 3
		CountdownSeconds = 3,       -- "3.. 2.. 1.. FIGHT!" freeze
		PostRoundDelay = 3.5,       -- Delay between rounds
		PostMatchDelay = 6.0,       -- Delay before teleporting back to lobby
	},

	-- Competitive Ranking & Rewards
	Rating = {
		BaseElo = 1000,
		WinElo = 25,
		LossElo = 15,
		WinRyo = 300,
		WinShards = 35,
		LossRyo = 50,
	},

	-- Coordinates (Sky Duel Arena)
	Arena = {
		Center = Vector3.new(0, 180, 0),
		SpawnP1 = Vector3.new(-28, 183, 0), -- Crimson/Red Corner
		SpawnP2 = Vector3.new(28, 183, 0),  -- Azure/Blue Corner
		LobbySpawn = Vector3.new(0, 52.5, -130), -- Return to Lobby
		ArenaRadius = 45,
	},

	-- Competitive Tiers
	Tiers = {
		{ MinElo = 0,    Name = "Bronze Genin",  Color = Color3.fromRGB(180, 115, 60),  Badge = "🥉" },
		{ MinElo = 1100, Name = "Silver Chunin", Color = Color3.fromRGB(195, 205, 220), Badge = "🥈" },
		{ MinElo = 1300, Name = "Gold Jonin",    Color = Color3.fromRGB(255, 215, 0),   Badge = "🥇" },
		{ MinElo = 1600, Name = "Diamond ANBU",  Color = Color3.fromRGB(0, 240, 255),   Badge = "💎" },
		{ MinElo = 1900, Name = "Mythic Kage",   Color = Color3.fromRGB(255, 45, 85),   Badge = "👑" },
	} :: { RankTier },
}

function DuelConfig.GetTierForElo(elo: number): RankTier
	local currentTier = DuelConfig.Tiers[1]
	for _, tier in ipairs(DuelConfig.Tiers) do
		if elo >= tier.MinElo then
			currentTier = tier
		end
	end
	return currentTier
end

return DuelConfig

