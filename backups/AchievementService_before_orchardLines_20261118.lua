-- BACKUP 2026-11-18: game.ServerScriptService.AchievementService (Script) before orchard lines help/steal (syncOrchard)
-- Restore: in Studio open ServerScriptService.AchievementService, replace its whole Source with everything below the "-- ===== SOURCE =====" line.
-- ===== SOURCE =====
-- AchievementService: นับยอดสะสมตลอดกาลแล้วมอบเหรียญตรา Roblox (2026-11-04) ค่าตัวเลขดู ReplicatedStorage.AchievementConfig
-- เรียก Achievement.Add(player, lineId, amount) จาก PlantingSystem.plantCrop และ FishingSystem (ผู้เล่นตกเอง + นากตกให้ ไม่นับขยะ)
-- DataStore "Achievement_v1": { c = { [lineId] = ยอดสะสม }, got = { [badgeId เป็นข้อความ] = true }, paid = { [badgeId] = true จ่ายรางวัลเหรียญแล้ว } } เซฟแบบ UpdateAsync เอาค่ามากสุด กันเซิร์ฟอื่นเขียนทับ
-- เซฟทุก 60 วิ + ตอนออก + ปิดเซิร์ฟ + ทันทีหลังได้ตรา · มอบตราไม่สำเร็จ = ลองใหม่ทุก AWARD_RETRY วิ และตอนเข้าเกมรอบหน้า
-- ยอดเกินเพดานต่อ WINDOW ไม่ถูกนับ + ลง CheatWatch เพราะตรา Roblox ดึงคืนไม่ได้
-- หมวด egg (2026-11-05): ไม่ใช้ Add เพราะไข่ออฟไลน์เข้ามาเป็นก้อนใหญ่จะชนเพดาน ลูปทุก 10 วิ ตั้งยอดตาม ChickenData stats.eggs แทน (ยอดที่เซิร์ฟเวอร์นับเอง ได้ยอดย้อนหลังด้วย) · ยังไม่มีหมวด egg ใน Config = ไม่ทำงาน
-- Studio: ใช้คีย์ปลอมเสมอ (ไม่แตะข้อมูลจริง) และจำลองการมอบตรา ถ้าจะมอบจริงตั้ง workspace Attribute DevAchievementRealAward = true
--   workspace Attribute DevAchievementKeyOverride = "<คีย์ปลอม>" เปลี่ยนคีย์ · DevAchievementAdd = "plant:10" เพิ่มยอดให้ทุกคนในเซิร์ฟ (เฉพาะ Studio)
--   Attribute บนผู้เล่น AchCount_<หมวด> (อัปเดตทุก 10 วิ) · AchGot = จำนวนตราที่ได้แล้ว

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("AchievementConfig"))
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))

-- PlantingSystem require โมดูลนี้ตอนเริ่ม: ห้ามรอของที่สคริปต์อื่นสร้าง (ค้าง = ปลูกผักทั้งเกมพัง) ไม่มีก็สร้างเองแบบสคริปต์อื่น
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end
-- บอกหน้าจอให้ขึ้นป๊อปอัปได้ตรา (ส่ง Badge ID, AchievementGui อ่านชื่อ/รูปจาก Config)
local earnedEvent = remoteEvents:FindFirstChild("AchievementEarned")
if not earnedEvent then
	earnedEvent = Instance.new("RemoteEvent")
	earnedEvent.Name = "AchievementEarned"
	earnedEvent.Parent = remoteEvents
end

