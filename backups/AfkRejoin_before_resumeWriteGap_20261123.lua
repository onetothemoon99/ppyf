-- BACKUP of game.ServerScriptService.AfkRejoin before FishingResume_v1 write gap (2026-11-23)
-- Restore: paste everything below this header back into the script's Source in Studio.
-- AfkRejoin: ผู้เล่นนิ่งเกือบ 20 นาที (Roblox เตะออกที่ 20 นาที) = พาเข้าเกมใหม่เซิร์ฟเวอร์เดิม นับเวลานิ่งใหม่ ไม่หลุดเกม
-- ฝั่งผู้เล่น (StarterPlayerScripts.AfkRejoinClient) นับเวลานิ่ง นับถอยหลัง 10 วิ แล้วส่ง RemoteEvent "AfkRejoin" มา ที่นี่เป็นคนสั่งย้ายเซิร์ฟเวอร์
-- เข้าเซิร์ฟเวอร์เดิมก่อน (JobId เดิม: ข้อมูลที่เซฟตอนออกอยู่ในเซิร์ฟเวอร์เดียวกัน โหลดกลับมาได้ค่าล่าสุดแน่นอน)
-- เซิร์ฟเวอร์เต็ม/เข้าไม่ได้ = ไปเซิร์ฟเวอร์อื่นแทน / TeleportData { afkRejoin = true } ให้ฝั่งผู้เล่นรู้ว่ามาจาก AFK
-- ตำแหน่งเดิม: LastPosition เซฟตอนออกแล้วพากลับมาที่เดิมให้เอง

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local rejoinEvent = remoteEvents:FindFirstChild("AfkRejoin")
if not rejoinEvent then
	rejoinEvent = Instance.new("RemoteEvent")
	rejoinEvent.Name = "AfkRejoin"
	rejoinEvent.Parent = remoteEvents
end
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local COOLDOWN = 20 -- วินาที กันส่งคำขอซ้ำ
local lastRequest = {} -- [player] = os.clock()
local triedAnyServer = {} -- [player] = true (เข้าเซิร์ฟเวอร์เดิมไม่ได้ ลองเซิร์ฟเวอร์อื่นไปแล้ว)
-- teleport ที่ Roblox รับคำขอแล้วแต่ยังไม่จบ (เครื่องช้าใช้เวลานาน) ระหว่างนี้ตาข่ายนิรภัยห้ามสั่งซ้ำ ไม่งั้นได้ IsTeleporting แล้วล้มทั้งคู่ (2026-10-23)
local teleportInFlight = {} -- [player] = os.clock()
local IN_FLIGHT_GRACE = 120

local function notify(player, text)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

-- ============ จดขั้นกลับมาตกปลาต่อ (2026-10-24) ============
-- ผู้เล่นแจ้ง: ขี่สัตว์ + AFK ตกปลา กลับมาแล้วไม่ถือเบ็ด (อ่านโค้ดไม่เจอสาเหตุ จำลองใน Studio ผ่าน) → จดทุกขั้นหลังเข้ามาใหม่ ไว้เป็นหลักฐานครั้งหน้า
-- เข้ามาด้วย AFK rejoin ที่มีข้อมูลตกปลา = เริ่มจด: ขั้นที่เซิร์ฟเวอร์เห็น (วางตัว/ขี่/นั่ง/ถือเบ็ด/เกิดใหม่/ออโต้/ทุ่น) + ที่เครื่องผู้เล่นรายงาน (AfkResumeReport)
-- ครบ 60 วิ: ไม่ครบตามที่ควร (ถือเบ็ดเดิม / ขี่ตัวเดิม / ออโต้) = เขียน 1 รายการ "resume-incomplete" ที่ DataStore "AfkRejoinWatch_v1" key "resume" (100 รายการล่าสุด) · ปกติไม่เขียนอะไร
-- Studio: พิมพ์อย่างเดียว (ตั้ง workspace Attribute DevAfkWatchWrite = true ถ้าจะเขียน) · ย่นเวลาตรวจ: workspace Attribute DevAfkResumeCheckAfter (วินาที)
local RESUME_CHECK_AFTER = 60
local RESUME_MAX_RECORDS = 100
local traceStore = game:GetService("DataStoreService"):GetDataStore("AfkRejoinWatch_v1")
local resumeTrace = {} -- [player] = { t0, exp, ev, client, conns }
local CLIENT_STAGES = { norod = true, equip = true }

local resumeReport = remoteEvents:FindFirstChild("AfkResumeReport")
if not resumeReport then
	resumeReport = Instance.new("RemoteEvent")
	resumeReport.Name = "AfkResumeReport"
	resumeReport.Parent = remoteEvents
end

local function traceEvent(player, key, value)
	local tr = resumeTrace[player]
	if not tr or #tr.ev >= 24 then return end
	tr.ev[#tr.ev + 1] = string.format("%s=%s@%.1f", key, tostring(value), os.clock() - tr.t0)
end

local function writeTraceRecord(rec)
	print(string.format("[AfkRejoin] RESUME-TRACE %s problems=%s ev=%s", tostring(rec.name), table.concat(rec.problems, ","), table.concat(rec.ev, " ")))
	if RunService:IsStudio() and workspace:GetAttribute("DevAfkWatchWrite") ~= true then return end
	task.spawn(function()
		for attempt = 1, 3 do
			local ok = pcall(function()
				traceStore:UpdateAsync("resume", function(old)
					local list = type(old) == "table" and table.clone(old) or {}
					table.insert(list, rec)
					while #list > RESUME_MAX_RECORDS do table.remove(list, 1) end
					return list
				end)
			end)
			if ok then return end
			task.wait(attempt * 3)
		end
	end)
end

local function heldRodId(player)
	local character = player.Character
	if character then
		for _, c in ipairs(character:GetChildren()) do
			if c:IsA("Tool") and c:GetAttribute("IsFishingRod") then return c:GetAttribute("RodId") end
		end
	end
	return nil
end

local function bagRodIds(player)
	local ids = {}
	local bp = player:FindFirstChildOfClass("Backpack")
	if bp then
		for _, c in ipairs(bp:GetChildren()) do
			if c:IsA("Tool") and c:GetAttribute("IsFishingRod") then table.insert(ids, tostring(c:GetAttribute("RodId"))) end
		end
	end
	return ids
end

local function resumeEvaluate(player, tr)
	if resumeTrace[player] ~= tr then return end
	resumeTrace[player] = nil
	for _, c in ipairs(tr.conns) do c:Disconnect() end
	if not player.Parent then return end
	local exp = tr.exp
	local held = heldRodId(player)
	local riding = player:GetAttribute("RidingMount")
	local auto = player:GetAttribute("FishingAuto") == true
	local problems = {}
	if held ~= exp.rod then table.insert(problems, held and "wrongRod" or "noRod") end
	if exp.mount and riding ~= exp.mount then table.insert(problems, "notRiding") end
	if exp.auto and not auto then table.insert(problems, "autoOff") end
	if #problems == 0 then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	writeTraceRecord({
		kind = "resume-incomplete", t = os.time(), userId = player.UserId, name = player.Name, job = game.JobId, ver = game.PlaceVersion,
		problems = problems,
		expected = { rod = exp.rod, auto = exp.auto, mount = exp.mount, seat = exp.seat },
		actual = {
			held = held, riding = riding, auto = auto, bobber = workspace:FindFirstChild(player.Name .. "_Bobber") ~= nil,
			spawnPlaced = player:GetAttribute("SpawnPlaced") == true, bag = bagRodIds(player), seated = humanoid ~= nil and humanoid.SeatPart ~= nil,
		},
		client = tr.client,
		ev = tr.ev,
	})
