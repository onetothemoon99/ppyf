-- BACKUP of ServerScriptService.PlaytimeRewards before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into ServerScriptService.PlaytimeRewards.Source in Studio
-- PlaytimeRewards: ตั๋วฟรีจากเวลาออนไลน์ + เหรียญรายวันระหว่างทาง (ค่าต่างๆ ดู ReplicatedStorage.PlaytimeConfig)
-- เก็บใน DataStore "PlaytimeRewards_v1": { day, progress (วินาทีสะสมสู่ตั๋วใบถัดไป), ticketsToday, dayOnline, milestones, undelivered }
-- ตั๋วแต่ละใบมีเลขใบเสร็จตายตัว "PT-<วัน>-<ใบที่>" ส่งผ่าน GachaTickets.Add ที่กันใบเสร็จซ้ำอยู่แล้ว
--   เซฟ "ได้ตั๋วแล้ว" ก่อน แล้วค่อยส่งตั๋ว ส่งไม่สำเร็จเก็บไว้ใน undelivered ลองใหม่เรื่อยๆ (ไม่หาย ไม่เบิ้ล)
-- ตั้ง Attribute ให้หน้าจอ: PlaytimeProgress, PlaytimeTicketsToday, PlaytimeDayOnline, PlaytimeTotal (นาทีที่เล่นสะสมทั้งหมด)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("PlaytimeConfig"))
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig"))
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")

local store = DataStoreService:GetDataStore("PlaytimeRewards_v1")
-- อันดับเวลาเล่นสะสม (นาที) ให้ป้าย PlaytimeBoard ดึงไปเรียง เขียนทุกครั้งที่เซฟ
local rankStore = DataStoreService:GetOrderedDataStore("PlaytimeLeaderboard_v1")
local TICK = 5          -- นับทุกกี่วินาที
local SAVE_EVERY = 60   -- เซฟความคืบหน้าทุกกี่วินาที
local TICKET_SECONDS = Config.TICKET_MINUTES * 60

local states = {} -- [player] = { data, loaded, lastSave }

local function notify(player, message)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, message) end
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.day = tonumber(d.day) or Config.DayNumber()
	d.progress = math.max(0, tonumber(d.progress) or 0)
	d.ticketsToday = math.max(0, math.floor(tonumber(d.ticketsToday) or 0))
	d.dayOnline = math.max(0, tonumber(d.dayOnline) or 0)
	d.totalOnline = math.max(0, tonumber(d.totalOnline) or 0) -- วินาทีที่เล่นสะสมทั้งหมด (เริ่มนับตั้งแต่มีระบบนี้)
	d.milestones = type(d.milestones) == "table" and d.milestones or {}
	d.undelivered = type(d.undelivered) == "table" and d.undelivered or {}
	return d
end

-- ขึ้นวันใหม่ (เที่ยงคืนเวลาไทย): โควตาตั๋ว/ของรายวันเริ่มใหม่ เวลาที่สะสมไว้ยังอยู่
local function rollDay(d)
	local today = Config.DayNumber()
	if d.day ~= today then
		d.day = today
		d.ticketsToday = 0
		d.dayOnline = 0
		d.milestones = {}
	end
end

-- (2026-10-02 ผู้เล่นขอ) ไม่แสดง "เวลาเล่น" บนตารางอันดับ (leaderstats) แล้ว: เวลาเล่นสะสมยังนับและเก็บเหมือนเดิม
--   ใช้กับตั๋วฟรี/ป้าย PlaytimeBoard (OrderedDataStore) และแถว PlaytimeTotal ในกล่องสถานะ ผ่าน Attribute PlaytimeTotal

local function publish(player, d)
	if not player.Parent then return end
	player:SetAttribute("PlaytimeProgress", math.floor(d.progress))
	player:SetAttribute("PlaytimeTicketsToday", d.ticketsToday)
	player:SetAttribute("PlaytimeDayOnline", math.floor(d.dayOnline))
	player:SetAttribute("PlaytimeTotal", math.floor(d.totalOnline / 60))
end

local function save(player, st)
	if not st.loaded then return false end
	st.lastSave = os.clock()
	-- 2026-10-29 InternalServerError (UpdateAsync PlaytimeRewards_v1): ลองซ้ำ 3 ครั้ง (รอ 2, 4 วิ) เดิมลองครั้งเดียว ตอนออกเกมพลาด = เวลาเล่นล่าสุดหาย
	local ok, err
	for attempt = 1, 3 do
		ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function()
				return st.data
			end)
		end)
		if ok then break end
		if attempt < 3 then task.wait(2 ^ attempt) end
	end
	if not ok then warn("PlaytimeRewards: เซฟไม่สำเร็จสำหรับ " .. player.Name .. " หลังลอง 3 ครั้ง: " .. tostring(err)) end
	local minutes = math.floor(st.data.totalOnline / 60)
	if minutes > 0 then
		pcall(function() rankStore:SetAsync(tostring(player.UserId), minutes) end)
	end
	return ok
end

