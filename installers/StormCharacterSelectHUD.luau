local ex = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):FindFirstChild('StormCharacterSelectHUD')
if ex then ex:Destroy() end
local s = Instance.new('LocalScript')
s.Name = 'StormCharacterSelectHUD'
s.Source = [=====[--!strict
-- StormCharacterSelectHUD.luau
-- CLIENT SCRIPT: Jump Force & Naruto Storm 4 Character Selection Modal & Roster HUD
-- Features:
--   • 5-Fighter Roster Grid: Naruto, Sasuke, Luffy, Zoro, Killua
--   • Dynamic Archetype Badges (Rushdown, Zoner, Grappler, Sword, Trickster)
--   • Detailed Character Dossier: 4 Stat Bars (Speed, Power, Defense, Jutsu)
--   • Technique Arsenal Showcase (M1, Low Sweep, Ninja Assist, Secret Technique)
--   • Interactive Selection with Sound Effects and Visual Glow
--   • Toggleable via [B] Key, Lobby Pedestal, or Top-Left HUD Button

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local evCharSelect = combatEvents:WaitForChild("CharacterSelectEvent", 10) :: RemoteEvent
local evOpenRoster = combatEvents:WaitForChild("OpenRosterEvent", 10) :: RemoteEvent

-- State
local isOpen = false
local currentSelectedId = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
local previewSelectedId = currentSelectedId

-- Sounds helper
local function playUiSound(soundName: string, pitch: number)
	task.spawn(function()
		pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/" .. soundName
			sound.Volume = 0.5
			sound.PlaybackSpeed = pitch or 1.0
			sound.Parent = SoundService
			sound:Play()
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end)
	end)
end

-- =========================================================
-- SCREEN GUI CREATION
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StormCharacterSelectHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = PlayerGui

-- Dark Vignette Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "ModalBackdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Position = UDim2.new(0, 0, 0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = screenGui

-- Main Modal Window
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainModal"
mainFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = backdrop
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(0, 240, 255)
modalStroke.Thickness = 2
modalStroke.Parent = mainFrame

-- Header Bar
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderBar"
headerFrame.Size = UDim2.new(1, 0, 0, 56)
headerFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
headerFrame.BackgroundTransparency = 0.2
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame
Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 24, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "⚡ SHINOBI ROSTER // CHOOSE YOUR FIGHTER"
titleLabel.Parent = headerFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(240, 40, 40)
closeBtn.BackgroundTransparency = 0.2
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- CONTENT SPLIT: LEFT GRID & RIGHT PREVIEW
-- =========================================================
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -40, 1, -80)
contentFrame.Position = UDim2.new(0, 20, 0, 68)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- LEFT PANEL: ROSTER CARDS (Width: 42%)
local rosterList = Instance.new("ScrollingFrame")
rosterList.Name = "RosterList"
rosterList.Size = UDim2.new(0.42, 0, 1, 0)
rosterList.Position = UDim2.new(0, 0, 0, 0)
rosterList.BackgroundTransparency = 1
rosterList.ScrollBarThickness = 6
rosterList.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
rosterList.CanvasSize = UDim2.new(0, 0, 0, 5 * 84)
rosterList.Parent = contentFrame

local rosterLayout = Instance.new("UIListLayout")
rosterLayout.SortOrder = Enum.SortOrder.LayoutOrder
rosterLayout.Padding = UDim.new(0, 10)
rosterLayout.Parent = rosterList

-- RIGHT PANEL: DETAILED DOSSIER (Width: 56%)
local previewPanel = Instance.new("Frame")
previewPanel.Name = "PreviewPanel"
previewPanel.Size = UDim2.new(0.56, 0, 1, 0)
previewPanel.Position = UDim2.new(0.44, 0, 0, 0)
previewPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
previewPanel.BackgroundTransparency = 0.4
previewPanel.Parent = contentFrame
Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 10)

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(40, 50, 70)
previewStroke.Thickness = 1.5
previewStroke.Parent = previewPanel

-- Scroll container for preview details
local previewScroll = Instance.new("ScrollingFrame")
previewScroll.Name = "PreviewScroll"
previewScroll.Size = UDim2.new(1, 0, 1, -54)
previewScroll.Position = UDim2.new(0, 0, 0, 0)
previewScroll.BackgroundTransparency = 1
previewScroll.ScrollBarThickness = 4
previewScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
previewScroll.CanvasSize = UDim2.new(0, 0, 0, 360)
previewScroll.Parent = previewPanel

