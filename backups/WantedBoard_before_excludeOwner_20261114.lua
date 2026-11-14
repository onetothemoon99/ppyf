-- BACKUP 2026-11-14: game.ServerScriptService.Orchard.WantedBoard (Script) before adding the game owner 9360333174 to the live EXCLUDE list (WANTED board reset)
-- Restore: open ServerScriptService.Orchard.WantedBoard in Studio, replace its whole Source with everything below the next line.
-- Only the EXCLUDE table differs from the edited version.
-- ===== SOURCE =====
-- WantedBoard: ป้าย WANTED โจรขโมยผลไม้มากที่สุดทั้งเกม (ผู้ใช้สั่ง 2026-11-02) หน้าทางเข้าสวน workspace.Orchard.Decor.WantedBoard
-- ใบใหญ่ Poster1 = อันดับ 1 (รูปหน้า ชื่อ จำนวนครั้ง) · ใบเล็ก Poster2-5 = อันดับ 2-5 · SurfaceGui สร้างตอนเกมรัน
-- นับ = ขโมยสำเร็จตลอดกาล (OrchardData stats.stole) โดนตบไม่นับ · รวมทุกเซิร์ฟผ่าน OrderedDataStore OrchardWanted_v1 (key UserId)
--   ดูค่าคนในเซิร์ฟทุก POLL วิ เพิ่มขึ้น = รอเขียน · เขียนทุก FLUSH วิ + ตอนออกเกม + ปิดเซิร์ฟ (UpdateAsync ไม่ลดค่า) · ป้ายรีเฟรชทุก REFRESH วิ
--   ป้ายรู้จักเฉพาะคนที่เข้าเกมหลังป้ายเปิด · บัญชีทดสอบ (EXCLUDE) ไม่นับ
-- Studio (รวม Team Test) เขียนลง store แยก OrchardWanted_v1_studio (สวนใน Studio ใช้คีย์ปลอม + ขโมยต้นตัวเองตอนทดสอบได้ ไม่ให้ปนป้ายจริง)
-- สวนปิด (DEV_ONLY) = workspace.Orchard ถูกย้ายออก ป้ายหายไปด้วย สคริปต์ไม่อ่าน store จนกว่าจะเจอป้าย (เปิดทีหลังได้ใน Team Test)
-- เฟส 2 (ยังไม่ทำ): ค่าหัว ตบอันดับ 1 ได้ = ได้เหรียญ

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local OrchardData = require(script.Parent:WaitForChild("OrchardData"))

-- 2026-11-06 แก้ป้ายไม่ขึ้นตอนทดสอบเป็นทีม: เซิร์ฟ Team Test อาจไม่นับเป็น Studio (ดู OrchardConfig TESTERS) จึงถือ DEV_ONLY เป็นเซิร์ฟทดสอบด้วย (เซิร์ฟจริงตอน DEV_ONLY สวนปิดอยู่ ไม่มีใครขโมย)
--   เซิร์ฟทดสอบ: ใช้ store แยก · นับบัญชีทดสอบด้วย (คนขโมยในการทดสอบคือบัญชีเหล่านี้) · อัปเดตเร็วขึ้น
local TEST_SERVER = RunService:IsStudio() or require(game:GetService("ReplicatedStorage"):WaitForChild("OrchardConfig")).DEV_ONLY == true
local STORE_NAME = TEST_SERVER and "OrchardWanted_v1_studio" or "OrchardWanted_v1"
local store = DataStoreService:GetOrderedDataStore(STORE_NAME)
local POLL, FLUSH, REFRESH = 20, 120, 60
if TEST_SERVER then POLL, FLUSH, REFRESH = 5, 10, 20 end
local TOP = 5
local EXCLUDE = TEST_SERVER and {} or {
	[11611605711] = true, -- CtrlZ_2 บัญชีทดสอบ
	[9188779540] = true, -- valynlnwza บัญชีทดสอบ
}

local INK = Color3.fromRGB(70, 40, 20)
local INK_SOFT = Color3.fromRGB(120, 80, 45)
local RED = Color3.fromRGB(170, 35, 30)

-- ============ เก็บค่า ============
local written = {} -- [userId] = ค่าที่เขียนลง store แล้ว
local pending = {} -- [userId] = ค่าที่รอเขียน

