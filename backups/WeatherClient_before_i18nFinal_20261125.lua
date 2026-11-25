-- BACKUP of StarterPlayer.StarterPlayerScripts.WeatherClient before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.WeatherClient.Source in Studio
-- WeatherClient: ภาพ/เสียงฝนตก (เซิร์ฟเวอร์ WeatherService ตั้ง Attribute "Weather" ของ workspace)
--   เม็ดฝนตกรอบกล้อง + ฟ้าหม่น/เมฆครึ้ม (ColorCorrection + Clouds เฉพาะเครื่องเรา) + เสียงฝน + ฟ้าร้องฟ้าแลบเป็นระยะ
--   ป้าย 🌧️ มุมซ้ายบนบอกโบนัสและเวลาที่เหลือ / ทุกอย่างค่อยๆ เฟดเข้า-ออก ไม่เปลี่ยนกะทันหัน

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RAIN_SOUND = "rbxassetid://1516791621" -- Rain Effect (Roblox)
local THUNDER_SOUNDS = { "rbxassetid://139319051979882", "rbxassetid://136909414800877" }
local RAIN_VOLUME = 0.35
local FADE_TIME = 4 -- วินาทีที่ใช้เฟดเข้า/ออก

-- ============ เม็ดฝน: เส้นบางๆ ตกรอบกล้อง (ขยับทีเดียวทั้งชุดด้วย BulkMoveTo) ============
-- (ลอง ParticleEmitter แล้ว เส้นฝนแนวนอน/มองไม่เห็นแล้วแต่มุมกล้อง จึงใช้ชิ้นส่วนบางๆ แทน)
local DROP_COUNT = 380
local DROP_RADIUS = 38     -- ตกในวงรอบกล้อง
local DROP_TOP = 26        -- เกิดสูงกว่ากล้องเท่านี้
local DROP_BOTTOM = -18    -- ตกต่ำกว่ากล้องเท่านี้แล้ววนกลับขึ้นไป
local DROP_SPEED = { 60, 75 }
local DROP_TILT = CFrame.Angles(math.rad(6), 0, math.rad(3)) -- เอียงนิดๆ เหมือนลมพัด
local dropFolder = Instance.new("Folder")
dropFolder.Name = "RainDrops"
dropFolder.Parent = workspace
local drops, dropCFs, speeds = {}, {}, {}
local hidden = CFrame.new(0, -10000, 0)
for i = 1, DROP_COUNT do
	local d = Instance.new("Part")
	d.Name = "Drop"
	d.Anchored = true
	d.CanCollide = false
	d.CanQuery = false
	d.CanTouch = false
	d.CastShadow = false
	d.Material = Enum.Material.SmoothPlastic
	d.Color = Color3.fromRGB(215, 228, 248)
	d.Transparency = 0.3
	d.Size = Vector3.new(0.08, 2.6, 0.08)
	d.CFrame = hidden
	d.Parent = dropFolder
	drops[i] = d
	dropCFs[i] = hidden
	speeds[i] = math.random(DROP_SPEED[1], DROP_SPEED[2])
end
local dropY = {}  -- ความสูงสัมพัทธ์กับกล้อง
local dropXZ = {} -- ตำแหน่งแนวนอน (โลก)
local function respawn(i, camPos, anywhere)
	local a = math.random() * math.pi * 2
	local r = math.sqrt(math.random()) * DROP_RADIUS
	dropXZ[i] = Vector3.new(camPos.X + math.cos(a) * r, 0, camPos.Z + math.sin(a) * r)
	dropY[i] = anywhere and (DROP_BOTTOM + math.random() * (DROP_TOP - DROP_BOTTOM)) or (DROP_TOP + math.random() * 4)
end
local dropsActive = 0

-- จำนวนเม็ดฝนตามระดับกราฟิก (GraphicsConfig RainDrops: ต่ำ 40% / ต่ำสุด 0 = เหลือแค่เสียงกับฟ้าหม่น) 2026-10-24
local GraphicsConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("GraphicsConfig"))
local dropFactor = 1
local function refreshDropFactor()
	local f = tonumber(GraphicsConfig.Get(player:GetAttribute(GraphicsConfig.ATTRIBUTE)).RainDrops)
	dropFactor = f and math.clamp(f, 0, 1) or 1
end
player:GetAttributeChangedSignal(GraphicsConfig.ATTRIBUTE):Connect(refreshDropFactor)
refreshDropFactor()

-- ============ ฟ้าหม่น + เมฆครึ้ม ============
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "RainTint"
tint.Parent = Lighting
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local baseCover, baseDensity, baseColor = 0.58, 0.62, Color3.new(1, 1, 1)
if clouds then baseCover, baseDensity, baseColor = clouds.Cover, clouds.Density, clouds.Color end

-- ============ เสียง ============
local rainSound = Instance.new("Sound")
rainSound.Name = "RainSound"
rainSound.SoundId = RAIN_SOUND
rainSound.Looped = true
rainSound.Volume = 0
rainSound.SoundGroup = SoundService:FindFirstChild("NatureSounds") or SoundService:FindFirstChild("EffectSounds") -- สไลเดอร์ "เสียงธรรมชาติ"
rainSound.Parent = SoundService

