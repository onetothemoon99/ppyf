-- BACKUP 2026-11-15 ก่อนให้ปุ่ม "ใช้" ในกระเป๋าหาช่องว่างในหน้าที่เปิดอยู่ก่อน
-- Studio path: game.StarterPlayer.StarterPlayerScripts.HotbarState (ModuleScript) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: วางท่อนด้านล่างกลับแทนท้ายฟังก์ชัน UseTool แล้วลบ currentPage / SetCurrentPage / OnUsePlaced ที่เพิ่มไว้
-- ========================================================================
	if tool:GetAttribute("IsFishingRod") then
		local old = HotbarState.GetSlotTool(ROD_SLOT)
		slots[ROD_SLOT] = tool
		return true, ROD_SLOT, old
	end
	for i = 1, MAX_SLOTS do
		if not HotbarState.GetSlotTool(i) and HotbarState.CanPlaceInSlot(tool, i) then
			slots[i] = tool
			return true, i
		end
	end
	return false, "full"
end
