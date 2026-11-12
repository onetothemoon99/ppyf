-- Backup 2026-11-12 of StarterPlayer.StarterPlayerScripts.KrathongLakeFx (LocalScript) before the collectible krathongs drift down the stream.
-- To restore: paste everything below these 2 lines back into that script's Source.
-- KrathongLakeFx (2026-11-12): กระทงลอยในทะเลสาบ ฝั่งผู้เล่น (เซิร์ฟเวอร์: ServerScriptService.Krathong.KrathongLakeService)
--   กระทงใน workspace.KrathongLake โยกขึ้นลง/หมุนช้าๆ/ลอยเลื่อนนิดหน่อย บนเครื่องนี้ (เซิร์ฟวางนิ่ง ไม่ส่งตำแหน่งซ้ำ)
--   RemoteEvent KrathongLakeFx (pos, userId, amount) = มีคนเก็บ: วงน้ำ + เสียงน้ำ · คนเก็บเห็น "+เหรียญ" ลอยขึ้น

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local ANIM_DISTANCE = 220
local SPLASH_SOUND = "rbxasset://sounds/impact_water.mp3"

local items = {} -- [model] = { base, phase, drift }

local function ghost(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

local function track(m)
	if items[m] or not m:IsA("Model") then return end
	items[m] = { base = m:GetPivot(), phase = math.random() * math.pi * 2, drift = math.random() * math.pi * 2 }
end

local function ripple(pos, size)
	local ring = Instance.new("Part")
	ring.Name = "LakeKrathongRipple"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(225, 242, 250)
	ring.Transparency = 0.6
	ring.Size = Vector3.new(0.04, 0.6, 0.6)
	ghost(ring)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.04, size, size), Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 1)
end

local function popup(pos, amount)
	local holder = Instance.new("Part")
	holder.Name = "LakeKrathongPopup"
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	ghost(holder)
	holder.Position = pos + Vector3.new(0, 1.5, 0)
	holder.Parent = workspace
	local sound = Instance.new("Sound")
	sound.SoundId = SPLASH_SOUND
	sound.Volume = 0.45
	sound.RollOffMaxDistance = 50
	sound.SoundGroup = SoundService:FindFirstChild("EffectSounds")
	sound.Parent = holder
	sound:Play()
	Debris:AddItem(holder, 3)
	if not amount then return end
	local gui = Instance.new("BillboardGui")
	gui.Adornee = holder
	gui.Size = UDim2.fromOffset(190, 46)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = "🌸 💰 +" .. (tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
	label.TextColor3 = amount >= 500 and Color3.fromRGB(255, 205, 70) or Color3.fromRGB(255, 240, 190)
	label.TextStrokeColor3 = Color3.fromRGB(110, 70, 160)
	label.TextStrokeTransparency = 0.1
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(gui, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.6)
end

task.spawn(function()
	local remote = ReplicatedStorage:WaitForChild("KrathongLakeFx")
	remote.OnClientEvent:Connect(function(pos, userId, amount)
		if typeof(pos) ~= "Vector3" then return end
		local cam = workspace.CurrentCamera
		if cam and (cam.CFrame.Position - pos).Magnitude > 200 then return end
		ripple(Vector3.new(pos.X, pos.Y - 0.3, pos.Z), 6)
		popup(pos, userId == player.UserId and tonumber(amount) or nil)
	end)
end)

local folderConns = {}
local function hookFolder(folder)
	for _, c in ipairs(folderConns) do c:Disconnect() end
	table.clear(folderConns)
	table.clear(items)
	if not folder then return end
	for _, m in ipairs(folder:GetChildren()) do track(m) end
	table.insert(folderConns, folder.ChildAdded:Connect(function(m) task.defer(track, m) end))
	table.insert(folderConns, folder.ChildRemoved:Connect(function(m) items[m] = nil end))
end
workspace.ChildAdded:Connect(function(c) if c.Name == "KrathongLake" then hookFolder(c) end end)
workspace.ChildRemoved:Connect(function(c) if c.Name == "KrathongLake" then hookFolder(nil) end end)
if workspace:FindFirstChild("KrathongLake") then hookFolder(workspace.KrathongLake) end

RunService.RenderStepped:Connect(function()
	if not next(items) then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	local t = os.clock()
	for m, it in pairs(items) do
		if m.Parent and (it.base.Position - camPos).Magnitude < ANIM_DISTANCE then
			local p = it.phase
			local offset = CFrame.new(math.sin(t * 0.25 + it.drift) * 0.8, math.sin(t * 1.6 + p) * 0.08, math.cos(t * 0.2 + it.drift) * 0.8)
			m:PivotTo(offset * it.base * CFrame.Angles(math.sin(t * 1.3 + p) * 0.05, t * 0.15 + p, math.cos(t * 1.1 + p) * 0.05))
		end
	end
end)
