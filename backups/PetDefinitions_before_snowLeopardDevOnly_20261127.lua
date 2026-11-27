-- BACKUP 2026-11-27 of ServerScriptService.PetSystem.PetDefinitions (Studio) before SnowLeopard DevOnly.
-- Restore: paste everything below this header into ServerScriptService.PetSystem.PetDefinitions.Source.
-- Source bytes 40295, hash 733596309 (h=(h*31+byte)%2147483647)
-- PetDefinitions: ข้อมูลของสัตว์เลี้ยงแต่ละตัว
-- เพิ่มสัตว์เลี้ยงตัวใหม่ในอนาคต แค่เพิ่ม entry ใหม่ในตารางนี้ ไม่ต้องแก้ไฟล์อื่นเลย
-- ความสามารถ "นำโชค" (Lucky) ใส่ให้เองอัตโนมัติกับทุกตัวที่ความหายากมีค่าโชคใน LuckConfig.PetLuckByRarity (ตำนาน / ลับ)
-- ตัวไหนจะตั้งค่าโชคเองให้ใส่ Luck = <เลข> (ใส่ให้ตัวระดับอื่นก็ได้ จะได้ความสามารถนำโชคเหมือนกัน)
local LuckConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("LuckConfig"))

local PetDefinitions = {
	PastelPinkRabbit = {
		DisplayName = "กระต่ายสีชมพู",
		Rarity = "Common", -- ความหายาก: Common (ธรรมดา) / Rare (หายาก) / Legendary (ตำนาน) / Secret (ลับ) ดู ReplicatedStorage.PetRarity
		TemplateFolder = "PetTemplates", -- โฟลเดอร์ใน ServerStorage ที่เก็บโมเดล
		WalkSpeed = 8,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		BoneNames = { -- ชื่อ Motor6D สำหรับแอนิเมชันเดินแบบ procedural (ปรับได้ต่อสัตว์เลี้ยงแต่ละตัว)
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint", -- สำหรับเด้งลำตัวขึ้นลงตามจังหวะกระโดด
			Tail = "Tail",
		},
		Abilities = { "Harvester" }, -- รายชื่อความสามารถ (ต้องตรงกับชื่อไฟล์ใน Abilities folder)
	},

	ChibiPanda = {
		DisplayName = "หมีแพนด้าน้อย",
		Rarity = "Rare",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 8,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
		},
		Abilities = { "Planter" }, -- แพนด้าช่วยปลูกอย่างเดียว (เอาช่วยเก็บเกี่ยวออกแล้ว)
	},

	ChibiCat = {
		DisplayName = "แมวน้อยน่ารัก",
		Rarity = "Common",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 8,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
		Tail = "Tail",
		},
		Abilities = { "Harvester" },
	},

	ChibiFox = {
		DisplayName = "สุนัขจิ้งจอกน้อย",
		Rarity = "Rare", -- เดิมธรรมดา (ปรับ 2026-09-24)
		TemplateFolder = "PetTemplates",
		WalkSpeed = 9,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Planter" }, -- ช่วยปลูกอย่างเดียว (เดิมช่วยเก็บเกี่ยว ปรับ 2026-09-24)
	},

	-- สัตว์เทพ: จิ้งจอกเก้าหาง (ระดับลับ) หาง 9 หางสีเดียวกับตัว + ออร่าทองส้มทั้งตัว + หิ่งห้อยทองส้ม 9 ตัวบินวนรอบตัว
	-- โมเดลอยู่ที่ ServerStorage.PetTemplates.NineTailFox (หางกลางสะบัดทั้งพัด อีก 8 หางมีข้อต่อ TailFan ของตัวเอง พลิ้วแยกกัน)
	NineTailFox = {
		DisplayName = "จิ้งจอกเก้าหาง",
		Description = "🦊 สัตว์เทพ: เก็บเกี่ยวได้ผลผลิต x2 · นำโชค x30 · หิวช้ากว่าปกติครึ่งหนึ่ง", -- แสดงในเมนูสัตว์เลี้ยง (ไม่ใส่ก็ได้)
		Rarity = "Secret",
		Luck = 30, -- ตั้งเอง (สูงกว่าค่าระดับลับใน LuckConfig.PetLuckByRarity ที่ยังเป็น 20)
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		RainbowAura = true, -- ไฟที่ติด Attribute "Rainbow" ไล่สีรุ้งเรื่อยๆ (ทำใน PetController)
		FireflyRing = true, -- วงแหวนหิ่งห้อยสีรุ้งบินวนรอบตัว แบบหุ่นข้าวโพด (วาดฝั่งผู้เล่นใน PetFireflyRing)
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Harvester" }, -- ช่วยเก็บเกี่ยวอย่างเดียว (เดิมใส่ Planter ไว้ด้วย เลยช่วยปลูกด้วย)
		HarvestMultiplier = 2, -- เก็บเกี่ยวแล้วได้ผลผลิต x2 (ความหิวช้า x0.5 มาจากระดับลับใน PetRarity)
		WorkSpeed = 1.3, -- ทำงานเร็วขึ้น 30% (รวมงานเก็บเกี่ยว)
	},

	-- ระดับตำนาน: แมวเก้าชีวิต แมวดำตาทอง ปลอกคอกระดิ่งทอง + ดวงไฟวิญญาณสีม่วง 9 ดวงบินวนรอบตัว
	-- ดวงไฟ = ชีวิตที่เหลือ: หิวจนหมดแรง (0%) จะฟื้นคืนชีพกลับมา 50% และดวงไฟหาย 1 ดวง ให้อาหารเมื่อไหร่กลับมาครบ (ดู PetHunger)
	-- โมเดลอยู่ที่ ServerStorage.PetTemplates.NineLivesCat (สร้างจากแมวน้อย เปลี่ยนลายหัว/หู/หางเป็นแมวดำ)
	NineLivesCat = {
		DisplayName = "แมวเก้าชีวิต",
		Description = "🐈‍⬛ 9 ชีวิต: หิวจนหมดแรงแล้วฟื้นเอง 50% (9 ครั้ง) · นำโชค x15 · หิวช้าลง 25%",
		Rarity = "Legendary",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 9,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		NineLives = 9, -- จำนวนชีวิต (ฟื้นเองตอนหิวจนหมดแรงได้เท่านี้ครั้ง)
		AuraDim = 0.9, -- 2026-11-19 AuraDim: ผู้ใช้สั่งลดความสว่างแมวเก้าชีวิต 10% (แสง/ประกาย/ขอบเรืองแสง ใน PetController + ดวงไฟม่วง 9 ดวงใน PetFireflyRing) เฉพาะตัวนี้ ไม่กระทบตำนานตัวอื่น
		FireflyRing = true, -- ดวงไฟวิญญาณบินวนรอบตัว (วาดฝั่งผู้เล่นใน PetFireflyRing) จำนวนดวง = ชีวิตที่เหลือ
		FireflyColors = { Color3.fromRGB(205, 150, 255), Color3.fromRGB(125, 70, 235) }, -- ม่วงอ่อน <-> ม่วงเข้ม
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Planter" }, -- ช่วยปลูกผัก (เดิมช่วยเก็บเกี่ยว) นำโชค x15 ใส่ให้เองจากความหายากตำนาน ดูท้ายไฟล์
	},
	WhiteTiger = {
		DisplayName = "เสือพยัคฆ์ขาว",
		Description = "🐅 เจ้าแห่งทิศตะวันตก: ว่องไว ทำงานเร็วขึ้น 30% · นำโชค x15 · หิวช้าลง 25%",
		Rarity = "Legendary",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 11, -- เดินเร็วกว่าตัวอื่น
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		WorkSpeed = 1.3, -- ทำงานเร็วขึ้น 30% (คูณกับโบนัสเลเวล ดู PetHunger.GetSpeed)
		FireflyRing = true, -- ลมพยัคฆ์: ดวงไฟขาวอมฟ้าบินวนรอบตัว (PetFireflyRing)
		FireflyCount = 5, -- จำนวนดวง (ไม่ใส่ = 9)
		FireflyColors = { Color3.fromRGB(160, 215, 255), Color3.fromRGB(60, 150, 255) }, -- ฟ้าอ่อน <-> ฟ้าเข้ม (เข้ากับขอบเรืองแสงสีฟ้า)
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Harvester" }, -- ช่วยเก็บเกี่ยว (นำโชค x15 ใส่ให้เองจากความหายากตำนาน)
	},

	-- นากน้อยนักตกปลา (ระดับตำนาน) ไม่อยู่ในตู้สุ่ม ได้จากสมุดสะสมปลาครบทุกชนิด (FishIndex / FishingConfig.INDEX.PetReward)
	-- ความสามารถ "ช่วยตกปลา" (Fisher): ตอนเจ้าของตกปลา เดินไปยืนริมน้ำ ถือเบ็ดของตัวเองตกปลาช่วย (ดู FishingSystem / FishingPetBonus)
	Otter = {
		DisplayName = "นากน้อยนักตกปลา",
		Description = "🦦 รางวัลสะสมปลาครบทุกชนิดในสมุด: เดินไปริมน้ำใกล้เรา ตกปลาเองได้ (ไม่ต้องถือเบ็ด) ปลาเข้ากระเป๋าเรา · นำโชค x15",
		Rarity = "Legendary",
		NotInGacha = true, -- ไม่ออกจากตู้สุ่ม
		UnlockHint = "📖 ได้จากสมุดสะสมปลา: จับปลาให้ครบทุกชนิด", -- แสดงในเมนูตอนยังไม่มี
		TemplateFolder = "PetTemplates",
		WalkSpeed = 9,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		BoneNames = { -- หูติดกับหัว (ไม่มีข้อต่อหู)
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Fisher" },
	},

	-- 👑 มังกรแดงสุลต่าน (ระดับสุลต่าน) ได้จากแพ็กสุลต่านเท่านั้น (SultanService ให้ตอนได้แพ็ก) ไม่อยู่ในตู้สุ่ม
	-- โมเดล ServerStorage.PetTemplates.SultanDragon (AI mesh 4 ชิ้น: ตัว/ปีกซ้าย/ปีกขวา/หาง ข้อต่อ LeftWing/RightWing/Tail)
	-- บินลอยตามเจ้าของ (Flying: กระพือปีก สะบัดหาง พ่นไฟเป็นพักๆ ดู PetController setupFlyAnimation)
	-- โบนัสตอนพาออกมา: ขายได้เงิน +10% (SellBonus -> Attribute PetSellBonus) / ผักของเจ้าของโตเร็วขึ้น 15% (GrowBoost -> PetGrowBoost)
	SultanDragon = {
		DisplayName = "มังกรแดงสุลต่าน",
		Description = "🔥 สัตว์สุลต่าน: บินได้ · ช่วยปลูกผัก · นำโชค x50 · ขายได้เงิน +10% · พ่นไฟให้ผักโตเร็วขึ้น 15%",
		Rarity = "Sultan",
		NotInGacha = true,
		UnlockHint = "👑 ได้จากแพ็กสุลต่านเท่านั้น",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 11,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		Flying = { Height = 1.8, WorkHeight = 0.7 }, -- ลอยสูงจากพื้น (studs) / ตอนทำงานโฉบลงต่ำ
		SellBonus = 0.10,
		GrowBoost = 0.15,
		Luck = 50,
		Abilities = { "Planter" }, -- ช่วยปลูกผัก (เดิมช่วยเก็บเกี่ยว ปรับ 2026-10-02)
		-- 2026-10-09 ผู้ใช้ขอ: ค่าพื้นฐานปลูกได้ ~100 ต้น/นาที (อิ่มเต็ม เลเวล 1 ช่องติดกัน) เดิม ~35
		--   ต่อต้น = หยิบเมล็ด 0.6 x PreTimeMult + ฝัง 1.0 / WorkSpeed + ขยับช่อง ~0.05 = 0.18 + 0.38 + 0.05 ≈ 0.6 วิ
		WorkSpeed = 2.6,
		PreTimeMult = 0.3, -- ย่นเวลาหยิบเมล็ด/ท่าเด้งก่อนทำงาน (ใช้ใน PetController)
	},

	-- 👻 ผีน้อยนักปักหุ่น (ระดับลับ) สัตว์ประจำอีเวนต์ฮาโลวีน 2026 ออกจากตู้สุ่มช่วงอีเวนต์ (GachaConfig.Events "Halloween_2026")
	-- Season = ซ่อนทั้งตัวจนกว่าเทศกาลนั้นจะเริ่ม (ReplicatedStorage.SeasonConfig.HasStarted ดูท้ายไฟล์) เทศกาลจบแล้วคนที่ได้ไปยังใช้ได้
	-- โมเดล ServerStorage.PetTemplates.ScarecrowGhost (AI mesh: ตัว/หมวกแม่มด/แขน + หุ่นทองคำนำโชคจิ๋วในมือ) หน้าหัน -Z
	-- ลอยตามเจ้าของแบบมังกร (Flying): ข้อต่อ LeftWing = แขนที่ว่างโบกขึ้นลง, RightWing = มือที่ถือหุ่นโบกหุ่นไปมา
	-- ความสามารถ "ช่วยปักหุ่น" (ScarecrowPlacer): หยิบหุ่นดวงดีจากแถบช่องลัดของเจ้าของ (ไม่หยิบจากกระเป๋า 2026-10-14) ไปปักตรงจุดที่สั่ง
	ScarecrowGhost = {
		DisplayName = "ผีน้อยนักปักหุ่น",
		Description = "👻 สัตว์ลับฮาโลวีน: ลอยได้ · กด 👻 สั่งปักหุ่น เลือกจุด แล้วผีน้อยหยิบหุ่นดวงดีจากแถบช่องลัดไปปักตรงนั้นให้ (หมดเวลาก็ปักตัวใหม่) · เก็บเกี่ยวในรัศมีหุ่นฟางของเราได้ผลผลิต x1.5 (อัพเลเวลเพิ่มถึง x1.8 ที่ Lv.15) และผักในวงหุ่นฟางโตเร็วขึ้น 10% · นำโชค x30 · หิวช้ากว่าปกติครึ่งหนึ่ง",
		Rarity = "Secret",
		Luck = 30, -- ตั้งเองเท่าจิ้งจอกเก้าหาง (ค่าระดับลับใน LuckConfig.PetLuckByRarity ยังเป็น 20) ผู้ใช้ขอ 2026-10-11
		Season = "GhostGacha2026", -- สวิตช์แยกของผีน้อยใน SeasonConfig (เริ่ม 15 ต.ค. ต่อจากจิ้งจอกเก้าหาง ไม่ผูกกับของตกแต่งฮาโลวีน)
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, 0, 0), -- โมเดลหันหน้า -Z อยู่แล้ว (ตัวอื่นหัน +Z จึงต้องหมุน 180)
		Flying = { Height = 3.5, WorkHeight = 0.9 }, -- ลอยสูงขึ้น (เดิม 1.5) ผู้ใช้ขอ 2026-10-13; ตอนปักหุ่นยังโฉบลงต่ำเท่าเดิม
		-- ความสามารถพิเศษ (ผู้ใช้เลือก 2026-10-11 ให้สูสีกับจิ้งจอกเก้าหาง): ตอนพาผีน้อยออกมา เก็บเกี่ยวต้นที่อยู่ในรัศมีหุ่นฟางที่เราปัก = ผลผลิต x1.5
		-- (0.5 = ส่วนที่เพิ่ม; ไม่คูณซ้อนกับ x2 ของจิ้งจอก ใช้ตัวที่มากกว่า ดู PlantingSystem.doHarvest / PetController)
		StrawYieldBonus = 0.5,
		StrawGrowBoost = 0.1, -- 2026-10-15 ผู้ใช้ขอ: ผักของเจ้าของที่อยู่ในรัศมีหุ่นฟางที่เราปัก โตเร็วขึ้น 10% (เวลาแต่ละช่วง x0.9) ดู PlantingSystem.growPlant
		Abilities = { "ScarecrowPlacer" }, -- นำโชค (Lucky) ใส่ให้เองท้ายไฟล์เพราะมีค่า Luck
	},

	-- 🔮 แม่มดน้อย (ระดับพรีเมียม) 2026-10-14 ผู้ใช้ขอ: ซื้อด้วย Robux เท่านั้น (ReplicatedStorage.PremiumPetConfig / ServerScriptService.PremiumPetService)
	--   ซื้อซ้ำ = +1 เลเวล สูงสุด Lv.15 · ไม่อยู่ในตู้ · แลก/อัปด้วยเศษไม่ได้
	--   ความสามารถ: ช่วยปลูก (Planter) แต่ปลูกทีละ 2 ต้น (PlantBatch) และร่ายเวทจากระยะ CastReach ไปที่แปลง (มีแสงเวทมนต์สีม่วง ดู Abilities.Planter)
	LittleWitch = {
		DisplayName = "แม่มดน้อย",
		Description = "🔮 สัตว์พรีเมียม: ขี่ไม้กวาดบินตาม · ร่ายเวทปลูกผักให้ทีละ 2 ต้น · นำโชค x30", -- ผู้ใช้ขอ 2026-10-14: ตัดข้อความตั้งแต่ "ซื้อเพิ่ม = +1 เลเวล" ออก
		Rarity = "Premium",
		NotInGacha = true,
		Season = "Halloween2026", -- ผู้ใช้ขอ 2026-10-14: ปล่อยพร้อมเทศกาลฮาโลวีน (ก่อนเริ่ม = ซ่อนทั้งตัว ซื้อไม่ได้ · เทศกาลจบแล้วคนที่มียังใช้ได้ ดู SeasonConfig.HasStarted)
		UnlockHint = "💎 ซื้อด้วย Robux เท่านั้น",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 11,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, 0, 0), -- โมเดลหันหน้า -Z
		Flying = { Height = 2.9, WorkHeight = 2.42 }, -- สูงขึ้น 10% สองรอบตามผู้ใช้ขอ 2026-10-14 (เดิม 2.4 / 2.0 → 2.64 / 2.2 → 2.9 / 2.42) · บินบนไม้กวาด ตอนร่ายเวทไม่ต้องโฉบลงต่ำ
		Abilities = { "Planter" },
		PlantBatch = 2,  -- ปลูกทีละ 2 ต้น (ช่องที่เลือก + ช่องว่างที่ใกล้ที่สุด)
		CastReach = 6,   -- ร่ายเวทจากระยะนี้ ไม่ต้องบินไปทับช่องปลูก
		Luck = 30, -- นำโชค x30 เท่าสัตว์ระดับลับ (ผู้ใช้ขอ 2026-10-14) ความสามารถ "นำโชค" ใส่ให้เองท้ายไฟล์
		CastFx = true,   -- แสงเวทมนต์ตอนปลูก (แทนท่าหยิบเมล็ด/ก้มฝัง)
	},

	-- 🐶 ซุกซน (ระดับลึกลับ 2026-10-22) ชิวาวาขาวปื้นส้มของผู้สร้างเกม มีแค่ผู้สร้าง หรือคนที่ผู้สร้างมอบให้ (/give <ชื่อ> zukzon ใน AdminGive, มอบซ้ำ = +1 เลเวล)
	-- HiddenUnlessOwned = คนที่ยังไม่มีไม่เห็นในเมนู/สมุด/ตู้สุ่มเลย (PetManager.buildPetList, GachaService)
	-- ความสามารถ: ปุ่มกอดอย่างเดียว (ช่วยเก็บเกี่ยว ขุดหาสมบัติ นำโชค เอาออก 2026-10-23) · เจ้าของกดปุ่มกอดได้โชค +10% 5 นาที (ZukzonService)
	Zukzon = {
		DisplayName = "ซุกซน",
		Description = "🐶 สัตว์ลึกลับ: กอดน้องได้โชค +10% 5 นาที · ไม่ใช้ช่องสัตว์",
		Rarity = "Mythic",
		NotInGacha = true,
		HiddenUnlessOwned = true,
		UnlockHint = "🔮 ได้จากผู้สร้างเกมเท่านั้น",
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, math.rad(180), 0),
		BoneNames = {
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			LeftEar = "Left Ear",
			RightEar = "Right Ear",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Luck = 0, -- ผู้ใช้ขอ 2026-10-23: ไม่มีนำโชค (0 = ท้ายไฟล์ไม่ใส่ความสามารถ Lucky ให้)
		FreeSlot = true, -- ไม่ใช้ช่องสัตว์เลี้ยง พาออกมาเพิ่มได้เสมอ (ผู้ใช้ขอ 2026-10-22) ดู PetManager.getActiveCount
		SitAfter = 1.5, -- เจ้าของหยุดเดินเกิน 1.5 วิ = นั่งรอ (ไม่เดินเล่น) ผู้ใช้ขอ 2026-10-22 · ท่านั่งใน PetAnimator (Attribute โมเดล SitPose = "Dog")
		SleepAfter = 25, -- เจ้าของยืนนิ่งเกิน 25 วิ = นอนขดเป็นวง (ผู้ใช้ส่งรูปน้องนอน 2026-10-22) ท่าใน PetAnimator (Attribute โมเดล SleepPose = "Curl")
		Abilities = {}, -- ผู้ใช้ขอ 2026-10-23: ไม่มีความสามารถ เหลือแค่ปุ่มกอด (ZukzonService) · โมดูล Abilities.TreasureDigger ยังเก็บไว้
	},

	-- 🦘 จริงใจ จิงโจ้หมวกสานพระจันทร์ (2026-10-29) ผู้ใช้ขอ: ความสามารถเดียวกับจิ้งจอกเก้าหางไปก่อน (เก็บเกี่ยว x2 · ทำงานเร็ว 30% · นำโชค x30 · หิวช้าครึ่งหนึ่งจากระดับลับ)
	--   เก็บผลผลิตแล้วลอยลงกระเป๋าหน้าท้อง (Attachment "PouchAttachment" ในโมเดล ดู PetWorkEffects.StashProduce)
	--   2026-11-01 ผู้ใช้สั่ง: อยู่ในตู้สุ่มตลอด ไม่ใช่ตัวอีเวนต์ (AlwaysInGacha ดู GachaService.buildState · เอา Season ออกแล้ว เห็นตลอด) · ไม่มี /give · โมเดล ServerStorage.PetTemplates.Jingjai
	Jingjai = {
		DisplayName = "จริงใจจิงโจ้", -- เดิม "จริงใจ" ผู้ใช้ขอเปลี่ยน 2026-10-29
		Description = "🦘 จริงใจจิงโจ้: เก็บเกี่ยวใส่กระเป๋าหน้าท้อง ได้ผลผลิต x2 · นำโชค x30 · หิวช้ากว่าปกติครึ่งหนึ่ง",
		DescriptionEn = "🦘 Jingjai the Kangaroo: Harvests into its pouch, yield x2 · Luck x30 · Gets hungry half as fast",
		Rarity = "Secret",
		Luck = 30,
		AlwaysInGacha = true, -- สัตว์ลับที่อยู่ในตู้ตลอด ไม่ต้องมีอีเวนต์ (เดิม Season = "JingjaiGacha2026" + อีเวนต์ Jingjai_2026_11)
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, 0, 0), -- โมเดล AI หันหน้า -Z
		BoneNames = { -- หูติดกับหัว หมวกเชื่อม WeldConstraint กับหัว
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Harvester" },
		HarvestMultiplier = 2,
		WorkSpeed = 1.3,
	},

	-- 👑🐝 ผึ้งราชินี (ระดับตำนาน 2026-10-29) อยู่ในตู้ระดับตำนาน ปล่อยพร้อมจริงใจจิงโจ้ (ผู้ใช้สั่ง 2026-10-31) = ผูกสวิตช์ SeasonConfig.JingjaiGacha2026 (HasStarted: เริ่มแล้วอยู่ในตู้ตลอดไป ไม่หายตอนอีเวนต์จิงโจ้จบ)
	-- บินตามเจ้าของ (ปีกกระพือเร็วด้วย Attribute FlapSpeed บนโมเดล) · ช่วยปลูก (เดิมช่วยเก็บเกี่ยว ผู้ใช้สั่งเปลี่ยน 2026-10-29) + ผสมเกสร PollinateChance = ต้นที่ผึ้งปลูกได้ผลผลิตแถม 1 ตอนเก็บ (Abilities.Planter ตั้ง slot.pollinated → PlantingSystem.doHarvest)
	-- โมเดล ServerStorage.PetTemplates.QueenBee (AI mesh: ตัว/หัว/ปีก 2 ข้าง/มงกุฎ หันหน้า -Z) เอฟเฟกต์เกสร/น้ำผึ้งใน StarterPlayerScripts.QueenBeeFx
	QueenBee = {
		DisplayName = "ผึ้งราชินี",
		Description = "🐝 บินได้ · ช่วยปลูกผัก · ผสมเกสร 15% ต้นที่ปลูกให้ได้ผลผลิตเพิ่ม 1 · นำโชค x15 · หิวช้าลง 25%",
		-- ภาษาอังกฤษ (เมนูสัตว์เลี้ยงใช้แทน Description เมื่อผู้เล่นไม่ได้ใช้ภาษาไทย) แยกส่วนด้วย " · " เหมือนกัน ห้ามมี ":" กลางข้อความ (ตัวตัดคำอธิบายถือเป็นชื่อฉายา)
		DescriptionEn = "🐝 Can fly · Helps plant vegetables · Pollinates 15% of the crops it plants (+1 harvest) · Luck x15 · Gets hungry 25% slower",
		Rarity = "Legendary",
		Season = "JingjaiGacha2026", -- เดิม "QueenBeeRelease" (สวิตช์แยก ไม่ใช้แล้ว)
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3,
		FacingOffset = CFrame.Angles(0, 0, 0), -- โมเดล AI หันหน้า -Z
		Flying = { Height = 2.2, WorkHeight = 0.9 }, -- บินสูงระดับไหล่ ตอนเก็บโฉบลงต่ำ
		Abilities = { "Planter" }, -- ผู้ใช้สั่ง 2026-10-29 (เดิม Harvester)
		PollinateChance = 0.15, -- ผู้ใช้เลือก 2026-10-29 · สุ่มต่อต้นตอนปลูก
	},

	-- 🌸 ตุ่นนักอนุรักษ์ (ระดับลับ 2026-11-06) ตุ่นปากเป็ดถือกระทง อีเวนต์ลอยกระทง ตู้สุ่มเข้า 15 พ.ย. (SeasonConfig.PlatypusGacha2026 + GachaConfig.Events "Platypus_2026_11") อยู่ในตู้คู่กับจริงใจจิงโจ้
	--   ความสามารถ KrathongCollector: ทุก 15 วิ ลงน้ำใกล้เจ้าของ (60 studs) เก็บกระทงได้เหรียญ 100-1000 · Swims = ตัวจมลงน้ำตอนอยู่บนผิวน้ำ (PetController + PetAnimator)
	--   โมเดล ServerStorage.PetTemplates.Platypus (AI mesh รุ่น 2: ตัว+หัวชิ้นเดียว ปากแยกชิ้น) หันหน้า -Z · เอฟเฟกต์ StarterPlayerScripts.PlatypusFx
	Platypus = {
		DisplayName = "ตุ่นนักอนุรักษ์",
		Description = "🌸 ตุ่นนักอนุรักษ์: ลงน้ำเก็บกระทงทุก 15 วิ ได้เหรียญ 100-1,000 · นำโชค x30 · หิวช้ากว่าปกติครึ่งหนึ่ง",
		DescriptionEn = "🌸 Conservation Platypus: Collects krathongs from the water every 15 seconds for 100-1,000 coins · Luck x30 · Gets hungry half as fast",
		Rarity = "Secret",
		Luck = 30,
		Season = "PlatypusGacha2026", -- ยังไม่ถึงวัน = เอาออกจากตารางท้ายไฟล์ (ไม่ขึ้นเมนู/ตู้สุ่ม) จบอีเวนต์แล้วคนที่ได้ไปยังใช้ได้
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, 0, 0), -- โมเดล AI หันหน้า -Z
		Swims = { Sink = 0.75 },
		ShowcasePerk = "เก็บกระทงทุก 15 วิ ได้เหรียญ 100-1,000", -- บรรทัดความสามารถบนตู้สุ่ม
		BoneNames = { -- แขนติดลำตัว (ถือกระทง/เหรียญ) กระทงและเหรียญเชื่อมกับลำตัว
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			Root = "RootJoint", -- หัวอยู่ในชิ้นตัว (รุ่น 2 หัวแยกชิ้นแล้วหาย) ไม่มีข้อต่อ Neck · Head ในโมเดลเป็นชิ้นล่องหน
			Tail = "Tail",
		},
		Abilities = { "KrathongCollector" },
	},

	-- ❄️ เสือดาวหิมะ (ระดับลับ 2026-11-27) แผน SNOW_LEOPARD_PET.md · โมเดล Blender ServerStorage.PetTemplates.SnowLeopard (หันหน้า -Z)
	--   ช่วยปลูก + มือซ้ายชูผลผลิตที่กำลังปลูก (Attachment "HoldL" ที่ LeftArm) · ปากบัวรดน้ำ Attachment "CanSpout" ที่ RightArm
	--   ตู้: Season SnowLeopardGacha2026 (เริ่ม 1 ธ.ค.) + AlwaysInGacha · 1–15 ธ.ค. ตัวหน้าตู้ 75% · ทดสอบใน Studio: DevForceSeason ใส่ "SnowLeopardGacha2026" แล้ว /give <ชื่อ> snowleopard
	SnowLeopard = {
		DisplayName = "เสือดาวหิมะ",
		Description = "❄️ เสือดาวหิมะ: ช่วยปลูกผัก ชูผลผลิตที่กำลังปลูกโชว์ · แปลงที่ปลูกให้โตเร็วขึ้น 10% · นำโชค x30 · หิวช้ากว่าปกติครึ่งหนึ่ง",
		DescriptionEn = "❄️ Snow Leopard: Helps plant crops and shows off the crop it is planting · Crops it plants grow 10% faster · Luck x30 · Gets hungry half as fast",
		Rarity = "Secret",
		Luck = 30,
		Season = "SnowLeopardGacha2026", -- ยังไม่เริ่ม/สวิตช์ปิด = ไม่มีตัวนี้ในเกมเลย (เริ่ม 1 ธ.ค. หลังเปิดสวิตช์ SeasonConfig)
		AlwaysInGacha = true, -- เริ่มแล้วอยู่ในตู้ระดับลับตลอดไป (1–15 ธ.ค. เป็นตัวหน้าตู้ 75% ดู GachaConfig.Events SnowLeopard_2026_12)
		TemplateFolder = "PetTemplates",
		WalkSpeed = 10,
		FollowDistance = 3.5,
		FacingOffset = CFrame.Angles(0, 0, 0), -- โมเดลหันหน้า -Z
		BoneNames = { -- หูอยู่ในชิ้นหัว ตะกร้า/ตะเกียงติดลำตัว บัวรดน้ำติดแขนขวา
			LeftHip = "Left Hip",
			RightHip = "Right Hip",
			LeftShoulder = "Left Shoulder",
			RightShoulder = "Right Shoulder",
			Neck = "Neck",
			Root = "RootJoint",
			Tail = "Tail",
		},
		Abilities = { "Planter" },
		PlantGrowBoost = 0.1, -- แปลงที่ตัวนี้ปลูก โตเร็วขึ้น 10% (Abilities.Planter ส่งให้ PlantingSystem.growPlant ผ่าน slot.petGrowBoost)
		HoldCrop = "HoldL", -- ชูผลผลิตของพืชที่เพิ่งปลูกบนฝ่ามือซ้าย (Abilities.Planter holdCrop)
	},

	-- ตัวอย่าง: อนาคตเพิ่มสัตว์เลี้ยงตัวใหม่แค่ลอกแบบนี้แล้วแก้ค่า
	-- SomeNewPet = {
	-- 	DisplayName = "ชื่อสัตว์เลี้ยงใหม่",
	-- 	TemplateFolder = "PetTemplates",
	-- 	WalkSpeed = 10,
	-- 	FollowDistance = 3,
	-- 	FacingOffset = CFrame.Angles(0, 0, 0),
	-- 	BoneNames = { LeftHip = "Left Hip", RightHip = "Right Hip" },
	-- 	Abilities = { "Harvester", "SomeNewAbility" },
	-- },
}

