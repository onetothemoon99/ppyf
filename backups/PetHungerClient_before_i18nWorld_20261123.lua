-- BACKUP of StarterPlayer.StarterPlayerScripts.PetHungerClient before Thai/English world signs (i18n phase 4, 2026-11-23)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.PetHungerClient.Source in Studio
-- PetHungerClient: แถบความหิวเหนือหัวสัตว์เลี้ยง + ป้าย "ให้อาหาร" (เห็นเฉพาะสัตว์เลี้ยงของตัวเอง)
-- ป้ายให้อาหารขึ้นเฉพาะตอนถืออาหารสัตว์อยู่ แถบความหิวขึ้นตอนถืออาหารสัตว์ หรือตอนหิวเหลือไม่ถึงครึ่ง

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local tr = Localization.Tr()

local player = Players.LocalPlayer
local petFeed = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PetFeed")

-- โหลดเสียงเคี้ยว (เล่นจากเซิร์ฟเวอร์ใน PetManager ตอนให้อาหาร) ไว้ก่อน ครั้งแรกที่ป้อนจะได้ดังทันที ไม่ต้องรอโหลด
task.spawn(function()
	pcall(function()
		-- ใส่เป็น Sound ไม่ใช่สตริง: สตริงเปล่าจะโหลดเป็นรูป → "Asset type does not match requested type"
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://137096768206416" -- ต้องตรงกับ FEED_SOUND_ID ใน PetManager
		game:GetService("ContentProvider"):PreloadAsync({ s })
		s:Destroy()
	end)
end)

local SHOW_BELOW = 50 -- หิวเหลือต่ำกว่านี้ โชว์แถบเหนือหัวเสมอ เตือนว่าถึงเวลาให้อาหาร

local tracked = {} -- [petModel] = { prompt, billboard, fill, label, petId }
local refreshPicker -- ป้ายเลือกสัตว์ (ประกาศไว้ก่อน นิยามท้ายไฟล์)

local function holdingProduce()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("IsPetFood") == true -- ป้อนได้เฉพาะอาหารสัตว์
end

local function hungerColor(value)
	if value > 50 then return Color3.fromRGB(110, 200, 90) end
	if value > 20 then return Color3.fromRGB(240, 190, 60) end
	return Color3.fromRGB(230, 80, 70)
end

local function refresh(model)
	local entry = tracked[model]
	if not entry then return end
	local value = player:GetAttribute("PetHunger_" .. entry.petId) or 100
	local holding = holdingProduce()
	entry.fill.Size = UDim2.new(value / 100, 0, 1, 0)
	entry.fill.BackgroundColor3 = hungerColor(value)
	entry.label.Text = (value <= 0 and tr("😵 หิวจนไม่ทำงาน", "😵 Too hungry to work") or "🍖 " .. math.floor(value + 0.5) .. "%")
	entry.billboard.Enabled = holding or value < SHOW_BELOW
	entry.prompt.Enabled = holding and value < 100
end

local function refreshAll()
	for model in pairs(tracked) do refresh(model) end
	if refreshPicker then refreshPicker() end
end

local function track(model)
	if tracked[model] then return end
	if model:GetAttribute("OwnerUserId") ~= player.UserId then return end
	local petId = model:GetAttribute("PetId")
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not petId or not root then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FeedPrompt"
	prompt.ActionText = tr("ให้อาหาร", "Feed")
	prompt.ObjectText = model:GetAttribute("PetDisplayName") or petId
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F -- แยกจากปุ่ม E เก็บเกี่ยว กันกดผิดตอนสัตว์ยืนข้างต้นผัก
	prompt.Enabled = false
	prompt.Parent = root
	prompt.Triggered:Connect(function()
		petFeed:FireServer(petId)
	end)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HungerBar"
	billboard.Size = UDim2.new(0, 70, 0, 22)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 60
	billboard.Enabled = false
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 12)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	local back = Instance.new("Frame")
	back.Size = UDim2.new(1, 0, 0, 7)
	back.Position = UDim2.new(0, 0, 0, 14)
	back.BackgroundColor3 = Color3.fromRGB(60, 45, 40)
	back.BorderSizePixel = 0
	back.Parent = billboard
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	tracked[model] = { prompt = prompt, billboard = billboard, fill = fill, label = label, petId = petId }
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			tracked[model] = nil
			if refreshPicker then refreshPicker() end
		end
	end)
	refresh(model)
	if refreshPicker then refreshPicker() end
