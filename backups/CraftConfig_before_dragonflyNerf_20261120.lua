-- BACKUP of game.ReplicatedStorage.CraftConfig (Studio Source, byte-exact, len 10742 hash 1116923509)
-- Restore: paste everything below this header into game.ReplicatedStorage.CraftConfig.Source in Studio.
-- CraftConfig: โต๊ะช่างนากน้อย เฟส 2 (2026-10-09) สูตรคราฟเบ็ด ใช้ทั้งเซิร์ฟเวอร์ (CraftBench) และหน้าต่าง (CraftBenchGui)
--   เบ็ดของผู้เล่น (Kind = "rod"): ได้เบ็ดใน FishingConfig.Rods (บันทึกใน FishingShop_v1 เหมือนซื้อ)
--   เบ็ดของน้องนาก (Kind = "petRod"): สัตว์ที่ช่วยตกปลาใช้คันที่ดีที่สุดที่มีเอง (บันทึกใน CraftBench_v1)
-- วัตถุดิบ = ปลา/ขยะในกระเป๋า (ใช้กองไม่ติดดาวก่อน แล้วค่อยกองติดดาว ⭐ · ดาวต่ำก่อน · 2026-10-14 กองติดดาวใช้คราฟได้แล้ว) + เหรียญ / "@Secret" = ปลาระดับลับชนิดใดก็ได้

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))

local CraftConfig = {}

-- เปิดพร้อมปลาชุดใหม่ 40 ชนิด (FishingConfig.FISH_V2 รวม DevFishV2 ใน Studio) ปิดอยู่ = โต๊ะยังขึ้นหน้าต่าง "เร็วๆ นี้"
CraftConfig.ENABLED = FishingConfig.FISH_V2 == true
-- Studio เท่านั้น: workspace Attribute DevCraftOn = true เปิดระบบคราฟโดยไม่เปิดปลาชุดใหม่ (กันนากตกปลาชุดใหม่เข้าบัญชีจริงตอนทดสอบ)
if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevCraftOn") == true then CraftConfig.ENABLED = true end

-- เบ็ดของน้องนาก (ใช้ใน FishingSystem ตอนสัตว์ช่วยตกปลา) Template = โมเดลใน ServerStorage.FishingTemplates
-- 2026-10-10 ผู้ใช้ขอ: หอยน้อยกับดาวทะเลแยกสายกัน ไม่มีอันไหนดีกว่า ผู้เล่นเลือกให้นากถือเอง (ช่องเบ็ดนากในเมนูสัตว์ / กด "ใช้" ในกระเป๋า)
--   LuckMult = คูณโชคเบ็ดเจ้าของ, HungerMult = ความหิวต่อปลา 1 ตัว (0.8 = หิวช้าลง 20%)
--   DoubleChance = โอกาสได้ปลา 2 ตัว (1 = ทุกครั้ง), BiteMult = เวลารอปลากินคูณ (1/1.5 = ตกเร็วขึ้น 50%)
--   ทุกคัน: นากได้ปลาถึงระดับลับ (PET_TIER_WEIGHTS ใช้เมื่อเบ็ดเจ้าของไม่มีระดับลับ)
CraftConfig.PET_TIER_WEIGHTS = { Common = 56, Rare = 33, Legendary = 10, Secret = 1 } -- เท่าเบ็ดดาวรุ้ง
CraftConfig.PET_TIER_LUCK = 3 -- โชคฐานของตารางข้างบน (เท่าเบ็ดดาวรุ้ง)
CraftConfig.PetRods = {
	Shell = {
		Rank = 1, Icon = "🐚", Name = "เบ็ดหอยน้อย", NameEn = "Little Shell Rod", Template = "PetRod_Shell",
		LuckMult = 2, HungerMult = 0.8, DoubleChance = 1,
		Bobber = "Bobber_PetShell", -- ทุ่นหอยสีแดง (โมเดลใน ServerStorage.FishingTemplates ไม่มี = ทุ่นธรรมดา)
	},
	Starfish = {
		Rank = 2, Icon = "⭐", Name = "เบ็ดดาวทะเล", NameEn = "Starfish Rod", Template = "PetRod_Starfish",
		LuckMult = 2, HungerMult = 0.8, BiteMult = 1 / 1.5,
		Bobber = "Bobber_PetPuffer", -- ทุ่นปลาปักเป้าสีแดง
	},
}
CraftConfig.PET_RODS_NEED_BOOK = true -- คราฟเบ็ดนากได้เมื่อสะสมปลาครบเล่ม (40 ชนิด) แล้ว

