--!strict
-- StormBossHUD.luau
-- CLIENT SCRIPT: Dynamic Wave Tracker, Akatsuki Boss HP Bar, and Trial Victory Fanfare
-- Features:
--   • Top Wave Tracker Pill with enemy count and wave titles
--   • Majestic Akatsuki Shadow Boss Bar with ghost damage lag and Crimson glow
--   • Grand Wave Clear Fanfare (+500 Ryo & +50 Shards) with anime victory audio

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evWaveStatus = combatEvents:WaitForChild("WaveStatusEvent", 15) :: RemoteEvent
local evWaveReward = combatEvents:WaitForChild("WaveRewardEvent", 15) :: RemoteEvent

-- Sound Helper
local function playSafeSound(soundId: string, pitch: number?, vol: number?)
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
-- SCREEN GUI
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormBossHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 15
screenGui.Parent = PlayerGui

-- 1. WAVE TRACKER DOCK (Top Center-Right)
local waveDock = Instance.new("Frame")
waveDock.Name = "WaveTrackerDock"
waveDock.Size = UDim2.new(0, 320, 0, 52)
waveDock.Position = UDim2.new(0.5, 0, 0, 85)
waveDock.AnchorPoint = Vector2.new(0.5, 0)
waveDock.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
waveDock.BackgroundTransparency = 0.25
waveDock.Visible = false
waveDock.Parent = screenGui
Instance.new("UICorner", waveDock).CornerRadius = UDim.new(0, 10)

local dockStroke = Instance.new("UIStroke")
dockStroke.Color = Color3.fromRGB(0, 240, 255)
dockStroke.Thickness = 1.5
dockStroke.Parent = waveDock

local waveTitleLbl = Instance.new("TextLabel")
waveTitleLbl.Name = "WaveTitle"
waveTitleLbl.Size = UDim2.new(1, -16, 0, 22)
waveTitleLbl.Position = UDim2.new(0, 8, 0, 6)
waveTitleLbl.BackgroundTransparency = 1
waveTitleLbl.Font = Enum.Font.GothamBlack
waveTitleLbl.TextSize = 13
waveTitleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
waveTitleLbl.Text = "🌊 GELOMBANG 1 / 3"
waveTitleLbl.Parent = waveDock

local waveSubLbl = Instance.new("TextLabel")
waveSubLbl.Name = "WaveSub"
waveSubLbl.Size = UDim2.new(1, -16, 0, 18)
waveSubLbl.Position = UDim2.new(0, 8, 0, 28)
waveSubLbl.BackgroundTransparency = 1
waveSubLbl.Font = Enum.Font.GothamBold
waveSubLbl.TextSize = 11
waveSubLbl.TextColor3 = Color3.fromRGB(180, 200, 230)
waveSubLbl.Text = "⚔️ Sisa Musuh: 2"
waveSubLbl.Parent = waveDock

-- 2. BOSS HEALTH BAR (Top Center)
local bossBarContainer = Instance.new("Frame")
bossBarContainer.Name = "BossBarContainer"
bossBarContainer.Size = UDim2.new(0, 520, 0, 62)
bossBarContainer.Position = UDim2.new(0.5, 0, 0, 95)
bossBarContainer.AnchorPoint = Vector2.new(0.5, 0)
bossBarContainer.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
bossBarContainer.BackgroundTransparency = 0.2
bossBarContainer.Visible = false
bossBarContainer.Parent = screenGui
Instance.new("UICorner", bossBarContainer).CornerRadius = UDim.new(0, 10)

local bossStroke = Instance.new("UIStroke")
bossStroke.Color = Color3.fromRGB(255, 30, 80)
bossStroke.Thickness = 2
bossStroke.Parent = bossBarContainer

local bossNameLbl = Instance.new("TextLabel")
bossNameLbl.Name = "BossName"
bossNameLbl.Size = UDim2.new(0.65, 0, 0, 24)
bossNameLbl.Position = UDim2.new(0, 16, 0, 6)
bossNameLbl.BackgroundTransparency = 1
bossNameLbl.Font = Enum.Font.GothamBlack
bossNameLbl.TextSize = 14
bossNameLbl.TextColor3 = Color3.fromRGB(255, 45, 75)
bossNameLbl.TextXAlignment = Enum.TextXAlignment.Left
bossNameLbl.Text = "👹 AKATSUKI SHADOW BOSS"
bossNameLbl.Parent = bossBarContainer

local bossHpLbl = Instance.new("TextLabel")
bossHpLbl.Name = "BossHP"
bossHpLbl.Size = UDim2.new(0.3, 0, 0, 24)
bossHpLbl.Position = UDim2.new(0.7, -16, 0, 6)
bossHpLbl.BackgroundTransparency = 1
bossHpLbl.Font = Enum.Font.GothamBlack
bossHpLbl.TextSize = 12
bossHpLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
bossHpLbl.TextXAlignment = Enum.TextXAlignment.Right
bossHpLbl.Text = "750 / 750 HP"
bossHpLbl.Parent = bossBarContainer

-- Bar Track
local bossBarTrack = Instance.new("Frame")
bossBarTrack.Name = "BarTrack"
bossBarTrack.Size = UDim2.new(1, -32, 0, 16)
bossBarTrack.Position = UDim2.new(0, 16, 0, 34)
bossBarTrack.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
bossBarTrack.Parent = bossBarContainer
Instance.new("UICorner", bossBarTrack).CornerRadius = UDim.new(0, 6)

local bossGhostBar = Instance.new("Frame")
bossGhostBar.Name = "GhostBar"
bossGhostBar.Size = UDim2.new(1, 0, 1, 0)
bossGhostBar.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
bossGhostBar.BorderSizePixel = 0
bossGhostBar.Parent = bossBarTrack
Instance.new("UICorner", bossGhostBar).CornerRadius = UDim.new(0, 6)

