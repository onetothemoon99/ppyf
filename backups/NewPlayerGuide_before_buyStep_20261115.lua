-- BACKUP 2026-11-15 ก่อนเพิ่มขั้น "ซื้อเมล็ด" เป็นขั้นแรกของการสอนผู้เล่นใหม่
-- Studio path: game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide (LocalScript) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: วางท่อนด้านล่างกลับแทนท่อนเดียวกัน แล้วลบ seedCount() / baseSeeds ที่เพิ่มไว้
-- ========================================================================
-- (1) ตาราง STEPS
local STEPS = {
	{ id = "plant", th = "กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน", en = "Tap slot 1 (seeds), then tap the soil",
		markTh = "แปลงดิน", markEn = "Soil plot" },
	{ id = "harvest", th = "รอต้นโต แล้วกดปุ่มเก็บที่ต้น", en = "Wait for it to grow, then press harvest",
		markTh = "กำลังโต...", markEn = "Growing...", readyTh = "โตแล้ว! กดเก็บ", readyEn = "Ready! Harvest" },
	{ id = "sell", th = "ไปร้านเมล็ด แล้วขายผลผลิต", en = "Go to the seed shop and sell your crops",
		markTh = "ร้านเมล็ด", markEn = "Seed shop" },
	{ id = "npc", th = "ไปคุยกับหุ่นนกฮูก มีอย่างอื่นให้ลองอีก", en = "Talk to the Robot Owl for more to try",
		markTh = "หุ่นนกฮูก", markEn = "Robot Owl" },
}

-- (2) สถานะ
local basePlant, maxPlant, baseCoins = 0, 0, 0

-- (3) enterStep
local function enterStep(n)
	step = n
	basePlant = plantCount()
	maxPlant = basePlant
	baseCoins = coins()
	targetPos = nil

-- (4) checkStep ต้นฟังก์ชัน
local function checkStep()
	local s = STEPS[step]
	if s.id == "plant" then

-- (5) start
	everStarted = true
	enterStep(1)
	gui.Enabled = true
