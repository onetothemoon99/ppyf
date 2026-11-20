-- BACKUP 2026-11-21 of ServerScriptService.MountSystem.MountService (Script) before adding FollowPart welds for the flamingo. Restore: paste everything below this line into that script's Source.
-- MountService: ขึ้นขี่ / ลงจากสัตว์ขี่ (2026-10-15)
-- RemoteFunction RemoteEvents.MountRequest(action, mountId):
--   "ride"     = เลือกตัวนั้น (ต้องมี) แล้วขึ้นขี่ (ขี่ตัวอื่นอยู่ = เปลี่ยนตัว)
--   "toggle"   = ขี่อยู่ = ลง / ไม่ได้ขี่ = ขึ้นตัวที่เลือกไว้ (ยังไม่เลือก = ตัวแรกที่มี)
--   "dismount" = ลง
-- วิธีติด: โมเดลสัตว์เชื่อม (Weld) ใต้ HumanoidRootPart + ยก Humanoid.HipHeight ให้ตัวละครลอยอยู่บนหลัง
--   ส่วนของสัตว์ไม่ชน/ไม่มีน้ำหนัก ตัวละครยังเดินเองตามปกติ (ฟิสิกส์ฝั่งผู้เล่นเหมือนเดิม)
--   ท่านั่ง / ความเร็ว / แรงกระโดด ทำฝั่งผู้เล่น (MountClient + SprintController อ่าน Attribute ด้านล่าง)
-- โมเดล: ServerStorage.MountTemplates.<mountId> (Model ที่มี PrimaryPart "MountRoot" อยู่กลางพื้นใต้เท้า หน้าหัน -Z,
--   Attribute SeatHeight = ความสูงหลังจากพื้น) ยังไม่มี = สร้างตัวชั่วคราวจากบล็อก (ขั้นที่ 5 จะใส่โมเดลจริง)
-- Attribute บนผู้เล่น: RidingMount = mountId หรือ nil, MountSpeed, MountJump
-- ลงเองอัตโนมัติ: ตาย / เกิดใหม่ / ออกเกม / นั่งเก้าอี้ (Humanoid.Sit) / โมเดลหาย
-- ระบบอื่นสั่งลงได้: BindableEvent ServerStorage.MountDismount:Fire(player)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MountConfig = require(ReplicatedStorage:WaitForChild("MountConfig"))
local MountOwnership = require(script.Parent:WaitForChild("MountOwnership"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local request = remoteEvents:FindFirstChild("MountRequest")
if not request then
	request = Instance.new("RemoteFunction")
	request.Name = "MountRequest"
	request.Parent = remoteEvents
end
local dismountEvent = ServerStorage:FindFirstChild("MountDismount")
if not dismountEvent then
	dismountEvent = Instance.new("BindableEvent")
	dismountEvent.Name = "MountDismount"
	dismountEvent.Parent = ServerStorage
end

local REQUEST_COOLDOWN = 0.5
local RIDER_LIFT = 0.05 -- ท่าคร่อมหลัง (MountFx): ก้น = HRP ล่าง ให้แนบหลังสัตว์ (เดิม 0.3 ตอนใช้ท่านั่งเก้าอี้)

local riding = {} -- [player] = { model, weld, humanoid, hipHeight, conns }
local lastRequest = {}

-- ============ ตัวชั่วคราว (ก่อนมีโมเดลจริง) ============
local PLACEHOLDER_COLORS = {
	CalmTurtle = { Color3.fromRGB(120, 180, 100), Color3.fromRGB(150, 110, 70) },
	FluffyBunny = { Color3.fromRGB(250, 250, 250), Color3.fromRGB(255, 190, 210) },
	CloudSheep = { Color3.fromRGB(240, 240, 255), Color3.fromRGB(190, 180, 230) },
	WildHorse = { Color3.fromRGB(140, 90, 55), Color3.fromRGB(60, 40, 30) },
	ChillCapybara = { Color3.fromRGB(170, 120, 80), Color3.fromRGB(255, 170, 60) },
	SakuraDeer = { Color3.fromRGB(210, 160, 120), Color3.fromRGB(255, 170, 200) },
	RainbowUnicorn = { Color3.fromRGB(250, 250, 255), Color3.fromRGB(255, 150, 220) },
	WitchCatBroom = { Color3.fromRGB(120, 80, 50), Color3.fromRGB(140, 80, 200) },
}

local function part(model, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = model
	return p
end

local function buildPlaceholder(mountId)
	local colors = PLACEHOLDER_COLORS[mountId] or { Color3.fromRGB(200, 200, 200), Color3.fromRGB(120, 120, 120) }
	local main, accent = colors[1], colors[2]
	local model = Instance.new("Model")
	model.Name = mountId
	local root = part(model, "MountRoot", Vector3.new(1, 0.2, 1), CFrame.new(0, 0.1, 0), main)
	root.Transparency = 1
	model.PrimaryPart = root
	-- -Z = หน้า
	part(model, "Body", Vector3.new(2.2, 1.6, 3.4), CFrame.new(0, 2.2, 0), main)
	part(model, "Head", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 3.2, -2), main)
	part(model, "Nose", Vector3.new(0.8, 0.6, 0.4), CFrame.new(0, 2.9, -2.8), accent)
	part(model, "EarL", Vector3.new(0.3, 0.7, 0.3), CFrame.new(-0.45, 4.1, -2), accent)
	part(model, "EarR", Vector3.new(0.3, 0.7, 0.3), CFrame.new(0.45, 4.1, -2), accent)
	part(model, "Saddle", Vector3.new(2.3, 0.25, 1.6), CFrame.new(0, 3.1, 0.2), accent)
	for _, x in ipairs({ -0.7, 0.7 }) do
		for _, z in ipairs({ -1.2, 1.2 }) do
			part(model, "Leg", Vector3.new(0.5, 1.5, 0.5), CFrame.new(x, 0.75, z), main)
		end
	end
	part(model, "Tail", Vector3.new(0.4, 0.4, 0.8), CFrame.new(0, 2.6, 2), accent)
	model:SetAttribute("SeatHeight", 3.2)
	model:SetAttribute("Placeholder", true)
	return model
end

local addEffects -- ด้านล่าง
-- ============ เอฟเฟกต์ประจำตัว (ทุกคนเห็น) ตัวปล่อยชื่อ "MountFx" เปิด/ปิดตามการเดินโดย MountFx ฝั่งผู้เล่น ============
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local function emitter(parent, colors, rate, size, speed, lifetime, accel)
	local e = Instance.new("ParticleEmitter")
	e.Name = "MountFx"
	e.Texture = SPARKLE
	e.Color = colors
	e.Rate = rate
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.Lifetime = NumberRange.new(lifetime * 0.6, lifetime)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = accel or Vector3.new(0, -2, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.LightEmission = 0.6
	e.LightInfluence = 0.3
	e.Enabled = false
	e.Parent = parent
	return e
end

-- จุดในพิกัดของ MountRoot (x ขวา, y ขึ้น, z หลัง) -> Attachment บนตัวสัตว์
local function attachAt(body, root, name, offset)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = body.CFrame:PointToObjectSpace(root.CFrame:PointToWorldSpace(offset))
	a.Parent = body
	return a
end

addEffects = function(model, mountId)
	local def = MountConfig.Mounts[mountId]
	local root = model.PrimaryPart
	local body = model:FindFirstChild("Body") or root
	if not (def and root and body) then return end
	local _, size = model:GetBoundingBox()
	local seat = tonumber(model:GetAttribute("SeatHeight")) or 3
	local back = size.Z * 0.4
	if def.Perk == "PetalTrail" then
		-- กลีบซากุระร่วงจากหลังกวาง
		local a = attachAt(body, root, "PetalFx", Vector3.new(0, seat * 0.7, back * 0.5))
		local e = emitter(a, ColorSequence.new(Color3.fromRGB(255, 180, 210), Color3.fromRGB(255, 225, 240)), 18, 0.35, 2, 2.5, Vector3.new(0, -1.5, 0))
		e.Drag = 2
	elseif def.Perk == "DoubleJump" then
		-- รอยสายรุ้งตามหลังยูนิคอร์น
		local a0 = attachAt(body, root, "TrailTop", Vector3.new(0, seat * 0.8, back))
		local a1 = attachAt(body, root, "TrailBottom", Vector3.new(0, seat * 0.35, back))
		local t = Instance.new("Trail")
		t.Name = "RainbowTrail"
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.Lifetime = 0.6
		t.MinLength = 0.2
		t.FaceCamera = true
		t.LightEmission = 0.5
		t.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 150)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 110)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 235, 150)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(120, 190, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255)),
		})
		t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		t.Parent = body
		emitter(attachAt(body, root, "SparkleFx", Vector3.new(0, seat * 0.6, back)), ColorSequence.new(Color3.fromRGB(255, 240, 255), Color3.fromRGB(200, 220, 255)), 10, 0.3, 1.5, 1.2)
	elseif def.Perk == "Hover" then
		-- ดาวม่วง-ส้มโปรยจากขนไม้กวาด (ติดตลอด ไม้กวาดลอยอยู่)
		local a = attachAt(body, root, "StarFx", Vector3.new(0, seat * 0.8, back))
		local e = emitter(a, ColorSequence.new(Color3.fromRGB(190, 120, 255), Color3.fromRGB(255, 160, 70)), 14, 0.4, 2, 1.6, Vector3.new(0, -1, 0))
		e:SetAttribute("Always", true)
	elseif def.Perk == "MagicTrail" then
		-- ลามะไม่ลานะ: ดาวสีพาสเทลโปรยเป็นทางตามหลัง + ประกายม่วงรอบตัว + โคมม่วงที่คอส่องแสง
		local a = attachAt(body, root, "StarTrailFx", Vector3.new(0, seat * 0.7, back * 0.7))
		local e = emitter(a, ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 220, 255)),
		}), 16, 0.45, 2.2, 2, Vector3.new(0, 0.6, 0))
		e.Drag = 1.5
		local runes = emitter(attachAt(body, root, "RuneFx", Vector3.new(0, 0.6, 0)), ColorSequence.new(Color3.fromRGB(200, 120, 255), Color3.fromRGB(240, 190, 255)), 10, 0.35, 1.2, 1.4, Vector3.new(0, 1.2, 0))
		runes.SpreadAngle = Vector2.new(180, 20)
		local lamp = attachAt(body, root, "LanternGlow", Vector3.new(0, seat * 0.62, -size.Z * 0.32))
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(200, 130, 255)
		light.Brightness = 1.6
		light.Range = 10
		light.Shadows = false
		light.Parent = lamp
		local glow = emitter(lamp, ColorSequence.new(Color3.fromRGB(215, 160, 255)), 4, 0.5, 0.2, 1, Vector3.zero)
		glow:SetAttribute("Always", true)
	elseif def.Perk == "Moo" then
		-- วัว: กลีบดอกไม้สีพาสเทลผุดจากเท้าตามทาง (2026-10-31)
		local e = emitter(attachAt(body, root, "FlowerFx", Vector3.new(0, 0.3, back * 0.5)), ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 200)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 235, 130)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}), 14, 0.45, 1.6, 1.6, Vector3.new(0, 1.2, 0))
		e.SpreadAngle = Vector2.new(70, 70)
	elseif def.Perk == "MudSplash" then
		-- ควาย: โคลนสีน้ำตาลกระเซ็นจากเท้า (2026-10-31)
		local e = emitter(attachAt(body, root, "MudFx", Vector3.new(0, 0.25, back * 0.4)), ColorSequence.new(Color3.fromRGB(120, 85, 50), Color3.fromRGB(165, 120, 75)), 22, 0.4, 3.5, 0.8, Vector3.new(0, -14, 0))
		e.SpreadAngle = Vector2.new(55, 55)
		e.LightEmission = 0
	elseif def.Perk == "Gallop" then
		-- ม้าก้านกล้วย: ใบตองปลิวจากปลายก้าน (2026-10-31)
		local e = emitter(attachAt(body, root, "LeafFx", Vector3.new(0, 0.6, back * 0.85)), ColorSequence.new(Color3.fromRGB(110, 185, 70), Color3.fromRGB(170, 215, 100)), 12, 0.45, 2, 1.8, Vector3.new(0, -2.5, 0))
		e.Drag = 1.5
		e.LightEmission = 0
		-- 2026-10-31 ผู้ใช้เลือก: (1) ประกายเขียว-ทองรอบก้านตลอดเวลา แบบดาวไม้กวาด (2) ริบบิ้นใบตองลากตามปลายก้าน แบบสายรุ้งยูนิคอร์น
		local glitter = emitter(attachAt(body, root, "GlitterFx", Vector3.new(0, seat * 0.85, 0.3)), ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 255, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 110)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 235, 120)),
		}), 12, 0.32, 1.4, 1.5, Vector3.new(0, 0.4, 0))
		glitter.SpreadAngle = Vector2.new(180, 180)
		glitter:SetAttribute("Always", true)
		local tailZ = back * 0.95
		local a0 = attachAt(body, root, "LeafTrailTop", Vector3.new(0, seat * 0.62, tailZ))
		local a1 = attachAt(body, root, "LeafTrailBottom", Vector3.new(0, seat * 0.28, tailZ))
		local t = Instance.new("Trail")
		t.Name = "LeafTrail"
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.Lifetime = 0.7
		t.MinLength = 0.2
		t.FaceCamera = true
		t.LightEmission = 0.35
		t.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 225, 95)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 190, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 240, 140)),
		})
		t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
		t.Parent = body
	elseif def.Perk == "KindSpray" then
		-- ช้างน้อยใจบุญ (2026-11-03): หยดน้ำพ่นจากปลายงวงตกเป็นโค้ง + ประกายหัวใจเขียว-ชมพูลอยขึ้นจากหลัง
		-- ปลายงวงในพิกัด MountRoot วัดจากโมเดล (งวงชูสูงทาง -Z)
		local water = emitter(attachAt(body, root, "TrunkSprayFx", Vector3.new(0, 3.9, -3.5)), ColorSequence.new(Color3.fromRGB(170, 225, 255), Color3.fromRGB(235, 250, 255)), 18, 0.32, 7, 1, Vector3.new(0, -16, 0))
		water.SpreadAngle = Vector2.new(18, 18)
		water.EmissionDirection = Enum.NormalId.Top
		local hearts = emitter(attachAt(body, root, "KindHeartFx", Vector3.new(0, seat * 0.9, back * 0.7)), ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 225, 140)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 160, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 240, 170)),
		}), 10, 0.45, 1.2, 1.8, Vector3.new(0, 1.5, 0))
		hearts.SpreadAngle = Vector2.new(60, 60)
	elseif def.Perk == "SlowFall" then
		-- ปุยเมฆเล็กๆ ตอนเดิน
		emitter(attachAt(body, root, "CloudFx", Vector3.new(0, 0.4, back * 0.6)), ColorSequence.new(Color3.fromRGB(235, 240, 255), Color3.fromRGB(210, 200, 250)), 6, 0.6, 0.8, 1.2, Vector3.new(0, 0.5, 0))
	end
