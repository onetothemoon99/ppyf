-- BACKUP of ServerScriptService.LuckBoosterGift before adding GetAsync pre-check to inbox deliver (2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.LuckBoosterGift.Source in Studio
-- LuckBoosterGift: ส่ง "หุ่นทองคำนำโชค" (ระดับ x100) ให้เพื่อนเป็นของขวัญ (Developer Product: LuckConfig.BoosterTiers.x100.GiftProductId)
-- สินค้าแยกจากการซื้อให้ตัวเอง (ProductId) ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนได้หุ่นทองคำ 1 อันเข้ากระเป๋า
-- ของเป็นไอเทม (ไม่ใช่สิทธิ์ถาวร) จึงฝากไว้ใน "กล่องจดหมาย" ใน DataStore ก่อน แล้วส่งเข้ากระเป๋าเมื่อกระเป๋าของผู้รับโหลดเสร็จ
--   ผู้รับออกเกมไปแล้วก็ไม่หาย: ได้ตอนเข้าเกมครั้งถัดไป (ส่งให้คนเดิมซ้ำได้ สะสมเป็นกอง)
-- DataStore "LuckGift_v1": "inbox_<userId>" = { count = ส่งมาทั้งหมด, delivered = ส่งเข้ากระเป๋าไปแล้ว, receipts = {...}, fromName }
--                          "pending_<userId>" = { to, toName, t } (ผู้ซื้อเลือกผู้รับไว้)
-- ส่งเข้ากระเป๋า: จดว่าส่งแล้ว (UpdateAsync) ก่อน แล้วค่อยให้ของ (หลายเซิร์ฟเวอร์พร้อมกันก็ได้ครั้งเดียว) เหมือน SultanService.claim

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))

