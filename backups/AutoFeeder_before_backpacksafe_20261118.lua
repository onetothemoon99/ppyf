-- BACKUP 2026-11-18 of game.ServerScriptService.AutoFeeder before fix: safe Backpack lookup / no item loss when Backpack missing
-- Restore: paste everything below this header into ServerScriptService.AutoFeeder Source
-- AutoFeeder: ชามอาหารอัตโนมัติ (Game Pass ดู ReplicatedStorage.AutoFeederConfig)
-- DataStore "AutoFeeder_v1": { food = { [ดาว] = ถุง }, enabled, threshold, order ("low" = ดาวต่ำก่อน / "high"), off = { [petId] = true }, autoFill }
-- autoFill (ค่าเริ่มต้นเปิด): อาหารที่เครื่องทำอาหารสัตว์ทำเสร็จ ไหลเข้าชามเอง (PetFoodConverter เรียกผ่าน BindableFunction "AutoFeederBridge")
-- สัตว์ที่พาออกมา (ตัวในฉากที่ OwnerUserId = ผู้เล่น) หิวต่ำกว่าที่ตั้ง -> กินจากชามทีละถุง (อิ่มเท่าป้อนอาหารสัตว์เอง PetHunger.PET_FOOD_BY_STAR)
-- เติม/นำออก: เซฟก่อนแล้วค่อยเปลี่ยนของในกระเป๋า เซฟไม่ได้ = ย้อนกลับ (ของไม่หาย ไม่เบิ้ล)
-- ความเป็นเจ้าของ: เช็กตอนเข้าเกม + ตอนซื้อสำเร็จในเกม (ไม่ต้องออกเข้าใหม่) ตั้ง Attribute "HasAutoFeeder"

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("AutoFeederConfig"))
local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local PetHunger = require(ServerScriptService:WaitForChild("PetSystem"):WaitForChild("PetHunger"))
local PetDefinitions = require(ServerScriptService.PetSystem:WaitForChild("PetDefinitions"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local request = remoteEvents:FindFirstChild("AutoFeederRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "AutoFeederRequest"
	request.Parent = remoteEvents
end

local store = DataStoreService:GetDataStore("AutoFeeder_v1")
local SAVE_EVERY = 60
local SAVE_MIN_INTERVAL = 15 -- per-key DataStore write cooldown
local FEED_SOUND_ID = "rbxassetid://137096768206416" -- เสียงเคี้ยวเดียวกับตอนป้อนเอง (PetManager)

local states = {} -- [player] = { data, loaded, owned, dirty, lastSave, warnedLow, warnedEmpty }
local giftSelect -- นิยามด้านล่าง (ส่วนของขวัญ)
local lastFed = {} -- [petModel] = os.clock()

local function notify(player, text)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.food = type(d.food) == "table" and d.food or {}
	for star = 1, 5 do d.food[star] = math.max(0, math.floor(tonumber(d.food[star]) or 0)) end
	d.enabled = d.enabled ~= false
	d.threshold = table.find(Config.THRESHOLDS, d.threshold) and d.threshold or Config.DEFAULT_THRESHOLD
	d.order = (d.order == "high") and "high" or "low"
	d.off = type(d.off) == "table" and d.off or {}
	d.autoFill = d.autoFill ~= false
	return d
end

local function total(d)
	local n = 0
	for star = 1, 5 do n += d.food[star] end
	return n
end

local function copy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end
	return c
end

local function publish(player, st)
	if not player.Parent then return end
	player:SetAttribute("HasAutoFeeder", st.owned == true)
	if st.loaded then
		player:SetAttribute("AutoFeederFood", total(st.data))
		player:SetAttribute("AutoFeederOn", st.data.enabled)
	end
end

local function save(player, st, force)
	if st.saving then return false end
	st.saving = true
	local now = os.clock()
	local remaining = SAVE_MIN_INTERVAL - (now - (st.lastSave or 0))
	if st.lastSave and st.lastSave > 0 and remaining > 0 then
		if not force then
			task.wait(remaining)
		else
			task.wait(remaining)
		end
	end

	local snapshot = copy(st.data)
	local ok, err = false, nil
	for attempt = 1, 3 do
		st.lastSave = os.clock()
		ok, err = pcall(function()
			store:SetAsync(tostring(player.UserId), snapshot)
		end)
		if ok then break end

		local message = tostring(err)
		local throttled = string.find(message, "KeyThrottled", 1, true)
			or string.find(message, "request rate exceeds", 1, true)
		if not throttled or attempt == 3 then break end
		task.wait(5 * attempt)
	end

	st.saving = false
	if ok then
		st.dirty = false
	else
		st.dirty = true
		warn("AutoFeeder: เซฟไม่สำเร็จสำหรับ " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end
local function activePets(player)
	local list = {}
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("OwnerUserId") == player.UserId and m:GetAttribute("PetId") then
			table.insert(list, m)
		end
	end
	return list
end

-- ============ กินจากชาม ============
local function feedEffect(pet, gain)
	local root = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart", true)
	if not root then return end
	local cf, size = pet:GetBoundingBox()
	local look = pet:GetPivot().LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
	local groundY = cf.Position.Y - size.Y / 2
	-- ชามใบเล็กโผล่ข้างหน้าสัตว์แป๊บหนึ่ง
	local bowl = Instance.new("Part")
	bowl.Name = "AutoFeederBowl"
	bowl.Shape = Enum.PartType.Cylinder
	bowl.Size = Vector3.new(0.35, 1.1, 1.1)
	bowl.Color = Color3.fromRGB(255, 170, 200)
	bowl.Material = Enum.Material.SmoothPlastic
	bowl.Anchored = true
	bowl.CanCollide = false
	bowl.CanQuery = false
	bowl.CanTouch = false
	bowl.CFrame = CFrame.new(cf.Position * Vector3.new(1, 0, 1) + Vector3.new(0, groundY + 0.18, 0) + look.Unit * (size.Z / 2 + 0.4)) * CFrame.Angles(0, 0, math.rad(90))
	local kibble = Instance.new("Part")
	kibble.Name = "Kibble"
	kibble.Shape = Enum.PartType.Cylinder
	kibble.Size = Vector3.new(0.12, 0.9, 0.9)
	kibble.Color = Color3.fromRGB(190, 120, 60)
	kibble.Material = Enum.Material.Pebble
	kibble.Anchored = true
	kibble.CanCollide = false
	kibble.CanQuery = false
	kibble.CanTouch = false
	kibble.CFrame = bowl.CFrame * CFrame.new(0.14, 0, 0)
	kibble.Parent = bowl
	bowl.Parent = workspace
	Debris:AddItem(bowl, 1.6)

	local sound = Instance.new("Sound")
	sound.SoundId = FEED_SOUND_ID
	sound.Volume = 0.7
	sound.PlaybackSpeed = 0.95 + math.random() * 0.2
	sound.RollOffMaxDistance = 60
	sound.SoundGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds")
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, 4)

	-- "+30% 🍖" ลอยขึ้นเหนือหัว
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 90, 0, 24)
	bb.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 0.6, 0)
	bb.Adornee = root
	bb.AlwaysOnTop = true
	bb.MaxDistance = 50
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = Color3.fromRGB(120, 230, 110)
	t.Text = "+" .. gain .. "% 🍖"
	t.Parent = bb
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(40, 60, 30); stroke.Parent = t
	bb.Parent = root
	Debris:AddItem(bb, 1.4)
end

local function pickStar(d)
	if d.order == "high" then
		for star = 5, 1, -1 do if d.food[star] > 0 then return star end end
	else
		for star = 1, 5 do if d.food[star] > 0 then return star end end
	end
	return nil
end

local function tick(player, st)
	local d = st.data
	if not (st.owned and d.enabled) or total(d) <= 0 then return end
	for _, pet in ipairs(activePets(player)) do
		local petId = pet:GetAttribute("PetId")
		if not d.off[petId] and (os.clock() - (lastFed[pet] or 0)) >= Config.FEED_COOLDOWN then
			local hunger = PetHunger.Get(player, petId)
			if hunger < d.threshold then
				local star = pickStar(d)
				if not star then break end
				local gain = PetHunger.PET_FOOD_BY_STAR[star] or PetHunger.PET_FOOD_BY_STAR[1]
				local before = hunger
				local after = PetHunger.Change(player, petId, gain)
				if PetHunger.GetMaxLives(petId) > 0 then PetHunger.RestoreLives(player, petId) end
				d.food[star] -= 1
				st.dirty = true
				lastFed[pet] = os.clock()
				feedEffect(pet, math.floor(after - before + 0.5))
				publish(player, st)
				local left = total(d)
				if left == 0 and not st.warnedEmpty then
					st.warnedEmpty = true
					notify(player, "🥣 อาหารในชามอัตโนมัติหมดแล้ว! เติมอาหารสัตว์ได้ที่ปุ่ม 🥣 ด้านขวาของจอ")
				elseif left <= Config.LOW_WARNING and left > 0 and not st.warnedLow then
					st.warnedLow = true
					notify(player, string.format("🥣 อาหารในชามเหลือ %d ถุง ใกล้หมดแล้ว", left))
				end
			end
		end
	end
end

-- ============ หน้าต่างชาม ============
local function petFoodTools(player)
	local list = {}
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if loc then
			for _, tool in ipairs(loc:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("IsPetFood") then table.insert(list, tool) end
			end
		end
	end
	return list
end

local function infoFor(player, st)
	local inBag = { 0, 0, 0, 0, 0 }
	for _, tool in ipairs(petFoodTools(player)) do
		local star = math.clamp(tool:GetAttribute("Star") or 1, 1, 5)
		inBag[star] += tool:GetAttribute("Count") or 1
	end
	local pets = {}
	for _, pet in ipairs(activePets(player)) do
		local petId = pet:GetAttribute("PetId")
		table.insert(pets, { Id = petId, DisplayName = pet:GetAttribute("PetDisplayName") or petId, Off = st.loaded and st.data.off[petId] == true })
	end
	local d = st.loaded and st.data or normalize(nil)
	return {
		Owned = st.owned == true, Loaded = st.loaded, PassId = Config.GAMEPASS_ID,
		Food = copy(d.food), Total = total(d), Capacity = Config.CAPACITY, Unlimited = Config.UNLIMITED_CAPACITY == true, InBag = inBag,
		Enabled = d.enabled, Threshold = d.threshold, Thresholds = Config.THRESHOLDS, Order = d.order, Pets = pets, AutoFill = d.autoFill,
	}
end

local function deposit(player, st)
	local d = st.data
	local space = Config.UNLIMITED_CAPACITY and math.huge or (Config.CAPACITY - total(d))
	if not Config.UNLIMITED_CAPACITY and space <= 0 then return { ok = false, message = "ชามเต็มแล้ว (" .. Config.CAPACITY .. " ถุง)" } end
	-- ดาวต่ำเติมก่อน (ดาวสูงเก็บไว้ป้อนเองได้)
	local tools = petFoodTools(player)
	table.sort(tools, function(a, b) return (a:GetAttribute("Star") or 1) < (b:GetAttribute("Star") or 1) end)
	local plan, moved = {}, 0
	for _, tool in ipairs(tools) do
		if space <= 0 then break end
		local have = tool:GetAttribute("Count") or 1
		local take = math.min(have, space)
		table.insert(plan, { tool = tool, take = take, have = have, star = math.clamp(tool:GetAttribute("Star") or 1, 1, 5) })
		space -= take
		moved += take
	end
	if moved == 0 then return { ok = false, message = "ไม่มีอาหารสัตว์ในกระเป๋า ทำได้ที่เครื่องทำอาหารสัตว์" } end
	local before = copy(d.food)
	for _, p in ipairs(plan) do d.food[p.star] += p.take end
	if not save(player, st) then
		d.food = before
		return { ok = false, message = "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง" }
	end
	local lang = Localization.GetLanguage(player)
	for _, p in ipairs(plan) do
		local left = p.have - p.take
		if left <= 0 then
			p.tool:Destroy()
		else
			p.tool:SetAttribute("Count", left)
			p.tool.Name = ItemFactory.GetPetFoodName(p.star, left, lang)
		end
	end
	st.warnedLow, st.warnedEmpty = false, false
	publish(player, st)
	return { ok = true, message = string.format("🥣 เติมอาหารลงชามแล้ว %d ถุง", moved) }
end

local function withdraw(player, st)
	local d = st.data
	local n = total(d)
	if n <= 0 then return { ok = false, message = "ชามว่างอยู่" } end
	local food = copy(d.food)
	for star = 1, 5 do d.food[star] = 0 end
	if not save(player, st) then
		d.food = food
		return { ok = false, message = "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง" }
	end
	for star = 1, 5 do
		if food[star] > 0 then ItemFactory.GivePetFood(player, star, food[star]) end
	end
	publish(player, st)
	return { ok = true, message = string.format("นำอาหารออกจากชามแล้ว %d ถุง", n) }
end

local function setting(player, st, key, value)
	local d = st.data
	if key == "enabled" then
		d.enabled = value == true
	elseif key == "threshold" then
		if not table.find(Config.THRESHOLDS, value) then return { ok = false, message = "ค่าไม่ถูกต้อง" } end
		d.threshold = value
	elseif key == "order" then
		d.order = (value == "high") and "high" or "low"
	elseif key == "autoFill" then
		d.autoFill = value == true
	elseif key == "pet" then
		if type(value) ~= "string" or not PetDefinitions[value] then return { ok = false, message = "ไม่รู้จักสัตว์ตัวนี้" } end
		d.off[value] = (not d.off[value]) or nil
	else
		return { ok = false, message = "คำขอไม่ถูกต้อง" }
	end
	st.dirty = true
	publish(player, st)
	return { ok = true }
end

local busy = {}
request.OnServerInvoke = function(player, action, a, b)
	local st = states[player]
	if not st then return { ok = false, message = "ยังโหลดไม่เสร็จ" } end
	if busy[player] then return { ok = false, message = "กำลังทำรายการก่อนหน้าอยู่" } end
	busy[player] = true
	local ok, result = pcall(function()
		if action == "info" then return { ok = true } end
		if action == "giftSelect" then return giftSelect(player, a) end -- ส่งชามให้เพื่อน (ไม่ต้องมีชามเองก็ส่งได้)
		if not st.loaded then return { ok = false, message = "ยังโหลดข้อมูลชามไม่เสร็จ ลองใหม่อีกครั้ง" } end
		if not st.owned then return { ok = false, message = "ต้องมีชามอาหารอัตโนมัติก่อน (Game Pass)" } end
		if action == "deposit" then return deposit(player, st) end
		if action == "withdraw" then return withdraw(player, st) end
		if action == "setting" then return setting(player, st, a, b) end
		return { ok = false, message = "คำขอไม่ถูกต้อง" }
	end)
	busy[player] = nil
	if not ok then
		warn("AutoFeeder: คำขอ " .. tostring(action) .. " ของ " .. player.Name .. " ผิดพลาด: " .. tostring(result))
		result = { ok = false, message = "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง" }
	end
	result.info = infoFor(player, st)
	return result
end

-- ============ รับอาหารจากเครื่องทำอาหารสัตว์ (PetFoodConverter) ============
-- "space"(player) -> รับได้อีกกี่ถุง (ไม่มีชาม/ยังไม่โหลด/ปิด autoFill = 0)
-- "add"(player, { [ดาว] = ถุง }) -> true ใส่ชามแล้ว (เซฟทันที เซฟไม่ได้ก็ค้าง dirty ไว้เซฟรอบถัดไป)
local bridge = ServerScriptService:FindFirstChild("AutoFeederBridge") or Instance.new("BindableFunction")
bridge.Name = "AutoFeederBridge"
bridge.Parent = ServerScriptService
bridge.OnInvoke = function(action, player, bags)
	local st = states[player]
	if not (st and st.loaded and st.owned and st.data.autoFill) then return action == "space" and 0 or false end
	local d = st.data
	if action == "space" then
		-- ในชามมีถึงเพดานเติมออโต้แล้ว: ให้อาหารที่ทำเสร็จรอรับที่เครื่อง (กลับต่ำกว่าเพดานเมื่อสัตว์กินไป ก็ไหลเข้าชามต่อเอง)
		if total(d) >= Config.AUTO_FILL_BELOW then return 0 end
		if Config.UNLIMITED_CAPACITY then return math.huge end
		return math.max(0, Config.CAPACITY - total(d))
	elseif action == "add" and type(bags) == "table" then
		-- bags = { ถุงดาว1, ..., ถุงดาว5 } ครบ 5 ช่อง (ไม่ครบ = ข้อมูลเสีย ไม่รับ ให้เครื่องเก็บไว้ตามเดิม)
		if #bags ~= 5 then return false end
		local added = 0
		for star = 1, 5 do
			local n = math.max(0, math.floor(tonumber(bags[star]) or 0))
			d.food[star] += n
			added += n
		end
		if added <= 0 then return false end
		st.dirty = true
		st.warnedLow, st.warnedEmpty = false, false
		task.spawn(save, player, st, true)
		publish(player, st)
		return true
	end
	return false
end

-- ============ ความเป็นเจ้าของ Game Pass ============
local function checkOwnership(player, st)
	for attempt = 1, 3 do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GAMEPASS_ID)
		end)
		if ok then
			st.owned = owns or st.owned -- ได้ชามเป็นของขวัญแล้ว (checkGift) ห้ามโดนเขียนทับเป็น false
			publish(player, st)
			return
		end
		warn("AutoFeeder: เช็ก Game Pass ไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(owns))
		task.wait(3)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if passId ~= Config.GAMEPASS_ID or not purchased then return end
	local st = states[player]
	if not st then return end
	st.owned = true
	publish(player, st)
	notify(player, "🥣 ขอบคุณที่ซื้อชามอาหารอัตโนมัติ! เติมอาหารสัตว์ได้ที่ปุ่ม 🥣 ด้านขวาของจอ")
	print("🥣 AutoFeeder: " .. player.Name .. " ซื้อ Game Pass แล้ว")
end)

