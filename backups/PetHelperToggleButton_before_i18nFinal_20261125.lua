-- BACKUP of StarterPlayer.StarterPlayerScripts.PetHelperToggleButton before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.PetHelperToggleButton.Source in Studio
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local petAbilityToggle = remoteEvents:WaitForChild("PetAbilityToggle")
local petAbilitiesInfo = remoteEvents:WaitForChild("PetAbilitiesInfo")
local petListInfo = remoteEvents:WaitForChild("PetListInfo")
local petSelect = remoteEvents:WaitForChild("PetSelect")
local PetRarity = require(ReplicatedStorage:WaitForChild("PetRarity"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local tr, lang = Localization.Tr()

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetMenuGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 6
-- พิกัด y เริ่มจากขอบบนของพื้นที่ปลอดภัยของอุปกรณ์ (ไม่ใช่ใต้แถบ Roblox) เพื่อวางให้กึ่งกลางเสมอกับปุ่มเมนู/ไมค์ของ Roblox
-- ปุ่มแถบบนของ Roblox สูง 44 เว้นจากขอบบน 12 => กึ่งกลางที่ y=34 คงที่ทุกอุปกรณ์
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Parent = playerGui

-- ปุ่มเปิด/ปิดเมนู
local openButton = Instance.new("TextButton")
openButton.Name = "OpenPetMenuButton"
openButton.Size = UDim2.new(0, 44, 0, 44) -- เท่าปุ่มของ Roblox และปุ่มกระเป๋า (FullInventoryGui)
openButton.AnchorPoint = Vector2.new(1, 0.5)
-- แถวเดียวกับปุ่มกระเป๋าที่มุมขวาบน: ปุ่มกระเป๋าอยู่ขวา -68 กว้าง 44 เว้น 8 => -120
-- (ถ้าเปลี่ยนตำแหน่ง/ขนาดปุ่มกระเป๋า ต้องปรับเลขนี้ตาม)
openButton.Position = UDim2.new(1, -172, 0, 34) -- ถัดจากปุ่มตู้ตกแต่ง 🪑 (-120) (2026-10-30)
openButton.BackgroundColor3 = Color3.fromRGB(255, 220, 235)
openButton.Text = "🐾"
openButton.TextSize = 26
openButton.Font = Enum.Font.GothamBold
openButton.Selectable = false
openButton.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton
local openStroke = Instance.new("UIStroke") -- ขอบน้ำตาลเหมือนปุ่มกระเป๋า ให้เข้าชุดกัน
openStroke.Color = Color3.fromRGB(140, 100, 65)
openStroke.Thickness = 2
openStroke.Parent = openButton

-- กรอบเมนูหลัก
local mainFrame = Instance.new("Frame")
mainFrame.Name = "PetMenuFrame"
-- แบ่งเนื้อหาเป็น 2 แท็บ (สัตว์เลี้ยง / ความสามารถ) แต่ละแท็บเลื่อนได้เอง เนื้อหาเพิ่มกี่บรรทัดก็ไม่ล้นกรอบ
-- (เดิมวางรายชื่อสัตว์ + ปุ่มความสามารถ + หมายเหตุ ซ้อนลงมาในกรอบสูงคงที่ พอมีความสามารถ "นำโชค" เพิ่มมาก็ล้นออกข้างล่าง)
local MENU_HEIGHT = 400
local CONTENT_TOP = 84 -- ใต้หัวข้อ + แถบแท็บ
mainFrame.Size = UDim2.new(0, 320, 0, MENU_HEIGHT)
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = UDim2.new(1, -16, 0, 72) -- เปิดใต้แถวปุ่ม ชิดขวา
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 250, 245)
mainFrame.Visible = false
-- จอย: การเลือกวนอยู่ในเมนู ไม่หลุดไปปุ่มอื่นบนจอ
mainFrame.SelectionGroup = true
mainFrame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
mainFrame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
mainFrame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
mainFrame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- เมนูสูง 400 ล้นจอมือถือแนวนอน (~373) จึงย่อตามความสูงจอ โดยย่อเข้าหามุมขวาบนที่ยึดไว้
local menuScale = Instance.new("UIScale")
menuScale.Parent = mainFrame
local menuCamera = workspace.CurrentCamera
local function fitMenu()
	local vp = menuCamera.ViewportSize
	if vp.Y < 2 then return end
	menuScale.Scale = math.clamp((vp.Y - 96) / MENU_HEIGHT, 0.5, 1)
end
fitMenu()
menuCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMenu)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = tr("🐾 สัตว์เลี้ยงของฉัน", "🐾 My Pets")
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(80, 50, 40)
title.Parent = mainFrame

-- รายการสัตว์เลี้ยง (เลื่อนได้)
-- แถบแท็บ
local TAB_ACTIVE = Color3.fromRGB(255, 200, 220)
local TAB_INACTIVE = Color3.fromRGB(240, 228, 222)

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 34)
tabBar.Position = UDim2.new(0, 10, 0, 42)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local function createTab(name, text, order)
	local tab = Instance.new("TextButton")
	tab.Name = name
	tab.LayoutOrder = order
	tab.Size = UDim2.new(1 / 3, -6, 1, 0) -- 3 แท็บ (สัตว์เลี้ยง / ความสามารถ / สมุด)
	tab.BackgroundColor3 = TAB_INACTIVE
	tab.AutoButtonColor = false
	tab.Text = text
	tab.Font = Enum.Font.GothamBold
	tab.TextScaled = true -- แท็บแคบลง ให้ตัวอักษรหดเองถ้าไม่พอ
	local tabTextSize = Instance.new("UITextSizeConstraint")
	tabTextSize.MaxTextSize = 14
	tabTextSize.MinTextSize = 8
	tabTextSize.Parent = tab
	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingLeft = UDim.new(0, 4)
	tabPad.PaddingRight = UDim.new(0, 4)
	tabPad.Parent = tab
	tab.TextColor3 = Color3.fromRGB(80, 50, 40)
	tab.Selectable = true
	tab.Parent = tabBar
	Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 10)
	return tab
end

local petsTab = createTab("PetsTab", tr("🐾 สัตว์เลี้ยง", "🐾 Pets"), 1)
local abilitiesTab = createTab("AbilitiesTab", tr("✨ ความสามารถ", "✨ Abilities"), 2)
local bookTab = createTab("BookTab", tr("📖 สมุด", "📖 Book"), 3) -- สมุดสัตว์เลี้ยง: ทุกชนิด (มีแล้ว / ยังไม่มีเป็นเงา)

-- ============ แถบช่องสัตว์ (ล่างสุดของแท็บสัตว์เลี้ยง): พาออกมา x/2 + ปุ่มซื้อ Game Pass "ช่องสัตว์ +1" ============
local MarketplaceService = game:GetService("MarketplaceService")
local PetSlotConfig = require(ReplicatedStorage:WaitForChild("PetSlotConfig"))
local slotBar = Instance.new("Frame")
slotBar.Name = "SlotBar"
slotBar.Size = UDim2.new(1, -20, 0, 40)
slotBar.Position = UDim2.new(0, 10, 1, -46)
slotBar.BackgroundColor3 = Color3.fromRGB(255, 240, 225)
slotBar.Parent = mainFrame
Instance.new("UICorner", slotBar).CornerRadius = UDim.new(0, 10)
local slotLabel = Instance.new("TextLabel")
slotLabel.BackgroundTransparency = 1
slotLabel.Position = UDim2.new(0, 10, 0, 0)
slotLabel.Size = UDim2.new(1, -150, 1, 0)
slotLabel.Font = Enum.Font.GothamBold
slotLabel.TextSize = 13
slotLabel.TextColor3 = Color3.fromRGB(80, 50, 40)
slotLabel.TextXAlignment = Enum.TextXAlignment.Left
slotLabel.Parent = slotBar
local slotBuy = Instance.new("TextButton")
slotBuy.Name = "BuySlotButton"
slotBuy.AnchorPoint = Vector2.new(1, 0.5)
slotBuy.Position = UDim2.new(1, -6, 0.5, 0)
slotBuy.Size = UDim2.new(0, 136, 0, 30)
slotBuy.Font = Enum.Font.GothamBold
slotBuy.TextSize = 12
slotBuy.TextColor3 = Color3.new(1, 1, 1)
slotBuy.AutoButtonColor = true
slotBuy.Selectable = true
slotBuy.Parent = slotBar
Instance.new("UICorner", slotBuy).CornerRadius = UDim.new(0, 8)
local slotPriceText = "…"
local function countActive()
	local n = 0
	for _, m in ipairs(workspace:GetChildren()) do
		-- ตัวที่ไม่ใช้ช่อง (Attribute FreeSlot บนโมเดล เช่น ซุกซน) ไม่นับ
		if m:IsA("Model") and m:GetAttribute("OwnerUserId") == player.UserId and m:GetAttribute("PetId") and not m:GetAttribute("FreeSlot") then n += 1 end
	end
	return n
end
local function renderSlotBar()
	local slots = player:GetAttribute("PetSlots") or PetSlotConfig.BASE_SLOTS
	local hasPass = slots > PetSlotConfig.BASE_SLOTS
	slotLabel.Text = tr(string.format("🐾 พาออกมา %d/%d ตัว", countActive(), slots), string.format("🐾 Active %d/%d", countActive(), slots))
	if hasPass then
		slotBuy.Text = tr("✓ ช่องสัตว์ +1", "✓ Pet Slot +1")
		slotBuy.BackgroundColor3 = Color3.fromRGB(120, 190, 120)
	else
		slotBuy.Text = tr("🔓 ช่องสัตว์ +1 · R$", "🔓 Pet Slot +1 · R$") .. slotPriceText
		slotBuy.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
	end
end
player:GetAttributeChangedSignal("PetSlots"):Connect(renderSlotBar)
workspace.ChildAdded:Connect(function(c) if c:IsA("Model") then task.defer(renderSlotBar) end end)
workspace.ChildRemoved:Connect(function(c) if c:IsA("Model") then task.defer(renderSlotBar) end end)
renderSlotBar()
task.spawn(function()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(PetSlotConfig.GAMEPASS_ID, Enum.InfoType.GamePass) end)
	if ok and info and info.PriceInRobux then
		slotPriceText = tostring(info.PriceInRobux)
		renderSlotBar()
	end
end)
slotBuy.Activated:Connect(function()
	if (player:GetAttribute("PetSlots") or PetSlotConfig.BASE_SLOTS) > PetSlotConfig.BASE_SLOTS then return end
	MarketplaceService:PromptGamePassPurchase(player, PetSlotConfig.GAMEPASS_ID)
end)

local petListFrame = Instance.new("ScrollingFrame")
petListFrame.Name = "PetList"
local FEEDER_BAR_H = 58 -- แถวชามอาหาร (50) + ระยะห่าง อยู่กับที่เหนือรายการ (ไม่เลื่อนตาม)
petListFrame.Size = UDim2.new(1, -20, 1, -(CONTENT_TOP + FEEDER_BAR_H + 58)) -- เว้นบนให้ชามอาหาร / ล่างให้แถบช่องสัตว์
petListFrame.Position = UDim2.new(0, 10, 0, CONTENT_TOP + FEEDER_BAR_H)
petListFrame.BackgroundTransparency = 1
petListFrame.ScrollBarThickness = 6
petListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
petListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
petListFrame.Parent = mainFrame

local petListLayout = Instance.new("UIListLayout")
petListLayout.Padding = UDim.new(0, 8)
petListLayout.SortOrder = Enum.SortOrder.LayoutOrder
petListLayout.Parent = petListFrame

-- เว้นขอบบน/ล่างเล็กน้อย ขอบสีความหายากจะได้ไม่โดนตัดทิ้ง
local petListPadding = Instance.new("UIPadding")
petListPadding.PaddingTop = UDim.new(0, 2)
petListPadding.PaddingBottom = UDim.new(0, 2)
petListPadding.PaddingLeft = UDim.new(0, 2)
petListPadding.Parent = petListFrame

