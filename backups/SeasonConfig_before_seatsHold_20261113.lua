-- BACKUP 2026-11-13 before holding the 3 new seats behind the NewSeats2026 switch
-- Studio path: ReplicatedStorage.SeasonConfig
-- Restore: open that script in Studio, replace its whole Source with everything below the line of dashes.
-- ------------------------------------------------------------
-- SeasonConfig: สวิตช์เทศกาล ที่เดียวคุมทั้งแพตช์ (ใช้ร่วมกันทั้งเซิร์ฟเวอร์และฝั่งผู้เล่น)
-- เทศกาล "ทำงาน" เมื่อ Enabled = true และเวลาเซิร์ฟเวอร์อยู่ในช่วง StartUtc..EndUtc (เวลา UTC = เวลาไทย - 7 ชม.)
-- สิ่งที่ผูกกับเทศกาล (ชื่อเดียวกัน):
--   สกินหุ่นดวงดี  -> ReplicatedStorage.LuckConfig.BoosterSkins[<ชื่อ>]
--   ของตกแต่งในแมพ -> ServerStorage.SeasonalDecor[<ชื่อ>] (ServerScriptService.SeasonalDecor ยกไปวาง/เก็บให้เอง)
--   โคมไฟริมทาง + ขอบแปลงปลูก -> ค่า Lanterns / Plots ข้างล่าง + ชิ้นส่วนใน ServerStorage.SeasonalProps[<ชื่อ>] (สคริปต์เดียวกันเปลี่ยนให้ตอนเทศกาลทำงาน แล้วคืนของเดิมเมื่อจบ; ไม่แก้ของจริงในไฟล์เกม)
-- ปล่อยเทศกาล: เปลี่ยน Enabled เป็น true แล้ว Publish / เทศกาลผ่านไปจะหายเองตาม EndUtc (หรือปิดทันทีโดยใส่ false)
-- ลองดูใน Studio โดยไม่ต้องเปิด Enabled: ตั้ง Attribute DevForceSeason = "<ชื่อ>" บน ReplicatedStorage ก่อนกด Play (มีผลเฉพาะใน Studio)
--   หลายชื่อคั่นด้วยจุลภาคได้ เช่น "Halloween2026,GhostGacha2026"

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeasonConfig = {}

