-- BACKUP 2026-11-14: game.ReplicatedStorage.OrchardConfig (ModuleScript) before mango total time 2 h (FruitSeconds 2 h -> 100 min)
-- Restore: open ReplicatedStorage.OrchardConfig in Studio, replace its whole Source with everything below the next line.
-- Only the Mango GrowSeconds/FruitSeconds line differs from the edited version.
-- ===== SOURCE =====
-- OrchardConfig: สวนผลไม้ยืนต้น (มะม่วง / ทุเรียน) ค่าทั้งหมดอยู่ที่นี่ 2026-10-25
-- เฟส 1: ข้อมูล (OrchardData) + ล็อกในสวน workspace.Orchard + หน้าตาต้นตามขั้น (OrchardService)
-- เฟส 2: ซื้อเมล็ดที่ร้านเมล็ดพันธุ์ (เข้ากระเป๋า) -> ปลูกเองที่หลุมว่าง / เก็บเข้ากระเป๋า / ขายที่ร้าน (2026-10-26) · สรุปทั้งระบบ ORCHARD.md · เฟส 3: มือขโมย · เฟส 4: แจ้งเจ้าของ + มือตบ
-- ปลูกได้คนละ 5 ต้น รวมทุกชนิด (ผู้ใช้สั่ง 2026-10-26 เดิมชนิดละ 1) · เมล็ดซื้อได้ไม่จำกัด จำกัดตอนปลูก (ปลูกครบ 5 = ปลูกเพิ่มไม่ได้)
--   ล็อกละ 6 หลุม (แถวหน้า Hole1-3 + แถวหลัง Hole4-6 ตรงกัน 2026-10-27 เดิม 5 หลุมดูไม่เรียบร้อย) ปลูกได้ยังคนละ 5 ต้น · 2026-10-27 ย้ายสวนไปที่ภูเขาที่เกลี่ยเป็นที่ราบ y 20 (ล็อก 3 คอลัมน์ x 258/300/342 × 4 แถว z -470..-560 รั้ว x 232..368 z -588..-440 ประตูเหนือ/ตะวันออก)
-- ขโมยได้เฉพาะตอนเจ้าของอยู่ในเซิร์ฟเดียวกัน (ผู้ใช้เลือก 2026-10-25)

local OrchardConfig = {}

-- DEV_ONLY = true: เปิดเฉพาะใน Studio (Play / Team Test) เซิร์ฟจริงซ่อนทั้งระบบ (ผู้ใช้สั่งซ่อนไว้ก่อน 2026-10-25 เอาฟาร์มไก่ก่อน) · เปิดให้ผู้เล่นจริง = DEV_ONLY = false
--   ปิด = ย้าย workspace.Orchard ไป ServerStorage ตอนเกมรัน ไม่โหลด/เซฟข้อมูล
OrchardConfig.DEV_ONLY = false -- 2026-11-14 ผู้ใช้สั่ง "เปิดระบบ ผลไม้ยืนต้น" เปิดให้ผู้เล่นจริง · ก่อนหน้า: true 2026-11-13 ผู้ใช้สั่ง "สวนผลไม้ยืนต้นปิดไว้ก่อน" (Publish เอาเกาะใหม่เข้า) เปิดให้ผู้เล่นจริง = false · ก่อนหน้า: false 2026-11-12 ผู้ใช้สั่ง "เปิดแค่สวนผลไม้ก่อน" เปิดให้ผู้เล่นจริง (เซิร์ฟจริงใช้เวลาจริง ไม่ใช้ DEV_FAST_GROW) · เดิม true = ปิดในเซิร์ฟจริง (ผู้ใช้สั่ง 2026-10-30)
OrchardConfig.Enabled = (not OrchardConfig.DEV_ONLY) or game:GetService("RunService"):IsStudio()
-- ทดสอบเป็นทีม (ผู้ใช้แจ้ง 2026-10-30 Team Test ยังไม่เห็นสวน): ถ้าเซิร์ฟไม่นับเป็น Studio สวนรออยู่ พอคนใน TESTERS เข้ามาจากหน้าต่าง Studio
--   (ฝั่งผู้เล่น IsStudio = true ยิง RemoteEvent OrchardStudioHello) เซิร์ฟนั้นเปิดสวน · เซิร์ฟจริงไม่มีใครเข้าจาก Studio = ปิดตลอด
OrchardConfig.TESTERS = {
	[9360333174] = true, -- One_moretime91 เจ้าของเกม
	[11611605711] = true, -- CtrlZ_2 บัญชีทดสอบ
	[9188779540] = true, -- valynlnwza บัญชีทดสอบ
}

