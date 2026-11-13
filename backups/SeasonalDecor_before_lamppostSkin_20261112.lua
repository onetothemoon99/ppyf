-- Backup 2026-11-12 of ServerScriptService.SeasonalDecor (Script) before festival skins on the plaza Lamppost models.
-- To restore: paste everything below these 2 lines back into ServerScriptService.SeasonalDecor.Source.
-- SeasonalDecor: ของตกแต่งตามเทศกาล เปิด/ปิดทั้งชุดทีเดียว
-- ชุดตกแต่งเก็บเป็น Model ใน ServerStorage.SeasonalDecor ชื่อเดียวกับเทศกาลใน ReplicatedStorage.SeasonConfig (เช่น Halloween2026)
-- เทศกาลทำงาน -> สำเนาชุดนั้นไปวางใน workspace (ชื่อ SeasonalDecor_<เทศกาล>), เทศกาลจบ/ปิดสวิตช์ -> เก็บออกเอง
-- แก้ของตกแต่ง: ลาก Model จาก ServerStorage.SeasonalDecor มาไว้ใน Workspace แก้ใน Studio แล้วลากกลับ (ชิ้นส่วนไม่ต้องย้ายตำแหน่ง วางตรงจุดจริงอยู่แล้ว)
-- 2026-10-11 เพิ่ม: โคมไฟริมทางและขอบแปลงปลูกเปลี่ยนหน้าตาตามเทศกาล (ค่า Lanterns / Plots ใน SeasonConfig, ชิ้นส่วนใน ServerStorage.SeasonalProps.<เทศกาล>)
-- เปลี่ยนตอนเกมรันเท่านั้นและจำค่าเดิมไว้คืนตอนเทศกาลจบ (โคม/ขอบแปลงในไฟล์เกมไม่ถูกแก้)
-- 2026-10-13 ผูกตำแหน่ง (ผู้ใช้ขอ: ย้ายร้านแล้วของตกแต่งต้องตามไป): กลุ่มย่อยในชุดที่มี Attribute
--   AnchorPath (ทางไปของหลักใต้ workspace เช่น "Shops.FarmStall") + AnchorCFrame (จุดหมุนของของหลักตอนจัดวางชุดนี้)
--   ตอนวางชุด ชิ้นลูกทุกชิ้นของกลุ่มนั้นถูกย้าย/หมุนตามของหลักเท่ากับที่ของหลักขยับไปจากตอนจัด (หาของหลักไม่เจอ = วางตามพิกัดเดิม)
--   จัดกลุ่มนั้นใหม่ด้วยมือเมื่อไร ต้องตั้ง AnchorCFrame = จุดหมุนของของหลัก ณ ตอนนั้นด้วย
--   ฟักทองโคนโคม: สร้างตอนรันจาก SeasonalProps.<เทศกาล>.LanternBase (จุดหมุน = ก้นชิ้น) วางที่โคนโคมทุกต้น จึงตามโคมเอง

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SeasonConfig = require(ReplicatedStorage:WaitForChild("SeasonConfig"))
local decorSets = ServerStorage:WaitForChild("SeasonalDecor")

local CHECK_INTERVAL = 60 -- วินาที เซิร์ฟเวอร์ที่เปิดค้างข้ามเวลาเริ่ม/จบเทศกาลจะตามทันภายใน 1 นาที

local placed = {} -- [ชื่อเทศกาล] = Model ที่วางอยู่ใน workspace
local skins = {}  -- [ชื่อเทศกาล] = { folder = โฟลเดอร์ชิ้นที่เพิ่ม, undo = { ฟังก์ชันคืนค่าเดิม } }

-- เปลี่ยนค่า property แล้วจำค่าเดิมไว้คืน
local function setProp(undo, instance, property, value)
	local original = instance[property]
	instance[property] = value
	table.insert(undo, function()
		if instance.Parent then instance[property] = original end
	end)
end

local function cloneProp(template, cframe, parent)
	local copy = template:Clone()
	copy:PivotTo(cframe)
	copy.Parent = parent
	return copy
end

