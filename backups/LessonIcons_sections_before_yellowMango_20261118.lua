-- Backup (changed sections only) before "lesson panels: yellow mango icon", 2026-11-18
-- Restore: delete the inserted `do ... end` block marked "yellowicon 2026-11-18" after each icon label below.

-- [1] game.StarterPlayer.StarterPlayerScripts.HowToPlayGui (row icon, ~line 220):
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 4, 0, 0)
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.Text = row.data.icon
	icon.TextSize = 26
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.Parent = card

-- [2] game.StarterPlayer.StarterPlayerScripts.LessonNpcGui (lesson card icon, ~line 227):
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 8, 0.5, 0)
	icon.Size = UDim2.fromOffset(30, 30)
	icon.Text = lesson.icon
	icon.TextSize = 22
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.Parent = card
