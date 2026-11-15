-- Backup (เฉพาะท่อนที่แก้) ของ game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide ก่อนแก้ "ขั้นซื้อเมล็ดต้องซื้อ 10 เมล็ด" 2026-11-15
-- ย้อนกลับ: ใน Studio แทนแต่ละท่อนที่แก้ด้วยของเดิมข้างล่าง แล้วลบ BUY_SEEDS / lastSeeds / boughtSeeds / seedShopOpen ที่เพิ่มใต้ `local steps = STEPS`
--   และลบบรรทัด player:SetAttribute("GuideBuyQty", ...) ใน enterStep / stop / finish

-- [1] ใน STEPS (เดิมบรรทัด 53)
	{ id = "buy", th = "ไปร้านเมล็ด แล้วซื้อเมล็ด", en = "Go to the seed shop and buy seeds",

-- [2] ใน findHintTarget (เดิมบรรทัด 824)
		return list and firstTagged(list, "GuideBuySeed"), tr("👆 กดซื้อเมล็ด", "👆 Tap Buy")

-- [3] ใน checkStep (เดิมบรรทัด 567–569)
	if s.id == "buy" then
		if not targetPos then targetPos = shopPos() end
		return seedCount() > baseSeeds

-- [4] ใน start (เดิมบรรทัด 599)
	enterStep((steps == STEPS and seedCount() > 0) and 2 or 1)
