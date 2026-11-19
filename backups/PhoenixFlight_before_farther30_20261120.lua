-- BACKUP of game.ReplicatedStorage.PhoenixFlight (Studio Source, byte-exact, len 7634 hash 1032356904)
-- Restore: paste everything below this header into game.ReplicatedStorage.PhoenixFlight.Source in Studio.
-- PhoenixFlight: ท่าบินของนกฟีนิกซ์ (เบ็ดฟีนิกซ์) ใช้ร่วมกันระหว่าง SunBeeAuraFx (คนถือเบ็ด) กับ FishingOtterFx (นากหน้าตู้) 2026-11-20
-- ผู้ใช้สั่ง: ไม่ต้องบินวนตลอด (มึนหัว) -> เกาะไหล่ขวาเป็นส่วนใหญ่ (ปีกหุบ ขยับเบาๆ) ทุก 15-25 วิ (สุ่ม) บินออก 1 รอบ 4.5-6 วิ แล้วกลับมาเกาะ
--   ท่าบินสุ่มไม่ซ้ำรอบก่อน: โฉบขึ้นฟ้า / เลข 8 ด้านหลัง / วนกว้างรอบเดียว / เกลียวขึ้น · ออกตัว-ลงจอดค่อยๆ เร่ง/ชะลอ · ไม่บินตัดหน้ากล้อง
-- 2026-11-20 (ต่อมา) ผู้ใช้สั่ง "เกาะ 20% บิน 80%": บินรอบละ 6-9 วิ พักเกาะไหล่ 1.6-2.2 วิ (เดิม บิน 4.5-6 พัก 15-25 = เกาะ ~80%) ค่าอยู่ที่ FLY_TIME / PERCH_TIME
-- พิกัดท่าบิน = เทียบตัวคน (x ขวา, y บน, z หลัง) หน่วย stud คูณ scale

local Flight = {}
local rng = Random.new()
local FLY_TIME = { 6, 9 }         -- บินรอบละกี่วิ (สุ่มในช่วง)
local PERCH_TIME = { 1.6, 2.2 }   -- พักเกาะไหล่กี่วิก่อนบินรอบถัดไป
local FIRST_FLY = { 1, 2 }        -- ถือเบ็ดแล้วบินรอบแรกหลังกี่วิ
-- 2026-11-20 ผู้ใช้สั่ง: ไม่เกาะตัวละครแล้ว ช่วงพัก = บินลอยนิ่งๆ หลังไหล่ขวา (จุดพัก perch + HOVER_OFFSET) ปีกกางกระพือช้า ขึ้นลง + ส่ายเบาๆ
local HOVER_OFFSET = Vector3.new(0.85, 0.85, 1.05) -- คนถือเบ็ด: ไหล่ (1.05, 1.55, 0.25) -> ลอยที่ (1.9, 2.4, 1.3) = สูงกว่าไหล่นิด เยื้องไปด้านหลัง

local function smooth(e0, e1, x)
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

local PATTERNS = {
	function(u) -- โฉบขึ้นฟ้าแล้วร่อนลง
		local s = math.sin(math.pi * u)
		return Vector3.new(1.0 + 1.6 * s, 1.5 + 4.5 * s, 0.3 + 2.4 * s)
	end,
	function(u) -- เลข 8 ด้านหลัง
		local th = 2 * math.pi * u
		return Vector3.new(3.0 * math.sin(th), 2.3 + 0.5 * math.sin(2 * th), 2.4 + 1.3 * math.sin(2 * th))
	end,
	function(u) -- วนกว้างรอบเดียว (ออกด้านขวา ไปด้านหลัง)
		local th = 2 * math.pi * u
		return Vector3.new(3.4 * math.sin(th) + 1.0 * (1 - u), 2.0 + 0.7 * math.sin(th), 1.9 * (1 - math.cos(th)) + 0.3)
	end,
	function(u) -- บินขึ้นเป็นเกลียว
		local th = 4 * math.pi * u
		return Vector3.new(2.4 * math.sin(th), 1.5 + 4.0 * math.sin(math.pi * u), 1.6 + 1.4 * (1 - math.cos(th)) * 0.5)
	end,
	function(u) -- 2026-11-20 ผู้ใช้สั่ง: วนรอบตัว 1 รอบเหมือนตอนแรก (r 3.4 สูงระดับไหล่ คลื่นเบาๆ) ด้านหน้าตัวขยายวงออกอีก 0.7 ไม่บังหน้า
		local th = 2 * math.pi * u
		local r = 3.4 + 0.7 * math.max(0, -math.sin(th)) -- sin < 0 = ครึ่งด้านหน้า (z ติดลบ)
		return Vector3.new(r * math.cos(th), 1.4 + 0.35 * math.sin(2 * th), r * math.sin(th))
	end,
}
-- เวลาบินเฉพาะท่า (ไม่มี = FLY_TIME) / ท่าที่บินผ่านหน้ากล้องได้ (ไม่ดันหลบกล้อง)
local PATTERN_TIME = { [5] = { 4.8, 5.4 } } -- วนรอบตัว: ช่วงกลางเร็วพอๆ ตอนแรก (~4 วิต่อรอบ) รวมตอนออกตัว/ลงจอด
local PASS_CAMERA = { [5] = true }

