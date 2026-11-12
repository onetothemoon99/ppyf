-- BACKUP 2026-11-12 before "seats3" (RiversideLog / DuckFloat / KrathongPavilion)
-- Studio path: ServerScriptService.MountSystem.FurnitureService
-- Restore: open that script in Studio, replace its whole Source with everything below the line of dashes.
-- ------------------------------------------------------------
-- FurnitureService: วาง/เก็บของตกแต่งจากตู้สุ่มสัตว์ขี่ (2026-10-16)
--   RemoteFunction RemoteEvents.FurnitureRequest(action, furnId):
--     "place" furnId = วางตรงหน้าตัวเรา (วางได้ทีละ 1 ชิ้น วางชิ้นใหม่ = ชิ้นเก่าหาย) · "pickup" = เก็บ
--   แม่แบบ: ServerStorage.MountFurniture.<id> (Root ใต้ชิ้น หน้า = -Z, Seat1..n ล่องหน)
--   วางไว้ที่ workspace.PlacedFurniture.<UserId> · เจ้าของออกเกม = หาย · ใครก็นั่งได้ (ปุ่ม "นั่ง" ProximityPrompt)
--   ที่นั่งปิด CanTouch: เดินผ่านแล้วไม่นั่งเอง (เสื่อปิกนิกอยู่ระดับพื้น)
--   ปุ่มนั่ง = Seat:Sit(humanoid) · ขี่สัตว์อยู่ = ลงจากหลังก่อน (ServerStorage.MountDismount)
-- 2026-10-16 ผู้ใช้ขอ: ของตกแต่งในกระเป๋ามีปุ่ม "ใช้" -> ไปอยู่แถบช่องด่วน -> ถือแล้วมีไกด์วาง (StarterPlayerScripts.FurniturePlacer)
--   "tool" furnId = ให้ Tool ของตกแต่ง (Attribute IsFurniture / FurnId, ไม่มี Handle) ใส่ Backpack · ไม่เซฟลงกระเป๋า (InventorySystem ข้ามของที่ไม่รู้จัก)
--   Tool หายตอนเกิดใหม่ = ให้ใหม่ตอน CharacterAdded · เข้าเกมใหม่ = ให้ใหม่ถ้าผังช่องที่เซฟไว้มี "FurnId=<id>" (HotbarLayoutQuery)
--   "place" furnId, pos, yaw = วางตรงจุดที่ไกด์เลือก (ห่างตัวไม่เกิน MAX_RANGE) · ไม่ส่ง pos = วางตรงหน้าแบบเดิม

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig"))
local MountOwnership = require(script.Parent:WaitForChild("MountOwnership"))
local templates = ServerStorage:WaitForChild("MountFurniture")
local dismountEvent = ServerStorage:WaitForChild("MountDismount", 30)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local request = remoteEvents:FindFirstChild("FurnitureRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "FurnitureRequest"
	request.Parent = remoteEvents
end

local folder = workspace:FindFirstChild("PlacedFurniture")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "PlacedFurniture"
	folder.Parent = workspace
end

local COOLDOWN = 1.5
local PLACE_DISTANCE = 5 -- สตั๊ด ตรงหน้าตัว
local MAX_STEP = 3 -- พื้นตรงที่วางสูง/ต่ำกว่าเท้าเกินนี้ = วางไม่ได้
local MAX_RANGE = 24 -- วางจากไกด์: ห่างตัว (แนวราบ) ได้ไม่เกินนี้ (ฝั่งผู้เล่นจำกัด 20 เผื่อเดินระหว่างส่ง)
local MAX_STEP_FREE = 8 -- วางจากไกด์: พื้นสูง/ต่ำกว่าเท้าได้ไม่เกินนี้

local lastRequest = {}
local placed = {} -- [player] = model

local function tr(player, th, en)
	local ok, id = pcall(function() return player.LocaleId end)
	if ok and type(id) == "string" and string.sub(id, 1, 2) ~= "th" then return en end
	return th
end

local function removeFor(player)
	local m = placed[player]
	placed[player] = nil
	if m and m.Parent then
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("Seat") and d.Occupant then d.Occupant.Sit = false end
		end
		m:Destroy()
	end
	player:SetAttribute("PlacedFurniture", nil)
end

local function addSitPrompts(model, furnId)
	local def = MountConfig.Furniture[furnId]
	for _, seat in ipairs(model:GetDescendants()) do
		if seat:IsA("Seat") then
			seat.CanTouch = false
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SitPrompt"
			prompt.ActionText = def and def.Pose == "Lie" and "นอน" or "นั่ง"
			prompt.ObjectText = def and def.DisplayName or ""
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = seat
			prompt.Triggered:Connect(function(who)
				local character = who.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 or seat.Occupant then return end
				if who:GetAttribute("RidingMount") and dismountEvent then
					dismountEvent:Fire(who)
					task.wait(0.15)
				end
				if humanoid.SeatPart then return end
				seat:Sit(humanoid)
			end)
			-- ซ่อนปุ่มตอนมีคนนั่งอยู่แล้ว
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				prompt.Enabled = seat.Occupant == nil
			end)
		end
	end
