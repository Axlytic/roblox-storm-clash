--!strict
-- CombatServerMaster.luau
-- SERVER SCRIPT: Authoritative Combat Server Master
-- Features:
--   • Authoritative Hitbox & Distance Validation
--   • Tekken Defense & Just-Frame Parry Counter Verification
--   • Floating Combat Damage Indicators & Visual Block Feedback
--   • Naruto Storm 4 Assist Striker NPC Spawner & Jutsu Projectile Handler
--   • Full Integration with Training Dummy & Multiplayer PvP

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- =========================================================
-- 1. ENSURE COMBAT REMOTES
-- =========================================================
local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents") :: Folder?
if not combatEvents then
	combatEvents = Instance.new("Folder")
	combatEvents.Name = "CombatEvents"
	combatEvents.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evNinjaDash  = ensureRemote("NinjaDashEvent")
local evSidestep   = ensureRemote("SidestepEvent")
local evBlock      = ensureRemote("BlockEvent")
local evParry      = ensureRemote("ParryEvent")
local evAttack     = ensureRemote("AttackEvent")
local evAssist     = ensureRemote("AssistEvent")
local evLeaderSwap = ensureRemote("LeaderSwapEvent")
local evRanged     = ensureRemote("RangedAttackEvent")
local evSub        = ensureRemote("SubstitutionEvent")
local evCounter    = ensureRemote("CounterEvent")
local evNinjutsu   = ensureRemote("NinjutsuEvent")

-- =========================================================
-- 2. PLAYER COMBAT STATE TRACKING (Storm 4 + Tekken)
-- =========================================================
type PlayerCombatState = {
	isBlocking: boolean,
	blockType: string,
	blockStartTime: number,
	guardHealth: number,
	lastParriedTime: number,
	subStocks: number,
	lastSubTime: number,
	lastDamageTime: number,
	isCountering: boolean,
	counterStartTime: number,
	lastAttacker: Model?,
}

local playerCombatStates: { [number]: PlayerCombatState } = {}

local function setupPlayer(player: Player)
	playerCombatStates[player.UserId] = {
		isBlocking = false,
		blockType = "None",
		blockStartTime = 0,
		guardHealth = 100,
		lastParriedTime = 0,
		subStocks = 4,
		lastSubTime = 0,
		lastDamageTime = 0,
		isCountering = false,
		counterStartTime = 0,
		lastAttacker = nil,
	}
	player:SetAttribute("SubstitutionStocks", 4)
	player:SetAttribute("ChakraValue", 60)
	player:SetAttribute("IsBlocking", false)
	player:SetAttribute("IsCountering", false)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerCombatStates[player.UserId] = nil
end)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

-- Background Sub Stock Regeneration (1 stock every 12 seconds when not taking damage)
task.spawn(function()
	while true do
		task.wait(1.0)
		local now = os.clock()
		for userId, state in pairs(playerCombatStates) do
			local player = Players:GetPlayerByUserId(userId)
			if player and state.subStocks < 4 then
				-- Regenerate if player hasn't taken damage in last 3 seconds
				if now - state.lastDamageTime >= 3.0 and now - state.lastSubTime >= 12.0 then
					state.subStocks = math.min(4, state.subStocks + 1)
					state.lastSubTime = now
					player:SetAttribute("SubstitutionStocks", state.subStocks)
				end
			end
		end
	end
end)

