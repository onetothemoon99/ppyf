-- BACKUP 2026-11-14 before free reusable sign item (no shop)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.SignClient (LocalScript)
-- Restore: paste everything below this header into that script's Source in Studio

-- SignClient (2026-11-14): ป้ายเขียนข้อความ ฝั่งผู้เล่น (คู่กับ ServerScriptService.Sign.SignService)
--   ถือป้าย = ปุ่ม ✏️ เขียนป้าย (จอย Y) + 📍 ปักป้าย (จอย X) + วงบนพื้นตรงจุดที่จะปัก (เขียว = ปักได้ / แดง = ไม่ได้)
--   หน้าต่างเขียน = ช่องพิมพ์ + ตัวนับ n/20 (นับแบบ SignConfig.CountChars) · เซิร์ฟกรองข้อความแล้วตั้งบนป้ายเอง
--   ปุ่ม E เก็บป้ายที่ปัก: เปิดเฉพาะป้ายของเรา (เซิร์ฟสร้างแบบปิดไว้)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("SignConfig"))
if not Config.ENABLED then return end

local player = Players.LocalPlayer
local _, LANG = require(ReplicatedStorage:WaitForChild("Localization")).Tr()
local EN = LANG == "en"
local function tr(th, en) return EN and en or th end

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local requestRemote = remotes:WaitForChild("SignRequest")
local noticeRemote = remotes:WaitForChild("SignNotice")

local WOOD = Color3.fromRGB(150, 105, 65)
local CREAM = Color3.fromRGB(255, 248, 235)
local BROWN = Color3.fromRGB(90, 60, 35)
local GREEN = Color3.fromRGB(90, 175, 95)
local RED = Color3.fromRGB(215, 85, 85)
local FONT = Enum.Font.FredokaOne

-- ============ UI ============
local gui = Instance.new("ScreenGui")
gui.Name = "SignGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 12) c.Parent = o end
local function stroke(o, col, th) local s = Instance.new("UIStroke") s.Color = col or BROWN s.Thickness = th or 2 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o end
local function button(parent, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos or UDim2.new()
	b.BackgroundColor3 = color or WOOD
	b.AutoButtonColor = true
	b.Font = FONT
	b.Text = text
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = parent
	corner(b, 10)
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 5) pad.PaddingBottom = UDim.new(0, 5) pad.PaddingLeft = UDim.new(0, 8) pad.PaddingRight = UDim.new(0, 8) pad.Parent = b
	return b
end

local uiScale = Instance.new("UIScale")
local function fitScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	uiScale.Scale = math.clamp(math.min(vp.X / 1100, vp.Y / 620), 0.6, 1.15)
end

-- ข้อความเด้ง
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 90)
toast.Size = UDim2.new(0, 480, 0, 44)
toast.BackgroundColor3 = CREAM
toast.Font = FONT
toast.TextScaled = true
toast.TextColor3 = BROWN
toast.Visible = false
toast.ZIndex = 50
toast.Parent = gui
corner(toast, 12) stroke(toast, WOOD, 2)
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
noticeRemote.OnClientEvent:Connect(showToast)

-- ปุ่มตอนถือป้าย (ตำแหน่งเดียวกับปุ่มลอยกระทง ถือพร้อมกันไม่ได้)
local bar = Instance.new("Frame")
bar.Name = "SignButtons"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -98)
bar.Size = UDim2.new(0, 430, 0, 54)
bar.BackgroundTransparency = 1
bar.Visible = false
bar.Parent = gui
uiScale.Parent = bar
local writeBtn = button(bar, tr("✏️ เขียนป้าย", "✏️ Write sign"), UDim2.new(0, 205, 1, 0), UDim2.new(0, 0, 0, 0), WOOD)
local plantBtn = button(bar, tr("📍 ปักป้าย", "📍 Plant sign"), UDim2.new(0, 205, 1, 0), UDim2.new(1, -205, 0, 0), GREEN)
stroke(writeBtn, Color3.new(1, 1, 1), 2) stroke(plantBtn, Color3.new(1, 1, 1), 2)
local barScale = 1

