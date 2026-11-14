-- OrchardGui: สวนผลไม้ยืนต้น ฝั่งผู้เล่น (2026-10-26) ค่าดู ReplicatedStorage.OrchardConfig · เซิร์ฟเวอร์ดู ServerScriptService.Orchard.OrchardService · สรุป ORCHARD.md
-- 1) หน้าต่างเลือกเมล็ด (กด "ปลูกต้นไม้" ที่หลุมว่าง -> OrchardOpen "plant") ปุ่มตามเมล็ดที่มีในกระเป๋า
-- 2) หน้าต่างต้นไม้ (กด "ดูต้นไม้" -> OrchardOpen "tree") ขั้น/เวลา/ผล + ขุดทิ้ง (กด 2 ครั้ง)
-- 3) ป้ายเหนือต้นทุกต้น (ชื่อ · ขั้น · นับถอยหลัง · เจ้าของ) สร้างบนเครื่องเรา ตามภาษาของเรา
-- 4) ปุ่ม HolePrompt: ล็อกของเรา = เห็น · ล็อกว่าง = เห็นเฉพาะตอนเรายังไม่มีล็อก · ล็อกคนอื่น = ซ่อน (เซิร์ฟเช็กอีกที) + แปลอังกฤษ
-- 5) ปุ่ม "ขโมย" (เฟส 3) · 6) เฟส 4: เจ้าของเห็นกรอบแดง + ป้าย 🚨 เหนือหัวคนขโมย (OrchardAlert) + ปุ่ม "ตบ" (SlapPrompt เห็นเฉพาะเจ้าของ) · โดนตบ = ล้ม
-- จอย: เปิดแล้วเลือกปุ่มแรก · A กด · B ปิด · ตบ = Y (คีย์บอร์ด F)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("OrchardConfig"))
print(string.format("[Orchard] client: Enabled=%s IsStudio=%s", tostring(Config.Enabled), tostring(RunService:IsStudio())))
-- ทดสอบเป็นทีม: บอกเซิร์ฟว่าเราเข้าจาก Studio (เซิร์ฟเปิดสวนให้เฉพาะคนใน OrchardConfig.TESTERS) 2026-10-30
if RunService:IsStudio() then
	task.spawn(function()
		local hello = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("OrchardStudioHello", 30)
		if hello then hello:FireServer() end
	end)
end
if not Config.Enabled then return end
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestRemote = remoteEvents:WaitForChild("OrchardRequest")
local syncRemote = remoteEvents:WaitForChild("OrchardSync")
local openRemote = remoteEvents:WaitForChild("OrchardOpen")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local function lang() return Localization.GetLanguage(player) end
local function tr(th, en) return Localization.Pick(lang(), th, en) end

-- เวลาเดียวกับเซิร์ฟ (os.time) + เวลาเร่งทดสอบใน Studio
local function serverNow()
	local skip = RunService:IsStudio() and tonumber(workspace:GetAttribute("DevOrchardTimeSkip")) or 0
	return workspace:GetServerTimeNow() + skip
end

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h, m, s = seconds // 3600, (seconds % 3600) // 60, seconds % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

local COLOR_BG = Color3.fromRGB(255, 250, 240)
local COLOR_TEXT = Color3.fromRGB(70, 50, 30)
local COLOR_SUB = Color3.fromRGB(125, 100, 70)
local COLOR_BORDER = Color3.fromRGB(120, 150, 70)
local COLOR_GO = Color3.fromRGB(0, 176, 111)
local COLOR_GOLD = Color3.fromRGB(235, 160, 30)
local COLOR_GREY = Color3.fromRGB(150, 150, 160)
local COLOR_RED = Color3.fromRGB(220, 90, 80)

