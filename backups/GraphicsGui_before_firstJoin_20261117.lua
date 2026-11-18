-- Backup 2026-11-17 before firstJoin (partial: 1 changed section + 1 insert)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.GraphicsGui (LocalScript)
-- Restore:
--   1) delete "local firstIntro = false" (next to "local statusMode = nil", ~line 188)
--   2) put the status block in refresh() back to this:
	if statusMode == "saved" then
		statusLabel.Text = T("Graphics_Saved")
	elseif player:GetAttribute(GraphicsConfig.CHOSEN_ATTRIBUTE) == false then
		statusLabel.Text = T("Graphics_Auto")
	else
		statusLabel.Text = ""
	end
--   3) delete the block "เปิดเองครั้งแรกสำหรับผู้เล่นใหม่ (2026-11-17)" at the end of the "เปิด / ปิด" section.
