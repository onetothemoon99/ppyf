-- Backup (changed sections only) before "mango lesson v3: picker forced to slot 4, no warp on step 2, cut step removed,
-- lesson tree back to normal, Uncle watering needs the can in hand", 2026-11-18
-- Restore: put each section below back in Studio (search "v3 2026-11-18" to find the new code).

-- [1] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide
--   ORCHARD_STEPS oPlant + oCut entries were:
	{ id = "oPlant", warp = "orchard",
		th = "ถือเมล็ดมะม่วง แล้วกด E \"ปลูกต้นไม้\" ที่หลุมว่าง", en = "Hold the mango seed and press E \"Plant\" at an empty hole",
		markTh = "หลุมว่าง", markEn = "Empty hole" },
	-- (oHarvest unchanged)
	{ id = "oCut", warp = "orchard",
		th = "ต้นในบทเรียนแห้งแล้ว ไปที่ต้น กดค้าง E \"ตัดต้น\" ได้ท่อนไม้ไปทำปุ๋ย", en = "Your lesson tree has dried up. Go to it and hold E \"Cut down\" to get logs for fertilizer", -- kitslot 2026-11-18 ต้องถือขวานเอง (เลิกหยิบให้ 2026-11-07)
		markTh = "ต้นแห้งของคุณ", markEn = "Your dry tree" },
--   checkOrchardStep oCut branch (between oHarvest and oSell) was:
	elseif s.id == "oCut" then -- cut 2026-11-18
		if orchardWood() > orch.wood or orchardMyTrees() < orch.trees then return true end -- ได้ท่อนไม้ / ต้นหาย = ตัดแล้ว
		local pos, path = orchardFindTree("Dead")
		if not pos then
			if not orchLessonPlanted then return true end -- ไม่ได้ปลูกในบท + ไม่มีต้นแห้ง = ข้าม
			setCardText(tr("รอสักครู่ ต้นกำลังแห้ง…", "One moment, the tree is drying up…"))
			return false
		end
		-- kitslot 2026-11-18: ไม่ถือขวาน = ขวานลงช่อง 9 (ถ้ายังไม่อยู่แถบ) + ไฮไลต์ช่อง/ปุ่มเปลี่ยนหน้า (orchardHold "Axe") · ถือแล้ว = เหลือแต่ต้นเรืองแสง
		local heldTool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
		if heldTool and isAxe(heldTool) then
			shopHint, orchHold = nil, nil
		else
			orchardPlaceKit(isAxe)
			shopHint, orchHold = "orchardHold", "Axe"
		end
		targetPos = pos
		markText = tr(s.markTh, s.markEn)
		orchLandmark(path, tr("ต้นแห้ง · กดค้าง E ตัด", "Dry tree · hold E to cut"))
		setCardText(tr("ต้นในบทเรียนแห้งแล้ว! ", "Your lesson tree has dried up! ") .. slotText(isAxe, "ขวาน", "axe")
			.. tr("แล้วยืนใกล้ต้นแห้ง กดค้าง E \"ตัดต้น\" ได้ท่อนไม้ไปทำปุ๋ย", "then stand by the dry tree and hold E \"Cut down\" to get logs for fertilizer"))
		return false
--   oUncle steal phase had no orchardPlaceKit(isPicker) call after:
			shopHint, orchHold = "orchardHold", "Picker" -- ไฮไลต์ช่อง/กระเป๋าให้ถือตะกร้อ

-- [2] game.StarterPlayer.StarterPlayerScripts.HotbarState
--   AutoAssignNew GuideHandSlot block was:
	local guideHandSlot = localPlayer:GetAttribute("GuideHandSlot")
	if type(guideHandSlot) == "number" then
		for _, tool in ipairs(allTools) do
			if tool.Parent and tool:GetAttribute("IsStealHand") and not HotbarState.IsAssigned(tool) then
				local target = (not HotbarState.GetSlotTool(guideHandSlot) and HotbarState.CanPlaceInSlot(tool, guideHandSlot)) and guideHandSlot or firstFreeSlot(tool)
				if target then slots[target] = tool end
			end
		end
	end
--   PlaceGuideKit started:
	local home = NEW_PLAYER_HOME[HotbarState.ToolKey(tool)]
	if not home then return nil end
	local current = HotbarState.FindSlotOf(tool)
	if current then return current end

-- [3] game.ServerScriptService.Orchard.OrchardService
--   actions.plant lesson-grow block had:
		newTree.lesson = true -- cut 2026-11-18 เก็บรอบแรกแล้วแห้ง (actions.harvest) ให้บทเรียนสอนตัดต้น
--   actions.harvest had:
	local lessonDead = false -- cut 2026-11-18
	-- in commit, after t.harvests += 1:
		if t.lesson then -- cut 2026-11-18 ต้นบทเรียน: เก็บรอบแรกแล้วแห้งทันที (ปุ่ม "ตัดต้น" ขึ้นตามระบบเดิม)
			t.lesson = nil
			t.harvests = math.max(t.harvests, Config.Trees[t.kind].Harvests)
			lessonDead = true
		end
	-- after Give FRUIT:
	if lessonDead then pcall(OrchardItems.EnsureKit, player, lang(player)) end -- kitslot 2026-11-18 ต้นบทเรียนแห้ง = มีขวานแน่นอนก่อนขั้นตัด
	-- message block:
	if lessonDead then -- cut 2026-11-18
		extraTh = " · 🍂 ต้นในบทเรียนแห้งแล้ว กดค้าง \"ตัดต้น\" ได้ท่อนไม้"
		extraEn = " · 🍂 Your lesson tree has dried up. Hold \"Cut down\" to get logs"
	elseif left == 0 and revived then

-- [4] game.ServerScriptService.Orchard.UncleManao startPour began:
local function startPour(player)
	stopPour(player)
	local can = OrchardItems.EquipKit(player, "Can", langOf(player))
--   (and the HoldBegan handler called startPour(player) unconditionally after the inQuest/watered checks)

-- [5] game.ReplicatedStorage.LessonContent orchard text = 7-step version (with "4. ต้นแห้งแล้ว กดค้าง E ตัดต้น ได้ท่อนไม้").
