-- BACKUP of ServerScriptService.FishIndex before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into ServerScriptService.FishIndex.Source in Studio
-- FishIndex: สมุดสะสมปลา (เรียกจาก FishingSystem ตอนได้ปลา) ค่ารางวัลดู FishingConfig.INDEX
-- DataStore "FishIndex_v1": { fish = { [fishId] = { n = จำนวนที่จับได้, size = ใหญ่สุด, star = ดาวสูงสุด, t = เวลาจับครั้งแรก } },
--                             zones = { [zone] = true } (รับรางวัลแหล่งน้ำแล้ว), all = true (รับรางวัลครบเล่มแล้ว), petReward = true (ได้นากแล้ว) }
-- ได้ชนิดใหม่/ครบแหล่ง = ให้เหรียญทันที แล้วเซฟทันที (ครั้งอื่นเซฟเป็นระยะ + ตอนออก)
-- ยังโหลดไม่เสร็จ = เก็บไว้ในคิวก่อน โหลดเสร็จค่อยบันทึก (ปลาที่จับช่วงแรกไม่หายจากเล่ม)

local dprint = require(game:GetService("ReplicatedStorage"):WaitForChild("DevLog")) -- per-action logs: Studio only / DevLog attr (2026-11-21)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local PetOwnership = require(game:GetService("ServerScriptService"):WaitForChild("PetSystem"):WaitForChild("PetOwnership"))
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local REWARD_PET = Config.INDEX.PetReward.Pet -- รางวัลสะสมครบทุกชนิด (PetReward.Count = จำนวนชนิดทั้งหมดในสมุด): นากน้อยนักตกปลา

-- ให้สัตว์รางวัล (เซฟใน PetOwnership) ให้ไม่สำเร็จ = เข้าเกมครั้งหน้าลองใหม่ (ดู onPlayerAdded)
local function grantRewardPet(player)
	PetOwnership.WaitLoaded(player, 60) -- รอข้อมูลสัตว์โหลดครบก่อนเช็กว่ามีนากแล้วหรือยัง
	if PetOwnership.Owns(player, REWARD_PET) then return end
	local ok, isNew, saved = pcall(PetOwnership.Grant, player, REWARD_PET)
	if ok and isNew then
		harvestNotify:FireClient(player, nil, nil, nil, "🦦 ได้สัตว์เลี้ยงใหม่: นากน้อยนักตกปลา! เปิดเมนู 🐾 เพื่อพาออกมา")
	end
	if not (ok and saved) then warn("FishIndex: ให้นากไม่สำเร็จ " .. player.Name .. " จะลองใหม่ตอนเข้าเกม") end
