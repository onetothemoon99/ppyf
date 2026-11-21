-- BACKUP of ServerScriptService.CropContest taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ServerScriptService.CropContest, select all, paste everything BELOW the next line.
-- ===== original Source (25863 bytes, hash 1402163930) =====
-- CropContest: ประกวดผักยักษ์ประจำสัปดาห์ (2026-10-31) ค่าตัวเลขดู ReplicatedStorage.CropContestConfig · หน้าจอ = StarterPlayerScripts.CropContestGui
-- PlantingSystem.doHarvest เรียก CropContest.OnGiant ตอนได้ผักยักษ์ → พืชตรงหัวข้อสัปดาห์นี้ = ชั่ง หนักกว่าสถิติ = ส่งเข้าประกวดเอง
-- อันดับ: OrderedDataStore "CropContest_v1_w<สัปดาห์>" (คีย์ UserId, ค่า = กรัม) เขียนทุก 15 วิถ้ามีสถิติใหม่
-- ข้อมูลผู้เล่น: DataStore "CropContestPlayers_v1" { entered = { [สัปดาห์] = กรัม }, claimed = { [สัปดาห์] = true } } (เก็บ 6 สัปดาห์ล่าสุด)
-- Studio ใช้คลังแยก (ชื่อมี Dev) ไม่ปนกับอันดับจริง · เลื่อนสัปดาห์ทดสอบ: workspace DevCropContestWeekOffset
-- ในแมพ: ServerStorage.CropContestBoard (ป้าย + แท่นโชว์) ยกไป workspace เมื่อระบบเปิด อัปเดตตัวหนังสือบนป้ายทุก 60 วิ

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("CropContestConfig"))
local CropBookConfig = require(ReplicatedStorage:WaitForChild("CropBookConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local CropContest = {}
function CropContest.OnGiant() end -- ระบบปิด = ไม่ทำอะไร
if not Config.IsEnabled() then return CropContest end

local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))

-- PlantingSystem require โมดูลนี้ตอนเริ่ม: ห้ามรอของที่สคริปต์อื่นสร้าง ไม่มีก็สร้างเอง
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end
local function remote(className, name)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local request = remote("RemoteFunction", "CropContestRequest")
local openRemote = remote("RemoteEvent", "CropContestOpen")
local harvestNotify = remote("RemoteEvent", "HarvestNotify")

local IS_STUDIO = RunService:IsStudio()
local RANK_PREFIX = IS_STUDIO and "CropContestDev_v1_w" or "CropContest_v1_w"
local playerStore = DataStoreService:GetDataStore(IS_STUDIO and "CropContestPlayersDev_v1" or "CropContestPlayers_v1")
local KEEP_WEEKS = 6

local function now()
	local offset = IS_STUDIO and tonumber(workspace:GetAttribute("DevCropContestWeekOffset")) or 0
	return os.time() + offset * 7 * 86400
end
local function currentWeek() return Config.WeekIndex(now()) end
local function rankStore(w) return DataStoreService:GetOrderedDataStore(RANK_PREFIX .. w) end
local function say(player, th, en) return Localization.Pick(Localization.GetLanguage(player), th, en) end
local function cropName(crop, lang)
	local c = CropBookConfig.ById[crop]
	return c and (c.icon .. Localization.Pick(lang, c.th, c.en)) or crop
end

local states = {} -- [player] = { data, loaded, dirty, pendingRank, busy }

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.entered = type(d.entered) == "table" and d.entered or {}
	d.claimed = type(d.claimed) == "table" and d.claimed or {}
	return d
end

-- DataStore เก็บคีย์ตารางเป็นสตริงเสมอ (ตารางเลขเว้นช่วงเป็น dictionary) อ่าน/เขียนผ่าน tostring(สัปดาห์)
local function wk(w) return tostring(w) end

