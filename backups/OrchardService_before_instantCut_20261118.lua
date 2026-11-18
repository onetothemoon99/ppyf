-- Section backup of ServerScriptService.Orchard.OrchardService (Studio), 2026-11-18, before "instantCut"
-- (cutting a dead tree waited for the orchard DataStore save before giving wood). Was L1181-1182 inside actions.cut.
-- Restore: in Studio replace the "outsideEdit ... SaveLater" lines in actions.cut with these two lines.

	local ok = commit(player, st, function(d) d.trees[tostring(holeNo)] = nil end)
	if not ok then return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN)) end
