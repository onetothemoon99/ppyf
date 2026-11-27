-- BACKUP 2026-11-27 of ServerScriptService.PetSystem.Abilities.Planter (Studio) before the snow leopard +10% grow boost.
-- Restore: paste everything below this header into ServerScriptService.PetSystem.Abilities.Planter.Source.
-- Source bytes 22275, hash 1595221822 (h=(h*31+byte)%2147483647)
-- Ability: Planter — วิ่งไปปลูกผักจากเมล็ดที่ผู้เล่นวางไว้ช่อง 1 และ 2 บนแถบ 9 ช่อง ให้อัตโนมัติ
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local FarmSlotRegistry = require(ServerScriptService:WaitForChild("FarmSlotRegistry"))
local PetSeedSlots = require(script.Parent.Parent:WaitForChild("PetSeedSlots"))
local PetWorkEffects = require(script.Parent.Parent:WaitForChild("PetWorkEffects"))

local cropTemplates = ServerStorage:WaitForChild("CropTemplates")

local Planter = {}
Planter.Id = "Planter"
Planter.DisplayName = "ช่วยปลูกผัก"

local SEARCH_RADIUS = 40        -- หาช่องว่างในรัศมีนี้ "รอบตัวสัตว์เลี้ยง" (เดิมรอบตัวผู้เล่น ผู้เล่นเดินออกก็เลิกทำงาน)
local MAX_OWNER_DISTANCE = 90   -- ไม่ไปปลูกไกลจากเจ้าของเกินนี้ กันสัตว์เลี้ยงหลงไปไกล
local REACH_DISTANCE = 1.5  -- ต้องเดินไปถึงช่องปลูกบนแปลงก่อนถึงจะปลูกได้ (เดิม 3 + เผื่อ 0.4)
local SEARCH_INTERVAL = 0.5     -- ค้นหาใหม่ทุกครึ่งวินาที (เดิม 1 วินาที)
local FALLBACK_PLANT_LIMIT = 10 -- ใช้เฉพาะตอน PlantingSystem ยังไม่ทันแจ้งโควต้า
local TARGET_TIMEOUT = 25        -- เป้าเดิมค้างเกินนี้ (เดินไปไม่ถึง/ปลูกไม่ได้) ทิ้งแล้วหาใหม่ กันสัตว์ติดเป้าเดียวไม่ยอมไปไหน
local PICK_SEED_TIME = 0.6      -- ถึงช่องปลูกแล้ว หยิบเมล็ดขึ้นมาก่อน ค่อยก้มฝัง

-- จังหวะปลูก: หยิบเมล็ด (เด้งขึ้นเหนือหัว) -> ก้มฝัง (เมล็ดค่อยๆ ลงดิน) -> ต้นอ่อนขึ้น (PetController เป็นคนเรียก)
local EXTRAS = {
	preTime = PICK_SEED_TIME,
	onPre = function(ctx, pet)
		ctx.seed = PetWorkEffects.PickSeed(pet, 0.35)
	end,
	onWork = function(ctx, pet, duration, workSpot)
		-- จุดปลูกอยู่เหนือผิวดิน 0.5 (ดู computeSlotOffsets ใน PlantingSystem) เมล็ดต้องลงไปถึงผิวดินจริง
		PetWorkEffects.PlantSeed(ctx.seed, workSpot - Vector3.new(0, 0.5, 0), duration)
	end,
	onCleanup = function(ctx)
		PetWorkEffects.Remove(ctx.seed)
	end,
}

