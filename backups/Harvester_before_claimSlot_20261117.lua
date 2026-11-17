-- Backup 2026-11-17 before claimSlot (partial: the 2 changed pieces; Harvester full source is 79 lines, shown below in full)
-- Restore:
--   game.ServerScriptService.PetSystem.Abilities.Harvester (ModuleScript): replace the whole Source with section A.
--   game.ServerScriptService.FarmSlotRegistry (ModuleScript): replace FindNearestReadySlot with section B.

-- ===== A) Harvester (full) =====
-- Ability: Harvester — วิ่งไปเก็บเกี่ยวผลผลิตที่โตเต็มที่ให้อัตโนมัติ
local ServerScriptService = game:GetService("ServerScriptService")
local FarmSlotRegistry = require(ServerScriptService:WaitForChild("FarmSlotRegistry"))
local PetWorkEffects = require(script.Parent.Parent:WaitForChild("PetWorkEffects"))

local Harvester = {}
Harvester.Id = "Harvester"
Harvester.DisplayName = "ช่วยเก็บเกี่ยว"

local SEARCH_RADIUS = 40        -- หาต้นที่พร้อมเก็บในรัศมีนี้ "รอบตัวสัตว์เลี้ยง" (เดิมรอบตัวผู้เล่น ผู้เล่นเดินออกก็เลิกทำงาน)
local MAX_OWNER_DISTANCE = 90   -- ไม่ไปเก็บไกลจากเจ้าของเกินนี้ กันสัตว์เลี้ยงหลงไปไกล
local REACH_DISTANCE = 1.5  -- ต้องเดินไปยืนชิดต้นก่อนถึงจะเก็บได้ (เดิม 3 + เผื่อ 0.4 เก็บจากห่างเกือบ 3.5 studs)
local HARVEST_TIME = 1.0    -- วินาทีที่สัตว์ก้มจิกเก็บ (สำรอง) ปกติใช้ HoldDuration ของป้าย E เก็บเกี่ยว ให้เท่าผู้เล่นกดเก็บเอง
local SEARCH_INTERVAL = 0.5     -- ค้นหาใหม่ทุกครึ่งวินาที (เดิม 1 วินาที)
local STASH_TIME = 0.7          -- เก็บเสร็จแล้ว ผลผลิตลอยเข้ากระเป๋า (สัตว์ยืนรอเก็บให้เสร็จก่อนไปต้นถัดไป)

-- จังหวะหลังเก็บ: ผลผลิตย่อส่วนลอยโค้งจากต้นเข้าไปเก็บที่ตัวสัตว์ (PetController เป็นคนเรียก)
local EXTRAS = {
	postTime = STASH_TIME,
	-- สัตว์ที่มี Attribute MagicHarvest (จริงใจ 2026-10-29): บอกผู้เล่นทุกคนให้วาดวงเวทรอบต้น (ตำแหน่ง ; เวลาเซิร์ฟเวอร์ตอนเริ่ม ; ความยาว) วาดใน JingjaiFx
	onWork = function(ctx, pet, duration, spot)
		if pet:GetAttribute("MagicHarvest") and spot then
			pet:SetAttribute("MagicRune", string.format("%.2f,%.2f,%.2f;%.3f;%.3f", spot.X, spot.Y, spot.Z, workspace:GetServerTimeNow(), duration))
		end
	end,
	onPost = function(ctx, pet)
		PetWorkEffects.StashProduce(pet, ctx.cropType, ctx.fromPos, STASH_TIME)
		-- ผสมเกสรสำเร็จ (ผึ้งราชินี): บอกผู้เล่นทุกคนให้เด้งหยดน้ำผึ้ง "+1" ตรงต้น (ตำแหน่ง ; เวลาเซิร์ฟเวอร์) วาดใน QueenBeeFx
		if ctx.pollinated and ctx.fromPos then
			pet:SetAttribute("PollinateFx", string.format("%.2f,%.2f,%.2f;%.3f", ctx.fromPos.X, ctx.fromPos.Y, ctx.fromPos.Z, workspace:GetServerTimeNow()))
		end
	end,
}

function Harvester.Init(player, petModel)
	return { target = nil, lastSearchTime = 0 }
end

-- คืนค่า (ตำแหน่งเป้าหมาย, ระยะที่ถือว่าถึงแล้ว, ฟังก์ชันที่เรียกตอนถึง) หรือ nil ถ้าไม่มีอะไรให้ทำ
function Harvester.GetTarget(state, context)
	local player = context.player

	if state.target and not (state.target.occupied and state.target.stage == 5 and state.target.plantedBy == player) then
		state.target = nil
	end

	if not state.target and (tick() - state.lastSearchTime) >= SEARCH_INTERVAL then
		state.lastSearchTime = tick()
		local slot = FarmSlotRegistry.FindNearestReadySlot(context.petPivot.Position, player, SEARCH_RADIUS)
		if slot and (slot.position - context.charHRP.Position).Magnitude <= MAX_OWNER_DISTANCE then
			state.target = slot
		end
	end

	if not state.target then return nil end

	local slot = state.target
	-- สัตว์บางตัวเก็บได้ผลผลิตมากกว่าปกติ (HarvestMultiplier ใน PetDefinitions เช่น จิ้งจอกเก้าหาง = 2)
	local multiplier = (context.definition and context.definition.HarvestMultiplier) or 1
	-- ผึ้งราชินี (2026-10-29): PollinateChance = โอกาสผสมเกสร ได้ผลผลิตแถม 1 ชิ้น (สุ่มตอนเก็บจริง)
	local pollinateChance = (context.definition and context.definition.PollinateChance) or 0
	return slot.position, REACH_DISTANCE, function(ctx)
		if state.target == slot then state.target = nil end
		if slot.occupied and slot.stage == 5 and slot.plantedBy == player then
			-- จำชนิดพืช/ตำแหน่งไว้ก่อน (เก็บแล้วช่องจะว่าง) ไว้ทำเอฟเฟกต์เก็บเข้ากระเป๋า
			if ctx then
				ctx.cropType = slot.cropType
				ctx.fromPos = slot.position
			end
			local pollinated = pollinateChance > 0 and math.random() < pollinateChance
			if ctx then ctx.pollinated = pollinated end
			slot.harvest(player, multiplier, nil, pollinated and 1 or nil)
			return true -- เก็บได้จริง (ใช้คิดความหิว)
		end
		return false
	end, (slot.prompt and slot.prompt.HoldDuration > 0 and slot.prompt.HoldDuration) or HARVEST_TIME, EXTRAS
end

return Harvester

-- ===== B) FarmSlotRegistry.FindNearestReadySlot (lines 5-19) =====
--[[
function FarmSlotRegistry.FindNearestReadySlot(position, player, maxDistance)
	local closestSlot, closestDistance = nil, maxDistance or math.huge

	for _, slot in ipairs(FarmSlotRegistry.Slots) do
		if slot.occupied and slot.stage == 5 and slot.plantedBy == player then
			local distance = (slot.position - position).Magnitude
			if distance < closestDistance then
				closestSlot = slot
				closestDistance = distance
			end
		end
	end

	return closestSlot
end
]]
