-- BACKUP 2026-11-18 of game.StarterPlayer.StarterPlayerScripts.PetFoodGui before fix: collect fails/slow while cooking
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.PetFoodGui Source
-- PetFoodGui: หน้าต่างเครื่องทำอาหารสัตว์ (เปิดตอนกด E ที่ workspace.PetFoodMachine) + ป้ายสถานะเหนือเครื่อง (เห็นเฉพาะของเรา)
-- ทุกอย่างทำที่เซิร์ฟเวอร์ (PetFoodConverter) หน้าจอนี้แค่ส่งคำขอแล้วแสดงผล

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local request = remoteEvents:WaitForChild("PetFoodRequest")
local openEvent = remoteEvents:WaitForChild("PetFoodOpen")
-- ไทย/อังกฤษ ตามภาษาของผู้เล่น (2026-11-16) tr("ไทย", "English")
local tr = require(ReplicatedStorage:WaitForChild("Localization")).Tr()

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_SUB = Color3.fromRGB(130, 100, 90)
local COLOR_PINK = Color3.fromRGB(255, 200, 220)
local COLOR_GREEN = Color3.fromRGB(160, 230, 160)
local COLOR_GOLD = Color3.fromRGB(255, 215, 120)
local COLOR_DISABLED = Color3.fromRGB(215, 208, 205)
local CROP_ICON = {
	Strawberry = "🍓", Corn = "🌽", Wheat = "🌾", Onion = "🧅", Watermelon = "🍉",
	Pineapple = "🍍", Potato = "🥔", Cucumber = "🥒", Eggplant = "🍆", Pumpkin = "🎃", WitchBerry = "🍇",
	Carrot = "🥕",
	Sunflower = "🌻",
	Chili = "🌶️",
}

local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
-- วินาทีต่อถุง (แพ็กสุลต่านทำให้เป็นทศนิยมได้ เช่น 5.6)
local function secs(n)
	n = math.floor((tonumber(n) or 0) * 10 + 0.5) / 10
	return n == math.floor(n) and tostring(math.floor(n)) or tostring(n)