-- =========================================================
-- 2B. 3D WOODEN LOG & SMOKE (Storm 4 Kawarimi Effect)
-- =========================================================
local function spawnSubstitutionLog(cf: CFrame)
	local log = Instance.new("Part")
	log.Name = "KawarimiWoodLog"
	log.Shape = Enum.PartType.Cylinder
	log.Size = Vector3.new(2.8, 1.4, 1.4)
	log.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	log.Color = Color3.fromRGB(139, 90, 43)
	log.Material = Enum.Material.Wood
	log.Anchored = false
	log.CanCollide = true
	log.Parent = Workspace
	Debris:AddItem(log, 2.2)

	-- Puff of Smoke Emitter
	local att = Instance.new("Attachment", log)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(245, 245, 250), Color3.fromRGB(210, 210, 220))
	pe.Size = NumberSequence.new(2.5, 5.0)
	pe.Transparency = NumberSequence.new(0.2, 1.0)
	pe.Rate = 120
	pe.Speed = NumberRange.new(5, 14)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Parent = att
	task.delay(0.2, function() pe.Enabled = false end)

	-- Sound
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
-- 3. FLOATING COMBAT TEXT
-- =========================================================
local function spawnFloatingText(pos: Vector3, text: string, color: Color3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = pos + Vector3.new(math.random(-1, 1), 2.5, math.random(-1, 1))
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 45)
	bb.AlwaysOnTop = true
	bb.Parent = part

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb

	local tween = TweenService:Create(part, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = part.Position + Vector3.new(0, 3, 0),
	})
	tween:Play()

	task.delay(0.75, function()
		part:Destroy()
	end)
end

-- =========================================================
-- 4. BLOCK & PARRY LISTENERS
-- =========================================================
evBlock.OnServerEvent:Connect(function(player: Player, isBlocking: boolean, blockType: string, blockStartTime: number)
	local state = playerCombatStates[player.UserId]
	if state then
		state.isBlocking = isBlocking
		state.blockType = blockType or "None"
		state.blockStartTime = blockStartTime or os.clock()
		-- Broadcast to other clients for stance visuals
		evBlock:FireAllClients(player, isBlocking, blockType)
	end
end)

