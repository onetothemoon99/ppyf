-- BACKUP 2026-11-12 before "seats3" (RiversideLog / DuckFloat / KrathongPavilion)
-- Studio path: ReplicatedStorage.MountConfig
-- Restore: open that script in Studio, replace its whole Source with everything below the line of dashes.
-- ------------------------------------------------------------
-- MountConfig: ตู้สุ่มสัตว์ขี่ (2026-10-15) — รายชื่อสัตว์ขี่ ราคา อัตราออก (ใช้ทั้ง server และหน้าจอ)
-- สุ่มด้วยเหรียญอย่างเดียว · ได้ตัวซ้ำ = คืนเหรียญครึ่งหนึ่งของราคาสุ่ม
-- อัตราออกต่อระดับอยู่ใน RarityRates ส่วนในระดับเดียวกันแบ่งตาม Weight ของแต่ละตัว
-- ตัวที่มี Season = มีในตู้เฉพาะตอน SeasonConfig.IsActive(Season) (หมดเทศกาลแล้วคนที่ได้ไปยังขี่ได้ตลอด)
--   อัตราของตัวเทศกาลหักจากระดับ SeasonTakesFrom
-- ตัวที่มี Release = ยังไม่อยู่ในตู้จนกว่า SeasonConfig.HasStarted(Release) (เริ่มแล้วอยู่ตลอดไป) · SeasonRate ของมันหักจาก SeasonTakesFrom เหมือนตัวเทศกาล (2026-10-31)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeasonConfig = require(ReplicatedStorage:WaitForChild("SeasonConfig"))

local MountConfig = {}

-- สวิตช์เปิดระบบสัตว์ขี่ทั้งหมด (ตู้สุ่ม + ขี่ + เมนู) 2026-10-16 ผู้ใช้สั่ง "ซ่อนตู้สุ่มสัตว์ขี่ไว้ก่อน ยังไม่อยากเอาเข้าไป"
-- false = ตู้ไม่ขึ้นในแมพ (เซิร์ฟย้ายออกตอนเปิด) ไม่มีเมนู "สัตว์ขี่" เซิร์ฟปฏิเสธการสุ่ม/ขี่ · ปล่อยจริง: เปลี่ยนเป็น true แล้ว Publish
-- ลองใน Studio ทั้งที่ปิดอยู่: ตั้ง Attribute DevMountOn = true บน ReplicatedStorage ก่อนกด Play (มีผลเฉพาะใน Studio)
MountConfig.Enabled = true -- 2026-10-19 เปิดอีกครั้ง (ผู้ใช้: "เปิดระบบสัตว์ขี่และของตกแต่งให้ที") · ซ่อน = false
function MountConfig.IsEnabled()
	if MountConfig.Enabled then return true end
	return game:GetService("RunService"):IsStudio() and game:GetService("ReplicatedStorage"):GetAttribute("DevMountOn") == true
end

MountConfig.RollPrice = 100000 -- 2026-10-16 ผู้ใช้สั่ง (เดิม 15000)
MountConfig.DupeRefund = math.floor(MountConfig.RollPrice / 2)
MountConfig.MultiRollCount = 10 -- ปุ่มสุ่ม 10 ครั้ง (ไม่มีส่วนลด)

-- ระดับ เรียงจากต่ำไปสูง
MountConfig.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Secret", "Premium", "Kindness" } -- Kindness 2026-11-03 สัตว์ขี่ร้านแลกน้ำใจ -- 2026-10-16 เอาระดับไม่ธรรมดาออก (แกะย้ายไปหายาก)
MountConfig.Rarities = {
	Common = { Name = "ธรรมดา", NameEn = "Common", Color = Color3.fromRGB(200, 200, 200) },
	Uncommon = { Name = "ไม่ธรรมดา", NameEn = "Uncommon", Color = Color3.fromRGB(120, 220, 120) },
	Rare = { Name = "หายาก", NameEn = "Rare", Color = Color3.fromRGB(90, 170, 255) },
	Epic = { Name = "มหากาพย์", NameEn = "Epic", Color = Color3.fromRGB(190, 110, 255) },
	Legendary = { Name = "ตำนาน", NameEn = "Legendary", Color = Color3.fromRGB(255, 200, 60) },
	Secret = { Name = "ลับ", NameEn = "Secret", Color = Color3.fromRGB(255, 120, 200) },
	Premium = { Name = "พรีเมียม", NameEn = "Premium", Color = Color3.fromRGB(170, 110, 235) }, -- ซื้อด้วย Robux ในร้านค้าพิเศษ ไม่อยู่ในตู้
	Kindness = { Name = "น้ำใจ", NameEn = "Kindness", Color = Color3.fromRGB(110, 210, 130) }, -- แลกด้วยเหรียญช่วยเหลือที่ร้านแลกน้ำใจ (สวนผลไม้) ไม่อยู่ในตู้ 2026-11-03
}

