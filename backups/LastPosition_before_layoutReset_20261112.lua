-- Backup of game.ServerScriptService.LastPosition (Script) before the layout-version reset, 2026-11-12.
-- Restore: open the script in Studio, select all, paste everything below this header.
-- LastPosition: ออกเกมที่ไหน เข้ามาใหม่เกิดที่นั่น
-- 2026-10-10 ผู้ใช้ขอ: ตาย/กด Reset = เกิดที่จุดล่าสุดที่ปลอดภัยด้วย (เดิมเฉพาะตัวละครแรก) / กด Reset ซ้ำภายใน RESPAWN_ESCAPE วิ = กลับจุดเกิดปกติ (เผื่อติดอยู่ที่ไหน)
-- 2026-10-11 เปลี่ยนอวาตาร์ในเกม (เมนู Roblox) = ตัวละครถูกสร้างใหม่โดยไม่ตาย: เก็บตำแหน่งตอนตัวเก่าถูกลบ (ไม่ใช่ค่าที่เก็บทุก 5 วิ ซึ่งล้าหลังได้) และไม่นับเป็น "กด Reset ซ้ำ"
--   (เดิมเปลี่ยนอวาตาร์ 2 ครั้งภายใน 15 วิ = โดนส่งกลับจุดเกิด) · ระหว่างย้ายตัวไม่เก็บตำแหน่ง (กันเก็บจุดเกิดทับจุดล่าสุด)
-- 2026-10-11 ตาย/Reset ตอนอยู่ในน้ำ = เกิดที่ขอบแปลงปลูกที่ใกล้จุดตายที่สุด หันหน้าไปทางน้ำ (ผู้ใช้ขอ) หาแปลงไม่ได้ = จุดล่าสุดที่ปลอดภัยตามเดิม
-- DataStore "LastPosition_v1": { x, y, z, yaw } ตำแหน่งลำตัว (HumanoidRootPart) ล่าสุดที่ "ปลอดภัย"
-- ปลอดภัย = ยืนบนพื้นแข็ง (ไม่ลอย ไม่ว่ายน้ำ ไม่นั่ง ยังมีชีวิต) เก็บทุก 5 วิ แล้วเซฟตอนออกเกม / ปิดเซิร์ฟเวอร์
-- ตอนเข้าเกมเช็กซ้ำว่าจุดนั้นยังมีพื้นและไม่ใช่น้ำ (แมพอาจเปลี่ยน) ไม่ผ่าน = เกิดที่จุดเกิดปกติ
-- แมพโหลดทีละส่วน (StreamingEnabled): ขอให้เครื่องผู้เล่นโหลดแมพรอบจุดนั้นก่อนย้ายตัว (RequestStreamAroundAsync)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local store = DataStoreService:GetDataStore("LastPosition_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local PlayArea = require(game:GetService("ServerScriptService"):WaitForChild("PlayArea")) -- หลังกำแพงภูเขา = ไม่เก็บ/ไม่พากลับไป (เกิดที่จุดเกิดปกติ)

local SAMPLE_INTERVAL = 5      -- วินาที เก็บตำแหน่งล่าสุดที่ปลอดภัย
local MAP_LIMIT = 1100         -- นอกขอบทะเลรอบเกาะ = ไม่เก็บ
local MIN_Y, MAX_Y = -20, 400
local NEAR_SPAWN = 15          -- ออกเกมตรงจุดเกิดอยู่แล้ว ไม่ต้องย้าย
local LOAD_WAIT = 40           -- รอโหลดข้อมูลนานสุดกี่วิตอนตัวละครเกิด (เดิม 10: หลังรีเซิร์ฟคนเข้าพร้อมกัน DataStore ช้า = เกิดที่จุดเกิดปกติ) 2026-10-09
local WALKED_AWAY = 20         -- ระหว่างรอโหลด ผู้เล่นเดินออกจากจุดเกิดไกลกว่านี้แล้ว = ไม่พากลับ (ไม่ดึงตัวกลางทาง)
local SAVE_TRIES = 4           -- เซฟไม่ผ่าน (ตอนปิดเซิร์ฟทุกคนเซฟพร้อมกัน = โดนจำกัดการเขียน) ลองซ้ำกี่ครั้ง
local STREAMED_NEAR = 120       -- ตัวเก่าอยู่ใกล้เป้าหมายไม่เกินนี้ (สตั๊ด) = ไม่ต้องรอโหลดแมพก่อนย้ายตัวตอนเกิดใหม่
local SPAWN_MISS = 12          -- เกิดห่างจุดที่ตั้งไว้เกินนี้ (สตั๊ด แนวราบ) = จุดเกิดส่วนตัวไม่ทำงาน ใช้วิธีย้ายตัวแบบเดิมแทน
local RESPAWN_ESCAPE = 6     -- เกิดที่เดิมแล้วกด Reset ซ้ำภายในกี่วิ = ไปจุดเกิดปกติ
local pendingSaves = 0

local states = {} -- [player] = { loaded, saved = {x,y,z,yaw}|nil, last = {x,y,z,yaw}|nil, placed }

local function notify(player, text)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local ev = re and re:FindFirstChild("HarvestNotify")
	if ev and player.Parent then ev:FireClient(player, nil, nil, nil, text) end
end

local function spawnPosition()
	local s = workspace:FindFirstChildWhichIsA("SpawnLocation")
	return s and s.Position
end

local function validPoint(p)
	return math.abs(p.X) < MAP_LIMIT and math.abs(p.Z) < MAP_LIMIT and p.Y > MIN_Y and p.Y < MAX_Y
		and not PlayArea.IsBlocked(p.X, p.Z)
end

-- พื้นแข็งใต้จุด pos (ยิงลงไม่เกิน GROUND_REACH สตั๊ด ข้ามตัวละครทุกคน รวมสัตว์ขี่ที่เชื่อมอยู่ในตัวละคร และของที่เดินทะลุได้)
-- เจอน้ำ / ไม่เจออะไร / มีของขวางเหนือหัว = nil · คืน { x, y, z, yaw } ที่ y = ความสูงลำตัวตอนยืนบนพื้นนั้น
-- 2026-10-18 (ผู้ใช้: เปลี่ยนอวาตาร์แล้วไม่เกิดที่เดิม บางทีไปจุดที่เคยอยู่หลายชั่วโมงก่อน): เดิมเก็บจุดเฉพาะตอนยืนบนพื้น
--   ขี่สัตว์/นั่ง/กระโดดนานๆ = จุดที่เก็บไว้เก่ามาก ตอนนี้ใช้พื้นใต้ตัวแทน
local GROUND_REACH = 60
-- lowOk = true: ไม่เช็กของเหนือหัว (ใช้กับจุดที่ตัวเก่าเพิ่งยืนอยู่จริง เช่นใต้ต้นไม้/หลังคาเตี้ย เดิมไม่ผ่าน = ไปใช้จุดเก่า)
local function groundUnder(character, pos, yaw, lowOk)
	if not validPoint(pos) then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(ignore, pl.Character) end end
	if character then table.insert(ignore, character) end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	params.RespectCanCollide = true
	local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -GROUND_REACH, 0), params)
	if not hit then return nil end
	if hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Water then return nil end
	local above = not lowOk and workspace:Raycast(hit.Position + Vector3.new(0, 0.2, 0), Vector3.new(0, 5, 0), params)
	if above then return nil end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local height = 2 + (root and root.Size.Y / 2 or 1) + 0.3
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then height = math.max(humanoid.HipHeight, 2) + (root and root.Size.Y / 2 or 1) + 0.3 end
	local p = hit.Position + Vector3.new(0, height, 0)
	return { x = p.X, y = p.Y, z = p.Z, yaw = yaw or 0 }
