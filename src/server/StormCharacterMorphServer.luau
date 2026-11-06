--!strict
-- StormCharacterMorphServer.luau
-- SERVER MODULE: 3D Anime Character Visual Morph & Procedural Cosmetic Engine
-- Transforms standard R15 characters into unmistakable anime fighters across 24 iconic legends:
--   • Naruto Shippuden: Naruto Uzumaki, Sasuke Uchiha, Kakashi Hatake, Madara Uchiha
--   • One Piece: Monkey D. Luffy, Roronoa Zoro, Vinsmoke Sanji, Trafalgar D. Water Law
--   • Dragon Ball: Son Goku, Vegeta, Future Trunks
--   • Bleach: Ichigo Kurosaki, Sosuke Aizen, Byakuya Kuchiki
--   • Jujutsu Kaisen: Ryomen Sukuna, Satoru Gojo, Yuji Itadori, Megumi Fushiguro
--   • Hunter x Hunter: Killua Zoldyck, Gon Freecss
--   • Demon Slayer: Tanjiro Kamado, Zenitsu Agatsuma
--   • My Hero Academia: Izuku Midoriya (Deku), Katsuki Bakugo

local StormCharacterMorphServer = {}

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Helper: Create a welded accessory part
local function addMorphPart(parent: Model, part0: BasePart, offset: CFrame, size: Vector3, color: Color3, material: Enum.Material?, partType: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = "MorphPart"
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = partType or Enum.PartType.Block
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = false

	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = p
	w.Parent = p

	p.CFrame = part0.CFrame * offset
	p.Parent = parent
	return p
end

-- Helper: Create a wedge part
local function addMorphWedge(parent: Model, part0: BasePart, offset: CFrame, size: Vector3, color: Color3): WedgePart
	local wPart = Instance.new("WedgePart")
	wPart.Name = "MorphWedge"
	wPart.Size = size
	wPart.Color = color
	wPart.Material = Enum.Material.SmoothPlastic
	wPart.CanCollide = false
	wPart.Massless = true
	wPart.CastShadow = false

	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = wPart
	w.Parent = wPart

	wPart.CFrame = part0.CFrame * offset
	wPart.Parent = parent
	return wPart
end

-- Helper: Add particle aura to part
local function addAura(part: BasePart, texture: string, colors: {Color3}, sizeRange: {number}, rate: number, lifetime: number, name: string)
	local att = Instance.new("Attachment", part)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = texture or "rbxasset://textures/particles/sparkles_main.dds"
	if #colors >= 2 then
		pe.Color = ColorSequence.new(colors[1], colors[2])
	else
		pe.Color = ColorSequence.new(colors[1])
	end
	pe.Size = NumberSequence.new(sizeRange[1], sizeRange[2] or 0)
	pe.Rate = rate
	pe.Speed = NumberRange.new(1, 3)
	pe.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
	pe.Name = name
	pe.Parent = att
	return pe
end

-- =========================================================
-- 1. NARUTO UZUMAKI (Spiky Blonde Hair, Leaf Headband, Orange Tracksuit)
-- =========================================================
local function morphNaruto(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairColor = Color3.fromRGB(255, 215, 0)
	local headbandBlue = Color3.fromRGB(22, 42, 92)
	local plateSilver = Color3.fromRGB(215, 220, 230)
	local jumpsuitOrange = Color3.fromRGB(245, 115, 15)

	-- Spiky Anime Hair Cluster
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, -0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.6, 0.85, 0.7), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(-25), math.rad(25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.5) * CFrame.Angles(math.rad(-30), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairColor)
	addMorphPart(morphModel, head, CFrame.new(-0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor)
	addMorphPart(morphModel, head, CFrame.new(0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor)

	-- Konoha Forehead Protector Headband
	addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.56), Vector3.new(1.25, 0.38, 0.12), headbandBlue, Enum.Material.Fabric)
	local plate = addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.63), Vector3.new(0.72, 0.28, 0.05), plateSilver, Enum.Material.Metal)

	local emblem = Instance.new("SurfaceGui")
	emblem.Face = Enum.NormalId.Front
	local symLbl = Instance.new("TextLabel")
	symLbl.Size = UDim2.fromScale(1, 1)
	symLbl.BackgroundTransparency = 1
	symLbl.Font = Enum.Font.GothamBlack
	symLbl.TextSize = 14
	symLbl.TextColor3 = Color3.fromRGB(40, 45, 55)
	symLbl.Text = "🌀"
	symLbl.Parent = emblem
	emblem.Parent = plate

	-- Orange Track Jacket with Blue Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.35, 1.15), headbandBlue)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 1.4, 1.05), jumpsuitOrange)

	-- Bandage & Holster Pouch
	if rightLeg then
		addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.3, 0), Vector3.new(1.05, 0.5, 1.05), Color3.fromRGB(240, 240, 245), Enum.Material.Fabric)
		addMorphPart(morphModel, rightLeg, CFrame.new(0.55, 0.3, 0), Vector3.new(0.2, 0.35, 0.35), Color3.fromRGB(40, 30, 25), Enum.Material.Leather)
	end
end

