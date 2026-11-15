-- Backup 2026-11-16 (partial: only the parts changed by "steal holdPose"; full script is ~190k chars)
-- Studio path: game.ServerScriptService.Orchard.OrchardService
-- Restore: in OrchardService, replace the new versions of these pieces with the text below:
--   (1) `local stealing = {}` line (~2104) — also delete the new pickToken / STEAL_POSE_MAX / pickPoseDone lines added after it
--   (2) the whole `endAttempt` function
--   (3) in `beginAttempt`: the line that sets OrchardPickAt
--   (4) the start of `steal` (first 4 lines) — the rest of `steal` changed only `return notify(thief,` -> `return failNotify(thief,`
--       and one added `pickPoseDone(thief, myPick)` line before `harvestNotify:FireClient`; revert those
--   (5) StealPrompt `prompt.Triggered` handler
--   (6) PlayerRemoving: delete the added `pickToken[player] = nil` line

-- (1)
local stealing = {} -- ["Lot01#2"] = true ระหว่างเซฟ

-- (2)
local function endAttempt(thief, why)
	local at = attempts[thief]
	if not at then return end
	attempts[thief] = nil
	if at.slap then at.slap:Destroy() end
	if at.char then at.char:SetAttribute("OrchardPickAt", nil) end
	if at.owner.Parent and not isFake(at.owner) then alertRemote:FireClient(at.owner, "stop", { thief = thief, why = why }) end
end

-- (3)
	thief.Character:SetAttribute("OrchardPickAt", hole.Position)

-- (4)
local function steal(thief, lot, holeNo, prompt)
	local hs = holdStart[thief]
	holdStart[thief] = nil
	endAttempt(thief, "done")

-- (5)
			prompt.Triggered:Connect(function(player)
				local ok, err = pcall(steal, player, lot, i, prompt)
				if not ok then warn("OrchardService: steal error: " .. tostring(err)) end
			end)

-- (6)
	stunnedUntil[player] = nil
