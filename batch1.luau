local function install(name, sType, parent, src)
    local ex = parent:FindFirstChild(name)
    if ex then ex:Destroy() end
    local s = Instance.new(sType)
    s.Name = name
    s.Source = src
    s.Parent = parent
    print('[Installed] ' .. sType .. ': ' .. name)
end

do
    local src = [=====[--!strict
-- CombatConfig.luau
-- Shared configuration for Naruto Storm 4 Camera + Movement + Tekken Defense + Jump Force MUGEN 14 Architecture

local CombatConfig = {}

-- =========================================================
-- 0. NARUTO STORM KEYBOARD & CONTROLLER MAPPING
-- =========================================================
CombatConfig.Controls = {
	MoveForward   = Enum.KeyCode.W,         -- Maju
	MoveLeft      = Enum.KeyCode.A,         -- Kiri
	MoveBackward  = Enum.KeyCode.S,         -- Mundur
	MoveRight     = Enum.KeyCode.D,         -- Kanan
	PunchMelee    = Enum.KeyCode.J,         -- Pukulan Biasa (4-Hit Attack Combo)
	LowSweep      = Enum.KeyCode.K,         -- Serangan Bawah (Low Sweep Attack)
	RangedJutsu   = Enum.KeyCode.L,         -- Serangan Jarak Jauh (Anime Ranged Projectile)
	ChakraEnergy  = Enum.KeyCode.I,         -- Mengisi Energi / Hold untuk Ultimate Ougi
	GuardDefense  = Enum.KeyCode.F,         -- Pertahanan / Tekken High & Low Guard
	NinjaDash     = Enum.KeyCode.LeftShift, -- Ninja Dash (also Q / Double-tap Space)
}

-- =========================================================
-- 1. CAMERA SETTINGS (Naruto Storm 4 Dual-Target Framing)
-- =========================================================
CombatConfig.Camera = {
	MinDistance     = 14,    -- Minimum camera zoom distance (close combat)
	MaxDistance     = 46,    -- Maximum camera zoom distance (far apart)
	BaseHeight      = 6.2,   -- Default camera height above ground
	HeightFactor    = 0.38,  -- How much camera raises when fighters jump in air
	SideOffset      = 3.4,   -- Over-the-shoulder offset for cinematic arena view
	SmoothSpeed     = 12,    -- Camera lerp responsiveness (higher = snappier)
	FOV_Default     = 65,    -- Standard combat field-of-view
	FOV_Dashing     = 76,    -- Dynamic FOV increase during high-speed Ninja Dash
}

-- =========================================================
-- 2. MOVEMENT & DASH SETTINGS (Storm 4 Mobility & Tekken Sidestep)
-- =========================================================
CombatConfig.Movement = {
	NormalWalkSpeed  = 16,
	CombatRunSpeed   = 24,
	NinjaDashSpeed   = 85,    -- High-speed homing dash toward opponent
	NinjaDashRange   = 80,    -- Max distance to lock and dash
	DashDuration     = 0.70,  -- Max duration of a single dash
	StopDistance     = 6.5,   -- Stop dash when within melee strike range
	
	-- Tekken 3D Sidestep
	DoubleTapWindow  = 0.28,  -- Seconds between key presses to trigger sidestep
	SidestepDistance = 16,    -- Studs traveled in sidestep arc
	SidestepVelocity = 58,    -- Fast snappy lateral evasion impulse
	SidestepDuration = 0.24,
	SidestepCooldown = 0.65,
}

-- =========================================================
-- 3. DEFENSE & PARRY SETTINGS (Tekken Technical Defense)
-- =========================================================
CombatConfig.Defense = {
	MaxGuardHealth     = 100,
	GuardRegenRate     = 15,    -- HP regenerated per second when not blocking
	GuardDamageAbsorb  = 22,    -- Guard meter absorbed on high/mid hit
	GuardBreakStunTime = 2.2,   -- Stun duration if guard bar breaks (Guard Crush)
	
	-- Tekken Just-Frame Parry
	ParryWindow        = 0.18,  -- 180ms window from pressing Guard (F) to achieve Perfect Parry
	ParryStaggerTime   = 1.15,  -- Attacker stagger duration on being parried
}

-- =========================================================
-- 4. ATTACK & COMBO SETTINGS (Core Fighting Strings)
-- =========================================================
CombatConfig.Combo = {
	ComboResetTime   = 0.85,  -- Seconds before combo counter resets to 1
	MaxMeleeRange    = 7.5,   -- Max range for basic melee hits
	LungeDistance    = 4.5,   -- Forward step distance toward target on strike

	-- 4-Hit M1 Attack String
	Hits = {
		[1] = {
			Damage = 8,
			Hitstun = 0.32,
			Knockback = 3,
			AttackType = "High", -- High attack (can be blocked by High Guard)
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Pitch = 1.3,
		},
		[2] = {
			Damage = 10,
			Hitstun = 0.35,
			Knockback = 4,
			AttackType = "Mid",  -- Mid attack (blocked by High Guard)
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Pitch = 1.1,
		},
		[3] = {
			Damage = 14,
			Hitstun = 0.42,
			Knockback = 6,
			LiftY = 6,           -- Launches opponent slightly into the air
			AttackType = "High",
			Sound = "rbxasset://sounds/volume_slider.ogg",
			Pitch = 1.5,
		},
		[4] = {
			Damage = 24,
			Hitstun = 1.1,
			Knockback = 48,      -- Heavy finisher blow: launches opponent flying
			LiftY = 8,
			AttackType = "Mid",
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Pitch = 1.0,
		},
	},

	-- Crouch M1: Low Shinobi Sweep
	CrouchSweep = {
		Damage = 16,
		Hitstun = 0.75,
		Knockback = 12,
		AttackType = "Low",   -- LOW attack (Bypasses High Guard! Must use Low Guard to block!)
		Sound = "rbxasset://sounds/action_jump.mp3",
		Pitch = 1.4,
	},
}

-- =========================================================
-- 5. SUPPORT ASSIST & LEADER SWAP (Storm 4 Tag-Team Mechanics)
-- =========================================================
CombatConfig.Assist = {
	AssistCooldown   = 20,    -- Seconds cooldown after calling assist
	AssistDuration   = 2.8,   -- Seconds striker stays in arena before leaping out
	LeaderSwapWindow = 0.4,   -- Time window to swap leader during attack
	StrikerTypes = {
		["FireballStriker"] = {
			Name = "Fireball Striker",
			Jutsu = "Flame Bullet",
			Damage = 22,
			Range = 60,
			Color = Color3.fromRGB(255, 80, 20),
		},
		["ChidoriStriker"] = {
			Name = "Lightning Striker",
			Jutsu = "Lightning Thrust",
			Damage = 26,
			Range = 40,
			Color = Color3.fromRGB(80, 200, 255),
		},
	},
}

-- =========================================================
-- 6. JUMP FORCE MUGEN 14 ARCHETYPES (Scalable Class Framework)
-- =========================================================
CombatConfig.Archetypes = {
	["Rushdown"] = {
		DisplayName = "Rushdown (e.g. Naruto / Luffy)",
		WalkSpeed = 18,
		NinjaDashSpeed = 92,
		GuardHealth = 90,
		Description = "High mobility and rapid combo strings, excels at close-quarters pressure.",
	},
	["Zoner"] = {
		DisplayName = "Zoner (e.g. Sasuke / Goku)",
		WalkSpeed = 15,
		NinjaDashSpeed = 80,
		GuardHealth = 85,
		Description = "Long-range jutsu projectiles and defensive spacing.",
	},
	["Grappler"] = {
		DisplayName = "Grappler (e.g. Broly / All Might)",
		WalkSpeed = 14,
		NinjaDashSpeed = 75,
		GuardHealth = 130,
		Description = "High defense, heavy armor, and crushing unblockable throws.",
	},
	["Sword"] = {
		DisplayName = "Sword Specialist (e.g. Zoro / Ichigo)",
		WalkSpeed = 16,
		NinjaDashSpeed = 86,
		GuardHealth = 100,
		Description = "Disjointed weapon hitboxes, extended melee reach, and sweeping slashes.",
	},
	["Trickster"] = {
		DisplayName = "Trickster (e.g. Killua / Minato)",
		WalkSpeed = 17,
		NinjaDashSpeed = 98,
		GuardHealth = 80,
		Description = "Instant teleport evasion, deceptive feints, and swift counter-attacks.",
	},
}

-- =========================================================
-- 7. ULTIMATE SECRET TECHNIQUE (Storm 4 Cinematic Finisher)
-- =========================================================
CombatConfig.Ultimate = {
	MaxChakra           = 100,
	ChakraGainPerHit    = 12,     -- Gained per successful M1 strike
	ChakraGainOnHit     = 8,      -- Gained when taking damage
	ChakraChargeRate    = 35,     -- Points charged per second while holding [C]
	RushSpeed           = 125,    -- Initial supersonic rush speed
	RushMaxDuration     = 0.85,   -- Max duration to connect with target
	RushConnectDistance = 7.0,    -- Distance to trigger cinematic cutscene
	UltimateDamage      = 52,     -- Massive cinematic finisher damage
	CutsceneDuration    = 2.6,    -- Seconds of dynamic multihit cinematic
}

-- =========================================================
-- 8. AWAKENING / TEKKEN RAGE MODE
-- =========================================================
CombatConfig.Awakening = {
	HealthThreshold  = 0.30,   -- Activates when character HP drops below 30%
	DamageMultiplier = 1.25,   -- +25% attack damage boost in Rage state
	SpeedMultiplier  = 1.20,   -- +20% walk and dash speed boost
	AuraColor        = Color3.fromRGB(255, 45, 45),
}

-- =========================================================
-- 9. MATCH & ROUND SYSTEM (Storm 4 Dual Top Screen HUD)
-- =========================================================
CombatConfig.Match = {
	RoundDuration    = 99,     -- Standard fighting game 99 second timer
	RoundsToWin      = 2,      -- Best of 3 rounds
	IntroDelay       = 3.2,    -- Duration of "ROUND 1... FIGHT!" sequence
	OutroDelay       = 4.0,    -- Duration of "K.O.! VICTORY!" sequence
}

-- =========================================================
-- 10. WEAPON & SLASH VISUALS (Stylized Katana)
-- =========================================================
CombatConfig.Weapon = {
	BladeLength   = 3.8,
	TrailColor    = Color3.fromRGB(0, 240, 255),
	TrailLifetime = 0.22,
	SheathOffset  = CFrame.new(0.8, -0.2, 0.6) * CFrame.Angles(0, 0, math.rad(-140)),
	WieldOffset   = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(-90), 0, 0),
}

-- =========================================================
-- 11. PLAYABLE CHARACTER ROSTER (Jump Force & Storm 4 Roster)
-- =========================================================
CombatConfig.Characters = {
	["Naruto"] = {
		Id = "Naruto",
		Name = "Naruto Uzumaki",
		Anime = "Naruto Shippuden",
		Title = "Hero of the Hidden Leaf",
		Icon = "🦊",
		Archetype = "Rushdown",
		PrimaryColor = Color3.fromRGB(255, 130, 20),
		AccentColor = Color3.fromRGB(0, 220, 255),
		WalkSpeed = 18,
		NinjaDashSpeed = 92,
		GuardHealth = 90,
		Stats = { Speed = 90, Power = 85, Defense = 75, Jutsu = 88 },
		M1Name = "Shinobi Taijutsu Barrage",
		SweepName = "Uzumaki Low Sweep",
		RangedSkill = {
			Name = "Wind Style: Rasen-Shuriken",
			Damage = 20,
			Speed = 110,
			Cooldown = 1.6,
			Lifetime = 2.2,
			Color = Color3.fromRGB(0, 235, 255),
			Shape = "Disc",
			Sound = "rbxasset://sounds/action_whoosh.mp3",
			Icon = "🌀",
		},
		AssistName = "Shadow Clone Rasengan",
		UltimateName = "Wind Style: Rasenshuriken Blast",
		Quote = "I never go back on my word! That's my ninja way!",
	},
	["Sasuke"] = {
		Id = "Sasuke",
		Name = "Sasuke Uchiha",
		Anime = "Naruto Shippuden",
		Title = "Avenger of the Uchiha",
		Icon = "⚡",
		Archetype = "Zoner",
		PrimaryColor = Color3.fromRGB(150, 70, 255),
		AccentColor = Color3.fromRGB(80, 200, 255),
		WalkSpeed = 16,
		NinjaDashSpeed = 88,
		GuardHealth = 95,
		Stats = { Speed = 85, Power = 88, Defense = 80, Jutsu = 96 },
		M1Name = "Kusanagi Sword Flurry",
		SweepName = "Chidori Stream Sweep",
		RangedSkill = {
			Name = "Fire Style: Fireball Jutsu (Goukakyuu)",
			Damage = 22,
			Speed = 95,
			Cooldown = 1.8,
			Lifetime = 2.5,
			Color = Color3.fromRGB(255, 75, 20),
			Shape = "Ball",
			Sound = "rbxasset://sounds/impact_explosion_03.mp3",
			Icon = "🔥",
		},
		AssistName = "Fireball Jutsu / Flame Bullet",
		UltimateName = "Kirin: Heavenly Lightning Strike",
		Quote = "My dream doesn't exist in the future. It lies in the past.",
	},
	["Luffy"] = {
		Id = "Luffy",
		Name = "Monkey D. Luffy",
		Anime = "One Piece",
		Title = "Captain of the Straw Hats",
		Icon = "🍖",
		Archetype = "Grappler",
		PrimaryColor = Color3.fromRGB(240, 40, 40),
		AccentColor = Color3.fromRGB(255, 215, 0),
		WalkSpeed = 15,
		NinjaDashSpeed = 82,
		GuardHealth = 125,
		Stats = { Speed = 78, Power = 95, Defense = 98, Jutsu = 70 },
		M1Name = "Gum-Gum Pistol Combo",
		SweepName = "Gum-Gum Whip Sweep",
		RangedSkill = {
			Name = "Gum-Gum Pistol (Gomu Gomu no Pistol)",
			Damage = 18,
			Speed = 135,
			Cooldown = 1.4,
			Lifetime = 1.2,
			Color = Color3.fromRGB(245, 185, 140),
			Shape = "Fist",
			Sound = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Icon = "👊",
		},
		AssistName = "Gum-Gum Bazooka Striker",
		UltimateName = "Gear Fourth: King Kong Gun",
		Quote = "I'm gonna be King of the Pirates!",
	},
	["Zoro"] = {
		Id = "Zoro",
		Name = "Roronoa Zoro",
		Anime = "One Piece",
		Title = "Pirate Hunter / Santoryu",
		Icon = "⚔️",
		Archetype = "Sword",
		PrimaryColor = Color3.fromRGB(30, 220, 110),
		AccentColor = Color3.fromRGB(240, 255, 255),
		WalkSpeed = 16,
		NinjaDashSpeed = 86,
		GuardHealth = 105,
		Stats = { Speed = 82, Power = 94, Defense = 88, Jutsu = 80 },
		M1Name = "Three-Sword Style Onigiri",
		SweepName = "Dragon Twister Sweep",
		RangedSkill = {
			Name = "36 Pound Phoenix (Flying Slash)",
			Damage = 21,
			Speed = 115,
			Cooldown = 1.7,
			Lifetime = 2.0,
			Color = Color3.fromRGB(40, 255, 110),
			Shape = "SlashBlade",
			Sound = "rbxasset://sounds/action_jump.mp3",
			Icon = "⚔️",
		},
		AssistName = "1080 Pound Ho Cannon",
		UltimateName = "Billion-Fold World Trichiliocosm",
		Quote = "Scars on the back are a swordsman's shame.",
	},
	["Killua"] = {
		Id = "Killua",
		Name = "Killua Zoldyck",
		Anime = "Hunter x Hunter",
		Title = "Assassin Prodigy",
		Icon = "⚡",
		Archetype = "Trickster",
		PrimaryColor = Color3.fromRGB(0, 255, 230),
		AccentColor = Color3.fromRGB(180, 100, 255),
		WalkSpeed = 18,
		NinjaDashSpeed = 100,
		GuardHealth = 80,
		Stats = { Speed = 99, Power = 80, Defense = 70, Jutsu = 92 },
		M1Name = "Assassin Claws & Palm Strike",
		SweepName = "Rhythm Echo Sweep",
		RangedSkill = {
			Name = "Thunderbolt: Narukami Strike",
			Damage = 20,
			Speed = 145,
			Cooldown = 1.5,
			Lifetime = 1.4,
			Color = Color3.fromRGB(150, 230, 255),
			Shape = "Bolt",
			Sound = "rbxasset://sounds/electronicpingshort.wav",
			Icon = "⚡",
		},
		AssistName = "Thunderbolt Striker",
		UltimateName = "Godspeed: Whirlwind Execution",
		Quote = "If I don't defeat you right now... I can't protect anyone!",
	},
}

return CombatConfig
]=====]
    install('CombatConfig', 'ModuleScript', game:GetService('ReplicatedStorage'), src)
