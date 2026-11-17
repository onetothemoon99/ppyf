-- BACKUP of ServerScriptService.Orchard.OrchardData before instant-grow (โตทันที 10 R$) 2026-11-16
-- Restore: paste this whole file (minus these 2 header lines) into the script Source in Studio.
-- OrchardData: ข้อมูลสวนผลไม้ของผู้เล่น โหลด/เซฟ (ไม่มี Remote ดู OrchardService) 2026-10-25
-- DataStore "Orchard_v1" คีย์ = UserId (Studio: workspace Attribute "DevOrchardKeyOverride" = คีย์ปลอม ห้ามใช้ UserId จริง)
-- skins = { [Id] = true } ลายแปลงที่ซื้อ · skin = ลายที่ใส่ (2026-10-28)
-- { v, slots, trees = { ["1".."5"] = { kind, plantedAt, cycleStart, fruits, stolen } }, stats = { harvested, sold, coins, stolenFrom, stole } }
--   เมล็ด/ผลไม้อยู่ในกระเป๋าปกติ (OrchardItems / InventorySystem) ไม่เก็บในข้อมูลสวน (2026-10-26 เลิก basket/seeds)
--   fruits = ผลที่จะได้ในรอบนี้ (สุ่มตอนเริ่มรอบ ขโมยสำเร็จ = ลดลง) · stolen = โดนขโมยไปกี่ครั้งในรอบนี้
--   harvests = เก็บไปแล้วกี่รอบ (ครบ OrchardConfig.Trees[kind].Harvests = ต้นหมดอายุ OrchardService ลบทิ้ง 2026-10-27)
--   dead = ต้นแห้ง (เก็บครบรอบ 2026-11-02) · revived = เพื่อนช่วยฟื้นไปแล้ว (ฟื้นได้ครั้งเดียว) · fed = cycleStart ที่ใส่ปุ๋ยไปแล้ว (รอบละ 1 ครั้ง)
-- help = { coins = เหรียญช่วยเหลือ, total = ช่วยไปกี่ครั้ง, day = วัน (UTC "YYYYMMDD"), today = ได้เหรียญวันนี้กี่ครั้ง, owners = { ["UserId"] = ช่วยคนนี้ไปกี่ครั้งวันนี้ } } (2026-11-02)
-- ต้นโตตามเวลาจริง (os.time) เลยโตต่อตอนออฟไลน์ ขั้นของต้นคิดจาก OrchardConfig.StageAt ไม่ต้องเก็บ
-- กันข้อมูลหาย: ไม่เซฟอะไรก่อนโหลดสำเร็จ (บทเรียน LevelSystem/InventorySystem)

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("OrchardConfig"))
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))

local OrchardData = {}

local store = DataStoreService:GetDataStore("Orchard_v1")
local states = {} -- [player] = { data, loaded, dirty, lastSave, lastWriteAt, saving, flushQueued }
local rng = Random.new()

local SAVE_GAP = 6.5 -- Roblox เขียนคีย์เดิมได้ 1 ครั้งต่อ 6 วิ

-- ทดสอบเป็นทีม (Team Test ก็ IsStudio = true) หลายคนใช้คีย์ปลอมร่วมกันไม่ได้ (เซฟทับกัน) 2026-10-30:
--   เจ้าของเกมใช้คีย์ปลอมเดิม · คนอื่น = คีย์ปลอม + _<UserId> ของตัวเอง (ไม่แตะข้อมูลจริง)
local function keyOf(player)
	if RunService:IsStudio() and workspace:GetAttribute("DevOrchardKeyOverride") then
		local key = "dev_" .. tostring(workspace:GetAttribute("DevOrchardKeyOverride"))
		if player.UserId ~= 9360333174 then key ..= "_" .. player.UserId end -- เจ้าของเกม One_moretime91 (เกมเป็นของกลุ่ม CreatorId ใช้ไม่ได้)
		return key
	end
	return tostring(player.UserId)
end

-- เวลา (unix วินาที) · Studio: workspace Attribute "DevOrchardTimeSkip" = บวกเวลาเพิ่ม (ทดสอบต้นโต)
function OrchardData.Now()
	local skip = RunService:IsStudio() and tonumber(workspace:GetAttribute("DevOrchardTimeSkip")) or 0
	return os.time() + skip
end

local function count(v, max)
	local n = math.floor(tonumber(v) or 0)
	if n ~= n or n == math.huge then return 0 end -- NaN / อนันต์
	return math.clamp(n, 0, max or 1e15)
end

local function rollFruits(kind)
	local def = Config.Trees[kind]
	return rng:NextInteger(def.FruitMin, def.FruitMax)
end

