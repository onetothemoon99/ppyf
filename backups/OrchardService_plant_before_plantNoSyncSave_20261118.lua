-- BACKUP (section only) 2026-11-18
-- Studio path: game.ServerScriptService.Orchard.OrchardService
-- Parts of the planting code BEFORE "plantNoSyncSave" (plant no longer waits for a save slot; pose >= 1.1 s then ends).
-- Restore: put BLOCK 1 back in place of the new plantPoseDone (+ PLANT_POSE_MIN / plantStartAt lines),
--          remove the "plantStartAt[player] = os.clock()" line in plantFx,
--          and put BLOCK 2 back in actions.plant in place of the new "ใส่ต้นในหน่วยความจำ ... SaveLater" block
--          (from the "local ok = commit(player, st, function(d)" line down to "plantPoseDone(player)" before "if lessonGrow then -- 2026-11-18").

-- ===== BLOCK 1 =====
local PLANT_POSE_MAX = 8
local function plantPoseDone(player)
	plantToken[player] = (plantToken[player] or 0) + 1
	local char = player.Character
	if char then char:SetAttribute("OrchardPlantAt", nil) end
end

-- ===== BLOCK 2 (inside actions.plant) =====
	local ok = commit(player, st, function(d)
		d.trees[tostring(holeNo)] = OrchardData.NewTree(kind, OrchardData.Now())
		if lessonGrow then -- สูตรเดียวกับ applyInstantGrow (นิยามทีหลังในไฟล์ เรียกตรงนี้ไม่ได้)
			local t, now = d.trees[tostring(holeNo)], OrchardData.Now()
			t.plantedAt = math.min(t.plantedAt, now - def.GrowSeconds - def.FruitSeconds)
			t.cycleStart = now - def.FruitSeconds
			if (t.fruits or 0) <= 0 then t.fruits = def.FruitMin end
		end
		if claim then d.lot = lot.Name end -- ปลูกจองล็อกนี้ = จำไว้ (2026-11-06)
	end)
	if not ok then
		OrchardItems.Give(player, OrchardItems.SEED, kind, 1, lang(player)) -- เซฟสวนไม่ได้ = คืนเมล็ด
		if claim and not needsLot(player) then releaseLot(player) end
		plantPoseDone(player)
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	saveBag(player)
	render(player)
	plantPoseDone(player)
