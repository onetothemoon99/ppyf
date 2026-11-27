-- BACKUP 2026-11-27 of StarterPlayer.StarterPlayerScripts.GachaGui (Studio) before the snow leopard featured odds display.
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.GachaGui.Source.
-- Source bytes 62974, hash 1713665824 (h=(h*31+byte)%2147483647)
-- GachaGui: หน้าต่างตู้สุ่มสัตว์เลี้ยง (เปิดตอนกด E ที่ตู้ในแมพ)
-- การสุ่ม/ซื้อตั๋วทั้งหมดทำที่เซิร์ฟเวอร์ (GachaService) หน้าจอนี้แค่ส่งคำขอแล้วแสดงผล
-- แสดงอัตราออกทุกระดับเสมอ (กฎของ Roblox สำหรับการสุ่มแบบจ่ายเงิน) + ระบบการันตี + อีเวนต์ที่เปิดอยู่
-- แท็บ 💠 เลเวล & เศษ: ดูเลเวลสัตว์ทุกตัว (ได้ตัวซ้ำ = +1 เลเวลอัตโนมัติ) + ใช้เศษวิญญาณแลกสัตว์ในตู้
-- สุ่มเสร็จ: แคปซูลตกลงมา สั่น แย้มสีระดับที่ดีที่สุดที่ได้ แล้วแตกออก ค่อยโชว์การ์ดผลลัพธ์ (แตะเพื่อข้ามได้)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local tr, LANG = Localization.Tr()
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local gachaRequest = remoteEvents:WaitForChild("GachaRequest")
local gachaOpen = remoteEvents:WaitForChild("GachaOpen")
local PetRarity = require(ReplicatedStorage:WaitForChild("PetRarity"))
-- ชื่อระดับ/ชื่อสัตว์ตามภาษา (2026-11-07 เดิมใช้ DisplayName ไทยแล้วพึ่งแปลอัตโนมัติ ชื่อลับ/ตำนานจึงค้างเป็นไทย)
local function tierName(tier) return LANG == "en" and tier.DisplayNameEn or tier.DisplayName end
local function petName(p) return LANG == "en" and p.DisplayNameEn or p.DisplayName end
local previewFolder = ReplicatedStorage:WaitForChild("PetPreviewModels", 10)

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_SUB = Color3.fromRGB(130, 100, 90)
local COLOR_PINK = Color3.fromRGB(255, 200, 220)
local COLOR_GREEN = Color3.fromRGB(160, 230, 160)
local COLOR_GOLD = Color3.fromRGB(255, 215, 120)
local COLOR_DISABLED = Color3.fromRGB(215, 208, 205)

local info -- ข้อมูลตู้ล่าสุดจากเซิร์ฟเวอร์
local currentType = "Normal"
local DUPES_TAB = "__dupes" -- แท็บตัวซ้ำ & เศษ (ไม่ใช่แบบตั๋ว)
local working = false

-- 200000 -> "200,000"
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
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = COLOR_TEXT
	b.BackgroundColor3 = color or COLOR_PINK
	b.AutoButtonColor = true
	b.Selectable = true -- จอยเลือกได้ (กดด้วย Activated)
	b.Parent = parent
	corner(b, 10)
	return b
end

-- ============ หน้าต่างหลัก ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GachaGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 8
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
-- จอย: การเลือกวนอยู่ในหน้าต่าง ไม่หลุดไปปุ่มอื่นบนจอ
main.SelectionGroup = true
main.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
main.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
main.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
main.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
main.Active = true -- กันคลิกทะลุหน้าต่างไปโดนปุ่มข้างใต้ (เช่น ปุ่มเปิด/ปิดความสามารถบนแผงสัตว์ที่ใช้อยู่)
main.Parent = screenGui
corner(main, 16)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(140, 100, 65); mainStroke.Thickness = 2; mainStroke.Parent = main

-- ย่อให้พอดีจอเล็ก (มือถือแนวนอน)
local uiScale = Instance.new("UIScale"); uiScale.Parent = main
local camera = workspace.CurrentCamera
local function fit()
	local vp = camera.ViewportSize
	if vp.X < 2 then return end
	uiScale.Scale = math.clamp(math.min((vp.X - 24) / WIDTH, (vp.Y - 40) / HEIGHT), 0.5, 1)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = label(main, tr("🎁 ตู้สุ่มสัตว์เลี้ยง", "🎁 Pet Capsule Machine"), 20, COLOR_TEXT, true)
title.Size = UDim2.new(1, -60, 0, 36)
title.Position = UDim2.new(0, 16, 0, 8)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = button(main, "X", Color3.fromRGB(255, 190, 190))
closeButton.Name = "Close"
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.Activated:Connect(function() screenGui.Enabled = false end)

-- แท็บแบบตั๋ว
local tabRow = Instance.new("Frame")
tabRow.BackgroundTransparency = 1
tabRow.Size = UDim2.new(1, -32, 0, 36)
tabRow.Position = UDim2.new(0, 16, 0, 48)
tabRow.Parent = main
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 8); tabLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabLayout.Parent = tabRow
tabRow.Name = "TabRow"
local tabButtons = {}

-- ซ้าย: ตั๋ว + ปุ่มซื้อ/สุ่ม
local left = Instance.new("Frame")
left.BackgroundColor3 = Color3.fromRGB(255, 240, 235)
left.Size = UDim2.new(0, 250, 1, -104)
left.Position = UDim2.new(0, 16, 0, 92)
left.Parent = main
corner(left, 12)

local ticketLabel = label(left, "", 18, COLOR_TEXT, true)
ticketLabel.Size = UDim2.new(1, -20, 0, 30)
ticketLabel.Position = UDim2.new(0, 10, 0, 8)

local ticketSub = label(left, "", 12, COLOR_SUB)
ticketSub.Size = UDim2.new(1, -20, 0, 30)
ticketSub.Position = UDim2.new(0, 10, 0, 36)
ticketSub.TextYAlignment = Enum.TextYAlignment.Top

local buyLabel = label(left, tr("ซื้อตั๋ว", "Buy Tickets"), 13, COLOR_SUB, true)
buyLabel.Size = UDim2.new(1, -20, 0, 18)
buyLabel.Position = UDim2.new(0, 10, 0, 72)
buyLabel.TextXAlignment = Enum.TextXAlignment.Left

local buy1 = button(left, "", COLOR_GOLD)
buy1.Name = "Buy1"
buy1.Size = UDim2.new(0.5, -15, 0, 40)
buy1.Position = UDim2.new(0, 10, 0, 92)
buy1.TextWrapped = true
local buy10 = button(left, "", COLOR_GOLD)
buy10.Name = "Buy10"
buy10.Size = UDim2.new(0.5, -15, 0, 40)
buy10.Position = UDim2.new(0.5, 5, 0, 92)
buy10.TextWrapped = true

local rollLabel = label(left, tr("สุ่มสัตว์เลี้ยง", "Roll Pets"), 13, COLOR_SUB, true)
rollLabel.Size = UDim2.new(1, -20, 0, 18)
rollLabel.Position = UDim2.new(0, 10, 0, 142)
rollLabel.TextXAlignment = Enum.TextXAlignment.Left

local roll1 = button(left, tr("สุ่ม 1 ครั้ง", "Roll x1"), COLOR_PINK)
roll1.Name = "Roll1"
roll1.Size = UDim2.new(0.5, -15, 0, 52)
roll1.Position = UDim2.new(0, 10, 0, 162)
roll1.TextSize = 16
local roll10 = button(left, tr("สุ่ม 10 ครั้ง", "Roll x10"), COLOR_PINK)
roll10.Name = "Roll10"
roll10.Size = UDim2.new(0.5, -15, 0, 52)
roll10.Position = UDim2.new(0.5, 5, 0, 162)
roll10.TextSize = 16

local statusLabel = label(left, "", 12, Color3.fromRGB(200, 80, 80), true)
statusLabel.Size = UDim2.new(1, -20, 0, 50)
statusLabel.Position = UDim2.new(0, 10, 0, 222)
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

