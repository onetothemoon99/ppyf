-- BACKUP 2026-11-20: game.StarterPlayer.StarterPlayerScripts.SunBeeAuraFx (LocalScript) before the Phoenix grip/bird lights were set to 0.43 / 6
-- Restore: in Studio, paste everything below the "==== SOURCE ====" line into StarterPlayerScripts.SunBeeAuraFx's Source.
-- ==== SOURCE ====
-- SunBeeAuraFx: ออร่ารอบตัวคนที่ถือเบ็ดพิเศษ ทุกคนเห็น ทำบนเครื่องผู้เล่นแต่ละคน ไม่ใช้เซิร์ฟเวอร์ (2026-10-08)
--   เบ็ดผึ้งน้อย (RodId SunBee) = โทนทอง + กลีบทานตะวันปลิว / เบ็ดผีเสื้อ (RodId NightMoth) = โทนม่วง + ผีเสื้อบิน (เพิ่ม 2026-10-08 ผู้เล่นขอ)
--   วงเวทใต้เท้า 2 ชั้น (หมุนสวนกัน) + รัศมีแสงด้านหลังตัว + ละอองลอยขึ้น + ของปลิว (กลีบ/ผีเสื้อ)
--   + ทำให้ไฮไลต์/แสงที่คันเบ็ด (FishingSystem ใส่ไว้) เต้นเป็นจังหวะหายใจ
-- อยู่ไกลกล้องเกิน VIEW_DISTANCE = ซ่อน

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GraphicsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("GraphicsConfig"))
local PhoenixFlight = require(game:GetService("ReplicatedStorage"):WaitForChild("PhoenixFlight")) -- 2026-11-20 นกฟีนิกซ์เกาะไหล่ บินเป็นพักๆ
local PHOENIX_PERCH = Vector3.new(1.05, 1.55, 0.25) -- ไหล่ขวา (เทียบ HumanoidRootPart: x ขวา y บน z หลัง)

local TEX_CIRCLE = "rbxassetid://128255122232475"
local TEX_SUNBURST = "rbxassetid://140103725080553"
local TEX_DOT = "rbxassetid://100881846134039"
local VIEW_DISTANCE = 160
local CIRCLE_SIZE = 8 -- studs

