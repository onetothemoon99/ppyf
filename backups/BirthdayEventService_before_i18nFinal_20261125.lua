-- BACKUP of ServerScriptService.BirthdayEventService before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into ServerScriptService.BirthdayEventService.Source in Studio
-- BirthdayEventService: กิจกรรม "อรพรวันเกิด" (สร้าง 2026-10-19) ค่าต่างๆ ดู ReplicatedStorage.BirthdayEventConfig
-- ช่วงกิจกรรม: สร้างกล่องของขวัญ workspace.BirthdayEventGift ที่ลานร้านค้า + ตั้ง workspace Attribute BirthdayEventActive / BirthdayEventEndsAt / BirthdayEventHonoree
--   หมดเวลา = ลบกล่อง + ปิด Attribute (เช็กทุก 2 วิ)
-- ทำภารกิจครบ: WishingPond ยิง BindableEvent ServerScriptService.WishingPondWished (player, wishId, target, honoreeName)
--   พรวันเกิด + ผู้รับพร = VXLLLYN (อยู่ในเซิร์ฟ หรือเลือกแถวพิเศษตอนเธอไม่อยู่) -> ให้รางวัลอัตโนมัติ บัญชีละ 1 ครั้ง
-- กันรับซ้ำ: DataStore BirthdayEvent_v1 คีย์ "<Id>:<userId>" (Studio นำหน้า "studio:") จองด้วย token ก่อนให้ของ ให้ไม่สำเร็จ = คืนสิทธิ์ กด "รับรางวัล" ใหม่ได้ในหน้าต่างกิจกรรม
--   ตั๋ว/โควต้าใช้เลขอ้างอิงตาม Id = รับใหม่หลังพลาดกลางทางก็ไม่ได้ซ้ำ · VIP ถาวรบันทึกใน VipGift_v1 "to_<userId>" ที่เดียวกับของขวัญ VIP (มี VIP/สุลต่านแล้ว = ไม่ได้)
-- Studio (ทดสอบใน dev) workspace Attributes:
--   DevBirthdayForce = true    บังคับเปิดนอกช่วงเวลา (หมดเวลาทดสอบ = อีก 1 ชม.)
--   DevBirthdayRepeat = true   รับรางวัลซ้ำได้ (คีย์บันทึกใหม่ทุกครั้งที่กด Play / ตั้ง DevBirthdayReset = true ระหว่าง Play = รีเซ็ตทันที)
--   DevBirthdaySimulate = true ไม่ให้ของจริง (ตั๋ว/โควต้า/VIP/เหรียญ) แค่แจ้งเตือนว่าได้ กันของเข้าบัญชีเจ้าของตอนทดสอบ
--   (โยนน้อยชิ้นลง: DevWishThrowsNeeded ใน WishingPond)
-- ในเกมจริงทุกสวิตช์ไม่มีผล (เช็ก RunService:IsStudio())

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("BirthdayEventConfig"))
local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))

local store = DataStoreService:GetDataStore("BirthdayEvent_v1")
local vipGiftStore = DataStoreService:GetDataStore("VipGift_v1")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local request = remoteEvents:FindFirstChild("BirthdayEventRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "BirthdayEventRequest"
	request.Parent = remoteEvents
end
local wished = ServerScriptService:FindFirstChild("WishingPondWished")
if not wished then
	wished = Instance.new("BindableEvent")
	wished.Name = "WishingPondWished"
	wished.Parent = ServerScriptService
end

local claimed = {}   -- [player] = true (รับแล้ว) / false / nil (ยังเช็กไม่เสร็จ)
local completed = {} -- [player] = true ทำภารกิจครบแล้วในเซิร์ฟนี้ (ไว้กดรับใหม่ถ้าให้ของไม่สำเร็จ)
local busy = {}

local DEV_FORCE_SECONDS = 3600
local devForcedAt
local function window()
	if RunService:IsStudio() and workspace:GetAttribute("DevBirthdayForce") == true then
		devForcedAt = devForcedAt or os.time()
		return true, devForcedAt + DEV_FORCE_SECONDS
	end
	devForcedAt = nil
	return Config.IsActive(os.time()), Config.EndsAt
end

local IS_STUDIO = RunService:IsStudio()
local devSession = HttpService:GenerateGUID(false):sub(1, 8)
local function devFlag(name)
	return IS_STUDIO and workspace:GetAttribute(name) == true
end

local function keyOf(player)
	if devFlag("DevBirthdayRepeat") then
		return "studio:" .. devSession .. ":" .. Config.Id .. ":" .. player.UserId
	end
	return (IS_STUDIO and "studio:" or "") .. Config.Id .. ":" .. player.UserId
end

local function say(player, text)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, "\u{200B}" .. text) end
end

local function hasVip(player)
	return player:GetAttribute("IsVip") == true or player:GetAttribute("IsSultan") == true
