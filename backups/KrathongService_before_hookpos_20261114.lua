-- BACKUP 2026-11-14: game.ServerScriptService.Krathong.KrathongService (Script) before "hang point from the hook itself" (HangAt attribute no longer used)
-- Restore: in Studio open ServerScriptService.Krathong.KrathongService, replace its whole Source with everything below the "-- ===== SOURCE =====" line.
-- ===== SOURCE =====
-- KrathongService (2026-11-07): กิจกรรมลอยกระทง
--   ร้านแม่ค้า (โคลน ServerStorage.KrathongTemplates.Stall มาวางตอนเทศกาลเปิด = workspace.KrathongStall) ซื้อด้วยเหรียญ -> เข้ากระเป๋า
--   จุดลอยบนปลายท่า PondDock1 (workspace.KrathongFloatSpot) กด -> หน้าต่างเลือกกระทง + คำอธิษฐาน (ผ่านตัวกรอง Roblox) -> เสียกระทง 1 ใบ
--   ลอยแล้วได้บัฟ: Attribute KrathongBuffUntil (os.time) + KrathongEventBonus บนผู้เล่น (FishingSystem.rollFish อ่าน) ไม่เซฟ ออกเกม = หาย
--   ภาพกระทงลอยน้ำทำฝั่งผู้เล่นทั้งหมด (KrathongFx "float") เซิร์ฟไม่มีชิ้นส่วนในน้ำ
-- Remote: RemoteEvents.KrathongRequest (RemoteFunction: "buy", id, qty / "float", id, wish / "info") · KrathongOpen (เซิร์ฟ -> ผู้เล่น เปิดหน้าต่าง) · KrathongFx (ทุกคน)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")
-- ของตกแต่งธีมลอยกระทง (ร้าน / ลานปล่อยโคม / ลานแขวนโคม) เก็บไว้ที่ workspace.KrathongDecor ให้เห็น/แก้ได้ในโหมดแก้ไข (ผู้ใช้สั่ง 2026-11-08)
-- ตอนเซิร์ฟเริ่ม ย้ายกลับเข้า ServerStorage.KrathongTemplates ทันที (ก่อนผู้เล่นเข้า) แล้ว build() โคลนออกมาเฉพาะตอนสวิตช์เทศกาลเปิด เหมือนเดิม
do
	local decor = workspace:FindFirstChild("KrathongDecor")
	if decor then
		local templates = ServerStorage:FindFirstChild("KrathongTemplates")
		if not templates then
			templates = Instance.new("Folder")
			templates.Name = "KrathongTemplates"
			templates.Parent = ServerStorage
		end
		local moved = {}
		for _, m in ipairs(decor:GetChildren()) do
			local base = m.Name
			if moved[base] then
				moved[base] += 1
				m.Name = base .. "_" .. moved[base] -- ชื่อซ้ำ (เช่นลานแขวนโคมลานที่สอง) เก็บไว้ทั้งหมด
			else
				moved[base] = 1
				local old = templates:FindFirstChild(base)
				if old then old:Destroy() end
			end
			m.Parent = templates
		end
		decor:Destroy()
	end
end

