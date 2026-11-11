-- Backup 2026-11-11 of ServerScriptService.LevelSystem (ModuleScript) before the Lv2000 EXP curve change (LEVEL_CURVE.md).
-- To restore: paste this whole file back into ServerScriptService.LevelSystem.Source.
-- LevelSystem: ระบบเลเวลผู้เล่น ได้ XP จากการเก็บเกี่ยว เลื่อนเลเวลอัตโนมัติเมื่อ XP ครบเกณฑ์ (เซฟถาวรผ่าน DataStore)
-- เป็น ModuleScript ให้สคริปต์อื่น require ไปใช้ (เช่น PlantingSystem เรียก AddXP, ShopSystem เรียก GetLevel)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local CheatWatch = require(script.Parent:WaitForChild("CheatWatch")) -- จดผู้เล่นที่ XP ขึ้นเร็วเกินจริง + แจ้งเจ้าของ

local levelDataStore = DataStoreService:GetDataStore("PlayerLevel_v1")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local harvestNotify = remoteEvents:FindFirstChild("HarvestNotify")
if not harvestNotify then
	harvestNotify = Instance.new("RemoteEvent")
	harvestNotify.Name = "HarvestNotify"
	harvestNotify.Parent = remoteEvents
end

local levelUpdate = remoteEvents:FindFirstChild("LevelUpdate")
if not levelUpdate then
	levelUpdate = Instance.new("RemoteEvent")
	levelUpdate.Name = "LevelUpdate"
	levelUpdate.Parent = remoteEvents
end

local LevelSystem = {}

local loaded = {} -- [player] = true เฉพาะเมื่อโหลดข้อมูลจาก DataStore สำเร็จแล้ว (ยังไม่สำเร็จ = ห้ามเซฟทับ)
local playerXP = {}
local pendingXP = {}
local pendingLeaveSaves = {} -- [userId] = true ระหว่างรอเซฟก่อนผู้เล่นเดิมออกเสร็จ เพื่อให้การเข้าใหม่รออ่านข้อมูลล่าสุด

-- XP ที่ต้องใช้เพื่อเลื่อนจากเลเวลปัจจุบัน ไปเลเวลถัดไป ปรับสูตรตรงนี้ได้ถ้าอยากให้โตช้า/เร็วกว่านี้
local function xpNeededForLevel(level)
	return level * 100
end

local function getLevelValue(player)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then return nil end
	return leaderstats:WaitForChild("เลเวล", 10)
end

-- อ่านเลเวลปัจจุบันของผู้เล่น (ให้สคริปต์อื่นเรียกเช็คได้ เช่น ShopSystem เช็คก่อนอนุญาตให้ซื้อ)
function LevelSystem.GetLevel(player)
	local levelValue = getLevelValue(player)
	return levelValue and levelValue.Value or 1
end

local function notifyLevel(player)
	local levelValue = getLevelValue(player)
	if not levelValue then return end
	local xp = playerXP[player] or 0
	player:SetAttribute("LevelXP", xp)
	levelUpdate:FireClient(player, levelValue.Value, xp, xpNeededForLevel(levelValue.Value))
end

