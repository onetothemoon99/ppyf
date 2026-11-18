-- Backup 2026-11-17 before helpQueue (partial: helpTree lines ~2222-2231)
-- Studio path: game.ServerScriptService.Orchard.OrchardService (Script)
-- Restore: put this back in place of the queue block in helpTree (and delete HELP_QUEUE_WAIT / HELP_SAVE_WAIT above helpTree).
	local key = lot.Name .. "#" .. holeNo
	if helpingKey[key] or busy[owner] then return notify(helper, msg(helper, "ลองใหม่อีกครั้ง", "Please try again")) end
	helpingKey[key], busy[owner] = true, true
	local okCall, saved = pcall(commit, owner, ownerSt, function(d)
		local t = d.trees[tostring(holeNo)]
		if not (t and t.dead and not t.revived) then return false end
		OrchardData.StartNewCycle(t, OrchardData.Now())
		-- ฟื้นแล้วเก็บได้ RevivedHarvests รอบ (2026-11-07 ผู้ใช้สั่ง) ครบแล้วแห้ง revived = true รดซ้ำไม่ได้ ต้องตัด
		applyRevive(t)
	end)