-- b = ตัวนก (เก็บสถานะไว้ใน b.flight) · rootPos / look = ตำแหน่งกับทิศหน้าของเจ้าของ · perch = จุดเกาะ (พิกัดเทียบตัว)
-- คืน CFrame ของนก + มุมปีก (flap, ค่าติดลบ = ปีกหุบลง)
function Flight.Step(b, rootPos, look, camPos, now, perch, scale)
	scale = scale or 1
	local st = b.flight
	if not st then
		st = { mode = "perch", nextFly = now + rng:NextNumber(FIRST_FLY[1], FIRST_FLY[2]), last = 0 }
		b.flight = st
	end
	if st.mode == "perch" and now >= st.nextFly then
		st.mode, st.start, st.dur = "fly", now, rng:NextNumber(FLY_TIME[1], FLY_TIME[2])
		local pick = rng:NextInteger(1, #PATTERNS - 1)
		if pick >= st.last then pick += 1 end -- ไม่ซ้ำท่ารอบก่อน
		st.pat, st.last = pick, pick
		local pt = PATTERN_TIME[pick]
		if pt then st.dur = rng:NextNumber(pt[1], pt[2]) end
	elseif st.mode == "fly" and now >= st.start + st.dur then
		st.mode, st.nextFly = "perch", now + rng:NextNumber(PERCH_TIME[1], PERCH_TIME[2])
	end
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = flat.Magnitude > 1e-3 and flat.Unit or Vector3.new(0, 0, -1)
	local frame = CFrame.lookAt(rootPos, rootPos + flat) -- z บวก = ด้านหลังตัว
	local hover = Vector3.new(0.12 * math.sin(now * 1.1), 0.15 * math.sin(now * 1.8), 0.08 * math.sin(now * 0.9)) -- ลอยขึ้นลง/ส่ายเบาๆ
	local perchW = frame:PointToWorldSpace((perch + HOVER_OFFSET + hover) * scale)
	local blend, pos = 0, perchW
	if st.mode == "fly" then
		local u = (now - st.start) / st.dur
		blend = smooth(0, 0.18, u) * (1 - smooth(0.82, 1, u))
		local flyW = frame:PointToWorldSpace(PATTERNS[st.pat](u) * scale)
		pos = perchW:Lerp(flyW, blend)
		-- ไม่บินตัดหน้ากล้อง: ส่วนที่เลยเข้าไปฝั่งกล้อง (เกิน 0.4 stud) ดันกลับไปด้านข้าง/หลัง
		if camPos and not PASS_CAMERA[st.pat] then
			local c = (camPos - rootPos) * Vector3.new(1, 0, 1)
			if c.Magnitude > 1e-3 then
				c = c.Unit
				local k = ((pos - rootPos) * Vector3.new(1, 0, 1)):Dot(c)
				if k > 0.4 then pos -= c * (k - 0.4) * blend end -- ค่อยๆ ดันตาม blend (จุดลอยอยู่หลังไหล่ = ฝั่งกล้อง ไม่งั้นกระตุกตอนออกตัว)
			end
		end
	end
	local dir = st.prev and (pos - st.prev) or flat
	if dir.Magnitude < 1e-3 then dir = st.lastDir or flat end
	st.lastDir, st.prev = dir, pos
	local face = (flat * (1 - blend) + dir.Unit * blend)
	if face.Magnitude < 1e-3 then face = flat end
	local cf = CFrame.lookAt(pos, pos + face.Unit)
	local perchFlap = math.sin(now * 5) * 0.35 + 0.15 -- ลอยนิ่ง: กางปีกกระพือช้า (เดิม -0.85 = ปีกหุบตอนเกาะ)
	local flyFlap = math.sin(now * 11) * 0.6 + 0.1
	local w = math.clamp(blend * 2, 0, 1)
	return cf, perchFlap * (1 - w) + flyFlap * w
end

return Flight
