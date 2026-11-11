--!strict
-- RagdollServerManager.luau
-- SERVER SCRIPT: Authoritative K.O. Elimination & Ragdoll Physics Lifecycle Manager
-- Features:
--   • Seamless trigger of physical ragdoll on lethal blow / 0 HP
--   • Broadcasts KOEvent to all clients for cinematic slow-mo and announcer banner
--   • Awards K.O. Victory Ryo (+100) and advances "ArenaVictor" daily quest
--   • Auto-cleans and respawns Training Dummy with Ninja Smoke Poof
--   • Safe player respawn cycle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local RagdollHelper = require(ReplicatedStorage:WaitForChild("RagdollHelper")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 15) :: Folder
local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evKO = ensureRemote("KOEvent")

-- Spawn Ninja Smoke FX upon corpse cleanup
local function spawnNinjaSmoke(pos: Vector3)
	local p = Instance.new("Part")
	p.Name = "NinjaSmokeFX"
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.Parent = Workspace

	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(240, 240, 250)
	smoke.Opacity = 0.8
	smoke.RiseVelocity = 4
	smoke.Size = 8
	smoke.Parent = p

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/shattered.mp3"
		snd.Volume = 0.8
		snd.PlaybackSpeed = 1.1
		snd.Parent = p
		snd:Play()
	end)

	task.delay(1.5, function()
		smoke.Enabled = false
		task.delay(1.5, function() p:Destroy() end)
	end)
end

-- =========================================================
-- AUTHORITATIVE K.O. TRIGGER
-- =========================================================
function _G.TriggerKO(victimModel: Model, killerPlayer: Player?, fatalImpulse: Vector3?)
	if not victimModel or not victimModel.Parent then return end
	if victimModel:GetAttribute("IsKilled") == true then return end
	victimModel:SetAttribute("IsKilled", true)

	local root = victimModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	local torso = victimModel:FindFirstChild("Torso") or victimModel:FindFirstChild("UpperTorso") :: BasePart?
	local centerPos = (torso and torso.Position) or (root and root.Position) or Vector3.zero

	local impulse = fatalImpulse or Vector3.new(0, 18, -35)

	-- 1. Convert to physical ragdoll
	RagdollHelper.EnableRagdoll(victimModel, impulse)

	-- 1B. Trigger Killer's Equipped Kill Effect
	local effectId = killerPlayer and killerPlayer:GetAttribute("EquippedKillEffect") or "ClassicSmoke"
	if _G.PlayKillEffect then
		_G.PlayKillEffect(effectId, centerPos)
	end

	-- 2. Broadcast K.O. to all clients for slow-mo and announcer
	evKO:FireAllClients({
		VictimName = victimModel.Name,
		KillerName = killerPlayer and killerPlayer.Name or "Shinobi",
		Position = centerPos,
		IsDummy = (victimModel.Name == "TrainingDummy"),
	})

	print(string.format(">> [K.O. SYSTEM] %s was ELIMINATED by %s! <<", victimModel.Name, killerPlayer and killerPlayer.Name or "Unknown"))

	-- 3. Economy & Quest rewards for killer
	if killerPlayer then
		local curKills = tonumber(killerPlayer:GetAttribute("KillsCount")) or 0
		killerPlayer:SetAttribute("KillsCount", curKills + 1)

		if _G.AwardCombatRyo then
			_G.AwardCombatRyo(killerPlayer, 100, "K.O. Shinobi Victory")
		end
		if _G.AddQuestProgress then
			_G.AddQuestProgress(killerPlayer, "ArenaVictor", 1)
		end
	end

	-- 4. Lifecycle Cleanup & Respawn
	if victimModel.Name == "TrainingDummy" then
		task.delay(3.2, function()
			if victimModel and victimModel.Parent then
				local lastPos = centerPos
				victimModel:Destroy()
				spawnNinjaSmoke(lastPos)

				task.delay(0.6, function()
					if _G.RespawnTrainingDummy then
						_G.RespawnTrainingDummy()
					end
				end)
			end
		end)
	else
		-- Player Character
		local victimPlayer = Players:GetPlayerFromCharacter(victimModel)
		if victimPlayer then
			task.delay(3.8, function()
				if victimPlayer.Parent then
					victimPlayer:LoadCharacter()
				end
			end)
		end
	end
end

-- Monitor player humanoid deaths
local function hookPlayerCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then return end

	hum.Died:Connect(function()
		local lastAttackerName = char:GetAttribute("LastAttackerName")
		local killer = lastAttackerName and Players:FindFirstChild(lastAttackerName)
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local fatalVel = root and root.AssemblyLinearVelocity or Vector3.new(0, 15, -30)

		if _G.TriggerKO then
			_G.TriggerKO(char, killer, fatalVel)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		hookPlayerCharacter(player, char)
	end)
	if player.Character then
		hookPlayerCharacter(player, player.Character)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		hookPlayerCharacter(p, p.Character)
	end
end

print("[RagdollServerManager] ✅ Authoritative K.O. & Ragdoll Lifecycle Engine active.")

