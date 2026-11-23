-- BACKUP of game.ServerScriptService.ChickenFarm.ChickenService before delaying gift deliver 7 s (2026-11-23)
-- Restore: paste everything below this header back into the script's Source in Studio.
-- ChickenService: บ้านไก่ ฝั่งเซิร์ฟเวอร์ (ช่วงที่ 1, 2026-10-20) ค่าต่างๆ ดู ReplicatedStorage.ChickenConfig · ข้อมูลดู ChickenData
-- RemoteFunction RemoteEvents.ChickenRequest(action, arg): "info" / "buyChicken" / "buySlot" / "deposit"(ดาว 1-5, 0 = ทุกดาว หรือ {ดาว, จำนวนถุง}) / "withdraw"(ดาว 1-5, 0 = ทุกดาว) / "sellEggs" / "sellChicken"(id)
--   ช่วงที่ 3: "breed"({idA, idB}) ไข่เข้าตู้ฟัก · "hatch" รับลูกไก่ (ตู้ฟัก IncubatorPrompt = หน้าต่าง "breed")
-- RemoteEvent ChickenSync (เซิร์ฟ -> เจ้าของ: ข้อมูลล่าสุด ให้หน้าต่างและไก่ในลาน) · ChickenOpen(mode) (กด prompt -> เปิดหน้าต่างของจุดนั้น)
-- 2026-10-20 แยก 4 จุด (ผู้ใช้ขอ): เล้า CoopPrompt = "chickens" · ลุงไข่ขายไก่ ShopPrompt = "shop" · ราง TroughPrompt = "trough" · ตะกร้า EggPrompt = "basket"
-- ลำดับกันของหาย/เบิ้ล: เปลี่ยนข้อมูลไก่ -> เซฟ -> ค่อยแตะเหรียญ/กระเป๋า · เซฟไม่ได้ = ย้อนข้อมูลไก่กลับ ไม่แตะเหรียญ/กระเป๋า

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("ChickenConfig"))
local ChickenData = require(script.Parent:WaitForChild("ChickenData"))
local LevelSystem = require(ServerScriptService:WaitForChild("LevelSystem"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))
local SeasonConfig = require(ReplicatedStorage:WaitForChild("SeasonConfig")) -- กลายพันธุ์เทศกาล (ช่วงที่ 3)
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify") -- ประกาศไก่กลายพันธุ์หายาก

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local function remote(className, name)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local requestRemote = remote("RemoteFunction", "ChickenRequest")
local syncRemote = remote("RemoteEvent", "ChickenSync")
local openRemote = remote("RemoteEvent", "ChickenOpen")

-- ============ ซ่อนทั้งระบบ (ChickenConfig.Enabled = false, ผู้ใช้สั่ง 2026-10-21) ============
-- ย้ายลานไก่ + เล้าออกจากแมพไป ServerStorage (ผู้เล่นไม่เห็น ไม่มี prompt) ไม่โหลด/เซฟข้อมูลไก่ แล้วหยุดสคริปต์นี้
-- ใน Studio โหมด Edit ของยังอยู่ที่เดิม (ย้ายเฉพาะตอนเกมรัน)
if not Config.Enabled then
	local hidden = Instance.new("Folder")
	hidden.Name = "ChickenFarmHidden"
	hidden.Parent = game:GetService("ServerStorage")
	local props = workspace:FindFirstChild("FarmProps")
	for _, name in ipairs({ "ChickenYard", "ChickenCoop" }) do
		local m = props and props:FindFirstChild(name)
		if m then m.Parent = hidden end
	end
	requestRemote.OnServerInvoke = function()
		return { ok = false, info = { Enabled = false, Loaded = false } }
	end
	return
end

local REQUEST_COOLDOWN = 0.4
local SETTLE_EVERY = 30
local AUTOSAVE_EVERY = 60
local FLAG_COINS_PER_HOUR = 300000 -- ขายไข่ได้เกินนี้ใน 1 ชั่วโมง = จดชื่อ (ไม่บล็อก)

local busy = {} -- [player] = true
local lastRequest = {} -- [player] = os.clock()
local earned = {} -- [player] = { t0, coins } เงินจากไข่ในชั่วโมงนี้

local function th(player)
	return Localization.GetLanguage(player) ~= "en"
end
local function msg(player, thai, english)
	return th(player) and thai or english
end

-- ประกาศทั้งเซิร์ฟ แต่ละคนได้ภาษาของตัวเอง (2026-10-22 เดิม FireAllClients ภาษาไทยอย่างเดียว)
local function announce(thai, english)
	for _, p in ipairs(Players:GetPlayers()) do
		harvestNotify:FireClient(p, nil, nil, nil, msg(p, thai, english))
	end
end

-- XP เลเวลผู้เล่นจากฟาร์มไก่ (ผู้ใช้ขอ 2026-10-26) ให้หลังคำสั่งสำเร็จ คืนข้อความต่อท้าย " · +N XP" (เพดาน/ตัวดักโกงอยู่ใน LevelSystem.AddXP)
-- boost = true: คูณหุ่น EXP ตามตำแหน่งตัว (2026-11-19 ใช้กับขายไข่/กวาดดินเท่านั้น) ข้อความบอก XP ที่ได้จริง
local function giveXP(player, amount, boost)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then return "" end
	local gained = LevelSystem.AddXP(player, amount, boost and { boost = true } or nil)
	if type(gained) == "number" and gained > 0 then amount = gained end
	return " · +" .. amount .. " XP"
end

local function coinsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("เหรียญ")
end

local function levelOk(player)
	return LevelSystem.GetLevel(player) >= Config.UNLOCK_LEVEL
end

