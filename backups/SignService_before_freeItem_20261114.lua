-- BACKUP 2026-11-14 before free reusable sign item (no shop)
-- Studio path: game.ServerScriptService.Sign.SignService (Script)
-- Restore: paste everything below this header into that script's Source in Studio

-- SignService (2026-11-14): ป้ายเขียนข้อความ ฝั่งเซิร์ฟเวอร์ (คู่กับ StarterPlayerScripts.SignClient) · ค่าต่างๆ ReplicatedStorage.SignConfig · แผน SIGNS.md
--   ร้านป้าย = SignModels.SignShop โคลนไปที่ Config.SHOP_POS ตอนเกมรัน (workspace.SignShop) กด E ค้าง = ซื้อป้ายเปล่า 1 อัน
--   RemoteFunction RemoteEvents.SignRequest(action, ...) : "write" (ข้อความ) / "plant" (จุดบนพื้น) · ต้องถือป้ายอยู่
--   RemoteEvent RemoteEvents.SignNotice(ข้อความ) = แจ้งผลที่ไม่ได้มาจากปุ่ม (ซื้อ / เก็บ / หมดเวลา)
--   ป้ายที่ปัก = workspace.PlayerSigns.<Model> Anchored ไม่ชนใคร Attribute OwnerUserId/OwnerName/SignText · ปุ่ม E เก็บป้าย (คนอื่นไม่เห็นปุ่ม SignClient ซ่อน)
--   หายเอง: ครบ Config.LIFETIME = กลับเข้ากระเป๋า · เจ้าของออกเกม = ลบจากแมพ (InventorySystem เซฟป้ายนั้นเข้ากระเป๋าให้แล้วผ่าน SignItems.PlacedEntries)
--   คำสั่งแชทเจ้าของเกม: /clearsigns [ชื่อ] = ถอนป้ายที่ปัก (ทุกคน / เฉพาะคนนั้น) คืนเจ้าของเป็นป้ายเปล่า (ลบข้อความ)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage:WaitForChild("SignConfig"))
if not Config.ENABLED then return end -- DEV_ONLY: เซิร์ฟจริงไม่มีระบบป้าย (ป้ายในกระเป๋ายังเซฟผ่าน InventorySystem)

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local SignItems = require(script.Parent:WaitForChild("SignItems"))
local models = ReplicatedStorage:WaitForChild("SignModels")

local saveCoinsNow = ServerScriptService:WaitForChild("LeaderstatsSetup"):WaitForChild("SaveCoinsNow", 30)
local saveInventoryNow = ServerScriptService:WaitForChild("InventorySystem"):WaitForChild("SaveInventoryNow", 30)

local ADMINS = { [9360333174] = true } -- เจ้าของเกม (One_moretime91) ชุดเดียวกับคำสั่งอื่น

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
local requestRemote = remote("RemoteFunction", "SignRequest")
local noticeRemote = remote("RemoteEvent", "SignNotice")

local function lang(player)
	local ok, l = pcall(Localization.GetLanguage, player)
	return (ok and l == "en") and "en" or "th"
end
local function msg(player, th, en)
	return lang(player) == "en" and en or th
end
local function notify(player, text)
	if player and player.Parent then noticeRemote:FireClient(player, text) end