-- ============ ตัวดัก XP (2026-10-11) ============
-- 1) เพดาน XP ต่อ 10 นาที คิดจากโควต้าปลูกของผู้เล่นเอง: เกินนี้ = ไม่ให้ XP ส่วนเกิน + จดชื่อ (CheatWatch)
--    เก็บเกี่ยว 1 ต้นได้มากสุด 50 XP และต้นโตเร็วสุด ~5 วิ (ข้าวสาลี 13.2 วิ x ฝน x มังกรสุลต่าน) = 120 รอบต่อ 10 นาที
--    ผู้เล่นปกติไปไม่ถึงเพดานนี้ (ต้องปลูกเต็มโควต้า + เก็บทันทีทุกรอบ ตลอด 10 นาที) เคสโกงที่เจอเกินไป 2-4 เท่า
-- 2) ค่าเฉลี่ยตลอดชีพ: XP รวมทั้งหมด / นาทีที่เล่นสะสม (PlaytimeTotal) สูงผิดปกติ = จดชื่ออย่างเดียว ไม่ตัดอะไร
--    (เจ้าของเกมเล่นหนักสุด ~640 XP/นาที, เคสโกง 13,500-37,700 XP/นาที)
local XP_WINDOW = 600            -- วินาที
local XP_BUCKET = 60             -- นับเป็นช่องละกี่วินาที
local XP_PER_PLANT_SLOT = 6000   -- XP ต่อ 10 นาที ต่อโควต้าปลูก 1 ต้น (50 XP x 120 รอบ)
local XP_FLAT_ALLOWANCE = 20000  -- เผื่อ XP จากตกปลา ฯลฯ ต่อ 10 นาที
local LIFETIME_MIN_LEVEL = 50    -- ต่ำกว่านี้ไม่เช็กค่าเฉลี่ย (XP ยังน้อย ตัวเลขแกว่ง)
local LIFETIME_MIN_MINUTES = 10
local LIFETIME_XP_PER_MINUTE = 4000 -- 2026-10-28: 3000 -> 4000 (ผู้เล่น AFK 24 ชม. เช่น 0xoARESox0 เฉลี่ย ~3,140 โดนแจ้งซ้ำ)

local xpBuckets = {} -- [player] = { [เลขช่องเวลา] = XP ที่ได้ในช่องนั้น }

local function xpLimitFor(player)
	-- ทดสอบใน Studio: ตั้ง Attribute DevXpLimit บน ServerScriptService = เพดานปลอม (ลบทิ้งหลังทดสอบ)
	local dev = game:GetService("RunService"):IsStudio() and tonumber(game:GetService("ServerScriptService"):GetAttribute("DevXpLimit"))
	if dev then return dev end
	return math.max(10, tonumber(player:GetAttribute("PlantLimit")) or 10) * XP_PER_PLANT_SLOT + XP_FLAT_ALLOWANCE
end

-- นับ XP ก้อนนี้เข้าหน้าต่างเวลา คืน false ถ้าเกินเพดาน (ไม่นับ ไม่ให้ XP)
local function xpWithinLimit(player, amount)
	local buckets = xpBuckets[player]
	if not buckets then
		buckets = {}
		xpBuckets[player] = buckets
	end
	local current = math.floor(os.clock() / XP_BUCKET)
	local total = 0
	for index, xp in pairs(buckets) do
		if index <= current - XP_WINDOW / XP_BUCKET then
			buckets[index] = nil
		else
			total += xp
		end
	end
	local limit = xpLimitFor(player)
	if total + amount > limit then
		CheatWatch.Flag(player, "xp_rate", string.format("XP %.0f + %.0f ใน 10 นาที เกินเพดาน %.0f (โควต้าปลูก %s)",
			total, amount, limit, tostring(player:GetAttribute("PlantLimit") or "?")))
		return false
	end
	buckets[current] = (buckets[current] or 0) + amount
	return true
end

local function checkLifetimeXP(player, level)
	local minutes = tonumber(player:GetAttribute("PlaytimeTotal"))
	if level < LIFETIME_MIN_LEVEL or not minutes or minutes < LIFETIME_MIN_MINUTES then return end
	local totalXP = 50 * level * (level - 1) + (playerXP[player] or 0) -- เลเวล n ใช้ n x 100 XP
	local perMinute = totalXP / minutes
	if perMinute > LIFETIME_XP_PER_MINUTE then
		CheatWatch.Flag(player, "xp_lifetime", string.format("เฉลี่ย %.0f XP/นาที (เลเวล %.0f ใน %.0f นาที) เกิน %.0f", perMinute, level, minutes, LIFETIME_XP_PER_MINUTE))
	end
end

