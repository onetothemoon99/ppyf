-- BACKUP 2026-11-14 — ServerScriptService.LessonService (Script) ก่อนเปลี่ยนชื่อ "ครูฟาร์ม" เป็น "หุ่นนกฮูก"
-- วิธีคืน: ใน Studio เปิด ServerScriptService.LessonService แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 2 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- LessonService (2026-11-13 ช่วงที่ 2 ผู้ใช้ขอ): รางวัลบทเรียนของครูฟาร์ม เซิร์ฟเวอร์เป็นคนยืนยันว่าทำจริง และจ่ายครั้งเดียวต่อบัญชีต่อบทเรียน
-- ค่าตัวเลข/สวิตช์ดู ReplicatedStorage.LessonConfig · หน้าจอคือ StarterPlayerScripts.LessonNpcGui
-- ขั้นตอน: เซิร์ฟเวอร์เห็นว่าทำแล้ว -> สถานะ READY (แจ้งผู้เล่นให้ไปหาครูฟาร์ม) -> ผู้เล่นกด "รับรางวัล" (RemoteFunction LessonRequest "claim") -> จ่ายเหรียญ + สถานะ CLAIMED
--   ไม่จ่ายเองตอนทำเสร็จ เพื่อให้ผู้เล่นกลับไปหาครูฟาร์ม และผู้เล่นเก่าไม่โดนแจ้งเตือนรัวตอนเข้าเกม · ไม่มีการจ่ายเมื่อกดข้าม
-- วิธีตรวจ (ไม่ได้แก้สคริปต์ระบบเดิม อ่านสถานะจากข้างนอก):
--   basic   = ผู้เล่นส่ง SellCrop (ผลผลิต ไม่ใช่ปลา/เมล็ด/ผลไม้สวน) หรือ SellAllCrops แล้วเหรียญเพิ่มขึ้นในช่วง SELL_WINDOW วิรอบๆ คำสั่งนั้น
--   fish    = มี Tool ที่ Attribute IsFish ในกระเป๋า/มือ (ผู้เล่นเก่าที่มีปลาอยู่แล้ว = ผ่านทันที ตั้งใจให้เป็นแบบนี้)
--   chicken = ChickenFarm.ChickenData โหลดแล้วและมีไก่ >= 1 ตัว
-- DataStore "Lessons_v1": { ready = { [id] = true }, claimed = { [id] = true } } เซฟแบบ UpdateAsync รวมค่า (ไม่ลบของเซิร์ฟอื่น)
--   การจ่าย: จด claimed ใน DataStore ให้สำเร็จก่อน แล้วค่อยเพิ่มเหรียญ (หลายเซิร์ฟเวอร์พร้อมกันก็ได้ครั้งเดียว) · เหรียญรางวัลแจ้ง CheatWatch.AllowCoinGain ก่อนเพิ่ม
-- Attribute บนผู้เล่น: LessonsLoaded = true เมื่อโหลดเสร็จ · Lesson_<id> = 0 ยังไม่ทำ / 1 รอรับรางวัล / 2 รับแล้ว
-- Studio: ใช้คีย์ปลอมเสมอ ("StudioTest_<userId>") ไม่แตะสิทธิ์จริงของบัญชี · workspace Attribute DevLessonKeyOverride = "<คีย์>" เปลี่ยนคีย์เพื่อทดสอบซ้ำ
--   ข้อควรรู้: เหรียญที่จ่ายตอนทดสอบใน Studio เข้าเหรียญจริงของบัญชีที่กด Play (ระบบเหรียญไม่มีคีย์ปลอม)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("LessonConfig"))
if not Config.ENABLED then return end

local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local request = Instance.new("RemoteFunction")
request.Name = "LessonRequest"
request.Parent = remoteEvents

local store = DataStoreService:GetDataStore("Lessons_v1")
local CHECK_INTERVAL = 2 -- วินาทีระหว่างรอบตรวจ fish / chicken
local SELL_WINDOW = 1.5 -- วินาที: เหรียญต้องเพิ่มในช่วงนี้รอบคำสั่งขาย ถึงนับว่าขายสำเร็จ