function OrchardData.Normalize(d, t)
	if type(d) ~= "table" then d = {} end
	t = t or OrchardData.Now()
	d.v = 1
	d.slots = math.clamp(count(d.slots), Config.START_TREES, Config.MAX_TREES)
	local trees = {}
	if type(d.trees) == "table" then
		for i = 1, Config.MAX_TREES do
			local tr = d.trees[tostring(i)]
			if type(tr) == "table" and Config.Trees[tr.kind] then
				local def = Config.Trees[tr.kind]
				local plantedAt = math.min(tonumber(tr.plantedAt) or t, t)
				trees[tostring(i)] = {
					kind = tr.kind,
					plantedAt = plantedAt,
					cycleStart = tonumber(tr.cycleStart) or (plantedAt + def.GrowSeconds),
					fruits = math.clamp(count(tr.fruits), 0, def.FruitMax),
					stolen = count(tr.stolen, 99),
					harvests = count(tr.harvests, 99),
					dead = tr.dead == true or nil,
					revived = tr.revived == true or nil,
					fed = tonumber(tr.fed),
				}
			end
		end
	end
	d.trees = trees
	-- ลายแปลงที่ซื้อแล้ว (2026-10-28) skins = { [Id] = true } · skin = Id ที่ใส่อยู่ (nil = Classic)
	local skins = {}
	if type(d.skins) == "table" then
		for id, v in pairs(d.skins) do
			if v == true and Config.HoleSkinById[id] then skins[id] = true end
		end
	end
	d.skins = skins
	if not (type(d.skin) == "string" and skins[d.skin]) then d.skin = nil end
	d.lot = (type(d.lot) == "string" and d.lot:match("^Lot%d+$")) and d.lot or nil -- ล็อกที่เลือกไว้ (ย้ายมา/ปลูกจอง 2026-11-06) เข้าเกมใหม่ล็อกนี้ว่าง = กลับมาที่เดิม
	d.basket, d.seeds = nil, nil -- ข้อมูลทดสอบเก่า (เฟส 2 รุ่นแรก มีแต่คีย์ปลอมใน Studio)
	local st = type(d.stats) == "table" and d.stats or {}
	d.stats = { harvested = count(st.harvested), sold = count(st.sold), coins = count(st.coins), stolenFrom = count(st.stolenFrom), stole = count(st.stole) }
	local h = type(d.help) == "table" and d.help or {}
	local owners = {}
	if type(h.owners) == "table" then
		-- จำนวนครั้งที่ช่วยเจ้าของคนนี้วันนี้ (2026-11-02 เดิมเก็บ true = 1 ครั้ง)
		for k, v in pairs(h.owners) do
			if tonumber(k) then
				local n = v == true and 1 or count(v, 999)
				if n > 0 then owners[tostring(k)] = n end
			end
		end
	end
	d.help = { coins = count(h.coins), total = count(h.total), day = type(h.day) == "string" and h.day or nil, today = count(h.today, 999), owners = owners }
	-- ตู้แลกน้ำใจ (2026-11-03): shop = { titles = { [Id] = true }, title = Id ที่ใส่อยู่, week = เลขสัปดาห์, buys = { [Id] = ซื้อไปกี่ครั้งสัปดาห์นี้ }, quota = ซื้อแปลงผักไปกี่ครั้ง (ตลอดกาล) }
	local sh = type(d.shop) == "table" and d.shop or {}
	local titles, buys, backs = {}, {}, {}
	if type(sh.titles) == "table" then
		for id, v in pairs(sh.titles) do
			local it = Config.HelpShopById[id]
			if v == true and it and it.Grant == "title" then titles[id] = true end
		end
	end
	-- ประดับหลัง (เฟส 2, 2026-11-03): backs = { [Id] = true }, back = Id ที่ใส่อยู่
	if type(sh.backs) == "table" then
		for id, v in pairs(sh.backs) do
			local it = Config.HelpShopById[id]
			if v == true and it and it.Grant == "back" then backs[id] = true end
		end
	end
	if type(sh.buys) == "table" then
		for id, v in pairs(sh.buys) do
			if Config.HelpShopById[id] and count(v, 999) > 0 then buys[id] = count(v, 999) end
		end
	end
	d.shop = { titles = titles, title = (type(sh.title) == "string" and titles[sh.title]) and sh.title or nil,
		week = tonumber(sh.week), buys = buys, quota = count(sh.quota, 99),
		backs = backs, back = (type(sh.back) == "string" and backs[sh.back]) and sh.back or nil }
	return d
end

-- ต้นใหม่ (ยังไม่ใส่ลง d)
function OrchardData.NewTree(kind, t)
	local def = Config.Trees[kind]
	assert(def, "OrchardData.NewTree: ไม่รู้จักต้น " .. tostring(kind))
	return { kind = kind, plantedAt = t, cycleStart = t + def.GrowSeconds, fruits = rollFruits(kind), stolen = 0, harvests = 0 }
end