local function foodInBag(player)
	local list, perStar = {}, { 0, 0, 0, 0, 0 }
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if loc then
			for _, tool in ipairs(loc:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("IsPetFood") then
					table.insert(list, tool)
					local s = math.clamp(tool:GetAttribute("Star") or 1, 1, 5)
					perStar[s] += tool:GetAttribute("Count") or 1
				end
			end
		end
	end
	return list, perStar
end

local passOwned = {} -- [player] = { feed = bool, sell = bool } (ช่วงที่ 5)
local carrying = {} -- [player] = { id, tool } ไก่ที่อุ้มอยู่ (ทีละตัว ไม่เซฟ) 2026-10-21
local lastShowcase -- [player] = os.clock() สลับไก่โชว์ครั้งล่าสุด (กำหนดค่าในส่วนไก่โชว์)

-- 💰 ราคา Robux จริงจาก Creator Dashboard (ผู้ใช้ขอ 2026-10-28: ราคาให้อาหารอัตโนมัติขึ้น 180 แต่จริง 199)
-- ดึงทุก 10 นาที แก้ราคาใน Dashboard แล้วร้านตามเอง · ดึงไม่ได้/ID = 0 = ใช้ Config.PRICE_HINT
local livePrices = {}
local PRICE_SOURCES = {
	autoFeed = { "AUTO_FEED_PASS_ID", Enum.InfoType.GamePass },
	autoSell = { "AUTO_SELL_PASS_ID", Enum.InfoType.GamePass },
	instantHatch = { "INSTANT_HATCH_PRODUCT_ID", Enum.InfoType.Product },
	eggTray = { "EGG_TRAY_PRODUCT_ID", Enum.InfoType.Product },
	speedUp = { "SPEEDUP_PRODUCT_ID", Enum.InfoType.Product },
}
local function livePriceHint()
	local out = {}
	for key, fallback in pairs(Config.PRICE_HINT) do out[key] = livePrices[key] or fallback end
	return out
end
task.spawn(function()
	local market = game:GetService("MarketplaceService")
	while true do
		for key, src in pairs(PRICE_SOURCES) do
			local id = Config[src[1]] or 0
			if id > 0 then
				local ok, res = pcall(market.GetProductInfo, market, id, src[2])
				if ok and type(res) == "table" and tonumber(res.PriceInRobux) then livePrices[key] = res.PriceInRobux end
			end
		end
		task.wait(600)
	end
end)

local function snapshot(player)
	local st = ChickenData.Get(player)
	local info = {
		Enabled = Config.Enabled, Loaded = st ~= nil and st.loaded == true,
		LevelOk = levelOk(player), UnlockLevel = Config.UNLOCK_LEVEL,
		ChickenPrice = Config.CHICKEN_PRICE, ChickenSellPrice = Config.CHICKEN_SELL_PRICE,
		TroughCap = 100, BasketCap = 500, EggsPerBag = Config.EGGS_PER_BAG, -- ค่าจริงตามเลเวลอัปเกรดใส่ด้านล่าง
		BreedLevel = Config.BREED_LEVEL, BreedOk = LevelSystem.GetLevel(player) >= Config.BREED_LEVEL,
		BreedCost = Config.BREED_COST, BreedBags = Config.BREED_FOOD_BAGS, HatchMinutes = 30,
		GrowMinutes = Config.GROW_SECONDS / 60, RestMinutes = Config.REST_SECONDS / 60, PityMax = Config.PITY,
	}
	local _, perStar = foodInBag(player)
	info.InBag = perStar
	if not info.Loaded then return info end
	local d = st.data
	local t = ChickenData.Now()
	info.Slots = d.slots
	info.MaxSlots = Config.MAX_SLOTS
	info.SlotPrice = Config.SlotPrice(d.slots)
	local list = {}
	for id, c in pairs(d.chickens) do
		table.insert(list, {
			Id = id, Color = c.color, Speed = c.speed, Size = c.size, Gold = c.gold, Mut = c.mut,
			EggMinutes = Config.EggSeconds(c.speed) / 60, NextEggIn = math.max(0, c.nextEgg - t),
			EggPrice = Config.EggPrice(5, c.size, c.mut) / Config.EGG_PRICE[5], -- ตัวคูณราคา
			GrowIn = math.max(0, c.adultAt - t), RestIn = math.max(0, c.restUntil - t), Gen = c.gen,
			SellPrice = Config.SellPrice(c), -- ราคาขายตามระดับ (2026-10-25)
		})
	end
	table.sort(list, function(a, b) return (tonumber(a.Id) or 0) < (tonumber(b.Id) or 0) end)
	info.Chickens = list
	info.Trough = table.clone(d.trough)
	info.TroughBags = ChickenData.TroughBags(d)
	info.FoodEggsLeft = ChickenData.FoodEggsLeft(d)
	info.Basket = { Eggs = table.clone(d.basket.eggs), Gold = d.basket.gold, Value = d.basket.value, Count = ChickenData.BasketCount(d) }
	info.Stats = table.clone(d.stats)
	-- 🧹 เล้าสกปรก (2026-10-23)
	info.Dirt = math.floor(d.dirt)
	info.DirtSlow = Config.DirtSlow(d.dirt)
	info.DirtFree = Config.DIRT_FREE
	info.CleanMin = Config.CLEAN_MIN
	info.CleanReward = math.floor(d.dirt) * Config.CLEAN_COINS_PER_PCT
	info.DirtPiles = d.dirt >= Config.CLEAN_MIN and math.ceil(d.dirt / Config.DIRT_PER_PILE - 1e-6) or 0 -- กองดินที่ต้องกวาด (2026-10-23)
	info.Pity = d.pity
	-- ช่วงที่ 4
	info.Book = table.clone(d.book)
	info.BookCount = ChickenData.BookCount(d)
	info.BookTotal = #Config.BookEntries()
	info.BookClaimed = table.clone(d.bookClaimed)
	info.BookRewards = Config.BOOK_REWARDS
	info.Showcase = d.showcase
	-- ช่วงที่ 5
	info.TroughCap = ChickenData.TroughCap(d)
	info.BasketCap = ChickenData.BasketCap(d)
	info.HatchMinutes = ChickenData.HatchSeconds(d) / 60
	local upgrades = {}
	for id, u in pairs(Config.UPGRADES) do
		local lv = d.upg[id]
		local nextLv = u.Levels[lv + 1]
		table.insert(upgrades, { Id = id, Order = u.Order, Level = lv, MaxLevel = #u.Levels, Value = u.Levels[lv].Value, NextValue = nextLv and nextLv.Value, NextCost = nextLv and nextLv.Cost, RobuxOnly = u.RobuxOnly == true })
	end
	table.sort(upgrades, function(a, b) return a.Order < b.Order end)
	info.Upgrades = upgrades
	local passes = passOwned[player] or {}
	info.Passes = { Feed = passes.feed == true or d.giftFeed == true, Sell = passes.sell == true } -- giftFeed = เพื่อนส่งให้ (2026-10-23)
	info.GiftIds = { Feed = Config.AUTO_FEED_GIFT_PRODUCT_ID, Hatch = Config.INSTANT_HATCH_GIFT_PRODUCT_ID }
	info.AutoSellEnabled = Config.AUTO_SELL_ENABLED == true
	info.AutoFeedOn, info.AutoSellOn = d.autoFeedOn, d.autoSellOn
	info.AutoFeedMachine = d.autoFeedMachine -- 🥫 ดึงจากเครื่องทำอาหารสัตว์ 2026-11-05
	info.AutoCleanAt, info.AutoCleanSteps = d.autoCleanAt, Config.AUTO_CLEAN_STEPS -- 🧹 2026-10-28
	info.HatchTokens = d.hatchTokens
	info.SpeedTokens = d.speedTokens -- ⏩ 2026-10-28
	info.SpeedCoinPrice = Config.SPEEDUP_COIN_PRICE -- ⏩ ซื้อด้วยเหรียญ 2026-11-02
	info.Ids = { Feed = Config.AUTO_FEED_PASS_ID, Sell = Config.AUTO_SELL_PASS_ID, Hatch = Config.INSTANT_HATCH_PRODUCT_ID, Tray = Config.EGG_TRAY_PRODUCT_ID, Speed = Config.SPEEDUP_PRODUCT_ID }
	info.SpeedStudio = game:GetService("RunService"):IsStudio() -- Studio เห็นปุ่ม ⏩ เสมอ (ID = 0 ก็จำลองได้)
	info.PriceHint = livePriceHint()
	info.BreedBagsReady = ChickenData.PickBreedBags(d) ~= nil
	info.EggHatchCost = Config.EGG_HATCH_COST -- ฟักไข่จากแผง (2026-10-22)
	info.EggHatchOn = Config.EGG_HATCH_ENABLED -- ปิดไว้ 2026-10-29
	local normalEggs = 0
	for s = 1, 5 do normalEggs += d.basket.eggs[s] end
	info.NormalEggs = normalEggs
	info.CarriedId = carrying[player] and carrying[player].id or nil
	info.DirtPerPile = Config.DIRT_PER_PILE -- กองดิน 1 กอง (2026-10-23)
	-- ช่วงที่ 6: ประกวด + หอเกียรติยศ
	local week = Config.ContestWeek(t)
	local ct = d.contest
	local thisWeek = ct and ct.week == week
	info.Contest = {
		Week = week, ThemeId = Config.ContestTheme(week).Id, EndsIn = math.max(0, Config.ContestWeekEnds(week) - t),
		EntryId = thisWeek and ct.id or nil, EntryStat = thisWeek and ct.stat or nil,
		EntrySince = thisWeek and Config.ContestSince(ct.value) or nil, -- (2026-11-17 first) เวลาส่ง วินาทีจากต้นสัปดาห์
		Entry = thisWeek and { Color = ct.color, Mut = ct.mut, Speed = ct.speed, Size = ct.size, Gold = ct.gold } or nil,
		Pending = ct ~= nil and ct.week < week and d.contestClaimed < ct.week,
		Rewards = Config.CONTEST_REWARDS, Participation = Config.CONTEST_PARTICIPATION_COINS,
	}
	local hall = {}
	for _, h in ipairs(d.hall) do
		table.insert(hall, { Color = h.color, Mut = h.mut, Speed = h.speed, Size = h.size, Gold = h.gold, Gen = h.gen, At = h.at })
	end
	info.Hall = hall
	info.HallBonus = ChickenData.HallBonus(d)
	info.HallMax = Config.HALL_MAX
	info.HallStep = Config.HALL_BONUS
	info.HallUnretirePrice = Config.HALL_UNRETIRE_PRICE -- นำออกจากหอ 2026-11-02
	if d.incubator then
		-- ไม่บอกลูกก่อนฟัก (เซอร์ไพรส์ตอนกดรับ)
		info.Incubator = { ReadyIn = math.max(0, d.incubator.readyAt - t), Premium = d.incubator.premium, FromEgg = d.incubator.fromEgg }
		-- พ่อแม่ไข่ผสม (เฉพาะตัวที่ยังอยู่ในเล้า) ให้หน้าตู้ฟัก/ไก่ของฉันบอกว่ากำลังผสม 2026-10-27
		if d.incubator.parents then
			local ps = {}
			for _, id in ipairs(d.incubator.parents) do
				if d.chickens[id] then table.insert(ps, id) end
			end
			info.Incubator.Parents = ps
		end
		if d.incubator.readyAt <= t then
			-- ฟักแล้ว = เปิดดูลูกได้ ให้เลือกรับเข้าเล้าหรือขาย (ผู้ใช้ขอ 2026-10-22)
			local ch = d.incubator.child
			info.Incubator.Child = { Color = ch.color, Speed = ch.speed, Size = ch.size, Gold = ch.gold, Mut = ch.mut, Gen = ch.gen,
				IsNew = not d.book[Config.BookKey(ch.color, ch.mut)], CanRetire = Config.CanRetire(ch) }
			info.HatchSellPrice = Config.SellPrice(ch) -- ตามระดับลูกไก่ (2026-10-25)
		end
	end
	return info
end

local function sync(player)
	if not player.Parent then return end
	local info = snapshot(player)
	-- หน้าส่งของขวัญ (VipGui) ใช้ดูว่าเพื่อนมีให้อาหารอัตโนมัติแล้วไหม (2026-10-23)
	if info.Passes then player:SetAttribute("ChickenAutoFeed", info.Passes.Feed == true) end
	if info.Dirt then player:SetAttribute("ChickenDirt", info.Dirt) end
	-- ป้าย "ใหม่!" ที่จุดวาร์ปฟาร์มไก่ + จุดแดง ☰ (WarpGui / MoreMenuGui) จนกว่าจะเปิดหน้าต่างไก่ครั้งแรก · มีไก่/สมุดอยู่แล้ว = ไม่ใช่คนใหม่ (2026-10-25)
	if info.Loaded then
		local st = ChickenData.Get(player)
		local d = st and st.data
		player:SetAttribute("ChickenNew", d ~= nil and not d.seen and (info.BookCount or 0) == 0 and #(info.Chickens or {}) == 0)
	end
	if info.DirtPiles then player:SetAttribute("ChickenDirtPiles", info.DirtPiles) end -- จำนวนกองดิน (ChickenYardClient) 2026-10-23 -- ป้าย 🧹 ที่ไม้กวาด + กองสกปรกในลาน (ChickenYardClient)
	syncRemote:FireClient(player, info)
end

local function reply(player, ok, message)
	return { ok = ok, message = message, info = snapshot(player) }
end

local function deepCopy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = type(v) == "table" and deepCopy(v) or v end
	return c
end

-- ทำการเปลี่ยนแปลงที่ต้องเซฟก่อน: change(d) แก้ข้อมูล -> เซฟ -> ไม่ได้ = คืนค่าเดิม · สำเร็จคืน true, nil, before (ไว้ให้ undoPaid)
-- strict (หรืออยู่ใน grantLocked) = ต้องเซฟจริงก่อนเสมอ (ของ Robux / ของขวัญ / รับรางวัล) รอช่วงเขียนได้ไม่เกิน 10 วิ
-- คำสั่งทั่วไปที่เพิ่งเซฟไปไม่ถึง 6 วิ = ทำเลยแล้วรวมเซฟตอนครบระยะ (กดรัวไม่ต่อคิว DataStore 2026-10-23)
local strictSave = {} -- [player] = true ระหว่าง grantLocked
local function commit(player, st, change, strict)
	local before = deepCopy(st.data)
	local result = change(st.data)
	if result == false then return false, "nochange" end
	if not (strict or strictSave[player]) and not ChickenData.CanWriteNow(player) then
		ChickenData.SaveLater(player)
		return true, nil, before
	end
	if not ChickenData.SaveNow(player, 10) then
		st.data = before
		return false, "save"
	end
	return true, nil, before
end

-- เหรียญลดระหว่างรอเซฟ (ของใหม่เซฟลงไปแล้ว): คืนข้อมูลก่อนคำสั่งทั้งหมด แล้วเซฟทับทันที (2026-10-22 เดิมแค่ MarkDirty = เซิร์ฟล่มใน 60 วิ ได้ของฟรี)
-- เซฟไม่ได้ = MarkDirty ให้รอบอัตโนมัติลองต่อ
local function undoPaid(player, st, before)
	st.data = before
	if not ChickenData.CanWriteNow(player) or not ChickenData.Save(player) then ChickenData.SaveLater(player) end
end

local SAVE_FAIL_TH, SAVE_FAIL_EN = "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง", "Saving failed, please try again"

local actions = {}
local giftSelect -- ส่งของไก่ให้เพื่อน (ตั้งค่าในส่วนของขวัญด้านล่าง) 2026-10-23

function actions.buyChicken(player, st)
	local d = st.data
	if ChickenData.ChickenCount(d) >= d.slots then
		return reply(player, false, msg(player, "ช่องเต็มแล้ว ซื้อช่องเพิ่มก่อน", "No free slot, buy another slot first"))
	end
	local coins = coinsOf(player)
	local price = Config.CHICKEN_PRICE
	if not coins or coins.Value < price then
		return reply(player, false, msg(player, "เหรียญไม่พอ (ต้องใช้ " .. price .. ")", "Not enough coins (need " .. price .. ")"))
	end
	local t = ChickenData.Now()
	local newId, isNew
	local ok, _, before = commit(player, st, function(data)
		newId = tostring(data.nextId)
		data.nextId += 1
		data.chickens[newId] = ChickenData.NewShopChicken(t)
		isNew = ChickenData.Discover(data, data.chickens[newId])
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if coins.Value < price then
		-- เหรียญลดระหว่างรอเซฟ: เอาไก่ + ช่องสมุดคืน
		undoPaid(player, st, before)
		return reply(player, false, msg(player, "เหรียญไม่พอ", "Not enough coins"))
	end
	player:SetAttribute("CoinSrc", "chicken:buyChicken")
	coins.Value -= price
	local c = st.data.chickens[newId]
	local color = Config.Colors[c.color]
	local xpNote = giveXP(player, isNew and Config.XP.NEW_BOOK or 0) -- ซื้อได้ XP เฉพาะช่องสมุดใหม่
	return reply(player, true, msg(player,
		string.format("🐔 ได้ไก่%s ไข่เร็ว★%d ไข่ใหญ่★%d ไข่ทอง★%d", color.Th, c.speed, c.size, c.gold) .. (isNew and " · 📖 สมุดไก่ช่องใหม่!" or ""),
		string.format("🐔 Got a %s chicken: speed★%d size★%d gold★%d", color.En, c.speed, c.size, c.gold) .. (isNew and " · 📖 New book entry!" or "")) .. xpNote)
end

function actions.buySlot(player, st)
	local price = Config.SlotPrice(st.data.slots)
	if not price then return reply(player, false, msg(player, "ช่องครบสูงสุดแล้ว", "Already at the maximum slots")) end
	local coins = coinsOf(player)
	if not coins or coins.Value < price then
		return reply(player, false, msg(player, "เหรียญไม่พอ (ต้องใช้ " .. price .. ")", "Not enough coins (need " .. price .. ")"))
	end
	local ok, _, before = commit(player, st, function(data) data.slots += 1 end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if coins.Value < price then
		undoPaid(player, st, before)
		return reply(player, false, msg(player, "เหรียญไม่พอ", "Not enough coins"))
	end
	player:SetAttribute("CoinSrc", "chicken:buySlot")
	coins.Value -= price
	return reply(player, true, msg(player, "🏠 เพิ่มช่องเลี้ยงไก่เป็น " .. st.data.slots .. " ช่อง", "🏠 Coop now has " .. st.data.slots .. " slots"))
end

function actions.deposit(player, st, which)
	-- {ดาว, จำนวน} = เทไม่เกินจำนวนที่กรอก (ป๊อปอัปกรอกจำนวน ผู้ใช้ขอ 2026-10-28) · ตัวเลขเดียว = เทเท่าที่รางรับได้เหมือนเดิม
	local limit = math.huge
	if type(which) == "table" then
		limit = math.floor(tonumber(which[2]) or 0)
		which = which[1]
		if limit < 1 then return reply(player, false, msg(player, "ใส่จำนวนอย่างน้อย 1 ถุง", "Enter at least 1 bag")) end
	end
	which = math.floor(tonumber(which) or 0)
	if which < 0 or which > 5 then return reply(player, false, "?") end
	local d = st.data
	local cap = ChickenData.TroughCap(d)
	local space = cap - ChickenData.TroughBags(d)
	if space <= 0 then
		return reply(player, false, msg(player, "รางอาหารเต็มแล้ว (" .. cap .. " ถุง)", "The trough is full (" .. cap .. " bags)"))
	end
	space = math.min(space, limit)
	local tools = foodInBag(player)
	-- ดาวสูงเติมก่อน (ไข่ดีกว่า) เมื่อเลือก "ทุกดาว"
	table.sort(tools, function(a, b) return (a:GetAttribute("Star") or 1) > (b:GetAttribute("Star") or 1) end)
	local plan, moved = {}, 0
	for _, tool in ipairs(tools) do
		local s = math.clamp(tool:GetAttribute("Star") or 1, 1, 5)
		if space <= 0 then break end
		if which == 0 or which == s then
			local have = math.max(0, math.floor(tool:GetAttribute("Count") or 1))
			local take = math.min(have, space)
			if take > 0 then
				table.insert(plan, { tool = tool, take = take, have = have, star = s })
				space -= take
				moved += take
			end
		end
	end
	if moved == 0 then
		return reply(player, false, msg(player, "ไม่มีถุงอาหารสัตว์ในกระเป๋า ทำได้ที่เครื่องทำอาหารสัตว์", "No pet food bags in your bag. Make them at the pet food machine"))
	end
	-- หักถุงออกจากกระเป๋าก่อนเซฟ (กันแฮก รอบ 1 2026-10-26: เดิมหักหลังเซฟจากจำนวนที่นับไว้ก่อน ระหว่างรอเซฟเครื่องให้อาหารสัตว์ใช้ถุงเดียวกัน = ถุงเพิ่มฟรี)
	-- เซฟไม่ได้ = คืนถุงเท่าที่หักไป (บวกเข้าจำนวนปัจจุบัน ไม่เขียนทับค่าเดิม)
	local lang = Localization.GetLanguage(player)
	for _, p in ipairs(plan) do
		local left = p.have - p.take
		p.parent = p.tool.Parent
		if left <= 0 then
			p.tool.Parent = nil
		else
			p.tool:SetAttribute("Count", left)
			p.tool.Name = ItemFactory.GetPetFoodName(p.star, left, lang)
		end
	end
	local ok = commit(player, st, function(data)
		for _, p in ipairs(plan) do data.trough[p.star] += p.take end
	end)
	if not ok then
		for _, p in ipairs(plan) do
			local now = p.tool.Parent and math.max(0, math.floor(p.tool:GetAttribute("Count") or 0)) or 0
			local back = now + p.take
			p.tool:SetAttribute("Count", back)
			p.tool.Name = ItemFactory.GetPetFoodName(p.star, back, lang)
			if not p.tool.Parent then
				local home = (p.parent and p.parent.Parent) and p.parent or player:FindFirstChildOfClass("Backpack")
				p.tool.Parent = home
			end
		end
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	for _, p in ipairs(plan) do
		if not p.tool.Parent then p.tool:Destroy() end
	end
	return reply(player, true, msg(player, "🥣 เทอาหารลงราง " .. moved .. " ถุง", "🥣 Added " .. moved .. " bags to the trough"))
end

-- นำถุงอาหารออกจากรางคืนกระเป๋า (ผู้ใช้ขอ 2026-10-28) which = ดาว 1-5, 0 = ทุกดาว · ถุงที่ไก่เปิดกินอยู่ (openUsed) อยู่ในรางต่อ
-- เซฟก่อนเสมอ (strict) แล้วค่อยให้ถุง: รวมเซฟทีหลังแล้วเซิร์ฟล่ม = ถุงในกระเป๋าเซฟไป แต่รางยังเป็นค่าเดิม = ถุงเพิ่มฟรี
-- มีสิทธิ์ให้อาหารอัตโนมัติและเปิดอยู่ = ปิดสวิตช์ให้ ไม่งั้นรอบ autoWork (30 วิ) เทถุงกลับลงรางทันที
function actions.withdraw(player, st, which)
	which = math.floor(tonumber(which) or 0)
	if which < 0 or which > 5 then return reply(player, false, "?") end
	local take, moved = {}, 0
	for s = 1, 5 do
		take[s] = (which == 0 or which == s) and st.data.trough[s] or 0
		moved += take[s]
	end
	if moved == 0 then
		return reply(player, false, msg(player, "ไม่มีถุงอาหารในรางให้นำออก", "No food bags in the trough to take out"))
	end
	-- 2026-11-18 กระเป๋ายังไม่มา (เกิดใหม่/กำลังออก) = ยังไม่แตะราง (เดิมเซฟรางลดก่อน ให้ถุงพัง = ถุงหาย แบบ PetFoodConverter)
	if not ItemFactory.FindBackpack(player) then
		return reply(player, false, msg(player, "กระเป๋ายังไม่พร้อม รอสักครู่แล้วลองใหม่", "Your bag isn't ready yet, please try again in a moment"))
	end
	local p = passOwned[player]
	local feedOff = ((p and p.feed) or st.data.giftFeed) and st.data.autoFeedOn
	local ok = commit(player, st, function(data)
		for s = 1, 5 do data.trough[s] -= take[s] end
		if feedOff then data.autoFeedOn = false end
	end, true)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	-- ให้ทีละดาว ให้ไม่ได้ (กระเป๋าหาย/ออกเกมระหว่างเซฟ) = คืนเข้ารางแล้วเซฟอีกรอบ
	local given, failErr = 0, nil
	for s = 1, 5 do
		if take[s] > 0 then
			local okGive, err = false, "player left"
			if player.Parent then okGive, err = pcall(ItemFactory.GivePetFood, player, s, take[s]) end
			if okGive then given += take[s] else
				st.data.trough[s] += take[s]
				failErr = failErr or err
			end
		end
	end
	if failErr then
		if not ChickenData.CanWriteNow(player) or not ChickenData.Save(player) then ChickenData.SaveLater(player) end
		warn(string.format("ChickenService: ให้ถุงอาหาร %s ไม่ครบ (ได้ %d/%d) คืนเข้ารางแล้ว: %s", player.Name, given, moved, tostring(failErr)))
		if given <= 0 then
			return reply(player, false, msg(player, "ใส่กระเป๋าไม่ได้ ถุงยังอยู่ในราง ลองใหม่อีกครั้ง", "Couldn't put the bags in your bag; they're still in the trough, please try again"))
		end
		moved = given
	end
	return reply(player, true, msg(player, "🥣 นำถุงอาหารออกจากราง " .. moved .. " ถุง ใส่กระเป๋าแล้ว", "🥣 Took " .. moved .. " bags out of the trough into your bag")
		.. (feedOff and msg(player, " · ปิดให้อาหารอัตโนมัติให้แล้ว (เปิดคืนได้ที่ลุงไข่ขายไก่)", " · Auto-feed turned off (turn it back on at the Chicken Merchant)") or ""))
end

function actions.sellEggs(player, st)
	local d = st.data
	local value, n = d.basket.value, ChickenData.BasketCount(d)
	local goldEggs = d.basket.gold
	if n <= 0 then return reply(player, false, msg(player, "แผงยังไม่มีไข่", "The egg tray is empty")) end
	local coins = coinsOf(player)
	if not coins then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local ok = commit(player, st, function(data)
		data.basket = { eggs = { 0, 0, 0, 0, 0 }, gold = 0, value = 0 }
		data.stats.sold += n
		data.stats.coins += value
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	coins.Value += value
	-- จดชื่อถ้าได้เงินจากไข่เยอะผิดปกติ
	local e = earned[player]
	if not e or os.clock() - e.t0 > 3600 then e = { t0 = os.clock(), coins = 0 } earned[player] = e end
	e.coins += value
	if e.coins > FLAG_COINS_PER_HOUR and not e.flagged then
		e.flagged = true
		CheatWatch.Flag(player, "ChickenEggs", string.format("ขายไข่ได้ %d เหรียญใน 1 ชั่วโมง", e.coins))
	end
	local xpNote = giveXP(player, (n - goldEggs) * Config.XP.EGG + goldEggs * Config.XP.GOLD_EGG, true)
	return reply(player, true, msg(player, string.format("🥚 ขายไข่ %d ฟอง ได้ %d เหรียญ", n, value), string.format("🥚 Sold %d eggs for %d coins", n, value)) .. xpNote)
end

-- ============ ช่วงที่ 3: ผสมพันธุ์ / ฟัก ============
local function seasonActive(id)
	return SeasonConfig.IsActive(id)
end

function actions.breed(player, st, arg)
	if LevelSystem.GetLevel(player) < Config.BREED_LEVEL then
		return reply(player, false, msg(player, "ผสมพันธุ์ได้ตั้งแต่เลเวล " .. Config.BREED_LEVEL, "Breeding unlocks at level " .. Config.BREED_LEVEL))
	end
	if type(arg) ~= "table" then return reply(player, false, "?") end
	local idA, idB = tostring(arg[1]), tostring(arg[2])
	local d = st.data
	local a, b = d.chickens[idA], d.chickens[idB]
	if not a or not b or idA == idB then
		return reply(player, false, msg(player, "เลือกไก่ 2 ตัวก่อน", "Pick two chickens first"))
	end
	local t = ChickenData.Now()
	if d.incubator then
		return reply(player, false, msg(player, "ตู้ฟักมีไข่อยู่แล้ว", "The incubator already has an egg"))
	end
	for _, c in ipairs({ a, b }) do
		if not ChickenData.IsAdult(c, t) then
			return reply(player, false, msg(player, "ลูกไก่ยังผสมไม่ได้ รอให้โตก่อน", "Chicks can't breed yet"))
		end
		if ChickenData.IsResting(c, t) then
			return reply(player, false, msg(player, "ไก่ตัวนี้ยังพักอยู่", "That chicken is still resting"))
		end
	end
	local bags = ChickenData.PickBreedBags(d)
	if not bags then
		return reply(player, false, msg(player, "ต้องมีอาหารในรางอย่างน้อย " .. Config.BREED_FOOD_BAGS .. " ถุง", "Needs at least " .. Config.BREED_FOOD_BAGS .. " bags in the trough"))
	end
	local coins = coinsOf(player)
	local price = Config.BREED_COST
	if not coins or coins.Value < price then
		return reply(player, false, msg(player, "เหรียญไม่พอ (ต้องใช้ " .. price .. ")", "Not enough coins (need " .. price .. ")"))
	end
	local premium = true
	for _, s in ipairs(bags) do if s < 5 then premium = false end end
	local child, usedPity = ChickenData.MakeChild(a, b, premium, d.pity, seasonActive)
	local ok, _, before = commit(player, st, function(data)
		for _, s in ipairs(bags) do data.trough[s] -= 1 end
		data.incubator = { readyAt = t + ChickenData.HatchSeconds(data), premium = premium, child = child, parents = { idA, idB } }
		data.chickens[idA].restUntil = t + Config.REST_SECONDS
		data.chickens[idB].restUntil = t + Config.REST_SECONDS
		data.pity = child.mut and 0 or math.min(Config.PITY, data.pity + 1)
		data.stats.bred += 1
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if coins.Value < price then
		-- เหรียญลดระหว่างรอเซฟ: ยกเลิกไข่ คืนอาหาร การันตี สถิติ (ทั้งหมดกลับเป็นก่อนผสม)
		undoPaid(player, st, before)
		return reply(player, false, msg(player, "เหรียญไม่พอ", "Not enough coins"))
	end
	player:SetAttribute("CoinSrc", "chicken:breed")
	coins.Value -= price
	local xpNote = giveXP(player, Config.XP.BREED)
	return reply(player, true, msg(player,
		"🥚 ได้ไข่ผสม 1 ใบ ใส่ตู้ฟักแล้ว ฟักใน " .. math.floor(ChickenData.HatchSeconds(st.data) / 60) .. " นาที" .. (premium and " (อาหารพิเศษ ✨)" or ""),
		"🥚 Bred an egg, it hatches in " .. math.floor(ChickenData.HatchSeconds(st.data) / 60) .. " min" .. (premium and " (premium food ✨)" or "")) .. xpNote)
end

-- ขายลูกที่ฟักแล้วทันทีไม่เข้าเล้า (ผู้ใช้ขอ 2026-10-22) ได้เท่าขายไก่ · ยังนับเข้าสมุดไก่และสถิติฟัก (ได้เห็นแล้ว) ไม่ต้องมีช่องว่าง
function actions.sellHatch(player, st)
	local d = st.data
	local inc = d.incubator
	if not inc then return reply(player, false, msg(player, "ตู้ฟักว่างอยู่", "The incubator is empty")) end
	if inc.readyAt > ChickenData.Now() then return reply(player, false, msg(player, "ยังฟักไม่เสร็จ", "Not hatched yet")) end
	local coins = coinsOf(player)
	if not coins then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local child = inc.child
	local isNewEntry
	local ok = commit(player, st, function(data)
		isNewEntry = ChickenData.Discover(data, child)
		data.incubator = nil
		data.stats.hatched += 1
		if child.mut then data.stats.muts += 1 end
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local price = Config.SellPrice(child) -- ตามระดับ (2026-10-25)
	coins.Value += price
	local xpNote = giveXP(player, Config.XP.HATCH + (isNewEntry and Config.XP.NEW_BOOK or 0))
	return reply(player, true, msg(player, "💰 ขายลูกไก่แล้ว ได้ " .. price .. " เหรียญ", "💰 Chick sold for " .. price .. " coins")
		.. (isNewEntry and msg(player, " · 📖 สมุดไก่ช่องใหม่!", " · 📖 New book entry!") or "") .. xpNote)
end

function actions.hatch(player, st)
	local d = st.data
	local inc = d.incubator
	local t = ChickenData.Now()
	if not inc then return reply(player, false, msg(player, "ตู้ฟักว่างอยู่", "The incubator is empty")) end
	if inc.readyAt > t then return reply(player, false, msg(player, "ยังฟักไม่เสร็จ", "Not hatched yet")) end
	if ChickenData.ChickenCount(d) >= d.slots then
		return reply(player, false, msg(player, "ช่องเต็ม ขายไก่หรือซื้อช่องเพิ่มก่อนรับลูกไก่", "No free slot — sell a chicken or buy a slot first"))
	end
	local child = inc.child
	local newId, isNewEntry
	local ok = commit(player, st, function(data)
		newId = tostring(data.nextId)
		data.nextId += 1
		data.chickens[newId] = ChickenData.NewChick(child, t)
		isNewEntry = ChickenData.Discover(data, data.chickens[newId])
		data.incubator = nil
		data.stats.hatched += 1
		if child.mut then data.stats.muts += 1 end
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local col = Config.Colors[child.color]
	local mutTh, mutEn = Config.MutationLabel(child.mut, true), Config.MutationLabel(child.mut, false)
	if child.mut and Config.ANNOUNCE_MUTATIONS[child.mut] then
		announce(string.format("🐣 %s ฟักได้ไก่ %s!", player.DisplayName, mutTh), string.format("🐣 %s hatched a %s chicken!", player.DisplayName, mutEn))
	end
	local xpNote = giveXP(player, Config.XP.HATCH + (isNewEntry and Config.XP.NEW_BOOK or 0))
	return reply(player, true, msg(player,
		string.format("🐣 ได้ลูกไก่%s%s เร็ว★%d ใหญ่★%d ทอง★%d", col.Th, mutTh and (" " .. mutTh) or "", child.speed, child.size, child.gold) .. (isNewEntry and " · 📖 สมุดไก่ช่องใหม่!" or ""),
		string.format("🐣 Hatched a %s chick%s speed★%d size★%d gold★%d", col.En, mutEn and (" " .. mutEn) or "", child.speed, child.size, child.gold) .. (isNewEntry and " · 📖 New book entry!" or "")) .. xpNote)
end

-- ฟักไข่จากแผงเก็บไข่ (ผู้ใช้ขอ 2026-10-22): ไข่ธรรมดา EGG_HATCH_COST ฟอง -> ตู้ฟัก ได้ลูกไก่แบบไก่ร้าน · ใช้ตู้เดียวกับผสมพันธุ์ (รับลูกด้วย "hatch" เดิม)
function actions.hatchEgg(player, st)
	if not Config.EGG_HATCH_ENABLED then -- ปิดไว้ 2026-10-29 (ผู้ใช้สั่ง)
		return reply(player, false, msg(player, "ฟักไข่จากแผงปิดอยู่", "Hatching tray eggs is turned off"))
	end
	local d = st.data
	if d.incubator then
		return reply(player, false, msg(player, "ตู้ฟักมีไข่อยู่แล้ว", "The incubator already has an egg"))
	end
	local cost = Config.EGG_HATCH_COST
	local t = ChickenData.Now()
	local child = ChickenData.EggChild()
	local ok, why = commit(player, st, function(data)
		if not ChickenData.TakeNormalEggs(data, cost) then return false end
		data.incubator = { readyAt = t + ChickenData.HatchSeconds(data), premium = false, fromEgg = true, child = child }
	end)
	if not ok then
		if why == "nochange" then
			return reply(player, false, msg(player, "ไข่ในแผงไม่พอ (ต้องใช้ " .. cost .. " ฟอง ไม่นับไข่ทอง)", "Not enough eggs in the tray (needs " .. cost .. ", gold eggs don't count)"))
		end
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	return reply(player, true, msg(player,
		"🥚 ใส่ไข่ " .. cost .. " ฟองเข้าตู้ฟักแล้ว ฟักใน " .. math.floor(ChickenData.HatchSeconds(st.data) / 60) .. " นาที",
		"🥚 Put " .. cost .. " eggs in the incubator, hatches in " .. math.floor(ChickenData.HatchSeconds(st.data) / 60) .. " min"))
end

-- ============ ช่วงที่ 4: รางวัลสมุด / ไก่โชว์ ============
function actions.claimBook(player, st, count)
	count = math.floor(tonumber(count) or 0)
	local reward
	for _, r in ipairs(Config.BOOK_REWARDS) do if r.Count == count then reward = r end end
	if not reward then return reply(player, false, "?") end
	local d = st.data
	if d.bookClaimed[tostring(count)] then return reply(player, false, msg(player, "รับรางวัลนี้ไปแล้ว", "Already claimed")) end
	if ChickenData.BookCount(d) < count then
		return reply(player, false, msg(player, "เก็บสมุดให้ครบ " .. count .. " ช่องก่อน", "Collect " .. count .. " entries first"))
	end
	local coins = coinsOf(player)
	if not coins then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local ok = commit(player, st, function(data) data.bookClaimed[tostring(count)] = true end, true)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	coins.Value += reward.Coins
	return reply(player, true, msg(player, "📖 รางวัลสมุดไก่ " .. count .. " ช่อง: +" .. reward.Coins .. " เหรียญ", "📖 Book reward (" .. count .. "): +" .. reward.Coins .. " coins"))
end

-- สลับไก่ขึ้นลานโชว์รัว = เซิร์ฟสร้างโมเดลบนแท่นใหม่ทุกครั้ง → เว้น SHOWCASE_GAP วิ (กันแฮก รอบ 1 2026-10-26)
local SHOWCASE_GAP = 3
lastShowcase = {} -- [player] = os.clock() (ประกาศไว้ด้านบน)
function actions.showcase(player, st, id)
	if lastShowcase[player] and os.clock() - lastShowcase[player] < SHOWCASE_GAP then
		return reply(player, false, msg(player, "รอสักครู่ก่อนสลับไก่โชว์อีกครั้ง", "Wait a moment before switching the show chicken again"))
	end
	lastShowcase[player] = os.clock()
	local d = st.data
	id = id and tostring(id) or ""
	if id ~= "" and not d.chickens[id] then return reply(player, false, "?") end
	local newValue = id ~= "" and id ~= d.showcase and id or nil
	d.showcase = newValue -- ไม่เกี่ยวกับเงิน/ของ เซฟรอบอัตโนมัติได้
	ChickenData.MarkDirty(player)
	player:SetAttribute("ChickenShowcaseChanged", os.clock())
	return reply(player, true, newValue and msg(player, "⭐ ตั้งไก่ตัวนี้โชว์ที่ลานโชว์แล้ว", "⭐ This chicken is now on the show yard")
		or msg(player, "เอาไก่ลงจากลานโชว์แล้ว", "Removed from the show yard"))
end

-- ============ ช่วงที่ 5: อัปเกรด / สวิตช์ของอัตโนมัติ / คูปองฟักทันที ============
function actions.upgrade(player, st, id)
	local u = type(id) == "string" and Config.UPGRADES[id]
	if not u then return reply(player, false, "?") end
	if u.RobuxOnly then
		return reply(player, false, msg(player, "อัปเกรดนี้ซื้อด้วย Robux เท่านั้น", "This upgrade is Robux only"))
	end
	local lv = st.data.upg[id]
	local nextLv = u.Levels[lv + 1]
	if not nextLv then return reply(player, false, msg(player, "อัปเกรดสูงสุดแล้ว", "Already maxed")) end
	local coins = coinsOf(player)
	if not coins or coins.Value < nextLv.Cost then
		return reply(player, false, msg(player, "เหรียญไม่พอ (ต้องใช้ " .. nextLv.Cost .. ")", "Not enough coins (need " .. nextLv.Cost .. ")"))
	end
	local ok, _, before = commit(player, st, function(data) data.upg[id] = lv + 1 end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if coins.Value < nextLv.Cost then
		undoPaid(player, st, before)
		return reply(player, false, msg(player, "เหรียญไม่พอ", "Not enough coins"))
	end
	player:SetAttribute("CoinSrc", "chicken:upgrade")
	coins.Value -= nextLv.Cost
	return reply(player, true, msg(player, u.Icon .. " " .. u.Th .. " เลเวล " .. (lv + 1) .. "!", u.Icon .. " " .. u.En .. " level " .. (lv + 1) .. "!"))
end

function actions.toggle(player, st, which)
	local d = st.data
	if which == "feed" then d.autoFeedOn = not d.autoFeedOn
	elseif which == "sell" then d.autoSellOn = not d.autoSellOn
	elseif which == "machine" then d.autoFeedMachine = not d.autoFeedMachine
	else return reply(player, false, "?") end
	ChickenData.MarkDirty(player)
	local on
	if which == "feed" then on = d.autoFeedOn elseif which == "machine" then on = d.autoFeedMachine else on = d.autoSellOn end
	return reply(player, true, on and msg(player, "เปิดแล้ว", "Turned on") or msg(player, "ปิดแล้ว", "Turned off"))
end

-- 🧹 ตั้ง % ทำความสะอาดอัตโนมัติ (arg = ค่าใน AUTO_CLEAN_STEPS, 0 = ปิด) 2026-10-28 · สกปรกเกินค่าใหม่อยู่แล้ว = สะอาดทันที
function actions.autoClean(player, st, at)
	local d = st.data
	at = tonumber(at)
	if not at or not table.find(Config.AUTO_CLEAN_STEPS, at) then return reply(player, false, "?") end
	d.autoCleanAt = at
	local now = ChickenData.AutoCleanAt(d)
	if now and d.dirt >= now then d.dirt = 0 end
	ChickenData.MarkDirty(player)
	if at > 0 then
		return reply(player, true, msg(player, "🧹 ทำความสะอาดอัตโนมัติเมื่อสกปรก " .. at .. "%", "🧹 Auto-clean at " .. at .. "% dirty"))
	end
	return reply(player, true, msg(player, "🧹 ปิดทำความสะอาดอัตโนมัติ", "🧹 Auto-clean off"))
end

-- ใช้คูปองฟักทันทีที่มีอยู่ (ซื้อไว้ตอนตู้ว่าง)
function actions.useHatchToken(player, st)
	local d = st.data
	local t = ChickenData.Now()
	if not d.incubator or d.incubator.readyAt <= t then return reply(player, false, msg(player, "ไม่มีไข่ที่กำลังฟัก", "No egg is hatching")) end
	if d.hatchTokens <= 0 then return reply(player, false, msg(player, "ไม่มีคูปองฟักทันที", "No instant-hatch coupons")) end
	local ok = commit(player, st, function(data)
		data.hatchTokens -= 1
		data.incubator.readyAt = t
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	return reply(player, true, msg(player, "⚡ ไข่ฟักแล้ว! กดรับลูกไก่ได้เลย", "⚡ Hatched! Take your chick"))
end

-- ไก่ที่ส่งประกวดสัปดาห์นี้ถูกขาย/ปลดเกษียณ = ถอนออกจากประกวด (ผู้ใช้สั่ง 2026-10-27 กันได้ทั้งเงิน/โบนัสหอและรางวัลประกวด)
-- สัปดาห์ก่อน (รอกดรับรางวัล) ไม่แตะ จบผลไปแล้ว · ลบจากป้ายอันดับ = withdrawContest (ประกาศตัวจริงในส่วนประกวด)
local withdrawContest
local function contestEntryOf(d, id)
	local ct = d.contest
	return (ct and ct.id == id and ct.week == Config.ContestWeek(ChickenData.Now())) and ct or nil
end
local function withdrawNote(player, entry)
	return entry and msg(player, " · ถอนออกจากประกวดแล้ว", " · withdrawn from the contest") or ""
end

function actions.sellChicken(player, st, id)
	id = tostring(id)
	if not st.data.chickens[id] then return reply(player, false, "?") end
	local price = Config.SellPrice(st.data.chickens[id]) -- ตามระดับ (2026-10-25) คิดก่อนลบไก่
	local coins = coinsOf(player)
	if not coins then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local entry = contestEntryOf(st.data, id)
	local ok = commit(player, st, function(data)
		data.chickens[id] = nil
		if data.showcase == id then data.showcase = nil end
		if entry and data.contest == entry then data.contest = nil end
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if carrying[player] and carrying[player].id == id then carrying[player].tool:Destroy() end -- ขายตัวที่อุ้มอยู่
	if entry then withdrawContest(player, st, entry.week) end
	coins.Value += price
	return reply(player, true, msg(player, "ขายไก่แล้ว ได้ " .. price .. " เหรียญ", "Chicken sold for " .. price .. " coins") .. withdrawNote(player, entry))
end

-- ============ ช่วงที่ 6: ประกวดไก่รายสัปดาห์ + หอเกียรติยศ (ผู้ใช้ OK 2026-10-22) ============
-- อันดับสัปดาห์ละ 1 ร้าน: OrderedDataStore "ChickenContest_v1_w<สัปดาห์>" คีย์ = UserId ค่า = คะแนน × 1,000,000 + (ส่งเร็ว = มากกว่า)
-- Studio เขียนร้านแยก "ChickenContestDev_v1_w..." กันผลทดสอบไปโผล่ในอันดับจริง
-- รับรางวัล: สัปดาห์ถัดไปกดรับ ดูอันดับจาก 10 อันดับแรกของสัปดาห์นั้น · เซฟว่ารับแล้วก่อน ค่อยให้เหรียญ/ตั๋ว (ตั๋วมีเลขอ้างอิง ให้ซ้ำไม่ได้)
local DataStoreService = game:GetService("DataStoreService")
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local IS_STUDIO = game:GetService("RunService"):IsStudio()

local function contestStore(week)
	return DataStoreService:GetOrderedDataStore((IS_STUDIO and "ChickenContestDev_v1_w" or "ChickenContest_v1_w") .. week)
end

local function contestValue(stat, t, week)
	local sinceStart = t - (Config.ContestWeekEnds(week) - Config.CONTEST_WEEK_SECONDS)
	return stat * 1000000 + math.clamp(Config.CONTEST_WEEK_SECONDS - 1 - sinceStart, 0, 999999)
end

local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] then return nameCache[userId] end
	local p = Players:GetPlayerByUserId(userId)
	local name = p and p.DisplayName
	if not name then
		local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		name = ok and n or ("#" .. userId)
	end
	nameCache[userId] = name
	return name
end

local boardCache = {} -- [week] = { at, top = { { userId, value } } }
local function contestTop(week, maxAge)
	local c = boardCache[week]
	if c and os.clock() - c.at < maxAge then return c.top, true end
	local ok, pages = pcall(function() return contestStore(week):GetSortedAsync(false, 10) end)
	if not ok then
		warn("ChickenService: โหลดอันดับประกวดไม่ได้: " .. tostring(pages))
		return c and c.top or {}, c ~= nil
	end
	local top = {}
	for _, e in ipairs(pages:GetCurrentPage()) do
		table.insert(top, { userId = tonumber(e.key) or 0, value = e.value })
	end
	boardCache[week] = { at = os.clock(), top = top }
	return top, true
end

local function writeContest(player, st)
	local ct = st.data.contest
	if not ct then return true end
	local ok, err = pcall(function() contestStore(ct.week):SetAsync(tostring(player.UserId), ct.value) end)
	if ok then
		st.contestWritten = ct.week .. ":" .. ct.value
		boardCache[ct.week] = nil
	else
		warn("ChickenService: เขียนอันดับประกวดไม่ได้ " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

-- ลบชื่อออกจากป้ายอันดับสัปดาห์นั้น (เซฟ d.contest = nil แล้ว = กดรับรางวัลสัปดาห์นั้นไม่ได้อยู่แล้ว ลบไม่ติดแค่ชื่อค้างบนป้าย)
function withdrawContest(player, st, week)
	st.contestWritten = nil
	boardCache[week] = nil
	local ok, err = pcall(function() contestStore(week):RemoveAsync(tostring(player.UserId)) end)
	if not ok then warn("ChickenService: ถอนชื่อออกจากอันดับประกวดไม่ได้ " .. player.Name .. ": " .. tostring(err)) end
end

function actions.contestEnter(player, st, id)
	id = tostring(id)
	local d = st.data
	local c = d.chickens[id]
	if not c then return reply(player, false, "?") end
	local t = ChickenData.Now()
	if not ChickenData.IsAdult(c, t) then
		return reply(player, false, msg(player, "ลูกไก่ยังส่งประกวดไม่ได้ รอให้โตก่อน", "Chicks can't enter yet"))
	end
	local week = Config.ContestWeek(t)
	local cur = d.contest
	if cur and cur.week < week and d.contestClaimed < cur.week then
		return reply(player, false, msg(player, "รับรางวัลสัปดาห์ก่อนก่อน (หน้า 🏆 ประกวด)", "Claim last week's reward first (🏆 Contest)"))
	end
	local theme = Config.ContestTheme(week)
	if cur and cur.week == week and cur.id == id then
		if st.contestWritten ~= cur.week .. ":" .. cur.value then writeContest(player, st) end -- ครั้งก่อนเขียนไม่ติด = ลองใหม่
		return reply(player, true, msg(player, "ไก่ตัวนี้ส่งประกวดอยู่แล้ว", "This chicken is already entered"))
	end
	local stat = Config.ContestStat(theme.Id, c, id) -- id = เลข # ไก่ (หัวข้อ lowid/highid 2026-11-17)
	local value = contestValue(stat, t, week)
	-- (2026-11-17 first) หัวข้อส่งเร็วที่สุด: เปลี่ยนไก่กลางสัปดาห์ = เก็บเวลาส่งครั้งแรกไว้ ไม่เสียลำดับ
	if theme.Id == "first" and cur and cur.week == week and cur.value then value = cur.value end
	local ok = commit(player, st, function(data)
		data.contest = {
			week = week, id = id, color = c.color, speed = c.speed, size = c.size, gold = c.gold, mut = c.mut,
			stat = stat, value = value,
		}
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if not writeContest(player, st) then
		return reply(player, true, msg(player, "🏆 ส่งแล้ว แต่ป้ายอันดับยังอัปเดตไม่ได้ กดส่งตัวเดิมอีกครั้งทีหลัง", "🏆 Entered, but the ranking didn't update — press again later"))
	end
	return reply(player, true, msg(player,
		"🏆 ส่งไก่ #" .. id .. " ประกวด \"" .. theme.Th .. "\" แล้ว!",
		"🏆 Chicken #" .. id .. " entered \"" .. theme.En .. "\"!"))
end

function actions.contestClaim(player, st)
	local d = st.data
	local cur = d.contest
	local week = Config.ContestWeek(ChickenData.Now())
	if not cur or cur.week >= week or d.contestClaimed >= cur.week then
		return reply(player, false, msg(player, "ยังไม่มีรางวัลให้รับ", "No reward to claim"))
	end
	local top, ok = contestTop(cur.week, 60)
	if not ok then return reply(player, false, msg(player, "โหลดผลประกวดไม่ได้ ลองใหม่อีกครั้ง", "Couldn't load the results, try again")) end
	local rank
	for i, e in ipairs(top) do
		if e.userId == player.UserId then rank = i end
	end
	local r = Config.ContestReward(rank)
	local gain = r and r.Coins or Config.CONTEST_PARTICIPATION_COINS
	-- 2026-11-01 รางวัลเป็นคูปองฟักไข่ทันที เซฟพร้อมกับที่บอกว่ารับแล้ว (ครั้งเดียว ไม่ได้ซ้ำ ไม่หาย)
	local hatch = r and r.HatchTokens or 0
	local coins = coinsOf(player)
	if not coins then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local claimedWeek = cur.week
	local okSave = commit(player, st, function(data)
		data.contestClaimed = claimedWeek
		if hatch > 0 then data.hatchTokens = math.min(9999, data.hatchTokens + hatch) end
	end, true)
	if not okSave then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	CheatWatch.AllowCoinGain(player, gain) -- รางวัลหลักแสน-ล้าน ไม่ใช่เหรียญขึ้นเร็วผิดปกติ
	coins.Value += gain
	local ticketNote = hatch > 0 and msg(player, " + คูปองฟักไข่ทันที " .. hatch .. " ใบ ⚡", " + " .. hatch .. " instant-hatch coupons ⚡") or ""
	if rank and r then
		if rank == 1 then
			announce(string.format("🏆 %s ชนะประกวดไก่สัปดาห์ที่แล้ว!", player.DisplayName), string.format("🏆 %s won last week's chicken contest!", player.DisplayName))
		end
		return reply(player, true, msg(player, "🏆 อันดับ " .. rank .. "! ได้ " .. gain .. " เหรียญ", "🏆 Rank " .. rank .. "! +" .. gain .. " coins") .. ticketNote)
	end
	return reply(player, true, msg(player, "🎀 ขอบคุณที่ร่วมประกวด ได้ " .. gain .. " เหรียญ", "🎀 Thanks for entering! +" .. gain .. " coins"))
end

-- ป้ายอันดับในหน้า 🏆 (สัปดาห์นี้ 10 อันดับ + สับดาห์ก่อน 3 อันดับ) ไม่ผ่านคิวคำสั่ง แคช 60 วิ
local boardAsked = {} -- [player] = os.clock()
local function contestBoard(player)
	if boardAsked[player] and os.clock() - boardAsked[player] < 2 then return nil end
	boardAsked[player] = os.clock()
	local week = Config.ContestWeek(ChickenData.Now())
	local function rows(list, n)
		local out = {}
		for i, e in ipairs(list) do
			if i > n then break end
			table.insert(out, { Rank = i, Name = nameOf(e.userId), Stat = e.value // 1000000, Since = Config.ContestSince(e.value), Me = e.userId == player.UserId })
		end
		return out
	end
	local top = contestTop(week, 60)
	local last = contestTop(week - 1, 600)
	return {
		Week = week, ThemeId = Config.ContestTheme(week).Id, Top = rows(top, 10),
		LastThemeId = Config.ContestTheme(week - 1).Id, Last = rows(last, 3),
	}
end

function actions.retire(player, st, id)
	id = tostring(id)
	local d = st.data
	local c = d.chickens[id]
	if not c then return reply(player, false, "?") end
	if not ChickenData.IsAdult(c) then return reply(player, false, msg(player, "ลูกไก่ยังปลดเกษียณไม่ได้", "Chicks can't retire")) end
	if not Config.CanRetire(c) then
		return reply(player, false, msg(player, "ต้องได้ 5 ดาวครบทั้ง 3 ค่าก่อน", "Needs 5 stars in all three stats"))
	end
	if #d.hall >= Config.HALL_MAX then
		return reply(player, false, msg(player, "หอเกียรติยศเต็มแล้ว (" .. Config.HALL_MAX .. " ตัว)", "The Hall of Fame is full (" .. Config.HALL_MAX .. ")"))
	end
	local t = ChickenData.Now()
	local entry = contestEntryOf(d, id)
	local ok = commit(player, st, function(data)
		data.chickens[id] = nil
		if data.showcase == id then data.showcase = nil end
		if entry and data.contest == entry then data.contest = nil end
		table.insert(data.hall, { color = c.color, speed = c.speed, size = c.size, gold = c.gold, mut = c.mut, gen = c.gen, at = t })
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if carrying[player] and carrying[player].id == id then carrying[player].tool:Destroy() end
	if entry then withdrawContest(player, st, entry.week) end
	player:SetAttribute("ChickenShowcaseChanged", os.clock())
	local pct = math.floor(ChickenData.HallBonus(st.data) * 100 + 0.5)
	local xpNote = giveXP(player, c.fromHall and 0 or Config.XP.RETIRE) -- ตัวที่เคยนำออกจากหอ = ไม่ได้ XP ซ้ำ
	return reply(player, true, msg(player,
		"🏛 ไก่ #" .. id .. " เข้าหอเกียรติยศแล้ว! ไข่ขายได้ +" .. pct .. "% ถาวร",
		"🏛 Chicken #" .. id .. " joined the Hall of Fame! Eggs sell for +" .. pct .. "% forever") .. withdrawNote(player, entry) .. xpNote)
end

-- 🏛→🐔 นำไก่ออกจากหอเกียรติยศ (ผู้ใช้ขอ 2026-11-02) arg = { ลำดับในหอ, at } (at กันกดผิดตัวตอนลำดับเลื่อน)
-- เล้าต้องว่าง 1 ช่อง · เซฟก่อนแล้วค่อยหักเหรียญ (แบบ buySlot) · ได้ไก่โตค่าเดิม เลขใหม่ ไม่ต้องพัก · โบนัสหอลดตามจำนวนที่เหลือ
function actions.unretire(player, st, arg)
	if type(arg) ~= "table" then return reply(player, false, "?") end
	local index, at = tonumber(arg[1]), tonumber(arg[2])
	local d = st.data
	local h = index and d.hall[index]
	if not h or h.at ~= at then
		return reply(player, false, msg(player, "ไม่พบไก่ตัวนี้ในหอเกียรติยศ", "That chicken isn't in the Hall of Fame"))
	end
	if ChickenData.ChickenCount(d) >= d.slots then
		return reply(player, false, msg(player, "เล้าเต็มแล้ว ซื้อช่องเพิ่มหรือขายไก่ก่อน", "Your coop is full, buy a slot or sell a chicken first"))
	end
	local price = Config.HALL_UNRETIRE_PRICE or 0
	local coins = coinsOf(player)
	if not coins or coins.Value < price then
		return reply(player, false, msg(player, "เหรียญไม่พอ (ต้องใช้ " .. price .. ")", "Not enough coins (need " .. price .. ")"))
	end
	local t = ChickenData.Now()
	local newId
	local ok, _, before = commit(player, st, function(data)
		table.remove(data.hall, index)
		newId = tostring(data.nextId)
		data.nextId += 1
		data.chickens[newId] = {
			color = h.color, speed = h.speed, size = h.size, gold = h.gold, mut = h.mut,
			born = t, adultAt = t, restUntil = 0, gen = h.gen or 0,
			nextEgg = t + Config.EggSeconds(h.speed), fromHall = true,
		}
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if coins.Value < price then
		undoPaid(player, st, before)
		return reply(player, false, msg(player, "เหรียญไม่พอ", "Not enough coins"))
	end
	player:SetAttribute("CoinSrc", "chicken:unretire")
	coins.Value -= price
	local pct = math.floor(ChickenData.HallBonus(st.data) * 100 + 0.5)
	return reply(player, true, msg(player,
		"🐔 ไก่กลับเข้าเล้าแล้ว (ไก่ #" .. newId .. ") · หอเกียรติยศเหลือ +" .. pct .. "%",
		"🐔 Back in the coop (chicken #" .. newId .. ") · Hall of Fame bonus now +" .. pct .. "%"))
end

-- ============ อุ้มไก่ (ผู้ใช้ขอ 2026-10-21) ============
-- ไก่ที่อุ้ม = Tool "IsHeldChicken" ในช่องไอเทม (แบบแก้วเครื่องดื่ม) คนอื่นเห็นในมือ · ไม่เซฟลงกระเป๋า (InventorySystem ไม่รู้จัก = ข้าม)
-- ไก่ตัวนั้นหายจากลานระหว่างอุ้ม (CarriedId ใน snapshot) · วางลง/ตาย/ออกเกม/ขายไก่ = Tool หาย -> กลับไปเดินในลาน
local HELD_SCALE = 0.75
local buildHeldModel -- ประกาศด้านล่าง
local PICKUP_RANGE = 25 -- ต้องยืนใกล้ลาน (วัดจากขอบ YardArea)

local function yardArea()
	local node = workspace
	for _, name in ipairs(Config.YARD_PATH) do node = node and node:FindFirstChild(name) end
	return node and node:FindFirstChild("YardArea")
end

-- range = ระยะจากขอบ YardArea (ไม่ใส่ = PICKUP_RANGE)
local function nearYard(player, range)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local area = yardArea()
	if not (root and area) then return false end
	-- 2026-11-11: YardArea เป็นวงกลม (Cylinder นอนแบน รัศมี = Size.Y/2) → วัดระยะจากขอบวง
	if area:IsA("Part") and area.Shape == Enum.PartType.Cylinder then
		local d = Vector3.new(root.Position.X - area.Position.X, 0, root.Position.Z - area.Position.Z).Magnitude
		return math.max(0, d - math.min(area.Size.Y, area.Size.Z) / 2) <= (range or PICKUP_RANGE)
	end
	local rel = area.CFrame:PointToObjectSpace(root.Position)
	local dx = math.max(0, math.abs(rel.X) - area.Size.X / 2)
	local dz = math.max(0, math.abs(rel.Z) - area.Size.Z / 2)
	return math.sqrt(dx * dx + dz * dz) <= (range or PICKUP_RANGE)
end

local Looks = require(ReplicatedStorage:WaitForChild("ChickenLooks"))
local chickenTemplate = ReplicatedStorage:WaitForChild("ChickenTemplates"):WaitForChild("Chicken")

-- โมเดลไก่ในมือ (สร้างใหม่ได้ตอนอุ้มอยู่) · ลูกไก่ = เล็กกว่า จด Attribute "Chick" ไว้ให้ลูปด้านล่างขยายตอนโต (2026-10-26)
function buildHeldModel(tool, c)
	local handle = tool:FindFirstChild("Handle")
	local old = tool:FindFirstChild("HeldChicken")
	if old then old:Destroy() end
	local chick = (c.adultAt or 0) > ChickenData.Now()
	local model = chickenTemplate:Clone()
	model.Name = "HeldChicken"
	Looks.Paint(model, c.color, c.mut)
	model:ScaleTo(chick and HELD_SCALE * 0.6 or HELD_SCALE)
	-- ตัวไก่อยู่หน้ามือ หันหน้าออกไปทางเดียวกับผู้เล่น
	model:PivotTo(handle.CFrame * CFrame.Angles(0, math.pi, 0))
	local gems = model:FindFirstChild("MutGems") -- 💎 เม็ดหมุนไม่เชื่อมกับมือ (คง Anchored) เครื่องผู้เล่นขยับด้วย Looks.Orbit 2026-11-05
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and not (gems and p:IsDescendantOf(gems)) then
			p.Anchored = false
			p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = handle, p
			w.Parent = p
		end
	end
	model.Parent = tool
	tool:SetAttribute("Chick", chick or nil)
end

local function makeHeldTool(player, id, c)
	local col = Config.Colors[c.color] or {}
	local tool = Instance.new("Tool")
	tool.Name = "🐔 " .. msg(player, "ไก่" .. (col.Th or ""), (col.En or "") .. " chicken")
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = msg(player, "คลิกเพื่อวางไก่ลงลาน", "Click to put the chicken back")
	tool:SetAttribute("IsHeldChicken", true)
	tool:SetAttribute("ChickenId", id)
	tool:SetAttribute("ChickenLook", c.color)
	tool:SetAttribute("Mut", c.mut)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 0.4)
	handle.Transparency = 1
	handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
	handle.Massless = true
	handle.Parent = tool
	buildHeldModel(tool, c)
	tool.Grip = CFrame.new(0, -0.1, 0.55) -- ดันไก่มาข้างหน้าเล็กน้อย
	return tool
end

local function dropCarried(player)
	local cur = carrying[player]
	if cur and cur.tool.Parent then cur.tool:Destroy() end
	carrying[player] = nil
end

function actions.pickup(player, st, id)
	id = tostring(id)
	local c = st.data.chickens[id]
	if not c then return reply(player, false, "?") end
	if not nearYard(player) then return reply(player, false, msg(player, "เข้าไปใกล้ลานไก่ก่อน", "Get closer to the chicken yard")) end
	-- ถือไม้กวาดอยู่ในมือ = อุ้มไก่ไม่ได้ (ผู้ใช้สั่ง 2026-10-31) ฝั่งผู้เล่นซ่อนปุ่ม "อุ้มไก่" อยู่แล้ว ตรงนี้กันคำขอที่หลุดมา
	local held = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if held and held:GetAttribute("IsHeldBroom") then
		return reply(player, false, msg(player, "วางไม้กวาดก่อนค่อยอุ้มไก่", "Put the broom away before picking up a chicken"))
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return reply(player, false, "?") end
	if carrying[player] and carrying[player].id == id then return reply(player, true, nil) end
	dropCarried(player) -- อุ้มได้ทีละตัว: ตัวเก่ากลับลาน
	local tool = makeHeldTool(player, id, c)
	local entry = { id = id, tool = tool }
	carrying[player] = entry
	tool.Destroying:Connect(function()
		if carrying[player] == entry then
			carrying[player] = nil
			task.defer(sync, player)
		end
	end)
	tool.AncestryChanged:Connect(function(_, parent)
		-- ตาย (กระเป๋าเดิมหาย) = ไม่อยู่ในตัว/กระเป๋าผู้เล่นแล้ว
		if parent == nil and carrying[player] == entry then tool:Destroy() end
	end)
	tool.Parent = backpack
	return reply(player, true, nil)
end

-- ลูกไก่ที่อุ้มอยู่ถึงเวลาโต = ขยายโมเดลในมือเป็นไก่โต (ผู้ใช้แจ้ง 2026-10-26: อุ้มลูกไก่ใกล้โตแล้วกลายเป็นลูกไก่ตัวเล็กค้างในมือ)
task.spawn(function()
	while true do
		task.wait(1)
		for player, entry in pairs(carrying) do
			local tool = entry.tool
			if tool.Parent and tool:GetAttribute("Chick") then
				local st = ChickenData.Get(player)
				local c = st and st.loaded and st.data.chickens[entry.id]
				if c and c.adultAt <= ChickenData.Now() then
					buildHeldModel(tool, c)
					sync(player) -- หน้าต่างไก่ของฉันขึ้น "โตแล้ว" ด้วย
				end
			end
		end
	end
end)

function actions.putdown(player, st)
	if not carrying[player] then return reply(player, true, nil) end
	dropCarried(player)
	return reply(player, true, nil)
end

-- ============ 🧹 ถือไม้กวาดเดินกวาดกองดิน (ผู้ใช้ขอ 2026-10-23 แทนกด E ค้าง 3 วิ) ============
-- กด E ที่ไม้กวาดข้างเล้า = หยิบ / วางคืน (Tool "IsHeldBroom" แบบไก่ที่อุ้ม ไม่เซฟ คนอื่นเห็นในมือ)
-- กองดินในลาน = ความสกปรกช่วงละ DIRT_PER_PILE% (ChickenYardClient วาดฝั่งผู้เล่น) · ถือไม้กวาดคลิกใกล้กอง = "sweep" ทีละกอง
-- กวาด 1 ครั้ง = ความสกปรกลดลง 1 ส่วน (ส่วนเท่ากันตามจำนวนกองที่เหลือ) ได้เหรียญตามที่ลด (รวมทุกกอง = เท่าเดิม 5 เหรียญ/1%) · ต่ำกว่า CLEAN_MIN = สะอาด 0%
-- เดินออกห่างลาน / ตาย / ออกเกม = ไม้กวาดกลับที่เดิมเอง
local SWEEP_COOLDOWN = 0.8
local holdingBroom = {} -- [player] = Tool
local lastSweep = {} -- [player] = os.clock()

local function broomStand()
	local node = workspace
	for _, name in ipairs(Config.YARD_PATH) do node = node and node:FindFirstChild(name) end
	return node and node:FindFirstChild("CleanBroom")
end

local function makeBroomTool(player)
	local stand = broomStand()
	local stick = stand and stand:FindFirstChild("CleanAnchor")
	if not stick then return nil end
	local tool = Instance.new("Tool")
	tool.Name = "🧹 " .. msg(player, "ไม้กวาด", "Broom")
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = msg(player, "คลิกใกล้กองดินเพื่อกวาด", "Click near a dirt pile to sweep")
	tool:SetAttribute("IsHeldBroom", true)
	local handle = stick:Clone()
	handle.Name = "Handle"
	handle:ClearAllChildren()
	handle.Anchored = false
	handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
	handle.Massless = true
	handle.Parent = tool
	for _, p in ipairs(stand:GetChildren()) do
		if p:IsA("BasePart") and p ~= stick then
			local c = p:Clone()
			c:ClearAllChildren()
			c.Anchored = false
			c.CanCollide, c.CanTouch, c.CanQuery = false, false, false
			c.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = handle, c
			w.Parent = c
			c.Parent = tool
		end
	end
	-- จับด้ามฝั่งตรงข้ามขนไม้กวาด ปลายขนชี้ลงพื้นด้านหน้า (ด้ามยาวตามแกน X ของ CleanAnchor)
	local bristles = stand:FindFirstChild("Bristles")
	local side = bristles and stick.CFrame:PointToObjectSpace(bristles.Position).X >= 0 and 1 or -1
	tool:SetAttribute("BristleSide", side)
	tool.Grip = CFrame.new(-side * 2.1, 0, 0) * CFrame.Angles(0, 0, side * math.rad(90)) * CFrame.Angles(math.rad(-15), 0, 0) -- วัดใน Play: ขนไม้กวาดต่ำกว่าสะโพก ~3 สตั๊ด ห่างหน้า ~3.7
	return tool
end

local function dropBroom(player)
	local t = holdingBroom[player]
	holdingBroom[player] = nil
	if t and t.Parent then t:Destroy() end
end

function actions.takeBroom(player, st)
	local cur = holdingBroom[player]
	if cur and cur.Parent then return reply(player, true, nil) end
	if not nearYard(player) then return reply(player, false, msg(player, "เข้าไปใกล้เล้าก่อน", "Get closer to the coop")) end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = backpack and makeBroomTool(player)
	if not tool then return reply(player, false, "?") end
	holdingBroom[player] = tool
	tool.Destroying:Connect(function()
		if holdingBroom[player] == tool then
			holdingBroom[player] = nil
			task.defer(sync, player)
		end
	end)
	tool.AncestryChanged:Connect(function(_, parent)
		if parent == nil and holdingBroom[player] == tool then tool:Destroy() end
	end)
	tool.Parent = backpack
	return reply(player, true, nil)
end

function actions.returnBroom(player, st)
	dropBroom(player)
	return reply(player, true, nil)
end

-- เล้าสะอาด 0%: ไข่ฟองถัดไปที่คิดตอนสกปรก ดึงกลับมาเป็นเวลาปกติ (ไม่เร็วกว่าตอนนี้)
local function finishClean(data, t)
	data.dirt = 0
	data.dirtAt = t
	data.stats.cleaned += 1
	for _, c in pairs(data.chickens) do
		local normal = t + Config.EggSeconds(c.speed)
		if c.adultAt <= t and c.nextEgg > normal then c.nextEgg = normal end
	end
end

-- เซฟก่อน ค่อยให้เหรียญ (commit รวมเซฟถ้ากวาดรัวในช่วง 6 วิ)
function actions.sweep(player, st)
	local d = st.data
	local tool = holdingBroom[player]
	if not (tool and tool.Parent and tool.Parent == player.Character) then
		return reply(player, false, msg(player, "ถือไม้กวาดก่อน (หยิบที่ข้างเล้า)", "Hold the broom first (it's by the coop)"))
	end
	if d.dirt < Config.CLEAN_MIN then return reply(player, false, msg(player, "✨ เล้าสะอาดแล้ว", "✨ The coop is already clean")) end
	if not nearYard(player) then return reply(player, false, msg(player, "เข้าไปใกล้เล้าก่อน", "Get closer to the coop")) end
	if lastSweep[player] and os.clock() - lastSweep[player] < SWEEP_COOLDOWN then return reply(player, false, nil) end
	lastSweep[player] = os.clock()
	local coins = coinsOf(player)
	if not coins then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local step = Config.DIRT_PER_PILE
	local old = d.dirt
	local piles = math.max(1, math.ceil(old / step - 1e-6))
	local new = old * (piles - 1) / piles -- ทุกกองได้เท่ากัน (กองที่เหลือยัง = piles - 1 กองพอดี)
	if new < Config.CLEAN_MIN then new = 0 end
	local reward = math.floor(old * Config.CLEAN_COINS_PER_PCT) - math.floor(new * Config.CLEAN_COINS_PER_PCT)
	local t = ChickenData.Now()
	local ok = commit(player, st, function(data)
		if new == 0 then
			finishClean(data, t)
		else
			data.dirt = new
			data.dirtAt = t
		end
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if reward > 0 then coins.Value += reward end
	local xpNote = giveXP(player, Config.XP.SWEEP_PILE, true)
	local text
	if new == 0 then
		text = msg(player, "✨ เล้าสะอาดแล้ว! +" .. reward .. " เหรียญ" .. xpNote .. " · วางไม้กวาดคืนที่ข้างเล้า", "✨ Coop is clean! +" .. reward .. " coins" .. xpNote .. " · Put the broom back by the coop")
	else
		local left = math.ceil(new / step - 1e-6)
		text = msg(player, "🧹 +" .. reward .. " เหรียญ" .. xpNote .. " · เหลือ " .. left .. " กอง", "🧹 +" .. reward .. " coins" .. xpNote .. " · " .. left .. " piles left")
	end
	harvestNotify:FireClient(player, nil, nil, nil, text)
	return reply(player, true, nil)
end

-- เดินออกห่างลาน = ไม้กวาดกลับที่เดิม
task.spawn(function()
	while true do
		task.wait(2)
		for player, tool in pairs(holdingBroom) do
			if not player.Parent then
				dropBroom(player)
			elseif tool.Parent and not nearYard(player) then
				dropBroom(player)
				harvestNotify:FireClient(player, nil, nil, nil, msg(player, "🧹 วางไม้กวาดคืนที่เล้าแล้ว", "🧹 The broom went back to the coop"))
			end
		end
	end
end)


-- กันแฮก รอบ 1 (ผู้ใช้ OK 2026-10-26):
-- คำสั่งที่แตะเงิน/ข้อมูลไก่ต้องยืนใกล้ลาน (หน้าต่างเปิดจากป้ายที่ลานอยู่แล้ว ผู้เล่นปกติไม่เดือดร้อน) สคริปต์โกงสั่งจากที่อื่นไม่ได้
--   ไกลสุด = ป้ายลุงไข่ขายไก่ 21.4 สตั๊ดนอกขอบลาน + หน้าต่างปิดเองที่ 25 → 50 สตั๊ด · ให้อาหารอัตโนมัติ (autoWork) เรียกตรง ไม่ผ่านตรงนี้ = ทำงานได้ทุกที่เหมือนเดิม
local ACTION_RANGE = 50
local NEED_NEAR = {
	buyChicken = true, buySlot = true, deposit = true, withdraw = true, sellEggs = true, sellChicken = true, breed = true, hatch = true,
	sellHatch = true, hatchEgg = true, claimBook = true, showcase = true, upgrade = true, useHatchToken = true,
	contestEnter = true, contestClaim = true, retire = true, speedUp = true, speedUpCoins = true, unretire = true,
}
-- "info" คิดไข่ใหม่ทุกครั้ง ยิงรัว = เซิร์ฟหน่วง → ถี่กว่า INFO_GAP ตอบข้อมูลเดิมที่เก็บไว้
local INFO_GAP = 0.5
local infoAt, infoCache = {}, {}

local function handleRequest(player, action, arg)
	if type(action) ~= "string" then return nil end
	local st = ChickenData.Get(player)
	if action == "info" then
		local now = os.clock()
		if infoCache[player] and now - (infoAt[player] or 0) < INFO_GAP then return infoCache[player] end
		if st and st.loaded then ChickenData.Settle(st.data) end
		local r = reply(player, true, nil)
		infoAt[player], infoCache[player] = now, r
		return r
	end
	if action == "seen" then -- เปิดหน้าต่างไก่ครั้งแรก = เอาป้าย "ใหม่!" ออก (ไม่แตะเงิน/ของ เซฟรอบอัตโนมัติ)
		if st and st.loaded and not st.data.seen then
			st.data.seen = true
			ChickenData.MarkDirty(player)
			player:SetAttribute("ChickenNew", false)
		end
		return true
	end
	if action == "contestBoard" then
		if not (Config.Enabled and st and st.loaded) then return nil end
		return contestBoard(player)
	end
	if action == "giftSelect" then -- ผู้ซื้อไม่ต้องเลี้ยงไก่เองก็ส่งให้เพื่อนได้ (ไม่ผ่านเช็กเลเวล/ข้อมูลไก่ของผู้ซื้อ)
		if type(arg) ~= "table" then return { ok = false, message = "?" } end
		return giftSelect(player, arg[1], arg[2])
	end
	local handler = actions[action]
	if not handler then return nil end
	if not Config.Enabled then return reply(player, false, msg(player, "บ้านไก่ยังไม่เปิด", "The chicken coop is not open yet")) end
	if not levelOk(player) then
		return reply(player, false, msg(player, "ต้องเลเวล " .. Config.UNLOCK_LEVEL .. " ขึ้นไป", "Requires level " .. Config.UNLOCK_LEVEL))
	end
	if not (st and st.loaded) or player:GetAttribute("CoinsLoaded") ~= true then
		return reply(player, false, msg(player, "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง", "Still loading, please try again"))
	end
	if NEED_NEAR[action] and not nearYard(player, ACTION_RANGE) then
		return reply(player, false, msg(player, "เข้าไปใกล้ลานไก่ก่อน", "Get closer to the chicken yard"))
	end
	if busy[player] or (lastRequest[player] and os.clock() - lastRequest[player] < REQUEST_COOLDOWN) then
		return reply(player, false, msg(player, "ใจเย็นๆ รออีกนิดนะ", "Slow down a little"))
	end
	busy[player] = true
	lastRequest[player] = os.clock()
	ChickenData.Settle(st.data)
	local ok, result = pcall(handler, player, st, arg)
	busy[player] = nil
	if not ok then
		warn("ChickenService: " .. action .. " error: " .. tostring(result))
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	sync(player)
	return result
end
requestRemote.OnServerInvoke = handleRequest

-- ============ prompt ที่เล้า ============
local function hookPrompt()
	local node = workspace
	for _, name in ipairs(Config.YARD_PATH) do
		node = node and node:WaitForChild(name, 30)
	end
	if not node then return end
	-- ตำแหน่งลุงไข่ขายไก่ให้บทเรียน (TutorialGui ภารกิจ "ไปบ้านไก่") ชี้ได้แม้ลานยังไม่ stream ไปถึงเครื่องผู้เล่น
	local shopAnchor = node:FindFirstChild("ShopPromptAnchor", true)
	if shopAnchor and shopAnchor:IsA("BasePart") then ReplicatedStorage:SetAttribute("ChickenShopPos", shopAnchor.Position) end
	for promptName, mode in pairs({ CoopPrompt = "chickens", ShopPrompt = "shop", TroughPrompt = "trough", EggPrompt = "basket", IncubatorPrompt = "breed" }) do
		local prompt = node:FindFirstChild(promptName, true)
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = Config.Enabled
			prompt.Triggered:Connect(function(player)
				if not Config.Enabled then return end
				openRemote:FireClient(player, mode)
			end)
		else
			warn("ChickenService: ไม่เจอ " .. promptName .. " ในลานไก่")
		end
	end
	-- 🧹 ไม้กวาดข้างเล้า: กด E = หยิบไม้กวาด / ถืออยู่ = วางคืน (2026-10-23 เดิมกดค้าง 3 วิ = กวาดทีเดียว) ผ่าน handleRequest (ตรวจเลเวล/โหลด/คิว)
	local cleanPrompt = node:FindFirstChild("CleanPrompt", true)
	if cleanPrompt and cleanPrompt:IsA("ProximityPrompt") then
		cleanPrompt.Enabled = Config.Enabled
		cleanPrompt.HoldDuration = 0
		cleanPrompt.Triggered:Connect(function(player)
			if not Config.Enabled then return end
			local cur = holdingBroom[player]
			local res = handleRequest(player, (cur and cur.Parent) and "returnBroom" or "takeBroom")
			if type(res) == "table" and res.message then
				harvestNotify:FireClient(player, nil, nil, nil, res.message)
			end
		end)
	else
		warn("ChickenService: ไม่เจอ CleanPrompt ในลานไก่")
	end
end
task.spawn(hookPrompt)

-- ============ ช่วงที่ 5: Game Pass + สินค้า Robux ============
local MarketplaceService = game:GetService("MarketplaceService")
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))

-- Studio: workspace Attribute "DevChickenPasses" = true ทดสอบเหมือนมี Game Pass ทั้งสอง
local function devPasses()
	return game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevChickenPasses") == true
end

local function ownsPass(player, passId)
	if passId <= 0 then return false end
	for _ = 1, 3 do
		local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId) end)
		if ok then return owns end
		task.wait(2)
	end
	return false
end

-- 🧹 จำลงข้อมูลไก่ว่ามี Game Pass ให้อาหารจริง (ทำความสะอาดอัตโนมัติตอนออฟไลน์ใช้ค่านี้ เพราะตอนนั้นเช็ก Game Pass ไม่ได้) 2026-10-28
local function rememberCleanPass(player)
	local p = passOwned[player]
	local st = ChickenData.Get(player)
	if p and p.feedReal and st and st.loaded and not st.data.cleanPass then
		st.data.cleanPass = true
		ChickenData.MarkDirty(player)
		sync(player)
	end
end

local function checkPasses(player)
	local dev = devPasses()
	ChickenData.DevAutoClean = dev
	local realFeed = ownsPass(player, Config.AUTO_FEED_PASS_ID)
	passOwned[player] = {
		feed = dev or realFeed,
		feedReal = realFeed, -- ไม่นับ DevChickenPasses (ไม่จำ cleanPass ลงข้อมูลจริงจากสวิตช์ทดสอบ)
		sell = dev or ownsPass(player, Config.AUTO_SELL_PASS_ID),
	}
	rememberCleanPass(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then return end
	local p = passOwned[player] or {}
	if passId == Config.AUTO_FEED_PASS_ID and passId > 0 then p.feed, p.feedReal = true, true end
	if passId == Config.AUTO_SELL_PASS_ID and passId > 0 then p.sell = true end
	passOwned[player] = p
	rememberCleanPass(player)
	sync(player)
end)

-- ใบเสร็จ Robux ต้องรอคำสั่งที่กำลังเซฟอยู่ให้เสร็จก่อน (busy) ไม่งั้นคำสั่งนั้นเซฟล้ม = ย้อนข้อมูลทั้งก้อน ของที่ซื้อหายด้วย (2026-10-22)
-- คืน false ถ้ารอนานเกิน = Roblox ส่งใบเสร็จมาใหม่ทีหลัง
local function grantLocked(player, fn)
	local t0 = os.clock()
	while busy[player] do
		if os.clock() - t0 > 15 or not player.Parent then return false end
		task.wait(0.1)
	end
	busy[player] = true
	strictSave[player] = true
	local ok, result = pcall(fn)
	strictSave[player] = nil
	busy[player] = nil
	if not ok then
		warn("ChickenService grant error: " .. tostring(result))
		return false
	end
	return result
end

-- ⚡ ฟักทันที: ได้คูปอง 1 ใบ มีไข่กำลังฟัก = ใช้ทันที (เซฟก่อนยืนยันใบเสร็จ)
PurchaseRouter.Register(Config.INSTANT_HATCH_PRODUCT_ID, {
	name = "⚡ ฟักไข่ไก่ทันที",
	grant = function(player)
		local st = ChickenData.Get(player)
		if not (st and st.loaded) then return false end
		local used = false
		local ok = grantLocked(player, function()
			local t = ChickenData.Now()
			ChickenData.Settle(st.data, t)
			return (commit(player, st, function(data)
				if data.incubator and data.incubator.readyAt > t then
					data.incubator.readyAt = t
					used = true
				else
					data.hatchTokens += 1
				end
			end))
		end)
		if not ok then return false end
		harvestNotify:FireClient(player, nil, nil, nil, used and msg(player, "⚡ ไข่ฟักแล้ว! ไปรับลูกไก่ที่ตู้ฟักได้เลย", "⚡ Hatched! Get your chick at the incubator")
			or msg(player, "⚡ ได้คูปองฟักทันที 1 ใบ", "⚡ Got 1 instant-hatch coupon"))
		sync(player)
		return true
	end,
})

-- ⏩ เร่งเวลาไก่ (ผู้ใช้ขอ 2026-10-28) ไก่ 1 ตัวต่อการซื้อ 1 ครั้ง: ลูกไก่โตทันที / พ่อแม่หายพักทันที (ChickenData.SpeedUp)
-- Roblox ไม่บอกว่าซื้อให้ตัวไหน = จำไว้ตอนกด (speedPending ไม่เซฟ) · ใบเสร็จมาแต่ไม่รู้ตัว / ตัวนั้นโตหรือหายพักแล้ว / ถูกขาย = คูปอง 1 ใบ (เงินไม่หาย)
local SPEED_PROMPT_TIMEOUT = 120
local speedPending = {} -- [player] = { id = ไก่, at = os.clock() }
local function speedNote(player, kind, id)
	if kind == "grow" then
		return msg(player, "⏩ ลูกไก่ #" .. id .. " โตแล้ว! ออกไข่ได้เลย", "⏩ Chick #" .. id .. " is all grown up and laying!")
	end
	return msg(player, "⏩ ไก่ #" .. id .. " หายเหนื่อยแล้ว ผสมพันธุ์ได้เลย", "⏩ Chicken #" .. id .. " is rested and ready to breed")
end

local function grantSpeedUp(player)
	local st = ChickenData.Get(player)
	if not (st and st.loaded) then return false end
	local pend = speedPending[player]
	local kind, id
	local ok = grantLocked(player, function()
		local t = ChickenData.Now()
		ChickenData.Settle(st.data, t)
		return (commit(player, st, function(data)
			local c = pend and data.chickens[pend.id]
			kind = c and ChickenData.SpeedUp(c, t) or nil
			if kind then
				id = pend.id
			else
				data.speedTokens = math.min(9999, data.speedTokens + 1)
			end
		end))
	end)
	if not ok then return false end -- เซฟไม่ได้ = Roblox ส่งใบเสร็จมาใหม่ (จำตัวเดิมไว้)
	if speedPending[player] == pend then speedPending[player] = nil end
	harvestNotify:FireClient(player, nil, nil, nil, kind and speedNote(player, kind, id)
		or msg(player, "⏩ ได้คูปองเร่งเวลาไก่ 1 ใบ (ไก่ตัวที่เลือกไม่ต้องเร่งแล้ว) ใช้กับตัวอื่นได้ที่ตู้ฟัก", "⏩ Got 1 speed-up coupon (that chicken no longer needed it) — use it at the incubator"))
	sync(player)
	return true
end

PurchaseRouter.Register(Config.SPEEDUP_PRODUCT_ID, {
	name = "⏩ เร่งเวลาไก่",
	grant = grantSpeedUp,
})

-- ตู้แลกน้ำใจ (เหรียญช่วยเหลือ, OrchardService 2026-11-03): ServerScriptService.ChickenTokenGrant:Invoke(player, "hatch"|"speed", n)
--   = คูปองฟักทันที (hatchTokens) / เร่งเวลาไก่ (speedTokens) n ใบ · เซฟก่อน (grantLocked = strict) คืน true เมื่อบันทึกแล้ว · ฟาร์มไก่ปิด/ยังโหลดไม่เสร็จ = false
do
	local tokenGrant = game:GetService("ServerScriptService"):FindFirstChild("ChickenTokenGrant")
	if not tokenGrant then
		tokenGrant = Instance.new("BindableFunction")
		tokenGrant.Name = "ChickenTokenGrant"
		tokenGrant.Parent = game:GetService("ServerScriptService")
	end
	tokenGrant.OnInvoke = function(player, kind, n)
		if kind == "check" then -- ฟาร์มไก่โหลดเสร็จหรือยัง (SultanService เช็กก่อนจองโค้ด PK-)
			local st = ChickenData.Get(player)
			return st ~= nil and st.loaded == true
		end
		if kind == "checkFeed" then -- SultanService เช็กก่อนจองโค้ด FK- (2026-11-05): "loading" / "owned" = มีสิทธิ์แล้ว ไม่จองโค้ด / "ok"
			local st = ChickenData.Get(player)
			local p = passOwned[player]
			if not (st and st.loaded and p) then return "loading" end -- p = เช็ก Game Pass เสร็จแล้ว
			return (p.feed == true or st.data.giftFeed == true) and "owned" or "ok"
		end
		if kind == "feed" then -- ให้อาหารอัตโนมัติถาวร (ช่องเดียวกับของขวัญจากเพื่อน) เรียกซ้ำได้ไม่มีผลเพิ่ม
			local st = ChickenData.Get(player)
			if not (st and st.loaded) then return false end
			local ok = grantLocked(player, function()
				return (commit(player, st, function(data) data.giftFeed = true end))
			end)
			if not ok then return false end
			sync(player)
			return true
		end
		n = math.floor(tonumber(n) or 0)
		if n <= 0 or (kind ~= "hatch" and kind ~= "speed") then return false end
		local st = ChickenData.Get(player)
		if not (st and st.loaded) then return false end
		local ok = grantLocked(player, function()
			return (commit(player, st, function(data)
				if kind == "hatch" then
					data.hatchTokens = math.min(9999, data.hatchTokens + n)
				else
					data.speedTokens = math.min(9999, data.speedTokens + n)
				end
			end))
		end)
		if not ok then return false end
		sync(player)
		return true
	end
end

-- กด ⏩ ที่ไก่ 1 ตัว: มีคูปอง = ใช้เลย · ไม่มี = จำตัวไว้แล้วเปิดหน้าซื้อ (Studio + ID 0 หรือ Attribute DevSpeedSimulate = จำลองใบเสร็จ)
function actions.speedUp(player, st, id)
	if type(id) ~= "string" then return reply(player, false, "?") end
	local d = st.data
	local c = d.chickens[id]
	local t = ChickenData.Now()
	if not c then return reply(player, false, msg(player, "ไม่พบไก่ตัวนี้", "Chicken not found")) end
	if ChickenData.IsAdult(c, t) and not ChickenData.IsResting(c, t) then
		return reply(player, false, msg(player, "ไก่ตัวนี้ไม่ต้องเร่งแล้ว", "This chicken doesn't need speeding up"))
	end
	if d.speedTokens > 0 then
		local kind
		local ok = commit(player, st, function(data)
			kind = ChickenData.SpeedUp(data.chickens[id], t)
			data.speedTokens -= 1
		end)
		if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
		return reply(player, true, speedNote(player, kind, id) .. msg(player, " (ใช้คูปอง)", " (coupon used)"))
	end
	local pid = Config.SPEEDUP_PRODUCT_ID or 0
	local studioTest = IS_STUDIO and (pid == 0 or player:GetAttribute("DevSpeedSimulate") == true)
	if pid == 0 and not studioTest then return reply(player, false, msg(player, "เร็วๆ นี้ ✨", "Coming soon ✨")) end
	local pend = speedPending[player]
	if pend and os.clock() - pend.at < SPEED_PROMPT_TIMEOUT then
		return reply(player, false, msg(player, "กำลังทำรายการก่อนหน้าอยู่ รอสักครู่", "A previous purchase is still open, wait a moment"))
	end
	speedPending[player] = { id = id, at = os.clock() }
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantSpeedUp, player)
			if not (okGrant and res == true) then warn("ChickenService: จำลองเร่งเวลาไก่ไม่สำเร็จ: " .. tostring(res)) end
		end)
		return reply(player, true, "(Studio) " .. msg(player, "จำลองการซื้อ ⏩ เร่งเวลาไก่", "simulated ⏩ speed-up purchase"))
	end
	MarketplaceService:PromptProductPurchase(player, pid)
	return reply(player, true, msg(player, "เปิดหน้าชำระเงินแล้ว", "Payment opened"))
end

-- ⏩ เร่งเวลาไก่ด้วยเหรียญ (ผู้ใช้ขอ 2026-11-02) ไก่ 1 ตัว = Config.SPEEDUP_COIN_PRICE · เซฟก่อนแล้วค่อยหักเหรียญ เหมือน buySlot
function actions.speedUpCoins(player, st, id)
	if type(id) ~= "string" then return reply(player, false, "?") end
	local price = Config.SPEEDUP_COIN_PRICE or 0
	if price <= 0 then return reply(player, false, msg(player, "เร็วๆ นี้ ✨", "Coming soon ✨")) end
	local c = st.data.chickens[id]
	local t = ChickenData.Now()
	if not c then return reply(player, false, msg(player, "ไม่พบไก่ตัวนี้", "Chicken not found")) end
	if ChickenData.IsAdult(c, t) and not ChickenData.IsResting(c, t) then
		return reply(player, false, msg(player, "ไก่ตัวนี้ไม่ต้องเร่งแล้ว", "This chicken doesn't need speeding up"))
	end
	local coins = coinsOf(player)
	if not coins or coins.Value < price then
		return reply(player, false, msg(player, "เหรียญไม่พอ (ต้องใช้ " .. price .. ")", "Not enough coins (need " .. price .. ")"))
	end
	local kind
	local ok, _, before = commit(player, st, function(data)
		kind = ChickenData.SpeedUp(data.chickens[id], t)
		if not kind then return false end
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	if coins.Value < price then
		undoPaid(player, st, before)
		return reply(player, false, msg(player, "เหรียญไม่พอ", "Not enough coins"))
	end
	player:SetAttribute("CoinSrc", "chicken:speedUpCoins")
	coins.Value -= price
	return reply(player, true, speedNote(player, kind, id) .. msg(player, " (ใช้ 💰 ", " (paid 💰 ") .. price .. ")")
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if purchased or productId ~= Config.SPEEDUP_PRODUCT_ID then return end
	local p = Players:GetPlayerByUserId(userId)
	if p then speedPending[p] = nil end -- ปิดหน้าซื้อ = กดตัวใหม่ได้
end)

-- 🥚 ขยายแผงเก็บไข่ +1 ขั้น (Robux เท่านั้น) เซฟก่อนยืนยันใบเสร็จ · ตันแล้ว (หน้าจอไม่ให้กด) = ยืนยันแต่เตือนไว้ใน log
PurchaseRouter.Register(Config.EGG_TRAY_PRODUCT_ID, {
	name = "🥚 ขยายแผงเก็บไข่ +1 ขั้น",
	grant = function(player)
		local st = ChickenData.Get(player)
		if not (st and st.loaded) then return false end
		local maxLv = #Config.UPGRADES.basket.Levels
		local lv
		local ok = grantLocked(player, function()
			ChickenData.Settle(st.data)
			lv = st.data.upg.basket
			if lv >= maxLv then return true end
			return (commit(player, st, function(data) data.upg.basket = lv + 1 end))
		end)
		if not ok then return false end
		if lv >= maxLv then
			warn("ChickenService: " .. player.Name .. " ซื้อแผงไข่ตอนเต็มขั้นแล้ว (ยืนยันใบเสร็จไปแล้ว)")
			return true
		end
		harvestNotify:FireClient(player, nil, nil, nil, msg(player,
			"🥚 แผงเก็บไข่ใหญ่ขึ้น! เก็บได้ " .. Config.UpgradeValue("basket", lv + 1) .. " ฟอง",
			"🥚 Bigger egg tray! Holds " .. Config.UpgradeValue("basket", lv + 1) .. " eggs"))
		sync(player)
		return true
	end,
})

-- ============ 🎁 ส่งของไก่ให้เพื่อน (ผู้ใช้ขอ 2026-10-23) แบบ MountGift ============
-- ชนิด "feed" = ให้อาหารอัตโนมัติถาวร (data.giftFeed เหมือนมี Game Pass) · "hatch" = คูปองฟักทันที +1 (ส่งซ้ำได้)
-- DataStore "ChickenGift_v1": "inbox_<userId>" = { feed, hatch, feedDone, hatchDone, receipts, fromName } · "pending_<userId>_<kind>" = { to, toName, t }
-- ใบเสร็จ = ใส่กล่องจดหมายผู้รับ (กันซ้ำด้วย PurchaseId) → ผู้รับออนไลน์อยู่/เข้าเกมครั้งถัดไป ค่อยย้ายเข้าข้อมูลไก่ (จดว่าส่งแล้วก่อน เซฟไม่ได้ = คืนกล่อง)
-- Studio: ไอดีสินค้า 0 หรือ Attribute DevGiftSimulate บนผู้เล่น = จำลองจ่ายเงิน · DevGiftOffline = ส่งให้ UserId ที่ไม่อยู่ในเซิร์ฟได้
local giftStore = DataStoreService:GetDataStore("ChickenGift_v1")
local GIFT_KINDS = {
	feed = { productId = Config.AUTO_FEED_GIFT_PRODUCT_ID, th = "🤖 ให้อาหารไก่อัตโนมัติ", en = "🤖 Auto-feed chickens" },
	hatch = { productId = Config.INSTANT_HATCH_GIFT_PRODUCT_ID, th = "⚡ คูปองฟักทันที", en = "⚡ Instant-hatch coupon" },
}
local GIFT_PROMPT_TIMEOUT = 120
local giftPending = {} -- [player] = { [kind] = { to, toName, t } }
local giftPrompting = {} -- [player] = os.clock()
local giftDelivering = {}

local function readInbox(old)
	if type(old) ~= "table" then old = {} end
	for _, k in ipairs({ "feed", "hatch", "feedDone", "hatchDone" }) do
		old[k] = math.max(0, math.floor(tonumber(old[k]) or 0))
	end
	old.receipts = type(old.receipts) == "table" and old.receipts or {}
	return old
end

local function hasFeed(player)
	local st = ChickenData.Get(player)
	return (passOwned[player] and passOwned[player].feed == true) or (st and st.loaded and st.data.giftFeed == true) or false
end

-- ย้ายของจากกล่องจดหมายเข้าข้อมูลไก่ (ตอนโหลดเสร็จ / ตอนมีคนส่งมาขณะออนไลน์)
local function deliverGifts(player)
	if giftDelivering[player] then return end
	local st = ChickenData.Get(player)
	if not (st and st.loaded) then return end
	giftDelivering[player] = true
	local takeFeed, takeHatch, from = false, 0, nil
	local ok, err = pcall(function()
		giftStore:UpdateAsync("inbox_" .. player.UserId, function(old)
			takeFeed, takeHatch = false, 0
			if type(old) ~= "table" then return nil end
			local data = readInbox(old)
			from = data.fromName
			takeFeed = data.feed > data.feedDone
			takeHatch = data.hatch - data.hatchDone
			if not takeFeed and takeHatch <= 0 then return nil end
			data.feedDone, data.hatchDone = data.feed, data.hatch
			return data
		end)
	end)
	if not ok then
		warn("ChickenService: เช็กกล่องของขวัญไก่ " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
	elseif takeFeed or takeHatch > 0 then
		local granted = grantLocked(player, function()
			local cur = ChickenData.Get(player)
			if not (cur and cur.loaded) then return false end
			return (commit(player, cur, function(data)
				if takeFeed then data.giftFeed = true end
				if takeHatch > 0 then data.hatchTokens = math.min(9999, data.hatchTokens + takeHatch) end
			end))
		end)
		local fromText = tostring(from or "เพื่อน")
		if not granted then
			-- เซฟข้อมูลไก่ไม่ได้: คืนของเข้ากล่องจดหมาย (เข้าเกมครั้งถัดไปได้ใหม่)
			pcall(function()
				giftStore:UpdateAsync("inbox_" .. player.UserId, function(old)
					local data = readInbox(old)
					if takeFeed then data.feedDone = math.max(0, data.feed - 1) end
					data.hatchDone = math.max(0, data.hatchDone - takeHatch)
					return data
				end)
			end)
			warn("ChickenService: ให้ของขวัญไก่ " .. player.Name .. " ไม่สำเร็จ คืนเข้ากล่องจดหมาย")
		else
			if takeFeed then
				harvestNotify:FireClient(player, nil, nil, nil, msg(player,
					"🎁🤖 " .. fromText .. " ส่งให้อาหารไก่อัตโนมัติมาให้! รางเหลือน้อย = เทถุงอาหารจากกระเป๋าให้เอง (ถาวร)",
					"🎁🤖 " .. fromText .. " gifted you Auto-feed chickens! The trough refills from your bag (permanent)"))
			end
			if takeHatch > 0 then
				harvestNotify:FireClient(player, nil, nil, nil, msg(player,
					"🎁⚡ " .. fromText .. " ส่งคูปองฟักทันทีมาให้ " .. takeHatch .. " ใบ! ใช้ได้ที่ตู้ฟักไข่",
					"🎁⚡ " .. fromText .. " gifted you " .. takeHatch .. " instant-hatch coupon(s)! Use them at the incubator"))
			end
			print(string.format("🎁 ChickenGift: %s ได้ของขวัญจาก %s (feed=%s hatch=%d)", player.Name, fromText, tostring(takeFeed), takeHatch))
			sync(player)
		end
	end
	giftDelivering[player] = nil
end

local function grantGift(kind, buyer, receiptInfo)
	local pending = giftPending[buyer] and giftPending[buyer][kind]
	if not pending then
		local okRead, saved = pcall(function() return giftStore:GetAsync("pending_" .. buyer.UserId .. "_" .. kind) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("ChickenService: ใบเสร็จของขวัญไก่ (" .. kind .. ") ของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้")
		return false
	end
	local purchaseId = "gift_" .. tostring(receiptInfo.PurchaseId)
	local saved = false
	local ok, err = pcall(function()
		giftStore:UpdateAsync("inbox_" .. pending.to, function(old)
			local data = readInbox(old)
			if table.find(data.receipts, purchaseId) then saved = true return nil end
			data[kind] += 1
			data.fromName = buyer.DisplayName
			table.insert(data.receipts, purchaseId)
			while #data.receipts > 50 do table.remove(data.receipts, 1) end
			saved = true
			return data
		end)
	end)
	if not ok or not saved then
		warn("ChickenService: บันทึกของขวัญไก่ไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	if giftPending[buyer] then giftPending[buyer][kind] = nil end
	giftPrompting[buyer] = nil
	pcall(function() giftStore:RemoveAsync("pending_" .. buyer.UserId .. "_" .. kind) end)
	local toName = pending.toName or tostring(pending.to)
	local target = Players:GetPlayerByUserId(pending.to)
	if target then task.spawn(deliverGifts, target) end
	local g = GIFT_KINDS[kind]
	harvestNotify:FireClient(buyer, nil, nil, nil, msg(buyer,
		"🎁 ส่ง" .. g.th .. "ให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖",
		"🎁 Sent " .. g.en .. " to " .. toName .. ". Thanks for sharing 💖"))
	print("🎁 ChickenGift: " .. buyer.Name .. " ส่ง " .. kind .. " ให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
for kind, g in pairs(GIFT_KINDS) do
	PurchaseRouter.Register(g.productId, { name = "ของขวัญไก่ " .. kind, grant = function(buyer, receiptInfo) return grantGift(kind, buyer, receiptInfo) end })
end

giftSelect = function(player, kind, targetUserId)
	local g = type(kind) == "string" and GIFT_KINDS[kind]
	if not g then return { ok = false, message = "?" } end
	local studioTest = IS_STUDIO and (g.productId == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if g.productId == 0 and not studioTest then return { ok = false, message = msg(player, "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨", "Gifting isn't open yet, coming soon ✨") } end
	if type(targetUserId) ~= "number" or targetUserId ~= targetUserId then return { ok = false, message = "?" } end
	targetUserId = math.floor(targetUserId)
	if targetUserId == player.UserId then return { ok = false, message = msg(player, "ส่งให้ตัวเองไม่ได้ (ซื้อให้ตัวเองได้ที่ลุงไข่ขายไก่)", "You can't gift yourself (buy it at the Chicken Merchant)") } end
	local started = giftPrompting[player]
	if started and os.clock() - started < GIFT_PROMPT_TIMEOUT then
		return { ok = false, message = msg(player, "กำลังทำรายการก่อนหน้าอยู่ รอสักครู่", "A previous purchase is still open, wait a moment") }
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local toName
	if target then
		if not ChickenData.IsLoaded(target) then
			return { ok = false, message = msg(player, "ข้อมูลไก่ของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง", "Your friend's chicken data is still loading, try again") }
		end
		if kind == "feed" and hasFeed(target) then
			return { ok = false, message = msg(player, target.DisplayName .. " มีให้อาหารไก่อัตโนมัติแล้ว", target.DisplayName .. " already has Auto-feed") }
		end
		toName = target.DisplayName
	elseif IS_STUDIO and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId
	else
		return { ok = false, message = msg(player, "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว", "Your friend isn't in this server anymore") }
	end
	local pending = { to = targetUserId, toName = toName, t = os.time() }
	local okSave, err = pcall(function() giftStore:SetAsync("pending_" .. player.UserId .. "_" .. kind, pending, { player.UserId }) end)
	if not okSave then
		warn("ChickenService: จำผู้รับของขวัญไก่ไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = msg(player, "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง", "Saving isn't responding, try again") }
	end
	giftPending[player] = giftPending[player] or {}
	giftPending[player][kind] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, kind, player, { PurchaseId = "studio_" .. os.time() .. "_" .. math.random(1, 1e6), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("ChickenService: จำลองของขวัญไก่ไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) " .. msg(player, "จำลองการซื้อ", "simulated purchase") .. ": " .. msg(player, g.th, g.en) .. " → " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, g.productId)
	return { ok = true, message = msg(player, "เปิดหน้าชำระเงินแล้ว: ", "Payment opened: ") .. msg(player, g.th, g.en) .. " → " .. toName }
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if purchased then return end
	for kind, g in pairs(GIFT_KINDS) do
		if g.productId ~= 0 and productId == g.productId then
			local p = Players:GetPlayerByUserId(userId)
			if p then
				if giftPending[p] then giftPending[p][kind] = nil end
				giftPrompting[p] = nil
			end
		end
	end
end)

-- 🥫 กระเป๋า + hotbar ไม่มีถุง = ดึงถุงที่ทำเสร็จจากเครื่องทำอาหารสัตว์ (ผู้ใช้ขอ 2026-11-05)
-- ลำดับ: เครื่องหักถุง + เซฟ (PetFoodBridge) -> เติมราง + เซฟจริง (strict) -> เซฟไม่ได้ = คืนถุงเข้าเครื่อง · คืน จำนวนถุงที่ย้าย หรือ nil
local lastMachinePull = {} -- [player] = os.clock() ที่ดึงจากเครื่องสำเร็จครั้งล่าสุด (กันเขียน DataStore ถี่ตอนเครื่องทำทีละถุง)
local function pullFromMachine(player, st)
	local bridge = ServerScriptService:FindFirstChild("PetFoodBridge")
	local space = ChickenData.TroughCap(st.data) - ChickenData.TroughBags(st.data)
	if not bridge or space <= 0 then return nil end
	local okTake, bags = pcall(function() return bridge:Invoke("take", player, space) end)
	if not okTake or type(bags) ~= "table" then return nil end
	local moved = 0
	for s = 1, 5 do moved += bags[s] or 0 end
	if moved <= 0 then return nil end
	local ok = commit(player, st, function(data)
		for s = 1, 5 do data.trough[s] += bags[s] or 0 end
	end, true)
	if not ok then
		pcall(function() return bridge:Invoke("putBack", player, bags) end)
		return nil
	end
	lastMachinePull[player] = os.clock()
	return moved
end

-- ให้อาหาร/ขายไข่อัตโนมัติ (เรียกจากลูปทุก 30 วิ เฉพาะคนที่มี Game Pass และเปิดสวิตช์ไว้) ใช้คำสั่งเดียวกับปุ่ม = กฎการเซฟเดียวกัน
-- 2026-11-16 ผู้ใช้แจ้ง "ทำอาหารสัตว์เสร็จแล้วกดรับ เหมือนไม่เข้ากระเป๋า": ให้อาหารไก่อัตโนมัติดึงอาหารสัตว์จากกระเป๋า/เครื่องไปเทรางไก่
-- ระหว่างที่บทสัตว์เลี้ยง (LessonService) ยังไม่เสร็จ (Lesson_pet = TODO) พักการเติมรางไว้ ให้ผู้เล่นได้ถืออาหารไปป้อนสัตว์เอง · บทเสร็จ = ทำงานตามปกติ
local lessonCfg
do
	local module = ReplicatedStorage:FindFirstChild("LessonConfig")
	local okL, cfg = pcall(function() return module and require(module) end)
	if okL and type(cfg) == "table" then lessonCfg = cfg end
end
local function petLessonHold(player)
	if not (lessonCfg and lessonCfg.ENABLED) or (lessonCfg.Off and lessonCfg.Off.pet) then return false end
	if not (lessonCfg.Rewards and lessonCfg.Rewards.pet) or player:GetAttribute("LessonsLoaded") ~= true then return false end
	return (tonumber(player:GetAttribute("Lesson_pet")) or lessonCfg.TODO) == lessonCfg.TODO
end

local function autoWork(player, st)
	local p = passOwned[player]
	if not p then return end
	local d = st.data
	local feedLow = (p.feed or d.giftFeed) and d.autoFeedOn and ChickenData.TroughBags(d) < ChickenData.TroughCap(d) * Config.AUTO_FEED_BELOW
	-- บอกเครื่องทำอาหารให้เก็บถุงไว้ให้รางไก่ก่อน ยังไม่ส่งเข้าชามสัตว์ (PetFoodConverter)
	local lessonHold = feedLow and petLessonHold(player) -- บทสัตว์เลี้ยงยังไม่เสร็จ = ไม่แตะอาหารสัตว์ (2026-11-16)
	player:SetAttribute("ChickenTroughLow", (feedLow and d.autoFeedMachine and not lessonHold) and true or nil)
	if busy[player] then return end
	local worked = false
	busy[player] = true
	local ok, err = pcall(function()
		if feedLow and not lessonHold then
			local _, inBag = foodInBag(player)
			local any = 0
			for s = 1, 5 do any += inBag[s] end
			if any > 0 then
				local r = actions.deposit(player, st, 0)
				if r.ok then
					worked = true
					harvestNotify:FireClient(player, nil, nil, nil, "🤖 " .. tostring(r.message))
				end
			elseif d.autoFeedMachine and os.clock() - (lastMachinePull[player] or -math.huge) >= Config.AUTO_FEED_MACHINE_GAP then
				local moved = pullFromMachine(player, st)
				if moved then
					worked = true
					if ChickenData.TroughBags(st.data) >= ChickenData.TroughCap(st.data) * Config.AUTO_FEED_BELOW then player:SetAttribute("ChickenTroughLow", nil) end
					harvestNotify:FireClient(player, nil, nil, nil, "🤖 " .. msg(player, "🥣 เติมรางจากเครื่องทำอาหาร " .. moved .. " ถุง", "🥣 Added " .. moved .. " bags from the pet food maker"))
				end
			end
		end
		if Config.AUTO_SELL_ENABLED and p.sell and d.autoSellOn and ChickenData.BasketCount(d) >= ChickenData.BasketCap(d) * Config.AUTO_SELL_AT then
			local r = actions.sellEggs(player, st)
			if r.ok then
				worked = true
				harvestNotify:FireClient(player, nil, nil, nil, "🤖 " .. tostring(r.message))
			end
		end
	end)
	busy[player] = nil
	if not ok then warn("ChickenService autoWork: " .. tostring(err)) end
	if worked then sync(player) end
end

-- ============ ช่วงที่ 4: คะแนนป้ายอันดับ (OrderedDataStore "ChickenFarmRank_v1" คีย์ = UserId) หน้าตาป้ายดู ChickenBoard ============
-- คะแนน = สมุด × 1,000,000 + ไข่ทั้งหมด · Studio ไม่เขียน (คีย์ไก่ทดสอบไม่ใช่ของจริง)
local RunService = game:GetService("RunService")
local rankStore = game:GetService("DataStoreService"):GetOrderedDataStore("ChickenFarmRank_v1")
local RANK_WRITE_SECONDS = 120
local rankWritten = {} -- [userId] = คะแนนล่าสุดที่เขียน
local function writeRank(player)
	local st = ChickenData.Get(player)
	if not (st and st.loaded) or player.UserId <= 0 then return end
	if RunService:IsStudio() and workspace:GetAttribute("DevChickenKeyOverride") then return end
	local score = ChickenData.FarmScore(st.data)
	if score <= 0 or rankWritten[player.UserId] == score then return end
	local ok, err = pcall(function()
		rankStore:SetAsync(tostring(player.UserId), score)
	end)
	if ok then rankWritten[player.UserId] = score else warn("ChickenService: เขียนอันดับไม่สำเร็จ " .. player.Name .. ": " .. tostring(err)) end
end
task.spawn(function()
	while true do
		task.wait(RANK_WRITE_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do task.spawn(writeRank, player) end
	end
end)

-- ============ เข้า/ออก ============
local function onJoin(player)
	task.spawn(checkPasses, player)
	player.CharacterRemoving:Connect(function() dropCarried(player) task.defer(sync, player) end) -- ตาย/เกิดใหม่ = ไก่กลับลาน
	if ChickenData.Load(player) then
		sync(player)
		rememberCleanPass(player) -- checkPasses อาจเสร็จก่อนโหลดข้อมูล
		task.spawn(deliverGifts, player) -- ของขวัญที่เพื่อนส่งมาตอนออกเกม (2026-10-23)
	end
end

Players.PlayerAdded:Connect(function(player) task.spawn(onJoin, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onJoin, player) end

Players.PlayerRemoving:Connect(function(player)
	task.spawn(writeRank, player)
	ChickenData.Release(player)
	rankWritten[player.UserId] = nil
	busy[player], lastRequest[player], earned[player], passOwned[player] = nil, nil, nil, nil
	lastMachinePull[player] = nil
	speedPending[player] = nil
	if carrying[player] then carrying[player].tool:Destroy() carrying[player] = nil end
	dropBroom(player)
	lastSweep[player] = nil
	boardAsked[player] = nil
	infoAt[player], infoCache[player], lastShowcase[player] = nil, nil, nil
	giftPending[player], giftPrompting[player], giftDelivering[player] = nil, nil, nil
end)

game:BindToClose(function()
	local pending = 0
	for player, st in pairs(ChickenData.AllStates()) do
		if st.loaded then
			pending += 1
			task.spawn(function()
				ChickenData.Settle(st.data)
				ChickenData.Save(player)
				pending -= 1
			end)
		end
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 25 do task.wait(0.2) end
end)

-- ============ คิดไข่ระหว่างเล่น + เซฟอัตโนมัติ ============
task.spawn(function()
	while true do
		task.wait(SETTLE_EVERY)
		for player, st in pairs(ChickenData.AllStates()) do
			if st.loaded and player.Parent and not busy[player] then
				local laid = ChickenData.Settle(st.data)
				if laid > 0 then
					st.dirty = true
					sync(player)
				end
				if player:GetAttribute("CoinsLoaded") == true and player:GetAttribute("InventoryReady") == true then
					task.spawn(autoWork, player, st)
				end
				if st.dirty and os.clock() - st.lastSave >= AUTOSAVE_EVERY then
					ChickenData.SaveLater(player) -- เว้น 6 วิจากเซฟครั้งก่อนเอง
				end
			end
		end
	end
end)
