-- BACKUP 2026-11-21 of StarterPlayer.StarterPlayerScripts.MountFx (LocalScript) before flamingo wings/one-leg/ripples. Restore: paste everything below this line into that script's Source.
-- MountFx: ท่าทางสัตว์ขี่ของทุกคน (ฝั่งผู้เล่น ไม่กินเน็ต) 2026-10-15
--   MountService เชื่อมตัวสัตว์ด้วย Weld "BodyWeld" ไว้ -> ที่นี่ขยับ C0 ทุกเฟรม: เดิน = เด้ง/โยก, ยืน = หายใจเบาๆ
--   ตามความสามารถ (Attribute "Perk" บนโมเดล): Bouncy กระต่ายกระโดดดึ๋ง, Steady เต่าโยกช้า, Hover ไม้กวาดลอยขึ้นลงตลอด,
--   Rear ม้ายกขาหน้าตอนขึ้นขี่ · ตัวปล่อย "MountFx" เปิดตอนเดิน (Attribute Always = เปิดตลอด)
--   ทำเฉพาะตัวที่อยู่ใกล้กล้อง (RANGE) · ท่าคร่อมหลังของขา ดูด้านล่าง

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")

local RANGE = 160
local MOVING_SPEED = 1.5
local REAR_TIME = 0.9

local states = {} -- [model] = { weld, base, t, born, emitters, perk, back }

-- ============ ขางอได้ (EditableMesh) 2026-10-15 ============
-- ขาแยกชิ้นจาก segment_mesh เป็นเปลือกกลวง หมุนทั้งชิ้นแล้วขอบรอยตัดแยกจากลำตัว เห็นรอยดำที่สะโพก
-- -> ถ้าขามี Attribute BendTop (ความสูงในชิ้นขา) จะดัดเฉพาะส่วนที่ต่ำกว่านั้น ส่วนบน (ขอบรอยตัด) อยู่กับที่ ไม่มีช่อง
-- สร้างไม่ได้ (สิทธิ์/หน่วยความจำ) = กลับไปหมุนทั้งชิ้นแบบเดิม
local BEND_LENGTH = 0.7 -- studs ใต้ BendTop ที่ค่อยๆ เพิ่มการงอจนเต็มมุม

local function makeBendable(leg, part)
	task.spawn(function()
		local scale = part.Size / part.MeshSize
		local ok, em = pcall(function()
			return AssetService:CreateEditableMeshAsync(Content.fromUri(part.MeshId))
		end)
		if not ok or not em then return end
		local ok2, mp = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromObject(em))
		end)
		if not ok2 or not mp or not part.Parent then em:Destroy() return end
		local texture = part.TextureContent -- ApplyMesh ล้างลายผิว ต้องใส่คืน
		local ok3 = pcall(function() part:ApplyMesh(mp) end)
		mp:Destroy()
		part.TextureContent = texture
		if not ok3 then em:Destroy() return end
		local top = part:GetAttribute("BendTop")
		local pivot = Vector3.new(0, top, 0)
		local verts = {}
		for _, v in ipairs(em:GetVertices()) do
			local p = em:GetPosition(v) * scale
			local d = math.clamp((top - p.Y) / BEND_LENGTH, 0, 1)
			local w = d * d * (3 - 2 * d)
			if w > 0 then table.insert(verts, { id = v, rel = p - pivot, w = w }) end
		end
		leg.bend = { em = em, verts = verts, pivot = pivot, scale = scale, shown = 0 }
	end)
end