-- หน้าต่าง AchievementGui ขอยอดและตราของตัวเอง
local request = remoteEvents:FindFirstChild("AchievementRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "AchievementRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("Achievement_v1")
local SAVE_EVERY = 60

local Achievement = {}
local states = {} -- [player] = { data, loaded, dirty, lastSave, queue, key, windows, awarding, retryAt, attrDirty }

local function keyOf(player)
	if RunService:IsStudio() then
		local override = workspace:GetAttribute("DevAchievementKeyOverride")
		-- UserId ติดลบ = ผู้เล่นปลอมของ Studio (Local Server Player1 = -1) ใช้คีย์ของตัวเอง ไม่ใช้คีย์ปลอมร่วม (2026-11-17 ทดสอบผู้เล่นใหม่)
		if type(override) == "string" and override ~= "" and player.UserId > 0 then return override end
		return "StudioTest_" .. tostring(player.UserId)
	end
	return tostring(player.UserId)
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.c = type(d.c) == "table" and d.c or {}
	d.got = type(d.got) == "table" and d.got or {}
	d.paid = type(d.paid) == "table" and d.paid or {}
	return d
end

local function save(player, st)
	st.lastSave = os.clock()
	local snapshot = st.data
	local ok, err = pcall(function()
		store:UpdateAsync(st.key, function(old)
			old = normalize(old)
			for id, n in pairs(snapshot.c) do old.c[id] = math.max(old.c[id] or 0, n) end
			for id in pairs(snapshot.got) do old.got[id] = true end
			for id in pairs(snapshot.paid) do old.paid[id] = true end
			return old
		end)
	end)
	if ok then st.dirty = false else warn("AchievementService: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

local function publish(player, st)
	if not player.Parent then return end
	for lineId in pairs(Config.Lines) do
		player:SetAttribute("AchCount_" .. lineId, st.data.c[lineId] or 0)
	end
	local got = 0
	for _ in pairs(st.data.got) do got += 1 end
	player:SetAttribute("AchGot", got)
	st.attrDirty = false
end

local function unpaid(st, tier)
	return (tier.coins or 0) > 0 and not st.data.paid[tostring(tier.id)]
end

-- ตราที่ถึงยอดแล้วแต่ยังไม่ได้ตราหรือยังไม่ได้เหรียญ เรียงตามหมวดแล้วจากขั้นต่ำไปสูง
local function pendingTiers(st)
	local out = {}
	for lineId, line in pairs(Config.Lines) do
		local n = st.data.c[lineId] or 0
		for _, tier in ipairs(line.Tiers) do
			if n >= tier.need and (not st.data.got[tostring(tier.id)] or unpaid(st, tier)) then
				table.insert(out, { line = line, tier = tier })
			end
		end
	end
	return out
end

-- มอบ 1 ตรา คืน true = ผู้เล่นมีตราแล้ว, isNew = เพิ่งได้รอบนี้
local function awardOne(player, tier)
	if RunService:IsStudio() and workspace:GetAttribute("DevAchievementRealAward") ~= true then
		print(string.format("🏅 AchievementService: จำลองมอบตรา %s (%d) ให้ %s", tier.th, tier.id, player.Name))
		return true, true
	end
	local okHas, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, tier.id) end)
	if not okHas then
		warn("AchievementService: เช็กตราไม่สำเร็จ: " .. tostring(has))
		return false, false
	end
	if has then return true, false end
	local okAward, awarded = pcall(function() return BadgeService:AwardBadgeAsync(player.UserId, tier.id) end)
	if not okAward or awarded ~= true then
		warn("AchievementService: มอบตราไม่สำเร็จ " .. tostring(tier.id) .. ": " .. tostring(awarded))
		return false, false
	end
	return true, true
end

-- จ่ายรางวัลเหรียญครั้งเดียว รอเหรียญโหลดก่อน (ไม่งั้นค่าโหลดทับรางวัล) คืน false = ยังจ่ายไม่ได้ ลองใหม่รอบหน้า
local function payCoins(player, st, tier)
	local waited = 0
	while player.Parent and not player:GetAttribute("CoinsLoaded") and waited < 30 do
		task.wait(1)
		waited += 1
	end
	if not player.Parent or player:GetAttribute("CoinsLoaded") ~= true then return false end
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("เหรียญ")
	if not coins then return false end
	st.data.paid[tostring(tier.id)] = true
	st.dirty = true
	CheatWatch.AllowCoinGain(player, tier.coins)
	coins.Value += tier.coins
	print(string.format("🏅 AchievementService: %s ได้รางวัล %d เหรียญ (%s)", player.Name, tier.coins, tier.th))
	return true
end