-- Top Info: Large Icon + Name + Title
local pIcon = Instance.new("TextLabel")
pIcon.Name = "PreviewIcon"
pIcon.Size = UDim2.new(0, 68, 0, 68)
pIcon.Position = UDim2.new(0, 16, 0, 16)
pIcon.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
pIcon.Font = Enum.Font.GothamBold
pIcon.TextSize = 36
pIcon.Text = "🦊"
pIcon.Parent = previewScroll
Instance.new("UICorner", pIcon).CornerRadius = UDim.new(0, 10)
local pIconStroke = Instance.new("UIStroke")
pIconStroke.Color = Color3.fromRGB(255, 130, 20)
pIconStroke.Thickness = 2.5
pIconStroke.Parent = pIcon

local pName = Instance.new("TextLabel")
pName.Name = "PreviewName"
pName.Size = UDim2.new(1, -100, 0, 26)
pName.Position = UDim2.new(0, 96, 0, 16)
pName.BackgroundTransparency = 1
pName.Font = Enum.Font.GothamBlack
pName.TextSize = 20
pName.TextColor3 = Color3.fromRGB(255, 255, 255)
pName.TextXAlignment = Enum.TextXAlignment.Left
pName.Text = "NARUTO UZUMAKI"
pName.Parent = previewScroll

local pTitle = Instance.new("TextLabel")
pTitle.Name = "PreviewTitle"
pTitle.Size = UDim2.new(1, -100, 0, 18)
pTitle.Position = UDim2.new(0, 96, 0, 44)
pTitle.BackgroundTransparency = 1
pTitle.Font = Enum.Font.GothamMedium
pTitle.TextSize = 12
pTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
pTitle.TextXAlignment = Enum.TextXAlignment.Left
pTitle.Text = "Hero of the Hidden Leaf • RUSHDOWN"
pTitle.Parent = previewScroll

local pQuote = Instance.new("TextLabel")
pQuote.Name = "PreviewQuote"
pQuote.Size = UDim2.new(1, -32, 0, 32)
pQuote.Position = UDim2.new(0, 16, 0, 92)
pQuote.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
pQuote.BackgroundTransparency = 0.5
pQuote.Font = Enum.Font.GothamMedium
pQuote.TextSize = 12
pQuote.RichText = true
pQuote.TextColor3 = Color3.fromRGB(220, 220, 230)
pQuote.TextWrapped = true
pQuote.Text = '"I never go back on my word! That\'s my ninja way!"'
pQuote.Parent = previewScroll
Instance.new("UICorner", pQuote).CornerRadius = UDim.new(0, 6)

-- STATS SECTION (4 Horizontal Bars)
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, -32, 0, 110)
statsContainer.Position = UDim2.new(0, 16, 0, 132)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = previewScroll

local statFills: { [string]: Frame } = {}
local statLabels: { [string]: TextLabel } = {}

local statDefs = {
	{ key = "Speed",   label = "SPEED",   y = 0,   color = Color3.fromRGB(0, 255, 200) },
	{ key = "Power",   label = "POWER",   y = 28,  color = Color3.fromRGB(255, 80, 80) },
	{ key = "Defense", label = "DEFENSE", y = 56,  color = Color3.fromRGB(255, 215, 0) },
	{ key = "Jutsu",   label = "JUTSU",   y = 84,  color = Color3.fromRGB(180, 100, 255) },
}

for _, def in ipairs(statDefs) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.Position = UDim2.new(0, 0, 0, def.y)
	row.BackgroundTransparency = 1
	row.Parent = statsContainer

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 75, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(180, 190, 210)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = def.label
	lbl.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -120, 0, 10)
	barBg.Position = UDim2.new(0, 80, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
	barBg.Parent = row
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = def.color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)
	statFills[def.key] = barFill

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(0, 35, 1, 0)
	valLbl.Position = UDim2.new(1, -35, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = Enum.Font.GothamBlack
	valLbl.TextSize = 12
	valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Text = "85"
	valLbl.Parent = row
	statLabels[def.key] = valLbl
end

-- SKILLS ARSENAL BOX
local skillsBox = Instance.new("Frame")
skillsBox.Name = "SkillsBox"
skillsBox.Size = UDim2.new(1, -32, 0, 84)
skillsBox.Position = UDim2.new(0, 16, 0, 248)
skillsBox.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
skillsBox.BackgroundTransparency = 0.4
skillsBox.Parent = previewScroll
Instance.new("UICorner", skillsBox).CornerRadius = UDim.new(0, 8)

local sListLayout = Instance.new("UIListLayout")
sListLayout.Padding = UDim.new(0, 3)
sListLayout.Parent = skillsBox

local function createSkillRow(prefix: string, name: string): TextLabel
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -12, 0, 18)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.GothamMedium
	row.TextSize = 11
	row.TextColor3 = Color3.fromRGB(200, 210, 230)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = "  " .. prefix .. ": " .. name
	row.Parent = skillsBox
	return row
