-- BACKUP of ReplicatedStorage.GraphicsConfig taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ReplicatedStorage.GraphicsConfig, select all, paste everything BELOW the next line.
-- ===== original Source (8814 bytes, hash 9900862) =====
-- GraphicsConfig: ระดับกราฟิกที่ผู้เล่นเลือกเองได้ (2026-10-03) ทำฝั่งผู้เล่นล้วน คนอื่นไม่เห็นผล
-- ใช้ร่วมกันระหว่าง GraphicsQuality (ตัวใช้ค่า), GraphicsGui (หน้าต่าง), CropAura / AmbientCritters (เพดานเอฟเฟกต์) และ GraphicsPrefs (ตัวจำค่าฝั่งเซิร์ฟเวอร์)
-- วัดผลจริงใน Studio ได้เฉพาะ "เงา" (ปิดแล้วเฟรมเร็วขึ้นราวเท่าตัว) ที่เหลือเป็นการลดงานตามหลักทั่วไป ตัวเลขเฟรมที่ได้ดูจาก FPS สดในหน้าต่างบนเครื่องจริง

local GraphicsConfig = {}

GraphicsConfig.ATTRIBUTE = "GraphicsQuality" -- Attribute บนตัวผู้เล่น = ระดับที่ใช้อยู่ตอนนี้ (ตั้งฝั่งผู้เล่นเอง สคริปต์เอฟเฟกต์อ่านจากตรงนี้)
GraphicsConfig.CHOSEN_ATTRIBUTE = "GraphicsChosen" -- true = ผู้เล่นเลือกเอง/เคยบันทึกไว้ (false = ระบบเลือกให้ตามอุปกรณ์)
GraphicsConfig.SAVED_ATTRIBUTE = "GraphicsSaved" -- เซิร์ฟเวอร์ตั้งให้ตอนเข้าเกม = ระดับที่เคยบันทึก (ไม่มี = ยังไม่เคยเลือก)
GraphicsConfig.LOADED_ATTRIBUTE = "GraphicsLoaded" -- เซิร์ฟเวอร์ตั้ง true เมื่ออ่านค่าที่บันทึกเสร็จ (สำเร็จหรือไม่ก็ตาม)
GraphicsConfig.DEFAULT_LEVEL = "high"

-- ลำดับที่แสดงในหน้าต่าง
GraphicsConfig.Order = { "high", "mid", "low", "lowest" }