-- ============ ชามอาหารอัตโนมัติ: แถวบนสุดของแท็บสัตว์เลี้ยง ============
-- ย้ายมาจากแผงสัตว์ที่ใช้อยู่ด้านขวาจอ (ActivePetsHud เลิกใช้ 2026-10-01) กดแล้วเปิดหน้าต่างชาม (AutoFeederGui)
-- ยังไม่มี Game Pass ก็กดดูได้ (หน้าต่างชามมีปุ่มซื้อ) / clearPetRows ไม่ลบแถวนี้ (ไม่ได้อยู่ใน petRows)
local AutoFeederConfig = require(ReplicatedStorage:WaitForChild("AutoFeederConfig"))
local FEEDER_ACCENT = Color3.fromRGB(236, 132, 170)
local feederRow = Instance.new("TextButton")
feederRow.Name = "FeederRow"
feederRow.LayoutOrder = 0
feederRow.Size = UDim2.new(1, -28, 0, 50) -- กว้างเท่าการ์ดสัตว์ในรายการ
feederRow.Position = UDim2.new(0, 10, 0, CONTENT_TOP) -- ติดอยู่ใต้แท็บ ไม่เลื่อนตามรายการ (ผู้เล่นขอ 2026-10-01)
feederRow.BackgroundColor3 = Color3.fromRGB(255, 244, 248)
feederRow.Text = ""
feederRow.AutoButtonColor = true
feederRow.Selectable = true
feederRow.Parent = mainFrame
Instance.new("UICorner", feederRow).CornerRadius = UDim.new(0, 8)
local feederStroke = Instance.new("UIStroke")
feederStroke.Thickness = 2
feederStroke.Color = FEEDER_ACCENT
feederStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
feederStroke.Parent = feederRow

local feederIcon = Instance.new("TextLabel")
feederIcon.Size = UDim2.new(0, 40, 0, 40)
feederIcon.Position = UDim2.new(0, 6, 0.5, -20)
feederIcon.BackgroundColor3 = Color3.fromRGB(255, 228, 238)
feederIcon.Text = "🥣"
feederIcon.TextSize = 24
feederIcon.Parent = feederRow
Instance.new("UICorner", feederIcon).CornerRadius = UDim.new(1, 0)

local feederTitle = Instance.new("TextLabel")
feederTitle.BackgroundTransparency = 1
feederTitle.Position = UDim2.new(0, 54, 0, 5)
feederTitle.Size = UDim2.new(1, -136, 0, 18)
feederTitle.Font = Enum.Font.GothamBold
feederTitle.TextSize = 14
feederTitle.TextColor3 = Color3.fromRGB(80, 50, 40)
feederTitle.TextXAlignment = Enum.TextXAlignment.Left
feederTitle.Parent = feederRow

local feederBadge = Instance.new("TextLabel")
feederBadge.AnchorPoint = Vector2.new(1, 0)
feederBadge.Position = UDim2.new(1, -8, 0, 5)
feederBadge.Size = UDim2.new(0, 74, 0, 18)
feederBadge.Font = Enum.Font.GothamBold
feederBadge.TextSize = 11
feederBadge.Parent = feederRow
Instance.new("UICorner", feederBadge).CornerRadius = UDim.new(0, 9)

local feederBar = Instance.new("Frame")
feederBar.Position = UDim2.new(0, 54, 0, 27)
feederBar.Size = UDim2.new(1, -62, 0, 16)
feederBar.BackgroundColor3 = Color3.fromRGB(235, 222, 226)
feederBar.BorderSizePixel = 0
feederBar.Parent = feederRow
Instance.new("UICorner", feederBar).CornerRadius = UDim.new(0, 8)
local feederFill = Instance.new("Frame")
feederFill.BorderSizePixel = 0
feederFill.Parent = feederBar
Instance.new("UICorner", feederFill).CornerRadius = UDim.new(0, 8)
local feederBarText = Instance.new("TextLabel")
feederBarText.BackgroundTransparency = 1
feederBarText.Size = UDim2.new(1, 0, 1, 0)
feederBarText.Font = Enum.Font.GothamBold
feederBarText.TextSize = 11
feederBarText.TextColor3 = Color3.fromRGB(60, 40, 35)
feederBarText.ZIndex = 2
feederBarText.Parent = feederBar

local function setFeederBadge(label, bg, fg)
	feederBadge.Text = label
	feederBadge.BackgroundColor3 = bg
	feederBadge.TextColor3 = fg
end
local function renderFeederRow()
	if not player:GetAttribute("HasAutoFeeder") then
		feederTitle.Text = tr("ชามอาหารอัตโนมัติ", "Auto Pet Feeder")
		setFeederBadge(tr("ดูเลย ›", "View ›"), FEEDER_ACCENT, Color3.new(1, 1, 1))
		feederFill.Size = UDim2.new(0, 0, 1, 0)
		feederBarText.Text = tr("สัตว์กินเองเมื่อหิว", "Pets eat on their own when hungry")
		feederStroke.Color = FEEDER_ACCENT
		return
	end
	-- เซิร์ฟเวอร์ยังโหลดชามไม่เสร็จ (เช่น DataStore throttle หลังรีเซิร์ฟ) = ยังไม่มี AutoFeederFood ขึ้น "กำลังโหลด" แทน 0
	if player:GetAttribute("AutoFeederFood") == nil then
		feederTitle.Text = tr("🥣 ชามอาหาร", "🥣 Food Bowl")
		feederFill.Visible = false
		feederBarText.Text = tr("⏳ กำลังโหลด...", "⏳ Loading...")
		setFeederBadge(tr("รอสักครู่", "Please wait"), Color3.fromRGB(230, 224, 222), Color3.fromRGB(130, 100, 90))
		feederStroke.Color = FEEDER_ACCENT
		return
	end
	local food = player:GetAttribute("AutoFeederFood") or 0
	local cap = AutoFeederConfig.CAPACITY
	local on = player:GetAttribute("AutoFeederOn") ~= false
	local low = food <= AutoFeederConfig.LOW_WARNING
	local ratio = AutoFeederConfig.UNLIMITED_CAPACITY and 0 or math.clamp(food / cap, 0, 1)
	feederTitle.Text = tr("🥣 ชามอาหาร", "🥣 Food Bowl")
	feederFill.Size = UDim2.new(ratio, 0, 1, 0)
	feederFill.Visible = food > 0 and not AutoFeederConfig.UNLIMITED_CAPACITY
	feederFill.BackgroundColor3 = not on and Color3.fromRGB(180, 172, 170)
		or (ratio > 0.3 and Color3.fromRGB(110, 200, 90))
		or (low and Color3.fromRGB(230, 80, 70))
		or Color3.fromRGB(240, 190, 60)
	feederBarText.Text = AutoFeederConfig.UNLIMITED_CAPACITY and tr(string.format("🍖 %d ถุง", food), string.format("🍖 %d bags", food)) or tr(string.format("🍖 %d / %d ถุง", food, cap), string.format("🍖 %d / %d bags", food, cap))
	if not on then
		setFeederBadge(tr("ปิดอยู่", "Off"), Color3.fromRGB(230, 224, 222), Color3.fromRGB(130, 100, 90))
		feederStroke.Color = Color3.fromRGB(190, 180, 176)
	elseif low then
		setFeederBadge(food == 0 and tr("หมดแล้ว!", "Empty!") or tr("ใกล้หมด!", "Low!"), Color3.fromRGB(255, 225, 222), Color3.fromRGB(200, 60, 55))
		feederStroke.Color = Color3.fromRGB(230, 90, 80)
	else
		setFeederBadge(tr("✓ เปิดอยู่", "✓ On"), Color3.fromRGB(205, 240, 198), Color3.fromRGB(40, 110, 40))
		feederStroke.Color = FEEDER_ACCENT
	end
end
for _, attr in ipairs({ "HasAutoFeeder", "AutoFeederFood", "AutoFeederOn" }) do
	player:GetAttributeChangedSignal(attr):Connect(renderFeederRow)
end
renderFeederRow()
feederRow.Activated:Connect(function()
	local g = playerGui:FindFirstChild("AutoFeederGui")
	local open = g and g:FindFirstChild("OpenAutoFeeder")
	if open then
		mainFrame.Visible = false -- ปิดเมนูก่อน หน้าต่างชามจะได้ไม่ซ้อนกัน
		open:Fire()
	end
end)

-- แท็บความสามารถ: ปุ่มเปิด/ปิด + หมายเหตุ เลื่อนได้ (เนื้อหาเปลี่ยนตามสัตว์เลี้ยงที่พาออกมา)
local abilityListFrame = Instance.new("ScrollingFrame")
abilityListFrame.Name = "AbilityList"
abilityListFrame.Size = UDim2.new(1, -20, 1, -(CONTENT_TOP + 10))
abilityListFrame.Position = UDim2.new(0, 10, 0, CONTENT_TOP)
abilityListFrame.BackgroundTransparency = 1
abilityListFrame.BorderSizePixel = 0
abilityListFrame.ScrollBarThickness = 6
abilityListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
abilityListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
abilityListFrame.Visible = false
abilityListFrame.Parent = mainFrame

local abilityListPadding = Instance.new("UIPadding")
abilityListPadding.PaddingRight = UDim.new(0, 8) -- เว้นที่ให้แถบเลื่อน
abilityListPadding.Parent = abilityListFrame

-- คำอธิบายสั้นบนสุดของแท็บ (ไม่ถูกลบตอนสร้างปุ่มใหม่)
local abilityHint = Instance.new("TextLabel")
abilityHint.Name = "AbilityHint"
abilityHint.LayoutOrder = -1
abilityHint.Size = UDim2.new(1, 0, 0, 0)
abilityHint.AutomaticSize = Enum.AutomaticSize.Y
abilityHint.BackgroundTransparency = 1
abilityHint.Text = tr("กดเพื่อเปิด/ปิด ใช้กับทุกตัวที่พาออกมา", "Tap to toggle. Applies to all active pets.")
abilityHint.Font = Enum.Font.Gotham
abilityHint.TextSize = 13
abilityHint.TextColor3 = Color3.fromRGB(130, 110, 100)
abilityHint.TextWrapped = true
abilityHint.TextXAlignment = Enum.TextXAlignment.Left
abilityHint.Parent = abilityListFrame

-- แท็บสมุดสัตว์เลี้ยง (ผู้เล่นขอ 2026-10-02): แท็บสัตว์เลี้ยงเหลือเฉพาะตัวที่มีแล้ว ตัวที่ยังไม่มีมาอยู่ในสมุดนี้ (เงา ??? + วิธีได้)
local bookListFrame = Instance.new("ScrollingFrame")
bookListFrame.Name = "BookList"
bookListFrame.Size = UDim2.new(1, -20, 1, -(CONTENT_TOP + 10))
bookListFrame.Position = UDim2.new(0, 10, 0, CONTENT_TOP)
bookListFrame.BackgroundTransparency = 1
bookListFrame.BorderSizePixel = 0
bookListFrame.ScrollBarThickness = 6
bookListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
-- 2026-10-11 เดิมใช้ AutomaticCanvasSize = Y แต่ขนาดพื้นที่เลื่อนไม่ขยายตามรายการ (รายการสูง 1114 พื้นที่เลื่อนค้างที่ 306) สมุดจึงเลื่อนลงไม่ได้
-- ตั้งขนาดเองจากความสูงจริงของรายการแทน (ดู syncBookCanvas ด้านล่าง)
bookListFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
bookListFrame.Visible = false
bookListFrame.Parent = mainFrame
local bookLayout = Instance.new("UIListLayout")
bookLayout.Padding = UDim.new(0, 8)
bookLayout.SortOrder = Enum.SortOrder.LayoutOrder
bookLayout.Parent = bookListFrame
local bookPadding = Instance.new("UIPadding")
bookPadding.PaddingTop = UDim.new(0, 2)
bookPadding.PaddingBottom = UDim.new(0, 2)
bookPadding.PaddingLeft = UDim.new(0, 2)
bookPadding.Parent = bookListFrame
-- 2026-10-12: AbsoluteContentSize เป็นขนาดหลังย่อตาม menuScale แต่ CanvasSize เป็นหน่วยก่อนย่อ จอเล็ก (เมนูย่อ) เลื่อนไม่ถึงรายการท้ายๆ (อาการเดียวกับ Music Box) = หารด้วยสเกล
local function syncBookCanvas()
	local scale = math.max(menuScale.Scale, 0.05)
	bookListFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(bookLayout.AbsoluteContentSize.Y / scale) + 8)
