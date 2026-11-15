-- Backup 2026-11-16 (partial: only the lines changed by "no tree cooldown after slap"; OrchardService is ~190k chars, OrchardConfig ~37k)
-- Restore: put these lines back in place of the new ones.

-- (1) game.ReplicatedStorage.OrchardConfig, line 189 (inside Steal = { ... }):
	TreeCooldown = 600, -- (เฟส 4) ต้นที่เจ้าของตบจับขโมยได้ พักกี่วินาที (ต่อเซิร์ฟ ไม่เซฟ)

-- (2) game.ServerScriptService.Orchard.OrchardService, lines 2332-2333 (in slapThief, notify(owner, ...)):
		string.format("👋 ตบ %s ทัน! ต้นนี้ปลอดภัย %d นาที%s", thief.DisplayName, math.floor((Steal.TreeCooldown or 600) / 60), reward > 0 and (" · ได้ " .. Config.Short(reward) .. " เหรียญ") or ""),
		string.format("👋 You slapped %s in time! This tree is safe for %d min%s", thief.DisplayName, math.floor((Steal.TreeCooldown or 600) / 60), reward > 0 and (" · +" .. Config.Short(reward) .. " coins") or "")))