OrchardConfig.START_TREES = 6 -- หลุมในล็อกใช้ได้ทุกหลุม (เลิกขายปลดล็อกหลุม 2026-10-25) = MAX_TREES
OrchardConfig.MAX_TREES = 6 -- ล็อก 1 ล็อก = 6 หลุม (เลือกหลุมปลูกเอง) ต้องมี Hole1..MAX_TREES ทุกล็อก (2026-10-27 เดิม 5)
OrchardConfig.MAX_PER_PLAYER = 6 -- ต้นที่ปลูกได้ รวมทุกชนิด ต่อคน (ไม่เกิน MAX_TREES) เช็กตอนปลูก ไม่เช็กตอนซื้อ · ผู้ใช้เปลี่ยน 5 -> 6 (2026-10-29)
OrchardConfig.MIN_LEVEL = 1 -- เลเวลขั้นต่ำซื้อเมล็ด/ปลูก (20 → 1 ผู้ใช้สั่ง 2026-10-29)
OrchardConfig.HARVEST_DISTANCE = 14 -- เก็บผล / ปลูกเมล็ด ต้องยืนที่ต้น/หลุม

-- GrowSeconds = กล้า -> ต้นโต (ครั้งแรก) · FruitSeconds = ออกดอกจนผลสุก 1 รอบ · Fruit = จำนวนผลต่อรอบ (สุ่ม Min..Max)
-- Harvests = เก็บได้กี่รอบต่อต้น (ผู้ใช้สั่ง 2026-10-27 เดิมเก็บได้ไม่จำกัด) · ไม่ใส่ = ไม่จำกัด
--   เก็บครบ = ต้นแห้ง (2026-11-02 เดิมต้นหายไปเลย) ดู OrchardConfig.DeadTree
-- Open = false: ชนิดนี้ยังไม่เปิด (ร้านไม่ขายเมล็ด ซื้อ/ปลูกไม่ได้) ต้นที่ปลูกไว้แล้วยังโต/เก็บได้ · 2026-10-27 ผู้ใช้สั่งเปิดแค่มะม่วง
OrchardConfig.Trees = {
	Mango = {
		-- ชื่อ "มะม่วงหมอนทอง" ผู้ใช้สั่ง 2026-10-29 (เดิม มะม่วง) · GoldAura = ต้นตอนผลสุกมีออร่าทอง (ประกาย + ฝุ่นทองลอยขึ้น + แสงทอง) ดูน่าขโมย
		Order = 1, NameTh = "มะม่วงหมอนทอง", NameEn = "Monthong Mango", Icon = "🥭", Open = true, GoldAura = true,
		GrowSeconds = 20 * 60, FruitSeconds = 2 * 3600, -- โต 3 ชม. → 1 ชม. → 20 นาที (ผู้ใช้สั่ง 2026-10-29)
		FruitMin = 1, FruitMax = 1, Harvests = 2, -- รอบละ 1 ผลเท่านั้น (เดิม 1-2 ผู้ใช้สั่ง 2026-10-29)
		FruitPrice = 100000, SeedPrice = 10000, -- ผู้ใช้ปรับ 2026-10-26 (เดิม ผล 1M / เมล็ด 500k)
		Scale = 0.6, -- ขนาดต้นโต (เทียบเทมเพลต ServerStorage.OrchardTemplates.<ชนิดต้น>)
		-- ต้นตอนผลสุก = โมเดลมะม่วงของฉาก (ผลอยู่ในพื้นผิว) สูง RipeHeight studs ไม่ต้องต่อผลเพิ่ม (ผู้ใช้ส่งรูป 2026-10-26)
		RipeTemplate = "MangoRipe", RipeHeight = 13,
		IconImage = "rbxassetid://133531079824880", -- รูปมะม่วงสีเหลือง แทนอีโมจิ 🥭 ที่ Roblox วาดเป็นสีแดง (ป้าย +1 มุมขวาบน 2026-11-03, ไฟล์ product_icons/mango_yellow_icon.png)
		FruitSize = Vector3.new(1.6, 2.2, 1.6),
		GreenColor = Color3.fromRGB(120, 175, 60), RipeColor = Color3.fromRGB(255, 190, 40),
		FruitMaterial = Enum.Material.SmoothPlastic,
	},
	Durian = {
		Order = 2, NameTh = "ทุเรียน", NameEn = "Durian", Icon = "🍈", Open = false, -- ยังไม่เปิด (ผู้ใช้สั่ง 2026-10-27)
		GrowSeconds = 6 * 3600, FruitSeconds = 4 * 3600,
		FruitMin = 1, FruitMax = 3, Harvests = 2,
		FruitPrice = 2500000, SeedPrice = 2000000,
		Scale = 0.7,
		FruitSize = Vector3.new(2.4, 2.8, 2.4),
		GreenColor = Color3.fromRGB(95, 130, 45), RipeColor = Color3.fromRGB(190, 170, 60),
		FruitMaterial = Enum.Material.Slate, -- ผิวขรุขระแทนหนาม (เฟส 2 ทำโมเดลผลทุเรียนจริง)
	},
}

