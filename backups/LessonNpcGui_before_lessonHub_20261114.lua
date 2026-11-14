-- BACKUP 2026-11-14 — StarterPlayer.StarterPlayerScripts.LessonNpcGui (LocalScript) before moving lessons into ReplicatedStorage.LessonContent + RunLesson event (lesson hub)
-- Restore: in Studio open StarterPlayer.StarterPlayerScripts.LessonNpcGui and paste everything below the "BEGIN SOURCE" line over the whole Source (and delete ReplicatedStorage.LessonContent)
-- ===== BEGIN SOURCE =====
-- LessonNpcGui (2026-11-13 ผู้ใช้ขอ ช่วงที่ 1): NPC "ครูฟาร์ม" (Workspace.GuideNPC) บอกวิธีเล่นเรื่องต่างๆ
-- กดคุย (ProximityPrompt GuideNPC...TalkPrompt) = เปิดหน้าต่างบทเรียน: แต่ละหัวข้อมีวิธีเล่น 3 ข้อ + ปุ่ม "พาไป" (เส้นทองนำทางของ NewPlayerGuide ผ่าน NewPlayerGuideGui.GuideTo)
-- ช่วงที่ 2 (วันเดียวกัน): รางวัลเหรียญต่อบทเรียน · เซิร์ฟเวอร์ (ServerScriptService.LessonService) ยืนยันว่าทำแล้วและตั้ง Attribute บนผู้เล่น Lesson_<id> = 0 ยังไม่ทำ / 1 รอรับ / 2 รับแล้ว
--   หน้าต่างนี้แค่แสดงสถานะและส่งคำขอรับรางวัล (RemoteFunction LessonRequest "claim") จำนวนเหรียญอ่านจาก ReplicatedStorage.LessonConfig · LessonConfig ปิด/ไม่มี = หน้าต่างข้อมูลเฉยๆ แบบช่วงที่ 1
--   ปุ่มของแต่ละการ์ด: ยังไม่ทำ/รับแล้ว = "พาไป" (หรือ "เริ่มนำทาง" ของบท ปลูก เก็บ ขาย) · รอรับ = ปุ่มทอง "รับรางวัล"
-- เพิ่มหัวข้อ: เติมใน LESSONS และใส่ getPos (คืน Vector3 ของจุดที่จะพาไป หรือ nil = ซ่อนปุ่มพาไป) · available() คืน false = ไม่แสดงหัวข้อนั้น
-- ป้ายเหนือหัว NPC: ชื่อ + "!" สีทอง จนกว่าจะคุยครั้งแรกในรอบที่เล่นนั้น และขึ้นอีกทุกครั้งที่มีรางวัลรอรับ (BillboardGui ต้องอยู่ใน PlayerGui + Adornee · AlwaysOnTop = false ตามเกร็ดบทเรียนเดิม)
-- เมนูอื่นเปิดได้ด้วย BindableEvent LessonNpcGui.OpenLessons · จอย: เปิดแล้วเลือกปุ่มพาไปอันแรกให้ · B ปิด

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
-- รางวัล (ช่วงที่ 2): ไม่มีโมดูล/ปิดอยู่ = ไม่แสดงรางวัล
local LessonConfig
do
	local module = ReplicatedStorage:WaitForChild("LessonConfig", 10)
	local ok, result = pcall(function() return module and require(module) end)
	if ok and type(result) == "table" and result.ENABLED then LessonConfig = result end