-- ชื่อบทเรียนในข้อความแจ้งเตือน (หน้าต่างมีชื่อของตัวเองใน LessonNpcGui)
local NAMES = {
	basic = { th = "ปลูก เก็บ ขาย", en = "Plant, harvest, sell" },
	fish = { th = "ตกปลา", en = "Fishing" },
	chicken = { th = "เลี้ยงไก่", en = "Chickens" },
}

local states = {} -- [player] = { data = { ready, claimed }, loaded, key, coinUpAt, sellAt, claiming }

local function keyOf(player)
	if RunService:IsStudio() then
		local override = workspace:GetAttribute("DevLessonKeyOverride")
		if type(override) == "string" and override ~= "" then return override end
		return "StudioTest_" .. tostring(player.UserId)
	end
	return tostring(player.UserId)
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.ready = type(d.ready) == "table" and d.ready or {}
	d.claimed = type(d.claimed) == "table" and d.claimed or {}
	return d
end

local function publish(player, st)
	if not player.Parent then return end
	for _, id in ipairs(Config.Order) do
		local state = st.data.claimed[id] and Config.CLAIMED or (st.data.ready[id] and Config.READY or Config.TODO)
		player:SetAttribute("Lesson_" .. id, state)
	end
	player:SetAttribute("LessonsLoaded", true)
end

-- เซฟรวมค่า: ready / claimed มีแต่เพิ่ม ไม่มีลด
local function save(player, st)
	local snapshot = st.data
	local ok, err = pcall(function()
		store:UpdateAsync(st.key, function(old)
			old = normalize(old)
			for id in pairs(snapshot.ready) do old.ready[id] = true end
			for id in pairs(snapshot.claimed) do old.claimed[id] = true end
			return old
		end)
	end)
	if not ok then warn("LessonService: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

local function notify(player, th, en)
	if not player.Parent then return end
	harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(Localization.GetLanguage(player), th, en))
end

local function formatCoins(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- เซิร์ฟเวอร์เห็นว่าทำบทเรียนแล้ว: ตั้ง READY + แจ้งให้ไปรับรางวัล (ครั้งเดียว)
local function markReady(player, st, id)
	if st.data.ready[id] or st.data.claimed[id] then return end
	st.data.ready[id] = true
	publish(player, st)
	task.spawn(save, player, st)
	local name = NAMES[id] or { th = id, en = id }
	local coins = formatCoins(Config.Rewards[id] or 0)
	notify(player,
		"✅ บทเรียน \"" .. name.th .. "\" สำเร็จ! ไปรับรางวัล 💰 " .. coins .. " ที่ครูฟาร์ม",
		"✅ Lesson \"" .. name.en .. "\" done! Claim 💰 " .. coins .. " from the Farm Teacher")
end

-- ============ วิธีตรวจที่ใช้ลูป (fish / chicken) ============
local function hasToolWith(player, attr)
	for _, location in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute(attr) then return true end
			end
		end
	end
	return false
end

-- ChickenData require ตอนใช้ครั้งแรก (ระบบไก่ปิดหรือโมดูลพัง = บทเรียนไก่ไม่ผ่านเฉยๆ ไม่กระทบบทเรียนอื่น)
local chickenData, chickenDataTried = nil, false
local function hasChicken(player)
	if not chickenDataTried then
		chickenDataTried = true
		local folder = ServerScriptService:FindFirstChild("ChickenFarm")
		local module = folder and folder:FindFirstChild("ChickenData")
		if module then
			local ok, result = pcall(require, module)
			if ok then chickenData = result else warn("LessonService: โหลด ChickenData ไม่สำเร็จ: " .. tostring(result)) end
		end
	end
	if not chickenData or not chickenData.IsLoaded(player) then return false end
	local record = chickenData.Get(player)
	local d = record and record.data
	return type(d) == "table" and type(d.chickens) == "table" and chickenData.ChickenCount(d) >= 1
end

local CHECKS = {
	fish = function(player) return hasToolWith(player, "IsFish") end,
	chicken = hasChicken,
}

-- ============ บทเรียน basic: คำสั่งขายผลผลิต + เหรียญเพิ่ม ============
local function watchCoins(player, st)
	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 60)
		local coins = leaderstats and leaderstats:WaitForChild("เหรียญ", 60)
		if not coins then return end
		local last = coins.Value
		coins.Changed:Connect(function(value)
			if value > last then st.coinUpAt = os.clock() end
			last = value
		end)
	end)
