-- BACKUP of ServerScriptService.PetSlotGift before Thai/English gift messages (i18n phase 2, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.PetSlotGift.Source in Studio
-- PetSlotGift: ส่ง "ช่องสัตว์ +1" ให้เพื่อนเป็นของขวัญ (Developer Product: PetSlotConfig.GIFT_PRODUCT_ID)
-- Game Pass ซื้อให้คนอื่นไม่ได้ จึงขายเป็น Developer Product: ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนพาสัตว์ออกมาได้ 3 ตัวถาวร
-- (แบบเดียวกับของขวัญ VIP ใน VipService / แพ็กสุลต่านใน SultanService)
-- DataStore "PetSlotGift_v1": "to_<userId>" = { from, fromName, t, receipt, seen } (PetManager.checkPetSlots เรียก HasGift ตอนเข้าเกม)
--                            "pending_<userId>" = { to, toName, t } (ผู้ซื้อเลือกผู้รับไว้)
-- Attribute "PetSlots" บนตัวผู้เล่น = ตัวตัดสินจำนวนช่อง (PetManager.maxActivePets) ตอนส่งสำเร็จให้ผู้รับที่อยู่ในเซิร์ฟเวอร์ ตั้งค่านี้ตรงๆ

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PurchaseRouter = require(script.Parent:WaitForChild("PurchaseRouter"))
local Config = require(ReplicatedStorage:WaitForChild("PetSlotConfig"))
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local store = DataStoreService:GetDataStore("PetSlotGift_v1")
local DataLoadRetry = require(script.Parent:WaitForChild("DataLoadRetry"))
local request = remoteEvents:FindFirstChild("PetSlotGiftRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "PetSlotGiftRequest"
	request.Parent = remoteEvents
end

local PetSlotGift = {}

local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local GIFT_PROMPT_TIMEOUT = 120

local function notify(player, text)
	if player and player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

local function hasExtraSlot(player)
	return (player:GetAttribute("PetSlots") or Config.BASE_SLOTS) > Config.BASE_SLOTS
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
		warn("PetSlotGift: ใบเสร็จของขวัญช่องสัตว์ของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local target = Players:GetPlayerByUserId(pending.to)
	local record = {
		from = buyer.UserId, fromName = buyer.DisplayName, t = os.time(),
		receipt = tostring(receiptInfo.PurchaseId), seen = target ~= nil,
	}
	local okSave, err = pcall(function() store:SetAsync("to_" .. pending.to, record, { pending.to }) end)
	if not okSave then
		warn("PetSlotGift: บันทึกของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() store:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	if target then
		target:SetAttribute("PetSlots", Config.BASE_SLOTS + Config.BONUS_SLOTS)
		notify(target, "🎁 " .. buyer.DisplayName .. " ส่งช่องสัตว์ +1 ให้คุณเป็นของขวัญ! พาสัตว์ออกมาได้ " .. (Config.BASE_SLOTS + Config.BONUS_SLOTS) .. " ตัวพร้อมกันแล้ว 🐾")
	end
	notify(buyer, "🎁 ส่งช่องสัตว์ +1 ให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖")
	print("🎁 PetSlotGift: " .. buyer.Name .. " ส่งช่องสัตว์ +1 ให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(Config.GIFT_PRODUCT_ID or 0, { name = "ของขวัญช่องสัตว์ +1", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกันและยังไม่มีช่องสัตว์ +1) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
local function giftSelect(player, targetUserId)
	local productId = Config.GIFT_PRODUCT_ID or 0
	-- Studio: ยังไม่มี ID สินค้า หรือผู้ทดสอบตั้ง Attribute DevGiftSimulate = true (จากฝั่งเซิร์ฟเวอร์) = จำลองการจ่ายเงิน ไม่เรียกหน้าชำระเงินจริง
	local studioTest = RunService:IsStudio() and (productId == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if productId == 0 and not studioTest then return { ok = false, message = "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨" } end
	if type(targetUserId) ~= "number" or targetUserId ~= targetUserId then return { ok = false, message = "คำขอไม่ถูกต้อง" } end
	targetUserId = math.floor(targetUserId)
	if targetUserId == player.UserId then return { ok = false, message = "ส่งให้ตัวเองไม่ได้" } end
	local started = giftPrompting[player]
	if started and os.clock() - started < GIFT_PROMPT_TIMEOUT then
		return { ok = false, message = "กำลังทำรายการก่อนหน้าอยู่ รอสักครู่" }
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local toName
	if target then
		if target:GetAttribute("PetSlots") == nil then
			return { ok = false, message = "ข้อมูลของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		if hasExtraSlot(target) then
			return { ok = false, message = target.DisplayName .. " มีช่องสัตว์ +1 อยู่แล้ว" }
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
		warn("PetSlotGift: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("PetSlotGift: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: ช่องสัตว์ +1 สำหรับ " .. toName }
end

request.OnServerInvoke = function(player, action, value)
	if action == "giftSelect" then return giftSelect(player, value) end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
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

Players.PlayerRemoving:Connect(function(player)
	giftPending[player] = nil
	giftPrompting[player] = nil
end)

-- PetManager.checkPetSlots เรียกตอนเข้าเกม: มีบันทึกของขวัญ = ได้ช่องสัตว์ +1 (ครั้งแรกหลังได้รับตอนออฟไลน์ แจ้งผู้ได้รับหนึ่งครั้ง)
function PetSlotGift.HasGift(player)
	for attempt = 1, 3 do
		DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
		local ok, rec = pcall(function() return store:GetAsync("to_" .. player.UserId) end)
		if ok then
			if type(rec) ~= "table" then return false end
			if rec.seen ~= true then
				rec.seen = true
				task.delay(8, notify, player, "🎁 คุณได้รับช่องสัตว์ +1 เป็นของขวัญจาก " .. tostring(rec.fromName or "เพื่อน") .. "! พาสัตว์ออกมาได้ 3 ตัวแล้ว 🐾")
				task.spawn(function()
					pcall(function()
						store:UpdateAsync("to_" .. player.UserId, function(old)
							if type(old) ~= "table" then return nil end
							old.seen = true
							return old
						end)
					end)
				end)
			end
			return true
		end
		warn("PetSlotGift: เช็กของขวัญช่องสัตว์ไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(rec))
		task.wait(2)
	end
	-- ไม่ผ่าน 3 ครั้ง (DataStore throttle): ไม่รอ (PetManager กำลังกู้สัตว์) ลองต่อเบื้องหลัง เจอของขวัญเมื่อไหร่เพิ่มช่องให้เลย (2026-10-09)
	DataLoadRetry.Background(player, "PetSlotGift", DataLoadRetry.Get(store, "to_" .. player.UserId), function(rec)
		if type(rec) ~= "table" then return end
		player:SetAttribute("PetSlots", Config.BASE_SLOTS + Config.BONUS_SLOTS)
		if rec.seen ~= true then
			task.delay(3, notify, player, "🎁 คุณได้รับช่องสัตว์ +1 เป็นของขวัญจาก " .. tostring(rec.fromName or "เพื่อน") .. "! พาสัตว์ออกมาได้ 3 ตัวแล้ว 🐾")
			pcall(function()
				store:UpdateAsync("to_" .. player.UserId, function(old)
					if type(old) ~= "table" then return nil end
					old.seen = true
					return old
				end)
			end)
		end
	end)
	return false
end

return PetSlotGift
