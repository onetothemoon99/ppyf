-- BACKUP 2026-11-12 of game.StarterPlayer.StarterPlayerScripts.PlatypusFx (LocalScript, Studio) before "hide the candle stick (CoinHeld) with the krathong".
-- Restore: copy everything BELOW the "==== SOURCE ====" line into that script's Source in Studio.
-- ==== SOURCE ====
-- PlatypusFx: เอฟเฟกต์ตุ่นนักอนุรักษ์ (2026-11-06) ทำฝั่งผู้เล่นล้วน เซิร์ฟเวอร์ส่งแค่ Attribute บนตัวสัตว์ (Abilities.KrathongCollector / PetController)
--   KrathongWork = "x,y,z;เวลาเริ่ม;ความยาว" -> ดำลงน้ำ: วงระลอก + เสียงน้ำ + ฟองอากาศระหว่างงม แล้วน้ำกระเซ็นตอนโผล่ (2026-11-11 เดิมมีกระทงจิ๋วลอยเข้าหาตัว เอาออกแล้ว)
--   KrathongGot = "เวลา;วิที่ถือ" -> โผล่ขึ้นมาถือกระทงในมือ (2026-11-11) · ท่าดำงมอยู่ที่ PetAnimator (WorkAnim "dive")
--   KrathongCoin = "จำนวน;เวลา" -> ตัวเลข +เหรียญลอยขึ้น เห็นเฉพาะเจ้าของ (ไม่ใช้แจ้งเตือนใหญ่ ทุก 15 วิจะรก) + กระทงในมือหายพร้อมประกาย (มาหลัง KrathongGot 5 วิ)
--   Swimming = วงน้ำรอบตัวตอนว่าย
-- กราฟิก FxOff = ไม่วาดเอฟเฟกต์ แต่เจ้าของยังเห็นตัวเลขเหรียญ · โหมดถ่ายภาพซ่อนสัตว์ (PhotoHidePets) = ปิด

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GraphicsConfig = require(ReplicatedStorage:WaitForChild("GraphicsConfig"))
local PetRenderState = require(ReplicatedStorage:WaitForChild("PetRenderState"))

local player = Players.LocalPlayer
local MAX_DISTANCE = 120
local RIPPLE_EVERY = 0.7
local SPLASH_SOUND = "rbxasset://sounds/impact_water.mp3" -- เสียงเดียวกับทุ่นตกปลา

local HOLD_TIME = 5 -- ถือกระทงค้างกี่วิหลังงมขึ้นมา (ผู้ใช้สั่ง 2026-11-06: อยู่เฉยๆ ไม่ถือ) · 2026-11-11: ถือ 5 วิแล้วค่อยได้เหรียญ (เวลาจริงมาจาก KrathongGot) ค่านี้ = เผื่อไว้ ถ้าไม่มี KrathongCoin มาปิด

local pets = {} -- [model] = { conns, nextRipple, holdToken }

local function fxOff()
	return player:GetAttribute("PhotoHidePets") == true or GraphicsConfig.Get(player:GetAttribute(GraphicsConfig.ATTRIBUTE)).FxOff == true
end

local function ghost(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

local function ripple(pos, size)
	-- แผ่นวงน้ำจางๆ กางออกแล้วหาย (2026-11-06 ลอง CylinderHandleAdornment กับ SurfaceGui แล้ว ขึ้นบนผิวน้ำไม่ครบ/ไม่ขึ้น แผ่น Part ขึ้นแน่นอน)
	local ring = Instance.new("Part")
	ring.Name = "KrathongRipple"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(225, 242, 250)
	ring.Transparency = 0.72
	ring.Size = Vector3.new(0.04, 0.5, 0.5)
	ghost(ring)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.04, size, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 1)
end

local function splashSound(pos)
	local holder = Instance.new("Part")
	holder.Name = "KrathongSound"
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	ghost(holder)
	holder.Position = pos
	holder.Parent = workspace
	local sound = Instance.new("Sound")
	sound.SoundId = SPLASH_SOUND
	sound.Volume = 0.35
	sound.RollOffMaxDistance = 45
	sound.SoundGroup = SoundService:FindFirstChild("EffectSounds")
	sound.Parent = holder
	sound:Play()
	Debris:AddItem(holder, 3)
end

-- กระทงจิ๋วลอยจากข้างตัวตุ่นบนน้ำเข้าหาตัว แล้วหายไปตอนเก็บ
local function playWork(model, value)
	if type(value) ~= "string" or fxOff() then return end
	local x, y, z, startAt, length = value:match("^([%-%d%.]+),([%-%d%.]+),([%-%d%.]+);([%d%.]+);([%d%.]+)$")
	if not x then return end
	local pos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
	length = math.clamp(tonumber(length), 0.3, 6)
	local remaining = length - (workspace:GetServerTimeNow() - tonumber(startAt))
	if remaining < 0.2 then return end
	if (pos - workspace.CurrentCamera.CFrame.Position).Magnitude > MAX_DISTANCE then return end

	-- มุดลงน้ำ
	ripple(pos, 5)
	splashSound(pos)
	-- ฟองอากาศผุดขึ้นตรงที่ตุ่นงมอยู่
	task.spawn(function()
		local untilAt = os.clock() + remaining - 0.25
		while os.clock() < untilAt and model.Parent do
			local cf = PetRenderState[model] or model:GetPivot()
			local base = Vector3.new(cf.Position.X, pos.Y, cf.Position.Z)
			local bubble = Instance.new("Part")
			bubble.Name = "KrathongBubble"
			bubble.Shape = Enum.PartType.Ball
			bubble.Material = Enum.Material.SmoothPlastic
			bubble.Color = Color3.fromRGB(235, 248, 255)
			bubble.Transparency = 0.35
			local s = math.random(14, 26) / 100
			bubble.Size = Vector3.new(s, s, s)
			ghost(bubble)
			bubble.Position = base + Vector3.new(math.random(-50, 50) / 100, -0.1, math.random(-50, 50) / 100)
			bubble.Parent = workspace
			TweenService:Create(bubble, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = bubble.Position + Vector3.new(0, 0.45, 0),
				Transparency = 1,
			}):Play()
			Debris:AddItem(bubble, 0.6)
			task.wait(0.12)
		end
	end)
	-- โผล่ขึ้นมา (ตรงกับตอนเซิร์ฟเวอร์ตั้ง KrathongGot)
	task.delay(remaining, function()
		if not model.Parent or fxOff() then return end
		local cf = PetRenderState[model] or model:GetPivot()
		local at = Vector3.new(cf.Position.X, pos.Y, cf.Position.Z)
		ripple(at, 4)
		splashSound(at)
	end)
