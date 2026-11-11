-- Backup 2026-11-11 of ReplicatedStorage.KrathongConfig (ModuleScript) before the night-glow lantern change.
-- To restore: paste everything below these 2 lines back into ReplicatedStorage.KrathongConfig.Source.
-- KrathongConfig (2026-11-07): กิจกรรมลอยกระทง ซื้อกระทงจากแม่ค้า เก็บในกระเป๋า แล้วไปลอยที่ท่าน้ำ PondDock1
-- เปิด/ปิดทั้งกิจกรรม = SeasonConfig.Seasons.KrathongFloat2026 (แยกจาก LoyKrathong2026 ที่เปิดปลาอีเวนต์อยู่แล้ว เพื่อไม่ให้ของที่ยังทำไม่เสร็จหลุดไปตอน Publish)
-- ลองใน Studio: DevForceSeason ใส่ "KrathongFloat2026"
-- ของในกระเป๋า: Tool IsKrathong + KrathongId + Count (ServerScriptService.Krathong.KrathongItems) · InventorySystem kind "Krathong"
-- โมเดล: ReplicatedStorage.KrathongModels.<id> (Handle = MeshPart ฐานที่ y 0) ใช้ทั้งในมือ รูปในกระเป๋า และตอนลอยน้ำ

local KrathongConfig = {}

KrathongConfig.SEASON = "KrathongFloat2026"

