-- Backup 2026-11-17 before idThemes (partial: changed sections only; the "first" theme from earlier today is already in)
-- Earlier backup of the same area (before "first"): backups/ChickenContest_before_firstTheme_20261117.lua
-- Restore: put these sections back and delete the lowid/highid theme rows + CONTEST_ROTATION_V2.

-- ===== game.ReplicatedStorage.ChickenConfig =====
	{ Id = "first", Icon = "🏃", Th = "ส่งเร็วที่สุด", En = "First to enter", Hint = { "ส่งก่อนชนะ ไม่ดูค่าของไก่ (เปลี่ยนไก่ทีหลัง = เวลาส่งเดิม)", "Earliest entry wins, chicken stats don't count (switching keeps your time)" } },
}
-- (2026-11-17 first) หัวข้อที่ 6 เริ่มหมุนตั้งแต่สัปดาห์ 2968 (จ. 24 พ.ย. 2026) สัปดาห์ก่อนหน้านั้นหมุน 5 หัวข้อเดิม (หัวข้อสัปดาห์ที่เล่นอยู่ไม่เปลี่ยนกลางทาง)
--   สัปดาห์แรกของรอบใหม่ = "first" แล้วต่อ best, speed, size, gold, mut, first, ...
ChickenConfig.CONTEST_THEMES_V2_FROM = 2968
ChickenConfig.CONTEST_OLD_THEME_COUNT = 5

function ChickenConfig.ContestTheme(week)
	local list = ChickenConfig.CONTEST_THEMES
	if week < ChickenConfig.CONTEST_THEMES_V2_FROM then
		return list[week % ChickenConfig.CONTEST_OLD_THEME_COUNT + 1]
	end
	return list[(week - ChickenConfig.CONTEST_THEMES_V2_FROM + #list - 1) % #list + 1]
end

function ChickenConfig.ContestStat(themeId, c)
	local base = ChickenConfig.ChickenScore(c)
	if themeId == "speed" then return c.speed * 1000 + base end
	if themeId == "size" then return c.size * 1000 + base end
	if themeId == "gold" then return c.gold * 1000 + base end
	if themeId == "mut" then
		local m = c.mut and ChickenConfig.Mutations[c.mut]
		return (m and m.Order or 0) * 1000 + base
	end
	if themeId == "first" then return 0 end -- (2026-11-17 first) ไม่ดูค่าไก่ อันดับ = เวลาส่งล้วนๆ
	return base
end

-- ===== game.ServerScriptService.ChickenFarm.ChickenService, actions.contestEnter =====
	local stat = Config.ContestStat(theme.Id, c)

-- ===== game.StarterPlayer.StarterPlayerScripts.ChickenGui, statText first line =====
	if themeId == "first" then return tr("ส่ง ", "Entered ") .. Config.ContestSinceText(since, LANG == "th") end -- (2026-11-17 first) แสดงเวลาส่งแทนคะแนน

-- ===== game.ServerScriptService.ChickenFarm.ChickenContestBoard, statText first line =====
	if themeId == "first" then return "🏃 ส่ง " .. Config.ContestSinceText(since, true) end -- (2026-11-17 first) เวลาส่ง (เวลาไทย)
