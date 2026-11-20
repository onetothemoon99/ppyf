-- BACKUP 2026-11-21 of StarterPlayer.StarterPlayerScripts.MountClient (LocalScript) before the flamingo Wade perk. Restore: paste everything below this line into that script's Source.
-- MountClient: หน้าต่างเลือกสัตว์ขี่ + ปุ่มลัด H + ท่านั่ง/แรงกระโดดตอนขี่ (2026-10-15)
--   เปิดหน้าต่าง: เมนู ☰ → 🐴 สัตว์ขี่ (MoreMenuGui ยิง BindableEvent MountGui.OpenMount)
--   H (คีย์บอร์ด, ไม่ได้พิมพ์แชท) = ขึ้น/ลงตัวที่เลือกไว้ · จอย: เปิดหน้าต่างแล้วเลือกการ์ด
--   ตอนขี่ (Attribute RidingMount บนผู้เล่น ตั้งโดย MountService): เล่นท่านั่ง (Animate.sit) วนไป
--     แรงกระโดด = ค่าเริ่มต้น x MountJump · ความเร็วเดินคูณใน SprintController (MountSpeed)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local tr, lang = Localization.Tr()
local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig"))
if not MountConfig.IsEnabled() then return end -- ระบบสัตว์ขี่ยังไม่เปิด (MountConfig.Enabled) ไม่มีปุ่ม H / หน้าต่างเลือกสัตว์ขี่ (2026-10-16)

local player = Players.LocalPlayer
local request = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MountRequest")

local BASE_JUMP_HEIGHT = StarterPlayer.CharacterJumpHeight
local COLOR_BG = Color3.fromRGB(245, 252, 250)
local COLOR_TEXT = Color3.fromRGB(60, 60, 80)
local COLOR_SUB = Color3.fromRGB(110, 110, 130)
local COLOR_MINT = Color3.fromRGB(175, 235, 215)
local COLOR_LOCKED = Color3.fromRGB(225, 225, 230)

local function mountName(id)
	local def = MountConfig.Mounts[id]
	if not def then return id end
	return lang == "th" and def.DisplayName or def.DisplayNameEn
end
local function rarityName(id)
	local r = MountConfig.Rarities[id] or MountConfig.Rarities.Common
	return lang == "th" and r.Name or r.NameEn
end

-- ============ ท่านั่ง + แรงกระโดด ============
local sitTrack
local function stopSit()
	if sitTrack then
		sitTrack:Stop(0.2)
		sitTrack = nil
	end
end

local function applyRiding()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local mountId = player:GetAttribute("RidingMount")
	humanoid.JumpHeight = BASE_JUMP_HEIGHT * (mountId and (player:GetAttribute("MountJump") or 1) or 1)
	if not mountId then
		stopSit()
		return
	end
	local def = MountConfig.Mounts[mountId]
	if def and def.StandRide then -- ม้าก้านกล้วย: ยืนวิ่งเอง ไม่เล่นท่านั่ง
		stopSit()
		return
	end
	if sitTrack and sitTrack.IsPlaying then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	local animate = character:FindFirstChild("Animate")
	local sitFolder = animate and animate:FindFirstChild("sit")
	local anim = sitFolder and sitFolder:FindFirstChildOfClass("Animation")
	if not (animator and anim) then return end
	sitTrack = animator:LoadAnimation(anim)
	sitTrack.Priority = Enum.AnimationPriority.Action4
	sitTrack.Looped = true
	sitTrack:Play(0.2)
end

player:GetAttributeChangedSignal("RidingMount"):Connect(applyRiding)
player:GetAttributeChangedSignal("MountJump"):Connect(applyRiding)
player.CharacterAdded:Connect(function(character)
	sitTrack = nil
	character:WaitForChild("Humanoid")
	applyRiding()
end)

-- ============ ส่งคำขอ ============
local notifyLabel
local function notify(text)
	if notifyLabel then
		notifyLabel.Text = text or ""
	end
end

local busy = false
local function send(action, mountId)
	if busy then return end
	busy = true
	local ok, res = pcall(function() return request:InvokeServer(action, mountId) end)
	busy = false
	if not ok or not res then
		notify(tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Connection failed. Try again."))
		return
	end
	if not res.ok and res.message then notify(res.message) else notify("") end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end -- พิมพ์แชทอยู่
	if input.KeyCode == Enum.KeyCode.H then
		send("toggle")
	end
end)

-- ============ หน้าต่างเลือกสัตว์ขี่ ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MountGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 8
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local openEvent = Instance.new("BindableEvent")
openEvent.Name = "OpenMount"
openEvent.Parent = screenGui

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

local WIDTH, HEIGHT = 560, 380
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COLOR_BG
main.Active = true
main.SelectionGroup = true
main.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
main.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
main.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
main.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
main.Parent = screenGui
corner(main, 16)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(120, 150, 170); mainStroke.Thickness = 2; mainStroke.Parent = main
local uiScale = Instance.new("UIScale"); uiScale.Parent = main
local camera = workspace.CurrentCamera
local function fit()
	local vp = camera.ViewportSize
	if vp.X < 2 then return end
	uiScale.Scale = math.clamp(math.min((vp.X - 24) / WIDTH, (vp.Y - 40) / HEIGHT), 0.5, 1)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = label(main, tr("🐴 สัตว์ขี่ของฉัน", "🐴 My Mounts"), 20, COLOR_TEXT, true)