end

-- ============ เช็กตอนเข้าเกม ============
local function loadClaim(player)
	if claimed[player] ~= nil then return end
	local ok, rec = DataLoadRetry.Load(player, "BirthdayEventService", DataLoadRetry.Get(store, keyOf(player)))
	if ok and player.Parent then
		claimed[player] = type(rec) == "table" and rec.token ~= nil
		player:SetAttribute("BirthdayEventDone", claimed[player] or nil)
	end
end

local function onPlayerAdded(player)
	if window() then loadClaim(player) end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
Players.PlayerRemoving:Connect(function(player)
	claimed[player] = nil
	completed[player] = nil
	busy[player] = nil
end)

local function waitReady(player)
	local t0 = os.clock()
	while player.Parent and os.clock() - t0 < 60 do
		if player:GetAttribute("CoinsLoaded") == true and claimed[player] ~= nil then return true end
		if claimed[player] == nil then task.spawn(loadClaim, player) end
		task.wait(1)
	end
	return false
end

local function fire(scriptName, child, player)
	local s = ServerScriptService:FindFirstChild(scriptName)
	local ev = s and s:FindFirstChild(child)
	if ev then ev:Fire(player) end
end

local function release(key, token)
	pcall(function()
		store:UpdateAsync(key, function(old)
			if type(old) == "table" and old.token == token then return { released = true, t = os.time() } end
			return nil
		end)
	end)
end

