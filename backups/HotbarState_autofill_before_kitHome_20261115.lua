-- BACKUP 2026-11-15 ก่อนให้ผู้เล่นใหม่ได้บัวรดน้ำช่อง 8 / ขวานช่อง 9
-- Studio path: game.StarterPlayer.StarterPlayerScripts.HotbarState (ModuleScript) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: ลบ NEW_PLAYER_HOME + newPlayerSlot ที่เพิ่มไว้ใต้ firstFreeSlot แล้ววางท่อน (1)(2) กลับแทนท่อนเดียวกันใน AutoAssignNew
-- (สคริปต์เต็มก่อนทำ 2 แถว: backups/HotbarState_before_hotbar2row_20261115.lua)
-- ========================================================================
-- (1) ใน AutoAssignNew ช่วง lateRestore (ไม่มีข้อมูลเซฟ)
				elseif not isX100 and not tool:GetAttribute("IsProduce") and not tool:GetAttribute("IsFish") and not tool:GetAttribute("IsBait") then
					local target = firstFreeSlot(tool)
					if target then slots[target] = tool end
				end

-- (2) ใน AutoAssignNew ลูปของที่ยังไม่เคยเห็น
			elseif known and known > 0 and not keepX100InInventory then
				-- เคยอยู่ช่องนี้: ลงช่องเดิม / ช่องเดิมผิดกฎ (เช่นเบ็ดเคยอยู่ช่อง 4) หรือไม่ว่าง = ช่องที่ถูก (ถ้ายังเข้าเกมอยู่)
				local target = (not HotbarState.GetSlotTool(known) and HotbarState.CanPlaceInSlot(tool, known)) and known
					or (not HotbarState.CanPlaceInSlot(tool, known) and firstFreeSlot(tool)) or nil
				if target then slots[target] = tool end
			elseif not autoFill or keepX100InInventory then
