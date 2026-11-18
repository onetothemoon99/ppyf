-- Backup (changed sections only) before "warp button to the Robot Owl", 2026-11-17
-- Restore: undo each change listed below in Studio (each section shows the original code).

-- [1] game.ReplicatedStorage.WarpConfig (ModuleScript)
--     Change: one new entry { Id = "owl", ... } added at the end of WarpConfig.Destinations (no Cat = not listed in the ☰ Warp menu).
--     Restore: delete that one line.

-- [2] game.ServerScriptService.WarpService (Script), in warpRequest.OnServerEvent
--     Change: new `if dest.Npc then ... end` block inserted right after the `if dest.MyLot then ... end` block (ends with:)
		dest = { Pos = sum / n, Look = Vector3.new(0, 0, 1), Name = dest.Name, En = dest.En }
	end
--     Restore: delete the inserted `if dest.Npc` block.

-- [3] game.StarterPlayer.StarterPlayerScripts.LessonNpcGui (LocalScript)
-- [3a] guideToTeacher ev:Fire table was:
		ev:Fire({
			pos = pos,
			title = tr(t.th, t.en),
			text = tr(t.guideTh, t.guideEn),
			mark = tr(t.th, t.en),
			arriveDist = t.arriveDist,
			doneText = tr(t.doneTh, t.doneEn),
		})
-- [3b] coin listener end was:
		local active = sellGuide
		sellGuide = nil
		finishGuideHere(active.title, tr(active.lesson.soldTh, active.lesson.soldEn))

-- [4] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide (LocalScript)
-- [4a] STEPS npc entry was:
	{ id = "npc", th = "ไปคุยกับหุ่นนกฮูก มีอย่างอื่นให้ลองอีก", en = "Talk to the Robot Owl for more to try",
		markTh = "หุ่นนกฮูก", markEn = "Robot Owl" },
-- [4b] enterStep: line `markText = tr(s.markTh, s.markEn)` had no setWarp after it.
-- [4c] finish(): `hideWorld()` had no setWarp(nil) after it.
-- [4d] guideTo: no closeWhenOpen handling; no closeWhenOpen variable / RenderStepped watcher.
