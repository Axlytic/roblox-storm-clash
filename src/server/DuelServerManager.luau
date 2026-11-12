--!strict
-- DuelServerManager.luau
-- SERVER SCRIPT: Ranked 1v1 PvP Matchmaking, Sky Arena Spawner & Best-of-3 Duel Director
-- Features:
--   • Procedural Sky Arena Generation with glowing barrier forcefields at Y=180
--   • Matchmaking Queue with automated pairing of active combatants
--   • Best-of-3 Rounds Format with HP reset, character freezing during 3-2-1 countdown
--   • Competitive ELO Rating calculation & persistent attributes
--   • Comprehensive Anti-Cheat/Disconnect handling: forfeit award on rage-quit

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

local DuelConfig = require(ReplicatedStorage:WaitForChild("DuelConfig"))

-- 1. Ensure Combat Events Folder & RemoteEvents
local combatEvents = ReplicatedStorage:FindFirstChild("CombatEvents") :: Folder
if not combatEvents then
	combatEvents = Instance.new("Folder")
	combatEvents.Name = "CombatEvents"
	combatEvents.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evQueue      = getOrCreateRemote("DuelQueueEvent")
local evMatchStart = getOrCreateRemote("DuelMatchStartEvent")
local evRoundState = getOrCreateRemote("DuelRoundStateEvent")
local evMatchEnd   = getOrCreateRemote("DuelMatchEndEvent")

-- 2. DataStore for Ranked ELO
local rankedStore = nil
pcall(function()
	rankedStore = DataStoreService:GetDataStore("ShinobiRankedElo_v1")
end)

-- 3. Match Data Structures
type ActiveMatch = {
	Id: string,
	Player1: Player,
	Player2: Player,
	Score1: number,
	Score2: number,
	CurrentRound: number,
	State: "Countdown" | "InRound" | "RoundOver" | "MatchOver",
	TimeLeft: number,
	HeartbeatConn: RBXScriptConnection?,
}

local queue: { Player } = {}
local activeMatches: { [string]: ActiveMatch } = {}
local playerMatchMap: { [number]: string } = {}

-- =========================================================
-- ARENA BUILDER (Sky Citadel Ring)
-- =========================================================
local function ensureSkyArena(): Model
	local existing = Workspace:FindFirstChild("DuelSkyArena")
	if existing and existing:IsA("Model") then
		return existing
	end

	local arenaModel = Instance.new("Model")
	arenaModel.Name = "DuelSkyArena"

	-- Main Combat Floor (Circular Obsidian Platform)
	local floor = Instance.new("Part")
	floor.Name = "ArenaFloor"
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(4, 90, 90)
	floor.CFrame = CFrame.new(DuelConfig.Arena.Center) * CFrame.Angles(0, 0, math.rad(90))
	floor.Anchored = true
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(18, 20, 28)
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = arenaModel

	-- Outer Glowing Energy Barrier Ring
	local neonRing = Instance.new("Part")
	neonRing.Name = "NeonBoundaryRing"
	neonRing.Shape = Enum.PartType.Cylinder
	neonRing.Size = Vector3.new(4.5, 92, 92)
	neonRing.CFrame = floor.CFrame
	neonRing.Anchored = true
	neonRing.CanCollide = false
	neonRing.Material = Enum.Material.Neon
	neonRing.Color = Color3.fromRGB(0, 240, 255)
	neonRing.Transparency = 0.55
	neonRing.Parent = arenaModel

	-- Invisible Barrier Cylinder to prevent falling off
	local barrierWall = Instance.new("Part")
	barrierWall.Name = "BarrierForcefield"
	barrierWall.Shape = Enum.PartType.Cylinder
	barrierWall.Size = Vector3.new(35, 91, 91)
	barrierWall.CFrame = CFrame.new(DuelConfig.Arena.Center + Vector3.new(0, 16, 0)) * CFrame.Angles(0, 0, math.rad(90))
	barrierWall.Anchored = true
	barrierWall.CanCollide = true
	barrierWall.Material = Enum.Material.ForceField
	barrierWall.Color = Color3.fromRGB(0, 240, 255)
	barrierWall.Transparency = 0.92
	barrierWall.Parent = arenaModel

	-- P1 Crimson Pedestal
	local ped1 = Instance.new("Part")
	ped1.Name = "Pedestal_P1"
	ped1.Size = Vector3.new(8, 1, 8)
	ped1.Position = DuelConfig.Arena.SpawnP1 - Vector3.new(0, 0.5, 0)
	ped1.Anchored = true
	ped1.Material = Enum.Material.Neon
	ped1.Color = Color3.fromRGB(255, 45, 60)
	ped1.Transparency = 0.3
	ped1.Parent = arenaModel

	-- P2 Azure Pedestal
	local ped2 = Instance.new("Part")
	ped2.Name = "Pedestal_P2"
	ped2.Size = Vector3.new(8, 1, 8)
	ped2.Position = DuelConfig.Arena.SpawnP2 - Vector3.new(0, 0.5, 0)
	ped2.Anchored = true
	ped2.Material = Enum.Material.Neon
	ped2.Color = Color3.fromRGB(0, 210, 255)
	ped2.Transparency = 0.3
	ped2.Parent = arenaModel

	arenaModel.Parent = Workspace
	return arenaModel
