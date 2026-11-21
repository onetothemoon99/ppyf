-- BACKUP of ServerScriptService.PetFoodConverter taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ServerScriptService.PetFoodConverter, select all, paste everything BELOW the next line.
-- ===== original Source (34103 bytes, hash 1113405801) =====
-- PetFoodConverter: เครื่องทำอาหารสัตว์กลางแมพ (workspace.PetFoodMachine) ค่าต่างๆ ดู ReplicatedStorage.PetFoodConfig
-- แต่ละคนมีคิวของตัวเอง เก็บใน DataStore "PetFoodConverter_v1":
--   { level, queue = { {star, bags}, ... } (ทำตามลำดับ), cursor = เวลาที่ถุงปัจจุบันเริ่มทำ (unix วินาที), ready = { [ดาว] = ถุงที่พร้อมรับ } }
-- คำนวณจากเวลาจริง (settle) เครื่องจึงทำงานต่อตอนผู้เล่นออกจากเกม กลับมาก็ได้ของครบ
-- ทุกคำสั่งที่เปลี่ยนของ เซฟก่อนแล้วค่อยเปลี่ยนของในกระเป๋า/เหรียญ เซฟไม่ได้ = ย้อนกลับทั้งหมด (ของไม่หาย ไม่เบิ้ล)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("PetFoodConfig"))
local SultanConfig = require(ReplicatedStorage:WaitForChild("SultanConfig")) -- แพ็กสุลต่าน: เวลาต่อถุง x MACHINE_TIME_MULT
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
-- ข้อความถึงผู้เล่น ไทย/อังกฤษ ตามภาษาของผู้เล่น (2026-11-16)
local function L(player, th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end

-- ปลาส่งมาเป็น "Fish_<fishId>" (แยกจากชื่อผัก) ปลา 1 ตัว = FISH_BAGS[ระดับ] ถุง
local function fishIdOf(cropType)
	local id = type(cropType) == "string" and cropType:match("^Fish_(.+)$")
	return id and FishingConfig.Fish[id] and not FishingConfig.Fish[id].Junk and id or nil
end
local function bagsPerFish(fishId)
	return Config.FISH_BAGS[FishingConfig.Fish[fishId].Rarity] or 1
end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local function getRemote(name, class)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local request = getRemote("PetFoodRequest", "RemoteFunction")
local openEvent = getRemote("PetFoodOpen", "RemoteEvent")

local store = DataStoreService:GetDataStore("PetFoodConverter_v1")
local feederBridge = ServerScriptService:WaitForChild("AutoFeederBridge", 30) -- ชามอาหารอัตโนมัติ (AutoFeeder)
local nextTransfer = {} -- [player] = os.clock() ที่ลองส่งเข้าชามได้อีกครั้ง
local fullWarned = {}   -- [player] = true แจ้งแล้วว่าชามเต็ม

local SAVE_EVERY = 60

local states = {} -- [player] = { data, loaded, dirty, lastSave }

local function now()
	return DateTime.now().UnixTimestampMillis / 1000
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	local _, level = Config.GetLevel(d.level)
	d.level = level
	d.queue = type(d.queue) == "table" and d.queue or {}
	local clean = {}
	for _, e in ipairs(d.queue) do
		local star, bags = math.floor(tonumber(e.star) or 0), math.floor(tonumber(e.bags) or 0)
		if star >= 1 and star <= 5 and bags > 0 then table.insert(clean, { star = star, bags = bags }) end
	end
	d.queue = clean
	d.cursor = tonumber(d.cursor) or now()
	d.ready = type(d.ready) == "table" and d.ready or {}
	for star = 1, 5 do d.ready[star] = math.max(0, math.floor(tonumber(d.ready[star]) or 0)) end
	return d
end

local function queued(d)
	local n = 0
	for _, e in ipairs(d.queue) do n += e.bags end
	return n
end

local function readyTotal(d)
	local n = 0
	for star = 1, 5 do n += d.ready[star] end
	return n
end

-- ทำถุงที่ถึงเวลาแล้วให้เสร็จ คืนจำนวนถุงที่เพิ่งเสร็จ
local function settle(d)
	local t = now()
	if #d.queue == 0 then
		d.cursor = t
		return 0
	end
	local per = Config.GetLevel(d.level).Seconds * (tonumber(d.timeMult) or 1) -- timeMult: แพ็กสุลต่าน (จดในข้อมูล ออฟไลน์ก็เร็ว)
	local made = 0
	while #d.queue > 0 and t - d.cursor >= per do
		d.cursor += per
		local head = d.queue[1]
		head.bags -= 1
		d.ready[head.star] += 1
		made += 1
		if head.bags <= 0 then table.remove(d.queue, 1) end
	end
	if #d.queue == 0 then d.cursor = t end
	return made
end

local function publish(player, d)
	if not player.Parent then return end
	player:SetAttribute("PetFoodQueue", queued(d))
	player:SetAttribute("PetFoodReady", readyTotal(d))
end

-- 2026-10-28 KeyThrottled (SetAsync PetFoodConverter_v1) ยังเกิด: ใส่เครื่อง/รับ/อัปเกรดติดๆ กัน, BindToClose + PlayerRemoving เซฟซ้อน, เซฟทุก 60 วิชนคำสั่ง
-- เซฟของคนเดียวกันเข้าคิวทีละครั้ง + เว้นจากการเขียนครั้งก่อนอย่างน้อย WRITE_GAP วิ (Roblox พักคีย์เดิม ~6 วิ)
-- onlyIfDirty = true (เซฟตามรอบ / ตอนออก / ปิดเซิร์ฟ): รอคิวเสร็จแล้วข้อมูลไม่เปลี่ยน = ไม่ต้องเขียนซ้ำ
local WRITE_GAP = 7
local function save(player, st, onlyIfDirty)
	while st.saving do task.wait(0.2) end
	if onlyIfDirty and not st.dirty then return true end
	local gap = WRITE_GAP - (os.clock() - (st.lastWriteAt or -math.huge))
	if gap > 0 then
		st.saving = true
		task.wait(gap)
	end
	st.saving = true
	st.lastSave = os.clock()
	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), st.data)
	end)
	st.lastWriteAt = os.clock()
	st.saving = false
	if ok then st.dirty = false else warn("PetFoodConverter: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

local function copy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end
	return c
end

-- ผู้เล่นที่มีชามอาหารอัตโนมัติ: ย้ายอาหารที่ทำเสร็จเข้าชามเลย (ดาวต่ำก่อน) คืนจำนวนถุงที่ย้าย
-- ลำดับ: เอาออกจากเครื่อง -> เซฟเครื่อง (ไม่ได้ = ย้อนกลับ) -> ใส่ชาม
local function transferToBowl(player, st)
	if not feederBridge or not player:GetAttribute("HasAutoFeeder") then return 0 end
	local d = st.data
	local ready = 0
	for star = 1, 5 do ready += d.ready[star] end
	if ready <= 0 then return 0 end
	local okSpace, space = pcall(function() return feederBridge:Invoke("space", player) end)
	space = okSpace and tonumber(space) or 0
	if space <= 0 then
		-- ชามเต็ม (หรือปิดดึงอัตโนมัติ): อาหารรอที่เครื่องตามปกติ
		if okSpace and player:GetAttribute("HasAutoFeeder") and not fullWarned[player] and (player:GetAttribute("AutoFeederFood") or 0) > 0 then
			fullWarned[player] = true
		end
		return 0
	end
	fullWarned[player] = nil
	-- ตารางต้องครบ 5 ช่องเสมอ: ส่งผ่าน BindableFunction แล้วตารางที่มีแค่บางดาว (เช่น {[5]=42}) หายระหว่างทาง
	local moved, bags = 0, { 0, 0, 0, 0, 0 }
	for star = 1, 5 do
		local take = math.min(d.ready[star], space - moved)
		if take > 0 then
			bags[star] = take
			d.ready[star] -= take
			moved += take
		end
	end
	if moved <= 0 then return 0 end
	if not save(player, st) then
		-- บวกคืน ไม่เขียนทับทั้งตาราง: ระหว่างรอเซฟฟาร์มไก่อาจหยิบถุงไปแล้ว (PetFoodBridge 2026-11-05)
		for star = 1, 5 do d.ready[star] += bags[star] end
		return 0
	end
	local okAdd, added = pcall(function() return feederBridge:Invoke("add", player, bags) end)
	if not (okAdd and added) then
		-- ใส่ชามไม่ได้ (เช่น ชามเพิ่งถูกปิด) คืนเข้าเครื่อง
		for star = 1, 5 do d.ready[star] += bags[star] end
		st.dirty = true
		return 0
	end
	print(string.format("🥫 PetFood: %s ส่งเข้าชามอัตโนมัติ %d ถุง", player.Name, moved))
	return moved
end

-- ============ ผลผลิตในกระเป๋า ============
local function produceStacks(player)
	local list = {}
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if loc then
			for _, tool in ipairs(loc:GetChildren()) do
				-- ติดดาวไว้ (Starred) = ไม่ใส่เครื่อง/ไม่แสดง (ผู้เล่นขอ 2026-10-03)
				-- ผักกลายพันธุ์ (Mutation) ไม่ใส่เครื่อง กันเผลอเอาของแพงมาทำอาหาร (2026-10-30)
				if tool:IsA("Tool") and not tool:GetAttribute("Starred") and ((tool:GetAttribute("IsProduce") and tool:GetAttribute("CropType") and not tool:GetAttribute("Mutation"))
					or (tool:GetAttribute("IsFish") and not tool:GetAttribute("IsJunk") and FishingConfig.Fish[tool:GetAttribute("FishId")])) then
					table.insert(list, tool)
				end
			end
		end
	end
	return list
end

local function findStack(player, cropType, star)
	local fishId = fishIdOf(cropType)
	for _, tool in ipairs(produceStacks(player)) do
		if tool:GetAttribute("Star") == star then
			if fishId and tool:GetAttribute("IsFish") and tool:GetAttribute("FishId") == fishId then return tool end
			if not fishId and tool:GetAttribute("IsProduce") and tool:GetAttribute("CropType") == cropType then return tool end
		end
	end
	return nil
end

local function setToolCount(player, tool, count)
	if count <= 0 then
		tool:Destroy()
	else
		tool:SetAttribute("Count", count)
		if tool:GetAttribute("IsFish") then
			tool.Name = ItemFactory.GetFishName(tool:GetAttribute("FishId"), tool:GetAttribute("Star"), count, Localization.GetLanguage(player))
		else
			tool.Name = ItemFactory.GetProduceName(tool:GetAttribute("CropType"), tool:GetAttribute("Star"), count, Localization.GetLanguage(player))
		end
	end
end

-- ============ ข้อมูลให้หน้าต่าง ============
local function infoFor(player, st)
	local d = st.data
	local level, levelNum = Config.GetLevel(d.level)
	local nextLevel = Config.SpeedLevels[levelNum + 1]
	local stacks = {}
	for _, tool in ipairs(produceStacks(player)) do
		local fishId = tool:GetAttribute("IsFish") and tool:GetAttribute("FishId")
		table.insert(stacks, {
			CropType = fishId and ("Fish_" .. fishId) or tool:GetAttribute("CropType"), Star = tool:GetAttribute("Star") or 1,
			Count = tool:GetAttribute("Count") or 1, Name = tool.Name,
			IsFish = fishId and true or nil, BagsPer = fishId and bagsPerFish(fishId) or nil, -- ปลา: ใส่ทีละตัว ตัวละกี่ถุง
		})
	end
	table.sort(stacks, function(a, b)
		if (a.IsFish or false) ~= (b.IsFish or false) then return b.IsFish == true end -- ผักก่อน ปลาทีหลัง
		if a.Star ~= b.Star then return a.Star > b.Star end
		return a.CropType < b.CropType
	end)
	return {
		FishBags = Config.FISH_BAGS,
		Level = levelNum, Seconds = level.Seconds * (tonumber(d.timeMult) or 1), MaxLevel = #Config.SpeedLevels,
		NextSeconds = nextLevel and nextLevel.Seconds * (tonumber(d.timeMult) or 1), NextCost = nextLevel and nextLevel.Cost,
		SultanSpeed = (tonumber(d.timeMult) or 1) < 1 or nil,
		Queue = copy(d.queue), Queued = queued(d), Cursor = d.cursor, Now = now(),
		Ready = copy(d.ready), ReadyTotal = readyTotal(d),
		Stacks = stacks, PerBag = Config.PRODUCE_PER_BAG,
		AutoToBowl = player:GetAttribute("HasAutoFeeder") == true,
	}
end

-- ============ คำสั่ง ============
local function insert(player, st, cropType, star, bags)
	star = math.floor(tonumber(star) or 0)
	bags = math.floor(tonumber(bags) or 0)
	-- star ~= star / bags ~= bags = NaN (ทะลุการเทียบ < > ได้)
	if type(cropType) ~= "string" or star ~= star or bags ~= bags or star < 1 or star > 5 or bags < 1 then return { ok = false, message = L(player, "ข้อมูลไม่ถูกต้อง", "Invalid data") } end
	local tool = findStack(player, cropType, star)
	if not tool then return { ok = false, message = L(player, "ไม่มีผลผลิตนี้ในกระเป๋าแล้ว", "That item is no longer in your bag") } end
	local d = st.data
	settle(d)
	local have = tool:GetAttribute("Count") or 1
	local fishId = fishIdOf(cropType)
	local used -- จำนวนชิ้น/ตัวที่ใช้
	if fishId then
		-- ปลา: ค่าที่ส่งมา = จำนวนตัว
		local per = bagsPerFish(fishId)
		local fishCount = math.min(bags, have)
		bags = fishCount * per
		used = fishCount
	else
		bags = math.min(bags, math.floor(have / Config.PRODUCE_PER_BAG))
		if bags < 1 then return { ok = false, message = string.format(L(player, "ต้องมีผลผลิตดาวเดียวกันอย่างน้อย %d ชิ้น", "You need at least %d crops of the same star"), Config.PRODUCE_PER_BAG) } end
		used = bags * Config.PRODUCE_PER_BAG
	end

	local before = copy(d)
	local last = d.queue[#d.queue]
	if last and last.star == star then
		last.bags += bags
	else
		table.insert(d.queue, { star = star, bags = bags })
	end
	if not save(player, st) then
		st.data = before
		return { ok = false, message = L(player, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง", "Save failed, please try again") }
	end
	setToolCount(player, tool, have - used)
	publish(player, st.data)
	return { ok = true, message = L(player,
		string.format("ใส่เครื่องแล้ว %d ถุง (ใช้%s %d %s)", bags, fishId and "ปลา" or "ผลผลิต", used, fishId and "ตัว" or "ชิ้น"),
		string.format("Added %d bags to the machine (used %d %s)", bags, used, fishId and "fish" or "crops")) }
end

local function collect(player, st)
	local d = st.data
	settle(d)
	local total = readyTotal(d)
	if total <= 0 then return { ok = false, message = L(player, "ยังไม่มีอาหารที่ทำเสร็จ", "No finished food yet") } end
	-- 2026-11-18: กระเป๋ายังไม่มา (เกิดใหม่/กำลังออก) = ยังไม่แตะข้อมูล (เดิมเซฟ ready=0 ก่อน แล้ว GivePetFood พัง = ถุงหาย)
	if not player:FindFirstChildOfClass("Backpack") then
		return { ok = false, message = L(player, "กระเป๋ายังไม่พร้อม รอสักครู่แล้วลองใหม่", "Your bag isn't ready yet, please try again in a moment") }
	end
	local ready = copy(d.ready)
	for star = 1, 5 do d.ready[star] = 0 end
	if not save(player, st) then
		-- บวกคืน ไม่เขียนทับทั้งตาราง (ระหว่างรอเซฟ settle/รางไก่อาจเปลี่ยน ready)
		for star = 1, 5 do d.ready[star] += ready[star] end
		return { ok = false, message = L(player, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง", "Save failed, please try again") }
	end
	-- ให้ของทีละดาว ให้ไม่ได้ (กระเป๋าหาย/ออกเกมระหว่างเซฟ) = คืนส่วนที่เหลือเข้าเครื่องแล้วเซฟอีกรอบ
	local given, failErr = 0, nil
	for star = 1, 5 do
		if ready[star] > 0 then
			local okGive, err = true, nil
			if player.Parent then
				okGive, err = pcall(ItemFactory.GivePetFood, player, star, ready[star])
			else
				okGive, err = false, "player left"
			end
			if okGive then
				given += ready[star]
			else
				d.ready[star] += ready[star]
				failErr = failErr or err
			end
		end
	end
	if failErr then
		st.dirty = true
		pcall(save, player, st)
		warn(string.format("PetFoodConverter: ให้ถุงอาหาร %s ไม่ครบ (ได้ %d/%d) คืนเข้าเครื่องแล้ว: %s", player.Name, given, total, tostring(failErr)))
		publish(player, d)
		if given <= 0 then
			return { ok = false, message = L(player, "ใส่กระเป๋าไม่ได้ อาหารยังอยู่ในเครื่อง ลองใหม่อีกครั้ง", "Couldn't put food in your bag; it's still in the machine, please try again") }
		end
		total = given
	end
	publish(player, d)
	print(string.format("🥫 PetFood: %s รับอาหาร %d ถุง", player.Name, total))
	return { ok = true, message = string.format(L(player, "🥫 ได้อาหารสัตว์ %d ถุง!", "🥫 Got %d bags of pet food!"), total) }
end

local function upgrade(player, st)
	local d = st.data
	local _, levelNum = Config.GetLevel(d.level)
	local nextLevel = Config.SpeedLevels[levelNum + 1]
	if not nextLevel then return { ok = false, message = L(player, "ความเร็วสูงสุดแล้ว", "Already at max speed") } end
	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
	if not coins then return { ok = false, message = L(player, "ยังโหลดเหรียญไม่เสร็จ", "Coins are still loading") } end
	if coins.Value < nextLevel.Cost then return { ok = false, message = string.format(L(player, "เหรียญไม่พอ (ต้องใช้ %d)", "Not enough coins (need %d)"), nextLevel.Cost) } end
	settle(d) -- ถุงที่ทำเสร็จด้วยความเร็วเดิมก่อน แล้วค่อยเร็วขึ้น
	player:SetAttribute("CoinSrc", "petfood_upgrade")
	coins.Value -= nextLevel.Cost
	d.level = levelNum + 1
	if not save(player, st) then
		d.level = levelNum
		coins.Value += nextLevel.Cost
		return { ok = false, message = L(player, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง (คืนเหรียญแล้ว)", "Save failed, please try again (coins refunded)") }
	end
	print(string.format("🥫 PetFood: %s อัปเกรดเครื่องเป็น Lv.%d", player.Name, d.level))
	return { ok = true, message = string.format(L(player, "⚡ เครื่องเร็วขึ้นเป็น Lv.%d (%d วิ/ถุง)", "⚡ Machine upgraded to Lv.%d (%ds/bag)"), d.level, nextLevel.Seconds) }
end

local busy = {}
request.OnServerInvoke = function(player, action, a, b, c)
	local st = states[player]
	if not (st and st.loaded) then return { ok = false, message = L(player, "ยังโหลดข้อมูลเครื่องไม่เสร็จ ลองใหม่อีกครั้ง", "Machine data is still loading, please try again") } end
	-- 2026-11-18 กดรับไม่ได้ระหว่างเครื่องทำงาน:
	-- info ไม่จองเครื่อง (ไม่มีการรอ) ตอบพร้อมข้อมูลเสมอ (เดิมตอบ "กำลังทำรายการก่อนหน้า" ไม่มีข้อมูล = หน้าต่างค้าง)
	-- คำสั่งอื่นเจอเครื่องถูกจอง (ฟาร์มไก่ดึงถุง/คำสั่งก่อนหน้ารอเซฟ) = รอคิวสูงสุด 15 วิ (เดิมปฏิเสธทันที)
	if action == "info" then
		settle(st.data)
		publish(player, st.data)
		return { ok = true, info = infoFor(player, st) }
	end
	local t0 = os.clock()
	while busy[player] and states[player] == st and os.clock() - t0 < 15 do task.wait(0.2) end
	if busy[player] or states[player] ~= st then
		warn(string.format("PetFoodConverter: %s ของ %s รอเครื่องว่างเกิน 15 วิ ไม่ได้ทำ", tostring(action), player.Name))
		return { ok = false, message = L(player, "เครื่องไม่ว่าง ลองใหม่อีกครั้ง", "The machine is busy, please try again"), info = infoFor(player, st) }
	end
	local waitedBusy = os.clock() - t0
	busy[player] = true
	local ok, result = pcall(function()
		if action == "insert" then
			return insert(player, st, a, b, c)
		elseif action == "collect" then
			return collect(player, st)
		elseif action == "upgrade" then
			return upgrade(player, st)
		end
		return { ok = false, message = L(player, "คำขอไม่ถูกต้อง", "Invalid request") }
	end)
	busy[player] = nil
	if not ok then
		warn("PetFoodConverter: คำขอ " .. tostring(action) .. " ของ " .. player.Name .. " ผิดพลาด: " .. tostring(result))
		result = { ok = false, message = L(player, "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง", "Something went wrong, please try again") }
	end
	-- log ไว้สืบเคส "กดรับไม่ได้" (ดูได้ที่ F9 > Server) รับไม่สำเร็จ หรือใช้เวลาเกิน 3 วิ
	local took = os.clock() - t0
	if action == "collect" and (not result.ok or took > 3) then
		warn(string.format("PetFoodConverter: collect %s %s ใช้ %.1f วิ (รอคิว %.1f) พร้อมรับเหลือ %d คิว %d ชาม=%s: %s",
			player.Name, result.ok and "ช้า" or "ไม่สำเร็จ", took, waitedBusy, readyTotal(st.data), queued(st.data),
			tostring(player:GetAttribute("HasAutoFeeder") == true), tostring(result.message)))
	end
	result.info = infoFor(player, st)
	return result
end

-- ============ ตัวเครื่องในแมพ: กด E เปิดหน้าต่าง ============
local function hookMachine(machine)
	local part = machine:IsA("BasePart") and machine or machine:FindFirstChildWhichIsA("BasePart", true)
	if not part or part:FindFirstChild("PetFoodPrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PetFoodPrompt"
	prompt.ObjectText = "🥫 เครื่องทำอาหารสัตว์"
	prompt.ActionText = "เปิดเครื่อง"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player) openEvent:FireClient(player) end)
end
local machine = workspace:FindFirstChild("PetFoodMachine")
if machine then hookMachine(machine) end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "PetFoodMachine" then hookMachine(child) end
end)

-- ============ ผู้เล่นเข้า/ออก ============
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function onPlayerAdded(player)
	local st = { data = nil, loaded = false, dirty = false, lastSave = os.clock() }
	states[player] = st
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = ใช้เครื่องไม่ได้ทั้งรอบตอน DataStore throttle) 2026-10-09
	local okLoad, loadedData = DataLoadRetry.Load(player, "PetFoodConverter", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
	if okLoad then
		st.data = normalize(loadedData)
		st.loaded = true
	end
	if not st.loaded then return end -- โหลดไม่ได้ = ใช้เครื่องไม่ได้รอบนี้ (กันเขียนทับของเดิม)
	-- แพ็กสุลต่าน: เวลาต่อถุง x MACHINE_TIME_MULT จดไว้ในข้อมูลเครื่อง (ตอนออฟไลน์ก็เร็วด้วย)
	-- IsSultan = true -> เร็ว / false (เช็กแล้วไม่มี) -> ปกติ / nil (ยังเช็กไม่เสร็จ) -> ไม่เปลี่ยน
	local function applySultanSpeed()
		local flag = player:GetAttribute("IsSultan")
		if flag == nil or not st.data then return end
		local mult = flag == true and SultanConfig.MACHINE_TIME_MULT or 1
		if (tonumber(st.data.timeMult) or 1) ~= mult then
			settle(st.data) -- ถุงที่ถึงเวลาแล้วคิดด้วยความเร็วเดิมก่อน
			st.data.timeMult = mult ~= 1 and mult or nil
			st.dirty = true
		end
	end
	player:GetAttributeChangedSignal("IsSultan"):Connect(applySultanSpeed)
	task.defer(applySultanSpeed)
	local made = settle(st.data) -- ที่ทำเสร็จระหว่างออฟไลน์
	if made > 0 then st.dirty = true end
	publish(player, st.data)
	if readyTotal(st.data) > 0 then
		task.delay(8, function()
			if player.Parent and readyTotal(st.data) > 0 then
				harvestNotify:FireClient(player, nil, nil, nil,
					string.format(L(player, "🥫 อาหารสัตว์พร้อมรับ %d ถุง ที่เครื่องทำอาหารสัตว์", "🥫 %d bags of pet food are ready at the Pet Food Machine"), readyTotal(st.data)))
			end
		end)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	busy[player] = nil
	nextTransfer[player] = nil
	fullWarned[player] = nil
	if st and st.loaded then
		-- optimize 2026-10-10: เซฟเฉพาะตอนข้อมูลเปลี่ยน (เดิมเซฟทุกครั้งที่ออก) · ถุงที่ทำเสร็จตามเวลาคำนวณใหม่ได้จาก cursor ตอนโหลดอยู่แล้ว
		if settle(st.data) > 0 then st.dirty = true end
		if st.dirty then
			DataLoadRetry.BeginLeaveSave(player.UserId) -- เข้าเซิร์ฟเดิมทันที = รอเซฟนี้ก่อนโหลด
			pcall(save, player, st, true)
			DataLoadRetry.EndLeaveSave(player.UserId)
		end
	end
end)

game:BindToClose(function()
	for player, st in pairs(states) do
		if st.loaded and st.dirty then task.spawn(save, player, st, true) end
	end
	task.wait(3)
end)

-- ============ ฟาร์มไก่ดึงถุงที่ทำเสร็จจากเครื่อง (ChickenService autoWork 2026-11-05) ============
-- Invoke("take", player, จำนวนสูงสุด) -> ตาราง 5 ช่อง { [ดาว] = ถุง } ดาวสูงก่อน หรือ nil = ไม่มีของ/ยังโหลดไม่เสร็จ/เซฟไม่ได้
-- Invoke("putBack", player, ตาราง 5 ช่อง) -> คืนถุงเข้าเครื่องเมื่อเซฟฝั่งไก่ไม่ได้
-- ลำดับเดียวกับส่งเข้าชาม: เอาออกจากเครื่อง -> เซฟเครื่อง -> ค่อยใส่รางไก่ · ตารางต้องครบ 5 ช่องเสมอ (ส่งผ่าน Bindable)
local foodBridge = ServerScriptService:FindFirstChild("PetFoodBridge") or Instance.new("BindableFunction")
foodBridge.Name = "PetFoodBridge"
foodBridge.Parent = ServerScriptService
foodBridge.OnInvoke = function(action, player, arg)
	local st = states[player]
	if not (st and st.loaded) then return nil end
	local d = st.data
	if action == "take" then
		local space = math.floor(tonumber(arg) or 0)
		if space ~= space or space <= 0 or busy[player] then return nil end
		busy[player] = true
		settle(d)
		local bags, moved = { 0, 0, 0, 0, 0 }, 0
		for star = 5, 1, -1 do
			local take = math.min(d.ready[star], space - moved)
			if take > 0 then
				bags[star] = take
				d.ready[star] -= take
				moved += take
			end
		end
		if moved <= 0 then
			busy[player] = nil
			return nil
		end
		local okCall, saved = pcall(save, player, st)
		if okCall and saved and not player.Parent then
			-- ออกเกมระหว่างรอเซฟ: ฝั่งไก่รับถุงไม่ได้แล้ว คืนเข้าเครื่องแล้วเซฟอีกรอบ
			for star = 1, 5 do d.ready[star] += bags[star] end
			st.dirty = true
			pcall(save, player, st)
			busy[player] = nil
			return nil
		end
		if not (okCall and saved) then
			for star = 1, 5 do d.ready[star] += bags[star] end
			st.dirty = true
			busy[player] = nil
			return nil
		end
		busy[player] = nil
		publish(player, d)
		print(string.format("🥫 PetFood: %s ส่งเข้ารางไก่ %d ถุง", player.Name, moved))
		return bags
	elseif action == "putBack" then
		if type(arg) ~= "table" then return false end
		for star = 1, 5 do
			d.ready[star] += math.max(0, math.floor(tonumber(arg[star]) or 0))
		end
		st.dirty = true
		publish(player, d)
		return true
	end
	return nil
end

local TRANSFER_WRITE_GAP = 8 -- วินาที (Roblox พักการเขียนคีย์เดิมราว 6 วิ)
-- เดินเครื่องระหว่างเล่น: อัปเดตตัวเลขบนจอ + แจ้งตอนทำเสร็จหมดคิว + เซฟเป็นระยะ
while true do
	task.wait(2)
	for player, st in pairs(states) do
		if st.loaded and player.Parent then
			local d = st.data
			local hadQueue = #d.queue > 0
			local made = settle(d)
			if made > 0 then st.dirty = true end
			-- มีชามอาหารอัตโนมัติ: อาหารที่เสร็จแล้วส่งเข้าชามเลย (ลองซ้ำทุก 10 วิ เผื่อชามว่างขึ้นทีหลัง)
			local moved = 0
			-- ย้ายเข้าชาม = เขียน DataStore 1 ครั้ง: เว้นจากการเขียนครั้งก่อนอย่างน้อย TRANSFER_WRITE_GAP วิ (เดิมย้ายทุก 2 วิ = เขียนคีย์เดิมรัว จนโดน KeyThrottled) 2026-10-13
			-- รางไก่ต่ำกว่า 20% และเปิดดึงจากเครื่อง (ChickenTroughLow): เก็บถุงไว้ให้รางไก่ก่อน เติมแล้วค่อยไหลเข้าชามต่อ 2026-11-05
			-- 2026-11-18 ไม่ย้ายระหว่างผู้เล่นกำลังกดรับ/ใส่/อัปเกรด (busy) เดิมถุงที่เห็นตอนกดไหลเข้าชามก่อน = ได้ "ยังไม่มีอาหาร"
			if readyTotal(d) > 0 and not busy[player] and player:GetAttribute("HasAutoFeeder") and not player:GetAttribute("ChickenTroughLow") and os.clock() >= (nextTransfer[player] or 0) and os.clock() - (st.lastSave or 0) >= TRANSFER_WRITE_GAP then
				moved = transferToBowl(player, st)
				nextTransfer[player] = os.clock() + (moved > 0 and TRANSFER_WRITE_GAP or 10)
				st.movedSinceNotify = (st.movedSinceNotify or 0) + moved
			end
			if made > 0 or moved > 0 then publish(player, d) end
			if made > 0 and hadQueue and #d.queue == 0 then
				local left = readyTotal(d)
				if (st.movedSinceNotify or 0) > 0 then
					harvestNotify:FireClient(player, nil, nil, nil, left > 0
						and string.format(L(player, "🥣 เครื่องทำอาหารเสร็จแล้ว! ส่งเข้าชาม %d ถุง · ชามเต็ม เหลือรอรับที่เครื่อง %d ถุง", "🥣 Pet food done! %d bags went to the bowl · bowl is full, %d bags wait at the machine"), st.movedSinceNotify, left)
						or string.format(L(player, "🥣 เครื่องทำอาหารเสร็จแล้ว! ส่งเข้าชามอัตโนมัติ %d ถุง", "🥣 Pet food done! %d bags went to your auto-feeder bowl"), st.movedSinceNotify))
				else
					harvestNotify:FireClient(player, nil, nil, nil,
						string.format(L(player, "🥫 เครื่องทำอาหารเสร็จแล้ว! พร้อมรับ %d ถุง", "🥫 Pet food done! %d bags ready to collect"), left))
				end
				st.movedSinceNotify = 0
			end
			if st.dirty and not st.saving and os.clock() - st.lastSave >= SAVE_EVERY then task.spawn(save, player, st, true) end
		end
	end
end