-- เก็บผลแล้วเริ่มรอบใหม่ (เฟส 2 ใช้) คืนจำนวนผลที่ได้
function OrchardData.StartNewCycle(tree, t)
	local got = tree.fruits
	tree.cycleStart = t
	tree.fruits = rollFruits(tree.kind)
	tree.stolen = 0
	return got
end

-- วันนี้ (UTC) ไว้นับการช่วยต่อวัน · เปลี่ยนวัน = ล้างตัวนับของวันก่อน
function OrchardData.HelpToday(d)
	local day = os.date("!%Y%m%d", OrchardData.Now())
	if d.help.day ~= day then
		d.help.day, d.help.today, d.help.owners = day, 0, {}
	end
	return d.help
end

-- สัปดาห์ใหม่ = ล้างตัวนับซื้อต่อสัปดาห์ของตู้แลกน้ำใจ
function OrchardData.ShopWeek(d)
	local w = Config.WeekNumber(OrchardData.Now())
	if d.shop.week ~= w then d.shop.week, d.shop.buys = w, {} end
	return d.shop
end

function OrchardData.TreeCount(d)
	local n = 0
	for _ in pairs(d.trees) do n += 1 end
	return n
end

-- ช่องว่างช่องแรก (ภายใน slots) หรือ nil
function OrchardData.FreeSlot(d)
	for i = 1, d.slots do
		if not d.trees[tostring(i)] then return i end
	end
	return nil
end

-- ============ สถานะต่อผู้เล่น ============
function OrchardData.Get(player)
	return states[player]
end

function OrchardData.IsLoaded(player)
	local st = states[player]
	return st ~= nil and st.loaded == true
end

function OrchardData.Load(player)
	local st = { data = nil, loaded = false, dirty = false, lastSave = 0 }
	states[player] = st
	local ok, record = DataLoadRetry.Load(player, "Orchard", DataLoadRetry.Get(store, keyOf(player)), function()
		return states[player] == st
	end)
	if not ok or states[player] ~= st then return false end
	st.data = OrchardData.Normalize(record, OrchardData.Now())
	st.loaded = true
	st.lastSave = os.clock()
	player:SetAttribute("OrchardLoaded", true)
	return true
end

-- เซฟทันที คืน true/false (ไม่เซฟถ้ายังโหลดไม่สำเร็จ)
function OrchardData.Save(player)
	local st = states[player]
	if not (st and st.loaded) then return false end
	if RunService:IsStudio() and workspace:GetAttribute("DevOrchardFailSave") == true then
		warn("OrchardData: จำลองเซฟไม่สำเร็จ (DevOrchardFailSave)")
		return false
	end
	local data = st.data
	st.saving = true
	st.lastWriteAt = os.clock()
	st.dirty = false
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function()
			return data
		end)
	end)
	st.saving = false
	if ok then
		st.lastSave = os.clock()
	else
		st.dirty = true
		warn("OrchardData: เซฟไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function OrchardData.CanWriteNow(player)
	local st = states[player]
	if not st or st.saving then return false end
	return not st.lastWriteAt or os.clock() - st.lastWriteAt >= SAVE_GAP
end

-- รวมคำสั่งที่ติดกันเป็นเซฟเดียวตอนครบระยะ
function OrchardData.SaveLater(player)
	local st = states[player]
	if not (st and st.loaded) then return end
	st.dirty = true
	if st.flushQueued then return end
	st.flushQueued = true
	task.spawn(function()
		while states[player] == st and not OrchardData.CanWriteNow(player) do
			local left = st.lastWriteAt and (SAVE_GAP - (os.clock() - st.lastWriteAt)) or 0
			task.wait(math.max(left, 0.25))
		end
		st.flushQueued = false
		if states[player] == st and st.dirty then OrchardData.Save(player) end
	end)
end

-- รอจนเขียนได้ (ไม่เกิน maxWait วิ) แล้วเซฟเลย คืน true/false (ของมีค่า: ปลูก/เก็บ/ขโมย)
function OrchardData.SaveNow(player, maxWait)
	local st = states[player]
	if not (st and st.loaded) then return false end
	local deadline = os.clock() + (maxWait or 10)
	while not OrchardData.CanWriteNow(player) do
		if os.clock() > deadline or states[player] ~= st then return false end
		task.wait(0.25)
	end
	return OrchardData.Save(player)
end

-- ตอนออก: เซฟ (บอก DataLoadRetry ให้รอบใหม่รอเซฟนี้เสร็จก่อนโหลด)
function OrchardData.Release(player)
	local st = states[player]
	if st and st.loaded and st.dirty then
		DataLoadRetry.BeginLeaveSave(player.UserId)
		OrchardData.Save(player)
		DataLoadRetry.EndLeaveSave(player.UserId)
	end
	if states[player] == st then states[player] = nil end
end

function OrchardData.AllStates()
	return states
end

return OrchardData
