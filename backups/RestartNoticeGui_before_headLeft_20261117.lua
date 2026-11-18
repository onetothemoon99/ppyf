-- Backup 2026-11-17 before headLeft (partial: only layout() changed; script is 217 lines)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.RestartNoticeGui (LocalScript)
-- Restore: replace the layout function (and delete helpButtonShown / HEAD_LEFT_X above it) with:

local function layout()
	local w = gui.AbsoluteSize.X
	if w < 10 then w = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 800 end
	local pw = math.clamp(w - 24, 260, 460)
	card.Size = UDim2.fromOffset(pw, PANEL_TOP + PANEL_H)
	panel.Size = UDim2.fromOffset(pw, PANEL_H)
end