-- DEV_FAST_GROW: ทดสอบใน Studio ให้มะม่วงโตไว (ผู้ใช้สั่ง 2026-10-27) ใช้เฉพาะ IsStudio() เซิร์ฟจริงใช้เวลาจริงเสมอ · เลิกทดสอบ = DEV_FAST_GROW = nil
OrchardConfig.DEV_FAST_GROW = nil -- 2026-11-14 ผู้ใช้สั่ง: ใน dev มะม่วงใช้เวลาจริง (โต 20 นาที + ผลสุก 2 ชม.) เปิดเร็วคืน = { Mango = { GrowSeconds = 10, FruitSeconds = 60 } } · ก่อนหน้า: -- 2026-11-06 ผู้ใช้สั่ง: ทดสอบทีมผลสุก 1 นาที (โต 60 → 10 วิ) · เดิม:  -- 2026-11-02 ผู้ใช้สั่ง: ใน Studio โต 1 นาที + ผลสุก 1 นาที (ทดสอบต้นแห้ง) · เซิร์ฟจริงใช้เวลาจริงเสมอ · เลิกทดสอบ = nil
-- 2026-11-06: เซิร์ฟ Team Test ไม่นับเป็น Studio จึงใช้ DEV_ONLY ด้วย (เดิมฝั่งผู้เล่นได้เวลาเร็ว แต่เซิร์ฟเวอร์ยังใช้เวลาจริง) · เซิร์ฟจริงตอน DEV_ONLY สวนปิดอยู่ เปิดสวนจริง (DEV_ONLY = false) = ใช้เวลาจริง
if OrchardConfig.DEV_FAST_GROW and (game:GetService("RunService"):IsStudio() or OrchardConfig.DEV_ONLY == true) then
	for kind, t in pairs(OrchardConfig.DEV_FAST_GROW) do
		local def = OrchardConfig.Trees[kind]
		if def then
			def.GrowSeconds = t.GrowSeconds or def.GrowSeconds
			def.FruitSeconds = t.FruitSeconds or def.FruitSeconds
		end
	end
end

-- ขั้นของต้น: โต 3 ขั้นตาม GrowSeconds แล้ววนรอบผล ดอก -> ผลเขียว -> ผลสุก (ค้างจนกว่าจะเก็บ)
OrchardConfig.Stages = { "Sapling", "Young", "Grown", "Flower", "Green", "Ripe" }
OrchardConfig.StageNames = {
	Sapling = { th = "ต้นกล้า", en = "Sapling" },
	Young = { th = "ต้นเล็ก", en = "Young tree" },
	Grown = { th = "ต้นโต", en = "Grown tree" },
	Flower = { th = "ออกดอก", en = "Flowering" },
	Green = { th = "ผลยังไม่สุก", en = "Unripe fruit" },
	Ripe = { th = "ผลสุกแล้ว!", en = "Ripe!" },
}
OrchardConfig.StageNames.Dead = { th = "ต้นแห้ง", en = "Dead tree" } -- เก็บครบรอบแล้ว (2026-11-02)
OrchardConfig.StageScale = { Sapling = 0.3, Young = 0.6 } -- คูณกับ Scale ของต้น (ขั้นอื่น = เต็มต้น)

-- ต้นแห้ง (ผู้ใช้สั่ง 2026-11-02): เก็บครบ Harvests รอบ = ต้นไม่หาย กลายเป็นต้นแห้ง ยังนับเป็น 1 ใน MAX_PER_PLAYER ต้น ขโมยไม่ได้
--   ทาง 1: เจ้าของกดค้าง "ตัดต้น" CutSeconds วิ = หลุมว่าง + ได้ท่อนไม้ WoodPerCut ท่อน
--   ทาง 2: ผู้เล่นคนอื่นในเซิร์ฟ (เจ้าของต้องอยู่) กดค้าง "รดน้ำช่วย" HelpSeconds วิ = ต้นฟื้น เก็บได้อีก Harvests รอบ (ฟื้นได้ครั้งเดียวต่อต้น แห้งรอบ 2 = ต้องตัด)
--     คนช่วยได้ 💚 เหรียญช่วยเหลือ HelpCoins (สกุลใหม่ เก็บใน OrchardData.help.coins ไว้แลกของรางวัล ร้านยังไม่ทำ)
--     กันบัญชีปลอม: คนช่วยต้องเลเวล HelpMinLevel · ช่วยเจ้าของคนเดิมได้วันละ 1 ครั้ง · ได้เหรียญวันละไม่เกิน HelpDailyCoins ครั้ง (เกินแล้วยังช่วยได้แต่ไม่ได้เหรียญ)
--     เจ้าของกด "ขอความช่วยเหลือ" = แจ้งทุกคนในเซิร์ฟ (เว้น HelpAskCooldown วิ)
OrchardConfig.DeadTree = {
	Template = "MangoDead", -- โมเดลต้นแห้ง (มีแค่ลำต้น กิ่ง ก้าน ไม่มีใบ) ใน ServerStorage.OrchardTemplates (2026-11-03) ไม่มี = ใช้ต้นปกติทาสีน้ำตาล
	Height = 11, -- ความสูงต้นแห้ง (studs)
	HelpIcon = "rbxassetid://82193103012073", -- ไอคอนบัวรดน้ำเหนือต้นแห้งที่เพื่อนช่วยรดน้ำได้ (product_icons/watering_can_icon.png)
	CutSeconds = 4, WoodPerCut = 2, -- 3 → 4 วิ ฟันขวานครบ 4 ครั้ง (ผู้ใช้สั่ง 2026-11-02)
	-- ผู้ใช้สั่ง 2026-11-02: เหรียญช่วยเหลือได้ไม่จำกัดต่อวัน (HelpDailyCoins 5 → math.huge) · เลเวล 5 ขึ้นไปเหมือนเดิม (เคยลดเป็น 1 แล้วผู้ใช้สั่งคืน)
	--   ช่วยเจ้าของคนเดิมได้วันละ HelpPerOwnerDaily ครั้ง (1 → 3 → ไม่จำกัด ผู้ใช้สั่ง 2026-11-02 "ไปก่อน") · ตัวจำกัดที่เหลือ = ต้นต้องแห้ง + ฟื้นได้ครั้งเดียวต่อต้น
	HelpSeconds = 3, HelpCoins = 1, HelpMinLevel = 5, HelpDailyCoins = math.huge, HelpPerOwnerDaily = math.huge, HelpAskCooldown = 60,
	HelpRange = 9,
	RevivedHarvests = 1, -- เพื่อนรดน้ำฟื้นแล้วเก็บได้กี่รอบ แล้วแห้งต้องตัด (ผู้ใช้สั่ง 2026-11-07 เดิมเท่า Harvests)
}

