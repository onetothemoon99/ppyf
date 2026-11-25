-- BACKUP of ServerScriptService.PetSystem.PetManager before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into ServerScriptService.PetSystem.PetManager.Source in Studio
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PetController = require(script.Parent:WaitForChild("PetController"))
local PetDefinitions = require(script.Parent:WaitForChild("PetDefinitions"))
local PetSeedSlots = require(script.Parent:WaitForChild("PetSeedSlots"))
local PetHunger = require(script.Parent:WaitForChild("PetHunger"))
local PetOwnership = require(script.Parent:WaitForChild("PetOwnership"))
local ItemFactory = require(game:GetService("ServerScriptService"):WaitForChild("ItemFactory"))
local LuckSystem = require(game:GetService("ServerScriptService"):WaitForChild("LuckSystem"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
-- ข้อความถึงผู้เล่น ไทย/อังกฤษ + ชื่อสัตว์ตามภาษา (2026-11-23)
local function L(player, th, en)
	return Localization.Pick(player and Localization.GetLanguage(player) or "th", th, en)
end
local function petNameFor(player, def)
	if not def then return "?" end
	return L(player, def.DisplayName, def.DisplayNameEn or def.DisplayName)
end
local Abilities = script.Parent:WaitForChild("Abilities")
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))

-- พาออกมาได้เฉพาะตัวที่ผู้เล่นเป็นเจ้าของ (PetOwnership) ตัวเริ่มต้นทุกคนมีเสมอ
local DEFAULT_PET_ID = PetOwnership.STARTER_PET_ID
-- จำนวนที่พาออกมาพร้อมกันได้: ปกติ 2 ตัว ซื้อ Game Pass "ช่องสัตว์ +1" ได้ 3 ตัว (Attribute "PetSlots" บนตัวผู้เล่น)
local PetSlotConfig = require(ReplicatedStorage:WaitForChild("PetSlotConfig"))
local MarketplaceService = game:GetService("MarketplaceService")
local PetSlotGift = require(game:GetService("ServerScriptService"):WaitForChild("PetSlotGift")) -- ของขวัญช่องสัตว์ +1
local checkPetSlots -- นิยามด้านล่าง (ส่วน Game Pass)
local function maxActivePets(player)
	return player:GetAttribute("PetSlots") or PetSlotConfig.BASE_SLOTS
end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- สำเนาโมเดลสัตว์เลี้ยงไปไว้ใน ReplicatedStorage ให้เมนูสัตว์เลี้ยง (PetHelperToggleButton) โชว์โมเดลได้
-- ต้นฉบับยังอยู่ใน ServerStorage ที่เดิม แก้/เพิ่มโมเดลที่นั่นที่เดียว เมนูจะตามเอง
do
	local previewFolder = Instance.new("Folder")
	previewFolder.Name = "PetPreviewModels"
	for petId, def in pairs(PetDefinitions) do
		local folderName = def.TemplateFolder or "PetTemplates"
		local templateFolder = game:GetService("ServerStorage"):FindFirstChild(folderName)
		local template = templateFolder and templateFolder:FindFirstChild(petId)
		if template then
			local preview = template:Clone()
			for _, obj in ipairs(preview:GetDescendants()) do
				if obj:IsA("LuaSourceContainer") then obj:Destroy() end
			end
			-- หน้าต่างต่างๆ (เมนูสัตว์เลี้ยง/ตู้สุ่ม/แผงสัตว์ที่ใช้) ตั้งกล้องโดยถือว่าสัตว์หันหน้าแบบมาตรฐาน (FacingOffset 180 องศา)
			-- ตัวที่โมเดลหันอีกทาง (เช่น ผีน้อยนักปักหุ่น FacingOffset 0) จะเห็นแต่หลัง จึงหมุนชิ้นส่วนในสำเนาโชว์ให้ตรงมาตรฐาน (จุดหมุนของโมเดลคงเดิม ต้นฉบับไม่เปลี่ยน)
			local standardFacing = CFrame.Angles(0, math.rad(180), 0)
			local fix = standardFacing * (def.FacingOffset or standardFacing):Inverse()
			if not fix:FuzzyEq(CFrame.identity, 0.001) then
				local pivot = preview:GetPivot()
				for _, part in ipairs(preview:GetDescendants()) do
					if part:IsA("BasePart") and part ~= preview.PrimaryPart then
						part.CFrame = pivot * fix * pivot:ToObjectSpace(part.CFrame)
					end
				end
			end
			preview.Parent = previewFolder
		end
	end
	previewFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
	local remote = remoteEvents:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteEvents
	end
	return remote
end

local petAbilityToggle = getOrCreateRemote("PetAbilityToggle")
local petAbilitiesInfo = getOrCreateRemote("PetAbilitiesInfo")
local petListInfo = getOrCreateRemote("PetListInfo")
local petSelect = getOrCreateRemote("PetSelect")
local petSeedSlotsRemote = getOrCreateRemote("PetSeedSlots")
local petFeed = getOrCreateRemote("PetFeed")
-- แจ้งสถานะเปิด/ปิดความสามารถ: ส่งให้เมนู (PetAbilityToggle) + ตั้ง Attribute "AbilityOn_<id>" บนตัวผู้เล่น
-- (แผงสัตว์ที่ใช้อยู่ ActivePetsHud อ่าน Attribute ไปแสดงปุ่มเปิด/ปิดบนการ์ด)
local function setAbilityState(player, abilityId, isOn)
	player:SetAttribute("AbilityOn_" .. abilityId, isOn == true)
	petAbilityToggle:FireClient(player, abilityId, isOn)
end
local harvestNotify = getOrCreateRemote("HarvestNotify") -- ใช้แจ้งข้อความลอยบนจอ (ตัวเดียวกับ PlantingSystem)

-- ฝั่งผู้เล่นรายงานว่าช่อง 1-2 บนแถบ 9 ช่องมีเมล็ดอะไร (ตรวจความถูกต้องทุกครั้งที่ใช้ใน PetSeedSlots)
petSeedSlotsRemote.OnServerEvent:Connect(function(player, tool1, tool2)
	PetSeedSlots.Set(player, tool1, tool2)
end)

local activePets = {} -- [player] = { [petId] = petInstance }
local activePetIds = {} -- [player] = { [petId] = true }

