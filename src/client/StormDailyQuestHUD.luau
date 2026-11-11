--!strict
-- StormDailyQuestHUD.luau
-- CLIENT SCRIPT: Modern Shinobi Daily Quests & 7-Day Login Streak Interface
-- Design: Dark Glassmorphism, Gold/Cyan Accent, High-Contrast Anime Typography

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evQuestSync   = combatEvents:WaitForChild("QuestSyncEvent", 15) :: RemoteEvent
local evClaimQuest  = combatEvents:WaitForChild("ClaimQuestRewardEvent", 15) :: RemoteEvent
local evClaimStreak = combatEvents:WaitForChild("ClaimLoginStreakEvent", 15) :: RemoteEvent
local evQuestNotify = combatEvents:WaitForChild("QuestNotificationEvent", 15) :: RemoteEvent

-- State
local isOpen = false
local currentTab = "Quests" -- "Quests" or "Streak"
local playerQuestData: any = nil

-- Safe Audio Player
local function playUiSound(soundId: string, pitch: number?)
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = soundId
			s.PlaybackSpeed = pitch or 1.0
			s.Volume = 0.6
			s.Parent = SoundService
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
		end)
	end)
end

-- =========================================================
-- SCREEN GUI & BACKDROP
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormDailyQuestHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = PlayerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "QuestBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = screenGui

-- Main Container Window
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainModal"
mainFrame.Size = UDim2.new(0.82, 0, 0.82, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = backdrop
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 240, 255)
frameStroke.Thickness = 2
frameStroke.Parent = mainFrame

-- =========================================================
-- HEADER: TITLE & TABS & CLOSE
-- =========================================================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.35, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 24, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "📜 SHINOBI MISSIONS & REWARDS"
titleLabel.Parent = header

-- Tab Switcher: Quests vs Streak
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(0.42, 0, 0, 36)
tabContainer.Position = UDim2.new(0.42, 0, 0.5, 0)
tabContainer.AnchorPoint = Vector2.new(0, 0.5)
tabContainer.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
tabContainer.Parent = header
Instance.new("UICorner", tabContainer).CornerRadius = UDim.new(0, 8)

local btnQuestsTab = Instance.new("TextButton")
btnQuestsTab.Name = "TabQuests"
btnQuestsTab.Size = UDim2.new(0.5, -4, 1, -6)
btnQuestsTab.Position = UDim2.new(0, 3, 0.5, 0)
btnQuestsTab.AnchorPoint = Vector2.new(0, 0.5)
btnQuestsTab.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
btnQuestsTab.Font = Enum.Font.GothamBold
btnQuestsTab.TextSize = 12
btnQuestsTab.TextColor3 = Color3.fromRGB(10, 15, 24)
btnQuestsTab.Text = "⚔️ MISI HARIAN"
btnQuestsTab.Parent = tabContainer
Instance.new("UICorner", btnQuestsTab).CornerRadius = UDim.new(0, 6)

local btnStreakTab = Instance.new("TextButton")
btnStreakTab.Name = "TabStreak"
btnStreakTab.Size = UDim2.new(0.5, -4, 1, -6)
btnStreakTab.Position = UDim2.new(0.5, 1, 0.5, 0)
btnStreakTab.AnchorPoint = Vector2.new(0, 0.5)
btnStreakTab.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
btnStreakTab.Font = Enum.Font.GothamBold
btnStreakTab.TextSize = 12
btnStreakTab.TextColor3 = Color3.fromRGB(180, 190, 210)
btnStreakTab.Text = "📅 LOGIN STREAK"
btnStreakTab.Parent = tabContainer
Instance.new("UICorner", btnStreakTab).CornerRadius = UDim.new(0, 6)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(230, 45, 65)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- BODY CONTAINER: TAB 1 (QUESTS) & TAB 2 (STREAK)
-- =========================================================
local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "BodyFrame"
bodyFrame.Size = UDim2.new(1, -40, 1, -78)
bodyFrame.Position = UDim2.new(0, 20, 0, 68)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

