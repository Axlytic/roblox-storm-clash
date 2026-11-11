--!strict
-- StormGachaHUD.luau
-- CLIENT SCRIPT: Cinematic Shinobi Gacha Summon Interface & Dramatic Reveal Stage
-- Features:
--   • 1x Summon (100 Ryo) & 10x Multi-Summon (900 Ryo)
--   • Dynamic Pity Progress Bar (0/50 Guarantee)
--   • Daily Login Reward Claim (+250 Ryo)
--   • Dramatic Anime Summon Reveal Cutscene:
--       - Pulsing Summoning Orb & Screen Shake
--       - Tier-dependent flash colors (Cyan -> Purple -> Gold -> Crimson/Rainbow)
--       - Splash Card presentation with Stars, Title, Archetype, Quote, and New/Duplicate status
--   • Grid layout for 10x Multi-Summon results with skip support
--   • Full Mobile Touch, Keyboard ([G] Key), and 3D Lobby Altar Integration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Force Landscape on Mobile
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evGachaPull    = combatEvents:WaitForChild("GachaPullEvent", 15) :: RemoteEvent
local evGachaSync    = combatEvents:WaitForChild("GachaSyncEvent", 15) :: RemoteEvent
local evClaimDaily   = combatEvents:WaitForChild("ClaimDailyRewardEvent", 15) :: RemoteEvent
local evOpenGacha    = combatEvents:WaitForChild("OpenGachaEvent", 15) :: RemoteEvent

-- State
local isOpen = false
local isSummoning = false
local currentRyo = 300
local currentPity = 0
local currentShards = 0
local unlockedMap: { [string]: boolean } = {}

-- Sound Helper
local function playSound(soundId: string, pitch: number, vol: number?)
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = soundId
			s.PlaybackSpeed = pitch or 1.0
			s.Volume = vol or 0.8
			s.Parent = SoundService
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
		end)
	end)
end

-- =========================================================
-- CREATE GUI INSTANCES
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormGachaHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Dark Vignette Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "GachaBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
backdrop.BackgroundTransparency = 0.25
backdrop.Parent = screenGui

-- Main Gacha Modal Window (Landscape 88% x 86%)
local mainModal = Instance.new("Frame")
mainModal.Name = "MainModal"
mainModal.Size = UDim2.new(0.88, 0, 0.86, 0)
mainModal.Position = UDim2.new(0.5, 0, 0.5, 0)
mainModal.AnchorPoint = Vector2.new(0.5, 0.5)
mainModal.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
mainModal.BorderSizePixel = 0
mainModal.Parent = backdrop
Instance.new("UICorner", mainModal).CornerRadius = UDim.new(0, 14)

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(255, 215, 0)
modalStroke.Thickness = 2
modalStroke.Parent = mainModal

-- =========================================================
-- HEADER: CURRENCY & PITY BAR
-- =========================================================
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 56)
headerFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
headerFrame.BackgroundTransparency = 0.2
headerFrame.Parent = mainModal
Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.35, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "⛩️ SHINOBI SUMMON // GACHA BANNER"
titleLabel.Parent = headerFrame

-- Ryo Display
local ryoBadge = Instance.new("Frame")
ryoBadge.Size = UDim2.new(0, 150, 0, 36)
ryoBadge.Position = UDim2.new(0.42, 0, 0.5, 0)
ryoBadge.AnchorPoint = Vector2.new(0, 0.5)
ryoBadge.BackgroundColor3 = Color3.fromRGB(25, 30, 48)
ryoBadge.Parent = headerFrame
Instance.new("UICorner", ryoBadge).CornerRadius = UDim.new(0, 8)

local ryoLbl = Instance.new("TextLabel")
ryoLbl.Size = UDim2.fromScale(1, 1)
ryoLbl.BackgroundTransparency = 1
ryoLbl.Font = Enum.Font.GothamBold
ryoLbl.TextSize = 15
ryoLbl.TextColor3 = Color3.fromRGB(255, 225, 50)
ryoLbl.Text = "🪙 300 Ryo"
ryoLbl.Parent = ryoBadge