local bossHpFill = Instance.new("Frame")
bossHpFill.Name = "HpFill"
bossHpFill.Size = UDim2.new(1, 0, 1, 0)
bossHpFill.BackgroundColor3 = Color3.fromRGB(255, 30, 80)
bossHpFill.BorderSizePixel = 0
bossHpFill.Parent = bossBarTrack
Instance.new("UICorner", bossHpFill).CornerRadius = UDim.new(0, 6)

-- 3. GRAND VICTORY FANFARE BANNER
local fanfareFrame = Instance.new("Frame")
fanfareFrame.Name = "FanfareFrame"
fanfareFrame.Size = UDim2.new(0.85, 0, 0, 170)
fanfareFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
fanfareFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fanfareFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
fanfareFrame.BackgroundTransparency = 1
fanfareFrame.Visible = false
fanfareFrame.Parent = screenGui
Instance.new("UICorner", fanfareFrame).CornerRadius = UDim.new(0, 14)

local fanStroke = Instance.new("UIStroke")
fanStroke.Color = Color3.fromRGB(255, 215, 0)
fanStroke.Thickness = 2.5
fanStroke.Transparency = 1
fanStroke.Parent = fanfareFrame

local fanTitle = Instance.new("TextLabel")
fanTitle.Size = UDim2.new(1, 0, 0, 56)
fanTitle.Position = UDim2.new(0, 0, 0, 16)
fanTitle.BackgroundTransparency = 1
fanTitle.Font = Enum.Font.GothamBlack
fanTitle.TextSize = 36
fanTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
fanTitle.TextTransparency = 1
fanTitle.Text = "🏆 UJIAN SHINOBI LULUS! 🏆"
fanTitle.Parent = fanfareFrame

local fanSub = Instance.new("TextLabel")
fanSub.Size = UDim2.new(1, 0, 0, 30)
fanSub.Position = UDim2.new(0, 0, 0, 72)
fanSub.BackgroundTransparency = 1
fanSub.Font = Enum.Font.GothamBold
fanSub.TextSize = 18
fanSub.TextColor3 = Color3.fromRGB(0, 240, 255)
fanSub.TextTransparency = 1
fanSub.Text = "★ ALL 3 WAVES CLEARED! GRAND BOUNTY CLAIMED ★"
fanSub.Parent = fanfareFrame

local fanReward = Instance.new("TextLabel")
fanReward.Size = UDim2.new(1, 0, 0, 28)
fanReward.Position = UDim2.new(0, 0, 0, 112)
fanReward.BackgroundTransparency = 1
fanReward.Font = Enum.Font.GothamBlack
fanReward.TextSize = 16
fanReward.TextColor3 = Color3.fromRGB(255, 235, 100)
fanReward.TextTransparency = 1
fanReward.Text = "🪙 +500 RYO • 💎 +50 ESSENCE SHARDS"
fanReward.Parent = fanfareFrame

-- =========================================================
-- EVENT LISTENERS
-- =========================================================
local lastBossRatio = 1.0

evWaveStatus.OnClientEvent:Connect(function(data)
	if not data then return end

	local wave = data.Wave or 0
	if wave <= 0 then
		waveDock.Visible = false
		bossBarContainer.Visible = false
		return
	end

	-- Show Wave Dock
	waveDock.Visible = true
	waveTitleLbl.Text = string.format("🌊 GELOMBANG %d / %d: %s", wave, data.MaxWaves or 3, data.Title or "")
	waveSubLbl.Text = string.format("⚔️ Sisa Musuh: %d", data.ActiveCount or 0)

	-- Boss Wave 3
	if data.BossName and data.BossHP then
		bossBarContainer.Visible = true
		bossNameLbl.Text = "👹 " .. string.upper(data.BossName)
		bossHpLbl.Text = string.format("%d / %d HP", data.BossHP, data.BossMaxHP or 750)

		local ratio = math.clamp(data.BossHP / (data.BossMaxHP or 750), 0, 1)
		bossHpFill.Size = UDim2.new(ratio, 0, 1, 0)

		if ratio < lastBossRatio then
			TweenService:Create(bossGhostBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(ratio, 0, 1, 0)
			}):Play()
		else
			bossGhostBar.Size = UDim2.new(ratio, 0, 1, 0)
		end
		lastBossRatio = ratio
	else
		bossBarContainer.Visible = false
	end
end)

evWaveReward.OnClientEvent:Connect(function(res)
	if not res then return end

	if res.Success then
		-- Play victory audio
		playSafeSound("rbxasset://sounds/victory.mp3", 1.0, 1.0)
		playSafeSound("rbxasset://sounds/electronicpingshort.wav", 1.2, 0.8)

		-- Show Fanfare
		fanfareFrame.Visible = true
		fanfareFrame.BackgroundTransparency = 0.2
		fanStroke.Transparency = 0
		fanTitle.TextTransparency = 0
		fanSub.TextTransparency = 0
		fanReward.TextTransparency = 0

		-- Elastic Pulse
		fanfareFrame.Size = UDim2.new(0.95, 0, 0, 190)
		TweenService:Create(fanfareFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.85, 0, 0, 170)
		}):Play()

		task.delay(3.5, function()
			local tw = TweenService:Create(fanfareFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
			TweenService:Create(fanStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			TweenService:Create(fanTitle, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			TweenService:Create(fanSub, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			TweenService:Create(fanReward, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			tw:Play()
			tw.Completed:Connect(function()
				fanfareFrame.Visible = false
			end)
		end)
	end
end)

print("[StormBossHUD] ✅ Dynamic Wave Tracker, Akatsuki Boss HP Bar, and Fanfare active.")
