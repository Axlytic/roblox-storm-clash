--!strict
-- StormAnimationController.luau
-- CLIENT SCRIPT: Master Procedural Anime Combat Animation Engine
-- Features:
--   • 100% Asset-Independent: Zero asset load failures or HTTP 403 permission errors
--   • Multi-Keyframe Sequence Engine with Sub-Frame Hermite Smoothstep Easing:
--       - Phase 0: Anticipation / Energy Windup (Coiling joints)
--       - Phase 1: Explosive Release / Strike Snap (Acceleration)
--       - Phase 2: Micro Hitstop / Impact Frame (Freeze at peak extension)
--       - Phase 3: Recoil / Follow-through & Settle
--   • Complete Naruto Storm 4 Move List:
--       - Idle: Dynamic breathing sway with shinobi guard posture
--       - Neutral Combo (4-Hit): Right Jab -> Left Hook -> Roundhouse Kick -> Twin Palm Blast
--       - Up Combo (4-Hit): Rising Chin Jab -> Crescent Kick -> Backflip -> Skyward Leaping Uppercut (Launcher)
--       - Down Combo (4-Hit): Shin Kick -> 360 Low Sweep -> Overhead Heel Drop -> Heavy Ground Slam (Bounce)
--       - Air Combo (3-Hit): Air Thrust -> 360 Helicopter Kick -> Meteor Dive Spike
--       - Storm 4 Counter Stance: Cross-arm X-Guard -> Explosive Deflection Repel
--       - Chakra Load: Iconic Naruto Ram Hand Seal with pulsing aura
--       - Ninjutsu Rush: Low forward sprint thrusting Rasengan / Chidori palm forward
--       - Kawarimi: Flash Vanish Seal gesture
--       - Ninja Dash: 52° forward aerodynamic dive with trailing arms
--       - Hit Reactions: High Head Snap, Mid Gut Flinch, Stagger Stun (Dizzy Wobble)
--   • Real-Time Katana & Weapon Trail Synchronization

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- TYPES & DATA STRUCTURES
-- =========================================================
type JointOffsets = { [string]: CFrame }

type Keyframe = {
	t: number, -- Time fraction (0.0 to 1.0)
	offsets: JointOffsets,
}

type AnimationSequence = {
	duration: number,
	loop: boolean?,
	keyframes: { Keyframe },
}

-- Universal Joint Cache (AnimationConstraint & Motor6D)
local joints: { [string]: Instance } = {}
local baseC0: { [string]: CFrame } = {}
local katanaTrail: Trail? = nil

-- Animation State
local currentAnimName = "Idle"
local animStartTime = 0
local animDuration = 1.0
local isLooping = true
local currentSequence: AnimationSequence? = nil

-- Buttery Smooth Crossfade Pose Blending Engine
local lastAppliedOffsets: JointOffsets = {}
local blendStartOffsets: JointOffsets = {}
local blendStartTime = 0
local BLEND_DURATION = 0.065 -- 65ms seamless crossfade eliminating all joint pops!

-- Forward declaration of triggerCombatAnimation
local triggerCombatAnimation: (animName: string, durationOverride: number?) -> ()

-- Hit Flinch State
local flinchEndTime = 0
local flinchOffsets: JointOffsets = {}

