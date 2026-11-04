local function install(name, sType, parent, src)
    local ex = parent:FindFirstChild(name)
    if ex then ex:Destroy() end
    local s = Instance.new(sType)
    s.Name = name
    s.Source = src
    s.Parent = parent
    print('[Installed] ' .. sType .. ': ' .. name)
end

do
    local src = [=====[--!strict
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

	-- 4. Local Chakra Gauge
	local chakraVal = LocalPlayer:GetAttribute("ChakraValue") or 50
	local chakraRatio = math.clamp(tonumber(chakraVal) :: number / 100, 0, 1)
	p1ChakraFill.Size = UDim2.new(chakraRatio, 0, 1, 0)
	if chakraRatio >= 1.0 then
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(255, 220, 50) -- glowing gold when ready
	else
		p1ChakraFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	end
end)

print("[StormMatchHUD] ✅ Naruto Storm 4 Dual Top Screen Fighting HUD & Announcer active.")
]=====]
    install('StormMatchHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- MobileCombatHUD.luau
-- CLIENT SCRIPT: Modern Cyber-Anime Mobile Touch Controls HUD
-- Features:
--   • Auto-activates on Mobile / Tablet touch screens (or toggleable on PC)
--   • Ergonomic Right-Thumb Combat Layout:
--       [ATTACK] Button (Primary M1 / J Key)
--       [GUARD]  Button (Hold for K Key High/Low Guard, tap for Parry)
--       [DASH]   Button (L Key Homing Ninja Dash)
--       [ASSIST] Button (I Key Jutsu Striker)
--       [SWAP]   Button (U Key Tag Swap)
--       [LOCK]   Button (Z Key Camera Lock-on)
--   • Tactile spring-back animations on button press & neon glow

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Bindable Events for Client Communication
local function getOrMakeBindable(name: string): BindableEvent
	local be = ReplicatedStorage:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = ReplicatedStorage
	end
	return be
end

local evMobileAttack   = getOrMakeBindable("MobileAttackAction")
local evMobileLow      = getOrMakeBindable("MobileLowAttackAction")
local evMobileRanged   = getOrMakeBindable("MobileRangedAction")
local evMobileGuard    = getOrMakeBindable("MobileGuardAction")
local evMobileDash     = getOrMakeBindable("MobileDashAction")
local evMobileAssist   = getOrMakeBindable("MobileAssistAction")
local evMobileSwap     = getOrMakeBindable("MobileSwapAction")
local evMobileUltimate = getOrMakeBindable("MobileUltimateAction")
local evMobileChakra   = getOrMakeBindable("MobileChakraAction")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormMobileCombatHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Visibility check: TouchEnabled OR PC manual toggle button
local isTouchDevice = UserInputService.TouchEnabled
local hudContainer = Instance.new("Frame")
hudContainer.Name = "ActionCluster"
hudContainer.Size = UDim2.new(0, 260, 0, 260)
hudContainer.Position = UDim2.new(1, -270, 1, -270)
hudContainer.BackgroundTransparency = 1
hudContainer.Visible = isTouchDevice -- Auto-shows on Mobile
hudContainer.Parent = screenGui

-- =========================================================
-- BUTTON BUILDER HELPER
-- =========================================================
local function createActionButton(
	name: string,
	icon: string,
	keyHint: string,
	color: Color3,
	pos: UDim2,
	size: UDim2
): (TextButton, UIStroke)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size
	btn.Position = pos
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	btn.BackgroundTransparency = 0.25
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = hudContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2.5
	stroke.Parent = btn

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 0.55, 0)
	iconLabel.Position = UDim2.new(0, 0, 0.12, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextSize = 22
	iconLabel.TextColor3 = color
	iconLabel.Parent = btn

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.Size = UDim2.new(1, 0, 0.35, 0)
	hintLabel.Position = UDim2.new(0, 0, 0.60, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = keyHint
	hintLabel.Font = Enum.Font.GothamBlack
	hintLabel.TextSize = 10
	hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	hintLabel.Parent = btn

	-- Press Animation
	local origSize = size
	local smallSize = UDim2.new(size.X.Scale, size.X.Offset * 0.90, size.Y.Scale, size.Y.Offset * 0.90)

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(btn, TweenInfo.new(0.08), { Size = smallSize, BackgroundTransparency = 0.05 }):Play()
		end
	end)

	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(btn, TweenInfo.new(0.12), { Size = origSize, BackgroundTransparency = 0.25 }):Play()
		end
	end)

	return btn, stroke
