-- BACKUP of game.ReplicatedStorage.FishingConfig (full Source, 59889 bytes) taken 2026-11-26 before opening the Sakura Jellyfish rod for sale (product ids).
-- Restore: in Studio open game.ReplicatedStorage.FishingConfig, select all, paste everything below this header.
-- FishingConfig: ระบบตกปลา (ใช้ทั้งเซิร์ฟเวอร์และหน้าจอ)
--   เบ็ด (Rods): ซื้อด้วยเหรียญที่ร้านตกปลา ยิ่งขั้นสูง ปลากินเร็วขึ้น เหวี่ยงได้ไกลขึ้น เกี่ยวง่ายขึ้น และเพิ่มโชค
--   เหยื่อ (Bait): ทำจากผลผลิต ใช้อัตโนมัติ 1 ชิ้นต่อปลากิน 1 ครั้ง
--   วงจร: ถือเบ็ด -> คลิกเหวี่ยงลงน้ำ -> รอปลากิน -> ทุ่นจม "❗" -> คลิกดึงให้ทันเวลา -> ได้ปลา

local FishingConfig = {}

FishingConfig.Rods = {
	-- ZoneBonus = กรอบเขียวในมินิเกมกว้างขึ้น (สัดส่วนของแถบ)
	Bamboo = {
		Order = 1, Icon = "🎋",
		DisplayName = "เบ็ดไม้ไผ่",
		Description = "เบ็ดเริ่มต้น รับฟรีที่ร้านตกปลา · ได้ปลาถึงระดับ หายาก",
		TierWeights = { Common = 85, Rare = 15 }, -- บันไดระดับปลาต่อเบ็ด (2026-10-03): ระดับที่ไม่มีในตาราง = ไม่มีทางได้เลย
		Price = 0,
		Luck = 1,             -- ตัวคูณโชคปลาหายาก
		CastDistance = 14,    -- ระยะเหวี่ยง (studs)
		BiteTime = { 6, 14 }, -- ปลากินหลังรอกี่วินาที (สุ่มในช่วงนี้)
		HookWindow = 1.6,     -- มีเวลากดเกี่ยวกี่วินาทีหลังทุ่นจม
		ZoneBonus = 0,
	},
	Carrot = {
		Order = 2, Icon = "🥕",
		DisplayName = "เบ็ดแครอท",
		Description = "คันส้มสดใส มีใบแครอทที่ด้าม · ได้ปลาถึงระดับ หายาก (โอกาสสูงขึ้น)",
		TierWeights = { Common = 78, Rare = 22 },
		Price = 8000,
		Luck = 1.25, CastDistance = 16, BiteTime = { 5.5, 12.5 }, HookWindow = 1.8, ZoneBonus = 0.02,
	},
	Kitty = {
		Order = 3, Icon = "🐱",
		DisplayName = "เบ็ดแมวเหมียว",
		Description = "หัวแมวน้อยที่ด้าม รีลอุ้งเท้า กระดิ่งทองที่ปลาย · ได้ปลาถึงระดับ ตำนาน",
		TierWeights = { Common = 68, Rare = 28, Legendary = 4 },
		Price = 30000,
		Luck = 1.6, CastDistance = 18, BiteTime = { 5, 11 }, HookWindow = 2.0, ZoneBonus = 0.04,
	},
	Candy = {
		Order = 4, Icon = "🍬",
		DisplayName = "เบ็ดลูกกวาด",
		Description = "ลายลูกกวาดแดงขาว รีลอมยิ้ม ปลายหัวใจ · ได้ปลาถึงระดับ ตำนาน (โอกาสสูงขึ้น)",
		TierWeights = { Common = 62, Rare = 30, Legendary = 8 },
		Price = 120000,
		Luck = 2.2, CastDistance = 20, BiteTime = { 4.5, 9.5 }, HookWindow = 2.2, ZoneBonus = 0.06,
	},
	Rainbow = {
		Order = 5, Icon = "🌈",
		DisplayName = "เบ็ดดาวรุ้ง",
		Description = "คันเจ็ดสี ดาวเรืองแสงที่ปลาย ปลาหายากชอบมาก · ได้ปลาทุกระดับ รวมลับสุดยอด",
		TierWeights = { Common = 56, Rare = 33, Legendary = 10, Secret = 1 },
		Price = 450000,
		Luck = 3, CastDistance = 24, BiteTime = { 4, 8 }, HookWindow = 2.5, ZoneBonus = 0.08,
	},
	NightMoth = {
		Order = 6, Icon = "🦋",
		DisplayName = "เบ็ดผีเสื้อ", -- 2026-10-08 เดิม เบ็ดผีเสื้อราตรี (RodId ยังเป็น NightMoth ห้ามเปลี่ยน ข้อมูลคนที่ซื้อแล้วผูกกับชื่อนี้)
		Description = "คันยาวประดับผีเสื้อเรืองแสงและออร่าราตรี · ซื้อถาวร 99 Robux",
		TierWeights = { Common = 52, Rare = 34, Legendary = 12, Secret = 2 },
		Price = 0, RobuxPrice = 99, ProductId = 3716702721, GiftProductId = 3717189301, -- GiftProductId = Developer Product "ส่งเบ็ดให้เพื่อน" (เพิ่ม 2026-10-08) — 2026-10-08 ราคา 45 → 99 (ราคาจริงตั้งที่ Creator Dashboard ตัวเลขนี้แค่แสดงบนปุ่ม)
		OnSale = true, -- true = แสดง/ขายในร้าน, false = ซ่อนจากร้านและปิดการซื้อใหม่ (2026-10-08 ผู้เล่นขอเปิดขาย)
		Luck = 5, CastDistance = 26, BiteTime = { 3.5, 7 }, HookWindow = 2.7, ZoneBonus = 0.10, -- โชค 4 → 5 (2026-10-08)
	},
	-- 2026-10-08 ผู้เล่นขอ: 199 Robux โชค 5 ปลาที่ได้ 3 ดาวขึ้นไปเสมอ (MinStar) ไม่มีขยะ (NoJunk) ดู FishingSystem.rollFish
	-- ProductId = Developer Product 199 R$ (ต้องสร้างใน Creator Dashboard แล้วใส่เลขที่นี่ แล้วเปิด OnSale = true)
	SunBee = {
		Order = 7, Icon = "🐝",
		DisplayName = "เบ็ดผึ้งน้อย", -- 2026-10-08 เดิม เบ็ดผึ้งตะวันฉาย (RodId ยังเป็น SunBee)
		Description = "กิ่งไม้พันเถาโคลเวอร์ รังผึ้งเรืองแสง ผึ้งบินรอบคัน ทุ่นดอกทานตะวัน · ปลา 3 ดาวขึ้นไปทุกตัว",
		TierWeights = { Common = 45, Rare = 36, Legendary = 16, Secret = 3 },
		MinStar = 3, -- NoJunk เอาออก 2026-10-08 (ผู้เล่นขอ: ขยะตกได้ทุกเบ็ด) การันตี 3 ดาวใช้กับปลา ขยะยังเป็น 1 ดาว
		Price = 0, RobuxPrice = 199, ProductId = 3717142136, GiftProductId = 3717189349, -- GiftProductId = Developer Product "ส่งเบ็ดให้เพื่อน" (เพิ่ม 2026-10-08)
		OnSale = true, -- 2026-10-08 เปิดขายแล้ว (Developer Product 199 R$)
		Luck = 8, CastDistance = 28, BiteTime = { 3, 6 }, HookWindow = 2.9, ZoneBonus = 0.12, -- โชค 5 → 8 (2026-10-08)
	},
	-- 2026-11-19 เบ็ดฟีนิกซ์ (ผู้ใช้สั่ง): 199 Robux ค่าพลังเท่าเบ็ดผึ้งน้อยทุกอย่าง เปลี่ยนแค่หน้าตา (โมเดล art/phoenix_rod/build_phoenix_rod.py)
	-- 2026-11-19 เปิดขาย: ProductId 3733495263 (ผู้ใช้สร้าง 199 R$) · ส่งของขวัญ GiftProductId 3733495613 (ผู้ใช้สร้าง 199 R$)
	Phoenix = {
		Order = 7.5, Icon = "🔥",
		DisplayName = "เบ็ดฟีนิกซ์",
		Description = "คันไล่สีแดงส้มทอง ปีกขนนกไฟ หัวนกฟีนิกซ์ที่ปลาย ทุ่นไข่ไฟ นกฟีนิกซ์ไฟบินวนรอบตัว ออร่าเปลวไฟ · ปลา 3 ดาวขึ้นไปทุกตัว",
		TierWeights = { Common = 45, Rare = 36, Legendary = 16, Secret = 3 },
		MinStar = 3,
		Price = 0, RobuxPrice = 199, ProductId = 3733495263, GiftProductId = 3733495613,
		OnSale = true,
		DevOnly = true, -- 2026-11-19 ผู้ใช้สั่ง "แค่ใน dev ก่อน" ดู DEV_ONLY_RODS ข้างล่าง · เปิดให้ผู้เล่นจริง = ลบบรรทัดนี้ (หรือ false)
		Luck = 8, CastDistance = 28, BiteTime = { 3, 6 }, HookWindow = 2.9, ZoneBonus = 0.12,
	},
	-- 2026-11-26 เบ็ดแมงกะพรุนซากุระ (ผู้ใช้สั่ง): 199 Robux ค่าพลังเท่าเบ็ดผึ้งน้อย/ฟีนิกซ์ทุกอย่าง เปลี่ยนแค่หน้าตา (โมเดล art/sakura_jelly_rod/build_sakura_jelly.py)
	--   ยังไม่มีสินค้า: ผู้ใช้สร้าง Developer Product 199 R$ (ซื้อ + ของขวัญ) แล้วใส่ ProductId / GiftProductId + OnSale = true
	SakuraJelly = {
		Order = 7.6, Icon = "🌸", -- 🪼 อาจไม่มีในฟอนต์ Roblox ใช้ดอกซากุระแทน
		DisplayName = "เบ็ดแมงกะพรุนซากุระ",
		Description = "คันชมพูมุกประดับดอกซากุระ แมงกะพรุนเรืองแสงที่ด้าม ทุ่นแมงกะพรุนจิ๋ว แมงกะพรุนซากุระลอยตามตัว · ปลา 3 ดาวขึ้นไปทุกตัว",
		TierWeights = { Common = 45, Rare = 36, Legendary = 16, Secret = 3 },
		MinStar = 3,
		Price = 0, RobuxPrice = 199, ProductId = 0,
		OnSale = false,
		DevOnly = true, -- 2026-11-26 เฉพาะ Studio ก่อน · เปิดให้ผู้เล่นจริง = ลบบรรทัดนี้แล้ว Publish
		Luck = 8, CastDistance = 28, BiteTime = { 3, 6 }, HookWindow = 2.9, ZoneBonus = 0.12,
	},
	-- 2026-11-19 เบ็ดกบน้อย (ผู้ใช้สั่ง): 99 Robux ค่าพลังเท่าเบ็ดผีเสื้อทุกอย่าง เปลี่ยนแค่หน้าตา (โมเดล art/frog_rod/build_frog_rod.py)
	-- 2026-11-19 เปิดขาย: ProductId 3733532606 (เบ็ดกบน้อย 99 R$) · GiftProductId 3733532792 (ของขวัญเบ็ดกบน้อย 99 R$) ผู้ใช้สร้าง
	Froggy = {
		Order = 6.5, Icon = "🐸",
		DisplayName = "เบ็ดกบน้อย",
		Description = "คันลายผิวกบพันริบบิ้นชมพู กบน้อยกอดคัน รอกใบบัว ปลายดอกบัวตูม ทุ่นใบบัวมีกบจิ๋ว · ซื้อถาวร 99 Robux",
		TierWeights = { Common = 52, Rare = 34, Legendary = 12, Secret = 2 },
		Price = 0, RobuxPrice = 99, ProductId = 3733532606, GiftProductId = 3733532792,
		OnSale = true,
		DevOnly = true, -- 2026-11-19 ผู้ใช้สั่ง "แค่ใน dev ก่อน" ดู DEV_ONLY_RODS ข้างล่าง · เปิดให้ผู้เล่นจริง = ลบบรรทัดนี้ (หรือ false)
		Luck = 5, CastDistance = 26, BiteTime = { 3.5, 7 }, HookWindow = 2.7, ZoneBonus = 0.10,
	},
	-- 2026-10-09 เบ็ดคราฟ (โต๊ะช่างนากน้อย ดู CraftConfig): Craft = true ได้จากการคราฟเท่านั้น (OnSale = false ไม่ขายในร้าน)
	-- ผู้ใช้กำหนด: ระดับปลาเท่าเบ็ดผีเสื้อ โชค x4 ระยะ 25 ปลากินเร็ว 45% (เฉลี่ย 5.5 วิ เทียบไม้ไผ่ 10) เวลาเกี่ยว 2.6 กรอบมินิเกม +9%
	EarthLove = {
		Order = 8, Icon = "🌍",
		DisplayName = "เบ็ดรักโลก",
		Description = "คันใบไม้จากของรีไซเคิล ลูกโลกจิ๋วที่ด้าม · ปลา 2 ดาวขึ้นไปทุกตัว · คราฟได้ที่โต๊ะช่างนากน้อยเท่านั้น",
		TierWeights = { Common = 52, Rare = 34, Legendary = 12, Secret = 2 },
		MinStar = 2, -- ปลา 2 ดาวขึ้นไปทุกตัว (ขยะยังเป็น 1 ดาว เหมือนเบ็ดผึ้งน้อย)
		Price = 0, Craft = true, OnSale = false,
		-- 2026-10-11 ผู้ใช้ปรับ: โชค 4 → 6, ระยะเหวี่ยง 25 → 27, ปลากินเร็ว 45% → 52% (เฉลี่ย 4.8 วิ เทียบไม้ไผ่ 10), ปลา 2 ดาวขึ้นไป
		Luck = 6, CastDistance = 27, BiteTime = { 3.1, 6.5 }, HookWindow = 2.6, ZoneBonus = 0.09,
	},
	-- 2026-11-20 เบ็ดแมลงปอน้อย (ผู้ใช้สั่ง เบ็ดคราฟแบบ 5): คราฟได้ที่โต๊ะช่างนากน้อยเท่านั้น โชค x6 ปลา 2 ดาวขึ้นไป ค่าอื่นเท่าเบ็ดรักโลก
	--   ZoneLuck = { stream = 1.5 }: ตกในลำธาร ปลาหายากขึ้นไปออกง่ายขึ้น 1.5 เท่า (FishingSystem.rollFish) · ออร่า: แมลงปอ 3D บินวน + กลีบดอกไม้ร่วง (SunBeeAuraFx) · DevOnly = เฉพาะ Studio
	Dragonfly = {
		Order = 8.5, Icon = "💧", -- 🪾 ไม่มีในฟอนต์ Roblox (ขึ้นกล่อง) 2026-11-20
		DisplayName = "เบ็ดแมลงปอน้อย",
		Description = "คันก้านบัวสีฟ้า แมลงปอเกาะปลายคัน รอกดอกบัว แมลงปอบินรอบตัว · ได้ปลาทุกระดับ ถึงระดับลับ · คราฟได้ที่โต๊ะช่างนากน้อยเท่านั้น",
		TierWeights = { Common = 52, Rare = 34, Legendary = 12, Secret = 2 },
		-- 2026-11-20 ผู้ใช้สั่ง "ความสามารถเท่าเบ็ดผีเสื้อ กลัวขายผีเสื้อไม่ออก": เอา MinStar 2 + ZoneLuck { stream = 1.5 } ออก ค่าเท่า NightMoth ทุกค่า (เดิม Luck 6 / 27 / {3.1, 6.5} / 2.6 / 0.09)
		Price = 0, Craft = true, OnSale = false,
		DevOnly = true,
		DevCoinPrice = 900000, -- 2026-11-20 ผู้ใช้สั่ง: ใน Studio ซื้อด้วยเหรียญอย่างเดียวได้ที่ร้านตกปลา (ไว้ทดสอบ) เซิร์ฟจริงไม่มีผล · เอาออก = ลบบรรทัดนี้
		Luck = 5, CastDistance = 26, BiteTime = { 3.5, 7 }, HookWindow = 2.7, ZoneBonus = 0.10,
	},
}

