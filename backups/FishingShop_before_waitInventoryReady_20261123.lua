-- BACKUP of game.ServerScriptService.FishingShop before rod restore waits for InventoryReady (2026-11-23)
-- Restore: paste everything below this header back into the script's Source in Studio.
-- FishingShop: ร้านตกปลาริมทะเลสาบ (workspace.FishingShop) ซื้อเบ็ดด้วยเหรียญ + ทำเหยื่อจากผลผลิต ค่าต่างๆ ดู ReplicatedStorage.FishingConfig
-- เบ็ดที่ซื้อแล้วจดไว้ใน DataStore "FishingShop_v1" { rods = { [rodId] = true } } กันเบ็ดหาย (เข้าเกมใหม่ไม่มีในกระเป๋า = คืนให้)
-- ซื้อเบ็ด: หักเหรียญ -> เซฟว่ามีแล้ว -> ให้เบ็ด (เซฟไม่ได้ = คืนเหรียญ)
-- ทำเหยื่อ: ผลผลิต 1 ชิ้น = เหยื่อ BAIT_PER_PRODUCE ชิ้น ดาวเดียวกัน (ของในกระเป๋าเซฟโดย InventorySystem)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local SultanConfig = require(ReplicatedStorage:WaitForChild("SultanConfig")) -- ApplySell: โบนัสเงินขาย (สุลต่าน/สัตว์เลี้ยง)
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))

local function say(player, th, en) return Localization.Pick(Localization.GetLanguage(player), th, en) end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getRemote(name, class)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local request = getRemote("FishingShopRequest", "RemoteFunction")
local openEvent = getRemote("FishingShopOpen", "RemoteEvent")

local store = DataStoreService:GetDataStore("FishingShop_v1")
local states = {} -- [player] = { data = { rods = {} }, loaded }

local function coinsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("เหรียญ")
end

local function allTools(player)
	local list = {}
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, tool in ipairs(loc and loc:GetChildren() or {}) do
			if tool:IsA("Tool") then table.insert(list, tool) end
		end
	end
	return list
end

-- ของที่เอาไปขาย/ทำเหยื่อได้: ไม่รวมกองที่ติดดาว (Starred) ไว้ (ผู้เล่นขอ 2026-10-03)
local function usableTools(player)
	local list = {}
	for _, tool in ipairs(allTools(player)) do
		if not tool:GetAttribute("Starred") then table.insert(list, tool) end
	end
	return list
end

local function hasRodTool(player, rodId)
	for _, tool in ipairs(allTools(player)) do
		if tool:GetAttribute("IsFishingRod") and tool:GetAttribute("RodId") == rodId then return true end
	end
	return false
end

local function owns(player, st, rodId)
	return st.data.rods[rodId] == true or hasRodTool(player, rodId)
end