-- TAB 1: QUESTS LIST
local questScroll = Instance.new("ScrollingFrame")
questScroll.Name = "QuestScroll"
questScroll.Size = UDim2.new(1, 0, 1, 0)
questScroll.BackgroundTransparency = 1
questScroll.ScrollBarThickness = 6
questScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
questScroll.CanvasSize = UDim2.new(0, 0, 0, #QuestConfig.DailyQuests * 95)
questScroll.Parent = bodyFrame

local qListLayout = Instance.new("UIListLayout")
qListLayout.Padding = UDim.new(0, 10)
qListLayout.SortOrder = Enum.SortOrder.LayoutOrder
qListLayout.Parent = questScroll

-- TAB 2: 7-DAY STREAK CONTAINER
local streakFrame = Instance.new("Frame")
streakFrame.Name = "StreakFrame"
streakFrame.Size = UDim2.new(1, 0, 1, 0)
streakFrame.BackgroundTransparency = 1
streakFrame.Visible = false
streakFrame.Parent = bodyFrame

local streakSubtitle = Instance.new("TextLabel")
streakSubtitle.Name = "StreakSubtitle"
streakSubtitle.Size = UDim2.new(1, 0, 0, 28)
streakSubtitle.Position = UDim2.new(0, 0, 0, 0)
streakSubtitle.BackgroundTransparency = 1
streakSubtitle.Font = Enum.Font.GothamMedium
streakSubtitle.TextSize = 13
streakSubtitle.TextColor3 = Color3.fromRGB(180, 200, 230)
streakSubtitle.TextXAlignment = Enum.TextXAlignment.Left
streakSubtitle.Text = "🔥 Masuk setiap hari untuk mendapatkan koin Ryo dan Shards. Hari ke-7 memberikan Hadiah Mythic!"
streakSubtitle.Parent = streakFrame

local streakGrid = Instance.new("Frame")
streakGrid.Name = "StreakGrid"
streakGrid.Size = UDim2.new(1, 0, 0, 170)
streakGrid.Position = UDim2.new(0, 0, 0, 36)
streakGrid.BackgroundTransparency = 1
streakGrid.Parent = streakFrame

local sGridLayout = Instance.new("UIGridLayout")
sGridLayout.CellSize = UDim2.new(0.132, 0, 1, 0)
sGridLayout.CellPadding = UDim2.new(0.012, 0, 0, 0)
sGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
sGridLayout.Parent = streakGrid

local claimStreakBtn = Instance.new("TextButton")
claimStreakBtn.Name = "ClaimStreakButton"
claimStreakBtn.Size = UDim2.new(0.4, 0, 0, 44)
claimStreakBtn.Position = UDim2.new(0.5, 0, 1, -54)
claimStreakBtn.AnchorPoint = Vector2.new(0.5, 0)
claimStreakBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
claimStreakBtn.Font = Enum.Font.GothamBlack
claimStreakBtn.TextSize = 14
claimStreakBtn.TextColor3 = Color3.fromRGB(15, 18, 24)
claimStreakBtn.Text = "🎁 KLAIM LOGIN HARI INI"
claimStreakBtn.Parent = streakFrame
Instance.new("UICorner", claimStreakBtn).CornerRadius = UDim.new(0, 10)

local streakBtnStroke = Instance.new("UIStroke")
streakBtnStroke.Color = Color3.fromRGB(255, 255, 255)
streakBtnStroke.Thickness = 2
streakBtnStroke.Parent = claimStreakBtn

-- =========================================================
-- DYNAMIC CARD RENDERING
-- =========================================================
local questCards: { [string]: { Frame: Frame, BarFill: Frame, ProgressLbl: TextLabel, ClaimBtn: TextButton } } = {}
local streakCards: { [number]: Frame } = {}

local function renderQuestCards()
	-- Clear existing
	for _, child in ipairs(questScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	questCards = {}

	for idx, qDef in ipairs(QuestConfig.DailyQuests) do
		local card = Instance.new("Frame")
		card.Name = "QuestCard_" .. qDef.Id
		card.Size = UDim2.new(1, -8, 0, 84)
		card.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
		card.BackgroundTransparency = 0.2
		card.LayoutOrder = idx
		card.Parent = questScroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(45, 55, 75)
		cardStroke.Thickness = 1.5
		cardStroke.Parent = card

		-- Icon Box
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(0, 54, 0, 54)
		iconLbl.Position = UDim2.new(0, 14, 0.5, 0)
		iconLbl.AnchorPoint = Vector2.new(0, 0.5)
		iconLbl.BackgroundColor3 = Color3.fromRGB(28, 35, 50)
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.TextSize = 28
		iconLbl.Text = qDef.Icon
		iconLbl.Parent = card
		Instance.new("UICorner", iconLbl).CornerRadius = UDim.new(0, 8)

		-- Info: Title & Description
		local qTitle = Instance.new("TextLabel")
		qTitle.Size = UDim2.new(0.55, 0, 0, 20)
		qTitle.Position = UDim2.new(0, 80, 0, 14)
		qTitle.BackgroundTransparency = 1
		qTitle.Font = Enum.Font.GothamBlack
		qTitle.TextSize = 14
		qTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Text = qDef.Title
		qTitle.Parent = card

		local qDesc = Instance.new("TextLabel")
		qDesc.Size = UDim2.new(0.55, 0, 0, 16)
		qDesc.Position = UDim2.new(0, 80, 0, 36)
		qDesc.BackgroundTransparency = 1
		qDesc.Font = Enum.Font.GothamMedium
		qDesc.TextSize = 11
		qDesc.TextColor3 = Color3.fromRGB(160, 175, 200)
		qDesc.TextXAlignment = Enum.TextXAlignment.Left
		qDesc.Text = qDef.Description
		qDesc.Parent = card

		-- Progress Bar Container
		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(0.55, 0, 0, 8)
		barBg.Position = UDim2.new(0, 80, 0, 58)
		barBg.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
		barBg.Parent = card
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(0, 0, 1, 0)
		barFill.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
		barFill.BorderSizePixel = 0
		barFill.Parent = barBg
		Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

		local progressLbl = Instance.new("TextLabel")
		progressLbl.Size = UDim2.new(0, 90, 0, 16)
		progressLbl.Position = UDim2.new(0.55, 90, 0, 54)
		progressLbl.BackgroundTransparency = 1
		progressLbl.Font = Enum.Font.GothamBold
		progressLbl.TextSize = 10
		progressLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
		progressLbl.TextXAlignment = Enum.TextXAlignment.Left
		progressLbl.Text = "0 / " .. tostring(qDef.TargetGoal)
		progressLbl.Parent = card

		-- Reward Badge & Claim Button
		local rewardLbl = Instance.new("TextLabel")
		rewardLbl.Size = UDim2.new(0, 110, 0, 20)
		rewardLbl.Position = UDim2.new(1, -260, 0.5, 0)
		rewardLbl.AnchorPoint = Vector2.new(0, 0.5)
		rewardLbl.BackgroundTransparency = 1
		rewardLbl.Font = Enum.Font.GothamBold
		rewardLbl.TextSize = 12
		rewardLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
		rewardLbl.TextXAlignment = Enum.TextXAlignment.Right
		rewardLbl.Text = string.format("+%d 🪙 | +%d 💎", qDef.RyoReward, qDef.ShardsReward)
		rewardLbl.Parent = card

		local claimBtn = Instance.new("TextButton")
		claimBtn.Name = "ClaimButton"
		claimBtn.Size = UDim2.new(0, 120, 0, 38)
		claimBtn.Position = UDim2.new(1, -135, 0.5, 0)
		claimBtn.AnchorPoint = Vector2.new(0, 0.5)
		claimBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.TextSize = 12
		claimBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
		claimBtn.Text = "BELUM SELESAI"
		claimBtn.AutoButtonColor = false
		claimBtn.Parent = card
		Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)

		claimBtn.MouseButton1Click:Connect(function()
			playUiSound(QuestConfig.Sounds.TabClick, 1.2)
			evClaimQuest:FireServer(qDef.Id)
		end)

		questCards[qDef.Id] = {
			Frame = card,
			BarFill = barFill,
			ProgressLbl = progressLbl,
			ClaimBtn = claimBtn,
		}
	end
end

local function renderStreakCards()
	for _, child in ipairs(streakGrid:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	streakCards = {}

	for dayIdx = 1, 7 do
		local streakDef = QuestConfig.LoginStreakDays[dayIdx]
		local isDay7 = (dayIdx == 7)

		local card = Instance.new("Frame")
		card.Name = "StreakCard_" .. tostring(dayIdx)
		card.BackgroundColor3 = if isDay7 then Color3.fromRGB(38, 22, 35) else Color3.fromRGB(20, 26, 38)
		card.LayoutOrder = dayIdx
		card.Parent = streakGrid
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = if isDay7 then Color3.fromRGB(255, 60, 100) else Color3.fromRGB(45, 55, 75)
		cStroke.Thickness = 1.5
		cStroke.Parent = card

		local dLabel = Instance.new("TextLabel")
		dLabel.Size = UDim2.new(1, 0, 0, 22)
		dLabel.Position = UDim2.new(0, 0, 0, 8)
		dLabel.BackgroundTransparency = 1
		dLabel.Font = Enum.Font.GothamBlack
		dLabel.TextSize = 12
		dLabel.TextColor3 = if isDay7 then Color3.fromRGB(255, 80, 120) else Color3.fromRGB(200, 215, 240)
		dLabel.Text = "HARI " .. tostring(dayIdx)
		dLabel.Parent = card

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 0, 52)
		iconLbl.Position = UDim2.new(0, 0, 0, 32)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.TextSize = if isDay7 then 38 else 30
		iconLbl.Text = streakDef.Icon
		iconLbl.Parent = card

		local ryoLbl = Instance.new("TextLabel")
		ryoLbl.Size = UDim2.new(1, 0, 0, 20)
		ryoLbl.Position = UDim2.new(0, 0, 1, -44)
		ryoLbl.BackgroundTransparency = 1
		ryoLbl.Font = Enum.Font.GothamBlack
		ryoLbl.TextSize = 13
		ryoLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
		ryoLbl.Text = "+" .. tostring(streakDef.Ryo) .. " 🪙"
		ryoLbl.Parent = card

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Name = "StatusLabel"
		statusLbl.Size = UDim2.new(1, 0, 0, 16)
		statusLbl.Position = UDim2.new(0, 0, 1, -22)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Font = Enum.Font.GothamBold
		statusLbl.TextSize = 10
		statusLbl.TextColor3 = Color3.fromRGB(140, 155, 175)
		statusLbl.Text = "TERKUNCI"
		statusLbl.Parent = card

		streakCards[dayIdx] = card
	end
end

-- =========================================================
-- UPDATE DISPLAY FROM SERVER DATA
-- =========================================================
local function updateFromData(data: any)
	playerQuestData = data
	if not data then return end

	-- Update Quests
	if data.Quests then
		for _, qDef in ipairs(QuestConfig.DailyQuests) do
			local uiCard = questCards[qDef.Id]
			local qState = data.Quests[qDef.Id]
			if uiCard and qState then
				local cur = qState.Current or 0
				local goal = qDef.TargetGoal
				local pct = math.clamp(cur / goal, 0, 1)

				uiCard.ProgressLbl.Text = string.format("%d / %d", cur, goal)
				TweenService:Create(uiCard.BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(pct, 0, 1, 0)
				}):Play()

				if qState.Claimed then
					uiCard.ClaimBtn.BackgroundColor3 = Color3.fromRGB(25, 32, 45)
					uiCard.ClaimBtn.TextColor3 = Color3.fromRGB(110, 125, 145)
					uiCard.ClaimBtn.Text = "✅ SUDAH DIKLAIM"
					uiCard.ClaimBtn.Active = false
				elseif cur >= goal then
					uiCard.ClaimBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
					uiCard.ClaimBtn.TextColor3 = Color3.fromRGB(10, 15, 24)
					uiCard.ClaimBtn.Text = "🎁 KLAIM HADIAH!"
					uiCard.ClaimBtn.Active = true
				else
					uiCard.ClaimBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
					uiCard.ClaimBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
					uiCard.ClaimBtn.Text = "PROGRESS..."
					uiCard.ClaimBtn.Active = false
				end
			end
		end
	end

	-- Update Streak
	local curDay = data.StreakDay or 1
	for dayIdx, card in pairs(streakCards) do
		local statusLbl = card:FindFirstChild("StatusLabel") :: TextLabel?
		local stroke = card:FindFirstChildOfClass("UIStroke")

		if dayIdx < curDay then
			-- Already claimed in past days
			if statusLbl then
				statusLbl.Text = "✅ SELESAI"
				statusLbl.TextColor3 = Color3.fromRGB(0, 255, 160)
			end
			card.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
		elseif dayIdx == curDay then
			-- Current day
			if statusLbl then
				statusLbl.Text = "🌟 HARI INI"
				statusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
			card.BackgroundColor3 = Color3.fromRGB(30, 42, 64)
			if stroke then stroke.Color = Color3.fromRGB(255, 215, 0) end
		else
			-- Future locked
			if statusLbl then
				statusLbl.Text = "🔒 TERKUNCI"
				statusLbl.TextColor3 = Color3.fromRGB(120, 135, 155)
			end
		end
	end