-- สัตว์ประจำเทศกาล (มี Season): ถ้าเทศกาลนั้นยังไม่เคยเริ่ม เอาออกจากตารางเลย = ไม่ขึ้นในเมนูสัตว์เลี้ยง/ตู้สุ่ม ไม่มีใครรู้ว่ามี
-- (เซิร์ฟเวอร์อ่านค่าตอนเริ่มทำงาน เซิร์ฟเวอร์ที่เปิดค้างข้ามเวลาเริ่มเทศกาลจะเห็นสัตว์ตัวนี้หลังรีสตาร์ต)
local SeasonConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("SeasonConfig"))
for petId, def in pairs(PetDefinitions) do
	if def.Season and not SeasonConfig.HasStarted(def.Season) then
		PetDefinitions[petId] = nil
	end
end

-- ค่าโชคของสัตว์แต่ละตัว (Luck ที่ตั้งเอง หรือตามความหายาก) และใส่ความสามารถ "Lucky" ให้ตัวที่มีโชค
for _, def in pairs(PetDefinitions) do
	def.Luck = def.Luck or LuckConfig.PetLuckByRarity[def.Rarity or "Common"]
	if def.Luck and def.Luck > 0 then
		def.Abilities = def.Abilities or {}
		if not table.find(def.Abilities, "Lucky") then
			table.insert(def.Abilities, "Lucky")
		end
	end