-- ขวา: อัตราออก + รายชื่อสัตว์ในตู้
local right = Instance.new("ScrollingFrame")
right.BackgroundColor3 = Color3.fromRGB(255, 244, 240)
right.Size = UDim2.new(1, -298, 1, -104)
right.Position = UDim2.new(0, 282, 0, 92)
right.ScrollBarThickness = 6
right.AutomaticCanvasSize = Enum.AutomaticSize.Y
right.CanvasSize = UDim2.new()
right.BorderSizePixel = 0
right.Selectable = false
right.Parent = main
corner(right, 12)
local rightPad = Instance.new("UIPadding"); rightPad.PaddingTop = UDim.new(0, 8); rightPad.PaddingLeft = UDim.new(0, 8); rightPad.PaddingRight = UDim.new(0, 12); rightPad.PaddingBottom = UDim.new(0, 8); rightPad.Parent = right
local rightLayout = Instance.new("UIListLayout"); rightLayout.Padding = UDim.new(0, 6); rightLayout.SortOrder = Enum.SortOrder.LayoutOrder; rightLayout.Parent = right

-- แท็บตัวซ้ำ & เศษ (แทนที่ซ้าย+ขวา ตอนเลือกแท็บนี้)
local dupePanel = Instance.new("Frame")
dupePanel.Name = "Dupes"
dupePanel.BackgroundTransparency = 1
dupePanel.Size = UDim2.new(1, -32, 1, -104)
dupePanel.Position = UDim2.new(0, 16, 0, 92)
dupePanel.Visible = false
dupePanel.Parent = main

local shardLabel = label(dupePanel, "", 16, Color3.fromRGB(70, 110, 190), true)
shardLabel.Size = UDim2.new(0.5, 0, 0, 22)
shardLabel.TextXAlignment = Enum.TextXAlignment.Left

local dupeStatus = label(dupePanel, "", 12, Color3.fromRGB(40, 150, 60), true)
dupeStatus.Size = UDim2.new(0.5, 0, 0, 22)
dupeStatus.Position = UDim2.new(0.5, 0, 0, 0)
dupeStatus.TextXAlignment = Enum.TextXAlignment.Right

local dupeRules = label(dupePanel, "", 11, COLOR_SUB)
dupeRules.Size = UDim2.new(1, 0, 0, 30)
dupeRules.Position = UDim2.new(0, 0, 0, 22)
dupeRules.TextXAlignment = Enum.TextXAlignment.Left
dupeRules.TextYAlignment = Enum.TextYAlignment.Top

local dupeList = Instance.new("ScrollingFrame")
dupeList.BackgroundColor3 = Color3.fromRGB(245, 244, 255)
dupeList.Size = UDim2.new(1, 0, 1, -56)
dupeList.Position = UDim2.new(0, 0, 0, 56)
dupeList.ScrollBarThickness = 6
dupeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
dupeList.CanvasSize = UDim2.new()
dupeList.BorderSizePixel = 0
dupeList.Selectable = false
dupeList.Parent = dupePanel
corner(dupeList, 12)
local dupePad = Instance.new("UIPadding"); dupePad.PaddingTop = UDim.new(0, 6); dupePad.PaddingLeft = UDim.new(0, 6); dupePad.PaddingRight = UDim.new(0, 12); dupePad.PaddingBottom = UDim.new(0, 6); dupePad.Parent = dupeList
local dupeLayout = Instance.new("UIListLayout"); dupeLayout.Padding = UDim.new(0, 6); dupeLayout.SortOrder = Enum.SortOrder.LayoutOrder; dupeLayout.Parent = dupeList

-- ============ หน้าผลลัพธ์ ============
local resultOverlay = Instance.new("Frame")
resultOverlay.Name = "Results"
resultOverlay.Size = UDim2.new(1, 0, 1, 0)
resultOverlay.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
resultOverlay.BackgroundTransparency = 0.25
resultOverlay.Visible = false
resultOverlay.Active = true -- กันคลิกทะลุไปโดนปุ่มซื้อ/สุ่มที่อยู่ข้างใต้ (เดิมกดพื้นหลังผลลัพธ์แล้วซื้อตั๋วเพิ่มโดยไม่ตั้งใจ)
resultOverlay.ZIndex = 20
resultOverlay.SelectionGroup = true
resultOverlay.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
resultOverlay.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
resultOverlay.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
resultOverlay.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
resultOverlay.Parent = main
corner(resultOverlay, 16)

local resultTitle = label(resultOverlay, tr("🎉 ผลการสุ่ม", "🎉 Gacha Results"), 20, Color3.new(1, 1, 1), true)
resultTitle.Size = UDim2.new(1, 0, 0, 36)
resultTitle.Position = UDim2.new(0, 0, 0, 10)
resultTitle.ZIndex = 21

local resultGrid = Instance.new("Frame")
resultGrid.BackgroundTransparency = 1
resultGrid.Size = UDim2.new(1, -24, 1, -110)
resultGrid.Position = UDim2.new(0, 12, 0, 50)
resultGrid.ZIndex = 21
resultGrid.Parent = resultOverlay
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 100, 0, 128)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = resultGrid

local okButton = button(resultOverlay, tr("ตกลง", "OK"), COLOR_GREEN)
okButton.Name = "OK"
okButton.Size = UDim2.new(0, 160, 0, 40)
okButton.AnchorPoint = Vector2.new(0.5, 1)
okButton.Position = UDim2.new(0.5, 0, 1, -12)
okButton.ZIndex = 22
okButton.Activated:Connect(function()
	resultOverlay.Visible = false
	working = false
end)

-- ระหว่างสุ่ม (กดสุ่ม -> รอเซิร์ฟเวอร์ -> แคปซูลแตก -> หน้าผล จนกด "ตกลง") ห้ามปิดหน้าต่าง
-- (เดิมปิดได้ / บทเรียนปิดตู้ตัดหน้า = เสียตั๋วแล้วไม่เห็นว่าได้อะไร) ซ่อนปุ่ม X และถ้ามีอะไรปิดหน้าต่าง = เปิดคืนทันที
-- Attribute "GachaBusy" บอกสคริปต์อื่น (เช่น TutorialGui) ว่ากำลังสุ่มอยู่ ให้รอก่อน
local rolling = false
local function setRolling(on)
	rolling = on
	closeButton.Visible = not on
	player:SetAttribute("GachaBusy", on or nil)
end
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if rolling and not screenGui.Enabled then screenGui.Enabled = true end
end)
-- ปิดหน้าผลแล้ว (กดตกลง / B) = สุ่มเสร็จสมบูรณ์
resultOverlay:GetPropertyChangedSignal("Visible"):Connect(function()
	if not resultOverlay.Visible and rolling then setRolling(false) end
end)