-- ความสามารถที่บังคับเปิดตลอด (2026-10-03 ผู้เล่นขอ: "นำโชค" ปิดไม่ได้ คนที่ปิดไว้ให้เปิดใหม่): กดปิดไม่ได้ + ค่าที่เซฟไว้เป็นปิดก็ถูกแก้เป็นเปิดเมื่อใช้งาน
-- เพิ่มความสามารถอื่นที่บังคับเปิดได้ที่ตารางนี้
local ALWAYS_ON_ABILITIES = { Lucky = true }
local function forceAlwaysOn(player)
	local changed = {}
	for _, petInstance in pairs(activePets[player] or {}) do
		for _, abilityModule in ipairs(petInstance.abilities) do
			local id = abilityModule.Id
			if ALWAYS_ON_ABILITIES[id] then
				petInstance.enabledAbilities[id] = true
				changed[id] = true
			end
		end
	end
	for id in pairs(changed) do
		if player:GetAttribute("AbilityOn_" .. id) ~= true then setAbilityState(player, id, true) end
	end
end

-- ค่าโชคจากสัตว์เลี้ยงที่พาออกมาและเปิด "นำโชค" อยู่ = Luck ของแต่ละตัว x ความอิ่ม (บวกกันทุกตัว)
-- PlantingSystem ถามผ่าน LuckSystem.GetLuck ตอนปลูก
LuckSystem.SetPetLuckProvider(function(player)
	local total = 0
	for petId, petInstance in pairs(activePets[player] or {}) do
		local def = petInstance.definition
		if petInstance.enabledAbilities["Lucky"] and def and def.Luck then
			total += def.Luck * PetHunger.GetEfficiency(player, petId)
		end
	end
	return total
end)

-- สัตว์ช่วยตกปลา (นาก): ตัวที่พาออกมา + เปิด "ช่วยตกปลา" + ยังไม่หิวจนหมดแรง (FishingSystem ให้มันถือเบ็ดตกปลาช่วย)
-- ความเร็ว = เลเวล (ความเร็วทำงาน) x ความอิ่ม, จับได้ทีไรหิวขึ้นเท่าทำงาน 1 ครั้ง
local FishingPetBonus = require(game:GetService("ServerScriptService"):WaitForChild("FishingPetBonus"))
FishingPetBonus.SetProvider(function(player)
	local best
	for petId, petInstance in pairs(activePets[player] or {}) do
		local def = petInstance.definition
		if petInstance.enabledAbilities["Fisher"] and def and petInstance.model and petInstance.model.Parent
			and not (petInstance.IsCalled and petInstance.IsCalled()) then -- ถูกเรียกไปกินอาหาร = เลิกตกปลาชั่วคราว (FishingSystem เก็บคัน/ทุ่น)
			local eff = PetHunger.GetEfficiency(player, petId)
			if eff > 0 then
				local speed = PetHunger.GetSpeed(player, petId) * math.max(0.3, eff)
				if not best or speed > best.speed then
					best = {
						petId = petId, name = def.DisplayName, model = petInstance.model, speed = speed,
						onHelp = function(mult) -- (ค่าความหิวเซฟพร้อมรอบหิวตามเวลา) mult = ตัวคูณความหิวจากเบ็ดนาก (หอยน้อย 0.8)
							PetHunger.Consume(player, petId, PetHunger.JOB_COST * (tonumber(mult) or 1))
						end,
					}
				end
			end
		end
	end
	return best
end)

