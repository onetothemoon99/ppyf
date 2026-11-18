-- BACKUP of ServerScriptService.ShopSystem before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into ServerScriptService.ShopSystem.Source in Studio
-- bytes=50705 sum=23825013
-- ShopSystem: ซื้อเมล็ด + หุ่นเพิ่มดวง + ขายผลผลิตจากไอเทมในกระเป๋าโดยตรง

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local shops = workspace:WaitForChild("Shops")
local cropTemplates = ServerStorage:WaitForChild("CropTemplates")
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local LevelSystem = require(game:GetService("ServerScriptService"):WaitForChild("LevelSystem"))
local ItemFactory = require(game:GetService("ServerScriptService"):WaitForChild("ItemFactory"))
local ItemFactory = require(game:GetService("ServerScriptService"):WaitForChild("ItemFactory"))
local SultanConfig = require(ReplicatedStorage:WaitForChild("SultanConfig")) -- ApplySell: โบนัสเงินขาย (สุลต่าน/สัตว์เลี้ยง)
-- พืชเทศกาล (2026-10-14): SHOP_ITEMS ที่มี Season ขายเมล็ดเฉพาะตอนเทศกาลนั้นเปิด (SeasonConfig.IsActive) จบเทศกาล = หายจากร้าน
-- แต่ผลผลิต/เมล็ดที่มีอยู่แล้วยังขายและปลูกได้ตามปกติ
local SeasonConfig = require(ReplicatedStorage:WaitForChild("SeasonConfig"))
local OrchardConfig = require(ReplicatedStorage:WaitForChild("OrchardConfig"))
-- WithOrchard = true: ขายเมล็ดพร้อมระบบสวน (2026-11-04 ผู้ใช้สั่งให้พืชใหม่เข้าพร้อมไม้ยืนต้น) เปิดสวนในเซิร์ฟจริงเมื่อไหร่ พืชนี้ขึ้นร้านเมื่อนั้น
local function seasonOpen(entry)
	if entry.WithOrchard and not OrchardConfig.Enabled then return false end
	return entry.Season == nil or SeasonConfig.IsActive(entry.Season)
end

-- ============ สวนผลไม้ยืนต้น (2026-10-26 ผู้ใช้: เมล็ดขายที่ร้านเหมือนผัก ผลไม้ขายที่ร้าน) ============
-- แท็บซื้อ: CropType "OrchardSeed_<ชนิด>" (ซื้อได้ไม่จำกัด จำกัดตอนปลูกที่ OrchardService แทน: คนละ OrchardConfig.MAX_PER_PLAYER = 5 ต้น, 2026-10-26) · แท็บขาย: "Orchard_<ชนิด>" ราคา FruitPrice ตายตัว
-- ไม่คิดโบนัสขายสุลต่าน/สัตว์ (ผลละหลักล้านอยู่แล้ว) · เงินที่ได้แจ้ง CheatWatch.AllowCoinGain ก่อน · ซื้อ/ขายแล้วเซฟกระเป๋า+เงินทันที
local ServerScriptService = game:GetService("ServerScriptService")
local orchardFolder = ServerScriptService:WaitForChild("Orchard")
local OrchardItems = require(orchardFolder:WaitForChild("OrchardItems"))
local OrchardData = require(orchardFolder:WaitForChild("OrchardData"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))
local saveCoinsNow = ServerScriptService:WaitForChild("LeaderstatsSetup"):WaitForChild("SaveCoinsNow", 30)
local saveInventoryNow = ServerScriptService:WaitForChild("InventorySystem"):WaitForChild("SaveInventoryNow", 30)

-- ร้านผลไม้ & อุปกรณ์ (2026-10-27 ผู้ใช้สั่งแยกร้าน): แผงที่ทางเข้าสวนมะม่วง workspace.Orchard.Decor.FruitShop (ปุ่ม OrchardShopPrompt)
--   ขายเมล็ดไม้ผล + ตะกร้อขโมย · รับซื้อผลไม้สวน · ร้านเมล็ดพันธุ์เดิมไม่มีของสวนแล้ว · shopKindOf[player] = ร้านที่เปิดล่าสุด ("orchard" / "seed") ใช้เลือกรายการและตรวจตอนซื้อ/ขาย
local shopKindOf = {}
game:GetService("Players").PlayerRemoving:Connect(function(player) shopKindOf[player] = nil end)
local function inOrchardShop(player) return shopKindOf[player] == "orchard" end

local function saveBagAndCoins(player)
	if saveCoinsNow then saveCoinsNow:Fire(player) end
	if saveInventoryNow then saveInventoryNow:Fire(player) end
end

-- จำนวนต้นที่ปลูกอยู่ (แสดงในร้าน เทียบ OrchardConfig.MAX_PER_PLAYER, nil = ข้อมูลสวนยังโหลดไม่เสร็จ)
local function orchardTreeCount(player)
	local st = OrchardData.Get(player)
	if not (st and st.loaded) then return nil end
	return OrchardData.TreeCount(st.data)
end

-- เลเวลขั้นต่ำที่ต้องมีถึงจะซื้อเมล็ดพันธุ์ชนิดนี้ได้ (ไม่ตั้งไว้ = ซื้อได้ตั้งแต่เลเวล 1)
local CROP_MIN_LEVEL = {
	Strawberry = 5,
	Potato = 7,
	Cucumber = 12,
	Eggplant = 17,
	Corn = 3,
	Wheat = 1,
	Onion = 10,
	Pineapple = 15,
	Watermelon = 20,
	Pumpkin = 24, -- 2026-10-08 ผู้เล่นขอ (เดิมไม่ได้ตั้งไว้ = ซื้อได้ตั้งแต่เลเวล 1)
	Carrot = 25, -- แครอท 2026-11-04
	Sunflower = 28, -- ดอกทานตะวัน 2026-11-04
	Chili = 32, -- พริกขี้หนู 2026-11-04
	WitchBerry = 5, -- เบอร์รี่แม่มด พืชกิจกรรมฮาโลวีน 2026 (เดิม 30, ลดเหลือ 5 ให้ผู้เล่นใหม่ร่วมกิจกรรมได้ 2026-10-17)
	-- เผื่อพืชใหม่ในอนาคต: 25
}