-- ============ แม่มดน้อย (def.CastFx) 2026-10-14: ร่ายเวทจากระยะ (def.CastReach) ไปที่ช่องปลูก แทนท่าหยิบเมล็ด/ก้มฝัง ============
-- ลูกแก้วเวทมนต์สีม่วงที่ตัวแม่มด + ลำแสงเวทโค้งไปที่ช่องปลูกทุกช่อง + วงเวทมนต์บนดิน + ประกายดาวลอยขึ้น (สร้างฝั่งเซิร์ฟเวอร์ ลบทิ้งตอนจบ)
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local MAGIC_A, MAGIC_B, MAGIC_C = Color3.fromRGB(180, 110, 255), Color3.fromRGB(255, 150, 230), Color3.fromRGB(255, 225, 130)
local function fxPart(name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = Enum.Material.Neon; p.Anchored = true
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	if shape then p.Shape = shape end
	return p
end
local function sparkles(parent, rate, colors, speed, life)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.Rate = rate
	e.Lifetime = NumberRange.new(life or 0.8, (life or 0.8) * 1.6)
	e.Speed = NumberRange.new(speed or 1.5, (speed or 1.5) * 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Color = colors
	e.LightEmission = 1
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-180, 180)
	e.Parent = parent
	return e
end
local TweenService = game:GetService("TweenService")
-- 2026-10-14 ผู้ใช้ขอ: แสงโปร่งใสๆ เหมือนเสกเวทมนต์ — ทุกชิ้นเป็นแสงจางๆ (ForceField/Neon โปร่งใส) ค่อยๆ สว่างขึ้นแล้วจางหาย ไม่มีชิ้นทึบ
local function fadeIn(part, target, time)
	local final = part.Transparency
	part.Transparency = 1
	TweenService:Create(part, TweenInfo.new(time or 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Transparency = target or final }):Play()
end
local function castStart(ctx, pet, spots, duration)
	local folder = Instance.new("Folder")
	folder.Name = "WitchCastFx"
	local pivot = pet:GetPivot()
	local orbPos = pivot.Position + pivot.LookVector * 1.1 + Vector3.new(0, 0.5, 0)
	-- ลูกแก้วแสง: แกนสว่างเล็กๆ + หมอกแสงโปร่งใสรอบนอก (ForceField = ระยิบระยับโปร่งแสง)
	local orb = fxPart("Orb", Vector3.new(0.45, 0.45, 0.45), CFrame.new(orbPos), MAGIC_B, Enum.PartType.Ball)
	orb.Transparency = 0.35
	orb.Parent = folder
	fadeIn(orb, 0.35)
	local halo = fxPart("OrbHalo", Vector3.new(1.4, 1.4, 1.4), CFrame.new(orbPos), MAGIC_A, Enum.PartType.Ball)
	halo.Material = Enum.Material.ForceField
	halo.Parent = folder
	fadeIn(halo, 0.55)
	TweenService:Create(halo, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = Vector3.new(1.8, 1.8, 1.8) }):Play()
	local light = Instance.new("PointLight"); light.Color = MAGIC_A; light.Range = 10; light.Brightness = 1.6; light.Parent = orb
	local twinkle = sparkles(orb, 26, ColorSequence.new(MAGIC_B, MAGIC_A), 1.6, 0.8)
	twinkle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	local a0 = Instance.new("Attachment"); a0.Parent = orb
	for i, spot in ipairs(spots) do
		local ground = spot - Vector3.new(0, 0.45, 0)
		local flat = CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90))
		-- วงเวทบนดิน: แผ่นแสงโปร่งใส ค่อยๆ ขยายออก + หมุนช้าๆ
		local ring = fxPart("Ring", Vector3.new(0.05, 1, 1), flat, MAGIC_A, Enum.PartType.Cylinder)
		ring.Material = Enum.Material.ForceField
		ring.Parent = folder
		fadeIn(ring, 0.35, 0.3)
		TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.05, 3.4, 3.4) }):Play()
		local inner = fxPart("RingGlow", Vector3.new(0.04, 2, 2), flat, MAGIC_B, Enum.PartType.Cylinder)
		inner.Parent = folder
		fadeIn(inner, 0.8, 0.4)
		-- เสาแสงโปร่งใสขึ้นจากแปลง (จางจากล่างขึ้นบน)
		local column = fxPart("LightColumn", Vector3.new(4.2, 1.6, 1.6), CFrame.new(ground + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), MAGIC_B, Enum.PartType.Cylinder)
		column.Material = Enum.Material.ForceField
		column.Parent = folder
		fadeIn(column, 0.6, 0.5)
		local rise = sparkles(ring, 18, ColorSequence.new({ ColorSequenceKeypoint.new(0, MAGIC_C), ColorSequenceKeypoint.new(0.5, MAGIC_B), ColorSequenceKeypoint.new(1, MAGIC_A) }), 1.4, 1.1)
		rise.EmissionDirection = Enum.NormalId.Right -- แกน X ของทรงกระบอก = ชี้ขึ้น
		rise.SpreadAngle = Vector2.new(30, 30)
		rise.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		-- ลำแสงเวทโค้ง โปร่งใส ไล่จางปลายสาย
		local a1 = Instance.new("Attachment"); a1.Parent = inner
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Color = ColorSequence.new(MAGIC_B, MAGIC_A)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0.85) })
		beam.Width0, beam.Width1 = 0.35, 0.12
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.CurveSize0 = (i % 2 == 1) and 2 or -2
		beam.Segments = 20
		beam.Parent = orb
	end
	folder.Parent = workspace
	ctx.castFx = folder
	-- จางหายก่อนจบการร่าย (เหลือ 0.3 วิสุดท้าย)
	local life = math.max(0.4, (duration or 1) - 0.3)
	task.delay(life, function()
		if not folder.Parent then return end
		for _, d in ipairs(folder:GetDescendants()) do
			if d:IsA("BasePart") then
				TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			elseif d:IsA("ParticleEmitter") then
				d.Enabled = false
			elseif d:IsA("Beam") then
				d.Enabled = false
			end
		end
	end)
