-- BACKUP of ServerScriptService.DisconnectLogger taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ServerScriptService.DisconnectLogger, select all, paste everything BELOW the next line.
-- ===== original Source (16950 bytes, hash 2023745059) =====
-- Records a short per-player history of joins and exits for disconnect diagnosis.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))

local LOG_STORE = DataStoreService:GetDataStore("DisconnectLogs_v1")
local MAX_SESSIONS_PER_PLAYER = 12
local sessions = {}

-- log เก็บไว้ 7 วัน: ทุกครั้งที่เขียน log ของผู้เล่นจะทิ้ง entry ที่เก่ากว่านี้ + กวาดทุก key สัปดาห์ละครั้ง (ท้ายสคริปต์) (2026-10-19)
local RETENTION_MS = 7 * 24 * 3600 * 1000
local function isStale(entry, cutoff)
	return type(entry) ~= "table" or (entry.joinedAt or 0) < cutoff
end

-- สุขภาพฝั่งผู้เล่นก่อนหลุด (2026-10-19): HealthReporter (LocalScript) ส่ง FPS/ความหน่วงเฟรม/หน่วยความจำมาทุก 5 วิ,
-- เซิร์ฟเวอร์วัด ping เองทุก 5 วิ เก็บแค่ 12 ค่าล่าสุด (~1 นาที) แล้วสรุปลง entry.health ตอนผู้เล่นออก (ไม่เพิ่มการเขียน DataStore)
-- lastReportAgoS สูง = เครื่องผู้เล่นไม่ส่งข้อมูลมานานก่อนหลุด (เครื่องค้าง / เน็ตขาด)
local HEALTH_WINDOW = 12
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local reportHealth = remoteEvents:FindFirstChild("ReportHealth")
if not reportHealth then
	reportHealth = Instance.new("RemoteEvent")
	reportHealth.Name = "ReportHealth"
	reportHealth.Parent = remoteEvents
end

local healthData = {} -- [player] = {client = {...}, pings = {...}, lastClientAt}
local function healthOf(player)
	local h = healthData[player]
	if not h then
		h = { client = {}, pings = {} }
		healthData[player] = h
	end
	return h
end
local function pushCapped(list, value)
	table.insert(list, value)
	if #list > HEALTH_WINDOW then table.remove(list, 1) end
end

-- 2026-10-24 ค่าการวาดภาพ (ตัวที่ 4 จาก HealthReporter): tris/draws/cpu/gpu + ระดับกราฟิก (lvl) อุปกรณ์ (dev) ระดับ Roblox (rq)
-- สรุปลง entry.health ตอนออก + shared.ClientPerfSummary() ให้ ServerHealthLogger จดทุก 5 นาที (แยกตาม อุปกรณ์/ระดับ)
local VALID_LEVELS = { high = true, mid = true, low = true, lowest = true }
local VALID_DEVICES = { mobile = true, pc = true, console = true }
local function num(v, maxV)
	if type(v) ~= "number" or v ~= v then return nil end
	return math.clamp(v, 0, maxV)
end
local function cleanRender(r)
	if type(r) ~= "table" then return nil end
	return {
		tris = num(r.tris, 1e8),
		draws = num(r.draws, 1e6),
		cpu = num(r.cpu, 10000),
		gpu = num(r.gpu, 10000),
		lvl = VALID_LEVELS[r.lvl] and r.lvl or nil,
		dev = VALID_DEVICES[r.dev] and r.dev or nil,
		rq = num(r.rq, 21),
	}
end

reportHealth.OnServerEvent:Connect(function(player, fps, worstMs, memMb, renderInfo)
	if type(fps) ~= "number" or type(worstMs) ~= "number" or type(memMb) ~= "number" then return end
	local h = healthOf(player)
	local now = os.clock()
	if h.lastClientAt and now - h.lastClientAt < 2 then return end -- กันสแปม
	h.lastClientAt = now
	local r = cleanRender(renderInfo)
	pushCapped(h.client, {
		fps = math.clamp(fps, 0, 1000),
		worst = math.clamp(worstMs, 0, 600000),
		mem = math.clamp(memMb, 0, 100000),
		r = r,
	})
	if r then
		h.lvl, h.dev, h.rq = r.lvl, r.dev, r.rq
	end
end)

-- ค่าเฉลี่ยของช่วงที่เก็บไว้ (~1 นาที) ต่อผู้เล่นหนึ่งคน
local function renderAverages(h)
	local s = { n = 0, fps = 0, tris = 0, draws = 0, cpu = 0, gpu = 0 }
	for _, rec in ipairs(h.client) do
		if rec.r and rec.r.tris then
			s.n += 1
			s.fps += rec.fps
			s.tris += rec.r.tris
			s.draws += rec.r.draws or 0
			s.cpu += rec.r.cpu or 0
			s.gpu += rec.r.gpu or 0
		end
	end
	if s.n == 0 then return nil end
	return {
		fps = s.fps / s.n, tris = s.tris / s.n, draws = s.draws / s.n,
		cpu = s.cpu / s.n, gpu = s.gpu / s.n,
	}
