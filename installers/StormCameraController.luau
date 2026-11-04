local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormCameraController')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormCameraController'
s.Source = [=====[--!strict
-- StormCameraController.luau
-- CLIENT SCRIPT: Dynamic 3D Lock-On Arena Camera (Naruto Shippuden: Ultimate Ninja Storm 4 Style)
-- Features:
--   • Dual-Target Dynamic Midpoint Framing (Player & Opponent framed simultaneously)
--   • Adaptive Zoom based on distance
--   • Vertical tilt compensation for airborne combos
--   • Dynamic FOV expansion during Ninja Dash
--   • Cyber-Anime Lock-On Crosshair HUD Reticle
--   • Toggle Lock-On with 'Z' key or Middle Click

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera

-- Camera Parameters
local MIN_DIST = 14
local MAX_DIST = 46
local BASE_HEIGHT = 6.2
local HEIGHT_AIR_FACTOR = 0.38
local SIDE_OFFSET = 3.4
local SMOOTH_SPEED = 12
local FOV_DEFAULT = 65
local FOV_DASHING = 76

local isLockOnActive = true
local currentTarget: Model? = nil

-- =========================================================
-- CYBER-ANIME LOCK-ON RETICLE HUD
-- =========================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local reticleGui = Instance.new("ScreenGui")
reticleGui.Name = "StormReticleGUI"
reticleGui.ResetOnSpawn = false
reticleGui.Parent = playerGui

local reticleFrame = Instance.new("Frame")
reticleFrame.Name = "ReticleContainer"
reticleFrame.Size = UDim2.new(0, 56, 0, 56)
reticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
reticleFrame.BackgroundTransparency = 1
reticleFrame.Visible = false
reticleFrame.Parent = reticleGui

-- Outer Ring
local outerRing = Instance.new("Frame")
outerRing.Size = UDim2.fromScale(1, 1)
outerRing.BackgroundTransparency = 1
outerRing.Parent = reticleFrame
Instance.new("UICorner", outerRing).CornerRadius = UDim.new(1, 0)
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(0, 240, 255)
outerStroke.Thickness = 2
outerStroke.Parent = outerRing

-- Inner Diamond
local innerDiamond = Instance.new("Frame")
innerDiamond.Size = UDim2.fromScale(0.35, 0.35)
innerDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
innerDiamond.Position = UDim2.fromScale(0.5, 0.5)
innerDiamond.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
innerDiamond.BackgroundTransparency = 0.2
innerDiamond.Rotation = 45
innerDiamond.BorderSizePixel = 0
innerDiamond.Parent = reticleFrame
Instance.new("UICorner", innerDiamond).CornerRadius = UDim.new(0, 3)

-- 4 Crosshair Ticks
local function createTick(angle: number)
	local tick = Instance.new("Frame")
	tick.Size = UDim2.new(0, 2, 0, 8)
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
	tick.BorderSizePixel = 0
	local rad = math.rad(angle)
	tick.Position = UDim2.new(0.5 + math.cos(rad) * 0.58, 0, 0.5 + math.sin(rad) * 0.58, 0)
	tick.Parent = reticleFrame
end
createTick(0)
createTick(90)
createTick(180)
createTick(270)

-- =========================================================
-- TARGET ACQUISITION
-- =========================================================
local function findNearestTarget(): Model?
	local myChar = LocalPlayer.Character
	if not myChar then return nil end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return nil end

	local bestTarget: Model? = nil
	local closestDist = 120

	-- 1. Check Training Dummy
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") and dummy:FindFirstChild("HumanoidRootPart") then
		local dRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
		local dist = (dRoot.Position - myRoot.Position).Magnitude
		if dist < closestDist then
			closestDist = dist
			bestTarget = dummy
		end
	end

	-- 2. Check Other Players
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local root = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = (root.Position - myRoot.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					bestTarget = p.Character
				end
			end
		end
	end

	return bestTarget
end

-- Update Reticle Screen Position
local function updateReticle(target: Model?)
	if not target or not isLockOnActive then
		reticleFrame.Visible = false
		return
	end

	local root = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		reticleFrame.Visible = false
		return
	end

	local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 1.2, 0))
	if onScreen then
		reticleFrame.Visible = true
		reticleFrame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
		outerRing.Rotation = (outerRing.Rotation + 1.5) % 360
		innerDiamond.Rotation = (innerDiamond.Rotation - 2) % 360
	else
		reticleFrame.Visible = false
	end
end

-- =========================================================
-- DYNAMIC CAMERA UPDATE
-- =========================================================
local currentCamPos = Vector3.zero
local currentCamFocus = Vector3.zero

local function onRenderStep(dt: number)
	local myChar = LocalPlayer.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return end

	-- Find or retain target
	if not currentTarget or not currentTarget.Parent then
		currentTarget = findNearestTarget()
	end

	updateReticle(currentTarget)

	if not isLockOnActive or not currentTarget then
		if Camera.CameraType == Enum.CameraType.Scriptable then
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = FOV_DEFAULT
		end
		return
	end

	local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		Camera.CameraType = Enum.CameraType.Custom
		return
	end

	-- Activate Scriptable Camera for Storm 4 Dynamic Dual Framing
	if Camera.CameraType ~= Enum.CameraType.Scriptable then
		Camera.CameraType = Enum.CameraType.Scriptable
		currentCamPos = Camera.CFrame.Position
		currentCamFocus = myRoot.Position
	end

	local pPos = myRoot.Position
	local tPos = targetRoot.Position

	-- 1. Midpoint between Player and Opponent
	local midpoint = (pPos + tPos) * 0.5

	-- 2. Distance and adaptive zoom
	local diff = (tPos - pPos)
	local dist = diff.Magnitude
	local clampedDist = math.clamp(dist * 0.95 + 8, MIN_DIST, MAX_DIST)

	-- 3. Direction vectors
	local lookDir = if dist > 0.1 then diff.Unit else Vector3.new(0, 0, -1)
	local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
	local rightDir = Vector3.new(-flatDir.Z, 0, flatDir.X) -- Perpendicular lateral vector

	-- 4. Vertical air height compensation
	local verticalOffset = math.max(0, math.max(pPos.Y, tPos.Y) - 50) * HEIGHT_AIR_FACTOR

	-- 5. Calculate ideal Camera Position (behind Player, offset laterally for over-shoulder cinematic view)
	local targetCamPos = pPos - (flatDir * clampedDist) + Vector3.new(0, BASE_HEIGHT + verticalOffset, 0) + (rightDir * SIDE_OFFSET)

	-- 6. Calculate ideal Camera Focus (looking slightly toward midpoint and target)
	local targetFocus = midpoint + Vector3.new(0, 1.5 + verticalOffset * 0.5, 0)

	-- 7. Smooth Interpolation (Lerp)
	local lerpFactor = math.clamp(dt * SMOOTH_SPEED, 0, 1)
	currentCamPos = currentCamPos:Lerp(targetCamPos, lerpFactor)
	currentCamFocus = currentCamFocus:Lerp(targetFocus, lerpFactor)

	Camera.CFrame = CFrame.lookAt(currentCamPos, currentCamFocus)

	-- Dynamic FOV adjustment during Ninja Dash
	local isDashing = LocalPlayer:GetAttribute("IsNinjaDashing") == true
	local targetFOV = isDashing and FOV_DASHING or FOV_DEFAULT
	Camera.FieldOfView = Camera.FieldOfView + (targetFOV - Camera.FieldOfView) * math.clamp(dt * 8, 0, 1)
end

RunService:BindToRenderStep("StormLockOnCamera", Enum.RenderPriority.Camera.Value + 1, onRenderStep)

-- Toggle Lock-On with Key 'Z' or Middle Click
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Z or input.UserInputType == Enum.UserInputType.MouseButton3 then
		isLockOnActive = not isLockOnActive
		if isLockOnActive then
			currentTarget = findNearestTarget()
		else
			currentTarget = nil
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = FOV_DEFAULT
		end
		print(">> [Storm Camera] Lock-On:", isLockOnActive and "ON" or "OFF", "<<")
	end
end)

print("[StormCameraController] ✅ Loaded — Press 'Z' to toggle Naruto Storm 4 Lock-On Camera.")
]=====]
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormCameraController'
