-- BACKUP 2026-11-12 of game.StarterPlayer.StarterPlayerScripts.HotbarState (ModuleScript, Studio) before "seeds kept in the bag stay in the bag after rejoin".
-- Restore: copy everything BELOW the "==== SOURCE ====" line into that script's Source in Studio.
-- ==== SOURCE ====
-- HotbarState: เก็บว่าไอเทมไหนอยู่ช่องไหนใน 9 ช่องหลัก + ระบบลาก-วาง (drag and drop)
-- ใช้ร่วมกันระหว่าง CustomHotbar และ FullInventoryGui (state ฝั่ง client เท่านั้น)
-- วางเป็น ModuleScript ไว้ใน StarterPlayerScripts ระดับเดียวกับสองสคริปต์นั้น

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemPreview = require(ReplicatedStorage:WaitForChild("ItemPreview"))

local HotbarState = {}

local MAX_SLOTS = 6 -- 6 ช่อง (ช่อง 6 = เบ็ด) ผู้เล่นขอ 2026-10-01 เดิม 9 ช่อง
-- ช่อง 1-2 สงวนไว้ให้เมล็ดเท่านั้น ใส่หุ่นเพิ่มดวงไม่ได้
-- เพราะสัตว์เลี้ยง (ความสามารถ "ช่วยปลูกผัก") หยิบของจากสองช่องแรกไปปลูกให้อัตโนมัติ
local RESERVED_SEED_SLOTS = 2
-- ให้สคริปต์อื่นแจ้งเตือนตอนวางไม่ได้ (CustomHotbar ตั้งค่าไว้เพื่อให้ช่องกระพริบแดง)
HotbarState.OnAssignRejected = nil
local slots = {} -- [1..9] = Tool instance หรือ nil
local pendingTool = nil -- ไอเทมที่ผู้เล่นเลือกจากกระเป๋าเต็ม รอวางลงช่อง
local inventoryOpen = false -- กระเป๋าเต็มเปิดอยู่หรือไม่ (ใช้คุมว่าจะโชว์ปุ่ม x ในแถบ 9 ช่องไหม)

-- คืนไอเทมในช่องนั้น (เคลียร์ทิ้งอัตโนมัติถ้าไอเทมถูกทำลายไปแล้ว เช่นใช้จนหมด)
function HotbarState.GetSlotTool(index)
	local tool = slots[index]
	if tool and tool.Parent then
		return tool
	end
	slots[index] = nil
	return nil
end

-- ช่อง 9 = เบ็ดตกปลาเท่านั้น (เบ็ดก็อยู่ได้แค่ช่อง 9) กด "ใช้" เบ็ดอีกคันในกระเป๋า = สลับเบ็ดในช่อง 9 (ผู้เล่นขอ 2026-10-01)
local ROD_SLOT = MAX_SLOTS
HotbarState.ROD_SLOT = ROD_SLOT

-- เมล็ดพันธุ์ = มี CropType แต่ไม่ใช่ผลผลิต/หุ่น (นิยามเดียวกับ TutorialGui.countSeeds)
local function isSeed(tool)
	return tool:GetAttribute("CropType") ~= nil and not tool:GetAttribute("IsProduce") and not tool:GetAttribute("IsBooster")
end
HotbarState.IsSeed = isSeed

-- เมล็ดไม้ผล (มะม่วง/ทุเรียน) ไม่มี CropType แต่ให้อยู่ช่องเมล็ด 1-2 ได้ (สัตว์ช่วยปลูกข้ามเอง เพราะเซิร์ฟ PetSeedSlots รับเฉพาะที่มี CropType) 2026-10-26
local function isAnySeed(tool)
	return isSeed(tool) or tool:GetAttribute("IsOrchardSeed") == true
end

-- ช่องนี้รับไอเทมชิ้นนี้ได้ไหม
function HotbarState.CanPlaceInSlot(tool, index)
	if index < 1 or index > MAX_SLOTS then return false end -- ช่องที่ไม่มีแล้ว (ข้อมูลเก่าสมัย 9 ช่อง)
	if not tool then return true end
	local isRod = tool:GetAttribute("IsFishingRod") == true
	if index == ROD_SLOT then return isRod end
	if isRod then return false end
	-- ช่อง 1-2 = เมล็ดเท่านั้น (ผู้ใช้ขอ 2026-10-16 กันผู้เล่นใหม่งง · สัตว์ช่วยปลูกหยิบเมล็ดจากสองช่องนี้)
	if index <= RESERVED_SEED_SLOTS then
		return isAnySeed(tool)
	end
	return true
end

function HotbarState.IsReservedSlot(index)
	return index <= RESERVED_SEED_SLOTS
end

function HotbarState.FindSlotOf(tool)
	for i = 1, MAX_SLOTS do
		if slots[i] == tool then
			return i
		end
	end
	return nil
end

function HotbarState.IsAssigned(tool)
	return HotbarState.FindSlotOf(tool) ~= nil
end

