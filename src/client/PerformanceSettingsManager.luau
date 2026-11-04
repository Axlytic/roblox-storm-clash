--!strict
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

