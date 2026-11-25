-- BACKUP of StarterPlayer.StarterPlayerScripts.SultanShopGui before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.SultanShopGui.Source in Studio
-- SultanShopGui: หน้าต่างขายแพ็กสุลต่าน (Game Pass ดู ReplicatedStorage.SultanConfig) มังกรหมุนโชว์ + ของในแพ็กครบ + ปุ่มซื้อ (ราคาจริงจาก Dashboard)
-- เปิดจากที่อื่น: PlayerGui.SultanShopGui.OpenSultanShop:Fire() (การ์ดใน QuickShop / หน้าต่าง VIP)
-- จอย: เปิดแล้วเลือกปุ่มซื้อให้ · A กด · B ปิด

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("SultanConfig"))
local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))
local VipConfig = require(ReplicatedStorage:WaitForChild("VipConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local player = Players.LocalPlayer
local lang = Localization.GetLanguage(player)

local COLOR_BG = Color3.fromRGB(44, 16, 64)
local COLOR_PANEL = Color3.fromRGB(62, 26, 88)
local COLOR_GOLD = Color3.fromRGB(255, 205, 80)
local COLOR_TEXT = Color3.fromRGB(255, 244, 225)
local COLOR_SUB = Color3.fromRGB(215, 190, 235)

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 12); c.Parent = obj; return c end
local function stroke(obj, color, t) local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = t or 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = obj; return s end
local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end
local function commas(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- ============ หน้าต่าง ============
local gui = Instance.new("ScreenGui")
gui.Name = "SultanShopGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local openEvent = Instance.new("BindableEvent")
openEvent.Name = "OpenSultanShop"
openEvent.Parent = gui

local WIDTH, HEIGHT = 580, 370
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
local mainStroke = stroke(main, COLOR_GOLD, 3)
local mainStrokeGrad = Instance.new("UIGradient")
mainStrokeGrad.Color = VipConfig.SULTAN_BADGE
mainStrokeGrad.Parent = mainStroke
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

-- หัวข้อ
local title = label(main, Config.TITLE and Localization.F("Sultan_TitleWith", lang, Config.TITLE) or Localization.T("Sultan_Title", lang), 22, Color3.new(1, 1, 1), true)
title.Font = Enum.Font.GothamBlack
title.Size = UDim2.new(1, -70, 0, 36)
title.Position = UDim2.new(0, 18, 0, 10)
title.TextWrapped = false
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = VipConfig.SULTAN_BADGE
titleGrad.Parent = title

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.BackgroundColor3 = Color3.fromRGB(215, 95, 110)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Text = "X"
closeButton.Parent = main
corner(closeButton, 17)

-- ซ้าย: มังกรหมุน + ปุ่มซื้อ
local left = Instance.new("Frame")
left.BackgroundColor3 = COLOR_PANEL
left.Position = UDim2.new(0, 16, 0, 56)
left.Size = UDim2.new(0, 220, 1, -72)
left.Parent = main
corner(left, 14)

local viewport = Instance.new("ViewportFrame")
viewport.Name = "DragonView"
viewport.Position = UDim2.new(0, 10, 0, 10)
viewport.Size = UDim2.new(1, -20, 0, 170)
viewport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
viewport.Ambient = Color3.fromRGB(190, 170, 170)
viewport.LightColor = Color3.new(1, 1, 1)
viewport.LightDirection = Vector3.new(-1, -1, -1)
viewport.Parent = left
corner(viewport, 12)
local viewGrad = Instance.new("UIGradient")
viewGrad.Rotation = 90
viewGrad.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(190, 110, 230))
viewGrad.Parent = viewport
local petName = label(left, Localization.T("Sultan_PetName", lang), 15, COLOR_GOLD, true)
petName.Position = UDim2.new(0, 10, 0, 184)
petName.Size = UDim2.new(1, -20, 0, 20)
petName.TextXAlignment = Enum.TextXAlignment.Center

local buyButton = Instance.new("TextButton")
buyButton.Name = "Buy"
buyButton.AnchorPoint = Vector2.new(0, 1)
buyButton.Position = UDim2.new(0, 10, 1, -28)
buyButton.Size = UDim2.new(1, -76, 0, 50) -- เหลือที่ด้านขวาให้ปุ่ม 🎁
buyButton.BackgroundColor3 = COLOR_GOLD
buyButton.Font = Enum.Font.GothamBlack
buyButton.TextSize = 19
buyButton.TextColor3 = Color3.fromRGB(70, 30, 20)
buyButton.Text = Localization.F("Sultan_Buy", lang, tostring(Config.PRICE_HINT))
buyButton.Parent = left
corner(buyButton, 14)
stroke(buyButton, Color3.fromRGB(150, 80, 20), 2)
local buyNote = label(left, Localization.T("Sultan_BuyNote", lang), 12, COLOR_SUB, false)
buyNote.AnchorPoint = Vector2.new(0.5, 1)
buyNote.Position = UDim2.new(0.5, 0, 1, -8)
buyNote.Size = UDim2.new(1, -20, 0, 16)
buyNote.TextXAlignment = Enum.TextXAlignment.Center

-- ขวา: ของในแพ็ก
local right = Instance.new("ScrollingFrame")
right.Name = "Perks"
right.BackgroundColor3 = COLOR_PANEL
right.Position = UDim2.new(0, 248, 0, 56)
right.Size = UDim2.new(1, -264, 1, -72)
right.BorderSizePixel = 0
right.ScrollBarThickness = 6
right.ScrollBarImageColor3 = COLOR_GOLD
right.AutomaticCanvasSize = Enum.AutomaticSize.Y
right.CanvasSize = UDim2.new()
right.Selectable = false
right.Parent = main
corner(right, 14)
local rightPad = Instance.new("UIPadding")
rightPad.PaddingTop = UDim.new(0, 8)
rightPad.PaddingBottom = UDim.new(0, 8)
rightPad.PaddingLeft = UDim.new(0, 8)
rightPad.PaddingRight = UDim.new(0, 12)
rightPad.Parent = right
local rightList = Instance.new("UIListLayout")
rightList.Padding = UDim.new(0, 6)
rightList.SortOrder = Enum.SortOrder.LayoutOrder
rightList.Parent = right

local b = Config.BUNDLE
local x100Luck = LuckConfig.BoosterTiers.x100.Luck
local CoinTradeConfig = require(ReplicatedStorage:WaitForChild("CoinTradeConfig")) -- สิทธิ์เทรดเงินของสุลต่าน (2026-10-13)
local PERKS = {
	{ "🔥", Localization.T("Sultan_Perk1_Title", lang), Localization.T("Sultan_Perk1_Desc", lang) },
	{ "🎁", Localization.T("Sultan_Perk2_Title", lang), Localization.F("Sultan_Perk2_Desc", lang, b.PremiumTickets, commas(b.Coins), x100Luck, b.X100Scarecrows) },
	{ "💎", Localization.T("Sultan_Perk3_Title", lang), Localization.F("Sultan_Perk3_Desc", lang, Config.DAILY_PREMIUM_TICKETS) },
	{ "💰", Localization.F("Sultan_Perk4_Title", lang, math.floor(Config.SELL_BONUS * 100 + 0.5)), Localization.T("Sultan_Perk4_Desc", lang) },
	{ "🍀", Localization.F("Sultan_Perk5_Title", lang, Config.LUCK_MULT), Localization.T("Sultan_Perk5_Desc", lang) },
	{ "🌟", Localization.F("Sultan_Perk6_Title", lang, Config.MIN_PLANT_QUALITY), Localization.F("Sultan_Perk6_Desc", lang, Config.MIN_PLANT_QUALITY) },
	{ "⚡", Localization.F("Sultan_Perk7_Title", lang, math.floor((1 - Config.MACHINE_TIME_MULT) * 100 + 0.5)), Localization.T("Sultan_Perk7_Desc", lang) },
	{ "✨", Localization.T("Sultan_Perk8_Title", lang), Localization.T("Sultan_Perk8_Desc", lang) },
	{ "🤝", Localization.F("Sultan_Perk10_Title", lang, CoinTradeConfig.SULTAN_LEVEL, commas(CoinTradeConfig.SULTAN_DAILY_LIMIT), CoinTradeConfig.SULTAN2_LEVEL, commas(CoinTradeConfig.SULTAN2_DAILY_LIMIT)),
		Localization.F("Sultan_Perk10_Desc", lang, commas(CoinTradeConfig.DAILY_LIMIT), CoinTradeConfig.TAX_PERCENT) },
	{ "✅", Localization.T("Sultan_Perk9_Title", lang), Localization.T("Sultan_Perk9_Desc", lang) },
}
for i, perk in ipairs(PERKS) do
	local row = Instance.new("Frame")
	row.LayoutOrder = i
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundColor3 = i == 1 and Color3.fromRGB(96, 36, 70) or Color3.fromRGB(78, 36, 108)
	row.Parent = right
	corner(row, 10)
	if i == 1 then stroke(row, COLOR_GOLD, 1.5) end
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 44)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = row
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	local icon = label(row, perk[1], 22, Color3.new(1, 1, 1), true)
	icon.Size = UDim2.new(0, 34, 0, 34)
	icon.Position = UDim2.new(0, -40, 0, 0)
	icon.TextXAlignment = Enum.TextXAlignment.Center
	-- ไอคอนไม่เข้าแถว (วางลอยซ้าย) ย้ายออกจาก UIListLayout ด้วย Frame ครอบ
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(0, 0, 0, 0)
	holder.LayoutOrder = 0
	holder.Parent = row
	icon.Parent = holder
	icon.Position = UDim2.new(0, -40, 0, -2)
	local head = label(row, perk[2], 15, COLOR_GOLD, true)
	head.LayoutOrder = 1
	head.Size = UDim2.new(1, 0, 0, 0)
	head.AutomaticSize = Enum.AutomaticSize.Y
	local sub = label(row, perk[3], 12, COLOR_SUB, false)
	sub.LayoutOrder = 2
	sub.Size = UDim2.new(1, 0, 0, 0)
	sub.AutomaticSize = Enum.AutomaticSize.Y