local BOOSTER_CROP_TYPE = "QualityBooster" -- ตัวระบุพิเศษ ไม่ใช่พืชจริง ใช้แยกในระบบซื้อ/แจกไอเทม
local BOOSTER_PRICE = 500 -- หุ่นโชค x50 (เดิม 300 ถูกเกิน ได้คืน 3-5 เท่า) ที่ 500 ผู้เล่นใหม่ยังได้คืนราว 2 เท่าใน 5 นาที

local SHOP_ITEMS = {
	{ CropType = "Wheat", Price = 8, Label = "🌾 ข้าวสาลี" },
	{ CropType = "Strawberry", Price = 10, Label = "🍓 สตรอว์เบอร์รี่" },
	{ CropType = "Potato", Price = 11, Label = "🥔 มันฝรั่ง" },
	{ CropType = "Onion", Price = 12, Label = "🧅 หัวหอม" },
	{ CropType = "Corn", Price = 15, Label = "🌽 ข้าวโพด" },
	{ CropType = "Cucumber", Price = 14, Label = "🥒 แตงกวา" },
	{ CropType = "Pineapple", Price = 18, Label = "🍍 สับปะรด" },
	{ CropType = "Eggplant", Price = 19, Label = "🍆 มะเขือยาว" },
	{ CropType = "Watermelon", Price = 20, Label = "🍉 แตงโม" },
	{ CropType = "Pumpkin", Price = 24, Label = "🎃 ฟักทอง" },
	{ CropType = "Carrot", Price = 22, Label = "🥕 แครอท", WithOrchard = true },
	{ CropType = "Sunflower", Price = 30, Label = "🌻 ดอกทานตะวัน", WithOrchard = true },
	{ CropType = "Chili", Price = 36, Label = "🌶️ พริกขี้หนู", WithOrchard = true },
	{ CropType = "WitchBerry", Price = 32, Label = "🍇 เบอร์รี่แม่มด", Season = "Halloween2026" }, -- โต 80 วิ (ราคา = 2 เท่าของราคาขายฐาน แบบพืชอื่น)
	{ CropType = BOOSTER_CROP_TYPE, Price = BOOSTER_PRICE, Label = "🍀 หุ่นฟางดวงดี" },
}

local CROPS = {
	{ CropType = "Strawberry", Label = "🍓 สตรอว์เบอร์รี่" },
	{ CropType = "Corn", Label = "🌽 ข้าวโพด" },
	{ CropType = "Wheat", Label = "🌾 ข้าวสาลี" },
	{ CropType = "Onion", Label = "🧅 หัวหอม" },
	{ CropType = "Watermelon", Label = "🍉 แตงโม" },
	{ CropType = "Pineapple", Label = "🍍 สับปะรด" },
	{ CropType = "Potato", Label = "🥔 มันฝรั่ง" },
	{ CropType = "Cucumber", Label = "🥒 แตงกวา" },
	{ CropType = "Eggplant", Label = "🍆 มะเขือยาว" },
	{ CropType = "Pumpkin", Label = "🎃 ฟักทอง" },
	{ CropType = "Carrot", Label = "🥕 แครอท" },
	{ CropType = "Sunflower", Label = "🌻 ดอกทานตะวัน" },
	{ CropType = "Chili", Label = "🌶️ พริกขี้หนู" },
	{ CropType = "WitchBerry", Label = "🍇 เบอร์รี่แม่มด" },
}

local BASE_PRICE = { Strawberry = 5, Corn = 8, Wheat = 4, Onion = 6, Watermelon = 10, Pineapple = 8, Potato = 5, Cucumber = 7, Eggplant = 9, Pumpkin = 12, WitchBerry = 16, Carrot = 11, Sunflower = 15, Chili = 18 }
local STAR_PRICE_MULTIPLIER = {
	[1] = 1.0, [2] = 1.3, [3] = 1.6, [4] = 2.0, [5] = 2.5,
}

-- ราคาขายผลผลิต 1 ชิ้น: ราคาฐาน x ดาว x โบนัสสมุดพืช (Attribute CB_Sell_<พืช> ขั้นทองแดง +5% เพชรรวม +15% ตั้งโดย CropBook 2026-10-30) แล้วค่อยคิดโบนัสสุลต่าน/สัตว์
local CropBookConfig = require(ReplicatedStorage:WaitForChild("CropBookConfig"))
-- ผักกลายพันธุ์ (2026-10-30): คูณราคาตาม MutationConfig · ในร้านส่งเป็น CropType "Mut_<กลายพันธุ์>_<พืช>" (ShopGui ส่งคืนมาตอนกดขาย ไม่ต้องแก้ฝั่งผู้เล่น)
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))
local function cropUnitPrice(player, cropType, star, mutation)
	local bookSell = math.clamp(tonumber(player:GetAttribute(CropBookConfig.AttrSell(cropType))) or 0, 0, 1)
	return SultanConfig.ApplySell(player, math.floor((BASE_PRICE[cropType] or 0) * (STAR_PRICE_MULTIPLIER[star] or 1) * (1 + bookSell) * MutationConfig.Mult(mutation) + 0.5))
end

-- ขายเมล็ดคืนร้าน (ผู้ใช้ขอ 2026-10-18): ได้ครึ่งหนึ่งของราคาซื้อ (ปัดลง ขั้นต่ำ 1) ไม่คิดโบนัสสุลต่าน/สัตว์เลี้ยง (กันซื้อแล้วขายกำไร)
-- ปุ่ม "ขายทั้งหมด" ไม่รวมเมล็ด ต้องกดขายทีละชนิดเอง · ในร้านส่งเป็น CropType "Seed_<ชนิด>" Seed = true
local SEED_SELL_PRICE = {}

for _, entry in ipairs(SHOP_ITEMS) do
	if entry.CropType ~= BOOSTER_CROP_TYPE then
		SEED_SELL_PRICE[entry.CropType] = math.max(1, math.floor(entry.Price / 2))
	end
end

-- ขายหุ่นฟางดวงดีคืนร้าน (ผู้ใช้ขอ 2026-10-19): เฉพาะหุ่นระดับ "x50" (ค่าโชค 20 = หุ่น x20 ที่ผู้เล่นเห็น) ได้ครึ่งราคาซื้อ ไม่คิดโบนัสขาย
-- หุ่นทองคำ x100 ขายคืนไม่ได้ (ไม่ขึ้นในแท็บขาย และเซิร์ฟไม่รับ) · ในร้านส่งเป็นแถวแบบเมล็ด CropType "Seed_QualityBooster" (ไม่นับในขายทั้งหมด)
local SELLABLE_BOOSTER_TIER = "x50"
local BOOSTER_SELL_PRICE = math.floor(BOOSTER_PRICE / 2)

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local requestShopOpen = remoteEvents:FindFirstChild("RequestShopOpen")
if not requestShopOpen then
	requestShopOpen = Instance.new("RemoteEvent")
	requestShopOpen.Name = "RequestShopOpen"
	requestShopOpen.Parent = remoteEvents
