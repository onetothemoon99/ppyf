-- Backup (changed sections only) before "orchard: water/steal buttons only while holding the tool", 2026-11-18
-- Script: game.StarterPlayer.StarterPlayerScripts.OrchardGui
-- Restore: put the lines below back (search "toolgate 2026-11-18" to find the new code and remove it).

-- [1] applyHelp, the show line was:
	local show = prompt:GetAttribute("CanHelp") == true and owner ~= nil

-- [2] the 0.3 s loop was:
task.spawn(function()
	while true do
		task.wait(0.3)
		local holding, tier = holdingHand()
		for prompt, lot in pairs(stealPrompts) do applySteal(prompt, lot, holding, tier) end
		for prompt, lot in pairs(helpPrompts) do applyHelp(prompt, lot) end
		for prompt, lot in pairs(prompts) do
			if prompt:GetAttribute("State") == "grow" then applyPrompt(prompt, lot) end -- ถือ/เก็บปุ๋ย = เปลี่ยนคำบนปุ่ม
		end
	end
end)
--   (no Uncle Manao prompt handling; no holdingCan / canWaterHelp helpers)
