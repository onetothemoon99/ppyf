-- BACKUP 2026-11-16 of game.ServerScriptService.WarpService (Script) before "stream destination first" change.
-- Restore: open ServerScriptService.WarpService in Studio and replace its whole Source with everything BELOW the "==== SOURCE ====" line.
-- ==== SOURCE ====
-- WarpService: พาผู้เล่นวาปไปจุดใน ReplicatedStorage.WarpConfig (ปุ่ม 🧭 ฝั่งผู้เล่น = WarpGui)
-- ผู้เล่นส่งมาแค่ "รหัสจุด" เซิร์ฟเวอร์เช็กรหัส/คูลดาวน์/ตัวละครยังมีชีวิต แล้วหาพื้นจริงใต้จุดนั้นด้วยเรย์ก่อนวาง (ไม่ฝังพื้น/ไม่ตกน้ำ)
-- ตกปลาอยู่: ย้ายออกไปไกลทุ่น ระบบตกปลาเก็บเบ็ดให้เอง (toofar) ถ้าเปิดออโต้ + ถือเบ็ดอยู่ ฝั่งผู้เล่นจะเหวี่ยงเบ็ดที่จุดใหม่ต่อให้ (หันหน้าไปทางน้ำแล้ว)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("WarpConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local function say(player, th, en) return Localization.Pick(Localization.GetLanguage(player), th, en) end
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local warpRequest = remoteEvents:FindFirstChild("WarpRequest")
if not warpRequest then
	warpRequest = Instance.new("RemoteEvent")
	warpRequest.Name = "WarpRequest"
	warpRequest.Parent = remoteEvents
end

local lastWarp = {} -- [player] = os.clock()

-- นั่งอยู่แล้ววาป: SeatWeld ทำให้ที่นั่ง (แม้ Anchored) เป็นก้อนเดียวกับตัวละคร PivotTo จะลากที่นั่งล่องหนไปค้างที่จุดวาป
-- (คนต่อไปที่วาปมาชนแล้วนั่งเอง บัค 2026-10-08) จึงต้องตัดรอยเชื่อมกับที่นั่งก่อนย้ายตัวเสมอ
-- คืนค่า true = เพิ่งลุกจากที่นั่ง (ต้องรอเครื่องผู้เล่นรับรู้ก่อน ไม่งั้นตำแหน่งที่เครื่องผู้เล่นส่งมาจะทับการวาปครั้งแรก)
local function leaveSeat(character, humanoid)
	local seat = humanoid.SeatPart
	if seat then
		for _, j in ipairs(seat:GetChildren()) do
			if (j:IsA("JointInstance") or j:IsA("WeldConstraint"))
				and ((j.Part0 and j.Part0:IsDescendantOf(character)) or (j.Part1 and j.Part1:IsDescendantOf(character))) then
				j:Destroy()
			end
		end
	end
	humanoid.Sit = false
	return seat ~= nil
end

local function notify(player, text)
	if player.Parent then harvestNotify:FireClient(player, nil, nil, nil, text) end
end

-- หาจุดยืนจริง: ยิงเรย์ลงจากเหนือจุดตั้งต้น 40 สตั๊ด (ไม่โดนตัวละครคนอื่น) ได้น้ำ/ไม่เจออะไร = ใช้ค่า Y ในคอนฟิก
local function standPosition(dest, character, humanoid, root)
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then table.insert(ignore, p.Character) end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	local hit = workspace:Raycast(dest.Pos + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
	local lift = humanoid.HipHeight + root.Size.Y / 2 + 0.2
	if hit and hit.Material ~= Enum.Material.Water then
		return Vector3.new(dest.Pos.X, hit.Position.Y + lift, dest.Pos.Z)
	end
	return dest.Pos
end

warpRequest.OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" then return end
	local dest = Config.Get(id)
	if not dest then return end
	if dest.MyLot then -- แปลงของฉัน (2026-11-07): กลางล็อกของผู้เล่นคนนี้ (Attribute OrchardLot ตั้งโดย OrchardService)
		local zone = workspace:FindFirstChild("Orchard")
		local lots = zone and zone:FindFirstChild("Lots")
		local lotName = player:GetAttribute("OrchardLot")
		local lot = lots and type(lotName) == "string" and lots:FindFirstChild(lotName)
		local sum, n = Vector3.zero, 0
		for _, child in ipairs(lot and lot:GetChildren() or {}) do
			if child:IsA("BasePart") and child.Name:match("^Hole%d+$") then
				sum += child.Position
				n += 1
			end
		end
		if n == 0 then
			notify(player, say(player, "🧭 คุณยังไม่มีแปลงในสวน", "🧭 You don't have an orchard lot yet"))
			return
		end
		dest = { Pos = sum / n, Look = Vector3.new(0, 0, 1), Name = dest.Name, En = dest.En }
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and humanoid.Health > 0) then return end
	if player:GetAttribute("CarriedBy") then -- กำลังถูกแบก (CarryService) ตัวติดกับคนแบกอยู่ วาปไม่ได้ (คนแบกวาปได้ คนถูกแบกติดไปด้วย)
		notify(player, say(player, "🧭 ลงจากการแบกก่อนนะ", "🧭 Get down from the carry first"))
		return
	end
	if player:GetAttribute("GachaBusy") then
		notify(player, say(player, "🧭 รอตู้สุ่มสัตว์เลี้ยงทำงานให้เสร็จก่อนนะ", "🧭 Wait for the pet machine to finish first"))
		return
	end
	local now = os.clock()
	if lastWarp[player] and now - lastWarp[player] < Config.COOLDOWN then
		local left = math.ceil(Config.COOLDOWN - (now - lastWarp[player]))
		notify(player, say(player, "🧭 รอ " .. left .. " วินาทีแล้วค่อยวาปใหม่", "🧭 Wait " .. left .. "s before warping again"))
		return
	end
	lastWarp[player] = now
	local wasSeated = leaveSeat(character, humanoid)
	if wasSeated then task.wait(0.35) end
	if not (character.Parent and root.Parent and humanoid.Health > 0) then return end
	local pos = standPosition(dest, character, humanoid, root)
	local look = Vector3.new(dest.Look.X, 0, dest.Look.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
	local target = CFrame.lookAt(pos, pos + look)
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(target)
	if wasSeated then
		-- กันเครื่องผู้เล่นที่เน็ตช้าดึงตัวกลับที่เก้าอี้: เช็กอีกทีแล้ววางซ้ำ
		task.wait(0.5)
		if root.Parent and (root.Position - pos).Magnitude > 8 then
			leaveSeat(character, humanoid)
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(target)
		end
	end
	notify(player, say(player, "🧭 วาปไป " .. dest.Name .. " แล้ว", "🧭 Warped to " .. (dest.En or dest.Name)))
end)

Players.PlayerRemoving:Connect(function(player) lastWarp[player] = nil end)
