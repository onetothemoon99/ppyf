-- BACKUP of game.ServerScriptService.SultanService (Script) before adding code MANGO555, 2026-11-16
-- Restore: in Studio open ServerScriptService.SultanService, select all, paste everything below the 4 header lines.
-- Checksum (h=h*31+byte mod 2147483647) of the body = 1930642699, 75578 bytes.
--
-- SultanService: แพ็กสุลต่าน (Game Pass ดู ReplicatedStorage.SultanConfig)
-- ความเป็นเจ้าของ -> Attribute "IsSultan" บนตัวผู้เล่น (VipService ให้สิทธิ์ VIP ตาม / ระบบขาย-โชค-เครื่องทำอาหาร อ่านไปคิดโบนัส)
-- DataStore "Sultan_v1": { bundleGiven = true/false, lastDaily = เลขวันที่รับตั๋วรายวันล่าสุด }
-- ของครั้งเดียว: จด bundleGiven ด้วย UpdateAsync ก่อนแจก (หลายเซิร์ฟเวอร์พร้อมกันก็ได้ครั้งเดียว) ตั๋วใช้เลขใบเสร็จปลอมกันซ้ำอีกชั้น
-- แจกเงิน/หุ่นหลัง CoinsLoaded + InventoryLoaded เท่านั้น (ไม่งั้นโดนค่าที่โหลดมาทับ)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("SultanConfig"))
local promoCodeStore = DataStoreService:GetDataStore("SultanPromoCodeClaims_v1")
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local GachaConfig = require(ReplicatedStorage:WaitForChild("GachaConfig"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local PetOwnership = require(ServerScriptService:WaitForChild("PetSystem"):WaitForChild("PetOwnership"))
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))
local SULTAN_PET_ID = "SultanDragon" -- มังกรแดงสุลต่าน (PetDefinitions) ให้ทุกคนที่มีแพ็ก

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local store = DataStoreService:GetDataStore("Sultan_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local states = {} -- [player] = { owned, loaded, data, granting }

local function notify(player, text)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

local function remote(name, class)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local request = remote("SultanRequest", "RemoteFunction")   -- "aura" (true/false) เปิด/ปิดออร่า
local announceEvent = remote("SultanAnnounce", "RemoteEvent") -- ประกาศทั้งเซิร์ฟเวอร์ (ชื่อ, "join"/"purchase")

-- ============ ออร่าทองรอบตัว (ทุกคนเห็น) Attribute "SultanAura" = false คือปิด ============
local AURA_NAME = "SultanAura"
local function makeAura()
	local att = Instance.new("Attachment")
	att.Name = AURA_NAME
	att.Position = Vector3.new(0, -0.6, 0)
	-- ประกายทองกระจายรอบตัว (texture ของ Roblox เอง โหลดได้แน่นอน)
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkles"
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 230, 130), Color3.fromRGB(255, 170, 60))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	sparkle.Lifetime = NumberRange.new(1, 1.6)
	sparkle.Rate = 9
	sparkle.Speed = NumberRange.new(1.2, 2.4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Acceleration = Vector3.new(0, 1.2, 0)
	sparkle.Drag = 1.6
	sparkle.Parent = att
	-- ละอองทอง-ม่วงลอยขึ้นจากเท้า
	local motes = Instance.new("ParticleEmitter")
	motes.Name = "Motes"
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(Color3.fromRGB(255, 210, 90), Color3.fromRGB(200, 110, 255))
	motes.LightEmission = 1
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(0.5, 0.28), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	motes.Lifetime = NumberRange.new(1.4, 2.2)
	motes.Rate = 6
	motes.Speed = NumberRange.new(1.5, 2.5)
	motes.SpreadAngle = Vector2.new(35, 35)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.Parent = att
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 205, 110)
	light.Brightness = 0.7
	light.Range = 7
	light.Parent = att
	return att
end