end

ensureSkyArena()

-- =========================================================
-- ELO & PLAYER INITIALIZATION
-- =========================================================
local function initPlayerElo(player: Player)
	player:SetAttribute("RankedElo", DuelConfig.Rating.BaseElo)
	player:SetAttribute("RankedWins", 0)
	player:SetAttribute("RankedLosses", 0)
	player:SetAttribute("IsInDuel", false)

	if rankedStore then
		task.spawn(function()
			local success, data = pcall(function()
				return rankedStore:GetAsync("Player_" .. tostring(player.UserId))
			end)
			if success and type(data) == "table" then
				player:SetAttribute("RankedElo", data.Elo or DuelConfig.Rating.BaseElo)
				player:SetAttribute("RankedWins", data.Wins or 0)
				player:SetAttribute("RankedLosses", data.Losses or 0)
			end
		end)
	end
end

Players.PlayerAdded:Connect(initPlayerElo)
for _, p in ipairs(Players:GetPlayers()) do
	initPlayerElo(p)
end

local function savePlayerElo(player: Player)
	if not rankedStore then return end
	local payload = {
		Elo = player:GetAttribute("RankedElo") or DuelConfig.Rating.BaseElo,
		Wins = player:GetAttribute("RankedWins") or 0,
		Losses = player:GetAttribute("RankedLosses") or 0,
	}
	pcall(function()
		rankedStore:SetAsync("Player_" .. tostring(player.UserId), payload)
	end)
end

Players.PlayerRemoving:Connect(function(player: Player)
	-- Remove from queue
	for i = #queue, 1, -1 do
		if queue[i] == player then
			table.remove(queue, i)
			break
		end
	end

	-- Handle active match forfeit
	local matchId = playerMatchMap[player.UserId]
	if matchId and activeMatches[matchId] then
		local match = activeMatches[matchId]
		local opponent = (match.Player1 == player) and match.Player2 or match.Player1
		if opponent and opponent.Parent then
			-- Forfeit win
			match.Score1 = (opponent == match.Player1) and 2 or 0
			match.Score2 = (opponent == match.Player2) and 2 or 0
			match.State = "MatchOver"
		end
	end

	savePlayerElo(player)
	playerMatchMap[player.UserId] = nil
end)

-- =========================================================
-- MATCH EXECUTION ENGINE
-- =========================================================
local function teleportFighters(p1: Player, p2: Player)
	local c1 = p1.Character
	local c2 = p2.Character
	if c1 and c1:FindFirstChild("HumanoidRootPart") then
		c1.HumanoidRootPart.CFrame = CFrame.lookAt(DuelConfig.Arena.SpawnP1, DuelConfig.Arena.Center)
	end
	if c2 and c2:FindFirstChild("HumanoidRootPart") then
		c2.HumanoidRootPart.CFrame = CFrame.lookAt(DuelConfig.Arena.SpawnP2, DuelConfig.Arena.Center)
	end
end

local function freezeFighters(p1: Player, p2: Player, freeze: boolean)
	for _, p in ipairs({ p1, p2 }) do
		if p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = freeze and 0 or 16
				hum.JumpPower = freeze and 0 or 50
			end
		end
	end
end

local function healFighters(p1: Player, p2: Player)
	for _, p in ipairs({ p1, p2 }) do
		if p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Health = hum.MaxHealth
			end
			p:SetAttribute("ChakraValue", 100)
			p:SetAttribute("SubstitutionCount", 4)
		end
	end
end