end

-- หาจุดวางตรงหน้าผู้เล่น คืน CFrame (หันหน้าเข้าหาผู้เล่น) หรือ nil, ข้อความ
local function findSpot(player, template, aimPos, aimYaw)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid) or humanoid.Health <= 0 then return nil, tr(player, "ตัวละครยังไม่พร้อม", "Your character isn't ready") end
	if humanoid.SeatPart then return nil, tr(player, "ลุกจากที่นั่งก่อนนะ", "Stand up first") end
	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
	look = look.Unit
	local _, size = template:GetBoundingBox()
	local reach = PLACE_DISTANCE + math.max(size.X, size.Z) / 2
	local target = hrp.Position + look * reach
	local feetY = hrp.Position.Y - humanoid.HipHeight - hrp.Size.Y / 2
	local free = typeof(aimPos) == "Vector3" and type(aimYaw) == "number" and aimPos == aimPos and aimYaw == aimYaw
	if free then
		local flat = (aimPos - hrp.Position) * Vector3.new(1, 0, 1)
		if flat.Magnitude > MAX_RANGE then return nil, tr(player, "ไกลเกินไป เดินเข้าไปใกล้ๆ ก่อนนะ", "Too far, walk closer first") end
		target = aimPos
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { folder }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	local hit = workspace:Raycast(target + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), params)
	if not hit then return nil, tr(player, "ตรงนี้วางไม่ได้ ลองหาพื้นเรียบๆ", "Can't place here, find flat ground") end
	if hit.Material == Enum.Material.Water then return nil, tr(player, "วางในน้ำไม่ได้", "Can't place in water") end
	if math.abs(hit.Position.Y - feetY) > (free and MAX_STEP_FREE or MAX_STEP) then return nil, tr(player, "พื้นตรงนั้นสูง/ต่ำเกินไป", "The ground there is too uneven") end
	-- หน้า (-Z) ของชิ้นหันเข้าหาผู้เล่น · วางจากไกด์ = หันตามที่ผู้เล่นหมุนไว้
	local cf = CFrame.lookAt(hit.Position, hit.Position + look) * CFrame.Angles(0, math.pi, 0)
	if free then cf = CFrame.new(hit.Position) * CFrame.Angles(0, aimYaw % (math.pi * 2), 0) end

	-- ห้ามทับของแข็ง (ผนัง ร้าน ต้นไม้ที่ชนได้) ยกเว้นพื้น Terrain
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignore
	overlap.RespectCanCollide = true
	local boxSize = Vector3.new(size.X * 0.8, math.max(size.Y - 0.6, 1), size.Z * 0.8)
	local boxCf = cf + Vector3.new(0, 0.5 + boxSize.Y / 2, 0)
	for _, part in ipairs(workspace:GetPartBoundsInBox(boxCf, boxSize, overlap)) do
		if not part:IsA("Terrain") and part.CanCollide and part.Transparency < 1 then
			return nil, tr(player, "ตรงนั้นมีของขวางอยู่ ลองขยับไปที่โล่งๆ", "Something is in the way, try an open spot")
		end
	end
	return cf
end