end

-- ============ มังกรหมุนโชว์ ============
local spinModel, spinCenter, spinOffset
task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("PetPreviewModels", 30)
	local template = folder and folder:WaitForChild("SultanDragon", 30)
	if not template then
		local t = label(viewport, "🐉", 60, Color3.new(1, 1, 1), true)
		t.Size = UDim2.new(1, 0, 1, 0)
		t.TextXAlignment = Enum.TextXAlignment.Center
		return
	end
	local model = template:Clone()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true end
		if d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Highlight") then d:Destroy() end
	end
	model.Parent = viewport
	local cf, size = model:GetBoundingBox()
	local radius = size.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local front = -model:GetPivot().LookVector -- หน้าโมเดลอยู่ฝั่งตรงข้าม LookVector (แบบเดียวกับสัตว์ตัวอื่น)
	cam.CFrame = CFrame.lookAt(cf.Position + front * (radius / math.sin(math.rad(15)) * 0.85) + Vector3.new(0, radius * 0.2, 0), cf.Position)
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	spinModel = model
	spinCenter = CFrame.new(cf.Position)
	spinOffset = spinCenter:ToObjectSpace(model:GetPivot())
end)
local spinAngle = 0
RunService.RenderStepped:Connect(function(dt)
	if not gui.Enabled or not spinModel then return end
	spinAngle += dt * math.rad(35)
	local yaw = math.sin(spinAngle) * math.rad(55)
	local bob = math.sin(spinAngle * 3.2) * 0.12
	spinModel:PivotTo(spinCenter * CFrame.new(0, bob, 0) * CFrame.Angles(0, yaw, 0) * spinOffset)
	mainStrokeGrad.Rotation = (mainStrokeGrad.Rotation + dt * 60) % 360
	titleGrad.Offset = Vector2.new(math.sin(os.clock() * 1.8) * 0.5, 0)
end)

