-- BACKUP 2026-11-15 ก่อนย้ายปุ่มสลับหน้า (PageToggle) ออกไปนอกแถบ
-- Studio path: game.StarterPlayer.StarterPlayerScripts.CustomHotbar (LocalScript) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: วางท่อนด้านล่างกลับแทนท่อนเดียวกัน (สคริปต์เต็มก่อนทำแถบเลื่อนหน้า: backups/CustomHotbar_before_pageSlide_20261115.lua)
-- ========================================================================
-- (1) สร้างปุ่ม
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.Position = UDim2.new(1, BASE_PAD, 0.5, 0)
toggleButton.Size = UDim2.fromOffset(26, 44)

-- (2) applyResponsiveLayout
	local baseW = BASE_PAD*2 + ROW_SLOTS*BASE_SLOT_W + (ROW_SLOTS-1)*BASE_GAP
