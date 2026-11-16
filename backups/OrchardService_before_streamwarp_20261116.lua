-- BACKUP 2026-11-16 of game.ServerScriptService.Orchard.OrchardService (Script) before "stream destination before far warp" change.
-- Restore: replace the script's whole Source in Studio with everything BELOW the "==== SOURCE ====" line.
-- ==== SOURCE ====
-- OrchardService: สวนผลไม้ยืนต้น ฝั่งเซิร์ฟเวอร์ (เฟส 1-2, 2026-10-25/26) ค่าดู ReplicatedStorage.OrchardConfig · ข้อมูลดู OrchardData · สรุปทั้งระบบ ORCHARD.md
-- สวน = workspace.Orchard.Lots.Lot01..12 (ล็อกละ Hole1-6 แถวหน้า 1-3 แถวหลัง 4-6 + SignBoard, 2026-10-27 เดิม 5 หลุม) ต้นไม้เป็นของผู้เล่นตลอด (DataStore Orchard_v1) ส่วนล็อกแจกให้ต่อเซิร์ฟ
--   เข้าเซิร์ฟ + มีต้น = ได้ล็อกว่างล็อกแรก · ยังไม่มีต้น = ปลูกลงล็อกว่างไหนก็ได้ (ล็อกนั้นเป็นของเรา) · ออก/ไม่มีต้นแล้ว = คืนล็อก
-- 2026-10-26 (ผู้ใช้): เมล็ดซื้อที่ร้านเมล็ดพันธุ์เหมือนผัก (ShopSystem) เข้ากระเป๋า · ปลูก/เก็บเองที่หลุม · ผลเข้ากระเป๋า ขายที่ร้าน
--   เมล็ด/ผล = Tool IsOrchardSeed / IsOrchardFruit (OrchardItems) เลิกร้านสวน + ตะกร้าผลไม้ (สำรอง ServerStorage._Backup_20261026)
-- ทุกหลุมมี HolePrompt อันเดียว ข้อความตามสถานะ: ว่าง = "ปลูกต้นไม้" (ปลูกเมล็ดที่ถืออยู่ทันที ไม่มีหน้าต่างเลือกแล้ว 2026-10-26) · สุก = "เก็บเกี่ยว" · กำลังโต = "ดูต้นไม้" (ขุดทิ้งได้)
--   ฝั่งผู้เล่น (OrchardGui) ซ่อนปุ่มของล็อกคนอื่น / ล็อกว่างเมื่อเรามีล็อกแล้ว · เซิร์ฟเช็กเจ้าของอีกทีเสมอ
-- RemoteFunction RemoteEvents.OrchardRequest(action, arg): "info" · "plant"({lot, hole, kind}) · "remove"(hole) · RemoteEvent OrchardOpen(mode, data) · OrchardSync(info)
-- ต้นแห้ง (2026-11-02, OrchardConfig.DeadTree): เก็บครบรอบ = tree.dead · HolePrompt State "dead" = เจ้าของกดค้าง "ตัดต้น" (ได้ท่อนไม้)
--   HelpPrompt ทุกหลุม (Attribute CanHelp = ต้นแห้งที่ยังไม่เคยฟื้น) เจ้าของกด = ขอความช่วยเหลือ (แจ้งทั้งเซิร์ฟ) · คนอื่นกดค้าง = รดน้ำช่วย (ต้นฟื้น + คนช่วยได้เหรียญช่วยเหลือ)
--   ถือปุ๋ยไม้ผลแล้วกด HolePrompt ที่ต้นที่กำลังโต = ใส่ปุ๋ย (ลดเวลา FertilizerSeconds รอบละ 1 ครั้ง)
--   "buySkin"(Id) / "equipSkin"(Id) ลายแปลงปลูก (OrchardConfig.HoleSkins, แท็บ "แต่งแปลง" ในร้านผลไม้ & อุปกรณ์ (ReplicatedStorage.OrchardSkinTab)) 2026-10-28
-- ลำดับกันของหาย/เบิ้ล: ปลูก = หักเมล็ด -> เซฟสวน (ไม่ได้ = คืนเมล็ด) · เก็บ = เซฟสวน (รอบใหม่) -> ค่อยให้ผล · ทั้งคู่สั่งเซฟกระเป๋าทันที
-- Studio: ServerStorage.OrchardDev (BindableFunction) dev(player, action, a, b) — ต้องตั้ง workspace DevOrchardKeyOverride (คีย์ปลอม) ก่อน
--   "plant"(kind, hole) · "seed"(kind) ให้เมล็ด · "fruit"(kind, n) · "clear" · "info" · "setCoins"(ค่า) ตั้งเหรียญคืนหลังทดสอบ (ไม่โดน CheatWatch จด) · เร่งเวลา: workspace DevOrchardTimeSkip
--   เจ้าของปลอม (ทดสอบขโมยคนเดียว 2026-10-27): "fakeowner"(จำนวนต้น, "grow") · "fakeslap" · "fakeclear" · "hand"(n) ให้ตะกร้อขโมย (ไม่ต้องตั้งคีย์ปลอม)
--   ยามเฝ้าสวน (NPC จาก ServerStorage.OrchardTemplates.FakeGuard) ยืนกลางล็อกเจ้าของปลอม เห็นคนขโมยแล้วเดินมาตบ · "fakeguard"(false) ปิดยาม (ทดสอบขโมยสำเร็จ) / (true) เปิด

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("OrchardConfig"))
local OrchardData = require(script.Parent:WaitForChild("OrchardData"))
local OrchardItems = require(script.Parent:WaitForChild("OrchardItems"))
local LevelSystem = require(ServerScriptService:WaitForChild("LevelSystem"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local CheatWatch = require(ServerScriptService:WaitForChild("CheatWatch"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")
local function remote(className, name)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local requestRemote = remote("RemoteFunction", "OrchardRequest")
local syncRemote = remote("RemoteEvent", "OrchardSync")
local openRemote = remote("RemoteEvent", "OrchardOpen")

local zone = workspace:WaitForChild("Orchard", 30)
if not zone then
	warn("OrchardService: ไม่เจอ workspace.Orchard หยุดทำงาน")
	return
end

-- ============ ซ่อนทั้งระบบ (OrchardConfig.Enabled = false) ============
-- ปิดอยู่ = ซ่อนสวนแล้วรอ ผู้ทดสอบ (Config.TESTERS) เข้ามาจาก Studio (ทดสอบเป็นทีม) = เปิดสวนในเซิร์ฟนี้แล้วทำงานต่อตามปกติ (2026-10-30)
local studioHello = remote("RemoteEvent", "OrchardStudioHello")
print(string.format("[Orchard] start: Enabled=%s DEV_ONLY=%s IsStudio=%s JobId=%q", tostring(Config.Enabled), tostring(Config.DEV_ONLY), tostring(RunService:IsStudio()), game.JobId))
if not Config.Enabled then
	zone.Parent = ServerStorage
	requestRemote.OnServerInvoke = function()
		return { ok = false, info = { Enabled = false, Loaded = false } }
	end
	local opened = Instance.new("BindableEvent")
	studioHello.OnServerEvent:Connect(function(player)
		if Config.Enabled then return end
		if not (Config.TESTERS and Config.TESTERS[player.UserId]) then
			print("[Orchard] Studio client ที่ไม่อยู่ใน TESTERS: " .. player.Name .. " (" .. player.UserId .. ")")
			return
		end
		Config.Enabled = true -- โมดูลใช้ร่วมทั้งเซิร์ฟ (ShopSystem เห็นค่าใหม่ทันที)
		print("[Orchard] เปิดสวนในเซิร์ฟนี้ (ทดสอบเป็นทีม) จาก " .. player.Name)
		opened:Fire()
	end)
	opened.Event:Wait()
	zone.Parent = workspace
end

local REFRESH_EVERY = 5
local AUTOSAVE_EVERY = 60
local REQUEST_COOLDOWN = 0.1 -- กันกดรัวต่อคำสั่ง (ผู้ใช้สั่งลด 0.4 -> 0.1 วิ 2026-10-30)
local SAVE_FAIL_TH, SAVE_FAIL_EN = "ระบบบันทึกขัดข้อง ลองใหม่อีกครั้ง", "Saving failed, please try again"

local templates = ServerStorage:WaitForChild("OrchardTemplates") -- ต้นไม่มีผล (ชื่อ = ชนิดต้น) ผล/ดอกสร้างเพิ่มตามขั้น
local saveCoinsNow = ServerScriptService:WaitForChild("LeaderstatsSetup"):WaitForChild("SaveCoinsNow", 30)
local saveInventoryNow = ServerScriptService:WaitForChild("InventorySystem"):WaitForChild("SaveInventoryNow", 30)

local lots = {}
local lotByName = {}
for _, lot in ipairs(zone:WaitForChild("Lots"):GetChildren()) do
	if lot:IsA("Model") and lot:FindFirstChild("Hole1") then
		table.insert(lots, lot)
		lotByName[lot.Name] = lot
	end
end
table.sort(lots, function(a, b) return a.Name < b.Name end)

local lotOf = {} -- [player] = lot
local ownerOf = {} -- [lot] = player
local joinOrder = {} -- [player] = os.clock() ตอนโหลดเสร็จ (คิวรอล็อก)
local busy = {} -- [player] = true
local lastRequest = {} -- [player] = os.clock()

-- Studio: เจ้าของปลอม (OrchardDev "fakeowner") ไม่ใช่ Player จริง = ไม่ส่ง Remote ไม่เซฟ ข้อมูลอยู่ในหน่วยความจำ หายเมื่อหยุด Play
local fakeOwner, fakeState = nil, nil
local fakeGuard, guardPost, guardOn = nil, nil, true -- NPC ยามเฝ้าสวนของเจ้าของปลอม / จุดยืน / เปิดไล่ตบไหม
local onFakeAttempt -- (ตั้งในส่วนทดสอบใน Studio) มีคนเริ่มขโมยต้นเจ้าของปลอม = ยามเดินมาตบ
-- เจ้าของปลอมเต็มสวน (Studio DevOrchardFakeDeadAll 2026-11-03): [ตัวปลอม] = state แบบเดียวกับ fakeState
local fakeExtras = {}
local function isFake(p) return p ~= nil and ((fakeOwner ~= nil and p == fakeOwner) or fakeExtras[p] ~= nil) end
local function stateOf(p)
	if fakeOwner ~= nil and p == fakeOwner then return fakeState end
	if p ~= nil and fakeExtras[p] then return fakeExtras[p] end
	return OrchardData.Get(p)
end

local function lang(player)
	if isFake(player) then return "th" end
	return Localization.GetLanguage(player)
end
local function msg(player, thai, english)
	return Localization.Pick(lang(player), thai, english)
end
local function notify(player, text)
	if text and isFake(player) then print("[เจ้าของปลอม] " .. text) return end
	if text then harvestNotify:FireClient(player, nil, nil, nil, text) end
end
local function saveBag(player)
	if saveInventoryNow then saveInventoryNow:Fire(player) end
end
local function coinsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("เหรียญ")
end
local function lotNo(lot)
	return lot and (lot.Name:gsub("Lot0?", "")) or "-"
end

-- ============ ป้ายล็อก ============
local function setSign(lot, player)
	local board = lot:FindFirstChild("SignBoard")
	local gui = board and board:FindFirstChildWhichIsA("SurfaceGui")
	local label = gui and gui:FindFirstChild("OwnerLabel")
	if not label then return end
	if player then
		label.Text = "🌳 สวนของ\n" .. player.DisplayName
		label.TextColor3 = Color3.fromRGB(255, 245, 210)
	else
		label.Text = "🌳 ล็อกว่าง\nFree lot"
		label.TextColor3 = Color3.fromRGB(215, 205, 180)
	end
end

-- ============ หน้าตาต้น ============
local function treesFolder(lot)
	local f = lot:FindFirstChild("Trees")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Trees"
		f.Parent = lot
	end
	return f
end

local function decorPart(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

-- ============ ลายแปลงปลูก (สกินหลุม 2026-10-28) ============
-- แต่ละหลุมมีโมเดล "Decor" (ขอบ/ดิน/หินเดิม) เปลี่ยนลาย = ลบ Decor แล้ว clone ReplicatedStorage.OrchardHoleSkins.<Id> มาวางกลางหลุม
-- Decor เดิมของหลุมไม่มี Attribute Skin = Classic อยู่แล้ว ไม่ต้องสร้างใหม่ (ตอนเปิดเซิร์ฟ clearLot ทุกล็อกไม่เสียแรง)
local holeSkins = ReplicatedStorage:WaitForChild("OrchardHoleSkins")
local function applySkin(lot, skinId)
	if not (skinId and Config.HoleSkinById[skinId] and holeSkins:FindFirstChild(skinId)) then skinId = "Classic" end
	for i = 1, Config.MAX_TREES do
		local hole = lot:FindFirstChild("Hole" .. i)
		local cur = hole and hole:FindFirstChild("Decor")
		if hole and (cur and cur:GetAttribute("Skin") or "Classic") ~= skinId then
			if cur then cur:Destroy() end
			local decor = holeSkins[skinId]:Clone()
			decor.Name = "Decor"
			decor:SetAttribute("Skin", skinId)
			decor:PivotTo(CFrame.new(hole.Position))
			decor.Parent = hole
		end
	end
end

local function addBall(parent, name, size, color, material, cf)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1, 1, 1)
	p.Color = color
	p.Material = material
	decorPart(p)
	p.CFrame = cf
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = size
	mesh.Parent = p
	p.Parent = parent
	return p
end

-- สร้างต้น 1 ต้นตามขั้น วางบนหลุม (สุ่มมุมหมุนแบบคงที่ต่อหลุม ต้นไม่หมุนไปมาทุกครั้งที่เปลี่ยนขั้น)
local function buildTree(hole, kind, stage, fruits, seed, needsHelp, stolen)
	local def = Config.Trees[kind]
	local model = Instance.new("Model")
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- มือถือไม่ได้ต้นครึ่งต้น
	-- ผลสุก + มีเทมเพลตต้นสุก (เช่น MangoRipe ผลอยู่ในพื้นผิว) = ใช้โมเดลนั้น ไม่ต่อผลเพิ่ม
	-- ถูกขโมยไปแล้ว (2026-11-03): ต้นสุกเต็มต้นดูเหมือนไม่มีอะไรหาย → ใช้ต้นปกติ + ผลสุกห้อยเท่าที่เหลือจริง
	local ripeTemplate = stage == "Ripe" and fruits > 0 and (stolen or 0) == 0 and def.RipeTemplate and templates:FindFirstChild(def.RipeTemplate)
	-- ต้นแห้ง (2026-11-03): โมเดลเฉพาะ มีแค่ลำต้น กิ่ง ก้านแห้ง ไม่มีใบ
	local deadTemplate = stage == "Dead" and Config.DeadTree.Template and templates:FindFirstChild(Config.DeadTree.Template)
	local body = (deadTemplate or ripeTemplate or templates:FindFirstChild(kind) or templates:FindFirstChildWhichIsA("Model")):Clone()
	body.Name = "Body"
	for _, p in ipairs(body:GetDescendants()) do
		if p:IsA("BasePart") then decorPart(p) end
		-- ต้นแห้ง (2026-11-02): ต้นเป็น MeshPart ชิ้นเดียวมีเท็กเจอร์ เอาเท็กเจอร์ออกแล้วทาสีน้ำตาลแห้งทั้งต้น
		if stage == "Dead" and not deadTemplate then
			if p:IsA("MeshPart") then p.TextureID = "" end
			if p:IsA("SurfaceAppearance") then p:Destroy() end
			if p:IsA("BasePart") then
				p.Color = Color3.fromRGB(125, 98, 70)
				p.Material = Enum.Material.Wood
			end
		end
	end
	if deadTemplate then
		local _, size0 = body:GetBoundingBox()
		body:ScaleTo(body:GetScale() * (Config.DeadTree.Height or 11) / size0.Y)
	elseif ripeTemplate then
		local _, size0 = body:GetBoundingBox()
		body:ScaleTo(body:GetScale() * (def.RipeHeight or 13) / size0.Y)
	else
		body:ScaleTo(def.Scale * (Config.StageScale[stage] or 1))
	end
	local groundY = hole.Position.Y + hole.Size.Y / 2
	local yaw = math.rad((seed * 137) % 360)
	body:PivotTo(CFrame.new(hole.Position.X, groundY, hole.Position.Z) * CFrame.Angles(0, yaw, 0))
	local cf, size = body:GetBoundingBox()
	body:PivotTo(body:GetPivot() + Vector3.new(0, groundY - (cf.Y - size.Y / 2) - 0.3, 0))
	body.Parent = model
	cf, size = body:GetBoundingBox() -- cf หมุนตามต้น จุดบนพุ่มใบคิดในแกนของต้น (พุ่มใบกว้าง/ลึกไม่เท่ากัน)

	-- ลำต้นชนได้ (ต้นโตแล้ว)
	if stage ~= "Sapling" then
		local trunk = Instance.new("Part")
		trunk.Name = "TrunkCollider"
		trunk.Size = Vector3.new(1.4, size.Y * 0.5, 1.4)
		trunk.Transparency = 1
		trunk.Anchored = true
		trunk.CanCollide = true
		trunk.CanQuery = false
		trunk.CanTouch = false
		trunk.CFrame = CFrame.new(hole.Position.X, groundY + size.Y * 0.25, hole.Position.Z)
		trunk.Parent = model
	end

	local rng = Random.new(seed)
	if stage == "Dead" then
		-- ใบแห้งร่วงช้าๆ จากพุ่ม
		local fall = Instance.new("Part")
		fall.Name = "DeadLeaves"
		fall.Size = Vector3.new(size.X * 0.8, 0.2, size.Z * 0.8)
		fall.Transparency = 1
		decorPart(fall)
		fall.CFrame = cf * CFrame.new(0, size.Y * 0.2, 0)
		local leaves = Instance.new("ParticleEmitter")
		leaves.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		leaves.Color = ColorSequence.new(Color3.fromRGB(190, 120, 50), Color3.fromRGB(150, 95, 45))
		leaves.Size = NumberSequence.new(0.35)
		leaves.Lifetime = NumberRange.new(3, 4)
		leaves.Rate = 2
		leaves.Speed = NumberRange.new(0.2, 0.6)
		leaves.Acceleration = Vector3.new(0.4, -1.2, 0)
		leaves.RotSpeed = NumberRange.new(-90, 90)
		leaves.SpreadAngle = Vector2.new(180, 180)
		leaves.Parent = fall
		fall.Parent = model
		-- 2026-11-07 ผู้ใช้สั่ง: ต้นแห้งรอเพื่อนช่วยไม่มีออร่าเหลืองแล้ว (เดิม HelpAura/HelpGlow/PointLight/HelpRing) หน้าตาเหมือนต้นแห้งธรรมดา
	elseif stage == "Flower" then
		for i = 1, 10 do
			local a = rng:NextNumber() * math.pi * 2
			local up = rng:NextNumber(0.0, 0.3)
			local pos = cf:PointToWorldSpace(Vector3.new(math.cos(a) * size.X * 0.4, size.Y * up, math.sin(a) * size.Z * 0.4))
			local color = i % 2 == 0 and Color3.fromRGB(255, 250, 235) or Color3.fromRGB(255, 205, 225)
			addBall(model, "Flower", Vector3.new(0.7, 0.7, 0.7), color, Enum.Material.SmoothPlastic, CFrame.new(pos))
		end
	elseif ripeTemplate then
		-- (2026-11-07 ผู้ใช้สั่ง: ต้นสุกไม่มีเอฟเฟกต์แล้ว เดิม RipeGlow = ประกาย RipeSparkle + ฝุ่น GoldMotes + แสง GoldLight)
	elseif (stage == "Green" or stage == "Ripe") and fruits > 0 then
		local color = stage == "Ripe" and def.RipeColor or def.GreenColor
		local start = rng:NextNumber() * math.pi * 2
		for i = 1, fruits do
			local a = start + (i - 1) * (math.pi * 2 / fruits)
			-- ผลห้อยที่ขอบพุ่มใบด้านนอก เห็นได้จากพื้น
			local pos = cf:PointToWorldSpace(Vector3.new(math.cos(a) * size.X * 0.48, -size.Y * 0.04, math.sin(a) * size.Z * 0.48))
			local fruit = addBall(model, "Fruit", def.FruitSize, color, def.FruitMaterial, CFrame.new(pos))
			local stem = Instance.new("Part")
			stem.Name = "Stem"
			stem.Size = Vector3.new(0.15, 0.9, 0.15)
			stem.Color = Color3.fromRGB(95, 70, 40)
			stem.Material = Enum.Material.Wood
			decorPart(stem)
			stem.CFrame = CFrame.new(pos + Vector3.new(0, def.FruitSize.Y / 2 + 0.35, 0))
			stem.Parent = model
			-- (ประกายที่ผลตอนสุก ลบออก 2026-11-07 ผู้ใช้สั่ง)
		end
	end

	-- ป้ายเหนือต้น (ชื่อ/ขั้น/นับถอยหลัง) สร้างฝั่งผู้เล่นที่ LabelAnchor (OrchardGui) ตามภาษาของแต่ละคน
	local anchor = Instance.new("Part")
	anchor.Name = "LabelAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	decorPart(anchor)
	anchor.CFrame = CFrame.new(hole.Position.X, cf.Y + size.Y / 2 + 1, hole.Position.Z)
	anchor.Parent = model
	return model
end

-- ปุ่มที่หลุม: ตั้งข้อความ/เปิดปิดตามสถานะ (State = "empty" / "grow" / "ripe") ฝั่งผู้เล่นแปลอังกฤษเอง
local function setHolePrompt(hole, state, kind, cutOnly)
	local prompt = hole and hole:FindFirstChild("HolePrompt")
	if not prompt then return end
	prompt:SetAttribute("State", state)
	local def = kind and Config.Trees[kind]
	if state == "dead" then
		prompt.ActionText = "ตัดต้น"
		-- แห้งรอบ 2 (เคยฟื้นแล้ว) = ไม่มีปุ่มขอความช่วยเหลือ บอกให้ชัดว่าตัดได้อย่างเดียว (2026-11-07 ผู้ใช้สั่ง) · OrchardGui แปลอังกฤษ
		prompt.ObjectText = "🍂 " .. (def and def.NameTh or "") .. "แห้ง" .. (cutOnly and " (ตัดได้อย่างเดียว)" or "")
		prompt.HoldDuration = Config.DeadTree.CutSeconds
	elseif state == "ripe" then
		prompt.ActionText = "เก็บเกี่ยว"
		prompt.ObjectText = def and (def.Icon .. " " .. def.NameTh) or ""
		prompt.HoldDuration = 0.6
	elseif state == "grow" then
		prompt.ActionText = "ดูต้นไม้"
		prompt.ObjectText = def and (def.Icon .. " " .. def.NameTh) or ""
		prompt.HoldDuration = 0
	else
		prompt.ActionText = "ปลูกต้นไม้"
		prompt.ObjectText = "🕳️ หลุม " .. hole.Name:gsub("Hole", "")
		prompt.HoldDuration = 0
	end
end

-- ============ มือขโมย (เฟส 3, 2026-10-26) ============
-- ทุกหลุมมี StealPrompt (กดค้างตาม Steal.Seconds) เซิร์ฟตั้ง Attribute CanSteal ตามต้น · ฝั่งผู้เล่น (OrchardGui) โชว์เฉพาะตอนถือมือขโมย + ต้นคนอื่น + CanSteal
-- ต้นของคนอื่นมีในสวนเฉพาะตอนเจ้าของอยู่เซิร์ฟนี้ = ขโมยได้เฉพาะตอนเจ้าของอยู่ (ผู้ใช้เลือก)
local Steal = Config.Steal
local attempts = {} -- [คนขโมย] = { owner, lot, holeNo, hole, prompt, slap } กำลังกดค้างขโมยอยู่ (actions.harvest ใช้ล็อกต้น จึงต้องประกาศก่อน)
local caughtUntil = {} -- [hole] = os.clock() ที่ต้นนี้พักถึง (เจ้าของตบจับขโมยได้ เฟส 4)

local function cooling(hole)
	local t = hole and caughtUntil[hole]
	return t ~= nil and os.clock() < t
end

local function canBeStolen(tree, now)
	return tree ~= nil and Config.StageAt(tree, now) == "Ripe"
		and tree.fruits > (Steal.KeepForOwner or 1) and (tree.stolen or 0) < (Steal.PerCycle or 1)
end

local function setStealPrompt(hole, tree, now)
	local prompt = hole and hole:FindFirstChild("StealPrompt")
	if not prompt then return end
	local ok = canBeStolen(tree, now) and not cooling(hole)
	if prompt:GetAttribute("CanSteal") ~= ok then prompt:SetAttribute("CanSteal", ok) end
	if ok then
		local def = Config.Trees[tree.kind]
		prompt.HoldDuration = Steal.Seconds[tree.kind] or 30 -- ตะกร้อธรรมดา · ถือตะกร้อจอมโจร = OrchardGui ลดเวลาฝั่งผู้เล่นเอง (อ่าน Attribute TreeKind)
		prompt:SetAttribute("TreeKind", tree.kind)
		prompt.ObjectText = def.Icon .. " " .. def.NameTh
	end
end

-- ปุ่มช่วยต้นแห้ง (2026-11-02): CanHelp = ต้นแห้งที่ยังไม่เคยฟื้น · ฝั่งผู้เล่น (OrchardGui) ตั้งคำ/เวลากดค้างตามว่าเป็นเจ้าของไหม
local function setHelpPrompt(hole, tree)
	local prompt = hole and hole:FindFirstChild("HelpPrompt")
	if not prompt then return end
	local ok = tree ~= nil and tree.dead == true and not tree.revived
	if prompt:GetAttribute("CanHelp") ~= ok then prompt:SetAttribute("CanHelp", ok) end
	if ok then
		local def = Config.Trees[tree.kind]
		prompt.ObjectText = "🍂 " .. (def and def.NameTh or "") .. "แห้ง"
	end
end

-- วาดต้นของผู้เล่นในล็อกให้ตรงข้อมูล (สร้างใหม่เฉพาะต้นที่ขั้น/ผลเปลี่ยน)
local function render(player)
	local lot = lotOf[player]
	local st = stateOf(player)
	if not (lot and st and st.loaded) then return end
	local folder = treesFolder(lot)
	local now = OrchardData.Now()
	for i = 1, Config.MAX_TREES do
		local hole = lot:FindFirstChild("Hole" .. i)
		local tree = st.data.trees[tostring(i)]
		local existing = folder:FindFirstChild("Tree" .. i)
		if not (tree and hole) then
			if existing then existing:Destroy() end
			setHolePrompt(hole, "empty")
			setStealPrompt(hole, nil, now)
			setHelpPrompt(hole, nil)
		else
			-- ผลรอบนี้โดนขโมยหมด (2026-11-06 ผู้ใช้สั่ง: ถูกขโมยแล้วเก็บไม่ได้) ต้นเริ่มรอบใหม่เองทันที นับเป็น 1 รอบเก็บเหมือนเดิม (เดิมค้างสุก ต้องกดเก็บได้ 0 ผล) · รวมต้นที่ค้างจากข้อมูลเก่า
			if tree.fruits <= 0 and not tree.dead and Config.StageAt(tree, now) == "Ripe" then
				OrchardData.StartNewCycle(tree, now)
				tree.harvests = (tree.harvests or 0) + 1
				if Config.HarvestsLeft(tree) == 0 then tree.dead = true end
				if not isFake(player) then OrchardData.SaveLater(player) end
			end
			local stage, nextAt = Config.StageAt(tree, now)
			local same = existing
				and existing:GetAttribute("Kind") == tree.kind
				and existing:GetAttribute("Stage") == stage
				and existing:GetAttribute("Fruits") == tree.fruits
				and existing:GetAttribute("Stolen") == ((tree.stolen or 0) > 0 or nil)
				and existing:GetAttribute("NeedsHelp") == ((tree.dead == true and not tree.revived) or nil) -- ออร่าเหลืองต้นแห้ง
			if not same then
				if existing then existing:Destroy() end
				existing = buildTree(hole, tree.kind, stage, tree.fruits, player.UserId % 997 + i * 31, tree.dead == true and not tree.revived, tree.stolen)
				existing.Name = "Tree" .. i
				existing:SetAttribute("Owner", player.Name)
				existing:SetAttribute("OwnerId", player.UserId)
				existing:SetAttribute("Slot", i)
				existing:SetAttribute("Kind", tree.kind)
				existing:SetAttribute("Stage", stage)
				existing:SetAttribute("Fruits", tree.fruits)
				existing:SetAttribute("Stolen", (tree.stolen or 0) > 0 or nil)
				existing:SetAttribute("NeedsHelp", (tree.dead == true and not tree.revived) or nil)
				existing.Parent = folder
			end
			existing:SetAttribute("NextAt", nextAt or 0)
			existing:SetAttribute("RipeAt", Config.RipeAt(tree) or 0) -- ป้ายเหนือต้นนับถอยหลังถึงผลสุก
			existing:SetAttribute("HarvestsLeft", (not tree.dead) and Config.HarvestsLeft(tree) or nil) -- ป้ายเหนือต้น (nil = ไม่จำกัด)
			existing:SetAttribute("CanRevive", (tree.dead and not tree.revived) or nil) -- ต้นแห้งที่เพื่อนยังช่วยได้ (ป้ายเหนือต้น)
			existing:SetAttribute("Fed", (tree.fed ~= nil and tree.fed == tree.cycleStart) or nil) -- ใส่ปุ๋ยรอบนี้แล้ว
			setHolePrompt(hole, stage == "Dead" and "dead" or (stage == "Ripe" and "ripe" or "grow"), tree.kind, tree.revived == true)
			setStealPrompt(hole, tree, now)
			setHelpPrompt(hole, tree)
		end
	end
end

-- ============ แจก/คืนล็อก ============
local function clearLot(lot)
	local f = lot:FindFirstChild("Trees")
	if f then f:ClearAllChildren() end
	lot:SetAttribute("OwnerId", nil)
	for i = 1, Config.MAX_TREES do
		setHolePrompt(lot:FindFirstChild("Hole" .. i), "empty") -- ล็อกว่าง: ใครยังไม่มีล็อกก็มาปลูกจองได้
		setStealPrompt(lot:FindFirstChild("Hole" .. i), nil, 0)
		setHelpPrompt(lot:FindFirstChild("Hole" .. i), nil)
	end
	setSign(lot, nil)
	applySkin(lot, nil)
end

local function assignLot(player, lot)
	ownerOf[lot], lotOf[player] = player, lot
	lot:SetAttribute("OwnerId", player.UserId)
	player:SetAttribute("OrchardLot", lot.Name)
	setSign(lot, player)
	local st = stateOf(player)
	applySkin(lot, st and st.data and st.data.skin)
	render(player)
end

-- ให้ล็อกว่างล็อกแรก (มีอยู่แล้ว = คืนอันเดิม) คืน lot หรือ nil ถ้าสวนเต็ม
local function ensureLot(player)
	if lotOf[player] then return lotOf[player] end
	-- ล็อกที่จำไว้ (d.lot 2026-11-06) ยังว่าง = กลับที่เดิม ไม่ว่าง = ล็อกว่างแรกตามเดิม
	local saved = stateOf(player)
	local wantName = saved and saved.data and saved.data.lot
	if wantName then
		for _, lot in ipairs(lots) do
			if lot.Name == wantName and not ownerOf[lot] then
				assignLot(player, lot)
				return lot
			end
		end
	end
	for _, lot in ipairs(lots) do
		if not ownerOf[lot] then
			assignLot(player, lot)
			return lot
		end
	end
	player:SetAttribute("OrchardLot", nil)
	return nil
end

-- มีต้นอยู่ = ต้องมีล็อกไว้แสดงต้น
local function needsLot(player)
	local st = OrchardData.Get(player)
	return st ~= nil and st.loaded and OrchardData.TreeCount(st.data) > 0
end

-- ล็อกว่างแล้ว: ให้คนที่มีต้นแต่ยังไม่มีล็อก (โหลดเสร็จก่อนได้ก่อน)
local function giveFreeLots()
	local waiting = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if not lotOf[p] and needsLot(p) then table.insert(waiting, p) end
	end
	table.sort(waiting, function(a, b) return (joinOrder[a] or 0) < (joinOrder[b] or 0) end)
	for _, p in ipairs(waiting) do
		if not ensureLot(p) then break end
	end
end

local function releaseLot(player)
	local lot = lotOf[player]
	if not lot then return end
	lotOf[player], ownerOf[lot] = nil, nil
	player:SetAttribute("OrchardLot", nil)
	clearLot(lot)
	task.defer(giveFreeLots)
end

-- ปุ่ม HolePrompt ทุกหลุม (ต่อ Triggered ด้านล่าง)
for _, lot in ipairs(lots) do
	for i = 1, Config.MAX_TREES do
		local hole = lot:FindFirstChild("Hole" .. i)
		if hole and not hole:FindFirstChild("HolePrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "HolePrompt"
			prompt.MaxActivationDistance = 9
			prompt.RequiresLineOfSight = false
			prompt.Parent = hole
		end
		-- ปุ่ม "ขโมย" (เฟส 3) เซิร์ฟไม่แตะ Enabled อีก ฝั่งผู้เล่นเปิด/ปิดเองตาม CanSteal + ถือมือขโมย
		if hole and not hole:FindFirstChild("StealPrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "StealPrompt"
			prompt.ActionText = "ขโมย"
			prompt.MaxActivationDistance = Steal.Range
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = 30
			prompt:SetAttribute("CanSteal", false)
			prompt.Parent = hole
		end
		-- ปุ่มช่วยต้นแห้ง (2026-11-02) เซิร์ฟไม่แตะ Enabled ฝั่งผู้เล่นเปิด/ปิดตาม CanHelp
		if hole and not hole:FindFirstChild("HelpPrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "HelpPrompt"
			prompt.ActionText = "รดน้ำช่วย"
			prompt.MaxActivationDistance = Config.DeadTree.HelpRange
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = Config.DeadTree.HelpSeconds
			prompt.KeyboardKeyCode = Enum.KeyCode.F
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
			prompt.UIOffset = Vector2.new(0, 70)
			prompt.Enabled = false
			prompt:SetAttribute("CanHelp", false)
			prompt.Parent = hole
		end
	end
	clearLot(lot)
end

-- ============ ข้อมูลให้ฝั่งผู้เล่น ============
local function seedCounts(player)
	local seeds = {}
	for kind in pairs(Config.Trees) do seeds[kind] = OrchardItems.CountOf(player, OrchardItems.SEED, kind) end
	return seeds
end

local function snapshot(player)
	local st = OrchardData.Get(player)
	local info = {
		Enabled = Config.Enabled, Loaded = st ~= nil and st.loaded == true,
		Level = LevelSystem.GetLevel(player), MinLevel = Config.MIN_LEVEL,
		Lot = lotOf[player] and lotOf[player].Name or nil,
	}
	if not info.Loaded then return info end
	local now = OrchardData.Now()
	info.Now = now
	info.Seeds = seedCounts(player)
	info.Skins = table.clone(st.data.skins or {})
	info.Skin = st.data.skin or "Classic"
	info.Trees = {}
	for i = 1, Config.MAX_TREES do
		local tr = st.data.trees[tostring(i)]
		if tr then
			local stage, nextAt = Config.StageAt(tr, now)
			info.Trees[tostring(i)] = { Kind = tr.kind, Stage = stage, NextAt = nextAt, RipeAt = Config.RipeAt(tr), Fruits = tr.fruits, HarvestsLeft = (not tr.dead) and Config.HarvestsLeft(tr) or nil, Revived = tr.revived }
		end
	end
	info.HelpCoins = st.data.help and st.data.help.coins or 0
	return info
end

local function sync(player)
	if isFake(player) then return end
	syncRemote:FireClient(player, snapshot(player))
end

local function reply(player, ok, message)
	return { ok = ok, message = message, info = snapshot(player) }
end

-- เปลี่ยนข้อมูล -> เซฟจริงทันที (ต้นไม้ราคาหลักแสน-ล้าน) เซฟไม่ได้ = คืนค่าเดิม คืน true/false
local function commit(player, st, change)
	local before = table.clone(st.data)
	before.trees = {}
	for k, v in pairs(st.data.trees) do before.trees[k] = table.clone(v) end
	before.stats = table.clone(st.data.stats)
	before.skins = table.clone(st.data.skins or {})
	-- เหรียญช่วยเหลือ + ตู้แลกน้ำใจ (2026-11-03) เซฟไม่ได้ต้องคืนค่าเดิมครบ (ตารางซ้อนกัน)
	if st.data.help then
		before.help = table.clone(st.data.help)
		before.help.owners = table.clone(st.data.help.owners or {})
	end
	if st.data.shop then
		before.shop = table.clone(st.data.shop)
		before.shop.titles = table.clone(st.data.shop.titles or {})
		before.shop.buys = table.clone(st.data.shop.buys or {})
		before.shop.backs = table.clone(st.data.shop.backs or {})
	end
	if change(st.data) == false then return false end
	if isFake(player) then return true end -- เจ้าของปลอมไม่เซฟ
	if not OrchardData.SaveNow(player, 10) then
		st.data = before
		return false
	end
	return true
end

-- จุดที่ผู้เล่นยืนอยู่ใกล้หลุมไหม (แนวนอน)
local function nearHole(player, hole)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and hole) then return false end
	return (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude <= Config.HARVEST_DISTANCE
end

local actions = {}

-- ปลูกเมล็ดจากกระเป๋า: arg = { ชื่อล็อก, หลุม, ชนิด } · ล็อกต้องเป็นของเรา หรือว่างและเรายังไม่มีล็อก (= จองล็อกนั้น)
-- ท่าปลูก (ผู้ใช้สั่ง 2026-11-02): ตัวละครก้มลง เอื้อมมือขวาลงหลุม (Attribute OrchardPlantAt ให้ OrchardGui ทำท่า ~1 วิ)
--   + เมล็ดหล่นจากมือลงหลุม + ดินฟุ้งเล็กน้อย · เรียกตอนหักเมล็ดแล้ว (ก่อนรอเซฟ ท่าจะได้ไม่ช้าตาม DataStore)
local plantToken = {} -- [player] = ตัวเลขรอบท่าปลูก
-- 2026-11-15 ผู้ใช้สั่ง: ผู้เล่นปลูก = ทำท่าค้างไปเรื่อยๆ จนได้ข้อความปลูกสำเร็จ/ไม่สำเร็จ (actions.plant เรียก plantPoseDone ก่อน reply ทันที ไม่มีดีเลย์)
--   PLANT_POSE_MAX = กันท่าค้างถ้าเซฟค้าง/สคริปต์ error · NPC (ไม่ส่ง hold) ยังทำท่า 1.1 วิเหมือนเดิม
local PLANT_POSE_MAX = 8
local function plantPoseDone(player)
	plantToken[player] = (plantToken[player] or 0) + 1
	local char = player.Character
	if char then char:SetAttribute("OrchardPlantAt", nil) end
end
local function plantFx(player, hole, kind, hold)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (char and root and hole) then return end
	local token = (plantToken[player] or 0) + 1
	plantToken[player] = token
	char:SetAttribute("OrchardPlantAt", hole.Position)
	task.delay(hold and PLANT_POSE_MAX or 1.1, function()
		if plantToken[player] == token and char.Parent then char:SetAttribute("OrchardPlantAt", nil) end
	end)
	local groundY = hole.Position.Y + hole.Size.Y / 2
	local target = Vector3.new(hole.Position.X, groundY + 0.1, hole.Position.Z)
	local def = Config.Trees[kind]
	task.delay(0.35, function() -- รอให้มือลงไปใกล้ดินก่อน
		local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		local from = hand and hand.Position or (root.Position + Vector3.new(0, 1, 0))
		local seed = Instance.new("Part")
		seed.Name = "PlantingSeed"
		seed.Shape = Enum.PartType.Ball
		seed.Size = Vector3.new(0.45, 0.45, 0.45)
		seed.Color = def and def.RipeColor or Color3.fromRGB(150, 110, 60)
		seed.Material = Enum.Material.SmoothPlastic
		decorPart(seed)
		seed.CFrame = CFrame.new(from)
		seed.Parent = workspace
		local t0 = os.clock()
		while os.clock() - t0 < 0.3 and seed.Parent do
			local a = (os.clock() - t0) / 0.3
			seed.CFrame = CFrame.new(from:Lerp(target, a * a))
			task.wait()
		end
		seed:Destroy()
		-- ดินฟุ้งตอนเมล็ดตกถึงหลุม
		local p = Instance.new("Part")
		p.Size = Vector3.new(1, 0.2, 1)
		p.Transparency = 1
		decorPart(p)
		p.CFrame = CFrame.new(target)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(140, 100, 60), Color3.fromRGB(110, 80, 50))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.3) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(0.5, 0.8)
		pe.Speed = NumberRange.new(2, 4)
		pe.SpreadAngle = Vector2.new(70, 70)
		pe.Acceleration = Vector3.new(0, -6, 0)
		pe.Rate = 0
		pe.Parent = p
		p.Parent = workspace
		pe:Emit(12)
		game:GetService("Debris"):AddItem(p, 1.5)
	end)
end
Players.PlayerRemoving:Connect(function(player) plantToken[player] = nil end)

function actions.plant(player, st, arg)
	if type(arg) ~= "table" then return reply(player, false, "?") end
	local lot = lotByName[tostring(arg[1])]
	local holeNo = math.floor(tonumber(arg[2]) or 0)
	local kind = arg[3]
	local def = Config.Trees[kind]
	local hole = lot and lot:FindFirstChild("Hole" .. holeNo)
	if not (def and hole) then return reply(player, false, "?") end
	if not Config.IsOpen(kind) then -- ชนิดที่ยังไม่เปิด (เช่นทุเรียน 2026-10-27)
		return reply(player, false, msg(player, def.Icon .. " " .. def.NameTh .. "ยังไม่เปิดให้ปลูก รออัปเดตนะ", def.Icon .. " " .. def.NameEn .. " can't be planted yet, coming soon"))
	end
	-- จำกัดต้นต่อคนเช็กตอนปลูก (ร้านขายเมล็ดไม่จำกัด 2026-10-26) เช็กก่อนเรื่องล็อก ข้อความจะได้ตรงเรื่อง
	if OrchardData.TreeCount(st.data) >= Config.MAX_PER_PLAYER then
		return reply(player, false, msg(player, "ปลูกไม้ผลได้คนละ " .. Config.MAX_PER_PLAYER .. " ต้น (ครบแล้ว)", "You can have " .. Config.MAX_PER_PLAYER .. " fruit trees (limit reached)"))
	end
	local claim = false
	if ownerOf[lot] ~= player then
		if ownerOf[lot] or lotOf[player] then
			return reply(player, false, msg(player, "ปลูกได้เฉพาะในล็อกของคุณ (ล็อก " .. lotNo(lotOf[player]) .. ")", "You can only plant in your own lot (lot " .. lotNo(lotOf[player]) .. ")"))
		end
		claim = true
	end
	if st.data.trees[tostring(holeNo)] and not claim then return reply(player, false, msg(player, "หลุมนี้มีต้นแล้ว", "This hole already has a tree")) end
	if claim and OrchardData.TreeCount(st.data) > 0 then
		return reply(player, false, msg(player, "สวนเต็ม ต้นของคุณยังไม่มีล็อกในเซิร์ฟนี้", "The orchard is full, your trees have no lot in this server"))
	end
	if not nearHole(player, hole) then return reply(player, false, msg(player, "เดินไปที่หลุมก่อน", "Walk to the hole first")) end
	local heldSeed = player.Character and player.Character:FindFirstChildWhichIsA("Tool") -- ต้องถือเมล็ดชนิดนี้อยู่จริง (2026-11-07 กันยิง Remote ตรง)
	if not (heldSeed and heldSeed:GetAttribute(OrchardItems.SEED) and heldSeed:GetAttribute("FruitKind") == kind) then
		return reply(player, false, msg(player, "🌱 ถือเมล็ดก่อนถึงจะปลูกได้", "🌱 Hold a seed first"))
	end
	if not OrchardItems.Take(player, OrchardItems.SEED, kind, 1, lang(player)) then
		return reply(player, false, msg(player, "ไม่มีเมล็ด" .. def.NameTh .. " ซื้อได้ที่ร้านผลไม้ & อุปกรณ์หน้าสวน", "No " .. def.NameEn .. " seed, buy one at the Fruit & Tools stall by the orchard gate"))
	end
	pcall(plantFx, player, hole, kind, true) -- ท่าหยิบเมล็ดลงหลุม (2026-11-02) · ค้างจนกว่าจะ reply (2026-11-15)
	if claim then assignLot(player, lot) end
	local ok = commit(player, st, function(d)
		d.trees[tostring(holeNo)] = OrchardData.NewTree(kind, OrchardData.Now())
		if claim then d.lot = lot.Name end -- ปลูกจองล็อกนี้ = จำไว้ (2026-11-06)
	end)
	if not ok then
		OrchardItems.Give(player, OrchardItems.SEED, kind, 1, lang(player)) -- เซฟสวนไม่ได้ = คืนเมล็ด
		if claim and not needsLot(player) then releaseLot(player) end
		plantPoseDone(player)
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	saveBag(player)
	render(player)
	plantPoseDone(player)
	return reply(player, true, msg(player,
		string.format("%s ปลูก%sที่ล็อก %s หลุม %d แล้ว! ต้นโตต่อแม้ออกจากเกม", def.Icon, def.NameTh, lotNo(lot), holeNo),
		string.format("%s Planted %s in lot %s hole %d! It keeps growing while you are offline", def.Icon, def.NameEn, lotNo(lot), holeNo)))
end

function actions.remove(player, st, holeNo)
	holeNo = math.floor(tonumber(holeNo) or 0)
	if not st.data.trees[tostring(holeNo)] then return reply(player, false, "?") end
	local ok = commit(player, st, function(d) d.trees[tostring(holeNo)] = nil end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	render(player)
	if not needsLot(player) then releaseLot(player) end
	return reply(player, true, msg(player, "🪓 ขุดต้นทิ้งแล้ว หลุมที่ " .. holeNo .. " ว่าง", "🪓 Tree removed, hole " .. holeNo .. " is free"))
end

-- ต้นโยกเยกหลังเก็บผล (ผู้ใช้สั่ง 2026-11-02): เอียงไปมารอบโคนต้น ค่อยๆ เบาลงใน 1.5 วิ แล้วกลับที่เดิมพอดี
--   โมเดลถูกสร้างใหม่ (render เปลี่ยนขั้น) ระหว่างโยก = หยุดเอง (model.Parent = nil)
local swaying = {} -- [model] = true
local function swayTree(model, hole)
	if swaying[model] then return end
	swaying[model] = true
	local pivot = model:GetPivot()
	local base = Vector3.new(hole.Position.X, hole.Position.Y + hole.Size.Y / 2, hole.Position.Z)
	local yaw = math.random() * math.pi * 2
	local axis = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
	task.spawn(function()
		local t0, dur = os.clock(), 1.5
		while model.Parent and os.clock() - t0 < dur do
			local t = os.clock() - t0
			local ang = math.rad(6) * math.sin(t * math.pi * 2 * 1.8) * (1 - t / dur)
			model:PivotTo(CFrame.new(base) * CFrame.fromAxisAngle(axis, ang) * CFrame.new(-base) * pivot)
			task.wait()
		end
		if model.Parent then model:PivotTo(pivot) end
		swaying[model] = nil
	end)
end

-- ต้นสั่นไหวระหว่างถูกตะกร้อสอย (ผู้ใช้สั่ง 2026-11-03): โยกถี่ๆ เบาๆ เปลี่ยนทิศไปมา + ใบไม้ร่วง จนกว่าจะเลิกสอย (stillOn() = false) แล้วค่อยๆ กลับที่เดิม
--   โมเดลถูกสร้างใหม่ระหว่างโยก (ขโมยสำเร็จ = ต้นเปลี่ยนหน้าตา) = หยุดเอง
local function shakeWhileStealing(model, hole, stillOn)
	if swaying[model] then return end
	swaying[model] = true
	local pivot = model:GetPivot()
	local base = Vector3.new(hole.Position.X, hole.Position.Y + hole.Size.Y / 2, hole.Position.Z)
	local _, size = model:GetBoundingBox()
	local leafPart = Instance.new("Part")
	leafPart.Name = "StealLeaves"
	leafPart.Size = Vector3.new(size.X * 0.6, 0.2, size.Z * 0.6)
	leafPart.Transparency = 1
	decorPart(leafPart)
	leafPart.CFrame = CFrame.new(base + Vector3.new(0, size.Y * 0.6, 0))
	local leaves = Instance.new("ParticleEmitter")
	leaves.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	leaves.Color = ColorSequence.new(Color3.fromRGB(110, 170, 70), Color3.fromRGB(70, 130, 50))
	leaves.Size = NumberSequence.new(0.4)
	leaves.Lifetime = NumberRange.new(1.5, 2.2)
	leaves.Rate = 8
	leaves.Speed = NumberRange.new(0.5, 1.5)
	leaves.Acceleration = Vector3.new(0, -4, 0)
	leaves.RotSpeed = NumberRange.new(-120, 120)
	leaves.SpreadAngle = Vector2.new(180, 180)
	leaves.Parent = leafPart
	leafPart.Parent = model
	task.spawn(function()
		local t0, w = os.clock(), 0
		local yaw0 = math.random() * math.pi * 2
		while model.Parent do
			local on = stillOn()
			w = math.clamp(w + (on and 0.12 or -0.08), 0, 1) -- ค่อยๆ เริ่ม / ค่อยๆ หยุด
			if not on and w <= 0 then break end
			local t = os.clock() - t0
			local yaw = yaw0 + math.sin(t * 1.3) * 1.2 -- ทิศโยกเปลี่ยนไปมาช้าๆ
			local axis = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
			local ang = math.rad(3.5) * w * (math.sin(t * math.pi * 2 * 2.6) + 0.35 * math.sin(t * math.pi * 2 * 5.3))
			model:PivotTo(CFrame.new(base) * CFrame.fromAxisAngle(axis, ang) * CFrame.new(-base) * pivot)
			leaves.Enabled = on
			task.wait()
		end
		if model.Parent then model:PivotTo(pivot) end
		if leafPart.Parent then
			leaves.Enabled = false
			game:GetService("Debris"):AddItem(leafPart, 2.5)
		end
		swaying[model] = nil
	end)
end

-- เก็บผล: กดที่หลุมเท่านั้น ต้องเป็นเจ้าของ ยืนใกล้ และต้นสุกจริงตามเวลา · ผลเข้ากระเป๋า
function actions.harvest(player, st, holeNo)
	local lot = lotOf[player]
	local hole = lot and lot:FindFirstChild("Hole" .. tostring(holeNo))
	local tr = st.data.trees[tostring(holeNo)]
	if not (hole and tr) then return reply(player, false, "?") end
	if not nearHole(player, hole) then return reply(player, false, msg(player, "เดินไปที่ต้นก่อน", "Walk to the tree first")) end
	-- 2026-11-06 ผู้ใช้สั่ง: มีคนกำลังขโมยต้นนี้อยู่ = เจ้าของเก็บไม่ได้ ต้องตบก่อน · ถูกขโมยหมดแล้ว (fruits = 0) ก็เก็บไม่ได้ ต้นเริ่มรอบใหม่เองใน render
	for _, at in pairs(attempts) do
		if at.lot == lot and tostring(at.holeNo) == tostring(holeNo) then
			return reply(player, false, msg(player, "🚨 มีคนกำลังขโมยต้นนี้อยู่! กด \"ตบ\" ที่ตัวคนขโมยก่อน", "🚨 Someone is stealing from this tree! Slap them first"))
		end
	end
	if tr.fruits <= 0 then
		return reply(player, false, msg(player, "😭 ผลรอบนี้โดนขโมยไปแล้ว", "😭 This round's fruit was stolen"))
	end
	if Config.StageAt(tr, OrchardData.Now()) ~= "Ripe" then
		return reply(player, false, msg(player, "ผลยังไม่สุก", "The fruit is not ripe yet"))
	end
	local kind = tr.kind
	local got, left, revived = 0, nil, tr.revived == true
	-- เก็บได้ Trees[kind].Harvests รอบต่อต้น (ผู้ใช้สั่ง 2026-10-27) รอบสุดท้าย = ต้นแห้ง (2026-11-02 เดิมต้นหาย) ตัดทิ้ง / เพื่อนช่วยฟื้น
	local ok = commit(player, st, function(d)
		local t = d.trees[tostring(holeNo)]
		got = OrchardData.StartNewCycle(t, OrchardData.Now())
		t.harvests = (t.harvests or 0) + 1
		left = Config.HarvestsLeft(t)
		if left == 0 then t.dead = true end
		d.stats.harvested += got
	end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	OrchardItems.Give(player, OrchardItems.FRUIT, kind, got, lang(player))
	saveBag(player)
	render(player)
	-- ต้นโยกเยกตอนดึงผลออก (2026-11-02) โมเดลหลัง render = ต้นขั้นใหม่
	local swayModel = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. tostring(holeNo))
	if swayModel then swayTree(swayModel, hole) end
	if not needsLot(player) then releaseLot(player) end -- ต้นสุดท้ายหมดอายุ = คืนล็อก
	local def = Config.Trees[kind]
	local extraTh, extraEn = "", ""
	if left == 0 and revived then
		extraTh = " · 🍂 ต้นนี้แห้งอีกแล้ว (ฟื้นได้ครั้งเดียว) กดค้าง \"ตัดต้น\" ได้ท่อนไม้ แล้วปลูกใหม่"
		extraEn = " · 🍂 This tree died again (it can only be revived once). Hold \"Cut down\" for logs, then replant"
	elseif left == 0 then
		extraTh = string.format(" · 🍂 เก็บครบ %d รอบ ต้นแห้งแล้ว! กดค้าง \"ตัดต้น\" ได้ท่อนไม้ หรือให้เพื่อนในเซิร์ฟมารดน้ำช่วย ต้นจะฟื้นเก็บได้อีก %d รอบ", def.Harvests, Config.DeadTree.RevivedHarvests)
		extraEn = string.format(" · 🍂 %d harvests done, the tree died! Hold \"Cut down\" for logs, or ask a friend in this server to water it: it revives for %d more harvest(s)", def.Harvests, Config.DeadTree.RevivedHarvests)
	elseif left then
		extraTh = string.format(" · ต้นนี้เก็บได้อีก %d รอบ", left)
		extraEn = string.format(" · %d more harvest(s) from this tree", left)
	end
	if got <= 0 then
		return reply(player, true, msg(player,
			string.format("😭 รอบนี้%sโดนขโมยไปหมดแล้ว ต้นเริ่มออกผลรอบใหม่", def.NameTh) .. extraTh,
			string.format("😭 This round's %s was stolen, the tree starts a new round", def.NameEn:lower()) .. extraEn))
	end
	-- เก็บได้ = ป้ายมุมขวาบนแบบเก็บผัก "+1 🥭" (ผู้ใช้สั่ง 2026-11-02 เดิมเป็นข้อความกลางจอ) · HarvestNotifyGui อ่าน "Orchard:<ชนิด>" + ดาว 0
	--   รอบที่เหลือ/ต้นแห้ง ดูที่ป้ายเหนือต้น · คืน message ไว้ให้คำสั่งทดสอบ แต่ปุ่มที่หลุมไม่เด้งข้อความนี้ (quiet)
	if not isFake(player) then harvestNotify:FireClient(player, "Orchard:" .. kind, 0, got) end
	local res = reply(player, true, msg(player,
		string.format("%s เก็บ%sได้ %d ผล", def.Icon, def.NameTh, got),
		string.format("%s Picked %d %s", def.Icon, got, def.NameEn)))
	res.quiet = true
	return res
end

-- ============ ขวาน / บัวรดน้ำ (2026-11-02): เสียง + เอฟเฟกต์ ============
local effectGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds")
local function playSound(id, parent, volume, looped)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.Looped = looped == true
	s.RollOffMaxDistance = 60
	s.SoundGroup = effectGroup -- ทุกเสียงต้องเข้ากลุ่ม (แถบปรับเสียงเอฟเฟกต์)
	s.Parent = parent
	s:Play()
	if not s.Looped then game:GetService("Debris"):AddItem(s, 6) end
	return s
end

-- เศษไม้กระเด็นที่โคนต้น 1 ครั้ง
local function chipBurst(pos)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.Transparency = 1
	decorPart(p)
	p.CFrame = CFrame.new(pos)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(205, 160, 105), Color3.fromRGB(140, 100, 60))
	pe.Size = NumberSequence.new(0.35, 0.1)
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(6, 10)
	pe.SpreadAngle = Vector2.new(50, 50)
	pe.Acceleration = Vector3.new(0, -25, 0)
	pe.RotSpeed = NumberRange.new(-200, 200)
	pe.Rate = 0
	pe.Parent = p
	p.Parent = workspace
	pe:Emit(14)
	game:GetService("Debris"):AddItem(p, 2)
end

-- ต้นสั่นนิดหน่อยตอนโดนฟัน (เอียงไปมารอบฐานต้น แล้วกลับที่เดิม)
local function shakeTree(model, base)
	local pivot = model:GetPivot()
	local function tilt(deg)
		local rel = CFrame.new(base) * CFrame.Angles(math.rad(deg), 0, math.rad(deg * 0.6)) * CFrame.new(-base)
		if model.Parent then model:PivotTo(rel * pivot) end
	end
	task.spawn(function()
		for _, d in ipairs({ 3, -2.2, 1.2, -0.5, 0 }) do
			tilt(d)
			task.wait(0.05)
		end
	end)
end

-- กดค้าง "ตัดต้น": หยิบขวานขึ้นมือ แล้วฟันทุก 1 วิ (ท่า Slash ของ Tool) ครบ CutSeconds = 4 ครั้ง · ปล่อยปุ่ม = หยุด
local chopToken = {} -- [player] = ตัวเลขรอบฟัน (เปลี่ยน = หยุดรอบเดิม)
local reachToken = {} -- [player] = ตัวเลขรอบเอื้อมมือหยิบผล (เก็บเกี่ยว 2026-11-02)
-- ท่าเก็บผลค้างจนได้ข้อความ (ผู้ใช้สั่ง 2026-11-16 แบบเดียวกับท่าปลูก): กดเก็บสำเร็จ = ท่าเอื้อมค้างระหว่างรอเซฟ แล้วลบทันทีก่อนแจ้งผล
--   harvesting[player] = true ระหว่างเก็บ (ปล่อยปุ่มแล้วไม่ล้างท่า) · HARVEST_POSE_MAX = กันท่าค้างถ้าเซฟค้าง/สคริปต์ error
local harvesting = {}
local HARVEST_POSE_MAX = 8
local chopAuto = {} -- [player] = ขวานที่หยิบขึ้นมือให้เอง (ตอนเริ่มไม่ได้ถืออยู่) ฟันเสร็จ/ปล่อยปุ่ม = เก็บเข้ากระเป๋าเอง (ผู้ใช้สั่ง 2026-11-02)

-- เก็บของที่หยิบให้เองคืนกระเป๋า (ถ้ายังถืออยู่และยังเป็นชิ้นเดิม)
local function putAway(player, tool)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if tool and hum and tool.Parent == char then hum:UnequipTools() end
end

-- ต้องถือขวาน/บัวในมือเอง ไม่หยิบให้แล้ว (ผู้ใช้สั่ง 2026-11-07) ไม่ถือ = เตือนวิธีหยิบ เว้นช่วงกันเตือนซ้ำตอนกดค้างครบ
local kitWarnAt = {} -- [player] = os.clock()
Players.PlayerRemoving:Connect(function(player) kitWarnAt[player] = nil end)
local function heldKit(player, id)
	local tool = OrchardItems.FindKit(player, id)
	if tool and tool.Parent == player.Character then return tool end
	if not tool then OrchardItems.EnsureKit(player, lang(player)) end -- ของแจกฟรีหาย = ใส่กระเป๋าคืน
	return nil
end
local function warnKit(player, id)
	if kitWarnAt[player] and os.clock() - kitWarnAt[player] < 6 then return end
	kitWarnAt[player] = os.clock()
	if id == "Axe" then
		notify(player, msg(player, "🪓 ถือขวานก่อน แล้วค่อยตัดต้น (เปิดกระเป๋า แท็บอุปกรณ์ กด ใช้)", "🪓 Hold the axe first (open your bag, Tools tab, press Use)"))
	else
		notify(player, msg(player, "🚿 ถือบัวรดน้ำก่อน แล้วค่อยรดน้ำ (เปิดกระเป๋า แท็บอุปกรณ์ กด ใช้)", "🚿 Hold the watering can first (open your bag, Tools tab, press Use)"))
	end
end

local function startChop(player, lot, holeNo)
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	if not hole then return end
	local axe = heldKit(player, "Axe")
	if not axe then return warnKit(player, "Axe") end
	local token = (chopToken[player] or 0) + 1
	chopToken[player] = token
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then -- หันหน้าเข้าต้น
		local look = Vector3.new(hole.Position.X, root.Position.Y, hole.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end
	task.spawn(function()
		for _ = 1, Config.DeadTree.CutSeconds do
			if chopToken[player] ~= token or axe.Parent ~= player.Character then return end
			local anim = Instance.new("StringValue")
			anim.Name = "toolanim"
			anim.Value = "Slash"
			anim.Parent = axe
			task.delay(1, function() if anim.Parent then anim:Destroy() end end)
			task.wait(0.25) -- ขวานกระทบต้น
			if chopToken[player] ~= token then return end
			local model = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. holeNo)
			local groundY = hole.Position.Y + hole.Size.Y / 2
			local fromSide = root and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)) or Vector3.new(1, 0, 0)
			fromSide = fromSide.Magnitude > 0.1 and fromSide.Unit or Vector3.new(1, 0, 0)
			chipBurst(Vector3.new(hole.Position.X, groundY + 1.2, hole.Position.Z) + fromSide * 0.8)
			playSound(Config.KitSounds.Chop, hole, 0.7)
			if model then shakeTree(model, Vector3.new(hole.Position.X, groundY, hole.Position.Z)) end
			task.wait(0.75)
		end
	end)
end

-- ต้นล้ม (หลังตัดสำเร็จ): ย้ายโมเดลต้นออกจากล็อก หมุนล้มออกจากคนตัด เสียงไม้กระแทก จางหาย + ท่อนไม้เด้งเข้าตัว
local function fallTree(model, hole, player)
	if not model then return end
	local groundY = hole.Position.Y + hole.Size.Y / 2
	local base = Vector3.new(hole.Position.X, groundY, hole.Position.Z)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local away = root and (base - Vector3.new(root.Position.X, groundY, root.Position.Z)) or Vector3.new(1, 0, 0)
	away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
	local axis = Vector3.new(0, 1, 0):Cross(away).Unit -- หมุนรอบแกนนี้ = ยอดต้นล้มไปทาง away
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then d:Destroy() end
		if d:IsA("BasePart") then d.CanCollide = false end
	end
	model.Name = "FallingTree"
	model.Parent = workspace
	local pivot = model:GetPivot()
	task.spawn(function()
		local t0 = os.clock()
		local dur = 0.9
		while os.clock() - t0 < dur and model.Parent do
			local a = (os.clock() - t0) / dur
			local ang = math.rad(85) * a * a -- เร่งขึ้นตอนล้ม
			model:PivotTo(CFrame.new(base) * CFrame.fromAxisAngle(axis, ang) * CFrame.new(-base) * pivot)
			task.wait()
		end
		if not model.Parent then return end
		model:PivotTo(CFrame.new(base) * CFrame.fromAxisAngle(axis, math.rad(85)) * CFrame.new(-base) * pivot)
		playSound(Config.KitSounds.Fall, hole, 0.8)
		chipBurst(base + away * 6 + Vector3.new(0, 0.5, 0))
		task.wait(0.8)
		for i = 1, 10 do
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then d.Transparency = math.max(d.Transparency, i / 10) end
			end
			task.wait(0.05)
		end
		model:Destroy()
	end)
	-- ท่อนไม้เด้งจากตอไม้เข้าตัวคนตัด (สวยงามอย่างเดียว ของจริงเข้ากระเป๋าแล้ว)
	local preview = ReplicatedStorage:FindFirstChild("ItemPreviewModels") and ReplicatedStorage.ItemPreviewModels:FindFirstChild("OrchardMat_Wood")
	if preview and root then
		for i = 1, Config.DeadTree.WoodPerCut do
			task.delay(1.1 + i * 0.25, function()
				local log = preview:Clone()
				log.Parent = workspace
				local from = base + Vector3.new(0, 1, 0)
				local t0 = os.clock()
				while os.clock() - t0 < 0.6 and log.Parent do
					local a = (os.clock() - t0) / 0.6
					local to = root.Parent and root.Position or from
					local pos = from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 3, 0)
					log:PivotTo(CFrame.new(pos) * CFrame.Angles(0, a * 6, a * 3))
					task.wait()
				end
				log:Destroy()
			end)
		end
	end
end

-- ตัดต้นแห้ง (2026-11-02): กดค้างที่หลุม (HolePrompt State "dead") หลุมว่าง + ท่อนไม้ DeadTree.WoodPerCut เข้ากระเป๋า (เซฟสวนก่อนค่อยให้ไม้)
--   ต้องมีขวาน (แจกฟรี กดค้างแล้วหยิบขึ้นมือให้เอง startChop) · สำเร็จ = ต้นล้ม (fallTree)
function actions.cut(player, st, holeNo)
	local lot = lotOf[player]
	local hole = lot and lot:FindFirstChild("Hole" .. tostring(holeNo))
	local tr = st.data.trees[tostring(holeNo)]
	if not (hole and tr and tr.dead) then return reply(player, false, "?") end
	if not nearHole(player, hole) then return reply(player, false, msg(player, "เดินไปที่ต้นก่อน", "Walk to the tree first")) end
	if not heldKit(player, "Axe") then
		warnKit(player, "Axe")
		return { ok = false, quiet = true, info = snapshot(player) }
	end
	local ok = commit(player, st, function(d) d.trees[tostring(holeNo)] = nil end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	local wood = Config.DeadTree.WoodPerCut
	OrchardItems.GiveMat(player, "Wood", wood, lang(player))
	saveBag(player)
	local falling = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. holeNo)
	if falling then pcall(fallTree, falling, hole, player) end -- ย้ายต้นออกก่อน render จะลบทิ้ง
	render(player)
	if not needsLot(player) then releaseLot(player) end
	return reply(player, true, msg(player,
		string.format("🪓 ตัดต้นแห้งแล้ว ได้ท่อนไม้ %d ท่อน 🌲 (เอาไปทำปุ๋ยที่เครื่องทำปุ๋ยข้างร้านผลไม้) หลุมที่ %d ว่างแล้ว", wood, holeNo),
		string.format("🪓 Dead tree cut down, got %d logs 🌲 (make fertilizer at the machine by the fruit stall). Hole %d is free", wood, holeNo)))
end

-- ใส่ปุ๋ยไม้ผล (2026-11-02): ถือปุ๋ยแล้วกดที่ต้นของเราที่กำลังโต = เวลาเดินไปข้างหน้า FertilizerSeconds (เลื่อน plantedAt/cycleStart ย้อนหลัง)
--   รอบผลละ 1 ครั้ง (tree.fed = cycleStart หลังใส่ เก็บผลแล้วรอบใหม่ cycleStart เปลี่ยน = ใส่ได้อีก) · หักปุ๋ยก่อน เซฟไม่ได้ = คืน
function actions.fertilize(player, st, holeNo)
	local lot = lotOf[player]
	local hole = lot and lot:FindFirstChild("Hole" .. tostring(holeNo))
	local tr = st.data.trees[tostring(holeNo)]
	if not (hole and tr) then return reply(player, false, "?") end
	local now = OrchardData.Now()
	local stage = Config.StageAt(tr, now)
	if stage == "Dead" or stage == "Ripe" then
		return reply(player, false, msg(player, "🌱 ใส่ปุ๋ยได้เฉพาะต้นที่กำลังโต/ผลยังไม่สุก", "🌱 Fertilizer only works on a tree that is still growing"))
	end
	if tr.fed ~= nil and tr.fed == tr.cycleStart then
		return reply(player, false, msg(player, "🌱 ต้นนี้ใส่ปุ๋ยรอบนี้แล้ว (รอบละ 1 ครั้ง)", "🌱 This tree already got fertilizer this round (once per round)"))
	end
	if not nearHole(player, hole) then return reply(player, false, msg(player, "เดินไปที่ต้นก่อน", "Walk to the tree first")) end
	if not OrchardItems.TakeMat(player, "Fertilizer", 1, lang(player)) then
		return reply(player, false, msg(player, "ไม่มีปุ๋ยไม้ผล ทำได้ที่เครื่องทำปุ๋ยข้างร้านผลไม้ (ใช้ท่อนไม้)", "No tree fertilizer, make it at the machine by the fruit stall (uses logs)"))
	end
	local secs = Config.FertilizerSeconds
	local ok = commit(player, st, function(d)
		local t = d.trees[tostring(holeNo)]
		t.plantedAt -= secs
		t.cycleStart -= secs
		t.fed = t.cycleStart
	end)
	if not ok then
		OrchardItems.GiveMat(player, "Fertilizer", 1, lang(player))
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	saveBag(player)
	render(player)
	local def = Config.Trees[tr.kind]
	return reply(player, true, msg(player,
		string.format("🌱 ใส่ปุ๋ยให้%sแล้ว! โตเร็วขึ้น %d นาที", def.NameTh, math.floor(secs / 60)),
		string.format("🌱 Fertilized your %s! %d minutes faster", def.NameEn, math.floor(secs / 60))))
end

-- ============ เครื่องทำปุ๋ย (ผู้ใช้สั่ง 2026-11-02 แทนสูตรคราฟที่โต๊ะช่างนากน้อย) ============
-- zone.Decor.FertilizerMachine (Body = MeshPart AI, PromptPart.FertilizerPrompt, Body.SmokeVent) · ค่า Config.FertilizerMachine
-- กดค้างครบ = เช็กไม้/เหรียญ → หักทันที → เครื่องสั่น + ควันเขียว + เสียง Seconds วิ → ปุ๋ย 1 ถุงเด้งจากเครื่องเข้ากระเป๋า (คนละครั้ง หลายคนใช้พร้อมกันได้)
local machineBusy = {} -- [player] = true ระหว่างเครื่องทำปุ๋ยให้
local machineRunning = 0 -- กี่คนกำลังใช้ (เอฟเฟกต์เปิดค้างจนคนสุดท้ายเสร็จ)

local function machineFx(machine, on)
	local body = machine and machine:FindFirstChild("Body")
	local vent = body and body:FindFirstChild("SmokeVent")
	if not vent then return end
	local smoke = vent:FindFirstChild("MachineSmoke")
	if not smoke then
		smoke = Instance.new("ParticleEmitter")
		smoke.Name = "MachineSmoke"
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(Color3.fromRGB(170, 220, 140), Color3.fromRGB(230, 245, 220))
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.4) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		smoke.Lifetime = NumberRange.new(1.2, 1.8)
		smoke.Speed = NumberRange.new(2, 3.5)
		smoke.SpreadAngle = Vector2.new(15, 15)
		smoke.Acceleration = Vector3.new(0.6, 1.5, 0)
		smoke.EmissionDirection = Enum.NormalId.Top
		smoke.Rate = 14
		smoke.Enabled = false
		smoke.Parent = vent
	end
	smoke.Enabled = on
end

-- จำนวนที่ทำได้มากสุดตอนนี้ (ตามท่อนไม้ / เหรียญ / MaxBatch)
local function fertilizerMax(player)
	local cfg = Config.FertilizerMachine
	local coins = coinsOf(player)
	local byWood = math.floor(OrchardItems.MatCount(player, "Wood") / cfg.Wood)
	local byCoins = coins and math.floor(coins.Value / cfg.Coins) or 0
	return math.clamp(math.min(byWood, byCoins), 0, cfg.MaxBatch or 20)
end

-- เวลาทำตามจำนวน: Seconds + PerExtra ต่อถุงที่เกิน 1 (ไม่เกิน MaxSeconds)
local function fertilizerSeconds(n)
	local cfg = Config.FertilizerMachine
	return math.min(cfg.Seconds + (n - 1) * (cfg.PerExtra or 0.5), cfg.MaxSeconds or 10)
end

-- ทำปุ๋ย n ถุง (เลือกจำนวนในหน้าต่าง ผู้ใช้สั่ง 2026-11-02): ตรวจ + หักไม้/เหรียญทันที คืนผล { ok, message } แล้วเครื่องทำงานต่อเบื้องหลัง
local function useFertilizerMachine(player, machine, n)
	local cfg = Config.FertilizerMachine
	n = math.floor(tonumber(n) or 1)
	if not Config.Enabled then return { ok = false } end
	if n < 1 or n > (cfg.MaxBatch or 20) then return { ok = false, message = "?" } end
	if machineBusy[player] then return { ok = false, message = msg(player, "⏳ เครื่องกำลังทำปุ๋ยให้คุณอยู่ รอสักครู่", "⏳ The machine is still making your fertilizer") } end
	local L = lang(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local body = machine:FindFirstChild("Body")
	if not (root and body) or (root.Position - body.Position).Magnitude > 16 then
		return { ok = false, message = msg(player, "เดินไปที่เครื่องทำปุ๋ยก่อน", "Walk to the fertilizer machine first") }
	end
	if player:GetAttribute("InventoryLoaded") == false then return { ok = false, message = msg(player, "ยังโหลดกระเป๋าไม่เสร็จ", "Your bag is still loading") } end
	local wood, coinsNeed = cfg.Wood * n, cfg.Coins * n
	local have = OrchardItems.MatCount(player, "Wood")
	if have < wood then
		return { ok = false, message = msg(player,
			string.format("🌲 ต้องใช้ท่อนไม้ %d ท่อน (มี %d) ได้จากตัดต้นแห้งในสวน", wood, have),
			string.format("🌲 Needs %d logs (you have %d), cut down dead trees in the orchard", wood, have)) }
	end
	local coins = coinsOf(player)
	if not coins or player:GetAttribute("CoinsLoaded") == false then return { ok = false, message = msg(player, "ยังโหลดเหรียญไม่เสร็จ", "Coins are still loading") } end
	if coins.Value < coinsNeed then
		return { ok = false, message = msg(player, "เหรียญไม่พอ ต้องมี " .. Config.Short(coinsNeed), "Not enough coins, you need " .. Config.Short(coinsNeed)) }
	end
	if not OrchardItems.TakeMat(player, "Wood", wood, L) then return { ok = false, message = "?" } end
	player:SetAttribute("CoinSrc", "fertilizer")
	coins.Value -= coinsNeed
	machineBusy[player] = true
	saveBag(player)
	if saveCoinsNow then saveCoinsNow:Fire(player) end
	local secs = fertilizerSeconds(n)
	task.spawn(function()
		machineRunning += 1
		machineFx(machine, true)
		-- เครื่องสั่นกึกๆ + เสียงทุก 0.5 วิ (กลับที่เดิมทุกครั้ง)
		local rest = body.CFrame
		local t0 = os.clock()
		local k = 0
		while os.clock() - t0 < secs do
			k += 1
			if k % 5 == 1 then playSound(Config.KitSounds.Chop, body, 0.45) end
			if body.Parent then
				body.CFrame = rest * CFrame.Angles(math.rad(math.random(-15, 15) / 10), 0, math.rad(math.random(-15, 15) / 10)) + Vector3.new(0, math.random() * 0.12, 0)
			end
			task.wait(0.1)
		end
		if body.Parent then body.CFrame = rest end
		machineRunning = math.max(0, machineRunning - 1)
		if machineRunning == 0 then machineFx(machine, false) end
		machineBusy[player] = nil
		if player.Parent ~= Players then return end -- ออกเกมระหว่างทำ = ไม้/เหรียญหักไปแล้ว (ไม่เกิน 10 วิ เกิดยาก)
		OrchardItems.GiveMat(player, "Fertilizer", n, L)
		saveBag(player)
		-- ถุงปุ๋ยเด้งจากเครื่องเข้าตัว (สวยงาม ไม่เกิน 3 ถุง)
		local preview = ReplicatedStorage:FindFirstChild("ItemPreviewModels") and ReplicatedStorage.ItemPreviewModels:FindFirstChild("OrchardMat_Fertilizer")
		if preview and root.Parent then
			for i = 1, math.min(n, 3) do
				task.delay((i - 1) * 0.2, function()
					local bag = preview:Clone()
					bag.Parent = workspace
					local from = body.Position + Vector3.new(0, body.Size.Y / 2, 0)
					local s0 = os.clock()
					while os.clock() - s0 < 0.6 and bag.Parent do
						local a = (os.clock() - s0) / 0.6
						local to = root.Parent and root.Position or from
						bag:PivotTo(CFrame.new(from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 3, 0)) * CFrame.Angles(0, a * 6, 0))
						task.wait()
					end
					bag:Destroy()
				end)
			end
		end
		notify(player, msg(player,
			string.format("🌱 ได้ปุ๋ยไม้ผล %d ถุง! ถือแล้วกดที่ต้นที่กำลังโต โตเร็วขึ้น %d นาที", n, math.floor(Config.FertilizerSeconds / 60)),
			string.format("🌱 Got %d tree fertilizer! Hold one and press on a growing tree, %d min faster", n, math.floor(Config.FertilizerSeconds / 60))))
		print(string.format("Orchard: %s ทำปุ๋ย %d ถุง (ไม้ %d + %d เหรียญ)", player.Name, n, wood, coinsNeed))
	end)
	return { ok = true, message = msg(player,
		string.format("🌱 ใส่ท่อนไม้แล้ว เครื่องกำลังทำปุ๋ย %d ถุง (%d วิ)...", n, math.ceil(secs)),
		string.format("🌱 Logs in, making %d fertilizer (%ds)...", n, math.ceil(secs))) }
end

-- ข้อมูลหน้าต่างเลือกจำนวน
local function fertilizerInfo(player)
	local cfg = Config.FertilizerMachine
	local coins = coinsOf(player)
	return { wood = OrchardItems.MatCount(player, "Wood"), coins = coins and coins.Value or 0, max = fertilizerMax(player),
		perWood = cfg.Wood, perCoins = cfg.Coins, maxBatch = cfg.MaxBatch or 20, busy = machineBusy[player] == true }
end

local fertilizerMachine = zone:FindFirstChild("Decor") and zone.Decor:FindFirstChild("FertilizerMachine")
do
	local prompt = fertilizerMachine and fertilizerMachine:FindFirstChild("FertilizerPrompt", true)
	if prompt then
		-- กด E = เปิดหน้าต่างเลือกจำนวน (OrchardGui) · ทำจริงผ่าน OrchardRequest "fertilizer"
		prompt.Triggered:Connect(function(player)
			if not Config.Enabled then return end
			openRemote:FireClient(player, "fertilizer", fertilizerInfo(player))
		end)
	else
		warn("OrchardService: ไม่เจอเครื่องทำปุ๋ย (Orchard.Decor.FertilizerMachine)")
	end
	Players.PlayerRemoving:Connect(function(player) machineBusy[player] = nil end)
end

-- ลายแปลง: ซื้อ = หักเหรียญ -> เซฟสวน (ไม่ได้ = คืนเหรียญ) แล้วใส่ให้เลย · ใส่ = ต้องซื้อแล้ว (Classic ฟรี) · ยังไม่มีล็อกก็ซื้อ/ใส่ได้ ได้ล็อกเมื่อไรลายขึ้นเอง
function actions.buySkin(player, st, id)
	local def = Config.HoleSkinById[tostring(id)]
	if not def or def.Price <= 0 then return reply(player, false, "?") end
	if st.data.skins[def.Id] then return reply(player, false, msg(player, "มีลายนี้แล้ว", "You already own this skin")) end
	local coins = coinsOf(player)
	if not coins or coins.Value < def.Price then
		return reply(player, false, msg(player, "เหรียญไม่พอ ต้องมี " .. Config.Short(def.Price), "Not enough coins, you need " .. Config.Short(def.Price)))
	end
	player:SetAttribute("CoinSrc", "hole_skin")
	coins.Value -= def.Price
	local ok = commit(player, st, function(d)
		d.skins[def.Id] = true
		d.skin = def.Id
	end)
	if not ok then
		coins.Value += def.Price
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	if saveCoinsNow then saveCoinsNow:Fire(player) end
	if lotOf[player] then applySkin(lotOf[player], def.Id) end
	return reply(player, true, msg(player, "🎀 ได้ลาย \"" .. def.NameTh .. "\" แล้ว! ใส่ให้ทุกหลุมในล็อกของคุณแล้ว", "🎀 Got the \"" .. def.NameEn .. "\" skin! It's on every hole in your lot"))
end

function actions.equipSkin(player, st, id)
	local def = Config.HoleSkinById[tostring(id)]
	if not def then return reply(player, false, "?") end
	if def.Price > 0 and not st.data.skins[def.Id] then return reply(player, false, msg(player, "ยังไม่ได้ซื้อลายนี้", "You don't own this skin yet")) end
	local want = def.Id ~= "Classic" and def.Id or nil
	if st.data.skin ~= want then
		local ok = commit(player, st, function(d) d.skin = want end)
		if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	end
	if lotOf[player] then applySkin(lotOf[player], def.Id) end
	return reply(player, true, msg(player, "🎀 ใส่ลาย \"" .. def.NameTh .. "\" แล้ว", "🎀 \"" .. def.NameEn .. "\" skin on"))
end

-- ตรวจร่วม (เลเวล/โหลด/คิว) แล้วเรียกคำสั่ง
local function run(player, action, arg)
	local handler = actions[action]
	local st = OrchardData.Get(player)
	if LevelSystem.GetLevel(player) < Config.MIN_LEVEL then
		return reply(player, false, msg(player, "ต้องเลเวล " .. Config.MIN_LEVEL .. " ขึ้นไป", "Requires level " .. Config.MIN_LEVEL))
	end
	if not (st and st.loaded) or player:GetAttribute("InventoryLoaded") == false then
		return reply(player, false, msg(player, "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง", "Still loading, please try again"))
	end
	if busy[player] or (lastRequest[player] and os.clock() - lastRequest[player] < REQUEST_COOLDOWN) then
		return reply(player, false, msg(player, "ใจเย็นๆ รออีกนิดนะ", "Slow down a little"))
	end
	busy[player] = true
	lastRequest[player] = os.clock()
	local ok, result = pcall(handler, player, st, arg)
	busy[player] = nil
	if not ok then
		warn("OrchardService: " .. action .. " error: " .. tostring(result))
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	sync(player)
	return result
end

-- ป๊อปแจ้งเตือนขโมย (2026-10-28): ปุ่ม "วาร์ปไปทันที" (OrchardGui) = "warpKeeper" วาร์ปไปหน้าเคาน์เตอร์ป้าแตงไทย (พ่อค้ามะม่วง)
-- ใช้ได้เฉพาะเจ้าของที่เพิ่งโดนแจ้งเตือนไม่เกิน WARP_WINDOW วิ ครั้งเดียวต่อการแจ้งเตือน (กันใช้เป็นวาร์ปฟรี)
local WARP_WINDOW = 90
local thiefAlertAt = {} -- [เจ้าของ] = os.clock() ตอนแจ้งเตือนล่าสุด (ตั้งใน beginAttempt)
local fakeThiefSlap -- Studio: ตบโจรปลอม (OrchardDev "fakethief")

local function warpToKeeper(player)
	local at = thiefAlertAt[player]
	if not at or os.clock() - at > WARP_WINDOW then return { ok = false } end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local shop = zone:FindFirstChild("Decor") and zone.Decor:FindFirstChild("FruitShop")
	local counter = shop and shop:FindFirstChild("Counter")
	if not (root and hum and hum.Health > 0 and counter) then return { ok = false } end
	thiefAlertAt[player] = nil
	local spot = counter.Position + Vector3.new(5.5, 0, 0) -- ป้าหันหน้า +X เคาน์เตอร์อยู่ระหว่างป้ากับจุดนี้
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local hit = workspace:Raycast(spot + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
	local y = (hit and hit.Position.Y or spot.Y) + hum.HipHeight + root.Size.Y / 2 + 0.5
	if hum.SeatPart then hum.Sit = false end
	local pos = Vector3.new(spot.X, y, spot.Z)
	char:PivotTo(CFrame.lookAt(pos, Vector3.new(counter.Position.X, y, counter.Position.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
	return { ok = true }
end

-- ============ ตู้แลกน้ำใจ 💚 (เฟส 1 ผู้ใช้สั่ง 2026-11-03) ============
-- แลกด้วยเหรียญช่วยเหลือ (help.coins) · รายการ/ราคา Config.HelpShop · ข้อมูล OrchardData shop · ตู้ zone.Decor.HelpShop (HelpShopPrompt)
-- ลำดับกันของหาย: หักเหรียญ + จดการซื้อ → เซฟสวน → ค่อยให้ของ · ให้ของไม่สำเร็จ (เช่นฟาร์มไก่ยังโหลดไม่เสร็จ) = คืนเหรียญ + ลบการซื้อ
local shopBusy = {}

local function shopPrice(it, shop)
	if it.Prices then return it.Prices[(shop.quota or 0) + 1] end -- nil = ซื้อครบทุกขั้นแล้ว
	return it.Price
end

local function chickenGrant()
	return ServerScriptService:FindFirstChild("ChickenTokenGrant")
end

-- สัตว์ขี่เอ็กซ์คลูซีฟ (Grant "mount", เฟส 3 2026-11-03): ใช้ MountOwnership ตัวเดียวกับระบบสัตว์ขี่ (ไม่มี/ปิดระบบ = ซ่อนแถว)
local function mountOwnership()
	local ok, MountConfig = pcall(function() return require(ReplicatedStorage:WaitForChild("MountConfig", 5)) end)
	if not (ok and MountConfig and MountConfig.IsEnabled()) then return nil end
	local folder = ServerScriptService:FindFirstChild("MountSystem")
	local m = folder and folder:FindFirstChild("MountOwnership")
	if not m then return nil end
	local okReq, mod = pcall(require, m)
	return okReq and mod or nil
end

local function setHelpTitleAttr(player)
	local st = OrchardData.Get(player)
	local id = st and st.loaded and st.data.shop and st.data.shop.title
	local it = id and Config.HelpShopById[id]
	player:SetAttribute("HelpTitle", it and it.Title or nil)
end

-- ประดับหลัง (เฟส 2, 2026-11-03): โมเดล OrchardTemplates.<Template> เชื่อมกับหลัง UpperTorso (ชื่อ HelpBackAccessory ในตัวละคร)
--   ตำแหน่ง = ผิวหลังลำตัว * Offset (config) * Fix (Attribute CFrame บนเทมเพลต = หมุนโมเดล AI ให้ตั้งตรง/หันออกจากหลัง) · เกิดใหม่ = ใส่ให้ใหม่
local function attachBack(player)
	-- ตู้ตกแต่ง แท็บประดับหลัง (FullInventoryGui 2026-11-03) อ่านของที่มีจาก Attribute HelpBackOwned_<Id>
	local st0 = OrchardData.Get(player)
	local backs = st0 and st0.loaded and st0.data.shop and st0.data.shop.backs
	if type(backs) == "table" then
		for bid, v in pairs(backs) do
			if v and player:GetAttribute("HelpBackOwned_" .. bid) ~= true then player:SetAttribute("HelpBackOwned_" .. bid, true) end
		end
	end
	local char = player.Character
	if not char then return end
	local old = char:FindFirstChild("HelpBackAccessory")
	if old then old:Destroy() end
	local st = OrchardData.Get(player)
	local id = st and st.loaded and st.data.shop and st.data.shop.back
	local it = id and Config.HelpShopById[id]
	player:SetAttribute("HelpBack", it and it.Id or nil)
	if not it then return end
	local template = templates:FindFirstChild(it.Template)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not (template and template:FindFirstChild("Handle") and torso) then return end
	local model = template:Clone()
	model.Name = "HelpBackAccessory"
	local handle = model.Handle
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
		end
	end
	local fix = template:GetAttribute("Fix")
	handle.CFrame = torso.CFrame * CFrame.new(0, 0, torso.Size.Z / 2) * (it.Offset or CFrame.new()) * (typeof(fix) == "CFrame" and fix or CFrame.new())
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= handle then
			local w = Instance.new("WeldConstraint") w.Part0, w.Part1 = handle, p w.Parent = p
		end
	end
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = torso, handle
	w.Parent = handle
	if it.Sparkle then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 210)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 220, 255)) })
		pe.Size = NumberSequence.new(0.3, 0)
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Rate = 8
		pe.Speed = NumberRange.new(0.3, 0.8)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 0.8
		pe.Parent = handle
	end
	model.Parent = char