title.Size = UDim2.new(1, -60, 0, 36)
title.Position = UDim2.new(0, 16, 0, 8)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.TextColor3 = COLOR_TEXT
closeButton.BackgroundColor3 = Color3.fromRGB(255, 190, 190)
closeButton.Size = UDim2.new(0, 34, 0, 34)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.Selectable = true
closeButton.Parent = main
corner(closeButton, 10)
closeButton.Activated:Connect(function() screenGui.Enabled = false end)

local subtitle = label(main, "", 12, COLOR_SUB)
subtitle.Size = UDim2.new(1, -32, 0, 18)
subtitle.Position = UDim2.new(0, 16, 0, 42)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.BackgroundColor3 = Color3.fromRGB(235, 245, 242)
list.Size = UDim2.new(1, -32, 1, -150)
list.Position = UDim2.new(0, 16, 0, 102) -- ใต้แถวของแต่ง (2026-10-16)
list.ScrollBarThickness = 6
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.Selectable = false
list.Parent = main
corner(list, 12)
local listPad = Instance.new("UIPadding"); listPad.PaddingTop = UDim.new(0, 8); listPad.PaddingLeft = UDim.new(0, 8); listPad.PaddingRight = UDim.new(0, 8); listPad.PaddingBottom = UDim.new(0, 8); listPad.Parent = list
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 116, 0, 122)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list
local function updateCanvas()
	list.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y / math.max(uiScale.Scale, 0.01) + 20)
end
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
uiScale:GetPropertyChangedSignal("Scale"):Connect(updateCanvas)

-- ============ แถวของแต่งสัตว์ขี่ (2026-10-16) ============ แตะเพื่อใส่ / "ไม่ใส่" = ถอด ใส่กับสัตว์ตัวไหนก็ได้
local accRow = Instance.new("ScrollingFrame")
accRow.Name = "Accessories"
accRow.BackgroundTransparency = 1
accRow.Size = UDim2.new(1, -32, 0, 34)
accRow.Position = UDim2.new(0, 16, 0, 64)
accRow.ScrollBarThickness = 4
accRow.ScrollingDirection = Enum.ScrollingDirection.X
accRow.AutomaticCanvasSize = Enum.AutomaticSize.X
accRow.CanvasSize = UDim2.new()
accRow.BorderSizePixel = 0
accRow.Selectable = false
accRow.Parent = main
local accLayout = Instance.new("UIListLayout")
accLayout.FillDirection = Enum.FillDirection.Horizontal
accLayout.Padding = UDim.new(0, 6)
accLayout.SortOrder = Enum.SortOrder.LayoutOrder
accLayout.VerticalAlignment = Enum.VerticalAlignment.Center
accLayout.Parent = accRow

local accOrdered = {}
for id in pairs(MountConfig.Accessories or {}) do table.insert(accOrdered, id) end
table.sort(accOrdered, function(a, b) return MountConfig.Accessories[a].Order < MountConfig.Accessories[b].Order end)

