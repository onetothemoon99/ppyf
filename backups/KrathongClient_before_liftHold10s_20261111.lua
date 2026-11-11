-- Backup 2026-11-11 of StarterPlayer.StarterPlayerScripts.KrathongClient (LocalScript) before the 10 s hold-above-head sky lantern change.
-- To restore: paste everything below these 2 lines back into StarterPlayer.StarterPlayerScripts.KrathongClient.Source.
-- KrathongClient (2026-11-07): หน้าต่างร้านกระทง / หน้าต่างลอยกระทง (เลือกชนิด + คำอธิษฐาน) / กระทงลอยน้ำ (ทำบนเครื่องนี้เท่านั้น) / ป้ายเวลาบัฟ
-- คู่กับ ServerScriptService.Krathong.KrathongService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("KrathongConfig"))
local ItemPreview = require(ReplicatedStorage:WaitForChild("ItemPreview"))
local _, LANG = require(ReplicatedStorage:WaitForChild("Localization")).Tr()
local EN = LANG == "en"
local function tr(th, en) return EN and en or th end

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestRemote = remotes:WaitForChild("KrathongRequest")
local openRemote = remotes:WaitForChild("KrathongOpen")
local fxRemote = remotes:WaitForChild("KrathongFx")
local models = ReplicatedStorage:WaitForChild("KrathongModels")

local PINK = Color3.fromRGB(230, 110, 160)
local CREAM = Color3.fromRGB(255, 248, 235)
local BROWN = Color3.fromRGB(110, 70, 45)
local FONT = Enum.Font.FredokaOne

-- ============ ป้าย E ภาษาอังกฤษ (เซิร์ฟตั้งเป็นไทย) ============
if EN then
	local TEXT = {
		KrathongShopPrompt = { "🌸 Krathong Stall", "Buy krathong" },
		KrathongFloatPrompt = { "🌸 Krathong Dock", "Float krathong" },
		LanternPrompt = { "🏮 Lantern Field", "Release lantern" },
	}
	local SIGN = { ["🌸 ร้านกระทง 🌸"] = "🌸 Krathong Stall 🌸", ["🏮 ลานปล่อยโคม 🏮"] = "🏮 Lantern Field 🏮", ["🏮 ลานแขวนโคม 🏮"] = "🏮 Lantern Garden 🏮" }
	local function fix(p)
		local t = p:IsA("ProximityPrompt") and TEXT[p.Name]
		if t then p.ObjectText, p.ActionText = t[1], t[2] end
		if p:IsA("TextLabel") and SIGN[p.Text] then p.Text = SIGN[p.Text] end
	end
	workspace.DescendantAdded:Connect(fix)
	for _, name in ipairs({ "KrathongStall", "KrathongFloatSpot", "KrathongLanternField", "KrathongLanternGarden" }) do
		local m = workspace:FindFirstChild(name)
		if m then for _, d in ipairs(m:GetDescendants()) do fix(d) end end
	end
end

-- ============ UI พื้นฐาน ============
local gui = Instance.new("ScreenGui")
gui.Name = "KrathongGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 12) c.Parent = o return c end
local function stroke(o, col, th) local s = Instance.new("UIStroke") s.Color = col or BROWN s.Thickness = th or 2 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o return s end
local function label(parent, text, size, pos, color, scaled)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos or UDim2.new()
	l.Font = FONT
	l.Text = text
	l.TextColor3 = color or BROWN
	l.TextScaled = scaled ~= false
	l.Parent = parent
	return l
end
local function button(parent, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos or UDim2.new()
	b.BackgroundColor3 = color or PINK
	b.AutoButtonColor = true
	b.Font = FONT
	b.Text = text
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = parent
	corner(b, 10)
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 4) pad.PaddingLeft = UDim.new(0, 6) pad.PaddingRight = UDim.new(0, 6) pad.Parent = b
	return b
end

-- ข้อความเด้งสั้นๆ
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 90)
toast.Size = UDim2.new(0, 460, 0, 44)
toast.BackgroundColor3 = CREAM
toast.Font = FONT
toast.TextScaled = true
toast.TextColor3 = BROWN
toast.Visible = false
toast.ZIndex = 50
toast.Parent = gui
corner(toast, 12) stroke(toast, PINK, 2)
do local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 10) p.PaddingRight = UDim.new(0, 10) p.PaddingTop = UDim.new(0, 6) p.PaddingBottom = UDim.new(0, 6) p.Parent = toast end
local toastToken = 0
local function showToast(text)
	if not text or text == "" then return end
	toastToken += 1
	local my = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3.5, function() if toastToken == my then toast.Visible = false end end)
end

-- หน้าต่างหลัก (ใช้ทั้งร้านและลอย)
local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.new(0, 820, 0, 400) -- 5 การ์ด (เพิ่มโคมแขวน 2026-11-08)
window.BackgroundColor3 = CREAM
window.Visible = false
window.Parent = gui
corner(window, 18) stroke(window, BROWN, 3)
local uiScale = Instance.new("UIScale") uiScale.Parent = window
local function fitScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	uiScale.Scale = math.clamp(math.min((vp.X - 24) / 820, (vp.Y - 24) / 400), 0.4, 1.2)
end
fitScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale) end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = PINK
header.Parent = window
corner(header, 18)
local headerFill = Instance.new("Frame") headerFill.Size = UDim2.new(1, 0, 0, 18) headerFill.Position = UDim2.new(0, 0, 1, -18) headerFill.BackgroundColor3 = PINK headerFill.BorderSizePixel = 0 headerFill.Parent = header
local title = label(header, "", UDim2.new(1, -80, 0, 36), UDim2.new(0, 16, 0, 9), Color3.new(1, 1, 1))
title.TextXAlignment = Enum.TextXAlignment.Left
local closeBtn = button(header, "X", UDim2.new(0, 40, 0, 40), UDim2.new(1, -48, 0, 7), Color3.fromRGB(200, 80, 110))

local subtitle = label(window, "", UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 0, 62))
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 16, 0, 92)
body.Size = UDim2.new(1, -32, 1, -104)
body.Parent = window

local mode -- "shop" / "float"
local info = { counts = {} }
local busy = false
local render -- forward

local function close()
	window.Visible = false
	mode = nil
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(window) then GuiService.SelectedObject = nil end
end
closeBtn.Activated:Connect(close)
UserInputService.InputBegan:Connect(function(input)
	if window.Visible and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape) then close() end
end)
-- เดินห่างร้าน/ท่า = ปิดเอง
local openedAt
RunService.Heartbeat:Connect(function()
	if not window.Visible or not openedAt then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - openedAt).Magnitude > 22 then close() end
end)

local function clearBody()
	for _, c in ipairs(body:GetChildren()) do c:Destroy() end
end

local function buffText()
	local untilT = tonumber(info.buffUntil) or 0
	local left = untilT - os.time()
	if left <= 0 then return tr("ลอยกระทง = โชคปลาอีเวนต์ลอยกระทงเพิ่มชั่วคราว", "Float a krathong = more event fish for a while") end
	local pct = math.floor((tonumber(info.bonus) or 0) * 100 + 0.5)
	return tr("🌸 บัฟตอนนี้: โชคปลาอีเวนต์ +", "🌸 Active: event fish luck +") .. pct .. "% · " .. string.format("%d:%02d", left // 60, left % 60)
end

local function card(parent, id, x, w)
	local def = Config.Types[id]
	local c = Instance.new("Frame")
	c.Size = UDim2.new(0, w, 1, 0)
	c.Position = UDim2.new(0, x, 0, 0)
	c.BackgroundColor3 = def.Bg
	c.Parent = parent
	corner(c, 12) stroke(c, def.Strip, 2)
	local strip = Instance.new("Frame") strip.Size = UDim2.new(1, 0, 0, 28) strip.BackgroundColor3 = def.Strip strip.Parent = c corner(strip, 12)
	local name = label(strip, def.Icon .. " " .. Config.Name(id, LANG), UDim2.new(1, -10, 1, -6), UDim2.new(0, 5, 0, 3), Color3.new(1, 1, 1))
	local view = Instance.new("Frame") view.BackgroundTransparency = 1 view.Size = UDim2.new(1, -20, 0, 92) view.Position = UDim2.new(0, 10, 0, 32) view.Parent = c
	pcall(ItemPreview.Create, view, "Krathong_" .. id, 1.1)
	local owned = label(c, tr("มีอยู่ ", "Owned ") .. tostring(info.counts[id] or 0), UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, 128))
	local perkText = def.LuckMult and (tr("โชค +", "Luck +") .. math.floor((def.LuckMult - 1) * 100 + 0.5) .. "% · " .. def.BuffMinutes .. tr(" นาที", " min"))
		or (tr("โชคปลาอีเวนต์ +", "Event fish +") .. math.floor((def.EventBonus or 0) * 100) .. "% · " .. def.BuffMinutes .. tr(" นาที", " min"))
	local perk = label(c, perkText,
		UDim2.new(1, -10, 0, 18), UDim2.new(0, 5, 0, 150), Color3.fromRGB(150, 95, 60))
	return c, owned, perk
end

local function request(action, a, b, c)
	if busy then return end
	busy = true
	local ok, res = pcall(function() return requestRemote:InvokeServer(action, a, b, c) end)
	busy = false
	if not ok or type(res) ~= "table" then showToast(tr("เชื่อมต่อไม่ได้ ลองใหม่อีกครั้ง", "Connection problem, try again")) return nil end
	if res.info then info = res.info end
	showToast(res.message)
	return res
end