end
-- สถานะรอรับ/รับแล้ว: LessonConfig ปิด/ไม่มี = ค่าที่ไม่มีวันตรง (lessonReward คืน nil อยู่แล้ว) กันอ้าง LessonConfig ที่เป็น nil
local STATE_READY = LessonConfig and LessonConfig.READY or -1
local STATE_CLAIMED = LessonConfig and LessonConfig.CLAIMED or -2
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local function tr(th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_CARD = Color3.fromRGB(255, 240, 225)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_SUB = Color3.fromRGB(130, 100, 90)
local COLOR_BORDER = Color3.fromRGB(140, 100, 65)
local COLOR_GOLD = Color3.fromRGB(255, 205, 80)
local COLOR_GO = Color3.fromRGB(0, 176, 111)

local NPC_NAME_TH, NPC_NAME_EN = "ครูฟาร์ม", "Farm Teacher"

local function rootPart()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- น้ำที่ใกล้ผู้เล่นที่สุด: ยิงเส้นลงพื้นเป็นวงแหวนรอบตัว ขยายทีละ 12 สตั๊ด (แบบเดียวกับบทเรียนเดิม)
local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false
waterParams.FilterType = Enum.RaycastFilterType.Exclude
local function nearestWater()
	local root = rootPart()
	if not root then return nil end
	waterParams.FilterDescendantsInstances = { player.Character }
	local origin = root.Position
	for r = 12, 240, 12 do
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2
			local p = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local hit = workspace:Raycast(Vector3.new(p.X, origin.Y + 40, p.Z), Vector3.new(0, -90, 0), waterParams)
			if hit and hit.Material == Enum.Material.Water then return hit.Position end
		end
	end
	return nil
end

-- หัวข้อบทเรียน (แก้/เพิ่มที่นี่ที่เดียว) · อิโมจิที่ใช้เคยแสดงผลได้ในเกมนี้แล้ว
local LESSONS = {
	{
		id = "basic", icon = "🌱", th = "ปลูก เก็บ ขาย", en = "Plant, harvest, sell",
		thLines = "1. กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน\n2. รอต้นโต แล้วกดปุ่มเก็บที่ต้น\n3. ขายผลผลิตที่ร้านเมล็ด แล้วซื้อเมล็ดใหม่",
		enLines = "1. Tap slot 1 (seeds), then tap a soil plot\n2. Wait for it to grow, then press harvest on the crop\n3. Sell your crops at the seed shop, then buy new seeds",
		startGuide = true, -- ปุ่ม = เริ่มลูกศรนำทาง 4 ขั้นของ NewPlayerGuide (NewPlayerGuideGui.StartGuide)
	},
	{
		id = "fish", icon = "🎣", th = "ตกปลา", en = "Fishing",
		thLines = "1. กดช่อง 6 เพื่อถือเบ็ด (ได้เบ็ดฟรีตอนเข้าเกม)\n2. ยืนใกล้น้ำ เบ็ดจะเหวี่ยงและดึงปลาเอง\n3. ขายปลาและซื้อเบ็ดที่ร้านตกปลา (เมนูขีดสามเส้น > วาป)",
		enLines = "1. Tap slot 6 to hold your rod (free when you join)\n2. Stand near water. It casts and reels in by itself\n3. Sell fish and buy rods at the Fishing Store (three-line menu > Warp)",
		markTh = "น้ำตกปลา", markEn = "Fishing water",
		guideTh = "ไปที่น้ำ แล้วกดช่อง 6 (เบ็ด)", guideEn = "Go to the water, then tap slot 6 (rod)",
		doneTh = "ถึงน้ำแล้ว! กดช่อง 6 เพื่อตกปลา", doneEn = "You're at the water! Tap slot 6 to fish",
		arriveDist = 10,
		getPos = nearestWater,
		-- ตกได้ระหว่างนำทาง = จบการนำทางเลย (2026-11-14: ผู้ใช้เดินไปตกปลาตรงอื่นได้ปลาแล้วการ์ดยังค้าง เพราะยืนห่างจุดน้ำที่สุ่มไว้เกิน 10 สตั๊ด)
		endOnCatch = true,
		catchTh = "ตกปลาได้แล้ว! เก่งมาก ขายปลาได้ที่ร้านตกปลา", catchEn = "You caught one! Sell fish at the Fishing Store",
	},
	{
		id = "chicken", icon = "🐔", th = "เลี้ยงไก่", en = "Chickens",
		thLines = "1. ไปฟาร์มไก่ (เดินตามเส้น หรือเมนูขีดสามเส้น > วาป)\n2. ซื้อไก่ที่ร้านไก่ ไก่จะออกไข่เอง\n3. เก็บไข่แล้วขาย คอยกวาดเล้าให้สะอาด ไข่จะออกเร็วขึ้น",
		enLines = "1. Go to the Chicken Farm (follow the line, or three-line menu > Warp)\n2. Buy a chicken at the chicken shop. It lays eggs by itself\n3. Collect and sell the eggs. Keep the coop clean for faster eggs",
		markTh = "ฟาร์มไก่", markEn = "Chicken Farm",
		guideTh = "ไปฟาร์มไก่ (ไกล? ใช้เมนูขีดสามเส้น > วาป)", guideEn = "Go to the Chicken Farm (far? use the menu > Warp)",
		doneTh = "ถึงฟาร์มไก่แล้ว! ซื้อไก่ตัวแรกที่ร้านไก่", doneEn = "You're at the Chicken Farm! Buy your first chicken",
		arriveDist = 16,
		available = function() -- ฟาร์มไก่ปิด (ChickenConfig.Enabled = false) = ไม่แสดงหัวข้อนี้
			local module = ReplicatedStorage:FindFirstChild("ChickenConfig", true)
			if not module then return false end
			local ok, config = pcall(require, module)
			return ok and type(config) == "table" and config.Enabled == true
		end,
		getPos = function() -- ChickenService ตั้ง Attribute ChickenShopPos บน ReplicatedStorage
			local pos = ReplicatedStorage:GetAttribute("ChickenShopPos")
			return typeof(pos) == "Vector3" and pos or nil
		end,
	},
}

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0); c.Parent = obj; return c end