end

-- เข้ามาด้วย AFK rejoin ที่มีข้อมูลตกปลา (f = TeleportData.fishing) = เริ่มจด
local function resumeBegin(player, f)
	local old = resumeTrace[player]
	if old then for _, c in ipairs(old.conns) do c:Disconnect() end end
	local tr = {
		t0 = os.clock(), ev = {}, conns = {},
		exp = { rod = f.rodId, auto = f.auto == true, mount = type(f.mount) == "string" and f.mount or nil, seat = f.seat ~= nil, cast = f.cast ~= nil },
	}
	resumeTrace[player] = tr
	traceEvent(player, "arrive", string.format("rod=%s,auto=%s,mount=%s,seat=%s", tostring(f.rodId), tostring(f.auto == true), tostring(f.mount), tostring(f.seat ~= nil)))
	local function conn(c) table.insert(tr.conns, c) end
	if player:GetAttribute("SpawnPlaced") then
		traceEvent(player, "spawnPlaced", "already")
	else
		conn(player:GetAttributeChangedSignal("SpawnPlaced"):Connect(function()
			if player:GetAttribute("SpawnPlaced") then traceEvent(player, "spawnPlaced", "ok") end
		end))
	end
	conn(player:GetAttributeChangedSignal("RidingMount"):Connect(function() traceEvent(player, "riding", player:GetAttribute("RidingMount")) end))
	conn(player:GetAttributeChangedSignal("FishingAuto"):Connect(function() traceEvent(player, "auto", player:GetAttribute("FishingAuto")) end))
	local function hookCharacter(character)
		traceEvent(player, "character", "seen")
		conn(character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child:GetAttribute("IsFishingRod") then traceEvent(player, "rodHeld", child:GetAttribute("RodId")) end
		end))
		conn(character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child:GetAttribute("IsFishingRod") and character.Parent then traceEvent(player, "rodLeftHand", child:GetAttribute("RodId")) end
		end))
	end
	if player.Character then hookCharacter(player.Character) end
	conn(player.CharacterAdded:Connect(function(character) traceEvent(player, "respawn", "CharacterAdded") hookCharacter(character) end))
	local bobberSeen = false
	conn(workspace.ChildAdded:Connect(function(c)
		if not bobberSeen and c.Name == player.Name .. "_Bobber" then bobberSeen = true traceEvent(player, "bobber", "first") end
	end))
	local after = RunService:IsStudio() and tonumber(workspace:GetAttribute("DevAfkResumeCheckAfter")) or RESUME_CHECK_AFTER
	task.delay(after, resumeEvaluate, player, tr)
end

-- เครื่องผู้เล่นรายงานขั้นถือเบ็ด (AfkRejoinClient.resumeFishing) — ใช้เป็นหลักฐานเท่านั้น ตรวจชนิด/จำกัดค่าก่อนเก็บ
resumeReport.OnServerEvent:Connect(function(player, stage, info)
	local tr = resumeTrace[player]
	if not tr or type(stage) ~= "string" or not CLIENT_STAGES[stage] then return end
	tr.client = tr.client or {}
	if tr.client[stage] then return end
	local rec = {}
	if type(info) == "table" then
		rec.waited = type(info.waited) == "number" and info.waited == info.waited and math.clamp(math.floor(info.waited), 0, 100000) or nil
		rec.found = info.found == true or nil
		rec.idMatch = info.idMatch == true or nil
		rec.held = info.held == true or nil
	end
	tr.client[stage] = rec
	traceEvent(player, "client", stage)
end)

Players.PlayerRemoving:Connect(function(player)
	local tr = resumeTrace[player]
	if tr then for _, c in ipairs(tr.conns) do c:Disconnect() end end
	resumeTrace[player] = nil
end)

-- กำลังตกปลาอยู่ไหม (ถือเบ็ดอันไหน / ออโต้ / เหยื่อที่เลือก) ส่งไปกับการเข้าเกมใหม่ ให้กลับมาตกต่อที่เดิม (AfkRejoinClient)
local fishingSnap = {} -- [player] = { rodId, auto, bait, seat } | false
-- นั่งเก้าอี้อยู่ = จำตำแหน่งเก้าอี้ไว้ เข้าเกมใหม่แล้วพานั่งที่เดิมก่อนตกปลาต่อ (2026-10-10 ผู้ใช้เจอ: นั่งเก้าอี้ตกปลา ครบ AFK กลับมายืนตกแทน)
local function seatInfo(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if not seat then return nil end
	local p = seat.Position
	return { x = math.floor(p.X * 100) / 100, y = math.floor(p.Y * 100) / 100, z = math.floor(p.Z * 100) / 100 }
end
-- 2026-10-12 จุดที่ทุ่นอยู่ในน้ำ (ผู้เล่นแจ้ง: ครบ AFK กลับมายืนถือเบ็ดเฉยๆ ไม่ตกออโต้)
-- ตอนกลับมา หน้าจอหาน้ำจาก "ตรงหน้าตัวละคร" เท่านั้น แต่ตอนเหวี่ยงครั้งแรกผู้เล่นแตะ/เล็งที่น้ำด้านข้างได้ (ไม่ต้องหันหน้าไป)
-- = กลับมาแล้วตรงหน้าไม่มีน้ำ ไม่เหวี่ยง → จำจุดทุ่นไปด้วย ให้ AfkRejoinClient เหวี่ยงลงจุดเดิม (เซิร์ฟเวอร์ยังตรวจระยะ/น้ำตามปกติ)
local lastCast = {} -- [player] = { x, y, z } จุดทุ่นล่าสุดขณะถือเบ็ด (ช่วงที่ทุ่นหายชั่วคราวยังใช้ค่านี้)
local function castInfo(player)
	local bobber = workspace:FindFirstChild(player.Name .. "_Bobber")
	if bobber then
		local p = bobber:IsA("Model") and bobber:GetPivot().Position or (bobber:IsA("BasePart") and bobber.Position) or nil
		if p then lastCast[player] = { x = math.floor(p.X * 100) / 100, y = math.floor(p.Y * 100) / 100, z = math.floor(p.Z * 100) / 100 } end
	end
	return lastCast[player]
end
local function takeFishingSnapshot(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("IsFishingRod") then
		-- mount = ขี่สัตว์ตกปลาอยู่ (2026-10-20 ผู้ใช้: ขี่ลามะตกปลา AFK กลับมาไม่ขี่แล้ว) กลับมาให้ขี่ตัวเดิมก่อนตกต่อ
		return { rodId = tool:GetAttribute("RodId"), auto = player:GetAttribute("FishingAuto") == true, bait = player:GetAttribute("FishingBait"), seat = seatInfo(player), cast = castInfo(player), mount = player:GetAttribute("RidingMount") }
	end
	if character and character.Parent then lastCast[player] = nil end -- เก็บเบ็ดแล้ว = ลืมจุดทุ่น
	return false
end

-- พานั่งเก้าอี้เดิม (หลัง LastPosition วางตัวเสร็จ = Attribute SpawnPlaced) เก้าอี้หาไม่เจอ/มีคนนั่งแล้ว = ยืนตกตามเดิม
local function resitLater(player, seatPos)
	if type(seatPos) ~= "table" or not (tonumber(seatPos.x) and tonumber(seatPos.y) and tonumber(seatPos.z)) then return end
	task.spawn(function()
		local waited = 0
		while player.Parent and not player:GetAttribute("SpawnPlaced") and waited < 45 do waited += task.wait(0.25) end
		task.wait(0.5)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (player.Parent and humanoid and humanoid.Health > 0) or humanoid.SeatPart then return end
		local pos = Vector3.new(seatPos.x, seatPos.y, seatPos.z)
		local best, bestDist
		for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 2)) do
			if (part:IsA("Seat") or part:IsA("VehicleSeat")) and not part.Disabled and not part.Occupant then
				local d = (part.Position - pos).Magnitude
				if d <= 1.5 and (not bestDist or d < bestDist) then best, bestDist = part, d end
			end
		end
		if not best then
			traceEvent(player, "sit", "noSeatFound")
			print("🪑 AfkRejoin: หาเก้าอี้เดิมของ " .. player.Name .. " ไม่เจอ หรือมีคนนั่งแล้ว = ยืนตกแทน")
			return
		end
		best:Sit(humanoid)
		traceEvent(player, "sit", "ok")
		print("🪑 AfkRejoin: พา " .. player.Name .. " นั่งเก้าอี้เดิม " .. best:GetFullName())
	end)