-- ============ ให้รางวัล ============
local function claim(player)
	if not window() then return { ok = false, message = "กิจกรรมหมดเวลาแล้ว" } end
	if not waitReady(player) then return { ok = false, message = "ยังโหลดข้อมูลไม่เสร็จ ลองกดรับรางวัลที่กล่องของขวัญอีกครั้ง" } end
	if claimed[player] then return { ok = false, already = true, message = "คุณรับรางวัลกิจกรรมนี้ไปแล้ว" } end
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("เหรียญ")
	if not coins then return { ok = false, message = "ไม่พบข้อมูลเหรียญ ลองใหม่อีกครั้ง" } end

	local key = keyOf(player)
	local token = HttpService:GenerateGUID(false)
	local giveVip = Config.GiveVip and not hasVip(player)
	local okClaim, rec = pcall(function()
		return store:UpdateAsync(key, function(old)
			if type(old) == "table" and old.token ~= nil then return old end
			return { userId = player.UserId, claimedAt = os.time(), token = token, coins = Config.Coins, tickets = Config.PremiumTickets, quota = Config.QuotaRewards, vip = giveVip }
		end, { player.UserId })
	end)
	if not okClaim or type(rec) ~= "table" then
		warn("BirthdayEventService: จองสิทธิ์ไม่สำเร็จ " .. player.Name .. ": " .. tostring(rec))
		return { ok = false, message = "บันทึกไม่สำเร็จ กดรับรางวัลที่กล่องของขวัญอีกครั้ง" }
	end
	if rec.token ~= token then
		claimed[player] = true
		player:SetAttribute("BirthdayEventDone", true)
		return { ok = false, already = true, message = "คุณรับรางวัลกิจกรรมนี้ไปแล้ว" }
	end

	if devFlag("DevBirthdaySimulate") then
		claimed[player] = true
		completed[player] = nil
		player:SetAttribute("BirthdayEventDone", true)
		local msg = "🎂 [ทดสอบ] สำเร็จกิจกรรม" .. Config.HonoreeTitle .. "วันเกิด! จะได้: 🎫 ตั๋วพรีเมียม x" .. Config.PremiumTickets
			.. " · 🌱 โควต้า +5 · 💰 " .. Config.Coins .. (giveVip and " · 👑 VIP" or " · (มี VIP แล้ว)") .. " (ไม่ให้ของจริง)"
		print("🎂 BirthdayEventService: [ทดสอบ] " .. player.Name .. " สำเร็จ ไม่ได้ให้ของจริง (key " .. key .. ")")
		say(player, msg)
		return { ok = true, message = msg, simulated = true }
	end

	local refBase = (IS_STUDIO and ("studio_" .. token .. "_") or "") .. "bday_" .. Config.Id
	-- ตั๋วพรีเมียม
	if (Config.PremiumTickets or 0) > 0 and GachaTickets.Add(player, "Premium", Config.PremiumTickets, refBase .. "_tickets") == nil then
		warn("BirthdayEventService: ให้ตั๋วไม่สำเร็จ " .. player.Name)
		release(key, token)
		return { ok = false, message = "ส่งตั๋วไม่สำเร็จ กดรับรางวัลที่กล่องของขวัญอีกครั้ง" }
	end
	-- โควต้าปลูก +5 (เลขอ้างอิงเดิม = ไม่บวกซ้ำ)
	local quotaGrant = ServerScriptService:FindFirstChild("PlantQuotaPromoGrant")
	for i = 1, (Config.QuotaRewards or 0) do
		local okQ, res = pcall(function() return quotaGrant and quotaGrant:Invoke(player, refBase .. "_quota_" .. i) end)
		if not (okQ and res == true) then
			warn("BirthdayEventService: ให้โควต้าไม่สำเร็จ " .. player.Name .. ": " .. tostring(res))
			release(key, token)
			return { ok = false, message = "ส่งโควต้าไม่สำเร็จ กดรับรางวัลที่กล่องของขวัญอีกครั้ง" }
		end
	end
	-- VIP ถาวร (เฉพาะคนที่ยังไม่มี)
	local gotVip = false
	if giveVip then
		local okV, err = pcall(function()
			vipGiftStore:UpdateAsync("to_" .. player.UserId, function(old)
				if type(old) == "table" then return nil end
				return { from = 0, fromName = "กิจกรรม" .. Config.HonoreeTitle .. "วันเกิด", t = os.time(), receipt = "event_" .. Config.Id, seen = true }
			end, { player.UserId })
		end)
		if okV then
			gotVip = true
			player:SetAttribute("AdminVipGranted", true) -- VipService เปิด VIP ทันที (เหมือน /give vip)
		else
			warn("BirthdayEventService: บันทึก VIP ไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
			release(key, token)
			return { ok = false, message = "ส่ง VIP ไม่สำเร็จ กดรับรางวัลที่กล่องของขวัญอีกครั้ง" }
		end
	end
	-- เหรียญ (ท้ายสุด ไม่ต้องดึงคืน)
	coins.Value += Config.Coins or 0
	claimed[player] = true
	completed[player] = nil
	player:SetAttribute("BirthdayEventDone", true)
	fire("LeaderstatsSetup", "SaveCoinsNow", player)
	local parts = {
		"🎫 ตั๋วสุ่มพรีเมียม x" .. Config.PremiumTickets,
		"🌱 โควต้าปลูก +5",
		"💰 " .. tostring(Config.Coins) .. " เหรียญ",
	}
	if gotVip then table.insert(parts, "👑 VIP ถาวร") end
	print("🎂 BirthdayEventService: " .. player.Name .. " รับรางวัล " .. Config.Id .. (gotVip and " (+VIP)" or ""))
	local msg = "🎂 สำเร็จกิจกรรม" .. Config.HonoreeTitle .. "วันเกิด! ได้รับ: " .. table.concat(parts, " · ")
	say(player, msg)
	return { ok = true, message = msg, vip = gotVip }
end

local function safeClaim(player)
	if busy[player] then return { ok = false, message = "กำลังส่งรางวัล..." } end
	busy[player] = true
	local ok, result = pcall(claim, player)
	busy[player] = nil
	if not ok then
		warn("BirthdayEventService: claim error " .. player.Name .. ": " .. tostring(result))
		return { ok = false, message = "ระบบขัดข้อง กดรับรางวัลที่กล่องของขวัญอีกครั้ง" }
	end
	if not result.ok and not result.already then say(player, "⚠️ " .. result.message) end
	return result
end

-- ============ ขอพรที่บ่อนางฟ้า ============
wished.Event:Connect(function(player, wishId, target, honoreeName)
	if wishId ~= "Birthday" or not window() then return end
	local forHonoree = Config.IsHonoree(honoreeName)
		or (typeof(target) == "Instance" and target:IsA("Player") and (Config.IsHonoree(target.Name) or Config.IsHonoree(target.DisplayName)))
	if not forHonoree then return end
	completed[player] = true
	if claimed[player] == true then return end
	task.delay(4, function() -- ให้เห็นพรพุ่งไปก่อนค่อยบอกรางวัล
		if player.Parent then safeClaim(player) end
	end)
end)

request.OnServerInvoke = function(player, action)
	local active, endsAt = window()
	if action == "get" then
		if active and claimed[player] == nil then
			local t0 = os.clock()
			task.spawn(loadClaim, player)
			while player.Parent and claimed[player] == nil and os.clock() - t0 < 8 do task.wait(0.25) end
		end
		local online = false
		for _, p in ipairs(Players:GetPlayers()) do
			if Config.IsHonoree(p.Name) then online = true end
		end
		return {
			active = active, endsAt = endsAt, now = os.time(),
			done = claimed[player] == true,
			canRetry = completed[player] == true and claimed[player] ~= true,
			honoreeOnline = online,
			hasVip = hasVip(player),
		}
	elseif action == "claim" then
		if not completed[player] then return { ok = false, message = "ทำภารกิจให้ครบก่อนนะ" } end
		return safeClaim(player)
	end
	return nil
end

-- ============ กล่องของขวัญที่ลานร้านค้า ============
local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function buildBox()
	local PINK = Color3.fromRGB(255, 140, 190)
	local LID = Color3.fromRGB(255, 110, 170)
	local GOLD = Color3.fromRGB(255, 215, 80)
	local base = CFrame.new(Config.BOX_POS) * CFrame.Angles(0, math.rad(30), 0)
	local m = Instance.new("Model")
	m.Name = "BirthdayEventGift"
	local body = part(m, "Body", Vector3.new(5, 4, 5), base * CFrame.new(0, 2, 0), PINK)
	body.CanCollide = true
	m.PrimaryPart = body
	part(m, "Lid", Vector3.new(5.6, 1.1, 5.6), base * CFrame.new(0, 4.55, 0), LID)
	part(m, "RibbonX", Vector3.new(5.2, 4.1, 0.9), base * CFrame.new(0, 2, 0), GOLD)
	part(m, "RibbonZ", Vector3.new(0.9, 4.1, 5.2), base * CFrame.new(0, 2, 0), GOLD)
	part(m, "LidRibbonX", Vector3.new(5.8, 1.2, 0.95), base * CFrame.new(0, 4.55, 0), GOLD)
	part(m, "LidRibbonZ", Vector3.new(0.95, 1.2, 5.8), base * CFrame.new(0, 4.55, 0), GOLD)
	part(m, "BowL", Vector3.new(1.9, 1.2, 0.6), base * CFrame.new(-0.9, 5.6, 0) * CFrame.Angles(0, 0, math.rad(30)), GOLD)
	part(m, "BowR", Vector3.new(1.9, 1.2, 0.6), base * CFrame.new(0.9, 5.6, 0) * CFrame.Angles(0, 0, math.rad(-30)), GOLD)
	local knot = part(m, "Knot", Vector3.new(0.9, 0.9, 0.9), base * CFrame.new(0, 5.45, 0), Color3.fromRGB(255, 190, 60))
	knot.Shape = Enum.PartType.Ball
	-- ประกาย + แสง
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 150, 210))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Rate = 10
	pe.Speed = NumberRange.new(1, 2.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Parent = body
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 220)
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = body
	-- กด/คลิก (ฝั่งผู้เล่นเปิดหน้าต่างเองใน BirthdayEventGui)
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 60
	cd.Parent = m -- อยู่ใต้ Model = คลิกส่วนไหนของกล่องก็ได้
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BirthdayPrompt"
	prompt.ObjectText = Config.Title
	prompt.ActionText = "ดูกิจกรรม"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = body
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = workspace
	return m
