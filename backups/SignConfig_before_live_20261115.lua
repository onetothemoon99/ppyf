-- BACKUP 2026-11-15: ReplicatedStorage.SignConfig (ModuleScript) ก่อนเปิดให้ผู้เล่นจริง (DEV_ONLY = false)
-- กู้คืน: เปิดสคริปต์นี้ใน Studio แล้ววางเนื้อหาตั้งแต่บรรทัดที่ 5 ของไฟล์นี้ทับทั้งหมด
-- (เนื้อหาเดิมตอนนั้น: DEV_ONLY = true, MAX_PLANTED = 1)
--
-- SignConfig (2026-11-14): ป้ายเขียนข้อความ ใช้ร่วมกันทั้งเซิร์ฟเวอร์ (ServerScriptService.Sign.SignService / SignItems) และหน้าจอ (StarterPlayerScripts.SignClient)
-- แผนเต็ม: SIGNS.md ในโฟลเดอร์โปรเจกต์ · ค่าทั้งหมดเป็นค่าที่เสนอไว้และผู้ใช้สั่งให้เริ่มด้วยค่านี้ 2026-11-14
-- 2026-11-14 (ผู้ใช้สั่ง "อยู่ในกระเป๋าเป็น item กดใช้เอา ไม่ต้องมีร้านขาย"): ทุกคนได้ป้ายฟรี 1 อัน ใช้ไม่หมด ปัก = วางสำเนาป้าย (ป้ายในมือยังอยู่) ไม่มีร้านแล้ว

local VipConfig = require(script.Parent:WaitForChild("VipConfig"))

local SignConfig = {}

-- DEV_ONLY = true: เปิดเฉพาะใน Studio เซิร์ฟจริงไม่แจกป้าย / ไม่มีหน้าต่าง / การปัก (แบบ LessonConfig / AchievementConfig)
--   ป้ายที่อยู่ในกระเป๋าแล้ว (มีเฉพาะคนที่ได้จาก Studio) ยังเซฟ/โหลดได้ตามปกติ · เปิดให้ผู้เล่นจริง = DEV_ONLY = false แล้ว Publish
SignConfig.DEV_ONLY = true
SignConfig.ENABLED = (not SignConfig.DEV_ONLY) or game:GetService("RunService"):IsStudio()

SignConfig.MAX_CHARS = 20          -- ตัวอักษร นับแบบ VipConfig.CountChars (ไม่นับสระบน/ล่าง วรรณยุกต์)
SignConfig.EDIT_COOLDOWN = 5       -- วินาที ระหว่างการเขียนแต่ละครั้ง
SignConfig.MAX_PLANTED = 1         -- ปักพร้อมกันได้คนละกี่ป้าย · 2026-11-14 ผู้ใช้สั่ง "ปักได้อันเดียว ถ้าปักใหม่ให้ย้ายอันเก่ามาปักใหม่" (เดิม 3) · ปักใหม่ = ย้ายป้ายเดิมมาตรงนี้
SignConfig.MAX_PLANTED_SERVER = 60 -- ทั้งเซิร์ฟ
SignConfig.LIFETIME = 30 * 60      -- วินาที ป้ายที่ปักหายเองเมื่อครบ (หรือเมื่อเจ้าของออกเกม)
SignConfig.PLANT_RANGE = 10        -- stud จากตัวผู้เล่นถึงจุดปัก
SignConfig.TEXT_MAX_DISTANCE = 80  -- stud ข้อความบนป้ายไม่วาดเมื่อไกลกว่านี้ (ประหยัดเครื่องมือถือ)
SignConfig.PICKUP_DISTANCE = 8     -- stud ระยะปุ่ม E ลบป้ายที่ปัก (เจ้าของเท่านั้น)

-- ปักได้เฉพาะพื้นดิน/หญ้า/ทราย (Terrain) ไม่ใช่น้ำ ถนน ลานอิฐ หิน หรือแปลงปลูกของใคร
SignConfig.GROUND = {
	[Enum.Material.Grass] = true,
	[Enum.Material.LeafyGrass] = true,
	[Enum.Material.Ground] = true,
	[Enum.Material.Mud] = true,
	[Enum.Material.Sand] = true,
}

-- โซนห้ามปัก (ระยะแนวนอนจากจุดกลาง) ลานเกิด / ร้านเมล็ด / ร้านตกปลา / ท่าเรือใหญ่
SignConfig.NO_ZONES = {
	{ name = "spawn", pos = Vector3.new(34, 0, -24), radius = 40 },
	{ name = "seedShop", pos = Vector3.new(62, 0, 32), radius = 30 },
	{ name = "fishShop", pos = Vector3.new(-335, 0, 403), radius = 35 },
	{ name = "mainDock", pos = Vector3.new(-434.7, 0, 642.8), radius = 45 },
}

-- สี
SignConfig.TEXT_COLOR = Color3.fromRGB(70, 45, 25)
SignConfig.BOARD_COLOR = Color3.fromRGB(222, 184, 135)
SignConfig.POST_COLOR = Color3.fromRGB(124, 92, 62)

SignConfig.CountChars = VipConfig.CountChars
SignConfig.Clean = VipConfig.Clean

-- ข้อความโดนตัวกรองปิดทั้งหมด (เหลือแต่ # และช่องว่าง)
function SignConfig.FullyBlocked(text)
	return type(text) == "string" and text ~= "" and text:gsub("[#%s]", "") == ""
end

function SignConfig.InNoZone(pos)
	for _, z in ipairs(SignConfig.NO_ZONES) do
		local d = Vector3.new(pos.X - z.pos.X, 0, pos.Z - z.pos.Z).Magnitude
		if d <= z.radius then return z.name end
	end
	return nil
end

return SignConfig
