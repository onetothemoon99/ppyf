-- BACKUP of game.ServerScriptService.MountSystem.MountGift before delaying gift deliver 7 s (2026-11-23)
-- Restore: paste everything below this header back into the script's Source in Studio.
-- MountGift: ส่ง "ลามะไม่ลานะ" (สัตว์ขี่ Game Pass) ให้เพื่อนเป็นของขวัญ (2026-10-19 ผู้ใช้ขอ) สินค้า = MountConfig.Mounts.MagicLlama.Shop.GiftProductId
-- Game Pass ส่งให้คนอื่นไม่ได้ จึงใช้ Developer Product แทน: เพื่อนได้ลามะถาวรในข้อมูลสัตว์ขี่ (MountOwnership) เหมือนสุ่มได้
-- เก็บใน "กล่องจดหมาย" ก่อน (แบบ PremiumPetGift) แล้วค่อยให้ตอนข้อมูลสัตว์ขี่ของผู้รับโหลดเสร็จ ผู้รับออกเกมก่อนก็ได้ตอนเข้าเกมครั้งถัดไป
-- DataStore "MountGift_v1": "inbox_<userId>" = { count, delivered, receipts, fromName } / "pending_<userId>" = { to, toName, t }
-- ส่งให้เพื่อนที่มีลามะแล้วไม่ได้ · ระบบสัตว์ขี่ปิด (MountConfig.Enabled) = ส่งไม่ได้ ของในกล่องรอจนเปิด
-- Studio: GiftProductId = 0 หรือ Attribute DevGiftSimulate = true บนผู้เล่น (ฝั่งเซิร์ฟเวอร์) = จำลองจ่ายเงิน · DevGiftOffline = ส่งให้ UserId ที่ไม่อยู่ในเซิร์ฟได้

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig"))
local MountOwnership = require(script.Parent:WaitForChild("MountOwnership"))
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local MOUNT_ID = "MagicLlama"
local def = MountConfig.Mounts[MOUNT_ID]
local GIFT_PRODUCT_ID = (def and def.Shop and def.Shop.GiftProductId) or 0

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local request = remoteEvents:FindFirstChild("MountGiftRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "MountGiftRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("MountGift_v1")
local giftPending = {}
local giftPrompting = {}
local delivering = {}
local GIFT_PROMPT_TIMEOUT = 120

local function notify(player, th, en)
	if player and player.Parent then
		harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(Localization.GetLanguage(player), th, en))
	end
end

local function readInbox(old)
	if type(old) ~= "table" then old = {} end
	old.count = math.max(0, math.floor(tonumber(old.count) or 0))
	old.delivered = math.max(0, math.floor(tonumber(old.delivered) or 0))
	old.receipts = type(old.receipts) == "table" and old.receipts or {}
	return old
end

