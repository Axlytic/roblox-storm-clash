--!strict
-- WaveSurvivalServerManager.luau
-- SERVER SCRIPT: PvE Wave Survival & Akatsuki Boss Incursion Arena Engine
-- Features:
--   • 3-Wave Escalating PvE Challenge Altar in Grand Shinobi Arena
--   • Wave 1: 2 Shadow Genin Clones (120 HP, Taijutsu M1)
--   • Wave 2: 3 Rogue Chunin Infiltrators (180 HP, Fast Dash & Kawarimi)
--   • Wave 3: Akatsuki Shadow Boss (750 HP, Boss Bar, Ground Slam, Dark Jutsu)
--   • Full Ragdoll Physics integration on kill via RagdollHelper
--   • Big Bounty: +500 Ryo, +50 Essence Shards & Quest Progression

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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

local evWaveStatus = ensureRemote("WaveStatusEvent")
local evWaveReward = ensureRemote("WaveRewardEvent")

-- State
local isWaveActive = false
local currentWave = 0
local activeEnemies: { Model } = {}
local currentBossModel: Model? = nil
local waveStarterPlayer: Player? = nil

-- Spawn Particle Helper
local function spawnSmokeFX(pos: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.Parent = Workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(color)
	pe.Size = NumberSequence.new(3, 8)
	pe.Speed = NumberRange.new(5, 12)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.5, 0.8)
	pe.Rate = 60
	pe.Parent = p
	pe:Emit(25)

	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxasset://sounds/shattered.mp3"
		snd.Volume = 0.7
		snd.PlaybackSpeed = 0.9
		snd.Parent = p
		snd:Play()
	end)

	task.delay(1.0, function() p:Destroy() end)
end

