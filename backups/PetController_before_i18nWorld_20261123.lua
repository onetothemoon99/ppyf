-- BACKUP of ServerScriptService.PetSystem.PetController before Thai/English world signs (i18n phase 4, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.PetSystem.PetController.Source in Studio
-- PetController: ตรรกะกลางของสัตว์เลี้ยงทุกตัว (สปอว์น/เดินตาม/แอนิเมชัน/เรียก Ability)
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Abilities = script.Parent:WaitForChild("Abilities")
local PetDefinitions = require(script.Parent:WaitForChild("PetDefinitions"))
local PetHunger = require(script.Parent:WaitForChild("PetHunger"))
local PetRarity = require(game:GetService("ReplicatedStorage"):WaitForChild("PetRarity"))
local PetLevelConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("PetLevelConfig"))

local PetController = {}

local rng = Random.new()

-- กลุ่มชนของสัตว์เลี้ยง: ไม่ชนกับอะไรเลย (ผู้เล่น/สัตว์ตัวอื่น/ฉาก) ผู้เล่นเดินทะลุได้
-- ตั้ง CanCollide = false อย่างเดียวไม่พอ: Humanoid บังคับให้ชิ้นชื่อ Head/Torso ชนเสมอ (ค่าในพร็อพเพอร์ตียังขึ้น false)
-- สัตว์ขยับด้วย PivotTo ทุกเฟรม ไม่ต้องใช้การชนอยู่แล้ว
local PET_COLLISION_GROUP = "Pets"
do
	local PhysicsService = game:GetService("PhysicsService")
	pcall(function()
		if not PhysicsService:IsCollisionGroupRegistered(PET_COLLISION_GROUP) then
			PhysicsService:RegisterCollisionGroup(PET_COLLISION_GROUP)
		end
		for _, group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
			PhysicsService:CollisionGroupSetCollidable(PET_COLLISION_GROUP, group.name, false)
		end
	end)
end

local function loadAbilityModules(abilityNames)
	local loaded = {}
	for _, name in ipairs(abilityNames) do
		local moduleScript = Abilities:FindFirstChild(name)
		if moduleScript then
			local ok, abilityModule = pcall(require, moduleScript)
			if ok then
				table.insert(loaded, abilityModule)
			else
				warn("[PetController] โหลด Ability " .. name .. " ไม่สำเร็จ: " .. tostring(abilityModule))
			end
		else
			warn("[PetController] ไม่พบ Ability module ชื่อ " .. name)
		end
	end
	return loaded
end

-- ทิศที่สัตว์ยืนข้างเจ้าของตามช่อง: 1 = ขวา, 2 = ซ้าย, 3 = ข้างหลัง (ช่องที่ 3 จาก Game Pass "ช่องสัตว์ +1")
-- FREE_SLOT = ตัวที่ไม่กินช่อง (def.FreeSlot เช่น ซุกซน) ยืนเฉียงหลังซ้าย
PetController.FREE_SLOT = 4
function PetController.SlotSide(ownerCF, slot)
	if slot == 2 then return -ownerCF.RightVector end
	if slot == 3 then return -ownerCF.LookVector end
	if slot == PetController.FREE_SLOT then return (-ownerCF.RightVector - ownerCF.LookVector).Unit end
	return ownerCF.RightVector
end

-- แอนิเมชันของสัตว์ (ท่าเดิน หู หาง หางพัด ปีก ท่าก้มทำงาน สีรุ้ง) ย้ายไปทำฝั่งผู้เล่นทั้งหมดแล้ว (2026-10-12)
--   -> StarterPlayerScripts.PetAnimator (โค้ดเดิมฝั่งเซิร์ฟเวอร์: ServerStorage._Backup_20261012.PetController_before_clientanim)
-- เดิมเซิร์ฟเวอร์ตั้ง Motor6D.C0 ทุกข้อต่อ + PivotTo ทุกเฟรม ทุกค่าถูกส่งหาผู้เล่นทุกคนที่อยู่ใกล้
-- วัดได้ ~25 KB/วิ ต่อสัตว์ 1 ตัวที่ยืนเฉยๆ (ไม่มีสัตว์ = 1 KB/วิ) เซิร์ฟเวอร์ 30 คน x 3 ตัว = เกิน 2 MB/วิ ต่อผู้เล่น
-- ของที่เพิ่งสร้าง (สัตว์ที่เพิ่งเรียก หุ่นที่เพิ่งปัก ตัวละครหลังเปลี่ยนอวาตาร์) เลยไปถึงเครื่องผู้เล่นช้า/ไม่ครบ
-- ตอนนี้เซิร์ฟเวอร์ยังคิดตำแหน่งทุกเฟรมเหมือนเดิม (ความสามารถยังแม่น) แต่ส่งตำแหน่งแค่ทุก PIVOT_SEND_INTERVAL วิ เครื่องผู้เล่นเกลี่ยให้ลื่นเอง
local PIVOT_SEND_INTERVAL = 0.1
local PIVOT_SEND_MIN_MOVE = 0.01   -- studs: ขยับน้อยกว่านี้ไม่ส่ง (ยืนนิ่ง = ไม่ส่งอะไรเลย)
local PIVOT_SEND_MIN_TURN = 0.005  -- เรเดียน
local EXTERNAL_MOVE = 0.05         -- สคริปต์อื่นย้ายโมเดลเอง (เช่น PetManager.gatherPets) เกินนี้ = คิดต่อจากตำแหน่งนั้น

-- มังกร: พ่นไฟเป็นพักๆ (ParticleEmitter "FireBreath" ที่ปาก) นานๆ ครั้ง ไม่เปลืองเน็ต จึงยังสั่งจากเซิร์ฟเวอร์
local function setupFireBreath(petModel)
	local breath = petModel:FindFirstChild("FireBreath", true)
	if not breath then return end
	task.spawn(function()
		task.wait(rng:NextNumber(6, 12))
		while petModel.Parent and breath.Parent do
			for _ = 1, 6 do
				if not breath.Parent then return end
				breath:Emit(6)
				task.wait(0.1)
			end
			task.wait(rng:NextNumber(10, 18))
		end
	end)
end

