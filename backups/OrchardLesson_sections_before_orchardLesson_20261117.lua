-- Backup (changed sections only) before the "orchard lesson + Uncle Manao" change, 2026-11-17
-- Restore: undo each change below in Studio. New script ServerScriptService.Orchard.UncleManao = delete it.

-- [1] game.ReplicatedStorage.LessonConfig
LessonConfig.Order = { "basic", "fish", "pet", "chicken" } -- pet = บทสัตว์เลี้ยง 2026-11-15 (ต่อจากตกปลา)
--   Rewards / XpRewards had no `orchard` entry.

-- [2] game.ServerScriptService.LessonService
--   NAMES had no `orchard` row.
--   normalize(d) had no `d.orchard` line; save() merge had no orchard lines.
--   request.OnServerInvoke was:
request.OnServerInvoke = function(player, action, id)
	if action == "claim" then return claim(player, id) end
	return { ok = false }
end
--   No "orchard quest" section / OrchardQuest BindableFunction. PlayerRemoving line was:
Players.PlayerRemoving:Connect(function(player) states[player] = nil; feedWatch[player] = nil end) -- ready/claimed เซฟทันทีตอนเปลี่ยน ไม่มีอะไรค้างตอนออก

-- [3] game.ReplicatedStorage.LessonContent: new lesson table `id = "orchard"` inserted after the fish lesson (delete it).

-- [4] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide: ORCHARD_STEPS set + checkOrchardStep + "orchard" branches in
--     start/enterStep/checkStep/finish/stop/findHintTarget (search "2026-11-17 บทสวนมะม่วง"). Full source from earlier today:
--     backups/NewPlayerGuide_before_fishWarpShop_20261117.lua (older; also lacks the fish/owl warp changes).

-- [5] game.StarterPlayer.StarterPlayerScripts.HotbarState, AutoAssignNew: line before `if not restoreDone and not tryRestore(allTools) then return end`
--     had no GuideHandSlot block (search "GuideHandSlot").

-- [6] game.StarterPlayer.StarterPlayerScripts.ShopGui line ~815 was:
		if actionButton and item.CropType ~= BOOSTER_CROP_TYPE and not item.Info then actionButton:SetAttribute("GuideBuySeed", index) end

-- [7] game.StarterPlayer.StarterPlayerScripts.OrchardGui ~line 2433 was:
	local guard = workspace:FindFirstChild("OrchardFakeGuard")
	local slapAt = guard and guard:GetAttribute("SlapAt")
	if slapAt then
		local age = workspace:GetServerTimeNow() - slapAt
		local sh = age < 0.45 and rigJoint(guard, "RightUpperArm", "RightShoulder")
		if sh then
			local a = age < 0.15 and (age / 0.15) * 160 or 160 - ((age - 0.15) / 0.3) * 200
			sh.Transform = sh.Transform * CFrame.Angles(math.rad(a), 0, math.rad(-25))
		end
	end