-- =========================================================
-- 1. ENEMY CREATION & COMBAT RIGGING
-- =========================================================
local function createShinobiNpc(name: string, maxHp: number, speed: number, color: Color3, pos: Vector3, isBoss: boolean): Model
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = if isBoss then Vector3.new(3, 3, 1.5) else Vector3.new(2, 2, 1)
	root.Position = pos + Vector3.new(0, 3, 0)
	root.Anchored = false
	root.CanCollide = false
	root.Transparency = 1
	root.Parent = model
	model.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = root.Size
	torso.CFrame = root.CFrame
	torso.Color = color
	torso.Material = if isBoss then Enum.Material.Neon else Enum.Material.SmoothPlastic
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = model

	local wRoot = Instance.new("WeldConstraint")
	wRoot.Part0 = root
	wRoot.Part1 = torso
	wRoot.Parent = torso

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = if isBoss then Vector3.new(1.8, 1.8, 1.8) else Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = torso.CFrame * CFrame.new(0, if isBoss then 2.2 else 1.6, 0)
	head.Color = if isBoss then Color3.fromRGB(30, 20, 25) else Color3.fromRGB(220, 180, 140)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = false
	head.Parent = model

	local wHead = Instance.new("WeldConstraint")
	wHead.Part0 = torso
	wHead.Part1 = head
	wHead.Parent = head

	-- Limbs
	local function addLimb(limbName: string, offset: CFrame, limbSize: Vector3)
		local limb = Instance.new("Part")
		limb.Name = limbName
		limb.Size = limbSize
		limb.CFrame = torso.CFrame * offset
		limb.Color = color
		limb.Material = Enum.Material.SmoothPlastic
		limb.Anchored = false
		limb.CanCollide = false
		limb.Parent = model

		local w = Instance.new("WeldConstraint")
		w.Part0 = torso
		w.Part1 = limb
		w.Parent = limb
	end

	local lSize = if isBoss then Vector3.new(1.4, 2.8, 1.4) else Vector3.new(1, 2, 1)
	addLimb("LeftArm", CFrame.new(-1.6, 0, 0), lSize)
	addLimb("RightArm", CFrame.new(1.6, 0, 0), lSize)
	addLimb("LeftLeg", CFrame.new(-0.6, -2, 0), lSize)
	addLimb("RightLeg", CFrame.new(0.6, -2, 0), lSize)

	-- Upright Stabilizer
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
	hum.MaxHealth = maxHp
	hum.Health = maxHp
	hum.WalkSpeed = speed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	-- Dark Chakra Aura for Shadows / Boss
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "ShadowAura"
	aura.Texture = "rbxasset://textures/particles/fire_main.dds"
	aura.Color = if isBoss
		then ColorSequence.new(Color3.fromRGB(255, 30, 80), Color3.fromRGB(50, 0, 30))
		else ColorSequence.new(Color3.fromRGB(60, 40, 100), Color3.fromRGB(15, 15, 25))
	aura.Size = NumberSequence.new(isBoss and 3 or 1.5, 0.2)
	aura.Rate = isBoss and 45 or 20
	aura.Speed = NumberRange.new(2, 6)
	aura.Lifetime = NumberRange.new(0.4, 0.7)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Parent = torso

	-- Overhead Tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "NpcTag"
	bb.Size = UDim2.new(0, 180, 0, 45)
	bb.StudsOffset = Vector3.new(0, if isBoss then 3.6 else 2.6, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 0.55)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.TextSize = if isBoss then 16 else 13
	nameLbl.TextColor3 = if isBoss then Color3.fromRGB(255, 40, 70) else Color3.fromRGB(200, 170, 255)
	nameLbl.Text = string.upper(name)
	nameLbl.Parent = bb

	local hpLbl = Instance.new("TextLabel")
	hpLbl.Name = "HPText"
	hpLbl.Size = UDim2.fromScale(1, 0.40)
	hpLbl.Position = UDim2.new(0, 0, 0.55, 0)
	hpLbl.BackgroundTransparency = 1
	hpLbl.Font = Enum.Font.GothamBold
	hpLbl.TextSize = 11
	hpLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	hpLbl.Text = string.format("%d / %d HP", maxHp, maxHp)
	hpLbl.Parent = bb

	-- Tag as combat target
	model:SetAttribute("IsCombatTarget", true)
	model:SetAttribute("IsWaveNpc", true)
	model.Parent = Workspace

	spawnSmokeFX(pos + Vector3.new(0, 2, 0), color)
	return model
end