local function deliver(player)
	if delivering[player] or not MountConfig.IsEnabled() then return end
	delivering[player] = true
	if not MountOwnership.WaitLoaded(player, 120) then delivering[player] = nil return end
	local take, from = false, nil
	local ok, err = pcall(function()
		store:UpdateAsync("inbox_" .. player.UserId, function(old)
			take = false
			if type(old) ~= "table" then return nil end
			local data = readInbox(old)
			from = data.fromName
			if data.delivered >= data.count then return nil end
			data.delivered = data.count -- ลามะมีตัวเดียว ส่งซ้ำหลายใบก็ให้ครั้งเดียว
			take = true
			return data
		end)
	end)
	if not ok then
		warn("MountGift: เช็กกล่องจดหมาย " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
	elseif take then
		local results = MountOwnership.GrantBatch(player, { MOUNT_ID }, 0)
		local fromText = tostring(from or "เพื่อน")
		if not results then
			pcall(function()
				store:UpdateAsync("inbox_" .. player.UserId, function(old)
					local data = readInbox(old)
					data.delivered = math.max(0, data.count - 1)
					return data
				end)
			end)
			warn("MountGift: ให้ลามะ " .. player.Name .. " ไม่สำเร็จ คืนเข้ากล่องจดหมาย")
		elseif results[1] and results[1].isNew then
			notify(player, "🎁🦙 ได้รับลามะไม่ลานะเป็นของขวัญจาก " .. fromText .. "! ขี่ได้จากตู้ตกแต่ง 🗄️ แท็บ 🐴 สัตว์ขี่", "🎁🦙 " .. fromText .. " gifted you the Never-Goodbye Llama! Ride it from the 🗄️ Decor Cabinet, 🐴 Mounts tab")
			print("🎁 MountGift: ให้ลามะ " .. player.Name .. " จาก " .. fromText)
		else
			warn("MountGift: " .. player.Name .. " มีลามะอยู่แล้วตอนได้ของขวัญจาก " .. fromText)
		end
	end
	delivering[player] = nil
end

local function grantGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return store:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("MountGift: ใบเสร็จของขวัญลามะของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local purchaseId = "gift_" .. tostring(receiptInfo.PurchaseId)
	local saved = false
	local ok, err = pcall(function()
		store:UpdateAsync("inbox_" .. pending.to, function(old)
			local data = readInbox(old)
			if table.find(data.receipts, purchaseId) then saved = true return nil end
			data.count += 1
			data.fromName = buyer.DisplayName
			table.insert(data.receipts, purchaseId)
			while #data.receipts > 50 do table.remove(data.receipts, 1) end
			saved = true
			return data
		end)
	end)
	if not ok or not saved then
		warn("MountGift: บันทึกของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() store:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	local target = Players:GetPlayerByUserId(pending.to)
	if target then task.spawn(deliver, target) end
	notify(buyer, "🎁 ส่งลามะไม่ลานะให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖", "🎁 Llama sent to " .. toName .. ". Thanks for sharing 💖")
	print("🎁 MountGift: " .. buyer.Name .. " ส่งลามะให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
if GIFT_PRODUCT_ID ~= 0 then
	PurchaseRouter.Register(GIFT_PRODUCT_ID, { name = "ของขวัญลามะไม่ลานะ", grant = grantGift })
end

local function giftSelect(player, targetUserId)
	local studioTest = RunService:IsStudio() and (GIFT_PRODUCT_ID == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if GIFT_PRODUCT_ID == 0 and not studioTest then return { ok = false, message = "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨" } end
	if not MountConfig.IsEnabled() then return { ok = false, message = "ระบบสัตว์ขี่ยังไม่เปิด" } end
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
		if not MountOwnership.WaitLoaded(target, 3) then
			return { ok = false, message = "ข้อมูลสัตว์ขี่ของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		if MountOwnership.Owns(target, MOUNT_ID) then
			return { ok = false, message = target.DisplayName .. " มีลามะไม่ลานะแล้ว" }
		end
		toName = target.DisplayName
	elseif RunService:IsStudio() and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId
	else
		return { ok = false, message = "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว" }
	end
	local pending = { to = targetUserId, toName = toName, t = os.time() }
	local okSave, err = pcall(function() store:SetAsync("pending_" .. player.UserId, pending, { player.UserId }) end)
	if not okSave then
		warn("MountGift: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("MountGift: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อลามะให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, GIFT_PRODUCT_ID)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: ลามะไม่ลานะสำหรับ " .. toName }
end

request.OnServerInvoke = function(player, action, value)
	if action == "giftSelect" then return giftSelect(player, value) end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if GIFT_PRODUCT_ID == 0 or productId ~= GIFT_PRODUCT_ID or purchased then return end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		giftPending[player] = nil
		giftPrompting[player] = nil
	end
end)

-- โค้ดลามะ RM-XXXXXX (2026-10-19): SultanService เรียก ServerScriptService.MountPromoGrant:Invoke(player, "check"|"grant")
-- check คืน "disabled" / "loading" / true (มีแล้ว) / false · grant คืน true เมื่อบันทึกสำเร็จ
local promoGrant = ServerScriptService:FindFirstChild("MountPromoGrant")
if not promoGrant then
	promoGrant = Instance.new("BindableFunction")
	promoGrant.Name = "MountPromoGrant"
	promoGrant.Parent = ServerScriptService
end
promoGrant.OnInvoke = function(player, action)
	if not MountConfig.IsEnabled() then return "disabled" end
	if not MountOwnership.WaitLoaded(player, 10) then return "loading" end
	if action == "check" then return MountOwnership.Owns(player, MOUNT_ID) end
	if action == "grant" then
		local results = MountOwnership.GrantBatch(player, { MOUNT_ID }, 0)
		return results ~= nil
	end
	return nil
end

Players.PlayerAdded:Connect(function(player) task.spawn(deliver, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(deliver, player) end
Players.PlayerRemoving:Connect(function(player)
	giftPending[player] = nil
	giftPrompting[player] = nil
	delivering[player] = nil
end)
