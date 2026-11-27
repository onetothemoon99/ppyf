-- BACKUP 2026-11-27 of ServerScriptService.AdminGive (Studio) before adding SnowLeopard.
-- Restore: paste everything below this header into ServerScriptService.AdminGive.Source (or ScriptEditorService:UpdateSourceAsync).
-- Source bytes 21977, hash 71619027 (h=(h*31+byte)%2147483647)
-- AdminGive: เจ้าของเกมให้เงิน/ของผู้เล่นผ่านแชท (สร้าง 2026-10-10 เช่น ชดเชย kwanindy27)
-- คำสั่ง: /give <ชื่อผู้เล่น หรือ UserId> <ของ> <จำนวน> [เหตุผล...]
--   /gift <ชื่อผู้เล่น หรือ UserId> <ชั่วโมง> [เหตุผล...] = ชดเชยเวลาเล่น (ได้ทศนิยม เช่น 1.5) ใช้คิวเดียวกับ /give (kind "playtime" จำนวนเป็นวินาที)
--     ออนไลน์เซิร์ฟไหนก็ได้ทันที ออฟไลน์ได้ตอนเข้าเกม ไม่ต้องให้ผู้เล่นออกเกมและไม่ต้อง Publish ทุกครั้ง · ไม่นับตั๋ว/รางวัลรายวัน (2026-11-05)
--   ของ: coins | x100 (หุ่นทองคำนำโชค) | x50 (หุ่นฟางดวงดี) | ticket (ตั๋วสุ่มปกติ) | premium (ตั๋วสุ่มพรีเมียม)
--         | feeder (ชามอาหารอัตโนมัติถาวร จำนวน 1) — บันทึกสิทธิ์ใน AutoFeederGift_v1 "to_<userId>" ที่เดียวกับของขวัญ/โค้ดชาม (2026-10-10)
--         | vip (VIP ถาวร จำนวน 1, ไม่ใส่จำนวนก็ได้) — บันทึกใน VipGift_v1 "to_<userId>" ที่เดียวกับของขวัญ VIP (2026-10-14 เช่น ให้ผู้ทดสอบ)
--   เช่น /give kwanindy27 coins 300000 ชดเชยเงินหาย  ·  /give kwanindy27 x100 1
-- ลำดับ: บันทึกคิวของที่ต้องให้ใน DataStore "AdminGrants_v1" คีย์ "u<userId>" (pending) -> MessagingService บอกทุกเซิร์ฟ
--   เซิร์ฟที่ผู้เล่นอยู่ส่งของทันที / ออฟไลน์ = ได้ตอนเข้าเกมครั้งหน้า (หลังเหรียญ+กระเป๋าโหลดเสร็จ)
--   ส่งของ: ย้าย pending -> log ด้วย UpdateAsync (กันส่งซ้ำหลายเซิร์ฟ) แล้วใส่ของ + เซฟเหรียญ/กระเป๋าทันที · ใส่ไม่สำเร็จ = คืนเข้า pending
--   ตั๋วสุ่มใช้ GachaTickets.Add พร้อมเลข "admin_<id>" (ให้ซ้ำไม่ได้)
-- log 50 รายการล่าสุดต่อคน (ใครให้ อะไร เท่าไร เมื่อไร เหตุผล ส่งเมื่อไร) · Studio ใช้คีย์ "studio:u<id>" แยกจากเกมจริง

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local store = DataStoreService:GetDataStore("AdminGrants_v1")
local TOPIC = "AdminGrant"
local MAX_LOG = 50
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")

local ADMINS = { [9360333174] = true } -- เจ้าของเกม (One_moretime91)
if game.CreatorType == Enum.CreatorType.User then ADMINS[game.CreatorId] = true end

