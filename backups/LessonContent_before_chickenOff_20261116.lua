-- Backup (เฉพาะท่อนที่แก้) ก่อนปิดบท "เลี้ยงไก่" (สอนซื้อไก่) 2026-11-16
-- เปิดบทคืน (ง่ายสุด): ลบ chicken ออกจาก LessonConfig.Off ใน ReplicatedStorage.LessonConfig — ไม่ต้องแตะไฟล์นี้
-- ถอดการแก้ทั้งหมด: แทนท่อนข้างล่างกลับ และลบบล็อก `local LESSON_OFF = {} ... end` ใต้ `local LessonContent = {}`

-- [1] game.ReplicatedStorage.LessonContent (เดิม)
function LessonContent.IsAvailable(lesson)
	return lesson.available == nil or lesson.available() == true
end

-- [2] game.StarterPlayer.StarterPlayerScripts.LessonNpcGui ใน layout (เดิมบรรทัด 388)
		local show = c.lesson.available == nil or c.lesson.available() == true
