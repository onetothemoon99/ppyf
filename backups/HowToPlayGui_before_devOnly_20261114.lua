-- BACKUP 2026-11-14 — StarterPlayer.StarterPlayerScripts.HowToPlayGui (LocalScript) ก่อนทำระบบสอนเล่นเป็น DEV_ONLY (ซ่อนบนเซิร์ฟจริง)
-- วิธีคืน: ใน Studio เปิด StarterPlayer.StarterPlayerScripts.HowToPlayGui แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 2 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- HowToPlayGui (2026-11-13 ผู้ใช้ขอ): ปุ่ม "?" สอนเล่น กึ่งกลางบนจอ แนวเดียวกับปุ่มแถวบน (ตำแหน่งเดิมของปุ่มเพนกวิน Music Box ซึ่งย้ายไปข้างปุ่ม ☰ ดู MoreMenuGui)
-- กด = เปิด/ปิดแผง "วิธีเล่น" (2026-11-14 ผู้ใช้เลือก "Full plan (link teacher)"): แถวบทเรียน ปลูก เก็บ ขาย / ตกปลา / เลี้ยงไก่ (จาก LessonContent) + หุ่นนกฮูก + เมนูเพิ่มเติม
--   แต่ละแถว: ไอคอน · ชื่อ + ป้ายรางวัล (💰 10,000 / รอรับ / ✅ รับแล้ว จาก Attribute Lesson_<id>) · คำอธิบายบรรทัดเดียว · ปุ่มขวา (เริ่ม/พาไป/ไปรับ)
--   ปุ่มสั่งงานผ่าน BindableEvent LessonNpcGui.RunLesson(id) (ทางเดียวกับปุ่มในหน้าต่างหุ่นนกฮูก) · กดรับรางวัลได้ที่หุ่นนกฮูกเท่านั้น (แถวที่รอรับ = ปุ่มทอง "ไปรับ" พาไปหาครู)
--   แผงชิดใต้ปุ่ม "?" และย่อให้ไม่ลงไปทับ hotbar · ป้าย "!" บนปุ่ม "?" ขึ้นด้วยเมื่อมีรางวัลรอรับ
-- ผู้เล่นใหม่ (Attribute IsNewPlayer จาก LeaderstatsSetup) = มีป้ายแดง "!" กระพริบมุมขวาบนของปุ่มจนกว่าจะเปิดครั้งแรก (ไม่เด้งหน้าต่างเอง)
-- ทดสอบใน Studio: ตั้ง Attribute IsNewPlayer = true บนผู้เล่นฝั่ง Client ตอน Play = ป้ายขึ้น
-- ไม่เกี่ยวกับ TutorialService / TutorialGui เดิม (ปิดถาวร 2026-11-01) · เมนูอื่นเปิดได้ด้วย BindableEvent HowToPlayGui.OpenHowToPlay
-- จอย: เปิดแล้วเลือกปุ่มปิดให้ · B ปิด

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
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

-- แถวในแผง: บทเรียนจาก ReplicatedStorage.LessonContent (ใช้ร่วมกับหน้าต่างหุ่นนกฮูก LessonNpcGui) + แถวหุ่นนกฮูก + แถวเมนูเพิ่มเติม
local LessonContent = require(ReplicatedStorage:WaitForChild("LessonContent"))
-- รางวัล (LessonConfig ปิด/ไม่มี = ไม่แสดงป้ายรางวัล แถวยังกดนำทางได้)
local LessonConfig
do
	local module = ReplicatedStorage:WaitForChild("LessonConfig", 10)
	local ok, result = pcall(function() return module and require(module) end)
	if ok and type(result) == "table" and result.ENABLED then LessonConfig = result end
end
local COLOR_GO = Color3.fromRGB(0, 176, 111)

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0); c.Parent = obj; return c end