end
bookLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncBookCanvas)
menuScale:GetPropertyChangedSignal("Scale"):Connect(syncBookCanvas)
syncBookCanvas()
-- หัวสมุด: สะสมแล้วกี่ชนิด (ไม่ถูกลบตอนสร้างรายการใหม่)
local bookHeader = Instance.new("TextLabel")
bookHeader.Name = "BookHeader"
bookHeader.LayoutOrder = -1
bookHeader.Size = UDim2.new(1, -8, 0, 22)
bookHeader.BackgroundTransparency = 1
bookHeader.Font = Enum.Font.GothamBold
bookHeader.TextSize = 14
bookHeader.TextColor3 = Color3.fromRGB(80, 50, 40)
bookHeader.TextXAlignment = Enum.TextXAlignment.Left
bookHeader.Text = tr("📖 สมุดสัตว์เลี้ยง", "📖 Pet Book")
bookHeader.Parent = bookListFrame

local currentTab = "pets"
local function showTab(which)
	currentTab = which
	local showPets = which == "pets"
	petListFrame.Visible = showPets
	slotBar.Visible = showPets -- แถบช่องสัตว์อยู่เฉพาะแท็บสัตว์เลี้ยง
	feederRow.Visible = showPets -- ชามอาหารก็อยู่เฉพาะแท็บสัตว์เลี้ยง
	abilityListFrame.Visible = which == "abilities"
	bookListFrame.Visible = which == "book"
	petsTab.BackgroundColor3 = showPets and TAB_ACTIVE or TAB_INACTIVE
	abilitiesTab.BackgroundColor3 = which == "abilities" and TAB_ACTIVE or TAB_INACTIVE
	bookTab.BackgroundColor3 = which == "book" and TAB_ACTIVE or TAB_INACTIVE
end
petsTab.Activated:Connect(function() showTab("pets") end)
abilitiesTab.Activated:Connect(function() showTab("abilities") end)
bookTab.Activated:Connect(function() showTab("book") end)
showTab("pets")

local abilityListLayout = Instance.new("UIListLayout")
abilityListLayout.Padding = UDim.new(0, 6)
abilityListLayout.SortOrder = Enum.SortOrder.LayoutOrder -- เรียงตามลำดับที่สร้าง หมายเหตุจะได้อยู่ใต้ปุ่มของมันพอดี
abilityListLayout.Parent = abilityListFrame

-- หมายเหตุใต้ปุ่มความสามารถ (เฉพาะตัวที่มีเงื่อนไขที่ผู้เล่นต้องรู้)
local ABILITY_NOTES = {
	Planter = tr("📌 หมายเหตุ: วางเมล็ดไว้ช่อง 1 และ 2 เท่านั้น สัตว์เลี้ยงจึงจะช่วยปลูกได้", "📌 Note: Put seeds in slots 1 and 2 only for the pet to help plant"),
	Fisher = tr("🎣 นากหาริมน้ำใกล้เรา (35 studs) แล้วตกปลาเอง ได้ปลาเข้ากระเป๋าเรา ตอนเราตกปลาจะมายืนตกข้างๆ", "🎣 Otter finds nearby water (35 studs) and fishes on its own. Fish goes to your bag. Stands beside you when you fish."),
	ScarecrowPlacer = tr("👻 กดปุ่ม \"สั่งปักหุ่น\" ทางซ้ายจอ เลือกจุดบนพื้น แล้วผีน้อยจะหยิบหุ่นดวงดีจากแถบช่องลัดไปปักตรงนั้น (หุ่นที่เก็บไว้ในกระเป๋าไม่ถูกหยิบ) ตัวเก่าหมดเวลาก็ปักตัวใหม่ที่เดิม ถ้าไม่สั่งจะไม่ปัก (ใช้หุ่นของเราทั้งหุ่นฟางและหุ่นทองคำ ปิดได้ถ้าอยากเก็บหุ่นไว้)", "👻 Press the \"Place order\" button on the left, pick a spot on the ground, and the little ghost takes Lucky Scarecrows from your hotbar (never from the bag) and places them there, replacing them when they expire. Without an order it places nothing (uses your straw and golden scarecrows; turn off to keep them)."),
	TreasureDigger = tr("🐾 ซุกซนดมหาสมบัติข้างตัวเราทุก 3 นาที (เลเวลสูงสุดทุก 2 นาที) ขุดเจอเหรียญ อาหารสัตว์ เหยื่อตกปลา หุ่นฟาง หรือตั๋วสุ่ม (ได้ยาก)", "🐾 Zukzon sniffs for treasure beside you every 3 minutes (2 at max level) and digs up coins, pet food, bait, a straw scarecrow or a gacha ticket (rare)"),
	KrathongCollector = tr("🌸 ตุ่นลงน้ำใกล้เรา (60 studs) เก็บกระทงทุก 15 วิ ได้เหรียญ 100-1,000 ถ้าไม่มีน้ำใกล้ตัวจะไม่ได้เหรียญ", "🌸 The platypus enters nearby water (60 studs) every 15 seconds and collects a krathong for 100-1,000 coins. No nearby water means no coins."),
}
local abilityOrder = 0

openButton.Activated:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

-- เปิดเมนูจากที่อื่น (เช่น กดการ์ดในแผงสัตว์ที่ใช้อยู่ ActivePetsHud): :Fire(petId)
-- เปิดแท็บสัตว์เลี้ยง เลื่อนไปที่แถวของตัวนั้น แล้วกระพริบสีให้เห็น
local openRequest = Instance.new("BindableEvent")
openRequest.Name = "OpenPetMenu"
openRequest.Parent = screenGui
openRequest.Event:Connect(function(petId)
	mainFrame.Visible = true
	showTab("pets")
	if type(petId) ~= "string" then return end
	task.defer(function()
		local row = petListFrame:FindFirstChild("PetRow_" .. petId)
		if not row then return end
		-- ระยะบนจอหารด้วย UIScale ที่ครอบอยู่ (CanvasPosition เป็นหน่วยก่อนย่อ/ขยาย)
		local scale = 1
		local node = petListFrame
		while node and node ~= screenGui do
			local s = node:FindFirstChildOfClass("UIScale")
			if s then scale *= s.Scale end
			node = node.Parent
		end
		local offset = (row.AbsolutePosition.Y - petListFrame.AbsolutePosition.Y) / scale + petListFrame.CanvasPosition.Y
		petListFrame.CanvasPosition = Vector2.new(0, math.max(0, offset - 8))
		local original = row.BackgroundColor3
		row.BackgroundColor3 = Color3.fromRGB(255, 236, 150)
		game:GetService("TweenService"):Create(row, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = original }):Play()
	end)
end)

local activePetIds = {} -- set ของ petId ที่กำลังใช้งานอยู่
-- กดเลือก/เลิกใช้แล้ว รายการสร้างใหม่ (ตัวที่ใช้อยู่ย้ายขึ้นบน) = เลื่อนกลับบนสุด + กระพริบแถวตัวนั้น
-- เดิมรายการค้างตำแหน่งเลื่อนเดิม กดตัวข้างล่างแล้วดูเหมือนไม่ขยับขึ้นไป
local pendingScrollPetId = nil
local petRows = {}
local hungerBars = {} -- [petId] = { fill, text }
local updateHungerBar -- ประกาศไว้ก่อน (นิยามจริงใต้ clearPetRows)
local abilityButtons = {}

local function clearAbilityButtons()
	for _, button in pairs(abilityButtons) do button:Destroy() end
	abilityButtons = {}
end

local function addAbilityNote(abilityId, key, text, color)
	local note = Instance.new("TextLabel")
	note.Name = "AbilityNote_" .. abilityId .. "_" .. key
	note.Size = UDim2.new(1, 0, 0, 0)
	note.AutomaticSize = Enum.AutomaticSize.Y -- สูงตามจำนวนบรรทัดจริง
	note.BackgroundTransparency = 1
	note.Text = text
	note.Font = Enum.Font.Gotham
	note.TextSize = 14
	note.TextColor3 = color
	note.TextWrapped = true
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.TextYAlignment = Enum.TextYAlignment.Top
	abilityOrder += 1
	note.LayoutOrder = abilityOrder + (abilityId == "Lucky" and 1000 or 0) -- นำโชค (ปุ่ม + หมายเหตุ) อยู่ล่างสุดเสมอ (2026-10-03 ผู้เล่นขอ)
	note.Parent = abilityListFrame
	-- เก็บไว้ให้ clearAbilityButtons ลบทิ้งพร้อมปุ่ม (คีย์ไม่ชนกับ abilityId ที่ใช้อัปเดตสถานะปุ่ม)
	abilityButtons["__note_" .. abilityId .. "_" .. key] = note
end

