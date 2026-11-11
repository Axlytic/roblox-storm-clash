--!strict
-- StormDuelHUD.luau
-- CLIENT SCRIPT: Ranked 1v1 Matchmaking Queue, Best-of-3 Scoreboard & Cinematic Duel Overlay
-- Features:
--   • Sleek Queue Modal: ELO rating, tier badge, radar animation, and instant matchmaking
--   • Top-Screen VS Header: Fighter avatars, names, round win dots, and 90s countdown timer
--   • Fullscreen Anime Announcer: "ROUND 1", "FIGHT!", "ROUND WON", and Match Victory/Defeat banners
--   • Built-in audio cues & spring tweens on round transitions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DuelConfig = require(ReplicatedStorage:WaitForChild("DuelConfig"))

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evQueue      = combatEvents:WaitForChild("DuelQueueEvent", 15) :: RemoteEvent
local evMatchStart = combatEvents:WaitForChild("DuelMatchStartEvent", 15) :: RemoteEvent
local evRoundState = combatEvents:WaitForChild("DuelRoundStateEvent", 15) :: RemoteEvent
local evMatchEnd   = combatEvents:WaitForChild("DuelMatchEndEvent", 15) :: RemoteEvent

-- Sound Engine
local function playSafeSound(soundId: string, pitch: number, vol: number?)
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = soundId
			s.PlaybackSpeed = pitch or 1.0
			s.Volume = vol or 0.85
			s.Parent = SoundService
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
		end)
	end)
end

-- =========================================================
-- SCREEN GUI ROOT
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormDuelHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 14
screenGui.Parent = PlayerGui

-- =========================================================
-- 1. MATCHMAKING QUEUE MODAL
-- =========================================================
local queueModal = Instance.new("Frame")
queueModal.Name = "QueueModal"
queueModal.Size = UDim2.new(0, 480, 0, 320)
queueModal.Position = UDim2.new(0.5, 0, 0.5, 0)
queueModal.AnchorPoint = Vector2.new(0.5, 0.5)
queueModal.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
queueModal.BackgroundTransparency = 0.08
queueModal.Visible = false
queueModal.Parent = screenGui
Instance.new("UICorner", queueModal).CornerRadius = UDim.new(0, 16)

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(255, 45, 85)
modalStroke.Thickness = 2
modalStroke.Parent = queueModal

-- Header
local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "Title"
modalTitle.Size = UDim2.new(1, -60, 0, 45)
modalTitle.Position = UDim2.new(0, 20, 0, 10)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBlack
modalTitle.TextSize = 20
modalTitle.TextColor3 = Color3.fromRGB(255, 230, 80)
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.Text = "⚔️ ARENA DUEL RANKED 1v1"
modalTitle.Parent = queueModal

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 18, 24)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 100)
closeBtn.Text = "✕"
closeBtn.Parent = queueModal
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
	queueModal.Visible = false
end)

-- ELO Rating Card
local eloCard = Instance.new("Frame")
eloCard.Name = "EloCard"
eloCard.Size = UDim2.new(1, -40, 0, 110)
eloCard.Position = UDim2.new(0, 20, 0, 65)
eloCard.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
eloCard.BackgroundTransparency = 0.3
eloCard.Parent = queueModal
Instance.new("UICorner", eloCard).CornerRadius = UDim.new(0, 12)

local badgeLabel = Instance.new("TextLabel")
badgeLabel.Name = "BadgeLabel"
badgeLabel.Size = UDim2.new(0, 70, 0, 70)
badgeLabel.Position = UDim2.new(0, 15, 0.5, -35)
badgeLabel.BackgroundTransparency = 1
badgeLabel.Font = Enum.Font.GothamBlack
badgeLabel.TextSize = 44
badgeLabel.Text = "🥇"
badgeLabel.Parent = eloCard

local tierLabel = Instance.new("TextLabel")
tierLabel.Name = "TierLabel"
tierLabel.Size = UDim2.new(1, -110, 0, 30)
tierLabel.Position = UDim2.new(0, 95, 0, 18)
tierLabel.BackgroundTransparency = 1
tierLabel.Font = Enum.Font.GothamBlack
tierLabel.TextSize = 20
tierLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
tierLabel.TextXAlignment = Enum.TextXAlignment.Left
tierLabel.Text = "Gold Jonin"
tierLabel.Parent = eloCard

