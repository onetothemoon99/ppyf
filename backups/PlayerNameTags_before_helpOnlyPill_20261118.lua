-- BACKUP of ServerScriptService.PlayerNameTags (Script) before making only HelpTitle a pill (VIP/crop back to plain text), 2026-11-18
-- Restore: paste everything below the "-- ==== SOURCE ====" line into the script's Source in Studio.
-- ==== SOURCE ====
-- PlayerNameTags: ป้ายเหนือหัวผู้เล่นทุกคน: ธงประเทศ + ไอคอนอุปกรณ์ (มือถือ/คอม/จอย) + ชื่อแสดง
-- สร้างฝั่งเซิร์ฟเวอร์ ทุกคนเห็นเหมือนกัน ซ่อนชื่อเดิมของ Roblox ไม่ให้ขึ้นซ้อน 2 ชื่อ
-- อุปกรณ์มาจาก DeviceReporter (ฝั่งผู้เล่น) ส่งมาทาง RemoteEvent "ReportDevice"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local CollectionService = game:GetService("CollectionService")

local VipConfig = require(ReplicatedStorage:WaitForChild("VipConfig"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local reportDevice = remoteEvents:FindFirstChild("ReportDevice")
if not reportDevice then
	reportDevice = Instance.new("RemoteEvent")
	reportDevice.Name = "ReportDevice"
	reportDevice.Parent = remoteEvents
end

-- ผู้เล่นกำลังพิมพ์แชท: TypingReporter (ฝั่งผู้เล่น) ส่ง true/false มาทาง "ReportTyping" เซิร์ฟเวอร์เก็บใน Attribute IsTyping
local reportTyping = remoteEvents:FindFirstChild("ReportTyping")
if not reportTyping then
	reportTyping = Instance.new("RemoteEvent")
	reportTyping.Name = "ReportTyping"
	reportTyping.Parent = remoteEvents
end
local TYPING_TIMEOUT = 20 -- ไม่มีส่ง true ใหม่เกินนี้ ถือว่าหยุดพิมพ์แล้ว กันป้ายค้าง (ฝั่งผู้เล่นส่งซ้ำทุก 8 วิระหว่างพิมพ์)
local typingToken = {}

local DEVICE_ICON = {
	mobile = "📱",
	pc = "💻",
	console = "🎮",
}

local TAG_NAME = "PlayerNameTag"
local TAG_OFFSET = Vector3.new(0, 1.9, 0) -- ขอบล่างของป้าย (ป้ายโตขึ้นด้านบนเมื่อมีฉายา VIP ชื่อไม่ขยับ)
local TAG_MAX_DISTANCE = 90

-- รหัสประเทศ 2 ตัวอักษร (เช่น "TH") -> อีโมจิธง (ตัวอักษร Regional Indicator 2 ตัวต่อกัน)
local function countryToFlag(code)
	if type(code) ~= "string" or #code ~= 2 then return "" end
	code = code:upper()
	local a, b = code:byte(1, 2)
	if a < 65 or a > 90 or b < 65 or b > 90 then return "" end
	return utf8.char(0x1F1E6 + a - 65, 0x1F1E6 + b - 65)
end

local function buildTagText(player)
	local parts = {}
	local flag = countryToFlag(player:GetAttribute("CountryCode"))
	if flag ~= "" then table.insert(parts, flag) end
	local icon = DEVICE_ICON[player:GetAttribute("Device") or ""]
	if icon then table.insert(parts, icon) end
	return table.concat(parts, " ")
end

-- ป้าย VIP ไล่สีชมพู (ตอนสร้างป้ายและตอนเปลี่ยนกลับจากป้ายสุลต่าน)
local VIP_BADGE_PINK = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 228, 242)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 125, 190)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(232, 62, 145)),
})

