-- BACKUP of game.StarterPlayer.StarterPlayerScripts.FishingShopGui (Studio Source, byte-exact, len 30485 hash 1964663435)
-- Restore: paste everything below this header into game.StarterPlayer.StarterPlayerScripts.FishingShopGui.Source in Studio.
-- FishingShopGui: หน้าต่างร้านตกปลา (เปิดตอนกด E ที่ workspace.FishingShop)
-- แท็บ "เบ็ดตกปลา" ซื้อเบ็ดด้วยเหรียญ / แท็บ "ทำเหยื่อ" แลกผลผลิตเป็นเหยื่อ ทุกอย่างทำที่เซิร์ฟเวอร์ (FishingShop)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local ItemPreview = require(ReplicatedStorage:WaitForChild("ItemPreview"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local tr, lang = Localization.Tr()
local function cropNameOf(st)
	local n = Localization.T("Crop_" .. tostring(st.CropType), lang)
	return n:sub(1, 5) == "Crop_" and st.Name or n
end
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local request = remoteEvents:WaitForChild("FishingShopRequest")
local openEvent = remoteEvents:WaitForChild("FishingShopOpen")

local COLOR_BG = Color3.fromRGB(245, 251, 255)
local COLOR_TEXT = Color3.fromRGB(45, 60, 85)
local COLOR_SUB = Color3.fromRGB(100, 115, 140)
local COLOR_BLUE = Color3.fromRGB(170, 215, 250)
local COLOR_GREEN = Color3.fromRGB(160, 230, 160)
local COLOR_GOLD = Color3.fromRGB(255, 215, 120)
local COLOR_DISABLED = Color3.fromRGB(210, 215, 222)
local COLOR_STEPPER = Color3.fromRGB(230, 190, 130)
local COLOR_MAX_BUTTON = Color3.fromRGB(200, 150, 90)
local COLOR_DARK = Color3.fromRGB(60, 45, 30)
local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local BAIT_STEP_SIZE = IS_TOUCH and 34 or 28
local BAIT_MAX_WIDTH = IS_TOUCH and 40 or 34
local BAIT_QTY_WIDTH = 46
local BAIT_MAKE_WIDTH = IS_TOUCH and 56 or 50
local BAIT_STEP_GAP = 4
local BAIT_STEPPER_WIDTH = BAIT_MAX_WIDTH + BAIT_STEP_SIZE * 2 + BAIT_QTY_WIDTH + BAIT_MAKE_WIDTH + BAIT_STEP_GAP * 4
local ROD_TINT = {
	Bamboo = Color3.fromRGB(205, 185, 110), Carrot = Color3.fromRGB(255, 150, 60), Kitty = Color3.fromRGB(255, 160, 200),
	Candy = Color3.fromRGB(240, 80, 100), Rainbow = Color3.fromRGB(170, 130, 255),
	NightMoth = Color3.fromRGB(165, 135, 230),
	SunBee = Color3.fromRGB(245, 185, 30),
}
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
	b.BackgroundColor3 = color or COLOR_BLUE
	b.AutoButtonColor = true
	b.Selectable = true -- จอยเลือกได้
	b.TextWrapped = true
	b.Parent = parent
	corner(b, 10)
	return b
end

-- ============ หน้าต่าง ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishingShopGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 8
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local WIDTH, HEIGHT = 620, 430
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COLOR_BG
main.Active = true
-- จอย: เลื่อนเลือกอยู่แค่ในหน้าต่างนี้
main.SelectionGroup = true
main.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
main.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
main.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
main.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
main.Parent = screenGui
corner(main, 16)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(70, 130, 190); mainStroke.Thickness = 2; mainStroke.Parent = main
local uiScale = Instance.new("UIScale"); uiScale.Parent = main
local camera = workspace.CurrentCamera
local function fit()
	local vp = camera.ViewportSize
	if vp.X < 2 then return end
	uiScale.Scale = math.clamp(math.min((vp.X - 24) / WIDTH, (vp.Y - 40) / HEIGHT), 0.5, 1)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = label(main, tr("🎣 ร้านตกปลา", "🎣 Fishing Shop"), 20, COLOR_TEXT, true)
title.Size = UDim2.new(0, 200, 0, 36)
title.Position = UDim2.new(0, 16, 0, 8)
title.TextXAlignment = Enum.TextXAlignment.Left
local coinsLabel = label(main, "", 14, Color3.fromRGB(180, 120, 20), true)
coinsLabel.Size = UDim2.new(0, 180, 0, 36)
coinsLabel.Position = UDim2.new(1, -236, 0, 8)
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
local closeButton = button(main, "X", Color3.fromRGB(255, 190, 190))
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.TextSize = 16
closeButton.Activated:Connect(function() screenGui.Enabled = false end)

-- แท็บ
local tabs = {}
local pages = {}
local function makeTab(id, text, x)
	local b = button(main, text, COLOR_DISABLED)
	b.Name = "Tab_" .. id
	b.Size = UDim2.new(0, 150, 0, 32)
	b.Position = UDim2.new(0, x, 0, 48)
	b.TextSize = 14
	tabs[id] = b
	local page = Instance.new("Frame")
	page.Name = "Page_" .. id
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, -32, 1, -130)
	page.Position = UDim2.new(0, 16, 0, 88)
	page.Visible = false
	page.Parent = main
	pages[id] = page
	return page
end
local rodPage = makeTab("rods", tr("🎣 เบ็ดตกปลา", "🎣 Rods"), 16)
local baitPage = makeTab("bait", tr("🐛 ทำเหยื่อ", "🐛 Make Bait"), 174)
local sellPage = makeTab("sell", tr("💰 ขายปลา", "💰 Sell Fish"), 332)
local currentTab = "rods"
local function showTab(id)
	currentTab = id
	for k, b in pairs(tabs) do
		b.BackgroundColor3 = k == id and COLOR_BLUE or COLOR_DISABLED
		pages[k].Visible = k == id
	end
end
showTab("rods")

local statusLabel = label(main, "", 13, Color3.fromRGB(40, 150, 60), true)
statusLabel.Size = UDim2.new(1, -32, 0, 30)
statusLabel.Position = UDim2.new(0, 16, 1, -38)

-- ============ หน้าเบ็ด ============
local rodList = Instance.new("ScrollingFrame")
rodList.BackgroundTransparency = 1
rodList.Size = UDim2.new(1, 0, 1, 0)
rodList.ScrollBarThickness = 6
rodList.AutomaticCanvasSize = Enum.AutomaticSize.Y
rodList.CanvasSize = UDim2.new()
rodList.BorderSizePixel = 0
rodList.Parent = rodPage
local rodPad = Instance.new("UIPadding"); rodPad.PaddingRight = UDim.new(0, 10); rodPad.PaddingTop = UDim.new(0, 2); rodPad.PaddingLeft = UDim.new(0, 2); rodPad.Parent = rodList
local rodLayout = Instance.new("UIListLayout"); rodLayout.Padding = UDim.new(0, 8); rodLayout.SortOrder = Enum.SortOrder.LayoutOrder; rodLayout.Parent = rodList

local BASE_BITE = (Config.Rods.Bamboo.BiteTime[1] + Config.Rods.Bamboo.BiteTime[2]) / 2
local rodRows = {} -- [rodId] = { button }
local doRequest

for i, entry in ipairs(Config.RodList(true)) do
	local id, rod = entry.Id, entry.Rod
	local tint = ROD_TINT[id] or COLOR_BLUE
	local row = Instance.new("Frame")
	row.Name = "Rod_" .. id
	row.LayoutOrder = i
	row.Size = UDim2.new(1, 0, 0, 92)
	row.BackgroundColor3 = Color3.new(1, 1, 1)
	row.Parent = rodList
	corner(row, 12)
	local stroke = Instance.new("UIStroke"); stroke.Color = tint; stroke.Thickness = 2.5; stroke.Parent = row
	local pic = Instance.new("Frame")
	pic.Size = UDim2.new(0, 120, 0, 80)
	pic.Position = UDim2.new(0, 6, 0.5, -40)
	pic.BackgroundColor3 = tint:Lerp(Color3.new(1, 1, 1), 0.75)
	pic.Parent = row
	corner(pic, 10)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("ItemPreviewModels", 30)
		if folder and folder:WaitForChild("Rod_" .. id, 30) then ItemPreview.Create(pic, "Rod_" .. id) end
	end)
	local name = label(row, rod.Icon .. " " .. Config.RodName(id, lang), 16, COLOR_TEXT, true)
	name.Size = UDim2.new(1, -270, 0, 22)
	name.Position = UDim2.new(0, 134, 0, 6)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local desc = label(row, Config.RodDesc(id, lang) or "", 11, COLOR_SUB)
	desc.Size = UDim2.new(1, -270, 0, 16)
	desc.Position = UDim2.new(0, 134, 0, 28)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	local avg = (rod.BiteTime[1] + rod.BiteTime[2]) / 2
	local faster = math.floor((1 - avg / BASE_BITE) * 100 + 0.5)
	-- 2026-10-18 ตัดบรรทัด 2 (เวลาเกี่ยว / กรอบมินิเกม) ออก เพราะตกปลาเหลือแต่แบบออโต้
	local stats = label(row, string.format(tr("🍀 โชค x%s   📏 ระยะ %d   ⏱️ ปลากินเร็วขึ้น %d%%", "🍀 Luck x%s   📏 Range %d   ⏱️ Bites %d%% faster"),
		tostring(rod.Luck), rod.CastDistance, faster), 11, COLOR_TEXT)
	stats.Size = UDim2.new(1, -270, 0, 36)
	stats.Position = UDim2.new(0, 134, 0, 48)
	stats.TextXAlignment = Enum.TextXAlignment.Left
	stats.TextYAlignment = Enum.TextYAlignment.Top
	local buy = button(row, "", COLOR_GOLD)
	buy.Name = "BuyButton"
	buy.Size = UDim2.new(0, 120, 0, 46)
	buy.Position = UDim2.new(1, -128, 0.5, -23)
	buy.TextSize = 14
	buy.Activated:Connect(function()
		if rodRows[id].owned then return end
		if rod.RobuxPrice then
			if (rod.ProductId or 0) <= 0 then
				statusLabel.Text = tr("เบ็ดนี้ยังไม่ได้ตั้งรหัสสินค้า", "This rod has no product ID configured")
				return
			end
			MarketplaceService:PromptProductPurchase(player, rod.ProductId)
			return
		end
		doRequest("buyRod", id)
	end)
	-- ปุ่ม 🎁 ส่งเบ็ดให้เพื่อน: เฉพาะเบ็ดที่มี GiftProductId กดแล้วปิดร้านแล้วเปิดหน้าเลือกเพื่อนของ VipGui (ชนิด rod_<RodId>) เพิ่ม 2026-10-08
	if rod.RobuxPrice and (tonumber(rod.GiftProductId) or 0) > 0 then
		buy.Size = UDim2.new(0, 120, 0, 40)
		buy.Position = UDim2.new(1, -128, 0, 10)
		local giftButton = button(row, "🎁", Color3.fromRGB(235, 95, 160))
		giftButton.Name = "GiftButton"
		giftButton.Size = UDim2.new(0, 120, 0, 28)
		giftButton.Position = UDim2.new(1, -128, 0, 56)
		giftButton.TextSize = 20
		giftButton.TextColor3 = Color3.new(1, 1, 1)
		giftButton.Activated:Connect(function()
			local vipGui = player.PlayerGui:FindFirstChild("VipGui")
			local openGift = vipGui and vipGui:FindFirstChild("OpenRodGift")
			if not openGift then return end
			screenGui.Enabled = false
			openGift:Fire(id)
		end)
	end
	rodRows[id] = { button = buy, rod = rod, owned = false }