local function applyAura(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local want = false -- ปิดออร่าทองรอบตัวของสุลต่านถาวร (ผู้เล่นขอ 2026-10-02) ตัวที่มีอยู่ถูกลบตอนเรียกนี้ (เปิดคืน: player:GetAttribute("IsSultan") == true and player:GetAttribute("SultanAura") ~= false)
	local existing = root:FindFirstChild(AURA_NAME)
	if want and not existing then
		makeAura().Parent = root
	elseif not want and existing then
		existing:Destroy()
	end
end

-- ============ ประกาศทั้งเซิร์ฟเวอร์ ============
-- เข้าเกม: ไม่ประกาศซ้ำภายใน 30 นาที (ระบบ AFK พาเข้าเกมใหม่ทุก ~19 นาที จะได้ไม่สแปม)
local lastAnnounced = {} -- [userId] = os.clock()
-- ผู้เล่นปิดประกาศตอนเข้าเซิร์ฟได้ (Attribute "SultanJoinAnnounce" = false / Sultan_v1.announce) ตอนซื้อแพ็กยังประกาศเสมอ
local function announce(player, kind)
	if kind == "join" and player:GetAttribute("SultanJoinAnnounce") == false then return end
	if kind == "join" then
		local last = lastAnnounced[player.UserId]
		if last and os.clock() - last < 1800 then return end
	end
	lastAnnounced[player.UserId] = os.clock()
	if player.Parent then announceEvent:FireAllClients(player.DisplayName, kind) end
end

local function commas(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- รอให้เงินและกระเป๋าโหลดเสร็จก่อนแจกของ (คืน false ถ้าไม่มาภายในเวลา)
local function waitForData(player, timeout)
	local waited = 0
	while player.Parent and waited < timeout do
		if player:GetAttribute("CoinsLoaded") and player:GetAttribute("InventoryReady") then return true end -- InventoryReady = กระเป๋าโหลดสำเร็จจริง (2026-10-13)
		waited += task.wait(0.5)
	end
	return false
end

-- จดค่าใน DataStore แบบเช็กแล้วเขียน (key ต้องยังเป็นค่าเดิมถึงจะเขียน) คืน true = เราเป็นคนเขียน (ได้สิทธิ์แจก)
local function claim(player, st, field, newValue)
	local claimed = false
	local ok, err = pcall(function()
		store:UpdateAsync(tostring(player.UserId), function(old)
			old = type(old) == "table" and old or {}
			if old[field] == newValue then
				claimed = false
				st.data = old
				return nil
			end
			old[field] = newValue
			claimed = true
			return old
		end, { player.UserId })
	end)
	if not ok then
		warn("SultanService: บันทึก " .. field .. " ไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return false
	end
	if claimed then st.data[field] = newValue end
	return claimed
end

local function giveBundle(player, st)
	if st.data.bundleGiven then return end
	if not waitForData(player, 90) then return end
	if not claim(player, st, "bundleGiven", true) then return end
	local b = Config.BUNDLE
	GachaTickets.Add(player, "Premium", b.PremiumTickets, "sultan_bundle")
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("เหรียญ")
	if coins then coins.Value += b.Coins end
	ItemFactory.GiveBoosterTool(player, b.X100Scarecrows, "x100")
	local luck = require(ReplicatedStorage:WaitForChild("LuckConfig")).BoosterTiers.x100.Luck
	notify(player, string.format("👑 ของขวัญสุลต่าน: 💎 ตั๋วพรีเมียม %d ใบ · 💰 %s เหรียญ · 🍀 หุ่นทองคำนำโชค (x%d) %d อัน",
		b.PremiumTickets, commas(b.Coins), luck, b.X100Scarecrows))
	print("👑 SultanService: แจกของแพ็กสุลต่านให้ " .. player.Name)
end

-- ให้มังกรแดงสุลต่าน (ทุกครั้งที่ได้สิทธิ์ ถ้ามีอยู่แล้วไม่มีอะไรเกิดขึ้น) รอข้อมูลสัตว์เลี้ยงโหลดเสร็จก่อน
-- (PetOwnership.Load ตั้ง PetLevel_<ตัวเริ่มต้น> ตอนโหลดเสร็จ ถ้าให้ก่อนโหลดเสร็จ ตัวที่ให้อาจโดนข้อมูลเก่าทับในหน่วยความจำ)
local function giveSultanPet(player)
	PetOwnership.WaitLoaded(player, 60)
	if not player.Parent or PetOwnership.Owns(player, SULTAN_PET_ID) then return end
	local isNew, saved = PetOwnership.Grant(player, SULTAN_PET_ID)
	if isNew then
		notify(player, "🔥 ได้ \"มังกรแดงสุลต่าน\" แล้ว! เปิดเมนูสัตว์เลี้ยง 🐾 เพื่อพาออกมาบินเคียงข้าง")
		print("👑 SultanService: ให้มังกรแดงสุลต่านกับ " .. player.Name .. " (saved=" .. tostring(saved) .. ")")
	end
end

local function giveDaily(player, st)
	local today = Config.DayIndex()
	if st.data.lastDaily == today then return end
	if not claim(player, st, "lastDaily", today) then return end
	local n = GachaTickets.Add(player, "Premium", Config.DAILY_PREMIUM_TICKETS, "sultan_daily_" .. today)
	if n then
		notify(player, "👑 ของขวัญรายวันสุลต่าน: 💎 ตั๋วพรีเมียม +" .. Config.DAILY_PREMIUM_TICKETS)
	end
end

-- เป็นสุลต่านแล้ว (เช็กตอนเข้าเกม / ซื้อสำเร็จ / ทดสอบใน Studio)
local function grant(player, st, reason)
	if st.owned then return end
	st.owned = true
	player:SetAttribute("SultanAura", st.data.aura ~= false)
	player:SetAttribute("SultanJoinAnnounce", st.data.announce ~= false)
	player:SetAttribute("IsSultan", true)
	applyAura(player)
	task.delay(reason == "purchase" and 1 or 5, announce, player, reason or "join")
	if st.granting then return end
	st.granting = true
	task.spawn(function()
		local waited = 0
		while not st.loaded and player.Parent and waited < 30 do waited += task.wait(0.5) end
		task.spawn(giveSultanPet, player)
		if st.loaded then
			giveBundle(player, st)
			giveDaily(player, st)
		end
		st.granting = false
	end)
end

local function checkOwnership(player, st)
	if st.data.promoSultan == true then
		grant(player, st, "join")
		return
	end
	if Config.GAMEPASS_ID == 0 then return end
	for attempt = 1, 3 do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GAMEPASS_ID)
		end)
		if ok then
			if owns then
				grant(player, st, "join")
			elseif not st.owned then
				player:SetAttribute("IsSultan", false) -- เช็กแล้วไม่มี (ระบบอื่นรู้ว่าเช็กเสร็จ เช่น เครื่องทำอาหารกลับความเร็วปกติ)
			end
			return
		end
		warn("SultanService: เช็ก Game Pass ไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(owns))
		task.wait(3)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if Config.GAMEPASS_ID == 0 or passId ~= Config.GAMEPASS_ID or not purchased then return end
	local st = states[player]
	if not st then return end
	grant(player, st, "purchase")
	notify(player, "👑 ยินดีต้อนรับท่านสุลต่าน! ได้สิทธิ์ VIP ทั้งหมด + ของขวัญกำลังมา")
	print("👑 SultanService: " .. player.Name .. " ซื้อแพ็กสุลต่านแล้ว")
end)

-- ============ ของขวัญแพ็กสุลต่าน (Developer Product: SultanConfig.GIFT_PRODUCT_ID) ============
-- Game Pass ซื้อให้คนอื่นไม่ได้ จึงขายเป็น Developer Product: ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนได้แพ็กสุลต่านครบ
-- (สิทธิ์ถาวร + มังกรแดง + ของครั้งเดียว + ตั๋วรายวัน เหมือนซื้อเอง) แบบเดียวกับของขวัญ VIP ใน VipService
-- DataStore "SultanGift_v1": "to_<userId>" = { from, fromName, t, receipt, seen } (เช็กตอนเข้าเกม) / "pending_<userId>" = { to, toName, t } (ผู้ซื้อเลือกผู้รับไว้)
local giftStore = DataStoreService:GetDataStore("SultanGift_v1")
local giftPending = {}   -- [player] = { to, toName, t }
local giftPrompting = {} -- [player] = os.clock() ตอนเปิดหน้าจ่ายเงิน
local GIFT_PROMPT_TIMEOUT = 120

local function grantGift(buyer, receiptInfo)
	local pending = giftPending[buyer]
	if not pending then
		local okRead, saved = pcall(function() return giftStore:GetAsync("pending_" .. buyer.UserId) end)
		if not okRead then return false end
		pending = saved
	end
	if type(pending) ~= "table" or type(pending.to) ~= "number" then
		warn("SultanService: ใบเสร็จของขวัญสุลต่านของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local target = Players:GetPlayerByUserId(pending.to)
	local record = {
		from = buyer.UserId, fromName = buyer.DisplayName, t = os.time(),
		receipt = tostring(receiptInfo.PurchaseId), seen = target ~= nil,
	}
	local okSave, err = pcall(function() giftStore:SetAsync("to_" .. pending.to, record, { pending.to }) end)
	if not okSave then
		warn("SultanService: บันทึกของขวัญสุลต่านไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
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
			grant(target, tst, "purchase") -- ประกาศ "ได้เป็นสุลต่านแล้ว" ให้ทั้งเซิร์ฟเวอร์ + แจกของแพ็ก
		end
		notify(target, "🎁 " .. buyer.DisplayName .. " ส่งแพ็กสุลต่านให้คุณเป็นของขวัญ! ได้สิทธิ์สุลต่านครบทุกอย่าง 👑")
	end
	notify(buyer, "🎁 ส่งแพ็กสุลต่านให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่ใจดี 💖")
	print("🎁 SultanService: " .. buyer.Name .. " ส่งแพ็กสุลต่านให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(Config.GIFT_PRODUCT_ID or 0, { name = "ของขวัญแพ็กสุลต่าน", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกันและยังไม่เป็นสุลต่าน) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
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
		local tst = states[target]
		if not (tst and tst.loaded) or target:GetAttribute("IsSultan") == nil then
			return { ok = false, message = "ข้อมูลของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		if target:GetAttribute("IsSultan") == true then
			return { ok = false, message = target.DisplayName .. " เป็นสุลต่านอยู่แล้ว" }
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
		warn("SultanService: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("SultanService: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: แพ็กสุลต่านสำหรับ " .. toName }
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

-- เข้าเกม: มีบันทึกของขวัญ = เป็นสุลต่าน (ครั้งแรกที่เข้ามาหลังได้รับตอนออฟไลน์ ประกาศเหมือนซื้อใหม่ + แจ้งผู้ได้รับ)
local function checkGift(player, st)
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = คนที่ได้สุลต่านเป็นของขวัญไม่ได้สิทธิ์รอบนั้น) 2026-10-09 · repeat...until true = บล็อกที่ return/break ได้เหมือนเดิม
	repeat
		local ok, rec = DataLoadRetry.Load(player, "SultanService(gift)", DataLoadRetry.Get(giftStore, "to_" .. player.UserId), function() return states[player] == st end)
		if ok then
			if type(rec) == "table" then
				st.gift = rec
				local firstTime = rec.seen ~= true
				grant(player, st, firstTime and "purchase" or "join")
				if firstTime then
					rec.seen = true
					task.delay(8, notify, player, "🎁 คุณได้รับแพ็กสุลต่านเป็นของขวัญจาก " .. tostring(rec.fromName or "เพื่อน") .. "! 👑")
					pcall(function()
						giftStore:UpdateAsync("to_" .. player.UserId, function(old)
							if type(old) ~= "table" then return nil end
							old.seen = true
							return old
						end)
					end)
				end
			end
			return
		end
	until true
end

local function onPlayerAdded(player)
	local st = { owned = false, loaded = false, data = {}, granting = false }
	states[player] = st
	-- โหลดแบบลองจนได้ในเธรดแยก (เดิมลอง 3 ครั้งแล้วเลิก + ข้ามเช็กของขวัญ) 2026-10-09
	-- ของขวัญก่อน แล้วค่อยเช็ก Game Pass (กัน IsSultan ถูกตั้งเป็น false แวบหนึ่งทั้งที่ได้ของขวัญ)
	task.spawn(function()
		local ok, data = DataLoadRetry.Load(player, "SultanService", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
		if not ok then return end
		st.data = type(data) == "table" and data or {}
		st.loaded = true
		checkGift(player, st)
		checkOwnership(player, st)
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		applyAura(player)
	end)
	player:GetAttributeChangedSignal("SultanAura"):Connect(function() applyAura(player) end)
	-- ทดสอบใน Studio: ตั้ง Attribute "DevGrantSultan" = true บนตัวผู้เล่นจากฝั่งเซิร์ฟเวอร์ = เป็นสุลต่านชั่วคราว (ใช้ได้เฉพาะใน Studio)
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevGrantSultan"):Connect(function()
			if player:GetAttribute("DevGrantSultan") == true then grant(player, st, "join") end
		end)
	end
end
local promoBusy = {}
local promoAttempts = {}
local promoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("SultanPromoCodes"))) do
	promoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end

-- โค้ดโปรโมชันทั่วไป: ใช้ได้หนึ่งครั้งต่อบัญชีภายในช่วงเวลาของแคมเปญ
local PromoCodeDefinitions = require(ServerScriptService:WaitForChild("PromoCodes"))
local coinPromoCodes = {}
for rawCode, definition in pairs(PromoCodeDefinitions) do
	coinPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = definition
end
local boomboxPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("BoomboxPromoCodes"))) do
	boomboxPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local boomboxPromoClaims = DataStoreService:GetDataStore("BoomboxPromoCodeClaims_v1")
local boomboxPromoEntitlements = DataStoreService:GetDataStore("BoomboxPromoEntitlements_v1")
local autoFeederPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("AutoFeederPromoCodes"))) do
	autoFeederPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local autoFeederPromoClaims = DataStoreService:GetDataStore("AutoFeederPromoCodeClaims_v1")
local luckBoosterPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("LuckBoosterPromoCodes"))) do
	luckBoosterPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local luckBoosterPromoClaims = DataStoreService:GetDataStore("LuckBoosterPromoCodeClaims_v1")
local butterflyRodPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("ButterflyRodPromoCodes"))) do
	butterflyRodPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local butterflyRodPromoClaims = DataStoreService:GetDataStore("ButterflyRodPromoCodeClaims_v1")
local sunBeeRodPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("SunBeeRodPromoCodes"))) do
	sunBeeRodPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local sunBeeRodPromoClaims = DataStoreService:GetDataStore("SunBeeRodPromoCodeClaims_v1")
local petSlotPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("PetSlotPromoCodes"))) do
	petSlotPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local petSlotPromoClaims = DataStoreService:GetDataStore("PetSlotPromoCodeClaims_v1")
local witchPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("WitchPromoCodes"))) do
	witchPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local witchPromoClaims = DataStoreService:GetDataStore("WitchPromoCodeClaims_v1")
-- 2026-10-15 โค้ดแม่มดน้อยเลเวล 15 (MMG-XXXXXX) แยกรายการ/ที่เก็บการใช้จาก MG-
local witchMaxPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("WitchMaxPromoCodes"))) do
	witchMaxPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local witchMaxPromoClaims = DataStoreService:GetDataStore("WitchMaxPromoCodeClaims_v1")
-- 2026-10-19 โค้ดลามะไม่ใช่ลามะ (RM-XXXXXX) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม
local llamaPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("LlamaMountPromoCodes"))) do
	llamaPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local llamaPromoClaims = DataStoreService:GetDataStore("LlamaMountPromoCodeClaims_v1")
local ticketPromoCodes = {} -- โค้ดตั๋วสุ่มถาวร บัญชีละครั้ง (TicketPromoCodes, 2026-11-01)
for rawCode, definition in pairs(require(ServerScriptService:WaitForChild("TicketPromoCodes"))) do
	ticketPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = definition
end
local ticketPromoClaims = DataStoreService:GetDataStore("TicketPromoCodeClaims_v1")
-- 2026-11-04 โค้ดแปลงปลูก +60 (PL-XXXXXX) / คูปองฟักทันที 12 ใบ (PK-XXXXXX) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม
local plantQuotaPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("PlantQuotaPromoCodes"))) do
	plantQuotaPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local plantQuotaPromoClaims = DataStoreService:GetDataStore("PlantQuotaPromoCodeClaims_v1")
local hatchTokenPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("HatchTokenPromoCodes"))) do
	hatchTokenPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local hatchTokenPromoClaims = DataStoreService:GetDataStore("HatchTokenPromoCodeClaims_v1")
-- 2026-11-05 โค้ดให้อาหารไก่อัตโนมัติถาวร (FK-XXXXXX) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม
local chickenAutoFeedPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("ChickenAutoFeedPromoCodes"))) do
	chickenAutoFeedPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local chickenAutoFeedPromoClaims = DataStoreService:GetDataStore("ChickenAutoFeedPromoCodeClaims_v1")