-- ============ หน้าต่างบทเรียน ============
local gui = Instance.new("ScreenGui")
gui.Name = "LessonNpcGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = playerGui

local WIDTH = 430
local CARD_HEIGHT = 132
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 24)
main.BackgroundColor3 = COLOR_BG
main.Active = true
main.SelectionGroup = true
main.Parent = gui
corner(main, 18)
do
	local st = Instance.new("UIStroke"); st.Color = COLOR_BORDER; st.Thickness = 3; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = main
end
local uiScale = Instance.new("UIScale")
uiScale.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 8)
title.Size = UDim2.new(1, -70, 0, 36)
title.Font = Enum.Font.GothamBold
title.TextSize = 19
title.TextColor3 = COLOR_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = main

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 6)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(235, 100, 100)
closeButton.Text = "X"
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Selectable = true
closeButton.Parent = main
corner(closeButton)

-- สถานะรางวัลของบทเรียน (จาก Attribute ที่เซิร์ฟเวอร์ตั้ง) คืน (สถานะ, จำนวนเหรียญ) · ไม่มีรางวัล = nil
local function lessonReward(id)
	local coins = LessonConfig and LessonConfig.Rewards[id]
	if not coins or player:GetAttribute("LessonsLoaded") ~= true then return nil end
	return tonumber(player:GetAttribute("Lesson_" .. id)) or LessonConfig.TODO, coins