local function save(player, st)
	local ok, err = pcall(function()
		store:UpdateAsync(tostring(player.UserId), function(old)
			old = type(old) == "table" and old or {}
			old.rods = type(old.rods) == "table" and old.rods or {}
			for id in pairs(st.data.rods) do old.rods[id] = true end -- รวมกัน ไม่ลบของเดิม
			return old
		end)
	end)
	if not ok then warn("FishingShop: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err)) end
	return ok
end

-- เบ็ด Robux (ผีเสื้อราตรี / ผึ้งตะวันฉาย ...) เป็น Developer Product ซื้อได้ครั้งเดียวในเชิงผลลัพธ์: ใบเสร็จบันทึกสิทธิ์ถาวรไว้กับบัญชี
-- 2026-10-08 ลงทะเบียนทุกคันที่มี RobuxPrice + ProductId (เดิมเขียนไว้เฉพาะผีเสื้อราตรี) ProductId = 0 = ยังไม่ได้สร้างสินค้า ข้าม
for rodId, rodDef in pairs(Config.Rods) do
	if rodDef.RobuxPrice and (tonumber(rodDef.ProductId) or 0) > 0 then
		PurchaseRouter.Register(rodDef.ProductId, {
			name = rodDef.DisplayName,
			grant = function(player)
				local st = player and states[player]
				if not (st and st.loaded) then return false end
				if st.data.rods[rodId] then
					ItemFactory.GiveRod(player, rodId)
					return true
				end
				st.data.rods[rodId] = true
				if not save(player, st) then
					st.data.rods[rodId] = nil
					return false
				end
				ItemFactory.GiveRod(player, rodId)
				return true
			end,
		})
	end
end

-- ============ ส่งเบ็ด Robux เป็นของขวัญให้เพื่อน (เพิ่ม 2026-10-08) ============
-- เบ็ดที่มี GiftProductId ใน FishingConfig (ตอนนี้ = เบ็ดผีเสื้อ NightMoth) ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนได้เบ็ดถาวร
-- (แบบเดียวกับ PetSlotGift / BoomboxGift; หน้าเลือกเพื่อนใช้ของ VipGui ชนิด "rod_<RodId>")
-- เบ็ดจดไว้ใน FishingShop_v1 ของผู้รับ (rods[rodId] = true) เหมือนการซื้อเอง ผู้รับออฟไลน์ = ได้ตอนเข้าเกมครั้งถัดไป (ระบบคืนเบ็ดเดิมให้เอง)
-- DataStore "FishingRodGift_v1": "pending_<buyerId>" = { to, toName, rodId, t } (ผู้ซื้อเลือกผู้รับไว้) / ใบเสร็จซ้ำไม่ซ้อน (ตั้ง rods เป็น true ซ้ำก็ไม่เกิดอะไร)
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local giftStore = DataStoreService:GetDataStore("FishingRodGift_v1")
local giftRequest = getRemote("FishingRodGiftRequest", "RemoteFunction")
local giftPending = {}   -- [buyer] = { to, toName, rodId, t }
local giftPrompting = {} -- [buyer] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local GIFT_PROMPT_TIMEOUT = 120

local function giftNotify(player, text)
	if player and player.Parent then remoteEvents:WaitForChild("HarvestNotify"):FireClient(player, nil, nil, nil, text) end
end

local function rodIdForGiftProduct(productId)
	for rodId, def in pairs(Config.Rods) do
		if (tonumber(def.GiftProductId) or 0) > 0 and def.GiftProductId == productId then return rodId end
	end
	return nil
end

-- ใบเสร็จของขวัญ: true = มอบและบันทึกแล้ว / false = ยังไม่ยืนยัน (Roblox ส่งใบเสร็จมาใหม่)
local function grantRodGift(rodId, buyer)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return giftStore:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" or pending.rodId ~= rodId then
		warn("FishingShop: ใบเสร็จของขวัญเบ็ด " .. rodId .. " ของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local target = Players:GetPlayerByUserId(pending.to)
	local rodName = Config.RodName(rodId, "th")
	local okSave, err = pcall(function()
		store:UpdateAsync(tostring(pending.to), function(old)
			old = type(old) == "table" and old or {}
			old.rods = type(old.rods) == "table" and old.rods or {}
			old.rods[rodId] = true
			if not target then -- ผู้รับออฟไลน์: จดไว้แจ้งตอนเข้าเกมครั้งถัดไป
				old.giftNotices = type(old.giftNotices) == "table" and old.giftNotices or {}
				old.giftNotices[rodId] = buyer.DisplayName
			end
			return old
		end, { pending.to })
	end)
	if not okSave then
		warn("FishingShop: บันทึกของขวัญเบ็ดไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() giftStore:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	if target then
		local tst = states[target]
		if tst and tst.loaded then tst.data.rods[rodId] = true end
		if not hasRodTool(target, rodId) then ItemFactory.GiveRod(target, rodId) end
		giftNotify(target, say(target,
			"🎁 " .. buyer.DisplayName .. " ส่ง" .. rodName .. "ให้คุณเป็นของขวัญ! อยู่ในแถบไอเทมแล้ว 🎣",
			"🎁 " .. buyer.DisplayName .. " gifted you the " .. Config.RodName(rodId, "en") .. "! It's in your item bar 🎣"))
	end
	giftNotify(buyer, say(buyer, "🎁 ส่ง" .. rodName .. "ให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖", "🎁 " .. Config.RodName(rodId, "en") .. " sent to " .. toName .. ". Thanks for sharing 💖"))
	print("🎁 FishingShop: " .. buyer.Name .. " ส่ง " .. rodId .. " ให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end

for rodId, rodDef in pairs(Config.Rods) do
	if (tonumber(rodDef.GiftProductId) or 0) > 0 then
		PurchaseRouter.Register(rodDef.GiftProductId, {
			name = "ของขวัญ " .. rodDef.DisplayName,
			grant = function(buyer) return grantRodGift(rodId, buyer) end,
		})
	end
end

-- ============ มอบเบ็ดจากโค้ดโปรโมชัน (เพิ่ม 2026-10-08) ============
-- SultanService.redeemButterflyRodPromoCode เรียก: "check" = มีเบ็ดนี้แล้วไหม (ไม่ให้เผาโค้ดทิ้งถ้ามีอยู่แล้ว) / "grant" = บันทึกสิทธิ์ถาวรใน FishingShop_v1 แล้วให้เบ็ด
-- เฉพาะเบ็ดที่อยู่ใน PROMO_RODS (ตอนนี้ = เบ็ดผีเสื้อ NightMoth + เบ็ดผึ้งน้อย SunBee) Studio: Attribute DevRodPromoSimulate = true (ตั้งจากเซิร์ฟเวอร์) = จำลอง ไม่เขียนข้อมูลจริง
local PROMO_RODS = { NightMoth = true, SunBee = true }
local promoRodGrant = Instance.new("BindableFunction")
promoRodGrant.Name = "FishingRodPromoGrant"
promoRodGrant.Parent = ServerScriptService
promoRodGrant.OnInvoke = function(player, mode, rodId)
	if not (typeof(player) == "Instance" and player:IsA("Player") and player.Parent) then return nil, "player unavailable" end
	-- 2026-10-09 เบ็ดคราฟ (Rods.*.Craft = true เช่น เบ็ดรักโลก) ใช้ทางเดียวกัน โต๊ะช่าง (CraftBench) เรียกหลังหักวัตถุดิบแล้ว
	local allowed = type(rodId) == "string" and Config.Rods[rodId] and (PROMO_RODS[rodId] or Config.Rods[rodId].Craft == true)
	if not allowed then return nil, "rod not allowed" end
	local simulate = RunService:IsStudio() and player:GetAttribute("DevRodPromoSimulate") == true
	local st = states[player]
	local waited = 0
	while player.Parent and not (st and st.loaded) and waited < 30 do
		waited += task.wait(0.5)
		st = states[player]
	end
	if not (st and st.loaded) then return nil, "shop data not loaded" end
	if mode == "check" then
		if simulate then return false end
		return owns(player, st, rodId)
	elseif mode == "grant" then
		if simulate then return true end
		if not st.data.rods[rodId] then
			st.data.rods[rodId] = true
			if not save(player, st) then
				st.data.rods[rodId] = nil
				return false, "save failed"
			end
		end
		if not hasRodTool(player, rodId) then ItemFactory.GiveRod(player, rodId) end
		return true
	end
	return nil, "bad mode"
end

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกันและยังไม่มีเบ็ดนี้) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
local function rodGiftSelect(player, rodId, targetUserId)
	local def = type(rodId) == "string" and Config.Rods[rodId]
	local productId = def and tonumber(def.GiftProductId) or 0
	-- Studio: ยังไม่มี ID สินค้า หรือผู้ทดสอบตั้ง Attribute DevGiftSimulate = true (ฝั่งเซิร์ฟเวอร์) = จำลองการจ่ายเงิน ไม่เรียกหน้าชำระเงินจริง
	local studioTest = def ~= nil and RunService:IsStudio() and (productId == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if not def or (productId == 0 and not studioTest) then return { ok = false, message = say(player, "เบ็ดนี้ส่งเป็นของขวัญไม่ได้", "This rod can't be gifted") } end
	if def.OnSale == false then return { ok = false, message = say(player, "เบ็ดนี้ปิดขายอยู่", "This rod is not currently for sale") } end
	if type(targetUserId) ~= "number" or targetUserId ~= targetUserId then return { ok = false, message = say(player, "คำขอไม่ถูกต้อง", "Invalid request") } end
	targetUserId = math.floor(targetUserId)
	if targetUserId == player.UserId then return { ok = false, message = say(player, "ส่งให้ตัวเองไม่ได้", "You can't gift yourself") } end
	local started = giftPrompting[player]
	if started and os.clock() - started < GIFT_PROMPT_TIMEOUT then
		return { ok = false, message = say(player, "กำลังทำรายการก่อนหน้าอยู่ รอสักครู่", "A previous purchase is still open, please wait") }
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local toName
	if target then
		local tst = states[target]
		if not (tst and tst.loaded) then
			return { ok = false, message = say(player, "ข้อมูลของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง", "Your friend's data is still loading, try again") }
		end
		if owns(target, tst, rodId) then
			return { ok = false, message = say(player, target.DisplayName .. " มี" .. def.DisplayName .. "อยู่แล้ว", target.DisplayName .. " already has the " .. Config.RodName(rodId, "en")) }
		end
		toName = target.DisplayName
	elseif RunService:IsStudio() and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId -- ทดสอบใน Studio เท่านั้น (ตั้ง Attribute จากฝั่งเซิร์ฟเวอร์)
	else
		return { ok = false, message = say(player, "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว", "Your friend is no longer in this server") }
	end
	local pending = { to = targetUserId, toName = toName, rodId = rodId, t = os.time() }
	local okSave, err = pcall(function() giftStore:SetAsync("pending_" .. player.UserId, pending, { player.UserId }) end)
	if not okSave then
		warn("FishingShop: จำผู้รับของขวัญเบ็ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = say(player, "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง", "Saving failed, please try again") }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantRodGift, rodId, player)
			if not (okGrant and res == true) then warn("FishingShop: จำลองของขวัญเบ็ดไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return { ok = true, message = say(player, "เปิดหน้าชำระเงินแล้ว: " .. def.DisplayName .. "สำหรับ " .. toName, "Payment opened: " .. Config.RodName(rodId, "en") .. " for " .. toName) }
end

giftRequest.OnServerInvoke = function(player, action, rodId, value)
	if action == "giftSelect" then return rodGiftSelect(player, rodId, value) end
	return { ok = false, message = say(player, "คำขอไม่ถูกต้อง", "Invalid request") }
end

-- ปิดหน้าจ่ายเงินโดยไม่ซื้อ = เลือกคนใหม่ได้เลย (ซื้อสำเร็จ: รอ grantRodGift ล้างให้)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if purchased or not rodIdForGiftProduct(productId) then return end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		giftPrompting[player] = nil
		giftPending[player] = nil
	end
end)

-- ============ ข้อมูลให้หน้าต่าง ============
local function infoFor(player, st)
	local rods = {}
	for _, entry in ipairs(Config.RodList()) do
		table.insert(rods, { Id = entry.Id, Owned = owns(player, st, entry.Id) })
	end
	local stacks, bait, fish = {}, { 0, 0, 0, 0, 0 }, {}
	for _, tool in ipairs(allTools(player)) do
		if tool:GetAttribute("Starred") then
			-- ติดดาวไว้: ไม่แสดงในรายการขาย/ทำเหยื่อ
		elseif tool:GetAttribute("Mutation") then
			-- ผักกลายพันธุ์: ไม่ทำเหยื่อ (ขายที่ร้านเมล็ดพันธุ์ได้ราคาคูณ) 2026-10-30
		elseif tool:GetAttribute("IsProduce") and tool:GetAttribute("CropType") then
			table.insert(stacks, {
				CropType = tool:GetAttribute("CropType"), Star = tool:GetAttribute("Star") or 1,
				Count = tool:GetAttribute("Count") or 1, Name = tool.Name,
			})
		elseif tool:GetAttribute("IsBait") then
			local star = tool:GetAttribute("Star") or 1
			bait[star] = (bait[star] or 0) + (tool:GetAttribute("Count") or 1)
		elseif tool:GetAttribute("IsFish") and Config.Fish[tool:GetAttribute("FishId")] then
			local fishId, star = tool:GetAttribute("FishId"), tool:GetAttribute("Star") or 1
			table.insert(fish, {
				FishId = fishId, Star = star, Count = tool:GetAttribute("Count") or 1,
				Name = Config.Fish[fishId].Name, Rarity = Config.Fish[fishId].Rarity, UnitPrice = SultanConfig.ApplySell(player, Config.GetPrice(fishId, star)),
			})
		end
	end
	table.sort(fish, function(a, b)
		if a.UnitPrice ~= b.UnitPrice then return a.UnitPrice > b.UnitPrice end
		return a.FishId < b.FishId
	end)
	table.sort(stacks, function(a, b)
		if a.Star ~= b.Star then return a.Star > b.Star end
		return a.CropType < b.CropType
	end)
	local coins = coinsOf(player)
	return { Rods = rods, Stacks = stacks, Bait = bait, Fish = fish, Coins = coins and coins.Value or 0 }
end

-- ============ คำสั่ง ============
local function buyRod(player, st, rodId)
	local rod = type(rodId) == "string" and Config.Rods[rodId]
	if not rod then return { ok = false, message = say(player, "ไม่มีเบ็ดนี้", "No such rod") } end
	local lang = Localization.GetLanguage(player)
	local rodName = Config.RodName(rodId, lang)
	if rod.OnSale == false then
		return { ok = false, message = say(player, "เบ็ดนี้ปิดขายอยู่", "This rod is not currently for sale") }
	end
	if rod.RobuxPrice then
		return { ok = false, message = say(player, "เบ็ดนี้ซื้อผ่าน Developer Product", "This rod is purchased through its Developer Product") }
	end
	if owns(player, st, rodId) then
		if not hasRodTool(player, rodId) then ItemFactory.GiveRod(player, rodId) end
		return { ok = false, message = say(player, "มี" .. rod.DisplayName .. "อยู่แล้ว", "You already have the " .. rodName) }
	end
	local coins = coinsOf(player)
	if not coins then return { ok = false, message = say(player, "ยังโหลดเหรียญไม่เสร็จ", "Coins haven't loaded yet") } end
	if coins.Value < rod.Price then
		return { ok = false, message = string.format(say(player, "เหรียญไม่พอ (ต้องใช้ %d)", "Not enough coins (need %d)"), rod.Price) }
	end
	player:SetAttribute("CoinSrc", "rod_buy")
	coins.Value -= rod.Price
	st.data.rods[rodId] = true
	if not save(player, st) then
		st.data.rods[rodId] = nil
		coins.Value += rod.Price
		return { ok = false, message = say(player, "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง (คืนเหรียญแล้ว)", "Save error, please try again (coins refunded)") }
	end
	ItemFactory.GiveRod(player, rodId)
	print(string.format("🎣 FishingShop: %s ซื้อ %s (%d เหรียญ)", player.Name, rodId, rod.Price))
	return { ok = true, message = rod.Price > 0 and say(player, "🎉 ได้" .. rod.DisplayName .. "แล้ว! อยู่ในแถบไอเทม", "🎉 Got the " .. rodName .. "! It's in your item bar") or say(player, "🎉 รับ" .. rod.DisplayName .. "ฟรีแล้ว!", "🎉 Got the " .. rodName .. " for free!") }
end

local function makeBait(player, cropType, star, amount)
	star = math.floor(tonumber(star) or 0)
	amount = math.floor(tonumber(amount) or 0)
	-- star ~= star / amount ~= amount = NaN (ทะลุการเทียบ < > ได้)
	if type(cropType) ~= "string" or star ~= star or amount ~= amount or star < 1 or star > 5 or amount < 1 then return { ok = false, message = say(player, "ข้อมูลไม่ถูกต้อง", "Invalid data") } end
	local stack
	for _, tool in ipairs(usableTools(player)) do
		if tool:GetAttribute("IsProduce") and tool:GetAttribute("CropType") == cropType and tool:GetAttribute("Star") == star and not tool:GetAttribute("Mutation") then
			stack = tool
			break
		end
	end
	if not stack then return { ok = false, message = say(player, "ไม่มีผลผลิตนี้ในกระเป๋าแล้ว", "That produce is no longer in your bag") } end
	-- 2026-11-18 กระเป๋ายังไม่มา (เกิดใหม่/กำลังออก) = ยังไม่ลบผลผลิต (เดิมลบแล้วให้เหยื่อพัง = ผลผลิตหาย)
	if not ItemFactory.FindBackpack(player) then return { ok = false, message = say(player, "กระเป๋ายังไม่พร้อม รอสักครู่แล้วลองใหม่", "Your bag isn't ready yet, please try again in a moment") } end
	local have = stack:GetAttribute("Count") or 1
	amount = math.min(amount, have)
	if have - amount <= 0 then
		stack:Destroy()
	else
		stack:SetAttribute("Count", have - amount)
		stack.Name = ItemFactory.GetProduceName(cropType, star, have - amount, Localization.GetLanguage(player))
	end
	local got = amount * Config.BAIT_PER_PRODUCE
	ItemFactory.GiveBait(player, star, got)
	return { ok = true, message = string.format(say(player, "🐛 ได้เหยื่อ %s %d ชิ้น (ใช้ผลผลิต %d ชิ้น)", "🐛 Got %s bait x%d (used %d produce)"), string.rep("⭐", star), got, amount) }
end

-- ขายปลา (ราคาเดียวกับร้านค้าหลัก FishingConfig.GetPrice) fishId = nil = ขายปลาทุกกอง
local function sellFish(player, fishId, star)
	local coins = coinsOf(player)
	if not coins then return { ok = false, message = say(player, "ยังโหลดเหรียญไม่เสร็จ", "Coins haven't loaded yet") } end
	local total, count = 0, 0
	for _, tool in ipairs(usableTools(player)) do
		local id = tool:GetAttribute("FishId")
		if tool:GetAttribute("IsFish") and Config.Fish[id] and (fishId == nil or (id == fishId and tool:GetAttribute("Star") == star)) then
			local n = tool:GetAttribute("Count") or 1
			total += SultanConfig.ApplySell(player, Config.GetPrice(id, tool:GetAttribute("Star") or 1)) * n
			count += n
			tool:Destroy()
		end
	end
	if count == 0 then return { ok = false, message = say(player, "ไม่มีปลาให้ขาย", "No fish to sell") } end
	coins.Value += total
	print(string.format("🐟 FishingShop: %s ขายปลา %d ตัว ได้ %d เหรียญ", player.Name, count, total))
	return { ok = true, message = string.format(say(player, "💰 ขายปลา %d ตัว ได้ %d เหรียญ", "💰 Sold %d fish for %d coins"), count, total) }
end

local busy = {}
request.OnServerInvoke = function(player, action, a, b, c)
	local st = states[player]
	if not (st and st.loaded) then return { ok = false, message = say(player, "ยังโหลดข้อมูลร้านไม่เสร็จ ลองใหม่อีกครั้ง", "The shop is still loading, try again") } end
	if busy[player] then return { ok = false, message = say(player, "กำลังทำรายการก่อนหน้าอยู่", "Still working on the previous action") } end
	busy[player] = true
	local ok, result = pcall(function()
		if action == "info" then
			return { ok = true }
		elseif action == "buyRod" then
			return buyRod(player, st, a)
		elseif action == "makeBait" then
			return makeBait(player, a, b, c)
		elseif action == "sellFish" then
			if type(a) ~= "string" then return { ok = false, message = say(player, "ข้อมูลไม่ถูกต้อง", "Invalid data") } end
			return sellFish(player, a, math.floor(tonumber(b) or 0))
		elseif action == "sellAllFish" then
			return sellFish(player, nil)
		end
		return { ok = false, message = say(player, "คำขอไม่ถูกต้อง", "Invalid request") }
	end)
	busy[player] = nil
	if not ok then
		warn("FishingShop: คำขอ " .. tostring(action) .. " ของ " .. player.Name .. " ผิดพลาด: " .. tostring(result))
		result = { ok = false, message = say(player, "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง", "Something went wrong, please try again") }
	end
	result.info = infoFor(player, st)
	return result
end

-- ============ ร้านในแมพ: กด E เปิดหน้าต่าง ============
local function hookShop(shop)
	local part = shop:FindFirstChild("PromptPart", true) or shop:FindFirstChildWhichIsA("BasePart", true)
	if not part or part:FindFirstChild("FishingShopPrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FishingShopPrompt"
	-- ProximityPrompt ขึ้นที่ไคลเอนต์เป็นภาษาไทย/อังกฤษไม่ได้จากเซิร์ฟเวอร์ ใช้ PromptLocalizer (ดูหัวข้อในบันทึก)
	prompt.ObjectText = "🎣 ร้านตกปลา"
	prompt.ActionText = "เปิดร้าน"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player) openEvent:FireClient(player) end)
end
local shop = workspace:FindFirstChild("FishingShop")
if shop then hookShop(shop) end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "FishingShop" then hookShop(child) end
end)

-- ============ ผู้เล่นเข้า/ออก ============
local RESTORE_DELAY = 15 -- รอ InventorySystem คืนของเดิมก่อน แล้วค่อยเช็กว่าเบ็ดที่ซื้อไว้หายไหม
local STARTER_ROD = Config.DEFAULT_ROD -- เบ็ดเริ่มต้น (ไม้ไผ่) แจกฟรีทุกคนตอนเข้าเกม
local STARTER_DELAY = 4 -- รอตัวละครเกิด + กระเป๋านิ่งก่อน (ของเดิมที่ InventorySystem คืนมาทีหลัง ไม่ซ้ำ เพราะมันข้ามเบ็ดที่มีอยู่แล้ว)
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

-- แจกเบ็ดเริ่มต้น: ยังไม่มีในกระเป๋า = ให้เลย (ครั้งแรกขึ้นข้อความบอก) แล้วจดไว้ว่ามีแล้ว (หายเมื่อไหร่ได้คืน)
local function giveStarterRod(player, st)
	if not player.Character then player.CharacterAdded:Wait() end
	task.wait(STARTER_DELAY)
	if not player.Parent or states[player] ~= st then return end
	local first = not st.data.rods[STARTER_ROD]
	if not hasRodTool(player, STARTER_ROD) then
		ItemFactory.GiveRod(player, STARTER_ROD)
		if first then
			harvestNotify:FireClient(player, nil, nil, nil, say(player, "🎣 ได้รับเบ็ดไม้ไผ่ฟรี! ไปตกปลาที่ทะเลสาบข้างท่าเรือได้เลย", "🎣 You got a free Bamboo Rod! Go fish at the lake by the dock"))
		end
	end
	if first then
		st.data.rods[STARTER_ROD] = true
		save(player, st)
	end
end

local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function onPlayerAdded(player)
	local st = { data = { rods = {} }, loaded = false }
	states[player] = st
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = ร้านขึ้น "ยังโหลดไม่เสร็จ" ทั้งรอบตอน DataStore throttle) 2026-10-09
	local ok, data = DataLoadRetry.Load(player, "FishingShop", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
	if not ok then return end
	if type(data) == "table" and type(data.rods) == "table" then
		for id, v in pairs(data.rods) do
			if v == true and Config.Rods[id] then st.data.rods[id] = true end
		end
	end
	st.loaded = true
	task.spawn(giveStarterRod, player, st)
	-- ได้เบ็ดเป็นของขวัญตอนออฟไลน์: แจ้งครั้งเดียวตอนเข้าเกม (ตัวเบ็ดคืนให้โดยรอบเช็กข้างล่าง)
	-- ใช้ข้อมูลที่อ่านมาแล้ว (เดิมอ่าน DataStore ซ้ำอีกรอบ เปลืองโควต้าอ่านตอนคนเข้าพร้อมกัน)
	task.spawn(function()
		local rec = data
		if type(rec) ~= "table" or type(rec.giftNotices) ~= "table" or next(rec.giftNotices) == nil then return end
		local notices = rec.giftNotices
		pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if type(old) ~= "table" then return nil end
				old.giftNotices = nil
				return old
			end, { player.UserId })
		end)
		task.wait(8)
		for rodId, fromName in pairs(notices) do
			local def = Config.Rods[rodId]
			if def then
				giftNotify(player, say(player, "🎁 คุณได้รับ" .. def.DisplayName .. "เป็นของขวัญจาก " .. tostring(fromName) .. "! 🎣", "🎁 You received the " .. Config.RodName(rodId, "en") .. " as a gift from " .. tostring(fromName) .. "! 🎣"))
			end
		end
	end)
	task.delay(RESTORE_DELAY, function()
		if not player.Parent or states[player] ~= st then return end
		for rodId in pairs(st.data.rods) do
			if not hasRodTool(player, rodId) and not Config.IsHiddenRod(rodId) then -- เบ็ด DevOnly ในเซิร์ฟจริง = ไม่คืน (สิทธิ์ยังอยู่) 2026-11-19
				ItemFactory.GiveRod(player, rodId)
				warn("FishingShop: คืนเบ็ด " .. rodId .. " ให้ " .. player.Name .. " (ไม่อยู่ในกระเป๋า)")
			end
		end
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

-- 2026-11-19 เบ็ด DevOnly (FishingConfig.IsHiddenRod) ในเซิร์ฟจริง: ถ้ามี Tool โผล่เข้ากระเป๋า/มือ (เช่น InventorySystem คืนของเก่าที่ได้จาก Studio) = เก็บออก
--   สิทธิ์ใน FishingShop_v1 ไม่ลบ เอา DevOnly ออกเมื่อไหร่ ลูปคืนเบ็ดด้านบนให้คืนเอง · ใน Studio ไม่ทำงานเลย
if not game:GetService("RunService"):IsStudio() then
	local function strip(child)
		if child:IsA("Tool") and child:GetAttribute("IsFishingRod") and Config.IsHiddenRod(child:GetAttribute("RodId")) then
			task.defer(function() if child.Parent then child:Destroy() end end)
		end
	end
	local function watch(container)
		for _, c in ipairs(container:GetChildren()) do strip(c) end
		container.ChildAdded:Connect(strip)
	end
	local function watchPlayer(player)
		local pack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 30)
		if pack then watch(pack) end
		player.ChildAdded:Connect(function(c) if c:IsA("Backpack") then watch(c) end end)
		if player.Character then watch(player.Character) end
		player.CharacterAdded:Connect(watch)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(watchPlayer, player) end
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	busy[player] = nil
	giftPending[player] = nil
	giftPrompting[player] = nil
end)
