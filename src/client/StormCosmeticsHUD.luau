--!strict
-- StormCosmeticsHUD.luau
-- CLIENT SCRIPT: Modern Shinobi Titles & K.O. Kill Effects Selection Modal
-- Design: Dark Glassmorphism, Dual-Tab Layout, Realtime Equip & Sound Effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CosmeticsConfig = require(ReplicatedStorage:WaitForChild("CosmeticsConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evEquipCosmetic = combatEvents:WaitForChild("EquipCosmeticEvent", 15) :: RemoteEvent
local evSyncCosmetic  = combatEvents:WaitForChild("SyncCosmeticEvent", 15) :: RemoteEvent

-- State
local isOpen = false
local currentTab = "Titles" -- "Titles" or "KillEffects"
local cosmeticProfile: any = nil

local function playUiSound(soundId: string, pitch: number?)
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = soundId
			s.PlaybackSpeed = pitch or 1.0
			s.Volume = 0.5
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
screenGui.Name = "StormCosmeticsHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 12
screenGui.Enabled = false
screenGui.Parent = PlayerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "CosmeticsBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainModal"
mainFrame.Size = UDim2.new(0.80, 0, 0.80, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = backdrop
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(190, 80, 255)
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

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0.4, 0, 1, 0)
titleLbl.Position = UDim2.new(0, 24, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 20
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Text = "✨ SHINOBI TITLES & KILL FX"
titleLbl.Parent = header

-- Tab Switcher
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(0.40, 0, 0, 36)
tabContainer.Position = UDim2.new(0.44, 0, 0.5, 0)
tabContainer.AnchorPoint = Vector2.new(0, 0.5)
tabContainer.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
tabContainer.Parent = header
Instance.new("UICorner", tabContainer).CornerRadius = UDim.new(0, 8)

local btnTitlesTab = Instance.new("TextButton")
btnTitlesTab.Name = "TabTitles"
btnTitlesTab.Size = UDim2.new(0.5, -4, 1, -6)
btnTitlesTab.Position = UDim2.new(0, 3, 0.5, 0)
btnTitlesTab.AnchorPoint = Vector2.new(0, 0.5)
btnTitlesTab.BackgroundColor3 = Color3.fromRGB(190, 80, 255)
btnTitlesTab.Font = Enum.Font.GothamBold
btnTitlesTab.TextSize = 12
btnTitlesTab.TextColor3 = Color3.fromRGB(10, 15, 24)
btnTitlesTab.Text = "👑 GELAR SHINOBI"
btnTitlesTab.Parent = tabContainer
Instance.new("UICorner", btnTitlesTab).CornerRadius = UDim.new(0, 6)

local btnFxTab = Instance.new("TextButton")
btnFxTab.Name = "TabEffects"
btnFxTab.Size = UDim2.new(0.5, -4, 1, -6)
btnFxTab.Position = UDim2.new(0.5, 1, 0.5, 0)
btnFxTab.AnchorPoint = Vector2.new(0, 0.5)
btnFxTab.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
btnFxTab.Font = Enum.Font.GothamBold
btnFxTab.TextSize = 12
btnFxTab.TextColor3 = Color3.fromRGB(180, 190, 210)
btnFxTab.Text = "💥 EFEK K.O."
btnFxTab.Parent = tabContainer
Instance.new("UICorner", btnFxTab).CornerRadius = UDim.new(0, 6)

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
-- BODY CONTAINER: CARDS GRID
-- =========================================================
local bodyScroll = Instance.new("ScrollingFrame")
bodyScroll.Name = "BodyScroll"
bodyScroll.Size = UDim2.new(1, -40, 1, -78)
bodyScroll.Position = UDim2.new(0, 20, 0, 68)
bodyScroll.BackgroundTransparency = 1
bodyScroll.ScrollBarThickness = 6
bodyScroll.ScrollBarImageColor3 = Color3.fromRGB(190, 80, 255)
bodyScroll.CanvasSize = UDim2.new(0, 0, 0, 480)
bodyScroll.Parent = mainFrame

local bGridLayout = Instance.new("UIGridLayout")
bGridLayout.CellSize = UDim2.new(0.485, 0, 0, 88)
bGridLayout.CellPadding = UDim2.new(0.03, 0, 0, 12)
bGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
bGridLayout.Parent = bodyScroll

-- =========================================================
-- RENDER FUNCTIONS
-- =========================================================
local function renderTitles()
	for _, child in ipairs(bodyScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local curEquipped = LocalPlayer:GetAttribute("EquippedTitle") or "GeninRookie"

	for idx, def in ipairs(CosmeticsConfig.Titles) do
		local card = Instance.new("Frame")
		card.Name = "TitleCard_" .. def.Id
		card.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
		card.BackgroundTransparency = 0.2
		card.LayoutOrder = idx
		card.Parent = bodyScroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = (def.Id == curEquipped) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 55, 75)
		cardStroke.Thickness = (def.Id == curEquipped) and 2.5 or 1.2
		cardStroke.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -120, 0, 24)
		nameLbl.Position = UDim2.new(0, 14, 0, 12)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = def.Color
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = def.Name
		nameLbl.Parent = card

		local reqLbl = Instance.new("TextLabel")
		reqLbl.Size = UDim2.new(1, -120, 0, 36)
		reqLbl.Position = UDim2.new(0, 14, 0, 38)
		reqLbl.BackgroundTransparency = 1
		reqLbl.Font = Enum.Font.GothamMedium
		reqLbl.TextSize = 11
		reqLbl.TextColor3 = Color3.fromRGB(160, 175, 200)
		reqLbl.TextXAlignment = Enum.TextXAlignment.Left
		reqLbl.TextWrapped = true
		reqLbl.Text = def.ReqDesc
		reqLbl.Parent = card

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0, 95, 0, 38)
		equipBtn.Position = UDim2.new(1, -105, 0.5, 0)
		equipBtn.AnchorPoint = Vector2.new(0, 0.5)
		equipBtn.Parent = card
		Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 8)

		if def.Id == curEquipped then
			equipBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
			equipBtn.Font = Enum.Font.GothamBlack
			equipBtn.TextSize = 11
			equipBtn.TextColor3 = Color3.fromRGB(10, 15, 24)
			equipBtn.Text = "✓ TERPASANG"
			equipBtn.Active = false
		else
			equipBtn.BackgroundColor3 = Color3.fromRGB(190, 80, 255)
			equipBtn.Font = Enum.Font.GothamBold
			equipBtn.TextSize = 12
			equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipBtn.Text = "PASANG"
			equipBtn.Active = true

			equipBtn.MouseButton1Click:Connect(function()
				playUiSound("rbxasset://sounds/action_jump.mp3", 1.2)
				evEquipCosmetic:FireServer("Title", def.Id)
				task.delay(0.2, renderTitles)
			end)
		end
	end
