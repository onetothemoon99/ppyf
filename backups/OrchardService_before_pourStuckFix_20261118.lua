-- Section backup of ServerScriptService.Orchard.OrchardService (Studio), 2026-11-18, before "pourStuckFix"
-- (watering-help pour: tilted can + water + sound could stay on if the hold-ended signal never reached the server).
-- Restore: in Studio replace the current stopPour function and the HelpPrompt PromptButtonHoldBegan handler with these blocks.

-- ===== stopPour (was L2101-2110)
local function stopPour(player)
	local p = pouring[player]
	if not p then return end
	pouring[player] = nil
	if p.tool and p.tool.Parent then p.tool.Grip = Config.Kit.Can.Grip end
	if p.emitter then p.emitter.Enabled = false game:GetService("Debris"):AddItem(p.emitter.Parent, 1.5) end
	if p.splash then p.splash.Enabled = false game:GetService("Debris"):AddItem(p.splash.Parent, 1.5) end
	if p.sound then p.sound:Destroy() end
	if p.auto and p.tool then putAway(player, p.tool) end -- บัวที่หยิบให้เอง = เก็บคืนเหมือนขวาน (2026-11-02)
end

-- ===== HelpPrompt PromptButtonHoldBegan (was L2488-2494)
			prompt.PromptButtonHoldBegan:Connect(function(player)
				helpHold[player] = { prompt = prompt, t = os.clock() }
				if ownerOf[lot] ~= player and prompt:GetAttribute("CanHelp") == true then
					local ok, err = pcall(startPour, player, hole)
					if not ok then warn("OrchardService: pour error: " .. tostring(err)) end
				end
			end)
