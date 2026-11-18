-- Section backup, 2026-11-18, before "faceOnClient" (cutting tree 2 right after tree 1 warped the player back to tree 1:
-- the server set HumanoidRootPart.CFrame from its stale copy of the client-owned position).
-- Restore: in Studio put each block back in place of the current code.
--   ServerScriptService.Orchard.OrchardService  startChop (was L1104-1108), startTrunkPour (was L2133-2138), startPour (was L2192-2197),
--     and delete the new local function faceHole (added above startChop)
--   ServerScriptService.Orchard.UncleManao      startPour (was L379-383)
--   StarterPlayer.StarterPlayerScripts.OrchardGui  PreSimulation "ตัวเรา: หันหน้าเข้าต้น" block (was L2490-2505)

-- ===== OrchardService startChop
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then -- หันหน้าเข้าต้น
		local look = Vector3.new(hole.Position.X, root.Position.Y, hole.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end

-- ===== OrchardService startTrunkPour
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local look = Vector3.new(hole.Position.X, root.Position.Y, hole.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end

-- ===== OrchardService startPour
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local look = Vector3.new(hole.Position.X, root.Position.Y, hole.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end

-- ===== UncleManao startPour
	local root = rootOf(player)
	if root then
		local look = Vector3.new(waterSpot.Position.X, root.Position.Y, waterSpot.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end

-- ===== OrchardGui PreSimulation facing block
	-- ตัวเรา: หันหน้าเข้าต้นครั้งเดียวตอนเริ่ม แล้วไม่ให้ตัวหมุนตามทางเดินจนเลิกขโมย
	local ch = player.Character
	local pickAt = ch and (ch:GetAttribute("OrchardPickAt") or ch:GetAttribute("OrchardHarvestAt") or ch:GetAttribute("OrchardPlantAt") or ch:GetAttribute("OrchardFertAt")) -- เก็บเกี่ยว/ปลูก/ใส่ปุ๋ยก็หันเข้าหลุม (2026-11-02, ปุ๋ย 2026-11-16)
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if typeof(pickAt) == "Vector3" and hum and root then
		if not faced or faced.char ~= ch then
			faced = { char = ch, hum = hum, autoRotate = hum.AutoRotate }
			hum.AutoRotate = false
			local flat = Vector3.new(pickAt.X, root.Position.Y, pickAt.Z)
			if (flat - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, flat) end
		end
	elseif faced then
		if faced.hum.Parent then faced.hum.AutoRotate = faced.autoRotate end
		faced = nil
	end