end

local function shopInfo(player)
	local st = OrchardData.Get(player)
	if not (st and st.loaded) then return { Loaded = false } end
	local shop = OrchardData.ShopWeek(st.data)
	local items = {}
	for _, it in ipairs(Config.HelpShop.Items) do
		local price = shopPrice(it, shop)
		table.insert(items, {
			Id = it.Id, Price = price, Bought = shop.buys[it.Id] or 0, Limit = it.WeekLimit,
			Owned = (shop.titles[it.Id] == true or shop.backs[it.Id] == true
				or (it.Grant == "mount" and mountOwnership() ~= nil and mountOwnership().Owns(player, it.Mount))) or nil,
			Equipped = (shop.title == it.Id or shop.back == it.Id) or nil,
			SoldOut = (price == nil) or nil, Step = it.Prices and (shop.quota or 0) or nil, Steps = it.Prices and #it.Prices or nil,
			Hidden = ((it.Grant == "hatch" or it.Grant == "speed") and not chickenGrant()) or (it.Grant == "mount" and not mountOwnership()) or nil,
		})
	end
	return { Loaded = true, Coins = st.data.help.coins, Items = items }
end

local function shopReply(player, ok, message)
	return { ok = ok, message = message, info = shopInfo(player) }
end

local function shopBuy(player, id)
	local it = type(id) == "string" and Config.HelpShopById[id]
	local st = OrchardData.Get(player)
	if not it then return shopReply(player, false, "?") end
	if not (st and st.loaded) or player:GetAttribute("InventoryLoaded") == false then
		return shopReply(player, false, msg(player, "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง", "Still loading, please try again"))
	end
	local shop = OrchardData.ShopWeek(st.data)
	local price = shopPrice(it, shop)
	if not price then return shopReply(player, false, msg(player, "ซื้อครบแล้ว", "Sold out")) end
	if it.Grant == "title" and shop.titles[it.Id] then return shopReply(player, false, msg(player, "มีฉายานี้แล้ว", "You already own this title")) end
	if it.Grant == "back" and shop.backs[it.Id] then return shopReply(player, false, msg(player, "มีชิ้นนี้แล้ว", "You already own this")) end
	if it.WeekLimit and (shop.buys[it.Id] or 0) >= it.WeekLimit then
		return shopReply(player, false, msg(player,
			string.format("สัปดาห์นี้แลกครบ %d ครั้งแล้ว (รีเซ็ตวันจันทร์ 07:00)", it.WeekLimit),
			string.format("Weekly limit of %d reached (resets Monday)", it.WeekLimit)))
	end
	if (it.Grant == "hatch" or it.Grant == "speed") and not chickenGrant() then
		return shopReply(player, false, msg(player, "ฟาร์มไก่ยังไม่เปิด", "The chicken farm isn't open"))
	end
	local mounts = it.Grant == "mount" and mountOwnership()
	if it.Grant == "mount" then
		if not mounts then return shopReply(player, false, msg(player, "ระบบสัตว์ขี่ยังไม่เปิด", "Mounts aren't open")) end
		if not mounts.IsLoaded(player) then return shopReply(player, false, msg(player, "ยังโหลดสัตว์ขี่ไม่เสร็จ ลองใหม่อีกครั้ง", "Mounts are still loading, please try again")) end
		if mounts.Owns(player, it.Mount) then return shopReply(player, false, msg(player, "มีสัตว์ขี่ตัวนี้แล้ว", "You already own this mount")) end
	end
	local coins = it.Grant == "coins" and coinsOf(player)
	if it.Grant == "coins" and (not coins or player:GetAttribute("CoinsLoaded") == false) then
		return shopReply(player, false, msg(player, "ยังโหลดเหรียญไม่เสร็จ", "Coins are still loading"))
	end
	if st.data.help.coins < price then
		return shopReply(player, false, msg(player,
			string.format("💚 เหรียญช่วยเหลือไม่พอ (มี %d ต้องใช้ %d) ช่วยรดน้ำต้นแห้งของเพื่อนเพื่อสะสม", st.data.help.coins, price),
			string.format("💚 Not enough help coins (%d / %d). Water friends' dead trees to earn more", st.data.help.coins, price)))
	end
	local quotaRef = it.Grant == "quota" and ("helpshop_" .. player.UserId .. "_" .. ((shop.quota or 0) + 1)) or nil
	-- 1) หักเหรียญ + จดการซื้อ แล้วเซฟก่อน
	local ok = commit(player, st, function(d)
		local sh = OrchardData.ShopWeek(d)
		d.help.coins -= price
		if it.WeekLimit then sh.buys[it.Id] = (sh.buys[it.Id] or 0) + 1 end
		if it.Grant == "quota" then sh.quota = (sh.quota or 0) + 1 end
		if it.Grant == "title" then sh.titles[it.Id] = true sh.title = it.Id end
		if it.Grant == "back" then sh.backs[it.Id] = true sh.back = it.Id end -- ซื้อแล้วใส่ให้เลย
	end)
	if not ok then return shopReply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	player:SetAttribute("HelpCoins", st.data.help.coins) -- (setHelpCoinsAttr ประกาศทีหลังส่วนนี้)
	-- 2) ให้ของ
	local granted = true
	if it.Grant == "coins" then
		CheatWatch.AllowCoinGain(player, it.Amount)
		coins.Value += it.Amount
		if saveCoinsNow then saveCoinsNow:Fire(player) end
	elseif it.Grant == "hatch" or it.Grant == "speed" then
		local g = chickenGrant()
		local okCall, res = pcall(function() return g:Invoke(player, it.Grant, 1) end)
		granted = okCall and res == true
	elseif it.Grant == "quota" then
		local g = ServerScriptService:FindFirstChild("PlantQuotaPromoGrant")
		local okCall, res = pcall(function() return g and g:Invoke(player, quotaRef) end)
		granted = okCall and res == true
	elseif it.Grant == "title" then
		setHelpTitleAttr(player)
	elseif it.Grant == "back" then
		pcall(attachBack, player)
	elseif it.Grant == "mount" then
		local okCall, res = pcall(function() return mounts.GrantBatch(player, { it.Mount }) end)
		granted = okCall and type(res) == "table"
	end
	if not granted then
		-- คืนเหรียญ + ลบการซื้อ (เซฟไม่ได้ = บันทึกไว้เซฟทีหลัง)
		local d = st.data
		local sh = OrchardData.ShopWeek(d)
		d.help.coins += price
		if it.WeekLimit and (sh.buys[it.Id] or 0) > 0 then sh.buys[it.Id] -= 1 end
		if it.Grant == "quota" and (sh.quota or 0) > 0 then sh.quota -= 1 end
		OrchardData.SaveLater(player)
		player:SetAttribute("HelpCoins", st.data.help.coins) -- (setHelpCoinsAttr ประกาศทีหลังส่วนนี้)
		warn("OrchardService: ตู้แลกน้ำใจ ให้ " .. it.Id .. " กับ " .. player.Name .. " ไม่สำเร็จ คืนเหรียญแล้ว")
		return shopReply(player, false, msg(player, "แลกไม่สำเร็จ คืนเหรียญช่วยเหลือแล้ว ลองใหม่อีกครั้ง", "Exchange failed, help coins refunded. Please try again"))
	end
	print(string.format("Orchard: %s แลก %s ด้วยเหรียญช่วยเหลือ %d (เหลือ %d)", player.Name, it.Id, price, st.data.help.coins))
	local name = msg(player, it.NameTh, it.NameEn)
	return shopReply(player, true, msg(player, "🎉 แลก" .. name .. "แล้ว!", "🎉 Got " .. name .. "!"))
