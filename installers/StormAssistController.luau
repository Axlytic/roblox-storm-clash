local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormAssistController')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormAssistController'
s.Source = [=====[--!strict
-- StormAssistController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Assist Striker Summon & Leader Swap
-- Features:
--   • Assist System:
--       [T] Key or Gamepad L1: Summon Assist Partner (Flame Bullet / Lightning Jutsu)
--       [U] Key or [G] or Gamepad L2: Leader Swap (Tag-out partner combo continuation)
--   • Note: [I] is strictly reserved for Chakra Charge & Ultimate Jutsu!
--   • Mobile Touch Support via Custom BindableEvent
--   • Assist Gauge HUD with real-time countdown & speedline flash on tag

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera :: Camera

-- Configuration
local ASSIST_COOLDOWN = 20
local lastAssistTime = -ASSIST_COOLDOWN
local isAssistAvailable = true

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local evAssist = combatEvents and combatEvents:FindFirstChild("AssistEvent") :: RemoteEvent?
local evLeaderSwap = combatEvents and combatEvents:FindFirstChild("LeaderSwapEvent") :: RemoteEvent?

-- Mobile/UI Bindable Integration
local evMobileAssist = ReplicatedStorage:FindFirstChild("MobileAssistAction") :: BindableEvent?
if not evMobileAssist then
	evMobileAssist = Instance.new("BindableEvent")
	evMobileAssist.Name = "MobileAssistAction"
	evMobileAssist.Parent = ReplicatedStorage
end

local evMobileSwap = ReplicatedStorage:FindFirstChild("MobileSwapAction") :: BindableEvent?
if not evMobileSwap then
	evMobileSwap = Instance.new("BindableEvent")
	evMobileSwap.Name = "MobileSwapAction"
	evMobileSwap.Parent = ReplicatedStorage
end

-- =========================================================
-- ASSIST GAUGE HUD
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormAssistHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local card = Instance.new("Frame")
card.Name = "AssistCard"
card.Size = UDim2.new(0, 195, 0, 52)
card.Position = UDim2.new(0, 24, 0.88, -26)
card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
card.BackgroundTransparency = 0.15
card.BorderSizePixel = 0
card.Parent = screenGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(0, 255, 200)
cardStroke.Thickness = 2
cardStroke.Parent = card

-- Portrait Box
local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 40, 0, 40)
iconBox.Position = UDim2.new(0, 6, 0.5, -20)
iconBox.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
iconBox.BorderSizePixel = 0
iconBox.Parent = card
Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 8)

local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.fromScale(1, 1)
iconText.BackgroundTransparency = 1
iconText.Text = "⚡"
iconText.TextSize = 22
iconText.Parent = iconBox

-- Assist Name & Key Hint
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -55, 0, 18)
nameLabel.Position = UDim2.new(0, 52, 0, 6)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "ASSIST [T / L1]: SHADOW STRIKER"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 9.5
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = card

-- Cooldown Bar
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -58, 0, 8)
barBg.Position = UDim2.new(0, 52, 0, 26)
barBg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
barBg.BorderSizePixel = 0
barBg.Parent = card
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

local swapLabel = Instance.new("TextLabel")
swapLabel.Size = UDim2.new(1, -55, 0, 12)
swapLabel.Position = UDim2.new(0, 52, 0, 36)
swapLabel.BackgroundTransparency = 1
swapLabel.Text = "TAG SWAP [U / G] READY"
swapLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
swapLabel.Font = Enum.Font.GothamMedium
swapLabel.TextSize = 9
swapLabel.TextXAlignment = Enum.TextXAlignment.Left
swapLabel.Parent = card

-- =========================================================
-- CALL ASSIST STRIKER
-- =========================================================
local function callAssistStriker()
	local now = os.clock()
	if now - lastAssistTime < ASSIST_COOLDOWN then
		print(">> [Assist] On cooldown! <<")
		return
	end

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	lastAssistTime = now
	isAssistAvailable = false

	-- Animate Assist HUD Cooldown
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	cardStroke.Color = Color3.fromRGB(100, 100, 100)

	-- Fire to server
	if evAssist then
		evAssist:FireServer("FireballStriker")
	end

	-- Sound
	pcall(function()
		local callSnd = Instance.new("Sound")
		callSnd.SoundId = "rbxasset://sounds/volume_slider.ogg"
		callSnd.PlaybackSpeed = 1.8
		callSnd.Volume = 0.9
		callSnd.Parent = root
		callSnd:Play()
		task.delay(0.5, function() pcall(function() callSnd:Destroy() end) end)
	end)

	print(">> [Storm Assist] Sasuke / Shadow Striker summoned! <<")

	-- Cooldown restoration loop
	task.spawn(function()
		while true do
			task.wait(0.1)
			local elapsed = os.clock() - lastAssistTime
			local progress = math.clamp(elapsed / ASSIST_COOLDOWN, 0, 1)
			barFill.Size = UDim2.new(progress, 0, 1, 0)

			if progress >= 1 then
				barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
				cardStroke.Color = Color3.fromRGB(0, 255, 200)
				isAssistAvailable = true
				break
			end
		end
	end)
end

-- =========================================================
-- LEADER SWAP (Press U / G / Gamepad L2)
-- =========================================================
local function executeLeaderSwap()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Screen Flash / Speedline effect
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.4
	flash.BorderSizePixel = 0
	flash.Parent = screenGui

	local tw = TweenService:Create(flash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function() flash:Destroy() end)

	-- Swap Sound
	pcall(function()
		local swapSnd = Instance.new("Sound")
		swapSnd.SoundId = "rbxasset://sounds/action_jump.mp3"
		swapSnd.PlaybackSpeed = 1.6
		swapSnd.Volume = 1
		swapSnd.Parent = root
		swapSnd:Play()
		task.delay(0.5, function() pcall(function() swapSnd:Destroy() end) end)
	end)

	if evLeaderSwap then
		evLeaderSwap:FireServer()
	end

	print(">> [Storm 4 LEADER SWAP] Tagged in Partner! Combo Synergy active! <<")
end

-- =========================================================
-- MULTI-PLATFORM INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- 1. Assist Summon with [T] or Gamepad ButtonL1 (Note: [I] is reserved for Chakra/Ult)
	if input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.ButtonL1 then
		callAssistStriker()
	-- 2. Leader Swap with [U] or [G] or Gamepad ButtonL2
	elseif input.KeyCode == Enum.KeyCode.U or input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonL2 then
		executeLeaderSwap()
	end
end)

-- Mobile Touch Integration
if evMobileAssist then
	evMobileAssist.Event:Connect(function()
		callAssistStriker()
	end)
end

if evMobileSwap then
	evMobileSwap.Event:Connect(function()
		executeLeaderSwap()
	end)
end

print("[StormAssistController] ✅ Loaded — Assist [T] / Gamepad (L1), Leader Swap [U] / [G] / Gamepad (L2).")
]=====]
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormAssistController'