end

-- ขี่สัตว์ตัวเดิม (หลัง LastPosition วางตัวเสร็จ) ผ่าน ServerStorage.MountRideRequest (MountService) · นั่งเก้าอี้อยู่/ขี่อยู่แล้ว/ถูกแบก = ไม่ทำ (2026-10-20)
local function rideLater(player, mountId)
	if type(mountId) ~= "string" or mountId == "" then return end
	task.spawn(function()
		local waited = 0
		while player.Parent and not player:GetAttribute("SpawnPlaced") and waited < 45 do waited += task.wait(0.25) end
		task.wait(0.8)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (player.Parent and humanoid and humanoid.Health > 0) or humanoid.SeatPart then
			traceEvent(player, "ride", "skip:" .. ((humanoid and humanoid.SeatPart) and "seated" or "noCharacter"))
			return
		end
		if player:GetAttribute("RidingMount") or player:GetAttribute("CarriedBy") then
			traceEvent(player, "ride", "skip:" .. (player:GetAttribute("RidingMount") and "alreadyRiding" or "carried"))
			return
		end
		local fn = game:GetService("ServerStorage"):WaitForChild("MountRideRequest", 10)
		local ok, result = pcall(function() return fn and fn:Invoke(player, mountId) end)
		traceEvent(player, "ride", tostring(ok and result))
		print("🐴 AfkRejoin: พา " .. player.Name .. " ขี่ " .. mountId .. " ต่อ = " .. tostring(ok and result))
	end)
end

-- เข้ามาจาก AFK (TeleportData ของเซิร์ฟเวอร์เก่า) และตอนนั้นนั่งเก้าอี้อยู่ = พานั่งที่เดิม / ขี่สัตว์อยู่ = ขี่ตัวเดิม
local function arrivalFromTeleportData(player, td)
	if type(td) == "table" and td.afkRejoin and type(td.fishing) == "table" then
		resumeBegin(player, td.fishing)
		if td.fishing.seat then
			resitLater(player, td.fishing.seat)
		elseif td.fishing.mount then
			rideLater(player, td.fishing.mount)
		end
	end
end
local function onPlayerAddedSeat(player)
	local ok, joinData = pcall(function() return player:GetJoinData() end)
	local td = ok and type(joinData) == "table" and joinData.TeleportData
	arrivalFromTeleportData(player, td)
end
-- ทดสอบใน Studio (ย้ายเซิร์ฟไม่ได้): ServerStorage.AfkArrivalTest:Fire(player, teleportData)
if RunService:IsStudio() then
	local ev = game:GetService("ServerStorage"):FindFirstChild("AfkArrivalTest") or Instance.new("BindableEvent")
	ev.Name = "AfkArrivalTest"
	ev.Parent = game:GetService("ServerStorage")
	ev.Event:Connect(arrivalFromTeleportData)
end
Players.PlayerAdded:Connect(onPlayerAddedSeat)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAddedSeat, player) end

-- กลับเซิร์ฟเวอร์เดิมได้ไหม (2026-10-10 ผู้เล่นแจ้งครบ AFK แล้วค้างหน้าโหลด)
--   อยู่คนเดียว: ออกปุ๊บเซิร์ฟเวอร์ว่าง Roblox ปิดทิ้ง ปลายทางหายระหว่างโหลด = ค้างหน้าโหลด -> ไปเซิร์ฟเวอร์อื่น/ใหม่แทน
--   กำลังจะรีเซิร์ฟ (RestartNotice ตั้ง RestartEndsAt) = เซิร์ฟเวอร์เดิมกำลังจะปิด ไม่กลับเข้าไป
local function sameServerOk(player)
	if game.PrivateServerId ~= "" or game.JobId == "" then return false end
	local others = 0
	for _, p in ipairs(Players:GetPlayers()) do if p ~= player then others += 1 end end
	if others == 0 then return false end
	local ends = ReplicatedStorage:GetAttribute("RestartEndsAt")
	if type(ends) == "number" and ends > os.time() - 300 then return false end
	return true
end

