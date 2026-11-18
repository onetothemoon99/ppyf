-- Section backup of ServerScriptService.Orchard.OrchardService (Studio), 2026-11-18, before "instantFertilize"
-- (fertilizing waited for the orchard DataStore save before replying). Was L1306-1315 inside actions.fertilize.
-- Restore: in Studio replace the "outsideEdit ... SaveLater" lines in actions.fertilize with this block.

	local ok = commit(player, st, function(d)
		local t = d.trees[tostring(holeNo)]
		t.plantedAt -= secs
		t.cycleStart -= secs
		t.fed = t.cycleStart
	end)
	if not ok then
		OrchardItems.GiveMat(player, "Fertilizer", 1, lang(player))
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