end

local function makeModel(mountId)
	local folder = ServerStorage:FindFirstChild("MountTemplates")
	local template = folder and folder:FindFirstChild(mountId)
	local model = template and template:Clone() or buildPlaceholder(mountId)
	model.Name = "Mount_" .. mountId
	if not model.PrimaryPart then model.PrimaryPart = model:FindFirstChild("MountRoot", true) end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.CastShadow = true
		end
	end
	-- เชื่อมทุกชิ้นเข้ากับ MountRoot ด้วย Weld (ไม่ใช่ WeldConstraint) ให้ MountFx ฝั่งผู้เล่นขยับ C0 ทำท่าเดิน/ยกขาได้
	local root = model.PrimaryPart
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("WeldConstraint") then d:Destroy() end
	end
	-- ชิ้นที่มี Attribute FollowBody (เช่น ตาลามะ 2026-10-16) เชื่อมกับ Body แทน จะได้ขยับตามท่าเดิน/โยกของ Body
	local bodyPart = model:FindFirstChild("Body")
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("Weld")
			w.Name = d.Name == "Body" and "BodyWeld" or "PartWeld"
			local base = (d:GetAttribute("FollowBody") and bodyPart and d ~= bodyPart) and bodyPart or root
			w.Part0 = base
			w.Part1 = d
			w.C0 = base.CFrame:ToObjectSpace(d.CFrame)
			w.Parent = d
		end
	end
	addEffects(model, mountId)
	model:SetAttribute("Perk", MountConfig.Mounts[mountId] and MountConfig.Mounts[mountId].Perk or nil)
	model:SetAttribute("StandRide", MountConfig.Mounts[mountId] and MountConfig.Mounts[mountId].StandRide or nil)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return model