end

-- ยืนอยู่บนพื้นแข็งแบบปลอดภัยไหม (ไม่เก็บตอนว่ายน้ำ/ตาย) · ขี่สัตว์/นั่ง/กระโดด/ตก = ใช้พื้นแข็งใต้ตัว (groundUnder)
local function safeSample(player, character)
	character = character or player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root) or humanoid.Health <= 0 then return nil end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Swimming then return nil end
	local p = root.Position
	if not validPoint(p) then return nil end
	local look = root.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local floor = humanoid.FloorMaterial
	local onGround = not humanoid.Sit and floor ~= Enum.Material.Air and floor ~= Enum.Material.Water
		and state ~= Enum.HumanoidStateType.Freefall and state ~= Enum.HumanoidStateType.Jumping
		and not player:GetAttribute("RidingMount")
	if onGround then return { x = p.X, y = p.Y, z = p.Z, yaw = yaw } end
	return groundUnder(character, p, yaw)
end

-- จุดที่เก็บไว้ยังใช้ได้ไหม: ยิงลงจากเหนือหัว ต้องเจอพื้นใกล้ๆ และไม่ใช่น้ำ คืนตำแหน่งลำตัวที่ควรวาง
local function checkSpot(character, data)
	local p = Vector3.new(data.x, data.y, data.z)
	if not validPoint(p) then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { character }
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(ignore, pl.Character) end end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	local hit = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
	if not hit then return nil end
	if hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Water then return nil end
	-- ไม่มีอะไรขวางเหนือหัว (เช่นแมพเพิ่มของมาวางทับจุดนั้น)
	local above = workspace:Raycast(hit.Position + Vector3.new(0, 0.2, 0), Vector3.new(0, 5, 0), params)
	if above and above.Instance.CanCollide then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local height = (humanoid and humanoid.HipHeight or 2) + (root and root.Size.Y / 2 or 1) + 0.3
	return hit.Position + Vector3.new(0, height, 0)
