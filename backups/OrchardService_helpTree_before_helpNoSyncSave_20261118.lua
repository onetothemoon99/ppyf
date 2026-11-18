-- BACKUP (section only) 2026-11-18
-- Studio path: game.ServerScriptService.Orchard.OrchardService
-- This is the helpTree() block (was lines 2191-2286) BEFORE "helpNoSyncSave" (watering no longer waits for a save of the owner).
-- Restore: in OrchardService, replace everything from "local HELP_QUEUE_WAIT = 20" down to the "end" of helpTree
--          (just above "-- ============ 💧 รดน้ำเอง") with the text below.

local HELP_QUEUE_WAIT = 20 -- วิ คนรดน้ำช่วยรอคิวเจ้าของเดียวกันได้นานสุด (2026-11-17 แบบเดียวกับขโมย)
local HELP_SAVE_WAIT = 20 -- วิ รอช่องเซฟเจ้าของ (เดิม 10)
local function helpTree(helper, lot, holeNo, prompt)
	local hh = helpHold[helper]
	helpHold[helper] = nil
	local owner = ownerOf[lot]
	if not owner or owner == helper or owner.Parent ~= Players then return end
	if not (hh and hh.prompt == prompt and os.clock() - hh.t >= Dead.HelpSeconds * helpHoldScale(helper) * 0.9) then return end
	local helperSt = OrchardData.Get(helper)
	if not (helperSt and helperSt.loaded) then
		return notify(helper, msg(helper, "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง", "Still loading, please try again"))
	end
	if not (trunkWaterOf(helper) or heldKit(helper, "Can")) then return warnKit(helper, "Can") end -- ขี่ช้างน้อยใจบุญ = พ่นน้ำจากงวงได้ ไม่ต้องถือบัว
	if LevelSystem.GetLevel(helper) < Dead.HelpMinLevel then
		return notify(helper, msg(helper, "ต้องเลเวล " .. Dead.HelpMinLevel .. " ขึ้นไปถึงจะช่วยรดน้ำต้นได้", "Requires level " .. Dead.HelpMinLevel .. " to help water trees"))
	end
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	local root = helper.Character and helper.Character:FindFirstChild("HumanoidRootPart")
	if not (hole and root) or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Dead.HelpRange + 3 then
		return notify(helper, msg(helper, "เดินไปที่ต้นก่อน", "Walk to the tree first"))
	end
	local ownerSt = stateOf(owner)
	local tree = ownerSt and ownerSt.loaded and ownerSt.data.trees[tostring(holeNo)]
	if not (tree and tree.dead and not tree.revived) then
		return notify(helper, msg(helper, "ต้นนี้ช่วยไม่ได้แล้ว", "This tree can't be helped anymore"))
	end
	local ownerKey = tostring(owner.UserId)
	local h = OrchardData.HelpToday(helperSt.data)
	local perOwner = Dead.HelpPerOwnerDaily or 1 -- ช่วยเจ้าของคนเดิมได้วันละกี่ครั้ง (3 ผู้ใช้สั่ง 2026-11-02)
	if (tonumber(h.owners[ownerKey]) or 0) >= perOwner and not isFake(owner) then -- เจ้าของปลอม (Studio) ช่วยซ้ำได้ ทดสอบหลายรอบ
		return notify(helper, msg(helper,
			string.format("💚 วันนี้ช่วยต้นของ %s ครบ %d ครั้งแล้ว พรุ่งนี้มาช่วยใหม่นะ", owner.DisplayName, perOwner),
			string.format("💚 You already helped %s %d times today, come back tomorrow", owner.DisplayName, perOwner)))
	end
	local key = lot.Name .. "#" .. holeNo
	if helpingKey[key] then return notify(helper, msg(helper, "ลองใหม่อีกครั้ง", "Please try again")) end -- ต้นเดียวกันกำลังถูกรดอยู่
	-- 2026-11-17 ผู้ใช้สั่ง (แบบเดียวกับขโมย): เจ้าของกำลังถูกเซฟ (คนอื่นรด/ขโมย/เจ้าของทำเอง) = รอคิวแทนตีกลับ แล้วตรวจซ้ำ
	if busy[owner] then
		notify(helper, msg(helper, "⏳ กำลังรดน้ำ...", "⏳ Watering..."))
		local t0 = os.clock()
		while busy[owner] and os.clock() - t0 < HELP_QUEUE_WAIT and helper.Parent and owner.Parent do task.wait(0.2) end
		if busy[owner] or not helper.Parent or owner.Parent ~= Players or ownerOf[lot] ~= owner or helpingKey[key] then
			return notify(helper, msg(helper, "ช่วยไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't help, please try again"))
		end
		local t = ownerSt.data.trees[tostring(holeNo)]
		if not (t and t.dead and not t.revived) then
			return notify(helper, msg(helper, "ต้นนี้ช่วยไม่ได้แล้ว", "This tree can't be helped anymore"))
		end
		local r = helper.Character and helper.Character:FindFirstChild("HumanoidRootPart")
		if not r or (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Dead.HelpRange + 3 then
			return notify(helper, msg(helper, "เดินไปที่ต้นก่อน", "Walk to the tree first"))
		end
		h = OrchardData.HelpToday(helperSt.data)
		if (tonumber(h.owners[ownerKey]) or 0) >= perOwner and not isFake(owner) then return end
	end
	helpingKey[key], busy[owner] = true, true
	local okCall, saved = pcall(commit, owner, ownerSt, function(d)
		local t = d.trees[tostring(holeNo)]
		if not (t and t.dead and not t.revived) then return false end
		OrchardData.StartNewCycle(t, OrchardData.Now())
		-- ฟื้นแล้วเก็บได้ RevivedHarvests รอบ (2026-11-07 ผู้ใช้สั่ง) ครบแล้วแห้ง revived = true รดซ้ำไม่ได้ ต้องตัด
		applyRevive(t)
	end, HELP_SAVE_WAIT)
	busy[owner], helpingKey[key] = nil, nil
	if not (okCall and saved) then
		if not okCall then warn("OrchardService: help error: " .. tostring(saved)) end
		return notify(helper, msg(helper, "ช่วยไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't help, please try again"))
	end
	-- (rest of the function — reward, render/sync, fx, notifies — was not changed by helpNoSyncSave)
