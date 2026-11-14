-- BACKUP 2026-11-14 before sign item (ป้ายเขียนข้อความ)
-- Studio path: game.ServerScriptService.InventorySystem (Script)
-- Restore: paste everything below this header into that script's Source in Studio

-- InventorySystem: เซฟ/โหลดกระเป๋าเต็มรูปแบบ (เมล็ด, ผลผลิต, หุ่นข้าวโพดดวงดี) ถาวรผ่าน DataStore เหมือนเงิน
-- กันของในกระเป๋าหายตอนออกจากเกมแล้วกลับเข้ามาใหม่

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
-- เมล็ด/ผลไม้สวน (มะม่วง/ทุเรียน) 2026-10-26: kind "OrchardSeed" / "OrchardFruit" { fruitKind, count, starred } · มือขโมย kind "StealHand" { count }
local OrchardItems = require(ServerScriptService:WaitForChild("Orchard"):WaitForChild("OrchardItems"))
-- กระทง (กิจกรรมลอยกระทง) 2026-11-07: kind "Krathong" { krathongId, count }
local KrathongItems = require(ServerScriptService:WaitForChild("Krathong"):WaitForChild("KrathongItems"))

local inventoryDataStore = DataStoreService:GetDataStore("PlayerInventory_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
-- กันกระเป๋าโดนเขียนทับ (2026-10-04): invLoaded[player] = true เฉพาะเมื่ออ่าน DataStore สำเร็จแล้ว (ไม่มีข้อมูล = ผู้เล่นใหม่ นับว่าสำเร็จ)
-- โหลดไม่สำเร็จ = ห้ามเซฟ (เดิมเซฟกระเป๋าว่างทับของจริงตอนออกเกม) และลองโหลดใหม่เบื้องหลังจนกว่าจะได้
-- ทดสอบใน Studio: ตั้ง Attribute DevFailInventoryLoad = จำนวนครั้งที่ให้โหลดล้มเหลว บน ServerScriptService (ลดลงเองทีละครั้ง)
local invLoaded = {}
local lastSavedInventory = {} -- [player] = signature ของกระเป๋าที่ DataStore มีอยู่ล่าสุด
local savingInventory = {}
local AUTOSAVE_INTERVAL = 300 -- เซฟอัตโนมัติทุก 5 นาทีระหว่างเล่น เหมือนระบบเงิน (นอกจากเซฟตอนออกอยู่แล้ว)

-- คีย์ DataStore ของกระเป๋า · ทดสอบใน Studio: ตั้ง Attribute DevInventoryKeyOverride (string) บน workspace = ใช้คีย์ปลอมนั้นแทนกระเป๋าจริง (2026-10-15 สืบเคสกระเป๋าเจ้าของเกมหาย)
-- ทดสอบเป็นทีม (Team Test ก็ IsStudio = true) 2026-10-30: เจ้าของเกมใช้คีย์ปลอมเดิม · คนอื่น = คีย์ปลอม + _<UserId> (กระเป๋าทดสอบของตัวเอง ไม่เซฟทับกัน ไม่แตะกระเป๋าจริง)
local function inventoryKey(player)
	if game:GetService("RunService"):IsStudio() then
		local override = workspace:GetAttribute("DevInventoryKeyOverride")
		if type(override) == "string" and override ~= "" then
			if player.UserId ~= 9360333174 then return override .. "_" .. player.UserId end -- เจ้าของเกม One_moretime91 (เกมเป็นของกลุ่ม CreatorId ใช้ไม่ได้)
			return override
		end
	end
	return tostring(player.UserId)
end

local function inventorySignature(data)
	local rows = {}
	for _, entry in ipairs(data) do
		table.insert(rows, HttpService:JSONEncode(entry))
	end
	table.sort(rows)
	return table.concat(rows, "|")
end

local function getAllTools(player)
	local tools = {}
	for _, location in ipairs({ player.Backpack, player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") then
					table.insert(tools, item)
				end
			end
		end
	end
	return tools
end

-- แปลง Tool หนึ่งชิ้นเป็นข้อมูลเปล่าๆ (nil = ไอเทมชนิดที่ไม่รู้จัก เผื่อมีเพิ่มในอนาคต ข้ามไปเงียบๆ ไม่เซฟ กันสคริปต์พัง)
local function serializeTool(tool)
	local count = tool:GetAttribute("Count") or 1
	if tool:GetAttribute("IsFish") then
		return { kind = "Fish", fishId = tool:GetAttribute("FishId"), star = tool:GetAttribute("Star") or 1, count = count, starred = tool:GetAttribute("Starred") == true or nil }
	elseif tool:GetAttribute("IsFishingRod") then
		return { kind = "Rod", rodId = tool:GetAttribute("RodId") }
	elseif tool:GetAttribute("IsBait") then
		return { kind = "Bait", star = tool:GetAttribute("Star") or 1, count = count }
	elseif tool:GetAttribute("IsPetFood") then
		return { kind = "PetFood", star = tool:GetAttribute("Star") or 1, count = count }
	elseif tool:GetAttribute("IsBooster") then
		-- tier: "x50" / "x100" (ข้อมูลเก่าไม่มี tier = หุ่นข้าวโพดดวงดี ซึ่งตอนนี้คือ x50)
		return { kind = "Booster", count = count, tier = tool:GetAttribute("BoosterTier") or "x50" }
	elseif tool:GetAttribute("IsProduce") then
		return {
			kind = "Produce",
			cropType = tool:GetAttribute("CropType"),
			star = tool:GetAttribute("Star"),
			count = count,
			starred = tool:GetAttribute("Starred") == true or nil, -- ติดดาวไว้ (ไม่ขาย) เซฟไว้ด้วย
			mutation = tool:GetAttribute("Mutation"), -- ผักกลายพันธุ์ (2026-10-30) nil = ผักปกติ ข้อมูลเก่าไม่มีช่องนี้
		}
	elseif tool:GetAttribute("IsOrchardFruit") then
		return { kind = "OrchardFruit", fruitKind = tool:GetAttribute("FruitKind"), count = count, starred = tool:GetAttribute("Starred") == true or nil }
	elseif tool:GetAttribute("IsOrchardSeed") then
		return { kind = "OrchardSeed", fruitKind = tool:GetAttribute("FruitKind"), count = count }
	elseif tool:GetAttribute(OrchardItems.HAND) then
		return { kind = "StealHand", count = count, tier = OrchardItems.TierOf(tool) } -- tier "Bandit" = ตะกร้อจอมโจร (2026-11-02) nil = ธรรมดา
	elseif tool:GetAttribute(OrchardItems.SLAP) then -- มือตบ 2026-10-29
		return { kind = "SlapHand", count = count }
	elseif tool:GetAttribute(OrchardItems.MAT) then -- ท่อนไม้ / ปุ๋ยไม้ผล 2026-11-02
		return { kind = "OrchardMat", matId = tool:GetAttribute("MatId"), count = count }
	elseif tool:GetAttribute(KrathongItems.ATTR) then -- กระทง 2026-11-07
		return { kind = "Krathong", krathongId = tool:GetAttribute("KrathongId"), count = count }
	elseif tool:GetAttribute("CropType") then
		return {
			kind = "Seed",
			cropType = tool:GetAttribute("CropType"),
			count = count,
		}
	end
	return nil
end

-- แปลง Tool ทุกชิ้นที่ผู้เล่นถืออยู่ ให้เป็นข้อมูลเปล่าๆ พร้อมเซฟ (ไม่เซฟตัว Instance ตรงๆ)
local function serializeInventory(player)
	local data = {}
	for _, tool in ipairs(getAllTools(player)) do
		local entry = serializeTool(tool)
		if entry then table.insert(data, entry) end
	end
	return data
end

-- ============ กันกระเป๋าหาย (2026-10-15) ============
-- เหตุ: plr:LoadCharacter() (ทดสอบใน Studio) เกิดใหม่โดยไม่ยิง Humanoid.Died -> ไม่มี snapshot ตอนตาย
--   และ Roblox ลบ Tool ทุกชิ้น + เปลี่ยน Backpack ใหม่ก่อน CharacterRemoving -> เซฟตอนออกเขียนกระเป๋าเหลือแต่เบ็ดทับของจริง
-- 1) ทุก Tool ที่ออกจาก Backpack/ตัวละคร ตรวจซ้ำหลัง 0.5 วิ:
--    - ยังอยู่ในตัวผู้เล่น = แค่ย้ายระหว่างกระเป๋ากับมือ ไม่นับ
--    - ที่อยู่เดิมยังเป็นกระเป๋า/ตัวละครปัจจุบัน = ใช้/ขาย/ปลูก/วางจริง -> นับเป็น "ของที่หายมีเหตุ" (explainedLoss)
--    - ที่อยู่เดิมถูกแทนที่แล้ว (Roblox ล้างตอนเกิดใหม่) = เก็บไว้ใน respawnLost แล้วคืนให้ตอนตัวละครใหม่เกิด ถ้าไม่ได้ตาย (ตายใช้ snapshot ตอน Died เหมือนเดิม)
--    - Count ลดลง (ขาย/ปลูกบางส่วน) ก็นับเป็นของที่หายมีเหตุด้วย
-- 2) ก่อนเซฟ: ของที่หายไปจากเซฟล่าสุด (ไม่นับเบ็ด) ลบด้วยของที่หายมีเหตุ ถ้าเหลือ >= ครึ่งหนึ่งของกระเป๋าเดิม (และกระเป๋าเดิม >= 20 ชิ้น)
--    = ไม่เซฟ เตือน + Attribute InventorySaveBlocked บนผู้เล่น + จดลง DataStore InventoryGuardLog_v1 (คีย์ u<id>, Studio ใช้ studio:u<id>)
local lastSavedData = {} -- [player] = ข้อมูลกระเป๋าที่ DataStore มีล่าสุด (หลังโหลด/หลังเซฟสำเร็จ)
local explainedLoss = {} -- [player] = { [kind] = จำนวนที่ออกจากกระเป๋าแบบมีเหตุ ตั้งแต่เซฟล่าสุด }
local respawnLost = {} -- [player] = { entry, ... } ของที่ Roblox ล้างตอนเกิดใหม่ รอคืน
local SHRINK_BLOCK_RATIO = 0.5
local SHRINK_MIN_TOTAL = 20
local guardLogStore = DataStoreService:GetDataStore("InventoryGuardLog_v1")
local guardLogged = {}

local function kindTotals(data)
	local totals, sum = {}, 0
	for _, e in ipairs(data) do
		if e.kind ~= "Rod" then
			local n = tonumber(e.count) or 1
			totals[e.kind] = (totals[e.kind] or 0) + n
			sum += n
		end
	end
	return totals, sum
end

local function addExplained(player, kind, n)
	if not kind or kind == "Rod" or n <= 0 then return end
	local t = explainedLoss[player]
	if not t then t = {}; explainedLoss[player] = t end
	t[kind] = (t[kind] or 0) + n
end

-- คืน ok, จำนวนที่หายโดยไม่มีเหตุ, จำนวนในเซฟล่าสุด
local function checkShrink(player, data)
	local last = lastSavedData[player]
	if not last then return true, 0, 0 end
	local before, beforeSum = kindTotals(last)
	if beforeSum < SHRINK_MIN_TOTAL then return true, 0, beforeSum end
	local now = kindTotals(data)
	local explained = explainedLoss[player] or {}
	local unexplained = 0
	for kind, n in pairs(before) do
		unexplained += math.max(0, n - (now[kind] or 0) - (explained[kind] or 0))
	end
	return unexplained < beforeSum * SHRINK_BLOCK_RATIO, unexplained, beforeSum
end

local function reportBlocked(player, unexplained, beforeTotal, data)
	local _, nowTotal = kindTotals(data)
	warn(string.format("InventorySystem: ไม่เซฟกระเป๋าของ %s — ของหายโดยไม่มีเหตุ %d จาก %d ชิ้น (ตอนนี้เหลือ %d) กันเขียนทับกระเป๋าจริง", player.Name, unexplained, beforeTotal, nowTotal))
	player:SetAttribute("InventorySaveBlocked", unexplained)
	if guardLogged[player] then return end -- จดลง DataStore ครั้งเดียวต่อรอบเล่น
	guardLogged[player] = true
	local key = (game:GetService("RunService"):IsStudio() and "studio:" or "") .. "u" .. player.UserId
	task.spawn(pcall, function()
		guardLogStore:UpdateAsync(key, function(old)
			old = type(old) == "table" and old or {}
			table.insert(old, { t = os.time(), before = beforeTotal, now = nowTotal, unexplained = unexplained, job = game.JobId })
			while #old > 10 do table.remove(old, 1) end
			return old
		end)
	end)
end

local hookedTools = setmetatable({}, { __mode = "k" }) -- [tool] = Count ล่าสุด
local function hookTool(player, tool)
	if not tool:IsA("Tool") or hookedTools[tool] ~= nil then return end
	hookedTools[tool] = tonumber(tool:GetAttribute("Count")) or 1
	tool:GetAttributeChangedSignal("Count"):Connect(function()
		local old = hookedTools[tool] or 1
		local new = tonumber(tool:GetAttribute("Count")) or 1
		hookedTools[tool] = new
		if new < old and invLoaded[player] then
			local entry = serializeTool(tool)
			if entry then addExplained(player, entry.kind, old - new) end
		end
	end)
end

local function onToolLeft(player, container, tool)
	if not tool:IsA("Tool") or not invLoaded[player] then return end
	local entry = serializeTool(tool)
	if not entry then return end
	task.delay(0.5, function()
		if not player.Parent then return end -- ออกเกมแล้ว (เซฟตอนออกจัดการเอง)
		if tool.Parent and tool:IsDescendantOf(player) then return end
		if player.Character and tool.Parent and tool:IsDescendantOf(player.Character) then return end
		local stillCurrent
		if container:IsA("Backpack") then
			stillCurrent = container.Parent == player
		else
			stillCurrent = container == player.Character
		end
		if stillCurrent then
			addExplained(player, entry.kind, tonumber(entry.count) or 1)
		else
			local list = respawnLost[player]
			if not list then list = {}; respawnLost[player] = list end
			table.insert(list, entry)
		end
	end)
end

local function hookContainer(player, container)
	for _, child in ipairs(container:GetChildren()) do hookTool(player, child) end
	container.ChildAdded:Connect(function(child) hookTool(player, child) end)
	container.ChildRemoved:Connect(function(child) onToolLeft(player, container, child) end)
end

local function saveInventory(player)
	if not invLoaded[player] then
		warn("InventorySystem: ข้ามการเซฟกระเป๋าของ " .. player.Name .. " (ยังโหลดของเดิมไม่สำเร็จ กันเขียนทับ)")
		return
	end
	local ok, data = pcall(serializeInventory, player)
	if not ok then
		warn("InventorySystem: serializeInventory error สำหรับ " .. player.Name .. ": " .. tostring(data))
		return
	end

	local signature = inventorySignature(data)
	if signature == lastSavedInventory[player] then return end -- ไม่มีอะไรเปลี่ยน ไม่ต้องใช้คิว DataStore
	local shrinkOk, unexplained, beforeTotal = checkShrink(player, data)
	if not shrinkOk then
		reportBlocked(player, unexplained, beforeTotal, data) -- กระเป๋าหดผิดปกติ: ไม่เขียนทับของจริง
		return
	end
	if savingInventory[player] then
		local deadline = os.clock() + 12
		repeat task.wait(0.1) until not savingInventory[player] or os.clock() >= deadline
		if savingInventory[player] then return end
		return saveInventory(player) -- เซฟใหม่หลังงานก่อนหน้าเสร็จ เผื่อกระเป๋าเปลี่ยนระหว่างนั้น
	end
	savingInventory[player] = true
	local saveOk, err = false, nil
	for attempt = 1, 3 do
		saveOk, err = pcall(function()
			inventoryDataStore:SetAsync(inventoryKey(player), data)
		end)
		if saveOk then break end
		if attempt < 3 then task.wait((2 ^ (attempt - 1)) + math.random()) end
	end
	savingInventory[player] = nil
	if saveOk then
		lastSavedInventory[player] = signature
		lastSavedData[player] = data
		explainedLoss[player] = nil
		if player:GetAttribute("InventorySaveBlocked") then player:SetAttribute("InventorySaveBlocked", nil) end
	else
		warn("InventorySystem: เซฟไม่สำเร็จสำหรับ " .. player.Name .. " หลังลอง 3 ครั้ง: " .. tostring(err))
	end
end

-- สคริปต์อื่นสั่งเซฟกระเป๋าทันที (ของสวนผลไม้หลักล้าน ไม่รอรอบ 5 นาที) 2026-10-26 · การเซฟยังผ่านตัวกันกระเป๋าหดตามปกติ
local saveNowEvent = Instance.new("BindableEvent")
saveNowEvent.Name = "SaveInventoryNow"
saveNowEvent.Parent = script
saveNowEvent.Event:Connect(function(player)
	if typeof(player) == "Instance" and player:IsA("Player") and player.Parent then task.spawn(saveInventory, player) end
end)

-- สร้าง Tool จากข้อมูลที่เซฟ/ถ่ายไว้ แล้วใส่ลงกระเป๋า
local function giveItems(player, data)
	local lang = Localization.GetLanguage(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		warn("InventorySystem: หา Backpack ของ " .. player.Name .. " ไม่เจอ")
		return
	end

	-- 2026-10-21 รวมกองซ้ำ (ผู้ใช้: ดาวเดียวกันแต่แยกช่อง) เหตุ: ของที่คืน/โหลดถูกสร้างเป็นกองใหม่เสมอ
	--   ระหว่างรอโหลดกระเป๋าตอนเข้าเกม หรือช่วงเกิดใหม่ (ตาย/เปลี่ยนอวาตาร์) สัตว์เลี้ยงเก็บเกี่ยวได้กองใหม่ไปก่อน -> กองดาวเดียวกัน 2 กอง แล้วเซฟแยกค้างตลอด
	--   ตอนนี้: 1) รวมรายการซ้ำในข้อมูลก่อน (ซ่อมกระเป๋าที่เคยแยกไว้แล้ว) 2) มีกองชนิด+ดาวเดียวกันอยู่ในกระเป๋าแล้ว = บวกเข้ากองเดิม ไม่สร้างกองใหม่
	--   ขยะ (ปลา Junk) แยกกองตามติดดาวเหมือนเดิม · ผลผลิต/ปลาอื่นรวมกองแม้ติดดาวคนละแบบ (กองที่รวมได้ติดดาวถ้ามีกองไหนติดดาว)
	local function entryStackKey(entry)
		local kind = entry.kind
		if kind == "Produce" then return "Produce|" .. tostring(entry.cropType) .. "|" .. tostring(entry.star) .. (entry.mutation and ("|" .. tostring(entry.mutation)) or "") end
		if kind == "Fish" then
			local def = FishingConfig.Fish[entry.fishId]
			local key = "Fish|" .. tostring(entry.fishId) .. "|" .. tostring(entry.star or 1)
			if def and def.Junk then key ..= (entry.starred == true and "|starred" or "|normal") end
			return key
		end
		if kind == "Bait" or kind == "PetFood" then return kind .. "|" .. tostring(entry.star or 1) end
		if kind == "Booster" then return "Booster|" .. tostring(entry.tier or "x50") end
		if kind == "Seed" then return "Seed|" .. tostring(entry.cropType) end
		if kind == "OrchardSeed" or kind == "OrchardFruit" then return kind .. "|" .. tostring(entry.fruitKind) end
		if kind == "StealHand" then return "StealHand|" .. tostring(entry.tier or "") end
		if kind == "SlapHand" then return kind end
		if kind == "OrchardMat" then return "OrchardMat|" .. tostring(entry.matId) end
		if kind == "Krathong" then return "Krathong|" .. tostring(entry.krathongId) end
		return nil -- เบ็ด/อื่นๆ ไม่รวม
	end
	local entriesToRestore = {}
	local merged = {}
	for _, entry in ipairs(data) do
		local key = entryStackKey(entry)
		local stack = key and merged[key]
		if stack then
			stack.count = (tonumber(stack.count) or 1) + (tonumber(entry.count) or 1)
			if entry.starred == true then stack.starred = true end
		else
			local copy = table.clone(entry)
			table.insert(entriesToRestore, copy)
			if key then merged[key] = copy end
		end
	end
	-- กองที่มีอยู่ในกระเป๋า/มือแล้ว (เช่นสัตว์เลี้ยงเพิ่งเก็บเกี่ยวให้ระหว่างรอโหลด)
	local existing = {}
	for _, loc in ipairs({ backpack, player.Character }) do
		for _, t in ipairs(loc and loc:GetChildren() or {}) do
			if t:IsA("Tool") then
				local okE, e = pcall(serializeTool, t)
				local key = okE and e and entryStackKey(e)
				if key and not existing[key] then existing[key] = t end
			end
		end
	end
	local function addToTool(tool, entry)
		local n = (tonumber(tool:GetAttribute("Count")) or 1) + (tonumber(entry.count) or 1)
		tool:SetAttribute("Count", n)
		if entry.kind == "Produce" then
			tool.Name = ItemFactory.GetProduceName(entry.cropType, entry.star, n, lang, entry.mutation)
		elseif entry.kind == "Fish" then
			tool.Name = ItemFactory.GetFishName(entry.fishId, entry.star, n, lang)
		elseif entry.kind == "OrchardSeed" or entry.kind == "OrchardFruit" or entry.kind == "StealHand" or entry.kind == "SlapHand" or entry.kind == "OrchardMat" then
			OrchardItems.Rename(tool, lang)
		elseif entry.kind == "Krathong" then
			KrathongItems.Rename(tool, lang)
		else
			local renamed, hits = string.gsub(tool.Name, "x%d+$", "x" .. n)
			if hits > 0 then tool.Name = renamed end
		end
		if entry.starred == true and (entry.kind == "Fish" or entry.kind == "Produce" or entry.kind == "OrchardFruit") then tool:SetAttribute("Starred", true) end
	end
	local remaining = {}
	for _, entry in ipairs(entriesToRestore) do
		local key = entryStackKey(entry)
		local tool = key and existing[key]
		if tool and tool.Parent then
			local okAdd, err = pcall(addToTool, tool, entry)
			if not okAdd then
				warn("InventorySystem: รวมกองไม่สำเร็จ (" .. tostring(key) .. "): " .. tostring(err))
				table.insert(remaining, entry)
			end
		else
			table.insert(remaining, entry)
		end
	end
	entriesToRestore = remaining

	for _, entry in ipairs(entriesToRestore) do
		local createOk, toolOrErr = pcall(function()
			if entry.kind == "Fish" then
				return ItemFactory.CreateFishTool(entry.fishId, entry.star, entry.count, lang)
			elseif entry.kind == "Rod" then
				-- เบ็ดมีได้ขั้นละคันเดียว (ร้านตกปลาอาจคืนเบ็ดที่ซื้อไว้ให้ก่อนแล้ว) มีอยู่แล้ว = ข้าม
				for _, loc in ipairs({ backpack, player.Character }) do
					for _, t in ipairs(loc and loc:GetChildren() or {}) do
						if t:IsA("Tool") and t:GetAttribute("IsFishingRod") and t:GetAttribute("RodId") == entry.rodId then return nil end
					end
				end
				return ItemFactory.CreateRodTool(entry.rodId, lang)
			elseif entry.kind == "Bait" then
				return ItemFactory.CreateBaitTool(entry.star, entry.count, lang)
			elseif entry.kind == "PetFood" then
				return ItemFactory.CreatePetFoodTool(entry.star, entry.count, lang)
			elseif entry.kind == "Booster" then
				return ItemFactory.CreateBoosterTool(entry.count, lang, entry.tier)
			elseif entry.kind == "Produce" then
				return ItemFactory.CreateProduceTool(entry.cropType, entry.star, entry.count, lang, entry.mutation)
			elseif entry.kind == "Seed" then
				return ItemFactory.CreateSeedTool(entry.cropType, entry.count)
			elseif entry.kind == "OrchardSeed" then
				return OrchardItems.CreateSeedTool(entry.fruitKind, tonumber(entry.count) or 1, lang)
			elseif entry.kind == "OrchardFruit" then
				return OrchardItems.CreateFruitTool(entry.fruitKind, tonumber(entry.count) or 1, lang)
			elseif entry.kind == "StealHand" then
				return OrchardItems.CreateHandTool(tonumber(entry.count) or 1, lang, entry.tier)
			elseif entry.kind == "SlapHand" then
				return OrchardItems.CreateSlapTool(tonumber(entry.count) or 1, lang)
			elseif entry.kind == "OrchardMat" then
				return OrchardItems.CreateMatTool(entry.matId, tonumber(entry.count) or 1, lang)
			elseif entry.kind == "Krathong" then
				return KrathongItems.Create(entry.krathongId, tonumber(entry.count) or 1, lang)
			end
			return nil
		end)

		if not createOk then
			warn("InventorySystem: สร้างไอเทมคืนไม่สำเร็จ (" .. tostring(entry.kind) .. "/" .. tostring(entry.cropType) .. "): " .. tostring(toolOrErr))
		elseif toolOrErr then
			if entry.starred == true and (entry.kind == "Fish" or entry.kind == "Produce" or entry.kind == "OrchardFruit") then
				toolOrErr:SetAttribute("Starred", true)
			end
			toolOrErr.Parent = backpack
		end
	end
