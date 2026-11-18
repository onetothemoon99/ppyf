-- BACKUP of ServerScriptService.BoosterPlacementSystem before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into ServerScriptService.BoosterPlacementSystem.Source in Studio
-- bytes=31577 sum=16101362
-- BoosterPlacementSystem: วางหุ่นเพิ่มดวงได้อิสระในโลก มีอายุจำกัด 5 นาทีแล้วหายไปเอง
-- มีอนิเมชันตอนปัก (ตกลงมาจากด้านบนแล้วเด้งเข้าที่) + เสียงตุบตอนกระทบพื้น

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local placeBooster = remoteEvents:FindFirstChild("PlaceBooster")
if not placeBooster then
	placeBooster = Instance.new("RemoteEvent")
	placeBooster.Name = "PlaceBooster"
	placeBooster.Parent = remoteEvents
end

-- แม่แบบหุ่นแต่ละระดับอยู่ใน ServerStorage > BoosterTemplates (ชื่อตาม Template ใน LuckConfig)
-- x50 = QualityBoosterTemplate (หุ่นฟางดวงดี เดิมเป็นหุ่นข้าวโพด), x100 = LuckyCloverTemplate (หุ่นโคลเวอร์สี่แฉก) จุดหมุน (pivot) ต้องอยู่ที่ฐาน
local boosterTemplates = ServerStorage:WaitForChild("BoosterTemplates")
local boosterTemplate = boosterTemplates:WaitForChild("QualityBoosterTemplate")

-- tierId ใส่มาด้วย = ใช้โมเดลสกินเทศกาลที่กำลังแสดงอยู่ (LuckConfig.BoosterSkins) ถ้ามี คืนค่าที่สองเป็นข้อมูลสกิน
local function getTierTemplate(tier, tierId)
	local skin = tierId and require(ReplicatedStorage:WaitForChild("LuckConfig")).GetActiveBoosterSkin(tierId)
	local skinTemplate = skin and boosterTemplates:FindFirstChild(skin.Template)
	if skinTemplate then return skinTemplate, skin end
	return (tier.Template and boosterTemplates:FindFirstChild(tier.Template)) or boosterTemplate
end

-- สำเนาหุ่นทุกระดับไปไว้ใน ReplicatedStorage ให้ร้านค้า/ช่องไอเทม (ItemPreview) โชว์โมเดลแทนไอคอน (ชื่อตาม PreviewName ใน LuckConfig)
local LuckConfigForPreview = require(ReplicatedStorage:WaitForChild("LuckConfig"))
do
	local previewFolder = ReplicatedStorage:FindFirstChild("ItemPreviewModels")
	if not previewFolder then
		previewFolder = Instance.new("Folder")
		previewFolder.Name = "ItemPreviewModels"
		previewFolder.Parent = ReplicatedStorage
	end
	for tierId, tier in pairs(LuckConfigForPreview.BoosterTiers) do
		if tier.PreviewName and not previewFolder:FindFirstChild(tier.PreviewName) then
			-- ช่วงเทศกาลรูปในร้าน/กระเป๋าเป็นหุ่นสกินไปด้วย (ชื่อ PreviewName เดิม ฝั่งผู้เล่นไม่ต้องแก้)
			local preview = (getTierTemplate(tier, tierId)):Clone()
			preview.Name = tier.PreviewName
			for _, obj in ipairs(preview:GetDescendants()) do
				if obj:IsA("LuaSourceContainer") then obj:Destroy() end
			end
			preview.Parent = previewFolder
		end
	end
end

local boosters = workspace:FindFirstChild("QualityBoosters")
if not boosters then
	boosters = Instance.new("Folder")
	boosters.Name = "QualityBoosters"
	boosters.Parent = workspace
end

local MAX_PLACE_DISTANCE = 20 -- ระยะสูงสุดจากตัวผู้เล่นที่วางได้ (กันวางข้ามแมพ)
-- ค่าโชค รัศมี อายุ และจำนวนที่ปักได้พร้อมกัน แยกตามระดับหุ่น (x50 / x100) อยู่ใน ReplicatedStorage.LuckConfig
-- ระดับของหุ่นอ่านจาก Attribute "BoosterTier" บน Tool (ไม่มี = x50 คือหุ่นข้าวโพดดวงดีเดิม)
local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))

