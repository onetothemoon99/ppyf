-- Backup 2026-11-16 (the pieces changed by "stable server number + code")
-- Studio paths: game.ServerScriptService.ServerBrowserService and game.StarterPlayer.StarterPlayerScripts.ServerBrowserGui
-- Restore: put these old pieces back in place of the new ones (and delete the new STARTED_AT / shortCode / numberServers code in ServerBrowserService).

-------- ServerBrowserService: record in publishServer --------
	local record = {
		PlaceId = game.PlaceId,
		Players = playerCount,
		MaxPlayers = Players.MaxPlayers,
		UpdatedAt = os.time(),
		-- 2026-10-20 AfkRejoin เลือกเครื่องคนเยอะสุดจากรายการนี้: เวอร์ชันใหม่สุดเท่านั้น + ไม่ใช่เครื่องที่กำลังรีเซิร์ฟ
		PlaceVersion = game.PlaceVersion,
		Restarting = isRestarting(),
	}

-------- ServerBrowserService: list action --------
		local servers = {}
		for _, entry in ipairs(entries) do
			local value = entry.value
			if type(value) == "table" and value.PlaceId == game.PlaceId and type(value.Players) == "number" then
				table.insert(servers, {
					Id = entry.key,
					Players = value.Players,
					MaxPlayers = tonumber(value.MaxPlayers) or Players.MaxPlayers,
					IsCurrent = entry.key == game.JobId,
				})
			end
		end
		return { ok = true, servers = servers }

-------- ServerBrowserGui: row heading (line 196) --------
		local heading = makeLabel(row, tr("เซิร์ฟเวอร์ %d", "Server %d"):format(index), 14, COLOR_TEXT, true)

-------- ServerBrowserGui: heading as of 2026-11-16 first change ("เซิร์ฟเวอร์ N · #CODE"), replaced the same day by "เซิร์ฟเวอร์ #CODE" --------
		-- 2026-11-16: เลข/รหัสมาจากเซิร์ฟ (ทุกคนเห็นเหมือนกัน) ไม่ใช่ลำดับแถว
		local headingText = tr("เซิร์ฟเวอร์ %d", "Server %d"):format(tonumber(server.No) or index)
		if type(server.Code) == "string" and server.Code ~= "" then headingText ..= " · #" .. server.Code end
		local heading = makeLabel(row, headingText, 14, COLOR_TEXT, true)