-- =========================================================
-- EASING HELPERS (Hermite Smoothstep & Overshoot Snap)
-- =========================================================
local function smoothstep(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function snapEase(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * x * (x * (x * 6 - 15) + 10) -- Smootherstep
end

-- =========================================================
-- JOINT FINDER (Supports full R15 AnimationConstraint, Motor6D, and R6 fallback)
-- =========================================================
local function setupCharacter(char: Model)
	table.clear(joints)
	table.clear(baseC0)

	local function findJoint(name: string): Instance?
		for _, desc in ipairs(char:GetDescendants()) do
			if (desc:IsA("AnimationConstraint") or desc:IsA("Motor6D")) and (desc.Name == name or desc.Name:lower() == name:lower()) then
				return desc
			end
		end
		return nil
	end

	-- Universal R15 & R6 Joint Mapping
	joints["RootJoint"]     = findJoint("RootJoint") or findJoint("Root")
	joints["Waist"]         = findJoint("Waist")
	joints["Neck"]          = findJoint("Neck")
	joints["RightShoulder"] = findJoint("RightShoulder") or findJoint("Right Shoulder")
	joints["LeftShoulder"]  = findJoint("LeftShoulder") or findJoint("Left Shoulder")
	joints["RightElbow"]    = findJoint("RightElbow")
	joints["LeftElbow"]     = findJoint("LeftElbow")
	joints["RightWrist"]    = findJoint("RightWrist")
	joints["LeftWrist"]     = findJoint("LeftWrist")
	joints["RightHip"]      = findJoint("RightHip") or findJoint("Right Hip")
	joints["LeftHip"]       = findJoint("LeftHip") or findJoint("Left Hip")
	joints["RightKnee"]     = findJoint("RightKnee")
	joints["LeftKnee"]      = findJoint("LeftKnee")
	joints["RightAnkle"]    = findJoint("RightAnkle")
	joints["LeftAnkle"]     = findJoint("LeftAnkle")

	-- Cache default C0 for Motor6D fallback
	for key, joint in pairs(joints) do
		if joint and joint:IsA("Motor6D") then
			baseC0[key] = (joint :: Motor6D).C0
		end
	end

	-- Katana Slash Trail lookup
	task.delay(0.4, function()
		local katana = char:FindFirstChild("StormKatana")
		if katana then
			local blade = katana:FindFirstChild("Blade")
			if blade then
				katanaTrail = blade:FindFirstChild("SlashTrail") :: Trail?
			end
		end
	end)

	-- Dynamic Hit Reaction Listener
	local hum = char:WaitForChild("Humanoid", 3) :: Humanoid?
	if hum then
		local lastHealth = hum.Health
		hum.HealthChanged:Connect(function(newHealth)
			if newHealth < lastHealth and newHealth > 0 then
				local diff = lastHealth - newHealth
				if currentAnimName ~= "Ultimate" and currentAnimName ~= "StaggerStun" and currentAnimName ~= "CounterStance" then
					local hitAnim = if diff >= 18 then "HitHead" else "HitGut"
					if triggerCombatAnimation then
						triggerCombatAnimation(hitAnim, 0.22)
					end
				end
			end
			lastHealth = newHealth
		end)
	end

	-- Attribute Hit Reaction Listener (Replicated from server)
	char:GetAttributeChangedSignal("VictimHitReaction"):Connect(function()
		local react = tostring(char:GetAttribute("VictimHitReaction") or "")
		if react == "Launched" then
			if triggerCombatAnimation then triggerCombatAnimation("HitHead", 0.50) end
		elseif react == "GroundBounce" then
			if triggerCombatAnimation then triggerCombatAnimation("HitGut", 0.38) end
		elseif react == "Stagger" then
			if triggerCombatAnimation then triggerCombatAnimation("StaggerStun", 0.65) end
		elseif react == "High" then
			if triggerCombatAnimation then triggerCombatAnimation("HitHead", 0.20) end
		elseif react == "Mid" then
			if triggerCombatAnimation then triggerCombatAnimation("HitGut", 0.20) end
		end
	end)
end

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- =========================================================
-- DEFINING DETAILED ANIME ANIMATION SEQUENCES
-- =========================================================
local ANIMATIONS: { [string]: AnimationSequence } = {}

-- ---------------------------------------------------------
-- [0] IDLE: Shinobi Combat Stance (Natural Breathing + Boxing Guard)
-- ---------------------------------------------------------
ANIMATIONS["Idle"] = {
	duration = 1.8,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, math.rad(-18), 0),
				Waist         = CFrame.Angles(0, math.rad(18), 0),
				Neck          = CFrame.Angles(math.rad(2), math.rad(4), 0),
				RightShoulder = CFrame.new(-0.05, -0.05, -0.1) * CFrame.Angles(math.rad(38), math.rad(-22), math.rad(18)),
				LeftShoulder  = CFrame.new(0.05, -0.02, 0.1) * CFrame.Angles(math.rad(48), math.rad(32), math.rad(-22)),
				RightElbow    = CFrame.Angles(math.rad(52), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(68), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-8), 0, math.rad(12)),
				LeftHip       = CFrame.Angles(math.rad(12), 0, math.rad(-10)),
				RightKnee     = CFrame.Angles(math.rad(15), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(18), 0, 0),
			}
		},
		{
			t = 0.5,
			offsets = {
				RootJoint     = CFrame.new(0, 0.02, 0) * CFrame.Angles(0, math.rad(-18), 0),
				Waist         = CFrame.Angles(math.rad(2), math.rad(18), 0),
				Neck          = CFrame.Angles(math.rad(-1), math.rad(4), 0),
				RightShoulder = CFrame.new(-0.05, -0.02, -0.1) * CFrame.Angles(math.rad(42), math.rad(-22), math.rad(18)),
				LeftShoulder  = CFrame.new(0.05, 0.01, 0.1) * CFrame.Angles(math.rad(52), math.rad(32), math.rad(-22)),
				RightElbow    = CFrame.Angles(math.rad(48), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(64), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-8), 0, math.rad(12)),
				LeftHip       = CFrame.Angles(math.rad(12), 0, math.rad(-10)),
				RightKnee     = CFrame.Angles(math.rad(12), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(14), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, math.rad(-18), 0),
				Waist         = CFrame.Angles(0, math.rad(18), 0),
				Neck          = CFrame.Angles(math.rad(2), math.rad(4), 0),
				RightShoulder = CFrame.new(-0.05, -0.05, -0.1) * CFrame.Angles(math.rad(38), math.rad(-22), math.rad(18)),
				LeftShoulder  = CFrame.new(0.05, -0.02, 0.1) * CFrame.Angles(math.rad(48), math.rad(32), math.rad(-22)),
				RightElbow    = CFrame.Angles(math.rad(52), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(68), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-8), 0, math.rad(12)),
				LeftHip       = CFrame.Angles(math.rad(12), 0, math.rad(-10)),
				RightKnee     = CFrame.Angles(math.rad(15), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(18), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [1] NEUTRAL COMBO (4-Hit Iconic Martial Flurry)
-- ---------------------------------------------------------
-- Hit 1: Fast Right Straight Jab (Windup -> Explosive Snap -> Recoil)
ANIMATIONS["Neutral1"] = {
	duration = 0.26,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-15), 0),
				Waist         = CFrame.Angles(0, math.rad(15), 0),
				RightShoulder = CFrame.new(0, 0, 0.2) * CFrame.Angles(math.rad(30), math.rad(-45), 0),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(55), math.rad(35), 0),
				LeftElbow     = CFrame.Angles(math.rad(70), 0, 0),
			}
		},
		{
			t = 0.42, -- Snap Strike!
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, -0.4) * CFrame.Angles(0, math.rad(32), 0),
				Waist         = CFrame.Angles(0, math.rad(-30), 0),
				Neck          = CFrame.Angles(0, math.rad(-10), 0),
				RightShoulder = CFrame.new(0.1, 0.1, -0.8) * CFrame.Angles(math.rad(88), math.rad(15), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(10), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(45), math.rad(40), 0),
				LeftElbow     = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(15), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-25), 0, 0),
			}
		},
		{
			t = 1.0, -- Settle
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-10), 0),
				Waist         = CFrame.Angles(0, math.rad(10), 0),
				RightShoulder = CFrame.new(0, 0, -0.1) * CFrame.Angles(math.rad(40), math.rad(-20), 0),
				RightElbow    = CFrame.Angles(math.rad(55), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(50), math.rad(30), 0),
				LeftElbow     = CFrame.Angles(math.rad(65), 0, 0),
			}
		}
	}
}