-- ชื่อไอเทมตามระดับ (คีย์ใน Localization)
local TIER_NAME_KEY = {
	x50 = "Item_Booster",
	x100 = "Item_BoosterX100",
}

local function getToolTierId(tool)
	local tierId = tool:GetAttribute("BoosterTier")
	if LuckConfig.BoosterTiers[tierId] then return tierId end
	return LuckConfig.DEFAULT_BOOSTER_TIER
end

local PLACE_ANIMATION_DURATION = 0.4 -- วินาที
local PLACE_DROP_HEIGHT = 6 -- ตกลงมาจากความสูงเท่านี้ (สตัด) เหนือจุดที่วางจริง
local THUD_SOUND_ID = "rbxassetid://121998572055800"

local harvestNotify = remoteEvents:FindFirstChild("HarvestNotify")
if not harvestNotify then
	harvestNotify = Instance.new("RemoteEvent")
	harvestNotify.Name = "HarvestNotify"
	harvestNotify.Parent = remoteEvents
end

local activeBoostersByPlayer = {} -- [player.UserId] = { models... } เก็บตัวที่ยังไม่หมดอายุของผู้เล่นแต่ละคน

-- นับเฉพาะตัวที่ยังไม่หมดอายุจริงๆ ของระดับนี้ (x50 กับ x100 นับแยกกัน ปักได้อย่างละตัวพร้อมกัน)
local function countActiveBoosters(player, tierId)
	local list = activeBoostersByPlayer[player.UserId]
	if not list then return 0 end

	local count = 0
	for i = #list, 1, -1 do
		local entry = list[i]
		if not entry.model.Parent then
			table.remove(list, i) -- เคลียร์ตัวที่หมดอายุ/ถูกลบไปแล้วทิ้งจากรายการ
		elseif entry.tier == tierId then
			count += 1
		end
	end
	return count
end

-- หาเวลาที่เหลือของตัวที่ใกล้จะหมดอายุน้อยที่สุด (นับถอยหลังสั้นสุด) ไว้บอกผู้เล่น
local function getShortestRemaining(player, tierId)
	local list = activeBoostersByPlayer[player.UserId]
	if not list or #list == 0 then return 0 end

	local shortest = math.huge
	for _, entry in ipairs(list) do
		if entry.model.Parent and entry.tier == tierId then
			local remaining = entry.expireAt - os.clock()
			if remaining < shortest then
				shortest = remaining
			end
		end
	end
	return math.max(0, math.ceil(shortest))
end

-- ปักได้เฉพาะหุ่นที่ถืออยู่ในมือจริงเท่านั้น (Tool ที่ถืออยู่จะอยู่ใน Character ส่วนที่ไม่ได้ถืออยู่ใน Backpack)
-- เดิมเผื่อหาในกระเป๋าต่อด้วย ทำให้เกิดบั๊ก: ปักหุ่นฟางแล้วคำขอที่ค้างอยู่ไปหยิบหุ่นโคลเวอร์ในกระเป๋ามาปักต่อทันที
local function findBoosterTool(player)
	local character = player.Character
	if not character then return nil end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") and item:GetAttribute("IsBooster") then
			return item
		end
	end
	return nil
end

-- เล่นเสียงตุบตรงจุดที่ปักลง (แยกเป็น Part ชั่วคราวลอยอยู่ตรงนั้น เล่นเสร็จแล้วทำลายตัวเอง)
local function playThudSound(position)
	local soundPart = Instance.new("Part")
	soundPart.Name = "ThudSoundEmitter"
	soundPart.Size = Vector3.new(0.2, 0.2, 0.2)
	soundPart.Transparency = 1
	soundPart.CanCollide = false
	soundPart.CanQuery = false
	soundPart.Anchored = true
	soundPart.CFrame = CFrame.new(position)
	soundPart.Parent = workspace

	local thud = Instance.new("Sound")
	thud.SoundId = THUD_SOUND_ID
	thud.Volume = 0.8
	thud.SoundGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds") -- ปรับ/ปิดได้ตามสไลเดอร์เสียงเอฟเฟกต์
	thud.Parent = soundPart
	thud:Play()

	thud.Ended:Connect(function()
		soundPart:Destroy()
	end)
	-- เผื่อ id เสียงโหลดไม่ได้ ก็ยังต้องเคลียร์ทิ้งอยู่ดี กันพาร์ทค้าง
	game:GetService("Debris"):AddItem(soundPart, 3)
