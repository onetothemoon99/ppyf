-- BACKUP of ServerScriptService.RestartNotice before Thai/English system text (i18n phase 3, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.RestartNotice.Source in Studio
-- RestartNotice: แจ้งผู้เล่นทุกเซิร์ฟก่อนรีเซิร์ฟ + เซฟข้อมูลล่วงหน้า (สร้าง 2026-10-09)
-- เจ้าของเกมพิมพ์ในแชท: /restart 5 (นาที 1-30, ไม่ใส่ = 5) · /restart cancel = ยกเลิก
--   -> MessagingService ส่งทุกเซิร์ฟ -> ตั้ง Attribute "RestartEndsAt" (เวลา unix) ที่ ReplicatedStorage หน้าจอ RestartNoticeGui นับถอยหลัง
--   เหลือ PRESAVE_AT วิ = เซฟล่วงหน้าทีละคน (เว้นช่วง ไม่ให้เซฟพร้อมกัน) ผ่าน BindableEvent ServerScriptService.PreRestartSave:Fire(player)
--   (ตำแหน่ง / สถานะตกปลา / เหรียญ / กระเป๋า) ตอนปิดเซิร์ฟจริงจะเหลือสิ่งที่ต้องเซฟน้อยลงมาก (กันโดนจำกัดการเขียน เหมือนรีเซิร์ฟ 22:14)
-- หมดเวลาแล้วเจ้าของกด Shut Down / Migrate ใน Creator Dashboard เอง (เกมไม่ได้ปิดเซิร์ฟเอง) · เกินเวลา STALE_AFTER แล้วยังไม่ปิด = แถบหายเอง
-- ทดสอบใน Studio: พิมพ์คำสั่งเดียวกันได้ (บัญชี Studio = เจ้าของ) หรือตั้ง ReplicatedStorage Attribute RestartEndsAt ตรงๆ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")
local TextChatService = game:GetService("TextChatService")

local TOPIC = "RestartNotice"
local DEFAULT_MINUTES, MIN_MINUTES, MAX_MINUTES = 5, 1, 30
local PRESAVE_AT = 45      -- เหลือกี่วิเริ่มเซฟล่วงหน้า
local PRESAVE_GAP = 0.6    -- วิ ระหว่างผู้เล่นแต่ละคน
local STALE_AFTER = 300    -- หมดเวลาแล้วยังไม่รีเซิร์ฟกี่วิ แถบจะหาย

local ADMINS = { [9360333174] = true } -- เจ้าของเกม (One_moretime91)
if game.CreatorType == Enum.CreatorType.User then ADMINS[game.CreatorId] = true end

local preSave = ServerScriptService:FindFirstChild("PreRestartSave")
if not preSave then
	preSave = Instance.new("BindableEvent")
	preSave.Name = "PreRestartSave"
	preSave.Parent = ServerScriptService
end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local token = 0 -- เปลี่ยนทุกครั้งที่เริ่ม/ยกเลิก (กันนับถอยหลังเก่าทำงานต่อ)

local function preSaveAll(myToken)
	local list = Players:GetPlayers()
	print("🔄 RestartNotice: เซฟล่วงหน้า " .. #list .. " คน")
	for _, player in ipairs(list) do
		if token ~= myToken then return end
		if player.Parent then preSave:Fire(player) end
		task.wait(PRESAVE_GAP)
	end
end

-- เริ่ม/ยกเลิกในเซิร์ฟเวอร์นี้ (ทุกเซิร์ฟได้รับจาก MessagingService)
local function apply(data)
	if type(data) ~= "table" then return end
	token += 1
	local myToken = token
	if data.action == "cancel" then
		ReplicatedStorage:SetAttribute("RestartEndsAt", nil)
		print("🔄 RestartNotice: ยกเลิกแจ้งรีเซิร์ฟ")
		for _, p in ipairs(Players:GetPlayers()) do
			harvestNotify:FireClient(p, nil, nil, nil, "✅ ยกเลิกการรีสตาร์ทเซิร์ฟเวอร์แล้ว เล่นต่อได้เลย")
		end
		return
	end
	if data.action ~= "start" or type(data.endsAt) ~= "number" then return end
	local endsAt = data.endsAt
	ReplicatedStorage:SetAttribute("RestartEndsAt", endsAt)
	print("🔄 RestartNotice: จะรีเซิร์ฟใน " .. math.max(0, endsAt - os.time()) .. " วิ")
	task.spawn(function()
		-- รอถึงช่วงเซฟล่วงหน้า (เหลือเวลาน้อยกว่านั้นอยู่แล้ว = เซฟเลย)
		while token == myToken and os.time() < endsAt - PRESAVE_AT do task.wait(1) end
		if token ~= myToken then return end
		preSaveAll(myToken)
		-- หมดเวลานานแล้วยังไม่ถูกปิด = เอาแถบออก
		while token == myToken and os.time() < endsAt + STALE_AFTER do task.wait(5) end
		if token == myToken then ReplicatedStorage:SetAttribute("RestartEndsAt", nil) end
	end)
end

-- สั่งนับถอยหลัง/ยกเลิก เฉพาะเซิร์ฟเวอร์นี้ จากสคริปต์อื่น (AutoRestart รีสตาร์ทตามเวลา) 2026-10-14
-- ServerScriptService.RestartNoticeLocal:Fire({ action = "start", endsAt = <unix> }) / ({ action = "cancel" })
local localTrigger = Instance.new("BindableEvent")
localTrigger.Name = "RestartNoticeLocal"
localTrigger.Event:Connect(apply)
localTrigger.Parent = ServerScriptService

-- ส่งให้ทุกเซิร์ฟ (รวมตัวเอง) · ส่งไม่ได้ = อย่างน้อยทำในเซิร์ฟนี้
local subscribed = false
local function broadcast(data)
	local ok, err = pcall(function() MessagingService:PublishAsync(TOPIC, data) end)
	if not ok or not subscribed then
		warn("RestartNotice: ส่งทุกเซิร์ฟไม่สำเร็จ (ทำเฉพาะเซิร์ฟนี้): " .. tostring(err))
		apply(data)
	end
	return ok
end

task.spawn(function()
	for attempt = 1, 5 do
		local ok, err = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message) apply(message.Data) end)
		end)
		if ok then subscribed = true return end
		warn("RestartNotice: ต่อ MessagingService ไม่สำเร็จ (ครั้งที่ " .. attempt .. "): " .. tostring(err))
		task.wait(5 * attempt)
	end