local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = obj return c end
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
local function button(parent, name, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = 17
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Selectable = true
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	return b
end

-- ============ หน้าต่างเล็ก (เลือกเมล็ด / ต้นไม้) ============
local gui = Instance.new("ScreenGui")
gui.Name = "OrchardGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = playerGui

local WIDTH, HEIGHT = 400, 270
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(WIDTH, HEIGHT)
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
	local st = Instance.new("UIStroke") st.Color = COLOR_BORDER st.Thickness = 3 st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border st.Parent = main
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

local title = label(main, "", 20, COLOR_TEXT, true)
title.Size = UDim2.new(1, -70, 0, 30)
title.Position = UDim2.fromOffset(16, 10)
local subtitle = label(main, "", 13, COLOR_SUB, false)
subtitle.Size = UDim2.new(1, -32, 0, 36)
subtitle.Position = UDim2.fromOffset(16, 40)
subtitle.TextYAlignment = Enum.TextYAlignment.Top

local closeButton = button(main, "Close", Color3.fromRGB(240, 120, 110))
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(34, 34)
closeButton.Text = "X"
closeButton.TextSize = 16
corner(closeButton, 17)

local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(16, 82)
body.Size = UDim2.new(1, -32, 1, -128)
body.Parent = main
do
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = body
end

local kinds = Config.SortedKinds()
local plantButtons = {}
for k, kind in ipairs(kinds) do
	local b = button(body, "Plant_" .. kind, COLOR_GO)
	b.LayoutOrder = k
	b.Size = UDim2.new(1, 0, 0, 46)
	plantButtons[kind] = b
end
local treeInfo = label(body, "", 16, COLOR_TEXT, true)
treeInfo.LayoutOrder = 20
treeInfo.Size = UDim2.new(1, 0, 0, 60)
treeInfo.TextYAlignment = Enum.TextYAlignment.Top
local removeButton = button(body, "Remove", COLOR_GREY)
removeButton.LayoutOrder = 21
removeButton.Size = UDim2.new(1, 0, 0, 40)

local status = label(main, "", 14, COLOR_TEXT, true)
status.Name = "Status"
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.new(0, 16, 1, -8)
status.Size = UDim2.new(1, -32, 0, 38)
status.TextXAlignment = Enum.TextXAlignment.Center

-- ============ ข้อมูล + วาด ============
local info = nil
local mode = "plant" -- "plant" / "tree"
local target = nil -- { lot, hole }
local removeArmed = 0

local function treeAt(hole)
	return info and info.Trees and info.Trees[tostring(hole)]
end

local function refresh()
	local ready = info and info.Loaded
	local holeNo = target and target.hole or 0
	local lotNo = target and (tostring(target.lot):gsub("Lot0?", "")) or "-"
	for _, b in pairs(plantButtons) do b.Visible = false end
	treeInfo.Visible, removeButton.Visible = false, false
	if mode == "plant" then
		title.Text = string.format(tr("🌱 ปลูกที่ล็อก %s หลุม %d", "🌱 Plant in lot %s hole %d"), lotNo, holeNo)
		local any = false
		for _, kind in ipairs(kinds) do
			local def = Config.Trees[kind]
			local n = ready and info.Seeds and info.Seeds[kind] or 0
			local b = plantButtons[kind]
			b.Visible = n > 0
			b.Text = string.format(tr("%s ปลูก%s (มีเมล็ด %d)", "%s Plant %s (%d seed)"), def.Icon, Config.NameOf(kind, lang()), n)
			any = any or n > 0
		end
		subtitle.Text = any and tr("เลือกเมล็ดในกระเป๋า · ต้นโตต่อแม้ออกจากเกม · ปลูกแล้วย้ายหลุมไม่ได้", "Choose a seed from your bag · trees keep growing while you are offline · a planted tree can't be moved")
			or tr("ไม่มีเมล็ดมะม่วง/ทุเรียนในกระเป๋า ซื้อได้ที่ร้านผลไม้ & อุปกรณ์หน้าสวน", "No mango/durian seeds in your bag. Buy them at the Fruit & Tools stall by the orchard gate")
	else
		local t = treeAt(holeNo)
		local def = t and Config.Trees[t.Kind]
		title.Text = def and (def.Icon .. " " .. Config.NameOf(t.Kind, lang()) .. string.format(tr(" · หลุม %d", " · hole %d"), holeNo)) or tr("🌳 ต้นไม้", "🌳 Tree")
		subtitle.Text = def and string.format(tr("ผลละ %s · ออกผลทุก %d ชม. · เก็บแล้วเข้ากระเป๋า ขายที่ร้าน", "%s each · fruit every %dh · picked fruit goes to your bag, sell it at the shop"),
			Config.Short(def.FruitPrice), def.FruitSeconds // 3600) or ""
		if t then
			local now = info.Now + (os.clock() - (info._at or os.clock()))
			local stage = Config.StageName(t.Stage, lang())
			if t.Stage == "Ripe" then
				treeInfo.Text = string.format(tr("%s %d ผล · กด \"เก็บเกี่ยว\" ที่ต้น", "%s %d fruit · press \"Harvest\" at the tree"), stage, t.Fruits)
			else
				treeInfo.Text = string.format(tr("%s · เก็บเกี่ยวได้ใน %s", "%s · ready to harvest in %s"), stage, clock((t.RipeAt or t.NextAt or now) - now)) -- เวลาถึงผลสุก ตรงกับป้ายเหนือต้น (ผู้ใช้สั่ง 2026-11-06)
			end
			if t.HarvestsLeft then -- เก็บได้จำกัดรอบ (2026-10-27)
				treeInfo.Text ..= string.format(tr(" · เก็บได้อีก %d รอบ", " · %d harvest(s) left"), t.HarvestsLeft)
			end
			treeInfo.Visible = true
			removeButton.Visible = true
			local armed = os.clock() - removeArmed < 4
			removeButton.Text = armed and tr("กดอีกครั้งเพื่อขุดต้นทิ้ง (ไม่ได้เมล็ดคืน)", "Tap again to dig it up (no seed back)") or tr("🪓 ขุดต้นทิ้ง", "🪓 Dig up")
			removeButton.BackgroundColor3 = armed and COLOR_RED or COLOR_GREY
		else
			treeInfo.Visible = true
			treeInfo.Text = tr("หลุมนี้ว่างแล้ว", "This hole is empty now")
		end
	end
end

local function setInfo(newInfo)
	if type(newInfo) ~= "table" then return end
	newInfo._at = os.clock()
	info = newInfo
	if gui.Enabled then refresh() end
end
syncRemote.OnClientEvent:Connect(setInfo)

local waiting = false
local function request(action, arg)
	if waiting then return nil end
	waiting = true
	status.Text = "⏳"
	status.TextColor3 = COLOR_SUB
	local ok, res = pcall(function() return requestRemote:InvokeServer(action, arg) end)
	waiting = false
	if not ok or type(res) ~= "table" then
		status.Text = tr("เชื่อมต่อไม่ได้ ลองใหม่อีกครั้ง", "Connection problem, please try again")
		status.TextColor3 = COLOR_RED
		return nil
	end
	setInfo(res.info)
	status.Text = res.message or ""
	status.TextColor3 = res.ok and COLOR_GO or COLOR_RED
	refresh()
	return res
end

local function close() gui.Enabled = false end

for _, kind in ipairs(kinds) do
	plantButtons[kind].Activated:Connect(function()
		if not target then return end
		local res = request("plant", { target.lot, target.hole, kind })
		if res and res.ok then task.delay(1.3, function() if mode == "plant" then close() end end) end
	end)
end
removeButton.Activated:Connect(function()
	if not target then return end
	if os.clock() - removeArmed < 4 then
		removeArmed = 0
		local res = request("remove", target.hole)
		if res and res.ok then task.delay(1.3, close) end
	else
		removeArmed = os.clock()
		refresh()
	end
end)

-- ============ เปิด/ปิด + จอย ============
local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(main)
end
local function firstButton()
	for _, kind in ipairs(kinds) do
		if plantButtons[kind].Visible then return plantButtons[kind] end
	end
	if removeButton.Visible then return removeButton end
	return closeButton
end
local function holePart()
	local zone = workspace:FindFirstChild("Orchard")
	local lot = target and zone and zone:FindFirstChild("Lots") and zone.Lots:FindFirstChild(tostring(target.lot))
	return lot and lot:FindFirstChild("Hole" .. tostring(target.hole))
end
openRemote.OnClientEvent:Connect(function(newMode, data)
	if type(data) ~= "table" or (newMode ~= "plant" and newMode ~= "tree") then return end -- เครื่องทำปุ๋ย / ตู้แลกน้ำใจ มีหน้าต่างของตัวเอง (ด้านล่าง)
	mode = newMode == "tree" and "tree" or "plant"
	target = { lot = data.lot, hole = tonumber(data.hole) }
	removeArmed = 0
	gui.Enabled = true
	status.Text = ""
	refresh()
	task.spawn(function()
		local ok, res = pcall(function() return requestRemote:InvokeServer("info") end)
		if ok and type(res) == "table" then setInfo(res.info) end
		if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] and gui.Enabled then
			GuiService.SelectedObject = firstButton()
		end
	end)
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
	local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(255, 190, 40) st.Thickness = 3.5 st.Parent = selectBox
end
for _, d in ipairs(main:GetDescendants()) do
	if d:IsA("GuiButton") then d.SelectionImageObject = selectBox end
end

-- เดินห่างหลุม = ปิดเอง · เปิดอยู่ = นับถอยหลังทุกวินาที
task.spawn(function()
	while true do
		task.wait(1)
		if gui.Enabled then
			local hole = holePart()
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hole and root and (root.Position - hole.Position).Magnitude > Config.HARVEST_DISTANCE + 6 then
				close()
			else
				refresh()
				local sel = GuiService.SelectedObject
				if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] and (not sel or (sel:IsDescendantOf(main) and not sel.Visible)) then
					GuiService.SelectedObject = firstButton()
				end
			end
		end
	end
end)

-- ============ เครื่องทำปุ๋ย: เลือกจำนวน (ผู้ใช้สั่ง 2026-11-02) ============
-- เซิร์ฟยิง OrchardOpen "fertilizer" { wood, coins, max, perWood, perCoins, maxBatch, busy } ตอนกด E ที่เครื่อง
-- - / + / MAX เลือกจำนวน → "ทำปุ๋ย" = OrchardRequest "fertilizer"(n) (เซิร์ฟเช็กซ้ำทุกอย่าง) · จอย: เปิดแล้วเลือกปุ่มทำปุ๋ย B ปิด · เดินห่างเครื่อง = ปิดเอง
do
	local FW, FH = 360, 290
	local fgui = Instance.new("ScreenGui")
	fgui.Name = "OrchardFertilizerGui"
	fgui.ResetOnSpawn = false
	fgui.DisplayOrder = 30 -- อยู่เหนือแถบช่องด่วน
	fgui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	fgui.Enabled = false
	fgui.Parent = playerGui
	local win = Instance.new("Frame")
	win.Name = "Main"
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.Position = UDim2.fromScale(0.5, 0.5)
	win.Size = UDim2.fromOffset(FW, FH)
	win.BackgroundColor3 = COLOR_BG
	win.Active = true
	win.SelectionGroup = true
	win.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	win.Parent = fgui
	corner(win, 18)
	do local st = Instance.new("UIStroke") st.Color = COLOR_BORDER st.Thickness = 3 st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border st.Parent = win end
	local fscale = Instance.new("UIScale")
	fscale.Parent = win
	local function ffit()
		local vp = camera.ViewportSize
		if vp.X < 2 then return end
		fscale.Scale = math.clamp(math.min((vp.X - 24) / FW, (vp.Y - 40) / FH), 0.5, 1)
	end
	ffit()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(ffit)

	local ftitle = label(win, tr("🌱 เครื่องทำปุ๋ย", "🌱 Fertilizer machine"), 20, COLOR_TEXT, true)
	ftitle.Size = UDim2.new(1, -70, 0, 30)
	ftitle.Position = UDim2.fromOffset(16, 10)
	local fsub = label(win, "", 13, COLOR_SUB, false)
	fsub.Size = UDim2.new(1, -32, 0, 34)
	fsub.Position = UDim2.fromOffset(16, 40)
	fsub.TextYAlignment = Enum.TextYAlignment.Top
	local fclose = button(win, "Close", Color3.fromRGB(240, 120, 110))
	fclose.AnchorPoint = Vector2.new(1, 0)
	fclose.Position = UDim2.new(1, -12, 0, 12)
	fclose.Size = UDim2.fromOffset(34, 34)
	fclose.Text = "X"
	fclose.TextSize = 16
	corner(fclose, 17)

	-- แถวเลือกจำนวน: [-] [จำนวน] [+] [MAX]
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(16, 82)
	row.Size = UDim2.new(1, -32, 0, 50)
	row.Parent = win
	local minus = button(row, "Minus", COLOR_GOLD)
	minus.Size = UDim2.fromOffset(50, 50)
	minus.Text = "−"
	minus.TextSize = 26
	local countBox = Instance.new("Frame")
	countBox.BackgroundColor3 = Color3.new(1, 1, 1)
	countBox.Position = UDim2.fromOffset(58, 0)
	countBox.Size = UDim2.new(1, -58 - 58 - 82, 1, 0)
	countBox.Parent = row
	corner(countBox, 10)
	do local st = Instance.new("UIStroke") st.Color = COLOR_BORDER st.Thickness = 2 st.Parent = countBox end
	local countLabel = label(countBox, "1", 26, COLOR_TEXT, true)
	countLabel.Size = UDim2.fromScale(1, 1)
	countLabel.TextXAlignment = Enum.TextXAlignment.Center
	local plus = button(row, "Plus", COLOR_GOLD)
	plus.AnchorPoint = Vector2.new(1, 0)
	plus.Position = UDim2.new(1, -82, 0, 0)
	plus.Size = UDim2.fromOffset(50, 50)
	plus.Text = "+"
	plus.TextSize = 26
	local maxB = button(row, "Max", COLOR_BORDER)
	maxB.AnchorPoint = Vector2.new(1, 0)
	maxB.Position = UDim2.new(1, 0, 0, 0)
	maxB.Size = UDim2.fromOffset(74, 50)
	maxB.Text = "MAX"

	local cost = label(win, "", 15, COLOR_TEXT, true)
	cost.Position = UDim2.fromOffset(16, 142)
	cost.Size = UDim2.new(1, -32, 0, 44)
	cost.TextXAlignment = Enum.TextXAlignment.Center
	cost.RichText = true
	local make = button(win, "Make", COLOR_GO)
	make.Position = UDim2.fromOffset(16, 192)
	make.Size = UDim2.new(1, -32, 0, 48)
	make.TextSize = 18
	local fstatus = label(win, "", 13, COLOR_TEXT, true)
	fstatus.AnchorPoint = Vector2.new(0, 1)
	fstatus.Position = UDim2.new(0, 16, 1, -6)
	fstatus.Size = UDim2.new(1, -32, 0, 38)
	fstatus.TextXAlignment = Enum.TextXAlignment.Center
	for _, d in ipairs(win:GetDescendants()) do
		if d:IsA("GuiButton") then d.SelectionImageObject = selectBox end
	end

	local fdata, count, fwaiting = nil, 1, false
	local function short(n) return Config.Short(n) end
	local function frefresh()
		local d = fdata or {}
		local perW, perC = d.perWood or Config.FertilizerMachine.Wood, d.perCoins or Config.FertilizerMachine.Coins
		local maxN = math.max(d.max or 0, 0)
		count = math.clamp(count, 1, math.max(d.maxBatch or 20, 1))
		fsub.Text = string.format(tr("ท่อนไม้ %d + %s เหรียญ = ปุ๋ย 1 ถุง · ใส่ต้นที่กำลังโต = เร็วขึ้น %d นาที", "%d logs + %s coins = 1 fertilizer · use on a growing tree = %d min faster"),
			perW, short(perC), math.floor(Config.FertilizerSeconds / 60))
		countLabel.Text = tostring(count)
		local needW, needC = perW * count, perC * count
		local okW, okC = (d.wood or 0) >= needW, (d.coins or 0) >= needC
		local function col(ok) return ok and "#1f9e5a" or "#d8504a" end
		cost.Text = string.format(tr("ใช้ <font color=\"%s\">🌲 %d (มี %d)</font> · <font color=\"%s\">💰 %s (มี %s)</font>", "Uses <font color=\"%s\">🌲 %d (have %d)</font> · <font color=\"%s\">💰 %s (have %s)</font>"),
			col(okW), needW, d.wood or 0, col(okC), short(needC), short(d.coins or 0))
		local can = okW and okC and not d.busy and not fwaiting
		make.Text = d.busy and tr("⏳ เครื่องกำลังทำอยู่...", "⏳ Machine is busy...")
			or string.format(tr("🌱 ทำปุ๋ย %d ถุง", "🌱 Make %d fertilizer"), count)
		make.BackgroundColor3 = can and COLOR_GO or COLOR_GREY
		minus.BackgroundColor3 = count > 1 and COLOR_GOLD or COLOR_GREY
		plus.BackgroundColor3 = count < math.max(maxN, 1) and COLOR_GOLD or COLOR_GREY
		maxB.BackgroundColor3 = maxN > 0 and COLOR_BORDER or COLOR_GREY
	end
	local function fclose_() fgui.Enabled = false end
	local function machineBody()
		local zone = workspace:FindFirstChild("Orchard")
		local m = zone and zone:FindFirstChild("Decor") and zone.Decor:FindFirstChild("FertilizerMachine")
		return m and m:FindFirstChild("Body")
	end
	local function fetch()
		local ok, res = pcall(function() return requestRemote:InvokeServer("fertilizerInfo") end)
		if ok and type(res) == "table" then fdata = res frefresh() end
	end

	minus.Activated:Connect(function() count = math.max(1, count - 1) frefresh() end)
	plus.Activated:Connect(function()
		local maxN = fdata and fdata.max or 0
		count = math.min(count + 1, math.max(maxN, 1)) -- เกินที่ทำได้ไม่ได้
		frefresh()
	end)
	maxB.Activated:Connect(function()
		count = math.max(1, fdata and fdata.max or 1)
		frefresh()
	end)
	make.Activated:Connect(function()
		if fwaiting or not fdata or fdata.busy then return end
		fwaiting = true
		fstatus.Text = "⏳"
		fstatus.TextColor3 = COLOR_SUB
		local ok, res = pcall(function() return requestRemote:InvokeServer("fertilizer", count) end)
		fwaiting = false
		if not ok or type(res) ~= "table" then
			fstatus.Text = tr("เชื่อมต่อไม่ได้ ลองใหม่อีกครั้ง", "Connection problem, please try again")
			fstatus.TextColor3 = COLOR_RED
			return
		end
		if type(res.info) == "table" then fdata = res.info end
		fstatus.Text = res.message or ""
		fstatus.TextColor3 = res.ok and COLOR_GO or COLOR_RED
		count = 1
		frefresh()
		if res.ok then task.delay(1.2, fclose_) end
	end)
	fclose.Activated:Connect(fclose_)

	openRemote.OnClientEvent:Connect(function(newMode, data)
		if newMode ~= "fertilizer" or type(data) ~= "table" then return end
		fdata = data
		count = 1
		fstatus.Text = ""
		gui.Enabled = false -- ไม่เปิดซ้อนกับหน้าต่างต้นไม้
		fgui.Enabled = true
		frefresh()
		if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then GuiService.SelectedObject = make end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB and fgui.Enabled then fclose_() end
	end)
	fgui:GetPropertyChangedSignal("Enabled"):Connect(function()
		local sel = GuiService.SelectedObject
		if not fgui.Enabled and sel and sel:IsDescendantOf(win) then GuiService.SelectedObject = nil end
	end)
	-- เปิดอยู่: เดินห่างเครื่อง = ปิด · อัปเดตไม้/เหรียญทุก 2 วิ (เครื่องทำเสร็จ/ได้ไม้เพิ่ม)
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(1)
			if fgui.Enabled then
				local b = machineBody()
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if b and root and (root.Position - b.Position).Magnitude > 18 then
					fclose_()
				else
					tick += 1
					if tick % 2 == 0 and not fwaiting then task.spawn(fetch) end
				end
			end
		end
	end)
end