end

-- ============ เสียงตอนขึ้นขี่ (กลุ่ม EffectSounds: สไลเดอร์เสียงเอฟเฟกต์คุมได้) ============
local SUMMON_SOUNDS = {
	WildHorse = { id = "rbxassetid://3165902128", volume = 1 }, -- Horse_Neigh (ม้าร้อง)
	WitchCatBroom = { id = "rbxassetid://135082616547404", volume = 1.2 }, -- cute-cat-meow (แมวเหมียว)
	ThaiCow = { id = "rbxassetid://138223429", volume = 1 }, -- Cow moo (2026-10-31)
	ThaiBuffalo = { id = "rbxassetid://138223429", volume = 1.1, speed = 0.72 }, -- เสียงวัวเดียวกัน ทุ้มลง = ควาย
	AlbinoBuffalo = { id = "rbxassetid://138223429", volume = 1.1, speed = 0.8 }, -- ทุยเผือก (2026-10-31)
	KindElephant = { id = "rbxassetid://9114300941", volume = 0.9, speed = 1.15 }, -- ช้างร้อง (Pro Sound Effects) เร่งนิดหน่อย = ช้างเด็ก (2026-11-03)
	BananaHorse = { id = "rbxassetid://92630369612488", volume = 0.8, duration = 1.6 }, -- เสียงกุบกับ (Horse Trot Loopable) แทนม้าร้อง ผู้ใช้สั่ง 2026-10-31 · duration = ตัดเสียงหลังกี่วินาที
}
local DEFAULT_SUMMON_SOUND = { id = "rbxassetid://3406813517", volume = 0.6 } -- Power_Up (เสียงวิ้ง)