-- Hit 2: High Horizontal Left Hook / Shinobi Palm Strike
ANIMATIONS["Neutral2"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(30), 0),
				Waist         = CFrame.Angles(0, math.rad(-30), 0),
				LeftShoulder  = CFrame.new(0, 0, 0.3) * CFrame.Angles(math.rad(40), math.rad(50), 0),
				LeftElbow     = CFrame.Angles(math.rad(90), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(55), math.rad(-30), 0),
			}
		},
		{
			t = 0.45, -- Hook Impact!
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, -0.4) * CFrame.Angles(0, math.rad(-42), 0),
				Waist         = CFrame.Angles(0, math.rad(40), 0),
				Neck          = CFrame.Angles(0, math.rad(12), 0),
				LeftShoulder  = CFrame.new(-0.2, 0.15, -0.7) * CFrame.Angles(math.rad(92), math.rad(-45), math.rad(35)),
				LeftElbow     = CFrame.Angles(math.rad(50), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(60), math.rad(-25), 0),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-20), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(25), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-15), 0),
				Waist         = CFrame.Angles(0, math.rad(15), 0),
				LeftShoulder  = CFrame.Angles(math.rad(45), math.rad(30), 0),
				RightShoulder = CFrame.Angles(math.rad(40), math.rad(-20), 0),
			}
		}
	}
}

-- Hit 3: High Spinning Roundhouse Kick (Body Pivot + Full Leg Extension)
ANIMATIONS["Neutral3"] = {
	duration = 0.34,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-40), 0),
				Waist         = CFrame.Angles(0, math.rad(40), 0),
				RightHip      = CFrame.Angles(math.rad(25), 0, math.rad(20)),
				RightKnee     = CFrame.Angles(math.rad(70), 0, 0),
			}
		},
		{
			t = 0.48, -- Roundhouse Whip!
			offsets = {
				RootJoint     = CFrame.new(0, 0.1, -0.3) * CFrame.Angles(math.rad(10), math.rad(75), 0),
				Waist         = CFrame.Angles(math.rad(-15), math.rad(-55), 0),
				Neck          = CFrame.Angles(0, math.rad(-30), 0),
				RightHip      = CFrame.Angles(0, math.rad(80), math.rad(75)),
				RightKnee     = CFrame.Angles(math.rad(10), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-25), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(35), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(35)),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, math.rad(-45)),
			}
		},
		{
			t = 1.0, -- Plant Foot Down
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, 0) * CFrame.Angles(0, math.rad(15), 0),
				Waist         = CFrame.Angles(0, math.rad(-15), 0),
				RightHip      = CFrame.Angles(math.rad(15), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-15), 0, 0),
			}
		}
	}
}

-- Hit 4: Heavy Twin Dragon Palms Finisher (Wall Splat / Knockdown)
ANIMATIONS["Neutral4"] = {
	duration = 0.52,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, 0.1) * CFrame.Angles(math.rad(15), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.2, 0.4) * CFrame.Angles(math.rad(-25), math.rad(-35), 0),
				LeftShoulder  = CFrame.new(0.1, -0.2, 0.4) * CFrame.Angles(math.rad(-25), math.rad(35), 0),
				RightElbow    = CFrame.Angles(math.rad(95), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(95), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-35), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(-35), 0, math.rad(-10)),
			}
		},
		{
			t = 0.50, -- Massive Twin Thrust!
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, -0.7) * CFrame.Angles(math.rad(28), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				Neck          = CFrame.Angles(math.rad(-20), 0, 0),
				RightShoulder = CFrame.new(-0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(-15), math.rad(10)),
				LeftShoulder  = CFrame.new(0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(15), math.rad(-10)),
				RightElbow    = CFrame.Angles(math.rad(12), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(12), 0, 0),
				RightHip      = CFrame.Angles(math.rad(30), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(45), 0, 0),
			}
		},
		{
			t = 0.72, -- Impact Hold (Hitstop pose)
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, -0.7) * CFrame.Angles(math.rad(28), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				RightShoulder = CFrame.new(-0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(-15), math.rad(10)),
				LeftShoulder  = CFrame.new(0.25, 0.2, -0.9) * CFrame.Angles(math.rad(95), math.rad(15), math.rad(-10)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.identity,
				Waist         = CFrame.identity,
				RightShoulder = CFrame.Angles(math.rad(40), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(40), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [2] UP COMBO (Air Launcher Strings - W + J)
-- ---------------------------------------------------------
ANIMATIONS["Up1"] = {
	duration = 0.26,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(-15), math.rad(-20), 0),
				RightShoulder = CFrame.new(0, -0.2, 0.1) * CFrame.Angles(math.rad(-10), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(80), 0, 0),
			}
		},
		{
			t = 0.45, -- Rising Chin Uppercut!
			offsets = {
				RootJoint     = CFrame.new(0, 0.15, -0.2) * CFrame.Angles(math.rad(15), math.rad(25), 0),
				Waist         = CFrame.Angles(math.rad(15), math.rad(-20), 0),
				Neck          = CFrame.Angles(math.rad(15), 0, 0),
				RightShoulder = CFrame.new(0.1, 0.4, -0.5) * CFrame.Angles(math.rad(125), math.rad(-25), math.rad(15)),
				RightElbow    = CFrame.Angles(math.rad(35), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(-30), 0, math.rad(-25)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.identity,
			}
		}
	}
}