local function accButton(name, text, selected, order, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.LayoutOrder = order
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.Size = UDim2.new(0, 0, 0, 28)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = selected and Color3.new(1, 1, 1) or COLOR_TEXT
	btn.BackgroundColor3 = selected and Color3.fromRGB(150, 110, 230) or Color3.fromRGB(240, 236, 252)
	btn.Selectable = true
	btn.Parent = accRow
	corner(btn, 14)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.Parent = btn
	btn.Activated:Connect(onClick)
	return btn
end

local function renderAccessories()
	for _, c in ipairs(accRow:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local current = player:GetAttribute("MountAccessory")
	if current == "" then current = nil end
	local head = label(accRow, tr("🎀 ของแต่ง:", "🎀 Accessory:"), 12, COLOR_SUB, true)
	head.AutomaticSize = Enum.AutomaticSize.X
	head.Size = UDim2.new(0, 0, 0, 28)
	head.LayoutOrder = 0
	head.TextWrapped = false
	local any = false
	for i, id in ipairs(accOrdered) do
		if player:GetAttribute("MountAccOwned_" .. id) == true then
			any = true
			local def = MountConfig.Accessories[id]
			local name = lang == "th" and def.DisplayName or def.DisplayNameEn
			accButton("Acc_" .. id, (def.Icon or "") .. " " .. name, current == id, i + 1, function()
				send("accessory", current == id and "" or id)
			end)
		end
	end
	if any then
		accButton("Acc_None", tr("ไม่ใส่", "None"), current == nil, 1, function() send("accessory", "") end)
	else
		local hint = label(accRow, tr("ยังไม่มี · สุ่มได้ที่ตู้สัตว์ขี่", "None yet · get them from the mount machine"), 12, COLOR_SUB)
		hint.AutomaticSize = Enum.AutomaticSize.X
		hint.Size = UDim2.new(0, 0, 0, 28)
		hint.LayoutOrder = 1
		hint.TextWrapped = false
	end
end

notifyLabel = label(main, "", 12, Color3.fromRGB(200, 80, 80), true)
notifyLabel.Size = UDim2.new(1, -32, 0, 18)
notifyLabel.AnchorPoint = Vector2.new(0, 1)
notifyLabel.Position = UDim2.new(0, 16, 1, -26)
notifyLabel.TextXAlignment = Enum.TextXAlignment.Left

local footer = label(main, "", 12, COLOR_SUB, true)
footer.Size = UDim2.new(1, -32, 0, 18)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 16, 1, -8)
footer.TextXAlignment = Enum.TextXAlignment.Left

local previewFolder = ReplicatedStorage:FindFirstChild("MountPreviewModels")

-- โหลดเมชรูปสัตว์ขี่ไว้ก่อน (ไม่งั้นเปิดหน้าต่างครั้งแรกบางตัวยังเป็นช่องว่าง)
task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("MountPreviewModels", 30)
	if folder then pcall(function() game:GetService("ContentProvider"):PreloadAsync(folder:GetDescendants()) end) end
end)
local function addPicture(parent, mountId, locked)
	local template = previewFolder and previewFolder:FindFirstChild(mountId)
	if not template or locked then
		local def = MountConfig.Mounts[mountId]
		local t = label(parent, locked and "❔" or (def and def.Icon or "🐾"), 40)
		t.Size = UDim2.new(1, -12, 0, 56)
		t.Position = UDim2.new(0, 6, 0, 18)
		t.TextScaled = true
		return
	end
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, -12, 0, 56)
	vp.Position = UDim2.new(0, 6, 0, 18)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(200, 200, 200)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = parent
	local model = template:Clone()
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	model.Parent = vp
	local cf, bbox = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local radius = bbox.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(cf.Position + (pivot.LookVector + pivot.RightVector * 0.6).Unit * (radius / math.sin(math.rad(15)) * 0.8) + Vector3.new(0, radius * 0.3, 0), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
end

local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = selectBox
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 190, 40); st.Thickness = 3.5; st.Parent = selectBox
end

local ordered = {}
for id in pairs(MountConfig.Mounts) do table.insert(ordered, id) end
table.sort(ordered, function(a, b) return MountConfig.Mounts[a].Order < MountConfig.Mounts[b].Order end)

local function render()
	renderAccessories()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local ridingId = player:GetAttribute("RidingMount")
	local have = 0
	for i, id in ipairs(ordered) do
		local def = MountConfig.Mounts[id]
		local owned = player:GetAttribute("MountOwned_" .. id) == true
		if owned then have += 1 end
		-- ตัวเทศกาลที่ยังไม่มีและไม่อยู่ในตู้แล้ว = ไม่ต้องโชว์ · ตัวที่มี Release ยังไม่ปล่อย = ไม่โชว์ (2026-10-31)
		if owned or not (def.Season or def.Release) or MountConfig.InPool(id) then
			local tier = MountConfig.Rarities[def.Rarity]
			local card = Instance.new("TextButton")
			card.Name = "Card_" .. id
			card.LayoutOrder = i
			card.Text = ""
			card.AutoButtonColor = owned
			card.Selectable = owned
			card.SelectionImageObject = selectBox
			card.BackgroundColor3 = owned and tier.Color:Lerp(Color3.new(1, 1, 1), 0.75) or COLOR_LOCKED
			card.Parent = list
			corner(card, 10)
			local st = Instance.new("UIStroke")
			st.Color = (id == ridingId) and Color3.fromRGB(60, 170, 90) or tier.Color
			st.Thickness = (id == ridingId) and 3.5 or 1.5
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			st.Parent = card
			local badge = label(card, rarityName(def.Rarity), 10, Color3.new(1, 1, 1), true)
			badge.BackgroundTransparency = 0
			badge.BackgroundColor3 = tier.Color
			badge.Size = UDim2.new(0, 62, 0, 15)
			badge.Position = UDim2.new(0, 4, 0, 4)
			corner(badge, 8)
			addPicture(card, id, not owned)
			local name = label(card, owned and mountName(id) or "???", 12, COLOR_TEXT, true)
			name.Size = UDim2.new(1, -8, 0, 26)
			name.Position = UDim2.new(0, 4, 0, 74)
			local stateText
			if id == ridingId then
				stateText = tr("🟢 กำลังขี่ · แตะเพื่อลง", "🟢 Riding · tap to get off")
			elseif owned then
				stateText = string.format(tr("⚡ เร็ว x%s · แตะเพื่อขี่", "⚡ x%s speed · tap to ride"), tostring(def.Speed))
			else
				stateText = def.HelpShop and tr("💚 แลกได้ที่ร้านแลกน้ำใจ", "💚 Get it at the Kindness shop") -- ช้างน้อยใจบุญ 2026-11-03
					or def.Shop and tr("🛒 ซื้อได้ที่ร้านค้าพิเศษ", "🛒 Buy in the special shop") or tr("🔒 สุ่มได้ที่ตู้สัตว์ขี่", "🔒 Get it from the machine")
			end
			local state = label(card, stateText, 10, id == ridingId and Color3.fromRGB(40, 140, 70) or COLOR_SUB, true)
			state.Size = UDim2.new(1, -8, 0, 20)
			state.Position = UDim2.new(0, 4, 1, -22)
			if owned then
				card.Activated:Connect(function()
					if player:GetAttribute("RidingMount") == id then
						send("dismount")
					else
						send("ride", id)
					end
				end)
			end
		end
	end
	subtitle.Text = string.format(tr("สะสมแล้ว %d/%d ตัว · แตะการ์ดเพื่อขึ้นขี่", "Collected %d/%d · tap a card to ride"), have, #ordered)
	footer.Text = UserInputService.KeyboardEnabled and tr("⌨️ กด H เพื่อขึ้น/ลงตัวที่ขี่ล่าสุด", "⌨️ Press H to ride / get off your last mount") or ""
	if have == 0 then
		notify(tr("ยังไม่มีสัตว์ขี่ ไปสุ่มที่ตู้สุ่มสัตว์ขี่ข้างตู้สัตว์เลี้ยงนะ", "No mounts yet. Visit the mount machine next to the pet machine!"))
	end
	updateCanvas()
end

local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
}
local lastSelected
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(main)
end
local function selectDefault()
	if not GAMEPAD_INPUTS[UserInputService:GetLastInputType()] then return end
	local target = lastSelected and list:FindFirstChild(lastSelected)
	if not (target and target.Selectable) then
		target = nil
		for _, id in ipairs(ordered) do
			local c = list:FindFirstChild("Card_" .. id)
			if c and c.Selectable then target = c break end
		end
	end
	GuiService.SelectedObject = target or closeButton
