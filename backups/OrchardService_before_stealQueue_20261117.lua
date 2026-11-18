-- Backup 2026-11-17 before stealQueue (partial: 2 changed sections)
-- Studio path: game.ServerScriptService.Orchard.OrchardService (Script)
-- Restore: put these sections back.

-- ===== commit (line ~611 and ~630) =====
local function commit(player, st, change)
	-- ...
	if not OrchardData.SaveNow(player, 10) then

-- ===== steal(), lines ~2535-2540 =====
	local key = lot.Name .. "#" .. holeNo
	if stealing[key] or busy[owner] then
		return notify(thief, msg(thief, "ลองใหม่อีกครั้ง", "Please try again"))
	end
	stealing[key], busy[owner] = true, true
	local okCall, saved = pcall(commit, owner, ownerSt, function(d)
		local tr = d.trees[tostring(holeNo)]
		if not (tr and tr.kind == kind and canBeStolen(tr, OrchardData.Now())) then return false end
		tr.fruits -= 1
		tr.stolen = (tr.stolen or 0) + 1
		d.stats.stolenFrom += 1
	end)