end
local function coinsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("เหรียญ")
end
local function short(n)
	if n >= 1000 and n % 1000 == 0 then return tostring(n // 1000) .. "k" end
	return tostring(n)
end
local function ready(player)
	-- InventoryReady = กระเป๋าโหลดสำเร็จจริง (ไม่งั้นป้ายที่ซื้อไม่ถูกเซฟ)
	return player:GetAttribute("CoinsLoaded") == true and player:GetAttribute("InventoryReady") == true
end
local function saveBag(player)
	if saveInventoryNow then saveInventoryNow:Fire(player) end
end
local function ownedCount(player)
	return #SignItems.Tools(player) + SignItems.PlacedCount(player)
end

local signFolder = workspace:FindFirstChild("PlayerSigns")
if not signFolder then
	signFolder = Instance.new("Folder")
	signFolder.Name = "PlayerSigns"
	signFolder.Parent = workspace
end

-- ============ ร้านป้าย ============
local function buy(player)
	if not ready(player) then
		return notify(player, msg(player, "ยังโหลดข้อมูลไม่เสร็จ รอสักครู่นะ", "Still loading your data, please wait"))
	end
	if ownedCount(player) >= Config.MAX_OWN then
		return notify(player, msg(player, "มีป้ายครบ " .. Config.MAX_OWN .. " อันแล้ว (นับรวมที่ปักอยู่)", "You already have " .. Config.MAX_OWN .. " signs (including planted ones)"))
	end
	local coins = coinsOf(player)
	if not coins or coins.Value < Config.PRICE then
		return notify(player, msg(player, "เหรียญไม่พอ ป้ายราคา " .. short(Config.PRICE) .. " 💰", "Not enough coins, a sign costs " .. short(Config.PRICE) .. " 💰"))
	end
	player:SetAttribute("CoinSrc", "sign")
	coins.Value -= Config.PRICE
	local tool = SignItems.Give(player, "", lang(player))
	if not tool then
		coins.Value += Config.PRICE
		return notify(player, msg(player, "ซื้อไม่สำเร็จ ลองใหม่อีกครั้ง", "Purchase failed, please try again"))
	end
	if saveCoinsNow then saveCoinsNow:Fire(player) end
	saveBag(player)
	notify(player, msg(player, "📝 ได้ป้ายเปล่าแล้ว! ถือป้ายแล้วกด ✏️ เขียนป้าย", "📝 Got a blank sign! Hold it and press ✏️ Write sign"))
end

do
	local shop = models.SignShop:Clone()
	shop.Name = "SignShop"
	local base = Vector3.new(Config.SHOP_POS.X, 200, Config.SHOP_POS.Z)
	local hit = workspace:Raycast(base, Vector3.new(0, -400, 0))
	local pos = Vector3.new(Config.SHOP_POS.X, hit and hit.Position.Y or Config.SHOP_POS.Y, Config.SHOP_POS.Z)
	shop:PivotTo(CFrame.lookAt(pos, pos + Config.SHOP_FACING))
	shop.Parent = workspace
	local prompt = shop:FindFirstChild("SignShopPrompt", true)
	local last = {}
	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if last[player] and now - last[player] < 1 then return end
		last[player] = now
		buy(player)
	end)
	Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end

-- ============ เขียนป้าย ============
local lastWrite = {}
local busy = {}
local actions = {}

function actions.write(player, text)
	local tool = SignItems.Held(player)
	if not tool then return { ok = false, message = msg(player, "ถือป้ายก่อน", "Hold a sign first") } end
	if type(text) ~= "string" or #text > 400 then return { ok = false, message = "?" } end
	text = Config.Clean(text)
	local n = Config.CountChars(text)
	if n == nil then return { ok = false, message = msg(player, "ข้อความไม่ถูกต้อง", "Invalid text") } end
	if n > Config.MAX_CHARS then
		return { ok = false, message = msg(player, "ยาวเกิน " .. Config.MAX_CHARS .. " ตัวอักษร", "Longer than " .. Config.MAX_CHARS .. " characters") }
	end
	local now = os.clock()
	if lastWrite[player] and now - lastWrite[player] < Config.EDIT_COOLDOWN then
		local wait = math.ceil(Config.EDIT_COOLDOWN - (now - lastWrite[player]))
		return { ok = false, message = msg(player, "รออีก " .. wait .. " วินาทีแล้วค่อยเขียนใหม่", "Wait " .. wait .. " more seconds") }
	end
	lastWrite[player] = now
	local l = lang(player)
	if text == "" then
		SignItems.SetRaw(tool, "")
		SignItems.SetShown(tool, "", l)
		saveBag(player)
		return { ok = true, shown = "", message = msg(player, "ลบข้อความบนป้ายแล้ว", "Sign cleared") }
	end
	local filtered = SignItems.Filter(player, text)
	if filtered == nil then
		lastWrite[player] = nil
		return { ok = false, message = msg(player, "ตัวกรองข้อความของ Roblox ไม่ตอบ ลองใหม่อีกที", "Roblox text filter did not respond, try again") }
	end
	if Config.FullyBlocked(filtered) then
		return { ok = false, message = msg(player, "ข้อความถูกตัวกรองของ Roblox ปิดทั้งหมด ลองเปลี่ยนคำ (เลี่ยงตัวเลข)", "The Roblox filter hid all of it, try other words (avoid numbers)") }
	end
	if tool.Parent == nil then return { ok = false, message = "?" } end
	SignItems.SetRaw(tool, text)
	SignItems.SetShown(tool, filtered, l)
	saveBag(player)
	local partly = filtered ~= text
	return { ok = true, shown = filtered, message = partly
		and msg(player, "เขียนแล้ว แต่บางคำถูกกรอง (###)", "Written, but some words were filtered (###)")
		or msg(player, "✏️ เขียนป้ายแล้ว! ทุกคนเห็นข้อความนี้", "✏️ Sign written! Everyone can see it") }
