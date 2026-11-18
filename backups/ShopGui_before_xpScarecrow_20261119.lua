-- BACKUP of StarterPlayer.StarterPlayerScripts.ShopGui before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into StarterPlayer.StarterPlayerScripts.ShopGui.Source in Studio
-- bytes=52779 sum=23316906
-- ShopGui: เมนูร้านค้า (แท็บแยก + กรอกจำนวน + ปุ่ม MAX + เช็คเงินไม่พอเป็นสีเทา + รองรับจอย + รองรับหลายภาษา)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local ItemPreview = require(ReplicatedStorage:WaitForChild("ItemPreview")) -- โมเดล 3D แทนไอคอน (เช่นหุ่นข้าวโพด)
local RarityFrame = require(ReplicatedStorage:WaitForChild("RarityFrame")) -- กรอบสีตามระดับ (ปลา)
local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig")) -- ค่าโชคหุ่นฟาง (แสดงในร้าน)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestShopOpen = remoteEvents:WaitForChild("RequestShopOpen")
local buySeed = remoteEvents:WaitForChild("BuySeed")
local sellCrop = remoteEvents:WaitForChild("SellCrop")
local sellAllCrops = remoteEvents:WaitForChild("SellAllCrops") -- ปุ่มขายผลผลิตทั้งหมด

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local LANG = Localization.GetLanguage(player) -- ตรวจภาษาจากการตั้งค่า Roblox ของผู้เล่นอัตโนมัติ (th/en)

-- ไอคอนไม่ขึ้นกับภาษา เก็บแยกจากคำแปลไว้ต่างหาก
local BOOSTER_CROP_TYPE = "QualityBooster" -- ต้องตรงกับ ShopSystem
-- เวลาโตพื้นฐานต้องตรงกับ STAGE_DURATION_BY_CROP ใน ServerScriptService.PlantingSystem (4 สเตจ)
local CROP_GROW_TIME = {
	Strawberry = 17.6, Corn = 35.2, Wheat = 13.2, Onion = 26.4,
	Watermelon = 40, Pineapple = 36, Potato = 22, Cucumber = 30, Eggplant = 34, Pumpkin = 65, WitchBerry = 80, Carrot = 48, Sunflower = 72, Chili = 90,
}
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
	[BOOSTER_CROP_TYPE] = "🍀", -- หุ่นฟางดวงดี (ไอคอนสำรอง ปกติโชว์โมเดล 3D)
}

local function getCropIcon(cropType)
	return CROP_ICON[cropType] or "🌱"
end

local function getCropName(cropType)
	if cropType == BOOSTER_CROP_TYPE then
		return Localization.T("Item_Booster", LANG)
	end
	return Localization.T("Crop_" .. cropType, LANG)
end

-- ชื่อที่ใช้ในแท็บซื้อ: ใส่คำว่า "เมล็ด" นำหน้า (หรือ "Seed" ต่อท้ายสำหรับอังกฤษ) ยกเว้นหุ่นข้าวโพดซึ่งไม่ใช่เมล็ด
local function getBuyItemName(cropType)
	if cropType == BOOSTER_CROP_TYPE then
		return getCropName(cropType)
	end
	return Localization.F("Shop_SeedName", LANG, getCropName(cropType))
end

local BUY_SOUND_ID = "rbxassetid://120891770644830"
local buySound = Instance.new("Sound")
buySound.Name = "BuySound"
buySound.SoundId = BUY_SOUND_ID
buySound.Volume = 0.6
buySound.SoundGroup = SoundService:FindFirstChild("EffectSounds")
buySound.Parent = SoundService

local SELL_SOUND_ID = "rbxassetid://120891770644830"
local sellSound = Instance.new("Sound")
sellSound.Name = "SellSound"
sellSound.SoundId = SELL_SOUND_ID
sellSound.Volume = 0.6
sellSound.SoundGroup = SoundService:FindFirstChild("EffectSounds")
sellSound.Parent = SoundService

local COLOR_CREAM = Color3.fromRGB(255, 250, 230)
local COLOR_BROWN = Color3.fromRGB(140, 100, 65)
local COLOR_GREEN_DARK = Color3.fromRGB(85, 135, 65)
local COLOR_GREEN = Color3.fromRGB(145, 200, 110)
local COLOR_ORANGE = Color3.fromRGB(225, 170, 95)
local COLOR_STEPPER = Color3.fromRGB(230, 190, 130)
local COLOR_MAX_BUTTON = Color3.fromRGB(200, 150, 90)
local COLOR_TEXT_DARK = Color3.fromRGB(60, 45, 30)
local COLOR_TAB_ACTIVE = Color3.fromRGB(255, 250, 240)
local COLOR_TAB_INACTIVE = Color3.fromRGB(220, 205, 175)
local COLOR_DISABLED_BG = Color3.fromRGB(225, 225, 220)
local COLOR_DISABLED_TEXT = Color3.fromRGB(150, 150, 145)
local COLOR_GAMEPAD_FOCUS = Color3.fromRGB(60, 160, 255)

-- มือถือ/แท็บเล็ต (จอสัมผัสไม่มีคีย์บอร์ด): ขยายปุ่มให้ใหญ่พอให้นิ้วกดโดนง่าย
local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ขนาดออกแบบของหน้าต่าง (หน่วยก่อนย่อ) ถ้าจอเล็กกว่านี้จะย่อด้วย UIScale และลดความสูงให้พอดีจอ
local BASE_WIDTH = 440
local BASE_HEIGHT = 480
local MIN_SCALE = 0.7
local MIN_HEIGHT = 220
local SCREEN_MARGIN = 12
local COMPACT_HEIGHT = 380 -- จอเตี้ยกว่านี้ (หน่วยก่อนย่อ) ใช้หัวหน้าต่างแบบบาง ให้เหลือที่แสดงรายการมากขึ้น

-- ขนาดปุ่มในแถวสินค้า
local STEP_BUTTON = IS_TOUCH and 36 or 28
local MAX_BUTTON_WIDTH = IS_TOUCH and 42 or 34
local QTY_WIDTH = 50
local STEP_GAP = 4
local ACTION_HEIGHT = IS_TOUCH and 36 or 30
local STEPPER_WIDTH = MAX_BUTTON_WIDTH + STEP_BUTTON * 2 + QTY_WIDTH + STEP_GAP * 3
local ROW_TOP = 12
local ACTION_Y = ROW_TOP + STEP_BUTTON + 8
local ROW_HEIGHT = ACTION_Y + ACTION_HEIGHT + 14
local TEXT_LEFT = 84
local INFO_TEXT_SIZE = 13 -- ขนาดคำอธิบายตอนข้อความยาวเกินช่อง (แถวสูงขึ้นแทน)
local TEXT_WIDTH_OFFSET = -(TEXT_LEFT + STEPPER_WIDTH + 20)