end

local harvestNotify = remoteEvents:FindFirstChild("HarvestNotify")
if not harvestNotify then
	harvestNotify = Instance.new("RemoteEvent")
	harvestNotify.Name = "HarvestNotify"
	harvestNotify.Parent = remoteEvents
end

local buySeed = remoteEvents:FindFirstChild("BuySeed")
if not buySeed then
	buySeed = Instance.new("RemoteEvent")
	buySeed.Name = "BuySeed"
	buySeed.Parent = remoteEvents
end

local sellCrop = remoteEvents:FindFirstChild("SellCrop")
if not sellCrop then
	sellCrop = Instance.new("RemoteEvent")
	sellCrop.Name = "SellCrop"
	sellCrop.Parent = remoteEvents
end

-- ปุ่ม "ขายผลผลิตทั้งหมด" ในแท็บขาย
local sellAllCrops = remoteEvents:FindFirstChild("SellAllCrops")
if not sellAllCrops then
	sellAllCrops = Instance.new("RemoteEvent")
	sellAllCrops.Name = "SellAllCrops"
	sellAllCrops.Parent = remoteEvents
end

local function findExistingSeedTool(player, cropType)
	local locations = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, location in ipairs(locations) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and not item:GetAttribute("IsProduce") and item:GetAttribute("CropType") == cropType then
					return item
				end
			end
		end
	end
	return nil
end

local function giveSeedTool(player, cropType, amount)
	amount = amount or 1
	local existingTool = findExistingSeedTool(player, cropType)

	if existingTool then
		local newCount = (existingTool:GetAttribute("Count") or 1) + amount
		existingTool:SetAttribute("Count", newCount)
		existingTool.Name = cropType .. " x" .. newCount
	else
		local seedTool = ItemFactory.CreateSeedTool(cropType, amount)
		seedTool.Parent = ItemFactory.GetBackpack(player)
	end
end

-- หุ่นฟางดวงดี (เดิมหุ่นข้าวโพด) ในร้านนี้คือหุ่นโชค x50 (stack รวมกับ x50 เดิม แยกกองจาก x100)
local function giveBoosterTool(player, amount)
	ItemFactory.GiveBoosterTool(player, amount, "x50")
end

-- หาไอเทมผลผลิต (ชนิด+ดาว) ในกระเป๋าผู้เล่น
local function findProduceTool(player, cropType, star, mutation)
	local locations = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, location in ipairs(locations) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsProduce")
					and item:GetAttribute("CropType") == cropType
					and item:GetAttribute("Star") == star
					and item:GetAttribute("Mutation") == mutation -- กลายพันธุ์แยกกอง (nil = ผักปกติ)
					and not item:GetAttribute("Starred") then -- ติดดาวไว้ = ไม่ขาย (ผู้เล่นขอ 2026-10-03)
					return item
				end
			end
		end
	end
	return nil
end

-- หาเมล็ดชนิดนี้ในกระเป๋า (เมล็ด = ไม่ใช่ผลผลิต/ปลา/เหยื่อ และ CropType เป็นพืชที่ร้านขายเมล็ด)
local function findSeedToolForSale(player, cropType)
	if not SEED_SELL_PRICE[cropType] then return nil end
	for _, location in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("CropType") == cropType and not item:GetAttribute("IsProduce")
					and not item:GetAttribute("IsFish") and not item:GetAttribute("IsBait") and not item:GetAttribute("Starred") then
					return item
				end
			end
		end
	end
	return nil
end

-- หุ่นฟางที่ขายคืนได้ (ระดับ x50 เท่านั้น · ติดดาวไว้ = ไม่ขาย)
local function findBoosterToolForSale(player)
	for _, location in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsBooster") == true
					and (item:GetAttribute("BoosterTier") or SELLABLE_BOOSTER_TIER) == SELLABLE_BOOSTER_TIER
					and not item:GetAttribute("Starred") then
					return item
				end
			end
		end
	end
	return nil
end

-- ============ ปลา (ขายในร้านเดียวกับผลผลิต ชนิดส่งเป็น "Fish_<id>") ============
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local function findFishTool(player, fishId, star)
	for _, location in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsFish") and item:GetAttribute("FishId") == fishId and item:GetAttribute("Star") == star and not item:GetAttribute("Starred") then
					return item
				end
			end
		end
	end
	return nil
end

-- ผลไม้สวน (มะม่วง/ทุเรียน) ราคาตายตัว ไม่มีดาว · ติดดาวไว้ = ไม่ขึ้นในร้าน · ขายได้เฉพาะร้านผลไม้ & อุปกรณ์
local function buildOrchardSellItems(player)
	local sellItems = {}
	local lang = Localization.GetLanguage(player)
	for _, kind in ipairs(OrchardConfig.Enabled and OrchardConfig.SortedKinds() or {}) do -- ปิดระบบสวน = ไม่ขึ้นในร้าน
		local def = OrchardConfig.Trees[kind]
		local tool = OrchardItems.Find(player, OrchardItems.FRUIT, kind, true)
		local count = tool and tool:GetAttribute("Count") or 0
		if count > 0 then
			table.insert(sellItems, {
				CropType = "Orchard_" .. kind, Star = 0, Count = count,
				UnitPrice = def.FruitPrice, TotalValue = def.FruitPrice * count,
				Name = OrchardConfig.NameOf(kind, lang), Icon = def.Icon,
			})
		end
	end
	return sellItems
end