end

-- ============ ปัก / เก็บ / หายเอง ============
local function totalPlanted()
	local n = 0
	for _, list in pairs(SignItems.placed) do n += #list end
	return n
end

local function removeRecord(userId, rec)
	local list = SignItems.placed[userId]
	if not list then return end
	local i = table.find(list, rec)
	if i then table.remove(list, i) end
	if #list == 0 then SignItems.placed[userId] = nil end
end

-- ถอนป้ายที่ปักกลับเข้ากระเป๋าเจ้าของ (wipe = ลบข้อความทิ้ง)
local function returnSign(owner, rec, wipe)
	local raw = wipe and "" or rec.raw
	local tool = SignItems.Give(owner, raw, lang(owner))
	if not tool then return false end -- ไม่มี Backpack (กำลังเกิดใหม่) ลองรอบหน้า
	if not wipe and rec.shown and rec.shown ~= "" then
		SignItems.SetShown(tool, rec.shown, lang(owner)) -- กรองแล้ว ไม่ต้องรอกรองใหม่
	end
	removeRecord(owner.UserId, rec)
	if rec.model then rec.model:Destroy() end
	saveBag(owner)
	return true
end

local pickupLast = {}
local function buildPlanted(player, tool, pos, facing)
	local m = models.Sign:Clone()
	m.Name = "Sign_" .. player.UserId
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false -- ไม่ขวางทางเดิน
			p.CanTouch = false
		end
	end
	-- ปักลงดินนิดหน่อย หันหน้าป้าย (ด้าน -Z) เข้าหาคนปัก
	local at = pos - Vector3.new(0, 0.35, 0)
	m:PivotTo(CFrame.lookAt(at, at + facing))
	m:SetAttribute("OwnerUserId", player.UserId)
	m:SetAttribute("OwnerName", player.DisplayName)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SignPickupPrompt"
	prompt.ObjectText = "📝 ป้ายของคุณ"
	prompt.ActionText = "เก็บป้าย"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = Config.PICKUP_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false -- SignClient เปิดให้เฉพาะเจ้าของ (คนอื่นไม่เห็นปุ่ม)
	prompt.Parent = m.Handle
	return m, prompt
end