end

local function tryTrack(obj)
	if obj:IsA("Model") and obj.Parent == workspace and obj:GetAttribute("PetId") then
		track(obj)
	end
end

for _, obj in ipairs(workspace:GetChildren()) do tryTrack(obj) end
workspace.ChildAdded:Connect(function(obj)
	-- รอ Attribute/ชิ้นส่วนมาถึงเครื่องก่อน
	task.wait(0.5)
	tryTrack(obj)
end)

player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 10) == "PetHunger_" or string.sub(name, 1, 9) == "PetLives_" then refreshAll() end
end)

local function hookCharacter(character)
	character.ChildAdded:Connect(refreshAll)
	character.ChildRemoved:Connect(refreshAll)
	refreshAll()
end
if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)

-- ============ ป้ายเลือกสัตว์ตอนถืออาหารสัตว์ (เพิ่ม 2026-10-09) ============
-- ถืออาหารสัตว์ = มีป้ายสัตว์ที่พาออกมาเหนือแถบไอเทม แตะตัวไหน = ตัวนั้นหยุดกิจกรรมแล้ววิ่งมากินอาหาร (เซิร์ฟเวอร์: PetManager.callPetToEat)
-- ยืนใกล้สัตว์แล้วกด F เหมือนเดิมก็ยังได้ (FeedPrompt ด้านบน)
local CALL_SECONDS = 12 -- ตรงกับ CALL_TIMEOUT ใน PetManager
local pickerGui = Instance.new("ScreenGui")
pickerGui.Name = "PetFeedPicker"
pickerGui.ResetOnSpawn = false
pickerGui.DisplayOrder = 8
pickerGui.Enabled = false
pickerGui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -104)
holder.Size = UDim2.new(0, 0, 0, 0)
holder.AutomaticSize = Enum.AutomaticSize.XY
holder.BackgroundTransparency = 1
holder.Parent = pickerGui
local holderList = Instance.new("UIListLayout")
holderList.FillDirection = Enum.FillDirection.Vertical
holderList.HorizontalAlignment = Enum.HorizontalAlignment.Center
holderList.Padding = UDim.new(0, 4)
holderList.SortOrder = Enum.SortOrder.LayoutOrder
holderList.Parent = holder

local pickerTitle = Instance.new("TextLabel")
pickerTitle.LayoutOrder = 1
pickerTitle.BackgroundTransparency = 1
pickerTitle.AutomaticSize = Enum.AutomaticSize.XY
pickerTitle.Font = Enum.Font.GothamBold
pickerTitle.TextSize = 13
pickerTitle.TextColor3 = Color3.new(1, 1, 1)
pickerTitle.TextStrokeTransparency = 0.35
pickerTitle.Text = tr("🥫 แตะสัตว์ที่อยากให้กินอาหาร", "🥫 Tap a pet to feed")
pickerTitle.Parent = holder

local chipRow = Instance.new("Frame")
chipRow.LayoutOrder = 2
chipRow.BackgroundTransparency = 1
chipRow.AutomaticSize = Enum.AutomaticSize.XY
chipRow.Size = UDim2.new(0, 0, 0, 0)
chipRow.Parent = holder
local rowList = Instance.new("UIListLayout")
rowList.FillDirection = Enum.FillDirection.Horizontal
rowList.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowList.Padding = UDim.new(0, 8)
rowList.SortOrder = Enum.SortOrder.LayoutOrder
rowList.Parent = chipRow

local chips = {}        -- [petId] = { button, stroke, name, fill, pct, lastValue }
local calledUntil = {}  -- [petId] = os.clock() ที่สัตว์ยังกำลังวิ่งมา
local pickerKey = ""

-- อิ่มเต็ม 100% อยู่แล้วไม่ต้องแสดงในป้าย (ผู้เล่นขอ 2026-10-09) ยกเว้นแมวเก้าชีวิตที่ชีวิตยังไม่ครบ (ป้อนแล้วชีวิตกลับมาครบ)
local NINE_LIVES = 9 -- ตรงกับ NineLives ของแมวเก้าชีวิตใน PetDefinitions (ตัวเดียวที่มีชีวิต)
local function needsFood(petId)
	if (player:GetAttribute("PetHunger_" .. petId) or 100) < 100 then return true end
	local lives = player:GetAttribute("PetLives_" .. petId)
	return lives ~= nil and lives < NINE_LIVES