-- อัตราออกต่อระดับ (%) ตอนไม่มีเทศกาล รวม 100
-- 2026-10-17 ผู้ใช้ส่งตารางเรทใหม่ (รูป): ทุกชิ้นตั้ง Weight = % ตรงตัว ส่วนที่เหลือทั้งหมดเป็นเหรียญ 10,000 (FillerItem)
MountConfig.RarityRates = { Common = 87.813, Rare = 9.016, Epic = 1.816, Legendary = 1.355 } -- 2026-10-18 สัตว์ขี่ + ของตกแต่ง ×0.9 (ผู้ใช้: ยากขึ้น 10%)
-- ชิ้นที่รับส่วนที่เหลือของระดับ: ของเทศกาล (ลับ) หักจากชิ้นนี้ชิ้นเดียว ชิ้นอื่นในระดับเดียวกันคง % เดิมเป๊ะ
MountConfig.FillerItem = "CoinPrize" -- 2026-10-16 ผู้ใช้: ให้ได้สัตว์ยากขึ้น (เดิม 55/25/15/4/1) ธรรมดามีเศษเพชร/ทับทิมปน
MountConfig.SeasonTakesFrom = "Common"
MountConfig.AnnounceFrom = "Epic" -- ได้ระดับนี้ขึ้นไป = ประกาศทั้งเซิร์ฟ