-- ============ เลือกเครื่องที่คนเยอะสุด (2026-10-20) ============
-- เช้า 10-20 รีสตาร์ท 09:00 แล้วคนแตกเป็น 3 เครื่อง: ช่วงนับถอยหลัง AFK ไป "เซิร์ฟสาธารณะ" Roblox เปิดเครื่องใหม่ให้ทีละคน
-- ตอนนี้ = ดูรายชื่อเครื่องจาก ServerBrowserService (MemoryStore LivePublicServers_v1) เลือกเครื่องเวอร์ชันใหม่สุด
-- ที่ไม่ได้กำลังรีเซิร์ฟ ยังเหลือที่ว่าง และคนเยอะสุด คน AFK จะค่อยๆ รวมไปอยู่เครื่องเดียวกันเอง
-- ใช้เฉพาะตอนกลับเครื่องเดิมไม่ได้ (เดิมไปเซิร์ฟสาธารณะ) · รายชื่ออ่านไม่ได้/ไม่มีเครื่องที่เข้าเกณฑ์ = เซิร์ฟสาธารณะแบบเดิม
local serverMap = game:GetService("MemoryStoreService"):GetSortedMap("LivePublicServers_v1")
local SLOT_MARGIN = 2 -- เว้นที่ว่างไว้ (เพื่อนตามมา/ตัวเลขคนอัปเดตทุก 15 วิ)
local RECORD_FRESH = 40 -- วิ รายการเก่ากว่านี้ = เครื่องอาจปิดไปแล้ว

-- คืน jobId, จำนวนคน ของเครื่องอื่นที่คนเยอะสุด + เวอร์ชันใหม่สุดที่เห็น (nil = ไม่มี/อ่านไม่ได้)
local function pickBusiestServer()
	if game.PrivateServerId ~= "" or game.JobId == "" then return nil end
	local ok, entries = pcall(function()
		return serverMap:GetRangeAsync(Enum.SortDirection.Descending, 100)
	end)
	if not ok or type(entries) ~= "table" then
		warn("[AfkRejoin] read server list failed: " .. tostring(entries))
		return nil
	end
	local now = os.time()
	local newest = game.PlaceVersion
	for _, entry in ipairs(entries) do
		local v = entry.value
		if type(v) == "table" and v.PlaceId == game.PlaceId and (tonumber(v.PlaceVersion) or 0) > newest then
			newest = v.PlaceVersion
		end
	end
	local bestId, bestPlayers
	for _, entry in ipairs(entries) do
		local v = entry.value
		if entry.key ~= game.JobId and type(v) == "table" and v.PlaceId == game.PlaceId
			and tonumber(v.PlaceVersion) == newest and not v.Restarting
			and type(v.Players) == "number" and now - (tonumber(v.UpdatedAt) or 0) <= RECORD_FRESH then
			local maxPlayers = tonumber(v.MaxPlayers) or Players.MaxPlayers
			if v.Players + SLOT_MARGIN <= maxPlayers and (not bestPlayers or v.Players > bestPlayers) then
				bestId, bestPlayers = entry.key, v.Players
			end
		end
	end
	return bestId, bestPlayers, newest
end

-- ============ เฝ้าคนที่ย้ายแล้วไม่กลับเข้ามา (2026-10-24) ============
-- valynlnwza 04:59 ย้ายสำเร็จฝั่งเซิร์ฟเวอร์ (0.9 วิ) แต่เครื่องไม่เคยกลับเข้ามา ~4 ชม. และ log ไม่มีอะไรบอก (เซิร์ฟเวอร์ไม่เห็นการต่อเซิร์ฟที่ล้มเหลว)
-- เซิร์ฟเวอร์เดิมเป็นปลายทาง (same-server) จึงเฝ้าเอง: ครบ 120 วิยังไม่กลับ = "missing", กลับช้ากว่า 15 วิ = "late" (ดู ServerScriptService.AfkRejoinWatch)
-- เก็บ 100 รายการล่าสุดที่ DataStore "AfkRejoinWatch_v1" key "recent" (ทุกเซิร์ฟเขียนรวมกัน) + พิมพ์ [AfkRejoin] WATCH ใน console
-- Studio ไม่เขียน (ตั้ง workspace Attribute DevAfkWatchWrite = true ถ้าจะทดสอบเขียน) · ตัวเฝ้าพัง = ไม่กระทบ AFK rejoin หลัก (ครอบ pcall ทุกจุด)
local watchDataStore = game:GetService("DataStoreService"):GetDataStore("AfkRejoinWatch_v1")
local WATCH_MAX_RECORDS = 100
local function watchServerInfo()
	local info = { job = game.JobId, ver = game.PlaceVersion, players = #Players:GetPlayers() }
	pcall(function() info.memMb = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()) end)
	return info
end
local function watchRecord(rec)
	print(string.format("[AfkRejoin] WATCH %s player=%s(%s) target=%s handoffMs=%s delaySec=%s ping=%s",
		tostring(rec.kind), tostring(rec.name), tostring(rec.userId), tostring(rec.target), tostring(rec.handoffMs), tostring(rec.delaySec), tostring(rec.ping)))
	if RunService:IsStudio() and workspace:GetAttribute("DevAfkWatchWrite") ~= true then return end
	task.spawn(function()
		for attempt = 1, 3 do
			local ok = pcall(function()
				watchDataStore:UpdateAsync("recent", function(old)
					local list = type(old) == "table" and table.clone(old) or {}
					table.insert(list, rec)
					while #list > WATCH_MAX_RECORDS do table.remove(list, 1) end
					return list
				end)
			end)
			if ok then return end
			task.wait(attempt * 3)
		end
		warn("[AfkRejoin] WATCH เขียน DataStore ไม่สำเร็จ")
	end)
end
-- ย้ายไปเซิร์ฟอื่น (busiest-server / สาธารณะ) เซิร์ฟต้นทางอาจปิดทันที (ผู้เล่นอยู่คนเดียว) จึงฝาก "ความคาดหวัง" ไว้ใน MemoryStore SortedMap "AfkRejoinExpect_v1" (key = UserId, อายุ 1 ชม.)
-- เซิร์ฟปลายทางลบเองเมื่อผู้เล่นมาถึง (crossArrived) · ทุกเซิร์ฟไล่ตรวจทุก 30 วิ (sweep) รายการที่เกิน 120 วิไม่มีใครเคลียร์ = missing (claim ได้คนเดียว)
-- MemoryStore ใน Studio แยกจากเกมจริง · ทุกจุดครอบ pcall (ล้ม = ไม่กระทบ AFK rejoin)
local watchMemory = game:GetService("MemoryStoreService"):GetSortedMap("AfkRejoinExpect_v1")
local EXPECT_TTL = 3600
local function expectPut(userId, entry)
	task.spawn(function() pcall(function() watchMemory:SetAsync(tostring(userId), entry, EXPECT_TTL) end) end)
end
local function expectCancel(userId)
	task.spawn(function() pcall(function() watchMemory:RemoveAsync(tostring(userId)) end) end)
end
local function expectResolve(userId) -- อ่านแล้วลบ
	local key = tostring(userId)
	local ok, v = pcall(function() return watchMemory:GetAsync(key) end)
	if not ok or type(v) ~= "table" then return nil end
	pcall(function() watchMemory:RemoveAsync(key) end)
	return v
