-- BACKUP 2026-11-15 ก่อนเพิ่ม EXP ในรางวัลบทเรียน
-- Studio path: game.ReplicatedStorage.LessonConfig (ModuleScript) — ทั้งสคริปต์
-- คืนค่า: วางโค้ดด้านล่าง (ใต้บรรทัด ===) ทับทั้งหมด
-- ========================================================================
-- LessonConfig (2026-11-13 ช่วงที่ 2): รางวัลบทเรียนของครูฟาร์ม ใช้ร่วมกันทั้งเซิร์ฟเวอร์ (ServerScriptService.LessonService) และหน้าจอ (StarterPlayerScripts.LessonNpcGui)
-- แก้จำนวนเหรียญที่นี่ที่เดียว · ENABLED = false = ปิดทั้งระบบสอนเล่น (2026-11-14 เดิมปิดแค่รางวัล) ดู DEV_ONLY ด้านล่าง
-- เพิ่มบทเรียนใหม่: เติม id ใน Order + Rewards แล้วเพิ่มวิธีตรวจใน LessonService (ตาราง CHECKS) และการ์ดใน LessonNpcGui (ตาราง LESSONS)

local LessonConfig = {}

-- DEV_ONLY = true: เปิดเฉพาะใน Studio เซิร์ฟจริงซ่อนทั้งระบบสอนเล่น (ผู้ใช้สั่ง 2026-11-14 "ระบบนี้ปิดไว้ แสดงแค่ใน dev" เลือก "ทั้งระบบสอนเล่น")
--   ปิด = ไม่มีหุ่นนกฮูก (LessonService ลบ Workspace.GuideNPC ตอนเกมรัน) · ไม่ตรวจ/ไม่จ่ายรางวัล · ไม่มีหน้าต่างบทเรียน (LessonNpcGui)
--   ไม่มีปุ่ม "?" (HowToPlayGui) · ไม่มีลูกศรนำทางผู้เล่นใหม่ (NewPlayerGuide) · เปิดให้ผู้เล่นจริง = DEV_ONLY = false
LessonConfig.DEV_ONLY = true
LessonConfig.ENABLED = (not LessonConfig.DEV_ONLY) or game:GetService("RunService"):IsStudio()

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
