-- Section backup, 2026-11-18, before "instantHarvest" (plan A: harvest applies in memory + SaveLater, fruit can't be sold until the orchard save that includes it succeeds).
-- Restore: in Studio replace each current section with the matching block below.
--   ServerScriptService.Orchard.OrchardService  actions.harvest (was L911-974) and the steal give lines (was L2648-2653)
--   ServerScriptService.Orchard.OrchardData     OrchardData.Save + CanWriteNow (was L209-239)
--   ServerScriptService.ShopSystem              orchard fruit sell branch (was L670-689)

-- ===== OrchardService actions.harvest (L911-974)
function actions.harvest(player, st, holeNo)
	local lot = lotOf[player]
	local hole = lot and lot:FindFirstChild("Hole" .. tostring(holeNo))
	local tr = st.data.trees[tostring(holeNo)]
	if not (hole and tr) then return reply(player, false, "?") end
	if not nearHole(player, hole) then return reply(player, false, msg(player, "เดินไปที่ต้นก่อน", "Walk to the tree first")) end
	-- 2026-11-06 ผู้ใช้สั่ง: มีคนกำลังขโมยต้นนี้อยู่ = เจ้าของเก็บไม่ได้ ต้องตบก่อน · ถูกขโมยหมดแล้ว (fruits = 0) ก็เก็บไม่ได้ ต้นเริ่มรอบใหม่เองใน render
	for _, at in pairs(attempts) do
		if at.lot == lot and tostring(at.holeNo) == tostring(holeNo) then
			return reply(player, false, msg(player, "🚨 มีคนกำลังขโมยต้นนี้อยู่! กด \"ตบ\" ที่ตัวคนขโมยก่อน", "🚨 Someone is stealing from this tree! Slap them first"))
		end
	end
	if tr.fruits <= 0 then
		return reply(player, false, msg(player, "😭 ผลรอบนี้โดนขโมยไปแล้ว", "😭 This round's fruit was stolen"))
	end
	if Config.StageAt(tr, OrchardData.Now()) ~= "Ripe" then
		return reply(player, false, msg(player, "ผลยังไม่สุก", "The fruit is not ripe yet"))
	end
	local kind = tr.kind
	local got, left, revived = 0, nil, tr.revived == true
	-- เก็บได้ Trees[kind].Harvests รอบต่อต้น (ผู้ใช้สั่ง 2026-10-27) รอบสุดท้าย = ต้นแห้ง (2026-11-02 เดิมต้นหาย) ตัดทิ้ง / เพื่อนช่วยฟื้น
	local ok = commit(player, st, function(d)
		local t = d.trees[tostring(holeNo)]
		got = OrchardData.StartNewCycle(t, OrchardData.Now())
		t.harvests = (t.harvests or 0) + 1
		t.lesson = nil -- v3 2026-11-18 เลิกทำให้ต้นบทเรียนแห้งหลังเก็บ (ต้นที่เคยติดป้ายไว้ = ล้างป้าย กลายเป็นต้นปกติ)
		left = Config.HarvestsLeft(t)
		if left == 0 then t.dead = true end
		d.stats.harvested += got
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	OrchardItems.Give(player, OrchardItems.FRUIT, kind, got, lang(player))
	saveBag(player)
	render(player)
	-- (rest of the function, from "-- ต้นโยกเยกตอนดึงผลออก" to "return res", was not changed)

-- ===== OrchardService steal give lines (L2648-2653)
	-- 2026-11-18 (instantStealHelp): จากตรงนี้ไม่มี yield · หักตะกร้อ → หักผลเจ้าของในหน่วยความจำ → ให้ผล · เซฟเจ้าของตามหลัง
	if not OrchardItems.TakeHand(thief, 1, lang(thief), tier) then return end
	stealing[key] = true
	applySteal(ownerSt, holeNo, kind)
	if not isFake(owner) then OrchardData.SaveLater(owner) end
	OrchardItems.Give(thief, OrchardItems.FRUIT, kind, 1, lang(thief))

-- ===== OrchardData L209-239
function OrchardData.Save(player)
	local st = states[player]
	if not (st and st.loaded) then return false end
	if RunService:IsStudio() and workspace:GetAttribute("DevOrchardFailSave") == true then
		warn("OrchardData: จำลองเซฟไม่สำเร็จ (DevOrchardFailSave)")
		return false
	end
	local data = st.data
	st.saving = true
	st.lastWriteAt = os.clock()
	st.dirty = false
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function()
			return data
		end)
	end)
	st.saving = false
	if ok then
		st.lastSave = os.clock()
	else
		st.dirty = true
		warn("OrchardData: เซฟไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function OrchardData.CanWriteNow(player)
	local st = states[player]
	if not st or st.saving then return false end
	return not st.lastWriteAt or os.clock() - st.lastWriteAt >= SAVE_GAP
end

-- ===== ShopSystem L670-689
	-- ผลไม้สวน: ราคาตายตัว (ไม่คิดโบนัสขาย) กองติดดาวไม่ขาย
	local fruitKind = type(cropType) == "string" and cropType:match("^Orchard_(.+)$")
	if fruitKind and OrchardConfig.Enabled and OrchardConfig.Trees[fruitKind] and inOrchardShop(player) then -- ปิดระบบสวน = ขายไม่ได้ · ขายได้เฉพาะร้านผลไม้
		local def = OrchardConfig.Trees[fruitKind]
		local tool = OrchardItems.Find(player, OrchardItems.FRUIT, fruitKind, true)
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("เหรียญ")
		if not (tool and coins) then return end
		local have = math.floor(tonumber(tool:GetAttribute("Count")) or 0)
		if have <= 0 then return end
		local qty = math.clamp(math.floor(tonumber(quantity) or have), 1, have)
		local lang = Localization.GetLanguage(player)
		if not OrchardItems.Take(player, OrchardItems.FRUIT, fruitKind, qty, lang, true) then return end
		local earned = def.FruitPrice * qty
		CheatWatch.AllowCoinGain(player, earned) -- ผลละหลักล้าน ไม่ใช่เหรียญขึ้นเร็วผิดปกติ
		coins.Value += earned
		saveBagAndCoins(player)
		print(player.Name .. " ขายผลไม้สวน " .. fruitKind .. " x" .. qty .. " ได้ " .. earned .. " เหรียญ")
		sendShopData(player)
		return
	end