end
local expectListPauseUntil = 0
local function expectList()
	-- GetRange ล้ม (เช่น InternalError ฝั่ง Roblox) = พักตรวจ 5 นาที ไม่ให้ขึ้น error ใน Output ทุก 30 วิทุกเซิร์ฟ (2026-10-30)
	if os.clock() < expectListPauseUntil then return {} end
	local ok, items = pcall(function() return watchMemory:GetRangeAsync(Enum.SortDirection.Ascending, 50) end)
	if not ok then expectListPauseUntil = os.clock() + 300 end
	return (ok and type(items) == "table") and items or {}
end
local function expectClaim(key) -- คืน true เมื่อเราเป็นคนแรกที่ทำเครื่องหมายรายการนี้
	local mine = false
	local ok = pcall(function()
		watchMemory:UpdateAsync(key, function(old)
			if type(old) == "table" and not old.claimed then
				old.claimed = true
				mine = true
				return old
			end
			return nil
		end, EXPECT_TTL)
	end)
	return ok and mine
end

local afkWatch
do
	local okWatch, WatchModule = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("AfkRejoinWatch", 10))
	end)
	if okWatch and WatchModule then
		afkWatch = WatchModule.new({
			clock = os.clock, wallTime = os.time, delay = task.delay, record = watchRecord, serverInfo = watchServerInfo,
			expect = expectPut, cancel = expectCancel, resolve = expectResolve, list = expectList, claim = expectClaim,
		})
	else
		warn("[AfkRejoin] AfkRejoinWatch โหลดไม่ได้ ไม่เฝ้าคนที่ย้ายแล้วไม่กลับ: " .. tostring(WatchModule))
	end
end
local function watchCall(method, ...)
	if not afkWatch then return end
	local ok, err = pcall(afkWatch[method], afkWatch, ...)
	if not ok then warn("[AfkRejoin] watch " .. method .. " error: " .. tostring(err)) end
end

-- serverId = jobId เครื่องคนเยอะสุด (ไม่ใส่ = เครื่องเดิม/สาธารณะตาม sameServer)
local function teleport(player, sameServer, serverId)
	local options = Instance.new("TeleportOptions")
	if serverId then
		options.ServerInstanceId = serverId
	elseif sameServer and game.PrivateServerId == "" and game.JobId ~= "" then
		options.ServerInstanceId = game.JobId
	end
	local target = serverId and "busiest-server" or (sameServer and game.JobId ~= "" and "same-server" or "public-server")
	player:SetAttribute("AfkRejoinPending", true)
	player:SetAttribute("AfkRejoinTarget", target)
	player:SetAttribute("AfkRejoinAttemptAt", DateTime.now().UnixTimestampMillis)
	-- ของตกแต่งที่วางไว้ (หายตอนออก) ส่งไปด้วย ให้ FurnitureService วางคืนที่เดิม + นั่งต่อ (2026-10-16)
	local furniture = nil
	local snap = game:GetService("ServerStorage"):FindFirstChild("FurnitureSnapshot")
	if snap then
		local okSnap, result = pcall(function() return snap:Invoke(player) end)
		if okSnap and type(result) == "table" then furniture = result end
	end
	options:SetTeleportData({ afkRejoin = true, target = target, fishing = fishingSnap[player] or nil, furniture = furniture })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if ok then
		teleportInFlight[player] = os.clock()
		watchCall("sent", player.UserId, player.Name, target, serverId)
	end
	return ok, err
end

local function reportFailed(player)
	teleportInFlight[player] = nil
	rejoinEvent:FireClient(player, "failed")
end

-- source: "client" = AfkRejoinClient นับครบแล้วขอมา (ทางหลัก) / "backstop" = เซิร์ฟเวอร์สั่งเองจากตาข่ายนิรภัยด้านล่าง
local function handleRejoinRequest(player, source)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < COOLDOWN then return end
	lastRequest[player] = now
	if source == "backstop" then player:SetAttribute("AfkBackstop", true) end
	if RunService:IsStudio() then
		-- Studio ย้ายเซิร์ฟเวอร์ไม่ได้ (ทดสอบจริงต้องเล่นบนเซิร์ฟเวอร์ Roblox)
		print("💤 AfkRejoin: (Studio) " .. player.Name .. " ครบเวลา AFK จะถูกพาเข้าเกมใหม่บนเซิร์ฟเวอร์จริง")
		notify(player, "💤 (Studio) ครบเวลา AFK · บนเซิร์ฟเวอร์จริงจะพาเข้าเกมใหม่ตรงนี้")
		rejoinEvent:FireClient(player, "studio")
		return
	end
	triedAnyServer[player] = nil
	player:SetAttribute("AfkRejoinFailure", nil)
	fishingSnap[player] = takeFishingSnapshot(player)
	local same = sameServerOk(player)
	-- เครื่องเดิมกลับไม่ได้ (อยู่คนเดียว/กำลังรีเซิร์ฟ) = เดิมก็ไปเซิร์ฟสาธารณะอยู่แล้ว → เลือกเครื่องคนเยอะสุดแทน (ไม่ให้ Roblox เปิดเครื่องใหม่ทีละคน)
	-- ช่วงปกติกลับเครื่องเดิมเหมือนเดิม (ผู้ใช้เลือก 2026-10-20: ไม่ให้กระทบของเดิม · เครื่องเดิม LevelSystem รอเซฟตอนออกเสร็จก่อนโหลด ข้ามเครื่องรอไม่ได้)
	local busiestId, busiestPlayers
	if not same then busiestId, busiestPlayers = pickBusiestServer() end
	if busiestId then
		print(string.format("💤 AfkRejoin: พา %s ไปเครื่องคนเยอะสุด %s (%d คน) แทนเซิร์ฟสาธารณะ (อยู่คนเดียว/กำลังรีเซิร์ฟ)",
			player.Name, busiestId:sub(1, 8), busiestPlayers))
		local okBusy, errBusy = teleport(player, false, busiestId)
		print(string.format("[AfkRejoin] attempt player=%s target=busiest-server requestAccepted=%s", player.Name, tostring(okBusy)))
		if okBusy then return end -- ล้มทีหลัง (เต็ม/ปิด) = TeleportInitFailed ด้านล่างลองเซิร์ฟสาธารณะ
		warn("AfkRejoin: เข้าเครื่องคนเยอะสุดไม่ได้ " .. player.Name .. ": " .. tostring(errBusy) .. " -> ทำแบบเดิม")
		player:SetAttribute("AfkRejoinFailure", "busiest-server: " .. tostring(errBusy))
	end
	print("💤 AfkRejoin: พา " .. player.Name .. " เข้าเกมใหม่ (AFK) " .. (same and "เซิร์ฟเวอร์เดิม" or "เซิร์ฟเวอร์อื่น (อยู่คนเดียว/กำลังจะรีเซิร์ฟ)"))
	if not same then triedAnyServer[player] = true end -- ไม่มีเซิร์ฟเวอร์เดิมให้ลอง ล้มทีหลัง = แจ้งเลย
	local ok, err = teleport(player, same)
	print(string.format("[AfkRejoin] attempt player=%s target=%s requestAccepted=%s", player.Name, tostring(player:GetAttribute("AfkRejoinTarget")), tostring(ok)))
	if not ok and not same then
		player:SetAttribute("AfkRejoinFailure", "public-server: " .. tostring(err))
		warn("AfkRejoin: ย้ายเซิร์ฟเวอร์ไม่สำเร็จ " .. player.Name .. ": " .. tostring(err))
		reportFailed(player)
	elseif not ok then
		player:SetAttribute("AfkRejoinFailure", "same-server: " .. tostring(err))
		warn("AfkRejoin: เข้าเซิร์ฟเวอร์เดิมไม่ได้ " .. player.Name .. ": " .. tostring(err))
		triedAnyServer[player] = true
		local ok2, err2 = teleport(player, false)
		print(string.format("[AfkRejoin] fallback player=%s target=%s requestAccepted=%s", player.Name, tostring(player:GetAttribute("AfkRejoinTarget")), tostring(ok2)))
		if not ok2 then
			player:SetAttribute("AfkRejoinFailure", tostring(player:GetAttribute("AfkRejoinFailure") or "") .. " | public-server: " .. tostring(err2))
			warn("AfkRejoin: ย้ายเซิร์ฟเวอร์ไม่สำเร็จ " .. player.Name .. ": " .. tostring(err2))
			reportFailed(player)
		end
	end