-- ============ ป้าย 🌧️ ============
local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local pill = Instance.new("TextLabel")
pill.Name = "RainPill"
pill.AnchorPoint = Vector2.new(0, 0)
pill.Position = UDim2.new(0, 12, 0, 64)
pill.Size = UDim2.new(0, 0, 0, 30)
pill.AutomaticSize = Enum.AutomaticSize.X
-- ไม่มีพื้นหลัง/กรอบ (ผู้เล่นขอให้โปร่งใส 2026-10-01) ใช้เส้นขอบตัวอักษรสีเข้มแทน อ่านออกบนฉากสว่าง
pill.BackgroundTransparency = 1
pill.TextColor3 = Color3.new(1, 1, 1)
pill.TextStrokeColor3 = Color3.fromRGB(25, 45, 80)
pill.TextStrokeTransparency = 0.2
pill.Font = Enum.Font.GothamBold
pill.TextSize = 14
pill.Visible = false
pill.Parent = gui

-- ============ ฟ้าแลบ + ฟ้าร้อง ============
local flash = Instance.new("ColorCorrectionEffect")
flash.Name = "LightningFlash"
flash.Parent = Lighting
local function lightning()
	-- แลบ 2 ที ติดกัน แล้วฟ้าร้องตามมา (ช้ากว่านิดหน่อยเหมือนจริง)
	for _, b in ipairs({ 0.45, 0.25 }) do
		flash.Brightness = b
		TweenService:Create(flash, TweenInfo.new(0.18), { Brightness = 0 }):Play()
		task.wait(0.22)
	end
	task.wait(0.4 + math.random() * 1.2)
	local t = Instance.new("Sound")
	t.SoundId = THUNDER_SOUNDS[math.random(1, #THUNDER_SOUNDS)]
	t.Volume = 0.35 + math.random() * 0.2
	t.PlaybackSpeed = 0.9 + math.random() * 0.2
	t.SoundGroup = SoundService:FindFirstChild("NatureSounds") or SoundService:FindFirstChild("EffectSounds")
	t.Parent = SoundService
	t:Play()
	t.Ended:Once(function() t:Destroy() end)
end

-- ============ เฟดเข้า/ออก ============
local level = 0 -- 0 = ฟ้าใส, 1 = ฝนเต็มที่
local nextThunder = os.clock() + 20

local function fmtTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

RunService.RenderStepped:Connect(function(dt)
	local raining = workspace:GetAttribute("Weather") == "Rain"
	local target = raining and 1 or 0
	if level ~= target then
		local step = dt / FADE_TIME
		level = math.clamp(level + (target > level and step or -step), 0, 1)
		rainSound.Volume = RAIN_VOLUME * level
		if level > 0 and not rainSound.IsPlaying then rainSound:Play() end
		if level == 0 and rainSound.IsPlaying then rainSound:Stop() end
		tint.Brightness = -0.06 * level
		tint.Saturation = -0.3 * level
		tint.Contrast = -0.05 * level
		tint.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(205, 215, 232), level)
		if clouds then
			clouds.Cover = baseCover + (0.9 - baseCover) * level
			clouds.Density = baseDensity + (0.85 - baseDensity) * level
			clouds.Color = baseColor:Lerp(Color3.fromRGB(150, 155, 168), level)
		end
	end
	-- ขยับเม็ดฝน
	local want = math.floor(DROP_COUNT * level * dropFactor + 0.5)
	if want > 0 or dropsActive > 0 then
		local camPos = camera.CFrame.Position
		for i = 1, DROP_COUNT do
			if i <= want then
				if i > dropsActive or not dropY[i] then respawn(i, camPos, true) end
				dropY[i] -= speeds[i] * dt
				local xz = dropXZ[i]
				-- ไกลจากกล้องเกิน (เดินไปไกล) หรือตกต่ำเกิน = เกิดใหม่ด้านบน
				if dropY[i] < DROP_BOTTOM or math.abs(xz.X - camPos.X) > DROP_RADIUS or math.abs(xz.Z - camPos.Z) > DROP_RADIUS then
					respawn(i, camPos, false)
					xz = dropXZ[i]
				end
				dropCFs[i] = CFrame.new(xz.X, camPos.Y + dropY[i], xz.Z) * DROP_TILT
			else
				dropCFs[i] = hidden
			end
		end
		workspace:BulkMoveTo(drops, dropCFs, Enum.BulkMoveMode.FireCFrameChanged)
		dropsActive = want
	end
	-- ป้าย + ฟ้าร้อง (เฉพาะตอนฝนตกเต็มที่)
	pill.Visible = raining
	if raining then
		local left = (workspace:GetAttribute("WeatherEndsAt") or os.time()) - os.time()
		pill.Text = "🌧️ ฝนตก · พืชโต +25% · ปลากิน +20% · " .. fmtTime(left)
		if level >= 1 and os.clock() >= nextThunder then
			nextThunder = os.clock() + 25 + math.random() * 30
			task.spawn(lightning)
		end
	end
end)