-- ของที่ให้ได้ + เพดานต่อครั้ง (กันพิมพ์เกิน)
local KINDS = {
	coins = { Max = 10000000, Icon = "💰", NameTH = "เหรียญ", NameEN = "Coins" },
	x100 = { Max = 100, Icon = "🍀", NameKey = "Item_BoosterX100" },
	x50 = { Max = 999, Icon = "🌾", NameKey = "Item_Booster" },
	ticket = { Max = 100, Icon = "🎟️", NameTH = "ตั๋วสุ่มสัตว์", NameEN = "Pet gacha ticket", Ticket = "Normal" },
	premium = { Max = 100, Icon = "🎫", NameTH = "ตั๋วสุ่มพรีเมียม", NameEN = "Premium gacha ticket", Ticket = "Premium" },
	feeder = { Max = 1, Icon = "🥣", NameTH = "ชามอาหารอัตโนมัติ (ถาวร)", NameEN = "Auto Pet Feeder (permanent)" },
	vip = { Max = 1, Icon = "✨", NameTH = "VIP (ถาวร)", NameEN = "VIP (permanent)" },
	-- ซุกซน สัตว์ลึกลับ (2026-10-22): ยังไม่มี = ได้ตัว + ประกาศทุกเซิร์ฟ (ZukzonService) / มีแล้ว = +1 เลเวล (เต็มแล้วไม่ได้อะไรเพิ่ม)
	zukzon = { Max = 1, Icon = "🐶", NameTH = "ซุกซน (สัตว์ลึกลับ)", NameEN = "Zukzon (Mythic pet)", PetId = "Zukzon" },
	-- /gift ชดเชยเวลาเล่น: จำนวนเป็นวินาที เพดาน 48 ชม. ต่อครั้ง (PlaytimeRewards.AddPlaytime กันซ้ำด้วย id ของรายการ)
	playtime = { Max = 48 * 3600, Icon = "⏱️", NameTH = "เวลาเล่น", NameEN = "Playtime" },
}
local autoFeederGiftStore = DataStoreService:GetDataStore("AutoFeederGift_v1") -- AutoFeeder.checkGift: มีบันทึก "to_<userId>" = มีชามถาวร
local vipGiftStore = DataStoreService:GetDataStore("VipGift_v1") -- VipService.checkGift: มีบันทึก "to_<userId>" = มี VIP ถาวร

local function keyOf(userId)
	return (RunService:IsStudio() and "studio:" or "") .. "u" .. tostring(userId)
end

local function itemName(kind, lang)
	local k = KINDS[kind]
	if not k then return kind end
	if k.NameKey then return Localization.T(k.NameKey, lang) end
	return lang == "en" and k.NameEN or k.NameTH
end