local hangPick = Config.TodayHang() -- สีโคมแขวนที่เลือกในร้าน (เปิดร้าน = สีของวันนี้)
local function renderShop()
	title.Text = tr("🌸 ร้านกระทงแม่ค้า", "🌸 Krathong Stall")
	subtitle.Text = tr("เก็บไว้ในกระเป๋า · กระทงลอยริมน้ำ · โคมลอยปล่อยได้ทุกที่ที่ฟ้าโล่ง · โคมแขวนแขวนที่ลานแขวนโคม", "Kept in your bag · float krathongs near water · release sky lanterns under any open sky · hang lanterns in the lantern garden")
	clearBody()
	local n, gap = #Config.Order, 10
	local w = math.floor((788 - gap * (n - 1)) / n)
	local first
	for i, id in ipairs(Config.Order) do
		if Config.IsHang(id) then id = hangPick end -- การ์ดโคมแขวน = สีที่เลือก (7 สีตามวัน)
		local def = Config.Types[id]
		local c, _, perk = card(body, id, (i - 1) * (w + gap), w)
		if Config.IsHang(id) then
			-- ปุ่มสี 7 วง ทับขอบล่างรูป · บรรทัดใต้จำนวน = ชื่อสี + วัน
			local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Size = UDim2.new(1, -10, 0, 18) row.Position = UDim2.new(0, 5, 0, 106) row.ZIndex = 3 row.Parent = c
			local lay = Instance.new("UIListLayout") lay.FillDirection = Enum.FillDirection.Horizontal lay.HorizontalAlignment = Enum.HorizontalAlignment.Center lay.Padding = UDim.new(0, 3) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = row
			local today = Config.TodayHang()
			for k, hid in ipairs(Config.HangIds) do
				local hdef = Config.Types[hid]
				local dot = Instance.new("TextButton")
				dot.LayoutOrder = k dot.Size = UDim2.new(0, 16, 0, 16) dot.Text = "" dot.AutoButtonColor = true
				dot.BackgroundColor3 = hdef.Lamp:Lerp(Color3.new(1, 1, 1), 0.15) dot.ZIndex = 3 dot.Parent = row
				corner(dot, 8)
				local st = stroke(dot, hid == id and Color3.fromRGB(255, 190, 60) or Color3.new(1, 1, 1), hid == id and 3 or 1.5)
				dot.Activated:Connect(function() hangPick = hid render() end)
			end
			perk.Text = def.Icon .. " " .. tr("สี" .. def.NameTh:gsub("^โคมแขวนสี", "") .. " · " .. def.DayTh, def.NameEn:gsub(" hanging lantern", "") .. " · " .. def.DayEn)
				.. (id == today and tr(" (สีวันนี้)", " (today)") or "")
		end
		local qty = 1
		local minus = button(c, "−", UDim2.new(0, 34, 0, 30), UDim2.new(0, 8, 0, 174), Color3.fromRGB(190, 150, 120))
		local q = label(c, "1", UDim2.new(0, 60, 0, 30), UDim2.new(0.5, -30, 0, 174))
		local plus = button(c, "+", UDim2.new(0, 34, 0, 30), UDim2.new(1, -42, 0, 174), Color3.fromRGB(190, 150, 120))
		local buy = button(c, "", UDim2.new(1, -16, 0, 44), UDim2.new(0, 8, 1, -52), def.Strip)
		local function refresh()
			q.Text = "x" .. qty
			buy.Text = tr("ซื้อ 💰", "Buy 💰") .. Config.Short(def.Price * qty)
		end
		refresh()
		minus.Activated:Connect(function() qty = qty <= 1 and 1 or (qty <= 5 and qty - 1 or qty - 5) refresh() end)
		plus.Activated:Connect(function() qty = math.min(Config.MAX_BUY, qty < 5 and qty + 1 or qty + 5) refresh() end)
		buy.Activated:Connect(function()
			local res = request("buy", id, qty)
			if res and res.ok then render() end
		end)
		first = first or buy
	end
	if UserInputService.GamepadEnabled and first then GuiService.SelectedObject = first end
end

local selectedId
local wishText = ""
local function renderFloat()
	title.Text = tr("🌸 ลอยกระทง", "🌸 Float a Krathong")
	subtitle.Text = buffText()
	clearBody()
	local ids = {}
	for _, id in ipairs(Config.Order) do if not Config.IsLantern(id) then table.insert(ids, id) end end
	local total = 0
	for _, id in ipairs(ids) do total += (info.counts[id] or 0) end
	if total <= 0 then
		local l = label(body, tr("ยังไม่มีกระทงเลย ซื้อได้ที่ร้านแม่ค้าหัวท่าน้ำนะ 🌸", "You have no krathong yet. Buy one at the stall at the start of the dock 🌸"),
			UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0.35, 0))
		return
	end
	if not selectedId or (info.counts[selectedId] or 0) <= 0 then
		selectedId = (info.held and (info.counts[info.held] or 0) > 0) and info.held or nil
		if not selectedId then for _, id in ipairs(ids) do if (info.counts[id] or 0) > 0 then selectedId = id break end end end
	end
	if selectedId and Config.IsLantern(selectedId) then selectedId = nil end
	local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Size = UDim2.new(1, 0, 0, 176) row.Parent = body
	local gap = 10
	local w = math.floor((788 - gap * (#ids - 1)) / #ids)
	for i, id in ipairs(ids) do
		local c = card(row, id, (i - 1) * (w + gap), w)
		local have = (info.counts[id] or 0) > 0
		local pick = Instance.new("TextButton") pick.BackgroundTransparency = 1 pick.Text = "" pick.Size = UDim2.fromScale(1, 1) pick.Parent = c
		if not have then
			-- ยังไม่มี = ทาบเทา + ป้าย
			local dim = Instance.new("Frame") dim.Size = UDim2.fromScale(1, 1) dim.BackgroundColor3 = Color3.fromRGB(240, 235, 230) dim.BackgroundTransparency = 0.35 dim.ZIndex = 5 dim.Parent = c corner(dim, 12)
			local tag = label(dim, tr("ยังไม่มี", "None yet"), UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0.4, 0), Color3.fromRGB(150, 120, 100))
			tag.ZIndex = 6
		end
		if id == selectedId then
			local s = c:FindFirstChildOfClass("UIStroke") s.Thickness = 5 s.Color = Color3.fromRGB(255, 190, 60)
		end
		pick.Activated:Connect(function()
			if have then selectedId = id render() end
		end)
	end
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -150, 0, 44)
	box.Position = UDim2.new(0, 0, 1, -48)
	box.BackgroundColor3 = Color3.new(1, 1, 1)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextScaled = true
	box.TextColor3 = BROWN
	box.PlaceholderText = tr("คำอธิษฐาน (ไม่ใส่ก็ได้)", "Your wish (optional)")
	box.Text = wishText
	box.Parent = body
	corner(box, 10) stroke(box, Color3.fromRGB(220, 190, 170), 2)
	do local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 10) p.PaddingRight = UDim.new(0, 10) p.PaddingTop = UDim.new(0, 8) p.PaddingBottom = UDim.new(0, 8) p.Parent = box end
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local t = box.Text
		local n = utf8.len(t)
		if n and n > Config.WISH_MAX then t = t:sub(1, utf8.offset(t, Config.WISH_MAX + 1) - 1) box.Text = t end
		wishText = t
	end)
	local go = button(body, tr("🌸 ลอยเลย", "🌸 Float"), UDim2.new(0, 140, 0, 44), UDim2.new(1, -140, 1, -48), PINK)
	go.Activated:Connect(function()
		if not selectedId then return end
		local res = request("float", selectedId, wishText)
		if res and res.ok then
			wishText = ""
			close()
		end
	end)
	if UserInputService.GamepadEnabled then GuiService.SelectedObject = go end
end

render = function()
	if mode == "shop" then renderShop() elseif mode == "float" then renderFloat() end
end

openRemote.OnClientEvent:Connect(function(kind, data)
	if kind == "toast" then showToast(data) return end
	if kind ~= "shop" and kind ~= "float" then return end
	info = type(data) == "table" and data or { counts = {} }
	info.counts = info.counts or {}
	mode = kind
	selectedId = nil
	hangPick = Config.TodayHang()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	openedAt = root and root.Position
	window.Visible = true
	render()
end)

-- ============ ป้ายเวลาบัฟ (มุมบนซ้าย แบบป้ายฝนตก 2026-11-07 ผู้ใช้สั่ง) ============
-- หน้าตาเดียวกับ WeatherClient.RainPill: ไม่มีพื้นหลัง/กรอบ ตัวหนังสือขาวขอบน้ำเงินเข้ม GothamBold 14 · ScreenGui แยกแบบ WeatherGui (DeviceSafeInsets)
-- ไม่ทับป้ายอื่นมุมบนซ้าย: ป้ายฝน (WeatherGui.RainPill y 64) / ป้ายอีเวนต์เก็บขยะ "Help the otter" (TrashEventGui.Pill y 92) → ลงแถวถัดไปทีละ 28
local buffGui = Instance.new("ScreenGui")
buffGui.Name = "KrathongBuffGui"
buffGui.ResetOnSpawn = false
buffGui.DisplayOrder = 2
buffGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
buffGui.Parent = player:WaitForChild("PlayerGui")
local pill = Instance.new("TextLabel")
pill.Name = "KrathongBuff"
pill.AnchorPoint = Vector2.new(0, 0)
pill.Position = UDim2.new(0, 12, 0, 64)
pill.Size = UDim2.new(0, 0, 0, 30)
pill.AutomaticSize = Enum.AutomaticSize.X
pill.BackgroundTransparency = 1
pill.TextColor3 = Color3.new(1, 1, 1)
pill.TextStrokeColor3 = Color3.fromRGB(25, 45, 80)
pill.TextStrokeTransparency = 0.2
pill.Font = Enum.Font.GothamBold
pill.TextSize = 14
pill.Visible = false
pill.Parent = buffGui
local SLOT_Y, SLOT_H = 64, 28
local function otherVisible(guiName, labelName)
	local pg = player:FindFirstChild("PlayerGui")
	local g = pg and pg:FindFirstChild(guiName)
	local l = g and g:FindFirstChild(labelName)
	return l ~= nil and l.Visible and (not g:IsA("ScreenGui") or g.Enabled)
end
-- จัดแถวป้ายของเรา (บัฟ แล้วนับถอยหลังปล่อยโคม) ลงช่องว่างทีละ 28 · ป้ายฝนอยู่ที่ 64 / ป้ายเก็บขยะอยู่ที่ 92 (ตายตัว)
local function layoutPills()
	local taken = {}
	if otherVisible("WeatherGui", "RainPill") then taken[SLOT_Y] = true end
	if otherVisible("TrashEventGui", "Pill") then taken[SLOT_Y + SLOT_H] = true end
	local y = SLOT_Y
	for _, name in ipairs({ "KrathongBuff", "LanternLuck", "LanternCountdown" }) do
		local l = buffGui:FindFirstChild(name)
		if l and l.Visible then
			while taken[y] do y += SLOT_H end
			l.Position = UDim2.new(0, 12, 0, y)
			taken[y] = true
		end
	end
