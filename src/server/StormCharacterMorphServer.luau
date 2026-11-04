--!strict
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