end

-- ============ ติดดาว (2026-10-03) ============
-- ผู้เล่นกดดาวบนการ์ดในกระเป๋า (FullInventoryGui) ยิง RemoteEvent InventoryStar(tool, ค่าใหม่ true/false)
-- เซิร์ฟเวอร์ตั้ง Attribute Starred บน Tool ของตัวเอง กองที่ติดดาว = ไม่ขาย / ไม่ใส่เครื่องทำอาหารสัตว์ / ไม่ทำเหยื่อ (ดู ShopSystem/FishingShop/PetFoodConverter)
-- ผลผลิต/ปลาชนิดและระดับดาวเดียวกันรวมกองตามปกติ; ขยะรวมกองไม่ติดดาวก่อน และหากไม่มีกองนั้นจึงรวมเข้ากองติดดาวชนิดเดียวกัน
local starRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("InventoryStar")
if not starRemote then
	starRemote = Instance.new("RemoteEvent")
	starRemote.Name = "InventoryStar"
	starRemote.Parent = ReplicatedStorage.RemoteEvents
end
local lastStar = {}
starRemote.OnServerEvent:Connect(function(player, tool, value)
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") or type(value) ~= "boolean" then return end
	if not (tool:IsDescendantOf(player.Backpack) or (player.Character and tool:IsDescendantOf(player.Character))) then return end
	if not (tool:GetAttribute("IsProduce") or tool:GetAttribute("IsFish") or tool:GetAttribute("IsOrchardFruit")) then return end
	local now = os.clock()
	if lastStar[player] and now - lastStar[player] < 0.15 then return end
	lastStar[player] = now
	tool:SetAttribute("Starred", value or nil)
end)
Players.PlayerRemoving:Connect(function(player) lastStar[player] = nil end)