end
-- ป้ายโชคจากแขวนโคม (2026-11-11) แถวถัดจากบัฟปลาอีเวนต์ · Attribute LanternLuckUntil = เวลาเซิร์ฟเวอร์
local luckPill = pill:Clone()
luckPill.Name = "LanternLuck"
luckPill.Visible = false
luckPill.Parent = buffGui
task.spawn(function()
	while true do
		local ll = (tonumber(player:GetAttribute("LanternLuckUntil")) or 0) - workspace:GetServerTimeNow()
		if ll > 0 then
			ll = math.floor(ll)
			local pct = math.floor(((Config.Types.HangLantern and Config.Types.HangLantern.LuckMult or 1.3) - 1) * 100 + 0.5)
			luckPill.Text = tr("🏮 โชค +", "🏮 Luck +") .. pct .. "% · " .. string.format("%d:%02d", ll // 60, ll % 60)
			luckPill.Visible = true
		else
			luckPill.Visible = false
		end
		layoutPills()
		task.wait(1)
	end
end)
task.spawn(function()
	while true do
		local left = (tonumber(player:GetAttribute("KrathongBuffUntil")) or 0) - os.time()
		if left > 0 then
			local pct = math.floor((tonumber(player:GetAttribute("KrathongEventBonus")) or 0) * 100 + 0.5)
			pill.Text = tr("🌸 โชคปลาอีเวนต์ +", "🌸 Event fish +") .. pct .. "% · " .. string.format("%d:%02d", left // 60, left % 60)
			pill.Visible = true
			layoutPills()
		else
			pill.Visible = false
		end
		if window.Visible and mode == "float" then
			info.buffUntil = player:GetAttribute("KrathongBuffUntil")
			info.bonus = player:GetAttribute("KrathongEventBonus")
			subtitle.Text = buffText()
		end
		task.wait(1)
	end
end)

-- ============ กระทงลอยน้ำ (ทุกเครื่องทำเอง) ============
local floatFolder = Instance.new("Folder")
floatFolder.Name = "KrathongFloating"
floatFolder.Parent = workspace
local floating = {} -- { model, t0, seed, path, light }
-- เส้นทางไหลต่อใบ: ท่าน้ำ = Config.PATH / ปุ่มลอยริมน้ำ = คำนวณจากจุดลงน้ำ + ทิศ (ทุกเครื่องคำนวณเองจาก terrain เดียวกัน)
local terrainParams = RaycastParams.new()
terrainParams.FilterType = Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances = { workspace.Terrain }
terrainParams.IgnoreWater = false
local function isWaterAt(p, waterY)
	local hit = workspace:Raycast(Vector3.new(p.X, waterY + 4, p.Z), Vector3.new(0, -8, 0), terrainParams)
	return hit ~= nil and hit.Material == Enum.Material.Water and math.abs(hit.Position.Y - waterY) < 1.5
end
-- ลำธารมีแผ่นน้ำสีฟ้า (LayoutDecor.StreamDecor.WaterSheet) ทับน้ำ terrain สูงกว่า ~0.37 -> ถ้าไม่ยกขึ้น กระทงจะอยู่ใต้แผ่นดูเหมือนจม (2026-11-11)
-- ความสูงแผ่น = attr KrathongSurfaceY บน WaterSheet · ใช้เฉพาะจุดที่อยู่ในกรอบของแผ่นและน้ำ terrain ต่ำกว่าแผ่นไม่เกิน 0.5
local function surfaceYAt(p, terrainY)
	local ld = workspace:FindFirstChild("LayoutDecor")
	local sd = ld and ld:FindFirstChild("StreamDecor")
	local ws = sd and sd:FindFirstChild("WaterSheet")
	local top = ws and ws:GetAttribute("KrathongSurfaceY")
	if typeof(top) ~= "number" or terrainY > top or top - terrainY > 0.5 then return terrainY end
	for _, part in ipairs(ws:GetDescendants()) do
		if part:IsA("BasePart") then
			local lp = part.CFrame:PointToObjectSpace(Vector3.new(p.X, part.Position.Y, p.Z))
			-- + KrathongFloatLift: ยกเพิ่มให้ฐานพ้นแผ่นน้ำ (ผู้ใช้: "ยังจมน้ำอยู่" 2026-11-11)
			if math.abs(lp.X) <= part.Size.X / 2 and math.abs(lp.Z) <= part.Size.Z / 2 then
				local extra = ws:GetAttribute("KrathongFloatLift")
				return top + (typeof(extra) == "number" and extra or 0)
			end
		end
	end
	return terrainY
end
local function buildPath(start, dir)
	local pts = { Vector3.new(start.X, 0, start.Z) }
	local cur, d = start, Vector3.new(dir.X, 0, dir.Z).Unit
	for _ = 1, Config.HERE_STEPS do
		local moved = false
		for _, ang in ipairs({ 0, 30, -30, 60, -60 }) do
			local nd = CFrame.Angles(0, math.rad(ang), 0):VectorToWorldSpace(d)
			local c = cur + nd * Config.HERE_STEP
			-- เช็กกลางทางด้วย กันข้ามแนวดินแคบๆ
			if isWaterAt(c, start.Y) and isWaterAt(cur + nd * (Config.HERE_STEP / 2), start.Y) then
				table.insert(pts, Vector3.new(c.X, 0, c.Z))
				cur, d, moved = c, nd, true
				break
			end
		end
		if not moved then break end
	end
	return pts
end
local function measure(path)
	local seg, total = {}, 0
	for i = 1, #path - 1 do seg[i] = (path[i + 1] - path[i]).Magnitude total += seg[i] end
	return seg, total
end
local function pointAt(f, d)
	local path, seg = f.path, f.seg
	if #path < 2 then return path[1], f.dir end
	for i = 1, #seg do
		if d <= seg[i] then
			local a, b = path[i], path[i + 1]
			return a:Lerp(b, d / seg[i]), (b - a).Unit
		end
		d -= seg[i]
	end
	local n = #path
	return path[n], (path[n] - path[n - 1]).Unit
end

local function removeFloat(i)
	local f = table.remove(floating, i)
	if f and f.model then f.model:Destroy() end
end

local function lightCount()
	local n = 0
	for _, f in ipairs(floating) do if f.light then n += 1 end end
	return n
end

local function spawnFloat(data)
	local src = models:FindFirstChild(tostring(data.id))
	if not src then return end
	if #floating >= Config.MAX_FLOATING then removeFloat(1) end
	local def = Config.Types[data.id]
	local m = src:Clone()
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end
	end
	local handle = m.PrimaryPart
	local light
	if handle and lightCount() < Config.LIGHT_LIMIT then
		light = Instance.new("PointLight")
		light.Color = def and def.Light or Color3.fromRGB(255, 200, 120)
		light.Range = 10
		light.Brightness = 1.6
		light.Shadows = false
		light.Parent = handle
	end
	if handle then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 200, 0, data.wish and 38 or 22) -- ป้ายคำอธิษฐานเล็กลง 2026-11-08
		bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		bb.MaxDistance = 70
		bb.LightInfluence = 0
		bb.Adornee = handle
		local who = label(bb, "🌸 " .. tostring(data.owner or ""), UDim2.new(1, 0, 0, 20), UDim2.new(), Color3.new(1, 1, 1))
		local s1 = Instance.new("UIStroke") s1.Color = Color3.fromRGB(170, 60, 110) s1.Thickness = 1.5 s1.Parent = who
		if data.wish then
			local w = label(bb, "“" .. data.wish .. "”", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 21), Color3.fromRGB(255, 245, 200))
			w.Font = Enum.Font.GothamMedium
			local cap = Instance.new("UITextSizeConstraint") cap.MaxTextSize = 14 cap.Parent = w -- ข้อความสั้นไม่ขยายใหญ่เกินชื่อ
			local s2 = Instance.new("UIStroke") s2.Color = Color3.fromRGB(120, 70, 40) s2.Thickness = 1.2 s2.Parent = w
		end
		bb.Parent = handle
	end
	m.Parent = floatFolder
	local rnd = Random.new(tonumber(data.seed) or 1)
	local path, waterY, dir0 = Config.PATH, Config.WATER_Y, Vector3.new(-1, 0, 0)
	if typeof(data.start) == "Vector3" and typeof(data.dir) == "Vector3" then
		path, waterY, dir0 = buildPath(data.start, data.dir), surfaceYAt(data.start, data.start.Y), data.dir
	end
	local seg, total = measure(path)
	table.insert(floating, {
		path = path, seg = seg, pathLen = total, waterY = waterY, dir = dir0,
		model = m,
		t0 = tonumber(data.t0) or workspace:GetServerTimeNow(),
		side = rnd:NextNumber(-4, 4), -- ไหลเยื้องซ้ายขวาคนละเส้น
		phase = rnd:NextNumber(0, math.pi * 2),
		spin = rnd:NextNumber(-0.25, 0.25),
		light = light,
		parts = (function() local t = {} for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then table.insert(t, p) end end return t end)(), -- จางทั้งใบรวมธูป
		lift = handle and (handle.Size.Y / 2 - math.min(0.15, handle.Size.Y * 0.3)) or 0.3, -- PivotTo วางจุดกึ่งกลาง -> ยกให้ฐานจมน้ำแค่นิดเดียว (ฐานใหม่เตี้ย 2026-11-07)
		flame = m:FindFirstChild("CandleFlame"), -- เปลวไฟไหว
		flameSize = m:FindFirstChild("CandleFlame") and m.CandleFlame.Size,
	})
	-- วงน้ำกระเพือมตอนวางลงน้ำ
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.05, 1.5, 1.5)
	ring.CFrame = CFrame.new(Vector3.new(path[1].X, waterY + 0.05, path[1].Z)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true ring.CanCollide = false ring.CanQuery = false ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 255, 255)
	ring.Transparency = 0.4
	ring.Parent = floatFolder
	TweenService:Create(ring, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.05, 9, 9), Transparency = 1 }):Play()
	task.delay(1.5, function() ring:Destroy() end)
end

-- ============ โคมลอยขึ้นฟ้า (ทุกเครื่องทำเอง) ============
local lanterns = {} -- { model, t0, start, drift, phase, light, parts, halo }
local nightFlag = false -- กลางคืนบนเครื่องนี้ (ลูปแสงกลางคืนท้ายไฟล์อัปเดต) ใช้ตั้งความเข้มวงแสง
local function gfxMult()
	local q = player:GetAttribute("GraphicsQuality")
	local t = Config.GFX_LANTERN_MULT
	return (t and type(q) == "string" and t[q]) or 1
