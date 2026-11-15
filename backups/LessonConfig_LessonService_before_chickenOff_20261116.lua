-- Backup (เฉพาะท่อนที่แก้) ก่อนปิดบท "เลี้ยงไก่" (สอนซื้อไก่) 2026-11-16
-- ย้อนกลับ/เปิดบทคืน: ง่ายสุด = ลบ chicken ออกจาก LessonConfig.Off (หรือตั้ง LessonConfig.Off = {})
-- ถอดทั้งหมด: แทนท่อนข้างล่างกลับในแต่ละสคริปต์ และลบ LessonConfig.Off

-- [1] game.ReplicatedStorage.LessonConfig (เดิมบรรทัด 14)
LessonConfig.Order = { "basic", "fish", "pet", "chicken" } -- pet = บทสัตว์เลี้ยง 2026-11-15 (ต่อจากตกปลา)

-- [2] game.ServerScriptService.LessonService ในลูปตรวจ (เดิมบรรทัด 323)
					if Config.Rewards[id] and not st.data.ready[id] and not st.data.claimed[id] then