-- ============ ของขวัญชามอาหารอัตโนมัติ (Developer Product: AutoFeederConfig.GIFT_PRODUCT_ID) ============
-- Game Pass ซื้อให้คนอื่นไม่ได้ จึงขายเป็น Developer Product: ผู้ซื้อเลือกเพื่อนในเซิร์ฟเวอร์ -> จ่าย Robux -> เพื่อนได้ชามถาวร
-- (แบบเดียวกับของขวัญ VIP / สุลต่าน / ช่องสัตว์ +1) DataStore "AutoFeederGift_v1": "to_<userId>" = { from, fromName, t, receipt, seen } / "pending_<userId>" = { to, toName, t }
local PurchaseRouter = require(ServerScriptService:WaitForChild("PurchaseRouter"))
local giftStore = DataStoreService:GetDataStore("AutoFeederGift_v1")
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
		warn("AutoFeeder: ใบเสร็จของขวัญชามของ " .. buyer.Name .. " ไม่มีผู้รับที่เลือกไว้ (ยังไม่ยืนยัน)")
		return false
	end
	local target = Players:GetPlayerByUserId(pending.to)
	local record = {
		from = buyer.UserId, fromName = buyer.DisplayName, t = os.time(),
		receipt = tostring(receiptInfo.PurchaseId), seen = target ~= nil,
	}
	local okSave, err = pcall(function() giftStore:SetAsync("to_" .. pending.to, record, { pending.to }) end)
	if not okSave then
		warn("AutoFeeder: บันทึกของขวัญชามไม่สำเร็จ " .. buyer.Name .. " -> " .. tostring(pending.to) .. ": " .. tostring(err))
		return false
	end
	giftPending[buyer] = nil
	giftPrompting[buyer] = nil
	pcall(function() giftStore:RemoveAsync("pending_" .. buyer.UserId) end)
	local toName = pending.toName or tostring(pending.to)
	if target then
		local tst = states[target]
		if tst then
			tst.owned = true
			tst.gift = record
			publish(target, tst)
		end
		notify(target, "🥣 " .. buyer.DisplayName .. " ส่งชามอาหารอัตโนมัติให้คุณเป็นของขวัญ! เติมอาหารสัตว์ได้ที่ชามในเมนูสัตว์เลี้ยง 🐾")
	end
	notify(buyer, "🥣 ส่งชามอาหารอัตโนมัติให้ " .. toName .. " เรียบร้อยแล้ว ขอบคุณที่แบ่งปัน 💖")
	print("🎁 AutoFeeder: " .. buyer.Name .. " ส่งชามอาหารอัตโนมัติให้ " .. toName .. " (" .. pending.to .. ")")
	return true
