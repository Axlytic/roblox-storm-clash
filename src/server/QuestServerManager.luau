--!strict
-- QuestServerManager.luau
-- SERVER SCRIPT: Authoritative Quest Engine, Daily Login Streak Tracker, and Reward Dispenser

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig")) :: any

-- DataStore Setup with Safe Fallback
local questDataStore: DataStore? = nil
pcall(function()
	questDataStore = DataStoreService:GetDataStore("StormClash_Quests_v1")
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

local evQuestSync       = ensureRemote("QuestSyncEvent")
local evClaimQuest      = ensureRemote("ClaimQuestRewardEvent")
local evClaimStreak     = ensureRemote("ClaimLoginStreakEvent")
local evQuestNotify     = ensureRemote("QuestNotificationEvent")

-- In-Memory Player Quest Profiles
type PlayerQuestProfile = {
	StreakDay: number,
	LastStreakClaim: number,
	Quests: { [string]: { Current: number, Claimed: boolean } },
}

local questProfiles: { [number]: PlayerQuestProfile } = {}

local function createDefaultQuestProfile(): PlayerQuestProfile
	local qMap = {}
	for _, q in ipairs(QuestConfig.DailyQuests) do
		qMap[q.Id] = { Current = 0, Claimed = false }
	end
	return {
		StreakDay = 1,
		LastStreakClaim = 0,
		Quests = qMap,
	}
end

-- =========================================================
-- 1. DATA PERSISTENCE
-- =========================================================
local function loadQuestData(player: Player)
	local userId = player.UserId
	local prof = createDefaultQuestProfile()

	if questDataStore then
		local success, saved = pcall(function()
			return questDataStore:GetAsync("Quest_" .. tostring(userId))
		end)
		if success and saved and type(saved) == "table" then
			if saved.StreakDay then prof.StreakDay = saved.StreakDay end
			if saved.LastStreakClaim then prof.LastStreakClaim = saved.LastStreakClaim end
			if saved.Quests and type(saved.Quests) == "table" then
				for qId, qData in pairs(saved.Quests) do
					if prof.Quests[qId] then
						prof.Quests[qId].Current = qData.Current or 0
						prof.Quests[qId].Claimed = qData.Claimed or false
					end
				end
			end
		end
	end

	questProfiles[userId] = prof
	evQuestSync:FireClient(player, prof)
end

local function saveQuestData(player: Player)
	local userId = player.UserId
	local prof = questProfiles[userId]
	if not prof or not questDataStore then return end

	pcall(function()
		questDataStore:SetAsync("Quest_" .. tostring(userId), {
			StreakDay = prof.StreakDay,
			LastStreakClaim = prof.LastStreakClaim,
			Quests = prof.Quests,
		})
	end)
end

Players.PlayerAdded:Connect(function(player)
	loadQuestData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveQuestData(player)
	questProfiles[player.UserId] = nil
end)

-- Handle existing players
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(loadQuestData, p)
end

-- =========================================================
-- 2. AUTHORITATIVE QUEST PROGRESSION API
-- =========================================================
function _G.AddQuestProgress(player: Player, questId: string, amount: number)
	if not player or not player.Parent then return end
	local prof = questProfiles[player.UserId]
	if not prof then return end

	local qState = prof.Quests[questId]
	if not qState or qState.Claimed then return end

	-- Find quest def
	local qDef: any = nil
	for _, q in ipairs(QuestConfig.DailyQuests) do
		if q.Id == questId then
			qDef = q
			break
		end
	end
	if not qDef then return end

	local old = qState.Current
	local new = math.min(qDef.TargetGoal, old + (amount or 1))
	qState.Current = new

	if old < qDef.TargetGoal and new >= qDef.TargetGoal then
		-- Quest Completed!
		evQuestNotify:FireClient(player, {
			Title = "🏆 MISI SELESAI!",
			Message = qDef.Title .. " siap diklaim!",
			QuestId = questId,
		})
	end

	evQuestSync:FireClient(player, prof)
end

-- =========================================================
-- 3. REMOTE EVENT HANDLERS
-- =========================================================
evClaimQuest.OnServerEvent:Connect(function(player: Player, questId: string)
	local prof = questProfiles[player.UserId]
	if not prof then return end

	local qState = prof.Quests[questId]
	if not qState or qState.Claimed then
		evClaimQuest:FireClient(player, { Success = false, Message = "Misi belum selesai atau sudah diklaim!" })
		return
	end

	local qDef: any = nil
	for _, q in ipairs(QuestConfig.DailyQuests) do
		if q.Id == questId then
			qDef = q
			break
		end
	end
	if not qDef then return end

	if qState.Current < qDef.TargetGoal then
		evClaimQuest:FireClient(player, { Success = false, Message = "Target misi belum tercapai!" })
		return
	end

	qState.Claimed = true

	-- Award Ryo via global economy handler
	if _G.AwardCombatRyo then
		_G.AwardCombatRyo(player, qDef.RyoReward, "Hadiah Misi: " .. qDef.Title)
	end

	evClaimQuest:FireClient(player, {
		Success = true,
		QuestId = questId,
		RyoAwarded = qDef.RyoReward,
		ShardsAwarded = qDef.ShardsReward,
		Message = string.format("Berhasil klaim +%d Ryo dari misi %s!", qDef.RyoReward, qDef.Title),
	})
	evQuestSync:FireClient(player, prof)
end)

evClaimStreak.OnServerEvent:Connect(function(player: Player)
	local prof = questProfiles[player.UserId]
	if not prof then return end

	local now = os.time()
	local elapsed = now - prof.LastStreakClaim
	if elapsed < QuestConfig.DailyClaimCooldown and prof.LastStreakClaim > 0 then
		local remaining = QuestConfig.DailyClaimCooldown - elapsed
		local hours = math.floor(remaining / 3600)
		local mins = math.floor((remaining % 3600) / 60)
		evClaimStreak:FireClient(player, {
			Success = false,
			Message = string.format("Login streak sudah diklaim! Kembali dalam %d jam %d menit.", hours, mins),
		})
		return
	end

	local dayIndex = prof.StreakDay
	local streakData = QuestConfig.LoginStreakDays[dayIndex] or QuestConfig.LoginStreakDays[1]

	prof.LastStreakClaim = now
	prof.StreakDay = if dayIndex >= 7 then 1 else dayIndex + 1

	if _G.AwardCombatRyo then
		_G.AwardCombatRyo(player, streakData.Ryo, "Login Streak Day " .. tostring(dayIndex))
	end

	evClaimStreak:FireClient(player, {
		Success = true,
		DayClaimed = dayIndex,
		RyoAwarded = streakData.Ryo,
		ShardsAwarded = streakData.Shards,
		NextDay = prof.StreakDay,
		Message = string.format("🎉 Berhasil klaim Hadiah Hari ke-%d: +%d Ryo!", dayIndex, streakData.Ryo),
	})
	evQuestSync:FireClient(player, prof)
end)

evQuestSync.OnServerEvent:Connect(function(player: Player)
	local prof = questProfiles[player.UserId]
	if prof then
		evQuestSync:FireClient(player, prof)
	end
end)

print("[QuestServerManager] ✅ Authoritative Quest & Login Streak Engine loaded.")