-- พื้นหลังแคปซูลของแถวฉายา (2026-11-18 ผู้ใช้เลือกแบบ B): Frame "Bg" อยู่ใต้ตัวหนังสือ ไล่สีตามระดับฉายา + ขอบสีเด่น
-- ไม่ใช้ Highlight (เซิร์ฟเวอร์ชน 255 อยู่แล้ว) ไม่มีอะไรวิ่งทุกเฟรม ป้ายกว้างตามข้อความ (สูงสุด PILL_MAX_W + ขอบข้างละ PILL_PAD)
local OrchardConfig = require(ReplicatedStorage:WaitForChild("OrchardConfig"))
local PILL_PAD = 10
local PILL_MAX_W = 212
local function seq(a, b) return ColorSequence.new(a, b) end
local TITLE_STYLE = {
	kind = { bg = seq(Color3.fromRGB(16, 62, 36), Color3.fromRGB(30, 100, 58)), stroke = Color3.fromRGB(120, 235, 160), text = Color3.fromRGB(190, 255, 210) },
	guardian = { bg = seq(Color3.fromRGB(18, 70, 34), Color3.fromRGB(92, 86, 22)), stroke = Color3.fromRGB(235, 205, 95), text = Color3.fromRGB(220, 255, 180) },
	angel = { bg = seq(Color3.fromRGB(34, 64, 130), Color3.fromRGB(124, 90, 26)), stroke = Color3.fromRGB(255, 218, 110), text = Color3.fromRGB(255, 247, 210) },
	crop = { bg = seq(Color3.fromRGB(80, 56, 24), Color3.fromRGB(40, 84, 30)), stroke = Color3.fromRGB(190, 230, 120), text = Color3.fromRGB(205, 248, 145) },
	rainbow = { bg = seq(Color3.fromRGB(56, 24, 86), Color3.fromRGB(20, 56, 90)), stroke = Color3.fromRGB(245, 245, 255) },
	sultan = { bg = seq(Color3.fromRGB(64, 18, 86), Color3.fromRGB(100, 66, 10)), stroke = Color3.fromRGB(255, 212, 90) },
}
-- ฉายาตู้แลกน้ำใจ: Id → ระดับ (ฉายาใหม่ใส่ TitleStyle = "kind"/"guardian"/"angel" ใน OrchardConfig ได้ ไม่ใส่ = เขียว)
local HELP_TIER = { TitleKind = "kind", TitleGuardian = "guardian", TitleAngel = "angel", TitleAngelBoy = "angel" }
local helpStyleByText = {}
do
	local seen = {}
	local function walk(t)
		if seen[t] then return end
		seen[t] = true
		if t.Grant == "title" and type(t.Title) == "string" then
			local st = TITLE_STYLE[t.TitleStyle or HELP_TIER[t.Id] or "kind"] or TITLE_STYLE.kind
			helpStyleByText[t.Title] = st
			if type(t.TitleEn) == "string" then helpStyleByText[t.TitleEn] = st end
		end
		for _, v in pairs(t) do
			if type(v) == "table" then walk(v) end
		end
	end
	walk(OrchardConfig)
end

-- สีพื้นของฉายา VIP สีเดียว = สีที่เลือกแบบเข้ม ขอบ = สีที่เลือก
local function vipPlainStyle(c)
	local black = Color3.new(0, 0, 0)
	return { bg = seq(c:Lerp(black, 0.8), c:Lerp(black, 0.62)), stroke = c }
end

local function applyPill(label, style)
	local bg = label:FindFirstChild("Bg")
	if not bg or not style then return end
	local grad = bg:FindFirstChildOfClass("UIGradient")
	if grad then grad.Color = style.bg end
	local stroke = bg:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = style.stroke end
end