-- ============ ช่องเบ็ดของน้องนาก (ใต้ปุ่ม "ช่วยตกปลา") 2026-10-10 ============
-- หน้าตาเหมือนช่อง 6 (เบ็ด) ในแถบไอเทม: แถบสีบนหัว + รูปเบ็ด 3D / กด "ใช้" ที่เบ็ดนากในกระเป๋า = มาอยู่ช่องนี้ / ปุ่มถอด = กลับกระเป๋า
-- คันที่ใส่อยู่ = Attribute ผู้เล่น PetRodBest (เซิร์ฟเวอร์ CraftBench ตั้ง) · ระบบคราฟยังปิด = ไม่แสดง
local CraftConfig = require(ReplicatedStorage:WaitForChild("CraftConfig"))
local ItemPreview = require(ReplicatedStorage:WaitForChild("ItemPreview"))
local PET_ROD_STRIP = { Shell = Color3.fromRGB(110, 190, 220), Starfish = Color3.fromRGB(240, 140, 100) }
local function addPetRodSlot()
	if not CraftConfig.ENABLED then return end
	local box = Instance.new("Frame")
	box.Name = "PetRodSlot"
	box.Size = UDim2.new(1, 0, 0, 96)
	box.BackgroundColor3 = Color3.fromRGB(255, 246, 228)
	abilityOrder += 1
	box.LayoutOrder = abilityOrder
	box.Parent = abilityListFrame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
	local bs = Instance.new("UIStroke") bs.Color = Color3.fromRGB(225, 190, 130) bs.Thickness = 1.5 bs.Parent = box
	abilityButtons["__petRodSlot"] = box

	-- ช่องเบ็ด (แบบช่อง 6 ในแถบไอเทม)
	local slot = Instance.new("Frame")
	slot.Name = "Slot"
	slot.Position = UDim2.fromOffset(8, 8)
	slot.Size = UDim2.fromOffset(72, 80)
	slot.BackgroundColor3 = Color3.fromRGB(250, 236, 196)
	slot.ClipsDescendants = true
	slot.Parent = box
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)
	local ss = Instance.new("UIStroke") ss.Color = Color3.fromRGB(120, 85, 50) ss.Thickness = 2 ss.Parent = slot
	local strip = Instance.new("TextLabel")
	strip.Size = UDim2.new(1, 0, 0, 18)
	strip.BackgroundColor3 = Color3.fromRGB(235, 170, 20)
	strip.BorderSizePixel = 0
	strip.Font = Enum.Font.GothamBold
	strip.TextSize = 11
	strip.TextColor3 = Color3.new(1, 1, 1)
	strip.TextStrokeTransparency = 0.6
	strip.Parent = slot
	local pic = Instance.new("Frame")
	pic.BackgroundTransparency = 1
	pic.Position = UDim2.fromOffset(2, 20)
	pic.Size = UDim2.new(1, -4, 1, -22)
	pic.Parent = slot

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(90, 6)
	title.Size = UDim2.new(1, -98, 0, 20)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(90, 55, 35)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = tr("🎣 เบ็ดของน้องนาก", "🎣 Otter's rod")
	title.Parent = box
	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.fromOffset(90, 26)
	desc.Size = UDim2.new(1, -98, 0, 34)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextWrapped = true
	desc.TextColor3 = Color3.fromRGB(130, 90, 60)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = box
	local takeOff = Instance.new("TextButton")
	takeOff.Name = "TakeOffRod"
	takeOff.Position = UDim2.fromOffset(90, 62)
	takeOff.Size = UDim2.fromOffset(120, 26)
	takeOff.BackgroundColor3 = Color3.fromRGB(240, 150, 140)
	takeOff.Font = Enum.Font.GothamBold
	takeOff.TextSize = 13
	takeOff.TextColor3 = Color3.new(1, 1, 1)
	takeOff.Text = tr("ถอดเบ็ดเข้ากระเป๋า", "Back to bag")
	takeOff.Selectable = true
	takeOff.Parent = box
	Instance.new("UICorner", takeOff).CornerRadius = UDim.new(0, 8)

	-- กดที่ช่อง = กางรายการเบ็ดนากที่อยู่ในกระเป๋าให้เลือก (2026-10-10 ผู้ใช้ขอ) รายการกางอยู่ในกล่องนี้เอง กดเบ็ด = ให้นากถือ
	local SLOT_BOX_HEIGHT = 96
	local PICK_ROW_HEIGHT = 52
	local isLocked = false
	local pickOpen = false
	local shownId = false
	local pickButton = Instance.new("TextButton")
	pickButton.Name = "PetRodPick"
	pickButton.Size = UDim2.fromScale(1, 1)
	pickButton.BackgroundTransparency = 1
	pickButton.Text = ""
	pickButton.ZIndex = 5
	pickButton.Selectable = true
	pickButton.Parent = slot
	local pickList = Instance.new("Frame")
	pickList.Name = "PickList"
	pickList.Position = UDim2.fromOffset(8, SLOT_BOX_HEIGHT)
	pickList.Size = UDim2.new(1, -16, 0, 0)
	pickList.BackgroundTransparency = 1
	pickList.Visible = false
	pickList.Parent = box
	local pickLayout = Instance.new("UIListLayout")
	pickLayout.Padding = UDim.new(0, 6)
	pickLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pickLayout.Parent = pickList

	-- เบ็ดนากในกระเป๋า (คันที่นากถืออยู่ไม่อยู่ในกระเป๋า เซิร์ฟเวอร์ CraftBench จัดให้)
	local function bagPetRods()
		local list, seen = {}, {}
		for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
			for _, t in ipairs(loc and loc:GetChildren() or {}) do
				local id = t:IsA("Tool") and t:GetAttribute("IsPetRod") and t:GetAttribute("PetRodId")
				if id and CraftConfig.PetRods[id] and not seen[id] then
					seen[id] = true
					table.insert(list, id)
				end
			end
		end
		table.sort(list, function(a, b) return CraftConfig.PetRods[a].Rank < CraftConfig.PetRods[b].Rank end)
		return list
	end

	local rebuildPick
	local function chooseRod(id)
		local rf = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("CraftBenchRequest")
		if not rf then return end
		local ok, result = pcall(function() return rf:InvokeServer("equipPetRod", id) end)
		if ok and type(result) == "table" and result.ok then
			pickOpen = false
			rebuildPick()
		elseif ok and type(result) == "table" and type(result.message) == "string" then
			desc.Text = result.message
			shownId = false -- ให้ render รอบหน้าเขียนคำอธิบายปกติกลับ
		end
	end

	rebuildPick = function()
		for _, c in ipairs(pickList:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		if not pickOpen then
			pickList.Visible = false
			box.Size = UDim2.new(1, 0, 0, SLOT_BOX_HEIGHT)
			return
		end
		local rods = bagPetRods()
		local height
		if #rods == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 36)
			empty.BackgroundColor3 = Color3.fromRGB(250, 236, 196)
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextWrapped = true
			empty.TextColor3 = Color3.fromRGB(130, 90, 60)
			empty.Text = tr("ยังไม่มีเบ็ดนากในกระเป๋า · คราฟได้ที่โต๊ะช่างนากน้อย", "No otter rods in your bag · craft one at the Otter's Workshop")
			empty.Parent = pickList
			Instance.new("UICorner", empty).CornerRadius = UDim.new(0, 8)
			height = 36
		else
			for i, id in ipairs(rods) do
				local def = CraftConfig.PetRods[id]
				local row = Instance.new("TextButton")
				row.Name = "PetRodChoice_" .. id
				row.LayoutOrder = i
				row.Size = UDim2.new(1, 0, 0, PICK_ROW_HEIGHT)
				row.BackgroundColor3 = Color3.fromRGB(255, 252, 240)
				row.Text = ""
				row.Selectable = true
				row.Parent = pickList
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
				local rs = Instance.new("UIStroke") rs.Color = PET_ROD_STRIP[id] or Color3.fromRGB(225, 190, 130) rs.Thickness = 1.5 rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border rs.Parent = row
				local rowPic = Instance.new("Frame")
				rowPic.BackgroundTransparency = 1
				rowPic.Position = UDim2.fromOffset(4, 4)
				rowPic.Size = UDim2.fromOffset(44, 44)
				rowPic.Parent = row
				if not ItemPreview.Create(rowPic, def.Template, 1.15) then
					local e = Instance.new("TextLabel") e.BackgroundTransparency = 1 e.Size = UDim2.fromScale(1, 1) e.Text = def.Icon e.TextSize = 24 e.Parent = rowPic
				end
				local rowName = Instance.new("TextLabel")
				rowName.BackgroundTransparency = 1
				rowName.Position = UDim2.fromOffset(56, 4)
				rowName.Size = UDim2.new(1, -62, 0, 18)
				rowName.Font = Enum.Font.GothamBold
				rowName.TextSize = 14
				rowName.TextColor3 = Color3.fromRGB(90, 55, 35)
				rowName.TextXAlignment = Enum.TextXAlignment.Left
				rowName.Text = def.Icon .. " " .. tr(def.Name, def.NameEn)
				rowName.Parent = row
				local recipe = CraftConfig.Get("Pet" .. id)
				local rowDesc = Instance.new("TextLabel")
				rowDesc.BackgroundTransparency = 1
				rowDesc.Position = UDim2.fromOffset(56, 22)
				rowDesc.Size = UDim2.new(1, -62, 0, 26)
				rowDesc.Font = Enum.Font.Gotham
				rowDesc.TextSize = 11
				rowDesc.TextWrapped = true
				rowDesc.TextTruncate = Enum.TextTruncate.AtEnd
				rowDesc.TextColor3 = Color3.fromRGB(130, 90, 60)
				rowDesc.TextXAlignment = Enum.TextXAlignment.Left
				rowDesc.TextYAlignment = Enum.TextYAlignment.Top
				rowDesc.Text = recipe and tr(recipe.Desc, recipe.DescEn) or ""
				rowDesc.Parent = row
				row.Activated:Connect(function() chooseRod(id) end)
			end
			height = #rods * PICK_ROW_HEIGHT + (#rods - 1) * 6
		end
		pickList.Size = UDim2.new(1, -16, 0, height)
		pickList.Visible = true
		box.Size = UDim2.new(1, 0, 0, SLOT_BOX_HEIGHT + height + 8)
	end
	pickButton.Activated:Connect(function()
		if isLocked then return end
		pickOpen = not pickOpen
		rebuildPick()
	end)

	local function render()
		local id = player:GetAttribute("PetRodBest")
		local def = id and CraftConfig.PetRods[id]
		-- ล็อกจนกว่าสมุดปลาครบเล่ม (ผู้ใช้ขอ 2026-10-10) Attribute FishBookHave/FishBookTotal จาก FishIndex
		local have, total = player:GetAttribute("FishBookHave"), player:GetAttribute("FishBookTotal")
		local locked = CraftConfig.PET_RODS_NEED_BOOK and not def and not (have and total and have >= total)
		isLocked = locked
		if locked and pickOpen then pickOpen = false rebuildPick() end
		local key = locked and ("lock" .. tostring(have) .. "/" .. tostring(total)) or (id or "")
		if shownId == key then return end
		shownId = key
		pic:ClearAllChildren()
		if locked then
			strip.Text = tr("🔒 ล็อก", "🔒 Locked")
			strip.BackgroundColor3 = Color3.fromRGB(150, 140, 135)
			local e = Instance.new("TextLabel") e.BackgroundTransparency = 1 e.Size = UDim2.fromScale(1, 1) e.Text = "🔒" e.TextSize = 30 e.Parent = pic
			desc.Text = string.format(tr("สะสมปลาในสมุดให้ครบ %d ชนิดเพื่อปลดล็อกช่องเบ็ดนาก (ตอนนี้ %d/%d)", "Complete all %d fish in the book to unlock the otter rod slot (now %d/%d)"), total or 40, have or 0, total or 40)
			takeOff.Visible = false
		elseif def then
			strip.Text = def.Icon .. " " .. tr((def.Name:gsub("^เบ็ด", "")), (def.NameEn:gsub(" Rod$", "")))
			strip.BackgroundColor3 = PET_ROD_STRIP[id] or Color3.fromRGB(235, 170, 20)
			if not ItemPreview.Create(pic, def.Template, 1.15) then
				local e = Instance.new("TextLabel") e.BackgroundTransparency = 1 e.Size = UDim2.fromScale(1, 1) e.Text = def.Icon e.TextSize = 30 e.Parent = pic
			end
			local recipe = CraftConfig.Get("Pet" .. id)
			desc.Text = recipe and tr(recipe.Desc, recipe.DescEn) or ""
			takeOff.Visible = true
		else
			strip.Text = tr("ว่าง", "Empty")
			strip.BackgroundColor3 = Color3.fromRGB(190, 170, 150)
			local e = Instance.new("TextLabel") e.BackgroundTransparency = 1 e.Size = UDim2.fromScale(1, 1) e.Text = "🎣" e.TextSize = 26 e.TextTransparency = 0.5 e.Parent = pic
			desc.Text = tr("กดที่ช่องเพื่อเลือกเบ็ดนากจากกระเป๋า (คราฟได้ที่โต๊ะช่างนากน้อย)", "Tap the slot to pick an otter rod from your bag (craft one at the Otter's Workshop)")
			takeOff.Visible = false
		end
	end
	render()
	local conns = {
		player:GetAttributeChangedSignal("PetRodBest"):Connect(render),
		player:GetAttributeChangedSignal("FishBookHave"):Connect(render),
		player:GetAttributeChangedSignal("FishBookTotal"):Connect(render),
	}
	-- กระเป๋าเปลี่ยนระหว่างกางรายการอยู่ = สร้างรายการใหม่
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		local function bagChanged() if pickOpen then task.defer(rebuildPick) end end
		table.insert(conns, backpack.ChildAdded:Connect(bagChanged))
		table.insert(conns, backpack.ChildRemoved:Connect(bagChanged))
	end
	box.Destroying:Connect(function() for _, c in ipairs(conns) do c:Disconnect() end end)
	takeOff.Activated:Connect(function()
		local rf = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("CraftBenchRequest")
		if rf then pcall(function() rf:InvokeServer("unequipPetRod") end) end
	end)
end

-- extraNote: หมายเหตุจากเซิร์ฟเวอร์ตามสัตว์ที่พาออกมา (เช่น "✨ จิ้งจอกเก้าหาง เก็บเกี่ยวได้ผลผลิต x2")
local function createAbilityButton(abilityId, displayName, extraNote)
	local button = Instance.new("TextButton")
	button.Name = "AbilityButton_" .. abilityId
	button.Size = UDim2.new(1, 0, 0, 36)
	button.BackgroundColor3 = Color3.fromRGB(255, 200, 220)
	button.TextColor3 = Color3.fromRGB(60, 30, 40)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.Text = "✨ " .. displayName .. tr(": ปิด", ": Off")
	if abilityId == "Lucky" then
		-- นำโชคบังคับเปิดตลอด: แสดงแค่ชื่อ ไม่มี ":เปิด/ปิด" (2026-10-03 ผู้เล่นขอ)
		button.Text = "✨ " .. displayName
		button.BackgroundColor3 = Color3.fromRGB(160, 230, 160)
	end
	button.Selectable = true
	abilityOrder += 1
	button.LayoutOrder = abilityOrder + (abilityId == "Lucky" and 1000 or 0)
	button.Parent = abilityListFrame

	if ABILITY_NOTES[abilityId] then
		addAbilityNote(abilityId, "rule", ABILITY_NOTES[abilityId], Color3.fromRGB(150, 90, 60))
	end
	if type(extraNote) == "string" and extraNote ~= "" then
		addAbilityNote(abilityId, "bonus", extraNote, Color3.fromRGB(200, 120, 20)) -- สีทองส้ม เข้ากับออร่าจิ้งจอกเก้าหาง
	end
	if abilityId == "Fisher" then addPetRodSlot() end -- ช่องเบ็ดของน้องนาก

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	if abilityId == "Lucky" then button.AutoButtonColor = false end -- นำโชคบังคับเปิดตลอด กดไม่ทำอะไร (เซิร์ฟเวอร์ไม่ยอมปิดอยู่แล้ว)
	button.Activated:Connect(function()
		if abilityId == "Lucky" then return end
		petAbilityToggle:FireServer(abilityId)
	end)

	abilityButtons[abilityId] = button
end

-- โมเดลสัตว์เลี้ยงที่เซิร์ฟเวอร์ (PetManager) สำเนามาไว้ให้โชว์ในเมนู
local PREVIEW_SIZE = 64
local PREVIEW_SPIN_SPEED = math.rad(40) -- องศา/วินาที
local PREVIEW_FOV = 30
local previewFolder = ReplicatedStorage:WaitForChild("PetPreviewModels", 10)
local spinningPreviews = {} -- [model] = { centerCFrame, pivotOffset }
local previewAngle = 0

local function createPetPreview(parent, petId, locked)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "PetPreview"
	viewport.Size = UDim2.new(0, PREVIEW_SIZE, 0, PREVIEW_SIZE)
	viewport.Position = UDim2.new(0, 8, 0, 8) -- ยึดจากด้านบน (แถวที่มีคำอธิบายสูงกว่า ไม่ให้เลื่อนลงมาทับ)
	viewport.BackgroundColor3 = Color3.fromRGB(255, 225, 235)
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	if locked then
		-- ยังไม่มีตัวนี้: พื้นหลังสีอ่อน (ตัวโมเดลทำเป็นเงาดำด้านล่าง)
		viewport.BackgroundColor3 = Color3.fromRGB(225, 218, 222)
		viewport.Ambient = Color3.new(0, 0, 0)
		viewport.LightColor = Color3.new(0, 0, 0)
	end
	viewport.Parent = parent

	local viewportCorner = Instance.new("UICorner")
	viewportCorner.CornerRadius = UDim.new(0, 8)
	viewportCorner.Parent = viewport

	local template = previewFolder and previewFolder:FindFirstChild(petId)
	if not template then
		-- ไม่มีโมเดล (เช่นเพิ่มสัตว์เลี้ยงใน PetDefinitions แต่ยังไม่ใส่โมเดล) โชว์รอยเท้าแทน
		local fallback = Instance.new("TextLabel")
		fallback.Size = UDim2.new(1, 0, 1, 0)
		fallback.BackgroundTransparency = 1
		fallback.Text = "🐾"
		fallback.TextSize = 30
		fallback.Parent = viewport
		return
	end

	local model = template:Clone()
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then obj.Anchored = true end
		if locked then
			-- เงาดำ: เห็นแค่ทรง ไม่เห็นสี/ลาย/หน้าตา ให้อยากสุ่มมาครอบครอง
			if obj:IsA("MeshPart") then obj.TextureID = "" end
			if obj:IsA("BasePart") then
				obj.Color = Color3.fromRGB(25, 22, 28)
				obj.Material = Enum.Material.SmoothPlastic
				obj.Reflectance = 0
			end
			if obj:IsA("SurfaceAppearance") or obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Highlight") then obj:Destroy() end
		end
	end
	model.Parent = viewport

	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = boxCFrame.Position
	local centerCFrame = CFrame.new(center)
	-- หน้าของโมเดลอยู่ฝั่งตรงข้าม LookVector (PetDefinitions หมุน FacingOffset 180 องศาตอนเดินตาม)
	local frontDirection = -model:GetPivot().LookVector
	local radius = boxSize.Magnitude / 2
	-- คูณ 0.8 ให้ซูมเข้าไปอีกนิด (รัศมีจากเส้นทแยงกล่องเผื่อเกินจริง โมเดลจะดูเล็กไป)
	local distance = radius / math.sin(math.rad(PREVIEW_FOV / 2)) * 0.8

	local camera = Instance.new("Camera")
	camera.FieldOfView = PREVIEW_FOV
	camera.CFrame = CFrame.lookAt(center + frontDirection * distance + Vector3.new(0, radius * 0.5, 0), center)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	spinningPreviews[model] = { centerCFrame, centerCFrame:ToObjectSpace(model:GetPivot()) }
end

-- หมุนโมเดลช้าๆ เฉพาะตอนเมนูเปิดอยู่ (หมุนไป-กลับซ้ายขวา ให้เห็นหน้าสัตว์เลี้ยงเป็นหลัก)
-- เอฟเฟกต์สีรุ้งวิ่งวนของระดับที่ตั้ง Gradient ไว้ (เช่น "ลับ")
local animatedGradients = {} -- [UIGradient] = true
local GRADIENT_SPIN_SPEED = 90 -- องศา/วินาที

local function addRarityGradient(parent, sequence)
	local gradient = Instance.new("UIGradient")
	gradient.Color = sequence
	gradient.Parent = parent
	animatedGradients[gradient] = true
	return gradient
end

RunService.RenderStepped:Connect(function(dt)
	if not mainFrame.Visible then return end
	for gradient in pairs(animatedGradients) do
		if gradient.Parent then
			gradient.Rotation = (gradient.Rotation + dt * GRADIENT_SPIN_SPEED) % 360
		else
			animatedGradients[gradient] = nil
		end
	end
	previewAngle += dt * PREVIEW_SPIN_SPEED
	local yaw = math.sin(previewAngle) * math.rad(50)
	for model, data in pairs(spinningPreviews) do
		if model.Parent then
			model:PivotTo(data[1] * CFrame.Angles(0, yaw, 0) * data[2])
		else
			spinningPreviews[model] = nil
		end
	end
end)

local function clearPetRows()
	for _, row in pairs(petRows) do row:Destroy() end
	petRows = {}
	hungerBars = {}
end

function updateHungerBar(petId)
	local bar = hungerBars[petId]
	if not bar then return end
	local value = player:GetAttribute("PetHunger_" .. petId) or 100
	bar.fill.Size = UDim2.new(value / 100, 0, 1, 0)
	bar.fill.BackgroundColor3 = (value > 50 and Color3.fromRGB(110, 200, 90))
		or (value > 20 and Color3.fromRGB(240, 190, 60)) or Color3.fromRGB(230, 80, 70)
	bar.text.Text = "🍖" .. math.floor(value + 0.5) .. "%"
end

-- ป้ายเลเวล (Lv จากตัวซ้ำ ดู PetLevelConfig) อัปเดตทันทีที่อัปเลเวลในตู้สุ่ม
local levelPills = {} -- [petId] = TextLabel
local function updateLevelPill(petId)
	local pill = levelPills[petId]
	if not (pill and pill.Parent) then return end
	local level = player:GetAttribute("PetLevel_" .. petId) or 1
	local dupes = player:GetAttribute("PetDupes_" .. petId) or 0
	pill.Text = "Lv." .. level .. (dupes > 0 and ("  ⬆️" .. dupes) or "")
end

player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 10) == "PetHunger_" then
		updateHungerBar(string.sub(name, 11))
	elseif string.sub(name, 1, 9) == "PetLevel_" or string.sub(name, 1, 9) == "PetDupes_" then
		updateLevelPill(string.sub(name, 10))
	end
