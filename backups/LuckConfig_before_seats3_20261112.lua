-- BACKUP 2026-11-12 before "seats3" (RiversideLog / DuckFloat / KrathongPavilion)
-- Studio path: ReplicatedStorage.LuckConfig
-- Restore: open that script in Studio, replace its whole Source with everything below the line of dashes.
-- ------------------------------------------------------------
-- LuckConfig: ค่าโชค (ใช้ร่วมกันทั้งเซิร์ฟเวอร์และฝั่งผู้เล่น)
-- ค่าโชครวม = หุ่นทุกตัวที่ต้นอยู่ในรัศมี (ของใครปักก็ได้) + สัตว์เลี้ยง "นำโชค" ของคนปลูก บวกกันทั้งหมด
-- เช่น หุ่นฟาง (โชค 20) สองตัว + หุ่นทองคำ (โชค 100) อีกตัว = x140 (ไม่มีแหล่งไหนเลย = x1)
-- ชื่อระดับ "x50"/"x100" เป็นแค่รหัสภายใน (บันทึกอยู่ในกระเป๋าผู้เล่นแล้ว ห้ามเปลี่ยน) ค่าโชคจริงดูที่ Luck
-- หุ่นฟาง x50 ใช้ค่าโชค 20, หุ่นทองคำ x100 ใช้ค่าโชค 100

local LuckConfig = {}

-- น้ำหนักสุ่ม "คุณภาพต้น" 1-5 ตอนปลูก (x1 = ไม่มีโชค) ดาวผลผลิตสุ่มต่อจากคุณภาพต้นอีกที (HARVEST_ODDS ใน PlantingSystem)
LuckConfig.BASE_WEIGHTS = { 50, 25, 15, 7, 3 }

-- หุ่นแต่ละระดับ (ค่า Tier ตั้งอยู่บน Tool เป็น Attribute "BoosterTier" ไม่มี = x50)
-- แต่ละคนปักได้พร้อมกันระดับละ MaxActive ตัว (นับแยกระดับ)
LuckConfig.DEFAULT_BOOSTER_TIER = "x50"
LuckConfig.BoosterTiers = {
	-- Template = ชื่อโมเดลใน ServerStorage.BoosterTemplates, PreviewName = ชื่อโมเดลใน ReplicatedStorage.ItemPreviewModels (รูปในร้าน/ช่องไอเทม)
	x50 = { Luck = 20, Radius = 15, Lifetime = 300, MaxActive = 1,   -- ซื้อด้วยเหรียญ (หุ่นข้าวโพดดวงดีเดิม)
		Template = "QualityBoosterTemplate", PreviewName = "QualityBooster" },
	-- Robux เท่านั้น รัศมี 2 เท่า อยู่ 15 นาที หุ่นโคลเวอร์สี่แฉก + ออร่าสีรุ้ง (x50 ใช้สีทองเดิม) ซื้อผ่าน Developer Product นี้
	-- AuraColor = สีหลักของเอฟเฟกต์ตอนถือ/กรอบการ์ด (ตอนปักจะไล่สีรุ้งเพราะ Rainbow = true)
	x100 = { Luck = 100, Radius = 30, Lifetime = 900, MaxActive = 1, ProductId = 3714157810,
		-- ของขวัญ: ซื้อให้เพื่อน (สินค้าแยกจาก ProductId) ServerScriptService.LuckBoosterGift 0 = ยังไม่ได้สร้างสินค้า ใส่ ID แล้วปุ่ม 🎁 จะขึ้นในเกมจริง
		GiftProductId = 3715868092,
		AuraColor = Color3.fromRGB(120, 230, 120), Rainbow = true,
		Template = "LuckyCloverTemplate", PreviewName = "QualityBoosterX100" },
}
-- สกินหุ่นตามเทศกาล: เปลี่ยนแค่หน้าตา (โมเดลตอนปัก/ตอนถือ/รูปในร้านและกระเป๋า + สีออร่า) ค่าโชค รัศมี อายุ ราคา และชื่อไอเทมเหมือนเดิม
-- แสดงเมื่อเทศกาลชื่อเดียวกันใน ReplicatedStorage.SeasonConfig ทำงานอยู่ (สวิตช์ Enabled + ช่วงวันอยู่ที่นั่น คุมทั้งสกินและของตกแต่ง) เซิร์ฟเวอร์เลือกสกินตอนใช้งานจริง ฝั่งผู้เล่นไม่ต้องรู้
-- Tiers[ระดับ].Template = ชื่อโมเดลใน ServerStorage.BoosterTemplates (จุดหมุนอยู่ที่ฐาน หน้าหันตาม LookVector เหมือนแม่แบบปกติ)
-- ลองดูใน Studio โดยไม่ต้องเปิด Enabled: ตั้ง Attribute DevForceSeason = "Halloween2026" บน ReplicatedStorage ก่อนกด Play (ดู SeasonConfig)
LuckConfig.BoosterSkins = {
	Halloween2026 = {
		Tiers = {
			-- หุ่นฟางดวงดี -> หุ่นฟางหัวฟักทองหมวกแม่มด ออร่าส้มสลับม่วง
			x50 = { Template = "HalloweenScarecrowTemplate",
				AuraColor = Color3.fromRGB(255, 150, 40), AuraColor2 = Color3.fromRGB(180, 100, 255),
				SparkleRate = 3 }, -- ประกายรอบตัวหุ่นตอนปัก (เม็ด/วินาที) ไม่ใส่ = ประกายแบบเดิมที่ออกเยอะ
			-- หุ่นทองคำนำโชค (โคลเวอร์) -> โคลเวอร์แม่มดน้อย หมวกม่วง ปีกค้างคาว ห้อยฟักทอง (ออร่าสีรุ้งตอนปักยังเหมือนเดิม สีนี้ใช้กับแสง/เอฟเฟกต์ตอนถือ)
			-- NoBodyFx = ปิดประกาย/เส้นขอบสีรุ้ง/ดาววนรอบตัวหุ่นตอนปัก (วงหิ่งห้อยบอกรัศมียังอยู่)
			x100 = { Template = "HalloweenCloverTemplate", AuraColor = Color3.fromRGB(180, 100, 255), NoBodyFx = false }, -- เปิดเอฟเฟกต์ไว้ก่อน (ผู้ใช้ขอ 2026-10-11) จะปิดให้ใส่ true
		},
	},
}

