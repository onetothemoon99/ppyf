-- BACKUP 2026-11-14: ServerScriptService.Sign.SignService (Script) ก่อนเปลี่ยนเป็นปักได้ป้ายเดียว (onePlanted)
-- กู้คืน: เปิดสคริปต์นี้ใน Studio แล้ววางเนื้อหาตั้งแต่บรรทัดที่ 5 ของไฟล์นี้ทับทั้งหมด
-- (เนื้อหาเดิม 18912 ไบต์)
--
-- SignService (2026-11-14): ป้ายเขียนข้อความ ฝั่งเซิร์ฟเวอร์ (คู่กับ StarterPlayerScripts.SignClient) · ค่าต่างๆ ReplicatedStorage.SignConfig · แผน SIGNS.md
-- 2026-11-14 (ผู้ใช้สั่ง "อยู่ในกระเป๋าเป็น item กดใช้เอา ไม่ต้องมีร้านขาย"): ไม่มีร้านแล้ว
--   ทุกคนได้ป้ายฟรี 1 อัน (แจกหลังกระเป๋าโหลดสำเร็จ ถ้ายังไม่มี) ใช้ไม่หมด · มีเกิน 1 อัน = เก็บไว้อันเดียว
--   RemoteFunction RemoteEvents.SignRequest(action, ...) : "write" (ข้อความ) / "plant" (จุดบนพื้น) · ต้องถือป้ายอยู่
--   ปัก = วางสำเนาป้าย (ข้อความเดียวกับในมือ) ลงพื้น ป้ายในมือยังอยู่ · ปักได้คนละ Config.MAX_PLANTED เกิน = ลบอันที่ปักก่อนสุด
--   ป้ายที่ปัก = workspace.PlayerSigns.<Model> Anchored ไม่ชนใคร Attribute OwnerUserId/OwnerName/SignText · เจ้าของกด E = ลบ (คนอื่นไม่เห็นปุ่ม SignClient ซ่อน)
--   หายเอง: ครบ Config.LIFETIME หรือเจ้าของออกเกม (ไม่เซฟ ป้ายที่ปักไม่ใช่ของในกระเป๋า)
--   RemoteEvent RemoteEvents.SignNotice(ข้อความ) = แจ้งผลที่ไม่ได้มาจากการกด (ได้ป้าย / หมดเวลา / ทีมงานลบ)
--   คำสั่งแชทเจ้าของเกม: /clearsigns [ชื่อ] = ลบป้ายที่ปัก (ทุกคน / เฉพาะคนนั้น) และล้างข้อความบนป้ายในมือของคนนั้น

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage:WaitForChild("SignConfig"))
if not Config.ENABLED then return end -- DEV_ONLY: เซิร์ฟจริงไม่มีระบบป้าย (ป้ายในกระเป๋ายังเซฟผ่าน InventorySystem)

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local SignItems = require(script.Parent:WaitForChild("SignItems"))
local models = ReplicatedStorage:WaitForChild("SignModels")

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
local function saveBag(player)
	if saveInventoryNow then saveInventoryNow:Fire(player) end
end

local signFolder = workspace:FindFirstChild("PlayerSigns")
if not signFolder then
	signFolder = Instance.new("Folder")
	signFolder.Name = "PlayerSigns"
	signFolder.Parent = workspace
end

