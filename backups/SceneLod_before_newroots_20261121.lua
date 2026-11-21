-- BACKUP of StarterPlayer.StarterPlayerScripts.SceneLod taken 2026-11-21 before adding FishDock, MangoGardenDecor and Orchard.Decor to SceneLod.
-- Restore: in Studio open StarterPlayer.StarterPlayerScripts.SceneLod, select all, paste everything BELOW the next line.
-- ===== original Source (7785 bytes, hash 972773434) =====
-- SceneLod: ไม่วาดฉากตกแต่งที่อยู่ไกลกล้อง เฉพาะระดับกราฟิกที่ตั้ง SceneHideDist (ต่ำ 220 / ต่ำสุด 140 studs) 2026-10-24
-- เหตุผล: วัดที่ลานร้านเมล็ด (2026-10-13) HikingMap ตัวเดียว = 232k สามเหลี่ยม / 131 draw call, ของตกแต่งฮาโลวีน 80k ฯลฯ
-- ซ่อนแค่การวาดบนเครื่องนี้ (LocalTransparencyModifier = 1) ชน/เดินได้ปกติ คนอื่นไม่เห็นผล · Terrain (ภูเขา/พื้น/น้ำ) ยังเห็นเสมอ
-- แบ่งชิ้นส่วนเป็นช่อง CELL x CELL studs ตามตำแหน่ง ตรวจทุก 0.5 วิ เฉพาะช่องที่เปลี่ยนสถานะ (ใกล้↔ไกล) จึงแตะชิ้นส่วน
-- เฉพาะกลุ่มที่เป็นฉากล้วน (ROOTS / LOOSE_NAMES / PREFIXES) ไม่แตะแปลง ร้าน ตู้ ป้ายอันดับ พืช (CropLod ดูแลเอง) สัตว์ ตัวละคร
-- ข้าม: ชิ้นใหญ่กว่า BIG_PART (พื้น/ทรายแผ่นใหญ่ ซ่อนแล้วเห็นรูโหว่) ชิ้นที่มองไม่เห็นอยู่แล้ว และอะไรที่ตั้ง Attribute KeepVisible = true
-- เกมเปิด StreamingEnabled: ชิ้นส่วนโหลดเข้า/ออกตลอด จึงตาม DescendantAdded/Removing ของแต่ละกลุ่ม

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GraphicsConfig = require(ReplicatedStorage:WaitForChild("GraphicsConfig"))
local player = Players.LocalPlayer

local CELL = 48
local CHECK_EVERY = 0.5
local HYSTERESIS = 12 -- studs กันกระพริบตอนยืนอยู่ตรงเส้นแบ่ง
local BIG_PART = 60

-- โฟลเดอร์ฉากใน workspace
local ROOTS = {
	HikingMap = true, Beach = true, FarmFlora = true, IslandDecor = true, Scenery = true, Tree = true,
	WildFlower = true, RestSpots = true, FarmDressing = true, TerraceDressing = true, Lights = true,
	FarmBridges = true, Waterfall = true,
	LayoutDecor = true, IslandScatter = true, -- 2026-11-10 ต้นมะพร้าว/ร่ม/ม้านั่งริมหาด/ท่าเรือ/LakeSurround (ทะเลสาบ) + หินและพุ่มทั่วเกาะ (ผู้ใช้กลัวหน่วง)
	PlacedFurniture = true, -- เฟอร์นิเจอร์ที่ผู้เล่นวาง (FurnitureService) ซ่อนเฉพาะที่ไกล ใกล้ๆ ยังเห็น (ซ่อนหมด = เก้าอี้ล่องหนชนได้)
}
-- โมเดลตกแต่งที่วางตรงใน workspace (ShopCatNpc = แมวจิ๋วหน้าร้านเมล็ด 982 ชิ้น, "Model" = เก้าอี้แคมป์)
local LOOSE_NAMES = {
	Lantern = true, Palm = true, Bench = true, ["Long Table"] = true, GreenShrub = true, MangoTree = true,
	HibiscusBush = true, pumpkin_seedling = true, ["tent and campfire"] = true, PoolSet = true, Model = true, ShopCatNpc = true,
}
-- ของเทศกาล (ServerScriptService.SeasonalDecor)
-- + กิจกรรมลอยกระทง (2026-11-07): ลานปล่อยโคม KrathongLanternField / ลานแขวนโคม KrathongLanternGarden (โคม 240 ดวง) / ร้าน KrathongStall
--   ไม่ใส่ KrathongFloating (กระทงที่กำลังลอย ขยับทุกเฟรม ช่องตารางคำนวณตอนเพิ่มชิ้นจะผิด)
local PREFIXES = { "SeasonalDecor_", "SeasonalSkin_", "KrathongLantern", "KrathongStall" }