local function buildSellItemsData(player)
	if inOrchardShop(player) then return buildOrchardSellItems(player) end
	local sellItems = {}
	local sellLang = Localization.GetLanguage(player)
	for _, cropInfo in ipairs(CROPS) do
		for star = 1, 5 do
			local tool = findProduceTool(player, cropInfo.CropType, star)
			local count = tool and tool:GetAttribute("Count") or 0
			if count > 0 then
				local unitPrice = cropUnitPrice(player, cropInfo.CropType, star)
				table.insert(sellItems, {
					CropType = cropInfo.CropType,
					Star = star,
					Label = cropInfo.Label,
					Count = count,
					UnitPrice = unitPrice,
					TotalValue = unitPrice * count,
				})
			end
			-- กองกลายพันธุ์ของพืช+ดาวนี้ (ส่งชื่อ/ไอคอนไปเอง แบบปลา)
			for _, mutation in ipairs(MutationConfig.ORDER) do
				local mTool = findProduceTool(player, cropInfo.CropType, star, mutation)
				local mCount = mTool and mTool:GetAttribute("Count") or 0
				if mCount > 0 then
					local unitPrice = cropUnitPrice(player, cropInfo.CropType, star, mutation)
					local book = CropBookConfig.ById[cropInfo.CropType]
					table.insert(sellItems, {
						CropType = "Mut_" .. mutation .. "_" .. cropInfo.CropType,
						Star = star,
						Label = cropInfo.Label,
						Name = MutationConfig.Label(mutation, sellLang) .. " " .. Localization.T("Crop_" .. cropInfo.CropType, sellLang),
						Icon = book and book.icon or nil,
						PreviewModel = cropInfo.CropType == "WitchBerry" and "WitchBerry" or nil,
						Rarity = mutation == "Rainbow" and "Secret" or mutation == "Golden" and "Legendary" or nil,
						Count = mCount,
						UnitPrice = unitPrice,
						TotalValue = unitPrice * mCount,
					})
				end
			end
		end
	end
	-- ปลา: เรียงตามชื่อ ดาวสูงก่อน
	local fishIds = {}
	for fishId in pairs(FishingConfig.Fish) do table.insert(fishIds, fishId) end
	table.sort(fishIds, function(a, b) return FishingConfig.Fish[a].Name < FishingConfig.Fish[b].Name end)
	for _, fishId in ipairs(fishIds) do
		for star = 5, 1, -1 do
			local tool = findFishTool(player, fishId, star)
			local count = tool and tool:GetAttribute("Count") or 0
			if count > 0 then
				local unitPrice = SultanConfig.ApplySell(player, FishingConfig.GetPrice(fishId, star))
				table.insert(sellItems, {
					CropType = "Fish_" .. fishId, Star = star, Count = count,
					UnitPrice = unitPrice, TotalValue = unitPrice * count,
					Name = FishingConfig.FishName(fishId, Localization.GetLanguage(player)), Icon = "🐟", PreviewModel = "Fish_" .. fishId,
					Rarity = FishingConfig.Fish[fishId].Rarity, -- กรอบสีตามระดับในร้าน
				})
			end
		end
	end
	-- เมล็ด (ครึ่งราคาซื้อ) อยู่ท้ายรายการ ฝั่งผู้เล่นไม่นับรวมในแถบขายทั้งหมด (Seed = true)
	for _, entry in ipairs(SHOP_ITEMS) do
		local price = SEED_SELL_PRICE[entry.CropType]
		local tool = price and findSeedToolForSale(player, entry.CropType)
		local count = tool and tool:GetAttribute("Count") or 0
		if count > 0 then
			table.insert(sellItems, {
				CropType = "Seed_" .. entry.CropType, SeedCrop = entry.CropType, Seed = true, Star = 0,
				Count = count, UnitPrice = price, TotalValue = price * count,
			})
		end
	end
	-- หุ่นฟางดวงดี x50 (ครึ่งราคาซื้อ) แถวแบบเมล็ด: ชื่อ/รูปตามแท็บซื้อ ไม่นับในขายทั้งหมด
	local booster = findBoosterToolForSale(player)
	local boosterCount = booster and booster:GetAttribute("Count") or 0
	if boosterCount > 0 then
		table.insert(sellItems, {
			CropType = "Seed_" .. BOOSTER_CROP_TYPE, SeedCrop = BOOSTER_CROP_TYPE, Seed = true, Star = 0,
			Count = boosterCount, UnitPrice = BOOSTER_SELL_PRICE, TotalValue = BOOSTER_SELL_PRICE * boosterCount,
		})
	end
	return sellItems
end

