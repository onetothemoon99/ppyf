-- BACKUP 2026-11-12 of game.ServerScriptService.Krathong.KrathongLakeService (Script, Studio) before moving the krathongs from the big lake to the stream.
-- Restore: copy everything BELOW the "==== SOURCE ====" line into that script's Source in Studio.
-- ==== SOURCE ====
-- KrathongLakeService (2026-11-12 ผู้ใช้สั่ง): กระทงลอยในทะเลสาบใหญ่ ผู้เล่นว่าย/เดินลงไปชน = เก็บได้เหรียญ
-- เปิดเฉพาะวันลอยกระทง 24 พ.ย. 2026 ตามเวลาไทย (ผู้ใช้สั่ง 2026-11-12) 00:00-23:59 · ไม่ผูกกับสวิตช์ KrathongFloat2026
-- ทดสอบใน Studio: ตั้ง Attribute workspace.DevKrathongLake = true (ใช้ได้เฉพาะใน Studio)
-- ค่าที่ผู้ใช้เลือก: 20 ใบพร้อมกัน · 200-1,000 เหรียญต่อใบ · เกิดใหม่หลัง 20 วิ · ไม่จำกัดต่อชั่วโมง
-- ของในแมพ: workspace.KrathongLake (Model ละใบ Anchored ชนไม่ได้) · เอฟเฟกต์: RemoteEvent ReplicatedStorage.KrathongLakeFx -> StarterPlayerScripts.KrathongLakeFx

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COUNT = 20
local RESPAWN = 20
local PICK_RANGE = 4.5   -- ระยะแนวราบจากตัวผู้เล่นถึงกระทง
local PICK_HEIGHT = 7
local SCALE = 1.3
local SINK = 0.25        -- จมลงในน้ำนิดหน่อยให้ดูลอยจริง
local LAKE_MIN = Vector3.new(194, 0, 224)
local LAKE_MAX = Vector3.new(386, 0, 516)
local EDGE_CLEAR = 6     -- จุดเกิดต้องมีน้ำรอบตัวระยะนี้ (ไม่ชิดฝั่ง/ศาลา)
local KINDS = { "Lotus", "Banana", "Bread" }
local EVENT_YEAR, EVENT_MONTH, EVENT_DAY = 2026, 11, 24
local TH_OFFSET = 7 * 3600 -- เวลาไทย UTC+7
local RunService = game:GetService("RunService")

local function isEventDay()
	if RunService:IsStudio() and workspace:GetAttribute("DevKrathongLake") == true then return true end
	local t = os.date("!*t", os.time() + TH_OFFSET)
	return t.year == EVENT_YEAR and t.month == EVENT_MONTH and t.day == EVENT_DAY
end
-- เรตเหรียญ (รวม 100) ใบถูกออกบ่อย ใบแพงนานๆ ที
local REWARDS = {
	{ 200, 18 }, { 300, 18 }, { 400, 18 }, { 500, 18 },
	{ 600, 7 }, { 700, 7 }, { 800, 7 },
	{ 900, 3.5 }, { 1000, 3.5 },
}

local rng = Random.new()
local models = ReplicatedStorage:WaitForChild("KrathongModels")
local fx = ReplicatedStorage:FindFirstChild("KrathongLakeFx") or Instance.new("RemoteEvent")
fx.Name = "KrathongLakeFx"
fx.Parent = ReplicatedStorage

local function roll()
	local r = rng:NextNumber(0, 100)
	for _, row in ipairs(REWARDS) do
		r -= row[2]
		if r <= 0 then return row[1] end
	end
	return REWARDS[1][1]
end

local folder = nil
local active = {} -- [model] = true

local function waterAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0))
	return hit and hit.Material == Enum.Material.Water and hit.Position or nil
end

local function findSpot()
	for _ = 1, 40 do
		local x = rng:NextNumber(LAKE_MIN.X, LAKE_MAX.X)
		local z = rng:NextNumber(LAKE_MIN.Z, LAKE_MAX.Z)
		local p = waterAt(x, z)
		if p and waterAt(x + EDGE_CLEAR, z) and waterAt(x - EDGE_CLEAR, z) and waterAt(x, z + EDGE_CLEAR) and waterAt(x, z - EDGE_CLEAR) then
			local near = false
			for m in pairs(active) do
				if (m:GetPivot().Position - p).Magnitude < 8 then near = true break end
			end
			if not near then return p end
		end
	end
	return nil
end

local function spawnOne()
	if not folder or not folder.Parent then return end
	local pos = findSpot()
	if not pos then return end
	local src = models:FindFirstChild(KINDS[rng:NextInteger(1, #KINDS)])
	if not src then return end
	local m = src:Clone()
	m.Name = "LakeKrathong"
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	pcall(function() m:ScaleTo(SCALE) end)
	local cf, size = m:GetBoundingBox()
	local pivotAboveBottom = m:GetPivot().Y - (cf.Y - size.Y / 2)
	m:PivotTo(CFrame.new(pos + Vector3.new(0, pivotAboveBottom - SINK, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	m:SetAttribute("WaterY", pos.Y)
	m.Parent = folder
	active[m] = true
end

local function collect(player, m)
	if not active[m] then return end
	if player:GetAttribute("CoinsLoaded") ~= true then return end -- บวกก่อนโหลด = โดนค่าที่โหลดมาทับ
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("เหรียญ")
	if not coins then return end
	active[m] = nil
	local amount = roll()
	coins.Value += amount
	local pos = m:GetPivot().Position
	m:Destroy()
	fx:FireAllClients(pos, player.UserId, amount)
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local notify = remotes and remotes:FindFirstChild("HarvestNotify")
	if notify then notify:FireClient(player, "Coins", 0, amount) end
	task.delay(RESPAWN, spawnOne)
end

local function setOn(on)
	if on and not (folder and folder.Parent) then
		folder = Instance.new("Folder")
		folder.Name = "KrathongLake"
		folder.Parent = workspace
		for _ = 1, COUNT do spawnOne() end
	elseif not on and folder then
		folder:Destroy()
		folder = nil
		table.clear(active)
	end
end

-- เปิด/ปิดตามวัน (เช็กทุก 3 วิ: ข้ามเที่ยงคืนเวลาไทยแล้วเปิด/ปิดเองในเซิร์ฟที่เปิดค้าง)
task.spawn(function()
	while true do
		pcall(setOn, isEventDay())
		-- เผื่อจุดเกิดหาไม่เจอบางรอบ เติมให้ครบ
		if folder and folder.Parent then
			local n = 0
			for _ in pairs(active) do n += 1 end
			if n < COUNT - 3 then spawnOne() end
		end
		task.wait(3)
	end
end)

-- เก็บ: เช็กระยะจากตัวละครจริงทุก 0.2 วิ
task.spawn(function()
	while true do
		task.wait(0.2)
		if folder and next(active) then
			for _, player in ipairs(Players:GetPlayers()) do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 then
					local rp = root.Position
					for m in pairs(active) do
						local mp = m:GetPivot().Position
						local dx, dz = mp.X - rp.X, mp.Z - rp.Z
						if dx * dx + dz * dz <= PICK_RANGE * PICK_RANGE and math.abs(mp.Y - rp.Y) <= PICK_HEIGHT then
							collect(player, m)
							break
						end
					end
				end
			end
		end
	end
end)