-- dim = ตัวคูณความสว่างของออร่าทั้งชุด (1 = เต็ม) ผึ้งน้อย 0.85 = ลดแสงลง 15% (ผู้เล่นขอ 2026-10-11)
local STYLES = {
	SunBee = {
		dim = 0.549, -- 0.85 x 0.85 x 0.95 (ลด 15% สองรอบ แล้วอีก 5% วันเดียวกัน) x 0.8 (ลดอีก 20% ผู้เล่นขอ 2026-11-16)
		circle = Color3.fromRGB(255, 205, 70), rays = Color3.fromRGB(255, 255, 255),
		moteA = Color3.fromRGB(255, 245, 170), moteB = Color3.fromRGB(255, 185, 40),
		drift = "rbxassetid://91306079180953", driftFlipbook = false, driftSize = 0.32,
		highlight = "SunBeeAura", light = "SunBeeAuraGold", lightBase = 1.6, lightAmp = 1.4, range = 10, headHalo = false,
	},
	-- 2026-11-19 เบ็ดฟีนิกซ์ (ผู้ใช้สั่ง): วงเวทเปลวไฟ (ไฟลุกรอบขอบวง flameRing) + ประกายไฟลอยขึ้นเร็ว + ขนนกไฟร่วงลงมาจากเหนือหัว (driftFall)
	--   ไม่มีไฮไลต์ที่คัน (กันช่อง Highlight 255 เต็ม) แสง PhoenixAuraFire อยู่ในเทมเพลต Rod_Phoenix.Grip ขนนก = รูปจาก art/phoenix_rod/make_feather.py
	Phoenix = {
		dim = 0.75,
		circle = Color3.fromRGB(255, 120, 40), rays = Color3.fromRGB(255, 200, 120),
		moteA = Color3.fromRGB(255, 235, 150), moteB = Color3.fromRGB(255, 70, 20),
		moteRate = 40, moteSpeed = NumberRange.new(2.5, 5), moteSize = 0.12,
		drift = "rbxassetid://79532410767899", driftFlipbook = false, driftSize = 0.45, driftFall = false, -- ขนนกร่วงย้ายไปออกจากตัวนก (BirdFeathers) 2026-11-19
		-- 2026-11-19 ผู้ใช้สั่ง "ไม่เอาออร่าที่เท้า": ไม่มีวงเวท (noCircle) และไฟรอบวง (flameRing = false) เหลือประกายไฟลอยขึ้น + ขนนกไฟร่วง · เปิดคืน = flameRing = true + ลบ noCircle
		flameRing = false, noCircle = true,
		-- 2026-11-19 ผู้ใช้สั่ง: นกฟีนิกซ์ไฟ 3D บินวนรอบตัว (bird = เทมเพลต ReplicatedStorage.PhoenixFx.Bird, ปีกกระพือ ไฟลากตาม สลัดขนนกร่วงแทน driftFall)
		--   + ออร่าเปลวไฟคลุมตัว (bodyFlames ไฟบางๆ ลุกจากลำตัว ไม่ใช่ที่เท้า) · noDrift = ไม่ปล่อยขนนกจากแผ่นเหนือหัวแล้ว
		bird = true, bodyFlames = true, noDrift = true,
		highlight = "PhoenixNoHighlight", light = "PhoenixAuraFire", lightBase = 1.0, lightAmp = 1.2, range = 9, headHalo = false,
	},
	-- 2026-11-19 เบ็ดกบน้อย (ผู้ใช้สั่ง ให้สู้เบ็ดผีเสื้อได้): ไม่มีออร่าที่เท้า (เบ็ด 99 R$) · แมลงปอ 3D บินวนแบบพุ่ง-หยุดค้าง (critter + dart)
	--   หิ่งห้อยกระพริบลอยขึ้น (motes + moteFlicker) · กลีบบัวชมพูร่วงจากเหนือหัว (driftFall + driftColor) · กบที่ด้ามพองคอร้อง + โน้ตเพลง (throatPuff)
	--   ฟองสบู่สีรุ้ง / แสงปลายคัน / โน้ต อยู่ในเทมเพลต Rod_Froggy เอง · รูปจาก art/frog_rod/make_fx_textures.py
	Froggy = {
		dim = 0.9,
		circle = Color3.fromRGB(150, 230, 110), rays = Color3.fromRGB(220, 255, 200),
		moteA = Color3.fromRGB(235, 255, 150), moteB = Color3.fromRGB(150, 240, 90),
		moteRate = 20, moteSpeed = NumberRange.new(0.3, 0.9), moteSize = 0.22, moteLife = NumberRange.new(2.5, 4), moteFlicker = true, moteBright = 3,
		bodyLight = { Color3.fromRGB(150, 255, 130), 3.4, 10 }, -- แสงเขียวอ่อนคลุมตัวคนถือ (แทน Highlight ที่เบ็ดผีเสื้อใช้) ปิดเองตอนกราฟิก LightsOff
		-- 2026-11-19 ผู้ใช้สั่ง: เอาแมลงปอบินวน + กลีบดอกไม้ร่วงออก (เก็บไว้ทำเบ็ดแมลงปอน้อย: critter = { "FrogFx", "Dragonfly" }, dart = true / driftFall + driftColor + รูป 116162051621497)
		drift = "rbxassetid://116162051621497", driftFlipbook = false, driftSize = 0.32, noDrift = true,
		flameRing = false, noCircle = true,
		throatPuff = true,
		highlight = "FrogNoHighlight", light = "FrogGlow", lightBase = 0.7, lightAmp = 0.5, range = 7, headHalo = false,
	},
	-- NightMoth ปิด 2026-10-08 (ผู้เล่นขอ: เบ็ดผีเสื้อไม่มีออร่าใต้เท้า) เปิดคืน = ลบ "-- " หน้าบรรทัดข้างล่าง
	-- 	NightMoth = {
	-- 		circle = Color3.fromRGB(175, 120, 255), rays = Color3.fromRGB(215, 185, 255),
	-- 		moteA = Color3.fromRGB(240, 225, 255), moteB = Color3.fromRGB(160, 100, 255),
	-- 		drift = "rbxassetid://137826566831606", driftFlipbook = true, driftSize = 0.42,
	-- 		highlight = "NightMothGripAura", light = "NightMothAuraPurple", lightBase = 1.8, lightAmp = 1.2, range = 9,
	-- 	},
}

