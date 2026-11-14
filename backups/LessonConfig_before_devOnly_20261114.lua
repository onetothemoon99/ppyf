-- BACKUP 2026-11-14 — ReplicatedStorage.LessonConfig (ModuleScript) ก่อนทำระบบสอนเล่นเป็น DEV_ONLY (ซ่อนบนเซิร์ฟจริง)
-- วิธีคืน: ใน Studio เปิด ReplicatedStorage.LessonConfig แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 2 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- LessonConfig (2026-11-13 ช่วงที่ 2): รางวัลบทเรียนของครูฟาร์ม ใช้ร่วมกันทั้งเซิร์ฟเวอร์ (ServerScriptService.LessonService) และหน้าจอ (StarterPlayerScripts.LessonNpcGui)
-- แก้จำนวนเหรียญที่นี่ที่เดียว · ENABLED = false = ไม่ตรวจ ไม่จ่าย และหน้าต่างบทเรียนไม่แสดงรางวัล (ยังเป็นหน้าต่างข้อมูลเหมือนช่วงที่ 1)
-- เพิ่มบทเรียนใหม่: เติม id ใน Order + Rewards แล้วเพิ่มวิธีตรวจใน LessonService (ตาราง CHECKS) และการ์ดใน LessonNpcGui (ตาราง LESSONS)

local LessonConfig = {}

LessonConfig.ENABLED = true

-- ลำดับบทเรียน (id ต้องตรงกับ LessonNpcGui.LESSONS)
LessonConfig.Order = { "basic", "fish", "chicken" }

-- รางวัลเหรียญ ครั้งเดียวต่อบัญชีต่อบทเรียน (ผู้เล่นกดรับที่ครูฟาร์มหลังเซิร์ฟเวอร์ยืนยันว่าทำแล้ว)
-- basic   = ปลูก เก็บ แล้วขายผลผลิตที่ร้านเมล็ดสำเร็จ 1 ครั้ง
-- fish    = มีปลาในกระเป๋า (ตกได้อย่างน้อย 1 ตัว)
-- chicken = มีไก่ในฟาร์มไก่อย่างน้อย 1 ตัว
LessonConfig.Rewards = {
	basic = 10000,
	fish = 10000,
	chicken = 10000,
}

-- สถานะต่อบทเรียน ที่เซิร์ฟเวอร์ตั้งเป็น Attribute "Lesson_<id>" บนผู้เล่น
LessonConfig.TODO = 0 -- ยังไม่ได้ทำ
LessonConfig.READY = 1 -- ทำแล้ว รอกดรับรางวัลที่ครูฟาร์ม
LessonConfig.CLAIMED = 2 -- รับรางวัลแล้ว

return LessonConfig