-- ============ ปุ่มกึ่งกลางบนจอ (y=34 = แนวเดียวกับปุ่มแถวบน) ============
-- อยู่ใน ScreenGui ของตัวเองที่เปิดตลอด (แผงวิธีเล่นอยู่อีก ScreenGui ที่เปิด/ปิด)
local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "HowToPlayButtonGui"
buttonGui.ResetOnSpawn = false
buttonGui.DisplayOrder = 5
buttonGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
buttonGui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "HowToPlayButton"
openButton.AnchorPoint = Vector2.new(0.5, 0.5)
openButton.Position = UDim2.new(0.5, 0, 0, 34)
openButton.Size = UDim2.new(0, 44, 0, 44)
openButton.BackgroundColor3 = COLOR_GOLD
openButton.Text = "?" -- ตัวอักษรธรรมดา ไม่พึ่งอิโมจิ (บางตัวไม่แสดงในเกมนี้)
openButton.TextSize = 28
openButton.Font = Enum.Font.GothamBlack
openButton.TextColor3 = COLOR_TEXT
openButton.AutoButtonColor = true
openButton.Selectable = true
openButton.Parent = buttonGui
corner(openButton)
do
	local st = Instance.new("UIStroke"); st.Color = COLOR_BORDER; st.Thickness = 2; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = openButton
end
-- ป้ายแดง "!" มุมขวาบนของปุ่ม กระพริบ (ขยาย-หด + จาง-เข้ม) ตอนแสดง · ผู้ใช้ขอ 2026-11-13
local newDot = Instance.new("TextLabel")
newDot.Name = "NewDot"
newDot.AnchorPoint = Vector2.new(0.5, 0.5)
newDot.Position = UDim2.new(1, -5, 0, 5)
newDot.Size = UDim2.new(0, 20, 0, 20)
newDot.BackgroundColor3 = Color3.fromRGB(235, 45, 55)
newDot.Text = "!"
newDot.TextSize = 15
newDot.Font = Enum.Font.GothamBlack
newDot.TextColor3 = Color3.new(1, 1, 1)
newDot.Visible = false
newDot.ZIndex = 3
newDot.Parent = openButton
corner(newDot)
do
	local st = Instance.new("UIStroke"); st.Color = Color3.new(1, 1, 1); st.Thickness = 1.5; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = newDot
end
local newDotScale = Instance.new("UIScale")
newDotScale.Parent = newDot
local BLINK_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local blinkTweens = {
	TweenService:Create(newDotScale, BLINK_INFO, { Scale = 1.3 }),
	TweenService:Create(newDot, BLINK_INFO, { BackgroundTransparency = 0.45 }),
}
local openedOnce = false -- เปิดแผงแล้วในรอบที่เล่นนี้ = ป้ายแดงไม่กลับมาอีก
local function setNewDot(show)
	newDot.Visible = show
	for _, t in ipairs(blinkTweens) do
		if show then t:Play() else t:Cancel() end
	end
	if not show then
		newDotScale.Scale = 1
		newDot.BackgroundTransparency = 0
	end
end

-- ============ แผงวิธีเล่น ============
local gui = Instance.new("ScreenGui")
gui.Name = "HowToPlayGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = playerGui

local WIDTH = 420
local ROW_HEIGHT = 56
local ROW_GAP = 6
local TOP = 52 -- ใต้หัวแผง
local PANEL_Y = 64 -- ขอบบนของแผง (ใต้ปุ่ม "?" ที่ y 34 ± 22)
local HOTBAR_RESERVE = 84 -- เว้นที่ล่างจอให้ hotbar
local BUTTON_W = 92
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0)
main.Position = UDim2.new(0.5, 0, 0, PANEL_Y)
main.Size = UDim2.fromOffset(WIDTH, 200)
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
title.TextSize = 20
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

-- ============ แถว ============
-- kind: "lesson" (บทเรียน) / "teacher" (หุ่นนกฮูก) / "info" (ข้อมูลอย่างเดียว ไม่มีปุ่ม)
local ROWS = {}
for _, lesson in ipairs(LessonContent.LESSONS) do table.insert(ROWS, { kind = "lesson", data = lesson }) end
table.insert(ROWS, { kind = "teacher", data = LessonContent.TEACHER })
table.insert(ROWS, { kind = "info", data = LessonContent.MORE_MENU })

local function formatCoins(n)
	local str = tostring(math.floor(n))
	local out = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
-- สถานะรางวัลของบทเรียน: (สถานะ, เหรียญ) · ไม่มีรางวัล/ยังไม่โหลด = nil
local function lessonReward(id)
	local coins = LessonConfig and LessonConfig.Rewards[id]
	if not coins or player:GetAttribute("LessonsLoaded") ~= true then return nil end
	return tonumber(player:GetAttribute("Lesson_" .. id)) or LessonConfig.TODO, coins