end

-- Studio: DevBirthdayReset = true ระหว่าง Play = เริ่มใหม่ (คีย์ใหม่ + ทุกคนยังไม่ได้รับ) แล้วปิดสวิตช์เอง
if IS_STUDIO then
	workspace:GetAttributeChangedSignal("DevBirthdayReset"):Connect(function()
		if workspace:GetAttribute("DevBirthdayReset") ~= true then return end
		workspace:SetAttribute("DevBirthdayRepeat", true)
		devSession = HttpService:GenerateGUID(false):sub(1, 8)
		for _, p in ipairs(Players:GetPlayers()) do
			claimed[p] = false
			completed[p] = nil
			p:SetAttribute("BirthdayEventDone", nil)
		end
		workspace:SetAttribute("DevBirthdayReset", nil)
		print("🎂 BirthdayEventService: [ทดสอบ] รีเซ็ตแล้ว รับใหม่ได้")
	end)
end

local box
local wasActive = nil
local function tick()
	local active, endsAt = window()
	if active ~= wasActive then
		wasActive = active
		if active then
			workspace:SetAttribute("BirthdayEventEndsAt", endsAt)
			workspace:SetAttribute("BirthdayEventHonoree", Config.HonoreeName)
			workspace:SetAttribute("BirthdayEventActive", true)
			if not (box and box.Parent) then box = buildBox() end
			for _, p in ipairs(Players:GetPlayers()) do task.spawn(loadClaim, p) end
			print("🎂 BirthdayEventService: เปิดกิจกรรม " .. Config.Id .. " ถึง " .. os.date("!%Y-%m-%d %H:%M UTC", endsAt))
		else
			workspace:SetAttribute("BirthdayEventActive", nil)
			workspace:SetAttribute("BirthdayEventEndsAt", nil)
			if box then box:Destroy() box = nil end
			local old = workspace:FindFirstChild("BirthdayEventGift")
			if old then old:Destroy() end
		end
	elseif active then
		workspace:SetAttribute("BirthdayEventEndsAt", endsAt)
	end
end

task.spawn(function()
	while true do
		local ok, err = pcall(tick)
		if not ok then warn("BirthdayEventService: " .. tostring(err)) end
		task.wait(2)
	end
end)