end

-- จุดนั้นอยู่ในน้ำไหม: ยิงลงมาจากข้างบน เจอผิวน้ำก่อน และผิวน้ำไม่ต่ำกว่าตัวเกิน 3 สตั๊ด (ยืนบนสะพานเหนือน้ำ = ไม่นับ)
local function inWater(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = false
	local hit = workspace:Raycast(pos + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), params)
	return hit ~= nil and hit.Material == Enum.Material.Water and hit.Position.Y >= pos.Y - 3
end

-- ขอบแปลงปลูกที่ใกล้จุด pos ที่สุด (เข้ามาจากขอบ PLOT_INSET สตั๊ด) ลองทีละแปลงจากใกล้ไปไกล ต้องผ่าน checkSpot · คืน { x, y, z, yaw } หันหน้าไปทาง pos
local PLOT_INSET = 3
local PLOT_TRIES = 4
local soilCache = nil
local function soils()
	if soilCache and #soilCache > 0 then return soilCache end
	soilCache = {}
	local plots = workspace:FindFirstChild("FarmPlots")
	if plots then
		for _, plot in ipairs(plots:GetChildren()) do
			for _, child in ipairs(plot:GetChildren()) do -- Soil เป็นลูกตรงของแปลง (บางแปลงมีหลายชิ้น)
				if child:IsA("BasePart") and child.Name == "Soil" then table.insert(soilCache, child) end
			end
		end
	end
	return soilCache
end

