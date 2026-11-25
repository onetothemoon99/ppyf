-- BACKUP of ServerScriptService.GachaService before Thai/English world signs (i18n phase 4, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.GachaService.Source in Studio
-- GachaService: ตู้สุ่มสัตว์เลี้ยง (ฝั่งเซิร์ฟเวอร์ทั้งหมด)
--   - ตั๋ว 2 แบบ: Normal (ซื้อด้วยเหรียญ) / Premium (ซื้อด้วย Robux ผ่าน PurchaseRouter) อัตราออกต่างกัน ดู ReplicatedStorage.GachaConfig
--   - การสุ่มทำที่นี่เท่านั้น ฝั่งผู้เล่นแค่ "ขอสุ่ม" ห้ามส่งผลลัพธ์มาเอง
--   - ต้องหักตั๋วสำเร็จก่อนถึงจะสุ่ม ให้สัตว์ไม่สำเร็จ = คืนตั๋ว (ผู้เล่นไม่เสียของฟรี)
--   - ได้ตัวซ้ำ: +1 เลเวลทันที (PetOwnership) เลเวลเต็มแล้วเป็นเศษวิญญาณ (แท็บ 💠 ในหน้าต่างตู้ไว้ใช้เศษแลกตัว)
--     เศษวิญญาณแลกสัตว์ที่อยู่ในตู้ตอนนี้ได้ (ตัวลับเฉพาะช่วงอีเวนต์) ค่าต่างๆ ดู ReplicatedStorage.PetLevelConfig
--   - ระดับลับออกเฉพาะช่วงอีเวนต์ (GachaConfig.Events) ตู้สลับเรตเองตามเวลา
--   - การันตี (pity) นับแยกตามแบบตั๋ว เก็บพร้อมตั๋วใน GachaTickets
--   - ประกาศ: ได้ตำนานขึ้นไป = ทุกคนในเซิร์ฟเวอร์เห็น (แบนเนอร์ + แชท), ได้ลับ = ประกาศทุกเซิร์ฟเวอร์ (GachaAnnouncer ฝั่งผู้เล่น)
--   - ประเทศที่ Roblox ห้ามการสุ่มแบบจ่ายเงิน (PolicyService) ซื้อ/ใช้ตั๋วพรีเมียมไม่ได้

local dprint = require(game:GetService("ReplicatedStorage"):WaitForChild("DevLog")) -- per-action logs: Studio only / DevLog attr (2026-11-21)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PolicyService = game:GetService("PolicyService")

local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig"))
local PetRarity = require(ReplicatedStorage:WaitForChild("PetRarity"))
local PetLevelConfig = require(ReplicatedStorage:WaitForChild("PetLevelConfig"))
local PetSystem = ServerScriptService:WaitForChild("PetSystem")
local PetDefinitions = require(PetSystem:WaitForChild("PetDefinitions"))
local PetOwnership = require(PetSystem:WaitForChild("PetOwnership"))
local PetController = require(PetSystem:WaitForChild("PetController"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch")) -- จดผู้เล่นที่ซื้อตั๋ว/ได้ตัวลับมากผิดปกติ
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
-- ข้อความถึงผู้เล่น ไทย/อังกฤษ ตามภาษาของผู้เล่น (2026-11-23)
local function L(player, th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end
local TextEn = require(ServerScriptService:WaitForChild("TextEn")) -- ข้อความจาก PetOwnership (ตัวซ้ำ/เศษ) แปลตอนส่งกลับ
local TICKET_EN = { Normal = "Normal Ticket", Premium = "Premium Ticket" }
local function ticketName(player, typeId, ticketType)
	return L(player, ticketType.DisplayName, ticketType.DisplayNameEn or TICKET_EN[typeId] or ticketType.DisplayName)
end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local gachaRequest = remoteEvents:FindFirstChild("GachaRequest")
if not gachaRequest then
	gachaRequest = Instance.new("RemoteFunction")
	gachaRequest.Name = "GachaRequest"
	gachaRequest.Parent = remoteEvents
end
local gachaAnnounce = remoteEvents:FindFirstChild("GachaAnnounce")
if not gachaAnnounce then
	gachaAnnounce = Instance.new("RemoteEvent")
	gachaAnnounce.Name = "GachaAnnounce"
	gachaAnnounce.Parent = remoteEvents
end
local gachaOpen = remoteEvents:FindFirstChild("GachaOpen")
if not gachaOpen then
	gachaOpen = Instance.new("RemoteEvent")
	gachaOpen.Name = "GachaOpen"
	gachaOpen.Parent = remoteEvents
end

local rng = Random.new()

-- ============ ตู้: สัตว์แต่ละระดับ + อัตราออกจริง (ขึ้นกับว่าอยู่ในช่วงอีเวนต์ไหม) ============
local EVENT_RARITY = GachaConfig.EVENT_RARITY

local function buildState(event)
	local pool = {}
	for petId, def in pairs(PetDefinitions) do
		local rarityId = def.Rarity or PetRarity.DEFAULT
		local inPool = not def.NotInGacha -- สัตว์รางวัล (เช่น นากจากสมุดปลา) ไม่อยู่ในตู้
		if inPool and rarityId == EVENT_RARITY and not def.AlwaysInGacha then -- สัตว์ลับ: อยู่ในตู้เฉพาะช่วงอีเวนต์ที่มีมัน (AlwaysInGacha = อยู่ตลอด 2026-11-01)
			inPool = event ~= nil and (event.SecretPets == nil or table.find(event.SecretPets, petId) ~= nil)
		end
		if inPool then
			pool[rarityId] = pool[rarityId] or {}
			table.insert(pool[rarityId], petId)
		end
	end
	for _, list in pairs(pool) do table.sort(list) end
	-- ตัดระดับที่ไม่มีสัตว์แล้วเฉลี่ยใหม่ (ผู้เล่นไม่เสียตั๋วฟรี)
	local odds = {}
	for typeId, ticketType in pairs(GachaConfig.TicketTypes) do
		-- มีสัตว์ลับในตู้ (อีเวนต์ หรือตัว AlwaysInGacha) = ใช้เรตที่มีลับ
		local hasSecret = pool[EVENT_RARITY] ~= nil and #pool[EVENT_RARITY] > 0
		local source = ((event or hasSecret) and ticketType.EventOdds) or ticketType.Odds
		local o, total = {}, 0
		for rarityId, pct in pairs(source) do
			if pool[rarityId] and #pool[rarityId] > 0 and pct > 0 then
				o[rarityId] = pct
				total += pct
			end
		end
		for rarityId, pct in pairs(o) do o[rarityId] = pct / total * 100 end
		odds[typeId] = o
	end
	return { event = event, pool = pool, odds = odds }
end

local state = buildState(GachaConfig.GetActiveEvent())
local stateChanged = Instance.new("BindableEvent")

-- เช็กทุกครั้งที่ใช้ + วนเช็กเป็นระยะ อีเวนต์เริ่ม/จบกลางเซิร์ฟเวอร์ก็สลับเรตทันที
local function currentState()
	local event = GachaConfig.GetActiveEvent()
	if (event and event.Id) ~= (state.event and state.event.Id) then
		state = buildState(event)
		print("🎰 Gacha: " .. (event and ("เริ่มอีเวนต์ " .. event.Name) or "อีเวนต์จบแล้ว ตู้กลับเป็นเรตปกติ"))
		stateChanged:Fire()
	end
	return state
end
task.spawn(function()
	while true do
		task.wait(15)
		currentState()
	end
end)

local function tierOrder(rarityId) return PetRarity.Get(rarityId).Order end
local ORDER_RARE, ORDER_LEGENDARY = tierOrder("Rare"), tierOrder("Legendary")

-- เรียงจากหายากไปธรรมดา ให้ผลคงที่ (ไม่ขึ้นกับลำดับของ pairs)
local function sortedTiers(odds)
	local order = {}
	for rarityId in pairs(odds) do table.insert(order, rarityId) end
	table.sort(order, function(a, b) return tierOrder(a) > tierOrder(b) end)
	return order
end

local function naturalTier(odds, r)
	local x = r:NextNumber(0, 100)
	local acc = 0
	local order = sortedTiers(odds)
	for _, rarityId in ipairs(order) do
		acc += odds[rarityId]
		if x < acc then return rarityId end
	end
	return order[#order]
end

-- สุ่มระดับ 1 ครั้ง + การันตี pity (ตารางตัวนับ แก้ในนี้เลย)
--   ลับ: ครั้งที่ครบกำหนดได้ลับแน่นอน (เฉพาะช่วงอีเวนต์ ตัวนับไม่เดินนอกอีเวนต์ จึงสะสมข้ามอีเวนต์)
--   ตำนาน: ครั้งที่ครบกำหนด ถ้าสุ่มได้ต่ำกว่าตำนาน ยกเป็นตำนาน (ได้ลับก็นับว่าได้ตำนานขึ้นไปแล้ว)
--   หายากขึ้นไป: ครั้งที่ครบกำหนด ถ้าสุ่มได้ธรรมดา ยกเป็นหายาก (ได้สูงกว่าอยู่แล้วก็ได้ตามนั้น)
local function rollTier(odds, rules, pity, r)
	local secretOn = odds[EVENT_RARITY] ~= nil
	local tier = naturalTier(odds, r)
	local forced = nil
	if secretOn and rules.Secret and pity.Secret + 1 >= rules.Secret then
		tier, forced = EVENT_RARITY, EVENT_RARITY
	elseif odds.Legendary and rules.Legendary and pity.Legendary + 1 >= rules.Legendary and tierOrder(tier) < ORDER_LEGENDARY then
		tier, forced = "Legendary", "Legendary"
	elseif odds.Rare and rules.Rare and pity.Rare + 1 >= rules.Rare and tierOrder(tier) < ORDER_RARE then
		tier, forced = "Rare", "Rare"
	end
	pity.Rare = tierOrder(tier) >= ORDER_RARE and 0 or pity.Rare + 1
	pity.Legendary = tierOrder(tier) >= ORDER_LEGENDARY and 0 or pity.Legendary + 1
	-- ได้ระดับลับจากการสุ่มปกติไม่รีเซ็ตตัวนับ; รีเซ็ตเฉพาะครั้งที่การันตีลับทำงานครบกำหนด
	if secretOn then pity.Secret = forced == EVENT_RARITY and 0 or pity.Secret + 1 end
	return tier, forced
end

local function rollOne(st, typeId, pity)
	local tier, forced = rollTier(st.odds[typeId], GachaConfig.TicketTypes[typeId].Pity or {}, pity, rng)
	local list = st.pool[tier]
	return list[rng:NextInteger(1, #list)], tier, forced
end

-- เรตเฉลี่ยระยะยาวเมื่อนับการันตีด้วย (โชว์เป็น "≈" ใต้ตาราง)
-- จำลองสุ่มจริงด้วยกติกาเดียวกับของจริง seed ตายตัว ทุกเซิร์ฟเวอร์ได้ตัวเลขเท่ากัน คำนวณครั้งเดียวต่อโหมดตู้
local SIM_ROLLS = 200000
local ratesCache = {} -- [state] = { [typeId] = rates }
local function pityRates(st, typeId)
	ratesCache[st] = ratesCache[st] or {}
	if ratesCache[st][typeId] then return ratesCache[st][typeId] end
	local odds = st.odds[typeId]
	local rules = GachaConfig.TicketTypes[typeId].Pity or {}
	local r = Random.new(20260924)
	local pity = { Rare = 0, Legendary = 0, Secret = 0 }
	local rareUp, legendaryUp, secret = 0, 0, 0
	for i = 1, SIM_ROLLS do
		local tier = rollTier(odds, rules, pity, r)
		local order = tierOrder(tier)
		if order >= ORDER_RARE then rareUp += 1 end
		if tier == "Legendary" then legendaryUp += 1 end
		if tier == EVENT_RARITY then secret += 1 end
		if i % 20000 == 0 then task.wait() end -- ไม่ให้เซิร์ฟเวอร์ค้าง
	end
	local rates = {
		Rare = rareUp / SIM_ROLLS * 100,
		Legendary = odds.Legendary and legendaryUp / SIM_ROLLS * 100 or nil,
		Secret = odds[EVENT_RARITY] and secret / SIM_ROLLS * 100 or nil,
	}
	ratesCache[st][typeId] = rates
	return rates
end

-- คำนวณเก็บไว้ล่วงหน้า ผู้เล่นเปิดตู้ครั้งแรกจะได้ไม่ต้องรอ
local function warmRates(st)
	task.spawn(function()
		for typeId in pairs(GachaConfig.TicketTypes) do pityRates(st, typeId) end
	end)
end
warmRates(state)
stateChanged.Event:Connect(function() warmRates(state) end)

-- ============ PolicyService: ประเทศที่ห้ามการสุ่มแบบจ่ายเงิน ============
local restricted = {} -- [player] = true/false
local function loadPolicy(player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	-- ถามไม่ได้ = ถือว่าห้ามไว้ก่อน (ปลอดภัยกว่า) ตั๋วธรรมดายังใช้ได้ปกติ
	restricted[player] = (not ok) or (info and info.ArePaidRandomItemsRestricted == true)
end

local function isBlocked(player, ticketType)
	return ticketType.Paid and restricted[player] ~= false
end

-- ============ ตั๋วพรีเมียมที่ซื้อด้วย Robux ============
for _, product in ipairs(GachaConfig.TicketProducts) do
	local ticketType = GachaConfig.TicketTypes[product.TicketType]
	PurchaseRouter.Register(product.ProductId, {
		name = ticketType.DisplayName .. " " .. product.Amount .. " ใบ",
		grant = function(player, receiptInfo)
			local balance = GachaTickets.Add(player, product.TicketType, product.Amount, tostring(receiptInfo.PurchaseId))
			if not balance then return false end
			harvestNotify:FireClient(player, nil, nil, nil,
				L(player, string.format("%s ได้%s +%d ใบ (มี %d ใบ)", ticketType.Icon, ticketType.DisplayName, product.Amount, balance),
					string.format("%s +%d %s (you have %d)", ticketType.Icon, product.Amount, ticketName(player, product.TicketType, ticketType), balance)))
			return true
		end,
	})
end

-- ============ ประกาศเมื่อสุ่มได้ของดี ============
local MessagingService = game:GetService("MessagingService")
local ANNOUNCE_TOPIC = "GachaAnnounce_v1"
local ANNOUNCE_MIN_ORDER = tierOrder("Legendary") -- ตำนานขึ้นไปประกาศในเซิร์ฟเวอร์
-- ลับ (EVENT_RARITY) ประกาศข้ามเซิร์ฟเวอร์ด้วย

local function announceRoll(player, results)
	for _, r in ipairs(results) do
		if tierOrder(r.Rarity) >= ANNOUNCE_MIN_ORDER then
			local payload = {
				UserId = player.UserId, Name = player.DisplayName,
				PetId = r.PetId, PetName = r.DisplayName, Rarity = r.Rarity, IsNew = r.IsNew,
			}
			gachaAnnounce:FireAllClients(payload)
			if r.Rarity == EVENT_RARITY then
				task.spawn(function()
					local message = table.clone(payload)
					message.JobId = game.JobId
					local ok, err = pcall(function() MessagingService:PublishAsync(ANNOUNCE_TOPIC, message) end)
					if not ok then warn("GachaService: ประกาศข้ามเซิร์ฟเวอร์ไม่สำเร็จ: " .. tostring(err)) end
				end)
			end
		end
	end
end

-- รับประกาศจากเซิร์ฟเวอร์อื่น (ข้ามของเซิร์ฟเวอร์ตัวเอง เพราะประกาศไปแล้ว)
task.spawn(function()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(ANNOUNCE_TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" or data.JobId == game.JobId then return end
			if data.Kind == "Fish" then return end -- ปลาไม่ประกาศให้คนอื่นแล้ว (2026-10-01) ข้ามข้อความจากเซิร์ฟเวอร์เวอร์ชันเก่า
			if type(data.Name) ~= "string" or type(data.PetName) ~= "string" or type(data.Rarity) ~= "string" then return end
			if not PetRarity.Get(data.Rarity) then return end
			gachaAnnounce:FireAllClients({
				UserId = tonumber(data.UserId) or 0, Name = string.sub(data.Name, 1, 40),
				PetId = type(data.PetId) == "string" and data.PetId or nil,
				PetName = string.sub(data.PetName, 1, 40), Rarity = data.Rarity, OtherServer = true,
				Kind = data.Kind == "Fish" and "Fish" or nil, -- ประกาศปลาจาก FishingSystem ใช้หัวข้อเดียวกัน
				Detail = type(data.Detail) == "string" and string.sub(data.Detail, 1, 40) or nil,
			})
		end)
	end)
	if not ok then warn("GachaService: ฟังประกาศข้ามเซิร์ฟเวอร์ไม่ได้: " .. tostring(err)) end
end)

-- ============ คำขอจากหน้าต่างตู้ ============
local busy = {}     -- [player] = true ระหว่างทำคำขอ (กันสุ่มซ้อน)
local lastRoll = {} -- [player] = os.clock()

local function ticketCounts(player)
	local counts = {}
	for typeId in pairs(GachaConfig.TicketTypes) do counts[typeId] = GachaTickets.Get(player, typeId) end
	return counts
end

local function infoFor(player)
	local st = currentState()
	local types = {}
	for typeId, ticketType in pairs(GachaConfig.TicketTypes) do
		table.insert(types, {
			Id = typeId,
			Order = ticketType.Order,
			DisplayName = ticketType.DisplayName,
			Icon = ticketType.Icon,
			CoinPrice = ticketType.CoinPrice,
			Paid = ticketType.Paid == true,
			Blocked = isBlocked(player, ticketType),
			Odds = st.odds[typeId],
			PityRules = ticketType.Pity,
			Pity = GachaTickets.GetPity(player, typeId),
			WithPity = pityRates(st, typeId),
		})
	end
	table.sort(types, function(a, b) return a.Order < b.Order end)
	local pool = {}
	for rarityId, list in pairs(st.pool) do
		pool[rarityId] = {}
		for _, petId in ipairs(list) do
			table.insert(pool[rarityId], { Id = petId, DisplayName = PetDefinitions[petId].DisplayName, DisplayNameEn = PetDefinitions[petId].DisplayNameEn, Owned = PetOwnership.Owns(player, petId) })
		end
	end
	local products = {}
	for _, product in ipairs(GachaConfig.TicketProducts) do
		table.insert(products, { ProductId = product.ProductId, Amount = product.Amount, TicketType = product.TicketType })
	end
	local event = st.event and { Id = st.event.Id, Name = st.event.Name, NameEn = st.event.NameEn, EndsAt = st.event.End } or nil
	-- แท็บตัวซ้ำ: สัตว์ทุกตัว + เลเวล/ตัวซ้ำ/แลกได้ไหม
	-- สัตว์พรีเมียม (ซื้อด้วย Robux เท่านั้น 2026-10-14): ส่ง Premium = { ProductId, Price, MaxLevel, Sim } ให้หน้าจอทำปุ่มซื้อ/อัปเลเวล
	local PremiumPetConfig = require(ReplicatedStorage:WaitForChild("PremiumPetConfig"))
	local function premiumInfo(petId)
		local cfg = PremiumPetConfig.Get(petId)
		if not cfg or cfg.ShopOnly then return nil end -- ShopOnly = ขายในร้านสุดพิเศษเท่านั้น แท็บนี้คงปุ่มอัปเลเวลด้วยเศษ
		local price = nil
		if cfg.ProductId and cfg.ProductId > 0 then
			local ok, infoP = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(cfg.ProductId, Enum.InfoType.Product) end)
			price = ok and infoP and infoP.PriceInRobux or nil
		end
		local sim = game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevPremiumPetSim") == true
		return { ProductId = cfg.ProductId, Price = price, MaxLevel = cfg.MaxLevel, OnSale = (cfg.ProductId or 0) > 0 or sim }
	end
	local pets = {}
	for petId, def in pairs(PetDefinitions) do
		local rarityId = def.Rarity or PetRarity.DEFAULT
		if def.HiddenUnlessOwned and not PetOwnership.Owns(player, petId) then continue end -- สัตว์ลึกลับ: ไม่มี = ไม่เห็น
		table.insert(pets, {
			Id = petId, DisplayName = def.DisplayName, DisplayNameEn = def.DisplayNameEn, Rarity = rarityId,
			Owned = PetOwnership.Owns(player, petId),
			Level = PetOwnership.GetLevel(player, petId),
			Dupes = PetOwnership.GetDupes(player, petId),
			InPool = st.pool[rarityId] ~= nil and table.find(st.pool[rarityId], petId) ~= nil,
			ShardCost = PetLevelConfig.ShardCostOf(rarityId),
			ShardValue = PetLevelConfig.ShardValue(rarityId),
			LevelUpCost = PetLevelConfig.LevelUpCostOf(petId, rarityId), -- นาก/ลับ/สุลต่าน: อัปเลเวลด้วยเศษ (แลกตัวใหม่ไม่ได้)
			UnlockHint = def.UnlockHint, -- ได้จากที่อื่น (เช่น นากจากสมุดปลา / มังกรจากแพ็กสุลต่าน)
			Premium = premiumInfo(petId),
		})
	end
	table.sort(pets, function(a, b)
		local oa, ob = tierOrder(a.Rarity), tierOrder(b.Rarity)
		if oa ~= ob then return oa > ob end
		return a.DisplayName < b.DisplayName
	end)
	return {
		Types = types, Pool = pool, Products = products, Tickets = ticketCounts(player),
		MaxRolls = GachaConfig.MAX_ROLLS_PER_REQUEST, Event = event, EventRarity = EVENT_RARITY,
		Pets = pets, Shards = PetOwnership.GetShards(player),
		Level = {
			Max = PetLevelConfig.MAX_LEVEL,
			SpeedPerLevel = PetLevelConfig.SPEED_PER_LEVEL,
			HungerPerLevel = PetLevelConfig.HUNGER_PER_LEVEL,
		},
	}
end

-- ตัวดักตู้สุ่ม (จดชื่ออย่างเดียว ไม่ห้ามซื้อ/สุ่ม) นับต่อรอบที่ผู้เล่นอยู่ในเซิร์ฟเวอร์นี้
-- ทางที่เคยเจอ: เหรียญโกง -> ซื้อตั๋วธรรมดาไม่อั้น -> การันตีตัวลับทุก 200 ครั้ง
local COIN_TICKETS_FLAG = 150 -- ซื้อตั๋วด้วยเหรียญครบเท่านี้ในรอบเดียว (150 ใบ = 3 ล้านเหรียญ)
local SECRETS_FLAG = 2        -- ได้ตัวลับครบเท่านี้ในรอบเดียว
local coinTicketsBought = {} -- [player] = จำนวนใบ
local secretsRolled = {}     -- [player] = จำนวนตัว

local function buyWithCoins(player, typeId, count)
	local ticketType = GachaConfig.TicketTypes[typeId]
	if not ticketType or not ticketType.CoinPrice then return { ok = false, message = L(player, "ตั๋วแบบนี้ซื้อด้วยเหรียญไม่ได้", "This ticket can't be bought with coins") } end
	count = math.floor(tonumber(count) or 0)
	if count ~= count or count < 1 or count > GachaConfig.MAX_COIN_TICKETS_PER_BUY then -- count ~= count = NaN (ทะลุการเทียบ < > = ซื้อตั๋วโดยไม่มีเหรียญได้)
		return { ok = false, message = L(player, "จำนวนไม่ถูกต้อง", "Invalid amount") }
	end
	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
	if not coins then return { ok = false, message = L(player, "ยังโหลดเหรียญไม่เสร็จ", "Coins are still loading") } end
	local cost = ticketType.CoinPrice * count
	-- บทเรียนผู้เล่นใหม่: ตั๋วธรรมดา 1 ใบแรกฟรี (TutorialService ตั้ง Attribute "FreeNormalTicket" ให้ ใช้ได้ครั้งเดียว)
	local free = typeId == "Normal" and count == 1 and player:GetAttribute("FreeNormalTicket") == true
	if free then
		cost = 0
		player:SetAttribute("FreeNormalTicket", nil) -- กันกดซ้ำระหว่างรอเซฟ
	end
	if coins.Value < cost then
		return { ok = false, message = L(player, string.format("เหรียญไม่พอ (ต้องใช้ %s)", tostring(cost)), string.format("Not enough coins (need %s)", tostring(cost))) }
	end
	player:SetAttribute("CoinSrc", "gacha_ticket")
	coins.Value -= cost
	local balance = GachaTickets.Add(player, typeId, count)
	if not balance then
		coins.Value += cost -- เซฟตั๋วไม่ได้ คืนเหรียญ
		if free then player:SetAttribute("FreeNormalTicket", true) end -- คืนสิทธิ์ฟรี
		return { ok = false, message = L(player, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง (คืนเหรียญแล้ว)", "Save error, please try again (coins refunded)") }
	end
	if free then player:SetAttribute("FreeTicketClaimed", true) end -- TutorialService จดว่าใช้สิทธิ์แล้ว (ถาวร)
	dprint(string.format("🎟️ Gacha: %s ซื้อ%s %d ใบ ด้วย %d เหรียญ%s (มี %d ใบ)", player.Name, ticketType.DisplayName, count, cost, free and " (ฟรีจากบทเรียน)" or "", balance))
	if cost > 0 then
		coinTicketsBought[player] = (coinTicketsBought[player] or 0) + count
		if coinTicketsBought[player] >= COIN_TICKETS_FLAG then
			CheatWatch.Flag(player, "gacha_coin_tickets", string.format("ซื้อตั๋วด้วยเหรียญ %d ใบในรอบนี้ (%d เหรียญ)", coinTicketsBought[player], coinTicketsBought[player] * ticketType.CoinPrice))
		end
	end
	return { ok = true, tickets = ticketCounts(player) }
end

local function roll(player, typeId, count)
	local ticketType = GachaConfig.TicketTypes[typeId]
	if not ticketType then return { ok = false, message = L(player, "ไม่รู้จักตั๋วแบบนี้", "Unknown ticket type") } end
	count = math.floor(tonumber(count) or 0)
	if count ~= 1 and count ~= GachaConfig.MAX_ROLLS_PER_REQUEST then return { ok = false, message = L(player, "จำนวนครั้งไม่ถูกต้อง", "Invalid roll count") } end
	if isBlocked(player, ticketType) then return { ok = false, message = L(player, "ตั๋วพรีเมียมใช้ในประเทศของคุณไม่ได้", "Premium tickets aren't available in your country") } end
	if not GachaTickets.IsLoaded(player) then return { ok = false, message = L(player, "ยังโหลดข้อมูลตั๋วไม่เสร็จ ลองใหม่อีกครั้ง", "Tickets are still loading, please try again") } end
	if lastRoll[player] and os.clock() - lastRoll[player] < GachaConfig.ROLL_COOLDOWN then
		return { ok = false, message = L(player, "ใจเย็นๆ รออีกนิดนะ", "Slow down, wait a moment") }
	end
	lastRoll[player] = os.clock()

	local st = currentState()
	local spent, rolled, left, pityBefore, pityAfter, saveErr = GachaTickets.SpendAndRoll(player, typeId, count, function(pity)
		local out = {}
		for i = 1, count do
			local petId, rarityId, forced = rollOne(st, typeId, pity)
			out[i] = { petId = petId, rarity = rarityId, forced = forced }
		end
		return out
	end)
	if not spent then
		if saveErr then -- DataStore/สุ่มพัง ไม่ใช่ตั๋วไม่พอ (ตั๋วยังไม่ถูกหัก) 2026-11-18 เคส kxnfilm_007
			lastRoll[player] = nil -- กดใหม่ได้ทันที ไม่ต้องรอคูลดาวน์
			return { ok = false, message = L(player, "ระบบบันทึกขัดข้อง ลองกดสุ่มใหม่อีกครั้ง (ยังไม่หักตั๋ว)", "Save error, please roll again (no ticket was used)") }
		end
		return { ok = false, message = L(player, string.format("%s ไม่พอ (มี %d ใบ)", ticketType.DisplayName, left or 0), string.format("Not enough %s (you have %d)", ticketName(player, typeId, ticketType), left or 0)) }
	end

	local petIds = {}
	for i, r in ipairs(rolled) do petIds[i] = r.petId end
	local granted = PetOwnership.GrantBatch(player, petIds)
	if not granted then
		GachaTickets.Refund(player, typeId, count, pityBefore) -- ให้สัตว์ไม่สำเร็จ คืนตั๋ว + ย้อนตัวนับการันตี
		return { ok = false, message = L(player, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง (คืนตั๋วแล้ว)", "Save error, please try again (tickets refunded)") }
	end

	local results = {}
	for i, r in ipairs(granted) do
		results[i] = {
			PetId = r.petId, DisplayName = PetDefinitions[r.petId].DisplayName, DisplayNameEn = PetDefinitions[r.petId].DisplayNameEn,
			Rarity = rolled[i].rarity, IsNew = r.isNew, Forced = rolled[i].forced ~= nil,
			AutoShards = r.shards, -- เลเวลเต็มแล้ว ตัวซ้ำกลายเป็นเศษทันที
			NewLevel = r.level,    -- ตัวซ้ำ = +1 เลเวลทันที
		}
	end
	local names = {}
	for _, r in ipairs(results) do table.insert(names, r.PetId .. (r.IsNew and "*" or "") .. (r.Forced and "!" or "")) end
	dprint(string.format("🎰 Gacha: %s สุ่ม%s x%d -> %s (pity หายาก %d ตำนาน %d ลับ %d)", player.Name, ticketType.DisplayName, count,
		table.concat(names, ", "), pityAfter.Rare, pityAfter.Legendary, pityAfter.Secret))
	if player:GetAttribute("TutorialStep") == 7 then -- ขั้นสุ่มสัตว์ในบทเรียนรุ่น 2 (2026-10-18 เดิมขั้น 10) ต้องตรงกับ STEP_GACHA_ROLL ใน TutorialService
		player:SetAttribute("TutorialGachaRollDone", true) -- ส่งสัญญาณหลังหักตั๋วและบันทึกสัตว์สำเร็จแล้วเท่านั้น
		dprint("[Tutorial] gacha roll completed for " .. player.Name .. "; moving to pet-use step")
	end
	for _, r in ipairs(results) do
		if r.Rarity == EVENT_RARITY then secretsRolled[player] = (secretsRolled[player] or 0) + 1 end
	end
	if (secretsRolled[player] or 0) >= SECRETS_FLAG then
		CheatWatch.Flag(player, "gacha_secret", string.format("ได้ตัวลับ %d ตัวในรอบนี้ (ตั๋วที่ซื้อด้วยเหรียญ %d ใบ)", secretsRolled[player], coinTicketsBought[player] or 0))
	end
	announceRoll(player, results)
	return { ok = true, results = results, tickets = ticketCounts(player), pity = pityAfter }
end

gachaRequest.OnServerInvoke = function(player, action, typeId, count)
	if busy[player] then return { ok = false, message = L(player, "กำลังทำรายการก่อนหน้าอยู่", "Still processing your last request") } end
	busy[player] = true
	local ok, result = pcall(function()
		if action == "info" then
			return { ok = true, info = infoFor(player) }
		elseif action == "buyCoins" then
			return buyWithCoins(player, typeId, count)
		elseif action == "roll" then
			return roll(player, typeId, count)
		elseif action == "levelUp" or action == "toShards" then
			-- typeId = petId, count = จำนวนตัวซ้ำที่ใช้
			if type(typeId) ~= "string" or not PetDefinitions[typeId] then return { ok = false, message = L(player, "ไม่รู้จักสัตว์ตัวนี้", "Unknown pet") } end
			local ok, message = PetOwnership.UseDupes(player, typeId, action == "levelUp" and "level" or "shards", count)
			return { ok = ok, message = message }
		elseif action == "shardLevelUp" then
			-- typeId = petId (นาก / ระดับลับ / สุลต่าน) ต้องมีสัตว์ตัวนั้นอยู่แล้ว
			local def = type(typeId) == "string" and PetDefinitions[typeId]
			if not def then return { ok = false, message = L(player, "ไม่รู้จักสัตว์ตัวนี้", "Unknown pet") } end
			local ok, message = PetOwnership.LevelUpWithShards(player, typeId)
			if ok then dprint(string.format("💠 Gacha: %s อัปเลเวล %s ด้วยเศษ", player.Name, typeId)) end
			return { ok = ok, message = message }
		elseif action == "exchange" then
			-- typeId = petId ที่อยากได้ (ต้องอยู่ในตู้ตอนนี้ ตัวลับเฉพาะช่วงอีเวนต์)
			local def = type(typeId) == "string" and PetDefinitions[typeId]
			if not def then return { ok = false, message = L(player, "ไม่รู้จักสัตว์ตัวนี้", "Unknown pet") } end
			local list = currentState().pool[def.Rarity or PetRarity.DEFAULT]
			if not (list and table.find(list, typeId)) then
				return { ok = false, message = L(player, "ตัวนี้ยังไม่อยู่ในตู้ตอนนี้ (ตัวลับแลกได้เฉพาะช่วงอีเวนต์)", "This pet isn't in the machine right now (Secret pets only during events)") }
			end
			local ok, message = PetOwnership.ExchangeShards(player, typeId)
			if ok then dprint(string.format("💠 Gacha: %s แลกเศษเป็น %s", player.Name, typeId)) end
			return { ok = ok, message = message }
		end
		return { ok = false, message = L(player, "คำขอไม่ถูกต้อง", "Invalid request") }
	end)
	busy[player] = nil
	if not ok then
		warn("GachaService: คำขอ " .. tostring(action) .. " ของ " .. player.Name .. " ผิดพลาด: " .. tostring(result))
		return { ok = false, message = L(player, "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง", "Something went wrong, please try again") }
	end
	return TextEn.Result(player, result)
end

-- ============ ตัวตู้ในแมพ: เดินไปกด E เปิดหน้าต่างตู้ ============
local function hookMachine(machine)
	local prompt = machine:FindFirstChild("GachaPrompt", true)
	if not prompt then
		local anchorPart = machine:IsA("BasePart") and machine or machine:FindFirstChildWhichIsA("BasePart", true)
		if not anchorPart then return end
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GachaPrompt"
		prompt.ActionText = "เปิดตู้สุ่ม"
		prompt.ObjectText = "🎁 ตู้สุ่มสัตว์เลี้ยง"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchorPart
	end
	prompt.Triggered:Connect(function(player)
		gachaOpen:FireClient(player)
	end)
end
local machine = workspace:FindFirstChild("GachaMachine")
if machine then hookMachine(machine) end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "GachaMachine" then hookMachine(child) end
end)

-- ============ ตัวโชว์บนตู้: สัตว์ระดับสูงสุดลอยอยู่บนหลังคา + ป้ายชื่อ/โอกาสออก/ความสามารถ ============
-- เซิร์ฟเวอร์แค่วางไว้นิ่งๆ ส่วนลอยขึ้นลง ส่ายตัว ไล่สีรุ้ง ทำฝั่งผู้เล่นใน GachaShowcaseClient (ลื่นกว่า ไม่กินเน็ต)
local ServerStorage = game:GetService("ServerStorage")
local SHOWCASE_SCALE = 1.8   -- ขยายให้เห็นชัดจากไกลๆ
local SHOWCASE_GAP = 1.2     -- ระยะจากหลังคาตู้ถึงเท้า
local SHOWCASE_CYCLE = 8     -- ระดับนั้นมีหลายตัว = สลับโชว์ทุกกี่วินาที

local function showcaseRarity()
	local best
	for rarityId, list in pairs(state.pool) do
		if #list > 0 and (not best or PetRarity.Get(rarityId).Order > PetRarity.Get(best).Order) then best = rarityId end
	end
	return best
end

local function fmtPct(p)
	local s = string.format("%.4f", p):gsub("0+$", ""):gsub("%.$", "")
	return s .. "%"
end

-- โอกาสได้ "ตัวนี้" ต่อการสุ่ม 1 ครั้ง แยกตามชนิดตั๋ว (เหรียญ / Robux)
local function chanceText(rarityId)
	local types = {}
	for typeId, t in pairs(GachaConfig.TicketTypes) do table.insert(types, { id = typeId, t = t }) end
	table.sort(types, function(a, b) return a.t.Order < b.t.Order end)
	local parts = {}
	for _, e in ipairs(types) do
		local pct = state.odds[e.id][rarityId]
		if pct then table.insert(parts, (e.t.Paid and "Robux " or "เหรียญ ") .. fmtPct(pct / #state.pool[rarityId])) end
	end
	return string.format("★ %s · %s ★", PetRarity.Get(rarityId).DisplayName, table.concat(parts, " · "))
end

local function perksText(def)
	local perks = {}
	if def.HarvestMultiplier and def.HarvestMultiplier > 1 then table.insert(perks, "เก็บเกี่ยว x" .. def.HarvestMultiplier) end
	if def.NineLives then table.insert(perks, def.NineLives .. " ชีวิต") end
	if def.Luck and def.Luck > 0 then table.insert(perks, "นำโชค x" .. def.Luck) end
	return table.concat(perks, " · ")
end

-- บรรทัดที่ 2 ใต้นำโชค: ความสามารถพิเศษของตัวโชว์ (2026-10-15 ผู้ใช้ขอ เช่น ผีน้อย) ไม่มี = ซ่อนบรรทัด
local function specialPerksText(def, petId)
	local perks = {}
	if def.StrawYieldBonus then
		local maxBonus = PetLevelConfig.StrawYieldAt and PetLevelConfig.StrawYieldAt(petId, PetLevelConfig.MAX_LEVEL)
		local text = "ผลผลิตในวงหุ่นฟาง x" .. (1 + def.StrawYieldBonus)
		if maxBonus and maxBonus > def.StrawYieldBonus then text ..= "→" .. (1 + maxBonus) end
		table.insert(perks, text)
	end
	if def.StrawGrowBoost then table.insert(perks, "ผักในวงโตไว +" .. math.floor(def.StrawGrowBoost * 100 + 0.5) .. "%") end
	if def.GrowBoost then table.insert(perks, "ผักโตไว +" .. math.floor(def.GrowBoost * 100 + 0.5) .. "%") end
	if def.SellBonus then table.insert(perks, "ขายได้เงิน +" .. math.floor(def.SellBonus * 100 + 0.5) .. "%") end
	if def.PollinateChance then table.insert(perks, "ผสมเกสร " .. math.floor(def.PollinateChance * 100 + 0.5) .. "% ผลผลิต +1") end -- ผึ้งราชินี 2026-10-29
	if def.ShowcasePerk then table.insert(perks, def.ShowcasePerk) end -- ข้อความสำเร็จรูปจาก PetDefinitions (ตุ่นนักอนุรักษ์ 2026-11-06)
	return table.concat(perks, " · ")
end

local function makeText(parent, name, order, height, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(1, height)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(30, 15, 45)
	stroke.Thickness = 2.5
	stroke.Parent = label
	return label
end

local function buildLabel(anchorPart)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShowcaseLabel"
	gui.Size = UDim2.fromScale(12, 5.9) -- หน่วยเป็น studs: ไกลแล้วเล็กลงเหมือนวัตถุจริง (2026-10-15: 4.8 → 5.9 เผื่อบรรทัดความสามารถ ขนาดตัวอักษรเดิมเท่าเดิม)
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.Adornee = anchorPart
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = gui
	makeText(gui, "Chance", 1, 0.146, Color3.fromRGB(255, 220, 110))
	local name = makeText(gui, "PetName", 2, 0.325, Color3.new(1, 1, 1))
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Rainbow" -- ฝั่งผู้เล่นขยับให้สีวิ่ง (สีตั้งตามระดับของตัวที่โชว์)
	gradient.Parent = name
	makeText(gui, "Perks", 3, 0.195, Color3.fromRGB(130, 255, 120))
	makeText(gui, "Perks2", 4, 0.165, Color3.fromRGB(190, 255, 170)) -- ความสามารถพิเศษ (ซ่อนถ้าไม่มี)
	makeText(gui, "EventTime", 5, 0.146, Color3.fromRGB(255, 170, 215)) -- นับถอยหลังอีเวนต์ (ซ่อนนอกอีเวนต์)
	gui.Parent = anchorPart
	return gui
end

local function placeShowcase(machine, petId, label)
	local def = PetDefinitions[petId]
	local folder = ServerStorage:FindFirstChild(def.TemplateFolder or "PetTemplates")
	local template = folder and folder:FindFirstChild(petId)
	if not template then
		warn("GachaService: ไม่พบโมเดลตัวโชว์ " .. petId)
		return nil
	end
	local pet = template:Clone()
	pet.Name = "GachaShowcase"
	for _, d in ipairs(pet:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		elseif d:IsA("Humanoid") then
			d:Destroy() -- ไม่ต้องเดิน และไม่ให้ขึ้นชื่อ Humanoid ลอยบนหัว
		end
	end
	PetController.ApplyRarityGlow(pet, def.Rarity)
	pet:ScaleTo(pet:GetScale() * SHOWCASE_SCALE)

	-- หันหน้าทางเดียวกับหน้าตู้ (หน้าตู้ = LookVector ของจุดหมุนตู้) เดิมหันไปทางจุดเกิด มองจากหน้าตู้แล้วเห็นหลังตัวโชว์ (ผู้ใช้ขอแก้ 2026-10-11)
	local mcf, msize = machine:GetBoundingBox()
	local top = mcf.Position.Y + msize.Y / 2
	local dir = machine:GetPivot().LookVector * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.01 then dir = Vector3.new(0, 0, -1) end
	local rot = CFrame.lookAt(Vector3.zero, dir.Unit) * (def.FacingOffset or CFrame.identity)
	pet:PivotTo(rot)
	local pcf, psize = pet:GetBoundingBox()
	local feetBelowPivot = -(pcf.Position.Y - psize.Y / 2) -- ระยะจากจุดหมุนลงไปถึงเท้า
	local base = CFrame.new(mcf.Position.X, top + SHOWCASE_GAP + feetBelowPivot, mcf.Position.Z) * rot
	pet:PivotTo(base)

	pet:SetAttribute("GachaShowcase", true)
	pet:SetAttribute("ShowcaseBase", base)
	pet:SetAttribute("RainbowAura", def.RainbowAura == true)
	if def.FireflyRing then
		pet:SetAttribute("FireflyRing", true)
		pet:SetAttribute("FireflyScale", SHOWCASE_SCALE)
		if def.FireflyCount then pet:SetAttribute("FireflyCount", def.FireflyCount) end
		if def.FireflyColors then
			pet:SetAttribute("FireflyColorA", def.FireflyColors[1])
			pet:SetAttribute("FireflyColorB", def.FireflyColors[2] or def.FireflyColors[1])
		end
	end
	pet.Parent = workspace

	label.Chance.Text = chanceText(def.Rarity)
	label.PetName.Text = def.DisplayName
	-- ชื่อ: ลับ = สีรุ้งวิ่ง, ระดับอื่น = ไล่สีประจำระดับจากสว่างลงเข้ม (ดูเงาวาว อ่านชัดกว่าสีเดียว)
	local tier = PetRarity.Get(def.Rarity)
	local gradient = label.PetName.Rainbow
	label.PetName.TextColor3 = Color3.new(1, 1, 1)
	if tier.Gradient then
		gradient.Color = tier.Gradient
		gradient.Rotation = 0
	else
		gradient.Color = ColorSequence.new(tier.Color:Lerp(Color3.new(1, 1, 1), 0.45), tier.Color)
		gradient.Rotation = 90
	end
	gradient:SetAttribute("Animate", tier.Gradient ~= nil)
	label.Perks.Text = perksText(def)
	local perks2 = label:FindFirstChild("Perks2")
	if perks2 then
		perks2.Text = specialPerksText(def, petId)
		perks2.Visible = perks2.Text ~= ""
	end
	label.StudsOffsetWorldSpace = Vector3.new(0, top + SHOWCASE_GAP + psize.Y + 2.75 - label.Adornee.Position.Y, 0) -- 2.2 → 2.75 ป้ายสูงขึ้น 1.1 สตั๊ด (เพิ่มบรรทัดความสามารถ) ขอบล่างจะได้ไม่ทับตัวสัตว์
	return pet
end

local function fmtTimeLeft(seconds)
	seconds = math.max(0, seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	if days > 0 then return string.format("%d วัน %d ชม.", days, hours) end
	if hours > 0 then return string.format("%d ชม. %d นาที", hours, minutes) end
	return string.format("%d นาที", math.max(1, minutes))
end

local showcaseToken = 0
local function startShowcase(machine)
	showcaseToken += 1
	local token = showcaseToken
	local rarityId = showcaseRarity()
	local list = rarityId and state.pool[rarityId]
	-- 2026-11-06 ผู้ใช้สั่ง: มีตัวเทศกาลในตู้ = โชว์เฉพาะตัวเทศกาล ไม่มี = วนทุกตัวในระดับเหมือนเดิม
	if list and state.event and state.event.SecretPets then
		local festival = {}
		for _, petId in ipairs(list) do
			if table.find(state.event.SecretPets, petId) then table.insert(festival, petId) end
		end
		if #festival > 0 then list = festival end
	end
	local anchorPart = machine:FindFirstChildWhichIsA("BasePart", true)
	if not list or not anchorPart then return end
	local label = anchorPart:FindFirstChild("ShowcaseLabel") or buildLabel(anchorPart)
	task.spawn(function()
		local index, current = 0, nil
		local nextSwap = 0
		while machine.Parent and token == showcaseToken do
			if os.clock() >= nextSwap then
				index = index % #list + 1
				if current then current:Destroy() end
				current = placeShowcase(machine, list[index], label)
				nextSwap = #list > 1 and os.clock() + SHOWCASE_CYCLE or math.huge
			end
			local event = state.event
			label.EventTime.Visible = event ~= nil
			if event then
				label.EventTime.Text = "⏳ " .. event.Name .. " · เหลือ " .. fmtTimeLeft(event.End - os.time())
			end
			task.wait(1)
		end
		if current then current:Destroy() end
	end)
end
if machine then startShowcase(machine) end
stateChanged.Event:Connect(function() -- อีเวนต์เริ่ม/จบ: เปลี่ยนตัวโชว์ + เรตบนป้าย
	local m = workspace:FindFirstChild("GachaMachine")
	if m then startShowcase(m) end
end)

-- ============ ผู้เล่นเข้า/ออก ============
local function onPlayer(player)
	task.spawn(loadPolicy, player)
	GachaTickets.Load(player)
end
Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	GachaTickets.Unload(player)
	restricted[player] = nil
	busy[player] = nil
	lastRoll[player] = nil
	coinTicketsBought[player] = nil
	secretsRolled[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, player)
end