end

-- สรุปทั้งเซิร์ฟ: { ["mobile/lowest"] = { n, fps, tris(k), draws, cpu, gpu }, ... }
shared.ClientPerfSummary = function()
	local groups = {}
	for player, h in pairs(healthData) do
		if player.Parent then
			local avg = renderAverages(h)
			if avg then
				local key = (h.dev or "?") .. "/" .. (h.lvl or "?")
				local g = groups[key]
				if not g then
					g = { n = 0, fps = 0, tris = 0, draws = 0, cpu = 0, gpu = 0 }
					groups[key] = g
				end
				g.n += 1
				g.fps += avg.fps
				g.tris += avg.tris
				g.draws += avg.draws
				g.cpu += avg.cpu
				g.gpu += avg.gpu
			end
		end
	end
	local function r1(v) return math.floor(v * 10 + 0.5) / 10 end
	for _, g in pairs(groups) do
		g.fps = r1(g.fps / g.n)
		g.tris = r1(g.tris / g.n / 1000) -- พันสามเหลี่ยม
		g.draws = math.floor(g.draws / g.n + 0.5)
		g.cpu = r1(g.cpu / g.n)
		g.gpu = r1(g.gpu / g.n)
	end
	return groups
end

task.spawn(function()
	while true do
		task.wait(5)
		for _, player in ipairs(Players:GetPlayers()) do
			local ok, ping = pcall(function() return player:GetNetworkPing() end)
			if ok and type(ping) == "number" then
				pushCapped(healthOf(player).pings, math.floor(ping * 1000 + 0.5))
			end
		end
	end
end)

