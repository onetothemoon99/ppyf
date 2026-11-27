-- BACKUP 2026-11-27 of ReplicatedStorage.GachaConfig (Studio) before the snow leopard event + featured rate.
-- Restore: paste everything below this header into ReplicatedStorage.GachaConfig.Source.
-- Source bytes 8929, hash 1285318337 (h=(h*31+byte)%2147483647)
-- GachaConfig: ตั้งค่าตู้สุ่มสัตว์เลี้ยง (ใช้ทั้งเซิร์ฟเวอร์และหน้าจอฝั่งผู้เล่น)
--
-- ตั๋วสุ่มที่ซื้อด้วย Robux (Developer Product)
-- วิธีตั้งค่า: สร้าง Developer Product ใน Creator Dashboard แล้วเอา ID มาใส่แทน 0 ด้านล่าง
-- ราคา Robux ตั้ง/แก้ใน Dashboard ได้เลย ไม่ต้องแก้โค้ด (Amount = จำนวนตั๋วที่ได้ต่อการซื้อ 1 ครั้ง)
-- ProductId = 0 คือยังไม่ได้สร้าง ระบบจะข้ามสินค้านั้นไป (ปุ่มซื้อจะยังไม่พร้อมใช้)

local GachaConfig = {}

-- ระดับที่ออกเฉพาะช่วงอีเวนต์ (นอกอีเวนต์ไม่อยู่ในตู้เลย)
GachaConfig.EVENT_RARITY = "Secret"

-- ตั๋ว 2 แบบ เก็บจำนวนแยกกัน อัตราออกต่างกัน (เปอร์เซ็นต์ รวมกัน 100)
--   Normal  = ซื้อด้วยเหรียญในเกม
--   Premium = ซื้อด้วย Robux (TicketProducts ด้านล่าง) อัตราออกดีกว่า
-- Odds      = นอกช่วงอีเวนต์ (ไม่มีลับ เรตของลับย้ายไปรวมที่ธรรมดา)
-- EventOdds = ช่วงอีเวนต์ (มีลับ)
-- Pity      = การันตี นับแยกตามแบบตั๋ว
--   Rare      = ทุกกี่ครั้งได้ "หายากขึ้นไป" แน่นอน
--   Legendary = ภายในกี่ครั้งได้ "ตำนาน" แน่นอน
--   Secret    = ภายในกี่ครั้งได้ "ลับ" แน่นอน (นับเฉพาะช่วงอีเวนต์ และสะสมข้ามอีเวนต์ได้)
-- ถ้าระดับไหนไม่มีสัตว์เลย ระบบตัดระดับนั้นออกแล้วเฉลี่ยอัตราใหม่เอง (ผู้เล่นไม่เสียตั๋วฟรี)
GachaConfig.TicketTypes = {
	Normal = {
		Order = 1,
		DisplayName = "ตั๋วธรรมดา",
		Icon = "🎟️",
		CoinPrice = 20000, -- เหรียญต่อ 1 ใบ
		Odds = { Common = 94.3, Rare = 5.1, Legendary = 0.6 },
		EventOdds = { Common = 94.1, Rare = 5.1, Legendary = 0.6, Secret = 0.2 },
		Pity = { Rare = 10, Legendary = 90, Secret = 200 },
	},
	Premium = {
		Order = 2,
		DisplayName = "ตั๋วพรีเมียม",
		Icon = "💎",
		Paid = true, -- สุ่มด้วยของที่จ่ายเงินจริง (ประเทศที่ Roblox ห้ามการสุ่มแบบจ่ายเงิน จะซื้อ/ใช้ไม่ได้)
		Odds = { Common = 91.5, Rare = 7, Legendary = 1.5 },
		EventOdds = { Common = 91, Rare = 7, Legendary = 1.5, Secret = 0.5 },
		Pity = { Rare = 10, Legendary = 50, Secret = 100 },
	},
}

-- ============ อีเวนต์ (ช่วงที่สัตว์ลับออกจากตู้) ============
-- เวลาเป็นเวลาไทย เริ่ม = เปิดตอนเที่ยงคืนของวันนั้น, จบ = ปิดตอนเที่ยงคืนของวันนั้น
-- ตู้สลับเข้า/ออกโหมดอีเวนต์เองตามเวลา ไม่ต้อง Publish ใหม่
-- SecretPets = สัตว์ลับที่ออกในอีเวนต์นี้ (ไม่ใส่ = สัตว์ลับทุกตัว)
local function thaiDate(year, month, day)
	return DateTime.fromUniversalTime(year, month, day, 0, 0, 0).UnixTimestamp - 7 * 3600
end

