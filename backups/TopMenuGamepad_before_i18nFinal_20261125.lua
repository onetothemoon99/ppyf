-- BACKUP of StarterPlayer.StarterPlayerScripts.TopMenuGamepad before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.TopMenuGamepad.Source in Studio
-- TopMenuGamepad: จอยกด ⬆️ (D-pad ขึ้น) = เข้าไปเลือกแถวปุ่มมุมขวาบน (ร้าน กระเป๋า สัตว์เลี้ยง โดเนท สมุดปลา ช่วยเหลือ VIP)
-- ◀ ▶ เลื่อน · A เปิด · B ออก (ปุ่มพวกนี้ปกติตั้ง Selectable = false ไว้ จะได้ไม่โดนเลือกโดยไม่ตั้งใจ)
-- หาปุ่มเองทุกครั้งที่กด (ปุ่มกลมขนาดปุ่ม Roblox ที่อยู่แถวบนสุดครึ่งขวา) ตอนเข้าแถวเปิด Selectable + ต่อทาง ◀ ▶ ให้
-- ออกแถว (B / เปิดหน้าต่างที่เลือกปุ่มของมันเอง) คืนค่าเดิมทุกปุ่ม

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- กรอบทองวงกลมรอบปุ่มที่เลือก
local ring = Instance.new("Frame")
ring.BackgroundTransparency = 1
ring.Size = UDim2.new(1, 8, 1, 8)
ring.Position = UDim2.new(0, -4, 0, -4)
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = ring
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 190, 40); s.Thickness = 3.5; s.Parent = ring
end

-- ป้ายบอกปุ่มใต้แถว (ตอนอยู่ในแถว)
local hintGui = Instance.new("ScreenGui")
hintGui.Name = "TopMenuGamepadHint"
hintGui.ResetOnSpawn = false
hintGui.DisplayOrder = 12
hintGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
hintGui.Parent = playerGui
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(1, 0)
hint.Position = UDim2.new(1, -16, 0, 62)
hint.Size = UDim2.new(0, 0, 0, 26)
hint.AutomaticSize = Enum.AutomaticSize.X
hint.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
hint.BackgroundTransparency = 0.05
hint.Font = Enum.Font.GothamBold
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(80, 50, 40)
hint.Text = "◀ ▶ เลือกเมนู · A เปิด · B ออก"
hint.Visible = false
hint.Parent = hintGui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = hint
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(140, 100, 65); s.Thickness = 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = hint
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 12); p.PaddingRight = UDim.new(0, 12); p.Parent = hint
end

-- ปุ่มในแถวมุมขวาบน เรียงซ้ายไปขวา
local function collectButtons()
	local list = {}
	local half = camera.ViewportSize.X / 2
	for _, sg in ipairs(playerGui:GetChildren()) do
		if sg:IsA("ScreenGui") and sg.Enabled and sg ~= hintGui then
			for _, b in ipairs(sg:GetChildren()) do
				if b:IsA("GuiButton") and b.Visible and b.AbsoluteSize.Y >= 28 and b.AbsoluteSize.Y <= 60
					and b.AbsolutePosition.Y <= 30 and b.AbsolutePosition.X > half then
					table.insert(list, b)
				end
			end
		end
	end
	-- แถวซ้ายบน (ต่อจากปุ่ม Roblox) เช่น ปุ่มเพลง 🎵 อยู่ใน TopbarRowGui.Row
	local topbar = playerGui:FindFirstChild("TopbarRowGui")
	local row = topbar and topbar.Enabled and topbar:FindFirstChild("Row")
	if row then
		for _, b in ipairs(row:GetChildren()) do
			if b:IsA("GuiButton") and b.Visible then table.insert(list, b) end
		end
	end
	table.sort(list, function(a, b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
	return list
end

local saved = {} -- [button] = ค่าเดิม { Selectable, SelectionImageObject, NextSelection* }
local lastButtonName = nil -- เข้าแถวครั้งหน้า เริ่มที่ปุ่มที่ใช้ล่าสุด

local function inRow(obj)
	return obj ~= nil and saved[obj] ~= nil
end

local function exitRow()
	for b, old in pairs(saved) do
		if b.Parent then
			b.Selectable = old.Selectable
			b.SelectionImageObject = old.Image
			b.NextSelectionLeft, b.NextSelectionRight = old.Left, old.Right
			b.NextSelectionUp, b.NextSelectionDown = old.Up, old.Down
		end
	end
	local sel = GuiService.SelectedObject
	if inRow(sel) then GuiService.SelectedObject = nil end
	saved = {}
	hint.Visible = false
end

local function enterRow()
	local list = collectButtons()
	if #list == 0 then return end
	exitRow()
	local start = list[1]
	for i, b in ipairs(list) do
		saved[b] = {
			Selectable = b.Selectable, Image = b.SelectionImageObject,
			Left = b.NextSelectionLeft, Right = b.NextSelectionRight, Up = b.NextSelectionUp, Down = b.NextSelectionDown,
		}
		b.Selectable = true
		b.SelectionImageObject = ring
		b.NextSelectionLeft = list[i - 1] or b
		b.NextSelectionRight = list[i + 1] or b
		b.NextSelectionUp = b
		b.NextSelectionDown = b
		if b.Name == lastButtonName then start = b end
	end
	hint.Visible = true
	GuiService.SelectedObject = start
end

-- เลือกอยู่ในแถว จำปุ่มล่าสุดไว้ / การเลือกหลุดออกจากแถว (หน้าต่างที่เปิดเลือกปุ่มของมันเอง หรือถูกล้าง) = คืนค่าเดิม
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	local sel = GuiService.SelectedObject
	if inRow(sel) then
		lastButtonName = sel.Name
	elseif next(saved) then
		task.defer(function()
			if not inRow(GuiService.SelectedObject) then exitRow() end
		end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.DPadUp then
		-- ไม่มีอะไรถูกเลือกอยู่ (เดินเล่นปกติ) = เข้าแถว / กำลังเลือกปุ่มในหน้าต่างอื่นอยู่ = ปล่อยให้ลูกศรเลื่อนปกติ
		if GuiService.SelectedObject == nil and not UserInputService:GetFocusedTextBox() then
			enterRow()
		end
	elseif input.KeyCode == Enum.KeyCode.ButtonB and inRow(GuiService.SelectedObject) then
		exitRow()
	end
end)

-- เลิกใช้จอย (ขยับเมาส์/แตะจอ) ระหว่างอยู่ในแถว = ออกแถว
UserInputService.LastInputTypeChanged:Connect(function(inputType)
	if next(saved) and not inputType.Name:find("Gamepad") then exitRow() end
end)

-- ทดสอบใน Studio (จำลองปุ่ม D-pad ไม่ได้): PlayerGui.TopMenuGamepadHint.TestEnter:Fire() / TestExit:Fire()
if game:GetService("RunService"):IsStudio() then
	local enter = Instance.new("BindableEvent"); enter.Name = "TestEnter"; enter.Parent = hintGui
	local leave = Instance.new("BindableEvent"); leave.Name = "TestExit"; leave.Parent = hintGui
	enter.Event:Connect(enterRow)
	leave.Event:Connect(exitRow)
end