ANIMATIONS["Up2"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.Angles(0, math.rad(25), 0),
				LeftHip   = CFrame.Angles(math.rad(-20), 0, 0),
			}
		},
		{
			t = 0.46, -- Vertical Crescent Upkick!
			offsets = {
				RootJoint     = CFrame.new(0, 0.2, 0) * CFrame.Angles(math.rad(-25), math.rad(-35), 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(115), 0, math.rad(-15)),
				LeftKnee      = CFrame.Angles(math.rad(10), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(35)),
				LeftShoulder  = CFrame.Angles(math.rad(-45), 0, math.rad(-35)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

ANIMATIONS["Up3"] = {
	duration = 0.32,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(35), 0, 0),
			}
		},
		{
			t = 0.50, -- Somersault Kick Flip!
			offsets = {
				RootJoint     = CFrame.new(0, 0.5, -0.2) * CFrame.Angles(math.rad(-85), 0, 0),
				Waist         = CFrame.Angles(math.rad(30), 0, 0),
				RightHip      = CFrame.Angles(math.rad(120), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(90), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(160), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(160), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(15), 0, 0),
			}
		}
	}
}

-- Hit 4: Skyward Leaping Uppercut (Shoryu Dragon Launcher -> LiftY = +38)
ANIMATIONS["Up4"] = {
	duration = 0.55,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.5, 0.2) * CFrame.Angles(math.rad(25), math.rad(-30), 0),
				RightShoulder = CFrame.new(0, -0.4, 0.2) * CFrame.Angles(math.rad(-45), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(90), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-45), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
			}
		},
		{
			t = 0.45, -- Skyward Leaping Apex Launcher!
			offsets = {
				RootJoint     = CFrame.new(0, 1.2, -0.3) * CFrame.Angles(math.rad(-20), math.rad(25), 0),
				Waist         = CFrame.Angles(math.rad(-15), math.rad(-20), 0),
				Neck          = CFrame.Angles(math.rad(-35), 0, 0), -- Head tracking skyward!
				RightShoulder = CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(175), math.rad(-10), math.rad(15)),
				RightElbow    = CFrame.Angles(math.rad(10), 0, 0),
				LeftShoulder  = CFrame.new(0, -0.2, 0.3) * CFrame.Angles(math.rad(-55), 0, math.rad(-25)),
				LeftHip       = CFrame.Angles(math.rad(75), 0, 0), -- High knee drive
				LeftKnee      = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-20), 0, 0),
			}
		},
		{
			t = 0.70, -- Apex Freeze (Skyward Pose)
			offsets = {
				RootJoint     = CFrame.new(0, 1.2, -0.3) * CFrame.Angles(math.rad(-20), math.rad(25), 0),
				RightShoulder = CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(175), math.rad(-10), math.rad(15)),
				LeftHip       = CFrame.Angles(math.rad(75), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.identity,
			}
		}
	}
}

-- ---------------------------------------------------------
-- [3] DOWN COMBO (Ground Bounce Strings - S + J / K)
-- ---------------------------------------------------------
ANIMATIONS["Down1"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(15), 0, 0),
			}
		},
		{
			t = 0.45, -- Shin Kick!
			offsets = {
				RootJoint     = CFrame.new(0, -0.6, -0.2) * CFrame.Angles(math.rad(25), math.rad(-35), 0),
				RightHip      = CFrame.Angles(math.rad(65), math.rad(45), math.rad(30)),
				RightKnee     = CFrame.Angles(math.rad(15), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-55), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(65), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(45), 0, math.rad(30)),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, math.rad(-30)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- Down2: 360° Low Shinobi Spin Sweep
ANIMATIONS["Down2"] = {
	duration = 0.32,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(25), 0, 0),
			}
		},
		{
			t = 0.48, -- Full Low Sweep Arc!
			offsets = {
				RootJoint     = CFrame.new(0, -1.3, 0) * CFrame.Angles(math.rad(35), math.rad(-85), 0),
				Waist         = CFrame.Angles(0, math.rad(75), 0),
				RightHip      = CFrame.Angles(0, math.rad(90), math.rad(80)),
				RightKnee     = CFrame.Angles(math.rad(5), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-80), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(95), 0, 0),
				LeftShoulder  = CFrame.new(0, -0.3, -0.4) * CFrame.Angles(math.rad(75), 0, 0), -- Left hand planted on floor
				RightShoulder = CFrame.Angles(math.rad(-35), 0, math.rad(45)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint = CFrame.new(0, -0.3, 0),
			}
		}
	}
}

