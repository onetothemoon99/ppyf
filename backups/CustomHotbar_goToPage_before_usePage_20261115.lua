-- BACKUP 2026-11-15 ก่อนให้ goToPage บอกหน้าให้ HotbarState + เลื่อนหน้าเมื่อกด "ใช้" แล้วของลงอีกหน้า
-- Studio path: game.StarterPlayer.StarterPlayerScripts.CustomHotbar (LocalScript) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: ลบบรรทัด HotbarState.SetCurrentPage(page) ใน goToPage และฟังก์ชัน HotbarState.OnUsePlaced ที่เพิ่มไว้ใต้ goToPage(1, true)
-- ========================================================================
	currentPage = page
	toggleButton.Text = page == 1 and "▶" or "◀"

goToPage(1, true)
toggleButton.Activated:Connect(function()
