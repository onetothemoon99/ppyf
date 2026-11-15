-- BACKUP 2026-11-15: game.ServerScriptService.Krathong.KrathongLakeService (Script) before opening it from now until the festival ends (was 24 Nov 2026 only)
-- Restore: in Studio open ServerScriptService.Krathong.KrathongLakeService, replace its whole Source with everything below the "-- ===== SOURCE =====" line.
-- ===== SOURCE =====
-- KrathongLakeService (2026-11-12 ผู้ใช้สั่ง): กระทงลอยในลำธาร (ย้ายจากทะเลสาบใหญ่ตามผู้ใช้สั่งวันเดียวกัน) ผู้เล่นลงไปกด E ค้าง (ProximityPrompt HOLD_SECONDS วิ, ผู้ใช้สั่ง 2026-11-12 แทนการชนแล้วเก็บเลย) = เก็บได้เหรียญ
-- ลำธาร = ลำธารจากน้ำตก workspace.LayoutDecor.StreamDecor ตามเส้นกลาง STREAM_LINE (จาก CHANGELOG ลำธารรอบ 2) ผิวน้ำ Terrain y 4 แผ่นสีฟ้าคราม y ~4.37
-- เปิดเฉพาะวันลอยกระทง 24 พ.ย. 2026 ตามเวลาไทย (ผู้ใช้สั่ง 2026-11-12) 00:00-23:59 · ไม่ผูกกับสวิตช์ KrathongFloat2026
-- ทดสอบใน Studio: ตั้ง Attribute workspace.DevKrathongLake = true (ใช้ได้เฉพาะใน Studio)
-- ค่าที่ผู้ใช้เลือก: 20 ใบพร้อมกัน · เหรียญ 1/5/10/20/50/100/500/1,000 ต่อใบ (2026-11-12 แทน 200-1,000) · เกิดใหม่หลัง 20 วิ · ไม่จำกัดต่อชั่วโมง
-- ของในแมพ: workspace.KrathongLake (Model ละใบ Anchored ชนไม่ได้) · เอฟเฟกต์: RemoteEvent ReplicatedStorage.KrathongLakeFx -> StarterPlayerScripts.KrathongLakeFx

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COUNT = 20
local RESPAWN = 20
local HOLD_SECONDS = 1.5 -- กด E ค้างกี่วิ
local PROMPT_RANGE = 8   -- ระยะที่ปุ่มขึ้น
local PICK_RANGE = 12    -- เซิร์ฟเช็กระยะจริงตอนกดสำเร็จ (กว้างกว่าปุ่มหน่อย เพราะกระทงไหวบนเครื่องผู้เล่น)
local SCALE = 1.3
local SINK = 0.25        -- จมลงในน้ำนิดหน่อยให้ดูลอยจริง
-- เส้นกลางลำธาร (x, z) จากปลายแอ่งน้ำตกถึงปลายน้ำ (ส่วนต่อทางตะวันตกของ x 130 ตอนนี้เป็นแปลงผัก ไม่ใช้)
local STREAM_LINE = { {404,38},{362,76},{324,106},{286,124},{248,130},{210,128},{170,124},{138,126} }
local STREAM_HALF = 24   -- สุ่มห่างเส้นกลางได้ไม่เกินนี้ (จุดต้องเป็นน้ำจริงด้วย)
local SURFACE_Y = 4.37   -- ผิวแผ่นน้ำสีฟ้าครามของลำธาร (สูงกว่าน้ำ Terrain 0.37) วางตามนี้ ไม่งั้นกระทงจมใต้แผ่น
local EDGE_CLEAR = 4     -- จุดเกิดต้องมีน้ำรอบตัวระยะนี้ (ไม่ชิดตลิ่ง/ใต้สะพาน)
local KINDS = { "Lotus", "Banana", "Bread" }
local EVENT_YEAR, EVENT_MONTH, EVENT_DAY = 2026, 11, 24
local TH_OFFSET = 7 * 3600 -- เวลาไทย UTC+7
local RunService = game:GetService("RunService")

local function isEventDay()
	if RunService:IsStudio() and workspace:GetAttribute("DevKrathongLake") == true then return true end
	local t = os.date("!*t", os.time() + TH_OFFSET)
	return t.year == EVENT_YEAR and t.month == EVENT_MONTH and t.day == EVENT_DAY
