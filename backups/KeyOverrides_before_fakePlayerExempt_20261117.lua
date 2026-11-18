-- Backup 2026-11-17 before fakePlayerExempt (partial: the keyOf functions of 6 scripts)
-- Restore: put each function back in its script (all in ServerScriptService).

-- ===== AchievementService =====
local function keyOf(player)
	if RunService:IsStudio() then
		local override = workspace:GetAttribute("DevAchievementKeyOverride")
		if type(override) == "string" and override ~= "" then return override end
		return "StudioTest_" .. tostring(player.UserId)
	end
	return tostring(player.UserId)
end

-- ===== CropBook =====
local function keyOf(player)
	if RunService:IsStudio() then
		local override = workspace:GetAttribute("DevCropBookKeyOverride")
		if type(override) == "string" and override ~= "" then return override end
	end
	return tostring(player.UserId)
end

-- ===== OrderBoardService =====
local function keyOf(player)
	if RunService:IsStudio() then
		local override = workspace:GetAttribute("DevOrderBoardKeyOverride")
		if type(override) == "string" and override ~= "" then return override end
	end
	return tostring(player.UserId)
end

-- ===== PetSystem.PetOwnership =====
local function keyOf(player)
	-- ทดสอบใน Studio: workspace Attribute "DevPetKeyOverride" = คีย์ปลอมแทน UserId (ไม่แตะข้อมูลจริง) ตั้งใน Edit mode แล้วลบทิ้ง
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DevPetKeyOverride") then return tostring(workspace:GetAttribute("DevPetKeyOverride")) end
	return tostring(player.UserId)
end

-- ===== MountSystem.MountOwnership =====
local function keyOf(player)
	-- ทดสอบใน Studio: workspace Attribute "DevMountKeyOverride" = คีย์ปลอม (ไม่แตะข้อมูลจริง)
	if RunService:IsStudio() and workspace:GetAttribute("DevMountKeyOverride") then
		return tostring(workspace:GetAttribute("DevMountKeyOverride"))
	end
	return tostring(player.UserId)
end

-- ===== ChickenFarm.ChickenData =====
local function keyOf(player)
	if RunService:IsStudio() and workspace:GetAttribute("DevChickenKeyOverride") then
		return "dev_" .. tostring(workspace:GetAttribute("DevChickenKeyOverride"))
	end
	return tostring(player.UserId)
end