end

local function commas(n)
	return (tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function playCoin(model, value)
	if model:GetAttribute("OwnerUserId") ~= player.UserId or type(value) ~= "string" then return end
	local amount = tonumber(value:match("^(%d+);"))
	local head = model:FindFirstChild("Head")
	if not amount or not head then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "KrathongCoinPopup"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(170, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 100
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = "💰 +" .. commas(amount)
	label.TextColor3 = amount >= 600 and Color3.fromRGB(255, 205, 70) or Color3.fromRGB(255, 240, 190)
	label.TextStrokeColor3 = Color3.fromRGB(110, 70, 160)
	label.TextStrokeTransparency = 0.1
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(gui, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.6)
end

-- กระทงในมือ: ซ่อนเป็นค่าตั้งต้น โชว์ตอนได้กระทง (ทำฝั่งผู้เล่น เห็นทุกคนเพราะทุกเครื่องรับ Attribute เดียวกัน) ตู้โชว์และรูปในเมนูยังถือกระทงตามเทมเพลต
local function setHolding(model, on)
	local krathong = model:FindFirstChild("KrathongHeld")
	local flame = model:FindFirstChild("CandleFlame")
	if krathong then krathong.Transparency = on and 0 or 1 end
	if flame then
		flame.Transparency = on and 0 or 1
		local sparks = flame:FindFirstChildOfClass("ParticleEmitter")
		if sparks then sparks.Enabled = on end
	end
end

-- hold = ถือกี่วิ (เผื่อเหรียญไม่มา จะเลิกถือเองหลังเวลานี้ +1 วิ)
local function showHeld(model, rec, hold)
	rec.holdToken = (rec.holdToken or 0) + 1
	local token = rec.holdToken
	setHolding(model, true)
	task.delay((hold or HOLD_TIME) + 1, function()
		if pets[model] == rec and rec.holdToken == token then setHolding(model, false) end
	end)
end

-- ได้เหรียญ = กระทงในมือหายพร้อมประกายเทียน
local function releaseHeld(model, rec)
	rec.holdToken = (rec.holdToken or 0) + 1
	local flame = model:FindFirstChild("CandleFlame")
	local sparks = flame and flame:FindFirstChildOfClass("ParticleEmitter")
	if sparks and not fxOff() then pcall(function() sparks:Emit(14) end) end
	setHolding(model, false)
end

local function remove(model)
	local rec = pets[model]
	if not rec then return end
	for _, conn in ipairs(rec.conns) do conn:Disconnect() end
	pets[model] = nil
end

local function add(model)
	if pets[model] or model:GetAttribute("PetId") ~= "Platypus" then return end
	local rec = { conns = {}, nextRipple = 0 }
	setHolding(model, false)
	table.insert(rec.conns, model:GetAttributeChangedSignal("KrathongWork"):Connect(function()
		playWork(model, model:GetAttribute("KrathongWork"))
	end))
	table.insert(rec.conns, model:GetAttributeChangedSignal("KrathongGot"):Connect(function()
		local v = model:GetAttribute("KrathongGot")
		if type(v) ~= "string" then return end
		local startAt, hold = v:match("^([%d%.]+);([%d%.]+)$") -- (ห้ามเขียน x and v:match() ได้ค่าแค่ตัวแรก)
		startAt, hold = tonumber(startAt), tonumber(hold)
		if not (startAt and hold) then return end
		local left = hold - (workspace:GetServerTimeNow() - startAt)
		if left > 0.2 then showHeld(model, rec, left) end
	end))
	table.insert(rec.conns, model:GetAttributeChangedSignal("KrathongCoin"):Connect(function()
		releaseHeld(model, rec)
		playCoin(model, model:GetAttribute("KrathongCoin"))
	end))
	pets[model] = rec
end

local function consider(obj)
	if obj:IsA("Model") then
		task.delay(0.5, function()
			if obj.Parent == workspace then add(obj) end
		end)
	end
end
for _, obj in ipairs(workspace:GetChildren()) do consider(obj) end
workspace.ChildAdded:Connect(consider)
workspace.ChildRemoved:Connect(remove)

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for model, rec in pairs(pets) do
		if model:GetAttribute("Swimming") == true and now >= rec.nextRipple then
			rec.nextRipple = now + RIPPLE_EVERY
			local cf = PetRenderState[model] or model:GetPivot()
			if not fxOff() and (cf.Position - workspace.CurrentCamera.CFrame.Position).Magnitude < MAX_DISTANCE then
				ripple(cf.Position - Vector3.new(0, 0.15, 0), 3.5)
			end
		end
	end
end)