-- =========================================================
-- 2. SASUKE UCHIHA (Winged Hair, Stand-Up Collar, Shimenawa Rope)
-- =========================================================
local function morphSasuke(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	if not head or not upperTorso then return end

	local hairDark = Color3.fromRGB(18, 22, 32)
	local tunicWhite = Color3.fromRGB(235, 238, 245)
	local ropePurple = Color3.fromRGB(145, 65, 215)
	local sashBlue = Color3.fromRGB(30, 45, 80)

	-- Spiky Dark Hair & Bangs
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0.1) * CFrame.Angles(math.rad(-20), math.rad(180), 0), Vector3.new(0.9, 0.85, 0.8), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(-150), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(150), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	addMorphPart(morphModel, head, CFrame.new(-0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(-10)), Vector3.new(0.2, 0.75, 0.15), hairDark)
	addMorphPart(morphModel, head, CFrame.new(0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(10)), Vector3.new(0.2, 0.75, 0.15), hairDark)

	-- High Stand-Up Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0.45) * CFrame.Angles(math.rad(12), 0, 0), Vector3.new(1.5, 0.65, 0.15), tunicWhite, Enum.Material.Fabric)

	-- Purple Shimenawa Rope & Blue Apron Sash
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, -0.3, 0), Vector3.new(2.1, 0.85, 1.15), sashBlue, Enum.Material.Fabric)
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0), Vector3.new(2.25, 0.35, 1.25), ropePurple, Enum.Material.Fabric)
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0.7), Vector3.new(0.8, 0.5, 0.4), ropePurple, Enum.Material.Fabric)
	end

	-- Sharingan Eye Aura
	addAura(head, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 30, 30), Color3.fromRGB(180, 0, 0)}, {0.25, 0}, 12, 0.6, "SharinganAura")
end

-- =========================================================
-- 3. KAKASHI HATAKE (Silver Hair, Mask, Flak Jacket)
-- =========================================================
local function morphKakashi(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSilver = Color3.fromRGB(230, 235, 240)
	local maskNavy = Color3.fromRGB(24, 28, 42)
	local flakGreen = Color3.fromRGB(48, 88, 56)
	local flakDark = Color3.fromRGB(30, 58, 36)

	-- Spiky Silver Hair sweeping to left
	addMorphWedge(morphModel, head, CFrame.new(-0.2, 0.85, 0) * CFrame.Angles(math.rad(15), math.rad(-15), math.rad(25)), Vector3.new(0.85, 0.95, 0.8), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.25, 0.75, 0.1) * CFrame.Angles(math.rad(20), math.rad(20), math.rad(20)), Vector3.new(0.65, 0.85, 0.65), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.5) * CFrame.Angles(math.rad(-25), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairSilver)

	-- Ninja Face Mask covering nose and mouth
	addMorphPart(morphModel, head, CFrame.new(0, -0.25, -0.45), Vector3.new(1.15, 0.55, 0.35), maskNavy, Enum.Material.Fabric)

	-- Headband Tilted over left eye (Sharingan protector)
	addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.55) * CFrame.Angles(0, 0, math.rad(-14)), Vector3.new(1.25, 0.42, 0.12), maskNavy, Enum.Material.Fabric)
	addMorphPart(morphModel, head, CFrame.new(-0.15, 0.28, -0.62) * CFrame.Angles(0, 0, math.rad(-14)), Vector3.new(0.65, 0.28, 0.05), Color3.fromRGB(215, 220, 230), Enum.Material.Metal)

	-- Jonin Green Flak Jacket with shoulder pads & chest pockets
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.05, 0), Vector3.new(2.15, 1.45, 1.15), flakGreen, Enum.Material.Fabric)
	-- Shoulder pads
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.1, 0.65, 0), Vector3.new(0.4, 0.35, 1.1), flakDark, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, 0.65, 0), Vector3.new(0.4, 0.35, 1.1), flakDark, Enum.Material.Fabric)
	-- Twin scroll pockets on chest
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.5, 0.1, -0.6), Vector3.new(0.45, 0.55, 0.15), flakDark, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.5, 0.1, -0.6), Vector3.new(0.45, 0.55, 0.15), flakDark, Enum.Material.Fabric)
end

-- =========================================================
-- 4. MADARA UCHIHA (Wild Mane, Red Samurai Armor, Susanoo Glow)
-- =========================================================
local function morphMadara(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local armorCrimson = Color3.fromRGB(175, 25, 35)
	local robeMaroon = Color3.fromRGB(60, 20, 30)

	-- Massive Wild Spiky Mane
	addMorphWedge(morphModel, head, CFrame.new(0, 0.9, 0.2) * CFrame.Angles(math.rad(-25), math.rad(180), 0), Vector3.new(1.2, 1.1, 1.0), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.6, 0.7, 0.3) * CFrame.Angles(math.rad(-20), math.rad(-150), math.rad(30)), Vector3.new(0.8, 1.0, 0.8), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.6, 0.7, 0.3) * CFrame.Angles(math.rad(-20), math.rad(150), math.rad(-30)), Vector3.new(0.8, 1.0, 0.8), hairBlack)
	-- Hair flowing down over back of torso
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, 0.65), Vector3.new(1.6, 1.5, 0.4), hairBlack)

	-- Sengoku Samurai Armor Chestplate & Pauldrons
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.1), Vector3.new(2.1, 1.4, 1.1), robeMaroon, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, -0.58), Vector3.new(1.8, 0.9, 0.18), armorCrimson, Enum.Material.Metal)
	-- Segmented Shoulder Pauldrons
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.25, 0.65, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.5, 0.8, 1.2), armorCrimson, Enum.Material.Metal)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.25, 0.65, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.5, 0.8, 1.2), armorCrimson, Enum.Material.Metal)

	-- Susanoo Azure Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 120, 255), Color3.fromRGB(20, 50, 200)}, {0.6, 0}, 15, 0.7, "SusanooAura")
