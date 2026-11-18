-- Section backup of ServerScriptService.Orchard.OrchardService (Studio), 2026-11-18, before "instantStealHelp"
-- (plan A: steal applies in memory + SaveLater owner, commit replays outside edits after a failed save, helpTree no busy wait).
-- Script had 3740 lines. Sections below are the original lines L610-635 (commit), L2221-2330 (helpHoldScale + helpTree),
-- L2582-2753 (stealBatch + steal), L3030-3073 (dev command "stealbatch").
-- Restore: in Studio open OrchardService, replace each current section with the matching block below.

-- =====L610-635
-- เปลี่ยนข้อมูล -> เซฟจริงทันที (ต้นไม้ราคาหลักแสน-ล้าน) เซฟไม่ได้ = คืนค่าเดิม คืน true/false
local function commit(player, st, change, maxWait) -- maxWait = รอช่องเซฟได้นานสุดกี่วิ (ไม่ใส่ = 10, ขโมย = 20 คนต่อคิวกัน 2026-11-17)
	local before = table.clone(st.data)
	before.trees = {}
	for k, v in pairs(st.data.trees) do before.trees[k] = table.clone(v) end
	before.stats = table.clone(st.data.stats)
	before.skins = table.clone(st.data.skins or {})
	-- เหรียญช่วยเหลือ + ตู้แลกน้ำใจ (2026-11-03) เซฟไม่ได้ต้องคืนค่าเดิมครบ (ตารางซ้อนกัน)
	if st.data.help then
		before.help = table.clone(st.data.help)
		before.help.owners = table.clone(st.data.help.owners or {})
	end
	if st.data.shop then
		before.shop = table.clone(st.data.shop)
		before.shop.titles = table.clone(st.data.shop.titles or {})
		before.shop.buys = table.clone(st.data.shop.buys or {})
		before.shop.backs = table.clone(st.data.shop.backs or {})
	end
	if change(st.data) == false then return false end
	if isFake(player) then return true end -- เจ้าของปลอมไม่เซฟ
	if not OrchardData.SaveNow(player, maxWait or 10) then
		st.data = before
		return false
	end
	return true
end

-- =====L2221-2330
-- ขี่สัตว์ที่มี HelpHoldScale (ช้างน้อยใจบุญ 0.5, 2026-11-03) = รดน้ำช่วยใช้เวลาเท่านั้น (ฝั่งผู้เล่นตั้ง HoldDuration ตามกัน)
local function helpHoldScale(player)
	local riding = player:GetAttribute("RidingMount")
	if type(riding) ~= "string" or riding == "" then return 1 end
	local ok, MountConfig = pcall(function() return require(ReplicatedStorage:WaitForChild("MountConfig", 5)) end)
	local def = ok and MountConfig and MountConfig.Mounts[riding]
	return def and tonumber(def.HelpHoldScale) or 1
end