local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local fxByCharacter = {} -- [character] = fx

local function heldAuraRod(character)
	local tool = character and character:FindFirstChildOfClass("Tool")
	local rodId = tool and tool:GetAttribute("RodId")
	if rodId and STYLES[rodId] then return tool, rodId end
	return nil
end

local function makeFx(character, root, rodId)
	local style = STYLES[rodId]
	local dim = style.dim or 1
	local folder = Instance.new("Folder")
	folder.Name = "RodAuraFx_" .. rodId
	folder.Parent = workspace

	-- แผ่นพื้น (มองไม่เห็น) ถือวงเวท + เป็นจุดปล่อยละออง
	local pad = Instance.new("Part")
	pad.Name = "CirclePad"
	pad.Anchored, pad.CanCollide, pad.CanQuery, pad.CanTouch, pad.CastShadow = true, false, false, false, false
	pad.Transparency = 1
	pad.Size = Vector3.new(CIRCLE_SIZE, 0.05, CIRCLE_SIZE)
	pad.Parent = folder
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Top
	surface.LightInfluence = 0
	surface.Brightness = 1.1 * dim -- สว่างกว่านี้ลายวงเวทจะกลายเป็นก้อนแสงเบลอ (bloom)
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 64
	surface.Adornee = pad
	surface.Parent = pad
	local function circleImage(scale, transparency)
		local img = Instance.new("ImageLabel")
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.Size = UDim2.fromScale(scale, scale)
		img.BackgroundTransparency = 1
		img.Image = TEX_CIRCLE
		img.ImageColor3 = style.circle
		img.ImageTransparency = transparency
		img.Parent = surface
		return img
	end
	local outer = circleImage(1, 0.1)
	local inner = circleImage(0.62, 0.25)

	-- ละอองลอยขึ้นจากวง + ของปลิว (กลีบทานตะวัน / ผีเสื้อ)
	local motes = Instance.new("ParticleEmitter")
	motes.Name = "RisingMotes"
	motes.Texture = TEX_DOT
	motes.Shape, motes.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	motes.EmissionDirection = Enum.NormalId.Top
	motes.Rate = style.moteRate or 30
	motes.Lifetime = style.moteLife or NumberRange.new(1.4, 2.6)
	motes.Speed = style.moteSpeed or NumberRange.new(1.2, 2.8)
	motes.SpreadAngle = Vector2.new(6, 6)
	motes.Drag = 0.6
	motes.Size = NS({ NK(0, 0), NK(0.2, style.moteSize or 0.16, 0.06), NK(1, 0) })
	motes.Transparency = style.moteFlicker and NS({ NK(0, 1), NK(0.12, 0.05), NK(0.3, 0.75), NK(0.48, 0.05), NK(0.66, 0.7), NK(0.82, 0.1), NK(1, 1) })
		or NS({ NK(0, 0.1), NK(0.8, 0.2), NK(1, 1) }) -- moteFlicker = กระพริบแบบหิ่งห้อย
	motes.Color = ColorSequence.new(style.moteA, style.moteB)
	motes.LightEmission, motes.LightInfluence, motes.Brightness = 1, 0, (style.moteBright or 2) * dim
	motes.Parent = pad
	local drift = Instance.new("ParticleEmitter")
	drift.Name = "Drift"
	drift.Texture = style.drift
	if style.driftFlipbook then
		drift.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
		drift.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		drift.FlipbookFramerate = NumberRange.new(10, 14)
		drift.FlipbookStartRandom = true
		drift.Rotation = NumberRange.new(-20, 20)
		drift.RotSpeed = NumberRange.new(-15, 15)
		drift.LightEmission = 0.7
	else
		drift.Rotation = NumberRange.new(0, 360)
		drift.RotSpeed = NumberRange.new(-90, 90)
		drift.LightEmission = 0.3
	end
	drift.Shape, drift.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	drift.EmissionDirection = Enum.NormalId.Top
	drift.Rate = 3
	drift.Lifetime = NumberRange.new(3, 5)
	drift.Speed = NumberRange.new(0.6, 1.4)
	drift.SpreadAngle = Vector2.new(30, 30)
	drift.Acceleration = Vector3.new(0.35, -0.08, 0.15)
	drift.Drag = 0.3
	drift.Size = NS({ NK(0, 0), NK(0.15, style.driftSize, 0.08), NK(0.85, style.driftSize, 0.08), NK(1, 0) })
	drift.Transparency = NS({ NK(0, 1), NK(0.1, 0), NK(0.85, 0.1), NK(1, 1) })
	drift.LightInfluence = 0.2
	if style.driftColor then drift.Color = ColorSequence.new(style.driftColor) end
	drift.Parent = pad
	if style.noDrift then drift.Enabled = false end
	-- นกฟีนิกซ์บินวน (เทมเพลตอยู่ที่จุดกำเนิด เก็บ CFrame ของแต่ละชิ้นเทียบ Root ไว้ แล้ววางใหม่ทุกเฟรม)
	local bird
	local critter = style.critter or (style.bird and { "PhoenixFx", "Bird" }) -- สัตว์บินวน = { โฟลเดอร์ใน ReplicatedStorage, ชื่อโมเดล }
	local birdTemplate = critter and game:GetService("ReplicatedStorage"):FindFirstChild(critter[1])
	birdTemplate = birdTemplate and birdTemplate:FindFirstChild(critter[2])
	if birdTemplate then
		local model = birdTemplate:Clone()
		model.Parent = folder
		bird = { model = model, root = model.PrimaryPart, parts = {},
			sL = model:GetAttribute("ShoulderL") or Vector3.new(-0.12, 0.08, -0.04), sR = model:GetAttribute("ShoulderR") or Vector3.new(0.12, 0.08, -0.04),
			phase = math.random() * math.pi * 2 }
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") then table.insert(bird.parts, { part = p, rel = p.CFrame, piece = p:GetAttribute("Piece") or "Root" }) end
		end
	end
	-- แสงคลุมตัว (bodyLight = { สี, ความสว่าง, ระยะ }) ไม่ใช่ Highlight · กราฟิกที่ปิดไฟ (LightsOff) = ไม่สร้าง
	local glowBox, glowLight
	if style.bodyLight and not GraphicsConfig.Get(Players.LocalPlayer:GetAttribute(GraphicsConfig.ATTRIBUTE)).LightsOff then
		glowBox = Instance.new("Part")
		glowBox.Name = "BodyGlow"
		glowBox.Anchored, glowBox.CanCollide, glowBox.CanQuery, glowBox.CanTouch, glowBox.CastShadow = true, false, false, false, false
		glowBox.Transparency = 1
		glowBox.Size = Vector3.new(0.2, 0.2, 0.2)
		glowBox.Parent = folder
		glowLight = Instance.new("PointLight")
		glowLight.Color, glowLight.Brightness, glowLight.Range, glowLight.Shadows = style.bodyLight[1], style.bodyLight[2] * dim, style.bodyLight[3], false
		glowLight.Parent = glowBox
	end
	-- ออร่าเปลวไฟคลุมตัว: กล่องล่องหนขนาดลำตัว ปล่อยไฟบางๆ ลอยขึ้น (ตามตัวทุกเฟรม)
	local bodyBox, bodyFire
	if style.bodyFlames then
		bodyBox = Instance.new("Part")
		bodyBox.Name = "BodyFlames"
		bodyBox.Anchored, bodyBox.CanCollide, bodyBox.CanQuery, bodyBox.CanTouch, bodyBox.CastShadow = true, false, false, false, false
		bodyBox.Transparency = 1
		bodyBox.Size = Vector3.new(1.9, 2.6, 1.1)
		bodyBox.Parent = folder
		bodyFire = Instance.new("ParticleEmitter")
		bodyFire.Name = "BodyFire"
		bodyFire.Texture = "rbxasset://textures/particles/fire_main.dds"
		bodyFire.Shape, bodyFire.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
		bodyFire.EmissionDirection = Enum.NormalId.Top
		bodyFire.Rate = 32
		bodyFire.Lifetime = NumberRange.new(0.4, 0.7)
		bodyFire.Speed = NumberRange.new(1, 2)
		bodyFire.SpreadAngle = Vector2.new(8, 8)
		bodyFire.Rotation = NumberRange.new(-20, 20)
		bodyFire.Size = NS({ NK(0, 0.7, 0.15), NK(0.6, 0.45), NK(1, 0.1) })
		bodyFire.Transparency = NS({ NK(0, 0.35), NK(0.7, 0.6), NK(1, 1) })
		bodyFire.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 90)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 110, 30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 20)) })
		bodyFire.LightEmission, bodyFire.LightInfluence, bodyFire.Brightness = 1, 0, 1.3 * dim
		bodyFire.Parent = bodyBox
	end
	-- ขนนกไฟร่วง (ฟีนิกซ์): ปล่อยจากแผ่นล่องหนเหนือหัว ตกลงช้าๆ หมุนพลิ้ว
	local fallPad
	if style.driftFall then
		fallPad = Instance.new("Part")
		fallPad.Name = "FallPad"
		fallPad.Anchored, fallPad.CanCollide, fallPad.CanQuery, fallPad.CanTouch, fallPad.CastShadow = true, false, false, false, false
		fallPad.Transparency = 1
		fallPad.Size = Vector3.new(6, 0.05, 6)
		fallPad.Parent = folder
		drift.EmissionDirection = Enum.NormalId.Bottom
		drift.Rate = 4
		drift.Lifetime = NumberRange.new(3, 4.5)
		drift.Speed = NumberRange.new(0.3, 0.8)
		drift.SpreadAngle = Vector2.new(20, 20)
		drift.Acceleration = Vector3.new(0.2, -0.9, 0.1)
		drift.Drag = 0.8
		drift.Rotation = NumberRange.new(0, 360)
		drift.RotSpeed = NumberRange.new(-120, 120)
		drift.LightEmission = 0.6
		drift.Brightness = 1.5 * dim
		drift.Parent = fallPad
	end
	-- ไฟลุกรอบขอบวงเวท (ฟีนิกซ์): จุดไฟ 12 จุดรอบขอบวง (Shape Disc/Cylinder บนแผ่นบาง ไม่ขึ้นเป็นวง ทดสอบ 2026-11-19)
	local flames
	if style.flameRing then
		flames = {}
		local base = Instance.new("ParticleEmitter")
		base.Name = "FlameRing"
		base.Texture = "rbxasset://textures/particles/fire_main.dds"
		base.EmissionDirection = Enum.NormalId.Top
		base.Rate = 7
		base.Lifetime = NumberRange.new(0.45, 0.85)
		base.Speed = NumberRange.new(1.5, 2.8)
		base.SpreadAngle = Vector2.new(5, 5)
		base.Rotation = NumberRange.new(-15, 15)
		base.Size = NS({ NK(0, 0.9, 0.2), NK(0.6, 0.6), NK(1, 0.1) })
		base.Transparency = NS({ NK(0, 0.15), NK(0.7, 0.4), NK(1, 1) })
		base.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 100)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 110, 30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 20)) })
		base.LightEmission, base.LightInfluence, base.Brightness = 1, 0, 2 * dim
		for i = 1, 12 do
			local ang = i / 12 * math.pi * 2
			local at = Instance.new("Attachment")
			at.Name = "FlameAt"
			at.Position = Vector3.new(math.cos(ang) * CIRCLE_SIZE * 0.45, 0.05, math.sin(ang) * CIRCLE_SIZE * 0.45)
			at.Parent = pad
			local e = base:Clone()
			e.Parent = at
			table.insert(flames, e)
		end
		base:Destroy()
	end

	-- รัศมีแสงด้านหลังตัว (ป้ายหันหากล้อง เลื่อนไปด้านหลังตัวละคร)
	local halo = Instance.new("BillboardGui")
	halo.Name = "RodHalo"
	halo.Enabled = style.headHalo ~= false
	halo.Size = UDim2.fromScale(9, 9)
	halo.StudsOffset = Vector3.new(0, 0.9, -1.6)
	halo.LightInfluence = 0
	halo.Brightness = 1.6 * dim
	halo.MaxDistance = VIEW_DISTANCE
	halo.Adornee = root
	halo.Parent = folder
	local rays = Instance.new("ImageLabel")
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.Size = UDim2.fromScale(1, 1)
	rays.BackgroundTransparency = 1
	rays.Image = TEX_SUNBURST
	rays.ImageColor3 = style.rays
	rays.ImageTransparency = 0.35
	rays.Parent = halo
	local rays2 = rays:Clone()
	rays2.Size = UDim2.fromScale(0.7, 0.7)
	rays2.ImageTransparency = 0.5
	rays2.Parent = halo

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, folder }
	params.IgnoreWater = false
	return { rodId = rodId, style = style, folder = folder, pad = pad, outer = outer, inner = inner, rays = rays, rays2 = rays2, motes = motes, drift = drift, params = params, root = root, fallPad = fallPad, flames = flames, bird = bird, bodyBox = bodyBox, bodyFire = bodyFire, glowBox = glowBox, glowLight = glowLight }
