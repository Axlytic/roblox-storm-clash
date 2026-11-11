--!strict
-- CosmeticsServerManager.luau
-- SERVER SCRIPT: Authoritative Title Badges, Overhead Billboards, and K.O. Kill FX Engine

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")

local CosmeticsConfig = require(ReplicatedStorage:WaitForChild("CosmeticsConfig")) :: any

-- DataStore Setup
local cosDataStore: DataStore? = nil
pcall(function()
	cosDataStore = DataStoreService:GetDataStore("StormClash_Cosmetics_v1")
end)

-- Remotes
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

local evEquipCosmetic = ensureRemote("EquipCosmeticEvent")
local evSyncCosmetic  = ensureRemote("SyncCosmeticEvent")

-- In-Memory Player Profiles
type PlayerCosmeticProfile = {
	EquippedTitle: string,
	EquippedKillEffect: string,
	UnlockedTitles: { [string]: boolean },
	UnlockedKillEffects: { [string]: boolean },
}
local playerCosmetics: { [number]: PlayerCosmeticProfile } = {}

local function createDefaultProfile(): PlayerCosmeticProfile
	local titles = {}
	for _, t in ipairs(CosmeticsConfig.Titles) do
		if t.DefaultUnlocked then titles[t.Id] = true end
	end
	local kfx = {}
	for _, k in ipairs(CosmeticsConfig.KillEffects) do
		if k.DefaultUnlocked then kfx[k.Id] = true end
	end
	return {
		EquippedTitle = "GeninRookie",
		EquippedKillEffect = "ClassicSmoke",
		UnlockedTitles = titles,
		UnlockedKillEffects = kfx,
	}
end