-- สกินที่กำลังแสดงอยู่ของหุ่นระดับนี้ (ไม่มี = nil ใช้หน้าตาปกติ) คืน { Template, AuraColor, AuraColor2 }, ชื่อสกิน
local SeasonConfig = require(script.Parent:WaitForChild("SeasonConfig"))
function LuckConfig.GetActiveBoosterSkin(tierId)
	tierId = LuckConfig.BoosterTiers[tierId] and tierId or LuckConfig.DEFAULT_BOOSTER_TIER
	for skinId, skin in pairs(LuckConfig.BoosterSkins) do
		local look = skin.Tiers[tierId]
		if look and SeasonConfig.IsActive(skinId) then
			return look, skinId
		end
	end
	return nil
end

-- หุ่นที่ไม่ได้ตั้ง Attribute "LuckMultiplier" ไว้ (เช่นหุ่นถาวร KernelCorn ที่วางไว้ในแมพ) ใช้ค่านี้
LuckConfig.DEFAULT_BOOSTER_LUCK = 20 -- เท่าหุ่นฟาง (ระดับ x50)
LuckConfig.DEFAULT_BOOSTER_RADIUS = 15

-- สัตว์เลี้ยงความสามารถ "นำโชค" (Lucky) ได้ค่าโชคตามความหายาก (คูณความอิ่ม หิวครึ่งหนึ่ง = โชคครึ่งเดียว)
-- ตัวไหนจะตั้งเองให้ใส่ Luck = <เลข> ใน PetDefinitions
LuckConfig.PetLuckByRarity = {
	Common = 2,
	Rare = 5,
	Legendary = 15,
	Secret = 20,
	Sultan = 20,
}