end

local m1SkillLbl   = createSkillRow("🥊 Combo M1", "Shinobi Taijutsu Barrage")
local sweepSkillLbl = createSkillRow("⚡ Sweep", "Uzumaki Low Sweep")
local assistSkillLbl = createSkillRow("👥 Assist", "Shadow Clone Rasengan")
local ultSkillLbl  = createSkillRow("💥 Ultimate", "Wind Style: Rasenshuriken")

-- BOTTOM ACTION BUTTON (Docked at base of PreviewPanel)
local selectBtn = Instance.new("TextButton")
selectBtn.Name = "SelectFighterButton"
selectBtn.Size = UDim2.new(1, -32, 0, 42)
selectBtn.Position = UDim2.new(0, 16, 1, -48)
selectBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
selectBtn.Font = Enum.Font.GothamBlack
selectBtn.TextSize = 14
selectBtn.TextColor3 = Color3.fromRGB(12, 18, 24)
selectBtn.Text = "⚔️ PILIH KARAKTER SHINOBI (SELECT)"
selectBtn.Parent = previewPanel
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 8)

local selStroke = Instance.new("UIStroke")
selStroke.Color = Color3.fromRGB(255, 255, 255)
selStroke.Thickness = 1.5
selStroke.Parent = selectBtn

-- =========================================================
-- ROSTER CARD CREATION & SELECTION LOGIC
-- =========================================================
local cardStrokes: { [string]: UIStroke } = {}
local cardFrames: { [string]: TextButton } = {}

local function updatePreview(charId: string)
	local char = CombatConfig.Characters[charId]
	if not char then return end

	previewSelectedId = charId

	-- Update preview text & visuals
	pIcon.Text = char.Icon
	pIconStroke.Color = char.PrimaryColor
	pName.Text = string.upper(char.Name)
	pName.TextColor3 = char.PrimaryColor
	pTitle.Text = char.Title .. " • " .. string.upper(char.Archetype)
	pTitle.TextColor3 = char.AccentColor
	pQuote.Text = '"' .. char.Quote .. '"'

	-- Update Stats
	local stats = char.Stats or { Speed = 80, Power = 80, Defense = 80, Jutsu = 80 }
	for key, fill in pairs(statFills) do
		local val = stats[key] or 80
		local ratio = math.clamp(val / 100, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ratio, 0, 1, 0),
		}):Play()
		if statLabels[key] then
			statLabels[key].Text = tostring(val)
		end
	end

	-- Update Skill Names
	m1SkillLbl.Text    = "  🥊 Combo [J]: " .. char.M1Name
	sweepSkillLbl.Text = "  ⚡ Sweep [S+J]: " .. char.SweepName
	assistSkillLbl.Text = "  👥 Assist [U]: " .. char.AssistName
	ultSkillLbl.Text   = "  💥 Ultimate [I]: " .. char.UltimateName

	-- Update Button State
	if charId == currentSelectedId then
		selectBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
		selectBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		selectBtn.Text = "✓ KARAKTER TERPILIH (CURRENT)"
	else
		selectBtn.BackgroundColor3 = char.PrimaryColor
		selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectBtn.Text = "⚔️ PILIH " .. string.upper(char.Name) .. " (SELECT)"
	end

	-- Highlight active card
	for id, stroke in pairs(cardStrokes) do
		if id == charId then
			stroke.Color = Color3.fromRGB(255, 215, 0)
			stroke.Thickness = 3
		else
			stroke.Color = Color3.fromRGB(45, 55, 75)
			stroke.Thickness = 1.5
		end
	end
end