end

-- =========================================================
-- =========================================================
-- CREATE COMBAT BUTTONS (Naruto Storm Mobile Layout)
-- =========================================================
-- 1. PUNCH [J] (Primary Combo Strike)
local btnAttack = createActionButton(
	"BtnAttack", "⚔️", "PUNCH [J]", Color3.fromRGB(0, 240, 255),
	UDim2.new(0.65, 0, 0.65, 0), UDim2.new(0, 78, 0, 78)
)
btnAttack.MouseButton1Click:Connect(function()
	evMobileAttack:Fire(false)
end)

-- 2. LOW SWEEP [K] (Serangan Bawah)
local btnLow = createActionButton(
	"BtnLow", "⚡", "LOW [K]", Color3.fromRGB(255, 180, 20),
	UDim2.new(0.88, 0, 0.65, 0), UDim2.new(0, 56, 0, 56)
)
btnLow.MouseButton1Click:Connect(function()
	evMobileLow:Fire()
end)

-- 3. RANGED JUTSU [L] (Serangan Jarak Jauh)
local btnRanged = createActionButton(
	"BtnRanged", "🌀", "RANGED [L]", Color3.fromRGB(80, 220, 255),
	UDim2.new(0.65, 0, 0.32, 0), UDim2.new(0, 56, 0, 56)
)
btnRanged.MouseButton1Click:Connect(function()
	evMobileRanged:Fire()
end)

-- 4. GUARD [F] (Hold to Block)
local btnGuard = createActionButton(
	"BtnGuard", "🛡️", "GUARD [F]", Color3.fromRGB(255, 215, 0),
	UDim2.new(0.88, 0, 0.32, 0), UDim2.new(0, 56, 0, 56)
)
btnGuard.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		evMobileGuard:Fire(true)
	end
end)
btnGuard.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		evMobileGuard:Fire(false)
	end
end)

-- 5. DASH [SHIFT] (Homing Ninja Dash)
local btnDash = createActionButton(
	"BtnDash", "💨", "DASH [SHIFT]", Color3.fromRGB(0, 255, 170),
	UDim2.new(0.38, 0, 0.82, 0), UDim2.new(0, 56, 0, 56)
)
btnDash.MouseButton1Click:Connect(function()
	evMobileDash:Fire()
end)

-- 6. CHAKRA ENERGY & ULTIMATE [I] (Hold for Ultimate!)
local btnChakra = createActionButton(
	"BtnChakra", "🔥", "CHAKRA/ULT [I]", Color3.fromRGB(255, 80, 40),
	UDim2.new(0.12, 0, 0.65, 0), UDim2.new(0, 58, 0, 58)
)
local isMobileHoldingChakra = false
local mobileChakraStart = 0
btnChakra.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMobileHoldingChakra = true
		mobileChakraStart = os.clock()
		evMobileChakra:Fire(true)
		task.spawn(function()
			while isMobileHoldingChakra do
				task.wait(0.05)
				local held = os.clock() - mobileChakraStart
				local curChakra = LocalPlayer:GetAttribute("ChakraValue") or 0
				if isMobileHoldingChakra and curChakra >= 100 and held >= 0.60 then
					evMobileChakra:Fire(false)
					evMobileUltimate:Fire()
					break
				end
			end
		end)
	end
end)
btnChakra.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMobileHoldingChakra = false
		evMobileChakra:Fire(false)
	end
end)

-- 7. LEADER SWAP [U]
local btnSwap = createActionButton(
	"BtnSwap", "🔄", "SWAP [U]", Color3.fromRGB(200, 100, 255),
	UDim2.new(0.20, 0, 0.38, 0), UDim2.new(0, 48, 0, 48)
)
btnSwap.MouseButton1Click:Connect(function()
	evMobileSwap:Fire()
end)