end
PurchaseRouter.Register(Config.GIFT_PRODUCT_ID or 0, { name = "ของขวัญชามอาหารอัตโนมัติ", grant = grantGift })

-- ผู้ซื้อเลือกผู้รับ (ต้องอยู่ในเซิร์ฟเวอร์เดียวกันและยังไม่มีชาม) แล้วเซิร์ฟเวอร์เปิดหน้าจ่ายเงินให้
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
		if not tst or target:GetAttribute("HasAutoFeeder") == nil then
			return { ok = false, message = "ข้อมูลของเพื่อนยังโหลดไม่เสร็จ ลองใหม่อีกครั้ง" }
		end
		if tst.owned or target:GetAttribute("HasAutoFeeder") == true then
			return { ok = false, message = target.DisplayName .. " มีชามอาหารอัตโนมัติอยู่แล้ว" }
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
		warn("AutoFeeder: จำผู้รับของขวัญไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" }
	end
	giftPending[player] = pending
	if studioTest then
		task.spawn(function()
			local okGrant, res = pcall(grantGift, player, { PurchaseId = "studio_" .. os.time(), PlayerId = player.UserId })
			if not (okGrant and res == true) then warn("AutoFeeder: จำลองของขวัญไม่สำเร็จ: " .. tostring(res)) end
		end)
		return { ok = true, message = "(Studio) จำลองการซื้อของขวัญให้ " .. toName }
	end
	giftPrompting[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return { ok = true, message = "เปิดหน้าชำระเงินแล้ว: ชามอาหารอัตโนมัติสำหรับ " .. toName }
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

-- เข้าเกม: มีบันทึกของขวัญ = มีชาม (ครั้งแรกหลังได้รับตอนออฟไลน์ แจ้งผู้ได้รับหนึ่งครั้ง)
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local function checkGift(player, st)
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = คนที่ได้ชามเป็นของขวัญไม่มีชามรอบนั้น) 2026-10-09
	repeat
		local ok, rec = DataLoadRetry.Load(player, "AutoFeeder(gift)", DataLoadRetry.Get(giftStore, "to_" .. player.UserId), function() return states[player] == st end)
		if ok then
			if type(rec) == "table" then
				st.owned = true
				st.gift = rec
				if rec.seen ~= true then
					rec.seen = true
					task.delay(8, notify, player, "🥣 คุณได้รับชามอาหารอัตโนมัติเป็นของขวัญจาก " .. tostring(rec.fromName or "เพื่อน") .. "! เติมอาหารสัตว์ได้ที่ชามในเมนูสัตว์เลี้ยง 🐾")
					task.spawn(function()
						pcall(function()
							giftStore:UpdateAsync("to_" .. player.UserId, function(old)
								if type(old) ~= "table" then return nil end
								old.seen = true
								return old
							end)
						end)
					end)
				end
			end
			return
		end
	until true