-- =========================================================
-- 1. DATA PERSISTENCE & OVERHEAD BILLBOARD
-- =========================================================
local function applyOverheadTitle(player: Player, char: Model)
	local head = char:WaitForChild("Head", 5) :: BasePart?
	if not head then return end

	local existing = head:FindFirstChild("ShinobiTitleTag")
	if existing then existing:Destroy() end

	local prof = playerCosmetics[player.UserId]
	local titleId = prof and prof.EquippedTitle or "GeninRookie"

	local titleDef: any = nil
	for _, t in ipairs(CosmeticsConfig.Titles) do
		if t.Id == titleId then
			titleDef = t
			break
		end
	end
	if not titleDef then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "ShinobiTitleTag"
	bb.Size = UDim2.new(0, 220, 0, 52)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "TitleText"
	titleLbl.Size = UDim2.new(1, 0, 0, 22)
	titleLbl.Position = UDim2.new(0, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 14
	titleLbl.TextColor3 = titleDef.Color
	titleLbl.Text = titleDef.Name
	titleLbl.Parent = bb

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = titleDef.GlowColor
	tStroke.Thickness = 1.8
	tStroke.Parent = titleLbl

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "PlayerName"
	nameLbl.Size = UDim2.new(1, 0, 0, 18)
	nameLbl.Position = UDim2.new(0, 0, 0, 24)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 12
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	nameLbl.Parent = bb
end

local function loadPlayerCosmetics(player: Player)
	local userId = player.UserId
	local defaultProf = createDefaultProfile()

	if cosDataStore then
		local success, saved = pcall(function()
			return cosDataStore:GetAsync("Cos_" .. tostring(userId))
		end)
		if success and typeof(saved) == "table" then
			if saved.EquippedTitle then defaultProf.EquippedTitle = saved.EquippedTitle end
			if saved.EquippedKillEffect then defaultProf.EquippedKillEffect = saved.EquippedKillEffect end
			if typeof(saved.UnlockedTitles) == "table" then
				for k, v in pairs(saved.UnlockedTitles) do
					if v == true then defaultProf.UnlockedTitles[k] = true end
				end
			end
			if typeof(saved.UnlockedKillEffects) == "table" then
				for k, v in pairs(saved.UnlockedKillEffects) do
					if v == true then defaultProf.UnlockedKillEffects[k] = true end
				end
			end
		end
	end

	playerCosmetics[userId] = defaultProf
	player:SetAttribute("EquippedTitle", defaultProf.EquippedTitle)
	player:SetAttribute("EquippedKillEffect", defaultProf.EquippedKillEffect)

	if player.Character then
		applyOverheadTitle(player, player.Character)
	end
	evSyncCosmetic:FireClient(player, defaultProf)
end

local function savePlayerCosmetics(player: Player)
	local userId = player.UserId
	local prof = playerCosmetics[userId]
	if not prof or not cosDataStore then return end

	pcall(function()
		cosDataStore:SetAsync("Cos_" .. tostring(userId), {
			EquippedTitle = prof.EquippedTitle,
			EquippedKillEffect = prof.EquippedKillEffect,
			UnlockedTitles = prof.UnlockedTitles,
			UnlockedKillEffects = prof.UnlockedKillEffects,
		})
	end)
end

Players.PlayerAdded:Connect(function(player)
	loadPlayerCosmetics(player)
	player.CharacterAdded:Connect(function(char)
		task.delay(0.5, function()
			applyOverheadTitle(player, char)
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerCosmetics(player)
	playerCosmetics[player.UserId] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
	loadPlayerCosmetics(p)
end

-- =========================================================
-- 2. K.O. KILL EFFECT SPAWNER
-- =========================================================
function _G.PlayKillEffect(effectId: string, pos: Vector3)
	local rootPart = Instance.new("Part")
	rootPart.Name = "KillEffect_" .. effectId
	rootPart.Size = Vector3.new(1, 1, 1)
	rootPart.Position = pos
	rootPart.Transparency = 1
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Parent = Workspace

	if effectId == "RaikiriLightning" then
		-- Lightning Strike Bolt from sky
		local bolt = Instance.new("Part")
		bolt.Size = Vector3.new(1.8, 38, 1.8)
		bolt.Position = pos + Vector3.new(0, 19, 0)
		bolt.Color = Color3.fromRGB(0, 240, 255)
		bolt.Material = Enum.Material.Neon
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.Parent = rootPart

		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(120, 255, 255), Color3.fromRGB(0, 180, 255))
		pe.Size = NumberSequence.new(1.5, 0.2)
		pe.Speed = NumberRange.new(14, 28)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Lifetime = NumberRange.new(0.4, 0.7)
		pe.Parent = bolt
		pe:Emit(40)

		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			s.PlaybackSpeed = 0.65
			s.Volume = 1
			s.Parent = rootPart
			s:Play()
		end)

		Debris:AddItem(bolt, 0.35)

	elseif effectId == "SakuraBlossom" then
		-- Sakura Petal Explosion
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 140, 190), Color3.fromRGB(255, 200, 225))
		pe.Size = NumberSequence.new(1.8, 0.4)
		pe.Speed = NumberRange.new(8, 20)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Parent = rootPart
		pe:Emit(50)

		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/action_jump.mp3"
			s.PlaybackSpeed = 1.3
			s.Volume = 0.9
			s.Parent = rootPart
			s:Play()
		end)

	elseif effectId == "AmaterasuFlames" then
		-- Black Cursed Flame Pillar
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(30, 10, 45)
		fire.SecondaryColor = Color3.fromRGB(180, 20, 60)
		fire.Size = 12
		fire.Heat = 15
		fire.Parent = rootPart

		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
			s.PlaybackSpeed = 0.8
			s.Volume = 1
			s.Parent = rootPart
			s:Play()
		end)

		task.delay(1.5, function() fire.Enabled = false end)

	else
		-- Classic Smoke
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(230, 230, 240)
		smoke.Size = 8
		smoke.RiseVelocity = 5
		smoke.Parent = rootPart
		task.delay(1.2, function() smoke.Enabled = false end)
	end

	task.delay(2.5, function() rootPart:Destroy() end)
end

-- =========================================================
-- 3. REMOTE EVENT HANDLERS
-- =========================================================
evEquipCosmetic.OnServerEvent:Connect(function(player: Player, kind: string, cosmeticId: string)
	local prof = playerCosmetics[player.UserId]
	if not prof then return end

	if kind == "Title" then
		prof.EquippedTitle = cosmeticId
		player:SetAttribute("EquippedTitle", cosmeticId)
		if player.Character then
			applyOverheadTitle(player, player.Character)
		end
	elseif kind == "KillEffect" then
		prof.EquippedKillEffect = cosmeticId
		player:SetAttribute("EquippedKillEffect", cosmeticId)
	end

	evSyncCosmetic:FireClient(player, prof)
	print(string.format(">> [CosmeticsServer] %s equipped %s: %s", player.Name, kind, cosmeticId))
end)

print("[CosmeticsServerManager] ✅ Shinobi Titles & K.O. Kill FX active.")