-- Icon = อีโมจิแทนรูป (ก่อนมีโมเดล), Speed = ตัวคูณความเร็วเดิน (และวิ่ง ถ้าไม่มี RunSpeed), RunSpeed = ตัวคูณตอนวิ่งแยก, Jump = ตัวคูณแรงกระโดด, Perk = ความสามารถพิเศษ (ทำในขั้นที่ 6)
MountConfig.Mounts = {
	CalmTurtle = {
		Order = 1, Icon = "🐢", Rarity = "Common", Weight = 9, -- 2026-10-16 ลดจาก 13 (เพิ่มของตกแต่ง ผู้ใช้: ให้สัตว์ขี่ได้ยากขึ้น)
		DisplayName = "เต่าผู้ใจเย็น", DisplayNameEn = "Calm Turtle",
		Speed = 0.54, RunSpeed = 16 / 26, Jump = 1, Perk = "Steady", Swim = true, -- Swim 2026-10-23 (ผู้ใช้: เต่าจมน้ำตอนน้ำลึก) ลอยครึ่งน้ำแบบคาปิบาร่า -- เดิน 8.64 (ช้ากว่าเดินเอง) / วิ่ง 16 = เท่าผู้เล่นเดินปกติ
		Desc = "เดินช้าๆ ใจเย็นตามชื่อ โดนชนก็ไม่ล้ม ว่ายน้ำได้", DescEn = "Slow and steady. Never gets knocked over, and it can swim.",
	},
	FluffyBunny = {
		Order = 2, Icon = "🐰", Rarity = "Rare", Weight = 1.134, -- เดิม 2.3 -- 2026-10-16 ผู้ใช้ย้ายจากธรรมดาเป็นหายาก
		DisplayName = "กระต่ายขนปุย", DisplayNameEn = "Fluffy Bunny",
		Speed = 1.15, Jump = 1.5, Perk = "Bouncy",
		Desc = "กระโดดสูงขึ้น เด้งดึ๋งตามจังหวะเดิน", DescEn = "Jumps higher and bounces as it walks.",
	},
	CloudSheep = {
		Order = 3, Icon = "🐑", Rarity = "Rare", Weight = 1.134, -- เดิม 1.9
		DisplayName = "แกะปุยเมฆ", DisplayNameEn = "Cloud Sheep",
		Speed = 1.15, Jump = 1, Perk = "SlowFall",
		Desc = "ตกจากที่สูงจะลอยลงช้าๆ เหมือนนั่งเมฆ", DescEn = "Floats down gently like a cloud.",
	},
	WildHorse = {
		Order = 4, Icon = "🐴", Rarity = "Rare", Weight = 1.134, -- เดิม 2.3
		DisplayName = "ม้าผู้พยศ", DisplayNameEn = "Wild Horse",
		Speed = 1.4, Jump = 1.1, Perk = "Rear",
		Desc = "วิ่งไวขึ้น ยกขาหน้าตอนขึ้นขี่", DescEn = "Runs fast and rears up when you mount.",
	},
	ChillCapybara = {
		Order = 5, Icon = "🐹", Rarity = "Rare", Weight = 1.134, -- เดิม 1.5
		DisplayName = "คาปิบาร่าสายชิล", DisplayNameEn = "Chill Capybara",
		Speed = 1.4, Jump = 1, Perk = "Swim",
		Desc = "ว่ายน้ำได้ ลงทะเลหรือทะเลสาบโดยไม่ต้องลงจากหลัง", DescEn = "Swims in the sea and lakes while you ride.",
	},
	SakuraDeer = {
		Order = 6, Icon = "🦌", Rarity = "Epic", Weight = 0.486, -- เดิม 2.4
		DisplayName = "กวางซากุระ", DisplayNameEn = "Sakura Deer",
		Speed = 1.6, Jump = 1.2, Perk = "PetalTrail",
		Desc = "วิ่งเร็ว กลีบซากุระร่วงเป็นทางตามหลัง", DescEn = "Fast, leaves a trail of sakura petals.",
	},
	RainbowUnicorn = {
		Order = 7, Icon = "🦄", Rarity = "Legendary", Weight = 0.405, -- เดิม 0.6
		DisplayName = "ยูนิคอร์นสายรุ้ง", DisplayNameEn = "Rainbow Unicorn",
		Speed = 1.8, Jump = 1.2, Perk = "DoubleJump",
		Desc = "เร็วที่สุด กระโดดสองชั้นได้ ทิ้งรอยสายรุ้ง", DescEn = "Fastest. Double jump and a rainbow trail.",
	},
	WitchCatBroom = {
		Order = 8, Icon = "🧹", Rarity = "Secret", Weight = 0.162, Season = "Halloween2026", SeasonRate = 0.162, -- 2026-10-17 Weight = SeasonRate (เดิม 1) ให้ไม้กวาดคง 0.5 หลังหมวกเหลือ 0.07
		DisplayName = "ไม้กวาดแมวเหมียวแม่มด", DisplayNameEn = "Witch Cat Broom",
		Speed = 1.7, Jump = 1, Perk = "Hover",
		Desc = "บินได้อิสระ ขึ้นสูงลงต่ำตามใจ ร่อนข้ามน้ำได้ (ร้านค้าสุดพิเศษ)", DescEn = "Fly freely, up and down as you like, even over water (Special Shop).",
	},
	-- 2026-10-31 ผู้ใช้สั่ง: วัว + ควาย ระดับตำนาน ปล่อยพร้อมจริงใจจิงโจ้ (Release = เริ่มแล้วอยู่ในตู้ตลอดไป) เรทเพิ่มตัวละ 0.3% หักจากเหรียญ 10,000
	ThaiCow = {
		Order = 11, Icon = "🐄", Rarity = "Epic", Weight = 0.486, Release = "JingjaiGacha2026", SeasonRate = 0.486, -- 2026-10-31 ผู้ใช้ย้ายเป็นมหากาพย์ (เดิมตำนาน 0.3) เรทเท่ากวางซากุระ
		DisplayName = "วัวมอมอ", DisplayNameEn = "Momo the Cow", -- เดิม "วัวน้อยกระดิ่งทอง" ผู้ใช้เปลี่ยน 2026-10-31
		Speed = 1.65, Jump = 1.3, Perk = "Moo",
		Desc = "ร้องมอ~ ตอนขึ้นขี่ เดินแล้วมีดอกไม้ผุดตามทาง", DescEn = "Moos when you mount, flowers pop up along the way.",
	},
	ThaiBuffalo = {
		Order = 12, Icon = "🐃", Rarity = "Epic", Weight = 0.486, Release = "JingjaiGacha2026", SeasonRate = 0.486, -- 2026-10-31 ผู้ใช้ย้ายเป็นมหากาพย์ (เดิมตำนาน 0.3) เรทเท่ากวางซากุระ
		DisplayName = "เจ้าทุย", DisplayNameEn = "Tui the Buffalo", -- เดิม "ควายทุ่งผ้าขาวม้า" ผู้ใช้เปลี่ยน 2026-10-31
		Speed = 1.6, Jump = 1, Perk = "MudSplash", Swim = true, Steady = true, -- Steady (2026-10-31): โดนชนไม่ล้มแบบเต่า แม้ Perk ไม่ใช่ "Steady"
		Desc = "ว่ายน้ำได้ โดนชนก็ไม่ล้ม วิ่งแล้วโคลนกระเซ็น", DescEn = "Swims, never gets knocked over, and splashes mud as it runs.",
	},
	-- 2026-10-31 ผู้ใช้สั่ง (ส่งรูปอ้างอิง): ทุยเผือก ระดับตำนาน ปล่อยพร้อมจริงใจจิงโจ้แบบเดียวกับเจ้าทุย/วัวมอมอ เรท 0.3% หักจากเหรียญ 10,000
	AlbinoBuffalo = {
		Order = 14, Icon = "🐃", Rarity = "Legendary", Weight = 0.3, Release = "JingjaiGacha2026", SeasonRate = 0.3,
		DisplayName = "เจ้าทุยเผือก", DisplayNameEn = "Albino Tui", -- เดิม "ทุยเผือก" ผู้ใช้เปลี่ยน 2026-10-31
		Speed = 1.6, Jump = 1, Perk = "Moo", Swim = true, Steady = true,
		Desc = "ว่ายน้ำได้ โดนชนก็ไม่ล้ม เดินแล้วมีดอกไม้ผุดตามทาง", DescEn = "Swims, never gets knocked over, flowers pop up along the way.",
	},
	-- 2026-10-31 ผู้ใช้สั่ง: ม้าก้านกล้วย สัตว์ลับแทนไม้กวาด ออกช่วงอีเวนต์จริงใจจิงโจ้ 1–23 พ.ย. (เรทเท่าไม้กวาด)
	BananaHorse = {
		Order = 13, Icon = "🍌", Rarity = "Secret", Weight = 0.162, Season = "JingjaiGacha2026", SeasonRate = 0.162,
		DisplayName = "ม้าก้านกล้วย", DisplayNameEn = "Banana Stalk Horse",
		Speed = 1.7, Jump = 1.2, Perk = "Gallop", Fly = true, -- 2026-10-31 ผู้ใช้: ท่าขี่แบบไม้กวาดแมวเหมียว (นั่งคร่อม ก้านลอย) เดิม StandRide = true (ยืนวิ่งคร่อม) -- Fly 2026-10-31 ผู้ใช้สั่ง: บินได้แบบไม้กวาด/ลามะ (MountClient canFly) -- StandRide: ยืนวิ่งคร่อมก้านกล้วยเอง (ไม่นั่ง เท้าแตะพื้น ท่าวิ่งปกติ)
		Desc = "บินได้อิสระ ควบกระโดดเป็นจังหวะ ใบตองปลิวตามทาง (เฉพาะอีเวนต์จริงใจจิงโจ้)", DescEn = "Flies freely, gallops in little hops, banana leaves flutter behind (Jingjai event only).",
	},
	-- 2026-11-03 ผู้ใช้เลือก: สัตว์ขี่เอ็กซ์คลูซีฟร้านแลกน้ำใจ (สวนผลไม้) ไม่อยู่ในตู้ · HelpShop = ราคาเหรียญช่วยเหลือ (ขายจริงตาม OrchardConfig.HelpShop)
	--   ความสามารถ: ขี่อยู่กดรดน้ำช่วยต้นแห้งเพื่อนได้เลย ใช้เวลา HelpHoldScale เท่า (OrchardService/OrchardGui)
	KindElephant = {
		Order = 15, Icon = "🐘", Rarity = "Kindness", Weight = 0, HelpShop = 500, HelpHoldScale = 0.5,
		DisplayName = "ช้างน้อยใจบุญ", DisplayNameEn = "Kind Little Elephant",
		Speed = 1.6, Jump = 1, Perk = "KindSpray",
		TrunkWater = Vector3.new(0, 3.9, -3.5), -- ขี่แล้วรดน้ำต้นไม้ = งวงพ่นน้ำแทนบัว (ตำแหน่งปลายงวงเทียบ MountRoot, OrchardService.startPour)
		Desc = "งวงพ่นน้ำ หัวใจลอยตามทาง ขี่อยู่รดน้ำช่วยต้นแห้งเพื่อนได้เร็วขึ้นเท่าตัว (ร้านแลกน้ำใจ)", DescEn = "Sprays water from its trunk with hearts trailing behind. Water a friend's dead tree twice as fast while riding (Kindness shop).",
	},
	-- ร้านค้าพิเศษ (Robux) 2026-10-16 ผู้ใช้ขอ: โมเดลตามรูปลามะขนครีม ผ้าปักแดง-เขียวหัวเป็ด ถือโคมม่วง · ไม่อยู่ในตู้สุ่ม
	-- Shop = { GamePassId = Game Pass ที่ผู้ใช้สร้าง (2026-10-16 "ลามะไม่ใช่ลามะ" 540 R$ ราคาจริงอ่านจาก Roblox), PriceRobux = ราคาสำรองไว้แสดงถ้าอ่านไม่ได้ }
	--   ซื้อครั้งเดียว ได้สัตว์ขี่ถาวร · มี Game Pass แล้วเข้าเกมเมื่อไหร่ก็ได้สัตว์คืน (MountShopService)
	MagicLlama = {
		Order = 9, Icon = "🦙", Rarity = "Premium", Weight = 0, Shop = { GamePassId = 2039540565, PriceRobux = 299, GiftProductId = 3719679834 }, -- 2026-10-19 ผู้ใช้: ราคาต้อง 299 (เดิม 540) · ราคาที่คิดจริงตั้งที่ Game Pass บน Creator Hub
		DisplayName = "ลามะไม่ลานะ", DisplayNameEn = "Never-Goodbye Llama",
		Speed = 1.8, Jump = 1.2, Perk = "MagicTrail",
		Fly = true, -- 2026-10-16 ผู้ใช้: บินได้แบบไม้กวาด (ขายเป็น Robux) · MountClient บินอิสระ + ข้ามน้ำได้
		Desc = "บินได้อิสระ เร็วเท่ายูนิคอร์น เดินแล้วมีดาวกับต้นอ่อนผุดตามทาง (ร้านค้าพิเศษ)", DescEn = "Flies freely, as fast as the unicorn, sprouts and stars pop up along the way (special shop).",
	},
}

