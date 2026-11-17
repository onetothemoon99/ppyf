-- Backup 2026-11-17 before yellowCardIcon (partial: insert only)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.ShopGui (LocalScript)
-- Restore: delete the block marked "ไอคอนการ์ดมะม่วงเหลือง (2026-11-17)" that sits between these unchanged lines (~512-522):

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = config.icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = iconBox

	if config.previewModel and ItemPreview.Create(iconBox, config.previewModel) then
		iconLabel.Visible = false
	end