-- ============ เบ็ดที่เปิดเฉพาะใน Studio (DEV_ONLY_RODS) 2026-11-19 ============
-- เบ็ดที่ตั้ง DevOnly = true (ตอนนี้ Phoenix + Froggy + Dragonfly + SakuraJelly): ใน Studio เห็น/ซื้อได้ปกติ · เซิร์ฟจริง = ปิดขาย (ไม่อยู่ในร้าน) ไม่มีปุ่มส่งของขวัญ
--   FishingShop ไม่คืนเบ็ดนี้ตอนเข้าเกม + เก็บ Tool ออกจากกระเป๋า (สิทธิ์ใน FishingShop_v1 ยังอยู่ เปิดจริงเมื่อไหร่ได้คืนเอง)
--   RodShowcase ลบตู้โชว์ + นากโชว์ของเบ็ดนี้ตอนเริ่มเซิร์ฟ · เปิดให้ผู้เล่นจริง = เอา DevOnly ออกจากเบ็ดนั้นแล้ว Publish
local IS_STUDIO = game:GetService("RunService"):IsStudio()
for _, rod in pairs(FishingConfig.Rods) do
	if rod.DevCoinPrice and IS_STUDIO then -- Studio เท่านั้น: เปิดขายด้วยเหรียญในร้าน (เบ็ดคราฟที่ตั้ง DevCoinPrice) 2026-11-20
		rod.OnSale = true
		rod.Price = rod.DevCoinPrice
	end
	if rod.DevOnly and not IS_STUDIO then
		rod.OnSale = false
		rod.GiftProductId = nil
		rod.HiddenLive = true
	end
