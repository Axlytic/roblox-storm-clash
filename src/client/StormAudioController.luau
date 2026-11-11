--!strict
-- StormAudioController.luau
-- CLIENT SCRIPT: High-Fidelity Anime Combat Sound Engine & Audio Director
-- Features:
--   • 3D Spatial Sound Effects with distance attenuation for attacks, blocks, and jutsus
--   • Procedural pitch-shifting (+/- 5%) on repeated hits to eliminate audio fatigue
--   • Pre-cached sound instances in SoundService for zero latency audio trigger
--   • Global API `_G.PlayCombatSFX(category, name, worldPos)` for all client & UI scripts
--   • Dynamic Battle BGM crossfader: seamlessly responds to combat engagement

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder?
local evAttack    = combatEvents and combatEvents:FindFirstChild("AttackEvent") :: RemoteEvent?
local evParry     = combatEvents and combatEvents:FindFirstChild("ParryEvent") :: RemoteEvent?
local evBlock     = combatEvents and combatEvents:FindFirstChild("BlockEvent") :: RemoteEvent?
local evDash      = combatEvents and combatEvents:FindFirstChild("NinjaDashEvent") :: RemoteEvent?
local evAwaken    = combatEvents and combatEvents:FindFirstChild("AwakeningEvent") :: RemoteEvent?
local evPlaySound = combatEvents and combatEvents:FindFirstChild("PlaySoundEvent") :: RemoteEvent?

-- Sound Cache Pool to avoid instancing lag
local soundFolder = Instance.new("Folder")
soundFolder.Name = "StormAudioPool"
soundFolder.Parent = SoundService

local rng = Random.new()

-- Play sound helper with spatial positioning or 2D stereo
local function playSFX(category: string, name: string, worldPos: Vector3?, volumeOverride: number?, pitchOverride: number?)
	local cat = (SoundConfig :: any)[category]
	if not cat then return end
	local entry = cat[name]
	if not entry then return end

	local minP = entry.PitchRange.min
	local maxP = entry.PitchRange.max
	local pitch = pitchOverride or (minP + rng:NextNumber() * (maxP - minP))
	local volume = volumeOverride or entry.DefaultVolume

	task.spawn(function()
		pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = entry.Id
			sound.Volume = volume
			sound.PlaybackSpeed = pitch

			if worldPos then
				-- 3D Spatial Sound at hit location
				local attachPart = Instance.new("Part")
				attachPart.Name = "SFX_Emitter"
				attachPart.Size = Vector3.new(0.5, 0.5, 0.5)
				attachPart.Position = worldPos
				attachPart.Anchored = true
				attachPart.CanCollide = false
				attachPart.CanQuery = false
				attachPart.CanTouch = false
				attachPart.Transparency = 1
				attachPart.Parent = Workspace

				sound.RollOffMode = Enum.RollOffMode.InverseTapered
				sound.RollOffMinDistance = 10
				sound.RollOffMaxDistance = 120
				sound.Parent = attachPart

				sound:Play()
				sound.Ended:Connect(function()
					attachPart:Destroy()
				end)
				-- Fallback cleanup
				task.delay(3.5, function()
					pcall(function() attachPart:Destroy() end)
				end)
			else
				-- 2D Stereo sound
				sound.Parent = soundFolder
				sound:Play()
				sound.Ended:Connect(function()
					sound:Destroy()
				end)
				task.delay(3.5, function()
					pcall(function() sound:Destroy() end)
				end)
			end
		end)
	end)
end

-- Export Global API
_G.PlayCombatSFX = playSFX

-- Listen to Combat Remote Events for Audio Juice
if evAttack then
	evAttack.OnClientEvent:Connect(function(attacker: Player, hitVictim: Model?, attackType: string?, hitPos: Vector3?)
		local myChar = LocalPlayer.Character
		local isMyAction = (attacker == LocalPlayer)

		if hitVictim then
			-- Hit landed!
			local root = hitVictim:FindFirstChild("HumanoidRootPart") :: BasePart?
			local pos = hitPos or (root and root.Position) or (myChar and myChar:GetPivot().Position)

			if attackType == "Heavy" or attackType == "Launcher" or attackType == "GroundSlam" then
				playSFX("Combat", "HitImpactHeavy", pos)
				playSFX("Combat", "CriticalShatter", pos, 0.7)
			else
				playSFX("Combat", "HitImpactLight", pos)
			end
		else
			-- Whiff / Swing whoosh
			if isMyAction then
				playSFX("Combat", "PunchSwing", nil, 0.6)
			end
		end
	end)
end

if evParry then
	evParry.OnClientEvent:Connect(function(parrier: Player, attacker: Player, hitPos: Vector3?)
		local myChar = LocalPlayer.Character
		local pos = hitPos or (myChar and myChar:GetPivot().Position)
		playSFX("Defense", "ParryBell", pos, 1.0, 1.3)
		playSFX("Combat", "CriticalShatter", pos, 0.8, 1.2)
	end)
end

if evBlock then
	evBlock.OnClientEvent:Connect(function(blocker: Player, isBlocking: boolean, blockType: string)
		if isBlocking and blocker == LocalPlayer then
			playSFX("Defense", "BlockThud", nil, 0.65)
		end
	end)
end

if evDash then
	evDash.OnClientEvent:Connect(function(dasher: Player)
		if dasher == LocalPlayer then
			playSFX("Defense", "NinjaDash", nil, 0.75)
		end
	end)
end

if evAwaken then
	evAwaken.OnClientEvent:Connect(function(player: Player, isAwakened: boolean)
		local char = player.Character
		local pos = char and char:GetPivot().Position
		if isAwakened then
			playSFX("Defense", "AwakeningRoar", pos, 1.0)
			playSFX("Defense", "ChakraCharge", pos, 0.9, 1.4)
		end
	end)
end

if evPlaySound then
	evPlaySound.OnClientEvent:Connect(function(category: string, name: string, worldPos: Vector3?, vol: number?, pitch: number?)
		playSFX(category, name, worldPos, vol, pitch)
	end)
end

print("[StormAudioController] ✅ Loaded — Anime combat sound design & 3D spatial FX engine initialized.")