local function updateTag(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local tag = head and head:FindFirstChild(TAG_NAME)
	if not tag then return end
	tag.Typing.Visible = player:GetAttribute("IsTyping") == true
	-- ธง + อุปกรณ์ ต่อท้ายชื่อในบรรทัดเดียวกัน (2026-11-10 ผู้ใช้สั่ง) แถว Icons เดิมเว้นว่างไว้ (NameTagPrefs ซ่อนแถวที่ไม่มีข้อความเอง)
	local iconText = buildTagText(player)
	tag.Icons.Text = ""
	tag.Icons.Visible = false

	-- VIP / สุลต่าน: ป้ายเหนือชื่อ + ชื่อสีทอง + ฉายาใต้ชื่อ (ข้อความกรองแล้วจาก VipService)
	-- สุลต่าน (แพ็กสุลต่าน) ได้ป้าย "สุลต่าน" ไล่สีทอง-ม่วงมีประกายวิ่ง (แท็ก "VipShimmer" ฝั่งผู้เล่นขยับ) แทนป้าย VIP
	local isSultan = player:GetAttribute("IsSultan") == true
	local isVip = isSultan or player:GetAttribute("IsVip") == true
	local badge = tag.VipBadge
	badge.Visible = isVip
	local crown = badge:FindFirstChild("Crown")
	if crown then crown.Visible = isSultan end
	for _, nm in ipairs({ "SparkleL", "SparkleR" }) do
		local sp = badge:FindFirstChild(nm)
		if sp then sp.Visible = isSultan end
	end
	local vipText = badge:FindFirstChild("VipText")
	local badgeGrad = vipText and vipText:FindFirstChildOfClass("UIGradient")
	if vipText and badgeGrad then
		if isSultan then
			vipText.Text = VipConfig.SULTAN_TEXT
			vipText.Font = Enum.Font.FredokaOne
			vipText.TextSize = 26
			vipText.TextStrokeColor3 = Color3.fromRGB(70, 15, 90)
			badgeGrad.Color = VipConfig.SULTAN_BADGE
			badgeGrad.Rotation = 0
			if not CollectionService:HasTag(badgeGrad, "VipShimmer") then CollectionService:AddTag(badgeGrad, "VipShimmer") end
		else
			vipText.Text = "VIP"
			vipText.Font = Enum.Font.FredokaOne
			vipText.TextSize = 27
			vipText.TextStrokeColor3 = Color3.fromRGB(125, 20, 75)
			badgeGrad.Color = VIP_BADGE_PINK
			badgeGrad.Rotation = 90
			if CollectionService:HasTag(badgeGrad, "VipShimmer") then
				CollectionService:RemoveTag(badgeGrad, "VipShimmer")
				badgeGrad.Offset = Vector2.zero
			end
		end
	end
	tag.PlayerName.Text = iconText ~= "" and (player.DisplayName .. " " .. iconText) or player.DisplayName
	tag.PlayerName.TextColor3 = isVip and VipConfig.NAME_COLOR or Color3.fromRGB(255, 255, 255)

	local title = isVip and (player:GetAttribute("VipTitle") or "") or ""
	local titleLabel = tag.Title
	titleLabel.Visible = title ~= ""
	titleLabel.Text = title
	local colorDef = VipConfig.GetColor(player:GetAttribute("VipTitleColor")) or VipConfig.GetColor(VipConfig.DEFAULT_COLOR)
	if colorDef.sultan and not isSultan then colorDef = VipConfig.GetColor(VipConfig.DEFAULT_COLOR) end -- หมดสิทธิ์สุลต่าน = สีปกติ
	local rainbow = titleLabel:FindFirstChild("Rainbow")
	local shimmer = titleLabel:FindFirstChild("Shimmer")
	if colorDef.rainbow then
		if shimmer then shimmer:Destroy() end
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		if not rainbow then
			rainbow = Instance.new("UIGradient")
			rainbow.Name = "Rainbow"
			rainbow.Color = VipConfig.RAINBOW
			rainbow.Parent = titleLabel
			CollectionService:AddTag(rainbow, "VipRainbow") -- VipGui ทำให้สีเลื่อนไหลฝั่งผู้เล่น
		end
	elseif colorDef.gradient then
		if rainbow then rainbow:Destroy() end
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		if not shimmer then
			shimmer = Instance.new("UIGradient")
			shimmer.Name = "Shimmer"
			shimmer.Parent = titleLabel
			CollectionService:AddTag(shimmer, "VipShimmer")
		end
		shimmer.Color = colorDef.gradient
	else
		if rainbow then rainbow:Destroy() end
		if shimmer then shimmer:Destroy() end
		titleLabel.TextColor3 = colorDef.color
	end
	if colorDef.rainbow then
		applyPill(titleLabel, TITLE_STYLE.rainbow)
	elseif colorDef.gradient then
		applyPill(titleLabel, TITLE_STYLE.sultan)
	else
		applyPill(titleLabel, vipPlainStyle(colorDef.color))
	end

	-- ฉายาจากสมุดพืช (Attribute CropTitle ตั้งโดย CropBook): บรรทัดของตัวเองใต้ฉายา VIP สีเขียวอ่อน
	-- (2026-10-31 ผู้ใช้ขอเพิ่มอีกบรรทัด เดิมใช้บรรทัดฉายา VIP ร่วมกัน = มีฉายา VIP แล้วฉายาพืชไม่ขึ้น)
	local cropTitle = player:GetAttribute("CropTitle")
	local cropLabel = tag:FindFirstChild("CropTitle")
	if cropLabel then
		local show = type(cropTitle) == "string" and cropTitle ~= ""
		cropLabel.Visible = show
		cropLabel.Text = show and ("🌾 " .. cropTitle) or ""
		cropLabel.TextColor3 = TITLE_STYLE.crop.text
		applyPill(cropLabel, TITLE_STYLE.crop)
	end

	-- ฉายาจากตู้แลกน้ำใจ (Attribute HelpTitle ตั้งโดย OrchardService, 2026-11-03): บรรทัดของตัวเอง สีเขียวอ่อน (ข้อความมีอิโมจินำหน้าอยู่แล้ว)
	local helpTitle = player:GetAttribute("HelpTitle")
	local helpLabel = tag:FindFirstChild("HelpTitle")
	if helpLabel then
		local show = type(helpTitle) == "string" and helpTitle ~= ""
		helpLabel.Visible = show
		helpLabel.Text = show and helpTitle or ""
		local st = (show and helpStyleByText[helpTitle]) or TITLE_STYLE.kind
		helpLabel.TextColor3 = st.text
		applyPill(helpLabel, st)
	end
end

local function textRow(parent, name, order, height, font, size)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height)
	l.BackgroundTransparency = 1
	l.Font = font
	l.TextSize = size
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	l.TextStrokeTransparency = 0.4
	l.Text = ""
	l.Parent = parent
	return l
