-- BACKUP 2026-11-14 before free reusable sign item (no shop)
-- Studio path: game.ReplicatedStorage.SignConfig (ModuleScript)
-- Restore: paste everything below this header into that script's Source in Studio

-- SignConfig (2026-11-14): ป้ายเขียนข้อความ ใช้ร่วมกันทั้งเซิร์ฟเวอร์ (ServerScriptService.Sign.SignService / SignItems) และหน้าจอ (StarterPlayerScripts.SignClient)
-- แผนเต็ม: SIGNS.md ในโฟลเดอร์โปรเจกต์ · ค่าทั้งหมดเป็นค่าที่เสนอไว้และผู้ใช้สั่งให้เริ่มด้วยค่านี้ 2026-11-14

local VipConfig = require(script.Parent:WaitForChild("VipConfig"))

local SignConfig = {}

-- DEV_ONLY = true: เปิดเฉพาะใน Studio เซิร์ฟจริงไม่มีร้านป้าย / ปุ่ม / การปัก (แบบ LessonConfig / AchievementConfig)
--   ป้ายที่อยู่ในกระเป๋าแล้ว (มีเฉพาะคนที่ได้จาก Studio) ยังเซฟ/โหลดได้ตามปกติ · เปิดให้ผู้เล่นจริง = DEV_ONLY = false แล้ว Publish
SignConfig.DEV_ONLY = true
SignConfig.ENABLED = (not SignConfig.DEV_ONLY) or game:GetService("RunService"):IsStudio()

SignConfig.PRICE = 5000            -- เหรียญ ต่อป้าย 1 อัน (ร้านป้ายข้างร้านเมล็ด)
SignConfig.MAX_OWN = 10            -- ถือ/มีในกระเป๋า + ที่ปักอยู่ รวมได้สูงสุดกี่อันต่อคน (กันกระเป๋ารก)
SignConfig.MAX_CHARS = 20          -- ตัวอักษร นับแบบ VipConfig.CountChars (ไม่นับสระบน/ล่าง วรรณยุกต์)
SignConfig.EDIT_COOLDOWN = 5       -- วินาที ระหว่างการเขียนแต่ละครั้ง
SignConfig.MAX_PLANTED = 3         -- ปักพร้อมกันได้คนละกี่ป้าย
SignConfig.MAX_PLANTED_SERVER = 60 -- ทั้งเซิร์ฟ
SignConfig.LIFETIME = 30 * 60      -- วินาที ป้ายที่ปักกลับเข้ากระเป๋าเองเมื่อครบ (หรือเมื่อเจ้าของออกเกม = เซฟกลับเข้ากระเป๋า)
SignConfig.PLANT_RANGE = 10        -- stud จากตัวผู้เล่นถึงจุดปัก
SignConfig.TEXT_MAX_DISTANCE = 80  -- stud ข้อความบนป้ายไม่วาดเมื่อไกลกว่านี้ (ประหยัดเครื่องมือถือ)
SignConfig.PICKUP_DISTANCE = 8     -- stud ระยะปุ่ม E เก็บป้าย

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

-- ร้านป้าย (เซิร์ฟสร้างตอนเกมรันจาก SignModels.SignShop ไม่มีในแมพตอน Edit) วางบนพื้นตรงนี้ หันหน้าไป FACING
SignConfig.SHOP_POS = Vector3.new(50, 0, 46)
SignConfig.SHOP_FACING = Vector3.new(0, 0, -1)

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
