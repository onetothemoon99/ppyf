-- BACKUP 2026-11-13 — StarterPlayer.StarterPlayerScripts.HowToPlayGui (LocalScript) ก่อนเพิ่มปุ่ม "เริ่มนำทาง" (ระบบลูกศร 3 ขั้น NewPlayerGuide)
-- วิธีคืน: ใน Studio เปิด StarterPlayer.StarterPlayerScripts.HowToPlayGui แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 3 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- และลบ/ปิด StarterPlayer.StarterPlayerScripts.NewPlayerGuide ถ้าต้องการเอาระบบลูกศรออกด้วย
-- HowToPlayGui (2026-11-13 ผู้ใช้ขอ): ปุ่ม "?" สอนเล่น กึ่งกลางบนจอ แนวเดียวกับปุ่มแถวบน (ตำแหน่งเดิมของปุ่มเพนกวิน Music Box ซึ่งย้ายไปข้างปุ่ม ☰ ดู MoreMenuGui)
-- กด = เปิด/ปิดแผง "วิธีเล่น" 5 ข้อสั้นๆ (ปลูก เก็บ ขาย ตกปลา เมนูเพิ่มเติม) · ยังเป็นข้อความอย่างเดียว ไม่มีภารกิจ/ลูกศร/รางวัล
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

-- ข้อความสอนเล่น: แก้/เพิ่มข้อได้ที่นี่ที่เดียว (อิโมจิทุกตัวเคยใช้ในเกมนี้แล้ว แสดงผลได้)
local STEPS = {
	{ icon = "🌱", th = "ปลูก", en = "Plant",
		thDesc = "กดช่อง 1 (เมล็ด) แล้วแตะที่แปลงดิน", enDesc = "Tap slot 1 (seeds), then tap a soil plot" },
	{ icon = "✅", th = "เก็บ", en = "Harvest",
		thDesc = "รอต้นโต แล้วกดปุ่มเก็บที่ขึ้นบนต้น", enDesc = "Wait for the crop to grow, then press the harvest button on it" },
	{ icon = "💰", th = "ขาย", en = "Sell",
		thDesc = "ไปร้านเมล็ด ขายผลผลิต แล้วซื้อเมล็ดใหม่", enDesc = "Go to the seed shop, sell your crops, then buy new seeds" },
	{ icon = "🎣", th = "ตกปลา", en = "Fish",
		thDesc = "กดช่อง 6 (เบ็ด) ใกล้น้ำ เบ็ดจะเหวี่ยงเอง", enDesc = "Tap slot 6 (rod) near water. It casts by itself" },
	{ icon = "🧭", th = "เมนูเพิ่มเติม", en = "More menu",
		thDesc = "ปุ่มขีดสามเส้นมุมซ้ายบน: วาป สมุดปลา ท่าเต้น และอื่นๆ", enDesc = "The three-line button at the top left: warp, fish book, dances and more" },
}

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

local WIDTH = 400
local ROW_HEIGHT = 64 -- ชื่อ 1 บรรทัด + คำอธิบายได้ 2 บรรทัด
local HEIGHT = 52 + #STEPS * (ROW_HEIGHT + 6) + 10
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 24) -- เลื่อนลง 24 ให้พ้นปุ่ม "?" กึ่งกลางบนจอ (จอเตี้ยแผงเคยทับปุ่ม)
main.Size = UDim2.fromOffset(WIDTH, HEIGHT)
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
local function fit()
	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize
	if not vp or vp.X < 2 then return end
	-- ย่อทั้งแผงให้พอดีจอเตี้ย/แคบ (มือถือแนวนอนสูงราว 390: ได้ ~0.8 ตัวหนังสือ 13 → ~10 px ยังอ่านออก)
	uiScale.Scale = math.clamp(math.min((vp.Y - 80) / HEIGHT, (vp.X - 24) / WIDTH), 0.6, 1)
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 8)
title.Size = UDim2.new(1, -70, 0, 36)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = COLOR_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
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

local rowTexts = {} -- { { name = TextLabel, desc = TextLabel, step = table } }
for i, step in ipairs(STEPS) do
	local card = Instance.new("Frame")
	card.Name = "Step" .. i
	card.Position = UDim2.new(0, 10, 0, 52 + (i - 1) * (ROW_HEIGHT + 6))
	card.Size = UDim2.new(1, -20, 0, ROW_HEIGHT)
	card.BackgroundColor3 = COLOR_CARD
	card.Parent = main
	corner(card, 10)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 6, 0, 0)
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.Text = step.icon
	icon.TextSize = 26
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 52, 0, 6)
	name.Size = UDim2.new(1, -60, 0, 20)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextColor3 = COLOR_TEXT
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.new(0, 52, 0, 26)
	desc.Size = UDim2.new(1, -60, 0, 34)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 13
	desc.TextColor3 = COLOR_SUB
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Parent = card

	rowTexts[i] = { name = name, desc = desc, step = step }
end

-- อ่านภาษาทุกครั้งที่เปิด เผื่อผู้เล่นเปลี่ยนภาษา Roblox ระหว่างเล่น
local function refreshTexts()
	title.Text = tr("วิธีเล่น", "How to play")
	for i, r in ipairs(rowTexts) do
		r.name.Text = i .. ". " .. tr(r.step.th, r.step.en)
		r.desc.Text = tr(r.step.thDesc, r.step.enDesc)
	end
end

-- ============ เปิด / ปิด ============
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function close()
	gui.Enabled = false
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(main) then GuiService.SelectedObject = nil end
end
local function open()
	refreshTexts()
	fit()
	openedOnce = true
	gui.Enabled = true
	setNewDot(false)
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then
		GuiService.SelectedObject = closeButton
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

-- ป้ายแดงสำหรับผู้เล่นใหม่ (IsNewPlayer มาช้าหลังโหลดเหรียญ จึงฟังการเปลี่ยนด้วย) · เปิดแผงครั้งแรกแล้วหาย (จำแค่ในรอบที่เล่นนี้)
local function refreshNewDot()
	if player:GetAttribute("IsNewPlayer") == true and not openedOnce then setNewDot(true) end
end
player:GetAttributeChangedSignal("IsNewPlayer"):Connect(refreshNewDot)
refreshNewDot()