end

-- ============ หน้าเหยื่อ ============
local baitInfo = Instance.new("Frame")
baitInfo.BackgroundColor3 = Color3.fromRGB(255, 244, 232)
baitInfo.Size = UDim2.new(0, 250, 1, 0)
baitInfo.Parent = baitPage
corner(baitInfo, 12)
local baitTitle = label(baitInfo, tr("🐛 เหยื่อทำอะไรได้?", "🐛 What does bait do?"), 14, COLOR_TEXT, true)
baitTitle.Size = UDim2.new(1, -20, 0, 20)
baitTitle.Position = UDim2.new(0, 10, 0, 8)
baitTitle.TextXAlignment = Enum.TextXAlignment.Left
local lines = {}
for star = 1, 5 do
	local b = Config.Bait[star]
	table.insert(lines, string.format(tr("%s  ปลากินเร็วขึ้น %d%% · โชค +%s", "%s  Bites %d%% faster · Luck +%s"), string.rep("⭐", star), math.floor((1 - b.BiteMult) * 100 + 0.5), tostring(b.Luck)))
end
local baitText = label(baitInfo, string.format(tr("ผลผลิต 1 ชิ้น = เหยื่อ %d ชิ้น (ดาวเท่ากัน)\nใช้อัตโนมัติ 1 ชิ้นต่อปลากิน 1 ครั้ง\nเลือกดาวที่จะใช้ได้ที่ปุ่ม 🐛 ตอนถือเบ็ด\n\n%s", "1 crop = %d bait (same stars)\nUsed automatically, 1 bait per bite\nPick which stars to use with the 🐛 button while holding a rod\n\n%s"),
	Config.BAIT_PER_PRODUCE, table.concat(lines, "\n")), 11, COLOR_SUB)