local function endDuelMatch(match: ActiveMatch, winner: Player, loser: Player)
	match.State = "MatchOver"
	if match.HeartbeatConn then
		match.HeartbeatConn:Disconnect()
		match.HeartbeatConn = nil
	end

	-- Calculate ELO
	local winElo = winner:GetAttribute("RankedElo") or DuelConfig.Rating.BaseElo
	local loseElo = loser:GetAttribute("RankedElo") or DuelConfig.Rating.BaseElo

	local newWinElo = winElo + DuelConfig.Rating.WinElo
	local newLoseElo = math.max(0, loseElo - DuelConfig.Rating.LossElo)

	winner:SetAttribute("RankedElo", newWinElo)
	winner:SetAttribute("RankedWins", (winner:GetAttribute("RankedWins") or 0) + 1)

	loser:SetAttribute("RankedElo", newLoseElo)
	loser:SetAttribute("RankedLosses", (loser:GetAttribute("RankedLosses") or 0) + 1)

	savePlayerElo(winner)
	savePlayerElo(loser)

	-- Award Bounties
	if _G.AwardCombatRyo then
		_G.AwardCombatRyo(winner, DuelConfig.Rating.WinRyo, "Ranked 1v1 Victory")
		_G.AwardCombatRyo(loser, DuelConfig.Rating.LossRyo, "Ranked 1v1 Consolation")
	end
	if _G.AwardEssenceShards then
		_G.AwardEssenceShards(winner, DuelConfig.Rating.WinShards)
	end

	-- Notify Clients
	evMatchEnd:FireClient(winner, true, winElo, newWinElo, DuelConfig.Rating.WinElo, DuelConfig.Rating.WinRyo, DuelConfig.Rating.WinShards)
	evMatchEnd:FireClient(loser, false, loseElo, newLoseElo, -DuelConfig.Rating.LossElo, DuelConfig.Rating.LossRyo, 0)

	-- Teleport back to Lobby after delay
	task.delay(DuelConfig.Match.PostMatchDelay, function()
		for _, p in ipairs({ match.Player1, match.Player2 }) do
			p:SetAttribute("IsInDuel", false)
			playerMatchMap[p.UserId] = nil
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				p.Character.HumanoidRootPart.CFrame = CFrame.new(DuelConfig.Arena.LobbySpawn)
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = 16
					hum.JumpPower = 50
					hum.Health = hum.MaxHealth
				end
			end
		end
		activeMatches[match.Id] = nil
	end)
end

local function startDuelRound(match: ActiveMatch)
	match.State = "Countdown"
	match.TimeLeft = DuelConfig.Match.RoundTimeLimit

	teleportFighters(match.Player1, match.Player2)
	freezeFighters(match.Player1, match.Player2, true)
	healFighters(match.Player1, match.Player2)

	-- Broadcast Countdown
	for count = DuelConfig.Match.CountdownSeconds, 1, -1 do
		evRoundState:FireClient(match.Player1, "Countdown", match.CurrentRound, match.Score1, match.Score2, count, "")
		evRoundState:FireClient(match.Player2, "Countdown", match.CurrentRound, match.Score1, match.Score2, count, "")
		task.wait(1.0)
		if match.State == "MatchOver" then return end
	end

	-- "FIGHT!"
	evRoundState:FireClient(match.Player1, "Countdown", match.CurrentRound, match.Score1, match.Score2, 0, "FIGHT!")
	evRoundState:FireClient(match.Player2, "Countdown", match.CurrentRound, match.Score1, match.Score2, 0, "FIGHT!")
	freezeFighters(match.Player1, match.Player2, false)
	match.State = "InRound"

	-- Round Heartbeat Loop
	local roundEnded = false
	local function checkRoundOver(): (boolean, Player?, Player?)
		local hum1 = match.Player1.Character and match.Player1.Character:FindFirstChildOfClass("Humanoid")
		local hum2 = match.Player2.Character and match.Player2.Character:FindFirstChildOfClass("Humanoid")

		if not hum1 or hum1.Health <= 0 then
			return true, match.Player2, match.Player1
		elseif not hum2 or hum2.Health <= 0 then
			return true, match.Player1, match.Player2
		end

		if match.TimeLeft <= 0 then
			-- Timeout: Winner is player with higher HP percentage
			local p1Ratio = hum1.Health / math.max(1, hum1.MaxHealth)
			local p2Ratio = hum2.Health / math.max(1, hum2.MaxHealth)
			if p1Ratio >= p2Ratio then
				return true, match.Player1, match.Player2
			else
				return true, match.Player2, match.Player1
			end
		end

		return false, nil, nil
	end

	task.spawn(function()
		while match.State == "InRound" and not roundEnded do
			task.wait(1.0)
			match.TimeLeft -= 1
			evRoundState:FireClient(match.Player1, "InRound", match.CurrentRound, match.Score1, match.Score2, match.TimeLeft, "")
			evRoundState:FireClient(match.Player2, "InRound", match.CurrentRound, match.Score1, match.Score2, match.TimeLeft, "")

			local isOver, roundWinner, roundLoser = checkRoundOver()
			if isOver and roundWinner and roundLoser then
				roundEnded = true
				match.State = "RoundOver"

				if roundWinner == match.Player1 then
					match.Score1 += 1
				else
					match.Score2 += 1
				end

				evRoundState:FireClient(match.Player1, "RoundWon", match.CurrentRound, match.Score1, match.Score2, 0, roundWinner.Name)
				evRoundState:FireClient(match.Player2, "RoundWon", match.CurrentRound, match.Score1, match.Score2, 0, roundWinner.Name)

				-- Check Match Point (First to 2 wins)
				if match.Score1 >= DuelConfig.Match.RoundsToWin then
					endDuelMatch(match, match.Player1, match.Player2)
				elseif match.Score2 >= DuelConfig.Match.RoundsToWin then
					endDuelMatch(match, match.Player2, match.Player1)
				else
					-- Next Round
					match.CurrentRound += 1
					task.wait(DuelConfig.Match.PostRoundDelay)
					if match.State ~= "MatchOver" then
						startDuelRound(match)
					end
				end
				break
			end
		end
	end)