end)

-- ============ คำสั่งแชท (เฉพาะเจ้าของ) ============
local lastCommand = {} -- [player] = { text, clock } กันทำซ้ำ (TextChatCommand + Chatted อาจยิงทั้งคู่)
local function handleCommand(player, text)
	if not (player and ADMINS[player.UserId]) or type(text) ~= "string" then return end
	local arg = text:lower():match("^%s*/restart%s*(.-)%s*$")
	if arg == nil then return end
	local prev = lastCommand[player]
	if prev and prev.text == text and os.clock() - prev.clock < 2 then return end
	lastCommand[player] = { text = text, clock = os.clock() }
	if arg == "cancel" or arg == "stop" then
		broadcast({ action = "cancel" })
		harvestNotify:FireClient(player, nil, nil, nil, "🔄 ส่งคำสั่งยกเลิกไปทุกเซิร์ฟแล้ว")
		return
	end
	local minutes = tonumber(arg) or DEFAULT_MINUTES
	minutes = math.clamp(math.floor(minutes), MIN_MINUTES, MAX_MINUTES)
	local endsAt = os.time() + minutes * 60
	broadcast({ action = "start", endsAt = endsAt, by = player.Name })
	harvestNotify:FireClient(player, nil, nil, nil, string.format("🔄 แจ้งทุกเซิร์ฟแล้ว: รีสตาร์ทใน %d นาที · หมดเวลาแล้วกด Shut Down ใน Dashboard · ยกเลิก: /restart cancel", minutes))
end

-- TextChatService: คำสั่งที่สร้างฝั่งเซิร์ฟเวอร์ยิง Triggered ที่เซิร์ฟเวอร์ (ข้อความคำสั่งไม่ขึ้นแชทให้คนอื่นเห็น)
local okCmd, errCmd = pcall(function()
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "RestartNoticeCommand"
	cmd.PrimaryAlias = "/restart"
	cmd.Parent = folder
	cmd.Triggered:Connect(function(source, text)
		local player = source and Players:GetPlayerByUserId(source.UserId)
		handleCommand(player, text)
	end)
end)
if not okCmd then warn("RestartNotice: สร้างคำสั่งแชทไม่สำเร็จ: " .. tostring(errCmd)) end

-- เผื่อ TextChatCommand ไม่ยิงที่เซิร์ฟเวอร์: ฟัง Chatted ด้วย (กันซ้ำด้วย lastCommand)
local function hookPlayer(player)
	if not ADMINS[player.UserId] then return end
	player.Chatted:Connect(function(message) handleCommand(player, message) end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerRemoving:Connect(function(player) lastCommand[player] = nil end)