baitText.Size = UDim2.new(1, -20, 0, 150)
baitText.Position = UDim2.new(0, 10, 0, 30)
baitText.TextXAlignment = Enum.TextXAlignment.Left
baitText.TextYAlignment = Enum.TextYAlignment.Top
local haveTitle = label(baitInfo, tr("🎒 เหยื่อที่มี", "🎒 Your bait"), 14, COLOR_TEXT, true)
haveTitle.Size = UDim2.new(1, -20, 0, 20)
haveTitle.Position = UDim2.new(0, 10, 0, 186)
haveTitle.TextXAlignment = Enum.TextXAlignment.Left
local haveText = label(baitInfo, "", 12, COLOR_TEXT)
haveText.Size = UDim2.new(1, -20, 0, 60)
haveText.Position = UDim2.new(0, 10, 0, 208)
haveText.TextXAlignment = Enum.TextXAlignment.Left
haveText.TextYAlignment = Enum.TextYAlignment.Top

local produceTitle = label(baitPage, tr("🧺 ผลผลิตในกระเป๋า", "🧺 Produce in your bag"), 14, COLOR_TEXT, true)
produceTitle.Size = UDim2.new(1, -266, 0, 20)
produceTitle.Position = UDim2.new(0, 262, 0, 0)
produceTitle.TextXAlignment = Enum.TextXAlignment.Left
local produceList = Instance.new("ScrollingFrame")
produceList.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
produceList.Size = UDim2.new(1, -262, 1, -24)
produceList.Position = UDim2.new(0, 262, 0, 24)
produceList.ScrollBarThickness = 6
produceList.AutomaticCanvasSize = Enum.AutomaticSize.Y
produceList.CanvasSize = UDim2.new()
produceList.BorderSizePixel = 0
produceList.Parent = baitPage
corner(produceList, 12)
local plPad = Instance.new("UIPadding"); plPad.PaddingTop = UDim.new(0, 6); plPad.PaddingLeft = UDim.new(0, 6); plPad.PaddingRight = UDim.new(0, 12); plPad.PaddingBottom = UDim.new(0, 6); plPad.Parent = produceList
local plLayout = Instance.new("UIListLayout"); plLayout.Padding = UDim.new(0, 6); plLayout.SortOrder = Enum.SortOrder.LayoutOrder; plLayout.Parent = produceList