-- ล้าง slot ที่ไอเทมถูกทำลาย/หายไปแล้ว
function HotbarState.CleanupInvalid()
	for i = 1, MAX_SLOTS do
		local tool = slots[i]
		if tool and not tool.Parent then
			slots[i] = nil
		end
	end
	if pendingTool and not pendingTool.Parent then
		pendingTool = nil
	end

	-- ของที่อยู่ผิดช่อง (เช่นวางไว้ก่อนมีกฎ: หุ่นในช่อง 1-2 / เบ็ดนอกช่อง 9 / ของอื่นในช่อง 9) ย้ายไปช่องที่ถูก
	-- ไม่มีช่องให้ = กลับไปอยู่ในกระเป๋า (เช่น มีเบ็ดในแถบ 2 คัน คันที่สองกลับกระเป๋า)
	for i = 1, MAX_SLOTS do
		local tool = slots[i]
		if tool and not HotbarState.CanPlaceInSlot(tool, i) then
			slots[i] = nil
			for j = 1, MAX_SLOTS do
				if not slots[j] and HotbarState.CanPlaceInSlot(tool, j) then
					slots[j] = tool
					break
				end
			end
		end
	end
end

-- ============ จำช่องข้ามการเข้าเกมใหม่ (เซิร์ฟเวอร์เซฟที่ HotbarLayout) ============
-- key ของไอเทม = ชนิด + ดาว/รุ่น (ไม่รวมจำนวน) เช่น "IsFishingRod=true|RodId=Rainbow"
-- IsFurniture/FurnId = ของตกแต่งจากตู้สัตว์ขี่ (2026-10-16) FurnitureService อ่าน "FurnId=<id>" จากผังที่เซฟไว้เพื่อให้ Tool คืนตอนเข้าเกม
local KEY_ATTRIBUTES = { "IsFishingRod", "IsFish", "IsBait", "IsPetFood", "IsBooster", "IsProduce", "IsJunk", "CropType", "Star", "RodId", "BoosterTier", "FishId", "IsFurniture", "FurnId", "IsOrchardSeed", "IsOrchardFruit", "FruitKind", "IsStealHand", "IsSlapHand", "Mutation", "StealTier", "IsOrchardMat", "MatId", "IsOrchardTool", "OrchardToolId", "IsKrathong", "KrathongId" } -- เมล็ด/ผลไม้สวน 2026-10-26 (เดิมได้ key ว่าง = เซฟช่องไม่ติด)
function HotbarState.ToolKey(tool)
	local parts = {}
	for _, name in ipairs(KEY_ATTRIBUTES) do
		local value = tool:GetAttribute(name)
		if value ~= nil then table.insert(parts, name .. "=" .. tostring(value)) end
	end
	return table.concat(parts, "|")
end

local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer
-- 2026-10-11 ghostKeys[ช่อง] = ชนิดของที่ "จอง" ช่องนั้นอยู่ แม้ตัวของจะหายไปชั่วคราว (ใช้หมด / เกิดใหม่ / เซิร์ฟเวอร์กำลังปิดแล้วลบของก่อนตัดการเชื่อมต่อ)
-- ใช้ตอนส่งช่องไปเซฟ: เดิมส่งตามของที่มีอยู่จริง ณ ตอนนั้น ของหายชั่วคราว = เซฟแถบว่างทับของเดิม (พบข้อมูลเซฟของเจ้าของเกมว่างทั้ง 9 ช่อง)
-- ล้างเมื่อผู้เล่นถอดของออกเอง (Unassign) หรือของชนิดนั้นไปอยู่ช่องอื่นแล้ว
local ghostKeys = {}
local remembered = {}          -- [key] = ช่องล่าสุดของของชนิดนี้ (0 = เก็บไว้ในกระเป๋า)
local restoreDone = false      -- จัดช่องตามที่เซฟไว้ตอนเข้าเกมแล้วหรือยัง
local restoreDeadline = os.clock() + 30 -- รอข้อมูลช่องจากเซิร์ฟเวอร์ (HotbarLayoutLoaded) ได้นานสุดเท่านี้
local joinWindowUntil = 0   -- ช่วงเข้าเกม (กระเป๋ายังโหลดไม่ครบ): ของที่ไม่อยู่ในช่องที่เซฟไว้ = อยู่ในกระเป๋า / ไม่ส่งเซฟ
local hasSavedLayout = false
local restoreReadySince = nil
local respawnUntil = 0         -- ช่วงหลังเกิดใหม่: ของถูกสร้างใหม่หมด (InventorySystem) ให้กลับช่องเดิม/อยู่กระเป๋าเหมือนเดิม
local lastSentLayout = nil
local pendingLayout, pendingSince = nil, 0

localPlayer.CharacterAdded:Connect(function()
	respawnUntil = os.clock() + 8
end)

