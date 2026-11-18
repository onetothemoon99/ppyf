-- Backup (changed sections only) before "mango lesson step 6: can icon over Uncle's dry tree + new watering/finish text", 2026-11-18
-- Restore: put the lines below back (search "step6 2026-11-18" to find the new code and remove it).

-- [1] game.StarterPlayer.StarterPlayerScripts.UncleManaoFx: no can-icon block (it was appended at the end of the script). Delete it.

-- [2] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide
--   oUncle watering card was:
			setCardText(tr("ได้มะม่วงแล้ว! รดน้ำต้นแห้งให้ลุง: ", "Got a mango! Water Uncle's dry tree: ") .. slotText(isCan, "บัวรดน้ำ", "watering can")
				.. tr("ยืนใกล้ต้น กดค้าง F \"รดน้ำให้ลุง\"", "stand next to it and hold F \"Water\""))
--   finish() orchard text (2 places, guideTo text + fallback card) was:
	tr("เก่งมาก! จบบทสวนมะม่วงแล้ว ไปรับรางวัลที่หุ่นนกฮูก", "Well done! Mango orchard lesson complete. Claim your reward from the Robot Owl")