-- ของในกระเป๋าที่ถ่ายไว้ตอนผู้เล่นตาย รอใส่คืนตอนเกิดใหม่ [player] = data
local pendingRestore = {}

-- Roblox ล้าง Backpack ทิ้งตอนตัวละครถูกเก็บ และของที่ถืออยู่ในมือก็หายไปกับตัวละครด้วย
-- วัดจากของจริง: ตอน Humanoid.Died ของยังอยู่ครบ แต่พอถึง CharacterRemoving เหลือ 0 ชิ้นแล้ว
-- จึงต้องถ่ายรายการของไว้ตั้งแต่จังหวะ Died
local function hookDeath(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	humanoid.Died:Once(function()
		local ok, data = pcall(serializeInventory, player)
		if ok then
			pendingRestore[player] = data
		else
			warn("InventorySystem: ถ่ายรายการของตอนตายไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(data))
		end
	end)
end

local function onCharacterAdded(player, character)
	hookDeath(player, character)
	hookContainer(player, character)
	local data = pendingRestore[player]
	pendingRestore[player] = nil
	-- รอให้ Roblox ลอก StarterGear ลง Backpack ให้เสร็จก่อน ไม่งั้นของที่เพิ่งใส่อาจโดนล้างตาม
	-- และรอให้ onToolLeft (หน่วง 0.5 วิ) จดของที่ Roblox ล้างตอนเกิดใหม่ครบก่อน
	task.wait(1)
	local lost = respawnLost[player]
	respawnLost[player] = nil
	if data then
		giveItems(player, data) -- ตายจริง: ใช้ snapshot ตอน Died (ของที่ถูกล้างชุดเดียวกัน ไม่คืนซ้ำ)
	elseif lost and #lost > 0 and game:GetService("RunService"):IsStudio() and game:GetService("ServerScriptService"):GetAttribute("DevSkipRespawnRestore") then
		warn("InventorySystem: DevSkipRespawnRestore เปิดอยู่ ไม่คืนของ " .. #lost .. " กอง (ทดสอบตัวกันกระเป๋าหด)")
	elseif lost and #lost > 0 then
		warn("InventorySystem: " .. player.Name .. " เกิดใหม่โดยไม่ได้ตาย (เช่น LoadCharacter) ของ " .. #lost .. " กองถูกล้าง -> คืนให้")
		giveItems(player, lost)
	end
end

-- สร้างของกลับคืนให้ผู้เล่นตามข้อมูลที่เคยเซฟไว้ (เรียกครั้งเดียวตอนเข้าเกม)
local function restoreInventory(player)
	for attempt = 1, 4 do
		if not player.Parent or invLoaded[player] then return end
		local ok, data
		local forced = game:GetService("RunService"):IsStudio() and (tonumber(game:GetService("ServerScriptService"):GetAttribute("DevFailInventoryLoad")) or 0) or 0
		if forced > 0 then
			game:GetService("ServerScriptService"):SetAttribute("DevFailInventoryLoad", forced - 1)
			ok, data = false, "จำลองโหลดไม่สำเร็จ (DevFailInventoryLoad)"
		else
			DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
			ok, data = pcall(function()
				return inventoryDataStore:GetAsync(inventoryKey(player))
			end)
		end
		if ok then
			if type(data) == "table" then giveItems(player, data) end
			local serializedOk, currentData = pcall(serializeInventory, player)
			if serializedOk and type(data) == "table" then lastSavedInventory[player] = inventorySignature(currentData) end
			if serializedOk then lastSavedData[player] = currentData end -- ฐานเทียบของตัวกันกระเป๋าหด
			player:SetAttribute("InventoryReady", true) -- โหลดสำเร็จจริง = ของที่ได้หลังจากนี้ถูกเซฟ (InventoryLoaded ถูกตั้งแม้โหลดไม่สำเร็จ) 2026-10-13
			invLoaded[player] = true -- อ่านสำเร็จ (ไม่มีข้อมูล = ผู้เล่นใหม่ หรือยังไม่เคยเซฟไว้)
			return
		end
		warn("InventorySystem: โหลดข้อมูลไม่สำเร็จสำหรับ " .. player.Name .. " (ครั้งที่ " .. attempt .. "): " .. tostring(data))
		if attempt < 4 then task.wait(math.min(2 ^ (attempt - 1), 8) + math.random()) end
	end
end

-- สคริปต์อื่นสั่งเซฟกระเป๋าทันที (2026-10-09 โต๊ะช่างคราฟเสร็จ = เซฟเลย กันวัตถุดิบกลับมาถ้าเซิร์ฟเวอร์ล่มก่อนรอบเซฟ) ยังเคารพการกันเซฟก่อนโหลดสำเร็จใน saveInventory
local saveNowEvent = Instance.new("BindableEvent")
saveNowEvent.Name = "SaveInventoryNow"
saveNowEvent.Parent = script
saveNowEvent.Event:Connect(function(player)
	if typeof(player) == "Instance" and player:IsA("Player") and player.Parent then saveInventory(player) end
end)
-- เซฟล่วงหน้าก่อนรีเซิร์ฟ (ServerScriptService.RestartNotice ยิงทีละคน) ตอนปิดจริงของไม่เปลี่ยน = ไม่เขียนซ้ำ (lastSavedInventory) 2026-10-09
task.spawn(function()
	local ev = game:GetService("ServerScriptService"):WaitForChild("PreRestartSave", 60)
	if ev then ev.Event:Connect(function(player)
		if typeof(player) == "Instance" and player:IsA("Player") and player.Parent then task.spawn(saveInventory, player) end
	end) end
end)

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	-- ตัวกันกระเป๋าหาย: ติดตาม Backpack ทุกใบ (Roblox สร้างใบใหม่ทุกครั้งที่เกิด)
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then hookContainer(player, child) end
	end)
	local currentBackpack = player:FindFirstChildOfClass("Backpack")
	if currentBackpack then hookContainer(player, currentBackpack) end

	-- ตอนออกเกม ตัวละครถูกลบก่อน PlayerRemoving จะทำงาน (วัดจริง: ตอน PlayerRemoving ตัวละครหายแล้ว แต่ Backpack ยังอยู่ครบ)
	-- ของที่ถืออยู่ในมืออยู่ใต้ตัวละคร เลยหายไปกับตัวละคร ไม่ถูกเซฟ (บัค: ซื้อหุ่น x100 ถือไว้แล้วออกเกม หุ่นหาย)
	-- จึงย้ายของในมือกลับเข้า Backpack ตั้งแต่ตอนตัวละครกำลังจะถูกลบ
	-- (ตอนตายก็ทำงานด้วย แต่ไม่ซ้ำ เพราะ Roblox ล้าง Backpack เก่าตอนเกิดใหม่ และคืนของจาก snapshot ตอน Died แทน)
	player.CharacterRemoving:Connect(function(character)
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then return end
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				item.Parent = backpack
			end
		end
	end)

	-- รอให้ตัวละคร spawn จริงก่อน (Backpack ก่อนตัวละคร spawn ครั้งแรกยังไม่เสถียร อาจถูกแทนที่ทำให้ของที่เพิ่งใส่หายไป)
	if not player.Character then
		player.CharacterAdded:Wait()
	else
		hookDeath(player, player.Character) -- ตัวละครมาก่อนเราผูกสัญญาณ จึงผูกให้เองตรงนี้
		hookContainer(player, player.Character)
	end

	-- หลุดแล้วเข้าเซิร์ฟเดิมทันที: รอเซฟกระเป๋าของรอบก่อนเสร็จก่อนค่อยอ่าน (ไม่งั้นได้ของเก่า แล้วเซฟทับทีหลัง) 2026-10-10
	DataLoadRetry.WaitLeaveSaves(player)
	restoreInventory(player)
	player:SetAttribute("InventoryLoaded", true)
	-- โหลดไม่ได้: เล่นต่อได้ (สคริปต์อื่นไม่ต้องรอ) แต่ไม่เซฟทับ และลองโหลดใหม่เบื้องหลังทุก 15 วินาที ได้แล้วค่อยคืนของเดิมให้
	task.spawn(function()
		local retryDelay = math.random(20, 35)
		while player.Parent and not invLoaded[player] do
			task.wait(retryDelay)
			retryDelay = math.min(retryDelay * 1.5, 60) + math.random(0, 5)
			restoreInventory(player)
		end
	end) -- สคริปต์อื่นที่จะแจกของตอนเข้าเกม (เช่น แพ็กสุลต่าน) รอตัวนี้ก่อน

	task.spawn(function()
		task.wait(math.random(5, 40)) -- กระจายรอบเซฟของผู้เล่นที่เข้าใกล้กัน
		while player.Parent do
			task.wait(AUTOSAVE_INTERVAL + math.random(0, 30))
			if player.Parent then
				saveInventory(player)
			end
		end
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
-- ผู้เล่นที่เข้ามาก่อนสคริปต์นี้พร้อม (require ด้านบนรอได้) เดิมไม่ถูกโหลดกระเป๋าทั้งรอบ (เจอใน Studio 2026-10-13: กระเป๋าว่าง 120 วิ ไม่มี warn)
for _, existing in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, existing) end

Players.PlayerRemoving:Connect(function(player)
	pendingRestore[player] = nil
	local userId = player.UserId
	DataLoadRetry.BeginLeaveSave(userId) -- รอบใหม่ที่เข้ามาเร็วจะรอเซฟนี้เสร็จก่อนโหลด (pcall ข้างล่างกันค้างตอน error)
	task.wait() -- ให้สคริปต์อื่นที่ผูกกับ PlayerRemoving เหมือนกัน (เช่น PlantingSystem เก็บเกี่ยว/คืนเงินให้อัตโนมัติ) ทำงานเสร็จก่อน แล้วค่อยเซฟ กันข้อมูลตกหล่น
	pcall(saveInventory, player)
	invLoaded[player] = nil
	lastSavedInventory[player] = nil
	lastSavedData[player] = nil
	explainedLoss[player] = nil
	respawnLost[player] = nil
	guardLogged[player] = nil
	DataLoadRetry.EndLeaveSave(userId)
end)

-- เผื่อเซิร์ฟเวอร์ถูกปิด/รีสตาร์ทกะทันหัน เซฟของทุกคนที่ยังออนไลน์อยู่ก่อนปิดจริง
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveInventory(player)
	end
end)
