-- BACKUP 2026-11-18 of game.ServerScriptService.PlantingSystem before fix: safe Backpack lookup / no item loss when Backpack missing
-- Restore: paste everything below this header into ServerScriptService.PlantingSystem Source
-- PlantingSystem: ปลูกได้หลายต้นต่อแปลง (คำนวณตารางจากขนาดแปลงจริง)

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local farmPlots = workspace:WaitForChild("FarmPlots")
local cropTemplates = ServerStorage:WaitForChild("CropTemplates")
local ServerScriptService = game:GetService("ServerScriptService")
local WeatherConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("WeatherConfig")) -- ฝนตก = พืชโตเร็วขึ้น
local Debris = game:GetService("Debris")
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local LevelSystem = require(ServerScriptService:WaitForChild("LevelSystem"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
-- สมุดพืช (2026-10-30): บันทึกผลผลิตตอนเก็บ + โบนัสความชำนาญ (โตเร็ว / ดาว +1) อ่านจาก Attribute CB_Grow_/CB_Star_<พืช> บนตัวผู้เล่น (ระบบปิด = ไม่มี Attribute)
local CropBook = require(ServerScriptService:WaitForChild("CropBook"))
local Achievement = require(ServerScriptService:WaitForChild("AchievementService")) -- เหรียญตรา Roblox: นับยอดปลูกสะสม (2026-11-04)
local CropBookConfig = require(ReplicatedStorage:WaitForChild("CropBookConfig"))
-- ผักกลายพันธุ์ (2026-10-30): สุ่มตอนเก็บเกี่ยว ใช้ค่าโชคตอนปลูก (slot.luck) + ฝนตกไหม
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))
-- ประกวดผักยักษ์ (2026-10-31): ได้ผักยักษ์ = ส่งให้ CropContest ชั่ง (ระบบปิด = OnGiant ว่าง)
local CropContest = require(ServerScriptService:WaitForChild("CropContest"))
local MUTATION_ANNOUNCE_COOLDOWN = 300 -- ประกาศผักรุ้งทั้งเซิร์ฟ คนละไม่เกิน 1 ครั้งต่อ 5 นาที
-- ค่าตารางช่องปลูก แชร์กับไกด์สีเขียว/แดงฝั่งผู้เล่น (PlantSlotGuide) จะได้คำนวณช่องตรงกันเสมอ
local FarmGridConfig = require(ReplicatedStorage:WaitForChild("FarmGridConfig"))
-- สี/จำนวนดวงของออร่าตามดาว เซิร์ฟเวอร์แค่ติดป้าย ส่วนตัววงหิ่งห้อยวาดที่ CropAuraRing ฝั่งผู้เล่น
local CropAuraConfig = require(ReplicatedStorage:WaitForChild("CropAuraConfig"))
local CollectionService = game:GetService("CollectionService")
local DEFAULT_LANG = "th" -- ภาษาที่ใช้กับข้อความที่ทุกคนเห็นร่วมกัน (เช่น ป้าย ProximityPrompt) เพราะแยกตามผู้เล่นไม่ได้

-- สวิตช์ log ดีบักการปลูก/เก็บเกี่ยว: ปกติปิด (ไม่พิมพ์อะไร ไม่กิน log)
-- เปิด: ตั้ง Attribute DebugPlanting = true บน workspace (ใน Studio ตั้งใน Properties ก่อนกด Play; เกมจริงสั่งจาก Console ฝั่งเซิร์ฟเวอร์)
local function debugOn()
	return workspace:GetAttribute("DebugPlanting") == true
end

-- ตัวนับสะสมตั้งแต่เปิดเซิร์ฟ (2026-10-14 optimize ผัก ขั้น 0): ServerHealthLogger อ่าน Attribute เหล่านี้ไปจดทุก 5 นาที
-- StatPlanted = ปลูก, StatHarvested = เก็บ, StatStageModels = โคลนโมเดลต้น (ทุกครั้งที่เปลี่ยนระยะ)
local function bumpStat(name)
	script:SetAttribute(name, (script:GetAttribute(name) or 0) + 1)
end

local XP_PER_STAR = 10 -- XP ที่ได้ต่อ 1 ดาวคุณภาพของผลผลิตที่เก็บเกี่ยวได้ (5 ดาว = 50 XP)

-- ต้นโตครบแล้วค้างไว้เกินเท่านี้ (วินาที) ระบบเก็บเข้ากระเป๋าให้เอง กันลืมเก็บแล้วช่องค้างเปล่า
local AUTO_HARVEST_DELAY = 180
-- ระยะไกลสุดที่ยอมให้กดป้ายเก็บเกี่ยว (ป้ายเองขึ้นที่ ~10 studs เผื่อแล็ก/ตัวละครขยับ) กันยิงป้ายจากอีกฟากแมพ
local HARVEST_PROMPT_MAX_DISTANCE = 30

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local harvestNotify = remoteEvents:FindFirstChild("HarvestNotify")
if not harvestNotify then
	harvestNotify = Instance.new("RemoteEvent")
	harvestNotify.Name = "HarvestNotify"
	harvestNotify.Parent = remoteEvents
end

-- เสียงปลูก/เก็บ: ให้เครื่องผู้เล่นที่อยู่ใกล้เล่นเอง (CropSoundClient) แทนการสร้าง Part+Sound บนเซิร์ฟทุกครั้ง (2026-10-14)
local cropSound = remoteEvents:FindFirstChild("CropSound")
if not cropSound then
	cropSound = Instance.new("RemoteEvent")
	cropSound.Name = "CropSound"
	cropSound.Parent = remoteEvents
end

local plantByClick = remoteEvents:FindFirstChild("PlantByClick")
if not plantByClick then
	plantByClick = Instance.new("RemoteEvent")
	plantByClick.Name = "PlantByClick"
	plantByClick.Parent = remoteEvents
end