-- ของที่สุ่มได้จากตู้ที่ไม่ใช่สัตว์ขี่ (2026-10-16 ผู้ใช้: ไม่มีระบบแลก ให้สัตว์ขี่ออกยาก และเป็นที่เบิร์นเหรียญ ไม่ให้เงินเฟ้อ)
-- ประวัติ: เศษเพชร/ทับทิม → เกือกม้านำโชค (แลกสัตว์ได้ ยกเลิก) → แคปซูลเปล่า → หุ่นฟางดวงดี
MountConfig.Items = {
	-- 2026-10-16 ผู้ใช้: ของปลอบใจเป็นของในฟาร์ม เช่น หุ่นฟางดวงดี (แทนแคปซูลเปล่า) · ไม่มีระบบแลก ไม่คืนเหรียญ
	-- Currency = "Booster": ให้หุ่นระดับ BoosterTier (LuckConfig.BoosterTiers) Amount ตัวเข้ากระเป๋า · Currency = "Coins": ให้เหรียญ Amount
	-- 2026-10-17 ผู้ใช้: เปลี่ยน "หุ่นฟางดวงดี x10" เป็นเหรียญ 10,000 (ของซ้ำยังได้หุ่นฟาง ดู DupeScarecrowAmount)
	CoinPrize = {
		Order = 10, Icon = "💰", Rarity = "Common", Weight = 67.213, Currency = "Coins", Amount = 10000,
		DisplayName = "เหรียญ 10,000", DisplayNameEn = "10,000 Coins",
		Desc = "ได้เหรียญ 10,000", DescEn = "Get 10,000 coins.",
	},
}

