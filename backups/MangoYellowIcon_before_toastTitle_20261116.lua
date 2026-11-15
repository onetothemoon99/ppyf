-- Backup 2026-11-16 before "yellow mango image in toasts + orchard window" (plan items 1-2)
-- (A) game.StarterPlayer.StarterPlayerScripts.HarvestNotifyGui — showSoftMessage before the change.
--     Restore: replace the new showSoftMessage (it has a "YellowIcon" block) with this one.
-- (B) game.StarterPlayer.StarterPlayerScripts.OrchardGui — nothing was removed; a new block was inserted just above
--     "-- ============ ข้อมูล + วาด ============" (starts with "-- 2026-11-16 ผู้ใช้สั่ง: อีโมจิ 🥭" and ends with the iconify(...) calls).
--     Restore: delete that block.

-------- (A) HarvestNotifyGui.showSoftMessage --------
local function showSoftMessage(text)
	softCount += 1
	local label = Instance.new("TextLabel")
	label.LayoutOrder = softCount
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y -- ข้อความยาวขึ้นบรรทัดใหม่ ไม่ทับอันถัดไป
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLOR_TEXT_LIGHT
	label.TextStrokeColor3 = COLOR_TEXT_OUTLINE
	label.TextStrokeTransparency = 0.2
	label.TextSize = 20
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	label.Parent = softStack
	TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0, TextStrokeTransparency = 0.2 }):Play()
	task.delay(2.2, function()
		local hide = TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 })
		hide:Play()
		hide.Completed:Wait()
		label:Destroy()
	end)
end
