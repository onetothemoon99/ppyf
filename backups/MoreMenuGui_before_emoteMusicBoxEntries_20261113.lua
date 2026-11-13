-- BACKUP 2026-11-13 — StarterPlayer.StarterPlayerScripts.MoreMenuGui (LocalScript) ก่อนเพิ่มรายการ "ท่าเต้น" + "Music Box" และซ่อนปุ่มเดิมบนแถวบน
-- วิธีคืน: ใน Studio เปิด StarterPlayer.StarterPlayerScripts.MoreMenuGui แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 3 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- และลบ StarterPlayer.StarterPlayerScripts.HowToPlayGui (สคริปต์ใหม่ของการแก้รอบนี้) ถ้าต้องการย้อนทั้งหมด
-- MoreMenuGui: ปุ่ม "เมนูเพิ่มเติม" (ขีดสามเส้น) แถวซ้ายบนข้างปุ่ม Roblox เปิดรายการ: เพลงและเสียง / วาปไปจุดต่างๆ / สมุดสะสมปลา / ตั้งสถานะ (VIP)
-- (2026-10-02 ผู้เล่นขอ: ย้ายปุ่มพวกนี้เข้าเมนูเดียว ปุ่มเดิมถูกซ่อนในสคริปต์ของแต่ละตัว หน้าต่างยังเป็นของเดิม)
-- แต่ละรายการ = ยิง BindableEvent ของหน้าต่างนั้น: MusicPlayerGui.OpenMusic / WarpGui.OpenWarp / FishIndexGui.OpenFishIndex / VipGui.OpenVip
-- ปุ่มมีจุดแดงเมื่อมีปลาใหม่ในสมุด (FishIndexGui ตั้ง Attribute HasNew)
-- จอย: ปุ่มอยู่ในแถว TopbarRow (TopMenuGamepad เลือกให้) เปิดแล้วเลือกรายการแรกให้ · ▲▼ เลือก · A เปิด · B ปิด

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local TopbarRow = require(script.Parent:WaitForChild("TopbarRow"))
local Localization = require(game:GetService("ReplicatedStorage"):WaitForChild("Localization"))
local player = Players.LocalPlayer
local function tr(th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end -- อ่านภาษาปัจจุบันของผู้เล่นทุกครั้งที่เรียก
local playerGui = player:WaitForChild("PlayerGui")

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_CARD = Color3.fromRGB(255, 240, 225)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_BORDER = Color3.fromRGB(140, 100, 65)

local ENTRIES = {
	{ id = "music", icon = "🎵", th = "เสียง", en = "Sound", gui = "MusicPlayerGui", event = "OpenMusic" },
	{ id = "warp", icon = "🧭", th = "วาป", en = "Warp", gui = "WarpGui", event = "OpenWarp" },
	-- "สัตว์ขี่" เอาออกจากเมนูแล้ว 2026-10-16 (ผู้ใช้: เมนูเพิ่มเติมไม่เอาสัตว์ขี่แล้ว) อยู่ในกระเป๋าแท็บ 🐴 สัตว์ขี่ + ปุ่ม H / ปุ่ม 🐴 แทน
	{ id = "servers", icon = "🌐", th = "เซิร์ฟเวอร์", en = "Servers", gui = "ServerBrowserGui", event = "OpenServerBrowser" },
	{ id = "fish", icon = "📖", th = "สมุดปลา", en = "Fish Book", gui = "FishIndexGui", event = "OpenFishIndex" },
	-- เมนูเรียง 2 คอลัมน์ ซ้าย→ขวา ออเดอร์ก่อนสมุดพืช = สมุดพืชอยู่ใต้สมุดปลาพอดี (2026-10-31 ผู้ใช้ขอ)
	{ id = "orders", icon = "📋", th = "ออเดอร์", en = "Orders", gui = "OrderBoardGui", event = "OpenOrderBoard" }, -- 2026-10-31 กระดานออเดอร์ สวิตช์เดียวกับสมุดพืช
	{ id = "cropbook", icon = "🌱", th = "สมุดพืช", en = "Crop Book", gui = "CropBookGui", event = "OpenCropBook" }, -- 2026-10-30 สวิตช์ CropBookConfig.IsEnabled (FarmEndgame2026 แพตช์หน้า)
	{ id = "contest", icon = "🏆", th = "ประกวดผัก", en = "Crop Contest", gui = "CropContestGui", event = "OpenCropContest" }, -- 2026-10-31 ประกวดผักยักษ์ สวิตช์เดียวกับสมุดพืช
	{ id = "badges", icon = "🏅", th = "เหรียญตรา", en = "Badges", gui = "AchievementGui", event = "OpenAchievement" }, -- 2026-11-04 สวิตช์ AchievementConfig.ENABLED
	{ id = "vip", icon = "👑", th = "ตั้งสถานะ", en = "VIP Status", gui = "VipGui", event = "OpenVip" },
	-- 📘 "บทเรียน" เอาออกแล้ว 2026-10-27 (ปิดบทเรียนผู้เล่นใหม่) · เปิดคืน: { id = "tutorial", icon = "📘", th = "บทเรียน", en = "Tutorial", gui = "TutorialGui", event = "OpenTutorial" } (updateTutorialEntry ยังอยู่ ไม่มีรายการนี้ = ไม่ทำอะไร)
	{ id = "graphics", icon = "⚙️", th = "กราฟิก", en = "Graphics", gui = "GraphicsGui", event = "OpenGraphics" },

	{ id = "time", icon = "🕒", th = "เวลาในเกม", en = "Time of day", gui = "PersonalTimeGui", event = "OpenPersonalTime" },	{ id = "photo", icon = "📷", th = "โหมดถ่ายภาพ", en = "Photo Mode", gui = "PhotoModeGui", event = "OpenPhoto" }, -- ซ่อน UI ทั้งหมด (2026-10-03) -- เลือกระดับกราฟิกตามเครื่อง (2026-10-03)
	{ id = "redeem", icon = "🎟️", th = "แลกโค้ด", en = "Redeem Code", gui = "SultanRedeemGui", event = "OpenRedeemCodeMenu" },
}
-- สัตว์ขี่ยังไม่เปิด (MountConfig.Enabled = false) = ไม่มีปุ่ม "สัตว์ขี่" ในเมนู (2026-10-16)
do
	local MountConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("MountConfig"))
	if not MountConfig.IsEnabled() then
		for i = #ENTRIES, 1, -1 do
			if ENTRIES[i].id == "mount" then table.remove(ENTRIES, i) end
		end
	end
	if not require(game:GetService("ReplicatedStorage"):WaitForChild("AchievementConfig")).ENABLED then
		for i = #ENTRIES, 1, -1 do
			if ENTRIES[i].id == "badges" then table.remove(ENTRIES, i) end
		end
	end
	-- สมุดพืชยังไม่ปล่อย = ไม่มีปุ่ม (2026-10-30)
	local CropBookConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("CropBookConfig"))
	if not CropBookConfig.IsEnabled() then
		for i = #ENTRIES, 1, -1 do
			if ENTRIES[i].id == "cropbook" or ENTRIES[i].id == "orders" or ENTRIES[i].id == "contest" then table.remove(ENTRIES, i) end
		end
	end