end
function FishingConfig.IsHiddenRod(rodId)
	local rod = FishingConfig.Rods[rodId]
	return rod ~= nil and rod.HiddenLive == true
end

-- ============ เหยื่อ (ทำจากผลผลิตที่ร้านตกปลา) ============
-- ผลผลิต 1 ชิ้น = เหยื่อ BAIT_PER_PRODUCE ชิ้น ดาวเดียวกัน / ใช้ 1 ชิ้นต่อปลากิน 1 ครั้ง
-- BiteMult = เวลารอปลากินคูณเท่านี้, Luck = บวกเพิ่มจากโชคของเบ็ด
FishingConfig.BAIT_PER_PRODUCE = 2
FishingConfig.Bait = {
	[1] = { BiteMult = 0.95, Luck = 0.1 },
	[2] = { BiteMult = 0.9, Luck = 0.2 },
	[3] = { BiteMult = 0.85, Luck = 0.35 },
	[4] = { BiteMult = 0.8, Luck = 0.5 },
	[5] = { BiteMult = 0.75, Luck = 0.75 },
}

-- สีประจำรุ่นเบ็ด (แถบบน/พื้นช่อง) ใช้ในแถบ 9 ช่องกับกระเป๋า ให้แยกออกว่าคันไหน (เดิมทุกคันฟ้าเหมือนกัน รูปเบ็ดก็เล็ก)
FishingConfig.RodStyle = {
	Bamboo = { Strip = Color3.fromRGB(95, 150, 70), Bg = Color3.fromRGB(215, 238, 195) },
	Carrot = { Strip = Color3.fromRGB(230, 130, 50), Bg = Color3.fromRGB(255, 225, 195) },
	Kitty = { Strip = Color3.fromRGB(225, 120, 160), Bg = Color3.fromRGB(255, 222, 235) },
	Candy = { Strip = Color3.fromRGB(210, 70, 80), Bg = Color3.fromRGB(255, 215, 215) },
	Rainbow = { Strip = Color3.fromRGB(140, 90, 220), Bg = Color3.fromRGB(230, 215, 255) },
	NightMoth = { Strip = Color3.fromRGB(111, 90, 170), Bg = Color3.fromRGB(224, 218, 250) },
	SunBee = { Strip = Color3.fromRGB(235, 170, 20), Bg = Color3.fromRGB(255, 240, 190) },
	Phoenix = { Strip = Color3.fromRGB(220, 60, 30), Bg = Color3.fromRGB(255, 222, 200) },
	SakuraJelly = { Strip = Color3.fromRGB(230, 100, 160), Bg = Color3.fromRGB(255, 225, 238) }, -- 2026-11-26
	Froggy = { Strip = Color3.fromRGB(90, 175, 70), Bg = Color3.fromRGB(220, 245, 200) },
	Dragonfly = { Strip = Color3.fromRGB(70, 160, 200), Bg = Color3.fromRGB(210, 240, 250) },
	EarthLove = { Strip = Color3.fromRGB(95, 175, 85), Bg = Color3.fromRGB(215, 240, 205) },
}
FishingConfig.DEFAULT_ROD_STYLE = { Strip = Color3.fromRGB(90, 160, 220), Bg = Color3.fromRGB(215, 235, 250) }
function FishingConfig.GetRodStyle(rodId)
	return FishingConfig.RodStyle[rodId] or FishingConfig.DEFAULT_ROD_STYLE
end
-- ชื่อสั้นของรุ่น (ตัดคำว่า "เบ็ด" หน้าชื่อ) เช่น "ไม้ไผ่", "ดาวรุ้ง"
function FishingConfig.RodShortName(rodId)
	local rod = FishingConfig.Rods[rodId]
	if not rod then return nil end
	return (rod.DisplayName:gsub("^เบ็ด", ""))
end

function FishingConfig.RodList(forShop)
	local list = {}
	for id, rod in pairs(FishingConfig.Rods) do
		if not forShop or rod.OnSale ~= false then
			table.insert(list, { Id = id, Rod = rod })
		end
	end
	table.sort(list, function(x, y) return x.Rod.Order < y.Rod.Order end)
	return list
end

FishingConfig.DEFAULT_ROD = "Bamboo"
FishingConfig.MAX_LINE_DISTANCE = 55 -- เดินห่างทุ่นเกินนี้ สายขาด (เก็บเบ็ดอัตโนมัติ)

-- ============ ปลา ============
-- แหล่งน้ำ (เซิร์ฟเวอร์แยกจากตำแหน่งทุ่น ดู FishingSystem.getZone)
FishingConfig.Zones = {
	canal = { Name = "คลอง", Icon = "🏞️" },
	lake = { Name = "ทะเลสาบ", Icon = "🛶" },
	stream = { Name = "ลำธาร", Icon = "⛰️" },
	sea = { Name = "ทะเล", Icon = "🌊" },
}

-- โอกาสแต่ละระดับต่อปลา 1 ตัว (ก่อนคูณโชค) ระดับที่แหล่งนั้นไม่มีปลาจะถูกตัดแล้วเฉลี่ยใหม่
FishingConfig.RarityWeights = { Common = 75, Rare = 22, Legendary = 3, Secret = 0.3 }
-- โอกาสระดับปลาตามเบ็ด (บันไดต่อเบ็ด ดู Rods.*.TierWeights): เบ็ดไม้ไผ่/แครอท = ธรรมดา-หายาก, แมว/ลูกกวาด = ถึงตำนาน, ดาวรุ้ง = ถึงลับ
-- luck = โชครวม (เบ็ด + เหยื่อ) ส่วนที่เกินโชคของเบ็ดเอง (= เหยื่อ) คูณเข้าระดับที่เบ็ดนั้นได้: หายาก x m^0.5, ตำนาน x m, ลับ x m
-- เหยื่อไม่ทำให้ได้ระดับที่เบ็ดไม่มี (ระดับที่ไม่มีในตารางเป็น 0)
-- ตัวคูณโอกาสได้ปลาระดับลับ (ทุกเบ็ด/ทุกเหยื่อ) 0.8 = ตกยากขึ้น 20% (2026-10-10 ผู้เล่นขอ) ปรับที่เลขนี้เลขเดียว
FishingConfig.SECRET_CHANCE_MULT = 0.8
-- ตัวคูณโอกาสได้ปลาระดับตำนาน (ทุกเบ็ด/ทุกเหยื่อ) 0.8 = ตกยากขึ้น 20% (2026-10-12 ผู้เล่นขอ)
FishingConfig.LEGENDARY_CHANCE_MULT = 0.64 -- 0.8 x 0.8 (ผู้เล่นขอยากขึ้นร้อยละ 20 สองรอบ 2026-10-12)
-- ตารางระดับใดก็ได้ (base) ที่มีโชคฐาน baseLuck (เบ็ดนากใช้ตารางของตัวเอง ดู CraftConfig.PET_TIER_WEIGHTS) 2026-10-10
function FishingConfig.TierWeightsFrom(base, baseLuck, luck)
	baseLuck = math.max(0.01, baseLuck or 1)
	local m = math.max(1, (luck or baseLuck) / baseLuck)
	return {
		Common = base.Common or 0,
		Rare = (base.Rare or 0) * math.sqrt(m),
		Legendary = (base.Legendary or 0) * m * FishingConfig.LEGENDARY_CHANCE_MULT,
		Secret = (base.Secret or 0) * m * FishingConfig.SECRET_CHANCE_MULT,
	}
