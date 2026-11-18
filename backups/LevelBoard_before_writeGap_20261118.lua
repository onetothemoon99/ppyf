-- Backup of ServerScriptService.LevelBoard (Script, Studio), 2026-11-18, before "writeGap" (DataStore queue warning on LevelLeaderboard_v1).
-- Restore: in Studio open ServerScriptService.LevelBoard, replace all of its Source with everything below the line "-- ===== SOURCE =====".
-- ===== SOURCE =====
-- LevelBoard: ป้ายอันดับ "เลเวลสูงสุด" ของทั้งเกม ทุกเซิร์ฟเวอร์ (workspace.LevelBoard.Screen) ธีมเขียวอ่อน (ผู้ใช้ขอ 2026-10-13)
-- อันดับเก็บใน OrderedDataStore "LevelLeaderboard_v1" (คีย์ = UserId, ค่า = เลเวล) สคริปต์นี้เขียนเอง:
--   ผู้เล่นในเซิร์ฟเวอร์ที่โหลดเลเวลสำเร็จแล้ว (Attribute LevelDataLoaded = true) เขียนเมื่อเลเวลเปลี่ยน (เช็กทุก WRITE_SECONDS) และตอนออกเกม
--   ยังโหลดเลเวลไม่สำเร็จ = ไม่เขียน (กันเลเวล 1 ชั่วคราวไปทับอันดับ) · ค่าในที่เก็บสูงกว่า = ไม่เขียนทับ
-- อันดับเริ่มนับจากคนที่เข้าเกมหลังสคริปต์นี้ออกจริง (ไม่ย้อนอ่านเลเวลของคนที่ไม่เคยเข้ามาอีก)
-- แสดง 10 อันดับ รูปหน้าอวาตาร์ + ชื่อ + เลเวล รีเฟรชทุก 1 นาที (หน้าตาเดียวกับ PlaytimeBoard)

local DataStoreService = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local Players = game:GetService("Players")

local rankStore = DataStoreService:GetOrderedDataStore("LevelLeaderboard_v1")
local board = workspace:WaitForChild("LevelBoard")
local screen = board:WaitForChild("Screen")

local TOP_N = 10
local REFRESH_SECONDS = 60
local WRITE_SECONDS = 120
local LEVEL_STAT = "เลเวล" -- ชื่อค่าใน leaderstats (LeaderstatsSetup / LevelSystem)

local GREEN = Color3.fromRGB(60, 160, 105)
local GREEN_SOFT = Color3.fromRGB(176, 236, 196)
local CREAM = Color3.fromRGB(246, 255, 249)
local BROWN = Color3.fromRGB(70, 90, 75)
local MEDALS = {
	{ emoji = "🥇", color = Color3.fromRGB(255, 205, 70) },
	{ emoji = "🥈", color = Color3.fromRGB(205, 212, 222) },
	{ emoji = "🥉", color = Color3.fromRGB(226, 160, 110) },
}

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0, 12); c.Parent = obj end
local function stroke(obj, color, thickness)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = obj
end
local function label(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamBold
	l.Parent = parent
	return l
end

-- ============ โครงป้าย ============
local old = screen:FindFirstChild("LevelSurface")
if old then old:Destroy() end
local surface = Instance.new("SurfaceGui")
surface.Name = "LevelSurface"
surface.Face = Enum.NormalId.Front
surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surface.PixelsPerStud = 50
surface.LightInfluence = 0.2
surface.MaxDistance = 120
surface.Parent = screen

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = CREAM
root.Parent = surface
local bg = Instance.new("UIGradient")
bg.Rotation = 90
bg.Color = ColorSequence.new(Color3.fromRGB(206, 246, 222), CREAM)
bg.Parent = root

for _, d in ipairs({ { "⭐", 0.04, 0.06, 26 }, { "🌟", 0.96, 0.06, 26 }, { "🍀", 0.04, 0.92, 22 }, { "✨", 0.96, 0.92, 24 } }) do
	local s = label(root, d[1], d[4], GREEN_SOFT)
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Position = UDim2.fromScale(d[2], d[3])
	s.Size = UDim2.fromOffset(40, 40)
end

local title = label(root, "🏆 เลเวลสูงสุด 🏆", 36, GREEN, Enum.Font.GothamBlack)
title.Size = UDim2.new(1, 0, 0, 46)
title.Position = UDim2.fromOffset(0, 10)
local titleStroke = Instance.new("UIStroke"); titleStroke.Color = Color3.new(1, 1, 1); titleStroke.Thickness = 3; titleStroke.Parent = title

local subtitle = label(root, "สุดยอดนักฟาร์มของทั้งเกม · Top levels", 16, Color3.fromRGB(90, 160, 120), Enum.Font.GothamMedium)
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.fromOffset(0, 56)

local list = Instance.new("Frame")
list.Name = "List"
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(18, 86)
list.Size = UDim2.new(1, -36, 1, -128)
list.Parent = root
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5, -6, 0.2, -6)
grid.CellPadding = UDim2.fromOffset(12, 6)
grid.FillDirection = Enum.FillDirection.Vertical
grid.FillDirectionMaxCells = 5
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list

