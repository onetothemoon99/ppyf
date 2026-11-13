-- BACKUP 2026-11-13 — StarterPlayer.StarterPlayerScripts.NewPlayerGuide (LocalScript) ก่อนเพิ่มขั้น 4 "ไปหาครูฟาร์ม" + นำทางไปจุดบทเรียน (LessonNpcGui)
-- วิธีคืน: ใน Studio เปิด StarterPlayer.StarterPlayerScripts.NewPlayerGuide แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 3 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- และลบ StarterPlayer.StarterPlayerScripts.LessonNpcGui + Workspace.GuideNPC ถ้าต้องการเอา NPC ครูฟาร์มออกด้วย
-- NewPlayerGuide (2026-11-13 ผู้ใช้ขอ "ทำลูกศร 3 ขั้น"): นำทางผู้เล่นใหม่ 3 ขั้น ปลูก → เก็บ → ขาย
-- ทำงานฝั่งเครื่องผู้เล่นอย่างเดียว: ไม่มีเซิร์ฟเวอร์ / DataStore / รางวัล · ไม่เกี่ยวกับ TutorialService / TutorialGui เดิม (ปิดถาวร 2026-11-01)
-- เริ่มเอง: ผู้เล่นใหม่ (Attribute IsNewPlayer จาก LeaderstatsSetup = บัญชีที่ยังไม่มีข้อมูลเหรียญ มีแค่รอบแรกที่เข้าเกม) หลังเข้า AUTO_START_DELAY วิ
-- เริ่มเองได้ทุกคน: ปุ่ม "เริ่มนำทาง" ในแผงวิธีเล่น (HowToPlayGui) ยิง BindableEvent NewPlayerGuideGui.StartGuide · กด X บนการ์ด = หยุด
-- สิ่งที่แสดง: การ์ดมุมขวาบน (ขั้น n/3 + สิ่งที่ต้องทำ + ระยะ) · เส้นทองจากตัวผู้เล่นไปเป้าหมาย (Beam) · ลูกศร ▼ เด้งเหนือเป้าหมายพร้อมป้ายชื่อ
-- ตรวจว่าผ่านขั้น (ทุก 0.3 วิ):
--   1 ปลูก  = Attribute PlantCount เพิ่มจากตอนเริ่มขั้น · เป้า = จุดบนแปลงดิน (FarmPlots ... Soil) ที่ใกล้ผู้เล่นที่สุด
--   2 เก็บ  = PlantCount ลดลงจากค่าสูงสุดที่เห็นในขั้นนี้ · เป้า = ต้นของเรา (Soil.PlantSlot<n> ที่ OwnerUserId = เรา ต้นที่โตแล้วมาก่อน)
--   3 ขาย  = เหรียญ (leaderstats "เหรียญ") เพิ่มจากตอนเริ่มขั้น · เป้า = พื้นหน้าร้านเมล็ด (workspace.Shops.Shop)
-- ข้อควรรู้: บัญชีที่มีสัตว์เลี้ยงช่วยปลูก/เก็บ ขั้น 1-2 อาจผ่านเอง (PlantCount นับของสัตว์ด้วย) · เหรียญที่เพิ่มจากทางอื่นในขั้น 3 ก็นับผ่าน
-- เกร็ดจากบทเรียนเดิม: BillboardGui ที่สร้างฝั่งเครื่องต้องอยู่ใน PlayerGui + ตั้ง Adornee · AlwaysOnTop = true ทำให้ไม่แสดงในเกมนี้ · ใช้ตัวอักษร "▼" แทนอิโมจิ
-- ทดสอบใน Studio: ตอน Play ตั้ง Attribute IsNewPlayer = true บนผู้เล่นฝั่ง Client (เริ่มเอง) หรือกดปุ่ม "เริ่มนำทาง" ในแผง "?"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local function tr(th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end

local AUTO_START_DELAY = 4 -- วินาทีหลังรู้ว่าเป็นผู้เล่นใหม่ แล้วเริ่มนำทางเอง
local CHECK_INTERVAL = 0.3
local FINISH_SHOW_TIME = 7 -- วินาทีที่การ์ด "เก่งมาก" ค้างไว้หลังจบ

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_SUB = Color3.fromRGB(130, 100, 90)
local COLOR_BORDER = Color3.fromRGB(140, 100, 65)
local COLOR_GOLD = Color3.fromRGB(255, 205, 80)

-- ข้อความของแต่ละขั้น (แก้ได้ที่นี่ที่เดียว)
local STEPS = {
	{ id = "plant", th = "กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน", en = "Tap slot 1 (seeds), then tap the soil",
		markTh = "แปลงดิน", markEn = "Soil plot" },
	{ id = "harvest", th = "รอต้นโต แล้วกดปุ่มเก็บที่ต้น", en = "Wait for it to grow, then press harvest",
		markTh = "กำลังโต...", markEn = "Growing...", readyTh = "โตแล้ว! กดเก็บ", readyEn = "Ready! Harvest" },
	{ id = "sell", th = "ไปร้านเมล็ด แล้วขายผลผลิต", en = "Go to the seed shop and sell your crops",
		markTh = "ร้านเมล็ด", markEn = "Seed shop" },
}

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0); c.Parent = obj; return c end