-- โคมไฟริมทาง: Model ชื่อ "Lantern" ใน workspace และ workspace.Lights (มี Glow + PointLight)
local LANTERN_HEAD_PARTS = { Bottom = true, Frame = true, Glow = true, Cap = true }
local BASE_OFFSET = Vector3.new(-1.9, 0, -1.2) -- ตำแหน่งของวางโคนโคม เทียบกับก้นเสา (แกนของโคม)
local baseParams = RaycastParams.new() -- หาพื้น (เฉพาะ terrain รวมผิวน้ำ)
baseParams.FilterType = Enum.RaycastFilterType.Include
baseParams.FilterDescendantsInstances = { workspace.Terrain }
baseParams.IgnoreWater = false
local function applyLanterns(cfg, props, folder, undo)
	local head = props:FindFirstChild(cfg.Head or "LanternHead")
	if not head then return end
	local base = props:FindFirstChild(cfg.Base or "LanternBase") -- ของวางโคนโคม (ไม่มี = ไม่วาง)
	local lanterns = {}
	for _, container in ipairs({ workspace, workspace:FindFirstChild("Lights") }) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Model") and child.Name == "Lantern" and child:FindFirstChild("Glow") then
				table.insert(lanterns, child)
			end
		end
	end
	for _, lantern in ipairs(lanterns) do
		local glow = lantern.Glow
		for _, part in ipairs(lantern:GetChildren()) do
			if part:IsA("BasePart") and LANTERN_HEAD_PARTS[part.Name] then
				setProp(undo, part, "Transparency", 1)
			end
		end
		local light = glow:FindFirstChildWhichIsA("Light")
		if light and cfg.LightColor then setProp(undo, light, "Color", cfg.LightColor) end
		-- หัวโคมเทศกาลหันหน้าตามแขนโคม (ออกจากเสา)
		local look = lantern:GetPivot().LookVector * Vector3.new(1, 0, 1)
		if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
		cloneProp(head, CFrame.lookAt(glow.Position, glow.Position + look), folder)
		if base then
			local foot = lantern:GetPivot() -- จุดหมุนของโคม = ก้นเสา
			local spot = (foot * CFrame.new(BASE_OFFSET)).Position
			-- วางบนพื้นจริงตรงจุดนั้น (โคมริมตลิ่ง/ริมน้ำ: จุดข้างเสาอาจเป็นน้ำหรือพื้นต่างระดับมาก = ไม่วาง)
			local hit = workspace:Raycast(spot + Vector3.new(0, 6, 0), Vector3.new(0, -12, 0), baseParams)
			if hit and hit.Material ~= Enum.Material.Water and math.abs(hit.Position.Y - foot.Position.Y) <= 1.5 then
				cloneProp(base, CFrame.new(hit.Position) * CFrame.Angles(0, (foot.Position.X + foot.Position.Z) % 6.28, 0), folder)
			end
		end
	end
end