end)

-- บรรทัดความสามารถพิเศษ (สีส้มใต้การ์ด): ตัดส่วนที่ซ้ำกับบรรทัด skill ออก (ผู้เล่นขอ 2026-10-01)
-- ซ้ำ = นำโชค xN (อยู่ท้าย skill แล้ว) / ชื่อความสามารถ เช่น "ช่วยเก็บเกี่ยว" / "เก็บเกี่ยวได้ผลผลิต x2" (skill มี x2 แล้ว)
-- ข้อความเดิมใน PetDefinitions ไม่แก้ (ที่อื่นอย่างตู้สุ่มยังใช้ครบ) ตัดเฉพาะตอนแสดงในเมนูนี้
local SKILL_NAMES = { ["ช่วยเก็บเกี่ยว"] = true, ["ช่วยปลูกผัก"] = true, ["ช่วยตกปลา"] = true }
local function trimPetDescription(text)
	local prefix, body = text:match("^(.-:%s*)(.+)$")
	if not prefix then prefix, body = "", text end
	local keep = {}
	for part in (body .. " · "):gmatch("(.-) · ") do
		local drop = part == "" or SKILL_NAMES[part] or part:find("นำโชค", 1, true) or part:find("ผลผลิต x", 1, true)
		if not drop then table.insert(keep, part) end
	end
	if #keep == 0 then return nil end
	return prefix .. table.concat(keep, " · ")
end

-- คำอธิบายภาษาอังกฤษที่เขียนไว้เอง (PetDefinitions.DescriptionEn, 2026-10-29 ผึ้งราชินี) ตัดส่วนซ้ำแบบเดียวกัน
-- สัตว์ที่ไม่มี DescriptionEn ยังใช้ภาษาไทย ให้คำแปลอัตโนมัติของ Roblox แปลเหมือนเดิม
local SKILL_NAMES_EN = { ["Helps plant vegetables"] = true, ["Helps harvest"] = true, ["Helps fish"] = true }
local function trimPetDescriptionEn(text)
	local prefix, body = text:match("^(.-:%s*)(.+)$")
	if not prefix then prefix, body = "", text end
	local keep = {}
	for part in (body .. " · "):gmatch("(.-) · ") do
		local drop = part == "" or SKILL_NAMES_EN[part] or part:find("Luck x", 1, true) or part:find("yield x", 1, true)
		if not drop then table.insert(keep, part) end
	end
	if #keep == 0 then return nil end
	return prefix .. table.concat(keep, " · ")
end
local function petSpecialText(petInfo)
	if lang ~= "th" and type(petInfo.DescriptionEn) == "string" and petInfo.DescriptionEn ~= "" then
		return trimPetDescriptionEn(petInfo.DescriptionEn)
	end
	return (type(petInfo.Description) == "string" and petInfo.Description ~= "") and trimPetDescription(petInfo.Description) or nil
end

