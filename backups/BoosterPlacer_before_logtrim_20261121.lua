-- BACKUP of StarterPlayer.StarterPlayerScripts.BoosterPlacer taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open StarterPlayer.StarterPlayerScripts.BoosterPlacer, select all, paste everything BELOW the next line.
-- ===== original Source (6493 bytes, hash 1513047881) =====
-- BoosterPlacer: คลิกเมาส์ตอนถือ "หุ่นเพิ่มดวง" เพื่อวางตรงจุดที่คลิก (วางได้อิสระ ไม่จำกัดแค่แปลงดิน)
-- + โชว์วงหิ่งห้อยพรีวิวรัศมีจริง ลอยตามจุดที่เล็งอยู่ตลอดเวลาที่ถือหุ่นอยู่

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local placeBooster = remoteEvents:WaitForChild("PlaceBooster")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- รัศมีพรีวิวตามระดับหุ่นที่ถือ (x50 = 15, x100 = 30) อ่านจาก ReplicatedStorage.LuckConfig ตัวเดียวกับที่เซิร์ฟเวอร์ใช้จริง
local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))

local function getToolRadius(tool)
	return LuckConfig.GetBoosterTier(tool and tool:GetAttribute("BoosterTier")).Radius
end
local PREVIEW_COLOR = Color3.fromRGB(255, 221, 89) -- ทอง-เหลือง สีเดียวกับตอนปักจริง
local PREVIEW_FIREFLY_COUNT = 16
local PREVIEW_HEIGHT = 1

local previewContainer = nil
local previewOffsets = nil -- ตำแหน่งสัมพัทธ์ของหิ่งห้อยแต่ละจุด (คงที่ ขยับแค่จุดศูนย์กลางตามเป้าเล็ง)
local previewConnection = nil

local function createPreview(radius)
	if previewContainer then return end

	previewContainer = Instance.new("Folder")
	previewContainer.Name = "BoosterRadiusPreview"
	previewContainer.Parent = workspace

	previewOffsets = {}

	for i = 1, PREVIEW_FIREFLY_COUNT do
		local angle = (i / PREVIEW_FIREFLY_COUNT) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * radius, PREVIEW_HEIGHT, math.sin(angle) * radius)
		table.insert(previewOffsets, offset)

		local bug = Instance.new("Part")
		bug.Name = "PreviewFirefly"
		bug.Shape = Enum.PartType.Ball
		bug.Material = Enum.Material.Neon
		bug.Color = PREVIEW_COLOR
		bug.Size = Vector3.new(0.25, 0.25, 0.25)
		bug.Transparency = 0.2
		bug.CanCollide = false
		bug.CanQuery = false
		bug.Anchored = true
		bug.Parent = previewContainer

		local light = Instance.new("PointLight")
		light.Color = PREVIEW_COLOR
		light.Range = 5
		light.Brightness = 1
		light.Parent = bug
	end
end

local function updatePreview(centerPosition)
	if not previewContainer then return end

	local index = 0
	for _, bug in ipairs(previewContainer:GetChildren()) do
		if bug:IsA("BasePart") then
			index += 1
			local offset = previewOffsets[index]
			if offset then
				bug.CFrame = CFrame.new(centerPosition + offset)
			end
		end
	end
end

local function destroyPreview()
	if previewConnection then
		previewConnection:Disconnect()
		previewConnection = nil
	end
	if previewContainer then
		previewContainer:Destroy()
		previewContainer = nil
	end
	previewOffsets = nil
end

local function startPreviewLoop(tool)
	destroyPreview() -- สลับหุ่นคนละระดับแล้วรัศมีต้องเปลี่ยนตาม
	createPreview(getToolRadius(tool))
	previewConnection = RunService.RenderStepped:Connect(function()
		-- โหมดถ่ายภาพ (PhotoModeGui) = เอาวงหิ่งห้อยพรีวิวออกจากฉากชั่วคราว
		if previewContainer then previewContainer.Parent = (not player:GetAttribute("PhotoMode")) and workspace or nil end
		local target = mouse.Hit
		if target then
			updatePreview(target.Position)
		end
	end)
end

local function onToolActivated(tool)
	if not tool:GetAttribute("IsBooster") then return end -- ไม่ใช่หุ่นเพิ่มดวง ปล่อยให้สคริปต์อื่นจัดการ
	print("🔍 [DEBUG] BoosterPlacer: ถือหุ่นอยู่ กด Activated แล้ว")

	local target = mouse.Target
	if not target then
		print("🔍 [DEBUG] BoosterPlacer: mouse.Target เป็น nil (ไม่ได้คลิกโดนอะไรเลย)")
		return
	end

	print("🔍 [DEBUG] BoosterPlacer: คลิกโดน " .. target:GetFullName() .. " ที่ตำแหน่ง " .. tostring(mouse.Hit.Position))
	placeBooster:FireServer(mouse.Hit.Position)
end

-- ไอเทมที่ผูก Activated ไว้แล้ว [Tool] = true
-- สำคัญ: ต้องกันผูกซ้ำ เพราะ ChildAdded จะยิงทุกครั้งที่หยิบไอเทมเดิมขึ้นมาถือใหม่
-- ถ้าผูกซ้ำ คลิกทีเดียวจะยิง placeBooster ไปเซิร์ฟเวอร์หลายรอบ กลายเป็นปักหลายตัวรวดเดียว
local hookedTools = {}

local function hookTool(child)
	if not child:IsA("Tool") or hookedTools[child] then return end
	hookedTools[child] = true
	child.Destroying:Connect(function() hookedTools[child] = nil end)

	child.Activated:Connect(function()
		onToolActivated(child)
	end)

	if child:GetAttribute("IsBooster") then
		child.Equipped:Connect(function() startPreviewLoop(child) end)
		child.Unequipped:Connect(destroyPreview)
	end
end

local function hookCharacter(character)
	character.ChildAdded:Connect(hookTool)

	-- เผื่อถืออยู่แล้วตอนสคริปต์เริ่มทำงาน
	for _, child in ipairs(character:GetChildren()) do
		hookTool(child)
		if child:IsA("Tool") and child:GetAttribute("IsBooster") then
			startPreviewLoop(child) -- ถืออยู่แล้วตั้งแต่ก่อนสคริปต์เริ่ม เปิดพรีวิวทันที
		end
	end
end

if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)
player.CharacterRemoving:Connect(destroyPreview) -- กันวงพรีวิวค้างลอยอยู่ถ้าตัวละครตาย/รีสปอนกลางคัน