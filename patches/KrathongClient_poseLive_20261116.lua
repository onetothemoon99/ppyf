-- Patch 2026-11-16 (option B, user approved): krathong / lantern poses work in the LIVE game
-- Target: game.StarterPlayer.StarterPlayerScripts.KrathongClient
-- Why: the poses were built with KeyframeSequenceProvider:RegisterKeyframeSequence (rbxtemp://),
--      which only works in Studio. In live servers the character did not move.
-- Fix: same pose angles, but each client writes the joint Transform itself every PreSimulation
--      (the method OrchardGui's planting pose already uses and that moves the character in Play).
--      loadPose() keeps its old signature and returns an object with :Play(fade) / :Stop(fade),
--      so startPray / startHang / startRelease / switch / endPray stay unchanged.
--
-- HOW TO APPLY: replace the block that starts at the line
--   "-- ============ ท่าอธิษฐาน: ยกกระทงขึ้นเหนือหัวก่อนลอย (2026-11-07) ============"
-- and ends with the "local function loadPose(animator, name) ... end" function
-- (backup file lines 839-917), with everything below the cut line.
-- Before applying, save the live Source to backups/KrathongClient_before_poseLive_20261116.lua.
-- ------------------------------------------------------------------ cut ------------------------

-- ============ ท่าอธิษฐาน: ยกกระทงขึ้นเหนือหัวก่อนลอย (2026-11-07) ============
local praying = {} -- [character] = { t0, dur, model, tracks, hidden, head, lift, phase }
-- ท่าลอยกระทง (2026-11-07 ผู้ใช้สั่ง "นั่งลงแล้วยกมืออธิษฐานแล้วลอยกระทงลงน้ำ"):
--   คุกเข่าลงถือกระทงระดับอก → ยกกระทงจรดหน้าผากอธิษฐาน → โน้มตัวยื่นแขนวางกระทงลงน้ำ → ลุกขึ้น
-- 2026-11-16: เดิมสร้างท่าด้วย KeyframeSequenceProvider (rbxtemp://) ซึ่งใช้ได้แค่ใน Studio → เกมจริงตัวไม่ขยับ
--   ตอนนี้ทุกเครื่องเขียน Transform ของข้อต่อเองทุกเฟรมช่วง PreSimulation (หลังแอนิเมชันเดิน เหมือนท่าปลูกใน OrchardGui)
--   ทำงานได้ทั้ง Motor6D และ AnimationConstraint · R6 = ไม่มีข้อต่อชื่อเหล่านี้ ท่าไม่ขึ้น แต่กระทงยังเคลื่อนตามลำดับ
local KNEEL_DROP = 0.9 -- ลดลำตัวลงตอนคุกเข่า (สตั๊ด) ทดสอบ 2026-11-07: 1.5 แข้งจมพื้น ~0.6 / 1.2 จม ~0.3
local function rx(d) return CFrame.Angles(math.rad(d), 0, 0) end
local POSES = {
	-- คุกเข่า ถือกระทงระดับอก
	hold = { LowerTorso = CFrame.new(0, -KNEEL_DROP, 0), UpperTorso = CFrame.new(),
		RightUpperLeg = CFrame.new(), LeftUpperLeg = CFrame.new(), RightLowerLeg = rx(-90), LeftLowerLeg = rx(-90),
		RightUpperArm = rx(50) * CFrame.Angles(0, 0, math.rad(18)), LeftUpperArm = rx(50) * CFrame.Angles(0, 0, math.rad(-18)),
		RightLowerArm = rx(55), LeftLowerArm = rx(55) },
	-- คุกเข่า ยกกระทงจรดหน้าผาก (อธิษฐาน)
	wish = { LowerTorso = CFrame.new(0, -KNEEL_DROP, 0), UpperTorso = rx(-5),
		RightUpperLeg = CFrame.new(), LeftUpperLeg = CFrame.new(), RightLowerLeg = rx(-90), LeftLowerLeg = rx(-90),
		RightUpperArm = rx(115) * CFrame.Angles(0, 0, math.rad(22)), LeftUpperArm = rx(115) * CFrame.Angles(0, 0, math.rad(-22)),
		RightLowerArm = rx(45), LeftLowerArm = rx(45) },
	-- คุกเข่า โน้มตัวไปข้างหน้า ยื่นแขนวางกระทงลงน้ำ
	place = { LowerTorso = CFrame.new(0, -KNEEL_DROP, 0), UpperTorso = rx(-35),
		RightUpperLeg = CFrame.new(), LeftUpperLeg = CFrame.new(), RightLowerLeg = rx(-90), LeftLowerLeg = rx(-90),
		RightUpperArm = rx(80) * CFrame.Angles(0, 0, math.rad(8)), LeftUpperArm = rx(80) * CFrame.Angles(0, 0, math.rad(-8)),
		RightLowerArm = rx(10), LeftLowerArm = rx(10) },
}
-- ยืนชูแขนสองข้างขึ้นเหนือหัว ปล่อยโคมลอย (2026-11-08) ขาไม่ใส่ = ใช้ท่ายืนปกติ
POSES.reach = {
	RightUpperArm = rx(160) * CFrame.Angles(0, 0, math.rad(12)), LeftUpperArm = rx(160) * CFrame.Angles(0, 0, math.rad(-12)),
	RightLowerArm = rx(15), LeftLowerArm = rx(15), UpperTorso = rx(6) }
-- แขวนโคม: ชูมือขวามือเดียวถือไม้ไผ่ขึ้นเหนือหัว แขนซ้ายปล่อยตามท่ายืนปกติ (2026-11-14 ผู้ใช้สั่ง "ถือมือเดียวแล้วยกมือขึ้น")
--   ใช้เฉพาะ startHang · ปล่อยโคมลอย (startRelease) ยังใช้ reach สองแขน
POSES.reachOne = {
	RightUpperArm = rx(165) * CFrame.Angles(0, 0, math.rad(18)), RightLowerArm = rx(8), UpperTorso = rx(4) }

-- ชื่อข้อต่อ R15 (อยู่ในชิ้นลูก เช่น RightUpperArm.RightShoulder)
local POSE_JOINT = {
	LowerTorso = "Root", UpperTorso = "Waist",
	RightUpperArm = "RightShoulder", LeftUpperArm = "LeftShoulder", RightLowerArm = "RightElbow", LeftLowerArm = "LeftElbow",
	RightUpperLeg = "RightHip", LeftUpperLeg = "LeftHip", RightLowerLeg = "RightKnee", LeftLowerLeg = "LeftKnee",
}
local function isJoint(x) return x:IsA("Motor6D") or x:IsA("AnimationConstraint") end
local function poseJoint(ch, partName)
	local part = ch:FindFirstChild(partName)
	if not part then return nil end
	local j = part:FindFirstChild(POSE_JOINT[partName] or "")
	if j and isJoint(j) then return j end
	return nil
end
local function poseEase(x) x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end

-- "แทร็ก" ท่า: :Play(fade) ค่อยๆ ใส่ท่า · :Stop(fade) ค่อยๆ คืนท่าเดิม (แทนที่ AnimationTrack เดิม)
local poseActive = {} -- [character] = { track, ... } ตัวหลังสุดเขียนทับทีหลัง (อยู่บนสุด)
local PoseTrack = {}
PoseTrack.__index = PoseTrack
function PoseTrack:Play(fade)
	self.target = 1
	self.rate = 1 / math.max(tonumber(fade) or 0.1, 0.02)
	local list = poseActive[self.ch]
	if not list then list = {} poseActive[self.ch] = list end
	local i = table.find(list, self)
	if i then table.remove(list, i) end
	table.insert(list, self)
end
function PoseTrack:Stop(fade)
	self.target = 0
	self.rate = 1 / math.max(tonumber(fade) or 0.1, 0.02)
end
local function loadPose(animator, name)
	local spec = POSES[name]
	local hum = animator and animator.Parent
	local ch = hum and hum.Parent
	if not spec or not ch or not ch:IsA("Model") then return nil end
	local joints = {}
	for partName, cf in pairs(spec) do
		local j = poseJoint(ch, partName)
		if j then joints[j] = cf end
	end
	if next(joints) == nil then return nil end
	return setmetatable({ ch = ch, joints = joints, w = 0, target = 0, rate = 10 }, PoseTrack)
end
-- PreSimulation = หลัง Animator เขียนท่าเดิน/ยืนของเฟรมนี้แล้ว เราผสมท่าทับ (OrchardGui ใช้จังหวะเดียวกัน ขยับจริงใน Play)
RunService.PreSimulation:Connect(function(dt)
	if next(poseActive) == nil then return end
	for ch, list in pairs(poseActive) do
		if not ch.Parent then
			poseActive[ch] = nil
		else
			for i = #list, 1, -1 do
				local t = list[i]
				if t.w < t.target then t.w = math.min(t.target, t.w + dt * t.rate)
				elseif t.w > t.target then t.w = math.max(t.target, t.w - dt * t.rate) end
				if t.w <= 0 and t.target <= 0 then table.remove(list, i) end
			end
			for _, t in ipairs(list) do
				local k = poseEase(t.w)
				for j, cf in pairs(t.joints) do
					if j.Parent then j.Transform = j.Transform:Lerp(cf, k) end
				end
			end
			if #list == 0 then poseActive[ch] = nil end
		end
	end
end)
