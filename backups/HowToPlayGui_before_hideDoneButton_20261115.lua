-- Backup (เฉพาะท่อนที่แก้) ของ game.StarterPlayer.StarterPlayerScripts.HowToPlayGui ก่อนแก้ "บทที่รับรางวัลแล้วไม่มีปุ่ม" 2026-11-15
-- ท่อนนี้อยู่ใน function layout() (เดิมบรรทัด 323–336) ภายใน `if show then ... for _, row in ipairs(ROWS) do`
-- ย้อนกลับ: ใน Studio แทนท่อน `if row.kind == "lesson" then ... row.go.Visible = ...` ด้วยท่อนข้างล่าง
--   และลบ local COLOR_CARD_DONE / function doneLabel ที่เพิ่มไว้เหนือ `local function layout()`
			if row.kind == "lesson" then
				local state, coins = lessonReward(d.id)
				if LessonConfig and state == LessonConfig.READY then
					row.name.Text = nameText .. " · 💰 " .. rewardText(d.id, coins)
					row.desc.Text = tr("ทำแล้ว! ไปรับรางวัลที่หุ่นนกฮูก", "Done! Claim it from the Robot Owl")
					setButton(row.go, tr("ไปรับ", "Claim"), true, true)
				elseif LessonConfig and state == LessonConfig.CLAIMED then
					row.name.Text = nameText .. " · ✅"
					setButton(row.go, d.startGuide and tr("เริ่ม", "Start") or tr("พาไป", "Take me"), false)
				else
					row.name.Text = state and (nameText .. " · 💰 " .. rewardText(d.id, coins)) or nameText
					setButton(row.go, d.startGuide and tr("เริ่ม", "Start") or tr("พาไป", "Take me"), false)
				end
				row.go.Visible = d.startGuide == true or d.getPos ~= nil