local function readStole(player)
	local st = OrchardData.Get(player)
	if not (st and st.loaded and st.data and st.data.stats) then return nil end
	return tonumber(st.data.stats.stole) or 0
end

local function poll(player)
	if EXCLUDE[player.UserId] then return end
	local n = readStole(player)
	if n and n > 0 and n > (written[player.UserId] or 0) then pending[player.UserId] = n end
end

local function write(userId, n)
	local ok, err = pcall(function()
		store:UpdateAsync(tostring(userId), function(old)
			old = tonumber(old) or 0
			if n <= old then return nil end
			return n
		end)
	end)
	if ok then
		written[userId] = math.max(written[userId] or 0, n)
	else
		warn("WantedBoard: เขียนไม่สำเร็จ " .. tostring(userId) .. ": " .. tostring(err))
	end
	return ok
end

local function flush()
	for userId, n in pairs(pending) do
		pending[userId] = nil
		if not write(userId, n) then pending[userId] = math.max(pending[userId] or 0, n) end
	end
end

Players.PlayerRemoving:Connect(function(player)
	poll(player) -- สวนอาจปล่อยข้อมูลไปก่อน = ใช้ค่าที่ poll ไว้ล่าสุด
	local n = pending[player.UserId]
	if n then
		pending[player.UserId] = nil
		if not write(player.UserId, n) then pending[player.UserId] = n end
	end
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do poll(p) end
	flush()
end)

-- ============ ชื่อ / รูปหน้า ============
local infoCache = {} -- [userId] = { name, user }
local thumbCache = {} -- [userId] = url

local function fetchInfos(ids)
	local need = {}
	for _, id in ipairs(ids) do if not infoCache[id] then table.insert(need, id) end end
	if #need > 0 then
		local ok, list = pcall(function() return UserService:GetUserInfosByUserIdsAsync(need) end)
		if ok and type(list) == "table" then
			for _, info in ipairs(list) do infoCache[info.Id] = { name = info.DisplayName, user = info.Username } end
		end
	end
	for _, id in ipairs(ids) do
		if not thumbCache[id] then
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
			end)
			if ok and url then thumbCache[id] = url end
		end
	end
end

-- ============ หน้าตาป้าย ============
local function text(parent, name, str, pos, size, color, font)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = str
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamBold
	l.TextScaled = true
	l.Parent = parent
	return l
end

-- big = ใบอันดับ 1
local function buildPoster(part, big)
	local gui = part:FindFirstChild("WantedGui")
	if gui then return gui end
	gui = Instance.new("SurfaceGui")
	gui.Name = "WantedGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.6
	gui.MaxDistance = 120
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(236, 214, 162)
	frame.Parent = gui
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(150, 100, 55)
	border.Thickness = big and 10 or 7
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = frame
	local pad = Instance.new("UIPadding")
	local p = UDim.new(0.05, 0)
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = p, p, UDim.new(0.03, 0), UDim.new(0.03, 0)
	pad.Parent = frame
	text(frame, "Title", "WANTED", UDim2.fromScale(0, 0), UDim2.fromScale(1, big and 0.15 or 0.17), INK, Enum.Font.Bangers)
	text(frame, "Sub", big and "โจรประจำสวน · อันดับ 1" or "อันดับ ?", UDim2.fromScale(0, big and 0.15 or 0.17), UDim2.fromScale(1, big and 0.06 or 0.08), INK_SOFT)
	local photo = Instance.new("Frame")
	photo.Name = "Photo"
	photo.AnchorPoint = Vector2.new(0.5, 0)
	photo.Position = UDim2.fromScale(0.5, big and 0.23 or 0.27)
	photo.Size = UDim2.fromScale(big and 0.8 or 0.78, big and 0.47 or 0.42)
	photo.BackgroundColor3 = Color3.fromRGB(205, 175, 120)
	photo.Parent = frame
	local pstroke = Instance.new("UIStroke")
	pstroke.Color = INK
	pstroke.Thickness = big and 5 or 3
	pstroke.Parent = photo
	local img = Instance.new("ImageLabel")
	img.Name = "Face"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.ScaleType = Enum.ScaleType.Crop
	img.ImageColor3 = Color3.fromRGB(255, 240, 215) -- อมสีซีเปียเล็กน้อยให้เหมือนภาพพิมพ์เก่า
	img.Parent = photo
	local q = text(photo, "Unknown", "?", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), INK_SOFT, Enum.Font.Bangers)
	q.Visible = false
	text(frame, "PlayerName", "", UDim2.fromScale(0, big and 0.72 or 0.71), UDim2.fromScale(1, big and 0.1 or 0.12), INK)
	text(frame, "Count", "", UDim2.fromScale(0, big and 0.83 or 0.84), UDim2.fromScale(1, big and 0.09 or 0.12), RED)
	gui.Parent = part
	return gui
