-- Backup 2026-11-17 before firstTheme (partial: only the changed sections of 4 scripts)
-- Restore: replace each changed section with the original text below, and delete the new
-- helpers marked "(2026-11-17 first)" in ChickenConfig.

-- ===== game.ReplicatedStorage.ChickenConfig (ModuleScript), lines 236-274 =====
ChickenConfig.CONTEST_THEMES = {
	{ Id = "best", Icon = "🏅", Th = "ไก่เก่งที่สุด", En = "Best chicken", Hint = { "คะแนนรวมแบบลานโชว์ (สายพันธุ์ + ดาวรวม + สีทอง)", "Overall score (mutation + total stars + gold colour)" } },
	{ Id = "speed", Icon = "⚡", Th = "ไข่เร็วที่สุด", En = "Fastest layer", Hint = { "ดาวไข่เร็วมากสุดชนะ", "Most speed stars wins" } },
	{ Id = "size", Icon = "🥚", Th = "ไข่ใหญ่ที่สุด", En = "Biggest eggs", Hint = { "ดาวไข่ใหญ่มากสุดชนะ", "Most size stars wins" } },
	{ Id = "gold", Icon = "✨", Th = "ไข่ทองที่สุด", En = "Golden touch", Hint = { "ดาวไข่ทองมากสุดชนะ", "Most gold stars wins" } },
	{ Id = "mut", Icon = "🌈", Th = "สายพันธุ์หายากที่สุด", En = "Rarest mutation", Hint = { "สายพันธุ์หายากกว่าชนะ (สายรุ้ง > คริสตัล > ไฟ > เรืองแสง)", "Rarer mutation wins (Rainbow > Crystal > Fire > Glow)" } },
}
function ChickenConfig.ContestTheme(week)
	return ChickenConfig.CONTEST_THEMES[week % #ChickenConfig.CONTEST_THEMES + 1]
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
	return base
end

-- ===== game.ServerScriptService.ChickenFarm.ChickenService (Script) =====
-- line 232 (info.Contest):
		EntryId = thisWeek and ct.id or nil, EntryStat = thisWeek and ct.stat or nil,
-- line 869-874 (actions.contestEnter):
	local stat = Config.ContestStat(theme.Id, c)
	local ok = commit(player, st, function(data)
		data.contest = {
			week = week, id = id, color = c.color, speed = c.speed, size = c.size, gold = c.gold, mut = c.mut,
			stat = stat, value = contestValue(stat, t, week),
		}
	end)
-- line 932 (contestBoard rows):
			table.insert(out, { Rank = i, Name = nameOf(e.userId), Stat = e.value // 1000000, Me = e.userId == player.UserId })

-- ===== game.StarterPlayer.StarterPlayerScripts.ChickenGui (LocalScript) =====
-- lines 1368-1380:
local function statText(themeId, stat)
	stat = stat or 0
	if themeId == "best" then return tr("คะแนน ", "Score ") .. stat end
	local main, rest = stat // 1000, stat % 1000
	if themeId == "mut" then
		local icon = "·"
		for _, m in pairs(Config.Mutations) do
			if m.Order == main and not m.Season then icon = m.Icon end
		end
		return (main > 0 and icon or tr("สายพันธุ์ทั่วไป", "Standard breed")) .. " · " .. rest
	end
	return stars(main) .. " · " .. rest
end
-- line 1420: ... statText(ct.ThemeId, ct.EntryStat)), nil, nil, nil, 88)
-- line 1441: ... statText(board.ThemeId, r.Stat))
-- line 1450: ... statText(board.LastThemeId, r.Stat))

-- ===== game.ServerScriptService.ChickenFarm.ChickenContestBoard (Script) =====
-- lines 52-63:
local function statText(themeId, stat)
	if themeId == "best" then return "⭐ " .. stat end
	local main, rest = stat // 1000, stat % 1000
	if themeId == "mut" then
		local icon = "·"
		for _, m in pairs(Config.Mutations) do
			if m.Order == main and not m.Season then icon = m.Icon end
		end
		return (main > 0 and icon or "—") .. " · " .. rest
	end
	return string.rep("★", math.clamp(main, 0, 5)) .. " · " .. rest
end
-- line 221:
		if userId then table.insert(top, { userId = userId, stat = e.value // 1000000 }) end
-- line 230:
		makeRow(rank, e.userId, nameCache[e.userId] or ("ผู้เล่น " .. e.userId), statText(theme.Id, e.stat))
