-- BACKUP of ServerScriptService.ScarecrowGhostGift before adding GetAsync pre-check to inbox deliver (2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.ScarecrowGhostGift.Source in Studio
-- ScarecrowGhostGift: ส่งผีน้อยนักปักหุ่นให้เพื่อนเป็นของขวัญ (2026-11-04 ผู้ใช้สั่ง) สินค้า = PremiumPetConfig.Pets.ScarecrowGhost.GiftProductId
-- ลอกจาก PremiumPetGift (ผีน้อยนักปักหุ่น) แยก DataStore/Remote ไม่ให้กระทบกล่องจดหมายเดิม: เพื่อนได้เหมือนซื้อเอง 1 ครั้ง ยังไม่มี = Lv.1 / มีแล้ว = +1 เลเวล · Lv.15 แล้วส่งให้ไม่ได้
-- DataStore "ScarecrowGhostGift_v1": "inbox_<userId>" / "pending_<userId>" · Studio: Attribute DevGiftSimulate บนผู้เล่น (ฝั่งเซิร์ฟเวอร์) = จำลองจ่ายเงิน · DevGiftOffline = ส่งให้ UserId ที่ไม่อยู่ในเซิร์ฟได้

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local PremiumPetConfig = require(ReplicatedStorage:WaitForChild("PremiumPetConfig"))
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))
local PetSystem = ServerScriptService:WaitForChild("PetSystem")
local PetDefinitions = require(PetSystem:WaitForChild("PetDefinitions"))
local PetOwnership = require(PetSystem:WaitForChild("PetOwnership"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local PET_ID = "ScarecrowGhost"
local cfg = PremiumPetConfig.Get(PET_ID)
local GIFT_PRODUCT_ID = (cfg and cfg.GiftProductId) or 0

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local request = remoteEvents:FindFirstChild("ScarecrowGhostGiftRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "ScarecrowGhostGiftRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("ScarecrowGhostGift_v1")
local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local delivering = {}    -- [player] = true
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

local function levelOf(player)
	if not PetOwnership.Owns(player, PET_ID) then return 0 end
	return PetOwnership.GetLevel(player, PET_ID)
end

-- ให้ของในกล่องจดหมาย (ตอนเข้าเกม / หลังมีของขวัญใหม่ถึงผู้รับที่อยู่ในเซิร์ฟ)
local function deliver(player)
	if delivering[player] then return end
	if not (PetDefinitions[PET_ID] and cfg) then return end
	delivering[player] = true
	if not PetOwnership.WaitLoaded(player, 120) then delivering[player] = nil return end
	local from
	for _ = 1, cfg.MaxLevel do
		if not player.Parent then break end
		local take = false
		local ok, err = pcall(function()
			store:UpdateAsync("inbox_" .. player.UserId, function(old)
				take = false
				if type(old) ~= "table" then return nil end
				local data = readInbox(old)
				from = data.fromName
				if data.delivered >= data.count then return nil end
				data.delivered += 1
				take = true
				return data
			end)
		end)
		if not ok then
			warn("ScarecrowGhostGift: เช็กกล่องจดหมาย " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
			break
		end
		if not take then break end
		local result = PetOwnership.GrantPremium(player, PET_ID, cfg.MaxLevel)
		if not result then
			-- เซฟสัตว์ไม่สำเร็จ: คืนของเข้ากล่อง ได้ใหม่ตอนเข้าเกมครั้งหน้า
			pcall(function()
				store:UpdateAsync("inbox_" .. player.UserId, function(old)
					local data = readInbox(old)
					data.delivered = math.max(0, data.delivered - 1)
					return data
				end)
			end)
			warn("ScarecrowGhostGift: ให้ผีน้อยนักปักหุ่น " .. player.Name .. " ไม่สำเร็จ คืนเข้ากล่องจดหมาย")
			break
		end
		local fromText = tostring(from or "เพื่อน")
		if result.isNew then
			notify(player, "🎁👻 ได้รับผีน้อยนักปักหุ่นเป็นของขวัญจาก " .. fromText .. "! พาออกมาได้ที่เมนูสัตว์เลี้ยง 🐾", "🎁👻 " .. fromText .. " gifted you the Scarecrow Ghost! Bring it out from the pet menu 🐾")
		elseif result.maxed then
			warn("ScarecrowGhostGift: " .. player.Name .. " ได้ของขวัญตอนผีน้อยเลเวลเต็มแล้ว (ไม่ได้เพิ่มเลเวล) จาก " .. fromText)
		else
			notify(player, "🎁⬆️ " .. fromText .. " ส่งของขวัญให้! ผีน้อยนักปักหุ่น Lv." .. result.level, "🎁⬆️ Gift from " .. fromText .. "! Scarecrow Ghost Lv." .. result.level)
		end
		print("🎁 ScarecrowGhostGift: ให้ผีน้อยนักปักหุ่น " .. player.Name .. " (Lv." .. tostring(result.level) .. ") จาก " .. fromText)
	end
	delivering[player] = nil
end

-- PurchaseRouter เรียกตอนจ่ายเงินสำเร็จ: true = บันทึกเข้ากล่องจดหมายผู้รับแล้ว / false = ยังไม่ยืนยัน (Roblox ส่งใบเสร็จมาใหม่)
local function grantGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return store:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("ScarecrowGhostGift: ใบเสร็จของขวัญผีน้อยของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local purchaseId = "gift_" .. tostring(receiptInfo.PurchaseId)
	local saved = false
	local ok, err = pcall(function()
		store:UpdateAsync("inbox_" .. pending.to, function(old)
			local data = readInbox(old)
			if table.find(data.receipts, purchaseId) then
				saved = true
				return nil
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
		warn("ScarecrowGhostGift: บันทึกของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() store:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	local target = Players:GetPlayerByUserId(pending.to)
	if target then task.delay(7, deliver, target) end -- 2026-11-23 รอ 7 วิ กันเขียน inbox_ ซ้ำใน 6 วิ (DataStore เข้าคิว)
	notify(buyer, "🎁 ส่งผีน้อยนักปักหุ่นให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖", "🎁 Scarecrow Ghost sent to " .. toName .. ". Thanks for sharing 💖")
	print("🎁 ScarecrowGhostGift: " .. buyer.Name .. " ส่งผีน้อยนักปักหุ่นให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(GIFT_PRODUCT_ID, { name = "ของขวัญผีน้อยนักปักหุ่น", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (อยู่ในเซิร์ฟเดียวกัน ผีน้อยยังไม่เต็ม Lv.15) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
local function giftSelect(player, targetUserId)
	local studioTest = RunService:IsStudio() and (GIFT_PRODUCT_ID == 0 or player:GetAttribute("DevGiftSimulate") == true)
	if GIFT_PRODUCT_ID == 0 and not studioTest then return { ok = false, message = "ยังไม่เปิดให้ส่งของขวัญ เร็วๆ นี้ ✨" } end
	if not (PetDefinitions[PET_ID] and cfg and PremiumPetConfig.IsReleased(PET_ID)) then
		return { ok = false, message = "ผีน้อยนักปักหุ่นยังไม่เปิด " }
	end
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
		if not PetOwnership.WaitLoaded(target, 3) then
			return { ok = false, message = "ข้อมูลสัตว์เลี้ยงของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		if levelOf(target) >= cfg.MaxLevel then
			return { ok = false, message = target.DisplayName .. " มีผีน้อยนักปักหุ่นเลเวลเต็มแล้ว (Lv." .. cfg.MaxLevel .. ")" }
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
		warn("ScarecrowGhostGift: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("ScarecrowGhostGift: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อผีน้อยนักปักหุ่นให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, GIFT_PRODUCT_ID)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: ผีน้อยนักปักหุ่นสำหรับ " .. toName }
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

Players.PlayerAdded:Connect(function(player) task.spawn(deliver, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(deliver, player) end
Players.PlayerRemoving:Connect(function(player)
	giftPending[player] = nil
	giftPrompting[player] = nil
	delivering[player] = nil
end)
