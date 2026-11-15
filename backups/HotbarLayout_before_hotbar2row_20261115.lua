-- BACKUP 2026-11-15 ก่อนทำ hotbar 2 แถว (12 ช่อง + ปุ่มย่อ)
-- Studio path: game.ServerScriptService.HotbarLayout (Script)
-- คืนค่า: เปิดสคริปต์นี้ใน Studio แล้ววางโค้ดด้านล่าง (ใต้บรรทัด ===) ทับทั้งหมด
-- ========================================================================
-- HotbarLayout: เซฟว่าของชิ้นไหนอยู่ช่องไหนในแถบ 9 ช่อง (DataStore "HotbarLayout_v1")
-- เดิมแถบ 9 ช่องจำไว้แค่ฝั่งผู้เล่นระหว่างเล่น เข้าเกมใหม่ของทุกชิ้นถูกจัดลงช่องใหม่หมด
-- (เช่น เก็บเบ็ดเข้ากระเป๋าแล้ว เข้าเกมใหม่เบ็ดกลับมาอยู่ในแถบ) ตอนนี้กลับมาอยู่ช่องเดิม / ที่เก็บไว้ก็อยู่ในกระเป๋าต่อ
-- ผู้เล่น (HotbarState) ส่ง key ของของในแต่ละช่องมาทาง RemoteEvents.HotbarLayoutSave
-- ตอนเข้าเกมตั้ง Attribute "HotbarLayout" (JSON) + "HotbarLayoutLoaded" ให้ผู้เล่นเอาไปจัดช่อง
-- เก็บแค่ "ของชนิดไหนอยู่ช่องไหน" ไม่ใช่ของจริง (ของจริงอยู่ที่ InventorySystem) ส่งมาผิดๆ ก็ไม่ได้ของเพิ่ม

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local store = DataStoreService:GetDataStore("HotbarLayout_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local remote = remoteEvents:FindFirstChild("HotbarLayoutSave")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "HotbarLayoutSave"
	remote.Parent = remoteEvents
end

local MAX_SLOTS = 9
local MAX_KEY_LENGTH = 120
local AUTOSAVE_INTERVAL = 120

local layouts = {} -- [player] = { key1..key9 } ("" = ช่องว่าง)
local dirty = {}   -- [player] = true ถ้ามีการเปลี่ยนที่ยังไม่เซฟ
local loadOk = {}  -- [player] = true ถ้าโหลดสำเร็จ (โหลดพัง = ไม่เซฟทับของเดิม)

-- 2026-10-11 (ผู้เล่นแจ้ง: รีเซิร์ฟแล้วเมล็ดในช่อง 1-2 ไปอยู่ช่องอื่น สัตว์เลยไม่ปลูกให้)
-- เดิม: อ่านไม่ได้ 3 ครั้ง (หลังรีเซิร์ฟทุกคนเข้าพร้อมกัน DataStore โดนจำกัด) ก็บอกฝั่งผู้เล่นว่า "โหลดแล้ว" ทั้งที่ไม่มีข้อมูล
--   → หน้าจอจัดของลงช่องใหม่ตามลำดับที่ของมาถึง แล้วส่งกลับมาเซฟทับช่องเดิม
-- ใหม่: ลองจนอ่านได้ (DataLoadRetry.Load รอเซฟตอนออกรอบก่อนด้วย) ค่อยตั้ง HotbarLayoutLoaded · ก่อนอ่านได้ไม่รับช่องจากฝั่งผู้เล่น
--   ฝั่งผู้เล่น (HotbarState) รอ แล้วจัดช่องตามที่เซฟเมื่อข้อมูลมาถึง แม้จะมาช้า
local SAVE_TRIES = 3
local pendingSaves = 0

local function load(player)
	local ok, data = DataLoadRetry.Load(player, "HotbarLayout", DataLoadRetry.Get(store, tostring(player.UserId)))
	if not ok or not player.Parent then return end
	loadOk[player] = true
	if type(data) == "table" and type(data.slots) == "table" then
		layouts[player] = data.slots
		player:SetAttribute("HotbarLayout", HttpService:JSONEncode(data.slots))
	end
	player:SetAttribute("HotbarLayoutLoaded", true)
end

-- leaving = เซฟตอนออก/ปิดเซิร์ฟ: ลองซ้ำได้ (ทุกระบบเซฟพร้อมกันตอนปิดเซิร์ฟ ครั้งเดียวมักโดนจำกัด) + ทำเครื่องหมายให้รอบเข้าใหม่รอ
local function save(player, leaving)
	if not (dirty[player] and loadOk[player] and layouts[player]) then return end
	local userId = player.UserId
	local name = player.Name
	local slots = layouts[player]
	dirty[player] = nil
	pendingSaves += 1
	if leaving then DataLoadRetry.BeginLeaveSave(userId) end
	local ok, err
	for attempt = 1, (leaving and SAVE_TRIES or 1) do
		ok, err = pcall(function()
			store:SetAsync(tostring(userId), { slots = slots })
		end)
		if ok then break end
		if leaving and attempt < SAVE_TRIES then task.wait(attempt * 2 + math.random()) end
	end
	if leaving then DataLoadRetry.EndLeaveSave(userId) end
	pendingSaves -= 1
	if not ok then
		if layouts[player] == slots then dirty[player] = true end
		warn("HotbarLayout: เซฟไม่สำเร็จ " .. name .. ": " .. tostring(err))
	end
end

remote.OnServerEvent:Connect(function(player, slots)
	if type(slots) ~= "table" then return end
	if not loadOk[player] then return end -- ยังอ่านช่องเดิมไม่ได้ = ไม่รับ (กันช่องชั่วคราวของหน้าจอมาเซฟทับ)
	local clean = {}
	for i = 1, MAX_SLOTS do
		local key = slots[i]
		clean[i] = (type(key) == "string" and #key <= MAX_KEY_LENGTH) and key or ""
	end
	layouts[player] = clean
	dirty[player] = true
end)

-- 2026-10-14 ให้สคริปต์ฝั่งเซิร์ฟเวอร์อื่นถามได้ว่าตอนนี้ผู้เล่นวางของชนิดไหนไว้ในแถบช่องลัด (ผีน้อยปักหุ่นใช้เฉพาะหุ่นที่อยู่ในแถบ)
-- BindableFunction ServerStorage.HotbarLayoutQuery: Invoke(player) -> { key ช่อง 1..9 } ("" = ว่าง) หรือ nil ถ้ายังไม่รู้ (key แบบเดียวกับ HotbarState.ToolKey)
local ServerStorage = game:GetService("ServerStorage")
local layoutQuery = ServerStorage:FindFirstChild("HotbarLayoutQuery")
if not layoutQuery then
	layoutQuery = Instance.new("BindableFunction")
	layoutQuery.Name = "HotbarLayoutQuery"
	layoutQuery.Parent = ServerStorage
end
layoutQuery.OnInvoke = function(player)
	local slots = layouts[player]
	if not slots then return nil end
	return table.clone(slots)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(load, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	task.spawn(save, player, true) -- ไม่บล็อก (ลองซ้ำได้หลายวิ) อ่านค่าไปแล้วก่อนล้างตารางด้านล่าง
	layouts[player] = nil
	dirty[player] = nil
	loadOk[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player, true)
	end
	task.wait(0.5)
	local t0 = os.clock()
	while pendingSaves > 0 and os.clock() - t0 < 20 do task.wait(0.2) end
end)

-- เซฟล่วงหน้าก่อนรีเซิร์ฟ (ServerScriptService.RestartNotice ยิงทีละคน เหมือน LastPosition)
task.spawn(function()
	local ev = game:GetService("ServerScriptService"):WaitForChild("PreRestartSave", 60)
	if not ev then return end
	ev.Event:Connect(function(player)
		task.spawn(save, player, false)
	end)
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			save(player)
		end
	end
end)