end
local function mmss(sec)
	sec = math.max(0, math.ceil(sec))
	if sec >= 3600 then return string.format("%d:%02d:%02d", sec // 3600, sec % 3600 // 60, sec % 60) end
	return string.format("%d:%02d", sec // 60, sec % 60)
end
local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = obj; return c end
local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 14
	l.TextColor3 = color or COLOR_TEXT
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextWrapped = true
	l.Parent = parent
	return l
end
local function button(parent, text, color)
	local b = Instance.new("TextButton")
	b.Text = text
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = COLOR_TEXT
	b.BackgroundColor3 = color or COLOR_PINK
	b.AutoButtonColor = true
	b.Selectable = true -- จอยเลือกได้ (กดด้วย Activated)
	b.TextWrapped = true
	b.Parent = parent
	corner(b, 10)
	return b
end

-- ============ หน้าต่าง ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetFoodGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local WIDTH, HEIGHT = 580, 400
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COLOR_BG
main.Active = true
-- จอย: การเลือกวนอยู่ในหน้าต่าง ไม่หลุดไปปุ่มอื่นบนจอ
main.SelectionGroup = true
main.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
main.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
main.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
main.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
main.Parent = screenGui
corner(main, 16)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(140, 100, 65); mainStroke.Thickness = 2; mainStroke.Parent = main
local uiScale = Instance.new("UIScale"); uiScale.Parent = main
local camera = workspace.CurrentCamera
local function fit()
	local vp = camera.ViewportSize
	if vp.X < 2 then return end
	uiScale.Scale = math.clamp(math.min((vp.X - 24) / WIDTH, (vp.Y - 40) / HEIGHT), 0.5, 1)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = label(main, tr("🥫 เครื่องทำอาหารสัตว์", "🥫 Pet Food Machine"), 20, COLOR_TEXT, true)
title.Size = UDim2.new(1, -60, 0, 36)
title.Position = UDim2.new(0, 16, 0, 8)
title.TextXAlignment = Enum.TextXAlignment.Left
local closeButton = button(main, "X", Color3.fromRGB(255, 190, 190))
closeButton.Name = "Close"
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.TextSize = 16
closeButton.Activated:Connect(function() screenGui.Enabled = false end)

local recipe = label(main, "", 12, COLOR_SUB)
recipe.Size = UDim2.new(1, -32, 0, 18)
recipe.Position = UDim2.new(0, 16, 0, 42)
recipe.TextXAlignment = Enum.TextXAlignment.Left
-- ข้อความยาว (ชามอัตโนมัติ / ภาษาอังกฤษ) ย่อตัวอักษรให้พอดีบรรทัด ไม่ล้นออกนอกกรอบ (2026-11-16)
recipe.TextScaled = true
do local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 12; c.MinTextSize = 8; c.Parent = recipe end

-- ซ้าย: สถานะเครื่อง
local left = Instance.new("Frame")
left.BackgroundColor3 = Color3.fromRGB(255, 240, 235)
left.Size = UDim2.new(0, 262, 1, -78)
left.Position = UDim2.new(0, 16, 0, 64)
left.Parent = main
corner(left, 12)

local workTitle = label(left, tr("⚙️ กำลังทำ", "⚙️ Cooking"), 14, COLOR_TEXT, true)
workTitle.Size = UDim2.new(1, -20, 0, 20)
workTitle.Position = UDim2.new(0, 10, 0, 8)
workTitle.TextXAlignment = Enum.TextXAlignment.Left
local workText = label(left, "", 12, COLOR_SUB)
workText.Size = UDim2.new(1, -20, 0, 32)
workText.Position = UDim2.new(0, 10, 0, 28)
workText.TextXAlignment = Enum.TextXAlignment.Left
workText.TextYAlignment = Enum.TextYAlignment.Top
local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -20, 0, 12)
barBack.Position = UDim2.new(0, 10, 0, 62)
barBack.BackgroundColor3 = Color3.fromRGB(225, 215, 210)
barBack.BorderSizePixel = 0
barBack.Parent = left
corner(barBack, 6)
local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(240, 140, 180)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
corner(barFill, 6)

local readyTitle = label(left, tr("✅ พร้อมรับ", "✅ Ready"), 14, COLOR_TEXT, true)
readyTitle.Size = UDim2.new(1, -20, 0, 20)
readyTitle.Position = UDim2.new(0, 10, 0, 84)
readyTitle.TextXAlignment = Enum.TextXAlignment.Left
local readyText = label(left, "", 12, COLOR_SUB)
readyText.Size = UDim2.new(1, -20, 0, 18)
readyText.Position = UDim2.new(0, 10, 0, 104)
readyText.TextXAlignment = Enum.TextXAlignment.Left
local collectButton = button(left, "", COLOR_GREEN)
collectButton.Name = "Collect"
collectButton.Size = UDim2.new(1, -20, 0, 38)
collectButton.Position = UDim2.new(0, 10, 0, 126)
collectButton.TextSize = 15

local speedTitle = label(left, "", 14, COLOR_TEXT, true)
speedTitle.Size = UDim2.new(1, -20, 0, 20)
speedTitle.Position = UDim2.new(0, 10, 0, 176)
speedTitle.TextXAlignment = Enum.TextXAlignment.Left
local upgradeButton = button(left, "", COLOR_GOLD)
upgradeButton.Name = "Upgrade"
upgradeButton.Size = UDim2.new(1, -20, 0, 40)
upgradeButton.Position = UDim2.new(0, 10, 0, 198)

local statusLabel = label(left, "", 12, Color3.fromRGB(40, 150, 60), true)
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 246)
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

-- ขวา: ผลผลิตในกระเป๋า
local rightTitle = label(main, tr("🧺 ผลผลิต & ปลาในกระเป๋า", "🧺 Crops & fish in your bag"), 14, COLOR_TEXT, true)
rightTitle.Size = UDim2.new(1, -310, 0, 20)
rightTitle.Position = UDim2.new(0, 292, 0, 64)
rightTitle.TextXAlignment = Enum.TextXAlignment.Left
local right = Instance.new("ScrollingFrame")
right.BackgroundColor3 = Color3.fromRGB(255, 244, 240)
right.Size = UDim2.new(1, -308, 1, -106)
right.Position = UDim2.new(0, 292, 0, 88)
right.ScrollBarThickness = 6
right.AutomaticCanvasSize = Enum.AutomaticSize.Y
right.CanvasSize = UDim2.new()
right.BorderSizePixel = 0
right.Selectable = false
right.Parent = main
corner(right, 12)
local rightPad = Instance.new("UIPadding"); rightPad.PaddingTop = UDim.new(0, 6); rightPad.PaddingLeft = UDim.new(0, 6); rightPad.PaddingRight = UDim.new(0, 12); rightPad.PaddingBottom = UDim.new(0, 6); rightPad.Parent = right
local rightLayout = Instance.new("UIListLayout"); rightLayout.Padding = UDim.new(0, 6); rightLayout.SortOrder = Enum.SortOrder.LayoutOrder; rightLayout.Parent = right

