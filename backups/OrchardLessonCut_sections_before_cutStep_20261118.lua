-- Backup (changed sections only) before "mango lesson: fix harvest-step crash + lesson tree dies after harvest + cut-down step", 2026-11-18
-- Restore: put each section below back in Studio (search the new code by "cut 2026-11-18" to find what to remove).

-- [1] game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide (lines ~611-635). The helpers sat ABOVE orchardLots (bug: orchardLots nil at call):
local function orchardMyTreeModels()
	local lots, name = orchardLots(), player:GetAttribute("OrchardLot")
	local lot = lots and type(name) == "string" and lots:FindFirstChild(name)
	return lot, lot and lot:FindFirstChild("Trees")
end
local function orchardRipeTree() -- คืน ตำแหน่งหลุม, path ต้น (ต้นมะม่วงสุกที่ใกล้สุด) · ไม่มี = nil
	local lot, trees = orchardMyTreeModels()
	local root = rootPart()
	if not (lot and trees) then return nil end
	local best, bestD, bestPath
	for _, m in ipairs(trees:GetChildren()) do
		if m:GetAttribute("Stage") == "Ripe" and m:GetAttribute("Kind") == "Mango" and (tonumber(m:GetAttribute("Fruits")) or 0) > 0 then
			local hole = lot:FindFirstChild("Hole" .. tostring(m:GetAttribute("Slot")))
			local pos = hole and hole:IsA("BasePart") and hole.Position or m:GetPivot().Position
			local d = root and (pos - root.Position).Magnitude or 0
			if not bestD or d < bestD then best, bestD, bestPath = pos, d, "Orchard/Lots/" .. lot.Name .. "/Trees/" .. m.Name end
		end
	end
	return best, bestPath
end
local function orchardLots() local o = workspace:FindFirstChild("Orchard") return o and o:FindFirstChild("Lots") end
--   ORCHARD_STEPS had no oCut step (order: oSeed, oPlant, oHarvest, oSell, oHand, oUncle).
--   enterStep orch line had no `wood` field:
		orch = { seeds = orchardMangoSeeds(), hands = orchardHands(), trees = orchardMyTrees(), fruits = orchardMangoFruits(), pingAt = 0 } -- fruits = ขั้นเก็บ/ขาย 2026-11-18

-- [2] game.ServerScriptService.Orchard.OrchardData, Normalize tree table had no `lesson` field:
					fed = tonumber(tr.fed),
				}

-- [3] game.ServerScriptService.Orchard.OrchardService
--   actions.plant lesson-grow block had no `t.lesson = true` line.
--   actions.harvest commit was:
	local ok = commit(player, st, function(d)
		local t = d.trees[tostring(holeNo)]
		got = OrchardData.StartNewCycle(t, OrchardData.Now())
		t.harvests = (t.harvests or 0) + 1
		left = Config.HarvestsLeft(t)
		if left == 0 then t.dead = true end
		d.stats.harvested += got
	end)
--   and the extra-text block started with `if left == 0 and revived then` (no lesson-tree branch).

-- [4] game.ReplicatedStorage.LessonContent orchard lesson text = the 6-step version
--   (see backups/OrchardHarvestSell_sections_before_harvestSellSteps_20261118.lua for the 4-step one).