-- ============ ตู้แลกน้ำใจ 💚 (เฟส 1 ผู้ใช้สั่ง 2026-11-03) ============
-- เซิร์ฟยิง OrchardOpen "helpshop" { Loaded, Coins, Items = { Id, Price, Bought, Limit, Owned, Equipped, SoldOut, Step, Steps, Hidden } } ตอนกด E ที่ตู้
-- แท็บ "ของใช้" / "ฉายา" / "ประดับหลัง" / "สัตว์ขี่" · กดแลก = หน้าต่างยืนยัน (ยืนยัน / ยกเลิก 2026-11-03 เดิมกด 2 ครั้ง) · เหรียญไม่พอ = บอกทันที · ฉายาที่มีแล้ว = ใส่/ถอด · เซิร์ฟเช็กทุกอย่างซ้ำ
-- จอย: เปิดแล้วเลือกปุ่มแรก B ปิด · เดินห่างตู้ = ปิดเอง
do
	local SW, SH = 420, 430
	local sgui = Instance.new("ScreenGui")
	sgui.Name = "OrchardHelpShopGui"
	sgui.ResetOnSpawn = false
	sgui.DisplayOrder = 30 -- อยู่เหนือแถบช่องด่วน (เดิม 8 แถบทับขอบล่าง)
	sgui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	sgui.Enabled = false
	sgui.Parent = playerGui
	local win = Instance.new("Frame")
	win.Name = "Main"
	win.AnchorPoint = Vector2.new(0.5, 0.5)
	win.Position = UDim2.fromScale(0.5, 0.5)
	win.Size = UDim2.fromOffset(SW, SH)
	win.BackgroundColor3 = COLOR_BG
	win.Active = true
	win.SelectionGroup = true
	win.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	win.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	win.Parent = sgui
	corner(win, 18)
	do local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(90, 190, 120) st.Thickness = 3 st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border st.Parent = win end
	local sscale = Instance.new("UIScale")
	sscale.Parent = win
	local function sfit()
		local vp = camera.ViewportSize
		if vp.X < 2 then return end
		sscale.Scale = math.clamp(math.min((vp.X - 24) / SW, (vp.Y - 40) / SH), 0.5, 1)
	end
	sfit()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(sfit)

	local stitle = label(win, tr("💚 ร้านแลกน้ำใจ", "💚 Kindness Shop"), 20, COLOR_TEXT, true) -- เดิม "ตู้แลกน้ำใจ" ผู้ใช้เปลี่ยนชื่อ 2026-11-03
	stitle.Size = UDim2.new(1, -70, 0, 30)
	stitle.Position = UDim2.fromOffset(16, 10)
	local scoins = label(win, "", 15, Color3.fromRGB(40, 150, 80), true)
	scoins.Size = UDim2.new(1, -32, 0, 22)
	scoins.Position = UDim2.fromOffset(16, 40)
	local sclose = button(win, "Close", Color3.fromRGB(240, 120, 110))
	sclose.AnchorPoint = Vector2.new(1, 0)
	sclose.Position = UDim2.new(1, -12, 0, 12)
	sclose.Size = UDim2.fromOffset(34, 34)
	sclose.Text = "X"
	sclose.TextSize = 16
	corner(sclose, 17)

	-- แท็บ
	local tabRow = Instance.new("Frame")
	tabRow.BackgroundTransparency = 1
	tabRow.Position = UDim2.fromOffset(16, 68)
	tabRow.Size = UDim2.new(1, -32, 0, 36)
	tabRow.Parent = win
	local TABS = { { id = "items", th = "🎁 ของใช้", en = "🎁 Items" }, { id = "titles", th = "🏷️ ฉายา", en = "🏷️ Titles" }, { id = "back", th = "🎒 ประดับหลัง", en = "🎒 Back" },
		{ id = "mount", th = "🐘 สัตว์ขี่", en = "🐘 Mount" } } -- ประดับหลัง = เฟส 2 · สัตว์ขี่ = เฟส 3 (2026-11-03)
	local tabButtons = {}
	local TW = 1 / #TABS
	for i, t in ipairs(TABS) do
		local b = button(tabRow, "Tab_" .. t.id, COLOR_GREY)
		b.Size = UDim2.new(TW, -4, 1, 0)
		b.Position = UDim2.new((i - 1) * TW, (i - 1) * 2, 0, 0)
		b.Text = tr(t.th, t.en)
		b.TextSize = 14
		tabButtons[t.id] = b
	end

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(16, 112)
	list.Size = UDim2.new(1, -32, 1, -160)
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Selectable = false
	list.Parent = win
	do
		local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, 8) l.SortOrder = Enum.SortOrder.LayoutOrder l.Parent = list
		local p = Instance.new("UIPadding") p.PaddingRight = UDim.new(0, 8) p.PaddingTop = UDim.new(0, 2) p.PaddingBottom = UDim.new(0, 4) p.Parent = list
	end
	local sstatus = label(win, "", 13, COLOR_TEXT, true)
	sstatus.AnchorPoint = Vector2.new(0, 1)
	sstatus.Position = UDim2.new(0, 16, 1, -6)
	sstatus.Size = UDim2.new(1, -32, 0, 38)
	sstatus.TextXAlignment = Enum.TextXAlignment.Center

	-- แถวสินค้า (สร้างครั้งเดียวตาม Config) · ซ่อนตามแท็บ/Hidden
	local rows = {} -- [Id] = { frame, name, detail, btn, def }
	for i, def in ipairs(Config.HelpShop.Items) do
		local f = Instance.new("Frame")
		f.Name = "Row_" .. def.Id
		f.LayoutOrder = i
		f.Size = UDim2.new(1, 0, 0, 64)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.Parent = list
		corner(f, 12)
		do local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(200, 230, 200) st.Thickness = 2 st.Parent = f end
		local icon = label(f, def.Icon, 28, COLOR_TEXT, true)
		icon.Position = UDim2.fromOffset(8, 0)
		icon.Size = UDim2.fromOffset(40, 64)
		icon.TextXAlignment = Enum.TextXAlignment.Center
		local nm = label(f, lang() == "en" and def.NameEn or def.NameTh, 15, COLOR_TEXT, true)
		nm.Position = UDim2.fromOffset(52, 8)
		nm.Size = UDim2.new(1, -52 - 120, 0, 22)
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.TextWrapped = false
		local dt = label(f, "", 12, COLOR_SUB, false)
		dt.Position = UDim2.fromOffset(52, 32)
		dt.Size = UDim2.new(1, -52 - 120, 0, 24)
		dt.TextYAlignment = Enum.TextYAlignment.Top
		local b = button(f, "Buy_" .. def.Id, COLOR_GO)
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -10, 0.5, 0)
		b.Size = UDim2.fromOffset(104, 40)
		b.TextSize = 15
		b.SelectionImageObject = selectBox
		if def.Grant == "mount" then
			-- สัตว์ขี่: แถวสูงขึ้น + ภาพ 3D หมุน (ReplicatedStorage.MountPreviewModels.<Mount>) แทนอีโมจิ
			f.Size = UDim2.new(1, 0, 0, 132)
			local src = ReplicatedStorage:FindFirstChild("MountPreviewModels") and ReplicatedStorage.MountPreviewModels:FindFirstChild(def.Mount)
			if src then
				icon.Visible = false
				local vp = Instance.new("ViewportFrame")
				vp.BackgroundTransparency = 1
				vp.Position = UDim2.fromOffset(4, 6)
				vp.Size = UDim2.fromOffset(120, 120)
				vp.Parent = f
				local model = src:Clone()
				model.Parent = vp
				local cam = Instance.new("Camera")
				cam.FieldOfView = 40
				cam.Parent = vp
				vp.CurrentCamera = cam
				local cf, size = model:GetBoundingBox()
				local dist = math.max(size.X, size.Y, size.Z) * 1.9
				task.spawn(function()
					local a = math.rad(200)
					while vp.Parent do
						if sgui.Enabled and f.Visible then
							a += math.rad(1.2)
							cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(math.sin(a) * dist, size.Y * 0.35, math.cos(a) * dist), cf.Position)
						end
						task.wait(1 / 30)
					end
				end)
				nm.Position = UDim2.fromOffset(128, 12)
				nm.Size = UDim2.new(1, -128 - 116, 0, 22)
				dt.Position = UDim2.fromOffset(128, 38)
				dt.Size = UDim2.new(1, -128 - 116, 0, 84)
				dt.TextWrapped = true
			end
		end
		rows[def.Id] = { frame = f, name = nm, detail = dt, btn = b, def = def }
	end
	for _, d in ipairs(win:GetDescendants()) do
		if d:IsA("GuiButton") then d.SelectionImageObject = selectBox end
	end

	local sdata, tab, swaiting = nil, "items", false
	local sendToken = 0 -- กันปุ่มค้าง: เซิร์ฟไม่ตอบใน 15 วิ = ปลดล็อกให้กดใหม่ได้ (2026-11-03)

	-- หน้าต่างยืนยันการแลก (ผู้ใช้สั่ง 2026-11-03 แทนการกด 2 ครั้งที่ผู้เล่นไม่รู้ว่าต้องกดซ้ำ): คลุมทั้งหน้าต่าง ปุ่ม ยืนยัน / ยกเลิก
	local confirmCover = Instance.new("TextButton") -- ปุ่มใสๆ คลุม = กดข้างหลังไม่ได้
	confirmCover.Name = "ConfirmCover"
	confirmCover.Text = ""
	confirmCover.AutoButtonColor = false
	confirmCover.Selectable = false
	confirmCover.BackgroundColor3 = Color3.new(0, 0, 0)
	confirmCover.BackgroundTransparency = 0.45
	confirmCover.Size = UDim2.fromScale(1, 1)
	confirmCover.ZIndex = 20
	confirmCover.Visible = false
	confirmCover.Parent = win
	corner(confirmCover, 18)
	local confirmBox = Instance.new("Frame")
	confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmBox.Position = UDim2.fromScale(0.5, 0.5)
	confirmBox.Size = UDim2.fromOffset(330, 190)
	confirmBox.BackgroundColor3 = COLOR_BG
	confirmBox.ZIndex = 21
	confirmBox.Parent = confirmCover
	corner(confirmBox, 14)
	do local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(90, 190, 120) st.Thickness = 3 st.Parent = confirmBox end
	local confirmTitle = label(confirmBox, "", 18, COLOR_TEXT, true)
	confirmTitle.Position = UDim2.fromOffset(14, 14)
	confirmTitle.Size = UDim2.new(1, -28, 0, 52)
	confirmTitle.TextXAlignment = Enum.TextXAlignment.Center
	confirmTitle.ZIndex = 22
	local confirmText = label(confirmBox, "", 14, COLOR_SUB, false)
	confirmText.Position = UDim2.fromOffset(14, 68)
	confirmText.Size = UDim2.new(1, -28, 0, 44)
	confirmText.TextXAlignment = Enum.TextXAlignment.Center
	confirmText.ZIndex = 22
	local confirmYes = button(confirmBox, "ConfirmYes", COLOR_GO)
	confirmYes.Position = UDim2.new(0.5, 6, 1, -60)
	confirmYes.Size = UDim2.new(0.5, -20, 0, 46)
	confirmYes.Text = tr("✅ ยืนยันแลก", "✅ Confirm")
	confirmYes.ZIndex = 22
	confirmYes.SelectionImageObject = selectBox
	local confirmNo = button(confirmBox, "ConfirmNo", COLOR_GREY)
	confirmNo.Position = UDim2.new(0, 14, 1, -60)
	confirmNo.Size = UDim2.new(0.5, -20, 0, 46)
	confirmNo.Text = tr("ยกเลิก", "Cancel")
	confirmNo.ZIndex = 22
	confirmNo.SelectionImageObject = selectBox
	local confirmId = nil
	local function itemData(id)
		for _, it in ipairs(sdata and sdata.Items or {}) do
			if it.Id == id then return it end
		end
		return nil
	end
	local function srefresh()
		local coins = sdata and sdata.Coins or 0
		scoins.Text = string.format(tr("มีเหรียญช่วยเหลือ 💚 %d · หาได้จากรดน้ำต้นแห้งของเพื่อน", "Help coins 💚 %d · earn them by watering friends' dead trees"), coins)
		for id, b in pairs(tabButtons) do b.BackgroundColor3 = id == tab and Color3.fromRGB(90, 190, 120) or COLOR_GREY end
		for id, r in pairs(rows) do
			local it = itemData(id)
			local def = r.def
			r.frame.Visible = def.Tab == tab and it ~= nil and not it.Hidden
			if it then
				local parts = {}
				if it.Price then table.insert(parts, "💚 " .. it.Price) end
				if it.Limit then table.insert(parts, string.format(tr("สัปดาห์นี้ %d/%d", "this week %d/%d"), it.Bought or 0, it.Limit)) end
				if it.Steps then table.insert(parts, string.format(tr("ซื้อแล้ว %d/%d ครั้ง", "bought %d/%d"), it.Step or 0, it.Steps)) end
				if def.Grant == "title" then table.insert(parts, it.Equipped and tr("ใส่อยู่", "wearing") or (it.Owned and tr("มีแล้ว", "owned") or tr("โชว์บนหัวให้ทุกคนเห็น", "shown above your head"))) end
				if def.Grant == "back" then table.insert(parts, it.Equipped and tr("ใส่อยู่", "wearing") or (it.Owned and tr("มีแล้ว", "owned") or tr("ติดหลังตัวละคร", "worn on your back"))) end
				if def.Grant == "mount" then
					table.insert(parts, it.Owned and tr("✅ มีแล้ว ขี่ได้จากตู้ 🗄️ ตกแต่ง", "✅ Owned, ride it from the 🗄️ Decor Cabinet")
						or tr("สัตว์ขี่หาได้ที่นี่ที่เดียว\nวิ่ง ×1.6 · งวงพ่นน้ำ หัวใจลอยตามทาง\nขี่อยู่รดน้ำช่วยเพื่อนได้เร็วขึ้นเท่าตัว", "Only from this shop\n×1.6 speed · trunk spray and hearts\nWater friends' trees twice as fast while riding"))
				end
				r.detail.Text = table.concat(parts, " · ")
				local b = r.btn
				if def.Grant == "mount" and it.Owned then
					b.Text = tr("มีแล้ว", "Owned")
					b.BackgroundColor3 = COLOR_GREY
				elseif (def.Grant == "title" or def.Grant == "back") and it.Owned then
					b.Text = it.Equipped and tr("ถอด", "Remove") or tr("ใส่", "Wear")
					b.BackgroundColor3 = it.Equipped and COLOR_GREY or COLOR_GOLD
				elseif it.SoldOut or (it.Limit and (it.Bought or 0) >= it.Limit) then
					b.Text = it.SoldOut and tr("ครบแล้ว", "Sold out") or tr("ครบสัปดาห์นี้", "Weekly max")
					b.BackgroundColor3 = COLOR_GREY
				else
					b.Text = tr("แลก 💚", "Get 💚") .. (it.Price or "")
					b.BackgroundColor3 = (it.Price and coins >= it.Price) and COLOR_GO or COLOR_GREY
				end
			end
		end
	end
	local function hideConfirm()
		confirmId = nil
		confirmCover.Visible = false
	end
	local function sclose_() hideConfirm() sgui.Enabled = false end
	local function boothBody()
		local zone = workspace:FindFirstChild("Orchard")
		local m = zone and zone:FindFirstChild("Decor") and zone.Decor:FindFirstChild("HelpShop")
		return m and m:FindFirstChild("Body")
	end
	local function send(action, arg)
		if swaiting then
			sstatus.Text = tr("⏳ กำลังทำรายการก่อนหน้า รอสักครู่", "⏳ Still working on the last request")
			sstatus.TextColor3 = COLOR_SUB
			return
		end
		swaiting = true
		sendToken += 1
		local token = sendToken
		sstatus.Text = "⏳"
		sstatus.TextColor3 = COLOR_SUB
		task.delay(15, function()
			if swaiting and sendToken == token then
				swaiting = false
				sstatus.Text = tr("เซิร์ฟตอบช้า ปิดแล้วเปิดร้านใหม่เพื่อดูผล ก่อนกดซ้ำ", "The server is slow. Reopen the shop to check before trying again")
				sstatus.TextColor3 = COLOR_RED
			end
		end)
		local ok, res = pcall(function() return requestRemote:InvokeServer(action, arg) end)
		if sendToken == token then swaiting = false end
		if not ok or type(res) ~= "table" then
			sstatus.Text = tr("เชื่อมต่อไม่ได้ ลองใหม่อีกครั้ง", "Connection problem, please try again")
			sstatus.TextColor3 = COLOR_RED
			return
		end
		if type(res.info) == "table" and res.info.Loaded then sdata = res.info end
		sstatus.Text = res.message or ""
		sstatus.TextColor3 = res.ok and COLOR_GO or COLOR_RED
		srefresh()
	end
	for id, r in pairs(rows) do
		r.btn.Activated:Connect(function()
			local it = itemData(id)
			if not it or swaiting then return end
			if r.def.Grant == "title" and it.Owned then
				send("helpShopEquip", (not it.Equipped) and id or false)
				return
			end
			if r.def.Grant == "mount" and it.Owned then return end -- มีแล้ว ขี่ที่ตู้ตกแต่ง
			if r.def.Grant == "back" and it.Owned then -- ประดับหลัง: ใส่/ถอด
				send("helpShopEquip", { back = (not it.Equipped) and id or false })
				return
			end
			if it.SoldOut or (it.Limit and (it.Bought or 0) >= it.Limit) then return end
			local coins = sdata and sdata.Coins or 0
			if it.Price and coins < it.Price then
				sstatus.Text = string.format(tr("💚 เหรียญช่วยเหลือไม่พอ (มี %d ต้องใช้ %d)", "💚 Not enough help coins (%d / %d)"), coins, it.Price)
				sstatus.TextColor3 = COLOR_RED
				return
			end
			-- เปิดหน้าต่างยืนยัน
			confirmId = id
			local name = lang() == "en" and r.def.NameEn or r.def.NameTh
			confirmTitle.Text = string.format(tr("แลก %s %s ?", "Get %s %s?"), r.def.Icon or "", name)
			confirmText.Text = string.format(tr("ใช้เหรียญช่วยเหลือ 💚 %d\nเหลือ 💚 %d", "Costs 💚 %d help coins\nYou'll have 💚 %d left"), it.Price or 0, coins - (it.Price or 0))
			confirmCover.Visible = true
			if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then GuiService.SelectedObject = confirmYes end
		end)
	end
	confirmYes.Activated:Connect(function()
		local id = confirmId
		hideConfirm()
		if id then send("helpShopBuy", id) end
	end)
	confirmNo.Activated:Connect(hideConfirm)
	confirmCover.Activated:Connect(hideConfirm) -- กดนอกกล่อง = ยกเลิก
	for id, b in pairs(tabButtons) do
		b.Activated:Connect(function() tab = id hideConfirm() srefresh() end)
	end
	sclose.Activated:Connect(sclose_)
	openRemote.OnClientEvent:Connect(function(newMode, data)
		if newMode ~= "helpshop" or type(data) ~= "table" then return end
		sdata = data.Loaded and data or nil
		hideConfirm()
		sstatus.Text = data.Loaded and "" or tr("ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง", "Still loading, please try again")
		gui.Enabled = false
		sgui.Enabled = true
		srefresh()
		if GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then GuiService.SelectedObject = tabButtons.items end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB and sgui.Enabled then
			if confirmCover.Visible then hideConfirm() else sclose_() end -- B ตอนถามยืนยัน = ยกเลิก
		end
	end)
	sgui:GetPropertyChangedSignal("Enabled"):Connect(function()
		local sel = GuiService.SelectedObject
		if not sgui.Enabled and sel and sel:IsDescendantOf(win) then GuiService.SelectedObject = nil end
	end)
	-- เดินห่างตู้ = ปิด
	task.spawn(function()
		while true do
			task.wait(0.5)
			if sgui.Enabled then
				local b = boothBody()
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if b and root and (root.Position - b.Position).Magnitude > 20 then
					sclose_()
				end
			end
		end
	end)
