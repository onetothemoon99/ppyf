-- Backup (changed sections only) before "mango lesson: axe -> slot 9 / can -> slot 8 + hold highlight", 2026-11-18
-- Restore: put each section below back in Studio (search "kitslot 2026-11-18" to find the new code).

-- [1] game.StarterPlayer.StarterPlayerScripts.HotbarState: no HotbarState.PlaceGuideKit function
--     (it was added right after HotbarState.UseTool). Delete it.

-- [2] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide
--   ORCHARD_STEPS oCut text was:
		th = "ต้นในบทเรียนแห้งแล้ว ไปที่ต้น กดค้าง E \"ตัดต้น\" (ขวานขึ้นมือให้เอง) ได้ท่อนไม้ไปทำปุ๋ย", en = "Your lesson tree has dried up. Go to it and hold E \"Cut down\" (the axe is equipped for you) to get logs for fertilizer",
--   no isAxe helper (was after isCan):
local function isCan(t) return t:GetAttribute("IsOrchardTool") == true and t:GetAttribute("OrchardToolId") == "Can" end
--   checkOrchardStep oCut, after `if not pos then ... end` was:
		targetPos = pos
		markText = tr(s.markTh, s.markEn)
		orchLandmark(path, tr("ต้นแห้ง · กดค้าง E ตัด", "Dry tree · hold E to cut"))
		setCardText(tr(s.th, s.en))
		return false
--   oUncle watering branch started:
		else
			shopHint, orchHold = "orchardHold", "Can" -- ไฮไลต์ช่อง/กระเป๋าให้ถือบัวรดน้ำ
--   findHintTarget orchardHold test/label were:
		local test = orchHold == "Can" and isCan or (orchHold == "Seed" and isMangoSeed) or isPicker
		local label = orchHold == "Can" and tr("👆 กดถือบัวรดน้ำ", "👆 Tap to hold the watering can")

-- [3] game.ServerScriptService.Orchard.OrchardService actions.harvest: no EnsureKit call after `saveBag(player)` for lessonDead.
