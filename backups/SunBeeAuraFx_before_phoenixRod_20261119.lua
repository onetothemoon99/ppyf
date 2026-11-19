-- BACKUP of game.StarterPlayer.StarterPlayerScripts.SunBeeAuraFx (Studio Source, byte-exact, len 11853 hash 1779918814)
-- Restore: paste everything below this header into game.StarterPlayer.StarterPlayerScripts.SunBeeAuraFx.Source in Studio.
-- SunBeeAuraFx: ออร่ารอบตัวคนที่ถือเบ็ดพิเศษ ทุกคนเห็น ทำบนเครื่องผู้เล่นแต่ละคน ไม่ใช้เซิร์ฟเวอร์ (2026-10-08)
--   เบ็ดผึ้งน้อย (RodId SunBee) = โทนทอง + กลีบทานตะวันปลิว / เบ็ดผีเสื้อ (RodId NightMoth) = โทนม่วง + ผีเสื้อบิน (เพิ่ม 2026-10-08 ผู้เล่นขอ)
--   วงเวทใต้เท้า 2 ชั้น (หมุนสวนกัน) + รัศมีแสงด้านหลังตัว + ละอองลอยขึ้น + ของปลิว (กลีบ/ผีเสื้อ)
--   + ทำให้ไฮไลต์/แสงที่คันเบ็ด (FishingSystem ใส่ไว้) เต้นเป็นจังหวะหายใจ
-- อยู่ไกลกล้องเกิน VIEW_DISTANCE = ซ่อน

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GraphicsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("GraphicsConfig"))

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
	motes.Rate = 30
	motes.Lifetime = NumberRange.new(1.4, 2.6)
	motes.Speed = NumberRange.new(1.2, 2.8)
	motes.SpreadAngle = Vector2.new(6, 6)
	motes.Drag = 0.6
	motes.Size = NS({ NK(0, 0), NK(0.2, 0.16, 0.06), NK(1, 0) })
	motes.Transparency = NS({ NK(0, 0.1), NK(0.8, 0.2), NK(1, 1) })
	motes.Color = ColorSequence.new(style.moteA, style.moteB)
	motes.LightEmission, motes.LightInfluence, motes.Brightness = 1, 0, 2 * dim
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
	drift.Parent = pad

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
	return { rodId = rodId, style = style, folder = folder, pad = pad, outer = outer, inner = inner, rays = rays, rays2 = rays2, motes = motes, drift = drift, params = params, root = root }
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
		fx.drift.Enabled = near
		-- วงเวทวางบนพื้นใต้เท้า (ยิงลงหาพื้น/น้ำ) กระโดดแล้ววงยังอยู่ที่พื้น
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), fx.params)
		if hit and near then
			fx.pad.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.06, 0))
			fx.outer.Visible, fx.inner.Visible = true, true
		else
			fx.outer.Visible, fx.inner.Visible = false, false
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