end

-- =========================================================
-- 5. MONKEY D. LUFFY (Straw Hat, Vest, X-Scar, Fur Shorts)
-- =========================================================
local function morphLuffy(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftLeg = (char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local strawYellow = Color3.fromRGB(230, 190, 95)
	local ribbonRed = Color3.fromRGB(220, 25, 25)
	local vestRed = Color3.fromRGB(225, 30, 30)
	local furWhite = Color3.fromRGB(250, 250, 255)

	-- 3D Straw Hat (Mugiwara)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.08, 3.2, 3.2), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)
	addMorphPart(morphModel, head, CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.18, 1.85, 1.85), ribbonRed, Enum.Material.Fabric, Enum.PartType.Cylinder)
	addMorphPart(morphModel, head, CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 1.8, 1.8), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)

	-- Messy Black Hair beneath hat
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(-20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))

	-- Open Red Sleeveless Vest
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0.52), Vector3.new(1.8, 1.45, 0.15), vestRed, Enum.Material.Fabric)

	-- Chest X-Scar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30))
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30))

	-- Yellow Sash & Denim Fur Cuffs
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.25, 0), Vector3.new(2.15, 0.3, 1.2), Color3.fromRGB(245, 205, 30), Enum.Material.Fabric)
	end
	if leftLeg then addMorphPart(morphModel, leftLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric) end
	if rightLeg then addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric) end
end

-- =========================================================
-- 6. RORONOA ZORO (Green Marimo Hair, Haramaki, 3 Katanas)
-- =========================================================
local function morphZoro(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local marimoGreen = Color3.fromRGB(45, 175, 75)
	local haramakiGreen = Color3.fromRGB(25, 95, 45)
	local bandanaBlack = Color3.fromRGB(20, 22, 26)

	-- Emerald Green Crop Hair (Marimo)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.35, 0.45, 1.35), marimoGreen, Enum.Material.Grass)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, -0.15) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.8, 0.4, 0.8), marimoGreen)

	-- Black Bandana on Left Bicep
	if leftArm then
		addMorphPart(morphModel, leftArm, CFrame.new(0, 0.2, 0), Vector3.new(1.15, 0.4, 1.15), bandanaBlack, Enum.Material.Fabric)
	end

	-- Emerald Green Haramaki (Belly Warmer)
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 0.95, 1.15), haramakiGreen, Enum.Material.Fabric)
	end

	-- Santoryu (3 Katana Sheaths on Right Hip)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, -0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-135)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(245, 245, 250))
	addMorphPart(morphModel, upperTorso, CFrame.new(1.15, -0.5, 0.4) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(190, 30, 30))
	addMorphPart(morphModel, upperTorso, CFrame.new(1.2, -0.4, 0.6) * CFrame.Angles(0, 0, math.rad(-145)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(24, 24, 28))

	-- Left Eye Scar
	addMorphPart(morphModel, head, CFrame.new(-0.25, 0.08, -0.56) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.04, 0.35, 0.02), Color3.fromRGB(80, 40, 40))
end

-- =========================================================
-- 7. VINSMOKE SANJI (Golden Swoop Hair, Black Suit, Diable Flames)
-- =========================================================
local function morphSanji(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairGold = Color3.fromRGB(250, 215, 60)
	local suitBlack = Color3.fromRGB(25, 28, 35)

	-- Golden Swooping Side Bangs (covers right eye)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 0.35, -0.5) * CFrame.Angles(math.rad(35), math.rad(15), math.rad(-20)), Vector3.new(0.65, 0.85, 0.35), hairGold)
	addMorphWedge(morphModel, head, CFrame.new(-0.2, 0.75, 0) * CFrame.Angles(math.rad(15), math.rad(-15), 0), Vector3.new(0.85, 0.65, 0.8), hairGold)

	-- Black Formal Suit Jacket & Tie
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), suitBlack, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.35, -0.56), Vector3.new(0.15, 0.7, 0.05), Color3.fromRGB(15, 15, 20), Enum.Material.Fabric) -- Tie

	-- Diable Jambe Flame Aura on right leg
	if rightLeg then
		addAura(rightLeg, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 120, 20), Color3.fromRGB(255, 40, 10)}, {0.45, 0}, 16, 0.5, "DiableFlames")
	end
end

-- =========================================================
-- 8. TRAFALGAR LAW (Spotted Fur Hat, Black Coat, Kikoku Nodachi)
-- =========================================================
local function morphLaw(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hatWhite = Color3.fromRGB(245, 245, 250)
	local coatBlack = Color3.fromRGB(22, 24, 30)

	-- White Spotted Fur Bucket Cap
	addMorphPart(morphModel, head, CFrame.new(0, 0.75, 0), Vector3.new(1.4, 0.55, 1.4), hatWhite, Enum.Material.Fabric)
	-- Fur spots
	addMorphPart(morphModel, head, CFrame.new(-0.4, 0.75, -0.65), Vector3.new(0.2, 0.2, 0.1), coatBlack)
	addMorphPart(morphModel, head, CFrame.new(0.4, 0.75, -0.65), Vector3.new(0.2, 0.2, 0.1), coatBlack)

	-- Goatee Beard
	addMorphPart(morphModel, head, CFrame.new(0, -0.5, -0.5), Vector3.new(0.2, 0.18, 0.15), coatBlack)

	-- Black Long Coat with Yellow Jolly Roger
	local coat = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.5, 1.15), coatBlack, Enum.Material.Fabric)
	local sg = Instance.new("SurfaceGui", coat)
	sg.Face = Enum.NormalId.Back
	local lbl = Instance.new("TextLabel", sg)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "💛"
	lbl.TextSize = 24

	-- Massive Kikoku Nodachi with Fur Crossguard slung at hip
	local nodachi = addMorphPart(morphModel, upperTorso, CFrame.new(1.15, -0.5, 0.2) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.2, 4.2, 0.3), coatBlack)
	-- White fur tsuba guard
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.45, 0.3, 0.45), hatWhite, Enum.Material.Fabric)
end