-- มอบทีละตราในเธรดเดียวต่อคน มาซ้ำระหว่างทำ = รอบนี้วนเก็บให้เองจนหมด
local function processAwards(player, st)
	if st.awarding or not st.loaded then return end
	st.awarding = true
	local failed = false
	while player.Parent and states[player] == st and not failed do
		local list = pendingTiers(st)
		if #list == 0 then break end
		local changed = false
		for _, item in ipairs(list) do
			if not player.Parent then break end
			local ok = true
			if not st.data.got[tostring(item.tier.id)] then
				local isNew
				ok, isNew = awardOne(player, item.tier)
				if ok then
					st.data.got[tostring(item.tier.id)] = true
					st.dirty = true
					changed = true
					if isNew then
						earnedEvent:FireClient(player, item.tier.id)
						print(string.format("🏅 AchievementService: %s ได้ตรา %s", player.Name, item.tier.th))
					end
				end
			end
			if ok and unpaid(st, item.tier) then
				if payCoins(player, st, item.tier) then changed = true else ok = false end
			end
			if not ok then failed = true end
		end
		if changed then
			publish(player, st)
			save(player, st)
		end
	end
	if failed then st.retryAt = os.clock() + Config.AWARD_RETRY else st.retryAt = nil end
	st.awarding = false
end

-- นับตามเพดานต่อ WINDOW คืนจำนวนที่นับจริง
local function allowed(player, st, lineId, amount)
	local w = st.windows[lineId]
	local now = os.clock()
	if not w or now - w.start >= Config.WINDOW then
		w = { start = now, n = 0, flagged = false }
		st.windows[lineId] = w
	end
	local cap = Config.WindowCap(lineId, player:GetAttribute("PlantLimit"))
	local take = math.max(0, math.min(amount, cap - w.n))
	w.n += take
	if take < amount and not w.flagged then
		w.flagged = true
		pcall(CheatWatch.Flag, player, "achievement_rate", string.format("%s เกิน %d ต่อ %d วิ", lineId, cap, Config.WINDOW))
	end
	return take
end

-- noCap = true เฉพาะ DevAchievementAdd ใน Studio (ไม่ผ่านเพดาน)
local function apply(player, st, lineId, amount, noCap)
	local line = Config.Lines[lineId]
	local take = noCap and amount or allowed(player, st, lineId, amount)
	if take <= 0 then return end
	local before = st.data.c[lineId] or 0
	local after = before + take
	st.data.c[lineId] = after
	st.dirty = true
	st.attrDirty = true
	for _, tier in ipairs(line.Tiers) do
		if before < tier.need and after >= tier.need then
			task.spawn(processAwards, player, st)
			break
		end
	end
end

-- ตั้งยอดสะสมจากยอดที่เซิร์ฟเวอร์นับเอง เพิ่มได้อย่างเดียว ไม่ผ่านเพดานต่อ WINDOW
local function setTotal(player, st, lineId, total)
	local line = Config.Lines[lineId]
	local before = st.data.c[lineId] or 0
	if not line or total <= before then return end
	st.data.c[lineId] = total
	st.dirty = true
	st.attrDirty = true
	for _, tier in ipairs(line.Tiers) do
		if before < tier.need and total >= tier.need then
			task.spawn(processAwards, player, st)
			break
		end
	end
end

-- ChickenData require ตอนใช้ครั้งแรก ไม่ require ตอนเริ่ม เพราะ PlantingSystem รอโมดูลนี้อยู่
local chickenData, chickenDataTried = nil, false
local function syncEggs(player, st)
	if not Config.Lines.egg then return end
	if not chickenDataTried then
		chickenDataTried = true
		local folder = ServerScriptService:FindFirstChild("ChickenFarm")
		local module = folder and folder:FindFirstChild("ChickenData")
		if module then
			local ok, result = pcall(require, module)
			if ok then chickenData = result else warn("AchievementService: โหลด ChickenData ไม่สำเร็จ: " .. tostring(result)) end
		end
	end
	if not chickenData or not chickenData.IsLoaded(player) then return end
	local record = chickenData.Get(player)
	local stats = record and record.data and record.data.stats
	local eggs = stats and tonumber(stats.eggs)
	if eggs then setTotal(player, st, "egg", math.floor(eggs)) end
end