-- ============ ป๊อปอัพยืนยันก่อนใส่จำนวน ============
local confirmOverlay = Instance.new("TextButton") -- ปุ่มเต็มหน้าต่าง กันกดของข้างหลัง
confirmOverlay.Name = "ConfirmOverlay"
confirmOverlay.Text = ""
confirmOverlay.AutoButtonColor = false
confirmOverlay.Selectable = false
confirmOverlay.Size = UDim2.fromScale(1, 1)
confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.45
confirmOverlay.ZIndex = 20
confirmOverlay.Visible = false
confirmOverlay.Parent = main
corner(confirmOverlay, 16)
local confirmBox = Instance.new("Frame")
confirmBox.Size = UDim2.new(0, 320, 0, 170)
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBox.Position = UDim2.fromScale(0.5, 0.5)
confirmBox.BackgroundColor3 = COLOR_BG
confirmBox.ZIndex = 21
confirmBox.Active = true
confirmBox.SelectionGroup = true
confirmBox.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
confirmBox.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
confirmBox.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
confirmBox.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
confirmBox.Parent = confirmOverlay
corner(confirmBox, 14)
do local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(140, 100, 65); st.Thickness = 2; st.Parent = confirmBox end
local confirmTitle = label(confirmBox, tr("ยืนยันการใส่", "Confirm"), 16, COLOR_TEXT, true)
confirmTitle.Size = UDim2.new(1, -24, 0, 26)
confirmTitle.Position = UDim2.new(0, 12, 0, 10)
confirmTitle.ZIndex = 22
local confirmText = label(confirmBox, "", 13, COLOR_SUB)
confirmText.Size = UDim2.new(1, -24, 0, 70)
confirmText.Position = UDim2.new(0, 12, 0, 38)
confirmText.ZIndex = 22
local confirmYes = button(confirmBox, tr("✅ ยืนยัน", "✅ Confirm"), COLOR_GREEN)
confirmYes.Name = "ConfirmYes"
confirmYes.Size = UDim2.new(0.5, -18, 0, 38)
confirmYes.Position = UDim2.new(0, 12, 1, -50)
confirmYes.TextSize = 14
confirmYes.ZIndex = 22
local confirmNo = button(confirmBox, tr("ยกเลิก", "Cancel"), COLOR_DISABLED)
confirmNo.Name = "ConfirmNo"
confirmNo.Size = UDim2.new(0.5, -18, 0, 38)
confirmNo.Position = UDim2.new(0.5, 6, 1, -50)
confirmNo.TextSize = 14
confirmNo.ZIndex = 22
local confirmAction -- ฟังก์ชันที่จะทำเมื่อกดยืนยัน
local confirmReturnTo -- ปุ่มที่จอยเลือกอยู่ก่อนเปิดป๊อปอัพ
local function closeConfirm()
	confirmOverlay.Visible = false
	confirmAction = nil
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(confirmBox) then
		-- รายการขวาอาจถูกสร้างใหม่ระหว่างเปิดป๊อปอัพ ปุ่มเดิมหาย = หาปุ่มชื่อเดิมในหน้าต่างแทน
		local target = confirmReturnTo
		if target and not target.Parent then target = main:FindFirstChild(target.Name, true) end
		GuiService.SelectedObject = target
	end
end
local function askConfirm(text, onYes)
	confirmText.Text = text
	confirmAction = onYes
	confirmReturnTo = GuiService.SelectedObject
	confirmOverlay.Visible = true
	if confirmReturnTo then GuiService.SelectedObject = confirmYes end
end
confirmYes.Activated:Connect(function()
	local action = confirmAction
	closeConfirm()
	if action then action() end
end)
confirmNo.Activated:Connect(closeConfirm)
confirmOverlay.Activated:Connect(closeConfirm)

