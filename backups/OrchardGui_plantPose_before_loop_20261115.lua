-- Backup 2026-11-15 (partial: only the planting pose; full script is ~106k chars)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.OrchardGui
-- Restore: replace the new PLANT_ constants line and the "ก้มลงปลูกเมล็ด" block in the Heartbeat/Stepped loop with the text below.

-- constants (line ~1808)
local PLANT_WAIST, PLANT_SHOULDER, PLANT_HIP, PLANT_KNEE = -38, 45, 30, -45

-- pose block (line ~1881)
	-- ก้มลงปลูกเมล็ด (ทุกคนที่กำลังปลูก)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local on = ch ~= nil and typeof(ch:GetAttribute("OrchardPlantAt")) == "Vector3"
		local st = ch and planting[ch]
		if on and not st then
			st = { w = 0 }
			planting[ch] = st
		end
		if st then
			st.w = math.clamp(st.w + (on and dt or -dt) * 6, 0, 1)
			if st.w <= 0 then
				planting[ch] = nil
			else
				local w = st.w
				local waist = rigJoint(ch, "UpperTorso", "Waist")
				local sh = rigJoint(ch, "RightUpperArm", "RightShoulder")
				local lh, rh = rigJoint(ch, "LeftUpperLeg", "LeftHip"), rigJoint(ch, "RightUpperLeg", "RightHip")
				local lk, rk = rigJoint(ch, "LeftLowerLeg", "LeftKnee"), rigJoint(ch, "RightLowerLeg", "RightKnee")
				if waist then waist.Transform = waist.Transform * CFrame.Angles(math.rad(PLANT_WAIST * w), 0, 0) end
				if sh then sh.Transform = sh.Transform * CFrame.Angles(math.rad(PLANT_SHOULDER * w), 0, 0) end
				for _, j in ipairs({ lh, rh }) do j.Transform = j.Transform * CFrame.Angles(math.rad(PLANT_HIP * w), 0, 0) end
				for _, j in ipairs({ lk, rk }) do j.Transform = j.Transform * CFrame.Angles(math.rad(PLANT_KNEE * w), 0, 0) end
			end
		end
	end