local function summarizeHealth(player)
	local h = healthData[player]
	healthData[player] = nil
	if not h then return nil end
	local s = {}
	if #h.client > 0 then
		local sum, minFps, worst = 0, math.huge, 0
		for _, r in ipairs(h.client) do
			sum += r.fps
			minFps = math.min(minFps, r.fps)
			worst = math.max(worst, r.worst)
		end
		s.reports = #h.client
		s.fpsAvg = math.floor(sum / #h.client + 0.5)
		s.fpsMin = minFps
		s.worstFrameMs = worst
		s.clientMemMb = h.client[#h.client].mem
		local avg = renderAverages(h)
		if avg then
			s.trisK = math.floor(avg.tris / 100 + 0.5) / 10
			s.draws = math.floor(avg.draws + 0.5)
			s.cpuMs = math.floor(avg.cpu * 10 + 0.5) / 10
			s.gpuMs = math.floor(avg.gpu * 10 + 0.5) / 10
		end
		s.gfx = h.lvl
		s.device = h.dev
		s.robloxQ = h.rq
		s.lastReportAgoS = math.floor(os.clock() - h.lastClientAt + 0.5)
	else
		s.noClientReports = true
	end
	if #h.pings > 0 then
		local sum, peak = 0, 0
		for _, p in ipairs(h.pings) do
			sum += p
			peak = math.max(peak, p)
		end
		s.pingAvgMs = math.floor(sum / #h.pings + 0.5)
		s.pingMaxMs = peak
	end
	-- เหตุการณ์การ์ดแจ้งเตือนเครื่องหน่วง / ลดกราฟิกอัตโนมัติ จาก ServerScriptService.SlowHintReport (2026-10-25)
	local hint = player:GetAttribute("SlowHintLog")
	if type(hint) == "string" and hint ~= "" then s.hint = hint end
	return s
end

local function nowMs()
	return DateTime.now().UnixTimestampMillis
end

-- Roblox queues a second write to the same key within ~6 s ("DataStore request was added to queue").
-- An AFK rejoin leaves and re-enters this server in the same second, so the leave write and the next
-- join write collided on every rejoin. Space writes per user instead (2026-10-13).
local WRITE_GAP = 7
local lastWriteAt = {} -- [userId] = os.clock() of the latest write to that key from this server

local function updatePlayerLog(userId, mutate, action)
	local last = lastWriteAt[userId]
	if last then
		local remaining = WRITE_GAP - (os.clock() - last)
		if remaining > 0 then task.wait(remaining) end
	end
	local stamp = os.clock()
	lastWriteAt[userId] = stamp
	task.delay(WRITE_GAP * 2, function()
		if lastWriteAt[userId] == stamp then lastWriteAt[userId] = nil end
	end)
	local ok, err = pcall(function()
		LOG_STORE:UpdateAsync("u" .. tostring(userId), function(old)
			local logs = type(old) == "table" and table.clone(old) or {}
			mutate(logs)
			local cutoff = nowMs() - RETENTION_MS
			for i = #logs, 1, -1 do
				if isStale(logs[i], cutoff) then table.remove(logs, i) end
			end
			while #logs > MAX_SESSIONS_PER_PLAYER do
				table.remove(logs, 1)
			end
			return logs
		end)
	end)
	stamp = os.clock() -- count the gap from when the write finished
	lastWriteAt[userId] = stamp

	if not ok then
		warn(string.format("[DisconnectLogger] %s log failed for userId %d: %s", action, userId, tostring(err)))
	end
	return ok
end

local function startSession(player)
	if sessions[player] then return end

	local startedAt = nowMs()
	local sessionId = string.format("%s:%d:%d", game.JobId, startedAt, player.UserId)
	local joinData = {}
	pcall(function() joinData = player:GetJoinData() end)
	local teleportData = type(joinData) == "table" and type(joinData.TeleportData) == "table" and joinData.TeleportData or nil
	local session = {
		id = sessionId,
		startedAt = startedAt,
		jobId = game.JobId,
		placeId = game.PlaceId,
		afkRejoinArrival = teleportData and teleportData.afkRejoin == true or false,
		afkRejoinTarget = teleportData and teleportData.target or nil,
	}
	sessions[player] = session

	task.spawn(function()
		-- Low priority at join: let coins/level/inventory use the DataStore budget first (2026-10-13).
		-- If the player leaves meanwhile, finishSession writes the whole record itself.
		if not DataLoadRetry.Defer(player, "DisconnectLogger") then return end
		local saved = updatePlayerLog(player.UserId, function(logs)
			for _, entry in ipairs(logs) do
				if entry.sessionId == sessionId then return end
			end
			table.insert(logs, {
				sessionId = sessionId,
				status = session.closedAt and "left" or "active",
				joinedAt = startedAt,
				leftAt = session.closedAt,
				sessionSeconds = session.closedAt and math.max(0, math.floor((session.closedAt - startedAt) / 1000)) or nil,
				exitReason = session.exitReason,
				health = session.healthSummary,
				pingMs = session.pingMs,
				placeId = session.placeId,
				jobId = session.jobId,
				afkRejoinArrival = session.afkRejoinArrival,
				afkRejoinTarget = session.afkRejoinTarget,
				afkRejoinAttempted = session.afkRejoinAttempted,
				afkRejoinTargetRequested = session.afkRejoinTargetRequested,
				afkRejoinAttemptAt = session.afkRejoinAttemptAt,
				afkRejoinFailure = session.afkRejoinFailure,
			})
		end, "join")

		if saved then
			print(string.format("[DisconnectLogger] %s (%d) joined; session %s", player.Name, player.UserId, sessionId))
			if session.afkRejoinArrival then
				print(string.format("[AfkRejoin] arrival confirmed player=%s target=%s jobId=%s", player.Name, tostring(session.afkRejoinTarget), tostring(session.jobId)))
			end
		end
	end)
end

local function finishSession(player, exitReason)
	local session = sessions[player]
	if not session then
		startSession(player)
		session = sessions[player]
	end
	sessions[player] = nil

	local leftAt = nowMs()
	local pingMs
	local pingOk, pingSeconds = pcall(function()
		return player:GetNetworkPing()
	end)
	if pingOk and type(pingSeconds) == "number" then
		pingMs = math.floor(pingSeconds * 1000 + 0.5)
	end

	local reason = tostring(exitReason or "Unknown")
	local afkRejoinPending = player:GetAttribute("AfkRejoinPending") == true
	local afkRejoinTarget = player:GetAttribute("AfkRejoinTarget")
	local afkRejoinFailure = player:GetAttribute("AfkRejoinFailure")
	local afkRejoinAttemptAt = player:GetAttribute("AfkRejoinAttemptAt")
	session.closedAt = leftAt
	session.exitReason = reason
	session.pingMs = pingMs
	session.afkRejoinAttempted = afkRejoinPending
	session.afkRejoinTargetRequested = afkRejoinTarget
	session.afkRejoinFailure = afkRejoinFailure
	session.afkRejoinAttemptAt = afkRejoinAttemptAt
	local health = summarizeHealth(player)
	-- เวลานิ่งล่าสุดที่ผู้เล่นรายงาน (AfkIdleReporter) + ถูก AfkRejoin ตาข่ายนิรภัยสั่งย้ายหรือไม่ (2026-10-19)
	local idleReported = player:GetAttribute("AfkIdleReported")
	if type(idleReported) == "number" then
		health = health or {}
		health.idleS = idleReported
		health.afkBackstop = player:GetAttribute("AfkBackstop") == true or nil
	end
	-- สถานะไมค์ของผู้เล่นใหม่ (VoiceCheckReport) (2026-10-27)
	local voiceLog = player:GetAttribute("VoiceCheckLog")
	if type(voiceLog) == "string" and voiceLog ~= "" then
		health = health or {}
		health.voice = voiceLog
	end
	session.healthSummary = health
	local saved = updatePlayerLog(player.UserId, function(logs)
		for i = #logs, 1, -1 do
			local entry = logs[i]
			if entry.sessionId == session.id then
				entry.status = "left"
				entry.leftAt = leftAt
				entry.sessionSeconds = math.max(0, math.floor((leftAt - session.startedAt) / 1000))
				entry.exitReason = reason
				entry.pingMs = pingMs
				entry.health = health
				if afkRejoinPending then
					entry.afkRejoinAttempted = true
					entry.afkRejoinTarget = afkRejoinTarget
					entry.afkRejoinAttemptAt = afkRejoinAttemptAt
					entry.afkRejoinFailure = afkRejoinFailure
				end
				return
			end
		end

		-- Covers a fast disconnect before the asynchronous join record finishes.
		table.insert(logs, {
			sessionId = session.id,
			status = "left",
			joinedAt = session.startedAt,
			leftAt = leftAt,
			sessionSeconds = math.max(0, math.floor((leftAt - session.startedAt) / 1000)),
			exitReason = reason,
			pingMs = pingMs,
			placeId = session.placeId,
			jobId = session.jobId,
			afkRejoinArrival = session.afkRejoinArrival,
			afkRejoinTarget = session.afkRejoinTarget,
			afkRejoinAttempted = afkRejoinPending,
			health = health,
			afkRejoinTargetRequested = afkRejoinTarget,
			afkRejoinAttemptAt = afkRejoinAttemptAt,
			afkRejoinFailure = afkRejoinFailure,
		})
	end, "leave")

	print(string.format(
		"[DisconnectLogger] %s (%d) left; reason=%s pingMs=%s durationSec=%d saved=%s",
		player.Name,
		player.UserId,
		reason,
		pingMs and tostring(pingMs) or "unavailable",
		math.max(0, math.floor((leftAt - session.startedAt) / 1000)),
		tostring(saved)
	))
end

Players.PlayerAdded:Connect(startSession)
Players.PlayerRemoving:Connect(finishSession)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(startSession, player)
end

-- กวาด log เก่ากว่า 7 วันของทุกคน สัปดาห์ละครั้ง (เซิร์ฟเวอร์แรกที่เห็นว่าครบกำหนดเป็นคนทำ; ช้าๆ 1 key / 3 วิ ไม่แย่ง budget)
-- ข้ามใน Studio เพื่อไม่ไปยุ่งกับ DataStore ของเกมจริง
if not RunService:IsStudio() then
	task.spawn(function()
		task.wait(600)
		local stampStore = DataStoreService:GetDataStore("DisconnectLogsCleanup_v1")
		local claimed = false
		local ok = pcall(function()
			stampStore:UpdateAsync("lastSweep", function(old)
				if type(old) == "number" and nowMs() - old < RETENTION_MS then return nil end
				claimed = true
				return nowMs()
			end)
		end)
		if not ok or not claimed then return end

		local removed, trimmed = 0, 0
		local okList, pages = pcall(function() return LOG_STORE:ListKeysAsync("u", 100) end)
		if not okList then return end
		while true do
			for _, key in ipairs(pages:GetCurrentPage()) do
				local userId = tonumber(string.sub(key.KeyName, 2))
				if not (userId and Players:GetPlayerByUserId(userId)) then
					local cutoff = nowMs() - RETENTION_MS
					local okGet, logs = pcall(function() return LOG_STORE:GetAsync(key.KeyName) end)
					if okGet and type(logs) == "table" then
						local anyStale, allStale = false, true
						for _, e in ipairs(logs) do
							if isStale(e, cutoff) then anyStale = true else allStale = false end
						end
						if allStale then
							if pcall(function() LOG_STORE:RemoveAsync(key.KeyName) end) then removed += 1 end
						elseif anyStale then
							pcall(function()
								LOG_STORE:UpdateAsync(key.KeyName, function(old)
									if type(old) ~= "table" then return nil end
									local keep = {}
									for _, e in ipairs(old) do
										if not isStale(e, cutoff) then table.insert(keep, e) end
									end
									return keep
								end)
							end)
							trimmed += 1
						end
					end
					task.wait(3)
				end
			end
			if pages.IsFinished then break end
			if not pcall(function() pages:AdvanceToNextPageAsync() end) then break end
		end
		print(string.format("[DisconnectLogger] weekly sweep done: %d keys removed, %d trimmed", removed, trimmed))
	end)
end