-- ของจากสวน (2026-11-02): Tool IsOrchardMat + MatId + Count (OrchardItems) · InventorySystem kind "OrchardMat"
--   Wood = ท่อนไม้ได้จากตัดต้นแห้ง ใช้คราฟที่โต๊ะช่างนากน้อย (วัตถุดิบ "@Wood" ใน CraftConfig) / ขายที่ร้านผลไม้ไม่ได้
--   Fertilizer = ปุ๋ยไม้ผล คราฟจากไม้ (CraftConfig สูตร OrchardFertilizer) ถือแล้วกดที่ต้นของเราที่ยังไม่สุก = ลดเวลาที่เหลือ FertilizerSeconds วิ ใส่ได้รอบผลละ 1 ครั้ง
OrchardConfig.Mats = {
	Wood = { NameTh = "ท่อนไม้", NameEn = "Log", Icon = "🌲", Color = Color3.fromRGB(140, 95, 55) }, -- 🪵 ขึ้นกล่องใน Roblox (ผู้ใช้แจ้ง 2026-11-02)
	Fertilizer = { NameTh = "ปุ๋ยไม้ผล", NameEn = "Tree fertilizer", Icon = "🌱", Color = Color3.fromRGB(110, 170, 70) },
}
OrchardConfig.FertilizerSeconds = 30 * 60
-- เครื่องทำปุ๋ย (ผู้ใช้สั่ง 2026-11-02 ย้ายจากสูตรโต๊ะช่างนากน้อย): workspace.Orchard.Decor.FertilizerMachine (โมเดล AI ข้างร้านผลไม้)
--   กดค้าง E "ใส่ท่อนไม้" = หักท่อนไม้ Wood + เหรียญ Coins → เครื่องสั่น + ควัน Seconds วิ → ปุ๋ย 1 ถุงเข้ากระเป๋า
--   เลือกจำนวนได้ (ผู้ใช้สั่ง 2026-11-02): กด E = หน้าต่าง -/+/MAX ครั้งละไม่เกิน MaxBatch ถุง · เวลา = Seconds + PerExtra × (จำนวน - 1) ไม่เกิน MaxSeconds
OrchardConfig.FertilizerMachine = { Wood = 2, Coins = 5000, Seconds = 3, PerExtra = 0.5, MaxSeconds = 10, MaxBatch = 20 }

-- อุปกรณ์สวนแจกฟรี (ผู้ใช้สั่ง 2026-11-02): 🪓 ขวาน (ตัดต้นแห้ง) / 🚿 บัวรดน้ำ (ช่วยรดน้ำต้นแห้งเพื่อน)
--   Tool IsOrchardTool + OrchardToolId อยู่ในกระเป๋าแท็บอุปกรณ์ ไม่เซฟ (OrchardService ใส่ให้ทุกครั้งเข้าเกม/เกิดใหม่) · กดปุ่มที่ต้นแล้วหยิบขึ้นมือให้เอง
--   โมเดล AI ที่ ServerStorage.OrchardTemplates.<Template> (Handle = MeshPart) · Grip = ท่าถือ · PourGrip = บัวเอียงตอนรดน้ำ
OrchardConfig.Kit = {
	-- ขวานสองคม ใบมีดอยู่แกน ±X ของโมเดล หมุน 90° รอบ Y = คมขวานหันไปข้างหน้าเข้าต้น (ผู้ใช้แจ้ง 2026-11-02 เดิมคมหันซ้าย-ขวา ฟันด้วยสัน วัดใน Play แล้ว)
	Axe = { Order = 1, NameTh = "ขวาน", NameEn = "Axe", Icon = "🪓", Template = "OrchardAxe", Grip = CFrame.new(0, -0.75, 0) * CFrame.Angles(0, math.rad(90), 0) },
	-- บัวพวยเดียว (ทำใหม่ 2026-11-02 เดิม AI ทำพวยสองข้าง): พวยอยู่ฝั่ง -X หูหิ้วฝั่ง +X (วัดด้วย raycast) · จับที่หูหิ้ว หมุน 90° = พวยชี้ไปข้างหน้า · PourGrip เอียง X +55° = พวยก้มลงข้างหน้า (วัดใน Play)
	Can = { Order = 2, NameTh = "บัวรดน้ำ", NameEn = "Watering can", Icon = "🚿", Template = "OrchardCan",
		Grip = CFrame.new(1.0, 0.3, 0) * CFrame.Angles(0, math.rad(90), 0),
		PourGrip = CFrame.new(1.0, 0.3, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(55), 0, 0),
		SpoutSide = -1, SpoutHeight = 0.24,
	},
}
OrchardConfig.KitSounds = {
	Chop = "rbxassetid://9120950231", -- Wood Pound Dirt Two Wood Poles (ProSoundEffects)
	Fall = "rbxassetid://9120796401", -- Wood Barrel Impact Dropping On Ground
	Water = "rbxassetid://9120567556", -- Water Into Glass Faucet With Aerator 9 (ProSoundEffects) เทน้ำจากบัว · 2026-11-03 เดิม 9113846161 Coffee Brew Dribble เบาจนไม่ได้ยิน
	WaterSpray = "rbxassetid://9120604420", -- Water Squirt Big Hose Squirts 4 (ProSoundEffects) ช้างพ่นน้ำจากงวง
	Trumpet = "rbxassetid://9114300941", -- Elephant Trumpets Grunts 1 ช้างร้องตอนเริ่มพ่น
}