-- 2026-11-18 ผู้ใช้สั่ง (ช่วยกันรดคนละต้นในแปลงเดียว หลายคนรดไม่สำเร็จ): รดน้ำช่วยไม่เซฟเจ้าของทันทีแล้ว
--   เดิม 1 คนรด = เซฟเจ้าของทันที 1 ครั้ง (คีย์เดียวกันเซฟได้ทุก 6.5 วิ) คนที่ 3-4 รอคิวเกิน 20 วิ = "ช่วยไม่สำเร็จ"
--   ตอนนี้: ต้นฟื้นในหน่วยความจำทันที + OrchardData.SaveLater(เจ้าของ) รวมทุกคนเป็นเซฟเดียว · ไม่ถือ busy[เจ้าของ] แล้ว
--   ยังรอถ้าเจ้าของมีเซฟอื่นค้าง (busy = ขโมย/เก็บผล/เจ้าของกดเอง) เพราะเซฟนั้นล้มเหลว commit จะคืนข้อมูลทั้งก้อน ทับต้นที่เพิ่งฟื้น
--   ข้อแลก: เซิร์ฟล่มก่อนเซฟ (ไม่กี่วิ) = ต้นกลับแห้ง แต่คนช่วยได้ 💚 ไปแล้ว (ไม่มีเงิน/ของซ้ำ)
local HELP_BUSY_WAIT = 25 -- วิ รอเซฟอื่นของเจ้าของจบได้นานสุด (เซฟหนึ่งรอช่องได้ถึง 20 วิ)
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
	helpingKey[key] = true -- จองต้นนี้ไว้ระหว่างรอ กันคนอื่นรดต้นเดียวกันซ้อน (ปลดทุกทางออกด้านล่าง)
	local function fail(th, en)
		helpingKey[key] = nil
		return notify(helper, msg(helper, th, en))
	end
	if busy[owner] then
		notify(helper, msg(helper, "⏳ กำลังรดน้ำ...", "⏳ Watering..."))
		local t0 = os.clock()
		while busy[owner] and os.clock() - t0 < HELP_BUSY_WAIT and helper.Parent and owner.Parent do task.wait(0.2) end
		if busy[owner] or not helper.Parent or owner.Parent ~= Players or ownerOf[lot] ~= owner then
			return fail("ช่วยไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't help, please try again")
		end
		ownerSt = stateOf(owner)
		local r = helper.Character and helper.Character:FindFirstChild("HumanoidRootPart")
		if not r or (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Dead.HelpRange + 3 then
			return fail("เดินไปที่ต้นก่อน", "Walk to the tree first")
		end
		h = OrchardData.HelpToday(helperSt.data)
		if (tonumber(h.owners[ownerKey]) or 0) >= perOwner and not isFake(owner) then
			return fail("💚 วันนี้ช่วยต้นของเจ้าของคนนี้ครบแล้ว", "💚 You already helped this owner enough today")
		end
	end
	-- จากตรงนี้ไม่มี yield: ฟื้นต้นในหน่วยความจำ แล้วรวมเซฟเจ้าของทีหลัง
	local t = ownerSt and ownerSt.loaded and ownerSt.data.trees[tostring(holeNo)]
	if not (t and t.dead and not t.revived) then
		return fail("ต้นนี้ช่วยไม่ได้แล้ว", "This tree can't be helped anymore")
	end
	OrchardData.StartNewCycle(t, OrchardData.Now())
	-- ฟื้นแล้วเก็บได้ RevivedHarvests รอบ (2026-11-07 ผู้ใช้สั่ง) ครบแล้วแห้ง revived = true รดซ้ำไม่ได้ ต้องตัด
	applyRevive(t)
	tree = t
	helpingKey[key] = nil
	if not isFake(owner) then OrchardData.SaveLater(owner) end
	-- รางวัลคนช่วย (ต้นเจ้าของเซฟแล้ว เหรียญช่วยเหลือเซฟตามหลัง)
	h = OrchardData.HelpToday(helperSt.data)
	h.owners[ownerKey] = (tonumber(h.owners[ownerKey]) or 0) + 1
	h.total += 1
	local reward = h.today < Dead.HelpDailyCoins and Dead.HelpCoins or 0
	if reward > 0 then
		h.today += 1
		h.coins += reward
	end
	OrchardData.SaveLater(helper)
	setHelpCoinsAttr(helper)
	render(owner)
	sync(owner)
	sync(helper)
	reviveFx(hole)
	local def = Config.Trees[tree.kind]
	-- ช่วยรดน้ำสำเร็จ = ป้าย "+N 💚" มุมขวาบนแบบเก็บผลไม้ ไม่มีข้อความกลางจอ (ผู้ใช้สั่ง 2026-11-03) · ครบโควตาวันนี้ = ยังบอกเป็นข้อความ
	if reward > 0 then
		harvestNotify:FireClient(helper, "Orchard:HelpCoin", 0, reward)
	else notify(helper, msg(helper,
			string.format("💚 ช่วยรดน้ำ%sของ %s จนฟื้นแล้ว! (วันนี้ได้เหรียญช่วยเหลือครบ %d ครั้งแล้ว)", def.NameTh, owner.DisplayName, Dead.HelpDailyCoins),
			string.format("💚 You revived %s's %s! (daily help coin limit of %d reached)", owner.DisplayName, def.NameEn, Dead.HelpDailyCoins)))
	end
	notify(owner, msg(owner,
		string.format("💚 %s ช่วยรดน้ำ%sของคุณ ต้นฟื้นแล้ว! เก็บได้อีก %d รอบ (ล็อก %s หลุม %d)", helper.DisplayName, def.NameTh, Dead.RevivedHarvests, lotNo(lot), holeNo),
		string.format("💚 %s watered your %s, it's alive again! %d more harvest(s) (lot %s hole %d)", helper.DisplayName, def.NameEn, Dead.RevivedHarvests, lotNo(lot), holeNo)))
	print(string.format("Orchard: %s ช่วยต้น %s ของ %s (%s หลุม %d) เหรียญช่วยเหลือ +%d", helper.Name, tree.kind, owner.Name, lot.Name, holeNo, reward))
end

-- =====L2582-2753
-- 2026-11-18 ผู้ใช้สั่ง (stealBatch): โจรหลายคนขโมยคนละต้นของเจ้าของเดียวกัน = รวมเป็นชุด เซฟเจ้าของครั้งเดียว
--   เดิม 1 คน = 1 เซฟ (คีย์เดียวกันทุก 6.5 วิ) คนที่ 3-4 รอคิวเกิน 20 วิ = "ขโมยไม่สำเร็จ"
--   ยังเซฟเจ้าของ (ผล -1) ก่อนให้ผลเข้ากระเป๋าโจรเหมือนเดิม (กันเสกผลไม้ตอนเซิร์ฟล่ม) · คนที่มาระหว่างเซฟ = ชุดถัดไป
--   stealBatch[owner] = { queue = { {holeNo, kind, applied, ok, done} }, running } · runStealBatch ถือ busy[owner] เฉพาะตอนเซฟชุด
local STEAL_BATCH_WAIT = 25 -- วิ รอเซฟอื่นของเจ้าของ (เจ้าของกดเอง/รดน้ำเอง) จบได้นานสุด
local STEAL_SAVE_WAIT = 20 -- วิ รอช่องเซฟเจ้าของ (เดิม 10 เท่ากับ commit ทั่วไป)
local stealBatch = {} -- [owner] = { queue = {}, running = bool }

local function runStealBatch(owner)
	local b = stealBatch[owner]
	while b and b.queue[1] do
		local t0 = os.clock()
		while busy[owner] and os.clock() - t0 < STEAL_BATCH_WAIT and owner.Parent do task.wait(0.2) end
		local items = b.queue
		b.queue = {}
		if busy[owner] or owner.Parent ~= Players then
			for _, it in ipairs(items) do it.ok, it.done = false, true end
		else
			busy[owner] = true
			local st = stateOf(owner)
			local okCall, saved = false, "no state"
			if st and st.loaded then
				okCall, saved = pcall(commit, owner, st, function(d)
					local any = false
					local now = OrchardData.Now()
					for _, it in ipairs(items) do
						local tr = d.trees[tostring(it.holeNo)]
						if tr and tr.kind == it.kind and canBeStolen(tr, now) then
							tr.fruits -= 1
							tr.stolen = (tr.stolen or 0) + 1
							d.stats.stolenFrom += 1
							it.applied = true
							any = true
						end
					end
					if not any then return false end
				end, STEAL_SAVE_WAIT)
			end
			busy[owner] = nil
			if not okCall then warn("OrchardService: steal batch error: " .. tostring(saved)) end
			for _, it in ipairs(items) do
				it.ok = (okCall and saved and it.applied) and true or false
				it.done = true
			end
			print(string.format("Orchard: steal batch %s x%d saved=%s", owner.Name, #items, tostring(okCall and saved)))
		end
	end
end

-- ใส่คำขอเข้าชุดของเจ้าของ แล้วรอผล (yield) คืน item { ok, applied }
local function joinStealBatch(owner, holeNo, kind)
	local b = stealBatch[owner]
	if not b then
		b = { queue = {}, running = false }
		stealBatch[owner] = b
	end
	local item = { holeNo = holeNo, kind = kind }
	table.insert(b.queue, item)
	if not b.running then
		b.running = true
		task.spawn(function()
			local ok, err = pcall(runStealBatch, owner)
			if not ok then warn("OrchardService: steal batch crashed: " .. tostring(err)) end
			for _, it in ipairs(b.queue) do it.ok, it.done = false, true end -- พังกลางทาง = ทุกคนที่ค้างได้ "ไม่สำเร็จ"
			b.queue = {}
			b.running = false
			if stealBatch[owner] == b then stealBatch[owner] = nil end
		end)
	end
	while not item.done do task.wait(0.1) end
	return item
end
local function steal(thief, lot, holeNo, prompt, myPick)
	local hs = holdStart[thief]
	holdStart[thief] = nil
	endAttempt(thief, "done", true) -- ท่าค้างจนแจ้งผล (2026-11-16)
	-- ลบท่าก่อนทุกข้อความใน steal (ขโมยไม่ได้/เซฟไม่ได้) · ทางสำเร็จลบก่อนป้าย +1 · ทางเงียบ = Triggered ลบหลัง steal จบ
	local notify0 = notify
	local function notify(p, text)
		pickPoseDone(thief, myPick)
		return notify0(p, text)
	end
	local owner = ownerOf[lot]
	-- Studio: workspace DevOrchardSelfSteal = true ให้ขโมยต้นตัวเองได้ (ทดสอบคนเดียว)
	if not owner or (owner == thief and not selfStealTest()) or owner.Parent ~= Players then return end
	local ownerSt = stateOf(owner)
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	local tree = ownerSt and ownerSt.loaded and ownerSt.data.trees[tostring(holeNo)]
	if not (tree and hole) then return end
	local kind = tree.kind
	local def = Config.Trees[kind]
	local held, tier = OrchardItems.HeldHand(thief)
	local need = Config.StealSeconds(kind, held and tier or nil) -- ตะกร้อจอมโจร = ไวกว่า (2026-11-02)
	if not (hs and hs.prompt == prompt and os.clock() - hs.t >= need * 0.9) then return end
	if LevelSystem.GetLevel(thief) < Steal.MinLevel then
		return notify(thief, msg(thief, "ต้องเลเวล " .. Steal.MinLevel .. " ขึ้นไปถึงจะขโมยได้", "Requires level " .. Steal.MinLevel .. " to steal"))
	end
	if not isFake(owner) and LevelSystem.GetLevel(owner) < Steal.MinLevel then
		return notify(thief, msg(thief, "เจ้าของต้นนี้เลเวลยังไม่ถึง " .. Steal.MinLevel .. " ขโมยไม่ได้", "This tree's owner is below level " .. Steal.MinLevel .. ", can't steal"))
	end
	if thief:GetAttribute("InventoryLoaded") == false then return end
	if not held then
		return notify(thief, msg(thief, Steal.HandIcon .. " ถือ" .. Steal.HandNameTh .. "ก่อน (ซื้อได้ที่ร้านผลไม้ & อุปกรณ์หน้าสวน)", Steal.HandIcon .. " Hold a " .. Steal.HandNameEn:lower() .. " first (sold at the Fruit & Tools stall by the orchard gate)"))
	end
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not root or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Steal.Range + 3 then
		return notify(thief, msg(thief, "เดินไปใต้ต้นก่อน", "Stand under the tree first"))
	end
	if cooling(hole) then
		return notify(thief, msg(thief, "👋 ต้นนี้เจ้าของเพิ่งจับขโมยได้ พักอีกสักพัก", "👋 The owner just caught a thief at this tree, try later"))
	end
	if not canBeStolen(tree, OrchardData.Now()) then
		return notify(thief, msg(thief, "ต้นนี้ขโมยไม่ได้แล้ว (ต้นละ " .. Steal.PerCycle .. " ครั้งต่อรอบผล และต้องเหลือผลให้เจ้าของ)", "This tree can't be stolen from now (once per fruit round, the owner keeps some)"))
	end
	local key = lot.Name .. "#" .. holeNo
	if stealing[key] then -- ต้นเดียวกันกำลังถูกขโมยอยู่ (ต้นละ 1 ครั้งต่อรอบผลอยู่แล้ว)
		return notify(thief, msg(thief, "ลองใหม่อีกครั้ง", "Please try again"))
	end
	-- 2026-11-18 (stealBatch): เข้าชุดเซฟของเจ้าของ โจรหลายคนคนละต้น = เซฟเดียว (แทนต่อคิวทีละคน 2026-11-17)
	stealing[key] = true
	if busy[owner] or stealBatch[owner] then
		notify0(thief, msg(thief, "⏳ กำลังเก็บผล...", "⏳ Picking the fruit...")) -- notify0 = ท่าสอยยังค้างระหว่างรอ
	end
	local res = joinStealBatch(owner, holeNo, kind)
	ownerSt = stateOf(owner)
	if not res.ok then
		stealing[key] = nil
		if not thief.Parent then return end
		if res.applied == nil and owner.Parent == Players then -- เซฟผ่านแต่ต้นนี้เปลี่ยนระหว่างรอ (เจ้าของเก็บไปแล้ว ฯลฯ)
			local tr = ownerSt and ownerSt.data.trees[tostring(holeNo)]
			if not (tr and tr.kind == kind and canBeStolen(tr, OrchardData.Now())) then
				return notify(thief, msg(thief, "ต้นนี้ขโมยไม่ได้แล้ว", "This tree can't be stolen from now"))
			end
		end
		return notify(thief, msg(thief, "ขโมยไม่สำเร็จ ลองใหม่อีกครั้ง", "Steal failed, please try again"))
	end
	if not ownerSt then -- เจ้าของออกหลังเซฟ (ผลถูกหักและเซฟแล้ว) = ให้โจรตามปกติ ทางคืนผลด้านล่างจะข้าม
		ownerSt = { data = { trees = {}, stats = { stolenFrom = 0 } } }
	end
	-- มือขโมยหายระหว่างเซฟ (เกิดยาก) = คืนผลให้เจ้าของ ไม่ให้ของฟรี
	if not OrchardItems.TakeHand(thief, 1, lang(thief), tier) then
		local tr = ownerSt.data.trees[tostring(holeNo)]
		if tr then
			tr.fruits += 1
			tr.stolen = math.max(0, (tr.stolen or 1) - 1)
			ownerSt.data.stats.stolenFrom = math.max(0, ownerSt.data.stats.stolenFrom - 1)
			if not isFake(owner) then OrchardData.SaveLater(owner) end
		end
		stealing[key] = nil
		return
	end
	OrchardItems.Give(thief, OrchardItems.FRUIT, kind, 1, lang(thief))
	saveBag(thief)
	local thiefSt = OrchardData.Get(thief)
	if thiefSt and thiefSt.loaded then
		thiefSt.data.stats.stole += 1
		OrchardData.SaveLater(thief)
	end
	stealing[key] = nil
	render(owner)
	sync(owner)
	-- ต้นใหม่ (ผลเหลือน้อยลง) โยกต่ออีกนิดตอนผลหลุดออก (แบบเดียวกับเก็บเกี่ยว)
	local swayModel = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. tostring(holeNo))
	if swayModel then swayTree(swayModel, hole) end
	-- ขโมยสำเร็จ = ป้ายมุมขวาบน "+1 🥭" แบบเดียวกับเก็บเกี่ยว ไม่มีข้อความกลางจอ (ผู้ใช้สั่ง 2026-11-03)
	pickPoseDone(thief, myPick)
	harvestNotify:FireClient(thief, "Orchard:" .. kind, 0, 1)
	notify(owner, msg(owner,
		string.format("😱 %s ขโมย%sของคุณไป 1 ผล! (ล็อก %s หลุม %d)", thief.DisplayName, def.NameTh, lotNo(lot), holeNo),
		string.format("😱 %s stole 1 of your %s! (lot %s hole %d)", thief.DisplayName, def.NameEn, lotNo(lot), holeNo)))
	print(string.format("Orchard: %s ขโมย %s จาก %s (%s หลุม %d)", thief.Name, kind, owner.Name, lot.Name, holeNo))
end

-- =====L3030-3073 (inside dev.OnInvoke)
		if action == "stealbatch" then -- 2026-11-18 ทดสอบชุดขโมย: ผู้เล่น = เจ้าของ a = "2,3,4" หลุมที่ส่งคำขอพร้อมกัน (ไม่มีโจรจริง ไม่ให้ผลใคร) · b = "prep" ทำต้นสุก 3 ผลก่อน (เซฟเลย)
			local st = stateOf(player)
			if not (st and st.loaded) then return "not loaded" end
			local holes = {}
			for x in string.gmatch(tostring(a or ""), "%d+") do table.insert(holes, tonumber(x)) end
			if b == "prep" then
				local now = OrchardData.Now()
				for _, i in ipairs(holes) do
					local tr = st.data.trees[tostring(i)]
					local def = tr and Config.Trees[tr.kind]
					if def then
						tr.dead = nil
						tr.plantedAt = now - def.GrowSeconds - def.FruitSeconds - 1
						tr.cycleStart = tr.plantedAt + def.GrowSeconds
						tr.fruits, tr.stolen = 3, 0
					end
				end
				local ok = OrchardData.SaveNow(player, 20)
				render(player)
				sync(player)
				return "prep saved=" .. tostring(ok)
			end
			local before = {}
			for k, t in pairs(st.data.trees) do before[k] = t.fruits end
			local results, pending = {}, #holes
			local tStart = os.clock()
			for n, i in ipairs(holes) do
				task.spawn(function()
					local tr = st.data.trees[tostring(i)]
					local r = joinStealBatch(player, i, tr and tr.kind or "Mango")
					results[n] = string.format("hole%d ok=%s %.1fs", i, tostring(r.ok), os.clock() - tStart)
					pending -= 1
				end)
			end
			while pending > 0 do task.wait(0.1) end
			st = stateOf(player)
			for n, i in ipairs(holes) do
				local t = st.data.trees[tostring(i)]
				results[n] ..= string.format(" fruits %s->%s stolen=%s", tostring(before[tostring(i)]), tostring(t and t.fruits), tostring(t and t.stolen))
			end
			render(player)
			sync(player)
			return table.concat(results, " | ")
		end