end

-- ชื่อสัตว์ภาษาอังกฤษ (2026-11-07 ผู้ใช้แจ้งชื่อลับ/ตำนานในตู้สุ่มยังเป็นไทย) GachaService ส่ง DisplayNameEn ให้หน้าจอเลือกตามภาษา
local NAME_EN = {
	ChibiCat = "Cute Kitten", PastelPinkRabbit = "Pink Rabbit", ChibiFox = "Little Fox", ChibiPanda = "Little Panda",
	NineLivesCat = "Nine-Lives Cat", QueenBee = "Queen Bee", WhiteTiger = "White Tiger", Otter = "Little Otter Fisherman",
	Jingjai = "Jingjai the Kangaroo", NineTailFox = "Nine-Tailed Fox", ScarecrowGhost = "Scarecrow Ghost", Platypus = "Conservation Platypus",
	LittleWitch = "Little Witch", SultanDragon = "Red Dragon Sultan", Zukzon = "Zukzon", SnowLeopard = "Snow Leopard",
}
for petId, en in pairs(NAME_EN) do
	if PetDefinitions[petId] then PetDefinitions[petId].DisplayNameEn = en end
end

-- คำอธิบาย / วิธีได้ / ความสามารถตัวโชว์ ภาษาอังกฤษ (2026-11-25 เมนูสัตว์เลี้ยงผู้เล่นอังกฤษ) ตัวไหนตั้งในบล็อกของตัวเองแล้วไม่ทับ
local DESC_EN = {
	NineTailFox = "🦊 Divine pet: harvest yield x2 · Luck x30 · gets hungry half as fast",
	NineLivesCat = "🐈‍⬛ 9 lives: revives itself at 50% after starving (9 times) · Luck x15 · gets hungry 25% slower",
	WhiteTiger = "🐅 Lord of the West: nimble, works 30% faster · Luck x15 · gets hungry 25% slower",
	Otter = "🦦 Reward for completing the fish book: walks to water near you and fishes on its own (no rod needed), fish go to your bag · Luck x15",
	SultanDragon = "🔥 Sultan pet: flies · helps plant crops · Luck x50 · sell price +10% · breathes fire to make crops grow 15% faster",
	ScarecrowGhost = "👻 Secret Halloween pet: floats · tap 👻 to place a scarecrow, pick a spot and the ghost takes a lucky scarecrow from your hotbar and places it there (places a new one when it runs out) · harvests inside your scarecrow rings give yield x1.5 (up to x1.8 at Lv.15) and crops in the ring grow 10% faster · Luck x30 · gets hungry half as fast",
	LittleWitch = "🔮 Premium pet: flies along on a broom · casts spells to plant 2 crops at a time · Luck x30",
	Zukzon = "🐶 Mystery pet: hug it for +10% luck for 5 minutes · doesn't use a pet slot",
}
local HINT_EN = {
	Otter = "📖 From the fish book: catch every kind of fish",
	SultanDragon = "👑 Only from the Sultan Pack",
	LittleWitch = "💎 Robux only",
	Zukzon = "🔮 Only from the game creator",
}
local PERK_EN = {
	Platypus = "Collects a krathong every 15s for 100-1,000 coins",
}
for petId, def in pairs(PetDefinitions) do
	if type(def) == "table" then
		def.DescriptionEn = def.DescriptionEn or DESC_EN[petId]
		def.UnlockHintEn = def.UnlockHintEn or HINT_EN[petId]
		def.ShowcasePerkEn = def.ShowcasePerkEn or PERK_EN[petId]
	end
end

return PetDefinitions