local function isSceneRoot(inst)
	if inst.Parent ~= workspace then return false end
	if ROOTS[inst.Name] and inst:IsA("Folder") then return true end
	if LOOSE_NAMES[inst.Name] and inst:IsA("Model") and not inst:GetAttribute("PetId") and not Players:GetPlayerFromCharacter(inst) then return true end
	for _, p in ipairs(PREFIXES) do
		if string.sub(inst.Name, 1, #p) == p then return true end
	end
	return false
end

local cells = {} -- [key] = { center = Vector3, parts = { [part] = true }, hidden = bool }
local partCell = {} -- [part] = key
local hideDist = nil -- nil = ระดับนี้ไม่ซ่อน

local function setPart(part, hidden)
	part.LocalTransparencyModifier = hidden and 1 or 0
end

local function addPart(part)
	if partCell[part] or not part:IsA("BasePart") then return end
	if part.Transparency >= 1 or part:GetAttribute("KeepVisible") then return end
	local s = part.Size
	if math.max(s.X, s.Y, s.Z) > BIG_PART then return end
	local p = part.Position
	local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
	local key = cx .. "," .. cz
	local cell = cells[key]
	if not cell then
		cell = { center = Vector3.new((cx + 0.5) * CELL, 0, (cz + 0.5) * CELL), parts = {}, hidden = false }
		cells[key] = cell
	end
	cell.parts[part] = true
	partCell[part] = key
	if cell.hidden then setPart(part, true) end
end

local function removePart(part)
	local key = partCell[part]
	if not key then return end
	partCell[part] = nil
	local cell = cells[key]
	if cell then cell.parts[part] = nil end
end

local watched = {}
local function watchRoot(root)
	if watched[root] or not isSceneRoot(root) then return end
	watched[root] = true
	for i, d in ipairs(root:GetDescendants()) do
		addPart(d)
		if i % 2000 == 0 then task.wait() end
	end
	if root:IsA("BasePart") then addPart(root) end
	root.DescendantAdded:Connect(function(d)
		-- รอสคริปต์เจ้าของตั้งตำแหน่ง/ความโปร่งใสเสร็จก่อน
		if d:IsA("BasePart") then task.defer(function() if d.Parent then addPart(d) end end) end
	end)
	root.DescendantRemoving:Connect(removePart)
end

local function unwatchRoot(root)
	if not watched[root] then return end
	watched[root] = nil
	for _, d in ipairs(root:GetDescendants()) do removePart(d) end
end

local function update()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	local flat = Vector3.new(camPos.X, 0, camPos.Z)
	local half = CELL * 0.71 -- ระยะจากกลางช่องถึงมุม นับจากขอบช่องที่ใกล้สุดโดยประมาณ
	for _, cell in pairs(cells) do
		local want = false
		if hideDist then
			local d = (cell.center - flat).Magnitude - half
			if cell.hidden then
				want = d > hideDist - HYSTERESIS
			else
				want = d > hideDist
			end
		end
		if want ~= cell.hidden then
			cell.hidden = want
			for part in pairs(cell.parts) do setPart(part, want) end
		end
	end
end

local function applyLevel()
	local level = GraphicsConfig.Get(player:GetAttribute(GraphicsConfig.ATTRIBUTE))
	hideDist = tonumber(level.SceneHideDist)
	update()
end
player:GetAttributeChangedSignal(GraphicsConfig.ATTRIBUTE):Connect(applyLevel)

workspace.ChildAdded:Connect(function(c) task.defer(watchRoot, c) end)
workspace.ChildRemoved:Connect(unwatchRoot)
for _, c in ipairs(workspace:GetChildren()) do watchRoot(c) end
applyLevel()

while true do
	task.wait(CHECK_EVERY)
	if hideDist then update() end
end
