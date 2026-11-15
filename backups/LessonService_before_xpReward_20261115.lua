-- BACKUP 2026-11-15 ก่อนเพิ่ม EXP ในรางวัลบทเรียน
-- Studio path: game.ServerScriptService.LessonService (Script) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: วางท่อนด้านล่างกลับแทนท่อนเดียวกัน แล้วลบบรรทัด require LevelSystem / xpText ที่เพิ่มไว้
-- ========================================================================
-- (1) markReady ข้อความแจ้ง
	local name = NAMES[id] or { th = id, en = id }
	local coins = formatCoins(Config.Rewards[id] or 0)
	notify(player,
		"✅ บทเรียน \"" .. name.th .. "\" สำเร็จ! ไปรับรางวัล 💰 " .. coins .. " ที่หุ่นนกฮูก",
		"✅ Lesson \"" .. name.en .. "\" done! Claim 💰 " .. coins .. " from the Robot Owl")

-- (2) ท้าย claim
	CheatWatch.AllowCoinGain(player, reward)
	coins.Value += reward
	print(string.format("🎓 LessonService: %s รับรางวัลบทเรียน %s %d เหรียญ", player.Name, id, reward))
	return { ok = true, coins = reward }

-- (3) NAMES.basic
	basic = { th = "ปลูก เก็บ ขาย", en = "Plant, harvest, sell" },