-- ของแต่งสัตว์ขี่ (2026-10-16 ผู้ใช้: เพิ่มของแต่งเข้าตู้ ให้ได้สัตว์ขี่น้อยลงเหลือ ~25%) ชิ้นบนหัว 1 ช่อง ใส่กับสัตว์ขี่ตัวไหนก็ได้
-- โมเดล: ServerStorage.MountAccessories.<id> (จุดหมุนอยู่ใต้ชิ้น) วางที่ Attribute HeadPoint ของแม่แบบสัตว์ · รูปในตู้: MountPreviewModels.<id>
-- ได้ซ้ำ = คืนเหรียญ DupeRefund (ครึ่งราคาสุ่ม เดิมหุ่นฟาง เปลี่ยน 2026-10-20) · Weight = % ในระดับนั้นตอนไม่มีเทศกาล
MountConfig.Accessories = {
	PinkBow = { Order = 20, Icon = "🎀", Rarity = "Common", Weight = 4, Scale = 1,
		DisplayName = "โบว์ชมพู", DisplayNameEn = "Pink Bow", Desc = "ของแต่งสัตว์ขี่ ติดบนหัวสัตว์ตัวที่ขี่", DescEn = "Mount accessory, worn on your mount's head." },
	FlowerCrown = { Order = 21, Icon = "🌸", Rarity = "Common", Weight = 4, Scale = 1,
		DisplayName = "มงกุฎดอกไม้", DisplayNameEn = "Flower Crown", Desc = "ของแต่งสัตว์ขี่ ติดบนหัวสัตว์ตัวที่ขี่", DescEn = "Mount accessory, worn on your mount's head." },
	TinyTopHat = { Order = 22, Icon = "🎩", Rarity = "Rare", Weight = 1.6, -- เดิม 7
		 Scale = 1, Hat = true, -- Hat = หมวกจริง: สัตว์ที่มีหมวกในตัว (Attribute HatCoverPoint) ขยายครอบหมวกเดิม 2026-10-17
		DisplayName = "หมวกทรงสูงจิ๋ว", DisplayNameEn = "Tiny Top Hat", Desc = "ของแต่งสัตว์ขี่ ติดบนหัวสัตว์ตัวที่ขี่", DescEn = "Mount accessory, worn on your mount's head." },
	GoldCrown = { Order = 23, Icon = "👑", Rarity = "Epic", Weight = 0.7, -- เดิม 1.6
		 Scale = 1,
		DisplayName = "มงกุฎทอง", DisplayNameEn = "Gold Crown", Desc = "ของแต่งสัตว์ขี่ ติดบนหัวสัตว์ตัวที่ขี่", DescEn = "Mount accessory, worn on your mount's head." },
	AngelHalo = { Order = 24, Icon = "😇", Rarity = "Legendary", Weight = 0.5, -- เดิม 0.4
		 Scale = 1, Float = 0.5,
		DisplayName = "วงแหวนนางฟ้า", DisplayNameEn = "Angel Halo", Desc = "ของแต่งสัตว์ขี่ ลอยเรืองแสงเหนือหัว", DescEn = "Mount accessory, a glowing halo floating above the head." },
	PumpkinWitchHat = { Order = 25, Icon = "🎃", Rarity = "Secret", Weight = 0.2, Season = "Halloween2026", SeasonRate = 0.2, -- 2026-10-17 ผู้ใช้: เรท 0.07 (เดิม 0.5) · Weight = SeasonRate ให้แบ่งในระดับลับตรงตัว
		 Scale = 1, Hat = true,
		DisplayName = "หมวกฟักทองแม่มด", DisplayNameEn = "Pumpkin Witch Hat", Desc = "ของแต่งสัตว์ขี่ (ร้านค้าสุดพิเศษ)", DescEn = "Mount accessory (Special Shop)." },
}