local function buildBuyItemsData(player)
	local playerLevel = LevelSystem.GetLevel(player)
	local buyItems = {}
	local orchardShop = inOrchardShop(player)

	for _, entry in ipairs(orchardShop and {} or SHOP_ITEMS) do -- ร้านผลไม้ไม่ขายเมล็ดผัก/หุ่นฟาง
		if not seasonOpen(entry) then continue end -- พืชเทศกาลที่ยังไม่เปิด/จบแล้ว ไม่โชว์ในร้าน
		local requiredLevel = CROP_MIN_LEVEL[entry.CropType] or 1
		table.insert(buyItems, {
			CropType = entry.CropType,
			Price = entry.Price,
			Label = entry.Label,
			RequiredLevel = requiredLevel,
			Locked = playerLevel < requiredLevel,
			Event = entry.Season ~= nil, -- พืชกิจกรรม/เทศกาล: ร้านขึ้นป้าย "🎃 พืชกิจกรรม"
		})
	end

	-- เมล็ดไม้ยืนต้น (ปิดระบบสวน = ไม่ขึ้นในร้าน) ฝั่งผู้เล่นใช้ Name/Icon/Info ที่ส่งไป · ซื้อได้ไม่จำกัด (ผู้ใช้สั่ง 2026-10-26)
	-- ตั้งแต่ 2026-10-27 ขายเฉพาะร้านผลไม้ & อุปกรณ์ที่ทางเข้าสวน
	if OrchardConfig.Enabled and orchardShop then
		local lang = Localization.GetLanguage(player)
		local planted = orchardTreeCount(player) or 0
		for _, kind in ipairs(OrchardConfig.SortedKinds()) do
			if not OrchardConfig.IsOpen(kind) then continue end -- ชนิดที่ยังไม่เปิด (เช่นทุเรียน 2026-10-27) ไม่ขึ้นในร้าน
			local def = OrchardConfig.Trees[kind]
			-- เวลาเป็นข้อความ (ต่ำกว่า 1 ชม. = นาที เช่นมะม่วงโต 20 นาที 2026-10-29)
			local function dur(sec)
				if sec < 3600 then return math.floor(sec / 60) .. (lang == "en" and "m" or " นาที") end
				local h = sec / 3600
				return (h % 1 == 0 and tostring(h) or string.format("%.1f", h)) .. (lang == "en" and "h" or " ชม.")
			end
			table.insert(buyItems, {
				CropType = "OrchardSeed_" .. kind,
				Price = def.SeedPrice,
				Name = lang == "en" and (def.NameEn .. " Seed") or ("เมล็ด" .. def.NameTh),
				Icon = def.Icon,
				PreviewModel = "SeedPacket_" .. kind, -- ซองเมล็ด 3D (OrchardItems สร้างรูป) 2026-10-31
				-- คำอธิบายสั้น (ผู้ใช้สั่ง 2026-10-29): ปลูกที่ไหน · ออกผลใน · เก็บกี่รอบ · ราคาขาย (ราคาเมล็ดอยู่ใต้ชื่อในร้านแล้ว)
				Info = string.format(lang == "en" and "Plant at the fruit tree orchard · fruits in %s · %s · sells for %s"
					or "ปลูกได้ที่สวนไม้ยืนต้น · ออกผลใน %s · %s · ขายได้ราคา %s",
					dur(def.FruitSeconds),
					def.Harvests and (lang == "en" and (def.Harvests .. " harvests") or ("เก็บเกี่ยวได้ " .. def.Harvests .. " รอบ")) or (lang == "en" and "harvest forever" or "เก็บเกี่ยวได้ไม่จำกัด"),
					(string.reverse((string.gsub(string.reverse(tostring(def.FruitPrice)), "(%d%d%d)(%d)", "%1,%2"))))), -- 100000 → 100,000
				RequiredLevel = OrchardConfig.MIN_LEVEL,
				Locked = playerLevel < OrchardConfig.MIN_LEVEL,
			})
		end
		-- ตะกร้อขโมย (เฟส 3, 2026-10-26 เดิมชื่อมือขโมย เปลี่ยน 2026-10-27) ซื้อได้ไม่จำกัด
		local steal = OrchardConfig.Steal
		local stealTimes = {} -- เวลากดค้างเฉพาะชนิดที่เปิดแล้ว
		for _, kind in ipairs(OrchardConfig.SortedKinds()) do
			if OrchardConfig.IsOpen(kind) then
				local def = OrchardConfig.Trees[kind]
				table.insert(stealTimes, lang == "en" and (def.NameEn:lower() .. " " .. (steal.Seconds[kind] or 0) .. "s") or (def.NameTh .. " " .. (steal.Seconds[kind] or 0) .. " วิ"))
			end
		end
		table.insert(buyItems, {
			CropType = "OrchardHand",
			Price = steal.HandPrice,
			Name = lang == "en" and steal.HandNameEn or steal.HandNameTh,
			Icon = steal.HandIcon,
			PreviewModel = "StealPicker", -- รูป 3D แทนไอคอน (ItemPreviewModels) 2026-10-29
			Info = string.format(lang == "en" and "🌳 Bamboo picker pole: hold it under someone's ripe fruit tree and keep pressing \"Steal\" (%s) = 1 fruit · used up on success · owner must be in the server"
				or "🌳 ไม้สอยผลไม้: ถือไว้ ยืนใต้ต้นผลสุกของคนอื่น กดค้าง \"ขโมย\" (%s) = ได้ 1 ผล · สำเร็จแล้วตะกร้อหาย · เจ้าของต้องอยู่ในเซิร์ฟ",
				table.concat(stealTimes, " / ")),
			RequiredLevel = steal.MinLevel,
			Locked = playerLevel < steal.MinLevel,
		})
		-- มือตบ (2026-10-29) ของถาวร ซื้อได้ครั้งเดียว (มีแล้ว = ปุ่มเทา "มีแล้ว") ไม่ล็อกเลเวล (เจ้าของต้นทุกคนควรป้องกันได้)
		local ownsSlap = OrchardItems.HasSlap(player)
		table.insert(buyItems, {
			CropType = "OrchardSlap",
			Price = steal.SlapHandPrice,
			Name = lang == "en" and steal.SlapHandNameEn or steal.SlapHandNameTh,
			Icon = steal.SlapHandIcon,
			PreviewModel = "SlapHand",
			MaxQty = 1,
			LimitReached = ownsSlap,
			LimitText = lang == "en" and "✓ Owned" or "✓ มีแล้ว",
			Info = string.format(lang == "en" and "🛡️ Protect your trees: hold it and swing when someone steals = slap within %d studs (bare hand %d) · buy once, yours forever"
				or "🛡️ ป้องกันต้น: ถือไว้แล้วฟาดตอนมีคนขโมย = ตบได้ไกล %d สตัด (มือเปล่า %d) · ซื้อครั้งเดียวใช้ได้ตลอด",
				steal.SlapHandRange, steal.SlapRange),
		})
	end

	return buyItems
end

-- kind = "seed" / "orchard" ตอนเปิดร้าน · nil = รีเฟรชร้านเดิมหลังซื้อ/ขาย · ส่ง kind เป็นค่าที่ 4 ให้ ShopGui ตั้งชื่อร้าน
local function sendShopData(player, kind)
	if kind then shopKindOf[player] = kind end
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
	local coinAmount = coins and coins.Value or 0

	requestShopOpen:FireClient(player, buildBuyItemsData(player), buildSellItemsData(player), coinAmount, shopKindOf[player] or "seed")
end

for _, shopPart in ipairs(shops:GetChildren()) do
	local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.HoldDuration = 1 -- บังคับให้ต้องกด E ค้าง 1 วินาที แทนกดปุ๊บเปิดปุ๊บ (กันลืมถ้าย้าย/สร้างร้านใหม่ทีหลัง)
		prompt.Triggered:Connect(function(player)
			sendShopData(player, "seed")
		end)
	end
end

