local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormMatchHUD')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormMatchHUD'
s.Source = [=====[--!strict
-- StormMatchHUD.luau
-- CLIENT SCRIPT: Naruto Storm 4 Dual Top Screen Fighting HUD & Match Announcer System
-- Features:
--   • Top Symmetrical Angled Health Bars (Player 1 Left vs Opponent Right)
--   • Delayed "Ghost" Damage Bar animation (fighting game standard)
--   • Guard Gauge & Chakra / Ultimate Energy Meters
--   • Center 99s Hexagonal Round Countdown Timer
--   • Full Match Announcer System:
--       - "ROUND 1 / 2" -> "READY..." -> "FIGHT!" with cinematic pulse & screen shake
--       - "K.O.!" -> "PLAYER 1 WINS! / VICTORY!"
--   • Dynamic tracking of Target (Opponent Player or Training Dummy Lab)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local evCharSelect = combatEvents:WaitForChild("CharacterSelectEvent", 10) :: RemoteEvent?

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Force STRICT Landscape Orientation on Mobile Devices (Naruto Storm Fighting Standard)
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)
pcall(function()
	local StarterGui = game:GetService("StarterGui")
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

-- Match State
local roundTimer = 99
local isMatchActive = true
local playerWins = 0
local opponentWins = 0

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormMatchHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Main Top Container
local topContainer = Instance.new("Frame")
topContainer.Name = "TopHUDContainer"
topContainer.Size = UDim2.new(1, 0, 0, 110)
topContainer.Position = UDim2.new(0, 0, 0, 0)
topContainer.BackgroundTransparency = 1
topContainer.Parent = screenGui

-- =========================================================
-- CENTER TIMER & ROUND INDICATORS
-- =========================================================
local centerFrame = Instance.new("Frame")
centerFrame.Name = "CenterTimer"
centerFrame.Size = UDim2.new(0, 90, 0, 75)
centerFrame.Position = UDim2.new(0.5, 0, 0, 10)
centerFrame.AnchorPoint = Vector2.new(0.5, 0)
centerFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
centerFrame.BackgroundTransparency = 0.2
centerFrame.Parent = topContainer
Instance.new("UICorner", centerFrame).CornerRadius = UDim.new(0, 8)

local cStroke = Instance.new("UIStroke")
cStroke.Color = Color3.fromRGB(0, 240, 255)
cStroke.Thickness = 2
cStroke.Parent = centerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerText"
timerLabel.Size = UDim2.new(1, 0, 0.7, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 2)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextSize = 34
timerLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
timerLabel.Text = "99"
timerLabel.Parent = centerFrame

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundText"
roundLabel.Size = UDim2.new(1, 0, 0.3, 0)
roundLabel.Position = UDim2.new(0, 0, 0.68, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.Font = Enum.Font.GothamBold
roundLabel.TextSize = 11
roundLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
roundLabel.Text = "ROUND 1"
roundLabel.Parent = centerFrame

-- ROSTER BUTTON [B]
local rosterBtn = Instance.new("TextButton")
rosterBtn.Name = "OpenRosterHUDButton"
rosterBtn.Size = UDim2.new(0, 110, 0, 22)
rosterBtn.Position = UDim2.new(0.5, 0, 0, 88)
rosterBtn.AnchorPoint = Vector2.new(0.5, 0)
rosterBtn.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
rosterBtn.BackgroundTransparency = 0.2
rosterBtn.Font = Enum.Font.GothamBold
rosterBtn.TextSize = 10
rosterBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
rosterBtn.Text = "👥 ROSTER [B]"
rosterBtn.Parent = topContainer
Instance.new("UICorner", rosterBtn).CornerRadius = UDim.new(0, 6)
local rStroke = Instance.new("UIStroke")
rStroke.Color = Color3.fromRGB(0, 240, 255)
rStroke.Thickness = 1.2
rStroke.Parent = rosterBtn

rosterBtn.MouseButton1Click:Connect(function()
	local hud = PlayerGui:FindFirstChild("StormCharacterSelectHUD")
	if hud then
		local bindable = hud:FindFirstChild("ToggleRosterUI") :: BindableFunction?
		if bindable then
			bindable:Invoke(true)
		else
			hud.Enabled = not hud.Enabled
		end
	end
end)

-- =========================================================
-- FIGHTER 1 (LEFT SIDE - LOCAL PLAYER)
-- =========================================================
local p1Frame = Instance.new("Frame")
p1Frame.Name = "Fighter1_Left"
p1Frame.Size = UDim2.new(0.40, -55, 0, 70)
p1Frame.Position = UDim2.new(0.5, -55, 0, 12)
p1Frame.AnchorPoint = Vector2.new(1, 0)
p1Frame.BackgroundTransparency = 1
p1Frame.Parent = topContainer

-- P1 Avatar Portrait
local p1Avatar = Instance.new("ImageLabel")
p1Avatar.Name = "P1Avatar"
p1Avatar.Size = UDim2.new(0, 56, 0, 56)
p1Avatar.Position = UDim2.new(0, 0, 0, 5)
p1Avatar.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
p1Avatar.Parent = p1Frame
Instance.new("UICorner", p1Avatar).CornerRadius = UDim.new(1, 0)
local p1Stroke = Instance.new("UIStroke")
p1Stroke.Color = Color3.fromRGB(0, 255, 200)
p1Stroke.Thickness = 2.5
p1Stroke.Parent = p1Avatar

-- Load Local Player Thumbnail
task.spawn(function()
	local thumb, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	if isReady then
		p1Avatar.Image = thumb
	end
end)

-- P1 Name & Archetype
local p1Name = Instance.new("TextLabel")
p1Name.Name = "P1Name"
p1Name.Size = UDim2.new(1, -70, 0, 18)
p1Name.Position = UDim2.new(0, 66, 0, 2)
p1Name.BackgroundTransparency = 1
p1Name.Font = Enum.Font.GothamBlack
p1Name.TextSize = 13
p1Name.TextColor3 = Color3.fromRGB(255, 255, 255)
p1Name.TextXAlignment = Enum.TextXAlignment.Left
p1Name.Text = string.upper(LocalPlayer.DisplayName) .. " [SHINOBI]"
p1Name.Parent = p1Frame

local function updateLocalFighterUI(charId: string)
	local char = CombatConfig.Characters[charId]
	if char then
		p1Name.Text = string.format("%s // %s [%s]", string.upper(char.Name), string.upper(LocalPlayer.DisplayName), string.upper(char.Archetype))
		p1Stroke.Color = char.PrimaryColor
	else
		p1Name.Text = string.upper(LocalPlayer.DisplayName) .. " [SHINOBI]"
	end
end

LocalPlayer:GetAttributeChangedSignal("SelectedCharacter"):Connect(function()
	local cur = LocalPlayer:GetAttribute("SelectedCharacter")
	if cur then
		updateLocalFighterUI(tostring(cur))
	end
end)

if evCharSelect then
	evCharSelect.OnClientEvent:Connect(function(player: Player, charId: string, charData: any)
		if player == LocalPlayer then
			updateLocalFighterUI(charId)
		end
	end)
end

task.spawn(function()
	task.wait(0.5)
	local initChar = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
	updateLocalFighterUI(tostring(initChar))
end)

-- P1 Health Bar Container
local p1HealthBg = Instance.new("Frame")
p1HealthBg.Name = "P1HealthBg"
p1HealthBg.Size = UDim2.new(1, -70, 0, 18)
p1HealthBg.Position = UDim2.new(0, 66, 0, 22)
p1HealthBg.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
p1HealthBg.Parent = p1Frame
Instance.new("UICorner", p1HealthBg).CornerRadius = UDim.new(0, 4)

-- Delayed Ghost Bar (white/red decay)
local p1GhostBar = Instance.new("Frame")
p1GhostBar.Name = "P1GhostBar"
p1GhostBar.Size = UDim2.new(1, 0, 1, 0)
p1GhostBar.BackgroundColor3 = Color3.fromRGB(255, 230, 200)
p1GhostBar.BorderSizePixel = 0
p1GhostBar.Parent = p1HealthBg
Instance.new("UICorner", p1GhostBar).CornerRadius = UDim.new(0, 4)

-- Actual Green/Yellow HP Bar
local p1HealthFill = Instance.new("Frame")
p1HealthFill.Name = "P1HealthFill"
p1HealthFill.Size = UDim2.new(1, 0, 1, 0)
p1HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
p1HealthFill.BorderSizePixel = 0
p1HealthFill.Parent = p1HealthBg
Instance.new("UICorner", p1HealthFill).CornerRadius = UDim.new(0, 4)

-- P1 Sub-bars: Chakra & Guard
local p1ChakraBg = Instance.new("Frame")
p1ChakraBg.Name = "P1ChakraBg"
p1ChakraBg.Size = UDim2.new(0.65, 0, 0, 8)
p1ChakraBg.Position = UDim2.new(0, 66, 0, 44)
p1ChakraBg.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
p1ChakraBg.Parent = p1Frame
Instance.new("UICorner", p1ChakraBg).CornerRadius = UDim.new(0, 3)

local p1ChakraFill = Instance.new("Frame")
p1ChakraFill.Name = "P1ChakraFill"
p1ChakraFill.Size = UDim2.new(0.3, 0, 1, 0)
p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
p1ChakraFill.BorderSizePixel = 0
p1ChakraFill.Parent = p1ChakraBg
Instance.new("UICorner", p1ChakraFill).CornerRadius = UDim.new(0, 3)

local p1GuardBg = Instance.new("Frame")
p1GuardBg.Name = "P1GuardBg"
p1GuardBg.Size = UDim2.new(0.30, 0, 0, 8)
p1GuardBg.Position = UDim2.new(0, 66 + (p1HealthBg.AbsoluteSize.X * 0.7), 0, 44)
p1GuardBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
p1GuardBg.Parent = p1Frame
Instance.new("UICorner", p1GuardBg).CornerRadius = UDim.new(0, 3)

local p1GuardFill = Instance.new("Frame")
p1GuardFill.Name = "P1GuardFill"
p1GuardFill.Size = UDim2.new(1, 0, 1, 0)
p1GuardFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
p1GuardFill.BorderSizePixel = 0
p1GuardFill.Parent = p1GuardBg
Instance.new("UICorner", p1GuardFill).CornerRadius = UDim.new(0, 3)

-- P1 4-Slot Substitution Gauge (Storm 4 Kawarimi Indicator)
local p1SubContainer = Instance.new("Frame")
p1SubContainer.Name = "P1SubContainer"
p1SubContainer.Size = UDim2.new(0.65, 0, 0, 7)
p1SubContainer.Position = UDim2.new(0, 66, 0, 56)
p1SubContainer.BackgroundTransparency = 1
p1SubContainer.Parent = p1Frame

local p1SubLayout = Instance.new("UIListLayout")
p1SubLayout.FillDirection = Enum.FillDirection.Horizontal
p1SubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
p1SubLayout.Padding = UDim.new(0, 4)
p1SubLayout.Parent = p1SubContainer

local p1SubSegments: { Frame } = {}
for i = 1, 4 do
	local seg = Instance.new("Frame")
	seg.Name = "SubLog_" .. i
	seg.Size = UDim2.new(0.22, 0, 1, 0)
	seg.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	seg.BorderSizePixel = 0
	seg.Parent = p1SubContainer
	Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 2)
	table.insert(p1SubSegments, seg)
end

-- =========================================================
-- FIGHTER 2 (RIGHT SIDE - OPPONENT / TRAINING DUMMY)
-- =========================================================
local p2Frame = Instance.new("Frame")
p2Frame.Name = "Fighter2_Right"
p2Frame.Size = UDim2.new(0.40, -55, 0, 70)
p2Frame.Position = UDim2.new(0.5, 55, 0, 12)
p2Frame.AnchorPoint = Vector2.new(0, 0)
p2Frame.BackgroundTransparency = 1
p2Frame.Parent = topContainer

-- P2 Avatar Portrait (Far Right)
local p2Avatar = Instance.new("ImageLabel")
p2Avatar.Name = "P2Avatar"
p2Avatar.Size = UDim2.new(0, 56, 0, 56)
p2Avatar.Position = UDim2.new(1, -56, 0, 5)
p2Avatar.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
p2Avatar.Parent = p2Frame
Instance.new("UICorner", p2Avatar).CornerRadius = UDim.new(1, 0)
local p2Stroke = Instance.new("UIStroke")
p2Stroke.Color = Color3.fromRGB(255, 80, 80)
p2Stroke.Thickness = 2.5
p2Stroke.Parent = p2Avatar

-- P2 Name
local p2Name = Instance.new("TextLabel")
p2Name.Name = "P2Name"
p2Name.Size = UDim2.new(1, -70, 0, 18)
p2Name.Position = UDim2.new(0, 4, 0, 2)
p2Name.BackgroundTransparency = 1
p2Name.Font = Enum.Font.GothamBlack
p2Name.TextSize = 13
p2Name.TextColor3 = Color3.fromRGB(255, 255, 255)
p2Name.TextXAlignment = Enum.TextXAlignment.Right
p2Name.Text = "TRAINING DUMMY LAB"
p2Name.Parent = p2Frame

-- P2 Health Bar Container (Mirrored from right to left)
local p2HealthBg = Instance.new("Frame")
p2HealthBg.Name = "P2HealthBg"
p2HealthBg.Size = UDim2.new(1, -70, 0, 18)
p2HealthBg.Position = UDim2.new(0, 4, 0, 22)
p2HealthBg.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
p2HealthBg.Parent = p2Frame
Instance.new("UICorner", p2HealthBg).CornerRadius = UDim.new(0, 4)

local p2GhostBar = Instance.new("Frame")
p2GhostBar.Name = "P2GhostBar"
p2GhostBar.Size = UDim2.new(1, 0, 1, 0)
p2GhostBar.AnchorPoint = Vector2.new(1, 0)
p2GhostBar.Position = UDim2.new(1, 0, 0, 0)
p2GhostBar.BackgroundColor3 = Color3.fromRGB(255, 230, 200)
p2GhostBar.BorderSizePixel = 0
p2GhostBar.Parent = p2HealthBg
Instance.new("UICorner", p2GhostBar).CornerRadius = UDim.new(0, 4)

local p2HealthFill = Instance.new("Frame")
p2HealthFill.Name = "P2HealthFill"
p2HealthFill.Size = UDim2.new(1, 0, 1, 0)
p2HealthFill.AnchorPoint = Vector2.new(1, 0)
p2HealthFill.Position = UDim2.new(1, 0, 0, 0)
p2HealthFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
p2HealthFill.BorderSizePixel = 0
p2HealthFill.Parent = p2HealthBg
Instance.new("UICorner", p2HealthFill).CornerRadius = UDim.new(0, 4)

-- P2 Sub-bars: Chakra & Guard
local p2ChakraBg = Instance.new("Frame")
p2ChakraBg.Name = "P2ChakraBg"
p2ChakraBg.Size = UDim2.new(0.65, 0, 0, 8)
p2ChakraBg.Position = UDim2.new(0.35, -4, 0, 44)
p2ChakraBg.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
p2ChakraBg.Parent = p2Frame
Instance.new("UICorner", p2ChakraBg).CornerRadius = UDim.new(0, 3)

local p2ChakraFill = Instance.new("Frame")
p2ChakraFill.Name = "P2ChakraFill"
p2ChakraFill.Size = UDim2.new(0.5, 0, 1, 0)
p2ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
p2ChakraFill.BorderSizePixel = 0
p2ChakraFill.Parent = p2ChakraBg
Instance.new("UICorner", p2ChakraFill).CornerRadius = UDim.new(0, 3)

-- P2 4-Slot Substitution Gauge (Opponent Kawarimi Indicator)
local p2SubContainer = Instance.new("Frame")
p2SubContainer.Name = "P2SubContainer"
p2SubContainer.Size = UDim2.new(0.65, 0, 0, 7)
p2SubContainer.Position = UDim2.new(0.35, -4, 0, 56)
p2SubContainer.BackgroundTransparency = 1
p2SubContainer.Parent = p2Frame

local p2SubLayout = Instance.new("UIListLayout")
p2SubLayout.FillDirection = Enum.FillDirection.Horizontal
p2SubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
p2SubLayout.Padding = UDim.new(0, 4)
p2SubLayout.Parent = p2SubContainer

local p2SubSegments: { Frame } = {}
for i = 1, 4 do
	local seg = Instance.new("Frame")
	seg.Name = "SubLog_" .. i
	seg.Size = UDim2.new(0.22, 0, 1, 0)
	seg.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	seg.BorderSizePixel = 0
	seg.Parent = p2SubContainer
	Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 2)
	table.insert(p2SubSegments, seg)
end

-- =========================================================
-- ANNOUNCER OVERLAY BANNER
-- =========================================================
local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "AnnouncerBanner"
bannerFrame.Size = UDim2.new(1, 0, 0, 130)
bannerFrame.Position = UDim2.new(0, 0, 0.40, 0)
bannerFrame.AnchorPoint = Vector2.new(0, 0.5)
bannerFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
bannerFrame.BackgroundTransparency = 1
bannerFrame.Visible = false
bannerFrame.Parent = screenGui

local bannerText = Instance.new("TextLabel")
bannerText.Name = "BannerText"
bannerText.Size = UDim2.fromScale(1, 1)
bannerText.BackgroundTransparency = 1
bannerText.Font = Enum.Font.GothamBlack
bannerText.TextSize = 54
bannerText.TextColor3 = Color3.fromRGB(255, 220, 50)
bannerText.Text = "ROUND 1"
bannerText.Parent = bannerFrame

local function playAnnouncer(text: string, color: Color3, duration: number)
	bannerText.Text = text
	bannerText.TextColor3 = color
	bannerFrame.Visible = true
	bannerFrame.BackgroundTransparency = 0.35
	bannerText.TextTransparency = 0
	bannerText.TextSize = 68

	-- Punch in tween
	TweenService:Create(bannerText, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 52,
	}):Play()

	-- Sound cue
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
		snd.PlaybackSpeed = 1.3
		snd.Volume = 1
		snd.Parent = bannerFrame
		snd:Play()
		task.delay(1, function() pcall(function() snd:Destroy() end) end)
	end)

	task.delay(duration, function()
		local fade = TweenService:Create(bannerFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		local fadeText = TweenService:Create(bannerText, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fadeText:Play()
		fade.Completed:Connect(function()
			bannerFrame.Visible = false
		end)
	end)
end

-- Start Match Intro Sequence
task.spawn(function()
	task.wait(1.2)
	playAnnouncer("ROUND 1", Color3.fromRGB(255, 220, 50), 1.2)
	task.wait(1.5)
	playAnnouncer("READY...", Color3.fromRGB(0, 240, 255), 1.0)
	task.wait(1.1)
	playAnnouncer("FIGHT!", Color3.fromRGB(255, 50, 50), 1.4)
end)

-- =========================================================
-- RUNTIME HEALTH & TIMER UPDATER
-- =========================================================
local lastP1HP = 100
local lastP2HP = 100
local timerAccumulator = 0

RunService.RenderStepped:Connect(function(dt: number)
	-- 1. Round Timer countdown
	if isMatchActive then
		timerAccumulator = timerAccumulator + dt
		if timerAccumulator >= 1.0 then
			timerAccumulator = timerAccumulator - 1.0
			roundTimer = math.max(0, roundTimer - 1)
			timerLabel.Text = tostring(roundTimer)
			if roundTimer <= 15 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
			end
			if roundTimer == 0 then
				isMatchActive = false
				playAnnouncer("TIME UP!", Color3.fromRGB(255, 180, 0), 2.5)
			end
		end
	end

	-- 2. Local Player (P1) Health
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			p1HealthFill.Size = UDim2.new(hpRatio, 0, 1, 0)

			-- Smooth delayed ghost bar
			if hpRatio < lastP1HP then
				TweenService:Create(p1GhostBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(hpRatio, 0, 1, 0),
				}):Play()
				lastP1HP = hpRatio
			elseif hpRatio > lastP1HP then
				p1GhostBar.Size = UDim2.new(hpRatio, 0, 1, 0)
				lastP1HP = hpRatio
			end

			-- Dynamic HP color
			p1HealthFill.BackgroundColor3 = if hpRatio > 0.5 then Color3.fromRGB(0, 255, 140)
				elseif hpRatio > 0.25 then Color3.fromRGB(255, 200, 40)
				else Color3.fromRGB(255, 50, 50)
		end
	end

	-- 3. Opponent (P2) Health (Training Dummy or nearest player)
	local targetModel: Model? = nil
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		targetModel = dummy
		p2Name.Text = "TRAINING DUMMY LAB [BOT]"
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				targetModel = p.Character
				local oppCharId = p:GetAttribute("SelectedCharacter")
				local oppData = oppCharId and CombatConfig.Characters[oppCharId]
				if oppData then
					p2Name.Text = string.format("%s // %s [%s]", string.upper(oppData.Name), string.upper(p.DisplayName), string.upper(oppData.Archetype))
					p2Stroke.Color = oppData.PrimaryColor
				else
					p2Name.Text = string.upper(p.DisplayName)
				end
				break
			end
		end
	end

	if targetModel then
		local tHum = targetModel:FindFirstChildOfClass("Humanoid")
		if tHum then
			local tRatio = math.clamp(tHum.Health / tHum.MaxHealth, 0, 1)
			p2HealthFill.Size = UDim2.new(tRatio, 0, 1, 0)

			if tRatio < lastP2HP then
				TweenService:Create(p2GhostBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(tRatio, 0, 1, 0),
				}):Play()
				lastP2HP = tRatio
			elseif tRatio > lastP2HP then
				p2GhostBar.Size = UDim2.new(tRatio, 0, 1, 0)
				lastP2HP = tRatio
			end

			if tRatio <= 0 and isMatchActive then
				isMatchActive = false
				playAnnouncer("K.O.!", Color3.fromRGB(255, 40, 40), 2.5)
				task.delay(2.6, function()
					playAnnouncer("VICTORY!", Color3.fromRGB(255, 220, 50), 3.0)
				end)
			end
		end
	end

	-- 4. Local Chakra Gauge & Chakra Load Pulse
	local chakraVal = LocalPlayer:GetAttribute("ChakraValue") or 60
	local chakraRatio = math.clamp(tonumber(chakraVal) :: number / 100, 0, 1)
	p1ChakraFill.Size = UDim2.new(chakraRatio, 0, 1, 0)

	local isChakraLoaded = LocalPlayer:GetAttribute("IsChakraLoaded") == true
	if isChakraLoaded then
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	elseif chakraRatio >= 1.0 then
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(255, 220, 50) -- glowing gold when ready
	else
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	end

	-- 5. Storm 4 Substitution Bars (4 Stocks)
	local p1Subs = LocalPlayer:GetAttribute("SubstitutionStocks") or 4
	for i, seg in ipairs(p1SubSegments) do
		seg.BackgroundTransparency = (i <= p1Subs) and 0 or 0.85
	end

	local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)
	local p2Subs = (targetPlayer and targetPlayer:GetAttribute("SubstitutionStocks")) or 4
	for i, seg in ipairs(p2SubSegments) do
		seg.BackgroundTransparency = (i <= p2Subs) and 0 or 0.85
	end

	local p2Chakra = (targetPlayer and targetPlayer:GetAttribute("ChakraValue")) or 60
	p2ChakraFill.Size = UDim2.new(math.clamp(p2Chakra / 100, 0, 1), 0, 1, 0)
end)

print("[StormMatchHUD] ✅ Naruto Storm 4 Dual Top Screen Fighting HUD & Announcer active.")
]=====]
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormMatchHUD'
