-- BACKUP of StarterPlayer.StarterPlayerScripts.FishingFx taken 2026-11-21 before the B3 per-frame lowest-graphics change.
-- Restore: in Studio open StarterPlayer.StarterPlayerScripts.FishingFx, select all, paste everything BELOW the next line.
-- ===== original Source (10701 bytes, hash 186289396) =====
-- FishingFx: เอฟเฟกต์ตกปลาที่ทุกคนเห็น (เซิร์ฟเวอร์ FishingSystem ส่ง FishingFx มา แต่ละเครื่องเล่นเองให้ลื่น)
--   autoReel: ตกออโต้ได้ปลา -> ยกคันเบ็ด + ทุ่นลอยขึ้นจากน้ำพร้อมปลาห้อยดิ้น -> ปลาหดหายเข้ากระเป๋า -> เหวี่ยงทุ่นกลับลงจุดเดิม
--   manualReel: ชนะมินิเกม -> ท่าเดียวกันแต่ไม่เหวี่ยงกลับ (ตกเองจบทีละตัว เซิร์ฟเวอร์ลบทุ่นตามหลัง)
--   ขยับทุ่น (ของเซิร์ฟเวอร์) เฉพาะบนเครื่องเรา จบแล้ววางคืนตำแหน่งเดิม ไม่กระทบการตกปลาจริง

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local fxRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("FishingFx")
local previewFolder = ReplicatedStorage:WaitForChild("ItemPreviewModels")

local VIEW_DISTANCE = 150 -- ไกลกว่านี้ไม่ต้องเล่น
local SPLASH_SOUND = "rbxasset://sounds/impact_water.mp3"
local fishingSoundGroup = SoundService:FindFirstChild("EffectSounds")
local PULL_TIME, HANG_END, POP_START, RECAST_TIME = 0.6, 1.5, 1.25, 0.65
local HANG_DROP = 2.2 -- ทุ่นห้อยต่ำกว่าปลายคันเท่านี้

local function splash(pos, amount, volume)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Color = ColorSequence.new(Color3.fromRGB(235, 250, 255), Color3.fromRGB(150, 210, 245))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.4, 0.75)
	e.Speed = NumberRange.new(6, 11)
	e.SpreadAngle = Vector2.new(35, 35)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -30, 0)
	e.LightEmission = 0.3
	e.Parent = p
	e:Emit(amount or 20)
	local sound = Instance.new("Sound")
	sound.SoundId = SPLASH_SOUND
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = 1.1 + math.random() * 0.2
	sound.RollOffMaxDistance = 60
	sound.SoundGroup = fishingSoundGroup
	sound.Parent = p
	sound:Play()
	Debris:AddItem(p, 2)
end

-- ยก/วางคันเบ็ด: หมุนข้อต่อมือจับ (RightGrip) เฉพาะบนเครื่องเรา
local function rodTilt(character, up)
	local grip = character and character:FindFirstChild("RightGrip", true)
	if not (grip and grip:IsA("JointInstance")) then return end
	local base = grip:GetAttribute("BaseC1")
	if not base then
		base = grip.C1
		grip:SetAttribute("BaseC1", base)
	end
	local target = up and (base * CFrame.Angles(math.rad(-40), 0, 0)) or base -- ลบ = ปลายคันเชิดขึ้น
	TweenService:Create(grip, TweenInfo.new(up and 0.25 or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C1 = target }):Play()
end

local function arc(a, b, t, height)
	return a:Lerp(b, t) + Vector3.new(0, math.sin(t * math.pi) * height, 0)
end

local playing = {} -- [bobber] = true

