-- BACKUP 2026-11-11 of game.StarterPlayer.StarterPlayerScripts.PetAnimator (LocalScript, Studio) before the platypus "dive" work pose.
-- Restore: copy everything BELOW the "==== SOURCE ====" line into that script's Source in Studio.
-- ==== SOURCE ====
-- PetAnimator: แอนิเมชันสัตว์เลี้ยงทุกตัว ทำบนเครื่องผู้เล่น (2026-10-12) ย้ายมาจาก PetController ฝั่งเซิร์ฟเวอร์
-- เดิมเซิร์ฟเวอร์ขยับข้อต่อ (Motor6D.C0) + เลื่อนตัว (PivotTo) ทุกเฟรม ข้อมูลทั้งหมดถูกส่งหาผู้เล่นทุกคน
--   วัดได้ ~25 KB/วิ ต่อสัตว์ 1 ตัว เซิร์ฟเวอร์เต็ม = เกิน 2 MB/วิ ต่อคน ของที่เพิ่งสร้าง (สัตว์/หุ่น/ตัวละคร) เลยมาถึงช้าหรือไม่ครบ
-- ตอนนี้เซิร์ฟเวอร์ส่งแค่ตำแหน่งตัวสัตว์ ~10 ครั้ง/วิ (เฉพาะตอนขยับ) สคริปต์นี้ทำที่เหลือ:
--   1) เกลี่ยตำแหน่งให้ลื่นทุกเฟรม  2) ท่าเดิน/หู/หาง/หางพัด/ปีก  3) ท่าก้มจิก-เด้งตัวตอนทำงาน (Attribute WorkAnim)
--   4) ลอยขึ้นลงของสัตว์บิน  5) สีรุ้งของสัตว์เทพ (Attribute RainbowAura)
-- สัตว์ = Model ลูกตรงของ workspace ที่มี Attribute PetId + OwnerUserId + FacingOffset (PetController.Spawn ตั้งให้)
-- จังหวะหู/หางของแต่ละเครื่องไม่ตรงกันเป๊ะ (สุ่มคนละชุด) แต่ตำแหน่งและการทำงานของสัตว์ตรงกันทุกคน
-- สคริปต์อื่นที่ต้องเกาะตามตัวสัตว์ทุกเฟรม ให้อ่านตำแหน่งจาก ReplicatedStorage.PetRenderState

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local GraphicsConfig = require(ReplicatedStorage:WaitForChild("GraphicsConfig"))
local PetRenderState = require(ReplicatedStorage:WaitForChild("PetRenderState"))

local player = Players.LocalPlayer
local rng = Random.new()

local SNAP_DISTANCE = 12        -- ตำแหน่งใหม่ห่างจากที่วาดอยู่เกินนี้ (วาร์ป/เรียกกลับ) = ย้ายทันที ไม่ไถลข้ามแมพ
-- วาดตำแหน่งย้อนหลังเล็กน้อย (ช่วงส่งของเซิร์ฟเวอร์ x ค่านี้) แล้วไล่ระหว่างตำแหน่งที่ได้รับ 2 ครั้งล่าสุดตามเวลาจริง
-- ไม่ขึ้นกับเฟรมเรต: เครื่อง 15 fps กับ 60 fps เห็นสัตว์เดินด้วยความเร็วเท่ากัน (แบบแรกที่ลอง เริ่มไล่ใหม่ทุกครั้งที่ข้อมูลมา เครื่องเฟรมต่ำตามไม่ทันแล้วกระตุก)
local RENDER_DELAY_FACTOR = 1.5
local MIN_RENDER_DELAY = 0.12
local FOLLOW_SPEED = 18         -- ความเร็วเดินตามของสัตว์ (เท่า PetController) ใช้คิดมุมก้มหัวตอนบินเร็ว
local CANDIDATE_LIFETIME = 15   -- รอ Attribute/ชิ้นส่วนของโมเดลที่เพิ่งเข้ามาได้นานสุดกี่วินาที
-- ไกลกล้องเกินนี้ไม่ขยับข้อต่อ (ยังเกลี่ยตำแหน่งอยู่) ตามระดับกราฟิก
local JOINT_DISTANCE = { high = 120, mid = 90, low = 60, lowest = 40 }
-- สัตว์ที่ไกลกว่านี้ขยับข้อต่อเฟรมเว้นเฟรม (มองไม่ออก แต่งานของเครื่องลดครึ่งตอนเซิร์ฟเวอร์มีสัตว์ 60-90 ตัว)
local FULL_RATE_DISTANCE = 35