end

local function pickerPets()
	local list = {}
	for model, entry in pairs(tracked) do
		if needsFood(entry.petId) then
			table.insert(list, { petId = entry.petId, name = model:GetAttribute("PetDisplayName") or entry.petId })
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

local function makeChip(order, pet)
	local button = Instance.new("TextButton")
	button.Name = "Chip_" .. pet.petId
	button.LayoutOrder = order
	button.Size = UDim2.new(0, 132, 0, 52)
	button.BackgroundColor3 = Color3.fromRGB(255, 244, 230)
	button.AutoButtonColor = true
	button.Text = ""
	button.Selectable = false
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(240, 150, 170)
	stroke.Parent = button

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 8, 0, 5)
	name.Size = UDim2.new(1, -16, 0, 20)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 13
	name.TextColor3 = Color3.fromRGB(95, 60, 45)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = "🐾 " .. pet.name
	name.Parent = button

	local back = Instance.new("Frame")
	back.Position = UDim2.new(0, 8, 0, 30)
	back.Size = UDim2.new(1, -16, 0, 14)
	back.BackgroundColor3 = Color3.fromRGB(225, 210, 195)
	back.BorderSizePixel = 0
	back.Parent = button
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local pct = Instance.new("TextLabel")
	pct.BackgroundTransparency = 1
	pct.Size = UDim2.new(1, 0, 1, 0)
	pct.Font = Enum.Font.GothamBold
	pct.TextSize = 10
	pct.TextColor3 = Color3.new(1, 1, 1)
	pct.TextStrokeTransparency = 0.4
	pct.ZIndex = 3
	pct.Parent = back

	button.Parent = chipRow
	local chip = { button = button, stroke = stroke, name = name, fill = fill, pct = pct, lastValue = nil, label = "🐾 " .. pet.name }
	button.Activated:Connect(function()
		local value = player:GetAttribute("PetHunger_" .. pet.petId) or 100
		if value < 100 then
			calledUntil[pet.petId] = os.clock() + CALL_SECONDS
			task.delay(CALL_SECONDS + 0.2, function() if refreshPicker then refreshPicker() end end)
		end
		petFeed:FireServer(pet.petId, "call")
		if refreshPicker then refreshPicker() end
	end)
	return chip
end

refreshPicker = function()
	local pets = pickerPets()
	local show = holdingProduce() and #pets > 0
	pickerGui.Enabled = show
	if not show then return end
	local ids = {}
	for _, pet in ipairs(pets) do table.insert(ids, pet.petId) end
	local key = table.concat(ids, ",")
	if key ~= pickerKey then
		pickerKey = key
		for _, chip in pairs(chips) do chip.button:Destroy() end
		chips = {}
		for i, pet in ipairs(pets) do chips[pet.petId] = makeChip(i, pet) end
	end
	local now = os.clock()
	for petId, chip in pairs(chips) do
		local value = player:GetAttribute("PetHunger_" .. petId) or 100
		-- อิ่มขึ้น = กินแล้ว เลิกแสดงสถานะกำลังมา
		if chip.lastValue and value > chip.lastValue then calledUntil[petId] = nil end
		chip.lastValue = value
		local coming = (calledUntil[petId] or 0) > now
		chip.fill.Size = UDim2.new(math.clamp(value / 100, 0, 1), 0, 1, 0)
		chip.fill.BackgroundColor3 = hungerColor(value)
		chip.pct.Text = value <= 0 and tr("😵 หิวจนไม่ทำงาน", "😵 Too hungry") or ("🍖 " .. math.floor(value + 0.5) .. "%")
		chip.name.Text = coming and tr("🏃 กำลังวิ่งมา...", "🏃 Coming...") or chip.label
		chip.name.TextColor3 = coming and Color3.fromRGB(40, 150, 60) or Color3.fromRGB(95, 60, 45)
		chip.stroke.Color = coming and Color3.fromRGB(90, 190, 100) or Color3.fromRGB(240, 150, 170)
		chip.button.BackgroundTransparency = value >= 100 and 0.35 or 0
	end
end

refreshPicker()