-- ร้านผลไม้ & อุปกรณ์ที่ทางเข้าสวน (อยู่ใน workspace.Orchard = ปิดระบบสวนแล้วหายไปพร้อมสวน)
-- 2026-10-30 ต่อปุ่มเสมอ เช็ก Enabled ตอนกด (เดิมต่อเฉพาะตอนสวนเปิดตั้งแต่เซิร์ฟเริ่ม = ทดสอบเป็นทีมที่สวนเปิดทีหลังผ่าน OrchardStudioHello กด E แล้วไม่มีอะไรเกิดขึ้น)
--   สวนที่ปิดอยู่ถูกย้ายไป ServerStorage (OrchardService) เลยหาทั้งสองที่ ตัวปุ่มเป็นอันเดิมแม้สวนถูกย้ายกลับ
task.spawn(function()
	local prompt
	local t0 = os.clock()
	while not prompt and os.clock() - t0 < 120 do
		local zone = workspace:FindFirstChild("Orchard") or ServerStorage:FindFirstChild("Orchard")
		prompt = zone and zone:FindFirstChild("OrchardShopPrompt", true)
		if not prompt then task.wait(1) end
	end
	if not prompt then warn("ShopSystem: ไม่เจอ OrchardShopPrompt (ร้านผลไม้ & อุปกรณ์)") return end
	prompt.HoldDuration = 1
	prompt.Triggered:Connect(function(player)
		if not OrchardConfig.Enabled then return end
		sendShopData(player, "orchard")
	end)
end)

buySeed.OnServerEvent:Connect(function(player, cropType, quantity)
	-- NaN ทะลุ math.clamp และทำให้เช็ก "เงินไม่พอ" ผ่านเสมอ (เทียบกับ NaN = false) = ซื้อได้โดยไม่มีเงิน
	if type(quantity) == "number" and quantity ~= quantity then return end
	quantity = math.clamp(math.floor(tonumber(quantity) or 1), 1, 1000000) -- กรอกเองได้ไม่จำกัด (เงินไม่พอ = ไม่ขายด้านล่าง) เพดานนี้แค่กันเลขผิดปกติ

	-- เมล็ดไม้ยืนต้น: ซื้อได้ไม่จำกัด เช็กเลเวล + เงิน (จำกัด 5 ต้นอยู่ที่ตอนปลูก OrchardService)
	local orchardKind = type(cropType) == "string" and cropType:match("^OrchardSeed_(.+)$")
	if orchardKind then
		if not inOrchardShop(player) then return end -- ซื้อได้เฉพาะร้านผลไม้ & อุปกรณ์
		local def = OrchardConfig.Enabled and OrchardConfig.IsOpen(orchardKind) and OrchardConfig.Trees[orchardKind] -- ชนิดที่ยังไม่เปิด = ซื้อไม่ได้
		if not def then return end
		local lang = Localization.GetLanguage(player)
		if LevelSystem.GetLevel(player) < OrchardConfig.MIN_LEVEL then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.F("Shop_LevelRequired", lang, OrchardConfig.MIN_LEVEL))
			return
		end
		if orchardTreeCount(player) == nil or player:GetAttribute("CoinsLoaded") ~= true then
			harvestNotify:FireClient(player, nil, nil, nil, lang == "en" and "Still loading, please try again" or "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง")
			return
		end
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		local cost = def.SeedPrice * quantity
		if not coins or coins.Value < cost then return end
		player:SetAttribute("CoinSrc", "orchard_seed")
		coins.Value -= cost
		OrchardItems.Give(player, OrchardItems.SEED, orchardKind, quantity, lang)
		saveBagAndCoins(player)
		harvestNotify:FireClient(player, nil, nil, nil, lang == "en"
			and string.format("%s Got %d %s seed(s)! Plant them in the fruit tree orchard", def.Icon, quantity, def.NameEn)
			or string.format("%s ได้เมล็ด%s %d เมล็ดแล้ว! เข้าไปปลูกในสวนไม้ยืนต้น", def.Icon, def.NameTh, quantity))
		print(player.Name .. " ซื้อเมล็ดสวน " .. orchardKind .. " x" .. quantity .. " สำเร็จ")
		sendShopData(player)
		return
	end

	-- ตะกร้อขโมย (เฟส 3, 2026-10-26): เช็กเลเวล + เงิน ซื้อได้ไม่จำกัด
	if cropType == "OrchardHand" and OrchardConfig.Enabled and inOrchardShop(player) then
		local steal = OrchardConfig.Steal
		local lang = Localization.GetLanguage(player)
		if LevelSystem.GetLevel(player) < steal.MinLevel then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.F("Shop_LevelRequired", lang, steal.MinLevel))
			return
		end
		if player:GetAttribute("CoinsLoaded") ~= true or player:GetAttribute("InventoryLoaded") == false then
			harvestNotify:FireClient(player, nil, nil, nil, lang == "en" and "Still loading, please try again" or "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง")
			return
		end
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		local cost = steal.HandPrice * quantity
		if not coins or coins.Value < cost then return end
		player:SetAttribute("CoinSrc", "orchard_hand")
		coins.Value -= cost
		OrchardItems.GiveHand(player, quantity, lang)
		saveBagAndCoins(player)
		harvestNotify:FireClient(player, nil, nil, nil, lang == "en"
			and string.format("%s Got %d %s(s)! Hold one under someone's ripe fruit tree", steal.HandIcon, quantity, steal.HandNameEn:lower())
			or string.format("%s ได้%s %d อันแล้ว! ถือไปยืนใต้ต้นผลสุกของคนอื่น", steal.HandIcon, steal.HandNameTh, quantity))
		print(player.Name .. " ซื้อตะกร้อขโมย x" .. quantity .. " สำเร็จ")
		sendShopData(player)
		return
	end

	-- มือตบ (2026-10-29): เช็กเงิน ซื้อได้ไม่จำกัด เฉพาะร้านผลไม้
	if cropType == "OrchardSlap" and OrchardConfig.Enabled and inOrchardShop(player) then
		local steal = OrchardConfig.Steal
		local lang = Localization.GetLanguage(player)
		if player:GetAttribute("CoinsLoaded") ~= true or player:GetAttribute("InventoryLoaded") == false then
			harvestNotify:FireClient(player, nil, nil, nil, lang == "en" and "Still loading, please try again" or "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง")
			return
		end
		-- ของถาวร: มีแล้ว = ซื้อซ้ำไม่ได้ · ซื้อทีละ 1 เสมอ
		if OrchardItems.HasSlap(player) then
			harvestNotify:FireClient(player, nil, nil, nil, lang == "en" and "🖐️ You already own a slap hand (it never runs out)" or "🖐️ มีมือตบแล้ว (ใช้ได้ตลอด ไม่หมด)")
			sendShopData(player)
			return
		end
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		local cost = steal.SlapHandPrice
		if not coins or coins.Value < cost then return end
		player:SetAttribute("CoinSrc", "orchard_slap")
		coins.Value -= cost
		OrchardItems.GiveSlap(player, 1, lang)
		saveBagAndCoins(player)
		harvestNotify:FireClient(player, nil, nil, nil, lang == "en"
			and string.format("%s Got a slap hand! Hold it and swing when a thief comes · it never runs out", steal.SlapHandIcon)
			or string.format("%s ได้มือตบแล้ว! ถือไว้แล้วฟาดตอนมีคนขโมย · ใช้ได้ตลอด ไม่หมด", steal.SlapHandIcon))
		print(player.Name .. " ซื้อมือตบสำเร็จ")
		sendShopData(player)
		return
	end

	local item = nil
	for _, entry in ipairs(SHOP_ITEMS) do
		if entry.CropType == cropType then item = entry break end
	end
	if not item then return end
	if not seasonOpen(item) then return end -- ยิง remote ซื้อเมล็ดเทศกาลนอกช่วงเทศกาล

	-- เช็คเลเวลก่อนเสมอ (ฝั่งเซิร์ฟเวอร์ กันเลี่ยงผ่าน UI ยิง remote ตรงๆ)
	local requiredLevel = CROP_MIN_LEVEL[cropType] or 1
	local playerLevel = LevelSystem.GetLevel(player)
	if playerLevel < requiredLevel then
		local lang = Localization.GetLanguage(player)
		harvestNotify:FireClient(player, nil, nil, nil, Localization.F("Shop_LevelRequired", lang, requiredLevel))
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
	if not coins then return end

	local totalPrice = item.Price * quantity
	if coins.Value < totalPrice then
		print(player.Name .. " เงินไม่พอซื้อ " .. cropType .. " x" .. quantity)
		return
	end

	-- 2026-11-18 กระเป๋ายังไม่มา (เกิดใหม่/กำลังออก) = ไม่หักเหรียญ (เดิมหักแล้วให้ของพัง = เสียเหรียญฟรี)
	if not ItemFactory.FindBackpack(player) then
		harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(Localization.GetLanguage(player), "กระเป๋ายังไม่พร้อม รอสักครู่แล้วลองใหม่", "Your bag isn't ready yet, please try again in a moment"))
		return
	end
	player:SetAttribute("CoinSrc", "shop")
	coins.Value -= totalPrice

	if cropType == BOOSTER_CROP_TYPE then
		giveBoosterTool(player, quantity)
		print(player.Name .. " ซื้อหุ่นเพิ่มดวง x" .. quantity .. " สำเร็จ")
	else
		giveSeedTool(player, cropType, quantity)
		print(player.Name .. " ซื้อเมล็ด " .. cropType .. " x" .. quantity .. " สำเร็จ")
	end

	sendShopData(player)
