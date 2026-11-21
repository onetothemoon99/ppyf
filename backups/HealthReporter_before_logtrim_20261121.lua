-- BACKUP of StarterPlayer.StarterPlayerScripts.HealthReporter taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open StarterPlayer.StarterPlayerScripts.HealthReporter, select all, paste everything BELOW the next line.
-- ===== original Source (3291 bytes, hash 262348738) =====
-- HealthReporter: ส่ง FPS / หน่วยความจำฝั่งผู้เล่นให้เซิร์ฟเวอร์ทุก 5 วินาที
-- DisconnectLogger เก็บค่าล่าสุดไว้ แล้วเขียนสรุปลง log ตอนผู้เล่นออก (ใช้ไล่สาเหตุ error 277)
-- 2026-10-24 วัดผลกราฟิกบนเครื่องจริง: ส่งเพิ่ม (ตัวที่ 4) = { tris, draws, cpu, gpu (ms), lvl = ระดับกราฟิกในเกม, dev = mobile/pc/console, rq = ระดับกราฟิกของ Roblox 0-10 }
--   tris/draws/cpu/gpu = ค่าเฉลี่ยจากการอ่าน Stats วินาทีละครั้ง · DisconnectLogger + ServerHealthLogger สรุปแยกตามอุปกรณ์/ระดับ

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ReportHealth", 30)
if not remote then return end

local INTERVAL = 5
local frames = 0
local worstFrame = 0
RunService.RenderStepped:Connect(function(dt)
	frames += 1
	if dt > worstFrame then worstFrame = dt end
end)

-- เกณฑ์เดียวกับ GraphicsQuality / DeviceReporter
local function detectDevice()
	if GuiService:IsTenFootInterface() then return "console" end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then return "mobile" end
	return "pc"
end

local function robloxQuality()
	local q = 0
	pcall(function() q = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value end)
	return q -- 0 = อัตโนมัติ
end

local render = { n = 0, tris = 0, draws = 0, cpu = 0, gpu = 0 }
local function sampleRender()
	pcall(function()
		local tris, draws, cpu, gpu = Stats.SceneTriangleCount, Stats.SceneDrawcallCount, Stats.RenderCPUFrameTime, Stats.RenderGPUFrameTime
		render.tris += tris
		render.draws += draws
		render.cpu += cpu
		render.gpu += gpu
		render.n += 1
	end)
end

local function takeRender()
	local n = math.max(render.n, 1)
	local r = {
		tris = math.floor(render.tris / n),
		draws = math.floor(render.draws / n),
		cpu = math.floor(render.cpu / n * 10 + 0.5) / 10,
		gpu = math.floor(render.gpu / n * 10 + 0.5) / 10,
		lvl = Players.LocalPlayer:GetAttribute("GraphicsQuality"),
		dev = detectDevice(),
		rq = robloxQuality(),
	}
	render.n, render.tris, render.draws, render.cpu, render.gpu = 0, 0, 0, 0, 0
	return r
end

local lastAt = os.clock()
while true do
	for _ = 1, INTERVAL do
		task.wait(1)
		sampleRender()
	end
	local now = os.clock()
	local elapsed = now - lastAt
	lastAt = now
	local fps = math.floor(frames / math.max(elapsed, 0.001) + 0.5)
	local worstMs = math.floor(worstFrame * 1000 + 0.5)
	frames = 0
	worstFrame = 0
	local memMb = 0
	pcall(function() memMb = math.floor(Stats:GetTotalMemoryUsageMb()) end)
	remote:FireServer(fps, worstMs, memMb, takeRender())
end