end
local function formatCoins(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local close -- ประกาศก่อน นิยามด้านล่าง (ปุ่มพาไปเรียกใช้)
local layout -- เช่นกัน (ปุ่มรับรางวัลเรียกใช้หลังเซิร์ฟเวอร์ตอบ)
local claimBusy = false
local catchGuide -- { lesson, title } นำทางตกปลาที่กดพาไปล่าสุด รอปลาตัวแรก (ดูท้ายส่วนหน้าต่าง)
local cards = {} -- { { lesson, frame, name, lines, go } }
for _, lesson in ipairs(LESSONS) do
	local card = Instance.new("Frame")
	card.Name = "Lesson_" .. lesson.id
	card.Size = UDim2.new(1, -20, 0, CARD_HEIGHT)
	card.BackgroundColor3 = COLOR_CARD
	card.Parent = main
	corner(card, 10)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 8, 0, 4)
	icon.Size = UDim2.fromOffset(30, 28)
	icon.Text = lesson.icon
	icon.TextSize = 22
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 44, 0, 4)
	name.Size = UDim2.new(1, -150, 0, 28)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 17
	name.TextColor3 = COLOR_TEXT
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = card

	local go = Instance.new("TextButton")
	go.Name = "Go"
	go.AnchorPoint = Vector2.new(1, 0)
	go.Position = UDim2.new(1, -8, 0, 6)
	go.Size = UDim2.fromOffset(92, 36)
	go.BackgroundColor3 = COLOR_GO
	go.Font = Enum.Font.GothamBold
	go.TextSize = 15
	go.TextColor3 = Color3.new(1, 1, 1)
	go.Selectable = true
	go.Parent = card
	corner(go, 10)

	local lines = Instance.new("TextLabel")
	lines.Name = "Lines"
	lines.BackgroundTransparency = 1
	lines.Position = UDim2.new(0, 12, 0, 44)
	lines.Size = UDim2.new(1, -24, 1, -50)
	lines.Font = Enum.Font.Gotham
	lines.TextSize = 13
	lines.LineHeight = 1.15
	lines.TextColor3 = COLOR_SUB
	lines.TextXAlignment = Enum.TextXAlignment.Left
	lines.TextYAlignment = Enum.TextYAlignment.Top
	lines.TextWrapped = true
	lines.Parent = card

	go.Activated:Connect(function()
		-- รอรับรางวัล = ปุ่มนี้คือ "รับรางวัล": ขอเซิร์ฟเวอร์ แล้ววาดหน้าต่างใหม่ตามสถานะล่าสุด (เซิร์ฟเวอร์แจ้งผลเอง)
		local state = lessonReward(lesson.id)
		if state == STATE_READY then
			if claimBusy then return end
			local request = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("LessonRequest")
			if not request then return end
			claimBusy = true
			go.Text = "..."
			task.spawn(function()
				pcall(function() request:InvokeServer("claim", lesson.id) end)
				claimBusy = false
				if gui.Enabled then layout() end
			end)
			return
		end
		if lesson.startGuide then
			close()
			local guide = playerGui:FindFirstChild("NewPlayerGuideGui")
			local ev = guide and guide:FindFirstChild("StartGuide")
			if ev then ev:Fire() end
			return
		end
		local pos = lesson.getPos and lesson.getPos()
		if not pos then return end
		close()
		local guide = playerGui:FindFirstChild("NewPlayerGuideGui")
		local ev = guide and guide:FindFirstChild("GuideTo")
		if ev then
			ev:Fire({
				pos = pos,
				title = tr(NPC_NAME_TH, NPC_NAME_EN) .. ": " .. tr(lesson.th, lesson.en),
				text = tr(lesson.guideTh, lesson.guideEn),
				mark = tr(lesson.markTh, lesson.markEn),
				arriveDist = lesson.arriveDist,
				doneText = tr(lesson.doneTh, lesson.doneEn),
			})
			if lesson.endOnCatch then
				catchGuide = { lesson = lesson, title = tr(NPC_NAME_TH, NPC_NAME_EN) .. ": " .. tr(lesson.th, lesson.en) }
			end
		end
	end)

	table.insert(cards, { lesson = lesson, frame = card, name = name, lines = lines, go = go })
end

-- ตกปลาได้ระหว่างนำทางตกปลา: จบการนำทางด้วย GuideTo ที่ตำแหน่งตัวเอง (ถึงทันที แสดงข้อความแล้วการ์ดหายเอง)
-- เฉพาะตอนการ์ดนำทางยังเป็นของบทตกปลาอยู่ (หัวการ์ดตรงกัน) · กด X หรือมีนำทางอื่นแทนแล้ว = ไม่ยุ่ง
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
	local fishingState = remotes:WaitForChild("FishingState", 120)
	if not fishingState then return end
	fishingState.OnClientEvent:Connect(function(state)
		if state ~= "caught" or not catchGuide then return end
		local active = catchGuide
		catchGuide = nil
		local guide = playerGui:FindFirstChild("NewPlayerGuideGui")
		local cardTitle = guide and guide:FindFirstChild("Card") and guide.Card:FindFirstChild("Title")
		local ev = guide and guide:FindFirstChild("GuideTo")
		local root = rootPart()
		if not (ev and root and guide.Enabled and cardTitle and cardTitle.Text == active.title) then return end
		ev:Fire({
			pos = root.Position,
			title = active.title,
			text = "",
			mark = "",
			arriveDist = 1e6,
			doneText = tr(active.lesson.catchTh, active.lesson.catchEn),
		})
	end)
