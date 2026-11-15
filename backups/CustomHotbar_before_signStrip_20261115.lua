-- BACKUP 2026-11-15 ก่อนเพิ่มหน้าตาป้ายเขียนข้อความ (IsSign) ในช่อง hotbar
-- Studio path: game.StarterPlayer.StarterPlayerScripts.CustomHotbar (LocalScript) — สำรองเฉพาะท่อนที่แก้
-- การแก้ครั้งนี้ "เพิ่ม" อย่างเดียว ไม่ได้ลบโค้ดเดิม คืนค่า = ลบ 2 จุดที่มีคอมเมนต์ "ป้ายเขียนข้อความ 2026-11-15" ออก
--   (1) บรรทัด `if tool:GetAttribute("IsSign") then return "📝" end` ใน getToolIconText
--   (2) สาย `elseif tool:GetAttribute("IsSign") then ...` ใน refreshHotbar (ก่อนสาย IsOrchardMat)
-- ท่อนเดิมรอบจุดที่แทรก:
-- ========================================================================
	if tool:GetAttribute("IsHeldChicken") then return "🐔" end -- ไก่ที่อุ้มอยู่ 2026-10-21
	if tool:GetAttribute("IsFurniture") then

			elseif tool:GetAttribute("IsOrchardMat") then
				-- ท่อนไม้ / ปุ๋ยไม้ผล (สวนผลไม้) 2026-11-02: แถบสีไม้ / เขียว + จำนวน