end
-- ช่วงยกคทา (2026-10-14 ผู้ใช้ขอ): ลูกแก้วหน้าแม่มดค่อยๆ สว่างและใหญ่ขึ้น (รวมพลัง) จนถึงตอนร่าย แล้ว castStart ทำต่อ
-- ความยาวช่วงยกคทาสั้นลงตามเลเวล: Lv.1 = 1.5 วิ → Lv.15 = 0.75 วิ (castPreTime) · ผู้ใช้เลือกแบบ B 2026-10-14 (เดิม 2.0 → 1.0)
local CAST_PRE_MAX, CAST_PRE_MIN = 1.5, 0.75
local function castPreTime(level)
	level = math.clamp(math.floor(tonumber(level) or 1), 1, 15)
	return CAST_PRE_MAX - (level - 1) * (CAST_PRE_MAX - CAST_PRE_MIN) / 14
end
local function chargeStart(ctx, pet, length)
	local folder = Instance.new("Folder")
	folder.Name = "WitchChargeFx"
	local pivot = pet:GetPivot()
	local orbPos = pivot.Position + pivot.LookVector * 1.1 + Vector3.new(0, 0.5, 0)
	local core = fxPart("ChargeCore", Vector3.new(0.1, 0.1, 0.1), CFrame.new(orbPos), MAGIC_B, Enum.PartType.Ball)
	core.Transparency = 0.6
	core.Parent = folder
	local halo = fxPart("ChargeHalo", Vector3.new(0.3, 0.3, 0.3), CFrame.new(orbPos), MAGIC_A, Enum.PartType.Ball)
	halo.Material = Enum.Material.ForceField
	halo.Transparency = 1
	halo.Parent = folder
	local light = Instance.new("PointLight"); light.Color = MAGIC_A; light.Range = 8; light.Brightness = 0; light.Parent = core
	local motes = sparkles(core, 16, ColorSequence.new(MAGIC_C, MAGIC_B), 0.6, 0.6)
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	folder.Parent = workspace
	ctx.chargeFx = folder
	local info = TweenInfo.new(length, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(core, info, { Size = Vector3.new(0.45, 0.45, 0.45), Transparency = 0.3 }):Play()
	TweenService:Create(halo, info, { Size = Vector3.new(1.4, 1.4, 1.4), Transparency = 0.55 }):Play()
	TweenService:Create(light, info, { Brightness = 1.6 }):Play()
end
local function chargeStop(ctx)
	if ctx.chargeFx then ctx.chargeFx:Destroy() ctx.chargeFx = nil end
end
local CAST_EXTRAS = {
	preTime = CAST_PRE_MAX, -- ยกคทาก่อนร่าย (ค่าตั้งต้น Lv.1) แม่มดน้อยใช้ค่าตามเลเวลจาก castPreTime (ดู GetTarget)
	onPre = function(ctx, pet)
		chargeStart(ctx, pet, ctx.preLen or CAST_PRE_MAX)
	end,
	onWork = function(ctx, pet, duration, workSpot)
		chargeStop(ctx)
		local spots = { workSpot }
		if ctx.extraSpot then table.insert(spots, ctx.extraSpot) end
		castStart(ctx, pet, spots, duration)
	end,
	onCleanup = function(ctx)
		chargeStop(ctx)
		if ctx.castFx then ctx.castFx:Destroy() ctx.castFx = nil end
	end,
}

-- ผึ้งราชินี (2026-10-29): def.PollinateChance = โอกาสที่ต้นที่เพิ่งปลูกผสมเกสรติด ตอนเก็บได้ผลผลิตแถม 1 (PlantingSystem.doHarvest อ่าน slot.pollinated)
-- ติดแล้วบอกผู้เล่นทุกคนให้เด้งหยดน้ำผึ้ง "+1" ตรงต้น (Attribute PollinateFx บนตัวสัตว์ วาดใน QueenBeeFx)
local function tryPollinate(slot, def, pet)
	local chance = def and def.PollinateChance or 0
	if chance <= 0 or math.random() >= chance then return end
	slot.pollinated = true
	if pet and pet.Parent then
		pet:SetAttribute("PollinateFx", string.format("%.2f,%.2f,%.2f;%.3f", slot.position.X, slot.position.Y, slot.position.Z, workspace:GetServerTimeNow()))
	end
end

-- ปลูก 1 ต้นที่ช่องนั้น (หยิบเมล็ดช่อง 1 ก่อน หมดค่อยช่อง 2) คืน true = ปลูกได้จริง
local function plantOne(player, slot, limit, def, pet)
	if not slot or slot.occupied then return false end
	local seeds = PetSeedSlots.GetSeeds(player)
	if #seeds == 0 then return false end
	local seed = seeds[1]
	local cropType = seed:GetAttribute("CropType")
	if not cropType or not cropTemplates:FindFirstChild(cropType) then return false end
	if FarmSlotRegistry.CountPlayerPlants(player) >= limit then return false end
	slot.plantCrop(cropType, player)
	tryPollinate(slot, def, pet)
	local currentCount = seed:GetAttribute("Count") or 1
	if currentCount <= 1 then
		seed:Destroy()
	else
		local newCount = currentCount - 1
		seed:SetAttribute("Count", newCount)
		seed.Name = cropType .. " x" .. newCount
	end
	return true
end
local BATCH_NEAR = 4 -- ต้นที่ 2 ขึ้นไปต้องอยู่ใกล้ช่องแรกไม่เกินนี้ (สตัด)

-- โควต้าปลูกจริงของผู้เล่น = 10 + (ซื้อเพิ่ม x 5) PlantingSystem เป็นคนคิดแล้วเปิดไว้ทาง Attribute
-- เดิมโค้ดนี้ฝังเลข 10 ไว้เอง สัตว์เลี้ยงจึงหยุดปลูกที่ต้นที่ 10 ทั้งที่ผู้เล่นซื้อโควต้าไว้ถึง 35
local function getPlantLimit(player)
	return player:GetAttribute("PlantLimit") or FALLBACK_PLANT_LIMIT
end

function Planter.Init(player, petModel)
	return { target = nil, targetBoosted = false, targetSince = 0, lastSearchTime = 0 }
end

function Planter.GetTarget(state, context)
	local player = context.player

	local now = tick()
	local searchDue = (now - state.lastSearchTime) >= SEARCH_INTERVAL

	-- เป้าเดิมถูกปลูกแล้วหรือไกลเจ้าของเกินวง ให้ทิ้งทันที
	-- (เป้าที่อยู่ในรัศมีหุ่นเดิมไม่เคยถูกทิ้งเพราะระยะ จึงเคยค้างอยู่กับเป้าไกลที่เจ้าของเดินจากมา เลยให้ทิ้งเมื่อไกลเจ้าของเกิน MAX_OWNER_DISTANCE หรือค้างเกิน TARGET_TIMEOUT)
	if state.target and (state.target.occupied or now - (state.targetSince or now) > TARGET_TIMEOUT
			or (state.target.position - context.charHRP.Position).Magnitude > (state.targetBoosted and MAX_OWNER_DISTANCE or SEARCH_RADIUS)) then
		state.target = nil
		state.targetBoosted = false
	end

	-- ค้นหาเมื่อยังไม่มีเป้า หรือเป้าตอนนี้ไม่ได้อยู่ในรัศมีหุ่นของเจ้าของ (เผื่อเจ้าของเพิ่งปักหุ่น จะได้เปลี่ยนไปปลูกที่หุ่นเจ้าของ)
	if (not state.target or not state.targetBoosted) and searchDue then
		state.lastSearchTime = now

		-- ต้องมีเมล็ดในช่อง 1-2 และยังไม่เกินโควต้าปลูกจริง
		local seeds = PetSeedSlots.GetSeeds(player)
		if #seeds > 0 and FarmSlotRegistry.CountPlayerPlants(player) < getPlantLimit(player) then
			-- อันดับแรก: ช่องว่างในรัศมีหุ่นที่เจ้าของปักไว้ (หุ่นคนอื่นไม่แย่งลำดับเป้าของสัตว์เลี้ยง)
			-- ถ้าไม่มีหุ่นเจ้าของหรือรอบหุ่นเจ้าของเต็ม ให้หาเฉพาะช่องใกล้สัตว์และเจ้าของ โดยช่องในรัศมีหุ่นคนอื่นก็ใช้ได้
			local boosted = FarmSlotRegistry.FindNearestEmptyBoostedSlot(context.petPivot.Position, context.charHRP.Position, MAX_OWNER_DISTANCE, player.UserId)
			if boosted then
				state.target, state.targetBoosted, state.targetSince = boosted, true, now
			elseif not state.target then
				-- ไม่มีช่องใกล้เจ้าของก็ไม่ส่งสัตว์ไปหาเป้าหมายไกล ให้กลับไปติดตามเจ้าของ
				local slot = FarmSlotRegistry.FindNearestEmptySlot(context.petPivot.Position, player, SEARCH_RADIUS, SEARCH_RADIUS)
				if slot and (slot.position - context.charHRP.Position).Magnitude <= MAX_OWNER_DISTANCE then
					state.target, state.targetBoosted, state.targetSince = slot, false, now
				end
			end
		end
	end

	if not state.target then return nil end

	local slot = state.target
	local def = context.definition or {}
	local batch = math.max(1, def.PlantBatch or 1)
	if batch > 1 or def.CastFx then
		-- แม่มดน้อย: ร่ายจากระยะ ปลูกช่องที่เลือก + ช่องว่างใกล้ๆ รวม batch ต้น (หักเมล็ดและนับโควต้าต่อต้นเหมือนปลูกทีละต้น)
		local ctxShared = {}
		local petId = context.petModel and context.petModel:GetAttribute("PetId")
		local preLen = castPreTime(petId and player:GetAttribute("PetLevel_" .. petId) or 1)
		local extras = def.CastFx and setmetatable({
			preTime = preLen,
			onPre = function(ctx, pet)
				ctx.preLen = preLen
				CAST_EXTRAS.onPre(ctx, pet)
			end,
			onWork = function(ctx, pet, duration, workSpot)
				if batch > 1 then
					-- จองช่องที่ 2 ไว้วาดลำแสง (ตอนปลูกจริงเช็กอีกทีว่ายังว่าง)
					local second = nil
					for _, s in ipairs(FarmSlotRegistry.Slots) do
						if s ~= slot and not s.occupied and (s.position - slot.position).Magnitude <= BATCH_NEAR then
							if not second or (s.position - slot.position).Magnitude < (second.position - slot.position).Magnitude then second = s end
						end
					end
					ctxShared.second = second
					ctx.extraSpot = second and second.position or nil
				end
				CAST_EXTRAS.onWork(ctx, pet, duration, workSpot)
			end,
		}, { __index = CAST_EXTRAS }) or EXTRAS
		return slot.position, def.CastReach or REACH_DISTANCE, function(ctx)
			if state.target == slot then state.target = nil end
			local limit = getPlantLimit(player)
			local planted = 0
			if plantOne(player, slot, limit, def, context.petModel) then planted += 1 end
			local last = slot
			while planted > 0 and planted < batch do
				local nextSlot = ctxShared.second
				ctxShared.second = nil
				if not nextSlot or nextSlot.occupied then
					nextSlot = nil
					for _, s in ipairs(FarmSlotRegistry.Slots) do
						if not s.occupied and (s.position - last.position).Magnitude <= BATCH_NEAR then
							if not nextSlot or (s.position - last.position).Magnitude < (nextSlot.position - last.position).Magnitude then nextSlot = s end
						end
					end
				end
				if not plantOne(player, nextSlot, limit, def, context.petModel) then break end
				planted += 1
				last = nextSlot
			end
			return planted > 0 or nil -- ปลูกได้จริง (ใช้คิดความหิว 1 ครั้งต่อการร่าย)
		end, nil, extras
	end
	return slot.position, REACH_DISTANCE, function(ctx)
		if state.target == slot then state.target = nil end

		if slot.occupied then return end

		-- หยิบเมล็ดจากช่อง 1 ก่อน หมดค่อยช่อง 2
		local seeds = PetSeedSlots.GetSeeds(player)
		if #seeds == 0 then return end

		local seed = seeds[1]
		local cropType = seed:GetAttribute("CropType")
		if not cropType or not cropTemplates:FindFirstChild(cropType) then return end

		-- เช็คโควต้าอีกครั้งก่อนปลูกจริง
		if FarmSlotRegistry.CountPlayerPlants(player) >= getPlantLimit(player) then return end

		slot.plantCrop(cropType, player)
		tryPollinate(slot, context.definition, context.petModel)

		-- ลดจำนวนเมล็ด
		local currentCount = seed:GetAttribute("Count") or 1
		if currentCount <= 1 then
			seed:Destroy()
		else
			local newCount = currentCount - 1
			seed:SetAttribute("Count", newCount)
			seed.Name = cropType .. " x" .. newCount
		end
		return true -- ปลูกได้จริง (ใช้คิดความหิว)
	end, nil, EXTRAS -- nil = เวลาก้มฝังตามค่าเริ่มต้น (1 วิ เท่าผู้เล่น)
end

return Planter
