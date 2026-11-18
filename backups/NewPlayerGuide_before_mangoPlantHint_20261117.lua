-- Backup 2026-11-17 before mangoPlantHint (partial: changed sections)
-- Restore: put these sections back.

-- ===== game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide: nearestEmptyHole (~line 642) =====
local function nearestEmptyHole()
	local lots, root = orchardLots(), rootPart()
	if not (lots and root) then return nil end
	local mine = player:GetAttribute("OrchardLot")
	local best, bestD
	for _, lot in ipairs(lots:GetChildren()) do
		local ok = (type(mine) == "string" and lot.Name == mine) or (mine == nil and lot:GetAttribute("OwnerId") == nil)
		if ok then
			local trees = lot:FindFirstChild("Trees")
			for i = 1, 12 do
				local hole = lot:FindFirstChild("Hole" .. i)
				if hole and hole:IsA("BasePart") and not (trees and trees:FindFirstChild("Tree" .. i)) then
					local d = (hole.Position - root.Position).Magnitude
					if not bestD or d < bestD then best, bestD = hole.Position, d end
				end
			end
		end
	end
	return best
end

-- ===== NewPlayerGuide: checkOrchardStep oPlant (~line 694) =====
		targetPos = nearestEmptyHole() or attrPos("OrchardFruitShopPos")
		markText = tr(s.markTh, s.markEn)
		setCardText(slotText(isMangoSeed, "เมล็ดมะม่วง", "mango seed") .. tr("แล้วไปหลุมว่าง กด E \"ปลูกต้นไม้\"", "then press E \"Plant\" at the empty hole"))

-- ===== NewPlayerGuide: landmark RenderStepped (~line 1079) =====
	if not (m and m:IsA("Model")) or (shopMain and shopMain.Visible) then
		if landmarkSign.Enabled then hideLandmark() end
		return
	end
	local cf, size = m:GetBoundingBox()

-- ===== NewPlayerGuide: findHintTarget orchardHold (~line 1253) =====
		local test = orchHold == "Can" and isCan or isPicker
		local held = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
		if held and test(held) then return nil end
		local label = orchHold == "Can" and tr("👆 กดถือบัวรดน้ำ", "👆 Tap to hold the watering can") or tr("👆 กดถือตะกร้อขโมย", "👆 Tap to hold the fruit picker")
		...
			local tab = inv:FindFirstChild("Tab_tool", true)

-- ===== game.StarterPlayer.StarterPlayerScripts.FullInventoryGui (~line 1281) =====
		if useButton then useButton:SetAttribute("GuideTool", tool:GetAttribute("IsStealHand") and "Picker" or tool:GetAttribute("OrchardToolId")) end -- 2026-11-17 บทสวนมะม่วง: NewPlayerGuide ไฮไลต์ปุ่ม "ใช้" ตะกร้อ / บัวรดน้ำ
