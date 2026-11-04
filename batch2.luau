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
-- StormCharacterMorphServer.luau
-- SERVER MODULE: 3D Anime Character Visual Morph & Cosmetic Engine
-- Transforms standard R15 characters into unmistakable anime fighters:
--   • Naruto Uzumaki: Spiky Yellow Hair + Leaf Shinobi Headband + Orange Jumpsuit + Cheek Whiskers
--   • Sasuke Uchiha: Spiky Dark Hair & Bangs + High Collar + Purple Shimenawa Rope + Sharingan Eyes
--   • Monkey D. Luffy: 3D Straw Hat (Mugiwara) + Red Open Vest + Chest X-Scar + Blue Denim Shorts
--   • Roronoa Zoro: Green Crop Hair + Arm Bandana + Emerald Haramaki + Santoryu (3 Hip Katanas)
--   • Killua Zoldyck: Silver-White Wild Hair + Navy Turtle-Neck & White V-Neck + Electric Godspeed Aura

local StormCharacterMorphServer = {}

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Helper: Create a welded accessory part
local function addMorphPart(parent: Model, part0: BasePart, offset: CFrame, size: Vector3, color: Color3, material: Enum.Material, partType: Enum.PartType?): Part
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

-- =========================================================
-- 1. NARUTO UZUMAKI VISUAL MORPH
-- =========================================================
local function morphNaruto(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftLeg = (char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")) :: BasePart?
	local rightLeg = (char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) :: BasePart?
	if not head or not upperTorso then return end

	local hairColor = Color3.fromRGB(255, 215, 0) -- Blonde/Yellow
	local headbandBlue = Color3.fromRGB(22, 42, 92)
	local plateSilver = Color3.fromRGB(215, 220, 230)
	local jumpsuitOrange = Color3.fromRGB(245, 115, 15)

	-- 1. Spiky Anime Hair Cluster
	-- Center Top Spike
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, -0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.6, 0.85, 0.7), hairColor)
	-- Left & Right Upper Spikes
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(-25), math.rad(25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.75, 0) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-25)), Vector3.new(0.5, 0.75, 0.6), hairColor)
	-- Back Spikes
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.5) * CFrame.Angles(math.rad(-30), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairColor)
	-- Sideburns
	addMorphPart(morphModel, head, CFrame.new(-0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor, Enum.Material.SmoothPlastic)
	addMorphPart(morphModel, head, CFrame.new(0.62, 0.1, -0.2), Vector3.new(0.18, 0.5, 0.4), hairColor, Enum.Material.SmoothPlastic)

	-- 2. Konoha Forehead Protector Headband
	addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.56), Vector3.new(1.25, 0.38, 0.12), headbandBlue, Enum.Material.Fabric)
	-- Metal Plate
	local plate = addMorphPart(morphModel, head, CFrame.new(0, 0.28, -0.63), Vector3.new(0.72, 0.28, 0.05), plateSilver, Enum.Material.Metal)
	-- Engraved Spiral Emblem
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

	-- 3. Orange Track Jacket with Blue Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.85, 0.35, 1.15), headbandBlue, Enum.Material.SmoothPlastic) -- Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 1.4, 1.05), jumpsuitOrange, Enum.Material.SmoothPlastic)

	-- 4. Thigh Bandage & Ninja Pouch
	if rightLeg then
		addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.3, 0), Vector3.new(1.05, 0.5, 1.05), Color3.fromRGB(240, 240, 245), Enum.Material.Fabric) -- White bandage
		addMorphPart(morphModel, rightLeg, CFrame.new(0.55, 0.3, 0), Vector3.new(0.2, 0.35, 0.35), Color3.fromRGB(40, 30, 25), Enum.Material.Leather) -- Holster pouch
	end
end