-- Shards Display
local shardBadge = Instance.new("Frame")
shardBadge.Size = UDim2.new(0, 140, 0, 36)
shardBadge.Position = UDim2.new(0.58, 0, 0.5, 0)
shardBadge.AnchorPoint = Vector2.new(0, 0.5)
shardBadge.BackgroundColor3 = Color3.fromRGB(25, 30, 48)
shardBadge.Parent = headerFrame
Instance.new("UICorner", shardBadge).CornerRadius = UDim.new(0, 8)

local shardLbl = Instance.new("TextLabel")
shardLbl.Size = UDim2.fromScale(1, 1)
shardLbl.BackgroundTransparency = 1
shardLbl.Font = Enum.Font.GothamBold
shardLbl.TextSize = 14
shardLbl.TextColor3 = Color3.fromRGB(80, 230, 255)
shardLbl.Text = "💎 0 Shards"
shardLbl.Parent = shardBadge

-- Close Button [✕]
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- BANNER STAGE: FEATURED LEGENDS & PITY COUNTER
-- =========================================================
local bannerStage = Instance.new("Frame")
bannerStage.Name = "BannerStage"
bannerStage.Size = UDim2.new(1, -40, 0.65, 0)
bannerStage.Position = UDim2.new(0, 20, 0, 68)
bannerStage.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
bannerStage.Parent = mainModal
Instance.new("UICorner", bannerStage).CornerRadius = UDim.new(0, 10)

local bannerGradient = Instance.new("UIGradient")
bannerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 25, 55)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 25, 45)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 35)),
})
bannerGradient.Rotation = 45
bannerGradient.Parent = bannerStage

-- Featured Characters Showcase Title
local featHeader = Instance.new("TextLabel")
featHeader.Size = UDim2.new(1, 0, 0, 30)
featHeader.Position = UDim2.new(0, 0, 0, 10)
featHeader.BackgroundTransparency = 1
featHeader.Font = Enum.Font.GothamBlack
featHeader.TextSize = 16
featHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
featHeader.Text = "★ FEATURED MYTHIC & LEGENDARY SUMMONS ★"
featHeader.Parent = bannerStage

-- Showcase Display of Featured Roster
local featuredChars = {
	{ Id = "Madara",  Tier = "Mythic",    Stars = "★★★★★★", Color = Color3.fromRGB(255, 40, 80) },
	{ Id = "Sukuna",  Tier = "Mythic",    Stars = "★★★★★★", Color = Color3.fromRGB(255, 40, 80) },
	{ Id = "Gojo",    Tier = "Legendary", Stars = "★★★★★",  Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "Aizen",   Tier = "Legendary", Stars = "★★★★★",  Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "Sasuke",  Tier = "Legendary", Stars = "★★★★★",  Color = Color3.fromRGB(255, 215, 0) },
}

local cardsRow = Instance.new("Frame")
cardsRow.Size = UDim2.new(1, -30, 0, 140)
cardsRow.Position = UDim2.new(0, 15, 0, 45)
cardsRow.BackgroundTransparency = 1
cardsRow.Parent = bannerStage

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.Padding = UDim.new(0, 12)
rowLayout.Parent = cardsRow

