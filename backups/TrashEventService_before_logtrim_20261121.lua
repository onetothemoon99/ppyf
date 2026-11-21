-- BACKUP of ServerScriptService.TrashEventService taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ServerScriptService.TrashEventService, select all, paste everything BELOW the next line.
-- ===== original Source (25470 bytes, hash 608276096) =====
-- TrashEventService: อีเวนต์ "ทะเลสาบวิกฤต! ช่วยน้องนากเก็บขยะ" (สร้าง 2026-10-12) ค่าต่างๆ ดู ReplicatedStorage.TrashEventConfig
-- เปิด/ปิดรอบตามเวลาไทย (ทุกเซิร์ฟพร้อมกัน) -> workspace Attribute TrashEventActive / EndsAt / Round / Collected / Goal / Cleared (หน้าจออ่านจากตรงนี้)
-- ระหว่างรอบ: วางขยะลอยน้ำ + ลำแสง/แผ่นเรืองบนทะเลสาบ + น้องนากเก็บขยะ (workspace.TrashEvent) จบรอบ = เก็บออกหมด
-- FishingSystem ยิง BindableEvent "JunkCaught" (ลูกของสคริปต์นี้) ทุกครั้งที่ได้ขยะ: (player, ตำแหน่งทุ่น, จำนวน)
--   อยู่ในทะเลสาบ + มีรอบ = นับเข้าภารกิจรายวันของผู้เล่น + เป้ารวมของเซิร์ฟ
-- DataStore "TrashEvent_v1" คีย์ userId: { day = "YYYY-MM-DD" (เวลาไทย), count, claimed = { [milestoneId] = true }, clear = { [roundKey] = true } }
--   วันใหม่ = เริ่มนับใหม่ · ยังโหลดไม่เสร็จ = ไม่เซฟ (ขยะที่ได้ช่วงนั้นเข้าคิวไว้บวกทีหลัง)
--   กันรับรางวัลซ้ำข้ามเซิร์ฟ: จองใน DataStore (UpdateAsync) ก่อนให้เหรียญเสมอ จองไม่สำเร็จ = ยังไม่ให้ ลองใหม่รอบถัดไป
-- เจ้าของเกมพิมพ์ในแชท (ใช้ได้ทุกที่ รวม Team Test และเกมจริง มีผลเฉพาะเซิร์ฟนั้น): /trash (เริ่มรอบ 15 นาที) · /trash 5 (นาที 1-60) · /trash stop (จบรอบที่สั่งเอง)
-- Studio: คีย์ "studio:<userId>" · workspace Attribute DevTrashEvent = true (เริ่มทันที นาน DevTrashSeconds วินาที ถ้าตั้ง) / false (ปิด)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("TrashEventConfig"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")
local assets = ReplicatedStorage:WaitForChild("TrashEventAssets")

local junkCaught = Instance.new("BindableEvent")
junkCaught.Name = "JunkCaught"
junkCaught.Parent = script

local store = DataStoreService:GetDataStore("TrashEvent_v1")
local SAVE_EVERY = 60
local DIRTY_COLOR = Color3.fromRGB(196, 204, 92)  -- น้ำขุ่น เหลืองอมเขียว
local CLEAN_COLOR = Color3.fromRGB(110, 220, 255) -- น้ำใส ฟ้า

local states = {} -- [player] = { data, loaded, dirty, lastSave, queued, busy }
local round = nil -- { idx, key, endsAt, collected, goal, cleared, contrib = { [userId] = n }, folder, floaters, beaconParts }

local function pick(player, th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end
local function notify(player, th, en)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, pick(player, th, en)) end
end
local function comma(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- ============ ข้อมูลภารกิจรายวัน ============
local function fresh(day)
	return { day = day, count = 0, claimed = {}, clear = {} }
end
local function normalize(d, day)
	if type(d) ~= "table" or d.day ~= day then return fresh(day) end
	d.count = tonumber(d.count) or 0
	d.claimed = type(d.claimed) == "table" and d.claimed or {}
	d.clear = type(d.clear) == "table" and d.clear or {}
	return d
end
local function keyOf(player)
	return (RunService:IsStudio() and "studio:" or "") .. tostring(player.UserId)
end

local function publish(player, st)
	if not player.Parent then return end
	local claimed = 0
	for _, m in ipairs(Config.MILESTONES) do
		if st.data.claimed[m.Id] then claimed += 1 end
	end
	player:SetAttribute("TrashCount", st.data.count + (st.queued or 0))
	player:SetAttribute("TrashClaimed", claimed)
end

-- ข้ามวัน (เวลาไทย) = เริ่มนับใหม่
local function rollover(player, st)
	local day = Config.DayKey()
	if st.loaded and st.data.day ~= day then
		st.data = fresh(day)
		st.dirty = true
		publish(player, st)
	end
end

local function save(player, st)
	st.lastSave = os.clock()
	local snap = st.data
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			old = normalize(old, snap.day)
			old.count = math.max(old.count, snap.count)
			for k in pairs(snap.claimed) do old.claimed[k] = true end
			for k in pairs(snap.clear) do old.clear[k] = true end
			return old
		end)
	end)
	if ok then st.dirty = false else warn("TrashEventService: เซฟไม่สำเร็จ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

-- จองสิทธิ์รับรางวัลใน DataStore: คืน (สำเร็จไหม, เราเป็นคนจองได้ไหม)
local function reserve(player, st, field, id)
	local snap = st.data
	local won = false
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			old = normalize(old, snap.day)
			won = old[field][id] ~= true
			old[field][id] = true
			old.count = math.max(old.count, snap.count)
			return old
		end)
	end)
	if not ok then warn("TrashEventService: จองรางวัลไม่สำเร็จ " .. player.Name .. ": " .. tostring(err)) end
	return ok, ok and won