end
local function lanternLights()
	local n = 0
	for _, l in ipairs(lanterns) do if l.light then n += 1 end end
	return n
end
local function removeLantern(i)
	local l = table.remove(lanterns, i)
	if l and l.model then l.model:Destroy() end
end
local function spawnLantern(entry, t0, delayS, rnd)
	-- 2026-11-11 โคมเรืองแสงแบบรูปจริง (Config.GLOW_MODEL) ไม่มีโมเดลนี้ = โคมเดิม
	local glow = Config.GLOW_MODEL and models:FindFirstChild(Config.GLOW_MODEL)
	local src = glow or models:FindFirstChild("SkyLantern")
	if not src or typeof(entry.pos) ~= "Vector3" then return end
	-- ไกลกล้องเกิน LANTERN_CULL = ไม่สร้าง (2026-11-11 ปล่อยได้ทุกที่ โคมกระจายทั้งแมพ)
	local cam = workspace.CurrentCamera
	if cam and Config.LANTERN_CULL and (cam.CFrame.Position - entry.pos).Magnitude > Config.LANTERN_CULL then return end
	if #lanterns >= Config.MAX_LANTERNS then removeLantern(1) end
	local m = src:Clone()
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end
	end
	local sc = Config.LANTERN_SCALE or { 1.6, 2.1 }
	pcall(function() m:ScaleTo(rnd:NextNumber(sc[1], sc[2])) end) -- โคมจริงเล็กไป มองจากพื้นแทบไม่เห็น (ทดสอบ 2026-11-07) · ขนาดสุ่มให้มีใกล้ใหญ่ไกลเล็กแบบรูป
	local handle = m.PrimaryPart
	local light, halo
	local parts = {}
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then parts[p] = p.Transparency end end
	if handle and not glow then
		handle.Material = Enum.Material.Neon -- เรืองแสงเอง ไม่ต้องพึ่ง PointLight
		handle.Color = Color3.fromRGB(255, 190, 120)
	end
	-- วงแสงฟุ้งรอบโคม (BillboardGui ขนาดเป็นสตั๊ด) ติดที่ไส้ไฟ
	if handle and Config.HALO_IMAGE then
		local at = m:FindFirstChild("Flame") or handle
		local w = handle.Size.X * (Config.HALO_SIZE or 3.4)
		halo = Instance.new("BillboardGui")
		halo.Name = "Halo"
		halo.Size = UDim2.fromScale(w, w)
		halo.LightInfluence = 0
		halo.Adornee = at
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = Config.HALO_IMAGE
		img.ImageTransparency = nightFlag and Config.HALO_ALPHA.Night or Config.HALO_ALPHA.Day
		img.Parent = halo
		halo.Parent = at
		halo = img
	end
	if handle then
		if not entry.ambient and lanternLights() < Config.LANTERN_LIGHT_LIMIT then -- โคมประกอบฉากริมหาดไม่มี PointLight (Neon อย่างเดียว)
			light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 170, 100)
			light.Range = 12
			light.Brightness = 1.4
			light.Shadows = false
			light.Parent = handle
		end
		if entry.owner then
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 180, 0, 20)
			bb.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
			bb.MaxDistance = 60
			bb.LightInfluence = 0
			bb.Adornee = handle
			local who = label(bb, "🏮 " .. tostring(entry.owner), UDim2.fromScale(1, 1), UDim2.new(), Color3.new(1, 1, 1))
			local s1 = Instance.new("UIStroke") s1.Color = Color3.fromRGB(170, 80, 40) s1.Thickness = 1.5 s1.Parent = who
			bb.Parent = handle
		end
	end
	m:PivotTo(CFrame.new(entry.pos))
	m.Parent = floatFolder
	local a = rnd:NextNumber(0, math.pi * 2)
	table.insert(lanterns, {
		model = m,
		t0 = t0 + delayS,
		start = entry.pos + Vector3.new(0, 1.5, 0),
		-- ลมพัดออกทะเล (+Z) · โคมประกอบฉากกลางทะเลลมเบากว่า ให้ลอยอยู่หน้าหาดนานขึ้น (2026-11-11)
		drift = entry.ambient and (Vector3.new(math.cos(a), 0, math.sin(a)) * rnd:NextNumber(10, 25) + Vector3.new(0, 0, 12))
			or (Vector3.new(math.cos(a), 0, math.sin(a)) * rnd:NextNumber(25, 60) + Vector3.new(0, 0, 30)),
		phase = rnd:NextNumber(0, math.pi * 2),
		speed = rnd:NextNumber(0.85, 1.15),
		light = light,
		ambient = entry.ambient == true,
		parts = parts,
		halo = halo,
		fadeIn = entry.ambient == true, -- ค่อยๆ ปรากฏ 1.5 วิแรก (ไม่เด้งขึ้นกลางทะเล)
	})
	if entry.ambient then
		for p in pairs(parts) do p.Transparency = 1 end
		if halo then halo.ImageTransparency = 1 end
	end
end

