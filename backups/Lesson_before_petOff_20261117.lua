-- Backup 2026-11-17 before petOff (partial: 2 lines/sections)
-- Restore:
-- ===== game.ReplicatedStorage.LessonConfig line ~18 =====
LessonConfig.Off = { chicken = true }
-- ===== game.ServerScriptService.LessonService markReady (~line 108) =====
local function markReady(player, st, id)
	if st.data.ready[id] or st.data.claimed[id] then return end
