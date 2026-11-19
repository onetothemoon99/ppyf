-- BACKUP 2026-11-20: game.ServerScriptService.QualityBoosterVisual (Script) with x20/EXP/x100 lights at 0.54, before the extra 20% dim
-- Restore: in Studio, paste everything below the "==== SOURCE ====" line into ServerScriptService.QualityBoosterVisual's Source.
-- ==== SOURCE ====
-- QualityBoosterVisual: สร้างวงแหวนแสงหิ่งห้อยรอบ "หุ่นเพิ่มดวง" + Sparkles/แสงทองติดกับตัวหุ่นโดยตรง
-- (ส่วนติดตัวหุ่นใช้สไตล์เดียวกับตอนพืชโตเต็มที่ใน PlantingSystem)
-- แต่ละ Model ใต้ workspace.QualityBoosters ตั้ง Attribute ได้เอง:
--   BoostRadius (number) = รัศมีเป็นสตัด (ค่าเริ่มต้น 15) ต้องตรงกับที่ตั้งไว้ใน PlantingSystem
--   AuraColor   (Color3) = สีเอฟเฟกต์ทั้งหมด (ค่าเริ่มต้น ทอง-เหลือง เหมือนพืชโต 3 ดาว)
--   AuraColor2  (Color3) = ใส่แล้วหิ่งห้อยสลับสองสี AuraColor / AuraColor2 (สกินเทศกาล เช่น ฮาโลวีน ส้ม-ม่วง)
--   SparkleRate (number) = ใส่แล้วประกายรอบตัวหุ่นใช้ ParticleEmitter จำนวนเท่านี้เม็ด/วินาที แทน Sparkles (Sparkles ปรับจำนวนไม่ได้ ออกเยอะ)
--   NoBodyFx    (bool)   = ไม่ใส่ประกายรอบตัวหุ่นเลย (ทั้ง Sparkles และประกายสีรุ้ง) เหลือแค่แสงกับวงหิ่งห้อยบอกรัศมี; BoosterRainbowFx ก็ไม่ใส่เส้นขอบ/ดาววน
--   Rainbow     (bool)   = หิ่งห้อยแต่ละตัวสีไม่ซ้ำกันไล่เป็นสายรุ้ง + ประกายสีรุ้งลอยฟุ้งรอบตัว (หุ่น x100)
--                          สีไล่เปลี่ยนวน เส้นขอบเรืองแสง และดาวลอยวน ทำฝั่งผู้เล่นใน BoosterRainbowFx (ไม่ส่งข้อมูลผ่านเน็ตทุกเฟรม)

local TweenService = game:GetService("TweenService")

local boosters = workspace:FindFirstChild("QualityBoosters")
if not boosters then
	boosters = Instance.new("Folder")
	boosters.Name = "QualityBoosters"
	boosters.Parent = workspace
end

local DEFAULT_RADIUS = 15
local DEFAULT_COLOR = Color3.fromRGB(255, 221, 89) -- ทอง-เหลือง สีเดียวกับออร่าตอนพืชโตเต็มที่ 3 ดาว
local GROUND_LIFT = 1.2 -- ความสูงเฉลี่ยที่หิ่งห้อยลอยอยู่เหนือพื้น
local RADIUS_JITTER = 1.2 -- สุ่มระยะรัศมีเข้า-ออกเล็กน้อย ให้ดูรวมกลุ่มเป็นวงแหวนแบบธรรมชาติ ไม่เป๊ะเป็นเรขาคณิต
local HEIGHT_JITTER = 0.8 -- สุ่มความสูงแต่ละจุดต่างกัน
-- ไฟกลางตัวหุ่นแยกตามระดับ { Brightness, Range } ไม่มีในตาราง = 1.6 / 8 เหมือนเดิม
-- 2026-11-20 ผู้ใช้ขอ: หุ่น x20 (คีย์ x50) ตอนกลางคืนสว่างเป็นวงขาวบนพื้น ลดไฟตัวหุ่น (ไฟหิ่งห้อยดู FIREFLY_LIGHT_BY_TIER)
local BODY_LIGHT_BY_TIER = {
	x50 = { 0.54, 6 }, -- 2026-11-20 ลดอีก 10% (เดิม 0.6)
	xp = { 0.54, 6 }, -- 2026-11-20 หุ่น EXP เท่าหุ่น x20 (เดิม ไฟตัวหุ่น 1.6 / 8, หิ่งห้อย 1.5 / 6)
	x100 = { 0.54, 6 }, -- 2026-11-20 หุ่น x100 เท่าหุ่น x20 (เดิม ไฟตัวหุ่น 1.6 / 8, หิ่งห้อย 1.5 / 6)
}
-- ไฟ PointLight ของหิ่งห้อยแต่ละตัวแยกตามระดับ { Brightness, Range } ไม่มีในตาราง = 1.5 / 6 เหมือนเดิม
-- 2026-11-20 ผู้ใช้ขอ: หุ่น x20 ลดแสงหิ่งห้อยด้วย (ลูกไฟนีออน/ประกายเท่าเดิม)
local FIREFLY_LIGHT_BY_TIER = {
	x50 = { 0.54, 6 }, -- 2026-11-20 ลดอีก 10% (เดิม 0.6)
	xp = { 0.54, 6 }, -- 2026-11-20 หุ่น EXP เท่าหุ่น x20 (เดิม ไฟตัวหุ่น 1.6 / 8, หิ่งห้อย 1.5 / 6)
	x100 = { 0.54, 6 }, -- 2026-11-20 หุ่น x100 เท่าหุ่น x20 (เดิม ไฟตัวหุ่น 1.6 / 8, หิ่งห้อย 1.5 / 6)
}