end

-- =========================================================
-- TAB SWITCHING & MODAL CONTROLS
-- =========================================================
local function switchTab(tab: string)
	currentTab = tab
	playUiSound(QuestConfig.Sounds.TabClick, 1.1)

	if tab == "Quests" then
		btnQuestsTab.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
		btnQuestsTab.TextColor3 = Color3.fromRGB(10, 15, 24)
		btnStreakTab.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
		btnStreakTab.TextColor3 = Color3.fromRGB(180, 190, 210)
		questScroll.Visible = true
		streakFrame.Visible = false
	else
		btnStreakTab.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
		btnStreakTab.TextColor3 = Color3.fromRGB(10, 15, 24)
		btnQuestsTab.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
		btnQuestsTab.TextColor3 = Color3.fromRGB(180, 190, 210)
		questScroll.Visible = false
		streakFrame.Visible = true
	end
end

btnQuestsTab.MouseButton1Click:Connect(function() switchTab("Quests") end)
btnStreakTab.MouseButton1Click:Connect(function() switchTab("Streak") end)

local function toggleQuestModal(state: boolean?)
	isOpen = if state ~= nil then state else not isOpen
	screenGui.Enabled = isOpen
	playUiSound(QuestConfig.Sounds.TabClick, if isOpen then 1.0 else 0.8)

	if isOpen then
		evQuestSync:FireServer()
	end
end

closeBtn.MouseButton1Click:Connect(function() toggleQuestModal(false) end)
claimStreakBtn.MouseButton1Click:Connect(function()
	playUiSound(QuestConfig.Sounds.ClaimReward, 1.0)
	evClaimStreak:FireServer()
end)

-- Keyboard [M] Key (Missions)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		toggleQuestModal()
	end
end)

-- Remote Event Listeners
evQuestSync.OnClientEvent:Connect(function(data)
	updateFromData(data)
end)

evClaimQuest.OnClientEvent:Connect(function(res)
	if res.Success then
		playUiSound(QuestConfig.Sounds.QuestComplete, 1.0)
	end
end)

evClaimStreak.OnClientEvent:Connect(function(res)
	if res.Success then
		playUiSound(QuestConfig.Sounds.ClaimReward, 1.1)
	end
end)

-- Initialize UI layout
renderQuestCards()
renderStreakCards()

-- Expose global toggle for Topbar HUD integration
_G.ToggleQuestHUD = function()
	toggleQuestModal()
end

print("[StormDailyQuestHUD] ✅ Handcrafted Daily Quests & 7-Day Login Streak loaded. Hotkey [M] active.")

