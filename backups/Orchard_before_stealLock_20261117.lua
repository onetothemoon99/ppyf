-- Backup 2026-11-17 before stealLock (partial: changed sections only)
-- Restore: put these back and delete the "stealLock" helpers (setStealLock / clearStealLock / lockedPrompt) in OrchardService
-- and the StealingBy check + signal in OrchardGui.

-- ===== game.ServerScriptService.Orchard.OrchardService: endAttempt (~line 2454) =====
local function endAttempt(thief, why, keepPose) -- keepPose = กดขโมยครบ ให้ท่าค้างระหว่างเซฟ (2026-11-16)
	local at = attempts[thief]
	if not at then return end
	attempts[thief] = nil
	if at.slap then at.slap:Destroy() end

-- ===== OrchardService: beginAttempt start (~line 2466) =====
local function beginAttempt(thief, lot, holeNo, prompt)
	local owner = ownerOf[lot]
	local hole = lot:FindFirstChild("Hole" .. holeNo)
	if not (owner and hole) or (owner == thief and not selfStealTest()) then return end

-- ===== OrchardService: StealPrompt.Triggered (~line 2756) =====
			prompt.Triggered:Connect(function(player)
				-- ท่าสอยค้างจนได้ผล (2026-11-16): รอบท่านี้ = ค่าตอนกดครบ · กันค้าง STEAL_POSE_MAX · steal จบ (ทุกทาง) = ลบท่า
				local tok = pickToken[player]
				task.delay(STEAL_POSE_MAX, pickPoseDone, player, tok)
				local ok, err = pcall(steal, player, lot, i, prompt, tok)
				pickPoseDone(player, tok)
				if not ok then warn("OrchardService: steal error: " .. tostring(err)) end
			end)

-- ===== game.StarterPlayer.StarterPlayerScripts.OrchardGui: applySteal + hookSteal (~line 1721, 1738) =====
	local show = holding and prompt:GetAttribute("CanSteal") == true and owner ~= nil and (owner ~= player.UserId or selfTest)
	stealPrompts[prompt] = lot
	prompt.Destroying:Connect(function() stealPrompts[prompt] = nil end)