local function save(player, st)
	local snapshot = st.data
	local ok, err = pcall(function()
		playerStore:UpdateAsync(tostring(player.UserId), function(old)
			old = normalize(old)
			for w, g in pairs(snapshot.entered) do old.entered[w] = math.max(old.entered[w] or 0, g) end
			for w in pairs(snapshot.claimed) do old.claimed[w] = true end
			-- ตัดสัปดาห์เก่าเกิน KEEP_WEEKS
			local cut = currentWeek() - KEEP_WEEKS
			for w in pairs(old.entered) do if tonumber(w) and tonumber(w) < cut then old.entered[w] = nil end end
			for w in pairs(old.claimed) do if tonumber(w) and tonumber(w) < cut then old.claimed[w] = nil end end
			return old
		end)
	end)
	if ok then st.dirty = false else warn("CropContest: เซฟไม่สำเร็จ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

-- ============ อันดับ (แคช 60 วิ) ============
local topCache = {} -- [week] = { at, list = { { userId, grams, name } } }
local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] then return nameCache[userId] end
	local p = Players:GetPlayerByUserId(userId)
	local name = p and p.DisplayName
	if not name then
		local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		name = ok and n or ("#" .. userId)
	end
	nameCache[userId] = name
	return name
end

local function getTop(w, force)
	local c = topCache[w]
	if c and not force and os.clock() - c.at < 60 then return c.list end
	local list = c and c.list or {}
	local ok, pages = pcall(function() return rankStore(w):GetSortedAsync(false, Config.TOP_N) end)
	if ok and pages then
		list = {}
		for _, e in ipairs(pages:GetCurrentPage()) do
			local uid = tonumber(e.key)
			if uid then table.insert(list, { userId = uid, grams = e.value, name = nameOf(uid) }) end
		end
	end
	topCache[w] = { at = os.clock(), list = list }
	return list
end

local function rankIn(list, userId)
	for i, e in ipairs(list) do if e.userId == userId then return i end end
	return nil
end

-- ============ ชั่งผักยักษ์ ============
local lastAnnounce = {}

-- เก็บได้ผักยักษ์ (เรียกจาก PlantingSystem) คืนน้ำหนัก (กรัม) ถ้าเป็นพืชหัวข้อ
function CropContest.OnGiant(player, cropType, star)
	local st = states[player]
	if not (st and st.loaded) then return nil end
	local w = currentWeek()
	local theme = Config.Theme(w)
	if cropType ~= theme.crop then return nil end
	local grams = Config.RollGrams(theme, star)
	local prev = st.data.entered[wk(w)] or 0
	if grams <= prev then return grams end
	st.data.entered[wk(w)] = grams
	st.dirty = true
	st.pendingRank = true
	local lang = Localization.GetLanguage(player)
	harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(lang,
		string.format("🏆 %sยักษ์ %s กก. — สถิติใหม่ของคุณ! (ส่งเข้าประกวดแล้ว)", cropName(cropType, lang), Config.FormatKg(grams)),
		string.format("🏆 Giant %s %s kg — your new record! (entered in the contest)", cropName(cropType, lang), Config.FormatKg(grams))))
	-- หนักกว่าอันดับ 1 ที่รู้ = ประกาศทั้งเซิร์ฟ (คนละไม่เกิน 1 ครั้ง/10 นาที)
	local top = getTop(w)
	local leader = top[1]
	if (not leader or grams > leader.grams) and os.clock() - (lastAnnounce[player] or -math.huge) >= Config.ANNOUNCE_COOLDOWN then
		lastAnnounce[player] = os.clock()
		local announce = remoteEvents:FindFirstChild("GachaAnnounce")
		if announce then
			announce:FireAllClients({ UserId = player.UserId, Name = player.DisplayName, Rarity = "Legendary", Kind = "Crop",
				PetName = cropName(cropType, "th") .. "ยักษ์ " .. Config.FormatKg(grams) .. " กก.", Detail = "🏆 อันดับ 1 ประกวดผักยักษ์" })
		end
	end
	-- ใส่ตัวเองในแคชทันที (ป้ายเห็นก่อน DataStore รอบถัดไป)
	local i = rankIn(top, player.UserId)
	if i then table.remove(top, i) end
	table.insert(top, { userId = player.UserId, grams = grams, name = player.DisplayName })
	table.sort(top, function(a, b) return a.grams > b.grams end)
	while #top > Config.TOP_N do table.remove(top) end
	print(string.format("🏆 CropContest: %s %s %s กก. (w%d)", player.Name, cropType, Config.FormatKg(grams), w))
	return grams