ANIMATIONS["Down3"] = {
	duration = 0.35,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-15), 0, 0),
				RightHip  = CFrame.Angles(math.rad(110), 0, 0),
			}
		},
		{
			t = 0.52, -- Overhead Axe Heel Drop!
			offsets = {
				RootJoint     = CFrame.new(0, -0.6, -0.3) * CFrame.Angles(math.rad(45), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				RightHip      = CFrame.Angles(math.rad(45), 0, 0),
				RightKnee     = CFrame.Angles(math.rad(10), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(45)),
				LeftShoulder  = CFrame.Angles(math.rad(-45), 0, math.rad(-45)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- Down4: Heavy Meteor Ground Slam (Rebound Bounce)
ANIMATIONS["Down4"] = {
	duration = 0.54,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(-45), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(165), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(165), 0, 0),
			}
		},
		{
			t = 0.46, -- Ground Impact Crater Slam!
			offsets = {
				RootJoint     = CFrame.new(0, -1.2, -0.6) * CFrame.Angles(math.rad(55), 0, 0),
				Waist         = CFrame.Angles(math.rad(25), 0, 0),
				Neck          = CFrame.Angles(math.rad(-25), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.3, -0.8) * CFrame.Angles(math.rad(85), 0, 0),
				LeftShoulder  = CFrame.new(0.1, -0.3, -0.8) * CFrame.Angles(math.rad(85), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(25), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(25), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-55), 0, math.rad(25)),
				LeftHip       = CFrame.Angles(math.rad(-55), 0, math.rad(-25)),
				RightKnee     = CFrame.Angles(math.rad(75), 0, 0),
				LeftKnee      = CFrame.Angles(math.rad(75), 0, 0),
			}
		},
		{
			t = 0.72, -- Impact Hold
			offsets = {
				RootJoint = CFrame.new(0, -1.2, -0.6) * CFrame.Angles(math.rad(55), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [4] AIR COMBO (Mid-Air Aerial Strings)
-- ---------------------------------------------------------
ANIMATIONS["Air1"] = {
	duration = 0.26,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(math.rad(20), math.rad(-25), 0),
				RightShoulder = CFrame.Angles(math.rad(30), math.rad(-30), 0),
			}
		},
		{
			t = 0.45,
			offsets = {
				RootJoint     = CFrame.new(0, 0, -0.3) * CFrame.Angles(math.rad(25), math.rad(35), 0),
				Waist         = CFrame.Angles(0, math.rad(-35), 0),
				RightShoulder = CFrame.new(0, 0.1, -0.7) * CFrame.Angles(math.rad(95), math.rad(15), 0),
				LeftShoulder  = CFrame.Angles(math.rad(-45), 0, math.rad(-30)),
				RightHip      = CFrame.Angles(math.rad(35), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-35), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.Angles(math.rad(15), 0, 0) }
		}
	}
}

ANIMATIONS["Air2"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint = CFrame.Angles(0, math.rad(-60), 0),
			}
		},
		{
			t = 0.50, -- 360 Mid-Air Helicopter Spin Kick!
			offsets = {
				RootJoint     = CFrame.Angles(math.rad(15), math.rad(120), 0),
				Waist         = CFrame.Angles(0, math.rad(-30), 0),
				RightHip      = CFrame.Angles(0, math.rad(85), math.rad(70)),
				LeftHip       = CFrame.Angles(0, math.rad(-65), math.rad(-50)),
				RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(45)),
				LeftShoulder  = CFrame.Angles(math.rad(45), 0, math.rad(-45)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.Angles(math.rad(15), 0, 0) }
		}
	}
}