end
function FishingConfig.RodWeights(rodId, luck)
	local rod = FishingConfig.Rods[rodId] or FishingConfig.Rods[FishingConfig.DEFAULT_ROD]
	local base = rod.TierWeights or FishingConfig.RarityWeights
	local m = math.max(1, (luck or rod.Luck) / rod.Luck)
	return {
		Common = base.Common or 0,
		Rare = (base.Rare or 0) * math.sqrt(m),
		Legendary = (base.Legendary or 0) * m * FishingConfig.LEGENDARY_CHANCE_MULT,
		Secret = (base.Secret or 0) * m * FishingConfig.SECRET_CHANCE_MULT,
	}
end

-- (เก่า ไม่ใช้แล้วในระบบตกปลา) โชค (เบ็ด/เหยื่อ): หายาก x โชค^0.5, ตำนาน x โชค, ลับ x โชค
function FishingConfig.WeightsWithLuck(luck)
	luck = math.max(1, luck or 1)
	local w = FishingConfig.RarityWeights
	return { Common = w.Common, Rare = w.Rare * math.sqrt(luck), Legendary = w.Legendary * luck, Secret = w.Secret * luck }
end

-- ราคาขายคูณตามดาว (ชุดเดียวกับผลผลิตในร้าน)
FishingConfig.STAR_PRICE = { 1.0, 1.3, 1.6, 2.0, 2.5 }

-- ขนาดสุ่ม: ตัวเล็กออกบ่อย ตัวใหญ่ออกยาก (u ^ SIZE_SKEW) แล้วแบ่งดาวตามสัดส่วนขนาดในช่วงของชนิดนั้น
-- ได้ประมาณ ★1 47% ★2 22% ★3 15% ★4 10% ★5 6%
FishingConfig.SIZE_SKEW = 1.6
FishingConfig.STAR_BANDS = { 0.3, 0.55, 0.75, 0.9 } -- ขนาดเกินสัดส่วนนี้ = ดาวถัดไป

function FishingConfig.StarFromFraction(frac)
	local star = 1
	for i, edge in ipairs(FishingConfig.STAR_BANDS) do
		if frac >= edge then star = i + 1 end
	end
	return star
end

-- Night = ออกเฉพาะกลางคืน (ดูเวลาในเกม Lighting.ClockTime)
FishingConfig.Fish = {
	-- 🏞️ คลอง
	Rasbora = { Name = "ปลาซิว", Zone = "canal", Rarity = "Common", Price = 12, Size = { 4, 10 } },
	ClimbingPerch = { Name = "ปลาหมอ", Zone = "canal", Rarity = "Common", Price = 16, Size = { 8, 20 } },
	Snakehead = { Name = "ปลาช่อน", Zone = "canal", Rarity = "Rare", Price = 70, Size = { 25, 70 }, Retired = true }, -- 2026-10-08 เลิกออก (ปลากัดแทน) ของที่มีอยู่ยังขาย/ทำอาหารได้ แต่ตกไม่ได้และไม่นับในสมุด
	-- ชุดใหม่ 2026-10-08 (สมุดรุ่น 2, 40 ชนิด) Hidden = true = ยังไม่เปิด (รอโมเดลใน ServerStorage.FishModels) ตกไม่ได้ ไม่โผล่ในสมุด/เมนูวาร์ป
	MudCarp = { Name = "ปลาสร้อย", Zone = "canal", Rarity = "Common", Price = 14, Size = { 8, 18 }, Hidden = false },
	WaterStrider = { Name = "จิงโจ้น้ำ", Zone = "canal", Rarity = "Common", Price = 10, Size = { 1, 3 }, Hidden = false },
	Betta = { Name = "ปลากัด", Zone = "canal", Rarity = "Rare", Price = 75, Size = { 4, 7 }, Hidden = false },
	SwampEel = { Name = "ปลาไหล", Zone = "canal", Rarity = "Rare", Price = 80, Size = { 30, 90 }, Hidden = false },
	StripedCatfish = { Name = "ปลาสวาย", Zone = "canal", Rarity = "Legendary", Price = 360, Size = { 60, 130 }, Hidden = false },
	RiverPrawn = { Name = "กุ้งแม่น้ำ", Zone = "canal", Rarity = "Secret", Price = 1600, Size = { 15, 35 }, Hidden = false },
	RainbowGuppy = { Name = "ปลาหางนกยูง", Zone = "canal", Rarity = "Secret", Price = 1700, Size = { 3, 6 }, Hidden = false },
	-- 🛶 ทะเลสาบ
	Tilapia = { Name = "ปลานิล", Zone = "lake", Rarity = "Common", Price = 18, Size = { 15, 40 } },
	SilverBarb = { Name = "ปลาตะเพียน", Zone = "lake", Rarity = "Common", Price = 20, Size = { 12, 35 } },
	Catfish = { Name = "ปลาดุก", Zone = "lake", Rarity = "Rare", Price = 65, Size = { 25, 60 } },
	Featherback = { Name = "ปลากราย", Zone = "lake", Rarity = "Rare", Price = 85, Size = { 30, 80 } },
	GiantCatfish = { Name = "ปลาบึก", Zone = "lake", Rarity = "Legendary", Price = 350, Size = { 150, 300 } },
	RedtailCatfish = { Name = "ปลาคัง", Zone = "lake", Rarity = "Legendary", Price = 380, Size = { 60, 130 }, Hidden = false },
	TigerFish = { Name = "ปลาเสือตอ", Zone = "lake", Rarity = "Secret", Price = 2400, Size = { 20, 45 }, Hidden = false },
	Python = { Name = "งูเหลือม", Zone = "lake", Rarity = "Secret", Price = 2600, Size = { 200, 600 }, Hidden = false },
	DragonLobster = { Name = "กุ้งมังกร", Zone = "lake", Rarity = "Secret", Price = 2500, Size = { 25, 60 }, Hidden = false },
	-- ⛰️ ลำธาร / บ่อนาขั้นบันได
	Goldfish = { Name = "ปลาทอง", Zone = "stream", Rarity = "Common", Price = 22, Size = { 6, 18 } },
	Koi = { Name = "ปลาคาร์ป", Zone = "stream", Rarity = "Rare", Price = 90, Size = { 30, 80 } },
	DragonKoi = { Name = "ปลาคาร์ปมังกร", Zone = "stream", Rarity = "Legendary", Price = 400, Size = { 60, 120 } },
	Leech = { Name = "ปลิง", Zone = "stream", Rarity = "Common", Price = 12, Size = { 3, 12 }, Hidden = false },
	RedTilapia = { Name = "ปลาทับทิม", Zone = "stream", Rarity = "Rare", Price = 75, Size = { 15, 40 }, Hidden = false },
	GlowSnail = { Name = "หอยทาก", Zone = "stream", Rarity = "Secret", Price = 2200, Size = { 2, 8 }, Hidden = false },
	-- 🌊 ทะเล
	Mackerel = { Name = "ปลาทู", Zone = "sea", Rarity = "Common", Price = 18, Size = { 15, 30 } },
	Seabass = { Name = "ปลากะพง", Zone = "sea", Rarity = "Common", Price = 25, Size = { 30, 80 } },
	Clownfish = { Name = "ปลาการ์ตูน", Zone = "sea", Rarity = "Rare", Price = 70, Size = { 6, 12 } },
	Squid = { Name = "ปลาหมึก", Zone = "sea", Rarity = "Rare", Price = 80, Size = { 15, 45 } },
	MantaRay = { Name = "ปลากระเบนราหู", Zone = "sea", Rarity = "Legendary", Price = 380, Size = { 200, 500 } },
	Lanternfish = { Name = "ปลาตะเกียง", Zone = "sea", Rarity = "Legendary", Price = 450, Size = { 5, 15 } }, -- 2026-10-03: ถอด Night = true เพราะเกมมีแต่กลางวัน (ไม่งั้นจับไม่ได้ สมุดปลาไม่มีวันครบ)
	-- ✨ ลับ
	RainbowWhale = { Name = "ปลาวาฬสีรุ้ง", Zone = "sea", Rarity = "Secret", Price = 2500, Size = { 300, 900 } },
	Shrimp = { Name = "กุ้ง", Zone = "sea", Rarity = "Common", Price = 15, Size = { 5, 15 }, Hidden = false },
	Crab = { Name = "ปู", Zone = "sea", Rarity = "Common", Price = 22, Size = { 8, 25 }, Hidden = false },
	SeaUrchin = { Name = "เม่นทะเล", Zone = "sea", Rarity = "Rare", Price = 70, Size = { 5, 12 }, Hidden = false }, -- 2026-10-10 ผู้ใช้ขอ: ธรรมดา 12 → หายาก 70
	Scallop = { Name = "หอยเชลล์", Zone = "sea", Rarity = "Rare", Price = 65, Size = { 6, 15 }, Hidden = false },
	Shark = { Name = "ฉลาม", Zone = "sea", Rarity = "Legendary", Price = 420, Size = { 100, 300 }, Hidden = false },
	Sunfish = { Name = "ปลาโมลาโมลา", Zone = "sea", Rarity = "Legendary", Price = 400, Size = { 100, 330 }, Hidden = false },
	Dugong = { Name = "พะยูน", Zone = "sea", Rarity = "Legendary", Price = 450, Size = { 200, 350 }, Hidden = false },
	Pufferfish = { Name = "ปลาปักเป้า", Zone = "sea", Rarity = "Secret", Price = 2300, Size = { 10, 40 }, Hidden = false },
	Dolphin = { Name = "โลมา", Zone = "sea", Rarity = "Secret", Price = 2800, Size = { 150, 300 }, Hidden = false },
	-- 🎉 ปลาอีเวนต์: ตกได้ทุกแหล่งน้ำเฉพาะช่วงอีเวนต์ที่มีชื่อปลาใน GachaConfig.Events[..].Fish (ไม่นับในสมุดครบเล่ม)
	NineTailKoi = { Name = "ปลาคาร์ปเก้าหาง", Zone = "any", Rarity = "Legendary", Price = 800, Size = { 40, 120 }, EventOnly = true, Festival = "NineTailFox" },
	-- 🎃 ปลาอีเวนต์ฮาโลวีน 2026 (2026-10-13 ผู้ใช้เลือก: หายาก / ตำนาน / ลับ ออกพร้อมผีน้อย) ผูกกับ GachaConfig.Events "Halloween_2026"
	PumpkinGoldfish = { Name = "ปลาทองฟักทอง", Zone = "any", Rarity = "Rare", Price = 120, Size = { 8, 20 }, EventOnly = true, Season = "GhostGacha2026" },
	GhostSquid = { Name = "หมึกผีน้อย", Zone = "sea", Rarity = "Legendary", Price = 800, Size = { 15, 45 }, EventOnly = true, Season = "GhostGacha2026" },
	CandyBatRay = { Name = "กระเบนค้างคาวลูกกวาด", Zone = "any", Rarity = "Secret", Price = 2600, Size = { 80, 200 }, EventOnly = true, Season = "GhostGacha2026" },
	VampireFish = { Name = "ปลาแวมไพร์", Zone = "any", Rarity = "Secret", Price = 2600, Size = { 20, 60 }, EventOnly = true, Season = "GhostGacha2026" }, -- ผู้ใช้ขอเพิ่ม 2026-10-13 (ลับ ทุกแหล่งน้ำ)
	-- 🌸 ปลาอีเวนต์ลอยกระทง 2026 (2026-10-29 ผู้ใช้เลือก: หายาก / ตำนาน / ลับ ราคาเท่าชุดฮาโลวีน) ไม่มีตู้สุ่ม ผูกกับ SeasonConfig "LoyKrathong2026" (FishEvent)
	KrathongFish = { Name = "ปลากระทง", Zone = "any", Rarity = "Rare", Price = 120, Size = { 8, 20 }, EventOnly = true, Season = "LoyKrathong2026" },
	GoldenWovenBarb = { Name = "ปลาตะเพียนทอง", Zone = "canal", Rarity = "Legendary", Price = 800, Size = { 15, 40 }, EventOnly = true, Season = "LoyKrathong2026" },
	SkyLanternFish = { Name = "ปลาโคมลอย", Zone = "any", Rarity = "Secret", Price = 2600, Size = { 20, 60 }, EventOnly = true, Season = "LoyKrathong2026" },
	-- 🗑️ ขยะจากน้ำ (โอกาสดู JUNK) ดาว 1 เสมอ ขายได้นิดหน่อย สัตว์กินไม่ได้ ไม่นับในสมุดปลา (มีแท็บขยะแยก)
	OldBoot = { Name = "รองเท้าเก่า", Zone = "any", Rarity = "Junk", Price = 4, Size = { 24, 32 }, Junk = true },
	TinCan = { Name = "กระป๋องเปล่า", Zone = "any", Rarity = "Junk", Price = 2, Size = { 10, 14 }, Junk = true },
	PlasticBottle = { Name = "ขวดพลาสติก", Zone = "any", Rarity = "Junk", Price = 2, Size = { 18, 25 }, Junk = true },
	OldTire = { Name = "ยางรถเก่า", Zone = "any", Rarity = "Junk", Price = 6, Size = { 50, 70 }, Junk = true },
	TornNet = { Name = "แหขาด", Zone = "any", Rarity = "Junk", Price = 3, Size = { 40, 90 }, Junk = true },
	-- ขยะชุดใหม่ 2026-10-08 · JunkWeight = น้ำหนักสุ่ม (ปกติ 1) · Valuable = ขยะมีค่า ออกยาก เก็บไว้เป็นวัตถุดิบโต๊ะช่างนากน้อยในอนาคต
	BambooScrap = { Name = "เศษไม้ไผ่", Zone = "any", Rarity = "Junk", Price = 3, Size = { 20, 60 }, Junk = true, Hidden = false },
	Straw = { Name = "หลอด", Zone = "any", Rarity = "Junk", Price = 1, Size = { 18, 22 }, Junk = true, Hidden = false },
	OldPhone = { Name = "โทรศัพท์เก่า", Zone = "any", Rarity = "Junk", Price = 8, Size = { 12, 16 }, Junk = true, Hidden = false },
	DiamondShard = { Name = "เศษเพชร", Zone = "any", Rarity = "Junk", Price = 60, Size = { 1, 3 }, Junk = true, Valuable = true, JunkWeight = 0.15, Hidden = false },
	RubyShard = { Name = "เศษทับทิม", Zone = "any", Rarity = "Junk", Price = 45, Size = { 1, 3 }, Junk = true, Valuable = true, JunkWeight = 0.25, Hidden = false },
}

