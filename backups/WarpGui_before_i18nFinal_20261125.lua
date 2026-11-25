-- BACKUP of StarterPlayer.StarterPlayerScripts.WarpGui before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.WarpGui.Source in Studio
-- WarpGui: ปุ่ม 🧭 (แถวซ้ายบนข้างปุ่มเพลง) เปิดรายการจุดวาป: ร้านค้า + แหล่งตกปลา (ดู ReplicatedStorage.WarpConfig)
-- กดปุ่ม "ไป" -> ส่งรหัสจุดให้ WarpService (เซิร์ฟเวอร์พาไปเอง) แล้วปิดหน้าต่าง
-- แหล่งตกปลา: แสดงชื่อแหล่งน้ำ + ปลาที่เจอ (ดึงจาก FishingConfig)
-- จอย: เปิดแล้วเลือกปุ่ม "ไป" แรกให้ · ▲▼ เลื่อน · A วาป · B ปิด

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local WarpConfig = require(ReplicatedStorage:WaitForChild("WarpConfig"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local TopbarRow = require(script.Parent:WaitForChild("TopbarRow"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local warpRequest = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WarpRequest")

local player = Players.LocalPlayer
local lang = Localization.GetLanguage(player)
local function tr(th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end
local playerGui = player:WaitForChild("PlayerGui")

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_CARD = Color3.fromRGB(255, 240, 225)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_SUB = Color3.fromRGB(130, 100, 90)
local COLOR_BORDER = Color3.fromRGB(140, 100, 65)
local COLOR_GO = Color3.fromRGB(0, 176, 111)

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = obj; return c end
local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Parent = parent
	return l
end

-- ปลาที่เจอในแหล่งน้ำนี้ (ไม่รวมขยะ/ปลาอีเวนต์/ปลากลางคืน) เรียงจากราคาสูงไปต่ำ
local function fishText(zone)
	local list = {}
	for _, fish in pairs(FishingConfig.Fish) do
		if fish.Zone == zone and not fish.Junk and not fish.EventOnly and not fish.Night and not fish.Hidden and not fish.Retired then
			table.insert(list, { name = fish.Name, price = fish.Price or 0 })
		end
	end
	table.sort(list, function(a, b) return a.price > b.price end)
	local names = {}
	for i = 1, math.min(#list, 4) do names[i] = list[i].name end
	if #names == 0 then return "" end
	return "ปลา: " .. table.concat(names, " · ") .. (#list > 4 and " …" or "")
end

-- ============ ปุ่มในแถวซ้ายบน (ต่อจากปุ่มเพลง) ============
local topbarRow = TopbarRow.Get()
local openButton = Instance.new("TextButton")
openButton.Name = "WarpButton"
openButton.Size = UDim2.new(0, 44, 0, 44)
openButton.BackgroundColor3 = Color3.fromRGB(255, 250, 230)
openButton.Text = "🧭"
openButton.TextSize = 24
openButton.Font = Enum.Font.GothamBold
openButton.AutoButtonColor = true
openButton.Selectable = true
openButton.LayoutOrder = 2
openButton.Parent = topbarRow
openButton.Visible = false -- ย้ายไปอยู่ในเมนูเพิ่มเติม (MoreMenuGui) 2026-10-02
Instance.new("UICorner", openButton).CornerRadius = UDim.new(1, 0)
do
	local st = Instance.new("UIStroke")
	st.Color = COLOR_BORDER
	st.Thickness = 2
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = openButton
end

-- ============ หน้าต่าง ============
local gui = Instance.new("ScreenGui")
gui.Name = "WarpGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = playerGui

local WIDTH, HEIGHT = 400, 470
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
main.BackgroundColor3 = COLOR_BG
main.Active = true
main.SelectionGroup = true
main.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
main.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
main.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
main.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
main.Parent = gui
corner(main, 18)
do
	local st = Instance.new("UIStroke"); st.Color = COLOR_BORDER; st.Thickness = 3; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = main
end
local uiScale = Instance.new("UIScale")
uiScale.Parent = main
local camera = workspace.CurrentCamera
local function fit()
	local vp = camera.ViewportSize
	if vp.X < 2 then return end
	uiScale.Scale = math.clamp(math.min((vp.X - 24) / WIDTH, (vp.Y - 40) / HEIGHT), 0.5, 1)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = label(main, tr("🧭 วาป", "🧭 Warp"), 20, COLOR_TEXT, true)
title.Size = UDim2.new(1, -70, 0, 36)
title.Position = UDim2.new(0, 16, 0, 10)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.BackgroundColor3 = Color3.fromRGB(240, 120, 110)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Text = "X"
closeButton.Selectable = true
closeButton.Parent = main
corner(closeButton, 17)

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Position = UDim2.new(0, 12, 0, 54)
list.Size = UDim2.new(1, -24, 1, -66)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = COLOR_BORDER
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.Selectable = false
list.Parent = main
do
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = list
end

local goButtons = {} -- ตามลำดับที่แสดง (ไว้เลือกปุ่มแรกให้จอย)
local categoryLabels = {}
local destinationLabels = {}
local destinationDescLabels = {}
local clickLock = 0
local order = 0
local function nextOrder() order += 1 return order end

for _, cat in ipairs(WarpConfig.Categories) do
	local header = label(list, WarpConfig.TitleOf(cat, lang), 16, COLOR_TEXT, true)
	categoryLabels[cat.id] = header
	header.LayoutOrder = nextOrder()
	header.Size = UDim2.new(1, 0, 0, 26)
	for _, dest in ipairs(WarpConfig.Destinations) do
		if dest.Cat == cat.id then
			local descText = WarpConfig.DescOf(dest, lang)
			local hasDesc = descText ~= nil and descText ~= "" -- แหล่งตกปลาไม่มีคำอธิบาย/รายชื่อปลาแล้ว แถวสั้นลง
			local row = Instance.new("Frame")
			row.Name = "Row_" .. dest.Id
			row.LayoutOrder = nextOrder()
			row.Size = UDim2.new(1, 0, 0, hasDesc and 64 or 52)
			row.BackgroundColor3 = COLOR_CARD
			row.Parent = list
			corner(row, 12)
			if dest.MyLot then -- แปลงของฉัน: เห็นเฉพาะคนที่มีล็อกแล้ว (2026-11-07)
				local function refreshMyLot() row.Visible = player:GetAttribute("OrchardLot") ~= nil end
				player:GetAttributeChangedSignal("OrchardLot"):Connect(refreshMyLot)
				refreshMyLot()
			end

			local icon = label(row, dest.Icon, 28, COLOR_TEXT, true)
			icon.Size = UDim2.new(0, 40, 1, 0)
			icon.Position = UDim2.new(0, 8, 0, 0)
			icon.TextXAlignment = Enum.TextXAlignment.Center

			local name = label(row, WarpConfig.NameOf(dest, lang), hasDesc and 15 or 17, COLOR_TEXT, true)
			name.Position = hasDesc and UDim2.new(0, 54, 0, 6) or UDim2.new(0, 54, 0, 0)
			name.Size = hasDesc and UDim2.new(1, -150, 0, 20) or UDim2.new(1, -150, 1, 0)
			name.TextWrapped = false
			name.TextTruncate = Enum.TextTruncate.AtEnd
			destinationLabels[dest.Id] = name

			-- ป้าย "ใหม่!" จุดฟาร์มไก่ จนกว่าจะเปิดหน้าต่างไก่ครั้งแรก (Attribute ChickenNew จาก ChickenService) 2026-10-25
			-- 2026-11-18 ผู้ใช้สั่ง: ไม่แสดงป้ายนี้แล้ว (SHOW_CHICKEN_NEW = false) · คืน: backups/WarpGui_before_noChickenNew_20261118.lua
			local SHOW_CHICKEN_NEW = false
			if SHOW_CHICKEN_NEW and dest.Id == "chickenfarm" then
				local newTag = Instance.new("TextLabel")
				newTag.Name = "NewTag"
				newTag.AnchorPoint = Vector2.new(1, 0.5)
				newTag.Position = UDim2.new(1, -86, 0.5, 0)
				newTag.Size = UDim2.fromOffset(52, 22)
				newTag.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
				newTag.TextColor3 = Color3.new(1, 1, 1)
				newTag.Font = Enum.Font.GothamBlack
				newTag.TextSize = 13
				newTag.Text = tr("ใหม่!", "NEW!")
				newTag.ZIndex = (row.ZIndex or 1) + 2
				newTag.Parent = row
				corner(newTag, 11)
				local function refreshNew() newTag.Visible = player:GetAttribute("ChickenNew") == true end
				player:GetAttributeChangedSignal("ChickenNew"):Connect(refreshNew)
				refreshNew()
			end

			if hasDesc then
				local desc = label(row, descText, 12, COLOR_SUB, false)
				desc.Position = UDim2.new(0, 54, 0, 26)
				desc.Size = UDim2.new(1, -150, 0, 32)
				desc.TextYAlignment = Enum.TextYAlignment.Top
				destinationDescLabels[dest.Id] = desc
			end

			local go = Instance.new("TextButton")
			go.Name = "Go_" .. dest.Id
			go.AnchorPoint = Vector2.new(1, 0.5)
			go.Position = UDim2.new(1, -8, 0.5, 0)
			go.Size = UDim2.new(0, 72, 0, 36)
			go.BackgroundColor3 = COLOR_GO
			go.Font = Enum.Font.GothamBold
			go.TextSize = 16
			go.TextColor3 = Color3.new(1, 1, 1)
			go.Text = tr("ไป", "Go")
			go.Selectable = true
			go.Parent = row
			corner(go, 10)
			table.insert(goButtons, go)
			go.Activated:Connect(function()
				if os.clock() - clickLock < 1.5 then return end
				clickLock = os.clock()
				warpRequest:FireServer(dest.Id)
				gui.Enabled = false
			end)
		end
	end
end

-- รีเฟรชภาษาเมื่อเปิด เพื่อรองรับกรณีผู้เล่นเปลี่ยนภาษา Roblox ระหว่างเล่น
local function refreshLanguage()
	lang = Localization.GetLanguage(player)
	title.Text = tr("🧭 วาป", "🧭 Warp")
	for _, cat in ipairs(WarpConfig.Categories) do
		local header = categoryLabels[cat.id]
		if header then header.Text = WarpConfig.TitleOf(cat, lang) end
	end
	for _, dest in ipairs(WarpConfig.Destinations) do
		local name = destinationLabels[dest.Id]
		if name then name.Text = WarpConfig.NameOf(dest, lang) end
		local desc = destinationDescLabels[dest.Id]
		if desc then desc.Text = WarpConfig.DescOf(dest, lang) or "" end
	end
	for _, go in ipairs(goButtons) do go.Text = tr("ไป", "Go") end
end

-- ============ เปิด / ปิด (+ จอย) ============
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(main)
end
local function close()
	gui.Enabled = false
end
local function open()
	refreshLanguage()
	gui.Enabled = true
	list.CanvasPosition = Vector2.zero
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then
		GuiService.SelectedObject = goButtons[1] or closeButton
	end
end
openButton.Activated:Connect(function()
	if gui.Enabled then close() else open() end
end)
local openWarpEvent = Instance.new("BindableEvent")
openWarpEvent.Name = "OpenWarp" -- MoreMenuGui เรียก
openWarpEvent.Parent = gui
openWarpEvent.Event:Connect(function()
	if gui.Enabled then close() else open() end
end)
closeButton.Activated:Connect(close)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and gui.Enabled then close() end
end)
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not gui.Enabled and selectionInside() then GuiService.SelectedObject = nil end
end)

-- กรอบทองตอนเลือก (เหมือนหน้าต่างอื่น)
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
corner(selectBox, 10)
do
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 190, 40); st.Thickness = 3.5; st.Parent = selectBox
end
for _, d in ipairs(main:GetDescendants()) do
	if d:IsA("GuiButton") then d.SelectionImageObject = selectBox end
end
