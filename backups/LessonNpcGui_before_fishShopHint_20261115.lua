-- Backup (one line)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.LessonNpcGui (LocalScript), fishing chain after the first catch (ev:Fire to the fishing shop)
-- Change (2026-11-15): pass shopHint = "fishSell" so NewPlayerGuide highlights Sell Fish / Sell All in the fishing shop.
-- Restore: remove the `shopHint = "fishSell",` line after `stay = true,` in that ev:Fire table.
			stay = true,
		})
		sellGuide = { lesson = lesson, title = active.title, pos = shopPos }