-- =========================================================
-- TOGGLE BUTTON FOR PC TESTING
-- =========================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MobileHUDToggle"
toggleBtn.Size = UDim2.new(0, 95, 0, 26)
toggleBtn.Position = UDim2.new(1, -110, 0, 50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 10
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
toggleBtn.Text = isTouchDevice and "📱 TOUCH: ON" or "📱 TOUCH: OFF"
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
local tStroke = Instance.new("UIStroke")
tStroke.Color = Color3.fromRGB(0, 255, 200)
tStroke.Thickness = 1
tStroke.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
	hudContainer.Visible = not hudContainer.Visible
	toggleBtn.Text = hudContainer.Visible and "📱 TOUCH: ON" or "📱 TOUCH: OFF"
	tStroke.Color = hudContainer.Visible and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(150, 150, 150)
end)

print("[MobileCombatHUD] ✅ Loaded — Touch controls auto-configured for worldwide mobile & tablet players.")

]=====]
    install('MobileCombatHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- PerformanceSettingsManager.luau
-- CLIENT SCRIPT: Low-GFX & High-Performance Mode for Worldwide Devices
-- Features:
--   • Single-click toggle between [⚡ GFX: HIGH] and [⚡ GFX: LOW]
--   • Optimizes performance for budget Android, low-end PCs, and battery saving:
--       - Toggles Post-Processing (Bloom & SunRays)
--       - Toggles Dynamic Global Shadows
--       - Reduces particle clutter
--   • Locks FPS at smooth 60 FPS across all global regions

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isLowGfxActive = false

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormPerformanceGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Toggle Button (Top Right)
local btnGfx = Instance.new("TextButton")
btnGfx.Name = "GfxModeToggle"
btnGfx.Size = UDim2.new(0, 100, 0, 26)
btnGfx.Position = UDim2.new(1, -110, 0, 16)
btnGfx.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
btnGfx.BackgroundTransparency = 0.25
btnGfx.Font = Enum.Font.GothamBold
btnGfx.TextSize = 10
btnGfx.TextColor3 = Color3.fromRGB(0, 240, 255)
btnGfx.Text = "⚡ GFX: HIGH"
btnGfx.Parent = screenGui
Instance.new("UICorner", btnGfx).CornerRadius = UDim.new(0, 6)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 240, 255)
stroke.Thickness = 1.2
stroke.Parent = btnGfx

-- =========================================================
-- APPLY GRAPHICS SETTINGS
-- =========================================================
local function setLowGfxMode(enableLow: boolean)
	isLowGfxActive = enableLow

	-- 1. Lighting PostEffects
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then bloom.Enabled = not enableLow end

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then sunRays.Enabled = not enableLow end

	-- 2. Shadows
	Lighting.GlobalShadows = not enableLow

	-- 3. Update Button Visual
	if enableLow then
		btnGfx.Text = "⚡ GFX: LOW (60FPS)"
		btnGfx.TextColor3 = Color3.fromRGB(255, 200, 50)
		stroke.Color = Color3.fromRGB(255, 200, 50)
		print(">> [Storm Performance] Low-GFX Performance Mode Enabled (Optimized for Mobile/Budget Devices). <<")
	else
		btnGfx.Text = "⚡ GFX: HIGH"
		btnGfx.TextColor3 = Color3.fromRGB(0, 240, 255)
		stroke.Color = Color3.fromRGB(0, 240, 255)
		print(">> [Storm Performance] High Quality Anime Visuals Restored. <<")
	end
end

btnGfx.MouseButton1Click:Connect(function()
	setLowGfxMode(not isLowGfxActive)
end)