-- สูตร (เรียงตามที่แสดงในหน้าต่าง) ผู้ใช้ขอให้ยาก (2026-10-08): รักโลก ~11 ชม. หอยน้อย ~4 ชม. ดาวทะเล 15+ ชม. (เศษเพชรหายากสุด)
CraftConfig.Recipes = {
	{
		Id = "EarthLove", Kind = "rod", RodId = "EarthLove", Icon = "🌍",
		Name = "เบ็ดรักโลก", NameEn = "Earth Love Rod",
		Desc = "เบ็ดของคุณ · โชค x6 · ปลา 2 ดาวขึ้นไป · ตกได้ถึงปลาลับ",
		DescEn = "Your own rod · luck x6 · every fish 2 stars or better · catches up to Secret",
		-- 2026-10-11 ผู้ใช้ปรับสูตร (เดิม 200,000 เหรียญ + ขยะ 8 ชนิด + เพชร 4 ทับทิม 6)
		Coins = 1000000,
		Materials = {
			{ "OldTire", 50 }, { "TornNet", 30 }, { "BambooScrap", 35 }, { "PlasticBottle", 50 },
			{ "DiamondShard", 8 }, { "RubyShard", 5 },
		},
	},
	{
		-- 2026-11-20 เบ็ดแมลงปอน้อย (ผู้ใช้สั่ง): ปลาตามลำธาร/คลอง + หอยทาก (ปลาลับ) 1 ตัว · DevOnly = ซ่อนการ์ดในเซิร์ฟจริง (ดู FishingConfig.IsHiddenRod ท้ายไฟล์)
		Id = "Dragonfly", Kind = "rod", RodId = "Dragonfly", Icon = "💧", -- 🪾 ไม่มีในฟอนต์ Roblox
		Name = "เบ็ดแมลงปอน้อย", NameEn = "Little Dragonfly Rod",
		Desc = "เบ็ดของคุณ · โชค x6 · ปลา 2 ดาวขึ้นไป · ตกในลำธารได้ปลาหายากง่ายขึ้น · แมลงปอบินวนรอบตัว",
		DescEn = "Your own rod · luck x6 · every fish 2 stars or better · rarer fish in streams · a dragonfly flies around you",
		DevOnly = true,
		Coins = 900000,
		Materials = {
			{ "WaterStrider", 80 }, { "Rasbora", 60 }, { "Leech", 40 }, { "Betta", 20 },
			{ "GlowSnail", 1 }, { "DiamondShard", 5 },
		},
	},
	{
		Id = "PetShell", Kind = "petRod", PetRodId = "Shell", Icon = "🐚",
		Name = "เบ็ดหอยน้อย", NameEn = "Little Shell Rod",
		Desc = "เบ็ดของน้องนาก · ได้ปลาถึงระดับลับ · โชค x2 · หิวช้าลง 20% · ได้ปลา x2 ทุกครั้ง",
		DescEn = "For your otter · catches up to Secret · luck x2 · gets hungry 20% slower · every catch x2",
		Coins = 500000,
		Materials = { { "DiamondShard", 5 }, { "Scallop", 50 }, { "Straw", 50 } },
	},
	{
		Id = "PetStarfish", Kind = "petRod", PetRodId = "Starfish", Icon = "⭐",
		-- 2026-10-10: ไม่ต้องมีหอยน้อยก่อนแล้ว (แยกสายกัน ผู้เล่นเลือกเอง)
		Name = "เบ็ดดาวทะเล", NameEn = "Starfish Rod",
		Desc = "เบ็ดของน้องนาก · ได้ปลาถึงระดับลับ · โชค x2 · หิวช้าลง 20% · ตกเร็วขึ้น 50%",
		DescEn = "For your otter · catches up to Secret · luck x2 · gets hungry 20% slower · fishes 50% faster",
		Coins = 500000,
		Materials = { { "RubyShard", 5 }, { "SeaUrchin", 50 }, { "Straw", 50 } },
	},
	{
		-- ตะกร้อจอมโจร (ผู้ใช้สั่ง 2026-11-02): Kind "stealTool" คราฟซ้ำได้ไม่จำกัด ได้ 1 อันเข้ากระเป๋า (OrchardItems.GiveHand tier "Bandit")
		--   ใช้ได้ครั้งเดียว ขโมยไวขึ้น 50% (OrchardConfig.Steal.Tiers.Bandit) · การ์ดขึ้นเฉพาะตอนสวนเปิด (OrchardConfig.Enabled)
		Id = "BanditPicker", Kind = "stealTool", StealTier = "Bandit", Icon = "🦝", Preview = "BanditPicker",
		Name = "ตะกร้อจอมโจร", NameEn = "Bandit Picker",
		Desc = "สวนผลไม้ · ขโมยไวขึ้น 50% (มะม่วง 5 วิ) · ใช้ได้ 1 ครั้ง · คราฟซ้ำได้",
		DescEn = "Orchard · steals 50% faster (mango 5 s) · single use · craft as many as you like",
		Coins = 3000,
		Materials = { { "OldPhone", 1 }, { "TinCan", 1 }, { "OldBoot", 1 }, { "PlasticBottle", 1 } },
	},
	-- ปุ๋ยไม้ผล (OrchardFertilizer) ย้ายไปทำที่เครื่องทำปุ๋ยในสวนแล้ว (ผู้ใช้สั่ง 2026-11-02) · CraftBench ยังรองรับ Kind "orchardItem" / วัตถุดิบ "@Wood" ไว้ใช้ต่อได้
}

