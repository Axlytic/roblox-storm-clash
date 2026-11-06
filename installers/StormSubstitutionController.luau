local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormSubstitutionController')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormSubstitutionController'
s.Source = [=====[--!strict
-- StormSubstitutionController.luau
-- CLIENT SCRIPT: Naruto Storm 4 Substitution Jutsu (Kawarimi)
-- Features:
--   • 4-Stock Substitution System (The core competitive lifeline of Storm 4)
--   • Instant escape from enemy combos, jutsu, and hitstun
--   • Spawns 3D wooden log & smoke poof, teleports directly behind opponent
--   • Multi-platform input:
--       Keyboard: [E] or [Q] or [LeftShift] (when attacked)
--       Gamepad:  [L2] (Official PS/Xbox Storm 4 Button)
--       Mobile:   [🪵 SUB] Touch Button

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local evSub = combatEvents:WaitForChild("SubstitutionEvent") :: RemoteEvent

-- Mobile Bindable
local evMobileSub = ReplicatedStorage:FindFirstChild("MobileSubstitutionAction") :: BindableEvent?
if not evMobileSub then
	evMobileSub = Instance.new("BindableEvent")
	evMobileSub.Name = "MobileSubstitutionAction"
	evMobileSub.Parent = ReplicatedStorage
end

local lastSubRequest = 0

-- =========================================================
-- VISUAL LOG & SMOKE BURST (Client Prediction & Replication)
-- =========================================================
local function playKawarimiVisual(posCFrame: CFrame)
	local log = Instance.new("Part")
	log.Name = "LocalKawarimiLog"
	log.Shape = Enum.PartType.Cylinder
	log.Size = Vector3.new(2.8, 1.4, 1.4)
	log.CFrame = posCFrame * CFrame.Angles(0, 0, math.rad(90))
	log.Color = Color3.fromRGB(139, 90, 43)
	log.Material = Enum.Material.Wood
	log.Anchored = false
	log.CanCollide = true
	log.Parent = Workspace
	Debris:AddItem(log, 2.0)

	local att = Instance.new("Attachment", log)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(245, 245, 250), Color3.fromRGB(210, 210, 220))
	pe.Size = NumberSequence.new(2.5, 5.0)
	pe.Transparency = NumberSequence.new(0.2, 1.0)
	pe.Rate = 120
	pe.Speed = NumberRange.new(6, 15)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att
	task.delay(0.2, function() pe.Enabled = false end)

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
		snd.PlaybackSpeed = 0.8
		snd.Volume = 1.0
		snd.Parent = log
		snd:Play()
	end)
end

-- =========================================================
-- EXECUTE SUBSTITUTION
-- =========================================================
local function requestSubstitution()
	local now = os.clock()
	if now - lastSubRequest < 0.35 then return end
	lastSubRequest = now

	local curStocks = LocalPlayer:GetAttribute("SubstitutionStocks") or 4
	if curStocks < 1 then
		print(">> [Substitution] Out of Substitution stocks! (0 left) <<")
		return
	end

	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	print(">> [Substitution] Requesting Kawarimi escape! <<")
	evSub:FireServer()
end

-- Listen for Server Broadcast (other players or dummy subbing)
evSub.OnClientEvent:Connect(function(subbingPlayer: Player, prevCFrame: CFrame)
	if subbingPlayer ~= LocalPlayer then
		playKawarimiVisual(prevCFrame)
	end
end)

-- =========================================================
-- INPUT LISTENERS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	-- 1. Keyboard: [E] or [Q]
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Q then
		requestSubstitution()
	-- 2. Gamepad: [ButtonL2] (Official Storm 4 Sub Trigger)
	elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
		requestSubstitution()
	end
end)

-- Mobile Touch Listener
evMobileSub.Event:Connect(function()
	requestSubstitution()
end)

print("[StormSubstitutionController] ✅ Loaded — Substitution Jutsu [E / Q / Gamepad L2 / Mobile SUB] active.")

]=====]
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormSubstitutionController'
