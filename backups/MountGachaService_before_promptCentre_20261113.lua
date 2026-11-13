-- Backup of game.ServerScriptService.MountSystem.MountGachaService (Script) before moving the E prompt to the machine centre, 2026-11-13.
-- Restore: open the script in Studio, select all, paste everything below this header.
-- MountGachaService: ตู้สุ่มสัตว์ขี่ ฝั่งเซิร์ฟเวอร์ (2026-10-15)
--   - สุ่มด้วยเหรียญอย่างเดียว ราคา/อัตราออกดู ReplicatedStorage.MountConfig (ตัวเทศกาลเข้า/ออกตู้เองตาม SeasonConfig)
--   - การสุ่มทำที่นี่เท่านั้น ฝั่งผู้เล่นแค่ "ขอสุ่ม" 1 หรือ 10 ครั้ง
--   - หักเหรียญก่อน -> สุ่ม -> บันทึก (MountOwnership.GrantBatch) บันทึกไม่ได้ = คืนเหรียญทั้งหมด
--   - ได้ตัวซ้ำ (มีอยู่แล้ว หรือออกซ้ำในชุดเดียวกัน) = คืนเหรียญ MountConfig.DupeRefund ต่อตัว
--   - ประกาศ: ได้ระดับ MountConfig.AnnounceFrom ขึ้นไป = ทุกคนในเซิร์ฟเห็น (RemoteEvent MountGachaAnnounce)
--     ได้ระดับลับ = ประกาศทุกเซิร์ฟ (MessagingService หัวข้อ MountGachaAnnounce_v1)
-- RemoteFunction RemoteEvents.MountGachaRequest(action, count): "info" / "roll"
-- RemoteEvent RemoteEvents.MountGachaOpen: เซิร์ฟสั่งเปิดหน้าต่าง (กด E ที่ workspace.MountGachaMachine)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")