-- หน้าต่างเขียนป้าย
local pop = Instance.new("Frame")
pop.Name = "WritePopup"
pop.AnchorPoint = Vector2.new(0.5, 0.5)
pop.Position = UDim2.fromScale(0.5, 0.45)
pop.Size = UDim2.new(0, 460, 0, 250)
pop.BackgroundColor3 = CREAM
pop.Visible = false
pop.ZIndex = 10
pop.Parent = gui
corner(pop, 16) stroke(pop, BROWN, 3)
local popScale = Instance.new("UIScale") popScale.Parent = pop
local popTitle = Instance.new("TextLabel")
popTitle.BackgroundTransparency = 1
popTitle.Size = UDim2.new(1, -24, 0, 40)
popTitle.Position = UDim2.new(0, 12, 0, 10)
popTitle.Font = FONT
popTitle.TextScaled = true
popTitle.TextColor3 = BROWN
popTitle.Text = tr("✏️ เขียนบนป้าย (ทุกคนเห็น)", "✏️ Write on the sign (everyone sees it)")
popTitle.ZIndex = 11
popTitle.Parent = pop
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -40, 0, 64)
box.Position = UDim2.new(0, 20, 0, 60)
box.BackgroundColor3 = Config.BOARD_COLOR
box.Font = FONT
box.TextSize = 30
box.TextColor3 = Config.TEXT_COLOR
box.PlaceholderText = tr("พิมพ์ข้อความที่นี่", "Type here")
box.PlaceholderColor3 = Color3.fromRGB(150, 120, 90)
box.ClearTextOnFocus = false
box.TextWrapped = true
box.Text = ""
box.ZIndex = 11
box.Parent = pop
corner(box, 10) stroke(box, BROWN, 2)
local counter = Instance.new("TextLabel")
counter.BackgroundTransparency = 1
counter.Size = UDim2.new(1, -40, 0, 26)
counter.Position = UDim2.new(0, 20, 0, 130)
counter.Font = FONT
counter.TextScaled = true
counter.TextXAlignment = Enum.TextXAlignment.Right
counter.TextColor3 = BROWN
counter.ZIndex = 11
counter.Parent = pop
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -140, 0, 26)
hint.Position = UDim2.new(0, 20, 0, 130)
hint.Font = Enum.Font.Gotham
hint.TextScaled = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextColor3 = Color3.fromRGB(140, 110, 80)
hint.Text = tr("คำที่ไม่เหมาะสมจะถูกกรองเป็น ###", "Bad words get filtered as ###")
hint.ZIndex = 11
hint.Parent = pop
local saveBtn = button(pop, tr("✅ เขียนเลย", "✅ Write"), UDim2.new(0, 190, 0, 52), UDim2.new(0.5, 10, 1, -70), GREEN)
local cancelBtn = button(pop, tr("ยกเลิก", "Cancel"), UDim2.new(0, 190, 0, 52), UDim2.new(0.5, -200, 1, -70), Color3.fromRGB(170, 150, 130))
saveBtn.ZIndex = 11 cancelBtn.ZIndex = 11

-- ย่อ/ขยายตามจอ (แถบปุ่ม + หน้าต่างเขียน)
fitScale()
popScale.Scale = uiScale.Scale
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() fitScale() popScale.Scale = uiScale.Scale end) end

local function heldSign()
	local ch = player.Character
	local t = ch and ch:FindFirstChildWhichIsA("Tool")
	return (t and t:GetAttribute("IsSign")) and t or nil
end

local function updateCounter()
	local text = Config.Clean(box.Text)
	local n = Config.CountChars(text) or 999
	counter.Text = n .. "/" .. Config.MAX_CHARS
	local over = n > Config.MAX_CHARS
	counter.TextColor3 = over and RED or BROWN
	saveBtn.BackgroundColor3 = over and Color3.fromRGB(165, 150, 140) or GREEN
end
box:GetPropertyChangedSignal("Text"):Connect(updateCounter)

local sending = false
local function request(action, a)
	if sending then return nil end
	sending = true
	local ok, res = pcall(function() return requestRemote:InvokeServer(action, a) end)
	sending = false
	if not ok or type(res) ~= "table" then
		showToast(tr("เชื่อมต่อไม่ได้ ลองใหม่", "Connection problem, try again"))
		return nil
	end
	showToast(res.message)
	return res
end

local function closePop()
	pop.Visible = false
	box:ReleaseFocus()
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(pop) then GuiService.SelectedObject = nil end
end
local function openPop()
	local t = heldSign()
	if not t then return end
	box.Text = t:GetAttribute("SignText") or ""
	updateCounter()
	pop.Visible = true
	if UserInputService.GamepadEnabled then GuiService.SelectedObject = saveBtn else box:CaptureFocus() end
end
local function confirmWrite()
	if not pop.Visible then return end
	local text = Config.Clean(box.Text)
	if (Config.CountChars(text) or 999) > Config.MAX_CHARS then
		showToast(tr("ยาวเกิน " .. Config.MAX_CHARS .. " ตัวอักษร", "Longer than " .. Config.MAX_CHARS .. " characters"))
		return
	end
	local res = request("write", text)
	if res and res.ok then closePop() end