end
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(list) then lastSelected = sel.Name end
end)
closeButton.SelectionImageObject = selectBox

openEvent.Event:Connect(function()
	-- 2026-10-16 ผู้ใช้: ย้ายสัตว์ขี่ไปอยู่ในกระเป๋า (แท็บ 🐴 สัตว์ขี่) เมนู ☰ → สัตว์ขี่ = เปิดกระเป๋าที่แท็บนั้น
	local bag = player.PlayerGui:FindFirstChild("FullInventoryGui")
	local openTab = bag and bag:FindFirstChild("OpenTab")
	if openTab then
		openTab:Fire("mount")
		return
	end
	notify("") -- หากระเป๋าไม่เจอ ใช้หน้าต่างเดิม
	render()
	screenGui.Enabled = true
	task.defer(selectDefault)
end)

local function rerender()
	if not screenGui.Enabled then return end
	local wasInside = selectionInside()
	render()
	if wasInside then task.defer(selectDefault) end
end
player.AttributeChanged:Connect(function(name)
	if name == "RidingMount" or name == "MountEquipped" or name == "MountAccessory" or string.sub(name, 1, 11) == "MountOwned_" or string.sub(name, 1, 14) == "MountAccOwned_" then rerender() end
end)

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screenGui.Enabled and selectionInside() then GuiService.SelectedObject = nil end
end)
UserInputService.InputBegan:Connect(function(input)
	if screenGui.Enabled and input.KeyCode == Enum.KeyCode.ButtonB then screenGui.Enabled = false end
end)

-- ============ ความสามารถพิเศษของตัวที่ขี่อยู่ (เฉพาะตัวเอง) ============
-- Steady (เต่า): ไม่ล้ม (ปิดสถานะ FallingDown / Ragdoll)
-- SlowFall (แกะ): ตกลงช้า (จำกัดความเร็วตก)
-- DoubleJump (ยูนิคอร์น): กระโดดกลางอากาศได้อีก 1 ครั้ง
-- Hover (ไม้กวาด): ร่อนบนผิวน้ำได้ / Swim (คาปิบาร่า): ลอยตัวครึ่งน้ำ (พื้นล่องหนใต้ตัวเฉพาะเครื่องตัวเอง)
-- Swim (คาปิบาร่า) / Hover: ลงน้ำได้ · ตัวอื่นลงน้ำ (ว่ายน้ำ) = ลงจากหลังเอง
local RunService = game:GetService("RunService")

local SLOW_FALL_SPEED = 9
local WATER_OK = { Swim = true, Hover = true }

local function currentPerk()
	local id = player:GetAttribute("RidingMount")
	local def = id and MountConfig.Mounts[id]
	return def and def.Perk
end

-- บินอิสระได้ไหม: ไม้กวาด (Perk Hover) หรือตัวที่ MountConfig ตั้ง Fly = true (ลามะ ขายเป็น Robux 2026-10-16) · บินได้ = ข้ามน้ำได้ด้วย
local function canFly()
	local id = player:GetAttribute("RidingMount")
	local def = id and MountConfig.Mounts[id]
	return def ~= nil and (def.Perk == "Hover" or def.Fly == true)