-- ปิดรูบนลำตัวตรงที่ตัดขาออก (มองจากข้างล่างเห็นทะลุเข้าไปในตัว เห็นเสื้อผู้ขี่) ขอบรูเก็บไว้ใน Attribute CapHoles บน Body
-- รูปแบบ: รูคั่นด้วย "#" แต่ละรู = "x,y,z;x,y,z;...|u,v" (พิกัด mesh เรียงตามทิศขอบ, u,v = สีจากลายผิวตรงขอบ)
local function capBody(body)
	local data = body:GetAttribute("CapHoles")
	if type(data) ~= "string" or not body:IsA("MeshPart") then return end
	task.spawn(function()
		local ok, em = pcall(function()
			return AssetService:CreateEditableMeshAsync(Content.fromUri(body.MeshId), { FixedSize = false })
		end)
		if not ok or not em then return end
		local built = pcall(function()
			for loopStr in string.gmatch(data, "[^#]+") do
				local ptsStr, uvStr = loopStr:match("^(.-)|(.+)$")
				local u, v = uvStr:match("([^,]+),([^,]+)")
				local uvId = em:AddUV(Vector2.new(tonumber(u), tonumber(v)))
				local ids, c = {}, Vector3.zero
				for x, y, z in string.gmatch(ptsStr, "([^,;]+),([^,;]+),([^,;]+)") do
					local p = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
					table.insert(ids, em:AddVertex(p))
					c += p
				end
				local cid = em:AddVertex(c / #ids)
				for i = 1, #ids do
					local f = em:AddTriangle(ids[i % #ids + 1], ids[i], cid)
					em:SetFaceUVs(f, { uvId, uvId, uvId })
				end
			end
		end)
		local ok2, mp = false, nil
		if built then
			ok2, mp = pcall(function() return AssetService:CreateMeshPartAsync(Content.fromObject(em)) end)
		end
		if not ok2 or not mp or not body.Parent then em:Destroy() return end
		local texture = body.TextureContent
		local ok3 = pcall(function() body:ApplyMesh(mp) end)
		mp:Destroy()
		body.TextureContent = texture
		-- ตัว MeshPart อ้าง EditableMesh อยู่ เก็บไว้ทำลายตอนโมเดลหาย
		if ok3 then
			body.AncestryChanged:Connect(function()
				if not body:IsDescendantOf(game) then em:Destroy() end
			end)
		else
			em:Destroy()
		end
	end)
end

-- ============ โมเดลชิ้นเดียว + กระดูกขาในโค้ด (Attribute LegRig บน Body) 2026-10-15 ============
-- ไม่ตัดขาออกจากตัว -> ผิวต่อเนื่องทั้งตัว ไม่มีรอยต่อเลย ดัดจุดของขาแต่ละข้างรอบสะโพก น้ำหนักค่อยๆ จางเข้าหาลำตัว (แบบกระดูกใน Blender)
-- LegRig = ขาคั่นด้วย ";" แต่ละขา = "ชื่อ,หน้า(1/0),ซ้าย(1/0),แกนX,แกนZ,สะโพกY,สะโพกZ,เต็มที่Y,หมดที่Y[,เข่าX,เข่าY,เข่าZ,แก้เข่า°,แก้สะโพก°]"
--   พิกัดในชิ้น Body (studs) · เข่า/แก้ = ดัดขาที่ปั้นมางอ (ขาหน้าขวายูนิคอร์นยกอยู่) ให้ตั้งตรงก่อนแกว่ง
local SKIN_R0, SKIN_R1 = 0.45, 0.72 -- รัศมีจากแกนขา: ใน = ขาเต็มตัว, นอก = ไม่ขยับ
local KNEE_BLEND = 0.3

local function smooth01(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function rotX(p, pivot, a)
	local r = p - pivot
	local c, s = math.cos(a), math.sin(a)
	return pivot + Vector3.new(r.X, r.Y * c - r.Z * s, r.Y * s + r.Z * c)
end

local function parseRig(str)
	local rig = {}
	for legStr in string.gmatch(str, "[^;]+") do
		local f = string.split(legStr, ",")
		local n = function(i) return tonumber(f[i]) end
		local L = {
			name = f[1], front = f[2] == "1", left = f[3] == "1",
			ax = Vector3.new(n(4), 0, n(5)), hip = Vector3.new(n(4), n(6), n(7)), full = n(8), top = n(9),
		}
		if f[10] then
			L.knee = Vector3.new(n(10), n(11), n(12))
			L.kneeFix = math.rad(n(13))
			L.hipFix = math.rad(n(14))
		end
		table.insert(rig, L)
	end
	return rig
end

-- ขาหน้าขวาที่ปั้นมายกอยู่ (ยูนิคอร์น) -> ลบส่วนหน้า-ขวาล่าง (ขา + อกขวา) แล้วใส่สำเนาส่วนหน้า-ซ้ายที่กลับด้านแทน
-- พื้นที่เลือกให้ขอบอยู่ตรงที่ตัวซ้าย-ขวาเหมือนกัน (เลี่ยงผ้าอาน) -> เชื่อมขอบ: ดึงจุดขอบแต่ละฝั่งไปทับเส้นขอบอีกฝั่ง (ไม่ปิดด้วยแผ่นพัด เพราะเห็นเป็นเศษแหลม)
-- สำเนาใช้ normal ที่กลับด้านจากฝั่งซ้าย (ผิวนุ่มเท่ากัน) ตรงตะเข็บใช้ normal ของจุดเดิม ไม่เห็นเส้นแสงเงา
-- Attribute MirrorFront บน Body = "z1,y1,z2,y2,snap" (พิกัดใน Body) พื้นที่ = (z<z1 และ y<y1) หรือ (z<z2 และ y<y2) 2026-10-16
local function mirrorFrontLeft(em, scale, spec)
	local f = string.split(spec, ",")
	local boxes = { { tonumber(f[1]), tonumber(f[2]) }, { tonumber(f[3]), tonumber(f[4]) } }
	local snap = tonumber(f[5])
	-- ไม่ตัดตรงเส้นกลางตัว (ตรงนั้นสำเนากับของเดิมซ้อนกันแล้วเกิดรู) -> เว้นแถบกลางตัวไว้เป็นของเดิม
	local xm = tonumber(f[6]) or 0
	local function inRegion(c)
		for _, b in ipairs(boxes) do
			if c.Z < b[1] and c.Y < b[2] then return true end
		end
		return false
	end
	local function centre(face)
		local vs = em:GetFaceVertices(face)
		return (em:GetPosition(vs[1]) + em:GetPosition(vs[2]) + em:GetPosition(vs[3])) * scale / 3
	end
	local toDelete, toCopy = {}, {}
	for _, face in ipairs(em:GetFaces()) do
		local c = centre(face)
		if inRegion(c) then
			if c.X > xm then table.insert(toDelete, face) elseif c.X < -xm then table.insert(toCopy, face) end
		end
	end
	local newV, isNew, newN, newFaces = {}, {}, {}, {}
	for _, face in ipairs(toCopy) do
		local vs = em:GetFaceVertices(face)
		local uvs = em:GetFaceUVs(face)
		local ns = em:GetFaceNormals(face)
		local ids, nids = {}, {}
		for i, v in ipairs(vs) do
			if not newV[v] then
				local p = em:GetPosition(v)
				local nv = em:AddVertex(Vector3.new(-p.X, p.Y, p.Z))
				newV[v] = nv
				isNew[nv] = true
			end
			ids[i] = newV[v]
			if ns and ns[i] then
				if not newN[ns[i]] then
					local n = em:GetNormal(ns[i])
					newN[ns[i]] = em:AddNormal(Vector3.new(-n.X, n.Y, n.Z))
				end
				nids[i] = newN[ns[i]]
			end
		end
		-- กลับด้าน = กลับลำดับจุด (ไม่งั้นผิวจะหันเข้าใน)
		local nf = em:AddTriangle(ids[1], ids[3], ids[2])
		if uvs then em:SetFaceUVs(nf, { uvs[1], uvs[3], uvs[2] }) end
		if #nids == 3 then em:SetFaceNormals(nf, { nids[1], nids[3], nids[2] }) end
		table.insert(newFaces, nf)
	end
	for _, face in ipairs(toDelete) do em:RemoveFace(face) end
	-- ขอบเปิด (เทียบตำแหน่ง ไม่ใช่เลขจุด เพราะตะเข็บ UV แยกจุดซ้ำที่เดิม)
	local function openEdges()
		local count, ends = {}, {}
		for _, face in ipairs(em:GetFaces()) do
			local vs = em:GetFaceVertices(face)
			for i = 1, 3 do
				local a, b = vs[i], vs[i % 3 + 1]
				local pa, pb = em:GetPosition(a), em:GetPosition(b)
				local ka = string.format("%.4f,%.4f,%.4f", pa.X, pa.Y, pa.Z)
				local kb = string.format("%.4f,%.4f,%.4f", pb.X, pb.Y, pb.Z)
				local k = ka < kb and ka .. "|" .. kb or kb .. "|" .. ka
				count[k] = (count[k] or 0) + 1
				ends[k] = { a, b, face, i }
			end
		end
		local list = {}
		for k, n in pairs(count) do if n == 1 then table.insert(list, ends[k]) end end
		return list
	end
	local oldE, newE, oldVs, newVs = {}, {}, {}, {}
	for _, e in ipairs(openEdges()) do
		if isNew[e[1]] and isNew[e[2]] then
			table.insert(newE, e) newVs[e[1]] = true newVs[e[2]] = true
		elseif not isNew[e[1]] and not isNew[e[2]] then
			table.insert(oldE, e) oldVs[e[1]] = true oldVs[e[2]] = true
		end
	end
	local function nearestOn(p, segs)
		local best, bp, bv = math.huge, nil, nil
		for _, s in ipairs(segs) do
			local a, b = em:GetPosition(s[1]), em:GetPosition(s[2])
			local d = b - a
			local t = d:Dot(d) > 0 and math.clamp((p - a):Dot(d) / d:Dot(d), 0, 1) or 0
			local q = a + d * t
			local dist = (q - p).Magnitude
			if dist < best then best = dist bp = q bv = t < 0.5 and s[1] or s[2] end
		end
		return bp, best, bv
	end
	-- normal ของจุดเดิม (ไว้ให้ตะเข็บฝั่งสำเนาใช้ค่าเดียวกัน)
	local vNormal = {}
	for _, face in ipairs(em:GetFaces()) do
		local vs = em:GetFaceVertices(face)
		local ns = em:GetFaceNormals(face)
		if ns then
			for i, v in ipairs(vs) do
				if not isNew[v] and ns[i] then vNormal[v] = ns[i] end
			end
		end
	end
	-- จำทิศผิวของสามเหลี่ยมที่ติดตะเข็บไว้ ดึงจุดแล้วอันไหนพลิกกลับด้าน (มองจากข้างนอกจะหาย เห็นเป็นรู) จะลบทิ้งแล้วปิดรูใหม่
	local function faceDir(face)
		local vs = em:GetFaceVertices(face)
		local a, b, c = em:GetPosition(vs[1]), em:GetPosition(vs[2]), em:GetPosition(vs[3])
		return (b - a):Cross(c - a)
	end
	local seamFaces = {}
	for _, face in ipairs(em:GetFaces()) do
		for _, v in ipairs(em:GetFaceVertices(face)) do
			if newVs[v] or oldVs[v] then
				seamFaces[face] = faceDir(face)
				break
			end
		end
	end
	local snapTo = {}
	for _ = 1, 2 do
		for v in pairs(newVs) do
			local q, d, ov = nearestOn(em:GetPosition(v), oldE)
			if q and d * scale.X < snap then em:SetPosition(v, q) snapTo[v] = ov end
		end
		for v in pairs(oldVs) do
			local q, d = nearestOn(em:GetPosition(v), newE)
			if q and d * scale.X < snap then em:SetPosition(v, q) end
		end
	end
	local removed = {}
	for face, before in pairs(seamFaces) do
		local after = faceDir(face)
		if after.Magnitude < 1e-9 or before.Magnitude < 1e-9 or after.Unit:Dot(before.Unit) < 0.2 then
			em:RemoveFace(face)
			removed[face] = true
		end
	end
	for _, nf in ipairs(newFaces) do
		if removed[nf] then continue end
		local vs = em:GetFaceVertices(nf)
		local ns = em:GetFaceNormals(nf)
		if ns then
			local changed = false
			for i, v in ipairs(vs) do
				local ov = snapTo[v]
				if ov and vNormal[ov] then ns[i] = vNormal[ov] changed = true end
			end
			if changed then em:SetFaceNormals(nf, ns) end
		end
	end
	-- รอยแตกเส้นผมที่ยังเหลือ: พับขอบเปิดทุกเส้นลงไปในตัวเป็นแถบสีเดียวกับขอบ (มองเข้ารอยแตกเห็นสีตัว ไม่เห็นสีดำ/ทะลุ)
	-- รูเล็กที่เหลือ: ตัดคู่ขอบที่ทับกันอยู่แล้ว (เชื่อมแล้วแต่เลขจุดต่างกัน) ออก ที่เหลือไล่ต่อกันเป็นวง
	-- วงที่ปิดครบ (ไม่เกิน 12 เส้น) = รู -> ปิดด้วยพัดจากจุดกลางของรูนั้นเอง สี/normal จากขอบ
	do
		local TOL = 0.04 / scale.X
		local edges = openEdges()
		local P = {}
		for idx, e in ipairs(edges) do P[idx] = { em:GetPosition(e[1]), em:GetPosition(e[2]) } end
		local dead = {}
		for x = 1, #edges do
			if not dead[x] then
				for y = x + 1, #edges do
					if not dead[y] and (P[x][1] - P[y][2]).Magnitude < TOL and (P[x][2] - P[y][1]).Magnitude < TOL then
						dead[x] = true
						dead[y] = true
						break
					end
				end
			end
		end
		-- ขอบที่ต่อกันได้ (ปลายเส้นหนึ่ง = ต้นอีกเส้น) จุดหนึ่งอาจแตกได้หลายทาง -> หาวงที่สั้นที่สุดที่กลับมาจุดเริ่ม (ค้นแบบกว้าง ไม่เกิน 8 เส้น)
		local nextOf = {}
		for x = 1, #edges do
			if not dead[x] then
				nextOf[x] = {}
				for y = 1, #edges do
					if y ~= x and not dead[y] and (P[y][1] - P[x][2]).Magnitude < TOL then table.insert(nextOf[x], y) end
				end
			end
		end
		local used = {}
		for start = 1, #edges do
			if not dead[start] and not used[start] then
				local prev = { [start] = 0 }
				local frontier, found = { start }, nil
				for _ = 1, 8 do
					local nextFrontier = {}
					for _, x in ipairs(frontier) do
						if x ~= start and (P[x][2] - P[start][1]).Magnitude < TOL then found = x break end
						for _, y in ipairs(nextOf[x]) do
							if prev[y] == nil and not used[y] then prev[y] = x table.insert(nextFrontier, y) end
						end
					end
					if found or #nextFrontier == 0 then break end
					frontier = nextFrontier
				end
				if not found then continue end
				local list = {}
				local x = found
				while x ~= 0 do table.insert(list, 1, x) x = prev[x] end
				if #list < 3 then continue end
				for _, idx in ipairs(list) do used[idx] = true end
				local c = Vector3.zero
				for _, idx in ipairs(list) do c += P[idx][1] end
				local cid = em:AddVertex(c / #list)
				for _, idx in ipairs(list) do
					local a, b, face, i = edges[idx][1], edges[idx][2], edges[idx][3], edges[idx][4]
					local j = i % 3 + 1
					local nf = em:AddTriangle(b, a, cid)
					local uvs = em:GetFaceUVs(face)
					local ns = em:GetFaceNormals(face)
					if uvs then em:SetFaceUVs(nf, { uvs[j], uvs[i], uvs[i] }) end
					if ns and ns[i] and ns[j] then em:SetFaceNormals(nf, { ns[j], ns[i], ns[i] }) end
				end
			end
		end
	end
	-- รอยแยกเล็กที่เหลือ: ทุกขอบเปิดยื่นแผ่น "ปีก" ออกไปตามผิว 0.07 studs (ต่ำกว่าผิวนิดเดียว ไม่ซ้อนแสง)
	-- ปิดรอยแยกที่อยู่ในแนวผิว (แถบพับเข้าในตัวแบบเดิมมองจากข้างนอกเห็นแค่สัน ปิดไม่ได้)
	local FLAP = 0.07 / scale.X
	local SINK = 0.015 / scale.X
	for _, e in ipairs(openEdges()) do
		local a, b, face, i = e[1], e[2], e[3], e[4]
		local fv = em:GetFaceVertices(face)
		local pa, pb = em:GetPosition(a), em:GetPosition(b)
		local pc = em:GetPosition(fv[(i + 1) % 3 + 1])
		local n = (pb - pa):Cross(pc - pa)
		if n.Magnitude > 1e-9 and (pb - pa).Magnitude > 1e-6 then
			n = n.Unit
			local t = (pb - pa):Cross(n).Unit
			if t:Dot((pa + pb) / 2 - pc) < 0 then t = -t end
			local a2 = em:AddVertex(pa + t * FLAP - n * SINK)
			local b2 = em:AddVertex(pb + t * FLAP - n * SINK)
			local f1 = em:AddTriangle(b, a, a2)
			local f2 = em:AddTriangle(b, a2, b2)
			local uvs = em:GetFaceUVs(face)
			local ns = em:GetFaceNormals(face)
			local j = i % 3 + 1
			if uvs then
				em:SetFaceUVs(f1, { uvs[j], uvs[i], uvs[i] })
				em:SetFaceUVs(f2, { uvs[j], uvs[i], uvs[j] })
			end
			if ns and ns[i] and ns[j] then
				em:SetFaceNormals(f1, { ns[j], ns[i], ns[i] })
				em:SetFaceNormals(f2, { ns[j], ns[i], ns[j] })
			end
		end
	end
end

local function makeSkinned(st, body)
	local rig = parseRig(body:GetAttribute("LegRig"))
	st.legs = {}
	for _, L in ipairs(rig) do
		table.insert(st.legs, { front = L.front, left = L.left, angle = 0, rig = L })
	end
	task.spawn(function()
		local scale = body.Size / body.MeshSize
		local mirror = body:GetAttribute("MirrorFront")
		local ok, em = pcall(function()
			return AssetService:CreateEditableMeshAsync(Content.fromUri(body.MeshId), { FixedSize = type(mirror) ~= "string" })
		end)
		if not ok or not em then return end
		if type(mirror) == "string" then
			local okM, err = pcall(mirrorFrontLeft, em, scale, mirror)
			if not okM then warn("[MountFx] mirrorFrontLeft: " .. tostring(err)) em:Destroy() return end
		end
		local ok2, mp = pcall(function() return AssetService:CreateMeshPartAsync(Content.fromObject(em)) end)
		if not ok2 or not mp or not body.Parent then em:Destroy() return end
		local texture = body.TextureContent
		local ok3 = pcall(function() body:ApplyMesh(mp) end)
		mp:Destroy()
		body.TextureContent = texture
		if not ok3 then em:Destroy() return end
		-- น้ำหนักต่อจุด (คำนวณครั้งเดียว)
		local verts = {}
		for _, v in ipairs(em:GetVertices()) do
			local p = em:GetPosition(v) * scale
			for i, leg in ipairs(st.legs) do
				local L = leg.rig
				local r = Vector3.new(p.X - L.ax.X, 0, p.Z - L.ax.Z).Magnitude
				if L.knee then r = math.min(r, Vector3.new(p.X - L.knee.X, 0, p.Z - L.knee.Z).Magnitude) end
				local w = (1 - smooth01((r - SKIN_R0) / (SKIN_R1 - SKIN_R0))) * (1 - smooth01((p.Y - L.full) / (L.top - L.full)))
				if w > 0.001 then
					local wk = L.knee and (1 - smooth01((p.Y - (L.knee.Y - KNEE_BLEND / 3)) / KNEE_BLEND)) or 0
					table.insert(verts, { id = v, rest = p, leg = i, w = w, wk = wk })
					break
				end
			end
		end
		st.skin = { em = em, verts = verts, scale = scale, shown = {} }
		body.AncestryChanged:Connect(function()
			if not body:IsDescendantOf(game) then em:Destroy() end
		end)
	end)
end

local function applySkin(skin, legs)
	local changed = skin.shown.first == nil
	for i, leg in ipairs(legs) do
		if math.abs(leg.angle - (skin.shown[i] or 0)) > 0.002 then changed = true end
	end
	if not changed then return end
	skin.shown.first = true
	for i, leg in ipairs(legs) do skin.shown[i] = leg.angle end
	local em, scale = skin.em, skin.scale
	for _, v in ipairs(skin.verts) do
		local leg = legs[v.leg]
		local L = leg.rig
		local p = v.rest
		if L.knee and v.wk > 0 then p = rotX(p, L.knee, L.kneeFix * v.wk) end
		p = rotX(p, L.hip, ((L.hipFix or 0) + leg.angle) * v.w)
		em:SetPosition(v.id, p / scale)
	end
end

local function applyBend(b, angle)
	if math.abs(angle - b.shown) < 0.002 then return end
	b.shown = angle
	local em, pivot, scale = b.em, b.pivot, b.scale
	for _, v in ipairs(b.verts) do
		local a = angle * v.w
		local c, s = math.cos(a), math.sin(a)
		local r = v.rel
		-- หมุนรอบแกน X ของชิ้นขา (เหมือน CFrame.Angles(a, 0, 0))
		local p = pivot + Vector3.new(r.X, r.Y * c - r.Z * s, r.Y * s + r.Z * c)
		em:SetPosition(v.id, p / scale)
	end
end

local function setup(model)
	local body = model:FindFirstChild("Body")
	local weld = body and body:FindFirstChild("BodyWeld")
	if not weld then return nil end
	local emitters = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") and d.Name == "MountFx" then table.insert(emitters, d) end
	end
	local _, size = model:GetBoundingBox()
	local st = {
		weld = weld, base = weld.C0, t = math.random() * 10, born = os.clock(),
		emitters = emitters, perk = model:GetAttribute("Perk"), back = size.Z * 0.35, moving = nil,
	}
	-- ขาแยกชิ้น (ยูนิคอร์น: Attribute Jointed บนโมเดล) แกว่งที่สะโพกตามจังหวะเดิน/วิ่ง
	for _, part in ipairs(model:GetChildren()) do
		local w = part:IsA("BasePart") and part:FindFirstChild("PartWeld")
		local hinge = part:IsA("BasePart") and part:GetAttribute("Hinge")
		if w and typeof(hinge) == "Vector3" then
			st.legs = st.legs or {}
			local leg = {
				weld = w, rel = weld.C0:Inverse() * w.C0, hinge = hinge, angle = 0,
				front = part:GetAttribute("Front") == true, left = part:GetAttribute("Left") == true,
			}
			table.insert(st.legs, leg)
			if part:IsA("MeshPart") and typeof(part:GetAttribute("BendTop")) == "number" then
				makeBendable(leg, part)
			end
		end
	end
	if body:IsA("MeshPart") and type(body:GetAttribute("LegRig")) == "string" then
		makeSkinned(st, body)
	end
	-- หางส่าย (ช้างน้อยใจบุญ 2026-11-03): โมเดล Tail มี Attribute TailPivot (โคนหาง เทียบ MountRoot) ชิ้นหางเชื่อมกับ Body (FollowBody)
	local tailModel = model:FindFirstChild("Tail")
	local tailPivot = tailModel and tailModel:GetAttribute("TailPivot")
	if typeof(tailPivot) == "Vector3" then
		-- สัตว์ถูกขยายตามตัวคนขี่ (MountService.scaleMount) แต่ Attribute นี้ไม่ถูกคูณ → คูณที่นี่ ไม่งั้นตัวโตหางแกว่งรอบจุดผิด (2026-11-03)
		tailPivot *= tonumber(model:GetAttribute("RiderScale")) or 1
		for _, d in ipairs(tailModel:GetDescendants()) do
			local w = d:IsA("BasePart") and d:FindFirstChild("PartWeld")
			if w and w.Part0 == body then
				st.tail = st.tail or { pivot = weld.C0:Inverse() * tailPivot, parts = {}, t = math.random() * 6, speed = 0 }
				table.insert(st.tail.parts, { weld = w, base = w.C0 })
			end
		end
	end
	st.gait = 0
	if st.legs and not st.legs[1].rig then capBody(body) end
	states[model] = st
	model.AncestryChanged:Connect(function()
		if not model.Parent then
			states[model] = nil
			for _, leg in ipairs(st.legs or {}) do
				if leg.bend then leg.bend.em:Destroy() leg.bend = nil end
			end
		end
	end)
	return st
end

local function offsetFor(st, dt, speed)
	local moving = speed > MOVING_SPEED
	local perk = st.perk
	st.t += dt * (moving and math.clamp(speed / 10, 0.8, 2.2) or 0.35)
	local t = st.t
	local y, pitch, roll = 0, 0, 0
	if perk == "Hover" then
		y = math.sin(t * 3) * 0.18 + (moving and 0 or math.sin(t * 6) * 0.05)
		roll = math.sin(t * 2.2) * math.rad(moving and 4 or 2)
		pitch = moving and math.rad(-4) or 0
	elseif perk == "Bouncy" then
		if moving then
			y = math.abs(math.sin(t * 5)) * 0.55
			pitch = math.cos(t * 10) * math.rad(5)
		else
			y = math.sin(t * 4) * 0.04
		end
	elseif perk == "Gallop" then
		-- ม้าก้านกล้วย: ก้านเด้งขึ้นลงตามจังหวะควบ หัวเงยๆ ก้มๆ (2026-10-31)
		if moving then
			y = math.abs(math.sin(t * 6)) * 0.22
			pitch = math.sin(t * 12) * math.rad(5)
		else
			y = math.sin(t * 3) * 0.03
		end
	elseif perk == "Steady" then
		if moving then
			y = math.abs(math.sin(t * 3)) * 0.06
			roll = math.sin(t * 3) * math.rad(3)
		else
			y = math.sin(t * 3) * 0.02
		end
	else
		if moving then
			y = math.abs(math.sin(t * 6)) * 0.16
			pitch = math.sin(t * 12) * math.rad(3)
		else
			y = math.sin(t * 4) * 0.03
		end
	end
	local cf = CFrame.new(0, y, 0) * CFrame.Angles(pitch, 0, roll)
	-- ม้ายกขาหน้าตอนเพิ่งขึ้นขี่ (หมุนรอบขาหลัง)
	if perk == "Rear" then
		local age = os.clock() - st.born
		if age < REAR_TIME then
			local a = math.sin(age / REAR_TIME * math.pi) * math.rad(28)
			cf = CFrame.new(0, 0, st.back) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, -st.back) * cf
		end
	end
	return cf, moving
end

-- ============ ขาแกว่ง (โมเดลที่มีขาแยกชิ้น) ============
-- ก้าวสลับทแยง (หน้าซ้าย+หลังขวา / หน้าขวา+หลังซ้าย) ทั้งเดินและวิ่ง ยิ่งเร็วยิ่งก้าวถี่และกว้างขึ้นนิดหน่อย
-- ความเร็วถูกทำให้นุ่ม (ไม่กระตุกตามค่าความเร็วที่แกว่งทุกเฟรม) · หยุด = ค่อยๆ ยืนตรง
-- ลำตัวเด้งขึ้นลงตามจังหวะก้าว (2 ครั้งต่อรอบ) ขาตามลำตัวเสมอ
local STRIDE = 5 -- studs ต่อ 1 รอบก้าว (ยิ่งมาก ก้าวยิ่งช้า)
local MAX_SWING = math.rad(18) -- มากกว่านี้เห็นรอยต่อขากับลำตัว (ขาหน้าเสียบเข้าลำตัว 0.4 studs ในแม่แบบ)
-- ขาหลังมีชิ้นสะโพก (วงทอง) ติดมาด้วย แกว่งกว้างแล้วเห็นขอบขาด -> แกว่งแค่ ~10° (2026-10-15)
local BACK_SWING_SCALE = 0.55
local function animateLegs(st, dt, speed, bodyBase)
	st.smoothSpeed = (st.smoothSpeed or 0) + (speed - (st.smoothSpeed or 0)) * math.min(1, dt * 6)
	local s = st.smoothSpeed
	local moving = s > MOVING_SPEED
	-- ก้าวต่อวินาทีไม่เกิน 2.6 รอบ (วิ่งเร็วมากไม่เป็นขาปั่น)
	st.gait = (st.gait + dt * math.min(s / STRIDE, 2.6) * 2 * math.pi) % (2 * math.pi)
	local strength = math.clamp(s / 14, 0, 1)
	local amp = MAX_SWING * (0.55 + 0.45 * math.clamp(s / 30, 0, 1)) * strength
	-- ลำตัว: เด้งเบาๆ 2 ครั้งต่อรอบ + ก้มเงยนิดเดียว
	local bob = math.abs(math.sin(st.gait)) * 0.12 * strength
	local nod = math.sin(st.gait * 2) * math.rad(2) * strength
	local bodyC0 = bodyBase * CFrame.new(0, bob, 0) * CFrame.Angles(nod, 0, 0)
	st.weld.C0 = bodyC0
	for _, leg in ipairs(st.legs) do
		local diagonalA = leg.front == leg.left
		local legAmp = (leg.front or leg.bend or leg.rig) and amp or amp * BACK_SWING_SCALE
		local target = moving and math.sin(st.gait + (diagonalA and 0 or math.pi)) * legAmp or 0
		leg.angle += (target - leg.angle) * math.min(1, dt * 12)
		if leg.rig then
			-- โมเดลชิ้นเดียว: ดัดจุดทีเดียวหลังคำนวณมุมครบทุกขา
			continue
		elseif leg.bend then
			leg.weld.C0 = bodyC0 * leg.rel
			applyBend(leg.bend, leg.angle)
		else
			local h = leg.hinge
			leg.weld.C0 = bodyC0 * leg.rel * CFrame.new(h) * CFrame.Angles(leg.angle, 0, 0) * CFrame.new(-h)
		end
	end
	if st.skin then applySkin(st.skin, st.legs) end
end

-- หางส่ายซ้ายขวารอบโคนหาง: ยืน = ส่ายช้าเบาๆ · วิ่ง = ส่ายถี่และกว้างขึ้น + ปลายหางเหวี่ยงตามหลังจังหวะนิดหน่อย
local function animateTail(tl, dt, speed)
	tl.speed += (speed - tl.speed) * math.min(1, dt * 5)
	local strength = math.clamp(tl.speed / 16, 0, 1)
	tl.t += dt * (2.2 + 6 * strength)
	-- หางห้อยลง = แกว่งซ้ายขวารอบแกนหน้า-หลัง (roll) เป็นหลัก บิด (yaw) นิดหน่อยให้ดูพลิ้ว
	local roll = math.sin(tl.t) * math.rad(10 + 24 * strength)
	local yaw = math.sin(tl.t - 0.6) * math.rad(3 + 5 * strength)
	local p = tl.pivot
	local rot = CFrame.new(p) * CFrame.Angles(0, yaw, roll) * CFrame.new(-p)
	for _, part in ipairs(tl.parts) do
		if part.weld.Parent then part.weld.C0 = rot * part.base end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local camPos = workspace.CurrentCamera.CFrame.Position
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local mountId = player:GetAttribute("RidingMount")
		local model = mountId and character and character:FindFirstChild("Mount_" .. mountId)
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if model and hrp and (hrp.Position - camPos).Magnitude < RANGE then
			local st = states[model] or setup(model)
			if st and st.weld.Parent then
				local v = hrp.AssemblyLinearVelocity
				local speed = Vector3.new(v.X, 0, v.Z).Magnitude
				local offset, moving = offsetFor(st, dt, speed)
				if st.legs then
					animateLegs(st, dt, speed, st.base)
				else
					st.weld.C0 = st.base * offset
				end
				if st.tail then animateTail(st.tail, dt, speed) end
				if moving ~= st.moving then
					st.moving = moving
					for _, e in ipairs(st.emitters) do
						e.Enabled = moving or e:GetAttribute("Always") == true
					end
				end
			end
		end
	end
end)

-- ============ ท่าคร่อมหลัง (ขาแยกลงข้างลำตัวสัตว์) ทุกคนที่กำลังขี่ ============
-- ท่านั่ง (Animate.sit) ยังคุมลำตัว/แขน ส่วนขาตั้ง Transform ทับทุกเฟรม (แบบเดียวกับท่าแขนของ CarryClient)
-- ข้อต่อตัวละครแบบใหม่เป็น AnimationConstraint (มี Transform เหมือน Motor6D)
-- องศา: สะโพก { ก้ม/เงย, หมุน, กางออก } เข่า { งอ } ข้อเท้า { งอ } · กางมากขึ้นตามความกว้างตัวสัตว์
-- ทดสอบใน Studio: ReplicatedStorage Attribute "DevMountLegPose" = "hipPitch,hipSplay,knee,ankle" ปรับสดได้
local LEG_JOINTS = {
	leftHip = { "LeftUpperLeg", "LeftHip" }, rightHip = { "RightUpperLeg", "RightHip" },
	leftKnee = { "LeftLowerLeg", "LeftKnee" }, rightKnee = { "RightLowerLeg", "RightKnee" },
	leftAnkle = { "LeftFoot", "LeftAnkle" }, rightAnkle = { "RightFoot", "RightAnkle" },
}
local POSE = { hipPitch = 25, hipSplay = 30, knee = -45, ankle = 15 }
local SPLAY_MIN, SPLAY_MAX = 20, 45

local jointCache = setmetatable({}, { __mode = "k" })
local function jointsOf(character)
	local j = jointCache[character]
	if j then return j end
	j = {}
	for key, path in pairs(LEG_JOINTS) do
		local part = character:FindFirstChild(path[1])
		local joint = part and part:FindFirstChild(path[2])
		if joint and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then j[key] = joint end
	end
	jointCache[character] = j
	return j
end

local function devPose()
	if not RunService:IsStudio() then return nil end
	local s = game:GetService("ReplicatedStorage"):GetAttribute("DevMountLegPose")
	if type(s) ~= "string" then return nil end
	local a, b2, c, d = s:match("([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)")
	if not a then return nil end
	return { hipPitch = tonumber(a), hipSplay = tonumber(b2), knee = tonumber(c), ankle = tonumber(d) }
end

local splayCache = setmetatable({}, { __mode = "k" }) -- [model] = องศากาง
local function splayFor(model)
	local s = splayCache[model]
	if s then return s end
	local body = model:FindFirstChild("Body")
	local width = body and math.min(body.Size.X, body.Size.Z) or 2.5
	s = math.clamp(math.deg(math.atan((width / 2) / 1.4)), SPLAY_MIN, SPLAY_MAX)
	splayCache[model] = s
	return s
end

RunService.PreSimulation:Connect(function()
	local pose = devPose() or POSE
	for _, player in ipairs(Players:GetPlayers()) do
		local mountId = player:GetAttribute("RidingMount")
		local character = mountId and player.Character
		local model = character and character:FindFirstChild("Mount_" .. mountId)
		if model and not model:GetAttribute("StandRide") then -- StandRide = ยืนวิ่งเอง ไม่ต้องตั้งท่าคร่อม
			local j = jointsOf(character)
			local splay = devPose() and pose.hipSplay or splayFor(model)
			local p = math.rad(pose.hipPitch)
			local s = math.rad(splay)
			if j.leftHip then j.leftHip.Transform = CFrame.Angles(p, 0, -s) end
			if j.rightHip then j.rightHip.Transform = CFrame.Angles(p, 0, s) end
			local k = CFrame.Angles(math.rad(pose.knee), 0, 0)
			if j.leftKnee then j.leftKnee.Transform = k end
			if j.rightKnee then j.rightKnee.Transform = k end
			local a = CFrame.Angles(math.rad(pose.ankle), 0, 0)
			if j.leftAnkle then j.leftAnkle.Transform = a end
			if j.rightAnkle then j.rightAnkle.Transform = a end
		end
	end
end)

-- ============ ลามะไม่ลานะ (Perk MagicTrail): ต้นอ่อนผุดตามทางเดิน ============
-- สร้างบนเครื่องผู้เล่นแต่ละคนเอง (ไม่ส่งผ่านเน็ต) ต้นอ่อนงอกขึ้นจากพื้นด้านหลังแล้วค่อยๆ หายไป
local TweenService = game:GetService("TweenService")
local SPROUT_EVERY = 0.28 -- วินาทีต่อหนึ่งต้นตอนเดิน
local SPROUT_LIFE = 1.8
local SPROUT_RANGE = 120
local sproutFolder = Instance.new("Folder")
sproutFolder.Name = "MountSprouts"
sproutFolder.Parent = workspace
local sproutState = setmetatable({}, { __mode = "k" }) -- [character] = { last }

local function sproutPart(parent, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Ball
	p.Color = color
	p.Size = size
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function spawnSprout(pos)
	local model = Instance.new("Model")
	model.Name = "Sprout"
	local yaw = CFrame.Angles(0, math.random() * math.pi * 2, 0)
	local base = CFrame.new(pos) * yaw
	local green = Color3.fromRGB(110 + math.random(0, 40), 200, 90)
	local parts = {
		sproutPart(model, Vector3.new(0.12, 0.5, 0.12), base * CFrame.new(0, 0.25, 0), Color3.fromRGB(90, 170, 70), Enum.PartType.Cylinder),
		sproutPart(model, Vector3.new(0.55, 0.12, 0.3), base * CFrame.new(0.22, 0.5, 0) * CFrame.Angles(0, 0, math.rad(25)), green),
		sproutPart(model, Vector3.new(0.55, 0.12, 0.3), base * CFrame.new(-0.22, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-25)), green),
	}
	parts[1].CFrame = base * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
	-- บางต้นเป็นแครอทจิ๋ว / หัวผักกาดม่วง เหมือนในรูป
	local roll = math.random()
	if roll < 0.25 then
		table.insert(parts, sproutPart(model, Vector3.new(0.32, 0.32, 0.32), base * CFrame.new(0, 0.05, 0), Color3.fromRGB(255, 140, 50)))
	elseif roll < 0.45 then
		table.insert(parts, sproutPart(model, Vector3.new(0.34, 0.34, 0.34), base * CFrame.new(0, 0.05, 0), Color3.fromRGB(190, 60, 120)))
	end
	model.Parent = sproutFolder
	local finals = {}
	for _, p in ipairs(parts) do
		finals[p] = { size = p.Size, cf = p.CFrame }
		p.Size = p.Size * 0.05
		p.CFrame = CFrame.new(pos) * (p.CFrame - p.CFrame.Position)
	end
	for p, f in pairs(finals) do
		TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = f.size, CFrame = f.cf }):Play()
	end
	task.delay(SPROUT_LIFE, function()
		for p in pairs(finals) do
			TweenService:Create(p, TweenInfo.new(0.5), { Transparency = 1, Size = p.Size * 0.3 }):Play()
		end
		task.delay(0.6, function() model:Destroy() end)
	end)
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
RunService.Heartbeat:Connect(function()
	local camPos = workspace.CurrentCamera.CFrame.Position
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local mountId = player:GetAttribute("RidingMount")
		local character = mountId and player.Character
		local model = character and character:FindFirstChild("Mount_" .. mountId)
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if model and hrp and model:GetAttribute("Perk") == "MagicTrail" and (hrp.Position - camPos).Magnitude < SPROUT_RANGE then
			local v = hrp.AssemblyLinearVelocity
			local st = sproutState[character]
			if not st then st = { last = 0 }; sproutState[character] = st end
			if Vector3.new(v.X, 0, v.Z).Magnitude > MOVING_SPEED and now - st.last > SPROUT_EVERY then
				st.last = now
				groundParams.FilterDescendantsInstances = { sproutFolder, character }
				local back = hrp.CFrame * CFrame.new((math.random() - 0.5) * 1.6, 0, 1.6 + math.random() * 0.8)
				local hit = workspace:Raycast(back.Position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), groundParams)
				if hit and hit.Material ~= Enum.Material.Water then spawnSprout(hit.Position) end
			end
		end
	end
end)