local function place(player, furnId, aimPos, aimYaw)
	local def = MountConfig.Furniture[furnId]
	local template = templates:FindFirstChild(furnId)
	if not (def and template) then return false, tr(player, "ไม่มีของชิ้นนี้", "Unknown item") end
	if not MountOwnership.OwnsFurniture(player, furnId) then return false, tr(player, "ยังไม่มีที่นั่งชิ้นนี้", "You don't own this yet") end
	local cf, message = findSpot(player, template, aimPos, aimYaw)
	if not cf then return false, message end
	removeFor(player)
	local model = template:Clone()
	model.Name = tostring(player.UserId)
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("FurnId", furnId)
	model:PivotTo(cf) -- วางก่อนใส่ workspace (SeatGuard จำตำแหน่งตอนเพิ่มเข้ามา)
	addSitPrompts(model, furnId)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = folder
	placed[player] = model
	player:SetAttribute("PlacedFurniture", furnId)
	return true
end

-- ============ Tool ของตกแต่ง (ปุ่ม "ใช้" ในกระเป๋า -> แถบช่องด่วน -> ถือแล้ววางด้วยไกด์) ============
local heldFurn = {} -- [player] = { [furnId] = true } ชิ้นที่กด "ใช้" แล้ว (ให้ Tool ใหม่ตอนเกิดใหม่)

local function findFurnTool(player, furnId)
	for _, where in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if where then
			for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("IsFurniture") and t:GetAttribute("FurnId") == furnId then return t end
			end
		end
	end
	return nil
end

local function giveTool(player, furnId)
	if not MountConfig.IsEnabled() then return nil end -- ระบบปิดอยู่ = ไม่ให้ Tool ของตกแต่ง (ทั้งตอนเข้าเกม/เกิดใหม่)
	local def = MountConfig.Furniture[furnId]
	if not def or not MountOwnership.OwnsFurniture(player, furnId) then return nil end
	local set = heldFurn[player] or {}
	heldFurn[player] = set
	set[furnId] = true
	local existing = findFurnTool(player, furnId)
	if existing then return existing end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return nil end
	local tool = Instance.new("Tool")
	tool.Name = tr(player, def.DisplayName, def.DisplayNameEn or def.DisplayName)
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = tr(player, "ถือแล้วเลือกจุดวาง", "Hold it, then pick a spot")
	tool:SetAttribute("IsFurniture", true)
	tool:SetAttribute("FurnId", furnId)
	tool.Parent = backpack
	return tool
end

-- เกิดใหม่: Roblox ล้าง Backpack -> ให้ชิ้นที่เคยกด "ใช้" ใหม่ (HotbarState จำช่องเดิมไว้แล้ว)
local function onCharacterAdded(player)
	task.wait(0.5)
	local set = heldFurn[player]
	if not set or not player.Parent then return end
	for furnId in pairs(set) do giveTool(player, furnId) end
end

-- เข้าเกมใหม่: ผังช่องที่เซฟไว้มีของตกแต่งชิ้นไหน = ให้ Tool ชิ้นนั้น (จะกลับไปอยู่ช่องเดิม)
local function restoreToolsOnJoin(player)
	local query = ServerStorage:FindFirstChild("HotbarLayoutQuery")
	local waited, keys = 0, nil
	while player.Parent and waited < 90 do
		keys = MountOwnership.IsLoaded(player) and query and query:Invoke(player) or nil
		if keys then break end
		waited += task.wait(1)
	end
	if not (keys and player.Parent) then return end
	for _, key in pairs(keys) do
		local furnId = type(key) == "string" and string.match(key, "FurnId=([%w_]+)")
		if furnId then giveTool(player, furnId) end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function() onCharacterAdded(player) end)
	task.spawn(restoreToolsOnJoin, player)
end)
for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function() onCharacterAdded(p) end)
	task.spawn(restoreToolsOnJoin, p)
end

