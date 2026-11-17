-- Backup 2026-11-16 before fertPose (partial: all 3 changes are INSERTS plus 2 one-line edits; scripts are large)
-- Restore:
-- 1) game.ReplicatedStorage.OrchardConfig: in OrchardConfig.KitSounds delete the line starting with "Fertilize =".
-- 2) game.ServerScriptService.Orchard.OrchardService:
--    - delete the block "-- ท่าใส่ปุ๋ย + เสียง (2026-11-16)" ... "-- (จบ ท่าใส่ปุ๋ย)" just above "function actions.fertilize"
--    - in actions.fertilize delete the line "fertFx(player, hole)" (right after the TakeMat check).
-- 3) game.StarterPlayer.StarterPlayerScripts.OrchardGui:
--    - delete the constants block starting "-- ท่าใส่ปุ๋ย (2026-11-16)" (after "local planting = {}")
--    - delete the loop block "-- โรยปุ๋ย (ทุกคนที่กำลังใส่ปุ๋ย)" ... "-- (จบ โรยปุ๋ย)" (before the fake guard block)
--    - put the facing line back to the original below.
-- Original lines (OrchardGui ~2241):
	local pickAt = ch and (ch:GetAttribute("OrchardPickAt") or ch:GetAttribute("OrchardHarvestAt") or ch:GetAttribute("OrchardPlantAt")) -- เก็บเกี่ยว/ปลูกก็หันเข้าหลุม (2026-11-02)
-- Original lines (OrchardService actions.fertilize ~1136-1139):
	if not OrchardItems.TakeMat(player, "Fertilizer", 1, lang(player)) then
		return reply(player, false, msg(player, "ไม่มีปุ๋ยไม้ผล ทำได้ที่เครื่องทำปุ๋ยข้างร้านผลไม้ (ใช้ท่อนไม้)", "No tree fertilizer, make it at the machine by the fruit stall (uses logs)"))
	end
	local secs = Config.FertilizerSeconds
-- Original OrchardConfig.KitSounds last entry:
	Trumpet = "rbxassetid://9114300941", -- Elephant Trumpets Grunts 1 ช้างร้องตอนเริ่มพ่น
}