-- ============ ม้าก้านกล้วย (Perk Gallop) 2026-10-31: รอยใบตองบนพื้น + ลงพื้นแล้วใบตองฟุ้ง ============
-- สร้างบนเครื่องผู้เล่นแต่ละคนเอง (แบบต้นอ่อนลามะ) · ลอยอยู่ = ห่างพื้นเกินสะโพก + LEAF_AIR_GAP (ใช้ได้กับตัวละครคนอื่นด้วย ไม่พึ่ง FloorMaterial)
local LEAF_EVERY = 0.22
local LEAF_LIFE = 2.2
local LEAF_AIR_GAP = 1.6
local LAND_MIN_AIR = 0.6 -- ลอยนานกว่านี้แล้วลงพื้น = เอฟเฟกต์ลงพื้น
local LAND_SOUND = "rbxassetid://9120899089" -- Wood Impact (ProSoundEffects) เล่นแค่ช่วงแรก
local leafState = setmetatable({}, { __mode = "k" }) -- [character] = { last, airSince }
local LEAF_GREENS = { Color3.fromRGB(110, 185, 70), Color3.fromRGB(140, 205, 85), Color3.fromRGB(90, 160, 60) }

-- ขนาดใบ 0.95 × 0.4 (ใหญ่ขึ้น 1.5 เท่าให้เห็นชัด 2026-10-31)
local function leafPart(cf, scale)
	local p = sproutPart(sproutFolder, Vector3.new(0.06, 0.95, 0.4) * scale, cf, LEAF_GREENS[math.random(1, #LEAF_GREENS)], Enum.PartType.Block)
	return p
end

-- ใบตองร่วงลงนอนบนพื้นแล้วค่อยจาง
local function dropLeaf(pos)
	local rest = CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	local p = leafPart(rest * CFrame.new(-0.7, 0, 0) * CFrame.Angles(math.rad(math.random(-60, 60)), 0, 0), 1)
	TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = rest }):Play()
	task.delay(LEAF_LIFE, function()
		TweenService:Create(p, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		task.delay(0.7, function() p:Destroy() end)
	end)
end

local function playLandSound(pos)
	local holder = sproutPart(sproutFolder, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), Color3.new(1, 1, 1))
	holder.Transparency = 1
	local s = Instance.new("Sound")
	s.SoundId = LAND_SOUND
	s.Volume = 0.7
	s.PlaybackSpeed = 1.1
	s.RollOffMaxDistance = 60
	s.SoundGroup = game:GetService("SoundService"):FindFirstChild("EffectSounds")
	s.Parent = holder
	s:Play()
	task.delay(0.45, function() if s.Parent then s:Stop() end end)
	task.delay(1, function() holder:Destroy() end)
end

-- ลงพื้น: ใบตองกระจายเป็นวง + ฝุ่น + เสียงตุ้บ
local function landBurst(pos)
	local n = 12
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + math.random() * 0.3
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local start = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		local p = leafPart(start, 0.9 + math.random() * 0.4)
		local mid = pos + dir * (1.6 + math.random() * 0.9) + Vector3.new(0, 1.1 + math.random() * 0.6, 0)
		local land = pos + dir * (2.6 + math.random() * 1.2) + Vector3.new(0, 0.05, 0)
		TweenService:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(mid) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) }):Play()
		task.delay(0.25, function()
			if not p.Parent then return end
			TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(land) * CFrame.Angles(0, a, math.rad(90)) }):Play()
		end)
		task.delay(LEAF_LIFE, function()
			TweenService:Create(p, TweenInfo.new(0.6), { Transparency = 1 }):Play()
			task.delay(0.7, function() p:Destroy() end)
		end)
	end
	-- ฝุ่นวงกลม
	local holder = sproutPart(sproutFolder, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos + Vector3.new(0, 0.2, 0)), Color3.new(1, 1, 1))
	holder.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(225, 210, 175))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 0.9)
	e.Speed = NumberRange.new(5, 8)
	e.SpreadAngle = Vector2.new(5, 180)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -3, 0)
	e.Drag = 4
	e.Rate = 0
	e.Rotation = NumberRange.new(0, 360)
	e.Parent = holder
	e.Orientation = Enum.ParticleOrientation.FacingCamera
	e:Emit(18)
	playLandSound(pos)
	task.delay(1.2, function() holder:Destroy() end)