end)

-- จัดหน้าต่างทุกครั้งที่เปิด: ภาษาปัจจุบัน, หัวข้อที่เปิดอยู่, ความสูงตามจำนวนหัวข้อ, ย่อให้พอดีจอเตี้ย/แคบ
local firstGo
layout = function()
	title.Text = tr(NPC_NAME_TH, NPC_NAME_EN) .. ": " .. tr("อยากรู้เรื่องไหน?", "pick a topic") -- สั้นไว้ ไม่ให้ชนปุ่ม X
	local y = 52
	firstGo = nil
	for _, c in ipairs(cards) do
		local show = c.lesson.available == nil or c.lesson.available() == true
		c.frame.Visible = show
		if show then
			c.frame.Position = UDim2.new(0, 10, 0, y)
			y += CARD_HEIGHT + 8
			c.lines.Text = tr(c.lesson.thLines, c.lesson.enLines)
			-- ชื่อบทเรียน + รางวัล/สถานะในบรรทัดเดียวกัน · ปุ่มเปลี่ยนตามสถานะ
			local state, coins = lessonReward(c.lesson.id)
			local nameText = tr(c.lesson.th, c.lesson.en)
			local canGo = c.lesson.getPos ~= nil or c.lesson.startGuide == true
			if state == STATE_READY then
				c.name.Text = nameText .. " · 💰 " .. formatCoins(coins)
				c.go.Text = tr("รับรางวัล", "Claim")
				c.go.BackgroundColor3 = COLOR_GOLD
				c.go.TextColor3 = COLOR_TEXT
				c.go.Visible = true
			else
				if state == STATE_CLAIMED then
					c.name.Text = nameText .. " · ✅ " .. tr("รับแล้ว", "Claimed")
				elseif state then
					c.name.Text = nameText .. " · 💰 " .. formatCoins(coins)
				else
					c.name.Text = nameText
				end
				c.go.Text = c.lesson.startGuide and tr("เริ่มนำทาง", "Start") or tr("พาไป", "Take me")
				c.go.BackgroundColor3 = COLOR_GO
				c.go.TextColor3 = Color3.new(1, 1, 1)
				c.go.Visible = canGo
			end
			if not firstGo and c.go.Visible then firstGo = c.go end
		end
	end
	local height = y + 4
	main.Size = UDim2.fromOffset(WIDTH, height)
	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize
	if vp and vp.X > 2 then
		uiScale.Scale = math.clamp(math.min((vp.Y - 80) / height, (vp.X - 24) / WIDTH), 0.6, 1)
	end
end

-- ============ เปิด / ปิด ============
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local talkedOnce = false
local refreshHeadSign -- นิยามในหัวข้อ NPC
close = function()
	gui.Enabled = false
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(main) then GuiService.SelectedObject = nil end
end
local function open()
	layout()
	talkedOnce = true
	if refreshHeadSign then refreshHeadSign() end
	gui.Enabled = true
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then
		GuiService.SelectedObject = firstGo or closeButton
	end
end
closeButton.Activated:Connect(close)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and gui.Enabled then close() end
end)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if gui.Enabled then layout() end
end)

local openEvent = Instance.new("BindableEvent")
openEvent.Name = "OpenLessons"
openEvent.Parent = gui
openEvent.Event:Connect(open)