end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local request = remoteEvents:FindFirstChild("FishIndexRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "FishIndexRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("FishIndex_v1")
local SAVE_EVERY = 60

-- รุ่นสมุด (Config.INDEX.Version) 2026-10-08: รุ่น 2 = 40 ชนิด รางวัลครบแหล่ง/ครบเล่มรับได้อีกครั้ง จึงเก็บสถานะรับแยกคีย์
--   รุ่น 1 = zones / all (คงไว้เป็นประวัติ) · รุ่น 2 = zones2 / all2
-- ปลาในแหล่งน้ำนั้นยังซ่อนอยู่ (Config.HasHidden) = ยังไม่ให้รางวัลครบแหล่ง / ยังมีซ่อนทั้งเล่ม = ยังไม่ให้ครบเล่มและนาก
local VERSION = Config.INDEX.Version or 1
local ZKEY = VERSION >= 2 and ("zones" .. VERSION) or "zones"
local AKEY = VERSION >= 2 and ("all" .. VERSION) or "all"

local FishIndex = {}
local states = {} -- [player] = { data, loaded, dirty, lastSave, queue }

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.fish = type(d.fish) == "table" and d.fish or {}
	d.zones = type(d.zones) == "table" and d.zones or {}
	d[ZKEY] = type(d[ZKEY]) == "table" and d[ZKEY] or {}
	return d
end

local function countCaught(d, zone)
	local have, total = 0, 0
	for _, id in ipairs(Config.IndexList(zone)) do
		total += 1
		if d.fish[id] then have += 1 end
	end
	return have, total
end

local function publish(player, d)
	if player.Parent then player:SetAttribute("FishIndexCount", (countCaught(d))) end
end

local function save(player, st)
	st.lastSave = os.clock()
	local snapshot = st.data
	local ok, err = pcall(function()
		store:UpdateAsync(tostring(player.UserId), function(old)
			-- รวมกับของเดิม (กันเซิร์ฟเวอร์อื่นเขียนทับ): จำนวนเอามากสุด ขนาด/ดาวเอาสูงสุด
			old = normalize(old)
			for id, rec in pairs(snapshot.fish) do
				local o = old.fish[id]
				if not o then
					old.fish[id] = { n = rec.n, size = rec.size, star = rec.star, t = rec.t }
				else
					o.n = math.max(o.n or 0, rec.n or 0)
					o.size = math.max(o.size or 0, rec.size or 0)
					o.star = math.max(o.star or 0, rec.star or 0)
					o.t = math.min(o.t or rec.t, rec.t or o.t)
				end
			end
			for z in pairs(snapshot.zones) do old.zones[z] = true end
			if snapshot.all then old.all = true end
			for z in pairs(snapshot[ZKEY]) do old[ZKEY][z] = true end
			if snapshot[AKEY] then old[AKEY] = true end
			if snapshot.petReward then old.petReward = true end
			return old
		end)
	end)
	if ok then st.dirty = false else warn("FishIndex: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

local function addCoins(player, amount)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("เหรียญ")
	if coins and amount > 0 then coins.Value += amount end
end

-- บันทึกปลา 1 ตัว คืนผลให้หน้าจอ { isNew, bonus, zoneDone, zoneReward, allDone, allReward }
local function apply(player, st, fishId, size, star)
	local fish = Config.Fish[fishId]
	if not fish then return nil end
	local d = st.data
	local rec = d.fish[fishId]
	local result = { isNew = rec == nil, bonus = 0 }
	if rec then
		rec.n = (rec.n or 0) + 1
		result.newRecord = size > (rec.size or 0)
		rec.size = math.max(rec.size or 0, size)
		rec.star = math.max(rec.star or 0, star)
	else
		d.fish[fishId] = { n = 1, size = size, star = star, t = os.time() }
		result.bonus = Config.INDEX.FirstCatch[fish.Rarity] or 0
		-- ครบแหล่งน้ำ?
		-- (ปลาอีเวนต์ไม่มีแหล่งน้ำประจำ ไม่นับครบแหล่ง)
		local have, total = countCaught(d, fish.Zone)
		if not fish.EventOnly and total > 0 and have >= total and not d[ZKEY][fish.Zone] and not Config.HasHidden(fish.Zone) then
			d[ZKEY][fish.Zone] = true
			result.zoneDone = fish.Zone
			result.zoneReward = Config.INDEX.ZoneReward[fish.Zone] or 0
		end
		local allHave, allTotal = countCaught(d)
		-- ครบจำนวนชนิดที่กำหนด = ได้สัตว์รางวัล (ครั้งเดียว)
		if allHave >= Config.INDEX.PetReward.Count and not d.petReward and not Config.HasHidden() then
			d.petReward = true
			result.pet = REWARD_PET
			task.spawn(grantRewardPet, player)
		end
		if allHave >= allTotal and not d[AKEY] and not Config.HasHidden() then
			d[AKEY] = true
			result.allDone = true
			result.allReward = Config.INDEX.AllReward
		end
	end
	st.dirty = true
	local coins = result.bonus + (result.zoneReward or 0) + (result.allReward or 0)
	addCoins(player, coins)
	publish(player, d)
	if result.isNew then task.spawn(save, player, st) end
	if result.isNew then
		dprint(string.format("📖 FishIndex: %s ได้ปลาใหม่ %s (+%d เหรียญ)%s", player.Name, fishId, coins,
			result.zoneDone and (" ครบ" .. result.zoneDone) or ""))
	end
	return result
end

-- ความคืบหน้าสมุด (จับได้แล้ว, ทั้งหมด, โหลดแล้วไหม) โต๊ะช่างใช้เช็กเงื่อนไขคราฟเบ็ดนาก (2026-10-10)
-- บอกหน้าจอผู้เล่นว่าสมุดครบกี่ชนิดแล้ว (Attribute FishBookHave / FishBookTotal) ช่องเบ็ดนากในเมนูสัตว์ใช้ล็อก (2026-10-10)
local function updateBookAttr(player, st)
	if not (player.Parent and st and st.loaded) then return end
	local have, total = countCaught(st.data)
	player:SetAttribute("FishBookHave", have)
	player:SetAttribute("FishBookTotal", total)
end

function FishIndex.GetProgress(player)
	local st = states[player]
	if not (st and st.loaded) then return 0, #Config.IndexList(), false end
	local have, total = countCaught(st.data)
	return have, total, true
end

-- ============ Game Pass "ผ่านทันที" (2026-10-10) ============
-- เจ้าของพาส = ปลดล็อกปลาทุกชนิดในสมุด + รับรางวัลที่ยังไม่ได้ทั้งหมด (โบนัสชนิดใหม่ ครบแหล่งน้ำ ครบเล่ม นาก)
-- เช็กตอนเข้าเกมทุกครั้ง ปลาที่เพิ่มทีหลังจึงปลดล็อกให้เอง · ทดสอบใน Studio: ตั้ง Attribute "DevFishSkipPass" = true บนตัวผู้เล่น (จากเซิร์ฟเวอร์)
local SKIP_PASS_ID = (Config.INDEX.SkipPass and Config.INDEX.SkipPass.GAMEPASS_ID) or 0

-- โหมดทดสอบการซื้อ (เฉพาะ Studio) 2026-10-11: ตั้ง workspace Attribute "DevFishSkipTest" = true
--   เข้าเกม = ถือว่ายังไม่มีพาส (แม้บัญชีจะมีจริง) สมุดที่ไม่ครบจึงไม่ถูกปลดล็อกเอง และปุ่ม "ผ่านทันที" ขึ้น
--   กดปุ่มแล้วปิดหน้าต่างซื้อของ Roblox (ซื้อสำเร็จหรือขึ้นว่ามีอยู่แล้วก็ได้) = ถือว่าซื้อแล้ว ปลดล็อกตามจริง
--   เกมจริงไม่อ่าน Attribute นี้ (RunService:IsStudio) · เลิกทดสอบ = ลบ Attribute ออก
local function devSkipTest()
	return RunService:IsStudio() and workspace:GetAttribute("DevFishSkipTest") == true
end

local function ownsSkipPass(player)
	if RunService:IsStudio() and player:GetAttribute("DevFishSkipPass") then return true end
	if devSkipTest() then return player:GetAttribute("DevFishSkipBought") == true end
	if SKIP_PASS_ID <= 0 then return false end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, SKIP_PASS_ID)
		end)
		if ok then return result end
		warn("FishIndex: เช็ก Game Pass ผ่านทันทีไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(result))
		task.wait(2)
	end
	return false
end

-- ปลาที่ได้จากพาสบันทึกเป็น n = 0 (ยังไม่เคยตกเอง) ตกได้จริงทีหลังค่อยนับจำนวน/ขนาดตามปกติ
local function unlockAll(player)
	local st = states[player]
	if not (st and st.loaded) or st.unlocking then return end
	st.unlocking = true
	-- รอเงินโหลดก่อน (เพิ่มเหรียญก่อนโหลด = โดนค่าที่โหลดมาทับ รางวัลหาย) โหลดไม่ทัน = ยังไม่ปลดล็อก เข้าเกมครั้งหน้าทำใหม่
	local waited = 0
	while player.Parent and not player:GetAttribute("CoinsLoaded") and waited < 120 do
		task.wait(1)
		waited += 1
	end
	if not (player.Parent and states[player] == st and player:GetAttribute("CoinsLoaded")) then
		st.unlocking = nil
		return
	end
	local d = st.data
	local coins, added = 0, 0
	for _, id in ipairs(Config.IndexList()) do
		if not d.fish[id] then
			d.fish[id] = { n = 0, size = 0, star = 1, t = os.time() }
			coins += Config.INDEX.FirstCatch[Config.Fish[id].Rarity] or 0
			added += 1
		end
	end
	for _, z in ipairs(Config.ZONE_ORDER) do
		local have, total = countCaught(d, z)
		if total > 0 and have >= total and not d[ZKEY][z] and not Config.HasHidden(z) then
			d[ZKEY][z] = true
			coins += Config.INDEX.ZoneReward[z] or 0
		end
	end
	local newPet = false
	if not Config.HasHidden() then
		if not d[AKEY] then
			d[AKEY] = true
			coins += Config.INDEX.AllReward
		end
		if not d.petReward then
			d.petReward = true
			newPet = true
		end
	end
	st.unlocking = nil
	if added == 0 and coins == 0 and not newPet then return end
	st.dirty = true
	addCoins(player, coins)
	publish(player, d)
	updateBookAttr(player, st)
	task.spawn(save, player, st)
	if newPet then task.spawn(grantRewardPet, player) end
	harvestNotify:FireClient(player, nil, nil, nil, string.format("⚡ ผ่านทันที! ปลดล็อกปลาในสมุดครบทุกชนิดแล้ว (+%d ชนิด) รับรางวัล +%d เหรียญ", added, coins))
	dprint(string.format("⚡ FishIndex: %s ผ่านทันที ปลดล็อก %d ชนิด (+%d เหรียญ)%s", player.Name, added, coins, newPet and " + นาก" or ""))
end

-- เช็กสิทธิ์พาสแล้วปลดล็อก (ตอนเข้าเกม / หลังซื้อ) Attribute FishSkipPass = หน้าจอใช้ซ่อนปุ่มซื้อ
local function applySkipPass(player, owned)
	if not owned then return end
	if player.Parent then player:SetAttribute("FishSkipPass", true) end
	unlockAll(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if SKIP_PASS_ID <= 0 or passId ~= SKIP_PASS_ID then return end
	if devSkipTest() then
		player:SetAttribute("DevFishSkipBought", true) -- โหมดทดสอบ: ปิดหน้าต่างซื้อ = ถือว่าซื้อแล้ว
	elseif not purchased then
		return
	end
	print("⚡ FishIndex: " .. player.Name .. " ซื้อ Game Pass ผ่านทันที")
	applySkipPass(player, true)
end)

function FishIndex.Record(player, fishId, size, star)
	local st = states[player]
	if not st then return nil end
	if not st.loaded then
		table.insert(st.queue, { fishId, size, star })
		return nil
	end
	local result = apply(player, st, fishId, size, star)
	updateBookAttr(player, st)
	return result
end

request.OnServerInvoke = function(player, action)
	local st = states[player]
	if not (st and st.loaded) then return { ok = false, message = "ยังโหลดสมุดไม่เสร็จ ลองใหม่อีกครั้ง" } end
	if action == "info" then
		local fish = {}
		for id, rec in pairs(st.data.fish) do fish[id] = { n = rec.n, size = rec.size, star = rec.star } end
		local zones = {}
		for z in pairs(st.data[ZKEY]) do zones[z] = true end -- สถานะรับรางวัลของสมุดรุ่นปัจจุบัน
		return { ok = true, fish = fish, zones = zones, all = st.data[AKEY] == true, rewardPet = REWARD_PET, petReward = st.data.petReward == true,
			skipPass = { id = SKIP_PASS_ID, owned = player:GetAttribute("FishSkipPass") == true } }
	end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
end

local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function onPlayerAdded(player)
	local st = { data = normalize(nil), loaded = false, dirty = false, lastSave = os.clock(), queue = {} }
	states[player] = st
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก) ระหว่างรอ ปลาที่จับได้เข้าคิว st.queue ไว้ก่อน 2026-10-09
	local ok, data = DataLoadRetry.Load(player, "FishIndex", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
	if ok then
		st.data = normalize(data)
		st.loaded = true
	end
	if not st.loaded then return end
	publish(player, st.data)
	for _, q in ipairs(st.queue) do apply(player, st, q[1], q[2], q[3]) end
	updateBookAttr(player, st)
	-- สะสมครบจำนวนแล้วแต่ยังไม่ได้นาก (เช่น ให้ไม่สำเร็จรอบก่อน) รอระบบสัตว์โหลดก่อนแล้วให้ใหม่
	-- petReward = true อยู่แล้ว = ได้สิทธิ์ไปตั้งแต่กติกาเดิม (ครบ 10 ชนิด) ยังได้นากเหมือนเดิม
	if st.data.petReward or ((countCaught(st.data)) >= Config.INDEX.PetReward.Count and not Config.HasHidden()) then
		st.data.petReward = true
		task.delay(15, function() if player.Parent then grantRewardPet(player) end end)
	end
	st.queue = {}
	-- เจ้าของ Game Pass ผ่านทันที: ปลดล็อกปลาที่ยังขาด (รวมปลาที่เพิ่มหลังซื้อ)
	task.spawn(function() applySkipPass(player, ownsSkipPass(player)) end)
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevFishSkipPass"):Connect(function()
			applySkipPass(player, ownsSkipPass(player))
		end)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

