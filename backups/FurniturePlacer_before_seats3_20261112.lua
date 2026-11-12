-- BACKUP 2026-11-12 before "seats3" (RiversideLog / DuckFloat / KrathongPavilion)
-- Studio path: StarterPlayer.StarterPlayerScripts.FurniturePlacer
-- Restore: open that script in Studio, replace its whole Source with everything below the line of dashes.
-- ------------------------------------------------------------
-- FurniturePlacer: ถือของตกแต่ง (Tool ที่มี IsFurniture / FurnId) = โชว์ร่างโปร่งของชิ้นนั้น + ไกด์วิธีวาง (2026-10-16 ผู้ใช้ขอ)
--   ร่างโปร่งเขียว = วางได้ / แดง = วางไม่ได้ (บอกเหตุผลในไกด์) · หน้าชิ้นหันเข้าหาตัวเรา หมุนเพิ่มทีละ 45°
--   คอม: เมาส์เล็งจุด · คลิกซ้าย = วาง · R = หมุน · 2026-10-20 มีแถวปุ่มหมุน/วาง/เก็บเหมือนมือถือด้วย (เมาส์อยู่บนปุ่ม = ร่างโปร่งหยุดตาม)
--   มือถือ: แตะพื้นเพื่อย้ายร่างโปร่ง แล้วกดปุ่ม ✔ วาง (แตะจอไม่วางทันที กันเผลอ)
--   จอย: ร่างโปร่งอยู่หน้าตัว · R2 = วาง · RB = หมุน
--   ส่ง FurnitureRequest("place", id, ตำแหน่ง, มุม) เซิร์ฟเวอร์ตรวจซ้ำ (FurnitureService) · วางสำเร็จ = เก็บของในมือ
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local LANG = Localization.GetLanguage(player)
local function tr(th, en) return Localization.Pick(LANG, th, en) end

local MAX_RANGE = 20 -- ต้องน้อยกว่า FurnitureService.MAX_RANGE (24)
local MAX_STEP = 8 -- = FurnitureService.MAX_STEP_FREE
local ROTATE_STEP = math.rad(45)
local COLOR_OK = Color3.fromRGB(90, 220, 110)
local COLOR_BAD = Color3.fromRGB(235, 80, 80)

local activeTool, ghost, footprint, highlight, guide, renderConn = nil, nil, nil, nil, nil, nil
-- 2026-11-01 ผู้ใช้ขอ: ไกด์บอกว่านั่งแล้วหันหน้าไปทางไหน = ลูกศรสีเหลืองลอยเหนือที่นั่งแต่ละที่ (เห็นทะลุร่างโปร่ง)
--   ทิศมาจาก Attachment "SeatFacing" ใน ReplicatedStorage.MountPreviewModels.<id> (คัดจาก Seat จริงใน ServerStorage.MountFurniture เพิ่มชิ้นใหม่ต้องใส่ด้วย)
--   ที่นอน (หน้าหงายขึ้นฟ้า เช่น เปลดอกไม้) ไม่มีลูกศร
local seatArrows = {} -- { { model, local = CFrame เทียบ pivot ร่างโปร่ง } }
local ARROW_COLOR = Color3.fromRGB(255, 215, 60)
local rotOffset = 0
local lastAim = nil -- { pos, yaw, ok }
local touchScreenPos = nil -- มือถือ: จุดที่แตะพื้นล่าสุด
local busy = false
local ui = {}

local function lastInputKind()
	local t = UserInputService:GetLastInputType()
	if t == Enum.UserInputType.Touch then return "touch" end
	if t.Name:match("^Gamepad") then return "pad" end
	return "pc"
end

local function placedFolder() return workspace:FindFirstChild("PlacedFurniture") end