-- แสง/ออร่าตามความหายาก (ค่า Glow ใน ReplicatedStorage.PetRarity) คูณจากค่าในโมเดล โมเดลต้นฉบับไม่เปลี่ยน
-- เดิมทุกตัวแสงเท่ากันหมด (ส่อง 8 studs สว่าง 2 ออร่าขนาด 3-5) กระต่ายธรรมดาเลยเรืองแสงพอๆ กับตัวตำนาน
-- ตอนนี้ธรรมดาแสงน้อยๆ ไล่ขึ้นไปจนลับสว่างกว้างสุด ตำนานขึ้นไปมีขอบเรืองแสงสีประจำระดับด้วย
local function scaleSequence(seq, k)
	local points = {}
	for _, p in ipairs(seq.Keypoints) do
		table.insert(points, NumberSequenceKeypoint.new(p.Time, p.Value * k, p.Envelope * k))
	end
	return NumberSequence.new(points)
end

local function applyRarityGlow(pet, rarityId)
	local tier = PetRarity.Get(rarityId)
	local glow = tier.Glow
	if not glow then return end
	local dim = glow.AuraDim or 1 -- ลดความสว่างออร่า (ไม่รวมไฟที่มังกรพ่น)
	dim *= pet:GetAttribute("AuraDim") or 1 -- 2026-11-19 AuraDim: ค่าเฉพาะตัวจาก PetDefinitions (เช่น แมวเก้าชีวิต 0.9)
	for _, d in ipairs(pet:GetDescendants()) do
		if d:IsA("Light") then
			if d:IsA("PointLight") or d:IsA("SpotLight") then d.Range *= glow.LightRange end
			d.Brightness *= glow.LightBrightness * dim
		elseif d:IsA("ParticleEmitter") then
			d.Rate *= glow.ParticleRate
			d.Size = scaleSequence(d.Size, glow.ParticleSize)
			if d.Name ~= "FireBreath" then d.Brightness *= dim end
		elseif d:IsA("Highlight") and dim ~= 1 then -- ออร่าทองส้มทั้งตัวของจิ้งจอกเก้าหาง: ทึบน้อยลงตาม dim
			d.FillTransparency = 1 - (1 - d.FillTransparency) * dim
			d.OutlineTransparency = 1 - (1 - d.OutlineTransparency) * dim
		end
	end
	-- ขอบเรืองแสงสีประจำระดับ (ตัวที่มี Highlight ของตัวเองอยู่แล้ว เช่น ออร่าทองส้มของจิ้งจอกเก้าหาง ใช้ของเดิม)
	if glow.Outline and not pet:FindFirstChildWhichIsA("Highlight", true) then
		local outline = Instance.new("Highlight")
		outline.Name = "RarityOutline"
		outline.Adornee = pet
		outline.FillTransparency = 1
		outline.OutlineColor = tier.Color
		outline.OutlineTransparency = 1 - 0.7 * dim
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.Parent = pet
	end
end

PetController.ApplyRarityGlow = applyRarityGlow -- ตู้สุ่มใช้กับตัวโชว์บนตู้ด้วย