-- =========================================================
-- 9. SON GOKU (Saiyan Star Hair, Orange Gi, Blue Wristbands)
-- =========================================================
local function morphGoku(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightArm = (char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local giOrange = Color3.fromRGB(250, 130, 20)
	local shirtBlue = Color3.fromRGB(30, 80, 190)

	-- Iconic Saiyan Star Spikes
	addMorphWedge(morphModel, head, CFrame.new(0, 0.95, 0) * CFrame.Angles(math.rad(10), 0, 0), Vector3.new(0.9, 1.1, 0.9), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.7, 0.7, -0.1) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.7, 1.0, 0.7), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.7, 0.7, -0.1) * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.7, 1.0, 0.7), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.85, 0.1, 0) * CFrame.Angles(0, 0, math.rad(75)), Vector3.new(0.65, 0.9, 0.65), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.85, 0.1, 0) * CFrame.Angles(0, 0, math.rad(-75)), Vector3.new(0.65, 0.9, 0.65), hairBlack)

	-- Orange Martial Arts Gi with Blue Undershirt
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.65, 0), Vector3.new(1.8, 0.4, 1.1), shirtBlue, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), giOrange, Enum.Material.Fabric)

	-- Blue Wristbands
	if leftArm then addMorphPart(morphModel, leftArm, CFrame.new(0, -0.4, 0), Vector3.new(1.1, 0.4, 1.1), shirtBlue, Enum.Material.Fabric) end
	if rightArm then addMorphPart(morphModel, rightArm, CFrame.new(0, -0.4, 0), Vector3.new(1.1, 0.4, 1.1), shirtBlue, Enum.Material.Fabric) end
end

-- =========================================================
-- 10. VEGETA (Upright Flame Hair, Saiyan Battle Armor)
-- =========================================================
local function morphVegeta(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local armorWhite = Color3.fromRGB(240, 242, 248)
	local armorGold = Color3.fromRGB(245, 200, 45)
	local suitNavy = Color3.fromRGB(25, 45, 110)

	-- Tall Upright Flame Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 1.1, 0) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(1.1, 1.5, 1.0), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(-0.35, 1.25, 0.1) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.7, 1.3, 0.7), hairBlack)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 1.25, 0.1) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.7, 1.3, 0.7), hairBlack)

	-- Saiyan Royal Battle Armor Vest
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 1.45, 1.05), suitNavy, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.55), Vector3.new(1.85, 1.1, 0.15), armorWhite, Enum.Material.Metal)
	-- Gold shoulder straps
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.7, 0.75, 0), Vector3.new(0.45, 0.25, 1.15), armorGold, Enum.Material.Metal)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0.75, 0), Vector3.new(0.45, 0.25, 1.15), armorGold, Enum.Material.Metal)
end

-- =========================================================
-- 11. FUTURE TRUNKS (Purple Curtains Hair, CC Jacket, Broadsword)
-- =========================================================
local function morphTrunks(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairLavender = Color3.fromRGB(175, 155, 215)
	local ccBlue = Color3.fromRGB(65, 80, 155)

	-- Parted Anime Curtain Hair
	addMorphPart(morphModel, head, CFrame.new(-0.35, 0.4, -0.45) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.45, 0.7, 0.25), hairLavender)
	addMorphPart(morphModel, head, CFrame.new(0.35, 0.4, -0.45) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.45, 0.7, 0.25), hairLavender)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.3, 0.5, 1.3), hairLavender)

	-- CC Capsule Corp Cropped Blue Jacket
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, 0), Vector3.new(2.15, 1.0, 1.15), ccBlue, Enum.Material.Fabric)

	-- Broadsword in Scabbard strapped across back
	local scabbard = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, 0.65) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.3, 3.8, 0.35), Color3.fromRGB(150, 45, 45), Enum.Material.Leather)
	-- Golden Sword Hilt
	addMorphPart(morphModel, upperTorso, CFrame.new(1.2, 1.3, 0.65) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.2, 1.2, 0.2), Color3.fromRGB(240, 215, 50), Enum.Material.Metal)
end

-- =========================================================
-- 12. ICHIGO KUROSAKI (Spiky Orange Hair, Shihakusho, Zangetsu)
-- =========================================================
local function morphIchigo(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairOrange = Color3.fromRGB(255, 115, 20)
	local shihakushoBlack = Color3.fromRGB(18, 18, 22)
	local trimWhite = Color3.fromRGB(245, 245, 250)

	-- Spiky Shinigami Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.9, 0.95, 0.85), hairOrange)
	addMorphWedge(morphModel, head, CFrame.new(-0.45, 0.7, 0.1) * CFrame.Angles(math.rad(15), math.rad(-25), math.rad(30)), Vector3.new(0.65, 0.8, 0.65), hairOrange)
	addMorphWedge(morphModel, head, CFrame.new(0.45, 0.7, 0.1) * CFrame.Angles(math.rad(15), math.rad(25), math.rad(-30)), Vector3.new(0.65, 0.8, 0.65), hairOrange)

	-- Shihakusho Kimono with White V-Neck Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), shihakushoBlack, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.45, -0.56), Vector3.new(0.8, 0.45, 0.05), trimWhite, Enum.Material.Fabric)

	-- Giant Cleaver Blade Zangetsu strapped across back with bandages
	local zangetsu = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.2, 0.68) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.2, 4.4, 0.85), Color3.fromRGB(20, 20, 25), Enum.Material.Metal)
	-- White cloth wrap on hilt
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.2, 1.3, 0.68) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.25, 1.2, 0.25), trimWhite, Enum.Material.Fabric)
end