-- ============ ฉากโคมลอยขึ้นจากชายหาด (2026-11-11 ผู้ใช้สั่ง) ============
-- เครื่องนี้ทำเองล้วน (เซิร์ฟไม่ส่งอะไร): จุดสุ่มตามเส้น P01→P13 ใน workspace.KrathongBeachLanternLine ± HalfWidth
-- 2026-11-11 ผู้ใช้สั่ง: ย้ายไปขึ้นกลางทะเลหน้าหาด (เส้นอยู่ห่างฝั่ง ~120, HalfWidth 50) → รับเฉพาะจุดที่เป็นน้ำ เริ่มเหนือผิวน้ำ (เดิมรับเฉพาะพื้นทราย)
local beachParams = RaycastParams.new()
beachParams.FilterType = Enum.RaycastFilterType.Include
beachParams.FilterDescendantsInstances = { workspace.Terrain }
beachParams.IgnoreWater = false
local function beachPoint(rnd)
	local line = workspace:FindFirstChild("KrathongBeachLanternLine")
	if not line then return nil end
	local pts = {}
	for _, p in ipairs(line:GetChildren()) do if p:IsA("BasePart") then table.insert(pts, p) end end
	if #pts == 0 then return nil end
	table.sort(pts, function(a, b) return a.Name < b.Name end)
	local hw = tonumber(line:GetAttribute("HalfWidth")) or 5
	for _ = 1, 4 do
		local i = rnd:NextInteger(1, math.max(1, #pts - 1))
		local a, b = pts[i].Position, (pts[i + 1] or pts[i]).Position
		local p = a:Lerp(b, rnd:NextNumber())
		local d = (b - a) * Vector3.new(1, 0, 1)
		local side = d.Magnitude > 0.1 and Vector3.new(-d.Z, 0, d.X).Unit or Vector3.xAxis
		p += side * rnd:NextNumber(-hw, hw)
		local hit = workspace:Raycast(p + Vector3.new(0, 25, 0), Vector3.new(0, -50, 0), beachParams)
		if hit and hit.Material == Enum.Material.Water then return hit.Position + Vector3.new(0, 0.8, 0) end
	end
	return nil
end
local function ambientCount()
	local n = 0
	for _, l in ipairs(lanterns) do if l.ambient then n += 1 end end
	return n
end
local Lighting = game:GetService("Lighting")
local function isNightHere()
	local t = player:GetAttribute("PersonalVisualClockTime")
	t = typeof(t) == "number" and t or Lighting.ClockTime
	return t >= (Config.NIGHT_ON or 18.2) or t < (Config.NIGHT_OFF or 6.3)
end
-- รอบปล่อยพร้อมกัน: โคมขึ้นจากหาดพร้อมกัน BEACH_MASS ดวง (ทุกช่วงเวลา) ทยอยใน 6 วิ
local function beachWave(t0)
	if not Config.BEACH_AMBIENT or not workspace:FindFirstChild("KrathongBeachLanternLine") then return end
	local rnd = Random.new()
	for _ = 1, math.floor((Config.BEACH_MASS or 0) * gfxMult()) do
		local pos = beachPoint(rnd)
		if pos then spawnLantern({ pos = pos, ambient = true }, t0, rnd:NextNumber(0, 6), rnd) end
	end
end
-- กลางคืน: ปล่อยทีละดวงทุก BEACH_EVERY วิ บนฟ้าไม่เกิน BEACH_MAX (เหลือที่ให้โคมผู้เล่นอย่างน้อย 20 ดวง)
task.spawn(function()
	local rnd = Random.new()
	while true do
		local every = Config.BEACH_EVERY or { 2, 3.5 }
		task.wait(rnd:NextNumber(every[1], every[2]) / math.max(0.25, gfxMult()))
		if Config.BEACH_AMBIENT and isNightHere() and workspace:FindFirstChild("KrathongBeachLanternLine")
			and ambientCount() < (Config.BEACH_MAX or 20) * gfxMult() and #lanterns < Config.MAX_LANTERNS - 20 then
			local pos = beachPoint(rnd)
			if pos then spawnLantern({ pos = pos, ambient = true }, workspace:GetServerTimeNow(), 0, rnd) end
		end
	end
end)

-- ============ ท่าอธิษฐาน: ยกกระทงขึ้นเหนือหัวก่อนลอย (2026-11-07) ============
-- ทำบนทุกเครื่อง (เซิร์ฟส่ง "pray" ให้ทุกคน): ข้อต่อไหล่/ศอก R15 หมุน Motor6D.C0 (แอนิเมชันเดินเขียน Transform ทับทุกเฟรม ตั้ง Transform เองแขนไม่ขยับ) คืน C0 เดิมตอนจบ
--   กระทงสำเนาลอยเหนือหัวระหว่างมือสองข้าง กระทงที่ถืออยู่ในมือซ่อนชั่วคราว · R6 = ไม่ยกแขน แต่กระทงยังลอยเหนือหัว
local praying = {} -- [character] = { t0, dur, model, tracks, hidden, head, lift, phase }
-- ท่าลอยกระทง (2026-11-07 ผู้ใช้สั่ง "นั่งลงแล้วยกมืออธิษฐานแล้วลอยกระทงลงน้ำ"):
--   คุกเข่าลงถือกระทงระดับอก → ยกกระทงจรดหน้าผากอธิษฐาน → โน้มตัวยื่นแขนวางกระทงลงน้ำ → ลุกขึ้น
-- ท่าเป็นแอนิเมชันที่สร้างในเครื่อง (KeyframeSequenceProvider → rbxtemp://) Priority Action4 ทับท่าเดิน
--   เกมนี้ข้อต่อตัวละครเป็น AnimationConstraint: ตั้ง Transform/C0/Attachment เองไม่ขยับ (ลองแล้ว) ต้องเป็นแอนิเมชันจริง
--   rbxtemp ไม่ส่งข้ามเครื่อง ทุกเครื่องจึงเล่นท่าให้ตัวละครนั้นเอง (เซิร์ฟส่ง "pray" ให้ทุกคน) · R6 = ไม่มีข้อต่อชื่อเหล่านี้ ท่าไม่ขึ้น แต่กระทงยังเคลื่อนตามลำดับ
local KSP = game:GetService("KeyframeSequenceProvider")
local KNEEL_DROP = 0.9 -- ลดลำตัวลงตอนคุกเข่า (สตั๊ด) ทดสอบ 2026-11-07: 1.5 แข้งจมพื้น ~0.6 / 1.2 จม ~0.3
local function rx(d) return CFrame.Angles(math.rad(d), 0, 0) end
local POSES = {
	-- คุกเข่า ถือกระทงระดับอก
	hold = { LowerTorso = CFrame.new(0, -KNEEL_DROP, 0), UpperTorso = CFrame.new(),
		RightUpperLeg = CFrame.new(), LeftUpperLeg = CFrame.new(), RightLowerLeg = rx(-90), LeftLowerLeg = rx(-90),
		RightUpperArm = rx(50) * CFrame.Angles(0, 0, math.rad(18)), LeftUpperArm = rx(50) * CFrame.Angles(0, 0, math.rad(-18)),
		RightLowerArm = rx(55), LeftLowerArm = rx(55) },
	-- คุกเข่า ยกกระทงจรดหน้าผาก (อธิษฐาน)
	wish = { LowerTorso = CFrame.new(0, -KNEEL_DROP, 0), UpperTorso = rx(-5),
		RightUpperLeg = CFrame.new(), LeftUpperLeg = CFrame.new(), RightLowerLeg = rx(-90), LeftLowerLeg = rx(-90),
		RightUpperArm = rx(115) * CFrame.Angles(0, 0, math.rad(22)), LeftUpperArm = rx(115) * CFrame.Angles(0, 0, math.rad(-22)),
		RightLowerArm = rx(45), LeftLowerArm = rx(45) },
	-- คุกเข่า โน้มตัวไปข้างหน้า ยื่นแขนวางกระทงลงน้ำ
	place = { LowerTorso = CFrame.new(0, -KNEEL_DROP, 0), UpperTorso = rx(-35),
		RightUpperLeg = CFrame.new(), LeftUpperLeg = CFrame.new(), RightLowerLeg = rx(-90), LeftLowerLeg = rx(-90),
		RightUpperArm = rx(80) * CFrame.Angles(0, 0, math.rad(8)), LeftUpperArm = rx(80) * CFrame.Angles(0, 0, math.rad(-8)),
		RightLowerArm = rx(10), LeftLowerArm = rx(10) },
}
-- ยืนชูแขนสองข้างขึ้นเหนือหัว แขวนโคม (2026-11-08) ขาไม่ใส่ = ใช้ท่ายืนปกติ
POSES.reach = {
	RightUpperArm = rx(160) * CFrame.Angles(0, 0, math.rad(12)), LeftUpperArm = rx(160) * CFrame.Angles(0, 0, math.rad(-12)),
	RightLowerArm = rx(15), LeftLowerArm = rx(15), UpperTorso = rx(6) }
local TREE = { -- ลำดับข้อต่อ R15
	HumanoidRootPart = { "LowerTorso" },
	LowerTorso = { "UpperTorso", "RightUpperLeg", "LeftUpperLeg" },
	UpperTorso = { "RightUpperArm", "LeftUpperArm" },
	RightUpperArm = { "RightLowerArm" }, LeftUpperArm = { "LeftLowerArm" },
	RightUpperLeg = { "RightLowerLeg" }, LeftUpperLeg = { "LeftLowerLeg" },
}
local poseIds = {}
local function poseId(name)
	if poseIds[name] ~= nil then return poseIds[name] end
	local spec = POSES[name]
	local ks = Instance.new("KeyframeSequence")
	ks.Loop = true
	ks.Priority = Enum.AnimationPriority.Action4
	for _, t in ipairs({ 0, 1 }) do
		local kf = Instance.new("Keyframe")
		kf.Time = t
		local function build(partName, parent)
			local p = Instance.new("Pose")
			p.Name = partName
			if spec[partName] then p.CFrame = spec[partName] p.Weight = 1 else p.Weight = 0 end
			p.Parent = parent
			for _, child in ipairs(TREE[partName] or {}) do build(child, p) end
		end
		build("HumanoidRootPart", kf)
		kf.Parent = ks
	end
	local ok, id = pcall(function() return KSP:RegisterKeyframeSequence(ks) end)
	poseIds[name] = ok and id or false
	return poseIds[name]
end
local function loadPose(animator, name)
	local id = poseId(name)
	if not id then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok then return nil end
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true
	return track
end
local function smooth(x) x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end
-- ระหว่างท่า ตัวละครของเราเดิน/กระโดดไม่ได้ (คืนเองตอนจบ)
-- ⚠️ เกมนี้ไม่มี PlayerModule มาตรฐาน ห้าม WaitForChild (เคยค้างทั้งสคริปต์ 2026-11-07) → ปรับ WalkSpeed/JumpPower ของตัวเองแทน
local function lockMove(hum)
	if not hum then return nil end
	local saved = { ws = hum.WalkSpeed, jp = hum.JumpPower, jh = hum.JumpHeight }
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0
	return function()
		if not hum.Parent then return end
		-- ระบบอื่น (วิ่ง Shift / สัตว์ขี่) อาจตั้งค่าใหม่ระหว่างทาง คืนเฉพาะที่ยังเป็น 0 ที่เราตั้งไว้
		if hum.WalkSpeed == 0 then hum.WalkSpeed = saved.ws end
		if hum.JumpPower == 0 then hum.JumpPower = saved.jp end
		if hum.JumpHeight == 0 then hum.JumpHeight = saved.jh end
	end
end
local function endPray(ch)
	local p = praying[ch]
	if not p then return end
	praying[ch] = nil
	if p.model then p.model:Destroy() end
	for _, t in pairs(p.tracks) do pcall(function() t:Stop(0.4) end) end
	for part in pairs(p.hidden) do if part.Parent then part.LocalTransparencyModifier = 0 end end
	if p.unlock then pcall(p.unlock) end
end
local function startPray(data)
	local plr = Players:GetPlayerByUserId(tonumber(data.ownerId) or 0)
	local ch = plr and plr.Character
	local head = ch and ch:FindFirstChild("Head")
	local src = models:FindFirstChild(tostring(data.id))
	if not head or not src then return end
	endPray(ch)
	local m = src:Clone()
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end
	end
	m.Parent = floatFolder
	local tracks = {}
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator and ch:FindFirstChild("RightUpperArm") then
		for _, n in ipairs({ "hold", "wish", "place" }) do tracks[n] = loadPose(animator, n) end
		if tracks.hold then tracks.hold:Play(0.45) end
	end
	local hidden = {}
	local tool = ch:FindFirstChildWhichIsA("Tool")
	if tool and tool:GetAttribute("IsKrathong") then
		for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 hidden[p] = true end end
	end
	local unlock = (plr == player) and lockMove(hum) or nil
	local dur = tonumber(data.dur) or Config.PRAY_SECONDS
	local h = m.PrimaryPart
	praying[ch] = { t0 = tonumber(data.t0) or workspace:GetServerTimeNow(), dur = dur, model = m, tracks = tracks, hidden = hidden, head = head,
		lift = h and (h.Size.Y / 2 - math.min(0.15, h.Size.Y * 0.3)) or 0.3, phase = "hold", unlock = unlock, water = typeof(data.water) == "Vector3" and Vector3.new(data.water.X, surfaceYAt(data.water, data.water.Y), data.water.Z) or nil }
	-- กันค้าง: กระทงที่ลอยน้ำมาไม่ถึง (เน็ตช้า) ก็เก็บท่าเองหลังเวลานี้
	task.delay(dur + 1.5, function() if praying[ch] and praying[ch].model == m then endPray(ch) end end)
end
-- แขวนโคมด้วยไม้ไผ่ (2026-11-08 ผู้ใช้สั่ง ตามรูปงานจริง): ชูไม้ไผ่สองมือ ดันปลายไม้ขึ้นไปเกี่ยวโคมกับตะขอ แล้วลดไม้ลง
--   สำเนาในเครื่อง: ลำไม้ (ยืดได้ถ้าตะขออยู่ไกล) + ขอทองปลายไม้ + โคม (HangLanternLamp) · data.at = CFrame โคมที่ตะขอ · โคมจริงของเซิร์ฟขึ้นตอนจบ
local HANG_PUSH = 1.4 -- วินาทีที่ดันขึ้นจนโคมเกี่ยวตะขอ ที่เหลือคือลดไม้ลง
local function startHang(data)
	local plr = Players:GetPlayerByUserId(tonumber(data.ownerId) or 0)
	local ch = plr and plr.Character
	local head = ch and ch:FindFirstChild("Head")
	local poleSrc = models:FindFirstChild("HangLantern")
	local lampSrc = models:FindFirstChild("HangLanternLamp")
	if not head or not poleSrc or not lampSrc or typeof(data.at) ~= "CFrame" then return end
	endPray(ch)
	local m = Instance.new("Model")
	m.Name = "HangPole"
	local lamp = lampSrc:Clone()
	local ldef = Config.Types[tostring(data.id)]
	if ldef and ldef.Lamp and lamp:FindFirstChild("Paper") then lamp.Paper.UsePartColor = true lamp.Paper.Color = ldef.Lamp end
	lamp.Parent = m
	local pole = poleSrc.Handle:Clone()
	pole.Parent = m
	local arm = poleSrc.TipArm:Clone() arm.Parent = m
	local drop = poleSrc.TipDrop:Clone() drop.Parent = m
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end
	end
	m.Parent = floatFolder
	local tracks = {}
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator and ch:FindFirstChild("RightUpperArm") then
		tracks.reach = loadPose(animator, "reach")
		if tracks.reach then tracks.reach:Play(0.3) end
	end
	local hidden = {}
	local tool = ch:FindFirstChildWhichIsA("Tool")
	if tool and tool:GetAttribute("IsKrathong") then
		for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 hidden[p] = true end end
	end
	local unlock = (plr == player) and lockMove(hum) or nil
	local dur = tonumber(data.dur) or Config.HANG_POSE
	praying[ch] = { kind = "hang", t0 = tonumber(data.t0) or workspace:GetServerTimeNow(), dur = dur, model = m, tracks = tracks, hidden = hidden, head = head,
		phase = "reach", unlock = unlock, at = data.at, lamp = lamp, pole = pole, arm = arm, drop = drop,
		len = tonumber(poleSrc:GetAttribute("PoleLength")) or 10, armLen = tonumber(poleSrc:GetAttribute("TipArm")) or 0.55, tipUp = tonumber(poleSrc:GetAttribute("TipUp")) or 1.6 }
	task.delay(dur + 0.4, function() if praying[ch] and praying[ch].model == m then endPray(ch) end end)
end
-- วางลำไม้ (ปลายบน = tip) ผ่านมือ + ขอทอง + โคมห้อยใต้ขอ · toward = ทิศแนวราบจากตะขอมาหาผู้เล่น
local function placePole(p, hands, tip, toward, lampAt)
	local dir = tip - hands
	local dist = dir.Magnitude
	dir = dist > 0.01 and dir.Unit or Vector3.yAxis
	local len = math.max(p.len, dist + 1.2)
	local bottom = tip - dir * len
	p.pole.Size = Vector3.new(len, p.pole.Size.Y, p.pole.Size.Z)
	p.pole.CFrame = CFrame.lookAt((tip + bottom) / 2, tip) * CFrame.Angles(0, math.rad(90), 0) -- Cylinder แกนยาว X → ชี้ไปปลายไม้
	local armEnd = tip - toward * p.armLen
	p.arm.CFrame = CFrame.lookAt((tip + armEnd) / 2, armEnd)
	p.drop.CFrame = CFrame.new(armEnd - Vector3.new(0, 0.15, 0))
	p.lamp:PivotTo(lampAt or (CFrame.new(armEnd - Vector3.new(0, p.tipUp, 0)) * (p.at - p.at.Position)))
end
local KNEEL_T, WISH_T, PLACE = 0.6, 0.6, 1.1 -- คุกเข่า / ยกขึ้นอธิษฐาน / วางลงน้ำ (วินาที) ที่เหลือคือค้างอธิษฐาน
local function switch(p, name, fade)
	if p.phase == name then return end
	if p.tracks[p.phase] then p.tracks[p.phase]:Stop(fade) end
	if p.tracks[name] then p.tracks[name]:Play(fade) end
	p.phase = name
end
RunService.Stepped:Connect(function()
	if next(praying) == nil then return end
	local now = workspace:GetServerTimeNow()
	for ch, p in pairs(praying) do
		local age = now - p.t0
		if not ch.Parent or not p.head.Parent then
			endPray(ch)
		elseif p.kind == "hang" then
			local hcf = p.head.CFrame
			local yaw = select(2, hcf:ToOrientation())
			local flat = CFrame.new(hcf.Position) * CFrame.Angles(0, yaw, 0)
			local hands = (flat * CFrame.new(0, 1.2, -0.6)).Position -- สองมือชูเหนือหัว
			local hook = p.at.Position
			local toward = (hands - hook) * Vector3.new(1, 0, 1)
			toward = toward.Magnitude > 0.05 and toward.Unit or -flat.LookVector
			local tipTarget = hook + Vector3.new(0, p.tipUp, 0) + toward * p.armLen
			if age < HANG_PUSH then
				local tip0 = hands + Vector3.new(0, p.len * 0.6, 0) + toward * 0.2
				placePole(p, hands, tip0:Lerp(tipTarget, smooth(age / HANG_PUSH)), toward)
			else
				-- โคมค้างที่ตะขอแล้ว ลดไม้ลงห่างตะขอ
				local k = smooth((age - HANG_PUSH) / math.max(0.2, p.dur - HANG_PUSH))
				placePole(p, hands, tipTarget + Vector3.new(0, -3.5 * k, 0) + toward * (1.2 * k), toward, p.at)
			end
		else
			-- ตำแหน่งกระทงอิงหัว (หัวลดลงตามท่าคุกเข่าเอง)
			local hcf = p.head.CFrame
			local yaw = select(2, hcf:ToOrientation())
			local flat = CFrame.new(hcf.Position) * CFrame.Angles(0, yaw, 0)
			local chest = (flat * CFrame.new(0, -1.15, -1.05)).Position
			local brow = (flat * CFrame.new(0, 0.35, -1.0)).Position -- จรดหน้าผาก
			local water = p.water and (p.water + Vector3.new(0, p.lift, 0)) or (Config.PATH[1] + Vector3.new(0, Config.WATER_Y + p.lift, 0))
			local placeT = (age - (p.dur - PLACE)) / PLACE
			local pos
			if age < KNEEL_T then
				pos = chest
			elseif placeT < 0 then
				switch(p, "wish", 0.45)
				local k = smooth((age - KNEEL_T) / WISH_T)
				pos = chest:Lerp(brow, k) + Vector3.new(0, math.sin(age * 2) * 0.03 * k, 0)
			else
				switch(p, "place", 0.45)
				local k = smooth(placeT)
				local mid = (brow + water) / 2 + Vector3.new(0, 0.6, 0)
				pos = brow:Lerp(mid, k):Lerp(mid:Lerp(water, k), k)
				if placeT >= 1 then pos = water end
			end
			p.model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, yaw, 0))
		end
	end
end)

-- ท่าชูโคมขึ้นฟ้า (2026-11-11 ปล่อยได้ทุกที่): ชูแขนสองข้าง 1.3 วิ ระหว่างนั้นตัวเราเดินไม่ได้ · โคมเริ่มจากเหนือหัว
local function startRelease(ownerId)
	local plr = Players:GetPlayerByUserId(tonumber(ownerId) or 0)
	local ch = plr and plr.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator or not ch:FindFirstChild("RightUpperArm") or praying[ch] then return end
	local track = loadPose(animator, "reach")
	if not track then return end
	track:Play(0.25)
	local unlock = (plr == player) and lockMove(hum) or nil
	task.delay(1.3, function()
		pcall(function() track:Stop(0.4) end)
		if unlock then pcall(unlock) end
	end)
end

fxRemote.OnClientEvent:Connect(function(kind, data)
	if kind == "pray" and type(data) == "table" then startPray(data) end
	if kind == "hang" and type(data) == "table" then startHang(data) end
	if kind == "float" and type(data) == "table" then
		-- กระทงที่ถือวางลงน้ำแล้ว = เก็บท่าตอนใบที่ลอยน้ำมาถึงพอดี (ไม่มีช่วงหาย)
		local owner = Players:GetPlayerByUserId(tonumber(data.ownerId) or 0)
		if owner and owner.Character then endPray(owner.Character) end
		spawnFloat(data)
	end
	if kind == "lantern" and type(data) == "table" and type(data.list) == "table" then
		local rnd = Random.new()
		local t0 = tonumber(data.t0) or workspace:GetServerTimeNow()
		for i, entry in ipairs(data.list) do
			if type(entry) == "table" and entry.ownerId then
				-- โคมของผู้เล่น: เริ่มจากเหนือหัวตัวละครบนเครื่องนี้ + ท่าชูโคม
				local plr = Players:GetPlayerByUserId(tonumber(entry.ownerId) or 0)
				local head = plr and plr.Character and plr.Character:FindFirstChild("Head")
				if head then entry.pos = head.Position + Vector3.new(0, 0.3, 0) end
				if not data.mass then startRelease(entry.ownerId) end
			end
			spawnLantern(entry, t0, data.mass and rnd:NextNumber(0, 2.5) or 0, rnd)
		end
		if data.mass then beachWave(t0) end
	end
end)

RunService.Heartbeat:Connect(function()
	if #lanterns == 0 then return end
	local now = workspace:GetServerTimeNow()
	for i = #lanterns, 1, -1 do
		local l = lanterns[i]
		local age = math.max(0, now - l.t0)
		if age > Config.LANTERN_SECONDS or not l.model.Parent then
			removeLantern(i)
		else
			local k = age / Config.LANTERN_SECONDS
			-- ช่วงแรกค่อยๆ ลอยจากมือ แล้วขึ้นเร็วขึ้น + ลมพัดออกไป
			local up = Config.LANTERN_RISE * (k ^ 1.35) * l.speed
			local sway = Vector3.new(math.sin(age * 0.7 + l.phase), 0, math.cos(age * 0.55 + l.phase)) * 1.2
			local pos = l.start + Vector3.new(0, up, 0) + l.drift * (k ^ 1.2) + sway
			l.model:PivotTo(CFrame.new(pos) * CFrame.Angles(math.sin(age + l.phase) * 0.06, age * 0.15, math.cos(age * 0.8 + l.phase) * 0.06))
			local fade = math.clamp((age - (Config.LANTERN_SECONDS - 10)) / 10, 0, 1)
			local appear = l.fadeIn and math.clamp(age / 1.5, 0, 1) or 1
			if appear < 1 then fade = 1 - appear * (1 - fade) elseif l.fadeIn then l.fadeIn = nil fade = math.max(fade, 0) end
			if (fade > 0 or l.fadeIn == nil and appear >= 1 and age < 1.7) and l.parts then
				for p, t0p in pairs(l.parts) do p.Transparency = t0p + (1 - t0p) * fade end
				if l.light then l.light.Brightness = 1.4 * (1 - fade) end
			end
			-- วงแสงไหวแบบเปลวไฟ + จางตามโคม
			if l.halo then
				local base = nightFlag and Config.HALO_ALPHA.Night or Config.HALO_ALPHA.Day
				local flick = math.sin(age * 9 + l.phase) * 0.05 + math.sin(age * 23 + l.phase * 3) * 0.03
				l.halo.ImageTransparency = math.clamp(base + flick + (1 - base) * fade, 0, 1)
			end
		end
	end
end)

-- ============ ป้ายนับถอยหลังรอบปล่อยพร้อมกัน (มุมบนซ้าย แบบป้ายบัฟ) + เตือนล่วงหน้า ============
-- 2026-11-11 ผู้ใช้สั่ง: เดิมเป็น BillboardGui ลอยเหนือลาน (เห็นแค่ใกล้ลาน 160 studs) → ย้ายมาเป็นป้ายมุมบนซ้ายหน้าตาเดียวกับ KrathongBuff
-- แสดงทั้งเกาะตลอดช่วงที่มีลานปล่อยโคม (สวิตช์ KrathongFloat2026 เปิด) · อยู่ในลานแล้ว = ต่อท้ายว่าอยู่ในลานแล้ว
-- จอแคบ (กว้าง < 600) ตัดคำอธิบายท้ายออก ให้เหลือแค่เวลา
local cdPill = pill:Clone()
cdPill.Name = "LanternCountdown"
cdPill.Visible = false
cdPill.Parent = buffGui
local function inLanternField()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local d = root.Position - Config.LANTERN_FIELD
	return Vector3.new(d.X, 0, d.Z).Magnitude <= (Config.LANTERN_RADIUS or 18) + 2 and math.abs(d.Y) < 20
end
local warned = 0
task.spawn(function()
	while true do
		local f = workspace:FindFirstChild("KrathongLanternField")
		if f then
			local now = workspace:GetServerTimeNow()
			local nextT = Config.NextMass(now)
			local left = math.max(0, math.floor(nextT - now))
			local cam = workspace.CurrentCamera
			local narrow = cam and cam.ViewportSize.X < 600
			local txt = tr("🏮 ปล่อยโคมพร้อมกันอีก ", "🏮 Group release in ") .. string.format("%d:%02d", left // 60, left % 60)
			if inLanternField() then
				txt ..= tr(" · ✅ อยู่ในลานแล้ว", " · ✅ You're in the field")
			elseif not narrow then
				txt ..= tr(" · ยืนในลาน = โคมฟรี + บัฟ", " · stand inside = free lantern + buff")
			end
			cdPill.Text = txt
			cdPill.Visible = true
			-- เตือน 1 นาทีก่อน (ครั้งเดียวต่อรอบ) คนที่อยู่ไม่ไกลจากลาน
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if left <= Config.MASS_WARN and warned ~= nextT and root and (root.Position - Config.LANTERN_FIELD).Magnitude < 400 then
				warned = nextT
				showToast(tr("🏮 อีก 1 นาที ปล่อยโคมพร้อมกันที่ลาน · ยืนในลาน = โคมฟรี + บัฟ", "🏮 Group lantern release in 1 minute · stand inside = free lantern + buff"))
			end
		else
			cdPill.Visible = false
		end
		layoutPills()
		task.wait(1)
	end
end)

RunService.Heartbeat:Connect(function()
	if #floating == 0 then return end
	local now = workspace:GetServerTimeNow()
	local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero
	for i = #floating, 1, -1 do
		local f = floating[i]
		local age = now - f.t0
		if age > Config.FLOAT_SECONDS or not f.model.Parent then
			removeFloat(i)
		elseif f.model.PrimaryPart then
			local k = math.clamp(age / Config.FLOAT_SECONDS, 0, 1)
			local d = f.pathLen * (1 - (1 - k) ^ 1.6) -- เริ่มไวแล้วค่อยๆ ช้าลง
			local pos, dir = pointAt(f, d)
			local sideV = Vector3.new(-dir.Z, 0, dir.X)
			-- พ้นท่าค่อยแยกเส้น · เส้นทางสั้น (น้ำแคบ) แกว่งข้างน้อยลง
			local spread = math.min(1, age / 12) * math.clamp(f.pathLen / 30, 0.15, 1)
			pos += sideV * (f.side * spread + math.sin(age * 0.35 + f.phase) * 0.8 * math.clamp(f.pathLen / 30, 0.25, 1))
			local bob = math.sin(age * 1.6 + f.phase) * 0.06
			local tilt = math.sin(age * 1.1 + f.phase) * 0.05
			f.model:PivotTo(CFrame.new(pos.X, f.waterY + f.lift + bob, pos.Z) * CFrame.Angles(tilt, age * f.spin + f.phase, tilt * 0.6))
			-- จางหาย 8 วิสุดท้าย
			local fade = math.clamp((age - (Config.FLOAT_SECONDS - 8)) / 8, 0, 1)
			-- เปลวเทียนไหว (ยืด/หดเล็กน้อย) เฉพาะใบที่อยู่ใกล้กล้อง
			if f.flame and f.flameSize and (camPos - pos).Magnitude < 80 then
				local k2 = 1 + math.sin(age * 11 + f.phase) * 0.12 + math.sin(age * 23 + f.phase * 2) * 0.06
				f.flame.Size = Vector3.new(f.flameSize.X * (2 - k2), f.flameSize.Y * k2, f.flameSize.Z * (2 - k2))
				if f.light then f.light.Brightness = 1.6 * (0.85 + (k2 - 1)) * (1 - fade) end
			end
			if fade > 0 then
				for _, p in ipairs(f.parts) do p.Transparency = fade end
				if f.light then f.light.Brightness = 1.6 * (1 - fade) end
			end
		end
	end
end)

-- ============ ปุ่มลอยริมน้ำ (2026-11-07 ผู้ใช้สั่ง): ถือกระทง + หน้าตัวละครเป็นน้ำ = ปุ่ม "🌸 ลอยกระทง" ============
-- กดแล้วเปิดหน้าต่างเล็กพิมพ์คำอธิษฐาน (ไม่ใส่ก็ได้) → "ลอยเลย" = คุกเข่าอธิษฐานแล้ววางลงน้ำตรงหน้า · จอย = ปุ่ม Y · เซิร์ฟตรวจซ้ำ (actions.floatHere)
local floatBtn = button(gui, tr("🌸 ลอยกระทง", "🌸 Float krathong"), UDim2.new(0, 210, 0, 52), UDim2.new(0.5, -105, 1, -150), PINK)
floatBtn.Name = "FloatHereButton"
floatBtn.Visible = false
floatBtn.ZIndex = 5
stroke(floatBtn, Color3.new(1, 1, 1), 2)
local hereScale = Instance.new("UIScale") hereScale.Parent = floatBtn
local herePoint, hereId
local probeParams = RaycastParams.new()
probeParams.FilterType = Enum.RaycastFilterType.Exclude
probeParams.IgnoreWater = false
local function findWaterAhead(ch, root)
	probeParams.FilterDescendantsInstances = { ch, floatFolder }
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then return nil end
	look = look.Unit
	for _, dist in ipairs(Config.HERE_PROBE) do
		local p = root.Position + look * dist
		local hit = workspace:Raycast(Vector3.new(p.X, root.Position.Y + 1, p.Z), Vector3.new(0, -12, 0), probeParams)
		if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Water then return hit.Position end
	end
	return nil
end
local function heldKrathong()
	local ch = player.Character
	local tool = ch and ch:FindFirstChildWhichIsA("Tool")
	local id = tool and tool:GetAttribute("IsKrathong") and tool:GetAttribute("KrathongId")
	if id and not Config.IsLantern(id) then return id end
	return nil
end
-- โคมแขวนที่ถืออยู่ + ตะขอว่างที่ใกล้ที่สุด (2026-11-08)
local function heldHang()
	local ch = player.Character
	local tool = ch and ch:FindFirstChildWhichIsA("Tool")
	local id = tool and tool:GetAttribute("IsKrathong") and tool:GetAttribute("KrathongId")
	if id and Config.IsHang(id) then return id end
	return nil
end
local function findHook(root)
	local best, bestD = nil, Config.HANG_RANGE
	for _, g in ipairs(workspace:GetChildren()) do -- มีได้หลายลาน (ชื่อเดียวกัน)
		local hooks = g.Name == "KrathongLanternGarden" and g:FindFirstChild("Hooks")
		for _, h in ipairs(hooks and hooks:GetChildren() or {}) do
			if h:IsA("BasePart") and not h:GetAttribute("Taken") then
				local d = h.Position - root.Position
				local flat = Vector3.new(d.X, 0, d.Z).Magnitude
				if flat <= bestD and math.abs(d.Y) < 25 then best, bestD = h, flat end
			end
		end
	end
	return best
end
-- โคมลอยที่ถืออยู่ + เหนือหัวโล่งไหม (2026-11-11 ปล่อยได้ทุกที่) · เกณฑ์เดียวกับเซิร์ฟ (KrathongService.skyClear)
local function heldSky()
	local ch = player.Character
	local tool = ch and ch:FindFirstChildWhichIsA("Tool")
	local id = tool and tool:GetAttribute("IsKrathong") and tool:GetAttribute("KrathongId")
	if id and Config.IsLantern(id) and not Config.IsHang(id) then return id end
	return nil
end
local skyParams = RaycastParams.new()
skyParams.FilterType = Enum.RaycastFilterType.Exclude
skyParams.IgnoreWater = true
local function skyOpen(root)
	local skip = { floatFolder }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	local from = root.Position + Vector3.new(0, 2.5, 0)
	local left = Config.SKY_CLEAR or 40
	for _ = 1, 8 do
		skyParams.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(from, Vector3.new(0, left, 0), skyParams)
		if not hit then return true end
		local part = hit.Instance
		if part ~= workspace.Terrain and (part.Transparency >= 0.9 or not part.CanCollide) then
			table.insert(skip, part)
			left -= math.max(0, hit.Position.Y - from.Y)
			from = hit.Position
			if left <= 0 then return true end
		else
			return false
		end
	end
	return false
end
local function canRelease(ch)
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if hum:GetState() == Enum.HumanoidStateType.Swimming then return false end
	return hum.Sit or hum.FloorMaterial ~= Enum.Material.Air
end
local hereMode = "float" -- "float" = ลอยกระทง / "hang" = แขวนโคม / "lantern" = ปล่อยโคมลอย

-- หน้าต่างเล็กพิมพ์คำอธิษฐาน (อยู่เหนือปุ่ม)
local wishPop = Instance.new("Frame")
wishPop.Name = "HereWish"
wishPop.AnchorPoint = Vector2.new(0.5, 1)
wishPop.Position = UDim2.new(0.5, 0, 1, -140)
wishPop.Size = UDim2.new(0, 360, 0, 150)
wishPop.BackgroundColor3 = CREAM
wishPop.Visible = false
wishPop.ZIndex = 10
wishPop.Parent = gui
corner(wishPop, 16) stroke(wishPop, PINK, 3)
local popScale = Instance.new("UIScale") popScale.Parent = wishPop
local function fitPop()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	popScale.Scale = math.clamp((vp.X - 24) / 360, 0.6, 1.15)
end
fitPop()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPop) end
local popTitle = label(wishPop, "", UDim2.new(1, -60, 0, 30), UDim2.new(0, 14, 0, 10), BROWN)
popTitle.TextXAlignment = Enum.TextXAlignment.Left
popTitle.ZIndex = 11
local popClose = button(wishPop, "X", UDim2.new(0, 34, 0, 34), UDim2.new(1, -44, 0, 8), Color3.fromRGB(200, 80, 110))
popClose.ZIndex = 11
local popBox = Instance.new("TextBox")
popBox.Size = UDim2.new(1, -28, 0, 42)
popBox.Position = UDim2.new(0, 14, 0, 46)
popBox.BackgroundColor3 = Color3.new(1, 1, 1)
popBox.ClearTextOnFocus = false
popBox.Font = Enum.Font.Gotham
popBox.TextScaled = true
popBox.TextColor3 = BROWN
popBox.PlaceholderText = tr("คำอธิษฐาน (ไม่ใส่ก็ได้)", "Your wish (optional)")
popBox.Text = ""
popBox.ZIndex = 11
popBox.Parent = wishPop
corner(popBox, 10) stroke(popBox, Color3.fromRGB(220, 190, 170), 2)
do local p = Instance.new("UIPadding") p.PaddingLeft = UDim.new(0, 10) p.PaddingRight = UDim.new(0, 10) p.PaddingTop = UDim.new(0, 8) p.PaddingBottom = UDim.new(0, 8) p.Parent = popBox end
popBox:GetPropertyChangedSignal("Text"):Connect(function()
	local t = popBox.Text
	local n = utf8.len(t)
	if n and n > Config.WISH_MAX then popBox.Text = t:sub(1, utf8.offset(t, Config.WISH_MAX + 1) - 1) end
end)
local popGo = button(wishPop, tr("🌸 ลอยเลย", "🌸 Float"), UDim2.new(1, -28, 0, 40), UDim2.new(0, 14, 1, -52), PINK)
popGo.ZIndex = 11
local popAt -- ตำแหน่งตอนเปิด (เดินห่างเกิน 8 = ปิดเอง)

local hereBusy = false
-- ปล่อยโคม: ไม่มีหน้าต่างคำอธิษฐาน กดแล้วปล่อยเลย
local function releaseNow()
	if hereBusy then return end
	if not heldSky() then showToast(tr("ถือโคมลอยไว้ในมือก่อนนะ", "Hold the sky lantern first")) return end
	hereBusy = true
	floatBtn.Visible = false
	request("releaseHere")
	task.wait(1.3)
	hereBusy = false
end
local function closePop()
	wishPop.Visible = false
	popAt = nil
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(wishPop) then GuiService.SelectedObject = nil end
end
local function openPop()
	if hereMode == "lantern" then task.spawn(releaseNow) return end
	local id = hereMode == "hang" and heldHang() or heldKrathong()
	if not id or hereBusy then return end
	local def = Config.Types[id]
	popTitle.Text = (def and def.Icon or "🌸") .. " " .. Config.Name(id, LANG)
	popGo.Text = hereMode == "hang" and tr("🏮 แขวนเลย", "🏮 Hang") or tr("🌸 ลอยเลย", "🌸 Float")
	popGo.BackgroundColor3 = hereMode == "hang" and def.Strip or PINK
	popBox.Text = ""
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	popAt = root and root.Position
	floatBtn.Visible = false
	wishPop.Visible = true
	if UserInputService.GamepadEnabled then GuiService.SelectedObject = popGo end
end
local function confirmFloat()
	if hereBusy then return end
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if hereMode == "hang" then
		local hid = heldHang()
		if not hid or not root then closePop() showToast(tr("ถือโคมแขวนไว้ในมือก่อนนะ", "Hold the hanging lantern first")) return end
		local hook = findHook(root)
		if not hook then showToast(tr("เดินไปใต้ตะขอทองที่ยังว่างนะ", "Stand under an empty gold hook")) return end
		hereBusy = true
		local wish = popBox.Text
		closePop()
		request("hang", hid, hook, wish)
		task.wait(0.3)
		hereBusy = false
		return
	end
	local id = heldKrathong()
	if not id or not root then closePop() showToast(tr("ถือกระทงไว้ในมือก่อนนะ", "Hold the krathong in your hand first")) return end
	-- เช็กน้ำอีกรอบตอนกด (อาจเดิน/หมุนตัวไปแล้ว)
	local point = findWaterAhead(ch, root)
	if not point then showToast(tr("หันหน้าเข้าหาน้ำ แล้วเข้าไปใกล้อีกนิดนะ", "Face the water and get a bit closer")) return end
	hereBusy = true
	local wish = popBox.Text
	closePop()
	request("floatHere", id, point, wish)
	task.wait(0.3)
	hereBusy = false
end
floatBtn.Activated:Connect(openPop)
popGo.Activated:Connect(confirmFloat)
popClose.Activated:Connect(closePop)
popBox.FocusLost:Connect(function(enter) if enter and wishPop.Visible then confirmFloat() end end)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonY and floatBtn.Visible and not window.Visible then openPop()
	elseif wishPop.Visible and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape) then closePop() end