-- =========================================================
-- 5. ATTACK HANDLER (High/Mid/Low Guard & Parry Logic)
-- =========================================================
evAttack.OnServerEvent:Connect(function(attacker: Player, targetModel: Model, comboStep: number, attackType: string, damage: number, knockback: number)
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local aRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aRoot then return end

	if not targetModel or not targetModel.Parent then return end
	local tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tHum = targetModel:FindFirstChildOfClass("Humanoid")
	if not tRoot or not tHum or tHum.Health <= 0 then return end

	-- 1. Anti-Exploit Range Check (max 18 studs)
	local dist = (tRoot.Position - aRoot.Position).Magnitude
	if dist > 18 then
		return
	end

	-- 2. Determine Defender's Guard State
	local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
	local targetState = targetPlayer and playerCombatStates[targetPlayer.UserId]
	
	local isTargetBlocking = false
	local targetBlockType = "None"
	local targetBlockStartTime = 0

	if targetState then
		isTargetBlocking = targetState.isBlocking
		targetBlockType = targetState.blockType
		targetBlockStartTime = targetState.blockStartTime
	elseif targetModel:GetAttribute("DummyGuardMode") then
		-- Training Dummy configured guard mode
		local dMode = tostring(targetModel:GetAttribute("DummyGuardMode"))
		if dMode == "High" or dMode == "Low" or dMode == "Parry" then
			isTargetBlocking = true
			targetBlockType = dMode
			targetBlockStartTime = os.clock() -- always fresh for testing
		end
	end

	local now = os.clock()

	-- 3. Check for STORM 4 COUNTER ATTACK ([Guard + Attack] / [F + J])
	if targetState and targetState.isCountering and (now - targetState.counterStartTime <= 0.35) then
		print(string.format(">> [STORM 4 COUNTER BLOW] %s countered %s's strike! <<", targetModel.Name, attacker.Name))
		spawnFloatingText(tRoot.Position, "⚔️ COUNTER BLOW!", Color3.fromRGB(255, 215, 0))

		-- Blow attacker back flying across arena & stagger
		local counterDir = -aRoot.CFrame.LookVector
		aRoot.AssemblyLinearVelocity = (counterDir * 55) + Vector3.new(0, 10, 0)
		if targetPlayer then
			evParry:FireClient(targetPlayer, targetPlayer, attacker)
		end
		evParry:FireClient(attacker, targetPlayer or attacker, attacker)
		return
	end

	-- 3B. Check for TEKKEN JUST-FRAME PARRY (180ms window)
	local isParry = isTargetBlocking and (targetBlockType == "Parry" or (now - targetBlockStartTime <= 0.18))
	if isParry then
		print(string.format(">> [TEKKEN PERFECT PARRY] %s counter-parried %s! <<", targetModel.Name, attacker.Name))
		spawnFloatingText(tRoot.Position, "⚡ PERFECT PARRY!", Color3.fromRGB(255, 220, 50))

		-- Stagger attacker
		if targetPlayer then
			evParry:FireClient(targetPlayer, targetPlayer, attacker)
		end
		evParry:FireClient(attacker, targetPlayer or attacker, attacker)
		return
	end

	-- 4. Check for HIGH / MID / LOW GUARD
	local isBlocked = false
	if isTargetBlocking then
		if attackType == "High" and targetBlockType == "High" then
			isBlocked = true
		elseif attackType == "Mid" and targetBlockType == "High" then
			isBlocked = true
		elseif attackType == "Low" and targetBlockType == "Low" then
			isBlocked = true
		end
	end

	if isBlocked then
		-- Attack BLOCKED!
		print(string.format(">> [GUARD BLOCKED] %s blocked %s's %s attack! <<", targetModel.Name, attacker.Name, attackType))
		spawnFloatingText(tRoot.Position, "🛡️ BLOCKED", Color3.fromRGB(0, 220, 255))

		-- Spark block visual
		local blkPart = Instance.new("Part")
		blkPart.Size = Vector3.new(2, 2, 0.2)
		blkPart.CFrame = CFrame.lookAt((aRoot.Position + tRoot.Position) * 0.5, aRoot.Position)
		blkPart.Material = Enum.Material.ForceField
		blkPart.Color = Color3.fromRGB(0, 255, 255)
		blkPart.Anchored = true
		blkPart.CanCollide = false
		blkPart.Parent = Workspace
		Debris:AddItem(blkPart, 0.2)
		return
	end

	-- 5. CLEAN HIT!
	local isAwakening = attacker:GetAttribute("IsAwakening") == true
	local finalDamage = if isAwakening then math.floor(damage * 1.25) else damage
	tHum:TakeDamage(finalDamage)
	local dmgColor = if isAwakening then Color3.fromRGB(255, 30, 30) elseif attackType == "Low" then Color3.fromRGB(255, 170, 0) elseif comboStep == 4 then Color3.fromRGB(255, 50, 50) else Color3.fromRGB(255, 255, 255)
	spawnFloatingText(tRoot.Position, string.format("💥 -%d%s", finalDamage, isAwakening and " [RAGE]" or ""), dmgColor)

	-- Update State for Substitution & Chakra Tracking
	if targetState then
		targetState.lastAttacker = attackerChar
		targetState.lastDamageTime = now
	end
	if targetModel.Name == "TrainingDummy" then
		targetModel:SetAttribute("LastAttackerName", attacker.Name)
	end

	-- Chakra Gain on Hit
	local curChakra = attacker:GetAttribute("ChakraValue") or 60
	attacker:SetAttribute("ChakraValue", math.min(100, curChakra + 10))
	if targetPlayer then
		local tChakra = targetPlayer:GetAttribute("ChakraValue") or 60
		targetPlayer:SetAttribute("ChakraValue", math.min(100, tChakra + 7))
	end

	-- Apply Knockback & Storm Connections Mechanics:
	local hitDir = (tRoot.Position - aRoot.Position).Unit
	local flatHitDir = Vector3.new(hitDir.X, 0, hitDir.Z).Unit

	if attackType == "High" and comboStep == 4 then
		-- 🚀 STORM CONNECTIONS LAUNCHER (UP COMBO FINISHER)
		-- Launch victim 54 studs high into the sky, setting up Air Chase!
		tRoot.AssemblyLinearVelocity = (flatHitDir * 14) + Vector3.new(0, 54, 0)
		targetModel:SetAttribute("IsAirborneLaunched", true)
		targetModel:SetAttribute("VictimHitReaction", "Launched")
		spawnFloatingText(tRoot.Position + Vector3.new(0, 3, 0), "🚀 AIR LAUNCH!", Color3.fromRGB(180, 100, 255))
		
		if _G.AwardCombatRyo then _G.AwardCombatRyo(attacker, 5, "Air Launcher") end

		task.delay(1.8, function()
			if targetModel and targetModel.Parent then
				targetModel:SetAttribute("IsAirborneLaunched", false)
			end
		end)

	elseif (attackType == "Low" and comboStep == 4) or (attackType == "Mid" and comboStep == 3 and tRoot.Position.Y > 8) then
		-- 💥 GROUND SLAM & GROUND BOUNCE (DOWN COMBO FINISHER / AIR SPIKE)
		tRoot.AssemblyLinearVelocity = (flatHitDir * 8) + Vector3.new(0, -68, 0)
		targetModel:SetAttribute("VictimHitReaction", "GroundBounce")

		-- Spawn Impact Crater when hitting ground
		task.delay(0.12, function()
			if not tRoot or not tRoot.Parent then return end
			local craterPos = Vector3.new(tRoot.Position.X, 3.1, tRoot.Position.Z)
			
			local crater = Instance.new("Part")
			crater.Name = "GroundImpactCrater"
			crater.Shape = Enum.PartType.Cylinder
			crater.Size = Vector3.new(0.3, 7.5, 7.5)
			crater.CFrame = CFrame.new(craterPos) * CFrame.Angles(0, 0, math.rad(90))
			crater.Material = Enum.Material.Slate
			crater.Color = Color3.fromRGB(50, 45, 40)
			crater.Anchored = true
			crater.CanCollide = false
			crater.Parent = Workspace
			Debris:AddItem(crater, 3.0)

			-- Bounce rebound impulse (OTG window)
			tRoot.AssemblyLinearVelocity = Vector3.new(flatHitDir.X * 6, 14, flatHitDir.Z * 6)
			targetModel:SetAttribute("IsGroundBounced", true)
			spawnFloatingText(craterPos + Vector3.new(0, 2, 0), "💥 GROUND BOUNCE!", Color3.fromRGB(255, 170, 0))

			if _G.AwardCombatRyo then _G.AwardCombatRyo(attacker, 6, "Ground Bounce OTG") end

			task.delay(0.85, function()
				if targetModel and targetModel.Parent then
					targetModel:SetAttribute("IsGroundBounced", false)
				end
			end)
		end)

	elseif comboStep == 4 then
		-- Heavy Neutral Knockback
		tRoot.AssemblyLinearVelocity = (flatHitDir * knockback) + Vector3.new(0, 12, 0)
		targetModel:SetAttribute("VictimHitReaction", "HeavyKnockback")
		if _G.AwardCombatRyo then _G.AwardCombatRyo(attacker, 4, "Combo Finisher") end
	else
		-- Regular combo flinch (Hit 1, 2, 3)
		local liftY = if comboStep == 3 then 6 else 0
		tRoot.AssemblyLinearVelocity = (flatHitDir * knockback) + Vector3.new(0, liftY, 0)
		local reactType = if comboStep == 1 then "High" elseif comboStep == 2 then "Mid" else "Stagger"
		targetModel:SetAttribute("VictimHitReaction", reactType)
		if _G.AwardCombatRyo then _G.AwardCombatRyo(attacker, 1, "Combo Hit") end
	end
end)

