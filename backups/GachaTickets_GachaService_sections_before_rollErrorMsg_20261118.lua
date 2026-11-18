-- Section backup (2026-11-18) before change "rollErrorMsg".
-- Only the edited sections are saved (the rest of both scripts is unchanged).
-- To restore: in Studio, paste each section back over the new version of the same function.
--   1) game.ServerScriptService.GachaTickets  -> function GachaTickets.SpendAndRoll (failure branch, lines 178-181)
--   2) game.ServerScriptService.GachaService  -> local function roll(...) "if not spent then" block (lines 427-429)

-- ===== 1) GachaTickets.SpendAndRoll failure branch (original) =====
	if not ok then
		warn("GachaTickets: หักตั๋ว/สุ่ม " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
		return false, nil, GachaTickets.Get(player, typeId)
	end

-- ===== 2) GachaService roll() not-spent block (original) =====
	if not spent then
		return { ok = false, message = string.format("%s ไม่พอ (มี %d ใบ)", ticketType.DisplayName, left or 0) }
	end