-- ============ ท่าเดิน/ยืน (กระโดดแบบกระต่าย + หู + หาง) ============
-- คืนฟังก์ชัน step(dt) หรือ nil ถ้าโมเดลไม่มีข้อต่อขา · ms = { speed, turnRate } ของสัตว์ตัวนี้
local function buildWalk(petModel, boneNames, ms)
	local usedMotors = {}

	local function find(name)
		if not name then return nil end

		local target = nil
		for _, descendant in ipairs(petModel:GetDescendants()) do
			if string.lower(descendant.Name) == string.lower(name) then
				target = descendant
				break
			end
		end
		if not target then return nil end

		if target:IsA("Motor6D") then
			if usedMotors[target] then return nil end
			usedMotors[target] = true
			return target
		end

		local part = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
		if not part then return nil end

		local motor = part:FindFirstChildOfClass("Motor6D")
		if motor and not usedMotors[motor] then
			usedMotors[motor] = true
			return motor
		end

		for _, other in ipairs(petModel:GetDescendants()) do
			if other:IsA("Motor6D") and other.Part1 == part and not usedMotors[other] then
				usedMotors[other] = true
				return other
			end
		end

		return nil
	end

	local leftHip = find(boneNames.LeftHip)
	local rightHip = find(boneNames.RightHip)
	local leftShoulder = find(boneNames.LeftShoulder)
	local rightShoulder = find(boneNames.RightShoulder)
	local leftEar = find(boneNames.LeftEar)
	local rightEar = find(boneNames.RightEar)
	local neck = find(boneNames.Neck)
	local rootJoint = find(boneNames.Root)
	local tail = find(boneNames.Tail)

	if not leftHip or not rightHip then return nil end

	local origC0 = {}
	for _, motor in { leftHip, rightHip, leftShoulder, rightShoulder, leftEar, rightEar, neck, rootJoint, tail } do
		if motor then origC0[motor] = motor.C0 end
	end

	local animTime = 0
	-- ท่าวิ่งเหยาะแบบหมา (2026-10-22 ซุกซน): Attribute "AnimGait" = "Trot" บนโมเดล = ขาทแยงก้าวสลับกัน ตัวเด้งน้อย หางกระดิกแรง/เร็วกว่า
	local trot = petModel:GetAttribute("AnimGait") == "Trot"
	-- ท่ากระโดดแบบจิงโจ้ (2026-10-29 จริงใจ): AnimGait = "Hop" = กระโดดสองขาพร้อมกัน ลอยสูง ตัวโน้มหน้า แขนหดหน้าอก หางถ่วงสมดุล
	-- ริกจริงใจหันหน้า -Z: Angles(บวก,0,0) ที่สะโพก/ไหล่ = เหวี่ยงขา/แขนไปข้างหน้า, ที่ลำตัว = เอนไปข้างหลัง
	local kangaroo = petModel:GetAttribute("AnimGait") == "Hop"
	-- แขนหดไว้หน้าอกตลอด (ยืน/กระโดด) แบบจิงโจ้จริง: Attribute โมเดล ArmTuckL/ArmTuckR = Vector3 องศา (ยกไปหน้า, หมุน, เอียงเข้าใน)
	-- ค่าต่างกันซ้ายขวาเพราะไหล่ของโมเดลไม่สมมาตร (หาจากตำแหน่งอุ้งมือให้อยู่หน้าอก ดูภาพใน Studio 2026-10-29)
	local function tuckPose(attr)
		local v = petModel:GetAttribute(attr)
		if typeof(v) ~= "Vector3" then return nil end
		return CFrame.Angles(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
	end
	local armTuck = {}
	if leftShoulder then armTuck[leftShoulder] = tuckPose("ArmTuckL") end
	if rightShoulder then armTuck[rightShoulder] = tuckPose("ArmTuckR") end
	-- extra = ยก/ลดเพิ่มตามจังหวะ (เรเดียน)
	local function setArm(motor, extra)
		if not (motor and origC0[motor]) then return end
		motor.C0 = origC0[motor] * (armTuck[motor] or CFrame.new()) * CFrame.Angles(extra, 0, 0)
	end
	local wagScale = trot and 1.5 or 1
	-- hysteresis: เริ่มท่าเดินเมื่อเร็วเกิน 1.2 และกลับไปท่ายืนเมื่อช้ากว่า 0.4 (เกณฑ์เดียวจะสลับท่าทุกเฟรม เห็นเป็นตัวสั่น)
	local moving = false
	-- ค่าถ่วงให้ท่าเปลี่ยนแบบไล่ระดับ ไม่กระตุกตอนสลับท่า
	local blend = 0
	-- ท่ายืน: สะบัดหูและเหลียวมองเป็นครั้งคราว
	-- แกนหมุนของริกนี้ (วัดจากของจริง): Angles(x,0,0) = ก้ม/เงย, Angles(0,0,z) = หันซ้ายขวา
	local TWITCH_TIME, GLANCE_TIME = 0.4, 1.8
	local twitchTimer, twitchT, twitchLeft = rng:NextNumber(1, 3), 0, true
	local glanceTimer, glanceT, glanceDir = rng:NextNumber(2, 5), 0, 1

	-- หู: สปริง 2 แกนต่อข้าง (พับหน้า-หลัง + เอียงซ้าย-ขวา) ขยับตามแรงเฉื่อยของตัว
	local EAR_STIFFNESS = 70    -- ความแข็ง (หูเด้งกลับเร็วแค่ไหน)
	local EAR_DAMPING = 6       -- หน่วง (น้อย = ไหวหลายรอบก่อนนิ่ง)
	local EAR_KICK = 0.55       -- แรงกระตุกต่อการเปลี่ยนความเร็วแนวดิ่งของตัว
	local EAR_RUN_LEAN = 0.35   -- หูลู่หลังสูงสุดตอนวิ่งเต็มที่ (เรเดียน)
	local EAR_TURN_TILT = 0.08  -- หูเอียงต่อความเร็วเลี้ยว
	local function makeEar(motor, stiffness)
		return motor and { motor = motor, pitch = 0, pitchVel = 0, roll = 0, rollVel = 0, k = stiffness, c = EAR_DAMPING } or nil
	end
	local ears = {}
	table.insert(ears, makeEar(leftEar, EAR_STIFFNESS))
	table.insert(ears, makeEar(rightEar, EAR_STIFFNESS * 1.06)) -- ต่างกันนิดเดียว ไม่พร้อมกันเป๊ะแต่ยังไปทางเดียวกัน
	local lastBounce, lastBounceVel = 0, 0

	-- extra = ขยับตรงๆ ซ้อนบนสปริง (หายใจ/สะบัดหู) ต่อข้าง
	local function updateEars(dt, speed, bounce, extraL, extraR)
		dt = math.min(dt, 1 / 20) -- กันเฟรมกระตุกยาวๆ ทำสปริงระเบิด
		local bounceVel = (bounce - lastBounce) / math.max(dt, 1 / 240)
		local kick = (bounceVel - lastBounceVel) * EAR_KICK
		lastBounce, lastBounceVel = bounce, bounceVel
		local lean = -math.clamp(speed / 16, 0, 1) * EAR_RUN_LEAN * blend
		local tilt = math.clamp(-(ms.turnRate or 0) * EAR_TURN_TILT, -0.35, 0.35) * blend
		for _, ear in ipairs(ears) do
			if origC0[ear.motor] then
				-- ตัวดีดขึ้นกะทันหัน (เท้าแตะพื้น) = หูยังไปทางเดิมตามแรงเฉื่อย
				ear.pitchVel += -kick
				ear.pitchVel += ((lean - ear.pitch) * ear.k - ear.pitchVel * ear.c) * dt
				ear.pitch = math.clamp(ear.pitch + ear.pitchVel * dt, -0.9, 0.6)
				ear.rollVel += ((tilt - ear.roll) * ear.k - ear.rollVel * ear.c) * dt
				ear.roll = math.clamp(ear.roll + ear.rollVel * dt, -0.5, 0.5)
				local extra = (ear.motor == leftEar and extraL or extraR) or 0
				ear.motor.C0 = origC0[ear.motor] * CFrame.Angles(ear.pitch + extra, 0, ear.roll)
			end
		end
	end

	-- หาง: สปริง 2 แกน (ส่ายซ้ายขวา + เด้งขึ้นลง)
	local tailYaw, tailYawVel = 0, 0
	local tailPitch, tailPitchVel = 0, 0
	local wagTime = 0
	local TAIL_STIFFNESS = 55
	local TAIL_DAMPING = 9

	local function updateTail(dt, speed, hopPhase)
		if not (tail and origC0[tail]) then return end
		local moveAmt = blend * math.clamp(speed / 14, 0.3, 1.2)

		-- ส่ายซ้ายขวา: ยืนนิ่งส่ายช้าๆ เดินแล้วส่ายตามจังหวะก้าว แรงขึ้นตามความเร็ว
		local walkFreq = math.clamp((3 + speed * 0.6) * 0.5, 3, 7)
		local freq = (1.6 + (walkFreq - 1.6) * blend) * wagScale
		wagTime += dt * freq
		local amp = (0.22 + ((0.4 + 0.15 * moveAmt) - 0.22) * blend) * (trot and 1.35 or 1) -- ยืนนิ่ง ±13° / เดิน ±23-31° (หมา x1.35)
		local targetYaw = math.sin(wagTime) * amp
		-- เลี้ยว: ตัวหมุนไปก่อน หางตามมาทีหลัง เลยเหวี่ยงไปทางตรงข้ามกับทิศที่เลี้ยว
		targetYaw += math.clamp(-(ms.turnRate or 0) * 0.12, -0.45, 0.45)

		-- เด้งขึ้นลงตามจังหวะกระโดด ยืนนิ่งแค่ขยับเบาๆ ตามลมหายใจ
		local targetPitch = -hopPhase * 0.4 * moveAmt + math.sin(wagTime * 0.5) * 0.05 * (1 - blend)

		tailYawVel += ((targetYaw - tailYaw) * TAIL_STIFFNESS - tailYawVel * TAIL_DAMPING) * dt
		tailYaw += tailYawVel * dt
		tailPitchVel += ((targetPitch - tailPitch) * TAIL_STIFFNESS - tailPitchVel * TAIL_DAMPING) * dt
		tailPitch += tailPitchVel * dt
		tail.C0 = origC0[tail] * CFrame.Angles(tailPitch, tailYaw, 0)
	end

	-- ท่านอนขด (2026-10-22 ซุกซน): Attribute โมเดล SleepPose = "Curl" + เซิร์ฟเวอร์ตั้ง "Sleeping" = true เมื่อเจ้าของนิ่งนาน (PetController, def.SleepAfter)
	-- ลำตัวแข็งงอไม่ได้ เลยทำวงด้วย: ตัวหมอบ ขาพับใต้ท้อง หัวย้ายไปข้างไหล่ซ้ายหันกลับหาหาง หางพาดข้างซ้ายมาทางหัว (ปรับมุมจากภาพใน Studio)
	local sleepPose = nil
	if petModel:GetAttribute("SleepPose") == "Curl" then
		local r = math.rad
		sleepPose = {}
		local function put(motor, cf) if motor and origC0[motor] then sleepPose[motor] = cf end end
		put(rootJoint, CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, r(-12)))
		put(leftShoulder, CFrame.Angles(r(80), 0, 0))
		put(rightShoulder, CFrame.Angles(r(80), 0, 0))
		put(leftHip, CFrame.Angles(r(-80), 0, 0))
		put(rightHip, CFrame.Angles(r(-80), 0, 0))
		put(neck, CFrame.new(0.42, -0.22, -0.30) * CFrame.Angles(0, r(135), 0) * CFrame.Angles(r(22), 0, r(-10)))
		put(tail, CFrame.Angles(0, r(-65), 0) * CFrame.Angles(0, 0, r(-95)) * CFrame.Angles(r(-10), 0, 0))
		put(leftEar, CFrame.Angles(r(-30), 0, 0))
		put(rightEar, CFrame.Angles(r(-30), 0, 0))
	end
	-- ท่านั่งรอ (2026-10-22 ซุกซน): Attribute โมเดล SitPose = "Dog" + เซิร์ฟเวอร์ตั้ง "Sitting" = true เมื่อเจ้าของหยุดเดิน (def.SitAfter)
	-- ตัวเชิดหน้าขึ้น ก้นลงพื้น ขาหลังพับ ขาหน้าตั้ง หัวตั้งตรง (หางไม่อยู่ในท่า = ยังกระดิกได้) ปรับมุมจากภาพใน Studio
	local sitPose = nil
	if petModel:GetAttribute("SitPose") == "Dog" then
		local r = math.rad
		sitPose = {}
		local function put(motor, cf) if motor and origC0[motor] then sitPose[motor] = cf end end
		put(rootJoint, CFrame.new(0, -0.22, -0.12) * CFrame.Angles(r(-35), 0, 0))
		put(leftShoulder, CFrame.Angles(r(35), 0, 0))
		put(rightShoulder, CFrame.Angles(r(35), 0, 0))
		put(leftHip, CFrame.Angles(r(-60), 0, 0))
		put(rightHip, CFrame.Angles(r(-60), 0, 0))
		put(neck, CFrame.Angles(r(28), 0, 0))
	end
	local sitBlend = 0
	local function applySit(dt, speed)
		if not sitPose then return end
		-- นั่งเมื่อหยุดเดินแล้วจริงๆ (ยังเดินไปจุดยืนอยู่ = ยังไม่นั่ง) ลงนั่ง ~0.4 วิ ลุก ~0.2 วิ
		local want = petModel:GetAttribute("Sitting") == true and speed < 0.6
		sitBlend = math.clamp(sitBlend + (want and dt / 0.4 or -dt / 0.2), 0, 1)
		if sitBlend <= 0 then return end
		local s = sitBlend * sitBlend * (3 - 2 * sitBlend)
		for motor, pose in pairs(sitPose) do
			motor.C0 = motor.C0:Lerp(origC0[motor] * pose, s)
		end
	end

	local sleepBlend, sleepT = 0, 0
	local zzz = nil -- ป้าย 💤 เหนือหัว (สร้างตอนหลับครั้งแรก)
	-- โมเดลนอนขดแยก (SleepModel ปั้นใน Blender ตัวงอเป็นวงจริง ชิ้นมี Attribute SleepPart, ปกติ Transparency 1)
	-- ลงนอนเสร็จ = ซ่อนตัวปกติ (LocalTransparencyModifier เฉพาะเครื่องนี้) + โชว์ตัวนอน · ตื่น = สลับกลับทันที
	-- เจ้าของอุ้มอยู่ (HeldByOwner) = ไม่สลับ (ตัวจริงถูกซ่อนอยู่แล้ว)
	local sleepModel = petModel:FindFirstChild("SleepModel")
	local sleepParts, normalParts, swapped = {}, {}, false
	if sleepModel then
		for _, d in ipairs(petModel:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				if d:GetAttribute("SleepPart") then table.insert(sleepParts, d) else table.insert(normalParts, d) end
			end
		end
	end
	local function setSwapped(on)
		if on == swapped then return end
		swapped = on
		for _, p in ipairs(normalParts) do p.LocalTransparencyModifier = on and 1 or 0 end
		for _, p in ipairs(sleepParts) do p.Transparency = on and 0 or 1 end
	end

	local function applySleep(dt)
		if not sleepPose then return end
		local want = petModel:GetAttribute("Sleeping") == true
		-- ค่อยๆ ลงนอน (~1.5 วิ) ตื่นเร็วกว่า (~0.4 วิ)
		sleepBlend = math.clamp(sleepBlend + (want and dt / 1.5 or -dt / 0.4), 0, 1)
		if zzz then zzz.Enabled = sleepBlend > 0.95 end
		if sleepModel then setSwapped(sleepBlend >= 0.98 and not petModel:GetAttribute("HeldByOwner")) end
		if sleepBlend <= 0 then return end
		sleepT += dt
		local s = sleepBlend * sleepBlend * (3 - 2 * sleepBlend) -- smoothstep
		local breathe = CFrame.new(0, math.sin(sleepT * 1.6) * 0.02, 0)
		for motor, pose in pairs(sleepPose) do
			local target = origC0[motor] * pose
			if motor == rootJoint then target = target * breathe end
			motor.C0 = motor.C0:Lerp(target, s)
		end
		if not zzz and sleepBlend > 0.95 then
			local head = (sleepModel and sleepModel:FindFirstChild("Sleep_Head")) or petModel:FindFirstChild("Head")
			if head then
				zzz = Instance.new("BillboardGui")
				zzz.Name = "SleepZzz"
				zzz.Size = UDim2.fromOffset(50, 30)
				zzz.StudsOffset = Vector3.new(0.6, 1, 0)
				zzz.MaxDistance = 60
				zzz.LightInfluence = 0
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.TextScaled = true
				-- สีชมพู (ผู้ใช้ขอ 2026-10-22) อีโมจิ 💤 เปลี่ยนสีไม่ได้ (ขึ้นสีฟ้าเสมอ) เลยใช้ตัวอักษรแทน
				label.Text = "zZz"
				label.Font = Enum.Font.FredokaOne
				label.TextColor3 = Color3.fromRGB(255, 120, 175)
				label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
				label.TextStrokeTransparency = 0.2
				label.Rotation = -12
				label.Parent = zzz
				zzz.Adornee = head
				zzz.Parent = head
			end
		end
	end

	return function(dt)
		local speed = ms.speed or 0
		if speed > 1.2 then moving = true elseif speed < 0.4 then moving = false end
		blend += math.clamp((moving and 1 or 0) - blend, -dt * 6, dt * 6)
		local isMoving = blend > 0.01

		-- ว่ายน้ำ (2026-11-06 ตุ่นนักอนุรักษ์): เซิร์ฟเวอร์ตั้ง Attribute Swimming ตอนอยู่บนผิวน้ำ = ตัวโน้มไปหน้า ลอยขึ้นลงเบาๆ เท้ากับหางพาย ไม่เล่นท่าเดิน
		if petModel:GetAttribute("Swimming") == true then
			animTime += dt * 7
			local stroke = math.sin(animTime)
			local effort = 0.35 + 0.65 * blend
			if rootJoint and origC0[rootJoint] then
				rootJoint.C0 = origC0[rootJoint] * CFrame.new(0, math.sin(animTime * 0.5) * 0.06, 0) * CFrame.Angles(math.rad(-18), 0, 0)
			end
			if origC0[leftHip] then leftHip.C0 = origC0[leftHip] * CFrame.Angles(stroke * 0.7 * effort, 0, 0) end
			if origC0[rightHip] then rightHip.C0 = origC0[rightHip] * CFrame.Angles(-stroke * 0.7 * effort, 0, 0) end
			if neck and origC0[neck] then neck.C0 = origC0[neck] * CFrame.Angles(math.rad(14), 0, 0) end
			updateEars(dt, speed, 0)
			updateTail(dt, speed, stroke)
			return
		end

		if isMoving and kangaroo then
			-- กระโดดจิงโจ้จริง (ปรับ 2026-10-29): ต่อรอบ = แตะพื้นสั้นๆ (ย่อเก็บแรงแล้วดีด) 28% + ลอยโค้งยาว 72%
			-- จิงโจ้กระโดดจังหวะเกือบคงที่ วิ่งเร็วขึ้น = ลอยสูง/ไกลขึ้น ไม่ได้กระโดดถี่ขึ้นมาก
			local hopFreq = math.clamp(1.6 + speed * 0.04, 1.6, 2.6) -- ครั้งต่อวินาที
			animTime += dt * hopFreq
			local p = animTime % 1
			local intensity = math.clamp(speed / 12, 0.5, 1.2) * blend
			local STANCE = 0.28
			local height, legAngle, lean, armExtra, tailPhase
			if p < STANCE then
				local u = p / STANCE -- 0 = เพิ่งแตะพื้น -> 1 = ดีดตัว
				local squash = math.sin(u * math.pi)
				height = -squash * 0.14
				legAngle = 0.5 - u * 1.15         -- ขายื่นรับพื้นข้างหน้า -> ถีบไปข้างหลัง
				lean = 0.22 + 0.16 * squash       -- ย่อแล้วตัวก้มไปหน้า
				armExtra = -0.12 * squash          -- แขนตกตามแรงกระแทก
				tailPhase = -0.7                   -- หางลงแตะพื้นช่วยค้ำ
			else
				local u = (p - STANCE) / (1 - STANCE) -- 0 = ออกจากพื้น -> 1 = ก่อนลงพื้น
				height = 4 * u * (1 - u) * 0.8   -- โค้งพาราโบลา
				local swing = u * u * (3 - 2 * u)
				legAngle = -0.65 + 1.15 * swing   -- ขาเหยียดหลังตอนออกตัว แล้วค่อยเหวี่ยงมาหน้ารับพื้น
				lean = 0.34 - 0.14 * u            -- ลอยตัวโน้มไปหน้า ใกล้ลงพื้นค่อยยกตัวขึ้น
				armExtra = 0.08 * math.sin(u * math.pi)
				tailPhase = 1 - 0.6 * u            -- ลอย = หางยกตรงไปข้างหลังถ่วงตัว
			end
			local bodyBounce = height * intensity
			if rootJoint and origC0[rootJoint] then
				rootJoint.C0 = origC0[rootJoint] * CFrame.new(0, bodyBounce, 0) * CFrame.Angles(-lean * intensity, 0, 0)
			end
			-- ขาคู่หลังพร้อมกันเสมอ
			legAngle *= intensity
			if origC0[leftHip] then leftHip.C0 = origC0[leftHip] * CFrame.Angles(legAngle, 0, 0) end
			if origC0[rightHip] then rightHip.C0 = origC0[rightHip] * CFrame.Angles(legAngle, 0, 0) end
			-- แขนหดหน้าอก อุ้งมือห้อย ขยับแค่นิดเดียวตามแรงกระโดด
			setArm(leftShoulder, armExtra * blend)
			setArm(rightShoulder, armExtra * blend)
			-- หัวเงยชดเชยตัวที่ก้ม สายตายังมองไปข้างหน้า
			if neck and origC0[neck] then neck.C0 = origC0[neck] * CFrame.Angles(lean * 0.6 * intensity, 0, 0) end
			updateEars(dt, speed, bodyBounce)
			updateTail(dt, speed, tailPhase * 1.4)
		elseif isMoving then
			-- ความถี่กระโดดเปลี่ยนตามความเร็ว: เดินช้า = กระโดดช้าๆ, วิ่งเร็ว = กระโดดถี่เร็ว
			local hopFreq = math.clamp(3 + speed * 0.6, 3, 14)
			animTime += dt * hopFreq

			local intensity = math.clamp(speed / 14, 0.25, 1.5) * blend -- คูณ blend ให้ท่าค่อยๆ เข้า/ออก

			-- วงจรกระโดดกระต่าย: sin = 1 กำลังกระโดดขึ้น (ขาเหยียด) / sin = -1 กำลังลง (ขางอ)
			local hopPhase = math.sin(animTime)
			local hopPhaseAbs = math.abs(hopPhase)

			local legAngle = hopPhase * 0.6 * intensity
			if origC0[leftHip] then leftHip.C0 = origC0[leftHip] * CFrame.Angles(legAngle, 0, 0) end
			if origC0[rightHip] then rightHip.C0 = origC0[rightHip] * CFrame.Angles(trot and -legAngle or legAngle, 0, 0) end

			-- ลำตัวเด้งขึ้นลงตามจังหวะกระโดด (วิ่งเหยาะเด้งเบากว่า)
			local bodyBounce = hopPhaseAbs * (trot and 0.12 or 0.35) * intensity
			if rootJoint and origC0[rootJoint] then
				rootJoint.C0 = origC0[rootJoint] * CFrame.new(0, bodyBounce, 0)
			end

			-- แขน: แกว่งเล็กน้อยเพื่อสมดุล
			local armSwing = math.sin(animTime) * 0.25 * intensity
			-- วิ่งเหยาะ: ขาหน้าแกว่งเท่าขาหลัง ทแยงกัน (หน้าซ้ายคู่หลังขวา)
			local leftArm, rightArm = armSwing, armSwing
			if trot then leftArm, rightArm = -legAngle, legAngle end
			if leftShoulder and origC0[leftShoulder] then
				leftShoulder.C0 = origC0[leftShoulder] * CFrame.Angles(leftArm, 0, 0)
			end
			if rightShoulder and origC0[rightShoulder] then
				rightShoulder.C0 = origC0[rightShoulder] * CFrame.Angles(rightArm, 0, 0)
			end

			-- หู: ไหวตามแรงกระแทกของแต่ละก้าว + ลู่หลังตอนวิ่ง + เอียงตอนเลี้ยว
			updateEars(dt, speed, bodyBounce)

			-- หัว: ส่ายเล็กน้อยตามจังหวะกระโดด
			local headBob = hopPhase * 0.12 * intensity
			if neck and origC0[neck] then
				neck.C0 = origC0[neck] * CFrame.Angles(headBob, 0, 0)
			end

			updateTail(dt, speed, hopPhase)
		else
			-- ยืน: หายใจเบาๆ + หูค่อยๆ ทรุดสู่ตำแหน่งปกติ
			animTime += dt * 2
			local breathe = math.sin(animTime) * 0.05

			if origC0[leftHip] then leftHip.C0 = origC0[leftHip] end
			if origC0[rightHip] then rightHip.C0 = origC0[rightHip] end
			if rootJoint and origC0[rootJoint] then rootJoint.C0 = origC0[rootJoint] end
			if kangaroo then
				-- ยืนแบบจิงโจ้: แขนหดหน้าอก ขยับตามลมหายใจ
				setArm(leftShoulder, breathe * 0.6)
				setArm(rightShoulder, breathe * 0.6)
			else
				if leftShoulder and origC0[leftShoulder] then leftShoulder.C0 = origC0[leftShoulder] end
				if rightShoulder and origC0[rightShoulder] then rightShoulder.C0 = origC0[rightShoulder] end
			end

			-- สะบัดหูข้างใดข้างหนึ่งเป็นพักๆ (สั่นเร็วแล้วเบาลงจนหยุด)
			twitchTimer -= dt
			if twitchTimer <= 0 then
				twitchTimer = rng:NextNumber(2.5, 6)
				twitchLeft = rng:NextInteger(1, 2) == 1
				twitchT = TWITCH_TIME
			end
			local twitch = 0
			if twitchT > 0 then
				twitchT = math.max(0, twitchT - dt)
				twitch = math.sin(twitchT / TWITCH_TIME * math.pi * 6) * (twitchT / TWITCH_TIME) * 0.45
			end

			-- เหลียวมองซ้ายหรือขวา แล้วค่อยๆ หันกลับ
			glanceTimer -= dt
			if glanceTimer <= 0 then
				glanceTimer = rng:NextNumber(4, 9)
				glanceDir = rng:NextInteger(1, 2) == 1 and -1 or 1
				glanceT = GLANCE_TIME
			end
			local glance = 0
			if glanceT > 0 then
				glanceT = math.max(0, glanceT - dt)
				glance = math.sin((1 - glanceT / GLANCE_TIME) * math.pi) * 0.42 * glanceDir
			end

			if neck and origC0[neck] then neck.C0 = origC0[neck] * CFrame.Angles(breathe, 0, glance) end
			updateEars(dt, speed, 0, breathe * 0.5 + (twitchLeft and twitch or 0), breathe * 0.5 + (twitchLeft and 0 or twitch))
			updateTail(dt, speed, 0)
		end
		applySit(dt, speed)
		applySleep(dt)
	end
end

-- ============ หางแบบพัด (จิ้งจอกเก้าหาง): ข้อต่อ Motor6D "TailFan" ที่โคนของแต่ละหาง ============
-- แกนหมุนเก็บใน Attribute ของข้อต่อ: AxisA = ส่ายซ้ายขวาในแนวพัด, AxisB = สะบัดหน้าหลัง
local function buildTailFan(petModel, ms)
	local tails = {}
	for _, motor in ipairs(petModel:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Name == "TailFan" then
			local axisA = motor:GetAttribute("AxisA")
			local axisB = motor:GetAttribute("AxisB")
			if typeof(axisA) == "Vector3" and typeof(axisB) == "Vector3" then
				table.insert(tails, {
					motor = motor,
					origC0 = motor.C0,
					axisA = axisA.Unit,
					axisB = axisB.Unit,
					index = motor:GetAttribute("FanIndex") or #tails + 1,
					freq = rng:NextNumber(0.9, 1.1),   -- แต่ละหางจังหวะต่างกันนิดหน่อย ไม่ขยับเป็นแผ่นเดียว
					angleA = 0, velA = 0, angleB = 0, velB = 0,
				})
			end
		end
	end
	if #tails == 0 then return nil end

	local STIFFNESS, DAMPING = 30, 7   -- สปริง: หางไล่ตามท่าแบบมีแรงเฉื่อย ดูนุ่มเหมือนขนฟู
	local t = 0
	local activity = 0
	return function(dt)
		-- เดินเร็ว = หางพลิ้วแรงและเร็วขึ้น, ยืนนิ่ง = พลิ้วช้าๆ เบาๆ
		local targetActivity = math.clamp((ms.speed or 0) / 14, 0, 1)
		activity += (targetActivity - activity) * math.clamp(dt * 3, 0, 1)
		t += dt * (1.6 + activity * 3.4)
		local ampA = 0.16 + activity * 0.22
		local ampB = 0.10 + activity * 0.20
		for _, tail in ipairs(tails) do
			-- คลื่นไล่จากหางซ้ายสุดไปขวาสุด (เลื่อนเฟสทีละหาง) + สะบัดหน้าหลังคนละจังหวะ
			local phase = tail.index * 0.7
			local targetA = math.sin(t * tail.freq + phase) * ampA
			local targetB = math.sin(t * tail.freq * 1.3 + phase * 1.6 + 1.2) * ampB
			tail.velA += ((targetA - tail.angleA) * STIFFNESS - tail.velA * DAMPING) * dt
			tail.angleA += tail.velA * dt
			tail.velB += ((targetB - tail.angleB) * STIFFNESS - tail.velB * DAMPING) * dt
			tail.angleB += tail.velB * dt
			tail.motor.C0 = tail.origC0
				* CFrame.fromAxisAngle(tail.axisA, tail.angleA)
				* CFrame.fromAxisAngle(tail.axisB, tail.angleB)
		end
	end
end

-- ============ สัตว์บินได้ (มังกรสุลต่าน / ผีน้อย): กระพือปีก (LeftWing/RightWing) + สะบัดหาง (Tail) ============
-- พ่นไฟยังสั่งจากเซิร์ฟเวอร์ (PetController.setupFireBreath) · การลอยขึ้นลง/เอียงตัวอยู่ในลูปหลักข้างล่าง
local function buildFly(petModel, ms)
	local motors = {}
	for _, d in ipairs(petModel:GetDescendants()) do
		if d:IsA("Motor6D") then motors[d.Name] = d end
	end
	local leftWing, rightWing, tail = motors.LeftWing, motors.RightWing, motors.Tail
	if not (leftWing or rightWing or tail) then return nil end
	local orig = {}
	for _, m in { leftWing, rightWing, tail } do
		if m then orig[m] = m.C0 end
	end
	local t = rng:NextNumber(0, 6)
	-- 2026-10-14 ผีน้อยใช้ข้อต่อเดียวกันเป็น "แขน" กระพือแบบปีกมังกรดูแปลก (ผู้ใช้แจ้ง) ตั้งค่าต่อตัวได้ด้วย Attribute บนโมเดล:
	--   FlapAmp (ความกว้างการโบก เรเดียน) · FlapSpeed (คูณความเร็ว) · FlapBias (ยกค้าง) · RightFlapScale (แขนขวาโบกน้อยกว่า เช่น มือที่ถือหุ่น) ไม่ตั้ง = แบบเดิมของมังกร
	local ampAttr, speedAttr = petModel:GetAttribute("FlapAmp"), petModel:GetAttribute("FlapSpeed")
	local biasAttr, rightScale = petModel:GetAttribute("FlapBias"), petModel:GetAttribute("RightFlapScale") or 1
	return function(dt)
		local k = math.clamp((ms.speed or 0) / 16, 0, 1)
		t += dt * (7 + 7 * k) * (speedAttr or 1)
		local flap = math.sin(t) * (ampAttr or (0.35 + 0.25 * k)) + (biasAttr or 0.15) -- ปีกยกขึ้นนิดๆ เป็นค่ากลาง
		if leftWing then leftWing.C0 = orig[leftWing] * CFrame.Angles(0, 0, flap) end
		if rightWing then rightWing.C0 = orig[rightWing] * CFrame.Angles(0, 0, -flap * rightScale) end
		if tail then tail.C0 = orig[tail] * CFrame.Angles(math.sin(t * 0.35) * 0.12, math.sin(t * 0.5) * 0.35, 0) end
	end
end

-- ============ ออร่าสีรุ้ง (สัตว์เทพ): ไฟ/ชิ้นส่วนที่ติด Attribute "Rainbow" ไล่สีวนครบทุก 4 วินาที ============
local function buildRainbow(petModel)
	local items = {}
	for _, d in ipairs(petModel:GetDescendants()) do
		if d:GetAttribute("Rainbow") and (d:IsA("Light") or d:IsA("BasePart")) then
			table.insert(items, d)
		end
	end
	if #items == 0 then return nil end
	local hue = rng:NextNumber(0, 1)
	return function(dt)
		hue = (hue + dt * 0.25) % 1
		local color = Color3.fromHSV(hue, 0.55, 1)
		for _, item in ipairs(items) do item.Color = color end
	end
end

-- ============ ติดตามสัตว์ที่อยู่บนเครื่องนี้ ============
local pets = {}        -- [model] = rec
local nextId = 0
local candidates = {}  -- [model] = เวลาที่เลิกรอ (โมเดลที่เพิ่งเข้ามา อาจยังไม่ได้ Attribute/ชิ้นส่วนครบ)

local function parseWork(value)
	if type(value) ~= "string" then return nil end
	local mode, start, length = string.match(value, "^(%a+);([%d%.]+);([%d%.]+)$")
	start, length = tonumber(start), tonumber(length)
	if not (mode and start and length) then return nil end
	return { mode = mode, start = start, len = length }
end

local function safeBuild(label, model, fn, ...)
	local ok, result = pcall(fn, ...)
	if ok then return result end
	warn("[PetAnimator] " .. label .. " " .. model.Name .. ": " .. tostring(result))
	return nil
end

-- คืน true = เริ่มดูแลตัวนี้แล้ว / false = ยังไม่พร้อม (ลองใหม่รอบหน้า)
local function tryAdd(model)
	if pets[model] then return true end
	if model:GetAttribute("PetId") == nil or model:GetAttribute("OwnerUserId") == nil then return false end
	local facing = model:GetAttribute("FacingOffset")
	if typeof(facing) ~= "CFrame" or not model.PrimaryPart then return false end

	local cf = model:GetPivot()
	nextId += 1
	local rec = {
		id = nextId,
		owner = model:GetAttribute("OwnerUserId"),
		facing = facing,
		facingInv = facing:Inverse(),
		flying = model:GetAttribute("AnimFlying") == true,
		ms = { speed = 0, turnRate = 0 },
		base = cf,
		snaps = { { t = os.clock(), cf = cf } }, -- ตำแหน่งจากเซิร์ฟเวอร์พร้อมเวลาที่มาถึง (เก่า -> ใหม่)
		interval = 0.1,
		lastWritten = nil, -- nil = ยังไม่เคยเขียน/เพิ่งกลับมาวาด: รับตำแหน่งปัจจุบันเป็นจุดเริ่ม
	}

	local bonesJson = model:GetAttribute("AnimBones")
	if type(bonesJson) == "string" then
		local ok, bones = pcall(HttpService.JSONDecode, HttpService, bonesJson)
		if ok and type(bones) == "table" then rec.walk = safeBuild("walk", model, buildWalk, model, bones, rec.ms) end
	end
	rec.fan = safeBuild("tailfan", model, buildTailFan, model, rec.ms)
	if rec.flying then rec.fly = safeBuild("fly", model, buildFly, model, rec.ms) end
	if model:GetAttribute("RainbowAura") then rec.rainbow = safeBuild("rainbow", model, buildRainbow, model) end

	rec.work = parseWork(model:GetAttribute("WorkAnim"))
	rec.workConn = model:GetAttributeChangedSignal("WorkAnim"):Connect(function()
		rec.work = parseWork(model:GetAttribute("WorkAnim"))
	end)

	pets[model] = rec
	return true
end

local function remove(model)
	candidates[model] = nil
	PetRenderState[model] = nil
	local rec = pets[model]
	if not rec then return end
	pets[model] = nil
	if rec.workConn then rec.workConn:Disconnect() end
end

local function watch(obj)
	if not obj:IsA("Model") then return end
	if not tryAdd(obj) then candidates[obj] = os.clock() + CANDIDATE_LIFETIME end
end

for _, obj in ipairs(workspace:GetChildren()) do watch(obj) end
workspace.ChildAdded:Connect(watch)
workspace.ChildRemoved:Connect(remove)

local function yawOf(cf)
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local candidateTimer = 0
local frameCount = 0

RunService.RenderStepped:Connect(function(dt)
	-- โมเดลที่ยังรอข้อมูล ลองใหม่ทุก 0.25 วิ
	candidateTimer -= dt
	if candidateTimer <= 0 then
		candidateTimer = 0.25
		local clock = os.clock()
		for model, deadline in pairs(candidates) do
			if model.Parent ~= workspace or clock > deadline or tryAdd(model) then candidates[model] = nil end
		end
	end

	local camera = workspace.CurrentCamera
	if not camera then return end
	local camPos = camera.CFrame.Position
	local now = os.clock()
	local serverNow = workspace:GetServerTimeNow()
	local levelName = player:GetAttribute(GraphicsConfig.ATTRIBUTE)
	local hideOthers = GraphicsConfig.Get(levelName).HideOtherPets == true
	local jointDistance = JOINT_DISTANCE[levelName] or 90
	local animDt = math.min(dt, 0.1) -- เฟรมค้างยาวๆ ไม่ให้ท่ากระโดดข้าม
	frameCount += 1

	for model, rec in pairs(pets) do
		if model.Parent ~= workspace then
			remove(model)
		elseif hideOthers and rec.owner ~= player.UserId then
			-- ระดับต่ำสุด: สัตว์ของคนอื่นถูกซ่อน (GraphicsQuality) ไม่ต้องคิดอะไรเลย ปล่อยให้อยู่ตามตำแหน่งจากเซิร์ฟเวอร์
			rec.lastWritten = nil
			PetRenderState[model] = nil
		else
			-- 1) ตำแหน่ง: ค่าที่อ่านได้ไม่ตรงกับที่เราเขียนไว้ = เซิร์ฟเวอร์เพิ่งส่งตำแหน่งใหม่มา
			local actual = model:GetPivot()
			local snaps = rec.snaps
			if rec.lastWritten == nil or actual ~= rec.lastWritten then
				local newest = snaps[#snaps]
				if rec.lastWritten == nil or (actual.Position - newest.cf.Position).Magnitude > SNAP_DISTANCE then
					-- เพิ่งเริ่มวาด / วาร์ป: ย้ายทันที
					table.clear(snaps)
					snaps[1] = { t = now, cf = actual }
					rec.base = actual
					rec.ms.speed, rec.ms.turnRate = 0, 0
				else
					local gap = now - newest.t
					if gap < 0.3 then
						rec.interval += (math.clamp(gap, 0.05, 0.25) - rec.interval) * 0.2
					else
						-- เริ่มเดินหลังยืนนิ่ง: ถือว่ายังอยู่ที่เดิมจนถึงเมื่อ 1 ช่วงส่งก่อน ไม่งั้นก้าวแรกจะกระโดด
						table.insert(snaps, { t = now - rec.interval, cf = newest.cf })
					end
					table.insert(snaps, { t = now, cf = actual })
				end
			end
			-- วาด ณ เวลา (ตอนนี้ - หน่วง) : ไล่ระหว่างตำแหน่ง 2 ครั้งที่คร่อมเวลานั้น
			local renderT = now - math.max(rec.interval * RENDER_DELAY_FACTOR, MIN_RENDER_DELAY)
			while #snaps >= 2 and snaps[2].t <= renderT do table.remove(snaps, 1) end
			local base
			local s1, s2 = snaps[1], snaps[2]
			if s2 and renderT > s1.t then
				base = s1.cf:Lerp(s2.cf, math.clamp((renderT - s1.t) / math.max(s2.t - s1.t, 1e-3), 0, 1))
			else
				base = s1.cf
			end

			-- ความเร็วเดิน/ความเร็วเลี้ยวจากตำแหน่งที่วาดจริง (กรองให้นุ่ม) ให้ท่าเดิน หู หาง ใช้
			local ms = rec.ms
			local prev = rec.base
			local step = base.Position - prev.Position
			local rawSpeed = math.sqrt(step.X * step.X + step.Z * step.Z) / math.max(dt, 1e-3)
			ms.speed += (math.min(rawSpeed, 60) - ms.speed) * math.clamp(dt * 10, 0, 1)
			local yawDiff = yawOf(base) - yawOf(prev)
			yawDiff = math.atan2(math.sin(yawDiff), math.cos(yawDiff))
			ms.turnRate += (yawDiff / math.max(dt, 1e-3) - ms.turnRate) * math.clamp(dt * 8, 0, 1)
			rec.base = base

			-- 2) ท่าทั้งตัว: ก้มจิก/เด้งตัวตอนทำงาน (เวลาอิงนาฬิกาเซิร์ฟเวอร์) + ลอยขึ้นลงของสัตว์บิน
			local bob = nil
			local work = rec.work
			if work then
				local elapsed = serverNow - work.start
				if elapsed >= work.len then
					rec.work = nil
				elseif elapsed >= 0 then
					local envelope = math.sin(math.clamp(elapsed / math.max(work.len, 0.01), 0, 1) * math.pi) -- 0 → 1 → 0 นุ่มๆ
					if work.mode == "hop" then
						-- เด้งตัวเบาๆ พร้อมเงยหน้ามอง (หยิบเมล็ดขึ้นมา / รับผลผลิตเข้ากระเป๋า)
						bob = CFrame.new(0, 0.28 * envelope, 0) * CFrame.Angles(0.22 * envelope, 0, 0)
					else
						local peck = 0.5 + 0.5 * math.sin(elapsed * 10) -- จังหวะจิก
						bob = CFrame.new(0, -0.15 * envelope * peck, 0) * CFrame.Angles(-0.45 * envelope * (0.35 + 0.65 * peck), 0, 0)
					end
				end
			end
			if rec.flying then
				-- ลอยขึ้นลงเบาๆ + ก้มหัวลงตอนบินเร็ว + เอียงตัวตอนเลี้ยว
				local hover = CFrame.new(0, math.sin(now * 2.2) * 0.18, 0)
					* CFrame.Angles(-math.clamp(ms.speed / FOLLOW_SPEED, 0, 1) * 0.2, 0, math.clamp(ms.turnRate * 0.1, -0.35, 0.35))
				bob = bob and hover * bob or hover
			end

			-- base = ตำแหน่ง * ทิศ * FacingOffset จึงแทรกท่าไว้ก่อน FacingOffset เหมือนที่เซิร์ฟเวอร์เคยทำ
			local render = bob and (base * rec.facingInv * bob * rec.facing) or base
			-- ยืนนิ่งและไม่มีท่า = ตำแหน่งเดิม ไม่ต้องย้ายโมเดลซ้ำ (สัตว์ส่วนใหญ่ยืนนิ่งเกือบตลอด)
			if rec.lastWritten == nil or actual ~= rec.lastWritten or render ~= rec.lastRender then
				model:PivotTo(render)
				rec.lastWritten = model:GetPivot()
				rec.lastRender = render
			end
			PetRenderState[model] = render

			-- 3) ข้อต่อ: เฉพาะตัวที่อยู่ใกล้กล้อง
			local camDistance = (base.Position - camPos).Magnitude
			if camDistance <= jointDistance then
				local jointDt = animDt
				if camDistance > FULL_RATE_DISTANCE then
					-- ไกล: เฟรมเว้นเฟรม (สลับกันคนละครึ่งตาม id) และเดินเวลาท่าทีละ 2 เฟรม
					jointDt = (frameCount + rec.id) % 2 == 0 and math.min(animDt * 2, 0.1) or nil
				end
				if jointDt then
					if rec.walk then rec.walk(jointDt) end
					if rec.fan then rec.fan(jointDt) end
					if rec.fly then rec.fly(jointDt) end
					if rec.rainbow then rec.rainbow(jointDt) end
				end
			end
		end
	end
end)