request.OnServerInvoke = function(player, action, furnId, aimPos, aimYaw)
	if not MountConfig.IsEnabled() then return { ok = false, message = tr(player, "ระบบยังไม่เปิด", "Not available yet") } end
	if action == "tool" then
		if type(furnId) ~= "string" then return { ok = false } end
		if not MountOwnership.IsLoaded(player) then return { ok = false, message = tr(player, "ข้อมูลยังโหลดไม่เสร็จ", "Still loading") } end
		if not giveTool(player, furnId) then return { ok = false, message = tr(player, "ยังไม่มีที่นั่งชิ้นนี้", "You don't own this yet") } end
		return { ok = true }
	end
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < COOLDOWN then
		return { ok = false, message = tr(player, "ใจเย็นๆ ลองอีกทีนะ", "Slow down, try again") }
	end
	lastRequest[player] = now
	if not MountOwnership.IsLoaded(player) then return { ok = false, message = tr(player, "ข้อมูลยังโหลดไม่เสร็จ", "Still loading") } end
	if action == "place" then
		if type(furnId) ~= "string" then return { ok = false } end
		local ok, message = place(player, furnId, aimPos, aimYaw)
		return { ok = ok, message = message }
	elseif action == "pickup" then
		removeFor(player)
		return { ok = true }
	end
	return { ok = false }
end

-- ============ AFK rejoin: วางคืนที่เดิม + นั่งต่อ (2026-10-16 ผู้ใช้: นั่งตกปลา AFK แล้วต้องตกปลาอยู่ต่อ) ============
-- AfkRejoin เรียก FurnitureSnapshot ก่อนพาย้ายเซิร์ฟ ใส่ไว้ใน TeleportData.furniture = { id, cf = {12 ค่า}, seat = ลำดับที่นั่งที่นั่งอยู่ }
-- เข้ามาใหม่: รอข้อมูลของตกแต่งโหลด + LastPosition วางตัวเสร็จ (SpawnPlaced) -> วางที่เดิม -> นั่งที่เดิม
-- TeleportData แก้ได้จากฝั่งผู้เล่น: ตรวจว่ามีชิ้นนั้นจริง และจุดวางอยู่ใกล้ตัว (ไม่เกิน RESTORE_RANGE)
local RESTORE_RANGE = 30
local snapshotFn = ServerStorage:FindFirstChild("FurnitureSnapshot")
if not snapshotFn then
	snapshotFn = Instance.new("BindableFunction")
	snapshotFn.Name = "FurnitureSnapshot"
	snapshotFn.Parent = ServerStorage
end
snapshotFn.OnInvoke = function(player)
	local m = placed[player]
	if not (m and m.Parent) then return nil end
	local seatIndex = nil
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seatPart = humanoid and humanoid.SeatPart
	if seatPart and seatPart:IsDescendantOf(m) then seatIndex = tonumber(string.match(seatPart.Name, "^Seat(%d+)$")) end
	local comps = { m:GetPivot():GetComponents() }
	for i, v in ipairs(comps) do comps[i] = math.floor(v * 1000 + 0.5) / 1000 end
	return { id = m:GetAttribute("FurnId"), cf = comps, seat = seatIndex }
end