-- แถวแบบกว้าง (จอกว้างแต่เตี้ย เช่นมือถือแนวนอน): วางตัวปรับจำนวนกับปุ่มซื้อไว้บรรทัดเดียวกัน แถวเตี้ยลง เห็นสินค้าได้หลายรายการพร้อมกัน
local WIDE_MIN_WIDTH = 600
local WIDE_MAX_WIDTH = 760
local WIDE_ACTION_WIDTH = 96
local WIDE_ROW_HEIGHT = STEP_BUTTON + 24
local WIDE_ICON_SIZE = WIDE_ROW_HEIGHT - 16
local WIDE_TEXT_LEFT = 10 + WIDE_ICON_SIZE + 10
local WIDE_TEXT_WIDTH_OFFSET = -(WIDE_TEXT_LEFT + STEPPER_WIDTH + WIDE_ACTION_WIDTH + 36)
local wideRows = false

-- เปิดให้จอยเลือกโฟกัสปุ่มนี้ได้ พร้อมกรอบไฮไลต์ตอนโฟกัส (ใช้กับทุกปุ่มที่ต้องกดได้ด้วยจอย)
local function makeGamepadSelectable(button, baseStrokeColor, baseStrokeThickness)
	button.Selectable = true

	local stroke = button:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Color = baseStrokeColor or Color3.fromRGB(0, 0, 0)
		stroke.Thickness = baseStrokeThickness or 0
		stroke.Parent = button
	end

	local originalColor = stroke.Color
	local originalThickness = stroke.Thickness

	button.SelectionGained:Connect(function()
		stroke.Color = COLOR_GAMEPAD_FOCUS
		stroke.Thickness = 3
	end)
	button.SelectionLost:Connect(function()
		stroke.Color = originalColor
		stroke.Thickness = originalThickness
	end)

	return stroke
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main" -- GuideHint: NewPlayerGuide หาปุ่มในร้านไปไฮไลต์ (2026-11-15) · Attribute ActiveTab / ShopKind ตั้งด้านล่าง
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, BASE_WIDTH, 0, BASE_HEIGHT)
mainFrame.BackgroundColor3 = COLOR_CREAM
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- ตอนร้านเปิด ล็อกให้จอยเลือกได้เฉพาะปุ่มในร้าน ไม่งั้นเลื่อนสติ๊กออกนอกขอบร้านแล้วโฟกัสจะกระโดดไปปุ่มอื่นนอกร้าน
-- ที่จอยเลือกได้ (เช่นปุ่มกระเป๋าหรือเมนูของ Roblox) กรอบสีน้ำเงินจึงหลุดไปอยู่นอกร้าน กด A แล้วไปโดนของอื่น
-- ผูกกับ Visible ตัวเดียว ครอบทุกทางที่ร้านปิด (ปุ่ม X, ปุ่ม B บนจอย, สคริปต์อื่น)
mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if mainFrame.Visible then
		pcall(function() GuiService:AddSelectionParent("ShopGuiSelection", mainFrame) end)
	else
		pcall(function() GuiService:RemoveSelectionGroup("ShopGuiSelection") end)
	end
end)

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLOR_BROWN
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

local mainScale = Instance.new("UIScale")
mainScale.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = COLOR_GREEN_DARK
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 18)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = COLOR_GREEN_DARK
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -56, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = Localization.T("Shop_Title", LANG)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar
require(ReplicatedStorage:WaitForChild("YellowIcon")).Attach(titleLabel, { frac = 0.7, text = 1.1, max = 34 }) -- YellowIcon 2026-11-16: ร้านผลไม้ 🥭 แดง → รูปมะม่วงเหลือง
local titleSizeConstraint = Instance.new("UITextSizeConstraint")
titleSizeConstraint.MaxTextSize = 22
titleSizeConstraint.Parent = titleLabel

local closeButton = Instance.new("TextButton")
local CLOSE_SIZE = IS_TOUCH and 40 or 34
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Size = UDim2.new(0, CLOSE_SIZE, 0, CLOSE_SIZE)
closeButton.Position = UDim2.new(1, -8, 0.5, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(215, 95, 85)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Selectable = true
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(1, 0)
makeGamepadSelectable(closeButton)

local function closeShop()
	mainFrame.Visible = false
	GuiService.SelectedObject = nil
end
closeButton.MouseButton1Click:Connect(closeShop)

local coinsBar = Instance.new("Frame")
coinsBar.Size = UDim2.new(1, 0, 0, 32)
coinsBar.Position = UDim2.new(0, 0, 0, 50)
coinsBar.BackgroundColor3 = Color3.fromRGB(255, 240, 200)
coinsBar.Parent = mainFrame

local coinsBarPadding = Instance.new("UIPadding")
coinsBarPadding.PaddingLeft = UDim.new(0, 16)
coinsBarPadding.Parent = coinsBar

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1, -16, 1, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = Localization.F("Currency_Label", LANG, 0)
coinsLabel.TextColor3 = COLOR_TEXT_DARK
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = coinsBar
local coinsLabelSizeConstraint = Instance.new("UITextSizeConstraint")
coinsLabelSizeConstraint.MaxTextSize = 16
coinsLabelSizeConstraint.Parent = coinsLabel

-- แท็บสลับ ซื้อ/ขาย
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 40)
tabBar.Position = UDim2.new(0, 10, 0, 88)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local buyTabButton = Instance.new("TextButton")
buyTabButton.Name = "BuyTab" -- GuideHint
buyTabButton.Size = UDim2.new(0.5, -4, 1, 0)
buyTabButton.BackgroundColor3 = COLOR_TAB_ACTIVE
buyTabButton.Text = Localization.T("Shop_BuyTab", LANG)
buyTabButton.TextColor3 = COLOR_TEXT_DARK
buyTabButton.TextScaled = true
buyTabButton.Font = Enum.Font.GothamBold
buyTabButton.AutoButtonColor = false
buyTabButton.Parent = tabBar
Instance.new("UICorner", buyTabButton).CornerRadius = UDim.new(0, 10)
makeGamepadSelectable(buyTabButton)
local buyTabSizeConstraint = Instance.new("UITextSizeConstraint")
buyTabSizeConstraint.MaxTextSize = 14
buyTabSizeConstraint.Parent = buyTabButton