end

-- แถวฉายาแบบแคปซูล: ตัวหนังสือกว้างตามข้อความ (ยาวเกิน = ตัด …) + Frame "Bg" กว้างกว่าข้างละ PILL_PAD อยู่ใต้ตัวหนังสือ
-- (ป้ายใช้ ZIndexBehavior Global: Bg ZIndex 2 < ตัวหนังสือ 3) · สูงเผื่อสระบน/ล่างภาษาไทย
local function pillRow(parent, name, order, height, font, size)
	local l = textRow(parent, name, order, height, font, size)
	l.Size = UDim2.new(0, 0, 0, height)
	l.AutomaticSize = Enum.AutomaticSize.X
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.TextStrokeTransparency = 0.55
	l.ZIndex = 3
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(PILL_MAX_W, height)
	cap.Parent = l
	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.new(1, PILL_PAD * 2, 1, 0)
	bg.Position = UDim2.new(0, -PILL_PAD, 0, 0)
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.BackgroundTransparency = 0.18
	bg.BorderSizePixel = 0
	bg.ZIndex = 2
	bg.Parent = l
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = bg
	local grad = Instance.new("UIGradient")
	grad.Color = TITLE_STYLE.kind.bg
	grad.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1.5
	stroke.Transparency = 0.15
	stroke.Color = TITLE_STYLE.kind.stroke
	stroke.Parent = bg
	return l