-- Build Card for each fighter
local charOrder = { "Naruto", "Sasuke", "Luffy", "Zoro", "Killua" }
for idx, charId in ipairs(charOrder) do
	local char = CombatConfig.Characters[charId]
	if not char then continue end

	local card = Instance.new("TextButton")
	card.Name = "Card_" .. charId
	card.Size = UDim2.new(1, -6, 0, 74)
	card.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
	card.BackgroundTransparency = 0.2
	card.Text = ""
	card.AutoButtonColor = false
	card.LayoutOrder = idx
	card.Parent = rosterList
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(45, 55, 75)
	cStroke.Thickness = 1.5
	cStroke.Parent = card
	cardStrokes[charId] = cStroke
	cardFrames[charId] = card

	-- Fighter Icon
	local cIcon = Instance.new("TextLabel")
	cIcon.Size = UDim2.new(0, 50, 0, 50)
	cIcon.Position = UDim2.new(0, 12, 0.5, 0)
	cIcon.AnchorPoint = Vector2.new(0, 0.5)
	cIcon.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	cIcon.Font = Enum.Font.GothamBold
	cIcon.TextSize = 26
	cIcon.Text = char.Icon
	cIcon.Parent = card
	Instance.new("UICorner", cIcon).CornerRadius = UDim.new(0, 8)

	-- Name
	local cName = Instance.new("TextLabel")
	cName.Size = UDim2.new(1, -74, 0, 20)
	cName.Position = UDim2.new(0, 70, 0, 14)
	cName.BackgroundTransparency = 1
	cName.Font = Enum.Font.GothamBlack
	cName.TextSize = 14
	cName.TextColor3 = Color3.fromRGB(255, 255, 255)
	cName.TextXAlignment = Enum.TextXAlignment.Left
	cName.Text = char.Name
	cName.Parent = card

	-- Archetype Tag
	local cTag = Instance.new("TextLabel")
	cTag.Size = UDim2.new(0, 90, 0, 18)
	cTag.Position = UDim2.new(0, 70, 0, 38)
	cTag.BackgroundColor3 = char.PrimaryColor
	cTag.BackgroundTransparency = 0.3
	cTag.Font = Enum.Font.GothamBold
	cTag.TextSize = 10
	cTag.TextColor3 = Color3.fromRGB(255, 255, 255)
	cTag.Text = string.upper(char.Archetype)
	cTag.Parent = card
	Instance.new("UICorner", cTag).CornerRadius = UDim.new(0, 4)

	-- Click handler
	card.MouseButton1Click:Connect(function()
		playUiSound("volume_slider.ogg", 1.2)
		updatePreview(charId)
	end)
end

-- =========================================================
-- CONFIRM SELECTION
-- =========================================================
local function selectCharacter(charId: string)
	local char = CombatConfig.Characters[charId]
	if not char then return end

	currentSelectedId = charId
	playUiSound("action_footsteps_plastic.mp3", 1.5)

	-- Fire to server
	evCharSelect:FireServer(charId)

	-- Visual feedback
	updatePreview(charId)

	-- Close modal smoothly after short delay
	task.delay(0.3, function()
		screenGui.Enabled = false
		isOpen = false
	end)
end

selectBtn.MouseButton1Click:Connect(function()
	selectCharacter(previewSelectedId)
end)

-- =========================================================
-- MODAL TOGGLE & CONTROLS
-- =========================================================
local function toggleRoster(state: boolean?)
	if state ~= nil then
		isOpen = state
	else
		isOpen = not isOpen
	end

	screenGui.Enabled = isOpen
	if isOpen then
		playUiSound("volume_slider.ogg", 1.0)
		local current = LocalPlayer:GetAttribute("SelectedCharacter") or "Naruto"
		currentSelectedId = tostring(current)
		updatePreview(currentSelectedId)

		-- Animated Entrance
		mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
		mainFrame.BackgroundTransparency = 1
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0.1,
		}):Play()
	end
end

closeBtn.MouseButton1Click:Connect(function()
	toggleRoster(false)
end)

-- Keybind [B] to toggle roster
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleRoster()
	end
end)

-- Listen to Lobby Pedestal remote trigger
evOpenRoster.OnClientEvent:Connect(function()
	toggleRoster(true)
end)

-- Listen to character changes replicated from server
evCharSelect.OnClientEvent:Connect(function(player: Player, charId: string, charData: any)
	if player == LocalPlayer then
		currentSelectedId = charId
		updatePreview(charId)
	end
end)

-- Expose to global/other scripts via bindable if needed
local bindable = Instance.new("BindableFunction")
bindable.Name = "ToggleRosterUI"
bindable.OnInvoke = function(state)
	toggleRoster(state)
	return isOpen
end
bindable.Parent = screenGui

print("[StormCharacterSelectHUD] ✅ Shinobi Roster UI loaded. Press [B] or visit Lobby Pedestal.")
]=====]
s.Parent = game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts')
return 'Installed LocalScript: StormCharacterSelectHUD'