GachaConfig.Events = {
	-- 2026-11-01 ผู้ใช้สั่ง: เอาอีเวนต์ "Jingjai_2026_11" ออก จริงใจจิงโจ้อยู่ในตู้ตลอด ไม่ใช่ตัวอีเวนต์ (PetDefinitions.Jingjai.AlwaysInGacha) · สำเนาเดิม ServerStorage._Backup_20261101.GachaConfig_before_jingjaipermanent
	{
		Id = "NineTailFox_2026_09",
		Name = "🦊 อีเวนต์จิ้งจอกเก้าหาง",
		NameEn = "🦊 Nine-Tailed Fox Event",
		Start = thaiDate(2026, 9, 24),
		End = thaiDate(2026, 10, 15), -- 3 สัปดาห์
		SecretPets = { "NineTailFox" },
		Fish = { "NineTailKoi" }, -- ปลาอีเวนต์ (ตกได้เฉพาะช่วงนี้ ดู FishingConfig)
	},
	-- อีเวนต์ฮาโลวีน 2026: สัตว์ลับ = ผีน้อยนักปักหุ่น (PetDefinitions.ScarecrowGhost)
	-- Season = ผูกกับสวิตช์เทศกาลใน ReplicatedStorage.SeasonConfig (Enabled + ช่วงวันของเทศกาลเป็นตัวตัดสิน) สวิตช์ปิด = อีเวนต์นี้ไม่ทำงานแม้ถึงวัน
	-- Start/End ต้องตรงกับช่วงวันใน SeasonConfig (ใช้แสดงวันจบในหน้าตู้สุ่ม)
	{
		Id = "Halloween_2026",
		Name = "👻 อีเวนต์ฮาโลวีน: ผีน้อยนักปักหุ่น",
		NameEn = "👻 Halloween Event: Little Scarecrow Ghost",
		Season = "GhostGacha2026", -- สวิตช์แยกของผีน้อย (ไม่ผูกกับของตกแต่งฮาโลวีน) เริ่มต่อจากอีเวนต์จิ้งจอกเก้าหางทันที
		Start = thaiDate(2026, 10, 15),
		End = thaiDate(2026, 11, 1), -- ถึง 31 ต.ค. 23:59 (ผู้ใช้สั่ง 2026-10-31 เดิมสิ้นวัน 2 พ.ย.)
		SecretPets = { "ScarecrowGhost" },
		Fish = { "PumpkinGoldfish", "GhostSquid", "CandyBatRay", "VampireFish" }, -- ปลาอีเวนต์ฮาโลวีน (ตกได้เฉพาะช่วงนี้ ดู FishingConfig) 2026-10-13
	},
	-- อีเวนต์ลอยกระทง 2026: ตุ่นนักอนุรักษ์ (PetDefinitions.Platypus) ตู้สุ่มเข้า 15 พ.ย. จริงใจจิงโจ้ AlwaysInGacha ยังอยู่ในตู้ด้วย = ลับ 2 ตัว · ปลาลอยกระทงแยกอยู่ที่ SeasonConfig.LoyKrathong2026.FishEvent
	{
		Id = "Platypus_2026_11",
		Name = "🌸 อีเวนต์ลอยกระทง: ตุ่นนักอนุรักษ์",
		NameEn = "🌸 Loy Krathong Event: Conservation Platypus",
		Season = "PlatypusGacha2026",
		Start = thaiDate(2026, 11, 15),
		End = thaiDate(2026, 12, 1),
		SecretPets = { "Platypus" },
	},
}

local SeasonConfig = require(script.Parent:WaitForChild("SeasonConfig"))

function GachaConfig.GetActiveEvent(now)
	now = now or os.time()
	-- อีเวนต์ที่ผูกกับเทศกาลมาก่อน (เทศกาลทำงาน = อีเวนต์ทำงาน รวมตอนบังคับเปิดดูใน Studio)
	for _, event in ipairs(GachaConfig.Events) do
		if event.Season and SeasonConfig.IsActive(event.Season) then return event end
	end
	for _, event in ipairs(GachaConfig.Events) do
		if not event.Season and now >= event.Start and now < event.End then return event end
	end
	return nil
end

GachaConfig.MAX_ROLLS_PER_REQUEST = 10
GachaConfig.MAX_COIN_TICKETS_PER_BUY = 10
GachaConfig.ROLL_COOLDOWN = 1 -- วินาที กันกดรัว

-- ตั๋วพรีเมียมที่ซื้อด้วย Robux
GachaConfig.TicketProducts = {
	{ Id = "Ticket1", Amount = 1, ProductId = 3714474158, TicketType = "Premium" },   -- 💎 ตั๋วพรีเมียม 1 ใบ
	{ Id = "Ticket10", Amount = 10, ProductId = 3714474283, TicketType = "Premium" }, -- 💎 ตั๋วพรีเมียม 10 ใบ
}

function GachaConfig.GetTicketType(typeId)
	return GachaConfig.TicketTypes[typeId]
end

function GachaConfig.GetTicketProduct(productId)
	if not productId or productId == 0 then return nil end
	for _, product in ipairs(GachaConfig.TicketProducts) do
		if product.ProductId == productId then return product end
	end
	return nil
end

return GachaConfig