-- ============ ระบบจำกัดจำนวนต้นที่ปลูกพร้อมกันต่อผู้เล่น + Developer Product เพิ่มโควต้า (ซื้อซ้ำได้เรื่อยๆ) ============
local DataStoreService = game:GetService("DataStoreService")
local boostDataStore = DataStoreService:GetDataStore("PlantBoostPurchases_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))

-- ข้อมูลโควต้าที่ซื้อ: ข้อมูลเก่าเป็นตัวเลขเฉยๆ ข้อมูลใหม่เก็บยอดรวม, ซื้อด้วยเหรียญ และใบเสร็จ Robux
local function readBoostRecord(value)
	if type(value) == "number" then
		return { count = value, coinCount = 0, receipts = {} }
	elseif type(value) == "table" then
		return {
			count = tonumber(value.count) or 0,
			coinCount = math.max(0, tonumber(value.coinCount) or 0),
			receipts = type(value.receipts) == "table" and value.receipts or {},
		}
	end
	return { count = 0, coinCount = 0, receipts = {} }
end

local BASE_PLANT_LIMIT = 10
local BOOST_AMOUNT = 5 -- ซื้อ 1 ครั้ง ปลูกเพิ่มได้อีกเท่านี้
local BOOST_PRODUCT_ID = 3712426475 -- Developer Product "เพิ่มโควต้าปลูก +5"
local GIFT_PRODUCT_ID = 3715853171 -- Developer Product "ของขวัญโควต้าปลูก +5" (ซื้อให้เพื่อน แยกจากของตัวเอง) 0 = ยังไม่ได้สร้างสินค้า
local COIN_BOOST_PRICES = { 200000, 300000, 350000 }
local COIN_BOOST_MAX_PURCHASES = #COIN_BOOST_PRICES

local boostPurchaseCount = {} -- [player.UserId] = จำนวนครั้งที่เพิ่มโควต้าทั้งหมด (เซฟถาวร)
local coinBoostPurchaseCount = {} -- [player.UserId] = จำนวนครั้งที่ซื้อด้วยเหรียญ (สูงสุด 3)
local coinBoostDataLoaded = {} -- [player.UserId] = โหลดข้อมูลโควต้าจาก DataStore สำเร็จ
local coinBoostPurchaseBusy = {} -- ป้องกันกดซื้อซ้ำระหว่างกำลังบันทึก
local plantCountByPlayer = {} -- [player.UserId] = จำนวนต้นที่กำลังปลูกอยู่ตอนนี้ (นับเฉพาะที่ยังไม่เก็บเกี่ยว ไม่เซฟ รีเซตทุกครั้งที่เซิร์ฟเวอร์รีสตาร์ท)

local plantLimitUpdate = remoteEvents:FindFirstChild("PlantLimitUpdate")
if not plantLimitUpdate then
	plantLimitUpdate = Instance.new("RemoteEvent")
	plantLimitUpdate.Name = "PlantLimitUpdate"
	plantLimitUpdate.Parent = remoteEvents
end

local promptPlantBoost = remoteEvents:FindFirstChild("PromptPlantBoost")
if not promptPlantBoost then
	promptPlantBoost = Instance.new("RemoteEvent")
	promptPlantBoost.Name = "PromptPlantBoost"
	promptPlantBoost.Parent = remoteEvents
end
-- บอก Product ID ให้ร้านค้าด่วน (PlantLimitGui) ดึงราคา Robux จริงมาแสดงบนปุ่มซื้อได้
promptPlantBoost:SetAttribute("ProductId", BOOST_PRODUCT_ID)
promptPlantBoost:SetAttribute("BoostAmount", BOOST_AMOUNT)
promptPlantBoost:SetAttribute("GiftProductId", GIFT_PRODUCT_ID) -- ฝั่งผู้เล่นอ่านไปเปิด/ซ่อนปุ่มของขวัญ + ดึงราคาจริง

local function getPlantLimit(player)
	local count = boostPurchaseCount[player.UserId] or 0
	return BASE_PLANT_LIMIT + (count * BOOST_AMOUNT)
end

local function getPlayerPlantCount(player)
	return plantCountByPlayer[player.UserId] or 0
end

local function notifyPlantLimit(player)
	if not player or not player.Parent then return end
	-- เปิดโควต้าจริงให้สคริปต์อื่นอ่านได้ (สัตว์เลี้ยง "ช่วยปลูกผัก" ใช้เพดานนี้)
	-- เดิม Planter ฝังเลข 10 ไว้เอง ทั้งที่โควต้าจริงคือ 10 + (ซื้อเพิ่ม x 5) จึงหยุดปลูกก่อนถึงโควต้าจริง
	player:SetAttribute("PlantLimit", getPlantLimit(player))
	-- จำนวนต้นที่ปลูกอยู่ตอนนี้ (PlantSlotGuide อ่านไปเทียบกับโควต้า ไว้เปลี่ยนไกด์เป็นสีแดงตอนโควต้าเต็ม)
	player:SetAttribute("PlantCount", getPlayerPlantCount(player))
	plantLimitUpdate:FireClient(player, getPlayerPlantCount(player), getPlantLimit(player),
		coinBoostPurchaseCount[player.UserId] or 0, coinBoostDataLoaded[player.UserId] == true)

end

-- ปรับจำนวนต้นที่ปลูกอยู่ของผู้เล่นคนนี้ (delta = +1 ตอนปลูกใหม่, -1 ตอนเก็บเกี่ยว/ล้างทิ้ง)
local function changePlantCount(player, delta)
	if not player then return end
	local current = plantCountByPlayer[player.UserId] or 0
	plantCountByPlayer[player.UserId] = math.max(0, current + delta)
	notifyPlantLimit(player)
end

-- โหลดจำนวนครั้งที่เคยซื้อไว้แล้วจาก DataStore ตอนผู้เล่นเข้าเกม
local function loadBoostPurchases(player)
	DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
	local ok, value = pcall(function()
		return boostDataStore:GetAsync(tostring(player.UserId))
	end)
	-- ถ้าโหลดไม่สำเร็จ ยังซื้อด้วยเหรียญไม่ได้ ป้องกันการรีเซ็ตจำนวนครั้งหรือซื้อเกินสิทธิ์
	local record = ok and readBoostRecord(value) or nil
	boostPurchaseCount[player.UserId] = record and record.count or 0
	coinBoostPurchaseCount[player.UserId] = record and record.coinCount or 0
	coinBoostDataLoaded[player.UserId] = ok
	notifyPlantLimit(player)
	if not ok then
		warn("PlantingSystem: โหลดโควต้าปลูกของ " .. player.Name .. " ไม่สำเร็จ: " .. tostring(value) .. " (ลองต่อเบื้องหลัง)")
		-- เดิมอ่านครั้งเดียว พัง = โควต้าค้าง 10 ต้น + ซื้อด้วยเหรียญไม่ได้ทั้งรอบ (DataStore throttle) ลองต่อเบื้องหลังจนได้ 2026-10-09
		DataLoadRetry.Background(player, "PlantingSystem(quota)", DataLoadRetry.Get(boostDataStore, tostring(player.UserId)), function(lateValue)
			if coinBoostDataLoaded[player.UserId] then return end
			local late = readBoostRecord(lateValue)
			-- ระหว่างรอ อาจซื้อด้วย Robux แล้ว (บันทึกด้วย UpdateAsync จากค่าจริง) เอาค่ามากกว่า
			boostPurchaseCount[player.UserId] = math.max(late.count, boostPurchaseCount[player.UserId] or 0)
			coinBoostPurchaseCount[player.UserId] = late.coinCount
			coinBoostDataLoaded[player.UserId] = true
			notifyPlantLimit(player)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	plantCountByPlayer[player.UserId] = 0
	loadBoostPurchases(player)
end)

Players.PlayerRemoving:Connect(function(player)
	plantCountByPlayer[player.UserId] = nil
	boostPurchaseCount[player.UserId] = nil
	coinBoostPurchaseCount[player.UserId] = nil
	coinBoostDataLoaded[player.UserId] = nil
	coinBoostPurchaseBusy[player.UserId] = nil
end)

for _, existingPlayer in ipairs(Players:GetPlayers()) do
	plantCountByPlayer[existingPlayer.UserId] = 0
	loadBoostPurchases(existingPlayer)
end

local function purchaseCoinPlantBoost(player)
	local userId = player.UserId
	if coinBoostPurchaseBusy[userId] then return end
	coinBoostPurchaseBusy[userId] = true

	local function finish(status)
		coinBoostPurchaseBusy[userId] = nil
		notifyPlantLimit(player)
		plantLimitUpdate:FireClient(player, getPlayerPlantCount(player), getPlantLimit(player),
			coinBoostPurchaseCount[userId] or 0, coinBoostDataLoaded[userId] == true, status)
	end

	if not coinBoostDataLoaded[userId] then
		finish("data_unavailable")
		return
	end
	if player:GetAttribute("CoinsLoaded") ~= true then
		finish("coins_loading")
		return
	end

	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
	if not coins then
		finish("coins_unavailable")
		return
	end

	local currentCoinCount = coinBoostPurchaseCount[userId] or 0
	if currentCoinCount >= COIN_BOOST_MAX_PURCHASES then
		finish("max")
		return
	end

	local price = COIN_BOOST_PRICES[currentCoinCount + 1]
	if coins.Value < price then
		finish("not_enough")
		return
	end

	-- หักเหรียญก่อนบันทึก และคืนให้ทันทีถ้า DataStore ไม่รับรายการ
	player:SetAttribute("CoinSrc", "plant_quota")
	coins.Value -= price
	local ok, savedValue = pcall(function()
		return boostDataStore:UpdateAsync(tostring(userId), function(old)
			local data = readBoostRecord(old)
			if data.coinCount >= COIN_BOOST_MAX_PURCHASES then
				return data
			end
			data.coinCount += 1
			data.count += 1
			return data
		end)
	end)

	if not ok or savedValue == nil then
		coins.Value += price
		warn("PlantingSystem: บันทึกการซื้อโควต้าด้วยเหรียญของ " .. player.Name .. " ไม่สำเร็จ: " .. tostring(savedValue))
		finish("save_failed")
		return
	end

	local savedRecord = readBoostRecord(savedValue)
	if savedRecord.coinCount <= currentCoinCount then
		-- อีกเซิร์ฟเวอร์อาจซื้อครบ 3 ครั้งไปแล้วระหว่างที่ผู้เล่นกำลังกดซื้อ
		coins.Value += price
		coinBoostPurchaseCount[userId] = savedRecord.coinCount
		boostPurchaseCount[userId] = savedRecord.count
		finish("max")
		return
	end

	coinBoostPurchaseCount[userId] = savedRecord.coinCount
	boostPurchaseCount[userId] = savedRecord.count
	finish("bought")
end

promptPlantBoost.OnServerEvent:Connect(function(player, paymentType)
	if paymentType == "coins" then
		purchaseCoinPlantBoost(player)
	else
		MarketplaceService:PromptProductPurchase(player, BOOST_PRODUCT_ID)
	end
end)

-- ============ ซื้อด้วย Robux: ลงทะเบียนสินค้ากับตัวรับเงินกลาง (PurchaseRouter) ============
-- Roblox ให้มี ProcessReceipt ได้ตัวเดียวทั้งเกม ตอนนี้อยู่ที่ ServerScriptService.PurchaseRouter
-- (เรื่องผู้เล่นออกเกม / ใบเสร็จซ้ำ / ให้ของพังแล้วให้ Roblox ลองใหม่ ตัวกลางจัดการให้ทุกสินค้า)
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))
local DonationConfig = require(ReplicatedStorage:WaitForChild("DonationConfig"))
local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))

local donationThanks = remoteEvents:FindFirstChild("DonationThanks")
if not donationThanks then
	donationThanks = Instance.new("RemoteEvent")
	donationThanks.Name = "DonationThanks"
	donationThanks.Parent = remoteEvents
end

-- บริจาค: ไม่มีของให้ ยืนยันได้เลยแม้ผู้เล่นออกไปแล้ว (แค่ไม่ได้เห็นคำขอบคุณ)
-- บันทึกยอดสะสมลงป้ายผู้สนับสนุน (DonorRecords จำเลขใบเสร็จเอง นับซ้ำไม่ได้) บันทึกไม่ได้ = ยังไม่ยืนยัน ให้ Roblox ลองใหม่
local DonorRecords = require(ServerScriptService:WaitForChild("DonorRecords"))
-- 2026-10-24: โดเนทพร้อมข้อความ = ประกาศทุกเซิร์ฟ (ข้อความตรวจไว้แล้วก่อนจ่ายเงิน ดู DonationAnnounce)
local DonationAnnounce = require(ServerScriptService:WaitForChild("DonationAnnounce"))
for _, tier in ipairs(DonationConfig.Tiers) do
	PurchaseRouter.Register(tier.ProductId, {
		name = "บริจาค " .. tier.Amount,
		allowOffline = true,
		trackReceipt = false,
		grant = function(donor, receiptInfo)
			-- CurrencySpent = Robux ที่จ่ายจริง (ราคาใน Dashboard อาจไม่ตรงกับเลข Amount ใน DonationConfig)
			local spent = receiptInfo.CurrencySpent or tier.Amount
			local ok, isNew = DonorRecords.Record(receiptInfo.PlayerId, spent, receiptInfo.PurchaseId)
			if not ok then return false end
			if donor and isNew then
				donationThanks:FireClient(donor, spent)
			end
			if isNew then
				local announced, err = pcall(DonationAnnounce.OnDonated, receiptInfo, donor, spent)
				if not announced then warn("PlantingSystem: ประกาศโดเนทพัง: " .. tostring(err)) end
			end
			return true
		end,
	})
end

-- หุ่นทองคำนำโชค x100 (ตัวกลางจำใบเสร็จให้ ไม่ได้หุ่นเบิ้ลตอน Roblox เรียกซ้ำ)
PurchaseRouter.Register(LuckConfig.BoosterTiers.x100.ProductId, {
	name = "หุ่นทองคำนำโชค (ระดับ x100)",
	grant = function(buyer)
		ItemFactory.GiveBoosterTool(buyer, 1, "x100")
		harvestNotify:FireClient(buyer, nil, nil, nil,
			"🍀 " .. Localization.T("Item_BoosterX100", Localization.GetLanguage(buyer)) .. " +1")
		return true
	end,
})

