-- Backup (เฉพาะท่อนที่แก้) ของ game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide ก่อนแก้ "ขั้นขาย: ชี้ปุ่มขายแถวบนสุด ไม่ใช่ขายทั้งหมด" 2026-11-16
-- ย้อนกลับ: แทนแต่ละท่อนด้วยของเดิมข้างล่าง แล้วลบ local baseBasic และบรรทัด baseBasic = ... ใน enterStep

-- [1] findHintTarget ท่อนร้านเมล็ด แท็บขาย
	if tab ~= "sell" then return main:FindFirstChild("SellTab", true), tr("👆 กดแท็บขาย", "👆 Tap the Sell tab") end
	local all = list and list:FindFirstChild("SellAllButton", true)
	if all then return all, tr("👆 กดขายทั้งหมด", "👆 Tap Sell All") end
	return list and firstTagged(list, "GuideSellCrop"), tr("👆 กดขาย", "👆 Tap Sell")

-- [2] checkStep ขั้น sell
	elseif s.id == "sell" then
		if not targetPos then targetPos = shopPos() end
		return coins() > baseCoins
