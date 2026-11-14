-- BACKUP 2026-11-14 — ReplicatedStorage.LessonContent (ModuleScript) ก่อนทำบทตกปลาเป็นนำทางต่อกัน น้ำ → ตกได้ → ร้านตกปลา
-- วิธีคืน: ใน Studio เปิด ReplicatedStorage.LessonContent แล้ววาง Source ด้านล่างนี้ทับทั้งหมด (ลบ 2 บรรทัดคอมเมนต์นี้ออกก็ได้)
-- LessonContent (2026-11-14 ผู้ใช้เลือก "Full plan (link teacher)"): ข้อมูลบทเรียนที่ใช้ร่วมกัน 2 หน้าต่าง (ฝั่งเครื่องผู้เล่นเท่านั้น)
--   StarterPlayerScripts.LessonNpcGui = หน้าต่างครูฟาร์ม (การ์ดใหญ่ วิธีเล่น 3 ข้อ + ปุ่มพาไป/รับรางวัล)
--   StarterPlayerScripts.HowToPlayGui = แผง "?" (แถวสั้น คำอธิบายบรรทัดเดียว hubTh/hubEn + ปุ่ม + ป้ายรางวัล)
-- รางวัล/สถานะอยู่ที่ ReplicatedStorage.LessonConfig + ServerScriptService.LessonService (ไม่ได้อยู่ที่นี่) · id ต้องตรงกับ LessonConfig.Order
-- ฟิลด์: id, icon, th/en (ชื่อ), thLines/enLines (วิธีเล่น 3 ข้อ หน้าต่างครู), hubTh/hubEn (บรรทัดเดียว แผง "?")
--   startGuide = true → ปุ่มเริ่มลูกศรนำทาง 4 ขั้น (NewPlayerGuideGui.StartGuide)
--   getPos() → Vector3 จุดที่พาไป (nil = ซ่อนปุ่ม) · markTh/guideTh/doneTh/arriveDist = ข้อความ/ระยะของการนำทาง (NewPlayerGuideGui.GuideTo)
--   endOnCatch + catchTh = ตกปลาได้ระหว่างนำทาง → จบการนำทาง · available() → false = ไม่แสดงบทนี้
-- เรียกใช้ฝั่งเครื่องผู้เล่นเท่านั้น (getPos ใช้ Players.LocalPlayer)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LessonContent = {}

local function rootPart()
	local player = Players.LocalPlayer
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- น้ำที่ใกล้ผู้เล่นที่สุด: ยิงเส้นลงพื้นเป็นวงแหวนรอบตัว ขยายทีละ 12 สตั๊ด (ย้ายมาจาก LessonNpcGui)
local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false
waterParams.FilterType = Enum.RaycastFilterType.Exclude
local function nearestWater()
	local root = rootPart()
	if not root then return nil end
	waterParams.FilterDescendantsInstances = { root.Parent }
	local origin = root.Position
	for r = 12, 240, 12 do
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2
			local p = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local hit = workspace:Raycast(Vector3.new(p.X, origin.Y + 40, p.Z), Vector3.new(0, -90, 0), waterParams)
			if hit and hit.Material == Enum.Material.Water then return hit.Position end
		end
	end
	return nil
end