local function createPetRow(petInfo)
	local row = Instance.new("Frame")
	row.Name = "PetRow_" .. petInfo.Id
	local tier = PetRarity.Get(petInfo.Rarity)
	-- ยังไม่ได้เป็นเจ้าของ: เห็นแค่เงา ชื่อ "???" และระดับความหายาก (รู้ว่ามีตัวอะไรรออยู่ แต่เลือกไม่ได้)
	local locked = petInfo.Owned == false
	-- ยังไม่มี + มีวิธีได้พิเศษ (เช่น นากจากสมุดปลา) = บอกวิธีได้แทนคำอธิบาย
	local lockedHint = locked and type(petInfo.UnlockHint) == "string" and petInfo.UnlockHint or nil
	local shownDescription = (not locked) and petSpecialText(petInfo) or nil
	local hasDescription = lockedHint ~= nil or shownDescription ~= nil
	row.Size = UDim2.new(1, -8, 0, hasDescription and 112 or 80) -- เว้นที่ให้แถบเลื่อน กันขอบสีความหายากโดนทับ / มีคำอธิบายสูงขึ้น
	if hasDescription then
		local desc = Instance.new("TextLabel")
		desc.Name = "Description"
		desc.Size = UDim2.new(1, -16, 0, 30) -- 2 บรรทัด (คำอธิบายสัตว์พิเศษยาวเกิน 1 บรรทัด เดิมโดนตัดทิ้ง)
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Position = UDim2.new(0, 8, 0, 78)
		desc.BackgroundTransparency = 1
		desc.Text = lockedHint or shownDescription
		desc.Font = Enum.Font.GothamBold
		desc.TextSize = 12
		desc.TextColor3 = lockedHint and Color3.fromRGB(70, 120, 170) or Color3.fromRGB(190, 110, 20)
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = row
	end
	row.BackgroundColor3 = tier.RowColor
	if locked then row.BackgroundTransparency = 0.35 end
	row.Parent = petListFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	-- ขอบสีตามความหายาก (ธรรมดาไม่มีขอบ ให้ตัวหายากดูเด่นกว่า)
	if tier.Order > 1 then
		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = tier.Color
		rowStroke.Thickness = 2
		rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rowStroke.Parent = row
		if tier.Gradient then
			rowStroke.Color = Color3.new(1, 1, 1) -- ให้สีรุ้งแสดงสีจริง (UIGradient คูณกับสีเดิม)
			rowStroke.Thickness = 3
			addRarityGradient(rowStroke, tier.Gradient)
		end
	end

	-- ป้ายความหายาก มุมขวาบน (เหนือปุ่มเลือก)
	local rarityBadge = Instance.new("TextLabel")
	rarityBadge.Name = "RarityBadge"
	rarityBadge.Size = UDim2.new(0, 70, 0, 16)
	rarityBadge.Position = UDim2.new(1, -80, 0, 4)
	rarityBadge.BackgroundColor3 = tier.Color
	rarityBadge.Text = tier.DisplayName
	rarityBadge.Font = Enum.Font.GothamBold
	rarityBadge.TextSize = 11
	rarityBadge.TextColor3 = Color3.new(1, 1, 1)
	rarityBadge.Parent = row
	Instance.new("UICorner", rarityBadge).CornerRadius = UDim.new(1, 0)
	if tier.Gradient then
		rarityBadge.BackgroundColor3 = Color3.new(1, 1, 1)
		rarityBadge.Text = "✨ " .. tier.DisplayName .. " ✨"
		rarityBadge.TextStrokeTransparency = 0.2
		rarityBadge.TextStrokeColor3 = tier.Color
		addRarityGradient(rarityBadge, tier.Gradient)
	end

	createPetPreview(row, petInfo.Id, locked)

	-- แถวชื่อ: ชื่อสัตว์ + ป้ายค่าโชคสีเขียว (ความสามารถนำโชค ค่าตามความหายาก ดู LuckConfig.PetLuckByRarity)
	local nameRow = Instance.new("Frame")
	nameRow.Name = "NameRow"
	nameRow.Size = UDim2.new(1, -164, 0, 24)
	nameRow.Position = UDim2.new(0, 80, 0, 10)
	nameRow.BackgroundTransparency = 1
	nameRow.Parent = row

	local nameRowLayout = Instance.new("UIListLayout")
	nameRowLayout.FillDirection = Enum.FillDirection.Horizontal
	nameRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	nameRowLayout.Padding = UDim.new(0, 6)
	nameRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	nameRowLayout.Parent = nameRow

	local nameLabel = Instance.new("TextLabel")
	nameLabel.LayoutOrder = 1
	nameLabel.Size = UDim2.new(0, 0, 1, 0)
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = locked and "???" or petInfo.DisplayName
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(70, 40, 35)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = nameRow

	if not locked then
		local levelPill = Instance.new("TextLabel")
		levelPill.Name = "LevelPill"
		levelPill.LayoutOrder = 3
		levelPill.Size = UDim2.new(0, 0, 0, 18)
		levelPill.AutomaticSize = Enum.AutomaticSize.X
		levelPill.BackgroundColor3 = Color3.fromRGB(225, 225, 255)
		levelPill.Font = Enum.Font.GothamBold
		levelPill.TextSize = 12
		levelPill.TextColor3 = Color3.fromRGB(80, 80, 170)
		-- ป้ายเลเวลอยู่มุมซ้ายบนของการ์ด (ทับมุมรูปสัตว์) ผู้เล่นขอ 2026-10-01 เดิมอยู่ท้ายชื่อ
		levelPill.AnchorPoint = Vector2.new(0, 0)
		levelPill.Position = UDim2.new(0, 4, 0, 4)
		levelPill.ZIndex = 3
		levelPill.Parent = row
		Instance.new("UICorner", levelPill).CornerRadius = UDim.new(1, 0)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = levelPill
		levelPills[petInfo.Id] = levelPill
		updateLevelPill(petInfo.Id)
	end


	-- ความสามารถนำโชคแสดงเป็นป้าย 🍀 ข้างชื่อแล้ว ไม่ต้องเขียนซ้ำในบรรทัดความสามารถ
	-- ไอคอนนำหน้าแต่ละความสามารถ แทนคำว่า "ความสามารถ:" (มือถือจอเล็กเห็นแค่คำนำหน้า ชื่อความสามารถโดนตัด)
	local ABILITY_ICONS = { Planter = "🌱", Harvester = "🌾", Fisher = "🎣", ScarecrowPlacer = "👻", TreasureDigger = "🐾", KrathongCollector = "🌸" }
	local abilityNames = {}
	for _, ability in ipairs(petInfo.Abilities) do
		if ability.Id ~= "Lucky" then
			-- "ช่วยเก็บเกี่ยว (ผลผลิต x2)" ย่อเป็น "ช่วยเก็บเกี่ยว x2" ให้พอดีบรรทัดเดียว
			local shortName = ability.DisplayName:gsub(" %(ผลผลิต (x[%d%.]+)%)", " %1")
			table.insert(abilityNames, (ABILITY_ICONS[ability.Id] or "⭐") .. " " .. shortName)
		end
	end
	-- ค่าโชคต่อท้ายบรรทัดความสามารถ (เดิมเป็นป้ายเขียวข้างชื่อ)
	if not locked and petInfo.Luck and petInfo.Luck > 0 then
		table.insert(abilityNames, tr("🍀 โชค x", "🍀 Luck x") .. petInfo.Luck)
	end

	local abilityLabel = Instance.new("TextLabel")
	abilityLabel.Size = UDim2.new(1, -164, 0, 22)
	abilityLabel.Position = UDim2.new(0, 80, 0, 36)
	abilityLabel.BackgroundTransparency = 1
	abilityLabel.Text = #abilityNames > 0 and table.concat(abilityNames, "  ") or "—"
	abilityLabel.Font = Enum.Font.Gotham
	abilityLabel.TextSize = 13
	abilityLabel.TextColor3 = Color3.fromRGB(100, 80, 75)
	abilityLabel.TextWrapped = true
	abilityLabel.TextXAlignment = Enum.TextXAlignment.Left
	abilityLabel.TextYAlignment = Enum.TextYAlignment.Top
	-- จอแคบ (มือถือบางรุ่น) ให้ตัวอักษรหดลงเองแทนที่จะโดนตัด (ใหญ่สุด 13 เท่าเดิม)
	abilityLabel.TextScaled = true
	local abilitySize = Instance.new("UITextSizeConstraint")
	abilitySize.MaxTextSize = 13
	abilitySize.MinTextSize = 8
	abilitySize.Parent = abilityLabel
	abilityLabel.Parent = row

	if locked then
		abilityLabel.Text = tr("🔒 ยังไม่ได้เป็นเจ้าของ", "🔒 Not owned yet")
		abilityLabel.TextColor3 = Color3.fromRGB(130, 110, 115)
		local lockLabel = Instance.new("TextLabel")
		lockLabel.Name = "LockedLabel"
		lockLabel.Size = UDim2.new(0, 70, 0, 34)
		lockLabel.Position = UDim2.new(1, -80, 0, 30)
		lockLabel.BackgroundColor3 = Color3.fromRGB(215, 205, 210)
		lockLabel.Text = "🔒"
		lockLabel.TextSize = 18
		lockLabel.Font = Enum.Font.GothamBold
		lockLabel.Parent = row
		Instance.new("UICorner", lockLabel).CornerRadius = UDim.new(0, 8)
		petRows[petInfo.Id] = row
		return
	end

	-- แถบความหิว (ความหิว = ประสิทธิภาพการทำงาน) อ่านจาก Attribute ที่เซิร์ฟเวอร์ตั้งบนตัวผู้เล่น
	local hungerBack = Instance.new("Frame")
	hungerBack.Name = "HungerBar"
	hungerBack.Size = UDim2.new(1, -214, 0, 8)
	hungerBack.Position = UDim2.new(0, 80, 0, 62)
	hungerBack.BackgroundColor3 = Color3.fromRGB(225, 205, 200)
	hungerBack.BorderSizePixel = 0
	hungerBack.Parent = row
	Instance.new("UICorner", hungerBack).CornerRadius = UDim.new(1, 0)

	local hungerFill = Instance.new("Frame")
	hungerFill.BorderSizePixel = 0
	hungerFill.Parent = hungerBack
	Instance.new("UICorner", hungerFill).CornerRadius = UDim.new(1, 0)

	local hungerText = Instance.new("TextLabel")
	hungerText.Size = UDim2.new(0, 46, 0, 14)
	hungerText.Position = UDim2.new(1, -130, 0, 59)
	hungerText.BackgroundTransparency = 1
	hungerText.Font = Enum.Font.GothamBold
	hungerText.TextSize = 11
	hungerText.TextColor3 = Color3.fromRGB(100, 80, 75)
	hungerText.TextXAlignment = Enum.TextXAlignment.Left
	hungerText.Parent = row

	hungerBars[petInfo.Id] = { fill = hungerFill, text = hungerText }
	updateHungerBar(petInfo.Id)

	local selectButton = Instance.new("TextButton")
	selectButton.Name = "SelectButton"
	selectButton.Size = UDim2.new(0, 70, 0, 34)
	selectButton.Position = UDim2.new(1, -80, 0, 30) -- เลื่อนลงเล็กน้อย เว้นที่ให้ป้ายความหายาก
	selectButton.Font = Enum.Font.GothamBold
	selectButton.TextSize = 13
	-- คำแปลอัตโนมัติของ Roblox ยาวกว่าปุ่มได้ (เช่น "เลิกใช้" → "Remove equipment" ล้นปุ่ม ผู้ใช้แจ้ง 2026-10-29) ให้ตัดบรรทัดและหดตัวอักษรให้พอดีปุ่ม
	selectButton.TextWrapped = true
	selectButton.TextScaled = true
	local selectTextSize = Instance.new("UITextSizeConstraint")
	selectTextSize.MaxTextSize = 13
	selectTextSize.MinTextSize = 7
	selectTextSize.Parent = selectButton
	local selectPad = Instance.new("UIPadding")
	selectPad.PaddingLeft = UDim.new(0, 4)
	selectPad.PaddingRight = UDim.new(0, 4)
	selectPad.Parent = selectButton
	selectButton.Selectable = true
	selectButton.Parent = row

	local selectCorner = Instance.new("UICorner")
	selectCorner.CornerRadius = UDim.new(0, 8)
	selectCorner.Parent = selectButton

	selectButton:SetAttribute("PetActive", activePetIds[petInfo.Id] == true) -- GuideHint 2026-11-15: บทสอนสัตว์เลี้ยงไฮไลต์ปุ่ม "เลือก" ที่ยังไม่ได้พาออกมา
	if activePetIds[petInfo.Id] then
		selectButton.Text = tr("เลิกใช้", "Unequip")
		selectButton.BackgroundColor3 = Color3.fromRGB(160, 230, 160)
		selectButton.TextColor3 = Color3.fromRGB(30, 70, 30)
	else
		selectButton.Text = tr("เลือก", "Select")
		selectButton.BackgroundColor3 = Color3.fromRGB(255, 200, 220)
		selectButton.TextColor3 = Color3.fromRGB(60, 30, 40)
	end

	selectButton.Activated:Connect(function()
		pendingScrollPetId = petInfo.Id
		petSelect:FireServer(petInfo.Id)
	end)

	petRows[petInfo.Id] = row