local empty = label(root, "ยังไม่มีข้อมูล\nเก็บเลเวลไปเรื่อยๆ แล้วชื่อจะขึ้นที่นี่! 🌱", 28, Color3.fromRGB(100, 170, 130))
empty.Size = UDim2.new(1, 0, 0, 90)
empty.Position = UDim2.new(0, 0, 0.5, -30)
empty.Visible = false

local footer = label(root, "ปลูก เก็บ ตกปลา เพื่อไต่อันดับนะ! 🌟", 16, BROWN, Enum.Font.GothamMedium)
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.Position = UDim2.new(0.5, 0, 1, -10)
footer.Size = UDim2.new(0, 350, 0, 26)
footer.BackgroundColor3 = Color3.new(1, 1, 1)
footer.BackgroundTransparency = 0.2
corner(footer, UDim.new(1, 0))
stroke(footer, GREEN_SOFT, 2)

-- ============ แถวอันดับ ============
local function makeRow(rank, userId, name, level)
	local row = Instance.new("Frame")
	row.Name = "Rank" .. rank
	row.LayoutOrder = rank
	row.BackgroundColor3 = Color3.new(1, 1, 1)
	row.BackgroundTransparency = rank <= 3 and 0 or 0.25
	corner(row, UDim.new(1, 0))
	stroke(row, rank <= 3 and MEDALS[rank].color or GREEN_SOFT, rank <= 3 and 3 or 2)

	local badge
	if rank <= 3 then
		badge = label(row, MEDALS[rank].emoji, 26, BROWN)
	else
		badge = label(row, tostring(rank), 16, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
		badge.BackgroundColor3 = Color3.fromRGB(110, 206, 150)
		badge.BackgroundTransparency = 0
		corner(badge, UDim.new(1, 0))
	end
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 6, 0.5, 0)
	badge.Size = UDim2.fromOffset(28, 28)

	local avatar = Instance.new("ImageLabel")
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.Position = UDim2.new(0, 38, 0.5, 0)
	avatar.Size = UDim2.fromOffset(38, 38)
	avatar.BackgroundColor3 = GREEN_SOFT
	avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
	avatar.Parent = row
	corner(avatar, UDim.new(1, 0))
	stroke(avatar, Color3.new(1, 1, 1), 2)

	local nameLabel = label(row, name, 17, BROWN)
	nameLabel.Position = UDim2.fromOffset(84, 4)
	nameLabel.Size = UDim2.new(1, -94, 0.5, -2)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local levelLabel = label(row, "⭐ Lv. " .. level, 15, GREEN)
	levelLabel.Position = UDim2.new(0, 84, 0.5, 0)
	levelLabel.Size = UDim2.new(1, -94, 0.5, -4)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.TextYAlignment = Enum.TextYAlignment.Top

	row.Parent = list