local function nearestPlotSpot(character, pos)
	local list = {}
	for _, soil in ipairs(soils()) do
		if soil.Parent then
			local half = soil.Size / 2
			local l = soil.CFrame:PointToObjectSpace(pos)
			local mx, mz = math.max(half.X - PLOT_INSET, 0), math.max(half.Z - PLOT_INSET, 0)
			local edge = soil.CFrame:PointToWorldSpace(Vector3.new(math.clamp(l.X, -mx, mx), half.Y, math.clamp(l.Z, -mz, mz)))
			local dx, dz = pos.X - edge.X, pos.Z - edge.Z
			table.insert(list, { edge = edge, dist = math.sqrt(dx * dx + dz * dz), yaw = math.atan2(-dx, -dz) })
		end
	end
	table.sort(list, function(a, b) return a.dist < b.dist end)
	for i = 1, math.min(PLOT_TRIES, #list) do
		local c = list[i]
		local data = { x = c.edge.X, y = c.edge.Y + 2, z = c.edge.Z, yaw = c.yaw }
		if checkSpot(character, data) then return data end
	end
	return nil
end

-- จุดที่ตัวเก่าอยู่ "ตอนนี้" (ตอนตาย/เปลี่ยนอวาตาร์) 2026-10-19 ผู้ใช้แจ้งรอบ 4: เปลี่ยนอวาตาร์แล้วไปจุดเกิด / จุดเมื่อหลายชั่วโมงก่อน
-- เดิมหาพื้นใต้ตัวไม่ได้ (นั่งเรือบนน้ำตอน AFK ตกปลา / อยู่ใต้ของเตี้ย / กลางอากาศ) = ใช้ st.last ที่อาจเก่าหลายชั่วโมง
-- ตอนนี้: พื้นใต้ตัว (ไม่เช็กเหนือหัว) → อยู่ในน้ำ = ขอบแปลงที่ใกล้สุด → ไม่งั้นจุดที่ตัวอยู่ตรงๆ · นอกแมพ/หลังกำแพง = nil
local function spotAt(character, pos, yaw)
	if not (pos and validPoint(pos)) then return nil end
	local ground = groundUnder(character, pos, yaw, true)
	if ground then return ground end
	if inWater(pos) then return nearestPlotSpot(character, pos) end
	return { x = pos.X, y = pos.Y, z = pos.Z, yaw = yaw or 0 }
end

-- ลายเซ็นหน้าตาตัวละคร (เสื้อ/กางเกง/หน้า/สีผิว/ของใส่) ไว้ดูว่าตัวใหม่ "เปลี่ยนอวาตาร์" ไม่ใช่กด Reset ซ้ำ
local function lookSignature(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local ok, desc = pcall(function() return humanoid:GetAppliedDescription() end)
	if not (ok and desc) then return nil end
	local parts = { desc.Shirt, desc.Pants, desc.GraphicTShirt, desc.Face, desc.Head, desc.Torso,
		desc.HatAccessory, desc.HairAccessory, desc.FaceAccessory, desc.BackAccessory, desc.FrontAccessory,
		desc.NeckAccessory, desc.ShouldersAccessory, desc.WaistAccessory, tostring(desc.HeadColor), tostring(desc.TorsoColor) }
	local okLayered, layered = pcall(function() return desc:GetAccessories(false) end)
	if okLayered then for _, a in ipairs(layered) do table.insert(parts, tostring(a.AssetId)) end end
	for i, v in ipairs(parts) do parts[i] = tostring(v) end
	return table.concat(parts, "|")
end

-- ============ จุดเกิดส่วนตัว (2026-10-12) ============
-- เมนูเปลี่ยนอวาตาร์ของ Roblox ทำงานด้วยการรีเซ็ตตัวละครแล้วเกิดใหม่ (ตัวละคร "ตาย" จริง) ผู้เล่นแจ้ง: เปลี่ยนแล้วไปเกิดที่จุดเกิด /
-- คนอื่นมองไม่เห็นตัว / มองไม่เห็นตัวเอง — เดิมตัวใหม่เกิดที่จุดเกิดก่อนแล้วเซิร์ฟเวอร์ค่อยย้ายตัว (PivotTo) ไปจุดเดิมซึ่งอยู่ไกลได้หลายร้อยสตั๊ด
-- ใหม่: แต่ละคนมี SpawnLocation ล่องหนของตัวเอง (workspace.PlayerRespawnSpots) วางไว้ที่จุดล่าสุดที่ปลอดภัย + ตั้ง player.RespawnLocation
--   = Roblox สร้างตัวละครตรงนั้นเลย ไม่มีการย้ายตัวหลังเกิด · ตั้งเป็น "ไม่กลาง" (Neutral = false, TeamColor เท่าของผู้เล่น) ผู้เล่นอื่นที่ไม่ได้ตั้ง
--   RespawnLocation จึงไม่ถูกสุ่มมาเกิดที่นี่ (ทดสอบใน Studio แล้ว) · เกิดพลาดจุด = placeRespawn ย้ายตัวแบบเดิมเป็นทางสำรอง
local SPOT_FOLDER = "PlayerRespawnSpots"
local SPOT_DROP = 3 -- ตัวละครเกิดสูงกว่ากึ่งกลางแผ่นเกิดราว 3 สตั๊ด (วัดใน Studio)

local function setRespawnSpot(player, st, target, yaw)
	if not player.Parent then return end
	if not target then
		st.spawnTarget = nil
		player.RespawnLocation = nil
		return
	end
	local part = st.spawnPart
	if not (part and part.Parent) then
		local folder = workspace:FindFirstChild(SPOT_FOLDER)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = SPOT_FOLDER
			folder.Parent = workspace
		end
		part = Instance.new("SpawnLocation")
		part.Name = "Spot_" .. player.UserId
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
		part.Transparency = 1
		part.Size = Vector3.new(2, 1, 2)
		part.Neutral = false
		part.AllowTeamChangeOnTouch = false
		part.Duration = 0
		part.Enabled = true
		for _, d in ipairs(part:GetChildren()) do if d:IsA("Decal") then d:Destroy() end end
		st.spawnPart = part
	end
	part.TeamColor = player.TeamColor
	part.CFrame = CFrame.new(target - Vector3.new(0, SPOT_DROP, 0)) * CFrame.Angles(0, yaw or 0, 0)
	if part.Parent == nil then part.Parent = workspace:FindFirstChild(SPOT_FOLDER) end
	st.spawnTarget, st.spawnYaw = target, yaw or 0
	player.RespawnLocation = part
end

-- ตั้งจุดเกิดส่วนตัวตามจุดล่าสุดที่ปลอดภัย (ใกล้จุดเกิดปกติอยู่แล้ว = ใช้จุดเกิดปกติ)
local function spotFromLast(player, st)
	local data = st.last
	if not data then return end
	local p = Vector3.new(data.x, data.y, data.z)
	local spawnPos = spawnPosition()
	if spawnPos and (p - spawnPos).Magnitude < NEAR_SPAWN then
		setRespawnSpot(player, st, nil)
	else
		setRespawnSpot(player, st, p, data.yaw)
	end
end

-- ตอนตาย (รวมกด Reset และเปลี่ยนอวาตาร์): ตัดสินว่าตัวใหม่จะเกิดที่ไหน แล้วตั้งจุดเกิดส่วนตัวก่อน Roblox สร้างตัว (RespawnTime 3 วิ)
--   ตายซ้ำภายใน RESPAWN_ESCAPE วิหลังเกิด = จุดเกิดปกติ (เผื่อติด) · ตายในน้ำ = แปลงปลูกที่ใกล้สุด · นอกนั้น = จุดล่าสุดที่ปลอดภัย
local function decideRespawn(player, character, st, deathPos, deathInWater)
	st.escapeNext, st.plotNext = nil, nil
	if st.respawnPlacedAt and os.clock() - st.respawnPlacedAt < RESPAWN_ESCAPE then
		st.respawnPlacedAt = nil
		st.escapeNext = true
		-- เผื่อกรณีเปลี่ยนอวาตาร์ซ้ำเร็วๆ (ตัวใหม่หน้าตาไม่เหมือนเดิม = ไม่ใช่กด Reset หนี) placeRespawn พากลับจุดนี้
		st.escapeAlt = spotAt(character, deathPos, st.deathYaw)
		setRespawnSpot(player, st, nil)
		return
	end
	local plotSpot = deathInWater and deathPos and nearestPlotSpot(character, deathPos) or nil
	-- ไม่ใช่ตายในน้ำ = จุดที่ตายจริง (spotAt: พื้นใต้ตัว / ตรงที่ตัวอยู่) ไม่ต้องผ่าน checkSpot ซ้ำ · หาไม่ได้จริงๆ ค่อยใช้จุดล่าสุดที่เก็บไว้
	local deathSpot = (not plotSpot) and deathPos and spotAt(character, deathPos, st.deathYaw) or nil
	local data = plotSpot or deathSpot or st.last
	if not data then return end
	local spawnPos = spawnPosition()
	if spawnPos and (Vector3.new(data.x, data.y, data.z) - spawnPos).Magnitude < NEAR_SPAWN then
		setRespawnSpot(player, st, nil)
		return
	end
	local target = (data == deathSpot and Vector3.new(data.x, data.y, data.z)) or checkSpot(character, data)
	if not target then
		setRespawnSpot(player, st, nil)
		return
	end
	st.plotNext = plotSpot ~= nil
	setRespawnSpot(player, st, target, data.yaw)
end

-- ตัวละครใหม่หลังตัวแรก: ปกติ Roblox วางตัวที่จุดเกิดส่วนตัวให้แล้ว ที่นี่แค่ตรวจ + แจ้งข้อความ · เกิดพลาดจุด (เกิน SPAWN_MISS) = ย้ายตัวแบบเดิม
local function placeRespawn(player, character, st, wasDeath)
	st.deathInWater, st.deathPos = nil, nil
	local escaped, plotSpot = st.escapeNext, st.plotNext
	local escapeAlt, oldLook = st.escapeAlt, st.deathLook
	st.escapeNext, st.plotNext, st.escapeAlt = nil, nil, nil
	if escaped then
		-- ตัวใหม่หน้าตาเปลี่ยน = เปลี่ยนอวาตาร์ (ไม่ใช่กด Reset หนี) → พากลับจุดที่เพิ่งอยู่ (2026-10-19)
		if escapeAlt and oldLook then
			local t0 = os.clock()
			while player.Parent and character.Parent and not player:HasAppearanceLoaded() and os.clock() - t0 < 6 do task.wait(0.2) end
			local newLook = lookSignature(character)
			local root = character:FindFirstChild("HumanoidRootPart")
			if newLook and newLook ~= oldLook and root and character.Parent then
				local target = Vector3.new(escapeAlt.x, escapeAlt.y, escapeAlt.z)
				if (root.Position - target).Magnitude > STREAMED_NEAR then pcall(function() player:RequestStreamAroundAsync(target, 8) end) end
				if character.Parent and root.Parent then
					character:PivotTo(CFrame.new(target) * CFrame.Angles(0, escapeAlt.yaw or 0, 0))
					root.AssemblyLinearVelocity = Vector3.zero
					st.last = escapeAlt
					spotFromLast(player, st)
					st.respawnPlacedAt = os.clock()
					return
				end
			end
		end
		notify(player, "🏠 กลับจุดเกิดแล้ว")
		return
	end
	local target = st.spawnTarget
	if not target then return end -- เกิดที่จุดเกิดปกติ (ไม่มีจุดล่าสุด / อยู่ใกล้จุดเกิดอยู่แล้ว / จุดเดิมใช้ไม่ได้)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or character.Parent == nil then return end
	local data = { x = target.X, y = target.Y, z = target.Z, yaw = st.spawnYaw or 0 }
	local miss = ((root.Position - target) * Vector3.new(1, 0, 1)).Magnitude
	if miss <= SPAWN_MISS then
		st.prevCharPos = nil
		st.last = data
		if not wasDeath then return end
		st.respawnPlacedAt = os.clock()
		notify(player, (plotSpot and "📍 เกิดที่แปลงปลูกใกล้น้ำที่สุด" or "📍 เกิดที่จุดล่าสุด") .. " · อยากกลับจุดเกิด กด Reset อีกครั้งภายใน " .. RESPAWN_ESCAPE .. " วิ")
		return
	end
	print(string.format("📍 LastPosition: %s เกิดห่างจุดที่ตั้งไว้ %.0f สตั๊ด ใช้วิธีย้ายตัวแทน", player.Name, miss))
	local spawnPos = spawnPosition()
	-- 2026-10-11 (ผู้เล่นแจ้ง: เปลี่ยนอวาตาร์แล้วบางคนมองไม่เห็นคนอื่น/ตัวเอง เหมือนโหลดไม่ทัน): ตัวใหม่เกิดที่จุดเกิดก่อนเสมอ
	-- แล้วค่อยถูกย้าย ถ้าตัวเก่าเพิ่งอยู่ใกล้เป้าหมาย เครื่องผู้เล่นมีแมพตรงนั้นอยู่แล้ว = ย้ายทันที ไม่รอโหลดแมพ
	-- (การรอ RequestStreamAroundAsync อาจกินหลายวิตอนเซิร์ฟแน่น ระหว่างนั้นตัวละครยืนที่จุดเกิด เครื่องผู้เล่นสลับไปโหลดแมพอีกฟาก)
	local alreadyThere = st.prevCharPos ~= nil and (st.prevCharPos - target).Magnitude <= STREAMED_NEAR
	st.prevCharPos = nil
	if not alreadyThere then
		pcall(function() player:RequestStreamAroundAsync(target, 8) end)
		if character.Parent == nil or not root.Parent then return end
	end
	character:PivotTo(CFrame.new(target) * CFrame.Angles(0, data.yaw or 0, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	st.last = { x = target.X, y = target.Y, z = target.Z, yaw = data.yaw or 0 }
	if not wasDeath then return end
	st.respawnPlacedAt = os.clock()
	notify(player, (plotSpot and "📍 เกิดที่แปลงปลูกใกล้น้ำที่สุด" or "📍 เกิดที่จุดล่าสุด") .. " · อยากกลับจุดเกิด กด Reset อีกครั้งภายใน " .. RESPAWN_ESCAPE .. " วิ")
end

local function placeCharacter(player, character, st, wasDeath)
	if st.placed then return placeRespawn(player, character, st, wasDeath) end
	st.placed = true -- ตัวละครแรก (ตาย/Reset ทีหลัง = placeRespawn)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or character.Parent == nil then return end
	local startPos = root.Position
	local waited = 0
	while not st.loaded and waited < LOAD_WAIT and player.Parent do waited += task.wait(0.2) end
	local data = st.saved
	if not data then return end
	local spawnPos = spawnPosition()
	if spawnPos and (Vector3.new(data.x, data.y, data.z) - spawnPos).Magnitude < NEAR_SPAWN then return end
	if character.Parent == nil or not root.Parent then return end
	-- โหลดช้าจนผู้เล่นเดินไปที่อื่นแล้ว = ไม่ดึงกลับ (เซฟตำแหน่งต่อตามปกติ)
	if (root.Position - startPos).Magnitude > WALKED_AWAY then
		print("📍 LastPosition: โหลดตำแหน่งของ " .. player.Name .. " ช้า ผู้เล่นเดินไปที่อื่นแล้ว ไม่พากลับ")
		return
	end
	local target = checkSpot(character, data)
	if not target then
		print("📍 LastPosition: จุดเดิมของ " .. player.Name .. " ใช้ไม่ได้แล้ว เกิดที่จุดเกิดปกติ")
		return
	end
	-- ให้เครื่องผู้เล่นโหลดแมพรอบจุดนั้นก่อน ไม่งั้นไปถึงแล้วพื้นยังไม่มา ตกแมพ
	pcall(function() player:RequestStreamAroundAsync(target, 8) end)
	if character.Parent == nil or not root.Parent then return end
	character:PivotTo(CFrame.new(target) * CFrame.Angles(0, data.yaw or 0, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	st.last = { x = target.X, y = target.Y, z = target.Z, yaw = data.yaw or 0 }
	spotFromLast(player, st)
	notify(player, "📍 กลับมาที่เดิมตอนออกเกม · อยากกลับจุดเกิด กด Reset 2 ครั้งติดกัน")
end

local function save(player, st)
	if not (st and st.loaded and st.last) then return end
	local data = st.last
	local userId = player.UserId
	local name = player.Name
	local value = { x = math.floor(data.x * 10) / 10, y = math.floor(data.y * 10) / 10, z = math.floor(data.z * 10) / 10, yaw = math.floor((data.yaw or 0) * 100) / 100 }
	-- เซฟค่าเดิมไปแล้ว (เช่น เซฟล่วงหน้าก่อนรีเซิร์ฟ RestartNotice) = ไม่เขียนซ้ำ ลดคำขอตอนปิดเซิร์ฟ
	local valueKey = string.format("%.1f,%.1f,%.1f,%.2f", value.x, value.y, value.z, value.yaw)
	if st.savedKey == valueKey then return end
	-- ลองซ้ำ (เดิมเซฟครั้งเดียว: รีเซิร์ฟ 2026-10-09 22:14 เซฟได้ 3 จาก 18 คน เพราะทุกระบบเซฟพร้อมกันจนโดนจำกัดการเขียน)
	pendingSaves += 1
	DataLoadRetry.BeginLeaveSave(userId) -- เข้าเซิร์ฟเดิมทันที = รอเซฟนี้ก่อนโหลด (2026-10-10)
	local ok, err
	for attempt = 1, SAVE_TRIES do
		ok, err = pcall(function()
			store:SetAsync(tostring(userId), value, { userId })
		end)
		if ok then break end
		if attempt < SAVE_TRIES then task.wait(attempt * 2 + math.random() * 2) end
	end
	pendingSaves -= 1
	DataLoadRetry.EndLeaveSave(userId)
	if ok then st.savedKey = valueKey end
	if not ok then warn("LastPosition: เซฟไม่สำเร็จ " .. name .. ": " .. tostring(err)) end
end

-- เซฟล่วงหน้าก่อนรีเซิร์ฟ (ServerScriptService.RestartNotice ยิงทีละคน) 2026-10-09
task.spawn(function()
	local ev = game:GetService("ServerScriptService"):WaitForChild("PreRestartSave", 60)
	if not ev then return end
	ev.Event:Connect(function(player)
		local st = states[player]
		if not st then return end
		local sample = safeSample(player)
		if sample then st.last = sample end
		task.spawn(save, player, st)
	end)
end)

local function onPlayerAdded(player)
	local st = { loaded = false, saved = nil, last = nil, placed = false }
	states[player] = st
	-- Attribute "SpawnPlaced" = จัดตำแหน่งตัวละครแรกเสร็จแล้ว (ระบบอื่นรอตัวนี้ก่อนทำต่อ เช่น กลับมาตกปลาต่อหลังเข้าเกมใหม่เพราะ AFK)
	local function place(character)
		local wasDeath = st.prevDied ~= false -- ไม่รู้ = ถือว่าตาย (พฤติกรรมเดิม)
		st.prevDied = nil
		st.placing = true
		placeCharacter(player, character, st, wasDeath)
		if player.Character == character or not player.Character then st.placing = false end
		if player.Parent then player:SetAttribute("SpawnPlaced", true) end
	end
	-- จำว่าตายตรงไหน และตอนนั้นอยู่ในน้ำไหม (กำลังว่ายน้ำ หรือจุดนั้นเป็นน้ำ)
	local function watchDeath(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end
		local swimming = false
		humanoid.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Swimming then swimming = true
			elseif new ~= Enum.HumanoidStateType.Dead then swimming = false end
		end)
		humanoid.Died:Connect(function()
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			st.deathPos = root.Position
			local look = root.CFrame.LookVector
			st.deathYaw = math.atan2(-look.X, -look.Z)
			st.deathInWater = swimming or inWater(root.Position)
			st.deathLook = lookSignature(character)
			if st.placed then decideRespawn(player, character, st, st.deathPos, st.deathInWater) end
		end)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(watchDeath, character)
		task.spawn(place, character)
	end)
	if player.Character then task.spawn(watchDeath, player.Character) end
	-- ตัวละครเก่ากำลังถูกลบ: ยังไม่ตาย = เปลี่ยนอวาตาร์/โหลดตัวใหม่ → เก็บจุดที่ยืนอยู่ตอนนี้เลย (ถ้าปลอดภัย) ตัวใหม่จะเกิดตรงนั้น
	player.CharacterRemoving:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local died = not humanoid or humanoid.Health <= 0
		st.prevDied = died
		local oldRoot = character:FindFirstChild("HumanoidRootPart")
		st.prevCharPos = oldRoot and oldRoot.Position or nil -- ใช้ตัดสินว่าตัวใหม่ต้องรอโหลดแมพก่อนย้ายไหม
		if not died and st.placed and not st.placing then
			-- หาพื้นแบบปกติไม่ได้ (นั่งเรือ/ใต้ของเตี้ย/ว่ายน้ำ) = จุดที่ตัวอยู่ตอนนี้ (spotAt) แทนจุดที่เก็บไว้เก่าๆ
			local oldYaw = oldRoot and math.atan2(-oldRoot.CFrame.LookVector.X, -oldRoot.CFrame.LookVector.Z) or 0
			local sample = safeSample(player, character) or (oldRoot and spotAt(character, oldRoot.Position, oldYaw))
			if sample then
				st.last = sample
				spotFromLast(player, st)
			end
		end
	end)
	if player.Character then task.spawn(place, player.Character) end
	-- ลองจนได้ (เดิมลอง 3 ครั้งแล้วเลิก = รอบนั้นไม่เซฟตำแหน่งเลย) โหลดช้าเกิน LOAD_WAIT = เกิดที่จุดเกิดปกติเหมือนเดิม แต่เซฟตำแหน่งต่อได้ 2026-10-09
	local ok, data = DataLoadRetry.Load(player, "LastPosition", DataLoadRetry.Get(store, tostring(player.UserId)), function() return states[player] == st end)
	if ok then
		if type(data) == "table" and tonumber(data.x) and tonumber(data.y) and tonumber(data.z) then
			st.saved = { x = tonumber(data.x), y = tonumber(data.y), z = tonumber(data.z), yaw = tonumber(data.yaw) or 0 }
		end
		st.loaded = true
	end
	-- เก็บตำแหน่งล่าสุดที่ปลอดภัยเป็นระยะ (ตอนออกเกมตัวละครอาจถูกลบไปแล้ว)
	task.spawn(function()
		while player.Parent do
			local sample = st.placed and not st.placing and safeSample(player)
			if sample then
				st.last = sample
				spotFromLast(player, st) -- จุดเกิดส่วนตัวตามจุดล่าสุดที่ปลอดภัย (ใช้เมื่อตัวใหม่ถูกสร้างโดยไม่ผ่านการตาย)
			end
			task.wait(SAMPLE_INTERVAL)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	if st then
		local sample = safeSample(player) -- ตัวละครยังอยู่ = ใช้จุดล่าสุดจริงๆ
		if sample then st.last = sample end
		st.savedOnLeave = true
		task.spawn(save, player, st) -- ไม่บล็อก (ลองซ้ำได้หลายวิ) BindToClose รอ pendingSaves ให้
		if st.spawnPart then st.spawnPart:Destroy() end -- จุดเกิดส่วนตัวของคนที่ออก
	end
	states[player] = nil
end)

game:BindToClose(function()
	for player, st in pairs(states) do
		if not st.savedOnLeave then
			local sample = safeSample(player)
			if sample then st.last = sample end
			st.savedOnLeave = true
			task.spawn(save, player, st)
		end
	end
	-- รอให้เซฟครบ (รวมที่เริ่มตอน PlayerRemoving) เดิมรอแค่ 2 วิ · Roblox ให้เวลา BindToClose รวม 30 วิ
	task.wait(0.5)
	local t0 = os.clock()
	while pendingSaves > 0 and os.clock() - t0 < 25 do task.wait(0.2) end
end)
