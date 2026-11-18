-- Backup (changed sections only) before "mango lesson: instant-grow + harvest + sell steps", 2026-11-18
-- Restore: put each section below back in Studio (search the new code by "2026-11-18" to find what to remove).

-- [1] game.ServerScriptService.LessonService
--   normalize(d) orchard lines were:
	d.orchard.stole = d.orchard.stole == true or nil
	d.orchard.watered = d.orchard.watered == true or nil
--   save() merge orchard lines were:
			if snapshot.orchard.stole then old.orchard.stole = true end
			if snapshot.orchard.watered then old.orchard.watered = true end
--   orchardQuest.OnInvoke "status" / "mark" were:
	if action == "status" then
		if not (st and st.loaded) then return { loaded = false } end
		return { loaded = true, inQuest = orchardActive[player] == true and orchardTodo(st) == true, todo = orchardTodo(st) == true,
			stole = st.data.orchard.stole == true, watered = st.data.orchard.watered == true }
	end
	if action == "mark" then -- what = "stole" / "watered" · เซฟให้สำเร็จก่อนคืน true (ผู้เรียกค่อยให้ของ)
		if not orchardTodo(st) or (what ~= "stole" and what ~= "watered") then return false end

-- [2] game.ServerScriptService.Orchard.OrchardService, actions.plant: no lesson-grow block. The commit and reply were:
	local ok = commit(player, st, function(d)
		d.trees[tostring(holeNo)] = OrchardData.NewTree(kind, OrchardData.Now())
		if claim then d.lot = lot.Name end -- ปลูกจองล็อกนี้ = จำไว้ (2026-11-06)
	end)
	-- ...
	return reply(player, true, msg(player,
		string.format("%s ปลูก%sที่ล็อก %s หลุม %d แล้ว! ต้นโตต่อแม้ออกจากเกม", def.Icon, def.NameTh, lotNo(lot), holeNo),
		string.format("%s Planted %s in lot %s hole %d! It keeps growing while you are offline", def.Icon, def.NameEn, lotNo(lot), holeNo)))
--   (no lessonQuestFn helper above actions.plant)

-- [3] game.StarterPlayer.StarterPlayerScripts.ShopGui renderSellTab, after createItemRow:
		if actionButton and not item.Seed then actionButton:SetAttribute("GuideSellCrop", index) end
--   (no GuideItem line on sell rows)

-- [4] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide
--   ORCHARD_STEPS had 4 steps: oSeed, oPlant, oHand, oUncle (no oHarvest / oSell between oPlant and oHand).
--   enterStep orch line was:
		orch = { seeds = orchardMangoSeeds(), hands = orchardHands(), trees = orchardMyTrees(), pingAt = 0 }
--   checkOrchardStep had no oHarvest / oSell branches; no isMangoFruit / orchardMangoFruits / orchardRipeHole helpers.
--   findHintTarget orchard shop block started:
	if shopHint == "orchardSeed" or shopHint == "orchardHand" then
		if not (main and main.Visible and main:GetAttribute("ShopKind") == "orchard") then return nil end
		if main:GetAttribute("ActiveTab") ~= "buy" then return main:FindFirstChild("BuyTab", true), tr("👆 กดแท็บซื้อ", "👆 Tap the Buy tab") end
--   Full older source: backups/NewPlayerGuide_before_mangoPlantHint_20261117.lua

-- [5] game.ReplicatedStorage.LessonContent, lesson id "orchard" text was:
		thLines = "1. ไปสวนมะม่วง ซื้อเมล็ดมะม่วงที่ร้านผลไม้\n2. ถือเมล็ด แล้วกด E ปลูกที่หลุมว่าง\n3. ซื้อตะกร้อขโมยที่ร้านผลไม้\n4. ขโมยมะม่วงลุงมะนาว แล้วรดน้ำต้นแห้งให้ลุง",
		enLines = "1. Go to the mango orchard and buy a mango seed at the fruit shop\n2. Hold the seed and press E at an empty hole to plant\n3. Buy a fruit picker at the fruit shop\n4. Steal a mango from Uncle Manao, then water his dry tree",
		hubTh = "ซื้อเมล็ด ปลูก ซื้อตะกร้อ ขโมยและรดน้ำที่ลุงมะนาว", hubEn = "Buy a seed, plant, buy a picker, steal and water at Uncle Manao",
