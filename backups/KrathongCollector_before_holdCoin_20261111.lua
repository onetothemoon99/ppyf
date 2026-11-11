-- BACKUP 2026-11-11 of game.ServerScriptService.PetSystem.Abilities.KrathongCollector (ModuleScript, Studio) before "hold krathong 5 s then coins".
-- Restore: copy everything BELOW the "==== SOURCE ====" line into that script's Source in Studio.
-- ==== SOURCE ====
-- Ability: KrathongCollector (เก็บกระทง) — ตุ่นนักอนุรักษ์ (2026-11-06) ทุก 15 วิ ลงน้ำใกล้เจ้าของ เก็บกระทง แล้วได้เหรียญสุ่ม 100-1000 ให้เจ้าของ
-- ใช้น้ำจริงในระยะ WATER_RANGE จากเจ้าของเท่านั้น (ผู้ใช้เลือก) ไม่มีน้ำใกล้ = ไม่ได้เหรียญรอบนั้น · เลเวลไม่เร่งรอบ (15 วิเท่าเดิม)
-- เรตเหรียญ (ผู้ใช้กำหนด รวม 100%): 100-500 ค่าละ 16% · 600-1000 ค่าละ 4%
-- เอฟเฟกต์ฝั่งผู้เล่น: Attribute บนตัวสัตว์ KrathongWork / KrathongCoin -> StarterPlayerScripts.PlatypusFx

local KrathongCollector = {}
KrathongCollector.Id = "KrathongCollector"
KrathongCollector.DisplayName = "เก็บกระทง"

KrathongCollector.INTERVAL = 15 -- วินาทีต่อรอบ นับจากตอนเริ่มออกเดิน
local FIRST_DELAY = 5
local RETRY_NO_WATER = 5
local WATER_RANGE = 60
local RING_STEP = 8
local RING_POINTS = 12
local REACH_DISTANCE = 1.2
local TARGET_TIMEOUT = 12
local WORK_TIME = 1.6

KrathongCollector.Rewards = {
	{ coins = 100, chance = 16 }, { coins = 200, chance = 16 }, { coins = 300, chance = 16 }, { coins = 400, chance = 16 }, { coins = 500, chance = 16 },
	{ coins = 600, chance = 4 }, { coins = 700, chance = 4 }, { coins = 800, chance = 4 }, { coins = 900, chance = 4 }, { coins = 1000, chance = 4 },
}

local rng = Random.new()

function KrathongCollector.RollCoins(random)
	local roll = (random or rng):NextInteger(1, 100)
	for _, reward in ipairs(KrathongCollector.Rewards) do
		roll -= reward.chance
		if roll <= 0 then return reward.coins end
	end
	return KrathongCollector.Rewards[1].coins
end

-- หาน้ำใกล้เจ้าของที่สุด: ยิงลงทีละวง จากใกล้ไปไกล เจอผิวน้ำจุดแรก = ใช้ (ติดสะพาน/ท่าเรือ = เส้นนั้นไม่นับ)
local function findWater(player, petModel, origin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, petModel }
	params.RespectCanCollide = true
	local phase = rng:NextNumber(0, math.pi * 2)
	for radius = RING_STEP, WATER_RANGE, RING_STEP do
		for i = 1, RING_POINTS do
			local angle = phase + (i / RING_POINTS) * math.pi * 2
			local spot = origin + Vector3.new(math.cos(angle) * radius, 25, math.sin(angle) * radius)
			local hit = workspace:Raycast(spot, Vector3.new(0, -70, 0), params)
			if hit and hit.Material == Enum.Material.Water then return hit.Position end
		end
	end
	return nil
end

function KrathongCollector.Init(player, petModel)
	return { nextRun = os.clock() + FIRST_DELAY, target = nil, targetSince = 0 }
end

function KrathongCollector.GetTarget(state, context)
	local player = context.player
	local now = os.clock()
	if state.target and now - state.targetSince > TARGET_TIMEOUT then
		state.target = nil -- ไปไม่ถึง รอรอบถัดไป
	end
	if not state.target then
		if now < state.nextRun then return nil end
		local hrp = context.charHRP
		if not hrp then return nil end
		local water = findWater(player, context.petModel, hrp.Position)
		if not water then
			state.nextRun = now + RETRY_NO_WATER
			return nil
		end
		state.target = water
		state.targetSince = now
		state.nextRun = now + KrathongCollector.INTERVAL
	end
	local position = state.target
	local petModel = context.petModel
	return position, REACH_DISTANCE, function()
		if state.target ~= position then return end
		state.target = nil
		if player:GetAttribute("CoinsLoaded") ~= true then return end -- เพิ่มก่อนโหลด = โดนค่าที่โหลดมาทับ
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("เหรียญ")
		if not coins then return end
		local amount = KrathongCollector.RollCoins()
		coins.Value += amount
		petModel:SetAttribute("KrathongCoin", string.format("%d;%.3f", amount, workspace:GetServerTimeNow()))
		-- แจ้งเตือนมุมขวาบนแบบเก็บเกี่ยว (HarvestNotifyGui cropType "Coins" star 0)
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
		local notify = remotes and remotes:FindFirstChild("HarvestNotify")
		if notify then notify:FireClient(player, "Coins", 0, amount) end
		return true
	end, WORK_TIME, {
		onWork = function(_, _, duration, spot)
			local p = spot or position
			petModel:SetAttribute("KrathongWork", string.format("%.2f,%.2f,%.2f;%.3f;%.3f", p.X, p.Y, p.Z, workspace:GetServerTimeNow(), duration or WORK_TIME))
		end,
	}
end

return KrathongCollector