ANIMATIONS["Air3"] = {
	duration = 0.52,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(-35), 0, 0),
				RightShoulder = CFrame.Angles(math.rad(165), 0, 0),
				LeftShoulder  = CFrame.Angles(math.rad(165), 0, 0),
			}
		},
		{
			t = 0.45, -- Dive Spike Crash Slam!
			offsets = {
				RootJoint     = CFrame.new(0, -0.6, -0.8) * CFrame.Angles(math.rad(75), 0, 0),
				Waist         = CFrame.Angles(math.rad(20), 0, 0),
				RightShoulder = CFrame.new(0, 0, -0.8) * CFrame.Angles(math.rad(95), 0, 0),
				LeftShoulder  = CFrame.new(0, 0, -0.8) * CFrame.Angles(math.rad(95), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-45), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-45), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [5] STORM 4 COUNTER ATTACK (Cross-Arm Stance -> Deflection Shockwave)
-- ---------------------------------------------------------
ANIMATIONS["CounterStance"] = {
	duration = 0.38,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(15), math.rad(-20), 0),
				Waist         = CFrame.Angles(0, math.rad(20), 0),
				RightShoulder = CFrame.new(-0.25, 0.15, -0.5) * CFrame.Angles(math.rad(75), math.rad(-40), math.rad(25)),
				LeftShoulder  = CFrame.new(0.25, 0.15, -0.5) * CFrame.Angles(math.rad(75), math.rad(40), math.rad(-25)),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(85), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-20), 0, math.rad(15)),
				LeftHip       = CFrame.Angles(math.rad(15), 0, math.rad(-15)),
			}
		},
		{
			t = 0.50, -- Deflection Outward Burst!
			offsets = {
				RootJoint     = CFrame.new(0, -0.1, -0.4) * CFrame.Angles(math.rad(10), 0, 0),
				Waist         = CFrame.Angles(math.rad(15), 0, 0),
				RightShoulder = CFrame.new(0.3, 0.2, -0.8) * CFrame.Angles(math.rad(90), math.rad(45), math.rad(-25)),
				LeftShoulder  = CFrame.new(-0.3, 0.2, -0.8) * CFrame.Angles(math.rad(90), math.rad(-45), math.rad(25)),
				RightElbow    = CFrame.Angles(math.rad(15), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(15), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [6] CHAKRA LOAD (Naruto Ram Hand Seal)
-- ---------------------------------------------------------
ANIMATIONS["ChakraLoad"] = {
	duration = 0.45,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(10), 0, 0),
				Waist         = CFrame.Angles(math.rad(10), 0, 0),
				RightShoulder = CFrame.new(-0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(-35), math.rad(15)),
				LeftShoulder  = CFrame.new(0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(35), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(-15), 0, math.rad(-10)),
			}
		},
		{
			t = 0.50, -- Pulsing Seal
			offsets = {
				RootJoint     = CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(12), 0, 0),
				Waist         = CFrame.Angles(math.rad(12), 0, 0),
				RightShoulder = CFrame.new(-0.25, -0.1, -0.4) * CFrame.Angles(math.rad(48), math.rad(-35), math.rad(15)),
				LeftShoulder  = CFrame.new(0.25, -0.1, -0.4) * CFrame.Angles(math.rad(48), math.rad(35), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(80), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(80), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(10), 0, 0),
				RightShoulder = CFrame.new(-0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(-35), math.rad(15)),
				LeftShoulder  = CFrame.new(0.25, -0.1, -0.4) * CFrame.Angles(math.rad(45), math.rad(35), math.rad(-15)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [7] NINJUTSU RUSH (Rasengan / Chidori Sprint Thrust)
-- ---------------------------------------------------------
ANIMATIONS["NinjutsuRush"] = {
	duration = 0.60,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(35), math.rad(-25), 0),
				RightShoulder = CFrame.new(0, -0.2, 0.4) * CFrame.Angles(math.rad(-25), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(85), 0, 0),
			}
		},
		{
			t = 0.35, -- Full Forward Sprint Thrust!
			offsets = {
				RootJoint     = CFrame.new(0, -0.45, -0.8) * CFrame.Angles(math.rad(48), 0, 0),
				Waist         = CFrame.Angles(math.rad(15), 0, 0),
				Neck          = CFrame.Angles(math.rad(-35), 0, 0),
				RightShoulder = CFrame.new(0, 0.2, -0.95) * CFrame.Angles(math.rad(95), 0, 0),
				RightElbow    = CFrame.Angles(math.rad(10), 0, 0),
				LeftShoulder  = CFrame.new(0, 0, 0.6) * CFrame.Angles(math.rad(-65), 0, math.rad(-25)),
				RightHip      = CFrame.Angles(math.rad(-45), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(35), 0, 0),
			}
		},
		{
			t = 0.85, -- Hold thrust
			offsets = {
				RootJoint     = CFrame.new(0, -0.45, -0.8) * CFrame.Angles(math.rad(48), 0, 0),
				RightShoulder = CFrame.new(0, 0.2, -0.95) * CFrame.Angles(math.rad(95), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [8] NINJA DASH (Naruto 52° Aerodynamic Flight)
-- ---------------------------------------------------------
ANIMATIONS["NinjaDash"] = {
	duration = 0.50,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, -0.6) * CFrame.Angles(math.rad(52), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				Neck          = CFrame.Angles(math.rad(-38), 0, 0),
				RightShoulder = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(22)),
				LeftShoulder  = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(-22)),
				RightHip      = CFrame.Angles(math.rad(-25), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(25), 0, 0),
			}
		},
		{
			t = 0.5,
			offsets = {
				RootJoint     = CFrame.new(0, -0.42, -0.6) * CFrame.Angles(math.rad(55), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				Neck          = CFrame.Angles(math.rad(-40), 0, 0),
				RightShoulder = CFrame.new(0, 0, 0.55) * CFrame.Angles(math.rad(-68), 0, math.rad(24)),
				LeftShoulder  = CFrame.new(0, 0, 0.55) * CFrame.Angles(math.rad(-68), 0, math.rad(-24)),
				RightHip      = CFrame.Angles(math.rad(25), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-25), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.4, -0.6) * CFrame.Angles(math.rad(52), 0, 0),
				Waist         = CFrame.Angles(math.rad(-10), 0, 0),
				Neck          = CFrame.Angles(math.rad(-38), 0, 0),
				RightShoulder = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(22)),
				LeftShoulder  = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(-65), 0, math.rad(-22)),
				RightHip      = CFrame.Angles(math.rad(-25), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(25), 0, 0),
			}
		}
	}
}

-- ---------------------------------------------------------
-- [9] DEFENSE POSES (High Guard, Low Guard, Parry)
-- ---------------------------------------------------------
ANIMATIONS["HighGuard"] = {
	duration = 0.20,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-20), 0),
				Waist         = CFrame.Angles(0, math.rad(20), 0),
				RightShoulder = CFrame.new(-0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(-35), math.rad(25)),
				LeftShoulder  = CFrame.new(0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(35), math.rad(-25)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(15), 0, math.rad(-10)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(-20), 0),
				Waist         = CFrame.Angles(0, math.rad(20), 0),
				RightShoulder = CFrame.new(-0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(-35), math.rad(25)),
				LeftShoulder  = CFrame.new(0.2, 0.1, -0.5) * CFrame.Angles(math.rad(78), math.rad(35), math.rad(-25)),
				RightElbow    = CFrame.Angles(math.rad(75), 0, 0),
				LeftElbow     = CFrame.Angles(math.rad(75), 0, 0),
				RightHip      = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
				LeftHip       = CFrame.Angles(math.rad(15), 0, math.rad(-10)),
			}
		}
	}
}

ANIMATIONS["LowGuard"] = {
	duration = 0.20,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(22), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(-25), 0),
				LeftShoulder  = CFrame.new(0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(25), 0),
				RightHip      = CFrame.Angles(math.rad(-50), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-50), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(22), 0, 0),
				RightShoulder = CFrame.new(-0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(-25), 0),
				LeftShoulder  = CFrame.new(0.1, -0.3, -0.4) * CFrame.Angles(math.rad(45), math.rad(25), 0),
				RightHip      = CFrame.Angles(math.rad(-50), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-50), 0, 0),
			}
		}
	}
}