end

-- ว่ายน้ำได้ไหม: Perk Swim (คาปิบาร่า) หรือตัวที่ MountConfig ตั้ง Swim = true (เต่า 2026-10-23) = ลอยครึ่งน้ำ ไม่ต้องลงจากหลัง
local function canSwim()
	local id = player:GetAttribute("RidingMount")
	local def = id and MountConfig.Mounts[id]
	return def ~= nil and (def.Perk == "Swim" or def.Swim == true)
end

local function seatHeight()
	local id = player:GetAttribute("RidingMount")
	local folder = ReplicatedStorage:FindFirstChild("MountPreviewModels")
	local m = id and folder and folder:FindFirstChild(id)
	return m and tonumber(m:GetAttribute("SeatHeight")) or 3
end

-- ข้อความสั้นๆ กลางล่างจอ
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "MountToast"
toastGui.ResetOnSpawn = false
toastGui.DisplayOrder = 9
toastGui.Parent = player:WaitForChild("PlayerGui")
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -140)
toast.Size = UDim2.new(0, 640, 0, 28) -- 2026-10-19 กว้างขึ้นให้คำแนะนำบินตามเมาส์ไม่ถูกตัด
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 16
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextStrokeTransparency = 0.4
toast.Text = ""
toast.Visible = false
toast.Parent = toastGui
local toastToken = 0
local function showToast(text)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		if toastToken == token then toast.Visible = false end
	end)
end

-- Steady: เปิด/ปิดสถานะล้มตามตัวที่ขี่
local function applySteady()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local id = player:GetAttribute("RidingMount")
	local def = id and MountConfig.Mounts[id]
	local steady = currentPerk() == "Steady" or (def ~= nil and def.Steady == true) -- Steady = true ใน MountConfig (ควาย 2026-10-31)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not steady)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not steady)
end
player:GetAttributeChangedSignal("RidingMount"):Connect(applySteady)
player.CharacterAdded:Connect(function(c) c:WaitForChild("Humanoid") applySteady() end)

-- DoubleJump
local airJumpUsed = false
local lastJumpAt = 0
UserInputService.JumpRequest:Connect(function()
	if currentPerk() ~= "DoubleJump" then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and hrp) then return end
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		lastJumpAt = os.clock()
		return
	end
	if airJumpUsed or os.clock() - lastJumpAt < 0.25 then return end
	airJumpUsed = true
	local v = math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)
	local cur = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(cur.X, v, cur.Z)
end)

-- พื้นล่องหนบนผิวน้ำ (Hover)
local waterPad = Instance.new("Part")
waterPad.Name = "MountWaterPad"
waterPad.Size = Vector3.new(10, 1, 10)
waterPad.Anchored = true
waterPad.Transparency = 1
waterPad.CanCollide = true
waterPad.CanQuery = false
waterPad.CanTouch = false

local waterCheckAt = 0
local waterDismountAt = 0
RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local perk = currentPerk()
	if not (humanoid and hrp) or not perk then
		if waterPad.Parent then waterPad.Parent = nil end
		airJumpUsed = false
		return
	end
	if humanoid.FloorMaterial ~= Enum.Material.Air then airJumpUsed = false end

	if perk == "SlowFall" then
		local v = hrp.AssemblyLinearVelocity
		if v.Y < -SLOW_FALL_SPEED then hrp.AssemblyLinearVelocity = Vector3.new(v.X, -SLOW_FALL_SPEED, v.Z) end
	end

	if perk == "Hover" or canSwim() or canFly() then
		if os.clock() - waterCheckAt > 0.1 then
			waterCheckAt = os.clock()
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { character, waterPad }
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = false
			local reach = humanoid.HipHeight + hrp.Size.Y / 2 + 6
			local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -reach, 0), params)
			if hit and hit.Material == Enum.Material.Water then
				-- ไม้กวาด: ยืนบนผิวน้ำ · คาปิบาร่า: ตัวจมครึ่งหนึ่ง (ผู้ขี่อยู่เหนือน้ำ เหมือนว่ายอยู่)
				local sink = (canSwim() and not canFly()) and seatHeight() * 0.55 or 0
				waterPad.CFrame = CFrame.new(hrp.Position.X, hit.Position.Y - sink - 0.5, hrp.Position.Z)
				if not waterPad.Parent then waterPad.Parent = workspace end
			elseif waterPad.Parent then
				waterPad.Parent = nil
			end
		end
	elseif waterPad.Parent then
		waterPad.Parent = nil
	end

	if humanoid:GetState() == Enum.HumanoidStateType.Swimming and not (WATER_OK[perk] or canFly() or canSwim()) and os.clock() - waterDismountAt > 1 then
		waterDismountAt = os.clock()
		task.spawn(send, "dismount")
		showToast(tr("🌊 ตัวนี้ว่ายน้ำไม่ได้ ลงจากหลังแล้ว (เต่า/คาปิบาร่า/ไม้กวาด/ลามะลงน้ำได้)", "🌊 This mount can't swim, you got off (turtle/capybara/broom/llama can)"))
	end