local eloPointsLabel = Instance.new("TextLabel")
eloPointsLabel.Name = "EloPointsLabel"
eloPointsLabel.Size = UDim2.new(1, -110, 0, 22)
eloPointsLabel.Position = UDim2.new(0, 95, 0, 48)
eloPointsLabel.BackgroundTransparency = 1
eloPointsLabel.Font = Enum.Font.GothamBold
eloPointsLabel.TextSize = 14
eloPointsLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
eloPointsLabel.TextXAlignment = Enum.TextXAlignment.Left
eloPointsLabel.Text = "Rating: 1420 ELO • Rekor: 12 M / 4 K"
eloPointsLabel.Parent = eloCard

local rewardNotice = Instance.new("TextLabel")
rewardNotice.Name = "RewardNotice"
rewardNotice.Size = UDim2.new(1, -110, 0, 18)
rewardNotice.Position = UDim2.new(0, 95, 0, 74)
rewardNotice.BackgroundTransparency = 1
rewardNotice.Font = Enum.Font.Gotham
rewardNotice.TextSize = 11
rewardNotice.TextColor3 = Color3.fromRGB(180, 200, 220)
rewardNotice.TextXAlignment = Enum.TextXAlignment.Left
rewardNotice.Text = "Menang: +25 ELO, +300 Ryo, +35 Shards | Format: Best of 3"
rewardNotice.Parent = eloCard

-- Queue Action Button
local findMatchBtn = Instance.new("TextButton")
findMatchBtn.Name = "FindMatchBtn"
findMatchBtn.Size = UDim2.new(1, -40, 0, 50)
findMatchBtn.Position = UDim2.new(0, 20, 0, 195)
findMatchBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
findMatchBtn.Font = Enum.Font.GothamBlack
findMatchBtn.TextSize = 16
findMatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
findMatchBtn.Text = "⚔️ CARI LAWAN (FIND MATCH)"
findMatchBtn.Parent = queueModal
Instance.new("UICorner", findMatchBtn).CornerRadius = UDim.new(0, 12)

local queueStatusLabel = Instance.new("TextLabel")
queueStatusLabel.Name = "QueueStatus"
queueStatusLabel.Size = UDim2.new(1, -40, 0, 24)
queueStatusLabel.Position = UDim2.new(0, 20, 0, 260)
queueStatusLabel.BackgroundTransparency = 1
queueStatusLabel.Font = Enum.Font.GothamBold
queueStatusLabel.TextSize = 12
queueStatusLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
queueStatusLabel.Text = "Status: Menunggu di Lobby"
queueStatusLabel.Parent = queueModal

local isQueued = false
local queueStartTime = 0

local function updateEloCard()
	local elo = LocalPlayer:GetAttribute("RankedElo") or DuelConfig.Rating.BaseElo
	local wins = LocalPlayer:GetAttribute("RankedWins") or 0
	local losses = LocalPlayer:GetAttribute("RankedLosses") or 0
	local tier = DuelConfig.GetTierForElo(elo)

	badgeLabel.Text = tier.Badge
	tierLabel.Text = tier.Name
	tierLabel.TextColor3 = tier.Color
	eloPointsLabel.Text = string.format("Rating: %d ELO • Rekor: %d M / %d K", elo, wins, losses)
end

findMatchBtn.MouseButton1Click:Connect(function()
	if not isQueued then
		evQueue:FireServer("Join")
	else
		evQueue:FireServer("Leave")
	end
end)

evQueue.OnClientEvent:Connect(function(status: string, queueCount: number)
	if status == "Queued" then
		isQueued = true
		queueStartTime = os.clock()
		findMatchBtn.Text = "✕ BATAL CARI LAWAN"
		findMatchBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
		queueStatusLabel.Text = string.format("⏳ Mencari Shinobi sepadan... (Antrean: %d pemain)", queueCount)
		queueStatusLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
		playSafeSound("rbxasset://sounds/electronicpingshort.wav", 1.2, 0.6)
	else
		isQueued = false
		findMatchBtn.Text = "⚔️ CARI LAWAN (FIND MATCH)"
		findMatchBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
		queueStatusLabel.Text = "Status: Menunggu di Lobby"
		queueStatusLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
	end
end)

-- =========================================================
-- 2. IN-DUEL SCOREBOARD (Top Screen Bar)
-- =========================================================
local duelScoreboard = Instance.new("Frame")
duelScoreboard.Name = "DuelScoreboard"
duelScoreboard.Size = UDim2.new(0, 520, 0, 56)
duelScoreboard.Position = UDim2.new(0.5, 0, 0, 14)
duelScoreboard.AnchorPoint = Vector2.new(0.5, 0)
duelScoreboard.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
duelScoreboard.BackgroundTransparency = 0.15
duelScoreboard.Visible = false
duelScoreboard.Parent = screenGui
Instance.new("UICorner", duelScoreboard).CornerRadius = UDim.new(0, 14)

