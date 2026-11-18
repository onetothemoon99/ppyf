-- Section backup of ServerScriptService.Orchard.OrchardService (Studio), 2026-11-18, before "harvestPoseToolFix"
-- (holding a tool while harvesting left the reach pose stuck). Was L1949-1960: HolePrompt.PromptButtonHoldBegan handler.
-- Restore: in Studio replace the current PromptButtonHoldBegan handler of HolePrompt (in the "ปุ่มที่หลุม" loop) with this block.

			-- ต้นแห้ง: เริ่มกดค้าง = หยิบขวานแล้วฟัน · ปล่อย = หยุดฟัน (2026-11-02)
			prompt.PromptButtonHoldBegan:Connect(function(player)
				-- เก็บเกี่ยว: เอื้อมมือหยิบผล (Attribute ให้ OrchardGui ทำท่าแขน + หันเข้าต้น) 2026-11-02
				if prompt:GetAttribute("State") == "ripe" and ownerOf[lot] == player and player.Character then
					reachToken[player] = (reachToken[player] or 0) + 1
					player.Character:SetAttribute("OrchardHarvestAt", hole.Position)
				end
				if prompt:GetAttribute("State") == "dead" and ownerOf[lot] == player then
					local ok, err = pcall(startChop, player, lot, i)
					if not ok then warn("OrchardService: chop error: " .. tostring(err)) end
				end
			end)