-- ============ แสดงผล ============
local info -- ข้อมูลล่าสุดจากเซิร์ฟเวอร์
local inputAmounts = {} -- เก็บจำนวนที่กรอกไว้ระหว่างหน้าจอรีเฟรช
local timeOffset = 0 -- เวลาเซิร์ฟเวอร์ - เวลาเครื่องเรา
local working = false
local doRequest -- ประกาศก่อน (ปุ่มในรายการเรียกใช้)

local function serverNow()
	return os.clock() + timeOffset
end

local function setStatus(text, good)
	statusLabel.Text = text or ""
	statusLabel.TextColor3 = good and Color3.fromRGB(40, 150, 60) or Color3.fromRGB(200, 80, 80)
end

local function starText(star) return string.rep("⭐", star) end
-- ชื่อกองในกระเป๋ามีดาว + "x2489" ต่อท้าย ตัดออกให้เหลือแค่ชื่อ (ป๊อปอัพยืนยันใส่ดาวเอง, 2026-11-16)
local STAR_SUFFIXES = { "★", "⭐", "☆", " " }
local function plainName(n)
	n = (tostring(n or ""):gsub("%s*[xX]%s*%d+$", ""))
	local cut = true
	while cut do
		cut = false
		for _, suf in ipairs(STAR_SUFFIXES) do
			if #n > #suf and n:sub(-#suf) == suf then n = n:sub(1, -#suf - 1); cut = true end
		end
	end
	return n
end

local function quantityInput(row, stack, maxCount, onSubmit)
	local key = stack.CropType .. "_" .. tostring(stack.Star)
	local box = Instance.new("TextBox")
	box.Name = "Amount_" .. key
	box.Size = UDim2.new(0, 48, 0, 34)
	box.Position = UDim2.new(0, 8, 0, 30)
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.TextColor3 = COLOR_TEXT
	box.PlaceholderText = "x"
	box.PlaceholderColor3 = COLOR_SUB
	box.Text = tostring(math.clamp(math.floor(tonumber(inputAmounts[key]) or 1), 1, math.max(maxCount, 1)))
	box.TextSize = 14
	box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false
	box.Selectable = true
	box.Parent = row
	corner(box, 8)
	local sanitizing = false
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if sanitizing then return end
		local cleaned = box.Text:gsub("%D", ""):sub(1, 6)
		if cleaned ~= box.Text then
			sanitizing = true
			box.Text = cleaned
			sanitizing = false
		end
		inputAmounts[key] = cleaned
	end)
	local make = button(row, tr("ใส่จำนวน", "Add"), maxCount > 0 and COLOR_PINK or COLOR_DISABLED)
	make.Name = "One_" .. key
	make.Size = UDim2.new(0, 64, 0, 34)
	make.Position = UDim2.new(0, 62, 0, 30)
	make.TextSize = 11
	local function submit()
		local amount = math.floor(tonumber(box.Text) or 1)
		amount = math.clamp(amount, 1, math.max(maxCount, 1))
		box.Text = tostring(amount)
		inputAmounts[key] = box.Text
		if maxCount > 0 then onSubmit(amount) end
	end
	make.Activated:Connect(submit)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then submit() else
			local amount = math.clamp(math.floor(tonumber(box.Text) or 1), 1, math.max(maxCount, 1))
			box.Text = tostring(amount)
			inputAmounts[key] = box.Text
		end
	end)
end

-- ลายเซ็นของรายการขวา ข้อมูลเดิม = ไม่สร้างปุ่มใหม่ (เดิมสร้างใหม่ทุก 3 วิ กดตรงจังหวะที่ปุ่มถูกลบ = กดไม่ติด ต้องกดซ้ำ)
local lastStacksSig
local function stacksSig()
	local parts = { tostring(info.PerBag) }
	for _, s in ipairs(info.Stacks) do
		table.insert(parts, table.concat({ s.CropType, s.Star, s.Count, tostring(s.BagsPer), tostring(s.IsFish), s.Name }, "|"))
	end
	return table.concat(parts, ";")
end