local sbStroke = Instance.new("UIStroke")
sbStroke.Color = Color3.fromRGB(255, 215, 0)
sbStroke.Thickness = 2
sbStroke.Parent = duelScoreboard

-- P1 (Left - Crimson)
local p1Name = Instance.new("TextLabel")
p1Name.Name = "P1Name"
p1Name.Size = UDim2.new(0, 160, 0, 24)
p1Name.Position = UDim2.new(0, 14, 0, 6)
p1Name.BackgroundTransparency = 1
p1Name.Font = Enum.Font.GothamBlack
p1Name.TextSize = 13
p1Name.TextColor3 = Color3.fromRGB(255, 60, 80)
p1Name.TextXAlignment = Enum.TextXAlignment.Left
p1Name.Text = "Player 1"
p1Name.Parent = duelScoreboard

local p1Dots = Instance.new("TextLabel")
p1Dots.Name = "P1Dots"
p1Dots.Size = UDim2.new(0, 160, 0, 20)
p1Dots.Position = UDim2.new(0, 14, 0, 30)
p1Dots.BackgroundTransparency = 1
p1Dots.Font = Enum.Font.GothamBlack
p1Dots.TextSize = 15
p1Dots.TextColor3 = Color3.fromRGB(255, 215, 0)
p1Dots.TextXAlignment = Enum.TextXAlignment.Left
p1Dots.Text = "⚪ ⚪"
p1Dots.Parent = duelScoreboard

-- P2 (Right - Azure)
local p2Name = Instance.new("TextLabel")
p2Name.Name = "P2Name"
p2Name.Size = UDim2.new(0, 160, 0, 24)
p2Name.Position = UDim2.new(1, -174, 0, 6)
p2Name.BackgroundTransparency = 1
p2Name.Font = Enum.Font.GothamBlack
p2Name.TextSize = 13
p2Name.TextColor3 = Color3.fromRGB(0, 220, 255)
p2Name.TextXAlignment = Enum.TextXAlignment.Right
p2Name.Text = "Player 2"
p2Name.Parent = duelScoreboard

local p2Dots = Instance.new("TextLabel")
p2Dots.Name = "P2Dots"
p2Dots.Size = UDim2.new(0, 160, 0, 20)
p2Dots.Position = UDim2.new(1, -174, 0, 30)
p2Dots.BackgroundTransparency = 1
p2Dots.Font = Enum.Font.GothamBlack
p2Dots.TextSize = 15
p2Dots.TextColor3 = Color3.fromRGB(255, 215, 0)
p2Dots.TextXAlignment = Enum.TextXAlignment.Right
p2Dots.Text = "⚪ ⚪"
p2Dots.Parent = duelScoreboard

-- Center Timer & Round
local roundTitle = Instance.new("TextLabel")
roundTitle.Name = "RoundTitle"
roundTitle.Size = UDim2.new(0, 140, 0, 20)
roundTitle.Position = UDim2.new(0.5, -70, 0, 6)
roundTitle.BackgroundTransparency = 1
roundTitle.Font = Enum.Font.GothamBlack
roundTitle.TextSize = 12
roundTitle.TextColor3 = Color3.fromRGB(255, 230, 80)
roundTitle.Text = "ROUND 1"
roundTitle.Parent = duelScoreboard

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0, 140, 0, 24)
timerLabel.Position = UDim2.new(0.5, -70, 0, 26)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextSize = 18
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Text = "⏱️ 90"
timerLabel.Parent = duelScoreboard

-- =========================================================
-- 3. FULLSCREEN ANIME ANNOUNCER OVERLAY
-- =========================================================
local announcerBanner = Instance.new("TextLabel")
announcerBanner.Name = "AnnouncerBanner"
announcerBanner.Size = UDim2.new(1, 0, 0, 120)
announcerBanner.Position = UDim2.new(0, 0, 0.38, 0)
announcerBanner.BackgroundTransparency = 1
announcerBanner.Font = Enum.Font.GothamBlack
announcerBanner.TextSize = 72
announcerBanner.TextColor3 = Color3.fromRGB(255, 45, 85)
announcerBanner.Text = ""
announcerBanner.Visible = false
announcerBanner.Parent = screenGui