end

do
    local src = [=====[--!strict
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

-- =========================================================
-- 2. PLAYER COMBAT STATE TRACKING
-- =========================================================
type PlayerCombatState = {
	isBlocking: boolean,
	blockType: string,
	blockStartTime: number,
	guardHealth: number,
	lastParriedTime: number,
}

local playerCombatStates: { [number]: PlayerCombatState } = {}

local function setupPlayer(player: Player)
	playerCombatStates[player.UserId] = {
		isBlocking = false,
		blockType = "None",
		blockStartTime = 0,
		guardHealth = 100,
		lastParriedTime = 0,
	}
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerCombatStates[player.UserId] = nil
end)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

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

	-- 3. Check for TEKKEN JUST-FRAME PARRY (180ms window)
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

	-- Apply Knockback
	local hitDir = (tRoot.Position - aRoot.Position).Unit
	local flatHitDir = Vector3.new(hitDir.X, 0, hitDir.Z).Unit
	local liftY = if comboStep == 4 then 12 elseif comboStep == 3 then 6 else 0
	tRoot.AssemblyLinearVelocity = (flatHitDir * knockback) + Vector3.new(0, liftY, 0)
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

	-- Distinct 3D mesh shaping per anime character:
	if charId == "Naruto" then
		-- Rasen-Shuriken: Aerodynamic Disc
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(0.4, 3.2, 3.2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, 0, math.rad(90))
	elseif charId == "Sasuke" then
		-- Goukakyuu Fireball: Giant Blazing Sphere
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(3.0, 3.0, 3.0)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif charId == "Luffy" then
		-- Gum-Gum Pistol: Elastic Fist Cylinder
		proj.Shape = Enum.PartType.Cylinder
		proj.Size = Vector3.new(3.2, 1.6, 1.6)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir) * CFrame.Angles(0, math.rad(90), 0)
	elseif charId == "Zoro" then
		-- 36 Pound Phoenix: Vertical Flying Wind Blade
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.3, 3.8, 2.4)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	elseif charId == "Killua" then
		-- Thunderbolt Narukami: Piercing Lightning Wedge
		proj.Shape = Enum.PartType.Block
		proj.Size = Vector3.new(0.8, 0.8, 3.2)
		proj.CFrame = CFrame.lookAt(startPos, startPos + finalAimDir)
	else
		proj.Shape = Enum.PartType.Ball
		proj.Size = Vector3.new(2, 2, 2)
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
]=====]
    install('CombatServerMaster', 'Script', game:GetService('ServerScriptService'), src)
