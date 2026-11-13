-- BACKUP 2026-11-12 of game.StarterPlayer.StarterPlayerScripts.KrathongFireworks (LocalScript, Studio) before "every 10 min for 2 min + /fireworks command".
-- Restore: copy everything BELOW the "==== SOURCE ====" line into that script's Source in Studio.
-- ==== SOURCE ====
-- KrathongFireworks (2026-11-12 ผู้ใช้สั่ง): พลุยิงจากทะเลหลังจุดที่โคมลอยขึ้นเอง มีเสียง ทำบนเครื่องผู้เล่นล้วน (เซิร์ฟไม่ส่งอะไรเพิ่ม)
-- จุดยิง = เส้น F01..F07 ใน workspace.KrathongBeachLanternLine.FireworkLine ± HalfWidth
--   (ต้นแบบแก้ใน Edit ที่ workspace.KrathongDecor.BeachLanternLine.FireworkLine · KrathongService โคลนทั้งเส้นแล้วทำให้มองไม่เห็นตอนเล่น)
-- ยิงเฉพาะกลางคืน (เวลาส่วนตัว/เวลาเกม แบบ KrathongClient) + เทศกาลเปิด (มีเส้น KrathongBeachLanternLine ในแมพ)
--   ปกติทีละลูกทุก EVERY วิ · รอบปล่อยโคมพร้อมกัน (KrathongFx "lantern" mass) = ชุดใหญ่ SHOW_SECONDS วิ + ปิดท้ายพร้อมกัน FINALE ลูก
-- ทดสอบใน Studio: ตั้ง Attribute workspace.DevFireworksNow = true → ยิงชุดใหญ่ทันที (ไม่สนกลางวัน/กลางคืน) ตั้ง false แล้ว true ใหม่ = ยิงอีกรอบ
-- 2026-11-12 รอบแรกเล็ก/จางเกินเมื่อมองจากหาด (~300 studs) → ขยายประกาย ~2.3 เท่า ความเร็วกระจาย ~2 เท่า + Brightness 3
-- ค่าทั้งหมดอยู่ใน CFG ข้างล่าง (เสียงเป็นของฟรีจาก Creator Store เปลี่ยน id ได้)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local CFG = {
	EVERY = { 4, 8 },            -- ปกติ: วิระหว่างลูก
	SHOW_SECONDS = 30,           -- ชุดใหญ่ตอนปล่อยโคมพร้อมกัน
	SHOW_EVERY = { 0.35, 0.9 },  -- ชุดใหญ่: วิระหว่างลูก
	FINALE = 8,                  -- ปิดท้ายพร้อมกันกี่ลูก
	MAX_ALIVE = 6,               -- ลอยอยู่พร้อมกันสูงสุด (ปกติ)
	MAX_ALIVE_SHOW = 12,         -- ชุดใหญ่
	BURST_HEIGHT = { 90, 150 },  -- แตกสูงจากผิวน้ำ
	RISE_TIME = { 1.3, 1.9 },
	CULL = 900,                  -- ไกลกล้องเกินนี้ไม่ยิง
	GFX = { high = 1, mid = 0.7, low = 0.4, lowest = 0 }, -- ตัวคูณจำนวนตามระดับกราฟิก (0 = ปิด)
	PARTICLES = 140,             -- ประกายต่อลูกที่กราฟิกสูง
	SOUND_DELAY = 0.5,           -- เสียงตูมช้ากว่าแสง (อยู่ไกล)
	SOUNDS = {
		launch = "rbxassetid://84790178390954",   -- firework_fly
		booms = { "rbxassetid://130548883007767", "rbxassetid://103126237078653", "rbxassetid://92353219346615" }, -- Firework_Explosion1 / Firework_Explosion / firework kaboom 3
		crackle = "rbxassetid://100559751053348", -- FireworkSpark
	},
	COLORS = {
		Color3.fromRGB(255, 205, 90),  -- ทอง
		Color3.fromRGB(255, 80, 80),   -- แดง
		Color3.fromRGB(255, 120, 200), -- ชมพู
		Color3.fromRGB(110, 255, 140), -- เขียว
		Color3.fromRGB(110, 190, 255), -- ฟ้า
		Color3.fromRGB(190, 120, 255), -- ม่วง
	},
	NIGHT_ON = 18.2, NIGHT_OFF = 6.3,
}
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local rnd = Random.new()
local alive = 0
local showUntil = 0

local function gfxMult()
	local q = player:GetAttribute("GraphicsQuality")
	return (type(q) == "string" and CFG.GFX[q]) or 1
end

local function isNight()
	local t = player:GetAttribute("PersonalVisualClockTime")
	t = typeof(t) == "number" and t or Lighting.ClockTime
	return t >= CFG.NIGHT_ON or t < CFG.NIGHT_OFF
end

local function fireLine()
	local l = workspace:FindFirstChild("KrathongBeachLanternLine")
	return l and l:FindFirstChild("FireworkLine")
end