end

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0); c.Parent = obj; return c end

-- ============ ปุ่มในแถวซ้ายบน ============
local row = TopbarRow.Get()
local topGui = row.Parent -- TopbarRowGui (ใช้ระบบพิกัดเดียวกับแถว วางเมนูใต้ปุ่มได้ตรง)

local moreButton = Instance.new("TextButton")
moreButton.Name = "MoreButton"
moreButton.Size = UDim2.new(0, 44, 0, 44)
moreButton.BackgroundColor3 = Color3.fromRGB(255, 250, 230)
moreButton.Text = ""
moreButton.AutoButtonColor = true
moreButton.Selectable = true
moreButton.LayoutOrder = 1
moreButton.Parent = row
corner(moreButton)
do
	local st = Instance.new("UIStroke")
	st.Color = COLOR_BORDER
	st.Thickness = 2
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = moreButton
	-- ขีดสามเส้น (วาดด้วยกรอบ ไม่พึ่งฟอนต์)
	for i = 0, 2 do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, 0.5, (i - 1) * 7)
		bar.Size = UDim2.new(0, 20, 0, 3)
		bar.BackgroundColor3 = COLOR_TEXT
		bar.BorderSizePixel = 0
		bar.Parent = moreButton
		corner(bar)
	end
end
local moreDot = Instance.new("Frame")
moreDot.Name = "NewDot"
moreDot.Size = UDim2.new(0, 12, 0, 12)
moreDot.Position = UDim2.new(1, -10, 0, -2)
moreDot.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
moreDot.Visible = false
moreDot.ZIndex = 3
moreDot.Parent = moreButton
corner(moreDot)