-- ============ ไกด์บนจอ ============
local function makeGuide()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FurniturePlaceGuide"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 56)
	panel.Size = UDim2.new(0, 330, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	-- 2026-10-16 ผู้ใช้: เหลือแค่ "กำลังวาง: ชื่อ" พื้นหลังโปร่งใส (สถานะดูจากสีร่างโปร่ง เขียว/แดง)
	panel.BackgroundTransparency = 1
	panel.Parent = gui
	local pad = Instance.new("UIPadding") pad.PaddingTop = UDim.new(0, 8) pad.PaddingBottom = UDim.new(0, 8) pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10) pad.Parent = panel
	local list = Instance.new("UIListLayout") list.Padding = UDim.new(0, 4) list.SortOrder = Enum.SortOrder.LayoutOrder list.HorizontalAlignment = Enum.HorizontalAlignment.Center list.Parent = panel
	local maxW = Instance.new("UISizeConstraint") maxW.MaxSize = Vector2.new(330, 1000) maxW.Parent = panel

	local function label(order, size, bold, color)
		local l = Instance.new("TextLabel")
		l.LayoutOrder = order
		l.Size = UDim2.new(1, 0, 0, 0)
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.BackgroundTransparency = 1
		l.TextWrapped = true
		l.TextSize = size
		l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		l.TextColor3 = color or Color3.fromRGB(60, 45, 30)
		l.Parent = panel
		return l
	end
	ui.title = label(1, 18, true, Color3.fromRGB(255, 255, 255))
	ui.title.TextStrokeTransparency = 0.2
	ui.title.TextStrokeColor3 = Color3.fromRGB(70, 40, 110)
	ui.facing = label(2, 14, true, Color3.fromRGB(255, 225, 90))
	ui.facing.TextStrokeTransparency = 0.2
	ui.facing.TextStrokeColor3 = Color3.fromRGB(70, 40, 20)
	ui.facing.Visible = false
	ui.status = label(2, 15, true)
	ui.hint = label(3, 13, false)
	ui.note = label(4, 12, false, Color3.fromRGB(120, 100, 80))
	ui.status.Visible = false
	ui.hint.Visible = false
	ui.note.Visible = false

	local row = Instance.new("Frame")
	row.LayoutOrder = 5
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundTransparency = 1
	row.Parent = panel
	ui.row = row -- ปุ่ม หมุน/วาง/เก็บ โชว์ทุกเครื่องแบบมือถือ (2026-10-20 ผู้ใช้ขอ เดิมเฉพาะมือถือ) · มือถือแตะจอไม่วางทันที ต้องกด ✔
	local rowList = Instance.new("UIListLayout") rowList.FillDirection = Enum.FillDirection.Horizontal rowList.Padding = UDim.new(0, 8) rowList.HorizontalAlignment = Enum.HorizontalAlignment.Center rowList.SortOrder = Enum.SortOrder.LayoutOrder rowList.Parent = row
	local function button(order, text, color, width)
		local b = Instance.new("TextButton")
		b.LayoutOrder = order
		b.Size = UDim2.new(0, width, 1, 0)
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.TextSize = 15
		b.Font = Enum.Font.GothamBold
		b.Parent = row
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		return b
	end
	ui.rotate = button(1, tr("หมุน 45°", "Rotate"), Color3.fromRGB(120, 140, 200), 120)
	ui.place = button(2, tr("✔ วาง", "✔ Place"), Color3.fromRGB(90, 175, 85), 100)
	ui.pickup = button(3, tr("🧺 เก็บ", "🧺 Pick up"), Color3.fromRGB(215, 140, 80), 90)
	return gui
end

-- ============ ร่างโปร่ง ============
local function buildGhost(furnId)
	local folder = ReplicatedStorage:FindFirstChild("MountPreviewModels")
	local template = folder and folder:FindFirstChild(furnId)
	if not template then return nil end
	local model = template:Clone()
	model.Name = "FurnitureGhost"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			if d.Transparency < 1 then d.Transparency = math.max(d.Transparency, 0.35) end
		elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("Sound") then
			d:Destroy()
		end
	end
	return model
end