-- เพิ่ม XP ให้ผู้เล่น (เรียกจาก PlantingSystem ตอนเก็บเกี่ยวสำเร็จ) เลื่อนเลเวลอัตโนมัติถ้า XP ครบ (เลื่อนได้หลายเลเวลรวดถ้า XP เยอะพอ)
function LevelSystem.AddXP(player, amount)
	local levelValue = getLevelValue(player)
	if not levelValue or type(amount) ~= "number" or amount ~= amount or amount <= 0 then return end -- amount ~= amount = NaN
	if not loaded[player] then
		pendingXP[player] = (pendingXP[player] or 0) + amount
		return false -- hold XP until the real level arrives
	end
	if not xpWithinLimit(player, amount) then return false end -- เร็วเกินจริง: ไม่ให้ XP + จดชื่อ

	local xp = (playerXP[player] or 0) + amount
	local leveledUp = false

	while xp >= xpNeededForLevel(levelValue.Value) do
		xp -= xpNeededForLevel(levelValue.Value)
		levelValue.Value += 1
		leveledUp = true
	end

	playerXP[player] = xp
	notifyLevel(player)

	if leveledUp then
		local lang = Localization.GetLanguage(player)
		harvestNotify:FireClient(player, nil, nil, nil, Localization.F("Level_UpNotify", lang, levelValue.Value))
	end
end

-- ============ โหลด / เซฟ (กันเลเวลโดนเขียนทับ) ============
-- เหตุการณ์ 2026-10-03: โหลดไม่สำเร็จรอบหนึ่ง -> ใช้เลเวล 1 -> ตอนออกเกมเซฟเลเวล 1 ทับเลเวลจริง 161
-- กติกาใหม่: เซฟได้ก็ต่อเมื่อโหลดสำเร็จแล้วเท่านั้น (loaded) โหลดไม่สำเร็จ = ลองซ้ำเรื่อยๆ ไม่เซฟทับ
--   และตอนเซฟใช้ UpdateAsync ไม่ยอมให้เลเวลในที่เก็บลดลง (เลเวลไม่เคยลดตามปกติ) เผื่อมีค่าเก่าค้างมาเขียนทับ
local RETRY_TRIES = 5      -- ลองโหลดติดกันกี่ครั้งตอนเข้าเกม
local RETRY_BACKOFF = 2    -- วินาที (คูณเพิ่มทีละครั้ง)
local BACKGROUND_RETRY = 15 -- ยังโหลดไม่ได้: ลองใหม่เบื้องหลังทุกกี่วินาที
local AUTOSAVE_EVERY = 120
local SAVE_TRIES = 3       -- เซฟไม่สำเร็จ ลองซ้ำกี่ครั้ง
local SAVE_BACKOFF = 2     -- วินาที (คูณเพิ่มทีละครั้ง)
local activeSaves = 0      -- จำนวนเซฟที่กำลังทำ (BindToClose รอให้เสร็จ)

local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function readStored(player)
	-- ทดสอบใน Studio: ตั้ง Attribute DevFailLevelLoad = true บน ServerScriptService = จำลองโหลดไม่สำเร็จ
	if game:GetService("RunService"):IsStudio() and game:GetService("ServerScriptService"):GetAttribute("DevFailLevelLoad") == true then
		return false, "DevFailLevelLoad"
	end
	DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
	return pcall(function()
		return levelDataStore:GetAsync(tostring(player.UserId))
	end)
end

local function applyLoaded(player, levelValue, data)
	if type(data) == "table" then
		levelValue.Value = math.max(1, math.floor(tonumber(data.Level) or 1))
		playerXP[player] = math.max(0, tonumber(data.XP) or 0)
	else
		playerXP[player] = 0 -- ไม่เคยมีข้อมูล = ผู้เล่นใหม่จริง (อ่านสำเร็จแต่ว่าง)
	end
	loaded[player] = true
	local queuedXP = pendingXP[player] or 0
	pendingXP[player] = nil
	player:SetAttribute("LevelDataLoaded", true)
	if queuedXP > 0 then
		LevelSystem.AddXP(player, queuedXP) -- apply queued XP to the loaded level
	else
		notifyLevel(player)
	end
end