end

local function onPlayerAdded(player)
	local st = { data = nil, loaded = false, owned = false, dirty = false, lastSave = os.clock() }
	states[player] = st
	player:GetAttributeChangedSignal("PromoAutoFeederGranted"):Connect(function()
		if player:GetAttribute("PromoAutoFeederGranted") == true then
			st.owned = true
			publish(player, st)
			notify(player, "🥣 แลกโค้ดสำเร็จ! ได้รับชามอาหารอัตโนมัติถาวรแล้ว")
		end
	end)
	if player:GetAttribute("PromoAutoFeederGranted") == true then st.owned = true end
	-- ของขวัญก่อน แล้วค่อยเช็ก Game Pass (กันค่า HasAutoFeeder เป็น false แวบหนึ่งทั้งที่ได้ของขวัญ)
	task.spawn(function()
		checkGift(player, st)
		checkOwnership(player, st)
	end)
	-- ทดสอบใน Studio: ตั้ง Attribute "DevFailAutoFeederLoad" = จำนวนครั้งที่ให้ GetAsync ล้มเหลว บน workspace (ลดลงเองทีละครั้ง)
	local function loadOnce()
		local forced = RunService:IsStudio() and (tonumber(workspace:GetAttribute("DevFailAutoFeederLoad")) or 0) or 0
		if forced > 0 then
			workspace:SetAttribute("DevFailAutoFeederLoad", forced - 1)
			return false, "จำลองโหลดไม่สำเร็จ (DevFailAutoFeederLoad)"
		end
		DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
		return pcall(function() return store:GetAsync(tostring(player.UserId)) end)
	end
	DataLoadRetry.WaitLeaveSaves(player) -- หลุดแล้วเข้าเซิร์ฟเดิมทันที = รอเซฟชามรอบก่อนเสร็จก่อนอ่าน (2026-10-10)
	for attempt = 1, 3 do
		local ok, data = loadOnce()
		if ok then
			st.data = normalize(data)
			st.loaded = true
			break
		end
		warn("AutoFeeder: โหลดไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(data))
		task.wait(3)
	end
	publish(player, st)
	-- โหลดไม่ได้ 3 ครั้ง (มักเป็น DataStore throttle ตอนคนเข้าพร้อมกัน เช่น หลังรีเซิร์ฟ) ลองต่อเบื้องหลังจนได้ (2026-10-09)
	-- เดิมเลิกโหลดทั้งรอบ ชามขึ้น 0 จนกว่าจะออกเข้าใหม่ · ระหว่างรอไม่เซฟ (ของเดิมไม่หาย) หน้าจอขึ้น "กำลังโหลด" เพราะ AutoFeederFood ยังไม่ถูกตั้ง
	if not st.loaded then
		task.spawn(function()
			local delay = 10
			while player.Parent and states[player] == st and not st.loaded do
				task.wait(delay)
				if not (player.Parent and states[player] == st) then break end
				local ok, data = loadOnce()
				if ok then
					st.data = normalize(data)
					st.loaded = true
					publish(player, st)
					print("AutoFeeder: โหลดข้อมูลชามของ " .. player.Name .. " ได้แล้ว (ลองใหม่)")
				else
					warn("AutoFeeder: ยังโหลดชามไม่ได้ " .. player.Name .. ": " .. tostring(data))
					delay = math.min(delay + 10, 60)
				end
			end
		end)
	end
	-- ทดสอบใน Studio: ตั้ง Attribute "DevGrantAutoFeeder" = true บนตัวผู้เล่นจากฝั่งเซิร์ฟเวอร์ = ให้ชามชั่วคราว (ใช้ได้เฉพาะใน Studio)
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevGrantAutoFeeder"):Connect(function()
			st.owned = player:GetAttribute("DevGrantAutoFeeder") == true or st.owned
			publish(player, st)
		end)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	states[player] = nil
	giftPending[player] = nil
	giftPrompting[player] = nil
	busy[player] = nil
	if st and st.loaded and st.dirty then
		DataLoadRetry.BeginLeaveSave(player.UserId)
		pcall(save, player, st, true)
		DataLoadRetry.EndLeaveSave(player.UserId)
	end
end)

game:BindToClose(function()
	for player, st in pairs(states) do
		if st.loaded and st.dirty then task.spawn(save, player, st, true) end
	end
	task.wait(29)
end)

while true do
	task.wait(1)
	for player, st in pairs(states) do
		if st.loaded and player.Parent then
			local ok, err = pcall(tick, player, st)
			if not ok then warn("AutoFeeder: ป้อนอัตโนมัติผิดพลาด " .. player.Name .. ": " .. tostring(err)) end
			if st.dirty and os.clock() - st.lastSave >= SAVE_EVERY then task.spawn(save, player, st, true) end
		end
	end
	for pet in pairs(lastFed) do
		if not pet.Parent then lastFed[pet] = nil end
	end
end