end

local function saveCoinsNow(player)
	local s = ServerScriptService:FindFirstChild("LeaderstatsSetup")
	local ev = s and s:FindFirstChild("SaveCoinsNow")
	if ev then ev:Fire(player) end
end

-- ให้รางวัลที่ถึงแล้วแต่ยังไม่ได้ (ภารกิจรายวัน + โบนัสเก็บหมดของรอบนี้) เรียกซ้ำได้
local function checkRewards(player)
	local st = states[player]
	if not (st and st.loaded) or st.busy then return end
	if player:GetAttribute("CoinsLoaded") ~= true then return end -- เพิ่มเหรียญก่อนโหลด = โดนค่าที่โหลดมาทับ
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("เหรียญ")
	if not coins then return end
	st.busy = true
	local paid = false
	for _, m in ipairs(Config.MILESTONES) do
		local data = st.data
		if data.count >= m.Count and not data.claimed[m.Id] then
			local ok, won = reserve(player, st, "claimed", m.Id)
			if not ok or states[player] ~= st or st.data ~= data then break end
			data.claimed[m.Id] = true
			if won and player.Parent then
				coins.Value += m.Coins
				paid = true
				notify(player, string.format("🎁 ภารกิจเก็บขยะ %d ชิ้น สำเร็จ! +%s เหรียญ", m.Count, comma(m.Coins)),
					string.format("🎁 Trash mission (%d pieces) complete! +%s coins", m.Count, comma(m.Coins)))
				print(string.format("🗑️ TrashEvent: %s รับรางวัลภารกิจ %s (+%d)", player.Name, m.Id, m.Coins))
			end
		end
	end
	local r = round
	if Config.CLEAR_BONUS > 0 and r and r.cleared and states[player] == st and (r.contrib[player.UserId] or 0) > 0 and not st.data.clear[r.key] then
		local data = st.data
		local ok, won = reserve(player, st, "clear", r.key)
		if ok and states[player] == st and st.data == data then
			data.clear[r.key] = true
			if won and player.Parent then
				coins.Value += Config.CLEAR_BONUS
				paid = true
				notify(player, "🦦 ขอบคุณน้า~ ทะเลสาบสะอาดแล้ว! โบนัสคนช่วยเก็บ +" .. comma(Config.CLEAR_BONUS) .. " เหรียญ",
					"🦦 Thank you! The lake is clean! Helper bonus +" .. comma(Config.CLEAR_BONUS) .. " coins")
				print(string.format("🗑️ TrashEvent: %s รับโบนัสเก็บหมด %s (+%d)", player.Name, r.key, Config.CLEAR_BONUS))
			end
		end
	end
	st.busy = nil
	if paid then saveCoinsNow(player) end
	if states[player] == st then publish(player, st) end