end)

-- ============ บินอิสระ (ไม้กวาด Perk Hover + ตัวที่ Fly = true เช่นลามะ) 2026-10-16 ============
-- ค้าง Space / ปุ่มกระโดด / ปุ่ม ⬆ บนจอ / จอ A = บินขึ้น · ค้าง Q หรือ C / ปุ่ม ⬇ บนจอ / จอ L2 = ลง · ไม่กด = ลอยค้างความสูงเดิม
-- เดินหน้า/เลี้ยวตามปกติ (ตัวละครคุมในอากาศ) · สูงสุด FLY_MAX_Y (กำแพงเขตเกมสูงถึง y 371) · ลงถึงพื้น = เดินบนพื้นตามเดิม
local FLY_UP_SPEED = 22
local FLY_DOWN_SPEED = 26
local FLY_MAX_Y = 300
local flyDownHeld = false
local flyUpHeld = false
-- 2026-10-19 ผู้ใช้: บินขึ้นลงตามการหันเมาส์/กล้อง — เดินหน้าอยู่แล้วหันกล้องเงยเหนือขอบฟ้า = บินขึ้น, ก้มต่ำ = บินลง
-- ช่วงกลาง (กล้องก้มนิดหน่อยแบบปกติ) = บินระดับเดิม · ปุ่ม Space/Q/⬆/⬇ ยังใช้ได้และมีผลก่อน
local PITCH_LEVEL_TOP = 0.0 -- LookVector.Y สูงกว่านี้ = ไต่ขึ้น
local PITCH_LEVEL_BOTTOM = -0.35 -- ต่ำกว่านี้ = ร่อนลง (กล้องปกติมองลงราว -0.2 ถึง -0.3)
local PITCH_FULL = 0.45 -- เกินขอบช่วงกลางเท่านี้ = ความเร็วเต็ม

-- 2026-10-16 ผู้ใช้: "มีแต่ปุ่มขึ้น ไม่มีปุ่มลง" (เดิม ⬇ โชว์เฉพาะมือถือ และทับปุ่ม X ของผีน้อย)
-- ตอนนี้ขี่ไม้กวาด = ปุ่ม ⬆ / ⬇ บนจอทุกเครื่อง เรียงแนวตั้ง ซ้ายของแถวปุ่มด้านขวา · คอมมีป้ายปุ่มคีย์บอร์ด (Space / Q)
-- 2026-10-28 ผู้ใช้: ไม่ต้องแสดงปุ่ม ⬆ / ⬇ แล้ว (บินตามกล้อง + Space/Q/ปุ่มกระโดด/จอยยังใช้ได้) · แสดงคืน = true
local SHOW_FLY_BUTTONS = false
local function makeFlyButton(name, text, posY, onHold)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 28
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = Color3.fromRGB(150, 100, 220)
	b.BackgroundTransparency = 0.2
	b.AutoButtonColor = true
	b.Selectable = false
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Size = UDim2.new(0, 56, 0, 56)
	b.Position = UDim2.new(1, -165, 1, posY)
	b.Visible = false
	b.Parent = toastGui
	corner(b, 28)
	local st = Instance.new("UIStroke") st.Color = Color3.new(1, 1, 1) st.Thickness = 2 st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border st.Parent = b
	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.BackgroundTransparency = 1
	key.AnchorPoint = Vector2.new(0.5, 1)
	key.Position = UDim2.new(0.5, 0, 1, -2)
	key.Size = UDim2.new(1, 0, 0, 12)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 10
	key.TextColor3 = Color3.new(1, 1, 1)
	key.Parent = b
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then onHold(true) end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then onHold(false) end
	end)
	return b, key
end
local flyUpButton, flyUpKey = makeFlyButton("FlyUp", "⬆", -300, function(v) flyUpHeld = v end)
local flyDownButton, flyDownKey = makeFlyButton("FlyDown", "⬇", -235, function(v) flyDownHeld = v end)

local function keyHeld(...)
	if UserInputService:GetFocusedTextBox() then return false end
	for _, k in ipairs({ ... }) do
		if UserInputService:IsKeyDown(k) then return true end
	end
	return false
end
local function padHeld(button)
	for _, pad in ipairs({ Enum.UserInputType.Gamepad1, Enum.UserInputType.Gamepad2 }) do
		if UserInputService:IsGamepadButtonDown(pad, button) then return true end
	end
	return false
end

-- แรงต้านแรงโน้มถ่วงตอนบิน (ตั้งความเร็วทุกเฟรมอย่างเดียว ระหว่างเฟรมยังตกลงทีละนิด ลอยค้างไม่อยู่)
local antiGravity
local function setAntiGravity(hrp, on)
	if on then
		if not (antiGravity and antiGravity.Parent == hrp) then
			if antiGravity then antiGravity:Destroy() end
			local att = Instance.new("Attachment")
			att.Name = "BroomFlyAttachment"
			att.Parent = hrp
			antiGravity = Instance.new("VectorForce")
			antiGravity.Name = "BroomAntiGravity"
			antiGravity.Attachment0 = att
			antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
			antiGravity.ApplyAtCenterOfMass = true
			antiGravity.Parent = hrp
		end
		antiGravity.Force = Vector3.new(0, hrp.AssemblyMass * workspace.Gravity, 0)
		antiGravity.Enabled = true
	elseif antiGravity then
		antiGravity.Enabled = false
	end
