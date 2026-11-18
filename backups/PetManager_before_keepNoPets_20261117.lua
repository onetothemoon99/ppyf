-- Backup 2026-11-17 before keepNoPets (partial: the 3 changed sections; PetManager is large)
-- Studio path: game.ServerScriptService.PetSystem.PetManager (Script)
-- Restore: put these sections back and delete "local choseNone" (added above the petSelect handler).

-- ===== petSelect handler (~line 413) =====
petSelect.OnServerEvent:Connect(function(player, petId)
	if type(petId) ~= "string" or not PetDefinitions[petId] then return end
	if not PetOwnership.Owns(player, petId) then
		harvestNotify:FireClient(player, nil, nil, nil, "🔒 ยังไม่มีสัตว์เลี้ยงตัวนี้")
		return
	end
	spawnPetFor(player, petId)
	scheduleSave(player)
end)

-- ===== applySavedSettings (~line 529) =====
	if type(data) ~= "table" or type(data.pets) ~= "table" or #data.pets == 0 then
		return false -- ผู้เล่นใหม่ หรือเคยปิดสัตว์เลี้ยงไว้หมด
	end

-- ===== setupPlayer CharacterAdded (~line 600) =====
		if getTotalActive(player) == 0 then
			ensurePet(player, DEFAULT_PET_ID)   -- ไม่มีสักตัว ให้ตัวเริ่มต้นกลับมา
		else