-- =========================================================
-- 2. SASUKE UCHIHA VISUAL MORPH
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

	-- 1. Winged Spiky Dark Hair & Long Front Bangs
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0.1) * CFrame.Angles(math.rad(-20), math.rad(180), 0), Vector3.new(0.9, 0.85, 0.8), hairDark)
	-- Winged Side Spikes
	addMorphWedge(morphModel, head, CFrame.new(-0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(-150), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	addMorphWedge(morphModel, head, CFrame.new(0.55, 0.65, 0.2) * CFrame.Angles(math.rad(-15), math.rad(150), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairDark)
	-- Front Bangs framing cheeks
	addMorphPart(morphModel, head, CFrame.new(-0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(-10)), Vector3.new(0.2, 0.75, 0.15), hairDark, Enum.Material.SmoothPlastic)
	addMorphPart(morphModel, head, CFrame.new(0.5, -0.15, -0.55) * CFrame.Angles(0, 0, math.rad(10)), Vector3.new(0.2, 0.75, 0.15), hairDark, Enum.Material.SmoothPlastic)

	-- 2. High Stand-Up Collar
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.75, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.18, 0.65, 0.9), tunicWhite, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0.45) * CFrame.Angles(math.rad(12), 0, 0), Vector3.new(1.5, 0.65, 0.15), tunicWhite, Enum.Material.Fabric)

	-- 3. Purple Shimenawa Knotted Rope Belt & Blue Apron Sash
	if lowerTorso then
		-- Blue Apron Sash
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, -0.3, 0), Vector3.new(2.1, 0.85, 1.15), sashBlue, Enum.Material.Fabric)
		-- Thick Purple Rope Ring
		local rope = addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0), Vector3.new(2.25, 0.35, 1.25), ropePurple, Enum.Material.Fabric)
		-- Rope Bow Knot at back
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.1, 0.7), Vector3.new(0.8, 0.5, 0.4), ropePurple, Enum.Material.Fabric)
	end

	-- 4. Sharingan Eye Aura Particles
	local eyeAura = Instance.new("ParticleEmitter")
	eyeAura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	eyeAura.Color = ColorSequence.new(Color3.fromRGB(255, 30, 30), Color3.fromRGB(180, 0, 0))
	eyeAura.Size = NumberSequence.new(0.25, 0)
	eyeAura.Rate = 12
	eyeAura.Speed = NumberRange.new(0.5, 1.5)
	eyeAura.Lifetime = NumberRange.new(0.4, 0.7)
	eyeAura.Parent = head
	eyeAura.Name = "SharinganAura"
end

-- =========================================================
-- 3. MONKEY D. LUFFY VISUAL MORPH
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
	local denimBlue = Color3.fromRGB(45, 90, 175)
	local furWhite = Color3.fromRGB(250, 250, 255)
	local skinTone = Color3.fromRGB(255, 220, 185)

	-- 1. Authentic 3D Straw Hat (Mugiwara)
	-- Wide Brim (Cylinder)
	local brim = addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.08, 3.2, 3.2), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)
	-- Red Ribbon Band
	local ribbon = addMorphPart(morphModel, head, CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.18, 1.85, 1.85), ribbonRed, Enum.Material.Fabric, Enum.PartType.Cylinder)
	-- Dome Crown
	local dome = addMorphPart(morphModel, head, CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 1.8, 1.8), strawYellow, Enum.Material.Wood, Enum.PartType.Cylinder)

	-- 2. Messy Black Anime Hair beneath hat
	addMorphWedge(morphModel, head, CFrame.new(-0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(-20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))
	addMorphWedge(morphModel, head, CFrame.new(0.4, 0.45, -0.4) * CFrame.Angles(math.rad(25), math.rad(20), 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(15, 15, 18))

	-- 3. Open Red Sleeveless Vest
	-- Left & Right Vest panels (leaving center chest exposed)
	addMorphPart(morphModel, upperTorso, CFrame.new(-0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0.7, 0, 0), Vector3.new(0.7, 1.45, 1.1), vestRed, Enum.Material.Fabric)
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0, 0.52), Vector3.new(1.8, 1.45, 0.15), vestRed, Enum.Material.Fabric) -- Back of vest

	-- 4. Iconic Chest X-Scar
	local scar1 = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30), Enum.Material.SmoothPlastic)
	local scar2 = addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.15, -0.53) * CFrame.Angles(0, 0, math.rad(-40)), Vector3.new(0.12, 0.95, 0.05), Color3.fromRGB(60, 30, 30), Enum.Material.SmoothPlastic)

	-- 5. Denim Shorts with White Fur Cuffs & Yellow Sash
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0.25, 0), Vector3.new(2.15, 0.3, 1.2), Color3.fromRGB(245, 205, 30), Enum.Material.Fabric) -- Yellow Sash
	end
	if leftLeg then
		addMorphPart(morphModel, leftLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric)
	end
	if rightLeg then
		addMorphPart(morphModel, rightLeg, CFrame.new(0, 0.4, 0), Vector3.new(1.1, 0.25, 1.1), furWhite, Enum.Material.Fabric)
	end
