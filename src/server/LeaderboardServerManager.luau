--!strict
-- LeaderboardServerManager.luau
-- SERVER SCRIPT: Roblox Native Leaderstats & 3D Shinobi Hall of Fame Monument
-- Features:
--   • Native Roblox Tab Leaderstats (K.O.s, Highest Streak, Ryo)
--   • DataStore persistence for player lifetime stats
--   • 3D Japanese Pagoda Hall of Fame Monument in Grand Shinobi Arena
--   • Realtime dynamic sorting & rendering of Top Shinobi Warriors

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- DataStore Setup
local statsDataStore: DataStore? = nil
pcall(function()
	statsDataStore = DataStoreService:GetDataStore("StormClash_Leaderstats_v1")
end)

-- In-Memory Player Stats
type PlayerStatsRecord = {
	Kills: number,
	HighestStreak: number,
}
local playerStats: { [number]: PlayerStatsRecord } = {}

-- =========================================================
-- 1. NATIVE LEADERSTATS CREATION & PERSISTENCE
-- =========================================================
local function setupPlayerLeaderstats(player: Player)
	local userId = player.UserId
	local defaultStats: PlayerStatsRecord = {
		Kills = 0,
		HighestStreak = 0,
	}

	if statsDataStore then
		local success, saved = pcall(function()
			return statsDataStore:GetAsync("Stats_" .. tostring(userId))
		end)
		if success and typeof(saved) == "table" then
			defaultStats.Kills = saved.Kills or 0
			defaultStats.HighestStreak = saved.HighestStreak or 0
		end
	end

	playerStats[userId] = defaultStats

	-- Create standard Roblox leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local killsVal = Instance.new("IntValue")
	killsVal.Name = "K.O.s"
	killsVal.Value = defaultStats.Kills
	killsVal.Parent = leaderstats

	local streakVal = Instance.new("IntValue")
	streakVal.Name = "Streak"
	streakVal.Value = defaultStats.HighestStreak
	streakVal.Parent = leaderstats

	local ryoVal = Instance.new("IntValue")
	ryoVal.Name = "Ryo"
	ryoVal.Value = tonumber(player:GetAttribute("RyoValue")) or 300
	ryoVal.Parent = leaderstats

	leaderstats.Parent = player

	player:SetAttribute("KillsCount", defaultStats.Kills)
	player:SetAttribute("HighestStreak", defaultStats.HighestStreak)

	-- Sync attribute changes to leaderstats
	player:GetAttributeChangedSignal("KillsCount"):Connect(function()
		local k = tonumber(player:GetAttribute("KillsCount")) or 0
		killsVal.Value = k
		defaultStats.Kills = k
	end)

	player:GetAttributeChangedSignal("HighestStreak"):Connect(function()
		local s = tonumber(player:GetAttribute("HighestStreak")) or 0
		streakVal.Value = s
		defaultStats.HighestStreak = s
	end)

	player:GetAttributeChangedSignal("RyoValue"):Connect(function()
		local r = tonumber(player:GetAttribute("RyoValue")) or 0
		ryoVal.Value = r
	end)
end

local function savePlayerLeaderstats(player: Player)
	local userId = player.UserId
	local stats = playerStats[userId]
	if not stats or not statsDataStore then return end

	pcall(function()
		statsDataStore:SetAsync("Stats_" .. tostring(userId), {
			Kills = stats.Kills,
			HighestStreak = stats.HighestStreak,
		})
	end)
end

