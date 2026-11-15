-- Backup 2026-11-16 (partial: only the parts changed by "harvest holdPose"; full script is ~190k chars)
-- Studio path: game.ServerScriptService.Orchard.OrchardService
-- Restore: in OrchardService, replace the new versions of these pieces with the text below:
--   (1) the line `local reachToken = {}` (~line 967) — also delete the new `harvesting` / HARVEST_POSE_MAX lines next to it
--   (2) inside the HolePrompt loop: the PromptButtonHoldEnded reach-clear block
--   (3) inside prompt.Triggered: the `if state == "ripe" and owner == player then` branch
--   (4) the PlayerRemoving cleanup line that ends with `reachToken[player] = nil, nil, nil, nil, nil`

-- (1)
local reachToken = {} -- [player] = ตัวเลขรอบเอื้อมมือหยิบผล (เก็บเกี่ยว 2026-11-02)

-- (2)
				-- เลิกเอื้อมมือหลังปล่อยปุ่ม 0.7 วิ (เห็นท่าดึงผลตอนต้นโยก) · กดใหม่ทัน = ไม่ล้าง
				local rt = reachToken[player]
				if rt then
					task.delay(0.7, function()
						if reachToken[player] ~= rt then return end
						reachToken[player] = nil
						if player.Character then player.Character:SetAttribute("OrchardHarvestAt", nil) end
					end)
				end

-- (3)
				if state == "ripe" and owner == player then
					local res = run(player, "harvest", i)
					if type(res) == "table" and not res.quiet then notify(player, res.message) end -- เก็บได้ = ป้ายมุมขวาบนแทน

-- (4)
	helpHold[player], helpAskAt[player], chopToken[player], chopAuto[player], reachToken[player] = nil, nil, nil, nil, nil