-- แพ็กขายในร้านค้าสุดพิเศษ (Developer Product) 2026-11-04 ผู้ใช้สั่ง: ซื้อครั้งเดียวได้ครบทุกชิ้น · มีแล้วบางชิ้น = ยังซื้อได้ ได้ชิ้นที่ขาด · มีครบ = ซื้อไม่ได้
-- เซิร์ฟเวอร์: ServerScriptService.MountSystem.MountBundleShop · ในตู้สุ่มยังออกตามเทศกาลเหมือนเดิม
MountConfig.Bundles = {
	WitchBroomBundle = {
		ProductId = 3728218685, -- "ไม้กวาดแมวเหมียวแม่มด+หมวกแม่มด" 399 R$
		GiftProductId = 3728219050, -- "ของขวัญไม้กวาดแมวเหมียวแม่มด+หมวกแม่มด" 399 R$
		Mounts = { "WitchCatBroom" },
		Accessories = { "PumpkinWitchHat" },
		DisplayName = "ไม้กวาดแมวเหมียวแม่มด + หมวกฟักทองแม่มด", DisplayNameEn = "Witch Cat Broom + Pumpkin Witch Hat",
	},
}
function MountConfig.AccInPool(accId)
	local def = MountConfig.Accessories[accId]
	if not def then return false end
	if def.Season then return SeasonConfig.IsActive(def.Season) end
	return true
end