local function renderStacks()
	if info then
		local sig = stacksSig()
		if sig == lastStacksSig then return false end
		lastStacksSig = sig
	else
		lastStacksSig = nil
	end
	for _, c in ipairs(right:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if not info then return true end
	if #info.Stacks == 0 then
		local empty = label(right, tr("ยังไม่มีผลผลิตหรือปลาในกระเป๋า\nเก็บเกี่ยวผักหรือตกปลาแล้วเอามาใส่เครื่องได้เลย", "No crops or fish in your bag yet\nHarvest crops or catch fish, then put them in the machine"), 12, COLOR_SUB)
		empty.Size = UDim2.new(1, 0, 0, 60)
		return true
	end
	for i, s in ipairs(info.Stacks) do
		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 70)
		row.BackgroundColor3 = Color3.fromRGB(235, 245, 225)
		row.Parent = right
		corner(row, 8)
		local name = label(row, (s.IsFish and "🐟" or (CROP_ICON[s.CropType] or "🌱")) .. " " .. s.Name, 12, COLOR_TEXT, true)
		name.Size = UDim2.new(1, -16, 0, 24)
		name.Position = UDim2.new(0, 8, 0, 2)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextYAlignment = Enum.TextYAlignment.Center
		name.TextWrapped = false
		name.TextTruncate = Enum.TextTruncate.AtEnd
		if s.IsFish then
			-- ปลา: ใส่ทีละตัว (ตัวละ BagsPer ถุง)
			row.BackgroundColor3 = Color3.fromRGB(215, 238, 245)
			local maxFish = s.Count
			quantityInput(row, s, maxFish, function(amount)
				askConfirm(string.format(tr("ได้อาหาร x%d ถุง\nใส่ 🐟 %s %s %d ตัว", "Makes x%d bags of food\nPut in 🐟 %s %s × %d"), amount * s.BagsPer, plainName(s.Name), starText(s.Star), amount),
					function() doRequest("insert", s.CropType, s.Star, amount) end)
			end)
			local all = button(row, tr("ใส่ทั้งหมด", "Add all") .. "\n(+" .. maxFish * s.BagsPer .. tr(" ถุง)", " bags)"), maxFish >= 1 and COLOR_GOLD or COLOR_DISABLED)
			all.Name = "All_" .. s.CropType .. "_" .. s.Star
			all.Size = UDim2.new(0, 70, 0, 34)
			all.Position = UDim2.new(0, 132, 0, 30)
			all.TextSize = 11
			if maxFish >= 1 then all.Activated:Connect(function()
				askConfirm(string.format(tr("ได้อาหาร x%d ถุง\nใส่ 🐟 %s %s %d ตัว", "Makes x%d bags of food\nPut in 🐟 %s %s × %d"), maxFish * s.BagsPer, plainName(s.Name), starText(s.Star), maxFish),
					function() doRequest("insert", s.CropType, s.Star, maxFish) end)
			end) end
			continue
		end
		-- ใส่ได้ตามจำนวนผลผลิตที่มีจริง โดยเซิร์ฟเวอร์ตรวจและจำกัดซ้ำอีกชั้น
		local maxBags = math.floor(s.Count / info.PerBag)
		quantityInput(row, s, maxBags, function(amount)
			askConfirm(string.format(tr("ได้อาหาร x%d ถุง\nใส่ %s %s %s %d ชิ้น", "Makes x%d bags of food\nPut in %s %s %s × %d"), amount, CROP_ICON[s.CropType] or "🌱", plainName(s.Name), starText(s.Star), amount * info.PerBag),
				function() doRequest("insert", s.CropType, s.Star, amount) end)
		end)
		local all = button(row, tr("ใส่ทั้งหมด", "Add all") .. "\n(" .. maxBags .. tr(" ถุง)", " bags)"), maxBags >= 1 and COLOR_GOLD or COLOR_DISABLED)
		all.Name = "All_" .. s.CropType .. "_" .. s.Star
		all.Size = UDim2.new(0, 70, 0, 34)
		all.Position = UDim2.new(0, 132, 0, 30)
		all.TextSize = 11
		if maxBags >= 1 then all.Activated:Connect(function()
			askConfirm(string.format(tr("ได้อาหาร x%d ถุง\nใส่ %s %s %s %d ชิ้น", "Makes x%d bags of food\nPut in %s %s %s × %d"), maxBags, CROP_ICON[s.CropType] or "🌱", plainName(s.Name), starText(s.Star), maxBags * info.PerBag),
				function() doRequest("insert", s.CropType, s.Star, maxBags) end)
		end) end
	end