-- ขอบแปลงปลูก: workspace.FarmDressing.RaisedBeds.<แปลง>_Edging (Beam x4, CornerPost x4, SignPost, Sign)
local function applyPlots(cfg, props, folder, undo)
	local dressing = workspace:FindFirstChild("FarmDressing")
	local beds = dressing and dressing:FindFirstChild("RaisedBeds")
	local topper = cfg.Topper and props:FindFirstChild(cfg.Topper)
	for _, edging in ipairs(beds and beds:GetChildren() or {}) do
		if edging:IsA("Model") then
			local center = edging:GetBoundingBox().Position
			local posts = {}
			local sign
			for _, part in ipairs(edging:GetChildren()) do
				if part:IsA("BasePart") then
					if part.Name == "Beam" and cfg.BeamColor then
						setProp(undo, part, "Color", cfg.BeamColor)
					elseif part.Name == "CornerPost" then
						if cfg.PostColor then setProp(undo, part, "Color", cfg.PostColor) end
						table.insert(posts, part)
					elseif part.Name == "Sign" then
						sign = part
						if cfg.SignColor then setProp(undo, part, "Color", cfg.SignColor) end
					end
				end
			end
			if topper then
				-- ฟักทองบนเสามุมทแยง 2 ต้น (ต้นแรก + ต้นที่ไกลที่สุดจากต้นแรก) หันหน้าออกนอกแปลง
				table.sort(posts, function(a, b)
					if a.Position.X ~= b.Position.X then return a.Position.X < b.Position.X end
					return a.Position.Z < b.Position.Z
				end)
				local chosen = {}
				if posts[1] then
					table.insert(chosen, posts[1])
					local far, farDist = nil, 0
					for _, post in ipairs(posts) do
						local d = (post.Position - posts[1].Position).Magnitude
						if d > farDist then far, farDist = post, d end
					end
					if far then table.insert(chosen, far) end
				end
				for _, post in ipairs(chosen) do
					local top = post.Position + Vector3.new(0, post.Size.Y / 2, 0)
					local out = (post.Position - center) * Vector3.new(1, 0, 1)
					if out.Magnitude < 0.01 then out = Vector3.new(0, 0, -1) end
					cloneProp(topper, CFrame.lookAt(top, top + out), folder)
				end
				-- อีกลูกนั่งบนป้ายชื่อแปลง หันทางเดียวกับหน้าป้าย
				if sign then
					local top = sign.Position + Vector3.new(0, sign.Size.Y / 2, 0)
					local look = sign.CFrame.LookVector * Vector3.new(1, 0, 1)
					if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
					cloneProp(topper, CFrame.lookAt(top, top + look), folder)
				end
			end
		end
	end

	-- ผังเกาะใหม่ (2026-10-13): รั้วไม้รอบแปลง workspace.IslandDecor.PlotFences.Fence<n> (Post / Rail) และป้ายเลขแปลง PlotNumbers.PlotNumber<n> (Post / Board)
	-- ราวรั้ว = BeamColor, เสา = PostColor, แผ่นป้าย = SignColor, ฟักทอง (Topper) บนเสามุมทั้ง 4 มุมของรั้ว + บนป้ายเลข หันหน้าออกนอกแปลง
	local island = workspace:FindFirstChild("IslandDecor")
	local fences = island and island:FindFirstChild("PlotFences")
	local centers = {} -- [เลขแปลง] = จุดกลางรั้ว (ใช้หันฟักทองบนป้ายออกนอกแปลง)
	for _, fence in ipairs(fences and fences:GetChildren() or {}) do
		if fence:IsA("Model") then
			local center = fence:GetBoundingBox().Position
			centers[fence.Name:match("%d+") or fence.Name] = center
			local corner = {} -- [มุม] = เสาที่ไกลจุดกลางที่สุดในมุมนั้น
			for _, part in ipairs(fence:GetChildren()) do
				if part:IsA("BasePart") then
					if part.Name == "Rail" and cfg.BeamColor then
						setProp(undo, part, "Color", cfg.BeamColor)
					elseif part.Name == "Post" then
						if cfg.PostColor then setProp(undo, part, "Color", cfg.PostColor) end
						local off = part.Position - center
						local key = (off.X >= 0 and "+" or "-") .. (off.Z >= 0 and "+" or "-")
						local dist = off.X * off.X + off.Z * off.Z
						if not corner[key] or dist > corner[key].dist then corner[key] = { post = part, dist = dist } end
					end
				end
			end
			if topper then
				for _, entry in pairs(corner) do
					local post = entry.post
					local top = post.Position + Vector3.new(0, post.Size.Y / 2, 0)
					local out = (post.Position - center) * Vector3.new(1, 0, 1)
					if out.Magnitude < 0.01 then out = Vector3.new(0, 0, -1) end
					cloneProp(topper, CFrame.lookAt(top, top + out), folder)
				end
			end
		end
	end
	local numbers = island and island:FindFirstChild("PlotNumbers")
	for _, number in ipairs(numbers and numbers:GetChildren() or {}) do
		if number:IsA("Model") then
			local post, board = number:FindFirstChild("Post"), number:FindFirstChild("Board")
			if post and post:IsA("BasePart") and cfg.PostColor then setProp(undo, post, "Color", cfg.PostColor) end
			if board and board:IsA("BasePart") then
				if cfg.SignColor then setProp(undo, board, "Color", cfg.SignColor) end
				if topper then
					local top = board.Position + Vector3.new(0, board.Size.Y / 2, 0)
					-- หน้าป้าย = แกนบางของแผ่น (RightVector) เลือกด้านที่หันออกจากแปลง
					local face = board.CFrame.RightVector * Vector3.new(1, 0, 1)
					if face.Magnitude < 0.01 then face = Vector3.new(0, 0, -1) end
					local center = centers[number.Name:match("%d+") or number.Name]
					if center and face:Dot((board.Position - center) * Vector3.new(1, 0, 1)) < 0 then face = -face end
					cloneProp(topper, CFrame.lookAt(top, top + face), folder)
				end
			end
		end
	end
	-- เกาะ v5 (2026-11-10): รั้วรอบพื้นที่แปลง workspace.IslandDecor.PlotAreas.<Area> (Post / Rail / GatePost เป็น Part ตรงในโมเดล)
	-- ราว = BeamColor, เสา + เสาประตู = PostColor, Topper บนเสามุม 4 มุม (เสาที่ไกลจุดกลางที่สุดในแต่ละมุม) และบนเสาประตูทั้งสองต้น หันออกนอกแปลง
	local areas = island and island:FindFirstChild("PlotAreas")
	for _, area in ipairs(areas and areas:GetChildren() or {}) do
		if area:IsA("Model") or area:IsA("Folder") then
			local sum, n = Vector3.zero, 0
			for _, part in ipairs(area:GetChildren()) do
				if part:IsA("BasePart") and (part.Name == "Post" or part.Name == "GatePost") then sum += part.Position; n += 1 end
			end
			if n > 0 then
				local center = sum / n
				local corner, gates = {}, {}
				for _, part in ipairs(area:GetChildren()) do
					if part:IsA("BasePart") then
						if part.Name == "Rail" and cfg.BeamColor then
							setProp(undo, part, "Color", cfg.BeamColor)
						elseif part.Name == "Post" or part.Name == "GatePost" then
							if cfg.PostColor then setProp(undo, part, "Color", cfg.PostColor) end
							if part.Name == "GatePost" then
								table.insert(gates, part)
							else
								local off = part.Position - center
								local key = (off.X >= 0 and "+" or "-") .. (off.Z >= 0 and "+" or "-")
								local dist = off.X * off.X + off.Z * off.Z
								if not corner[key] or dist > corner[key].dist then corner[key] = { post = part, dist = dist } end
							end
						end
					end
				end
				if topper then
					local tops = {}
					for _, entry in pairs(corner) do table.insert(tops, entry.post) end
					for _, g in ipairs(gates) do table.insert(tops, g) end
					for _, post in ipairs(tops) do
						local cf = post.CFrame
						local h = post.Size / 2
						local ey = math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z
						local top = post.Position + Vector3.new(0, ey, 0)
						local out = (post.Position - center) * Vector3.new(1, 0, 1)
						if out.Magnitude < 0.01 then out = Vector3.new(0, 0, -1) end
						cloneProp(topper, CFrame.lookAt(top, top + out), folder)
					end
				end
			end
		end
	end