-- =========================================================
-- 2. ENEMY AI BEHAVIOR LOOP (CHASE & ATTACK)
-- =========================================================
local function runNpcCombatAI(npc: Model, isBoss: boolean)
	local root = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = npc:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	task.spawn(function()
		local attackCooldown = 0
		while npc.Parent and hum.Health > 0 and isWaveActive do
			task.wait(0.2)
			attackCooldown = math.max(0, attackCooldown - 0.2)

			-- Find nearest player
			local nearestPlayer: Player? = nil
			local nearestDist = 9999
			local pRoot: BasePart? = nil

			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				if char then
					local cRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					local cHum = char:FindFirstChildOfClass("Humanoid")
					if cRoot and cHum and cHum.Health > 0 then
						local dist = (cRoot.Position - root.Position).Magnitude
						if dist < nearestDist then
							nearestDist = dist
							nearestPlayer = p
							pRoot = cRoot
						end
					end
				end
			end

			if pRoot and nearestPlayer then
				-- Move toward player
				hum:MoveTo(pRoot.Position)

				-- Melee Attack Range (within 7 studs)
				if nearestDist <= 8.5 and attackCooldown <= 0 then
					attackCooldown = if isBoss then 1.4 else 1.8

					-- Face player
					root.CFrame = CFrame.lookAt(root.Position, Vector3.new(pRoot.Position.X, root.Position.Y, pRoot.Position.Z))

					-- Swing Animation Impulse
					local lungeDir = (pRoot.Position - root.Position).Unit
					root.AssemblyLinearVelocity = lungeDir * 18 + Vector3.new(0, 6, 0)

					-- Deal damage to player
					local pChar = nearestPlayer.Character
					local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
					if pHum and pHum.Health > 0 then
						local dmg = if isBoss then 28 else 12
						pHum:TakeDamage(dmg)
						pRoot.AssemblyLinearVelocity = lungeDir * 32 + Vector3.new(0, 10, 0)

						-- Sound
						pcall(function()
							local s = Instance.new("Sound")
							s.SoundId = "rbxasset://sounds/sword_hit.wav"
							s.PlaybackSpeed = if isBoss then 0.75 else 1.1
							s.Volume = 0.8
							s.Parent = root
							s:Play()
							s.Ended:Connect(function() s:Destroy() end)
						end)
					end

					-- Boss Special Ability: Ground Slam Tremor
					if isBoss and math.random() < 0.4 then
						task.delay(0.6, function()
							if root.Parent and hum.Health > 0 then
								root.AssemblyLinearVelocity = Vector3.new(0, 35, 0)
								task.delay(0.4, function()
									if root.Parent then
										root.AssemblyLinearVelocity = Vector3.new(0, -50, 0)
										-- Shockwave
										for _, p in ipairs(Players:GetPlayers()) do
											local char = p.Character
											local cr = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
											local ch = char and char:FindFirstChildOfClass("Humanoid")
											if cr and ch and (cr.Position - root.Position).Magnitude <= 24 then
												ch:TakeDamage(20)
												cr.AssemblyLinearVelocity = (cr.Position - root.Position).Unit * 50 + Vector3.new(0, 18, 0)
											end
										end
									end
								end)
							end
						end)
					end
				end
			end
		end
	end)
end