local function launchPoint(line)
	local pts = {}
	for _, p in ipairs(line:GetChildren()) do if p:IsA("BasePart") then table.insert(pts, p) end end
	if #pts == 0 then return nil end
	table.sort(pts, function(a, b) return a.Name < b.Name end)
	local i = rnd:NextInteger(1, math.max(1, #pts - 1))
	local a, b = pts[i].Position, (pts[i + 1] or pts[i]).Position
	local p = a:Lerp(b, rnd:NextNumber())
	local d = (b - a) * Vector3.new(1, 0, 1)
	local side = d.Magnitude > 0.1 and Vector3.new(-d.Z, 0, d.X).Unit or Vector3.xAxis
	local hw = tonumber(line:GetAttribute("HalfWidth")) or 20
	return p + side * rnd:NextNumber(-hw, hw)
end

local function ghost(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

local function holder(pos, life)
	local p = Instance.new("Part")
	p.Name = "Firework"
	p.Transparency = 1
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	ghost(p)
	p.Position = pos
	p.Parent = workspace
	Debris:AddItem(p, life)
	return p
end

local function sound(parent, id, volume, speed)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = speed or 1
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 180
	s.RollOffMaxDistance = 1600
	s.SoundGroup = SoundService:FindFirstChild("EffectSounds")
	s.Parent = parent
	s:Play()
end

local function seq(a, b) return ColorSequence.new(a, b) end

-- ประกายแตก 4 แบบ: peony (ทรงกลม) / willow (ทองไหลย้อย) / ring (วงแหวน) / glitter (ระยิบ + เปาะแปะ)
local function burst(pos, kind, color, color2, mult)
	local part = holder(pos, 7)
	local n = math.max(12, math.floor(CFG.PARTICLES * mult))
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.LightEmission = 1
	e.LightInfluence = 0
	pcall(function() e.Brightness = 3 end) -- ไกลจากหาด ~300 studs ต้องสว่างกว่าปกติ
	e.Enabled = false
	e.Rate = 0
	e.Color = seq(color, color2)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.15), NumberSequenceKeypoint.new(1, 1) })
	e.SpreadAngle = Vector2.new(180, 180)
	e.RotSpeed = NumberRange.new(-90, 90)
	if kind == "willow" then
		e.Color = seq(Color3.fromRGB(255, 215, 120), Color3.fromRGB(255, 140, 40))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 7), NumberSequenceKeypoint.new(1, 1.5) })
		e.Speed = NumberRange.new(90, 110)
		e.Drag = 1.6
		e.Lifetime = NumberRange.new(3, 4.2)
		e.Acceleration = Vector3.new(0, -14, 0)
	elseif kind == "ring" then
		e.Shape = Enum.ParticleEmitterShape.Disc
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		e.ShapePartial = 1
		e.SpreadAngle = Vector2.new(4, 4)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 7.5), NumberSequenceKeypoint.new(1, 0) })
		e.Speed = NumberRange.new(130, 145)
		e.Drag = 2.4
		e.Lifetime = NumberRange.new(1.8, 2.3)
		e.Acceleration = Vector3.new(0, -6, 0)
		part.Size = Vector3.new(2, 0.2, 2)
		-- เอียงวงแหวนให้หันหาคนดูบ้าง (สุ่ม)
		part.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(rnd:NextNumber(55, 90)), rnd:NextNumber(0, math.pi * 2), 0)
	else
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 0) })
		e.Speed = NumberRange.new(120, 150)
		e.Drag = 2.6
		e.Lifetime = NumberRange.new(1.6, 2.4)
		e.Acceleration = Vector3.new(0, -8, 0)
	end
	e.Parent = part
	e:Emit(n)
	-- แกนกลางวาบ
	local flash = Instance.new("Part")
	flash.Name = "FireworkFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
	flash.Size = Vector3.new(10, 10, 10)
	ghost(flash)
	flash.Position = pos
	flash.Parent = workspace
	TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(34, 34, 34), Transparency = 1 }):Play()
	Debris:AddItem(flash, 0.4)
	if mult >= 0.99 then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 60
		light.Brightness = 4
		light.Parent = part
		TweenService:Create(light, TweenInfo.new(0.6), { Brightness = 0 }):Play()
	end
	-- glitter: ระยิบขาวตามหลังพร้อมเสียงเปาะแปะ
	if kind == "glitter" then
		task.delay(0.8, function()
			if not part.Parent then return end
			local g = Instance.new("ParticleEmitter")
			g.Texture = SPARK
			g.LightEmission = 1
			g.LightInfluence = 0
			g.Enabled = false
			g.Color = seq(Color3.new(1, 1, 1), Color3.fromRGB(255, 240, 200))
			g.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3.5), NumberSequenceKeypoint.new(1, 0) })
			g.Speed = NumberRange.new(10, 45)
			g.SpreadAngle = Vector2.new(180, 180)
			g.Lifetime = NumberRange.new(0.3, 1.1)
			g.Drag = 1
			g.Shape = Enum.ParticleEmitterShape.Sphere
			g.Parent = part
			part.Size = Vector3.new(60, 60, 60)
			g:Emit(math.floor(n * 0.8))
		end)
	end
	-- เสียง: ตูม (ช้ากว่าแสงนิดหน่อย) + เปาะแปะ
	task.delay(CFG.SOUND_DELAY, function()
		local booms = CFG.SOUNDS.booms
		sound(part, booms[rnd:NextInteger(1, #booms)], 1, rnd:NextNumber(0.9, 1.1))
		if kind == "glitter" or rnd:NextNumber() < 0.4 then
			task.delay(0.6, function() if part.Parent then sound(part, CFG.SOUNDS.crackle, 0.7, rnd:NextNumber(0.95, 1.1)) end end)
		end
	end)
end

local KINDS = { "peony", "peony", "willow", "ring", "glitter" }

local function launch(line, mult, maxAlive)
	if alive >= maxAlive then return end
	local base = launchPoint(line)
	if not base then return end
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - base).Magnitude > CFG.CULL then return end
	alive += 1
	local height = rnd:NextNumber(CFG.BURST_HEIGHT[1], CFG.BURST_HEIGHT[2])
	local rise = rnd:NextNumber(CFG.RISE_TIME[1], CFG.RISE_TIME[2])
	local top = base + Vector3.new(rnd:NextNumber(-8, 8), height, rnd:NextNumber(-8, 8))
	local color = CFG.COLORS[rnd:NextInteger(1, #CFG.COLORS)]
	local color2 = CFG.COLORS[rnd:NextInteger(1, #CFG.COLORS)]
	-- ลูกไฟพุ่งขึ้น + หางประกาย
	local rocket = Instance.new("Part")
	rocket.Name = "FireworkRocket"
	rocket.Shape = Enum.PartType.Ball
	rocket.Material = Enum.Material.Neon
	rocket.Color = Color3.fromRGB(255, 230, 170)
	rocket.Size = Vector3.new(1, 1, 1)
	ghost(rocket)
	rocket.Position = base
	rocket.Parent = workspace
	local tail = Instance.new("ParticleEmitter")
	tail.Texture = SPARK
	tail.LightEmission = 1
	tail.LightInfluence = 0
	tail.Color = seq(Color3.fromRGB(255, 220, 150), Color3.fromRGB(255, 120, 40))
	tail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
	tail.Lifetime = NumberRange.new(0.4, 0.8)
	tail.Rate = 45 * math.max(0.4, mult)
	tail.Speed = NumberRange.new(1, 4)
	tail.SpreadAngle = Vector2.new(15, 15)
	tail.EmissionDirection = Enum.NormalId.Bottom
	tail.Acceleration = Vector3.new(0, -10, 0)
	tail.Parent = rocket
	sound(rocket, CFG.SOUNDS.launch, 0.55, rnd:NextNumber(0.95, 1.1))
	TweenService:Create(rocket, TweenInfo.new(rise, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = top }):Play()
	task.delay(rise, function()
		tail.Enabled = false
		rocket.Transparency = 1
		Debris:AddItem(rocket, 1)
		local kind = KINDS[rnd:NextInteger(1, #KINDS)]
		pcall(burst, top, kind, color, color2, mult)
		task.delay(3, function() alive -= 1 end)
	end)
end

-- รอบปล่อยโคมพร้อมกัน = ชุดใหญ่
local function startShow(force)
	local line = fireLine()
	local mult = gfxMult()
	if not line or mult <= 0 or (not force and not isNight()) then return end
	showUntil = os.clock() + CFG.SHOW_SECONDS
	task.spawn(function()
		while os.clock() < showUntil do
			if fireLine() then launch(fireLine(), gfxMult(), CFG.MAX_ALIVE_SHOW) end
			task.wait(rnd:NextNumber(CFG.SHOW_EVERY[1], CFG.SHOW_EVERY[2]) / math.max(0.4, gfxMult()))
		end
		-- ปิดท้ายพร้อมกัน
		local l = fireLine()
		if l then
			for _ = 1, math.max(2, math.floor(CFG.FINALE * gfxMult())) do
				launch(l, gfxMult(), CFG.MAX_ALIVE_SHOW + CFG.FINALE)
				task.wait(rnd:NextNumber(0.03, 0.15))
			end
		end
	end)
end

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
	local fx = remotes:WaitForChild("KrathongFx")
	fx.OnClientEvent:Connect(function(kind, data)
		if kind == "lantern" and type(data) == "table" and data.mass then startShow(false) end
	end)
end)

-- Studio: ยิงชุดใหญ่ทันที
if RunService:IsStudio() then
	workspace:GetAttributeChangedSignal("DevFireworksNow"):Connect(function()
		if workspace:GetAttribute("DevFireworksNow") == true then startShow(true) end
	end)
end

-- ปกติ: กลางคืนทีละลูก
task.spawn(function()
	while true do
		local mult = gfxMult()
		task.wait(rnd:NextNumber(CFG.EVERY[1], CFG.EVERY[2]) / math.max(0.4, mult))
		local line = fireLine()
		if line and mult > 0 and os.clock() >= showUntil and isNight() then
			launch(line, mult, CFG.MAX_ALIVE)
		end
	end
end)