-- ============ การ์ดมุมขวาบน (ใต้แถวปุ่มไอคอน) ============
local gui = Instance.new("ScreenGui")
gui.Name = "NewPlayerGuideGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3 -- ต่ำกว่าหน้าต่างร้าน/กระเป๋า หน้าต่างจะบังการ์ดได้
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -12, 0, 64)
card.Size = UDim2.fromOffset(264, 62)
card.BackgroundColor3 = COLOR_BG
card.Parent = gui
corner(card, 12)
do
	local st = Instance.new("UIStroke"); st.Color = COLOR_GOLD; st.Thickness = 3; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = card
end

local cardTitle = Instance.new("TextLabel")
cardTitle.Name = "Title"
cardTitle.BackgroundTransparency = 1
cardTitle.Position = UDim2.new(0, 10, 0, 5)
cardTitle.Size = UDim2.new(1, -52, 0, 18)
cardTitle.Font = Enum.Font.GothamBold
cardTitle.TextSize = 13
cardTitle.TextColor3 = COLOR_SUB
cardTitle.TextXAlignment = Enum.TextXAlignment.Left
cardTitle.Parent = card

local cardText = Instance.new("TextLabel")
cardText.Name = "Text"
cardText.BackgroundTransparency = 1
cardText.Position = UDim2.new(0, 10, 0, 23)
cardText.Size = UDim2.new(1, -20, 0, 34)
cardText.Font = Enum.Font.GothamBold
cardText.TextSize = 14
cardText.TextColor3 = COLOR_TEXT
cardText.TextXAlignment = Enum.TextXAlignment.Left
cardText.TextYAlignment = Enum.TextYAlignment.Top
cardText.TextWrapped = true
cardText.Parent = card

local stopButton = Instance.new("TextButton")
stopButton.Name = "Stop"
stopButton.AnchorPoint = Vector2.new(1, 0)
stopButton.Position = UDim2.new(1, -4, 0, 2) -- กรอบกด 36x26 (ตัว X เล็ก แต่พื้นที่กดกว้าง)
stopButton.Size = UDim2.fromOffset(36, 26)
stopButton.BackgroundTransparency = 1
stopButton.Text = "X"
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.TextColor3 = COLOR_SUB
stopButton.Parent = card

-- ============ เป้าหมายในโลก: ชิ้นส่วนล่องหน + เส้นทอง + ลูกศร ============
local targetPart = Instance.new("Part")
targetPart.Name = "NewPlayerGuideTarget"
targetPart.Anchored = true
targetPart.CanCollide = false
targetPart.CanQuery = false
targetPart.CanTouch = false
targetPart.Transparency = 1
targetPart.Size = Vector3.new(1, 1, 1)
local targetAttach = Instance.new("Attachment")
targetAttach.Position = Vector3.new(0, 3, 0) -- ปลายเส้นลอยเหนือเป้า 3 สตั๊ด (ระดับสายตา)
targetAttach.Parent = targetPart

local beam = Instance.new("Beam")
beam.Name = "GuideBeam"
beam.Color = ColorSequence.new(COLOR_GOLD)
beam.Transparency = NumberSequence.new(0.2)
beam.LightEmission = 0.7
beam.Width0 = 0.7
beam.Width1 = 0.7
beam.FaceCamera = true
beam.Segments = 1
beam.Attachment1 = targetAttach
beam.Parent = targetPart

