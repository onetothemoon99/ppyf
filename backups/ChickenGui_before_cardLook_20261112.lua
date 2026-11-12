-- Backup 2026-11-12 of StarterPlayer.StarterPlayerScripts.ChickenGui (LocalScript) before the card look change (framing, light, mutation aura).
-- To restore: paste everything below these 2 lines back into StarterPlayer.StarterPlayerScripts.ChickenGui.Source.
-- ChickenGui: หน้าต่างระบบไก่ (2026-10-20) แยกตามจุดในแมพ (ผู้ใช้ขอ: เมนูเดียวหลายแท็บงง):
--   เล้า = "chickens" ไก่ของฉัน · ลุงไข่ขายไก่ = "shop" · รางอาหาร = "trough" · ตะกร้าไข่ = "basket" (RemoteEvent ChickenOpen(mode))
-- คำสั่งทั้งหมดส่ง RemoteEvents.ChickenRequest เซิร์ฟเป็นคนคิดทุกอย่าง หน้าจอแค่แสดงผล · รองรับจอย (B ปิด) และจอเล็ก (UIScale)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService") -- ของ Robux (ช่วงที่ 5)

local Config = require(ReplicatedStorage:WaitForChild("ChickenConfig"))
local tr, LANG = require(ReplicatedStorage:WaitForChild("Localization")).Tr()
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestRemote = remoteEvents:WaitForChild("ChickenRequest")
local syncRemote = remoteEvents:WaitForChild("ChickenSync")
local openRemote = remoteEvents:WaitForChild("ChickenOpen")

local player = Players.LocalPlayer

local W, H = 720, 430
local C_BG = Color3.fromRGB(255, 250, 240)
local C_HEAD = Color3.fromRGB(255, 160, 175)
local C_CARD = Color3.fromRGB(255, 255, 255)
local C_TEXT = Color3.fromRGB(70, 50, 45)
local C_SUB = Color3.fromRGB(140, 115, 105)
local C_BTN = Color3.fromRGB(120, 200, 120)
local C_BTN_OFF = Color3.fromRGB(200, 195, 190)
local C_SELL = Color3.fromRGB(255, 170, 90)
local C_TAB = Color3.fromRGB(255, 225, 230)
local C_TAB_ON = Color3.fromRGB(255, 120, 145)

local info = nil -- ข้อมูลล่าสุดจากเซิร์ฟ
local infoAt = os.clock()
local tab = "chickens" -- หน้าต่างที่เปิดอยู่
local SIZES = { chickens = Vector2.new(720, 480), shop = Vector2.new(640, 470), trough = Vector2.new(600, 400), basket = Vector2.new(600, 300), breed = Vector2.new(720, 470), book = Vector2.new(720, 480), contest = Vector2.new(720, 480), hall = Vector2.new(720, 480) }
-- หน้าต่างที่เปิดจากเล้า มีแถบสลับหน้าด้านบน (ช่วงที่ 6 เพิ่ม 🏆 ประกวด + 🏛 หอเกียรติยศ แทนปุ่มสมุดอันเดียว 2026-10-22)
local NAV_TABS = { "chickens", "book", "contest", "hall" }
local retireArmed = {} -- [id] = os.clock() กดปลดเกษียณครั้งแรก
local board = nil -- อันดับประกวดล่าสุด (ขอแยกจาก info)
local boardAt = -math.huge
local boardLoading = false
local selected = {} -- หน้าต่างผสมพันธุ์: id ไก่ที่เลือก (สูงสุด 2)
local pending = false
local sellArmed = {} -- [id] = os.clock() กดขายครั้งแรก
local lastSelectedName = nil

-- ============ โครงหน้าต่าง ============
local gui = Instance.new("ScreenGui")
gui.Name = "ChickenGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Text = ""
dim.AutoButtonColor = false
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.55
dim.Size = UDim2.fromScale(1, 1)
dim.Selectable = false
dim.ZIndex = 0
dim.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 18)
panel.Size = UDim2.fromOffset(W, H)
panel.BackgroundColor3 = C_BG
panel.SelectionGroup = true
panel.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = C_HEAD
stroke.Thickness = 3
local uiScale = Instance.new("UIScale", panel)

local function fit()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	uiScale.Scale = math.clamp(math.min((v.X - 24) / W, (v.Y - 84) / H), 0.5, 1.25)
end
fit()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 16
	l.TextColor3 = color or C_TEXT
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local selectRing = Instance.new("Frame")
selectRing.BackgroundTransparency = 1
Instance.new("UICorner", selectRing).CornerRadius = UDim.new(0, 10)
local ringStroke = Instance.new("UIStroke", selectRing)
ringStroke.Color = Color3.fromRGB(255, 190, 40)
ringStroke.Thickness = 3.5

local function button(parent, name, text, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color or C_BTN
	b.AutoButtonColor = true
	b.Selectable = true
	b.SelectionImageObject = selectRing
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end

-- หัวหน้าต่าง
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = C_HEAD
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
local title = label(header, tr("🐔 บ้านไก่", "🐔 Chicken Coop"), 22, Color3.new(1, 1, 1), true)
title.Position = UDim2.fromOffset(18, 0)
title.Size = UDim2.new(0, 360, 1, 0)
local subtitle = label(header, "", 15, Color3.new(1, 1, 1), false)
subtitle.Position = UDim2.fromOffset(200, 0)
subtitle.Size = UDim2.new(1, -420, 1, 0)
subtitle.TextXAlignment = Enum.TextXAlignment.Right
local closeButton = button(header, "Close", "X", Color3.fromRGB(235, 95, 115))
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -44, 0, 6)
closeButton.TextSize = 20
-- ปุ่มสลับ ไก่ของฉัน <-> สมุดไก่ (ช่วงที่ 4)
local bookButton = button(header, "BookToggle", "", Color3.fromRGB(255, 205, 90))
bookButton.Size = UDim2.fromOffset(150, 36)
bookButton.Position = UDim2.new(1, -202, 0, 6)
bookButton.TextSize = 15
bookButton.TextColor3 = Color3.fromRGB(110, 75, 60)
bookButton.Visible = false

local TITLES = {
	chickens = tr("🏠 ไก่ของฉัน", "🏠 My chickens"),
	shop = tr("🐔 ร้านไก่ลุงไข่", "🐔 Uncle Egg's Chickens"),
	trough = tr("🥣 รางอาหารไก่", "🥣 Feed trough"),
	basket = tr("🥚 แผงเก็บไข่", "🥚 Egg tray"),
	breed = tr("🥚 ตู้ฟักไข่ · ผสมพันธุ์", "🥚 Incubator · Breeding"),
	book = tr("📖 สมุดไก่", "📖 Chicken Book"),
	contest = tr("🏆 ประกวดไก่รายสัปดาห์", "🏆 Weekly Chicken Contest"),
	hall = tr("🏛 หอเกียรติยศ", "🏛 Hall of Fame"),
}

-- แถบสลับหน้า (ไก่ของฉัน / สมุด / ประกวด / หอเกียรติยศ) ใต้หัวหน้าต่าง
local navRow = Instance.new("Frame")
navRow.Name = "Nav"
navRow.BackgroundTransparency = 1
navRow.Position = UDim2.fromOffset(14, 54)
navRow.Size = UDim2.new(1, -28, 0, 34)
navRow.Visible = false
navRow.Parent = panel
local navLayout = Instance.new("UIListLayout", navRow)
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.Padding = UDim.new(0, 6)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
local NAV_LABELS = {
	chickens = tr("🐔 ไก่ของฉัน", "🐔 My chickens"), book = tr("📖 สมุดไก่", "📖 Book"),
	contest = tr("🏆 ประกวด", "🏆 Contest"), hall = tr("🏛 หอเกียรติยศ", "🏛 Hall of Fame"),
}
local navButtons = {}
local openTab -- ประกาศด้านล่าง (open)
for i, id in ipairs(NAV_TABS) do
	local b = button(navRow, "Nav_" .. id, NAV_LABELS[id], C_TAB)
	b.LayoutOrder = i
	b.Size = UDim2.new(0.25, -5, 1, 0)
	b.TextSize = 15
	b.Activated:Connect(function() if openTab then openTab(id) end end)
	navButtons[id] = b
end

-- เนื้อหา
local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(14, 58)
body.Size = UDim2.new(1, -28, 1, -104)
body.ScrollBarThickness = 6
body.ScrollingDirection = Enum.ScrollingDirection.Y
body.CanvasSize = UDim2.new()
body.Selectable = false
body.Parent = panel

local status = label(panel, "", 15, C_SUB, true)
status.Position = UDim2.new(0, 18, 1, -40)
status.Size = UDim2.new(1, -36, 0, 32)
status.TextXAlignment = Enum.TextXAlignment.Center

local function setStatus(text, good)
	status.Text = text or ""
	status.TextColor3 = good == false and Color3.fromRGB(215, 70, 70) or (good and Color3.fromRGB(60, 150, 70) or C_SUB)
end

local function clearBody()
	for _, c in ipairs(body:GetChildren()) do
		if not c:IsA("UIScale") then c:Destroy() end
	end
end

local function fitCanvas(layout, pad)
	local function upd()
		body.CanvasSize = UDim2.fromOffset(0, math.ceil(layout.AbsoluteContentSize.Y / math.max(uiScale.Scale, 0.01)) + (pad or 8))
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
	upd()
end

local function stars(n)
	n = math.clamp(n or 1, 1, 5)
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