-- โมเดล 3D ของสัตว์ในการ์ดผลลัพธ์ (ใช้สำเนาที่ PetManager เตรียมไว้ให้เมนูสัตว์เลี้ยง)
local function addPreview(parent, petId)
	local template = previewFolder and previewFolder:FindFirstChild(petId)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, -12, 0, 70)
	vp.Position = UDim2.new(0, 6, 0, 6)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(200, 200, 200)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.ZIndex = parent.ZIndex + 1
	vp.Parent = parent
	if not template then
		local t = label(vp, "🐾", 30); t.Size = UDim2.new(1, 0, 1, 0); t.ZIndex = vp.ZIndex
		return
	end
	local model = template:Clone()
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	model.Parent = vp
	local cf, size = model:GetBoundingBox()
	local front = -model:GetPivot().LookVector
	local radius = size.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(cf.Position + front * (radius / math.sin(math.rad(15)) * 0.8) + Vector3.new(0, radius * 0.4, 0), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
end

local function showResults(results)
	working = true -- ปิดปุ่มซื้อ/สุ่มจนกว่าจะกด "ตกลง"
	for _, c in ipairs(resultGrid:GetChildren()) do if not c:IsA("UIGridLayout") then c:Destroy() end end
	gridLayout.CellSize = #results > 1 and UDim2.new(0, 96, 0, 124) or UDim2.new(0, 150, 0, 170)
	resultOverlay.Visible = true
	for i, r in ipairs(results) do
		local tier = PetRarity.Get(r.Rarity)
		local card = Instance.new("Frame")
		card.LayoutOrder = i
		card.BackgroundColor3 = tier.RowColor
		card.ZIndex = 22
		card.Parent = resultGrid
		corner(card, 10)
		local stroke = Instance.new("UIStroke"); stroke.Color = tier.Color; stroke.Thickness = tier.Order > 1 and 3 or 1.5; stroke.Parent = card
		addPreview(card, r.PetId)
		local name = label(card, petName(r), 12, COLOR_TEXT, true)
		name.Size = UDim2.new(1, -8, 0, 28)
		name.Position = UDim2.new(0, 4, 1, -50)
		name.ZIndex = 23
		local badge = label(card, tierName(tier), 11, Color3.new(1, 1, 1), true)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = tier.Color
		badge.Size = UDim2.new(0, 60, 0, 16)
		badge.Position = UDim2.new(0, 4, 0, 4)
		badge.ZIndex = 23
		corner(badge, 8)
		if r.Forced then -- ได้จากการันตี
			local shield = label(card, "🛡️", 14)
			shield.Size = UDim2.new(0, 20, 0, 18)
			shield.Position = UDim2.new(1, -24, 0, 3)
			shield.ZIndex = 23
		end
		local tagText = r.IsNew and tr("✨ ใหม่!", "✨ New!")
			or (r.AutoShards and ("Lv.MAX → +" .. r.AutoShards .. " 💠"))
			or (r.NewLevel and ("⬆️ Lv." .. r.NewLevel .. "!"))
			or tr("ซ้ำ", "Dup")
		local tag = label(card, tagText, 11, r.IsNew and Color3.fromRGB(40, 150, 60) or COLOR_SUB, true)
		tag.Size = UDim2.new(1, -8, 0, 16)
		tag.Position = UDim2.new(0, 4, 1, -20)
		tag.ZIndex = 23
		-- โผล่ทีละใบ
		card.Visible = false
		task.delay((i - 1) * 0.12, function()
			if card.Parent then
				card.Visible = true
				local sc = Instance.new("UIScale"); sc.Scale = 0.4; sc.Parent = card
				TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end)
	end
end

-- ============ แอนิเมชันแคปซูลแตก ============
local revealLayer = Instance.new("TextButton") -- ทั้งจอ: บังคลิกทุกอย่าง + แตะเพื่อข้าม
revealLayer.Name = "Reveal"
revealLayer.Size = UDim2.new(1, 0, 1, 0)
revealLayer.BackgroundColor3 = Color3.fromRGB(25, 15, 30)
revealLayer.BackgroundTransparency = 0.3
revealLayer.Text = ""
revealLayer.AutoButtonColor = false
revealLayer.Selectable = false
revealLayer.Visible = false
revealLayer.ZIndex = 50
revealLayer.Parent = screenGui

local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.BackgroundTransparency = 1
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.new(0.5, 0, 0.5, 0)
stage.Size = UDim2.new(0, 360, 0, 360)
stage.ZIndex = 51
stage.Parent = revealLayer
local stageScale = Instance.new("UIScale"); stageScale.Parent = stage

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.ZIndex = 60
flash.Parent = revealLayer

local skipHint = label(revealLayer, tr("แตะเพื่อข้าม", "Tap to skip"), 14, Color3.fromRGB(230, 220, 230), true)
skipHint.AnchorPoint = Vector2.new(0.5, 1)
skipHint.Position = UDim2.new(0.5, 0, 1, -24)
skipHint.Size = UDim2.new(0, 200, 0, 24)
skipHint.ZIndex = 61

local function circle(parent, size, color, z)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(0.5, 0, 0.5, 0)
	f.Size = size
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	corner(f, 999)
	return f
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local skipReveal = nil -- ฟังก์ชันข้ามแอนิเมชันที่กำลังเล่น (ให้จอยกด A/B ข้ามได้)
local CAPSULE = 150
local NEUTRAL = Color3.fromRGB(255, 140, 185)

local function playReveal(results, onDone)
	working = true -- กันกดซื้อ/สุ่มซ้อนระหว่างเล่น
	player:SetAttribute("GachaRevealing", true) -- GachaAnnouncer รอให้จบก่อนประกาศของตัวเอง
	local best = results[1].Rarity
	for _, r in ipairs(results) do
		if PetRarity.Get(r.Rarity).Order > PetRarity.Get(best).Order then best = r.Rarity end
	end
	local tier = PetRarity.Get(best)
	local order = tier.Order
	local tierColor = tier.Gradient and Color3.new(1, 1, 1) or tier.Color

	for _, c in ipairs(stage:GetChildren()) do if not c:IsA("UIScale") then c:Destroy() end end
	stageScale.Scale = uiScale.Scale
	flash.BackgroundTransparency = 1
	revealLayer.Visible = true

	-- แสงด้านหลัง + ลำแสงหมุน (ตำนานขึ้นไป)
	local glow = circle(stage, UDim2.new(0, 250, 0, 250), tierColor, 52)
	glow.BackgroundTransparency = 1
	if tier.Gradient then local gg = Instance.new("UIGradient"); gg.Color = tier.Gradient; gg.Parent = glow end
	local rays = Instance.new("Frame")
	rays.Name = "Rays"
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.new(0.5, 0, 0.5, 0)
	rays.Size = UDim2.new(0, 360, 0, 360)
	rays.BackgroundTransparency = 1
	rays.Visible = false
	rays.ZIndex = 52
	rays.Parent = stage
	for i = 0, 7 do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.new(0.5, 0, 0.5, 0)
		ray.Size = UDim2.new(0, 14, 1, 0)
		ray.Rotation = i * 22.5
		ray.BackgroundColor3 = tierColor
		ray.BorderSizePixel = 0
		ray.ZIndex = 52
		ray.Parent = rays
		local rg = Instance.new("UIGradient")
		rg.Rotation = 90
		rg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 1),
		})
		if tier.Gradient then rg.Color = tier.Gradient end
		rg.Parent = ray
	end

	-- แคปซูล: ครึ่งบนสี (แย้มระดับ) + ครึ่งล่างขาว + แถบกลาง
	local capsule = Instance.new("Frame")
	capsule.Name = "Capsule"
	capsule.AnchorPoint = Vector2.new(0.5, 0.5)
	capsule.Position = UDim2.new(0.5, 0, -0.6, 0)
	capsule.Size = UDim2.new(0, CAPSULE, 0, CAPSULE)
	capsule.BackgroundTransparency = 1
	capsule.ZIndex = 53
	capsule.Parent = stage

	local function half(isTop)
		local h = Instance.new("CanvasGroup") -- ตัดครึ่งวงกลม + จางทั้งชิ้นได้
		h.Name = isTop and "Top" or "Bottom"
		h.Size = UDim2.new(1, 0, 0.5, 0)
		h.Position = UDim2.new(0, 0, isTop and 0 or 0.5, 0)
		h.BackgroundTransparency = 1
		h.ZIndex = 54
		h.Parent = capsule
		local ball = Instance.new("Frame")
		ball.Size = UDim2.new(1, 0, 2, 0)
		ball.Position = UDim2.new(0, 0, isTop and 0 or -1, 0)
		ball.BackgroundColor3 = isTop and NEUTRAL or Color3.fromRGB(255, 250, 245)
		ball.BorderSizePixel = 0
		ball.ZIndex = 54
		ball.Parent = h
		corner(ball, 999)
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(120, 80, 90); stroke.Thickness = 3; stroke.Parent = ball
		local shade = Instance.new("UIGradient") -- เงานูนๆ
		shade.Rotation = 90
		shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 205, 215))
		shade.Parent = ball
		return h, ball
	end
	local top, topBall = half(true)
	local bottom = half(false)
	local shine = circle(top, UDim2.new(0, 34, 0, 22), Color3.new(1, 1, 1), 55)
	shine.Position = UDim2.new(0.3, 0, 0.35, 0)
	shine.Rotation = -30
	shine.BackgroundTransparency = 0.35
	local band = Instance.new("Frame")
	band.Name = "Band"
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.new(0.5, 0, 0.5, 0)
	band.Size = UDim2.new(1, 4, 0, 12)
	band.BackgroundColor3 = Color3.fromRGB(120, 80, 90)
	band.BorderSizePixel = 0
	band.ZIndex = 56
	band.Parent = capsule
	corner(band, 6)

	local bigText = label(stage, "", 30, Color3.new(1, 1, 1), true)
	bigText.Font = Enum.Font.GothamBlack
	bigText.AnchorPoint = Vector2.new(0.5, 0.5)
	bigText.Position = UDim2.new(0.5, 0, 0.5, 0)
	bigText.Size = UDim2.new(1, 0, 0, 50)
	bigText.ZIndex = 58
	bigText.TextTransparency = 1
	local bigStroke = Instance.new("UIStroke"); bigStroke.Color = Color3.fromRGB(40, 20, 50); bigStroke.Thickness = 3; bigStroke.Transparency = 1; bigStroke.Parent = bigText
	if tier.Gradient then local bg = Instance.new("UIGradient"); bg.Color = tier.Gradient; bg.Parent = bigText
	else bigText.TextColor3 = tier.Color end

	local finished = false
	local skipConn, spinConn
	local function finish()
		if finished then return end
		finished = true
		skipReveal = nil
		if skipConn then skipConn:Disconnect() end
		if spinConn then spinConn:Disconnect() end
		revealLayer.Visible = false
		for _, c in ipairs(stage:GetChildren()) do if not c:IsA("UIScale") then c:Destroy() end end
		player:SetAttribute("GachaRevealing", nil)
		onDone()
	end
	skipConn = revealLayer.Activated:Connect(finish)
	skipReveal = finish
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if rays.Parent and rays.Visible then rays.Rotation = (rays.Rotation + dt * 35) % 360 end
	end)

	task.spawn(function()
		local function pause(t) task.wait(t) return finished end
		-- 1) ตกลงมาเด้งๆ
		tween(capsule, 0.55, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Bounce)
		if pause(0.7) then return end
		-- 2) สั่น: ครั้งที่ 1 เฉยๆ, ครั้งที่ 2 แย้มสี (หายากขึ้นไป), ครั้งที่ 3 ลำแสง (ตำนานขึ้นไป)
		local shakes = order >= 3 and 3 or 2
		for i = 1, shakes do
			local angle = 8 + i * 5
			for k = 1, 4 do
				tween(capsule, 0.06, { Rotation = (k % 2 == 1 and angle or -angle) })
				if pause(0.06) then return end
			end
			tween(capsule, 0.08, { Rotation = 0 })
			if i == 2 and order >= 2 then
				tween(topBall, 0.25, { BackgroundColor3 = tierColor })
				if tier.Gradient then local tg = Instance.new("UIGradient"); tg.Color = tier.Gradient; tg.Parent = topBall end
				tween(glow, 0.3, { BackgroundTransparency = 0.6 })
			end
			if i == 3 and order >= 3 then
				rays.Visible = true
				tween(glow, 0.3, { BackgroundTransparency = 0.35, Size = UDim2.new(0, 290, 0, 290) })
			end
			if pause(i == shakes and 0.45 or 0.35) then return end
		end
		-- 3) แตก: ฝาบนเด้งขึ้น ฝาล่างร่วง แสงวาบ
		band.Visible = false
		tween(top, 0.5, { Position = UDim2.new(-0.25, 0, -0.9, 0), Rotation = -35, GroupTransparency = 1 })
		tween(bottom, 0.5, { Position = UDim2.new(0.2, 0, 1.3, 0), Rotation = 20, GroupTransparency = 1 })
		flash.BackgroundTransparency = order >= 3 and 0 or 0.4
		tween(flash, 0.6, { BackgroundTransparency = 1 })
		if order >= 3 then
			bigText.Text = tier.Gradient and ("✨ " .. tierName(tier) .. "!! ✨") or ("✨ " .. tierName(tier) .. "! ✨")
			local pop = Instance.new("UIScale"); pop.Scale = 0.3; pop.Parent = bigText
			tween(pop, 0.4, { Scale = 1.15 }, Enum.EasingStyle.Back)
			tween(bigText, 0.2, { TextTransparency = 0 })
			tween(bigStroke, 0.2, { Transparency = 0 })
		end
		if pause(order >= 3 and 1.3 or 0.5) then return end
		finish()
	end)
