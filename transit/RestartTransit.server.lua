-- RestartTransit: ที่พักทางตอนรีสตาร์ทเซิร์ฟเวอร์อัตโนมัติ (สร้าง 2026-10-14)
-- วางเป็น Script ใน ServerScriptService ของ Place ที่ 2 (Place พักทาง) เท่านั้น ห้ามใส่ในเกมหลัก
-- รับผู้เล่นที่เกมหลักส่งมา (AutoRestart) รอสั้น ๆ ให้เซิร์ฟเวอร์เก่าปิด แล้วส่งกลับเกมหลัก = ได้เซิร์ฟเวอร์ใหม่
-- Place นี้ไม่โหลด/ไม่เซฟข้อมูลผู้เล่นใด ๆ

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local MAIN_PLACE_ID = 75556752635760 -- เกมหลัก (พักผ่อนหย่อนฟาร์ม)
local WAIT_BEFORE_RETURN = 6 -- วิ ให้เซิร์ฟเวอร์เก่าว่างและปิดก่อน จะได้ไม่ถูกส่งกลับเข้าตัวเดิม
local BATCH = 25
local KICK_TEXT = "🔄 ย้ายเซิร์ฟเวอร์ไม่สำเร็จ กดเข้าเกมอีกครั้งได้เลย ข้อมูลเซฟไว้แล้ว / Couldn't move you to a new server, please rejoin. Your data is saved."

local waiting = {} -- { player, arrivedAt, hops }
local tries = {} -- [player] = จำนวนครั้งที่ลองส่งกลับ

local function hopsOf(player)
	local ok, joinData = pcall(function() return player:GetJoinData() end)
	local td = ok and type(joinData) == "table" and joinData.TeleportData
	return type(td) == "table" and tonumber(td.softRestartHops) or 1
end

local function sendBack(list, hops)
	if #list == 0 then return end
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ softRestart = true, softRestartHops = hops + 1 })
	for _, p in ipairs(list) do tries[p] = (tries[p] or 0) + 1 end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(MAIN_PLACE_ID, list, options)
	end)
	if not ok then
		warn("RestartTransit: ส่งกลับไม่สำเร็จ: " .. tostring(err))
		for _, p in ipairs(list) do
			task.delay(3, function()
				if not p.Parent then return end
				if (tries[p] or 0) >= 3 then p:Kick(KICK_TEXT) return end
				sendBack({ p }, hops)
			end)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	table.insert(waiting, { player = player, arrivedAt = os.clock(), hops = hopsOf(player) })
end)
for _, p in ipairs(Players:GetPlayers()) do
	table.insert(waiting, { player = p, arrivedAt = os.clock(), hops = hopsOf(p) })
end

TeleportService.TeleportInitFailed:Connect(function(player, result, message)
	warn("RestartTransit: TeleportInitFailed " .. player.Name .. " " .. tostring(result) .. " " .. tostring(message))
	task.wait(2)
	if not player.Parent then return end
	if (tries[player] or 0) >= 3 then player:Kick(KICK_TEXT) return end
	sendBack({ player }, hopsOf(player))
end)

Players.PlayerRemoving:Connect(function(player) tries[player] = nil end)

-- ส่งกลับเป็นกลุ่ม (คนที่มาด้วยกันได้เซิร์ฟเวอร์เดียวกัน)
while true do
	task.wait(1)
	local ready, rest, hops = {}, {}, 1
	for _, w in ipairs(waiting) do
		if w.player.Parent and os.clock() - w.arrivedAt >= WAIT_BEFORE_RETURN and #ready < BATCH then
			table.insert(ready, w.player)
			hops = math.max(hops, w.hops)
		elseif w.player.Parent then
			table.insert(rest, w)
		end
	end
	waiting = rest
	sendBack(ready, hops)
end