local function fmtTime(s)
	s = math.max(0, math.floor(s))
	if s >= 86400 then -- ประกวดนับเป็นวัน (ช่วงที่ 6)
		return string.format("%d%s %d:%02d:%02d", s // 86400, tr(" วัน", "d"), (s % 86400) // 3600, (s % 3600) // 60, s % 60)
	end
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

local function fmtNum(n)
	local s = tostring(math.floor(n or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function card(parent, name, order)
	local f = Instance.new("Frame")
	f.Name = name
	f.LayoutOrder = order or 0
	f.BackgroundColor3 = C_CARD
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke", f)
	s.Color = Color3.fromRGB(240, 215, 205)
	s.Thickness = 1.5
	return f
end

-- ============ ส่งคำสั่ง ============
local render -- forward

local function send(action, arg)
	if pending then return end
	pending = true
	setStatus(tr("กำลังทำ...", "Working..."))
	local ok, res = pcall(function() return requestRemote:InvokeServer(action, arg) end)
	pending = false
	if not ok or type(res) ~= "table" then
		setStatus(tr("เชื่อมต่อไม่ได้ ลองใหม่อีกครั้ง", "Connection problem, try again"), false)
		return
	end
	if res.info then info, infoAt = res.info, os.clock() end
	setStatus(res.message, res.ok)
	render()
end

-- ============ แต่ละแท็บ ============
local timerLabels = {} -- { label, left, prefix?, done? } นับถอยหลังทุกครึ่งวิ

local function renderLocked(text)
	local l = label(body, text, 18, C_SUB, true)
	l.Size = UDim2.new(1, 0, 0, 120)
	l.TextXAlignment = Enum.TextXAlignment.Center
	body.CanvasSize = UDim2.new()
end

-- โมเดลไก่ 3D ในการ์ด (สีขน + กลายพันธุ์จาก ChickenLooks ตัวเดียวกับในลาน) 2026-10-20
local Looks = require(ReplicatedStorage:WaitForChild("ChickenLooks"))
local chickenTemplate = ReplicatedStorage:WaitForChild("ChickenTemplates"):WaitForChild("Chicken")
local function chickenViewport(parent, c, position, size, chick)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Model"
	vp.Size = UDim2.fromOffset(size, size)
	vp.Position = position
	vp.BackgroundColor3 = Color3.fromRGB(255, 244, 236)
	vp.BackgroundTransparency = 0
	vp.Ambient = Color3.fromRGB(200, 200, 200)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
	vp.Parent = parent
	Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 10)
	local model = chickenTemplate:Clone()
	Looks.Paint(model, c.Color, c.Mut)
	local gems = model:FindFirstChild("MutGems") -- 💎 การ์ดไม่ใช้เม็ดหมุน (กล้องด้านล่างคิดระยะจากขนาดโมเดล)
	if gems then gems:Destroy() end
	-- ไก่หันหน้า -Z: หมุนเล็กน้อยให้เห็นข้างตัว กล้องอยู่ด้านหน้า (ฝั่ง -Z)
	model:PivotTo(CFrame.Angles(0, math.rad(-25), 0))
	model.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	-- ถอยกล้องตามความสูงตัวจริงให้เห็นครบตั้งแต่หงอนถึงเท้า (เดิมระยะตายตัวใกล้เกิน หัว/เท้าโดนตัด) ลูกไก่ถอยออกไปอีกให้ดูตัวเล็ก
	local cf, s = model:GetBoundingBox()
	local half = math.max(s.Y, s.X) / 2
	local dist = half / math.tan(math.rad(cam.FieldOfView / 2)) * (chick and 1.75 or 1.35)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, half * 0.35, -dist), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

-- ============ ป๊อปอัพยืนยัน (ขายไก่ / ปลดเกษียณ / ขายลูกจากตู้ฟัก) แทนกดปุ่มซ้ำ 2 ครั้ง (ผู้ใช้ขอ 2026-10-22) ============
local confirmDim = Instance.new("TextButton")
confirmDim.Name = "ConfirmDim"
confirmDim.Text = ""
confirmDim.AutoButtonColor = false
confirmDim.Selectable = false
confirmDim.BackgroundColor3 = Color3.new(0, 0, 0)
confirmDim.BackgroundTransparency = 0.45
confirmDim.Size = UDim2.fromScale(1, 1)
confirmDim.ZIndex = 20
confirmDim.Visible = false
confirmDim.Parent = panel
Instance.new("UICorner", confirmDim).CornerRadius = UDim.new(0, 16)
local confirmBox = Instance.new("Frame")
confirmBox.Name = "ConfirmBox"
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBox.Position = UDim2.fromScale(0.5, 0.5)
confirmBox.Size = UDim2.fromOffset(400, 236)
confirmBox.BackgroundColor3 = C_BG
confirmBox.ZIndex = 21
confirmBox.Parent = confirmDim
Instance.new("UICorner", confirmBox).CornerRadius = UDim.new(0, 16)
local confirmStroke = Instance.new("UIStroke", confirmBox)
confirmStroke.Color = C_HEAD
confirmStroke.Thickness = 3
local confirmTitle = label(confirmBox, "", 20, C_TEXT, true)
confirmTitle.Position = UDim2.fromOffset(16, 10)
confirmTitle.Size = UDim2.new(1, -32, 0, 30)
confirmTitle.TextXAlignment = Enum.TextXAlignment.Center
local confirmText = label(confirmBox, "", 14, C_SUB)
confirmText.Position = UDim2.fromOffset(128, 48)
confirmText.Size = UDim2.new(1, -144, 0, 112)
confirmText.TextYAlignment = Enum.TextYAlignment.Top
local confirmCancel = button(confirmBox, "ConfirmCancel", tr("ยกเลิก", "Cancel"), C_BTN_OFF)
confirmCancel.Size = UDim2.new(0.5, -24, 0, 44)
confirmCancel.Position = UDim2.new(0, 16, 1, -58)
local confirmOk = button(confirmBox, "ConfirmOk", "", Color3.fromRGB(230, 80, 80))
confirmOk.Size = UDim2.new(0.5, -24, 0, 44)
confirmOk.Position = UDim2.new(0.5, 8, 1, -58)
-- ปุ่มที่สามตรงกลาง (เช่น 💰 ซื้อด้วยเหรียญ ผู้ใช้ขอ 2026-11-02) ซ่อนไว้ โชว์เมื่อ askConfirm ได้ alt = { text, color, onAlt }
local confirmAlt = button(confirmBox, "ConfirmAlt", "", Color3.fromRGB(235, 175, 55))
confirmAlt.Size = UDim2.new(1 / 3, -16, 0, 44)
confirmAlt.Position = UDim2.new(1 / 3, 8, 1, -58)
confirmAlt.Visible = false
-- ช่องกรอกจำนวน (ตอนเทลงราง ผู้ใช้ขอ 2026-10-28) ซ่อนไว้ โชว์เมื่อ askConfirm ได้ amount = { max, default }
local amountBox = Instance.new("TextBox")
amountBox.Name = "ConfirmAmount"
amountBox.Size = UDim2.new(1, -140, 0, 38) -- เว้น 12 จากปุ่ม Max (ผู้ใช้ส่งรูป: ชิดกัน)
amountBox.Position = UDim2.fromOffset(16, 118)
amountBox.BackgroundColor3 = Color3.new(1, 1, 1)
amountBox.TextColor3 = C_TEXT
amountBox.PlaceholderText = tr("จำนวนถุง", "Bags")
amountBox.Font = confirmText.Font
amountBox.TextSize = 18
amountBox.ClearTextOnFocus = false
amountBox.Visible = false
amountBox.Parent = confirmBox
Instance.new("UICorner", amountBox).CornerRadius = UDim.new(0, 10)
local amountStroke = Instance.new("UIStroke", amountBox)
amountStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
amountStroke.Color = C_HEAD
amountStroke.Thickness = 2
local amountMax = button(confirmBox, "ConfirmMax", tr("สูงสุด", "Max"), C_BTN)
amountMax.Size = UDim2.fromOffset(96, 38)
amountMax.Position = UDim2.new(1, -112, 0, 118)
amountMax.Visible = false
local amountLimit = 0
amountBox:GetPropertyChangedSignal("Text"):Connect(function()
	local digits = amountBox.Text:gsub("%D", "")
	if digits ~= amountBox.Text then amountBox.Text = digits end
	amountStroke.Color = C_HEAD
end)
amountMax.Activated:Connect(function() amountBox.Text = tostring(amountLimit) end)
-- ChickenGui ใช้ ZIndexBehavior Global: ของในกล่องต้อง ZIndex สูงกว่ากล่อง (21) ไม่งั้นโดนกล่องทับ ป๊อปอัพว่างเปล่า (ผู้ใช้ส่งรูป 2026-10-22)
local function raiseConfirm()
	for _, x in ipairs(confirmBox:GetDescendants()) do
		if x:IsA("GuiObject") then x.ZIndex = 22 end
	end
end
raiseConfirm()
local confirmAction = nil
local confirmAltAction = nil
local function hideConfirm()
	confirmDim.Visible = false
	confirmAction = nil
	confirmAltAction = nil
	amountBox:ReleaseFocus()
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(confirmDim) then GuiService.SelectedObject = nil end
end
-- c = ข้อมูลไก่ (Color/Mut) ไว้โชว์โมเดล · onOk = ทำเมื่อกดยืนยัน
-- amount = { max = สูงสุด, default = ค่าเริ่ม } = มีช่องกรอกจำนวน onOk(จำนวน)
local function askConfirm(c, chick, heading, desc, okText, okColor, onOk, amount, alt)
	local old = confirmBox:FindFirstChild("Model")
	if old then old:Destroy() end
	if c then chickenViewport(confirmBox, c, UDim2.fromOffset(16, 52), 100, chick) end
	-- ไม่มีรูปไก่ (เช่น นำอาหารออกจากราง) = ข้อความเต็มกล่อง
	confirmText.Position = UDim2.fromOffset(c and 128 or 16, 48)
	confirmText.Size = UDim2.new(1, c and -144 or -32, 0, amount and 64 or 112)
	amountBox.Visible, amountMax.Visible = amount ~= nil, amount ~= nil
	if amount then
		amountLimit = amount.max
		amountBox.Text = tostring(amount.default or amount.max)
		amountStroke.Color = C_HEAD
	end
	raiseConfirm()
	confirmTitle.Text = heading
	confirmText.Text = desc
	confirmOk.Text = okText
	confirmOk.BackgroundColor3 = okColor or Color3.fromRGB(230, 80, 80)
	confirmAction = onOk
	-- alt = 3 ปุ่มเท่ากัน (ยกเลิก | alt | ยืนยัน) · ไม่มี = 2 ปุ่มครึ่งกล่องเหมือนเดิม
	confirmAlt.Visible = alt ~= nil
	confirmAltAction = alt and alt.onAlt or nil
	if alt then
		confirmAlt.Text = alt.text
		confirmAlt.BackgroundColor3 = alt.color or Color3.fromRGB(235, 175, 55)
		confirmCancel.Size = UDim2.new(1 / 3, -16, 0, 44)
		confirmOk.Size = UDim2.new(1 / 3, -16, 0, 44)
		confirmOk.Position = UDim2.new(2 / 3, 0, 1, -58)
	else
		confirmCancel.Size = UDim2.new(0.5, -24, 0, 44)
		confirmOk.Size = UDim2.new(0.5, -24, 0, 44)
		confirmOk.Position = UDim2.new(0.5, 8, 1, -58)
	end
	confirmDim.Visible = true
	if UserInputService:GetLastInputType().Name:find("Gamepad") then GuiService.SelectedObject = confirmCancel end
end
confirmCancel.Activated:Connect(hideConfirm)
confirmDim.Activated:Connect(hideConfirm)
confirmOk.Activated:Connect(function()
	local action = confirmAction
	local n
	if amountBox.Visible then
		n = tonumber(amountBox.Text)
		if not n or n < 1 or n > amountLimit then
			amountStroke.Color = Color3.fromRGB(230, 80, 80) -- จำนวนไม่ถูก = กรอบแดง ไม่ปิดกล่อง
			if n and n > amountLimit then amountBox.Text = tostring(amountLimit) end
			return
		end
	end
	hideConfirm()
	if action then action(n) end
end)
confirmAlt.Activated:Connect(function()
	local action = confirmAltAction
	hideConfirm()
	if action then action() end
end)

-- กรอบสี + ป้ายใต้รูปตามสายพันธุ์ (2026-10-26; เดิม 2026-10-22 ตามระดับ) · คืนค่าระดับ ChickenConfig.ChickenTier ให้คนเรียกเหมือนเดิม
local RAINBOW_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 120)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 90)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 235, 110)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(120, 220, 140)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(110, 180, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 140, 255)),
})
local GENERAL_BREED = { Color = Color3.fromRGB(176, 158, 136) } -- สีกรอบสายพันธุ์ทั่วไป
local function tierFrame(f, c, pillPosition, pillWidth)
	local _, t = Config.ChickenTier({ speed = c.Speed, size = c.Size, gold = c.Gold, mut = c.Mut })
	-- กรอบแบ่งตามสายพันธุ์เท่านั้น ไม่ใช้สีระดับ (ผู้ใช้ขอ 2026-10-26 กันงง): สายพันธุ์พิเศษ = ChickenConfig.MUT_FRAME · ไม่มี = สายพันธุ์ "ทั่วไป" GENERAL_BREED
	local mutFrame = c.Mut and Config.MUT_FRAME and Config.MUT_FRAME[c.Mut]
	local frameColor = typeof(mutFrame) == "Color3" and mutFrame or GENERAL_BREED.Color
	local rainbowFrame = mutFrame == "rainbow"
	-- สายพันธุ์พิเศษ = กรอบหนากว่า + แสงฟุ้งสีสายพันธุ์รอบการ์ด + ป้ายใต้รูปเป็นชื่อสายพันธุ์สีเดียวกัน (ผู้ใช้ขอ 2026-10-26: แยกจากสีระดับให้ชัด)
	local breed = mutFrame ~= nil and Config.Mutations[c.Mut] or nil
	local s = f:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = frameColor
		s.Thickness = breed and 4.5 or 3
		if rainbowFrame then
			s.Color = Color3.new(1, 1, 1)
			Instance.new("UIGradient", s).Color = RAINBOW_SEQ
		end
	end
	if breed then
		-- แสงฟุ้ง: เฟรมใสขนาดเท่าการ์ด ใส่ UIStroke หนาโปร่ง วาดออกนอกขอบการ์ด (ไม่บังเนื้อหา ไม่รับการกด)
		local glow = Instance.new("Frame")
		glow.Name = "BreedGlow"
		glow.BackgroundTransparency = 1
		glow.Size = UDim2.fromScale(1, 1)
		glow.Active = false
		glow.Parent = f
		Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)
		local gs = Instance.new("UIStroke")
		gs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		gs.Color = rainbowFrame and Color3.new(1, 1, 1) or frameColor
		gs.Thickness = 8
		gs.Transparency = 0.65
		gs.Parent = glow
		if rainbowFrame then Instance.new("UIGradient", gs).Color = RAINBOW_SEQ end
	end
	f.BackgroundColor3 = Color3.new(1, 1, 1):Lerp(frameColor, breed and 0.12 or 0.08)
	local pill = Instance.new("TextLabel")
	pill.Name = "Tier"
	-- ป้ายใต้รูป = ชื่อระดับ + สีระดับเหมือนเดิม (ผู้ใช้ขอ 2026-10-26: เปลี่ยนแค่สีกรอบ)
	pill.Text = LANG == "th" and t.Th or t.En
	pill.Font = Enum.Font.GothamBold
	pill.TextSize = 12
	pill.TextScaled = true
	do
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 12
		cap.Parent = pill
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
		pad.Parent = pill
	end
	pill.TextColor3 = Color3.new(1, 1, 1)
	pill.TextStrokeTransparency = 0.6
	local pillRainbow = t.Rainbow
	pill.BackgroundColor3 = pillRainbow and Color3.new(1, 1, 1) or t.Color
	pill.Size = UDim2.fromOffset(pillWidth, 18)
	pill.Position = pillPosition
	pill.ZIndex = 3 -- ทับขอบล่างรูปไก่ (ZIndexBehavior Global)
	pill.Parent = f
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
	if pillRainbow then Instance.new("UIGradient", pill).Color = RAINBOW_SEQ end
	return t