end

-- =========================================================
-- 4. RORONOA ZORO VISUAL MORPH
-- =========================================================
local function morphZoro(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local marimoGreen = Color3.fromRGB(45, 175, 75)
	local haramakiGreen = Color3.fromRGB(25, 95, 45)
	local coatGreen = Color3.fromRGB(18, 60, 32)
	local bandanaBlack = Color3.fromRGB(20, 22, 26)

	-- 1. Emerald Green Crop Hair (Marimo)
	addMorphPart(morphModel, head, CFrame.new(0, 0.65, 0), Vector3.new(1.35, 0.45, 1.35), marimoGreen, Enum.Material.Grass)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.8, -0.15) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(0.8, 0.4, 0.8), marimoGreen)

	-- 2. Black Pirate Bandana tied around Left Bicep
	if leftArm then
		addMorphPart(morphModel, leftArm, CFrame.new(0, 0.2, 0), Vector3.new(1.15, 0.4, 1.15), bandanaBlack, Enum.Material.Fabric)
		-- Knot tail
		addMorphPart(morphModel, leftArm, CFrame.new(-0.6, 0.1, 0), Vector3.new(0.2, 0.5, 0.3), bandanaBlack, Enum.Material.Fabric)
	end

	-- 3. Emerald Green Haramaki (Belly Warmer)
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0, 0), Vector3.new(2.1, 0.95, 1.15), haramakiGreen, Enum.Material.Fabric)
	end

	-- 4. Santoryu (3 Katana Sheaths on Right Hip)
	-- Sword 1: Wado Ichimonji (White)
	local s1 = addMorphPart(morphModel, upperTorso, CFrame.new(1.1, -0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-135)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(245, 245, 250), Enum.Material.SmoothPlastic)
	-- Sword 2: Sandai Kitetsu (Red)
	local s2 = addMorphPart(morphModel, upperTorso, CFrame.new(1.15, -0.5, 0.4) * CFrame.Angles(0, 0, math.rad(-140)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(190, 30, 30), Enum.Material.SmoothPlastic)
	-- Sword 3: Shusui (Black & Gold)
	local s3 = addMorphPart(morphModel, upperTorso, CFrame.new(1.2, -0.4, 0.6) * CFrame.Angles(0, 0, math.rad(-145)), Vector3.new(0.18, 3.6, 0.28), Color3.fromRGB(24, 24, 28), Enum.Material.SmoothPlastic)

	-- 5. Left Eye Scar Line
	addMorphPart(morphModel, head, CFrame.new(-0.25, 0.08, -0.56) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.04, 0.35, 0.02), Color3.fromRGB(80, 40, 40), Enum.Material.SmoothPlastic)
end

