-- BACKUP of ServerScriptService.FarmSlotRegistry before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into ServerScriptService.FarmSlotRegistry.Source in Studio
-- bytes=4916 sum=2358207
local FarmSlotRegistry = {}
FarmSlotRegistry.Slots = {} -- PlantingSystem จะเอา allSlots มาผูกกับตัวแปรนี้

-- หาช่องปลูกที่ "โตเต็มที่แล้ว" ของผู้เล่นคนนี้ ที่อยู่ใกล้ตำแหน่งที่กำหนดที่สุด (ภายในระยะ maxDistance)
-- skip (ไม่ใส่ก็ได้): function(slot) คืน true = ข้ามช่องนี้ (2026-11-17 Harvester ข้ามต้นที่สัตว์ตัวอื่นจองไว้)
function FarmSlotRegistry.FindNearestReadySlot(position, player, maxDistance, skip)
	local closestSlot, closestDistance = nil, maxDistance or math.huge

	for _, slot in ipairs(FarmSlotRegistry.Slots) do
		if slot.occupied and slot.stage == 5 and slot.plantedBy == player and not (skip and skip(slot)) then
			local distance = (slot.position - position).Magnitude
			if distance < closestDistance then
				closestSlot = slot
				closestDistance = distance
			end
		end
	end

	return closestSlot
end

-- หาช่องว่างใกล้สัตว์ โดยจำกัดวงรอบเจ้าของ; ช่องในรัศมีหุ่นของผู้เล่นอื่นก็เลือกได้
function FarmSlotRegistry.FindNearestEmptySlot(position, player, maxDistance, maxOwnerDistance)
	local character = player and player.Character
	local ownerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not ownerRoot then return nil end

	local closestSlot, closestDistance = nil, maxDistance or math.huge
	for _, slot in ipairs(FarmSlotRegistry.Slots) do
		if not slot.occupied then
			local distance = (slot.position - position).Magnitude
			local ownerDistance = (slot.position - ownerRoot.Position).Magnitude
			if ownerDistance <= (maxOwnerDistance or math.huge) and distance < closestDistance then
				closestSlot = slot
				closestDistance = distance
			end
		end
	end

	return closestSlot
end

-- หุ่นเพิ่มดวงที่ปักอยู่ตอนนี้ { position, radius } (เกณฑ์เดียวกับ isWithinQualityBooster ใน PlantingSystem)
local function getActiveBoosters(ownerUserId)
	local list = {}
	local folder = workspace:FindFirstChild("QualityBoosters")
	if not folder then return list end
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and (ownerUserId == nil or model:GetAttribute("OwnerUserId") == ownerUserId) then
			local ok, pivot = pcall(function() return model:GetPivot().Position end)
			if ok then
				table.insert(list, { position = pivot, radius = model:GetAttribute("BoostRadius") or 15, ownerUserId = model:GetAttribute("OwnerUserId") })
			end
		end
	end
	return list
end

local function inAnyBooster(position, boosters)
	for _, b in ipairs(boosters) do
		if (position - b.position).Magnitude <= b.radius then return true end
	end
	return false
end

-- ช่องปลูกนี้อยู่ในระยะหุ่นเพิ่มดวงไหม (ปลูกแล้วได้คุณภาพขั้นต่ำ 3 ดาว)
function FarmSlotRegistry.IsSlotBoosted(slot)
	return inAnyBooster(slot.position, getActiveBoosters())
end

-- หาช่องว่างในรัศมีหุ่นของเจ้าของที่ใกล้ position ที่สุด โดยช่องต้องห่าง ownerPos ไม่เกิน maxOwnerDistance
-- ไม่พบหุ่นของเจ้าของ หรือช่องรอบหุ่นเจ้าของเต็มแล้ว คืน nil (หุ่นคนอื่นไม่ใช้จัดลำดับเป้าสัตว์เลี้ยง)
function FarmSlotRegistry.FindNearestEmptyBoostedSlot(position, ownerPos, maxOwnerDistance, ownerUserId)
	local boosters = getActiveBoosters(ownerUserId)
	if #boosters == 0 then return nil end

	local closestSlot, closestDistance = nil, math.huge
	for _, slot in ipairs(FarmSlotRegistry.Slots) do
		if not slot.occupied then
			local slotPos = slot.position
			if (slotPos - ownerPos).Magnitude <= maxOwnerDistance and inAnyBooster(slotPos, boosters) then
				local distance = (slotPos - position).Magnitude
				if distance < closestDistance then
					closestSlot = slot
					closestDistance = distance
				end
			end
		end
	end
	return closestSlot
end

-- นับจำนวนต้นที่ผู้เล่นคนนี้กำลังปลูกอยู่
function FarmSlotRegistry.CountPlayerPlants(player)
	local count = 0
	for _, slot in ipairs(FarmSlotRegistry.Slots) do
		if slot.occupied and slot.plantedBy == player then
			count = count + 1
		end
	end
	return count
end

return FarmSlotRegistry