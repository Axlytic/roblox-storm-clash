--!strict
-- StormCameraController.luau
-- CLIENT SCRIPT: Dynamic CyberConnect2 Anime Camera (Naruto x Boruto Storm Connections Style)
-- Features:
--   • Dual-Target Dynamic Framing: Frames both fighters seamlessly in 3D space
--   • Combo Dynamic Zoom: Camera pushes in tighter as combo hits chain together (rising tension)
--   • Skyward Launcher Pitch: Tilts up (+22°) during Up Combos & Air Chases to capture airborne combat
--   • Downward Ground Slam Pitch: Tilts down (-18°) on meteor spikes & ground bounces
--   • Dash FOV Expansion & Speedline Vignette: Dynamic FOV transition (65 -> 76) during Ninja Dash & CDC
--   • Subtle Dutch Angle Tilt on Heavy Finishers (2.5° cinematic roll)
--   • Ground Collision Avoidance: Guarantees camera never clips below the arena floor
--   • Cyber-Anime Lock-On Crosshair HUD Reticle with rotation animation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera :: Camera

-- Camera Parameters
local MIN_DIST = 14
local MAX_DIST = 46
local BASE_HEIGHT = 6.2
local HEIGHT_AIR_FACTOR = 0.42
local SIDE_OFFSET = 3.6
local SMOOTH_SPEED = 14
local FOV_DEFAULT = 65
local FOV_DASHING = 76
local FLOOR_MIN_Y = 4.8

local isLockOnActive = true
local currentTarget: Model? = nil

-- Dynamic Cinematic Offsets (Decayed via dt)
local dynamicPitchOffset = 0.0 -- Upward / downward tilt in degrees
local dynamicRollOffset  = 0.0 -- Dutch angle roll in degrees
local dynamicZoomOffset  = 0.0 -- Distance push-in (negative is closer)
local dynamicFOVTarget   = FOV_DEFAULT

-- Bindables
local function getOrMakeBindable(name: string): BindableEvent
	local be = ReplicatedStorage:FindFirstChild(name) :: BindableEvent?
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = name
		be.Parent = ReplicatedStorage
	end
	return be
end

local evCamImpact = getOrMakeBindable("StormCameraImpactEvent")

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
-- DYNAMIC EVENT HANDLER: RESPOND TO COMBAT MOVEMENTS
-- =========================================================
evCamImpact.Event:Connect(function(eventType: string, param1: any, param2: any, param3: any)
	if eventType == "ComboHit" then
		local step = tonumber(param1) or 1
		local isHeavy = param2 == true
		local branch = tostring(param3 or "Neutral")

		-- Push in tighter as combo builds
		dynamicZoomOffset = math.clamp(-step * 1.6, -6.5, 0)
		dynamicFOVTarget = FOV_DEFAULT - (step * 1.5)

		if isHeavy then
			dynamicRollOffset = (branch == "Up" and 2.5 or -2.5)
			task.delay(0.20, function()
				dynamicRollOffset = 0
			end)
		end

	elseif eventType == "Launcher" then
		-- Upward skyward pitch tilt (+22°)
		dynamicPitchOffset = 22.0
		dynamicZoomOffset = -3.0
		task.delay(1.0, function()
			dynamicPitchOffset = 0
		end)

	elseif eventType == "AirChase" then
		-- Mid-air dogfight tracking
		dynamicPitchOffset = 18.0
		dynamicFOVTarget = FOV_DASHING
		dynamicZoomOffset = -4.0
		task.delay(0.65, function()
			dynamicPitchOffset = 0
			dynamicFOVTarget = FOV_DEFAULT
		end)

	elseif eventType == "GroundSlam" then
		-- Downward ground slam tilt (-18°)
		dynamicPitchOffset = -18.0
		dynamicZoomOffset = -2.0
		task.delay(0.5, function()
			dynamicPitchOffset = 0
		end)

	elseif eventType == "CDC" then
		-- Chakra Dash Cancel sudden snap
		dynamicFOVTarget = FOV_DASHING + 2
		dynamicZoomOffset = -4.5
		task.delay(0.3, function()
			dynamicFOVTarget = FOV_DEFAULT
			dynamicZoomOffset = 0
		end)

	elseif eventType == "Dash" then
		dynamicFOVTarget = FOV_DASHING
		local dur = tonumber(param1) or 0.6
		task.delay(dur, function()
			dynamicFOVTarget = FOV_DEFAULT
		end)
	end
end)

