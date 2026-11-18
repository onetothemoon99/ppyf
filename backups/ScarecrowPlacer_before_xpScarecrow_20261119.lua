-- BACKUP of ServerScriptService.PetSystem.Abilities.ScarecrowPlacer before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into ServerScriptService.PetSystem.Abilities.ScarecrowPlacer.Source in Studio
-- bytes=6670 sum=3550592
-- Ability: ScarecrowPlacer (นักปักหุ่น) — ผีน้อยหยิบหุ่นดวงดีจากแถบช่องลัดของเจ้าของไปปักให้เอง
-- 2026-10-14 (ผู้ใช้ขอ): ใช้เฉพาะหุ่นที่อยู่ในแถบช่องลัด 6 ช่อง (หรือถืออยู่) ไม่หยิบหุ่นที่เก็บไว้ในกระเป๋า ตัดสินที่ BoosterPlacementSystem.findToolOfTier
-- 2026-10-12 (ผู้ใช้ขอ: ผีน้อยปักมั่ว): ปักเฉพาะจุดที่เจ้าของ "สั่ง" ไว้เท่านั้น (ปุ่ม 👻 สั่งปักหุ่น ใน StarterPlayerScripts.GhostPlaceGui)
--   จุดที่สั่งเก็บเป็น Attribute "GhostPlaceSpot" (Vector3) บนผู้เล่น (BoosterPlacementSystem ตรวจแล้วตั้งให้) ไม่มีจุด = ผีน้อยไม่ปักหุ่นเลย
-- เงื่อนไข: มีจุดที่สั่ง + เจ้าของอยู่ห่างจุดนั้นไม่เกิน MAX_OWNER_DISTANCE + มีหุ่นระดับนั้นในแถบช่องลัด + ยังไม่มีหุ่นระดับนั้นของเจ้าของปักอยู่
--   (หุ่นฟางกับหุ่นทองคำนับแยกกัน ตัวเก่าหมดเวลาเมื่อไหร่ก็ไปปักตัวใหม่ ตราบที่ยังมีในกระเป๋า)
-- ปักจริงทำใน ServerScriptService.BoosterPlacementSystem ผ่าน BindableFunction ServerStorage.PetBoosterPlace (หักหุ่น 1 ตัวเหมือนเจ้าของปักเอง)
-- ปิดความสามารถนี้บนการ์ดสัตว์เลี้ยง = ผีน้อยไม่หยิบหุ่นไปปัก (เก็บหุ่นทองคำไว้ปักเองได้)

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local ScarecrowPlacer = {}
ScarecrowPlacer.Id = "ScarecrowPlacer"
ScarecrowPlacer.DisplayName = "ช่วยปักหุ่น"

local CHECK_INTERVAL = 2    -- เช็กว่ามีหุ่นให้ปักไหมทุกกี่วินาที
local MAX_OWNER_DISTANCE = 90 -- เจ้าของอยู่ไกลจุดที่สั่งเกินนี้ = ผีน้อยไม่ไปปัก (กันบินข้ามแมพ/เปลืองหุ่นตอนเจ้าของไม่อยู่แถวนั้น)
local SECOND_TIER_OFFSET = 3  -- มีหุ่น 2 ระดับ: หุ่นฟางปักตรงจุดที่สั่ง หุ่นทองคำปักเยื้องออกไปเท่านี้ ไม่ทับกัน
local REACH_DISTANCE = 2.5
local TARGET_TIMEOUT = 20   -- ไปไม่ถึงจุดปักภายในนี้ = ทิ้งแล้วคิดใหม่

local TIER_NAME_KEY = { x50 = "Item_Booster", x100 = "Item_BoosterX100" }

local function notify(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local event = remotes and remotes:FindFirstChild("HarvestNotify")
	if event then event:FireClient(player, nil, nil, nil, text) end
end

function ScarecrowPlacer.Init(player, petModel)
	return { target = nil, tierId = nil, targetSince = 0, lastCheck = 0, side = 1 }
end

function ScarecrowPlacer.GetTarget(state, context)
	local player = context.player
	local placeFn = ServerStorage:FindFirstChild("PetBoosterPlace")
	if not placeFn then return nil end

	local now = os.clock()
	if state.target and now - state.targetSince > TARGET_TIMEOUT then
		state.target = nil
	end

	if not state.target and now - state.lastCheck >= CHECK_INTERVAL then
		state.lastCheck = now
		local hrp = context.charHRP
		local ordered = player:GetAttribute("GhostPlaceSpot") -- จุดที่เจ้าของสั่งไว้ (ไม่สั่ง = ไม่ปัก)
		if hrp and typeof(ordered) == "Vector3" and (hrp.Position - ordered).Magnitude <= MAX_OWNER_DISTANCE then
			local ok, tiers = pcall(function() return placeFn:Invoke(player, "query") end)
			if ok and type(tiers) == "table" and #tiers > 0 then
				-- หุ่นฟาง (x50) ปักตรงจุดที่สั่งพอดี ระดับอื่น (หุ่นทองคำ) เยื้องออกไปข้างๆ ไม่ให้ทับกัน
				local tierId = table.find(tiers, "x50") and "x50" or tiers[1]
				local spot = ordered
				if tierId ~= "x50" then spot = ordered + Vector3.new(SECOND_TIER_OFFSET, 0, 0) end
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { player.Character, workspace:FindFirstChild("QualityBoosters") }
				params.RespectCanCollide = true -- ข้ามสัตว์เลี้ยง/ต้นพืช/ของตกแต่งที่เดินทะลุได้ ให้จุดปักอยู่บนพื้นจริง
				local hit = workspace:Raycast(spot + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), params)
				if hit and hit.Material ~= Enum.Material.Water then
					state.target = hit.Position
					state.tierId = tierId
					state.targetSince = now
				end
			end
		end
	end

	if not state.target then return nil end

	local position, tierId = state.target, state.tierId
	return position, REACH_DISTANCE, function()
		if state.target == position then state.target = nil end
		local ok, placed = pcall(function() return placeFn:Invoke(player, "place", tierId, position) end)
		if ok and placed == true then
			local lang = Localization.GetLanguage(player)
			local itemName = Localization.T(TIER_NAME_KEY[tierId] or "Item_Booster", lang)
			notify(player, Localization.Pick(lang, "👻 ผีน้อยปัก" .. itemName .. "ให้แล้ว!", "👻 Little Ghost placed a " .. itemName .. " for you!"))
			return true -- ปักได้จริง (ใช้คิดความหิว)
		end
	end
end

return ScarecrowPlacer