-- ============ ฉากหลังจับการแตะนอกเมนู (ต่ำกว่าแถวปุ่ม จึงกดปุ่มเมนูได้ตามปกติ) ============
local dimGui = Instance.new("ScreenGui")
dimGui.Name = "MoreMenuDim"
dimGui.ResetOnSpawn = false
dimGui.DisplayOrder = 4
dimGui.IgnoreGuiInset = true
dimGui.Enabled = false
dimGui.Parent = playerGui
local dim = Instance.new("TextButton")
dim.Size = UDim2.new(1, 0, 1, 0)
dim.BackgroundTransparency = 1
dim.Text = ""
dim.AutoButtonColor = false
dim.Selectable = false
dim.Parent = dimGui

-- ============ รายการเมนู ============
local panel = Instance.new("Frame")
panel.Name = "MoreMenuPanel"
panel.Size = UDim2.new(0, 250, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = COLOR_BG
panel.Visible = false
panel.ZIndex = 5
panel.SelectionGroup = true
panel.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
panel.Parent = topGui
corner(panel, 14)
do
	local st = Instance.new("UIStroke"); st.Color = COLOR_BORDER; st.Thickness = 2.5; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6); pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = panel
	-- จัดเป็นตาราง 2 คอลัมน์ทุกขนาดหน้าจอ ปรับความกว้างช่องให้พอดีกับจอ
	local layout = Instance.new("UIGridLayout")
	layout.Name = "EntryGrid"
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.CellPadding = UDim2.fromOffset(4, 4)
	layout.CellSize = UDim2.fromOffset(238, 46)
	layout.Parent = panel
end

local entryButtons = {}
local entryLabels = {}
local entryDots = {}
local closeMenu
local updateTutorialEntry
for i, entry in ipairs(ENTRIES) do
	local b = Instance.new("TextButton")
	b.Name = "Entry_" .. entry.id
	b.LayoutOrder = i
	b.Size = UDim2.new(1, 0, 0, 46)
	b.BackgroundColor3 = COLOR_CARD
	b.Text = ""
	b.AutoButtonColor = true
	b.Selectable = true
	b.ZIndex = 6
	b.Parent = panel
	corner(b, 10)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.Position = UDim2.new(0, 4, 0, 0)
	icon.Text = entry.icon
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.ZIndex = 7
	icon.Parent = b

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -56, 1, 0)
	label.Position = UDim2.new(0, 48, 0, 0)
	label.Text = tr(entry.th, entry.en)
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = COLOR_TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 7
	label.Parent = b

	local dot = Instance.new("Frame")
	dot.Name = "NewDot"
	dot.AnchorPoint = Vector2.new(1, 0.5)
	dot.Position = UDim2.new(1, -10, 0.5, 0)
	dot.Size = UDim2.new(0, 12, 0, 12)
	dot.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	dot.Visible = false
	dot.ZIndex = 7
	dot.Parent = b
	corner(dot)
	entryDots[entry.id] = dot

	entryButtons[i] = b
	entryLabels[entry.id] = label
	b.Activated:Connect(function()
		closeMenu()
		local g = playerGui:FindFirstChild(entry.gui)
		local ev = g and g:FindFirstChild(entry.event)
		if ev then ev:Fire() end
	end)
end

-- กรอบทองตอนเลือก (จอย)
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
corner(selectBox, 10)
do
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 190, 40); st.Thickness = 3.5; st.Parent = selectBox
end
for _, b in ipairs(entryButtons) do b.SelectionImageObject = selectBox end

-- ============ เปิด / ปิด ============
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(panel)
end
closeMenu = function()
	panel.Visible = false
	dimGui.Enabled = false
	if selectionInside() then GuiService.SelectedObject = nil end
end
-- ใช้ 2 คอลัมน์ทุกอุปกรณ์ แล้วปรับความกว้างตาม viewport
local function applyColumns()
	local vp = topGui.AbsoluteSize
	local grid = panel:FindFirstChild("EntryGrid")
	if not grid then return end
	local gap = 4
	local pad = 12 -- ขอบในของแผง 6+6
	-- จอแคบมาก: หดช่องให้พอดีจอ
	local cell = math.clamp(math.floor((vp.X - 16 - pad - gap) / 2), 130, 205)
	grid.CellSize = UDim2.fromOffset(cell, 42)
	grid.FillDirectionMaxCells = 2
	panel.Size = UDim2.new(0, cell * 2 + gap + pad, 0, 0)
	for _, b in ipairs(entryButtons) do
		for _, l in ipairs(b:GetChildren()) do
			if l:IsA("TextLabel") and l.TextXAlignment == Enum.TextXAlignment.Left then
				l.TextSize = 14
				l.TextTruncate = Enum.TextTruncate.AtEnd
			end
		end
	end