-- 2026-11-04 โค้ดจิ้งจอกเก้าหาง (N9-XXXXXX) / ผีน้อยนักปักหุ่น (GO-XXXXXX) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม
local nineTailFoxPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("NineTailFoxPromoCodes"))) do
	nineTailFoxPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local nineTailFoxPromoClaims = DataStoreService:GetDataStore("NineTailFoxPromoCodeClaims_v1")
local scarecrowGhostPromoCodes = {}
for _, rawCode in ipairs(require(ServerScriptService:WaitForChild("ScarecrowGhostPromoCodes"))) do
	scarecrowGhostPromoCodes[string.upper(rawCode):gsub("[^A-Z0-9]", "")] = true
end
local scarecrowGhostPromoClaims = DataStoreService:GetDataStore("ScarecrowGhostPromoCodeClaims_v1")
local petSlotGiftStore = DataStoreService:GetDataStore("PetSlotGift_v1") -- สิทธิ์ช่องสัตว์ +1 เก็บที่เดียวกับของขวัญ (PetSlotGift.HasGift อ่านตอนเข้าเกม)
local PetSlotConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("PetSlotConfig"))
local autoFeederGiftStore = DataStoreService:GetDataStore("AutoFeederGift_v1")
local coinPromoClaims = DataStoreService:GetDataStore("PromoCodeAccountClaims_v1")
local promoActivationStore = DataStoreService:GetDataStore("PromoCodeActivation_v1")
local playerCoinsStore = DataStoreService:GetDataStore("PlayerCoins_v1")

local function getPromoActivation(code)
	if RunService:IsStudio() then return nil, "โค้ดแจกเงินใช้ได้ในเกมจริงเท่านั้น" end
	local ok, record = pcall(function()
		return promoActivationStore:UpdateAsync(code, function(old)
			if type(old) == "table" and type(old.startedAt) == "number" then return old end
			return { startedAt = os.time() }
		end)
	end)
	if not ok or type(record) ~= "table" or type(record.startedAt) ~= "number" then
		warn("SultanService: อ่านวันเริ่มโค้ดไม่สำเร็จ " .. code .. ": " .. tostring(record))
		return nil, "ระบบตรวจสอบโค้ดขัดข้อง ลองใหม่อีกครั้ง"
	end
	return record.startedAt
end

-- UpdateAsync ทำให้ทุกเซิร์ฟเวอร์ใช้เวลาเริ่มแคมเปญเดียวกัน และการรีสตาร์ตไม่ต่ออายุโค้ด
if not RunService:IsStudio() then
	task.spawn(function()
		for code in pairs(coinPromoCodes) do getPromoActivation(code) end
	end)
end