end

-- เล่นอนิเมชันตกลงมาแล้วปักเข้าที่ (ตกจากด้านบนแล้วเด้งลงตำแหน่งจริงแบบสปริง)
-- คืนค่าเป็น true ทันทีที่แอนิเมชันเล่นเสร็จแล้ว (ใช้ต่อคิวถึงจะขึ้นป้ายนับถอยหลัง/แจ้งระบบอื่นๆ ให้ตรงจังหวะ)
local function animatePlacement(model, finalCFrame)
	local startCFrame = finalCFrame * CFrame.new(0, PLACE_DROP_HEIGHT, 0)
	model:PivotTo(startCFrame)

	local startTime = os.clock()
	local finished = false

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.clamp((os.clock() - startTime) / PLACE_ANIMATION_DURATION, 0, 1)
		local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		model:PivotTo(startCFrame:Lerp(finalCFrame, easedAlpha))

		if alpha >= 1 and not finished then
			finished = true
			connection:Disconnect()
			playThudSound(finalCFrame.Position)
		end
	end)
end

-- สร้างป้ายนับถอยหลังลอยเหนือหุ่น อัปเดตทุกวินาทีจนกว่าจะหมดอายุ
-- จุดยึดป้ายอยู่ "ใน" โมเดล จึงตกลงมาพร้อมหุ่นตอนเล่นอนิเมชันตก ต้องวางเทียบกับตำแหน่งหุ่น "ตอนนี้"
-- เดิมวางที่จุดปัก (พื้น) + ครึ่งความสูง แต่ตอนนั้นหุ่นยังลอยอยู่สูง PLACE_DROP_HEIGHT พอหุ่นตกลงมา ป้ายก็ตกตาม
-- จนจมลงไปใต้ดิน ~1.4 studs (วัดจริง) แทบมองไม่เห็น ตอนนี้วางเหนือหัวของโมเดลตามตำแหน่งจริง ตกลงมาด้วยกันแล้วอยู่เหนือหัวพอดี
local function createCountdownLabel(model, lifetime)
	local boxCFrame, size = model:GetBoundingBox()
	local topPos = Vector3.new(boxCFrame.Position.X, boxCFrame.Position.Y + size.Y / 2 + 0.8, boxCFrame.Position.Z)

	local anchor = Instance.new("Part")
	anchor.Name = "CountdownAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Anchored = true
	anchor.CFrame = CFrame.new(topPos)
	anchor.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CountdownGui"
	billboard.Size = UDim2.new(0, 90, 0, 26)
	billboard.StudsOffset = Vector3.new(0, 0.3, 0)
	-- 2026-10-28 ผู้ใช้: เห็นเวลาเฉพาะในระยะการมองเห็น = ไม่ทะลุสิ่งของ + หายเมื่อห่างเกิน 60 studs (เดิม AlwaysOnTop เห็นทั้งแมพ)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = anchor

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Size = UDim2.new(1, 0, 1, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLabel.TextStrokeTransparency = 0.3
	countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	countdownLabel.TextScaled = true
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.Text = "⏳ " .. lifetime
	countdownLabel.Parent = billboard

	task.spawn(function()
		local remaining = lifetime
		while remaining > 0 and model.Parent do
			local minutes = math.floor(remaining / 60)
			local seconds = remaining % 60
			countdownLabel.Text = string.format("⏳ %d:%02d", minutes, seconds)
			task.wait(1)
			remaining -= 1
		end
	end)
end

-- ปักหุ่น 1 ตัวให้ผู้เล่นจาก Tool ที่ระบุ (ไม่เช็คเงื่อนไข คนเรียกเช็คมาแล้ว) หันหน้าหุ่นไปทาง facingPos คืนจำนวนหุ่นที่เหลือใน Tool
-- ใช้ร่วมกัน: ผู้เล่นปักเอง (PlaceBooster) และสัตว์เลี้ยง "นักปักหุ่น" ปักให้ (PetBoosterPlace ด้านล่าง)
local function spawnBooster(player, tool, tierId, tier, position, facingPos)
	local count = tool:GetAttribute("Count") or 0
	local template, skin = getTierTemplate(tier, tierId)
	local model = template:Clone()
	-- ตั้งค่าก่อนใส่ลง workspace เอฟเฟกต์ออร่า (QualityBoosterVisual) จะได้อ่านรัศมีถูกตั้งแต่แรก
	model:SetAttribute("BoostRadius", tier.Radius)
	model:SetAttribute("LuckMultiplier", tier.Luck)
	model:SetAttribute("BoosterTier", tierId)
	model:SetAttribute("OwnerUserId", player.UserId) -- ไว้บอกว่าใครปัก (ผลโชคยังใช้ร่วมกันทุกคน)
	local auraColor = (skin and skin.AuraColor) or tier.AuraColor
	if auraColor then
		model:SetAttribute("AuraColor", auraColor) -- สีออร่าตามระดับ/สกิน (QualityBoosterVisual อ่านค่านี้)
	end
	if skin and skin.SparkleRate then
		model:SetAttribute("SparkleRate", skin.SparkleRate) -- ประกายรอบตัวแบบบาง กำหนดจำนวนได้ (QualityBoosterVisual)
	end
	if skin and skin.NoBodyFx then
		model:SetAttribute("NoBodyFx", true) -- ปิดประกาย/เส้นขอบ/ดาววนรอบตัวหุ่น (QualityBoosterVisual + BoosterRainbowFx)
	end
	if skin and skin.AuraColor2 then
		model:SetAttribute("AuraColor2", skin.AuraColor2) -- หิ่งห้อยสลับสองสี (สกินเทศกาล)
	end
	if tier.Rainbow then
		model:SetAttribute("Rainbow", true) -- ออร่า/ประกายไล่สีรุ้ง + ดาวลอยวน (QualityBoosterVisual)
	end
	model.Parent = boosters

	-- หันหน้าหุ่นเข้าหาคนปัก (หน้าหุ่น = LookVector ของ pivot) เดิมหันทิศเดิมตลอด ปักแล้วบางทีเห็นแต่ด้านหลัง
	local facing = Vector3.new(facingPos.X, position.Y, facingPos.Z)
	local finalCFrame = (facing - position).Magnitude > 0.1 and CFrame.lookAt(position, facing) or CFrame.new(position)
	animatePlacement(model, finalCFrame)

	createCountdownLabel(model, tier.Lifetime)

	-- บันทึกตัวนี้ไว้ในโควต้าของผู้เล่นคนนี้
	local expireAt = os.clock() + tier.Lifetime
	activeBoostersByPlayer[player.UserId] = activeBoostersByPlayer[player.UserId] or {}
	table.insert(activeBoostersByPlayer[player.UserId], { model = model, expireAt = expireAt, tier = tierId })

	-- หมดอายุอัตโนมัติตามระดับ (x50 = 5 นาที, x100 = 15 นาที) ลบตัวเองออกจาก workspace.QualityBoosters
	-- ซึ่งจะทำให้เอฟเฟกต์ออร่าใน QualityBoosterVisual เคลียร์ตามไปด้วยอัตโนมัติ
	task.delay(tier.Lifetime, function()
		if model.Parent then
			model:Destroy()
		end
	end)

	-- หักไอเทมออกจากกระเป๋า 1 ชิ้น (เหมือนใช้เมล็ดปลูก)
	local remaining = count - 1
	if remaining <= 0 then
		tool:Destroy()
	else
		tool:SetAttribute("Count", remaining)
		tool.Name = Localization.T(TIER_NAME_KEY[tierId] or "Item_Booster", Localization.GetLanguage(player)) .. " x" .. remaining
	end
	return remaining
end

placeBooster.OnServerEvent:Connect(function(player, position)
	print("🔍 [DEBUG] BoosterPlacementSystem: ได้รับคำขอวางจาก " .. player.Name .. " ตำแหน่ง " .. tostring(position))

	if typeof(position) ~= "Vector3" then
		print("🔍 [DEBUG] หยุดเพราะ position ไม่ใช่ Vector3 (typeof=" .. typeof(position) .. ")")
		return
	end

	local tool = findBoosterTool(player)
	if not tool then
		print("🔍 [DEBUG] หยุดเพราะตอนนี้ไม่ได้ถือหุ่นอยู่ในมือ (อาจเป็นคำขอซ้ำที่ค้างมาหลังเลิกถืออัตโนมัติ)")
		return
	end

	local count = tool:GetAttribute("Count") or 0
	if count <= 0 then
		print("🔍 [DEBUG] หยุดเพราะ Count ของหุ่นเหลือ 0")
		return
	end

	local tierId = getToolTierId(tool)
	local tier = LuckConfig.GetBoosterTier(tierId)

	-- เช็คว่าปักหุ่นระดับนี้ครบโควต้าต่อผู้เล่นหรือยัง (x50 กับ x100 นับแยกกัน)
	if countActiveBoosters(player, tierId) >= tier.MaxActive then
		local lang = Localization.GetLanguage(player)
		local remaining = getShortestRemaining(player, tierId)
		local minutes = math.floor(remaining / 60)
		local seconds = remaining % 60
		harvestNotify:FireClient(player, nil, nil, nil,
			Localization.F("Booster_LimitReached", lang, tier.MaxActive, minutes, seconds))
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print("🔍 [DEBUG] หยุดเพราะหา HumanoidRootPart ไม่เจอ")
		return
	end
	local distance = (hrp.Position - position).Magnitude
	if distance > MAX_PLACE_DISTANCE then
		print("🔍 [DEBUG] หยุดเพราะระยะไกลเกิน (" .. math.floor(distance) .. " > " .. MAX_PLACE_DISTANCE .. ")")
		return
	end

	print("🔍 [DEBUG] ผ่านทุกเงื่อนไขแล้ว กำลัง spawn โมเดล...")

	local remaining = spawnBooster(player, tool, tierId, tier, position, hrp.Position)

	-- ปักเสร็จแล้วเลิกถือหุ่นทันที กันเผลอกคลิกซ้ำแล้วปักตัวถัดไป (หุ่นที่เหลือยังอยู่ในกระเป๋า หยิบใหม่ได้)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end

	print(player.Name .. " วางหุ่นเพิ่มดวงที่ " .. tostring(position) .. " (คงเหลือ " .. remaining .. " ตัว)")
end)
-- ============ สัตว์เลี้ยง "นักปักหุ่น" (PetSystem.Abilities.ScarecrowPlacer) ============
-- BindableFunction ServerStorage.PetBoosterPlace
--   Invoke(player, "query")                    -> { tierId, ... } ระดับที่ปักได้ตอนนี้ (มีหุ่นในแถบช่องลัด/ในมือ และยังไม่ครบจำนวนที่ปักพร้อมกันได้)
--   Invoke(player, "place", tierId, position)  -> true/false  ปักหุ่นระดับนั้นที่ตำแหน่งนั้น (หักหุ่น 1 ตัวเหมือนปักเอง)
-- 2026-10-14 (ผู้ใช้ขอ): สัตว์เลี้ยงหยิบได้เฉพาะหุ่นที่อยู่ในแถบช่องลัด 6 ช่อง (หรือถืออยู่ในมือ) หุ่นที่เก็บไว้ในกระเป๋าไม่ถูกแตะ
--   แถบช่องลัดกับกระเป๋าเป็น Tool ใน Backpack เหมือนกัน ต่างกันที่ผังช่องที่ฝั่งผู้เล่นส่งมา (ServerScriptService.HotbarLayout -> ServerStorage.HotbarLayoutQuery)
--   จึงเทียบ key ของหุ่นกับ key ในช่อง (สูตรเดียวกับ StarterPlayerScripts.HotbarState.ToolKey แก้ที่นั่นต้องแก้ที่นี่ด้วย) ยังไม่รู้ผังช่อง = ถือว่าไม่มีหุ่นในแถบ
local HOTBAR_KEY_ATTRIBUTES = { "IsFishingRod", "IsFish", "IsBait", "IsPetFood", "IsBooster", "IsProduce", "IsJunk", "CropType", "Star", "RodId", "BoosterTier", "FishId", "Mutation" }
local function hotbarToolKey(tool)
	local parts = {}
	for _, name in ipairs(HOTBAR_KEY_ATTRIBUTES) do
		local value = tool:GetAttribute(name)
		if value ~= nil then table.insert(parts, name .. "=" .. tostring(value)) end
	end
	return table.concat(parts, "|")
end
local function hotbarKeySet(player)
	local query = ServerStorage:FindFirstChild("HotbarLayoutQuery")
	if not query then return {} end
	local ok, slots = pcall(function() return query:Invoke(player) end)
	local set = {}
	if ok and type(slots) == "table" then
		for _, key in ipairs(slots) do
			if type(key) == "string" and key ~= "" then set[key] = true end
		end
	end
	return set
end
local function findToolOfTier(player, tierId)
	local inHotbar = hotbarKeySet(player)
	for _, location in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsBooster") and getToolTierId(item) == tierId and (item:GetAttribute("Count") or 0) > 0
					and (location == player.Character or inHotbar[hotbarToolKey(item)]) then -- ถืออยู่ หรือ อยู่ในแถบช่องลัด
					return item
				end
			end
		end
	end
	return nil
end

local petPlace = ServerStorage:FindFirstChild("PetBoosterPlace")
if not petPlace then
	petPlace = Instance.new("BindableFunction")
	petPlace.Name = "PetBoosterPlace"
	petPlace.Parent = ServerStorage
end
petPlace.OnInvoke = function(player, action, tierId, position)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return false end
	if action == "query" then
		local list = {}
		for id, tier in pairs(LuckConfig.BoosterTiers) do
			if countActiveBoosters(player, id) < tier.MaxActive and findToolOfTier(player, id) then
				table.insert(list, id)
			end
		end
		table.sort(list)
		return list
	elseif action == "place" then
		local tier = LuckConfig.BoosterTiers[tierId]
		if not tier or typeof(position) ~= "Vector3" then return false end
		if countActiveBoosters(player, tierId) >= tier.MaxActive then return false end
		local tool = findToolOfTier(player, tierId)
		if not tool then return false end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local facing = hrp and hrp.Position or (position + Vector3.new(0, 0, -1))
		spawnBooster(player, tool, tierId, tier, position, facing)
		return true
	end
	return false
end

-- คำสั่งจุดปักหุ่นของผีน้อย (2026-10-12): ผู้เล่นกดปุ่ม 👻 สั่งปักหุ่น แล้วเลือกจุดบนพื้น (StarterPlayerScripts.GhostPlaceGui)
-- RemoteEvent RemoteEvents.GhostPlaceOrder(position | nil)  nil = ยกเลิกจุดที่สั่ง
-- เก็บเป็น Attribute "GhostPlaceSpot" (Vector3) บนผู้เล่น (อยู่แค่รอบเล่นนี้ ไม่บันทึก) PetSystem.Abilities.ScarecrowPlacer อ่านค่านี้ ไม่มี = ผีน้อยไม่ปัก
local ghostPlaceOrder = remoteEvents:FindFirstChild("GhostPlaceOrder")
if not ghostPlaceOrder then
	ghostPlaceOrder = Instance.new("RemoteEvent")
	ghostPlaceOrder.Name = "GhostPlaceOrder"
	ghostPlaceOrder.Parent = remoteEvents
end
local GHOST_ORDER_MAX_DISTANCE = 60 -- สั่งจุดได้ไกลสุดจากตัวผู้เล่น
local lastGhostOrder = {}
ghostPlaceOrder.OnServerEvent:Connect(function(player, position)
	local now = os.clock()
	if now - (lastGhostOrder[player] or 0) < 0.3 then return end
	lastGhostOrder[player] = now
	if position == nil then
		player:SetAttribute("GhostPlaceSpot", nil)
		return
	end
	if typeof(position) ~= "Vector3" or position ~= position then return end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - position).Magnitude > GHOST_ORDER_MAX_DISTANCE then
		harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(Localization.GetLanguage(player), "จุดนั้นไกลเกินไป ลองเลือกจุดที่ใกล้ตัวกว่านี้", "That spot is too far. Pick one closer to you."))
		return
	end
	-- หาพื้นจริงใต้จุดที่เลือก (ข้ามของที่เดินทะลุได้) ไม่รับจุดในน้ำ
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, boosters } -- ข้ามหุ่นที่ปักอยู่ (เลือกจุดทับหุ่นเดิม = จุดอยู่ที่พื้น ไม่ใช่บนหัวหุ่น)
	params.RespectCanCollide = true
	local hit = workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -24, 0), params)
	if not hit or hit.Material == Enum.Material.Water then
		harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(Localization.GetLanguage(player), "ตรงนั้นปักหุ่นไม่ได้ ลองเลือกจุดบนพื้น", "A scarecrow can't go there. Pick a spot on the ground."))
		return
	end
	player:SetAttribute("GhostPlaceSpot", hit.Position)