end

-- ใส่/ถอดประดับหลัง (arg = { back = Id } ใส่ / { back = false } ถอด) 2026-11-03
local function shopWearBack(player, st, id)
	local want = nil
	if type(id) == "string" then
		if not st.data.shop.backs[id] then return shopReply(player, false, msg(player, "ยังไม่มีชิ้นนี้", "You don't own this")) end
		want = id
	end
	if st.data.shop.back ~= want then
		local ok = commit(player, st, function(d) d.shop.back = want end)
		if not ok then return shopReply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	end
	pcall(attachBack, player)
	return shopReply(player, true, want and msg(player, "ใส่ประดับหลังแล้ว", "Back item on") or msg(player, "ถอดประดับหลังแล้ว", "Back item off"))
end

-- ใส่/ถอดฉายา (id = false/nil = ถอด) · arg เป็นตาราง { back = ... } = ประดับหลัง
local function shopEquip(player, id)
	local st = OrchardData.Get(player)
	if not (st and st.loaded) then return shopReply(player, false, "?") end
	if type(id) == "table" then return shopWearBack(player, st, id.back) end
	local want = nil
	if type(id) == "string" then
		if not st.data.shop.titles[id] then return shopReply(player, false, msg(player, "ยังไม่มีฉายานี้", "You don't own this title")) end
		want = id
	end
	if st.data.shop.title ~= want then
		local ok = commit(player, st, function(d) d.shop.title = want end)
		if not ok then return shopReply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
	end
	setHelpTitleAttr(player)
	return shopReply(player, true, want and msg(player, "ใส่ฉายาแล้ว", "Title on") or msg(player, "ถอดฉายาแล้ว", "Title off"))
