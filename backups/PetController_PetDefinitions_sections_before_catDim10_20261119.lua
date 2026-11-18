-- SECTION BACKUP 2026-11-19 (before NineLivesCat -10% brightness). Only the parts that changed; the rest of each script was not touched.
-- Restore = put these sections back exactly as below (or simply delete the lines marked "2026-11-19 AuraDim" in each script).

-- ===== ServerScriptService.PetSystem.PetController : applyRarityGlow, the `local dim` line (was) =====
	local dim = glow.AuraDim or 1 -- ลดความสว่างออร่า (ไม่รวมไฟที่มังกรพ่น)

-- ===== ServerScriptService.PetSystem.PetController : PetController.Spawn, before applyRarityGlow (was) =====
	pet:SetAttribute("FacingOffset", def.FacingOffset or CFrame.new())
	applyRarityGlow(pet, def.Rarity) -- จำนวนดวงไฟ = ชีวิตที่เหลือ (อ่านจาก PetLives_<petId> ของเจ้าของ)

-- ===== ServerScriptService.PetSystem.PetDefinitions : NineLivesCat (was) =====
		NineLives = 9, -- จำนวนชีวิต (ฟื้นเองตอนหิวจนหมดแรงได้เท่านี้ครั้ง)
		FireflyRing = true, -- ดวงไฟวิญญาณบินวนรอบตัว (วาดฝั่งผู้เล่นใน PetFireflyRing) จำนวนดวง = ชีวิตที่เหลือ