-- =========================================================
-- TARGET ACQUISITION & RETICLE
-- =========================================================
local function findNearestTarget(): Model?
	local myChar = LocalPlayer.Character
	if not myChar then return nil end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return nil end

	local bestTarget: Model? = nil
	local closestDist = 120

	-- 1. Training Dummy
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") and dummy:FindFirstChild("HumanoidRootPart") then
		local dRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
		local dist = (dRoot.Position - myRoot.Position).Magnitude
		if dist < closestDist then
			closestDist = dist
			bestTarget = dummy
		end
	end

	-- 2. Other Players
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
-- DYNAMIC CAMERA RENDER UPDATE
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

	-- Activate Scriptable Camera for Dynamic Dual Framing
	if Camera.CameraType ~= Enum.CameraType.Scriptable then
		Camera.CameraType = Enum.CameraType.Scriptable
		currentCamPos = Camera.CFrame.Position
		currentCamFocus = myRoot.Position
	end

	local pPos = myRoot.Position
	local tPos = targetRoot.Position

	-- 1. Midpoint between Player and Opponent
	local midpoint = (pPos + tPos) * 0.5

	-- 2. Distance and adaptive zoom with combo push-in
	local diff = (tPos - pPos)
	local dist = diff.Magnitude
	local clampedDist = math.clamp(dist * 0.95 + 8 + dynamicZoomOffset, MIN_DIST, MAX_DIST)

	-- 3. Direction vectors
	local lookDir = if dist > 0.1 then diff.Unit else Vector3.new(0, 0, -1)
	local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
	local rightDir = Vector3.new(-flatDir.Z, 0, flatDir.X)

	-- 4. Vertical air height compensation (follows airborne launcher)
	local highestY = math.max(pPos.Y, tPos.Y)
	local verticalOffset = math.max(0, highestY - 5.0) * HEIGHT_AIR_FACTOR

	-- 5. Calculate ideal Camera Position with dynamic pitch & side offset
	local pitchRad = math.rad(dynamicPitchOffset)
	local heightWithPitch = BASE_HEIGHT + verticalOffset - (math.sin(pitchRad) * clampedDist * 0.35)
	
	local targetCamPos = pPos - (flatDir * (clampedDist * math.cos(pitchRad))) + Vector3.new(0, heightWithPitch, 0) + (rightDir * SIDE_OFFSET)

	-- Guarantee camera never dips beneath arena floor (Floor Y = 3)
	if targetCamPos.Y < FLOOR_MIN_Y then
		targetCamPos = Vector3.new(targetCamPos.X, FLOOR_MIN_Y, targetCamPos.Z)
	end

	-- 6. Calculate ideal Camera Focus
	local targetFocus = midpoint + Vector3.new(0, 1.5 + verticalOffset * 0.5 + (math.sin(pitchRad) * 4), 0)

	-- 7. Smooth Lerp Interpolation
	local lerpFactor = math.clamp(dt * SMOOTH_SPEED, 0, 1)
	currentCamPos = currentCamPos:Lerp(targetCamPos, lerpFactor)
	currentCamFocus = currentCamFocus:Lerp(targetFocus, lerpFactor)

	-- 8. Apply CFrame with Dutch Roll Tilt
	local baseCF = CFrame.lookAt(currentCamPos, currentCamFocus)
	if math.abs(dynamicRollOffset) > 0.05 then
		Camera.CFrame = baseCF * CFrame.Angles(0, 0, math.rad(dynamicRollOffset))
	else
		Camera.CFrame = baseCF
	end

	-- 9. Smoothly Decay Offsets back to neutral
	dynamicPitchOffset = dynamicPitchOffset + (0 - dynamicPitchOffset) * math.clamp(dt * 3.5, 0, 1)
	dynamicRollOffset  = dynamicRollOffset  + (0 - dynamicRollOffset)  * math.clamp(dt * 6.0, 0, 1)
	dynamicZoomOffset  = dynamicZoomOffset  + (0 - dynamicZoomOffset)  * math.clamp(dt * 4.0, 0, 1)

	-- 10. Dynamic FOV Interpolation
	local isDashing = LocalPlayer:GetAttribute("IsNinjaDashing") == true
	local curTargetFOV = if isDashing then FOV_DASHING else dynamicFOVTarget
	Camera.FieldOfView = Camera.FieldOfView + (curTargetFOV - Camera.FieldOfView) * math.clamp(dt * 8, 0, 1)
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

print("[StormCameraController] ✅ Dynamic Storm Connections Camera Active: Combo Zoom, Skyward Pitch (+22°), Dive Cam (-18°), Dutch Angles ready.")