end

local function shopRun(player, fn, arg)
	if shopBusy[player] then return shopReply(player, false, msg(player, "ใจเย็นๆ รออีกนิดนะ", "Slow down a little")) end
	shopBusy[player] = true
	local ok, res = pcall(fn, player, arg)
	shopBusy[player] = nil
	if not ok then
		warn("OrchardService: help shop error: " .. tostring(res))
		return shopReply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	return res
end

do
	local booth = zone:FindFirstChild("Decor") and zone.Decor:FindFirstChild("HelpShop")
	local prompt = booth and booth:FindFirstChild("HelpShopPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(player)
			if not Config.Enabled then return end
			openRemote:FireClient(player, "helpshop", shopInfo(player))
		end)
	end
	Players.PlayerRemoving:Connect(function(player) shopBusy[player] = nil end)
end

requestRemote.OnServerInvoke = function(player, action, arg)
	if type(action) ~= "string" then return nil end
	if action == "info" then return reply(player, true, nil) end
	if action == "warpKeeper" then return warpToKeeper(player) end
	-- เครื่องทำปุ๋ย (หน้าต่างเลือกจำนวน 2026-11-02): "fertilizerInfo" = ไม้/เหรียญ/ทำได้สูงสุด · "fertilizer"(n) = ทำ n ถุง
	if action == "fertilizerInfo" then return fertilizerInfo(player) end
	-- ตู้แลกน้ำใจ (2026-11-03)
	if action == "helpShopInfo" then return shopInfo(player) end
	if action == "helpShopBuy" then return shopRun(player, shopBuy, arg) end
	if action == "helpShopEquip" then return shopRun(player, shopEquip, arg) end
	if action == "fertilizer" then
		if not fertilizerMachine then return { ok = false } end
		local ok, res = pcall(useFertilizerMachine, player, fertilizerMachine, arg)
		if not ok then
			machineBusy[player] = nil
			warn("OrchardService: fertilizer machine error: " .. tostring(res))
			return { ok = false, message = msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN) }
		end
		res.info = fertilizerInfo(player)
		return res
	end
	-- ถือเมล็ดแล้วคลิกที่หลุม (2026-10-27 ผู้ใช้สั่ง แบบปลูกผัก): arg = { ชื่อล็อก, หลุม } ชนิดเมล็ดเซิร์ฟอ่านจากของในมือเอง · ตรวจทุกอย่างเหมือนกด "ปลูกต้นไม้" ที่หลุม · ผลแจ้งเป็นข้อความเด้ง
	if action == "plantHeld" then
		if type(arg) ~= "table" then return nil end
		local held = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
		local kind = held and held:GetAttribute(OrchardItems.SEED) and held:GetAttribute("FruitKind")
		if not (kind and Config.Trees[kind]) then return nil end
		local res = run(player, "plant", { arg[1], arg[2], kind })
		if type(res) == "table" then notify(player, res.message) end
		return res
	end
	if action ~= "plant" and action ~= "remove" and action ~= "buySkin" and action ~= "equipSkin" then return nil end -- เก็บผลผ่านปุ่มที่หลุมเท่านั้น
	return run(player, action, arg)