-- ============ ชื่อภาษาอังกฤษ (หลายภาษา 2026-10-03: ภาษามาจาก LocaleId ของผู้เล่น ดู Localization) ============
-- ใช้ FishingConfig.FishName(id, lang) / ZoneName / RodName / RodDesc / RodShort / JunkName ; lang = "th" หรือ "en"
-- ปลา/เบ็ด/แหล่งน้ำใหม่ต้องใส่ En ด้วย (ไม่มีก็ถอยกลับไปใช้ชื่อไทย)
local FISH_EN = {
	Rasbora = "Rasbora", ClimbingPerch = "Climbing Perch", Snakehead = "Snakehead",
	Tilapia = "Tilapia", SilverBarb = "Silver Barb", Catfish = "Catfish", Featherback = "Featherback", GiantCatfish = "Giant Catfish",
	Goldfish = "Goldfish", Koi = "Koi", DragonKoi = "Dragon Koi",
	Mackerel = "Mackerel", Seabass = "Seabass", Clownfish = "Clownfish", Squid = "Squid", MantaRay = "Manta Ray", Lanternfish = "Lanternfish",
	RainbowWhale = "Rainbow Whale", NineTailKoi = "Nine-Tail Koi",
	PumpkinGoldfish = "Pumpkin Goldfish", GhostSquid = "Little Ghost Squid", CandyBatRay = "Candy Bat Ray", VampireFish = "Vampire Fish",
	KrathongFish = "Krathong Fish", GoldenWovenBarb = "Golden Woven Barb", SkyLanternFish = "Sky Lantern Fish",
	OldBoot = "Old Boot", TinCan = "Tin Can", PlasticBottle = "Plastic Bottle", OldTire = "Old Tire", TornNet = "Torn Net",
	-- ชุดใหม่ 2026-10-08
	MudCarp = "Siamese Mud Carp", WaterStrider = "Water Strider", Betta = "Betta", SwampEel = "Swamp Eel", StripedCatfish = "Striped Catfish",
	RiverPrawn = "Giant River Prawn", RainbowGuppy = "Rainbow Guppy",
	RedtailCatfish = "Redtail Catfish", TigerFish = "Siamese Tiger Fish", Python = "Reticulated Python", DragonLobster = "Dragon Lobster",
	Leech = "Leech", RedTilapia = "Red Tilapia", GlowSnail = "Glow Snail",
	Shrimp = "Shrimp", Crab = "Crab", SeaUrchin = "Sea Urchin", Scallop = "Scallop", Shark = "Shark", Sunfish = "Ocean Sunfish", Dugong = "Dugong",
	Pufferfish = "Pufferfish", Dolphin = "Dolphin",
	BambooScrap = "Bamboo Scrap", Straw = "Straw", OldPhone = "Old Phone", DiamondShard = "Diamond Shard", RubyShard = "Ruby Shard",
}
for id, en in pairs(FISH_EN) do
	if FishingConfig.Fish[id] then FishingConfig.Fish[id].En = en end