function actions.plant(player, point)
	local tool = SignItems.Held(player)
	if not tool then return { ok = false, message = msg(player, "ถือป้ายก่อน", "Hold a sign first") } end
	if typeof(point) ~= "Vector3" then return { ok = false, message = "?" } end
	if (tool:GetAttribute("SignText") or "") == "" then
		return { ok = false, message = msg(player, "เขียนข้อความบนป้ายก่อนค่อยปัก", "Write on the sign before planting it") }
	end
	if SignItems.PlacedCount(player) >= Config.MAX_PLANTED then
		return { ok = false, message = msg(player, "ปักได้พร้อมกัน " .. Config.MAX_PLANTED .. " ป้าย เก็บป้ายเก่าก่อน", "You can plant " .. Config.MAX_PLANTED .. " signs at once, pick one up first") }
	end
	if totalPlanted() >= Config.MAX_PLANTED_SERVER then
		return { ok = false, message = msg(player, "เซิร์ฟนี้ป้ายเต็มแล้ว ลองใหม่ทีหลัง", "This server is full of signs, try later") }
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return { ok = false, message = "?" } end
	local flat = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
	if flat.Magnitude > Config.PLANT_RANGE + 2 or math.abs(point.Y - root.Position.Y) > 12 then
		return { ok = false, message = msg(player, "ไกลเกินไป เดินเข้าไปใกล้ๆ", "Too far, walk closer") }
	end
	local zone = Config.InNoZone(point)
	if zone then
		return { ok = false, message = msg(player, "ปักตรงนี้ไม่ได้ (ลานเกิด / หน้าร้าน / ท่าเรือ)", "You can't plant here (spawn / shop / dock)") }
	end
	-- ตรวจพื้นจริง: ยิงลงจากเหนือจุด ต้องชน Terrain ดิน/หญ้า/ทราย ก่อนอย่างอื่น (น้ำนับด้วย)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { signFolder }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	local hit = workspace:Raycast(point + Vector3.new(0, 4, 0), Vector3.new(0, -8, 0), params)
	if not hit or hit.Instance ~= workspace.Terrain or not Config.GROUND[hit.Material] then
		return { ok = false, message = msg(player, "ปักได้เฉพาะบนดิน หญ้า หรือทราย", "Signs go in dirt, grass or sand only") }
	end
	if hit.Normal.Y < 0.7 then
		return { ok = false, message = msg(player, "ตรงนี้ชันเกินไป", "Too steep here") }
	end
	for _, other in ipairs(signFolder:GetChildren()) do
		if other:IsA("Model") and (other:GetPivot().Position - hit.Position).Magnitude < 2.5 then
			return { ok = false, message = msg(player, "ใกล้ป้ายอื่นเกินไป", "Too close to another sign") }
		end
	end
	if busy[player] then return { ok = false, message = "" } end
	busy[player] = true
	local facing = Vector3.new(root.Position.X - hit.Position.X, 0, root.Position.Z - hit.Position.Z)
	facing = facing.Magnitude > 0.1 and facing.Unit or Vector3.new(0, 0, -1)
	local shown = tool:GetAttribute("SignText") or ""
	local raw = SignItems.RawOf(tool)
	local m, prompt = buildPlanted(player, tool, hit.Position, facing)
	SignItems.SetShown(m, shown)
	local rec = { model = m, raw = raw, shown = shown, expires = os.time() + Config.LIFETIME }
	local list = SignItems.placed[player.UserId]
	if not list then list = {}; SignItems.placed[player.UserId] = list end
	table.insert(list, rec)
	tool:Destroy()
	m.Parent = signFolder
	prompt.Triggered:Connect(function(who)
		if who.UserId ~= player.UserId then return end
		local now = os.clock()
		if pickupLast[who] and now - pickupLast[who] < 0.5 then return end
		pickupLast[who] = now
		if not m.Parent then return end
		if returnSign(who, rec, false) then
			notify(who, msg(who, "📝 เก็บป้ายเข้ากระเป๋าแล้ว", "📝 Sign back in your bag"))
		end
	end)
	saveBag(player)
	busy[player] = nil
	return { ok = true, message = msg(player, "📍 ปักป้ายแล้ว! อยู่ได้ " .. (Config.LIFETIME // 60) .. " นาที กด E ที่ป้ายเพื่อเก็บคืน",
		"📍 Sign planted! It stays " .. (Config.LIFETIME // 60) .. " minutes, press E on it to pick it up") }
end

requestRemote.OnServerInvoke = function(player, action, a)
	local fn = type(action) == "string" and actions[action]
	if not fn then return { ok = false, message = "?" } end
	local ok, res = pcall(fn, player, a)
	if not ok then
		warn("SignService: " .. tostring(action) .. " error: " .. tostring(res))
		busy[player] = nil
		return { ok = false, message = msg(player, "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง", "Something went wrong, try again") }
	end
	return res
end

-- หมดเวลา = กลับเข้ากระเป๋า (เช็กทุก 10 วิ)
task.spawn(function()
	while true do
		task.wait(10)
		local t = os.time()
		for userId, list in pairs(SignItems.placed) do
			local owner = Players:GetPlayerByUserId(userId)
			if owner then
				for i = #list, 1, -1 do
					local rec = list[i]
					if rec and rec.model and rec.model.Parent and t >= rec.expires then
						if returnSign(owner, rec, false) then
							notify(owner, msg(owner, "📝 ป้ายที่ปักไว้ครบเวลาแล้ว กลับเข้ากระเป๋า", "📝 A planted sign timed out and is back in your bag"))
						end
					end
				end
			end
		end
	end
end)

-- เจ้าของออกเกม: ลบป้ายออกจากแมพทันที แต่เก็บรายการไว้อีก 60 วิ ให้ InventorySystem เซฟเข้ากระเป๋าทัน (เซฟตอนออกรวม PlacedEntries)
Players.PlayerRemoving:Connect(function(player)
	lastWrite[player] = nil
	busy[player] = nil
	pickupLast[player] = nil
	local list = SignItems.placed[player.UserId]
	if not list then return end
	for _, rec in ipairs(list) do
		if rec.model then rec.model:Destroy() rec.model = nil end
	end
	task.delay(60, function()
		if SignItems.placed[player.UserId] == list then SignItems.placed[player.UserId] = nil end
	end)
end)
-- เข้าเซิร์ฟเดิมก่อน 60 วิ: ป้ายพวกนั้นเซฟเข้ากระเป๋าไปแล้ว (โหลดกลับมาเป็น Tool) ล้างรายการเก่า กันนับซ้ำ
Players.PlayerAdded:Connect(function(player)
	local list = SignItems.placed[player.UserId]
	if list then
		for _, rec in ipairs(list) do if rec.model then rec.model:Destroy() end end
		SignItems.placed[player.UserId] = nil
	end
end)

-- ============ /clearsigns [ชื่อ] (เจ้าของเกม) ============
local function adminNotify(player, text)
	local hn = remoteEvents:FindFirstChild("HarvestNotify")
	if hn then hn:FireClient(player, nil, nil, nil, text) else notify(player, text) end
end
local lastCommand = {}
local function handleCommand(player, text)
	if not player or not ADMINS[player.UserId] or type(text) ~= "string" then return end
	if text:lower():sub(1, 11) ~= "/clearsigns" then return end
	local prev = lastCommand[player]
	if prev and prev.text == text and os.clock() - prev.clock < 2 then return end
	lastCommand[player] = { text = text, clock = os.clock() }
	local name = text:match("^/%a+%s+(%S+)")
	local cleared = 0
	for userId, list in pairs(SignItems.placed) do
		local owner = Players:GetPlayerByUserId(userId)
		local match = name == nil or (owner and (owner.Name:lower() == name:lower() or owner.DisplayName:lower() == name:lower()))
		if owner and match then
			for i = #list, 1, -1 do
				if returnSign(owner, list[i], true) then cleared += 1 end
			end
			notify(owner, msg(owner, "📝 ป้ายที่ปักไว้ถูกเก็บคืนโดยทีมงาน (ลบข้อความแล้ว)", "📝 Your planted signs were removed by staff (text cleared)"))
		end
	end
	adminNotify(player, "📝 ถอนป้าย " .. cleared .. " อัน" .. (name and (" ของ " .. name) or " (ทุกคน)") .. " คืนเจ้าของเป็นป้ายเปล่า")
end
local okCmd, errCmd = pcall(function()
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "ClearSignsCommand"
	cmd.PrimaryAlias = "/clearsigns"
	cmd.Parent = folder
	cmd.Triggered:Connect(function(source, text)
		handleCommand(source and Players:GetPlayerByUserId(source.UserId), text)
	end)
end)
if not okCmd then warn("SignService: สร้างคำสั่งแชทไม่สำเร็จ: " .. tostring(errCmd)) end
local function hookChat(player)
	if not ADMINS[player.UserId] then return end
	player.Chatted:Connect(function(message) handleCommand(player, message) end)
end
Players.PlayerAdded:Connect(hookChat)
for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
Players.PlayerRemoving:Connect(function(player) lastCommand[player] = nil end)
