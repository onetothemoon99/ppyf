-- BACKUP 2026-11-19: StarterPlayer.StarterPlayerScripts.PetFireflyRing (LocalScript) before the NineLivesCat -10% brightness (AuraDim attribute)
-- Restore: paste everything below the "---- SOURCE ----" line into PetFireflyRing.Source in Studio
---- SOURCE ----
-- PetFireflyRing: วงแหวนหิ่งห้อยออร่าทองส้ม บินวนรอบสัตว์เลี้ยงที่ตั้ง Attribute "FireflyRing" (เช่น จิ้งจอกเก้าหาง)
-- หน้าตาแบบเดียวกับหิ่งห้อยรอบหุ่นข้าวโพด (QualityBoosterVisual) แต่ใช้ออร่าสีเดียวกับหางจิ้งจอก และบินวนตามตัวสัตว์ไปด้วย
-- จำนวน 9 ตัว เท่าจำนวนหางของจิ้งจอกเก้าหาง
-- ตัวไหนตั้ง Attribute FireflyColorA/B ไว้ ใช้สีนั้นแทน (เช่น แมวเก้าชีวิต = ดวงไฟวิญญาณสีม่วง)
-- ตัวที่มี Attribute NineLives: จำนวนดวงที่เห็น = ชีวิตที่เหลือ (อ่าน PetLives_<petId> บนตัวเจ้าของ) เสียชีวิตแล้วดวงแตกหายไป 1 ดวง
-- วาดฝั่งผู้เล่น (ทุกคนเห็นของทุกคน) ขยับลื่นทุกเฟรม และไม่ต้องส่งข้อมูลผ่านเน็ตเลย
-- 2026-10-21 โมเดลที่ติด tag "FireflyRing" (ไก่กลายพันธุ์ จาก ChickenLooks) ได้วงแหวนด้วย อยู่ลึกแค่ไหนก็ได้ (ลาน / แท่นโชว์ / อุ้มอยู่ในมือ) ข้ามตัวใน ViewportFrame · ไม่อยู่ใน workspace (ไก่ในกระเป๋า) = ซ่อน

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ตำแหน่งสัตว์ที่เครื่องนี้วาดจริง (PetAnimator เกลี่ยให้ลื่นแล้ว) เซิร์ฟเวอร์ส่งตำแหน่งแค่ ~10 ครั้ง/วิ อ่าน GetPivot ตรงๆ วงแหวนจะกระตุก
local PetRenderState = require(game:GetService("ReplicatedStorage"):WaitForChild("PetRenderState"))

local FIREFLY_COUNT = 9
local RING_RADIUS = 2.2       -- รัศมีวงแหวนรอบตัว (studs)
local RADIUS_JITTER = 0.35    -- แต่ละตัวบินเข้า-ออกไม่เท่ากัน ดูเป็นธรรมชาติ
local HEIGHT = 0.9            -- ความสูงเฉลี่ยจากจุดกลางตัว
local HEIGHT_JITTER = 0.45
local ORBIT_SPEED = 0.6       -- เรเดียน/วินาที (วนครบรอบราว 10 วิ)
-- สีเดียวกับออร่าที่หาง (NineTailFox > tail > TailAura / TailAuraHighlight) แต่ละตัวค่อยๆ ไล่ทอง <-> ส้ม คนละจังหวะ
local GOLD = Color3.fromRGB(255, 200, 70)
local ORANGE = Color3.fromRGB(255, 130, 40)
local AURA_COLOR = ColorSequence.new({ ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(1, ORANGE) })
local SHIMMER_SPEED = 0.9
local MAX_DISTANCE = 120      -- ไกลกล้องเกินนี้ซ่อนไว้ ประหยัดเครื่อง

local rings = {} -- [petModel] = { folder, bugs = { {part, light, phase, radius, height, bobSpeed, blinkSpeed} } }