end

local function createTag(player, character)
	local head = character:WaitForChild("Head", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not head or not humanoid then return end

	-- ซ่อนชื่อแบบเดิมของ Roblox ใช้ป้ายใหม่แทน
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local old = head:FindFirstChild(TAG_NAME)
	if old then old:Destroy() end

	local tag = Instance.new("BillboardGui")
	tag.Name = TAG_NAME
	tag.Size = UDim2.new(0, 240, 0, 145) -- เดิม 100 → 120 (บรรทัดฉายาสมุดพืช 2026-10-31) → 145 (แถวฉายาแคปซูลสูงขึ้น 2026-11-18)
	tag.ZIndexBehavior = Enum.ZIndexBehavior.Global -- พื้นแคปซูล (ลูก) ต้องอยู่ใต้ตัวหนังสือ (พ่อ)
	tag.SizeOffset = Vector2.new(0, 0.5) -- ยึดขอบล่างของป้ายไว้ที่ TAG_OFFSET
	tag.StudsOffset = TAG_OFFSET
	tag.MaxDistance = TAG_MAX_DISTANCE
	tag.LightInfluence = 0
	tag.ResetOnSpawn = false
	tag.Parent = head

	-- เรียงบนลงล่าง ชิดขอบล่าง: ธง+อุปกรณ์ / 👑 VIP / ชื่อ / ฉายา (แถวที่ซ่อนไม่กินที่)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 3)
	list.Parent = tag

	-- "กำลังพิมพ์..." อยู่บนสุด (ซ่อนไว้จนกว่าจะพิมพ์)
	local typing = textRow(tag, "Typing", 0, 20, Enum.Font.GothamBold, 15)
	typing.Text = "กำลังพิมพ์..."
	typing.TextColor3 = Color3.fromRGB(255, 240, 160)
	typing.Visible = false

	local icons = textRow(tag, "Icons", 1, 20, Enum.Font.GothamBold, 18)
	icons.TextStrokeTransparency = 1

	-- ป้าย VIP: ✨ 👑 VIP ✨ (ตัวอักษรไล่สีชมพู)
	local badge = Instance.new("Frame")
	badge.Name = "VipBadge"
	badge.LayoutOrder = 2
	badge.Size = UDim2.new(0, 0, 0, 30)
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.BackgroundTransparency = 1
	badge.Visible = false
	badge.Parent = tag
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Padding = UDim.new(0, 3)
	row.Parent = badge
	local function badgePart(text, order, font, size)
		local l = Instance.new("TextLabel")
		l.LayoutOrder = order
		l.Size = UDim2.new(0, 0, 1, 0)
		l.AutomaticSize = Enum.AutomaticSize.X
		l.BackgroundTransparency = 1
		l.Font = font
		l.TextSize = size
		l.TextColor3 = Color3.fromRGB(255, 255, 255)
		l.Text = text
		l.Parent = badge
		return l
	end
	local sparkleL = badgePart("✨", 1, Enum.Font.GothamBold, 13)
	sparkleL.Name = "SparkleL" -- ประกาย/มงกุฎเป็นของสุลต่านเท่านั้น VIP เหลือแค่คำว่า VIP (ผู้เล่นขอ 2026-10-02)
	sparkleL.Visible = false
	local crownPart = badgePart(VipConfig.CROWN, 2, Enum.Font.GothamBold, 22)
	crownPart.Name = "Crown" -- มงกุฎแสดงเฉพาะสุลต่าน (VIP ไม่มีมงกุฎแล้ว ผู้เล่นขอ 2026-10-02) updateTag เปิด/ปิด
	crownPart.Visible = false
	local vipText = badgePart("VIP", 3, Enum.Font.FredokaOne, 27)
	vipText.Name = "VipText"
	vipText.TextStrokeColor3 = Color3.fromRGB(125, 20, 75)
	vipText.TextStrokeTransparency = 0
	local gold = Instance.new("UIGradient")
	gold.Rotation = 90
	gold.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 228, 242)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 125, 190)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(232, 62, 145)),
	})
	gold.Parent = vipText
	local sparkleR = badgePart("✨", 4, Enum.Font.GothamBold, 13)
	sparkleR.Name = "SparkleR"
	sparkleR.Visible = false

	-- ชื่อแสดง
	local nameLabel = textRow(tag, "PlayerName", 3, 22, Enum.Font.GothamBold, 17)
	nameLabel.Text = player.DisplayName

	-- ฉายา VIP ใต้ชื่อ (ซ่อนไว้ถ้าไม่มี)
	local titleLabel = pillRow(tag, "Title", 4, 24, Enum.Font.GothamBold, 15)
	titleLabel.Visible = false

	-- ฉายาสมุดพืช บรรทัดล่างสุด (ซ่อนไว้ถ้าไม่ได้เลือก) 2026-10-31
	local cropTitleLabel = pillRow(tag, "CropTitle", 5, 22, Enum.Font.GothamBold, 14)
	cropTitleLabel.TextColor3 = TITLE_STYLE.crop.text
	cropTitleLabel.Visible = false

	-- ฉายาตู้แลกน้ำใจ บรรทัดล่างสุด (ซ่อนไว้ถ้าไม่ได้ใส่) 2026-11-03
	local helpTitleLabel = pillRow(tag, "HelpTitle", 6, 22, Enum.Font.GothamBold, 14)
	helpTitleLabel.TextColor3 = TITLE_STYLE.kind.text
	helpTitleLabel.Visible = false

	updateTag(player)