local function loadPlayerLevel(player, levelValue)
	player:SetAttribute("LevelDataLoaded", false)
	-- AFK rejoin กลับเซิร์ฟเวอร์เดิมได้ก่อน PlayerRemoving เซฟเสร็จ
	-- รอเซฟของ Player instance ก่อนหน้า แล้วค่อยอ่าน DataStore เพื่อไม่ให้ข้ามเลเวลล่าสุด
	while player.Parent and pendingLeaveSaves[player.UserId] do
		task.wait(0.1)
	end
	local tries = 0
	while player.Parent and not loaded[player] do
		tries += 1
		local ok, data = readStored(player)
		if ok then
			applyLoaded(player, levelValue, data)
			return
		end
		warn("LevelSystem: โหลดเลเวลของ " .. player.Name .. " ไม่สำเร็จ (ครั้งที่ " .. tries .. "): " .. tostring(data))
		playerXP[player] = 0
		-- ยังไม่ส่งค่าเลเวลเริ่มต้น 1 ไปยังหน้าจอ: โหลดข้อมูลจริงยังอยู่ระหว่างลองใหม่
		task.wait(tries <= RETRY_TRIES and RETRY_BACKOFF * tries or BACKGROUND_RETRY)
	end
end

local function savePlayerLevel(player)
	if not loaded[player] then
		warn("LevelSystem: ข้ามการเซฟเลเวลของ " .. player.Name .. " (ยังโหลดข้อมูลเดิมไม่สำเร็จ กันเขียนทับ)")
		return
	end
	local levelValue = getLevelValue(player)
	if not levelValue then return end

	local newLevel, newXP = levelValue.Value, playerXP[player] or 0
	-- InternalServerError ฝั่ง Roblox เป็นชั่วคราว: ลองซ้ำ SAVE_TRIES ครั้ง (2026-11-01)
	activeSaves += 1
	local ok, err
	for attempt = 1, SAVE_TRIES do
		ok, err = pcall(function()
			levelDataStore:UpdateAsync(tostring(player.UserId), function(old)
				if type(old) == "table" then
					local oldLevel = tonumber(old.Level) or 1
					if oldLevel > newLevel then return nil end -- ในที่เก็บสูงกว่า = ค่าเรากำลังเก่า/ผิด ไม่เขียนทับ
				end
				return { Level = newLevel, XP = newXP }
			end)
		end)
		if ok then break end
		warn("LevelSystem: เซฟเลเวลของ " .. player.Name .. " ไม่สำเร็จ (ครั้งที่ " .. attempt .. "): " .. tostring(err))
		if attempt < SAVE_TRIES then task.wait(SAVE_BACKOFF * attempt) end
	end
	activeSaves -= 1
end

Players.PlayerAdded:Connect(function(player)
	local levelValue = getLevelValue(player)
	if levelValue then
		loadPlayerLevel(player, levelValue)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	pendingLeaveSaves[userId] = true
	local ok, err = pcall(savePlayerLevel, player)
	if not ok then warn("LevelSystem: เซฟตอนออกผิดพลาดสำหรับ " .. player.Name .. ": " .. tostring(err)) end
	pendingLeaveSaves[userId] = nil
	playerXP[player] = nil
	pendingXP[player] = nil
	loaded[player] = nil
	xpBuckets[player] = nil
end)

for _, existingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local levelValue = getLevelValue(existingPlayer)
		if levelValue then
			loadPlayerLevel(existingPlayer, levelValue)
		end
	end)
end

-- เซฟสำรองระหว่างเล่น + ตอนเซิร์ฟเวอร์ปิด (เดิมเซฟแค่ตอนออกเกม ถ้าเซิร์ฟเวอร์ล่มได้ความคืบหน้าหาย)
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_EVERY)
		for _, player in ipairs(Players:GetPlayers()) do
			if loaded[player] then
				task.spawn(savePlayerLevel, player)
				local levelValue = getLevelValue(player)
				if levelValue then checkLifetimeXP(player, levelValue.Value) end
			end
		end
	end
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(savePlayerLevel, player)
	end
	local t0 = os.clock()
	repeat task.wait(0.25) until activeSaves <= 0 or os.clock() - t0 > 25
end)

return LevelSystem