end

-- ปุ่มที่หลุม: ว่าง = เปิดหน้าต่างเลือกเมล็ด · สุก = เก็บ · กำลังโต = หน้าต่างต้นไม้ (ขุดทิ้ง)
for _, lot in ipairs(lots) do
	for i = 1, Config.MAX_TREES do
		local hole = lot:FindFirstChild("Hole" .. i)
		local prompt = hole and hole:FindFirstChild("HolePrompt")
		if prompt then
			-- ต้นแห้ง: เริ่มกดค้าง = หยิบขวานแล้วฟัน · ปล่อย = หยุดฟัน (2026-11-02)
			prompt.PromptButtonHoldBegan:Connect(function(player)
				-- เก็บเกี่ยว: เอื้อมมือหยิบผล (Attribute ให้ OrchardGui ทำท่าแขน + หันเข้าต้น) 2026-11-02
				if prompt:GetAttribute("State") == "ripe" and ownerOf[lot] == player and player.Character then
					reachToken[player] = (reachToken[player] or 0) + 1
					player.Character:SetAttribute("OrchardHarvestAt", hole.Position)
				end
				if prompt:GetAttribute("State") == "dead" and ownerOf[lot] == player then
					local ok, err = pcall(startChop, player, lot, i)
					if not ok then warn("OrchardService: chop error: " .. tostring(err)) end
				end
			end)
			prompt.PromptButtonHoldEnded:Connect(function(player)
				-- เลิกเอื้อมมือหลังปล่อยปุ่ม 0.7 วิ (เห็นท่าดึงผลตอนต้นโยก) · กดใหม่ทัน = ไม่ล้าง
				local rt = reachToken[player]
				if rt then
					task.delay(0.7, function()
						if reachToken[player] ~= rt or harvesting[player] then return end -- กำลังเก็บ = ให้ Triggered ล้างเองหลังได้ผล (2026-11-16)
						if player.Character then player.Character:SetAttribute("OrchardHarvestAt", nil) end
					end)
				end
				local token = (chopToken[player] or 0) + 1
				chopToken[player] = token
				-- ฟันเสร็จ/ปล่อยปุ่ม: ขวานที่หยิบให้เอง = เก็บคืน (รอให้ท่าฟันสุดท้ายจบก่อน) · กดใหม่ทัน = ไม่เก็บ
				local auto = chopAuto[player]
				if auto then
					task.delay(0.8, function()
						if chopToken[player] ~= token or chopAuto[player] ~= auto then return end
						chopAuto[player] = nil
						putAway(player, auto)
					end)
				end
			end)
			prompt.Triggered:Connect(function(player)
				local owner = ownerOf[lot]
				local st = OrchardData.Get(player)
				if not (st and st.loaded) then return end
				local state = prompt:GetAttribute("State")
				if owner and owner ~= player then return end
				if state == "ripe" and owner == player then
					-- ท่าเอื้อมค้างจนได้ผล (2026-11-16): รอบใหม่ = ตัวล้าง 0.7 วิของปล่อยปุ่มใช้ไม่ได้ · กันค้าง HARVEST_POSE_MAX
					local rt = (reachToken[player] or 0) + 1
					reachToken[player] = rt
					harvesting[player] = true
					if player.Character then player.Character:SetAttribute("OrchardHarvestAt", hole.Position) end
					local function poseDone()
						if reachToken[player] ~= rt then return end
						harvesting[player] = nil
						if player.Character then player.Character:SetAttribute("OrchardHarvestAt", nil) end
					end
					task.delay(HARVEST_POSE_MAX, poseDone)
					local ok, res = pcall(run, player, "harvest", i)
					poseDone() -- ลบท่าก่อนแจ้งผล ทั้งเก็บได้และเซฟไม่ได้ (ไม่มีดีเลย์)
					if not ok then error(res, 0) end
					if type(res) == "table" and not res.quiet then notify(player, res.message) end -- เก็บได้ = ป้ายมุมขวาบนแทน
				elseif state == "dead" and owner == player then -- ตัดต้นแห้ง (2026-11-02)
					local res = run(player, "cut", i)
					if type(res) == "table" and not res.quiet then notify(player, res.message) end
					local auto = chopAuto[player] -- ตัดเสร็จ = เก็บขวานที่หยิบให้เองคืนกระเป๋า
					if auto then
						local token = chopToken[player]
						task.delay(0.8, function()
							if chopToken[player] ~= token or chopAuto[player] ~= auto then return end
							chopAuto[player] = nil
							putAway(player, auto)
						end)
					end
				elseif state == "grow" and owner == player and OrchardItems.HeldMat(player, "Fertilizer") then -- ถือปุ๋ย = ใส่ปุ๋ย (2026-11-02)
					local res = run(player, "fertilize", i)
					if type(res) == "table" then notify(player, res.message) end
				elseif state == "grow" and owner == player then
					sync(player)
					openRemote:FireClient(player, "tree", { lot = lot.Name, hole = i })
				elseif state == "empty" then
					if not owner and lotOf[player] then
						notify(player, msg(player, "ล็อกของคุณคือล็อก " .. lotNo(lotOf[player]), "Your lot is lot " .. lotNo(lotOf[player])))
						return
					end
					-- ปลูกเมล็ดที่ถืออยู่เท่านั้น (2026-11-07 ผู้ใช้สั่ง เดิมมือว่างแต่มีเมล็ดชนิดเดียว = ปลูกให้เอง)
					local held = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
					local kind = held and held:GetAttribute(OrchardItems.SEED) and held:GetAttribute("FruitKind") or nil
					if not (kind and Config.Trees[kind]) then
						local kinds = 0
						for k, n in pairs(seedCounts(player)) do
							if n > 0 and Config.IsOpen(k) then kinds += 1 end -- นับเฉพาะชนิดที่เปิดแล้ว
						end
						if kinds == 0 then
							notify(player, msg(player, "🌱 ยังไม่มีเมล็ดมะม่วง/ทุเรียน ซื้อได้ที่ร้านผลไม้ & อุปกรณ์หน้าสวน", "🌱 No mango/durian seeds yet, buy them at the Fruit & Tools stall by the orchard gate"))
							return
						end
						if not (kitWarnAt[player] and os.clock() - kitWarnAt[player] < 6) then
							kitWarnAt[player] = os.clock()
							notify(player, msg(player, "🌱 ถือเมล็ดก่อนถึงจะปลูกได้ (กดช่องเมล็ดในแถบ หรือเปิดกระเป๋ากด ใช้)", "🌱 Hold a seed first (pick it on the hotbar, or press Use in your bag)"))
						end
						return
					end
					local res = run(player, "plant", { lot.Name, i, kind })
					if type(res) == "table" then notify(player, res.message) end
				end
			end)
		end
	end
end

-- ============ เพื่อนช่วยต้นแห้ง (2026-11-02) ============
-- HelpPrompt: เจ้าของกด (ไม่ต้องค้าง) = ขอความช่วยเหลือ แจ้งคนอื่นทั้งเซิร์ฟ · คนอื่นกดค้าง HelpSeconds = รดน้ำช่วย
--   ต้นฟื้น (dead = nil, revived = true, เก็บได้อีก Harvests รอบ เริ่มรอบผลใหม่เลย) → คนช่วยได้เหรียญช่วยเหลือ (วันละไม่เกิน HelpDailyCoins ครั้ง)
--   กันกดทันที: ต้องเคย PromptButtonHoldBegan ที่ปุ่มเดียวกันนานพอ (แบบขโมย)
local Dead = Config.DeadTree
local helpHold = {} -- [player] = { prompt, t }
local helpAskAt = {} -- [เจ้าของ] = os.clock() ขอความช่วยเหลือล่าสุด
local helpingKey = {} -- ["Lot01#2"] = true ระหว่างเซฟ

-- บัวรดน้ำ (2026-11-02): เริ่มกดค้าง "รดน้ำช่วย" = หยิบบัวขึ้นมือ เอียงเท (Grip -> PourGrip) + สายน้ำจากพวย + เสียงน้ำ · ปล่อย/ครบ = กลับท่าถือปกติ
local pouring = {} -- [player] = { tool, emitter, sound, auto }
local function stopPour(player)
	local p = pouring[player]
	if not p then return end
	pouring[player] = nil
	if p.tool and p.tool.Parent then p.tool.Grip = Config.Kit.Can.Grip end
	if p.emitter then p.emitter.Enabled = false game:GetService("Debris"):AddItem(p.emitter.Parent, 1.5) end
	if p.splash then p.splash.Enabled = false game:GetService("Debris"):AddItem(p.splash.Parent, 1.5) end
	if p.sound then p.sound:Destroy() end
	if p.auto and p.tool then putAway(player, p.tool) end -- บัวที่หยิบให้เอง = เก็บคืนเหมือนขวาน (2026-11-02)
end
-- ขี่สัตว์ที่มี TrunkWater (ช้างน้อยใจบุญ) = งวงพ่นน้ำใส่ต้นไม้แทนการถือบัว (2026-11-03)
local function trunkWaterOf(player)
	local riding = player:GetAttribute("RidingMount")
	if type(riding) ~= "string" or riding == "" then return nil end
	local ok, MountConfig = pcall(function() return require(ReplicatedStorage:WaitForChild("MountConfig", 5)) end)
	local def = ok and MountConfig and MountConfig.Mounts[riding]
	if not (def and typeof(def.TrunkWater) == "Vector3") then return nil end
	local char = player.Character
	local model = char and char:FindFirstChild("Mount_" .. riding)
	local mroot = model and (model:FindFirstChild("MountRoot") or model.PrimaryPart)
	if not (mroot and mroot:IsA("BasePart")) then return nil end
	return mroot, def.TrunkWater * (tonumber(model:GetAttribute("RiderScale")) or 1) -- คนขี่ตัวโต = ช้างถูกขยาย
end

local function startTrunkPour(player, hole, mroot, offset)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local look = Vector3.new(hole.Position.X, root.Position.Y, hole.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end
	local tip = mroot.CFrame:PointToWorldSpace(offset)
	local target = hole.Position + Vector3.new(0, 2.5, 0)
	local flat = Vector3.new(target.X - tip.X, 0, target.Z - tip.Z).Magnitude
	local speed, gravity = 16, 18
	local t = math.clamp(flat / speed, 0.25, 1.4)
	-- เล็งสูงกว่าเป้าเท่าที่น้ำตกตามแรงโน้มถ่วง น้ำจะโค้งลงต้นไม้พอดี
	local aim = target + Vector3.new(0, 0.5 * gravity * t * t, 0)
	local jetAtt = Instance.new("Attachment")
	jetAtt.Name = "TrunkPour"
	jetAtt.CFrame = mroot.CFrame:ToObjectSpace(CFrame.lookAt(tip, aim))
	jetAtt.Parent = mroot
	local jet = Instance.new("ParticleEmitter")
	jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	jet.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255), Color3.fromRGB(225, 248, 255))
	jet.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.55) })
	jet.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.5) })
	jet.Lifetime = NumberRange.new(t, t + 0.12)
	jet.Speed = NumberRange.new(speed * (flat > 0 and (aim - tip).Magnitude / flat or 1))
	jet.SpreadAngle = Vector2.new(5, 5)
	jet.Acceleration = Vector3.new(0, -gravity, 0)
	jet.EmissionDirection = Enum.NormalId.Front
	jet.Rate = 90
	jet.LightEmission = 0.35
	jet.Parent = jetAtt
	local splashAtt = Instance.new("Attachment")
	splashAtt.Name = "TrunkSplash"
	splashAtt.WorldPosition = target
	splashAtt.Parent = workspace.Terrain
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	splash.Color = ColorSequence.new(Color3.fromRGB(190, 230, 255), Color3.fromRGB(255, 255, 255))
	splash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.05) })
	splash.Lifetime = NumberRange.new(0.35, 0.6)
	splash.Speed = NumberRange.new(3, 6)
	splash.SpreadAngle = Vector2.new(70, 70)
	splash.Acceleration = Vector3.new(0, -20, 0)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Rate = 40
	splash.LightEmission = 0.3
	splash.Parent = splashAtt
	-- เสียง (2026-11-03 ผู้ใช้สั่ง): ช้างร้องเบาๆ 1 ครั้ง (เร่งเป็นช้างเด็ก) + เสียงฉีดน้ำวนตลอดที่พ่น
	local trumpet = playSound(Config.KitSounds.Trumpet or Config.KitSounds.Water, mroot, 0.6)
	trumpet.PlaybackSpeed = 1.15
	local spray = playSound(Config.KitSounds.WaterSpray or Config.KitSounds.Water, mroot, 1, true)
	pouring[player] = { emitter = jet, splash = splash, sound = spray }
end

local function startPour(player, hole)
	stopPour(player)
	local mroot, trunkOffset = trunkWaterOf(player)
	if mroot then return startTrunkPour(player, hole, mroot, trunkOffset) end
	local canId = "Can"
	local can = heldKit(player, canId)
	if not can then return warnKit(player, canId) end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local look = Vector3.new(hole.Position.X, root.Position.Y, hole.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end
	local def = Config.Kit.Can
	can.Grip = def.PourGrip or (def.Grip * CFrame.Angles(math.rad(-55), 0, 0))
	local handle = can:FindFirstChild("Handle")
	local emitter
	if handle then
		local att = Instance.new("Attachment")
		att.Name = "PourSpout"
		local side = def.SpoutSide or 1 -- +1 = พวยอยู่ฝั่ง +X ของโมเดล / -1 = ฝั่ง -X
		att.Position = Vector3.new(side * handle.Size.X * 0.48, handle.Size.Y * (def.SpoutHeight or 0.2), 0)
		att.Parent = handle
		emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255), Color3.fromRGB(220, 245, 255))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.3) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.6) })
		emitter.Lifetime = NumberRange.new(0.5, 0.8)
		emitter.Speed = NumberRange.new(2, 3)
		emitter.SpreadAngle = Vector2.new(12, 12)
		emitter.Acceleration = Vector3.new(0, -30, 0)
		emitter.EmissionDirection = side > 0 and Enum.NormalId.Right or Enum.NormalId.Left
		emitter.Rate = 70
		emitter.LightEmission = 0.3
		emitter.Parent = att
	end
	pouring[player] = { tool = can, emitter = emitter, sound = playSound(Config.KitSounds.Water, handle or hole, 1, true) } -- เสียงเทน้ำดังขึ้น 0.6 → 1 (2026-11-03)
end

local function setHelpCoinsAttr(player)
	local st = OrchardData.Get(player)
	if st and st.loaded then player:SetAttribute("HelpCoins", st.data.help.coins) end
end

local function treeNameOf(player, kind)
	local def = Config.Trees[kind]
	return def and msg(player, def.NameTh, def.NameEn) or "?"
end

local HELP_BROADCAST_GAP = 10 -- วิ เพดานประกาศขอความช่วยเหลือรวมทั้งเซิร์ฟ
local helpBroadcastAt = nil
local function askHelp(owner, lot, holeNo)
	local st = stateOf(owner)
	local tree = st and st.loaded and st.data.trees[tostring(holeNo)]
	if not (tree and tree.dead and not tree.revived) then return end
	local last = helpAskAt[owner]
	if last and os.clock() - last < Dead.HelpAskCooldown then
		return notify(owner, msg(owner,
			string.format("🙏 ขอความช่วยเหลือไปแล้ว รออีก %d วิ", math.ceil(Dead.HelpAskCooldown - (os.clock() - last))),
			string.format("🙏 Help already requested, wait %d s", math.ceil(Dead.HelpAskCooldown - (os.clock() - last)))))
	end
	-- เพดานรวมทั้งเซิร์ฟ (กันแชทรก): ประกาศได้ 1 ครั้งทุก HELP_BROADCAST_GAP วิ เกิน = บอกเจ้าของให้ลองใหม่ (ไม่เสียระยะเว้น 60 วิของเจ้าของ)
	if helpBroadcastAt and os.clock() - helpBroadcastAt < HELP_BROADCAST_GAP then
		if isFake(owner) then return end
		return notify(owner, msg(owner, "🙏 มีคนขอความช่วยเหลืออยู่ ลองใหม่อีกครั้งนะ", "🙏 Someone else just asked for help, try again in a moment"))
	end
	helpBroadcastAt = os.clock()
	helpAskAt[owner] = os.clock()
	-- 2026-11-07 ผู้ใช้สั่ง: ข้อความระบบของเกมในแชททุกเครื่อง แบบประกาศปลาลับ (GachaAnnouncer) ทุกคนทุกอายุเห็น ไม่ติดกฎแชท
	--   ข้อความตายตัว + ชื่อที่แสดง (เดิม: เจ้าของพิมพ์เอง SendAsync / ก่อนหน้านั้นการ์ดเด้ง)
	remote("RemoteEvent", "OrchardAlert"):FireAllClients("helpchat", { owner = owner.DisplayName })
	if not isFake(owner) then
		notify(owner, msg(owner, "🙏 ขอความช่วยเหลือในแชทแล้ว รอเพื่อนมารดน้ำนะ", "🙏 Asked for help in chat, wait for a friend to water it"))
	end
end

-- ขี่สัตว์ที่มี HelpHoldScale (ช้างน้อยใจบุญ 0.5, 2026-11-03) = รดน้ำช่วยใช้เวลาเท่านั้น (ฝั่งผู้เล่นตั้ง HoldDuration ตามกัน)
local function helpHoldScale(player)
	local riding = player:GetAttribute("RidingMount")
	if type(riding) ~= "string" or riding == "" then return 1 end
	local ok, MountConfig = pcall(function() return require(ReplicatedStorage:WaitForChild("MountConfig", 5)) end)
	local def = ok and MountConfig and MountConfig.Mounts[riding]
	return def and tonumber(def.HelpHoldScale) or 1
end