-- ตู้แลกน้ำใจ 💚 (เฟส 1 ผู้ใช้สั่ง 2026-11-03): แลกด้วยเหรียญช่วยเหลือ (OrchardData help.coins) ที่ workspace.Orchard.Decor.HelpShop
--   Grant: "coins" (Amount เหรียญ) / "hatch" / "speed" (คูปองไก่ ผ่าน ServerScriptService.ChickenTokenGrant) / "quota" (โควต้าปลูกผัก +5 ถาวร ผ่าน PlantQuotaPromoGrant)
--     / "title" (ฉายาบนหัว ซื้อครั้งเดียว ใส่/ถอดได้ Attribute ผู้เล่น HelpTitle → PlayerNameTags) / "back" (ประดับหลัง)
--     / "mount" (สัตว์ขี่ ผ่าน MountOwnership.GrantBatch มีแล้ว = ซื้อไม่ได้ ให้ไม่สำเร็จ = คืนเหรียญ 2026-11-03)
--   WeekLimit = ซื้อได้กี่ครั้งต่อสัปดาห์ (สัปดาห์เริ่มวันจันทร์ 07:00 เวลาไทย) · Prices = ราคาตามครั้งที่ซื้อ (ครบทุกขั้น = ซื้อไม่ได้แล้ว)
OrchardConfig.HelpShop = {
	Items = {
		{ Id = "Coins1M", Tab = "items", Icon = "💰", NameTh = "เงิน 1M", NameEn = "1M coins", Price = 2, WeekLimit = 5, Grant = "coins", Amount = 1000000 },
		{ Id = "HatchCoupon", Tab = "items", Icon = "⚡", NameTh = "คูปองฟักไข่ทันที", NameEn = "Instant-hatch coupon", Price = 5, WeekLimit = 3, Grant = "hatch" },
		{ Id = "SpeedCoupon", Tab = "items", Icon = "⏩", NameTh = "คูปองไก่โตทันที", NameEn = "Chicken speed-up coupon", Price = 15, WeekLimit = 3, Grant = "speed" },
		{ Id = "PlantQuota", Tab = "items", Icon = "🌱", NameTh = "แปลงปลูกผัก +5 (ถาวร)", NameEn = "Crop slots +5 (permanent)", Prices = { 40, 60, 80, 100, 120 }, Grant = "quota" },
		{ Id = "TitleKind", Tab = "titles", Icon = "💚", NameTh = "ฉายา 💚 คนใจดี", NameEn = "Title 💚 Kind Heart", Price = 60, Grant = "title", Title = "💚 คนใจดี" },
		{ Id = "TitleGuardian", Tab = "titles", Icon = "🌳", NameTh = "ฉายา 🌳 ผู้พิทักษ์สวน", NameEn = "Title 🌳 Orchard Guardian", Price = 150, Grant = "title", Title = "🌳 ผู้พิทักษ์สวน" },
		{ Id = "TitleAngel", Tab = "titles", Icon = "👼", NameTh = "ฉายา 👼 นางฟ้าใจบุญ", NameEn = "Title 👼 Kind Angel", Price = 300, Grant = "title", Title = "👼 นางฟ้าใจบุญ" },
		-- ฉายาคู่กัน (ผู้ใช้สั่ง 2026-11-03 ราคาเท่านางฟ้าใจบุญ)
		{ Id = "TitleAngelBoy", Tab = "titles", Icon = "😇", NameTh = "ฉายา 😇 เทพบุตรใจบุญ", NameEn = "Title 😇 Kind Angel Prince", Price = 300, Grant = "title", Title = "😇 เทพบุตรใจบุญ" },
		-- ประดับหลัง (เฟส 2 ผู้ใช้สั่ง 2026-11-03): ซื้อครั้งเดียว ใส่/ถอดได้ ใส่ได้ทีละชิ้น · โมเดล ServerStorage.OrchardTemplates.<Template> (Handle = MeshPart)
		--   ติดที่ UpperTorso.BodyBackAttachment (R15) · Offset = CFrame จากจุดนั้น (หมุนโมเดล AI ให้ตั้งตรง + ดันออกจากหลัง) · Sparkle = ประกายสี
		{ Id = "BackLeafWings", Tab = "back", Icon = "🍃", NameTh = "ปีกใบไม้", NameEn = "Leaf wings", Price = 100, Grant = "back", Template = "BackLeafWings", Offset = CFrame.new(0, 0.3, 0.4) },
		{ Id = "BackCanPack", Tab = "back", Icon = "🚿", NameTh = "เป้บัวรดน้ำ", NameEn = "Watering-can backpack", Price = 180, Grant = "back", Template = "BackCanPack", Offset = CFrame.new(0, 0, 0.7) },
		{ Id = "BackRainbowWings", Tab = "back", Icon = "🦋", NameTh = "ปีกผีเสื้อสายรุ้ง", NameEn = "Rainbow butterfly wings", Price = 300, Grant = "back", Template = "BackRainbowWings", Offset = CFrame.new(0, 0.3, 0.4), Sparkle = true },
		-- สัตว์ขี่เอ็กซ์คลูซีฟ (เฟส 3 ผู้ใช้เลือก 2026-11-03): ซื้อครั้งเดียว ได้ถาวร ผ่าน MountOwnership · Mount = id ใน MountConfig.Mounts (ขี่/เก็บที่ตู้ 🗄️ ตกแต่ง)
		{ Id = "MountKindElephant", Tab = "mount", Icon = "🐘", NameTh = "ช้างน้อยใจบุญ", NameEn = "Kind Little Elephant", Price = 500, Grant = "mount", Mount = "KindElephant" },
	},
}
OrchardConfig.HelpShopById = {}
for i, it in ipairs(OrchardConfig.HelpShop.Items) do
	it.Order = i
	OrchardConfig.HelpShopById[it.Id] = it