end
local function anyRewardReady()
	if not LessonConfig then return false end
	for _, lesson in ipairs(LessonContent.LESSONS) do
		if LessonContent.IsAvailable(lesson) and lessonReward(lesson.id) == LessonConfig.READY then return true end
	end
	return false
end

local function runLesson(id)
	local npcGui = playerGui:FindFirstChild("LessonNpcGui")
	local ev = npcGui and npcGui:FindFirstChild("RunLesson")
	if ev then ev:Fire(id) end
end

local close -- นิยามด้านล่าง
for _, row in ipairs(ROWS) do
	local card = Instance.new("Frame")
	card.Name = "Row_" .. (row.data.id or row.kind)
	card.Size = UDim2.new(1, -20, 0, ROW_HEIGHT)
	card.BackgroundColor3 = COLOR_CARD
	card.Parent = main
	corner(card, 10)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 4, 0, 0)
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.Text = row.data.icon
	icon.TextSize = 26
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.Parent = card

	local hasButton = row.kind ~= "info"
	local textRight = hasButton and -(BUTTON_W + 60) or -56
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 48, 0, 6)
	name.Size = UDim2.new(1, textRight, 0, 22)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 17
	name.TextColor3 = COLOR_TEXT
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.new(0, 48, 0, 29)
	desc.Size = UDim2.new(1, textRight, 0, 20)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 14
	desc.TextColor3 = COLOR_SUB
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.Parent = card

	local go
	if hasButton then
		go = Instance.new("TextButton")
		go.Name = "Go"
		go.AnchorPoint = Vector2.new(1, 0.5)
		go.Position = UDim2.new(1, -8, 0.5, 0)
		go.Size = UDim2.fromOffset(BUTTON_W, 38)
		go.Font = Enum.Font.GothamBold
		go.TextSize = 15
		go.Selectable = true
		go.Parent = card
		corner(go, 10)
		go.Activated:Connect(function()
			close()
			if row.kind == "teacher" or go:GetAttribute("ToTeacher") then
				runLesson("teacher")
			else
				runLesson(row.data.id)
			end
		end)
	end
	row.card, row.name, row.desc, row.go = card, name, desc, go
end

-- จัดแผงทุกครั้งที่เปิด/สถานะเปลี่ยน: ภาษา, แถวที่แสดง, ป้ายรางวัล, ปุ่ม, ความสูง, ย่อให้พอดีจอ
local panelHeight = 200
local firstGo
local function setButton(go, text, gold, toTeacher)
	go.Text = text
	go.BackgroundColor3 = gold and COLOR_GOLD or COLOR_GO
	go.TextColor3 = gold and COLOR_TEXT or Color3.new(1, 1, 1)
	go:SetAttribute("ToTeacher", toTeacher == true)
end
local function fit()
	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize
	if not vp or vp.X < 2 then return end
	local availY = vp.Y - PANEL_Y - HOTBAR_RESERVE -- ViewportSize = ทั้งจอ · แผงวัดจากขอบบนจอ (DeviceSafeInsets ไม่ตัดแถบบนของ Roblox)
	uiScale.Scale = math.clamp(math.min(availY / panelHeight, (vp.X - 24) / WIDTH), 0.6, 1)
end
local COMPACT_ROW_HEIGHT = 40
local function rowShown(row)
	if row.kind == "lesson" then return LessonContent.IsAvailable(row.data) end
	if row.kind == "teacher" then return workspace:FindFirstChild("GuideNPC") ~= nil end
	return true