local function helpTree(helper, lot, holeNo, prompt)
	local hh = helpHold[helper]
	helpHold[helper] = nil
	local owner = ownerOf[lot]
	if not owner or owner == helper or owner.Parent ~= Players then return end
	if not (hh and hh.prompt == prompt and os.clock() - hh.t >= Dead.HelpSeconds * helpHoldScale(helper) * 0.9) then return end
	local helperSt = OrchardData.Get(helper)
	if not (helperSt and helperSt.loaded) then
		return notify(helper, msg(helper, "ยังโหลดข้อมูลไม่เสร็จ ลองใหม่อีกครั้ง", "Still loading, please try again"))
	end
	if not (trunkWaterOf(helper) or heldKit(helper, "Can")) then return warnKit(helper, "Can") end -- ขี่ช้างน้อยใจบุญ = พ่นน้ำจากงวงได้ ไม่ต้องถือบัว
	if LevelSystem.GetLevel(helper) < Dead.HelpMinLevel then
		return notify(helper, msg(helper, "ต้องเลเวล " .. Dead.HelpMinLevel .. " ขึ้นไปถึงจะช่วยรดน้ำต้นได้", "Requires level " .. Dead.HelpMinLevel .. " to help water trees"))
	end
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	local root = helper.Character and helper.Character:FindFirstChild("HumanoidRootPart")
	if not (hole and root) or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Dead.HelpRange + 3 then
		return notify(helper, msg(helper, "เดินไปที่ต้นก่อน", "Walk to the tree first"))
	end
	local ownerSt = stateOf(owner)
	local tree = ownerSt and ownerSt.loaded and ownerSt.data.trees[tostring(holeNo)]
	if not (tree and tree.dead and not tree.revived) then
		return notify(helper, msg(helper, "ต้นนี้ช่วยไม่ได้แล้ว", "This tree can't be helped anymore"))
	end
	local ownerKey = tostring(owner.UserId)
	local h = OrchardData.HelpToday(helperSt.data)
	local perOwner = Dead.HelpPerOwnerDaily or 1 -- ช่วยเจ้าของคนเดิมได้วันละกี่ครั้ง (3 ผู้ใช้สั่ง 2026-11-02)
	if (tonumber(h.owners[ownerKey]) or 0) >= perOwner and not isFake(owner) then -- เจ้าของปลอม (Studio) ช่วยซ้ำได้ ทดสอบหลายรอบ
		return notify(helper, msg(helper,
			string.format("💚 วันนี้ช่วยต้นของ %s ครบ %d ครั้งแล้ว พรุ่งนี้มาช่วยใหม่นะ", owner.DisplayName, perOwner),
			string.format("💚 You already helped %s %d times today, come back tomorrow", owner.DisplayName, perOwner)))
	end
	local key = lot.Name .. "#" .. holeNo
	if helpingKey[key] or busy[owner] then return notify(helper, msg(helper, "ลองใหม่อีกครั้ง", "Please try again")) end
	helpingKey[key], busy[owner] = true, true
	local okCall, saved = pcall(commit, owner, ownerSt, function(d)
		local t = d.trees[tostring(holeNo)]
		if not (t and t.dead and not t.revived) then return false end
		OrchardData.StartNewCycle(t, OrchardData.Now())
		-- ฟื้นแล้วเก็บได้ RevivedHarvests รอบ (2026-11-07 ผู้ใช้สั่ง) ครบแล้วแห้ง revived = true รดซ้ำไม่ได้ ต้องตัด
		local total = Config.Trees[t.kind].Harvests or 0
		t.dead, t.revived, t.harvests, t.fed = nil, true, math.max(0, total - Dead.RevivedHarvests), nil
	end)
	busy[owner], helpingKey[key] = nil, nil
	if not (okCall and saved) then
		if not okCall then warn("OrchardService: help error: " .. tostring(saved)) end
		return notify(helper, msg(helper, "ช่วยไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't help, please try again"))
	end
	-- รางวัลคนช่วย (ต้นเจ้าของเซฟแล้ว เหรียญช่วยเหลือเซฟตามหลัง)
	h = OrchardData.HelpToday(helperSt.data)
	h.owners[ownerKey] = (tonumber(h.owners[ownerKey]) or 0) + 1
	h.total += 1
	local reward = h.today < Dead.HelpDailyCoins and Dead.HelpCoins or 0
	if reward > 0 then
		h.today += 1
		h.coins += reward
	end
	OrchardData.SaveLater(helper)
	setHelpCoinsAttr(helper)
	render(owner)
	sync(owner)
	sync(helper)
	-- ประกายเขียวที่ต้นตอนฟื้น
	local fx = Instance.new("Part")
	fx.Size = Vector3.new(6, 1, 6)
	fx.Transparency = 1
	decorPart(fx)
	fx.CFrame = CFrame.new(hole.Position + Vector3.new(0, 3, 0))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(120, 230, 120), Color3.fromRGB(200, 255, 170))
	pe.Size = NumberSequence.new(0.6, 0)
	pe.Lifetime = NumberRange.new(1, 1.6)
	pe.Speed = NumberRange.new(3, 6)
	pe.SpreadAngle = Vector2.new(60, 60)
	pe.Acceleration = Vector3.new(0, 2, 0)
	pe.LightEmission = 0.8
	pe.Rate = 0
	pe.Parent = fx
	fx.Parent = workspace
	pe:Emit(40)
	game:GetService("Debris"):AddItem(fx, 3)
	local def = Config.Trees[tree.kind]
	-- ช่วยรดน้ำสำเร็จ = ป้าย "+N 💚" มุมขวาบนแบบเก็บผลไม้ ไม่มีข้อความกลางจอ (ผู้ใช้สั่ง 2026-11-03) · ครบโควตาวันนี้ = ยังบอกเป็นข้อความ
	if reward > 0 then
		harvestNotify:FireClient(helper, "Orchard:HelpCoin", 0, reward)
	else notify(helper, msg(helper,
			string.format("💚 ช่วยรดน้ำ%sของ %s จนฟื้นแล้ว! (วันนี้ได้เหรียญช่วยเหลือครบ %d ครั้งแล้ว)", def.NameTh, owner.DisplayName, Dead.HelpDailyCoins),
			string.format("💚 You revived %s's %s! (daily help coin limit of %d reached)", owner.DisplayName, def.NameEn, Dead.HelpDailyCoins)))
	end
	notify(owner, msg(owner,
		string.format("💚 %s ช่วยรดน้ำ%sของคุณ ต้นฟื้นแล้ว! เก็บได้อีก %d รอบ (ล็อก %s หลุม %d)", helper.DisplayName, def.NameTh, Dead.RevivedHarvests, lotNo(lot), holeNo),
		string.format("💚 %s watered your %s, it's alive again! %d more harvest(s) (lot %s hole %d)", helper.DisplayName, def.NameEn, Dead.RevivedHarvests, lotNo(lot), holeNo)))
	print(string.format("Orchard: %s ช่วยต้น %s ของ %s (%s หลุม %d) เหรียญช่วยเหลือ +%d", helper.Name, tree.kind, owner.Name, lot.Name, holeNo, reward))
end

for _, lot in ipairs(lots) do
	for i = 1, Config.MAX_TREES do
		local hole = lot:FindFirstChild("Hole" .. i)
		local prompt = hole and hole:FindFirstChild("HelpPrompt")
		if prompt then
			prompt.PromptButtonHoldBegan:Connect(function(player)
				helpHold[player] = { prompt = prompt, t = os.clock() }
				if ownerOf[lot] ~= player and prompt:GetAttribute("CanHelp") == true then
					local ok, err = pcall(startPour, player, hole)
					if not ok then warn("OrchardService: pour error: " .. tostring(err)) end
				end
			end)
			prompt.PromptButtonHoldEnded:Connect(function(player)
				task.delay(0.2, stopPour, player)
			end)
			prompt.Triggered:Connect(function(player)
				task.delay(0.3, stopPour, player)
				local ok, err = pcall(function()
					if ownerOf[lot] == player then askHelp(player, lot, i) else helpTree(player, lot, i, prompt) end
				end)
				if not ok then warn("OrchardService: help error: " .. tostring(err)) end
			end)
		end
	end
end
Players.PlayerRemoving:Connect(function(player)
	helpHold[player], helpAskAt[player], chopToken[player], chopAuto[player], reachToken[player] = nil, nil, nil, nil, nil
	harvesting[player] = nil
	pouring[player] = nil
end)

-- ============ ขโมย (เฟส 3) ============
-- กดค้าง StealPrompt ครบเวลา -> ตรวจทุกอย่างที่เซิร์ฟ -> เซฟสวนเจ้าของ (ผล -1, stolen +1) สำเร็จ = หักมือขโมย 1 + ให้ผล 1 เข้ากระเป๋าคนขโมย
-- กันโกงยิง Triggered ทันที: ต้องเคย PromptButtonHoldBegan ที่ปุ่มเดียวกันนานพอ (90% ของเวลากดค้าง)
local holdStart = {} -- [player] = { prompt, t }
local stealing = {} -- ["Lot01#2"] = true ระหว่างเซฟ
-- ท่าสอยผลค้างจนได้ข้อความ (ผู้ใช้สั่ง 2026-11-16 แบบเดียวกับท่าเก็บผล): กดขโมยครบ = เลิกปุ่มตบ/แจ้งเจ้าของทันที แต่ท่า OrchardPickAt ค้างจน steal แจ้งผล
--   pickToken[thief] = รอบท่า (เพิ่มทุกครั้งที่ตั้ง/ลบท่า) · STEAL_POSE_MAX = กันท่าค้างถ้าเซฟค้าง/สคริปต์ error
local pickToken = {}
local STEAL_POSE_MAX = 8
local function pickPoseDone(thief, tok)
	if pickToken[thief] ~= tok then return end
	local ch = thief.Character
	if ch then ch:SetAttribute("OrchardPickAt", nil) end
end

-- ============ แจ้งเจ้าของ + ตบ (เฟส 4, 2026-10-27) ============
-- เริ่มกดค้าง StealPrompt = attempts[คนขโมย] + ปุ่ม SlapPrompt ที่ตัวคนขโมย (Attribute OwnerId = เจ้าของต้น ฝั่งผู้เล่นโชว์เฉพาะเจ้าของ)
--   + RemoteEvent OrchardAlert ถึงเจ้าของ ("start"/"stop" กรอบแดง + ป้าย 🚨 เหนือหัว) · ปล่อยปุ่ม / ขโมยสำเร็จ = เลิก
-- ตบ = ยกเลิกการขโมย (ล้าง holdStart) + ล้ม ("stun" ถึงคนขโมย + ปลดของในมือ) + เสียตะกร้อ 1 + เจ้าของได้เงิน + ต้นพัก TreeCooldown
local alertRemote = remote("RemoteEvent", "OrchardAlert")
local stunnedUntil = {} -- [คนขโมย] = os.clock()

-- มือตบ (2026-10-29): ถืออยู่ = ตบได้ไกล SlapHandRange · ตบโดนตอนถือ = หมด 1 อัน (useSlapHand)
local function slapReach()
	return math.max(Steal.SlapRange, Steal.SlapHandRange or 0)
end
local function slapRangeOf(owner)
	return OrchardItems.HeldSlap(owner) and (Steal.SlapHandRange or Steal.SlapRange) or Steal.SlapRange
end
-- 2026-10-29 ผู้ใช้สั่ง: มือตบเป็นของถาวร (ซื้อครั้งเดียว 1,000,000) ตบแล้วไม่หมด · คืน true = ตบด้วยมือตบ
local function useSlapHand(owner)
	return OrchardItems.HeldSlap(owner)
end

local function selfStealTest()
	return RunService:IsStudio() and workspace:GetAttribute("DevOrchardSelfSteal") == true
end

local slapThief -- (ตั้งค่าด้านล่าง ถัดจาก steal)

local function endAttempt(thief, why, keepPose) -- keepPose = กดขโมยครบ ให้ท่าค้างระหว่างเซฟ (2026-11-16)
	local at = attempts[thief]
	if not at then return end
	attempts[thief] = nil
	if at.slap then at.slap:Destroy() end
	if at.char and not keepPose then
		pickToken[thief] = (pickToken[thief] or 0) + 1
		at.char:SetAttribute("OrchardPickAt", nil)
	end
	if at.owner.Parent and not isFake(at.owner) then alertRemote:FireClient(at.owner, "stop", { thief = thief, why = why }) end
end

local function beginAttempt(thief, lot, holeNo, prompt)
	local owner = ownerOf[lot]
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	if not (owner and hole) or (owner == thief and not selfStealTest()) then return end
	local held, tier = OrchardItems.HeldHand(thief)
	if prompt:GetAttribute("CanSteal") ~= true or not held then return end
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if attempts[thief] then endAttempt(thief, "switch") end
	local ownerSt = stateOf(owner)
	local tree = ownerSt and ownerSt.data and ownerSt.data.trees[tostring(holeNo)]
	local def = tree and Config.Trees[tree.kind]
	local slap = Instance.new("ProximityPrompt")
	slap.Name = "SlapPrompt"
	slap.ActionText = "ตบ"
	slap.ObjectText = "🚨 " .. thief.DisplayName
	slap.KeyboardKeyCode = Enum.KeyCode.F
	slap.GamepadKeyCode = Enum.KeyCode.ButtonY
	slap.HoldDuration = 0
	slap.MaxActivationDistance = slapReach() -- ไกลสุด (ถือมือตบ) ฝั่งเจ้าของลดเหลือ SlapRange เองตอนไม่ได้ถือ (OrchardGui)
	slap.RequiresLineOfSight = false
	slap.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	slap:SetAttribute("OwnerId", owner.UserId)
	slap.Parent = root
	attempts[thief] = { owner = owner, lot = lot, holeNo = holeNo, hole = hole, prompt = prompt, slap = slap, char = thief.Character, tier = tier }
	-- ท่าสอยผลไม้ (2026-10-27): ทุกเครื่อง (OrchardGui) ยกแขนขวาชี้ไม้เข้าพุ่มใบของตัวที่มี Attribute นี้ · คนขโมยหันหน้าเข้าต้น
	pickToken[thief] = (pickToken[thief] or 0) + 1 -- รอบใหม่ = ตัวลบท่าของการขโมยก่อนหน้าข้าม (2026-11-16)
	thief.Character:SetAttribute("OrchardPickAt", hole.Position)
	local treeModel = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. holeNo)
	if treeModel then
		local myAttempt = attempts[thief]
		shakeWhileStealing(treeModel, hole, function() return attempts[thief] == myAttempt end)
	end
	if isFake(owner) and onFakeAttempt then task.spawn(onFakeAttempt, thief, attempts[thief]) end
	slap.Triggered:Connect(function(player)
		local ok, err = pcall(function() slapThief(player, thief) end)
		if not ok then warn("OrchardService: slap error: " .. tostring(err)) end
	end)
	if not isFake(owner) then
		thiefAlertAt[owner] = os.clock()
		alertRemote:FireClient(owner, "start", { thief = thief, lot = lot.Name, hole = holeNo, kind = tree and tree.kind, seconds = tree and Config.StealSeconds(tree.kind, tier) })
	end
	local name = def and msg(owner, def.NameTh, def.NameEn) or "?"
	notify(owner, msg(owner,
		string.format("🚨 %s กำลังขโมย%sของคุณ! (ล็อก %s หลุม %d) รีบไปกด \"ตบ\" ที่ตัวคนขโมย", thief.DisplayName, name, lotNo(lot), holeNo),
		string.format("🚨 %s is stealing your %s! (lot %s hole %d) Hurry and press \"Slap\" on them", thief.DisplayName, name, lotNo(lot), holeNo)))
end

local function steal(thief, lot, holeNo, prompt, myPick)
	local hs = holdStart[thief]
	holdStart[thief] = nil
	endAttempt(thief, "done", true) -- ท่าค้างจนแจ้งผล (2026-11-16)
	-- ลบท่าก่อนทุกข้อความใน steal (ขโมยไม่ได้/เซฟไม่ได้) · ทางสำเร็จลบก่อนป้าย +1 · ทางเงียบ = Triggered ลบหลัง steal จบ
	local notify0 = notify
	local function notify(p, text)
		pickPoseDone(thief, myPick)
		return notify0(p, text)
	end
	local owner = ownerOf[lot]
	-- Studio: workspace DevOrchardSelfSteal = true ให้ขโมยต้นตัวเองได้ (ทดสอบคนเดียว)
	if not owner or (owner == thief and not selfStealTest()) or owner.Parent ~= Players then return end
	local ownerSt = stateOf(owner)
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	local tree = ownerSt and ownerSt.loaded and ownerSt.data.trees[tostring(holeNo)]
	if not (tree and hole) then return end
	local kind = tree.kind
	local def = Config.Trees[kind]
	local held, tier = OrchardItems.HeldHand(thief)
	local need = Config.StealSeconds(kind, held and tier or nil) -- ตะกร้อจอมโจร = ไวกว่า (2026-11-02)
	if not (hs and hs.prompt == prompt and os.clock() - hs.t >= need * 0.9) then return end
	if LevelSystem.GetLevel(thief) < Steal.MinLevel then
		return notify(thief, msg(thief, "ต้องเลเวล " .. Steal.MinLevel .. " ขึ้นไปถึงจะขโมยได้", "Requires level " .. Steal.MinLevel .. " to steal"))
	end
	if not isFake(owner) and LevelSystem.GetLevel(owner) < Steal.MinLevel then
		return notify(thief, msg(thief, "เจ้าของต้นนี้เลเวลยังไม่ถึง " .. Steal.MinLevel .. " ขโมยไม่ได้", "This tree's owner is below level " .. Steal.MinLevel .. ", can't steal"))
	end
	if thief:GetAttribute("InventoryLoaded") == false then return end
	if not held then
		return notify(thief, msg(thief, Steal.HandIcon .. " ถือ" .. Steal.HandNameTh .. "ก่อน (ซื้อได้ที่ร้านผลไม้ & อุปกรณ์หน้าสวน)", Steal.HandIcon .. " Hold a " .. Steal.HandNameEn:lower() .. " first (sold at the Fruit & Tools stall by the orchard gate)"))
	end
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not root or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hole.Position.X, 0, hole.Position.Z)).Magnitude > Steal.Range + 3 then
		return notify(thief, msg(thief, "เดินไปใต้ต้นก่อน", "Stand under the tree first"))
	end
	if cooling(hole) then
		return notify(thief, msg(thief, "👋 ต้นนี้เจ้าของเพิ่งจับขโมยได้ พักอีกสักพัก", "👋 The owner just caught a thief at this tree, try later"))
	end
	if not canBeStolen(tree, OrchardData.Now()) then
		return notify(thief, msg(thief, "ต้นนี้ขโมยไม่ได้แล้ว (ต้นละ " .. Steal.PerCycle .. " ครั้งต่อรอบผล และต้องเหลือผลให้เจ้าของ)", "This tree can't be stolen from now (once per fruit round, the owner keeps some)"))
	end
	local key = lot.Name .. "#" .. holeNo
	if stealing[key] or busy[owner] then
		return notify(thief, msg(thief, "ลองใหม่อีกครั้ง", "Please try again"))
	end
	stealing[key], busy[owner] = true, true
	local okCall, saved = pcall(commit, owner, ownerSt, function(d)
		local tr = d.trees[tostring(holeNo)]
		if not (tr and tr.kind == kind and canBeStolen(tr, OrchardData.Now())) then return false end
		tr.fruits -= 1
		tr.stolen = (tr.stolen or 0) + 1
		d.stats.stolenFrom += 1
	end)
	busy[owner] = nil
	if not (okCall and saved) then
		stealing[key] = nil
		if not okCall then warn("OrchardService: steal error: " .. tostring(saved)) end
		return notify(thief, msg(thief, "ขโมยไม่สำเร็จ ลองใหม่อีกครั้ง", "Steal failed, please try again"))
	end
	-- มือขโมยหายระหว่างเซฟ (เกิดยาก) = คืนผลให้เจ้าของ ไม่ให้ของฟรี
	if not OrchardItems.TakeHand(thief, 1, lang(thief), tier) then
		local tr = ownerSt.data.trees[tostring(holeNo)]
		if tr then
			tr.fruits += 1
			tr.stolen = math.max(0, (tr.stolen or 1) - 1)
			ownerSt.data.stats.stolenFrom = math.max(0, ownerSt.data.stats.stolenFrom - 1)
			if not isFake(owner) then OrchardData.SaveLater(owner) end
		end
		stealing[key] = nil
		return
	end
	OrchardItems.Give(thief, OrchardItems.FRUIT, kind, 1, lang(thief))
	saveBag(thief)
	local thiefSt = OrchardData.Get(thief)
	if thiefSt and thiefSt.loaded then
		thiefSt.data.stats.stole += 1
		OrchardData.SaveLater(thief)
	end
	stealing[key] = nil
	render(owner)
	sync(owner)
	-- ต้นใหม่ (ผลเหลือน้อยลง) โยกต่ออีกนิดตอนผลหลุดออก (แบบเดียวกับเก็บเกี่ยว)
	local swayModel = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. tostring(holeNo))
	if swayModel then swayTree(swayModel, hole) end
	-- ขโมยสำเร็จ = ป้ายมุมขวาบน "+1 🥭" แบบเดียวกับเก็บเกี่ยว ไม่มีข้อความกลางจอ (ผู้ใช้สั่ง 2026-11-03)
	pickPoseDone(thief, myPick)
	harvestNotify:FireClient(thief, "Orchard:" .. kind, 0, 1)
	notify(owner, msg(owner,
		string.format("😱 %s ขโมย%sของคุณไป 1 ผล! (ล็อก %s หลุม %d)", thief.DisplayName, def.NameTh, lotNo(lot), holeNo),
		string.format("😱 %s stole 1 of your %s! (lot %s hole %d)", thief.DisplayName, def.NameEn, lotNo(lot), holeNo)))
	print(string.format("Orchard: %s ขโมย %s จาก %s (%s หลุม %d)", thief.Name, kind, owner.Name, lot.Name, holeNo))
end

-- เจ้าของกด "ตบ" ที่ตัวคนขโมยระหว่างที่กำลังกดค้างขโมยอยู่
slapThief = function(owner, thief)
	local at = attempts[thief]
	if not at or at.owner ~= owner then return end
	local oRoot = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
	local tRoot = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not tRoot then return end
	if not isFake(owner) and (not oRoot or (oRoot.Position - tRoot.Position).Magnitude > slapRangeOf(owner) + 4) then return end -- เจ้าของปลอมไม่มีตัว ตบได้จากทุกที่ · ถือมือตบ = ไกลกว่า
	if not isFake(owner) then
		useSlapHand(owner)
		alertRemote:FireAllClients("slapfx", { owner = owner, target = thief.Character }) -- แขนยืดไปตบ (OrchardGui) 2026-10-29
	end
	holdStart[thief] = nil -- ยกเลิกการขโมย (Triggered ทีหลังจะไม่ผ่าน)
	endAttempt(thief, "slapped")
	caughtUntil[at.hole] = os.clock() + (Steal.TreeCooldown or 600)
	stunnedUntil[thief] = os.clock() + Steal.StunSeconds
	local hum = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:UnequipTools() end
	local from = owner -- ทิศที่กระเด็น (เจ้าของปลอม = ตำแหน่งยาม)
	if isFake(owner) then
		local gRoot = fakeGuard and fakeGuard:FindFirstChild("HumanoidRootPart")
		from = gRoot and gRoot.Position or nil
	end
	alertRemote:FireClient(thief, "stun", { seconds = Steal.StunSeconds, from = from })
	-- ป้าย 👋💥 เหนือหัวคนขโมย ทุกคนเห็น
	local head = thief.Character and thief.Character:FindFirstChild("Head")
	if head then
		local bb = Instance.new("BillboardGui")
		bb.Name = "SlapPop"
		bb.Size = UDim2.fromScale(3, 3)
		bb.StudsOffset = Vector3.new(0, 2.6, 0)
		bb.AlwaysOnTop = true
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Text = "👋💥"
		l.TextScaled = true
		l.Parent = bb
		bb.Parent = head
		game:GetService("Debris"):AddItem(bb, 1.5)
	end
	-- เสียตะกร้อ 1 / เจ้าของได้รางวัล (ได้เฉพาะตอนคนขโมยเสียตะกร้อจริง)
	local lost = OrchardItems.TakeHand(thief, 1, lang(thief), at.tier) -- เสียตะกร้ออันที่ถือตอนเริ่มขโมย (ธรรมดา/จอมโจร)
	if lost then saveBag(thief) end
	local reward = lost and math.floor(Steal.HandPrice * (Steal.CatchReward or 0)) or 0
	local coins = not isFake(owner) and coinsOf(owner)
	if coins and reward > 0 and owner:GetAttribute("CoinsLoaded") == true then
		CheatWatch.AllowCoinGain(owner, reward)
		coins.Value += reward
		if saveCoinsNow then saveCoinsNow:Fire(owner) end
	else
		reward = 0
	end
	render(owner)
	notify(thief, msg(thief,
		string.format("👋 %s จับได้! โดนตบล้ม %d วิ%s", owner.DisplayName, Steal.StunSeconds, lost and (" เสีย" .. (Config.HandInfo(at.tier, "th")) .. " 1 อัน") or ""),
		string.format("👋 %s caught you! Knocked down for %ds%s", owner.DisplayName, Steal.StunSeconds, lost and (", lost 1 " .. (Config.HandInfo(at.tier, "en")):lower()) or "")))
	notify(owner, msg(owner,
		string.format("👋 ตบ %s ทัน!%s%s", thief.DisplayName, (Steal.TreeCooldown or 0) >= 60 and string.format(" ต้นนี้ปลอดภัย %d นาที", math.floor((Steal.TreeCooldown or 600) / 60)) or "", reward > 0 and (" · ได้ " .. Config.Short(reward) .. " เหรียญ") or ""),
		string.format("👋 You slapped %s in time!%s%s", thief.DisplayName, (Steal.TreeCooldown or 0) >= 60 and string.format(" This tree is safe for %d min", math.floor((Steal.TreeCooldown or 600) / 60)) or "", reward > 0 and (" · +" .. Config.Short(reward) .. " coins") or "")))
	print(string.format("Orchard: %s ตบ %s (%s หลุม %d) รางวัล %d", owner.Name, thief.Name, at.lot.Name, at.holeNo, reward))
end

