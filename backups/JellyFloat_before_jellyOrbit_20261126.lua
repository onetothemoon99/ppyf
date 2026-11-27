-- BACKUP of game.ReplicatedStorage.JellyFloat (full Source, 3809 bytes) taken 2026-11-26 before the jellyfish orbit / no petals / pink rod glow change.
-- Restore: in Studio open game.ReplicatedStorage.JellyFloat, select all, paste everything below this header.
-- JellyFloat: แมงกะพรุนซากุระ 3D ลอยตามตัว (เบ็ดแมงกะพรุนซากุระ) ใช้ร่วมกันระหว่าง SunBeeAuraFx (คนถือเบ็ด) กับ FishingOtterFx (นากหน้าตู้) 2026-11-26
--   เทมเพลต ReplicatedStorage.SakuraJellyFx.Jelly: Root ล่องหนที่จุดกำเนิด (= ขอบร่ม จุดหมุนหนวด) + MeshPart ที่มี Attribute Piece = Bell / Arms / Tent
--   ท่า: ลอยนิ่งๆ เหนือไหล่ขวา (ไม่บินวน ผู้ใช้เคยบอกนกฟีนิกซ์วนแล้วมึนหัว) ตามตัวแบบหน่วงๆ ขึ้นลงเบาๆ
--   ร่มพอง-หดเป็นจังหวะ (หดแล้วลอยขึ้นนิด) หนวดแกว่งช้าๆ หันหน้า (ตา) หากล้องค่อยๆ

local JellyFloat = {}

function JellyFloat.Make(template, parent)
	local model = template:Clone()
	model.Parent = parent
	local j = { model = model, root = model.PrimaryPart, parts = {}, phase = math.random() * math.pi * 2 }
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			table.insert(j.parts, { part = p, rel = p.CFrame, size = p.Size, piece = p:GetAttribute("Piece") or "Root" })
		end
	end
	return j
end

local function lerpAngle(a, b, k)
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * k
end

-- anchor = CFrame ของตัวคน/นาก · offset = จุดลอยเทียบ anchor (x ขวา y บน z หลัง) · t = เวลา (บวก phase มาแล้วก็ได้)
function JellyFloat.Step(j, dt, anchor, camPos, t, offset)
	local wander = Vector3.new(0.2 * math.sin(t * 0.37), 0.22 * math.sin(t * 1.1), 0.15 * math.sin(t * 0.53))
	local look = anchor.LookVector * Vector3.new(1, 0, 1) -- ใช้แค่ทิศหันแนวนอน (pivot นากเอียงอยู่ ทำให้แมงกะพรุนต่ำเกิน)
	if look.Magnitude < 1e-3 then look = Vector3.new(0, 0, -1) end
	local upright = CFrame.lookAt(anchor.Position, anchor.Position + look)
	local target = upright:PointToWorldSpace(offset + wander)
	if not j.pos or (j.pos - target).Magnitude > 12 then j.pos = target end
	j.pos = j.pos:Lerp(target, 1 - math.exp(-dt * 3)) -- ตามแบบหน่วงๆ เดินแล้วลอยตามมา
	local want = j.yaw or 0
	if camPos then
		local d = (camPos - j.pos) * Vector3.new(1, 0, 1)
		if d.Magnitude > 0.1 then want = math.atan2(-d.X, -d.Z) end
	end
	j.yaw = lerpAngle(j.yaw or want, want, 1 - math.exp(-dt * 2))
	local p = math.sin(t * 2.4) -- บวก = ร่มหด (แคบลง สูงขึ้น) แล้วลอยขึ้นนิด
	local cf = CFrame.new(j.pos + Vector3.new(0, 0.07 * p, 0)) * CFrame.Angles(0, j.yaw, 0)
		* CFrame.Angles(0.07 * math.sin(t * 0.9), 0, 0.07 * math.sin(t * 0.7))
	local s = Vector3.new(1 - 0.07 * p, 1 + 0.05 * p, 1 - 0.07 * p)
	local lag = math.sin(t * 2.4 - 0.9) -- หนวดตามร่มช้ากว่านิดหน่อย
	for _, e in ipairs(j.parts) do
		if e.piece == "Bell" then
			e.part.Size = e.size * s
			e.part.CFrame = cf * CFrame.new(e.rel.Position * s) * e.rel.Rotation
		elseif e.piece == "Arms" or e.piece == "Tent" then
			local k = (e.piece == "Arms") and 0 or 1.4
			local sway = CFrame.Angles(0.12 * math.sin(t * 1.3 + k) + 0.05 * lag, 0, 0.1 * math.sin(t * 1.05 + k))
			e.part.CFrame = cf * sway * e.rel
		else
			e.part.CFrame = cf * e.rel
		end
	end
end

return JellyFloat
