-- BACKUP of game.StarterPlayer.StarterPlayerScripts.FishingOtterFx (full Source, 6716 bytes) taken 2026-11-26 before the Sakura Jellyfish rod.
-- Restore: in Studio open game.StarterPlayer.StarterPlayerScripts.FishingOtterFx, select all, paste everything below this header.
-- FishingOtterFx: นาก NPC 2 ตัวยืนถือเบ็ดโชว์หน้าตู้เบ็ดผีเสื้อ / เบ็ดผึ้งน้อย (workspace.FishingOtters)
--   2026-10-08: เปลี่ยนจากตกปลาเป็นยืนถือเบ็ดเฉยๆ (ผู้เล่นขอ) · ทำบนเครื่องผู้เล่นแต่ละคน ตกแต่งอย่างเดียว
--   ป้ายชื่อตามภาษา · นากโยกตัวเบาๆ (คันเบ็ดขยับตาม) · วงเวทใต้เท้าหมุน เฉพาะตัวที่มี CirclePad (ผึ้งน้อยเท่านั้น
--   เพราะเบ็ดผีเสื้อจริงไม่มีวงใต้เท้า)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local tr, lang = require(ReplicatedStorage:WaitForChild("Localization")).Tr()

local NEAR = 120
local PhoenixFlight = require(ReplicatedStorage:WaitForChild("PhoenixFlight")) -- 2026-11-20 นกฟีนิกซ์เกาะไหล่นาก บินเป็นพักๆ (แบบเดียวกับเบ็ดจริง)
local OTTER_PERCH = Vector3.new(0.75, 1.15, 0.15)
local gate = require(ReplicatedStorage:WaitForChild("FxThrottle")).Gate() -- ระดับต่ำ = โยกน้อยครั้งลง / ต่ำสุด = ยืนนิ่ง (2026-10-24)

local npcs = {} -- [model] = state

-- 2026-11-19 นากที่ตั้ง Attribute PhoenixBird = true (Otter_Phoenix): นกฟีนิกซ์ไฟบินวนรอบตัว เหมือนตอนผู้เล่นถือเบ็ดจริง (SunBeeAuraFx) แต่วงเล็กกว่า
-- 2026-11-19 นากที่ตั้ง Attribute FrogDragonfly = true (Otter_Froggy): แมลงปอบินวนแบบพุ่ง-หยุดค้าง (dart) เหมือนเบ็ดกบน้อยจริง
local function makeBird(npc, folderName, modelName, dart)
	local fxFolder = ReplicatedStorage:FindFirstChild(folderName or "PhoenixFx")
	local template = fxFolder and fxFolder:FindFirstChild(modelName or "Bird")
	if not template then return nil end
	local model = template:Clone()
	model.Name = "Display" .. (modelName or "Bird")
	model.Parent = npc
	local b = { model = model, root = model.PrimaryPart, parts = {}, dart = dart,
		sL = model:GetAttribute("ShoulderL") or Vector3.new(-0.12, 0.08, -0.04), sR = model:GetAttribute("ShoulderR") or Vector3.new(0.12, 0.08, -0.04) }
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then table.insert(b.parts, { part = p, rel = p.CFrame, piece = p:GetAttribute("Piece") or "Root" }) end
	end
	return b