-- =========================================================
-- 13. SOSUKE AIZEN (Dangling Front Curl, Arrancar Robe)
-- =========================================================
local function morphAizen(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBrown = Color3.fromRGB(55, 38, 28)
	local haoriWhite = Color3.fromRGB(245, 245, 250)

	-- Slicked-back brown hair
	addMorphPart(morphModel, head, CFrame.new(0, 0.6, 0.1), Vector3.new(1.35, 0.45, 1.35), hairBrown)
	-- Signature dangling front hair lock
	addMorphPart(morphModel, head, CFrame.new(0.1, 0.1, -0.6) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.12, 0.75, 0.1), hairBrown)

	-- Grand Master Haori Robe with High Dramatic Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.5, 1.15), haoriWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.8, 0.8, 0) * CFrame.Angles(0, 0, math.rad(20)), Vector3.new(0.15, 0.8, 0.9), haoriWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.8, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-20)), Vector3.new(0.15, 0.8, 0.9), haoriWhite, Enum.Material.Fabric)

	-- Violet Spiritual Pressure Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(130, 40, 210), Color3.fromRGB(70, 20, 110)}, {0.5, 0}, 14, 0.6, "AizenAura")
end

-- =========================================================
-- 14. BYAKUYA KUCHIKI (Kenseikan Clips, Ginpakuhahana Scarf, Cherry Blossom)
-- =========================================================
local function morphByakuya(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlack = Color3.fromRGB(15, 15, 20)
	local clipWhite = Color3.fromRGB(245, 245, 250)
	local scarfTurquoise = Color3.fromRGB(45, 185, 185)

	-- Long Straight Black Hair
	addMorphPart(morphModel, head, CFrame.new(0, 0.6, 0.1), Vector3.new(1.35, 0.45, 1.35), hairBlack)
	addMorphPart(morphModel, head, CFrame.new(0, 0.1, 0.6), Vector3.new(1.2, 0.9, 0.3), hairBlack)
	-- Noble Kenseikan White Hairclips
	addMorphPart(morphModel, head, CFrame.new(-0.4, 0.75, -0.2), Vector3.new(0.15, 0.25, 0.35), clipWhite)
	addMorphPart(morphModel, head, CFrame.new(0.4, 0.75, -0.2), Vector3.new(0.15, 0.25, 0.35), clipWhite)

	-- Ginpakuhahana Turquoise Scarf around Neck & White Captain Haori
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.9, 0.35, 1.2), scarfTurquoise, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.45, 1.15), clipWhite, Enum.Material.Fabric)

	-- Floating Cherry Blossom Petals Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 160, 195), Color3.fromRGB(255, 210, 225)}, {0.4, 0}, 16, 0.8, "PetalAura")
end

-- =========================================================
-- 15. RYOMEN SUKUNA (Pink Slick Spikes, Curse Markings, Monk Robe)
-- =========================================================
local function morphSukuna(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairPink = Color3.fromRGB(235, 120, 145)
	local robeWhite = Color3.fromRGB(240, 240, 245)
	local markBlack = Color3.fromRGB(15, 15, 20)

	-- Slicked-Back Pink Spiky Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, 0.1) * CFrame.Angles(math.rad(-15), math.rad(180), 0), Vector3.new(0.9, 0.8, 0.85), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(-0.35, 0.7, 0) * CFrame.Angles(math.rad(-10), math.rad(-160), math.rad(20)), Vector3.new(0.6, 0.75, 0.6), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 0.7, 0) * CFrame.Angles(math.rad(-10), math.rad(160), math.rad(-20)), Vector3.new(0.6, 0.75, 0.6), hairPink)

	-- Black Demonic Curse Markings on Forehead & Cheeks
	addMorphPart(morphModel, head, CFrame.new(0, 0.35, -0.56), Vector3.new(0.35, 0.12, 0.05), markBlack)
	addMorphPart(morphModel, head, CFrame.new(-0.4, 0, -0.54), Vector3.new(0.12, 0.35, 0.05), markBlack)
	addMorphPart(morphModel, head, CFrame.new(0.4, 0, -0.54), Vector3.new(0.12, 0.35, 0.05), markBlack)

	-- Monk Robe
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), robeWhite, Enum.Material.Fabric)

	-- Blood-Crimson Malevolent Curse Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(180, 20, 50), Color3.fromRGB(20, 20, 25)}, {0.5, 0}, 16, 0.6, "SukunaAura")
end