function PetController.Spawn(player, petId, slot)
	slot = slot or 1
	local def = PetDefinitions[petId]
	if not def then
		warn("[PetController] ไม่พบ PetDefinitions สำหรับ " .. tostring(petId))
		return nil
	end

	local templateFolder = ServerStorage:FindFirstChild(def.TemplateFolder or "PetTemplates")
	local template = templateFolder and templateFolder:FindFirstChild(petId)
	if not template then
		warn("[PetController] ไม่พบโมเดล " .. petId .. " ใน ServerStorage")
		return nil
	end

	local pet = template:Clone()
	pet.Name = player.Name .. "_" .. petId
	-- 2026-10-12 ส่งทั้งตัวให้เครื่องผู้เล่นเป็นก้อนเดียว (Atomic): เกมเปิด StreamingEnabled และโมเดลสัตว์มีโมเดลย่อยซ้อน (head / Face / left ear ...)
	-- แบบ Default ชิ้นส่วนถูกส่งแยกทีละชิ้น เครื่องหน่วยความจำน้อยได้ไม่ครบ (ผู้เล่นแจ้ง: Infinix Hot 40i เสือตาหาย จิ้งจอกไม่มีหู) เทมเพลตใน PetTemplates ตั้งไว้แล้ว บรรทัดนี้กันเทมเพลตใหม่ลืมตั้ง
	pet.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	-- ให้ฝั่งผู้เล่นรู้ว่าตัวไหนเป็นของใคร/ตัวอะไร (ป้ายให้อาหาร + แถบความหิวเหนือหัว)
	pet:SetAttribute("PetId", petId)
	pet:SetAttribute("OwnerUserId", player.UserId)
	pet:SetAttribute("PetDisplayName", def.DisplayName)
	pet:SetAttribute("PetRarity", def.Rarity or "Common") -- แผงสัตว์ที่ใช้อยู่ (ActivePetsHud) ใช้ทำสีขอบ
	pet:SetAttribute("PetAbilities", table.concat(def.Abilities or {}, ",")) -- ปุ่มเปิด/ปิดความสามารถบนการ์ด (ActivePetsHud)
	if def.FireflyRing then pet:SetAttribute("FireflyRing", true) end -- ฝั่งผู้เล่นวาดหิ่งห้อยบินวนเอง (PetFireflyRing)
	if def.FireflyColors then -- สีหิ่งห้อยเฉพาะตัว (ไม่ตั้ง = ทองส้มแบบจิ้งจอกเก้าหาง)
		pet:SetAttribute("FireflyColorA", def.FireflyColors[1])
		pet:SetAttribute("FireflyColorB", def.FireflyColors[2] or def.FireflyColors[1])
	end
	if def.FireflyCount then pet:SetAttribute("FireflyCount", def.FireflyCount) end -- จำนวนดวง (ไม่ตั้ง = 9)
	if def.NineLives then pet:SetAttribute("NineLives", def.NineLives) end
	-- ข้อมูลให้ PetAnimator ฝั่งผู้เล่นทำแอนิเมชันเอง (ท่าเดิน / บิน / สีรุ้ง / ทิศหน้าของโมเดล)
	if def.BoneNames then pet:SetAttribute("AnimBones", HttpService:JSONEncode(def.BoneNames)) end
	if def.Flying then pet:SetAttribute("AnimFlying", true) end
	if def.RainbowAura then pet:SetAttribute("RainbowAura", true) end
	pet:SetAttribute("FacingOffset", def.FacingOffset or CFrame.new())
	if def.AuraDim then pet:SetAttribute("AuraDim", def.AuraDim) end -- 2026-11-19 AuraDim: applyRarityGlow + PetFireflyRing อ่านไปลดความสว่างเฉพาะตัว
	applyRarityGlow(pet, def.Rarity) -- จำนวนดวงไฟ = ชีวิตที่เหลือ (อ่านจาก PetLives_<petId> ของเจ้าของ)

	-- Anchor เฉพาะชิ้นราก ที่เหลือให้ Motor6D เป็นตัวยึดไว้
	-- ถ้า Anchor ทุกชิ้น (โค้ดเดิม) ข้อต่อจะขยับอะไรไม่ได้เลย แอนิเมชันเดิน/กระโดดจึงไม่เคยทำงาน
	-- สัตว์เลี้ยงเลยเลื่อนไปทั้งตัวแข็งๆ เหมือนรูปปั้น วัดแล้วยืนยัน: ขยับข้อต่อได้ 0 องศา
	-- Massless กันน้ำหนักแขนขาดึงริก และยังปิดการชนไว้เหมือนเดิม
	-- ถ้าโมเดลไหนไม่ได้ตั้ง PrimaryPart ไว้ ให้ Anchor ทุกชิ้นแบบเดิม กันชิ้นส่วนร่วง
	-- ปรับ C0 ของทุกข้อต่อให้ตรงกับตำแหน่งที่โมเดลวางไว้จริงก่อน
	-- ตอน Anchor ทุกชิ้น ตำแหน่งมาจาก CFrame ของแต่ละชิ้น ค่าข้อต่อผิดก็ไม่มีผล
	-- แต่พอปล่อยให้ข้อต่อเป็นตัวยึด ชิ้นส่วนจะเด้งไปอยู่ตามค่าข้อต่อแทน
	-- โมเดลแพนด้ามีค่าข้อต่อคลาดจากตำแหน่งจริงถึง 0.49 studs ถ้าไม่ปรับก่อน ตัวจะเพี้ยน
	for _, joint in ipairs(pet:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			joint.C0 = joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame) * joint.C1
		end
	end

	local rootPart = pet.PrimaryPart
	for _, desc in ipairs(pet:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = (rootPart == nil) or (desc == rootPart)
			desc.CanCollide = false
			desc.CollisionGroup = PET_COLLISION_GROUP
			desc.Massless = (rootPart ~= nil) and (desc ~= rootPart)
		end
	end

	local humanoid = pet:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = player.Name .. "'s " .. def.DisplayName
		humanoid.WalkSpeed = def.WalkSpeed or 8
		-- ปิดระบบท่าทางของ Humanoid: เราขยับสัตว์เลี้ยงเองด้วย PivotTo + Motor6D ไม่ได้ใช้ระบบเดินของมัน
		-- ถ้าปล่อยไว้ Humanoid จะหาพื้นไม่เจอ (ชิ้นรากถูก Anchor) แล้วเข้าสถานะ FallingDown
		-- ซึ่งไปคลายข้อต่อจนหัวและหูหลุดลอยออกจากตัว (วัดได้: หูเพี้ยนไป 0.31 studs)
		humanoid.EvaluateStateMachine = false
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	pet.Parent = workspace

	-- วางไว้ข้างตัวละครตั้งแต่แรก ไม่งั้นมันจะเกิดที่ตำแหน่งของเทมเพลต (ไกลมาก)
	-- แล้วต้องเดินกลับมาหาเจ้าของด้วยความเร็วเดินปกติ ซึ่งใช้เวลาเป็นนาที
	do
		local character = player.Character
		local charHRP = character and character:FindFirstChild("HumanoidRootPart")
		if charHRP then
			local side = PetController.SlotSide(charHRP.CFrame, slot)
			pet:PivotTo(CFrame.new(charHRP.Position + side * (def.FollowDistance or 3)))
		end
	end

	-- ระยะจากจุด Pivot ถึงเท้า ใช้วางเท้าให้แตะพื้นพอดี (โมเดลแต่ละตัวไม่เท่ากัน ราว 0.56-0.76 studs)
	-- ไม่นับหาง/วงแหวน เพราะหางที่แผ่ออกข้าง (เช่น จิ้งจอกเก้าหาง) ห้อยต่ำกว่าเท้า ทำให้ตัวลอยจากพื้น
	local feetOffset
	do
		local bottom = math.huge
		for _, part in ipairs(pet:GetDescendants()) do
			if part:IsA("BasePart") and part ~= pet.PrimaryPart
				and not string.find(string.lower(part.Name), "tail") and part.Name ~= "Halo" then
				local cf, size = part.CFrame, part.Size
				for _, x in { -1, 1 } do for _, y in { -1, 1 } do for _, z in { -1, 1 } do
					bottom = math.min(bottom, (cf * Vector3.new(x * size.X / 2, y * size.Y / 2, z * size.Z / 2)).Y)
				end end end
			end
		end
		if bottom == math.huge then
			local bbCF, bbSize = pet:GetBoundingBox()
			bottom = bbCF.Position.Y - bbSize.Y / 2
		end
		feetOffset = pet:GetPivot().Position.Y - bottom
	end

	-- ออร่าสีรุ้ง / ท่าเดิน / หางพัด / กระพือปีก: PetAnimator ฝั่งผู้เล่นทำ (อ่าน Attribute RainbowAura / AnimBones / AnimFlying)
	if def.Flying then setupFireBreath(pet) end

	-- โบนัสของเจ้าของตอนพาตัวนี้ออกมา (มังกรสุลต่าน): ขายได้เงินเพิ่ม (Attribute PetSellBonus อ่านใน SultanConfig.SellMultiplier)
	-- และผักที่เจ้าของปลูกโตเร็วขึ้น (PetGrowBoost อ่านใน PlantingSystem) เก็บตัวนี้กลับ/หายไป = คืนค่า
	-- ผีน้อยนักปักหุ่น: StrawYieldBonus -> PetStrawYieldBonus (เก็บเกี่ยวในรัศมีหุ่นฟางของเจ้าของได้ผลผลิตเพิ่ม อ่านใน PlantingSystem.doHarvest)
	-- 2026-10-15: โบนัสหุ่นฟางของผีน้อยโตตามเลเวล (PetLevelConfig.StrawYieldAt: x1.5 ที่ Lv.1 → x1.8 ที่ Lv.15) อัปเลเวลตอนพาออกมาอยู่ = ปรับทันที
	if def.SellBonus or def.GrowBoost or def.StrawYieldBonus or def.StrawGrowBoost then
		local function strawValue()
			if not def.StrawYieldBonus then return nil end
			return PetLevelConfig.StrawYieldAt(petId, PetHunger.GetLevel(player, petId)) or def.StrawYieldBonus
		end
		local applied = {}
		local function addAttr(attr, value)
			if not value or value == 0 then return end
			local v = math.floor(((player:GetAttribute(attr) or 0) + value) * 1000 + 0.5) / 1000
			player:SetAttribute(attr, v > 0 and v or nil)
		end
		local function apply(values)
			for attr, value in pairs(values) do
				addAttr(attr, value - (applied[attr] or 0))
				applied[attr] = value
			end
		end
		-- PetStrawGrowBoost (ผีน้อย 2026-10-15): ต้นในรัศมีหุ่นฟางของเจ้าของโตเร็วขึ้น อ่านใน PlantingSystem.growPlant
		apply({ PetSellBonus = def.SellBonus or 0, PetGrowBoost = def.GrowBoost or 0, PetStrawYieldBonus = strawValue() or 0, PetStrawGrowBoost = def.StrawGrowBoost or 0 })
		local levelConn
		if def.StrawYieldBonus then
			levelConn = player:GetAttributeChangedSignal("PetLevel_" .. petId):Connect(function()
				if pet.Parent then apply({ PetStrawYieldBonus = strawValue() or 0 }) end
			end)
		end
		local removed = false
		pet.Destroying:Connect(function()
			if removed then return end
			removed = true
			if levelConn then levelConn:Disconnect() end
			if player.Parent then
				local back = {}
				for attr in pairs(applied) do back[attr] = 0 end
				apply(back)
			end
		end)
	end

	local abilityModules = loadAbilityModules(def.Abilities or {})
	local abilityStates = {}
	for _, abilityModule in ipairs(abilityModules) do
		abilityStates[abilityModule] = (abilityModule.Init and abilityModule.Init(player, pet)) or {}
	end

	local followConn
	local enabledAbilities = {}

	-- สถานะการเคลื่อนที่ (เก็บไว้ข้ามเฟรม)
	local smoothTarget          -- เป้าหมายที่ถูกกรองแล้ว
	local currentYaw            -- ทิศที่หันอยู่จริง (เรเดียน, ยังไม่รวม FacingOffset)
	local vel = 0               -- ความเร็วปัจจุบัน (studs/วินาที)
	local lastPlayerPos         -- ใช้ดูว่าผู้เล่นขยับไหม
	local stillTime = 0         -- ผู้เล่นยืนนิ่งมานานแค่ไหน
	local wanderOffset = Vector3.zero
	local wanderTimer = 0
	local reachToken, reachStartedAt, reachBudget = 0, 0, 0 -- รหัสรอบทำงาน / เวลาเริ่ม / เวลาสูงสุดที่ควรใช้ (เกินนี้ถือว่าค้าง)
	local reachInFlight = false   -- onReach กำลังทำงานอยู่ ไม่ให้เรียกซ้ำ
	local workPauseUntil = 0      -- ช่วงหยุดพักหลังทำงานเสร็จ
	local workStart, workUntil = 0, 0   -- ช่วงก้มทำงาน (จิกเก็บ/ขุดปลูก) ก่อนจะเก็บ/ปลูกจริง
	local feedCall = nil              -- ผู้เล่นกดเรียกมากินอาหาร { untilT, onArrive } (PetManager สั่งผ่าน CallToEat)
	local workFacePos             -- ตำแหน่งต้นที่กำลังก้มทำงานอยู่ ไว้หันหน้าเข้าหา
	local workMode = "peck"       -- ท่าตอนทำงาน: "peck" = ก้มจิก/ขุด, "hop" = เด้งตัวเบาๆ (หยิบเมล็ด/เก็บเข้ากระเป๋า)
	local DEFAULT_WORK_TIME = 1.0   -- เท่ากับผู้เล่นกดค้างเก็บเกี่ยว (HoldDuration = 1 วิ)

	local WALK_SPEED = def.WalkSpeed or 8
	-- ความเร็ว 2 ระดับ: ตามเจ้าของ กับ ไปทำงาน (ปลูก/เก็บเกี่ยว)
	-- ตอนแก้อาการตัวสั่น ผมเคยจำกัดไว้ที่ WalkSpeed (8) ทำให้ไปถึงเป้า 40 studs ใช้ 4.5 วิ (เดิมราว 0.7 วิ)
	-- และช้ากว่าผู้เล่นเดิน (16) ครึ่งหนึ่ง สัตว์เลี้ยงเลยตามไม่ทันและทำงานได้น้อยลงมาก
	local FOLLOW_SPEED = math.max(WALK_SPEED, 18)  -- เร็วกว่าผู้เล่นเดินเล็กน้อย จะได้ตามทัน
	-- ไปทำงานด้วยความเร็วเท่าตอนเดินตาม (เดิม 26 วิ่งพุ่งไปเร็วเกิน ดูไม่เหมือนเดินไปเก็บ)
	local WORK_SPEED = FOLLOW_SPEED
	-- เวลาต่อต้นให้เท่ากับผู้เล่นทำเอง: ก้มทำงาน 1 วิพอดี (ไม่สุ่ม) แล้วไปต้นถัดไปเลย
	-- เดิมสุ่ม 85-125% ของ 1.3 วิ แล้วพักอีก 0.7 วิ รวมราว 2 วิต่อต้น ช้ากว่าผู้เล่นเกือบเท่าตัว
	local WORK_PAUSE = 0
	local LEASH_DISTANCE = 120                     -- หลงไกลเกินนี้ (เช่นผู้เล่นวาร์ป) พากลับมาข้างเจ้าของเลย
	local ACCEL = 70                      -- studs/วินาที^2 เร่ง/ชะลอแบบค่อยเป็นค่อยไป
	local TURN_RATE = math.rad(540)       -- หันได้ไม่เกิน 540 องศา/วินาที (วิ่งเร็วขึ้นจึงเผื่อให้เลี้ยวทัน) (เดิมหันทันทีทุกเฟรม)
	local ARRIVE_SLACK = 0.4                     -- ผ่อนระยะ "ถึงแล้ว" ให้เผื่อ ไม่ต้องเป๊ะ
	local STOP_DISTANCE = 1.2             -- เข้าใกล้เป้าเท่านี้ถือว่าถึงแล้ว
	local IDLE_AFTER = 2                  -- ผู้เล่นนิ่งเกินกี่วินาทีจึงเริ่มเดินเล่น

	-- หาความสูงพื้นใต้จุดที่กำหนด (ข้ามของที่ทะลุได้ เช่น ต้นผัก/ตัวสัตว์เลี้ยง และข้ามตัวผู้เล่นทุกคน)
	-- เดิมความสูงไล่ตามเป้าตรงๆ: ตอนไปแปลงเป้าคือจุดปลูกบนผิวดิน จุด Pivot กลางตัวเลยจมลงไปในดิน
	-- ดูเหมือนดำดินไปเก็บ ตอนนี้วางเท้าบนพื้นจริงเสมอ ทั้งตอนเดินตามและตอนไปทำงาน
	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	groundParams.RespectCanCollide = true
	local function findGroundY(pos, fromY)
		local ignore = { pet }
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then table.insert(ignore, p.Character) end
		end
		groundParams.FilterDescendantsInstances = ignore
		local result = workspace:Raycast(Vector3.new(pos.X, fromY, pos.Z), Vector3.new(0, -30, 0), groundParams)
		return result and result.Position.Y, result and result.Material
	end

	-- พื้นเปลี่ยนช้ากว่าการเคลื่อนที่ของสัตว์เลี้ยง: ตรวจ raycast 20 ครั้ง/วินาที
	-- แต่ยังคำนวณและขยับโมเดลทุกเฟรมเพื่อให้การเดินและแอนิเมชันลื่นเหมือนเดิม
	local GROUND_CHECK_INTERVAL = 1 / 20
	local groundCheckTimer = GROUND_CHECK_INTERVAL
	local cachedGroundY
	local cachedOnWater = false -- ยืนบนผิวน้ำอยู่ไหม (เฉพาะสัตว์ def.Swims ใช้จมตัว 2026-11-06)
	local hasGroundSample = false

	-- ตำแหน่งที่เซิร์ฟเวอร์คิด (ทุกเฟรม ไม่รวมท่าก้ม/ลอย) กับตำแหน่งที่ส่งให้ผู้เล่นล่าสุด (ทุก PIVOT_SEND_INTERVAL)
	local simCF = pet:GetPivot()
	local sentCF = simCF
	local sendTimer = 0
	local function pushPivot()
		sendTimer = 0
		pet:PivotTo(simCF)
		sentCF = pet:GetPivot() -- อ่านกลับ กันเศษทศนิยมทำให้เข้าใจผิดว่ามีสคริปต์อื่นย้าย
	end

	local function updateFollow(dt)
		if not pet or not pet.Parent then
			if followConn then followConn:Disconnect() end
			return
		end

		local character = player.Character
		if not character then return end
		local charHRP = character:FindFirstChild("HumanoidRootPart")
		if not charHRP then return end

		-- สคริปต์อื่นย้ายตัวโมเดลเอง (เช่น พามาข้างตัวละครที่เพิ่งเกิดใหม่) = คิดต่อจากตำแหน่งนั้น
		local actualCF = pet:GetPivot()
		if (actualCF.Position - sentCF.Position).Magnitude > EXTERNAL_MOVE then
			simCF, sentCF = actualCF, actualCF
			smoothTarget, vel = nil, 0
			hasGroundSample = false
			groundCheckTimer = GROUND_CHECK_INTERVAL
		end
		local currentCF = simCF
		local currentPos = currentCF.Position

		-- หลงไกลเกินไป (ผู้เล่นวาร์ป/ตกแมพ) พาวาร์ปกลับมาข้างเจ้าของเลย ไม่ต้องเดินข้ามแมพ
		local ownerPos = charHRP.Position
		if (currentPos - ownerPos).Magnitude > LEASH_DISTANCE then
			local side = PetController.SlotSide(charHRP.CFrame, slot)
			simCF = CFrame.new(ownerPos + side * (def.FollowDistance or 3)) * CFrame.Angles(0, currentYaw or 0, 0) * (def.FacingOffset or CFrame.new())
			pushPivot()
			smoothTarget, vel = nil, 0
			hasGroundSample = false
			groundCheckTimer = GROUND_CHECK_INTERVAL
			return
		end

		local targetPos, reachDistance, onReach = nil, nil, nil
		local currentWorkTime = DEFAULT_WORK_TIME
		local currentExtras = nil -- จังหวะก่อน/หลังทำงาน ที่ความสามารถส่งมา (เช่น หยิบเมล็ด / เก็บเข้ากระเป๋า)
		-- หิวจนหมดแรง (0%) ไม่ไปทำงาน แค่เดินตามเจ้าของจนกว่าจะได้กิน
		-- ถูกเรียกมากินอาหาร: หยุดทุกกิจกรรม วิ่งมาหาเจ้าของ ถึงแล้วค่อยป้อน (หมดเวลา = กลับไปทำงานตามเดิม)
		local calling = feedCall
		if calling and os.clock() > calling.untilT then feedCall, calling = nil, nil end
		-- เจ้าของอุ้มอยู่ (ZukzonService ตั้ง "HeldByOwner") = ตัวจริงซ่อนอยู่ ไม่ทำงาน
		local canWork = calling == nil and PetHunger.Get(player, petId) > 0 and not pet:GetAttribute("HeldByOwner")
		for _, abilityModule in ipairs(canWork and abilityModules or {}) do
			if enabledAbilities[abilityModule.Id] and abilityModule.GetTarget then
				local pos, reach, callback, workTime, extras = abilityModule.GetTarget(abilityStates[abilityModule], {
					player = player, petModel = pet, petPivot = currentCF, charHRP = charHRP, definition = def,
				})
				if pos then
					targetPos, reachDistance, onReach = pos, reach, callback
					currentWorkTime = workTime or DEFAULT_WORK_TIME
					currentExtras = extras
					break
				end
			end
		end

		-- หยุดพักสั้นๆ หลังทำงานเสร็จ ให้ดูเหมือนกำลังก้มทำ ไม่ไถลไปเป้าถัดไปทันที
		-- (ยืนอยู่กับที่ ไม่ใช่กลับไปหาเจ้าของ ไม่งั้นจะเดินไปเดินกลับทุกครั้ง)
		-- ยืนทำงานอยู่กับที่ตลอดทุกจังหวะ (หยิบเมล็ด -> ก้มทำ -> เก็บเข้ากระเป๋า)
		-- เดิมนับเฉพาะตอนความสามารถยังมีเป้า พอเก็บเสร็จเป้าหาย สัตว์จะเดินจากไปทั้งที่ผลผลิตยังลอยมาไม่ถึงตัว
		-- ธงทำงานค้าง (งานตายกลางทางหรือรอนานเกินเวลา) = ปลดเอง ไม่งั้นสัตว์ยืนนิ่งไม่ทำงานจนต้องเอาออกแล้วเรียกใหม่
		if reachInFlight and os.clock() - reachStartedAt > reachBudget then
			reachInFlight = false
			workPauseUntil = 0
			warn("[PetController] " .. tostring(petId) .. " ทำงานค้างเกินเวลา ปลดให้กลับไปทำงานต่อ")
		end
		local isWorking = calling == nil and (reachInFlight or os.clock() < workPauseUntil)
		if isWorking then
			targetPos, reachDistance, onReach = currentPos, 99, nil
		end
		local realTarget = targetPos  -- เป้าจริง (ต้นพืช/ช่องปลูก) ไว้เช็คว่าไปถึงจริงไหม

		if calling then
			-- วิ่งมายืนข้างเจ้าของ (ด้านเดียวกับช่องของมัน) ใกล้พอให้กิน
			targetPos, reachDistance, onReach = charHRP.Position + PetController.SlotSide(charHRP.CFrame, slot) * 2.2, 0.8, nil
			realTarget = targetPos
		end
		local isSpecialTarget = targetPos ~= nil

		-- ผู้เล่นยืนนิ่งนานพอ → สัตว์เลี้ยงเดินเล่นรอบๆ จุดที่ยืนประจำ ไม่ยืนแข็งเป็นรูปปั้น
		local playerPos = charHRP.Position
		local playerMoved = (lastPlayerPos == nil) or (playerPos - lastPlayerPos).Magnitude > 0.05
		lastPlayerPos = playerPos
		if playerMoved or isSpecialTarget then
			stillTime = 0
			wanderTimer = 0
			wanderOffset = wanderOffset:Lerp(Vector3.zero, math.clamp(dt * 2, 0, 1)) -- เลิกเดินเล่น กลับมาตามเจ้าของ
		else
			stillTime += dt
			-- สัตว์ที่นอนได้ (def.SleepAfter เช่น ซุกซน 2026-10-22): เจ้าของนิ่งนานเกินนี้ = หยุดเดินเล่น นอนขดตรงนั้น (ท่านอนทำใน PetAnimator จาก Attribute "Sleeping")
			if def.SleepAfter and stillTime > def.SleepAfter then
				-- นอนอยู่ ไม่สุ่มจุดเดินเล่นใหม่
			elseif def.SitAfter and stillTime > def.SitAfter then
				-- นั่งรอเจ้าของ (def.SitAfter เช่น ซุกซน 2026-10-22) ไม่เดินเล่น ท่านั่งทำใน PetAnimator จาก Attribute "Sitting"
			elseif stillTime > IDLE_AFTER then
				wanderTimer -= dt
				if wanderTimer <= 0 then
					wanderTimer = rng:NextNumber(2.5, 5)      -- ย้ายที่ทุก 2.5-5 วินาที
					local a = rng:NextNumber(0, math.pi * 2)
					local r = rng:NextNumber(1.2, 3.2)
					wanderOffset = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				end
			end
		end

		local sleepingNow = false
		if def.SleepAfter then
			sleepingNow = stillTime > def.SleepAfter and not isSpecialTarget and not pet:GetAttribute("HeldByOwner")
			if pet:GetAttribute("Sleeping") ~= sleepingNow then pet:SetAttribute("Sleeping", sleepingNow) end
		end
		if def.SitAfter then
			local sittingNow = stillTime > def.SitAfter and not sleepingNow and not isSpecialTarget and not pet:GetAttribute("HeldByOwner")
			if pet:GetAttribute("Sitting") ~= sittingNow then pet:SetAttribute("Sitting", sittingNow) end
		end

		if not targetPos then
			-- slot 1 = ด้านขวา, slot 2 = ด้านซ้าย
			local sideVector = PetController.SlotSide(charHRP.CFrame, slot)
			targetPos = playerPos + sideVector * (def.FollowDistance or 3) + wanderOffset
			reachDistance = STOP_DISTANCE
		end

		-- ตำแหน่งผู้เล่นมาถึงเซิร์ฟเวอร์ราว 20 ครั้ง/วินาที แต่ลูปนี้ทำงาน 60 ครั้ง/วินาที
		-- ถ้าวิ่งตามค่าดิบจะได้การขยับเป็นช่วงๆ (เดิน 1 เฟรม หยุด 2 เฟรม) เห็นเป็นตัวกระตุก
		-- จึงกรองเป้าหมายให้ลื่นก่อน แล้วค่อยวิ่งตามเป้าที่กรองแล้ว
		-- เป้างาน (ต้นพืช) อยู่นิ่ง ไม่ต้องกรอง เดินตรงไปหาเลย (ความเร็วมีความเฉื่อยอยู่แล้ว ไม่กระชาก)
		if not smoothTarget or (isSpecialTarget and not isWorking) then
			smoothTarget = targetPos
		else
			smoothTarget = smoothTarget:Lerp(targetPos, math.clamp(dt * 10, 0, 1))
		end

		local flat = Vector3.new(smoothTarget.X - currentPos.X, 0, smoothTarget.Z - currentPos.Z)
		local dist = flat.Magnitude
		local stopDist = reachDistance or STOP_DISTANCE

		-- ยิ่งใกล้ยิ่งช้าลง แล้วเร่ง/ชะลอแบบมีความเฉื่อย ไม่กระชากจาก 0 เป็นเต็มสปีดในเฟรมเดียว
		local desiredSpeed = (dist > stopDist) and math.min(isSpecialTarget and WORK_SPEED or FOLLOW_SPEED, (dist - stopDist) * 3.5) or 0
		vel += math.clamp(desiredSpeed - vel, -ACCEL * dt, ACCEL * dt)

		local newPos = currentPos
		if vel > 0.01 and dist > 1e-4 then
			newPos = currentPos + (flat / dist) * math.min(vel * dt, dist)
		end
		-- ความสูง: วางเท้าบนพื้นจริงใต้ตำแหน่งใหม่ (ไม่มีพื้นค่อยไล่ตามเป้าแบบเดิม) ค่อยๆ ไล่ กันสะดุดตอนพื้นต่างระดับ
		groundCheckTimer += dt
		if not hasGroundSample or groundCheckTimer >= GROUND_CHECK_INTERVAL then
			groundCheckTimer = 0
			local groundMaterial
			cachedGroundY, groundMaterial = findGroundY(newPos, math.max(playerPos.Y, smoothTarget.Y, currentPos.Y - feetOffset) + 1.5)
			cachedOnWater = groundMaterial == Enum.Material.Water
			if def.Swims and pet:GetAttribute("Swimming") ~= cachedOnWater then pet:SetAttribute("Swimming", cachedOnWater) end -- PetAnimator / PlatypusFx อ่านไปทำท่าว่ายและระลอกน้ำ
			hasGroundSample = true
		end
		local groundY = cachedGroundY
		-- สัตว์บินได้: ลอยสูงจากพื้น ตอนทำงาน (ก้มเก็บ) โฉบลงต่ำ
		local hover = 0
		if def.Flying then
			hover = (os.clock() < workUntil or reachInFlight) and (def.Flying.WorkHeight or 0.7) or (def.Flying.Height or 1.8)
		end
		-- สัตว์ว่ายน้ำได้ (def.Swims ตุ่นนักอนุรักษ์): อยู่บนผิวน้ำ = ตัวจมลงครึ่งตัว
		if def.Swims and cachedOnWater then hover -= def.Swims.Sink or 0.7 end
		local desiredY = groundY and (groundY + feetOffset + hover) or smoothTarget.Y
		newPos = Vector3.new(newPos.X, currentPos.Y + (desiredY - currentPos.Y) * math.clamp(dt * 10, 0, 1), newPos.Z)

		-- ทิศที่อยากหัน: กำลังเดิน = หันไปทางที่เดิน, หยุดแล้ว = หันหาเจ้าของ
		-- เดิมสองกรณีนี้สลับกันได้ทุกเฟรม ทำให้ตัวหมุนกลับไปกลับมา ~55 องศาต่อเฟรม (อาการตัวสั่น)
		-- ตอนนี้หันได้ไม่เกิน TURN_RATE ต่อวินาที ต่อให้สลับกรณีก็ค่อยๆ หัน ไม่กระตุก
		local desiredYaw
		local facePos = (isWorking and workFacePos) or (isSpecialTarget and realTarget) or nil
		if vel > 1 and dist > stopDist then
			desiredYaw = math.atan2(-flat.X, -flat.Z)
		elseif facePos then
			-- ตอนทำงาน หันหน้าเข้าหาต้นพืช (เดิมหันหาเจ้าของ ดูเหมือนเก็บข้างหลัง)
			local toPlant = Vector3.new(facePos.X - newPos.X, 0, facePos.Z - newPos.Z)
			if toPlant.Magnitude > 0.1 then desiredYaw = math.atan2(-toPlant.X, -toPlant.Z) end
		else
			local toPlayer = Vector3.new(playerPos.X - newPos.X, 0, playerPos.Z - newPos.Z)
			if toPlayer.Magnitude > 0.1 then desiredYaw = math.atan2(-toPlayer.X, -toPlayer.Z) end
		end
		if currentYaw == nil then currentYaw = desiredYaw or 0 end
		local yawStep = 0
		if desiredYaw then
			local diff = math.atan2(math.sin(desiredYaw - currentYaw), math.cos(desiredYaw - currentYaw))
			yawStep = math.clamp(diff, -TURN_RATE * dt, TURN_RATE * dt)
			currentYaw += yawStep
		end

		-- ท่าก้มจิก/เด้งตัวตอนทำงาน และการลอยขึ้นลง/เอียงตัวของสัตว์บิน: PetAnimator ฝั่งผู้เล่นทำ (อ่าน Attribute WorkAnim)
		simCF = CFrame.new(newPos) * CFrame.Angles(0, currentYaw, 0) * (def.FacingOffset or CFrame.new())
		sendTimer += dt
		if sendTimer >= PIVOT_SEND_INTERVAL then
			local moved = (simCF.Position - sentCF.Position).Magnitude
			local turned = math.acos(math.clamp(simCF.LookVector:Dot(sentCF.LookVector), -1, 1))
			if moved > PIVOT_SEND_MIN_MOVE or turned > PIVOT_SEND_MIN_TURN then pushPivot() end
		end


		-- ถึงตัวเจ้าของแล้ว (ชะลอเกือบหยุด) = ป้อนอาหารครั้งเดียว
		if calling and feedCall == calling then
			local toOwner = Vector3.new(playerPos.X - newPos.X, 0, playerPos.Z - newPos.Z).Magnitude
			if toOwner <= 3.4 and vel < 4 then
				feedCall = nil
				task.spawn(function()
					local ok, err = pcall(calling.onArrive)
					if not ok then warn("[PetController] ป้อนอาหารตอนมาถึงผิดพลาด: " .. tostring(err)) end
				end)
			end
		end

		-- ต้องเดินไปถึงต้นจริง (วัดจากตำแหน่งจริง ไม่ใช่เป้าที่กรองแล้ว) และชะลอเกือบหยุดแล้ว ถึงจะเริ่มทำงาน
		local realDist = realTarget and Vector3.new(realTarget.X - newPos.X, 0, realTarget.Z - newPos.Z).Magnitude or math.huge
		if realDist <= stopDist + ARRIVE_SLACK and vel < 3 and isSpecialTarget and onReach and not reachInFlight then
			workFacePos = realTarget
			-- เดิมเรียกซ้ำทุกเฟรม (~60 ครั้ง/วินาที) ตอนนี้เรียกครั้งเดียวแล้วรอให้จบก่อน
			-- ใช้ pcall กันความสามารถที่ error แล้ว reachInFlight ค้างเป็น true ทำให้สัตว์เลี้ยงหยุดทำงานถาวร
			-- ถึงแล้วไม่เก็บทันที: หยุดก้มทำงานก่อน (มีท่าจิก) แล้วค่อยเก็บ/ปลูกตอนท้ายช่วง
			reachInFlight = true
			-- อิ่มเต็ม = เท่าผู้เล่นทำเอง (1 วิ) หิวเหลือ 50% ทำงานได้ครึ่งเดียว = ใช้ 2 วิต่อต้น
			-- เลเวลจากตัวซ้ำ: ทุกเลเวลทำงานเร็วขึ้น 2% (Lv.15 ใช้เวลาต่อต้นน้อยลง 1/1.28)
			local efficiency = math.max(PetHunger.GetEfficiency(player, petId), PetHunger.MIN_EFFICIENCY)
			local duration = currentWorkTime / (efficiency * PetHunger.GetSpeed(player, petId))
			local workSpot = realTarget
			local extras = currentExtras or {}
			local preTime = (extras.preTime or 0) * (def.PreTimeMult or 1) -- เช่น มังกรสุลต่าน 0.3 = หยิบเมล็ดเร็วกว่าตัวอื่น (2026-10-09)
			reachToken += 1
			local myToken = reachToken
			reachStartedAt = os.clock()
			reachBudget = preTime + duration + (extras.postTime or 0) + 8
			local function phase(mode, length)
				workMode = mode
				workStart = os.clock()
				workUntil = workStart + length
				workPauseUntil = workUntil
				-- PetAnimator ฝั่งผู้เล่นเล่นท่าตามนี้ (ท่า ; เวลาเซิร์ฟเวอร์ตอนเริ่ม ; ความยาว)
				pet:SetAttribute("WorkAnim", string.format("%s;%.3f;%.3f", mode, workspace:GetServerTimeNow(), length))
			end
			local function isStillThere()
				local here = pet.Parent and simCF.Position
				return here and Vector3.new(workSpot.X - here.X, 0, workSpot.Z - here.Z).Magnitude <= stopDist + 1
			end
			local function safe(fn, ...)
				if not fn then return end
				local ok, err = pcall(fn, ...)
				if not ok then warn("[PetController] เอฟเฟกต์ทำงานผิดพลาด: " .. tostring(err)) end
			end
			task.spawn(function()
				local ctx = {}
				-- 1) ก่อนทำงาน (เช่น หยิบเมล็ดขึ้นมา) เด้งตัวเบาๆ
				if extras.onPre and preTime > 0 then
					phase("hop", preTime)
					safe(extras.onPre, ctx, pet)
					task.wait(preTime)
				end
				-- 2) ก้มทำงาน (จิกเก็บ/ขุดฝัง) เวลาเท่าผู้เล่นทำเอง หารด้วยความหิว
				phase("peck", duration)
				safe(extras.onWork, ctx, pet, duration, workSpot)
				task.wait(duration)
				-- เช็คอีกรอบว่ายังยืนอยู่ที่ต้น (เช่น โดนวาร์ปกลับหาเจ้าของระหว่างทำงาน ก็ไม่เก็บ/ปลูกจากที่ไกล)
				local didWork = false
				if isStillThere() then
					local ok, result = pcall(onReach, ctx)
					if not ok then
						warn("[PetController] ความสามารถทำงานผิดพลาด: " .. tostring(result))
					elseif result then
						didWork = true
						-- ปลูก/เก็บได้จริงค่อยหิวขึ้น (ไปถึงแล้วโดนคนอื่นตัดหน้าไม่นับ)
						safe(PetHunger.Consume, player, petId, PetHunger.JOB_COST) -- error ตรงนี้ไม่ทำให้ธงทำงานค้าง
					end
				end
				-- 3) หลังทำงาน (เช่น ผลผลิตลอยเข้ากระเป๋า) เฉพาะตอนทำได้จริง
				if didWork and extras.onPost and (extras.postTime or 0) > 0 then
					phase("hop", extras.postTime)
					safe(extras.onPost, ctx, pet)
					task.wait(extras.postTime)
				end
				safe(extras.onCleanup, ctx)
				workMode = "peck"
				workPauseUntil = os.clock() + WORK_PAUSE
				if reachToken == myToken then reachInFlight = false end -- งานเก่าที่ถูกปลดไปแล้วไม่เคลียร์ธงของงานใหม่
			end)
		end
	end

	followConn = RunService.Heartbeat:Connect(updateFollow)

	local function destroy()
		if followConn then followConn:Disconnect() end
		for _, abilityModule in ipairs(abilityModules) do
			if abilityModule.Cleanup then abilityModule.Cleanup(abilityStates[abilityModule]) end
		end
		if pet and pet.Parent then pet:Destroy() end
	end

	if humanoid then
		humanoid.Died:Connect(destroy)
	end

	return {
		model = pet,
		definition = def,
		abilities = abilityModules,
		enabledAbilities = enabledAbilities,
		destroy = destroy,
		slot = slot,
		-- เรียกมากินอาหาร: onArrive ถูกเรียกเมื่อมาถึงข้างเจ้าของ / หมดเวลา timeout วินาที = ยกเลิกเอง
		CallToEat = function(timeout, onArrive) feedCall = { untilT = os.clock() + (timeout or 12), onArrive = onArrive } end,
		CancelCall = function() feedCall = nil end,
		IsCalled = function() return feedCall ~= nil end,
	}
end

return PetController