end

-- โหลดเสียงรดน้ำ/ช้างพ่นน้ำไว้ก่อน (2026-11-03) รดน้ำช่วยตอนขี่ช้างจบใน 1.5 วิ ไม่งั้นครั้งแรกเสียงยังโหลดไม่ทันก็จบแล้ว
task.spawn(function()
	local list = {}
	for _, id in pairs(Config.KitSounds or {}) do
		local s = Instance.new("Sound")
		s.SoundId = id
		table.insert(list, s)
	end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
	for _, s in ipairs(list) do s:Destroy() end
end)

-- ============ ป้ายเหนือต้น ============
local labels = {} -- [model] = TextLabel

local function ownerName(model)
	local p = Players:GetPlayerByUserId(model:GetAttribute("OwnerId") or 0)
	return p and p.DisplayName or tostring(model:GetAttribute("Owner") or "?")
end

local function updateLabel(model, l)
	local kind, stage = model:GetAttribute("Kind"), model:GetAttribute("Stage")
	local def = Config.Trees[kind]
	if not def then return end
	-- ป้ายต้นคนอื่นแสดงใกล้ๆ สวนเต็มแล้วป้ายซ้อนกันจนหาต้นตัวเองไม่เจอ (2026-11-07) · ต้นแห้งคงระยะเดิม เพื่อนจะได้เห็นไอคอนบัวรดน้ำ
	if l.Parent then
		local wantDist = (model:GetAttribute("OwnerId") == player.UserId or stage == "Dead") and 70 or 25
		if l.Parent.MaxDistance ~= wantDist then l.Parent.MaxDistance = wantDist end
	end
	-- ไอคอนบัวรดน้ำเด้งอยู่เหนือป้าย = ต้นแห้งที่เพื่อนยังช่วยรดน้ำได้ (ผู้ใช้สั่ง 2026-11-03)
	local can = l.Parent and l.Parent:FindFirstChild("CanIcon")
	if can then can.Visible = stage == "Dead" and model:GetAttribute("CanRevive") == true and model:GetAttribute("OwnerId") ~= player.UserId end -- ต้นของเราเองไม่ต้องมี (ผู้ใช้สั่ง 2026-11-03)
	if stage == "Dead" then
		-- ต้นแห้ง (ผู้ใช้สั่ง 2026-11-03): บน = บัวรดน้ำอันใหญ่ (เฉพาะต้นที่ช่วยได้) · กลาง = ไอคอน 🍂 · ล่าง = ชื่อเจ้าของ
		--   ป้ายสูงขึ้น (ไอคอนอยู่ในกรอบ ไม่ถูกตัด) ทางเลือกตัดต้น/ขอความช่วยเหลืออยู่ที่ปุ่มที่หลุมแล้ว
		local bb = l.Parent
		if bb then
			bb.Size = UDim2.fromOffset(200, 124)
			bb.StudsOffset = Vector3.new(0, 3.2, 0)
		end
		l.Size = UDim2.new(1, 0, 0, 28)
		l.Position = UDim2.new(0.5, 0, 0, 88)
		l.Text = "🍂"
		l.TextColor3 = Color3.fromRGB(235, 190, 130)
		local sub0 = bb and bb:FindFirstChild("Sub")
		if sub0 then
			local mineTree = model:GetAttribute("OwnerId") == player.UserId
			sub0.Visible = true
			sub0.Size = UDim2.new(1, 0, 0, 22)
			sub0.Position = UDim2.new(0.5, 0, 0, 112)
			sub0.Text = mineTree and tr("⭐ ต้นของฉัน", "⭐ My tree") or string.format(tr("ของ %s", "%s's tree"), ownerName(model))
		end
		return
	end
	-- ไอคอนรูป (มะม่วงสีเหลือง 2026-11-03 อีโมจิ 🥭 ของ Roblox เป็นสีแดง) วางซ้ายข้อความ แทนอีโมจิในข้อความ
	local icon = l.Parent and l.Parent:FindFirstChild("Icon")
	local useImage = icon ~= nil and type(def.IconImage) == "string"
	if icon then
		icon.Visible = useImage
		if useImage and icon.Image ~= def.IconImage then icon.Image = def.IconImage end
	end
	-- ต้นสุก = "🥭 ผลสุกแล้ว!" ไม่มีชื่อต้น + บรรทัดล่างเป็นชื่อเจ้าของ (ผู้ใช้สั่ง 2026-11-03)
	--   บรรทัดบนแยกเป็น TextLabel ของมันเอง รูปมะม่วงจะชิดซ้ายบรรทัดนี้พอดี (Sub = บรรทัดล่าง)
	local sub = l.Parent and l.Parent:FindFirstChild("Sub")
	if stage == "Ripe" then
		l.Size = UDim2.fromScale(1, 0.5)
		l.Position = UDim2.fromScale(0.5, 0.27)
		l.Text = (useImage and "" or (def.Icon .. " ")) .. Config.StageName(stage, lang())
		l.TextColor3 = Color3.fromRGB(255, 225, 90)
		if icon then icon.Size = UDim2.fromScale(0.5, 0.5) end
		if sub then
			local mineTree = model:GetAttribute("OwnerId") == player.UserId
			sub.Visible = true
			sub.Text = mineTree and tr("⭐ ต้นของฉัน", "⭐ My tree") or string.format(tr("ของ %s", "%s's tree"), ownerName(model))
		end
		return
	end
	-- ยังไม่สุก (ผู้ใช้สั่ง 2026-11-06): บรรทัดบน = รูปผลไม้ + เวลาถึงผลสุก (ไม่มีชื่อต้น/ชื่อขั้น เวลาไม่รีเซ็ตตอนเปลี่ยนขั้น) · บรรทัดล่างเหมือนเดิม · วางแบบเดียวกับต้นสุก
	l.Size = UDim2.fromScale(1, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.27)
	if icon then icon.Size = UDim2.fromScale(0.5, 0.5) end
	local target = model:GetAttribute("RipeAt") or 0
	if target <= 0 then target = model:GetAttribute("NextAt") or 0 end
	l.Text = (useImage and "" or (def.Icon .. " ")) .. (target > 0 and clock(target - serverNow()) or "")
	l.TextColor3 = Color3.new(1, 1, 1)
	if sub then
		local mine = model:GetAttribute("OwnerId") == player.UserId
		local left = model:GetAttribute("HarvestsLeft") -- เก็บได้อีกกี่รอบ (ต้นของเราเท่านั้น)
		local leftText = (mine and left) and string.format(tr(" · เก็บได้อีก %d รอบ", " · %d harvest(s) left"), left) or ""
		sub.Visible = true
		sub.Text = mine and (tr("⭐ ต้นของฉัน", "⭐ My tree") .. leftText) or string.format(tr("ของ %s", "%s's tree"), ownerName(model))
	end
end