for _, feat in ipairs(featuredChars) do
	local char = CombatConfig.Characters[feat.Id]
	if not char then continue end

	local fCard = Instance.new("Frame")
	fCard.Size = UDim2.new(0, 130, 1, 0)
	fCard.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
	fCard.Parent = cardsRow
	Instance.new("UICorner", fCard).CornerRadius = UDim.new(0, 8)

	local fStroke = Instance.new("UIStroke")
	fStroke.Color = feat.Color
	fStroke.Thickness = 1.5
	fStroke.Parent = fCard

	local fIcon = Instance.new("TextLabel")
	fIcon.Size = UDim2.new(1, 0, 0, 45)
	fIcon.Position = UDim2.new(0, 0, 0, 8)
	fIcon.BackgroundTransparency = 1
	fIcon.Font = Enum.Font.GothamBold
	fIcon.TextSize = 34
	fIcon.Text = char.Icon
	fIcon.Parent = fCard

	local fName = Instance.new("TextLabel")
	fName.Size = UDim2.new(1, -6, 0, 18)
	fName.Position = UDim2.new(0, 3, 0, 56)
	fName.BackgroundTransparency = 1
	fName.Font = Enum.Font.GothamBlack
	fName.TextSize = 12
	fName.TextColor3 = Color3.fromRGB(255, 255, 255)
	fName.TextScaled = true
	fName.Text = char.Name
	fName.Parent = fCard

	local fStars = Instance.new("TextLabel")
	fStars.Size = UDim2.new(1, 0, 0, 14)
	fStars.Position = UDim2.new(0, 0, 0, 78)
	fStars.BackgroundTransparency = 1
	fStars.Font = Enum.Font.GothamBold
	fStars.TextSize = 11
	fStars.TextColor3 = feat.Color
	fStars.Text = feat.Stars
	fStars.Parent = fCard

	local fTier = Instance.new("TextLabel")
	fTier.Size = UDim2.new(0.8, 0, 0, 18)
	fTier.Position = UDim2.new(0.1, 0, 0, 104)
	fTier.BackgroundColor3 = feat.Color
	fTier.BackgroundTransparency = 0.3
	fTier.Font = Enum.Font.GothamBlack
	fTier.TextSize = 9
	fTier.TextColor3 = Color3.fromRGB(255, 255, 255)
	fTier.Text = string.upper(feat.Tier)
	fTier.Parent = fCard
	Instance.new("UICorner", fTier).CornerRadius = UDim.new(0, 4)
end

-- Pity Progress Bar at bottom of stage
local pityFrame = Instance.new("Frame")
pityFrame.Size = UDim2.new(1, -40, 0, 24)
pityFrame.Position = UDim2.new(0, 20, 1, -34)
pityFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
pityFrame.Parent = bannerStage
Instance.new("UICorner", pityFrame).CornerRadius = UDim.new(0, 6)

local pityFill = Instance.new("Frame")
pityFill.Size = UDim2.new(0, 0, 1, 0)
pityFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
pityFill.BorderSizePixel = 0
pityFill.Parent = pityFrame
Instance.new("UICorner", pityFill).CornerRadius = UDim.new(0, 6)

local pityLbl = Instance.new("TextLabel")
pityLbl.Size = UDim2.fromScale(1, 1)
pityLbl.BackgroundTransparency = 1
pityLbl.Font = Enum.Font.GothamBlack
pityLbl.TextSize = 11
pityLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
pityLbl.Text = "PITY GARANSI: 0 / 50 PULLS (DIJAMIN ★5/★6 PADA 50)"
pityLbl.Parent = pityFrame

-- =========================================================
-- BOTTOM ACTION BUTTONS
-- =========================================================
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(1, -40, 0, 52)
bottomBar.Position = UDim2.new(0, 20, 1, -66)
bottomBar.BackgroundTransparency = 1
bottomBar.Parent = mainModal

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Padding = UDim.new(0, 16)
btnLayout.Parent = bottomBar

-- Daily Reward Button
local dailyBtn = Instance.new("TextButton")
dailyBtn.Size = UDim2.new(0, 180, 1, 0)
dailyBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
dailyBtn.Font = Enum.Font.GothamBlack
dailyBtn.TextSize = 12
dailyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dailyBtn.Text = "🎁 KLAIM HARIAN\n(+250 Ryo)"
dailyBtn.Parent = bottomBar
Instance.new("UICorner", dailyBtn).CornerRadius = UDim.new(0, 8)