Players.PlayerAdded:Connect(setupPlayerLeaderstats)
Players.PlayerRemoving:Connect(function(player)
	savePlayerLeaderstats(player)
	playerStats[player.UserId] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
	setupPlayerLeaderstats(p)
end

-- =========================================================
-- 2. 3D SHINOBI HALL OF FAME MONUMENT (ARENA PERIMETER)
-- =========================================================
local monumentModel: Model? = nil
local listFrameContainer: Frame? = nil

local function build3DLeaderboardMonument()
	local existing = Workspace:FindFirstChild("ShinobiLeaderboardMonument")
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = "ShinobiLeaderboardMonument"

	local monumentPos = Vector3.new(-38, 0, 0)
	local lookTarget = Vector3.new(0, 3, 0) -- Faces center of the arena!

	-- Base Foundation Slab
	local baseSlab = Instance.new("Part")
	baseSlab.Name = "BaseSlab"
	baseSlab.Size = Vector3.new(16, 2, 8)
	baseSlab.CFrame = CFrame.lookAt(monumentPos + Vector3.new(0, 1, 0), lookTarget)
	baseSlab.Color = Color3.fromRGB(30, 35, 48)
	baseSlab.Material = Enum.Material.Slate
	baseSlab.Anchored = true
	baseSlab.Parent = model

	-- Main Display Tablet Part
	local screenPart = Instance.new("Part")
	screenPart.Name = "ScreenPart"
	screenPart.Size = Vector3.new(14, 10, 0.6)
	screenPart.CFrame = baseSlab.CFrame * CFrame.new(0, 6, 0)
	screenPart.Color = Color3.fromRGB(15, 18, 26)
	screenPart.Material = Enum.Material.SmoothPlastic
	screenPart.Anchored = true
	screenPart.Parent = model

	-- Wooden Torii Frame Pillars
	local function makePillar(offset: Vector3)
		local p = Instance.new("Part")
		p.Size = Vector3.new(1.2, 12, 1.2)
		p.CFrame = screenPart.CFrame * CFrame.new(offset.X, 0, offset.Z)
		p.Color = Color3.fromRGB(120, 35, 30)
		p.Material = Enum.Material.WoodPlanks
		p.Anchored = true
		p.Parent = model
		return p
	end
	makePillar(Vector3.new(-7.2, 0, 0))
	makePillar(Vector3.new(7.2, 0, 0))

	-- Top Pagoda Roof Beam
	local topRoof = Instance.new("Part")
	topRoof.Size = Vector3.new(17.5, 1.4, 2.5)
	topRoof.CFrame = screenPart.CFrame * CFrame.new(0, 5.6, 0)
	topRoof.Color = Color3.fromRGB(45, 48, 55)
	topRoof.Material = Enum.Material.Slate
	topRoof.Anchored = true
	topRoof.Parent = model

	-- Lanterns
	local function makeLantern(xOffset: number)
		local lantern = Instance.new("Part")
		lantern.Size = Vector3.new(1.2, 2, 1.2)
		lantern.CFrame = screenPart.CFrame * CFrame.new(xOffset, 4, 1)
		lantern.Color = Color3.fromRGB(255, 150, 40)
		lantern.Material = Enum.Material.Neon
		lantern.Anchored = true
		lantern.Parent = model

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 50)
		light.Range = 14
		light.Brightness = 2.5
		light.Parent = lantern
	end
	makeLantern(-6.5)
	makeLantern(6.5)

	-- =====================================================
	-- SURFACE GUI SETUP
	-- =====================================================
	local sGui = Instance.new("SurfaceGui")
	sGui.Name = "LeaderboardSurfaceGui"
	sGui.Face = Enum.NormalId.Front
	sGui.CanvasSize = Vector2.new(900, 650)
	sGui.LightInfluence = 0
	sGui.AlwaysOnTop = false
	sGui.Parent = screenPart

	-- Main Background
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	bg.BorderSizePixel = 0
	bg.Parent = sGui

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.fromRGB(0, 240, 255)
	bgStroke.Thickness = 3
	bgStroke.Parent = bg

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 85)
	header.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	header.BorderSizePixel = 0
	header.Parent = bg

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 48)
	title.Position = UDim2.new(0, 0, 0, 6)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 28
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Text = "⛩️ SHINOBI HALL OF FAME ⛩️"
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 24)
	subtitle.Position = UDim2.new(0, 0, 0, 52)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextSize = 14
	subtitle.TextColor3 = Color3.fromRGB(0, 240, 255)
	subtitle.Text = "★ TOP WARRIORS BY TOTAL K.O. ELIMINATIONS ★"
	subtitle.Parent = header

	-- Column Header
	local colHeader = Instance.new("Frame")
	colHeader.Size = UDim2.new(1, -40, 0, 32)
	colHeader.Position = UDim2.new(0, 20, 0, 95)
	colHeader.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	colHeader.Parent = bg
	Instance.new("UICorner", colHeader).CornerRadius = UDim.new(0, 6)

	local function makeColLabel(text: string, xPos: number, width: number, align: Enum.TextXAlignment): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(width, 0, 1, 0)
		lbl.Position = UDim2.new(xPos, 0, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextColor3 = Color3.fromRGB(160, 175, 200)
		lbl.TextXAlignment = align
		lbl.Text = text
		lbl.Parent = colHeader
		return lbl
	end
	makeColLabel("RANK", 0.03, 0.12, Enum.TextXAlignment.Left)
	makeColLabel("SHINOBI FIGHTER", 0.18, 0.40, Enum.TextXAlignment.Left)
	makeColLabel("HERO EQUIPPED", 0.60, 0.22, Enum.TextXAlignment.Left)
	makeColLabel("K.O.s", 0.84, 0.13, Enum.TextXAlignment.Right)

	-- Rows Container
	local rowsContainer = Instance.new("Frame")
	rowsContainer.Name = "RowsContainer"
	rowsContainer.Size = UDim2.new(1, -40, 0, 500)
	rowsContainer.Position = UDim2.new(0, 20, 0, 135)
	rowsContainer.BackgroundTransparency = 1
	rowsContainer.Parent = bg

	local rListLayout = Instance.new("UIListLayout")
	rListLayout.Padding = UDim.new(0, 10)
	rListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rListLayout.Parent = rowsContainer

	listFrameContainer = rowsContainer
	monumentModel = model
	model.Parent = Workspace
	print(">> [Leaderboard] 3D Shinobi Hall of Fame monument built at: " .. tostring(monumentPos) .. " <<")
end

-- =========================================================
-- 3. DYNAMIC REFRESH LOOP (TOP 5 SHINOBI)
-- =========================================================
local function refreshLeaderboardRows()
	if not listFrameContainer then return end

	-- Clear current rows
	for _, child in ipairs(listFrameContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Gather and sort active players
	type ShinobiEntry = {
		Name: string,
		DisplayName: string,
		CharName: string,
		CharStar: number,
		Kills: number,
		IsPlayer: boolean,
	}

	local entries: { ShinobiEntry } = {}

	for _, p in ipairs(Players:GetPlayers()) do
		local kills = tonumber(p:GetAttribute("KillsCount")) or 0
		local charId = tostring(p:GetAttribute("SelectedCharacter") or "Naruto")
		local starLevel = tonumber(p:GetAttribute("CharStar_" .. charId)) or 1
		local charDef = CombatConfig.Characters[charId]
		local charName = charDef and charDef.Name or charId

		table.insert(entries, {
			Name = p.Name,
			DisplayName = p.DisplayName,
			CharName = charName,
			CharStar = starLevel,
			Kills = kills,
			IsPlayer = true,
		})
	end

	-- Filler Legendary Shinobi if server has fewer than 5 players
	local legendaryLegends: { ShinobiEntry } = {
		{ Name = "Madara_Legend", DisplayName = "Madara Uchiha", CharName = "Madara", CharStar = 5, Kills = 88, IsPlayer = false },
		{ Name = "Sukuna_King",   DisplayName = "Ryomen Sukuna", CharName = "Sukuna", CharStar = 5, Kills = 74, IsPlayer = false },
		{ Name = "Gojo_Limitless", DisplayName = "Satoru Gojo", CharName = "Gojo", CharStar = 5, Kills = 62, IsPlayer = false },
		{ Name = "Sasuke_Avenger", DisplayName = "Sasuke Uchiha", CharName = "Sasuke", CharStar = 4, Kills = 45, IsPlayer = false },
		{ Name = "Zoro_Ashura",   DisplayName = "Roronoa Zoro", CharName = "Zoro", CharStar = 4, Kills = 36, IsPlayer = false },
	}

	for _, leg in ipairs(legendaryLegends) do
		if #entries < 5 then
			table.insert(entries, leg)
		end
	end

	-- Sort descending by K.O.s
	table.sort(entries, function(a, b)
		return a.Kills > b.Kills
	end)

	local rankStyles = {
		[1] = { Color = Color3.fromRGB(255, 215, 0),  Icon = "🥇", BgColor = Color3.fromRGB(38, 32, 20) },
		[2] = { Color = Color3.fromRGB(220, 230, 245), Icon = "🥈", BgColor = Color3.fromRGB(28, 32, 42) },
		[3] = { Color = Color3.fromRGB(255, 140, 50),  Icon = "🥉", BgColor = Color3.fromRGB(34, 26, 20) },
		[4] = { Color = Color3.fromRGB(170, 185, 210), Icon = "4",  BgColor = Color3.fromRGB(20, 25, 36) },
		[5] = { Color = Color3.fromRGB(150, 165, 190), Icon = "5",  BgColor = Color3.fromRGB(20, 25, 36) },
	}

	for rankIdx = 1, math.min(5, #entries) do
		local entry = entries[rankIdx]
		local style = rankStyles[rankIdx] or rankStyles[5]

		local row = Instance.new("Frame")
		row.Name = "Row_" .. tostring(rankIdx)
		row.Size = UDim2.new(1, 0, 0, 78)
		row.BackgroundColor3 = style.BgColor
		row.BackgroundTransparency = 0.2
		row.LayoutOrder = rankIdx
		row.Parent = listFrameContainer
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = style.Color
		rowStroke.Thickness = if rankIdx == 1 then 2.5 else 1.5
		rowStroke.Parent = row

		-- Rank Badge
		local rankLbl = Instance.new("TextLabel")
		rankLbl.Size = UDim2.new(0.12, 0, 1, 0)
		rankLbl.Position = UDim2.new(0.02, 0, 0, 0)
		rankLbl.BackgroundTransparency = 1
		rankLbl.Font = Enum.Font.GothamBlack
		rankLbl.TextSize = 24
		rankLbl.TextColor3 = style.Color
		rankLbl.Text = style.Icon
		rankLbl.Parent = row

		-- Fighter Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.40, 0, 0, 24)
		nameLbl.Position = UDim2.new(0.16, 0, 0, 16)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextSize = 16
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = string.upper(entry.DisplayName)
		nameLbl.Parent = row

		local subNameLbl = Instance.new("TextLabel")
		subNameLbl.Size = UDim2.new(0.40, 0, 0, 18)
		subNameLbl.Position = UDim2.new(0.16, 0, 0, 42)
		subNameLbl.BackgroundTransparency = 1
		subNameLbl.Font = Enum.Font.GothamMedium
		subNameLbl.TextSize = 11
		subNameLbl.TextColor3 = Color3.fromRGB(160, 175, 200)
		subNameLbl.TextXAlignment = Enum.TextXAlignment.Left
		subNameLbl.Text = "@" .. entry.Name .. (if entry.IsPlayer then " [ONLINE]" else " [HOF BOT]")
		subNameLbl.Parent = row

		-- Equipped Hero & Star Rank
		local heroLbl = Instance.new("TextLabel")
		heroLbl.Size = UDim2.new(0.24, 0, 1, 0)
		heroLbl.Position = UDim2.new(0.58, 0, 0, 0)
		heroLbl.BackgroundTransparency = 1
		heroLbl.Font = Enum.Font.GothamBold
		heroLbl.TextSize = 13
		heroLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
		heroLbl.TextXAlignment = Enum.TextXAlignment.Left
		heroLbl.Text = string.format("%s (%d★)", entry.CharName, entry.CharStar)
		heroLbl.Parent = row

		-- Total K.O.s
		local koLbl = Instance.new("TextLabel")
		koLbl.Size = UDim2.new(0.15, 0, 1, 0)
		koLbl.Position = UDim2.new(0.83, 0, 0, 0)
		koLbl.BackgroundTransparency = 1
		koLbl.Font = Enum.Font.GothamBlack
		koLbl.TextSize = 22
		koLbl.TextColor3 = style.Color
		koLbl.TextXAlignment = Enum.TextXAlignment.Right
		koLbl.Text = tostring(entry.Kills) .. " 💥"
		koLbl.Parent = row
	end
end

-- Initialize Monument & Dynamic Update Loop
task.delay(1.5, function()
	build3DLeaderboardMonument()
	refreshLeaderboardRows()

	-- Periodic update every 3.5 seconds
	while true do
		task.wait(3.5)
		refreshLeaderboardRows()
	end
end)

print("[LeaderboardServerManager] ✅ Native Leaderstats & 3D Shinobi Hall of Fame active.")