-- ============ ป้ายลอย "แปลงของฉัน" (2026-11-07 ผู้ใช้สั่ง) ============
-- ลอยสูงเหนือกลางล็อกของเรา เห็นทะลุต้นไม้ เห็นเฉพาะเจ้าของ (สร้างฝั่งผู้เล่น) · แสดงตลอดในเขตสวน (ภายใน MARKER_RANGE) ซ่อนเมื่อเข้าแปลงแล้ว (MARKER_NEAR)
local MARKER_RANGE, MARKER_NEAR, MARKER_HEIGHT = 220, 16, 15 -- ปลายลูกศรชี้ลงกลางแปลง เหนือยอดต้นไม้
task.spawn(function()
	local part = Instance.new("Part")
	part.Name = "MyLotMarker"
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Name = "MyLotMarkerGui"
	bb.Size = UDim2.fromOffset(170, 96)
	bb.SizeOffset = Vector2.new(0, 0.5) -- ขอบล่างป้าย (ปลายลูกศร) อยู่ที่จุดกลางแปลง
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Enabled = false
	bb.Parent = part
	local box = Instance.new("TextLabel")
	box.Size = UDim2.new(1, 0, 0, 58)
	box.BackgroundColor3 = Color3.fromRGB(70, 150, 75)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 17
	box.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = box
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = box
	-- ลูกศรชี้ลงแปลง (2026-11-07 ผู้ใช้สั่ง)
	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.AnchorPoint = Vector2.new(0.5, 1)
	arrow.Position = UDim2.fromScale(0.5, 1)
	arrow.Size = UDim2.fromOffset(60, 40)
	arrow.Font = Enum.Font.GothamBlack
	arrow.Text = "▼"
	arrow.TextSize = 38
	arrow.TextColor3 = Color3.fromRGB(70, 150, 75)
	arrow.TextStrokeColor3 = Color3.new(1, 1, 1)
	arrow.TextStrokeTransparency = 0
	arrow.Parent = bb
	-- ชั้นที่สองแบบปกติ: ตอนทดสอบ AlwaysOnTop ไม่ขึ้นในภาพจับจอ ซ้อนไว้ให้เห็นแน่นอน
	local flat = bb:Clone()
	flat.Name = "MyLotMarkerFlat"
	flat.AlwaysOnTop = false
	flat.Parent = part
	local flatBox = flat:FindFirstChildOfClass("TextLabel")
	-- ขยับขึ้นลงเบาๆ ให้สะดุดตา
	local bob = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	for _, g in ipairs({ bb, flat }) do
		game:GetService("TweenService"):Create(g, bob, { StudsOffset = Vector3.new(0, 1.5, 0) }):Play()
	end
	local cachedName, center = nil, nil
	while true do
		task.wait(0.25)
		local name = player:GetAttribute("OrchardLot")
		if name ~= cachedName then
			cachedName, center = name, nil
			local zone = workspace:FindFirstChild("Orchard")
			local lotsFolder = zone and zone:FindFirstChild("Lots")
			local lot = lotsFolder and name and lotsFolder:FindFirstChild(name)
			local sum, n = Vector3.zero, 0
			for _, c in ipairs(lot and lot:GetChildren() or {}) do
				if c:IsA("BasePart") and c.Name:match("^Hole%d+$") then
					sum += c.Position
					n += 1
				end
			end
			if n > 0 then
				center = sum / n
				part.Position = center + Vector3.new(0, MARKER_HEIGHT, 0)
			else
				cachedName = nil -- ล็อกยังมาไม่ถึง (StreamingEnabled) ลองใหม่รอบหน้า
			end
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local show = false
		if center and root then
			local d = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
			show = d <= MARKER_RANGE and d > MARKER_NEAR
			if show then
				box.Text = tr("📍 แปลงของฉัน", "📍 My orchard") .. "\n" .. string.format(tr("%d ม.", "%d m"), math.floor(d))
				flatBox.Text = box.Text
			end
		end
		if bb.Enabled ~= show then
			bb.Enabled = show
			flat.Enabled = show
		end
	end
end)

local function hookTree(model)
	if labels[model] or not model:IsA("Model") or not model:GetAttribute("Kind") then return end
	local anchor = model:WaitForChild("LabelAnchor", 10)
	if not anchor or not model.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "TreeLabel"
	bb.Size = UDim2.fromOffset(200, 44)
	bb.StudsOffset = Vector3.new(0, 1.2, 0)
	bb.MaxDistance = 70
	bb.Parent = anchor
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.5)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextStrokeTransparency = 0.4
	l.Parent = bb
	-- รูปไอคอนผลไม้ (Trees[kind].IconImage) ชิดซ้ายตัวหนังสือ ตามความกว้างข้อความจริง (TextBounds)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(1, 0.5)
	icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	icon.Size = UDim2.fromScale(0.42, 0.42)
	icon.Visible = false
	icon.Parent = bb
	local can = Instance.new("ImageLabel")
	can.Name = "CanIcon"
	can.BackgroundTransparency = 1
	can.Image = Config.DeadTree.HelpIcon or ""
	can.AnchorPoint = Vector2.new(0.5, 0)
	can.Size = UDim2.fromOffset(56, 56) -- 70 → 56 (ลด 20% ผู้ใช้สั่ง 2026-11-03)
	can.Position = UDim2.new(0.5, 0, 0, 18)
	can.Visible = false
	can.Parent = bb
	game:GetService("TweenService"):Create(can, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(0.5, 0, 0, 8) }):Play()
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.AnchorPoint = Vector2.new(0.5, 0.5)
	sub.Position = UDim2.fromScale(0.5, 0.76)
	sub.Size = UDim2.fromScale(1, 0.42)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.TextStrokeTransparency = 0.4
	sub.Visible = false
	sub.Parent = bb
	local function placeIcon()
		icon.Position = UDim2.new(0.5, -l.TextBounds.X / 2 - 2, l.Position.Y.Scale, 0)
	end
	l:GetPropertyChangedSignal("TextBounds"):Connect(placeIcon)
	l:GetPropertyChangedSignal("Position"):Connect(placeIcon)
	labels[model] = l
	updateLabel(model, l)
	placeIcon()
	model.Destroying:Connect(function() labels[model] = nil end)
end

-- ============ ปุ่มที่หลุม: ใครเห็น + คำอังกฤษ ============
local PROMPT_EN = { ["ปลูกต้นไม้"] = "Plant tree", ["เก็บเกี่ยว"] = "Harvest", ["ดูต้นไม้"] = "View tree", ["ตัดต้น"] = "Cut down" }
local prompts = {} -- [prompt] = lot

-- ถือปุ๋ยไม้ผลอยู่ไหม (2026-11-02) ถือ = ปุ่มต้นที่กำลังโตของเราเป็น "ใส่ปุ๋ย" (เซิร์ฟเช็กของในมือเอง)
local function holdingFertilizer()
	local t = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	return t ~= nil and t:GetAttribute("IsOrchardMat") == true and t:GetAttribute("MatId") == "Fertilizer"
end

local function applyPrompt(prompt, lot)
	local owner = lot:GetAttribute("OwnerId")
	local allowed = owner == player.UserId or (owner == nil and player:GetAttribute("OrchardLot") == nil)
	if prompt.Enabled ~= allowed then prompt.Enabled = allowed end
	if prompt:GetAttribute("State") == "grow" then
		local want = holdingFertilizer() and tr("ใส่ปุ๋ย 🌱", "Fertilize 🌱") or tr("ดูต้นไม้", "View tree")
		if prompt.ActionText ~= want then prompt.ActionText = want end
	end
	if lang() == "en" then
		local en = PROMPT_EN[prompt.ActionText]
		if en then prompt.ActionText = en end
		local obj = prompt.ObjectText
		obj = obj:gsub("หลุม", "Hole")
		obj = obj:gsub("แห้ง %(ตัดได้อย่างเดียว%)", " (dead, cut only)"):gsub("แห้ง$", " (dead)") -- ต้นแห้ง (2026-11-07)
		for _, kind in ipairs(kinds) do
			obj = obj:gsub(Config.Trees[kind].NameTh, Config.Trees[kind].NameEn)
		end
		if obj ~= prompt.ObjectText then prompt.ObjectText = obj end
	end
end

local function hookPrompt(prompt)
	if prompts[prompt] or not (prompt:IsA("ProximityPrompt") and prompt.Name == "HolePrompt") then return end
	local lot = prompt:FindFirstAncestorWhichIsA("Model")
	if not lot then return end
	prompts[prompt] = lot
	for _, prop in ipairs({ "Enabled", "ActionText", "ObjectText" }) do
		prompt:GetPropertyChangedSignal(prop):Connect(function() applyPrompt(prompt, lot) end)
	end
	lot:GetAttributeChangedSignal("OwnerId"):Connect(function() applyPrompt(prompt, lot) end)
	prompt.Destroying:Connect(function() prompts[prompt] = nil end)
	applyPrompt(prompt, lot)
end
player:GetAttributeChangedSignal("OrchardLot"):Connect(function()
	for prompt, lot in pairs(prompts) do applyPrompt(prompt, lot) end
end)

-- ============ ปุ่ม "ย้ายมาแปลงนี้" ที่ป้ายล็อกว่าง (2026-11-06) ============
-- เห็นเฉพาะล็อกว่าง + เรามีล็อกอยู่แล้ว · เซิร์ฟตรวจซ้ำ (OrchardService moveLot รวมกรณีโจรกำลังขโมย)
local movePrompts = {} -- [prompt] = lot
local function applyMove(prompt, lot)
	local show = lot:GetAttribute("OwnerId") == nil and player:GetAttribute("OrchardLot") ~= nil
	if prompt.Enabled ~= show then prompt.Enabled = show end
	local action = tr("ย้ายมาแปลงนี้", "Move here")
	if prompt.ActionText ~= action then prompt.ActionText = action end
	if lang() == "en" then
		local obj = prompt.ObjectText:gsub("ล็อก", "Lot")
		if obj ~= prompt.ObjectText then prompt.ObjectText = obj end
	end
end
-- หน้าต่างยืนยันก่อนย้าย (2026-11-07 ผู้ใช้สั่ง)
local moveConfirm
local function closeMoveConfirm()
	if moveConfirm then moveConfirm:Destroy(); moveConfirm = nil end