end

-- ============ ฉากที่ทะเลสาบ ============
local function lockPart(p)
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.CastShadow = false
end

local function neon(name, size, cf, transparency, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Color = DIRTY_COLOR
	p.Transparency = transparency
	p.Size = size
	p.CFrame = cf
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	lockPart(p)
	p.Parent = parent
	return p
end

local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false
local function isWater(x, z)
	local hit = workspace:Raycast(Vector3.new(x, Config.WATER_Y + 40, z), Vector3.new(0, -80, 0), waterParams)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

local FLOAT_IDS = { "PlasticBottle", "TinCan", "OldTire", "OldBoot", "TornNet", "BambooScrap", "OldPhone", "PlasticBottle", "TinCan", "OldTire" }

local function buildWorld(r)
	local old = workspace:FindFirstChild("TrashEvent")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "TrashEvent"
	local cx, cz, wy = Config.CENTER.X, Config.CENTER.Y, Config.WATER_Y

	-- ลำแสง + แผ่นเรืองบนผิวน้ำ (เห็นได้จากไกล/จากบนฟ้า: โหลดตลอด ไม่ขึ้นกับระยะ streaming)
	local beacon = Instance.new("Model")
	beacon.Name = "Beacon"
	beacon.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local up = CFrame.Angles(0, 0, math.rad(90)) -- แกนทรงกระบอก (X) ตั้งขึ้น
	r.beaconParts = {
		neon("WaterGlow", Vector3.new(0.1, 104, 104), CFrame.new(cx, wy + 0.12, cz - 1) * up, 0.86, beacon),
		neon("PillarOuter", Vector3.new(420, 16, 16), CFrame.new(cx, wy + 210, cz) * up, 0.86, beacon),
		neon("PillarInner", Vector3.new(420, 5, 5), CFrame.new(cx, wy + 210, cz) * up, 0.6, beacon),
	}
	beacon.Parent = folder

	-- ขยะลอยน้ำ (ตำแหน่งสุ่มแบบเดิมทุกรอบ อยู่บนน้ำจริง ห่างฝั่ง ห่างกัน)
	local floaters = Instance.new("Folder")
	floaters.Name = "Floaters"
	floaters.Parent = folder
	r.floaters = {}
	local models = ServerStorage:FindFirstChild("FishModels")
	local rng = Random.new(20261012)
	local placed = {}
	local tries = 0
	while #placed < Config.FLOAT_COUNT and tries < 1500 and models do
		tries += 1
		local a, d = rng:NextNumber(0, math.pi * 2), math.sqrt(rng:NextNumber()) * (Config.RADIUS - 4)
		local x, z = cx + math.cos(a) * d, cz + math.sin(a) * d
		local ok = d > 12 and isWater(x, z) and isWater(x + 6, z) and isWater(x - 6, z) and isWater(x, z + 6) and isWater(x, z - 6)
		if ok then
			for _, p in ipairs(placed) do
				if (p - Vector2.new(x, z)).Magnitude < 9 then ok = false break end
			end
		end
		local template = ok and models:FindFirstChild(FLOAT_IDS[#placed % #FLOAT_IDS + 1])
		if template then
			table.insert(placed, Vector2.new(x, z))
			local m = template:Clone()
			m.Name = "Float_" .. template.Name
			m:ScaleTo(rng:NextNumber(2.6, 3.6))
			m:PivotTo(CFrame.new(x, wy + 0.15, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)))
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					lockPart(p)
					CollectionService:AddTag(p, "TrashFloat") -- หน้าจอทำให้ลอยโยก (TrashEventGui)
				end
			end
			m.Parent = floaters
			table.insert(r.floaters, m)
		end
		if tries % 100 == 0 then task.wait() end
	end
	r.floatTotal = #r.floaters

	-- น้องนากเก็บขยะบนแท่นไม้ข้างจุดวาป
	local npc = Instance.new("Model")
	npc.Name = "OtterNpc"
	npc.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local cf = CFrame.lookAt(Config.NPC_POS, Config.NPC_LOOK) * CFrame.Angles(0, math.pi, 0) -- โมเดลนากหันหน้า +Z
	local platform = assets:FindFirstChild("Platform")
	if platform then
		platform = platform:Clone()
		platform:PivotTo(cf)
		platform.Parent = npc
	end
	local otter = assets:FindFirstChild("OtterCleaner")
	if otter then
		otter = otter:Clone()
		otter:PivotTo(cf)
		otter.Parent = npc
	end
	local anchor = Instance.new("Part")
	anchor.Name = "PromptPart"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.CFrame = cf * CFrame.new(0, 3, 0)
	lockPart(anchor)
	anchor.Parent = npc
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TrashOtterPrompt" -- หน้าจอ (TrashEventGui) เปิดการ์ดอีเวนต์เมื่อกด
	prompt.ObjectText = "🦦 น้องนากเก็บขยะ"
	prompt.ActionText = "คุยกับน้องนาก"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	npc.PrimaryPart = anchor
	CollectionService:AddTag(npc, "TrashOtterNpc") -- หน้าจอทำป้ายเหนือหัว (แยกภาษาได้)
	npc.Parent = folder

	folder.Parent = workspace
	r.folder = folder
end

local function setBeaconColor(r, color)
	for _, p in ipairs(r.beaconParts or {}) do
		if p.Parent then p.Color = color end
	end
end

-- ขยะลอยน้ำหายตามความคืบหน้าของเซิร์ฟ (หายแล้วไม่กลับมา)
local function updateFloaters(r)
	local total = r.floatTotal or 0
	local remain = r.cleared and 0 or math.ceil(total * (1 - math.clamp(r.collected / math.max(1, r.goal), 0, 1)))
	while #r.floaters > remain do
		local m = table.remove(r.floaters)
		if m then m:Destroy() end
	end
end

local function publishRound(r)
	workspace:SetAttribute("TrashEventCollected", r.collected)
	workspace:SetAttribute("TrashEventGoal", Config.GOAL_ENABLED and r.goal or 0) -- 0 = ไม่มีเป้ารวม (หน้าจอแสดงแค่ยอดที่เก็บได้)
	workspace:SetAttribute("TrashEventCleared", r.cleared == true)
end

local function participants(r)
	local n = 0
	for _ in pairs(r.contrib) do n += 1 end
	return n
end

local function clearLake(r)
	r.cleared = true
	setBeaconColor(r, CLEAN_COLOR)
	updateFloaters(r)
	publishRound(r)
	print(string.format("🗑️ TrashEvent: เก็บขยะครบ %d/%d ทะเลสาบสะอาดแล้ว (รอบ %s)", r.collected, r.goal, r.key))
	for _, player in ipairs(Players:GetPlayers()) do
		if Config.CLEAR_BONUS > 0 and (r.contrib[player.UserId] or 0) > 0 then
			task.spawn(checkRewards, player) -- แจ้งพร้อมโบนัส (ตอนนี้ CLEAR_BONUS = 0 จึงไม่เข้าทางนี้)
		else
			notify(player, "🦦 ทะเลสาบหมอกเช้าสะอาดแล้ว! ขอบคุณทุกคนที่ช่วยกันเก็บขยะ", "🦦 Misty Lake is clean! Thanks to everyone who helped")
		end
	end
end

-- ============ นับขยะ ============
local function addJunk(player, pos, amount)
	local r = round
	if not r or typeof(player) ~= "Instance" or typeof(pos) ~= "Vector3" or not Config.InArea(pos) then return end
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 5)
	local st = states[player]
	if not st then return end
	r.contrib[player.UserId] = (r.contrib[player.UserId] or 0) + amount
	r.collected += amount
	if Config.GOAL_ENABLED and not r.cleared then
		r.goal = math.max(Config.GOAL_MIN, Config.GOAL_PER_PLAYER * participants(r)) -- เป้าตามจำนวนคนที่มาช่วยจริง
	end
	if st.loaded then
		rollover(player, st)
		st.data.count += amount
		st.dirty = true
	else
		st.queued = (st.queued or 0) + amount
	end
	publish(player, st)
	if not Config.GOAL_ENABLED then
		publishRound(r) -- ไม่จำกัดขยะ (2026-10-13): ขยะลอยน้ำไม่หาย ไม่มีสถานะ "เก็บครบ" นับยอดรวมอย่างเดียว
	elseif not r.cleared and r.collected >= r.goal then
		clearLake(r)
	else
		updateFloaters(r)
		publishRound(r)
	end
	task.spawn(checkRewards, player)
end
junkCaught.Event:Connect(function(player, pos, amount)
	local ok, err = pcall(addJunk, player, pos, amount)
	if not ok then warn("TrashEventService: นับขยะผิดพลาด: " .. tostring(err)) end
end)

-- ============ เปิด/ปิดรอบ ============
-- ประกาศตอนอีเวนต์เริ่มทำที่หน้าจอ (TrashEventGui: น้องนากโผล่ออกมาแล้วขึ้นข้อความ) เซิร์ฟเวอร์ไม่ส่งข้อความซ้ำ (2026-10-12 ผู้ใช้ขอ)
local function startRound(idx, endsAt)
	local r = {
		idx = idx, endsAt = endsAt, collected = 0, goal = Config.GOAL_MIN, cleared = false, contrib = {}, floaters = {},
		key = idx > 0 and ("r" .. idx) or ("dev" .. os.time()),
	}
	local ok, err = pcall(buildWorld, r)
	if not ok then warn("TrashEventService: สร้างฉากไม่สำเร็จ: " .. tostring(err)) end
	round = r
	publishRound(r)
	workspace:SetAttribute("TrashEventEndsAt", endsAt)
	workspace:SetAttribute("TrashEventRound", Config.DayKey() .. "#" .. r.key)
	workspace:SetAttribute("TrashEventActive", true) -- หน้าจอ (TrashEventGui) เห็นค่านี้แล้วให้น้องนากโผล่มาประกาศเอง
	print(string.format("🗑️ TrashEvent: เริ่มรอบ %s (อีก %d วินาที) ขยะลอยน้ำ %d ชิ้น", r.key, endsAt - os.time(), r.floatTotal or 0))
end

local function stopRound()
	local r = round
	if not r then return end
	round = nil
	workspace:SetAttribute("TrashEventActive", false)
	workspace:SetAttribute("TrashEventCleared", false)
	if r.folder then r.folder:Destroy() end
	for _, player in ipairs(Players:GetPlayers()) do
		notify(player, "🦦 อีเวนต์เก็บขยะจบแล้ว ขอบคุณที่มาช่วยน้องนากนะ!", "🦦 The trash event is over. Thanks for helping the otter!")
	end
	print(string.format("🗑️ TrashEvent: จบรอบ %s เก็บได้ %d/%d%s", r.key, r.collected, r.goal, r.cleared and " (เก็บหมด)" or ""))
end

-- ============ ผู้เล่นเข้า/ออก ============
local function onPlayerAdded(player)
	local st = { data = fresh(Config.DayKey()), loaded = false, dirty = false, lastSave = os.clock(), queued = 0 }
	states[player] = st
	local ok, data = DataLoadRetry.Load(player, "TrashEvent", DataLoadRetry.Get(store, keyOf(player)), function() return states[player] == st end)
	if not ok or states[player] ~= st then return end
	st.data = normalize(data, Config.DayKey())
	st.loaded = true
	if st.queued > 0 then
		st.data.count += st.queued
		st.queued = 0
		st.dirty = true
	end
	publish(player, st)
	player:SetAttribute("TrashLoaded", true)
	task.spawn(checkRewards, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	if st and st.loaded and st.dirty then
		DataLoadRetry.BeginLeaveSave(player.UserId)
		pcall(save, player, st)
		DataLoadRetry.EndLeaveSave(player.UserId)
	end
end)

game:BindToClose(function()
	for player, st in pairs(states) do
		if st.loaded and st.dirty then task.spawn(save, player, st) end
	end
	task.wait(2)
end)

-- ============ วงหลัก ============
local devEndsAt = nil
local adminEndsAt = nil -- รอบที่เจ้าของเกมสั่งเองด้วย /trash (เวลาจบ unix)
local function wanted()
	local now = os.time()
	if adminEndsAt then
		if now < adminEndsAt then return 0, adminEndsAt end
		adminEndsAt = nil
	end
	if RunService:IsStudio() then
		local dev = workspace:GetAttribute("DevTrashEvent")
		if dev == false then devEndsAt = nil return nil end
		if dev == true then
			if not devEndsAt then devEndsAt = now + (tonumber(workspace:GetAttribute("DevTrashSeconds")) or Config.DURATION) end
			if now < devEndsAt then return 0, devEndsAt end
			workspace:SetAttribute("DevTrashEvent", nil)
			devEndsAt = nil
		else
			devEndsAt = nil
		end
	end
	if not Config.ENABLED then return nil end
	return Config.Schedule(now)
end

-- ============ คำสั่งแชทของเจ้าของเกม: /trash ============
local TextChatService = game:GetService("TextChatService")
local ADMINS = { [9360333174] = true } -- เจ้าของเกม (One_moretime91)
if game.CreatorType == Enum.CreatorType.User then ADMINS[game.CreatorId] = true end
local lastCommand = {} -- [player] = { text, clock } กันทำซ้ำ (TextChatCommand + Chatted อาจยิงทั้งคู่)
local function handleCommand(player, text)
	if not (player and ADMINS[player.UserId]) or type(text) ~= "string" then return end
	local arg = text:lower():match("^%s*/trash%s*(.-)%s*$")
	if arg == nil then return end
	local prev = lastCommand[player]
	if prev and prev.text == text and os.clock() - prev.clock < 2 then return end
	lastCommand[player] = { text = text, clock = os.clock() }
	if arg == "stop" or arg == "off" or arg == "cancel" then
		adminEndsAt = nil
		harvestNotify:FireClient(player, nil, nil, nil, "🗑️ สั่งจบรอบทดสอบอีเวนต์เก็บขยะแล้ว (รอบตามเวลาปกติไม่ถูกปิด)")
		return
	end
	local minutes = math.clamp(math.floor(tonumber(arg) or (Config.DURATION / 60)), 1, 60)
	adminEndsAt = os.time() + minutes * 60
	harvestNotify:FireClient(player, nil, nil, nil, string.format("🗑️ เริ่มรอบทดสอบอีเวนต์เก็บขยะ %d นาที (เฉพาะเซิร์ฟนี้) · จบก่อนเวลา: /trash stop", minutes))
	print(string.format("🗑️ TrashEvent: %s สั่งเริ่มรอบทดสอบ %d นาที", player.Name, minutes))
end
local okCmd, errCmd = pcall(function()
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "TrashEventCommand"
	cmd.PrimaryAlias = "/trash"
	cmd.Parent = folder
	cmd.Triggered:Connect(function(source, text)
		handleCommand(source and Players:GetPlayerByUserId(source.UserId), text)
	end)
end)
if not okCmd then warn("TrashEventService: สร้างคำสั่งแชทไม่สำเร็จ: " .. tostring(errCmd)) end
local function hookAdmin(player)
	if not ADMINS[player.UserId] then return end
	player.Chatted:Connect(function(message) handleCommand(player, message) end)
end
Players.PlayerAdded:Connect(hookAdmin)
for _, p in ipairs(Players:GetPlayers()) do hookAdmin(p) end
Players.PlayerRemoving:Connect(function(player) lastCommand[player] = nil end)

workspace:SetAttribute("TrashEventActive", false)
local tick = 0
while true do
	local okLoop, errLoop = pcall(function()
		local idx, endsAt = wanted()
		if round and (idx == nil or idx ~= round.idx) then stopRound() end
		if idx and not round then startRound(idx, endsAt) end
		tick += 1
		if tick % 5 == 0 then
			for player, st in pairs(states) do
				rollover(player, st)
				task.spawn(checkRewards, player)
				if st.loaded and st.dirty and os.clock() - st.lastSave >= SAVE_EVERY then task.spawn(save, player, st) end
			end
		end
	end)
	if not okLoop then warn("TrashEventService: " .. tostring(errLoop)) end
	task.wait(1)
end
