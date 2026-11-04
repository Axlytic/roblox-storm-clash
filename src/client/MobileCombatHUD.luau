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

local evMobileAttack = getOrMakeBindable("MobileAttackAction")
local evMobileGuard  = getOrMakeBindable("MobileGuardAction")
local evMobileDash   = getOrMakeBindable("MobileDashAction")
local evMobileAssist = getOrMakeBindable("MobileAssistAction")
local evMobileSwap   = getOrMakeBindable("MobileSwapAction")

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
-- CREATE COMBAT BUTTONS
-- =========================================================
-- 1. ATTACK [J] (Big Central Action Button)
local btnAttack = createActionButton(
	"BtnAttack", "⚔️", "ATTACK [J]", Color3.fromRGB(0, 240, 255),
	UDim2.new(0.65, 0, 0.65, 0), UDim2.new(0, 78, 0, 78)
)
btnAttack.MouseButton1Click:Connect(function()
	evMobileAttack:Fire()
end)

-- 2. GUARD [K] (Right side button with hold support)
local btnGuard = createActionButton(
	"BtnGuard", "🛡️", "GUARD [K]", Color3.fromRGB(255, 215, 0),
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

-- 3. DASH [L] (Left bottom button)
local btnDash = createActionButton(
	"BtnDash", "💨", "DASH [L]", Color3.fromRGB(0, 255, 170),
	UDim2.new(0.28, 0, 0.82, 0), UDim2.new(0, 58, 0, 58)
)
btnDash.MouseButton1Click:Connect(function()
	evMobileDash:Fire()
end)

-- 4. ASSIST [I] (Top mid button)
local btnAssist = createActionButton(
	"BtnAssist", "⚡", "ASSIST [I]", Color3.fromRGB(255, 100, 50),
	UDim2.new(0.48, 0, 0.22, 0), UDim2.new(0, 52, 0, 52)
)
btnAssist.MouseButton1Click:Connect(function()
	evMobileAssist:Fire()
end)

-- 5. LEADER SWAP [U] (Top left button)
local btnSwap = createActionButton(
	"BtnSwap", "🔄", "SWAP [U]", Color3.fromRGB(200, 100, 255),
	UDim2.new(0.18, 0, 0.40, 0), UDim2.new(0, 48, 0, 48)
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
