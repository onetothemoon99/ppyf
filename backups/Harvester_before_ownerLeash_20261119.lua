-- Backup 2026-11-19 before ownerLeash (full Source, 110 lines)
-- Studio path: game.ServerScriptService.PetSystem.Abilities.Harvester (ModuleScript)
-- Restore: replace the whole Source of that ModuleScript with everything below this header.

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

-- จองต้น (2026-11-17 ผู้ใช้สั่ง): สัตว์เก็บเกี่ยว 2 ตัวเคยวิ่งไปต้นเดียวกัน (ต่างคนต่างหาต้นที่ใกล้ตัวเองที่สุด)
--   เลือกต้นแล้วจองไว้ ตัวอื่นข้ามต้นที่จองแล้ว · เก็บเสร็จ/เปลี่ยนเป้า/ต้นหาย = ปล่อยจอง
--   จองค้าง (ถอดสัตว์/เจ้าของออก) = ใช้ได้เฉพาะตอนสัตว์ตัวนั้นยังเล็งต้นนี้อยู่ และต่ออายุทุกครั้งที่ GetTarget ถูกเรียก ไม่ต่อเกิน CLAIM_TTL = หมดอายุ
local CLAIM_TTL = 5
local claims = setmetatable({}, { __mode = "k" }) -- [slot] = { state = state ของสัตว์ที่จอง, at = tick() }
Harvester._claims = claims -- ใช้ตอนทดสอบ

local function claimedByOther(slot, state)
	local c = claims[slot]
	if not c or c.state == state then return false end
	if c.state.target ~= slot or tick() - c.at > CLAIM_TTL then
		claims[slot] = nil
		return false
	end
	return true
end

local function claim(state, slot)
	claims[slot] = { state = state, at = tick() }
end

local function release(state, slot)
	local c = slot and claims[slot]
	if c and c.state == state then claims[slot] = nil end
end

function Harvester.Init(player, petModel)
	return { target = nil, lastSearchTime = 0 }
end

-- คืนค่า (ตำแหน่งเป้าหมาย, ระยะที่ถือว่าถึงแล้ว, ฟังก์ชันที่เรียกตอนถึง) หรือ nil ถ้าไม่มีอะไรให้ทำ
function Harvester.GetTarget(state, context)
	local player = context.player

	if state.target and (not (state.target.occupied and state.target.stage == 5 and state.target.plantedBy == player) or claimedByOther(state.target, state)) then
		release(state, state.target)
		state.target = nil
	end

	if not state.target and (tick() - state.lastSearchTime) >= SEARCH_INTERVAL then
		state.lastSearchTime = tick()
		local slot = FarmSlotRegistry.FindNearestReadySlot(context.petPivot.Position, player, SEARCH_RADIUS, function(s)
			return claimedByOther(s, state) -- ต้นที่สัตว์ตัวอื่นจองไว้ = ข้าม
		end)
		if slot and (slot.position - context.charHRP.Position).Magnitude <= MAX_OWNER_DISTANCE then
			state.target = slot
		end
	end

	if not state.target then return nil end

	local slot = state.target
	claim(state, slot) -- จอง/ต่ออายุทุกครั้งที่ยังเล็งต้นนี้
	-- สัตว์บางตัวเก็บได้ผลผลิตมากกว่าปกติ (HarvestMultiplier ใน PetDefinitions เช่น จิ้งจอกเก้าหาง = 2)
	local multiplier = (context.definition and context.definition.HarvestMultiplier) or 1
	-- ผึ้งราชินี (2026-10-29): PollinateChance = โอกาสผสมเกสร ได้ผลผลิตแถม 1 ชิ้น (สุ่มตอนเก็บจริง)
	local pollinateChance = (context.definition and context.definition.PollinateChance) or 0
	return slot.position, REACH_DISTANCE, function(ctx)
		if state.target == slot then state.target = nil end
		release(state, slot)
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