-- ============ หน้าขายปลา ============
local RarityFrame = require(ReplicatedStorage:WaitForChild("RarityFrame"))
local sellTop = label(sellPage, "", 13, COLOR_TEXT, true)
sellTop.Size = UDim2.new(1, -150, 0, 34)
sellTop.TextXAlignment = Enum.TextXAlignment.Left
local sellAllButton = button(sellPage, tr("💰 ขายทั้งหมด", "💰 Sell All"), COLOR_GOLD)
sellAllButton.Name = "SellAllButton"
sellAllButton.Size = UDim2.new(0, 140, 0, 34)
sellAllButton.Position = UDim2.new(1, -140, 0, 0)
local fishList = Instance.new("ScrollingFrame")
fishList.BackgroundColor3 = Color3.fromRGB(235, 246, 252)
fishList.Size = UDim2.new(1, 0, 1, -42)
fishList.Position = UDim2.new(0, 0, 0, 42)
fishList.ScrollBarThickness = 6
fishList.AutomaticCanvasSize = Enum.AutomaticSize.Y
fishList.CanvasSize = UDim2.new()
fishList.BorderSizePixel = 0
fishList.Parent = sellPage
corner(fishList, 12)
local flPad = Instance.new("UIPadding"); flPad.PaddingTop = UDim.new(0, 6); flPad.PaddingLeft = UDim.new(0, 6); flPad.PaddingRight = UDim.new(0, 12); flPad.PaddingBottom = UDim.new(0, 6); flPad.Parent = fishList
local flLayout = Instance.new("UIListLayout"); flLayout.Padding = UDim.new(0, 6); flLayout.SortOrder = Enum.SortOrder.LayoutOrder; flLayout.Parent = fishList