end
local function moveBird(b, center, tt, look)
	if not b.dart then
		local cam = workspace.CurrentCamera
		local cf, flap = PhoenixFlight.Step(b, center, look or Vector3.new(0, 0, 1), cam and cam.CFrame.Position, tt, OTTER_PERCH, 0.8)
		local wingL = cf * CFrame.new(b.sL) * CFrame.Angles(0, 0, flap) * CFrame.new(-b.sL)
		local wingR = cf * CFrame.new(b.sR) * CFrame.Angles(0, 0, -flap) * CFrame.new(-b.sR)
		for _, e in ipairs(b.parts) do
			e.part.CFrame = ((e.piece == "WingL" and wingL) or (e.piece == "WingR" and wingR) or cf) * e.rel
		end
		return
	end
	local a = b.dart and (tt * 1.5 + (1.5 / 1.3) * math.sin(tt * 1.3)) or tt * 1.3
	local r = b.dart and (2.5 + 0.35 * math.sin(tt * 0.8)) or 2.8
	local pos = center + Vector3.new(math.cos(a) * r, (b.dart and 1.6 or 1.3) + 0.3 * math.sin(tt * 2.1), math.sin(a) * r)
	local dir = b.prev and (pos - b.prev) or Vector3.new(-math.sin(a), 0, math.cos(a))
	if dir.Magnitude < 1e-3 then dir = b.lastDir or Vector3.new(-math.sin(a), 0, math.cos(a)) end
	b.lastDir = dir
	b.prev = pos
	local toCenter = ((center - pos) * Vector3.new(1, 0, 1)).Unit
	local cf = CFrame.lookAt(pos, pos + dir.Unit, (Vector3.yAxis + toCenter * 0.45).Unit)
	local flap = b.dart and (math.sin(tt * 45) * 0.35) or (math.sin(tt * 11) * 0.6 + 0.1)
	local wingL = cf * CFrame.new(b.sL) * CFrame.Angles(0, 0, flap) * CFrame.new(-b.sL)
	local wingR = cf * CFrame.new(b.sR) * CFrame.Angles(0, 0, -flap) * CFrame.new(-b.sR)
	for _, e in ipairs(b.parts) do
		e.part.CFrame = ((e.piece == "WingL" and wingL) or (e.piece == "WingR" and wingR) or cf) * e.rel
	end
end

local function setup(npc)
	if npcs[npc] then return end
	local rodId = npc:GetAttribute("RodId")
	local otter = npc:FindFirstChild("Otter")
	local rod = npc:FindFirstChild("Rod")
	if not (rodId and otter and rod and otter.PrimaryPart) then return end
	local tag = npc:FindFirstChild("NameTag")
	if tag then
		local r = Config.Rods[rodId]
		tag.Rod.Text = (r and r.Icon or "🎣") .. " " .. Config.RodName(rodId, lang)
		tag.Who.Text = tr("🦦 นากโชว์เบ็ด · ซื้อได้ที่ตู้นี้", "🦦 Rod model · buy it at this case")
	end
	local pad = npc:FindFirstChild("CirclePad")
	local gui = pad and pad:FindFirstChildWhichIsA("SurfaceGui")
	npcs[npc] = {
		otter = otter, rod = rod,
		otterPivot = otter:GetPivot(), rodPivot = rod:GetPivot(),
		circle = gui and gui:FindFirstChild("Circle"),
		bird = (npc:GetAttribute("PhoenixBird") and makeBird(npc, "PhoenixFx", "Bird"))
			or (npc:GetAttribute("FrogDragonfly") and makeBird(npc, "FrogFx", "Dragonfly", true)) or nil,
	}
end

local function scan()
	local root = workspace:FindFirstChild("FishingOtters")
	if not root then return end
	for _, npc in ipairs(root:GetChildren()) do
		if npc:IsA("Model") then setup(npc) end
	end
end
scan()
task.spawn(function()
	while true do task.wait(2) scan() end
end)

local clock = 0
RunService.RenderStepped:Connect(function(dt)
	dt = gate(dt)
	if not dt then return end
	clock += dt
	local cam = workspace.CurrentCamera
	for npc, st in pairs(npcs) do
		if not (npc.Parent and st.otter.Parent) then npcs[npc] = nil continue end
		local near = cam and (cam.CFrame.Position - st.otterPivot.Position).Magnitude <= NEAR
		if not near then continue end
		if st.circle then st.circle.Rotation = (clock * 20) % 360 end
		local seed = st.otterPivot.Position.X
		local sway = CFrame.Angles(0, 0, math.sin(clock * 1.6 + seed) * 0.035)
		local lift = Vector3.new(0, math.sin(clock * 2.2 + seed) * 0.04, 0)
		st.otter:PivotTo((st.otterPivot + lift) * sway)
		st.rod:PivotTo(st.rodPivot + lift)
		if st.bird then moveBird(st.bird, st.otterPivot.Position, clock + seed, st.otterPivot.LookVector) end
	end
end)