end

local wasFlyMount = false
RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local isFly = humanoid and hrp and canFly() and humanoid.Health > 0
	local showFly = SHOW_FLY_BUTTONS and isFly and true or false
	flyUpButton.Visible = showFly
	flyDownButton.Visible = showFly
	local keys = showFly and not UserInputService.TouchEnabled
	flyUpKey.Text = keys and "Space" or ""
	flyDownKey.Text = keys and "Q" or ""
	if isFly and not wasFlyMount then
		local icon = currentPerk() == "Hover" and "🧹 " or "✨ "
		showToast(icon .. (UserInputService.TouchEnabled and (SHOW_FLY_BUTTONS and tr("เดินหน้าแล้วเงยกล้อง = บินขึ้น · ก้มกล้อง = ลง (หรือค้าง ⬆ / ⬇)", "Move forward and tilt the camera up to climb, down to dive (or hold ⬆ / ⬇)")
			or tr("เดินหน้าแล้วเงยกล้อง = บินขึ้น · ก้มกล้อง = ลง (ค้างปุ่มกระโดด = ขึ้น)", "Move forward and tilt the camera up to climb, down to dive (hold Jump to rise)"))
			or tr("เดินหน้าแล้วหันเมาส์ขึ้น = บินขึ้น · หันลง = ลง (หรือค้าง Space / Q)", "Move forward and aim the mouse up to climb, down to dive (or hold Space / Q)")))
	end
	wasFlyMount = isFly and true or false
	if not isFly then
		flyDownHeld = false
		flyUpHeld = false
		if antiGravity then antiGravity.Enabled = false end
		return
	end
	local up = flyUpHeld or humanoid.Jump or keyHeld(Enum.KeyCode.Space) or padHeld(Enum.KeyCode.ButtonA)
	local down = flyDownHeld or keyHeld(Enum.KeyCode.Q, Enum.KeyCode.C) or padHeld(Enum.KeyCode.ButtonL2)
	-- บินตามกล้อง: ต้องกำลังเดินไปทางที่กล้องหัน (ถอยหลังไม่นับ)
	local pitchVy = 0
	local cam = workspace.CurrentCamera
	local move = humanoid.MoveDirection
	if cam and move.Magnitude > 0.1 then
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local forward = flat.Magnitude > 0.05 and move.Unit:Dot(flat.Unit) or 0
		if forward > 0.3 then
			if look.Y > PITCH_LEVEL_TOP then
				pitchVy = math.clamp((look.Y - PITCH_LEVEL_TOP) / PITCH_FULL, 0, 1) * FLY_UP_SPEED * forward
			elseif look.Y < PITCH_LEVEL_BOTTOM then
				pitchVy = -math.clamp((PITCH_LEVEL_BOTTOM - look.Y) / PITCH_FULL, 0, 1) * FLY_DOWN_SPEED * forward
			end
		end
	end
	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
	local climbByPitch = pitchVy > 2
	if onGround and not up and not climbByPitch then -- เดินบนพื้นตามปกติ (เงยกล้องตอนวิ่ง = ขึ้นบินได้)
		setAntiGravity(hrp, false)
		return
	end
	setAntiGravity(hrp, true)
	local vy = 0
	if up and not down then
		vy = hrp.Position.Y < FLY_MAX_Y and FLY_UP_SPEED or 0
	elseif down and not up then
		vy = -FLY_DOWN_SPEED
	elseif pitchVy ~= 0 then
		vy = (pitchVy > 0 and hrp.Position.Y >= FLY_MAX_Y) and 0 or pitchVy
		if climbByPitch then up = true end -- ให้เปลี่ยนสถานะเป็นลอยตัวเหมือนกดขึ้น
	end
	if up and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	local v = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(v.X, vy, v.Z)
end)

-- ============ ปุ่มเรียกสัตว์ขี่ มือถือ + คอม (2026-10-16) ============
-- ทุกเครื่อง (คอมแสดงด้วย ป้าย "ขี่ H" · 2026-10-16) · มีสัตว์ขี่อย่างน้อย 1 ตัว · วางเหนือปุ่มวิ่ง (SprintGui) ซ้ายปุ่มวิ่งเป็นที่ของปุ่ม ⬇ ไม้กวาด
-- กด = "toggle" เหมือน H: ไม่ได้ขี่ = ขึ้นตัวที่เลือกไว้ · ขี่อยู่ = ลง
local summonGui = Instance.new("ScreenGui")
summonGui.Name = "MountSummonGui"
summonGui.ResetOnSpawn = false
summonGui.DisplayOrder = 5
summonGui.Parent = player:WaitForChild("PlayerGui")

