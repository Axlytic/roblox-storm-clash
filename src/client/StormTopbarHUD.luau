--!strict
-- StormTopbarHUD.luau
-- CLIENT SCRIPT: Modern Shinobi Topbar & Quick Navigation Dock
-- Features:
--   • Live Ryo (🪙) & Essence Shards (💎) Balance with bounce tweening
--   • Quick Navigation Buttons: Roster [B], Gacha [N], Misi [M], BGM Music
--   • Built-in Anime Battle BGM Jukebox with Mute/Play toggle
--   • Dark Glassmorphism, Zero Clutter, Full Mobile Touch Friendly

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evAddRyo    = combatEvents:WaitForChild("AddCombatRyoEvent", 15) :: RemoteEvent?
local evGachaSync = combatEvents:WaitForChild("GachaSyncEvent", 15) :: RemoteEvent?

-- Safe Sound Helper
local function playClickSound()
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/action_jump.mp3"
			s.PlaybackSpeed = 1.3
			s.Volume = 0.5
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
screenGui.Name = "StormTopbarHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = PlayerGui

-- Main Container (Top-Left Dock)
local dockContainer = Instance.new("Frame")
dockContainer.Name = "TopLeftDock"
dockContainer.Size = UDim2.new(0, 660, 0, 44)
dockContainer.Position = UDim2.new(0, 16, 0, 14)
dockContainer.BackgroundTransparency = 1
dockContainer.Parent = screenGui

local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
dockLayout.Padding = UDim.new(0, 10)
dockLayout.Parent = dockContainer

-- =========================================================
-- 1. CURRENCY PILL (🪙 Ryo & 💎 Shards)
-- =========================================================
local currencyPill = Instance.new("Frame")
currencyPill.Name = "CurrencyPill"
currencyPill.Size = UDim2.new(0, 190, 1, 0)
currencyPill.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
currencyPill.BackgroundTransparency = 0.25
currencyPill.LayoutOrder = 1
currencyPill.Parent = dockContainer
Instance.new("UICorner", currencyPill).CornerRadius = UDim.new(0, 22)

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = Color3.fromRGB(255, 205, 50)
pillStroke.Thickness = 1.5
pillStroke.Parent = currencyPill

local ryoLabel = Instance.new("TextLabel")
ryoLabel.Name = "RyoLabel"
ryoLabel.Size = UDim2.new(0.55, 0, 1, 0)
ryoLabel.Position = UDim2.new(0, 12, 0, 0)
ryoLabel.BackgroundTransparency = 1
ryoLabel.Font = Enum.Font.GothamBlack
ryoLabel.TextSize = 13
ryoLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
ryoLabel.TextXAlignment = Enum.TextXAlignment.Left
ryoLabel.Text = "🪙 300 RYO"
ryoLabel.Parent = currencyPill

local shardsLabel = Instance.new("TextLabel")
shardsLabel.Name = "ShardsLabel"
shardsLabel.Size = UDim2.new(0.42, 0, 1, 0)
shardsLabel.Position = UDim2.new(0.55, 0, 0, 0)
shardsLabel.BackgroundTransparency = 1
shardsLabel.Font = Enum.Font.GothamBlack
shardsLabel.TextSize = 13
shardsLabel.TextColor3 = Color3.fromRGB(0, 235, 255)
shardsLabel.TextXAlignment = Enum.TextXAlignment.Left
shardsLabel.Text = "💎 0"
shardsLabel.Parent = currencyPill

-- Helper: Animate Currency Gain
local function animateRyoGain(amount: number)
	local tw1 = TweenService:Create(currencyPill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(45, 38, 20),
	})
	local tw2 = TweenService:Create(currencyPill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(15, 18, 28),
	})
	tw1:Play()
	tw1.Completed:Connect(function() tw2:Play() end)
end

-- =========================================================
-- 2. NAVIGATION DOCK BUTTONS
-- =========================================================
local function createNavButton(name: string, iconText: string, hotkey: string, order: number, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "NavBtn_" .. name
	btn.Size = UDim2.new(0, 72, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	btn.BackgroundTransparency = 0.25
	btn.LayoutOrder = order
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = iconText
	btn.AutoButtonColor = false
	btn.Parent = dockContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(50, 60, 85)
	bStroke.Thickness = 1.2
	bStroke.Parent = btn

	-- Hover & Click Micro-interactions
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(28, 35, 55),
		}):Play()
		bStroke.Color = Color3.fromRGB(0, 240, 255)
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(18, 22, 34),
		}):Play()
		bStroke.Color = Color3.fromRGB(50, 60, 85)
	end)

	btn.MouseButton1Click:Connect(function()
		playClickSound()
		onClick()
	end)

	return btn