-- =========================================================
-- 5B. SUBSTITUTION JUTSU (Kawarimi - The Lifeline of Combat)
-- =========================================================
evSub.OnServerEvent:Connect(function(player: Player)
	local state = playerCombatStates[player.UserId]
	if not state or state.subStocks < 1 then
		return
	end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	-- Find attacker to teleport behind
	local targetChar: Model? = state.lastAttacker
	if not targetChar or not targetChar.Parent then
		-- Fallback: check nearest opponent in front
		local dummy = Workspace:FindFirstChild("TrainingDummy")
		if dummy and dummy:IsA("Model") then
			targetChar = dummy
		else
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local dist = (p.Character:GetPivot().Position - root.Position).Magnitude
					if dist <= 30 then
						targetChar = p.Character
						break
					end
				end
			end
		end
	end

	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	-- 1. Deduct Sub Stock & Reset Hitstun
	state.subStocks -= 1
	state.lastSubTime = os.clock()
	player:SetAttribute("SubstitutionStocks", state.subStocks)

	-- 2. Spawn 3D Wood Log & Smoke Puff at player's previous location
	local prevCFrame = root.CFrame
	spawnSubstitutionLog(prevCFrame)

	-- 3. Teleport 4.5 studs directly BEHIND the attacker facing their back!
	local behindPos = targetRoot.Position - (targetRoot.CFrame.LookVector * 4.5)
	root.CFrame = CFrame.lookAt(behindPos, targetRoot.Position)
	root.AssemblyLinearVelocity = Vector3.zero

	-- 4. Floating Text & Broadcast
	spawnFloatingText(root.Position, "🪵 KAWARIMI!", Color3.fromRGB(255, 215, 0))
	evSub:FireAllClients(player, prevCFrame)

	print(string.format(">> [SUBSTITUTION JUTSU] %s substituted behind %s! (%d logs left) <<", player.Name, targetChar.Name, state.subStocks))
end)