-- มือตบฟาดแบบค้อนยางตีตู้สุ่ม (2026-10-29 ผู้ใช้สั่ง, ดู MountSystem.ToyHammerService): คลิก/แตะที่ไหนก็ได้ = ท่าฟาด (toolanim "Slash")
-- 0.15 วิต่อมาหาคนที่กำลังขโมยต้นเราที่ใกล้สุดในระยะมือตบ (แนวราบ) → slapThief (หักมือตบ + slapfx) · ไม่มีใครในระยะ = ฟาดลม ไม่เสียมือตบ
local SWING_COOLDOWN = 0.45
local lastSlapSwing = {}
OrchardItems.OnSlapSwing = function(tool)
	local player = Players:GetPlayerFromCharacter(tool.Parent)
	if not player then return end
	local now = os.clock()
	if lastSlapSwing[player] and now - lastSlapSwing[player] < SWING_COOLDOWN then return end
	lastSlapSwing[player] = now
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	task.delay(1, function() if anim.Parent then anim:Destroy() end end)
	task.delay(0.15, function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not (root and tool.Parent == player.Character) then return end
		local reach = slapRangeOf(player)
		local function flatDist(p) return ((p - root.Position) * Vector3.new(1, 0, 1)).Magnitude end
		local best, bestDist = nil, reach
		for thief, at in pairs(attempts) do
			local tRoot = at.owner == player and thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
			if tRoot and flatDist(tRoot.Position) <= bestDist then best, bestDist = thief, flatDist(tRoot.Position) end
		end
		local fake = fakeThiefSlap and workspace:FindFirstChild("OrchardFakeThief")
		local fRoot = fake and fake:FindFirstChild("HumanoidRootPart")
		if fRoot and fRoot:FindFirstChild("SlapPrompt") and flatDist(fRoot.Position) <= bestDist then
			fakeThiefSlap(player)
			return
		end
		if best then slapThief(player, best) end
	end)
end
Players.PlayerRemoving:Connect(function(player) lastSlapSwing[player] = nil end)

for _, lot in ipairs(lots) do
	for i = 1, Config.MAX_TREES do
		local hole = lot:FindFirstChild("Hole" .. i)
		local prompt = hole and hole:FindFirstChild("StealPrompt")
		if prompt then
			prompt.PromptButtonHoldBegan:Connect(function(player)
				if stunnedUntil[player] and os.clock() < stunnedUntil[player] then return end -- กำลังล้มอยู่
				holdStart[player] = { prompt = prompt, t = os.clock() }
				local ok, err = pcall(beginAttempt, player, lot, i, prompt)
				if not ok then warn("OrchardService: alert error: " .. tostring(err)) end
			end)
			prompt.PromptButtonHoldEnded:Connect(function(player)
				-- ปล่อยก่อนครบ = เลิก (เว้นนิดให้ Triggered ทำงานก่อนตอนกดครบ)
				task.delay(0.3, function()
					local at = attempts[player]
					if at and at.prompt == prompt then endAttempt(player, "released") end
				end)
			end)
			prompt.Triggered:Connect(function(player)
				-- ท่าสอยค้างจนได้ผล (2026-11-16): รอบท่านี้ = ค่าตอนกดครบ · กันค้าง STEAL_POSE_MAX · steal จบ (ทุกทาง) = ลบท่า
				local tok = pickToken[player]
				task.delay(STEAL_POSE_MAX, pickPoseDone, player, tok)
				local ok, err = pcall(steal, player, lot, i, prompt, tok)
				pickPoseDone(player, tok)
				if not ok then warn("OrchardService: steal error: " .. tostring(err)) end
			end)
		end
	end
end

-- ============ ย้ายมาแปลงว่าง (ผู้ใช้สั่ง 2026-11-06) ============
-- ปุ่ม MovePrompt ที่ป้ายทุกล็อก ฝั่งผู้เล่น (OrchardGui) โชว์เฉพาะล็อกว่าง + เรามีล็อกอยู่แล้ว · ต้นเก็บตามเลขหลุม ย้าย = วาดในล็อกใหม่ เวลา/ผล/รอบเก็บเดิม
-- โจรกำลังขโมยต้นไหนก็ตามในล็อกเรา = ย้ายไม่ได้ · ต้นที่กำลังพักหลังตบโจร (caughtUntil) ย้ายเวลาพักตามไป
local MOVE_COOLDOWN, MOVE_RANGE = 30, 16
local lastMove = {} -- [player] = os.clock()

local function stealingFromMe(player)
	for _, at in pairs(attempts) do
		if at.owner == player then return true end
	end
	return false
end

local function moveLot(player, target)
	local from = lotOf[player]
	if not from or from == target then return end
	local st = stateOf(player)
	if not (st and st.loaded and OrchardData.TreeCount(st.data) > 0) then return end
	if ownerOf[target] then return notify(player, msg(player, "ล็อกนี้มีเจ้าของแล้ว", "This lot is already taken")) end
	if stealingFromMe(player) then
		return notify(player, msg(player, "🚨 มีคนกำลังขโมยต้นของคุณอยู่ ย้ายไม่ได้", "🚨 Someone is stealing from your trees, you can't move now"))
	end
	if busy[player] then return notify(player, msg(player, "ลองใหม่อีกครั้ง", "Please try again")) end
	local left = (lastMove[player] or -MOVE_COOLDOWN) + MOVE_COOLDOWN - os.clock()
	if left > 0 then
		return notify(player, msg(player, "รออีก " .. math.ceil(left) .. " วิ ค่อยย้ายใหม่", "Wait " .. math.ceil(left) .. "s before moving again"))
	end
	local board = target:FindFirstChild("SignBoard")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (board and root) or (root.Position - board.Position).Magnitude > MOVE_RANGE then
		return notify(player, msg(player, "เดินไปที่ป้ายก่อน", "Walk to the sign first"))
	end
	busy[player] = true
	local okCall, saved = pcall(commit, player, st, function(d) d.lot = target.Name end)
	busy[player] = nil
	if not (okCall and saved) then
		if not okCall then warn("OrchardService: moveLot error: " .. tostring(saved)) end
		return notify(player, msg(player, "ย้ายไม่สำเร็จ ลองใหม่อีกครั้ง", "Couldn't move, please try again"))
	end
	-- เซฟใช้เวลา ระหว่างนั้นอาจมีคนเอาล็อกไปก่อน หรือโจรเริ่มขโมย
	if player.Parent ~= Players or lotOf[player] ~= from then return end
	if ownerOf[target] then return notify(player, msg(player, "ล็อกนี้มีเจ้าของแล้ว", "This lot is already taken")) end
	if stealingFromMe(player) then
		return notify(player, msg(player, "🚨 มีคนกำลังขโมยต้นของคุณอยู่ ย้ายไม่ได้", "🚨 Someone is stealing from your trees, you can't move now"))
	end
	for i = 1, Config.MAX_TREES do
		local oldHole, newHole = from:FindFirstChild("Hole" .. i), target:FindFirstChild("Hole" .. i)
		if oldHole and caughtUntil[oldHole] then
			if newHole then caughtUntil[newHole] = caughtUntil[oldHole] end
			caughtUntil[oldHole] = nil
		end
	end
	ownerOf[from] = nil
	clearLot(from)
	assignLot(player, target)
	lastMove[player] = os.clock()
	sync(player)
	notify(player, msg(player, "🌳 ย้ายสวนมาล็อก " .. lotNo(target) .. " แล้ว", "🌳 Moved your orchard to lot " .. lotNo(target)))
	task.defer(giveFreeLots)
end

