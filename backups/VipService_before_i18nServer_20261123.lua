-- BACKUP of ServerScriptService.VipService before Thai/English player messages (i18n phase 1, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.VipService.Source in Studio
-- VipService: VIP (Game Pass ReplicatedStorage.VipConfig) ตั้งสถานะเหนือหัวได้เอง
-- DataStore "VipTitle_v1": { title = ข้อความที่พิมพ์ (ยังไม่กรอง), color = id สี, show = แสดงสถานะไหม }
-- ทุกครั้งที่จะขึ้นป้าย (บันทึกใหม่ / เข้าเกม) ต้องผ่านตัวกรองของ Roblox (TextService) ก่อน กรองไม่ได้ = ไม่แสดง
-- ผลลัพธ์อยู่ใน Attribute ของผู้เล่น: IsVip, VipTitle (กรองแล้ว, "" = ไม่แสดง), VipTitleColor -> PlayerNameTags วาดป้าย / VipClient ใส่แท็กแชต
-- ความเป็นเจ้าของ: เช็กตอนเข้าเกม + ตอนซื้อสำเร็จในเกม (แบบเดียวกับ AutoFeeder)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("VipConfig"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local request = remoteEvents:FindFirstChild("VipRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "VipRequest"
	request.Parent = remoteEvents
end

local PurchaseRouter = require(game:GetService("ServerScriptService"):WaitForChild("PurchaseRouter"))

local store = DataStoreService:GetDataStore("VipTitle_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local giftStore = DataStoreService:GetDataStore("VipGift_v1") -- ของขวัญ VIP (ดูหัวข้อ "ของขวัญ VIP" ด้านล่าง)
local giftSelect -- นิยามด้านล่าง (ต้องใช้ grant)

local states = {} -- [player] = { owned, loaded, data, lastEdit }
local busy = {}

local function notify(player, text)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.title = type(d.title) == "string" and d.title or ""
	d.color = Config.GetColor(d.color) and d.color or Config.DEFAULT_COLOR
	d.show = d.show ~= false
	return d
end

-- กรองข้อความสำหรับให้ทุกคนเห็น (ป้ายเหนือหัว) คืน nil ถ้ากรองไม่สำเร็จ
local function filterForEveryone(player, text)
	if text == "" then return "" end
	for attempt = 1, 2 do
		local ok, result = pcall(function()
			local filtered = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
			return filtered:GetNonChatStringForBroadcastAsync()
		end)
		if ok and type(result) == "string" then return result end
		warn("VipService: กรองข้อความไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(result))
		task.wait(1)
	end
	return nil
end

-- ตัวกรองของ Roblox ปิดข้อความทั้งหมด (เหลือแต่ ####) เช่นข้อความที่มีตัวเลข ในเกมจริงเข้มกว่าใน Studio (Studio ไม่กรอง)
-- ป้าย "##############" เหนือหัวดูเหมือนบั๊ก: ไม่แสดงป้ายแทน + บอกเจ้าของให้เปลี่ยนข้อความ
local function fullyBlocked(text)
	return type(text) == "string" and text ~= "" and text:gsub("[#%s]", "") == ""
end
local BLOCKED_MESSAGE = "สถานะของคุณถูกตัวกรองข้อความของ Roblox ปิดไว้ทั้งหมด จึงไม่แสดงเหนือหัว · กดปุ่ม VIP เปลี่ยนข้อความ (เลี่ยงตัวเลขหรือคำที่อาจถูกกรอง)"

-- 2026-10-21 (ผู้ใช้: เปลี่ยนเครื่อง/ล็อกอินใหม่ สถานะไม่แสดง ต้องกดบันทึกใหม่): ตัวกรองของ Roblox มักล้มช่วงเพิ่งเข้าเกม
--   เดิมลอง 2 ครั้งแล้วเลิก = ไม่มีป้ายทั้งรอบเล่น · ตอนนี้กรองไม่ได้ = ลองใหม่เบื้องหลังเรื่อยๆ (RETRY_DELAYS) จนกว่าจะขึ้นป้ายได้
local RETRY_DELAYS = { 3, 5, 10, 20, 30, 60, 120 }
local publish
local function scheduleRetry(player, st)
	if st.retrying then return end
	st.retrying = true
	task.spawn(function()
		for i, delay in ipairs(RETRY_DELAYS) do
			task.wait(delay)
			if not player.Parent or states[player] ~= st then return end
			st.retrying = false
			local result = publish(player, st, true)
			if result ~= nil then
				if i > 1 then print("👑 VipService: ขึ้นสถานะของ " .. player.Name .. " ได้หลังลองกรองใหม่ " .. i .. " รอบ") end
				return
			end
			st.retrying = true
		end
		st.retrying = false
		warn("VipService: กรองสถานะของ " .. player.Name .. " ไม่สำเร็จทุกรอบ ไม่แสดงป้ายรอบนี้")
	end)
end

-- ตั้ง Attribute ให้ป้ายชื่อ/แชตใช้ (กรองข้อความใหม่ทุกครั้ง) คืนข้อความที่กรองแล้ว (nil = กรองไม่ได้ จะลองใหม่เองเบื้องหลัง)
function publish(player, st, isRetry)
	if not player.Parent then return nil end
	player:SetAttribute("IsVip", st.owned == true)
	local d = st.data
	if not (st.owned and d) then
		player:SetAttribute("VipTitle", "")
		return ""
	end
	player:SetAttribute("VipTitleColor", d.color)
	if not d.show or d.title == "" then
		player:SetAttribute("VipTitle", "")
		return ""
	end
	local filtered = filterForEveryone(player, d.title)
	if fullyBlocked(filtered) then
		if player.Parent then player:SetAttribute("VipTitle", "") end
		if not st.blockedNotified then
			st.blockedNotified = true
			task.delay(8, notify, player, BLOCKED_MESSAGE) -- รอหน้าจอผู้เล่นโหลดเสร็จก่อนแจ้ง
		end
		return ""
	end
	if player.Parent then player:SetAttribute("VipTitle", filtered or "") end
	if filtered == nil and not isRetry then scheduleRetry(player, st) end
	return filtered
end

local function infoFor(player, st)
	return {
		owned = st.owned == true,
		loaded = st.loaded == true,
		passId = Config.GAMEPASS_ID,
		giftProductId = Config.GIFT_PRODUCT_ID or 0,
		title = st.data and st.data.title or "",
		color = st.data and st.data.color or Config.DEFAULT_COLOR,
		show = not st.data or st.data.show,
		shown = player:GetAttribute("VipTitle") or "",
		cooldown = st.lastEdit and math.max(0, math.ceil(Config.EDIT_COOLDOWN - (os.clock() - st.lastEdit))) or 0,
	}
end

local function save(player, st, title, color, show)
	if type(color) ~= "string" or not Config.GetColor(color) then return { ok = false, message = "สีไม่ถูกต้อง" } end
	if Config.GetColor(color).sultan and player:GetAttribute("IsSultan") ~= true then
		return { ok = false, message = "👑 สีนี้สำหรับแพ็กสุลต่านเท่านั้น" }
	end
	title = Config.Clean(title)
	if #title > 200 then return { ok = false, message = "สถานะยาวเกินไป" } end
	local count = Config.CountChars(title)
	if count == nil then return { ok = false, message = "มีตัวอักษรที่ใช้ไม่ได้" } end
	if count > Config.MAX_TITLE_LENGTH then
		return { ok = false, message = "สถานะยาวได้ไม่เกิน " .. Config.MAX_TITLE_LENGTH .. " ตัวอักษร" }
	end
	if st.lastEdit and os.clock() - st.lastEdit < Config.EDIT_COOLDOWN then
		return { ok = false, message = "รออีก " .. math.ceil(Config.EDIT_COOLDOWN - (os.clock() - st.lastEdit)) .. " วินาทีแล้วค่อยบันทึกใหม่" }
	end

	-- เช็กตัวกรองก่อนบันทึก ถ้าระบบกรองล่ม ไม่บันทึก (จะได้ไม่เก็บข้อความที่แสดงไม่ได้)
	local filtered = filterForEveryone(player, title)
	if filtered == nil then return { ok = false, message = "ระบบกรองข้อความไม่ตอบสนอง ลองใหม่อีกครั้ง" } end
	if fullyBlocked(filtered) then
		-- ถูกกรองทั้งข้อความ: ไม่บันทึก (ไม่งั้นป้ายจะเป็น #### ทั้งแถว)
		return { ok = false, message = "ข้อความนี้ถูกตัวกรองของ Roblox ปิดทั้งหมด ลองข้อความอื่น (เลี่ยงตัวเลขหรือคำที่อาจถูกกรอง)" }
	end

	local newData = { title = title, color = color, show = show == true }
	local ok, err = pcall(function() store:SetAsync(tostring(player.UserId), newData, { player.UserId }) end)
	if not ok then
		warn("VipService: บันทึกไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	st.data = newData
	st.lastEdit = os.clock()
	-- ใช้ผลกรองที่ได้แล้ว ไม่ต้องกรองซ้ำ
	player:SetAttribute("VipTitleColor", color)
	player:SetAttribute("VipTitle", (newData.show and title ~= "") and filtered or "")
	local wasFiltered = filtered ~= title
	return {
		ok = true,
		filtered = wasFiltered,
		message = wasFiltered and "บันทึกแล้ว แต่ข้อความบางส่วนถูกกรอง (###)" or "บันทึกสถานะแล้ว ✨",
	}
end

request.OnServerInvoke = function(player, action, title, color, show)
	local st = states[player]
	if not st then return { ok = false, message = "ยังโหลดไม่เสร็จ" } end
	if busy[player] then return { ok = false, message = "กำลังทำรายการก่อนหน้าอยู่", info = infoFor(player, st) } end
	busy[player] = true
	local ok, result = pcall(function()
		if action == "info" then return { ok = true } end
		if action == "giftSelect" then return giftSelect(player, title) end -- ส่ง VIP ให้เพื่อน (ไม่ต้องมี VIP เองก็ส่งได้)
		if not st.loaded then return { ok = false, message = "ยังโหลดข้อมูล VIP ไม่เสร็จ ลองใหม่อีกครั้ง" } end
		if not st.owned then return { ok = false, message = "ต้องมี VIP ก่อน (Game Pass)" } end
		if action == "save" then return save(player, st, title, color, show) end
		return { ok = false, message = "คำขอไม่ถูกต้อง" }
	end)
	busy[player] = nil
	if not ok then
		warn("VipService: คำขอ " .. tostring(action) .. " ของ " .. player.Name .. " ผิดพลาด: " .. tostring(result))
		result = { ok = false, message = "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง" }
	end
	result.info = infoFor(player, st)
	return result
end

-- ============ VIP พิเศษ (ผู้สร้างมอบให้ ไม่ต้องซื้อบัตร) ============
-- เพิ่ม UserId ตรงนี้ = ได้สิทธิ์ VIP ทุกอย่างเหมือนซื้อบัตร (อยู่ฝั่งเซิร์ฟเวอร์ ผู้เล่นแก้เองไม่ได้) ต้อง Publish ถึงจะมีผลในเกมจริง
local GIFTED_VIP = {
	[11646315279] = "a_valinnn", -- มอบให้ 2026-09-30
	[11611605711] = "CtrlZ_2", -- มอบให้ 2026-10-14 (ชื่อที่แสดง XxLemoNxX)
}

-- ============ ความเป็นเจ้าของ Game Pass ============
local function checkOwnership(player, st)
	if Config.GAMEPASS_ID == 0 then return end -- ยังไม่ได้ใส่ ID
	for attempt = 1, 3 do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GAMEPASS_ID)
		end)
		if ok then
			st.owned = owns or st.owned
			return
		end
		warn("VipService: เช็ก Game Pass ไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(owns))
		task.wait(3)
	end
end

local function grant(player, st)
	if st.owned then return end
	st.owned = true
	publish(player, st)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if Config.GAMEPASS_ID == 0 or passId ~= Config.GAMEPASS_ID or not purchased then return end
	local st = states[player]
	if not st then return end
	grant(player, st)
	notify(player, "\u{200B}ยินดีต้อนรับ VIP! ตั้งสถานะเหนือหัวได้ที่ปุ่ม VIP มุมขวาบน") -- \u{200B} = ไม่ต้องเติม ⚠️ นำหน้า (HarvestNotifyGui.withWarnIcon)
	print("👑 VipService: " .. player.Name .. " ซื้อ VIP แล้ว")
end)

-- ============ ของขวัญ VIP (Developer Product: VipConfig.GIFT_PRODUCT_ID) ============
-- Game Pass ซื้อให้คนอื่นไม่ได้ จึงขายเป็น Developer Product: ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> บันทึกว่าเพื่อนได้ VIP (ถาวร)
-- DataStore "VipGift_v1" (giftStore ประกาศไว้ด้านบน):
--   "to_<userId>"      = { from, fromName, t, receipt, seen } คนนี้ได้ VIP จากของขวัญ (เช็กตอนเข้าเกมใน checkGift)
--   "pending_<userId>" = { to, toName, t } ผู้ซื้อเลือกผู้รับไว้แล้ว (จำไว้เผื่อใบเสร็จมาถึงตอนกลับเข้าเกมรอบหน้า)
local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน (กันเลือกคนใหม่ทับระหว่างรอใบเสร็จ)
local GIFT_PROMPT_TIMEOUT = 120

-- PurchaseRouter เรียกตอนจ่ายเงินสำเร็จ: true = มอบและบันทึกแล้ว / false = ยังไม่ยืนยัน (Roblox จะส่งใบเสร็จมาใหม่)
local function grantGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return giftStore:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("VipService: ใบเสร็จของขวัญ VIP ของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local target = Players:GetPlayerByUserId(pending.to)
	local record = {
		from = buyer.UserId, fromName = buyer.DisplayName, t = os.time(),
		receipt = tostring(receiptInfo.PurchaseId), seen = target ~= nil,
	}
	local okSave, err = pcall(function() giftStore:SetAsync("to_" .. pending.to, record, { pending.to }) end)
	if not okSave then
		warn("VipService: บันทึกของขวัญ VIP ไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() giftStore:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	if target then
		local tst = states[target]
		if tst then
			tst.gift = record
			grant(target, tst)
		end
		notify(target, "🎁 " .. buyer.DisplayName .. " ส่ง VIP ให้คุณเป็นของขวัญ! ตั้งสถานะเหนือหัวได้ที่ปุ่ม VIP มุมขวาบน")
	end
	notify(buyer, "🎁 ส่ง VIP ให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖")
	print("🎁 VipService: " .. buyer.Name .. " ส่ง VIP ให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(Config.GIFT_PRODUCT_ID or 0, { name = "ของขวัญ VIP", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกันและยังไม่มี VIP) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
giftSelect = function(player, targetUserId)
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
		local tst = states[target]
		if not (tst and tst.loaded) or target:GetAttribute("IsVip") == nil then
			return { ok = false, message = "ข้อมูลของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		if target:GetAttribute("IsVip") == true or target:GetAttribute("IsSultan") == true then
			return { ok = false, message = target.DisplayName .. " มี VIP อยู่แล้ว" }
		end
		toName = target.DisplayName
	elseif RunService:IsStudio() and player:GetAttribute("DevGiftOffline") == true then
		toName = "UserId " .. targetUserId -- ทดสอบใน Studio เท่านั้น (ตั้ง Attribute จากฝั่งเซิร์ฟเวอร์)
	else
		return { ok = false, message = "เพื่อนไม่ได้อยู่ในเซิร์ฟเวอร์นี้แล้ว" }
	end
	local pending = { to = targetUserId, toName = toName, t = os.time() }
	local okSave, err = pcall(function() giftStore:SetAsync("pending_" .. player.UserId, pending, { player.UserId }) end)
	if not okSave then
		warn("VipService: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		-- Studio (ยังไม่ได้ใส่ ID สินค้า): จำลองว่าจ่ายเงินสำเร็จ เพื่อทดสอบการมอบ VIP
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("VipService: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: VIP สำหรับ " .. toName }
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

-- เข้าเกม: มีบันทึกของขวัญ = ได้ VIP
local function checkGift(player, st)
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = คนที่ได้ VIP เป็นของขวัญไม่ได้ VIP รอบนั้น) 2026-10-09
	local ok, rec = DataLoadRetry.Load(player, "VipService(gift)", DataLoadRetry.Get(giftStore, "to_" .. player.UserId), function() return states[player] == st end)
	if ok and type(rec) == "table" then
		st.owned = true
		st.gift = rec
	end
end

-- ได้ของขวัญตอนไม่ได้อยู่ในเกม: แจ้งครั้งแรกที่เข้ามา แล้วจำว่าแจ้งแล้ว
local function announceGift(player, st)
	local rec = st.gift
	if not (rec and rec.seen ~= true) then return end
	rec.seen = true
	task.delay(8, notify, player, "🎁 คุณได้รับ VIP เป็นของขวัญจาก " .. tostring(rec.fromName or "เพื่อน") .. "! ตั้งสถานะเหนือหัวได้ที่ปุ่ม VIP มุมขวาบน")
	pcall(function()
		giftStore:UpdateAsync("to_" .. player.UserId, function(old)
			if type(old) ~= "table" then return nil end
			old.seen = true
			return old
		end)
	end)
end

local function onPlayerAdded(player)
	local st = { owned = false, loaded = false, data = nil, lastEdit = nil }
	states[player] = st
	local ownDone = false
	task.spawn(function() checkOwnership(player, st); checkGift(player, st); ownDone = true end)
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก) 2026-10-09
	local okLoad, loadedData = DataLoadRetry.Load(player, "VipService", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
	if okLoad then
		st.data = normalize(loadedData)
		st.loaded = true
	end
	while not ownDone and player.Parent do task.wait(0.2) end
	publish(player, st)
	-- แพ็กสุลต่าน (SultanService ตั้ง IsSultan) ได้สิทธิ์ VIP ทั้งหมดด้วย
	local function checkSultan()
		if player:GetAttribute("IsSultan") == true then grant(player, st) end
	end
	player:GetAttributeChangedSignal("IsSultan"):Connect(checkSultan)
	checkSultan()
	if GIFTED_VIP[player.UserId] then grant(player, st) end -- VIP พิเศษ
	announceGift(player, st) -- ได้ VIP เป็นของขวัญตอนออฟไลน์: แจ้งครั้งแรก
	-- เจ้าของเกมให้ VIP ด้วย /give <ชื่อ> vip (AdminGive บันทึก VipGift_v1 แล้วตั้ง Attribute นี้) = เปิด VIP ทันทีไม่ต้องเข้าเกมใหม่
	local function checkAdminVip()
		if player:GetAttribute("AdminVipGranted") == true then grant(player, st) end
	end
	player:GetAttributeChangedSignal("AdminVipGranted"):Connect(checkAdminVip)
	checkAdminVip()
	-- ทดสอบใน Studio: ตั้ง Attribute "DevGrantVip" = true บนตัวผู้เล่นจากฝั่งเซิร์ฟเวอร์ = ให้ VIP ชั่วคราว (ใช้ได้เฉพาะใน Studio)
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevGrantVip"):Connect(function()
			if player:GetAttribute("DevGrantVip") == true then grant(player, st) end
		end)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	busy[player] = nil
	giftPending[player] = nil
	giftPrompting[player] = nil
end)