SeasonConfig.Seasons = {
	Halloween2026 = {
		Enabled = true, -- 2026-10-14 ผู้ใช้สั่งเปิด (Publish เที่ยงคืน)
		StartUtc = DateTime.fromUniversalTime(2026, 10, 14, 17, 0, 0).UnixTimestamp, -- 15 ต.ค. 2026 00:00 เวลาไทย (เดิม 24 ต.ค. เลื่อนมาพร้อมตู้สุ่มผีน้อย)
		EndUtc = DateTime.fromUniversalTime(2026, 10, 31, 17, 0, 0).UnixTimestamp,    -- ถึง 31 ต.ค. 2026 23:59 เวลาไทย (ผู้ใช้สั่ง 2026-10-31 เดิมสิ้นวัน 2 พ.ย.) ทุกอย่างของเทศกาลจบพร้อมกัน
		-- ของตกแต่งในแมพ + สกิน (โคม/ขอบแปลง/ต้นไม้/ร้าน/เปลี่ยนสี) จบก่อน: 1 พ.ย. 2026 00:00 เวลาไทย (ผู้ใช้สั่ง 2026-10-31) ของอื่นที่ผูกเทศกาลนี้ (เมล็ดเบอร์รี่แม่มด ไม้กวาด/หมวกในตู้สัตว์ขี่ ไก่ฟักทอง เพลง) ยังจบตาม EndUtc
		DecorEndUtc = DateTime.fromUniversalTime(2026, 10, 31, 17, 0, 0).UnixTimestamp,
		-- โคมไฟริมทาง (Model ชื่อ Lantern): ซ่อนตัวโคมเดิม ห้อยหัวฟักทอง (SeasonalProps.Halloween2026.LanternHead) แทน แสงเป็นสีส้ม ลบทั้งบรรทัด = ไม่เปลี่ยนโคม
		Lanterns = { Head = "LanternHead", LightColor = Color3.fromRGB(255, 150, 60) },
		-- ขอบแปลงปลูก (workspace.FarmDressing.RaisedBeds.*_Edging): ทาสีคาน/เสามุม/ป้าย + วางฟักทอง (PostTopper) บนเสามุมทแยง 2 ต้นและบนป้าย ตัวดินและพืชไม่เปลี่ยน ลบทั้งบรรทัด = ไม่เปลี่ยนแปลง
		-- ต้นไม้: สลับต้นที่ใช้เมชนี้ (MeshId เดิม) เป็นชิ้นใน SeasonalProps.Halloween2026 ชื่อทางขวา (รูปทรงเดิม ลายใหม่) ต้นเดิมถูกซ่อนไว้แล้วคืนตอนจบ
		--   ต้นชมพู -> ต้นใบม่วงประดับดาว (ต้นมะม่วง + ต้นเหลืองคงเดิม) ลบทั้งบรรทัด = ไม่เปลี่ยนต้นไม้
		--   2026-10-15 ผู้ใช้สั่งปิดต้นลูกอม (ต้นมะม่วง -> Tree_Candy ลายจุดดูเหมือนเห็ด) ถ้าจะเปิดคืน: เพิ่ม ["rbxassetid://96122743898590"] = "Tree_Candy"
		Trees = { ["rbxassetid://98262133568878"] = "Tree_PurpleStar" },
		-- ร้านค้า/พ่อค้า/ร้านตกปลา: สลับแบบเดียวกับต้นไม้ (หาใน workspace.Shops และ workspace.FishingShop) รูปทรงเดิม ลายฮาโลวีนสีม่วง-ส้ม
		--   Follow = true: ชิ้นเทศกาลขยับตามชิ้นเดิมทุกเฟรมฝั่งผู้เล่น (พ่อค้าหันมองผู้เล่น ดู ShopMerchantFx / SeasonalDecorFx)
		Swaps = {
			["rbxassetid://94527307330072"] = "Shop_Awning",
			["rbxassetid://83899084132053"] = "Shop_Counter",
			["rbxassetid://132609192888703"] = { Prop = "Shop_Merchant", Follow = true },
			["rbxassetid://83898418298628"] = "Fish_Stall",
			-- ตู้สุ่มสัตว์ + เครื่องทำอาหารสัตว์ (Follow เผื่อสคริปต์เขย่า/ขยับตัวเครื่อง)
			["rbxassetid://133785963550282"] = { Prop = "Gacha_Machine", Follow = true },
			["rbxassetid://135204997777614"] = { Prop = "PetFood_Machine", Follow = true },
		},
		Plots = { Topper = "PostTopper",
			BeamColor = Color3.fromRGB(96, 62, 128), PostColor = Color3.fromRGB(235, 130, 40), SignColor = Color3.fromRGB(120, 80, 160) },
		-- ของที่ประกอบจากชิ้นส่วน (ไม่ใช่เมชเดียว): เปลี่ยนสีตามสีเดิม ("r,g,b") ตอนเทศกาลทำงาน ดู ServerScriptService.SeasonalDecor applyRecolors (2026-10-13)
		--   โต๊ะช่างนากน้อย: ชมพู -> ส้ม, ชมพูเข้ม -> ม่วง, ชมพูอ่อน -> ลาเวนเดอร์, แถบขาวของกันสาด/ผ้าคลุมโต๊ะ -> ม่วง (ลายส้มสลับม่วง), ฟักทองลูกเล็กบนหัวเสากันสาด 2 ต้น ลบทั้งก้อน = ไม่เปลี่ยน
		Recolors = {
			{ Path = "OtterCraftBench", FrontPart = "PromptPart", Topper = "PostTopper", TopperScale = 0.7, TopperOn = { PostCap = true },
				Colors = {
					["255,150,188"] = Color3.fromRGB(255, 150, 70),
					["240,110,160"] = Color3.fromRGB(130, 85, 180),
					["255,214,228"] = Color3.fromRGB(226, 208, 245),
				},
				ByName = {
					Stripe = { ["255,250,248"] = Color3.fromRGB(150, 105, 200) },
					Scallop = { ["255,250,248"] = Color3.fromRGB(150, 105, 200) },
					Drape = { ["255,250,248"] = Color3.fromRGB(150, 105, 200) },
					DrapeScallop = { ["255,250,248"] = Color3.fromRGB(150, 105, 200) },
				},
			},
			-- เวที + บาร์ริมหาด (2026-10-14 ผู้ใช้ขอ): สีพาสเทลเดิม ฟ้า -> ม่วง, เขียวมิ้นท์ -> เขียวมะนาว, ชมพู -> ส้ม, เหลือง -> เหลืองส้ม (ฉากหลัง ร่ม เก้าอี้ ไฟประดับ ขวดบนชั้นบาร์ กลอง) ส่วนไม้ หลังคา ป้าย คงเดิม
			{ Path = "IslandDecor.BeachStage",
				Colors = {
					["140,200,250"] = Color3.fromRGB(150, 105, 200),
					["150,225,200"] = Color3.fromRGB(175, 220, 120),
					["255,170,190"] = Color3.fromRGB(255, 150, 70),
					["255,225,130"] = Color3.fromRGB(255, 200, 90),
				},
			},
		},
	},

	-- อีเวนต์ตู้สุ่ม "ผีน้อยนักปักหุ่น" (2026-10-11 ผู้ใช้ขอให้สุ่มได้ต่อจากจิ้งจอกเก้าหาง แยกสวิตช์จากของตกแต่งฮาโลวีน)
	-- คุม: อีเวนต์ใน ReplicatedStorage.GachaConfig.Events "Halloween_2026" + การมองเห็นของ PetDefinitions.ScarecrowGhost (ก่อนเริ่ม = ซ่อนทั้งตัว)
	-- เริ่มต่อจากอีเวนต์จิ้งจอกเก้าหาง (จบเที่ยงคืน 15 ต.ค.) ถึงสิ้นวัน 2 พ.ย. ปล่อย: เปลี่ยน Enabled เป็น true แล้ว Publish (เริ่มเองเมื่อถึงวัน)
	GhostGacha2026 = {
		Enabled = true, -- 2026-10-14 ผู้ใช้สั่งเปิด (Publish เที่ยงคืน)
		StartUtc = DateTime.fromUniversalTime(2026, 10, 14, 17, 0, 0).UnixTimestamp, -- 15 ต.ค. 2026 00:00 เวลาไทย (ต่อจากจิ้งจอกเก้าหางพอดี)
		EndUtc = DateTime.fromUniversalTime(2026, 10, 31, 17, 0, 0).UnixTimestamp,    -- ถึง 31 ต.ค. 2026 23:59 เวลาไทย (ผู้ใช้สั่ง 2026-10-31 เดิมสิ้นวัน 2 พ.ย.)
	},

	-- อีเวนต์ตู้สุ่ม "จริงใจ" จิงโจ้ (2026-10-29 ผู้ใช้ขอให้เป็นสัตว์ตู้สุ่มตัวถัดไป แต่ยังไม่เอาเข้าเกมจริง)
	-- คุม: อีเวนต์ GachaConfig.Events "Jingjai_2026_11" + การมองเห็นของ PetDefinitions.Jingjai (ก่อนเริ่ม = ซ่อนทั้งตัว)
	--   + ผึ้งราชินี (PetDefinitions.QueenBee ตำนาน อยู่ในตู้ตลอดไปหลังเริ่ม) + สัตว์ขี่ใหม่ (MountConfig: ม้าก้านกล้วย Season, เจ้าทุย/วัวมอมอ/ทุยเผือก Release) · ระบบ end game ปลูกผักย้ายไปสวิตช์ FarmEndgame2026 แล้ว (2026-10-31)
	-- เริ่มต่อจากผีน้อย (จบเที่ยงคืน 1 พ.ย.) ถึงสิ้นวัน 23 พ.ย. ปล่อย: เปลี่ยน Enabled เป็น true แล้ว Publish · ลองใน Studio: DevForceSeason ใส่ "JingjaiGacha2026"
	-- ⚠️ ไม่ใช้แล้ว 2026-10-31: ผึ้งราชินีย้ายไปปล่อยพร้อมจริงใจจิงโจ้ (PetDefinitions.QueenBee.Season = "JingjaiGacha2026") สวิตช์นี้ไม่มีผลอะไร
	-- ผึ้งราชินี (PetDefinitions.QueenBee ระดับตำนาน 2026-10-29): สวิตช์ปล่อยตัว ไม่ใช่อีเวนต์ (เปิดแล้วอยู่ในตู้ระดับตำนานตลอดไป)
	-- ปิด = เกมจริงไม่เห็นทั้งตัว · ปล่อย: Enabled = true แล้ว Publish · ลองใน Studio: DevForceSeason ใส่ "QueenBeeRelease"
	QueenBeeRelease = {
		Enabled = false, -- ผู้ใช้เลือก 2026-10-29: อยู่ในตู้สุ่ม แต่ปิดไว้ก่อน
		StartUtc = DateTime.fromUniversalTime(2026, 10, 28, 17, 0, 0).UnixTimestamp, -- เปิดสวิตช์เมื่อไหร่ก็ออกทันที
		EndUtc = DateTime.fromUniversalTime(2100, 1, 1, 0, 0, 0).UnixTimestamp,
	},

	JingjaiGacha2026 = {
		Enabled = true, -- 2026-10-31 ผู้ใช้สั่งเปิด (เริ่มเอง 1 พ.ย. 00:00 ต่อจากผีน้อย)
		StartUtc = DateTime.fromUniversalTime(2026, 10, 31, 17, 0, 0).UnixTimestamp, -- 1 พ.ย. 2026 00:00 เวลาไทย (ต่อจากผีน้อยพอดี; ผู้ใช้สั่งเลื่อนจาก 3 พ.ย. 2026-10-31)
		EndUtc = DateTime.fromUniversalTime(2026, 11, 23, 17, 0, 0).UnixTimestamp,   -- ถึงสิ้นวัน 23 พ.ย. 2026 เวลาไทย
	},

	-- ระบบ end game ปลูกผัก (สมุดพืช / ผักกลายพันธุ์ / กระดานออเดอร์ / ประกวดผักยักษ์) ดู CropBookConfig.IsEnabled
	-- 2026-10-31 ผู้ใช้สั่ง: แยกเป็นแพตช์หน้า ไม่ปล่อยพร้อมจริงใจจิงโจ้แล้ว · สวิตช์ปล่อยตัว (HasStarted: เปิดแล้วอยู่ตลอดไป)
	-- ปล่อย: Enabled = true แล้ว Publish (+ รีสตาร์ตเซิร์ฟ เพราะกระดานออเดอร์/ป้ายประกวดเช็กตอนเซิร์ฟเริ่ม) · ลองใน Studio: DevForceSeason ใส่ "FarmEndgame2026"
	FarmEndgame2026 = {
		Enabled = false, -- รอผู้ใช้สั่งปล่อยในแพตช์หน้า
		StartUtc = DateTime.fromUniversalTime(2026, 10, 30, 17, 0, 0).UnixTimestamp, -- เปิดสวิตช์เมื่อไหร่ก็ออกทันที
		EndUtc = DateTime.fromUniversalTime(2100, 1, 1, 0, 0, 0).UnixTimestamp,
	},

	-- อีเวนต์ปลาลอยกระทง (2026-10-29 ผู้ใช้เลือกธีม): ปลาอีเวนต์อย่างเดียว ไม่มีตู้สุ่ม (วันลอยกระทงจริง 24 พ.ย. 2026)
	-- คุม: ปลาใน FishingConfig.Fish ที่ Season = "LoyKrathong2026" (ปลากระทง / ปลาตะเพียนทอง / ปลาโคมลอย) ดู FishingConfig.ActiveEventFish
	-- FishEvent = ชื่ออีเวนต์ที่แสดงในแท็บ 🎉 ของสมุดปลา · ปล่อย: Enabled = true แล้ว Publish · ลองใน Studio: DevForceSeason ใส่ "LoyKrathong2026"
	LoyKrathong2026 = {
		Enabled = true, -- 2026-11-06 ผู้ใช้สั่งเปิด เอาเข้ารอบนี้
		StartUtc = DateTime.fromUniversalTime(2026, 11, 6, 2, 0, 0).UnixTimestamp, -- 6 พ.ย. 2026 09:00 เวลาไทย (ผู้ใช้สั่ง 2026-11-06 แก้จาก 7 พ.ย. 00:00 เดิม 17 พ.ย.)
		EndUtc = DateTime.fromUniversalTime(2026, 11, 30, 17, 0, 0).UnixTimestamp,   -- ถึงสิ้นวัน 30 พ.ย. 2026 เวลาไทย
		FishEvent = { Id = "LoyKrathong_2026", Name = "🌸 อีเวนต์ลอยกระทง", NameEn = "🌸 Loy Krathong Event" },
	},

	-- กิจกรรมลอยกระทงที่ท่าน้ำ + ร้านแม่ค้ากระทง (2026-11-07 กำลังสร้าง) คุม: ReplicatedStorage.KrathongConfig / ServerScriptService.Krathong
	-- แยกจาก LoyKrathong2026 (เปิดอยู่แล้ว) กันของที่ยังทำไม่เสร็จหลุดตอน Publish · ปล่อย: Enabled = true · ลองใน Studio: DevForceSeason ใส่ "KrathongFloat2026"
	KrathongFloat2026 = {
		Enabled = false,
		StartUtc = DateTime.fromUniversalTime(2026, 11, 6, 17, 0, 0).UnixTimestamp, -- 7 พ.ย. 2026 00:00 เวลาไทย
		EndUtc = DateTime.fromUniversalTime(2026, 11, 30, 17, 0, 0).UnixTimestamp,   -- ถึงสิ้นวัน 30 พ.ย. 2026 เวลาไทย (พร้อมปลาอีเวนต์)
		-- ธีมลอยกระทง (2026-11-07 ผู้ใช้สั่ง "ทำธีมแปลงผักต่อ") ชิ้นส่วนใน ServerStorage.SeasonalProps.KrathongFloat2026 เปลี่ยนตอนรันแล้วคืนเองตอนจบ (ServerScriptService.SeasonalDecor)
		--   โคมไฟริมทาง -> หัวโคมล้านนา แสงส้มอุ่น + กระทงขนมปังใบเล็กที่โคนเสา · รั้ว/ขอบแปลง -> ราวชมพูบัว เสาทอง ป้ายครีม + กระทงดอกบัวบนเสามุม/ป้าย · ลบบรรทัด = ไม่เปลี่ยนส่วนนั้น
		Lanterns = { Head = "LanternHead", Base = "LanternBase", LightColor = Color3.fromRGB(255, 175, 105) },
		Plots = { Topper = "PostTopper",
			BeamColor = Color3.fromRGB(245, 160, 190), PostColor = Color3.fromRGB(225, 180, 80), SignColor = Color3.fromRGB(255, 240, 215) },
	},

	-- อีเวนต์ตู้สุ่ม "ตุ่นนักอนุรักษ์" (2026-11-06 ผู้ใช้สั่ง: เข้าตู้ 15 พ.ย. อยู่คู่จริงใจจิงโจ้ซึ่งไม่ใช่สัตว์เทศกาล = ลับ 2 ตัว) จบพร้อมอีเวนต์ลอยกระทง
	-- คุม: GachaConfig.Events "Platypus_2026_11" + การมองเห็นของ PetDefinitions.Platypus · ลองใน Studio: DevForceSeason ใส่ "PlatypusGacha2026"
	-- ⚠️ PetDefinitions อ่านตอนเซิร์ฟเริ่ม: เซิร์ฟที่เปิดค้างข้ามเวลาเริ่มต้องรีสตาร์ตถึงจะมีตัวนี้
	PlatypusGacha2026 = {
		Enabled = true,
		StartUtc = DateTime.fromUniversalTime(2026, 11, 14, 17, 0, 0).UnixTimestamp, -- 15 พ.ย. 2026 00:00 เวลาไทย
		EndUtc = DateTime.fromUniversalTime(2026, 11, 30, 17, 0, 0).UnixTimestamp,   -- ถึงสิ้นวัน 30 พ.ย. 2026 เวลาไทย
	},
}