-- หมวด level / time (2026-11-06): ตั้งยอดตามเลเวลและชั่วโมงเล่นที่เซิร์ฟเวอร์เก็บอยู่แล้ว ได้ยอดย้อนหลังด้วย · ยังไม่มีหมวดใน Config = ไม่ทำงาน
local function syncLevelAndTime(player, st)
	if Config.Lines.level and player:GetAttribute("LevelDataLoaded") == true then
		local stats = player:FindFirstChild("leaderstats")
		local level = stats and stats:FindFirstChild("เลเวล")
		if level then setTotal(player, st, "level", math.floor(level.Value)) end
	end
	if Config.Lines.time then
		local minutes = tonumber(player:GetAttribute("PlaytimeTotal"))
		if minutes then setTotal(player, st, "time", math.floor(minutes / 60)) end
	end
end

-- เพิ่มยอดสะสม ไม่ yield ใช้ในจุดร้อนได้ (พังก็ไม่กระทบระบบที่เรียก ถ้าเรียกผ่าน pcall)
function Achievement.Add(player, lineId, amount)
	if not Config.ENABLED or not Config.Lines[lineId] then return end
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then return end
	local st = states[player]
	if not st then return end
	if not st.loaded then
		st.queue[lineId] = (st.queue[lineId] or 0) + amount
		return
	end
	apply(player, st, lineId, amount)
end

local function onPlayerAdded(player)
	if not Config.ENABLED or states[player] then return end
	local st = { data = normalize(nil), loaded = false, dirty = false, lastSave = os.clock(), queue = {}, key = keyOf(player), windows = {}, attrDirty = false }
	states[player] = st
	local ok, data = DataLoadRetry.Load(player, "Achievement", DataLoadRetry.Get(store, st.key), function() return states[player] == st end)
	if not ok then return end
	st.data = normalize(data)
	st.loaded = true
	local queued = st.queue
	st.queue = {}
	for lineId, amount in pairs(queued) do apply(player, st, lineId, amount) end
	if (st.data.c.join or 0) < 1 then apply(player, st, "join", 1) end -- ตราต้อนรับ
	publish(player, st)
	processAwards(player, st) -- ตราที่ค้างจากรอบก่อน
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

local pendingSaves = 0

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	if st and st.loaded and st.dirty then
		pendingSaves += 1
		DataLoadRetry.BeginLeaveSave(player.UserId)
		for attempt = 1, 3 do
			local ok, saved = pcall(save, player, st)
			if ok and saved then break end
			if attempt < 3 then task.wait(2 * attempt) end
		end
		DataLoadRetry.EndLeaveSave(player.UserId)
		pendingSaves -= 1
	end
end)

game:BindToClose(function()
	for player, st in pairs(states) do
		if st.loaded and st.dirty then
			pendingSaves += 1
			task.spawn(function()
				pcall(save, player, st)
				pendingSaves -= 1
			end)
		end
	end
	task.wait(0.5)
	local deadline = os.clock() + 20
	while pendingSaves > 0 and os.clock() < deadline do task.wait(0.2) end
end)

task.spawn(function()
	while true do
		task.wait(10)
		for player, st in pairs(states) do
			if st.loaded then
				pcall(syncEggs, player, st)
				pcall(syncLevelAndTime, player, st)
				if st.attrDirty then publish(player, st) end
				if st.dirty and os.clock() - st.lastSave >= SAVE_EVERY then task.spawn(save, player, st) end
				if st.retryAt and os.clock() >= st.retryAt then task.spawn(processAwards, player, st) end
			end
		end
	end
end)

request.OnServerInvoke = function(player, action)
	if action ~= "info" or not Config.ENABLED then return { ok = false } end
	local st = states[player]
	if not (st and st.loaded) then return { ok = false } end
	return { ok = true, c = st.data.c, got = st.data.got }
end

if RunService:IsStudio() then
	workspace:GetAttributeChangedSignal("DevAchievementAdd"):Connect(function()
		local text = workspace:GetAttribute("DevAchievementAdd")
		local lineId, amount = string.match(tostring(text), "^(%a+):(%d+)$")
		if not lineId then return end
		if not Config.Lines[lineId] then return end
		for _, player in ipairs(Players:GetPlayers()) do
			local st = states[player]
			if st and st.loaded then apply(player, st, lineId, tonumber(amount), true) end
		end
	end)
end

return Achievement