end

-- รายละเอียดไก่ในป๊อปอัพ: ดาว 3 ค่า + กลายพันธุ์
-- ไก่ตัวนี้เป็นพ่อ/แม่ของไข่ผสมที่ยังฟักอยู่ไหม (ผู้ใช้ขอ 2026-10-27: บอกว่าตัวไหนกำลังผสมพันธุ์)
local function isBreeding(id)
	local inc = info and info.Incubator
	if not inc or (inc.ReadyIn or 0) <= 0 or not inc.Parents then return false end
	return table.find(inc.Parents, tostring(id)) ~= nil
end

-- ชื่อสั้นของไก่จาก id ("ไก่ดำ #6") ใช้บนการ์ดตู้ฟัก
local function chickenName(id)
	for _, c in ipairs(info.Chickens or {}) do
		if tostring(c.Id) == tostring(id) then
			local col = Config.Colors[c.Color] or Config.Colors.White
			return tr("ไก่", "") .. (LANG == "th" and col.Th or col.En) .. " #" .. c.Id
		end
	end
	return "#" .. tostring(id)
end

local function chickenLines(c)
	local mutText = Config.MutationLabel(c.Mut, LANG == "th")
	return string.format("%s %s\n%s %s\n%s %s", tr("ไข่เร็ว", "Speed"), stars(c.Speed), tr("ไข่ใหญ่", "Size"), stars(c.Size), tr("ไข่ทอง", "Gold"), stars(c.Gold))
		.. (mutText and ("\n" .. mutText) or "")
end

local function renderChickens()
	local grid = Instance.new("UIGridLayout", body)
	grid.CellSize = UDim2.new(1 / 3, -10, 0, 184) -- สูงขึ้นให้มีแถวปุ่มประกวด/ปลดเกษียณ (ช่วงที่ 6)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	-- เว้นขอบให้กรอบสีระดับ (หนา 3 วาดนอกการ์ด) ไม่โดนกรอบเลื่อนตัด (ผู้ใช้ส่งรูป 2026-10-22: กรอบดูขาดๆ)
	local pad = Instance.new("UIPadding", body)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 5), UDim.new(0, 8)
	fitCanvas(grid, 18)
	-- 🧹 การ์ดความสะอาดเล้า ช่องแรก (2026-10-23) หยิบไม้กวาดข้างเล้าแล้วเดินกวาดกองดิน
	if info.Dirt and #(info.Chickens or {}) > 0 then
		local dirt = info.Dirt
		local slowed = (info.DirtSlow or 1) > 1.001
		local f = card(body, "CoopDirt", 0)
		local h = label(f, tr("🧹 ความสะอาดเล้า", "🧹 Coop cleanliness"), 15, C_TEXT, true)
		h.Position = UDim2.fromOffset(12, 8)
		h.Size = UDim2.new(1, -24, 0, 26)
		local big = label(f, (100 - dirt) .. "%", 30, slowed and Color3.fromRGB(200, 90, 60) or Color3.fromRGB(80, 170, 90), true)
		big.Position = UDim2.fromOffset(12, 36)
		big.Size = UDim2.new(1, -24, 0, 36)
		local barBg = Instance.new("Frame")
		barBg.BackgroundColor3 = Color3.fromRGB(235, 225, 215)
		barBg.BorderSizePixel = 0
		barBg.Position = UDim2.fromOffset(12, 76)
		barBg.Size = UDim2.new(1, -24, 0, 12)
		barBg.Parent = f
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = slowed and Color3.fromRGB(230, 120, 80) or Color3.fromRGB(110, 200, 120)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromScale(math.clamp((100 - dirt) / 100, 0, 1), 1)
		bar.Parent = barBg
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local note
		if slowed then
			note = string.format(tr("⚠ เล้าสกปรก ไข่ออกช้าลง x%.2f", "⚠ Dirty coop: eggs x%.2f slower"), info.DirtSlow)
		elseif dirt >= (info.CleanMin or 5) then
			note = string.format(tr("สกปรกเกิน %d%% ไข่จะออกช้าลง", "Over %d%% dirty, eggs slow down"), info.DirtFree or 50)
		else
			note = tr("✨ สะอาดดี ไข่ออกปกติ", "✨ Clean, eggs at full speed")
		end
		if dirt >= (info.CleanMin or 5) then
			note ..= tr("\n🧹 หยิบไม้กวาดข้างเล้า (E) แล้วเดินกวาดกองดินในลาน ได้ +", "\n🧹 Grab the broom by the coop (E) and sweep the dirt piles: +") .. fmtNum(info.CleanReward or 0) .. tr(" เหรียญ", " coins")
		end
		local d = label(f, note, 13, C_SUB)
		d.Position = UDim2.fromOffset(12, 96)
		d.Size = UDim2.new(1, -24, 0, 80)
		d.TextYAlignment = Enum.TextYAlignment.Top
	end
	local waiting = (info.FoodEggsLeft or 0) <= 0
	local full = (info.Basket and info.Basket.Count or 0) >= (info.BasketCap or math.huge)
	for i, c in ipairs(info.Chickens or {}) do
		local col = Config.Colors[c.Color] or Config.Colors.White
		local f = card(body, "Chicken_" .. c.Id, i)
		local chick = (c.GrowIn or 0) > 0
		chickenViewport(f, c, UDim2.new(1, -86, 0, 40), 76, chick)
		tierFrame(f, c, UDim2.new(1, -86, 0, 100), 76)
		local name = label(f, (chick and "🐣 " or "") .. tr((chick and "ลูกไก่" or "ไก่") .. col.Th, col.En .. (chick and " chick" or " chicken")) .. "  #" .. c.Id, 15, C_TEXT, true)
		name.Position = UDim2.fromOffset(12, 8)
		name.Size = UDim2.new(1, -60, 0, 30)
		-- ⭐ ตั้งไก่โชว์ที่ลานโชว์ (ช่วงที่ 4) ได้ 1 ตัว กดซ้ำ = เอาลง
		local isShow = info.Showcase == c.Id
		local showBtn = button(f, "Show_" .. c.Id, isShow and "⭐" or "☆", isShow and Color3.fromRGB(255, 190, 40) or C_BTN_OFF)
		showBtn.Size = UDim2.fromOffset(34, 28)
		showBtn.Position = UDim2.new(1, -42, 0, 8)
		showBtn.TextSize = 18
		showBtn.Activated:Connect(function()
			if chick then
				setStatus(tr("ลูกไก่ยังขึ้นโชว์ไม่ได้ รอโตก่อน", "Chicks can't be shown yet"), false)
				return
			end
			send("showcase", c.Id)
		end)
		local extra = {}
		local mutText = Config.MutationLabel(c.Mut, LANG == "th")
		if mutText then table.insert(extra, mutText) end
		if isBreeding(c.Id) then table.insert(extra, tr("🥚 กำลังผสมพันธุ์", "🥚 Breeding"))
		elseif (c.RestIn or 0) > 0 then table.insert(extra, tr("💤 พักหลังผสม", "💤 Resting")) end
		-- รุ่น (gen) ซ่อนแล้ว 2026-10-26 (ผู้ใช้สั่ง: ไม่มีผลกับการผสมพันธุ์ เลยไม่ต้องโชว์) ข้อมูลยังเก็บอยู่
		local lines = label(f, string.format("%s %s\n%s %s\n%s %s\n%s",
			tr("ไข่เร็ว", "Speed"), stars(c.Speed), tr("ไข่ใหญ่", "Size"), stars(c.Size), tr("ไข่ทอง", "Gold"), stars(c.Gold), table.concat(extra, " · ")), 13, C_SUB)
		lines.Position = UDim2.fromOffset(12, 40)
		lines.Size = UDim2.new(1, -100, 0, 66)
		lines.TextYAlignment = Enum.TextYAlignment.Top
		local timer = label(f, "", 13, C_TEXT, true)
		timer.Position = UDim2.fromOffset(12, 116)
		timer.Size = UDim2.new(0.6, -12, 0, 26)
		if chick then
			table.insert(timerLabels, { label = timer, left = c.GrowIn, prefix = tr("🐣 โตใน ", "🐣 Grows in "), done = tr("🐔 โตแล้ว!", "🐔 Grown!") })
		elseif full then
			timer.Text = tr("🥚 แผงไข่เต็ม", "🥚 Tray full")
		elseif waiting then
			timer.Text = tr("🥣 รออาหาร", "🥣 Needs food")
		else
			table.insert(timerLabels, { label = timer, left = c.NextEggIn })
		end
		local sellPrice = c.SellPrice or info.ChickenSellPrice or 0 -- ราคาตามระดับไก่ (2026-10-25)
		local sell = button(f, "Sell_" .. c.Id, tr("ขาย ", "Sell ") .. fmtNum(sellPrice), C_SELL)
		sell.Size = UDim2.new(0.4, -10, 0, 26)
		sell.Position = UDim2.new(0.6, 0, 0, 116)
		sell.TextSize = 13
		sell.Activated:Connect(function()
			local notes = {}
			if c.Mut then table.insert(notes, tr("⚠ ไก่สายพันธุ์หายาก!", "⚠ Mutated — rare!")) end
			if info.Showcase == c.Id then table.insert(notes, tr("⚠ ตัวนี้โชว์อยู่ที่ลานโชว์", "⚠ On the show yard")) end
			if info.Contest and info.Contest.EntryId == c.Id then table.insert(notes, tr("⚠ ส่งประกวดอยู่ ขายแล้วจะถูกถอนออกจากประกวด", "⚠ Entered in the contest — selling withdraws it")) end
			if Config.CanRetire({ speed = c.Speed, size = c.Size, gold = c.Gold }) then table.insert(notes, tr("⚠ ปลดเกษียณเข้าหอเกียรติยศได้", "⚠ Could join the Hall of Fame")) end
			askConfirm(c, chick, tr("💰 ขายไก่ตัวนี้?", "💰 Sell this chicken?"),
				tr("ไก่", "") .. tr(col.Th, col.En .. " chicken") .. "  #" .. c.Id .. "\n" .. chickenLines(c)
					.. (#notes > 0 and ("\n" .. table.concat(notes, "\n")) or "") .. tr("\nขายแล้วเอาคืนไม่ได้", "\nThis can't be undone"),
				"💰 " .. tr("ขาย ", "Sell ") .. fmtNum(sellPrice), Color3.fromRGB(230, 80, 80),
				function() send("sellChicken", c.Id) end)
		end)
		-- ช่วงที่ 6: 🏆 ส่งประกวด · 🏛 ปลดเกษียณ (เฉพาะไก่โต 5 ดาวครบ 3 ค่า)
		local entered = info.Contest and info.Contest.EntryId == c.Id
		local enter = button(f, "Contest_" .. c.Id, entered and tr("🏆 ส่งอยู่", "🏆 Entered") or tr("🏆 ส่งประกวด", "🏆 Enter contest"),
			entered and Color3.fromRGB(255, 190, 40) or (chick and C_BTN_OFF or Color3.fromRGB(150, 140, 230)))
		enter.Size = UDim2.new(0.5, -14, 0, 26)
		enter.Position = UDim2.fromOffset(10, 150)
		enter.TextSize = 13
		enter.Activated:Connect(function()
			if chick then setStatus(tr("ลูกไก่ยังส่งประกวดไม่ได้ รอให้โตก่อน", "Chicks can't enter yet"), false) return end
			send("contestEnter", c.Id)
		end)
		-- ปุ่มปลดเกษียณขึ้นเฉพาะไก่โตที่ครบ 5/5/5 (ผู้ใช้สั่ง 2026-10-28 เอาปุ่มสีเทาของตัวที่ยังไม่ครบออก)
		local canRetire = Config.CanRetire({ speed = c.Speed, size = c.Size, gold = c.Gold })
		if not chick and canRetire then
			local retire = button(f, "Retire_" .. c.Id, tr("🏛 ปลดเกษียณ", "🏛 Retire"), Color3.fromRGB(200, 160, 90))
			retire.Size = UDim2.new(0.5, -10, 0, 26)
			retire.Position = UDim2.new(0.5, 0, 0, 150)
			retire.TextSize = 13
			retire.Activated:Connect(function()
				local step = math.floor((info.HallStep or 0.02) * 100 + 0.5)
				askConfirm(c, false, tr("🏛 ปลดเกษียณไก่ตัวนี้?", "🏛 Retire this chicken?"),
					tr("ไก่", "") .. tr(col.Th, col.En .. " chicken") .. "  #" .. c.Id .. "\n" .. chickenLines(c)
						.. tr("\nไก่จะออกจากเล้าไปอยู่หอเกียรติยศ ไข่ขายได้ +", "\nIt leaves the coop for the Hall of Fame: eggs sell for +") .. step .. tr("% ถาวร", "% forever")
						.. (entered and tr("\n⚠ ส่งประกวดอยู่ จะถูกถอนออกจากประกวด", "\n⚠ Entered in the contest — retiring withdraws it") or ""),
					tr("🏛 ปลดเกษียณ", "🏛 Retire"), Color3.fromRGB(200, 160, 90),
					function() send("retire", c.Id) end)
			end)
		end
	end
	for s = #(info.Chickens or {}) + 1, info.Slots or 0 do
		local f = card(body, "Empty_" .. s, s)
		f.BackgroundTransparency = 0.4
		local l = label(f, tr("ช่องว่าง\nซื้อไก่ได้ที่ 🐔 ลุงไข่ขายไก่\nหน้าประตูลาน", "Empty slot\nBuy chickens from\n🐔 the Chicken Merchant"), 14, C_SUB)
		l.Size = UDim2.fromScale(1, 1)
		l.TextXAlignment = Enum.TextXAlignment.Center
	end
end

local function bigCard(order, name, heading, desc, btnText, enabled, onClick, height)
	local f = card(body, name, order)
	f.Size = UDim2.new(1, -8, 0, height or 96)
	local h = label(f, heading, 18, C_TEXT, true)
	h.Position = UDim2.fromOffset(16, 10)
	h.Size = UDim2.new(1, -220, 0, 28)
	local d = label(f, desc, 14, C_SUB)
	d.Position = UDim2.fromOffset(16, 40)
	d.Size = UDim2.new(1, btnText and -220 or -32, 0, (height or 96) - 48)
	d.TextYAlignment = Enum.TextYAlignment.Top
	if btnText then
		local b = button(f, name .. "Button", btnText, enabled and C_BTN or C_BTN_OFF)
		b.Size = UDim2.fromOffset(180, 44)
		b.Position = UDim2.new(1, -196, 0.5, -22)
		b.Activated:Connect(onClick)
	end
	return f
end

local function listLayout()
	local layout = Instance.new("UIListLayout", body)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	-- เว้นขอบให้กรอบสีระดับ (เช่น การ์ดลูกไก่ที่ตู้ฟัก) ไม่โดนกรอบเลื่อนตัด เหมือนหน้าไก่ของฉัน (2026-10-22)
	local pad = Instance.new("UIPadding", body)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 5), UDim.new(0, 2)
	fitCanvas(layout, 18)