-- 1x Summon Button
local pull1Btn = Instance.new("TextButton")
pull1Btn.Size = UDim2.new(0, 220, 1, 0)
pull1Btn.BackgroundColor3 = Color3.fromRGB(0, 160, 240)
pull1Btn.Font = Enum.Font.GothamBlack
pull1Btn.TextSize = 14
pull1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
pull1Btn.Text = "⛩️ 1x SUMMON\n(100 🪙 Ryo)"
pull1Btn.Parent = bottomBar
Instance.new("UICorner", pull1Btn).CornerRadius = UDim.new(0, 8)

local p1Stroke = Instance.new("UIStroke")
p1Stroke.Color = Color3.fromRGB(255, 255, 255)
p1Stroke.Thickness = 1.5
p1Stroke.Parent = pull1Btn

-- 10x Multi-Summon Button
local pull10Btn = Instance.new("TextButton")
pull10Btn.Size = UDim2.new(0, 260, 1, 0)
pull10Btn.BackgroundColor3 = Color3.fromRGB(230, 140, 20)
pull10Btn.Font = Enum.Font.GothamBlack
pull10Btn.TextSize = 14
pull10Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
pull10Btn.Text = "🔥 10x MULTI-SUMMON\n(900 🪙 Ryo • DISKON 10%)"
pull10Btn.Parent = bottomBar
Instance.new("UICorner", pull10Btn).CornerRadius = UDim.new(0, 8)

local p10Stroke = Instance.new("UIStroke")
p10Stroke.Color = Color3.fromRGB(255, 215, 0)
p10Stroke.Thickness = 2
p10Stroke.Parent = pull10Btn

-- =========================================================
-- CINEMATIC SUMMON REVEAL STAGE
-- =========================================================
local revealOverlay = Instance.new("Frame")
revealOverlay.Name = "RevealOverlay"
revealOverlay.Size = UDim2.new(1, 0, 1, 0)
revealOverlay.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
revealOverlay.BackgroundTransparency = 0.05
revealOverlay.Visible = false
revealOverlay.ZIndex = 50
revealOverlay.Parent = screenGui

-- Center Flash Orb
local summonOrb = Instance.new("Frame")
summonOrb.Name = "SummonOrb"
summonOrb.Size = UDim2.new(0, 140, 0, 140)
summonOrb.Position = UDim2.new(0.5, 0, 0.45, 0)
summonOrb.AnchorPoint = Vector2.new(0.5, 0.5)
summonOrb.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
summonOrb.ZIndex = 52
summonOrb.Parent = revealOverlay
Instance.new("UICorner", summonOrb).CornerRadius = UDim.new(1, 0)

-- Result Card Container
local resultContainer = Instance.new("Frame")
resultContainer.Name = "ResultContainer"
resultContainer.Size = UDim2.new(0.9, 0, 0.85, 0)
resultContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
resultContainer.AnchorPoint = Vector2.new(0.5, 0.5)
resultContainer.BackgroundTransparency = 1
resultContainer.ZIndex = 55
resultContainer.Visible = false
resultContainer.Parent = revealOverlay

-- Dismiss Button
local continueBtn = Instance.new("TextButton")
continueBtn.Size = UDim2.new(0, 240, 0, 48)
continueBtn.Position = UDim2.new(0.5, 0, 1, -40)
continueBtn.AnchorPoint = Vector2.new(0.5, 1)
continueBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
continueBtn.Font = Enum.Font.GothamBlack
continueBtn.TextSize = 16
continueBtn.TextColor3 = Color3.fromRGB(15, 18, 25)
continueBtn.Text = "✓ AMBIL SEMUA HADIAH"
continueBtn.ZIndex = 60
continueBtn.Visible = false
continueBtn.Parent = revealOverlay
Instance.new("UICorner", continueBtn).CornerRadius = UDim.new(0, 10)