end

-- เลขสัปดาห์ (เริ่มวันจันทร์ 00:00 UTC = 07:00 เวลาไทย) unix 0 = วันพฤหัส เลยบวก 3 วัน
function OrchardConfig.WeekNumber(t)
	return math.floor(((t or os.time()) + 3 * 86400) / (7 * 86400))
end

function OrchardConfig.MatName(id, lang)
	local m = OrchardConfig.Mats[id]
	if not m then return tostring(id) end
	return lang == "en" and m.NameEn or m.NameTh
end
OrchardConfig.FLOWER_PART = 0.4 -- ช่วงแรกของรอบผลที่เป็นดอก

-- เฟส 3 มือขโมย (2026-10-26): ซื้อที่ร้านเมล็ดพันธุ์ (ไม่จำกัด) ถือไว้ ยืนใต้ต้นสุกของคนอื่น กดค้าง "ขโมย" ครบเวลา = ได้ 1 ผล มือหาย 1 ชิ้น
--   ต้นของคนอื่นโชว์เฉพาะตอนเจ้าของอยู่เซิร์ฟเดียวกัน = ขโมยได้เฉพาะตอนเจ้าของอยู่ (ผู้ใช้เลือก) · เฟส 4 = แจ้งเจ้าของ + มือตบ (ยังไม่ทำ)
OrchardConfig.Steal = {
	HandPrice = 5000, -- 50000 → 5000 (ผู้ใช้สั่ง 2026-10-29) -- มือขโมย 1 ชิ้น ใช้แล้วหมด (หักเมื่อขโมยสำเร็จเท่านั้น)
	-- 2026-10-27 ผู้ใช้เปลี่ยนเป็น "ตะกร้อขโมย" (ไม้สอยมะม่วง ไม้ไผ่ + ตะกร้อ) ชื่อในโค้ดยังเป็น Hand/IsStealHand เดิม (ของในกระเป๋าเดิมใช้ต่อได้)
	HandIcon = "🧺", HandColor = Color3.fromRGB(196, 160, 90),
	HandNameTh = "ตะกร้อขโมย", HandNameEn = "Fruit picker",
	Range = 8, -- ต้องยืนห่างต้นไม่เกิน (studs) = ระยะปุ่ม "ขโมย"
	Seconds = { Mango = 10, Durian = 25 }, -- กดค้าง E ขโมยนานเท่านี้ (ผู้ใช้สั่ง 2026-10-28: มะม่วง 25 → 15 → 10, ทุเรียน 40 → 25) (เซิร์ฟเช็กเวลากดค้างจริงด้วย กันโกงกดทันที)
	TreeCooldown = 600, -- (เฟส 4) ต้นที่เจ้าของตบจับขโมยได้ พักกี่วินาที (ต่อเซิร์ฟ ไม่เซฟ)
	PerCycle = 1, -- ต้น 1 ต้นโดนขโมยได้กี่ครั้งต่อรอบผล
	KeepForOwner = 0, -- 1 → 0 (ผู้ใช้สั่ง 2026-10-29: มะม่วงรอบละ 1 ผล ให้ขโมยผลเดียวได้) · เดิม: -- เหลือผลให้เจ้าของอย่างน้อยเท่านี้ (ต้นที่มีผลไม่เกินนี้ = ขโมยไม่ได้)
	MinLevel = 1, -- ทั้งคนขโมยและเจ้าของต้น (20 → 1 ผู้ใช้สั่ง 2026-10-29)
	-- เฟส 4 (2026-10-27): คนขโมยเริ่มกดค้าง = แจ้งเจ้าของ + กรอบแดง/ป้าย 🚨 เหนือหัวคนขโมย (เห็นเฉพาะเจ้าของ) + ปุ่ม "ตบ" ที่ตัวคนขโมย
	--   ตบโดน = คนขโมยล้ม StunSeconds ขโมยถูกยกเลิก เสียตะกร้อ 1 เจ้าของได้ HandPrice × CatchReward (ตอนนี้ 0) ต้นนั้นพัก TreeCooldown
	SlapRange = 5, StunSeconds = 5, CatchReward = 0, -- ตบ: ระยะมือเปล่า (10 → 5) / ล้มกี่วิ / รางวัลจับขโมย (0 = ไม่มี ผู้ใช้สั่งเอาออก 2026-10-29)
	-- มือตบ (2026-10-29 ผู้ใช้สั่ง): ซื้อที่ร้านผลไม้ ถือไว้ = ตบคนขโมยได้ไกล SlapHandRange (มือเปล่า SlapRange) · ตบโดนตอนถืออยู่ = หมด 1 อัน
	SlapHandPrice = 1000000, -- 30000 → 1,000,000 (ผู้ใช้สั่ง 2026-10-29)
	SlapHandRange = 10, -- ถือมือตบ 30 → 10 (ผู้ใช้สั่ง 2026-10-29)
	SlapHandIcon = "🖐️",
	SlapHandNameTh = "มือตบ", SlapHandNameEn = "Slap hand",
	-- ตะกร้อจอมโจร (ผู้ใช้สั่ง 2026-11-02): คราฟที่โต๊ะช่างนากน้อย (CraftConfig สูตร BanditPicker) ใช้ได้ครั้งเดียวเหมือนตะกร้อธรรมดา แต่ขโมยไวขึ้น
	--   Tool เดิม IsStealHand + Attribute StealTier = "Bandit" (กองแยกจากตะกร้อธรรมดา) · SecondsMult คูณ Seconds (ปัดขึ้น) มะม่วง 5 วิ ทุเรียน 13 วิ
	Tiers = {
		Bandit = { NameTh = "ตะกร้อจอมโจร", NameEn = "Bandit picker", Icon = "🦝", SecondsMult = 0.5, Template = "BanditPicker" }, -- ไอคอนแรคคูน (หน้ากากโจร) เดิม 🥷 แต่ Roblox ไม่มีอิโมจินี้ ขึ้นเป็นกล่อง
	},
}

