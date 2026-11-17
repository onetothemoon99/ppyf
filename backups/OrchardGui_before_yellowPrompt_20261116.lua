-- Backup 2026-11-16 before yellowPrompt (partial: the change is an INSERT only; full script is ~109k chars, 2138 lines)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.OrchardGui (LocalScript)
-- Restore: delete the block that starts with
--   "-- ============ ปุ่ม E หน้าตาเอง: มะม่วงเหลือง (2026-11-16) ============"
-- and ends with the line "-- ============ (จบ ปุ่ม E หน้าตาเอง) ============".
-- It sits between these unchanged lines (line ~228-230 before the change):

for _, b in pairs(plantButtons) do iconify(b) end

-- ============ ข้อมูล + วาด ============