local function reelUp(data, recast)
	local bobber = data.bobber
	if not (bobber and bobber.Parent) or playing[bobber] then return end
	local landing = data.landing
	local camera = workspace.CurrentCamera
	if typeof(landing) ~= "Vector3" or (camera.CFrame.Position - landing).Magnitude > VIEW_DISTANCE then return end
	local owner = Players:GetPlayerByUserId(data.userId or 0)
	local character = owner and owner.Character
	local tip
	if data.pet then
		-- สัตว์ช่วยตกปลา: ใช้ปลายเบ็ดจิ๋วในมือสัตว์ ไม่ยกคันของเจ้าของ
		tip = typeof(data.tip) == "Instance" and data.tip or nil
		character = nil
	else
		local tool = character and character:FindFirstChildOfClass("Tool")
		tip = tool and tool:FindFirstChild("RodTip", true)
	end
	if not tip then return end
	local hangDrop = data.pet and 1.3 or HANG_DROP
	local fishSize = data.pet and 0.8 or 1.2
	playing[bobber] = true

	-- ปลาห้อยปลายสาย (โมเดลเดียวกับรูปในกระเป๋า)
	local fish, fishLen, fishScale
	local template = data.fishId and previewFolder:FindFirstChild("Fish_" .. data.fishId)
	if template then
		fish = template:Clone()
		for _, d in ipairs(fish:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanQuery = false d.CanTouch = false end
		end
		local _, size = fish:GetBoundingBox()
		fishLen = size.X
		fishScale = fish:GetScale()
		fish.Parent = workspace
	end

	splash(landing, 26, 0.6)
	if character then rodTilt(character, true) end
	local tilted = character ~= nil
	local t0 = os.clock()
	local slow = RunService:IsStudio() and workspace:GetAttribute("FishFxSlow") or 1
	local conn
	local function finish()
		if conn then conn:Disconnect() conn = nil end
		if fish then fish:Destroy() fish = nil end
		if tilted then rodTilt(character, false) end
		if recast and bobber.Parent then bobber:PivotTo(CFrame.new(landing)) end
		playing[bobber] = nil
	end
	conn = RunService.RenderStepped:Connect(function()
		if not (bobber.Parent and tip.Parent) then finish() return end
		local t = (os.clock() - t0) / slow
		local hang = tip.WorldPosition - Vector3.new(0, hangDrop, 0)
		local pos
		if t < PULL_TIME then
			-- ดึงขึ้น: พุ่งจากน้ำเป็นโค้งเข้าหาปลายคัน
			local a = t / PULL_TIME
			pos = arc(landing, hang, 1 - (1 - a) ^ 2, 2.5)
		elseif t < HANG_END then
			-- ห้อยแกว่งที่ปลายคัน
			pos = hang + Vector3.new(math.sin(t * 6) * 0.25, 0, 0)
		elseif not recast then
			-- ตกเอง: จบที่ปลายคัน (ทุ่นถูกลบตามหลัง)
			finish()
			return
		elseif t < HANG_END + RECAST_TIME then
			-- เหวี่ยงกลับลงจุดเดิม
			if tilted then tilted = false rodTilt(character, false) end
			local a = (t - HANG_END) / RECAST_TIME
			pos = arc(hang, landing, a * a, 3)
		else
			splash(landing, 14, 0.35)
			finish()
			return
		end
		bobber:PivotTo(CFrame.new(pos))
		if fish then
			if t >= HANG_END then
				fish:Destroy() fish = nil
			else
				-- ห้อยหัวขึ้น (แกนยาว X -> แนวตั้ง) ดิ้นไปมา ช่วงท้ายหดหายเข้ากระเป๋า
				local s = 1
				if t > POP_START then s = math.max(0.05, 1 - (t - POP_START) / (HANG_END - POP_START)) end
				fish:ScaleTo(fishScale * fishSize * s)
				local wiggle = CFrame.Angles(math.sin(t * 22) * 0.35, 0, 0)
				fish:PivotTo(CFrame.new(pos - Vector3.new(0, 0.25 + fishLen * 0.6 * s, 0)) * CFrame.Angles(0, t * 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)) * wiggle)
			end
		end
	end)
end

-- ============ สายเบ็ดหย่อนตามน้ำหนัก (2026-10-08) ============
-- เดิม Beam โค้งตามแกน RodTip (CurveSize0 -1.5) เลยดูเป็นลวดแข็งโก่งออกตามท่าจับคัน
-- ตอนนี้ทุกเฟรม: สายออกจากปลายคันแล้วหย่อนลง แตะน้ำแนวราบตอนถึงทุ่น / ทุ่นห้อยใต้ปลายคัน = สายตึงตรง
-- หมุนแกน Attachment เฉพาะบนเครื่องเรา (ไม่กระทบเซิร์ฟเวอร์)
local LINE_BEAMS = { FishingLine = true, FishingLineAura = true }
local DOWN = Vector3.new(0, -1, 0)
local lineBobbers = {} -- [bobber model] = true
local function trackBobber(m)
	if m:IsA("Model") and (m.Name:match("_Bobber$") or m.Name:match("_PetBobber$")) then lineBobbers[m] = true end
end
for _, m in ipairs(workspace:GetChildren()) do trackBobber(m) end
workspace.ChildAdded:Connect(trackBobber)
workspace.ChildRemoved:Connect(function(m) lineBobbers[m] = nil end)

RunService.RenderStepped:Connect(function()
	local camPos = workspace.CurrentCamera.CFrame.Position
	local now = os.clock()
	for m in pairs(lineBobbers) do
		if not m.Parent then lineBobbers[m] = nil continue end
		local ball = m.PrimaryPart -- ชิ้นส่วนอาจยังมาไม่ครบตอนโมเดลเพิ่งเข้ามา รอเฟรมถัดไป
		if not ball then continue end
		local beams = {}
		for _, b in ipairs(ball:GetChildren()) do
			if b:IsA("Beam") and LINE_BEAMS[b.Name] then table.insert(beams, b) end
		end
		local a0, a1 = beams[1] and beams[1].Attachment0, beams[1] and beams[1].Attachment1
		if not (a0 and a1 and a0.Parent and a1.Parent) then continue end
		local p0, p3 = a0.WorldPosition, a1.WorldPosition
		if (camPos - p3).Magnitude > VIEW_DISTANCE then continue end
		local delta = p3 - p0
		local flat = delta * Vector3.new(1, 0, 1)
		local h = flat.Magnitude
		local c0, c1 = 0, 0
		if h > 0.6 then
			local dir = flat.Unit
			local drop = math.max(0, -delta.Y)
			local sway = 1 + math.sin(now * 1.3 + h) * 0.06 -- ลมพัดสายไหวเบาๆ
			local p1 = p0 + dir * h * 0.22 + DOWN * (drop * 0.35 + h * 0.06) * sway
			local p2 = p3 - dir * h * 0.38
			a0.WorldAxis = (p1 - p0).Unit
			a1.WorldAxis = dir
			c0, c1 = (p1 - p0).Magnitude, (p3 - p2).Magnitude
		end
		for _, b in ipairs(beams) do
			b.CurveSize0, b.CurveSize1 = c0, c1
			if b.Segments < 20 then b.Segments = 20 end
		end
	end
end)

fxRemote.OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	if kind == "autoReel" then
		reelUp(data, true)
	elseif kind == "manualReel" then
		reelUp(data, false)
	end
end)