end

rejoinEvent.OnServerEvent:Connect(function(player)
	handleRejoinRequest(player, "client")
end)

-- ============ ตาข่ายนิรภัย (2026-10-19) ============
-- AfkRejoinClient ทำงานฝั่งเครื่องผู้เล่นอย่างเดียว ถ้ามันไม่ส่งคำขอมา (นับไม่ถึง/ถูกยกเลิก/สคริปต์ค้าง) ผู้เล่นจะโดน Roblox เตะที่ 20 นาที
-- AfkIdleReporter (ผู้เล่น) ส่งเวลานิ่งมาทุก 10 วิ: นิ่งเกิน BACKSTOP_IDLE (19 นาที = หลังทางหลักที่ 17:50-18:10 และก่อน Roblox เตะ)
-- แล้วยังไม่มีคำขอย้ายใน BACKSTOP_RETRY วิ = เซิร์ฟเวอร์สั่งย้ายเอง ผ่านขั้นตอนเดียวกับทางหลัก (เซฟตกปลา/ของตกแต่ง/TeleportData)
-- ทางหลักทำงานปกติ = ตัวนี้ไม่เคยทำงาน (ย้ายแล้วเซิร์ฟเวอร์ใหม่นับเวลานิ่งใหม่)
-- Studio ปิดไว้ ยกเว้นตั้ง workspace Attribute DevAfkBackstopAfter (วินาที) เพื่อทดสอบ (ใน Studio แค่พิมพ์ข้อความ ไม่ย้ายจริง)
local reportIdle = remoteEvents:FindFirstChild("ReportIdle")
if not reportIdle then
	reportIdle = Instance.new("RemoteEvent")
	reportIdle.Name = "ReportIdle"
	reportIdle.Parent = remoteEvents
end
local BACKSTOP_IDLE = 19 * 60
local BACKSTOP_RETRY = 60
local lastIdleReportAt = {} -- [player] = os.clock()

reportIdle.OnServerEvent:Connect(function(player, idleSeconds)
	if type(idleSeconds) ~= "number" or idleSeconds ~= idleSeconds then return end
	local now = os.clock()
	if lastIdleReportAt[player] and now - lastIdleReportAt[player] < 5 then return end -- กันสแปม
	lastIdleReportAt[player] = now
	idleSeconds = math.clamp(math.floor(idleSeconds), 0, 100000)
	player:SetAttribute("AfkIdleReported", idleSeconds) -- DisconnectLogger เก็บค่านี้ไว้ใน log ตอนออก

	local testAfter = tonumber(workspace:GetAttribute("DevAfkBackstopAfter"))
	if RunService:IsStudio() and not testAfter then return end
	if idleSeconds < (testAfter or BACKSTOP_IDLE) then return end
	if lastRequest[player] and now - lastRequest[player] < BACKSTOP_RETRY then return end
	if teleportInFlight[player] and now - teleportInFlight[player] < IN_FLIGHT_GRACE then return end

	print(string.format("[AfkRejoin] backstop: %s idle %d s and no rejoin request yet -> server starts the rejoin", player.Name, idleSeconds))
	handleRejoinRequest(player, "backstop")
end)

Players.PlayerRemoving:Connect(function(player)
	lastIdleReportAt[player] = nil
end)

-- เริ่มย้ายแล้วล้มทีหลัง (เช่นเซิร์ฟเวอร์เดิมเต็ม) = ลองเซิร์ฟเวอร์อื่นอีกครั้ง
TeleportService.TeleportInitFailed:Connect(function(player, result, message)
	if not lastRequest[player] or os.clock() - lastRequest[player] > COOLDOWN then return end
	if result == Enum.TeleportResult.IsTeleporting then
		warn("[AfkRejoin] TeleportInitFailed IsTeleporting player=" .. player.Name .. " = teleport ก่อนหน้ายังทำงานอยู่ ไม่ลองซ้ำ")
		return
	end
	local failedTarget = player:GetAttribute("AfkRejoinTarget") or "unknown"
	local failure = tostring(failedTarget) .. ": " .. tostring(result) .. " - " .. tostring(message)
	player:SetAttribute("AfkRejoinFailure", tostring(player:GetAttribute("AfkRejoinFailure") or "") .. " | " .. failure)
	warn("[AfkRejoin] TeleportInitFailed player=" .. player.Name .. " target=" .. tostring(failedTarget) .. " result=" .. tostring(result) .. " message=" .. tostring(message))
	if triedAnyServer[player] then
		reportFailed(player)
		return
	end
	triedAnyServer[player] = true
	player:SetAttribute("AfkRejoinTarget", "public-server")
	task.wait(1)
	local ok, err = teleport(player, false)
	print(string.format("[AfkRejoin] fallback-after-init-failure player=%s target=%s requestAccepted=%s", player.Name, tostring(player:GetAttribute("AfkRejoinTarget")), tostring(ok)))
	if not ok then
		player:SetAttribute("AfkRejoinFailure", tostring(player:GetAttribute("AfkRejoinFailure") or "") .. " | public-server: " .. tostring(err))
		reportFailed(player)
	end
end)