end
local function showMoveConfirm(lot)
	closeMoveConfirm()
	local fromNo = tostring(player:GetAttribute("OrchardLot") or ""):match("%d+") or "?"
	local toNo = lot.Name:match("%d+") or "?"
	local gui = Instance.new("ScreenGui")
	gui.Name = "OrchardMoveConfirm"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 58
	gui.Parent = playerGui
	moveConfirm = gui
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.45)
	card.Size = UDim2.fromOffset(340, 180)
	card.BackgroundColor3 = COLOR_BG
	card.Parent = gui
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 18); cc.Parent = card
	local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(140, 100, 65); cs.Thickness = 3; cs.Parent = card
	local function text(str, size, y, h, font, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(16, y)
		l.Size = UDim2.new(1, -32, 0, h)
		l.Font = font
		l.Text = str
		l.TextColor3 = color
		l.TextSize = size
		l.TextWrapped = true
		l.Parent = card
	end
	text(tr("🌳 ย้ายมาแปลงนี้?", "🌳 Move to this lot?"), 22, 14, 32, Enum.Font.GothamBold, COLOR_TEXT)
	text(string.format(tr("ย้ายสวนจากล็อก %s ไปล็อก %s\nต้นทุกต้นย้ายตามมา เวลาและรอบเก็บเท่าเดิม", "Move your orchard from lot %s to lot %s\nAll trees come along, time and harvests stay the same"), fromNo, toNo), 15, 50, 56, Enum.Font.Gotham, COLOR_SUB)
	local function button(str, bg, fg, x)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.new(x, 0, 1, -14)
		b.Size = UDim2.new(0.5, -22, 0, 46)
		b.BackgroundColor3 = bg
		b.Font = Enum.Font.GothamBold
		b.Text = str
		b.TextColor3 = fg
		b.TextSize = 17
		b.Parent = card
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = b
		return b
	end
	local cancel = button(tr("ยกเลิก", "Cancel"), Color3.fromRGB(232, 220, 200), COLOR_TEXT, 0.27)
	local ok = button(tr("ยืนยันย้าย", "Move"), Color3.fromRGB(95, 175, 105), Color3.new(1, 1, 1), 0.73)
	cancel.Activated:Connect(closeMoveConfirm)
	ok.Activated:Connect(function()
		closeMoveConfirm()
		local ev = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("OrchardMoveLot")
		if ev then ev:FireServer(lot.Name) end
	end)
	if UserInputService:GetLastInputType().Name:match("^Gamepad") then GuiService.SelectedObject = ok end
end

local function hookMove(prompt)
	if movePrompts[prompt] or not (prompt:IsA("ProximityPrompt") and prompt.Name == "MovePrompt") then return end
	local lot = prompt:FindFirstAncestorWhichIsA("Model")
	if not lot then return end
	movePrompts[prompt] = lot
	prompt.Triggered:Connect(function() showMoveConfirm(lot) end)
	lot:GetAttributeChangedSignal("OwnerId"):Connect(function() applyMove(prompt, lot) end)
	prompt.Destroying:Connect(function() movePrompts[prompt] = nil end)
	applyMove(prompt, lot)
end
player:GetAttributeChangedSignal("OrchardLot"):Connect(function()
	for prompt, lot in pairs(movePrompts) do applyMove(prompt, lot) end
end)

-- ============ ปุ่ม "ขโมย" (เฟส 3, 2026-10-26) ============
-- เห็นเฉพาะตอน: เซิร์ฟบอก CanSteal (ต้นสุก ยังไม่โดนขโมยรอบนี้) + เป็นต้นคนอื่น + เราถือมือขโมยอยู่ (เซิร์ฟตรวจซ้ำทุกอย่าง)
local stealPrompts = {} -- [prompt] = lot

-- คืน ถือตะกร้อไหม, tier ของตะกร้อ (nil = ธรรมดา / "Bandit" = จอมโจร 2026-11-02)
local function holdingHand()
	local t = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	if t ~= nil and t:GetAttribute("IsStealHand") == true then return true, t:GetAttribute("StealTier") end
	return false, nil
end

local function applySteal(prompt, lot, holding, tier)
	-- เวลากดค้างตามตะกร้อที่ถือ (เซิร์ฟตั้งค่าตะกร้อธรรมดา เซิร์ฟเช็กเวลาจริงตามตะกร้อที่ถือเหมือนกัน)
	local kind = prompt:GetAttribute("TreeKind")
	if holding and kind then
		local secs = Config.StealSeconds(kind, tier)
		if prompt.HoldDuration ~= secs then prompt.HoldDuration = secs end
	end
	local owner = lot:GetAttribute("OwnerId")
	local selfTest = RunService:IsStudio() and workspace:GetAttribute("DevOrchardSelfSteal") == true -- ทดสอบคนเดียวใน Studio
	local show = holding and prompt:GetAttribute("CanSteal") == true and owner ~= nil and (owner ~= player.UserId or selfTest)
	if prompt.Enabled ~= show then prompt.Enabled = show end
	local action = tr("ขโมย", "Steal")
	if prompt.ActionText ~= action then prompt.ActionText = action end
	if lang() == "en" then
		local obj = prompt.ObjectText
		for _, kind in ipairs(kinds) do
			obj = obj:gsub(Config.Trees[kind].NameTh, Config.Trees[kind].NameEn)
		end
		if obj ~= prompt.ObjectText then prompt.ObjectText = obj end
	end
end

local function hookSteal(prompt)
	if stealPrompts[prompt] or not (prompt:IsA("ProximityPrompt") and prompt.Name == "StealPrompt") then return end
	local lot = prompt:FindFirstAncestorWhichIsA("Model")
	if not lot then return end
	stealPrompts[prompt] = lot
	prompt.Destroying:Connect(function() stealPrompts[prompt] = nil end)
	local holding, tier = holdingHand()
	applySteal(prompt, lot, holding, tier)
end

-- ============ ขอบขาวรอบต้นของเรา (ผู้ใช้สั่ง 2026-11-07) ============
-- เห็นเฉพาะเจ้าของ ไม่ระบายทับต้น เห็นทะลุต้นอื่น ระยะเท่าป้ายแปลงของฉัน · KeepFx = กราฟิกต่ำยังเห็น (GraphicsQuality ปิด Highlight ทั้งฉาก)
local MY_OUTLINE_RANGE = 220
local myOutlines = {} -- [model] = Highlight
task.spawn(function()
	while true do
		task.wait(0.5)
		local want = {}
		local name = player:GetAttribute("OrchardLot")
		local zone = workspace:FindFirstChild("Orchard")
		local lotsFolder = zone and zone:FindFirstChild("Lots")
		local lot = lotsFolder and name and lotsFolder:FindFirstChild(name)
		local trees = lot and lot:FindFirstChild("Trees")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if trees and root then
			for _, m in ipairs(trees:GetChildren()) do
				if m:IsA("Model") and m:GetAttribute("OwnerId") == player.UserId then
					local ok, pivot = pcall(m.GetPivot, m)
					if ok and (pivot.Position - root.Position).Magnitude <= MY_OUTLINE_RANGE then want[m] = true end
				end
			end
		end
		for m, h in pairs(myOutlines) do
			if not want[m] or not m.Parent then h:Destroy() myOutlines[m] = nil end
		end
		for m in pairs(want) do
			if not myOutlines[m] then
				local h = Instance.new("Highlight")
				h.Name = "MyTreeOutline"
				h:SetAttribute("KeepFx", true)
				h.FillTransparency = 1
				h.OutlineColor = Color3.new(1, 1, 1)
				h.OutlineTransparency = 0
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Adornee = m
				h.Parent = m
				myOutlines[m] = h
			end
		end
	end
end)

-- (กรอบเหลือง Highlight รอบต้นแห้งที่รอเพื่อนช่วย ลบออก 2026-11-07 ผู้ใช้สั่ง ต้นแห้งเป็นไม้แห้งธรรมดา)

-- ============ ปุ่มช่วยต้นแห้ง (2026-11-02) ============
-- เซิร์ฟตั้ง CanHelp (ต้นแห้งที่ยังไม่เคยฟื้น) · เจ้าของ = "ขอความช่วยเหลือ" กดทีเดียว · คนอื่น = "รดน้ำช่วย" กดค้าง (เซิร์ฟตรวจซ้ำ)
local helpPrompts = {} -- [prompt] = lot
local function applyHelp(prompt, lot)
	local owner = lot:GetAttribute("OwnerId")
	local show = prompt:GetAttribute("CanHelp") == true and owner ~= nil
	if prompt.Enabled ~= show then prompt.Enabled = show end
	if not show then return end
	local mine = owner == player.UserId
	local action = mine and tr("ขอความช่วยเหลือ 🙏", "Ask for help 🙏") or tr("รดน้ำช่วย 💚", "Water it 💚")
	if prompt.ActionText ~= action then prompt.ActionText = action end
	local hold = mine and 0 or Config.DeadTree.HelpSeconds
	-- ขี่ช้างน้อยใจบุญ (MountConfig HelpHoldScale) = กดค้างสั้นลง (2026-11-03 เซิร์ฟเช็กเวลาเดียวกัน)
	local riding = player:GetAttribute("RidingMount")
	if not mine and type(riding) == "string" and riding ~= "" then
		local okM, MountConfig = pcall(require, ReplicatedStorage:FindFirstChild("MountConfig"))
		local mdef = okM and MountConfig and MountConfig.Mounts[riding]
		if mdef and mdef.HelpHoldScale then hold *= mdef.HelpHoldScale end
	end
	if prompt.HoldDuration ~= hold then prompt.HoldDuration = hold end
	if lang() == "en" then
		local obj = prompt.ObjectText:gsub("แห้ง$", "")
		for _, kind in ipairs(kinds) do
			obj = obj:gsub(Config.Trees[kind].NameTh, "Dead " .. Config.Trees[kind].NameEn:lower())
		end
		if obj ~= prompt.ObjectText then prompt.ObjectText = obj end
	end
end
local function hookHelp(prompt)
	if helpPrompts[prompt] or not (prompt:IsA("ProximityPrompt") and prompt.Name == "HelpPrompt") then return end
	local lot = prompt:FindFirstAncestorWhichIsA("Model")
	if not lot then return end
	helpPrompts[prompt] = lot
	prompt.Destroying:Connect(function() helpPrompts[prompt] = nil end)
	applyHelp(prompt, lot)
end

task.spawn(function()
	while true do
		task.wait(0.3)
		local holding, tier = holdingHand()
		for prompt, lot in pairs(stealPrompts) do applySteal(prompt, lot, holding, tier) end
		for prompt, lot in pairs(helpPrompts) do applyHelp(prompt, lot) end
		for prompt, lot in pairs(prompts) do
			if prompt:GetAttribute("State") == "grow" then applyPrompt(prompt, lot) end -- ถือ/เก็บปุ๋ย = เปลี่ยนคำบนปุ่ม
		end
	end
end)

local function watchZone(zone)
	local lots = zone:WaitForChild("Lots", 30)
	if not lots then return end
	lots.DescendantAdded:Connect(function(d)
		if d:IsA("Model") and d.Parent and d.Parent.Name == "Trees" then task.spawn(hookTree, d) end
		if d:IsA("ProximityPrompt") then task.defer(hookPrompt, d) task.defer(hookSteal, d) task.defer(hookHelp, d) task.defer(hookMove, d) end
	end)
	for _, d in ipairs(lots:GetDescendants()) do
		if d:IsA("Model") and d.Parent and d.Parent.Name == "Trees" then task.spawn(hookTree, d) end
		if d:IsA("ProximityPrompt") then hookPrompt(d) hookSteal(d) hookHelp(d) hookMove(d) end
	end
end
local zone = workspace:FindFirstChild("Orchard")
if zone then
	task.spawn(watchZone, zone)
else
	local conn
	conn = workspace.ChildAdded:Connect(function(c)
		if c.Name == "Orchard" then conn:Disconnect() watchZone(c) end
	end)
end

task.spawn(function()
	while true do
		task.wait(1)
		for model, l in pairs(labels) do
			if model.Parent then updateLabel(model, l) else labels[model] = nil end
		end
	end
end)

-- ============ แจ้งเตือนขโมย + ตบ (เฟส 4, 2026-10-27) ============
-- เซิร์ฟยิง OrchardAlert: "start" (ถึงเจ้าของ) = กรอบแดง + ป้าย 🚨 เหนือหัวคนขโมย มองทะลุสิ่งของ · "stop" = เอาออก · "stun" (ถึงคนขโมย) = ล้ม N วิ
local alertRemote = remoteEvents:WaitForChild("OrchardAlert", 30)
local marks = {} -- [thief] = { highlight, billboard, expires }

local function clearMark(thief)
	local m = marks[thief]
	if not m then return end
	marks[thief] = nil
	if m.highlight then m.highlight:Destroy() end
	if m.billboard then m.billboard:Destroy() end
end

local function markThief(thief)
	-- Model = คนขโมยปลอม (Studio, OrchardDev "fakethief")
	local char = typeof(thief) == "Instance" and (thief:IsA("Player") and thief.Character or (thief:IsA("Model") and thief))
	if not char then return end
	clearMark(thief)
	local hl = Instance.new("Highlight")
	hl.Name = "OrchardThiefMark"
	hl.FillColor = Color3.fromRGB(255, 60, 60)
	hl.FillTransparency = 0.65
	hl.OutlineColor = Color3.fromRGB(255, 40, 40)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char
	hl.Parent = char
	local head = char:FindFirstChild("Head")
	local bb = Instance.new("BillboardGui")
	bb.Name = "OrchardThiefSign"
	bb.Size = UDim2.fromOffset(170, 64)
	bb.StudsOffset = Vector3.new(0, 3.6, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = head or char:FindFirstChild("HumanoidRootPart")
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(255, 70, 60)
	l.TextStrokeTransparency = 0.2
	l.Text = tr("🚨 ขโมย!", "🚨 Thief!") .. "\n⬇️"
	l.Parent = bb
	bb.Parent = playerGui
	marks[thief] = { highlight = hl, billboard = bb, expires = os.clock() + 70 }
	-- ป้ายกะพริบให้สะดุดตา
	task.spawn(function()
		local on = true
		while marks[thief] and marks[thief].billboard == bb do
			on = not on
			l.TextTransparency = on and 0 or 0.35
			task.wait(0.4)
		end
	end)
end

local function stunSelf(seconds, from)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) then return end
	hum.PlatformStand = true
	local fromRoot = typeof(from) == "Instance" and from:IsA("Player") and from.Character and from.Character:FindFirstChild("HumanoidRootPart")
	local fromPos = typeof(from) == "Vector3" and from or (fromRoot and fromRoot.Position) -- Vector3 = ยามเฝ้าสวนปลอม (Studio)
	local dir = fromPos and (root.Position - fromPos) or -root.CFrame.LookVector
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then dir = -root.CFrame.LookVector end
	root.AssemblyLinearVelocity = dir.Unit * 28 + Vector3.new(0, 22, 0)
	root.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
	task.delay(tonumber(seconds) or 5, function()
		if hum.Parent then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- ============ ป๊อปแจ้งเตือนขโมยกลางจอ (2026-10-28 ผู้ใช้สั่ง) ============
-- เจ้าของได้ "start" = การ์ดแดงเด้งกลางจอ + เสียงติ๊งต่องเบาๆ · ปุ่ม "ไม่สนใจ" / "วาร์ปไปทันที" (OrchardRequest "warpKeeper" ไปหน้าร้านป้าแตงไทย)
-- เสียงไม่ใส่ SoundGroup = ไม่อยู่ในระบบปรับ/ปิดเสียงของเกม (ผู้ใช้สั่งให้ปิดไม่ได้) ความดังคงที่ ALERT_VOLUME
local TweenService = game:GetService("TweenService")
local ALERT_SOUND_ID = "rbxassetid://6148388066" -- Chime (Creator Store ฟรี)
local ALERT_VOLUME = 0.4
-- ป๊อปค้างเท่าเวลากดค้างขโมย (Config.Steal.Seconds[ชนิดต้น]) · คนขโมยเลิก/สำเร็จ/โดนตบ ("stop") = ปิดทันที
local stealPopup -- ScreenGui ที่เปิดอยู่

local alertSound = Instance.new("Sound")
alertSound.Name = "OrchardStealChime"
alertSound.SoundId = ALERT_SOUND_ID
alertSound.Volume = ALERT_VOLUME
alertSound.Parent = script

local function closeStealPopup()
	if stealPopup then stealPopup:Destroy(); stealPopup = nil end
end

-- ดุ๊งดิ๊ง 3 ครั้ง (ต่ำ-สูง) แต่ละเสียงเป็น Sound แยก เล่นซ้อนกันได้ไม่ตัดกัน
local DING_DONG = { 0.8, 1.2 } -- PlaybackSpeed ดุ๊ง / ดิ๊ง
local DING_GAP, DING_PAIR_GAP, DING_TIMES = 0.28, 0.75, 3
local function playDingDong(gui)
	task.spawn(function()
		for i = 1, DING_TIMES do
			for j, speed in ipairs(DING_DONG) do
				if stealPopup ~= gui then return end
				local s = alertSound:Clone()
				s.Volume = ALERT_VOLUME
				s.PlaybackSpeed = speed
				s.Parent = script
				s:Play()
				task.delay(3, function() s:Destroy() end)
				task.wait(j < #DING_DONG and DING_GAP or DING_PAIR_GAP)
			end
		end
	end)
end

local function showStealPopup(data)
	closeStealPopup()
	local popupSeconds = tonumber(data.seconds) or (data.kind and Config.Steal and Config.Steal.Seconds and Config.Steal.Seconds[data.kind]) or 25 -- data.seconds = ตามตะกร้อที่คนขโมยถือ (2026-11-02)
	local thief = data.thief
	local thiefName = typeof(thief) == "Instance" and (thief:IsA("Player") and thief.DisplayName or thief:GetAttribute("DisplayName")) or "?"
	local def = data.kind and Config.Trees[data.kind]
	local fruit = def and tr(def.NameTh, def.NameEn) or tr("ต้นไม้", "tree")
	local lotNo = tostring(data.lot or ""):match("%d+")

	local gui = Instance.new("ScreenGui")
	gui.Name = "OrchardStealAlert"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60
	gui.Parent = playerGui
	stealPopup = gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.42)
	card.Size = UDim2.fromOffset(340, 196)
	card.BackgroundColor3 = Color3.fromRGB(235, 70, 85)
	card.Parent = gui
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 24); cc.Parent = card
	local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(255, 255, 255); cs.Thickness = 4; cs.Parent = card
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(255, 120, 130), Color3.fromRGB(225, 50, 70))
	grad.Rotation = 90
	grad.Parent = card
	local scale = Instance.new("UIScale"); scale.Scale = 0.4; scale.Parent = card

	local function text(str, size, y, h, font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(14, y)
		l.Size = UDim2.new(1, -28, 0, h)
		l.Font = font or Enum.Font.FredokaOne
		l.Text = str
		l.TextColor3 = Color3.fromRGB(255, 255, 255)
		l.TextScaled = true
		l.TextWrapped = true
		local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(150, 25, 45); st.Thickness = 1.5; st.Parent = l
		local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = size; c.Parent = l
		l.Parent = card
		return l
	end
	local title = text(tr("🚨 มีคนมาขโมย! 🚨", "🚨 Thief alert! 🚨"), 30, 12, 38)
	text(string.format(tr("%s กำลังสอย%sของคุณ", "%s is picking your %s"), thiefName, fruit), 19, 54, 24, Enum.Font.GothamBold)
	if lotNo then
		text(string.format(tr("ล็อก %s · หลุม %s", "Lot %s · hole %s"), lotNo, tostring(data.hole or "?")), 15, 80, 20, Enum.Font.GothamMedium)
	end

	local function button(str, bg, fg, x)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.new(x, 0, 1, -16)
		b.Size = UDim2.new(0.5, -22, 0, 50)
		b.BackgroundColor3 = bg
		b.Font = Enum.Font.FredokaOne
		b.Text = str
		b.TextColor3 = fg
		b.TextScaled = true
		b.Parent = card
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = b
		local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(150, 25, 45); s.Thickness = 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = b
		local t = Instance.new("UITextSizeConstraint"); t.MaxTextSize = 20; t.Parent = b
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 6); p.PaddingRight = UDim.new(0, 6); p.Parent = b
		return b
	end
	local ignore = button(tr("ไม่สนใจ", "Ignore"), Color3.fromRGB(255, 245, 245), Color3.fromRGB(200, 60, 75), 0.27)
	local warp = button(tr("🌀 วาร์ปไปทันที", "🌀 Warp now"), Color3.fromRGB(255, 214, 90), Color3.fromRGB(110, 60, 20), 0.73)
	ignore.Activated:Connect(closeStealPopup)
	local warping = false
	warp.Activated:Connect(function()
		if warping then return end
		warping = true
		warp.Text = "…"
		pcall(function() requestRemote:InvokeServer("warpKeeper") end)
		if stealPopup == gui then closeStealPopup() end
	end)
	if UserInputService:GetLastInputType().Name:match("^Gamepad") then GuiService.SelectedObject = warp end

	-- เด้งเข้า + ส่ายเบาๆ ให้สะดุดตา แต่ไม่น่าตกใจ
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.spawn(function()
		local t0 = os.clock()
		while stealPopup == gui do
			local t = os.clock() - t0
			card.Rotation = (t < 1.2) and math.sin(t * 28) * 3 * (1 - t / 1.2) or 0
			title.TextTransparency = (math.floor(t * 2.5) % 2 == 0) and 0 or 0.25
			if t > popupSeconds then closeStealPopup() break end
			task.wait()
		end
	end)

	playDingDong(gui)