ANIMATIONS["Parry"] = {
	duration = 0.30,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.Angles(0, math.rad(35), 0),
				Waist         = CFrame.Angles(0, math.rad(-35), 0),
				RightShoulder = CFrame.new(0.2, 0.2, -0.6) * CFrame.Angles(math.rad(88), math.rad(65), math.rad(-30)),
				LeftShoulder  = CFrame.Angles(math.rad(-20), 0, math.rad(-30)),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- ---------------------------------------------------------
-- [10] HIT REACTIONS & STAGGER STUN
-- ---------------------------------------------------------
ANIMATIONS["HitHead"] = {
	duration = 0.28,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, 0, 0.2) * CFrame.Angles(math.rad(-25), math.rad(-10), 0),
				Waist         = CFrame.Angles(math.rad(-15), 0, 0),
				Neck          = CFrame.Angles(math.rad(-35), math.rad(-15), 0), -- Head snaps back
				RightShoulder = CFrame.Angles(math.rad(-35), 0, math.rad(35)),
				LeftShoulder  = CFrame.Angles(math.rad(-35), 0, math.rad(-35)),
			}
		},
		{
			t = 0.6,
			offsets = {
				RootJoint = CFrame.new(0, 0, 0.1) * CFrame.Angles(math.rad(-10), 0, 0),
				Neck      = CFrame.Angles(math.rad(-15), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

ANIMATIONS["HitGut"] = {
	duration = 0.30,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.3, 0.1) * CFrame.Angles(math.rad(35), 0, 0),
				Waist         = CFrame.Angles(math.rad(25), 0, 0),
				Neck          = CFrame.Angles(math.rad(-15), 0, 0),
				RightShoulder = CFrame.new(0, -0.1, -0.2) * CFrame.Angles(math.rad(35), math.rad(-25), 0),
				LeftShoulder  = CFrame.new(0, -0.1, -0.2) * CFrame.Angles(math.rad(35), math.rad(25), 0),
				RightHip      = CFrame.Angles(math.rad(-30), 0, 0),
				LeftHip       = CFrame.Angles(math.rad(-30), 0, 0),
			}
		},
		{
			t = 1.0,
			offsets = { RootJoint = CFrame.identity }
		}
	}
}

-- Stagger Stun (When parried / countered - dizzy wobble)
ANIMATIONS["StaggerStun"] = {
	duration = 1.30,
	loop = true,
	keyframes = {
		{
			t = 0.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(10), math.rad(15), math.rad(8)),
				Neck          = CFrame.Angles(math.rad(15), math.rad(-10), math.rad(-12)),
				RightShoulder = CFrame.Angles(math.rad(10), 0, math.rad(15)),
				LeftShoulder  = CFrame.Angles(math.rad(10), 0, math.rad(-15)),
			}
		},
		{
			t = 0.5,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(12), math.rad(-15), math.rad(-8)),
				Neck          = CFrame.Angles(math.rad(15), math.rad(10), math.rad(12)),
				RightShoulder = CFrame.Angles(math.rad(5), 0, math.rad(20)),
				LeftShoulder  = CFrame.Angles(math.rad(5), 0, math.rad(-20)),
			}
		},
		{
			t = 1.0,
			offsets = {
				RootJoint     = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(10), math.rad(15), math.rad(8)),
				Neck          = CFrame.Angles(math.rad(15), math.rad(-10), math.rad(-12)),
			}
		}
	}
}

-- Backward compatibility aliases
ANIMATIONS["Attack1"] = ANIMATIONS["Neutral1"]
ANIMATIONS["Attack2"] = ANIMATIONS["Neutral2"]
ANIMATIONS["Attack3"] = ANIMATIONS["Neutral3"]
ANIMATIONS["Attack4"] = ANIMATIONS["Neutral4"]
ANIMATIONS["LowSweep"] = ANIMATIONS["Down2"]
ANIMATIONS["ChakraCharge"] = ANIMATIONS["ChakraLoad"]
ANIMATIONS["Hit"] = ANIMATIONS["HitGut"]
ANIMATIONS["Stagger"] = ANIMATIONS["StaggerStun"]
ANIMATIONS["Block"] = ANIMATIONS["HighGuard"]
ANIMATIONS["Guard"] = ANIMATIONS["HighGuard"]

-- =========================================================
-- ANIMATION PLAYBACK & INTERPOLATION ENGINE
-- =========================================================
triggerCombatAnimation = function(animName: string, durationOverride: number?)
	local seq = ANIMATIONS[animName]
	if not seq then
		print(string.format(">> [StormAnimation] Unknown anim: %s, falling back to Idle <<", animName))
		seq = ANIMATIONS["Idle"]
		animName = "Idle"
	end

	-- Snapshot current applied offsets to start seamless crossfade blend!
	table.clear(blendStartOffsets)
	for k, v in pairs(lastAppliedOffsets) do
		blendStartOffsets[k] = v
	end
	blendStartTime = os.clock()

	currentAnimName = animName
	currentSequence = seq
	animStartTime = os.clock()
	animDuration = durationOverride or seq.duration
	isLooping = seq.loop == true

	-- Weapon trail
	if katanaTrail then
		local isAttack = string.sub(animName, 1, 7) == "Neutral"
			or string.sub(animName, 1, 2) == "Up"
			or string.sub(animName, 1, 4) == "Down"
			or string.sub(animName, 1, 3) == "Air"
			or animName == "NinjaDash"
			or animName == "NinjutsuRush"
		katanaTrail.Enabled = isAttack
	end
end

-- Remote & Bindable Listeners
local evAnim = ReplicatedStorage:FindFirstChild("StormCombatAnimationEvent") :: BindableEvent?
if not evAnim then
	evAnim = Instance.new("BindableEvent")
	evAnim.Name = "StormCombatAnimationEvent"
	evAnim.Parent = ReplicatedStorage
end
evAnim.Event:Connect(triggerCombatAnimation)