-- ============ สถานะ + ซื้อ ============
local priceText = tostring(Config.PRICE_HINT)
local function render()
	local owned = player:GetAttribute("IsSultan") == true
	buyButton.Text = owned and Localization.T("Sultan_Owned", lang) or Localization.F("Sultan_Buy", lang, priceText)
	buyButton.TextSize = owned and 16 or 19
	buyButton.BackgroundColor3 = owned and Color3.fromRGB(130, 200, 130) or COLOR_GOLD
	buyNote.Text = owned and Localization.T("Sultan_BuyNoteOwned", lang) or Localization.T("Sultan_BuyNote", lang)
end
player:GetAttributeChangedSignal("IsSultan"):Connect(render)
render()
task.spawn(function()
	if Config.GAMEPASS_ID == 0 then return end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(Config.GAMEPASS_ID, Enum.InfoType.GamePass)
	end)
	if ok and info and info.PriceInRobux then
		priceText = tostring(info.PriceInRobux)
		render()
	end
end)

buyButton.Activated:Connect(function()
	if player:GetAttribute("IsSultan") == true or Config.GAMEPASS_ID == 0 then return end
	MarketplaceService:PromptGamePassPurchase(player, Config.GAMEPASS_ID)
end)

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
openEvent.Event:Connect(function()
	gui.Enabled = true
	render()
	right.CanvasPosition = Vector2.zero
	if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then GuiService.SelectedObject = buyButton end
end)
closeButton.Activated:Connect(close)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonB and gui.Enabled then close() end
end)
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not gui.Enabled and selectionInside() then GuiService.SelectedObject = nil end
end)

