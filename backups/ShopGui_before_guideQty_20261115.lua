-- Backup (เฉพาะท่อนที่แก้) ของ game.StarterPlayer.StarterPlayerScripts.ShopGui ก่อนแก้ "บทสอนตั้งจำนวนซื้อเมล็ดไว้ให้" 2026-11-15
-- ย้อนกลับ: ใน Studio แทนแต่ละท่อนด้วยของเดิมข้างล่าง และลบ `local guideQty = ...` / `defaultQty = ...` ที่เพิ่มใน renderBuyTab

-- [1] ใน createItemRow (เดิมบรรทัด 614)
	qtyBox.Text = disabled and "0" or "1"