-- =========================================================
-- 5. KILLUA ZOLDYCK VISUAL MORPH
-- =========================================================
local function morphKillua(char: Model, morphModel: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	local upperTorso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local lowerTorso = (char:FindFirstChild("LowerTorso") or upperTorso) :: BasePart?
	local leftHand = (char:FindFirstChild("LeftHand") or char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")) :: BasePart?
	local rightHand = (char:FindFirstChild("RightHand") or char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not head or not upperTorso then return end

	local hairSilver = Color3.fromRGB(245, 245, 255)
	local turtleNavy = Color3.fromRGB(25, 30, 50)
	local shirtWhite = Color3.fromRGB(240, 242, 248)
	local shortsViolet = Color3.fromRGB(40, 35, 65)

	-- 1. Silver-White Wild Spiky Assassin Hair
	addMorphWedge(morphModel, head, CFrame.new(0, 0.85, 0) * CFrame.Angles(math.rad(10), 0, 0), Vector3.new(0.85, 0.9, 0.8), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(-0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(-30), math.rad(30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.45, 0.75, 0.1) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(-30)), Vector3.new(0.6, 0.8, 0.6), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0, 0.65, 0.55) * CFrame.Angles(math.rad(-25), math.rad(180), 0), Vector3.new(0.8, 0.75, 0.6), hairSilver)
	-- Fluffy front bangs
	addMorphWedge(morphModel, head, CFrame.new(-0.25, 0.45, -0.55) * CFrame.Angles(math.rad(35), 0, math.rad(-15)), Vector3.new(0.35, 0.5, 0.25), hairSilver)
	addMorphWedge(morphModel, head, CFrame.new(0.25, 0.45, -0.55) * CFrame.Angles(math.rad(35), 0, math.rad(15)), Vector3.new(0.35, 0.5, 0.25), hairSilver)

	-- 2. Navy Blue Turtle-Neck Undershirt with White V-Neck Skater Shirt
	addMorphPart(morphModel, upperTorso, CFrame.new(0, 0.75, 0), Vector3.new(1.65, 0.4, 1.05), turtleNavy, Enum.Material.Fabric) -- High turtle-neck
	addMorphPart(morphModel, upperTorso, CFrame.new(0, -0.05, 0), Vector3.new(2.1, 1.35, 1.1), shirtWhite, Enum.Material.Fabric) -- Baggy white shirt

	-- 3. Indigo Assassin Shorts
	if lowerTorso then
		addMorphPart(morphModel, lowerTorso, CFrame.new(0, 0, 0), Vector3.new(2.05, 0.9, 1.05), shortsViolet, Enum.Material.Fabric)
	end

	-- 4. Godspeed Electric Lightning Sparks (Active aura on fists)
	local function addLightning(hand: BasePart)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 240)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		sparks.Size = NumberSequence.new(0.3, 0)
		sparks.Rate = 18
		sparks.Speed = NumberRange.new(1, 3)
		sparks.Lifetime = NumberRange.new(0.2, 0.45)
		sparks.Name = "GodspeedSparks"
		sparks.Parent = hand
	end
	if leftHand then addLightning(leftHand) end
	if rightHand then addLightning(rightHand) end
end

-- =========================================================
-- MASTER MORPH DISPATCHER
-- =========================================================
function StormCharacterMorphServer.applyMorph(char: Model, charId: string)
	if not char then return end

	-- 1. Remove previous morph
	local oldMorph = char:FindFirstChild("AnimeMorph")
	if oldMorph then oldMorph:Destroy() end

	-- Remove any old particle effects attached to limbs
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("ParticleEmitter") and (desc.Name == "SharinganAura" or desc.Name == "GodspeedSparks") then
			desc:Destroy()
		end
	end

	-- 2. Hide default Roblox accessories (hats/hair) so they don't clash with anime hair
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle") :: BasePart?
			if handle then
				handle.Transparency = 1
			end
		end
	end

	-- 3. Create fresh Morph Container Model
	local morphModel = Instance.new("Model")
	morphModel.Name = "AnimeMorph"

	-- 4. Apply Character-Specific Anime Sculpt & Clothing
	if charId == "Naruto" then
		morphNaruto(char, morphModel)
	elseif charId == "Sasuke" then
		morphSasuke(char, morphModel)
	elseif charId == "Luffy" then
		morphLuffy(char, morphModel)
	elseif charId == "Zoro" then
		morphZoro(char, morphModel)
	elseif charId == "Killua" then
		morphKillua(char, morphModel)
	end

	morphModel.Parent = char
	print(string.format(">> [AnimeMorph] Successfully morphed %s into 3D %s! <<", char.Name, charId))
end

return StormCharacterMorphServer
]=====]
    install('StormCharacterMorphServer', 'ModuleScript', game:GetService('ServerScriptService'), src)
