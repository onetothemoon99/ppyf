-- BACKUP of ServerScriptService.OrderBoardService taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ServerScriptService.OrderBoardService, select all, paste everything BELOW the next line.
-- ===== original Source (19505 bytes, hash 87604238) =====
-- OrderBoardService: กระดานออเดอร์ (2026-10-31) ค่าตัวเลขดู ReplicatedStorage.OrderBoardConfig · หน้าจอ = StarterPlayerScripts.OrderBoardGui
-- DataStore "OrderBoard_v1" ต่อคน: { day, orders = { { kind = "normal"/"mutation", crop, minStar, mutation, need, have, paid } x3 },
--   rerolls = ใช้ไปวันนี้, allPaid = รับโบนัสครบ 3 ใบแล้ว, streak, lastFullDay, week, weekly = { have5, haveRainbow, paid } }
-- ส่งของ = ดึงผักที่ตรงเงื่อนไขจากกระเป๋าให้เอง (ดาวต่ำก่อน ไม่แตะกองที่ติดดาว ⭐) ส่งทีละส่วนได้ ครบ = ให้รางวัล
--   ออเดอร์ผักธรรมดาไม่ดึงผักกลายพันธุ์ (กันเสียของแพง) · ให้รางวัลไม่สำเร็จ (paid = false) กด "รับรางวัล" ใหม่ได้
-- ทดสอบใน Studio: workspace DevOrderBoardKeyOverride = คีย์ปลอม · DevOrderBoardDayOffset = เลื่อนวัน (ทดสอบขึ้นวันใหม่/สัปดาห์ใหม่)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("OrderBoardConfig"))
if not Config.IsEnabled() then return end -- ยังไม่ปล่อย = ไม่ทำอะไร (หน้าจอ/ป้ายก็ไม่ขึ้น)

