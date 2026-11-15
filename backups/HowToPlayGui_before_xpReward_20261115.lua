-- BACKUP 2026-11-15 ก่อนเพิ่ม EXP ในป้ายรางวัลบทเรียน
-- Studio path: game.StarterPlayer.StarterPlayerScripts.HowToPlayGui (LocalScript) — สำรองเฉพาะท่อนที่แก้
-- คืนค่า: ลบฟังก์ชัน rewardText ที่เพิ่มไว้ใต้ formatCoins แล้วเปลี่ยน rewardText(d.id, coins) กลับเป็น formatCoins(coins) (2 จุด)
-- ========================================================================
					row.name.Text = nameText .. " · 💰 " .. formatCoins(coins)
					row.name.Text = state and (nameText .. " · 💰 " .. formatCoins(coins)) or nameText

-- (เพิ่ม) ป้ายชื่อแถว ก่อนให้ย่อตัวหนังสือพอดีช่อง (เพิ่ม TextScaled + UITextSizeConstraint ต่อท้ายท่อนนี้ ลบออก = คืนค่า)
	name.TextSize = 17
	name.TextColor3 = COLOR_TEXT
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card
