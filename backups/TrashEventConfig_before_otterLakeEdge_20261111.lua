-- BACKUP 2026-11-11: ReplicatedStorage.TrashEventConfig (ModuleScript) ก่อนย้ายน้องนากไปขอบทะเลสาบ
-- คืนค่า: วาง Source ข้างล่างทั้งหมดกลับเข้า ReplicatedStorage.TrashEventConfig (เปลี่ยนแค่บรรทัด NPC_POS)
-- TrashEventConfig: อีเวนต์ "ทะเลสาบวิกฤต! ช่วยน้องนากเก็บขยะ" (สร้าง 2026-10-12)
-- ขยะลอยเต็มทะเลสาบ (ทะเลสาบใหม่ขวาบน ตั้งแต่ 2026-11-08 เดิมทะเลสาบหมอกเช้าบนเขา) น้องนากเก็บไม่ไหว ชวนผู้เล่นมาตกขยะ
--   ระหว่างอีเวนต์ ตกปลาในทะเลสาบนี้: ปลากินเร็วขึ้น BITE_BONUS · โอกาสได้ขยะ +JUNK_BONUS (บวกตรงๆ เท่ากันทุกเบ็ด) · ขยะมีค่า (เศษเพชร/ทับทิม) ออกบ่อยขึ้น x VALUABLE_MULT
--   ภารกิจส่วนตัว (นับสะสมทั้งวัน รีเซ็ตเที่ยงคืนเวลาไทย): เก็บขยะครบตาม MILESTONES ได้เหรียญ
--   เป้ารวมของเซิร์ฟ: ขยะลอยน้ำค่อยๆ หาย เก็บครบ = ออร่าเปลี่ยนเป็นฟ้าใส (ไม่แจกเหรียญยกเซิร์ฟแล้ว ดู CLEAR_BONUS) โบนัสขยะยังอยู่จนหมดเวลา
-- เวลา: ทุกเซิร์ฟเกิดพร้อมกันตามเวลาไทย (TIMES) ครั้งละ DURATION วินาที (ตอนนี้ 30 นาที)
-- ใช้ทั้งเซิร์ฟเวอร์ (TrashEventService, FishingSystem) และหน้าจอ (TrashEventGui)
-- ทดสอบใน Studio: workspace Attribute "DevTrashEvent" = true (เริ่มทันที) / false (ปิด ไม่ทำตามเวลา) / ลบ = ทำตามเวลา

local TrashEventConfig = {}

TrashEventConfig.ENABLED = true -- false = ปิดอีเวนต์ทั้งหมด (ไม่เกิดตามเวลา)

TrashEventConfig.TZ_OFFSET = 7 * 3600 -- เวลาไทย (UTC+7)
-- ชั่วโมง, นาที (เวลาไทย) เพิ่มรอบใหม่ให้ต่อท้ายเสมอ (ลำดับในตารางเป็นคีย์โบนัสเก็บหมดของรอบนั้น) · รอบ 00:00 เพิ่ม 2026-10-12
-- รอบ 00:00 เริ่มพร้อมวันใหม่พอดี ภารกิจรายวันจึงเริ่มนับ 0 ตั้งแต่ต้นรอบ
-- 2026-10-13 ผู้ใช้แก้: รอบแรกเริ่ม 12:00 (เดิมตั้งไว้ 12:30)
TrashEventConfig.TIMES = { { 12, 0 }, { 18, 0 }, { 21, 0 }, { 0, 0 } }
TrashEventConfig.DURATION = 30 * 60 -- 2026-10-13 ผู้ใช้ขอ: รอบละ 30 นาที (เดิม 15)

-- พื้นที่: ทะเลสาบหมอกเช้า (ค่าเดียวกับ HILL_LAKE ใน FishingSystem) ผิวน้ำ y 4
-- 2026-11-08 เกาะสร้างใหม่ ×2: ทะเลสาบวงรี กลาง (276, 440) รัศมี x 96 z 182 ผิวน้ำ y 4 (ค่าเดียวกับ HILL_LAKE ใน FishingSystem) · ก่อนหน้า (282, 405) r 80 y 8, เดิม (468, -201)
-- 2026-11-08 ย้อนเกาะเป็น 1:1: ทะเลสาบกลาง (138, 220) รัศมี 48×91 (เกาะ ×2 เดิม (276, 440) 96×182)
-- 2026-11-08 ปรับเกาะตามภาพ: ทะเลสาบกลาง (160, 180) รัศมี 61×101 (ก่อนหน้า (138, 220) 48×91)
TrashEventConfig.CENTER = Vector2.new(290, 370) -- 2026-11-08 เกาะ v5: ทะเลสาบใหม่ · ก่อนหน้า (160, 180) 61×101
TrashEventConfig.RX, TrashEventConfig.RZ = 103, 153
TrashEventConfig.RADIUS = 153 -- วงสุ่มขยะลอยน้ำ (TrashEventService เช็กว่าเป็นน้ำจริงอีกที)
TrashEventConfig.WATER_Y = 4
TrashEventConfig.WARP_ID = "mistlake" -- จุดวาปใน WarpConfig

