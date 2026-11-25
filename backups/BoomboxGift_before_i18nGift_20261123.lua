-- BACKUP of ServerScriptService.BoomboxGift before Thai/English gift messages (i18n phase 2, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.BoomboxGift.Source in Studio
-- BoomboxGift: ส่ง "มิวสิกบ็อกซ์เพนกวิน" ให้เพื่อนเป็นของขวัญ (Developer Product: BoomboxConfig.GIFT_PRODUCT_ID) เพิ่ม 2026-10-08
-- Game Pass ซื้อให้คนอื่นไม่ได้ จึงขายเป็น Developer Product: ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนได้มิวสิกบ็อกซ์ถาวร
-- (แบบเดียวกับ PetSlotGift / หน้าเลือกเพื่อนใช้ของ VipGui ชนิด "boombox")
-- สิทธิ์ถาวรเก็บที่ DataStore "BoomboxPromoEntitlements_v1" (ที่เดียวกับโค้ดแลก Boombox) key = userId:
--   { owned = true, gifts = { [receipt] = { from, fromName, t } }, giftUnseen = true/nil }
-- BoomboxService อ่าน owned ตอนเข้าเกมอยู่แล้ว ผู้รับออนไลน์ = ตั้ง Attribute BoomboxPromoOwned ให้เลย (BoomboxService มอบเพนกวินทันที)
-- "pending_<userId>" ใน DataStore "BoomboxGift_v1" = ผู้รับที่ผู้ซื้อเลือกไว้ { to, toName, t }

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PurchaseRouter = require(script.Parent:WaitForChild("PurchaseRouter"))
local Config = require(ReplicatedStorage:WaitForChild("BoomboxConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local entitlementStore = DataStoreService:GetDataStore("BoomboxPromoEntitlements_v1")
local pendingStore = DataStoreService:GetDataStore("BoomboxGift_v1")
local request = remoteEvents:FindFirstChild("BoomboxGiftRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "BoomboxGiftRequest"
	request.Parent = remoteEvents
end

local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local GIFT_PROMPT_TIMEOUT = 120

local function say(player, th, en) return Localization.Pick(Localization.GetLanguage(player), th, en) end
local function notify(player, text)
	if player and player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

-- PurchaseRouter เรียกตอนจ่ายเงินสำเร็จ: true = มอบและบันทึกแล้ว / false = ยังไม่ยืนยัน (Roblox จะส่งใบเสร็จมาใหม่)
local function grantGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return pendingStore:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("BoomboxGift: ใบเสร็จของขวัญมิวสิกบ็อกซ์ของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local target = Players:GetPlayerByUserId(pending.to)
	local receipt = tostring(receiptInfo.PurchaseId)
	local okSave, saved = pcall(function()
		return entitlementStore:UpdateAsync(tostring(pending.to), function(old)
			old = type(old) == "table" and old or {}
			old.owned = true
			old.gifts = type(old.gifts) == "table" and old.gifts or {}
			if not old.gifts[receipt] then
				old.gifts[receipt] = { from = buyer.UserId, fromName = buyer.DisplayName, t = os.time() }
			end
			old.giftUnseen = target == nil or nil -- ผู้รับออฟไลน์ = แจ้งตอนเข้าเกมครั้งถัดไป
			old.giftFromName = buyer.DisplayName
			old.updatedAt = os.time()
			return old
		end, { pending.to })
	end)
	if not okSave or type(saved) ~= "table" or saved.owned ~= true then
		warn("BoomboxGift: บันทึกของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(saved))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() pendingStore:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	if target then
		target:SetAttribute("BoomboxPromoOwned", true) -- BoomboxService มอบเพนกวินและตั้ง HasBoombox ให้เอง
		notify(target, say(target,
			"🎁 " .. buyer.DisplayName .. " ส่งมิวสิกบ็อกซ์เพนกวินให้คุณเป็นของขวัญ! ใช้ได้ถาวรแล้ว 🐧🎵",
			"🎁 " .. buyer.DisplayName .. " gifted you the Penguin Music Box! It's yours forever 🐧🎵"))
	end
	notify(buyer, say(buyer,
		"🎁 ส่งมิวสิกบ็อกซ์เพนกวินให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖",
		"🎁 Penguin Music Box sent to " .. toName .. ". Thanks for sharing 💖"))
	print("🎁 BoomboxGift: " .. buyer.Name .. " ส่งมิวสิกบ็อกซ์ให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(Config.GIFT_PRODUCT_ID or 0, { name = "ของขวัญมิวสิกบ็อกซ์เพนกวิน", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกันและยังไม่มีมิวสิกบ็อกซ์) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
local function giftSelect(player, targetUserId)
	local productId = Config.GIFT_PRODUCT_ID or 0
	-- Studio: ยังไม่มี ID สินค้า หรือผู้ทดสอบตั้ง Attribute DevGiftSimulate = true (จากฝั่งเซิร์ฟเวอร์) = จำลองการจ่ายเงิน ไม่เรียกหน้าชำระเงินจริง
	local studioTest = RunService:IsStudio() and (productId == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if productId == 0 and not studioTest then return { ok = false, message = say(player, "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨", "Gifting isn't open yet ✨") } end
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
		if target:GetAttribute("HasBoombox") == true then
			return { ok = false, message = say(player, target.DisplayName .. " มีมิวสิกบ็อกซ์อยู่แล้ว", target.DisplayName .. " already has the Music Box") }
		end
		toName = target.DisplayName
	elseif RunService:IsStudio() and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId -- ทดสอบใน Studio เท่านั้น (ตั้ง Attribute จากฝั่งเซิร์ฟเวอร์)
	else
		return { ok = false, message = say(player, "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว", "Your friend is no longer in this server") }
	end
	local pending = { to = targetUserId, toName = toName, t = os.time() }
	local okSave, err = pcall(function() pendingStore:SetAsync("pending_" .. player.UserId, pending, { player.UserId }) end)
	if not okSave then
		warn("BoomboxGift: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = say(player, "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง", "Saving failed, please try again") }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("BoomboxGift: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return { ok = true, message = say(player, "เปิดหน้าชำระเงินแล้ว: มิวสิกบ็อกซ์เพนกวินสำหรับ ", "Payment opened: Penguin Music Box for ") .. toName }
end

request.OnServerInvoke = function(player, action, value)
	if action == "giftSelect" then return giftSelect(player, value) end
	return { ok = false, message = say(player, "คำขอไม่ถูกต้อง", "Invalid request") }
end

-- ปิดหน้าจ่ายเงินโดยไม่ซื้อ = เลือกคนใหม่ได้เลย (ซื้อสำเร็จ: รอ grantGift ล้างให้)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if productId ~= (Config.GIFT_PRODUCT_ID or 0) or productId == 0 or purchased then return end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		giftPrompting[player] = nil
		giftPending[player] = nil
	end
end)

-- ได้รับตอนออฟไลน์: แจ้งครั้งเดียวตอนเข้าเกม (สิทธิ์เอง BoomboxService อ่าน owned ให้อยู่แล้ว)
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function onPlayerAdded(player)
	-- แค่แจ้งของขวัญ ไม่เร่งด่วน: หลีกทางให้ของสำคัญโหลดก่อน (2026-10-13)
	if not DataLoadRetry.Defer(player, "BoomboxGift") then return end
	-- ลองจนได้ (เดิมอ่านครั้งเดียว พัง = ไม่แจ้งของขวัญ) 2026-10-09
	local ok, rec = DataLoadRetry.Load(player, "BoomboxGift", DataLoadRetry.Get(entitlementStore, tostring(player.UserId)))
	if not ok or type(rec) ~= "table" or rec.giftUnseen ~= true then return end
	task.delay(8, function()
		notify(player, say(player,
			"🎁 คุณได้รับมิวสิกบ็อกซ์เพนกวินเป็นของขวัญจาก " .. tostring(rec.giftFromName or "เพื่อน") .. "! 🐧🎵",
			"🎁 You received the Penguin Music Box as a gift from " .. tostring(rec.giftFromName or "a friend") .. "! 🐧🎵"))
	end)
	pcall(function()
		entitlementStore:UpdateAsync(tostring(player.UserId), function(old)
			if type(old) ~= "table" then return nil end
			old.giftUnseen = nil
			return old
		end)
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end

Players.PlayerRemoving:Connect(function(player)
	giftPending[player] = nil
	giftPrompting[player] = nil
end)