end

RunService.Heartbeat:Connect(function()
	local camPos = workspace.CurrentCamera.CFrame.Position
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local mountId = player:GetAttribute("RidingMount")
		local character = mountId and player.Character
		local model = character and character:FindFirstChild("Mount_" .. mountId)
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if model and hrp and humanoid and model:GetAttribute("Perk") == "Gallop" and (hrp.Position - camPos).Magnitude < SPROUT_RANGE then
			local st = leafState[character]
			if not st then st = { last = 0, airSince = nil }; leafState[character] = st end
			groundParams.FilterDescendantsInstances = { sproutFolder, character }
			local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -(humanoid.HipHeight + hrp.Size.Y / 2 + LEAF_AIR_GAP), 0), groundParams)
			local grounded = hit ~= nil
			if not grounded then
				st.airSince = st.airSince or now
			else
				if st.airSince and now - st.airSince >= LAND_MIN_AIR and hit.Material ~= Enum.Material.Water then
					landBurst(hit.Position)
				end
				st.airSince = nil
				local v = hrp.AssemblyLinearVelocity
				if Vector3.new(v.X, 0, v.Z).Magnitude > MOVING_SPEED and now - st.last > LEAF_EVERY then
					st.last = now
					-- ใบตองหล่นแถวปลายก้าน (หลังตัวผู้ขี่)
					local back = hrp.CFrame * CFrame.new((math.random() - 0.5) * 1.2, 0, 2.5 + math.random() * 1.5)
					local g = workspace:Raycast(back.Position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), groundParams)
					if g and g.Material ~= Enum.Material.Water then dropLeaf(g.Position) end
				end
			end
		end
	end
end)