end

-- ต้นไม้: MeshPart ที่ MeshId ตรงกับตาราง Trees ถูกซ่อน (โปร่งใส) แล้ววางชิ้นเทศกาลขนาด/ตำแหน่งเดียวกันทับ (เมชของ MeshPart เปลี่ยนตอนเกมรันไม่ได้ จึงต้องสลับทั้งชิ้น)
-- หาใน workspace.FarmFlora / Shops / FishingShop และโมเดลชั้นบนสุดของ workspace ที่ชื่อมีคำว่า Tree
-- ค่าในตารางเป็นชื่อชิ้น หรือ { Prop = ชื่อชิ้น, Follow = true } (Follow = ติดแท็ก SeasonFollow + ObjectValue "SeasonSource" ให้ฝั่งผู้เล่นขยับตามชิ้นเดิม)
local SWAP_ROOTS = { "FarmFlora", "Shops", "FishingShop", "GachaMachine", "PetFoodMachine" }
local function applyTrees(map, props, folder, undo)
	local roots = {}
	for _, name in ipairs(SWAP_ROOTS) do
		local root = workspace:FindFirstChild(name)
		if root then table.insert(roots, root) end
	end
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child.Name:find("Tree") then table.insert(roots, child) end
	end
	for _, root in ipairs(roots) do
		for _, part in ipairs(root:GetDescendants()) do
			if part:IsA("MeshPart") then
				local entry = map[part.MeshId]
				local propName = type(entry) == "table" and entry.Prop or entry
				local template = propName and props:FindFirstChild(propName)
				if template then
					local copy = template:Clone()
					copy.Size = part.Size
					copy.CFrame = part.CFrame
					copy.CastShadow = part.CastShadow
					if type(entry) == "table" and entry.Follow then
						local source = Instance.new("ObjectValue")
						source.Name = "SeasonSource"
						source.Value = part
						source.Parent = copy
						copy:AddTag("SeasonFollow")
					end
					copy.Parent = folder
					setProp(undo, part, "Transparency", 1)
				end
			end
		end
	end