end

-- Button 1: Roster [B]
createNavButton("Roster", "👥 ROSTER", "B", 2, function()
	local charSelectGui = PlayerGui:FindFirstChild("StormCharacterSelectHUD") :: ScreenGui?
	if charSelectGui then
		charSelectGui.Enabled = not charSelectGui.Enabled
	end
end)

-- Button 2: Gacha [N]
createNavButton("Gacha", "⛩️ GACHA", "N", 3, function()
	local gachaGui = PlayerGui:FindFirstChild("StormGachaHUD") :: ScreenGui?
	if gachaGui then
		gachaGui.Enabled = not gachaGui.Enabled
	end
end)

-- Button 3: Misi [M]
createNavButton("Quests", "📜 MISI", "M", 4, function()
	if _G.ToggleQuestHUD then
		_G.ToggleQuestHUD()
	else
		local questGui = PlayerGui:FindFirstChild("StormDailyQuestHUD") :: ScreenGui?
		if questGui then
			questGui.Enabled = not questGui.Enabled
		end
	end
end)

-- Button 4: Gelar / Titles & Kill Effects [K]
createNavButton("Cosmetics", "✨ GELAR", "K", 5, function()
	if _G.ToggleCosmeticsHUD then
		_G.ToggleCosmeticsHUD()
	else
		local cosGui = PlayerGui:FindFirstChild("StormCosmeticsHUD") :: ScreenGui?
		if cosGui then
			cosGui.Enabled = not cosGui.Enabled
		end
	end
end)

-- Button 5: Ranked 1v1 PvP Duel [P]
createNavButton("Duel", "⚔️ 1v1", "P", 6, function()
	if _G.ToggleDuelHUD then
		_G.ToggleDuelHUD()
	else
		local duelGui = PlayerGui:FindFirstChild("StormDuelHUD") :: ScreenGui?
		if duelGui then
			duelGui.Enabled = not duelGui.Enabled
		end
	end
end)

-- =========================================================
-- 3. ANIME BATTLE BGM JUKEBOX & MUTE TOGGLE
-- =========================================================
local bgmSound = Instance.new("Sound")
bgmSound.Name = "StormAnimeBGM"
-- Standard energetic fighting game sound asset (built-in Roblox soundtrack)
bgmSound.SoundId = "rbxassetid://1843528859" -- Epic Anime Battle Theme
bgmSound.Looped = true
bgmSound.Volume = 0.28
bgmSound.Parent = SoundService

local isBgmPlaying = true
pcall(function() bgmSound:Play() end)

local bgmBtn = createNavButton("BGM", "🎵 BGM", "", 7, function()
	isBgmPlaying = not isBgmPlaying
	if isBgmPlaying then
		bgmSound.Volume = 0.28
		bgmSound:Resume()
	else
		bgmSound.Volume = 0
		bgmSound:Pause()
	end
end)

-- =========================================================
-- LIVE ATTRIBUTE & REMOTE SYNC
-- =========================================================
local function updateBalances()
	local ryo = LocalPlayer:GetAttribute("RyoValue") or 300
	local shards = LocalPlayer:GetAttribute("EssenceShards") or 0
	ryoLabel.Text = string.format("🪙 %s RYO", tostring(ryo))
	shardsLabel.Text = string.format("💎 %s", tostring(shards))
end

LocalPlayer:GetAttributeChangedSignal("RyoValue"):Connect(function()
	updateBalances()
	animateRyoGain(0)
end)
LocalPlayer:GetAttributeChangedSignal("EssenceShards"):Connect(updateBalances)

if evAddRyo then
	evAddRyo.OnClientEvent:Connect(function(amount: number, reason: string?)
		updateBalances()
		animateRyoGain(amount)
	end)
end

if evGachaSync then
	evGachaSync.OnClientEvent:Connect(function(prof: any)
		if prof then
			if prof.Ryo then LocalPlayer:SetAttribute("RyoValue", prof.Ryo) end
			if prof.EssenceShards then LocalPlayer:SetAttribute("EssenceShards", prof.EssenceShards) end
			updateBalances()
		end
	end)
end

updateBalances()
print("[StormTopbarHUD] ✅ Sleek Shinobi Topbar & Quick Dock loaded. Roster [B], Gacha [N], Misi [M].")