local sellTabButton = Instance.new("TextButton")
sellTabButton.Name = "SellTab" -- GuideHint
sellTabButton.Size = UDim2.new(0.5, -4, 1, 0)
sellTabButton.BackgroundColor3 = COLOR_TAB_INACTIVE
sellTabButton.Text = Localization.T("Shop_SellTab", LANG)
sellTabButton.TextColor3 = COLOR_TEXT_DARK
sellTabButton.TextScaled = true
sellTabButton.Font = Enum.Font.GothamBold
sellTabButton.AutoButtonColor = false
sellTabButton.Parent = tabBar
Instance.new("UICorner", sellTabButton).CornerRadius = UDim.new(0, 10)
makeGamepadSelectable(sellTabButton)
local sellTabSizeConstraint = Instance.new("UITextSizeConstraint")
sellTabSizeConstraint.MaxTextSize = 14
sellTabSizeConstraint.Parent = sellTabButton

-- แท็บ "🎀 แต่งแปลง" ลายแปลงปลูก เฉพาะร้านผลไม้ & อุปกรณ์ (shopKind "orchard") 2026-10-28 · เนื้อหาวาดโดย ReplicatedStorage.OrchardSkinTab
local SkinTab = require(ReplicatedStorage:WaitForChild("OrchardSkinTab"))
local skinTabButton = sellTabButton:Clone()
skinTabButton.Name = "SkinTab"
skinTabButton.Text = Localization.Pick(LANG, "🎀 แต่งแปลง", "🎀 Plot Skins")
skinTabButton.Visible = false
skinTabButton.Parent = tabBar
makeGamepadSelectable(skinTabButton) -- 2026-11-16 จอย: โคลนไม่ได้สัญญาณไฮไลต์มาด้วย ต้องผูกใหม่
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
buyTabButton.LayoutOrder, sellTabButton.LayoutOrder, skinTabButton.LayoutOrder = 1, 2, 3
local function setTabCount(n)
	local w = UDim2.new(1 / n, -(8 * (n - 1)) / n, 1, 0)
	buyTabButton.Size, sellTabButton.Size, skinTabButton.Size = w, w, w
	skinTabButton.Visible = n == 3
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "List" -- GuideHint
scrollFrame.Size = UDim2.new(1, 0, 1, -132)
scrollFrame.Position = UDim2.new(0, 0, 0, 132)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = COLOR_BROWN
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 10)
contentPadding.PaddingBottom = UDim.new(0, 14)
contentPadding.PaddingLeft = UDim.new(0, 14)
contentPadding.PaddingRight = UDim.new(0, 14)
contentPadding.Parent = scrollFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = scrollFrame

-- จัดขนาด/ตำแหน่งหน้าต่างให้พอดีจอ (มือถือแนวนอนจอเตี้ย, แนวตั้งจอแคบ) และไม่ทับ hotbar ด้านล่างถ้าที่พอ
local function getHotbarTop()
	local hotbarGui = playerGui:FindFirstChild("CustomHotbar")
	if not (hotbarGui and hotbarGui:IsA("ScreenGui") and hotbarGui.Enabled) then return nil end
	local hotbarFrame = hotbarGui:FindFirstChildWhichIsA("GuiObject")
	if not (hotbarFrame and hotbarFrame.Visible) then return nil end
	return hotbarFrame.AbsolutePosition.Y
end

local function applyHeaderLayout(compact)
	local titleHeight = compact and 40 or 50
	local coinsHeight = compact and 24 or 32
	local tabHeight = compact and 34 or 40
	if IS_TOUCH then tabHeight = math.max(tabHeight, 38) end
	local tabY = titleHeight + coinsHeight + 6
	local listY = tabY + tabHeight + 4

	titleBar.Size = UDim2.new(1, 0, 0, titleHeight)
	titleLabel.Size = UDim2.new(1, -(CLOSE_SIZE + 32), 1, 0)
	coinsBar.Size = UDim2.new(1, 0, 0, coinsHeight)
	coinsBar.Position = UDim2.new(0, 0, 0, titleHeight)
	tabBar.Size = UDim2.new(1, -20, 0, tabHeight)
	tabBar.Position = UDim2.new(0, 10, 0, tabY)
	scrollFrame.Size = UDim2.new(1, 0, 1, -listY)
	scrollFrame.Position = UDim2.new(0, 0, 0, listY)
end

local rerenderActiveTab -- กำหนดทีหลัง (ใช้วาดแถวใหม่ตอนหมุนจอแล้วแบบแถวเปลี่ยน)

local function updateLayout()
	local screen = screenGui.AbsoluteSize
	if screen.X <= 0 or screen.Y <= 0 then return end

	local availWidth = screen.X - SCREEN_MARGIN * 2
	local scale = math.clamp(availWidth / BASE_WIDTH, MIN_SCALE, 1)
	local width = BASE_WIDTH

	local top = SCREEN_MARGIN
	local bottom = screen.Y - SCREEN_MARGIN
	local hotbarTop = getHotbarTop()
	-- หลบ hotbar เฉพาะตอนที่ยังเหลือที่พอ ถ้าจอเตี้ยมาก (มือถือแนวนอน) ยอมให้ร้านทับ hotbar ดีกว่าเห็นสินค้าแค่แถวเดียว
	if hotbarTop and (hotbarTop - 8 - top) / scale >= COMPACT_HEIGHT then
		bottom = math.min(bottom, hotbarTop - 8)
	end

	local availHeight = (bottom - top) / scale
	local height = math.clamp(availHeight, MIN_HEIGHT, BASE_HEIGHT)

	local compact = height < COMPACT_HEIGHT

	local newWideRows = compact and availWidth >= WIDE_MIN_WIDTH
	if newWideRows then
		width = math.min(availWidth, WIDE_MAX_WIDTH)
	end

	mainScale.Scale = scale
	mainFrame.Size = UDim2.new(0, width, 0, height)
	mainFrame.Position = UDim2.new(0.5, 0, 0, top + (bottom - top) / 2)
	applyHeaderLayout(compact)

	if newWideRows ~= wideRows then
		wideRows = newWideRows
		if mainFrame.Visible and rerenderActiveTab then
			rerenderActiveTab()
		end
	end
end

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout()

local latestBuyItems = {}
local latestSellItems = {}
local latestCoinAmount = 0
local activeTab = "buy"