-- 2026-11-20 สูตรที่ตั้ง DevOnly = true: เซิร์ฟจริงเอาออกจากรายการ (ไม่ขึ้นการ์ด คราฟไม่ได้) · Studio เห็นปกติ
if not game:GetService("RunService"):IsStudio() then
	for i = #CraftConfig.Recipes, 1, -1 do
		if CraftConfig.Recipes[i].DevOnly then table.remove(CraftConfig.Recipes, i) end
	end
end

function CraftConfig.Get(recipeId)
	for _, r in ipairs(CraftConfig.Recipes) do
		if r.Id == recipeId then return r end
	end
	return nil
end

-- ปลาชนิดนี้นับเป็นวัตถุดิบช่องนี้ไหม
-- วัตถุดิบที่ไม่ใช่ปลา (ของจากสวน OrchardItems MatId) 2026-11-02: "@Wood" = ท่อนไม้
CraftConfig.OrchardMaterials = { ["@Wood"] = "Wood" }

function CraftConfig.Matches(materialId, fishId)
	if CraftConfig.OrchardMaterials[materialId] then return false end
	if materialId == "@Secret" then
		local fish = FishingConfig.Fish[fishId]
		return fish ~= nil and fish.Rarity == "Secret" and not fish.Junk
	end
	return materialId == fishId
end

-- ชื่อวัตถุดิบตามภาษา
function CraftConfig.MaterialName(materialId, lang)
	if materialId == "@Secret" then return lang == "en" and "Any Secret fish" or "ปลาระดับลับชนิดใดก็ได้" end
	if materialId == "@Wood" then return lang == "en" and "🌲 Log" or "🌲 ท่อนไม้" end -- 🪵 ไม่มีในฟอนต์ Roblox
	return FishingConfig.FishName(materialId, lang) or materialId
end

return CraftConfig