-- =========================================================
-- 5C. STORM 4 COUNTER ATTACK STANCE TOGGLE ([F + J])
-- =========================================================
evCounter.OnServerEvent:Connect(function(player: Player, isCountering: boolean)
	local state = playerCombatStates[player.UserId]
	if state then
		state.isCountering = isCountering
		state.counterStartTime = if isCountering then os.clock() else 0
		player:SetAttribute("IsCountering", isCountering)
		evCounter:FireAllClients(player, isCountering)
	end
end)

-- =========================================================
-- 5D. CHARACTER NINJUTSU ([I] + [J] Chakra Rush)
-- =========================================================
evNinjutsu.OnServerEvent:Connect(function(player: Player, targetModel: Model?)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local curChakra = player:GetAttribute("ChakraValue") or 60
	if curChakra < 25 then
		spawnFloatingText(root.Position, "⚠️ NOT ENOUGH CHAKRA!", Color3.fromRGB(255, 100, 100))
		return
	end

	-- Deduct 25 Chakra
	player:SetAttribute("ChakraValue", curChakra - 25)

	local charId = tostring(player:GetAttribute("SelectedCharacter") or "Naruto")
	local charData = CombatConfig.Characters[charId] or CombatConfig.Characters["Naruto"]
	local jutsu = charData.NinjutsuSkill or {
		Name = "Ninjutsu Strike",
		Damage = 30,
		RushSpeed = 90,
		Color = Color3.fromRGB(0, 220, 255),
		Knockback = 45,
		LiftY = 12,
	}

	-- Find target
	local tRoot: BasePart? = nil
	local tHum: Humanoid? = nil
	if targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
		tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart
		tHum = targetModel:FindFirstChildOfClass("Humanoid")
	else
		local dummy = Workspace:FindFirstChild("TrainingDummy")
		if dummy and dummy:FindFirstChild("HumanoidRootPart") then
			tRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
			tHum = dummy:FindFirstChildOfClass("Humanoid")
		end
	end

	-- Forward Rush Impulse
	local rushDir = root.CFrame.LookVector
	root.AssemblyLinearVelocity = rushDir * (jutsu.RushSpeed or 90)

	-- Sonic Jutsu Visual Part
	local jutsuPart = Instance.new("Part")
	jutsuPart.Shape = Enum.PartType.Ball
	jutsuPart.Size = Vector3.new(3.5, 3.5, 3.5)
	jutsuPart.CFrame = root.CFrame * CFrame.new(0, 0, -2.5)
	jutsuPart.Material = Enum.Material.Neon
	jutsuPart.Color = jutsu.Color or Color3.fromRGB(0, 240, 255)
	jutsuPart.CanCollide = false
	jutsuPart.Anchored = false
	jutsuPart.Parent = Workspace

	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = jutsuPart
	w.Parent = jutsuPart

	local att = Instance.new("Attachment", jutsuPart)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(jutsu.Color or Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(2, 0)
	pe.Rate = 90
	pe.Speed = NumberRange.new(5, 15)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Parent = att

	Debris:AddItem(jutsuPart, 0.6)

	-- Hit registration
	task.delay(0.18, function()
		if tRoot and tHum and tHum.Health > 0 then
			local dist = (tRoot.Position - root.Position).Magnitude
			if dist <= 14 then
				tHum:TakeDamage(jutsu.Damage or 30)
				spawnFloatingText(tRoot.Position, string.format("💥 %s -%d!", jutsu.Name, jutsu.Damage or 30), jutsu.Color or Color3.fromRGB(0, 240, 255))
				local knockDir = (tRoot.Position - root.Position).Unit
				tRoot.AssemblyLinearVelocity = (knockDir * (jutsu.Knockback or 45)) + Vector3.new(0, jutsu.LiftY or 12, 0)
			end
		end
	end)

	print(string.format(">> [NINJUTSU ACTIVATED] %s unleashed %s! <<", player.Name, jutsu.Name))
end)

-- =========================================================
-- 6. STORM 4 ASSIST STRIKER JUTSU
-- =========================================================
evAssist.OnServerEvent:Connect(function(player: Player, strikerType: string)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Find Target to aim jutsu at
	local targetRoot: BasePart? = nil
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:FindFirstChild("HumanoidRootPart") then
		targetRoot = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				targetRoot = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart
				break
			end
		end
	end

	-- 1. Spawn Striker Companion NPC beside player
	local strikerModel = Instance.new("Model")
	strikerModel.Name = "AssistStriker_" .. player.Name

	local sRoot = Instance.new("Part")
	sRoot.Name = "HumanoidRootPart"
	sRoot.Size = Vector3.new(2, 2, 1)
	sRoot.CFrame = root.CFrame * CFrame.new(3.5, 0, 1.5)
	sRoot.Color = Color3.fromRGB(40, 50, 80)
	sRoot.Material = Enum.Material.SmoothPlastic
	sRoot.Anchored = true
	sRoot.CanCollide = false
	sRoot.Parent = strikerModel

	local sHead = Instance.new("Part")
	sHead.Name = "Head"
	sHead.Size = Vector3.new(1.2, 1.2, 1.2)
	sHead.CFrame = sRoot.CFrame * CFrame.new(0, 1.6, 0)
	sHead.Color = Color3.fromRGB(220, 180, 140)
	sHead.Anchored = true
	sHead.CanCollide = false
	sHead.Parent = strikerModel

	-- Tag Billboard
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 140, 0, 35)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = sHead

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⚡ STRIKER JUTSU!"
	lbl.TextColor3 = Color3.fromRGB(0, 255, 200)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb

	strikerModel.Parent = Workspace

	-- 2. Fire Jutsu Projectile toward target
	if targetRoot then
		local startPos = sRoot.Position + Vector3.new(0, 1.5, 0)
		local endPos = targetRoot.Position + Vector3.new(0, 1.5, 0)
		local jutsuDir = (endPos - startPos).Unit

		local orb = Instance.new("Part")
		orb.Name = "JutsuOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(2.5, 2.5, 2.5)
		orb.Position = startPos
		orb.Color = Color3.fromRGB(0, 220, 255)
		orb.Material = Enum.Material.Neon
		orb.CanCollide = false
		orb.Anchored = false
		orb.Parent = Workspace

		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
		pe.Size = NumberSequence.new(1.5, 0)
		pe.Rate = 50
		pe.Speed = NumberRange.new(5, 12)
		pe.Lifetime = NumberRange.new(0.3, 0.5)
		pe.Parent = orb

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = jutsuDir * 80
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bv.Parent = orb

		orb.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			if model and model ~= char and model ~= strikerModel then
				local hum = model:FindFirstChildOfClass("Humanoid")
				local r = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hum and r then
					hum:TakeDamage(22)
					spawnFloatingText(r.Position, "⚡ JUTSU IMPACT -22", Color3.fromRGB(0, 255, 255))
					r.AssemblyLinearVelocity = jutsuDir * 40 + Vector3.new(0, 10, 0)
					orb:Destroy()
				end
			end
		end)

		Debris:AddItem(orb, 2.5)
	end

	-- Despawn Striker after 2.8 seconds
	task.delay(2.8, function()
		strikerModel:Destroy()
	end)