end
writeBtn.Activated:Connect(openPop)
saveBtn.Activated:Connect(confirmWrite)
cancelBtn.Activated:Connect(closePop)
box.FocusLost:Connect(function(enter) if enter then confirmWrite() end end)

-- ============ จุดปัก + วงบนพื้น ============
local marker = Instance.new("Part")
marker.Name = "SignPlantMarker"
marker.Shape = Enum.PartType.Cylinder
marker.Size = Vector3.new(0.12, 2.2, 2.2)
marker.Anchored = true
marker.CanCollide = false
marker.CanQuery = false
marker.CanTouch = false
marker.CastShadow = false
marker.Material = Enum.Material.Neon
marker.Transparency = 0.45

local function signFolder() return workspace:FindFirstChild("PlayerSigns") end

-- คืน จุดบนพื้น, ปักได้ไหม (ตรวจคร่าวๆ เซิร์ฟตรวจจริงอีกที)
local function aimPoint()
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return nil, false end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local from = root.Position + look * 4 + Vector3.new(0, 4, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { ch, marker }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	local f = signFolder() if f then table.insert(ignore, f) end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	local hit = workspace:Raycast(from, Vector3.new(0, -14, 0), params)
	if not hit then return nil, false end
	local ok = hit.Instance == workspace.Terrain and Config.GROUND[hit.Material] == true and hit.Normal.Y >= 0.7 and Config.InNoZone(hit.Position) == nil
	return hit.Position, ok
end

local function doPlant()
	local t = heldSign()
	if not t then return end
	if (t:GetAttribute("SignText") or "") == "" then
		showToast(tr("เขียนข้อความบนป้ายก่อนค่อยปัก", "Write on the sign before planting it"))
		return
	end
	local pos = aimPoint()
	if not pos then
		showToast(tr("ไม่เจอพื้นตรงหน้า", "No ground in front of you"))
		return
	end
	request("plant", pos)
end
plantBtn.Activated:Connect(doPlant)

UserInputService.InputBegan:Connect(function(input, processed)
	if pop.Visible and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape) then closePop() return end
	if not bar.Visible or pop.Visible then return end
	if input.KeyCode == Enum.KeyCode.ButtonY then openPop()
	elseif input.KeyCode == Enum.KeyCode.ButtonX then doPlant() end
end)

-- วนเช็กถือป้าย / วงจุดปัก
task.spawn(function()
	while true do
		local t = heldSign()
		local show = t ~= nil
		if pop.Visible and not t then closePop() end
		if show and not bar.Visible then
			uiScale.Scale = uiScale.Scale * 0.6
			local target = uiScale.Scale / 0.6
			TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = target }):Play()
		end
		bar.Visible = show
		if show then
			local pos, ok = aimPoint()
			if pos then
				marker.Color = ok and GREEN or RED
				marker.CFrame = CFrame.new(pos + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
				marker.Parent = workspace
			else
				marker.Parent = nil
			end
			plantBtn.BackgroundColor3 = (pos and ok) and GREEN or Color3.fromRGB(165, 150, 140)
		else
			marker.Parent = nil
		end
		task.wait(0.15)
	end
end)

-- ============ ปุ่ม E เก็บป้าย: เฉพาะของเรา ============
local function fixPrompt(p)
	if not p:IsA("ProximityPrompt") then return end
	if p.Name == "SignPickupPrompt" then
		local m = p:FindFirstAncestorWhichIsA("Model")
		p.Enabled = m ~= nil and m:GetAttribute("OwnerUserId") == player.UserId
		if EN then p.ObjectText, p.ActionText = "📝 Your sign", "Pick up" end
	elseif p.Name == "SignShopPrompt" and EN then
		p.ObjectText, p.ActionText = "📝 Sign Shop", "Buy sign 5k 💰"
	end
end
workspace.DescendantAdded:Connect(fixPrompt)
task.spawn(function()
	local f = workspace:WaitForChild("PlayerSigns", 60)
	if f then for _, d in ipairs(f:GetDescendants()) do fixPrompt(d) end end
	local shop = workspace:WaitForChild("SignShop", 60)
	if shop then
		for _, d in ipairs(shop:GetDescendants()) do
			fixPrompt(d)
			if EN and d:IsA("TextLabel") and d.Name == "ShopText" then d.Text = "📝 Sign Shop 📝" end
		end
	end
end)