print("[PerformanceSettingsManager] ✅ Loaded — Low-GFX / 60FPS Performance Toggle active.")

]=====]
    install('PerformanceSettingsManager', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

do
    local src = [=====[--!strict
-- StormCharacterSelectHUD.luau
-- CLIENT SCRIPT: Jump Force & Naruto Storm 4 Character Selection Modal & Roster HUD
-- Features:
--   • 5-Fighter Roster Grid: Naruto, Sasuke, Luffy, Zoro, Killua
--   • Dynamic Archetype Badges (Rushdown, Zoner, Grappler, Sword, Trickster)
--   • Detailed Character Dossier: 4 Stat Bars (Speed, Power, Defense, Jutsu)
--   • Technique Arsenal Showcase (M1, Low Sweep, Ninja Assist, Secret Technique)
--   • Interactive Selection with Sound Effects and Visual Glow
--   • Toggleable via [B] Key, Lobby Pedestal, or Top-Left HUD Button

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local evCharSelect = combatEvents:WaitForChild("CharacterSelectEvent", 10) :: RemoteEvent
local evOpenRoster = combatEvents:WaitForChild("OpenRosterEvent", 10) :: RemoteEvent

-- State
local isOpen = false
local currentSelectedId = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
local previewSelectedId = currentSelectedId

-- Sounds helper
local function playUiSound(soundName: string, pitch: number)
	task.spawn(function()
		pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/" .. soundName
			sound.Volume = 0.5
			sound.PlaybackSpeed = pitch or 1.0
			sound.Parent = SoundService
			sound:Play()
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end)
	end)
end

-- =========================================================
-- SCREEN GUI CREATION
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormCharacterSelectHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Dark Vignette Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "ModalBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Position = UDim2.new(0, 0, 0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = screenGui

-- Main Modal Window
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainModal"
mainFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = backdrop
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(0, 240, 255)
modalStroke.Thickness = 2
modalStroke.Parent = mainFrame

-- Header Bar
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderBar"
headerFrame.Size = UDim2.new(1, 0, 0, 56)
headerFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
headerFrame.BackgroundTransparency = 0.2
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame
Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 24, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "⚡ SHINOBI ROSTER // CHOOSE YOUR FIGHTER"
titleLabel.Parent = headerFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(240, 40, 40)
closeBtn.BackgroundTransparency = 0.2
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- CONTENT SPLIT: LEFT GRID & RIGHT PREVIEW
-- =========================================================
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -40, 1, -80)
contentFrame.Position = UDim2.new(0, 20, 0, 68)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- LEFT PANEL: ROSTER CARDS (Width: 42%)
local rosterList = Instance.new("ScrollingFrame")
rosterList.Name = "RosterList"
rosterList.Size = UDim2.new(0.42, 0, 1, 0)
rosterList.Position = UDim2.new(0, 0, 0, 0)
rosterList.BackgroundTransparency = 1
rosterList.ScrollBarThickness = 6
rosterList.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
rosterList.CanvasSize = UDim2.new(0, 0, 0, 5 * 84)
rosterList.Parent = contentFrame

local rosterLayout = Instance.new("UIListLayout")
rosterLayout.SortOrder = Enum.SortOrder.LayoutOrder
rosterLayout.Padding = UDim.new(0, 10)
rosterLayout.Parent = rosterList

-- RIGHT PANEL: DETAILED DOSSIER (Width: 56%)
local previewPanel = Instance.new("Frame")
previewPanel.Name = "PreviewPanel"
previewPanel.Size = UDim2.new(0.56, 0, 1, 0)
previewPanel.Position = UDim2.new(0.44, 0, 0, 0)
previewPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
previewPanel.BackgroundTransparency = 0.4
previewPanel.Parent = contentFrame
Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 10)

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(40, 50, 70)
previewStroke.Thickness = 1.5
previewStroke.Parent = previewPanel

-- Scroll container for preview details
local previewScroll = Instance.new("ScrollingFrame")
previewScroll.Name = "PreviewScroll"
previewScroll.Size = UDim2.new(1, 0, 1, -54)
previewScroll.Position = UDim2.new(0, 0, 0, 0)
previewScroll.BackgroundTransparency = 1
previewScroll.ScrollBarThickness = 4
previewScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
previewScroll.CanvasSize = UDim2.new(0, 0, 0, 360)
previewScroll.Parent = previewPanel

-- Top Info: Large Icon + Name + Title
local pIcon = Instance.new("TextLabel")
pIcon.Name = "PreviewIcon"
pIcon.Size = UDim2.new(0, 68, 0, 68)
pIcon.Position = UDim2.new(0, 16, 0, 16)
pIcon.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
pIcon.Font = Enum.Font.GothamBold
pIcon.TextSize = 36
pIcon.Text = "🦊"
pIcon.Parent = previewScroll
Instance.new("UICorner", pIcon).CornerRadius = UDim.new(0, 10)
local pIconStroke = Instance.new("UIStroke")
pIconStroke.Color = Color3.fromRGB(255, 130, 20)
pIconStroke.Thickness = 2.5
pIconStroke.Parent = pIcon