end)

-- =========================================================
-- 7. ULTIMATE SECRET TECHNIQUE (Storm 4 Finisher)
-- =========================================================
local evUltimate = ensureRemote("UltimateEvent")
evUltimate.OnServerEvent:Connect(function(attacker: Player, targetModel: Model)
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local aRoot = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aRoot then return end

	if not targetModel or not targetModel.Parent then return end
	local tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tHum = targetModel:FindFirstChildOfClass("Humanoid")
	if not tRoot or not tHum or tHum.Health <= 0 then return end

	local dist = (tRoot.Position - aRoot.Position).Magnitude
	if dist > 25 then return end

	local isAwakening = attacker:GetAttribute("IsAwakening") == true
	local ultDmg = if isAwakening then 65 else 52
	tHum:TakeDamage(ultDmg)
	spawnFloatingText(tRoot.Position, string.format("⚡ ULTIMATE FINISH -%d!", ultDmg), Color3.fromRGB(255, 220, 50))
	local hitDir = (tRoot.Position - aRoot.Position).Unit
	tRoot.AssemblyLinearVelocity = hitDir * 75 + Vector3.new(0, 20, 0)
end)

-- =========================================================
-- 8. AUTHENTIC ANIME RANGED ATTACK HANDLER ([L] Key)
-- =========================================================
evRanged.OnServerEvent:Connect(function(attacker: Player, aimDir: Vector3?, requestedCharId: string?)
	local char = attacker.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local charId = tostring(attacker:GetAttribute("SelectedCharacter") or requestedCharId or "Naruto")
	local charData = CombatConfig.Characters[charId] or CombatConfig.Characters["Naruto"]
	local skill = charData.RangedSkill or {
		Name = "Chakra Projectile",
		Damage = 18,
		Speed = 110,
		Lifetime = 2.0,
		Color = Color3.fromRGB(0, 230, 255),
	}

	local finalAimDir = if typeof(aimDir) == "Vector3" and aimDir.Magnitude > 0.1 then aimDir.Unit else root.CFrame.LookVector
	local startPos = root.Position + Vector3.new(0, 1.2, 0) + (finalAimDir * 2.5)

	-- 1. Create Anime Themed Projectile Model / Part
	local proj = Instance.new("Part")
	proj.Name = "AnimeProjectile_" .. charId
	proj.CanCollide = false
	proj.Anchored = false
	proj.Material = Enum.Material.Neon
	proj.Color = skill.Color or Color3.fromRGB(0, 230, 255)

	-- Distinct 3D mesh shaping per anime character skill shape:
	local shape = skill.Shape or "Ball"
	if shape == "Disc" then
		-- Aerodynamic Disc (Rasen-Shuriken, Destructo Disc)
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(0.4, 3.2, 3.2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, 0, math.rad(90))
	elseif shape == "Ball" then
		-- Blazing Energy / Flame Sphere (Goukakyuu, Ki Blast, Blue, Stun Grenade)
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(2.8, 2.8, 2.8)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif shape == "Fist" then
		-- Elastic / Air Shockwave Fist (Gum-Gum Pistol, Delaware Smash)
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(3.0, 1.6, 1.6)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, math.rad(90), 0)
	elseif shape == "SlashBlade" then
		-- Flying Anime Blade Wave (36 Pound Phoenix, Getsuga Tensho, Dismantle, Striking Tide)
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.3, 3.8, 2.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif shape == "Bolt" then
		-- Piercing Lightning Bolt / Hound (Narukami, Raiju, Thunder Spark)
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.7, 0.7, 3.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	else
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(2.4, 2.4, 2.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	end

	-- 2. Anime Particle Emitter
	local att = Instance.new("Attachment", proj)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(skill.Color or Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(1.4, 0)
	pe.Rate = 50
	pe.Speed = NumberRange.new(3, 8)
	pe.Lifetime = NumberRange.new(0.25, 0.45)
	pe.Parent = att

	-- 3. High-Speed Propulsion
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = finalAimDir * (skill.Speed or 110)
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Parent = proj

	proj.Parent = Workspace
	Debris:AddItem(proj, skill.Lifetime or 2.2)

	-- 4. Authoritative Collision & Damage
	local hitProcessed = false
	proj.Touched:Connect(function(hit)
		if hitProcessed then return end
		local targetModel = hit:FindFirstAncestorOfClass("Model")
		if not targetModel or targetModel == char or targetModel.Name:find("AssistStriker") then
			return
		end

		local tHum = targetModel:FindFirstChildOfClass("Humanoid")
		local tRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not tHum or not tRoot or tHum.Health <= 0 then
			return
		end

		hitProcessed = true

		-- Guard Check for Defender
		local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
		local targetState = targetPlayer and playerCombatStates[targetPlayer.UserId]
		local isGuarding = false
		if targetState then
			isGuarding = targetState.isBlocking and targetState.blockType == "High"
		elseif targetModel:GetAttribute("DummyGuardMode") == "High" then
			isGuarding = true
		end

		local isAwakening = attacker:GetAttribute("IsAwakening") == true
		local baseDmg = skill.Damage or 20
		local finalDmg = if isAwakening then math.floor(baseDmg * 1.25) else baseDmg

		if isGuarding then
			-- Projectile Guarded! Reduced chip damage
			local chipDmg = math.max(2, math.floor(finalDmg * 0.25))
			tHum:TakeDamage(chipDmg)
			spawnFloatingText(tRoot.Position, string.format("🛡️ BLOCKED (-%d)", chipDmg), Color3.fromRGB(0, 220, 255))
			tRoot.AssemblyLinearVelocity = finalAimDir * 12
		else
			-- Clean Anime Jutsu Hit!
			tHum:TakeDamage(finalDmg)
			local hitColor = skill.Color or Color3.fromRGB(255, 120, 30)
			spawnFloatingText(tRoot.Position, string.format("💥 %s -%d!", skill.Name, finalDmg), hitColor)
			tRoot.AssemblyLinearVelocity = finalAimDir * 42 + Vector3.new(0, 8, 0)
		end

		-- Hit burst particle
		pcall(function()
			local burst = Instance.new("Part")
			burst.Shape = Enum.PartType.Ball
			burst.Size = Vector3.new(3, 3, 3)
			burst.Position = proj.Position
			burst.Material = Enum.Material.Neon
			burst.Color = skill.Color or Color3.fromRGB(255, 200, 50)
			burst.Anchored = true
			burst.CanCollide = false
			burst.Parent = Workspace
			TweenService:Create(burst, TweenInfo.new(0.22), {
				Size = Vector3.new(5, 5, 5),
				Transparency = 1,
			}):Play()
			Debris:AddItem(burst, 0.25)
		end)

		proj:Destroy()
	end)
end)

print("[CombatServerMaster] ✅ Authoritative Combat Server Master fully initialized.")
