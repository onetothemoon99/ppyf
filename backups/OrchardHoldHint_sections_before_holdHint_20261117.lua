-- Backup (changed sections only) before "highlight: hold the picker / watering can" in the orchard lesson, 2026-11-17
-- Restore: undo the sections below in Studio.

-- [1] game.StarterPlayer.StarterPlayerScripts.FullInventoryGui (~line 1279) was:
		local _, useButton = createItemCard(tool, order)
		cardTools[useButton] = tool -- จอยเลือกที่ปุ่ม "ใช้"
--     (new line after it sets useButton attribute GuideTool; delete it)

-- [2] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide
--   * new local `orchHold` + `isCan` + `orchLandmark` helper near the orchard section (delete)
--   * checkOrchardStep, oUncle branch: the "not stole" (has picker) and "stole" parts used `shopHint = nil` and fixed texts:
--       steal text = slotText(isPicker, "ตะกร้อ", "picker") .. "ยืนใต้ต้นมะม่วงลุง กดค้าง E \"ขโมย\" (ลุงยอมให้คนในบทสอนเท่านั้น)"
--       water text = "ได้มะม่วงแล้ว! ไปรดน้ำต้นแห้งให้ลุง: ยืนใกล้ต้น กดค้าง F \"รดน้ำให้ลุง\""
--   * findHintTarget: new `if shopHint == "orchardHold" then ... end` branch before `if shopHint == "fishSell" then` (delete)