end

local function removeFx(character)
	local fx = fxByCharacter[character]
	if fx then
		fx.folder:Destroy()
		fxByCharacter[character] = nil
	end
end

-- หาใครถืออยู่ (เช็กทุก 0.25 วิ พอ) เปลี่ยนเบ็ดกลางทาง = สร้างเอฟเฟกต์ใหม่ตามสีของเบ็ด
local checkTimer = 0
local function refresh()
	-- กราฟิกต่ำสุด (FxOff) = ไม่วาดออร่าที่เท้าของใครเลยบนเครื่องนี้ (ผู้เล่นขอ 2026-10-11) เปลี่ยนระดับกลับ = ขึ้นคืนใน 0.25 วิ
	if GraphicsConfig.Get(Players.LocalPlayer:GetAttribute(GraphicsConfig.ATTRIBUTE)).FxOff then
		for character in pairs(fxByCharacter) do removeFx(character) end
		return
	end
	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local character = plr.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local tool, rodId = heldAuraRod(character)
		if root and tool then
			seen[character] = true
			local fx = fxByCharacter[character]
			if fx and fx.rodId ~= rodId then removeFx(character) fx = nil end
			if not fx then fxByCharacter[character] = makeFx(character, root, rodId) end
		end
	end
	for character in pairs(fxByCharacter) do
		if not seen[character] or not character.Parent then removeFx(character) end
	end
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	checkTimer += dt
	if checkTimer >= 0.25 then
		checkTimer = 0
		refresh()
	end
	local camPos = workspace.CurrentCamera.CFrame.Position
	local breathe = 0.5 + 0.5 * math.sin(t * 2.2)
	for character, fx in pairs(fxByCharacter) do
		local root = fx.root
		if not root.Parent then removeFx(character) continue end
		local near = (root.Position - camPos).Magnitude <= VIEW_DISTANCE
		fx.motes.Enabled = near
		fx.drift.Enabled = near and not fx.style.noDrift
		if fx.bodyBox then
			fx.bodyBox.CFrame = root.CFrame
			fx.bodyFire.Enabled = near
		end
		if fx.glowBox then
			fx.glowBox.CFrame = root.CFrame + Vector3.new(0, 0.6, 0)
			fx.glowLight.Enabled = near
			fx.glowLight.Brightness = fx.style.bodyLight[2] * (fx.style.dim or 1) * (0.75 + 0.35 * breathe)
		end
		-- นกฟีนิกซ์: วนรอบตัว r ~3 รอบละ ~4 วิ ขึ้นลงเป็นคลื่น นานๆ ทีโฉบขึ้นเหนือหัว เอียงตัวเข้าหากลางวง ปีกกระพือ
		local b = fx.bird
		if b and b.root.Parent then
			for _, child in ipairs(b.root:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Trail") then child.Enabled = near end
			end
			if near and not fx.style.dart then
				-- 2026-11-20 นกฟีนิกซ์: เกาะไหล่เป็นส่วนใหญ่ บินออกทุก 15-25 วิ ท่าสุ่มไม่ซ้ำ (ReplicatedStorage.PhoenixFlight) · เดิมวนรอบตัวตลอด ผู้ใช้บอกมึนหัว
				local cf, flap = PhoenixFlight.Step(b, root.Position, root.CFrame.LookVector, camPos, t + b.phase, PHOENIX_PERCH, 1)
				local wingL = cf * CFrame.new(b.sL) * CFrame.Angles(0, 0, flap) * CFrame.new(-b.sL)
				local wingR = cf * CFrame.new(b.sR) * CFrame.Angles(0, 0, -flap) * CFrame.new(-b.sR)
				for _, e in ipairs(b.parts) do
					local base = (e.piece == "WingL" and wingL) or (e.piece == "WingR" and wingR) or cf
					e.part.CFrame = base * e.rel
				end
			elseif near then
				local tt = t + b.phase
				local pos, a
				if fx.style.dart then
					-- แมลงปอ: ความเร็วเป็นจังหวะ 1.6 x (1 + cos) = หยุดค้างแวบหนึ่งแล้วพุ่งต่อ วงกว้าง/แคบสลับ ระดับไหล่ถึงหัว
					a = tt * 1.6 + (1.6 / 1.3) * math.sin(tt * 1.3)
					local r = 2.9 + 0.45 * math.sin(tt * 0.8)
					pos = root.Position + Vector3.new(math.cos(a) * r, 1.8 + 0.3 * math.sin(tt * 3.1) + 0.25 * math.sin(tt * 0.5), math.sin(a) * r)
				else
					local swoop = math.max(0, math.sin(tt * 0.7)) ^ 6 * 2.2
					a = tt * 1.55
					local r = 3.4 - swoop * 0.5
					pos = root.Position + Vector3.new(math.cos(a) * r, 1.4 + 0.35 * math.sin(tt * 2.3) + swoop, math.sin(a) * r)
				end
				local dir = b.prev and (pos - b.prev) or Vector3.new(-math.sin(a), 0, math.cos(a))
				if dir.Magnitude < 1e-3 then dir = b.lastDir or Vector3.new(-math.sin(a), 0, math.cos(a)) end -- หยุดค้าง = หันทางเดิม
				b.lastDir = dir
				b.prev = pos
				local toCenter = (root.Position - pos) * Vector3.new(1, 0, 1)
				toCenter = toCenter.Magnitude > 1e-3 and toCenter.Unit or Vector3.zero
				local up = (Vector3.yAxis + toCenter * 0.45).Unit
				local cf = CFrame.lookAt(pos, pos + dir.Unit, up)
				local flap = fx.style.dart and (math.sin(tt * 45) * 0.35) or (math.sin(tt * 11) * 0.6 + 0.1) -- แมลงปอกระพือเร็ว มุมแคบ
				local wingL = cf * CFrame.new(b.sL) * CFrame.Angles(0, 0, flap) * CFrame.new(-b.sL)
				local wingR = cf * CFrame.new(b.sR) * CFrame.Angles(0, 0, -flap) * CFrame.new(-b.sR)
				for _, e in ipairs(b.parts) do
					local base = (e.piece == "WingL" and wingL) or (e.piece == "WingR" and wingR) or cf
					e.part.CFrame = base * e.rel
				end
			end
		end
		-- วงเวทวางบนพื้นใต้เท้า (ยิงลงหาพื้น/น้ำ) กระโดดแล้ววงยังอยู่ที่พื้น
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), fx.params)
		if hit and near then
			fx.pad.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.06, 0))
			local showCircle = not fx.style.noCircle
			fx.outer.Visible, fx.inner.Visible = showCircle, showCircle
			if fx.flames then for _, e in ipairs(fx.flames) do e.Enabled = true end end
		else
			fx.outer.Visible, fx.inner.Visible = false, false
			if fx.flames then for _, e in ipairs(fx.flames) do e.Enabled = false end end
		end
		if fx.fallPad then fx.fallPad.CFrame = CFrame.new(root.Position + Vector3.new(0, 4.5, 0)) end
		-- กบที่ด้ามเบ็ดพองคอร้องทุก 4.5 วิ (ขยาย Throat บนเครื่องนี้ + ปล่อยโน้ต FrogNotes 2 ตัวต่อรอบ)
		if fx.style.throatPuff and near then
			local rodTool = heldAuraRod(character)
			local throat = rodTool and rodTool:FindFirstChild("Throat")
			local rest = throat and throat:GetAttribute("RestSize")
			if throat and rest then
				local seed = (fx.bird and fx.bird.phase) or 0
				local cycle = math.floor((t + seed) / 4.5)
				local p = (t + seed) % 4.5
				local k = p < 0.8 and (1 + 0.9 * math.sin(math.pi * p / 0.8)) or 1
				throat.Size = rest * k
				if p > 0.35 and fx.puffCycle ~= cycle then
					fx.puffCycle = cycle
					local notes = throat:FindFirstChild("FrogNotes")
					if notes then notes:Emit(2) end
				end
			end
		end
		fx.outer.Rotation = (t * 18) % 360
		fx.inner.Rotation = (-t * 32) % 360
		fx.outer.ImageTransparency = 0.05 + 0.2 * (1 - breathe)
		fx.inner.ImageTransparency = 0.2 + 0.2 * breathe
		fx.rays.Rotation = (t * 8) % 360
		fx.rays2.Rotation = (-t * 14) % 360
		fx.rays.ImageTransparency = 0.3 + 0.2 * (1 - breathe)
		fx.rays2.ImageTransparency = 0.45 + 0.2 * breathe
		-- คันเบ็ด: ไฮไลต์/แสงเต้นเป็นจังหวะ (ค่าบนเครื่องนี้เท่านั้น)
		local tool = heldAuraRod(character)
		if tool then
			local style = fx.style
			local dim = style.dim or 1 -- ลดแสง = ไฮไลต์จางลง + ไฟหรี่ลงตามสัดส่วน
			local aura = tool:FindFirstChild(style.highlight)
			if aura and aura:IsA("Highlight") then
				aura.FillTransparency = 1 - (0.32 - 0.18 * (1 - breathe)) * dim
				aura.OutlineTransparency = 1 - (0.95 - 0.25 * (1 - breathe)) * dim
			end
			local grip = tool:FindFirstChild("Grip", true)
			local light = grip and grip:FindFirstChild(style.light)
			if light then light.Brightness = (style.lightBase + style.lightAmp * breathe) * dim light.Range = style.range + 4 * breathe end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if plr.Character then removeFx(plr.Character) end
end)