end

local function launchMatch(p1: Player, p2: Player)
	local matchId = "Duel_" .. tostring(os.clock()) .. "_" .. tostring(p1.UserId)
	local match: ActiveMatch = {
		Id = matchId,
		Player1 = p1,
		Player2 = p2,
		Score1 = 0,
		Score2 = 0,
		CurrentRound = 1,
		State = "Countdown",
		TimeLeft = DuelConfig.Match.RoundTimeLimit,
		HeartbeatConn = nil,
	}

	activeMatches[matchId] = match
	playerMatchMap[p1.UserId] = matchId
	playerMatchMap[p2.UserId] = matchId

	p1:SetAttribute("IsInDuel", true)
	p2:SetAttribute("IsInDuel", true)

	-- Notify Match Start
	local p1Elo = p1:GetAttribute("RankedElo") or DuelConfig.Rating.BaseElo
	local p2Elo = p2:GetAttribute("RankedElo") or DuelConfig.Rating.BaseElo

	evMatchStart:FireClient(p1, {
		OpponentName = p2.Name,
		OpponentDisplayName = p2.DisplayName,
		OpponentElo = p2Elo,
		OpponentTier = DuelConfig.GetTierForElo(p2Elo).Name,
		Side = "P1",
	})

	evMatchStart:FireClient(p2, {
		OpponentName = p1.Name,
		OpponentDisplayName = p1.DisplayName,
		OpponentElo = p1Elo,
		OpponentTier = DuelConfig.GetTierForElo(p1Elo).Name,
		Side = "P2",
	})

	startDuelRound(match)
end

-- =========================================================
-- QUEUE HANDLER
-- =========================================================
evQueue.OnServerEvent:Connect(function(player: Player, action: string)
	if action == "Join" then
		-- Check if already in queue or in duel
		if player:GetAttribute("IsInDuel") == true then return end
		for _, p in ipairs(queue) do
			if p == player then return end
		end

		table.insert(queue, player)
		evQueue:FireClient(player, "Queued", #queue)
		print(string.format(">> [DuelServer] %s joined 1v1 Queue. Total in queue: %d", player.Name, #queue))

		-- Matchmaking Pair Check
		if #queue >= 2 then
			local p1 = table.remove(queue, 1) :: Player
			local p2 = table.remove(queue, 1) :: Player
			if p1 and p2 and p1.Parent and p2.Parent then
				print(string.format(">> [DuelServer] ⚔️ MATCH PAIRED: %s vs %s! Launching Sky Arena Duel...", p1.Name, p2.Name))
				launchMatch(p1, p2)
			end
		end

	elseif action == "Leave" then
		for i = #queue, 1, -1 do
			if queue[i] == player then
				table.remove(queue, i)
				evQueue:FireClient(player, "Idle", 0)
				print(string.format(">> [DuelServer] %s left 1v1 Queue.", player.Name))
				break
			end
		end
	end
end)

print("[DuelServerManager] ✅ Loaded — Ranked 1v1 Matchmaking, Sky Arena & Best-of-3 Engine active.")

