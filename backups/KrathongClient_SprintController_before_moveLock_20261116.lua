-- Backup 2026-11-16 before moveLock (partial: only the 2 changed sections)
-- Full KrathongClient from just before today's pose change: backups/KrathongClient_before_poseLive_20261116.lua
-- Restore: in each script, replace the changed function with the matching text below.

-- ===== game.StarterPlayer.StarterPlayerScripts.KrathongClient (LocalScript), line ~944 =====
local function lockMove(hum)
	if not hum then return nil end
	local saved = { ws = hum.WalkSpeed, jp = hum.JumpPower, jh = hum.JumpHeight }
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0
	return function()
		if not hum.Parent then return end
		-- ระบบอื่น (วิ่ง Shift / สัตว์ขี่) อาจตั้งค่าใหม่ระหว่างทาง คืนเฉพาะที่ยังเป็น 0 ที่เราตั้งไว้
		if hum.WalkSpeed == 0 then hum.WalkSpeed = saved.ws end
		if hum.JumpPower == 0 then hum.JumpPower = saved.jp end
		if hum.JumpHeight == 0 then hum.JumpHeight = saved.jh end
	end
end

-- ===== game.StarterPlayer.StarterPlayerScripts.SprintController (LocalScript), line 138-146 =====
local fovTween
local function apply()
	local want = toggled or shiftHeld
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then -- ขี่สัตว์ = คูณความเร็ว (MountService ตั้ง MountSpeed / MountRunSpeed ตอนวิ่ง)
		local walkMult = player:GetAttribute("MountSpeed") or 1
		local runMult = player:GetAttribute("MountRunSpeed") or walkMult
		humanoid.WalkSpeed = want and RUN_SPEED * runMult or WALK_SPEED * walkMult
	end