end)

sellCrop.OnServerEvent:Connect(function(player, cropType, star, quantity)
	if type(quantity) == "number" and quantity ~= quantity then return end -- NaN ทะลุ math.clamp ทำยอดเงิน/จำนวนเพี้ยน
	-- ปลา
	local fishId = type(cropType) == "string" and cropType:match("^Fish_(.+)$")
	if fishId and FishingConfig.Fish[fishId] then
		local fishTool = findFishTool(player, fishId, star)
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		if not (fishTool and coins) then return end
		local have = fishTool:GetAttribute("Count") or 0
		if have <= 0 then return end
		local qty = math.clamp(math.floor(tonumber(quantity) or have), 1, have)
		local earned = SultanConfig.ApplySell(player, FishingConfig.GetPrice(fishId, star)) * qty
		coins.Value += earned
		if have - qty <= 0 then
			fishTool:Destroy()
		else
			fishTool:SetAttribute("Count", have - qty)
			fishTool.Name = ItemFactory.GetFishName(fishId, star, have - qty, Localization.GetLanguage(player))
		end
		print(player.Name .. " ขายปลา " .. fishId .. " ดาว " .. tostring(star) .. " x" .. qty .. " ได้ " .. earned .. " เหรียญ")
		sendShopData(player)
		return
	end
	-- ผลไม้สวน: ราคาตายตัว (ไม่คิดโบนัสขาย) กองติดดาวไม่ขาย
	local fruitKind = type(cropType) == "string" and cropType:match("^Orchard_(.+)$")
	if fruitKind and OrchardConfig.Enabled and OrchardConfig.Trees[fruitKind] and inOrchardShop(player) then -- ปิดระบบสวน = ขายไม่ได้ · ขายได้เฉพาะร้านผลไม้
		local def = OrchardConfig.Trees[fruitKind]
		local tool = OrchardItems.Find(player, OrchardItems.FRUIT, fruitKind, true)
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		if not (tool and coins) then return end
		-- 2026-11-18 (instantHarvest): เพิ่งเก็บ/ขโมยผลแต่สวนต้นทางยังเซฟไม่เสร็จ (ไม่เกิน ~6.5 วิ) = ยังขายไม่ได้ กันผลไม้ซ้ำ
		if OrchardData.HasUnsavedFruit and OrchardData.HasUnsavedFruit(player) then
			if harvestNotify then
				harvestNotify:FireClient(player, nil, nil, nil, Localization.GetLanguage(player) == "en"
					and "💾 Saving your fruit, try selling again in a few seconds"
					or "💾 กำลังบันทึกผลไม้ ลองขายอีกครั้งในไม่กี่วินาที")
			end
			sendShopData(player)
			return
		end
		local have = math.floor(tonumber(tool:GetAttribute("Count")) or 0)
		if have <= 0 then return end
		local qty = math.clamp(math.floor(tonumber(quantity) or have), 1, have)
		local lang = Localization.GetLanguage(player)
		if not OrchardItems.Take(player, OrchardItems.FRUIT, fruitKind, qty, lang, true) then return end
		local earned = def.FruitPrice * qty
		CheatWatch.AllowCoinGain(player, earned) -- ผลละหลักล้าน ไม่ใช่เหรียญขึ้นเร็วผิดปกติ
		coins.Value += earned
		saveBagAndCoins(player)
		print(player.Name .. " ขายผลไม้สวน " .. fruitKind .. " x" .. qty .. " ได้ " .. earned .. " เหรียญ")
		sendShopData(player)
		return
	end
	-- เมล็ด: ครึ่งราคาซื้อ (ไม่คิดโบนัสขาย)
	local seedCrop = type(cropType) == "string" and cropType:match("^Seed_(.+)$")
	-- หุ่นฟางดวงดี x50: ครึ่งราคาซื้อ (หุ่น x100 หาไม่เจอใน findBoosterToolForSale = ขายไม่ได้)
	if seedCrop == BOOSTER_CROP_TYPE then
		local boosterTool = findBoosterToolForSale(player)
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		if not (boosterTool and coins) then return end
		local have = boosterTool:GetAttribute("Count") or 0
		if have <= 0 then return end
		local qty = math.clamp(math.floor(tonumber(quantity) or have), 1, have)
		local earned = BOOSTER_SELL_PRICE * qty
		coins.Value += earned
		if have - qty <= 0 then
			boosterTool:Destroy()
		else
			boosterTool:SetAttribute("Count", have - qty)
			local baseLabel = boosterTool.Name:match("^(.-)%s*x%d+$") or boosterTool.Name
			boosterTool.Name = baseLabel .. " x" .. (have - qty)
		end
		print(player.Name .. " ขายหุ่นฟาง x" .. qty .. " ได้ " .. earned .. " เหรียญ")
		sendShopData(player)
		return
	end
	if seedCrop then
		local seedTool = findSeedToolForSale(player, seedCrop)
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		if not (seedTool and coins) then return end
		local have = seedTool:GetAttribute("Count") or 0
		if have <= 0 then return end
		local qty = math.clamp(math.floor(tonumber(quantity) or have), 1, have)
		local earned = SEED_SELL_PRICE[seedCrop] * qty
		coins.Value += earned
		if have - qty <= 0 then
			seedTool:Destroy()
		else
			seedTool:SetAttribute("Count", have - qty)
			seedTool.Name = seedCrop .. " x" .. (have - qty) -- ชื่อแบบเดียวกับ giveSeedTool
		end
		print(player.Name .. " ขายเมล็ด " .. seedCrop .. " x" .. qty .. " ได้ " .. earned .. " เหรียญ")
		sendShopData(player)
		return
	end
	-- ผักกลายพันธุ์: CropType "Mut_<กลายพันธุ์>_<พืช>"
	local mutation
	if type(cropType) == "string" then
		local m, c = cropType:match("^Mut_(%a+)_(.+)$")
		if m then
			if not MutationConfig.Get(m) then return end
			mutation, cropType = m, c
		end
	end
	local tool = findProduceTool(player, cropType, star, mutation)
	if not tool then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
	if not coins then return end

	local count = tool:GetAttribute("Count") or 0
	if count <= 0 then return end

	quantity = math.clamp(math.floor(tonumber(quantity) or count), 1, count)

	local unitPrice = cropUnitPrice(player, cropType, star, mutation)
	local earned = unitPrice * quantity

	coins.Value += earned

	local remaining = count - quantity
	if remaining <= 0 then
		tool:Destroy()
	else
		tool:SetAttribute("Count", remaining)
		local baseLabel = tool.Name:match("^(.-)%s*x%d+$") or tool.Name
		tool.Name = baseLabel .. " x" .. remaining
	end

	print(player.Name .. " ขาย " .. cropType .. " ดาว " .. star .. " x" .. quantity .. " ได้ " .. earned .. " เหรียญ")

	sendShopData(player)
end)