end

-- ============ แสดงข้อมูลตามแบบตั๋วที่เลือก ============
local productPrices = {} -- [productId] = ราคา Robux จริงจาก Dashboard

local function currentTypeInfo()
	if not info then return nil end
	for _, t in ipairs(info.Types) do if t.Id == currentType then return t end end
	return nil
end

local function setStatus(text, good)
	statusLabel.Text = text or ""
	statusLabel.TextColor3 = good and Color3.fromRGB(40, 150, 60) or Color3.fromRGB(200, 80, 80)
end

local function fmtPct(pct)
	local s = string.format("%.2f", pct):gsub("0+$", ""):gsub("%.$", "")
	return s .. "%"
end

local function fmtTimeLeft(seconds)
	seconds = math.max(0, seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	if days > 0 then return string.format(tr("%d วัน %d ชม.", "%d d %d h"), days, hours) end
	if hours > 0 then return string.format(tr("%d ชม. %d นาที", "%d h %d m"), hours, minutes) end
	return string.format(tr("%d นาที", "%d m"), math.max(1, minutes))
end

local function textRow(order, text, size, color, bold)
	local l = label(right, text, size, color, bold)
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = order
	return l
end

local function boxRow(order, bg, strokeColor)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.BackgroundColor3 = bg
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Parent = right
	corner(row, 8)
	local stroke = Instance.new("UIStroke"); stroke.Color = strokeColor; stroke.Thickness = 1.5; stroke.Parent = row
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = row
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 2); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = row
	return row
end

local function rowText(row, order, text, size, color, bold)
	local l = label(row, text, size, color, bold)
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = order
	return l
end

