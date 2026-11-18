-- Backup 2026-11-17 before noMassWarn (partial: removed block only)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.KrathongClient (LocalScript), line ~1276
-- Restore: put this block back right after the line
--   cdPill.Visible = f ~= nil -- 2026-11-16 ...
			-- เตือน 1 นาทีก่อน (ครั้งเดียวต่อรอบ) คนที่อยู่ไม่ไกลจากลาน
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if left <= Config.MASS_WARN and warned ~= nextT and root and (not f or (root.Position - Config.LANTERN_FIELD).Magnitude < 400) then
				warned = nextT
				if f then
					showToast(tr("🏮 อีก 1 นาที ปล่อยโคมพร้อมกันที่ลาน · ยืนในลาน = โคมฟรี + บัฟ", "🏮 Group lantern release in 1 minute · stand inside = free lantern + buff"))
				else
					showToast(tr("🏮 อีก 1 นาที ปล่อยโคมพร้อมกัน · ดูโคมลอยขึ้นจากทะเลหน้าหาด", "🏮 Group lantern release in 1 minute · watch the lanterns rise over the sea"))
				end
			end