local function commas(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function amountText(kind, amount, lang)
	if kind == "coins" then return commas(amount) end
	if kind == "playtime" then
		return string.format(lang == "en" and "+%s h" or "+%s ชม.", string.format("%.2f", amount / 3600):gsub("%.?0+$", ""))
	end
	return "x" .. tostring(amount)
end

local function notify(player, text)
	if player and player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

-- ============ ส่งของให้ผู้เล่นที่อยู่ในเซิร์ฟนี้ ============
local delivering = {}
local deliverAgain = {} -- [player] = true มีสัญญาณใหม่ระหว่างส่งรอบก่อน = ส่งต่ออีกรอบ

local function waitReady(player)
	local t0 = os.clock()
	while player.Parent and os.clock() - t0 < 120 do
		if player:GetAttribute("CoinsLoaded") == true and player:GetAttribute("InventoryReady") == true then return true end
		task.wait(0.5)
	end
	return false
end

local function applyGrant(player, g)
	local kind = KINDS[g.kind]
	if not kind then error("unknown kind " .. tostring(g.kind)) end
	local amount = math.floor(tonumber(g.amount) or 0)
	if amount <= 0 then error("bad amount") end
	if g.kind == "coins" then
		local ls = player:FindFirstChild("leaderstats")
		local coins = ls and ls:FindFirstChild("เหรียญ")
		if not coins then error("no coins") end
		coins.Value += amount
	elseif g.kind == "feeder" then
		-- บันทึกสิทธิ์ถาวร (เหมือนโค้ดชามใน SultanService) แล้วเปิดชามให้ทันทีผ่าน Attribute ที่ AutoFeeder ฟังอยู่
		local saved
		autoFeederGiftStore:UpdateAsync("to_" .. player.UserId, function(old)
			old = type(old) == "table" and old or {}
			old.adminGrants = type(old.adminGrants) == "table" and old.adminGrants or {}
			old.adminGrants[tostring(g.id)] = true
			old.seen = true
			old.t = old.t or os.time()
			saved = old
			return old
		end, { player.UserId })
		if not saved then error("feeder save failed") end
		player:SetAttribute("PromoAutoFeederGranted", true)
	elseif g.kind == "vip" then
		-- บันทึกแบบเดียวกับของขวัญ VIP (มีบันทึกเดิมอยู่แล้ว = มี VIP อยู่แล้ว ไม่เขียนทับ) แล้วเปิด VIP ทันทีผ่าน Attribute ที่ VipService ฟังอยู่
		local saved
		vipGiftStore:UpdateAsync("to_" .. player.UserId, function(old)
			if type(old) == "table" then saved = old; return nil end
			saved = { from = g.by, fromName = "ทีมงาน", t = os.time(), receipt = "admin_" .. tostring(g.id), seen = true }
			return saved
		end, { player.UserId })
		if not saved then error("vip save failed") end
		player:SetAttribute("AdminVipGranted", true)
	elseif g.kind == "playtime" then
		local add = ServerScriptService:WaitForChild("PlaytimeRewards"):WaitForChild("AddPlaytime", 30)
		if not add or add:Invoke(player, amount, "admin_" .. tostring(g.id)) ~= true then error("playtime add failed") end
	elseif kind.PetId then
		local PetOwnership = require(ServerScriptService:WaitForChild("PetSystem"):WaitForChild("PetOwnership"))
		if not PetOwnership.WaitLoaded(player, 60) then error("pets not loaded") end
		local result = PetOwnership.GrantPremium(player, kind.PetId)
		if not result then error("pet grant failed") end
		if result.isNew then
			local announce = game:GetService("ServerStorage"):FindFirstChild("ZukzonAnnounce")
			if announce then announce:Fire(player) end
		end
	elseif kind.Ticket then
		if GachaTickets.Add(player, kind.Ticket, amount, "admin_" .. tostring(g.id)) == nil then error("ticket save failed") end
	else
		ItemFactory.GiveBoosterTool(player, amount, g.kind)
	end
end

local function fire(scriptName, child, player)
	local s = ServerScriptService:FindFirstChild(scriptName)
	local ev = s and s:FindFirstChild(child)
	if ev then ev:Fire(player) end
end

local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local function deliver(player)
	if delivering[player] then deliverAgain[player] = true return end
	delivering[player] = true
	deliverAgain[player] = nil
	local ok, err = pcall(function()
		if not waitReady(player) then return end
		-- ไม่เร่งด่วน: หลีกทางให้ของสำคัญโหลดก่อน (2026-10-13)
		if not DataLoadRetry.Defer(player, "AdminGive") then return end
		-- เอาคิวออกแบบ atomic (เซิร์ฟอื่นส่งซ้ำไม่ได้)
		local taken
		store:UpdateAsync(keyOf(player.UserId), function(old)
			if type(old) ~= "table" or type(old.pending) ~= "table" or #old.pending == 0 then
				taken = {}
				return nil
			end
			taken = old.pending
			old.pending = {}
			old.log = type(old.log) == "table" and old.log or {}
			for _, g in ipairs(taken) do
				local entry = table.clone(g)
				entry.deliveredAt = os.time()
				entry.job = game.JobId
				table.insert(old.log, entry)
			end
			while #old.log > MAX_LOG do table.remove(old.log, 1) end
			return old
		end, { player.UserId })
		if not taken or #taken == 0 then return end
		local lang = Localization.GetLanguage(player)
		local failed, parts, touchedCoins, touchedInv = {}, {}, false, false
		for _, g in ipairs(taken) do
			local okG, errG = pcall(applyGrant, player, g)
			if okG then
				local amt = amountText(g.kind, g.amount, lang)
				table.insert(parts, (KINDS[g.kind] and KINDS[g.kind].Icon or "") .. " " .. itemName(g.kind, lang) .. " " .. amt)
				if g.kind == "coins" then touchedCoins = true elseif g.kind == "x100" or g.kind == "x50" then touchedInv = true end
				print(string.format("🎁 AdminGive: ส่ง %s x%s ให้ %s (id %s, โดย %s)", tostring(g.kind), tostring(g.amount), player.Name, tostring(g.id), tostring(g.byName)))
			else
				warn("AdminGive: ใส่ของไม่สำเร็จ " .. player.Name .. " " .. tostring(g.kind) .. ": " .. tostring(errG))
				table.insert(failed, g)
			end
		end
		if touchedCoins then fire("LeaderstatsSetup", "SaveCoinsNow", player) end
		if touchedInv then fire("InventorySystem", "SaveInventoryNow", player) end
		-- ใส่ไม่สำเร็จ = คืนเข้าคิว (ได้รอบหน้า)
		if #failed > 0 then
			pcall(function()
				store:UpdateAsync(keyOf(player.UserId), function(old)
					old = type(old) == "table" and old or {}
					old.pending = type(old.pending) == "table" and old.pending or {}
					for _, g in ipairs(failed) do table.insert(old.pending, g) end
					return old
				end, { player.UserId })
			end)
		end
		if #parts > 0 then
			local reason = taken[1] and taken[1].reason
			local head = Localization.Pick(lang, "🎁 ได้รับของจากทีมงาน: ", "🎁 Gift from the team: ")
			notify(player, head .. table.concat(parts, " · ") .. ((type(reason) == "string" and reason ~= "") and (" (" .. reason .. ")") or ""))
		end
	end)
	delivering[player] = nil
	if not ok then warn("AdminGive: deliver error " .. player.Name .. ": " .. tostring(err)) end
	if deliverAgain[player] and player.Parent then task.defer(deliver, player) end
end

-- เข้าเกม = เช็กคิวค้าง (ออฟไลน์ตอนสั่ง)
Players.PlayerAdded:Connect(function(player) task.spawn(deliver, player) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(deliver, p) end
Players.PlayerRemoving:Connect(function(player) delivering[player] = nil deliverAgain[player] = nil end)

-- สัญญาณจากเซิร์ฟที่สั่ง: ผู้เล่นอยู่เซิร์ฟนี้ = ส่งเลย
local function onSignal(data)
	local userId = type(data) == "table" and tonumber(data.userId)
	local player = userId and Players:GetPlayerByUserId(userId)
	if player then task.spawn(deliver, player) end
end
local subscribed = false
task.spawn(function()
	for attempt = 1, 5 do
		local ok = pcall(function() MessagingService:SubscribeAsync(TOPIC, function(msg) onSignal(msg.Data) end) end)
		if ok then subscribed = true return end
		task.wait(5 * attempt)
	end
	warn("AdminGive: ต่อ MessagingService ไม่สำเร็จ (ผู้เล่นจะได้ของตอนเข้าเกมครั้งหน้า)")
end)

-- ============ คำสั่งแชท (เฉพาะเจ้าของ) ============
local lastCommand = {}
local function reply(admin, text) notify(admin, "🛠️ " .. text) end

-- "/gift ชื่อ 2 เหตุผล" -> { ชื่อ, วินาที, เหตุผล } / ผิดรูปแบบ = nil
local GIFT_USAGE = "วิธีใช้: /gift ชื่อผู้เล่น ชั่วโมง [เหตุผล] (ไม่เกิน 48 ชม. ต่อครั้ง)"
local function parseGift(args)
	local target, hoursText, reason = args:match("^(%S+)%s+(%S+)%s*(.*)$")
	local seconds = target and tonumber(hoursText) and math.floor(tonumber(hoursText) * 3600)
	if not seconds or seconds ~= seconds or seconds < 60 or seconds > KINDS.playtime.Max then return nil end
	return target, seconds, reason
end

local function handleCommand(admin, text)
	if not (admin and ADMINS[admin.UserId]) or type(text) ~= "string" then return end
	local giftArgs = text:match("^%s*/gift%s+(.+)$")
	if giftArgs or text:lower():match("^%s*/gift%s*$") then
		local target, seconds, reason = parseGift(giftArgs or "")
		if not target then reply(admin, GIFT_USAGE) return end
		text = string.format("/give %s playtime %d %s", target, seconds, reason)
	end
	local args = text:match("^%s*/give%s+(.+)$")
	if not args then
		if text:lower():match("^%s*/give%s*$") then
			reply(admin, "วิธีใช้: /give ชื่อผู้เล่น coins|x100|x50|ticket|premium|feeder|vip|zukzon จำนวน [เหตุผล]")
		end
		return
	end
	local prev = lastCommand[admin]
	if prev and prev.text == text and os.clock() - prev.clock < 3 then return end -- TextChatCommand + Chatted ยิงซ้ำ
	lastCommand[admin] = { text = text, clock = os.clock() }

	local target, kind, amountText, reason = args:match("^(%S+)%s+(%S+)%s+(%S+)%s*(.*)$")
	if not target then target, kind = args:match("^(%S+)%s+(%S+)%s*$") end -- ไม่ใส่จำนวน (ใช้ได้กับของที่ให้ได้ครั้งละ 1 เช่น vip/feeder)
	kind = kind and kind:lower()
	-- "/give ชื่อ pet zukzon ..." = เหมือน "/give ชื่อ zukzon ..."
	if kind == "pet" and amountText and KINDS[amountText:lower()] and KINDS[amountText:lower()].PetId then
		kind = amountText:lower()
		amountText, reason = (reason or ""):match("^(%S*)%s*(.*)$")
		if amountText == "" then amountText = nil end
	end
	local amount = tonumber(amountText and amountText:gsub(",", "") or nil)
	local def = kind and KINDS[kind]
	if def and def.Max == 1 and not amount then
		-- ของที่ให้ได้ 1 ชิ้น: คำหลังชนิดของไม่ใช่ตัวเลข = เป็นเหตุผล
		reason = ((amountText or "") .. " " .. (reason or "")):match("^%s*(.-)%s*$")
		amount = 1
	end
	if not (target and def and amount) then
		reply(admin, "คำสั่งไม่ถูก: /give ชื่อผู้เล่น coins|x100|x50|ticket|premium|feeder|vip|zukzon จำนวน [เหตุผล]")
		return
	end
	amount = math.floor(amount)
	if amount <= 0 or amount > def.Max then
		reply(admin, string.format("จำนวนต้องอยู่ระหว่าง 1 – %s", commas(def.Max)))
		return
	end

	-- หา UserId (พิมพ์เลข = UserId / ไม่งั้น = ชื่อบัญชี ไม่ใช่ชื่อที่แสดง)
	local userId = tonumber(target)
	local username = target
	if not userId then
		local okId, id = pcall(function() return Players:GetUserIdFromNameAsync(target) end)
		if not okId or not id then
			reply(admin, "ไม่พบผู้เล่นชื่อ " .. target .. " (ใช้ชื่อบัญชี ไม่ใช่ชื่อที่แสดง หรือใส่ UserId)")
			return
		end
		userId = id
	else
		local okN, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		username = okN and n or tostring(userId)
	end

	local grant = {
		id = HttpService:GenerateGUID(false),
		kind = kind,
		amount = amount,
		reason = reason ~= "" and reason:sub(1, 80) or nil,
		by = admin.UserId,
		byName = admin.Name,
		t = os.time(),
	}
	local okSave, err = pcall(function()
		store:UpdateAsync(keyOf(userId), function(old)
			old = type(old) == "table" and old or {}
			old.pending = type(old.pending) == "table" and old.pending or {}
			table.insert(old.pending, grant)
			return old
		end, { userId })
	end)
	if not okSave then
		reply(admin, "บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง: " .. tostring(err))
		return
	end
	print(string.format("🛠️ AdminGive: %s สั่งให้ %s (%d) %s x%d เหตุผล: %s", admin.Name, username, userId, kind, amount, tostring(grant.reason)))

	-- บอกทุกเซิร์ฟ (รวมเซิร์ฟนี้)
	local okPub = pcall(function() MessagingService:PublishAsync(TOPIC, { userId = userId }) end)
	if not okPub or not subscribed then onSignal({ userId = userId }) end
	local online = Players:GetPlayerByUserId(userId) ~= nil
	local amt = amountText(kind, amount, "th")
	reply(admin, string.format("ส่ง %s %s ให้ %s แล้ว · %s", itemName(kind, "th"), amt, username,
		online and "อยู่เซิร์ฟนี้ ได้ทันที" or "อยู่เซิร์ฟอื่น = ได้ทันที / ออฟไลน์ = ได้ตอนเข้าเกม"))
end

local okCmd, errCmd = pcall(function()
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "AdminGiveCommand"
	cmd.PrimaryAlias = "/give"
	cmd.Parent = folder
	cmd.Triggered:Connect(function(source, text)
		handleCommand(source and Players:GetPlayerByUserId(source.UserId), text)
	end)
	local giftCmd = Instance.new("TextChatCommand")
	giftCmd.Name = "AdminGiftCommand"
	giftCmd.PrimaryAlias = "/gift"
	giftCmd.Parent = folder
	giftCmd.Triggered:Connect(function(source, text)
		handleCommand(source and Players:GetPlayerByUserId(source.UserId), text)
	end)
end)
if not okCmd then warn("AdminGive: สร้างคำสั่งแชทไม่สำเร็จ: " .. tostring(errCmd)) end

local function hookPlayer(player)
	if not ADMINS[player.UserId] then return end
	player.Chatted:Connect(function(message) handleCommand(player, message) end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerRemoving:Connect(function(player) lastCommand[player] = nil end)