local pName = Instance.new("TextLabel")
pName.Name = "PreviewName"
pName.Size = UDim2.new(1, -100, 0, 26)
pName.Position = UDim2.new(0, 96, 0, 16)
pName.BackgroundTransparency = 1
pName.Font = Enum.Font.GothamBlack
pName.TextSize = 20
pName.TextColor3 = Color3.fromRGB(255, 255, 255)
pName.TextXAlignment = Enum.TextXAlignment.Left
pName.Text = "NARUTO UZUMAKI"
pName.Parent = previewScroll

local pTitle = Instance.new("TextLabel")
pTitle.Name = "PreviewTitle"
pTitle.Size = UDim2.new(1, -100, 0, 18)
pTitle.Position = UDim2.new(0, 96, 0, 44)
pTitle.BackgroundTransparency = 1
pTitle.Font = Enum.Font.GothamMedium
pTitle.TextSize = 12
pTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
pTitle.TextXAlignment = Enum.TextXAlignment.Left
pTitle.Text = "Hero of the Hidden Leaf • RUSHDOWN"
pTitle.Parent = previewScroll

local pQuote = Instance.new("TextLabel")
pQuote.Name = "PreviewQuote"
pQuote.Size = UDim2.new(1, -32, 0, 32)
pQuote.Position = UDim2.new(0, 16, 0, 92)
pQuote.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
pQuote.BackgroundTransparency = 0.5
pQuote.Font = Enum.Font.GothamMedium
pQuote.TextSize = 12
pQuote.RichText = true
pQuote.TextColor3 = Color3.fromRGB(220, 220, 230)
pQuote.TextWrapped = true
pQuote.Text = '"I never go back on my word! That\'s my ninja way!"'
pQuote.Parent = previewScroll
Instance.new("UICorner", pQuote).CornerRadius = UDim.new(0, 6)

-- STATS SECTION (4 Horizontal Bars)
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, -32, 0, 110)
statsContainer.Position = UDim2.new(0, 16, 0, 132)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = previewScroll

local statFills: { [string]: Frame } = {}
local statLabels: { [string]: TextLabel } = {}

local statDefs = {
	{ key = "Speed",   label = "SPEED",   y = 0,   color = Color3.fromRGB(0, 255, 200) },
	{ key = "Power",   label = "POWER",   y = 28,  color = Color3.fromRGB(255, 80, 80) },
	{ key = "Defense", label = "DEFENSE", y = 56,  color = Color3.fromRGB(255, 215, 0) },
	{ key = "Jutsu",   label = "JUTSU",   y = 84,  color = Color3.fromRGB(180, 100, 255) },
}

for _, def in ipairs(statDefs) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.Position = UDim2.new(0, 0, 0, def.y)
	row.BackgroundTransparency = 1
	row.Parent = statsContainer

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 75, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(180, 190, 210)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = def.label
	lbl.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -120, 0, 10)
	barBg.Position = UDim2.new(0, 80, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
	barBg.Parent = row
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = def.color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)
	statFills[def.key] = barFill

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(0, 35, 1, 0)
	valLbl.Position = UDim2.new(1, -35, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = Enum.Font.GothamBlack
	valLbl.TextSize = 12
	valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Text = "85"
	valLbl.Parent = row
	statLabels[def.key] = valLbl
end

-- SKILLS ARSENAL BOX
local skillsBox = Instance.new("Frame")
skillsBox.Name = "SkillsBox"
skillsBox.Size = UDim2.new(1, -32, 0, 84)
skillsBox.Position = UDim2.new(0, 16, 0, 248)
skillsBox.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
skillsBox.BackgroundTransparency = 0.4
skillsBox.Parent = previewScroll
Instance.new("UICorner", skillsBox).CornerRadius = UDim.new(0, 8)

local sListLayout = Instance.new("UIListLayout")
sListLayout.Padding = UDim.new(0, 3)
sListLayout.Parent = skillsBox

local function createSkillRow(prefix: string, name: string): TextLabel
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -12, 0, 18)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 11
	row.TextColor3 = Color3.fromRGB(200, 210, 230)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = "  " .. prefix .. ": " .. name
	row.Parent = skillsBox
	return row
end