end

do
    local src = [=====[--!strict
-- LobbyManagerServer.luau
-- SERVER SCRIPT: Anime Staging Lobby & Character Roster Management
-- Features:
--   • Procedural Shinobi Staging Lobby (separate from Combat Arena)
--   • SpawnLocation situated in the Lobby courtyard
--   • Interactive Gateways (Teleport to 1v1 Arena & Return to Lobby)
--   • Character Select Pedestal & Terminal
--   • Authoritative Character Roster & Attribute Replication

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig")) :: any
local StormCharacterMorphServer = require(ServerScriptService:WaitForChild("StormCharacterMorphServer")) :: any

-- Positions
local LOBBY_CENTER = Vector3.new(0, 50, -160)
local ARENA_SPAWN  = Vector3.new(0, 52.5, 0)
local LOBBY_SPAWN  = Vector3.new(0, 52.5, -160)

-- Remotes
local combatEvents = ReplicatedStorage:WaitForChild("CombatEvents", 10) :: Folder
local function ensureRemote(name: string): RemoteEvent
	local ev = combatEvents:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = combatEvents
	end
	return ev
end

local evCharSelect   = ensureRemote("CharacterSelectEvent")
local evOpenRoster   = ensureRemote("OpenRosterEvent")
local evTeleportGate = ensureRemote("TeleportGateEvent")

-- Forward declaration
local applyCharacter: (player: Player, charId: string) -> ()

-- =========================================================
-- CREATE 3D ANIME DISPLAY MANNEQUIN
-- =========================================================
local function createAnimeMannequin(parent: Instance, pos: Vector3, charId: string)
	local charData = CombatConfig.Characters[charId]
	if not charData then return end

	-- Pedestal
	local ped = Instance.new("Part")
	ped.Name = "Pedestal_" .. charId
	ped.Shape = Enum.PartType.Cylinder
	ped.Size = Vector3.new(0.8, 5, 5)
	ped.CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ped.Color = charData.PrimaryColor
	ped.Material = Enum.Material.Neon
	ped.Transparency = 0.35
	ped.Anchored = true
	ped.CanCollide = true
	ped.Parent = parent

	-- Mannequin Model
	local man = Instance.new("Model")
	man.Name = "Mannequin_" .. charId

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(pos + Vector3.new(0, 3.2, 0)) * CFrame.Angles(0, math.rad(180), 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = man
	man.PrimaryPart = root

	local upperTorso = Instance.new("Part")
	upperTorso.Name = "UpperTorso"
	upperTorso.Size = Vector3.new(1.8, 1.4, 1.0)
	upperTorso.CFrame = root.CFrame * CFrame.new(0, 0.4, 0)
	upperTorso.Color = Color3.fromRGB(240, 210, 180)
	upperTorso.Anchored = true
	upperTorso.CanCollide = false
	upperTorso.Parent = man

	local lowerTorso = Instance.new("Part")
	lowerTorso.Name = "LowerTorso"
	lowerTorso.Size = Vector3.new(1.7, 0.8, 0.9)
	lowerTorso.CFrame = root.CFrame * CFrame.new(0, -0.6, 0)
	lowerTorso.Color = Color3.fromRGB(30, 35, 45)
	lowerTorso.Anchored = true
	lowerTorso.CanCollide = false
	lowerTorso.Parent = man

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(240, 210, 180)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = man

	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftUpperArm"
	leftArm.Size = Vector3.new(0.8, 1.4, 0.8)
	leftArm.CFrame = root.CFrame * CFrame.new(-1.3, 0.3, 0)
	leftArm.Color = Color3.fromRGB(240, 210, 180)
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.Parent = man

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightUpperArm"
	rightArm.Size = Vector3.new(0.8, 1.4, 0.8)
	rightArm.CFrame = root.CFrame * CFrame.new(1.3, 0.3, 0)
	rightArm.Color = Color3.fromRGB(240, 210, 180)
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.Parent = man

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLowerLeg"
	leftLeg.Size = Vector3.new(0.8, 1.5, 0.8)
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.5, -1.5, 0)
	leftLeg.Color = Color3.fromRGB(35, 40, 50)
	leftLeg.Anchored = true
	leftLeg.CanCollide = false
	leftLeg.Parent = man

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLowerLeg"
	rightLeg.Size = Vector3.new(0.8, 1.5, 0.8)
	rightLeg.CFrame = root.CFrame * CFrame.new(0.5, -1.5, 0)
	rightLeg.Color = Color3.fromRGB(35, 40, 50)
	rightLeg.Anchored = true
	rightLeg.CanCollide = false
	rightLeg.Parent = man

	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = man

	-- Morph into authentic 3D Anime Fighter
	pcall(function()
		StormCharacterMorphServer.applyMorph(man, charId)
	end)

	-- Overhead Billboard
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 180, 0, 50)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 0.5)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = string.format("%s %s", charData.Icon, charData.Name)
	nameLbl.TextColor3 = charData.PrimaryColor
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.TextScaled = true
	nameLbl.Parent = bb

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.fromScale(1, 0.45)
	subLbl.Position = UDim2.new(0, 0, 0.5, 0)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = string.format("%s • %s", charData.Title, charData.Archetype)
	subLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
	subLbl.Font = Enum.Font.GothamBold
	subLbl.TextScaled = true
	subLbl.Parent = bb

	-- Instant Select Proximity Prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pilih " .. charData.Name
	prompt.ObjectText = "⚡ ROSTER"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = root

	prompt.Triggered:Connect(function(player)
		if applyCharacter then
			applyCharacter(player, charId)
		end
	end)

	man.Parent = parent