-- ปรับน้ำหนักตามค่าโชค: คุณภาพ i คูณ luck^((i-1)/4) (5 ดาวคูณเต็ม luck, 1 ดาวไม่คูณ)
-- ยิ่งโชคสูง ผลที่เพิ่มยิ่งน้อยลงเอง รายได้เฉลี่ยต่อต้นจึงไม่เกิน ~3 เท่าของปกติ ต่อให้หุ่นซ้อนกันเยอะแค่ไหน
function LuckConfig.ApplyLuck(luck)
	luck = math.max(1, luck or 1)
	local weights = {}
	local n = #LuckConfig.BASE_WEIGHTS
	for i, w in ipairs(LuckConfig.BASE_WEIGHTS) do
		weights[i] = w * luck ^ ((i - 1) / (n - 1))
	end
	return weights
end

-- โอกาสของแต่ละคุณภาพ (รวมกัน = 1) ไว้แสดงใน UI
function LuckConfig.GetChances(luck)
	local weights = LuckConfig.ApplyLuck(luck)
	local total = 0
	for _, w in ipairs(weights) do total += w end
	local chances = {}
	for i, w in ipairs(weights) do chances[i] = w / total end
	return chances
end

function LuckConfig.GetBoosterTier(tierId)
	return LuckConfig.BoosterTiers[tierId] or LuckConfig.BoosterTiers[LuckConfig.DEFAULT_BOOSTER_TIER]
end

-- ค่าโชคจากหุ่นทุกตัวใน workspace.QualityBoosters ที่ position อยู่ในรัศมี (บวกกัน) ใช้ได้ทั้งสองฝั่ง
function LuckConfig.GetBoosterLuckAt(position)
	local folder = workspace:FindFirstChild("QualityBoosters")
	if not folder then return 0 end
	local total = 0
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local radius = model:GetAttribute("BoostRadius") or LuckConfig.DEFAULT_BOOSTER_RADIUS
			local ok, pivot = pcall(function() return model:GetPivot().Position end)
			if ok and (position - pivot).Magnitude <= radius then
				local tierId = model:GetAttribute("BoosterTier")
				local tier = tierId and LuckConfig.BoosterTiers[tierId]
				total += (tier and tier.Luck) or model:GetAttribute("LuckMultiplier") or LuckConfig.DEFAULT_BOOSTER_LUCK
			end
		end
	end
	return total
end

-- รวมค่าโชคทุกแหล่ง (ไม่มีเลย = x1) ส่ง player มาด้วย = คิดสิทธิ์ถาวรของผู้เล่นคนนั้น (แพ็กสุลต่าน: โชค x2)
local SultanConfig = require(script.Parent:WaitForChild("SultanConfig"))
LuckConfig.HUG_LUCK_MULT = 1.1 -- กอดซุกซน: โชค +10%
LuckConfig.LANTERN_LUCK_MULT = 1.3 -- แขวนโคม: โชค +30%
function LuckConfig.Combine(boosterLuck, petLuck, player)
	local luck = math.max(1, (boosterLuck or 0) + (petLuck or 0))
	if player and player:GetAttribute("IsSultan") == true then
		luck *= SultanConfig.LUCK_MULT
	end
	-- กอดซุกซน (2026-10-22 ZukzonService): เจ้าของได้โชค x1.1 จนถึงเวลา Attribute "HugLuckUntil" (เวลาเซิร์ฟเวอร์ GetServerTimeNow)
	local hugUntil = player and player:GetAttribute("HugLuckUntil")
	if type(hugUntil) == "number" and hugUntil > workspace:GetServerTimeNow() then
		luck *= LuckConfig.HUG_LUCK_MULT
	end
	-- แขวนโคมลอยกระทง (2026-11-11 KrathongService): โชค x1.3 จนถึงเวลา Attribute "LanternLuckUntil" (เวลาเซิร์ฟเวอร์ GetServerTimeNow)
	local lanternUntil = player and player:GetAttribute("LanternLuckUntil")
	if type(lanternUntil) == "number" and lanternUntil > workspace:GetServerTimeNow() then
		luck *= LuckConfig.LANTERN_LUCK_MULT
	end
	return luck
end

-- แสดงค่าโชคแบบอ่านง่าย เช่น 70 -> "x70", 12.5 -> "x12.5"
function LuckConfig.Format(luck)
	local rounded = math.floor(luck * 10 + 0.5) / 10
	if rounded == math.floor(rounded) then
		return "x" .. tostring(math.floor(rounded))
	end
	return "x" .. tostring(rounded)
end

return LuckConfig