-- ============ แสดงผล ============
local info
local working = false

local function setStatus(text, good)
	statusLabel.Text = text or ""
	statusLabel.TextColor3 = good and Color3.fromRGB(40, 150, 60) or Color3.fromRGB(200, 80, 80)
end

local function renderRods()
	local owned = {}
	for _, r in ipairs(info.Rods) do owned[r.Id] = r.Owned end
	for id, row in pairs(rodRows) do
		row.owned = owned[id] == true
		if row.owned then
			row.button.Text = tr("✓ มีแล้ว", "✓ Owned")
			row.button.BackgroundColor3 = COLOR_GREEN
		elseif row.rod.RobuxPrice then
			local icon = row.rod.Icon or "🌙"
			row.button.Text = (row.rod.ProductId or 0) > 0 and (icon .. " " .. row.rod.RobuxPrice .. " R$") or tr(icon .. " รอตั้งสินค้า", icon .. " Product ID needed")
			row.button.BackgroundColor3 = (ROD_TINT[id] or Color3.fromRGB(165, 135, 230)):Lerp(Color3.new(1, 1, 1), 0.55)
		elseif row.rod.Price <= 0 then
			row.button.Text = tr("🎁 รับฟรี", "🎁 Free")
			row.button.BackgroundColor3 = COLOR_GREEN
		else
			row.button.Text = "💰 " .. commas(row.rod.Price)
			row.button.BackgroundColor3 = info.Coins >= row.rod.Price and COLOR_GOLD or COLOR_DISABLED
		end
	end
end

