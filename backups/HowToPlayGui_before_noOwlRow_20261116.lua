-- Backup (เฉพาะบรรทัดที่แก้) ของ game.StarterPlayer.StarterPlayerScripts.HowToPlayGui ก่อนเอาแถว "หุ่นนกฮูก" ออกจากแผง "?" 2026-11-16
-- ย้อนกลับ: ใส่บรรทัดนี้คืนใต้ลูป `for _, lesson in ipairs(LessonContent.LESSONS) do ... end` ในหัวข้อ "แถว"

table.insert(ROWS, { kind = "teacher", data = LessonContent.TEACHER })