end

local function setupPlayer(player)
	-- ประเทศของผู้เล่น (หาไม่ได้ = ไม่แสดงธง)
	task.spawn(function()
		local ok, code = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(player)
		end)
		if ok and type(code) == "string" then
			player:SetAttribute("CountryCode", code)
		end
	end)

	player:GetAttributeChangedSignal("IsTyping"):Connect(function() updateTag(player) end)
	player:GetAttributeChangedSignal("CountryCode"):Connect(function() updateTag(player) end)
	player:GetAttributeChangedSignal("Device"):Connect(function() updateTag(player) end)
	player:GetPropertyChangedSignal("DisplayName"):Connect(function() updateTag(player) end)
	for _, attr in ipairs({ "IsVip", "IsSultan", "VipTitle", "VipTitleColor", "CropTitle", "HelpTitle" }) do
		player:GetAttributeChangedSignal(attr):Connect(function() updateTag(player) end)
	end

	player.CharacterAdded:Connect(function(character)
		createTag(player, character)
	end)
	if player.Character then
		task.spawn(createTag, player, player.Character)
	end
end

-- ฝั่งผู้เล่นบอกอุปกรณ์มา (รับเฉพาะค่าที่รู้จัก)
reportDevice.OnServerEvent:Connect(function(player, device)
	if DEVICE_ICON[device] then
		player:SetAttribute("Device", device)
	end
end)

local lastTypingReport = {}
reportTyping.OnServerEvent:Connect(function(player, typing)
	if type(typing) ~= "boolean" then return end
	local now = os.clock()
	if typing and now - (lastTypingReport[player] or 0) < 0.2 then return end -- กันสแปม (false ผ่านเสมอ จะได้ไม่ค้าง)
	lastTypingReport[player] = now

	player:SetAttribute("IsTyping", typing or nil)
	local token = (typingToken[player] or 0) + 1
	typingToken[player] = token
	if typing then
		task.delay(TYPING_TIMEOUT, function()
			if typingToken[player] == token and player.Parent then player:SetAttribute("IsTyping", nil) end
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTypingReport[player] = nil
	typingToken[player] = nil
end)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