local aStroke = Instance.new("UIStroke")
aStroke.Color = Color3.fromRGB(255, 230, 80)
aStroke.Thickness = 3
aStroke.Parent = announcerBanner

local function flashAnnouncer(text: string, color: Color3, duration: number, soundId: string?)
	announcerBanner.Text = text
	announcerBanner.TextColor3 = color
	announcerBanner.TextSize = 90
	announcerBanner.Visible = true

	if soundId then
		playSafeSound(soundId, 1.0, 1.0)
	end

	local tw = TweenService:Create(announcerBanner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 72,
	})
	tw:Play()

	task.delay(duration, function()
		local twFade = TweenService:Create(announcerBanner, TweenInfo.new(0.4), { TextTransparency = 1 })
		twFade:Play()
		twFade.Completed:Connect(function()
			announcerBanner.Visible = false
			announcerBanner.TextTransparency = 0
		end)
	end)
end

-- =========================================================
-- REMOTE LISTENERS
-- =========================================================
evMatchStart.OnClientEvent:Connect(function(info: any)
	queueModal.Visible = false
	duelScoreboard.Visible = true

	local isP1 = (info.Side == "P1")
	p1Name.Text = isP1 and LocalPlayer.DisplayName or info.OpponentDisplayName
	p2Name.Text = isP1 and info.OpponentDisplayName or LocalPlayer.DisplayName
	p1Dots.Text = "⚪ ⚪"
	p2Dots.Text = "⚪ ⚪"
	roundTitle.Text = "ROUND 1"
	timerLabel.Text = "⏱️ 90"

	flashAnnouncer("⚔️ DUEL 1v1 DIMULAI! ⚔️", Color3.fromRGB(255, 230, 80), 2.2, "rbxasset://sounds/bell.wav")
end)

evRoundState.OnClientEvent:Connect(function(state: string, roundNum: number, s1: number, s2: number, timer: number, extra: string)
	roundTitle.Text = "ROUND " .. tostring(roundNum)

	-- Update Score Dots
	local p1Won = (s1 >= 1 and "🔴 " or "⚪ ") .. (s1 >= 2 and "🔴" or "⚪")
	local p2Won = (s2 >= 1 and "🔵 " or "⚪ ") .. (s2 >= 2 and "🔵" or "⚪")
	p1Dots.Text = p1Won
	p2Dots.Text = p2Won

	if state == "Countdown" then
		if timer > 0 then
			flashAnnouncer(tostring(timer), Color3.fromRGB(255, 215, 0), 0.75, "rbxasset://sounds/electronicpingshort.wav")
		elseif extra == "FIGHT!" then
			flashAnnouncer("FIGHT!", Color3.fromRGB(255, 30, 60), 1.2, "rbxasset://sounds/impact_explosion_03.mp3")
		end
	elseif state == "InRound" then
		timerLabel.Text = string.format("⏱️ %02d", timer)
	elseif state == "RoundWon" then
		flashAnnouncer("★ ROUND " .. tostring(roundNum) .. " WON! ★\n" .. extra, Color3.fromRGB(0, 240, 255), 2.5, "rbxasset://sounds/bell.wav")
	end
end)

evMatchEnd.OnClientEvent:Connect(function(isWinner: boolean, oldElo: number, newElo: number, delta: number, ryoReward: number, shardsReward: number)
	duelScoreboard.Visible = false

	if isWinner then
		flashAnnouncer(
			string.format("👑 VICTORY! 👑\n+%d ELO • +%d RYO • +%d SHARDS", delta, ryoReward, shardsReward),
			Color3.fromRGB(255, 215, 0),
			4.5,
			"rbxasset://sounds/bell.wav"
		)
	else
		flashAnnouncer(
			string.format("DEFEAT\n%d ELO • +%d RYO", delta, ryoReward),
			Color3.fromRGB(255, 60, 60),
			4.5,
			"rbxasset://sounds/impact_explosion_03.mp3"
		)
	end

	updateEloCard()
end)

-- Global Toggle
function _G.ToggleDuelHUD()
	queueModal.Visible = not queueModal.Visible
	if queueModal.Visible then
		updateEloCard()
	end
end

-- Hotkey [P]
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.P then
		_G.ToggleDuelHUD()
	end
end)

updateEloCard()
print("[StormDuelHUD] ✅ Loaded — Ranked 1v1 Queue & In-Duel Cinematic Scoreboard initialized.")