-- ลูกศรแบนชี้ไปทาง -Z ของตัวเอง (ก้าน + หัวลูกศร 2 ขา) มี Highlight AlwaysOnTop = เห็นแม้อยู่ในร่างโปร่ง
local function makeArrow()
	local model = Instance.new("Model")
	model.Name = "SeatFacingArrow"
	local function piece(name, size, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = ARROW_COLOR
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = model
		return p
	end
	model.PrimaryPart = piece("Shaft", Vector3.new(0.22, 0.08, 0.9), CFrame.new(0, 0, -0.45))
	for _, side in ipairs({ 1, -1 }) do
		piece("Head", Vector3.new(0.22, 0.08, 0.55), CFrame.new(0, 0, -0.95) * CFrame.Angles(0, math.rad(40) * side, 0) * CFrame.new(0, 0, 0.27))
	end
	local hl = Instance.new("Highlight")
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillColor = ARROW_COLOR
	hl.FillTransparency = 0.15
	hl.OutlineColor = Color3.fromRGB(90, 55, 10)
	hl.OutlineTransparency = 0.2
	hl.Parent = model
	model.WorldPivot = CFrame.new()
	return model
end

local function clearArrows()
	for _, a in ipairs(seatArrows) do a.model:Destroy() end
	seatArrows = {}
end

-- อ่าน SeatFacing ของร่างโปร่ง → ลูกศรเหนือที่นั่ง ชี้ทิศหน้าตอนนั่ง (ตำแหน่งเทียบ pivot เก็บไว้ ย้ายตามร่างทุกเฟรม)
local function buildArrows(model)
	clearArrows()
	local pivot = model:GetPivot()
	for _, att in ipairs(model:GetDescendants()) do
		if att:IsA("Attachment") and att.Name == "SeatFacing" then
			local lc = pivot:ToObjectSpace(att.WorldCFrame)
			local look = lc.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if math.abs(look.Y) < 0.7 and flat.Magnitude > 0.01 then
				flat = flat.Unit
				local start = lc.Position + Vector3.new(0, 1.7, 0) - flat * 0.3
				table.insert(seatArrows, { model = makeArrow(), localCf = CFrame.lookAt(start, start + flat) })
			end
		end
	end
	return #seatArrows
end

local function sizeOf(model)
	local _, size = model:GetBoundingBox()
	return size
end

-- ตรวจจุดวางแบบเดียวกับ FurnitureService (เซิร์ฟเวอร์ตรวจซ้ำอีกที) คืน ok, ข้อความ
local function checkSpot(hit, cf, size, hrp, humanoid)
	if humanoid.SeatPart then return false, tr("ลุกจากที่นั่งก่อนนะ", "Stand up first") end
	if not hit then return false, tr("เล็งที่พื้นเรียบๆ", "Aim at flat ground") end
	if hit.Material == Enum.Material.Water then return false, tr("วางในน้ำไม่ได้", "Can't place in water") end
	local flat = (hit.Position - hrp.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > MAX_RANGE then return false, tr("ไกลเกินไป เดินเข้าไปใกล้ๆ", "Too far, walk closer") end
	local feetY = hrp.Position.Y - humanoid.HipHeight - hrp.Size.Y / 2
	if math.abs(hit.Position.Y - feetY) > MAX_STEP then return false, tr("พื้นตรงนั้นสูง/ต่ำเกินไป", "The ground there is too uneven") end
	local ignore = { ghost, footprint }
	local folder = placedFolder() if folder then table.insert(ignore, folder) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignore
	overlap.RespectCanCollide = true
	local boxSize = Vector3.new(size.X * 0.8, math.max(size.Y - 0.6, 1), size.Z * 0.8)
	local boxCf = cf + Vector3.new(0, 0.5 + boxSize.Y / 2, 0)
	for _, part in ipairs(workspace:GetPartBoundsInBox(boxCf, boxSize, overlap)) do
		if not part:IsA("Terrain") and part.CanCollide and part.Transparency < 1 then
			return false, tr("มีของขวางอยู่ ลองที่โล่งๆ", "Something is in the way")
		end
	end
	return true, tr("✅ วางตรงนี้ได้", "✅ You can place it here")
end

local function updateTexts()
	if not activeTool then return end
	local def = MountConfig.Furniture[activeTool:GetAttribute("FurnId")]
	local name = def and (LANG == "th" and def.DisplayName or def.DisplayNameEn or def.DisplayName) or "?"
	ui.title.Text = "🪑 " .. tr("กำลังวาง: ", "Placing: ") .. name
	local kind = lastInputKind()
	if kind == "touch" then
		ui.hint.Text = tr("แตะพื้นเพื่อเลือกจุด แล้วกด ✔ วาง", "Tap the ground to pick a spot, then press ✔ Place")
	elseif kind == "pad" then
		ui.hint.Text = tr("R2 = วาง · RB = หมุน · ร่างโปร่งอยู่หน้าตัวเรา", "R2 = place · RB = rotate · the ghost sits in front of you")
	else
		ui.hint.Text = tr("เมาส์เล็งจุด · คลิกซ้าย = วาง · R = หมุน", "Aim with the mouse · Left click = place · R = rotate")
	end
	local placed = player:GetAttribute("PlacedFurniture")
	ui.note.Text = (placed and tr("วางใหม่ = ชิ้นเดิมย้ายมาที่นี่ · ", "Placing again moves your current piece · ") or "")
		.. tr("วางได้ทีละ 1 ชิ้น · ใครก็มานั่งได้ · ออกเกมแล้วหายเอง · เก็บของในมือ = ยกเลิก", "1 piece at a time · anyone can sit · gone when you leave · put it away to cancel")
	ui.pickup.Visible = placed ~= nil
	ui.row.Visible = true
	-- ปุ่มหมุนบอกคีย์ลัดตามเครื่อง (ผู้ใช้ขอ 2026-10-20): คอม = R · จอย = RB · มือถือ = ไม่มี
	local rotateKey = (kind == "pc" and " (R)") or (kind == "pad" and " (RB)") or ""
	ui.rotate.Text = tr("หมุน 45°", "Rotate") .. rotateKey
end

local function yawToward(fromPos, toPos)
	local d = (toPos - fromPos) * Vector3.new(1, 0, 1)
	if d.Magnitude < 0.01 then return 0 end
	d = d.Unit
	return math.atan2(-d.X, -d.Z) -- CFrame.Angles(0, yaw, 0).LookVector = d (หน้า -Z หันเข้าหาตัวเรา)
end

local function step()
	if not (activeTool and ghost) then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid) then return end
	local hidden = player:GetAttribute("PhotoMode") == true
	ghost.Parent = hidden and nil or workspace
	footprint.Parent = hidden and nil or workspace
	guide.Enabled = not hidden

	local size = sizeOf(ghost)
	local ignore = { ghost, footprint }
	local folder = placedFolder() if folder then table.insert(ignore, folder) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false

	local kind = lastInputKind()
	-- เมาส์ชี้อยู่บนแถวปุ่ม = ไม่ย้ายร่างโปร่ง (ไม่งั้นเลื่อนไปกด ✔ แล้วร่างไปอยู่ใต้ปุ่ม)
	if kind == "pc" and lastAim and ui.row and ui.row.Visible then
		local m = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		local p, s = ui.row.AbsolutePosition, ui.row.AbsoluteSize
		if m.X >= p.X - 8 and m.X <= p.X + s.X + 8 and m.Y >= p.Y - 8 and m.Y <= p.Y + s.Y + 8 then
			updateTexts()
			return
		end
	end
	local hit
	if kind == "pad" or (kind == "touch" and not touchScreenPos) then
		local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
		local target = hrp.Position + look.Unit * (5 + math.max(size.X, size.Z) / 2)
		hit = workspace:Raycast(target + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), params)
	else
		local camera = workspace.CurrentCamera
		local screen = kind == "touch" and touchScreenPos or UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(screen.X, screen.Y)
		hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
		-- เล็งโดนผนัง/ด้านข้าง: หาพื้นใต้จุดนั้นอีกที
		if hit and hit.Normal.Y < 0.6 then
			hit = workspace:Raycast(hit.Position + hit.Normal * 0.5 + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), params)
		end
	end

	local pos = hit and hit.Position or (hrp.Position - Vector3.new(0, humanoid.HipHeight + hrp.Size.Y / 2, 0) + hrp.CFrame.LookVector * 6)
	local yaw = yawToward(pos, hrp.Position) + rotOffset
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	ghost:PivotTo(cf)
	for _, a in ipairs(seatArrows) do
		a.model.Parent = hidden and nil or workspace
		a.model:PivotTo(cf * a.localCf)
	end
	local ok, message = checkSpot(hit, cf, size, hrp, humanoid)
	lastAim = { pos = pos, yaw = yaw, ok = ok }

	local color = ok and COLOR_OK or COLOR_BAD
	highlight.FillColor = color
	highlight.OutlineColor = color
	footprint.Color = color
	local r = math.max(size.X, size.Z) + 0.6
	footprint.Size = Vector3.new(0.15, r, r)
	footprint.CFrame = CFrame.new(pos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ui.status.Text = ok and message or ("❌ " .. message)
	ui.status.TextColor3 = ok and Color3.fromRGB(50, 140, 60) or Color3.fromRGB(200, 60, 60)
	ui.place.BackgroundColor3 = ok and Color3.fromRGB(90, 175, 85) or Color3.fromRGB(160, 160, 160)
	updateTexts()
end

local function request(...)
	local remote = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("FurnitureRequest")
	if not remote then return nil end
	local args = table.pack(...)
	local ok, res = pcall(function() return remote:InvokeServer(table.unpack(args, 1, args.n)) end)
	return ok and type(res) == "table" and res or { ok = false, message = tr("เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง", "Connection failed. Try again.") }
end

local function flash(text, good)
	if not ui.status then return end
	ui.status.Text = text
	ui.status.TextColor3 = good and Color3.fromRGB(50, 140, 60) or Color3.fromRGB(200, 60, 60)
end

local stop
local function tryPlace()
	if busy or not activeTool or not lastAim then return end
	if not lastAim.ok then return end
	busy = true
	local tool = activeTool
	local res = request("place", tool:GetAttribute("FurnId"), lastAim.pos, lastAim.yaw)
	busy = false
	if res and res.ok then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and tool.Parent == player.Character then humanoid:UnequipTools() end -- วางเสร็จ = เก็บของในมือ ไกด์ปิดเอง
	elseif res then
		if activeTool then task.defer(function() flash("❌ " .. (res.message or tr("วางไม่สำเร็จ", "Couldn't place it")), false) end) end
	end
end

local function rotate()
	rotOffset = (rotOffset + ROTATE_STEP) % (math.pi * 2)
end

local function onAction(name, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if name == "FurnRotate" then rotate() return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end

function stop()
	activeTool = nil
	lastAim = nil
	touchScreenPos = nil
	if renderConn then renderConn:Disconnect() renderConn = nil end
	if ghost then ghost:Destroy() ghost = nil end
	clearArrows()
	if footprint then footprint:Destroy() footprint = nil end
	highlight = nil
	if guide then guide.Enabled = false end
	ContextActionService:UnbindAction("FurnRotate")
end

local function start(tool)
	stop()
	local furnId = tool:GetAttribute("FurnId")
	ghost = buildGhost(furnId)
	if not ghost then return end
	activeTool = tool
	rotOffset = 0
	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = ghost
	ghost.Parent = workspace
	footprint = Instance.new("Part")
	footprint.Name = "FurnitureGhostFootprint"
	footprint.Shape = Enum.PartType.Cylinder
	footprint.Material = Enum.Material.Neon
	footprint.Transparency = 0.6
	footprint.Anchored = true
	footprint.CanCollide = false
	footprint.CanQuery = false
	footprint.CanTouch = false
	footprint.CastShadow = false
	footprint.Parent = workspace
	if not guide then
		guide = makeGuide()
		ui.place.Activated:Connect(tryPlace)
		ui.rotate.Activated:Connect(rotate)
		ui.pickup.Activated:Connect(function()
			if busy then return end
			busy = true
			local res = request("pickup")
			busy = false
			if res and res.ok then flash(tr("🧺 เก็บชิ้นที่วางไว้แล้ว", "🧺 Picked up"), true) end
		end)
	end
	guide.Enabled = true
	local arrowCount = buildArrows(ghost)
	ui.facing.Text = tr("➡️ ลูกศรสีเหลือง = ทิศที่หันหน้าตอนนั่ง", "➡️ Yellow arrow = the way you face when seated")
	ui.facing.Visible = arrowCount > 0
	ContextActionService:BindActionAtPriority("FurnRotate", onAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.R, Enum.KeyCode.ButtonR1)
	renderConn = RunService.RenderStepped:Connect(step)
end

-- มือถือ: แตะพื้น = ย้ายร่างโปร่ง (ไม่วางทันที)
UserInputService.TouchTapInWorld:Connect(function(position, processed)
	if activeTool and not processed then touchScreenPos = position end
end)

local hooked = setmetatable({}, { __mode = "k" })
local function hookTool(tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("IsFurniture") or hooked[tool] then return end
	hooked[tool] = true
	tool.Equipped:Connect(function() start(tool) end)
	tool.Unequipped:Connect(function() if activeTool == tool then stop() end end)
	tool.Destroying:Connect(function() if activeTool == tool then stop() end end)
	-- คอม/จอย: คลิกซ้าย / R2 = วาง · มือถือ: แตะจอ = เลือกจุด (วางด้วยปุ่ม ✔)
	tool.Activated:Connect(function()
		if activeTool == tool and lastInputKind() ~= "touch" then tryPlace() end
	end)
	if tool.Parent == player.Character then start(tool) end
end

local function hookContainer(container)
	if not container then return end
	container.ChildAdded:Connect(hookTool)
	for _, c in ipairs(container:GetChildren()) do hookTool(c) end
end

local function onCharacter(character)
	stop()
	hookContainer(character)
	hookContainer(player:WaitForChild("Backpack"))
end
if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)
player.CharacterRemoving:Connect(stop)
