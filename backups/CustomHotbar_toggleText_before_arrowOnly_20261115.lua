-- BACKUP 2026-11-15 ก่อนให้ปุ่มย่อแถวบนแสดงแค่ลูกศร (ตัดตัวเลขจำนวนช่องออก)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.CustomHotbar (LocalScript) — สำรองเฉพาะส่วนที่แก้
-- คืนค่า: วางสองท่อนนี้กลับแทนท่อนเดียวกันในสคริปต์ (สคริปต์เต็มก่อนทำ 2 แถว: backups/CustomHotbar_before_hotbar2row_20261115.lua)
-- ========================================================================
-- (1) สร้างปุ่ม
toggleButton.Size = UDim2.new(0, 46, 0, 22)

-- (2) ใน refreshHotbar
	-- ปุ่มย่อ: ตอนย่ออยู่บอกจำนวนช่องแถวบนที่มีของ (ของที่ลงแถวบนตอนย่อจะได้ไม่หายเงียบ)
	if not topFrame.Visible then
		local filled = 0
		for i = ROW_SLOTS + 1, MAX_SLOTS do
			if HotbarState.GetSlotTool(i) then filled += 1 end
		end
		toggleButton.Text = filled > 0 and ("▲ " .. filled) or "▲"
	else
		toggleButton.Text = "▼"
	end