-- ปุ่ม 🎁 ส่งแพ็กสุลต่านให้เพื่อน (เปิดหน้าเลือกเพื่อนใน VipGui ชนิด "sultan") ใครก็ส่งได้ แม้เป็นสุลต่านอยู่แล้ว
local giftButton = Instance.new("TextButton")
giftButton.Name = "GiftSultan"
giftButton.AnchorPoint = Vector2.new(1, 1)
giftButton.Position = UDim2.new(1, -10, 1, -28)
giftButton.Size = UDim2.new(0, 50, 0, 50)
giftButton.BackgroundColor3 = Color3.fromRGB(235, 95, 160)
giftButton.Font = Enum.Font.GothamBold
giftButton.TextSize = 26
giftButton.TextColor3 = Color3.new(1, 1, 1)
giftButton.Text = "🎁"
giftButton.Visible = (Config.GIFT_PRODUCT_ID or 0) ~= 0 or RunService:IsStudio()
giftButton.Parent = left
corner(giftButton, 14)
stroke(giftButton, Color3.fromRGB(150, 40, 100), 2)
giftButton.Activated:Connect(function()
	local g = player.PlayerGui:FindFirstChild("VipGui")
	local open = g and g:FindFirstChild("OpenSultanGift")
	if open then
		open:Fire() -- ไม่ปิดหน้าต่างแพ็กสุลต่าน: หน้าต่างของขวัญเปิดซ้อนบน
	end
end)

-- กรอบทองตอนเลือก (เหมือนหน้าต่างอื่น)
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
corner(selectBox, 12)
stroke(selectBox, Color3.fromRGB(255, 190, 40), 3.5)
for _, d in ipairs(main:GetDescendants()) do
	if d:IsA("GuiButton") then d.SelectionImageObject = selectBox end
end
