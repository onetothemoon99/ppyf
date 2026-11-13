-- BACKUP 2026-11-12: game.ReplicatedStorage.AchievementConfig (ModuleScript) before round 6 badges (5 new tiers)
-- Restore: in Studio open ReplicatedStorage.AchievementConfig, replace its whole Source with everything below the "-- ===== SOURCE =====" line.
-- ===== SOURCE =====
-- AchievementConfig: เหรียญตรา Roblox จากยอดสะสมตลอดกาล (2026-11-04) ใช้ร่วมกันทั้งเซิร์ฟเวอร์ (AchievementService) และหน้าจอในอนาคต
-- เพิ่มตรา: สร้างตราบน Creator Dashboard แล้วเพิ่มแถวใน Tiers ของหมวดนั้น (id = Badge ID ไม่ต้องแก้ DataStore)
-- รูปเหรียญอยู่ในโปรเจกต์ art/badges (generate.js)

local AchievementConfig = {}

-- DEV_ONLY = true: เปิดเฉพาะใน Studio (Play / Team Test) เซิร์ฟจริงซ่อนทั้งระบบ ไม่นับ ไม่มอบตรา ไม่จ่ายเหรียญ ไม่มีปุ่มใน ☰ (ผู้ใช้สั่ง 2026-11-04) · เปิดให้ผู้เล่นจริง = DEV_ONLY = false ดู ACHIEVEMENTS.md
AchievementConfig.DEV_ONLY = true
AchievementConfig.ENABLED = (not AchievementConfig.DEV_ONLY) or game:GetService("RunService"):IsStudio()
AchievementConfig.WINDOW = 600 -- ช่วงเวลาตรวจยอดผิดปกติ (วินาที)
AchievementConfig.AWARD_RETRY = 120 -- มอบตราไม่สำเร็จ ลองใหม่ทุกกี่วินาที