local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local LevelSystem = require(ServerScriptService:WaitForChild("LevelSystem"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local CropBook = require(ServerScriptService:WaitForChild("CropBook"))
local saveCoinsNow = ServerScriptService:WaitForChild("LeaderstatsSetup"):WaitForChild("SaveCoinsNow", 30)
local saveInventoryNow = ServerScriptService:WaitForChild("InventorySystem"):WaitForChild("SaveInventoryNow", 30)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local function remote(className, name)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local request = remote("RemoteFunction", "OrderBoardRequest")
local openBoard = remote("RemoteEvent", "OrderBoardOpen") -- เซิร์ฟ -> ผู้เล่น: กดป้ายแล้วเปิดหน้าต่าง
local harvestNotify = remote("RemoteEvent", "HarvestNotify")

local store = DataStoreService:GetDataStore("OrderBoard_v1")
local states = {} -- [player] = { data, loaded, key, busy }

local function keyOf(player)
	if RunService:IsStudio() then
		local override = workspace:GetAttribute("DevOrderBoardKeyOverride")
		if type(override) == "string" and override ~= "" and player.UserId > 0 then return override end -- UserId ติดลบ = ผู้เล่นปลอม Studio ใช้คีย์ตัวเอง (2026-11-17)
	end
	return tostring(player.UserId)
end

local function now()
	local offset = RunService:IsStudio() and tonumber(workspace:GetAttribute("DevOrderBoardDayOffset")) or 0
	return os.time() + offset * 86400
end

local function say(player, th, en) return Localization.Pick(Localization.GetLanguage(player), th, en) end

-- ============ สุ่มออเดอร์ ============
local function availableCrops(player, exclude)
	local level = LevelSystem.GetLevel(player) or 1
	local list = {}
	for id, c in pairs(Config.Crops) do
		if c.level <= level and id ~= exclude then table.insert(list, id) end
	end
	table.sort(list)
	if #list == 0 then list = { "Wheat" } end
	return list
end

local function newNormalOrder(player, exclude)
	local list = availableCrops(player, exclude)
	local crop = list[math.random(1, #list)]
	local minStar = math.random(Config.MIN_STAR_RANGE[1], Config.MIN_STAR_RANGE[2])
	return { kind = "normal", crop = crop, minStar = minStar, need = Config.QuantityFor(crop, minStar), have = 0, paid = false }
end

local function newMutationOrder(exclude)
	local choices = {}
	for _, m in ipairs(Config.MUTATION_ORDERS) do
		if m.mutation ~= exclude then table.insert(choices, m) end
	end
	if #choices == 0 then choices = Config.MUTATION_ORDERS end
	local pick = choices[math.random(1, #choices)]
	return { kind = "mutation", mutation = pick.mutation, need = pick.need, have = 0, paid = false }
end

local function newDay(player, d, today)
	d.day = today
	d.orders = {}
	local first
	for _ = 1, Config.DAILY_NORMAL do
		local o = newNormalOrder(player, first)
		first = first or o.crop
		table.insert(d.orders, o)
	end
	for _ = 1, Config.DAILY_MUTATION do table.insert(d.orders, newMutationOrder()) end
	d.rerolls = 0
	d.allPaid = false
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.orders = type(d.orders) == "table" and d.orders or {}
	d.weekly = type(d.weekly) == "table" and d.weekly or {}
	d.streak = tonumber(d.streak) or 0
	d.lastFullDay = tonumber(d.lastFullDay) or -1
	return d
end

-- ขึ้นวัน/สัปดาห์ใหม่ (เรียกก่อนทุกคำสั่ง) คืน true ถ้ามีการเปลี่ยน
local function rollover(player, d)
	local t = now()
	local today, week = Config.DayIndex(t), Config.WeekIndex(t)
	local changed = false
	if d.day ~= today then
		newDay(player, d, today)
		changed = true
	end
	if d.week ~= week then
		d.week = week
		d.weekly = { have5 = 0, haveRainbow = 0, paid = false }
		changed = true
	end
	-- ขาดไปเกิน 1 วัน = นับติดกันใหม่ (วันนี้ยังทำทัน)
	if d.lastFullDay < today - 1 and d.streak ~= 0 then
		d.streak = 0
		changed = true
	end
	return changed
end

local function save(st)
	local snapshot = st.data
	local ok, err = pcall(function()
		store:UpdateAsync(st.key, function() return snapshot end)
	end)
	if not ok then warn("OrderBoard: เซฟไม่สำเร็จ " .. tostring(st.key) .. ": " .. tostring(err)) end
	return ok
end

-- ============ ดึงผักจากกระเป๋า ============
local function produceTools(player)
	local list = {}
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if loc then
			for _, t in ipairs(loc:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("IsProduce") and t:GetAttribute("CropType") and not t:GetAttribute("Starred")
					and (tonumber(t:GetAttribute("Count")) or 0) > 0 then
					table.insert(list, t)
				end
			end
		end
	end
	return list
end

-- เอาออกจากกองที่ผ่าน match(tool) ได้สูงสุด want ชิ้น (ดาวต่ำก่อน) คืนจำนวนที่เอาได้
local function takeProduce(player, want, match)
	if want <= 0 then return 0 end
	local tools = {}
	for _, t in ipairs(produceTools(player)) do if match(t) then table.insert(tools, t) end end
	table.sort(tools, function(a, b) return (a:GetAttribute("Star") or 1) < (b:GetAttribute("Star") or 1) end)
	local lang = Localization.GetLanguage(player)
	local taken = 0
	for _, t in ipairs(tools) do
		if taken >= want then break end
		local count = math.floor(tonumber(t:GetAttribute("Count")) or 0)
		local take = math.min(count, want - taken)
		if take > 0 then
			taken += take
			local left = count - take
			if left <= 0 then
				t:Destroy()
			else
				t:SetAttribute("Count", left)
				t.Name = ItemFactory.GetProduceName(t:GetAttribute("CropType"), t:GetAttribute("Star") or 1, left, lang, t:GetAttribute("Mutation"))
			end
		end
	end
	return taken
end

local function matcherFor(o)
	if o.kind == "mutation" then
		return function(t) return t:GetAttribute("Mutation") == o.mutation end
	end
	return function(t)
		return t:GetAttribute("CropType") == o.crop and (t:GetAttribute("Star") or 1) >= o.minStar and not t:GetAttribute("Mutation")
	end
end

-- ============ รางวัล ============
local function grant(player, reward)
	if (reward.tickets or 0) > 0 and not GachaTickets.Add(player, "Normal", reward.tickets) then return false end
	if (reward.premium or 0) > 0 and not GachaTickets.Add(player, "Premium", reward.premium) then return false end
	if (reward.coins or 0) > 0 then
		local ls = player:FindFirstChild("leaderstats")
		local coins = ls and ls:FindFirstChild("เหรียญ")
		if not (coins and player:GetAttribute("CoinsLoaded")) then return false end
		CheatWatch.AllowCoinGain(player, reward.coins)
		coins.Value += reward.coins
		if saveCoinsNow then saveCoinsNow:Fire(player) end
	end
	return true
end

local function rewardText(player, reward)
	local parts = {}
	if (reward.tickets or 0) > 0 then table.insert(parts, say(player, "🎟️ ตั๋วธรรมดา x", "🎟️ Normal ticket x") .. reward.tickets) end
	if (reward.premium or 0) > 0 then table.insert(parts, say(player, "💎 ตั๋ว Premium x", "💎 Premium ticket x") .. reward.premium) end
	if (reward.coins or 0) > 0 then table.insert(parts, "💰 " .. reward.coins) end
	return table.concat(parts, " + ")
end

local function rewardOf(o)
	return o.kind == "mutation" and Config.MUTATION_REWARD or Config.NORMAL_REWARD
end

-- ให้รางวัลทุกอย่างที่ครบแต่ยังไม่ได้รับ (ออเดอร์ / โบนัสครบ 3 ใบ + ติดกัน / รายสัปดาห์) คืนข้อความที่ได้
local function payOut(player, st)
	local d = st.data
	local got, failed = {}, false
	for _, o in ipairs(d.orders) do
		if o.have >= o.need and not o.paid then
			if grant(player, rewardOf(o)) then
				o.paid = true
				table.insert(got, rewardText(player, rewardOf(o)))
			else
				failed = true
			end
		end
	end
	local allDone = #d.orders > 0
	for _, o in ipairs(d.orders) do if not o.paid then allDone = false end end
	if allDone and not d.allPaid then
		if grant(player, Config.ALL_DONE_REWARD) then
			d.allPaid = true
			table.insert(got, say(player, "โบนัสครบ 3 ใบ ", "All-3 bonus ") .. rewardText(player, Config.ALL_DONE_REWARD))
			local today = Config.DayIndex(now())
			if d.lastFullDay ~= today then
				d.streak = (d.lastFullDay == today - 1) and (d.streak + 1) or 1
				d.lastFullDay = today
				if d.streak >= Config.STREAK_DAYS then
					local t = Config.STREAK_TITLE
					if pcall(CropBook.GrantTitle, player, t.key, t.th, t.en) then
						d.streakTitle = true
					end
				end
			end
		else
			failed = true
		end
	end
	local w = d.weekly
	if (w.have5 or 0) >= Config.WEEKLY.star5 and (w.haveRainbow or 0) >= Config.WEEKLY.rainbow and not w.paid then
		local reward = { premium = Config.WEEKLY.premium }
		if grant(player, reward) then
			w.paid = true
			table.insert(got, say(player, "ออเดอร์ใหญ่ ", "Weekly order ") .. rewardText(player, reward))
		else
			failed = true
		end
	end
	return got, failed
end

-- ============ ข้อมูลให้หน้าจอ ============
local function info(player, st)
	local d = st.data
	local orders = {}
	for i, o in ipairs(d.orders) do
		orders[i] = { kind = o.kind, crop = o.crop, minStar = o.minStar, mutation = o.mutation, need = o.need, have = o.have, paid = o.paid,
			reward = rewardOf(o) }
	end
	local t = now()
	local nextDay = (Config.DayIndex(t) + 1) * 86400 - 7 * 3600
	local used = d.rerolls or 0
	return {
		ok = true, orders = orders, allPaid = d.allPaid == true, allReward = Config.ALL_DONE_REWARD,
		rerollsLeft = math.max(0, Config.REROLL_MAX - used), rerollPrice = used < Config.REROLL_FREE and 0 or Config.REROLL_PRICE,
		streak = d.streak, streakDays = Config.STREAK_DAYS, streakTitle = d.streakTitle == true,
		weekly = { have5 = d.weekly.have5 or 0, haveRainbow = d.weekly.haveRainbow or 0, paid = d.weekly.paid == true,
			need5 = Config.WEEKLY.star5, needRainbow = Config.WEEKLY.rainbow, premium = Config.WEEKLY.premium },
		resetIn = nextDay - t,
	}
end

-- ============ คำสั่ง ============
local actions = {}

function actions.deliver(player, st, index)
	local o = st.data.orders[index]
	if not o then return { ok = false } end
	if o.have >= o.need then return { ok = false, message = say(player, "ออเดอร์นี้ส่งครบแล้ว", "This order is already complete") } end
	local taken = takeProduce(player, o.need - o.have, matcherFor(o))
	if taken <= 0 then return { ok = false, message = say(player, "ไม่มีผักที่ตรงเงื่อนไขในกระเป๋า (กองที่ติดดาว ⭐ ไม่นับ)", "No matching produce in your bag (starred stacks are skipped)") } end
	o.have += taken
	return { ok = true, message = say(player, "ส่งแล้ว ", "Delivered ") .. taken .. say(player, " ชิ้น", ""), bag = true }
end

function actions.weekly(player, st)
	local w = st.data.weekly
	local t5 = takeProduce(player, Config.WEEKLY.star5 - (w.have5 or 0), function(t) return (t:GetAttribute("Star") or 1) >= 5 and not t:GetAttribute("Mutation") end)
	local tr = takeProduce(player, Config.WEEKLY.rainbow - (w.haveRainbow or 0), function(t) return t:GetAttribute("Mutation") == "Rainbow" end)
	if t5 + tr <= 0 then return { ok = false, message = say(player, "ไม่มีผัก ★5 หรือ 🌈 รุ้งให้ส่ง", "No ★5 or 🌈 Rainbow produce to deliver") } end
	w.have5 = (w.have5 or 0) + t5
	w.haveRainbow = (w.haveRainbow or 0) + tr
	return { ok = true, message = say(player, "ส่งแล้ว ", "Delivered ") .. (t5 + tr) .. say(player, " ชิ้น", ""), bag = true }
end

function actions.reroll(player, st, index)
	local d = st.data
	local o = d.orders[index]
	if not o then return { ok = false } end
	if o.have > 0 or o.paid then return { ok = false, message = say(player, "ออเดอร์ที่ส่งไปแล้วเปลี่ยนไม่ได้", "Orders you've started can't be changed") } end
	local used = d.rerolls or 0
	if used >= Config.REROLL_MAX then return { ok = false, message = say(player, "วันนี้เปลี่ยนครบแล้ว", "No more changes today") } end
	local price = used < Config.REROLL_FREE and 0 or Config.REROLL_PRICE
	if price > 0 then
		local ls = player:FindFirstChild("leaderstats")
		local coins = ls and ls:FindFirstChild("เหรียญ")
		if not (coins and player:GetAttribute("CoinsLoaded")) or coins.Value < price then
			return { ok = false, message = say(player, "เหรียญไม่พอ", "Not enough coins") }
		end
		player:SetAttribute("CoinSrc", "order_reroll")
		coins.Value -= price
		if saveCoinsNow then saveCoinsNow:Fire(player) end
	end
	d.rerolls = used + 1
	if o.kind == "mutation" then
		d.orders[index] = newMutationOrder(o.mutation)
	else
		-- ไม่ซ้ำกับพืชของออเดอร์ธรรมดาอีกใบ (พืชที่เปลี่ยนทิ้งอาจออกซ้ำได้ถ้ามีพืชให้เลือกน้อย)
		local other
		for i, x in ipairs(d.orders) do if i ~= index and x.kind == "normal" then other = x.crop end end
		d.orders[index] = newNormalOrder(player, other)
	end
	return { ok = true, message = price > 0 and (say(player, "เปลี่ยนแล้ว -", "Changed -") .. price .. say(player, " เหรียญ", " coins")) or say(player, "เปลี่ยนแล้ว (ฟรี)", "Changed (free)") }
end

function actions.claim(player, st) -- รับรางวัลที่ค้าง (ครั้งก่อนให้ไม่สำเร็จ)
	return { ok = true }
end

request.OnServerInvoke = function(player, action, arg)
	local st = states[player]
	if not (st and st.loaded) then return { ok = false, message = say(player, "ยังโหลดกระดานไม่เสร็จ ลองใหม่อีกครั้ง", "Board not loaded yet, try again") } end
	if st.busy then return { ok = false } end
	st.busy = true
	local ok, result = pcall(function()
		local changed = rollover(player, st.data)
		if action == "info" then
			if changed then save(st) end
			return info(player, st)
		end
		local fn = actions[action]
		if not fn or (arg ~= nil and type(arg) ~= "number") then return { ok = false } end
		local r = fn(player, st, arg and math.floor(arg))
		if r.ok then
			local got, failed = payOut(player, st)
			save(st)
			if r.bag and saveInventoryNow then saveInventoryNow:Fire(player) end
			if #got > 0 then r.message = "🎁 " .. table.concat(got, " · ") end
			if failed then r.message = (r.message and (r.message .. " · ") or "") .. say(player, "ให้รางวัลบางอย่างไม่สำเร็จ กดรับใหม่ได้", "Some rewards failed, press claim to retry") end
			if #got > 0 then print("📋 OrderBoard: " .. player.Name .. " ได้ " .. table.concat(got, " · ")) end
		end
		r.info = info(player, st)
		return r
	end)
	st.busy = nil
	if not ok then warn("OrderBoard: " .. tostring(result)) return { ok = false } end
	return result
end

-- ============ โหลด / ออกเกม ============
local function onPlayerAdded(player)
	local st = { data = normalize(nil), loaded = false, key = keyOf(player) }
	states[player] = st
	local ok, data = DataLoadRetry.Load(player, "OrderBoard", DataLoadRetry.Get(store, st.key), function() return states[player] == st end)
	if not ok then return end
	st.data = normalize(data)
	st.loaded = true
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
Players.PlayerRemoving:Connect(function(player) states[player] = nil end) -- ทุกคำสั่งเซฟทันทีอยู่แล้ว

-- ============ ป้ายกระดานในแมพ ============
-- เก็บไว้ที่ ServerStorage.OrderBoard เปิดระบบแล้วค่อยยกไป workspace (ระบบปิด = ไม่มีป้ายในแมพ) · ปุ่ม ProximityPrompt ชื่อ OrderBoardPrompt
task.spawn(function()
	local board = workspace:FindFirstChild("OrderBoard") or game:GetService("ServerStorage"):FindFirstChild("OrderBoard")
	if not board then warn("OrderBoard: ไม่เจอโมเดลป้าย ServerStorage.OrderBoard") return end
	board.Parent = workspace
	local prompt = board:FindFirstChild("OrderBoardPrompt", true)
	if not prompt then warn("OrderBoard: ป้ายไม่มี OrderBoardPrompt") return end
	prompt.Triggered:Connect(function(player) openBoard:FireClient(player) end)
end)
