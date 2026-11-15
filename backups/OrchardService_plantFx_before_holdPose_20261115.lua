-- Backup 2026-11-15 (partial: only the parts changed by "holdPose"; full script is ~190k chars)
-- Studio path: game.ServerScriptService.Orchard.OrchardService
-- Restore: in OrchardService, replace the new versions of these 3 pieces with the text below
--   (1) the start of plantFx, (2) the plantFx call in actions.plant, (3) the end of actions.plant.
--   Also delete the new PLANT_POSE_MAX constant and plantPoseDone function placed just above plantFx.

-- (1) start of plantFx (old: pose always cleared after 1.1 s)
local function plantFx(player, hole, kind)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (char and root and hole) then return end
	local token = (plantToken[player] or 0) + 1
	plantToken[player] = token
	char:SetAttribute("OrchardPlantAt", hole.Position)
	task.delay(1.1, function()
		if plantToken[player] == token and char.Parent then char:SetAttribute("OrchardPlantAt", nil) end
	end)
	-- ... rest of plantFx unchanged (seed drop + dust at 0.35 s)

-- (2) call in actions.plant
	pcall(plantFx, player, hole, kind) -- ท่าหยิบเมล็ดลงหลุม (2026-11-02)

-- (3) end of actions.plant
	if not ok then
		OrchardItems.Give(player, OrchardItems.SEED, kind, 1, lang(player)) -- เซฟสวนไม่ได้ = คืนเมล็ด
		if claim and not needsLot(player) then releaseLot(player) end
		return reply(player, false, msg(player, SAVE_FAIL_TH, SAVE_FAIL_EN))
	end
	saveBag(player)
	render(player)
	return reply(player, true, msg(player,