-- coins = รางวัลเหรียญครั้งเดียวต่อบัญชี (2026-11-04 ผู้ใช้กำหนด) · image = iconImageId ของตรา (หน้าต่าง AchievementGui ใช้แสดงรูป) · Tiers เรียงจากน้อยไปมาก · ค่าเพดานต่อ WINDOW กันปั๊มยอด ส่วนที่เกินไม่ถูกนับ
AchievementConfig.Lines = {
	-- ตราต้อนรับ: มอบตอนโหลดข้อมูลครั้งแรก (AchievementService.onPlayerAdded) · hideTotal = ไม่แสดงยอดสะสมในหน้าต่าง
	join = {
		order = 0, icon = "🎉", th = "ยินดีต้อนรับ", en = "Welcome", hideTotal = true,
		descTh = "ได้เข้าร่วม พักผ่อนหย่อนฟาร์ม", descEn = "Joined Chilling At Farm",
		Tiers = {
			{ need = 1, id = 2864899233197220, image = 86224016645610, th = "จุดเริ่มต้นของชาวสวน", en = "A Gardener's Beginning" },
		},
	},
	plant = {
		order = 1, icon = "🌱", th = "ปลูกพืช", en = "Planting",
		descTh = "ปลูกพืชครบ %s ต้น", descEn = "Plant %s crops",
		Tiers = {
			{ need = 10, id = 3069906135594246, image = 91181488186511, coins = 100000, th = "นักปลูกฝึกหัด", en = "Apprentice Planter" },
			{ need = 100, id = 703410877988170, image = 126896635159406, coins = 350000, th = "ชาวไร่ขยัน", en = "Hardworking Farmer" },
			{ need = 1000, id = 1646496349429969, image = 75786558881712, coins = 750000, th = "เซียนแปลงผัก", en = "Veggie Plot Master" },
			{ need = 10000, id = 3816612772573592, image = 119311145315529, coins = 1500000, th = "ตำนานชาวสวน", en = "Legendary Gardener" },
			{ need = 100000, id = 2802396583262652, image = 75932166263965, coins = 3000000, th = "เจ้าแห่งผืนดิน", en = "Lord of the Land" },
			{ need = 1000000, id = 3411879847380939, image = 83103360296792, coins = 5000000, th = "เทพแห่งการเพาะปลูก", en = "Farming Deity" },
		},
	},
	fish = {
		order = 2, icon = "🎣", th = "ตกปลา", en = "Fishing",
		descTh = "ตกปลาครบ %s ตัว", descEn = "Catch %s fish",
		Tiers = {
			{ need = 10, id = 992621926129590, image = 81912160577442, coins = 100000, th = "นักตกปลาฝึกหัด", en = "Apprentice Angler" },
			{ need = 100, id = 2564445070643858, image = 73601621000986, coins = 350000, th = "นักตกปลามือฉมัง", en = "Skilled Angler" },
			{ need = 1000, id = 876813979511547, image = 87183935166614, coins = 750000, th = "ราชานักตกปลา", en = "Master Angler" },
			{ need = 10000, id = 1188632024616960, image = 74985373631325, coins = 1500000, th = "นักตกปลาในตำนาน", en = "Legendary Angler" },
			{ need = 100000, id = 1041191966060619, image = 137689231392746, coins = 3000000, th = "เจ้าแห่งท้องน้ำ", en = "Lord of the Waters" },
		},
	},
	-- ยอดตาม ChickenData stats.eggs (รวมไข่ตอนออฟไลน์ + ย้อนหลัง) AchievementService.syncEggs ตั้งให้ทุก 10 วิ ไม่ผ่าน WindowCap
	egg = {
		order = 3, icon = "🥚", th = "ไข่ไก่", en = "Eggs",
		descTh = "ไก่ออกไข่ครบ %s ฟอง", descEn = "Hens lay %s eggs",
		Tiers = {
			{ need = 10, id = 2539101117450291, image = 114097239777253, coins = 100000, th = "เจ้าของเล้ามือใหม่", en = "Rookie Coop Keeper" },
			{ need = 100, id = 2806127303741150, image = 130824100524483, coins = 350000, th = "เจ้าของเล้าขยัน", en = "Busy Coop Keeper" },
			{ need = 1000, id = 814520466708967, image = 108497931154175, coins = 750000, th = "เซียนเล้าไก่", en = "Coop Master" },
			{ need = 10000, id = 1112641989898482, image = 131150041173100, coins = 1500000, th = "ราชาแห่งเล้าไก่", en = "Coop King" },
			{ need = 100000, id = 1188339460383359, image = 99704891731166, coins = 3000000, th = "จักรพรรดิเล้าไก่", en = "Coop Emperor" },
		},
	},
	-- ยอดตามเลเวลและชั่วโมงเล่น รวมยอดย้อนหลัง AchievementService.syncLevelAndTime ตั้งให้ทุก 10 วิ ไม่ผ่าน WindowCap
	level = {
		order = 4, icon = "⭐", th = "เลเวล", en = "Level",
		descTh = "ถึงเลเวล %s", descEn = "Reach level %s",
		Tiers = {
			{ need = 10, id = 148765460645788, image = 96734460958352, coins = 100000, th = "ชาวฟาร์มหน้าใหม่", en = "Rising Farmer" },
			{ need = 50, id = 1661982305118219, image = 138314975581119, coins = 350000, th = "ชาวฟาร์มตัวจริง", en = "True Farmer" },
			{ need = 100, id = 1461063817378209, image = 136649631043889, coins = 750000, th = "ปราชญ์ชาวฟาร์ม", en = "Farm Sage" },
			{ need = 500, id = 784026698394716, image = 76695962115439, coins = 1500000, th = "ปรมาจารย์ฟาร์ม", en = "Farm Grandmaster" },
			{ need = 1000, id = 3986937198030119, image = 125249512000057, coins = 3000000, th = "ตำนานแห่งฟาร์ม", en = "Farm Legend" },
		},
	},
	time = {
		order = 5, icon = "⏰", th = "เวลาเล่น (ชั่วโมง)", en = "Playtime (hours)",
		descTh = "เล่นครบ %s ชั่วโมง", descEn = "Play for %s hours",
		Tiers = {
			{ need = 10, id = 1583097615395428, image = 140285230076942, coins = 100000, th = "คนรักฟาร์ม", en = "Farm Lover" },
			{ need = 50, id = 2126607130537820, image = 111970248577507, coins = 350000, th = "ลูกบ้านประจำฟาร์ม", en = "Farm Regular" },
			{ need = 100, id = 3588191362605866, image = 90643489566173, coins = 750000, th = "ชาวฟาร์มตลอดกาล", en = "Farmer for Life" },
			{ need = 500, id = 1884531567153370, image = 71319356084714, coins = 1500000, th = "หัวใจของฟาร์ม", en = "Heart of the Farm" },
		},
	},
}

-- เพดานยอดต่อ WINDOW: รอบปลูกเร็วสุดราว 5 วินาที (เหมือน LevelSystem) = โควต้า x 120 ต่อ 10 นาที · ปลากัดต่อคนไม่ถึงทุก 2 วินาที รวมนากแล้ว
function AchievementConfig.WindowCap(lineId, plantLimit)
	if lineId == "plant" then return math.max(tonumber(plantLimit) or 10, 10) * 120 end
	return 300
end

return AchievementConfig