end

-- ปุ่ม "ใส่ 1" ของแถวบนสุดในรายการผลผลิต (ดูจาก LayoutOrder เพราะตำแหน่งบนจอยังไม่อัปเดตทันทีหลังสร้าง)
local function firstStackButton()
	local bestRow
	for _, row in ipairs(right:GetChildren()) do
		if row:IsA("Frame") and row:FindFirstChildWhichIsA("GuiButton") and (not bestRow or row.LayoutOrder < bestRow.LayoutOrder) then
			bestRow = row
		end
	end
	if not bestRow then return nil end
	for _, d in ipairs(bestRow:GetChildren()) do
		if d:IsA("GuiButton") and d.Name:sub(1, 4) == "One_" then return d end
	end
	return bestRow:FindFirstChildWhichIsA("GuiButton")
end

local function renderStatic()
	if not info then return end
	local fb = info.FishBags or {}
	recipe.Text = string.format(tr("สูตร: ผลผลิต %d ชิ้น (ดาวเดียวกัน) = 1 ถุง · ปลา 1 ตัว = %d/%d/%d/%d ถุง (ธรรมดา/หายาก/ตำนาน/ลับ) · ออกเกมได้ เครื่องทำต่อ",
		"Recipe: %d crops (same ⭐) = 1 bag · 1 fish = %d/%d/%d/%d bags (Common/Rare/Legendary/Secret) · works offline"),
		info.PerBag, fb.Common or 1, fb.Rare or 2, fb.Legendary or 4, fb.Secret or 8)
	if info.AutoToBowl then
		local limit = require(ReplicatedStorage:WaitForChild("AutoFeederConfig")).AUTO_FILL_BELOW
		local bowl = player:GetAttribute("AutoFeederFood") -- nil = เซิร์ฟเวอร์ยังโหลดชามไม่เสร็จ
		recipe.Text = tr("🥣 มีชามอาหารอัตโนมัติ: อาหารที่ทำเสร็จไหลเข้าชามเอง · ถ้าในชามมี ", "🥣 Auto-bowl: food goes to the bowl · waits here at ") .. commas(limit)
			.. tr(" ถุงขึ้นไป จะรอรับที่เครื่อง (ตอนนี้ในชาม ", "+ (bowl: ")
			.. (bowl and (commas(bowl) .. tr(" ถุง", " bags") .. (bowl >= limit and tr(" · รอรับที่เครื่อง", " · collect here") or "")) or tr("⏳ กำลังโหลด...", "⏳ Loading...")) .. ")"
	end
	-- พร้อมรับ
	local parts = {}
	for star = 5, 1, -1 do
		local n = info.Ready[star] or 0
		if n > 0 then table.insert(parts, starText(star) .. " x" .. n) end
	end
	readyText.Text = #parts > 0 and table.concat(parts, "  ") or tr("ยังไม่มี", "None yet")
	collectButton.Text = info.ReadyTotal > 0 and (tr("🥫 รับอาหาร (", "🥫 Collect (") .. info.ReadyTotal .. tr(" ถุง)", " bags)")) or tr("ยังไม่มีอาหารให้รับ", "Nothing to collect yet")
	collectButton.BackgroundColor3 = info.ReadyTotal > 0 and COLOR_GREEN or COLOR_DISABLED
	-- ความเร็ว
	speedTitle.Text = string.format(tr("⚡ ความเร็ว Lv.%d/%d · %s วิ/ถุง%s", "⚡ Speed Lv.%d/%d · %ss/bag%s"), info.Level, info.MaxLevel, secs(info.Seconds), info.SultanSpeed and " 👑" or "")
	if info.NextCost then
		upgradeButton.Text = string.format(tr("อัปเกรด → %s วิ/ถุง\n💰 %s", "Upgrade → %ss/bag\n💰 %s"), secs(info.NextSeconds), commas(info.NextCost))
		upgradeButton.BackgroundColor3 = COLOR_GOLD
	else
		upgradeButton.Text = tr("ความเร็วสูงสุดแล้ว ✨", "Max speed ✨")
		upgradeButton.BackgroundColor3 = COLOR_DISABLED
	end
	-- รายการขวาถูกสร้างใหม่ทุกครั้ง จอยเลือกปุ่มไหนอยู่ เลือกปุ่มชื่อเดิมกลับให้ (ไม่เด้งหาย)
	local prev = GuiService.SelectedObject
	local prevName = prev and prev:IsDescendantOf(right) and prev.Name
	if renderStacks() and prevName then
		local target = right:FindFirstChild(prevName, true)
		if not (target and target:IsA("GuiButton")) then
			target = firstStackButton()
		end
		GuiService.SelectedObject = target or collectButton
	end