-- =========================================================
-- 3. WAVE SPAWN & PROGRESSION LOGIC
-- =========================================================
local function spawnWave(waveNum: number)
	currentWave = waveNum
	activeEnemies = {}
	currentBossModel = nil

	print(string.format(">> [WaveSurvival] Spawning Wave %d / 3... <<", waveNum))

	if waveNum == 1 then
		-- Wave 1: 2 Shadow Genin
		local spawnPoints = { Vector3.new(-18, 3, 20), Vector3.new(18, 3, 20) }
		for i, pt in ipairs(spawnPoints) do
			local npc = createShinobiNpc("Shadow Genin " .. tostring(i), 120, 18, Color3.fromRGB(45, 35, 55), pt, false)
			table.insert(activeEnemies, npc)
			runNpcCombatAI(npc, false)
		end
		evWaveStatus:FireAllClients({
			Wave = 1,
			MaxWaves = 3,
			Title = "GELOMBANG 1: SHADOW GENIN CLONES",
			ActiveCount = #activeEnemies,
			BossName = nil,
		})

	elseif waveNum == 2 then
		-- Wave 2: 3 Rogue Chunin
		local spawnPoints = { Vector3.new(-22, 3, 10), Vector3.new(0, 3, 30), Vector3.new(22, 3, 10) }
		for i, pt in ipairs(spawnPoints) do
			local npc = createShinobiNpc("Rogue Chunin " .. tostring(i), 180, 23, Color3.fromRGB(30, 45, 65), pt, false)
			table.insert(activeEnemies, npc)
			runNpcCombatAI(npc, false)
		end
		evWaveStatus:FireAllClients({
			Wave = 2,
			MaxWaves = 3,
			Title = "GELOMBANG 2: ROGUE CHUNIN STRIKERS",
			ActiveCount = #activeEnemies,
			BossName = nil,
		})

	elseif waveNum == 3 then
		-- Wave 3: Akatsuki Shadow Boss
		local bossPos = Vector3.new(0, 3, 18)
		local boss = createShinobiNpc("Akatsuki Shadow Boss", 750, 26, Color3.fromRGB(180, 25, 45), bossPos, true)
		currentBossModel = boss
		table.insert(activeEnemies, boss)
		runNpcCombatAI(boss, true)

		evWaveStatus:FireAllClients({
			Wave = 3,
			MaxWaves = 3,
			Title = "GELOMBANG 3: AKATSUKI SHADOW BOSS",
			ActiveCount = 1,
			BossName = "AKATSUKI SHADOW BOSS",
			BossHP = 750,
			BossMaxHP = 750,
		})
	end

	-- Hook Death of each enemy
	for _, npc in ipairs(activeEnemies) do
		local hum = npc:WaitForChild("Humanoid") :: Humanoid
		local isBoss = (npc == currentBossModel)

		hum.HealthChanged:Connect(function(newHp)
			local tag = npc:FindFirstChild("Head") and npc.Head:FindFirstChild("NpcTag")
			local hpLbl = tag and tag:FindFirstChild("HPText") :: TextLabel?
			if hpLbl then
				hpLbl.Text = string.format("%d / %d HP", math.max(0, math.floor(newHp)), hum.MaxHealth)
			end

			-- Update Boss Bar if Boss
			if isBoss and isWaveActive then
				evWaveStatus:FireAllClients({
					Wave = 3,
					MaxWaves = 3,
					Title = "GELOMBANG 3: AKATSUKI SHADOW BOSS",
					ActiveCount = #activeEnemies,
					BossName = "AKATSUKI SHADOW BOSS",
					BossHP = math.max(0, math.floor(newHp)),
					BossMaxHP = hum.MaxHealth,
				})
			end

			if newHp <= 0 and npc:GetAttribute("IsKilled") ~= true then
				npc:SetAttribute("IsKilled", true)

				-- Convert to Ragdoll
				local lastAttacker = npc:GetAttribute("LastAttackerName")
				local killer = lastAttacker and Players:FindFirstChild(lastAttacker) or waveStarterPlayer
				RagdollHelper.EnableRagdoll(npc, Vector3.new(math.random(-15, 15), 18, -30))

				-- Reward killer
				if killer then
					local bounty = if isBoss then 200 else 40
					if _G.AwardCombatRyo then _G.AwardCombatRyo(killer, bounty, "Wave Elimination") end
					if _G.AddQuestProgress then _G.AddQuestProgress(killer, "ArenaVictor", 1) end
				end

				-- Remove from active list
				local idx = table.find(activeEnemies, npc)
				if idx then table.remove(activeEnemies, idx) end

				-- Cleanup corpse
				task.delay(2.8, function()
					if npc and npc.Parent then
						local p = npc:FindFirstChild("Torso") and npc.Torso.Position or Vector3.zero
						npc:Destroy()
						spawnSmokeFX(p, Color3.fromRGB(150, 150, 160))
					end
				end)

				-- Check if all enemies defeated
				if #activeEnemies == 0 then
					task.delay(2.0, function()
						if currentWave < 3 and isWaveActive then
							spawnWave(currentWave + 1)
						elseif currentWave >= 3 and isWaveActive then
							-- VICTORY!
							isWaveActive = false
							print(">> [WaveSurvival] ALL 3 WAVES CLEARED! GRAND VICTORY! <<")

							-- Grand Bounty
							if waveStarterPlayer then
								if _G.AwardCombatRyo then
									_G.AwardCombatRyo(waveStarterPlayer, 500, "Grand Wave Clear Bounty")
								end
								if _G.AwardEssenceShards then
									_G.AwardEssenceShards(waveStarterPlayer, 50)
								else
									local cur = tonumber(waveStarterPlayer:GetAttribute("EssenceShards")) or 0
									waveStarterPlayer:SetAttribute("EssenceShards", cur + 50)
								end
							end

							evWaveReward:FireAllClients({
								Success = true,
								RyoReward = 500,
								ShardsReward = 50,
								Message = "🏆 UJIAN SHINOBI LULUS! (+500 Ryo & +50 💎 Shards)",
							})

							evWaveStatus:FireAllClients({
								Wave = 0,
								MaxWaves = 3,
								Title = "UJIAN SELESAI",
								ActiveCount = 0,
								BossName = nil,
							})
						end
					end)
				end
			end
		end)
	end
