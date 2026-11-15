-- Backup (เฉพาะท่อนที่แก้) ก่อนแก้ "ไก่ดึงอาหารสัตว์ออกจากกระเป๋าระหว่างบทสัตว์เลี้ยง" 2026-11-16
-- ย้อนกลับ: แทนแต่ละท่อนด้วยของเดิมข้างล่าง แล้วลบฟังก์ชัน petLessonHold ที่เพิ่มเหนือ `local function autoWork`

-- [1] game.ServerScriptService.ChickenFarm.ChickenService ใน autoWork (เดิมบรรทัด 1942)
	player:SetAttribute("ChickenTroughLow", (feedLow and d.autoFeedMachine) and true or nil)
-- [2] ChickenService ใน autoWork (เดิมบรรทัด 1947)
		if feedLow then

-- [3] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide ใน enterStep
		pet = { maxTickets = normalTickets(), pets = petIdSet(), food = petFoodCount(), minHunger = hungerSum() }
-- [4] NewPlayerGuide ใน checkPetStep ขั้น feed
		if petFoodCount() < pet.food or h > pet.minHunger + 0.5 then return true end