end

do
    local src = [=====[--!strict
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
]=====]
    install('TrainingDummySpawner', 'Script', game:GetService('ServerScriptService'), src)
end

do
    local src = [=====[--!strict
-- StormWeaponServer.luau
-- SERVER SCRIPT: Stylized Anime Katana & Slash Trail System
-- Features:
--   • Procedural high-polish anime Katana model (no external mesh asset IDs needed!)
--   • Dynamic Motor6D/Weld attachment (Hip Sheath vs. RightHand Combat Grip)
--   • Vibrant Neon Slash Trail for strikes, dashes, and ultimate finishers
--   • Auto-equips upon Player Character spawn or Training Dummy creation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 5) :: Folder
if not combatEvents then
	combatEvents = Instance.new("Folder")
	combatEvents.Name = "CombatEvents"
	combatEvents.Parent = ReplicatedStorage
end

local evWeaponStance = combatEvents:FindFirstChild("WeaponStanceEvent") :: RemoteEvent?
if not evWeaponStance then
	evWeaponStance = Instance.new("RemoteEvent")
	evWeaponStance.Name = "WeaponStanceEvent"
	evWeaponStance.Parent = combatEvents
end

-- =========================================================
-- PROCEDURAL KATANA MODEL BUILDER
-- =========================================================
local function createKatanaModel(): Model
	local model = Instance.new("Model")
	model.Name = "StormKatana"

	-- 1. Handle (Core Motor part)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 1.2, 0.25)
	handle.Color = Color3.fromRGB(24, 26, 32)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = model
	model.PrimaryPart = handle

	-- 2. Pommel (Kashira)
	local pommel = Instance.new("Part")
	pommel.Name = "Pommel"
	pommel.Size = Vector3.new(0.3, 0.15, 0.3)
	pommel.Color = Color3.fromRGB(255, 215, 0)
	pommel.Material = Enum.Material.Metal
	pommel.CanCollide = false
	pommel.Massless = true
	pommel.CFrame = handle.CFrame * CFrame.new(0, -0.65, 0)
	pommel.Parent = model

	local wPommel = Instance.new("WeldConstraint")
	wPommel.Part0 = handle
	wPommel.Part1 = pommel
	wPommel.Parent = handle

	-- 3. Guard (Tsuba)
	local tsuba = Instance.new("Part")
	tsuba.Name = "Tsuba"
	tsuba.Size = Vector3.new(0.65, 0.1, 0.65)
	tsuba.Color = Color3.fromRGB(255, 215, 0)
	tsuba.Material = Enum.Material.Metal
	tsuba.CanCollide = false
	tsuba.Massless = true
	tsuba.CFrame = handle.CFrame * CFrame.new(0, 0.62, 0)
	tsuba.Parent = model

	local wTsuba = Instance.new("WeldConstraint")
	wTsuba.Part0 = handle
	wTsuba.Part1 = tsuba
	wTsuba.Parent = handle

	-- 4. Blade (Katana Steel + Neon Cutting Edge)
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.12, 3.4, 0.32)
	blade.Color = Color3.fromRGB(230, 240, 255)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, 2.35, 0.04)
	blade.Parent = model

	local wBlade = Instance.new("WeldConstraint")
	wBlade.Part0 = handle
	wBlade.Part1 = blade
	wBlade.Parent = handle

	-- Glowing Edge Line
	local edge = Instance.new("Part")
	edge.Name = "NeonEdge"
	edge.Size = Vector3.new(0.06, 3.38, 0.08)
	edge.Color = Color3.fromRGB(0, 240, 255)
	edge.Material = Enum.Material.Neon
	edge.CanCollide = false
	edge.Massless = true
	edge.CFrame = blade.CFrame * CFrame.new(0, 0, 0.15)
	edge.Parent = model

	local wEdge = Instance.new("WeldConstraint")
	wEdge.Part0 = blade
	wEdge.Part1 = edge
	wEdge.Parent = blade

	-- 5. Slash Trail Attachments
	local attBase = Instance.new("Attachment")
	attBase.Name = "TrailBase"
	attBase.Position = Vector3.new(0, -1.6, 0.12)
	attBase.Parent = blade

	local attTip = Instance.new("Attachment")
	attTip.Name = "TrailTip"
	attTip.Position = Vector3.new(0, 1.7, 0.12)
	attTip.Parent = blade

	local trail = Instance.new("Trail")
	trail.Name = "SlashTrail"
	trail.Attachment0 = attTip
	trail.Attachment1 = attBase
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.22
	trail.MinLength = 0.1
	trail.Enabled = false -- Enabled only during swings/dashes
	trail.Parent = blade

	return model