-- Shadows        = เงาแสงอาทิตย์ (false = ปิดเงาทั้งหมดของฉากนี้ตัวเดียวที่วัดแล้วช่วยเฟรมชัด)
-- Bloom/SunRays/DepthOfField = เอฟเฟกต์หน้าจอ true = คืนตามที่เกมตั้งไว้เดิม false = ปิด
-- MaxAuras       = ออร่าต้น 2-5 ดาวที่วาดพร้อมกันได้สูงสุด / MaxGlows = ต้นที่เรืองแสง (Highlight) พร้อมกันสูงสุด
-- WaterReflectance = ตัวคูณการสะท้อนของน้ำ (คูณกับค่าเดิมของเกม)
-- Critters       = สัดส่วนผีเสื้อ/นกที่แสดง (0 = ปิดทั้งหมด รวมหิ่งห้อย)
-- CropShadowDist = พืชที่อยู่ไกลกว่านี้ (studs) ไม่ทอดเงา (0 = ไม่ทอดเงาเลย)
-- CropHideDist   = พืชที่อยู่ไกลกว่านี้ซ่อนทั้งต้น เห็นแต่แปลงดิน (ผู้เล่นสั่ง 2026-10-03: ทุ่งไกลๆ ไม่ต้องแสดงต้นพืช)
-- CropDetailDist = พืชที่อยู่ไกลกว่านี้ซ่อนชิ้นส่วนหนักๆ (ฝักข้าวโพด รวงข้าวสาลี ฯลฯ) เหลือแค่ต้นกับใบ — CropLod
-- LightsOff      = ปิดแสงไฟ (PointLight/SpotLight/SurfaceLight) + เรืองแสง Highlight ทั้งฉาก (ออร่าสัตว์/เบ็ด/หุ่น/ไฟในแมพ) — GraphicsQuality (2026-10-10)
-- FxOff          = ปิดทุกอย่างใน LightsOff + อนุภาค (ParticleEmitter/Trail/Fire/Smoke/Sparkles) เช่น ประกายออร่า ฝน โน้ตเพลง
--                  ไม่ปิด: สายเบ็ด/ลูกศรบทสอน (Beam) กรอบช่องปลูก (SelectionBox) และอะไรก็ตามที่ตั้ง Attribute KeepFx = true
-- HideOtherPets  = ไม่วาดสัตว์เลี้ยงของผู้เล่นคนอื่น (เซิร์ฟ 30 คน = สัตว์ 60-90 ตัว) สัตว์ยังทำงานปกติ แค่เครื่องนี้มองไม่เห็น (2026-10-10)
--                  2026-10-24 รวมสัตว์ขี่ของคนอื่น + เฟอร์นิเจอร์ที่คนอื่นวาง (PlacedFurniture) ด้วย
-- SceneHideDist  = ฉากตกแต่ง (ป่า ภูเขา หาด ต้นไม้ โคม ของเทศกาล) ที่ไกลกล้องเกินนี้ (studs) ไม่วาด — SceneLod (2026-10-24) nil = วาดหมด
-- DecorFps       = แอนิเมชันตกแต่ง (กังหัน เป็ด ตู้โชว์หมุน นากโชว์เบ็ด ฯลฯ) ขยับกี่ครั้ง/วินาที — FxThrottle (2026-10-24) nil = ทุกเฟรม, 0 = หยุดนิ่ง
-- AvatarDetailDist = ตัวละครคนอื่นที่ไกลกว่านี้ ไม่วาดของประดับ (หมวก ผม ปีก เสื้อผ้าเลเยอร์) — AvatarLod (2026-10-24) nil = วาดหมด
-- NameTagDist    = ป้ายชื่อเหนือหัวคนอื่นเห็นได้ไม่เกินระยะนี้ (เดิม 90 จาก PlayerNameTags) — AvatarLod (2026-10-24)
-- RainDrops      = สัดส่วนเม็ดฝน (ชิ้นส่วน 380 ชิ้นขยับทุกเฟรม) nil = เต็ม, 0 = ไม่มีเม็ด (เสียง/ฟ้าหม่นยังมี) — WeatherClient (2026-10-24)
-- DressingKeep   = สัดส่วนหิน/ต้นไม้แต่งเขาน้ำตก (workspace.MountainDressing) ที่แสดง ชิ้นที่ Attribute LodRank เกินค่านี้ซ่อน — DressingLod (2026-11-09) nil = แสดงหมด
-- SkyOff         = ปิดเมฆ (Terrain.Clouds) + คลื่นน้ำ (WaterWaveSize 0) เฉพาะเครื่องนี้ — GraphicsQuality (2026-10-24)
GraphicsConfig.Levels = {
	high = { Icon = "✨", DressingKeep = 1, Shadows = true, Bloom = true, SunRays = true, DepthOfField = true, MaxAuras = 40, MaxGlows = 12, WaterReflectance = 1, Critters = 1, CropShadowDist = 40, CropDetailDist = 50, CropHideDist = 80 },
	mid = { Icon = "🌤️", DressingKeep = 0.85, Shadows = true, Bloom = true, SunRays = true, DepthOfField = true, MaxAuras = 20, MaxGlows = 6, WaterReflectance = 0.5, Critters = 1, CropShadowDist = 30, CropDetailDist = 40, CropHideDist = 60 },
	low = { Icon = "🌥️", DressingKeep = 0.6, SceneHideDist = 220, DecorFps = 20, AvatarDetailDist = 60, NameTagDist = 60, RainDrops = 0.4, LightsOff = true, Shadows = true, Bloom = false, SunRays = false, DepthOfField = false, MaxAuras = 8, MaxGlows = 0, WaterReflectance = 0, Critters = 0.4, CropShadowDist = 0, CropDetailDist = 30, CropHideDist = 45 },
	lowest = { Icon = "🔋", DressingKeep = 0.35, SceneHideDist = 140, DecorFps = 0, AvatarDetailDist = 35, NameTagDist = 40, RainDrops = 0, SkyOff = true, LightsOff = true, FxOff = true, HideOtherPets = true, Shadows = false, Bloom = false, SunRays = false, DepthOfField = false, MaxAuras = 0, MaxGlows = 0, WaterReflectance = 0, Critters = 0, CropShadowDist = 0, CropDetailDist = 20, CropHideDist = 30 },
}

function GraphicsConfig.IsValid(id)
	return type(id) == "string" and GraphicsConfig.Levels[id] ~= nil
end

function GraphicsConfig.Get(id)
	return GraphicsConfig.Levels[id] or GraphicsConfig.Levels[GraphicsConfig.DEFAULT_LEVEL]
end

-- ระดับเริ่มต้นตามอุปกรณ์ (ผู้เล่นที่ยังไม่เคยเลือก): มือถือ = ต่ำ / จอยคอนโซล = กลาง / คอม = สูง
function GraphicsConfig.DefaultFor(device)
	if device == "mobile" then return "low" end
	if device == "console" then return "mid" end
	return "high"
end

return GraphicsConfig