-- ขายผลผลิตทุกชิ้นในกระเป๋า/มือรวดเดียว (ราคาต่อชิ้นคิดสูตรเดียวกับขายทีละชนิด)
-- เซิร์ฟเวอร์คิดเงินเองทั้งหมด ไม่เชื่อยอดที่ฝั่งผู้เล่นส่งมา
sellAllCrops.OnServerEvent:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
	if not coins then return end

	local totalEarned, totalCount = 0, 0
	local orchardEarned = 0 -- ผลไม้สวนในก้อนนี้ (แจ้ง CheatWatch)
	local orchardShop = inOrchardShop(player) -- ร้านผลไม้ = ขายเฉพาะผลไม้สวน · ร้านเมล็ดพันธุ์ = ทุกอย่างยกเว้นผลไม้สวน
	for _, location in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("Starred") then
					-- ติดดาวไว้: ขายทั้งหมดก็ไม่ขายตัวนี้
				elseif orchardShop ~= (item:IsA("Tool") and item:GetAttribute("IsOrchardFruit") == true) then
					-- ไม่ใช่ของร้านนี้
				elseif item:IsA("Tool") and item:GetAttribute("IsFish") then
					-- ปลาขายรวมไปด้วย
					local count = item:GetAttribute("Count") or 0
					local fishId = item:GetAttribute("FishId")
					if count > 0 and FishingConfig.Fish[fishId] then
						totalEarned += SultanConfig.ApplySell(player, FishingConfig.GetPrice(fishId, math.clamp(item:GetAttribute("Star") or 1, 1, 5))) * count
						totalCount += count
						item:Destroy()
					end
				elseif item:IsA("Tool") and item:GetAttribute("IsOrchardFruit") and OrchardConfig.Enabled then
					local count = math.floor(tonumber(item:GetAttribute("Count")) or 0)
					local def = OrchardConfig.Trees[item:GetAttribute("FruitKind")]
					if count > 0 and def then
						totalEarned += def.FruitPrice * count
						orchardEarned += def.FruitPrice * count
						totalCount += count
						item:Destroy()
					end
				elseif item:IsA("Tool") and item:GetAttribute("IsProduce") then
					local count = item:GetAttribute("Count") or 0
					local cropType = item:GetAttribute("CropType")
					local star = math.clamp(item:GetAttribute("Star") or 1, 1, 5)
					if count > 0 and cropType then
						local unitPrice = cropUnitPrice(player, cropType, star, item:GetAttribute("Mutation"))
						totalEarned += unitPrice * count
						totalCount += count
						item:Destroy()
					end
				end
			end
		end
	end

	if totalCount == 0 then return end

	if orchardEarned > 0 then CheatWatch.AllowCoinGain(player, orchardEarned) end
	coins.Value += totalEarned
	if orchardEarned > 0 then saveBagAndCoins(player) end
	local lang = Localization.GetLanguage(player)
	harvestNotify:FireClient(player, nil, nil, nil, Localization.F("Shop_SoldAll", lang, totalCount, totalEarned))
	print(player.Name .. " ขายผลผลิตทั้งหมด " .. totalCount .. " ชิ้น ได้ " .. totalEarned .. " เหรียญ")

	sendShopData(player)
end)