-- =========================================================
-- UPDATE STATE HELPERS
-- =========================================================
local function updateGachaState(data: any)
	if not data then return end
	currentRyo = data.Ryo or currentRyo
	currentPity = data.Pity or currentPity
	currentShards = data.EssenceShards or currentShards
	unlockedMap = data.Unlocked or unlockedMap

	ryoLbl.Text = string.format("🪙 %d Ryo", currentRyo)
	shardLbl.Text = string.format("💎 %d Shards", currentShards)

	local ratio = math.clamp(currentPity / GachaConfig.Pity.HardPityThreshold, 0, 1)
	pityFill.Size = UDim2.new(ratio, 0, 1, 0)
	pityLbl.Text = string.format("PITY GARANSI: %d / %d PULLS (DIJAMIN ★5/★6 PADA %d)", currentPity, GachaConfig.Pity.HardPityThreshold, GachaConfig.Pity.HardPityThreshold)
end

-- =========================================================
-- PLAY DRAMATIC REVEAL SEQUENCE
-- =========================================================
local function playSummonCutscene(results: { any }, isMulti: boolean)
	isSummoning = true
	revealOverlay.Visible = true
	resultContainer.Visible = false
	continueBtn.Visible = false
	summonOrb.Visible = true
	summonOrb.Size = UDim2.new(0, 20, 0, 20)

	-- Find highest tier for orb peak color
	local highestTier = "Rare"
	for _, res in ipairs(results) do
		local t = res.Tier
		if t == "Mythic" then highestTier = "Mythic" break end
		if t == "Legendary" and highestTier ~= "Mythic" then highestTier = "Legendary" end
		if t == "Epic" and highestTier == "Rare" then highestTier = "Epic" end
	end

	local tierConfig = GachaConfig.Tiers[highestTier] or GachaConfig.Tiers.Rare
	summonOrb.BackgroundColor3 = tierConfig.Color

	playSound("rbxasset://sounds/electronicpingshort.wav", 1.2, 0.8)

	-- Orb Pulse Expansion Animation
	local expandTween = TweenService:Create(summonOrb, TweenInfo.new(1.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 280, 0, 280),
		BackgroundTransparency = 0.1,
	})
	expandTween:Play()

	task.wait(1.2)

	-- Screen Flash
	playSound("rbxasset://sounds/impact_explosion_03.mp3", tierConfig.SoundPitch or 1.0, 1.0)
	summonOrb.Visible = false

	-- Clear old result cards
	for _, child in ipairs(resultContainer:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	resultContainer.Visible = true

	if not isMulti and #results == 1 then
		-- SINGLE SUMMON: Big Cinematic Hero Card
		local res = results[1]
		local char = CombatConfig.Characters[res.Id]
		local tData = GachaConfig.Tiers[res.Tier] or GachaConfig.Tiers.Rare

		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 360, 0, 420)
		card.Position = UDim2.new(0.5, 0, 0.45, 0)
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
		card.Parent = resultContainer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = tData.Color
		cStroke.Thickness = 3
		cStroke.Parent = card

		-- Stars Header
		local sLbl = Instance.new("TextLabel")
		sLbl.Size = UDim2.new(1, 0, 0, 30)
		sLbl.Position = UDim2.new(0, 0, 0, 14)
		sLbl.BackgroundTransparency = 1
		sLbl.Font = Enum.Font.GothamBlack
		sLbl.TextSize = 22
		sLbl.TextColor3 = tData.Color
		sLbl.Text = tData.Stars .. " " .. string.upper(tData.Name)
		sLbl.Parent = card

		-- Big Icon
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 0, 90)
		iconLbl.Position = UDim2.new(0, 0, 0, 48)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.TextSize = 72
		iconLbl.Text = char and char.Icon or "⚡"
		iconLbl.Parent = card

		-- Name
		local nLbl = Instance.new("TextLabel")
		nLbl.Size = UDim2.new(1, -20, 0, 32)
		nLbl.Position = UDim2.new(0, 10, 0, 145)
		nLbl.BackgroundTransparency = 1
		nLbl.Font = Enum.Font.GothamBlack
		nLbl.TextSize = 22
		nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nLbl.Text = char and string.upper(char.Name) or res.Id
		nLbl.Parent = card

		-- Anime Title & Archetype
		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, 0, 0, 20)
		subLbl.Position = UDim2.new(0, 0, 0, 180)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = Enum.Font.GothamBold
		subLbl.TextSize = 13
		subLbl.TextColor3 = tData.Color
		subLbl.Text = (char and char.Anime or "Anime") .. " • " .. (char and string.upper(char.Archetype) or "FIGHTER")
		subLbl.Parent = card

		-- Status Badge (NEW! or DUPLICATE)
		local statusBadge = Instance.new("TextLabel")
		statusBadge.Size = UDim2.new(0.8, 0, 0, 32)
		statusBadge.Position = UDim2.new(0.1, 0, 0, 215)
		statusBadge.Font = Enum.Font.GothamBlack
		statusBadge.TextSize = 13
		if res.IsNew then
			statusBadge.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
			statusBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
			statusBadge.Text = "✨ KARAKTER BARU TERBUKA (UNLOCKED!)"
		else
			statusBadge.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
			statusBadge.TextColor3 = Color3.fromRGB(255, 240, 150)
			statusBadge.Text = string.format("DUPLIKAT -> +%d ESSENCE SHARDS", res.Shards or 10)
		end
		statusBadge.Parent = card
		Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 8)

		-- Quote
		local qLbl = Instance.new("TextLabel")
		qLbl.Size = UDim2.new(1, -30, 0, 60)
		qLbl.Position = UDim2.new(0, 15, 0, 260)
		qLbl.BackgroundTransparency = 1
		qLbl.Font = Enum.Font.GothamMedium
		qLbl.TextSize = 12
		qLbl.TextColor3 = Color3.fromRGB(200, 210, 225)
		qLbl.TextWrapped = true
		qLbl.Text = char and ('"' .. char.Quote .. '"') or ""
		qLbl.Parent = card
	else
		-- MULTI-SUMMON: 2x5 Grid of 10 Cards
		local grid = Instance.new("Frame")
		grid.Size = UDim2.new(1, 0, 0.85, 0)
		grid.Position = UDim2.new(0, 0, 0, 10)
		grid.BackgroundTransparency = 1
		grid.Parent = resultContainer

		local uigrid = Instance.new("UIGridLayout")
		uigrid.CellSize = UDim2.new(0.18, 0, 0.46, 0)
		uigrid.CellPadding = UDim2.new(0.02, 0, 0.04, 0)
		uigrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uigrid.Parent = grid

		for _, res in ipairs(results) do
			local char = CombatConfig.Characters[res.Id]
			local tData = GachaConfig.Tiers[res.Tier] or GachaConfig.Tiers.Rare

			local mCard = Instance.new("Frame")
			mCard.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
			mCard.Parent = grid
			Instance.new("UICorner", mCard).CornerRadius = UDim.new(0, 10)

			local mStroke = Instance.new("UIStroke")
			mStroke.Color = tData.Color
			mStroke.Thickness = 2
			mStroke.Parent = mCard

			local mIcon = Instance.new("TextLabel")
			mIcon.Size = UDim2.new(1, 0, 0, 48)
			mIcon.Position = UDim2.new(0, 0, 0, 8)
			mIcon.BackgroundTransparency = 1
			mIcon.Font = Enum.Font.GothamBold
			mIcon.TextSize = 36
			mIcon.Text = char and char.Icon or "⚡"
			mIcon.Parent = mCard

			local mName = Instance.new("TextLabel")
			mName.Size = UDim2.new(1, -6, 0, 18)
			mName.Position = UDim2.new(0, 3, 0, 58)
			mName.BackgroundTransparency = 1
			mName.Font = Enum.Font.GothamBlack
			mName.TextSize = 11
			mName.TextColor3 = Color3.fromRGB(255, 255, 255)
			mName.TextScaled = true
			mName.Text = char and char.Name or res.Id
			mName.Parent = mCard

			local mStars = Instance.new("TextLabel")
			mStars.Size = UDim2.new(1, 0, 0, 14)
			mStars.Position = UDim2.new(0, 0, 0, 78)
			mStars.BackgroundTransparency = 1
			mStars.Font = Enum.Font.GothamBold
			mStars.TextSize = 9
			mStars.TextColor3 = tData.Color
			mStars.Text = tData.Stars
			mStars.Parent = mCard

			local mStatus = Instance.new("TextLabel")
			mStatus.Size = UDim2.new(0.88, 0, 0, 18)
			mStatus.Position = UDim2.new(0.06, 0, 1, -26)
			mStatus.Font = Enum.Font.GothamBlack
			mStatus.TextSize = 8
			if res.IsNew then
				mStatus.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
				mStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
				mStatus.Text = "BARU!"
			else
				mStatus.BackgroundColor3 = Color3.fromRGB(80, 50, 120)
				mStatus.TextColor3 = Color3.fromRGB(200, 220, 255)
				mStatus.Text = "+" .. tostring(res.Shards or 10) .. "💎"
			end
			mStatus.Parent = mCard
			Instance.new("UICorner", mStatus).CornerRadius = UDim.new(0, 4)
		end
	end

	continueBtn.Visible = true
	isSummoning = false