end
local ZONE_EN = { canal = "Canal", lake = "Lake", stream = "Stream", sea = "Sea" }
for id, en in pairs(ZONE_EN) do
	if FishingConfig.Zones[id] then FishingConfig.Zones[id].En = en end
end
local ROD_EN = {
	Bamboo = { "Bamboo Rod", "Bamboo", "The starter rod, free at the Fishing Shop · catches up to Rare fish" },
	Carrot = { "Carrot Rod", "Carrot", "A bright orange rod with carrot leaves on the handle · catches up to Rare fish (better odds)" },
	Kitty = { "Kitty Rod", "Kitty", "A kitten head on the handle, paw-print reel, golden bell on the tip · catches up to Legendary fish" },
	Candy = { "Candy Rod", "Candy", "Red-and-white candy stripes, lollipop reel, heart tip · catches up to Legendary fish (better odds)" },
	Rainbow = { "Rainbow Star Rod", "Rainbow", "A seven-colour rod with a glowing star tip that rare fish love · catches every tier, even Secret" },
	NightMoth = { "Butterfly Rod", "Butterfly", "A long, glowing moth-themed rod with a soft night aura · permanent unlock for 99 Robux" },
	SunBee = { "Little Bee Rod", "Little Bee", "A clover-wrapped branch with a glowing honeycomb, buzzing bees and a sunflower bobber · every fish is 3★ or better" },
	Phoenix = { "Phoenix Rod", "Phoenix", "A red-to-gold rod with fire-feather wings, a phoenix head on the tip, a fire-egg bobber, a fire phoenix flying around you and a flame aura · every fish is 3★ or better" },
	SakuraJelly = { "Sakura Jellyfish Rod", "Sakura Jelly", "A pearly pink rod with sakura blossoms, a glowing jellyfish on the grip, a tiny jellyfish bobber and a sakura jellyfish floating beside you · every fish is 3★ or better" },
	Froggy = { "Little Frog Rod", "Little Frog", "A spotted frog-skin rod with a pink ribbon, a little frog hugging it, a lily-pad reel, a lotus-bud tip and a lily-pad bobber with a tiny frog · permanent unlock for 99 Robux" },
	Dragonfly = { "Little Dragonfly Rod", "Little Dragonfly", "A blue lotus-stem rod with a dragonfly on the tip, a water-lily reel and a dragonfly flying around you · catches every tier, even Secret · craft-only at the Otter's Workshop" },
	EarthLove = { "Earth Love Rod", "Earth Love", "A leafy rod made from recycled things, with a tiny globe on the handle · every fish is 2 stars or better · craft-only at the Otter's Workshop" },
}
for id, e in pairs(ROD_EN) do
	local rod = FishingConfig.Rods[id]
	if rod then rod.DisplayNameEn, rod.ShortEn, rod.DescriptionEn = e[1], e[2], e[3] end
end

function FishingConfig.FishName(id, lang)
	local f = FishingConfig.Fish[id]
	if not f then return tostring(id) end
	return lang == "en" and (f.En or f.Name) or f.Name
end
function FishingConfig.ZoneName(zone, lang)
	local z = FishingConfig.Zones[zone]
	if not z then return tostring(zone) end
	return lang == "en" and (z.En or z.Name) or z.Name
end
function FishingConfig.RodName(rodId, lang)
	local r = FishingConfig.Rods[rodId]
	if not r then return tostring(rodId) end
	return lang == "en" and (r.DisplayNameEn or r.DisplayName) or r.DisplayName
end
function FishingConfig.RodDesc(rodId, lang)
	local r = FishingConfig.Rods[rodId]
	if not r then return "" end
	return lang == "en" and (r.DescriptionEn or r.Description) or r.Description
end
function FishingConfig.RodShort(rodId, lang)
	local r = FishingConfig.Rods[rodId]
	if not r then return tostring(rodId) end
	if lang == "en" and r.ShortEn then return r.ShortEn end
	return FishingConfig.RodShortName(rodId)
end
function FishingConfig.JunkName(lang) return lang == "en" and "Junk" or FishingConfig.JUNK.Name end

-- ============ มินิเกมดึงปลา ============
-- กดค้าง = กรอบจับเลื่อนไปทางขวา ปล่อย = ไหลกลับซ้าย คุมกรอบให้คลุมปลาที่ว่ายหนี
-- ZoneSize = ความกว้างกรอบ (สัดส่วนของแถบ), FishSpeed = ปลาว่ายเร็วแค่ไหน, FishJump = ปลาเปลี่ยนตำแหน่งบ่อยแค่ไหน
FishingConfig.Minigame = {
	Common = { ZoneSize = 0.30, FishSpeed = 0.45, FishJump = 0.35 },
	Rare = { ZoneSize = 0.25, FishSpeed = 0.65, FishJump = 0.5 },
	Legendary = { ZoneSize = 0.20, FishSpeed = 0.9, FishJump = 0.65 },
	Secret = { ZoneSize = 0.17, FishSpeed = 1.1, FishJump = 0.8 },
}
FishingConfig.Minigame.Junk = { ZoneSize = 0.4, FishSpeed = 0.3, FishJump = 0.2 } -- ขยะดึงง่าย

FishingConfig.MINIGAME = {
	FillRate = 0.30,      -- หลอดเพิ่มต่อวินาทีตอนกรอบคลุมปลา
	DrainRate = 0.20,     -- หลอดลดต่อวินาทีตอนหลุด
	StartProgress = 0.3,  -- หลอดเริ่มต้น
	TimeLimit = 20,       -- วินาที
	MinTime = 1.8,        -- เร็วกว่านี้ไม่นับ (กันโกง: หลอดเต็มเร็วสุดราว 2.3 วิ)
}

-- ============ ตกออโต้ "วางเบ็ดทิ้งไว้" ============
-- 2026-10-18 ผู้ใช้สั่ง: ตกปลามีแต่ออโต้ (ตัดมินิเกม ผู้เล่นเล่นยาก) และให้ได้เท่าตกเองเดิม (เดิม BiteTimeMult 1.5 / RareMult 0.5)
FishingConfig.AUTO = {
	BiteTimeMult = 1,    -- ปลากินช้าลง (1 = เท่าตกเองเดิม)
	RareMult = 1,        -- โอกาสหายาก/ตำนาน/ลับ (1 = เต็ม)
	CatchDelay = 1.0,    -- ปลากินแล้วดึงเองหลังกี่วินาที
}