local marker = Instance.new("BillboardGui")
marker.Name = "NewPlayerGuideMarker"
marker.Size = UDim2.fromOffset(220, 74)
marker.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
marker.AlwaysOnTop = false -- true = ไม่แสดงในเกมนี้ (บทเรียนเดิมเจอมาแล้ว)
marker.MaxDistance = 2000
marker.ResetOnSpawn = false
marker.Enabled = false
marker.Adornee = targetPart
marker.Parent = playerGui
local markerLabel = Instance.new("TextLabel")
markerLabel.BackgroundTransparency = 1
markerLabel.Size = UDim2.new(1, 0, 0, 30)
markerLabel.Font = Enum.Font.GothamBold
markerLabel.TextSize = 18
markerLabel.TextColor3 = Color3.new(1, 1, 1)
markerLabel.TextStrokeColor3 = COLOR_TEXT
markerLabel.TextStrokeTransparency = 0
markerLabel.Parent = marker
local markerArrow = Instance.new("TextLabel")
markerArrow.BackgroundTransparency = 1
markerArrow.Position = UDim2.new(0, 0, 0, 28)
markerArrow.Size = UDim2.new(1, 0, 0, 44)
markerArrow.Font = Enum.Font.GothamBlack
markerArrow.TextSize = 40
markerArrow.Text = "▼"
markerArrow.TextColor3 = COLOR_GOLD
markerArrow.TextStrokeColor3 = COLOR_TEXT
markerArrow.TextStrokeTransparency = 0
markerArrow.Parent = marker

-- ============ ค่าที่ใช้ตรวจ ============
local function rootPart()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function plantCount()
	return tonumber(player:GetAttribute("PlantCount")) or 0
end
local function coins()
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("เหรียญ")
	return c and c.Value or 0
end

-- จุดบนแผ่นดินที่ใกล้ผู้เล่นที่สุด (แปลงใหญ่ไม่ต้องเดินไปกลางแปลง)
local function nearestSoil()
	local root = rootPart()
	local plots = workspace:FindFirstChild("FarmPlots")
	if not (root and plots) then return nil end
	local best, bestD
	for _, d in ipairs(plots:GetDescendants()) do
		if d.Name == "Soil" and d:IsA("BasePart") then
			local lp = d.CFrame:PointToObjectSpace(root.Position)
			local hx, hz = math.max(d.Size.X / 2 - 2, 0), math.max(d.Size.Z / 2 - 2, 0)
			local p = d.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -hx, hx), d.Size.Y / 2, math.clamp(lp.Z, -hz, hz)))
			local dist = (p - root.Position).Magnitude
			if not bestD or dist < bestD then best, bestD = p, dist end
		end
	end
	return best
end

-- ต้นของเรา: Soil.PlantSlot<n> ที่ OwnerUserId = เรา (ช่องปลูก CanQuery = false จึงไล่ดูลูกของ Soil แทนการค้นรัศมี) ต้นที่โตแล้วมาก่อน แล้วค่อยดูต้นที่ใกล้สุด
-- คืน (ตำแหน่ง, โตแล้วหรือยัง)
local function findMyCrop()
	local root = rootPart()
	local plots = workspace:FindFirstChild("FarmPlots")
	if not (root and plots) then return nil, false end
	local best, bestScore, bestReady
	for _, soil in ipairs(plots:GetDescendants()) do
		if soil.Name == "Soil" and soil:IsA("BasePart") then
			for _, part in ipairs(soil:GetChildren()) do
				if part:IsA("BasePart") and part.Name:sub(1, 9) == "PlantSlot" and part:GetAttribute("OwnerUserId") == player.UserId then
					local prompt = part:FindFirstChildOfClass("ProximityPrompt")
					local ready = prompt ~= nil and prompt.Enabled
					local score = (part.Position - root.Position).Magnitude - (ready and 100000 or 0)
					if not bestScore or score < bestScore then best, bestScore, bestReady = part.Position, score, ready end
				end
			end
		end
	end
	return best, bestReady == true
end

-- พื้นใต้ป้ายร้านเมล็ด (ชิ้น Shop อยู่ระดับหลังคา)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function shopPos()
	local shops = workspace:FindFirstChild("Shops")
	local shop = shops and shops:FindFirstChild("Shop")
	if not (shop and shop:IsA("BasePart")) then return nil end
	groundParams.FilterDescendantsInstances = { player.Character, shop }
	local hit = workspace:Raycast(shop.Position + Vector3.new(0, 2, 0), Vector3.new(0, -40, 0), groundParams)
	return hit and hit.Position or (shop.Position - Vector3.new(0, 6, 0))
end

-- ============ สถานะ ============
local step = 0 -- 0 = ไม่ได้นำทาง, 1..#STEPS = กำลังทำขั้นนั้น
local runId = 0 -- เพิ่มทุกครั้งที่เริ่ม/หยุด ลูปเก่าเห็นค่าไม่ตรงแล้วเลิกเอง
local basePlant, maxPlant, baseCoins = 0, 0, 0
local targetPos -- Vector3 ของเป้าหมายปัจจุบัน (nil = ยังหาไม่เจอ ซ่อนเส้น/ลูกศร)
local markText = ""
local everStarted = false