end

-- แถบความคืบหน้า + เวลาที่เหลือ (คำนวณเองทุกเฟรมจากข้อมูลล่าสุด)
local function renderProgress()
	if not info then return end
	if info.Queued <= 0 then
		workText.Text = tr("เครื่องว่างอยู่ · เลือกผลผลิตทางขวาแล้วกดใส่", "Machine is idle · pick something on the right and add it")
		barFill.Size = UDim2.new(0, 0, 1, 0)
		return
	end
	local elapsed = serverNow() - info.Cursor
	local per = info.Seconds
	local doneSince = math.floor(elapsed / per) -- ถุงที่น่าจะเสร็จไปแล้วตั้งแต่ข้อมูลล่าสุด
	local left = math.max(0, info.Queued - doneSince)
	if left <= 0 then
		workText.Text = tr("ทำเสร็จแล้ว กำลังอัปเดต...", "Done, updating...")
		barFill.Size = UDim2.new(1, 0, 1, 0)
		return
	end
	local frac = (elapsed % per) / per
	local stars = {}
	for _, e in ipairs(info.Queue) do table.insert(stars, starText(e.star) .. " x" .. e.bags) end
	workText.Text = string.format(tr("เหลือ %d ถุง · ถุงถัดไป %s · เสร็จทั้งหมด %s\n%s", "%d bags left · next %s · all done in %s\n%s"),
		left, mmss(per - (elapsed % per)), mmss(per * left - (elapsed % per)), table.concat(stars, "  "))
	barFill.Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0)
end

local function applyResult(res)
	if res and res.info then
		info = res.info
		timeOffset = info.Now - os.clock()
		renderStatic()
		renderProgress()
	end
end

doRequest = function(action, a, b, c)
	if working then
		if action == "info" then return end
		-- กดตรงกับตอนขอข้อมูลอัตโนมัติค้างอยู่: รอให้เสร็จแล้วทำต่อ (เดิมทิ้งเงียบๆ ต้องกดซ้ำ)
		local waited = 0
		while working and waited < 10 do waited += task.wait() end
		if working then return end
	end
	working = true
	setStatus(tr("กำลังดำเนินการ...", "Working..."), true)
	local ok, res = pcall(function() return request:InvokeServer(action, a, b, c) end)
	working = false
	if not ok or not res then
		setStatus(tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't connect, please try again"))
		return
	end
	applyResult(res)
	if action == "info" then setStatus("") else setStatus(res.message, res.ok) end
end

collectButton.Activated:Connect(function()
	if info and info.ReadyTotal > 0 then doRequest("collect") end
end)
upgradeButton.Activated:Connect(function()
	if info and info.NextCost then doRequest("upgrade") end
end)

local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(main)
end


openEvent.OnClientEvent:Connect(function()
	screenGui.Enabled = true
	setStatus("")
	doRequest("info")
	-- เปิดด้วยจอย = เลือกปุ่มให้เลย (มีอาหารพร้อมรับ = ปุ่มรับ / ไม่มี = ปุ่มใส่ผลผลิตแถวแรก)
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] and screenGui.Enabled and not selectionInside() then
		local target = (info and info.ReadyTotal > 0) and collectButton or firstStackButton() or upgradeButton
		GuiService.SelectedObject = target
	end
end)

-- จอย: B = ปิดหน้าต่าง / ปิดแล้วปล่อยการเลือก
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and screenGui.Enabled then
		if confirmOverlay.Visible then closeConfirm() return end -- B ตอนป๊อปอัพเปิด = ยกเลิกป๊อปอัพก่อน
		screenGui.Enabled = false
	end
end)
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screenGui.Enabled then confirmOverlay.Visible = false; confirmAction = nil end
	if not screenGui.Enabled and selectionInside() then GuiService.SelectedObject = nil end
end)