-- ============ สมุดสะสมปลา ============
-- จับชนิดใหม่ครั้งแรก = โบนัสตามระดับ / จับครบทุกชนิดในแหล่งน้ำ = รางวัลแหล่งน้ำ / ครบทั้งเล่ม = รางวัลใหญ่
FishingConfig.ZONE_ORDER = { "canal", "lake", "stream", "sea" }
FishingConfig.INDEX = {
	FirstCatch = { Common = 100, Rare = 500, Legendary = 2000, Secret = 10000 },
	-- สมุดรุ่น 2 (40 ชนิด, 2026-10-08): รางวัลครบแหล่งน้ำ/ครบเล่มรับได้อีกครั้ง (FishIndex เก็บแยกเป็น zones2 / all2)
	-- รุ่น 1 เดิม: canal 3000, lake 8000, stream 5000, sea 20000, ครบเล่ม 50000
	Version = 2,
	ZoneReward = { canal = 6000, lake = 15000, stream = 8000, sea = 40000 },
	AllReward = 100000,
	-- Game Pass "ผ่านทันที" (2026-10-10): ซื้อแล้วปลดล็อกปลาทุกชนิดในสมุด + ได้รางวัลทั้งหมดทันที (โบนัสชนิดใหม่ ครบแหล่งน้ำ ครบเล่ม นาก)
	-- เจ้าของพาสได้สมุดครบเสมอ รวมปลาที่เพิ่มทีหลัง (FishIndex เช็กตอนเข้าเกม) · GAMEPASS_ID = 0 = ยังไม่เปิดขาย (ปุ่มไม่ขึ้น)
	SkipPass = { GAMEPASS_ID = 2026238507 }, -- Game Pass "สะสมปลาครบ 40" 435 R$ (เจ้าของเกมให้รหัส 2026-10-11) 0 = ไม่ขาย ซ่อนปุ่ม
	PetReward = { Count = 999, Pet = "Otter" }, -- จับครบทุกชนิดในสมุด (ไม่นับปลาอีเวนต์/ขยะ) ได้นากน้อยนักตกปลา · Count ตั้งท้ายไฟล์ = จำนวนชนิดทั้งหมด
}
local RARITY_RANK = { Common = 1, Rare = 2, Legendary = 3, Secret = 4 }
-- รายชื่อปลาเรียงตามเล่ม: แหล่งน้ำ -> ระดับ -> ราคา  (zone = nil = ทั้งหมด)
function FishingConfig.IndexList(zone)
	local list = {}
	for id, fish in pairs(FishingConfig.Fish) do
		if not fish.EventOnly and not fish.Junk and not fish.Hidden and not fish.Retired and (zone == nil or fish.Zone == zone) then table.insert(list, id) end
	end
	local zoneRank = {}
	for i, z in ipairs(FishingConfig.ZONE_ORDER) do zoneRank[z] = i end
	table.sort(list, function(x, y)
		local fx, fy = FishingConfig.Fish[x], FishingConfig.Fish[y]
		if fx.Zone ~= fy.Zone then return (zoneRank[fx.Zone] or 99) < (zoneRank[fy.Zone] or 99) end
		if fx.Rarity ~= fy.Rarity then return RARITY_RANK[fx.Rarity] < RARITY_RANK[fy.Rarity] end
		if fx.Price ~= fy.Price then return fx.Price < fy.Price end
		return x < y
	end)
	return list
end

-- ============ ขยะ ============
-- โอกาสได้ขยะแทนปลา = Chance / โชค (เบ็ด + เหยื่อ) เบ็ดดีขยะน้อยลง: ไม้ไผ่ 12% ... ดาวรุ้ง 4%
FishingConfig.JUNK = { Chance = 0.12, Name = "ขยะ", Color = Color3.fromRGB(150, 115, 80) }
function FishingConfig.JunkChance(luck)
	return FishingConfig.JUNK.Chance / math.max(1, luck or 1)
end
function FishingConfig.JunkList()
	local list = {}
	for id, fish in pairs(FishingConfig.Fish) do
		if fish.Junk and not fish.Hidden then table.insert(list, id) end
	end
	table.sort(list, function(x, y)
		local fx, fy = FishingConfig.Fish[x], FishingConfig.Fish[y]
		if fx.Price ~= fy.Price then return fx.Price < fy.Price end
		return x < y
	end)
	return list