end)

-- 2026-10-15 (ผู้ใช้แจ้ง: AFK แล้วผีน้อยไม่ปักหุ่น): จุดที่สั่งเดิมอยู่แค่รอบเล่นนี้ พอ AFK ครบ 19 นาทีแล้วเกมพาเข้าเซิร์ฟใหม่ (AfkRejoin)
-- หรือเซิร์ฟรีสตาร์ท จุดหาย = ผีน้อยไม่ปักอีกเลย (หุ่นเดิมก็หายตอนออก) → จำจุดไว้ใน DataStore "GhostPlaceSpot_v1" (key = UserId, {x, y, z, t})
--   เซฟ 3 วิหลังเปลี่ยนครั้งสุดท้าย (กดเลือกจุดรัว ๆ = เขียนครั้งเดียว) · กด X ยกเลิก = ลบคีย์ · เข้าเกม = ตั้งจุดเดิมคืน (ปุ่ม 👻 ขึ้นสีเขียวเอง)
local ghostSpotStore = game:GetService("DataStoreService"):GetDataStore("GhostPlaceSpot_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local ghostSpotLoaded = {}  -- [player] = true หลังอ่านค่าเดิมเสร็จ (ก่อนหน้านั้นไม่เซฟ กันทับค่าเดิมด้วย nil)
local ghostSpotSaveToken = {}
local function saveGhostSpot(player)
	if not ghostSpotLoaded[player] then return end
	local token = (ghostSpotSaveToken[player] or 0) + 1
	ghostSpotSaveToken[player] = token
	local userId = player.UserId
	local spot = player:GetAttribute("GhostPlaceSpot") -- อ่านตอนนี้ (ผู้เล่นออกไปแล้วอาจอ่านไม่ได้ จะกลายเป็นลบจุดทิ้ง)
	task.delay(3, function()
		if ghostSpotSaveToken[player] ~= token then return end -- มีการเปลี่ยนใหม่กว่า รอเซฟรอบนั้น
		local ok, err = pcall(function()
			if typeof(spot) == "Vector3" then
				ghostSpotStore:SetAsync(tostring(userId), { x = spot.X, y = spot.Y, z = spot.Z, t = os.time() }, { userId })
			else
				ghostSpotStore:RemoveAsync(tostring(userId))
			end
		end)
		if not ok then warn("BoosterPlacementSystem: เซฟจุดปักหุ่นผีน้อยไม่สำเร็จ " .. tostring(userId) .. ": " .. tostring(err)) end
	end)
end
local function loadGhostSpot(player)
	player:GetAttributeChangedSignal("GhostPlaceSpot"):Connect(function() saveGhostSpot(player) end)
	-- 2026-10-20 StandardReadGameServerThrottled (GhostPlaceSpot_v1): เดิมยิง GetAsync ทันทีตอนเข้าเกม (ไม่ผ่าน DataLoadRetry) ลอง 3 ครั้งแล้วเลิก
	--   = หลีกทางให้ของสำคัญโหลดก่อน (Defer) แล้วโหลดแบบรอโควต้า + ลองจนได้ (Load)
	if not DataLoadRetry.Defer(player, "BoosterPlacementSystem(ghostSpot)") then return end
	local ok, data = DataLoadRetry.Load(player, "BoosterPlacementSystem(ghostSpot)", DataLoadRetry.Get(ghostSpotStore, tostring(player.UserId)))
	if not ok or not player.Parent then return end -- ไม่ตั้ง loaded = ไม่เซฟทับของเดิมรอบนี้
	-- ผู้เล่นสั่งจุดใหม่ไปแล้วระหว่างอ่าน = ใช้จุดใหม่
	if player:GetAttribute("GhostPlaceSpot") == nil and type(data) == "table"
		and tonumber(data.x) and tonumber(data.y) and tonumber(data.z) then
		player:SetAttribute("GhostPlaceSpot", Vector3.new(data.x, data.y, data.z))
	end
	ghostSpotLoaded[player] = true
end
Players.PlayerAdded:Connect(function(player) task.spawn(loadGhostSpot, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadGhostSpot, player) end

Players.PlayerRemoving:Connect(function(player)
	lastGhostOrder[player] = nil
	ghostSpotLoaded[player] = nil
end)