-- ใน Studio: Attribute DevForceSeason บน ReplicatedStorage มีชื่อเทศกาลนี้ไหม (หลายชื่อคั่นด้วยจุลภาค)
local function isForced(seasonId)
	if not RunService:IsStudio() then return false end
	local value = ReplicatedStorage:GetAttribute("DevForceSeason")
	if type(value) ~= "string" then return false end
	for name in value:gmatch("[^,%s]+") do
		if name == seasonId then return true end
	end
	return false
end

-- ใน Studio: Attribute DevDisableSeason บน ReplicatedStorage = ปิดเทศกาลนี้แม้ถึงวัน (ทดสอบหลังเทศกาลจบ 2026-10-31) เกมจริงไม่อ่าน
local function isDevDisabled(seasonId)
	if not RunService:IsStudio() then return false end
	local value = ReplicatedStorage:GetAttribute("DevDisableSeason")
	if type(value) ~= "string" then return false end
	for name in value:gmatch("[^,%s]+") do
		if name == seasonId then return true end
	end
	return false
end

function SeasonConfig.IsActive(seasonId)
	local season = SeasonConfig.Seasons[seasonId]
	if not season then return false end
	if isDevDisabled(seasonId) then return false end
	if isForced(seasonId) then return true end
	local now = os.time()
	return season.Enabled == true and now >= season.StartUtc and now < season.EndUtc