LessonContent.LESSONS = {
	{
		id = "basic", icon = "🌱", th = "ปลูก เก็บ ขาย", en = "Plant, harvest, sell",
		thLines = "1. กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน\n2. รอต้นโต แล้วกดปุ่มเก็บที่ต้น\n3. ขายผลผลิตที่ร้านเมล็ด แล้วซื้อเมล็ดใหม่",
		enLines = "1. Tap slot 1 (seeds), then tap a soil plot\n2. Wait for it to grow, then press harvest on the crop\n3. Sell your crops at the seed shop, then buy new seeds",
		hubTh = "ช่อง 1 ปลูก รอโต เก็บ แล้วขายที่ร้านเมล็ด", hubEn = "Slot 1 to plant, then harvest and sell",
		startGuide = true, -- ปุ่ม = เริ่มลูกศรนำทาง 4 ขั้นของ NewPlayerGuide (NewPlayerGuideGui.StartGuide)
	},
	{
		id = "fish", icon = "🎣", th = "ตกปลา", en = "Fishing",
		thLines = "1. กดช่อง 6 เพื่อถือเบ็ด (ได้เบ็ดฟรีตอนเข้าเกม)\n2. ยืนใกล้น้ำ เบ็ดจะเหวี่ยงและดึงปลาเอง\n3. ขายปลาและซื้อเบ็ดที่ร้านตกปลา (เมนูขีดสามเส้น > วาป)",
		enLines = "1. Tap slot 6 to hold your rod (free when you join)\n2. Stand near water. It casts and reels in by itself\n3. Sell fish and buy rods at the Fishing Store (three-line menu > Warp)",
		hubTh = "ช่อง 6 ถือเบ็ด ยืนใกล้น้ำ เบ็ดตกเอง", hubEn = "Slot 6 for the rod, stand near water",
		markTh = "น้ำตกปลา", markEn = "Fishing water",
		guideTh = "ไปที่น้ำ แล้วกดช่อง 6 (เบ็ด)", guideEn = "Go to the water, then tap slot 6 (rod)",
		doneTh = "ถึงน้ำแล้ว! กดช่อง 6 เพื่อตกปลา", doneEn = "You're at the water! Tap slot 6 to fish",
		arriveDist = 10,
		getPos = nearestWater,
		-- ตกได้ระหว่างนำทาง = จบการนำทางเลย (2026-11-14: ยืนห่างจุดน้ำที่สุ่มไว้เกิน 10 สตั๊ดแล้วการ์ดค้าง)
		endOnCatch = true,
		catchTh = "ตกปลาได้แล้ว! เก่งมาก ขายปลาได้ที่ร้านตกปลา", catchEn = "You caught one! Sell fish at the Fishing Store",
	},
	{
		id = "chicken", icon = "🐔", th = "เลี้ยงไก่", en = "Chickens",
		thLines = "1. ไปฟาร์มไก่ (เดินตามเส้น หรือเมนูขีดสามเส้น > วาป)\n2. ซื้อไก่ที่ร้านไก่ ไก่จะออกไข่เอง\n3. เก็บไข่แล้วขาย คอยกวาดเล้าให้สะอาด ไข่จะออกเร็วขึ้น",
		enLines = "1. Go to the Chicken Farm (follow the line, or three-line menu > Warp)\n2. Buy a chicken at the chicken shop. It lays eggs by itself\n3. Collect and sell the eggs. Keep the coop clean for faster eggs",
		hubTh = "ซื้อไก่ที่ฟาร์มไก่ เก็บไข่ไปขาย", hubEn = "Buy a chicken, collect and sell eggs",
		markTh = "ฟาร์มไก่", markEn = "Chicken Farm",
		guideTh = "ไปฟาร์มไก่ (ไกล? ใช้เมนูขีดสามเส้น > วาป)", guideEn = "Go to the Chicken Farm (far? use the menu > Warp)",
		doneTh = "ถึงฟาร์มไก่แล้ว! ซื้อไก่ตัวแรกที่ร้านไก่", doneEn = "You're at the Chicken Farm! Buy your first chicken",
		arriveDist = 16,
		available = function() -- ฟาร์มไก่ปิด (ChickenConfig.Enabled = false) = ไม่แสดงบทนี้
			local module = ReplicatedStorage:FindFirstChild("ChickenConfig", true)
			if not module then return false end
			local ok, config = pcall(require, module)
			return ok and type(config) == "table" and config.Enabled == true
		end,
		getPos = function() -- ChickenService ตั้ง Attribute ChickenShopPos บน ReplicatedStorage
			local pos = ReplicatedStorage:GetAttribute("ChickenShopPos")
			return typeof(pos) == "Vector3" and pos or nil
		end,
	},
}

-- ครูฟาร์ม (Workspace.GuideNPC): แถวในแผง "?" + นำทางไปหา
LessonContent.TEACHER = {
	icon = "📘", th = "ครูฟาร์ม", en = "Farm Teacher",
	hubTh = "รับรางวัลบทเรียน และดูวิธีเล่นเพิ่ม", hubEn = "Claim lesson rewards and learn more",
	guideTh = "ไปคุยกับครูฟาร์ม (กด E)", guideEn = "Talk to the Farm Teacher (press E)",
	doneTh = "ถึงแล้ว! กด E คุยกับครูฟาร์ม", doneEn = "You're here! Press E to talk to the Farm Teacher",
	arriveDist = 10,
}
-- พื้นใต้ NPC (nil = ไม่มี NPC ในแมพ/ยังไม่ถูกสตรีม · GuideNPC ตั้ง ModelStreamingMode = Persistent ไว้แล้ว)
function LessonContent.TeacherPos()
	local npc = workspace:FindFirstChild("GuideNPC")
	if not npc then return nil end
	local cf, size = npc:GetBoundingBox()
	return cf.Position - Vector3.new(0, size.Y / 2, 0)
end

-- แถวข้อมูลท้ายแผง "?" (ไม่มีปุ่ม)
LessonContent.MORE_MENU = {
	icon = "🧭", th = "เมนูเพิ่มเติม", en = "More menu",
	hubTh = "ปุ่มขีดสามเส้นซ้ายบน: วาป สมุดปลา ท่าเต้น", hubEn = "Top-left three-line button: warp, fish book, dances",
}

function LessonContent.Find(id)
	for _, lesson in ipairs(LessonContent.LESSONS) do
		if lesson.id == id then return lesson end
	end
	return nil
end

function LessonContent.IsAvailable(lesson)
	return lesson.available == nil or lesson.available() == true
end

return LessonContent
