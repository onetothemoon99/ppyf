-- BACKUP of ReplicatedStorage.LoginAnnouncementConfig (ModuleScript) before filling V2.1 + new Id, 2026-11-26
-- Restore: paste everything below this header into ReplicatedStorage.LoginAnnouncementConfig.Source
-- LoginAnnouncementConfig: ประกาศตอนเข้าเกม (หน้าต่าง LoginAnnouncementGui) แก้ข้อความที่นี่แล้ว Publish
-- เปลี่ยน Id ทุกครั้งที่ลงประกาศใหม่ คนที่กด "ข้ามสำหรับวันนี้" ไปแล้วจะได้เห็นประกาศใหม่ (การข้ามผูกกับ Id)
-- 2026-10-08 รูปแบบใหม่: หัวนากโผล่ด้านบน + 2 หัวข้อ (ข่าวสาร + โค้ด / แจ้งอัปเดต เลื่อนขึ้นลงได้)
return {
	Enabled = true,
	Id = "farm-news-20261116", -- 2026-11-16 แถวเด่นเปลี่ยนเป็นสวนผลไม้ (เดิม farm-news-20261101)

	-- แถวเด่นบนสุด: ข้อความ + ปุ่มวาร์ป (Warp = Id จุดใน WarpConfig) · เอาออก = ลบทั้งก้อนนี้
	-- 2026-11-16 ผู้ใช้สั่ง: เปลี่ยนจากฟาร์มไก่ (2026-10-25) เป็นสวนผลไม้
	-- RequireChicken = true: ระบบไก่ปิด = ไม่แสดง · RequireOrchard = true: สวนปิด (OrchardConfig.Enabled = false) = ไม่แสดง
	Feature = {
		TH = "🥭 สวนผลไม้มาแล้ว! ปลูกมะม่วง เก็บผลขาย ช่วยเพื่อนรดน้ำ ระวังโดนขโมย!",
		EN = "🥭 The Orchard is here! Plant mangoes, sell the fruit, water friends' trees, watch out for thieves!",
		ButtonTH = "🌳 ไปสวนผลไม้",
		ButtonEN = "🌳 Go there",
		Warp = "orchard",
		RequireOrchard = true,
	},

	-- หัวข้อที่ 1: ข่าวสาร (Code = โค้ดที่แสดงในกล่องสีทอง เว้นว่าง "" = ไม่แสดงกล่องโค้ด)
	News = {
		TitleTH = "ข่าวสารจากฟาร์ม",
		TitleEN = "Farm News",
		BodyTH = "🎁 แจกโค้ดสำหรับนักฟาร์ม :",
		BodyEN = "🎁 Gift code for farmers:",
		Code = "NEWFARMER",
	},

	-- หัวข้อที่ 2: แจ้งอัปเดต (ใหม่สุดไว้บนสุด)
	Updates = {
		TitleTH = "แจ้งอัพเดต&ปรับปรุง",
		TitleEN = "Updates & Improvements",
		Items = {
			{
				Version = "V2.1",
				TH = "",
				EN = "",
			},
			{
				Version = "V2",
				TH = "อัพเดตสวนมะม่วงเข้าใหม่แล้ว พร้อมระบบขโมยและช่วยเหลือ , ลอยกระทง แขวนโคม ปล่อยโคมลอย , อัพเดตที่นั่งเพิ่มเติม สุ่มได้จากตู้สุ่มสัตว์ขี่ , เพิ่มป้ายสำหรับเขียนข้อความ",
				EN = " New Mango Orchard : Stealing & Rescue System | Loy Krathong Festival – Hang Lanterns & Release Sky Lanterns | More Seats from Mount Pet Gacha | New Message Boards",
			},
			{
				Version = "V1.2.1",
				TH = "สัตว์เลี้ยงใหม่จริงใจจิงโจ้ ผึ้งราชินี, ตู้สัตว์ขี่ ม้าก้านกล้วย เจ้าทุยเผือก เจ้าทุย วัวมอมอ",
				EN = "Jingjai the Kangaroo, Queen Bee | New Mounts: Banana Stalk Horse, Albino Tui, Tui the Buffalo, Momo the Cow",
			},
			{
				Version = "V1.2",
				TH = "ฟาร์มไก่",
				EN = "Chicken farm",
			},
			{
				Version = "V1.1.9",
				TH = "ตู้สุ่มสัตว์ขี่และของตกแต่ง",
				EN = "Mount & Decoration Gacha",
			},
			{
				Version = "V1.1.8",
				TH = "สัตว์เลี้ยงใหม่ผีน้อยนักปักหุ่น , แม่มดน้อย , ปลาอีเวนต์ 4 ตัว",
				EN = "New pets: Little Ghost Needle felt, Little Witch, and 4 event fish.",
			},
			{
				Version = "V1.1.7",
				TH = "เพิ่มEventช่วยน้องนากเก็บขยะ , สุลต่านLv.300ขึ้นไป สามารถเทรดเหรียญได้วันละ 1m",
				EN = "Added Otter Trash Collection event Sultans Lv.300 and above can trade up to 1M coins daily.",
			},
			{
				Version = "V1.1.6",
				TH = "อัพเดตปลาเพิ่มใหม่ , เปิดระบบคราฟเบ็ดได้ที่โต๊ะช่างนากน้อย,เพิ่มเพลงใน Music Box , สามารถปิดชื่อได้แล้ว, เพิ่มสนามมวยนากบัญชา",
				EN = "New fish added, fishing rod crafting at Otter's Workbench, new Music Box tracks, hide player names option, and added the Otterbancha Boxing Stadium.",
			},
			{
				Version = "V1.1.5",
				TH = "แก้ไขปัญหาafkตอนนั่งเก้าอี้ , แก้ไขผู้เล่นถูกดันตัวขณะตกปลา , สามารถรีตัวแล้วเกิดที่จุดเดิมได้แล้ว",
				EN = "Fixed AFK issue while sitting on chairs, Fixed players getting pushed while fishing, Players now respawn at their previous location after resetting.",
			},
			{
				Version = "V1.1.4",
				TH = "เพิ่มระบบอัพเลเวลสัตว์เลี้ยงด้วยเศษวิญญาณ , ปรับหน้าต่างการให้อาหารสัตว์เลี้ยง,แก้ไขระบบจับภาพถ่ายหน้าจอ",
				EN = "Add pet leveling with Soul Fragments, revamp pet feeding UI, fix screenshot capture.",
			},
			{
				Version = "V1.1.3",
				TH = "เพิ่มเบ็ดตกปลาผีเสื้อและเบ็ดตกปลาผึ้งน้อย, เพิ่ม Music Box, เพิ่มระบบโอนเหรียญ (สูงสุดวันละ 200,000)",
				EN = "New Butterfly Rod and Little Bee Rod, new Music Box, new coin transfer (up to 200,000 per day)",
			},
			{
				Version = "V1.1.2",
				TH = "ปรับปรุงสีจิ้งจอกน้อย",
				EN = "Little Fox has a new color",
			},
			{
				Version = "V1.1.1",
				TH = "เพิ่มโควต้าปลูก +5 สามารถซื้อเป็นเหรียญได้แล้วที่ร้านค้า",
				EN = "Planting quota +5 can now be bought with coins in the shop",
			},
		},
	},

	-- (เดิม) ฝั่งเซิร์ฟเวอร์ยังส่งค่าพวกนี้ไปด้วย เก็บไว้กันพัง
	TitleTH = "ข่าวสารจากฟาร์ม",
	TitleEN = "Farm News",
	DetailsTH = "",
	DetailsEN = "",
}