end

local function flushRank(player, st)
	if not st.pendingRank then return end
	st.pendingRank = false
	local w = currentWeek()
	local grams = st.data.entered[wk(w)]
	if not grams then return end
	local ok, err = pcall(function()
		rankStore(w):UpdateAsync(tostring(player.UserId), function(old)
			if type(old) == "number" and old >= grams then return nil end
			return grams
		end)
	end)
	if not ok then
		st.pendingRank = true
		warn("CropContest: ส่งอันดับไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
	end
end

-- ============ รางวัลสัปดาห์ก่อนๆ ============
-- สัปดาห์ที่ส่งแล้วจบไปแล้ว ยังไม่รับ = { week, grams, rank (nil = ไม่ติด 10), reward }
local function claimable(player, st)
	local w = currentWeek()
	local out = {}
	for key, grams in pairs(st.data.entered) do
		local pw = tonumber(key)
		if pw and pw < w and not st.data.claimed[key] then
			local rank = rankIn(getTop(pw), player.UserId)
			table.insert(out, { week = pw, grams = grams, rank = rank, crop = Config.Theme(pw).crop, reward = Config.Reward(rank) or Config.PARTICIPATION })
		end
	end
	table.sort(out, function(a, b) return a.week < b.week end)
	return out
end

local function grant(player, reward)
	if (reward.premium or 0) > 0 and not GachaTickets.Add(player, "Premium", reward.premium) then return false end
	if (reward.coins or 0) > 0 then
		local ls = player:FindFirstChild("leaderstats")
		local coins = ls and ls:FindFirstChild("เหรียญ")
		if not (coins and player:GetAttribute("CoinsLoaded")) then return false end
		CheatWatch.AllowCoinGain(player, reward.coins)
		coins.Value += reward.coins
		local saveCoins = ServerScriptService:FindFirstChild("LeaderstatsSetup") and ServerScriptService.LeaderstatsSetup:FindFirstChild("SaveCoinsNow")
		if saveCoins then saveCoins:Fire(player) end
	end
	if reward.title then
		local t = Config.TITLE
		local CropBook = require(ServerScriptService:WaitForChild("CropBook"))
		pcall(CropBook.GrantTitle, player, t.key, t.th, t.en)
	end
	return true
end

local function rewardText(player, reward)
	local parts = {}
	if (reward.premium or 0) > 0 then table.insert(parts, say(player, "💎 ตั๋ว Premium x", "💎 Premium ticket x") .. reward.premium) end
	if (reward.coins or 0) > 0 then table.insert(parts, "💰 " .. reward.coins) end
	if reward.title then table.insert(parts, say(player, "ฉายา ", "Title ") .. Localization.Pick(Localization.GetLanguage(player), Config.TITLE.th, Config.TITLE.en)) end
	return table.concat(parts, " + ")
end

-- ============ ข้อมูลให้หน้าจอ ============
local function info(player, st)
	local w = currentWeek()
	local top = {}
	for i, e in ipairs(getTop(w)) do top[i] = { name = e.name, grams = e.grams, me = e.userId == player.UserId } end
	local prevTop = getTop(w - 1)
	local winner = prevTop[1] and { name = prevTop[1].name, grams = prevTop[1].grams, crop = Config.Theme(w - 1).crop } or nil
	return {
		ok = true, week = w, crop = Config.Theme(w).crop, endsIn = Config.WeekEnds(w) - now(),
		top = top, myBest = st.data.entered[wk(w)], myRank = rankIn(getTop(w), player.UserId),
		claimable = claimable(player, st), winner = winner,
		rewards = Config.REWARDS, participation = Config.PARTICIPATION, nextCrop = Config.Theme(w + 1).crop,
	}
end

request.OnServerInvoke = function(player, action)
	local st = states[player]
	if not (st and st.loaded) then return { ok = false, message = say(player, "ยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง", "Not loaded yet, try again") } end
	if action == "info" then return info(player, st) end
	if action ~= "claim" or st.busy then return { ok = false } end
	st.busy = true
	local ok, result = pcall(function()
		local got = {}
		for _, c in ipairs(claimable(player, st)) do
			if grant(player, c.reward) then
				st.data.claimed[wk(c.week)] = true
				st.dirty = true
				table.insert(got, (c.rank and ("#" .. c.rank .. " ") or "") .. rewardText(player, c.reward))
				print(string.format("🏆 CropContest: %s รับรางวัล w%d อันดับ %s", player.Name, c.week, tostring(c.rank)))
			end
		end
		if st.dirty then save(player, st) end
		local r = info(player, st)
		r.message = #got > 0 and ("🎁 " .. table.concat(got, " · ")) or say(player, "ยังไม่มีรางวัลให้รับ", "No rewards to claim")
		r.claimedOk = #got > 0
		return r
	end)
	st.busy = nil
	if not ok then warn("CropContest: " .. tostring(result)) return { ok = false } end
	return result
end

-- ============ โหลด / ออก ============
local function onPlayerAdded(player)
	local st = { data = normalize(nil), loaded = false, dirty = false }
	states[player] = st
	local ok, data = DataLoadRetry.Load(player, "CropContest", DataLoadRetry.Get(playerStore, tostring(player.UserId)), function() return states[player] == st end)
	if not ok then return end
	st.data = normalize(data)
	st.loaded = true
	-- มีรางวัลค้าง = บอกผู้เล่น (ไปรับที่ป้าย)
	task.delay(20, function()
		if player.Parent and states[player] == st and #claimable(player, st) > 0 then
			player:SetAttribute("CropContestClaimable", true)
			harvestNotify:FireClient(player, nil, nil, nil, say(player, "🏆 มีรางวัลประกวดผักยักษ์รอรับ! ไปที่ป้ายประกวด หรือเมนู ☰", "🏆 Giant crop contest reward waiting! Visit the contest board or the ☰ menu"))
		end
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end

local pendingSaves = 0
Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	lastAnnounce[player] = nil
	if st and st.loaded then
		pendingSaves += 1
		flushRank(player, st)
		if st.dirty then save(player, st) end
		pendingSaves -= 1
	end
end)
game:BindToClose(function()
	for player, st in pairs(states) do
		if st.loaded then
			pendingSaves += 1
			task.spawn(function()
				flushRank(player, st)
				if st.dirty then save(player, st) end
				pendingSaves -= 1
			end)
		end
	end
	local deadline = os.clock() + 20
	while pendingSaves > 0 and os.clock() < deadline do task.wait(0.2) end
end)

-- ส่งสถิติเข้าอันดับ + เซฟทุก 15 วิ (กันเขียน DataStore ทุกครั้งที่เก็บได้ผักยักษ์)
task.spawn(function()
	while true do
		task.wait(15)
		for player, st in pairs(states) do
			if st.loaded and (st.pendingRank or st.dirty) then
				task.spawn(function()
					flushRank(player, st)
					if st.dirty then save(player, st) end
				end)
			end
		end
	end
end)

-- ============ ป้าย + แท่นโชว์ในแมพ ============
local function fmtLeft(s)
	s = math.max(0, math.floor(s))
	local d = s // 86400
	local h = (s % 86400) // 3600
	return d > 0 and string.format("%d วัน %d ชม.", d, h) or string.format("%d ชม. %d นาที", h, (s % 3600) // 60)
end

local shownWinnerWeek = nil
local function updateWinner(board, w)
	local stand = board:FindFirstChild("WinnerStand")
	if not stand then return end
	local prevTop = getTop(w - 1)
	local winner = prevTop[1]
	local key = (w - 1) .. ":" .. tostring(winner and winner.userId)
	if shownWinnerWeek == key then return end
	shownWinnerWeek = key
	local old = stand:FindFirstChild("WinnerCrop")
	if old then old:Destroy() end
	local label = stand:FindFirstChild("WinnerLabel", true)
	local crop = Config.Theme(w - 1).crop
	if label then
		label.Text = winner and string.format("🏆 แชมป์สัปดาห์ที่แล้ว\n%s\n%sยักษ์ %s กก.", winner.name, cropName(crop, "th"), Config.FormatKg(winner.grams))
			or "🏆 แชมป์สัปดาห์ที่แล้ว\nยังไม่มี"
	end
	if not winner then return end
	local template = ServerStorage:FindFirstChild("CropTemplates") and ServerStorage.CropTemplates:FindFirstChild(crop)
	local held = template and template:FindFirstChild("HeldFruit")
	local top = stand:FindFirstChild("Top")
	if not (held and top) then return end
	local model = Instance.new("Model")
	model.Name = "WinnerCrop"
	local copy = held:Clone()
	copy.Parent = model
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end
	end
	local size = model:GetExtentsSize()
	local scale = 3 / math.max(size.X, size.Y, size.Z, 0.01) -- ใหญ่ราว 3 สตัด
	model:ScaleTo(scale)
	local h = model:GetExtentsSize().Y
	model:PivotTo(CFrame.new(top.Position + Vector3.new(0, top.Size.Y / 2 + h / 2 + 0.1, 0)) * CFrame.Angles(0, os.clock() % 6, 0))
	model.Parent = stand
end

-- หน้าป้ายแบบเดียวกับป้าย "เลเวลสูงสุด" (ServerScriptService.LevelBoard ธีมเขียวอ่อน) ผู้ใช้ขอ 2026-10-31: ขนาดเท่ากัน ธีมเดียวกัน
-- ป้ายคือโมเดลที่ก๊อปจาก workspace.LevelBoard (CropContestBoard.Board) วาด SurfaceGui บนชิ้น Screen
local GREEN = Color3.fromRGB(60, 160, 105)
local GREEN_SOFT = Color3.fromRGB(176, 236, 196)
local CREAM = Color3.fromRGB(246, 255, 249)
local BROWN = Color3.fromRGB(70, 90, 75)
local MEDALS = {
	{ emoji = "🥇", color = Color3.fromRGB(255, 205, 70) },
	{ emoji = "🥈", color = Color3.fromRGB(205, 212, 222) },
	{ emoji = "🥉", color = Color3.fromRGB(226, 160, 110) },
}
local function uiCorner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0, 12); c.Parent = obj end
local function uiStroke(obj, color, thickness)
	local st = Instance.new("UIStroke"); st.Color = color; st.Thickness = thickness or 2
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = obj
end
local function uiLabel(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamBold
	l.Parent = parent
	return l
end

local boardUi = nil -- { subtitle, list, empty }
local function buildSurface(screen)
	local old = screen:FindFirstChild("ContestSurface")
	if old then old:Destroy() end
	local surface = Instance.new("SurfaceGui")
	surface.Name = "ContestSurface"
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
	for _, d in ipairs({ { "🍉", 0.04, 0.06, 26 }, { "🎃", 0.96, 0.06, 26 }, { "🌽", 0.04, 0.92, 22 }, { "✨", 0.96, 0.92, 24 } }) do
		local st = uiLabel(root, d[1], d[4], GREEN_SOFT)
		st.AnchorPoint = Vector2.new(0.5, 0.5)
		st.Position = UDim2.fromScale(d[2], d[3])
		st.Size = UDim2.fromOffset(40, 40)
	end
	local title = uiLabel(root, "🏆 ประกวดผักยักษ์ 🏆", 36, GREEN, Enum.Font.GothamBlack)
	title.Size = UDim2.new(1, 0, 0, 46)
	title.Position = UDim2.fromOffset(0, 10)
	local titleStroke = Instance.new("UIStroke"); titleStroke.Color = Color3.new(1, 1, 1); titleStroke.Thickness = 3; titleStroke.Parent = title
	local subtitle = uiLabel(root, "", 16, Color3.fromRGB(90, 160, 120), Enum.Font.GothamMedium)
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
	local empty = uiLabel(root, "ยังไม่มีใครส่งเข้าประกวดสัปดาห์นี้\nเก็บผักยักษ์ของพืชหัวข้อ แล้วชื่อจะขึ้นที่นี่! 🌱", 26, Color3.fromRGB(100, 170, 130))
	empty.Size = UDim2.new(1, 0, 0, 90)
	empty.Position = UDim2.new(0, 0, 0.5, -30)
	empty.Visible = false
	local footer = uiLabel(root, "เก็บ 🍉 ผักยักษ์ของพืชหัวข้อ = ส่งเข้าประกวดเอง · กด E ดูรางวัล 🌟", 16, BROWN, Enum.Font.GothamMedium)
	footer.AnchorPoint = Vector2.new(0.5, 1)
	footer.Position = UDim2.new(0.5, 0, 1, -10)
	footer.Size = UDim2.new(0, 520, 0, 26)
	footer.BackgroundColor3 = Color3.new(1, 1, 1)
	footer.BackgroundTransparency = 0.2
	uiCorner(footer, UDim.new(1, 0))
	uiStroke(footer, GREEN_SOFT, 2)
	boardUi = { subtitle = subtitle, list = list, empty = empty }
end

local function makeRow(list, rank, userId, name, grams)
	local row = Instance.new("Frame")
	row.Name = "Rank" .. rank
	row.LayoutOrder = rank
	row.BackgroundColor3 = Color3.new(1, 1, 1)
	row.BackgroundTransparency = rank <= 3 and 0 or 0.25
	uiCorner(row, UDim.new(1, 0))
	uiStroke(row, rank <= 3 and MEDALS[rank].color or GREEN_SOFT, rank <= 3 and 3 or 2)
	local badge
	if rank <= 3 then
		badge = uiLabel(row, MEDALS[rank].emoji, 26, BROWN)
	else
		badge = uiLabel(row, tostring(rank), 16, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
		badge.BackgroundColor3 = Color3.fromRGB(110, 206, 150)
		badge.BackgroundTransparency = 0
		uiCorner(badge, UDim.new(1, 0))
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
	uiCorner(avatar, UDim.new(1, 0))
	uiStroke(avatar, Color3.new(1, 1, 1), 2)
	local nameLabel = uiLabel(row, name, 17, BROWN)
	nameLabel.Position = UDim2.fromOffset(84, 4)
	nameLabel.Size = UDim2.new(1, -94, 0.5, -2)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	local weightLabel = uiLabel(row, "⚖️ " .. Config.FormatKg(grams) .. " กก.", 15, GREEN)
	weightLabel.Position = UDim2.new(0, 84, 0.5, 0)
	weightLabel.Size = UDim2.new(1, -94, 0.5, -4)
	weightLabel.TextXAlignment = Enum.TextXAlignment.Left
	weightLabel.TextYAlignment = Enum.TextYAlignment.Top
	row.Parent = list
end

local shownTopKey = nil
local function updateBoard(board)
	local w = currentWeek()
	local theme = Config.Theme(w)
	local screen = board:FindFirstChild("Screen", true)
	if screen and not boardUi then buildSurface(screen) end
	if boardUi then
		boardUi.subtitle.Text = string.format("สัปดาห์นี้: %sยักษ์หนักที่สุด · เหลือ %s", cropName(theme.crop, "th"), fmtLeft(Config.WeekEnds(w) - now()))
		local top = getTop(w)
		local parts = {}
		for _, e in ipairs(top) do table.insert(parts, e.userId .. ":" .. e.grams) end
		local key = w .. "|" .. table.concat(parts, ",")
		if key ~= shownTopKey then
			shownTopKey = key
			for _, child in ipairs(boardUi.list:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			for rank, e in ipairs(top) do makeRow(boardUi.list, rank, e.userId, e.name, e.grams) end
			boardUi.empty.Visible = #top == 0
		end
	end
	updateWinner(board, w)
end

task.spawn(function()
	local board = workspace:FindFirstChild("CropContestBoard") or ServerStorage:FindFirstChild("CropContestBoard")
	if not board then warn("CropContest: ไม่เจอ ServerStorage.CropContestBoard") return end
	board.Parent = workspace
	local prompt = board:FindFirstChild("CropContestPrompt", true)
	if prompt then prompt.Triggered:Connect(function(player) openRemote:FireClient(player) end) end
	while true do
		pcall(updateBoard, board)
		task.wait(60)
	end
end)

return CropContest