-- lightScale = ตัวคูณรัศมีไฟของหิ่งห้อย (จิ้งจอกเก้าหาง 0.5 ผู้เล่นขอลดรัศมีความสว่าง 2026-10-09)
local function makeBug(folder, index, colorA, colorB, count, lightScale)
	local bug = Instance.new("Part")
	bug.Name = "Firefly"
	bug.Shape = Enum.PartType.Ball
	bug.Material = Enum.Material.Neon
	bug.Size = Vector3.new(0.2, 0.2, 0.2)
	bug.CanCollide = false
	bug.CanQuery = false
	bug.CanTouch = false
	bug.CastShadow = false
	bug.Anchored = true
	bug.Parent = folder

	-- ไฟเฉพาะตัวเว้นตัว พอให้พื้นสว่างอุ่นๆ ไม่หนักเครื่อง
	local light
	if index % 2 == 0 then
		light = Instance.new("PointLight")
		light.Range = 4 * (lightScale or 1)
		light.Brightness = 1.2
		light.Shadows = false
		light.Parent = bug
	end

	-- ออร่าแบบเดียวกับหาง: ละอองแสงทองไล่ส้ม ลอยขึ้นแล้วจางหาย (ค่าเดียวกับ TailAura ในโมเดล)
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, colorA), ColorSequenceKeypoint.new(1, colorB) })
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.4, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.3, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkle.Lifetime = NumberRange.new(0.7, 1.2)
	sparkle.Rate = 6
	sparkle.Speed = NumberRange.new(0.15, 0.4)
	sparkle.Acceleration = Vector3.new(0, 0.6, 0)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.LightEmission = 1
	sparkle.LightInfluence = 0
	sparkle.Parent = bug

	return {
		part = bug,
		light = light,
		sparkle = sparkle,
		phase = (index / (count or FIREFLY_COUNT)) * math.pi * 2 + math.rad(math.random(-12, 12)),
		radius = RING_RADIUS + (math.random() * 2 - 1) * RADIUS_JITTER,
		height = HEIGHT + (math.random() * 2 - 1) * HEIGHT_JITTER,
		bobSpeed = 1.2 + math.random() * 1.2,
		blinkSpeed = 1.5 + math.random() * 2,
		shimmerPhase = math.random() * math.pi * 2,
	}
end

local function addRing(model)
	if rings[model] then return end
	local colorA = model:GetAttribute("FireflyColorA") or GOLD
	local colorB = model:GetAttribute("FireflyColorB") or ORANGE
	local folder = Instance.new("Folder")
	folder.Name = "FireflyRing_" .. model.Name
	folder.Parent = workspace
	local bugs = {}
	local scale = model:GetAttribute("FireflyScale") or 1 -- ตัวโชว์บนตู้สุ่มขยายใหญ่ วงแหวนกว้างตาม
	-- ตัวที่ตั้ง Attribute FireflyCount มีจำนวนดวงเฉพาะตัว (เช่น เสือพยัคฆ์ขาว 5 ดวง) ไม่ตั้ง = 9
	local count = math.clamp(math.floor(model:GetAttribute("FireflyCount") or FIREFLY_COUNT), 1, 20)
	for i = 1, count do
		local bug = makeBug(folder, i, colorA, colorB, count, model:GetAttribute("PetId") == "NineTailFox" and 0.5 or 1)
		bug.radius *= scale
		bug.height *= scale
		bug.part.Size *= scale
		table.insert(bugs, bug)
	end
	rings[model] = {
		folder = folder, bugs = bugs, colorA = colorA, colorB = colorB,
		maxLives = model:GetAttribute("NineLives"),
		owner = Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0),
		petId = model:GetAttribute("PetId"),
		lastAlive = nil,
	}
end