local function renderOdds(t)
	for _, c in ipairs(right:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local eventRarity = info.EventRarity or "Secret"

	-- อีเวนต์ที่เปิดอยู่ (ลับออกเฉพาะช่วงนี้)
	if info.Event then
		local banner = boxRow(-2, Color3.fromRGB(255, 225, 240), Color3.fromRGB(230, 110, 170))
		rowText(banner, 1, "🎉 " .. (LANG == "en" and info.Event.NameEn or info.Event.Name), 14, Color3.fromRGB(190, 60, 130), true)
		rowText(banner, 2, tr("ระดับลับออกได้เฉพาะช่วงอีเวนต์", "Secret rarity available only during events") .. " · " .. tr("เหลือ", "Time left") .. " " .. fmtTimeLeft(info.Event.EndsAt - workspace:GetServerTimeNow()), 12, COLOR_SUB)
	end

	textRow(0, tr("อัตราออกของ", "Drop rates for") .. " " .. t.DisplayName, 14, COLOR_TEXT, true)
	-- เรียงจากหายากไปธรรมดา
	local rarities = {}
	for rarityId in pairs(t.Odds) do table.insert(rarities, rarityId) end
	table.sort(rarities, function(a, b) return PetRarity.Get(a).Order > PetRarity.Get(b).Order end)
	for i, rarityId in ipairs(rarities) do
		local tier = PetRarity.Get(rarityId)
		local row = boxRow(i, tier.RowColor, tier.Color)
		rowText(row, 1, tierName(tier) .. "  " .. fmtPct(t.Odds[rarityId]), 14, tier.Color, true)
		local names = {}
		for _, pet in ipairs(info.Pool[rarityId] or {}) do
			table.insert(names, (pet.Owned and "✓ " or "") .. petName(pet))
		end
		rowText(row, 2, table.concat(names, " · "), 12, COLOR_SUB)
	end
	if not t.Odds[eventRarity] then -- นอกอีเวนต์: บอกว่าลับหายไปไหน
		local tier = PetRarity.Get(eventRarity)
		local row = boxRow(#rarities + 1, Color3.fromRGB(240, 236, 240), Color3.fromRGB(200, 190, 200))
		rowText(row, 1, tierName(tier) .. "  –", 14, COLOR_SUB, true)
		rowText(row, 2, tr("ออกเฉพาะช่วงอีเวนต์เท่านั้น", "Available only during events"), 12, COLOR_SUB)
	end

	-- ระบบการันตี + ความคืบหน้าของผู้เล่น
	local rules, pity, rates = t.PityRules or {}, t.Pity or {}, t.WithPity or {}
	local box = boxRow(50, Color3.fromRGB(235, 245, 255), Color3.fromRGB(110, 160, 220))
	rowText(box, 1, tr("🛡️ ระบบการันตี", "🛡️ Pity System") .. " (" .. t.DisplayName .. ")", 14, Color3.fromRGB(50, 100, 170), true)
	local lines = {
		{ key = "Rare", text = tr("หายากขึ้นไป: ทุก %d ครั้ง", "Rare+: every %d pulls") },
		{ key = "Legendary", text = tr("ตำนาน: ภายใน %d ครั้ง", "Legendary: within %d pulls") },
		{ key = "Secret", text = tr("ลับ: ภายใน %d ครั้ง", "Secret: within %d pulls") }, -- 2026-11-01 ลับมีตัวที่อยู่ตลอด (จริงใจจิงโจ้) ไม่เฉพาะอีเวนต์แล้ว
	}
	for i, line in ipairs(lines) do
		local every = rules[line.key]
		if every then
			local left = math.max(1, every - (pity[line.key] or 0))
			rowText(box, 1 + i, string.format(line.text, every) .. string.format(tr("  ·  อีก %d ครั้ง", "  ·  %d pulls left"), left), 12, COLOR_TEXT)
		end
	end
	-- 2026-11-15 ผู้ใช้สั่ง: ไม่แสดงบรรทัด "เรตรวมเมื่อนับการันตี ≈ ..." แล้ว (เซิร์ฟเวอร์ยังส่ง WithPity มาเหมือนเดิม) · สำเนาเดิม backups/GachaGui_before_hidePityRate_20261115.lua
	rowText(box, 11, tr("• ตัวนับการันตีแยกตามประเภทตั๋ว", "• Pity counters are separate per ticket type"), 11, COLOR_SUB)
	rowText(box, 12, tr("• ตัวนับการันตีลับสะสมข้ามอีเวนต์ได้", "• Secret pity counter carries across events"), 11, COLOR_SUB)

	textRow(99, tr("✓ = มีแล้ว · 🛡️ = ได้จากการันตี · ได้ตัวซ้ำ = +1 เลเวลทันที (เต็มแล้วเป็นเศษ ใช้แลกตัวได้ที่แท็บ 💠)", "✓ = Owned · 🛡️ = From pity · Dup = +1 level (max → shards, exchange in 💠 tab)"), 11, COLOR_SUB)
end

-- ============ แท็บตัวซ้ำ & เศษ ============
local doPetAction -- ประกาศไว้ก่อน (ปุ่มในแถวเรียกใช้)

local function smallButton(parent, text, enabled, onClick)
	local b = button(parent, text, enabled and COLOR_PINK or COLOR_DISABLED)
	b.TextSize = 11
	b.TextWrapped = true
	b.AutoButtonColor = enabled
	b.TextColor3 = enabled and COLOR_TEXT or COLOR_SUB
	b.Activated:Connect(function()
		if enabled then onClick() end
	end)
	return b
end

-- บรรทัด "อัพเลเวลได้อะไร" ใต้แต่ละแถว (2026-10-15 ผู้ใช้ขอ) ตัวที่มีโบนัสเลเวลเฉพาะอ่านจาก PetLevelConfig.LevelPerks
local PetLevelConfig = require(ReplicatedStorage:WaitForChild("PetLevelConfig"))
local function fmtMult(bonus)
	local s = string.format("%.2f", 1 + bonus):gsub("0+$", ""):gsub("%.$", "")
	return "x" .. s
end

local function renderDupes()
	for _, c in ipairs(dupeList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local shards = player:GetAttribute("PetShards") or info.Shards or 0
	local lv = info.Level or { Max = 15, SpeedPerLevel = 0.02, HungerPerLevel = 0.02 }
	shardLabel.Text = tr("💠 เศษวิญญาณ: ", "💠 Spirit Shards: ") .. shards
	dupeRules.Text = string.format(tr("ได้ตัวซ้ำ = +1 เลเวลทันที (สูงสุด Lv.%d) ทุกเลเวลทำงานเร็วขึ้น %d%% หิวช้าลง %d%% · เลเวลเต็มแล้วได้ซ้ำ = กลายเป็นเศษวิญญาณ · ใช้เศษแลกตัวที่อยากได้", "Dup = +1 level (max Lv.%d) · Each level: +%d%% speed, -%d%% hunger · Max dup → shards · Exchange shards for pets"),
		lv.Max, math.floor(lv.SpeedPerLevel * 100 + 0.5), math.floor(lv.HungerPerLevel * 100 + 0.5))
	for i, pet in ipairs(info.Pets or {}) do
		local tier = PetRarity.Get(pet.Rarity)
		local owned = pet.Owned
		local level = player:GetAttribute("PetLevel_" .. pet.Id) or pet.Level or 1
		local dupes = player:GetAttribute("PetDupes_" .. pet.Id) or 0
		local maxed = owned and level >= lv.Max

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.BackgroundColor3 = tier.RowColor
		row.Size = UDim2.new(1, 0, 0, 72)
		row.Parent = dupeList
		corner(row, 8)
		local stroke = Instance.new("UIStroke"); stroke.Color = tier.Color; stroke.Thickness = 1.5; stroke.Parent = row

		local name = label(row, tierName(tier) .. " · " .. petName(pet), 14, tier.Color, true)
		name.Size = UDim2.new(1, -130, 0, 20)
		name.Position = UDim2.new(0, 10, 0, 6)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.TextWrapped = false

		local perk = PetLevelConfig.PerkOf(pet.Id)
		local strawPerk = perk and perk.Kind == "StrawYield"
		local hungerPct = math.floor((level - 1) * lv.HungerPerLevel * 100 + 0.5)
		local detail
		if owned then
			local bonus = math.floor((level - 1) * lv.SpeedPerLevel * 100 + 0.5)
			local bonusText = ""
			if strawPerk then
				bonusText = string.format(tr(" · ผลผลิตรัศมีหุ่นฟาง %s", " · Straw-radius yield %s"), fmtMult(PetLevelConfig.StrawYieldAt(pet.Id, level)))
					.. (hungerPct > 0 and string.format(tr(" หิวช้าลง %d%%", ", -%d%% hunger"), hungerPct) or "")
			elseif bonus > 0 then
				bonusText = string.format(tr(" · เร็ว +%d%% หิวช้าลง %d%%", " · +%d%% speed, -%d%% hunger"), bonus, hungerPct)
			end
			detail = string.format("Lv.%d/%d%s%s", level, lv.Max, bonusText,
				(maxed and not pet.Premium) and tr(" · ได้ซ้ำเป็นเศษ", " · Dup → shards") or "")
		else
			detail = pet.UnlockHint or (pet.InPool and tr("ยังไม่มี · สุ่มหรือใช้เศษแลกได้", "Not owned · Roll or exchange shards") or tr("ยังไม่มี · อยู่ในตู้เฉพาะช่วงอีเวนต์", "Not owned · Event-exclusive"))
		end
		local sub = label(row, detail, 11, COLOR_SUB, true)
		sub.Size = UDim2.new(1, -130, 0, 18)
		sub.Position = UDim2.new(0, 10, 0, 28)
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextTruncate = Enum.TextTruncate.AtEnd
		sub.TextWrapped = false

		-- อัพเลเวลได้อะไร (+ เลเวลถัดไปถ้ามีตัวแล้วและยังไม่เต็ม)
		local perkText
		if strawPerk then
			perkText = string.format(tr("⬆️ อัพเลเวล: ผลผลิตในรัศมีหุ่นฟาง %s → %s (Lv.%d) · หิวช้าลง %d%%/เลเวล", "⬆️ Level up: straw-radius yield %s → %s (Lv.%d) · -%d%% hunger/level"),
				fmtMult(perk.Min), fmtMult(perk.Max), lv.Max, math.floor(lv.HungerPerLevel * 100 + 0.5))
			if owned and not maxed then
				perkText ..= string.format(tr(" · เลเวลถัดไป %s", " · next %s"), fmtMult(PetLevelConfig.StrawYieldAt(pet.Id, level + 1)))
			end
		else
			perkText = string.format(tr("⬆️ อัพเลเวล: ทำงานเร็วขึ้น %d%% หิวช้าลง %d%% ต่อเลเวล (Lv.%d = เร็ว +%d%%)", "⬆️ Level up: +%d%% speed, -%d%% hunger per level (Lv.%d = +%d%% speed)"),
				math.floor(lv.SpeedPerLevel * 100 + 0.5), math.floor(lv.HungerPerLevel * 100 + 0.5), lv.Max, math.floor((lv.Max - 1) * lv.SpeedPerLevel * 100 + 0.5))
		end
		local perkLabel = label(row, perkText, 11, Color3.fromRGB(120, 90, 170), true)
		perkLabel.Name = "LevelPerk"
		perkLabel.Size = UDim2.new(1, -130, 0, 18)
		perkLabel.Position = UDim2.new(0, 10, 0, 48)
		perkLabel.TextXAlignment = Enum.TextXAlignment.Left
		perkLabel.TextTruncate = Enum.TextTruncate.AtEnd
		perkLabel.TextWrapped = false

		local cost = pet.ShardCost
		local canBuy = cost ~= nil and pet.InPool and shards >= cost and not maxed
		local buyText
		if pet.UnlockHint then
			buyText = tr("🐾 แลกด้วยเศษ\nไม่ได้", "🐾 Shard Exchange\nN/A") -- ได้จากที่อื่นเท่านั้น (ดูข้อความใต้ชื่อ)
		elseif not cost then
			buyText = tr("🐾 แลกตัวนี้\nสุ่มเท่านั้น", "🐾 Exchange\nRoll Only") -- เช่น ระดับลับ: ได้จากตู้ช่วงอีเวนต์อย่างเดียว
		elseif not pet.InPool then
			buyText = tr("🐾 แลกตัวนี้\nยังไม่อยู่ในตู้", "🐾 Exchange\nNot in pool")
		elseif maxed then
			buyText = tr("🐾 แลกตัวนี้\nเลเวลเต็ม", "🐾 Exchange\nMax level")
		else
			buyText = tr("🐾 แลกตัวนี้", "🐾 Exchange") .. "\n💠 " .. commas(cost)
		end
		-- นาก / ระดับลับ / สุลต่าน: แลกตัวใหม่ไม่ได้ แต่ถ้ามีอยู่แล้ว ใช้เศษอัปเลเวลได้ (ราคาจากเซิร์ฟเวอร์ pet.LevelUpCost)
		local buyAction = "exchange"
		local levelCost = pet.LevelUpCost
		if levelCost then
			buyAction = "shardLevelUp"
			if not owned then
				buyText = tr("⬆️ อัพเลเวล\nไม่สามารถอัพได้", "⬆️ Level Up\nNot owned")
				canBuy = false
			elseif maxed then
				buyText = tr("⬆️ อัพเลเวล\nเลเวลเต็ม", "⬆️ Level Up\nMax level")
				canBuy = false
			else
				buyText = tr("⬆️ อัพเลเวล", "⬆️ Level Up") .. "\n💠 " .. commas(levelCost)
				canBuy = shards >= levelCost
			end
		end
		-- สัตว์พรีเมียม (แม่มดน้อย 2026-10-14): ซื้อด้วย Robux เท่านั้น ซื้อซ้ำ = +1 เลเวล เต็มแล้วซื้อไม่ได้ (เซิร์ฟเวอร์เช็กซ้ำก่อนเปิดหน้าซื้อ)
		if pet.Premium then
			local p = pet.Premium
			local priceText = p.Price and ("R$ " .. commas(p.Price)) or "Robux"
			if not p.OnSale then
				buyText, canBuy = tr("💎 ซื้อ\nยังไม่เปิดขาย", "💎 Buy\nNot on sale"), false
			elseif owned and level >= (p.MaxLevel or lv.Max) then
				buyText, canBuy = tr("⬆️ ซื้อเลเวล\nเลเวลเต็ม", "⬆️ Buy Level\nMax level"), false
			elseif owned then
				buyText, canBuy = tr("⬆️ ซื้อ +1 เลเวล", "⬆️ Buy +1 Lv") .. "\n" .. priceText, true
			else
				buyText, canBuy = tr("💎 ซื้อแม่มดน้อย", "💎 Buy") .. "\n" .. priceText, true
			end
			buyAction = "premium"
		end
		local b3 = smallButton(row, buyText, canBuy, function()
			if buyAction == "premium" then
				local ev = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("PremiumPetBuy")
				if ev then ev:FireServer(pet.Id) end
				return
			end
			doPetAction(buyAction, pet.Id, 1)
		end)
		if levelCost and not owned then
			-- ยังไม่มีสัตว์ตัวนี้: กดแล้วบอกเหตุผล (ปุ่มปิดอยู่จึงไม่ส่งคำขอไปเซิร์ฟเวอร์)
			b3.Activated:Connect(function()
				dupeStatus.TextColor3 = Color3.fromRGB(200, 80, 80)
				dupeStatus.Text = tr("ไม่สามารถอัพเลเวลได้ (ยังไม่มีสัตว์ตัวนี้)", "Can't level up (you don't own this pet)")
			end)
		end
		b3.Name = "Exchange_" .. pet.Id
		b3.Size = UDim2.new(0, 100, 0, 42)
		b3.Position = UDim2.new(1, -106, 0, 15)
		if canBuy then b3.BackgroundColor3 = COLOR_GOLD end
	end
end

local function refresh()
	main:SetAttribute("CurrentType", currentType) -- GuideHint 2026-11-15: บทสอนสัตว์เลี้ยง (NewPlayerGuide) ดูว่าเปิดแท็บตั๋วไหนอยู่
	for id, b in pairs(tabButtons) do
		b.BackgroundColor3 = (id == currentType) and COLOR_GOLD or COLOR_DISABLED
	end
	local isDupes = currentType == DUPES_TAB
	left.Visible, right.Visible, dupePanel.Visible = not isDupes, not isDupes, isDupes
	if isDupes then
		if info then renderDupes() end
		return
	end
	local t = currentTypeInfo()
	if not t then return end
	local count = player:GetAttribute("GachaTickets_" .. t.Id) or 0
	ticketLabel.Text = string.format(tr("%s %s: %d ใบ", "%s %s: %d tickets"), t.Icon, t.DisplayName, count)
	roll1.Text = tr("สุ่ม 1 ครั้ง\n(ใช้ 1 ใบ)", "Roll x1\n(1 ticket)")
	roll10.Text = string.format(tr("สุ่ม %d ครั้ง\n(ใช้ %d ใบ)", "Roll x%d\n(%d tickets)"), info.MaxRolls, info.MaxRolls)
	if t.Blocked then
		ticketSub.Text = tr("ตั๋วพรีเมียมเปิดให้ใช้ไม่ได้ในประเทศของคุณ", "Premium tickets are not available in your country")
		for _, b in ipairs({ buy1, buy10, roll1, roll10 }) do b.Visible = false end
		buyLabel.Visible, rollLabel.Visible = false, false
	else
		for _, b in ipairs({ buy1, buy10, roll1, roll10 }) do b.Visible = true end
		buyLabel.Visible, rollLabel.Visible = true, true
		if t.CoinPrice then
			local PlaytimeConfig = require(ReplicatedStorage:WaitForChild("PlaytimeConfig"))
			ticketSub.Text = string.format(tr("ซื้อด้วยเหรียญ หรือรับฟรีจากเวลาเล่น\n(%d นาทีได้ 1 ใบ วันละ %d ใบ)", "Buy with coins or earn free from playtime\n(1 ticket per %d min, %d tickets/day)"), PlaytimeConfig.TICKET_MINUTES, PlaytimeConfig.DAILY_TICKET_CAP)
			-- บทเรียนผู้เล่นใหม่: ใบแรกฟรี
			local freeFirst = t.Id == "Normal" and player:GetAttribute("FreeNormalTicket") == true
			buy1.Text = freeFirst and tr("1 ใบ\n✨ ฟรี!", "1 ticket\n✨ Free!") or (tr("1 ใบ", "1 ticket") .. "\n💰 " .. commas(t.CoinPrice))
			buy10.Text = tr("10 ใบ", "10 tickets") .. "\n💰 " .. commas(t.CoinPrice * 10)
		else
			ticketSub.Text = tr("ซื้อด้วย Robux · อัตราออกตัวหายากสูงกว่า", "Buy with Robux · Higher rare rates")
			local p1, p10
			for _, p in ipairs(info.Products) do
				if p.TicketType == t.Id and p.Amount == 1 then p1 = p end
				if p.TicketType == t.Id and p.Amount == 10 then p10 = p end
			end
			local price1 = p1 and productPrices[p1.ProductId]
			local price10 = p10 and productPrices[p10.ProductId]
			buy1.Text = tr("1 ใบ", "1 ticket") .. "\n" .. (price1 and ("R$ " .. price1) or "Robux")
			-- แพ็ก 10 ใบถูกกว่าซื้อทีละใบ: บอกว่าประหยัดกี่ % (คำนวณจากราคาจริงใน Dashboard)
			local save = (price1 and price10) and math.floor((1 - price10 / (price1 * 10)) * 100 + 0.5) or 0
			buy10.Text = tr("10 ใบ", "10 tickets") .. (save > 0 and (" (-" .. save .. "%)") or "") .. "\n" .. (price10 and ("R$ " .. price10) or "Robux")
		end
	end
	renderOdds(t)
end

player:GetAttributeChangedSignal("FreeNormalTicket"):Connect(function()
	if screenGui.Enabled and info then refresh() end
end)

local function buildTabs()
	for _, b in pairs(tabButtons) do b:Destroy() end
	tabButtons = {}
	for _, t in ipairs(info.Types) do
		local b = button(tabRow, t.Icon .. " " .. t.DisplayName, COLOR_DISABLED)
		b.Name = "Tab_" .. t.Id
		b.LayoutOrder = t.Order
		b.Size = UDim2.new(0, 170, 1, 0)
		b.Activated:Connect(function()
			currentType = t.Id
			setStatus("")
			refresh()
		end)
		tabButtons[t.Id] = b
	end
	local d = button(tabRow, tr("💠 เลเวล & เศษ", "💠 Levels & Shards"), COLOR_DISABLED)
	d.Name = "DupesTab"
	d.LayoutOrder = 99 -- อยู่ขวาสุดเสมอ
	d.Size = UDim2.new(0, 170, 1, 0)
	d.Activated:Connect(function()
		currentType = DUPES_TAB
		dupeStatus.Text = ""
		refresh()
	end)
	tabButtons[DUPES_TAB] = d
end

local function loadInfo()
	local ok, res = pcall(function() return gachaRequest:InvokeServer("info") end)
	if not ok or not res or not res.ok then
		setStatus(tr("โหลดข้อมูลตู้ไม่สำเร็จ ลองใหม่อีกครั้ง", "Failed to load machine data. Try again."))
		return false
	end
	info = res.info
	buildTabs()
	-- ราคา Robux จริงจาก Dashboard (โหลดครั้งเดียว)
	for _, p in ipairs(info.Products) do
		if not productPrices[p.ProductId] then
			task.spawn(function()
				local okP, pi = pcall(function() return MarketplaceService:GetProductInfo(p.ProductId, Enum.InfoType.Product) end)
				if okP and pi and pi.PriceInRobux then
					productPrices[p.ProductId] = pi.PriceInRobux
					if screenGui.Enabled then refresh() end
				end
			end)
		end
	end
	refresh()
	return true
end

-- ============ ปุ่ม ============
local function doRequest(action, count)
	if working then return end
	working = true
	if action == "roll" then setRolling(true) end
	setStatus(tr("กำลังดำเนินการ...", "Processing..."), true)
	local ok, res = pcall(function() return gachaRequest:InvokeServer(action, currentType, count) end)
	working = false
	if not ok or not res then
		setStatus(tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Connection failed. Try again."))
		if action == "roll" then setRolling(false) end
		return
	end
	if not res.ok then
		setStatus(res.message or tr("ทำรายการไม่สำเร็จ", "Action failed"))
		if action == "roll" then setRolling(false) end
		return
	end
	if action == "roll" and not res.results then setRolling(false) end
	setStatus(action == "buyCoins" and tr("ซื้อตั๋วสำเร็จ!", "Tickets purchased!") or "", true)
	if action == "roll" and res.results then
		local results = res.results
		playReveal(results, function() showResults(results) end)
		loadInfo() -- อัปเดต ✓ ตัวที่เพิ่งได้
	end
	refresh()
end

local function buyTickets(amount)
	local t = currentTypeInfo()
	if not t or t.Blocked then return end
	if t.CoinPrice then
		doRequest("buyCoins", amount)
	else
		for _, p in ipairs(info.Products) do
			if p.TicketType == t.Id and p.Amount == amount then
				MarketplaceService:PromptProductPurchase(player, p.ProductId)
				return
			end
		end
		setStatus(tr("ยังไม่มีสินค้านี้", "Product not available"))
	end
end

doPetAction = function(action, petId, count)
	if working then return end
	working = true
	dupeStatus.TextColor3 = Color3.fromRGB(40, 150, 60)
	dupeStatus.Text = tr("กำลังดำเนินการ...", "Processing...")
	local ok, res = pcall(function() return gachaRequest:InvokeServer(action, petId, count) end)
	working = false
	if not ok or not res then
		dupeStatus.TextColor3 = Color3.fromRGB(200, 80, 80)
		dupeStatus.Text = tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Connection failed. Try again.")
		return
	end
	dupeStatus.TextColor3 = res.ok and Color3.fromRGB(40, 150, 60) or Color3.fromRGB(200, 80, 80)
	dupeStatus.Text = res.message or (res.ok and tr("สำเร็จ!", "Success!") or tr("ทำรายการไม่สำเร็จ", "Action failed"))
	loadInfo() -- อัปเดตสัตว์ที่มี/เลเวล
end

buy1.Activated:Connect(function() buyTickets(1) end)
buy10.Activated:Connect(function() buyTickets(10) end)
roll1.Activated:Connect(function() doRequest("roll", 1) end)
roll10.Activated:Connect(function() doRequest("roll", info and info.MaxRolls or 10) end)

-- 2026-10-24 บทเรียนผู้เล่นใหม่ ▶ AUTO (TutorialGui) สั่งซื้อตั๋วธรรมดา 1 ใบ / สุ่ม 1 ครั้ง ผ่านทางเดียวกับปุ่ม (ได้แอนิเมชันเปิดตัว + หน้าผลสุ่มเหมือนกดเอง)
-- ใบแรกฟรีตาม FreeNormalTicket ที่ TutorialService ตั้ง ไม่มีสิทธิ์ฟรี = ซื้อด้วยเหรียญตามราคาปกติ (เซิร์ฟเวอร์คิดเอง) · ทำเฉพาะตอนหน้าตู้เปิดอยู่
local tutorialAuto = Instance.new("BindableEvent")
tutorialAuto.Name = "TutorialAuto"
tutorialAuto.Parent = screenGui
tutorialAuto.Event:Connect(function(action)
	if not screenGui.Enabled or working then return end
	if currentType ~= "Normal" then
		currentType = "Normal"
		refresh()
	end
	if action == "buy1" then
		buyTickets(1)
	elseif action == "roll1" then
		doRequest("roll", 1)
	end
end)

player.AttributeChanged:Connect(function(name)
	if not screenGui.Enabled then return end
	if string.sub(name, 1, 13) == "GachaTickets_" then
		refresh()
	elseif currentType == DUPES_TAB and (name == "PetShards" or string.sub(name, 1, 9) == "PetLevel_" or string.sub(name, 1, 9) == "PetDupes_") then
		refresh()
	end
end)

gachaOpen.OnClientEvent:Connect(function()
	if rolling then screenGui.Enabled = true return end -- กด E ซ้ำระหว่างสุ่ม: ไม่ล้างหน้าผล
	resultOverlay.Visible = false
	working = false
	setStatus("")
	screenGui.Enabled = true
	loadInfo()
end)

-- ============ จอย ============
-- เปิดตู้ด้วยจอย = เลือกปุ่ม "สุ่ม 1 ครั้ง" ให้เลย · A กด · LB/RB เปลี่ยนแท็บ · B ปิด (ระหว่างแคปซูลแตก A/B = ข้าม, หน้าผล B = ตกลง)
-- แท็บ/แถวแลกเศษถูกสร้างใหม่หลังสุ่ม/แลก ปุ่มที่เลือกอยู่จะถูกลบ จึงจำชื่อไว้แล้วเลือกปุ่มชื่อเดิมคืน
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function usingGamepad() return GAMEPAD_INPUTS[UserInputService:GetLastInputType()] == true end
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(main)
end

-- ปุ่มหลักของแท็บที่เปิดอยู่
local function defaultButton()
	if resultOverlay.Visible then return okButton end
	if currentType == DUPES_TAB then
		local best
		for _, row in ipairs(dupeList:GetChildren()) do
			local b = row:IsA("Frame") and row:FindFirstChildWhichIsA("TextButton")
			if b and (not best or row.LayoutOrder < best.Parent.LayoutOrder) then best = b end
		end
		return best or tabButtons[DUPES_TAB]
	end
	if roll1.Visible then return roll1 end
	return tabButtons[currentType] or closeButton
end

-- เลื่อนรายการให้เห็นปุ่มที่เลือก (CanvasPosition เป็นหน่วยก่อนย่อด้วย UIScale)
local function scrollIntoView(obj)
	local scroller = obj:FindFirstAncestorWhichIsA("ScrollingFrame")
	if not scroller then return end
	local scale = uiScale.Scale
	local top = (obj.AbsolutePosition.Y - scroller.AbsolutePosition.Y) / scale
	local bottom = top + obj.AbsoluteSize.Y / scale
	local view = scroller.AbsoluteSize.Y / scale
	if top < 0 then
		scroller.CanvasPosition = Vector2.new(0, math.max(0, scroller.CanvasPosition.Y + top - 6))
	elseif bottom > view then
		scroller.CanvasPosition = Vector2.new(0, scroller.CanvasPosition.Y + bottom - view + 6)
	end
end

local lastName = nil
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(main) then
		lastName = sel.Name
		scrollIntoView(sel)
	end
end)

local function selectTarget(target)
	if target and screenGui.Enabled then GuiService.SelectedObject = target end
end

-- LB/RB: แท็บก่อนหน้า/ถัดไป (เรียงตามลำดับบนจอ)
local function cycleTab(step)
	local list = {}
	for id, b in pairs(tabButtons) do table.insert(list, { id = id, order = b.LayoutOrder }) end
	table.sort(list, function(a, b) return a.order < b.order end)
	if #list == 0 then return end
	local index = 1
	for i, t in ipairs(list) do if t.id == currentType then index = i end end
	index = (index - 1 + step) % #list + 1
	currentType = list[index].id
	setStatus("")
	dupeStatus.Text = ""
	refresh()
	selectTarget(defaultButton())
end

-- ผลลัพธ์ขึ้น = เลือกปุ่มตกลง / กดตกลง = กลับไปปุ่มสุ่ม
resultOverlay:GetPropertyChangedSignal("Visible"):Connect(function()
	if not usingGamepad() or not screenGui.Enabled then return end
	if resultOverlay.Visible then
		selectTarget(okButton)
	elseif selectionInside() == false or GuiService.SelectedObject == okButton then
		selectTarget(defaultButton())
	end
end)
-- แคปซูลกำลังแตก: ปล่อยการเลือกไว้ก่อน (กด A จะได้ไม่ไปโดนปุ่มสุ่มข้างใต้)
revealLayer:GetPropertyChangedSignal("Visible"):Connect(function()
	if revealLayer.Visible and selectionInside() then GuiService.SelectedObject = nil end
end)

gachaOpen.OnClientEvent:Connect(function()
	-- loadInfo ใน handler หลักรอเซิร์ฟเวอร์อยู่ รอให้ปุ่มพร้อมก่อนค่อยเลือก
	task.delay(0.3, function()
		if screenGui.Enabled and usingGamepad() and not selectionInside() then selectTarget(defaultButton()) end
	end)
end)

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screenGui.Enabled then
		if selectionInside() then GuiService.SelectedObject = nil end
		lastName = nil
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if not screenGui.Enabled then return end
	local key = input.KeyCode
	if revealLayer.Visible then
		if (key == Enum.KeyCode.ButtonA or key == Enum.KeyCode.ButtonB) and skipReveal then skipReveal() end
		return
	end
	if key == Enum.KeyCode.ButtonB then
		if resultOverlay.Visible then
			resultOverlay.Visible = false
			working = false
		elseif not rolling then
			screenGui.Enabled = false
		end
	elseif (key == Enum.KeyCode.ButtonL1 or key == Enum.KeyCode.ButtonR1) and not resultOverlay.Visible and selectionInside() then
		cycleTab(key == Enum.KeyCode.ButtonL1 and -1 or 1)
	end
end)

-- ปุ่มที่เลือกอยู่ถูกลบ (แท็บ/แถวสร้างใหม่) หรือถูกซ่อน (สลับแท็บ) = เลือกปุ่มชื่อเดิมคืน / ปุ่มหลักของแท็บ
RunService.Heartbeat:Connect(function()
	if not (screenGui.Enabled and lastName and usingGamepad()) or revealLayer.Visible then return end
	local sel = GuiService.SelectedObject
	if sel ~= nil and not sel:IsDescendantOf(main) then
		lastName = nil -- ย้ายไปเลือกที่อื่นเอง ไม่ดึงกลับ
		return
	end
	local lost = sel == nil or not sel.Visible
	if sel and not lost then
		local node = sel.Parent
		while node and node ~= main do
			if node:IsA("GuiObject") and not node.Visible then lost = true break end
			node = node.Parent
		end
	end
	if not lost then return end
	local target = main:FindFirstChild(lastName, true)
	local ok = target and target:IsA("GuiButton") and target.Visible
	if ok then
		local node = target.Parent
		while node and node ~= main do
			if node:IsA("GuiObject") and not node.Visible then ok = false break end
			node = node.Parent
		end
	end
	selectTarget(ok and target or defaultButton())
end)

-- บอกปุ่มจอยใต้หัวข้อ (เฉพาะตอนใช้จอย)
local padHint = label(main, tr("LB/RB เปลี่ยนแท็บ · A กด · B ปิด", "LB/RB tabs · A select · B close"), 12, COLOR_SUB, true)
padHint.AnchorPoint = Vector2.new(1, 0)
padHint.Size = UDim2.new(0, 240, 0, 20)
padHint.Position = UDim2.new(1, -52, 0, 17)
padHint.TextXAlignment = Enum.TextXAlignment.Right
local function updatePadHint() padHint.Visible = usingGamepad() end
UserInputService.LastInputTypeChanged:Connect(updatePadHint)
updatePadHint()

-- กรอบทองตอนเลือก (เหมือนหน้าต่างอื่น) ติดให้ทุกปุ่มในหน้าต่าง (รวมปุ่มที่สร้างใหม่ทีหลัง)
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
