-- Backup (เฉพาะท่อนที่แก้) ก่อนแก้ "บทสอนขั้นซื้อ: เมล็ดที่ซื้อลงช่อง 1/2 เสมอ" 2026-11-16
-- ย้อนกลับ: แทนแต่ละท่อนด้วยของเดิมข้างล่าง แล้วลบ guideSeedCounts / บล็อก "บทสอนขั้นซื้อเมล็ด" ใน AutoAssignNew
--   และลบ seedInHotbar / ข้อความกระเป๋าในขั้น plant ของ NewPlayerGuide

-- [1] game.StarterPlayer.StarterPlayerScripts.HotbarState ต้น AutoAssignNew (เดิมบรรทัด 268–270)
function HotbarState.AutoAssignNew(allTools)
	HotbarState.CleanupInvalid()
	if not restoreDone and not tryRestore(allTools) then return end

-- [2] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide ใน checkStep ขั้น plant
	elseif s.id == "plant" then
		targetPos = nearestSoil()
		return plantCount() > basePlant