end
-- เรตเหรียญ (รวม 100) ค่ายิ่งสูงยิ่งออกยาก (ผู้ใช้สั่ง 2026-11-12) เฉลี่ย ~41 เหรียญต่อใบ
local REWARDS = {
	{ 1, 30 }, { 5, 22 }, { 10, 17 }, { 20, 12 },
	{ 50, 9 }, { 100, 6 }, { 500, 3 }, { 1000, 1 },
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

-- 🌊 2026-11-12 ผู้ใช้สั่ง "กระทงที่เป็นกิจกรรมให้เก็บด้วยไหลไปทางเดียวกัน": กระทงไหลตามลำธารออกจากน้ำตกไปทางตะวันตก (ทิศเดียวกับกระทงที่ผู้เล่นลอย)
--   เส้น/ความเร็ว = ReplicatedStorage.KrathongStreamLine (ใช้คู่กับ KrathongLakeFx) · เกิดแล้วตั้ง Attribute D0/T0/Side/PivotY/Yaw ครั้งเดียว เครื่องผู้เล่นคำนวณตำแหน่งเองทุกเฟรม
--   เซิร์ฟย้ายโมเดลจริงทุก DRIFT_TICK วิ (ให้คนเข้าใหม่/เช็กระยะตรง) · ไหลสุดเส้น / ไปเจอตลิ่ง = หายแล้วเกิดใหม่จุดสุ่ม (จำนวนคง COUNT)
local Line = require(ReplicatedStorage:WaitForChild("KrathongStreamLine"))
local DRIFT_TICK = 1
-- เช็กน้ำตอนไหล: ดูเฉพาะ Terrain (ลอดใต้สะพานได้ ไม่หายเพราะยิงโดนพื้นสะพาน)
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
local function terrainWaterAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), terrainOnly)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

-- จุดสุ่มตามความยาวลำธาร (ช่วงยาวได้กระทงมากกว่า) + เบี่ยงข้างตั้งฉากกับเส้น · เว้นท้ายเส้น 20% ให้ไหลได้สักพัก
local function streamPoint()
	local d = rng:NextNumber(0, Line.TOTAL * 0.8)
	local side = rng:NextNumber(-STREAM_HALF, STREAM_HALF)
	local x, z = Line.At(d, side)
	return x, z, d, side
end

local function findSpot()
	for _ = 1, 40 do
		local x, z, d, side = streamPoint()
		local p = waterAt(x, z)
		if p then p = Vector3.new(p.X, math.max(p.Y, SURFACE_Y), p.Z) end
		if p and waterAt(x + EDGE_CLEAR, z) and waterAt(x - EDGE_CLEAR, z) and waterAt(x, z + EDGE_CLEAR) and waterAt(x, z - EDGE_CLEAR) then
			local near = false
			for m in pairs(active) do
				if (m:GetPivot().Position - p).Magnitude < 8 then near = true break end
			end
			if not near then return p, d, side end
		end
	end
	return nil
end

local collect -- ประกาศก่อน (ใช้ในปุ่มของ spawnOne)

local function spawnOne()
	if not folder or not folder.Parent then return end
	local pos, d0, side = findSpot()
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
	local yaw = rng:NextNumber(0, math.pi * 2)
	m:PivotTo(CFrame.new(pos + Vector3.new(0, pivotAboveBottom - SINK, 0)) * CFrame.Angles(0, yaw, 0))
	m:SetAttribute("WaterY", pos.Y)
	m:SetAttribute("PivotY", pos.Y + pivotAboveBottom - SINK)
	m:SetAttribute("Yaw", yaw)
	m:SetAttribute("Side", side)
	m:SetAttribute("D0", d0)
	m:SetAttribute("T0", workspace:GetServerTimeNow())
	-- ปุ่มกด E ค้าง (มือถือ = แตะปุ่มค้าง, จอย = ปุ่ม X ค้าง)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CollectPrompt"
	prompt.ActionText = "เก็บกระทง"
	prompt.ObjectText = "🌸 กระทงลอย"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = HOLD_SECONDS
	prompt.MaxActivationDistance = PROMPT_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	m.Parent = folder
	active[m] = true
	prompt.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not (root and hum and hum.Health > 0) then return end
		local d = Line.Progress(m, workspace:GetServerTimeNow())
		local here = m:GetPivot().Position
		if d then local x, z = Line.At(d, m:GetAttribute("Side")) here = Vector3.new(x, here.Y, z) end -- ตำแหน่งตามสูตร (ตรงกับที่ผู้เล่นเห็น)
		if (root.Position - here).Magnitude > PICK_RANGE then return end
		collect(player, m)
	end)
end

function collect(player, m)
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

-- 🌊 ไหลตามลำธาร: ย้ายโมเดลจริงทุก DRIFT_TICK วิ · สุดเส้นหรือไม่ใช่น้ำแล้ว = เอาออกแล้วเกิดใหม่ (ไม่ให้เหรียญ)
task.spawn(function()
	while true do
		task.wait(DRIFT_TICK)
		if folder and folder.Parent then
			local now = workspace:GetServerTimeNow()
			for m in pairs(active) do
				local d = Line.Progress(m, now)
				if d then
					local x, z = Line.At(d, m:GetAttribute("Side"))
					if d >= Line.TOTAL - 1 or not terrainWaterAt(x, z) then
						active[m] = nil
						m:Destroy()
						task.defer(spawnOne)
					else
						m:PivotTo(CFrame.new(x, m:GetAttribute("PivotY") or m:GetPivot().Y, z) * CFrame.Angles(0, m:GetAttribute("Yaw") or 0, 0))
					end
				end
			end
		end
	end
end)

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