end

-- ย้ายกลุ่มย่อยที่ผูกกับของหลัก (AnchorPath / AnchorCFrame) ตามตำแหน่งปัจจุบันของของหลัก
local function resolveAnchor(path)
	local node = workspace
	for _, name in ipairs(string.split(path, ".")) do
		node = node:FindFirstChild(name)
		if not node then return nil end
	end
	return node
end
local function applyAnchors(set)
	local groups = set:GetDescendants()
	for _, group in ipairs(groups) do
		local path, stored = group:GetAttribute("AnchorPath"), group:GetAttribute("AnchorCFrame")
		if type(path) == "string" and typeof(stored) == "CFrame" then
			local anchor = resolveAnchor(path)
			local now = anchor and ((anchor:IsA("Model") and anchor:GetPivot()) or (anchor:IsA("BasePart") and anchor.CFrame))
			if now then
				local delta = now * stored:Inverse()
				for _, piece in ipairs(group:GetChildren()) do
					if piece:IsA("PVInstance") then piece:PivotTo(delta * piece:GetPivot()) end
				end
			end
		end
	end
end

-- ของที่ประกอบจากชิ้นส่วนธรรมดา (ไม่ใช่เมชเดียว เช่น โต๊ะช่างนากน้อย): เปลี่ยนสีตามตาราง SeasonConfig...Recolors (2026-10-13)
--   Path = ทางไปของใต้ workspace, Colors = { ["r,g,b" เดิม] = สีใหม่ }, ByName = { [ชื่อชิ้น] = { ["r,g,b" เดิม] = สีใหม่ } } (มาก่อน Colors)
--   Topper + TopperOn = { [ชื่อชิ้น] = true } = วางชิ้นเทศกาลบนชิ้นนั้น หันไปทาง FrontPart (เทียบจากจุดกลางของ) เมช (MeshPart) ไม่ถูกแตะ
--   เปลี่ยนตอนเกมรันเท่านั้น จำค่าเดิมไว้คืนตอนเทศกาลจบ; อ่านตำแหน่งของตอนนั้น ย้ายของใน Studio แล้วสกินตามไปเอง
local function colorKey(c)
	return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function applyRecolors(list, props, folder, undo)
	for _, entry in ipairs(list) do
		local root = resolveAnchor(entry.Path)
		if root then
			local center = (root:IsA("Model") and root:GetBoundingBox().Position) or root.Position
			local frontPart = entry.FrontPart and root:FindFirstChild(entry.FrontPart, true)
			local front = frontPart and frontPart:IsA("BasePart") and (frontPart.Position - center) * Vector3.new(1, 0, 1) or Vector3.new(0, 0, -1)
			if front.Magnitude < 0.01 then front = Vector3.new(0, 0, -1) end
			local topper = entry.Topper and props:FindFirstChild(entry.Topper)
			for _, part in ipairs(root:GetDescendants()) do
				if part:IsA("BasePart") and not part:IsA("MeshPart") then
					local key = colorKey(part.Color)
					local byName = entry.ByName and entry.ByName[part.Name]
					local to = (byName and byName[key]) or (entry.Colors and entry.Colors[key])
					if to then setProp(undo, part, "Color", to) end
					if topper and entry.TopperOn and entry.TopperOn[part.Name] then
						local cf, size = part.CFrame, part.Size
						local half = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
						local top = part.Position + Vector3.new(0, half - 0.1, 0)
						local copy = topper:Clone()
						if entry.TopperScale and copy:IsA("Model") then copy:ScaleTo(copy:GetScale() * entry.TopperScale) end
						copy:PivotTo(CFrame.lookAt(top, top + front))
						copy.Parent = folder
					end
				end
			end
		end
	end