local function clearContent()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if not child:IsA("UIGridStyleLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

-- สร้างแถวสินค้า 1 รายการ พร้อมตัวปรับจำนวน (-/กรอก/+/MAX)
-- config: { icon, name, infoText, maxQty, actionText, actionColor, onConfirm(quantity), disabled, disabledText }
-- คืนค่า: row, actionButton (actionButton จะเป็น nil ถ้าแถวนี้ disabled อยู่)
local function withCommas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	while true do
		local k
		s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then return s end
	end
end

local function createItemRow(config)
	local disabled = config.disabled or false

	local rowHeight = wideRows and WIDE_ROW_HEIGHT or ROW_HEIGHT
	local iconSize = wideRows and WIDE_ICON_SIZE or 64
	local textLeft = wideRows and WIDE_TEXT_LEFT or TEXT_LEFT
	local textWidthOffset = wideRows and WIDE_TEXT_WIDTH_OFFSET or TEXT_WIDTH_OFFSET
	local nameY = wideRows and (rowHeight / 2 - 21) or (rowHeight / 2 - 26)
	local infoY = wideRows and (rowHeight / 2 + 1) or (rowHeight / 2 - 2)
	local infoHeight = wideRows and (rowHeight / 2 - 5) or 32
	-- คำอธิบายยาว (เช่นเมล็ดไม้ยืนต้น/ตะกร้อโยน) ไม่ย่อตัวหนังสือให้พอดีช่อง (เล็กจนอ่านไม่ออก)
	-- ย้ายไปเต็มความกว้างใต้ไอคอน/ปุ่ม ขนาดคงที่ แล้วขยายแถวลงแทน (2026-10-28)
	local longInfo = false
	local nameLeft, nameWidthOffset = textLeft, textWidthOffset
	do
		local w = scrollFrame.AbsoluteSize.X
		w = ((w > 50) and (w / math.max(mainScale.Scale, 0.01)) or (BASE_WIDTH - 40)) - 12
		local font = Enum.Font.GothamMedium
		local need = TextService:GetTextSize(config.infoText or "", INFO_TEXT_SIZE, font, Vector2.new(math.max(w + textWidthOffset, 80), 10000)).Y
		if need > infoHeight then
			longInfo = true
			local full = TextService:GetTextSize(config.infoText, INFO_TEXT_SIZE, font, Vector2.new(w - 24, 10000)).Y
			infoY = rowHeight - 6
			infoHeight = full + 2
			textLeft, textWidthOffset = 12, -24
			rowHeight = infoY + infoHeight + 10
		end
	end
	local baseHeight = wideRows and WIDE_ROW_HEIGHT or ROW_HEIGHT
	local stepperPosition, actionSize, actionPosition
	if wideRows then
		stepperPosition = UDim2.new(1, -(STEPPER_WIDTH + WIDE_ACTION_WIDTH + 18), 0, 12)
		actionSize = UDim2.new(0, WIDE_ACTION_WIDTH, 0, STEP_BUTTON)
		actionPosition = UDim2.new(1, -(WIDE_ACTION_WIDTH + 10), 0, 12)
	else
		stepperPosition = UDim2.new(1, -(STEPPER_WIDTH + 10), 0, ROW_TOP)
		actionSize = UDim2.new(0, STEPPER_WIDTH, 0, ACTION_HEIGHT)
		actionPosition = UDim2.new(1, -(STEPPER_WIDTH + 10), 0, ACTION_Y)
	end

	local row = Instance.new("Frame")
	row.Name = "Row" .. tostring(config.index or 0) -- ใช้หาปุ่มเดิมให้จอยหลังรีเฟรชร้าน
	row.LayoutOrder = config.index or 0
	row.Size = UDim2.new(1, 0, 0, rowHeight)
	row.BackgroundColor3 = disabled and COLOR_DISABLED_BG or Color3.fromRGB(255, 255, 255)
	row.Parent = scrollFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = Color3.fromRGB(230, 220, 195)
	rowStroke.Thickness = 2
	rowStroke.Parent = row
	if config.rarity then RarityFrame.Apply(row, config.rarity, 14) end -- กรอบสีตามระดับ (ปลา)

	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, iconSize, 0, iconSize)
	iconBox.Position = UDim2.new(0, wideRows and 10 or 12, 0, (baseHeight - iconSize) / 2)
	iconBox.BackgroundColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_STEPPER
	iconBox.Parent = row
	Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 10)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = iconBox

	-- ไอคอนการ์ดมะม่วงเหลือง (2026-11-17): 🥭 ของ Roblox เป็นสีแดง → ไอคอนที่เป็นอีโมจิต้นไม้ที่มี IconImage (OrchardConfig) = ใช้รูปแทน (ผลมะม่วงในแท็บขาย)
	do
		local okY, YellowIcon = pcall(require, ReplicatedStorage:WaitForChild("YellowIcon"))
		local image, rest
		if okY and type(config.icon) == "string" then image, rest = YellowIcon.Split(config.icon) end
		if image and rest == "" then
			local img = Instance.new("ImageLabel")
			img.Name = "YellowIcon"
			img.BackgroundTransparency = 1
			img.AnchorPoint = Vector2.new(0.5, 0.5)
			img.Position = UDim2.fromScale(0.5, 0.5)
			img.Size = UDim2.fromScale(0.82, 0.82)
			img.ScaleType = Enum.ScaleType.Fit
			img.Image = image
			img.Parent = iconBox
			iconLabel.Visible = false
		end
	end

	if config.previewModel and ItemPreview.Create(iconBox, config.previewModel) then
		iconLabel.Visible = false
		local y = iconBox:FindFirstChild("YellowIcon")
		if y then y.Visible = false end
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, nameWidthOffset, 0, 20)
	-- ราคาใต้ชื่อ (config.priceText, แถวคำอธิบายยาวเช่นเมล็ดมะม่วง 2026-10-29): ชื่อขยับขึ้น ราคาอยู่บรรทัดถัดไป
	local showPrice = longInfo and config.priceText ~= nil
	nameLabel.Position = UDim2.new(0, nameLeft, 0, showPrice and (baseHeight / 2 - 21) or (longInfo and (baseHeight / 2 - 10) or nameY))
	if showPrice then
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(1, nameWidthOffset, 0, 18)
		priceLabel.Position = UDim2.new(0, nameLeft, 0, baseHeight / 2 + 1)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = config.priceText
		priceLabel.TextColor3 = disabled and COLOR_DISABLED_TEXT or Color3.fromRGB(205, 130, 25)
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Parent = row
		local pc = Instance.new("UITextSizeConstraint")
		pc.MaxTextSize = 15
		pc.Parent = priceLabel
	end
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = config.name
	nameLabel.TextColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_TEXT_DARK
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = row
	local nameSizeConstraint = Instance.new("UITextSizeConstraint")
	nameSizeConstraint.MaxTextSize = 16
	nameSizeConstraint.Parent = nameLabel

	local infoLabel = Instance.new("TextLabel")
	-- ข้อความราคายาว (เช่น "ราคา 8 / ชิ้น (ซื้อได้สูงสุด 1112)") ให้ขึ้นบรรทัดใหม่ได้ ไม่งั้นช่องแคบบนมือถือตัวอักษรจะเล็กจนอ่านไม่ออก
	infoLabel.Size = UDim2.new(1, textWidthOffset, 0, infoHeight)
	infoLabel.Position = UDim2.new(0, textLeft, 0, infoY)
	infoLabel.TextWrapped = true
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = config.infoText
	infoLabel.TextColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_GREEN_DARK
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextScaled = not longInfo
	infoLabel.TextSize = INFO_TEXT_SIZE
	infoLabel.Font = Enum.Font.GothamMedium
	infoLabel.Parent = row
	local infoSizeConstraint = Instance.new("UITextSizeConstraint")
	infoSizeConstraint.MaxTextSize = 13
	infoSizeConstraint.Parent = infoLabel

	-- ตัวปรับจำนวน (MAX/-/กรอก/+)
	local stepperFrame = Instance.new("Frame")
	stepperFrame.Size = UDim2.new(0, STEPPER_WIDTH, 0, STEP_BUTTON)
	stepperFrame.Position = stepperPosition
	stepperFrame.BackgroundTransparency = 1
	stepperFrame.Parent = row

	local maxButton = Instance.new("TextButton")
	maxButton.Name = "MaxButton"
	maxButton.Size = UDim2.new(0, MAX_BUTTON_WIDTH, 0, STEP_BUTTON)
	maxButton.Position = UDim2.new(0, 0, 0, 0)
	maxButton.BackgroundColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_MAX_BUTTON
	maxButton.Text = Localization.T("Shop_Max", LANG)
	maxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	maxButton.TextScaled = true
	maxButton.Font = Enum.Font.GothamBold
	maxButton.AutoButtonColor = false
	maxButton.Selectable = false
	maxButton.Parent = stepperFrame
	Instance.new("UICorner", maxButton).CornerRadius = UDim.new(0, 8)
	local maxButtonSizeConstraint = Instance.new("UITextSizeConstraint")
	maxButtonSizeConstraint.MaxTextSize = 12
	maxButtonSizeConstraint.Parent = maxButton

	local minusButton = Instance.new("TextButton")
	minusButton.Name = "MinusButton"
	minusButton.Size = UDim2.new(0, STEP_BUTTON, 0, STEP_BUTTON)
	minusButton.Position = UDim2.new(0, MAX_BUTTON_WIDTH + STEP_GAP, 0, 0)
	minusButton.BackgroundColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_STEPPER
	minusButton.Text = "-"
	minusButton.TextColor3 = COLOR_TEXT_DARK
	minusButton.TextScaled = true
	minusButton.Font = Enum.Font.GothamBold
	minusButton.AutoButtonColor = false
	minusButton.Selectable = false
	minusButton.Parent = stepperFrame
	Instance.new("UICorner", minusButton).CornerRadius = UDim.new(0, 8)

	local qtyBox = Instance.new("TextBox")
	qtyBox.Size = UDim2.new(0, QTY_WIDTH, 0, STEP_BUTTON)
	qtyBox.Position = UDim2.new(0, MAX_BUTTON_WIDTH + STEP_BUTTON + STEP_GAP * 2, 0, 0)
	qtyBox.BackgroundColor3 = Color3.fromRGB(250, 245, 235)
	qtyBox.Text = disabled and "0" or tostring(config.defaultQty or 1) -- defaultQty = บทสอนตั้งจำนวนไว้ให้ (2026-11-15)
	qtyBox.TextColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_TEXT_DARK
	qtyBox.TextScaled = true
	qtyBox.Font = Enum.Font.GothamBold
	qtyBox.ClearTextOnFocus = false
	qtyBox.TextEditable = not disabled
	qtyBox.Selectable = false -- แก้ไขจำนวนตรงๆ ด้วยจอยไม่สะดวก ใช้ปุ่ม -/+/MAX แทน
	qtyBox.Parent = stepperFrame
	Instance.new("UICorner", qtyBox).CornerRadius = UDim.new(0, 8)
	local qtyStroke = Instance.new("UIStroke")
	qtyStroke.Color = COLOR_BROWN
	qtyStroke.Thickness = 1
	qtyStroke.Parent = qtyBox

	local plusButton = Instance.new("TextButton")
	plusButton.Name = "PlusButton"
	plusButton.Size = UDim2.new(0, STEP_BUTTON, 0, STEP_BUTTON)
	plusButton.Position = UDim2.new(0, STEPPER_WIDTH - STEP_BUTTON, 0, 0)
	plusButton.BackgroundColor3 = disabled and COLOR_DISABLED_TEXT or COLOR_STEPPER
	plusButton.Text = "+"
	plusButton.TextColor3 = COLOR_TEXT_DARK
	plusButton.TextScaled = true
	plusButton.Font = Enum.Font.GothamBold
	plusButton.AutoButtonColor = false
	plusButton.Selectable = false
	plusButton.Parent = stepperFrame
	Instance.new("UICorner", plusButton).CornerRadius = UDim.new(0, 8)

	local maxQty = disabled and 0 or (config.maxQty or 999)
	-- กรอกเอง: ได้ถึงเท่าที่ซื้อ/ขายได้จริง (typeMaxQty) ส่วนปุ่ม MAX ใส่ได้แค่ maxQty (ร้านซื้อ = ไม่เกิน 999)
	local typeMax = disabled and 0 or (config.typeMaxQty or maxQty)

	local function clampQty()
		if disabled then
			qtyBox.Text = "0"
			return 0
		end
		local n = math.floor(tonumber(qtyBox.Text) or 1)
		n = math.clamp(n, 1, math.max(typeMax, 1))
		qtyBox.Text = tostring(n)
		return n
	end

	if not disabled then
		makeGamepadSelectable(maxButton)
		makeGamepadSelectable(minusButton)
		makeGamepadSelectable(plusButton)

		maxButton.MouseButton1Click:Connect(function()
			qtyBox.Text = tostring(math.max(maxQty, 1))
			clampQty()
		end)
		minusButton.MouseButton1Click:Connect(function()
			local n = clampQty()
			qtyBox.Text = tostring(math.max(1, n - 1))
		end)
		plusButton.MouseButton1Click:Connect(function()
			local n = clampQty()
			qtyBox.Text = tostring(math.min(typeMax, n + 1))
		end)
		qtyBox.FocusLost:Connect(clampQty)

		-- ช่องจำนวนรับเฉพาะตัวเลข: ตัดทุกตัวที่ไม่ใช่เลข 0-9 ทิ้งทันทีที่พิมพ์หรือวาง (ตัวอักษร ช่องว่าง สัญลักษณ์ อีโมจิ
		-- เลขไทย) และจำกัดจำนวนหลักไม่เกินหลักของจำนวนสูงสุด (เช่น ซื้อได้สูงสุด 42432 = 5 หลัก) ปล่อยให้ว่างได้ระหว่างพิมพ์
		-- ส่วนการบีบให้อยู่ในช่วง 1..สูงสุด ทำตอนกดยืนยัน/เลิกพิมพ์ (clampQty) เหมือนเดิม
		local maxDigits = #tostring(math.max(typeMax, 1))
		local sanitizing = false
		qtyBox:GetPropertyChangedSignal("Text"):Connect(function()
			if sanitizing then return end
			local cleaned = qtyBox.Text:gsub("%D", ""):sub(1, maxDigits)
			if cleaned ~= qtyBox.Text then
				sanitizing = true
				qtyBox.Text = cleaned
				sanitizing = false
			end
		end)
	end

	local actionButton = Instance.new("TextButton")
	actionButton.Name = "ActionButton"
	actionButton.Size = actionSize
	actionButton.Position = actionPosition
	actionButton.BackgroundColor3 = disabled and COLOR_DISABLED_TEXT or config.actionColor
	actionButton.Text = disabled and (config.disabledText or Localization.T("Shop_NotEnoughMoney", LANG)) or config.actionText
	actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionButton.TextScaled = true
	actionButton.Font = Enum.Font.GothamBold
	actionButton.AutoButtonColor = false
	actionButton.Selectable = false
	actionButton.Parent = row
	Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 8)
	local actionSizeConstraint = Instance.new("UITextSizeConstraint")
	actionSizeConstraint.MaxTextSize = 14
	actionSizeConstraint.Parent = actionButton

	if not disabled then
		makeGamepadSelectable(actionButton)
		actionButton.MouseButton1Click:Connect(function()
			local qty = clampQty()
			config.onConfirm(qty)
		end)
	end

	return row, (not disabled) and actionButton or nil