-- ของตกแต่ง (2026-10-16 ผู้ใช้: เพิ่มอุปกรณ์ตกแต่ง เช่น ที่นั่ง เปลนอน 5 ชิ้น ลดเรทสัตว์ขี่ลงอีก)
-- วางชั่วคราวข้างตัว ทีละ 1 ชิ้น ใครก็นั่งได้ เจ้าของออกเกม = หาย · นั่งตกปลา AFK แล้วโดนพากลับเซิร์ฟ = วางคืน + นั่งที่เดิม
-- Seats = จำนวนที่นั่ง, Pose = "Sit" / "Lie" (เปลนอน) / "Swing" (ชิงช้า) · โมเดล: ServerStorage.MountFurniture.<id> (ขั้นที่ 2)
-- ได้ซ้ำ = คืนเหรียญ DupeRefund (ครึ่งราคาสุ่ม ตั้งแต่ 2026-10-19) · Weight = % ในระดับนั้นตอนไม่มีเทศกาล
MountConfig.Furniture = {
	MushroomStool = { Order = 30, Icon = "🍄", Rarity = "Common", Weight = 3.6, Seats = 1, Pose = "Sit",
		DisplayName = "เก้าอี้ตอไม้เห็ด", DisplayNameEn = "Mushroom Stool", Desc = "ที่นั่ง วางข้างตัวแล้วนั่งได้ 1 คน", DescEn = "Seat. Place it and sit (1 seat)." },
	FlowerHammock = { Order = 31, Icon = "🌼", Rarity = "Rare", Weight = 1.44, Seats = 1, Pose = "Lie",
		DisplayName = "เปลนอนลายดอกไม้", DisplayNameEn = "Flower Hammock", Desc = "ที่นั่ง นอนเอนแกว่งเบาๆ", DescEn = "Seat. Lie back and sway gently." },
	CapyBeanbag = { Order = 32, Icon = "🐹", Rarity = "Rare", Weight = 1.44, Seats = 2, Pose = "Sit",
		DisplayName = "โซฟาคาปิบาร่า", DisplayNameEn = "Capybara Beanbag", Desc = "ที่นั่ง นั่งได้ 2 คน ชวนเพื่อนนั่งด้วย", DescEn = "Seat. Seats 2, bring a friend." },
	PicnicSet = { Order = 33, Icon = "🧺", Rarity = "Epic", Weight = 0.63, Seats = 4, Pose = "Sit",
		DisplayName = "ชุดปิกนิก", DisplayNameEn = "Picnic Set", Desc = "ที่นั่ง เสื่อ ตะกร้า ร่ม นั่งได้ 4 คน", DescEn = "Seat. Mat, basket and parasol, seats 4." },
	MoonSwing = { Order = 34, Icon = "🌙", Rarity = "Legendary", Weight = 0.45, Seats = 1, Pose = "Swing",
		DisplayName = "ชิงช้าพระจันทร์", DisplayNameEn = "Moon Swing", Desc = "ที่นั่ง นั่งแกว่ง มีดาวระยิบรอบตัว", DescEn = "Seat. Swing with twinkling stars." },
}
function MountConfig.FurnInPool(furnId)
	local def = MountConfig.Furniture[furnId]
	if not def then return false end
	if def.Season then return SeasonConfig.IsActive(def.Season) end
	return true
end

-- (ไม่ใช้แล้ว 2026-10-20: ของซ้ำทุกแบบคืนเหรียญ DupeRefund) เดิม = หุ่นฟาง x50 จำนวนนี้ตอนได้ของแต่งซ้ำ
MountConfig.DupeScarecrowAmount = 10

-- ระบบแลกเกือกม้ายกเลิก (2026-10-16) เกือกม้าที่ใครมีค้างอยู่ในข้อมูลไม่มีที่ใช้ ไม่แสดง
MountConfig.ExchangeCost = {}
function MountConfig.ExchangeCostOf(mountId)
	return nil
end

-- ข้อมูลของรายการในตู้ (สัตว์ขี่หรือของ) ใช้ในหน้าต่างตู้/ผลสุ่ม
function MountConfig.Entry(id)
	return MountConfig.Mounts[id] or MountConfig.Items[id] or MountConfig.Accessories[id] or MountConfig.Furniture[id]
end

-- ตัวนี้มีในตู้ตอนนี้ไหม
function MountConfig.InPool(mountId)
	local def = MountConfig.Mounts[mountId]
	if not def then return false end
	if def.Shop then return false end -- ขายในร้านค้าพิเศษ ไม่อยู่ในตู้
	if def.HelpShop then return false end -- แลกที่ร้านแลกน้ำใจ ไม่อยู่ในตู้ (2026-11-03)
	if def.Release and not SeasonConfig.HasStarted(def.Release) then return false end
	if def.Season then return SeasonConfig.IsActive(def.Season) end
	return true
end

-- อัตราออกต่อระดับตอนนี้ (รวมตัวเทศกาลที่เปิดอยู่) คืน { [rarity] = % }
function MountConfig.CurrentRarityRates()
	local rates = table.clone(MountConfig.RarityRates)
	for mountId, def in pairs(MountConfig.Mounts) do
		if (def.Season or def.Release) and def.SeasonRate and MountConfig.InPool(mountId) then
			rates[def.Rarity] = (rates[def.Rarity] or 0) + def.SeasonRate
			rates[MountConfig.SeasonTakesFrom] -= def.SeasonRate
		end
	end
	for accId, def in pairs(MountConfig.Accessories) do
		if def.Season and def.SeasonRate and MountConfig.AccInPool(accId) then
			rates[def.Rarity] = (rates[def.Rarity] or 0) + def.SeasonRate
			rates[MountConfig.SeasonTakesFrom] -= def.SeasonRate
		end
	end
	for furnId, def in pairs(MountConfig.Furniture) do
		if def.Season and def.SeasonRate and MountConfig.FurnInPool(furnId) then
			rates[def.Rarity] = (rates[def.Rarity] or 0) + def.SeasonRate
			rates[MountConfig.SeasonTakesFrom] -= def.SeasonRate
		end
	end
	return rates