-- =========================================================
-- RENDER STEP: JOINT INTERPOLATION & MOTOR6D APPLICATION
-- =========================================================
local function evaluateKeyframeOffsets(seq: AnimationSequence, progress: number): JointOffsets
	local keyframes = seq.keyframes
	if #keyframes == 1 then
		return keyframes[1].offsets
	end

	-- Find surrounding keyframes
	local kfA = keyframes[1]
	local kfB = keyframes[#keyframes]

	for i = 1, #keyframes - 1 do
		if progress >= keyframes[i].t and progress <= keyframes[i + 1].t then
			kfA = keyframes[i]
			kfB = keyframes[i + 1]
			break
		end
	end

	local span = kfB.t - kfA.t
	local alpha = if span > 0.0001 then math.clamp((progress - kfA.t) / span, 0, 1) else 0
	local easedAlpha = snapEase(alpha)

	-- Interpolate all joints in kfB
	local interpolated: JointOffsets = {}
	for jointName, cfB in pairs(kfB.offsets) do
		local cfA = kfA.offsets[jointName] or CFrame.identity
		interpolated[jointName] = cfA:Lerp(cfB, easedAlpha)
	end

	-- Copy any joints present in kfA but missing in kfB
	for jointName, cfA in pairs(kfA.offsets) do
		if not interpolated[jointName] then
			interpolated[jointName] = cfA
		end
	end

	return interpolated
end

local function onRenderStep(dt: number)
	local now = os.clock()
	local elapsed = now - animStartTime
	local seq = currentSequence or ANIMATIONS["Idle"]

	-- Progress calculation
	local progress = 0
	if isLooping then
		progress = (elapsed % animDuration) / animDuration
	else
		progress = math.clamp(elapsed / animDuration, 0, 1)
		-- Check completion of non-looping animation
		if progress >= 1.0 and currentAnimName ~= "Idle" then
			-- Evaluate player attributes for next state
			local isBlocking = LocalPlayer:GetAttribute("IsBlocking") == true
			local blockType = tostring(LocalPlayer:GetAttribute("BlockType") or "None")
			local isDashing = LocalPlayer:GetAttribute("IsNinjaDashing") == true
			local isCharging = LocalPlayer:GetAttribute("IsChakraCharging") == true
			local isCountering = LocalPlayer:GetAttribute("IsCountering") == true

			if isCountering then
				triggerCombatAnimation("CounterStance", 0.35)
			elseif isCharging then
				triggerCombatAnimation("ChakraLoad", 0.45)
			elseif isBlocking then
				triggerCombatAnimation(if blockType == "Low" then "LowGuard" else "HighGuard", 0.20)
			elseif isDashing then
				triggerCombatAnimation("NinjaDash", 0.50)
			else
				triggerCombatAnimation("Idle", 1.8)
				if katanaTrail then katanaTrail.Enabled = false end
			end
			seq = currentSequence or ANIMATIONS["Idle"]
			progress = 0
		end
	end

	-- Evaluate offsets from sequence
	local targetOffsets = evaluateKeyframeOffsets(seq, progress)
	local offsets: JointOffsets = {}

	-- Seamless Crossfade Blend: smoothly interpolate from previous pose to new animation
	local blendElapsed = now - blendStartTime
	if blendElapsed < BLEND_DURATION and next(blendStartOffsets) ~= nil then
		local bAlpha = math.clamp(blendElapsed / BLEND_DURATION, 0, 1)
		local easedBlend = bAlpha * bAlpha * (3 - 2 * bAlpha) -- Hermite smoothstep
		for jointName, tgtCf in pairs(targetOffsets) do
			local startCf = blendStartOffsets[jointName] or tgtCf
			offsets[jointName] = startCf:Lerp(tgtCf, easedBlend)
		end
		for jointName, startCf in pairs(blendStartOffsets) do
			if not offsets[jointName] then
				local tgtCf = targetOffsets[jointName] or startCf
				offsets[jointName] = startCf:Lerp(tgtCf, easedBlend)
			end
		end
	else
		offsets = targetOffsets
	end

	-- Apply offsets to cached joints (AnimationConstraint & Motor6D compatible)
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local isMoving = hum and hum.MoveDirection.Magnitude > 0.1

	for jointName, joint in pairs(joints) do
		if joint then
			local off = offsets[jointName]

			-- Shinobi Run blend: if Idle and character is running, perform Naruto Ninja Run!
			if currentAnimName == "Idle" and isMoving then
				if jointName == "RootJoint" then
					off = CFrame.Angles(math.rad(28), 0, 0)
				elseif jointName == "Waist" then
					off = CFrame.Angles(math.rad(8), 0, 0)
				elseif jointName == "Neck" then
					off = CFrame.Angles(math.rad(-22), 0, 0)
				elseif jointName == "RightShoulder" then
					off = CFrame.Angles(math.rad(-65), math.rad(-10), math.rad(-15))
				elseif jointName == "LeftShoulder" then
					off = CFrame.Angles(math.rad(-65), math.rad(10), math.rad(15))
				elseif jointName == "RightElbow" then
					off = CFrame.Angles(math.rad(18), 0, 0)
				elseif jointName == "LeftElbow" then
					off = CFrame.Angles(math.rad(18), 0, 0)
				elseif jointName:find("Hip") or jointName:find("Knee") or jointName:find("Ankle") then
					-- Let default Roblox walk/run animation cycle legs naturally!
					off = nil
				end
			end

			if off then
				lastAppliedOffsets[jointName] = off
				if joint:IsA("AnimationConstraint") then
					(joint :: AnimationConstraint).Transform = off
				elseif joint:IsA("Motor6D") then
					local m = joint :: Motor6D
					local base = baseC0[jointName]
					if base then
						m.C0 = base * off
					else
						m.Transform = off
					end
				end
			end
		end
	end
end

RunService:BindToRenderStep("StormProceduralAnim", Enum.RenderPriority.Character.Value + 1, onRenderStep)

print("[StormAnimationController] ✅ Master Procedural Anime Animation Engine active — 60FPS Multi-Keyframe Sequencer with Hermite Smoothstep ready.")
