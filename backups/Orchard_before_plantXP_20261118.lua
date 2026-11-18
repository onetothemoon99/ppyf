-- Section backup, 2026-11-18, before "plantXP" (EXP when planting a fruit tree).
-- Restore: in Studio put these lines back in place of the current ones.
--   ReplicatedStorage.OrchardConfig  Trees.Mango L38 and Trees.Durian L51 (remove the ", PlantXP = ..." part)
--   ServerScriptService.Orchard.OrchardService  actions.plant L827-839 (the SaveLater line through the final reply)

-- ===== OrchardConfig L38 (Mango)
		FruitPrice = 100000, SeedPrice = 10000, -- ผู้ใช้ปรับ 2026-10-26 (เดิม ผล 1M / เมล็ด 500k)
-- ===== OrchardConfig L51 (Durian)
		FruitPrice = 2500000, SeedPrice = 2000000,

-- ===== OrchardService actions.plant L827-839
	if not isFake(player) then OrchardData.SaveLater(player) end
	saveBag(player)
	render(player)
	plantPoseDone(player)
	if lessonGrow then -- 2026-11-18
		print("🎓 Orchard lesson instant grow: " .. player.Name .. " hole " .. holeNo)
		return reply(player, true, msg(player,
			string.format("⚡ ปลูก%sแล้ว! ต้นในบทเรียนโตทันที ผลสุก เก็บได้เลย", def.NameTh),
			string.format("⚡ Planted %s! Your lesson tree grew instantly, the fruit is ripe, harvest it now", def.NameEn)))
	end
	return reply(player, true, msg(player,
		string.format("%s ปลูก%sที่ล็อก %s หลุม %d แล้ว! ต้นโตต่อแม้ออกจากเกม", def.Icon, def.NameTh, lotNo(lot), holeNo),
		string.format("%s Planted %s in lot %s hole %d! It keeps growing while you are offline", def.Icon, def.NameEn, lotNo(lot), holeNo)))