-- เวลากดค้างขโมยของต้นชนิดนี้ ตามตะกร้อที่ถือ (tier nil = ตะกร้อธรรมดา)
function OrchardConfig.StealSeconds(kind, tier)
	local base = OrchardConfig.Steal.Seconds[kind] or 30
	local t = tier and OrchardConfig.Steal.Tiers[tier]
	return t and math.ceil(base * t.SecondsMult) or base
end

-- ชื่อ/ไอคอนตะกร้อตาม tier
function OrchardConfig.HandInfo(tier, lang)
	local s = OrchardConfig.Steal
	local t = tier and s.Tiers[tier]
	if t then return (lang == "en" and t.NameEn or t.NameTh), t.Icon end
	return (lang == "en" and s.HandNameEn or s.HandNameTh), s.HandIcon
end

function OrchardConfig.StageName(stage, lang)
	local n = OrchardConfig.StageNames[stage]
	if not n then return tostring(stage) end
	return lang == "en" and n.en or n.th
end

-- ขั้นของต้น ณ เวลา now คืน stage, nextAt (เวลาเปลี่ยนขั้นถัดไป, nil = สุกแล้ว รอเก็บ)
-- tree = { kind, plantedAt, cycleStart } (cycleStart = เริ่มรอบผลปัจจุบัน ครั้งแรก = plantedAt + GrowSeconds)
function OrchardConfig.StageAt(tree, now)
	local def = OrchardConfig.Trees[tree.kind]
	if not def then return nil, nil end
	if tree.dead then return "Dead", nil end -- ต้นแห้ง (2026-11-02)
	local grow = def.GrowSeconds
	local matureAt = tree.plantedAt + grow
	if now < tree.plantedAt + grow / 3 then return "Sapling", tree.plantedAt + grow / 3 end
	if now < tree.plantedAt + grow * 2 / 3 then return "Young", tree.plantedAt + grow * 2 / 3 end
	if now < matureAt then return "Grown", matureAt end
	local c = math.max(tree.cycleStart or matureAt, matureAt)
	local flowerEnd = c + def.FruitSeconds * OrchardConfig.FLOWER_PART
	local ripeAt = c + def.FruitSeconds
	if now < c then return "Grown", c end
	if now < flowerEnd then return "Flower", flowerEnd end
	if now < ripeAt then return "Green", ripeAt end
	return "Ripe", nil