-- ============ รีเซิร์ฟเวอร์ตอนกำลังตกปลา = เข้ามาใหม่แล้วตกต่อ (ผู้เล่นขอ 2026-10-03) ============
-- เซิร์ฟเวอร์ปิด (Publish/รีสตาร์ท) TeleportData ใช้ไม่ได้ จึงเซฟสถานะตกปลาลง DataStore ตอน BindToClose
-- เข้ามาใหม่ภายใน RESUME_WINDOW = ตั้ง Attribute ResumeRodId/ResumeAuto/ResumeBait ให้ AfkRejoinClient ทำ resumeFishing แบบเดียวกับกลับจาก AFK
-- (ตำแหน่งเดิม LastPosition เซฟตอน BindToClose อยู่แล้ว) อ่านแล้วลบทิ้ง เข้ารอบหน้าตามปกติจะไม่ตกปลาเอง
-- Studio: กดหยุด Play ก็เรียก BindToClose เหมือนกัน จึงทำเฉพาะตอนตั้ง workspace Attribute "DevFishingResumeTest" = true
local DataStoreService = game:GetService("DataStoreService")
local resumeStore = DataStoreService:GetDataStore("FishingResume_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local RESUME_WINDOW = 600 -- วินาที เข้ามาใหม่ช้ากว่านี้ = ไม่ตกต่อให้
-- 2026-10-17 ย้ายเซิร์ฟตอน AFK ล้มฝั่งเครื่องผู้เล่น (error 279 เน็ตสะดุด) TeleportData ไม่ได้ไปด้วย ผู้เล่นกดเข้าเกมเองทีหลังหลายนาที (CtrlZ_2 12.6 นาที)
-- = เซฟสถานะตกปลาตอนออกด้วย (ติดป้าย afk) ให้เวลากลับมานานกว่า · ย้ายสำเร็จ (มี TeleportData afkRejoin) = ลบทิ้ง ไม่ตกต่อ 2 ทาง
local AFK_FAIL_WINDOW = 1800
local function resumeEnabled()
	return not RunService:IsStudio() or workspace:GetAttribute("DevFishingResumeTest") == true
end

local fishingCache = {} -- [player] = สถานะล่าสุด (เก็บทุก 5 วิ เผื่อตอนปิดเซิร์ฟเวอร์ตัวละครถูกลบไปแล้ว)
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			fishingCache[player] = takeFishingSnapshot(player)
		end
		task.wait(5)
	end
end)

-- อัปเดตทันทีตอนถือ/เก็บเบ็ด หรือเปิดปิดออโต้/เปลี่ยนเหยื่อ (ตอน PlayerRemoving ตัวละครอาจถูกลบไปแล้ว ต้องใช้ค่านี้)
local function hookFishingCache(player)
	local function refresh() if player.Parent then fishingCache[player] = takeFishingSnapshot(player) end end
	local function hookCharacter(character)
		character.ChildAdded:Connect(function(c) if c:IsA("Tool") then refresh() end end)
		character.ChildRemoved:Connect(function(c) if c:IsA("Tool") and character.Parent then refresh() end end)
		refresh()
	end
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then hookCharacter(player.Character) end
	player:GetAttributeChangedSignal("FishingAuto"):Connect(refresh)
	player:GetAttributeChangedSignal("FishingBait"):Connect(refresh)
end
Players.PlayerAdded:Connect(hookFishingCache)
for _, player in ipairs(Players:GetPlayers()) do hookFishingCache(player) end

local function onPlayerAddedResume(player)
	if not resumeEnabled() then return end
	local key = tostring(player.UserId)
	local joinedAt = os.time()
	local okJoin, joinData = pcall(function() return player:GetJoinData() end)
	local td = okJoin and type(joinData) == "table" and joinData.TeleportData
	if type(td) == "table" and td.afkRejoin then
		-- ย้ายเซิร์ฟจาก AFK สำเร็จ: ตกต่อด้วย TeleportData (AfkRejoinClient) เรคอร์ดสำรองที่เซิร์ฟเก่าเซฟไว้ไม่ใช้ ลบทิ้ง
		-- ลบซ้ำอีกทีหลัง 30 วิ เพราะย้ายไปเซิร์ฟอื่น เซิร์ฟเก่าอาจเขียนทีหลังเราอ่าน (ลบเฉพาะเรคอร์ด afk ที่เก่ากว่าตอนเข้า)
		-- 2026-10-20 StandardReadGameServerThrottled (FishingResume_v1): เดิมอ่านซ้ำทันทีหลัง Load (อ่าน 3 ครั้ง/คน ตอนเข้าเกม)
		--   = ใช้ผลจาก Load เลย + รอโควต้า (Defer) ก่อนอ่าน งานนี้ไม่เร่งด่วน
		local function dropAfkRecord(data)
			if type(data) == "table" and data.afk and type(data.t) == "number" and data.t <= joinedAt then
				pcall(function() resumeStore:RemoveAsync(key) end)
			end
		end
		task.spawn(function()
			if not DataLoadRetry.Defer(player, "AfkRejoin(resume)") then return end
			local okLoad, data = DataLoadRetry.Load(player, "AfkRejoin(resume)", DataLoadRetry.Get(resumeStore, key)) -- รอเซฟตอนออกของเซิร์ฟเดิมให้เสร็จก่อน
			if okLoad then dropAfkRecord(data) end
			task.wait(30)
			if not DataLoadRetry.Defer(player, "AfkRejoin(resume)") then return end
			local ok, data2 = pcall(function() return resumeStore:GetAsync(key) end)
			if ok then dropAfkRecord(data2) end
		end)
		return
	end
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = หลังรีเซิร์ฟคนเข้าพร้อมกัน โหลดไม่ทัน ไม่กลับมาตกปลา) 2026-10-09
	-- 2026-10-20 หลีกทางให้เหรียญ/กระเป๋า/เลเวลโหลดก่อน (รอ 2-6 วิ + รอโควต้าอ่าน) กัน StandardReadGameServerThrottled ตอนคนเข้าพร้อมกัน
	if not DataLoadRetry.Defer(player, "AfkRejoin(resume)") then return end
	local okLoad, data = DataLoadRetry.Load(player, "AfkRejoin(resume)", DataLoadRetry.Get(resumeStore, key))
	if not okLoad or type(data) ~= "table" then return end
	pcall(function() resumeStore:RemoveAsync(key) end) -- ใช้ครั้งเดียว
	local window = data.afk and AFK_FAIL_WINDOW or RESUME_WINDOW
	if type(data.t) ~= "number" or os.time() - data.t > window then return end
	if type(data.rodId) ~= "string" or not player.Parent then return end
	player:SetAttribute("ResumeAuto", data.auto == true)
	player:SetAttribute("ResumeBait", type(data.bait) == "number" and data.bait or nil)
	if type(data.cast) == "table" and tonumber(data.cast.x) and tonumber(data.cast.y) and tonumber(data.cast.z) then
		player:SetAttribute("ResumeCast", Vector3.new(data.cast.x, data.cast.y, data.cast.z))
	end
	player:SetAttribute("ResumeRodId", data.rodId) -- ตั้งสุดท้าย: ฝั่งผู้เล่นฟังตัวนี้
	if data.seat then resitLater(player, data.seat) -- นั่งเก้าอี้ตกปลาอยู่ตอนรีเซิร์ฟ = นั่งที่เดิม
	elseif data.mount then rideLater(player, data.mount) end -- ขี่สัตว์ตกปลาอยู่ = ขี่ตัวเดิม (2026-10-20)
	print("🎣 AfkRejoin: " .. (data.afk and "ย้ายเซิร์ฟตอน AFK ไม่สำเร็จ แต่ " or "รีเซิร์ฟเวอร์ตอน ") .. player.Name .. " ตกปลาอยู่ = ให้ตกต่อ (" .. data.rodId .. (data.auto and ", ออโต้" or "") .. ")")