local m1SkillLbl   = createSkillRow("🥊 Combo M1", "Shinobi Taijutsu Barrage")
local sweepSkillLbl = createSkillRow("⚡ Sweep", "Uzumaki Low Sweep")
local assistSkillLbl = createSkillRow("👥 Assist", "Shadow Clone Rasengan")
local ultSkillLbl  = createSkillRow("💥 Ultimate", "Wind Style: Rasenshuriken")

-- BOTTOM ACTION BUTTON (Docked at base of PreviewPanel)
local selectBtn = Instance.new("TextButton")
selectBtn.Name = "SelectFighterButton"
selectBtn.Size = UDim2.new(1, -32, 0, 42)
selectBtn.Position = UDim2.new(0, 16, 1, -48)
selectBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
selectBtn.Font = Enum.Font.GothamBlack
selectBtn.TextSize = 14
selectBtn.TextColor3 = Color3.fromRGB(12, 18, 24)
selectBtn.Text = "⚔️ PILIH KARAKTER SHINOBI (SELECT)"
selectBtn.Parent = previewPanel
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 8)

local selStroke = Instance.new("UIStroke")
selStroke.Color = Color3.fromRGB(255, 255, 255)
selStroke.Thickness = 1.5
selStroke.Parent = selectBtn

-- =========================================================
-- ROSTER CARD CREATION & SELECTION LOGIC
-- =========================================================
local cardStrokes: { [string]: UIStroke } = {}
local cardFrames: { [string]: TextButton } = {}

local function updatePreview(charId: string)
	local char = CombatConfig.Characters[charId]
	if not char then return end

	previewSelectedId = charId

	-- Update preview text & visuals
	pIcon.Text = char.Icon
	pIconStroke.Color = char.PrimaryColor
	pName.Text = string.upper(char.Name)
	pName.TextColor3 = char.PrimaryColor
	pTitle.Text = char.Title .. " • " .. string.upper(char.Archetype)
	pTitle.TextColor3 = char.AccentColor
	pQuote.Text = '"' .. char.Quote .. '"'

	-- Update Stats
	local stats = char.Stats or { Speed = 80, Power = 80, Defense = 80, Jutsu = 80 }
	for key, fill in pairs(statFills) do
		local val = stats[key] or 80
		local ratio = math.clamp(val / 100, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ratio, 0, 1, 0),
		}):Play()
		if statLabels[key] then
			statLabels[key].Text = tostring(val)
		end
	end

	-- Update Skill Names
	m1SkillLbl.Text    = "  🥊 Combo [J]: " .. char.M1Name
	sweepSkillLbl.Text = "  ⚡ Sweep [S+J]: " .. char.SweepName
	assistSkillLbl.Text = "  👥 Assist [U]: " .. char.AssistName
	ultSkillLbl.Text   = "  💥 Ultimate [I]: " .. char.UltimateName

	-- Update Button State
	if charId == currentSelectedId then
		selectBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
		selectBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		selectBtn.Text = "✓ KARAKTER TERPILIH (CURRENT)"
	else
		selectBtn.BackgroundColor3 = char.PrimaryColor
		selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectBtn.Text = "⚔️ PILIH " .. string.upper(char.Name) .. " (SELECT)"
	end

	-- Highlight active card
	for id, stroke in pairs(cardStrokes) do
		if id == charId then
			stroke.Color = Color3.fromRGB(255, 215, 0)
			stroke.Thickness = 3
		else
			stroke.Color = Color3.fromRGB(45, 55, 75)
			stroke.Thickness = 1.5
		end
	end
end