local function playSummonSound(model, mountId)
	local part = model:FindFirstChild("Body") or model.PrimaryPart
	if not part then return end
	local info = SUMMON_SOUNDS[mountId] or DEFAULT_SUMMON_SOUND
	local sound = Instance.new("Sound")
	sound.Name = "SummonSound"
	sound.SoundId = info.id
	sound.Volume = info.volume
	sound.PlaybackSpeed = (info.speed or 1) * (0.95 + math.random() * 0.1)
	sound.RollOffMaxDistance = 60
	sound.SoundGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds")
	sound.Parent = part
	sound:Play()
	if info.duration then -- เสียงยาว ตัดให้สั้น (ค่อยๆ เบาลงก่อนหยุด)
		task.delay(info.duration, function()
			if not sound.Parent then return end
			game:GetService("TweenService"):Create(sound, TweenInfo.new(0.3), { Volume = 0 }):Play()
			task.delay(0.3, function() if sound.Parent then sound:Stop() end end)
		end)
	end
	game:GetService("Debris"):AddItem(sound, 5)
end

-- ============ ขึ้น / ลง ============
local function setAttrs(player, mountId)
	local def = mountId and MountConfig.Mounts[mountId]
	player:SetAttribute("RidingMount", mountId)
	player:SetAttribute("MountSpeed", def and def.Speed or nil)
	player:SetAttribute("MountRunSpeed", def and (def.RunSpeed or def.Speed) or nil)
	player:SetAttribute("MountJump", def and def.Jump or nil)