end

local function onSellCommand(player)
	local st = states[player]
	if not (st and st.loaded) or st.data.ready.basic or st.data.claimed.basic then return end
	local sellAt = os.clock()
	task.delay(0.4, function() -- ShopSystem อาจทำงานก่อนหรือหลังตัวฟังนี้ รอให้เหรียญอัปเดตแล้วค่อยเทียบ
		if states[player] ~= st then return end
		if st.coinUpAt and math.abs(st.coinUpAt - sellAt) <= SELL_WINDOW then markReady(player, st, "basic") end
	end)
end
task.spawn(function()
	local sellCrop = remoteEvents:WaitForChild("SellCrop", 60)
	if sellCrop then
		sellCrop.OnServerEvent:Connect(function(player, cropType)
			if type(cropType) ~= "string" then return end
			if cropType:match("^Fish_") or cropType:match("^Orchard_") or cropType:match("^Seed_") then return end
			onSellCommand(player)
		end)
	end
	local sellAll = remoteEvents:WaitForChild("SellAllCrops", 60)
	if sellAll then sellAll.OnServerEvent:Connect(onSellCommand) end
end)

-- ============ รับรางวัล ============
local function claim(player, id)
	local st = states[player]
	local reward = type(id) == "string" and Config.Rewards[id] or nil
	if not (st and st.loaded and reward) then return { ok = false, reason = "notready" } end
	if st.data.claimed[id] then return { ok = false, reason = "claimed" } end
	if not st.data.ready[id] then return { ok = false, reason = "notready" } end
	if st.claiming then return { ok = false, reason = "busy" } end
	if player:GetAttribute("CoinsLoaded") ~= true then return { ok = false, reason = "busy" } end
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
	if not coins then return { ok = false, reason = "busy" } end

	st.claiming = true
	-- จดว่ารับแล้วใน DataStore ก่อนจ่าย · เซิร์ฟอื่นจดไปแล้ว = ไม่จ่ายซ้ำ
	local claimedNow = false
	local ok, err = pcall(function()
		store:UpdateAsync(st.key, function(old)
			old = normalize(old)
			if old.claimed[id] then
				claimedNow = false
				return nil
			end
			claimedNow = true
			old.ready[id] = true
			old.claimed[id] = true
			return old
		end)
	end)
	st.claiming = false
	if not ok then
		warn("LessonService: จดรับรางวัลไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, reason = "busy" }
	end
	st.data.ready[id] = true
	st.data.claimed[id] = true
	publish(player, st)
	if not claimedNow then return { ok = false, reason = "claimed" } end
	if not player.Parent then return { ok = false, reason = "busy" } end
	CheatWatch.AllowCoinGain(player, reward)
	coins.Value += reward
	print(string.format("🎓 LessonService: %s รับรางวัลบทเรียน %s %d เหรียญ", player.Name, id, reward))
	return { ok = true, coins = reward }
end

request.OnServerInvoke = function(player, action, id)
	if action == "claim" then return claim(player, id) end
	return { ok = false }
end

-- ============ เข้า / ออก ============
local function onPlayerAdded(player)
	if states[player] then return end
	local st = { data = normalize(nil), loaded = false, key = keyOf(player) }
	states[player] = st
	watchCoins(player, st)
	local ok, data = DataLoadRetry.Load(player, "Lessons", DataLoadRetry.Get(store, st.key), function() return states[player] == st end)
	if not ok then return end -- โหลดไม่ได้ = รอบนี้ไม่ตรวจ ไม่จ่าย ไม่เซฟ (กันเขียนทับ/จ่ายซ้ำ)
	st.data = normalize(data)
	st.loaded = true
	publish(player, st)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end
Players.PlayerRemoving:Connect(function(player) states[player] = nil end) -- ready/claimed เซฟทันทีตอนเปลี่ยน ไม่มีอะไรค้างตอนออก

task.spawn(function()
	while true do
		task.wait(CHECK_INTERVAL)
		for player, st in pairs(states) do
			if st.loaded and player.Parent then
				for id, check in pairs(CHECKS) do
					if Config.Rewards[id] and not st.data.ready[id] and not st.data.claimed[id] then
						local ok, done = pcall(check, player)
						if ok and done then markReady(player, st, id) end
					end
				end
			end
		end
	end
end)