end

-- ============ ขอความช่วยเหลือในแชท (2026-11-07 ผู้ใช้สั่ง แบบประกาศปลาลับ GachaAnnouncer) ============
-- เซิร์ฟยิง "helpchat" { owner = ชื่อที่แสดง } ถึงทุกเครื่อง = ข้อความระบบตัวหนาสีเขียวใน RBXGeneral
--   ข้อความของเกม ไม่ใช่ผู้เล่นพิมพ์ = ทุกคนทุกอายุเห็น ไม่ติดกฎแชท/การกรอง · เซิร์ฟจำกัด 1 ครั้งทุก 10 วิ ทั้งเซิร์ฟ
local TextChatService = game:GetService("TextChatService")
local HELP_CHAT_COLOR = "#7CFF8A"
local function escapeRich(t)
	return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end
local function helpChat(data)
	local text = string.format('<font color="%s"><b>💚 %s: %s</b></font>', HELP_CHAT_COLOR, escapeRich(data.owner or "?"),
		tr("🙏 ใครว่างช่วยรดน้ำให้หน่อย", "🙏 Can someone help water my tree?"))
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then general:DisplaySystemMessage(text) end
	end)
end

-- ============ เอฟเฟกต์ตบด้วยมือตบ (2026-10-29 ผู้ใช้สั่ง แบบค้อนยางตีตู้สุ่ม) ============
-- เซิร์ฟฟาดท่า Slash ให้เอง (OrchardService.onSlapSwing) ตบโดน = ยิง "slapfx" { owner, target = ตัวคนขโมย (Model) } ถึงทุกเครื่อง
-- → เสียงตบ + ToyHammerFx.Effects (เสียงบีบ/BOING + ดาวกระเด็น + คำ "โป๊ก!") ที่หัวคนโดนตบ · ตัวคนตบหันหน้าเข้าหา
local ToyHammerFx = require(ReplicatedStorage:WaitForChild("ToyHammerFx"))
local SLAP_SOUND_ID = "rbxassetid://511340819" -- "Slap" (Creator Store ฟรี)
local SLAP_SOUND_VOLUME = 0.8
local function playSlapFx(ownerChar, target)
	if not (typeof(target) == "Instance" and target.Parent) then return end
	local goalPart = target:FindFirstChild("Head") or target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart")
	if not goalPart then return end
	if ownerChar and ownerChar == player.Character then
		local root = ownerChar:FindFirstChild("HumanoidRootPart")
		if root then
			local flat = Vector3.new(goalPart.Position.X, root.Position.Y, goalPart.Position.Z)
			if (flat - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, flat) end
		end
	end
	local s = Instance.new("Sound")
	s.SoundId = SLAP_SOUND_ID
	s.Volume = SLAP_SOUND_VOLUME
	s.RollOffMaxDistance = 80
	s.Parent = goalPart
	s:Play()
	task.delay(2, function() s:Destroy() end)
	ToyHammerFx.Effects(goalPart.Position + Vector3.new(0, 0.5, 0))
end

if alertRemote then
	alertRemote.OnClientEvent:Connect(function(kind, data)
		data = type(data) == "table" and data or {}
		if kind == "slapfx" then
			local owner = data.owner
			local ownerChar = typeof(owner) == "Instance" and owner:IsA("Player") and owner.Character
			playSlapFx(ownerChar, data.target, true)
			return
		end
		if kind == "helpchat" then
			helpChat(data)
			return
		end
		if kind == "start" then
			markThief(data.thief)
			showStealPopup(data)
		elseif kind == "stop" then
			clearMark(data.thief)
			closeStealPopup()
		elseif kind == "stun" then
			stunSelf(data.seconds, data.from)
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(1)
		for thief, m in pairs(marks) do
			if os.clock() > m.expires or not thief.Parent or not (m.highlight and m.highlight.Parent) then clearMark(thief) end
		end
	end
end)

-- ============ ท่าสอยผลไม้ระหว่างขโมย (2026-10-27) ============
-- เซิร์ฟตั้ง Attribute OrchardPickAt (ตำแหน่งหลุม) ที่ตัวคนขโมยระหว่างกดค้าง · ทุกเครื่องทับท่าแขนขวา (ยกตะกร้อชี้เข้าพุ่มใบ กระทุ้งขึ้นลง + ส่ายข้อมือ) หลังแอนิเมชันทุกเฟรม
--   ข้อต่อ R15 ของเกมนี้เป็น AnimationConstraint แก้ Attachment ไม่มีผล ต้องคูณ Transform ใน PreSimulation (ทำบนเครื่องทุกคน เพราะค่านี้ไม่ส่งต่อกัน)
--   คนขโมยเอง: หันหน้าเข้าต้น + ปิด AutoRotate จนเลิกขโมย · R6 ไม่มีข้อต่อชื่อนี้ = ไม่ขยับแขน
local PICK_SHOULDER, PICK_WRIST = 38, -74 -- องศาท่าหลัก (วัดใน Play กับตัวละครสูง: ปลายไม้สูงจากเท้า ~13-14 ห่างไปข้างหน้า ~7-8 = บนพุ่มมะม่วงสูง 13 · 45/-65 สูงเกินยอดต้น)
local PICK_HZ = 1.3 -- กระทุ้งกี่ครั้งต่อวินาที
local picking = {} -- [character] = { t0, w } (w = น้ำหนักท่า 0..1 ค่อยๆ ยก/ลดแขน)
-- ท่าเอื้อมมือหยิบผลตอนเก็บเกี่ยว (ผู้ใช้สั่ง 2026-11-02): เซิร์ฟตั้ง Attribute OrchardHarvestAt (ตำแหน่งหลุม) ระหว่างกดค้าง + หลังเก็บอีกนิด
--   แขนขวายกสูงเข้าพุ่มใบ มือกำแบบดึงผล (ไม่ต้องถืออะไร) · ต้นโยกเยกทำฝั่งเซิร์ฟ (OrchardService.swayTree)
local REACH_SHOULDER, REACH_WRIST, REACH_HZ = 150, -25, 2.4
local reaching = {} -- [character] = { t0, w }
-- ท่าปลูก (ผู้ใช้สั่ง 2026-11-02): เซิร์ฟตั้ง Attribute OrchardPlantAt ~1 วิ → ก้มตัว (เอว) + ย่อเข่า + แขนขวาเอื้อมลงหลุม (เซิร์ฟทำเมล็ดหล่น + ดินฟุ้ง)
local PLANT_WAIST, PLANT_SHOULDER, PLANT_HIP, PLANT_KNEE = -38, 45, 30, -45
local planting = {} -- [character] = { w }
local faced -- { char, hum, autoRotate } ตัวเราตอนหันเข้าต้นอยู่
-- ฟาดมือตบตอนขี่สัตว์ (ผู้ใช้สั่ง 2026-11-03): ท่านั่งสัตว์ขี่ (SitAnim ความสำคัญ Action4) ทับท่าฟาด ToolSlashAnim (Action) เลยมองไม่เห็นแขนขยับ
--   เซิร์ฟใส่ StringValue "toolanim" = "Slash" ในมือตบทุกครั้งที่ฟาด → ทุกเครื่องยกแขนขวาฟาดลงเอง 0.45 วิ (ท่าเดียวกับยามปลอม) เฉพาะคนที่กำลังขี่อยู่
local riderSlap = {} -- [character] = os.clock() ตอนเริ่มฟาด
workspace.DescendantAdded:Connect(function(d)
	if not (d:IsA("StringValue") and d.Name == "toolanim" and d.Value == "Slash") then return end
	local tool = d.Parent
	if not (tool and tool:IsA("Tool") and tool:GetAttribute("IsSlapHand") == true) then return end
	local plr = Players:GetPlayerFromCharacter(tool.Parent)
	if plr and plr:GetAttribute("RidingMount") then riderSlap[tool.Parent] = os.clock() end
end)

local function rigJoint(ch, partName, jointName)
	local part = ch:FindFirstChild(partName)
	return part and part:FindFirstChild(jointName)
end