-- ส่งตั๋วที่ได้แล้วแต่ยังไม่ถึงมือ (ใบเสร็จเดิมส่งซ้ำก็ไม่เบิ้ล)
local delivering = {}
local function deliver(player, st)
	if delivering[player] then return end
	delivering[player] = true
	local remaining = {}
	for _, receiptId in ipairs(st.data.undelivered) do
		local balance = player.Parent and GachaTickets.Add(player, Config.TICKET_TYPE, 1, receiptId)
		if balance then
			local ticketType = GachaConfig.TicketTypes[Config.TICKET_TYPE]
			notify(player, string.format("%s ได้%sฟรีจากเวลาเล่น! (วันนี้ %d/%d) มีอยู่ %d ใบ",
				ticketType.Icon, ticketType.DisplayName, st.data.ticketsToday, Config.DAILY_TICKET_CAP, balance))
		else
			table.insert(remaining, receiptId)
		end
	end
	st.data.undelivered = remaining
	delivering[player] = nil
	if player.Parent then save(player, st) end
end

local function giveMilestones(player, d)
	for _, m in ipairs(Config.Milestones) do
		local key = tostring(m.Minutes)
		if not d.milestones[key] and d.dayOnline >= m.Minutes * 60 then
			local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
			if coins then -- ยังโหลดเหรียญไม่เสร็จ = รอรอบหน้า
				coins.Value += m.Coins
				d.milestones[key] = true
				notify(player, string.format("⏰ ออนไลน์ครบ %d นาทีวันนี้ รับ 💰 %d เหรียญ!", m.Minutes, m.Coins))
			end
		end
	end
end

local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function onPlayerAdded(player)
	local st = { data = nil, loaded = false, lastSave = os.clock() }
	states[player] = st
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = ไม่นับเวลาเล่นทั้งรอบตอน DataStore throttle) 2026-10-09
	local ok, data = DataLoadRetry.Load(player, "PlaytimeRewards", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
	if ok then
		st.data = normalize(data)
		st.loaded = true
	end
	if not st.loaded or not player.Parent then return end -- โหลดไม่ได้ = ไม่นับ (กันเขียนทับของเดิม)
	rollDay(st.data)
	publish(player, st.data)
	if #st.data.undelivered > 0 then task.spawn(deliver, player, st) end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	if st and st.loaded then
		DataLoadRetry.BeginLeaveSave(player.UserId) -- เข้าเซิร์ฟเดิมทันที = รอเซฟนี้ก่อนโหลด (2026-10-10)
		pcall(save, player, st)
		DataLoadRetry.EndLeaveSave(player.UserId)
	end
end)

game:BindToClose(function()
	local pending = 0
	for player, st in pairs(states) do
		if st.loaded then
			pending += 1
			task.spawn(function()
				pcall(save, player, st)
				pending -= 1
			end)
		end
	end
	local deadline = os.clock() + 20 -- รอเซฟ (รวมลองซ้ำ) ให้จบ สูงสุด 20 วิ
	while pending > 0 and os.clock() < deadline do task.wait(0.2) end
end)

-- แอดมินชดเชยเวลาเล่น (/gift ใน AdminGive, 2026-11-05): บวกในหน่วยความจำของเซิร์ฟที่ผู้เล่นอยู่ แล้วเซฟ จึงไม่ถูกเซฟทับ
--   บวกเฉพาะเวลาสะสม totalOnline ไม่นับตั๋ว/รางวัลรายวัน · grantId เดิม = ไม่บวกซ้ำ · คืน true เมื่อบวกแล้ว (เซฟพลาดจะลงรอบถัดไปหรือตอนออกเกม)
local addPlaytime = Instance.new("BindableFunction")
addPlaytime.Name = "AddPlaytime"
addPlaytime.OnInvoke = function(player, seconds, grantId)
	if type(seconds) ~= "number" or seconds <= 0 or type(grantId) ~= "string" then return false end
	local t0 = os.clock()
	local st = states[player]
	while not (st and st.loaded) and player.Parent and os.clock() - t0 < 60 do
		task.wait(0.5)
		st = states[player]
	end
	if not (st and st.loaded) or states[player] ~= st or not player.Parent then return false end
	local d = st.data
	d.grants = type(d.grants) == "table" and d.grants or {}
	if d.grants[grantId] then return true end
	d.grants[grantId] = seconds
	d.totalOnline += seconds
	publish(player, d)
	save(player, st)
	return true
end
addPlaytime.Parent = script

-- นับเวลา
while true do
	task.wait(TICK)
	for player, st in pairs(states) do
		if st.loaded and player.Parent then
			local d = st.data
			rollDay(d)
			d.dayOnline += TICK
			d.totalOnline += TICK
			giveMilestones(player, d)
			if d.ticketsToday < Config.DAILY_TICKET_CAP then
				d.progress += TICK
				if d.progress >= TICKET_SECONDS then
					d.progress -= TICKET_SECONDS
					d.ticketsToday += 1
					table.insert(d.undelivered, string.format("PT-%d-%d", d.day, d.ticketsToday))
					task.spawn(function()
						save(player, st) -- จำว่าได้ตั๋วใบนี้แล้วก่อน ค่อยส่ง
						deliver(player, st)
					end)
				end
			else
				d.progress = 0 -- ครบโควตาวันนี้แล้ว เริ่มนับใหม่พรุ่งนี้
			end
			publish(player, d)
			if os.clock() - st.lastSave >= SAVE_EVERY then task.spawn(save, player, st) end
		end
	end
end
