-- BACKUP of ServerScriptService.PetSystem.PetOwnership before Thai/English player messages (i18n phase 1, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.PetSystem.PetOwnership.Source in Studio
-- PetOwnership: ผู้เล่นแต่ละคน "มี" สัตว์เลี้ยงตัวไหนบ้าง (พาออกมาได้เฉพาะตัวที่มี) + เลเวล / ตัวซ้ำ / เศษวิญญาณ
-- เก็บแยกจากการตั้งค่าสัตว์เลี้ยง (PetSettings_v1) เพราะของที่ได้มา (เช่น จากตู้สุ่มที่จ่าย Robux) หายไม่ได้
-- การเซฟใช้ UpdateAsync แบบ "รวมกัน" เสมอ (ของเดิม + ของใหม่) ไม่มีทางลบสัตว์ที่มีอยู่แล้ว ต่อให้เซิร์ฟเวอร์ 2 ตัวเซฟชนกัน
--
-- ข้อมูล: { owned = {[petId]=true}, dupes = {[petId]=n ตัวซ้ำค้างจากระบบเดิม}, levels = {[petId]=เลเวล}, shards = เศษวิญญาณ, v = 1 }
-- ได้ตัวซ้ำ = +1 เลเวลทันที (สูงสุด PetLevelConfig.MAX_LEVEL) เลเวลเต็มแล้วค่อยกลายเป็นเศษวิญญาณ
--   (ระบบเดิมเก็บตัวซ้ำไว้ให้ผู้เล่นเลือกเอง ตัวที่ค้างอยู่จะถูกอัปเลเวล/แปลงเป็นเศษให้ตอนเข้าเกม ดู applyPendingDupes)
-- ตั้งเป็น Attribute บนตัวผู้เล่นด้วย (หน้าจออ่านไปแสดง + PetHunger อ่านเลเวลไปคิดความเร็ว/ความหิว)
--   PetLevel_<petId> (เฉพาะตัวที่มี), PetDupes_<petId> (มีตัวซ้ำรอใช้), PetShards
--
-- ย้ายข้อมูลผู้เล่นเก่า (ครั้งแรกที่เข้าเกมหลังมีระบบนี้): เคยพาตัวไหนออกมาใช้ ได้เป็นเจ้าของตัวนั้น
--   ดูจากข้อมูลเดิมใน PetSettings_v1: ตัวที่พาออกมาอยู่ / เคยตั้งความสามารถ / มีค่าความหิวหรือชีวิต (= เคยใช้งานจริง)
--   ทุกคนได้ตัวเริ่มต้น (กระต่าย) เสมอ

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetDefinitions = require(script.Parent:WaitForChild("PetDefinitions"))
local PetLevelConfig = require(ReplicatedStorage:WaitForChild("PetLevelConfig"))

local PetOwnership = {}

PetOwnership.STARTER_PET_ID = "PastelPinkRabbit"
-- เปิดชั่วคราวได้ถ้าอยากให้ทุกคนมีทุกตัวเหมือนเดิม (เช่น ช่วงที่ตู้สุ่มยังไม่เปิด) ข้อมูลความเป็นเจ้าของยังเซฟตามปกติ
PetOwnership.UNLOCK_ALL = false

PetOwnership.Changed = Instance.new("BindableEvent") -- :Fire(player, petId) ตอนได้สัตว์ตัวใหม่ (PetManager ส่งเมนูใหม่)

local store = DataStoreService:GetDataStore("PetOwnership_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local owned = {} -- [player] = { [petId] = true }

local function keyOf(player)
	-- ทดสอบใน Studio: workspace Attribute "DevPetKeyOverride" = คีย์ปลอมแทน UserId (ไม่แตะข้อมูลจริง) ตั้งใน Edit mode แล้วลบทิ้ง
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevPetKeyOverride") and player.UserId > 0 then return tostring(workspace:GetAttribute("DevPetKeyOverride")) end
	return tostring(player.UserId)
end

local function rarityOf(petId)
	local def = PetDefinitions[petId]
	return def and def.Rarity or "Common"
end

-- จัดข้อมูลที่โหลดมาให้ครบทุกช่อง (ข้อมูลรุ่นแรกมีแค่ owned/dupes)
local function normalize(old)
	local data = (type(old) == "table" and type(old.owned) == "table") and old or { owned = {} }
	-- (2026-10-02) ไม่แจกกระต่ายตัวเริ่มต้นให้ทุกคนแล้ว: ผู้เล่นเก่าที่มีบันทึกมีกระต่ายใน owned อยู่แล้ว ผู้เล่นใหม่เริ่มด้วยมือเปล่า
	data.dupes = type(data.dupes) == "table" and data.dupes or {}
	data.levels = type(data.levels) == "table" and data.levels or {}
	data.shards = math.max(0, math.floor(tonumber(data.shards) or 0))
	data.v = 1
	return data
end

local function levelIn(data, petId)
	return math.clamp(math.floor(tonumber(data.levels[petId]) or 1), 1, PetLevelConfig.MAX_LEVEL)
end

-- ตั้ง Attribute ให้ตรงกับข้อมูลที่เซฟแล้ว
local function publish(player, data)
	if not (player and player.Parent) then return end
	for petId in pairs(PetDefinitions) do
		local has = data.owned[petId] == true or PetOwnership.UNLOCK_ALL
		player:SetAttribute("PetLevel_" .. petId, has and levelIn(data, petId) or nil)
		local d = math.floor(tonumber(data.dupes[petId]) or 0)
		player:SetAttribute("PetDupes_" .. petId, d > 0 and d or nil)
	end
	player:SetAttribute("PetShards", data.shards)
end

-- เซฟแบบรวมกัน: สัตว์ที่เซฟไว้แล้ว + สัตว์ที่ส่งมา (ไม่มีทางลบ) คืนค่าชุดสุดท้ายที่เซฟสำเร็จ หรือ nil ถ้าเซฟไม่ได้
local function saveMerge(player, petIds)
	local result
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			for _, petId in ipairs(petIds) do
				data.owned[petId] = true
			end
			result = data
			return data
		end)
	end)
	if not ok then
		warn("PetOwnership: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return nil
	end
	publish(player, result)
	return result.owned
end

-- ตัวซ้ำที่ค้างจากระบบเดิม -> อัปเลเวลให้เลย ส่วนที่เกินเลเวลเต็มเป็นเศษ
-- คืนค่า ข้อความสรุป (ไว้แจ้งผู้เล่น) หรือ nil ถ้าไม่มีอะไรเปลี่ยน
local function applyPendingDupes(player)
	local summary, final = {}, nil
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			summary = {}
			local changed = false
			for petId, n in pairs(data.dupes) do
				n = math.floor(tonumber(n) or 0)
				if n > 0 and PetDefinitions[petId] then
					local level = levelIn(data, petId)
					local steps = math.min(n, PetLevelConfig.MAX_LEVEL - level)
					if steps > 0 then
						data.levels[petId] = level + steps
						table.insert(summary, string.format("%s Lv.%d", PetDefinitions[petId].DisplayName, level + steps))
					end
					local extra = n - steps
					if extra > 0 then data.shards += extra * PetLevelConfig.ShardValue(rarityOf(petId)) end
				end
				changed = true
			end
			data.dupes = {}
			final = data
			return changed and data or nil
		end)
	end)
	if not ok then
		warn("PetOwnership: แปลงตัวซ้ำค้างไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return nil
	end
	if final then publish(player, final) end
	return #summary > 0 and ("⬆️ ตัวซ้ำที่เก็บไว้ถูกนำไปอัปเลเวลแล้ว: " .. table.concat(summary, ", ")) or nil
end

-- หาสัตว์ที่ผู้เล่นเคยใช้ จากข้อมูลการตั้งค่าเดิม (PetSettings_v1)
local function petsUsedInLegacy(legacy)
	local found = {}
	if type(legacy) ~= "table" then return found end
	if type(legacy.pets) == "table" then
		for _, entry in ipairs(legacy.pets) do
			if type(entry) == "table" and type(entry.id) == "string" then found[entry.id] = true end
		end
	end
	for _, field in ipairs({ "abilities", "hunger", "lives" }) do
		if type(legacy[field]) == "table" then
			for petId in pairs(legacy[field]) do
				if type(petId) == "string" then found[petId] = true end
			end
		end
	end
	return found
end

-- โหลดตอนผู้เล่นเข้าเกม (เรียกจาก PetManager ก่อนกู้สัตว์ที่เคยพาออกมา)
-- legacyData/legacyOk = ข้อมูล PetSettings_v1 ที่โหลดมาแล้ว (ใช้ย้ายข้อมูลครั้งแรก)
local loadedOwnership = {} -- [player] = true เมื่อ Load เสร็จจริง (ชุด owned ครบแล้ว)
local function loadOwnership(player, legacyData, legacyOk)
	-- เก็บตัวที่ได้ก่อนโหลดเสร็จไว้ (เช่น นากจากสมุดปลา / มังกรสุลต่าน) ไม่รีเซ็ตเหลือแค่ตัวเริ่มต้น
	-- เดิมสร้างชุดใหม่ทุกครั้ง ถ้าโหลดซ้ำ ระหว่างรอ DataStore ระบบอื่นเห็นว่าไม่มีตัวที่มีจริง (มังกรสุลต่าน "ได้ใหม่" ทุกครั้งที่เข้าเกม)
	local set = owned[player] or {}
	owned[player] = set

	-- ลองจนได้ (เดิมลองครั้งเดียว พัง = ไม่มีสัตว์สักตัวทั้งรอบตอน DataStore throttle) 2026-10-09
	-- PetManager เรียกจากเธรดกู้สัตว์เลี้ยง (รอได้ = กู้สัตว์ที่เคยพาออกมาได้ถูกต้องหลังโหลดเสร็จ)
	local ok, record = DataLoadRetry.Load(player, "PetOwnership", DataLoadRetry.Get(store, keyOf(player)))
	if not ok then
		-- ผู้เล่นออกไปก่อนโหลดได้: ไม่เซฟอะไร (ของที่เซฟไว้ไม่หาย)
		publish(player, normalize(nil))
		return set
	end

	if type(record) == "table" and type(record.owned) == "table" then
		for petId in pairs(record.owned) do
			if PetDefinitions[petId] then set[petId] = true end
		end
		publish(player, normalize(record))
		if type(record.dupes) == "table" and next(record.dupes) then
			task.spawn(function()
				local message = applyPendingDupes(player)
				if message then
					task.wait(5) -- รอหน้าจอผู้เล่นโหลดเสร็จก่อนแจ้ง
					local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
					local notify = remotes and remotes:FindFirstChild("HarvestNotify")
					if notify and player.Parent then notify:FireClient(player, nil, nil, nil, message) end
				end
			end)
		end
		return set
	end

	-- ยังไม่เคยมีข้อมูล: ย้ายจากข้อมูลเดิม (เฉพาะตอนโหลดข้อมูลเดิมสำเร็จ ไม่งั้นคนเก่าจะเหลือแค่กระต่ายถาวร)
	if not legacyOk then
		publish(player, normalize(nil))
		return set
	end
	-- ผู้เล่นใหม่เอี่ยม (ไม่มีทั้งบันทึกสัตว์และข้อมูลเดิม): ไม่แจกกระต่าย สร้างบันทึกเปล่าทันที รอบหน้าจะได้ไม่ถูกนับว่า "ข้อมูลเดิมที่ต้องย้าย" แล้วได้กระต่าย
	if legacyData == nil then
		if not saveMerge(player, {}) then publish(player, normalize(nil)) end
		return set
	end
	-- ผู้เล่นเก่าที่ยังไม่เคยมีบันทึกสัตว์ (ย้ายข้อมูลครั้งแรก): ยังได้กระต่ายเหมือนเดิม + ตัวที่เคยใช้
	set[PetOwnership.STARTER_PET_ID] = true
	local ids = { PetOwnership.STARTER_PET_ID }
	for petId in pairs(petsUsedInLegacy(legacyData)) do
		if PetDefinitions[petId] and petId ~= PetOwnership.STARTER_PET_ID then
			set[petId] = true
			table.insert(ids, petId)
		end
	end
	if not saveMerge(player, ids) then
		local data = normalize(nil)
		for _, petId in ipairs(ids) do data.owned[petId] = true end
		publish(player, data)
	end
	return set
end

-- โหลดความเป็นเจ้าของ: เรียกครั้งเดียวต่อผู้เล่น ทุกทางออกของ loadOwnership ถือว่าเสร็จ (รวมโหลดไม่ได้ = มีแค่ตัวเริ่มต้น)
function PetOwnership.Load(player, legacyData, legacyOk)
	local set = loadOwnership(player, legacyData, legacyOk)
	loadedOwnership[player] = true
	return set
end

-- ระบบอื่นที่จะให้สัตว์/เช็กว่ามีสัตว์ตัวไหน ต้องรอตรงนี้ก่อน (Attribute PetLevel_* ถูกตั้งตั้งแต่การเซฟครั้งแรกของระบบอื่น
-- ทั้งที่ชุด owned ยังไม่ครบ ทำให้ "ไม่มีมังกร/นาก" ผิดๆ แล้วให้ซ้ำ + แจ้ง "ได้ตัวใหม่" ทุกครั้งที่เข้าเกม)
function PetOwnership.WaitLoaded(player, timeout)
	local waited = 0
	while player.Parent and not loadedOwnership[player] and waited < (timeout or 60) do
		waited += task.wait(0.25)
	end
	return loadedOwnership[player] == true
end

function PetOwnership.Owns(player, petId)
	if PetOwnership.UNLOCK_ALL then return PetDefinitions[petId] ~= nil end
	local set = owned[player]
	return set ~= nil and set[petId] == true
end

function PetOwnership.GetOwned(player)
	local list = {}
	for petId in pairs(PetDefinitions) do
		if PetOwnership.Owns(player, petId) then table.insert(list, petId) end
	end
	return list
end

function PetOwnership.GetLevel(player, petId)
	return player:GetAttribute("PetLevel_" .. petId) or 1
end

function PetOwnership.GetDupes(player, petId)
	return player:GetAttribute("PetDupes_" .. petId) or 0
end

function PetOwnership.GetShards(player)
	return player:GetAttribute("PetShards") or 0
end

local function markOwned(player, petId)
	local set = owned[player]
	if not set then
		set = {}
		owned[player] = set
	end
	local isNew = not set[petId]
	set[petId] = true
	return isNew
end

-- ให้สัตว์กับผู้เล่น (เช่น จากตู้สุ่ม) เซฟทันที คืนค่า isNew, saved
-- isNew = เพิ่งได้ครั้งแรก (ไม่ใช่ตัวซ้ำ), saved = เซฟลง DataStore สำเร็จ
function PetOwnership.Grant(player, petId)
	if not PetDefinitions[petId] then return false, false end
	local isNew = markOwned(player, petId)
	local saved = saveMerge(player, { petId }) ~= nil
	if isNew then PetOwnership.Changed:Fire(player, petId) end
	return isNew, saved
end

-- ให้หลายตัวพร้อมกัน (ผลสุ่ม 1 หรือ 10 ครั้ง) เซฟครั้งเดียว
-- ตัวที่มีอยู่แล้ว (หรือออกซ้ำในชุดเดียวกัน) = +1 เลเวลทันที, เลเวลเต็มแล้ว = กลายเป็นเศษวิญญาณ
-- คืนค่า results (เรียงตาม petIds: { petId, isNew, level (เลเวลใหม่ถ้าอัป), shards (ถ้าเป็นเศษ) }) หรือ nil ถ้าเซฟไม่ได้ (ผู้เรียกต้องคืนตั๋ว)
function PetOwnership.GrantBatch(player, petIds)
	local results, final
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			-- เริ่มจากของที่มีในเซิร์ฟเวอร์ด้วย (เช่น ย้ายข้อมูลครั้งแรกที่เซฟไม่ทัน)
			for petId in pairs(owned[player] or {}) do data.owned[petId] = true end
			results = {}
			for _, petId in ipairs(petIds) do
				local isNew = not data.owned[petId]
				local shards, level = nil, nil
				if isNew then
					data.owned[petId] = true
				elseif levelIn(data, petId) >= PetLevelConfig.MAX_LEVEL then
					shards = PetLevelConfig.ShardValue(rarityOf(petId))
					data.shards += shards
				else
					level = levelIn(data, petId) + 1
					data.levels[petId] = level
				end
				table.insert(results, { petId = petId, isNew = isNew, level = level, shards = shards })
			end
			final = data
			return data
		end)
	end)
	if not ok or not results then
		warn("PetOwnership: ให้สัตว์หลายตัวไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return nil
	end
	local gotNew = false
	for _, r in ipairs(results) do
		if r.isNew then markOwned(player, r.petId); gotNew = true end
	end
	publish(player, final)
	if gotNew then PetOwnership.Changed:Fire(player) end
	return results
end

-- ใช้ตัวซ้ำ: action = "level" (1 ตัว = +1 เลเวล) หรือ "shards" (แลกเป็นเศษวิญญาณ)
-- คืนค่า สำเร็จ, ข้อความ
function PetOwnership.UseDupes(player, petId, action, count)
	local def = PetDefinitions[petId]
	if not def then return false, "ไม่รู้จักสัตว์ตัวนี้" end
	count = math.floor(tonumber(count) or 0)
	if count ~= count or count < 1 then return false, "จำนวนไม่ถูกต้อง" end -- count ~= count = NaN (ทะลุการเทียบกับจำนวนตัวซ้ำได้)
	if action ~= "level" and action ~= "shards" then return false, "คำขอไม่ถูกต้อง" end
	local success, message, final = false, "ทำรายการไม่สำเร็จ", nil
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			final = data
			local have = math.floor(tonumber(data.dupes[petId]) or 0)
			if have < count then
				success, message = false, "ตัวซ้ำไม่พอ"
				return nil
			end
			local used
			if action == "level" then
				local level = levelIn(data, petId)
				local steps = math.min(count, PetLevelConfig.MAX_LEVEL - level)
				if steps <= 0 then
					success, message = false, "เลเวลเต็มแล้ว (แลกตัวซ้ำเป็นเศษได้)"
					return nil
				end
				data.levels[petId] = level + steps
				used = steps
				success, message = true, string.format("⬆️ %s Lv.%d!", def.DisplayName, level + steps)
			else
				local gain = count * PetLevelConfig.ShardValue(rarityOf(petId))
				data.shards += gain
				used = count
				success, message = true, string.format("💠 ได้เศษวิญญาณ +%d", gain)
			end
			data.dupes[petId] = have - used > 0 and have - used or nil
			return data
		end)
	end)
	if not ok then
		warn("PetOwnership: ใช้ตัวซ้ำไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return false, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง"
	end
	if final then publish(player, final) end
	return success, message
end

-- แลกเศษวิญญาณเป็นสัตว์ (ผู้เรียกเช็กเองว่าตัวนี้แลกได้ตอนนี้ไหม)
-- มีอยู่แล้ว = +1 เลเวล, เลเวลเต็มแล้วแลกไม่ได้ (เสียเศษเปล่า)
-- คืนค่า สำเร็จ, ข้อความ, isNew
function PetOwnership.ExchangeShards(player, petId)
	local def = PetDefinitions[petId]
	local cost = def and PetLevelConfig.ShardCostOf(rarityOf(petId))
	if not cost then return false, "ตัวนี้แลกด้วยเศษไม่ได้" end
	local success, message, isNew, final = false, "ทำรายการไม่สำเร็จ", false, nil
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			for id in pairs(owned[player] or {}) do data.owned[id] = true end
			final = data
			if data.shards < cost then
				success, message = false, string.format("เศษวิญญาณไม่พอ (ต้องใช้ %d)", cost)
				return nil
			end
			isNew = not data.owned[petId]
			if not isNew and levelIn(data, petId) >= PetLevelConfig.MAX_LEVEL then
				success, message = false, "ตัวนี้เลเวลเต็มแล้ว"
				return nil
			end
			data.shards -= cost
			if isNew then
				data.owned[petId] = true
				message = string.format("🎉 ได้ %s แล้ว!", def.DisplayName)
			else
				local level = levelIn(data, petId) + 1
				data.levels[petId] = level
				message = string.format("⬆️ %s Lv.%d!", def.DisplayName, level)
			end
			success = true
			return data
		end)
	end)
	if not ok then
		warn("PetOwnership: แลกเศษไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return false, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง", false
	end
	if final then publish(player, final) end
	if success and isNew then
		markOwned(player, petId)
		PetOwnership.Changed:Fire(player, petId)
	end
	return success, message, isNew
end

-- อัปเลเวลด้วยเศษวิญญาณ (นาก / ระดับลับ / สุลต่าน ราคาดู PetLevelConfig.LevelUpCostOf) ต้องมีสัตว์ตัวนั้นอยู่แล้ว
-- ไม่มีสัตว์ = ไม่หักเศษ; เลเวลเต็ม = ไม่หักเศษ; คืนค่า สำเร็จ, ข้อความ
function PetOwnership.LevelUpWithShards(player, petId)
	local def = PetDefinitions[petId]
	local cost = def and PetLevelConfig.LevelUpCostOf(petId, rarityOf(petId))
	if not cost then return false, "ตัวนี้อัพเลเวลด้วยเศษไม่ได้" end
	local success, message, final = false, "ทำรายการไม่สำเร็จ", nil
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			for id in pairs(owned[player] or {}) do data.owned[id] = true end
			final = data
			if not data.owned[petId] then
				success, message = false, "ไม่สามารถอัพเลเวลได้ (ยังไม่มีสัตว์ตัวนี้)"
				return nil
			end
			local level = levelIn(data, petId)
			if level >= PetLevelConfig.MAX_LEVEL then
				success, message = false, "ตัวนี้เลเวลเต็มแล้ว"
				return nil
			end
			if data.shards < cost then
				success, message = false, string.format("เศษวิญญาณไม่พอ (ต้องใช้ %d)", cost)
				return nil
			end
			data.shards -= cost
			data.levels[petId] = level + 1
			success, message = true, string.format("⬆️ %s Lv.%d!", def.DisplayName, level + 1)
			return data
		end)
	end)
	if not ok then
		warn("PetOwnership: อัปเลเวลด้วยเศษไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return false, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง"
	end
	if final then publish(player, final) end
	return success, message
end

-- สัตว์พรีเมียมที่ซื้อด้วย Robux (PremiumPetService) 2026-10-14: ยังไม่มี = ได้ตัว (Lv.1) / มีแล้ว = +1 เลเวล (ไม่เกิน maxLevel)
-- เลเวลเต็มแล้ว (ซื้อซ้อนกันก่อนหน้าจอปิดปุ่มทัน) = ไม่เปลี่ยนอะไร คืน maxed = true ให้ผู้เรียกจัดการเอง
-- คืนค่า { isNew, level, maxed } หรือ nil ถ้าเซฟไม่ได้ (ผู้เรียกต้องตอบ Roblox ว่ายังไม่ให้ของ)
-- setLevel (2026-10-15 โค้ด MMG-): ตั้งเลเวลตรงๆ แทน +1 (ยังไม่มี = ได้ตัวเลเวลนั้น · มีแล้ว = ขึ้นเป็นเลเวลนั้น · ถึงแล้ว = maxed)
function PetOwnership.GrantPremium(player, petId, maxLevel, setLevel)
	if not PetDefinitions[petId] then return nil end
	maxLevel = math.min(maxLevel or PetLevelConfig.MAX_LEVEL, PetLevelConfig.MAX_LEVEL)
	if setLevel then setLevel = math.clamp(math.floor(setLevel), 1, maxLevel) end
	local result, final
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			for id in pairs(owned[player] or {}) do data.owned[id] = true end
			final = data
			if not data.owned[petId] then
				data.owned[petId] = true
				data.levels[petId] = setLevel or 1
				result = { isNew = true, level = setLevel or 1 }
				return data
			end
			local level = levelIn(data, petId)
			if level >= (setLevel or maxLevel) then
				result = { isNew = false, level = level, maxed = true }
				return nil
			end
			data.levels[petId] = setLevel or (level + 1)
			result = { isNew = false, level = setLevel or (level + 1) }
			return data
		end)
	end)
	if not ok or not result then
		warn("PetOwnership: ให้สัตว์พรีเมียมไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
		return nil
	end
	if final then publish(player, final) end
	if result.isNew then
		markOwned(player, petId)
		PetOwnership.Changed:Fire(player, petId)
	end
	return result
end

function PetOwnership.Unload(player)
	owned[player] = nil
	loadedOwnership[player] = nil
end

return PetOwnership