local function renderBait()
	local parts = {}
	for star = 5, 1, -1 do
		local n = info.Bait[star] or 0
		if n > 0 then table.insert(parts, string.rep("⭐", star) .. " x" .. n) end
	end
	haveText.Text = #parts > 0 and table.concat(parts, "\n") or tr("ยังไม่มีเหยื่อ", "No bait yet")
	for _, c in ipairs(produceList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if #info.Stacks == 0 then
		local empty = label(produceList, tr("ยังไม่มีผลผลิตในกระเป๋า\nเก็บเกี่ยวผักแล้วเอามาทำเหยื่อได้เลย", "No produce in your bag yet\nHarvest some crops and turn them into bait"), 12, COLOR_SUB)
		empty.Size = UDim2.new(1, 0, 0, 60)
		return
	end
	for i, st in ipairs(info.Stacks) do
		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, IS_TOUCH and 56 or 50)
		row.BackgroundColor3 = Color3.fromRGB(235, 245, 225)
		row.Parent = produceList
		corner(row, 8)
		local name = label(row, (CROP_ICON[st.CropType] or "🌱") .. " " .. cropNameOf(st) .. " " .. string.rep("⭐", math.clamp(st.Star or 1, 1, 5)), 12, COLOR_TEXT, true)
		name.Size = UDim2.new(1, -(BAIT_STEPPER_WIDTH + 20), 1, 0)
		name.Position = UDim2.new(0, 8, 0, 0)
		name.TextXAlignment = Enum.TextXAlignment.Left

		-- ตัวปรับจำนวนแบบเดียวกับร้านเมล็ด: MAX / - / กรอก / + / ทำ
		local stepper = Instance.new("Frame")
		stepper.Name = "BaitQuantityStepper_" .. st.CropType .. "_" .. st.Star
		stepper.Size = UDim2.new(0, BAIT_STEPPER_WIDTH, 0, BAIT_STEP_SIZE)
		stepper.Position = UDim2.new(1, -(BAIT_STEPPER_WIDTH + 8), 0.5, -BAIT_STEP_SIZE / 2)
		stepper.BackgroundTransparency = 1
		stepper.Parent = row

		local amountBox = Instance.new("TextBox")
		amountBox.Name = "MakeAmount_" .. st.CropType .. "_" .. st.Star
		amountBox.Size = UDim2.new(0, BAIT_QTY_WIDTH, 0, BAIT_STEP_SIZE)
		amountBox.Position = UDim2.new(0, BAIT_MAX_WIDTH + BAIT_STEP_SIZE + BAIT_STEP_GAP * 2, 0, 0)
		amountBox.BackgroundColor3 = Color3.fromRGB(250, 245, 235)
		amountBox.TextColor3 = COLOR_DARK
		amountBox.TextScaled = true
		amountBox.Text = "1"
		amountBox.ClearTextOnFocus = false
		amountBox.Font = Enum.Font.GothamBold
		amountBox.Parent = stepper
		corner(amountBox, 8)
		local amountStroke = Instance.new("UIStroke")
		amountStroke.Color = Color3.fromRGB(140, 100, 65)
		amountStroke.Parent = amountBox

		local maxButton = button(stepper, tr("MAX", "MAX"), COLOR_MAX_BUTTON)
		maxButton.Name = "MakeMax_" .. st.CropType .. "_" .. st.Star
		maxButton.Size = UDim2.new(0, BAIT_MAX_WIDTH, 0, BAIT_STEP_SIZE)
		maxButton.Position = UDim2.new(0, 0, 0, 0)
		maxButton.TextColor3 = Color3.new(1, 1, 1)
		maxButton.TextSize = 11
		local minusButton = button(stepper, "-", COLOR_STEPPER)
		minusButton.Name = "MakeMinus_" .. st.CropType .. "_" .. st.Star
		minusButton.Size = UDim2.new(0, BAIT_STEP_SIZE, 0, BAIT_STEP_SIZE)
		minusButton.Position = UDim2.new(0, BAIT_MAX_WIDTH + BAIT_STEP_GAP, 0, 0)
		minusButton.TextSize = 16
		local plusButton = button(stepper, "+", COLOR_STEPPER)
		plusButton.Name = "MakePlus_" .. st.CropType .. "_" .. st.Star
		plusButton.Size = UDim2.new(0, BAIT_STEP_SIZE, 0, BAIT_STEP_SIZE)
		plusButton.Position = UDim2.new(0, BAIT_MAX_WIDTH + BAIT_STEP_SIZE + BAIT_QTY_WIDTH + BAIT_STEP_GAP * 3, 0, 0)
		plusButton.TextSize = 16
		local make = button(stepper, tr("ทำ", "Make"), COLOR_BLUE)
		make.Name = "MakeAmountButton_" .. st.CropType .. "_" .. st.Star
		make.Size = UDim2.new(0, BAIT_MAKE_WIDTH, 0, BAIT_STEP_SIZE)
		make.Position = UDim2.new(0, BAIT_STEPPER_WIDTH - BAIT_MAKE_WIDTH, 0, 0)
		make.TextSize = 11

		local function clampAmount()
			local amount = math.clamp(math.floor(tonumber(amountBox.Text) or 1), 1, math.max(st.Count, 1))
			amountBox.Text = tostring(amount)
			return amount
		end
		local sanitizing = false
		amountBox:GetPropertyChangedSignal("Text"):Connect(function()
			if sanitizing then return end
			local cleaned = amountBox.Text:gsub("%D", ""):sub(1, #tostring(math.max(st.Count, 1)))
			if cleaned ~= amountBox.Text then
				sanitizing = true
				amountBox.Text = cleaned
				sanitizing = false
			end
		end)
		amountBox.FocusLost:Connect(clampAmount)
		maxButton.Activated:Connect(function() amountBox.Text = tostring(st.Count) end)
		minusButton.Activated:Connect(function() amountBox.Text = tostring(math.max(1, clampAmount() - 1)) end)
		plusButton.Activated:Connect(function() amountBox.Text = tostring(math.min(st.Count, clampAmount() + 1)) end)
		make.Activated:Connect(function()
			local amount = clampAmount()
			doRequest("makeBait", st.CropType, st.Star, amount)
		end)
	end
end

local function renderSell()
	for _, c in ipairs(fishList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local fish = info.Fish or {}
	local total, count = 0, 0
	for _, f in ipairs(fish) do total += f.UnitPrice * f.Count count += f.Count end
	sellTop.Text = count > 0 and string.format(tr("🐟 ปลาในกระเป๋า %d ตัว · รวม 💰 %s", "🐟 %d fish in your bag · total 💰 %s"), count, commas(total)) or tr("ยังไม่มีปลาในกระเป๋า", "No fish in your bag yet")
	sellAllButton.BackgroundColor3 = count > 0 and COLOR_GOLD or COLOR_DISABLED
	for i, f in ipairs(fish) do
		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 54)
		row.BackgroundColor3 = Color3.new(1, 1, 1)
		row.Parent = fishList
		corner(row, 10)
		RarityFrame.Apply(row, f.Rarity, 10)
		local pic = Instance.new("Frame")
		pic.Size = UDim2.new(0, 64, 0, 44)
		pic.Position = UDim2.new(0, 6, 0.5, -22)
		pic.BackgroundColor3 = Color3.fromRGB(215, 238, 248)
		pic.Parent = row
		corner(pic, 8)
		ItemPreview.Create(pic, "Fish_" .. f.FishId)
		local name = label(row, string.format("%s %s x%d", Config.FishName(f.FishId, lang), string.rep("⭐", f.Star), f.Count), 13, COLOR_TEXT, true)
		name.Size = UDim2.new(1, -230, 0, 22)
		name.Position = UDim2.new(0, 78, 0, 6)
		name.TextXAlignment = Enum.TextXAlignment.Left
		local price = label(row, string.format(tr("💰 %s / ตัว · รวม %s", "💰 %s each · total %s"), commas(f.UnitPrice), commas(f.UnitPrice * f.Count)), 11, COLOR_SUB)
		price.Size = UDim2.new(1, -230, 0, 18)
		price.Position = UDim2.new(0, 78, 0, 28)
		price.TextXAlignment = Enum.TextXAlignment.Left
		local sell = button(row, tr("ขาย", "Sell"), COLOR_GOLD)
		sell.Size = UDim2.new(0, 70, 0, 36)
		sell.Position = UDim2.new(1, -78, 0.5, -18)
		sell.Name = "Sell_" .. f.FishId .. "_" .. f.Star
		sell.Activated:Connect(function() doRequest("sellFish", f.FishId, f.Star) end)
	end
end

-- ปุ่มแรกที่กดได้ในหน้าที่เปิดอยู่ (ไว้ให้จอยเลือกตอนเปิดร้าน/เปลี่ยนแท็บ/ปุ่มเดิมหาย)
local function firstButtonIn(page)
	if page == sellPage then return sellAllButton end
	local best, bestY = nil, math.huge
	for _, d in ipairs(page:GetDescendants()) do
		if d:IsA("GuiButton") and d.Visible and d.AbsolutePosition.Y < bestY then
			best, bestY = d, d.AbsolutePosition.Y
		end
	end
	return best or tabs[currentTab]
end

local function render()
	if not info then return end
	coinsLabel.Text = "💰 " .. commas(info.Coins)
	-- ปุ่มในหน้าเหยื่อ/ขายปลาถูกสร้างใหม่ จอยเลือกปุ่มไหนอยู่ให้เลือกปุ่มชื่อเดิมคืน (ขายหมดแล้ว = ปุ่มแรกของหน้า)
	local prev = GuiService.SelectedObject
	local wasInside = prev ~= nil and prev:IsDescendantOf(main)
	local prevName = wasInside and prev.Name
	renderRods()
	renderBait()
	renderSell()
	if wasInside and not prev:IsDescendantOf(main) then
		local page = pages[currentTab]
		local again = page:FindFirstChild(prevName, true)
		GuiService.SelectedObject = (again and again:IsA("GuiButton")) and again or firstButtonIn(page)
	end
end

doRequest = function(action, a, b, c)
	if working then return end
	working = true
	setStatus(tr("กำลังดำเนินการ...", "Working..."), true)
	local ok, res = pcall(function() return request:InvokeServer(action, a, b, c) end)
	working = false
	if not ok or not res then
		setStatus(tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Connection failed, please try again"))
		return
	end
	if res.info then info = res.info render() end
	if action == "info" then setStatus("") else setStatus(res.message, res.ok) end
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	-- ซื้อเบ็ด Robux คันไหนก็ได้ (ผีเสื้อราตรี / ผึ้งตะวันฉาย) รอเซิร์ฟเวอร์ให้เบ็ดแล้วรีเฟรชหน้าร้าน
	local isRodProduct = false
	for _, rodDef in pairs(Config.Rods) do
		if rodDef.RobuxPrice and rodDef.ProductId == productId and productId > 0 then isRodProduct = true end
	end
	if userId ~= player.UserId or not purchased or not isRodProduct then return end
	task.delay(2, function()
		if screenGui.Parent then doRequest("info") end
	end)
end)

tabs.rods.Activated:Connect(function() showTab("rods") end)
tabs.bait.Activated:Connect(function() showTab("bait") end)
tabs.sell.Activated:Connect(function() showTab("sell") end)
sellAllButton.Activated:Connect(function()
	if info and info.Fish and #info.Fish > 0 then doRequest("sellAllFish") end
end)

-- ============ จอย ============
-- เปิดด้วยจอย = เลือกปุ่มแรกของแท็บให้ / LB RB = เปลี่ยนแท็บ / B = ปิดร้าน
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local TAB_ORDER = { "rods", "bait", "sell" }
local function selectionInside()
	local s = GuiService.SelectedObject
	return s ~= nil and s:IsDescendantOf(main)
end
local function selectFirst()
	GuiService.SelectedObject = firstButtonIn(pages[currentTab])
end

openEvent.OnClientEvent:Connect(function()
	screenGui.Enabled = true
	setStatus("")
	doRequest("info")
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] and screenGui.Enabled and not selectionInside() then
		selectFirst()
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if not screenGui.Enabled then return end
	if input.KeyCode == Enum.KeyCode.ButtonB then
		screenGui.Enabled = false
	elseif input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.ButtonL1 then
		local i = table.find(TAB_ORDER, currentTab) or 1
		local step = input.KeyCode == Enum.KeyCode.ButtonR1 and 1 or -1
		showTab(TAB_ORDER[((i - 1 + step) % #TAB_ORDER) + 1])
		if selectionInside() or GAMEPAD_INPUTS[input.UserInputType] then selectFirst() end
	end
end)

-- เลือกแท็บด้วย A = ย้ายการเลือกลงไปในหน้านั้นเลย
for id, b in pairs(tabs) do
	b.Activated:Connect(function()
		if selectionInside() then task.defer(selectFirst) end
	end)
end

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screenGui.Enabled and selectionInside() then GuiService.SelectedObject = nil end
end)

-- กรอบทองตอนเลือก (แบบเดียวกับหน้าต่างอื่น) ติดให้ทุกปุ่ม รวมที่สร้างใหม่ทีหลัง
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = selectBox
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 190, 40); s.Thickness = 3.5; s.Parent = selectBox
end
local function styleSelectable(obj)
	if obj:IsA("GuiButton") then obj.SelectionImageObject = selectBox end
end
for _, d in ipairs(main:GetDescendants()) do styleSelectable(d) end
main.DescendantAdded:Connect(styleSelectable)

-- คำแนะนำปุ่มจอยท้ายชื่อร้าน (แสดงเฉพาะตอนใช้จอย)
local padHint = label(main, tr("LB/RB เปลี่ยนแท็บ · A กด · B ปิด", "LB/RB switch tab · A select · B close"), 11, COLOR_SUB, true)
padHint.Size = UDim2.new(0, 220, 0, 36)
padHint.Position = UDim2.new(0, 170, 0, 8)
padHint.TextXAlignment = Enum.TextXAlignment.Left
local function updatePadHint()
	padHint.Visible = GAMEPAD_INPUTS[UserInputService:GetLastInputType()] == true
end
UserInputService.LastInputTypeChanged:Connect(updatePadHint)
updatePadHint()
