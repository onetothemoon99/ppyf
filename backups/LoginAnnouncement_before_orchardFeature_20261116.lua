-- Backup 2026-11-16 before the "orchard feature row" change
-- (A) game.ReplicatedStorage.LoginAnnouncementConfig — only lines 1-17 changed (Id + Feature); the rest of the file is unchanged.
--     Restore: put these lines back over the new Id + Feature block.
-- (B) game.StarterPlayer.StarterPlayerScripts.LoginAnnouncementGui — the RequireChicken check; restore by replacing the new check block with this one.

-------- (A) LoginAnnouncementConfig lines 1-17 --------
-- LoginAnnouncementConfig: ประกาศตอนเข้าเกม (หน้าต่าง LoginAnnouncementGui) แก้ข้อความที่นี่แล้ว Publish
-- เปลี่ยน Id ทุกครั้งที่ลงประกาศใหม่ คนที่กด "ข้ามสำหรับวันนี้" ไปแล้วจะได้เห็นประกาศใหม่ (การข้ามผูกกับ Id)
-- 2026-10-08 รูปแบบใหม่: หัวนากโผล่ด้านบน + 2 หัวข้อ (ข่าวสาร + โค้ด / แจ้งอัปเดต เลื่อนขึ้นลงได้)
return {
	Enabled = true,
	Id = "farm-news-20261101",

	-- แถวเด่นบนสุด (2026-10-25 ผู้ใช้ขอ ให้ผู้เล่นรู้ว่ามีฟาร์มไก่): ข้อความ + ปุ่มวาร์ป (Warp = Id จุดใน WarpConfig) · เอาออก = ลบทั้งก้อนนี้
	-- RequireChicken = true: ระบบไก่ปิดอยู่ (ChickenConfig.Enabled = false) = ไม่แสดงแถวนี้
	Feature = {
		TH = "🐔 ฟาร์มไก่มาแล้ว! เลี้ยงไก่ ไข่ออกเองแม้ออกเกม ผสมได้ไก่หายาก สะสมครบสมุดรับ 1,000,000 เหรียญ",
		EN = "🐔 The Chicken Farm is here! Chickens lay eggs even offline, breed rare ones, complete the book for 1,000,000 coins",
		ButtonTH = "🐔 ไปฟาร์มไก่",
		ButtonEN = "🐔 Go there",
		Warp = "chickenfarm",
		RequireChicken = true,
	},

-------- (B) LoginAnnouncementGui check --------
local feature = type(config.Feature) == "table" and config.Feature or nil
if feature and feature.RequireChicken then
	local okCfg, chickenCfg = pcall(function() return require(ReplicatedStorage:WaitForChild("ChickenConfig")) end)
	if not (okCfg and chickenCfg.Enabled) then feature = nil end
end
