-- Backup 2026-11-17 before streaming (chicken yard buttons slow to appear on weak devices after warping)
-- This change is PROPERTY-ONLY on the scene (ModelStreamingMode) + one small function in a LocalScript.
-- No parts were moved, added or deleted, so restoring = setting these values back.
--
-- 1) Scene: original ModelStreamingMode values (Studio path -> value)
--    workspace.FarmProps.ChickenYard                    = Atomic
--    workspace.FarmProps.ChickenYard.Incubator          = Default
--    workspace.FarmProps.ChickenYard.Trough             = Default
--    workspace.FarmProps.ChickenYard.EggStand           = Default
--    workspace.FarmProps.ChickenYard.ChickenMerchant    = Atomic
--    workspace.FarmProps.ChickenYard.CleanBroom         = Atomic
--    (unchanged: ShowYard = Atomic, ChickenBoard = Persistent, ChickenContestBoard = Persistent)
--    Restore in the Command Bar:
--[[
local y = workspace.FarmProps.ChickenYard
y.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
y.Incubator.ModelStreamingMode = Enum.ModelStreamingMode.Default
y.Trough.ModelStreamingMode = Enum.ModelStreamingMode.Default
y.EggStand.ModelStreamingMode = Enum.ModelStreamingMode.Default
y.ChickenMerchant.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
y.CleanBroom.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
]]
--
-- 2) game.StarterPlayer.StarterPlayerScripts.ChickenYardClient (LocalScript), lines 38-50 original:
-- คืน พื้นที่เดิน, รายการเขตห้ามเดิน (Part ที่มี Attribute NoWalk: เล้า ราง โต๊ะตะกร้า)
local noWalkCache, noWalkFor = nil, nil
local function yardParts()
	local node = yardModel()
	if not node then return nil end
	if noWalkFor ~= node then
		noWalkCache, noWalkFor = {}, node
		for _, p in ipairs(node:GetDescendants()) do
			if p:IsA("BasePart") and p:GetAttribute("NoWalk") then table.insert(noWalkCache, p) end
		end
	end
	return node:FindFirstChild("YardArea"), noWalkCache
end