end
Players.PlayerAdded:Connect(onPlayerAddedResume)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAddedResume, player) end

-- เซฟตอนผู้เล่นออก (ตอนปิดเซิร์ฟเวอร์ผู้เล่นถูกเอาออกก่อน BindToClose จะหาตัวไม่เจอ) BindToClose แค่รอให้เซฟเสร็จ
-- ผลพลอยได้: ออกเกมเองตอนตกปลา แล้วกลับมาภายใน RESUME_WINDOW ก็ตกต่อให้เหมือนกัน (เหมือน LastPosition ที่พากลับที่เดิม)
local pendingSaves = 0
local savedOnLeave = {} -- [userId] = true
local preSaved = {} -- [userId] = { key, clock } เซฟล่วงหน้าก่อนรีเซิร์ฟ (RestartNotice) ตอนออกถ้าสถานะเดิม = ไม่เขียนซ้ำ
local PRESAVE_FRESH = 180 -- วิ ค่าที่เซฟล่วงหน้ายังใช้แทนได้นานเท่าไร
local function snapKey(snap) return tostring(snap.rodId) .. "|" .. tostring(snap.auto) .. "|" .. tostring(snap.bait) end
local function saveResume(player, isPreSave)
	if not resumeEnabled() or savedOnLeave[player.UserId] then return end
	-- กำลังถูกพาย้ายเพราะ AFK = สถานะหลักไปทาง TeleportData แต่เซฟสำรองไว้ด้วย (ติดป้าย afk) เผื่อเครื่องผู้เล่นต่อเซิร์ฟไม่ติด (279) แล้วเข้าเกมเองทีหลัง
	-- ย้ายสำเร็จ onPlayerAddedResume ลบเรคอร์ดนี้ทิ้ง (ไม่ตกต่อ 2 ทาง)
	local afkLeave = not isPreSave and lastRequest[player] ~= nil and os.clock() - lastRequest[player] < 60
	local snap = afkLeave and fishingSnap[player] or takeFishingSnapshot(player)
	if snap == false and not (player.Character and player.Character.Parent) then snap = fishingCache[player] end -- ตัวละครหายแล้ว ใช้ค่าล่าสุดที่เก็บไว้
	if not (snap and snap.rodId) then return end
	local key = snapKey(snap)
	if isPreSave then
		preSaved[player.UserId] = { key = key, clock = os.clock() }
	else
		local pre = preSaved[player.UserId]
		if pre and pre.key == key and os.clock() - pre.clock < PRESAVE_FRESH then return end -- เซฟล่วงหน้าไว้แล้ว
		savedOnLeave[player.UserId] = true
	end
	pendingSaves += 1
	local userId = player.UserId
	-- หลุดแล้ว Roblox เชื่อมต่อใหม่เข้าเซิร์ฟเดิมในวินาทีเดียว (yumenotsuzuki 07:47): รอบใหม่ต้องรอเซฟนี้เสร็จก่อนอ่าน ไม่งั้นไม่ได้ตกปลาต่อ (2026-10-10)
	local markLeave = not isPreSave
	if markLeave then DataLoadRetry.BeginLeaveSave(userId) end
	task.spawn(function()
		-- ลองซ้ำ (ตอนปิดเซิร์ฟทุกระบบเซฟพร้อมกันจนโดนจำกัดการเขียน เดิมเซฟครั้งเดียว = หลายคนไม่ได้ตกต่อ) 2026-10-09
		local ok, err
		for attempt = 1, 4 do
			ok, err = pcall(function()
				resumeStore:SetAsync(tostring(userId), { rodId = snap.rodId, auto = snap.auto, bait = snap.bait, seat = snap.seat, cast = snap.cast, mount = snap.mount, afk = afkLeave or nil, t = os.time() }, { userId })
			end)
			if ok then break end
			if attempt < 4 then task.wait(attempt * 2 + math.random() * 2) end
		end
		if not ok then warn("AfkRejoin: เซฟสถานะตกปลาไม่สำเร็จ: " .. tostring(err)) end
		pendingSaves -= 1
		if markLeave then DataLoadRetry.EndLeaveSave(userId) end
	end)
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do saveResume(player) end
	local t0 = os.clock()
	while pendingSaves > 0 and os.clock() - t0 < 25 do task.wait(0.1) end -- เดิม 8 วิ (ลองซ้ำต้องใช้เวลามากขึ้น)
end)

-- เซฟล่วงหน้าก่อนรีเซิร์ฟ (ServerScriptService.RestartNotice ยิงทีละคน) 2026-10-09
task.spawn(function()
	local ev = game:GetService("ServerScriptService"):WaitForChild("PreRestartSave", 60)
	if ev then ev.Event:Connect(function(player) saveResume(player, true) end) end
end)

Players.PlayerRemoving:Connect(function(player)
	saveResume(player)
	lastRequest[player] = nil
	triedAnyServer[player] = nil
	teleportInFlight[player] = nil
	fishingSnap[player] = nil
	fishingCache[player] = nil
	lastCast[player] = nil
	task.delay(30, function() savedOnLeave[player.UserId] = nil preSaved[player.UserId] = nil end)
end)

-- เฝ้าคนที่ย้ายแล้วไม่กลับเข้ามา (AfkRejoinWatch): ออก = เริ่มจับเวลา, เข้ามา = หยุด / จดว่าช้า
Players.PlayerRemoving:Connect(function(player)
	local okPing, pingS = pcall(function() return player:GetNetworkPing() end)
	watchCall("left", player.UserId, okPing and type(pingS) == "number" and math.floor(pingS * 1000 + 0.5) or nil, player:GetAttribute("AfkIdleReported"))
end)
Players.PlayerAdded:Connect(function(player)
	watchCall("arrived", player.UserId)
	-- เข้ามาด้วย AFK rejoin ข้ามเซิร์ฟ (target ไม่ใช่ same-server) = เคลียร์ความคาดหวังที่เซิร์ฟต้นทางฝากไว้
	local okJoin, joinData = pcall(function() return player:GetJoinData() end)
	local td = okJoin and type(joinData) == "table" and joinData.TeleportData
	if type(td) == "table" and td.afkRejoin and td.target ~= "same-server" then
		task.spawn(watchCall, "crossArrived", player.UserId)
	end
end)

-- ทุกเซิร์ฟไล่ตรวจความคาดหวังที่ค้างเกินเวลา (Studio ไม่ทำ)
if not RunService:IsStudio() then
	task.spawn(function()
		task.wait(30)
		while true do
			watchCall("sweep")
			task.wait(30)
		end
	end)
end