local summonButton = Instance.new("TextButton")
summonButton.Name = "MountSummonButton"
summonButton.AnchorPoint = Vector2.new(0.5, 0.5)
summonButton.Size = UDim2.fromOffset(56, 56)
summonButton.Position = UDim2.new(1, -70, 1, -240)
summonButton.BackgroundColor3 = Color3.fromRGB(255, 248, 230)
summonButton.BackgroundTransparency = 0.05
summonButton.AutoButtonColor = false
summonButton.Selectable = false
summonButton.Text = ""
summonButton.Visible = false
summonButton.Parent = summonGui
corner(summonButton, 999)
local summonStroke = Instance.new("UIStroke")
summonStroke.Thickness = 3
summonStroke.Color = Color3.fromRGB(150, 100, 60)
summonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
summonStroke.Parent = summonButton
local summonPop = Instance.new("UIScale")
summonPop.Parent = summonButton

local summonIcon = Instance.new("TextLabel")
summonIcon.BackgroundTransparency = 1
summonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
summonIcon.Position = UDim2.fromScale(0.5, 0.42)
summonIcon.Size = UDim2.fromScale(0.6, 0.6)
summonIcon.Text = "🐴"
summonIcon.TextScaled = true
summonIcon.Parent = summonButton

local summonCaption = Instance.new("TextLabel")
summonCaption.BackgroundTransparency = 1
summonCaption.AnchorPoint = Vector2.new(0.5, 1)
summonCaption.Position = UDim2.new(0.5, 0, 1, -4)
summonCaption.Size = UDim2.new(1, 0, 0, 13)
summonCaption.Font = Enum.Font.GothamBold
summonCaption.TextSize = 11
summonCaption.TextColor3 = Color3.fromRGB(150, 100, 60)
summonCaption.Parent = summonButton

local function ownsAnyMount()
	for id in pairs(MountConfig.Mounts) do
		if player:GetAttribute("MountOwned_" .. id) == true then return true end
	end
	return false
end

local function renderSummon()
	local riding = player:GetAttribute("RidingMount") ~= nil
	local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	summonCaption.Text = touch and (riding and tr("ลง", "Off") or tr("ขี่", "Ride"))
		or (riding and tr("ลง H", "Off (H)") or tr("ขี่ H", "Ride (H)"))
	summonButton.BackgroundColor3 = riding and Color3.fromRGB(255, 205, 150) or Color3.fromRGB(255, 248, 230)
end

local summonBusy = false
summonButton.Activated:Connect(function()
	if summonBusy then return end
	summonBusy = true
	summonPop.Scale = 0.88
	TweenService:Create(summonPop, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local ok, res = pcall(function() return request:InvokeServer("toggle") end)
	summonBusy = false
	if not ok or not res then
		showToast(tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Connection failed. Try again."))
	elseif not res.ok and res.message then
		showToast(res.message)
	end
end)

local function placeSummon()
	local sprintGui = player.PlayerGui:FindFirstChild("SprintGui")
	local sprint = sprintGui and sprintGui:FindFirstChild("SprintButton")
	if sprint and sprint.AbsoluteSize.X > 0 then
		summonGui.IgnoreGuiInset = sprintGui.IgnoreGuiInset
		summonGui.ScreenInsets = sprintGui.ScreenInsets
		local size = math.floor(sprint.AbsoluteSize.X * 0.9)
		summonButton.Size = UDim2.fromOffset(size, size)
		-- ปุ่มวางหุ่นของผีน้อย (GhostPlaceGui.Holder) อยู่เหนือปุ่มวิ่งเหมือนกัน เปิดอยู่ = วางต่อขึ้นไปเหนือปุ่มนั้น
		local below = sprint
		local ghostGui = player.PlayerGui:FindFirstChild("GhostPlaceGui")
		local ghost = ghostGui and ghostGui:FindFirstChild("Holder")
		if ghost and ghostGui.Enabled and ghost.Visible and ghost.AbsoluteSize.X > 0
			and ghost.AbsolutePosition.Y < sprint.AbsolutePosition.Y then
			below = ghost
		end
		local center = below.AbsolutePosition + below.AbsoluteSize / 2 - summonGui.AbsolutePosition
		summonButton.Position = UDim2.fromOffset(sprint.AbsolutePosition.X + sprint.AbsoluteSize.X / 2 - summonGui.AbsolutePosition.X, center.Y - below.AbsoluteSize.Y / 2 - size / 2 - 10)
		return sprint.Visible
	end
	summonButton.Size = UDim2.fromOffset(56, 56)
	summonButton.Position = UDim2.new(1, -70, 1, -240)
	return true
end

player:GetAttributeChangedSignal("RidingMount"):Connect(renderSummon)
renderSummon()
task.spawn(function()
	while summonGui.Parent do
		local sprintShown = placeSummon()
		-- ปุ่มวิ่งซ่อน (แผงตกปลา/แผงขวาบนเปิด) = ซ่อนด้วย ไม่ให้ทับแผงพวกนั้น
		summonButton.Visible = sprintShown and ownsAnyMount()
		task.wait(1)
	end
end)

applyRiding()