for _, lot in ipairs(lots) do
	local board = lot:FindFirstChild("SignBoard")
	if board and not board:FindFirstChild("MovePrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "MovePrompt"
		prompt.ActionText = "ย้ายมาแปลงนี้"
		prompt.ObjectText = "🌳 ล็อก " .. lotNo(lot)
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 1
		prompt.Parent = board
	end
end
-- กดปุ่มที่ป้าย = หน้าต่างยืนยันฝั่งผู้เล่น (OrchardGui) ยืนยันแล้วถึงยิงมาที่นี่ (2026-11-07 ผู้ใช้สั่ง) · moveLot ตรวจทุกอย่างซ้ำ
remote("RemoteEvent", "OrchardMoveLot").OnServerEvent:Connect(function(player, lotName)
	if type(lotName) ~= "string" then return end
	for _, lot in ipairs(lots) do
		if lot.Name == lotName then
			local ok, err = pcall(moveLot, player, lot)
			if not ok then warn("OrchardService: moveLot error: " .. tostring(err)) end
			return
		end
	end
end)
Players.PlayerRemoving:Connect(function(player) lastMove[player] = nil end)

-- ============ ทดสอบใน Studio ============
if RunService:IsStudio() then
	local dev = ServerStorage:FindFirstChild("OrchardDev") or Instance.new("BindableFunction")
	dev.Name = "OrchardDev"
	dev.Parent = ServerStorage
	-- ยามเฝ้าสวนของเจ้าของปลอม (2026-10-27 ผู้ใช้สั่ง ทดสอบโดนตบ): พัก GUARD_REACT วิ -> เดินไล่ -> ถึงตัว = หันหน้า ฟาดแขน (Attribute SlapAt ให้ OrchardGui) แล้ว slapThief -> เดินกลับจุดยืน
	local GUARD_REACT, GUARD_REACH = 3, 4.5
	local function removeGuard()
		if fakeGuard then fakeGuard:Destroy() end
		fakeGuard, guardPost = nil, nil
	end
	local function spawnGuard(lot)
		removeGuard()
		local template = templates:FindFirstChild("FakeGuard")
		if not template then return end
		local sum, n = Vector3.zero, 0
		for i = 1, Config.MAX_TREES do
			local h = lot:FindFirstChild("Hole" .. i)
			if h then sum += h.Position n += 1 end
		end
		if n == 0 then return end
		guardPost = sum / n + Vector3.new(0, 4, 0)
		local g = template:Clone()
		g.Name = "OrchardFakeGuard"
		g.Humanoid.DisplayName = "👨‍🌾 " .. fakeOwner.DisplayName
		g.Humanoid.WalkSpeed = 14
		g:PivotTo(CFrame.new(guardPost))
		g.Parent = workspace
		g.HumanoidRootPart:SetNetworkOwner(nil)
		fakeGuard = g
	end
	onFakeAttempt = function(thief, at)
		local g = fakeGuard
		if not (g and guardOn) then return end
		local hum = g:FindFirstChildOfClass("Humanoid")
		local root = g:FindFirstChild("HumanoidRootPart")
		if not (hum and root) then return end
		task.wait(GUARD_REACT)
		while attempts[thief] == at and g.Parent do
			local tRoot = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
			if not tRoot then break end
			local d = (tRoot.Position - root.Position) * Vector3.new(1, 0, 1)
			if d.Magnitude <= GUARD_REACH then
				hum:MoveTo(root.Position)
				root.CFrame = CFrame.lookAt(root.Position, root.Position + d)
				g:SetAttribute("SlapAt", workspace:GetServerTimeNow())
				task.wait(0.18) -- ให้แขนง้างก่อนโดน
				if attempts[thief] == at then slapThief(fakeOwner, thief) end
				break
			end
			hum:MoveTo(tRoot.Position - d.Unit * 3)
			task.wait(0.25)
		end
		task.wait(1.5)
		if g.Parent and guardPost then hum:MoveTo(guardPost) end
	end

	dev.OnInvoke = function(player, action, a, b)
		if action == "setCoins" then
			local c = coinsOf(player)
			local value = math.floor(tonumber(a) or -1)
			if not c or value < 0 then return "?" end
			if value > c.Value then CheatWatch.AllowCoinGain(player, value - c.Value) end
			local before = c.Value
			c.Value = value
			if saveCoinsNow then saveCoinsNow:Fire(player) end
			return string.format("coins %d -> %d", before, value)
		end
		-- "slapself": ตบตัวเองระหว่างกำลังขโมยต้นตัวเอง (DevOrchardSelfSteal) เพราะปุ่มบนตัวละครเราเองไม่ขึ้นให้กด
		if action == "slapself" then
			if not attempts[player] then return "ไม่ได้กำลังขโมยอยู่" end
			slapThief(attempts[player].owner, player)
			return "slapped"
		end
		-- เจ้าของปลอม: ล็อกว่างล็อกแรก ต้นมะม่วง a ต้น (ค่าเริ่ม 5) ผลสุกต้นละ 2 ผล (ขโมยได้ต้นละ 1) · b = "grow" ปลูกใหม่ให้โตตามเวลา
		if action == "fakeowner" or action == "fakeclear" then
			if fakeOwner then
				for thief, at in pairs(attempts) do
					if at.owner == fakeOwner then endAttempt(thief, "owner left") end
				end
				local lot = lotOf[fakeOwner]
				if lot then
					lotOf[fakeOwner], ownerOf[lot] = nil, nil
					clearLot(lot)
				end
				fakeOwner, fakeState = nil, nil
				removeGuard()
			end
			if action == "fakeclear" then return "fake owner removed" end
			local lot
			for _, l in ipairs(lots) do
				if not ownerOf[l] then lot = l break end
			end
			if not lot then return "สวนเต็ม" end
			local n = math.clamp(math.floor(tonumber(a) or Config.MAX_TREES), 1, Config.MAX_TREES)
			local def = Config.Trees.Mango
			local now = OrchardData.Now()
			local planted = b == "grow" and now or (now - def.GrowSeconds - def.FruitSeconds - 1)
			local trees = {}
			for i = 1, n do
				trees[tostring(i)] = { kind = "Mango", plantedAt = planted, cycleStart = planted + def.GrowSeconds, fruits = 2, stolen = 0 }
			end
			fakeOwner = { Name = "FakeFarmer", DisplayName = "ชาวสวนทดสอบ", UserId = -999, Parent = Players }
			fakeState = { loaded = true, data = { v = 1, slots = Config.MAX_TREES, trees = trees, stats = { harvested = 0, sold = 0, coins = 0, stolenFrom = 0, stole = 0 } } }
			ownerOf[lot], lotOf[fakeOwner] = fakeOwner, lot
			lot:SetAttribute("OwnerId", fakeOwner.UserId)
			setSign(lot, fakeOwner)
			render(fakeOwner)
			spawnGuard(lot)
			return string.format("fake owner at %s: %d mango (%s) guard=%s", lot.Name, n, b == "grow" and "growing" or "ripe", fakeGuard and (guardOn and "on" or "off") or "none")
		end
		if action == "fakeguard" then
			guardOn = a ~= false
			return "guard " .. (guardOn and "on" or "off")
		end
		if action == "fakeslap" then
			for thief, at in pairs(attempts) do
				if fakeOwner and at.owner == fakeOwner then
					slapThief(fakeOwner, thief)
					return "slapped " .. thief.Name
				end
			end
			return "ไม่มีใครกำลังขโมยต้นเจ้าของปลอม"
		end
		-- ทดสอบป๊อปแจ้งเตือนขโมยคนเดียว (2026-10-28): ทำเหมือนมีคนกำลังขโมยต้นของเรา (คนขโมย = ตัวเราเอง)
		if action == "alertself" then
			thiefAlertAt[player] = os.clock()
			alertRemote:FireClient(player, "start", { thief = player, lot = lotOf[player] and lotOf[player].Name or "Lot01", hole = tonumber(a) or 1, kind = "Mango" })
			return "alert sent"
		end
		-- คนขโมยปลอม (2026-10-28): NPC ยืนใต้ต้นในล็อกเรา ถือตะกร้อ → แจ้งเตือนเหมือนของจริง (ป๊อป + กรอบแดง + ปุ่มตบ) · ครบเวลาขโมย = หนีไป (ไม่หักผลจริง) · โดนตบ = กระเด็นหายไป
		if action == "fakethief" then
			local lot = lotOf[player]
			if not lot then return "ยังไม่มีล็อก" end
			local holeNo = tonumber(a) or 1
			local hole = lot:FindFirstChild("Hole" .. holeNo)
			if not hole then return "ไม่มีหลุม " .. holeNo end
			local st = stateOf(player)
			local tree = st and st.data and st.data.trees[tostring(holeNo)]
			local kind = tree and tree.kind or "Mango"
			local secs = Steal.Seconds[kind] or 25
			local old = workspace:FindFirstChild("OrchardFakeThief")
			if old then old:Destroy() end
			local desc = Instance.new("HumanoidDescription")
			desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = Color3.fromRGB(245, 205, 150), Color3.fromRGB(245, 205, 150), Color3.fromRGB(245, 205, 150)
			desc.TorsoColor, desc.LeftLegColor, desc.RightLegColor = Color3.fromRGB(60, 60, 70), Color3.fromRGB(40, 40, 50), Color3.fromRGB(40, 40, 50)
			local npc = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
			npc.Name = "OrchardFakeThief"
			npc:SetAttribute("DisplayName", "โจรทดสอบ")
			local hum = npc:FindFirstChildOfClass("Humanoid")
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			local root = npc:WaitForChild("HumanoidRootPart")
			local from = hole.Position + Vector3.new(3, 0, 2)
			npc:PivotTo(CFrame.lookAt(from + Vector3.new(0, 3, 0), Vector3.new(hole.Position.X, from.Y + 3, hole.Position.Z)))
			-- ตะกร้อ (Model มี Handle) เชื่อมกับมือขวา ถือตั้งขึ้น
			local picker = templates:FindFirstChild("StealPicker")
			local hand = npc:FindFirstChild("RightHand")
			if picker and hand and picker.PrimaryPart then
				local p = picker:Clone()
				for _, d in ipairs(p:GetDescendants()) do
					if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanQuery, d.Massless = false, false, false, true end
				end
				p:PivotTo(hand.CFrame * CFrame.new(0, -0.2, 0))
				for _, d in ipairs(p:GetDescendants()) do
					if d:IsA("BasePart") and d ~= p.PrimaryPart then
						local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = p.PrimaryPart, d; w.Parent = d
					end
				end
				local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = hand, p.PrimaryPart; w.Parent = hand
				p.Parent = npc
			end
			npc.Parent = workspace
			local done = false
			local slap = Instance.new("ProximityPrompt")
			slap.Name = "SlapPrompt"
			slap.ActionText = "ตบ"
			slap.ObjectText = "🚨 โจรทดสอบ"
			slap.KeyboardKeyCode = Enum.KeyCode.F
			slap.GamepadKeyCode = Enum.KeyCode.ButtonY
			slap.HoldDuration = 0
			slap.MaxActivationDistance = slapReach()
			slap.RequiresLineOfSight = false
			slap.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
			slap:SetAttribute("OwnerId", player.UserId)
			slap.Parent = root
			local function finish(slapped)
				if done then return end
				done = true
				if player.Parent then alertRemote:FireClient(player, "stop", { thief = npc, why = slapped and "slap" or "done" }) end
				slap:Destroy()
				if slapped then
					notify(player, msg(player, "👋 ตบโจรทดสอบกระเด็นไปแล้ว! (จำลอง)", "👋 You slapped the test thief away! (simulated)"))
					alertRemote:FireAllClients("slapfx", { owner = player, target = npc })
					task.wait(0.16) -- รอมือยืดไปถึงก่อนกระเด็น
					hum.PlatformStand = true
					local pr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local dir = pr and (root.Position - pr.Position) or root.CFrame.LookVector
					dir = Vector3.new(dir.X, 0, dir.Z)
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(1, 0, 0)
					root.AssemblyLinearVelocity = dir * 40 + Vector3.new(0, 30, 0)
					root.AssemblyAngularVelocity = Vector3.new(4, 0, 4)
				else
					notify(player, msg(player, "😭 โจรทดสอบขโมยสำเร็จแล้วหนีไป (จำลอง ไม่หักผลจริง)", "😭 The test thief got away (simulated, no fruit lost)"))
				end
				task.delay(slapped and 2.5 or 0.5, function() if npc.Parent then npc:Destroy() end end)
			end
			local function slapFake(who)
				if who ~= player or done then return false end
				local pr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not pr or (pr.Position - root.Position).Magnitude > slapRangeOf(player) + 4 then return false end
				finish(true)
				return true
			end
			fakeThiefSlap = slapFake
			slap.Triggered:Connect(slapFake)
			thiefAlertAt[player] = os.clock()
			alertRemote:FireClient(player, "start", { thief = npc, lot = lot.Name, hole = holeNo, kind = kind })
			notify(player, msg(player,
				string.format("🚨 โจรทดสอบกำลังขโมยของคุณ! (ล็อก %s หลุม %d) รีบไปกด \"ตบ\" ที่ตัวคนขโมย", lotNo(lot), holeNo),
				string.format("🚨 A test thief is stealing from you! (lot %s hole %d) Hurry and press \"Slap\" on them", lotNo(lot), holeNo)))
			task.delay(secs, function() finish(false) end)
			return string.format("fake thief at %s hole %d (%s, %ds)", lot.Name, holeNo, kind, secs)
		end
		if action == "askfake" then -- "askfake"(ชื่อล็อก, หลุม) เจ้าของปลอมกดขอความช่วยเหลือ (ทดสอบป็อป 2026-11-07)
			for _, l in ipairs(lots) do
				if l.Name == a and ownerOf[l] and ownerOf[l] ~= player then
					helpAskAt[ownerOf[l]] = nil
					askHelp(ownerOf[l], l, tonumber(b) or 1)
					return "asked"
				end
			end
			return "no lot"
		end
		if action == "moveto" then -- "moveto"(ชื่อล็อก) ย้ายล็อกเหมือนกดปุ่ม (2026-11-06)
			local target
			for _, l in ipairs(lots) do if l.Name == a then target = l end end
			if not target then return "ไม่รู้จักล็อก" end
			local stealing = stealingFromMe(player)
			moveLot(player, target)
			return string.format("stealing=%s lot=%s", tostring(stealing), lotOf[player] and lotOf[player].Name or "-")
		end
		if action == "hand" then
			OrchardItems.GiveHand(player, math.max(1, math.floor(tonumber(a) or 1)), lang(player))
			saveBag(player)
			return "hand given"
		end
		-- ต้นแห้ง (2026-11-02): "mat"("Wood"/"Fertilizer", n) ให้ของ · "fakedead"(หลุม) ต้นเจ้าของปลอมแห้ง (ทดสอบรดน้ำช่วยคนเดียว) · "helpreset" ล้างตัวนับช่วยวันนี้
		if action == "mat" then
			OrchardItems.GiveMat(player, tostring(a), math.max(1, math.floor(tonumber(b) or 1)), lang(player))
			saveBag(player)
			return "mat given"
		end
		if action == "fakedead" then
			if not fakeOwner then return "ไม่มีเจ้าของปลอม (สั่ง fakeowner ก่อน)" end
			local tr = fakeState.data.trees[tostring(tonumber(a) or 1)]
			if not tr then return "ไม่มีต้นที่หลุมนี้" end
			tr.dead, tr.revived, tr.harvests = true, nil, Config.Trees[tr.kind].Harvests
			render(fakeOwner)
			return "fake tree dead"
		end
		-- "run"(คำสั่ง, หลุม) = ทำเหมือนกดปุ่มที่หลุม (harvest / cut / fertilize) · "ask"(หลุม) ขอความช่วยเหลือ · "helpfake"(หลุม) รดน้ำช่วยต้นเจ้าของปลอม
		if action == "run" then
			local res = run(player, tostring(a), type(b) == "table" and b or (tonumber(b) or 1)) -- plant = { ล็อก, หลุม, ชนิด }
			return type(res) == "table" and (tostring(res.ok) .. " " .. tostring(res.message)) or tostring(res)
		end
		if action == "machine" then -- เครื่องทำปุ๋ย "machine"(จำนวน) เหมือนกดทำปุ๋ยในหน้าต่าง (ต้องยืนใกล้) รอเครื่องทำเสร็จ
			local r = useFertilizerMachine(player, zone.Decor.FertilizerMachine, tonumber(a) or 1)
			if r.ok then task.wait(Config.FertilizerMachine.MaxSeconds or 10) end
			return "machine: " .. tostring(r.ok) .. " " .. tostring(r.message)
		end
		if action == "ask" then
			if not lotOf[player] then return "ยังไม่มีล็อก" end
			askHelp(player, lotOf[player], tonumber(a) or 1)
			return "asked"
		end
		if action == "helpfake" then
			local lot = fakeOwner and lotOf[fakeOwner]
			if not lot then return "ไม่มีเจ้าของปลอม" end
			local holeNo = tonumber(a) or 1
			local prompt = lot["Hole" .. holeNo].HelpPrompt
			helpHold[player] = { prompt = prompt, t = os.clock() - Dead.HelpSeconds }
			helpTree(player, lot, holeNo, prompt)
			local tr = fakeState.data.trees[tostring(holeNo)]
			return string.format("fake tree dead=%s revived=%s harvests=%s helpCoins=%s", tostring(tr.dead), tostring(tr.revived), tostring(tr.harvests), tostring(player:GetAttribute("HelpCoins")))
		end
		if action == "helpcoins" then -- "helpcoins"(n) ตั้งเหรียญช่วยเหลือ (ทดสอบตู้แลกน้ำใจ คีย์ปลอมเท่านั้น)
			if not workspace:GetAttribute("DevOrchardKeyOverride") then return "ตั้ง DevOrchardKeyOverride ก่อน" end
			local st = OrchardData.Get(player)
			if not (st and st.loaded) then return "ยังโหลดไม่เสร็จ" end
			st.data.help.coins = math.max(0, math.floor(tonumber(a) or 0))
			OrchardData.SaveLater(player)
			setHelpCoinsAttr(player)
			return "help coins = " .. st.data.help.coins
		end
		if action == "helpreset" then
			local st = OrchardData.Get(player)
			if not (st and st.loaded) then return "ยังโหลดไม่เสร็จ" end
			st.data.help.day = nil
			return "help day reset, coins=" .. st.data.help.coins
		end
		if not workspace:GetAttribute("DevOrchardKeyOverride") then
			return "ตั้ง workspace DevOrchardKeyOverride (คีย์ปลอม) ก่อน"
		end
		local st = OrchardData.Get(player)
		if not (st and st.loaded) then return "ยังโหลดไม่เสร็จ" end
		local d = st.data
		if action == "plant" then
			if not Config.Trees[a] then return "ไม่รู้จักต้น " .. tostring(a) end
			local slot = tonumber(b) or OrchardData.FreeSlot(d)
			if not slot or slot < 1 or slot > d.slots then return "ไม่มีช่องว่าง" end
			d.trees[tostring(slot)] = OrchardData.NewTree(a, OrchardData.Now())
		elseif action == "seed" or action == "fruit" then
			if not Config.Trees[a] then return "ไม่รู้จักต้น " .. tostring(a) end
			OrchardItems.Give(player, action == "seed" and OrchardItems.SEED or OrchardItems.FRUIT, a, math.max(1, math.floor(tonumber(b) or 1)), lang(player))
			return action .. " given"
		elseif action == "clear" then
			d.trees = {}
		elseif action == "dead" then -- "dead"(หลุม, "revived"?) ต้นของเราแห้ง (2026-11-02)
			local tr = d.trees[tostring(tonumber(a) or 1)]
			if not tr then return "ไม่มีต้นที่หลุมนี้" end
			tr.dead, tr.revived, tr.harvests = true, b == "revived" or nil, Config.Trees[tr.kind].Harvests
		elseif action == "ripe" then -- "ripe"(หลุม, เก็บไปแล้วกี่รอบ) ต้นสุกทันที
			local tr = d.trees[tostring(tonumber(a) or 1)]
			if not tr then return "ไม่มีต้นที่หลุมนี้" end
			local def = Config.Trees[tr.kind]
			local now = OrchardData.Now()
			tr.dead = nil
			tr.plantedAt = now - def.GrowSeconds - def.FruitSeconds - 1
			tr.cycleStart = tr.plantedAt + def.GrowSeconds
			tr.harvests = tonumber(b) or tr.harvests or 0
			tr.fruits = math.max(tr.fruits, 1)
		elseif action ~= "info" then
			return "ไม่รู้จักคำสั่ง " .. tostring(action)
		end
		if action ~= "info" then
			OrchardData.SaveLater(player)
			if needsLot(player) then
				ensureLot(player)
				render(player)
			else
				releaseLot(player)
			end
		end
		local now = OrchardData.Now()
		local lines = { string.format("lot=%s", lotOf[player] and lotOf[player].Name or "-") }
		for i = 1, Config.MAX_TREES do
			local tr = d.trees[tostring(i)]
			if tr then
				local stage, nextAt = Config.StageAt(tr, now)
				table.insert(lines, string.format("%d: %s %s fruits=%d next=%s", i, tr.kind, stage, tr.fruits, nextAt and (nextAt - now) .. "s" or "-"))
			end
		end
		return table.concat(lines, " | ")
	end
end

-- ============ จำลองต้นแห้งให้ช่วย (Studio, 2026-11-02 ผู้ใช้สั่ง) ============
-- workspace Attribute DevOrchardFakeDead = จำนวนต้น (เช่น 2): กด Play แล้วเจ้าของปลอม "ชาวสวนทดสอบ" ได้ล็อกว่างล็อกแรก ต้นมะม่วงแห้งทุกต้น (มีออร่าเหลือง)
--   เดินไปกดค้าง F "รดน้ำช่วย" ได้เหมือนของจริง (บัว + สายน้ำ + เหรียญช่วยเหลือเข้าคีย์ปลอม) · ต้นที่ฟื้นแล้วกลับแห้งเองใน 20 วิ ทดสอบซ้ำได้
--   เจ้าของปลอมไม่เซฟอะไร · เลิกจำลอง = ลบ Attribute นี้
-- 2026-11-06 ผู้ใช้สั่ง: มี 2 ล็อก (FAKE_DEAD_LOTS) และทำงานใน Team Test ด้วย (เซิร์ฟ Team Test ไม่นับเป็น Studio แต่เซิร์ฟจริงตอน DEV_ONLY สวนปิด โค้ดมาไม่ถึงตรงนี้) ใช้ fakeExtras แทน OrchardDev (มีเฉพาะ Studio)
local TEST_SERVER = RunService:IsStudio() or Config.DEV_ONLY == true
local FAKE_DEAD_LOTS = 2
if TEST_SERVER and tonumber(workspace:GetAttribute("DevOrchardFakeDead")) then
	task.spawn(function()
		local t0 = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - t0 < 60 do task.wait(1) end
		task.wait(4) -- ให้ผู้เล่นจริงได้ล็อกของตัวเองก่อน
		local n = math.clamp(math.floor(tonumber(workspace:GetAttribute("DevOrchardFakeDead")) or 2), 1, Config.MAX_TREES)
		local def = Config.Trees.Mango
		local function deadTree()
			local planted = OrchardData.Now() - def.GrowSeconds - def.FruitSeconds - 1
			return { kind = "Mango", plantedAt = planted, cycleStart = planted + def.GrowSeconds, fruits = 1, stolen = 0, harvests = def.Harvests, dead = true }
		end
		for lotIndex = 1, FAKE_DEAD_LOTS do
			local lot
			for _, l in ipairs(lots) do if not ownerOf[l] then lot = l break end end
			if not lot then print("[Orchard] จำลองต้นแห้ง: สวนเต็ม") break end
			local trees = {}
			for i = 1, n do trees[tostring(i)] = deadTree() end
			local fake = { Name = "FakeHelpFarmer" .. lotIndex, DisplayName = "ชาวสวนทดสอบ " .. lotIndex, UserId = -1001 - lotIndex, Parent = Players }
			fakeExtras[fake] = { loaded = true, data = { v = 1, slots = Config.MAX_TREES, trees = trees, stats = { harvested = 0, sold = 0, coins = 0, stolenFrom = 0, stole = 0 } } }
			ownerOf[lot], lotOf[fake] = fake, lot
			lot:SetAttribute("OwnerId", fake.UserId)
			setSign(lot, fake)
			render(fake)
			print(string.format("[Orchard] จำลองต้นแห้ง: เจ้าของปลอมที่ %s ต้นแห้ง %d ต้น", lot.Name, n))
			task.spawn(function() -- รดน้ำฟื้นแล้วกลับแห้งใน 20 วิ รดซ้ำได้
				local revivedAt = {}
				while fakeExtras[fake] do
					task.wait(2)
					local changed = false
					local list = fakeExtras[fake].data.trees
					for key in pairs(trees) do
						local tr = list[key]
						if not (tr and tr.dead and not tr.revived) then
							revivedAt[key] = revivedAt[key] or os.clock()
							if os.clock() - revivedAt[key] >= 20 then
								list[key] = deadTree()
								revivedAt[key] = nil
								changed = true
							end
						end
					end
					if changed then render(fake) end
				end
			end)
		end
	end)
end

-- ============ ล็อกมะม่วงสุกพร้อมเก็บ (Studio, 2026-11-03 ผู้ใช้สั่ง แทน "ต้นแห้งเต็มสวน") ============
-- workspace Attribute DevOrchardFakeRipe = true: กด Play แล้วล็อกว่าง 1 ล็อกได้เจ้าของปลอม "ชาวสวนผลสุก" มะม่วงสุกพร้อมเก็บครบทุกหลุม (ไม่มียาม)
--   ใช้ทดสอบตะกร้อขโมย · ต้นที่ถูกขโมย/เก็บแล้ว กลับมาสุกเต็มเองใน 20 วิ · ไม่เซฟอะไร หายเมื่อหยุด Play · เลิก = ลบ Attribute นี้
--   ใช้ร่วมกับ DevOrchardFakeDead (ล็อกต้นแห้งให้รดน้ำช่วย) ได้ ตัวนั้นได้ล็อกก่อน
if TEST_SERVER and workspace:GetAttribute("DevOrchardFakeRipe") == true then
	task.spawn(function()
		local t0 = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - t0 < 60 do task.wait(1) end
		task.wait(8) -- ผู้เล่นจริงได้ล็อกของตัวเอง + เจ้าของปลอม DevOrchardFakeDead ได้ก่อน
		local def = Config.Trees.Mango
		local function ripeTree()
			local planted = OrchardData.Now() - def.GrowSeconds - def.FruitSeconds - 1
			return { kind = "Mango", plantedAt = planted, cycleStart = planted + def.GrowSeconds, fruits = 2, stolen = 0, harvests = def.Harvests }
		end
		local lot
		for _, l in ipairs(lots) do if not ownerOf[l] then lot = l break end end
		if not lot then return print("[Orchard] ล็อกผลสุก: สวนเต็ม") end
		local trees = {}
		for i = 1, Config.MAX_TREES do trees[tostring(i)] = ripeTree() end
		local fake = { Name = "FakeRipeFarmer", DisplayName = "ชาวสวนผลสุก", UserId = -1001, Parent = Players }
		fakeExtras[fake] = { loaded = true, data = { v = 1, slots = Config.MAX_TREES, trees = trees, stats = { harvested = 0, sold = 0, coins = 0, stolenFrom = 0, stole = 0 } } }
		ownerOf[lot], lotOf[fake] = fake, lot
		lot:SetAttribute("OwnerId", fake.UserId)
		setSign(lot, fake)
		render(fake)
		print(string.format("[Orchard] ล็อกผลสุก: เจ้าของปลอมที่ %s มะม่วงสุก %d ต้น", lot.Name, Config.MAX_TREES))
		local touchedAt = {}
		while fakeExtras[fake] do
			task.wait(2)
			local st, changed = fakeExtras[fake], false
			for key, tr in pairs(st.data.trees) do
				local fresh = tr.stolen == 0 and tr.fruits == 2 and not tr.dead and tr.cycleStart <= OrchardData.Now() - def.FruitSeconds
				if fresh then
					touchedAt[key] = nil
				else
					touchedAt[key] = touchedAt[key] or os.clock()
					if os.clock() - touchedAt[key] >= 20 then
						st.data.trees[key] = ripeTree()
						touchedAt[key] = nil
						changed = true
					end
				end
			end
			for i = 1, Config.MAX_TREES do -- ต้นที่ถูกตัด/ลบ ปลูกคืน
				if not st.data.trees[tostring(i)] then st.data.trees[tostring(i)] = ripeTree() changed = true end
			end
			if changed then render(fake) end
		end
	end)
end

-- ============ สวนเต็มทุกแปลง (เซิร์ฟทดสอบ, 2026-11-07 ผู้ใช้สั่ง) ============
-- workspace Attribute DevOrchardFakeFull = จำนวนล็อกที่เว้นว่างไว้ (2 = คนทดสอบยังปลูก/ย้ายล็อกได้, 0 = เต็มทุกล็อก) · ลบ Attribute = ปิด
-- ล็อกว่างทุกล็อกได้เจ้าของปลอม + มะม่วงสุก 6 ต้น ถูกขโมย/ตัดแล้วกลับมาสุกใน 20 วิ · เจ้าของปลอมไม่เซฟอะไร
if TEST_SERVER and tonumber(workspace:GetAttribute("DevOrchardFakeFull")) then
	task.spawn(function()
		local t0 = os.clock()
		while #Players:GetPlayers() == 0 and os.clock() - t0 < 60 do task.wait(1) end
		task.wait(12) -- ผู้เล่นจริง + ล็อกจำลองอื่นได้ก่อน
		local def = Config.Trees.Mango
		local function ripeTree()
			local planted = OrchardData.Now() - def.GrowSeconds - def.FruitSeconds - 1
			return { kind = "Mango", plantedAt = planted, cycleStart = planted + def.GrowSeconds, fruits = 2, stolen = 0, harvests = 0 }
		end
		-- 2026-11-07 ผู้ใช้สั่ง: เปิด DevOrchardFakeCrowd ด้วย = NPC ชาวสวนดูแลเอง (ปลูก/เก็บ/ตัด/รดน้ำ/ขโมย) เริ่มแบบคละสภาพ ไม่รีเซ็ตเป็นสุกเอง
		local crowdSim = (tonumber(workspace:GetAttribute("DevOrchardFakeCrowd")) or 0) > 0
		local function mixedTree()
			local r = math.random()
			if r < 0.15 then return nil end -- หลุมว่าง รอ NPC ปลูก
			if r < 0.5 then return ripeTree() end
			local now = OrchardData.Now()
			if r < 0.75 then -- กำลังโต/รอผล
				local planted = now - math.random(0, def.GrowSeconds + def.FruitSeconds - 5)
				return { kind = "Mango", plantedAt = planted, cycleStart = planted + def.GrowSeconds, fruits = 2, stolen = 0, harvests = 0 }
			end
			local t = ripeTree()
			t.dead, t.harvests = true, def.Harvests
			if r >= 0.9 then t.revived = true end -- แห้งรอบ 2 = ต้องตัด
			return t
		end
		local free = {}
		for _, l in ipairs(lots) do if not ownerOf[l] then table.insert(free, l) end end
		local keep = math.max(0, math.floor(tonumber(workspace:GetAttribute("DevOrchardFakeFull")) or 2))
		local fakes = {}
		-- 2026-11-07: จำนวนล็อกปลอม = ล็อกทั้งหมด - keep (30 - 2 = 28) ไม่ขึ้นกับว่าคนทดสอบจองไปกี่ล็อก (เดิม = ล็อกว่าง - keep)
		for i = 1, math.min(#free, #lots - keep) do
			local lot = free[i]
			local trees = {}
			for h = 1, Config.MAX_TREES do trees[tostring(h)] = crowdSim and mixedTree() or ripeTree() end
			local fake = { Name = "FakeFullFarmer" .. i, DisplayName = "ชาวสวนจำลอง " .. i, UserId = -1100 - i, Parent = Players }
			fakeExtras[fake] = { loaded = true, data = { v = 1, slots = Config.MAX_TREES, trees = trees, stats = { harvested = 0, sold = 0, coins = 0, stolenFrom = 0, stole = 0 } } }
			ownerOf[lot], lotOf[fake] = fake, lot
			lot:SetAttribute("OwnerId", fake.UserId)
			setSign(lot, fake)
			render(fake)
			table.insert(fakes, fake)
			if i % 3 == 0 then task.wait() end
		end
		print(string.format("[Orchard] สวนเต็ม: เจ้าของปลอม %d ล็อก เว้นว่าง %d ล็อก%s", #fakes, #free - #fakes, crowdSim and " (NPC ดูแลเอง)" or ""))
		if crowdSim then return end -- NPC ใน OrchardFakeCrowd ปลูก/เก็บ/ตัดเอง ไม่ต้องรีเซ็ต
		local touchedAt = {}
		while true do
			task.wait(2)
			for _, fake in ipairs(fakes) do
				local st, changed = fakeExtras[fake], false
				for h = 1, Config.MAX_TREES do
					local key = tostring(h)
					local tr = st.data.trees[key]
					local fresh = tr and tr.stolen == 0 and tr.fruits == 2 and not tr.dead and Config.StageAt(tr, OrchardData.Now()) == "Ripe"
					local id = fake.UserId .. "#" .. key
					if fresh then
						touchedAt[id] = nil
					else
						touchedAt[id] = touchedAt[id] or os.clock()
						if os.clock() - touchedAt[id] >= 20 then
							st.data.trees[key] = ripeTree()
							touchedAt[id] = nil
							changed = true
						end
					end
				end
				if changed then render(fake) end
			end
		end
	end)
end

-- ============ ให้ผู้เล่นจำลองขโมย/รดน้ำต้นของเจ้าของปลอม (เซิร์ฟทดสอบ, 2026-11-07 ผู้ใช้สั่ง เช็กความหน่วง) ============
-- OrchardFakeCrowd เรียก ServerStorage.OrchardCrowdAction · แตะเฉพาะต้นของเจ้าของปลอม ไม่แตะต้นผู้เล่นจริง ไม่เซฟอะไร
if TEST_SERVER and tonumber(workspace:GetAttribute("DevOrchardFakeCrowd")) then
	local bf = Instance.new("BindableFunction")
	bf.Name = "OrchardCrowdAction"
	bf.Parent = ServerStorage
	local shaking = {} -- ["Lot01#2"] = true
	bf.OnInvoke = function(kind, lot, holeNo, rig)
		local owner = ownerOf[lot]
		if not (owner and isFake(owner)) then return false end
		local st = stateOf(owner)
		if not st then return false end
		-- สภาพทุกหลุมของล็อก (ให้ NPC เลือกงาน): empty / growing / ripe / dead (รดน้ำฟื้นได้) / deadfinal (ต้องตัด)
		if kind == "status" then
			local out, now = {}, OrchardData.Now()
			for h = 1, Config.MAX_TREES do
				local t = st.data.trees[tostring(h)]
				if not t then out[h] = "empty"
				elseif t.dead then out[h] = t.revived and "deadfinal" or "dead"
				elseif Config.StageAt(t, now) == "Ripe" then out[h] = "ripe"
				else out[h] = "growing" end
			end
			return out
		end
		local hole = lot:FindFirstChild("Hole" .. holeNo)
		if not hole then return false end
		local actor = { Character = rig } -- plantFx/fallTree อ่าน .Character
		if kind == "plant" then
			if st.data.trees[tostring(holeNo)] then return false end
			if rig then pcall(plantFx, actor, hole, "Mango") end
			st.data.trees[tostring(holeNo)] = OrchardData.NewTree("Mango", OrchardData.Now())
			render(owner)
			return true
		end
		local tr = st.data.trees[tostring(holeNo)]
		local model = lot:FindFirstChild("Trees") and lot.Trees:FindFirstChild("Tree" .. holeNo)
		if not tr then return false end
		local key = lot.Name .. "#" .. holeNo
		if kind == "chophit" then -- ขวานกระทบ 1 ครั้ง: เศษไม้ + เสียง + ต้นสั่น
			local groundY = hole.Position.Y + hole.Size.Y / 2
			chipBurst(Vector3.new(hole.Position.X, groundY + 1.2, hole.Position.Z))
			playSound(Config.KitSounds.Chop, hole, 0.7)
			if model then shakeTree(model, Vector3.new(hole.Position.X, groundY, hole.Position.Z)) end
			return true
		elseif kind == "cut" then
			if not tr.dead then return false end
			st.data.trees[tostring(holeNo)] = nil
			if model and rig then pcall(fallTree, model, hole, actor) end
			render(owner)
			return true
		elseif kind == "harvest" then
			if tr.dead or shaking[key] or Config.StageAt(tr, OrchardData.Now()) ~= "Ripe" then return false end
			OrchardData.StartNewCycle(tr, OrchardData.Now())
			tr.harvests = (tr.harvests or 0) + 1
			if Config.HarvestsLeft(tr) == 0 then tr.dead = true end
			render(owner)
			local fresh = lot.Trees:FindFirstChild("Tree" .. holeNo)
			if fresh then swayTree(fresh, hole) end
			return true
		end
		if kind == "shake" then
			if model and not shaking[key] then
				shaking[key] = true
				shakeWhileStealing(model, hole, function() return shaking[key] == true end)
			end
		elseif kind == "stop" then
			shaking[key] = nil
		elseif kind == "steal" then
			shaking[key] = nil
			if canBeStolen(tr, OrchardData.Now()) then
				tr.fruits -= 1
				tr.stolen = (tr.stolen or 0) + 1
				render(owner)
				local fresh = lot.Trees:FindFirstChild("Tree" .. holeNo)
				if fresh then swayTree(fresh, hole) end
				return true
			end
		elseif kind == "water" then
			if tr.dead and not tr.revived then
				OrchardData.StartNewCycle(tr, OrchardData.Now())
				tr.dead, tr.revived, tr.harvests, tr.fed = nil, true, math.max(0, (Config.Trees[tr.kind].Harvests or 0) - Dead.RevivedHarvests), nil
				render(owner)
				return true
			end
		end
		return false
	end
	-- เจ้าของปลอมกดขอความช่วยเหลือเองทุก FAKE_ASK_SECONDS วิ (2026-11-07 ผู้ใช้สั่ง) ผู้เล่นจริงเห็นแจ้งเตือนมุมขวาบน
	local FAKE_ASK_SECONDS = 30
	task.spawn(function()
		while true do
			task.wait(FAKE_ASK_SECONDS)
			local options = {}
			for _, lot in ipairs(lots) do
				local owner = ownerOf[lot]
				local st = owner and isFake(owner) and stateOf(owner)
				if st then
					for key, tr in pairs(st.data.trees) do
						if tr.dead and not tr.revived then table.insert(options, { owner = owner, lot = lot, hole = tonumber(key) }) end
					end
				end
			end
			if #options > 0 then
				local pick = options[math.random(1, #options)]
				helpAskAt[pick.owner] = nil
				local ok, err = pcall(askHelp, pick.owner, pick.lot, pick.hole)
				if not ok then warn("OrchardService: fake ask error: " .. tostring(err)) end
			end
		end
	end)
end

-- ============ เข้า/ออก ============
local function onJoin(player)
	-- ขวาน + บัวรดน้ำฟรี (2026-11-02) ใส่กระเป๋าหลังกระเป๋าโหลดเสร็จ + ทุกครั้งเกิดใหม่ (Backpack ถูกล้าง) · ไม่เซฟลงกระเป๋า
	task.spawn(function()
		local waited = 0
		while player.Parent and not player:GetAttribute("InventoryLoaded") and waited < 40 do waited += task.wait(0.5) end
		task.wait(1)
		if player.Parent then OrchardItems.EnsureKit(player, lang(player)) end
	end)
	player.CharacterAdded:Connect(function()
		task.delay(3, function() if player.Parent then OrchardItems.EnsureKit(player, lang(player)) end end)
	end)
	-- ประดับหลังใส่ให้ใหม่ทุกครั้งเกิด (รอชุดตัวละครโหลดก่อน ไม่งั้นขนาดลำตัวยังเปลี่ยน)
	player.CharacterAppearanceLoaded:Connect(function()
		task.wait(0.3)
		if player.Parent then pcall(attachBack, player) end
	end)
	if OrchardData.Load(player) then
		joinOrder[player] = os.clock()
		setHelpCoinsAttr(player)
		setHelpTitleAttr(player) -- ฉายาจากตู้แลกน้ำใจ
		pcall(attachBack, player) -- ประดับหลัง (เกิดใหม่ = CharacterAppearanceLoaded ด้านล่าง)
		if needsLot(player) then ensureLot(player) end
		sync(player)
	end
end

Players.PlayerAdded:Connect(function(player) task.spawn(onJoin, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onJoin, player) end

Players.PlayerRemoving:Connect(function(player)
	releaseLot(player)
	joinOrder[player] = nil
	busy[player], lastRequest[player], holdStart[player] = nil, nil, nil
	endAttempt(player, "left")
	stunnedUntil[player] = nil
	pickToken[player] = nil
	for thief, at in pairs(attempts) do
		if at.owner == player then endAttempt(thief, "owner left") end
	end
	OrchardData.Release(player)
end)

game:BindToClose(function()
	local pending = 0
	for player, st in pairs(OrchardData.AllStates()) do
		if st.loaded and st.dirty then
			pending += 1
			task.spawn(function()
				OrchardData.Save(player)
				pending -= 1
			end)
		end
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 25 do task.wait(0.2) end
end)

-- ============ เปลี่ยนขั้นต้นตามเวลา + เซฟอัตโนมัติ ============
task.spawn(function()
	local lastAutosave = os.clock()
	while true do
		task.wait(REFRESH_EVERY)
		for player in pairs(lotOf) do
			if player.Parent then render(player) end
		end
		if os.clock() - lastAutosave >= AUTOSAVE_EVERY then
			lastAutosave = os.clock()
			for player, st in pairs(OrchardData.AllStates()) do
				if st.loaded and st.dirty and player.Parent then OrchardData.SaveLater(player) end
			end
		end
	end
end)