end

-- =========================================================
-- EQUIP / SHEATH LOGIC
-- =========================================================
local function attachKatanaToChar(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local upperTorso = character:FindFirstChild("UpperTorso") :: BasePart? or character:FindFirstChild("Torso") :: BasePart?
	local rightHand = character:FindFirstChild("RightHand") :: BasePart? or character:FindFirstChild("Right Arm") :: BasePart?
	if not root or not upperTorso or not rightHand then return end

	local existing = character:FindFirstChild("StormKatana")
	if existing then existing:Destroy() end

	local katana = createKatanaModel()
	local handle = katana.PrimaryPart
	if not handle then return end

	-- Create Motor6D for animated smooth draw/sheath
	local katanaMotor = Instance.new("Motor6D")
	katanaMotor.Name = "KatanaWeld"
	katanaMotor.Part0 = rightHand -- default in combat hand
	katanaMotor.Part1 = handle
	katanaMotor.C0 = CFrame.new(0, -0.9, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	katanaMotor.Parent = rightHand

	katana.Parent = character
end

-- Handle character spawning
local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		attachKatanaToChar(char)
	end)
	if player.Character then
		attachKatanaToChar(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

-- Also attach katana to Training Dummy if present
task.spawn(function()
	task.wait(1)
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		local torso = dummy:FindFirstChild("Torso") :: BasePart?
		if torso and not dummy:FindFirstChild("StormKatana") then
			local katana = createKatanaModel()
			local handle = katana.PrimaryPart
			if handle then
				local w = Instance.new("WeldConstraint")
				w.Part0 = torso
				w.Part1 = handle
				w.Parent = torso
				handle.CFrame = torso.CFrame * CFrame.new(0.9, -0.2, 0.7) * CFrame.Angles(0, 0, math.rad(-135))
				katana.Parent = dummy
			end
		end
	end
end)

print("[StormWeaponServer] ✅ Anime Katana & Slash Trail System active.")

]=====]
    install('StormWeaponServer', 'Script', game:GetService('ServerScriptService'), src)
end

return 'Batch 1 OK (4 scripts)'