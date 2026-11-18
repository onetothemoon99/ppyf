-- Backup (changed sections only) before the fish-lesson warp button / shop highlight / sell-caught-fish change, 2026-11-17
-- Restore: put each section back in place of the new code in Studio.

-- [1] game.StarterPlayer.StarterPlayerScripts.LessonNpcGui (LocalScript), the FishingState listener (was lines 327-358)
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
	local fishingState = remotes:WaitForChild("FishingState", 120)
	if not fishingState then return end
	fishingState.OnClientEvent:Connect(function(state)
		if state ~= "caught" or not catchGuide then return end
		local active = catchGuide
		catchGuide = nil
		if not guideCardIs(active.title) then return end
		local lesson = active.lesson
		local shopPos = lesson.sellPos and lesson.sellPos()
		if not shopPos then -- หาร้านไม่เจอ = แจ้งตกได้แล้วจบแบบเดิม
			finishGuideHere(active.title, tr(lesson.catchTh, lesson.catchEn))
			return
		end
		local guide = playerGui:FindFirstChild("NewPlayerGuideGui")
		local ev = guide and guide:FindFirstChild("GuideTo")
		if not ev then return end
		playSuccess()
		ev:Fire({
			pos = shopPos,
			title = active.title,
			text = tr(lesson.catchTh, lesson.catchEn),
			mark = tr(lesson.sellMarkTh, lesson.sellMarkEn),
			arriveDist = lesson.sellArriveDist,
			doneText = tr(lesson.sellArriveTh, lesson.sellArriveEn),
			stay = true,
			shopHint = "fishSell", -- 2026-11-15 เปิดร้านตกปลาแล้ว NewPlayerGuide ไฮไลต์แท็บขายปลา / ขายทั้งหมด
		})
		sellGuide = { lesson = lesson, title = active.title, pos = shopPos }
	end)
end)

-- [2] game.ReplicatedStorage.LessonContent (ModuleScript), fish lesson lines (was lines 84 and 87)
		catchTh = "ตกได้แล้ว! ไปขายปลาที่ร้านตกปลา (ไกล? เมนูขีดสามเส้น > วาป)", catchEn = "You caught one! Sell it at the Fishing Store (far? menu > Warp)",
		sellArriveTh = "ถึงร้านแล้ว! กด E ที่ร้าน แล้วกดขายปลา", sellArriveEn = "You're at the store! Press E, then sell your fish",