end

-- ============ สมุดสัตว์เลี้ยง: แถวของแต่ละชนิด ============
local BOOK_ABILITY_ICONS = { Planter = "🌱", Harvester = "🌾", Fisher = "🎣", ScarecrowPlacer = "👻", TreasureDigger = "🐾", KrathongCollector = "🌸" }
local bookRows = {}
local function clearBookRows()
	for _, row in ipairs(bookRows) do row:Destroy() end
	bookRows = {}
end
local function createBookRow(petInfo, order)
	local locked = petInfo.Owned == false
	local tier = PetRarity.Get(petInfo.Rarity)
	local row = Instance.new("TextButton") -- ปุ่ม (กดไม่ทำอะไร) ให้จอยเลือก/เลื่อนรายการได้
	row.Name = "BookRow_" .. petInfo.Id
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -8, 0, 80)
	row.BackgroundColor3 = tier.RowColor
	row.BackgroundTransparency = locked and 0.35 or 0
	row.AutoButtonColor = false
	row.Text = ""
	row.Selectable = true
	row.Parent = bookListFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	if tier.Order > 1 then
		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = tier.Color
		rowStroke.Thickness = 2
		rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rowStroke.Parent = row
		if tier.Gradient then
			rowStroke.Color = Color3.new(1, 1, 1)
			rowStroke.Thickness = 3
			addRarityGradient(rowStroke, tier.Gradient)
		end
	end

	createPetPreview(row, petInfo.Id, locked)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -168, 0, 20)
	nameLabel.Position = UDim2.new(0, 80, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = locked and "???" or petInfo.DisplayName
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextColor3 = Color3.fromRGB(70, 40, 35)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	local rarityBadge = Instance.new("TextLabel")
	rarityBadge.Size = UDim2.new(0, 70, 0, 16)
	rarityBadge.Position = UDim2.new(1, -80, 0, 6)
	rarityBadge.BackgroundColor3 = tier.Color
	rarityBadge.Text = tier.DisplayName
	rarityBadge.Font = Enum.Font.GothamBold
	rarityBadge.TextSize = 11
	rarityBadge.TextColor3 = Color3.new(1, 1, 1)
	rarityBadge.Parent = row
	Instance.new("UICorner", rarityBadge).CornerRadius = UDim.new(1, 0)
	if tier.Gradient then
		rarityBadge.BackgroundColor3 = Color3.new(1, 1, 1)
		rarityBadge.TextStrokeTransparency = 0.2
		rarityBadge.TextStrokeColor3 = tier.Color
		addRarityGradient(rarityBadge, tier.Gradient)
	end

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(0, 70, 0, 24)
	status.Position = UDim2.new(1, -80, 0, 28)
	status.BackgroundColor3 = locked and Color3.fromRGB(215, 205, 210) or Color3.fromRGB(190, 238, 185)
	status.Text = locked and tr("🔒 ยังไม่มี", "🔒 Not yet") or tr("✅ มีแล้ว", "✅ Owned")
	status.Font = Enum.Font.GothamBold
	status.TextSize = 12
	status.TextColor3 = locked and Color3.fromRGB(120, 100, 105) or Color3.fromRGB(40, 110, 40)
	status.Parent = row
	Instance.new("UICorner", status).CornerRadius = UDim.new(0, 8)

	-- ความสามารถ + โชค แสดงทั้งตัวที่มีแล้วและยังไม่มี (ผู้เล่นขอ 2026-10-02: เห็นความสามารถแล้วอยากได้ตัวที่ยังไม่มี)
	local parts = {}
	for _, ability in ipairs(petInfo.Abilities or {}) do
		if ability.Id ~= "Lucky" then
			local shortName = ability.DisplayName:gsub(" %(ผลผลิต (x[%d%.]+)%)", " %1")
			table.insert(parts, (BOOK_ABILITY_ICONS[ability.Id] or "⭐") .. " " .. shortName)
		end
	end
	if petInfo.Luck and petInfo.Luck > 0 then table.insert(parts, tr("🍀 โชค x", "🍀 Luck x") .. petInfo.Luck) end
	local info = Instance.new("TextLabel")
	info.Name = "Abilities"
	info.Size = UDim2.new(1, -168, 0, 40)
	info.Position = UDim2.new(0, 80, 0, 30)
	info.BackgroundTransparency = 1
	info.Font = Enum.Font.GothamBold
	info.TextWrapped = true
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextScaled = true
	info.Text = #parts > 0 and table.concat(parts, "\n") or "—" -- ความสามารถละบรรทัด (ช่องแคบ ตัดคำกลางข้อความไม่สวย)
	info.TextColor3 = Color3.fromRGB(100, 80, 75)
	local infoSize = Instance.new("UITextSizeConstraint")
	infoSize.MaxTextSize = 12
	infoSize.MinTextSize = 8
	infoSize.Parent = info
	info.Parent = row

	-- ความสามารถพิเศษ (สีส้ม เต็มความกว้างใต้รูป) ตัดส่วนที่ซ้ำกับบรรทัดบนออกเหมือนแท็บสัตว์เลี้ยง
	local y = 76
	local special = petSpecialText(petInfo)
	if special then
		local desc = Instance.new("TextLabel")
		desc.Name = "Special"
		desc.Size = UDim2.new(1, -16, 0, 30)
		desc.Position = UDim2.new(0, 8, 0, y)
		desc.BackgroundTransparency = 1
		desc.Text = special
		desc.Font = Enum.Font.GothamBold
		desc.TextSize = 12
		desc.TextColor3 = Color3.fromRGB(190, 110, 20)
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Parent = row
		y += 32
	end
	-- ยังไม่มี: บอกวิธีได้มา (สีฟ้า) ใต้สุด
	if locked then
		local hint = Instance.new("TextLabel")
		hint.Name = "HowToGet"
		hint.Size = UDim2.new(1, -16, 0, 16)
		hint.Position = UDim2.new(0, 8, 0, y)
		hint.BackgroundTransparency = 1
		hint.Text = (type(petInfo.UnlockHint) == "string" and petInfo.UnlockHint ~= "") and petInfo.UnlockHint or tr("🐾 ได้จากตู้สุ่มสัตว์เลี้ยง", "🐾 Get from Pet Gacha Machine")
		hint.Font = Enum.Font.GothamBold
		hint.TextSize = 12
		hint.TextColor3 = Color3.fromRGB(60, 115, 175)
		hint.TextXAlignment = Enum.TextXAlignment.Left
		hint.TextTruncate = Enum.TextTruncate.AtEnd
		hint.Parent = row
		y += 20
	end
	row.Size = UDim2.new(1, -8, 0, math.max(80, y + 4))

	table.insert(bookRows, row)
end

-- สมุด: ทุกชนิด เรียงหายากขึ้นก่อน (ไม่แยกมี/ไม่มี จะได้เห็นว่าขาดตัวไหนในระดับไหน)
local function rebuildBook(petList, ownedCount)
	clearBookRows()
	bookHeader.Text = tr(string.format("📖 สะสมแล้ว %d/%d ชนิด", ownedCount, #petList), string.format("📖 Collected %d/%d types", ownedCount, #petList))
	local sorted = table.clone(petList)
	table.sort(sorted, function(a, b)
		local ra, rb = PetRarity.Get(a.Rarity).Order, PetRarity.Get(b.Rarity).Order
		if ra ~= rb then return ra > rb end
		return a.Id < b.Id
	end)
	for i, petInfo in ipairs(sorted) do createBookRow(petInfo, i) end
end

-- ยังไม่มีสัตว์เลี้ยงสักตัว (ผู้เล่นใหม่ไม่ได้กระต่ายแล้ว 2026-10-02): บอกว่าไปหาได้ที่ไหน
local emptyHint = Instance.new("TextLabel")
emptyHint.Name = "EmptyHint"
emptyHint.LayoutOrder = 0
emptyHint.BackgroundTransparency = 1
emptyHint.Size = UDim2.new(1, -8, 0, 90)
emptyHint.Font = Enum.Font.GothamBold
emptyHint.TextSize = 15
emptyHint.TextWrapped = true
emptyHint.TextColor3 = Color3.fromRGB(110, 80, 60)
emptyHint.Text = tr("🐾 ยังไม่มีสัตว์เลี้ยง\nสุ่มได้ที่ตู้สุ่มสัตว์เลี้ยง ข้างร้านค้า (กด ☰ → วาป → ร้านค้า)\nดูสัตว์ที่หาได้ในแท็บ \"📖 สมุด\"", "🐾 No pets yet\nGet one at the Pet Gacha Machine next to the shop (tap ☰ → Warp → Shop)\nSee all pets in the \"📖 Book\" tab")
emptyHint.Visible = false
emptyHint.Parent = petListFrame

petListInfo.OnClientEvent:Connect(function(petList, activeList)
	-- activeList คือ array ของ petId ที่กำลังใช้งานอยู่
	activePetIds = {}
	if activeList then
		for _, petId in ipairs(activeList) do
			activePetIds[petId] = true
		end
	end
	clearPetRows()
	-- นับจำนวนที่มี โชว์ที่หัวเมนู เช่น "สัตว์เลี้ยงของฉัน (3/6)" ให้อยากสะสมให้ครบ
	local ownedCount = 0
	for _, info in ipairs(petList) do
		if info.Owned ~= false then ownedCount += 1 end
	end
	title.Text = tr(string.format("🐾 สัตว์เลี้ยงของฉัน (%d/%d)", ownedCount, #petList), string.format("🐾 My Pets (%d/%d)", ownedCount, #petList))
	rebuildBook(petList, ownedCount) -- สมุด: ทุกชนิด (ตัวที่ยังไม่มีอยู่ในสมุดเท่านั้น)
	-- แท็บสัตว์เลี้ยง: เฉพาะตัวที่มีแล้ว
	local ownedList = {}
	for _, info in ipairs(petList) do
		if info.Owned ~= false then table.insert(ownedList, info) end
	end
	petList = ownedList
	emptyHint.Visible = #ownedList == 0
	-- ตัวที่ใช้งานอยู่ขึ้นบนสุด / ตัวที่ยังไม่มีไปอยู่ล่างสุด / นอกนั้นหายากกว่าขึ้นก่อน ระดับเดียวกันเรียงตามชื่อ
	table.sort(petList, function(a, b)
		local lockedA, lockedB = a.Owned == false, b.Owned == false
		if lockedA ~= lockedB then return lockedB end
		local activeA, activeB = activePetIds[a.Id] == true, activePetIds[b.Id] == true
		if activeA ~= activeB then return activeA end
		local ra, rb = PetRarity.Get(a.Rarity).Order, PetRarity.Get(b.Rarity).Order
		if ra ~= rb then return ra > rb end
		return a.Id < b.Id
	end)
	for i, petInfo in ipairs(petList) do
		createPetRow(petInfo)
		petRows[petInfo.Id].LayoutOrder = i -- แสดงตามลำดับที่เรียงไว้ (ตัวที่ใช้อยู่อยู่บนสุด)
	end
	if pendingScrollPetId then
		local petId = pendingScrollPetId
		pendingScrollPetId = nil
		petListFrame.CanvasPosition = Vector2.new(0, 0)
		task.defer(function()
			petListFrame.CanvasPosition = Vector2.new(0, 0) -- ขนาด canvas อัปเดตหลังจัดแถว ตั้งซ้ำอีกรอบ
			local row = petRows[petId]
			if row and activePetIds[petId] then
				local original = row.BackgroundColor3
				row.BackgroundColor3 = Color3.fromRGB(255, 236, 150)
				game:GetService("TweenService"):Create(row, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = original }):Play()
			end
		end)
	end
end)

petAbilitiesInfo.OnClientEvent:Connect(function(abilityList)
	clearAbilityButtons()
	for _, ability in ipairs(abilityList) do
		createAbilityButton(ability.Id, ability.DisplayName, ability.Note)
	end
end)

petAbilityToggle.OnClientEvent:Connect(function(abilityId, isEnabled)
	local button = abilityButtons[abilityId]
	if not button then return end
	local baseName = button.Text:match("✨ ([^:]+)") or button.Text
	baseName = baseName:gsub("%s+$", "")
	if abilityId == "Lucky" then
		button.Text = "✨ " .. baseName -- แค่ชื่อ เปิดตลอด (เซิร์ฟเวอร์บังคับ)
		button.BackgroundColor3 = Color3.fromRGB(160, 230, 160)
		return
	end
	if isEnabled then
		button.Text = "✨ " .. baseName .. tr(": เปิด", ": On")
		button.BackgroundColor3 = Color3.fromRGB(160, 230, 160)
	else
		button.Text = "✨ " .. baseName .. tr(": ปิด", ": Off")
		button.BackgroundColor3 = Color3.fromRGB(255, 200, 220)
	end
end)
-- ============ จอย ============
-- เปิดเมนู (จากการ์ดในแผงสัตว์ / ปุ่ม 🐾) ด้วยจอย = เลือกปุ่มให้เลย · A กด · LB/RB สลับแท็บ · B ปิด
-- รายการสัตว์/ความสามารถถูกสร้างใหม่ทุกครั้งที่เซิร์ฟเวอร์ส่งข้อมูลมา (เช่นหลังกดเลือกสัตว์) ปุ่มที่เลือกอยู่จะถูกลบ
-- จึงจำไว้ว่าเลือกอะไรอยู่ แล้วเลือกปุ่มของสัตว์/ความสามารถตัวเดิมคืนให้
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function usingGamepad() return GAMEPAD_INPUTS[UserInputService:GetLastInputType()] == true end
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(mainFrame)
end

-- เลื่อนรายการให้เห็นปุ่มที่เลือก (หน่วย CanvasPosition เป็นหน่วยก่อนย่อด้วย UIScale)
local function scrollIntoView(obj)
	local scroller = obj:FindFirstAncestorWhichIsA("ScrollingFrame")
	if not scroller then return end
	local scale = menuScale.Scale
	local top = (obj.AbsolutePosition.Y - scroller.AbsolutePosition.Y) / scale
	local bottom = top + obj.AbsoluteSize.Y / scale
	local view = scroller.AbsoluteSize.Y / scale
	if top < 0 then
		scroller.CanvasPosition = Vector2.new(0, math.max(0, scroller.CanvasPosition.Y + top - 6))
	elseif bottom > view then
		scroller.CanvasPosition = Vector2.new(0, scroller.CanvasPosition.Y + bottom - view + 6)
	end
end

-- ปุ่มแรกของแท็บที่เปิดอยู่ (เรียงตาม LayoutOrder: ตำแหน่งบนจอยังไม่อัปเดตทันทีหลังสร้างแถวใหม่)
local function firstInTab()
	if petListFrame.Visible then
		local best
		for _, row in ipairs(petListFrame:GetChildren()) do
			local b = row:IsA("Frame") and row:FindFirstChild("SelectButton")
			if b and (not best or row.LayoutOrder < best.Parent.LayoutOrder) then best = b end
		end
		return best or slotBuy
	end
	if bookListFrame.Visible then
		local best
		for _, b in ipairs(bookListFrame:GetChildren()) do
			if b:IsA("TextButton") and (not best or b.LayoutOrder < best.LayoutOrder) then best = b end
		end
		return best or bookTab
	end
	local best
	for _, b in ipairs(abilityListFrame:GetChildren()) do
		if b:IsA("TextButton") and (not best or b.LayoutOrder < best.LayoutOrder) then best = b end
	end
	return best or abilitiesTab
end

local function selectTarget(target)
	if not target then return end
	GuiService.SelectedObject = target
	task.defer(scrollIntoView, target)
end

-- สิ่งที่เลือกอยู่ล่าสุด เป็นคีย์ที่หาใหม่ได้หลังสร้างรายการใหม่
local lastKey = nil
local function keyOf(sel)
	if sel.Name == "SelectButton" and sel.Parent then return "pet:" .. sel.Parent.Name end
	return sel.Name
end
local function findKey(key)
	if not key then return nil end
	if key:sub(1, 4) == "pet:" then
		local row = petListFrame:FindFirstChild(key:sub(5))
		return row and row:FindFirstChild("SelectButton")
	end
	local obj = mainFrame:FindFirstChild(key, true)
	return obj and obj:IsA("GuiButton") and obj or nil
end
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(mainFrame) then
		lastKey = keyOf(sel)
		scrollIntoView(sel)
	end
end)

local function switchTab(which)
	showTab(which)
	if usingGamepad() and mainFrame.Visible then selectTarget(firstInTab()) end
end
petsTab.Activated:Connect(function() if usingGamepad() then switchTab("pets") end end)
abilitiesTab.Activated:Connect(function() if usingGamepad() then switchTab("abilities") end end)
bookTab.Activated:Connect(function() if usingGamepad() then switchTab("book") end end)
local TAB_ORDER = { "pets", "abilities", "book" }

-- เปิดเมนูด้วยจอย: สัตว์ที่ขอ (จากการ์ด) / ปุ่มแรกของแท็บ
local function selectOnOpen(petId)
	task.defer(function()
		if not (mainFrame.Visible and usingGamepad()) or selectionInside() then return end
		local target = type(petId) == "string" and findKey("pet:PetRow_" .. petId) or nil
		selectTarget(target or firstInTab())
	end)
end
openButton.Activated:Connect(function() selectOnOpen(nil) end)
openRequest.Event:Connect(selectOnOpen)

local function closeMenu()
	mainFrame.Visible = false
end
mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if not mainFrame.Visible then
		if selectionInside() then GuiService.SelectedObject = nil end
		lastKey = nil
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if not mainFrame.Visible then return end
	if input.KeyCode == Enum.KeyCode.ButtonB then
		closeMenu()
	elseif (input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.ButtonR1) and selectionInside() then
		-- LB = แท็บก่อนหน้า / RB = แท็บถัดไป (วน 3 แท็บ)
		local index = table.find(TAB_ORDER, currentTab) or 1
		local step = input.KeyCode == Enum.KeyCode.ButtonL1 and -1 or 1
		switchTab(TAB_ORDER[(index - 1 + step) % #TAB_ORDER + 1])
	end
end)

-- ปุ่มที่เลือกอยู่ถูกลบ (สร้างรายการใหม่) / ถูกซ่อน (สลับแท็บ) = เลือกตัวเดิมคืน หรือปุ่มแรกของแท็บ
RunService.Heartbeat:Connect(function()
	if not (mainFrame.Visible and lastKey and usingGamepad()) then return end
	local sel = GuiService.SelectedObject
	local lost = sel == nil or not sel:IsDescendantOf(mainFrame)
	if sel and sel:IsDescendantOf(mainFrame) then
		local list = sel:FindFirstAncestorWhichIsA("ScrollingFrame")
		if list and not list.Visible then lost = true end
	end
	if not lost then return end
	if sel ~= nil and not sel:IsDescendantOf(mainFrame) then
		-- ผู้เล่นย้ายไปเลือกที่อื่นเอง (เช่นแผงสัตว์) ไม่ดึงกลับ
		lastKey = nil
		return
	end
	local target = findKey(lastKey)
	if not (target and target.Visible and not (target:FindFirstAncestorWhichIsA("ScrollingFrame") and not target:FindFirstAncestorWhichIsA("ScrollingFrame").Visible)) then
		target = firstInTab()
	end
	selectTarget(target)
end)

-- ป้ายแท็บบอกปุ่มจอย (LB/RB) เฉพาะตอนใช้จอย
local function updateTabHints()
	local pad = usingGamepad()
	petsTab.Text = pad and tr("LB 🐾 สัตว์เลี้ยง", "LB 🐾 Pets") or tr("🐾 สัตว์เลี้ยง", "🐾 Pets")
	abilitiesTab.Text = tr("✨ ความสามารถ", "✨ Abilities")
	bookTab.Text = pad and tr("📖 สมุด RB", "📖 Book RB") or tr("📖 สมุด", "📖 Book")
end
UserInputService.LastInputTypeChanged:Connect(updateTabHints)
updateTabHints()

-- กรอบทองตอนเลือก (เหมือนหน้าต่างอื่น) ติดให้ทุกปุ่มในเมนู (รวมปุ่มที่สร้างใหม่ทีหลัง)
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
for _, d in ipairs(mainFrame:GetDescendants()) do styleSelectable(d) end
mainFrame.DescendantAdded:Connect(styleSelectable)

-- ============ จุดเตือนที่ปุ่ม 🐾 ============
-- แผงสัตว์ที่ใช้อยู่ (ActivePetsHud) เลิกใช้แล้ว: ตัวที่พาออกมาหิวมาก / ชามอาหารใกล้หมด = ขึ้น "!" แดงที่ปุ่ม 🐾 แทน
local HUNGRY_WARN = 20
local alertDot = Instance.new("TextLabel")
alertDot.Name = "AlertDot"
alertDot.AnchorPoint = Vector2.new(0.5, 0.5)
alertDot.Position = UDim2.new(1, -4, 0, 4)
alertDot.Size = UDim2.new(0, 18, 0, 18)
alertDot.BackgroundColor3 = Color3.fromRGB(230, 70, 60)
alertDot.Text = "!"
alertDot.Font = Enum.Font.GothamBlack
alertDot.TextSize = 13
alertDot.TextColor3 = Color3.new(1, 1, 1)
alertDot.ZIndex = 3
alertDot.Visible = false
alertDot.Parent = openButton
Instance.new("UICorner", alertDot).CornerRadius = UDim.new(1, 0)
local alertStroke = Instance.new("UIStroke"); alertStroke.Color = Color3.new(1, 1, 1); alertStroke.Thickness = 1.5; alertStroke.Parent = alertDot
local function needsAttention()
	for petId in pairs(activePetIds) do
		if (player:GetAttribute("PetHunger_" .. petId) or 100) <= HUNGRY_WARN then return true end
	end
	if player:GetAttribute("HasAutoFeeder") and player:GetAttribute("AutoFeederOn") ~= false
		and player:GetAttribute("AutoFeederFood") ~= nil -- ยังโหลดไม่เสร็จ ไม่เตือนว่าหมด
		and player:GetAttribute("AutoFeederFood") <= AutoFeederConfig.LOW_WARNING then
		return true
	end
	return false
end
local function updateAlert()
	alertDot.Visible = needsAttention()
end
player.AttributeChanged:Connect(function(name)
	if name:sub(1, 10) == "PetHunger_" or name:sub(1, 10) == "AutoFeeder" or name == "HasAutoFeeder" then updateAlert() end
end)
petListInfo.OnClientEvent:Connect(function() task.defer(updateAlert) end)
updateAlert()