end

local function buildHeader(header)
	if header:FindFirstChild("HeaderGui") then return end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "HeaderGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0.6
	gui.MaxDistance = 150
	local l = text(gui, "Label", "🤠 ประกาศจับ! โจรขโมยผลไม้ · MOST WANTED", UDim2.fromScale(0.03, 0.1), UDim2.fromScale(0.94, 0.8), Color3.fromRGB(255, 225, 150))
	l.TextStrokeTransparency = 0.4
	gui.Parent = header
end

local function fill(gui, rank, entry, big)
	local frame = gui:FindFirstChildOfClass("Frame")
	local face = frame.Photo.Face
	local unknown = frame.Photo.Unknown
	if not big then frame.Sub.Text = "อันดับ " .. rank end
	if entry then
		local info = infoCache[entry.id]
		face.Image = thumbCache[entry.id] or ""
		face.Visible = true
		unknown.Visible = face.Image == ""
		frame.PlayerName.Text = info and info.name or ("#" .. entry.id)
		frame.Count.Text = big and string.format("ขโมยสำเร็จ %d ครั้ง · %d steals", entry.n, entry.n) or string.format("%d ครั้ง", entry.n)
	else
		face.Image = ""
		face.Visible = false
		unknown.Visible = true
		frame.PlayerName.Text = big and "ยังไม่มีใครกล้า…" or "ว่าง"
		frame.Count.Text = big and "No one dares… yet" or ""
	end
end

local function findBoard()
	local orchard = workspace:FindFirstChild("Orchard")
	local decor = orchard and orchard:FindFirstChild("Decor")
	return decor and decor:FindFirstChild("WantedBoard")
end

local function refresh()
	local board = findBoard()
	if not board then return end -- สวนปิดอยู่ ไม่ต้องอ่าน store
	local header = board:FindFirstChild("Header")
	if header then buildHeader(header) end
	-- อ่านเผื่อแถวที่ต้องข้าม (บัญชีทดสอบ)
	local ok, pages = pcall(function() return store:GetSortedAsync(false, TOP + 4) end)
	if not ok then
		warn("WantedBoard: อ่านอันดับไม่สำเร็จ: " .. tostring(pages))
		return
	end
	local list, ids = {}, {}
	for _, row in ipairs(pages:GetCurrentPage()) do
		local id = tonumber(row.key)
		if id and not EXCLUDE[id] and (tonumber(row.value) or 0) > 0 and #list < TOP then
			table.insert(list, { id = id, n = row.value })
			table.insert(ids, id)
		end
	end
	if #ids > 0 then fetchInfos(ids) end
	local posters = board:FindFirstChild("Posters")
	if not posters then return end
	for rank = 1, TOP do
		local part = posters:FindFirstChild("Poster" .. rank)
		if part then fill(buildPoster(part, rank == 1), rank, list[rank], rank == 1) end
	end
end

task.spawn(function()
	local sincePoll, sinceFlush, sinceRefresh = 0, 0, REFRESH - 5
	while true do
		local dt = task.wait(1)
		sincePoll += dt
		sinceFlush += dt
		sinceRefresh += dt
		if sincePoll >= POLL then
			sincePoll = 0
			for _, p in ipairs(Players:GetPlayers()) do poll(p) end
		end
		if sinceFlush >= FLUSH and next(pending) then
			sinceFlush = 0
			flush()
			sinceRefresh = REFRESH -- เขียนแล้วรีเฟรชป้ายเลย
		end
		if sinceRefresh >= REFRESH then
			sinceRefresh = 0
			local okR, err = pcall(refresh)
			if not okR then warn("WantedBoard: " .. tostring(err)) end
		end
	end
end)