local activeVisuals = {} -- [model] = {container, tweens={}} เก็บไว้เคลียร์ทิ้งตอน booster ถูกลบ

-- หาตำแหน่งพื้นจริงของโมเดล จากก้น bounding box แทนจุด pivot
local function getGroundPosition(model)
	local cframe, size = model:GetBoundingBox()
	local bottomY = cframe.Position.Y - (size.Y / 2)
	return Vector3.new(cframe.Position.X, bottomY, cframe.Position.Z), cframe, size
end

-- สร้างหิ่งห้อย 1 จุด ที่ตำแหน่งกำหนด พร้อมกระพริบ+ลอยขึ้นลงเบาๆ แบบสุ่มจังหวะไม่พร้อมกัน
local function createFirefly(container, position, color, tierId)
	local bug = Instance.new("Part")
	bug.Name = "Firefly"
	bug.Shape = Enum.PartType.Ball
	bug.Material = Enum.Material.Neon
	bug.Color = color
	bug.Size = Vector3.new(0.2, 0.2, 0.2)
	bug.Transparency = 0.2
	bug.CanCollide = false
	bug.CanQuery = false
	bug.Anchored = true
	bug.CFrame = CFrame.new(position)
	bug.Parent = container

	local light = Instance.new("PointLight")
	light.Color = color
	local fireflyLight = FIREFLY_LIGHT_BY_TIER[tierId]
	light.Range = fireflyLight and fireflyLight[2] or 6
	light.Brightness = fireflyLight and fireflyLight[1] or 1.5
	light.Parent = bug

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(color)
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkle.Lifetime = NumberRange.new(0.6, 1.2)
	sparkle.Rate = 3
	sparkle.Speed = NumberRange.new(0.1, 0.3)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.LightEmission = 1
	sparkle.Parent = bug

	-- กระพริบพร่างๆ (หรี่-สว่างสลับ) จังหวะสุ่มไม่พร้อมกันแต่ละจุด
	local blinkDuration = 0.8 + math.random() * 1.2
	local blinkInfo = TweenInfo.new(blinkDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local blinkTween = TweenService:Create(bug, blinkInfo, { Transparency = 0.75 })
	blinkTween:Play()

	-- ลอยขึ้น-ลงเบาๆ แบบหิ่งห้อยบินโฉบไปมา จังหวะสุ่มไม่พร้อมกันแต่ละจุด
	local floatDuration = 1.5 + math.random() * 1.5
	local floatInfo = TweenInfo.new(floatDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local floatTween = TweenService:Create(bug, floatInfo, {
		CFrame = bug.CFrame * CFrame.new(0, 0.6, 0),
	})
	floatTween:Play()

	return { blinkTween, floatTween }, bug
end

-- Sparkles + PointLight ติดกับตัวหุ่นโดยตรง (สไตล์เดียวกับตอนพืชโตเต็มที่ใน PlantingSystem)
-- ประกายสีรุ้งลอยฟุ้งออกจากตัวหุ่น (หุ่น Rainbow)
local RAINBOW_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 70, 70)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 160, 50)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 235, 60)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(90, 230, 110)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(70, 190, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(90, 110, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(200, 90, 255)),
})

local function attachRainbowSparkles(container, centerPos, size)
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "RainbowSparkles"
	emitterPart.Size = Vector3.new(size.X * 0.9, size.Y * 0.8, size.Z * 0.9)
	emitterPart.Transparency = 1
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.Anchored = true
	emitterPart.CFrame = CFrame.new(centerPos)
	emitterPart.Parent = container

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = RAINBOW_SEQUENCE -- สุ่มสีจากสายรุ้งตามอายุของแต่ละเม็ด เม็ดเดียวไล่ผ่านหลายสี
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = 14
	emitter.Speed = NumberRange.new(0.3, 0.8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, 0.6, 0) -- ลอยขึ้นช้าๆ
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.LightEmission = 1
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.Parent = emitterPart
end