end

local function renderShop()
	listLayout()
	local count = #(info.Chickens or {})
	local free = (info.Slots or 0) - count
	bigCard(1, "BuyChicken", tr("🐔 ไก่ 1 ตัว", "🐔 One chicken"),
		tr("ดาวสุ่ม 1–2 ทุกความสามารถ · สีขาว/น้ำตาล/ดำ\nช่องว่าง ", "Random 1–2 stars on every ability · white/brown/black\nFree slots ") .. free,
		"💰 " .. fmtNum(info.ChickenPrice), free > 0, function() send("buyChicken") end)
	local price = info.SlotPrice
	bigCard(2, "BuySlot", tr("🏠 ช่องเลี้ยงไก่ +1", "🏠 Coop slot +1"),
		tr("ตอนนี้ ", "Now ") .. (info.Slots or 0) .. " / " .. (info.MaxSlots or 10) .. tr(" ช่อง", " slots"),
		price and ("💰 " .. fmtNum(price)) or tr("เต็มแล้ว", "Maxed"), price ~= nil, function() if price then send("buySlot") end end)
	-- ช่วงที่ 5: อัปเกรดด้วยเหรียญ
	local UNIT = { hatch = { tr(" นาที", " min"), 60 }, basket = { tr(" ฟอง", " eggs"), 1 }, trough = { tr(" ถุง", " bags"), 1 } }
	for i, u in ipairs(info.Upgrades or {}) do
		local cfg = Config.UPGRADES[u.Id]
		local unit = UNIT[u.Id] or { "", 1 }
		local now = fmtNum(u.Value / unit[2]) .. unit[1]
		local desc = u.NextValue and (tr("ตอนนี้ ", "Now ") .. now .. "  →  " .. fmtNum(u.NextValue / unit[2]) .. unit[1]) or (tr("ตอนนี้ ", "Now ") .. now .. tr(" (สูงสุด)", " (max)"))
		local btnText, enabled, action
		if not u.NextValue then
			btnText, enabled, action = tr("✔ สูงสุด", "✔ Maxed"), false, function() end
		elseif u.RobuxOnly then
			-- แผงเก็บไข่: Robux เท่านั้น (Developer Product ซื้อ 1 ครั้ง = +1 ขั้น)
			local productId = info.Ids and info.Ids.Tray or 0
			if productId > 0 then
				btnText, enabled = "R$ " .. tostring(info.PriceHint and info.PriceHint.eggTray or ""), true
				action = function() MarketplaceService:PromptProductPurchase(player, productId) end
			else
				btnText, enabled, action = tr("เร็วๆ นี้", "Coming soon"), false, function() end
			end
			desc = desc .. tr("\nขยายด้วย Robux เท่านั้น", "\nRobux only")
		else
			btnText, enabled = "💰 " .. fmtNum(u.NextCost), true
			action = function() send("upgrade", u.Id) end
		end
		local card = bigCard(2 + i, "Upgrade_" .. u.Id, cfg.Icon .. " " .. (LANG == "th" and cfg.Th or cfg.En) .. "  Lv " .. u.Level .. "/" .. u.MaxLevel, desc, btnText, enabled, action)
		if u.RobuxOnly then card.BackgroundColor3 = Color3.fromRGB(255, 248, 225) end
	end
	-- ช่วงที่ 5: ของ Robux (Game Pass) มีแล้ว = ปุ่มเปิด/ปิด · ยังไม่มี = ซื้อ · ยังไม่ตั้ง ID = เร็วๆ นี้
	local passes, ids, hint = info.Passes or {}, info.Ids or {}, info.PriceHint or {}
	local function passCard(order, key, idKey, onKey, heading, desc, hintKey, height, extra)
		local owned = passes[key] == true
		local on = info[onKey] ~= false
		local passId = ids[idKey] or 0
		local text, enabled, action
		if owned then
			text, enabled = on and tr("✅ เปิดอยู่", "✅ On") or tr("⏸ ปิดอยู่", "⏸ Off"), true
			action = function() send("toggle", key == "Feed" and "feed" or "sell") end
		elseif passId > 0 then
			text, enabled = "R$ " .. tostring(hint[hintKey] or ""), true
			action = function() MarketplaceService:PromptGamePassPurchase(player, passId) end
		else
			text, enabled = tr("เร็วๆ นี้", "Coming soon"), false
			action = function() end
		end
		local f = bigCard(order, "Pass_" .. key, heading, desc, text, enabled, action, height)
		f.BackgroundColor3 = Color3.fromRGB(255, 248, 225)
		if extra then extra(f, owned) end
	end
	-- 🧹 ทำความสะอาดอัตโนมัติ (มากับ Game Pass ให้อาหาร 2026-10-28): ปุ่มใต้ปุ่มหลัก กดวน 30 → 50 → 70 → 90 → ปิด
	local function cleanControl(f, owned)
		if not owned then return end
		local main = f:FindFirstChild("Pass_FeedButton")
		if main then main.Position = UDim2.new(1, -196, 0, 14) end
		local steps = info.AutoCleanSteps or { 30, 50, 70, 90, 0 }
		local at = info.AutoCleanAt or 50
		local b = button(f, "AutoCleanButton", at > 0 and (tr("🧹 สกปรก ", "🧹 At ") .. at .. tr("% = กวาด", "% dirty")) or tr("🧹 ปิดอยู่", "🧹 Off"),
			at > 0 and Color3.fromRGB(110, 190, 230) or C_BTN_OFF)
		b.Size = UDim2.fromOffset(180, 40)
		b.Position = UDim2.new(1, -196, 0, 66)
		b.TextSize = 14
		b.Activated:Connect(function()
			local i = table.find(steps, at) or 0
			lastSelectedName = b.Name
			send("autoClean", steps[i % #steps + 1])
		end)
		-- 🥫 กระเป๋าไม่มีถุง = ดึงจากเครื่องทำอาหารสัตว์ เปิด/ปิดได้ (2026-11-05)
		local machineOn = info.AutoFeedMachine ~= false
		local m = button(f, "AutoFeedMachineButton", machineOn and tr("🥫 ดึงจากเครื่อง: เปิด", "🥫 From maker: On") or tr("🥫 ดึงจากเครื่อง: ปิด", "🥫 From maker: Off"),
			machineOn and Color3.fromRGB(110, 190, 230) or C_BTN_OFF)
		m.Size = UDim2.fromOffset(180, 40)
		m.Position = UDim2.new(1, -196, 0, 112)
		m.TextSize = 14
		m.Activated:Connect(function()
			lastSelectedName = m.Name
			send("toggle", "machine")
		end)
	end
	passCard(6, "Feed", "Feed", "AutoFeedOn", tr("🤖 ให้อาหารไก่อัตโนมัติ + 🧹 ทำความสะอาด", "🤖 Auto-feed + 🧹 auto-clean"),
		tr("รางเหลือน้อยกว่า 20% เทถุงอาหารสัตว์จากกระเป๋าให้เอง กระเป๋าไม่มีก็ดึงจากเครื่องทำอาหารสัตว์\n🧹 เล้าสกปรกถึง % ที่ตั้ง = สะอาดเอง แม้ออกเกม (ไม่ได้เหรียญ กวาดเองยังได้เหรียญ) · Game Pass ถาวร",
			"Tops up the trough from your bag when it drops below 20%, or from the pet food maker if your bag has none\n🧹 Cleans the coop when it hits your chosen %, even offline (no coins — sweep yourself for coins) · permanent Game Pass"),
		"autoFeed", passes.Feed == true and 166 or 136, cleanControl)
	if info.AutoSellEnabled then passCard(7, "Sell", "Sell", "AutoSellOn", tr("💰 ขายไข่อัตโนมัติ", "💰 Auto-sell eggs"),
		tr("แผงไข่เกือบเต็ม (90%) ขายให้เอง ไก่ไม่หยุดออกไข่ (Game Pass ถาวร)", "Sells eggs when the egg tray is 90% full so chickens never stop (permanent Game Pass)"), "autoSell") end -- ปิดไว้ก่อน (ChickenConfig.AUTO_SELL_ENABLED)
	-- 🎁 ส่งให้เพื่อน (2026-10-23): เปิดหน้าเลือกเพื่อนของ VipGui (OpenChickenGift) · เกมจริงแสดงเมื่อตั้ง ID สินค้าแล้ว (Studio แสดงเสมอ กดส่ง = จำลอง)
	local giftIds = info.GiftIds or {}
	local function giftCard(order, which, idKey, heading, desc)
		if (giftIds[idKey] or 0) == 0 and not RunService:IsStudio() then return end
		local f = bigCard(order, "Gift_" .. idKey, heading, desc, "🎁 " .. tr("ส่งให้เพื่อน", "Gift a friend"), true, function() -- ราคาจริงขึ้นที่หน้าเลือกเพื่อน (GetProductInfo)
			local vip = player.PlayerGui:FindFirstChild("VipGui")
			local openGift = vip and vip:FindFirstChild("OpenChickenGift")
			if not openGift then setStatus(tr("เปิดหน้าส่งของขวัญไม่ได้ ลองใหม่อีกครั้ง", "Couldn't open the gift page, try again"), false) return end
			hideConfirm()
			gui.Enabled = false -- ปิดหน้าต่างไก่ ให้หน้าเลือกเพื่อนอยู่บนสุด
			if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject = nil end
			openGift:Fire(which)
		end)
		f.BackgroundColor3 = Color3.fromRGB(255, 236, 244)
	end
	giftCard(8, "feed", "Feed", tr("🎁 ส่งให้อาหารไก่อัตโนมัติให้เพื่อน", "🎁 Gift Auto-feed to a friend"),
		tr("เพื่อนได้สิทธิ์ถาวรเหมือนซื้อ Game Pass เอง · เลือกเพื่อนที่อยู่ในเซิร์ฟนี้", "Your friend gets it forever, same as the Game Pass · pick a friend in this server"))
	giftCard(9, "hatch", "Hatch", tr("🎁 ส่งคูปองฟักทันทีให้เพื่อน", "🎁 Gift an instant-hatch coupon"),
		tr("เพื่อนได้คูปอง ⚡ 1 ใบ ใช้ฟักไข่ในตู้ฟักได้ทันที · ส่งซ้ำได้", "Your friend gets 1 ⚡ coupon to hatch an incubator egg instantly · can gift again"))
	bigCard(10, "Tip", tr("💡 เลี้ยงไก่ยังไง", "💡 How it works"),
		tr("เดินเข้าลาน → 🥣 รางอาหาร: เติมถุงอาหารสัตว์ → ไก่ออกไข่เอง (แม้ออกเกม)\n🥚 แผงเก็บไข่ข้างเล้า: ขายไข่ · อาหารดาวสูง = ไข่แพงขึ้น", "In the yard → 🥣 Feed trough: add pet food → chickens lay eggs (even offline)\n🥚 Egg tray by the coop: sell eggs · better food = pricier eggs"), nil, nil, nil, 110)
end

local function renderTrough()
	listLayout()
	local t = info.Trough or {}
	local parts = {}
	for s = 5, 1, -1 do
		if (t[s] or 0) > 0 then table.insert(parts, string.rep("⭐", s) .. " x" .. t[s]) end
	end
	-- นำถุงออกจากรางคืนกระเป๋า (ผู้ใช้ขอ 2026-10-28) เฉพาะทั้งหมด (ตามดาวเอาออกตามที่ผู้ใช้สั่ง) · ถุงที่ไก่เปิดกินอยู่ไม่นับ (อยู่ในรางต่อ)
	local function askWithdraw(s, n)
		local left = (info.TroughBags or 0) - n
		local feedOn = info.Passes and info.Passes.Feed and info.AutoFeedOn ~= false
		askConfirm(nil, false, tr("🥣 นำอาหารออกจากราง?", "🥣 Take food out of the trough?"),
			(s > 0 and (string.rep("⭐", s) .. " x" .. n) or (tr("ทุกดาว ", "All stars ") .. n .. tr(" ถุง", " bags")))
				.. tr(" กลับไปอยู่ในกระเป๋า\nรางเหลือ ", " go back to your bag\nTrough left: ") .. left .. tr(" ถุง", " bags")
				.. (left <= 0 and (info.FoodEggsLeft or 0) - n * (info.EggsPerBag or 5) <= 0 and tr(" · ไก่จะหยุดออกไข่", " · chickens will stop laying") or "")
				.. (feedOn and tr("\n⚠ จะปิดให้อาหารอัตโนมัติให้ ไม่งั้นระบบจะเทถุงกลับลงราง", "\n⚠ Auto-feed will be turned off, or it would pour the bags back in") or ""),
			tr("นำออก", "Take out"), Color3.fromRGB(230, 140, 80),
			function() send("withdraw", s) end)
	end
	local inTrough = info.TroughBags or 0
	bigCard(1, "TroughNow", tr("🥣 ในราง ", "🥣 In the trough ") .. inTrough .. " / " .. (info.TroughCap or 100) .. tr(" ถุง", " bags"),
		(#parts > 0 and table.concat(parts, "   ") or tr("รางว่าง ไก่ไม่ออกไข่", "Empty — chickens won't lay")) .. "\n" ..
		tr("พอสำหรับไข่อีก ", "Enough for ") .. (info.FoodEggsLeft or 0) .. tr(" ฟอง (กินดาวสูงก่อน)", " more eggs (best food first)"),
		tr("นำออกทั้งหมด", "Take all out"), inTrough > 0, function() if inTrough > 0 then askWithdraw(0, inTrough) end end)
	local bag = info.InBag or {}
	local total = 0
	for s = 1, 5 do total += bag[s] or 0 end
	bigCard(2, "DepositAll", tr("🎒 ถุงอาหารในกระเป๋า ", "🎒 Food bags in your bag ") .. total,
		tr("ทำถุงอาหารได้ที่เครื่องทำอาหารสัตว์ (ผัก 2 ชิ้น = 1 ถุง)", "Make bags at the pet food maker (2 produce = 1 bag)"),
		tr("เททั้งหมด", "Add all"), total > 0, function() send("deposit", 0) end)
	for s = 5, 1, -1 do
		local n = bag[s] or 0
		if n > 0 then
			bigCard(10 - s, "Deposit" .. s, string.rep("⭐", s) .. tr(" ถุงอาหาร x", " food x") .. n,
				tr("ไข่จากอาหารนี้ ฟองละ ", "Eggs from this food sell for ") .. Config.EGG_PRICE[s] .. tr("+ เหรียญ", "+ coins each"),
				tr("เทลงราง", "Add"), true, function()
					local space = (info.TroughCap or 100) - (info.TroughBags or 0)
					local max = math.min(n, space)
					if max <= 0 then send("deposit", s) return end -- รางเต็ม ให้เซิร์ฟบอก
					askConfirm(nil, false, tr("🥣 เทลงรางกี่ถุง?", "🥣 How many bags?"),
						string.rep("⭐", s) .. tr(" ในกระเป๋า ", " in your bag: ") .. n .. tr(" ถุง\nรางรับได้อีก ", " bags\nTrough has room for ") .. space .. tr(" ถุง", " bags"),
						tr("เทลงราง", "Add"), C_BTN, function(amt) send("deposit", { s, amt }) end,
						{ max = max, default = max })
				end)
		end
	end
end

local function renderBasket()
	listLayout()
	local b = info.Basket or { Eggs = {}, Gold = 0, Value = 0, Count = 0 }
	local parts = {}
	for s = 5, 1, -1 do
		if (b.Eggs[s] or 0) > 0 then table.insert(parts, "🥚" .. string.rep("⭐", s) .. " x" .. b.Eggs[s]) end
	end
	if (b.Gold or 0) > 0 then table.insert(parts, tr("🟡 ไข่ทอง x", "🟡 Golden x") .. b.Gold) end
	bigCard(1, "BasketNow", tr("🥚 ไข่บนแผง ", "🥚 Eggs on tray ") .. (b.Count or 0) .. " / " .. (info.BasketCap or 500),
		#parts > 0 and table.concat(parts, "   ") or tr("ยังไม่มีไข่ เติมอาหารแล้วรอสักครู่", "No eggs yet — add food and wait a bit"),
		tr("ขาย 💰 ", "Sell 💰 ") .. fmtNum(b.Value or 0), (b.Count or 0) > 0, function() send("sellEggs") end)
	local st = info.Stats or {}
	bigCard(2, "Stats", tr("📊 สถิติ", "📊 Stats"),
		tr("ไข่ทั้งหมด ", "Eggs laid ") .. fmtNum(st.eggs or 0) .. tr(" ฟอง · ขายแล้ว ", " · sold ") .. fmtNum(st.sold or 0) .. tr(" ฟอง · ได้ ", " · earned ") .. fmtNum(st.coins or 0) .. tr(" เหรียญ", " coins"))
end

-- ============ ตู้ฟักไข่ · ผสมพันธุ์ (ช่วงที่ 3) ============
local function renderBreed()
	-- 2026-10-22 ตู้ฟักใช้ได้ตั้งแต่เลเวลพื้นฐาน (ฟักไข่จากแผง) ส่วนผสมพันธุ์ยังล็อกที่ BreedLevel
	listLayout()
	-- ตู้ฟัก
	local inc = info.Incubator
	if inc and inc.ReadyIn <= 0 and inc.Child then
		-- ฟักแล้ว: โชว์ลูกไก่ (สี ดาว กลายพันธุ์ ช่องสมุดใหม่ไหม) ให้เลือกรับเข้าเล้าหรือขายทันที (ผู้ใช้ขอ 2026-10-22)
		local ch = inc.Child
		local col = Config.Colors[ch.Color] or Config.Colors.White
		local mutText = Config.MutationLabel(ch.Mut, LANG == "th")
		local f = card(body, "Hatch", 1)
		f.Size = UDim2.new(1, -8, 0, 156)
		chickenViewport(f, ch, UDim2.fromOffset(12, 12), 104, true)
		tierFrame(f, ch, UDim2.fromOffset(12, 124), 104)
		local h = label(f, tr("🐣 ไข่ฟักแล้ว! ได้ลูกไก่", "🐣 Hatched! A ") .. tr(col.Th, col.En .. " chick") .. (mutText and ("  " .. mutText) or ""), 18, C_TEXT, true)
		h.Position = UDim2.fromOffset(128, 10)
		h.Size = UDim2.new(1, -140, 0, 26)
		local tags = {}
		if ch.IsNew then table.insert(tags, tr("📖 สมุดช่องใหม่!", "📖 New book entry!")) end
	if ch.CanRetire then table.insert(tags, tr("🏛 ปลดเกษียณเข้าหอเกียรติยศได้", "🏛 Can join the Hall of Fame")) end
		local d = label(f, string.format("%s %s   %s %s   %s %s\n%s",
			tr("ไข่เร็ว", "Speed"), stars(ch.Speed), tr("ไข่ใหญ่", "Size"), stars(ch.Size), tr("ไข่ทอง", "Gold"), stars(ch.Gold),
			#tags > 0 and table.concat(tags, "  ·  ") or tr("ลูกไก่โตใน ", "Grows up in ") .. (info.GrowMinutes or 60) .. tr(" นาทีหลังรับเข้าเล้า", " min after it joins the coop")), 14, C_SUB)
		d.Position = UDim2.fromOffset(128, 40)
		d.Size = UDim2.new(1, -140, 0, 48)
		d.TextYAlignment = Enum.TextYAlignment.Top
		local full = #(info.Chickens or {}) >= (info.Slots or 0)
		local take = button(f, "TakeChick", full and tr("🐣 เล้าเต็ม", "🐣 Coop full") or tr("🐣 รับเข้าเล้า", "🐣 Take to coop"), full and C_BTN_OFF or C_BTN)
		take.Size = UDim2.new(0.5, -76, 0, 40)
		take.Position = UDim2.fromOffset(128, 104)
		take.TextSize = 15
		take.Activated:Connect(function()
			if full then setStatus(tr("เล้าเต็ม ขายไก่ตัวอื่นหรือซื้อช่องเพิ่มก่อน (หรือขายลูกตัวนี้)", "Coop is full — sell a chicken or buy a slot first (or sell this chick)"), false) return end
			send("hatch")
		end)
		local sell = button(f, "SellChick", "💰 " .. tr("ขาย ", "Sell ") .. fmtNum(info.HatchSellPrice or 0), C_SELL)
		sell.Size = UDim2.new(0.5, -76, 0, 40)
		sell.Position = UDim2.new(0.5, 60, 0, 104)
		sell.TextSize = 15
		sell.Activated:Connect(function()
			local notes = {}
			if ch.Mut then table.insert(notes, tr("⚠ ลูกไก่สายพันธุ์หายาก!", "⚠ Mutated — rare!")) end
			if ch.CanRetire then table.insert(notes, tr("⚠ ปลดเกษียณเข้าหอเกียรติยศได้", "⚠ Could join the Hall of Fame")) end
			askConfirm(ch, true, tr("💰 ขายลูกไก่ตัวนี้?", "💰 Sell this chick?"),
				tr("ลูกไก่", "") .. tr(col.Th, col.En .. " chick") .. "\n" .. chickenLines(ch)
					.. (#notes > 0 and ("\n" .. table.concat(notes, "\n")) or "") .. tr("\nขายแล้วเอาคืนไม่ได้ (ยังนับเข้าสมุดไก่)", "\nThis can't be undone (still counts for the book)"),
				"💰 " .. tr("ขาย ", "Sell ") .. fmtNum(info.HatchSellPrice or 0), Color3.fromRGB(230, 80, 80),
				function() send("sellHatch") end)
		end)
	elseif inc and inc.ReadyIn <= 0 then
		bigCard(1, "Hatch", tr("🐣 ไข่ฟักแล้ว!", "🐣 The egg hatched!"),
			tr("กดรับลูกไก่เข้าเล้า (ต้องมีช่องว่าง) ลูกไก่โตใน ", "Take the chick to the coop (needs a free slot). Chicks grow in ") .. (info.GrowMinutes or 60) .. tr(" นาที", " min"),
			tr("🐣 รับลูกไก่", "🐣 Take chick"), true, function() send("hatch") end)
	elseif inc then
		local parentsText = ""
		if not inc.FromEgg and inc.Parents and #inc.Parents > 0 then
			local names = {}
			for _, id in ipairs(inc.Parents) do table.insert(names, chickenName(id)) end
			parentsText = tr("💞 พ่อแม่: ", "💞 Parents: ") .. table.concat(names, " × ") .. "\n"
		end
		local f = bigCard(1, "Hatching", (inc.FromEgg and tr("🥚 กำลังฟักไข่จากแผง", "🥚 Hatching a tray egg") or tr("🥚 กำลังผสมพันธุ์", "🥚 Breeding")) .. (inc.Premium and " ✨" or ""),
			parentsText .. tr("ลูกจะออกมาเป็นแบบไหน รอดูตอนฟัก! (ตู้ฟักทำงานต่อแม้ออกเกม)", "What will hatch? Find out soon! (keeps going while you're offline)"))
		local tl = label(f, "", 18, C_TEXT, true)
		tl.Position = UDim2.new(1, -196, 0, 10)
		tl.Size = UDim2.fromOffset(180, 30)
		-- ⚡ ฟักทันที (ช่วงที่ 5): มีคูปอง = ใช้เลย · ไม่มี = ซื้อด้วย Robux (ตั้ง ID แล้วเท่านั้น)
		local tokens = info.HatchTokens or 0
		local productId = info.Ids and info.Ids.Hatch or 0
		if tokens > 0 or productId > 0 then
			local hb = button(f, "InstantHatch", tokens > 0 and (tr("⚡ ใช้คูปอง (", "⚡ Use coupon (") .. tokens .. ")") or ("⚡ " .. tr("ฟักทันที", "Hatch now") .. " R$ " .. tostring(info.PriceHint and info.PriceHint.instantHatch or "")), Color3.fromRGB(255, 180, 60))
			hb.Size = UDim2.fromOffset(180, 38)
			hb.Position = UDim2.new(1, -196, 0, 50)
			hb.TextSize = 14
			hb.Activated:Connect(function()
				if tokens > 0 then send("useHatchToken") else MarketplaceService:PromptProductPurchase(player, productId) end
			end)
		end
		tl.TextXAlignment = Enum.TextXAlignment.Center
		table.insert(timerLabels, { label = tl, left = inc.ReadyIn, prefix = "⏳ ", done = tr("🐣 ฟักแล้ว!", "🐣 Hatched!"), refresh = true })
	else
		-- มีคูปองฟักทันทีเก็บไว้ (ซื้อตอนตู้ว่าง / เพื่อนส่งให้) บอกที่หัวการ์ด จะได้ไม่ลืม (ผู้ใช้ขอ 2026-10-24)
		local heldTokens = info.HatchTokens or 0
		bigCard(1, "Empty", tr("🥚 ตู้ฟักว่าง", "🥚 Incubator is empty") .. (heldTokens > 0 and (tr("  ·  ⚡ คูปองฟักทันที ", "  ·  ⚡ Instant-hatch coupons: ") .. heldTokens .. tr(" ใบ", "")) or ""),
			info.EggHatchOn and (info.BreedOk and tr("ฟักไข่จากแผง หรือเลือกไก่โต 2 ตัวด้านล่างมาผสม ลูกได้ดาวจากพ่อหรือแม่ และมีโอกาสเก่งกว่า หรือได้สายพันธุ์พิเศษ ✨🔥💎🌈", "Hatch tray eggs, or pick two grown chickens below to breed. The chick gets each parent's stars and may beat them — or mutate ✨🔥💎🌈")
				or tr("ฟักไข่จากแผงเก็บไข่เป็นลูกไก่ได้เลย", "Hatch eggs from your egg tray into chicks"))
			-- ฟักไข่จากแผงปิดอยู่ (2026-10-29): ตู้ฟักใช้กับผสมพันธุ์อย่างเดียว
			or (info.BreedOk and tr("เลือกไก่โต 2 ตัวด้านล่างมาผสม ลูกได้ดาวจากพ่อหรือแม่ และมีโอกาสเก่งกว่า หรือได้สายพันธุ์พิเศษ ✨🔥💎🌈", "Pick two grown chickens below to breed. The chick gets each parent's stars and may beat them — or mutate ✨🔥💎🌈")
				or tr("ตู้ฟักใช้ฟักไข่ผสมพันธุ์ ปลดล็อกที่เลเวล ", "The incubator hatches bred eggs — unlocks at level ") .. (info.BreedLevel or 20)))
		-- 🥚 ฟักไข่จากแผง (ได้ลูกไก่แบบไก่ร้าน) · ปิดอยู่ = ไม่โชว์การ์ด (ChickenConfig.EGG_HATCH_ENABLED)
		if info.EggHatchOn then
			local cost = info.EggHatchCost or 5
			local have = info.NormalEggs or 0
			local canEgg = have >= cost
			bigCard(2, "EggHatch", tr("🐣 ฟักไข่จากแผง", "🐣 Hatch tray eggs"),
				(canEgg and "" or (tr("⚠ ไข่ในแผงมี ", "⚠ The tray has ") .. have .. tr(" ฟอง\n", " eggs\n")))
					.. tr("ใช้ไข่ ", "Uses ") .. cost .. tr(" ฟอง (ไม่นับไข่ทอง) ได้ลูกไก่ 1 ตัว ดาว 1–2 เหมือนไก่ร้าน ฟัก ", " eggs (not gold eggs) for 1 chick with 1–2 stars like a shop chicken. Hatches in ")
					.. math.floor(info.HatchMinutes or 30) .. tr(" นาที", " min"),
				"🥚 " .. cost .. tr(" ฟอง", " eggs"), canEgg, function() if canEgg then send("hatchEgg") end end, 96)
		end
	end
	if not info.BreedOk then
		bigCard(3, "BreedLocked", tr("🔒 ผสมพันธุ์", "🔒 Breeding"),
			tr("ผสมพันธุ์ได้ตั้งแต่เลเวล ", "Breeding unlocks at level ") .. (info.BreedLevel or 20), nil, nil, nil, 70)
		return
	end
	-- เลือกพ่อแม่
	local holder = Instance.new("Frame")
	holder.Name = "Parents"
	holder.LayoutOrder = 4
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -8, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = body
	local grid = Instance.new("UIGridLayout", holder)
	grid.CellSize = UDim2.new(1 / 3, -6, 0, 96)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	-- ตัวที่เลือกไว้แต่ไม่มีแล้ว/ไม่พร้อม = เอาออก
	local ready = {}
	for _, c in ipairs(info.Chickens or {}) do
		if (c.GrowIn or 0) <= 0 and (c.RestIn or 0) <= 0 then ready[c.Id] = true end
	end
	for i = #selected, 1, -1 do
		if not ready[selected[i]] then table.remove(selected, i) end
	end
	-- ⏩ เร่งเวลาไก่ (ผู้ใช้ขอ 2026-10-28): ลูกไก่ / พ่อแม่ที่พัก กดปุ่มแล้วขึ้นป๊อปอัป มีคูปอง = ใช้คูปอง · ไม่มี = เซิร์ฟเปิดหน้าซื้อ Robux
	local speedOn = ((info.Ids and info.Ids.Speed) or 0) > 0 or info.SpeedStudio == true
	local C_SPEED = Color3.fromRGB(150, 120, 230)
	local function askSpeedUp(c, col)
		local chick = (c.GrowIn or 0) > 0
		local tokens = info.SpeedTokens or 0
		local price = info.PriceHint and info.PriceHint.speedUp
		local coinPrice = info.SpeedCoinPrice or 0
		-- 💰 ซื้อด้วยเหรียญ (ผู้ใช้ขอ 2026-11-02 · 💰 ฟอนต์ Roblox ไม่มี ขึ้นเป็นกล่อง) มีคูปอง = ไม่โชว์ (ใช้คูปองฟรีก่อน)
		local coinAlt = (tokens == 0 and coinPrice > 0) and {
			text = "💰 " .. (coinPrice >= 1e6 and (tostring(coinPrice / 1e6):gsub("%.0$", "") .. "M") or fmtNum(coinPrice)),
			onAlt = function() send("speedUpCoins", c.Id) end,
		} or nil
		askConfirm(c, chick, tr("⏩ เร่งเวลาไก่?", "⏩ Speed up this chicken?"),
			tr("ไก่", "") .. tr(col.Th, col.En .. " chicken") .. "  #" .. c.Id .. "\n"
				.. (chick and (tr("🐣 อีก ", "🐣 ") .. fmtTime(c.GrowIn) .. tr(" จะโต\n→ โตทันที ออกไข่ได้เลย", " until grown\n→ grows up now and starts laying"))
					or (tr("💤 พักอีก ", "💤 Resting ") .. fmtTime(c.RestIn) .. tr("\n→ หายพักทันที ผสมพันธุ์ได้เลย", " more\n→ rested now, ready to breed")))
				.. (tokens > 0 and (tr("\nใช้คูปอง 1 ใบ (มี ", "\nUses 1 coupon (you have ") .. tokens .. ")") or ""),
			tokens > 0 and tr("⏩ ใช้คูปอง", "⏩ Use coupon") or ("⏩ R$ " .. tostring(price or "")), C_SPEED,
			function() send("speedUp", c.Id) end, nil, coinAlt)
	end
	local shown = 0
	for i, c in ipairs(info.Chickens or {}) do
		local col = Config.Colors[c.Color] or Config.Colors.White
		local isSel = table.find(selected, c.Id) ~= nil
		local f = card(holder, "Parent_" .. c.Id, i)
		tierFrame(f, c, UDim2.new(1, -84, 0, 30), 74) -- กรอบ/ป้ายระดับ (ผู้ใช้ขอ 2026-10-22) ตัวที่เลือกอยู่ใช้สีเลือกทับด้านล่าง
		local breeding = isBreeding(c.Id)
		if isSel then
			f.BackgroundColor3 = Color3.fromRGB(255, 235, 240)
			local s = f:FindFirstChildOfClass("UIStroke")
			s.Color, s.Thickness = C_TAB_ON, 3
		elseif breeding then
			-- พ่อแม่ของไข่ในตู้ฟัก = การ์ดสีเหลือง ขอบส้ม (2026-10-27)
			f.BackgroundColor3 = Color3.fromRGB(255, 246, 220)
			local s = f:FindFirstChildOfClass("UIStroke")
			s.Color, s.Thickness = Color3.fromRGB(255, 170, 60), 3
		end
		local mutText = Config.MutationLabel(c.Mut, LANG == "th")
		local head = label(f, tr("ไก่", "") .. (LANG == "th" and col.Th or col.En) .. " #" .. c.Id .. (mutText and (" " .. mutText) or ""), 13, C_TEXT, true)
		head.Position = UDim2.fromOffset(10, 6)
		head.Size = UDim2.new(1, -16, 0, 22)
		local st = label(f, string.format("⚡%d  🥚%d  🟡%d", c.Speed, c.Size, c.Gold), 13, C_SUB)
		st.Position = UDim2.fromOffset(10, 28)
		st.Size = UDim2.new(1, -16, 0, 20)
		local btnText, ok
		local speedable = false -- ⏩ เร่งได้ (ลูกไก่ / พักอยู่)
		if (c.GrowIn or 0) > 0 then
			btnText, ok = tr("🐣 โตใน ", "🐣 Grows in ") .. fmtTime(c.GrowIn), false
			speedable = speedOn
		elseif breeding then
			btnText, ok = tr("🥚 กำลังผสมพันธุ์", "🥚 Breeding"), false
		elseif (c.RestIn or 0) > 0 then
			btnText, ok = tr("💤 พัก ", "💤 Rest ") .. fmtTime(c.RestIn), false
			speedable = speedOn
		else
			btnText, ok = isSel and tr("✔ เลือกแล้ว", "✔ Picked") or tr("เลือก", "Pick"), true
		end
		if speedable then btnText ..= "  ⏩" end
		local b = button(f, "Pick_" .. c.Id, btnText, ok and (isSel and C_TAB_ON or C_BTN) or (speedable and C_SPEED) or (breeding and Color3.fromRGB(255, 190, 90) or C_BTN_OFF))
		b.Size = UDim2.new(1, -20, 0, 30)
		b.Position = UDim2.new(0, 10, 0, 56)
		b.TextSize = 13
		b.Activated:Connect(function()
			if speedable then lastSelectedName = b.Name askSpeedUp(c, col) return end
			if not ok then return end
			local at = table.find(selected, c.Id)
			if at then
				table.remove(selected, at)
			else
				if #selected >= 2 then table.remove(selected, 1) end
				table.insert(selected, c.Id)
			end
			lastSelectedName = b.Name
			render()
		end)
		shown += 1
	end
	if shown == 0 then
		local l = label(holder, tr("ยังไม่มีไก่ ซื้อได้ที่ลุงไข่ขายไก่", "No chickens yet — buy some from the Chicken Merchant"), 14, C_SUB)
		l.Size = UDim2.fromScale(1, 1)
	end
	-- ปุ่มผสม
	local canBreed = #selected == 2 and not inc and info.BreedBagsReady
	local why
	if inc then why = tr("รอตู้ฟักว่างก่อน", "Wait for the incubator")
	elseif not info.BreedBagsReady then why = tr("เติมอาหารในรางอย่างน้อย ", "Put at least ") .. info.BreedBags .. tr(" ถุงก่อน", " bags in the trough")
	elseif #selected < 2 then why = tr("เลือกไก่อีก ", "Pick ") .. (2 - #selected) .. tr(" ตัว", " more") end
	local pityLeft = (info.PityMax or 50) - (info.Pity or 0)
	bigCard(5, "Breed", tr("💕 ผสมพันธุ์", "💕 Breed"),
		(why and ("⚠ " .. why .. "\n") or "") ..
		tr("ใช้ อาหาร ", "Uses ") .. info.BreedBags .. tr(" ถุงจากราง (⭐5 = โอกาสได้สายพันธุ์พิเศษ x1.5) · พ่อแม่พัก ", " trough bags (⭐5 = 1.5x mutation) · parents rest ") .. math.floor((info.RestMinutes or 120) / 60) .. tr(" ชม.", "h") ..
		tr("\nผสมอีก ", "\nGuaranteed ✨ Glow within ") .. pityLeft .. tr(" ครั้งการันตี ✨ เรืองแสง", " breeds"),
		"💕 💰 " .. fmtNum(info.BreedCost or 0), canBreed, function()
			if canBreed then
				local pair = { selected[1], selected[2] }
				selected = {}
				send("breed", pair)
			end
		end, 112)
end

-- ============ สมุดไก่ (ช่วงที่ 4) ============
local function renderBook()
	listLayout()
	local book = info.Book or {}
	local head = bigCard(1, "BookHead", tr("📖 เก็บได้ ", "📖 Collected ") .. (info.BookCount or 0) .. " / " .. (info.BookTotal or 25),
		tr("ได้ไก่ (ซื้อหรือฟัก) สีและสายพันธุ์แบบไหน = บันทึกถาวร ขายไปแล้วก็ไม่หาย", "Every colour + mutation you get (bought or hatched) is recorded forever, even after selling"), nil, nil, nil, 80)
	-- ตาราง 5 สี × 5 พันธุ์
	local holder = Instance.new("Frame")
	holder.Name = "BookGrid"
	holder.LayoutOrder = 2
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -8, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = body
	local grid = Instance.new("UIGridLayout", holder)
	grid.CellSize = UDim2.new(0.2, -6, 0, 62)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	for i, e in ipairs(Config.BookEntries()) do
		local got = book[e.Key] == true
		local col = Config.Colors[e.Color]
		local m = e.Mut and Config.Mutations[e.Mut]
		local f = card(holder, "Entry_" .. i, i)
		if not got then f.BackgroundColor3 = Color3.fromRGB(238, 232, 228) end
		local sw = Instance.new("Frame", f)
		sw.Size = UDim2.fromOffset(24, 24)
		sw.Position = UDim2.new(0, 8, 0.5, -12)
		sw.BackgroundColor3 = got and col.Main or Color3.fromRGB(200, 195, 190)
		Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
		local l = label(f, got and ((LANG == "th" and col.Th or col.En) .. "\n" .. (m and (m.Icon .. " " .. (LANG == "th" and m.Th or m.En)) or tr("ทั่วไป", "Standard"))) or ("?\n" .. (m and m.Icon or "·")), 12, got and C_TEXT or C_SUB, got)
		l.Position = UDim2.fromOffset(38, 4)
		l.Size = UDim2.new(1, -42, 1, -8)
	end
	-- พันธุ์เทศกาล (ไม่นับใน 25)
	local seasonal = {}
	for key in pairs(book) do
		local c, mid = key:match("^(%w+)|(%w+)$")
		local m = mid and Config.Mutations[mid]
		if m and m.Season then table.insert(seasonal, m.Icon .. " " .. (LANG == "th" and Config.Colors[c].Th or Config.Colors[c].En)) end
	end
	if #seasonal > 0 then
		bigCard(3, "Seasonal", tr("🎃 พันธุ์เทศกาล (ช่องพิเศษ)", "🎃 Seasonal (bonus)"), table.concat(seasonal, "  ·  "), nil, nil, nil, 70)
	end
	-- รางวัล
	local claimed = info.BookClaimed or {}
	for i, r in ipairs(info.BookRewards or {}) do
		local done = claimed[tostring(r.Count)] == true
		local canClaim = not done and (info.BookCount or 0) >= r.Count
		bigCard(10 + i, "Reward_" .. r.Count, tr("🎁 เก็บครบ ", "🎁 Collect ") .. r.Count .. tr(" ช่อง", " entries"),
			"💰 " .. fmtNum(r.Coins) .. tr(" เหรียญ", " coins"),
			done and tr("✔ รับแล้ว", "✔ Claimed") or (canClaim and tr("รับรางวัล", "Claim") or ((info.BookCount or 0) .. "/" .. r.Count)),
			canClaim, function() if canClaim then send("claimBook", r.Count) end end, 76)
	end
end

-- ============ ช่วงที่ 6: 🏆 ประกวด · 🏛 หอเกียรติยศ (2026-10-22) ============
local function themeOf(id)
	for _, th in ipairs(Config.CONTEST_THEMES) do
		if th.Id == id then return th end
	end
	return Config.CONTEST_THEMES[1]
end

-- คะแนนประกวดแบบอ่านง่าย: หัวข้อดาว = ★ ตามด้วยคะแนนรวม · กลายพันธุ์ = ไอคอนพันธุ์
local function statText(themeId, stat)
	stat = stat or 0
	if themeId == "best" then return tr("คะแนน ", "Score ") .. stat end
	local main, rest = stat // 1000, stat % 1000
	if themeId == "mut" then
		local icon = "·"
		for _, m in pairs(Config.Mutations) do
			if m.Order == main and not m.Season then icon = m.Icon end
		end
		return (main > 0 and icon or tr("สายพันธุ์ทั่วไป", "Standard breed")) .. " · " .. rest
	end
	return stars(main) .. " · " .. rest
end

local function loadBoard(force)
	if boardLoading or (not force and os.clock() - boardAt < 30) then return end
	boardLoading = true
	task.spawn(function()
		local ok, res = pcall(function() return requestRemote:InvokeServer("contestBoard") end)
		boardLoading = false
		if ok and type(res) == "table" then
			board, boardAt = res, os.clock()
			if gui.Enabled and tab == "contest" and not pending then render() end
		end
	end)
end

local function renderContest()
	listLayout()
	local ct = info.Contest or {}
	local theme = themeOf(ct.ThemeId)
	local head = bigCard(1, "ContestHead", theme.Icon .. tr(" หัวข้อสัปดาห์นี้: ", " This week: ") .. tr(theme.Th, theme.En),
		tr(theme.Hint[1], theme.Hint[2]) .. tr("\nส่งได้คนละ 1 ตัว เปลี่ยนได้ตลอดสัปดาห์ ไก่ยังอยู่ในเล้า · คะแนนเท่ากัน ส่งก่อนชนะ", "\nOne chicken each, change any time this week; it stays in your coop · ties go to the earlier entry"),
		nil, nil, nil, 96)
	local timer = label(head, "", 15, C_TEXT, true)
	timer.Position = UDim2.new(1, -230, 0, 10)
	timer.Size = UDim2.fromOffset(214, 28)
	timer.TextXAlignment = Enum.TextXAlignment.Right
	table.insert(timerLabels, { label = timer, left = ct.EndsIn or 0, prefix = tr("⏳ ปิดใน ", "⏳ Ends in "), done = tr("⏳ ปิดรอบแล้ว", "⏳ Closed") })
	-- รางวัลสัปดาห์ก่อนที่ยังไม่รับ
	if ct.Pending then
		bigCard(2, "ContestClaim", tr("🎁 ผลประกวดสัปดาห์ก่อนออกแล้ว!", "🎁 Last week's results are in!"),
			tr("กดรับรางวัลตามอันดับที่ได้", "Claim your reward for your rank"), tr("รับรางวัล", "Claim"), true,
			function() send("contestClaim") end, 80)
	end
	-- ไก่ที่ส่ง
	local e = ct.Entry
	if e then
		local col = Config.Colors[e.Color] or Config.Colors.White
		local mutText = Config.MutationLabel(e.Mut, LANG == "th")
		local f = bigCard(3, "ContestEntry", tr("🐔 ไก่ที่ส่ง: ไก่", "🐔 Your entry: ") .. tr(col.Th, col.En .. " chicken") .. " #" .. tostring(ct.EntryId),
			string.format("%s %s · %s %s · %s %s%s\n%s", tr("ไข่เร็ว", "Speed"), stars(e.Speed), tr("ไข่ใหญ่", "Size"), stars(e.Size), tr("ไข่ทอง", "Gold"), stars(e.Gold),
				mutText and (" · " .. mutText) or "", statText(ct.ThemeId, ct.EntryStat)), nil, nil, nil, 88)
		chickenViewport(f, e, UDim2.new(1, -84, 0, 6), 76, false)
	else
		bigCard(3, "ContestEntry", tr("🐔 ยังไม่ได้ส่งไก่", "🐔 No entry yet"),
			tr("กด 🏆 ส่งประกวด ที่การ์ดไก่ในหน้า 🐔 ไก่ของฉัน", "Press 🏆 Enter contest on a chicken in 🐔 My chickens"),
			tr("🐔 เลือกไก่", "🐔 Pick one"), true, function() if openTab then openTab("chickens") end end, 80)
	end
	-- รางวัล
	local lines, prev = {}, 0
	for _, r in ipairs(ct.Rewards or {}) do
		local rankText = r.MaxRank == prev + 1 and ("#" .. r.MaxRank) or ("#" .. (prev + 1) .. "–" .. r.MaxRank)
		table.insert(lines, rankText .. "  ⚡ " .. (r.HatchTokens or 0) .. tr(" คูปองฟักไข่ทันที + 💰 ", " instant-hatch coupons + 💰 ") .. fmtNum(r.Coins))
		prev = r.MaxRank
	end
	table.insert(lines, tr("ทุกคนที่ส่ง  💰 ", "Everyone who enters  💰 ") .. fmtNum(ct.Participation or 0))
	bigCard(4, "ContestRewards", tr("🎁 รางวัล (กดรับสัปดาห์ถัดไป)", "🎁 Rewards (claim next week)"), table.concat(lines, "\n"), nil, nil, nil, 40 + 20 * #lines + 10)
	-- อันดับ
	loadBoard(false)
	local rows = {}
	if board and board.Top then
		for _, r in ipairs(board.Top) do
			table.insert(rows, (r.Me and "▶ " or "") .. "#" .. r.Rank .. "  " .. tostring(r.Name) .. "  ·  " .. statText(board.ThemeId, r.Stat))
		end
	end
	local topText = board and (#rows > 0 and table.concat(rows, "\n") or tr("ยังไม่มีใครส่ง ส่งเป็นคนแรกเลย!", "No entries yet — be the first!")) or tr("กำลังโหลด...", "Loading...")
	bigCard(5, "ContestTop", tr("🏅 10 อันดับสัปดาห์นี้ (ทุกเซิร์ฟ)", "🏅 This week's top 10 (all servers)"), topText, nil, nil, nil, 44 + 20 * math.max(1, #rows) + 10)
	if board and board.Last and #board.Last > 0 then
		local last = {}
		local medals = { "🥇", "🥈", "🥉" }
		for _, r in ipairs(board.Last) do
			table.insert(last, (medals[r.Rank] or ("#" .. r.Rank)) .. " " .. tostring(r.Name) .. "  ·  " .. statText(board.LastThemeId, r.Stat))
		end
		local lt = themeOf(board.LastThemeId)
		bigCard(6, "ContestLast", tr("👑 ผู้ชนะสัปดาห์ก่อน: ", "👑 Last week's winners: ") .. tr(lt.Th, lt.En), table.concat(last, "\n"), nil, nil, nil, 44 + 20 * #last + 10)
	end
end

local function renderHall()
	listLayout()
	local hall = info.Hall or {}
	local pct = math.floor((info.HallBonus or 0) * 100 + 0.5)
	local step = math.floor((info.HallStep or 0.02) * 100 + 0.5)
	bigCard(1, "HallHead", tr("🏛 หอเกียรติยศ ", "🏛 Hall of Fame ") .. #hall .. "/" .. (info.HallMax or 10) .. tr("  ·  ไข่ขายได้ +", "  ·  Eggs sell +") .. pct .. "%",
		tr("ไก่โตที่ได้ 5 ดาวครบทั้ง 3 ค่า กด 🏛 ปลดเกษียณ ที่การ์ดไก่ได้ ไก่ออกจากเล้า (ช่องว่างลง) แล้วอยู่ที่นี่ตลอดไป ตัวละ +", "Adult chickens with 5 stars in all three stats can retire (🏛 Retire on its card). It leaves the coop and stays here forever: +")
			.. step .. tr("% ราคาไข่ถาวร สูงสุด ", "% egg price each, up to ") .. (info.HallMax or 10) .. tr(" ตัว", " chickens"), nil, nil, nil, 96)
	if #hall == 0 then
		bigCard(2, "HallEmpty", tr("ยังว่างอยู่", "Empty for now"), tr("ผสมพันธุ์ไปเรื่อยๆ จนได้ไก่ ★★★★★ ครบทุกค่า แล้วพามาอยู่ที่นี่", "Keep breeding until you get a ★★★★★ chicken in every stat"), nil, nil, nil, 70)
		return
	end
	local holder = Instance.new("Frame")
	holder.Name = "HallGrid"
	holder.LayoutOrder = 2
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -8, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = body
	local grid = Instance.new("UIGridLayout", holder)
	grid.CellSize = UDim2.new(0.5, -6, 0, 132) -- สูงขึ้นให้มีที่ปุ่มนำออก (2026-11-02)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	-- 🐔 นำออกจากหอ (ผู้ใช้ขอ 2026-11-02) เล้าต้องว่าง 1 ช่อง · เซิร์ฟเช็กซ้ำทุกอย่าง
	local unPrice = info.HallUnretirePrice or 0
	local unText = unPrice >= 1e6 and (tostring(unPrice / 1e6):gsub("%.0$", "") .. "M") or fmtNum(unPrice)
	local coopFull = #(info.Chickens or {}) >= (info.Slots or 0)
	for i, h in ipairs(hall) do
		local col = Config.Colors[h.Color] or Config.Colors.White
		local f = card(holder, "Hall_" .. i, i)
		chickenViewport(f, h, UDim2.fromOffset(8, 8), 80, false)
		tierFrame(f, h, UDim2.fromOffset(8, 72), 80)
		local mutText = Config.MutationLabel(h.Mut, LANG == "th")
		local when = h.At and h.At > 0 and os.date("%d/%m/%Y", h.At) or ""
		local l = label(f, "🏅 " .. tr("ไก่" .. col.Th, col.En .. " chicken") .. (mutText and ("  " .. mutText) or "")
			.. "\n★★★★★ × 3"
			.. "\n" .. tr("เกษียณ ", "Retired ") .. when, 13, C_TEXT, false)
		l.Position = UDim2.fromOffset(98, 8)
		l.Size = UDim2.new(1, -106, 1, -52)
		l.TextYAlignment = Enum.TextYAlignment.Top
		if unPrice > 0 then
			local b = button(f, "Unretire", tr("🐔 นำออก 💰 ", "🐔 Bring back 💰 ") .. unText, coopFull and C_BTN_OFF or C_BTN)
			b.Size = UDim2.new(1, -16, 0, 32)
			b.Position = UDim2.new(0, 8, 1, -40)
			b.Activated:Connect(function()
				if coopFull then
					setStatus(tr("เล้าเต็ม (", "Coop full (") .. #(info.Chickens or {}) .. "/" .. (info.Slots or 0) .. tr(") ซื้อช่องเพิ่มหรือขายไก่ก่อน", ") buy a slot or sell a chicken first"), false)
					return
				end
				local step = math.floor((info.HallStep or 0.02) * 100 + 0.5)
				local pct = math.floor((info.HallBonus or 0) * 100 + 0.5)
				askConfirm(h, false, tr("🐔 นำไก่ออกจากหอ?", "🐔 Bring this chicken back?"),
					tr("ไก่" .. col.Th, col.En .. " chicken") .. (mutText and ("  " .. mutText) or "") .. "  ★★★★★ × 3"
						.. tr("\nกลับเข้าเล้าเป็นไก่โต ออกไข่ได้เลย", "\nReturns to your coop as an adult, laying right away")
						.. tr("\nไข่ขายได้จากหอ ", "\nHall egg bonus ") .. "+" .. pct .. "% → +" .. math.max(0, pct - step) .. "%"
						.. tr("\nปลดเกษียณซ้ำได้ แต่ไม่ได้ XP อีก", "\nCan retire again, but no XP next time"),
					"💰 " .. unText, Color3.fromRGB(235, 175, 55),
					function() send("unretire", { i, h.At }) end)
			end)
		end
	end
end

render = function()
	timerLabels = {}
	bookButton.Visible = false -- ใช้แถบสลับหน้า (navRow) แทน (ช่วงที่ 6)
	local showNav = table.find(NAV_TABS, tab) ~= nil and info ~= nil and info.Loaded == true and info.LevelOk == true
	navRow.Visible = showNav
	for id, b in pairs(navButtons) do
		b.BackgroundColor3 = id == tab and C_TAB_ON or C_TAB
		b.TextColor3 = id == tab and Color3.new(1, 1, 1) or Color3.fromRGB(110, 75, 60)
	end
	body.Position = UDim2.fromOffset(14, showNav and 94 or 58)
	body.Size = UDim2.new(1, -28, 1, showNav and -140 or -104)
	clearBody()
	title.Text = TITLES[tab] or TITLES.chickens
	subtitle.Text = ""
	if not info then renderLocked(tr("กำลังโหลด...", "Loading...")) return end
	if not info.Enabled then renderLocked(tr("บ้านไก่ยังไม่เปิด", "The coop is not open yet")) return end
	if not info.LevelOk then
		renderLocked(tr("🔒 ต้องเลเวล ", "🔒 Requires level ") .. info.UnlockLevel .. tr(" ขึ้นไป", ""))
		return
	end
	if not info.Loaded then renderLocked(tr("กำลังโหลดข้อมูลไก่...", "Loading your chickens...")) return end
	if tab == "chickens" then
		subtitle.Text = tr("ไก่ ", "Chickens ") .. #(info.Chickens or {}) .. "/" .. (info.Slots or 0)
			.. tr("  ·  ราง ", "  ·  Trough ") .. (info.TroughBags or 0)
			.. tr("  ·  ไข่ ", "  ·  Eggs ") .. ((info.Basket and info.Basket.Count) or 0)
	end
	if tab == "chickens" then renderChickens()
	elseif tab == "shop" then renderShop()
	elseif tab == "trough" then renderTrough()
	elseif tab == "breed" then renderBreed()
	elseif tab == "book" then renderBook()
	elseif tab == "contest" then renderContest()
	elseif tab == "hall" then renderHall()
	else renderBasket() end
end

-- ============ เปิด/ปิด ============
local function usingGamepad()
	local t = UserInputService:GetLastInputType()
	return t == Enum.UserInputType.Gamepad1 or t == Enum.UserInputType.Gamepad2 or t == Enum.UserInputType.Gamepad3 or t == Enum.UserInputType.Gamepad4
end

-- จุดในแมพของแต่ละหน้าต่าง (ใช้ปิดเมื่อเดินห่าง)
local CLOSE_DISTANCE = 25
local ANCHORS = { chickens = "PromptAnchor", book = "PromptAnchor", contest = "PromptAnchor", hall = "PromptAnchor", shop = "ShopPromptAnchor", trough = "TroughPromptAnchor", basket = "EggPromptAnchor", breed = "IncubatorPromptAnchor" }
local openedAt = nil
local function anchorFor(mode)
	local yard = workspace:FindFirstChild("FarmProps") and workspace.FarmProps:FindFirstChild("ChickenYard")
	local name = ANCHORS[mode]
	return yard and name and yard:FindFirstChild(name, true) or nil
end

-- ปุ่มแรกในหน้าต่าง (ตามลำดับการ์ด) ให้จอยเลือกตอนเปิด
local function firstButton()
	local best, bestOrder = nil, math.huge
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("GuiObject") and c.LayoutOrder < bestOrder then
			local b = c:FindFirstChildWhichIsA("GuiButton", true)
			if b then best, bestOrder = b, c.LayoutOrder end
		end
	end
	return best or closeButton
end

local function close()
	hideConfirm()
	gui.Enabled = false
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(gui) then GuiService.SelectedObject = nil end
end

local function open(mode)
	hideConfirm()
	if player:GetAttribute("ChickenNew") == true then -- เปิดครั้งแรก = ป้าย "ใหม่!" ที่จุดวาร์ปหาย (2026-10-25)
		task.spawn(function() pcall(function() requestRemote:InvokeServer("seen") end) end)
	end
	tab = SIZES[mode] and mode or "chickens"
	openedAt = anchorFor(tab)
	W, H = SIZES[tab].X, SIZES[tab].Y
	panel.Size = UDim2.fromOffset(W, H)
	gui.Enabled = true
	fit()
	setStatus("")
	render()
	task.spawn(function()
		local ok, res = pcall(function() return requestRemote:InvokeServer("info") end)
		if ok and type(res) == "table" and res.info then
			info, infoAt = res.info, os.clock()
			if gui.Enabled then
				render()
				if usingGamepad() then GuiService.SelectedObject = firstButton() end
			end
		end
	end)
	if usingGamepad() then GuiService.SelectedObject = firstButton() end
end
closeButton.Activated:Connect(close)
openTab = function(id)
	if id == "contest" then loadBoard(true) end
	open(id)
end
bookButton.Activated:Connect(function()
	open(tab == "book" and "chickens" or "book")
end)
dim.Activated:Connect(close)
openRemote.OnClientEvent:Connect(open)
syncRemote.OnClientEvent:Connect(function(newInfo)
	if type(newInfo) ~= "table" then return end
	info, infoAt = newInfo, os.clock()
	if gui.Enabled and not pending then
		local sel = GuiService.SelectedObject
		lastSelectedName = sel and sel:IsDescendantOf(gui) and sel.Name or nil
		render()
	end
end)

-- จอย: B ปิด · คีย์บอร์ดไม่มีปุ่มลัด (กันชนกับแชท)
UserInputService.InputBegan:Connect(function(input)
	if not gui.Enabled then return end
	if input.KeyCode == Enum.KeyCode.ButtonB then
		if confirmDim.Visible then hideConfirm() else close() end -- ป๊อปอัพยืนยันเปิดอยู่ = ปิดแค่ป๊อปอัพ
	end
end)

-- นับถอยหลังไข่ฟองถัดไป + คืนการเลือกปุ่มหลังหน้าจอสร้างใหม่ + เดินห่างเล้า = ปิด
local tick = 0
RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then return end
	tick += dt
	if tick < 0.5 then return end
	tick = 0
	local elapsed = os.clock() - infoAt
	for _, t in ipairs(timerLabels) do
		local left = t.left - elapsed
		t.label.Text = left > 0 and ((t.prefix or "🥚 ") .. fmtTime(left)) or (t.done or tr("🥚 ใกล้ออกแล้ว", "🥚 Any moment"))
		if left <= 0 and t.refresh and not t.refreshed then
			-- ไข่ฟักครบเวลา = ขอข้อมูลใหม่ให้ปุ่ม "รับลูกไก่" ขึ้นทันที
			t.refreshed = true
			task.spawn(function()
				task.wait(1)
				local ok, res = pcall(function() return requestRemote:InvokeServer("info") end)
				if ok and type(res) == "table" and res.info and gui.Enabled and not pending then
					info, infoAt = res.info, os.clock()
					render()
				end
			end)
		end
	end
	if usingGamepad() and lastSelectedName then
		local sel = GuiService.SelectedObject
		if not (sel and sel:IsDescendantOf(gui)) then
			local again = panel:FindFirstChild(lastSelectedName, true)
			if again and again:IsA("GuiButton") then GuiService.SelectedObject = again end
		end
		lastSelectedName = nil
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	-- เดินห่างจุดที่เปิดหน้าต่างนี้ (ร้าน/ราง/ตะกร้า/ตู้ฟัก/เล้า) เกิน CLOSE_DISTANCE = ปิด (เดิมวัดจากเล้าอย่างเดียว ร้านที่อยู่ไกลเล้าเปิดแล้วปิดทันที 2026-10-20)
	local anchor = openedAt and openedAt.Parent and openedAt
	if root and anchor and (root.Position - anchor.Position).Magnitude > CLOSE_DISTANCE then close() end
end)