end

local nameCache = {}
local function resolveNames(userIds)
	local missing = {}
	for _, id in ipairs(userIds) do
		if not nameCache[id] then
			local p = Players:GetPlayerByUserId(id)
			if p then nameCache[id] = p.DisplayName else table.insert(missing, id) end
		end
	end
	if #missing > 0 then
		local ok, infos = pcall(function() return UserService:GetUserInfosByUserIdsAsync(missing) end)
		if ok then
			for _, info in ipairs(infos) do nameCache[info.Id] = info.DisplayName end
		end
		for _, id in ipairs(missing) do
			if not nameCache[id] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
				if ok2 then nameCache[id] = n end
			end
		end
	end
end

-- ============ เขียนเลเวลของผู้เล่นในเซิร์ฟเวอร์นี้ลงตารางอันดับ ============
local written = {} -- [userId] = เลเวลล่าสุดที่เขียนสำเร็จ
local function currentLevel(player)
	if player:GetAttribute("LevelDataLoaded") ~= true then return nil end -- ยังโหลดเลเวลจริงไม่สำเร็จ
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild(LEVEL_STAT)
	local level = value and tonumber(value.Value)
	if not level or level < 1 then return nil end
	return math.floor(level)
end
local WRITE_TRIES = 3 -- InternalServerError ของ Roblox มักหายเองในไม่กี่วินาที → ลองใหม่ 2 รอบ (2 s, 4 s)
local function writeLevel(player)
	local level = currentLevel(player)
	local userId = player.UserId
	if not level or userId <= 0 or written[userId] == level then return end
	local ok, err
	for attempt = 1, WRITE_TRIES do
		ok, err = pcall(function()
			rankStore:UpdateAsync(tostring(userId), function(old)
				if type(old) == "number" and old >= level then return nil end -- ในที่เก็บสูงกว่า/เท่ากัน = ไม่เขียน
				return level
			end)
		end)
		if ok then break end
		if attempt < WRITE_TRIES then task.wait(2 * attempt) end
	end
	if ok then written[userId] = level else warn("LevelBoard: เขียนอันดับของ " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err)) end
end

local function getTop()
	local ok, pages = pcall(function() return rankStore:GetSortedAsync(false, TOP_N, 1) end)
	if not ok then
		warn("LevelBoard: ดึงอันดับไม่ได้: " .. tostring(pages))
		return nil
	end
	local top = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key)
		if userId and entry.value > 0 then table.insert(top, { userId = userId, level = entry.value }) end
	end
	return top
end

local function refresh()
	local top = getTop()
	if not top then return end
	local ids = {}
	for _, e in ipairs(top) do table.insert(ids, e.userId) end
	resolveNames(ids)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for rank, e in ipairs(top) do
		makeRow(rank, e.userId, nameCache[e.userId] or ("ผู้เล่น " .. e.userId), e.level)
	end
	empty.Visible = #top == 0
end

Players.PlayerRemoving:Connect(function(player)
	writeLevel(player)
	written[player.UserId] = nil
end)
-- เซิร์ฟเวอร์ปิด: รอให้การเขียนตอนออกเกมของทุกคนเสร็จก่อน (รวมรอบลองใหม่)
game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function() writeLevel(player); pending -= 1 end)
	end
	local t = os.clock()
	while pending > 0 and os.clock() - t < 20 do task.wait(0.2) end
end)
task.spawn(function()
	while true do
		task.wait(WRITE_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(writeLevel, player)
		end
	end
end)
-- รอบแรก: รอให้คนที่อยู่ในเซิร์ฟเวอร์โหลดเลเวลเสร็จสักครู่ แล้วเขียน + แสดง
task.delay(20, function()
	for _, player in ipairs(Players:GetPlayers()) do writeLevel(player) end
	refresh()
end)

refresh()
while true do
	task.wait(REFRESH_SECONDS)
	refresh()
end