end

-- =========================================================
-- EVENT LISTENERS
-- =========================================================
pull1Btn.MouseButton1Click:Connect(function()
	if isSummoning then return end
	if currentRyo < GachaConfig.SinglePullCost then
		playSound("rbxasset://sounds/action_footsteps_plastic.mp3", 0.6)
		return
	end
	evGachaPull:FireServer("Single")
end)

pull10Btn.MouseButton1Click:Connect(function()
	if isSummoning then return end
	if currentRyo < GachaConfig.MultiPullCost then
		playSound("rbxasset://sounds/action_footsteps_plastic.mp3", 0.6)
		return
	end
	evGachaPull:FireServer("Multi")
end)

dailyBtn.MouseButton1Click:Connect(function()
	evClaimDaily:FireServer()
end)

continueBtn.MouseButton1Click:Connect(function()
	revealOverlay.Visible = false
	resultContainer.Visible = false
	continueBtn.Visible = false
	playSound("rbxasset://sounds/action_jump.mp3", 1.4)
end)

closeBtn.MouseButton1Click:Connect(function()
	if isSummoning then return end
	screenGui.Enabled = false
	isOpen = false
end)

-- Receive Gacha Pull Results
evGachaPull.OnClientEvent:Connect(function(data: any)
	if data and data.Success then
		updateGachaState({
			Ryo = data.NewRyo,
			Pity = data.Pity,
			EssenceShards = data.Shards,
		})
		playSummonCutscene(data.Results, data.IsMulti)
	else
		-- Error message
		if data and data.Message then
			print(">> [StormGacha] Error: " .. data.Message)
		end
	end
end)

-- Receive Full Data Sync
evGachaSync.OnClientEvent:Connect(function(prof: any)
	updateGachaState(prof)
end)

-- Receive Daily Reward confirmation
evClaimDaily.OnClientEvent:Connect(function(data: any)
	if data and data.Success then
		playSound("rbxasset://sounds/electronicpingshort.wav", 1.5)
		dailyBtn.Text = "✓ HARIAN DIAMBIL!"
		dailyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	end
end)

-- Receive Open Request (e.g. from Altar ProximityPrompt or Hotkey)
local function openGachaModal()
	screenGui.Enabled = true
	isOpen = true
	evGachaSync:FireServer()
end

evOpenGacha.OnClientEvent:Connect(function()
	openGachaModal()
end)

-- Keyboard [N] Key to Toggle Gacha Summon Modal (Avoids conflict with [G] Awakening)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.N then
		if screenGui.Enabled then
			screenGui.Enabled = false
			isOpen = false
		else
			openGachaModal()
		end
	end
end)

-- Initial Sync
evGachaSync:FireServer()
print("[StormGachaHUD] ✅ Shinobi Gacha Summon HUD & Reveal Cutscene loaded. Hotkey [N] active.")