local function attachBodyAura(container, centerPos, color, sparkleRate, noSparkle, tierId)
	local auraPart = Instance.new("Part")
	auraPart.Name = "QualityBoosterAura"
	auraPart.Size = Vector3.new(0.2, 0.2, 0.2)
	auraPart.Transparency = 1
	auraPart.CanCollide = false
	auraPart.CanQuery = false
	auraPart.Anchored = true
	auraPart.CFrame = CFrame.new(centerPos)
	auraPart.Parent = container

	if noSparkle then
		-- ไม่มีประกาย (NoBodyFx)
	elseif sparkleRate then
		-- ประกายแบบบางๆ กำหนดจำนวนได้ (สกินเทศกาล)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SoftSparkles"
		emitter.Color = ColorSequence.new(color)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Lifetime = NumberRange.new(1, 1.6)
		emitter.Rate = sparkleRate
		emitter.Speed = NumberRange.new(1, 2.2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.RotSpeed = NumberRange.new(-60, 60)
		emitter.LightEmission = 1
		emitter.Parent = auraPart
	else
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = auraPart
	end

	local light = Instance.new("PointLight")
	light.Color = color
	local bodyLight = BODY_LIGHT_BY_TIER[tierId]
	light.Range = bodyLight and bodyLight[2] or 8
	light.Brightness = bodyLight and bodyLight[1] or 1.6
	light.Parent = auraPart
end

local function buildAura(model)
	local ok, groundPos, cframe, size = pcall(getGroundPosition, model)
	if not ok then return end

	local radius = model:GetAttribute("BoostRadius") or DEFAULT_RADIUS
	local color = model:GetAttribute("AuraColor") or DEFAULT_COLOR
	local color2 = model:GetAttribute("AuraColor2")
	local rainbow = model:GetAttribute("Rainbow") == true

	local container = Instance.new("Folder")
	container.Name = "QualityBoosterAura"
	container.Parent = model

	local tweens = {}

	-- วงแหวนหิ่งห้อยรอบตัว (เหมือนเดิม)
	local circumference = 2 * math.pi * radius
	local fireflyCount = math.clamp(math.floor(circumference / 3.5), 10, 26)
	if color2 and fireflyCount % 2 == 1 then fireflyCount += 1 end -- จำนวนคู่ สองสีสลับกันลงตัวรอบวง

	for i = 1, fireflyCount do
		local baseAngle = (i / fireflyCount) * math.pi * 2
		local jitteredAngle = baseAngle + math.rad(math.random(-10, 10))
		local jitteredRadius = radius + math.random(-100, 100) / 100 * RADIUS_JITTER
		local jitteredHeight = GROUND_LIFT + math.random(-100, 100) / 100 * HEIGHT_JITTER

		local pos = groundPos + Vector3.new(
			math.cos(jitteredAngle) * jitteredRadius,
			jitteredHeight,
			math.sin(jitteredAngle) * jitteredRadius
		)

		-- หุ่นสายรุ้ง: หิ่งห้อยแต่ละตัวไล่สีรอบวง (ฝั่งผู้เล่นหมุนสีวนต่อเอง)
		local fireflyColor = rainbow and Color3.fromHSV((i - 1) / fireflyCount, 0.75, 1) or ((color2 and i % 2 == 0) and color2 or color)
		local fireflyTweens, bug = createFirefly(container, pos, fireflyColor, model:GetAttribute("BoosterTier"))
		if rainbow then
			bug:SetAttribute("HueOffset", (i - 1) / fireflyCount)
		end
		for _, tween in ipairs(fireflyTweens) do
			table.insert(tweens, tween)
		end
	end

	-- Sparkles/แสงทอง ติดกับตัวหุ่นโดยตรง (ใช้จุดกึ่งกลางจริงของโมเดล ไม่ใช่ลอยสูงเหนือหัว)
	local noBodyFx = model:GetAttribute("NoBodyFx") == true
	attachBodyAura(container, cframe.Position, color, model:GetAttribute("SparkleRate"), noBodyFx, model:GetAttribute("BoosterTier"))
	if rainbow and not noBodyFx then
		attachRainbowSparkles(container, cframe.Position, size)
	end

	activeVisuals[model] = { container = container, tweens = tweens }
end

local function removeAura(model)
	local data = activeVisuals[model]
	if not data then return end

	for _, tween in ipairs(data.tweens) do
		tween:Cancel()
	end
	if data.container then
		data.container:Destroy()
	end
	activeVisuals[model] = nil
end

for _, model in ipairs(boosters:GetChildren()) do
	if model:IsA("Model") then
		buildAura(model)
	end
end

boosters.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		-- รอโมเดลโหลดชิ้นส่วนให้ครบก่อนค่อยหาตำแหน่งจริง
		task.wait(0.6) -- รอให้อนิเมชันตกลงมาปักของ BoosterPlacementSystem (0.4 วินาที) เสร็จก่อน ไม่งั้นออร่าจะไปคำนวณตำแหน่งตอนโมเดลยังลอยอยู่
		buildAura(child)
	end
end)

boosters.ChildRemoved:Connect(function(child)
	removeAura(child)
end)
