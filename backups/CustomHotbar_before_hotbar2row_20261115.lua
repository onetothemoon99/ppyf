-- BACKUP 2026-11-15 ก่อนทำ hotbar 2 แถว (12 ช่อง + ปุ่มย่อ)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.CustomHotbar (LocalScript)
-- คืนค่า: เปิดสคริปต์นี้ใน Studio แล้ววางโค้ดด้านล่าง (ใต้บรรทัด ===) ทับทั้งหมด
-- ========================================================================
-- CustomHotbar: แถบไอเทมสไตล์ Harvest Moon (แยกเมล็ด/ผลผลิตด้วยแถบสีบนสุด)

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HotbarState = require(script.Parent:WaitForChild("HotbarState"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local RarityFrame = require(ReplicatedStorage:WaitForChild("RarityFrame")) -- กรอบสีตามระดับ (ปลา)
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig")) -- ผักกลายพันธุ์ (แถบสี/ชื่อบนช่อง)
local ItemPreview = require(ReplicatedStorage:WaitForChild("ItemPreview")) -- โมเดล 3D แทนไอคอน (เช่นหุ่นข้าวโพด)
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig")) -- สี/ชื่อ/ไอคอนประจำรุ่นเบ็ด
local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig")) -- ของตกแต่ง (ไอคอน) 2026-10-16
local KrathongConfig = require(ReplicatedStorage:WaitForChild("KrathongConfig")) -- กระทง (สีแถบ) 2026-11-07
local LANG = Localization.GetLanguage(player)
local tr = Localization.Pick
-- tr(LANG, "ไทย", "English") for quick inline bilingual strings

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local COLOR_CREAM = Color3.fromRGB(255, 250, 230)
local COLOR_BROWN = Color3.fromRGB(140, 100, 65)
local COLOR_GREEN_DARK = Color3.fromRGB(85, 135, 65)
local COLOR_TEXT_DARK = Color3.fromRGB(60, 45, 30)
local COLOR_SLOT_EMPTY = Color3.fromRGB(235, 225, 200)
local COLOR_SLOT_EQUIPPED = Color3.fromRGB(255, 250, 240) -- อ่อนลง ให้กรอบทองเด่นขึ้นเวลาตัดกัน
local COLOR_SLOT_PENDING_TARGET = Color3.fromRGB(255, 245, 200) -- ไฮไลต์ตอนมีไอเทมรอวางอยู่
local COLOR_SLOT_BLOCKED = Color3.fromRGB(225, 95, 85) -- ช่องที่รับไอเทมชิ้นนั้นไม่ได้

local COLOR_SEED_STRIP = Color3.fromRGB(120, 85, 55)   -- แถบบน: น้ำตาลเข้ม (เมล็ด)
local COLOR_SEED_BG = Color3.fromRGB(222, 200, 165)     -- พื้นกล่อง: ครีมกระดาษ (เมล็ด)
local COLOR_PRODUCE_STRIP = Color3.fromRGB(230, 165, 45) -- แถบบน: ทอง/ส้ม (ผลผลิต)
local COLOR_PRODUCE_BG = Color3.fromRGB(195, 225, 165)   -- พื้นกล่อง: เขียวอ่อน (ผลผลิต)
local COLOR_BOOSTER_STRIP = Color3.fromRGB(90, 160, 210) -- แถบบน: ฟ้า (หุ่นเพิ่มดวง)
local COLOR_BOOSTER_BG = Color3.fromRGB(210, 230, 245)   -- พื้นกล่อง: ฟ้าอ่อน (หุ่นเพิ่มดวง)

local CROP_ICON = {
	Strawberry = "🍓",
	Corn = "🌽",
	Wheat = "🌾",
	Onion = "🧅",
	Watermelon = "🍉",
	Pineapple = "🍍",
	Potato = "🥔",
	Cucumber = "🥒",
	Eggplant = "🍆",
	Pumpkin = "🎃", WitchBerry = "🍇",
	Carrot = "🥕",
	Sunflower = "🌻",
	Chili = "🌶️",
}

local MAX_SLOTS = 6 -- ต้องเท่ากับ HotbarState (ช่อง 6 = เบ็ด)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomHotbar"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1
screenGui.Parent = playerGui

local hotbarFrame = Instance.new("Frame")
hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
hotbarFrame.Position = UDim2.new(0.5, 0, 1, -10)
hotbarFrame.Size = UDim2.new(0, 0, 0, 0)
-- Size will be set after layout constants are defined
hotbarFrame.BackgroundColor3 = COLOR_CREAM
hotbarFrame.Parent = screenGui

Instance.new("UICorner", hotbarFrame).CornerRadius = UDim.new(0, 14)
local hotbarStroke = Instance.new("UIStroke")
hotbarStroke.Color = COLOR_BROWN
hotbarStroke.Thickness = 3
hotbarStroke.Parent = hotbarFrame

local hotbarPadding = Instance.new("UIPadding")
hotbarPadding.PaddingLeft = UDim.new(0, 10)
hotbarPadding.PaddingRight = UDim.new(0, 10)
hotbarPadding.PaddingTop = UDim.new(0, 10)
hotbarPadding.PaddingBottom = UDim.new(0, 10)
hotbarPadding.Parent = hotbarFrame

local BASE_SLOT_W, BASE_SLOT_H = 56, 58
local BASE_GAP, BASE_PAD = 8, 10

hotbarFrame.Size = UDim2.new(0, BASE_PAD*2 + MAX_SLOTS*BASE_SLOT_W + (MAX_SLOTS-1)*BASE_GAP, 0, BASE_PAD*2 + BASE_SLOT_H)

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.Padding = UDim.new(0, BASE_GAP)
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Parent = hotbarFrame

-- ย่อทั้งแถบด้วย UIScale ตัวเดียว ลูกทุกชิ้น (แถบสี, ตัวเลข, ปุ่ม x, ป้ายจำนวน) ย่อตามเองหมด
-- ถ้าไปแก้ขนาดช่องตรงๆ ต้องไล่แก้ offset ของลูกทุกชิ้นตาม
local uiScale = Instance.new("UIScale")
uiScale.Parent = hotbarFrame

local slotButtons = {}

local function getToolIconText(tool)
	if tool:GetAttribute("IsPetFood") then return "🥫" end
	if tool:GetAttribute("IsFishingRod") then return "🎣" end
	if tool:GetAttribute("IsFish") then return "🐟" end
	if tool:GetAttribute("IsBait") then return "🐛" end
	if tool:GetAttribute("IsBooster") then return "🍀" end
	if tool:GetAttribute("IsDrink") then return tool:GetAttribute("DrinkIcon") or "🍹" end -- แก้วจากบาร์ริมหาด
	if tool:GetAttribute("IsHeldBroom") then return "🧹" end -- ไม้กวาดกวาดเล้าไก่ 2026-10-23
	if tool:GetAttribute("OrchardIcon") then return tool:GetAttribute("OrchardIcon") end -- เมล็ด/ผลไม้สวน 2026-10-26
	if tool:GetAttribute("IsKrathong") then return KrathongConfig.IsLantern(tool:GetAttribute("KrathongId")) and "🏮" or "🌸" end -- กระทง / โคมลอย 2026-11-07
	if tool:GetAttribute("IsHeldChicken") then return "🐔" end -- ไก่ที่อุ้มอยู่ 2026-10-21
	if tool:GetAttribute("IsFurniture") then
		local def = MountConfig.Furniture[tool:GetAttribute("FurnId")]
		return def and def.Icon or "🪑"
	end
	local cropType = tool:GetAttribute("CropType")
	return CROP_ICON[cropType] or "🌱"
end

-- สลับระหว่างโมเดล 3D กับไอคอน refreshHotbar เรียกทุก 0.5 วินาที จึงสร้างใหม่เฉพาะตอนไอเทมในช่องเปลี่ยนชนิด
local HOTBAR_PREVIEW_ZOOM = 1.3

local function setSlotPreview(slotData, previewName)
	if slotData.previewName == previewName and (slotData.preview or not previewName) then return end
	if slotData.preview then
		slotData.preview:Destroy()
		slotData.preview = nil
	end
	slotData.previewName = previewName
	if previewName then
		-- ไม่มีโมเดล (เมล็ดทั่วไป) ได้ nil และใช้ไอคอนเดิม
		-- ช่องเล็ก ซูมเข้าให้หุ่นใหญ่ขึ้น ยอมให้ปลายเสาด้านล่างโดนตัดนิดหน่อย
		-- ซองเมล็ด (2026-10-31) ไม่ซูม ให้เห็นทั้งซองรวมป้าย SEED ด้านล่าง
		-- ท่อนไม้ / ปุ๋ยไม้ผล (2026-11-03) ไม่ซูมด้วย ถุงปุ๋ยทรงสูง ซูมแล้วเห็นแค่ครึ่งบน
		local noZoom = string.sub(previewName, 1, 11) == "SeedPacket_" or string.sub(previewName, 1, 11) == "OrchardMat_" or string.sub(previewName, 1, 13) == "OrchardFruit_"
		local zoom = noZoom and 1 or HOTBAR_PREVIEW_ZOOM
		slotData.preview = ItemPreview.Create(slotData.itemBox, previewName, zoom)
		if not slotData.preview then
			slotData.previewName = nil -- ลองใหม่รอบหน้า เผื่อโมเดลยังมาไม่ถึงตอนเข้าเกม
		end
	end
	slotData.icon.Visible = slotData.preview == nil
end

local function createSlot(index)
	local slot = Instance.new("TextButton")
	slot.Name = "Slot" .. index
	slot.LayoutOrder = index
	slot.BackgroundColor3 = COLOR_SLOT_EMPTY
	slot.AutoButtonColor = false
	slot.Text = ""
	slot.ClipsDescendants = false
	slot.Selectable = false -- กันไม่ให้ระบบจอยเลือกปุ่มนี้อัตโนมัติ (คุมด้วย L1/R1 เอง)
	slot.Size = UDim2.new(0, BASE_SLOT_W, 0, BASE_SLOT_H)
	slot.Parent = hotbarFrame

	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR_BROWN
	stroke.Thickness = 2
	stroke.Parent = slot

	-- กรอบเรืองแสงสีทอง (โชว์เฉพาะตอนถืออยู่ ซ้อนอยู่ด้านนอก stroke ปกติ)
	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "GlowFrame"
	glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	glowFrame.Size = UDim2.new(1, 14, 1, 14)
	glowFrame.BackgroundTransparency = 1
	glowFrame.ZIndex = 20
	glowFrame.Visible = false
	glowFrame.Parent = slot

	Instance.new("UICorner", glowFrame).CornerRadius = UDim.new(0, 16)
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(255, 60, 60) -- สีแดงสด เข้มพอมองเห็นชัด
	glowStroke.Thickness = 5
	glowStroke.Parent = glowFrame

	-- ลูกศรชี้ใต้ช่อง โชว์เฉพาะตอนถืออยู่
	local equippedArrow = Instance.new("TextLabel")
	equippedArrow.Name = "EquippedArrow"
	equippedArrow.AnchorPoint = Vector2.new(0.5, 0)
	equippedArrow.Position = UDim2.new(0.5, 0, 1, 2)
	equippedArrow.Size = UDim2.new(0, 20, 0, 14)
	equippedArrow.BackgroundTransparency = 1
	equippedArrow.Text = "▲"
	equippedArrow.TextColor3 = Color3.fromRGB(60, 160, 255)
	equippedArrow.TextScaled = true
	equippedArrow.Font = Enum.Font.GothamBold
	equippedArrow.Visible = false
	equippedArrow.ZIndex = 5
	equippedArrow.Parent = slot

	-- แถบสีบนสุด เต็มความกว้างช่อง บอกประเภททันทีที่มองเห็น
	local categoryStrip = Instance.new("Frame")
	categoryStrip.Name = "CategoryStrip"
	categoryStrip.Size = UDim2.new(1, 0, 0, 14)
	categoryStrip.Position = UDim2.new(0, 0, 0, 0)
	categoryStrip.BorderSizePixel = 0
	categoryStrip.Visible = false
	categoryStrip.Parent = slot

	local stripLabel = Instance.new("TextLabel")
	stripLabel.Name = "StripLabel"
	stripLabel.Size = UDim2.new(1, 0, 1, 0)
	stripLabel.BackgroundTransparency = 1
	stripLabel.Text = ""
	stripLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	stripLabel.TextScaled = true
	stripLabel.Font = Enum.Font.GothamBold
	stripLabel.Parent = categoryStrip
	local stripSizeConstraint = Instance.new("UITextSizeConstraint")
	stripSizeConstraint.MaxTextSize = 10
	stripSizeConstraint.Parent = stripLabel

	-- กล่องเนื้อหาไอเทม (อยู่ใต้แถบสี)
	local itemBox = Instance.new("Frame")
	itemBox.Name = "ItemBox"
	itemBox.Size = UDim2.new(1, 0, 1, -14)
	itemBox.Position = UDim2.new(0, 0, 0, 14)
	itemBox.BorderSizePixel = 0
	itemBox.Visible = false
	itemBox.Parent = slot

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = ""
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = itemBox

	local countBadge = Instance.new("Frame")
	countBadge.Name = "CountBadge"
	countBadge.AnchorPoint = Vector2.new(1, 1)
	countBadge.Position = UDim2.new(1, -2, 1, -2)
	countBadge.Size = UDim2.new(0, 22, 0, 16)
	countBadge.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
	countBadge.Visible = false
	countBadge.ZIndex = 2 -- ให้อยู่บนโมเดล 3D (ScreenGui นี้ใช้ ZIndexBehavior Global)
	countBadge.Parent = itemBox
	Instance.new("UICorner", countBadge).CornerRadius = UDim.new(0, 6)

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, 0, 1, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ""
	countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.ZIndex = 2
	countLabel.Parent = countBadge
	local countSizeConstraint = Instance.new("UITextSizeConstraint")
	countSizeConstraint.MaxTextSize = 12
	countSizeConstraint.Parent = countLabel

	local hotkeyLabel = Instance.new("TextLabel")
	hotkeyLabel.Name = "Hotkey"
	hotkeyLabel.Position = UDim2.new(0, 2, 0, 15)
	hotkeyLabel.Size = UDim2.new(0, 14, 0, 14)
	hotkeyLabel.BackgroundTransparency = 1
	hotkeyLabel.Text = tostring(index)
	hotkeyLabel.TextColor3 = COLOR_TEXT_DARK
	hotkeyLabel.TextTransparency = 0.4
	hotkeyLabel.TextScaled = true
	hotkeyLabel.Font = Enum.Font.Gotham
	hotkeyLabel.ZIndex = 5
	hotkeyLabel.Parent = slot

	-- ปุ่ม × เล็กๆ มุมขวาบน ไว้ถอดไอเทมออกจากช่องนี้ (กลับไปอยู่แค่ในกระเป๋าเต็ม)
	-- โชว์เฉพาะตอนเปิดกระเป๋าเต็มอยู่เท่านั้น (คุมผ่าน HotbarState.IsInventoryOpen())
	local removeButton = Instance.new("TextButton")
	removeButton.Name = "RemoveButton"
	removeButton.AnchorPoint = Vector2.new(1, 0)
	removeButton.Position = UDim2.new(1, -1, 0, 15)
	removeButton.Size = UDim2.new(0, 15, 0, 15)
	removeButton.BackgroundColor3 = Color3.fromRGB(200, 70, 60)
	removeButton.Text = "×"
	removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	removeButton.TextScaled = true
	removeButton.Font = Enum.Font.GothamBold
	removeButton.Selectable = false
	removeButton.ZIndex = 10
	removeButton.Visible = false
	removeButton.Parent = slot
	Instance.new("UICorner", removeButton).CornerRadius = UDim.new(1, 0)
	do -- กรอบทองตอนจอยเลือกปุ่ม ×
		local ring = Instance.new("Frame")
		ring.BackgroundTransparency = 1
		ring.Size = UDim2.new(1, 10, 1, 10)
		ring.Position = UDim2.new(0, -5, 0, -5)
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(255, 190, 40); rs.Thickness = 3; rs.Parent = ring
		removeButton.SelectionImageObject = ring
	end

	-- แม่กุญแจกลางช่อง โชว์เฉพาะตอนของที่กำลังจะวางลงช่องนี้ไม่ได้ (เช่นหุ่นลงช่อง 1-2)
	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockLabel"
	lockLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	lockLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	lockLabel.Size = UDim2.new(0, 24, 0, 24)
	lockLabel.BackgroundTransparency = 1
	lockLabel.Text = "🔒"
	lockLabel.TextScaled = true
	lockLabel.ZIndex = 30
	lockLabel.Visible = false
	lockLabel.Parent = slot

	-- ช่อง 9 สงวนให้เบ็ด: ตอนว่างโชว์ 🎣 จางๆ ให้รู้ว่าเบ็ดมาอยู่ตรงนี้
	-- ช่อง 1-2 เมล็ดเท่านั้น (2026-10-16): ตอนว่างโชว์ 🌱 จางๆ แบบเดียวกับช่องเบ็ด
	local rodHint
	if index == HotbarState.ROD_SLOT or HotbarState.IsReservedSlot(index) then
		rodHint = Instance.new("TextLabel")
		rodHint.Name = "RodHint"
		rodHint.AnchorPoint = Vector2.new(0.5, 0.5)
		rodHint.Position = UDim2.new(0.5, 0, 0.55, 0)
		rodHint.Size = UDim2.new(0, 28, 0, 28)
		rodHint.BackgroundTransparency = 1
		rodHint.Text = index == HotbarState.ROD_SLOT and "🎣" or "🌱"
		rodHint.TextScaled = true
		rodHint.TextTransparency = 0.6
		rodHint.Parent = slot
	end

	return {
		rodHint = rodHint,
		frame = slot,
		stroke = stroke,
		lockLabel = lockLabel,
		glowFrame = glowFrame,
		equippedArrow = equippedArrow,
		categoryStrip = categoryStrip,
		stripLabel = stripLabel,
		itemBox = itemBox,
		icon = iconLabel,
		countBadge = countBadge,
		countLabel = countLabel,
		removeButton = removeButton,
		tool = nil,
	}
end

for i = 1, MAX_SLOTS do
	slotButtons[i] = createSlot(i)
	HotbarState.RegisterSlotFrame(i, slotButtons[i].frame)
end

local function isCurrentlyEquipped(tool)
	local character = player.Character
	return character and tool.Parent == character
end

local function getBackpack()
	return player:FindFirstChild("Backpack")
end

local function getAllTools()
	local tools = {}
	local backpack = getBackpack()

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then table.insert(tools, item) end
		end
	end

	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then table.insert(tools, item) end
		end
	end

	return tools
end

-- ช่องที่เพิ่งถูกปฏิเสธ: [index] = เวลาที่ให้กระพริบถึง
-- เก็บเป็นเวลาแทนการสั่งโชว์ตรงๆ เพราะ refreshHotbar วาดใหม่ทุก 0.5 วินาที ถ้าสั่งตรงๆ จะโดนลบทิ้งก่อนคนเห็น
local rejectFlashUntil = {}

local function refreshHotbar()
	local tools = getAllTools()

	-- จัดไอเทมใหม่ที่ยังไม่เคยอยู่ในช่องไหนเลย ลงช่องว่างแรกอัตโนมัติ
	HotbarState.AutoAssignNew(tools)

	local pending = HotbarState.GetPending()
	local inventoryOpen = HotbarState.IsInventoryOpen()
	-- ไอเทมที่กำลังจะวาง (เลือกค้างไว้จากกระเป๋าเต็ม หรือกำลังลากอยู่) ใช้บอกว่าช่องไหนรับไม่ได้
	local incoming = pending or HotbarState.GetDragTool()

	for i = 1, MAX_SLOTS do
		local slotData = slotButtons[i]
		local tool = HotbarState.GetSlotTool(i)
		slotData.tool = tool
		slotData.lockLabel.Visible = false

		if tool then
			local isProduce = tool:GetAttribute("IsProduce")
			RarityFrame.Apply(slotData.frame, RarityFrame.GetToolRarity(tool), 10) -- กรอบสีตามระดับ (ปลา)

			slotData.categoryStrip.Visible = true
			slotData.itemBox.Visible = true
			slotData.icon.Text = getToolIconText(tool)
			setSlotPreview(slotData, ItemPreview.GetToolModelName(tool))
			-- ปุ่ม x โชว์เฉพาะตอนเปิดกระเป๋าเต็มอยู่เท่านั้น กันเผลอกดตอนเล่นปกติ
			slotData.removeButton.Visible = inventoryOpen and i ~= HotbarState.ROD_SLOT
			slotData.removeButton.Selectable = inventoryOpen and i ~= HotbarState.ROD_SLOT -- ช่อง 6 เป็นช่องเบ็ด ล็อกไม่ให้ถอดทิ้ง

			if isProduce then
				local star = tool:GetAttribute("Star") or 1
				local count = tool:GetAttribute("Count") or 1

				slotData.categoryStrip.BackgroundColor3 = COLOR_PRODUCE_STRIP
				slotData.stripLabel.Text = Localization.T("Hotbar_Produce", LANG) .. " " .. string.rep("★", star)
				-- ผักกลายพันธุ์ (2026-10-30): แถบสีตามแบบ + ชื่อแบบแทนคำว่า "ผลผลิต"
				local mutation = MutationConfig.Get(tool:GetAttribute("Mutation"))
				if mutation then
					slotData.categoryStrip.BackgroundColor3 = mutation.color
					slotData.stripLabel.Text = MutationConfig.Label(tool:GetAttribute("Mutation"), LANG) .. " " .. string.rep("★", star)
				end
				slotData.itemBox.BackgroundColor3 = COLOR_PRODUCE_BG

				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. count
			elseif tool:GetAttribute("IsFish") then
				-- ปลา: แถบฟ้าอมเขียว + ดาว + จำนวน / ขยะ: แถบน้ำตาล
				local star = tool:GetAttribute("Star") or 1
				local junk = tool:GetAttribute("IsJunk")
				slotData.categoryStrip.BackgroundColor3 = junk and Color3.fromRGB(150, 115, 80) or Color3.fromRGB(70, 175, 185)
				slotData.stripLabel.Text = junk and tr(LANG, "ขยะ", "Junk") or (Localization.T("Hotbar_Fish", LANG) .. " " .. string.rep("★", star))
				slotData.itemBox.BackgroundColor3 = junk and Color3.fromRGB(230, 220, 205) or Color3.fromRGB(210, 240, 245)
				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. (tool:GetAttribute("Count") or 1)
			elseif tool:GetAttribute("IsBait") then
				-- เหยื่อตกปลา: แถบน้ำตาลส้ม + ดาว + จำนวน
				local star = tool:GetAttribute("Star") or 1
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(190, 125, 80)
				slotData.stripLabel.Text = tr(LANG, "เหยื่อ ", "Bait ") .. string.rep("★", star)
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(245, 228, 210)
				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. (tool:GetAttribute("Count") or 1)
			elseif tool:GetAttribute("IsFishingRod") then
				-- เบ็ดตกปลา: สีตามรุ่น + ชื่อรุ่นบนแถบ + ไอคอนรุ่นมุมขวาล่าง (เดิมทุกคันฟ้าเหมือนกัน แยกไม่ออกว่าคันไหน)
				local rodId = tool:GetAttribute("RodId")
				local rod = FishingConfig.Rods[rodId]
				local style = FishingConfig.GetRodStyle(rodId)
				slotData.categoryStrip.BackgroundColor3 = style.Strip
				slotData.stripLabel.Text = FishingConfig.RodShort(rodId, LANG) or Localization.T("Hotbar_Rod", LANG)
				slotData.itemBox.BackgroundColor3 = style.Bg
				slotData.countBadge.Visible = rod ~= nil
				slotData.countLabel.Text = rod and rod.Icon or ""
			elseif tool:GetAttribute("IsPetFood") then
				-- อาหารสัตว์: แถบชมพู + ดาว + จำนวน (แบบเดียวกับผลผลิต)
				local star = tool:GetAttribute("Star") or 1
				local count = tool:GetAttribute("Count") or 1

				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(230, 140, 175)
				slotData.stripLabel.Text = Localization.T("Hotbar_PetFood", LANG) .. " " .. string.rep("★", star)
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(250, 218, 228)

				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. count
			elseif tool:GetAttribute("IsStealHand") then
				-- ตะกร้อขโมย (สวนผลไม้ เฟส 3, เดิมมือขโมย) 2026-10-27: แถบสีไม้ไผ่ + จำนวน
				local bandit = tool:GetAttribute("StealTier") == "Bandit" -- ตะกร้อจอมโจร 2026-11-02: แถบดำ
				slotData.categoryStrip.BackgroundColor3 = bandit and Color3.fromRGB(45, 40, 50) or Color3.fromRGB(160, 120, 55)
				slotData.stripLabel.Text = bandit and tr(LANG, "จอมโจร", "Bandit") or tr(LANG, "ตะกร้อขโมย", "Fruit picker")
				slotData.itemBox.BackgroundColor3 = bandit and Color3.fromRGB(250, 236, 190) or Color3.fromRGB(245, 232, 200)
				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. (tool:GetAttribute("Count") or 1)
			elseif tool:GetAttribute("IsOrchardTool") then
				-- ขวาน / บัวรดน้ำ (สวนผลไม้) 2026-11-02: ของถาวร ไม่แสดงจำนวน
				local can = tool:GetAttribute("OrchardToolId") == "Can"
				slotData.categoryStrip.BackgroundColor3 = can and Color3.fromRGB(70, 160, 190) or Color3.fromRGB(120, 90, 60)
				slotData.stripLabel.Text = can and tr(LANG, "บัวรดน้ำ", "Can") or tr(LANG, "ขวาน", "Axe")
				slotData.itemBox.BackgroundColor3 = can and Color3.fromRGB(215, 240, 245) or Color3.fromRGB(238, 225, 210)
				slotData.countBadge.Visible = false
			elseif tool:GetAttribute("IsKrathong") then
				-- กระทง (ลอยกระทง) 2026-11-07: แถบสีตามชนิด + จำนวน
				local kdef = KrathongConfig.Types[tool:GetAttribute("KrathongId")]
				slotData.categoryStrip.BackgroundColor3 = kdef and kdef.Strip or Color3.fromRGB(230, 110, 160)
				local isLantern = KrathongConfig.IsLantern(tool:GetAttribute("KrathongId"))
				slotData.stripLabel.Text = (kdef and kdef.TagTh) and tr(LANG, kdef.TagTh, kdef.TagEn) or (isLantern and tr(LANG, "โคมลอย", "Lantern") or tr(LANG, "กระทง", "Krathong")) -- โคมแขวน 2026-11-08
				slotData.itemBox.BackgroundColor3 = kdef and kdef.Bg or Color3.fromRGB(255, 228, 240)
				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. (tool:GetAttribute("Count") or 1)
			elseif tool:GetAttribute("IsOrchardMat") then
				-- ท่อนไม้ / ปุ๋ยไม้ผล (สวนผลไม้) 2026-11-02: แถบสีไม้ / เขียว + จำนวน
				local fert = tool:GetAttribute("MatId") == "Fertilizer"
				slotData.categoryStrip.BackgroundColor3 = fert and Color3.fromRGB(110, 170, 70) or Color3.fromRGB(140, 95, 55)
				slotData.stripLabel.Text = fert and tr(LANG, "ปุ๋ย", "Fertilizer") or tr(LANG, "ท่อนไม้", "Log")
				slotData.itemBox.BackgroundColor3 = fert and Color3.fromRGB(228, 245, 210) or Color3.fromRGB(240, 225, 205)
				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. (tool:GetAttribute("Count") or 1)
			elseif tool:GetAttribute("IsSlapHand") then
				-- มือตบ (สวนผลไม้) 2026-10-29: แถบชมพู · ของถาวร ไม่แสดงจำนวน
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(235, 110, 140)
				slotData.stripLabel.Text = tr(LANG, "มือตบ", "Slap hand")
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(255, 228, 234)
				slotData.countBadge.Visible = false
			elseif tool:GetAttribute("IsOrchardFruit") or tool:GetAttribute("IsOrchardSeed") then
				-- เมล็ด/ผลไม้สวน (มะม่วง/ทุเรียน) 2026-10-26: แถบเขียวเข้ม + จำนวน
				local fruit = tool:GetAttribute("IsOrchardFruit")
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(95, 140, 60)
				slotData.stripLabel.Text = fruit and tr(LANG, "ผลไม้", "Fruit") or tr(LANG, "เมล็ดไม้", "Tree seed")
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(228, 242, 210)
				slotData.countBadge.Visible = true
				slotData.countLabel.Text = "x" .. (tool:GetAttribute("Count") or 1)
			elseif tool:GetAttribute("IsFurniture") then
				-- ของตกแต่งจากตู้สัตว์ขี่ (ถือแล้ววางด้วยไกด์ FurniturePlacer) 2026-10-16
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(150, 110, 200)
				slotData.stripLabel.Text = tr(LANG, "ที่นั่ง", "Seat")
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(238, 228, 250)
				slotData.countBadge.Visible = false
			elseif tool:GetAttribute("IsHeldBroom") then
				-- ไม้กวาดกวาดเล้าไก่ (ของชั่วคราว ไม่เซฟ) 2026-10-23
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(190, 150, 90)
				slotData.stripLabel.Text = tr(LANG, "ไม้กวาด", "Broom")
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(250, 238, 215)
				slotData.countBadge.Visible = false
			elseif tool:GetAttribute("IsHeldChicken") then
				-- ไก่ที่อุ้มอยู่ (ของชั่วคราว ไม่เซฟ) 2026-10-21
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(255, 160, 175)
				slotData.stripLabel.Text = tr(LANG, "ไก่", "Chicken")
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(255, 238, 240)
				slotData.countBadge.Visible = false
			elseif tool:GetAttribute("IsDrink") then
				-- เครื่องดื่มจากบาร์ริมหาด (ของชั่วคราว ไม่มีจำนวน)
				slotData.categoryStrip.BackgroundColor3 = Color3.fromRGB(255, 150, 120)
				slotData.stripLabel.Text = tr(LANG, "เครื่องดื่ม", "Drink")
				slotData.itemBox.BackgroundColor3 = Color3.fromRGB(255, 232, 220)
				slotData.countBadge.Visible = false
			elseif tool:GetAttribute("IsBooster") then
				local count = tool:GetAttribute("Count") or 1

				slotData.categoryStrip.BackgroundColor3 = COLOR_BOOSTER_STRIP
				slotData.stripLabel.Text = Localization.T("Hotbar_Booster", LANG)
				slotData.itemBox.BackgroundColor3 = COLOR_BOOSTER_BG

				if count > 1 then
					slotData.countBadge.Visible = true
					slotData.countLabel.Text = "x" .. count
				else
					slotData.countBadge.Visible = false
				end
			else
				local count = tool:GetAttribute("Count") or 1

				slotData.categoryStrip.BackgroundColor3 = COLOR_SEED_STRIP
				slotData.stripLabel.Text = Localization.T("Hotbar_Seed", LANG)
				slotData.itemBox.BackgroundColor3 = COLOR_SEED_BG

				if count > 1 then
					slotData.countBadge.Visible = true
					slotData.countLabel.Text = "x" .. count
				else
					slotData.countBadge.Visible = false
				end
			end

			local equipped = isCurrentlyEquipped(tool)
			slotData.frame.BackgroundColor3 = equipped and COLOR_SLOT_EQUIPPED or COLOR_SLOT_EMPTY
			slotData.equippedArrow.Visible = equipped
			-- ใช้สีน้ำเงิน-ฟ้าตัดกับพื้นหลังโทนน้ำตาล/ครีม ให้เห็นชัดเจนไม่กลืนกัน
			slotData.stroke.Color = equipped and Color3.fromRGB(60, 160, 255) or COLOR_BROWN
			slotData.stroke.Thickness = equipped and 5 or 2
			slotData.glowFrame.Visible = equipped

		else
			slotData.categoryStrip.Visible = false
			slotData.itemBox.Visible = false
			slotData.icon.Text = ""
			setSlotPreview(slotData, nil)
			slotData.countBadge.Visible = false
			slotData.equippedArrow.Visible = false
			slotData.removeButton.Visible = false
			slotData.glowFrame.Visible = false -- แก้บั๊ก: ไม่งั้นกรอบแดง "ถืออยู่" จะค้างโชว์หลังไอเทมถูกใช้จนหมด/ถูกทำลาย
			RarityFrame.Apply(slotData.frame, nil)
			slotData.stroke.Color = COLOR_BROWN
			slotData.stroke.Thickness = 2
			slotData.frame.BackgroundColor3 = COLOR_SLOT_EMPTY
		end

		if slotData.rodHint then slotData.rodHint.Visible = tool == nil end

		-- ช่องที่เพิ่งถูกปฏิเสธ ยังอยู่ในช่วงกระพริบ
		if rejectFlashUntil[i] then
			if os.clock() < rejectFlashUntil[i] then
				slotData.stroke.Color = COLOR_SLOT_BLOCKED
				slotData.stroke.Thickness = 4
				slotData.lockLabel.Visible = true
			else
				rejectFlashUntil[i] = nil
			end
		end

		-- ไฮไลต์ทุกช่องตอนมีไอเทมรอวางอยู่ (เลือกมาจากกระเป๋าเต็ม) ให้รู้ว่าแตะช่องไหนก็วางได้
		-- ช่องที่รับไอเทมชิ้นนั้นไม่ได้ (เช่นหุ่นลงช่อง 1-2) โชว์กรอบแดงกับแม่กุญแจแทน
		if incoming and slotData.tool ~= incoming then
			if HotbarState.CanPlaceInSlot(incoming, i) then
				slotData.stroke.Color = Color3.fromRGB(255, 200, 60)
				slotData.stroke.Thickness = 3
				if not tool then
					slotData.frame.BackgroundColor3 = COLOR_SLOT_PENDING_TARGET
				end
			else
				slotData.stroke.Color = COLOR_SLOT_BLOCKED
				slotData.stroke.Thickness = 3
				slotData.lockLabel.Visible = true
			end
		end
	end
end

-- HotbarState เรียกตัวนี้เมื่อวางของลงช่องไม่ได้ ให้ช่องกระพริบแดงพร้อมแม่กุญแจ 0.8 วินาที
local REJECT_FLASH_TIME = 0.8
function HotbarState.OnAssignRejected(index)
	if not slotButtons[index] then return end
	rejectFlashUntil[index] = os.clock() + REJECT_FLASH_TIME
	refreshHotbar()
	task.delay(REJECT_FLASH_TIME + 0.05, refreshHotbar) -- วาดอีกรอบหลังหมดเวลา ให้กรอบกลับเป็นปกติ
end

local function onSlotClicked(index)
	local slotData = slotButtons[index]

	-- ถ้ามีไอเทมรออยู่ (เลือกมาจากกระเป๋าเต็ม) ให้วางลงช่องนี้แทนการถือ/ปลด
	local pending = HotbarState.GetPending()
	if pending then
		HotbarState.AssignToSlot(pending, index)
		HotbarState.ClearPending()
		refreshHotbar()
		return
	end

	local tool = slotData.tool
	if not tool then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if isCurrentlyEquipped(tool) then
		humanoid:UnequipTools()
	else
		humanoid:UnequipTools()
		humanoid:EquipTool(tool)
	end
end

-- ผูกทั้งคลิกปกติ (ถือ/ปลด, วางไอเทมที่เลือกไว้) และลากค้าง (ลากออกไปกระเป๋าเต็ม = ถอด, ลากไปอีกช่อง = สลับที่)
for i = 1, MAX_SLOTS do
	local slotData = slotButtons[i]

	HotbarState.SetupDraggable(
		slotData.frame,
		function()
			local tool = slotData.tool
			if not tool then return nil end
			return tool, slotData.icon.Text, slotData.itemBox.BackgroundColor3,
			(slotData.countBadge.Visible and slotData.countLabel.Text or nil)
		end,
		function()
			onSlotClicked(i)
		end,
		function()
			return i
		end
	)

	slotData.removeButton.MouseButton1Click:Connect(function()
		if i == HotbarState.ROD_SLOT then return end
		HotbarState.Unassign(i)
		refreshHotbar()
	end)
end

local function getEquippedIndex()
	for i = 1, MAX_SLOTS do
		local tool = slotButtons[i].tool
		if tool and isCurrentlyEquipped(tool) then
			return i
		end
	end
	return 0
end

-- เก็บของที่ถืออยู่ (มือว่าง)
local function putAway()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:UnequipTools() end
end

-- จอย LB/RB ไล่ช่องที่มีของ มีจุด "มือว่าง" คั่นหัวท้าย (เดิมวนถือของตลอด เก็บของด้วยจอยไม่ได้)
-- เช่น ถือช่องสุดท้ายแล้วกด RB = เก็บของ / มือว่างกด RB = ถือช่องแรกที่มีของ
local function cycleSlot(direction)
	local stops = { 0 } -- 0 = มือว่าง
	for i = 1, MAX_SLOTS do
		if slotButtons[i].tool then table.insert(stops, i) end
	end
	if #stops == 1 then return end
	local current = table.find(stops, getEquippedIndex()) or 1
	local nextStop = stops[((current - 1 + direction) % #stops) + 1]
	if nextStop == 0 then
		putAway()
	else
		onSlotClicked(nextStop)
	end
end

-- ============ ปรับขนาดตามจอ ============
-- เกมบังคับแนวนอน (StarterGui.ScreenOrientation = LandscapeSensor)
local camera = workspace.CurrentCamera

local function applyResponsiveLayout()
	local vp = camera.ViewportSize
	if vp.X < 2 or vp.Y < 2 then return end

	local baseW = BASE_PAD*2 + MAX_SLOTS*BASE_SLOT_W + (MAX_SLOTS-1)*BASE_GAP
	local baseH = BASE_PAD*2 + BASE_SLOT_H

	local scale = math.min(vp.X*0.92/baseW, vp.Y*0.15/baseH, 1)
	uiScale.Scale = math.clamp(scale, 0.40, 1)
	HotbarState.SetUiScale(uiScale.Scale)

	-- ชิดขอบล่างของจอ (เดิม -28/-20 ลอยสูงเกินไป) อย่าเปลี่ยน ScreenInsets ของ ScreenGui นี้:
	-- ระบบลากไอเทมใน HotbarState เทียบพิกัดกับ AbsolutePosition โดยสมมติว่า Inset ตรงกับ HotbarDragLayer
	hotbarFrame.Position = UDim2.new(0.5, 0, 1, UserInputService.TouchEnabled and -6 or -10)
end

applyResponsiveLayout()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(applyResponsiveLayout)

refreshHotbar()
task.spawn(function()
	while true do
		task.wait(0.5)
		refreshHotbar()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if UserInputService:GetFocusedTextBox() then return end
	if gameProcessed then return end -- กำลังพิมพ์แชต: พิมพ์ตัวเลขแล้วไม่ไปสลับของในมือ

	local keyMap = {
		[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9,
	}
	local index = keyMap[input.KeyCode]
	if index and index <= MAX_SLOTS then onSlotClicked(index) end
end)

-- ปุ่มจอย (เช็คที่ KeyCode อย่างเดียว คีย์บอร์ดส่ง ButtonR1/DPadDown ไม่ได้อยู่แล้ว และรองรับจอยทุกตัว)
local GuiService = game:GetService("GuiService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- กำลังเลือกปุ่มในหน้าต่างด้วยจอย (เช่น ร้านตกปลาใช้ LB/RB เปลี่ยนแท็บ) = ไม่สลับของในมือ
	if GuiService.SelectedObject ~= nil and (input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.ButtonL1) then return end
	if input.KeyCode == Enum.KeyCode.ButtonR1 then
		cycleSlot(1)
	elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
		cycleSlot(-1)
	elseif input.KeyCode == Enum.KeyCode.DPadDown and not gameProcessed then
		putAway() -- ปุ่มลูกศรลง = เก็บของ (ตอนเมนูเปิด ลูกศรใช้เลือกปุ่ม จะเป็น gameProcessed)
	end
end)

-- ป้ายบอกปุ่มจอยเหนือแถบ (แสดงเฉพาะตอนกำลังใช้จอย) วางไว้นอก hotbarFrame เพราะข้างในมี UIListLayout
local padHint = Instance.new("TextLabel")
padHint.Name = "GamepadHint"
padHint.AnchorPoint = Vector2.new(0.5, 1)
padHint.Size = UDim2.new(0, 0, 0, 22)
padHint.AutomaticSize = Enum.AutomaticSize.X
padHint.BackgroundColor3 = COLOR_CREAM
padHint.BackgroundTransparency = 0.1
padHint.Font = Enum.Font.GothamBold
padHint.TextSize = 13
padHint.TextColor3 = COLOR_TEXT_DARK
padHint.Text = tr(LANG, "LB ◀  สลับไอเทม  ▶ RB    ⬇️ เก็บของ    ⬆️ เมนู", "LB ◀  Switch item  ▶ RB    ⬇️ Put away    ⬆️ Menu")
padHint.Visible = false
padHint.Parent = screenGui
Instance.new("UICorner", padHint).CornerRadius = UDim.new(1, 0)
local padHintStroke = Instance.new("UIStroke")
padHintStroke.Color = COLOR_BROWN
padHintStroke.Thickness = 2
padHintStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
padHintStroke.Parent = padHint
local padHintPad = Instance.new("UIPadding")
padHintPad.PaddingLeft = UDim.new(0, 12)
padHintPad.PaddingRight = UDim.new(0, 12)
padHintPad.Parent = padHint

local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function placePadHint()
	local top = hotbarFrame.AbsolutePosition.Y - screenGui.AbsolutePosition.Y
	local centerX = hotbarFrame.AbsolutePosition.X - screenGui.AbsolutePosition.X + hotbarFrame.AbsoluteSize.X / 2
	padHint.Position = UDim2.fromOffset(centerX, top - 6)
end
local function updatePadHint()
	padHint.Visible = GAMEPAD_INPUTS[UserInputService:GetLastInputType()] == true
	if padHint.Visible then placePadHint() end
end
UserInputService.LastInputTypeChanged:Connect(updatePadHint)
hotbarFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePadHint)
hotbarFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePadHint)
updatePadHint()
-- รายงานให้เซิร์ฟเวอร์รู้ว่าช่อง 1-2 มีเมล็ดอะไร เพื่อให้สัตว์เลี้ยง "ช่วยปลูกผัก" ใช้เมล็ดจากสองช่องนี้เท่านั้น
-- (แถบ 9 ช่องเป็น state ฝั่งผู้เล่น เซิร์ฟเวอร์มองไม่เห็นเอง) ช่องว่างส่งเป็น false
-- ส่งเมื่อเปลี่ยน และย้ำทุก 10 วินาที เผื่อเซิร์ฟเวอร์ยังไม่ทันพร้อมตอนส่งครั้งแรก
-- เซิร์ฟเวอร์ตรวจความถูกต้องเองทุกครั้ง (ต้องเป็น Tool ของเราจริงและเป็นเมล็ด) ผู้เล่นโกงผ่านช่องนี้ไม่ได้
task.spawn(function()
	local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PetSeedSlots")
	local lastA, lastB, lastSent = nil, nil, 0
	while true do
		local a, b = HotbarState.GetSlotTool(1), HotbarState.GetSlotTool(2)
		if a ~= lastA or b ~= lastB or os.clock() - lastSent > 10 then
			remote:FireServer(a or false, b or false)
			lastA, lastB, lastSent = a, b, os.clock()
		end
		task.wait(0.5)
	end
end)