-- ============ แจกป้ายฟรี 1 อัน ============
-- รอ InventoryReady (กระเป๋าโหลดสำเร็จจริง) ก่อน ไม่งั้นป้ายที่เซฟไว้จะโหลดมาซ้ำ / ป้ายที่แจกไม่ถูกเซฟ
local function ensureSign(player)
	if not player.Parent or player:GetAttribute("InventoryReady") ~= true then return end
	local tools = SignItems.Tools(player)
	if #tools == 0 then
		if SignItems.Give(player, "", lang(player)) then
			saveBag(player)
			notify(player, msg(player, "📝 ได้ป้ายฟรีในกระเป๋าแล้ว! ถือป้ายแล้วกดใช้เพื่อเขียนและปัก", "📝 You got a free sign in your bag! Hold it and use it to write and plant"))
		end
	elseif #tools > 1 then
		-- เวอร์ชันร้านป้ายเดิม (ทดสอบใน Studio) อาจมีหลายอัน: เก็บอันที่มีข้อความไว้อันเดียว
		table.sort(tools, function(a, b) return #SignItems.RawOf(a) > #SignItems.RawOf(b) end) -- ดูข้อความดิบ (ตอนเข้าเกมตัวกรองยังไม่เสร็จ)
		for i = 2, #tools do tools[i]:Destroy() end
		saveBag(player)
	end
end
local function hookPlayer(player)
	player:GetAttributeChangedSignal("InventoryReady"):Connect(function() task.delay(1, ensureSign, player) end)
	task.delay(1, ensureSign, player)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end

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

-- ============ ปัก / ลบ / หายเอง ============
local function totalPlanted()
	local n = 0
	for _, list in pairs(SignItems.placed) do n += #list end
	return n
end

local function removeSign(userId, rec)
	local list = SignItems.placed[userId]
	if list then
		local i = table.find(list, rec)
		if i then table.remove(list, i) end
		if #list == 0 then SignItems.placed[userId] = nil end
	end
	if rec.model then rec.model:Destroy() rec.model = nil end
end

local pickupLast = {}
local function buildPlanted(player, pos, facing)
	local m = models.Sign:Clone()
	m.Name = "Sign_" .. player.UserId
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false -- ไม่ขวางทางเดิน
			p.CanTouch = false
		end
	end
	-- ปักลงดินนิดหน่อย หันหน้าป้าย (ด้าน -Z) เข้าหาคนปัก · pivot ของโมเดล = โคนเสา
	local at = pos - Vector3.new(0, 0.35, 0)
	m:PivotTo(CFrame.lookAt(at, at + facing))
	m:SetAttribute("OwnerUserId", player.UserId)
	m:SetAttribute("OwnerName", player.DisplayName)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SignPickupPrompt"
	prompt.ObjectText = "📝 ป้ายของคุณ"
	prompt.ActionText = "ลบป้าย"
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
	local shown = tool:GetAttribute("SignText") or ""
	if shown == "" then
		return { ok = false, message = msg(player, "เขียนข้อความบนป้ายก่อนค่อยปัก", "Write on the sign before planting it") }
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return { ok = false, message = "?" } end
	local flat = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
	if flat.Magnitude > Config.PLANT_RANGE + 2 or math.abs(point.Y - root.Position.Y) > 12 then
		return { ok = false, message = msg(player, "ไกลเกินไป เดินเข้าไปใกล้ๆ", "Too far, walk closer") }
	end
	if Config.InNoZone(point) then
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
	-- เกินจำนวน = ลบป้ายที่ปักก่อนสุดของคนนี้
	local list = SignItems.placed[player.UserId]
	while list and #list >= Config.MAX_PLANTED do
		removeSign(player.UserId, list[1])
		list = SignItems.placed[player.UserId]
	end
	if totalPlanted() >= Config.MAX_PLANTED_SERVER then
		busy[player] = nil
		return { ok = false, message = msg(player, "เซิร์ฟนี้ป้ายเต็มแล้ว ลองใหม่ทีหลัง", "This server is full of signs, try later") }
	end
	local facing = Vector3.new(root.Position.X - hit.Position.X, 0, root.Position.Z - hit.Position.Z)
	facing = facing.Magnitude > 0.1 and facing.Unit or Vector3.new(0, 0, -1)
	local m, prompt = buildPlanted(player, hit.Position, facing)
	SignItems.SetShown(m, shown)
	local rec = { model = m, shown = shown, expires = os.time() + Config.LIFETIME }
	list = SignItems.placed[player.UserId]
	if not list then list = {}; SignItems.placed[player.UserId] = list end
	table.insert(list, rec)
	m.Parent = signFolder
	prompt.Triggered:Connect(function(who)
		if who.UserId ~= player.UserId then return end
		local now = os.clock()
		if pickupLast[who] and now - pickupLast[who] < 0.5 then return end
		pickupLast[who] = now
		if not rec.model then return end
		removeSign(who.UserId, rec)
		notify(who, msg(who, "📝 ลบป้ายแล้ว", "📝 Sign removed"))
	end)
	busy[player] = nil
	local count = #list
	return { ok = true, message = msg(player, "📍 ปักป้ายแล้ว! (" .. count .. "/" .. Config.MAX_PLANTED .. ") อยู่ได้ " .. (Config.LIFETIME // 60) .. " นาที",
		"📍 Sign planted! (" .. count .. "/" .. Config.MAX_PLANTED .. ") It stays " .. (Config.LIFETIME // 60) .. " minutes") }
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

-- หมดเวลา = หาย (เช็กทุก 10 วิ)
task.spawn(function()
	while true do
		task.wait(10)
		local t = os.time()
		for userId, list in pairs(SignItems.placed) do
			for i = #list, 1, -1 do
				local rec = list[i]
				if rec and t >= rec.expires then removeSign(userId, rec) end
			end
		end
	end
end)

-- เจ้าของออกเกม = ป้ายที่ปักหายทั้งหมด
local function clearPlayer(userId)
	local list = SignItems.placed[userId]
	if not list then return 0 end
	local n = #list
	for i = #list, 1, -1 do removeSign(userId, list[i]) end
	SignItems.placed[userId] = nil
	return n
end
Players.PlayerRemoving:Connect(function(player)
	lastWrite[player] = nil
	busy[player] = nil
	pickupLast[player] = nil
	clearPlayer(player.UserId)
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
	for userId in pairs(table.clone(SignItems.placed)) do
		local owner = Players:GetPlayerByUserId(userId)
		local match = name == nil or (owner and (owner.Name:lower() == name:lower() or owner.DisplayName:lower() == name:lower()))
		if match then
			cleared += clearPlayer(userId)
			if owner then
				-- ล้างข้อความบนป้ายในมือ/กระเป๋าด้วย (ข้อความไม่เหมาะสมจะได้ไม่ถูกปักซ้ำ)
				for _, t in ipairs(SignItems.Tools(owner)) do
					SignItems.SetRaw(t, "")
					SignItems.SetShown(t, "", lang(owner))
				end
				saveBag(owner)
				notify(owner, msg(owner, "📝 ป้ายของคุณถูกลบโดยทีมงาน (ล้างข้อความแล้ว)", "📝 Your signs were removed by staff (text cleared)"))
			end
		end
	end
	adminNotify(player, "📝 ลบป้ายที่ปัก " .. cleared .. " อัน" .. (name and (" ของ " .. name) or " (ทุกคน)") .. " และล้างข้อความบนป้ายในมือ")
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
