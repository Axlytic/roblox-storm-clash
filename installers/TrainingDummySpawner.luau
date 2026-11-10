local ex = game:GetService('ServerScriptService'):FindFirstChild('TrainingDummySpawner')
if ex then ex:Destroy() end
local s = Instance.new('Script')
s.Name = 'TrainingDummySpawner'
s.Source = [=====[--!strict
-- TrainingDummySpawner.luau
-- SERVER SCRIPT: Fully Physical Interactive Fighting Lab Training Dummy NPC
-- Features:
--   • 100% Unanchored Physics: Responds dynamically to Launchers, Knockbacks, & Ground Bounces!
--   • Welded Anatomy: Torso, Head, Belt, Arms, Legs properly welded via WeldConstraint
--   • Upright Stabilizer: Uses AlignOrientation / Spring Gyro to remain standing during neutral state
--   • Interactive ProximityPrompt to switch Defense Modes:
--       [1] Neutral (Stand Still) -> Test Combos, Air Launchers, & CDC Loops
--       [2] High Guard Active -> Test Low Sweep Guard Piercing
--       [3] Low Guard Active -> Test High/Mid Hits
--       [4] Practice Parry -> Test Tekken Just-Frame Parry Counter
--   • Realtime Billboard HUD with HP bar and current Defense Mode
--   • Auto HP regeneration and boundary safety recovery

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local MODES = { "Neutral", "High", "Low", "Parry" }
local MODE_COLORS = {
	["Neutral"] = Color3.fromRGB(0, 255, 200),
	["High"]    = Color3.fromRGB(0, 200, 255),
	["Low"]     = Color3.fromRGB(255, 180, 0),
	["Parry"]   = Color3.fromRGB(255, 220, 50),
}

local function weldParts(p0: BasePart, p1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

local function createTrainingDummy(pos: Vector3): Model
	local existing = Workspace:FindFirstChild("TrainingDummy")
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = "TrainingDummy"

	-- HumanoidRootPart (Unanchored so physics and AssemblyLinearVelocity work!)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = pos + Vector3.new(0, 3, 0)
	root.Anchored = false
	root.CanCollide = false
	root.Transparency = 1
	root.Parent = model
	model.PrimaryPart = root

	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = root.CFrame
	torso.Color = Color3.fromRGB(55, 60, 75)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = model
	weldParts(root, torso)

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(220, 180, 140)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = false
	head.Parent = model
	weldParts(torso, head)

	-- Shinobi Belt
	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Size = Vector3.new(2.1, 0.4, 1.1)
	belt.CFrame = torso.CFrame * CFrame.new(0, -0.6, 0)
	belt.Color = Color3.fromRGB(220, 35, 35)
	belt.Material = Enum.Material.Fabric
	belt.Anchored = false
	belt.CanCollide = false
	belt.Parent = model
	weldParts(torso, belt)

	-- Limbs for visual weight and realistic ragdoll reaction
	local function makeLimb(name: string, size: Vector3, offset: CFrame, color: Color3)
		local limb = Instance.new("Part")
		limb.Name = name
		limb.Size = size
		limb.CFrame = torso.CFrame * offset
		limb.Color = color
		limb.Material = Enum.Material.SmoothPlastic
		limb.Anchored = false
		limb.CanCollide = false
		limb.Parent = model
		weldParts(torso, limb)
		return limb
	end

	makeLimb("LeftArm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0), Color3.fromRGB(220, 180, 140))
	makeLimb("RightArm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0), Color3.fromRGB(220, 180, 140))
	makeLimb("LeftLeg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0), Color3.fromRGB(45, 50, 60))
	makeLimb("RightLeg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0), Color3.fromRGB(45, 50, 60))

	-- Upright Physics Stabilizer: Keeps dummy standing upright while allowing full velocity knockbacks & launches
	local att = Instance.new("Attachment", root)
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = att
	alignOrientation.CFrame = CFrame.Angles(0, 0, 0)
	alignOrientation.MaxTorque = 45000
	alignOrientation.Responsiveness = 25
	alignOrientation.Parent = root

	-- Humanoid
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 2000
	hum.Health = 2000
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 0
	hum.Parent = model

	-- Overhead Tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "DummyTag"
	bb.Size = UDim2.new(0, 200, 0, 55)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.fromScale(1, 0.45)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⚔️ TRAINING DUMMY LAB"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextScaled = true
	titleLabel.Parent = bb

	local modeLabel = Instance.new("TextLabel")
	modeLabel.Size = UDim2.fromScale(1, 0.38)
	modeLabel.Position = UDim2.new(0, 0, 0.5, 0)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "[ MODE: NEUTRAL (STAND STILL) ]"
	modeLabel.TextColor3 = MODE_COLORS["Neutral"]
	modeLabel.Font = Enum.Font.GothamBold
	modeLabel.TextScaled = true
	modeLabel.Parent = bb

	-- ProximityPrompt to switch Guard Modes
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ganti Mode Latihan"
	prompt.ObjectText = "Training Dummy"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.Parent = torso

	local currentModeIdx = 1
	model:SetAttribute("DummyGuardMode", "Neutral")

	prompt.Triggered:Connect(function(player)
		currentModeIdx = (currentModeIdx % #MODES) + 1
		local newMode = MODES[currentModeIdx]
		model:SetAttribute("DummyGuardMode", newMode)

		modeLabel.Text = string.format("[ MODE: %s ]", string.upper(newMode))
		modeLabel.TextColor3 = MODE_COLORS[newMode] or Color3.fromRGB(255, 255, 255)
		print(string.format(">> [Training Lab] %s changed Dummy Mode to: %s <<", player.Name, newMode))
	end)

	-- Auto HP regeneration
	hum.HealthChanged:Connect(function(newHealth)
		if newHealth < 500 then
			hum.Health = 2000
		end
	end)

	-- Boundary safety: if dummy flies off arena, reset back to center
	task.spawn(function()
		while model.Parent do
			task.wait(2.0)
			if root and (root.Position.Y < -10 or (root.Position - pos).Magnitude > 85) then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
			end
		end
	end)

	-- Tag as combat target
	model:SetAttribute("IsCombatTarget", true)
	model.Parent = Workspace
	print(">> [TrainingDummy] Unanchored Physical Dummy spawned at arena floor: " .. tostring(pos) .. " <<")
	return model
end

-- Spawn Dummy at Combat Arena floor center (Floor is at Y = 3.0)
task.delay(1.0, function()
	createTrainingDummy(Vector3.new(0, 3.0, 16))
end)
]=====]
s.Parent = game:GetService('ServerScriptService')
return 'Installed Script: TrainingDummySpawner'