end

-- โฟกัสปุ่มให้จอยเฉพาะตอนเล่นด้วยจอยจริง บนมือถือ/เมาส์การตั้ง SelectedObject ทำให้ลิสต์เลื่อนหนีจากรายการแรกเอง
local function selectForGamepad(target)
	if UserInputService:GetLastInputType().Name:match("^Gamepad") then
		GuiService.SelectedObject = target
	end
end

local function renderBuyTab()
	clearContent()
	local firstSelectable = nil
	-- 2026-11-15 บทสอน (NewPlayerGuide ขั้นซื้อ) ตั้ง Attribute GuideBuyQty = เมล็ดที่ยังต้องซื้อ → ช่องจำนวนของเมล็ดผักตั้งเท่านั้น (ไม่เกินที่เงินพอ)
	local guideQty = tonumber(player:GetAttribute("GuideBuyQty"))

	for index, item in ipairs(latestBuyItems) do
		local maxAffordable = math.min(math.floor(latestCoinAmount / item.Price), item.MaxQty or math.huge) -- เมล็ดไม้ยืนต้นซื้อได้ทีละ 1
		local canAfford = maxAffordable > 0
		local locked = item.Locked

		local infoText
		if locked then
			infoText = Localization.F("Shop_LevelRequired", LANG, item.RequiredLevel)
		elseif canAfford then
			infoText = Localization.F("Shop_MaxAffordable", LANG, item.Price, maxAffordable)
		else
			infoText = Localization.F("Shop_CantAfford", LANG, item.Price)
		end
		-- หุ่นฟางดวงดี: บอกค่าโชคไว้หน้าราคา (อ่านจาก LuckConfig ปรับค่าที่นั่นแล้วร้านเปลี่ยนตาม)
		if item.CropType == BOOSTER_CROP_TYPE and not locked then
			local tier = LuckConfig.BoosterTiers[LuckConfig.DEFAULT_BOOSTER_TIER]
			local luck = (tier and tier.Luck) or LuckConfig.DEFAULT_BOOSTER_LUCK
			infoText = (LANG == "th" and "🍀 โชค x" or "🍀 Luck x") .. luck .. " · " .. infoText
		elseif CROP_GROW_TIME[item.CropType] then
			local seconds = CROP_GROW_TIME[item.CropType]
			local timeText = (seconds % 1 == 0) and tostring(seconds) or string.format("%.1f", seconds)
			infoText ..= LANG == "th"
				and (" · ⏱ โตพื้นฐาน " .. timeText .. " วินาที")
				or (" · ⏱ Base grow time " .. timeText .. "s")
		end
		-- เมล็ดไม้ยืนต้น (2026-10-26): เซิร์ฟส่ง Name/Icon/Info มาเอง (ซื้อได้ไม่จำกัด จำกัด 5 ต้นตอนปลูก)
		-- 2026-10-29: มี Info = ใช้ Info อย่างเดียว (ราคาอยู่ใต้ชื่อแล้ว ไม่ต่อ "ราคา X / ชิ้น (ซื้อได้สูงสุด N)" ท้าย)
		if item.Info and not locked then
			infoText = item.Info
		end
		-- พืชกิจกรรม (เมล็ดขายเฉพาะช่วงเทศกาล) บอกไว้หน้าข้อความ (2026-10-17)
		if item.Event then
			infoText = (LANG == "th" and "🎃 พืชกิจกรรม · " or "🎃 Event crop · ") .. infoText
		end

		local _, actionButton = createItemRow({
			index = index,
			icon = item.Icon or getCropIcon(item.CropType),
			-- เมล็ดผัก = ซองเมล็ด 3D "SeedPacket_<พืช>" (2026-10-31) หุ่นฟางใช้รูปตามชื่อเดิม
			previewModel = item.PreviewModel or (not item.Icon and (item.CropType == BOOSTER_CROP_TYPE and item.CropType or ("SeedPacket_" .. item.CropType))) or nil, -- PreviewModel = เซิร์ฟระบุรูป 3D เอง (ตะกร้อ/มือตบ 2026-10-29) ไม่มีโมเดล = ไอคอนเดิม
			name = item.Name or getBuyItemName(item.CropType),
			priceText = item.Info and ("💰 " .. withCommas(item.Price)) or nil, -- สินค้าสวน (มี Info) โชว์ราคาใต้ชื่อ
			infoText = infoText,
			maxQty = math.min(maxAffordable, item.MaxQty or 999), -- ปุ่ม MAX ใส่ได้ไม่เกิน 999
			defaultQty = (guideQty and guideQty > 1 and canAfford and item.CropType ~= BOOSTER_CROP_TYPE and not item.Info) and math.min(guideQty, maxAffordable) or nil,
			typeMaxQty = math.min(maxAffordable, item.MaxQty or math.huge), -- กรอกเองได้ถึงเท่าที่เงินพอ (เซิร์ฟเวอร์เช็กเงินอีกรอบ)
			actionText = Localization.T("Shop_Buy", LANG),
			actionColor = COLOR_GREEN,
			disabled = locked or (not canAfford) or item.LimitReached == true,
			disabledText = locked
				and ("🔒 " .. Localization.F("Shop_LevelRequired", LANG, item.RequiredLevel))
				or (item.LimitReached and item.LimitText)
				or Localization.T("Shop_NotEnoughMoney", LANG),
			onConfirm = function(qty)
				buySound:Play()
				buySeed:FireServer(item.CropType, qty)
			end,
		})
		-- GuideHint: เมล็ดผักธรรมดาที่กดซื้อได้ (ไม่ใช่หุ่นฟาง/สินค้าสวน) บทสอนไฮไลต์ปุ่มแรกที่มีป้ายนี้
		if actionButton and item.CropType ~= BOOSTER_CROP_TYPE and not item.Info then actionButton:SetAttribute("GuideBuySeed", index) end
		if actionButton then actionButton:SetAttribute("GuideItem", item.CropType) end -- 2026-11-17 บทสวนมะม่วง: ไฮไลต์ปุ่มซื้อตามชนิด (OrchardSeed_Mango / OrchardHand)
		firstSelectable = firstSelectable or actionButton
	end

	if #latestBuyItems == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = Localization.T("Shop_NoSeedsForSale", LANG)
		emptyLabel.TextColor3 = COLOR_TEXT_DARK
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = scrollFrame
	end

	-- ปุ่มที่จอยควรโฟกัสตอนเปิดแท็บ (ถ้าไม่มีรายการเลย ให้กลับไปโฟกัสแท็บแทน)
	return firstSelectable or buyTabButton