-- ตอนเข้าเกม: ได้ข้อมูลช่องจากเซิร์ฟเวอร์ (HotbarLayoutLoaded) = จำไว้ว่าของชนิดไหนอยู่ช่องไหน แล้วจัดตามนั้น
-- ของค่อยๆ มาจาก InventorySystem (เซิร์ฟเวอร์ช้าอาจนานหลายสิบวินาที) ระหว่างรอ (joinWindow) ของที่มาใหม่:
--   ตรงกับช่องที่เซฟ = ลงช่องนั้น / ไม่ตรง = อยู่ในกระเป๋า / ไม่ส่งเซฟทับ (เดิมรอแค่ 25 วิ ช้ากว่านั้นแถบถูกจัดใหม่ทั้งหมดแล้วเซฟทับของเดิม)
-- ยังไม่เคยเซฟ (ผู้เล่นใหม่) = จัดของใหม่ลงช่องว่างแบบเดิม
-- อ่านช่องที่เซิร์ฟเวอร์ส่งมา (Attribute HotbarLayout) ลง remembered · คืน true ถ้ามีข้อมูลเซฟ
local function readSavedLayout()
	local raw = localPlayer:GetAttribute("HotbarLayout")
	local ok, keys = pcall(function() return HttpService:JSONDecode(raw) end)
	if not (type(raw) == "string" and ok and type(keys) == "table") then return false end
	lastSentLayout = raw
	hasSavedLayout = true
	for i = 1, math.max(#keys, MAX_SLOTS) do -- ข้อมูลเก่าอาจมี 9 ช่อง: ช่อง 7-9 / เบ็ดช่อง 9 ย้ายไปช่องที่ถูกให้เอง (AutoAssignNew)
		local key = keys[i]
		if type(key) == "string" and key ~= "" then
			remembered[key] = i
			if i <= MAX_SLOTS then ghostKeys[i] = key end
		end
	end
	return true
end

-- 2026-10-11: เซิร์ฟเวอร์อ่านช่องไม่ทันภายใน restoreDeadline (หลังรีเซิร์ฟ DataStore โดนจำกัด) = รอต่อแบบ "มาช้า"
-- ระหว่างนั้นของอยู่ในกระเป๋า ไม่จัดลงช่องเอง และไม่ส่งช่องไปเซฟ (เดิมจัดใหม่แล้วเซฟทับ = เมล็ดหลุดจากช่อง 1-2)
-- ข้อมูลมาถึงเมื่อไหร่ AutoAssignNew จัดของลงช่องที่เซฟไว้ให้ (lateRestore)
local lateRestore = false

local function tryRestore(allTools)
	if not localPlayer:GetAttribute("HotbarLayoutLoaded") then
		if os.clock() < restoreDeadline then return false end
		restoreDone = true
		lateRestore = true
		return true
	end
	restoreDone = true
	-- ช่วงเข้าเกมเริ่มเสมอ (มี/ไม่มีข้อมูลเซฟ) สูงสุด 120 วิ ปกติจบเร็วกว่านี้ตอนกระเป๋าโหลดเสร็จ (ดูใน AutoAssignNew)
	joinWindowUntil = os.clock() + 120
	readSavedLayout()
	return true
end

-- ส่งช่องปัจจุบันให้เซิร์ฟเวอร์เซฟ (เฉพาะตอนเปลี่ยน และนิ่งแล้ว 1.5 วิ ไม่ยิงถี่)
local function syncLayout()
	if not restoreDone or os.clock() < respawnUntil or os.clock() < joinWindowUntil then return end
	if lateRestore or not localPlayer:GetAttribute("HotbarLayoutLoaded") then return end -- เซิร์ฟเวอร์ยังอ่านช่องเดิมไม่ได้ = ยังไม่ส่ง
	local keys = {}
	for i = 1, MAX_SLOTS do
		local tool = HotbarState.GetSlotTool(i)
		keys[i] = tool and HotbarState.ToolKey(tool) or ghostKeys[i] or ""
	end
	local json = HttpService:JSONEncode(keys)
	if json == lastSentLayout then pendingLayout = nil return end
	if json ~= pendingLayout then
		pendingLayout, pendingSince = json, os.clock()
		return
	end
	if os.clock() - pendingSince < 1.5 then return end
	local remote = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("HotbarLayoutSave")
	if not remote then return end
	remote:FireServer(keys)
	lastSentLayout, pendingLayout = json, nil
end

-- หาช่องว่างแรกที่ของชิ้นนี้ลงได้ (เบ็ด = ช่อง 9 / หุ่น-อาหาร-ปลา = ไม่ลงช่อง 1-2)
local function firstFreeSlot(tool)
	for i = 1, MAX_SLOTS do
		if not HotbarState.GetSlotTool(i) and HotbarState.CanPlaceInSlot(tool, i) then return i end
	end
	return nil
end

-- ช่องเมล็ดว่างแรก (1 ก่อน 2) · nil = เต็มทั้งสองช่อง
local function firstFreeSeedSlot()
	for i = 1, RESERVED_SEED_SLOTS do
		if not HotbarState.GetSlotTool(i) then return i end
	end
	return nil
end

-- จำนวนเมล็ดล่าสุดของแต่ละถุง: ซื้อเพิ่มเข้าถุงเดิมที่อยู่ในกระเป๋า (Count เพิ่ม) = ถือว่าเพิ่งซื้อ
local seedCounts = setmetatable({}, { __mode = "k" })
-- กระทง/โคมลอย (2026-11-07 ผู้ใช้สั่ง): จำนวนล่าสุดของแต่ละกอง ไว้ดูว่า "เพิ่งซื้อ" (กองใหม่ หรือ Count เพิ่ม)
local krathongCounts = setmetatable({}, { __mode = "k" })

-- ช่องว่างแรกสำหรับกระทง (ช่อง 3-5 ตาม CanPlaceInSlot) ช่องที่ยังจองให้ของชนิดอื่น (ghostKeys ของที่เพิ่งใช้หมด) ใช้หลังสุด · nil = เต็ม
local function freeSlotForKrathong(tool)
	local key = HotbarState.ToolKey(tool)
	local fallback
	for i = 1, MAX_SLOTS do
		if not HotbarState.GetSlotTool(i) and HotbarState.CanPlaceInSlot(tool, i) then
			if ghostKeys[i] == nil or ghostKeys[i] == key then return i end
			fallback = fallback or i
		end
	end
	return fallback
end

-- จัดไอเทมใหม่ (ที่ยังไม่เคยเห็นมาก่อน) ลงช่องว่างแรกอัตโนมัติ
-- ไอเทมที่เคยถูกถอดออกจากช่องโดยตั้งใจ (Unassign) จะไม่ถูกจัดกลับเข้าไปเองอีก
-- ของชนิดที่เคยอยู่ช่องไหน ได้มาใหม่ (ซื้อใหม่หลังใช้หมด/เกิดใหม่/เข้าเกม) กลับไปช่องเดิมถ้าว่าง (ช่องเดิมผิดกฎแล้ว = ช่องที่ถูก)
function HotbarState.AutoAssignNew(allTools)
	HotbarState.CleanupInvalid()
	if not restoreDone and not tryRestore(allTools) then return end
	-- ข้อมูลช่องมาถึงช้า: จัดของที่ยังไม่อยู่ในแถบลงช่องที่เซฟไว้ (ไม่ยุ่งกับของที่ผู้เล่นวางเองระหว่างรอ)
	-- ไม่มีข้อมูลเซฟเลย (ผู้เล่นใหม่) = จัดลงช่องว่างให้แบบผู้เล่นใหม่
	if lateRestore and localPlayer:GetAttribute("HotbarLayoutLoaded") then
		lateRestore = false
		local hasSaved = readSavedLayout()
		for _, tool in ipairs(allTools) do
			if tool.Parent and not HotbarState.IsAssigned(tool) then
				local isX100 = tool:GetAttribute("IsBooster") == true and tool:GetAttribute("BoosterTier") == "x100"
				if hasSaved then
					local known = remembered[HotbarState.ToolKey(tool)]
					if known and known > 0 and not isX100 then
						local target = (not HotbarState.GetSlotTool(known) and HotbarState.CanPlaceInSlot(tool, known)) and known
							or (not HotbarState.CanPlaceInSlot(tool, known) and firstFreeSlot(tool)) or nil
						if target then slots[target] = tool end
					end
				elseif not isX100 and not tool:GetAttribute("IsProduce") and not tool:GetAttribute("IsFish") and not tool:GetAttribute("IsBait") then
					local target = firstFreeSlot(tool)
					if target then slots[target] = tool end
				end
			end
		end
	end
	-- กระเป๋าโหลดเสร็จแล้ว 2 วิ = จบช่วงเข้าเกม
	if joinWindowUntil > os.clock() and localPlayer:GetAttribute("InventoryLoaded") then
		joinWindowUntil = math.min(joinWindowUntil, os.clock() + 2)
	end
	local joining = os.clock() < joinWindowUntil
	local respawning = os.clock() < respawnUntil
	-- ของใหม่ที่ไม่เคยอยู่ในแถบ (ซื้อ/ได้รับ/ทำจากเครื่อง) = เข้ากระเป๋า ผู้เล่นกด "ใช้" เอง (ผู้เล่นขอ 2026-10-01)
	-- ยกเว้นตอนเข้าเกมครั้งแรกของคนที่ยังไม่เคยเซฟช่อง (ผู้เล่นใหม่/ข้อมูลเก่า) จัดลงช่องให้แบบเดิม จะได้ไม่เริ่มด้วยแถบว่าง
	local autoFill = joining and not hasSavedLayout

	for _, tool in ipairs(allTools) do
		if not tool:GetAttribute("_HotbarSeen") then
			tool:SetAttribute("_HotbarSeen", true)
			local key = HotbarState.ToolKey(tool)
			local known = remembered[key]
			local keepX100InInventory = tool:GetAttribute("IsBooster") == true and tool:GetAttribute("BoosterTier") == "x100"
			if HotbarState.IsAssigned(tool) then
				-- อยู่ในช่องแล้ว
			elseif known and known > 0 and not keepX100InInventory then
				-- เคยอยู่ช่องนี้: ลงช่องเดิม / ช่องเดิมผิดกฎ (เช่นเบ็ดเคยอยู่ช่อง 4) หรือไม่ว่าง = ช่องที่ถูก (ถ้ายังเข้าเกมอยู่)
				local target = (not HotbarState.GetSlotTool(known) and HotbarState.CanPlaceInSlot(tool, known)) and known
					or (not HotbarState.CanPlaceInSlot(tool, known) and firstFreeSlot(tool)) or nil
				if target then slots[target] = tool end
			elseif not autoFill or keepX100InInventory then
				-- ของใหม่/ของที่ไม่ได้อยู่ในแถบตอนออก = อยู่ในกระเป๋า
			-- ผลผลิตที่เก็บเกี่ยวได้ ไม่จัดลงแถบ 9 ช่องอัตโนมัติ ให้อยู่แค่ในกระเป๋าเต็มเท่านั้น
			elseif not tool:GetAttribute("IsProduce") and not tool:GetAttribute("IsFish") and not tool:GetAttribute("IsBait") then
				local target = firstFreeSlot(tool)
				if target then slots[target] = tool end
			end
		end
	end

	-- เมล็ดที่เพิ่งได้มา (ซื้อจากร้าน = ถุงใหม่ หรือจำนวนในถุงเดิมเพิ่ม) ลงช่อง 1 หรือ 2 ก่อน เต็มแล้วค่อยอยู่ในกระเป๋า (ผู้ใช้ขอ 2026-10-16)
	-- ช่วงเข้าเกม/เกิดใหม่ไม่ทำ (ของถูกสร้างใหม่ทั้งหมด ให้กลับช่องที่เซฟไว้ตามเดิม)
	for _, tool in ipairs(allTools) do
		if tool.Parent and isAnySeed(tool) then
			local count = tool:GetAttribute("Count") or 1
			local before = seedCounts[tool]
			seedCounts[tool] = count
			local gained = before == nil or count > before
			-- 2026-11-03 ผู้เล่นแจ้ง: เอาเมล็ดเบอร์รี่แม่มดออกจากช่อง 2 แล้วบางทีกลับมาเอง (จำนวนเมล็ดเพิ่ม = ถูกยัดกลับ สัตว์เลยปลูกต่อ)
			-- เมล็ดชนิดที่อยู่ในกระเป๋าอยู่แล้ว (remembered = 0) ไม่ยัดกลับ เหมือนเบ็ด · เมล็ดชนิดใหม่ที่ไม่เคยมี ยังลงช่อง 1/2 เหมือนเดิม
			if gained and remembered[HotbarState.ToolKey(tool)] == 0 then gained = false end
			if gained and not joining and not respawning and restoreDone and not lateRestore and not HotbarState.IsAssigned(tool) then
				local target = firstFreeSeedSlot()
				if target then slots[target] = tool end
			end
		end
	end

	-- เบ็ดที่เพิ่งได้มาลงช่อง 6 เองถ้าช่องว่าง (ผู้ใช้ขอ 2026-10-18: ผู้เล่นใหม่ได้เบ็ดไม้ไผ่ฟรีหลังเกิด ~4 วิ ซึ่งเลยช่วงจัดช่องตอนเข้าเกม เดิมเลยไปอยู่ในกระเป๋า)
	-- เบ็ดชนิดที่ผู้เล่นเคยเอาออกไปไว้กระเป๋าเอง (remembered = 0) ไม่ยัดกลับ · ช่วงเข้าเกม/เกิดใหม่ไม่ทำ (ให้คืนช่องที่เซฟไว้ตามเดิม)
	if not joining and not respawning and restoreDone and not lateRestore and not HotbarState.GetSlotTool(ROD_SLOT) then
		for _, tool in ipairs(allTools) do
			if tool.Parent and tool:GetAttribute("IsFishingRod") and not HotbarState.IsAssigned(tool)
				and remembered[HotbarState.ToolKey(tool)] ~= 0 then
				slots[ROD_SLOT] = tool
				break
			end
		end
	end

	-- กระทง/โคมลอยที่เพิ่งซื้อ (กองใหม่ หรือจำนวนเพิ่ม) และยังไม่อยู่ในแถบ = ลงช่องว่างก่อน (ช่อง 3-5) เต็ม = อยู่ในกระเป๋า (ผู้ใช้สั่ง 2026-11-07)
	-- ต่างจากเมล็ด: เคยเอาชนิดนี้ไปไว้กระเป๋าเอง (remembered = 0) ซื้อใหม่ก็ยังลงช่องว่าง · ช่วงเข้าเกม/เกิดใหม่ไม่ทำ (กลับช่องที่เซฟไว้)
	for _, tool in ipairs(allTools) do
		if tool.Parent and tool:GetAttribute("IsKrathong") then
			local count = tool:GetAttribute("Count") or 1
			local before = krathongCounts[tool]
			krathongCounts[tool] = count
			local gained = before == nil or count > before
			if gained and not joining and not respawning and restoreDone and not lateRestore and not HotbarState.IsAssigned(tool) then
				local target = freeSlotForKrathong(tool)
				if target then slots[target] = tool end
			end
		end
	end

	-- จำว่าของแต่ละชนิดอยู่ช่องไหนตอนนี้ (ของที่ไม่อยู่แล้ว เช่นใช้หมด จำค่าเดิมไว้)
	-- ช่วงเข้าเกม/เกิดใหม่ยังไม่จำ "อยู่กระเป๋า" (ของบางชิ้นอาจยังมาไม่ถึง / ยังไม่ถูกจัดช่อง)
	-- 2026-10-19 แก้บั๊ก: เดิมผู้เล่นใหม่ได้เบ็ดไม้ไผ่ช่วงเกิดใหม่ ถูกจำเป็น 0 (= ผู้เล่นเอาไปกระเป๋าเอง) เลยไม่ลงช่อง 6 ต้องเปิดกระเป๋ากด "ใช้"
	for _, tool in ipairs(allTools) do
		local slot = HotbarState.FindSlotOf(tool)
		if slot or not (joining or respawning) then remembered[HotbarState.ToolKey(tool)] = slot or 0 end
	end
	-- อัปเดตการจองช่อง: ช่องที่มีของ = จองตามของนั้น / ช่องว่างที่ของชนิดที่จองไปอยู่ช่องอื่นแล้ว = เลิกจอง
	local liveKeys = {}
	for i = 1, MAX_SLOTS do
		local tool = HotbarState.GetSlotTool(i)
		if tool then
			ghostKeys[i] = HotbarState.ToolKey(tool)
			liveKeys[ghostKeys[i]] = true
		end
	end
	for i = 1, MAX_SLOTS do
		if ghostKeys[i] and not HotbarState.GetSlotTool(i) and liveKeys[ghostKeys[i]] then ghostKeys[i] = nil end
	end
	syncLayout()
end

-- วางไอเทมลงช่องที่กำหนด ถ้าช่องนั้นมีของอยู่แล้วจะสลับที่กัน
-- คืน true ถ้าวางสำเร็จ, false ถ้าช่องนั้นรับไอเทมชิ้นนี้ไม่ได้
function HotbarState.AssignToSlot(tool, index)
	if index < 1 or index > MAX_SLOTS then return false end

	if not HotbarState.CanPlaceInSlot(tool, index) then
		if HotbarState.OnAssignRejected then
			HotbarState.OnAssignRejected(index, tool)
		end
		return false
	end

	local oldIndex = HotbarState.FindSlotOf(tool)
	local displaced = slots[index]

	slots[index] = tool
	if oldIndex and oldIndex ~= index then
		-- ปกติสลับที่กัน แต่ถ้าของที่ถูกแทนที่ลงช่องเดิมไม่ได้ (เช่นหุ่นจะตกไปอยู่ช่องสงวน)
		-- ให้หาช่องอื่นที่ว่างแทน ถ้าไม่มีเลยก็เอาออกจากแถบไปอยู่ในกระเป๋าเต็ม
		if displaced and not HotbarState.CanPlaceInSlot(displaced, oldIndex) then
			slots[oldIndex] = nil
			for j = 1, MAX_SLOTS do
				if not slots[j] and HotbarState.CanPlaceInSlot(displaced, j) then
					slots[j] = displaced
					break
				end
			end
		else
			slots[oldIndex] = displaced
		end
	end
	return true
end

-- กด "ใช้" ในกระเป๋า: เอาไอเทมลงแถบ 9 ช่อง (แทนการลาก/🔀 เดิม)
-- เบ็ด = ช่อง 9 เสมอ (เบ็ดเดิมในช่อง 9 กลับกระเป๋า) / เมล็ด = ช่องว่างแรก (1-2 ก่อน) / อื่นๆ = ช่องว่างแรกตั้งแต่ช่อง 3
-- คืน true, ช่อง, เบ็ดเดิมที่ถูกแทน / false, "full" (ไม่มีช่องว่างให้)
function HotbarState.UseTool(tool)
	if not tool then return false, "none" end
	local current = HotbarState.FindSlotOf(tool)
	if current then return true, current end
	if tool:GetAttribute("IsFishingRod") then
		local old = HotbarState.GetSlotTool(ROD_SLOT)
		slots[ROD_SLOT] = tool
		return true, ROD_SLOT, old
	end
	for i = 1, MAX_SLOTS do
		if not HotbarState.GetSlotTool(i) and HotbarState.CanPlaceInSlot(tool, i) then
			slots[i] = tool
			return true, i
		end
	end
	return false, "full"
end

-- ถอดไอเทมออกจากช่อง (ไอเทมยังอยู่ในกระเป๋าเหมือนเดิม แค่ไม่โชว์ในแถบ 9 ช่องแล้ว)
function HotbarState.Unassign(index)
	slots[index] = nil
	ghostKeys[index] = nil -- ผู้เล่นถอดเอง = เลิกจองช่องนี้
end

function HotbarState.SetPending(tool)
	pendingTool = tool
end

function HotbarState.GetPending()
	if pendingTool and not pendingTool.Parent then
		pendingTool = nil
	end
	return pendingTool
end

function HotbarState.ClearPending()
	pendingTool = nil
end

-- เปิด/ปิดสถานะกระเป๋าเต็ม ใช้คุมว่าปุ่ม x ในแถบ 9 ช่องควรโชว์ไหม
function HotbarState.SetInventoryOpen(isOpen)
	inventoryOpen = isOpen
end

function HotbarState.IsInventoryOpen()
	return inventoryOpen
end

-- ============ ระบบลาก-วาง (Drag and Drop) ============
-- ใช้ร่วมกับปุ่ม x และ 🔀 เดิมได้ (เลือกวิธีไหนก็ได้)

local player = Players.LocalPlayer

local dragGui = nil
local ghost = nil
local ghostIcon = nil
local ghostCountLabel = nil

local dragging = false
local dragTool = nil
local dragSourceSlotIndex = nil -- index ถ้าลากมาจากช่องในแถบ 9 ช่อง, nil ถ้าลากมาจากกระเป๋าเต็ม

local dragMoveConnection = nil
local dragEndConnection = nil

local uiScale = 1 -- ตัวคูณขนาดปัจจุบันของแถบ 9 ช่อง (CustomHotbar เป็นคนตั้ง) ใช้ย่อ ghost ตอนลากให้เท่ากัน
function HotbarState.SetUiScale(n) uiScale = n end
function HotbarState.GetUiScale() return uiScale end

local slotFrames = {} -- [index] = GuiObject อ้างอิงตำแหน่งจริงของแต่ละช่องในแถบ 9 ช่อง
local inventoryFrame = nil -- อ้างอิงพื้นที่กระเป๋าเต็ม (ปล่อยตรงนี้ = ถอดออกจากช่อง)

function HotbarState.RegisterSlotFrame(index, frame)
	slotFrames[index] = frame
end

function HotbarState.RegisterInventoryFrame(frame)
	inventoryFrame = frame
end

local function ensureDragGui()
	if dragGui and dragGui.Parent then return end

	dragGui = Instance.new("ScreenGui")
	dragGui.Name = "HotbarDragLayer"
	dragGui.ResetOnSpawn = false
	dragGui.DisplayOrder = 100
	dragGui.Parent = player:WaitForChild("PlayerGui")

	ghost = Instance.new("Frame")
	ghost.Name = "DragGhost"
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.Size = UDim2.new(0, 58, 0, 60)
	ghost.BackgroundTransparency = 0.1
	ghost.Visible = false
	ghost.ZIndex = 100
	ghost.Parent = dragGui

	Instance.new("UICorner", ghost).CornerRadius = UDim.new(0, 10)
	local ghostStroke = Instance.new("UIStroke")
	ghostStroke.Color = Color3.fromRGB(140, 100, 65)
	ghostStroke.Thickness = 2
	ghostStroke.Parent = ghost

	ghostIcon = Instance.new("TextLabel")
	ghostIcon.Size = UDim2.new(1, 0, 1, 0)
	ghostIcon.BackgroundTransparency = 1
	ghostIcon.Text = ""
	ghostIcon.TextScaled = true
	ghostIcon.Font = Enum.Font.GothamBold
	ghostIcon.ZIndex = 101
	ghostIcon.Parent = ghost

	ghostCountLabel = Instance.new("TextLabel")
	ghostCountLabel.AnchorPoint = Vector2.new(1, 1)
	ghostCountLabel.Position = UDim2.new(1, -2, 1, -2)
	ghostCountLabel.Size = UDim2.new(0, 22, 0, 16)
	ghostCountLabel.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
	ghostCountLabel.BackgroundTransparency = 0.1
	ghostCountLabel.Text = ""
	ghostCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ghostCountLabel.TextScaled = true
	ghostCountLabel.Font = Enum.Font.GothamBold
	ghostCountLabel.ZIndex = 101
	ghostCountLabel.Visible = false
	Instance.new("UICorner", ghostCountLabel).CornerRadius = UDim.new(0, 6)
	ghostCountLabel.Parent = ghost
end

local function isPointerInput(inputType)
	return inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.Touch
		or inputType == Enum.UserInputType.MouseButton1
end

local function pointInFrame(x, y, frame)
	if not frame or not frame.Parent then return false end
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	return x >= pos.X and x <= pos.X + size.X and y >= pos.Y and y <= pos.Y + size.Y
end

local function findSlotAt(x, y)
	for i = 1, MAX_SLOTS do
		if pointInFrame(x, y, slotFrames[i]) then
			return i
		end
	end
	return nil
end

function HotbarState.GetDragTool()
	return dragging and dragTool or nil
end

local function finishDrag(x, y)
	if not dragging then return end
	dragging = false
	if ghost then ghost.Visible = false end

	if dragMoveConnection then dragMoveConnection:Disconnect() dragMoveConnection = nil end
	if dragEndConnection then dragEndConnection:Disconnect() dragEndConnection = nil end

	if dragTool and dragTool.Parent then
		local targetSlot = findSlotAt(x, y)
		if targetSlot then
			HotbarState.AssignToSlot(dragTool, targetSlot)
		elseif dragSourceSlotIndex and dragSourceSlotIndex ~= ROD_SLOT and pointInFrame(x, y, inventoryFrame) then
			-- ลากจากช่องในแถบมาปล่อยในพื้นที่กระเป๋าเต็ม = ถอดออกจากช่อง (ช่องเบ็ดล็อกไว้)
			HotbarState.Unassign(dragSourceSlotIndex)
		end
		-- ปล่อยไม่ตรงเป้าหมายไหนเลย = ไม่มีอะไรเปลี่ยน ไอเทมอยู่ที่เดิม
	end

	dragTool = nil
	dragSourceSlotIndex = nil
end

-- เริ่มลากจริง (เรียกจาก SetupDraggable ตอนขยับเกินระยะ threshold แล้ว)
local function beginDrag(input, tool, iconText, bgColor, countText, sourceSlotIndex)
	ensureDragGui()

	dragging = true
	dragTool = tool
	dragSourceSlotIndex = sourceSlotIndex

	ghost.BackgroundColor3 = bgColor
	ghostIcon.Text = iconText or ""
	-- ไอเทมที่มีโมเดล 3D (เช่นหุ่นข้าวโพด) โชว์โมเดลติดนิ้วแทนไอคอน ให้เหมือนที่เห็นในช่อง
	local oldPreview = ghostIcon:FindFirstChild("ItemPreview")
	if oldPreview then oldPreview:Destroy() end
	if ItemPreview.Create(ghostIcon, ItemPreview.GetToolModelName(tool)) then
		ghostIcon.Text = ""
	end
	if countText then
		ghostCountLabel.Visible = true
		ghostCountLabel.Text = countText
	else
		ghostCountLabel.Visible = false
	end

	ghost.Size = UDim2.new(0, 58 * uiScale, 0, 60 * uiScale) -- ให้เท่าขนาดช่องจริงบนจอนั้นๆ
	ghost.Position = UDim2.fromOffset(input.Position.X, input.Position.Y)
	ghost.Visible = true

	dragMoveConnection = UserInputService.InputChanged:Connect(function(moveInput)
		if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
			ghost.Position = UDim2.fromOffset(moveInput.Position.X, moveInput.Position.Y)
		end
	end)

	dragEndConnection = UserInputService.InputEnded:Connect(function(endInput)
		if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
			finishDrag(endInput.Position.X, endInput.Position.Y)
		end
	end)
end

local DRAG_THRESHOLD = 8

-- ผูกกลไก "กดค้างแล้วลาก / แตะเฉยๆ" ให้กับปุ่มใดๆ
-- getDragData() -> tool, iconText, bgColor, countText (คืน nil ตัวแรกถ้าไม่มีอะไรให้ลาก)
-- onClick() -> เรียกเมื่อกดแล้วปล่อยโดยไม่ได้ลาก (ขยับไม่เกิน threshold) - ใช้ทำงานแบบเดิม (ถือ/ปลด, เลือก 🔀 ฯลฯ)
-- getSourceSlotIndex() -> optional, คืน index ถ้าปุ่มนี้คือช่องในแถบ 9 ช่อง (ใช้ตอนลากออกไปกระเป๋าเต็ม)
function HotbarState.SetupDraggable(frame, getDragData, onClick, getSourceSlotIndex)
	frame.InputBegan:Connect(function(input)
		if not isPointerInput(input.UserInputType) or input.UserInputType == Enum.UserInputType.MouseMovement then
			return
		end

		local tool, iconText, bgColor, countText = getDragData()

		local startPos = input.Position
		local dragStarted = false

		local localMoveConn, localEndConn

		-- ถ้าไม่มีไอเทมให้ลาก (เช่นช่องว่าง) ก็แค่รอปล่อยแล้วนับเป็นคลิกตามปกติ ไม่ต้องคอยจับการขยับ
		if tool then
			localMoveConn = UserInputService.InputChanged:Connect(function(moveInput)
				if dragStarted then return end
				if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement and moveInput.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				local delta = (moveInput.Position - startPos).Magnitude
				if delta > DRAG_THRESHOLD then
					dragStarted = true
					localMoveConn:Disconnect()
					if localEndConn then localEndConn:Disconnect() end

					local sourceIndex = getSourceSlotIndex and getSourceSlotIndex() or nil
					beginDrag(moveInput, tool, iconText, bgColor, countText, sourceIndex)
				end
			end)
		end

		localEndConn = UserInputService.InputEnded:Connect(function(endInput)
			if endInput.UserInputType ~= Enum.UserInputType.MouseButton1 and endInput.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if localMoveConn then localMoveConn:Disconnect() end
			if localEndConn then localEndConn:Disconnect() end

			if not dragStarted then
				if onClick then onClick() end
			end
		end)
	end)
end

return HotbarState