end

local function dismount(player)
	local state = riding[player]
	if not state then return false end
	riding[player] = nil
	for _, c in ipairs(state.conns) do c:Disconnect() end
	if state.humanoid and state.humanoid.Parent then
		state.humanoid.HipHeight = state.hipHeight
	end
	if state.model then state.model:Destroy() end
	if player.Parent then setAttrs(player, nil) end
	return true
end

-- ============ ของแต่งสัตว์ขี่ (2026-10-16) ============
-- ชิ้นที่ใส่อยู่ (MountOwnership.GetAccessory) วางที่ Attribute HeadPoint ของแม่แบบ (พิกัดเทียบ MountRoot) เชื่อมกับ Body
-- (Body ขยับตามท่าเดินใน MountFx ของแต่งจึงขยับตาม) เปลี่ยนชิ้นระหว่างขี่ = ถอดของเดิมแล้วติดใหม่
local function attachAccessory(player, state)
	if not (state and state.model and state.model.Parent) then return end
	local old = state.model:FindFirstChild("MountAccessory")
	if old then old:Destroy() end
	local accId = MountOwnership.GetAccessory(player)
	local def = accId and MountConfig.Accessories[accId]
	local folder = ServerStorage:FindFirstChild("MountAccessories")
	local template = def and folder and folder:FindFirstChild(accId)
	-- หมวกประจำตัว (Model "DefaultHat" ในแม่แบบ = หมวกแม่มดของแมวไม้กวาด 2026-10-17): ใส่ของแต่งชิ้นไหนก็ถอดหมวกเดิมออก ไม่ซ้อนกัน
	local defaultHat = state.model:FindFirstChild("DefaultHat")
	if defaultHat then
		local wearing = template ~= nil
		for _, d in ipairs(defaultHat:GetDescendants()) do
			if d:IsA("BasePart") then
				if d:GetAttribute("BaseTransparency") == nil then d:SetAttribute("BaseTransparency", d.Transparency) end
				d.Transparency = wearing and 1 or d:GetAttribute("BaseTransparency")
			end
		end
	end
	local head = state.model:GetAttribute("HeadPoint")
	local root = state.model.PrimaryPart
	local body = state.model:FindFirstChild("Body") or root
	if not (template and typeof(head) == "Vector3" and root and body) then return end
	local acc = template:Clone()
	acc.Name = "MountAccessory"
	-- AccessoryScale (Attribute บนแม่แบบ): สัตว์หัวใหญ่ให้ของแต่งใหญ่ขึ้นตาม เช่นแมวไม้กวาด 2026-10-17
	local scale = (def.Scale or 1) * (tonumber(state.model:GetAttribute("AccessoryScale")) or 1)
	-- ตั้งรายตัว (Attribute บนแม่แบบสัตว์ 2026-10-17): AccScale_<accId> = ตัวคูณขนาดเพิ่ม, AccPos_<accId> = CFrame จุดหมุนของแต่ง (เทียบ MountRoot)
	-- เช่นกระต่าย: โบว์ที่หน้าผาก, วงแหวนเล็กลงลอยเหนือหน้าผากไม่ติดหู (ผู้ใช้ขอ)
	local extraScale = tonumber(state.model:GetAttribute("AccScale_" .. accId))
	if extraScale and extraScale > 0 then scale *= extraScale end
	if scale ~= 1 then acc:ScaleTo(acc:GetScale() * scale) end
	local customCf = state.model:GetAttribute("AccPos_" .. accId)
	local pos = root.CFrame:PointToWorldSpace(head + Vector3.new(0, (def.Float or 0) - 0.08, 0))
	-- สัตว์ที่มีหมวกในตัว (แมวไม้กวาด 2026-10-17): ใส่หมวก (def.Hat) = ขยายให้ใหญ่พอครอบหมวกเดิมมิด แล้ววางที่ HatCoverPoint ดูเหมือนเปลี่ยนหมวก
	-- Attribute บนแม่แบบ: HatCoverPoint (Vector3 เทียบ MountRoot = กึ่งกลางใต้หมวกเดิม), HatCoverSize (Vector3 ขนาดหมวกเดิม + เผื่อ)
	local coverPoint, coverSize = state.model:GetAttribute("HatCoverPoint"), state.model:GetAttribute("HatCoverSize")
	if def.Hat and typeof(coverPoint) == "Vector3" and typeof(coverSize) == "Vector3" then
		local _, size = acc:GetBoundingBox()
		local k = math.max(coverSize.X / size.X, coverSize.Z / size.Z, coverSize.Y / size.Y, 1)
		if k > 1 then acc:ScaleTo(acc:GetScale() * k) end
		pos = root.CFrame:PointToWorldSpace(coverPoint)
	end
	if typeof(customCf) == "CFrame" then
		acc:PivotTo(root.CFrame * customCf)
	else
		acc:PivotTo(root.CFrame.Rotation + pos)
	end
	for _, d in ipairs(acc:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			local w = Instance.new("Weld")
			w.Name = "AccessoryWeld"
			w.Part0 = body
			w.Part1 = d
			w.C0 = body.CFrame:ToObjectSpace(d.CFrame)
			w.Parent = d
		end
	end
	acc.Parent = state.model
end

-- ============ สัตว์ขี่ขยายตามตัวละคร (2026-10-20 ผู้ใช้: ตัวละครตัวใหม่ขี่ม้า/ลามะท่าแปลก) ============
-- สัตว์ทุกตัวจูนกับอวาตาร์เจ้าของเกม (สะโพกสูง REF_HIP) ตัวละครขายาว/สั้นกว่านี้ = ขยาย/ย่อสัตว์ตามสัดส่วน (ท่านั่งคร่อมเหมือนกันทุกคน)
-- Humanoid.HipHeight (R15) คำนวณจากความยาวขาอยู่แล้ว · อวาตาร์ปกติของ Roblox = 2.19 เจ้าของเกม = 2.00 (วัด 2026-10-20)
local REF_HIP = 2.0
local MIN_RIDER_SCALE, MAX_RIDER_SCALE = 0.8, 1.5

local function riderScale(humanoid, standingHip)
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then return 1 end
	local hip = tonumber(standingHip) or humanoid.HipHeight
	if not hip or hip <= 0 then return 1 end
	return math.clamp(hip / REF_HIP, MIN_RIDER_SCALE, MAX_RIDER_SCALE)
end

-- คูณตัวเลขที่เป็นระยะ (studs) ในสตริง "a,b,c;..." ตามลำดับช่องที่กำหนด (ช่องอื่น เช่น ชื่อ/องศา คงเดิม)
local function scaleFields(str, k, isDistance)
	local groups = {}
	for group in string.gmatch(str, "[^;]+") do
		local fields = {}
		local i = 0
		for f in string.gmatch(group, "[^,]+") do
			i += 1
			local n = tonumber(f)
			if n and isDistance(i) then f = tostring(math.floor(n * k * 1000 + 0.5) / 1000) end
			table.insert(fields, f)
		end
		table.insert(groups, table.concat(fields, ","))
	end
	return table.concat(groups, ";")
end

-- ขยายโมเดลสัตว์รอบ MountRoot (จุดหมุนที่พื้น) + ค่าตำแหน่งใน Attribute ที่เทียบ MountRoot (ScaleTo ไม่แตะ Attribute)
local function scaleMount(model, k)
	if math.abs(k - 1) < 0.03 then return end
	model:ScaleTo(model:GetScale() * k)
	for name, v in pairs(model:GetAttributes()) do
		if name == "SeatHeight" and type(v) == "number" then
			model:SetAttribute(name, v * k)
		elseif (name == "HeadPoint" or name == "HatCoverPoint" or name == "HatCoverSize") and typeof(v) == "Vector3" then
			model:SetAttribute(name, v * k)
		elseif string.match(name, "^AccPos_") and typeof(v) == "CFrame" then
			model:SetAttribute(name, v.Rotation + v.Position * k)
		end
	end
	model:SetAttribute("AccessoryScale", (tonumber(model:GetAttribute("AccessoryScale")) or 1) * k)
	model:SetAttribute("RiderScale", k)
	-- ยูนิคอร์น: กระดูกขา/การสะท้อนขาหน้า เก็บพิกัดใน Body เป็น studs (MountFx) ต้องคูณตาม · CapHoles เป็นพิกัด mesh ไม่ต้องแก้
	local body = model:FindFirstChild("Body")
	if body then
		local rig = body:GetAttribute("LegRig")
		if type(rig) == "string" then
			-- ชื่อ,หน้า,ซ้าย,แกนX,แกนZ,สะโพกY,สะโพกZ,เต็มที่Y,หมดที่Y[,เข่าX,เข่าY,เข่าZ,แก้เข่า°,แก้สะโพก°] = ช่อง 4-12 เป็นระยะ
			body:SetAttribute("LegRig", scaleFields(rig, k, function(i) return i >= 4 and i <= 12 end))
		end
		local mirror = body:GetAttribute("MirrorFront")
		if type(mirror) == "string" then
			body:SetAttribute("MirrorFront", scaleFields(mirror, k, function() return true end))
		end
	end
end

local function ride(player, mountId)
	local def = MountConfig.Mounts[mountId]
	if not def then return false, "ไม่รู้จักสัตว์ขี่ตัวนี้" end
	if not MountOwnership.Owns(player, mountId) then return false, "ยังไม่มีสัตว์ขี่ตัวนี้" end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and hrp) or humanoid.Health <= 0 then return false, "ตัวละครยังไม่พร้อม" end
	if humanoid.Sit then return false, "ลุกจากที่นั่งก่อนนะ" end
	-- ถูกแบกอยู่ = ขี่ไม่ได้ · กำลังแบกเพื่อน = ขี่ได้ เพื่อนไปด้วยกัน (ผู้ใช้ขอ 2026-10-20)
	if player:GetAttribute("CarriedBy") then return false, "ตอนถูกแบกขี่ไม่ได้" end
	if player:GetAttribute("BoxingSide") then return false, "อยู่บนเวทีมวย ขี่ไม่ได้นะ" end

	local hipHeight = riding[player] and riding[player].hipHeight or humanoid.HipHeight
	dismount(player)

	local model = makeModel(mountId)
	scaleMount(model, riderScale(humanoid, hipHeight)) -- ขยายตามความยาวขาตัวละคร (ก่อนอ่าน SeatHeight)
	local root = model.PrimaryPart
	local seat = tonumber(model:GetAttribute("SeatHeight")) or 3
	local halfRoot = hrp.Size.Y / 2
	-- ก้นตัวละคร (ใต้ LowerTorso) = ใต้ HRP -> HipHeight = ความสูงหลังสัตว์ + เผื่อนิดหน่อย (วัดใน Play 2026-10-15)
	local newHip = seat + RIDER_LIFT
	-- StandRide (ม้าก้านกล้วย 2026-10-31): ยืนบนพื้นตามปกติ ก้านอยู่ระหว่างขา -> สะโพกเท่าตอนยืน
	if def.StandRide then newHip = hipHeight end
	-- พื้นอยู่ที่ HRP.Y - halfRoot - HipHeight -> วาง MountRoot (พื้นใต้เท้าสัตว์) ตรงนั้น
	model:PivotTo(hrp.CFrame * CFrame.new(0, -(halfRoot + newHip), 0))
	local weld = Instance.new("Weld")
	weld.Name = "MountWeld"
	weld.Part0 = hrp
	weld.Part1 = root
	weld.C0 = CFrame.new(0, -(halfRoot + newHip), 0)
	weld.Parent = root
	model.Parent = character
	humanoid.HipHeight = newHip

	local state = { model = model, weld = weld, humanoid = humanoid, hipHeight = hipHeight, conns = {} }
	riding[player] = state
	table.insert(state.conns, humanoid.Died:Connect(function() dismount(player) end))
	table.insert(state.conns, humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
		if humanoid.Sit then dismount(player) end
	end))
	table.insert(state.conns, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) and riding[player] == state then dismount(player) end
	end))
	setAttrs(player, mountId)
	MountOwnership.SetEquipped(player, mountId)
	attachAccessory(player, state)
	playSummonSound(model, mountId)
	return true