TrashEventConfig.JUNK_BONUS = 0.30   -- บวกเข้าโอกาสได้ขยะตรงๆ (ไม้ไผ่ 12% -> 42%, ผึ้งน้อย 1.5% -> 31.5%)
TrashEventConfig.VALUABLE_MULT = 1.5 -- น้ำหนักสุ่มของขยะมีค่า (Valuable) คูณเท่านี้
-- ความเร็วตกปลาในบริเวณอีเวนต์ +10% (2026-10-12 ผู้ใช้ขอ: เฉพาะทะเลสาบที่มีอีเวนต์ ระหว่างรอบเท่านั้น)
-- BITE_MULT = เวลารอปลากินคูณเท่านี้ (แบบเดียวกับฝน RAIN_BITE_MULT 0.83 = +20%) · ทบกับฝน/เหยื่อได้
TrashEventConfig.BITE_BONUS = 0.10
TrashEventConfig.BITE_MULT = 1 / (1 + TrashEventConfig.BITE_BONUS)

-- ภารกิจส่วนตัว (สะสมทั้งวัน) Id ห้ามเปลี่ยน (ใช้เป็นคีย์บันทึกว่ารับแล้ว)
TrashEventConfig.MILESTONES = {
	{ Id = "m10", Count = 10, Coins = 2000 },
	{ Id = "m25", Count = 25, Coins = 5000 },
	{ Id = "m50", Count = 50, Coins = 12000 },
}

-- เป้ารวมของเซิร์ฟ = GOAL_PER_PLAYER x จำนวนผู้เล่นสูงสุดระหว่างรอบ (อย่างน้อย GOAL_MIN)
-- 2026-10-13 ผู้ใช้ขอ "ไม่จำกัดขยะ": GOAL_ENABLED = false = ไม่มีเป้ารวม ขยะลอยน้ำอยู่ตลอดรอบ ทะเลสาบไม่ "สะอาด" ก่อนหมดเวลา
--   true = แบบเดิม (ขยะลอยน้ำค่อยๆ หาย เก็บครบเป้า = ออร่าเปลี่ยนเป็นสีฟ้า)
TrashEventConfig.GOAL_ENABLED = false
TrashEventConfig.GOAL_PER_PLAYER = 20
TrashEventConfig.GOAL_MIN = 20
-- เหรียญให้ทุกคนที่ช่วยเก็บเมื่อทั้งเซิร์ฟเก็บครบเป้า (รอบละครั้ง) · 0 = ไม่แจก
-- 2026-10-12 ผู้ใช้ขอ: ไม่แจกยกเซิร์ฟแล้ว (เดิม 3000) ขยะลอยน้ำหาย/ออร่าเปลี่ยนสีตอนเก็บครบยังทำงานเหมือนเดิม
TrashEventConfig.CLEAR_BONUS = 0

TrashEventConfig.FLOAT_COUNT = 40 -- ขยะลอยน้ำ
-- น้องนากเก็บขยะ (ยืนบนแท่นไม้ข้างจุดวาปทะเลสาบ) หันหน้าไปทาง NPC_LOOK
TrashEventConfig.NPC_POS = Vector3.new(158, 7.8, 298) -- 2026-11-08 เกาะ v5: หญ้านอกรั้วทะเลสาบฝั่งตะวันตกเฉียงใต้ ใกล้ประตูรั้ว (182, 370) · ก่อนหน้า (84, 7.8, 206) -- 2026-11-08 ปรับเกาะตามภาพ: นอกรั้วทะเลสาบฝั่งตะวันตก ข้างท่าบ่อขอพร/จุดวาปบนท่า (112, 190) · ก่อนหน้า (82, 7.8, 232) -- 2026-11-08 เกาะ 1:1: ฝั่งตะวันตกทะเลสาบข้างจุดวาป (86, 220) · ×2 เดิม -- 2026-11-08 เกาะ ×2: ฝั่งตะวันตกทะเลสาบข้างจุดวาป (182, 440) · ก่อนหน้า (214, 15.6, 418) เดิม (479, 6.3, -134.5)
TrashEventConfig.NPC_LOOK = Vector3.new(290, 7.8, 370)

function TrashEventConfig.IsActive()
	return workspace:GetAttribute("TrashEventActive") == true
end

function TrashEventConfig.InArea(pos)
	local dx, dz = pos.X - TrashEventConfig.CENTER.X, pos.Z - TrashEventConfig.CENTER.Y
	return (dx / TrashEventConfig.RX) ^ 2 + (dz / TrashEventConfig.RZ) ^ 2 <= 1
end

-- วันที่ตามเวลาไทย "YYYY-MM-DD" (คีย์ภารกิจรายวัน)
function TrashEventConfig.DayKey(now)
	return os.date("!%Y-%m-%d", (now or os.time()) + TrashEventConfig.TZ_OFFSET)
end

-- ตอนนี้อยู่ในรอบไหน: คืน ลำดับรอบ (1..#TIMES), เวลาจบ (unix) / nil = ไม่มีรอบ
function TrashEventConfig.Schedule(now)
	now = now or os.time()
	local sec = (now + TrashEventConfig.TZ_OFFSET) % 86400
	for i, hm in ipairs(TrashEventConfig.TIMES) do
		local s = hm[1] * 3600 + hm[2] * 60
		if sec >= s and sec < s + TrashEventConfig.DURATION then
			return i, now - sec + s + TrashEventConfig.DURATION
		end
	end
	return nil
end

-- อีกกี่วินาทีถึงรอบถัดไป (หน้าจอใช้บอกเวลา)
function TrashEventConfig.NextStartIn(now)
	now = now or os.time()
	local sec = (now + TrashEventConfig.TZ_OFFSET) % 86400
	local best
	for _, hm in ipairs(TrashEventConfig.TIMES) do
		local s = hm[1] * 3600 + hm[2] * 60
		local d = s - sec
		if d <= 0 then d += 86400 end
		if not best or d < best then best = d end
	end
	return best
end

return TrashEventConfig
