-- BACKUP of game.StarterPlayer.StarterPlayerScripts.FishingOtterFx (Studio Source, byte-exact, len 3252 hash 1622737371)
-- Restore: paste everything below this header into game.StarterPlayer.StarterPlayerScripts.FishingOtterFx.Source in Studio.
-- FishingOtterFx: นาก NPC 2 ตัวยืนถือเบ็ดโชว์หน้าตู้เบ็ดผีเสื้อ / เบ็ดผึ้งน้อย (workspace.FishingOtters)
--   2026-10-08: เปลี่ยนจากตกปลาเป็นยืนถือเบ็ดเฉยๆ (ผู้เล่นขอ) · ทำบนเครื่องผู้เล่นแต่ละคน ตกแต่งอย่างเดียว
--   ป้ายชื่อตามภาษา · นากโยกตัวเบาๆ (คันเบ็ดขยับตาม) · วงเวทใต้เท้าหมุน เฉพาะตัวที่มี CirclePad (ผึ้งน้อยเท่านั้น
--   เพราะเบ็ดผีเสื้อจริงไม่มีวงใต้เท้า)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local tr, lang = require(ReplicatedStorage:WaitForChild("Localization")).Tr()

local NEAR = 120
local gate = require(ReplicatedStorage:WaitForChild("FxThrottle")).Gate() -- ระดับต่ำ = โยกน้อยครั้งลง / ต่ำสุด = ยืนนิ่ง (2026-10-24)

local npcs = {} -- [model] = state

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
	end
end)