-- =========================================================
-- 16. SATORU GOJO (Snow White Hair, Black Blindfold, Navy Uniform)
-- =========================================================
local function morphGojo(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSnow = Color3.fromRGB(250, 252, 255)
	local blindfoldBlack = Color3.fromRGB(18, 20, 26)
	local navyTech = Color3.fromRGB(24, 28, 45)

	-- Pure Snow-White Spiky Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(12), 0, 0), Vector3.new(0.85, 0.9, 0.8), hairSnow)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-25), math.rad(25)), Vector3.new(0.6, 0.8, 0.6), hairSnow)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(25), math.rad(-25)), Vector3.new(0.6, 0.8, 0.6), hairSnow)

	-- Black Blindfold wrapped securely across eyes
	addMorphPart(morphModel, head, CFrame.new(0, 0.08, -0.55), Vector3.new(1.25, 0.45, 0.15), blindfoldBlack, Enum.Material.Fabric)

	-- High-Collar Navy Jujutsu Sorcerer Uniform
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.7, 0.4, 1.1), navyTech, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), navyTech, Enum.Material.Fabric)

	-- Limitless Infinity Cyan/Purple Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(0, 180, 255), Color3.fromRGB(200, 50, 255)}, {0.5, 0}, 15, 0.7, "LimitlessAura")
end

-- =========================================================
-- 17. YUJI ITADORI (Pink/Black Undercut, Red Hood Collar)
-- =========================================================
local function morphYuji(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftHand = (char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairPink = Color3.fromRGB(245, 120, 155)
	local underBlack = Color3.fromRGB(20, 20, 24)
	local hoodRed = Color3.fromRGB(220, 35, 35)
	local navyTech = Color3.fromRGB(26, 30, 48)

	-- Spiky Pink Top with Black Undercut
	addMorphPart(morphModel, head, CFrame.new(0, 0.4, 0), Vector3.new(1.3, 0.35, 1.3), underBlack)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, -0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.8, 0.75, 0.75), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(-0.35, 0.7, 0) * CFrame.Angles(math.rad(15), math.rad(-20), math.rad(20)), Vector3.new(0.55, 0.7, 0.55), hairPink)
	addMorphWedge(morphModel, head, CFrame.new(0.35, 0.7, 0) * CFrame.Angles(math.rad(15), math.rad(20), math.rad(-20)), Vector3.new(0.55, 0.7, 0.55), hairPink)

	-- Red Hoodie Cowl extending from navy Jujutsu Tech uniform
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.4, 1.2), hoodRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), navyTech, Enum.Material.Fabric)

	-- Divergent Fist Cursed Sparks on hands
	if leftHand then addAura(leftHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 140, 255), Color3.fromRGB(255, 20, 60)}, {0.35, 0}, 14, 0.4, "DivergentSparks") end
	if rightHand then addAura(rightHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 140, 255), Color3.fromRGB(255, 20, 60)}, {0.35, 0}, 14, 0.4, "DivergentSparks") end
end

-- =========================================================
-- 18. MEGUMI FUSHIGURO (Spiky Sea-Urchin Hair, Shadow Puddle)
-- =========================================================
local function morphMegumi(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	if not head or not upperTorso then return end

	local hairDark = Color3.fromRGB(20, 24, 35)
	local navyTech = Color3.fromRGB(25, 30, 48)

	-- Spiky Starfish / Sea-Urchin Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(20), 0, 0), Vector3.new(0.8, 0.9, 0.8), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.75, 0.1) * CFrame.Angles(0, 0, math.rad(40)), Vector3.new(0.6, 0.85, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.75, 0.1) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.6, 0.85, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(-0.65, 0.2, 0) * CFrame.Angles(0, 0, math.rad(65)), Vector3.new(0.5, 0.75, 0.5), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.65, 0.2, 0) * CFrame.Angles(0, 0, math.rad(-65)), Vector3.new(0.5, 0.75, 0.5), hairDark)

	-- Navy Sorcerer Uniform
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), navyTech, Enum.Material.Fabric)

	-- Shadow Shikigami Aura at feet
	if lowerTorso then
		addAura(lowerTorso, "rbxasset://textures/particles/smoke_main.dds", {Color3.fromRGB(15, 18, 28), Color3.fromRGB(30, 35, 60)}, {0.6, 0}, 14, 0.7, "ShadowAura")
	end
end

-- =========================================================
-- 19. KILLUA ZOLDYCK (Wild Silver Hair, Turtleneck, Godspeed Sparks)
-- =========================================================
local function morphKillua(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftHand = (char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSilver = Color3.fromRGB(245, 245, 255)
	local turtleNavy = Color3.fromRGB(25, 30, 50)
	local shirtWhite = Color3.fromRGB(240, 242, 248)

	-- Silver-White Wild Spiky Assassin Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(10), 0, 0), Vector3.new(0.85, 0.9, 0.8), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(-0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-30), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)

	-- Navy Turtleneck & White Skater V-Neck Shirt
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.65, 0.4, 1.05), turtleNavy, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, -0.05, 0), Vector3.new(2.1, 1.35, 1.1), shirtWhite, Enum.Material.Fabric)

	-- Godspeed Lightning Sparks on fists
	if leftHand then addAura(leftHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(0, 255, 240), Color3.fromRGB(180, 100, 255)}, {0.35, 0}, 16, 0.4, "GodspeedSparks") end
	if rightHand then addAura(rightHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(0, 255, 240), Color3.fromRGB(180, 100, 255)}, {0.35, 0}, 16, 0.4, "GodspeedSparks") end
end