end

local function applySkins(seasonId)
	local season = SeasonConfig.Seasons[seasonId]
	local propsRoot = ServerStorage:FindFirstChild("SeasonalProps")
	local props = propsRoot and propsRoot:FindFirstChild(seasonId)
	if not season or not props or not (season.Lanterns or season.Plots or season.Trees or season.Swaps or season.Recolors) then return end
	local folder = Instance.new("Folder")
	folder.Name = "SeasonalSkin_" .. seasonId
	local undo = {}
	if season.Lanterns then
		local ok, err = pcall(applyLanterns, season.Lanterns, props, folder, undo)
		if not ok then warn("SeasonalDecor: เปลี่ยนโคมไม่สำเร็จ " .. tostring(err)) end
	end
	if season.Trees or season.Swaps then
		local map = {}
		for meshId, entry in pairs(season.Trees or {}) do map[meshId] = entry end
		for meshId, entry in pairs(season.Swaps or {}) do map[meshId] = entry end
		local ok, err = pcall(applyTrees, map, props, folder, undo)
		if not ok then warn("SeasonalDecor: เปลี่ยนต้นไม้ไม่สำเร็จ " .. tostring(err)) end
	end
	if season.Plots then
		local ok, err = pcall(applyPlots, season.Plots, props, folder, undo)
		if not ok then warn("SeasonalDecor: เปลี่ยนขอบแปลงไม่สำเร็จ " .. tostring(err)) end
	end
	if season.Recolors then
		local ok, err = pcall(applyRecolors, season.Recolors, props, folder, undo)
		if not ok then warn("SeasonalDecor: เปลี่ยนสีของตามเทศกาลไม่สำเร็จ " .. tostring(err)) end
	end
	folder.Parent = workspace
	skins[seasonId] = { folder = folder, undo = undo }
end

local function removeSkins(seasonId)
	local skin = skins[seasonId]
	if not skin then return end
	for i = #skin.undo, 1, -1 do pcall(skin.undo[i]) end
	skin.folder:Destroy()
	skins[seasonId] = nil
end

local function refresh()
	for seasonId in pairs(SeasonConfig.Seasons) do
		local active = SeasonConfig.IsDecorActive(seasonId) -- จบได้ก่อนเทศกาล (DecorEndUtc)
		local set = decorSets:FindFirstChild(seasonId)
		if active and set and not placed[seasonId] then
			local copy = set:Clone()
			copy.Name = "SeasonalDecor_" .. seasonId
			local okAnchor, errAnchor = pcall(applyAnchors, copy)
			if not okAnchor then warn("SeasonalDecor: ผูกตำแหน่งของตกแต่งไม่สำเร็จ " .. tostring(errAnchor)) end
			copy.Parent = workspace
			placed[seasonId] = copy
		elseif not active and placed[seasonId] then
			placed[seasonId]:Destroy()
			placed[seasonId] = nil
		end
		if active and not skins[seasonId] then
			applySkins(seasonId)
		elseif not active and skins[seasonId] then
			removeSkins(seasonId)
		end
	end
end

while true do
	refresh()
	task.wait(CHECK_INTERVAL)
end