-- ดวงที่ยังแสดง (ไม่มีระบบชีวิต = ครบทุกดวง)
local function aliveCount(ring)
	if not ring.maxLives then return #ring.bugs end
	local lives = ring.owner and ring.petId and ring.owner:GetAttribute("PetLives_" .. ring.petId)
	return math.clamp(lives or ring.maxLives, 0, #ring.bugs)
end

local function removeRing(model)
	local ring = rings[model]
	if not ring then return end
	ring.folder:Destroy()
	rings[model] = nil
end

local function check(obj)
	if obj:IsA("Model") and obj.Parent == workspace and obj:GetAttribute("FireflyRing") then
		addRing(obj)
	end
end

local CollectionService = game:GetService("CollectionService")
local function checkTagged(obj)
	if obj:IsA("Model") and not obj:FindFirstAncestorWhichIsA("ViewportFrame") then addRing(obj) end
end
for _, obj in ipairs(CollectionService:GetTagged("FireflyRing")) do checkTagged(obj) end
CollectionService:GetInstanceAddedSignal("FireflyRing"):Connect(function(obj)
	task.defer(checkTagged, obj) -- รอ Attribute สี/จำนวนที่ตั้งตามมา
end)
CollectionService:GetInstanceRemovedSignal("FireflyRing"):Connect(removeRing)

for _, obj in ipairs(workspace:GetChildren()) do check(obj) end
workspace.ChildAdded:Connect(function(obj)
	task.wait(0.3) -- รอ Attribute มาถึง
	check(obj)
end)
workspace.ChildRemoved:Connect(removeRing)

local clock = 0
RunService.RenderStepped:Connect(function(dt)
	clock += dt
	local camPos = workspace.CurrentCamera.CFrame.Position
	for model, ring in pairs(rings) do
		if not model.Parent then
			removeRing(model)
		else
			local center = (PetRenderState[model] or model:GetPivot()).Position
			-- โหมดถ่ายภาพกดซ่อนสัตว์ (Attribute PhotoHidePets จาก PhotoModeGui) = ซ่อนหิ่งห้อยด้วย
			local inRange = (center - camPos).Magnitude < MAX_DISTANCE and not Players.LocalPlayer:GetAttribute("PhotoHidePets")
				and (model.Parent == workspace or model:IsDescendantOf(workspace)) -- ไก่ที่อุ้มแต่เก็บเข้ากระเป๋า = ซ่อน
			local alive = aliveCount(ring)
			-- เสียชีวิต: ดวงที่ดับไปแตกเป็นประกายก่อนหาย / ได้ชีวิตคืน: ดวงที่กลับมาเปล่งประกายเบาๆ
			if ring.lastAlive and alive ~= ring.lastAlive and inRange then
				local lo, hi = math.min(alive, ring.lastAlive) + 1, math.max(alive, ring.lastAlive)
				for i = lo, hi do
					local b = ring.bugs[i]
					if b then b.sparkle:Emit(alive < ring.lastAlive and 30 or 10) end
				end
			end
			ring.lastAlive = alive
			for index, bug in ipairs(ring.bugs) do
				local visible = inRange and index <= alive
				if visible then
					local angle = bug.phase + clock * ORBIT_SPEED
					local y = bug.height + math.sin(clock * bug.bobSpeed + bug.phase) * 0.3
					bug.part.CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * bug.radius, y, math.sin(angle) * bug.radius))
					local color = ring.colorA:Lerp(ring.colorB, 0.5 + 0.5 * math.sin(clock * SHIMMER_SPEED + bug.shimmerPhase))
					bug.part.Color = color
					if bug.light then bug.light.Color = color end
					-- กระพริบเหมือนหิ่งห้อยจริง (หรี่-สว่างสลับ ไม่พร้อมกัน)
					local blink = 0.5 + 0.5 * math.sin(clock * bug.blinkSpeed + bug.phase * 3)
					bug.part.Transparency = 0.15 + 0.6 * (1 - blink)
					if bug.light then bug.light.Brightness = 0.4 + 1.2 * blink end
				else
					bug.part.Transparency = 1
					if inRange then -- ดวงที่ดับยังตามตำแหน่งวงแหวน ประกายตอนแตก/กลับมาจะเกิดตรงที่มันอยู่
						local angle = bug.phase + clock * ORBIT_SPEED
						bug.part.CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * bug.radius, bug.height, math.sin(angle) * bug.radius))
					end
				end
				bug.sparkle.Enabled = visible
				if bug.light then bug.light.Enabled = visible end
			end
		end
	end
end)