end

-- =========================================================
-- BUILD PROCEDURAL SHINOBI LOBBY
-- =========================================================
local function buildLobby()
	-- Remove any old default SpawnLocations outside Lobby
	for _, desc in ipairs(Workspace:GetChildren()) do
		if desc:IsA("SpawnLocation") and desc.Name ~= "LobbySpawnLocation" then
			desc:Destroy()
		end
	end

	local existing = Workspace:FindFirstChild("StormClashLobby")
	if existing then existing:Destroy() end

	local lobbyModel = Instance.new("Model")
	lobbyModel.Name = "StormClashLobby"

	-- 1. Main Floor Platform (Diameter 70)
	local floor = Instance.new("Part")
	floor.Name = "LobbyFloor"
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(4, 70, 70)
	floor.CFrame = CFrame.new(LOBBY_CENTER) * CFrame.Angles(0, 0, math.rad(90))
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(32, 35, 46)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Parent = lobbyModel

	-- Inner Ring
	local ring = Instance.new("Part")
	ring.Name = "InnerRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(4.1, 40, 40)
	ring.CFrame = CFrame.new(LOBBY_CENTER) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.WoodPlanks
	ring.Color = Color3.fromRGB(75, 45, 30)
	ring.Anchored = true
	ring.CanCollide = true
	ring.Parent = lobbyModel

	-- 2. SpawnLocation in Lobby
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawnLocation"
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.Position = LOBBY_SPAWN + Vector3.new(0, -1.8, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(0, 200, 255)
	spawn.Transparency = 0.6
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = lobbyModel

	-- 3. Japanese Torii Gate at Arena Entrance
	local gatePos = LOBBY_CENTER + Vector3.new(0, 0, 30)

	local function createPillar(offset: Vector3)
		local p = Instance.new("Part")
		p.Size = Vector3.new(1.8, 16, 1.8)
		p.Position = gatePos + offset
		p.Color = Color3.fromRGB(180, 25, 25)
		p.Material = Enum.Material.Wood
		p.Anchored = true
		p.CanCollide = true
		p.Parent = lobbyModel
	end
	createPillar(Vector3.new(-7, 8, 0))
	createPillar(Vector3.new(7, 8, 0))

	-- Torii Header
	local header = Instance.new("Part")
	header.Size = Vector3.new(18, 1.6, 2.4)
	header.Position = gatePos + Vector3.new(0, 16, 0)
	header.Color = Color3.fromRGB(24, 24, 28)
	header.Material = Enum.Material.Wood
	header.Anchored = true
	header.CanCollide = true
	header.Parent = lobbyModel

	-- 4. Gateway Portal to Combat Arena
	local portal = Instance.new("Part")
	portal.Name = "ArenaPortalGate"
	portal.Size = Vector3.new(12, 14, 0.5)
	portal.Position = gatePos + Vector3.new(0, 7, 0)
	portal.Material = Enum.Material.ForceField
	portal.Color = Color3.fromRGB(0, 240, 255)
	portal.Transparency = 0.5
	portal.Anchored = true
	portal.CanCollide = false
	portal.Parent = lobbyModel

	local portalPe = Instance.new("ParticleEmitter")
	portalPe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	portalPe.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 255, 255))
	portalPe.Size = NumberSequence.new(1.5, 0)
	portalPe.Rate = 35
	portalPe.Speed = NumberRange.new(4, 8)
	portalPe.Parent = portal

	-- Portal Prompt
	local portalPrompt = Instance.new("ProximityPrompt")
	portalPrompt.ActionText = "Masuk ke Arena Pertarungan"
	portalPrompt.ObjectText = "⚔️ COMBAT ARENA"
	portalPrompt.HoldDuration = 0
	portalPrompt.MaxActivationDistance = 14
	portalPrompt.Parent = portal

	portalPrompt.Triggered:Connect(function(player)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(ARENA_SPAWN)
				print(string.format(">> [Lobby] %s entered the Combat Arena! <<", player.Name))
			end
		end
	end)

	-- 5. Character Select Pedestal (Center of Lobby)
	local pedPos = LOBBY_CENTER + Vector3.new(0, 0, -10)
	local pedestal = Instance.new("Part")
	pedestal.Name = "RosterPedestal"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Size = Vector3.new(2.4, 6, 6)
	pedestal.CFrame = CFrame.new(pedPos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pedestal.Color = Color3.fromRGB(255, 215, 0)
	pedestal.Material = Enum.Material.Neon
	pedestal.Anchored = true
	pedestal.CanCollide = true
	pedestal.Parent = lobbyModel

	local pedPrompt = Instance.new("ProximityPrompt")
	pedPrompt.ActionText = "Pilih Karakter Anime"
	pedPrompt.ObjectText = "👥 ROSTER FIGHTER"
	pedPrompt.HoldDuration = 0
	pedPrompt.MaxActivationDistance = 12
	pedPrompt.Parent = pedestal

	pedPrompt.Triggered:Connect(function(player)
		evOpenRoster:FireClient(player)
	end)

	-- 6. Arena Return Portal (Back from Arena to Lobby)
	local arenaReturn = Instance.new("Part")
	arenaReturn.Name = "ArenaReturnPad"
	arenaReturn.Size = Vector3.new(6, 0.4, 6)
	arenaReturn.Position = Vector3.new(0, 50.3, 56)
	arenaReturn.Color = Color3.fromRGB(255, 140, 0)
	arenaReturn.Material = Enum.Material.Neon
	arenaReturn.Transparency = 0.4
	arenaReturn.Anchored = true
	arenaReturn.CanCollide = true
	arenaReturn.Parent = Workspace

	local retPrompt = Instance.new("ProximityPrompt")
	retPrompt.ActionText = "Kembali ke Lobi"
	retPrompt.ObjectText = "🏯 LOBI UTAMA"
	retPrompt.HoldDuration = 0
	retPrompt.MaxActivationDistance = 10
	retPrompt.Parent = arenaReturn

	retPrompt.Triggered:Connect(function(player)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(LOBBY_SPAWN)
				print(string.format(">> [Lobby] %s returned to the Lobby! <<", player.Name))
			end
		end
	end)

	-- 7. 5 3D Anime Character Mannequins standing in the Shinobi Lobby Courtyard
	local rosterList = {
		{ Id = "Naruto", Pos = LOBBY_CENTER + Vector3.new(0, 0, -22) },
		{ Id = "Sasuke", Pos = LOBBY_CENTER + Vector3.new(-12, 0, -18) },
		{ Id = "Luffy",  Pos = LOBBY_CENTER + Vector3.new(12, 0, -18) },
		{ Id = "Zoro",   Pos = LOBBY_CENTER + Vector3.new(-22, 0, -10) },
		{ Id = "Killua", Pos = LOBBY_CENTER + Vector3.new(22, 0, -10) },
	}

	for _, entry in ipairs(rosterList) do
		createAnimeMannequin(lobbyModel, entry.Pos, entry.Id)
	end

	lobbyModel.Parent = Workspace
	print(">> [LobbyManager] Shinobi Lobby Courtyard, Anime Mannequins & Gateways built successfully! <<")
end

-- =========================================================
-- CHARACTER SELECTION & APPLICATION
-- =========================================================
applyCharacter = function(player: Player, charId: string)
	local charData = CombatConfig.Characters[charId]
	if not charData then return end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- 1. Set Attributes
	player:SetAttribute("SelectedCharacter", charId)
	player:SetAttribute("CharacterName", charData.Name)
	player:SetAttribute("CharacterTitle", charData.Title)
	player:SetAttribute("CharacterIcon", charData.Icon)
	player:SetAttribute("CharacterArchetype", charData.Archetype)

	-- 2. Apply Speeds & Health
	hum.WalkSpeed = charData.WalkSpeed
	player:SetAttribute("NinjaDashSpeed", charData.NinjaDashSpeed)
	player:SetAttribute("MaxGuardHealth", charData.GuardHealth)

	-- 3. Update Katana / Blade Visuals with Character Palette
	local katana = char:FindFirstChild("StormKatana")
	if katana then
		local edge = katana:FindFirstChild("NeonEdge") :: BasePart?
		if edge then
			edge.Color = charData.PrimaryColor
		end

		local blade = katana:FindFirstChild("Blade") :: BasePart?
		if blade then
			local trail = blade:FindFirstChild("SlashTrail") :: Trail?
			if trail then
				trail.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, charData.PrimaryColor),
					ColorSequenceKeypoint.new(0.6, charData.AccentColor),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				})
			end
		end
	end

	-- 4. Apply 3D Anime Character Visual Morph (Naruto / Sasuke / Luffy / Zoro / Killua)
	pcall(function()
		StormCharacterMorphServer.applyMorph(char, charId)
	end)

	-- 5. Replicate to all clients
	evCharSelect:FireAllClients(player, charId, charData)
	print(string.format(">> [Roster] %s chose & morphed into: %s [%s]! <<", player.Name, charData.Name, charData.Archetype))
end

evCharSelect.OnServerEvent:Connect(function(player: Player, charId: string)
	applyCharacter(player, charId)
end)

-- Default setup for new players
local function onCharacter(player: Player, char: Model)
	task.wait(0.2)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = CFrame.new(LOBBY_SPAWN)
	end
	local current = player:GetAttribute("SelectedCharacter") or "Naruto"
	applyCharacter(player, tostring(current))
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		onCharacter(p, p.Character)
	end
end

-- Build lobby on server start
buildLobby()

print("[LobbyManagerServer] ✅ Lobby & Character Roster Server active.")
]=====]
    install('LobbyManagerServer', 'Script', game:GetService('ServerScriptService'), src)
end

return 'Batch 2 OK (2 scripts)'