-- ============ NPC: ป้ายกดคุย + ป้ายเหนือหัว ============
-- NPC อยู่ไกลอาจยังไม่ถูกสตรีมมา (StreamingEnabled) จึงรอแบบไม่จำกัดเวลาในเธรดแยก และตั้งค่าใหม่ทุกครั้งที่โมเดลโผล่กลับมา
local headSign = Instance.new("BillboardGui")
headSign.Name = "LessonNpcSign"
headSign.Size = UDim2.fromOffset(200, 64)
headSign.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
headSign.AlwaysOnTop = false
headSign.MaxDistance = 150
headSign.ResetOnSpawn = false
headSign.Enabled = false
headSign.Parent = playerGui
local signMark = Instance.new("TextLabel")
signMark.Name = "Mark"
signMark.BackgroundTransparency = 1
signMark.Size = UDim2.new(1, 0, 0, 36)
signMark.Font = Enum.Font.GothamBlack
signMark.TextSize = 34
signMark.Text = "!"
signMark.TextColor3 = COLOR_GOLD
signMark.TextStrokeColor3 = COLOR_TEXT
signMark.TextStrokeTransparency = 0
signMark.Parent = headSign
local signName = Instance.new("TextLabel")
signName.Name = "NpcName"
signName.BackgroundTransparency = 1
signName.Position = UDim2.new(0, 0, 0, 36)
signName.Size = UDim2.new(1, 0, 0, 26)
signName.Font = Enum.Font.GothamBold
signName.TextSize = 18
signName.TextColor3 = Color3.new(1, 1, 1)
signName.TextStrokeColor3 = COLOR_TEXT
signName.TextStrokeTransparency = 0
signName.Parent = headSign

refreshHeadSign = function()
	local rewardWaiting = false
	for _, lesson in ipairs(LESSONS) do
		if lessonReward(lesson.id) == STATE_READY then rewardWaiting = true end
	end
	signMark.Visible = not talkedOnce or rewardWaiting
	signName.Text = tr(NPC_NAME_TH, NPC_NAME_EN)
end
-- สถานะรางวัลเปลี่ยน (เซิร์ฟเวอร์ตั้ง Attribute): อัปเดต "!" เหนือหัว และหน้าต่างที่เปิดอยู่
local function onLessonStateChanged()
	refreshHeadSign()
	if gui.Enabled and not claimBusy then layout() end
end
player:GetAttributeChangedSignal("LessonsLoaded"):Connect(onLessonStateChanged)
for _, lesson in ipairs(LESSONS) do
	player:GetAttributeChangedSignal("Lesson_" .. lesson.id):Connect(onLessonStateChanged)
end

local boundNpcs = setmetatable({}, { __mode = "k" }) -- กันผูกซ้ำ (เธรดรอ + ChildAdded อาจเจอโมเดลเดียวกัน)
local function bindNpc(npc)
	if boundNpcs[npc] then return end
	boundNpcs[npc] = true
	-- ป้ายคุยอยู่ในชิ้นส่วนของโมเดล (ไม่ใช่ลูกตรง) รอให้สตรีมมาถึงไม่เกิน 30 วิ
	local prompt
	local t0 = os.clock()
	repeat
		prompt = npc:FindFirstChild("TalkPrompt", true)
		if not prompt then task.wait(0.5) end
	until prompt or os.clock() - t0 > 30 or not npc.Parent
	if not prompt or not prompt:IsA("ProximityPrompt") then
		boundNpcs[npc] = nil
		return
	end
	prompt.ActionText = tr("คุย", "Talk")
	prompt.ObjectText = tr(NPC_NAME_TH, NPC_NAME_EN)
	prompt.Triggered:Connect(open)
	local part = prompt.Parent
	if part and part:IsA("BasePart") then
		headSign.Adornee = part
		refreshHeadSign()
		headSign.Enabled = true
	end
end
task.spawn(function()
	local npc = workspace:WaitForChild("GuideNPC")
	bindNpc(npc)
end)
workspace.ChildAdded:Connect(function(child)
	if child.Name == "GuideNPC" then task.defer(bindNpc, child) end
end)