-- เซฟการตั้งค่าสัตว์เลี้ยงถาวร (ตัวไหนเปิดอยู่ + ความสามารถไหนเปิดไว้) เหมือนระบบเงิน/กระเป๋า
local petSettingsStore = DataStoreService:GetDataStore("PetSettings_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local lastSavedJson = {} -- [player] = JSON ที่เซฟล่าสุด (optimize 2026-10-10: ค่าเท่าเดิมไม่เขียนซ้ำ)
local savePending = {}   -- [player] = true ถ้ามีคิวเซฟค้างอยู่
local initialised = {}   -- [player] = true เมื่อกู้ค่าที่เซฟไว้เสร็จแล้ว
-- กันข้อมูลสัตว์ที่เซฟไว้โดนเขียนทับตอนรีเซิร์ฟเวอร์ (2026-10-02 ผู้เล่นเจอ "กลับไปใช้แต่กระต่าย"):
--   settingsLoadFailed = โหลดข้อมูลที่เซฟไว้ไม่สำเร็จ (DataStore ล่ม/โดนจำกัดตอนคนเข้าพร้อมกัน) ห้ามเซฟทับจนกว่าจะโหลดได้ (มีตัวลองใหม่เป็นระยะ)
--   finalSaved = เซฟรอบสุดท้ายตอนออกเกมแล้ว (สัตว์ถูกลบออกจากความจำแล้ว) BindToClose ห้ามเซฟซ้ำ ไม่งั้นได้รายการสัตว์ว่างทับของดี
local settingsLoadFailed = {} -- [player] = true
local finalSaved = setmetatable({}, { __mode = "k" })
local LOAD_RETRY_SECONDS = 20

local function getAbilityDisplayName(abilityId)
	local moduleScript = Abilities:FindFirstChild(abilityId)
	if not moduleScript then return abilityId end
	local ok, abilityModule = pcall(require, moduleScript)
	if ok and abilityModule.DisplayName then
		return abilityModule.DisplayName
	end
	return abilityId
end

-- สร้างรายชื่อสัตว์เลี้ยงทั้งหมด พร้อมความสามารถของแต่ละตัว (ส่งให้ client แสดงในเมนู)
-- Owned = ผู้เล่นคนนี้มีตัวนี้ไหม (ตัวที่ยังไม่มี เมนูแสดงเป็นเงา "???" เลือกไม่ได้)
local function buildPetList(player)
	local list = {}
	for petId, def in pairs(PetDefinitions) do
		-- สัตว์ลึกลับ (HiddenUnlessOwned): คนที่ยังไม่มีไม่รู้ว่ามีตัวนี้ (ไม่ส่งไปเลย)
		if def.HiddenUnlessOwned and player and not PetOwnership.Owns(player, petId) then continue end
		local abilities = {}
		for _, abilityId in ipairs(def.Abilities or {}) do
			local name = getAbilityDisplayName(abilityId)
			-- บอกโบนัสพิเศษในเมนู เช่น "ช่วยเก็บเกี่ยว (ผลผลิต x2)"
			if abilityId == "Harvester" and (def.HarvestMultiplier or 1) > 1 then
				name = name .. L(player, " (ผลผลิต x", " (yield x") .. def.HarvestMultiplier .. ")"
			end
			table.insert(abilities, { Id = abilityId, DisplayName = name })
		end
		table.insert(list, { Id = petId, DisplayName = def.DisplayName, Rarity = def.Rarity or "Common", Description = def.Description, DescriptionEn = def.DescriptionEn, UnlockHint = def.UnlockHint, Abilities = abilities, Luck = def.Luck,
			Owned = player == nil or PetOwnership.Owns(player, petId) })
	end
	return list
end

local function sendAbilitiesInfo(player)
	forceAlwaysOn(player)
	-- รวมความสามารถจากสัตว์เลี้ยงทุกตัวที่ใช้งานอยู่
	local list = {}
	local seen = {}
	local playerPets = activePets[player]
	if playerPets then
		for _, petInstance in pairs(playerPets) do
			for _, abilityModule in ipairs(petInstance.abilities) do
				if not seen[abilityModule.Id] then
					seen[abilityModule.Id] = {}
					table.insert(list, { Id = abilityModule.Id, DisplayName = abilityModule.DisplayName })
				end
				-- หมายเหตุโบนัสพิเศษของตัวที่พาออกมา ใต้ปุ่มความสามารถ (เช่น จิ้งจอกเก้าหางเก็บได้ผลผลิต x2)
				local def = petInstance.definition
				if abilityModule.Id == "Harvester" and def and (def.HarvestMultiplier or 1) > 1 then
					table.insert(seen[abilityModule.Id], L(player, "✨ " .. def.DisplayName .. " เก็บเกี่ยวได้ผลผลิต x" .. def.HarvestMultiplier, "✨ " .. petNameFor(player, def) .. " harvests yield x" .. def.HarvestMultiplier))
				end
				if abilityModule.Id == "Lucky" and def and def.Luck then
					table.insert(seen[abilityModule.Id],
						Localization.F("Pet_LuckyNote", Localization.GetLanguage(player), petNameFor(player, def), def.Luck))
				end
			end
		end
		for _, ability in ipairs(list) do
			if #seen[ability.Id] > 0 then ability.Note = table.concat(seen[ability.Id], "\n") end
		end
	end
	petAbilitiesInfo:FireClient(player, list)

	-- เมนูสร้างปุ่มใหม่เป็น "ปิด" ทุกครั้ง ส่งสถานะจริงตามไปด้วย ไม่งั้นปุ่มขึ้น "ปิด" ทั้งที่ยังทำงานอยู่
	for _, ability in ipairs(list) do
		local on = false
		for _, petInstance in pairs(playerPets or {}) do
			if petInstance.enabledAbilities[ability.Id] then on = true break end
		end
		setAbilityState(player, ability.Id, on) -- ส่งทั้งเปิดและปิด ให้ปุ่มตรงกับที่สัตว์ทำงานจริงเสมอ
	end
end

local function removePet(player, petId)
	local playerPets = activePets[player]
	if playerPets and playerPets[petId] then
		playerPets[petId].destroy()
		playerPets[petId] = nil
	end
	if activePetIds[player] then
		activePetIds[player][petId] = nil
	end
end

local function removeAllPets(player)
	local playerPets = activePets[player]
	if playerPets then
		for petId, petInstance in pairs(playerPets) do
			petInstance.destroy()
		end
	end
	activePets[player] = nil
	activePetIds[player] = nil
end

-- นับเฉพาะตัวที่ใช้ช่อง (def.FreeSlot เช่น ซุกซน 2026-10-22 = พาออกมาได้โดยไม่กินช่องสัตว์)
local function getActiveCount(player)
	local count = 0
	if activePetIds[player] then
		for petId in pairs(activePetIds[player]) do
			local def = PetDefinitions[petId]
			if not (def and def.FreeSlot) then count = count + 1 end
		end
	end
	return count
end

-- ทุกตัวที่พาออกมา รวมตัวที่ไม่ใช้ช่อง (ใช้เช็ก "ไม่มีสัตว์สักตัว")
local function getTotalActive(player)
	local n = 0
	for _ in pairs(activePetIds[player] or {}) do n += 1 end
	return n
end

local function getActiveList(player)
	local list = {}
	if activePetIds[player] then
		for petId in pairs(activePetIds[player]) do
			table.insert(list, petId)
		end
	end
	return list
end

-- แปลงสถานะปัจจุบันเป็นข้อมูลเปล่าๆ พร้อมเซฟ
local function serializeSettings(player)
	local pets, abilities = {}, {}
	local playerPets = activePets[player]
	if playerPets then
		for petId, petInstance in pairs(playerPets) do
			table.insert(pets, { id = petId, slot = petInstance.slot or 1 })
			local enabled = {}
			for abilityId, isOn in pairs(petInstance.enabledAbilities or {}) do
				if isOn then enabled[abilityId] = true end
			end
			abilities[petId] = enabled
		end
	end
	local allPetIds = {}
	for petId in pairs(PetDefinitions) do table.insert(allPetIds, petId) end
	return { pets = pets, abilities = abilities, hunger = PetHunger.Serialize(player, allPetIds), lives = PetHunger.SerializeLives(player, allPetIds) }
end

-- 2026-11-18 เตือน "DataStore request was added to queue": เซฟตามนัด (5 วิ) แล้วออกเกมทันที = เขียนคีย์เดิมห่างไม่ถึง 6 วิ
-- เตรียมข้อมูลก่อน (ตอนออกต้องเก็บก่อน removeAllPets) แล้วรอเซฟครั้งก่อนหน้า + เว้น SETTINGS_WRITE_GAP วิ ค่อยเขียน (ตัวที่เขียนทีหลัง = ข้อมูลใหม่กว่า)
local SETTINGS_WRITE_GAP = 7
local lastSettingsWrite = {} -- [userId] = os.clock()
local settingsWriting = {} -- [userId] = true ระหว่างเขียน
local function saveSettings(player)
	if settingsLoadFailed[player] or finalSaved[player] then return end
	local ok, data = pcall(serializeSettings, player)
	if not ok then
		warn("PetManager: เตรียมข้อมูลเซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(data))
		return
	end
	local okJson, json = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
	if okJson and json == lastSavedJson[player] then return end -- ไม่มีอะไรเปลี่ยน ไม่ใช้คิว DataStore
	local userId = player.UserId
	local deadline = os.clock() + 20
	while settingsWriting[userId] and os.clock() < deadline do task.wait(0.1) end
	settingsWriting[userId] = true
	local gap = SETTINGS_WRITE_GAP - (os.clock() - (lastSettingsWrite[userId] or -math.huge))
	if gap > 0 then task.wait(gap) end
	lastSettingsWrite[userId] = os.clock()
	local saveOk, err = pcall(function()
		petSettingsStore:SetAsync(tostring(userId), data)
	end)
	settingsWriting[userId] = nil
	if saveOk then
		if okJson then lastSavedJson[player] = json end
	else
		warn("PetManager: เซฟการตั้งค่าไม่สำเร็จสำหรับ " .. player.Name .. " (PetSettings_v1 key " .. userId .. "): " .. tostring(err))
	end
end

-- รวบการเปลี่ยนแปลงหลายครั้งติดกันให้เซฟรอบเดียว (กดเปิดปิดรัวๆ จะไม่ยิง DataStore ทุกครั้ง)
local function scheduleSave(player)
	if savePending[player] then return end
	savePending[player] = true
	task.delay(5, function()
		savePending[player] = nil
		if player.Parent then saveSettings(player) end
	end)
end

local function spawnPetFor(player, petId)
	petId = petId or DEFAULT_PET_ID

	-- ถ้าสัตว์เลี้ยงตัวนี้กำลังใช้งานอยู่ → ปิด (เอาออก)
	if activePetIds[player] and activePetIds[player][petId] then
		removePet(player, petId)
		sendAbilitiesInfo(player)
		petListInfo:FireClient(player, buildPetList(player), getActiveList(player))
		return
	end

	-- พาออกมาได้เฉพาะตัวที่เป็นเจ้าของ (เช็คที่เซิร์ฟเวอร์ กันยิง remote ตรงๆ)
	if not PetOwnership.Owns(player, petId) then
		return
	end

	-- ถ้าครบจำนวนสูงสุดแล้ว → เอาตัวแรกออกก่อน
	-- ครบจำนวนแล้ว -> เอาตัวที่พาออกมานานที่สุดออก (เดิมหยิบตัวไหนก็ได้)
	local isFree = PetDefinitions[petId] and PetDefinitions[petId].FreeSlot
	while not isFree and getActiveCount(player) >= maxActivePets(player) do
		local oldestId, oldestAt
		for id, inst in pairs(activePets[player] or {}) do
			local d = PetDefinitions[id]
			if not (d and d.FreeSlot) and (not oldestAt or (inst.spawnedAt or 0) < oldestAt) then oldestId, oldestAt = id, inst.spawnedAt or 0 end
		end
		if not oldestId then break end
		removePet(player, oldestId)
		-- ยังไม่มีช่องที่ 3: บอกครั้งเดียวว่าซื้อเพิ่มได้
		if maxActivePets(player) < PetSlotConfig.BASE_SLOTS + PetSlotConfig.BONUS_SLOTS and not player:GetAttribute("PetSlotHintShown") then
			player:SetAttribute("PetSlotHintShown", true)
			harvestNotify:FireClient(player, nil, nil, nil, L(player, "🐾 พาออกมาได้ 2 ตัว · ซื้อ \"ช่องสัตว์ +1\" ในเมนู 🐾 เพื่อพาออกมา 3 ตัวพร้อมกัน", "🐾 You can bring out 2 pets · Buy \"Pet Slot +1\" in the 🐾 menu to bring out 3 at once"))
		end
	end

	-- หา slot ว่าง (1 หรือ 2)
	local usedSlots = {}
	for _, petInst in pairs(activePets[player] or {}) do usedSlots[petInst.slot or 1] = true end
	local slot = 1
	while usedSlots[slot] do slot += 1 end
	if isFree then slot = PetController.FREE_SLOT end -- ตัวไม่ใช้ช่อง: ที่ยืนของตัวเอง ไม่ทับตัวอื่น

	local petInstance = PetController.Spawn(player, petId, slot)
	if petInstance then
		petInstance.spawnedAt = os.clock()
		-- ความสามารถที่เปิดอยู่แล้วกับอีกตัว ให้ตัวใหม่เปิดตาม (ปุ่มเดียวคุมทุกตัว)
		-- ไม่มีตัวอื่นที่มีความสามารถนี้ -> ใช้สถานะล่าสุดที่ผู้เล่นตั้งไว้ (Attribute "AbilityOn_<id>")
		-- เดิมไม่เช็คตรงนี้: เอาสัตว์ออกหมดแล้วพากลับมา ปุ่มยังขึ้น "เปิด" แต่ตัวใหม่ไม่ทำงาน
		for _, abilityModule in ipairs(petInstance.abilities) do
			local id = abilityModule.Id
			local hasHolder, holderOn = false, false
			for _, other in pairs(activePets[player] or {}) do
				for _, m in ipairs(other.abilities) do
					if m.Id == id then
						hasHolder = true
						if other.enabledAbilities[id] then holderOn = true end
						break
					end
				end
			end
			-- 2026-10-03 ผู้เล่นขอ: ตอนใช้ (พาสัตว์ออกมา/เข้าเกม) เปิดความสามารถให้ใช้ได้ทันที ถึงแม้เคยปิดไว้ (ปุ่มคนละความสามารถคุมทุกตัว จึงเปิดให้ทุกตัวที่มีความสามารถนั้นด้วย)
			-- (กดปิดเองเมื่อไรก็ได้หลังจากนั้น ยกเว้น "นำโชค" ที่บังคับเปิดตลอด ดู forceAlwaysOn)
			petInstance.enabledAbilities[id] = true
			for _, other in pairs(activePets[player] or {}) do
				for _, m in ipairs(other.abilities) do
					if m.Id == id then other.enabledAbilities[id] = true break end
				end
			end
		end
		activePets[player] = activePets[player] or {}
		activePets[player][petId] = petInstance
		activePetIds[player] = activePetIds[player] or {}
		activePetIds[player][petId] = true
		sendAbilitiesInfo(player)
		petListInfo:FireClient(player, buildPetList(player), getActiveList(player))
	end
end

-- ผู้เล่นเลือกไม่พาสัตว์ออกมาเลย (2026-11-17 ผู้ใช้แจ้ง: ปิดหมดแล้วเข้าเกมใหม่/เกิดใหม่ กระต่ายโผล่มาเอง)
--   true = อย่าเรียกตัวเริ่มต้นให้ตอนเกิดใหม่ · ตั้งตอนกดปิดตัวสุดท้าย หรือโหลดเจอรายการที่เซฟไว้เป็นค่าว่าง · พาสัตว์ออกมา = ล้าง
local choseNone = setmetatable({}, { __mode = "k" }) -- [player] = true

-- ผู้เล่นเลือกเปิด/ปิดสัตว์เลี้ยงจากเมนู (toggle)
petSelect.OnServerEvent:Connect(function(player, petId)
	if type(petId) ~= "string" or not PetDefinitions[petId] then return end
	if not PetOwnership.Owns(player, petId) then
		harvestNotify:FireClient(player, nil, nil, nil, L(player, "🔒 ยังไม่มีสัตว์เลี้ยงตัวนี้", "🔒 You don't have this pet yet"))
		return
	end
	spawnPetFor(player, petId)
	choseNone[player] = (getTotalActive(player) == 0) or nil
	scheduleSave(player)
end)

-- เปิด/ปิดความสามารถของสัตว์เลี้ยงตัวที่ใช้งานอยู่
petAbilityToggle.OnServerEvent:Connect(function(player, abilityId)
	local playerPets = activePets[player]
	if not playerPets then return end
	if ALWAYS_ON_ABILITIES[abilityId] then
		forceAlwaysOn(player) -- ปิดไม่ได้: บอกปุ่มให้กลับเป็นเปิดให้ตรงกับจริง
		petAbilityToggle:FireClient(player, abilityId, true)
		return
	end

	-- ปุ่มเดียวคุมสัตว์ทุกตัวที่มีความสามารถนี้ (เมนูมีปุ่มเดียวต่อความสามารถ)
	-- เดิมสลับเฉพาะ "ตัวแรกที่เจอ" พา 2 ตัวที่เก็บเกี่ยวได้ทั้งคู่ (เช่น จิ้งจอก + จิ้งจอกเก้าหาง) อีกตัวจะเปิดไม่ได้เลย
	local holders = {}
	for _, petInstance in pairs(playerPets) do
		for _, abilityModule in ipairs(petInstance.abilities) do
			if abilityModule.Id == abilityId then
				table.insert(holders, petInstance)
				break
			end
		end
	end
	if #holders == 0 then return end

	-- มีตัวไหนเปิดอยู่ = ปุ่มแสดง "เปิด" กดแล้วปิดทุกตัว / ไม่มีตัวไหนเปิด = กดแล้วเปิดทุกตัว
	local anyOn = false
	for _, petInstance in ipairs(holders) do
		if petInstance.enabledAbilities[abilityId] then anyOn = true break end
	end
	local newState = not anyOn
	for _, petInstance in ipairs(holders) do
		petInstance.enabledAbilities[abilityId] = newState
	end
	setAbilityState(player, abilityId, newState)
	scheduleSave(player)
end)

-- spawnPetFor เป็นปุ่ม "เปิด/ปิด" ของเมนู ถ้าเรียกตอนที่สัตว์เลี้ยงอยู่แล้วมันจะ "ปิด" (เอาออก)
-- เดิมโค้ดเรียกตัวนี้ทุกครั้งที่ตัวละครเกิดใหม่ พอผู้เล่นตายแล้วเกิด สัตว์เลี้ยงจึงหายไปเลย
-- ตรงนี้จึงใช้ ensurePet ที่ "สปอว์นเฉพาะตอนยังไม่มี" แทน
local function ensurePet(player, petId)
	petId = petId or DEFAULT_PET_ID
	if activePetIds[player] and activePetIds[player][petId] then return end
	spawnPetFor(player, petId)
end

-- ย้ายสัตว์เลี้ยงมาอยู่ข้างตัวละครใหม่ กันไม่ให้ต้องเดินข้ามแมพกลับมาหาเจ้าของ
local function gatherPets(player)
	local playerPets = activePets[player]
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not playerPets or not hrp then return end
	for _, petInstance in pairs(playerPets) do
		local model = petInstance.model
		if model and model.Parent then
			local side = PetController.SlotSide(hrp.CFrame, petInstance.slot)
			local def = petInstance.definition
			local dist = (def and def.FollowDistance) or 3
			model:PivotTo(CFrame.new(hrp.Position + side * dist) * (model:GetPivot() - model:GetPivot().Position))
		end
	end
end

-- กู้สัตว์เลี้ยงและความสามารถที่ผู้เล่นเคยตั้งไว้ คืนค่า true ถ้ามีข้อมูลเก่าให้กู้
local function applySavedSettings(player)
	-- ลองโหลดซ้ำหลายครั้งก่อนยอมแพ้ (ตอนรีเซิร์ฟเวอร์คนเข้าพร้อมกัน DataStore มักโดนจำกัดชั่วคราว)
	-- ทดสอบใน Studio: ตั้ง Attribute "DevFailPetLoad" = จำนวนครั้งที่ให้ GetAsync ล้มเหลว บน workspace (ลดลงเองทีละครั้ง)
	local ok, data
	DataLoadRetry.WaitLeaveSaves(player) -- หลุดแล้วเข้าเซิร์ฟเดิมทันที = รอเซฟรอบก่อนเสร็จก่อนอ่าน (2026-10-10)
	for attempt = 1, 4 do
		local forced = game:GetService("RunService"):IsStudio() and (tonumber(workspace:GetAttribute("DevFailPetLoad")) or 0) or 0
		if forced > 0 then
			workspace:SetAttribute("DevFailPetLoad", forced - 1)
			ok, data = false, "จำลองโหลดไม่สำเร็จ (DevFailPetLoad)"
		else
			DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
			ok, data = pcall(function()
				return petSettingsStore:GetAsync(tostring(player.UserId))
			end)
		end
		if ok then break end
		warn("PetManager: โหลดการตั้งค่าไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(data))
		if attempt < 4 and player.Parent then task.wait(2 * attempt) end
	end
	settingsLoadFailed[player] = (not ok) or nil
	-- โหลดความเป็นเจ้าของก่อน (ครั้งแรกจะย้ายจากข้อมูลเดิมนี้: เคยใช้ตัวไหนได้ตัวนั้น)
	PetOwnership.Load(player, ok and data or nil, ok)
	if not ok then
		warn("PetManager: โหลดการตั้งค่าไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(data) .. " (ใช้ตัวเริ่มต้นไปก่อน ไม่เซฟทับ จะลองโหลดใหม่ทุก " .. LOAD_RETRY_SECONDS .. " วิ)")
		return false
	end
	-- กู้ความหิวก่อนเสมอ (ต่อให้ปิดสัตว์เลี้ยงไว้หมด ความหิวก็ต้องคงเดิม ไม่รีเซ็ตเป็นอิ่มเต็ม)
	if type(data) == "table" and type(data.hunger) == "table" then
		for petId, value in pairs(data.hunger) do
			if PetDefinitions[petId] and type(value) == "number" then
				PetHunger.Set(player, petId, value)
			end
		end
	end
	-- ชีวิตที่เหลือของแมวเก้าชีวิต (ไม่มีข้อมูล = ครบทุกชีวิต)
	if type(data) == "table" and type(data.lives) == "table" then
		for petId, value in pairs(data.lives) do
			if PetDefinitions[petId] and type(value) == "number" then
				PetHunger.SetLives(player, petId, value)
			end
		end
	end
	if type(data) ~= "table" or type(data.pets) ~= "table" then
		return false -- ผู้เล่นใหม่ (ยังไม่มีข้อมูลเซฟ) = ได้ตัวเริ่มต้น
	end
	if #data.pets == 0 then
		-- 2026-11-17: เคยปิดสัตว์เลี้ยงไว้หมด = เคารพที่เลือก ไม่เรียกกระต่าย (เดิมคืน false เหมือนผู้เล่นใหม่ กระต่ายเลยโผล่ทุกครั้งที่เข้าเกม)
		choseNone[player] = true
		return "none"
	end

	for _, entry in ipairs(data.pets) do
		if type(entry) == "table" and type(entry.id) == "string" and PetDefinitions[entry.id] then
			ensurePet(player, entry.id)
		end
	end

	-- เปิดความสามารถตามที่เคยตั้งไว้ แล้วบอก UI ให้แสดงสถานะตรงกัน
	local savedAbilities = (type(data.abilities) == "table") and data.abilities or {}
	for petId, petInstance in pairs(activePets[player] or {}) do
		local enabled = savedAbilities[petId]
		if type(enabled) == "table" then
			for _, abilityModule in ipairs(petInstance.abilities) do
				if enabled[abilityModule.Id] then
					petInstance.enabledAbilities[abilityModule.Id] = true
					setAbilityState(player, abilityModule.Id, true)
				end
			end
		end
	end
	-- ข้อมูลเก่าอาจเปิดไว้ตัวเดียว (สมัยปุ่มสลับทีละตัว) ให้ทุกตัวที่มีความสามารถเดียวกันเปิดตาม
	local onAbilities = {}
	for _, petInstance in pairs(activePets[player] or {}) do
		for abilityId, isOn in pairs(petInstance.enabledAbilities) do
			if isOn then onAbilities[abilityId] = true end
		end
	end
	for _, petInstance in pairs(activePets[player] or {}) do
		for _, abilityModule in ipairs(petInstance.abilities) do
			if onAbilities[abilityModule.Id] then petInstance.enabledAbilities[abilityModule.Id] = true end
		end
	end
	-- ตัวที่เคยพาออกมาไม่ได้เป็นเจ้าของแล้ว (สปอว์นไม่ได้สักตัว) ให้ไปใช้ตัวเริ่มต้นแทน
	return getTotalActive(player) > 0
end

-- ============ Game Pass "ช่องสัตว์ +1" ============
checkPetSlots = function(player)
	local owns = false
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PetSlotConfig.GAMEPASS_ID)
		end)
		if ok then owns = result break end
		warn("PetManager: เช็ก Game Pass ช่องสัตว์ไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(result))
		task.wait(2)
	end
	-- ทดสอบใน Studio: ตั้ง Attribute "DevGrantPetSlot" = true บนตัวผู้เล่น (จากเซิร์ฟเวอร์)
	if game:GetService("RunService"):IsStudio() and player:GetAttribute("DevGrantPetSlot") then owns = true end
	if not owns and PetSlotGift.HasGift(player) then owns = true end -- ได้ช่องสัตว์ +1 เป็นของขวัญจากเพื่อน
	player:SetAttribute("PetSlots", PetSlotConfig.BASE_SLOTS + (owns and PetSlotConfig.BONUS_SLOTS or 0))
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if passId ~= PetSlotConfig.GAMEPASS_ID or not purchased then return end
	player:SetAttribute("PetSlots", PetSlotConfig.BASE_SLOTS + PetSlotConfig.BONUS_SLOTS)
	harvestNotify:FireClient(player, nil, nil, nil, L(player, "🐾 ขอบคุณที่ซื้อช่องสัตว์ +1! ตอนนี้พาสัตว์ออกมาได้ 3 ตัวพร้อมกันแล้ว", "🐾 Thanks for buying Pet Slot +1! You can now bring out 3 pets at once"))
	print("🐾 PetSlots: " .. player.Name .. " ซื้อ Game Pass ช่องสัตว์ +1")
end)

local setupDone = {} -- [player] = true กัน setupPlayer ซ้ำ (PlayerAdded + วนผู้เล่นที่มีอยู่แล้ว ทำงานทั้งคู่ตอนเซิร์ฟเวอร์เริ่มช้า)
local function setupPlayer(player)
	if setupDone[player] then return end
	setupDone[player] = true
	player.CharacterAdded:Connect(function()
		task.wait(2)
		-- ยังกู้ค่าที่เซฟไว้ไม่เสร็จ ปล่อยให้ตัวกู้ค่าจัดการ ไม่งั้นจะแย่งกันสปอว์นตัวเริ่มต้นทับของที่เซฟไว้
		if not initialised[player] then return end
		if getTotalActive(player) == 0 then
			-- ไม่มีสักตัว ให้ตัวเริ่มต้นกลับมา เว้นผู้เล่นตั้งใจปิดหมดเอง (choseNone, 2026-11-17)
			if not choseNone[player] then ensurePet(player, DEFAULT_PET_ID) end
		else
			gatherPets(player)                  -- มีอยู่แล้ว แค่เรียกมาอยู่ข้างๆ (เคารพตัวที่ผู้เล่นเลือกไว้)
		end
	end)

	task.spawn(function()
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		task.wait(2)
		checkPetSlots(player)
		local restoreOk, restored = pcall(applySavedSettings, player)
		if not restoreOk then
			warn("PetManager: กู้การตั้งค่าไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(restored))
		end
		-- ไม่มีข้อมูลเก่า (ผู้เล่นใหม่) ให้ตัวเริ่มต้นไปก่อน
		if not (restoreOk and restored) then
			ensurePet(player, DEFAULT_PET_ID)
		end
		initialised[player] = true
		-- ส่งรายชื่อสัตว์ให้เมนูเสมอหลังโหลดเสร็จ (2026-10-09) เดิมส่งเฉพาะตอนมีสัตว์ถูกพาออกมา
		-- คนที่ไม่มีตัวเริ่มต้น (กระต่าย) และไม่ได้พาตัวไหนออกมา เช่น ได้แค่นากจากสมุดปลา เมนูจึงว่างตลอด
		if player.Parent then
			sendAbilitiesInfo(player)
			petListInfo:FireClient(player, buildPetList(player), getActiveList(player))
		end
		-- โหลดไม่ได้ตอนเข้าเกม: ลองใหม่เป็นระยะจนได้ แล้วค่อยกู้สัตว์ที่เคยเซฟไว้ (ระหว่างนี้ไม่เซฟทับ ดู saveSettings)
		while player.Parent and settingsLoadFailed[player] do
			task.wait(LOAD_RETRY_SECONDS)
			if not player.Parent then break end
			local okRetry, restoredLater = pcall(applySavedSettings, player)
			if okRetry and not settingsLoadFailed[player] then
				print("🐾 PetManager: โหลดการตั้งค่าของ " .. player.Name .. " ได้แล้ว (กู้สัตว์ที่เคยเซฟไว้: " .. tostring(restoredLater) .. ")")
				petListInfo:FireClient(player, buildPetList(player), getActiveList(player))
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

-- ============ ความหิว: หิวเองตามเวลา (เฉพาะตัวที่พาออกมา) + ให้อาหารด้วยผลผลิต ============
task.spawn(function()
	while true do
		task.wait(PetHunger.PASSIVE_INTERVAL)
		for player, playerPets in pairs(activePets) do
			if player.Parent and initialised[player] then
				for petId in pairs(playerPets) do
					PetHunger.Consume(player, petId, PetHunger.PASSIVE_COST)
				end
				scheduleSave(player)
			end
		end
	end
end)

local FEED_MAX_DISTANCE = 15 -- ต้องยืนใกล้สัตว์เลี้ยงจริง (ป้ายกดให้อาหารขึ้นที่ 10 เผื่อสัตว์ขยับ)

-- ผู้เล่นถืออาหารสัตว์แล้วกดให้อาหารที่ตัวสัตว์เลี้ยง (1 ถุงต่อครั้ง ดาวสูงอิ่มมากกว่า)
-- ป้อนได้เฉพาะอาหารสัตว์ (ตั้งแต่ 2026-09-29) ผลผลิต/ปลาต้องเอาไปทำเป็นอาหารสัตว์ที่เครื่องทำอาหารสัตว์ก่อน
-- เสียงเคี้ยวตอนให้อาหาร เล่นที่ตัวสัตว์ (คนรอบๆ ได้ยินด้วย) เปลี่ยนเสียงได้ที่เลขนี้
local FEED_SOUND_ID = "rbxassetid://137096768206416" -- eat_crunchybread
local function playFeedSound(model)
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not part then return end
	local sound = Instance.new("Sound")
	sound.Name = "FeedSound"
	sound.SoundId = FEED_SOUND_ID
	sound.Volume = 0.8
	sound.PlaybackSpeed = 0.95 + math.random() * 0.2 -- เพี้ยนนิดหน่อยทุกคำ ให้ไม่ซ้ำเป๊ะ
	sound.RollOffMaxDistance = 60
	sound.SoundGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds")
	sound.Parent = part
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 4)
end

-- skipDistance = true ตอนสัตว์วิ่งมาถึงข้างเจ้าของเองแล้ว (กดเรียกจากป้ายเลือกสัตว์)
local feedPet = function(player, petId, skipDistance)
	local petInstance = activePets[player] and activePets[player][petId]
	if not petInstance or not petInstance.model or not petInstance.model.Parent then return end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or (not skipDistance and (hrp.Position - petInstance.model:GetPivot().Position).Magnitude > FEED_MAX_DISTANCE) then return end

	local tool = character:FindFirstChildOfClass("Tool")
	if not (tool and tool:GetAttribute("IsPetFood")) then
		harvestNotify:FireClient(player, nil, nil, nil, L(player, "🥫 สัตว์กินได้เฉพาะอาหารสัตว์ · เอาผลผลิตหรือปลาไปทำที่เครื่องทำอาหารสัตว์", "🥫 Pets only eat pet food · Turn crops or fish into food at the pet food machine"))
		return
	end

	local current = PetHunger.Get(player, petId)
	-- อิ่มเต็มแต่เสียชีวิตไปบ้าง (แมวเก้าชีวิต) ยังให้อาหารได้ เพื่อเติมชีวิตให้ครบ
	local maxLives = PetHunger.GetMaxLives(petId)
	local livesMissing = maxLives > 0 and PetHunger.GetLives(player, petId) < maxLives
	if current >= PetHunger.MAX and not livesMissing then
		harvestNotify:FireClient(player, nil, nil, nil, "😋 " .. petNameFor(player, petInstance.definition) .. L(player, " อิ่มแล้ว", " is full"))
		return
	end

	local star = math.clamp(tool:GetAttribute("Star") or 1, 1, 5)
	local gain = PetHunger.PET_FOOD_BY_STAR[star] or PetHunger.PET_FOOD_BY_STAR[1]
	local newValue = PetHunger.Change(player, petId, gain)
	playFeedSound(petInstance.model)

	-- หักอาหารสัตว์ 1 ถุง
	local count = tool:GetAttribute("Count") or 1
	if count <= 1 then
		tool:Destroy()
	else
		tool:SetAttribute("Count", count - 1)
		tool.Name = ItemFactory.GetPetFoodName(star, count - 1, Localization.GetLanguage(player))
	end

	harvestNotify:FireClient(player, nil, nil, nil,
		string.format(L(player, "🍖 %s อิ่มขึ้น +%d%% (%d%%)", "🍖 %s fullness +%d%% (%d%%)"), petNameFor(player, petInstance.definition),
			math.floor(newValue - current + 0.5), math.floor(newValue + 0.5)))
	-- แมวเก้าชีวิต: ได้กินแล้วดวงไฟวิญญาณ (ชีวิต) กลับมาครบ
	if livesMissing then
		PetHunger.RestoreLives(player, petId)
		harvestNotify:FireClient(player, nil, nil, nil,
			string.format(L(player, "🔮 %s ชีวิตกลับมาครบ %d ดวง", "🔮 %s's lives are back to %d"), petNameFor(player, petInstance.definition), maxLives))
	end
	scheduleSave(player)
end

-- ผู้เล่นถืออาหารสัตว์แล้วแตะสัตว์ที่ป้ายบนจอ: สัตว์หยุดกิจกรรม วิ่งมาหาเจ้าของ แล้วกินอาหารที่ถืออยู่ (ปุ่ม F ตอนยืนใกล้สัตว์ยังใช้ได้ตามเดิม)
local CALL_TIMEOUT = 12 -- วินาที ไปไม่ถึงภายในเวลานี้ = ยกเลิกแล้วกลับไปทำงาน
local function callPetToEat(player, petId)
	local petInstance = activePets[player] and activePets[player][petId]
	if not petInstance or not petInstance.model or not petInstance.model.Parent or not petInstance.CallToEat then return end
	local lang = Localization.GetLanguage(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not (tool and tool:GetAttribute("IsPetFood")) then
		harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(lang, "🥫 ถืออาหารสัตว์ไว้ในมือก่อนนะ", "🥫 Hold pet food in your hand first"))
		return
	end
	local maxLives = PetHunger.GetMaxLives(petId)
	local livesMissing = maxLives > 0 and PetHunger.GetLives(player, petId) < maxLives
	if PetHunger.Get(player, petId) >= PetHunger.MAX and not livesMissing then
		harvestNotify:FireClient(player, nil, nil, nil, "😋 " .. petNameFor(player, petInstance.definition) .. Localization.Pick(lang, " อิ่มแล้ว", " is full"))
		return
	end
	petInstance.CallToEat(CALL_TIMEOUT, function() feedPet(player, petId, true) end)
end

petFeed.OnServerEvent:Connect(function(player, petId, mode)
	if type(petId) ~= "string" then return end
	if mode == "call" then
		callPetToEat(player, petId)
	else
		feedPet(player, petId, false)
	end
end)

-- แมวเก้าชีวิตหิวจนหมดแรงแล้วฟื้นคืนชีพเอง (PetHunger.Consume) แจ้งผู้เล่นให้รู้
PetHunger.Revived.Event:Connect(function(player, petId, livesLeft)
	if not player.Parent then return end
	local def = PetDefinitions[petId]
	local name = def and petNameFor(player, def) or petId
	local text = livesLeft > 0
		and string.format(L(player, "🔮 %s ฟื้นคืนชีพ! (เหลือ %d ชีวิต) ให้อาหารเพื่อเติมชีวิต", "🔮 %s came back to life! (%d lives left) Feed it to refill its lives"), name, livesLeft)
		or string.format(L(player, "🔮 %s ใช้ชีวิตสุดท้ายแล้ว! รีบให้อาหารนะ", "🔮 %s is on its last life! Feed it soon"), name)
	harvestNotify:FireClient(player, nil, nil, nil, text)
	scheduleSave(player)
end)

-- ได้สัตว์ตัวใหม่ (เช่น จากตู้สุ่ม) ส่งรายชื่อใหม่ให้เมนู ตัวที่เป็นเงาจะกลายเป็นตัวจริง
PetOwnership.Changed.Event:Connect(function(player, petId)
	if not player.Parent then return end
	petListInfo:FireClient(player, buildPetList(player), getActiveList(player))
end)

Players.PlayerRemoving:Connect(function(player)
	PetSeedSlots.Clear(player)
	DataLoadRetry.BeginLeaveSave(player.UserId) -- เข้าเซิร์ฟเดิมทันที = รอเซฟนี้ก่อนโหลด
	pcall(saveSettings, player)   -- ต้องเซฟก่อน removeAllPets ไม่งั้นข้อมูลถูกล้างไปแล้ว
	DataLoadRetry.EndLeaveSave(player.UserId)
	lastSavedJson[player] = nil
	finalSaved[player] = true -- BindToClose ห้ามเซฟซ้ำหลังนี้ (สัตว์ถูกลบแล้ว จะได้รายการว่างทับของดี)
	removeAllPets(player)
	PetOwnership.Unload(player)
	savePending[player] = nil
	initialised[player] = nil
	setupDone[player] = nil
	settingsLoadFailed[player] = nil
end)

-- เซิร์ฟเวอร์ถูกปิด/รีสตาร์ท เซฟของทุกคนที่ยังอยู่ก่อน
game:BindToClose(function()
	-- 2026-11-18 เซฟพร้อมกันทุกคน (แต่ละคนอาจรอเว้นระยะ 7 วิ เดิมทีละคน อาจเกินเวลาปิดเซิร์ฟ 30 วิ)
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			pcall(saveSettings, player)
			pending -= 1
		end)
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 25 do task.wait(0.2) end
end)

-- ผู้เล่นที่เข้ามาก่อนสคริปต์นี้เริ่มทำงาน (เกิดบ่อยใน Studio และเกิดได้ในเกมจริง)
-- เดิมโค้ดสปอว์นให้เฉพาะคนที่ "มีตัวละครแล้ว" ณ วินาทีนั้น และไม่ผูก CharacterAdded ไว้ด้วย
-- ใครที่ตัวละครยังไม่เกิดพอดีจึงไม่ได้สัตว์เลี้ยงเลยทั้งเซสชัน -- อาการ "บางทีสัตว์เลี้ยงไม่มา"
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

print("[PetManager] ระบบสัตว์เลี้ยง (รองรับหลายตัว/หลายความสามารถ) เริ่มทำงานแล้ว")