local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig"))
local MountOwnership = require(script.Parent:WaitForChild("MountOwnership"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory")) -- เศษเพชร/ทับทิมจากตู้ (MountConfig.Items) 2026-10-16

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
local requestRemote = remote("RemoteFunction", "MountGachaRequest")
local announceRemote = remote("RemoteEvent", "MountGachaAnnounce")
local openRemote = remote("RemoteEvent", "MountGachaOpen")

local ROLL_COOLDOWN = 1 -- วินาที ระหว่างการสุ่มแต่ละครั้ง
local ROLLS_FLAG = 300 -- สุ่มครบเท่านี้ในรอบเดียว (4.5 ล้านเหรียญ) = จดชื่อให้เจ้าของดู
local ANNOUNCE_TOPIC = "MountGachaAnnounce_v1"

local rng = Random.new()
local busy = {} -- [player] = true ระหว่างทำคำขอ
local lastRoll = {} -- [player] = os.clock()
local rollsThisSession = {} -- [player] = จำนวนครั้ง

local function coinsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("เหรียญ")
end

local function pickOne(pool)
	local total = 0
	for _, e in ipairs(pool) do total += e.chance end
	local x = rng:NextNumber() * total
	for _, e in ipairs(pool) do
		x -= e.chance
		if x <= 0 then return e end
	end
	return pool[#pool]
end

local function infoFor(player)
	local pool = {}
	for _, e in ipairs(MountConfig.CurrentPool()) do
		table.insert(pool, { Id = e.id, Rarity = e.rarity, Chance = e.chance })
	end
	return {
		Price = MountConfig.RollPrice,
		DupeRefund = MountConfig.DupeRefund,
		MultiCount = MountConfig.MultiRollCount,
		Pool = pool,
		Owned = MountOwnership.GetOwned(player),
		Equipped = MountOwnership.GetEquipped(player),
	}
end

local function announce(player, results)
	local minRank = MountConfig.RarityRank(MountConfig.AnnounceFrom)
	for _, r in ipairs(results) do
		if MountConfig.RarityRank(r.Rarity) >= minRank then
			local payload = { UserId = player.UserId, Name = player.DisplayName, MountId = r.MountId, Rarity = r.Rarity, IsNew = r.IsNew }
			announceRemote:FireAllClients(payload)
			if r.Rarity == "Secret" then
				task.spawn(function()
					local message = table.clone(payload)
					message.JobId = game.JobId
					local ok, err = pcall(function() MessagingService:PublishAsync(ANNOUNCE_TOPIC, message) end)
					if not ok then warn("MountGachaService: ประกาศข้ามเซิร์ฟไม่สำเร็จ: " .. tostring(err)) end
				end)
			end
		end
	end
end

-- รับประกาศจากเซิร์ฟอื่น (ข้ามของเซิร์ฟตัวเอง)
task.spawn(function()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(ANNOUNCE_TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" or data.JobId == game.JobId then return end
			if type(data.Name) ~= "string" or type(data.MountId) ~= "string" then return end
			local def = MountConfig.Mounts[data.MountId]
			if not def then return end
			announceRemote:FireAllClients({
				UserId = tonumber(data.UserId) or 0, Name = string.sub(data.Name, 1, 40),
				MountId = data.MountId, Rarity = def.Rarity, OtherServer = true,
			})
		end)
	end)
	if not ok then warn("MountGachaService: ฟังประกาศข้ามเซิร์ฟไม่ได้: " .. tostring(err)) end
end)

local function roll(player, count)
	count = math.floor(tonumber(count) or 0)
	if count ~= 1 and count ~= MountConfig.MultiRollCount then return { ok = false, message = "จำนวนครั้งไม่ถูกต้อง" } end
	if player:GetAttribute("CoinsLoaded") ~= true then return { ok = false, message = "ยังโหลดเหรียญไม่เสร็จ ลองใหม่อีกครั้ง" } end
	if not MountOwnership.IsLoaded(player) then return { ok = false, message = "ยังโหลดข้อมูลสัตว์ขี่ไม่เสร็จ ลองใหม่อีกครั้ง" } end
	if player:GetAttribute("InventoryReady") ~= true then return { ok = false, message = "ยังโหลดกระเป๋าไม่เสร็จ ลองใหม่อีกครั้ง" } end -- ของปลอบใจเข้ากระเป๋า
	if lastRoll[player] and os.clock() - lastRoll[player] < ROLL_COOLDOWN then
		return { ok = false, message = "ใจเย็นๆ รออีกนิดนะ" }
	end
	local coins = coinsOf(player)
	if not coins then return { ok = false, message = "ยังโหลดเหรียญไม่เสร็จ ลองใหม่อีกครั้ง" } end
	local cost = MountConfig.RollPrice * count
	if coins.Value < cost then
		return { ok = false, message = string.format("เหรียญไม่พอ (ต้องใช้ %d)", cost) }
	end
	local pool = MountConfig.CurrentPool()
	if #pool == 0 then return { ok = false, message = "ตู้ยังไม่พร้อม" } end

	lastRoll[player] = os.clock()
	player:SetAttribute("CoinSrc", "mount_gacha")
	coins.Value -= cost
	local picks, mountIds = {}, {}
	local shoeAmounts, addShoes = {}, 0
	local accIds = {} -- ของแต่งสัตว์ขี่ (2026-10-16)
	local furnIds = {} -- ของตกแต่ง (2026-10-16)
	for i = 1, count do
		local e = pickOne(pool)
		picks[i] = e
		local def = e.item and MountConfig.Items[e.id]
		if def and def.Currency == "Horseshoe" then
			-- เกือกม้านำโชค: บันทึกพร้อมสัตว์ขี่ในครั้งเดียว
			local amount = rng:NextInteger(def.AmountMin or 1, def.AmountMax or 1)
			shoeAmounts[i] = amount
			addShoes += amount
		elseif e.acc then
			table.insert(accIds, e.id)
		elseif e.furn then
			table.insert(furnIds, e.id)
		elseif not e.item then
			table.insert(mountIds, e.id)
		end
	end
	-- สัตว์ขี่ + เกือกม้า: บันทึกครั้งเดียว บันทึกไม่ได้ = คืนเหรียญทั้งหมด
	local granted, accGranted, furnGranted = {}, {}, {}
	if #mountIds > 0 or addShoes > 0 or #accIds > 0 or #furnIds > 0 then
		granted, accGranted, furnGranted = MountOwnership.GrantBatch(player, mountIds, addShoes, accIds, furnIds)
		if not granted then
			coins.Value += cost
			return { ok = false, message = "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง (คืนเหรียญแล้ว)" }
		end
	end

	local results, refund = {}, 0
	local prize = 0 -- เหรียญรางวัลจากตู้ (Currency = "Coins") 2026-10-17
	local nextMount = 1
	local nextAcc = 1
	local nextFurn = 1
	for i, e in ipairs(picks) do
		local r
		if e.acc then
			-- ของแต่งสัตว์ขี่: ใหม่ = เก็บไว้ใส่ / ซ้ำ = คืนเหรียญครึ่งราคาสุ่ม (MountConfig.DupeRefund) เหมือนสัตว์ขี่/ของตกแต่งซ้ำ
			-- 2026-10-20 ผู้ใช้: อันไหนได้หุ่นดวงดี เปลี่ยนเป็นเงิน 50% ของค่าสุ่มแทน (เดิมได้หุ่นฟาง x50 จำนวน DupeScarecrowAmount)
			local g = accGranted[nextAcc]
			nextAcc += 1
			r = { MountId = e.id, Rarity = e.rarity, IsAcc = true, IsNew = g and g.isNew }
			if g and not g.isNew then
				r.Refund = MountConfig.DupeRefund
				refund += r.Refund
			end
		elseif e.furn then
			-- ของตกแต่ง: ใหม่ = เก็บไว้วาง / ซ้ำ = คืนเหรียญครึ่งราคาสุ่ม (MountConfig.DupeRefund) เหมือนสัตว์ขี่ซ้ำ
			-- 2026-10-19 ผู้ใช้: ของตกแต่งซ้ำไม่ต้องให้หุ่นฟางแล้ว ให้เงินครึ่งหนึ่งของการสุ่มแทน (ของแต่งซ้ำก็เป็นเงินแล้วตั้งแต่ 2026-10-20)
			local g = (furnGranted or {})[nextFurn]
			nextFurn += 1
			r = { MountId = e.id, Rarity = e.rarity, IsFurn = true, IsNew = g and g.isNew }
			if g and not g.isNew then
				r.Refund = MountConfig.DupeRefund
				refund += r.Refund
			end
		else
		if e.item and MountConfig.Items[e.id] and MountConfig.Items[e.id].Currency == "Coins" then
			-- เหรียญรางวัล (2026-10-17 แทนหุ่นฟางดวงดี x10)
			local def = MountConfig.Items[e.id]
			r = { MountId = e.id, Rarity = e.rarity, IsItem = true, Currency = "Coins", Amount = def.Amount or 0 }
			prize += def.Amount or 0
		elseif e.item and MountConfig.Items[e.id] and MountConfig.Items[e.id].Currency == "Booster" then
			-- ของปลอบใจในฟาร์ม (หุ่นฟางดวงดี) เข้ากระเป๋า ให้ไม่ได้ = คืนเหรียญของครั้งนั้น
			local def = MountConfig.Items[e.id]
			local ok = pcall(function() ItemFactory.GiveBoosterTool(player, def.Amount or 1, def.BoosterTier) end)
			r = { MountId = e.id, Rarity = e.rarity, IsItem = true, Currency = "Booster", Amount = def.Amount or 1 }
			if not ok then
				warn("MountGachaService: ให้หุ่นกับ " .. player.Name .. " ไม่สำเร็จ คืนเหรียญ")
				r.Refund = MountConfig.RollPrice
				refund += r.Refund
			end
		elseif e.item and MountConfig.Items[e.id] and MountConfig.Items[e.id].Currency == "None" then
			-- แคปซูลเปล่า: ไม่ได้อะไร ไม่คืนเหรียญ (ตู้เป็นที่เบิร์นเหรียญ 2026-10-16)
			r = { MountId = e.id, Rarity = e.rarity, IsItem = true, Currency = "None" }
		elseif shoeAmounts[i] then
			r = { MountId = e.id, Rarity = e.rarity, IsItem = true, Currency = "Horseshoe", Amount = shoeAmounts[i] }
		elseif e.item then
			-- ของเข้ากระเป๋า (FishId) ให้ไม่ได้ = คืนเหรียญของครั้งนั้น (ตอนนี้ไม่มีของแบบนี้ในตู้แล้ว)
			local def = MountConfig.Items[e.id]
			local ok = def and def.FishId and pcall(function() ItemFactory.GiveFish(player, def.FishId, 1, def.Amount or 1) end)
			r = { MountId = e.id, Rarity = e.rarity, IsItem = true, Amount = def and def.Amount or 1 }
			if not ok then
				r.Refund = MountConfig.RollPrice
				refund += r.Refund
			end
		else
			local g = granted[nextMount]
			nextMount += 1
			r = {
				MountId = g.mountId, Rarity = e.rarity, IsNew = g.isNew,
				Refund = (not g.isNew) and MountConfig.DupeRefund or nil,
			}
			if r.Refund then refund += r.Refund end
		end
		end
		results[i] = r
	end
	if refund > 0 and coins.Parent then coins.Value += refund end
	if prize > 0 and coins.Parent then coins.Value += prize end

	local names = {}
	for _, r in ipairs(results) do table.insert(names, r.MountId .. (r.IsNew and "*" or "") .. (r.IsItem and "(ของ)" or "")) end
	print(string.format("🐴 MountGacha: %s สุ่ม x%d -> %s (จ่าย %d คืน %d)", player.Name, count, table.concat(names, ", "), cost, refund))

	rollsThisSession[player] = (rollsThisSession[player] or 0) + count
	if rollsThisSession[player] >= ROLLS_FLAG then
		CheatWatch.Flag(player, "mount_gacha_rolls", string.format("สุ่มสัตว์ขี่ %d ครั้งในรอบนี้ (%d เหรียญ)", rollsThisSession[player], rollsThisSession[player] * MountConfig.RollPrice))
	end
	announce(player, results)
	return { ok = true, results = results, spent = cost, refund = refund, info = infoFor(player) }
end

requestRemote.OnServerInvoke = function(player, action, count)
	if not MountConfig.IsEnabled() then return { ok = false, message = "ตู้สุ่มสัตว์ขี่ยังไม่เปิด" } end -- สวิตช์ปิด (2026-10-16)
	if busy[player] then return { ok = false, message = "กำลังทำรายการก่อนหน้าอยู่" } end
	busy[player] = true
	local ok, result = pcall(function()
		if action == "info" then
			return { ok = true, info = infoFor(player) }
		elseif action == "roll" then
			return roll(player, count)
		elseif action == "exchange" then
			-- count = mountId ที่อยากแลกด้วยเกือกม้า
			local mountId = count
			local cost = type(mountId) == "string" and MountConfig.ExchangeCostOf(mountId)
			if not cost then return { ok = false, message = "ตู้นี้ไม่มีระบบแลกแล้ว" } end
			local ok, message = MountOwnership.Exchange(player, mountId, cost)
			if ok then print(string.format("🧲 MountGacha: %s แลก %s ด้วยเกือกม้า %d", player.Name, mountId, cost)) end
			return { ok = ok, message = message, mountId = mountId, info = infoFor(player) }
		end
		return { ok = false, message = "คำขอไม่ถูกต้อง" }
	end)
	busy[player] = nil
	if not ok then
		warn("MountGachaService: คำขอ " .. tostring(action) .. " ของ " .. player.Name .. " ผิดพลาด: " .. tostring(result))
		return { ok = false, message = "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง" }
	end
	return result
end

Players.PlayerRemoving:Connect(function(player)
	busy[player], lastRoll[player], rollsThisSession[player] = nil, nil, nil
end)

-- ============ ตัวตู้ในแมพ (workspace.MountGachaMachine): เดินไปกด E เปิดหน้าต่าง ============
local function hookMachine(machine)
	local prompt = machine:FindFirstChild("MountGachaPrompt", true)
	if not prompt then
		local anchorPart = machine:IsA("BasePart") and machine or machine:FindFirstChildWhichIsA("BasePart", true)
		if not anchorPart then return end
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "MountGachaPrompt"
		prompt.ActionText = "เปิดตู้สุ่ม"
		prompt.ObjectText = "🐴 ตู้สุ่มสัตว์ขี่"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchorPart
	end
	prompt.Triggered:Connect(function(player)
		openRemote:FireClient(player)
	end)
end
local machine = workspace:FindFirstChild("MountGachaMachine")
if not MountConfig.IsEnabled() then
	-- ระบบสัตว์ขี่ปิดอยู่ (MountConfig.Enabled): เก็บตู้ออกจากแมพตอนเปิดเซิร์ฟ ผู้เล่นไม่เห็น (ในไฟล์เกมยังอยู่ที่เดิม)
	if machine then machine.Parent = game:GetService("ServerStorage") end
	machine = nil
end
if machine then hookMachine(machine) end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "MountGachaMachine" and MountConfig.IsEnabled() then hookMachine(child) end
end)