end

-- ของตกแต่งในแมพ/สกินของเทศกาลนี้ยังแสดงอยู่ไหม (ServerScriptService.SeasonalDecor) = IsActive และยังไม่ถึง DecorEndUtc (ไม่ตั้ง = จบพร้อม EndUtc)
function SeasonConfig.IsDecorActive(seasonId)
	if not SeasonConfig.IsActive(seasonId) then return false end
	if isForced(seasonId) then return true end
	local season = SeasonConfig.Seasons[seasonId]
	return season.DecorEndUtc == nil or os.time() < season.DecorEndUtc
end

-- เทศกาลนี้ "เคยเริ่มแล้ว" หรือยัง (Enabled และถึงวันเริ่มแล้ว ไม่สนวันจบ) ใช้กับของที่ต้องอยู่ต่อหลังเทศกาลจบ
-- เช่น สัตว์เลี้ยงประจำเทศกาล (ก่อนเทศกาลเริ่ม = ซ่อนทั้งตัว, เทศกาลจบแล้วคนที่ได้ไปยังใช้ได้)
function SeasonConfig.HasStarted(seasonId)
	local season = SeasonConfig.Seasons[seasonId]
	if not season then return false end
	if isForced(seasonId) then return true end
	return season.Enabled == true and os.time() >= season.StartUtc
end

return SeasonConfig