-- =========================================================
-- 20. GON FREECSS (Tall Green Spike Column Hair, Adventure Vest)
-- =========================================================
local function morphGon(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairDarkGreen = Color3.fromRGB(18, 55, 28)
	local jacketGreen = Color3.fromRGB(48, 165, 68)
	local trimRed = Color3.fromRGB(225, 40, 30)

	-- Ultra-Tall Spiky Column Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 1.35, 0) * CFrame.Angles(math.rad(5), 0, 0), Vector3.new(1.1, 1.9, 1.0), hairDarkGreen)
	addMorphWedge(morphModel, head, CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(5), 0, 0), Vector3.new(0.85, 1.2, 0.8), hairDarkGreen)

	-- Green Adventure Jacket with Red Collar Piping
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.8, 0.35, 1.15), trimRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), jacketGreen, Enum.Material.Fabric)

	-- Jajanken Nen Concentration on Right Fist
	if rightHand then
		addAura(rightHand, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 110, 20)}, {0.5, 0}, 18, 0.5, "NenAura")
	end
end

-- =========================================================
-- 21. TANJIRO KAMADO (Burgundy Hair, Checker Haori, Hanafuda)
-- =========================================================
local function morphTanjiro(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBurgundy = Color3.fromRGB(75, 25, 35)
	local checkGreen = Color3.fromRGB(35, 145, 75)
	local checkBlack = Color3.fromRGB(20, 22, 28)

	-- Burgundy Messy Hair with Exposed Forehead
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, 0.1) * CFrame.Angles(math.rad(-15), math.rad(180), 0), Vector3.new(0.9, 0.85, 0.85), hairBurgundy)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.65, 0.1) * CFrame.Angles(math.rad(-10), math.rad(-150), math.rad(25)), Vector3.new(0.6, 0.75, 0.6), hairBurgundy)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.65, 0.1) * CFrame.Angles(math.rad(-10), math.rad(150), math.rad(-25)), Vector3.new(0.6, 0.75, 0.6), hairBurgundy)

	-- Forehead Burn Scar Mark
	addMorphPart(morphModel, head, CFrame.new(-0.28, 0.32, -0.56) * CFrame.Angles(0, 0, math.rad(-20)), Vector3.new(0.25, 0.3, 0.05), Color3.fromRGB(130, 35, 45))

	-- Hanging Hanafuda Earrings
	addMorphPart(morphModel, head, CFrame.new(-0.65, -0.2, 0), Vector3.new(0.08, 0.45, 0.25), Color3.fromRGB(245, 245, 250))
	addMorphPart(morphModel, head, CFrame.new(0.65, -0.2, 0), Vector3.new(0.08, 0.45, 0.25), Color3.fromRGB(245, 245, 250))

	-- Iconic Checkerboard Haori Coat
	local haori = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.45, 1.15), checkGreen, Enum.Material.Fabric)
	-- Checker block highlights
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.55, 0.3, -0.58), Vector3.new(0.5, 0.5, 0.05), checkBlack)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.55, -0.3, -0.58), Vector3.new(0.5, 0.5, 0.05), checkBlack)

	-- Nichirin Katana at hip
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, -0.5, 0.1) * CFrame.Angles(0, 0, math.rad(-135)), Vector3.new(0.18, 3.6, 0.25), checkBlack)
end

-- =========================================================
-- 22. ZENITSU AGATSUMA (Yellow/Orange Triangular Hair, Triangle Haori)
-- =========================================================
local function morphZenitsu(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftLeg = (char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairYellow = Color3.fromRGB(255, 225, 45)
	local tipOrange = Color3.fromRGB(245, 120, 20)

	-- Yellow Hair with Square/Triangular Tips
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.35, 0.45, 1.35), hairYellow)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.45, -0.45) * CFrame.Angles(math.rad(25), 0, 0), Vector3.new(0.4, 0.5, 0.3), tipOrange)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.45, -0.45) * CFrame.Angles(math.rad(25), 0, 0), Vector3.new(0.4, 0.5, 0.3), tipOrange)

	-- Yellow/Orange Triangle Pattern Haori
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.15, 1.45, 1.15), hairYellow, Enum.Material.Fabric)

	-- Crackling Thunder Sparks around feet
	if leftLeg then addAura(leftLeg, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 235, 60), Color3.fromRGB(255, 255, 255)}, {0.35, 0}, 16, 0.35, "ThunderSparks") end
	if rightLeg then addAura(rightLeg, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(255, 235, 60), Color3.fromRGB(255, 255, 255)}, {0.35, 0}, 16, 0.35, "ThunderSparks") end
end

-- =========================================================
-- 23. IZUKU MIDORIYA / DEKU (Fluffy Emerald Hair, Hero Cowl, Full Cowl)
-- =========================================================
local function morphDeku(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not upperTorso then return end

	local hairDarkGreen = Color3.fromRGB(25, 75, 45)
	local suitTeal = Color3.fromRGB(35, 145, 110)
	local cowlWhite = Color3.fromRGB(240, 240, 245)

	-- Fluffy Messy Green Spiky Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.85, 0.9, 0.85), hairDarkGreen)
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.7, 0.1) * CFrame.Angles(math.rad(20), math.rad(-25), math.rad(25)), Vector3.new(0.65, 0.75, 0.65), hairDarkGreen)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.7, 0.1) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-25)), Vector3.new(0.65, 0.75, 0.65), hairDarkGreen)

	-- Respirator Neck Cowl around collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.35, 1.2), cowlWhite, Enum.Material.Metal)

	-- Costume Gamma Hero Jumpsuit with Shoulder Pauldrons
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), suitTeal, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(-1.1, 0.6, 0), Vector3.new(0.35, 0.35, 1.1), Color3.fromRGB(15, 20, 25), Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(1.1, 0.6, 0), Vector3.new(0.35, 0.35, 1.1), Color3.fromRGB(15, 20, 25), Enum.Material.Fabric)

	-- One For All Full Cowl Emerald Lightning Aura
	addAura(upperTorso, "rbxasset://textures/particles/sparkles_main.dds", {Color3.fromRGB(60, 255, 210), Color3.fromRGB(20, 200, 150)}, {0.45, 0}, 16, 0.5, "FullCowlAura")
