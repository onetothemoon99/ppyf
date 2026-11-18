-- BACKUP (section only) 2026-11-18
-- Studio path: game.ServerScriptService.Orchard.OrchardService
-- Part of steal() BEFORE "stealBatch" (thieves of one owner share one save).
-- Restore:
--   1) Replace the two constant lines + the new "runStealBatch" block (everything from the "-- 2026-11-18 ... stealBatch" comment
--      down to just above "local function steal(") with BLOCK 1 below.
--   2) Inside steal(), replace everything from "-- 2026-11-17 ผู้ใช้แจ้ง: ขโมยพร้อมกัน 2 คน" (or the new 2026-11-18 batch comment)
--      down to (and including) the "if not (okCall and saved) then ... end" failure block with BLOCK 2 below.
--   The rest of steal() (TakeHand / Give / notifies) was not changed.

-- ===== BLOCK 1 =====
local STEAL_QUEUE_WAIT = 20 -- วิ คนขโมยรอคิวเจ้าของเดียวกันได้นานสุด (2026-11-17)
local STEAL_SAVE_WAIT = 20 -- วิ รอช่องเซฟเจ้าของ (เดิม 10 เท่ากับ commit ทั่วไป)

-- ===== BLOCK 2 =====
	-- 2026-11-17 ผู้ใช้แจ้ง: ขโมยพร้อมกัน 2 คน คนละต้น แปลงเดียวกัน = คนที่สอง "ขโมยไม่สำเร็จ"
	--   เจ้าของเดียวกันเซฟได้ทุก 6.5 วิ (OrchardData SAVE_GAP) เดิมเจอ busy[owner] = ตีกลับทันที → ต่อคิวรอ (ไม่เกิน STEAL_QUEUE_WAIT) แล้วตรวจเงื่อนไขซ้ำ
	if busy[owner] then
		notify0(thief, msg(thief, "⏳ กำลังเก็บผล...", "⏳ Picking the fruit...")) -- notify0 = ท่าสอยยังค้างระหว่างรอ
		local t0 = os.clock()
		while busy[owner] and os.clock() - t0 < STEAL_QUEUE_WAIT and thief.Parent and owner.Parent do task.wait(0.2) end
		if busy[owner] or not thief.Parent then
			return notify(thief, msg(thief, "ขโมยไม่สำเร็จ ลองใหม่อีกครั้ง", "Steal failed, please try again"))
		end
		-- ระหว่างรออะไรเปลี่ยนได้: ตรวจซ้ำก่อนให้ของ
		if owner.Parent ~= Players or ownerOf[lot] ~= owner or stealing[key] then
			return notify(thief, msg(thief, "ขโมยไม่สำเร็จ ลองใหม่อีกครั้ง", "Steal failed, please try again"))
		end
		local tr = ownerSt.data.trees[tostring(holeNo)]
		if not (tr and tr.kind == kind and canBeStolen(tr, OrchardData.Now())) then
			return notify(thief, msg(thief, "ต้นนี้ขโมยไม่ได้แล้ว", "This tree can't be stolen from now"))
		end
		if cooling(hole) then
			return notify(thief, msg(thief, "👋 ต้นนี้เจ้าของเพิ่งจับขโมยได้ พักอีกสักพัก", "👋 The owner just caught a thief at this tree, try later"))
		end
		held, tier = OrchardItems.HeldHand(thief)
		if not held then
			return notify(thief, msg(thief, Steal.HandIcon .. " ถือ" .. Steal.HandNameTh .. "ก่อน", Steal.HandIcon .. " Hold a " .. Steal.HandNameEn:lower() .. " first"))
		end
		local r = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
		if not r or (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Steal.Range + 3 then
			return notify(thief, msg(thief, "เดินไปใต้ต้นก่อน", "Stand under the tree first"))
		end
	end
	stealing[key], busy[owner] = true, true
	local okCall, saved = pcall(commit, owner, ownerSt, function(d)
		local tr = d.trees[tostring(holeNo)]
		if not (tr and tr.kind == kind and canBeStolen(tr, OrchardData.Now())) then return false end
		tr.fruits -= 1
		tr.stolen = (tr.stolen or 0) + 1
		d.stats.stolenFrom += 1
	end, STEAL_SAVE_WAIT)
	busy[owner] = nil
	if not (okCall and saved) then
		stealing[key] = nil
		if not okCall then warn("OrchardService: steal error: " .. tostring(saved)) end
		return notify(thief, msg(thief, "ขโมยไม่สำเร็จ ลองใหม่อีกครั้ง", "Steal failed, please try again"))
	end
