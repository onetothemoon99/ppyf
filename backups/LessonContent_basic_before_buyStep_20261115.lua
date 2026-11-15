-- BACKUP 2026-11-15 ก่อนเปลี่ยนบทเรียน "ปลูก เก็บ ขาย" เป็น "ซื้อเมล็ด ปลูก เก็บ ขาย"
-- Studio path: game.ReplicatedStorage.LessonContent (ModuleScript) — สำรองเฉพาะท่อนที่แก้ (บท id = "basic" ใน LessonContent.LESSONS)
-- คืนค่า: วางท่อนด้านล่างกลับแทนบท basic
-- ========================================================================
	{
		id = "basic", icon = "🌱", th = "ปลูก เก็บ ขาย", en = "Plant, harvest, sell",
		thLines = "1. กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน\n2. รอต้นโต แล้วกดปุ่มเก็บที่ต้น\n3. ขายผลผลิตที่ร้านเมล็ด แล้วซื้อเมล็ดใหม่",
		enLines = "1. Tap slot 1 (seeds), then tap a soil plot\n2. Wait for it to grow, then press harvest on the crop\n3. Sell your crops at the seed shop, then buy new seeds",
		hubTh = "ช่อง 1 ปลูก รอโต เก็บ แล้วขายที่ร้านเมล็ด", hubEn = "Slot 1 to plant, then harvest and sell",
		startGuide = true, -- ปุ่ม = เริ่มลูกศรนำทาง 4 ขั้นของ NewPlayerGuide (NewPlayerGuideGui.StartGuide)
	},