-- กรอบทองตอนเลือก (เหมือนหน้าต่างอื่น) ติดให้ทุกปุ่มในหน้าต่าง (รวมปุ่มในรายการที่สร้างใหม่ทีหลัง)
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = selectBox
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 190, 40); st.Thickness = 3.5; st.Parent = selectBox
end
local function styleSelectable(obj)
	if obj:IsA("GuiButton") then obj.SelectionImageObject = selectBox end
end
for _, d in ipairs(main:GetDescendants()) do styleSelectable(d) end
main.DescendantAdded:Connect(styleSelectable)

-- เปิดอยู่: ขยับแถบทุกเฟรม + ขอข้อมูลใหม่เป็นระยะ (ถุงเสร็จ / ผลผลิตในกระเป๋าเปลี่ยน)
local sinceRefresh = 0
RunService.Heartbeat:Connect(function(dt)
	if not screenGui.Enabled then return end
	renderProgress()
	sinceRefresh += dt
	if sinceRefresh >= 3 and not working and not UserInputService:GetFocusedTextBox() then
		sinceRefresh = 0
		task.spawn(doRequest, "info")
	end
end)

-- ============ ป้ายเหนือเครื่อง (เห็นเฉพาะของเรา) + เครื่องสั่นเบาๆ ตอนกำลังทำ ============
task.spawn(function()
	local machine = workspace:WaitForChild("PetFoodMachine", 30)
	if not machine then return end
	-- แมพโหลดทีละส่วนตามระยะ (streaming) ชิ้นส่วนของเครื่องอาจยังมาไม่ถึงตอนสคริปต์เริ่ม รอให้มาก่อน
	local part = machine:FindFirstChildWhichIsA("BasePart", true)
	while not part do
		machine.DescendantAdded:Wait()
		part = machine:FindFirstChildWhichIsA("BasePart", true)
	end
	local cf, size = machine:GetBoundingBox()
	local bb = Instance.new("BillboardGui")
	bb.Name = "PetFoodStatus"
	bb.Adornee = part
	bb.Size = UDim2.new(0, 200, 0, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, cf.Position.Y + size.Y / 2 - part.Position.Y + 1.6, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = screenGui.Parent
	local title2 = label(bb, tr("🥫 เครื่องทำอาหารสัตว์", "🥫 Pet Food Machine"), 14, Color3.new(1, 1, 1), true)
	title2.Size = UDim2.new(1, 0, 0.5, 0)
	local s1 = Instance.new("UIStroke"); s1.Color = Color3.fromRGB(70, 45, 35); s1.Thickness = 1.5; s1.Parent = title2
	local line = label(bb, "", 13, Color3.fromRGB(255, 225, 150), true)
	line.Size = UDim2.new(1, 0, 0.5, 0)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	local s2 = Instance.new("UIStroke"); s2.Color = Color3.fromRGB(70, 45, 35); s2.Thickness = 1.5; s2.Parent = line
	local function update()
		local q = player:GetAttribute("PetFoodQueue") or 0
		local r = player:GetAttribute("PetFoodReady") or 0
		if r > 0 then
			line.Text = tr("✅ พร้อมรับ ", "✅ Ready: ") .. r .. tr(" ถุง", " bags") .. (q > 0 and (tr(" · กำลังทำ ", " · cooking ") .. q) or "")
		elseif q > 0 then
			line.Text = tr("⚙️ กำลังทำ ", "⚙️ Cooking ") .. q .. tr(" ถุง", " bags")
		else
			line.Text = tr("ใส่ผลผลิต 2 ชิ้น = อาหาร 1 ถุง", "2 crops = 1 bag of food")
		end
	end
	player:GetAttributeChangedSignal("PetFoodQueue"):Connect(update)
	player:GetAttributeChangedSignal("PetFoodReady"):Connect(update)
	update()
	-- สั่น/เด้งเบาๆ ฝั่งเราเท่านั้นตอนเครื่องกำลังทำของเรา
	local base = machine:GetPivot()
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		if (player:GetAttribute("PetFoodQueue") or 0) > 0 then
			t += dt
			machine:PivotTo(base * CFrame.new(0, math.abs(math.sin(t * 9)) * 0.08, 0) * CFrame.Angles(0, 0, math.sin(t * 23) * 0.012))
		elseif t ~= 0 then
			t = 0
			machine:PivotTo(base)
		end
	end)
end)
