-- BACKUP of game.ServerScriptService.MountSystem.MountBundleShop before delaying gift deliver 7 s (2026-11-23)
-- Restore: paste everything below this header back into the script's Source in Studio.
-- MountBundleShop: ขายแพ็กสัตว์ขี่ + ของแต่ง และส่งให้เพื่อน (2026-11-04 ผู้ใช้สั่ง: ไม้กวาดแมวเหมียวแม่มด + หมวกฟักทองแม่มด) ค่าตั้ง = MountConfig.Bundles
-- ให้ของทุกชิ้นใน GrantBatch ครั้งเดียว (บันทึกพร้อมกัน) · มีแล้วบางชิ้น = ยังซื้อ/รับได้ ได้ชิ้นที่ขาด · มีครบ = ไม่เปิดหน้าซื้อ/ส่งให้ไม่ได้
-- ซื้อ = RemoteEvents.MountBundleBuy(bundleId) · ของขวัญ = RemoteFunction MountBundleGiftRequest (กล่องจดหมายแบบ MountGift)
-- DataStore "MountBundleGift_v1": "inbox_<userId>" = { count, delivered, receipts, fromName } / "pending_<userId>" = { to, toName, t }
-- Studio: workspace DevMountShopSim = กดซื้อแล้วได้ของทันที (ใช้คู่กับคีย์ปลอม DevMountKeyOverride) · DevGiftSimulate / DevGiftOffline บนผู้เล่น = จำลองของขวัญ

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

local BUNDLE_ID = "WitchBroomBundle"
local bundle = MountConfig.Bundles[BUNDLE_ID]
local PRODUCT_ID = bundle.ProductId
local GIFT_PRODUCT_ID = bundle.GiftProductId
local CABINET_TH = "ขี่ได้จากตู้ตกแต่ง 🗄️ แท็บ 🐴 สัตว์ขี่"
local CABINET_EN = "Find it in the 🗄️ Decor Cabinet, 🐴 Mounts tab"

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local buyRemote = remoteEvents:FindFirstChild("MountBundleBuy")
if not buyRemote then
	buyRemote = Instance.new("RemoteEvent")
	buyRemote.Name = "MountBundleBuy"
	buyRemote.Parent = remoteEvents
end
local request = remoteEvents:FindFirstChild("MountBundleGiftRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "MountBundleGiftRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("MountBundleGift_v1")
local giftPending = {}
local giftPrompting = {}
local delivering = {}
local promptOpen = {}
local lastAsk = {}
local GIFT_PROMPT_TIMEOUT = 120

local function notify(player, th, en)
	if player and player.Parent then
		harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(Localization.GetLanguage(player), th, en))
	end
end

local function ownsAll(player)
	for _, mountId in ipairs(bundle.Mounts) do
		if not MountOwnership.Owns(player, mountId) then return false end
	end
	for _, accId in ipairs(bundle.Accessories) do
		if not MountOwnership.OwnsAccessory(player, accId) then return false end
	end
	return true
end

-- ใส่ของทุกชิ้นในแพ็ก คืน true = บันทึกแล้ว (ชิ้นที่มีอยู่แล้วไม่เปลี่ยนแปลง)
local function grantBundle(player)
	if not MountOwnership.WaitLoaded(player, 60) then return false end
	return MountOwnership.GrantBatch(player, bundle.Mounts, 0, bundle.Accessories) ~= nil
end

local function grantPurchase(player)
	if not grantBundle(player) then return false end
	notify(player, "🧹 ได้ " .. bundle.DisplayName .. " แล้ว! " .. CABINET_TH, "🧹 You got the " .. bundle.DisplayNameEn .. "! " .. CABINET_EN)
	return true
end
PurchaseRouter.Register(PRODUCT_ID, { name = "แพ็กไม้กวาดแมวเหมียว", grant = grantPurchase })

buyRemote.OnServerEvent:Connect(function(player, bundleId)
	if bundleId ~= BUNDLE_ID or not MountConfig.IsEnabled() then return end
	local now = os.clock()
	if now - (lastAsk[player] or 0) < 1 then return end
	lastAsk[player] = now
	if not MountOwnership.WaitLoaded(player, 5) then
		notify(player, "กำลังโหลดข้อมูลสัตว์ขี่ ลองใหม่อีกครั้ง", "Still loading your mounts, try again")
		return
	end
	if ownsAll(player) then
		notify(player, "มีของในแพ็กครบแล้ว " .. CABINET_TH, "You already own everything in this pack. " .. CABINET_EN)
		return
	end
	if promptOpen[player] then return end
	if RunService:IsStudio() and workspace:GetAttribute("DevMountShopSim") == true then
		grantPurchase(player) -- จำลองซื้อใน Studio
		return
	end
	promptOpen[player] = true
	MarketplaceService:PromptProductPurchase(player, PRODUCT_ID)
end)

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
			data.delivered = data.count -- ของในแพ็กมีชิ้นเดียวต่อบัญชี ส่งซ้ำหลายใบก็ให้ครั้งเดียว
			take = true
			return data
		end)
	end)
	if not ok then
		warn("MountBundleShop: เช็กกล่องจดหมาย " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
	elseif take then
		local fromText = tostring(from or "เพื่อน")
		if grantBundle(player) then
			notify(player, "🎁🧹 ได้รับ " .. bundle.DisplayName .. " เป็นของขวัญจาก " .. fromText .. "! " .. CABINET_TH, "🎁🧹 " .. fromText .. " gifted you the " .. bundle.DisplayNameEn .. "! " .. CABINET_EN)
			print("🎁 MountBundleShop: ให้แพ็ก " .. player.Name .. " จาก " .. fromText)
		else
			pcall(function()
				store:UpdateAsync("inbox_" .. player.UserId, function(old)
					local data = readInbox(old)
					data.delivered = math.max(0, data.count - 1)
					return data
				end)
			end)
			warn("MountBundleShop: ให้แพ็ก " .. player.Name .. " ไม่สำเร็จ คืนเข้ากล่องจดหมาย")
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
		warn("MountBundleShop: ใบเสร็จของขวัญของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
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
		warn("MountBundleShop: บันทึกของขวัญไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() store:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	local target = Players:GetPlayerByUserId(pending.to)
	if target then task.spawn(deliver, target) end
	notify(buyer, "🎁 ส่งแพ็กไม้กวาดให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖", "🎁 Broom pack sent to " .. toName .. ". Thanks for sharing 💖")
	print("🎁 MountBundleShop: " .. buyer.Name .. " ส่งแพ็กให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(GIFT_PRODUCT_ID, { name = "ของขวัญแพ็กไม้กวาดแมวเหมียว", grant = grantGift })

local function giftSelect(player, targetUserId)
	local studioTest = RunService:IsStudio() and player:GetAttribute("DevGiftSimulate") == true
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
		if ownsAll(target) then
			return { ok = false, message = target.DisplayName .. " มีของในแพ็กครบแล้ว" }
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
		warn("MountBundleShop: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("MountBundleShop: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อแพ็กให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, GIFT_PRODUCT_ID)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: แพ็กไม้กวาดสำหรับ " .. toName }
end

request.OnServerInvoke = function(player, action, value)
	if action == "giftSelect" then return giftSelect(player, value) end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end
	if productId == PRODUCT_ID then promptOpen[player] = nil end
	if productId == GIFT_PRODUCT_ID and not purchased then
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
	promptOpen[player] = nil
	lastAsk[player] = nil
end)