end

-- อัตราออกรายตัวตอนนี้ คืนรายการ { { id, rarity, chance (%) } } เรียงตาม Order (ใช้ทั้งสุ่มและแสดงหน้าตู้)
function MountConfig.CurrentPool()
	local rates = MountConfig.CurrentRarityRates()
	local weightSum = {}
	for mountId, def in pairs(MountConfig.Mounts) do
		if MountConfig.InPool(mountId) then
			weightSum[def.Rarity] = (weightSum[def.Rarity] or 0) + def.Weight
		end
	end
	for _, def in pairs(MountConfig.Items) do
		weightSum[def.Rarity] = (weightSum[def.Rarity] or 0) + def.Weight
	end
	for accId, def in pairs(MountConfig.Accessories) do
		if MountConfig.AccInPool(accId) then
			weightSum[def.Rarity] = (weightSum[def.Rarity] or 0) + def.Weight
		end
	end
	for furnId, def in pairs(MountConfig.Furniture) do
		if MountConfig.FurnInPool(furnId) then
			weightSum[def.Rarity] = (weightSum[def.Rarity] or 0) + def.Weight
		end
	end
	local pool = {}
	for mountId, def in pairs(MountConfig.Mounts) do
		if MountConfig.InPool(mountId) and (rates[def.Rarity] or 0) > 0 then
			table.insert(pool, { id = mountId, rarity = def.Rarity, chance = rates[def.Rarity] * def.Weight / weightSum[def.Rarity] })
		end
	end
	for itemId, def in pairs(MountConfig.Items) do
		if (rates[def.Rarity] or 0) > 0 then
			table.insert(pool, { id = itemId, rarity = def.Rarity, chance = rates[def.Rarity] * def.Weight / weightSum[def.Rarity], item = true })
		end
	end
	for accId, def in pairs(MountConfig.Accessories) do
		if MountConfig.AccInPool(accId) and (rates[def.Rarity] or 0) > 0 then
			table.insert(pool, { id = accId, rarity = def.Rarity, chance = rates[def.Rarity] * def.Weight / weightSum[def.Rarity], acc = true })
		end
	end
	for furnId, def in pairs(MountConfig.Furniture) do
		if MountConfig.FurnInPool(furnId) and (rates[def.Rarity] or 0) > 0 then
			table.insert(pool, { id = furnId, rarity = def.Rarity, chance = rates[def.Rarity] * def.Weight / weightSum[def.Rarity], furn = true })
		end
	end
	-- FillerItem: ชิ้นอื่นในระดับเดียวกันได้ % ตอนไม่มีเทศกาล (คงที่) ชิ้นนี้ได้ส่วนที่เหลือ (2026-10-17)
	local fillerId = MountConfig.FillerItem
	local fillerDef = fillerId and MountConfig.Items[fillerId]
	if fillerDef and (weightSum[fillerDef.Rarity] or 0) > 0 then
		local tier = fillerDef.Rarity
		local base = MountConfig.RarityRates[tier] or 0
		local others = 0
		for _, e in ipairs(pool) do
			if e.rarity == tier and e.id ~= fillerId then
				e.chance = base * MountConfig.Entry(e.id).Weight / weightSum[tier]
				others += e.chance
			end
		end
		for _, e in ipairs(pool) do
			if e.id == fillerId then e.chance = math.max(0, (rates[tier] or 0) - others) end
		end
	end
	-- เรียงตามระดับ ธรรมดา → ลับ (2026-10-16 ผู้ใช้ขอ) ในระดับเดียวกันโอกาสมากขึ้นก่อน
	table.sort(pool, function(a, b)
		local ra, rb = MountConfig.RarityRank(a.rarity), MountConfig.RarityRank(b.rarity)
		if ra ~= rb then return ra < rb end
		if math.abs(a.chance - b.chance) > 1e-9 then return a.chance > b.chance end
		return MountConfig.Entry(a.id).Order < MountConfig.Entry(b.id).Order
	end)
	return pool
end

-- สัตว์ขี่ที่ขายด้วย Robux จาก Developer Product (PurchaseRouter ใช้)
function MountConfig.ByProduct(productId)
	if type(productId) ~= "number" or productId <= 0 then return nil end
	for mountId, def in pairs(MountConfig.Mounts) do
		if def.Shop and def.Shop.ProductId == productId then return mountId, def end
	end
	return nil
end

function MountConfig.RarityRank(rarity)
	return table.find(MountConfig.RarityOrder, rarity) or 0
end

return MountConfig
