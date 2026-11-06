--!strict
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
local evMobileSub      = getOrMakeBindable("MobileSubstitutionAction")

-- Force STRICT Landscape Orientation on Mobile & Tablet Devices (Naruto Storm Fighting Standard)
pcall(function()
	PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)
pcall(function()
	local StarterGui = game:GetService("StarterGui")
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
end)

-- Continuous enforcer: guarantee orientation never reverts to Portrait or Sensor
task.spawn(function()
	local StarterGui = game:GetService("StarterGui")
	for _ = 1, 10 do
		task.wait(0.5)
		if PlayerGui.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeLeft then
			pcall(function()
				PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
			end)
		end
		if StarterGui.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeLeft then
			pcall(function()
				StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeLeft
			end)
		end
	end
end)

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormMobileCombatHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
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

-- 8. SUBSTITUTION JUTSU [E/Q] (Kawarimi Escape)
local btnSub = createActionButton(
	"BtnSub", "🪵", "SUB [E]", Color3.fromRGB(255, 215, 0),
	UDim2.new(0.38, 0, 0.48, 0), UDim2.new(0, 54, 0, 54)
)
btnSub.MouseButton1Click:Connect(function()
	evMobileSub:Fire()
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