end

-- เวลาที่ผลจะสุก (รวมช่วงต้นโต) ป้ายเหนือต้นนับถอยหลังถึงจุดนี้ 2026-11-06
function OrchardConfig.RipeAt(tree)
	local def = OrchardConfig.Trees[tree.kind]
	if not def then return nil end
	local matureAt = tree.plantedAt + def.GrowSeconds
	return math.max(tree.cycleStart or matureAt, matureAt) + def.FruitSeconds
end

-- เก็บได้อีกกี่รอบ (nil = ไม่จำกัด) tree = ข้อมูลต้น (harvests = เก็บไปแล้วกี่รอบ)
function OrchardConfig.HarvestsLeft(tree)
	local def = tree and OrchardConfig.Trees[tree.kind]
	if not (def and def.Harvests) then return nil end
	return math.max(0, def.Harvests - (tree.harvests or 0))
end

function OrchardConfig.NameOf(kind, lang)
	local def = OrchardConfig.Trees[kind]
	if not def then return tostring(kind) end
	return lang == "en" and def.NameEn or def.NameTh
end

-- 1500000 -> "1.5M" · 25000 -> "25k"
-- ลายแปลงปลูก (สกินหลุม, 2026-10-28 ผู้ใช้สั่ง) ซื้อที่ร้านป้าแตงไทย ซื้อครั้งเดียวได้ตลอด ใส่ทีเดียวทั้ง 6 หลุมในล็อกของเรา คนอื่นเห็นด้วย ไม่มีผลกับต้น
-- โมเดล = ReplicatedStorage.OrchardHoleSkins.<Id> (จุดกลาง = กลางหลุม) · "Classic" = หลุมเดิม ฟรี
OrchardConfig.HoleSkins = {
	{ Id = "Classic", NameTh = "หลุมคลาสสิก", NameEn = "Classic", Tier = "Free", Price = 0 },
	{ Id = "PinkPastel", NameTh = "ขอบชมพูพาสเทล", NameEn = "Pastel Pink", Tier = "Common", Price = 300000 },
	{ Id = "WoodBox", NameTh = "กรอบไม้สี่เหลี่ยม", NameEn = "Wooden Box", Tier = "Common", Price = 500000 },
	{ Id = "Brick", NameTh = "อิฐแดงสี่เหลี่ยม", NameEn = "Red Brick", Tier = "Common", Price = 800000 },
	{ Id = "Daisy", NameTh = "ดอกเดซี่", NameEn = "Daisy", Tier = "Rare", Price = 2500000 },
	{ Id = "Candy", NameTh = "ลูกกวาด", NameEn = "Candy", Tier = "Rare", Price = 3000000 },
	{ Id = "Mushroom", NameTh = "เห็ดจุด", NameEn = "Spotted Mushroom", Tier = "Rare", Price = 4000000 },
	{ Id = "Watermelon", NameTh = "แตงโม", NameEn = "Watermelon", Tier = "Epic", Price = 6000000 },
	{ Id = "Heart", NameTh = "หัวใจ", NameEn = "Heart", Tier = "Epic", Price = 8000000 },
	{ Id = "Star", NameTh = "ดาวทอง", NameEn = "Gold Star", Tier = "Epic", Price = 10000000 },
	{ Id = "CatFace", NameTh = "หน้าแมว", NameEn = "Kitty Face", Tier = "Legendary", Price = 20000000 },
	{ Id = "Rainbow", NameTh = "สายรุ้ง", NameEn = "Rainbow", Tier = "Legendary", Price = 25000000 },
	{ Id = "MangoQueen", NameTh = "ราชินีมะม่วง", NameEn = "Mango Queen", Tier = "Legendary", Price = 50000000 },
}
OrchardConfig.HoleSkinById = {}
for i, s in ipairs(OrchardConfig.HoleSkins) do
	s.Order = i
	OrchardConfig.HoleSkinById[s.Id] = s
end
OrchardConfig.TierColors = {
	Free = Color3.fromRGB(170, 150, 120), Common = Color3.fromRGB(120, 180, 110), Rare = Color3.fromRGB(90, 160, 235),
	Epic = Color3.fromRGB(185, 110, 230), Legendary = Color3.fromRGB(245, 170, 40),
}

function OrchardConfig.Short(n)
	if n >= 1e6 then return (string.format("%.2f", n / 1e6):gsub("%.?0+$", "")) .. "M" end
	if n >= 1e3 then return (string.format("%.1f", n / 1e3):gsub("%.?0+$", "")) .. "k" end
	return tostring(n)
end

-- ชนิดนี้เปิดให้ซื้อเมล็ด/ปลูกแล้วหรือยัง (Open = false = ยังไม่เปิด)
function OrchardConfig.IsOpen(kind)
	local def = OrchardConfig.Trees[kind]
	return def ~= nil and def.Open ~= false
end

function OrchardConfig.SortedKinds()
	local list = {}
	for id in pairs(OrchardConfig.Trees) do table.insert(list, id) end
	table.sort(list, function(a, b) return OrchardConfig.Trees[a].Order < OrchardConfig.Trees[b].Order end)
	return list
end

return OrchardConfig