end
local function layout()
	title.Text = tr("วิธีเล่น", "How to play")
	local y = TOP
	firstGo = nil
	local ready = anyRewardReady()
	-- จอเตี้ย (มือถือแนวนอน): ถ้าแผงเต็มต้องย่อต่ำกว่า 0.85 ให้ซ่อนคำอธิบาย แถวเหลือ 40 ตัวหนังสือไม่เล็กเกิน
	local shown = 0
	for _, row in ipairs(ROWS) do if rowShown(row) then shown += 1 end end
	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize
	local fullHeight = TOP + shown * (ROW_HEIGHT + ROW_GAP) + 4
	local compact = vp ~= nil and vp.Y > 2 and (vp.Y - PANEL_Y - HOTBAR_RESERVE) < fullHeight * 0.85
	local rowH = compact and COMPACT_ROW_HEIGHT or ROW_HEIGHT
	for _, row in ipairs(ROWS) do
		local d = row.data
		local show = rowShown(row)
		row.card.Visible = show
		if show then
			row.card.Position = UDim2.new(0, 10, 0, y)
			row.card.Size = UDim2.new(1, -20, 0, rowH)
			row.name.Position = UDim2.new(0, 48, 0, compact and 9 or 6)
			row.desc.Visible = not compact
			if row.go then row.go.Size = UDim2.fromOffset(BUTTON_W, compact and 32 or 38) end
			y += rowH + ROW_GAP
			local nameText = tr(d.th, d.en)
			row.desc.Text = tr(d.hubTh, d.hubEn)
			if row.kind == "lesson" then
				local state, coins = lessonReward(d.id)
				if LessonConfig and state == LessonConfig.READY then
					row.name.Text = nameText .. " · 💰 " .. formatCoins(coins)
					row.desc.Text = tr("ทำแล้ว! ไปรับรางวัลที่หุ่นนกฮูก", "Done! Claim it from the Robot Owl")
					setButton(row.go, tr("ไปรับ", "Claim"), true, true)
				elseif LessonConfig and state == LessonConfig.CLAIMED then
					row.name.Text = nameText .. " · ✅"
					setButton(row.go, d.startGuide and tr("เริ่ม", "Start") or tr("พาไป", "Take me"), false)
				else
					row.name.Text = state and (nameText .. " · 💰 " .. formatCoins(coins)) or nameText
					setButton(row.go, d.startGuide and tr("เริ่ม", "Start") or tr("พาไป", "Take me"), false)
				end
				row.go.Visible = d.startGuide == true or d.getPos ~= nil
			elseif row.kind == "teacher" then
				if ready then
					row.name.Text = nameText .. " · " .. tr("มีรางวัลรอรับ", "reward waiting")
					setButton(row.go, tr("ไปรับ", "Claim"), true, true)
				else
					row.name.Text = nameText
					setButton(row.go, tr("พาไป", "Take me"), false, true)
				end
			else
				row.name.Text = nameText
			end
			if not firstGo and row.go and row.go.Visible then firstGo = row.go end
		end
	end
	panelHeight = y + 4
	main.Size = UDim2.fromOffset(WIDTH, panelHeight)
	fit()
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if gui.Enabled then layout() end -- จอเปลี่ยน (หมุนจอ/ย่อหน้าต่าง) = จัดใหม่ทั้งแผง เผื่อสลับโหมดแถวสั้น
end)

-- ============ เปิด / ปิด ============
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local refreshNewDot -- นิยามด้านล่าง
close = function()
	gui.Enabled = false
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(main) then GuiService.SelectedObject = nil end
end
local function open()
	layout()
	openedOnce = true
	gui.Enabled = true
	refreshNewDot()
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then
		GuiService.SelectedObject = firstGo or closeButton
	end
end
openButton.Activated:Connect(function()
	if gui.Enabled then close() else open() end
end)
closeButton.Activated:Connect(close)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and gui.Enabled then close() end
end)

local openEvent = Instance.new("BindableEvent")
openEvent.Name = "OpenHowToPlay"
openEvent.Parent = gui
openEvent.Event:Connect(open)

-- ป้ายแดง "!" บนปุ่ม "?": ผู้เล่นใหม่ที่ยังไม่เคยเปิดแผงในรอบนี้ หรือมีรางวัลบทเรียนรอรับ (หายเมื่อรับครบ)
refreshNewDot = function()
	local newPlayer = player:GetAttribute("IsNewPlayer") == true and not openedOnce
	local want = newPlayer or anyRewardReady()
	if want ~= newDot.Visible then setNewDot(want) end
end
local function onStateChanged()
	refreshNewDot()
	if gui.Enabled then layout() end
end
player:GetAttributeChangedSignal("IsNewPlayer"):Connect(refreshNewDot)
player:GetAttributeChangedSignal("LessonsLoaded"):Connect(onStateChanged)
for _, lesson in ipairs(LessonContent.LESSONS) do
	player:GetAttributeChangedSignal("Lesson_" .. lesson.id):Connect(onStateChanged)
end
refreshNewDot()
