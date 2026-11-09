--!strict
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