end

local function openMenu()
	-- รีเฟรชคำแปลทุกครั้งที่เปิด เผื่อผู้เล่นเปลี่ยนภาษา Roblox ระหว่างเล่น
	for _, entry in ipairs(ENTRIES) do
		local label = entryLabels[entry.id]
		if label then label.Text = tr(entry.th, entry.en) end
	end
	updateTutorialEntry()
	applyColumns()
	-- วางเมนูใต้ปุ่ม (พิกัดเดียวกับแถว: ลบจุดเริ่มของ TopbarRowGui)
	local origin = topGui.AbsolutePosition
	local x = moreButton.AbsolutePosition.X - origin.X
	local y = moreButton.AbsolutePosition.Y - origin.Y + moreButton.AbsoluteSize.Y + 6
	local maxX = math.max(0, topGui.AbsoluteSize.X - panel.Size.X.Offset - 8)
	panel.Position = UDim2.fromOffset(math.clamp(x, 0, maxX), y)
	panel.Visible = true
	dimGui.Enabled = true
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then
		GuiService.SelectedObject = entryButtons[1]
	end
end
moreButton.Activated:Connect(function()
	if panel.Visible then closeMenu() else openMenu() end
end)
-- ทดสอบใน Studio: เซิร์ฟเวอร์ตั้ง Attribute DevOpenMoreMenu = true บนผู้เล่น = เปิดเมนู
if game:GetService("RunService"):IsStudio() then
	player:GetAttributeChangedSignal("DevOpenMoreMenu"):Connect(function()
		if player:GetAttribute("DevOpenMoreMenu") then openMenu() end
	end)
end
dim.Activated:Connect(closeMenu)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and panel.Visible then closeMenu() end
end)

-- ============ รายการ "บทเรียน": ข้อความตามสถานะ ============
-- กำลังทำ (TutorialStep > 0) = ซ่อน/แสดงภารกิจ / จบหรือข้ามแล้วแต่ยังไม่เคยได้รางวัล = ทำบทเรียน · รับ 100,000 / ได้รางวัลแล้ว = เรียนวิธีเล่นอีกครั้ง
updateTutorialEntry = function()
	local label = entryLabels.tutorial
	if not label then return end
	local step = player:GetAttribute("TutorialStep") or 0
	if step > 0 then
		label.Text = tr("ซ่อน/แสดงภารกิจ", "Show/Hide Quests")
	elseif player:GetAttribute("TutorialRewarded") == false then
		label.Text = tr("ทำบทเรียน · รับ 100,000", "Tutorial · Get 100,000")
	else
		label.Text = tr("เรียนวิธีเล่นอีกครั้ง", "Replay Tutorial")
	end
end
player:GetAttributeChangedSignal("TutorialStep"):Connect(updateTutorialEntry)
player:GetAttributeChangedSignal("TutorialRewarded"):Connect(updateTutorialEntry)
updateTutorialEntry()

-- ============ จุดแดง: มีปลาใหม่ในสมุดสะสมปลา / ฟาร์มไก่ใหม่ (ยังไม่เคยเปิดหน้าต่างไก่ 2026-10-25) ============
local fishHasNew = false
local function refreshMoreDot()
	local chickenNew = player:GetAttribute("ChickenNew") == true
	-- สมุดพืช: มีรางวัลรอกดรับ (Attribute CropBookClaimable จาก CropBook) 2026-10-30
	local cropClaim = (tonumber(player:GetAttribute("CropBookClaimable")) or 0) > 0 and entryDots.cropbook ~= nil
	moreDot.Visible = fishHasNew or chickenNew or cropClaim
	if entryDots.warp then entryDots.warp.Visible = chickenNew end
	if entryDots.cropbook then entryDots.cropbook.Visible = cropClaim end
end
player:GetAttributeChangedSignal("ChickenNew"):Connect(refreshMoreDot)
player:GetAttributeChangedSignal("CropBookClaimable"):Connect(refreshMoreDot)
refreshMoreDot()
local function watchFishIndex(g)
	local function refresh()
		local has = g:GetAttribute("HasNew") == true
		fishHasNew = has
		entryDots.fish.Visible = has
		refreshMoreDot()
	end
	g:GetAttributeChangedSignal("HasNew"):Connect(refresh)
	refresh()
end
task.spawn(function()
	local g = playerGui:WaitForChild("FishIndexGui", 60)
	if g then watchFishIndex(g) end
end)