end)
task.spawn(function()
	while true do
		local ch = player.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		local id = heldKrathong()
		local hid = heldHang()
		local sid = heldSky()
		-- หน้าต่างเปิดอยู่: ปิดเองถ้าเก็บของ / เดินห่าง
		local popHeld = (hereMode == "hang") and hid or id
		if wishPop.Visible and (not popHeld or not root or (popAt and (root.Position - popAt).Magnitude > 8)) then closePop() end
		local show = false
		if (id or hid or sid) and root and not hereBusy and not praying[ch] and not window.Visible and not wishPop.Visible
			and workspace:FindFirstChild("KrathongStall") then -- ร้านอยู่ในแมพ = กิจกรรมเปิด
			if id and findWaterAhead(ch, root) then
				show = true
				hereMode = "float"
				floatBtn.Text = tr("🌸 ลอยกระทง", "🌸 Float krathong")
				floatBtn.BackgroundColor3 = PINK
			elseif hid and findHook(root) then
				show = true
				hereMode = "hang"
				floatBtn.Text = tr("🏮 แขวนโคม", "🏮 Hang lantern")
				floatBtn.BackgroundColor3 = Config.Types[hid].Strip
			elseif sid and canRelease(ch) then
				-- ใต้หลังคา = ปุ่มสีเทา บอกให้ออกไปที่โล่ง (กดได้ เซิร์ฟตอบเหตุผล)
				show = true
				hereMode = "lantern"
				local open = skyOpen(root)
				floatBtn.Text = open and tr("🏮 ปล่อยโคม", "🏮 Release lantern") or tr("🏮 ออกไปที่โล่งก่อน", "🏮 Find open sky")
				floatBtn.BackgroundColor3 = open and Config.Types[sid].Strip or Color3.fromRGB(165, 150, 140)
			end
		end
		if show and not floatBtn.Visible then
			hereScale.Scale = 0.6
			TweenService:Create(hereScale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		floatBtn.Visible = show
		task.wait(0.2)
	end
end)

-- ============ แสงกลางคืนตอนเทศกาล (2026-11-11 ผู้ใช้ส่งรูปโคมลอยเต็มฟ้า) ============
-- เครื่องนี้ทำเอง: กลางคืน (เวลาส่วนตัว/เวลาเกม แบบ NightLightsClient) + สวิตช์เทศกาลเปิด (มีร้านกระทงในแมพ)
--   Lighting.Bloom: Threshold/Intensity/Size = Config.NIGHT_LOOK (ของ Neon ทั้งแมพฟุ้งขึ้นด้วย) · ถ้าเซิร์ฟ (DayCycle) เปลี่ยนค่าระหว่างนั้น = จำค่าใหม่ไว้คืน แล้วตั้งของเราซ้ำ
--   ColorCorrectionEffect "KrathongNightTint" (ของเราเอง ไม่แตะของเดิม) = ฟ้าน้ำเงินเข้มขึ้น · เช้า/สวิตช์ปิด = คืนค่า Bloom เดิม + ปิด Tint
do
	local BLOOM_KEYS = { "Threshold", "Intensity", "Size" }
	local bloom, saved, applying = nil, nil, false
	local tint
	local function hookBloom()
		if bloom and bloom.Parent then return bloom end
		bloom = Lighting:FindFirstChild("Bloom") or Lighting:FindFirstChildOfClass("BloomEffect")
		if not bloom then return nil end
		for _, k in ipairs(BLOOM_KEYS) do
			bloom:GetPropertyChangedSignal(k):Connect(function()
				if applying or not saved then return end
				local look = Config.NIGHT_LOOK
				if look and bloom[k] ~= look[k] then
					saved[k] = bloom[k] -- เซิร์ฟเปลี่ยนค่า → จำไว้คืนตอนเช้า แล้วตั้งของเราซ้ำ
					applying = true bloom[k] = look[k] applying = false
				end
			end)
		end
		return bloom
	end
	local function setLook(on)
		local look = Config.NIGHT_LOOK
		local b = hookBloom()
		if b then
			if on and look then
				if not saved then saved = {} for _, k in ipairs(BLOOM_KEYS) do saved[k] = b[k] end end
				applying = true
				for _, k in ipairs(BLOOM_KEYS) do if b[k] ~= look[k] then b[k] = look[k] end end
				applying = false
			elseif saved then
				applying = true
				for k, v in pairs(saved) do b[k] = v end
				applying = false
				saved = nil
			end
		end
		if on and look then
			if not tint or not tint.Parent then
				tint = Instance.new("ColorCorrectionEffect")
				tint.Name = "KrathongNightTint"
				tint.Parent = Lighting
			end
			tint.TintColor, tint.Contrast, tint.Saturation, tint.Brightness = look.Tint, look.Contrast, look.Saturation, look.Brightness
			tint.Enabled = true
		elseif tint then
			tint.Enabled = false
		end
	end
	task.spawn(function()
		local last
		while true do
			nightFlag = isNightHere()
			local want = nightFlag and Config.NIGHT_LOOK ~= nil and workspace:FindFirstChild("KrathongStall") ~= nil
			if want ~= last then pcall(setLook, want) last = want end
			task.wait(1)
		end
	end)
end