end

-- =========================================================
-- 24. KATSUKI BAKUGO (Explosive Ash Blonde Hair, Grenade Gauntlets)
-- =========================================================
local function morphBakugo(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightArm = (char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairBlonde = Color3.fromRGB(240, 215, 140)
	local gauntletGreen = Color3.fromRGB(45, 95, 55)
	local orangeStrap = Color3.fromRGB(255, 110, 20)

	-- Explosive Spiky Hair Cluster
	addMorphWedge(morphModel, head, CFrame.new(0, 0.95, 0) * CFrame.Angles(math.rad(20), 0, 0), Vector3.new(1.0, 1.1, 0.95), hairBlonde)
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-30), math.rad(35)), Vector3.new(0.7, 0.9, 0.7), hairBlonde)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(-35)), Vector3.new(0.7, 0.9, 0.7), hairBlonde)

	-- Black Eye Mask with Flared Blast Accents
	addMorphPart(morphModel, head, CFrame.new(0, 0.15, -0.55), Vector3.new(1.25, 0.35, 0.15), Color3.fromRGB(18, 20, 25))
	addMorphPart(morphModel, head, CFrame.new(-0.75, 0.25, -0.4) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.2, 0.6, 0.1), orangeStrap)
	addMorphPart(morphModel, head, CFrame.new(0.75, 0.25, -0.4) * CFrame.Angles(0, 0, math.rad(35)), Vector3.new(0.2, 0.6, 0.1), orangeStrap)

	-- Black Tank Top with Orange X-Strap
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 1.45, 1.1), Color3.fromRGB(22, 24, 30), Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.56) * CFrame.Angles(0, 0, math.rad(35)), Vector3.new(0.25, 1.6, 0.05), orangeStrap)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.1, -0.56) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.25, 1.6, 0.05), orangeStrap)

	-- Massive Grenade Gauntlets on Forearms
	if leftArm then
		addMorphPart(morphModel, leftArm, CFrame.new(0, -0.3, 0), Vector3.new(1.6, 1.1, 1.6), gauntletGreen, Enum.Material.Metal)
	end
	if rightArm then
		addMorphPart(morphModel, rightArm, CFrame.new(0, -0.3, 0), Vector3.new(1.6, 1.1, 1.6), gauntletGreen, Enum.Material.Metal)
	end
end

-- =========================================================
-- MASTER MORPH DISPATCHER (24 CHARACTERS)
-- =========================================================
local morphTable: { [string]: (char: Model, morphModel: Model) -> () } = {
	["Naruto"]   = morphNaruto,
	["Sasuke"]   = morphSasuke,
	["Kakashi"]  = morphKakashi,
	["Madara"]   = morphMadara,
	["Luffy"]    = morphLuffy,
	["Zoro"]     = morphZoro,
	["Sanji"]    = morphSanji,
	["Law"]      = morphLaw,
	["Goku"]     = morphGoku,
	["Vegeta"]   = morphVegeta,
	["Trunks"]   = morphTrunks,
	["Ichigo"]   = morphIchigo,
	["Aizen"]    = morphAizen,
	["Byakuya"]  = morphByakuya,
	["Sukuna"]   = morphSukuna,
	["Gojo"]     = morphGojo,
	["Yuji"]     = morphYuji,
	["Megumi"]   = morphMegumi,
	["Killua"]   = morphKillua,
	["Gon"]      = morphGon,
	["Tanjiro"]  = morphTanjiro,
	["Zenitsu"]  = morphZenitsu,
	["Deku"]     = morphDeku,
	["Bakugo"]   = morphBakugo,
}

function StormCharacterMorphServer.applyMorph(char: Model, charId: string)
	if not char then return end

	-- 1. Remove previous morph container
	local oldMorph = char:FindFirstChild("AnimeMorph")
	if oldMorph then oldMorph:Destroy() end

	-- 2. Remove any previously created character particle emitters
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("ParticleEmitter") and (
			desc.Name == "SharinganAura" or desc.Name == "GodspeedSparks" or desc.Name == "SusanooAura" or
			desc.Name == "DiableFlames" or desc.Name == "AizenAura" or desc.Name == "PetalAura" or
			desc.Name == "SukunaAura" or desc.Name == "LimitlessAura" or desc.Name == "DivergentSparks" or
			desc.Name == "ShadowAura" or desc.Name == "NenAura" or desc.Name == "ThunderSparks" or
			desc.Name == "FullCowlAura"
		) then
			desc:Destroy()
		end
	end

	-- 3. Hide default Roblox accessories (hats/hair) so they do not clash with anime hair
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle") :: BasePart?
			if handle then
				handle.Transparency = 1
			end
		end
	end

	-- 4. Create fresh Morph Container Model
	local morphModel = Instance.new("Model")
	morphModel.Name = "AnimeMorph"

	-- 5. Dispatch morph function
	local morphFunc = morphTable[charId]
	if morphFunc then
		morphFunc(char, morphModel)
	else
		-- Fallback to Naruto if unknown id
		morphNaruto(char, morphModel)
	end

	morphModel.Parent = char
	print(string.format(">> [AnimeMorph] Successfully morphed %s into 3D %s! <<", char.Name, charId))
end

return StormCharacterMorphServer