local function restoreAfterRejoin(player, data)
	if type(data) ~= "table" or type(data.id) ~= "string" or type(data.cf) ~= "table" or #data.cf ~= 12 then return end
	local def = MountConfig.Furniture[data.id]
	local template = templates:FindFirstChild(data.id)
	if not (def and template) then return end
	for _, v in ipairs(data.cf) do if type(v) ~= "number" or v ~= v then return end end
	local cf = CFrame.new(table.unpack(data.cf))
	-- เอาแค่หมุนรอบแกนตั้ง กันข้อมูลแปลกๆ วางเอียง
	local look = cf.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then return end
	cf = CFrame.lookAt(cf.Position, cf.Position + look.Unit)
	local waited = 0
	while player.Parent and not player:GetAttribute("SpawnPlaced") and waited < 60 do
		waited += task.wait(0.25)
	end
	-- 2026-10-20 รอข้อมูลสัตว์ขี่/ของตกแต่งนานขึ้น (เดิมรวม 60 วิ เซิร์ฟคนเยอะ DataStore ช้า = ไม่วางคืนเงียบๆ)
	if not MountOwnership.WaitLoaded(player, 90) then
		print("🪑 FurnitureService: ข้อมูลของตกแต่งของ " .. player.Name .. " โหลดไม่ทัน ไม่วางคืน")
		return
	end
	task.wait(0.3)
	if not player.Parent or (placed[player] and placed[player].Parent) then return end -- วางชิ้นใหม่เองไปแล้ว = ไม่วางทับ
	if not MountOwnership.OwnsFurniture(player, data.id) then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid) then return end
	-- 2026-10-20 (ผู้ใช้: AFK กลับมาเฟอร์นิเจอร์หาย ต้องวางใหม่): เดิมตัวอยู่ไกลจากจุดที่วางเกิน RESTORE_RANGE = ไม่วางคืน (วางทิ้งไว้แล้วไป AFK ที่อื่น = หาย)
	-- ตอนนี้วางคืนที่เดิมเสมอถ้าจุดนั้นยังใช้ได้ (มีพื้น ไม่ใช่น้ำ ไม่มีของแข็งขวาง) · พานั่งต่อเฉพาะตอนตัวอยู่ใกล้ (RESTORE_RANGE)
	do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignore = { folder }
		for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
		params.FilterDescendantsInstances = ignore
		params.IgnoreWater = false
		local hit = workspace:Raycast(cf.Position + Vector3.new(0, 6, 0), Vector3.new(0, -12, 0), params)
		if not hit or hit.Material == Enum.Material.Water or math.abs(hit.Position.Y - cf.Position.Y) > 3 then
			print("🪑 FurnitureService: ไม่วางคืน " .. data.id .. " ให้ " .. player.Name .. " (จุดเดิมไม่มีพื้นแล้ว)")
			return
		end
		local _, size = template:GetBoundingBox()
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = ignore
		overlap.RespectCanCollide = true
		local boxSize = Vector3.new(size.X * 0.8, math.max(size.Y - 0.6, 1), size.Z * 0.8)
		for _, part in ipairs(workspace:GetPartBoundsInBox(cf + Vector3.new(0, 0.5 + boxSize.Y / 2, 0), boxSize, overlap)) do
			if not part:IsA("Terrain") and part.CanCollide and part.Transparency < 1 then
				print("🪑 FurnitureService: ไม่วางคืน " .. data.id .. " ให้ " .. player.Name .. " (มีของขวาง " .. part:GetFullName() .. ")")
				return
			end
		end
	end
	local near = (hrp.Position - cf.Position).Magnitude <= RESTORE_RANGE
	local model = template:Clone()
	model.Name = tostring(player.UserId)
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("FurnId", data.id)
	model:PivotTo(cf)
	addSitPrompts(model, data.id)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = folder
	placed[player] = model
	player:SetAttribute("PlacedFurniture", data.id)
	print("🪑 FurnitureService: วาง " .. data.id .. " คืนให้ " .. player.Name .. " หลังกลับจาก AFK")
	local index = tonumber(data.seat)
	local seat = near and index and model:FindFirstChild("Seat" .. math.floor(index))
	if seat and seat:IsA("Seat") then
		task.wait(0.3)
		if humanoid.Health > 0 and not humanoid.SeatPart and not seat.Occupant then
			seat:Sit(humanoid)
			print("🪑 FurnitureService: พา " .. player.Name .. " นั่ง " .. seat.Name .. " ที่เดิม")
		end
	end
end

local function onPlayerAdded(player)
	local ok, joinData = pcall(function() return player:GetJoinData() end)
	local td = ok and type(joinData) == "table" and joinData.TeleportData
	if type(td) == "table" and td.afkRejoin and type(td.furniture) == "table" then
		task.spawn(restoreAfterRejoin, player, td.furniture)
	end
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
-- ทดสอบใน Studio (ย้ายเซิร์ฟไม่ได้): ServerStorage.FurnitureRestoreTest:Fire(player, snapshot)
local restoreTest = ServerStorage:FindFirstChild("FurnitureRestoreTest") or Instance.new("BindableEvent")
restoreTest.Name = "FurnitureRestoreTest"
restoreTest.Parent = ServerStorage
restoreTest.Event:Connect(function(player, data) task.spawn(restoreAfterRejoin, player, data) end)

Players.PlayerRemoving:Connect(function(player)
	removeFor(player)
	lastRequest[player] = nil
	heldFurn[player] = nil
end)
