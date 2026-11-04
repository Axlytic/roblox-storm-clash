--!strict
-- TrainingDummySpawner.luau
-- SERVER SCRIPT: Interactive Fighting Lab Training Dummy NPC
-- Features:
--   • Tagged with "IsCombatTarget" for automatic Storm 4 lock-on
--   • Interactive ProximityPrompt to switch Defense Modes:
--       [1] Neutral (Stand Still) -> Test Combos & Ninja Dash
--       [2] High Guard Active -> Test Low Sweep Guard Piercing
--       [3] Low Guard Active -> Test High/Mid Hits
--       [4] Practice Parry -> Test Tekken Just-Frame Parry Counter
--   • Realtime Billboard HUD with HP bar and current Defense Mode
--   • Auto HP regeneration so testing is seamless

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local MODES = { "Neutral", "High", "Low", "Parry" }
local MODE_COLORS = {
	["Neutral"] = Color3.fromRGB(0, 255, 200),
	["High"]    = Color3.fromRGB(0, 200, 255),
	["Low"]     = Color3.fromRGB(255, 180, 0),
	["Parry"]   = Color3.fromRGB(255, 220, 50),
}

local function createTrainingDummy(pos: Vector3): Model
	local existing = Workspace:FindFirstChild("TrainingDummy")
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = "TrainingDummy"

	-- Humanoid & RootPart
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = pos + Vector3.new(0, 3, 0)
	root.Anchored = true
	root.CanCollide = true
	root.Transparency = 1
	root.Parent = model
	model.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = root.CFrame
	torso.Color = Color3.fromRGB(60, 65, 80)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = true
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(220, 180, 140)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Visual Gi / Shinobi Belt
	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Size = Vector3.new(2.1, 0.4, 1.1)
	belt.CFrame = torso.CFrame * CFrame.new(0, -0.6, 0)
	belt.Color = Color3.fromRGB(220, 30, 30)
	belt.Material = Enum.Material.Fabric
	belt.Anchored = true
	belt.CanCollide = false
	belt.Parent = model

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 1000
	hum.Health = 1000
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
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
	prompt.HoldDuration = 0.5
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
		if newHealth < 300 then
			hum.Health = 1000
		end
	end)

	-- Tag as combat target
	model:SetAttribute("IsCombatTarget", true)
	model.Parent = Workspace
	print(">> [TrainingDummy] Lab Dummy spawned successfully at " .. tostring(pos) .. " <<")
	return model
end

-- Spawn Dummy in arena center (Y=52 matches DilemmaArena floor)
task.delay(1.5, function()
	createTrainingDummy(Vector3.new(0, 50, 15))
end)