end

local function renderKillEffects()
	for _, child in ipairs(bodyScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local curEquipped = LocalPlayer:GetAttribute("EquippedKillEffect") or "ClassicSmoke"

	for idx, def in ipairs(CosmeticsConfig.KillEffects) do
		local card = Instance.new("Frame")
		card.Name = "FxCard_" .. def.Id
		card.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
		card.BackgroundTransparency = 0.2
		card.LayoutOrder = idx
		card.Parent = bodyScroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = (def.Id == curEquipped) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 55, 75)
		cardStroke.Thickness = (def.Id == curEquipped) and 2.5 or 1.2
		cardStroke.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -120, 0, 24)
		nameLbl.Position = UDim2.new(0, 14, 0, 12)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = def.Color
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = def.Name
		nameLbl.Parent = card

		local reqLbl = Instance.new("TextLabel")
		reqLbl.Size = UDim2.new(1, -120, 0, 36)
		reqLbl.Position = UDim2.new(0, 14, 0, 38)
		reqLbl.BackgroundTransparency = 1
		reqLbl.Font = Enum.Font.GothamMedium
		reqLbl.TextSize = 11
		reqLbl.TextColor3 = Color3.fromRGB(160, 175, 200)
		reqLbl.TextXAlignment = Enum.TextXAlignment.Left
		reqLbl.TextWrapped = true
		reqLbl.Text = def.ReqDesc
		reqLbl.Parent = card

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0, 95, 0, 38)
		equipBtn.Position = UDim2.new(1, -105, 0.5, 0)
		equipBtn.AnchorPoint = Vector2.new(0, 0.5)
		equipBtn.Parent = card
		Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 8)

		if def.Id == curEquipped then
			equipBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
			equipBtn.Font = Enum.Font.GothamBlack
			equipBtn.TextSize = 11
			equipBtn.TextColor3 = Color3.fromRGB(10, 15, 24)
			equipBtn.Text = "✓ TERPASANG"
			equipBtn.Active = false
		else
			equipBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
			equipBtn.Font = Enum.Font.GothamBold
			equipBtn.TextSize = 12
			equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipBtn.Text = "PASANG"
			equipBtn.Active = true

			equipBtn.MouseButton1Click:Connect(function()
				playUiSound("rbxasset://sounds/action_jump.mp3", 1.2)
				evEquipCosmetic:FireServer("KillEffect", def.Id)
				task.delay(0.2, renderKillEffects)
			end)
		end
	end
end

-- =========================================================
-- TAB SWITCHING & MODAL CONTROLS
-- =========================================================
local function switchTab(tab: string)
	currentTab = tab
	playUiSound("rbxasset://sounds/action_jump.mp3", 1.1)

	if tab == "Titles" then
		btnTitlesTab.BackgroundColor3 = Color3.fromRGB(190, 80, 255)
		btnTitlesTab.TextColor3 = Color3.fromRGB(10, 15, 24)
		btnFxTab.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
		btnFxTab.TextColor3 = Color3.fromRGB(180, 190, 210)
		renderTitles()
	else
		btnFxTab.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
		btnFxTab.TextColor3 = Color3.fromRGB(10, 15, 24)
		btnTitlesTab.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
		btnTitlesTab.TextColor3 = Color3.fromRGB(180, 190, 210)
		renderKillEffects()
	end
end

btnTitlesTab.MouseButton1Click:Connect(function() switchTab("Titles") end)
btnFxTab.MouseButton1Click:Connect(function() switchTab("KillEffects") end)

local function toggleCosmeticsModal(state: boolean?)
	isOpen = if state ~= nil then state else not isOpen
	screenGui.Enabled = isOpen
	playUiSound("rbxasset://sounds/action_jump.mp3", if isOpen then 1.0 else 0.8)

	if isOpen then
		if currentTab == "Titles" then
			renderTitles()
		else
			renderKillEffects()
		end
	end
end

closeBtn.MouseButton1Click:Connect(function() toggleCosmeticsModal(false) end)

-- Keyboard [K] Key (Kosmetik)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.K then
		toggleCosmeticsModal()
	end
end)

_G.ToggleCosmeticsHUD = function()
	toggleCosmeticsModal()
end

renderTitles()
print("[StormCosmeticsHUD] ✅ Shinobi Titles & Kill FX HUD active. Hotkey [K].")