local TIER_ID = "x100"
local tier = LuckConfig.BoosterTiers[TIER_ID]
local GIFT_PRODUCT_ID = tier.GiftProductId or 0

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local request = remoteEvents:FindFirstChild("LuckGiftRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "LuckGiftRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("LuckGift_v1")
local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local delivering = {}    -- [player] = true กันส่งเข้ากระเป๋าซ้อนกันในเซิร์ฟเวอร์เดียว
local GIFT_PROMPT_TIMEOUT = 120

local function notify(player, text)
	if player and player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

local function readInbox(old)
	if type(old) ~= "table" then old = {} end
	old.count = math.max(0, math.floor(tonumber(old.count) or 0))
	old.delivered = math.max(0, math.floor(tonumber(old.delivered) or 0))
	old.receipts = type(old.receipts) == "table" and old.receipts or {}
	return old
end

-- ส่งของในกล่องจดหมายเข้ากระเป๋า (เรียกตอนเข้าเกม และหลังมีของขวัญใหม่ถึงผู้รับที่อยู่ในเซิร์ฟเวอร์)
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function deliver(player)
	if delivering[player] then return end
	delivering[player] = true
	local waited = 0
	-- InventoryReady = กระเป๋าโหลดสำเร็จจริง (InventoryLoaded ถูกตั้งแม้โหลดไม่สำเร็จ ตอนนั้นกระเป๋าไม่ถูกเซฟ = หุ่นหายได้) รอได้นานขึ้นเพราะกระเป๋าลองโหลดใหม่เบื้องหลัง 2026-10-13
	while player.Parent and not player:GetAttribute("InventoryReady") and waited < 300 do waited += task.wait(0.5) end
	if not (player.Parent and player:GetAttribute("InventoryReady")) then delivering[player] = nil return end
	-- ไม่เร่งด่วน: หลีกทางให้ของสำคัญโหลดก่อน (2026-10-13)
	if not DataLoadRetry.Defer(player, "LuckBoosterGift") then delivering[player] = nil return end
	-- 2026-11-18 กระเป๋าไม่มี (เกิดใหม่/กำลังออก) = ยังไม่จดว่าส่งแล้ว เก็บไว้ในกล่องจดหมาย (ได้ตอนเข้าเกมครั้งถัดไป)
	if not ItemFactory.FindBackpack(player) then delivering[player] = nil return end
	local n, from = 0, nil
	local ok, err = pcall(function()
		store:UpdateAsync("inbox_" .. player.UserId, function(old)
			if type(old) ~= "table" then n = 0 return nil end
			local data = readInbox(old)
			n = data.count - data.delivered
			from = data.fromName
			if n <= 0 then n = 0 return nil end
			data.delivered = data.count
			return data
		end)
	end)
	if not ok then
		warn("LuckBoosterGift: เช็กกล่องจดหมาย " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
		delivering[player] = nil
		return
	end
	if n > 0 then
		-- 2026-11-18 เดิม: จดส่งแล้วแล้วออกเกม/ให้ของพัง = หุ่นหาย (ของ Robux) -> ให้ไม่ได้ = คืนเข้ากล่องจดหมาย (delivered -= n)
		local okGive, gErr = false, "player left"
		if player.Parent then okGive, gErr = pcall(ItemFactory.GiveBoosterTool, player, n, TIER_ID) end
		if okGive then
			notify(player, "🍀 ได้รับหุ่นทองคำนำโชค x" .. n .. " เป็นของขวัญจาก " .. tostring(from or "เพื่อน") .. "! ดูในกระเป๋า 🎒")
			print("🎁 LuckBoosterGift: ส่งหุ่นทองคำ " .. n .. " อันเข้ากระเป๋า " .. player.Name)
		else
			local okBack, bErr = pcall(function()
				store:UpdateAsync("inbox_" .. player.UserId, function(old)
					if type(old) ~= "table" then return nil end
					local data = readInbox(old)
					data.delivered = math.max(0, data.delivered - n)
					return data
				end)
			end)
			warn(string.format("LuckBoosterGift: ให้หุ่น %d อันกับ %s ไม่สำเร็จ (%s) คืนเข้ากล่องจดหมาย: %s", n, player.Name, tostring(gErr), okBack and "สำเร็จ" or ("ไม่สำเร็จ " .. tostring(bErr))))
		end
	end
	delivering[player] = nil
end

-- BindableFunction สำหรับรางวัลโค้ด: บันทึกเข้ากล่องจดหมายก่อน แล้วจึงส่งเข้ากระเป๋า
local promoGrant = Instance.new("BindableFunction")
promoGrant.Name = "LuckBoosterPromoGrant"
promoGrant.Parent = ServerScriptService
promoGrant.OnInvoke = function(player, code, amount)
	if not (player and player:IsA("Player") and player.Parent) then return false, "player unavailable" end
	if type(code) ~= "string" or not string.match(code, "^LK[A-Z0-9]+$") then return false, "invalid code" end
	amount = math.clamp(math.floor(tonumber(amount) or 0), 1, 50)
	local ok, err = pcall(function()
		store:UpdateAsync("inbox_" .. player.UserId, function(old)
			local data = readInbox(old)
			data.promoCodes = type(data.promoCodes) == "table" and data.promoCodes or {}
			if not data.promoCodes[code] then
				data.count += amount
				data.promoCodes[code] = true
				data.fromName = "โค้ดโปรโมชัน"
			end
			return data
		end, { player.UserId })
	end)
	if not ok then return false, tostring(err) end
	-- 2026-11-23 รอ 7 วิ: เพิ่งเขียน inbox_ คีย์เดียวกัน เขียนซ้ำใน 6 วิ = DataStore เข้าคิว (คำเตือน "request was added to queue")
	task.delay(7, deliver, player)
	return true
end

-- PurchaseRouter เรียกตอนจ่ายเงินสำเร็จ: true = มอบและบันทึกแล้ว / false = ยังไม่ยืนยัน (Roblox จะส่งใบเสร็จมาใหม่)
local function grantGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return store:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("LuckBoosterGift: ใบเสร็จของขวัญหุ่นทองคำของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local purchaseId = "gift_" .. tostring(receiptInfo.PurchaseId)
	local saved = false
	local ok, err = pcall(function()
		store:UpdateAsync("inbox_" .. pending.to, function(old)
			local data = readInbox(old)
			if table.find(data.receipts, purchaseId) then
				saved = true
				return nil -- ใบเสร็จนี้นับไปแล้ว
			end
			data.count += 1
			data.fromName = buyer.DisplayName
			table.insert(data.receipts, purchaseId)
			while #data.receipts > 50 do table.remove(data.receipts, 1) end
			saved = true
			return data
		end)
	end)
	if not ok or not saved then
		warn("LuckBoosterGift: บันทึกของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false -- ยังไม่ยืนยัน ให้ Roblox ลองใหม่ (เงินไม่หาย)
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() store:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	local target = Players:GetPlayerByUserId(pending.to)
	if target then task.delay(7, deliver, target) end -- 2026-11-23 รอ 7 วิ กันเขียน inbox_ ซ้ำใน 6 วิ (DataStore เข้าคิว)
	notify(buyer, "🎁 ส่งหุ่นทองคำนำโชคให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖")
	print("🎁 LuckBoosterGift: " .. buyer.Name .. " ส่งหุ่นทองคำนำโชคให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(GIFT_PRODUCT_ID, { name = "ของขวัญหุ่นทองคำนำโชค", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกัน ส่งซ้ำได้ ไม่มีคำว่ามีแล้ว) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
local function giftSelect(player, targetUserId)
	-- Studio: ยังไม่มี ID สินค้า หรือผู้ทดสอบตั้ง Attribute DevGiftSimulate = true (จากฝั่งเซิร์ฟเวอร์) = จำลองการจ่ายเงิน ไม่เรียกหน้าชำระเงินจริง
	local studioTest = RunService:IsStudio() and (GIFT_PRODUCT_ID == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if GIFT_PRODUCT_ID == 0 and not studioTest then return { ok = false, message = "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨" } end
	if type(targetUserId) ~= "number" or targetUserId ~= targetUserId then return { ok = false, message = "คำขอไม่ถูกต้อง" } end
	targetUserId = math.floor(targetUserId)
	if targetUserId == player.UserId then return { ok = false, message = "ส่งให้ตัวเองไม่ได้ (ซื้อให้ตัวเองได้ที่ร้านสุดพิเศษ)" } end
	local started = giftPrompting[player]
	if started and os.clock() - started < GIFT_PROMPT_TIMEOUT then
		return { ok = false, message = "กำลังทำรายการก่อนหน้าอยู่ รอสักครู่" }
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local toName
	if target then
		if target:GetAttribute("InventoryLoaded") == nil then
			return { ok = false, message = "กระเป๋าของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		toName = target.DisplayName
	elseif RunService:IsStudio() and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId -- ทดสอบใน Studio เท่านั้น (ตั้ง Attribute จากฝั่งเซิร์ฟเวอร์)
	else
		return { ok = false, message = "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว" }
	end
	local pending = { to = targetUserId, toName = toName, t = os.time() }
	local okSave, err = pcall(function() store:SetAsync("pending_" .. player.UserId, pending, { player.UserId }) end)
	if not okSave then
		warn("LuckBoosterGift: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("LuckBoosterGift: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, GIFT_PRODUCT_ID)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: หุ่นทองคำนำโชคสำหรับ " .. toName }
end

request.OnServerInvoke = function(player, action, value)
	if action == "giftSelect" then return giftSelect(player, value) end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
end

-- ปิดหน้าจ่ายเงินโดยไม่ซื้อ = เลือกคนใหม่ได้เลย (ซื้อสำเร็จ: รอ grantGift ล้างให้)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if GIFT_PRODUCT_ID == 0 or productId ~= GIFT_PRODUCT_ID or purchased then return end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		giftPending[player] = nil
		giftPrompting[player] = nil
	end
end)

-- เข้าเกม: มีของในกล่องจดหมาย (ได้ตอนออฟไลน์) = ส่งเข้ากระเป๋า
Players.PlayerAdded:Connect(function(player) task.spawn(deliver, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(deliver, player) end
Players.PlayerRemoving:Connect(function(player)
	giftPending[player] = nil
	giftPrompting[player] = nil
	delivering[player] = nil
end)