-- EventBonus = โอกาสที่ปลาที่ติดเบ็ดเปลี่ยนเป็นปลาอีเวนต์ "ระดับเดียวกัน" (ไม่ได้เพิ่มโอกาสระดับสูง) ระหว่างบัฟ
-- BuffMinutes = เวลาบัฟที่ได้ต่อการลอย 1 ครั้ง (ต่อเวลาได้ ไม่เกิน BUFF_MAX_MINUTES) · โบนัสใช้ค่าสูงสุดที่ยังไม่หมดเวลา
KrathongConfig.Types = {
	Banana = { Order = 1, NameTh = "กระทงใบตอง", NameEn = "Banana-leaf krathong", Icon = "🍃", Price = 1000, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(95, 165, 85), Bg = Color3.fromRGB(225, 242, 215), Light = Color3.fromRGB(255, 200, 120) },
	Bread = { Order = 2, NameTh = "กระทงขนมปัง", NameEn = "Bread krathong", Icon = "🍞", Price = 3000, BuffMinutes = 15, EventBonus = 0.15,
		Strip = Color3.fromRGB(200, 140, 70), Bg = Color3.fromRGB(250, 236, 210), Light = Color3.fromRGB(255, 190, 110) },
	Lotus = { Order = 3, NameTh = "กระทงดอกบัว", NameEn = "Lotus krathong", Icon = "🌸", Price = 8000, BuffMinutes = 20, EventBonus = 0.25,
		Strip = Color3.fromRGB(230, 110, 160), Bg = Color3.fromRGB(255, 228, 240), Light = Color3.fromRGB(255, 170, 200) },
	-- โคมลอย (2026-11-07): ของในกระเป๋าชนิดเดียวกัน (Kind = "Lantern") · 2026-11-11 ปล่อยได้ทุกที่ที่เหนือหัวโล่ง (หรือกด E ที่ลานบนท่าเรือ)
	SkyLantern = { Order = 4, Kind = "Lantern", NameTh = "โคมลอย", NameEn = "Sky lantern", Icon = "🏮", Price = 2000, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(225, 130, 60), Bg = Color3.fromRGB(255, 236, 215), Light = Color3.fromRGB(255, 175, 100) },
	-- โคมแขวน (2026-11-08 ผู้ใช้สั่ง): ถือไปแขวนที่ตะขอว่างในลานแขวนโคม (workspace.KrathongLanternGarden.Hooks) ทุกคนเห็น อยู่ HANG_LIFE วิ
	-- 2026-11-11 ผู้ใช้สั่ง: โคมแขวนไม่ให้โชคปลาอีเวนต์แล้ว ได้ "โชคหลัก" x LuckMult (1.3 = +30%) นาน BuffMinutes → Attribute LanternLuckUntil (คิดใน LuckConfig.Combine)
	-- โคมแขวน 7 สีตามวัน (2026-11-08 ผู้ใช้สั่ง) Day 1 = อาทิตย์ ... 7 = เสาร์ · HangLantern = สีแดง (id เดิม ของที่ซื้อไว้แล้วไม่หาย) · ในร้านเป็นการ์ดเดียว เลือกสี
	HangLantern = { Order = 5, Kind = "Hang", Day = 1, NameTh = "โคมแขวนสีแดง", NameEn = "Red hanging lantern", DayTh = "วันอาทิตย์", DayEn = "Sunday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(205, 75, 70), Bg = Color3.fromRGB(255, 230, 225), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(160, 32, 36) },
	HangYellow = { Order = 5, Kind = "Hang", Day = 2, NameTh = "โคมแขวนสีเหลือง", NameEn = "Yellow hanging lantern", DayTh = "วันจันทร์", DayEn = "Monday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(220, 175, 40), Bg = Color3.fromRGB(255, 240, 230), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(188, 148, 24) },
	HangPink = { Order = 5, Kind = "Hang", Day = 3, NameTh = "โคมแขวนสีชมพู", NameEn = "Pink hanging lantern", DayTh = "วันอังคาร", DayEn = "Tuesday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(225, 110, 160), Bg = Color3.fromRGB(255, 240, 230), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(172, 72, 120) },
	HangGreen = { Order = 5, Kind = "Hang", Day = 4, NameTh = "โคมแขวนสีเขียว", NameEn = "Green hanging lantern", DayTh = "วันพุธ", DayEn = "Wednesday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(95, 170, 70), Bg = Color3.fromRGB(255, 240, 230), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(88, 152, 40) },
	HangOrange = { Order = 5, Kind = "Hang", Day = 5, NameTh = "โคมแขวนสีส้ม", NameEn = "Orange hanging lantern", DayTh = "วันพฤหัสบดี", DayEn = "Thursday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(230, 125, 50), Bg = Color3.fromRGB(255, 240, 230), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(180, 80, 20) },
	HangBlue = { Order = 5, Kind = "Hang", Day = 6, NameTh = "โคมแขวนสีฟ้า", NameEn = "Light blue hanging lantern", DayTh = "วันศุกร์", DayEn = "Friday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(80, 150, 210), Bg = Color3.fromRGB(255, 240, 230), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(56, 120, 172) },
	HangPurple = { Order = 5, Kind = "Hang", Day = 7, NameTh = "โคมแขวนสีม่วง", NameEn = "Purple hanging lantern", DayTh = "วันเสาร์", DayEn = "Saturday", TagTh = "โคมแขวน", TagEn = "Lantern", Icon = "🏮", Price = 1500, BuffMinutes = 10, EventBonus = 0.10,
		Strip = Color3.fromRGB(150, 90, 190), Bg = Color3.fromRGB(255, 240, 230), Light = Color3.fromRGB(255, 160, 110), Lamp = Color3.fromRGB(120, 60, 160) },
}
KrathongConfig.Order = { "Banana", "Bread", "Lotus", "SkyLantern", "HangLantern" }

-- โคมทุกแบบ (โคมลอย + โคมแขวน) = ไม่ใช่กระทง ลอยน้ำไม่ได้
function KrathongConfig.IsLantern(id)
	local t = KrathongConfig.Types[id]
	return t ~= nil and t.Kind ~= nil
end
function KrathongConfig.IsHang(id)
	local t = KrathongConfig.Types[id]
	return t ~= nil and t.Kind == "Hang"
end

-- ลานแขวนโคม: ตะขอว่าง = Part "Hook" ใน KrathongLanternGarden.Hooks (Attribute HangAt = CFrame ของโคม, Taken = มีคนแขวนอยู่)
KrathongConfig.HANG_RANGE = 7 -- ยืนห่างตะขอ (แนวราบ) ไม่เกินนี้ถึงแขวนได้
KrathongConfig.HANG_POSE = 2.6 -- วินาที ดันไม้ไผ่ยกโคมขึ้นไปเกี่ยวตะขอ (1.4) แล้วลดไม้ลง
KrathongConfig.HANG_LIFE = 1800 -- โคมที่แขวนอยู่ 30 นาที แล้วจางหาย ตะขอว่างให้คนอื่น
KrathongConfig.HANG_COOLDOWN = 4
-- โคมแขวนเรียงตามวัน อาทิตย์ → เสาร์ (การ์ดร้านแสดงเป็นปุ่มสี)
KrathongConfig.HangIds = { "HangLantern", "HangYellow", "HangPink", "HangGreen", "HangOrange", "HangBlue", "HangPurple" }
-- สีของวันนี้ตามเวลาไทย (UTC+7)
function KrathongConfig.TodayHang(now)
	local wday = os.date("!*t", (now or os.time()) + 7 * 3600).wday -- 1 = อาทิตย์
	return KrathongConfig.HangIds[wday]
end

-- ลานปล่อยโคมริมหาด (ServerStorage.KrathongTemplates.LanternField วางที่เดิม = workspace.KrathongLanternField)
KrathongConfig.LANTERN_FIELD = Vector3.new(-434.7, 3.2, 642.8) -- 2026-11-10 ลานปล่อยโคมย้ายไปบนท่าเรือ LayoutDecor.SeaDocks.MainDock (พื้นไม้ y 3.2 น้ำรอบด้าน) ผู้ใช้สั่ง · เดิม (70, 5, 227)
KrathongConfig.LANTERN_RADIUS = 18 -- ยืนในวงนี้ = ปล่อยเองได้ / ได้ร่วมรอบปล่อยพร้อมกัน
KrathongConfig.LANTERN_SECONDS = 45 -- โคมลอยขึ้นจนจางหาย
KrathongConfig.LANTERN_RISE = 170 -- สตั๊ด
KrathongConfig.MAX_LANTERNS = 80 -- ต่อเครื่อง (60 → 80 วันที่ 2026-11-11 เผื่อโคมประกอบฉากริมหาด)
KrathongConfig.LANTERN_LIGHT_LIMIT = 12
-- ปล่อยโคมได้ทุกที่ (2026-11-11 ผู้ใช้สั่ง): ถือโคมลอย + ยืนบนพื้น + เหนือหัวโล่ง SKY_CLEAR สตั๊ด = ปุ่ม "🏮 ปล่อยโคม" (เซิร์ฟตรวจซ้ำ actions.releaseHere)
--   ชิ้นส่วนโปร่งใส (Transparency ≥ 0.9) หรือ CanCollide ปิด ไม่นับเป็นหลังคา · ลานบนท่าเรือ (กด E) ยังใช้ได้เหมือนเดิม
KrathongConfig.SKY_CLEAR = 40
KrathongConfig.LANTERN_CULL = 800 -- ฝั่งผู้เล่น: โคมที่เริ่มไกลกล้องเกินนี้ไม่สร้าง (ไม่มีใครเห็นอยู่แล้ว)
-- ฉากโคมลอยขึ้นจากชายหาด (2026-11-11): ฝั่งผู้เล่นทำเองล้วน เฉพาะกลางคืน (เวลาเดียวกับ NightLightsClient) เปิดตามสวิตช์ KrathongFloat2026
--   จุดปล่อย = เส้น P01→P13 ใน workspace.KrathongBeachLanternLine (ต้นแบบ KrathongTemplates.BeachLanternLine ลากแก้ใน Edit ได้ที่ workspace.KrathongDecor)
KrathongConfig.BEACH_AMBIENT = true -- false = ปิดเฉพาะโคมประกอบฉาก (ปุ่มปล่อยเอง/รอบพร้อมกันยังอยู่)
KrathongConfig.BEACH_EVERY = { 2, 3.5 } -- วินาทีระหว่างดวง (สุ่มในช่วงนี้)
KrathongConfig.BEACH_MAX = 20 -- โคมประกอบฉากบนฟ้าพร้อมกันสูงสุด (นับรวมใน MAX_LANTERNS)
KrathongConfig.BEACH_MASS = 40 -- รอบปล่อยพร้อมกัน :00/:30 = โคมขึ้นจากหาดพร้อมกันเพิ่มอีกเท่านี้ (ทุกช่วงเวลา ไม่ใช่แค่กลางคืน)
KrathongConfig.NIGHT_ON, KrathongConfig.NIGHT_OFF = 18.2, 6.3 -- ตรงกับ NightLightsClient
-- รอบปล่อยโคมพร้อมกัน: ทุก MASS_INTERVAL วิ (ตรงนาที :00 / :30) ใครยืนในลาน = ได้ปล่อยโคมฟรี 1 ดวง + บัฟ MASS_BONUS / MASS_MINUTES
KrathongConfig.MASS_INTERVAL = 1800
KrathongConfig.MASS_WARN = 60 -- ประกาศล่วงหน้า (วิ)
KrathongConfig.MASS_BONUS = 0.15
KrathongConfig.MASS_MINUTES = 15

-- วินาที (os.time / GetServerTimeNow) ของรอบปล่อยพร้อมกันถัดไป
function KrathongConfig.NextMass(now)
	return (math.floor(now / KrathongConfig.MASS_INTERVAL) + 1) * KrathongConfig.MASS_INTERVAL
end
KrathongConfig.BUFF_MAX_MINUTES = 60
KrathongConfig.MAX_BUY = 99
KrathongConfig.FLOAT_COOLDOWN = 4 -- วินาที ต่อคน
KrathongConfig.WISH_MAX = 60 -- ตัวอักษร (ผ่านตัวกรองข้อความ Roblox ก่อนให้คนอื่นเห็น)

-- ท่าน้ำ PondDock1: ทางเดินตามแกน X ฝั่งบก x -234 ปลายท่า (แท่นกว้าง) x -270..-260, z -12..-1.6, พื้นท่า y 3.2 น้ำ y 0
KrathongConfig.STALL_TEMPLATE = "Stall" -- ServerStorage.KrathongTemplates.Stall (วางในโลกไว้แล้ว ที่ (-222, 3.9, -18) หน้าร้านหัน +Z)
KrathongConfig.FLOAT_SPOT = Vector3.new(-265, 4.5, -6.6) -- จุดกด "ลอยกระทง" บนแท่นปลายท่า
KrathongConfig.FLOAT_RANGE = 16 -- ต้องยืนใกล้จุดนี้ถึงลอยได้
KrathongConfig.WATER_Y = 0
-- ปุ่มลอยริมน้ำ (2026-11-07): ถือกระทง + หน้าตัวละครเป็นน้ำ = ปุ่ม "🌸 ลอยกระทง" ขึ้น · เซิร์ฟยอมให้จุดน้ำห่างตัวได้ไม่เกิน HERE_RANGE (แนวราบ)
KrathongConfig.HERE_PROBE = { 2.5, 4, 5.5 } -- ระยะหน้าตัวที่เช็กหาน้ำ (สตั๊ด)
KrathongConfig.HERE_RANGE = 9
KrathongConfig.HERE_STEP = 4 -- เส้นทางไหล: ทุก 4 สตั๊ดเช็กว่ายังเป็นน้ำ (เจอฝั่ง = เลี้ยว ±30/60° ไม่ได้ = หยุดลอยอยู่ตรงนั้น)
KrathongConfig.HERE_STEPS = 14
-- เส้นทางที่กระทงไหล (จุดแรก = ลงน้ำข้างแท่น) น้ำโล่งไปทาง -X และ -Z
KrathongConfig.PATH = {
	Vector3.new(-272, 0, -6.6),
	Vector3.new(-280, 0, -14),
	Vector3.new(-286, 0, -30),
	Vector3.new(-290, 0, -50),
	Vector3.new(-294, 0, -70),
}
KrathongConfig.PRAY_SECONDS = 4.6 -- คุกเข่า 0.6 + ยกกระทงจรดหน้าผากอธิษฐาน + วิสุดท้าย 1.1 โน้มตัววางลงน้ำ (วินาที)
KrathongConfig.FLOAT_SECONDS = 300 -- ไหลจนจางหาย (5 นาที ผู้ใช้สั่ง 2026-11-08 เดิม 100)
KrathongConfig.MAX_FLOATING = 40 -- ต่อเครื่อง (ฝั่งผู้เล่น) เกินนี้ลบใบเก่าสุด
KrathongConfig.LIGHT_LIMIT = 12 -- ใบที่มีแสงเทียนจริง (PointLight) พร้อมกัน ไม่ใช้ Highlight (ช่อง Highlight 255 เต็มในเกมจริง)

function KrathongConfig.Name(id, lang)
	local t = KrathongConfig.Types[id]
	if not t then return tostring(id) end
	return lang == "en" and t.NameEn or t.NameTh
end

function KrathongConfig.Short(n)
	n = math.floor(tonumber(n) or 0)
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then out = out:sub(2) end
	return out
end

return KrathongConfig