RunService.PreSimulation:Connect(function(dt)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local pickAt = ch and ch:GetAttribute("OrchardPickAt")
		local tool = ch and ch:FindFirstChildWhichIsA("Tool")
		local on = typeof(pickAt) == "Vector3" and tool ~= nil and tool:GetAttribute("IsStealHand") == true
		local st = ch and picking[ch]
		if on and not st then
			st = { t0 = os.clock(), w = 0 }
			picking[ch] = st
		end
		if st then
			st.w = math.clamp(st.w + (on and dt or -dt) * 4, 0, 1)
			if st.w <= 0 then
				picking[ch] = nil
			else
				local ph = (os.clock() - st.t0) * PICK_HZ * math.pi * 2
				local sh = rigJoint(ch, "RightUpperArm", "RightShoulder")
				local wr = rigJoint(ch, "RightHand", "RightWrist")
				if sh then sh.Transform = sh.Transform * CFrame.Angles(math.rad((PICK_SHOULDER + 12 * math.sin(ph)) * st.w), 0, 0) end
				if wr then wr.Transform = wr.Transform * CFrame.Angles(math.rad((PICK_WRIST + 8 * math.sin(ph * 2)) * st.w), 0, 0) end
			end
		end
	end
	for ch in pairs(picking) do
		if not ch.Parent then picking[ch] = nil end
	end
	-- เอื้อมมือหยิบผล (ทุกคนที่กำลังเก็บเกี่ยว)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local on = ch ~= nil and typeof(ch:GetAttribute("OrchardHarvestAt")) == "Vector3"
		local st = ch and reaching[ch]
		if on and not st then
			st = { t0 = os.clock(), w = 0 }
			reaching[ch] = st
		end
		if st then
			st.w = math.clamp(st.w + (on and dt or -dt) * 5, 0, 1)
			if st.w <= 0 then
				reaching[ch] = nil
			else
				local ph = (os.clock() - st.t0) * REACH_HZ * math.pi * 2
				local sh = rigJoint(ch, "RightUpperArm", "RightShoulder")
				local el = rigJoint(ch, "RightLowerArm", "RightElbow")
				local wr = rigJoint(ch, "RightHand", "RightWrist")
				if sh then sh.Transform = sh.Transform * CFrame.Angles(math.rad((REACH_SHOULDER + 8 * math.sin(ph)) * st.w), 0, math.rad(-10 * st.w)) end
				if el then el.Transform = el.Transform * CFrame.Angles(math.rad((12 + 14 * math.max(0, math.sin(ph))) * st.w), 0, 0) end
				if wr then wr.Transform = wr.Transform * CFrame.Angles(math.rad((REACH_WRIST + 20 * math.sin(ph * 2)) * st.w), 0, 0) end
			end
		end
	end
	for ch in pairs(reaching) do
		if not ch.Parent then reaching[ch] = nil end
	end
	-- ก้มลงปลูกเมล็ด (ทุกคนที่กำลังปลูก)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local on = ch ~= nil and typeof(ch:GetAttribute("OrchardPlantAt")) == "Vector3"
		local st = ch and planting[ch]
		if on and not st then
			st = { w = 0 }
			planting[ch] = st
		end
		if st then
			st.w = math.clamp(st.w + (on and dt or -dt) * 6, 0, 1)
			if st.w <= 0 then
				planting[ch] = nil
			else
				local w = st.w
				local waist = rigJoint(ch, "UpperTorso", "Waist")
				local sh = rigJoint(ch, "RightUpperArm", "RightShoulder")
				local lh, rh = rigJoint(ch, "LeftUpperLeg", "LeftHip"), rigJoint(ch, "RightUpperLeg", "RightHip")
				local lk, rk = rigJoint(ch, "LeftLowerLeg", "LeftKnee"), rigJoint(ch, "RightLowerLeg", "RightKnee")
				if waist then waist.Transform = waist.Transform * CFrame.Angles(math.rad(PLANT_WAIST * w), 0, 0) end
				if sh then sh.Transform = sh.Transform * CFrame.Angles(math.rad(PLANT_SHOULDER * w), 0, 0) end
				for _, j in ipairs({ lh, rh }) do j.Transform = j.Transform * CFrame.Angles(math.rad(PLANT_HIP * w), 0, 0) end
				for _, j in ipairs({ lk, rk }) do j.Transform = j.Transform * CFrame.Angles(math.rad(PLANT_KNEE * w), 0, 0) end
			end
		end
	end
	for ch in pairs(planting) do
		if not ch.Parent then planting[ch] = nil end
	end
	-- ยามเฝ้าสวนปลอม (Studio, OrchardDev "fakeowner"): เซิร์ฟตั้ง SlapAt = เวลาเซิร์ฟ -> ยกแขนขวาสูงแล้วฟาดลง 0.45 วิ
	local guard = workspace:FindFirstChild("OrchardFakeGuard")
	local slapAt = guard and guard:GetAttribute("SlapAt")
	if slapAt then
		local age = workspace:GetServerTimeNow() - slapAt
		local sh = age < 0.45 and rigJoint(guard, "RightUpperArm", "RightShoulder")
		if sh then
			local a = age < 0.15 and (age / 0.15) * 160 or 160 - ((age - 0.15) / 0.3) * 200
			sh.Transform = sh.Transform * CFrame.Angles(math.rad(a), 0, math.rad(-25))
		end
	end
	-- ฟาดมือตบตอนขี่สัตว์ (ดู riderSlap)
	for rch, t0 in pairs(riderSlap) do
		local age = os.clock() - t0
		local sh = rch.Parent and age < 0.45 and rigJoint(rch, "RightUpperArm", "RightShoulder")
		if sh then
			local a = age < 0.15 and (age / 0.15) * 160 or 160 - ((age - 0.15) / 0.3) * 200
			sh.Transform = sh.Transform * CFrame.Angles(math.rad(a), 0, math.rad(-25))
		else
			riderSlap[rch] = nil
		end
	end
	-- ตัวเรา: หันหน้าเข้าต้นครั้งเดียวตอนเริ่ม แล้วไม่ให้ตัวหมุนตามทางเดินจนเลิกขโมย
	local ch = player.Character
	local pickAt = ch and (ch:GetAttribute("OrchardPickAt") or ch:GetAttribute("OrchardHarvestAt") or ch:GetAttribute("OrchardPlantAt")) -- เก็บเกี่ยว/ปลูกก็หันเข้าหลุม (2026-11-02)
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if typeof(pickAt) == "Vector3" and hum and root then
		if not faced or faced.char ~= ch then
			faced = { char = ch, hum = hum, autoRotate = hum.AutoRotate }
			hum.AutoRotate = false
			local flat = Vector3.new(pickAt.X, root.Position.Y, pickAt.Z)
			if (flat - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, flat) end
		end
	elseif faced then
		if faced.hum.Parent then faced.hum.AutoRotate = faced.autoRotate end
		faced = nil
	end
end)

-- ปุ่ม "ตบ" ที่ตัวคนขโมย: เห็นเฉพาะเจ้าของต้น (Attribute OwnerId) เซิร์ฟเช็กซ้ำ
-- มือตบ (2026-10-29): เซิร์ฟตั้งระยะปุ่ม = ไกลสุด เครื่องเราลดเหลือ SlapRange ตอนไม่ได้ถือมือตบ (ถือ = SlapHandRange) · เซิร์ฟเช็กระยะซ้ำ
local slapPrompts = {}
local function holdingSlapHand()
	local t = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	return t ~= nil and t:GetAttribute("IsSlapHand") == true
end
-- 2026-10-29: ถือมือตบ = ไม่มีปุ่ม F (ผู้ใช้สั่ง ให้คลิกเหวี่ยงเอง กะระยะเอง) · มือเปล่า = ปุ่ม F ระยะ SlapRange
local function updateSlapRange()
	local holding = holdingSlapHand()
	for prompt in pairs(slapPrompts) do
		if prompt.Parent then
			prompt.Enabled = not holding
			prompt.MaxActivationDistance = Config.Steal.SlapRange
		else
			slapPrompts[prompt] = nil
		end
	end
end
local function hookSlap(prompt)
	if not (prompt:IsA("ProximityPrompt") and prompt.Name == "SlapPrompt") then return end
	prompt.Enabled = prompt:GetAttribute("OwnerId") == player.UserId
	prompt.ActionText = tr("👋 ตบ", "👋 Slap")
	if prompt.Enabled then
		slapPrompts[prompt] = true
		updateSlapRange()
	end
end
local function watchHeldTool(char)
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then updateSlapRange() end end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then updateSlapRange() end end)
end
if player.Character then watchHeldTool(player.Character) end
player.CharacterAdded:Connect(watchHeldTool)
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") and d.Name == "SlapPrompt" then task.defer(hookSlap, d) end
end)

-- ============ ถือเมล็ดแล้วคลิกที่หลุมเพื่อปลูก (2026-10-27 ผู้ใช้สั่ง แบบปลูกผัก) ============
-- ถือเมล็ดไม้ผล (IsOrchardSeed) คลิก/แตะที่หลุมว่าง (หรือใกล้หลุมไม่เกิน CLICK_REACH) -> OrchardRequest "plantHeld" { ล็อก, หลุม } เซิร์ฟตรวจและแจ้งผลเอง
-- ระหว่างถือเมล็ด หลุมว่างที่เล็งอยู่และปลูกได้ (ล็อกเรา หรือล็อกว่างตอนเรายังไม่มีล็อก) เรืองสีเขียว · ปุ่ม E ที่หลุมยังใช้ได้เหมือนเดิม
local CLICK_REACH = 4.5 -- คลิกห่างกลางหลุมได้ไม่เกิน (studs แนวนอน)
local mouse = player:GetMouse()

-- มือตบ: ฟาดแบบค้อนยาง ฝั่งเซิร์ฟจัดการเอง (Tool.Activated → OrchardService) ฝั่งนี้แค่ซ่อนปุ่ม F ตอนถือ (updateSlapRange) + เล่นเอฟเฟกต์ slapfx
local plantGlow = Instance.new("Highlight")
plantGlow.Name = "OrchardPlantGlow"
plantGlow.FillColor = Color3.fromRGB(120, 230, 120)
plantGlow.OutlineColor = Color3.fromRGB(255, 255, 255)
plantGlow.FillTransparency = 0.45
plantGlow.DepthMode = Enum.HighlightDepthMode.Occluded
plantGlow.Enabled = false
plantGlow.Parent = playerGui

local function heldSeed()
	local t = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	return (t and t:GetAttribute("IsOrchardSeed")) and t or nil
end

-- ล็อกที่เราปลูกได้ (เซิร์ฟเช็กซ้ำ)
local function lotAllowed(lot)
	local owner = lot:GetAttribute("OwnerId")
	return owner == player.UserId or (owner == nil and player:GetAttribute("OrchardLot") == nil)
end

-- หลุมที่เล็งอยู่ (ใกล้จุดที่เมาส์ชี้ที่สุด) คืน { lot, hole, part } หรือ nil
local function aimedHole()
	local zone = workspace:FindFirstChild("Orchard")
	local lots = zone and zone:FindFirstChild("Lots")
	local hit = mouse.Hit and mouse.Hit.Position
	if not (lots and hit) then return nil end
	local best, bestD
	for _, lot in ipairs(lots:GetChildren()) do
		for i = 1, Config.MAX_TREES do
			local h = lot:FindFirstChild("Hole" .. i)
			if h then
				local d = Vector3.new(h.Position.X - hit.X, 0, h.Position.Z - hit.Z).Magnitude
				if d <= CLICK_REACH and (not bestD or d < bestD) then best, bestD = { lot = lot, hole = i, part = h }, d end
			end
		end
	end
	return best
end

local function canPlantAt(target)
	local prompt = target and target.part:FindFirstChild("HolePrompt")
	return prompt ~= nil and prompt:GetAttribute("State") == "empty" and lotAllowed(target.lot)
end

RunService.RenderStepped:Connect(function()
	local target = heldSeed() and aimedHole()
	if target and canPlantAt(target) then
		plantGlow.Adornee = target.part:FindFirstChild("Soil") or target.part
		plantGlow.Enabled = true
	elseif plantGlow.Enabled then
		plantGlow.Enabled = false
		plantGlow.Adornee = nil
	end
end)

local planting = false
local function onSeedActivated(tool)
	if planting or not tool:GetAttribute("IsOrchardSeed") then return end
	local target = aimedHole()
	if not target then return end
	local prompt = target.part:FindFirstChild("HolePrompt")
	if not prompt or prompt:GetAttribute("State") ~= "empty" then return end -- คลิกหลุมที่มีต้นแล้ว = ไม่ทำอะไร
	planting = true
	task.spawn(function()
		pcall(function() requestRemote:InvokeServer("plantHeld", { target.lot.Name, target.hole }) end)
		planting = false
	end)
end

-- กันผูกซ้ำ (หยิบเมล็ดเดิมขึ้นมาถือใหม่ = ChildAdded ยิงอีก เหมือน SeedClickPlanter)
local hookedSeeds = {}
local function hookSeed(child)
	if not child:IsA("Tool") or hookedSeeds[child] then return end
	hookedSeeds[child] = true
	child.Destroying:Connect(function() hookedSeeds[child] = nil end)
	child.Activated:Connect(function() onSeedActivated(child) end)
end
local function hookCharacter(character)
	character.ChildAdded:Connect(hookSeed)
	for _, c in ipairs(character:GetChildren()) do hookSeed(c) end
end
if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)