end

-- =========================================================
-- 4. 3D TRIAL STONE ALTAR IN ARENA
-- =========================================================
local function buildTrialAltar()
	local existing = Workspace:FindFirstChild("ShinobiTrialAltar")
	if existing then existing:Destroy() end

	local altarModel = Instance.new("Model")
	altarModel.Name = "ShinobiTrialAltar"

	local altarPos = Vector3.new(38, 2, 0) -- Eastern perimeter of arena

	-- Base Platform
	local base = Instance.new("Part")
	base.Name = "AltarBase"
	base.Size = Vector3.new(7, 1.4, 7)
	base.Position = altarPos
	base.Color = Color3.fromRGB(35, 40, 52)
	base.Material = Enum.Material.Slate
	base.Anchored = true
	base.Parent = altarModel

	-- Ancient Inscription Stone
	local stone = Instance.new("Part")
	stone.Name = "TrialStone"
	stone.Size = Vector3.new(3.5, 6, 1.2)
	stone.Position = altarPos + Vector3.new(0, 3.5, 0)
	stone.Color = Color3.fromRGB(22, 26, 36)
	stone.Material = Enum.Material.CorrodedMetal
	stone.Anchored = true
	stone.Parent = altarModel

	-- Glowing Kanji Rune Surface
	local runeGui = Instance.new("SurfaceGui")
	runeGui.Face = Enum.NormalId.Back
	runeGui.CanvasSize = Vector2.new(350, 600)
	runeGui.AlwaysOnTop = false
	runeGui.LightInfluence = 0
	runeGui.Parent = stone

	local runeLbl = Instance.new("TextLabel")
	runeLbl.Size = UDim2.fromScale(1, 1)
	runeLbl.BackgroundTransparency = 1
	runeLbl.Font = Enum.Font.GothamBlack
	runeLbl.TextSize = 32
	runeLbl.TextColor3 = Color3.fromRGB(255, 30, 80)
	runeLbl.Text = "試\n煉\nの\n碑\n⚡"
	runeLbl.Parent = runeGui

	-- Glowing Red Lanterns on sides
	for _, xOffset in ipairs({ -3.2, 3.2 }) do
		local lantern = Instance.new("Part")
		lantern.Size = Vector3.new(1, 2, 1)
		lantern.Position = altarPos + Vector3.new(xOffset, 2, 0)
		lantern.Color = Color3.fromRGB(255, 40, 60)
		lantern.Material = Enum.Material.Neon
		lantern.Anchored = true
		lantern.Parent = altarModel

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 50, 80)
		light.Range = 12
		light.Brightness = 2
		light.Parent = lantern
	end

	-- Proximity Prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Mulai Ujian Shinobi (Wave Incursion)"
	prompt.ObjectText = "Altar Inskripsi Kuno"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = stone

	prompt.Triggered:Connect(function(player)
		if isWaveActive then
			evWaveReward:FireClient(player, {
				Success = false,
				Message = "Gelombang musuh sedang aktif! Selesaikan dulu atau tunggu hingga selesai.",
			})
			return
		end

		isWaveActive = true
		waveStarterPlayer = player
		print(string.format(">> [WaveSurvival] %s triggered the Shinobi Trial Altar! <<", player.Name))
		spawnWave(1)
	end)

	altarModel.Parent = Workspace
	print(">> [WaveSurvival] Shinobi Trial Altar built at: " .. tostring(altarPos) .. " <<")
end

task.delay(1.5, function()
	buildTrialAltar()
end)

print("[WaveSurvivalServerManager] ✅ PvE Wave Survival & Akatsuki Boss Engine active.")