local pendingSaves = 0 -- BindToClose รอตัวนับนี้ (เซฟตอนออกลองซ้ำได้หลายวิ)

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	if st and st.loaded and st.dirty then
		pendingSaves += 1
		DataLoadRetry.BeginLeaveSave(player.UserId) -- เข้าเซิร์ฟเดิมทันที = รอเซฟนี้ก่อนโหลด (2026-10-10)
		-- DataStore ล่มชั่วคราว (InternalServerError) ลองใหม่สูงสุด 3 ครั้ง ไม่งั้นข้อมูลช่วงท้ายหาย (2026-10-24)
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
	-- 2026-10-30 เดิมรอตายตัว 3 วิ ตัดการลองซ้ำตอนออก (รอ 2+4 วิ) ทิ้งตอนเซิร์ฟปิด · รอให้เซฟครบ สูงสุด 20 วิ
	task.wait(0.5) -- เผื่อ PlayerRemoving ของคนที่ถูกเอาออกตอนปิดยังไม่เริ่ม
	local deadline = os.clock() + 20
	while pendingSaves > 0 and os.clock() < deadline do task.wait(0.2) end
end)

task.spawn(function()
	while true do
		task.wait(10)
		for player, st in pairs(states) do
			if st.loaded and st.dirty and os.clock() - st.lastSave >= SAVE_EVERY then task.spawn(save, player, st) end
		end
	end
end)

return FishIndex
