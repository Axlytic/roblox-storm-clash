--!strict
-- StormFinisherController.luau
-- CLIENT SCRIPT: Cinematic K.O. Finisher, Camera Hitstop, Impact Juice & Announcer
-- Features:
--   • Dynamic Camera FOV Snap Zoom-in on lethal impact (65 -> 50 -> 65)
--   • Brief Anime Impact Freeze (Desaturation + Contrast flash for 0.38s)
--   • Subsonic Audio Explosion & Victory Chime
--   • High-Contrast Anime K.O. Banner Overlay with Gold Glow and Smooth Spring Elastic Punch

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evKO = combatEvents:WaitForChild("KOEvent", 15) :: RemoteEvent

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
-- CREATE K.O. SCREEN GUI
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormFinisherHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 20
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Dark Vignette Overlay
local vignette = Instance.new("Frame")
vignette.Name = "VignetteBackdrop"
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
vignette.BackgroundTransparency = 1
vignette.Parent = screenGui

-- Center Banner Anchor
local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "BannerFrame"
bannerFrame.Size = UDim2.new(0.9, 0, 0, 180)
bannerFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
bannerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bannerFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
bannerFrame.BackgroundTransparency = 1
bannerFrame.Parent = screenGui
Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, 16)

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(255, 30, 60)
bannerStroke.Thickness = 3
bannerStroke.Transparency = 1
bannerStroke.Parent = bannerFrame

-- Main Big "K.O." Text
local koText = Instance.new("TextLabel")
koText.Name = "KOText"
koText.Size = UDim2.new(1, 0, 0, 95)
koText.Position = UDim2.new(0, 0, 0, 10)
koText.BackgroundTransparency = 1
koText.Font = Enum.Font.GothamBlack
koText.TextSize = 88
koText.TextColor3 = Color3.fromRGB(255, 35, 60)
koText.TextTransparency = 1
koText.Text = "⚡ K.O. ⚡"
koText.Parent = bannerFrame

local koStroke = Instance.new("UIStroke")
koStroke.Color = Color3.fromRGB(255, 230, 80)
koStroke.Thickness = 2.5
koStroke.Transparency = 1
koStroke.Parent = koText

-- Subtitle Text ("SHINOBI VICTORY!")
local victoryText = Instance.new("TextLabel")
victoryText.Name = "VictoryText"
victoryText.Size = UDim2.new(1, 0, 0, 36)
victoryText.Position = UDim2.new(0, 0, 0, 105)
victoryText.BackgroundTransparency = 1
victoryText.Font = Enum.Font.GothamBlack
victoryText.TextSize = 26
victoryText.TextColor3 = Color3.fromRGB(255, 220, 50)
victoryText.TextTransparency = 1
victoryText.Text = "★ SHINOBI VICTORY! ★"
victoryText.Parent = bannerFrame

-- Reward Bounty Pill ("+100 RYO EARNED")
local bountyText = Instance.new("TextLabel")
bountyText.Name = "BountyText"
bountyText.Size = UDim2.new(1, 0, 0, 24)
bountyText.Position = UDim2.new(0, 0, 0, 145)
bountyText.BackgroundTransparency = 1
bountyText.Font = Enum.Font.GothamBold
bountyText.TextSize = 15
bountyText.TextColor3 = Color3.fromRGB(0, 240, 255)
bountyText.TextTransparency = 1
bountyText.Text = "🪙 +100 RYO BOUNTY EARNED"
bountyText.Parent = bannerFrame

-- =========================================================
-- CINEMATIC HITSTOP & CAMERA JUICE
-- =========================================================
local function playCinematicKO(isKiller: boolean)
	screenGui.Enabled = true

	-- 1. Camera Snap Zoom (Hitstop feel)
	local curCam = Workspace.CurrentCamera
	if curCam then
		local origFov = curCam.FieldOfView
		curCam.FieldOfView = math.max(48, origFov - 16)
		task.delay(0.25, function()
			TweenService:Create(curCam, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				FieldOfView = origFov,
			}):Play()
		end)
	end

	-- 2. Impact Lighting Pulse
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "KOImpactFilter"
	cc.Contrast = 0.4
	cc.Saturation = -0.25
	cc.TintColor = Color3.fromRGB(255, 230, 210)
	cc.Parent = Lighting

	TweenService:Create(cc, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Contrast = 0,
		Saturation = 0,
		TintColor = Color3.fromRGB(255, 255, 255),
	}):Play()
	task.delay(0.7, function() pcall(function() cc:Destroy() end) end)

	-- 3. Sound Explosion
	playSafeSound("rbxasset://sounds/impact_explosion_03.mp3", 0.85, 1.0)
	playSafeSound("rbxasset://sounds/shattered.mp3", 1.0, 0.9)
	task.delay(0.2, function()
		playSafeSound("rbxasset://sounds/electronicpingshort.wav", 1.2, 0.8)
	end)

	-- 4. Screen Banner Animation
	vignette.BackgroundTransparency = 0.35
	bannerFrame.BackgroundTransparency = 0.15
	bannerStroke.Transparency = 0
	koText.TextTransparency = 0
	koStroke.Transparency = 0
	victoryText.TextTransparency = 0
	bountyText.TextTransparency = 0

	-- Elastic Pop-in
	bannerFrame.Size = UDim2.new(1.1, 0, 0, 210)
	TweenService:Create(bannerFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.85, 0, 0, 180),
	}):Play()

	-- Hold for 2.2s, then smooth fadeout
	task.delay(2.2, function()
		local twFade = TweenService:Create(vignette, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
		TweenService:Create(bannerFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(bannerStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		TweenService:Create(koText, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(koStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		TweenService:Create(victoryText, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(bountyText, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()

		twFade:Play()
		twFade.Completed:Connect(function()
			screenGui.Enabled = false
		end)
	end)
end

-- Listener
evKO.OnClientEvent:Connect(function(data)
	local killerName = data and data.KillerName
	local isKiller = (killerName == LocalPlayer.Name)
	playCinematicKO(isKiller)
end)

print("[StormFinisherController] ✅ Cinematic K.O. Finisher, Ragdoll Camera Juice, and Banner active.")