-- เพิ่มโควต้าปลูก +5: บวกเพิ่มจากค่าที่เซฟไว้จริงใน DataStore (UpdateAsync) และจำเลขใบเสร็จไว้ในข้อมูลเดียวกัน
-- เดิมเอาค่าที่โหลดไว้ตอนเข้าเกม +1 แล้ว SetAsync ทับ ถ้าตอนเข้าเกมโหลดไม่สำเร็จ (นับเป็น 0)
-- ซื้อครั้งถัดไปจะเขียนทับเป็น 1 -> คนที่เคยซื้อไว้ 5 ครั้งเสียโควต้าที่จ่ายเงินไปถาวร
PurchaseRouter.Register(BOOST_PRODUCT_ID, {
	name = "เพิ่มโควต้าปลูก +" .. BOOST_AMOUNT,
	grant = function(player, receiptInfo)
		local purchaseId = tostring(receiptInfo.PurchaseId)
		local newCount
		local ok, err = pcall(function()
			boostDataStore:UpdateAsync(tostring(player.UserId), function(old)
				local data = readBoostRecord(old)
				if table.find(data.receipts, purchaseId) then
					newCount = data.count
					return nil -- ใบเสร็จนี้นับไปแล้ว ไม่ต้องเขียน
				end
				data.count += 1
				table.insert(data.receipts, purchaseId)
				while #data.receipts > 50 do table.remove(data.receipts, 1) end
				newCount = data.count
				return data
			end)
		end)
		if not ok or not newCount then
			warn("PlantingSystem: เพิ่มโควต้าให้ " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
			return false -- ยังไม่ยืนยัน ให้ Roblox ลองใหม่ (เงินไม่หาย)
		end
		boostPurchaseCount[player.UserId] = newCount
		notifyPlantLimit(player)
		harvestNotify:FireClient(player, nil, nil, nil,
			Localization.F("Booster_PurchaseSuccess", Localization.GetLanguage(player), getPlantLimit(player)))
		return true
	end,
})

-- ============ ของขวัญโควต้าปลูก +5 (Developer Product: GIFT_PRODUCT_ID) ============
-- สินค้าแยกจากการซื้อให้ตัวเอง (BOOST_PRODUCT_ID) ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนได้ "ซื้อโควต้า" เพิ่ม 1 ครั้ง (+BOOST_AMOUNT ต้น ถาวร)
-- โควต้าเก็บเป็นจำนวนครั้งที่ซื้อใน boostDataStore ตาม UserId ของผู้รับ จึงบวกให้ได้ทันทีแม้ผู้รับออกเกมไปแล้ว (ไม่ต้องเช็กตอนเข้าเกมเพิ่ม)
-- ซื้อให้เพื่อนซ้ำได้เรื่อยๆ (โควต้าสะสม) DataStore "PlantQuotaGift_v1": "pending_<buyerId>" = { to, toName, t } (ผู้ซื้อเลือกผู้รับไว้)
local giftStore = DataStoreService:GetDataStore("PlantQuotaGift_v1")
local giftRequest = remoteEvents:FindFirstChild("PlantQuotaGiftRequest")
if not giftRequest then
	giftRequest = Instance.new("RemoteFunction")
	giftRequest.Name = "PlantQuotaGiftRequest"
	giftRequest.Parent = remoteEvents
end
local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local GIFT_PROMPT_TIMEOUT = 120

local function grantQuotaGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return giftStore:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("PlantingSystem: ใบเสร็จของขวัญโควต้าของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local purchaseId = "gift_" .. tostring(receiptInfo.PurchaseId)
	local newCount
	local ok, err = pcall(function()
		boostDataStore:UpdateAsync(tostring(pending.to), function(old)
			local data = readBoostRecord(old)
			if table.find(data.receipts, purchaseId) then
				newCount = data.count
				return nil -- ใบเสร็จนี้นับไปแล้ว
			end
			data.count += 1
			table.insert(data.receipts, purchaseId)
			while #data.receipts > 50 do table.remove(data.receipts, 1) end
			newCount = data.count
			return data
		end)
	end)
	if not ok or not newCount then
		warn("PlantingSystem: ให้โควต้าเป็นของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false -- ยังไม่ยืนยัน ให้ Roblox ลองใหม่ (เงินไม่หาย)
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() giftStore:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	local target = Players:GetPlayerByUserId(pending.to)
	if target then
		boostPurchaseCount[target.UserId] = newCount
		notifyPlantLimit(target)
		harvestNotify:FireClient(target, nil, nil, nil, "🎁 " .. buyer.DisplayName .. " ส่งโควต้าปลูก +" .. BOOST_AMOUNT .. " ให้คุณเป็นของขวัญ! ปลูกได้สูงสุด " .. getPlantLimit(target) .. " ต้นแล้ว 🌱")
	end
	harvestNotify:FireClient(buyer, nil, nil, nil, "🎁 ส่งโควต้าปลูก +" .. BOOST_AMOUNT .. " ให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖")
	print("🎁 PlantingSystem: " .. buyer.Name .. " ส่งโควต้าปลูก +" .. BOOST_AMOUNT .. " ให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(GIFT_PRODUCT_ID, { name = "ของขวัญโควต้าปลูก +" .. BOOST_AMOUNT, grant = grantQuotaGift })

-- โค้ดกิจกรรม (2026-10-19): SultanService เรียก ServerScriptService.PlantQuotaPromoGrant:Invoke(player, ref, times) = โควต้า +BOOST_AMOUNT ถาวร times ครั้ง (ไม่ใส่ = 1, สูงสุด 100)
-- ref เก็บใน receipts เหมือนใบเสร็จ = เรียกซ้ำด้วย ref เดิมไม่ได้เพิ่มซ้ำ · คืน true เมื่อบันทึกแล้ว
local quotaPromoGrant = game:GetService("ServerScriptService"):FindFirstChild("PlantQuotaPromoGrant")
if not quotaPromoGrant then
	quotaPromoGrant = Instance.new("BindableFunction")
	quotaPromoGrant.Name = "PlantQuotaPromoGrant"
	quotaPromoGrant.Parent = game:GetService("ServerScriptService")
end
quotaPromoGrant.OnInvoke = function(player, ref, times)
	if type(ref) ~= "string" or ref == "" then return false end
	times = math.clamp(math.floor(tonumber(times) or 1), 1, 100)
	local newCount
	local ok, err = pcall(function()
		boostDataStore:UpdateAsync(tostring(player.UserId), function(old)
			local data = readBoostRecord(old)
			if table.find(data.receipts, ref) then
				newCount = data.count
				return nil
			end
			data.count += times
			table.insert(data.receipts, ref)
			while #data.receipts > 50 do table.remove(data.receipts, 1) end
			newCount = data.count
			return data
		end)
	end)
	if not ok or not newCount then
		warn("PlantingSystem: ให้โควต้าจากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return false
	end
	if player.Parent then
		boostPurchaseCount[player.UserId] = newCount
		notifyPlantLimit(player)
	end
	return true
end

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกัน ไม่จำกัดว่ามีโควต้าเพิ่มแล้วหรือยัง) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
local function giftSelect(player, targetUserId)
	-- Studio: ยังไม่มี ID สินค้า หรือผู้ทดสอบตั้ง Attribute DevGiftSimulate = true (จากฝั่งเซิร์ฟเวอร์) = จำลองการจ่ายเงิน ไม่เรียกหน้าชำระเงินจริง
	local RunService = game:GetService("RunService")
	local studioTest = RunService:IsStudio() and (GIFT_PRODUCT_ID == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if GIFT_PRODUCT_ID == 0 and not studioTest then return { ok = false, message = "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨" } end
	if type(targetUserId) ~= "number" or targetUserId ~= targetUserId then return { ok = false, message = "คำขอไม่ถูกต้อง" } end
	targetUserId = math.floor(targetUserId)
	if targetUserId == player.UserId then return { ok = false, message = "ส่งให้ตัวเองไม่ได้ (ซื้อโควต้าให้ตัวเองได้ที่ร้านสุดพิเศษ)" } end
	local started = giftPrompting[player]
	if started and os.clock() - started < GIFT_PROMPT_TIMEOUT then
		return { ok = false, message = "กำลังทำรายการก่อนหน้าอยู่ รอสักครู่" }
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local toName
	if target then
		if boostPurchaseCount[target.UserId] == nil then
			return { ok = false, message = "ข้อมูลของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		toName = target.DisplayName
	elseif RunService:IsStudio() and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId -- ทดสอบใน Studio เท่านั้น (ตั้ง Attribute จากฝั่งเซิร์ฟเวอร์)
	else
		return { ok = false, message = "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว" }
	end
	local pending = { to = targetUserId, toName = toName, t = os.time() }
	local okSave, err = pcall(function() giftStore:SetAsync("pending_" .. player.UserId, pending, { player.UserId }) end)
	if not okSave then
		warn("PlantingSystem: จำผู้รับของขวัญโควต้าไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantQuotaGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("PlantingSystem: จำลองของขวัญโควต้าไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, GIFT_PRODUCT_ID)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: โควต้าปลูก +" .. BOOST_AMOUNT .. " สำหรับ " .. toName }
end

giftRequest.OnServerInvoke = function(player, action, value)
	if action == "giftSelect" then return giftSelect(player, value) end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
end

-- ปิดหน้าจ่ายเงินโดยไม่ซื้อ = เลือกคนใหม่ได้เลย (ซื้อสำเร็จ: รอ grantQuotaGift ล้างให้)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if GIFT_PRODUCT_ID == 0 or productId ~= GIFT_PRODUCT_ID or purchased then return end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		giftPending[player] = nil
		giftPrompting[player] = nil
	end
end)
Players.PlayerRemoving:Connect(function(player)
	giftPending[player] = nil
	giftPrompting[player] = nil
end)

local MAX_PLANT_DISTANCE = FarmGridConfig.MaxPlantDistance
local soilToTryPlant = {}
local allSlots = {} -- รวม slot ทุกช่องจากทุกแปลง (ใช้ตอนผู้เล่นออกจากเกม เพื่อไปเก็บเกี่ยว/คืนเมล็ดต้นของเขา)
local FarmSlotRegistry = require(ServerScriptService:WaitForChild("FarmSlotRegistry"))
FarmSlotRegistry.Slots = allSlots -- ผูก reference เข้าด้วยกัน (allSlots โตขึ้นทีหลัง ก็จะเห็นพร้อมกันอัตโนมัติ)

-- ราคาเมล็ดแต่ละชนิด (ต้องตรงกับ SHOP_ITEMS ใน ShopSystem.lua) ใช้คืนเงินตอนผู้เล่นออกจากเกมทั้งที่ต้นยังไม่โต
local SEED_PRICE = {
	Strawberry = 10,
	Corn = 15,
	Wheat = 8,
	Onion = 12,
	Pineapple = 18,
	Watermelon = 20,
	Potato = 11,
	Cucumber = 14,
	Eggplant = 19,
	Pumpkin = 24,
	Carrot = 22, -- แครอท (2026-11-04 ราคาต้องตรง ShopSystem)
	Sunflower = 30,
	Chili = 36,
	WitchBerry = 32, -- เบอร์รี่แม่มด พืชเทศกาลฮาโลวีน (2026-10-14)
}

-- ค่าตารางช่องปลูก (ระยะห่าง/เพดานแถว-คอลัมน์) ย้ายไปอยู่ ReplicatedStorage.FarmGridConfig แล้ว
-- เพราะไกด์ฝั่งผู้เล่นต้องใช้สูตรเดียวกัน กรอบไกด์จะได้ตรงกับช่องที่ปลูกจริงเสมอ
local GRID_SPACING = FarmGridConfig.GridSpacing

-- ระยะเวลาต่อสเตจ (วินาที) แยกตามชนิดพืช ปรับตัวเลขให้เร็ว/ช้าตามใจได้เลย
local STAGE_DURATION_BY_CROP = {
	Strawberry = { [1] = 4.4, [2] = 4.4, [3] = 4.4, [4] = 4.4, [5] = 0 }, -- รวม 17.6 วินาที (โตเร็ว, ช้าลง 10% จากเดิม)
	Corn = { [1] = 8.8, [2] = 8.8, [3] = 8.8, [4] = 8.8, [5] = 0 }, -- รวม 35.2 วินาที (โตช้ากว่า, ช้าลง 10% จากเดิม)
	Wheat = { [1] = 3.3, [2] = 3.3, [3] = 3.3, [4] = 3.3, [5] = 0 }, -- รวม 13.2 วินาที (โตเร็วที่สุด, ช้าลง 10% จากเดิม)
	Onion = { [1] = 6.6, [2] = 6.6, [3] = 6.6, [4] = 6.6, [5] = 0 }, -- รวม 26.4 วินาที (กลางๆ ระหว่างข้าวสาลีกับข้าวโพด)
	Watermelon = { [1] = 10, [2] = 10, [3] = 10, [4] = 10, [5] = 0 }, -- รวม 40 วินาที (โตช้าที่สุด ผลใหญ่)
	Pineapple = { [1] = 9, [2] = 9, [3] = 9, [4] = 9, [5] = 0 }, -- รวม 36 วินาที (โตช้า ใกล้เคียงแตงโม)
	Potato = { [1] = 5.5, [2] = 5.5, [3] = 5.5, [4] = 5.5, [5] = 0 }, -- รวม 22 วินาที (ระหว่างสตรอว์เบอรี่กับหัวหอม)
	Cucumber = { [1] = 7.5, [2] = 7.5, [3] = 7.5, [4] = 7.5, [5] = 0 }, -- รวม 30 วินาที (ระหว่างหัวหอมกับสับปะรด)
	Eggplant = { [1] = 8.5, [2] = 8.5, [3] = 8.5, [4] = 8.5, [5] = 0 }, -- รวม 34 วินาที (ระหว่างสับปะรดกับแตงโม)
	Pumpkin = { [1] = 16.25, [2] = 16.25, [3] = 16.25, [4] = 16.25, [5] = 0 }, -- รวม 65 วินาที (พืชธีมฮาโลวีน)
	Carrot = { [1] = 12, [2] = 12, [3] = 12, [4] = 12, [5] = 0 }, -- รวม 48 วินาที (2026-11-04)
	Sunflower = { [1] = 18, [2] = 18, [3] = 18, [4] = 18, [5] = 0 }, -- รวม 72 วินาที
	Chili = { [1] = 22.5, [2] = 22.5, [3] = 22.5, [4] = 22.5, [5] = 0 }, -- รวม 90 วินาที
	WitchBerry = { [1] = 20, [2] = 20, [3] = 20, [4] = 20, [5] = 0 }, -- รวม 80 วินาที (พืชกิจกรรมฮาโลวีน 2026 เลเวล 5 ตั้งที่ ShopSystem.CROP_MIN_LEVEL)
}
local DEFAULT_STAGE_DURATION = { [1] = 5.5, [2] = 5.5, [3] = 5.5, [4] = 5.5, [5] = 0 } -- ใช้กรณีมีพืชชนิดใหม่ที่ยังไม่ได้ตั้งเวลาไว้
-- หน้าตาต้นที่แสดงต่อสเตจ (2026-10-24 ผู้ใช้เลือกตัวเลือก B): เหลือ 3 หน้าตา เมล็ด(1) → กลาง(3) → โตเต็ม(5)
-- สเตจ 2 / 4 ยังนับเวลาเหมือนเดิม แต่ใช้โมเดลเดิมต่อ (ไม่ลบ+โคลนใหม่) = สร้าง/ลบโมเดลต้นน้อยลง 40% ลดข้อมูลที่เซิร์ฟส่งให้ผู้เล่น
-- จำนวนที่วัดได้ก่อนแก้: เซิร์ฟจริง 7 คน ≈ 16.5 โมเดล/วิ (ServerHealth_v1 crop.m) · อยากได้ 5 หน้าตาคืน = ตั้ง { 1, 2, 3, 4, 5 }
local VISUAL_STAGE = { [1] = 1, [2] = 1, [3] = 3, [4] = 3, [5] = 5 }
-- เสียงตอนปลูก: "Dirt Impacts 12" ของ ProSoundEffects (เสียงกลบดิน 0.73 วิ) เดิมใช้ 9125467298 ที่ไม่ค่อยเข้ากับการปลูก
local PLANT_SOUND_ID = "rbxassetid://9114109871"
local PLANT_SOUND_VOLUME = 0.25 -- เดิม 0.5 ดังเกินตอนปลูกรัวๆ
local HARVEST_SOUND_ID = "rbxassetid://87359591155512"

-- ชื่อ leaderstats/สถิติ (คงเป็นภาษาไทยตายตัว เพราะชื่อ leaderstat ของ Roblox แยกภาษาไม่ได้)
local CROP_STAT_NAME = { Strawberry = "สตรอว์เบอร์รี่", Corn = "ข้าวโพด", Wheat = "ข้าวสาลี", Onion = "หัวหอม", Watermelon = "แตงโม", Pineapple = "สับปะรด", Potato = "มันฝรั่ง", Cucumber = "แตงกวา", Eggplant = "มะเขือยาว", Pumpkin = "ฟักทอง", WitchBerry = "เบอร์รี่แม่มด", Carrot = "แครอท", Sunflower = "ดอกทานตะวัน", Chili = "พริกขี้หนู" }

local STAR_CONFIG = {
	[1] = { Yield = 2 },
	[2] = { Yield = 3 },
	[3] = { Yield = 4 },
	[4] = { Yield = 5 },
	[5] = { Yield = 5 }, -- เดิม 6 ลดลง เพราะหุ่นโชคทำให้ต้น 5 ดาวออกบ่อย ได้ผลผลิตเยอะเกินไป (เท่า 4 ดาว ต่างกันที่โอกาสได้ดาวสูงตอนเก็บเกี่ยว)
}

-- (สีออร่าตามดาวย้ายไปอยู่ ReplicatedStorage.CropAuraConfig แล้ว เพราะฝั่งผู้เล่นเป็นคนวาดวงหิ่งห้อย)

-- (HELD_SCALE ของโมเดลตอนถือย้ายไปอยู่ที่ ItemFactory.lua แล้ว เพราะเป็นตัวสร้าง Tool จริงตอนนี้)

-- คุณภาพต้นตอนปลูกสุ่มตาม "ค่าโชค" (เดิมใช้ตารางคงที่ + ตารางการันตี 3 ดาวตอนอยู่ในระยะหุ่น)
-- ค่าโชค = หุ่นทุกตัวที่ครอบจุดนี้ (ของใครก็ได้ บวกกัน) + สัตว์เลี้ยง "นำโชค" ของคนปลูก ดู LuckSystem / ReplicatedStorage.LuckConfig
-- (LuckConfig require ไว้ด้านบนแล้ว ใช้ร่วมกับ ProcessReceipt)
local LuckSystem = require(ServerScriptService:WaitForChild("LuckSystem"))
local SultanConfig = require(ReplicatedStorage:WaitForChild("SultanConfig")) -- สุลต่าน: ทั้งต้นที่ปลูกและผลผลิตไม่ต่ำกว่า MIN_PLANT_QUALITY / MIN_PRODUCE_STAR

local HARVEST_ODDS = {
	[1] = { 100, 0, 0, 0, 0 },
	[2] = { 15, 60, 20, 4, 1 },
	[3] = { 5, 20, 50, 20, 5 },
	[4] = { 2, 8, 20, 50, 20 },
	[5] = { 1, 3, 8, 23, 65 },
}

local function rollFromWeights(weights)
	local total = 0
	for _, w in ipairs(weights) do total += w end

	-- น้ำหนักจากค่าโชคเป็นทศนิยมได้ จึงสุ่มแบบทศนิยม (math.random(1, total) รับแค่จำนวนเต็ม)
	local roll = math.random() * total
	local cumulative = 0
	for star, w in ipairs(weights) do
		cumulative += w
		if roll < cumulative then return star end -- ใช้ < กันสุ่มได้ช่องที่น้ำหนัก 0 ตอน roll = 0
	end
	return 1
end

local function rollPlantQuality(luck)
	return rollFromWeights(LuckConfig.ApplyLuck(luck))
end

local function rollHarvestStar(plantedStar)
	return rollFromWeights(HARVEST_ODDS[plantedStar] or HARVEST_ODDS[1])
end

local function findExistingProduceTool(player, cropType, star, mutation)
	local locations = { player.Backpack, player.Character }
	for _, location in ipairs(locations) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsProduce")
					and item:GetAttribute("CropType") == cropType
					and item:GetAttribute("Star") == star
					and item:GetAttribute("Mutation") == mutation then -- กลายพันธุ์แยกกอง (nil = ผักปกติ)
					return item
				end
			end
		end
	end
	return nil
end

local function giveProduceTool(player, cropType, star, amount, mutation)
	local existing = findExistingProduceTool(player, cropType, star, mutation)
	local lang = Localization.GetLanguage(player)

	if existing then
		local newCount = (existing:GetAttribute("Count") or 0) + amount
		existing:SetAttribute("Count", newCount)
		existing.Name = ItemFactory.GetProduceName(cropType, star, newCount, lang, mutation)
	else
		local tool = ItemFactory.CreateProduceTool(cropType, star, amount, lang, mutation)
		tool.Parent = player.Backpack
	end
end

local function setModelVisible(model, visible)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = visible and 0 or 1
			part.CanCollide = false
		end
	end
end

-- ออร่าต้นโตครบ: เซิร์ฟเวอร์แค่ติดป้ายบอกดาวไว้ คนวาดจริงคือ CropAuraRing ฝั่งผู้เล่น
-- เดิมเซิร์ฟเวอร์สร้าง Sparkles + PointLight ระยะ 8 ให้ทุกต้น พอปลูกชิดกันเยอะๆ เลยสว่างจ้ารกไปหมดและกินเครื่อง
local function clearAura(anchor)
	local legacy = anchor:FindFirstChild("QualityAura") -- ของเก่าที่อาจค้างอยู่จากเซิร์ฟเวอร์รอบก่อน
	if legacy then legacy:Destroy() end
	CollectionService:RemoveTag(anchor, CropAuraConfig.Tag)
	anchor:SetAttribute(CropAuraConfig.StarAttribute, nil)
end

local function attachAura(anchor, star)
	clearAura(anchor)
	if not CropAuraConfig.Stars[star] then return end -- 1 ดาวไม่มีออร่า (เหมือนเดิม)

	anchor:SetAttribute(CropAuraConfig.StarAttribute, star)
	CollectionService:AddTag(anchor, CropAuraConfig.Tag)
end

-- เล่นเสียงตรงตำแหน่งที่กำหนด โดยไม่ฝากไว้กับจุดยึดช่อง (จุดยึดโดนลบทันทีหลังเก็บเกี่ยว เสียงจะขาดกลางคัน)
local farmingSoundGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds")

local SOUND_HEAR_DISTANCE = 70 -- เกินระยะเสียงดังสุด (RollOffMaxDistance 60) ไม่ต้องส่ง

local function playSoundAt(position, soundId, volume)
	-- เดิม (ถึง 2026-10-14) สร้าง Part ล่องหน + Sound ใหม่บนเซิร์ฟทุกครั้ง แล้วส่งให้ทุกคน: ต้นละ 2 ครั้ง (ปลูก/เก็บ)
	-- ตอนนี้ส่งแค่ตำแหน่ง+รหัสเสียงให้ผู้เล่นที่อยู่ใกล้ เครื่องผู้เล่นเล่นเอง (CropSoundClient ใช้กลุ่มเสียง EffectSounds เหมือนเดิม)
	for _, p in ipairs(Players:GetPlayers()) do
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - position).Magnitude <= SOUND_HEAR_DISTANCE then
			cropSound:FireClient(p, position, soundId, volume)
		end
	end
end

-- สร้างระบบ 1 ช่องปลูก (slot) ภายในแปลง
local function createSlot(soil, offset, slotIndex)
	-- จุดยึดช่อง + แผ่นดินเปียก + ป้าย E สร้างตอนปลูกจริงเท่านั้น แล้วลบทิ้งตอนเก็บ/ล้าง
	-- ระยะช่อง 1.5 studs ทำให้ทั้งแมพมีช่องราว 24,000 ช่อง ถ้าสร้างจุดยึดรอไว้ทุกช่อง เครื่องผู้เล่นต้องแบก part เปล่าเท่านั้น
	-- (ตำแหน่งช่องคำนวณจากสูตรใน FarmGridConfig ได้อยู่แล้ว ไม่ต้องมี part จริงวางรอ)
	-- หมุนตามแผ่นดิน + ตั้งบนผิวที่เห็นจริง (หญ้า terrain ที่ปิดแผ่นดินอยู่) ดู FarmGridConfig (แก้ 2026-10-08: เดิม soil.Position + offset แปลงหมุนปลูกล้ำขอบ)
	local surfacePoint = FarmGridConfig.GetSlotSurfacePoint(soil, offset)
	local slotPosition = surfacePoint + Vector3.new(0, 0.5, 0)
	local anchor = nil
	local prompt = nil
	local doHarvest -- ประกาศไว้ก่อน เพราะ createPlantVisuals ต้องผูก prompt.Triggered เข้ากับมัน

	local slot = {
		position = slotPosition, -- กลางช่องในโลก ใช้แทน anchor.Position เดิม (ช่องว่างจะไม่มี anchor แล้ว)
		anchor = nil, -- มีค่าเฉพาะตอนมีต้นปลูกอยู่
		prompt = nil, -- มีค่าเฉพาะตอนมีต้นปลูกอยู่
		generation = 0, -- เพิ่มทุกครั้งที่ปลูกใหม่ กัน growPlant ของต้นเก่าที่ยังรอ task.wait อยู่ ไปเร่งต้นใหม่
		occupied = false,
		cropType = nil,
		quality = nil,
		stage = 0,
		plantedBy = nil, -- ผู้เล่นที่เป็นเจ้าของต้นในช่องนี้ตอนนี้ (ใช้กับระบบจำกัดจำนวนต้น)
		stageModels = {},
	}

	-- จุดยึดช่อง = แผ่นดินเปียกใต้ต้นในชิ้นเดียว (2026-10-14: เดิมแยก 2 ชิ้น จุดยึดล่องหนสูงจากพื้น 0.5 + แผ่นดินเปียก)
	-- ป้าย E สร้างตอนโตครบเท่านั้น (เดิมสร้างตั้งแต่ปลูกแล้วปิดไว้ทั้งรอบ) ดู ensurePrompt
	local function createPlantVisuals()
		-- ที่อยู่ของโมเดลต้น/ป้าย/ออร่า และเป็นตัวบอกฝั่งผู้เล่นว่าช่องนี้ไม่ว่างแล้ว (PlantSlotGuide, TutorialGui ดูจากชื่อ PlantSlotN)
		-- ตำแหน่งอยู่บนผิวดิน ไม่ใช่ slotPosition (สูงกว่า 0.5) — CropAura ชดเชยความสูงให้แล้ว, โมเดลต้นวางจาก slotPosition เอง
		anchor = Instance.new("Part")
		anchor.Name = "PlantSlot" .. slotIndex
		anchor.Size = Vector3.new(GRID_SPACING - 0.4, 0.05, GRID_SPACING - 0.4)
		anchor.Material = Enum.Material.SmoothPlastic
		anchor.Color = Color3.fromRGB(80, 52, 34) -- ดินเปียกสีเข้มกว่าดินแห้งปกติ
		anchor.Transparency = 0.7 -- โปร่งแสงมาก เห็นเนื้อดินเดิมลอดผ่าน
		anchor.CanCollide = false
		anchor.CanQuery = false -- ถ้าเปิดไว้จะบังเมาส์ตรงจุดที่ผู้เล่นเล็งที่สุด
		anchor.CanTouch = false
		anchor.Anchored = true
		anchor.CFrame = CFrame.new(surfacePoint + Vector3.new(0, 0.02, 0)) * soil.CFrame.Rotation
		anchor.Parent = soil
		slot.anchor = anchor
	end

	local function ensurePrompt()
		if prompt or not anchor then return end
		prompt = Instance.new("ProximityPrompt")
		-- หมายเหตุ: ProximityPrompt เป็น Instance เดียวที่ทุกคนเห็นข้อความเดียวกัน (ไม่ใช่ RemoteEvent ที่ส่งแยกคนได้)
		-- เลยยังทำให้แสดงคนละภาษาตามผู้เล่นแต่ละคนไม่ได้ด้วยวิธีนี้ ใช้ภาษาเริ่มต้นของเซิร์ฟเวอร์ไปก่อน (ปรับ DEFAULT_LANG ได้)
		prompt.ActionText = Localization.T("Harvest_ActionText", DEFAULT_LANG)
		local owner = slot.plantedBy
		-- โชว์ชื่อเจ้าของต้นบนป้าย คนอื่นจะรู้ตั้งแต่ก่อนกดว่าเก็บไม่ได้
		if typeof(owner) == "Instance" then
			prompt.ObjectText = Localization.F("Harvest_OwnerObjectText", DEFAULT_LANG, owner.DisplayName)
		else
			prompt.ObjectText = Localization.T("Harvest_ObjectText", DEFAULT_LANG)
		end
		prompt.RequiresLineOfSight = false -- กันต้นไม้บังตัวเองไม่ให้เห็นป้าย E
		-- ไม่ผูก doHarvest ตรงๆ: โปรแกรมโกงยิงป้ายจากไกลได้ ต้องเช็กระยะฝั่งเซิร์ฟเวอร์เอง (2026-10-10 กรณี MRPTXYZ)
		prompt.Triggered:Connect(function(player)
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or (hrp.Position - slotPosition).Magnitude > HARVEST_PROMPT_MAX_DISTANCE then return end
			doHarvest(player)
		end)
		prompt.Parent = anchor
		slot.prompt = prompt
	end

	local function clearCropModels()
		if slot.plantedBy then
			changePlantCount(slot.plantedBy, -1) -- คืนโควต้าให้เจ้าของเดิม
			slot.plantedBy = nil
		end
		slot.stageModels = {}
		if prompt then prompt:Destroy(); prompt = nil end
		slot.prompt = nil

		-- ลบจุดยึด (= แผ่นดินเปียก) ทิ้ง ดินแห้งกลับคืน โมเดลต้นที่อยู่ข้างในหายตามไปด้วย ช่องว่างจึงไม่เหลือ part ค้างไว้เลย
		if anchor then
			clearAura(anchor) -- ถอด tag/attribute ออร่าก่อน เผื่อฝั่งผู้เล่นอ่านค้าง
			anchor:Destroy()
			anchor = nil
		end
		slot.anchor = nil
	end

	-- สร้างโมเดลต้นของสเตจที่ขอ แล้ววางให้โคนต้นแนบพื้นดินพอดี
	-- (โมเดลบางตัวมีจุด Pivot ไม่ได้อยู่โคนต้น เลยต้องเลื่อนตามกล่องขอบเขตแทน จะได้ไม่ลอย/ไม่จม)
	local function buildStageModel(stage)
		local template = slot.cropTemplate and slot.cropTemplate:FindFirstChild("Stage" .. stage)
		if not template or not anchor then return nil end

		local clone = template:Clone()
		clone.Name = "Stage" .. stage

		-- ต้นไม้ต้องไม่บังรังสีเมาส์ ไม่งั้นเล็งปลูกข้างต้นที่มีอยู่แล้วไม่ได้ (ใบแตงโมกว้าง 12 studs บังไป 27 ช่องรอบตัว)
		for _, descendant in ipairs(clone:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
			end
		end

		CollectionService:AddTag(clone, "CropModel") -- CropLod ฝั่งผู้เล่นใช้ลดรายละเอียดต้นที่อยู่ไกล
		clone.Parent = anchor
		clone:PivotTo(CFrame.new(slotPosition)) -- ไม่ใช้ anchor.CFrame: จุดยึดหมุนตามแปลงและอยู่บนผิวดินแล้ว
		bumpStat("StatStageModels")

		local boundsCFrame, boundsSize = clone:GetBoundingBox()
		local bottomY = boundsCFrame.Position.Y - boundsSize.Y / 2
		local groundY = surfacePoint.Y -- ผิวบนจริงตรงช่องนี้; slotPosition อยู่สูงกว่าพื้น 0.5 studs สำหรับจุดยึด
		-- Attribute SinkBelowGround (studs): ฝังโมเดลลงดิน ใช้กับพืชหัว เช่นแครอท (2026-11-04)
		local sink = tonumber(clone:GetAttribute("SinkBelowGround")) or 0
		clone:PivotTo(clone:GetPivot() + Vector3.new(0, groundY - bottomY - sink, 0))

		return clone
	end

	-- เก็บไว้เฉพาะสเตจที่กำลังแสดง สเตจเก่าลบทิ้ง
	-- เดิมโคนไว้ครบทั้ง 5 สเตจตั้งแต่ตอนปลูก แล้วซ่อนไว้ 4 สเตจ — เปลือง part และเน็ตเวิร์กราว 5 เท่า
	local function setStage(stage)
		slot.stage = stage
		local visual = VISUAL_STAGE[stage] or stage -- โมเดลที่แสดง (สเตจ 2/4 ใช้ตัวเดิมต่อ)

		for i, model in pairs(slot.stageModels) do
			if i ~= visual then
				model:Destroy()
				slot.stageModels[i] = nil
			end
		end
		if not slot.stageModels[visual] then
			slot.stageModels[visual] = buildStageModel(visual)
		end

		if stage == 5 then
			ensurePrompt()
			if not prompt then return end
			prompt.Enabled = true
			prompt.ActionText = Localization.T("Harvest_ActionText", DEFAULT_LANG)
			prompt.HoldDuration = 1
			if debugOn() then
				print("🔍 [DEBUG] " .. anchor.Name .. " โตครบแล้ว prompt.Enabled = " .. tostring(prompt.Enabled) .. " | ตำแหน่ง: " .. tostring(anchor.Position))
			end
		elseif prompt then
			prompt.Enabled = false
		end
	end

	-- โตครบแล้วไม่มีใครเก็บเกิน AUTO_HARVEST_DELAY → เก็บเข้ากระเป๋าเจ้าของให้เอง
	-- เช็ค generation กันเคสที่ต้นเดิมถูกเก็บ/ล้าง แล้วมีต้นใหม่มาแทนในช่องเดียวกันระหว่างรอ
	local function scheduleAutoHarvest(myGeneration)
		local owner = slot.plantedBy
		if typeof(owner) ~= "Instance" then return end

		task.delay(AUTO_HARVEST_DELAY, function()
			if not slot.occupied or slot.generation ~= myGeneration then return end -- ต้นนี้ไม่อยู่แล้ว
			if slot.stage ~= 5 then return end
			if slot.plantedBy ~= owner or not owner.Parent then return end -- เจ้าของออกจากเกมไปแล้ว (PlayerRemoving จัดการเองอยู่)

			doHarvest(owner)
		end)
	end

	-- ช่องนี้อยู่ในรัศมี "หุ่นฟาง" (x50) ที่ owner ปักเองไหม (หุ่นทองคำ/หุ่นของคนอื่นไม่นับ กติกาเดียวกับผลผลิต x1.5 ของผีน้อยใน doHarvest)
	local function inOwnStrawRadius(owner)
		local folder = workspace:FindFirstChild("QualityBoosters")
		for _, model in ipairs(folder and folder:GetChildren() or {}) do
			if model:IsA("Model") and model:GetAttribute("OwnerUserId") == owner.UserId
				and (model:GetAttribute("BoosterTier") or LuckConfig.DEFAULT_BOOSTER_TIER) == "x50"
				and (model:GetPivot().Position - slotPosition).Magnitude <= (model:GetAttribute("BoostRadius") or LuckConfig.DEFAULT_BOOSTER_RADIUS) then
				return true
			end
		end
		return false
	end

	local function growPlant(myGeneration)
		local durations = STAGE_DURATION_BY_CROP[slot.cropType] or DEFAULT_STAGE_DURATION
		for stage = 1, 4 do
			-- โตเร็วขึ้น: ฝนตก (WeatherConfig.RAIN_GROW_MULT) + มังกรสุลต่านของคนปลูก (Attribute PetGrowBoost) คิดตอนเริ่มแต่ละช่วง
			-- (เดิมโหลด WeatherConfig ไว้แต่ไม่ได้ใช้ ป้ายฝนบอก "พืชโต +25%" แต่ไม่เคยโตเร็วขึ้นจริง)
			local growMult = WeatherConfig.IsRaining() and WeatherConfig.RAIN_GROW_MULT or 1
			local owner = slot.plantedBy
			if typeof(owner) == "Instance" and owner.Parent then
				growMult *= 1 - math.clamp(tonumber(owner:GetAttribute("PetGrowBoost")) or 0, 0, 0.5)
				-- ผีน้อยนักปักหุ่น (2026-10-15 ผู้ใช้ขอ): พาออกมาอยู่ + ต้นอยู่ในรัศมีหุ่นฟางของเจ้าของ = ช่วงนี้โตเร็วขึ้น (PetStrawGrowBoost 0.1 = เวลา -10%) คิดตอนเริ่มแต่ละช่วง
				local strawGrow = tonumber(owner:GetAttribute("PetStrawGrowBoost")) or 0
				if strawGrow > 0 and inOwnStrawRadius(owner) then
					growMult *= 1 - math.clamp(strawGrow, 0, 0.5)
				end
				-- สมุดพืช ขั้นเงินขึ้นไปของพืชชนิดนี้ = เวลาโต -5% (2026-10-30)
				local bookGrow = tonumber(owner:GetAttribute(CropBookConfig.AttrGrow(slot.cropType))) or 0
				if bookGrow > 0 then growMult *= 1 - math.clamp(bookGrow, 0, 0.5) end
			end
			task.wait(durations[stage] * growMult)
			-- ถูกเก็บเกี่ยว/ล้างไปแล้วระหว่างรอ หรือถูกปลูกต้นใหม่แทนแล้ว (ต้นใหม่มี growPlant ของตัวเอง)
			if not slot.occupied or slot.generation ~= myGeneration then return end
			if stage == 4 then
				setStage(5)
				attachAura(anchor, slot.quality or 1)
				if prompt then
					prompt.ActionText = Localization.T("Harvest_ActionText", DEFAULT_LANG) .. " " .. string.rep("⭐", slot.quality or 1)
				end
				scheduleAutoHarvest(myGeneration)
			else
				setStage(stage + 1)
			end
		end
	end

	local function plantCrop(cropName, plantingPlayer)
		local cropTemplate = cropTemplates:FindFirstChild(cropName)
		if not cropTemplate then return end

		clearCropModels() -- ล้างต้นเดิม (ถ้ามีเจ้าของเดิมอยู่ จะคืนโควต้าให้เจ้าของเดิมอัตโนมัติ)
		slot.generation += 1
		slot.occupied = true
		slot.cropType = cropName
		slot.cropTemplate = cropTemplate -- setStage ใช้โคนสเตจถัดไปตอนโต
		slot.plantedBy = plantingPlayer
		slot.pollinated = nil -- ผึ้งราชินีปลูกแล้วผสมเกสรติด ตั้งใหม่หลังเรียกฟังก์ชันนี้ (Abilities.Planter)
		changePlantCount(plantingPlayer, 1)
		-- จำนวนต้นที่กำลังปลูกอาจไม่เปลี่ยนเมื่อปลูกทับช่องเดิม จึงนับการปลูกสำเร็จแยกให้เควสใช้ตรวจ
		if plantingPlayer then
			plantingPlayer:SetAttribute("PlantActionCount", (tonumber(plantingPlayer:GetAttribute("PlantActionCount")) or 0) + 1)
			pcall(Achievement.Add, plantingPlayer, "plant", 1) -- สัตว์ปลูกให้ก็นับ พังก็ไม่ให้การปลูกพัง
		end
		-- สุลต่านการันตีคุณภาพต้นขั้นต่ำตาม MIN_PLANT_QUALITY (สุ่มได้ต่ำกว่า = ยกขึ้น) ใช้กับสัตว์เลี้ยงช่วยปลูกด้วย เพราะนับตามเจ้าของ
		local plantLuck = LuckSystem.GetLuck(plantingPlayer, slotPosition)
		slot.quality = math.max(SultanConfig.MinPlantQuality(plantingPlayer), rollPlantQuality(plantLuck))
		slot.luck = plantLuck -- ใช้สุ่มกลายพันธุ์ตอนเก็บ (2026-10-30)
		createPlantVisuals() -- จุดยึด/แผ่นดินเปียก (ป้าย E สร้างตอนโตครบ)
		bumpStat("StatPlanted")

		-- จำเจ้าของต้นนี้ไว้ที่ช่องปลูก ใช้เช็คตอนเก็บเกี่ยว และเผื่อให้ฝั่งผู้เล่นเอาไปทำ UI ต่อ
		anchor:SetAttribute("OwnerUserId", plantingPlayer and plantingPlayer.UserId or nil)
		anchor:SetAttribute(CropAuraConfig.CropAttribute, cropName)


		playSoundAt(slotPosition, PLANT_SOUND_ID, PLANT_SOUND_VOLUME)

		setStage(1)
		task.spawn(growPlant, slot.generation)
	end

	-- yieldMultiplier: ตัวคูณผลผลิต ผู้เล่นกดเก็บเองไม่ส่งมา = 1 ส่วนสัตว์เลี้ยงบางตัวส่งมา (เช่น จิ้งจอกเก้าหาง = 2)
	-- silent = true: ไม่เล่นเสียงเก็บเกี่ยว (ใช้ตอนผู้เล่นออกเกม เก็บทุกต้นพร้อมกัน เดิมเสียงซ้อนกันหลายสิบเสียงดังมากสำหรับคนที่อยู่ใกล้ 2026-10-19)
	-- bonusItems: ผลผลิตแถมเป็นชิ้น บวกหลังคิดตัวคูณ ต้นที่ไม่ได้ผลผลิตเลย (ดินทรายสุ่มได้ 0) ไม่แถม
	-- ต้นที่ผึ้งราชินีปลูกแล้วผสมเกสรติด (slot.pollinated, 2026-10-29 ย้ายจากตอนเก็บมาตอนปลูก) = แถมเพิ่ม 1 ไม่ว่าใครเก็บ
	function doHarvest(player, yieldMultiplier, silent, bonusItems)
		if not slot.occupied then return end
		-- เก็บได้เฉพาะต้นที่โตครบแล้ว (เดิมไม่เช็ก: ยิงป้ายที่ปิดอยู่ = ปลูกแล้วเก็บทันทีวนปั๊ม XP/ผลผลิตได้ไม่จำกัด)
		if slot.stage ~= 5 then return end

		-- เก็บได้เฉพาะต้นที่ตัวเองปลูก (สัตว์เลี้ยงช่วยเก็บก็ส่งเจ้าของมาเหมือนกัน จึงผ่านด่านนี้ปกติ)
		-- ดูจาก Attribute บน anchor ไม่ใช่ตัวแปร slot.plantedBy เฉยๆ เพราะฝั่งผู้เล่นอ่านค่านี้ไปทำ UI ต่อได้ (คนแก้ไม่ได้ เพราะเซิร์ฟเวอร์เป็นคนตั้ง)
		local ownerUserId = anchor:GetAttribute("OwnerUserId")
		if ownerUserId and ownerUserId ~= player.UserId then
			local lang = Localization.GetLanguage(player)
			local owner = Players:GetPlayerByUserId(ownerUserId)
			harvestNotify:FireClient(player, nil, nil, nil,
				Localization.F("Harvest_NotYours", lang, owner and owner.DisplayName or Localization.T("Harvest_OtherPlayer", lang)))
			return
		end

		local plantedStar = slot.quality or 1
		local multiplier = (type(yieldMultiplier) == "number" and yieldMultiplier >= 1) and math.floor(yieldMultiplier) or 1
		-- ผีน้อยนักปักหุ่น (2026-10-11): เจ้าของพาผีน้อยออกมา (Attribute PetStrawYieldBonus จาก PetController) และต้นนี้อยู่ในรัศมี "หุ่นฟาง" ที่เจ้าของปักเอง
		-- = ผลผลิต x(1 + โบนัส) เช่น x1.5 ไม่ว่าใครเก็บ (เจ้าของเก็บเอง/สัตว์เลี้ยงเก็บให้) หุ่นทองคำและหุ่นของคนอื่นไม่นับ
		-- ไม่คูณซ้อนกับตัวคูณของสัตว์ที่เก็บ (เช่น จิ้งจอกเก้าหาง x2): ใช้ตัวที่มากกว่าตัวเดียว
		local effectiveMultiplier = multiplier
		local strawBonus = tonumber(player:GetAttribute("PetStrawYieldBonus")) or 0
		if strawBonus > 0 and 1 + strawBonus > multiplier then
			local folder = workspace:FindFirstChild("QualityBoosters")
			for _, model in ipairs(folder and folder:GetChildren() or {}) do
				if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId
					and (model:GetAttribute("BoosterTier") or LuckConfig.DEFAULT_BOOSTER_TIER) == "x50"
					and (model:GetPivot().Position - slotPosition).Magnitude <= (model:GetAttribute("BoostRadius") or LuckConfig.DEFAULT_BOOSTER_RADIUS) then
					effectiveMultiplier = 1 + strawBonus
					break
				end
			end
		end
		-- ตัวคูณที่มีเศษ (x1.5): ส่วนเศษสุ่มปัดขึ้น เช่น ผลผลิต 1 x1.5 = ได้ 1 หรือ 2 อย่างละครึ่ง (เฉลี่ย 1.5) ตัวคูณเต็ม (x1, x2) ได้เท่าเดิม
		-- ตัวคูณผลผลิตของแปลง (2026-10-12 ผู้เล่นขอ: แปลงหาดทรายได้ผลผลิตครึ่งเดียว): Attribute "YieldMult" บนโมเดลแปลง (หรือบนแผ่น Soil) ไม่ตั้ง = 1
		-- แปลงหาด FarmPlot55-62 ตั้งไว้ 0.8 (ลด 20% เดิม 0.5) · ส่วนเศษสุ่มปัดขึ้นเหมือนตัวคูณอื่น (ผลผลิต 1 x0.5 = ได้ 0 หรือ 1 อย่างละครึ่ง)
		local plotModel = soil.Parent
		local plotYield = tonumber(soil:GetAttribute("YieldMult")) or tonumber(plotModel and plotModel:GetAttribute("YieldMult")) or 1
		plotYield = math.clamp(plotYield, 0, 10)
		local rawYield = (STAR_CONFIG[plantedStar] or STAR_CONFIG[1]).Yield * effectiveMultiplier * plotYield
		local yieldAmount = math.floor(rawYield)
		if math.random() < rawYield - yieldAmount then yieldAmount += 1 end
		if slot.pollinated then
			bonusItems = (type(bonusItems) == "number" and bonusItems or 0) + 1
			slot.pollinated = nil
		end
		if yieldAmount > 0 and type(bonusItems) == "number" and bonusItems >= 1 then
			yieldAmount += math.min(math.floor(bonusItems), 5)
		end
		-- สุลต่านการันตีดาวผลผลิตขั้นต่ำเหมือนกัน (เดิมการันตีแค่คุณภาพต้น แต่ตอนเก็บยังสุ่มร่วงเป็น 1-2 ดาวได้)
		local harvestStar = math.max(SultanConfig.MinProduceStar(player), rollHarvestStar(plantedStar))
		local cropType = slot.cropType
		-- สมุดพืช ขั้นทองขึ้นไป = โอกาส 10% ดาวผลผลิต +1 (ไม่เกิน ★5) 2026-10-30
		local bookStar = tonumber(player:GetAttribute(CropBookConfig.AttrStar(cropType))) or 0
		if harvestStar < 5 and bookStar > 0 and math.random() < bookStar then harvestStar += 1 end

		local cropStats = player:FindFirstChild("CropStats")
		if cropStats then
			local statName = CROP_STAT_NAME[cropType]
			local stat = statName and cropStats:FindFirstChild(statName)
			if stat then stat.Value += yieldAmount end
		end

		if yieldAmount > 0 then
			-- กลายพันธุ์ทั้งต้น (ระบบปิด = ไม่สุ่ม)
			local mutation = MutationConfig.IsEnabled() and MutationConfig.Roll(WeatherConfig.IsRaining(), slot.luck or 0) or nil
			pcall(CropBook.Record, player, cropType, harvestStar, yieldAmount, mutation)
			if mutation == "Giant" then
				-- แยกเธรด เพราะอ่านอันดับจาก DataStore อาจรอ ไม่ให้การเก็บเกี่ยวช้าตาม
				task.spawn(pcall, CropContest.OnGiant, player, cropType, harvestStar)
			end
			giveProduceTool(player, cropType, harvestStar, yieldAmount, mutation)
			harvestNotify:FireClient(player, cropType, harvestStar, yieldAmount)
			if mutation then
				local lang = Localization.GetLanguage(player)
				local name = MutationConfig.Label(mutation, lang) .. " " .. Localization.T("Crop_" .. cropType, lang)
				-- ฉ่ำฝน (ออกบ่อยตอนฝนตก) แจ้งไม่เกิน 1 ครั้งต่อ 30 วิ แบบอื่นแจ้งทุกครั้ง
				local noticeNow = os.clock()
				local quietWet = mutation == "Wet" and noticeNow - (player:GetAttribute("WetNoticeAt") or -math.huge) < 30
				if mutation == "Wet" and not quietWet then player:SetAttribute("WetNoticeAt", noticeNow) end
				if not quietWet then harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(lang,
					string.format("✨ กลายพันธุ์! %s %s x%d (ขายได้ x%d)", name, string.rep("★", harvestStar), yieldAmount, MutationConfig.Mult(mutation)),
					string.format("✨ Mutation! %s %s x%d (sells x%d)", name, string.rep("★", harvestStar), yieldAmount, MutationConfig.Mult(mutation)))) end
				local mdef = MutationConfig.Get(mutation)
				-- ประกาศทั้งเซิร์ฟ (รุ้ง) คนละ 1 ครั้งต่อ ANNOUNCE_COOLDOWN วิ กันสัตว์เก็บฟาร์มใหญ่แล้วประกาศรัว (ครั้งอื่นได้แค่แจ้งเตือนของตัวเอง)
				local now = os.clock()
				if mdef.announce and now - (player:GetAttribute("MutationAnnouncedAt") or -math.huge) >= MUTATION_ANNOUNCE_COOLDOWN then
					player:SetAttribute("MutationAnnouncedAt", now)
					local announce = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GachaAnnounce")
					if announce then
						announce:FireAllClients({ UserId = player.UserId, Name = player.DisplayName, PetName = name, Rarity = "Secret", Kind = "Crop", Detail = string.rep("★", harvestStar) })
					end
				end
				print(string.format("✨ Mutation: %s ได้ %s %s ★%d x%d", player.Name, mutation, cropType, harvestStar, yieldAmount))
			end
		else
			-- ตัวคูณแปลงต่ำ (หาดทราย) สุ่มแล้วไม่ได้ผลผลิต: ไม่สร้างของ 0 ชิ้น แจ้งเหตุผลแทน
			harvestNotify:FireClient(player, nil, nil, nil, Localization.GetLanguage(player) == "en"
				and "🏖️ Sandy soil gives a smaller harvest: nothing from this plant"
				or "🏖️ ดินทรายได้ผลผลิตน้อยลง ต้นนี้ไม่ได้ผลผลิต")
		end
		LevelSystem.AddXP(player, harvestStar * XP_PER_STAR)

		-- เสียงเก็บเกี่ยวเล่นบน part ชั่วคราว ไม่ฝากไว้กับจุดยึด
		-- (จุดยึดโดนลบทันทีหลังเก็บ ถ้าฝากไว้กับมันเสียงจะขาดกลางคัน)
		if not silent then playSoundAt(slotPosition, HARVEST_SOUND_ID, 0.6) end
		bumpStat("StatHarvested")

		if debugOn() then
			print(player.Name .. " เก็บเกี่ยว " .. cropType .. " (ปลูกได้ " .. plantedStar
				.. " ดาว) ได้ผลผลิตคุณภาพ " .. harvestStar .. " ดาว จำนวน " .. yieldAmount .. " ผล")
		end

		clearCropModels()
		slot.occupied = false
		slot.cropType = nil
		slot.quality = nil
	end

	slot.plantCrop = plantCrop
	slot.harvest = doHarvest -- เปิดให้เรียกเก็บเกี่ยวจากที่อื่นได้ด้วย (เช่น ตอนผู้เล่นออกจากเกมทั้งที่ต้นโตเต็มที่แล้ว)
	slot.clearCropModels = clearCropModels -- เปิดให้ล้างต้นจากที่อื่นได้ด้วย (เช่น คืนเมล็ดตอนออกจากเกมทั้งที่ต้นยังไม่โต)
	return slot
end

-- ตั้งค่าดิน 1 แผ่น (แปลงปกติมีแผ่นเดียว ส่วนนาขั้นบันไดมีหลายแผ่น แต่ละขั้นชื่อ "Soil" เหมือนกัน)
local function setupSoil(plotModel, soil)
	if debugOn() then
		print("🔍 [DEBUG] setupFarmPlot เริ่มทำงานกับ: " .. plotModel:GetFullName())
		print("🔍 [DEBUG] soil.Size = " .. tostring(soil.Size))
	end
	-- ล็อก Anchored และขนาดตั้งต้นไว้ กันฟิสิกส์/สคริปต์อื่นมาแก้ Soil.Size ทีหลัง
	-- (แก้ปัญหาความสูงแปลงเพี้ยนตอน Play เทียบกับตอนวางใน Studio)
	soil.Anchored = true
	if not soil:GetAttribute("BaselineSize") then
		soil:SetAttribute("BaselineSizeX", soil.Size.X)
		soil:SetAttribute("BaselineSizeY", soil.Size.Y)
		soil:SetAttribute("BaselineSizeZ", soil.Size.Z)
		soil:SetAttribute("BaselineSize", true)
	end

	-- ปิด PlantPrompt เดิมของ Soil ถาวร (ไม่ใช้แล้ว แทนที่ด้วยระบบหลายช่องปลูก)
	local oldPrompt = soil:FindFirstChild("PlantPrompt")
	if oldPrompt then oldPrompt.Enabled = false end

	local offsets = FarmGridConfig.ComputeSlotOffsets(soil)
	if debugOn() then print("🔍 [DEBUG] จำนวน offsets ที่คำนวณได้: " .. #offsets) end

	local slots = {}
	-- (เอา print ต่อช่องออก เพราะช่องมีเป็นหลายหมื่น print ทีละช่องทำเซิร์ฟเวอร์ค้างตอนเริ่มเกม)
	for i, offset in ipairs(offsets) do
		-- แผ่นดินวงกลม (Attribute Round, 2026-11-09 FarmPlot5): ไม่สร้างช่องนอกวง คนและสัตว์เลี้ยงจึงปลูกตรงมุมสี่เหลี่ยมไม่ได้
		-- เลขช่อง i ยังตามตารางเต็ม (ชื่อ PlantSlot<i> ตรงกับ FarmGridConfig.GetNearestSlot ฝั่งผู้เล่น) ส่วน slots เก็บเฉพาะช่องที่ใช้ได้ เรียงต่อกัน
		if FarmGridConfig.IsOffsetUsable(soil, offset) then
			local slot = createSlot(soil, offset, i)
			slots[#slots + 1] = slot
			table.insert(allSlots, slot)
		end
	end
	if debugOn() then print("🔍 [DEBUG] setupFarmPlot เสร็จสิ้น มี slots ทั้งหมด: " .. #slots) end

	-- ลองปลูก: ปลูกตรงจุดที่คลิกจริง (ช่องใกล้จุดคลิกที่สุด) ทับของเดิมได้เลย
	local function tryPlant(player, clickPosition)
		local lang = Localization.GetLanguage(player)
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")

		if not tool then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.T("Plant_NeedSeed", lang))
			return
		end

		if tool:GetAttribute("IsProduce") then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.T("Plant_IsProduceNotSeed", lang))
			return
		end

		local cropType = tool:GetAttribute("CropType")
		if not cropType or not cropTemplates:FindFirstChild(cropType) then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.T("Plant_CantPlantThis", lang))
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- เช็คระยะจากจุดที่คลิกจริง ไม่ใช่จุดศูนย์กลางแปลง (แก้บั๊ก: แปลงใหญ่ยืนตรงขอบ/มุมไกลๆ
		-- จะห่างจากจุดศูนย์กลางเกิน MAX_PLANT_DISTANCE ทั้งที่ยืนอยู่บนดินจริงๆ ทำให้ปลูกไม่ได้แบบไม่มีสาเหตุ)
		local targetPosition = (typeof(clickPosition) == "Vector3") and clickPosition or soil.Position
		-- ปลูกได้เฉพาะในกรอบแปลง (คิดตามการหมุนของแผ่นดิน) คลิกนอกกรอบไม่ปลูก
		if not FarmGridConfig.IsInsideSoil(soil, targetPosition, GRID_SPACING / 2) then return end
		if (hrp.Position - targetPosition).Magnitude > MAX_PLANT_DISTANCE then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.T("Plant_TooFar", lang))
			return
		end

		-- หาช่องปลูกที่อยู่ใกล้จุดที่คลิกที่สุด (ไม่สนว่ามีต้นอยู่แล้วหรือไม่)
		local closestSlot = nil
		local closestDistance = math.huge

		for _, slot in ipairs(slots) do
			local distance = (slot.position - targetPosition).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestSlot = slot
			end
		end

		if not closestSlot then return end

		-- ห้ามปลูกทับจุดที่มีต้นอยู่แล้ว (กันเผลอคลิกจุดเดิมซ้ำๆ แล้วเสียเมล็ดฟรีโดยได้ต้นแค่ 1 ต้นเท่าเดิม)
		if closestSlot.occupied then
			harvestNotify:FireClient(player, nil, nil, nil, Localization.T("Plant_SlotOccupied", lang))
			return
		end

		-- เช็คโควต้าจำนวนต้นก่อนปลูก
		do
			local limit = getPlantLimit(player)
			local current = getPlayerPlantCount(player)
			if current >= limit then
				harvestNotify:FireClient(player, nil, nil, nil,
					Localization.F("Plant_LimitReached", lang, limit))
				return
			end
		end

		closestSlot.plantCrop(cropType, player)

		local currentCount = tool:GetAttribute("Count") or 1
		if currentCount <= 1 then
			tool:Destroy()
		else
			local newCount = currentCount - 1
			tool:SetAttribute("Count", newCount)
			tool.Name = cropType .. " x" .. newCount
		end
	end

	soilToTryPlant[soil] = tryPlant
end

-- ทุกแผ่นที่ชื่อ Soil ในแปลงนี้ (ช่องปลูก/ปลูกด้วยคลิก แยกตามแผ่นอยู่แล้วผ่าน soilToTryPlant)
local function setupFarmPlot(plotModel)
	for _, child in ipairs(plotModel:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Soil" then
			setupSoil(plotModel, child)
		end
	end
end

local plotCount = 0
for _, plotModel in ipairs(farmPlots:GetChildren()) do
	-- ข้าม FarmPlotTemplate (แม่แบบ ไม่ใช่แปลงจริง) ไม่ให้ถูกนับเป็นแปลงปลูก
	if plotModel:IsA("Model") and plotModel.Name ~= "FarmPlotTemplate" and plotModel:FindFirstChild("Soil") then
		setupFarmPlot(plotModel)
		plotCount += 1
	end
end

print("เปิดใช้งานแปลงดินทั้งหมด " .. plotCount .. " แปลง")

plantByClick.OnServerEvent:Connect(function(player, targetSoil, clickPosition)
	if typeof(targetSoil) ~= "Instance" then return end
	local tryPlant = soilToTryPlant[targetSoil]
	if tryPlant then
		tryPlant(player, clickPosition)
	end
end)

-- ผู้เล่นออกจากเกม: เคลียร์ต้นทั้งหมดที่เขาปลูกทิ้งไว้ กันเสียของเปล่าๆ
-- โตเต็มที่แล้ว → เก็บเกี่ยวให้อัตโนมัติเลย (เหมือนกดเก็บเอง)
-- ยังไม่โตเต็มที่ → คืนเงินค่าเมล็ดให้แทน (คืนเป็นเงินเพราะเงินเซฟถาวร ส่วนเมล็ด/ผลผลิตยังไม่ได้เซฟ)
Players.PlayerRemoving:Connect(function(player)
	for _, slot in ipairs(allSlots) do
		if slot.occupied and slot.plantedBy == player then
			-- แยกทีละต้นด้วย pcall (2026-10-14): เดิมถ้าต้นหนึ่ง error ลูปหยุด ต้นที่เหลือของคนนี้ค้างในแมพตลอดอายุเซิร์ฟ
			local ok, err = pcall(function()
				if slot.stage == 5 then
					slot.harvest(player, nil, true) -- เก็บเงียบ: ไม่ส่งเสียงเก็บเกี่ยวทุกต้นพร้อมกันให้คนรอบๆ
				else
					local refund = SEED_PRICE[slot.cropType] or 0
					local leaderstats = player:FindFirstChild("leaderstats")
					local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
					if coins and refund > 0 then
						coins.Value += refund
					end
				end
			end)
			if not ok then warn("PlantingSystem: เก็บ/คืนต้นตอนออกเกมไม่สำเร็จ: " .. tostring(err)) end
			-- ล้างให้แน่ทุกกรณี (เก็บสำเร็จแล้วช่องว่างอยู่แล้ว = ไม่ทำอะไร)
			if slot.occupied and slot.plantedBy == player then
				pcall(slot.clearCropModels)
				slot.occupied = false
				slot.cropType = nil
				slot.quality = nil
			end
		end
	end
end)