local function ensureRootAttach()
	local root = rootPart()
	if not root then return nil end
	local a = root:FindFirstChild("NewPlayerGuideAttach")
	if not a then
		a = Instance.new("Attachment")
		a.Name = "NewPlayerGuideAttach"
		a.Position = Vector3.new(0, 1.2, 0) -- ระดับอก
		a.Parent = root
	end
	return a
end

local function hideWorld()
	targetPart.Parent = nil
	marker.Enabled = false
end
local function showWorld()
	if not targetPos then hideWorld() return end
	targetPart.Position = targetPos
	targetPart.Parent = workspace
	beam.Attachment0 = ensureRootAttach()
	marker.Enabled = true
end

local function enterStep(n)
	step = n
	basePlant = plantCount()
	maxPlant = basePlant
	baseCoins = coins()
	targetPos = nil
	local s = STEPS[n]
	cardTitle.Text = tr("สอนเล่น", "Guide") .. " " .. n .. "/" .. #STEPS
	cardText.Text = tr(s.th, s.en)
	markText = tr(s.markTh, s.markEn)
end

local function stop()
	runId += 1
	step = 0
	gui.Enabled = false
	hideWorld()
end

local function finish()
	runId += 1
	local myRun = runId
	step = 0
	hideWorld()
	cardTitle.Text = tr("สอนเล่น", "Guide") .. " " .. #STEPS .. "/" .. #STEPS
	cardText.Text = tr("เก่งมาก! ลองซื้อเมล็ดใหม่ หรือกด ? ดูอย่างอื่น", "Well done! Buy new seeds, or tap ? for more")
	task.delay(FINISH_SHOW_TIME, function()
		if runId == myRun then gui.Enabled = false end
	end)
end

-- ตรวจขั้นปัจจุบัน 1 ครั้ง: อัปเดตเป้าหมาย แล้วคืน true ถ้าผ่านขั้น
local function checkStep()
	local s = STEPS[step]
	if s.id == "plant" then
		targetPos = nearestSoil()
		return plantCount() > basePlant
	elseif s.id == "harvest" then
		local pos, ready = findMyCrop()
		targetPos = pos
		markText = ready and tr(s.readyTh, s.readyEn) or tr(s.markTh, s.markEn)
		local now = plantCount()
		if now > maxPlant then maxPlant = now end
		return now < maxPlant
	else -- sell
		if not targetPos then targetPos = shopPos() end
		return coins() > baseCoins
	end
end

local function start()
	runId += 1
	local myRun = runId
	everStarted = true
	enterStep(1)
	gui.Enabled = true
	task.spawn(function()
		while runId == myRun do
			if checkStep() then
				if step >= #STEPS then
					finish()
					return
				end
				enterStep(step + 1)
				checkStep() -- หาเป้าหมายของขั้นใหม่ทันที
			end
			showWorld()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

-- ลูกศรเด้ง + ระยะทาง ทุกเฟรม (เฉพาะตอนกำลังนำทางและมีเป้าหมาย)
RunService.RenderStepped:Connect(function()
	if step == 0 or not targetPos or not marker.Enabled then return end
	marker.StudsOffsetWorldSpace = Vector3.new(0, 6 + math.sin(os.clock() * 4) * 0.6, 0)
	local root = rootPart()
	if root then
		local dist = math.floor((targetPos - root.Position).Magnitude + 0.5)
		markerLabel.Text = markText .. " · " .. dist .. " " .. tr("ม.", "m")
	end
end)
-- เกิดใหม่: ตัวละครใหม่ยังไม่มี Attachment ลูปตรวจจะสร้างให้ในรอบถัดไป (showWorld)

stopButton.Activated:Connect(stop)

local startEvent = Instance.new("BindableEvent")
startEvent.Name = "StartGuide"
startEvent.Parent = gui
startEvent.Event:Connect(start)

-- ผู้เล่นใหม่: เริ่มเอง 1 ครั้งต่อรอบที่เล่น (IsNewPlayer มาช้าหลังโหลดเหรียญ จึงฟังการเปลี่ยนด้วย)
local autoQueued = false
local function maybeAutoStart()
	if autoQueued or everStarted or player:GetAttribute("IsNewPlayer") ~= true then return end
	autoQueued = true
	task.delay(AUTO_START_DELAY, function()
		if not everStarted then start() end
	end)
end
player:GetAttributeChangedSignal("IsNewPlayer"):Connect(maybeAutoStart)
maybeAutoStart()