local function redeemCoinPromoCode(player, code, definition)
	local startedAt, activationError = getPromoActivation(code)
	if not startedAt then return { ok = false, message = activationError } end
	if os.time() >= startedAt + definition.durationSeconds then
		return { ok = false, message = "โค้ดนี้หมดอายุแล้ว" }
	end

	local waited = 0
	while player.Parent and not player:GetAttribute("CoinsLoaded") and waited < 90 do
		waited += task.wait(0.5)
	end
	if not player.Parent or not player:GetAttribute("CoinsLoaded") then
		return { ok = false, message = "ข้อมูลเหรียญยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("เหรียญ")
	if not coins then return { ok = false, message = "ไม่พบข้อมูลเหรียญ ลองใหม่อีกครั้ง" } end

	local token = game:GetService("HttpService"):GenerateGUID(false)
	local claimKey = code .. ":" .. tostring(player.UserId)
	local okClaim, claimRecord = pcall(function()
		return coinPromoClaims:UpdateAsync(claimKey, function(old)
			if type(old) == "table" then return old end
			return { userId = player.UserId, claimedAt = os.time(), token = token }
		end, { player.UserId })
	end)
	if not okClaim or type(claimRecord) ~= "table" then
		return { ok = false, message = "บันทึกการใช้โค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claimRecord.token ~= token then
		return { ok = false, message = "บัญชีนี้ใช้โค้ดนี้ไปแล้ว" }
	end

	coins.Value += definition.rewardCoins
	local saveOk, saveErr = pcall(function()
		playerCoinsStore:SetAsync(tostring(player.UserId), coins.Value)
	end)
	if not saveOk then
		warn("SultanService: เซฟเงินจากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(saveErr))
	end
	return { ok = true, message = "🎉 แลกสำเร็จ! ได้รับ " .. commas(definition.rewardCoins) .. " เหรียญ" }
end

local function redeemBoomboxPromoCode(player, code)
	local okClaim, claim = pcall(function()
		return boomboxPromoClaims:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okSave, entitlement = pcall(function()
		return boomboxPromoEntitlements:UpdateAsync(tostring(player.UserId), function(old)
			old = type(old) == "table" and old or {}
			old.owned = true
			old.codes = type(old.codes) == "table" and old.codes or {}
			old.codes[code] = true
			old.updatedAt = os.time()
			return old
		end, { player.UserId })
	end)
	if not okSave or type(entitlement) ~= "table" or entitlement.owned ~= true then
		warn("SultanService: บันทึกสิทธิ์ Boombox ไม่สำเร็จ " .. player.Name .. ": " .. tostring(entitlement))
		return { ok = false, message = "บันทึกรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end

	player:SetAttribute("BoomboxPromoOwned", true)
	return { ok = true, message = "🎉 แลกสำเร็จ! ได้รับ Boombox ถาวรแล้ว" }
end

local function redeemAutoFeederPromoCode(player, code)
	local okClaim, claim = pcall(function()
		return autoFeederPromoClaims:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okSave, entitlement = pcall(function()
		return autoFeederGiftStore:UpdateAsync("to_" .. player.UserId, function(old)
			old = type(old) == "table" and old or {}
			old.promoCodes = type(old.promoCodes) == "table" and old.promoCodes or {}
			old.promoCodes[code] = true
			old.seen = true
			old.t = old.t or os.time()
			return old
		end, { player.UserId })
	end)
	if not okSave or type(entitlement) ~= "table" or type(entitlement.promoCodes) ~= "table" or entitlement.promoCodes[code] ~= true then
		warn("SultanService: บันทึกสิทธิ์ชามจากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(entitlement))
		return { ok = false, message = "บันทึกรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end

	player:SetAttribute("PromoAutoFeederGranted", true)
	return { ok = true, message = "🎉 แลกสำเร็จ! ได้รับชามอาหารอัตโนมัติถาวรแล้ว" }
end

local function redeemLuckBoosterPromoCode(player, code)
	local okClaim, claim = pcall(function()
		return luckBoosterPromoClaims:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local grant = ServerScriptService:FindFirstChild("LuckBoosterPromoGrant")
	if not grant or not grant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local okGrant, granted, grantError = pcall(function()
		return grant:Invoke(player, code, 50)
	end)
	if not okGrant or granted ~= true then
		warn("SultanService: มอบหุ่นโชคจากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(grantError or granted))
		return { ok = false, message = "ส่งรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	return { ok = true, message = "🍀 แลกสำเร็จ! ได้รับหุ่นทองคำนำโชค x100 จำนวน 50 อันแล้ว" }
end

-- โค้ดแลกเบ็ดถาวร (BF-XXXXXX = เบ็ดผีเสื้อ NightMoth, BE-XXXXXX = เบ็ดผึ้งน้อย SunBee) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม
-- ลำดับ: อ่านว่าโค้ดถูกใช้หรือยัง -> เช็กว่าผู้เล่นมีเบ็ดอยู่แล้วไหม (มีแล้ว = ไม่จองโค้ด เก็บไว้ให้คนอื่นได้) -> จองโค้ดด้วย UpdateAsync -> มอบเบ็ด
-- มอบเบ็ดไม่สำเร็จ = โค้ดยังเป็นของคนเดิม ใช้โค้ดเดิมซ้ำได้ (เหมือนโค้ดชนิดอื่น)
local function redeemRodPromoCode(player, code, rodId, claimStore, rodName)
	local rodGrant = ServerScriptService:FindFirstChild("FishingRodPromoGrant")
	if not rodGrant or not rodGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end

	local okRead, existing = pcall(function() return claimStore:GetAsync(code) end)
	if not okRead then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	local claimedBy = type(existing) == "table" and existing.claimedBy or nil
	if claimedBy ~= nil and claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okCheck, owned = pcall(function() return rodGrant:Invoke(player, "check", rodId) end)
	if not okCheck or owned == nil then
		return { ok = false, message = "ตรวจสอบเบ็ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if owned == true then
		if claimedBy == player.UserId then
			return { ok = false, message = "คุณใช้โค้ดนี้ไปแล้ว " .. rodName .. "อยู่ในแถบไอเทมของคุณแล้ว" }
		end
		return { ok = false, message = "บัญชีนี้มี" .. rodName .. "อยู่แล้ว โค้ดนี้ยังไม่ถูกใช้ เก็บไว้ให้เพื่อนได้นะ" }
	end

	local okClaim, claim = pcall(function()
		return claimStore:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okGrant, granted, grantError = pcall(function() return rodGrant:Invoke(player, "grant", rodId) end)
	if not okGrant or granted ~= true then
		warn("SultanService: มอบ" .. rodName .. "จากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(grantError or granted))
		return { ok = false, message = "ส่งรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	return { ok = true, message = "🎉 แลกสำเร็จ! ได้รับ" .. rodName .. "ถาวรแล้ว อยู่ในแถบไอเทม 🎣" }
end

local function redeemButterflyRodPromoCode(player, code)
	return redeemRodPromoCode(player, code, "NightMoth", butterflyRodPromoClaims, "เบ็ดผีเสื้อ")
end

local function redeemSunBeeRodPromoCode(player, code)
	return redeemRodPromoCode(player, code, "SunBee", sunBeeRodPromoClaims, "เบ็ดผึ้งน้อย")
end

-- โค้ดช่องสัตว์ +1 (PT-XXXXXX) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม (2026-10-09)
-- ลำดับเหมือนโค้ดเบ็ด: โค้ดถูกใช้หรือยัง -> มี 3 ช่องอยู่แล้ว (Game Pass/ของขวัญ/โค้ดก่อน) = ไม่จองโค้ด -> จองโค้ด -> บันทึกสิทธิ์ใน PetSlotGift_v1 -> ตั้ง PetSlots
-- บันทึกสิทธิ์ไม่สำเร็จ = โค้ดยังเป็นของคนเดิม ใช้โค้ดเดิมซ้ำได้
local function redeemPetSlotPromoCode(player, code)
	local fullSlots = PetSlotConfig.BASE_SLOTS + PetSlotConfig.BONUS_SLOTS
	local okRead, existing = pcall(function() return petSlotPromoClaims:GetAsync(code) end)
	if not okRead then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	local claimedBy = type(existing) == "table" and existing.claimedBy or nil
	if claimedBy ~= nil and claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	-- PetManager ตั้ง PetSlots หลังเช็ก Game Pass/ของขวัญตอนเข้าเกม รอให้เช็กเสร็จก่อน
	local waitUntil = os.clock() + 12
	while player.Parent and player:GetAttribute("PetSlots") == nil and os.clock() < waitUntil do task.wait(0.25) end
	local slots = player:GetAttribute("PetSlots")
	if slots == nil then
		return { ok = false, message = "กำลังตรวจสอบช่องสัตว์ ลองใหม่อีกครั้ง" }
	end
	if slots >= fullSlots then
		if claimedBy == player.UserId then
			return { ok = false, message = "คุณใช้โค้ดนี้ไปแล้ว พาสัตว์ออกมาได้ " .. fullSlots .. " ตัวแล้ว" }
		end
		return { ok = false, message = "บัญชีนี้มีช่องสัตว์ +1 อยู่แล้ว โค้ดนี้ยังไม่ถูกใช้ เก็บไว้ให้เพื่อนได้นะ" }
	end

	local okClaim, claim = pcall(function()
		return petSlotPromoClaims:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okSave, entitlement = pcall(function()
		return petSlotGiftStore:UpdateAsync("to_" .. player.UserId, function(old)
			old = type(old) == "table" and old or {}
			old.promoCodes = type(old.promoCodes) == "table" and old.promoCodes or {}
			old.promoCodes[code] = true
			old.seen = true -- ไม่ต้องแจ้ง "ได้ของขวัญ" ตอนเข้าเกม
			old.t = old.t or os.time()
			return old
		end, { player.UserId })
	end)
	if not okSave or type(entitlement) ~= "table" or type(entitlement.promoCodes) ~= "table" or entitlement.promoCodes[code] ~= true then
		warn("SultanService: บันทึกช่องสัตว์จากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(entitlement))
		return { ok = false, message = "บันทึกรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end

	player:SetAttribute("PetSlots", fullSlots)
	return { ok = true, message = "🎉 แลกสำเร็จ! ได้รับช่องสัตว์ +1 ถาวร พาสัตว์ออกมาได้ " .. fullSlots .. " ตัวพร้อมกันแล้ว 🐾" }
end

-- โค้ดแม่มดน้อย (MG-XXXXXX) ใช้ได้โค้ดละหนึ่งครั้งทั่วเกม (2026-10-14) · 1 โค้ด = เท่ากับซื้อ 1 ครั้ง (ได้ตัว Lv.1 / +1 เลเวล)
-- ลำดับเหมือนโค้ดเบ็ด: โค้ดถูกใช้หรือยัง -> ยังไม่เปิด (ก่อนเทศกาล) / Lv.15 แล้ว = ไม่จองโค้ด -> จองโค้ด -> ให้ของ
-- ให้ของไม่สำเร็จ = โค้ดยังเป็นของคนเดิม ใช้โค้ดเดิมซ้ำได้ (กันกดซ้ำได้เลเวลเพิ่ม: บันทึก granted = true หลังให้แล้ว)
-- claimStore / grantAction / okMessage ไม่ใส่ = โค้ด MG- แบบเดิม · โค้ด MMG- ส่ง witchMaxPromoClaims + "grantMax" (เลเวลเต็มทันที)
local function redeemWitchPromoCode(player, code, claimStore, grantAction, okMessage)
	local witchPromoClaims = claimStore or witchPromoClaims
	grantAction = grantAction or "grant"
	local witchGrant = ServerScriptService:FindFirstChild("PremiumPetPromoGrant")
	if not witchGrant or not witchGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end

	local okRead, existing = pcall(function() return witchPromoClaims:GetAsync(code) end)
	if not okRead then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	local claimedBy = type(existing) == "table" and existing.claimedBy or nil
	if claimedBy ~= nil and claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end
	if claimedBy == player.UserId and existing.granted == true then
		return { ok = false, message = "คุณใช้โค้ดนี้ไปแล้ว" }
	end

	local okCheck, status = pcall(function() return witchGrant:Invoke(player, "check", "LittleWitch") end)
	if not okCheck or status == "loading" then
		return { ok = false, message = "กำลังโหลดข้อมูลสัตว์เลี้ยง ลองใหม่อีกครั้ง" }
	end
	if status == "notReleased" then
		return { ok = false, message = "แม่มดน้อยยังไม่เปิด ใช้โค้ดนี้ได้ตั้งแต่เทศกาลฮาโลวีนเริ่ม 🎃 โค้ดยังไม่ถูกใช้" }
	end
	if status == "maxed" then
		return { ok = false, message = "แม่มดน้อยของคุณเลเวลเต็มแล้ว โค้ดนี้ยังไม่ถูกใช้ เก็บไว้ให้เพื่อนได้นะ" }
	end

	local okClaim, claim = pcall(function()
		return witchPromoClaims:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end
	if claim.granted == true then
		return { ok = false, message = "คุณใช้โค้ดนี้ไปแล้ว" }
	end

	local okGrant, granted = pcall(function() return witchGrant:Invoke(player, grantAction, "LittleWitch") end)
	if not okGrant or granted ~= true then
		warn("SultanService: มอบแม่มดน้อยจากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(granted))
		return { ok = false, message = "ส่งรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local okMark, markErr = pcall(function()
		witchPromoClaims:UpdateAsync(code, function(old)
			if type(old) ~= "table" or old.claimedBy ~= player.UserId then return nil end
			old.granted = true
			old.grantedAt = os.time()
			return old
		end, { player.UserId })
	end)
	if not okMark then
		warn("SultanService: บันทึกว่าให้แม่มดน้อยแล้วไม่สำเร็จ " .. code .. ": " .. tostring(markErr))
	end
	return { ok = true, message = okMessage or "🔮 แลกสำเร็จ! ได้รับแม่มดน้อยแล้ว (มีอยู่แล้ว = +1 เลเวล) ดูได้ที่เมนูสัตว์เลี้ยง 🐾" }
end

-- โค้ดลามะ (RM-XXXXXX) ลำดับเหมือนโค้ดเบ็ด: โค้ดถูกใช้หรือยัง -> ระบบสัตว์ขี่ปิด / มีลามะแล้ว = ไม่จองโค้ด -> จองโค้ด -> ให้ลามะ (MountPromoGrant ใน MountGift)
-- ให้ไม่สำเร็จ = โค้ดยังเป็นของคนเดิม ใช้โค้ดเดิมซ้ำได้
local function redeemLlamaPromoCode(player, code)
	local mountGrant = ServerScriptService:FindFirstChild("MountPromoGrant")
	if not mountGrant or not mountGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end

	local okRead, existing = pcall(function() return llamaPromoClaims:GetAsync(code) end)
	if not okRead then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	local claimedBy = type(existing) == "table" and existing.claimedBy or nil
	if claimedBy ~= nil and claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okCheck, owned = pcall(function() return mountGrant:Invoke(player, "check") end)
	if not okCheck or owned == nil or owned == "loading" then
		return { ok = false, message = "กำลังโหลดข้อมูลสัตว์ขี่ ลองใหม่อีกครั้ง" }
	end
	if owned == "disabled" then
		return { ok = false, message = "ระบบสัตว์ขี่ยังไม่เปิด โค้ดนี้ยังไม่ถูกใช้" }
	end
	if owned == true then
		if claimedBy == player.UserId then
			return { ok = false, message = "คุณใช้โค้ดนี้ไปแล้ว ลามะอยู่ในตู้ตกแต่ง 🗄️ แท็บ 🐴 สัตว์ขี่แล้ว" }
		end
		return { ok = false, message = "บัญชีนี้มีลามะอยู่แล้ว โค้ดนี้ยังไม่ถูกใช้ เก็บไว้ให้เพื่อนได้นะ" }
	end

	local okClaim, claim = pcall(function()
		return llamaPromoClaims:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end

	local okGrant, granted = pcall(function() return mountGrant:Invoke(player, "grant") end)
	if not okGrant or granted ~= true then
		warn("SultanService: มอบลามะจากโค้ดไม่สำเร็จ " .. player.Name .. ": " .. tostring(granted))
		return { ok = false, message = "ส่งรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	return { ok = true, message = "🦙 แลกสำเร็จ! ได้รับลามะไม่ใช่ลามะถาวรแล้ว ขี่ได้จากตู้ตกแต่ง 🗄️ แท็บ 🐴 สัตว์ขี่" }
end

-- โค้ดตั๋วสุ่ม: จดการใช้ (granted = false) → เพิ่มตั๋ว (ใบเสร็จปลอมกันซ้ำอีกชั้น) → จด granted = true
-- เพิ่มตั๋วพัง = granted ยังเป็น false ใช้โค้ดเดิมซ้ำได้ · Studio ใช้คีย์/ใบเสร็จแยก "studio_" (ทดสอบแล้วไม่กินสิทธิ์ของจริง)
local function redeemTicketPromoCode(player, code, definition)
	local prefix = RunService:IsStudio() and "studio_" or ""
	local claimKey = prefix .. code .. "_" .. player.UserId
	local okClaim, claim = pcall(function()
		return ticketPromoClaims:UpdateAsync(claimKey, function(old)
			if type(old) == "table" then return old end
			return { claimedAt = os.time(), granted = false }
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.granted == true then
		return { ok = false, message = "บัญชีนี้ใช้โค้ดนี้ไปแล้ว" }
	end

	if GachaTickets.Add(player, definition.TicketType, definition.Amount, prefix .. "promo_" .. code) == nil then
		return { ok = false, message = "ส่งตั๋วไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	pcall(function()
		ticketPromoClaims:UpdateAsync(claimKey, function(old)
			old = type(old) == "table" and old or {}
			old.granted = true
			old.grantedAt = os.time()
			return old
		end, { player.UserId })
	end)
	local ticketType = GachaConfig.TicketTypes[definition.TicketType]
	local ticketName = ticketType and (ticketType.Icon .. " " .. ticketType.DisplayName) or "ตั๋วสุ่ม"
	return { ok = true, message = string.format("🎉 แลกสำเร็จ! ได้รับ %s %d ใบ ไปสุ่มที่ตู้สุ่มสัตว์เลี้ยงได้เลย", ticketName, definition.Amount) }
end

-- โค้ดใช้ครั้งเดียวทั่วเกมแบบให้ของได้ซ้ำไม่ได้ (PL-/PK- 2026-11-04): จองโค้ด -> ให้ของ -> จด granted = true
-- ให้ของไม่สำเร็จ = โค้ดยังเป็นของคนเดิม ใช้โค้ดเดิมซ้ำได้ · Studio ใช้คีย์ "studio_" แยก (ทดสอบแล้วไม่เผาโค้ดจริง)
local function redeemClaimedPromoCode(player, code, claimStore, grantFn, okMessage)
	local claimKey = (RunService:IsStudio() and "studio_" or "") .. code
	local okClaim, claim = pcall(function()
		return claimStore:UpdateAsync(claimKey, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
	end)
	if not okClaim or type(claim) ~= "table" then
		return { ok = false, message = "ตรวจสอบโค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
	end
	if claim.claimedBy ~= player.UserId then
		return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
	end
	if claim.granted == true then
		return { ok = false, message = "คุณใช้โค้ดนี้ไปแล้ว" }
	end

	local okGrant, granted = pcall(grantFn)
	if not okGrant or granted ~= true then
		warn("SultanService: ให้ของจากโค้ด " .. code .. " ไม่สำเร็จ " .. player.Name .. ": " .. tostring(granted))
		return { ok = false, message = "ส่งรางวัลไม่สำเร็จ ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local okMark, markErr = pcall(function()
		claimStore:UpdateAsync(claimKey, function(old)
			if type(old) ~= "table" or old.claimedBy ~= player.UserId then return nil end
			old.granted = true
			old.grantedAt = os.time()
			return old
		end, { player.UserId })
	end)
	if not okMark then
		warn("SultanService: บันทึกว่าให้ของจากโค้ด " .. code .. " แล้วไม่สำเร็จ: " .. tostring(markErr))
	end
	return { ok = true, message = okMessage }
end

local PLANT_QUOTA_PROMO_TIMES = 12 -- ครั้งละ +5 = แปลงปลูก +60 ช่อง
local HATCH_TOKEN_PROMO_AMOUNT = 12

local function redeemPlantQuotaPromoCode(player, code)
	local quotaGrant = ServerScriptService:FindFirstChild("PlantQuotaPromoGrant")
	if not quotaGrant or not quotaGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local ref = (RunService:IsStudio() and "studio_promo_" or "promo_") .. code -- ref ซ้ำ = PlantingSystem ไม่บวกซ้ำ
	return redeemClaimedPromoCode(player, code, plantQuotaPromoClaims, function()
		return quotaGrant:Invoke(player, ref, PLANT_QUOTA_PROMO_TIMES)
	end, "🌱 แลกสำเร็จ! ได้รับแปลงปลูก +60 ช่องถาวรแล้ว")
end

local function redeemHatchTokenPromoCode(player, code)
	local tokenGrant = ServerScriptService:FindFirstChild("ChickenTokenGrant")
	if not tokenGrant or not tokenGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local okCheck, ready = pcall(function() return tokenGrant:Invoke(player, "check") end)
	if not okCheck or ready ~= true then -- ยังไม่จองโค้ด
		return { ok = false, message = "กำลังโหลดข้อมูลฟาร์มไก่ ลองใหม่อีกครั้ง โค้ดนี้ยังไม่ถูกใช้" }
	end
	return redeemClaimedPromoCode(player, code, hatchTokenPromoClaims, function()
		return tokenGrant:Invoke(player, "hatch", HATCH_TOKEN_PROMO_AMOUNT)
	end, string.format("⚡ แลกสำเร็จ! ได้รับคูปองฟักไข่ทันที %d ใบ ใช้ได้ที่ตู้ฟักในฟาร์มไก่", HATCH_TOKEN_PROMO_AMOUNT))
end

-- มีสิทธิ์อยู่แล้ว (Game Pass/ของขวัญ/โค้ดก่อน) หรือยังโหลดไม่เสร็จ = ไม่จองโค้ด
local function redeemChickenAutoFeedPromoCode(player, code)
	local tokenGrant = ServerScriptService:FindFirstChild("ChickenTokenGrant")
	if not tokenGrant or not tokenGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local okCheck, status = pcall(function() return tokenGrant:Invoke(player, "checkFeed") end)
	if not okCheck or status == "loading" then
		return { ok = false, message = "กำลังโหลดข้อมูลฟาร์มไก่ ลองใหม่อีกครั้ง โค้ดนี้ยังไม่ถูกใช้" }
	end
	if status == "owned" then
		return { ok = false, message = "คุณมีระบบให้อาหารไก่อัตโนมัติอยู่แล้ว ไม่ต้องใช้โค้ดนี้ เก็บไว้ให้เพื่อนได้นะ" }
	end
	if status ~= "ok" then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	return redeemClaimedPromoCode(player, code, chickenAutoFeedPromoClaims, function()
		return tokenGrant:Invoke(player, "feed")
	end, "🤖 แลกสำเร็จ! ได้รับระบบให้อาหารไก่อัตโนมัติถาวรแล้ว รางเหลือน้อย = เทถุงอาหารจากกระเป๋าให้เอง")
end

-- โค้ดสัตว์พรีเมียม (N9-/GO- 2026-11-04) 1 โค้ด = เท่ากับซื้อ 1 ครั้ง (ยังไม่มี = Lv.1 · มีแล้ว = +1 เลเวล) · เลเวลเต็ม/ยังโหลดไม่เสร็จ = ไม่จองโค้ด
local function redeemPremiumPetPromoCode(player, code, petId, petName, claimStore, okMessage)
	local petGrant = ServerScriptService:FindFirstChild("PremiumPetPromoGrant")
	if not petGrant or not petGrant:IsA("BindableFunction") then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	local okCheck, status = pcall(function() return petGrant:Invoke(player, "check", petId) end)
	if not okCheck or status == "loading" then
		return { ok = false, message = "กำลังโหลดข้อมูลสัตว์เลี้ยง ลองใหม่อีกครั้ง" }
	end
	if status == "maxed" then
		return { ok = false, message = petName .. "ของคุณเลเวลเต็มแล้ว ไม่ต้องใช้โค้ดนี้ เก็บไว้ให้เพื่อนได้นะ" }
	end
	if status ~= "ok" then
		return { ok = false, message = "ระบบส่งรางวัลยังไม่พร้อม ลองใช้โค้ดเดิมอีกครั้ง" }
	end
	return redeemClaimedPromoCode(player, code, claimStore, function()
		return petGrant:Invoke(player, "grant", petId)
	end, okMessage)
end

local function redeemPromoCode(player, st, rawCode)
	if not (st and st.loaded) then return { ok = false, message = "ข้อมูลยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" } end
	if promoBusy[player] then return { ok = false, message = "กำลังตรวจโค้ดอยู่ รอสักครู่นะ" } end
	promoBusy[player] = true
	local okCall, result = pcall(function()
		if type(rawCode) ~= "string" or #rawCode > 40 then
			return { ok = false, message = "รูปแบบโค้ดไม่ถูกต้อง" }
		end

		local now = os.clock()
		local attempts = promoAttempts[player]
		if not attempts or now - attempts.started >= 60 then
			attempts = { started = now, count = 0 }
			promoAttempts[player] = attempts
		end
		if attempts.count >= 5 then
			return { ok = false, message = "ลองโค้ดครบ 5 ครั้งแล้ว กรุณารอ 1 นาที" }
		end
		attempts.count += 1

		local code = string.upper(rawCode):gsub("[^A-Z0-9]", "")
		local coinPromo = coinPromoCodes[code]
		if coinPromo then return redeemCoinPromoCode(player, code, coinPromo) end
		if boomboxPromoCodes[code] then return redeemBoomboxPromoCode(player, code) end
		if autoFeederPromoCodes[code] then return redeemAutoFeederPromoCode(player, code) end
		if luckBoosterPromoCodes[code] then return redeemLuckBoosterPromoCode(player, code) end
		if butterflyRodPromoCodes[code] then return redeemButterflyRodPromoCode(player, code) end
		if sunBeeRodPromoCodes[code] then return redeemSunBeeRodPromoCode(player, code) end
		if petSlotPromoCodes[code] then return redeemPetSlotPromoCode(player, code) end
		if witchPromoCodes[code] then return redeemWitchPromoCode(player, code) end
		if llamaPromoCodes[code] then return redeemLlamaPromoCode(player, code) end
		if ticketPromoCodes[code] then return redeemTicketPromoCode(player, code, ticketPromoCodes[code]) end
		if plantQuotaPromoCodes[code] then return redeemPlantQuotaPromoCode(player, code) end
		if hatchTokenPromoCodes[code] then return redeemHatchTokenPromoCode(player, code) end
		if chickenAutoFeedPromoCodes[code] then return redeemChickenAutoFeedPromoCode(player, code) end
		if nineTailFoxPromoCodes[code] then
			return redeemPremiumPetPromoCode(player, code, "NineTailFox", "จิ้งจอกเก้าหาง", nineTailFoxPromoClaims, "🦊 แลกสำเร็จ! ได้รับจิ้งจอกเก้าหางแล้ว (มีอยู่แล้ว = +1 เลเวล) ดูได้ที่เมนูสัตว์เลี้ยง 🐾")
		end
		if scarecrowGhostPromoCodes[code] then
			return redeemPremiumPetPromoCode(player, code, "ScarecrowGhost", "ผีน้อยนักปักหุ่น", scarecrowGhostPromoClaims, "👻 แลกสำเร็จ! ได้รับผีน้อยนักปักหุ่นแล้ว (มีอยู่แล้ว = +1 เลเวล) ดูได้ที่เมนูสัตว์เลี้ยง 🐾")
		end
		if witchMaxPromoCodes[code] then
			return redeemWitchPromoCode(player, code, witchMaxPromoClaims, "grantMax", "🔮 แลกสำเร็จ! ได้รับแม่มดน้อย Lv.15 (เลเวลเต็ม) ดูได้ที่เมนูสัตว์เลี้ยง 🐾")
		end
		if not promoCodes[code] then return { ok = false, message = "ไม่พบโค้ดนี้" } end
		if st.owned or player:GetAttribute("IsSultan") == true then
			return { ok = false, message = "บัญชีนี้มีสิทธิ์สุลต่านอยู่แล้ว" }
		end
		local waitUntil = os.clock() + 12
		while player.Parent and player:GetAttribute("IsSultan") == nil and os.clock() < waitUntil do task.wait(0.25) end
		if player:GetAttribute("IsSultan") == nil then
			return { ok = false, message = "กำลังตรวจสอบสิทธิ์สุลต่าน ลองใหม่อีกครั้ง" }
		end
		if player:GetAttribute("IsSultan") == true or st.owned then
			return { ok = false, message = "บัญชีนี้มีสิทธิ์สุลต่านอยู่แล้ว" }
		end

		local claim = promoCodeStore:UpdateAsync(code, function(old)
			old = type(old) == "table" and old or {}
			if old.claimedBy == nil then
				old.claimedBy = player.UserId
				old.claimedAt = os.time()
			end
			return old
		end, { player.UserId })
		if type(claim) ~= "table" then
			return { ok = false, message = "บันทึกการใช้โค้ดไม่สำเร็จ ลองใหม่อีกครั้ง" }
		end
		if claim.claimedBy ~= player.UserId then
			return { ok = false, message = "โค้ดนี้ถูกใช้ไปแล้ว" }
		end

		local saved = store:UpdateAsync(tostring(player.UserId), function(old)
			old = type(old) == "table" and old or {}
			old.promoSultan = true
			return old
		end, { player.UserId })
		if type(saved) ~= "table" or saved.promoSultan ~= true then
			return { ok = false, message = "บันทึกสิทธิ์ไม่สำเร็จ โค้ดนี้ยังใช้ซ้ำได้กับบัญชีเดิม" }
		end
		st.data = saved
		grant(player, st, "purchase")
		return { ok = true, message = "🎉 แลกสำเร็จ! ได้รับสิทธิ์สุลต่านเต็มแพ็กถาวรแล้ว" }
	end)
	promoBusy[player] = nil
	if not okCall then
		warn("SultanService: แลกโค้ดไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(result))
		return { ok = false, message = "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง" }
	end
	return result
end

request.OnServerInvoke = function(player, action, value)
	local st = states[player]
	if action == "redeemCode" then
		return redeemPromoCode(player, st, value)
	end
	if action == "giftSelect" then -- ส่งแพ็กสุลต่านให้เพื่อน (ไม่ต้องเป็นสุลต่านเองก็ส่งได้)
		if not (st and st.loaded) then return { ok = false, message = "ยังโหลดไม่เสร็จ" } end
		return giftSelect(player, value)
	end
	if not (st and st.loaded and st.owned) then return { ok = false, message = "ต้องมีแพ็กสุลต่านก่อน" } end
	if action == "aura" then
		local on = value == true
		st.data.aura = on
		player:SetAttribute("SultanAura", on)
		local ok = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				old = type(old) == "table" and old or {}
				old.aura = on
				return old
			end, { player.UserId })
		end)
		return { ok = true, aura = on, saved = ok }
	elseif action == "announce" then
		-- เปิด/ปิดข้อความ "ท่านสุลต่าน ... เข้าสู่ฟาร์มแล้ว!" ตอนเข้าเซิร์ฟ
		local on = value == true
		st.data.announce = on
		player:SetAttribute("SultanJoinAnnounce", on)
		local ok = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				old = type(old) == "table" and old or {}
				old.announce = on
				return old
			end, { player.UserId })
		end)
		return { ok = true, announce = on, saved = ok }
	end
	return { ok = false, message = "คำขอไม่ถูกต้อง" }
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	promoBusy[player] = nil
	promoAttempts[player] = nil
	giftPending[player] = nil
	giftPrompting[player] = nil
end)

-- อยู่ข้ามเที่ยงคืน = ได้ตั๋วรายวันของวันใหม่เลยไม่ต้องออกเข้าใหม่
task.spawn(function()
	while true do
		task.wait(300)
		for player, st in pairs(states) do
			if st.owned and st.loaded and st.data.lastDaily ~= Config.DayIndex() then
				task.spawn(giveDaily, player, st)
			end
		end
	end
end)