end

local function firstOwned(player)
	return MountOwnership.GetOwned(player)[1]
end

request.OnServerInvoke = function(player, action, mountId)
	if not MountConfig.IsEnabled() then return { ok = false, message = "ระบบสัตว์ขี่ยังไม่เปิด" } end -- สวิตช์ปิด (2026-10-16)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < REQUEST_COOLDOWN then
		return { ok = false, message = "ใจเย็นๆ รออีกนิดนะ" }
	end
	lastRequest[player] = now
	if not MountOwnership.IsLoaded(player) then return { ok = false, message = "ข้อมูลสัตว์ขี่ยังโหลดไม่เสร็จ" } end
	local ok, message
	if action == "ride" then
		if type(mountId) ~= "string" then return { ok = false, message = "คำขอไม่ถูกต้อง" } end
		ok, message = ride(player, mountId)
	elseif action == "toggle" then
		if riding[player] then
			ok = dismount(player)
		else
			local id = MountOwnership.GetEquipped(player) or firstOwned(player)
			if not id then return { ok = false, message = "ยังไม่มีสัตว์ขี่ ไปสุ่มที่ตู้สุ่มสัตว์ขี่ก่อนนะ" } end
			ok, message = ride(player, id)
		end
	elseif action == "accessory" then
		-- mountId = accId ที่จะใส่ / "" = ถอด
		local accId = (type(mountId) == "string" and mountId ~= "") and mountId or nil
		if accId and not MountConfig.Accessories[accId] then return { ok = false, message = "คำขอไม่ถูกต้อง" } end
		ok, message = MountOwnership.SetAccessory(player, accId)
		if ok and riding[player] then attachAccessory(player, riding[player]) end
	elseif action == "dismount" then
		ok = dismount(player) or true
	else
		return { ok = false, message = "คำขอไม่ถูกต้อง" }
	end
	return { ok = ok == true, message = message, riding = player:GetAttribute("RidingMount") }
end

dismountEvent.Event:Connect(function(player)
	if typeof(player) == "Instance" and player:IsA("Player") then dismount(player) end
end)

-- ระบบอื่นสั่งขี่ได้: ServerStorage.MountRideRequest:Invoke(player, mountId) -> true/false (2026-10-20 กลับจาก AFK ขี่สัตว์ตัวเดิมต่อ)
local rideFn = ServerStorage:FindFirstChild("MountRideRequest")
if not rideFn then
	rideFn = Instance.new("BindableFunction")
	rideFn.Name = "MountRideRequest"
	rideFn.Parent = ServerStorage
end
rideFn.OnInvoke = function(player, mountId)
	if not (typeof(player) == "Instance" and player:IsA("Player") and type(mountId) == "string") then return false end
	if not MountConfig.IsEnabled() or not MountConfig.Mounts[mountId] then return false end
	if not MountOwnership.WaitLoaded(player, 30) then return false end
	if player:GetAttribute("RidingMount") == mountId then return true end
	local ok = ride(player, mountId)
	return ok == true
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function() dismount(player) end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterRemoving:Connect(function() dismount(player) end)
end
Players.PlayerRemoving:Connect(function(player)
	dismount(player)
	lastRequest[player] = nil
end)