-- Build Card for each fighter
local charOrder = { "Naruto", "Sasuke", "Luffy", "Zoro", "Killua" }
for idx, charId in ipairs(charOrder) do
	local char = CombatConfig.Characters[charId]
	if not char then continue end

	local card = Instance.new("TextButton")
	card.Name = "Card_" .. charId
	card.Size = UDim2.new(1, -6, 0, 74)
	card.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
	card.BackgroundTransparency = 0.2
	card.Text = ""
	card.AutoButtonColor = false
	card.LayoutOrder = idx
	card.Parent = rosterList
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(45, 55, 75)
	cStroke.Thickness = 1.5
	cStroke.Parent = card
	cardStrokes[charId] = cStroke
	cardFrames[charId] = card

	-- Fighter Icon
	local cIcon = Instance.new("TextLabel")
	cIcon.Size = UDim2.new(0, 50, 0, 50)
	cIcon.Position = UDim2.new(0, 12, 0.5, 0)
	cIcon.AnchorPoint = Vector2.new(0, 0.5)
	cIcon.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	cIcon.Font = Enum.Font.GothamBold
	cIcon.TextSize = 26
	cIcon.Text = char.Icon
	cIcon.Parent = card
	Instance.new("UICorner", cIcon).CornerRadius = UDim.new(0, 8)

	-- Name
	local cName = Instance.new("TextLabel")
	cName.Size = UDim2.new(1, -74, 0, 20)
	cName.Position = UDim2.new(0, 70, 0, 14)
	cName.BackgroundTransparency = 1
	cName.Font = Enum.Font.GothamBlack
	cName.TextSize = 14
	cName.TextColor3 = Color3.fromRGB(255, 255, 255)
	cName.TextXAlignment = Enum.TextXAlignment.Left
	cName.Text = char.Name
	cName.Parent = card

	-- Archetype Tag
	local cTag = Instance.new("TextLabel")
	cTag.Size = UDim2.new(0, 90, 0, 18)
	cTag.Position = UDim2.new(0, 70, 0, 38)
	cTag.BackgroundColor3 = char.PrimaryColor
	cTag.BackgroundTransparency = 0.3
	cTag.Font = Enum.Font.GothamBold
	cTag.TextSize = 10
	cTag.TextColor3 = Color3.fromRGB(255, 255, 255)
	cTag.Text = string.upper(char.Archetype)
	cTag.Parent = card
	Instance.new("UICorner", cTag).CornerRadius = UDim.new(0, 4)

	-- Click handler
	card.MouseButton1Click:Connect(function()
		playUiSound("volume_slider.ogg", 1.2)
		updatePreview(charId)
	end)
end

-- =========================================================
-- CONFIRM SELECTION
-- =========================================================
local function selectCharacter(charId: string)
	local char = CombatConfig.Characters[charId]
	if not char then return end

	currentSelectedId = charId
	playUiSound("action_footsteps_plastic.mp3", 1.5)

	-- Fire to server
	evCharSelect:FireServer(charId)

	-- Visual feedback
	updatePreview(charId)

	-- Close modal smoothly after short delay
	task.delay(0.3, function()
		screenGui.Enabled = false
		isOpen = false
	end)
end

selectBtn.MouseButton1Click:Connect(function()
	selectCharacter(previewSelectedId)
end)

-- =========================================================
-- MODAL TOGGLE & CONTROLS
-- =========================================================
local function toggleRoster(state: boolean?)
	if state ~= nil then
		isOpen = state
	else
		isOpen = not isOpen
	end

	screenGui.Enabled = isOpen
	if isOpen then
		playUiSound("volume_slider.ogg", 1.0)
		local current = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
		currentSelectedId = tostring(current)
		updatePreview(currentSelectedId)

		-- Animated Entrance
		mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
		mainFrame.BackgroundTransparency = 1
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0.1,
		}):Play()
	end
end

closeBtn.MouseButton1Click:Connect(function()
	toggleRoster(false)
end)

-- Keybind [B] to toggle roster
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleRoster()
	end
end)

-- Listen to Lobby Pedestal remote trigger
evOpenRoster.OnClientEvent:Connect(function()
	toggleRoster(true)
end)

-- Listen to character changes replicated from server
evCharSelect.OnClientEvent:Connect(function(player: Player, charId: string, charData: any)
	if player == LocalPlayer then
		currentSelectedId = charId
		updatePreview(charId)
	end
end)

-- Expose to global/other scripts via bindable if needed
local bindable = Instance.new("BindableFunction")
bindable.Name = "ToggleRosterUI"
bindable.OnInvoke = function(state)
	toggleRoster(state)
	return isOpen
end
bindable.Parent = screenGui

print("[StormCharacterSelectHUD] ✅ Shinobi Roster UI loaded. Press [B] or visit Lobby Pedestal.")
]=====]
    install('StormCharacterSelectHUD', 'LocalScript', game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'), src)
end

return 'Batch 5 OK (4 scripts)'