end

-- แถบขายทั้งหมด อยู่บนสุดของแท็บขาย บอกจำนวนชิ้นและยอดเงินรวมที่จะได้
local function createSellAllRow(totalCount, totalValue)
	local row = Instance.new("Frame")
	row.Name = "SellAllRow"
	row.LayoutOrder = -1 -- อยู่เหนือทุกรายการ
	row.Size = UDim2.new(1, 0, 0, IS_TOUCH and 56 or 50)
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.Parent = scrollFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = COLOR_ORANGE
	rowStroke.Thickness = 2
	rowStroke.Parent = row

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -(STEPPER_WIDTH + 24), 1, 0)
	infoLabel.Position = UDim2.new(0, 12, 0, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = Localization.F("Shop_SellAllInfo", LANG, totalCount, totalValue)
	infoLabel.TextColor3 = COLOR_TEXT_DARK
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 14
	infoLabel.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "SellAllButton"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.new(0, STEPPER_WIDTH, 0, ACTION_HEIGHT)
	button.BackgroundColor3 = COLOR_ORANGE
	button.Text = Localization.T("Shop_SellAll", LANG)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Selectable = false
	button.Parent = row
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MaxTextSize = 14
	sizeConstraint.Parent = button
	makeGamepadSelectable(button)

	button.MouseButton1Click:Connect(function()
		sellSound:Play()
		sellAllCrops:FireServer()
	end)

	return button
end

local function renderSellTab()
	clearContent()
	local firstSelectable = nil

	-- มีของขายอย่างน้อย 2 รายการถึงจะมีปุ่มขายทั้งหมด (รายการเดียวกดขายทีละรายก็จบอยู่แล้ว)
	-- เมล็ด (item.Seed, 2026-10-18) ไม่นับ เพราะขายทั้งหมดไม่ขายเมล็ด ต้องกดขายเอง
	local totalCount, totalValue, totalRows = 0, 0, 0
	for _, item in ipairs(latestSellItems) do
		if not item.Seed then
			totalRows += 1
			totalCount += item.Count
			totalValue += item.TotalValue or (item.UnitPrice * item.Count)
		end
	end
	if totalRows >= 2 then
		firstSelectable = createSellAllRow(totalCount, totalValue)
	end

	for index, item in ipairs(latestSellItems) do
		local _, actionButton = createItemRow({
			index = index,
			icon = item.Seed and getCropIcon(item.SeedCrop) or item.Icon or getCropIcon(item.CropType), -- ปลาส่งไอคอน/ชื่อ/รูปมาจากเซิร์ฟเวอร์
			previewModel = item.Seed and (item.SeedCrop == BOOSTER_CROP_TYPE and item.SeedCrop or ("SeedPacket_" .. item.SeedCrop)) or item.PreviewModel, -- เมล็ดใช้รูปเดียวกับแท็บซื้อ (ซองเมล็ด 2026-10-31)
			rarity = item.Rarity,
			name = item.Seed and getBuyItemName(item.SeedCrop) or ((item.Name or getCropName(item.CropType)) .. " " .. string.rep("⭐", item.Star)),
			infoText = Localization.F("Shop_HaveCount", LANG, item.Count, item.UnitPrice)
				.. (item.Seed and (LANG == "th" and " · ครึ่งราคาซื้อ" or " · half the buy price") or ""),
			maxQty = item.Count,
			actionText = Localization.T("Shop_Sell", LANG),
			actionColor = COLOR_ORANGE,
			onConfirm = function(qty)
				sellSound:Play()
				sellCrop:FireServer(item.CropType, item.Star, qty)
			end,
		})
		-- GuideHint: ปุ่มขายผลผลิต (ไม่ใช่เมล็ด) ใช้ตอนไม่มีปุ่มขายทั้งหมด
		if actionButton and not item.Seed then actionButton:SetAttribute("GuideSellCrop", index) end
		if actionButton then actionButton:SetAttribute("GuideItem", item.CropType) end -- 2026-11-18 บทสวนมะม่วง ขั้นขาย: ไฮไลต์ปุ่มขาย Orchard_Mango
		firstSelectable = firstSelectable or actionButton
	end

	if #latestSellItems == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = Localization.T("Shop_NoProduceToSell", LANG)
		emptyLabel.TextColor3 = COLOR_TEXT_DARK
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = scrollFrame
	end

	return firstSelectable or sellTabButton
end

-- keepPosition = true ตอนเซิร์ฟเวอร์ส่งข้อมูลร้านมาใหม่หลังซื้อ/ขาย (ร้านเปิดอยู่แล้ว): คงตำแหน่งเลื่อนและปุ่มที่จอยเลือกไว้
-- ไม่งั้นลิสต์จะดีดกลับไปบนสุดทุกครั้งที่ซื้อของที่อยู่ด้านล่าง
local function setActiveTab(tab, keepPosition)
	activeTab = tab
	mainFrame:SetAttribute("ActiveTab", tab) -- GuideHint

	local savedCanvas = scrollFrame.CanvasPosition
	local savedRowName, savedButtonName
	local selected = GuiService.SelectedObject
	if keepPosition and selected and selected:IsDescendantOf(scrollFrame) then
		local selectedRow = selected:FindFirstAncestorWhichIsA("Frame")
		while selectedRow and selectedRow.Parent ~= scrollFrame do
			selectedRow = selectedRow.Parent
		end
		savedRowName = selectedRow and selectedRow.Name
		savedButtonName = selected.Name
	end

	local defaultSelection
	skinTabButton.BackgroundColor3 = tab == "skin" and COLOR_TAB_ACTIVE or COLOR_TAB_INACTIVE
	if tab == "skin" then
		buyTabButton.BackgroundColor3 = COLOR_TAB_INACTIVE
		sellTabButton.BackgroundColor3 = COLOR_TAB_INACTIVE
		clearContent()
		defaultSelection = SkinTab.Render(scrollFrame)
	elseif tab == "buy" then
		buyTabButton.BackgroundColor3 = COLOR_TAB_ACTIVE
		sellTabButton.BackgroundColor3 = COLOR_TAB_INACTIVE
		defaultSelection = renderBuyTab()
	else
		buyTabButton.BackgroundColor3 = COLOR_TAB_INACTIVE
		sellTabButton.BackgroundColor3 = COLOR_TAB_ACTIVE
		defaultSelection = renderSellTab()
	end

	if not keepPosition then
		scrollFrame.CanvasPosition = Vector2.new(0, 0)
		selectForGamepad(defaultSelection)
		return
	end

	-- ขนาด canvas (AutomaticCanvasSize) อาจยังไม่อัปเดตจนกว่าจะจัด layout เสร็จ ตั้งซ้ำอีกรอบในเฟรมถัดไปกันตำแหน่งถูกบีบ
	scrollFrame.CanvasPosition = savedCanvas
	task.defer(function()
		scrollFrame.CanvasPosition = savedCanvas
	end)

	if savedRowName then
		local row = scrollFrame:FindFirstChild(savedRowName)
		local button = row and row:FindFirstChild(savedButtonName, true)
		if not (button and button.Selectable) then
			-- ปุ่มเดิมกดไม่ได้แล้ว (เช่นเงินไม่พอ/ขายหมด) ให้ไปปุ่มแรกของแท็บแทน
			button = defaultSelection
		end
		GuiService.SelectedObject = button
	end
end

rerenderActiveTab = function() setActiveTab(activeTab) end

buyTabButton.MouseButton1Click:Connect(function() setActiveTab("buy") end)
sellTabButton.MouseButton1Click:Connect(function() setActiveTab("sell") end)
skinTabButton.MouseButton1Click:Connect(function() setActiveTab("skin") end)

-- ปิดร้านด้วยปุ่ม B บนจอยได้ (คุ้นเคยกว่า เพราะเมนูอื่นในเกมก็ใช้ B ปิดเหมือนกัน)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not mainFrame.Visible then return end
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonB then
		-- 2026-11-16: ป๊อปอัปยืนยันซื้อลายแปลง (OrchardSkinTab) เปิดอยู่ = B ปิดแค่ป๊อปอัป
		if SkinTab.ClosePopup and SkinTab.ClosePopup() then return end
		closeShop()
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and (input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.ButtonR1) then
		-- 2026-11-16 ผู้ใช้สั่ง: L1/R1 สลับแท็บ (ซื้อ / ขาย / แต่งแปลง ถ้ามี) วนรอบ · ป๊อปอัปเปิดอยู่ = ไม่สลับ
		if SkinTab.HasPopup and SkinTab.HasPopup() then return end
		local tabs = { "buy", "sell" }
		if skinTabButton.Visible then table.insert(tabs, "skin") end
		local idx = table.find(tabs, activeTab) or 1
		local step = input.KeyCode == Enum.KeyCode.ButtonR1 and 1 or -1
		setActiveTab(tabs[(idx - 1 + step) % #tabs + 1])
	end
end)

-- shopKind (ค่าที่ 4): "seed" = ร้านเมล็ดพันธุ์ · "orchard" = ร้านผลไม้ & อุปกรณ์ที่ทางเข้าสวน (2026-10-27) เปลี่ยนแค่ชื่อร้าน รายการเซิร์ฟเลือกมาให้แล้ว
requestShopOpen.OnClientEvent:Connect(function(buyItems, sellItems, coinAmount, shopKind)
	mainFrame:SetAttribute("ShopKind", shopKind or "seed") -- GuideHint
	titleLabel.Text = Localization.T(shopKind == "orchard" and "OrchardShop_Title" or "Shop_Title", LANG)
	coinsLabel.Text = Localization.F("Currency_Label", LANG, coinAmount)
	latestBuyItems = buyItems
	latestSellItems = sellItems
	latestCoinAmount = coinAmount

	-- ร้านเปิดอยู่แล้ว = เซิร์ฟเวอร์ส่งข้อมูลใหม่หลังซื้อ/ขาย ไม่ใช่การเปิดร้านใหม่
	local isRefresh = mainFrame.Visible
	setTabCount(shopKind == "orchard" and 3 or 2)
	if activeTab == "skin" and shopKind ~= "orchard" then activeTab = "buy" end
	-- แท็บแต่งแปลงไม่ใช้ข้อมูลร้าน เซิร์ฟส่งข้อมูลร้านใหม่มา (เช่นเหรียญเปลี่ยน) ไม่ต้องวาดการ์ดใหม่
	if isRefresh and activeTab == "skin" then
		mainFrame.Visible = true
		return
	end
	if not isRefresh then
		updateLayout() -- hotbar อาจย้าย/เปลี่ยนขนาดหลังจากร้านสร้างเสร็จ คำนวณใหม่ทุกครั้งที่เปิด
	end
	setActiveTab(activeTab, isRefresh)
	mainFrame.Visible = true
end)

-- 2026-11-15 บทสอนเปลี่ยนจำนวนที่ยังต้องซื้อ (หลังซื้อไปบางส่วน) = วาดแท็บซื้อใหม่ ช่องจำนวนจะได้ตรงกับที่เหลือ
player:GetAttributeChangedSignal("GuideBuyQty"):Connect(function()
	if mainFrame.Visible and activeTab == "buy" then setActiveTab("buy", true) end
end)