end
-- สุ่มขยะ 1 ชิ้นตาม JunkWeight (ปกติ 1 ขยะมีค่าออกยากกว่า) r = เลขสุ่ม 0..1
-- valuableMult = คูณน้ำหนักของขยะมีค่า (Valuable) อีเวนต์เก็บขยะใช้ให้เศษเพชร/ทับทิมออกบ่อยขึ้น (ดู TrashEventConfig) ไม่ใส่ = 1
function FishingConfig.PickJunk(r, valuableMult)
	local list = FishingConfig.JunkList()
	local function weightOf(id)
		local fish = FishingConfig.Fish[id]
		return (fish.JunkWeight or 1) * (fish.Valuable and valuableMult or 1)
	end
	local total = 0
	for _, id in ipairs(list) do total += weightOf(id) end
	local x = r * total
	for _, id in ipairs(list) do
		x -= weightOf(id)
		if x <= 0 then return id end
	end
	return list[#list]
end

-- ยังมีปลาที่ซ่อนอยู่ไหม (zone = nil = ทั้งเล่ม) — ซ่อนอยู่ = ยังไม่ให้รางวัลครบแหล่ง/ครบเล่ม/นาก (กันได้รางวัลก่อนเปิดครบชุด)
function FishingConfig.HasHidden(zone)
	for _, fish in pairs(FishingConfig.Fish) do
		if fish.Hidden and not fish.Junk and (zone == nil or fish.Zone == zone) then return true end
	end
	return false
end

-- ============ ปลาอีเวนต์ ============
-- ป้ายเทศกาลในการ์ดสมุดปลา (2026-11-06): คีย์ = fish.Festival หรือ fish.Season · เพิ่มเทศกาลใหม่ให้เพิ่มบรรทัดที่นี่ด้วย
-- Order = ลำดับชุดในแท็บอีเวนต์ (เลขมากอยู่ก่อน ให้เทศกาลใหม่ใช้เลขถัดไป)
FishingConfig.FESTIVALS = {
	NineTailFox = { Name = "🦊 อีเวนต์จิ้งจอกเก้าหาง", En = "🦊 Nine-Tailed Fox Event", Order = 1 },
	GhostGacha2026 = { Name = "🎃 เทศกาลฮาโลวีน", En = "🎃 Halloween", Order = 2 },
	LoyKrathong2026 = { Name = "🌸 เทศกาลลอยกระทง", En = "🌸 Loy Krathong", Order = 3 },
}
function FishingConfig.FestivalName(id, lang)
	local f = FishingConfig.Fish[id]
	local festival = f and FishingConfig.FESTIVALS[f.Festival or f.Season]
	if not festival then return nil end
	return lang == "en" and festival.En or festival.Name
end

function FishingConfig.EventFishList()
	local list = {}
	-- Season = ซ่อนจากสมุดจนกว่าเทศกาลนั้นจะเริ่ม (SeasonConfig.HasStarted) กันสปอยล์ก่อนปล่อย; เริ่มแล้วอยู่ในสมุดตลอด (2026-10-13)
	local SeasonConfig = require(script.Parent:WaitForChild("SeasonConfig"))
	for id, fish in pairs(FishingConfig.Fish) do
		if fish.EventOnly and (not fish.Season or SeasonConfig.HasStarted(fish.Season)) then table.insert(list, id) end
	end
	-- เรียงเป็นชุดตามเทศกาล (2026-11-06 ผู้ใช้สั่ง): ชุดที่กำลังจัดอยู่ขึ้นก่อน > เทศกาลใหม่กว่า > ราคาถูกก่อน > ชื่อ (ลำดับคงที่)
	local active = FishingConfig.ActiveEventFish()
	local function festivalOrder(id)
		local f = FishingConfig.Fish[id]
		local festival = FishingConfig.FESTIVALS[f.Festival or f.Season]
		return festival and festival.Order or 0
	end
	table.sort(list, function(x, y)
		local ax, ay = active[x] ~= nil, active[y] ~= nil
		if ax ~= ay then return ax end
		local ox, oy = festivalOrder(x), festivalOrder(y)
		if ox ~= oy then return ox > oy end
		local px, py = FishingConfig.Fish[x].Price, FishingConfig.Fish[y].Price
		if px ~= py then return px < py end
		return x < y
	end)
	return list
end

-- ปลาอีเวนต์ที่ตกได้ตอนนี้ { [fishId] = event } (อีเวนต์เดียวกับตู้สุ่ม GachaConfig.Events)
-- + อีเวนต์ปลาอย่างเดียว (ไม่มีตู้สุ่ม, 2026-10-29 ลอยกระทง): เทศกาลใน SeasonConfig ที่มี FishEvent และกำลังทำงาน = ปลาที่ Season ตรงกันตกได้
function FishingConfig.ActiveEventFish(now)
	local GachaConfig = require(script.Parent:WaitForChild("GachaConfig"))
	local SeasonConfig = require(script.Parent:WaitForChild("SeasonConfig"))
	local event = GachaConfig.GetActiveEvent(now)
	local set = {}
	if event and event.Fish then
		for _, id in ipairs(event.Fish) do set[id] = event end
	end
	for id, fish in pairs(FishingConfig.Fish) do
		local season = fish.EventOnly and fish.Season and SeasonConfig.Seasons[fish.Season]
		if season and season.FishEvent and not set[id] and SeasonConfig.IsActive(fish.Season) then
			set[id] = season.FishEvent
			if not (event and event.Fish) then event = season.FishEvent end -- สมุดปลาแสดงชื่ออีเวนต์ที่มีปลา (ตู้สุ่มที่ไม่มีปลาไม่นับ)
		end
	end
	return set, event
end

-- กลางคืน (ช่วงเดียวกับไฟโคมในแมพ)
function FishingConfig.IsNight(clockTime)
	return clockTime >= 18.2 or clockTime < 6.3
end

function FishingConfig.GetPrice(fishId, star)
	local fish = FishingConfig.Fish[fishId]
	if not fish then return 0 end
	return math.floor(fish.Price * (FishingConfig.STAR_PRICE[star] or 1) + 0.5)
end

function FishingConfig.GetRod(rodId)
	return FishingConfig.Rods[rodId] or FishingConfig.Rods[FishingConfig.DEFAULT_ROD]
end

-- ============ น้ำหนักปลา (กก.) ============
-- ข้อมูลยังเก็บเป็น "ขนาด" เหมือนเดิม (ใช้คิดดาว/สถิติในสมุดปลา) แต่หน้าจอแสดงเป็นน้ำหนักแทน ซม.
-- แปลงตามสัดส่วนขนาดในช่วงของชนิดนั้น: ตัวเล็กสุด = น้ำหนักต่ำสุด, ตัวใหญ่สุด = น้ำหนักสูงสุด
local WEIGHT_KG = {
	Rasbora = { 0.01, 0.05 }, ClimbingPerch = { 0.05, 0.4 }, Snakehead = { 0.5, 6 },
	Tilapia = { 0.2, 2.5 }, SilverBarb = { 0.1, 1.5 }, Catfish = { 0.3, 3 }, Featherback = { 0.5, 5 }, GiantCatfish = { 60, 300 },
	Goldfish = { 0.02, 0.3 }, Koi = { 1, 12 }, DragonKoi = { 6, 35 },
	Mackerel = { 0.1, 0.5 }, Seabass = { 0.6, 9 }, Clownfish = { 0.01, 0.06 }, Squid = { 0.2, 2.5 },
	MantaRay = { 150, 1500 }, Lanternfish = { 0.01, 0.08 },
	RainbowWhale = { 3000, 30000 },
	NineTailKoi = { 3, 30 },
	PumpkinGoldfish = { 0.05, 0.4 }, GhostSquid = { 0.2, 2.5 }, CandyBatRay = { 10, 120 }, VampireFish = { 0.3, 4 },
	KrathongFish = { 0.05, 0.4 }, GoldenWovenBarb = { 0.2, 1.5 }, SkyLanternFish = { 0.3, 3 },
	OldBoot = { 0.4, 1.2 }, TinCan = { 0.02, 0.06 }, PlasticBottle = { 0.02, 0.05 }, OldTire = { 5, 10 }, TornNet = { 0.5, 2.5 },
	-- ชุดใหม่ 2026-10-08 (ตัวเล็กมากอย่างจิงโจ้น้ำ/ปลิง/หอยทาก/หางนกยูง/หลอด/เศษพลอย ไม่ใส่ = แสดงเป็น ซม.)
	MudCarp = { 0.02, 0.15 }, Betta = { 0.01, 0.03 }, SwampEel = { 0.2, 1.5 }, StripedCatfish = { 5, 40 }, RiverPrawn = { 0.1, 0.5 },
	RedtailCatfish = { 5, 30 }, TigerFish = { 0.5, 3 }, Python = { 20, 120 }, DragonLobster = { 0.5, 4 },
	RedTilapia = { 0.2, 2 },
	Shrimp = { 0.01, 0.05 }, Crab = { 0.1, 1.5 }, SeaUrchin = { 0.05, 0.3 }, Scallop = { 0.05, 0.3 }, Shark = { 30, 400 },
	Sunfish = { 200, 2000 }, Dugong = { 250, 500 }, Pufferfish = { 0.2, 3 }, Dolphin = { 100, 300 },
	BambooScrap = { 0.1, 0.5 }, OldPhone = { 0.12, 0.2 },
}
for id, w in pairs(WEIGHT_KG) do
	if FishingConfig.Fish[id] then FishingConfig.Fish[id].Weight = w end
end

function FishingConfig.WeightKg(fishId, size)
	local fish = FishingConfig.Fish[fishId]
	if not (fish and fish.Weight and fish.Size) then return nil end
	local s0, s1 = fish.Size[1], fish.Size[2]
	local frac = (s1 > s0) and math.clamp(((size or s0) - s0) / (s1 - s0), 0, 1) or 0
	return fish.Weight[1] + (fish.Weight[2] - fish.Weight[1]) * frac
end

local function withCommas(n)
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- ข้อความน้ำหนัก เช่น "0.35 กก." / "4.2 กก." / "1,250 กก." (ชนิดที่ไม่มีข้อมูลน้ำหนัก กลับไปแสดง ซม.)
function FishingConfig.FormatWeight(fishId, size, lang)
	local en = lang == "en"
	local kgUnit = en and " kg" or " กก."
	local kg = FishingConfig.WeightKg(fishId, size)
	if not kg then return string.format("%.1f", size or 0) .. (en and " cm" or " ซม.") end
	if kg < 1 then return string.format("%.2f", kg) .. kgUnit end
	if kg < 100 then return string.format("%.1f", kg) .. kgUnit end
	return withCommas(kg) .. kgUnit
end

-- นากน้อยนักตกปลา: ต้องสะสมปลาครบทุกชนิดในสมุด (เพิ่มปลาใหม่เมื่อไหร่ จำนวนนี้เพิ่มตามเอง · คนที่ได้นากไปแล้วไม่โดนยึด)
-- ============ สวิตช์หลักปลาชุดใหม่ 40 ชนิด (2026-10-08) ============
-- false = เกมเหมือนเดิมทุกอย่าง (ปลาช่อนยังตกได้ รางวัลสมุดรุ่น 1 ปลาใหม่ซ่อนหมด) Publish งานอื่นระหว่างทำโมเดลได้ปลอดภัย
-- true  = เปิดสมุดรุ่น 2 (ตั้งตอนโมเดลครบและเอา Hidden ออกทุกตัวแล้วเท่านั้น)
-- ทดสอบใน Studio: ตั้ง Attribute DevFishV2 = true ที่ workspace (ในเกมจริงไม่มีผล)
FishingConfig.FISH_V2 = true -- 2026-10-12 เปิดใช้จริงตามที่เจ้าของเกมสั่ง (เตรียม Publish) · ปิดกลับ = false
do
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() and workspace:GetAttribute("DevFishV2") == true then FishingConfig.FISH_V2 = true end
end
if not FishingConfig.FISH_V2 then
	FishingConfig.Fish.Snakehead.Retired = nil
	for _, fish in pairs(FishingConfig.Fish) do
		if fish.Hidden ~= nil then fish.Hidden = true end -- ปลา/ขยะชุดใหม่ซ่อนทั้งหมด (แม้ตัวที่ทำเสร็จแล้ว)
	end
	FishingConfig.INDEX.Version = 1
	FishingConfig.INDEX.ZoneReward = { canal = 3000, lake = 8000, stream = 5000, sea = 20000 }
	FishingConfig.INDEX.AllReward = 50000
	function FishingConfig.HasHidden() return false end -- ไม่กันรางวัล (กติกาเดิม)
end

FishingConfig.INDEX.PetReward.Count = #FishingConfig.IndexList()

-- ============ XP ตอนตกปลาได้ (ผู้เล่นขอ 2026-10-03: ตกปลาก็ได้เลเวล) ============
-- XP = ฐานตามความหายาก + ดาว x PerStar (ขยะได้ค่าคงที่) เทียบกับเก็บพืช: ดาว x 10 (ปลาธรรมดา 3 ดาว = 30 = พืช 3 ดาว)
-- นากตกให้ ได้ AutoMult เซิร์ฟเวอร์ (FishingSystem) เป็นคนให้ XP · ผู้เล่นตกออโต้ได้ XP เต็มตั้งแต่ 2026-10-18 (เหลือแต่ตกออโต้)
FishingConfig.XP = {
	Junk = 5,
	ByRarity = { Common = 15, Rare = 30, Legendary = 60, Secret = 150 },
	PerStar = 5,
	AutoMult = 0.5,
}

function FishingConfig.CatchXP(fishId, star, auto)
	local fish = FishingConfig.Fish[fishId]
	if not fish then return 0 end
	local X = FishingConfig.XP
	local xp
	if fish.Junk then
		xp = X.Junk
	else
		xp = (X.ByRarity[fish.Rarity] or X.ByRarity.Common) + (tonumber(star) or 1) * X.PerStar
	end
	if auto then xp = xp * X.AutoMult end
	return math.max(1, math.floor(xp + 0.5))
end

return FishingConfig