local Config = require(ReplicatedStorage:WaitForChild("KrathongConfig"))
local SeasonConfig = require(ReplicatedStorage:WaitForChild("SeasonConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local KrathongItems = require(script.Parent:WaitForChild("KrathongItems"))

local saveCoinsNow = ServerScriptService:WaitForChild("LeaderstatsSetup"):WaitForChild("SaveCoinsNow", 30)
local saveInventoryNow = ServerScriptService:WaitForChild("InventorySystem"):WaitForChild("SaveInventoryNow", 30)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local function remote(class, name)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local requestRemote = remote("RemoteFunction", "KrathongRequest")
local openRemote = remote("RemoteEvent", "KrathongOpen")
local fxRemote = remote("RemoteEvent", "KrathongFx")

local function lang(player)
	local ok, l = pcall(Localization.GetLanguage, player)
	return (ok and l == "en") and "en" or "th"
end
local function msg(player, th, en)
	return lang(player) == "en" and en or th
end
local function coinsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("เหรียญ")
end
local function active()
	return SeasonConfig.IsActive(Config.SEASON)
end

local busy = {} -- [player] = กำลังทำคำขออยู่ (กันกดซ้ำ)

-- ============ บัฟ (กระทง / โคมลอย / รอบปล่อยพร้อมกัน) ============
-- ต่อเวลาได้ ไม่เกิน BUFF_MAX_MINUTES · โบนัส = ค่าสูงสุดที่ยังไม่หมดเวลา · คืน untilT, bonus
local function applyBuff(player, minutes, eventBonus)
	local t = os.time()
	local untilT = tonumber(player:GetAttribute("KrathongBuffUntil")) or 0
	local bonus = untilT > t and (tonumber(player:GetAttribute("KrathongEventBonus")) or 0) or 0
	untilT = math.min(math.max(untilT, t) + minutes * 60, t + Config.BUFF_MAX_MINUTES * 60)
	bonus = math.max(bonus, eventBonus)
	player:SetAttribute("KrathongBuffUntil", untilT)
	player:SetAttribute("KrathongEventBonus", bonus)
	return untilT, bonus
end
local function buffMsg(player, head, untilT, bonus)
	local mins = math.max(1, math.floor((untilT - os.time()) / 60 + 0.5))
	local pct = math.floor(bonus * 100 + 0.5)
	return msg(player, head[1] .. " โชคปลาอีเวนต์ +" .. pct .. "% อีก " .. mins .. " นาที", head[2] .. " Event fish luck +" .. pct .. "% for " .. mins .. " min")
end

local function inField(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local d = root.Position - Config.LANTERN_FIELD
	return Vector3.new(d.X, 0, d.Z).Magnitude <= Config.LANTERN_RADIUS + 2 and math.abs(d.Y) < 20, root.Position
end

-- ปล่อยโคมลอย ใช้โคมในกระเป๋า 1 ดวง (ใช้ร่วม: กด E ที่ลาน / ปุ่มปล่อยที่ไหนก็ได้ 2026-11-11)
--   ownerId ส่งไปด้วย = ทุกเครื่องเล่นท่าชูโคมขึ้นฟ้าให้ตัวละครนั้น (KrathongClient)
local lastLantern = {}
local function doRelease(player, pos)
	local id = "SkyLantern"
	local def = Config.Types[id]
	local now = os.clock()
	if lastLantern[player] and now - lastLantern[player] < Config.FLOAT_COOLDOWN then
		return { ok = false, message = msg(player, "รอแป๊บนึงนะ", "Wait a moment") }
	end
	if KrathongItems.Count(player, id) < 1 then
		return { ok = false, message = msg(player, "ไม่มีโคมลอย ซื้อได้ที่ร้านแม่ค้ากระทง หรือรอรอบปล่อยพร้อมกัน (ฟรี)", "No sky lantern. Buy one at the krathong stall, or join the group release (free)") }
	end
	lastLantern[player] = now
	if not KrathongItems.Take(player, id, 1, lang(player)) then return { ok = false, message = "?" } end
	if saveInventoryNow then saveInventoryNow:Fire(player) end
	local untilT, bonus = applyBuff(player, def.BuffMinutes, def.EventBonus)
	player:SetAttribute("LanternReleased", (player:GetAttribute("LanternReleased") or 0) + 1)
	fxRemote:FireAllClients("lantern", { list = { { owner = player.DisplayName, ownerId = player.UserId, pos = pos } }, t0 = workspace:GetServerTimeNow() })
	return { ok = true, message = buffMsg(player, { "🏮 ปล่อยโคมแล้ว!", "🏮 Lantern released!" }, untilT, bonus) }
end
-- กด E ที่ลานบนท่าเรือ (ไม่ต้องถือในมือ แค่มีในกระเป๋า)
local function releaseLantern(player)
	local ok, pos = inField(player)
	if not ok then return { ok = false, message = msg(player, "ไปยืนในลานปล่อยโคมก่อนนะ", "Stand in the lantern field first") } end
	return doRelease(player, pos)
end

-- เหนือหัวโล่งไหม (ปล่อยที่ไหนก็ได้ 2026-11-11): ยิงขึ้น SKY_CLEAR สตั๊ดจากเหนือหัว
--   ข้ามตัวละครทุกคน + ชิ้นส่วนโปร่งใส/CanCollide ปิด (ใบไม้ กำแพงล่องหน ฯลฯ) · ชนหลังคาทึบหรือ terrain = ไม่โล่ง
local skyParams = RaycastParams.new()
skyParams.FilterType = Enum.RaycastFilterType.Exclude
skyParams.IgnoreWater = true
local function skyClear(root)
	local skip = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	local from = root.Position + Vector3.new(0, 2.5, 0)
	local left = Config.SKY_CLEAR or 40
	for _ = 1, 8 do
		skyParams.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(from, Vector3.new(0, left, 0), skyParams)
		if not hit then return true end
		local part = hit.Instance
		if part ~= workspace.Terrain and (part.Transparency >= 0.9 or not part.CanCollide) then
			table.insert(skip, part)
			left -= math.max(0, hit.Position.Y - from.Y)
			from = hit.Position
			if left <= 0 then return true end
		else
			return false
		end
	end
	return false
end

-- ============ วาง/เก็บร้าน + จุดลอย + ลานโคม ตามสวิตช์เทศกาล ============
local stall, spot, field, garden, beachLine
local gardens = {} -- [โมเดลลานแขวนโคมในโลก] = true (มีได้หลายลาน: ต้นแบบชื่อขึ้นต้น LanternGarden)
local hung = {} -- [hook Part] = { model, untilT } โคมแขวนของผู้เล่น (ล้างตอนเก็บลาน)

local function shopInfo(player)
	return { counts = KrathongItems.Counts(player), buffUntil = player:GetAttribute("KrathongBuffUntil"), bonus = player:GetAttribute("KrathongEventBonus") }
end

local function makePrompt(parent, name, objectText, actionText)
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ObjectText = objectText
	p.ActionText = actionText
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function build()
	if not stall then
		local t = ServerStorage:FindFirstChild("KrathongTemplates")
		t = t and t:FindFirstChild(Config.STALL_TEMPLATE)
		if t then
			stall = t:Clone()
			stall.Name = "KrathongStall"
			local prompt = makePrompt(stall.PrimaryPart or stall:FindFirstChildWhichIsA("BasePart"), "KrathongShopPrompt", "🌸 ร้านกระทง", "ซื้อกระทง")
			prompt.Triggered:Connect(function(player)
				if not active() then return end
				openRemote:FireClient(player, "shop", shopInfo(player))
			end)
			stall.Parent = workspace
		else
			warn("KrathongService: ไม่เจอ ServerStorage.KrathongTemplates." .. Config.STALL_TEMPLATE)
		end
	end
	-- จุดกด "ลอยกระทง" ปลายท่า PondDock1 (KrathongFloatSpot) เอาออก 2026-11-07 ผู้ใช้สั่ง: ใช้ปุ่มลอยริมน้ำ (actions.floatHere) ได้ทุกที่แทน
	if not field then
		local t = ServerStorage:FindFirstChild("KrathongTemplates")
		t = t and t:FindFirstChild("LanternField")
		if t then
			field = t:Clone()
			field.Name = "KrathongLanternField"
			local p = Instance.new("Part")
			p.Name = "LanternPromptPart"
			p.Size = Vector3.new(2, 2, 2)
			p.Transparency = 1
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			p.CFrame = CFrame.new(Config.LANTERN_FIELD + Vector3.new(0, 3.5, 0))
			p.Parent = field
			local prompt = makePrompt(p, "LanternPrompt", "🏮 ลานปล่อยโคม", "ปล่อยโคมลอย")
			prompt.MaxActivationDistance = 12
			prompt.Triggered:Connect(function(player)
				if not active() or busy[player] then return end
				busy[player] = true
				local ok, res = pcall(releaseLantern, player)
				busy[player] = nil
				if ok and type(res) == "table" then openRemote:FireClient(player, "toast", res.message)
				elseif not ok then warn("KrathongService lantern: " .. tostring(res)) end
			end)
			field.Parent = workspace
		else
			warn("KrathongService: ไม่เจอ ServerStorage.KrathongTemplates.LanternField")
		end
	end
	-- เส้นจุดปล่อยโคมประกอบฉากริมหาด (2026-11-11) ต้นแบบมองเห็นใน Edit → ตอนเล่นล่องหน ผู้เล่นอ่านตำแหน่ง P01..P13 เอง
	if not beachLine then
		local t = ServerStorage:FindFirstChild("KrathongTemplates")
		t = t and t:FindFirstChild("BeachLanternLine")
		if t then
			beachLine = t:Clone()
			beachLine.Name = "KrathongBeachLanternLine"
			for _, p in ipairs(beachLine:GetDescendants()) do
				if p:IsA("BasePart") then p.Transparency = 1 p.CanCollide = false p.CanQuery = false p.CanTouch = false end
			end
			beachLine.Parent = workspace
		end
	end
	-- ลานแขวนโคม (2026-11-07) ทางเหนือของลานปล่อยโคม ฉากล้วน (ไม่มีปุ่ม) วางที่เดิมในต้นแบบ
	if not garden then
		local t = ServerStorage:FindFirstChild("KrathongTemplates")
		for _, tm in ipairs(t and t:GetChildren() or {}) do
			if tm:IsA("Model") and tm.Name:sub(1, 13) == "LanternGarden" then
				local g = tm:Clone()
				g.Name = "KrathongLanternGarden"
				g.Parent = workspace
				gardens[g] = true
				garden = garden or g
			end
		end
	end
end

local function teardown()
	if stall then stall:Destroy() stall = nil end
	if spot then spot:Destroy() spot = nil end
	if field then field:Destroy() field = nil end
	if beachLine then beachLine:Destroy() beachLine = nil end
	for g in pairs(gardens) do g:Destroy() end
	gardens = {}
	garden = nil
	hung = {}
end

task.spawn(function()
	while true do
		local ok, err = pcall(function()
			if active() then build() else teardown() end
		end)
		if not ok then warn("KrathongService: " .. tostring(err)) end
		task.wait(30)
	end
end)

-- ============ รอบปล่อยโคมพร้อมกัน (ทุก MASS_INTERVAL ตรงนาที :00 / :30) ============
-- ใครยืนในลานตอนถึงเวลา = ได้ปล่อยโคมฟรี 1 ดวง (ไม่เสียโคมในกระเป๋า) + บัฟ MASS_BONUS · ทุกคนในเซิร์ฟเห็นโคมขึ้นฟ้า
-- ทดสอบใน Studio: ตั้ง Attribute DevMassLanternNow = true บน ServerScriptService.Krathong.KrathongService = ปล่อยรอบพร้อมกันทันที (ลบเองหลังใช้)
local function massRelease()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local ok, pos = inField(player)
		if ok then
			local untilT, bonus = applyBuff(player, Config.MASS_MINUTES, Config.MASS_BONUS)
			player:SetAttribute("LanternReleased", (player:GetAttribute("LanternReleased") or 0) + 1)
			table.insert(list, { owner = player.DisplayName, pos = pos })
			openRemote:FireClient(player, "toast", buffMsg(player, { "🏮 ปล่อยโคมพร้อมกัน!", "🏮 Group lantern release!" }, untilT, bonus))
		end
	end
	-- ไม่มีใครอยู่ก็ยังปล่อยโคมของลาน 6 ดวง ให้คนที่มองจากที่อื่นเห็นท้องฟ้าสวย
	local extra = math.max(6, 14 - #list)
	for i = 1, extra do
		local a = (i / extra) * math.pi * 2
		local r = 3 + (i % 4) * 4 -- กระจายทั่วลาน (รัศมี 3-15)
		table.insert(list, { pos = Config.LANTERN_FIELD + Vector3.new(math.cos(a) * r, 3, math.sin(a) * r) })
	end
	fxRemote:FireAllClients("lantern", { list = list, t0 = workspace:GetServerTimeNow(), mass = true })
end

task.spawn(function()
	local nextMass = Config.NextMass(os.time())
	while true do
		task.wait(1)
		local ok, err = pcall(function()
			local dev = script:GetAttribute("DevMassLanternNow") == true and game:GetService("RunService"):IsStudio()
			if dev then script:SetAttribute("DevMassLanternNow", nil) end
			if os.time() >= nextMass or dev then
				if not dev then nextMass = Config.NextMass(os.time()) end
				if active() then massRelease() end
			end
		end)
		if not ok then warn("KrathongService mass: " .. tostring(err)) end
	end
end)

-- ============ คำขอจากผู้เล่น ============
local lastFloat = {}

local function filterWish(player, text)
	if type(text) ~= "string" then return nil end
	text = text:gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return nil end
	if utf8.len(text) == nil then return nil end
	if utf8.len(text) > Config.WISH_MAX then
		text = text:sub(1, utf8.offset(text, Config.WISH_MAX + 1) - 1)
	end
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()
	end)
	if not ok or type(result) ~= "string" or result == "" then return nil end
	return result
end

local actions = {}

function actions.info(player)
	return { ok = true, info = shopInfo(player) }
end

function actions.buy(player, id, qty)
	local def = Config.Types[id]
	qty = math.floor(tonumber(qty) or 0)
	if not def or qty < 1 or qty > Config.MAX_BUY then return { ok = false, message = "?" } end
	-- InventoryReady = กระเป๋าโหลดสำเร็จจริง (InventoryLoaded ตั้งแม้โหลดล้ม ซึ่งตอนนั้นกระเป๋าไม่ถูกเซฟ = กระทงที่ซื้อหาย)
	if player:GetAttribute("CoinsLoaded") ~= true or player:GetAttribute("InventoryReady") ~= true then
		return { ok = false, message = msg(player, "ยังโหลดข้อมูลไม่เสร็จ รอสักครู่นะ", "Still loading your data, please wait") }
	end
	local cost = def.Price * qty
	local coins = coinsOf(player)
	if not coins or coins.Value < cost then
		return { ok = false, message = msg(player, "เหรียญไม่พอ ต้องมี " .. Config.Short(cost) .. " 💰", "Not enough coins, you need " .. Config.Short(cost) .. " 💰") }
	end
	player:SetAttribute("CoinSrc", "krathong")
	coins.Value -= cost
	local tool = KrathongItems.Give(player, id, qty, lang(player))
	if not tool then
		coins.Value += cost
		return { ok = false, message = msg(player, "ซื้อไม่สำเร็จ ลองใหม่อีกครั้ง", "Purchase failed, please try again") }
	end
	if saveCoinsNow then saveCoinsNow:Fire(player) end
	if saveInventoryNow then saveInventoryNow:Fire(player) end
	if Config.IsHang(id) then
		return { ok = true, info = shopInfo(player),
			message = msg(player, "🏮 ได้" .. def.NameTh .. " x" .. qty .. " แล้ว ถือไปแขวนที่ตะขอทองว่างในลานแขวนโคมริมหาดได้เลย",
				"🏮 Got " .. def.NameEn .. " x" .. qty .. "! Hold it and hang it on an empty gold hook in the lantern garden on the beach") }
	end
	if Config.IsLantern(id) then
		return { ok = true, info = shopInfo(player),
			message = msg(player, "🏮 ได้" .. def.NameTh .. " x" .. qty .. " แล้ว ถือไว้แล้วกดปุ่มปล่อยโคมได้ทุกที่ที่เหนือหัวโล่ง",
				"🏮 Got " .. def.NameEn .. " x" .. qty .. "! Hold it and press Release anywhere under open sky") }
	end
	return { ok = true, info = shopInfo(player),
		message = msg(player, "🌸 ได้ " .. def.NameTh .. " x" .. qty .. " แล้ว อยู่ในกระเป๋า ถือไว้แล้วไปยืนริมน้ำ กดปุ่มลอยได้เลย",
			"🌸 Got " .. def.NameEn .. " x" .. qty .. "! It's in your bag. Hold it near any water and press Float") }
end

-- ลอยกระทง (ใช้ร่วม: ท่าน้ำ PondDock1 / ปุ่มลอยริมน้ำที่ไหนก็ได้)
--   start = จุดบนผิวน้ำที่กระทงลง (nil = เส้นทางท่าน้ำ Config.PATH) · ส่ง "pray" ให้ทุกคน แล้ว PRAY_SECONDS ค่อยส่ง "float"
local function doFloat(player, id, def, wish, root, start)
	local now = os.clock()
	if lastFloat[player] and now - lastFloat[player] < Config.FLOAT_COOLDOWN then
		return { ok = false, message = msg(player, "รอแป๊บนึงนะ", "Wait a moment") }
	end
	if KrathongItems.Count(player, id) < 1 then
		return { ok = false, message = msg(player, "ไม่มี" .. def.NameTh .. " ซื้อได้ที่ร้านแม่ค้าหัวท่า", "You have no " .. def.NameEn .. ". Buy one at the stall by the dock") }
	end
	lastFloat[player] = now
	local text = filterWish(player, wish) -- รอตัวกรองก่อนเสียของ (กรองล้ม = ลอยได้แต่ไม่มีคำอธิษฐาน)
	if not player.Parent or not KrathongItems.Take(player, id, 1, lang(player)) then
		return { ok = false, message = msg(player, "ลอยไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't float it, please try again") }
	end
	if saveInventoryNow then saveInventoryNow:Fire(player) end
	local untilT, bonus = applyBuff(player, def.BuffMinutes, def.EventBonus)
	player:SetAttribute("KrathongFloated", (player:GetAttribute("KrathongFloated") or 0) + 1)
	-- หันหน้าไปทางจุดที่กระทงจะลงน้ำ (ไม่ขยับตำแหน่ง · นั่งอยู่ = ไม่หมุน กันบั๊กลาก Seat)
	local waterPoint = start or Config.PATH[1]
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if root and hum and not hum.Sit then
		local target = Vector3.new(waterPoint.X, root.Position.Y, waterPoint.Z)
		if (target - root.Position).Magnitude > 0.5 then
			pcall(function() player.Character:PivotTo(CFrame.lookAt(root.Position, target)) end)
		end
	end
	-- ทิศที่กระทงไหล (ปุ่มลอยริมน้ำ): ออกจากตัวผู้เล่นไปทางน้ำ
	local dir
	if start and root then
		local d = (start - root.Position) * Vector3.new(1, 0, 1)
		dir = d.Magnitude > 0.1 and d.Unit or root.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	local t = workspace:GetServerTimeNow()
	fxRemote:FireAllClients("pray", { id = id, ownerId = player.UserId, t0 = t, dur = Config.PRAY_SECONDS, water = start })
	local floatData = {
		id = id,
		owner = player.DisplayName,
		ownerId = player.UserId,
		wish = text,
		seed = math.random(1, 1e6),
		t0 = t + Config.PRAY_SECONDS,
		start = start,
		dir = dir,
	}
	task.delay(Config.PRAY_SECONDS, function()
		fxRemote:FireAllClients("float", floatData)
	end)
	return { ok = true, info = shopInfo(player), message = buffMsg(player, { "🌸 ลอยกระทงแล้ว!", "🌸 Krathong floated!" }, untilT, bonus) }
end

local function krathongDef(player, id)
	local def = Config.Types[id]
	if not def then return nil, { ok = false, message = "?" } end
	if Config.IsHang(id) then
		return nil, { ok = false, message = msg(player, "โคมแขวนเอาไปแขวนที่ลานแขวนโคมริมหาดนะ", "Hang it in the lantern garden on the beach") }
	end
	if Config.IsLantern(id) then
		return nil, { ok = false, message = msg(player, "โคมลอยไม่ได้ลอยน้ำ ถือไว้แล้วกดปุ่มปล่อยโคมที่โล่งนะ", "Sky lanterns go up, not on water. Hold it and press Release under open sky") }
	end
	return def
end

-- ที่ท่าน้ำ (หน้าต่างลอย + คำอธิษฐาน)
function actions.float(player, id, wish)
	local def, err = krathongDef(player, id)
	if not def then return err end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - Config.FLOAT_SPOT).Magnitude > Config.FLOAT_RANGE then
		return { ok = false, message = msg(player, "ไปยืนที่ปลายท่าน้ำก่อนนะ", "Stand at the end of the dock first") }
	end
	return doFloat(player, id, def, wish, root, nil)
end

-- ปุ่มลอยริมน้ำ (2026-11-07 ผู้ใช้สั่ง): ถือกระทงอยู่ใกล้น้ำที่ไหนก็ได้ กดแล้วลอยตรงหน้า ไม่มีคำอธิษฐาน
--   ตรวจ: ถือกระทงชนิดนี้อยู่ในมือจริง / จุดเป็นน้ำ terrain จริง / ห่างตัวไม่เกิน HERE_RANGE แนวราบ
local waterParams = RaycastParams.new()
waterParams.FilterType = Enum.RaycastFilterType.Include
waterParams.FilterDescendantsInstances = { workspace.Terrain }
waterParams.IgnoreWater = false
function actions.floatHere(player, id, point, wish) -- wish = คำอธิษฐาน (ไม่ใส่ก็ได้) ผ่านตัวกรองใน doFloat 2026-11-07
	local def, err = krathongDef(player, id)
	if not def then return err end
	if typeof(point) ~= "Vector3" or point ~= point then return { ok = false, message = "?" } end
	if KrathongItems.HeldId(player) ~= id then
		return { ok = false, message = msg(player, "ถือกระทงไว้ในมือก่อนนะ", "Hold the krathong in your hand first") }
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return { ok = false, message = "?" } end
	local flat = (point - root.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > Config.HERE_RANGE or math.abs(point.Y - root.Position.Y) > 12 then
		return { ok = false, message = msg(player, "เข้าไปใกล้น้ำอีกนิดนะ", "Get a bit closer to the water") }
	end
	local hit = workspace:Raycast(point + Vector3.new(0, 4, 0), Vector3.new(0, -9, 0), waterParams)
	if not hit or hit.Material ~= Enum.Material.Water then
		return { ok = false, message = msg(player, "ตรงนั้นไม่ใช่น้ำนะ", "That spot isn't water") }
	end
	return doFloat(player, id, def, wish, root, Vector3.new(hit.Position.X, hit.Position.Y, hit.Position.Z))
end

-- ============ ปล่อยโคมได้ทุกที่ (2026-11-11 ผู้ใช้สั่ง) ============
-- ถือโคมลอยในมือ + ไม่ว่ายน้ำ + เหนือหัวโล่ง → ปล่อยตรงตำแหน่งตัว (ตำแหน่งจากเซิร์ฟ ไม่รับจากผู้เล่น)
function actions.releaseHere(player)
	if KrathongItems.HeldId(player) ~= "SkyLantern" then
		return { ok = false, message = msg(player, "ถือโคมลอยไว้ในมือก่อนนะ", "Hold the sky lantern in your hand first") }
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return { ok = false, message = "?" } end
	if hum:GetState() == Enum.HumanoidStateType.Swimming then
		return { ok = false, message = msg(player, "ขึ้นจากน้ำก่อนนะ", "Get out of the water first") }
	end
	if not skyClear(root) then
		return { ok = false, message = msg(player, "ออกไปที่โล่งก่อนนะ เหนือหัวมีหลังคาอยู่", "Go somewhere open, there's a roof above you") }
	end
	local res = doRelease(player, root.Position)
	res.info = res.ok and shopInfo(player) or nil
	return res
end

-- ============ แขวนโคม (2026-11-08 ผู้ใช้สั่ง) ============
-- ถือโคมแขวน + ยืนใต้ตะขอว่าง (KrathongLanternGarden.Hooks.<ชื่อ>) → ยกโคมขึ้นแขวน (ทุกคนเห็นท่า "hang") → โคมจริงขึ้นที่ตะขอ อยู่ HANG_LIFE วิ
-- ตะขอที่มีคนแขวน: Attribute Taken = true (ผู้เล่นใช้ซ่อนปุ่ม) · โคมเป็นของเซิร์ฟ อยู่ใน KrathongLanternGarden.Hung
local lastHang = {}
local function freeHook(hook)
	local h = hung[hook]
	hung[hook] = nil
	if h and h.model and h.model.Parent then h.model:Destroy() end
	if hook.Parent then hook:SetAttribute("Taken", nil) hook.Transparency = 0 for _, d in ipairs(hook:GetChildren()) do if d:IsA("BasePart") then d.Transparency = 0 end end end
end
local function makeHung(hook, player, wish, def) -- def = ชนิดโคม (สีตามวัน)
	local src = ReplicatedStorage.KrathongModels:FindFirstChild("HangLanternLamp") -- โคมล้วน (ไม่มีไม้ไผ่) ขนาดเท่าโคมในลาน
	local cf = hook:GetAttribute("HangAt")
	local g = hook.Parent and hook.Parent.Parent
	if not src or typeof(cf) ~= "CFrame" or not g or not gardens[g] then return nil end
	local folder = g:FindFirstChild("Hung")
	if not folder then folder = Instance.new("Folder") folder.Name = "Hung" folder.Parent = g end
	local m = src:Clone()
	m.Name = "Hung_" .. hook.Name
	if def and def.Lamp and m:FindFirstChild("Paper") then m.Paper.UsePartColor = true m.Paper.Color = def.Lamp end
	m:PivotTo(cf)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false end
	end
	m:SetAttribute("OwnerId", player.UserId)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Tag"
	bb.Size = UDim2.new(0, 200, 0, wish and 38 or 20)
	bb.StudsOffsetWorldSpace = Vector3.new(0, -2.6, 0) -- ใต้โคม (โคมอยู่เหนือหัว)
	bb.MaxDistance = 28
	bb.LightInfluence = 0
	local who = Instance.new("TextLabel")
	who.BackgroundTransparency = 1 who.Size = UDim2.new(1, 0, 0, 20) who.Font = Enum.Font.FredokaOne who.TextScaled = true
	who.Text = "🏮 " .. player.DisplayName who.TextColor3 = Color3.new(1, 1, 1)
	local s1 = Instance.new("UIStroke") s1.Color = Color3.fromRGB(170, 60, 50) s1.Thickness = 1.5 s1.Parent = who
	who.Parent = bb
	if wish then
		local w = Instance.new("TextLabel")
		w.BackgroundTransparency = 1 w.Size = UDim2.new(1, 0, 0, 16) w.Position = UDim2.new(0, 0, 0, 21) w.Font = Enum.Font.GothamMedium w.TextScaled = true
		w.Text = "“" .. wish .. "”" w.TextColor3 = Color3.fromRGB(255, 245, 200)
		local cap = Instance.new("UITextSizeConstraint") cap.MaxTextSize = 14 cap.Parent = w
		local s2 = Instance.new("UIStroke") s2.Color = Color3.fromRGB(120, 70, 40) s2.Thickness = 1.2 s2.Parent = w
		w.Parent = bb
	end
	bb.Adornee = m.PrimaryPart
	bb.Parent = m
	m.Parent = folder
	return m
end
function actions.hang(player, id, hook, wish) -- hook = Part ตะขอ (ส่งเป็น Instance)
	local def = Config.Types[id]
	if not def or not Config.IsHang(id) then return { ok = false, message = "?" } end
	if KrathongItems.HeldId(player) ~= id then
		return { ok = false, message = msg(player, "ถือโคมแขวนไว้ในมือก่อนนะ", "Hold the hanging lantern in your hand first") }
	end
	local ok = typeof(hook) == "Instance" and hook:IsA("BasePart") and hook.Parent and hook.Parent.Name == "Hooks" and gardens[hook.Parent.Parent]
	if not ok then return { ok = false, message = msg(player, "ไปที่ลานแขวนโคมริมหาดก่อนนะ", "Go to the lantern garden on the beach first") } end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return { ok = false, message = "?" } end
	local d = hook.Position - root.Position
	if Vector3.new(d.X, 0, d.Z).Magnitude > Config.HANG_RANGE + 1 or math.abs(d.Y) > 25 then
		return { ok = false, message = msg(player, "เข้าไปใกล้ตะขออีกนิดนะ", "Get a bit closer to the hook") }
	end
	if hung[hook] then return { ok = false, message = msg(player, "ตะขอนี้มีคนแขวนแล้ว ลองตะขออื่นนะ", "Someone already hung a lantern here, try another hook") } end
	local now = os.clock()
	if lastHang[player] and now - lastHang[player] < Config.HANG_COOLDOWN then
		return { ok = false, message = msg(player, "รอแป๊บนึงนะ", "Wait a moment") }
	end
	if KrathongItems.Count(player, id) < 1 then
		return { ok = false, message = msg(player, "ไม่มีโคมแขวน ซื้อได้ที่ร้านแม่ค้ากระทง", "No hanging lantern. Buy one at the krathong stall") }
	end
	lastHang[player] = now
	hung[hook] = { reserved = true } -- จองก่อนรอตัวกรอง กันสองคนแย่งตะขอเดียว
	hook:SetAttribute("Taken", true)
	local text = filterWish(player, wish)
	if not player.Parent or not KrathongItems.Take(player, id, 1, lang(player)) then
		freeHook(hook)
		return { ok = false, message = msg(player, "แขวนไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't hang it, please try again") }
	end
	if saveInventoryNow then saveInventoryNow:Fire(player) end
	-- 2026-11-11: โคมแขวน = โชคหลัก +30% (LuckConfig.LANTERN_LUCK_MULT) ต่อเวลาได้ ไม่เกิน BUFF_MAX_MINUTES · เวลาเซิร์ฟเวอร์ GetServerTimeNow แบบ HugLuckUntil
	local tNow = workspace:GetServerTimeNow()
	local luckUntil = tonumber(player:GetAttribute("LanternLuckUntil")) or 0
	luckUntil = math.min(math.max(luckUntil, tNow) + (def.BuffMinutes or 10) * 60, tNow + Config.BUFF_MAX_MINUTES * 60)
	player:SetAttribute("LanternLuckUntil", luckUntil)
	local luckPct = math.floor(((def.LuckMult or 1.3) - 1) * 100 + 0.5)
	local luckMins = math.max(1, math.floor((luckUntil - tNow) / 60 + 0.5))
	player:SetAttribute("LanternHung", (player:GetAttribute("LanternHung") or 0) + 1)
	-- หันหน้าเข้าหาตะขอ
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if hum and not hum.Sit then
		local target = Vector3.new(hook.Position.X, root.Position.Y, hook.Position.Z)
		if (target - root.Position).Magnitude > 0.5 then pcall(function() player.Character:PivotTo(CFrame.lookAt(root.Position, target)) end) end
	end
	local t = workspace:GetServerTimeNow()
	fxRemote:FireAllClients("hang", { id = id, ownerId = player.UserId, t0 = t, dur = Config.HANG_POSE, at = hook:GetAttribute("HangAt") })
	task.delay(Config.HANG_POSE, function()
		if not hook.Parent or not gardens[hook.Parent.Parent] then return end
		local m = makeHung(hook, player, text, def)
		local untilHang = os.time() + Config.HANG_LIFE
		hung[hook] = { model = m, untilT = untilHang }
		-- ซ่อนตะขอทองใต้โคม
		hook.Transparency = 1 for _, x in ipairs(hook:GetChildren()) do if x:IsA("BasePart") then x.Transparency = 1 end end
	end)
	return { ok = true, info = shopInfo(player), message = msg(player, "🏮 แขวนโคมแล้ว! โชค +" .. luckPct .. "% อีก " .. luckMins .. " นาที", "🏮 Lantern hung! Luck +" .. luckPct .. "% for " .. luckMins .. " min") }
end

-- โคมแขวนหมดเวลา = จางหายแล้วคืนตะขอ
task.spawn(function()
	while true do
		task.wait(5)
		local t = os.time()
		for hook, h in pairs(hung) do
			if h.untilT and t >= h.untilT then
				hung[hook] = nil
				local m = h.model
				if m and m.Parent then
					for _, p in ipairs(m:GetDescendants()) do
						if p:IsA("BasePart") then game:GetService("TweenService"):Create(p, TweenInfo.new(3), { Transparency = 1 }):Play() end
					end
					task.delay(3.2, function()
						if m.Parent then m:Destroy() end
						if not hung[hook] and hook.Parent then freeHook(hook) end
					end)
				elseif hook.Parent then
					freeHook(hook)
				end
			end
		end
	end
end)

requestRemote.OnServerInvoke = function(player, action, a, b, c)
	if type(action) ~= "string" or not actions[action] then return { ok = false, message = "?" } end
	if action ~= "info" and not active() then
		return { ok = false, message = msg(player, "กิจกรรมลอยกระทงยังไม่เปิด", "The Loy Krathong activity isn't open") }
	end
	if busy[player] then return { ok = false, message = msg(player, "รอแป๊บนึงนะ", "Wait a moment") } end
	busy[player] = true
	local ok, res = pcall(actions[action], player, a, b, c)
	busy[player] = nil
	if not ok then
		warn("KrathongService " .. action .. ": " .. tostring(res))
		return { ok = false, message = msg(player, "มีบางอย่างผิดพลาด ลองใหม่อีกครั้ง", "Something went wrong, please try again") }
	end
	return res
end

Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
	lastFloat[player] = nil
	lastLantern[player] = nil
	lastHang[player] = nil
end)
