-- BACKUP 2026-11-16 of game.StarterPlayer.StarterPlayerScripts.TutorialGui (LocalScript) before "stream destination before far warp" change.
-- Restore: replace the script's whole Source in Studio with everything BELOW the "==== SOURCE ====" line.
-- ==== SOURCE ====
-- 2026-10-27 ปิดบทเรียนผู้เล่นใหม่ทั้งระบบ (ผู้ใช้สั่ง) สคริปต์นี้ Enabled = false · สำเนาก่อนปิด ServerStorage._Backup_20261027 · เปิดคืน = Enabled = true ทั้ง TutorialService + TutorialGui และ TutorialGate.ENABLED = true
-- TutorialGui: บทเรียนผู้เล่นใหม่ (รุ่น 2, 2026-10-18) ขั้นหลัก 8 + ภารกิจเพิ่มเติม 3 ขั้นปัจจุบันมาจาก TutorialService (Attribute "TutorialStep")
--   ไม่มีหน้าต่างต้อนรับแล้ว (การ์ดภารกิจขึ้นทันที) · ตัวชี้ทางอยู่ระดับสายตา: ลูกศร 3D ลอยหน้าตัวผู้เล่นชี้ไปเป้า + เส้นแสงระดับอก
--   การ์ดภารกิจด้านบนจอ + เส้นแสงจากตัวละครไปเป้าหมาย + ป้าย ⬇️ เด้งเหนือเป้าหมาย
--   เช็กว่าทำขั้นนั้นเสร็จจากของในกระเป๋า/ค่าบนตัวผู้เล่น แล้วบอกเซิร์ฟเวอร์ (advance) / ปุ่ม ❓ มุมขวาบน = เล่นบทเรียนใหม่
--   2026-10-24 ปุ่ม 🧭 นำทาง (เดินไปเป้าเอง) + ▶ AUTO (เดินไป + ปลูก/เก็บ/ตกปลาให้ เปิดหน้าต่างร้าน/ตู้ให้) บนการ์ดภารกิจ ดูหัวข้อ "นำทาง + AUTO"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local request = remoteEvents:WaitForChild("TutorialRequest")
local fishingState = remoteEvents:WaitForChild("FishingState")

local tr = require(ReplicatedStorage:WaitForChild("Localization")).Tr()

local LAST_STEP = require(ReplicatedStorage:WaitForChild("ChickenConfig")).Enabled and 17 or 11 -- 2026-10-24 ภารกิจบ้านไก่ 6 ขั้น (12-17) ระบบไก่ปิดอยู่ = ไม่มีขั้นไก่ (ต้องตรงกับ TutorialService) -- 2026-10-22 +ภารกิจเสริม "ไปบ้านไก่" (ต้องตรงกับ TutorialService)
local ChickenConfig = require(ReplicatedStorage:WaitForChild("ChickenConfig"))
local CORE_LAST = 8 -- จบขั้นนี้ได้รางวัล หลังจากนั้นเป็นภารกิจเพิ่มเติม (ต้องตรงกับ TutorialService)
local REWARD_TEXT = tr("💰 100,000 เหรียญ", "💰 100,000 coins") -- ต้องตรงกับ TutorialService.REWARD_COINS (ขึ้นจาก 1,000 เมื่อ 2026-10-23)
local COLOR_TEXT = Color3.fromRGB(70, 50, 35)
local COLOR_SUB = Color3.fromRGB(125, 100, 85)
local GOLD = Color3.fromRGB(255, 200, 70)

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = obj; return c end
local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 14
	l.TextColor3 = color or COLOR_TEXT
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextWrapped = true
	l.Parent = parent
	return l
end
local function button(parent, text, color, textColor)
	local b = Instance.new("TextButton")
	b.Text = text
	b.TextSize = 15
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = textColor or COLOR_TEXT
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Selectable = true -- จอยเลือกได้
	b.Parent = parent
	corner(b, 12)
	return b
end

-- ============ ของในกระเป๋า ============
local function allTools()
	local list = {}
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, t in ipairs(loc and loc:GetChildren() or {}) do
			if t:IsA("Tool") then table.insert(list, t) end
		end
	end
	return list
end
local function countSeeds()
	local n = 0
	for _, t in ipairs(allTools()) do
		if t:GetAttribute("CropType") and not t:GetAttribute("IsProduce") and not t:GetAttribute("IsBooster") then n += t:GetAttribute("Count") or 1 end
	end
	return n
end
local function countProduce()
	local n = 0
	for _, t in ipairs(allTools()) do
		if t:GetAttribute("IsProduce") then n += t:GetAttribute("Count") or 1 end
	end
	return n
end
local function coins()
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("เหรียญ")
	return c and c.Value or 0
end
local function rootPart()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- ============ หาเป้าหมาย ============
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function shopPos()
	local shops0 = workspace:FindFirstChild("Shops")
	groundParams.FilterDescendantsInstances = { player.Character, shops0 and shops0:FindFirstChild("Shop") }
	local shops = workspace:FindFirstChild("Shops")
	local shop = shops and shops:FindFirstChild("Shop")
	if not shop then return nil end
	local hit = workspace:Raycast(shop.Position + Vector3.new(0, 2, 0), Vector3.new(0, -40, 0), groundParams)
	return hit and hit.Position or (shop.Position - Vector3.new(0, 6, 0))
end

local function nearestSoil()
	local root = rootPart()
	local plots = workspace:FindFirstChild("FarmPlots")
	if not (root and plots) then return nil end
	local best, bestD, bestSoil
	for _, d in ipairs(plots:GetDescendants()) do
		if d.Name == "Soil" and d:IsA("BasePart") then
			-- จุดบนดินที่ใกล้ผู้เล่นที่สุด (แปลงใหญ่ไม่ต้องเดินไปกลางแปลง)
			local lp = d.CFrame:PointToObjectSpace(root.Position)
			local hx, hz = d.Size.X / 2 - 1, d.Size.Z / 2 - 1
			local p = d.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -hx, hx), d.Size.Y / 2, math.clamp(lp.Z, -hz, hz)))
			local dist = (p - root.Position).Magnitude
			if not bestD or dist < bestD then best, bestD, bestSoil = p, dist, d end
		end
	end
	-- ผังเกาะใหม่ (2026-10-13): แปลงหลักเป็นเกาะมีคูน้ำล้อม → ชี้ขอบดินตรงสะพานของแปลงนั้นที่ใกล้ผู้เล่นที่สุด
	-- เส้นนำทางจะได้พาขึ้นสะพาน ไม่พาดข้ามน้ำ (แปลงที่ไม่มีสะพานใกล้ๆ เช่นนาขั้นบันได/หาด = จุดบนดินที่ใกล้สุดเหมือนเดิม)
	local bridges = workspace:FindFirstChild("FarmBridges")
	if bestSoil and bridges then
		local nearBridge, nearD
		for _, bridge in ipairs(bridges:GetChildren()) do
			if bridge:IsA("BasePart") then
				local lp = bestSoil.CFrame:PointToObjectSpace(bridge.Position)
				local dx = math.max(math.abs(lp.X) - bestSoil.Size.X / 2, 0)
				local dz = math.max(math.abs(lp.Z) - bestSoil.Size.Z / 2, 0)
				if math.sqrt(dx * dx + dz * dz) <= 16 then -- สะพานของแปลงนี้ (ติดขอบดินไม่เกิน 16)
					local dist = (bridge.Position - root.Position).Magnitude
					if not nearD or dist < nearD then nearBridge, nearD = bridge, dist end
				end
			end
		end
		if nearBridge then
			local lp = bestSoil.CFrame:PointToObjectSpace(nearBridge.Position)
			local hx, hz = bestSoil.Size.X / 2 - 2, bestSoil.Size.Z / 2 - 2
			best = bestSoil.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -hx, hx), bestSoil.Size.Y / 2, math.clamp(lp.Z, -hz, hz)))
		end
	end
	return best, bestSoil -- แผ่นดินด้วย (AUTO ปลูกใช้)
end

local myCrop -- ช่องปลูกของเราที่จะชี้ตอนขั้นเก็บเกี่ยว
-- 2026-10-24: เดิมใช้ GetPartBoundsInRadius แต่ช่องปลูกตั้ง CanQuery = false (แก้คลิกปลูก 2026-10-01) เลยไม่เคยเจอต้นเลย
-- ตอนนี้ไล่ดู PlantSlot<n> ใต้ Soil ทุกแผ่น (มีเฉพาะช่องที่มีต้น) · ต้นที่โตแล้ว (ป้าย E เปิด) มาก่อน แล้วค่อยดูต้นที่ใกล้สุด
local function findMyCrop()
	local root = rootPart()
	local plots = workspace:FindFirstChild("FarmPlots")
	if not (root and plots) then return nil end
	local best, bestScore
	for _, plot in ipairs(plots:GetChildren()) do
		for _, soil in ipairs(plot:GetChildren()) do
			if soil.Name == "Soil" and soil:IsA("BasePart") then
				for _, part in ipairs(soil:GetChildren()) do
					if part:IsA("BasePart") and part.Name:sub(1, 9) == "PlantSlot" and part:GetAttribute("OwnerUserId") == player.UserId then
						local dist = (part.Position - root.Position).Magnitude
						local prompt = part:FindFirstChildOfClass("ProximityPrompt")
						local score = dist - ((prompt and prompt.Enabled) and 1000 or 0)
						if dist <= 120 and (not bestScore or score < bestScore) then best, bestScore = part, score end
					end
				end
			end
		end
	end
	return best
end

local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false
waterParams.FilterType = Enum.RaycastFilterType.Exclude
local function nearestWater(fromPosition)
	local root = rootPart()
	local origin = fromPosition or (root and root.Position)
	if not origin then return nil end
	waterParams.FilterDescendantsInstances = { player.Character }
	for r = 12, 150, 12 do
		for i = 0, 15 do
			local a = i / 16 * math.pi * 2
			local p = origin + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local hit = workspace:Raycast(Vector3.new(p.X, origin.Y + 40, p.Z), Vector3.new(0, -90, 0), waterParams)
			if hit and hit.Material == Enum.Material.Water then return hit.Position end
		end
	end
	-- ไม่เจอใกล้ๆ: ไปท่าน้ำทะเลสาบ
	local dock = workspace:FindFirstChild("RestSpots") and workspace.RestSpots:FindFirstChild("LakeDock")
	return dock and dock:GetPivot().Position or nil
end

-- 2026-10-18 ผู้ใช้เลือกจุดตกปลาของบทเรียน: ขอบลานอิฐหลังร้านเมล็ดพันธุ์ (ใกล้เครื่องทำอาหารสัตว์) น้ำอยู่ถัดไปทาง +X ราว 3 สตั๊ด
-- เป็นจุดที่ยืน (พื้นอิฐ y 4) ไม่ใช่ผิวน้ำ ยืนตรงนี้ถือเบ็ด เบ็ดหาน้ำตรงหน้าเหวี่ยงเอง · หาไม่เจอน้ำตรงนั้น (แมพเปลี่ยน) = กลับไปหาน้ำใกล้ตัวเหมือนเดิม
local TUTORIAL_FISH_SPOT = Vector3.new(86, 4, -124)
local function tutorialFishingWater()
	local check = workspace:Raycast(Vector3.new(TUTORIAL_FISH_SPOT.X + 3, 40, TUTORIAL_FISH_SPOT.Z), Vector3.new(0, -80, 0), waterParams)
	if check and check.Material == Enum.Material.Water then return TUTORIAL_FISH_SPOT end
	local plots = workspace:FindFirstChild("FarmPlots")
	local plot3 = plots and plots:FindFirstChild("FarmPlot3")
	local soil = plot3 and plot3:FindFirstChild("Soil")
	-- ผังเกาะใหม่ (2026-10-13): มีน้ำตกปลาได้ติดลานร้าน ไม่ต้องพาไปถึงแปลง 3 (ห่างราว 160 สตั๊ด) ใช้น้ำที่ใกล้ผู้เล่นที่สุดแทน
	return nearestWater()
end

-- id = ใช้เช็กว่าทำขั้นนั้นเสร็จหรือยัง (runStep) ลำดับในตารางนี้ = ลำดับขั้นจริง (ต้องตรงกับ LAST_STEP ใน TutorialService)
-- รุ่น 2 (2026-10-18): เริ่มที่ปลูกเลย (เซิร์ฟเวอร์แจกเมล็ด 5 ถุง) ซื้อเมล็ดย้ายมาหลังขาย · อาหารสัตว์ย้ายไปเป็นภารกิจเพิ่มเติมท้ายสุด
local STEPS = {
	{ id = "plant", icon = "🌱", title = tr("ปลูกผัก", "Plant"), text = tr("เมล็ดฟรีอยู่ช่อง 1 ในแถบด้านล่าง กดช่อง 1 (หรือเลข 1) เดินตามลูกศร แล้วคลิก/แตะดินสีน้ำตาลเพื่อปลูก", "Your free seeds are in slot 1 on the bottom bar. Tap slot 1 (or press 1), follow the arrow and click/tap the brown soil to plant"), mark = tr("🌱 ปลูกตรงนี้", "🌱 Plant here") },
	{ id = "harvest", icon = "🌾", title = tr("เก็บเกี่ยว", "Harvest"), text = tr("รอต้นโตสักครู่ (ประมาณ 20 วินาที) โตแล้วเดินไปกด E ค้างที่ต้นเพื่อเก็บ", "Wait a moment for it to grow (about 20 seconds), then walk up and hold E on the plant to harvest"), mark = tr("🌾 ต้นของคุณ", "🌾 Your plant") },
	{ id = "sell", icon = "💰", title = tr("ขายผลผลิต", "Sell produce"), text = tr("เดินตามลูกศรไปร้านเมล็ดพันธุ์ กด E แล้วเลือกแท็บ \"ขายผลผลิต\" เพื่อขายรับเหรียญ", "Follow the arrow to the seed shop, press E and pick the \"Sell\" tab to sell your produce for coins"), mark = tr("💰 ขายที่นี่", "💰 Sell here") },
	{ id = "buy", icon = "🛒", title = tr("ซื้อเมล็ดเพิ่ม", "Buy more seeds"), text = tr("ใช้เงินที่ขายได้ กดแท็บ \"ซื้อเมล็ดพันธุ์\" แล้วซื้อเมล็ดอะไรก็ได้สักถุง · เมล็ดที่ซื้อจะไปอยู่ช่อง 1 หรือ 2", "Use the coins you earned: open the \"Buy seeds\" tab and buy any seed bag · seeds go to slot 1 or 2"), mark = tr("🛒 ร้านเมล็ดพันธุ์", "🛒 Seed Shop") },
	{ id = "fish", icon = "🎣", title = tr("ตกปลา", "Go fishing"), text = tr("กดช่อง 6 🎣 ในแถบด้านล่าง (หรือเลข 6) เพื่อถือเบ็ด เดินตามลูกศรไปริมน้ำ แล้วเบ็ดจะตกปลาให้เอง", "Tap slot 6 🎣 on the bottom bar (or press 6) to hold your rod, follow the arrow to the water, and it will fish for you"), mark = tr("🎣 ตกปลาตรงนี้", "🎣 Fish here") },
	{ id = "gachaBuy", icon = "🎟️", title = tr("รับตั๋วสุ่มฟรี", "Get a free gacha ticket"), text = tr("ไปที่ตู้สุ่มสัตว์เลี้ยง กด E แล้วกดซื้อ \"ตั๋วธรรมดา 1 ใบ\" · ใบแรกฟรี! ✨", "Go to the pet gacha machine, press E and buy \"1 Normal Ticket\" · the first one is free! ✨"), mark = tr("🎟️ ตู้สุ่มสัตว์เลี้ยง", "🎟️ Pet Gacha") },
	{ id = "gachaRoll", icon = "🎰", title = tr("สุ่มสัตว์เลี้ยง", "Roll for a pet"), text = tr("กดปุ่ม \"สุ่ม 1 ครั้ง\" ที่ตู้ แล้วลุ้นว่าจะได้สัตว์เลี้ยงตัวไหน! 🐾", "Tap \"Roll x1\" at the machine and see which pet you get! 🐾"), mark = tr("🎰 สุ่มที่นี่", "🎰 Roll here") },
	{ id = "petUse", icon = "🐾", title = tr("พาสัตว์เลี้ยงออกมา", "Bring out your pet"), text = tr("กดปุ่ม 🐾 มุมขวาบน แล้วกด \"เลือก\" ที่สัตว์ตัวใหม่ มันจะตามคุณและช่วยทำฟาร์ม (ขึ้น \"เลิกใช้\" = ออกมาอยู่แล้ว)", "Tap 🐾 at the top right and tap \"Select\" on your new pet. It follows you and helps on the farm (\"Unequip\" = already out)"), mark = nil },
	{ id = "foodInsert", icon = "🥫", title = tr("ทำอาหารสัตว์", "Make pet food"), text = tr("สัตว์เลี้ยงกินได้เฉพาะอาหารสัตว์! ไปที่เครื่องทำอาหารสัตว์ กด E แล้วกด \"ใส่\" ผลผลิต (ดาวเดียวกัน 2 ชิ้น = 1 ถุง)", "Pets only eat pet food! Go to the pet food machine, press E and tap \"Insert\" to add produce (2 of the same star = 1 bag)"), mark = tr("🥫 เครื่องทำอาหารสัตว์", "🥫 Pet Food Maker") },
	{ id = "foodCollect", icon = "📦", title = tr("รับอาหารสัตว์", "Collect pet food"), text = tr("เครื่องกำลังทำ (ถุงละประมาณ 20 วินาที) เสร็จแล้วกด E ที่เครื่อง แล้วกด \"รับอาหาร\"", "The machine is working (about 20 seconds per bag). When done, press E at the machine and tap \"Collect\""), mark = tr("📦 รับอาหารที่นี่", "📦 Collect food here") },
	{ id = "feed", icon = "🍖", title = tr("ป้อนอาหารสัตว์เลี้ยง", "Feed your pet"), text = tr("เปิดกระเป๋า 🎒 กด \"ใช้\" ที่อาหารสัตว์ 🥫 แล้วถือจากแถบด้านล่าง เดินไปใกล้สัตว์เลี้ยง กด F ค้างเพื่อให้อาหาร", "Open your bag 🎒, tap \"Use\" on the pet food 🥫 and hold it from the bottom bar. Walk up to your pet and hold F to feed it"), mark = tr("🍖 กด F ป้อนอาหาร", "🍖 Hold F to feed") },
	-- 2026-10-22 ภารกิจเสริมสุดท้าย: พาไปบ้านไก่ (ระบบไก่ปิดอยู่ = ผ่านขั้นนี้เอง)
	{ id = "chicken", icon = "🐔", title = tr("ไปบ้านไก่", "Visit the chicken coop"), text = tr("ไก่ออกไข่ให้ขายได้เงินแม้ตอนออกเกม! เดินตามลูกศรไปหาลุงไข่ขายไก่ กด E ดูไก่ที่ขาย (อาหารไก่ = ถุงอาหารสัตว์เทลงราง)", "Chickens lay eggs you can sell, even while you're offline! Follow the arrow to the Chicken Merchant and press E (chicken feed = pet food bags in the trough)"), mark = tr("🐔 ลุงไข่ขายไก่", "🐔 Chicken Merchant") },
	-- 2026-10-24 ภารกิจบ้านไก่ต่อ: ซื้อไก่ → เทอาหารลงราง → หยิบไม้กวาด → แผงไข่ → ตู้ฟัก (ทุกขั้นทำได้ทันที ไม่ต้องรอไข่ออก)
	{ id = "chickenBuy", icon = "🐣", title = tr("ซื้อไก่ตัวแรก", "Buy your first chicken"), text = tr("ที่ร้านลุงไข่ กดปุ่ม \"ซื้อไก่\" (ตัวละ 300 เหรียญ · ต้องเลเวล 2 ขึ้นไป) ไก่จะเดินเล่นในลานและออกไข่ให้เอง", "At the Chicken Merchant tap \"Buy chicken\" (300 coins each · needs level 2). It wanders the yard and lays eggs for you"), mark = tr("🐣 ซื้อไก่ที่นี่", "🐣 Buy chickens here") },
	{ id = "chickenFeed", icon = "🥣", title = tr("เติมอาหารไก่", "Feed the chickens"), text = tr("ไก่ต้องกินอาหารถึงจะออกไข่! ไปที่รางอาหาร กด E แล้วกดเทอาหารสัตว์ลงราง (1 ถุง = ไข่ 5 ฟอง)", "Chickens only lay eggs when fed! Go to the trough, press E and pour in pet food (1 bag = 5 eggs)"), mark = tr("🥣 รางอาหาร", "🥣 Trough") },
	{ id = "chickenBroom", icon = "🧹", title = tr("กวาดเล้า", "Clean the coop"), text = tr("เล้าจะสกปรกตามเวลา (สกปรกมากไข่จะช้าลง) ไปที่ไม้กวาดข้างเล้า กด E หยิบ แล้วคลิกกองดิน 🧹 ในลานเพื่อกวาด ได้เหรียญด้วย (วางคืนได้จากปุ่มบนจอ)", "The coop gets dirty over time (very dirty = slower eggs). Press E at the broom by the coop, then click the 🧹 dirt piles in the yard to sweep them for coins (put it back with the on-screen button)"), mark = tr("🧹 ไม้กวาด", "🧹 Broom") },
	{ id = "chickenEggs", icon = "🥚", title = tr("เก็บไข่ไปขาย", "Sell the eggs"), text = tr("ไข่เก็บในแผงไข่ (ออกให้แม้ตอนออกเกม) กด E ที่แผงไข่ แล้วกดขายไข่รับเหรียญ", "Eggs collect on the egg tray (even while you're offline). Press E at the tray and sell them for coins"), mark = tr("🥚 แผงไข่", "🥚 Egg tray") },
	{ id = "chickenHatch", icon = "🐥", title = tr("ฟักไข่เป็นลูกไก่", "Hatch an egg"), text = tr("ไข่ธรรมดา 5 ฟองฟักเป็นลูกไก่ตัวใหม่ได้! กด E ที่ตู้ฟัก (ไก่โตแล้วผสมพันธุ์ได้ที่เลเวล 20)", "5 normal eggs hatch into a new chick! Press E at the incubator (grown chickens can be bred from level 20)"), mark = tr("🐥 ตู้ฟักไข่", "🐥 Incubator") },
}

-- ============ ตัวช่วยของภารกิจบ้านไก่ (2026-10-24) ============
-- CHICKEN_PROMPT = ชื่อ ProximityPrompt ของแต่ละขั้นใต้ workspace.FarmProps.ChickenYard · CHICKEN_MODE = โหมดหน้าต่างที่ ChickenOpen ส่งมาเมื่อกดป้าย
local CHICKEN_PROMPT = { chicken = "ShopPrompt", chickenBuy = "ShopPrompt", chickenFeed = "TroughPrompt", chickenBroom = "CleanPrompt", chickenEggs = "EggPrompt", chickenHatch = "IncubatorPrompt" }
local CHICKEN_MODE = { chickenEggs = "basket", chickenHatch = "breed" }
local chk = { info = nil, openedAt = {}, req = nil } -- info = ข้อมูลไก่ล่าสุดจากเซิร์ฟ (ChickenSync) · openedAt[mode] = เวลาที่หน้าต่างนั้นเปิดล่าสุด
task.spawn(function()
	if not ChickenConfig.Enabled then return end
	local sync = remoteEvents:WaitForChild("ChickenSync", 15)
	local openEv = remoteEvents:WaitForChild("ChickenOpen", 15)
	chk.req = remoteEvents:WaitForChild("ChickenRequest", 15)
	if sync then sync.OnClientEvent:Connect(function(i) if type(i) == "table" and i.Loaded then chk.info = i end end) end
	if openEv then openEv.OnClientEvent:Connect(function(mode) chk.openedAt[mode] = os.clock() end) end
	if chk.req then
		local ok, res = pcall(function() return chk.req:InvokeServer("info") end)
		if ok and type(res) == "table" and res.info and res.info.Loaded then chk.info = res.info end
	end
end)
local function chickenPrompt(name)
	local node = workspace
	for _, n in ipairs(ChickenConfig.YARD_PATH) do node = node and node:FindFirstChild(n) end
	local p = node and node:FindFirstChild(name, true)
	return p and p:IsA("ProximityPrompt") and p or nil
end
local function chickenPromptPos(prompt)
	local p = prompt and prompt.Parent
	if p and p:IsA("BasePart") then return p.Position end
	if p and p:IsA("Attachment") then return p.WorldPosition end
	return nil
end
-- เป้าลูกศรของขั้นไก่: ป้ายของขั้นนั้น (ลานยังไม่ stream = ใช้ตำแหน่งลุงไข่ที่เซิร์ฟตั้งไว้)
local function chickenGoal(id)
	local pos = chickenPromptPos(chickenPrompt(CHICKEN_PROMPT[id] or "ShopPrompt"))
	if not pos then
		local p = ReplicatedStorage:GetAttribute("ChickenShopPos")
		pos = typeof(p) == "Vector3" and p or nil
	end
	return pos and pos - Vector3.new(0, 2, 0)
end
local function hasBroom()
	for _, t in ipairs(allTools()) do
		if t:GetAttribute("IsHeldBroom") then return true end
	end
	return false
end

-- ============ ตัวช่วยของขั้นอาหารสัตว์ ============
local function countPetFood()
	local n = 0
	for _, t in ipairs(allTools()) do
		if t:GetAttribute("IsPetFood") then n += t:GetAttribute("Count") or 1 end
	end
	return n
end
local function machinePos()
	local m = workspace:FindFirstChild("PetFoodMachine")
	if not m then return nil end
	local cf, size = m:GetBoundingBox()
	return cf.Position - Vector3.new(0, size.Y / 2, 0)
end
local function gachaPos()
	local m = workspace:FindFirstChild("GachaMachine")
	if not m then return nil end
	local cf, size = m:GetBoundingBox()
	return cf.Position - Vector3.new(0, size.Y / 2, 0)
end
local function normalTickets()
	return player:GetAttribute("GachaTickets_Normal") or 0
end

local function nearestPet()
	local root = rootPart()
	if not root then return nil end
	local best, bestD
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("OwnerUserId") == player.UserId and m:GetAttribute("PetId") then
			local d = (m:GetPivot().Position - root.Position).Magnitude
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	return best
end

-- ============ หน้าจอ ============
local gui = Instance.new("ScreenGui")
gui.Name = "TutorialGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local camera = workspace.CurrentCamera
local function fitScale(obj, w, h)
	local sc = Instance.new("UIScale"); sc.Parent = obj
	local function fit()
		local vp = camera.ViewportSize
		if vp.X > 2 then sc.Scale = math.clamp(math.min((vp.X - 24) / w, (vp.Y - 40) / h), 0.55, 1) end
	end
	fit()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	return sc
end

-- การ์ดภารกิจ
local card = Instance.new("Frame")
card.Name = "QuestCard"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -12, 0, 84)
card.Size = UDim2.new(0, 420, 0, 150) -- 2026-10-24: เดิม 400x92 → มีแถวปุ่มนำทาง/AUTO ด้านล่าง + ตัวหนังสือใหญ่ขึ้น (ผู้ใช้: ตัวเล็กอ่านยาก)
card.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
card.Visible = false
card.Parent = gui
corner(card, 16)
local cardStroke = Instance.new("UIStroke"); cardStroke.Thickness = 3; cardStroke.Color = GOLD; cardStroke.Parent = card
-- 2026-10-24 ผู้ใช้ขอย้ายการ์ดไปด้านขวา (เดิมกลางบน บังตัวละคร/ป้าย): ชิดขวาใต้แถวปุ่มมุมขวาบน เหนือปุ่มขี่สัตว์/วิ่ง (เริ่ม y ≈ 236) ทั้งจอปกติและจอเตี้ย
-- จอเตี้ย (มือถือแนวนอน): ย่อการ์ด 0.7 ชิดขวาใต้แถวปุ่มบน / จอปกติ: ขนาดเต็ม ชิดขวา
local COMPACT_HEIGHT = 500
local cardScale = Instance.new("UIScale"); cardScale.Parent = card
local function placeCard()
	local vp = camera.ViewportSize
	if vp.X < 2 then return end
	card.AnchorPoint = Vector2.new(1, 0)
	if vp.Y < COMPACT_HEIGHT then
		cardScale.Scale = 0.8 -- เดิม 0.7 ตัวหนังสือเล็กเกินบนมือถือ
		card.Position = UDim2.new(1, -12, 0, 62)
	else
		cardScale.Scale = math.clamp(math.min((vp.X - 24) / 420, (vp.Y - 40) / 300), 0.55, 1)
		card.Position = UDim2.new(1, -12, 0, 84)
	end
end
placeCard()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(placeCard)
local iconBack = Instance.new("Frame")
iconBack.Size = UDim2.new(0, 62, 0, 62)
iconBack.Position = UDim2.new(0, 12, 0.5, -31)
iconBack.BackgroundColor3 = Color3.fromRGB(255, 225, 140)
iconBack.Parent = card
corner(iconBack, 31)
local iconLabel = label(iconBack, "🛒", 32)
iconLabel.Size = UDim2.new(1, 0, 1, 0)
local stepLabel = label(card, "", 14, Color3.fromRGB(200, 130, 20), true)
stepLabel.Position = UDim2.new(0, 86, 0, 8)
stepLabel.Size = UDim2.new(1, -160, 0, 18)
stepLabel.TextXAlignment = Enum.TextXAlignment.Left
local titleLabel = label(card, "", 20, COLOR_TEXT, true)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Position = UDim2.new(0, 86, 0, 28)
titleLabel.Size = UDim2.new(1, -160, 0, 24)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
local textLabel = label(card, "", 15, COLOR_SUB)
textLabel.Position = UDim2.new(0, 86, 0, 54)
textLabel.Size = UDim2.new(1, -98, 0, 54)
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
local skipButton = button(card, tr("ข้าม", "Skip"), Color3.fromRGB(235, 228, 220), COLOR_SUB)
skipButton.Name = "SkipButton"
skipButton.TextSize = 14
skipButton.AnchorPoint = Vector2.new(1, 0)
skipButton.Position = UDim2.new(1, -10, 0, 8)
skipButton.Size = UDim2.new(0, 60, 0, 28)
local doneFlash = label(card, tr("✅ สำเร็จ!", "✅ Done!"), 26, Color3.fromRGB(60, 160, 70), true)
doneFlash.Font = Enum.Font.GothamBlack
doneFlash.Size = UDim2.new(1, 0, 1, 0)
doneFlash.BackgroundColor3 = Color3.fromRGB(225, 250, 225)
doneFlash.BackgroundTransparency = 0
doneFlash.ZIndex = 5
doneFlash.Visible = false
corner(doneFlash, 16)
local cardPop = Instance.new("UIScale"); cardPop.Parent = iconBack

-- หน้าต่างกลางจอ (ต้อนรับ / จบบทเรียน)
local popup = Instance.new("Frame")
popup.Name = "Popup"
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Position = UDim2.new(0.5, 0, 0.5, 0)
popup.Size = UDim2.new(0, 440, 0, 360)
popup.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
popup.Visible = false
popup.ZIndex = 10
popup.Parent = gui
corner(popup, 20)
local popStroke = Instance.new("UIStroke"); popStroke.Thickness = 4; popStroke.Color = Color3.new(1, 1, 1); popStroke.Parent = popup
local popGrad = Instance.new("UIGradient")
popGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 90)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 190, 90)),
})
popGrad.Parent = popStroke
fitScale(popup, 440, 360)
-- หน้าต่างใหญ่ของเกม (เครื่องทำอาหารสัตว์ / ร้าน / ตู้สุ่ม ฯลฯ) เปิดทับการ์ด = ให้การ์ดลงไปอยู่ใต้หน้าต่าง
-- (เดิมการ์ด DisplayOrder 9 ทับหน้าต่าง 8 บนมือถือบังปุ่มในหน้าต่าง) ปิดหน้าต่างแล้วการ์ดกลับขึ้นมาบนสุด
local BASE_ORDER = gui.DisplayOrder
local function windowCoversCard()
	local cp, cs = card.AbsolutePosition, card.AbsoluteSize
	for _, sg in ipairs(player.PlayerGui:GetChildren()) do
		-- ข้าม TouchGui ของ Roblox (กรอบใสเต็มจอของปุ่มบังคับบนมือถือ) และกรอบใสอื่นๆ นับเฉพาะหน้าต่างที่มีพื้นหลังจริง
		if sg:IsA("ScreenGui") and sg ~= gui and sg.Enabled and sg.Name ~= "TouchGui" then
			for _, f in ipairs(sg:GetChildren()) do
				if f:IsA("GuiObject") and f.Visible and f.BackgroundTransparency < 0.9 and f.AbsoluteSize.X >= 260 and f.AbsoluteSize.Y >= 200 then
					local p, s = f.AbsolutePosition, f.AbsoluteSize
					if p.X < cp.X + cs.X and cp.X < p.X + s.X and p.Y < cp.Y + cs.Y and cp.Y < p.Y + s.Y then return true end
				end
			end
		end
	end
	return false
end

-- แผงเงินย่อ/ขยายได้ (และโหลดทีหลัง) ตามไปอยู่ใต้แผงเสมอ + เช็กหน้าต่างทับการ์ด
task.spawn(function()
	local tick = 0
	while gui.Parent do
		task.wait(0.25)
		tick += 1
		if card.Visible and tick % 2 == 0 then placeCard() end
		local lower = card.Visible and not popup.Visible and windowCoversCard()
		gui.DisplayOrder = lower and 1 or BASE_ORDER
	end
end)
local popIcon = label(popup, "🌾", 54)
popIcon.Size = UDim2.new(1, 0, 0, 64)
popIcon.Position = UDim2.new(0, 0, 0, 10)
popIcon.ZIndex = 11
local popTitle = label(popup, "", 22, COLOR_TEXT, true)
popTitle.Font = Enum.Font.GothamBlack
popTitle.Size = UDim2.new(1, -30, 0, 30)
popTitle.Position = UDim2.new(0, 15, 0, 76)
popTitle.ZIndex = 11
local popText = label(popup, "", 14, COLOR_SUB)
popText.Size = UDim2.new(1, -40, 0, 180)
popText.Position = UDim2.new(0, 20, 0, 108)
popText.TextYAlignment = Enum.TextYAlignment.Top
popText.ZIndex = 11
local popMain = button(popup, "", Color3.fromRGB(120, 210, 110), Color3.new(1, 1, 1))
popMain.Name = "MainButton"
popMain.Size = UDim2.new(0, 190, 0, 44)
popMain.Position = UDim2.new(0.5, -150, 1, -60) -- เยื้องซ้าย เว้นที่ให้ปุ่มข้ามด้านขวา
popMain.TextSize = 17
popMain.ZIndex = 11
local popSkip = button(popup, tr("ข้ามบทเรียน", "Skip tutorial"), Color3.fromRGB(235, 228, 220), COLOR_SUB)
popSkip.Name = "SkipButton"
popSkip.Size = UDim2.new(0, 110, 0, 32)
popSkip.Position = UDim2.new(1, -124, 1, -54)
popSkip.TextSize = 12
popSkip.ZIndex = 11

-- ปุ่ม ❓ มุมขวาบน (แถวเดียวกับปุ่มอื่น ถัดจากสมุดปลา -224)
local helpButton = Instance.new("TextButton")
helpButton.Name = "HelpButton"
helpButton.Size = UDim2.new(0, 44, 0, 44)
helpButton.AnchorPoint = Vector2.new(1, 0.5)
helpButton.Position = UDim2.new(1, -276, 0, 34)
helpButton.BackgroundColor3 = Color3.fromRGB(255, 240, 200)
helpButton.Text = "❓"
helpButton.TextSize = 22
helpButton.Font = Enum.Font.GothamBold
helpButton.Selectable = false
helpButton.Visible = false -- ขึ้นเฉพาะตอนมีภารกิจค้างอยู่ (ทำครบแล้วหายไป มีภารกิจใหม่ค่อยกลับมา)
helpButton.Parent = gui
corner(helpButton, 22)
local helpStroke = Instance.new("UIStroke"); helpStroke.Color = Color3.fromRGB(140, 100, 65); helpStroke.Thickness = 2; helpStroke.Parent = helpButton

-- ============ ตัวชี้ทาง: เส้นแสง + ป้าย ⬇️ ============
local targetPart = Instance.new("Part")
targetPart.Name = "TutorialTarget"
targetPart.Anchored = true
targetPart.CanCollide = false
targetPart.CanQuery = false
targetPart.CanTouch = false
targetPart.Transparency = 1
targetPart.Size = Vector3.new(0.2, 0.2, 0.2)
local targetAttach = Instance.new("Attachment"); targetAttach.Parent = targetPart
-- 2026-10-18 ตัวชี้ทางระดับสายตา (ผู้ใช้ขอ: ไม่ให้อยู่ที่พื้น) ปลายเส้นแสงยกสูงจากพื้น TARGET_LIFT สตั๊ด ต้นเส้นอยู่ระดับอก
local TARGET_LIFT = 3
local beam = Instance.new("Beam")
beam.Attachment1 = targetAttach
beam.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 170, 60))
beam.Width0, beam.Width1 = 0.35, 0.35
beam.FaceCamera = true
beam.LightEmission = 1
beam.LightInfluence = 0
beam.Segments = 20
beam.CurveSize0 = 4
beam.CurveSize1 = -4
beam.Parent = targetPart
local marker = Instance.new("BillboardGui")
marker.Size = UDim2.new(0, 160, 0, 90)
marker.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0) -- เป้ายกสูง TARGET_LIFT แล้ว ป้าย ▼ อยู่เหนือพื้นราว 4.5 สตั๊ด (ระดับสายตา)
marker.AlwaysOnTop = false -- (AlwaysOnTop แล้วป้ายไม่ขึ้นเลย ทดสอบแล้ว)
marker.LightInfluence = 0
marker.Adornee = targetPart
marker.Enabled = false
marker.Parent = gui.Parent -- ป้ายโลก 3D ที่สคริปต์ฝั่งผู้เล่นสร้าง ต้องอยู่ใน PlayerGui (ใต้ Part ใน workspace ไม่ขึ้น)
local markerArrow = label(marker, "▼", 46, Color3.fromRGB(255, 205, 60), true)
local mas = Instance.new("UIStroke"); mas.Thickness = 3; mas.Color = Color3.fromRGB(120, 70, 10); mas.Parent = markerArrow
markerArrow.Size = UDim2.new(1, 0, 0, 50)
markerArrow.Position = UDim2.new(0, 0, 0, 36)
local markerText = label(marker, "", 15, Color3.new(1, 1, 1), true)
markerText.Size = UDim2.new(1, 0, 0, 30)
local mts = Instance.new("UIStroke"); mts.Thickness = 2; mts.Color = Color3.fromRGB(90, 60, 20); mts.Parent = markerText

-- ลูกศร 3D ลอยหน้าตัวผู้เล่นระดับสายตา ชี้ไปทางเป้าหมาย (อยู่ใน Camera = เห็นเฉพาะเรา) + ป้ายชื่อเป้า/ระยะทางเหนือลูกศร
local GUIDE_COLOR = Color3.fromRGB(255, 205, 60)
local guide = Instance.new("Model")
guide.Name = "TutorialGuideArrow"
local guideParts = {} -- { part, offset CFrame } หัวลูกศรชี้ -Z (ทิศ LookVector)
local function guidePart(size, offset)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = GUIDE_COLOR
	p.Size = size
	p.Parent = guide
	table.insert(guideParts, { p, offset })
	return p
end
local guideShaft = guidePart(Vector3.new(0.45, 0.45, 2.1), CFrame.new(0, 0, 0.75))
do
	local tip = Vector3.new(0, 0, -1)
	local len, ang = 1.5, math.rad(38)
	for _, s in ipairs({ -1, 1 }) do
		local dir = Vector3.new(s * math.sin(ang), 0, math.cos(ang)) -- จากปลายหัวเฉียงไปด้านหลัง
		local center = tip + dir * (len / 2)
		guidePart(Vector3.new(0.45, 0.45, len), CFrame.lookAt(center, center + dir))
	end
end
local guideLabel = Instance.new("BillboardGui")
guideLabel.Size = UDim2.new(0, 220, 0, 30)
guideLabel.StudsOffsetWorldSpace = Vector3.new(0, 1.3, 0)
guideLabel.AlwaysOnTop = false
guideLabel.LightInfluence = 0
guideLabel.Adornee = guideShaft
guideLabel.Enabled = false
guideLabel.Parent = gui.Parent
local guideText = label(guideLabel, "", 15, Color3.new(1, 1, 1), true)
guideText.Size = UDim2.new(1, 0, 1, 0)
local gts = Instance.new("UIStroke"); gts.Thickness = 2; gts.Color = Color3.fromRGB(90, 60, 20); gts.Parent = guideText
local guideTargetText = ""

local questHidden = false -- กด ❓ ระหว่างทำภารกิจ = ซ่อน/แสดงการ์ดและเส้นนำทาง (ภารกิจยังนับต่อ)
local goalPos -- เป้าล่าสุดของขั้นนี้ (บนพื้น) ปุ่ม 🧭/AUTO เดินไปที่นี่
local refreshNavButtons -- (นิยามในหัวข้อ "นำทาง + AUTO")
local function setTarget(pos, text)
	goalPos = pos
	if refreshNavButtons then refreshNavButtons() end
	if not pos or questHidden then
		targetPart.Parent = nil
		marker.Enabled = false
		guide.Parent = nil
		guideLabel.Enabled = false
		return
	end
	targetPart.Position = pos + Vector3.new(0, TARGET_LIFT, 0)
	markerText.Text = text or ""
	guideTargetText = text or ""
	targetPart.Parent = workspace
	marker.Enabled = true
	local root = rootPart()
	if root then
		local a0 = root:FindFirstChild("TutorialAttach") or Instance.new("Attachment")
		a0.Name = "TutorialAttach"
		a0.Position = Vector3.new(0, 1.2, 0) -- ระดับอก/สายตา (เดิม -1.5 = ติดพื้น)
		a0.Parent = root
		beam.Attachment0 = a0
	end
end

RunService.RenderStepped:Connect(function()
	if not targetPart.Parent then return end
	local t = os.clock()
	markerArrow.Position = UDim2.new(0, 0, 0, 36 + math.abs(math.sin(t * 4)) * -12)
	beam.Transparency = NumberSequence.new(0.15 + math.sin(t * 5) * 0.12)
	-- (Beam ไม่มี TextureOffset: ลายเลื่อนเองด้วย TextureSpeed) เดิมบรรทัดนี้ error ทุกเฟรม ทำให้โค้ดด้านล่างไม่เคยทำงาน
	-- ใกล้เป้าแล้ว ซ่อนเส้นและลูกศร เหลือแค่ป้าย ▼ ที่เป้า
	local root = rootPart()
	local flat = root and (targetPart.Position - root.Position) * Vector3.new(1, 0, 1)
	local far = flat ~= nil and flat.Magnitude > 9
	beam.Enabled = far
	if far then
		-- ลูกศรลอยหน้าตัว 3.2 สตั๊ด สูงระดับหัว ชี้ไปทางเป้า (เด้งเบาๆ ไปข้างหน้า)
		local dir = flat.Unit
		-- สูงเหนือหัวเล็กน้อย ไม่ให้สัตว์เลี้ยง/ตัวละครบัง
		local pos = root.Position + Vector3.new(0, 3.6 + math.sin(t * 3) * 0.15, 0) + dir * (3 + math.abs(math.sin(t * 4)) * 0.6)
		local base = CFrame.lookAt(pos, pos + dir)
		for _, item in ipairs(guideParts) do item[1].CFrame = base * item[2] end
		guide.Parent = workspace.CurrentCamera
		guideText.Text = guideTargetText .. string.format("  · %d ", math.floor(flat.Magnitude)) .. tr("ม.", "m")
		guideLabel.Enabled = true
	else
		guide.Parent = nil
		guideLabel.Enabled = false
	end
end)

-- ============ ขั้นตอน ============
local currentStep = 0
local stepToken = 0
local busy = false
local currentWater -- จุดน้ำที่ชี้ในขั้นตกปลา
local autoMode = false -- ▶ AUTO เปิดอยู่ (ทำทุกขั้นต่อกันจนกว่าผู้เล่นขยับเองหรือกดหยุด)
local startAutoStep, stopNav -- (นิยามในหัวข้อ "นำทาง + AUTO")
local popupHandler -- ปุ่มหลักของหน้าต่างกลางจอทำอะไร (เปลี่ยนตามหน้าต่าง)

local function stepData(step) return STEPS[step] end

local function showPopup(icon, title, text, mainText, showSkip, onMain)
	popIcon.Text = icon
	popTitle.Text = title
	popText.Text = text
	popMain.Text = mainText
	popSkip.Visible = showSkip
	popMain.Position = showSkip and UDim2.new(0.5, -150, 1, -60) or UDim2.new(0.5, -95, 1, -60) -- ไม่มีปุ่มข้าม = ปุ่มหลักอยู่กลาง
	popup.Visible = true
	local sc = popup:FindFirstChildOfClass("UIScale")
	local base = sc.Scale
	sc.Scale = base * 0.6
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = base }):Play()
	popupHandler = onMain
end
popMain.Activated:Connect(function()
	popup.Visible = false
	local h = popupHandler
	popupHandler = nil
	if h then h() end
end)

local function advance(step)
	if busy then return false end
	busy = true
	local ok, res = pcall(function() return request:InvokeServer("advance", step) end)
	busy = false
	if ok and res and res.ok then
		doneFlash.Visible = true
		task.delay(1.2, function() doneFlash.Visible = false end)
		if res.coreDone then
			-- จบขั้นหลัก 8 ขั้น = หน้ารับรางวัล แล้วทำภารกิจเสริม (ดูแลสัตว์) ต่อได้
			local waited = 0
			while (player:GetAttribute("GachaBusy") or player:GetAttribute("GachaRevealing")) and waited < 180 do waited += task.wait(0.2) end
			showPopup("🎉", tr("เก่งมาก! จบบทเรียนหลักแล้ว", "Great job! Tutorial complete"),
				(res.reward and res.reward > 0 and (tr("ได้รางวัล ", "You got ") .. REWARD_TEXT .. "!\n") or "")
				.. (res.boosterReward and tr("🍀 + หุ่นทองคำนำโชค (อยู่ในกระเป๋า ถือแล้วแตะพื้นเพื่อวาง ช่วยให้ผลผลิตดาวสูงขึ้น)\n", "🍀 + a Golden Lucky Scarecrow (in your bag: equip and tap the ground to place it for higher-star crops)\n") or "")
				.. (ChickenConfig.Enabled
					and tr("\nต่อไป: ภารกิจเสริม 9 ขั้น สอนทำอาหาร ป้อนสัตว์เลี้ยง (สัตว์หิว = ไม่ช่วยทำงาน) และเลี้ยงไก่ (ซื้อ ให้อาหาร กวาดเล้า เก็บไข่ ฟักไข่)", "\nNext: 9 bonus quests on making pet food, feeding your pet (hungry pets stop helping) and raising chickens (buy, feed, sweep, eggs, hatching)")
					or tr("\nต่อไป: ภารกิจเสริม 3 ขั้น สอนทำอาหารและป้อนสัตว์เลี้ยง (สัตว์หิว = ไม่ช่วยทำงาน)", "\nNext: 3 bonus quests on making pet food and feeding your pet (hungry pets stop helping)")),
				tr("ไปต่อ!", "Continue!"), false)
			return true
		end
		if res.step == 0 then
			setTarget(nil)
			card.Visible = false
			local waited = 0
			task.wait(0.3)
			-- รอจนผู้เล่นดูผลสุ่มแล้วกด "ตกลง" เอง (GachaGui ตั้ง GachaBusy ระหว่างสุ่ม) ไม่ปิดตู้ตัดหน้า
			while (player:GetAttribute("GachaBusy") or player:GetAttribute("GachaRevealing")) and waited < 180 do waited += task.wait(0.2) end
			if waited > 0 then task.wait(0.4) end
			-- ปิดหน้าต่างตู้สุ่มก่อน หน้าจบบทเรียนจะได้ไม่ซ้อน
			local gachaGui = player.PlayerGui:FindFirstChild("GachaGui")
			if gachaGui and gachaGui:IsA("ScreenGui") then gachaGui.Enabled = false end
			showPopup("🎉", tr("ครบทุกภารกิจแล้ว!", "All quests done!"),
				(res.reward and res.reward > 0 and (tr("ได้รางวัล ", "You got ") .. REWARD_TEXT .. "!\n\n") or "")
				.. (res.boosterReward and tr("\n🍀 หุ่นทองคำนำโชคอยู่ในกระเป๋า: ถือแล้วคลิก/แตะพื้นเพื่อวาง ช่วยเพิ่มโอกาสได้ผลผลิตดาวสูง (โชค x100) ในรัศมี 30 นาน 15 นาที ผู้เล่นใกล้ๆ ได้ผลด้วย", "\n🍀 Golden Lucky Scarecrow is in your Backpack. Equip and click/tap the ground to place it. Raises the chance of higher-star crops (Luck x100) within 30 studs for 15 minutes; nearby players benefit too.") or "")
				.. tr("💡 ต่อไปลองดู: ตู้สุ่มสัตว์เลี้ยง 🐾 · สมุดสะสมปลา 📖 · ร้านตกปลาริมทะเลสาบ 🎣\nมีภารกิจใหม่เมื่อไหร่ ปุ่ม ❓ จะกลับมาให้ทำต่อ", "💡 Next, try: the Pet Gacha 🐾 · the Fish Book 📖 · the Fishing Shop 🎣\nWhen there are new quests the ❓ button will come back"),
				tr("เล่นต่อเลย!", "Let's play!"), false)
		end
		return true
	end
	return false
end

-- เช็กว่าขั้นนี้เสร็จหรือยัง (วนทุก 0.5 วิ) + อัปเดตเป้าหมาย
local function runStep(step)
	stepToken += 1
	local token = stepToken
	local info = stepData(step)
	if not info then return end
	card.Visible = not questHidden
	iconLabel.Text = info.icon
	if step <= CORE_LAST then
		stepLabel.Text = string.format(tr("ขั้นที่ %d/%d · ครบรับ ", "Step %d/%d · Finish for "), step, CORE_LAST) .. REWARD_TEXT
	else
		stepLabel.Text = string.format(CHICKEN_PROMPT[info.id] and tr("ภารกิจเสริม %d/%d · บ้านไก่", "Bonus quest %d/%d · Chickens") or tr("ภารกิจเสริม %d/%d · ดูแลสัตว์เลี้ยง", "Bonus quest %d/%d · Pet care"), step - CORE_LAST, LAST_STEP - CORE_LAST)
	end
	titleLabel.Text = info.title
	textLabel.Text = info.text
	cardPop.Scale = 0.5
	TweenService:Create(cardPop, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	local id = info.id
	local baseSeeds, basePlant, baseProduce, baseCoins = countSeeds(), player:GetAttribute("PlantActionCount") or 0, countProduce(), coins()
	local baseFood = countPetFood()
	local stepStartAt = os.clock()
	-- ขั้นป้อน: นับว่าผ่านถ้าความอิ่มของสัตว์เพิ่มจากค่าต่ำสุดที่เคยเห็นในขั้นนี้ (2026-10-24 เดิมดูแค่จำนวนถุงในกระเป๋าลดลง อาหารไหลเข้าชาม/ทำเสร็จระหว่างนั้นแล้วไม่ผ่าน)
	local function hungerSum()
		local s = 0
		for k, v in pairs(player:GetAttributes()) do
			if type(v) == "number" and k:sub(1, 10) == "PetHunger_" then s += v end
		end
		return s
	end
	local minHunger = hungerSum()
	local baseTickets = normalTickets()
	local baseQueue, baseReady = player:GetAttribute("PetFoodQueue") or 0, player:GetAttribute("PetFoodReady") or 0
	local caught = false
	local completionDetected = false -- จดว่าทำสำเร็จแล้วไว้ retry ถ้าเซิร์ฟเวอร์เซฟขั้นไม่ผ่าน
	local fishConn
	if id == "fish" then
		fishConn = fishingState.OnClientEvent:Connect(function(state) if state == "caught" then caught = true end end)
	end
	local lastTargetUpdate = 0
	task.spawn(function()
		while stepToken == token and currentStep == step do
			local done = false
			if id == "buy" then
				done = countSeeds() > baseSeeds
			elseif id == "plant" then
				done = (player:GetAttribute("PlantActionCount") or 0) > basePlant
			elseif id == "harvest" then
				done = countProduce() > baseProduce
			elseif id == "sell" then
				done = baseProduce <= 0 or (countProduce() < baseProduce and coins() > baseCoins)
			elseif id == "foodInsert" then
				-- ใส่ผลผลิตแล้ว = คิวเพิ่ม (หรือเครื่องเร็วจนเสร็จไปแล้ว)
				done = (player:GetAttribute("PetFoodQueue") or 0) > baseQueue or (player:GetAttribute("PetFoodReady") or 0) > baseReady
			elseif id == "foodCollect" then
				done = countPetFood() > baseFood
			elseif id == "feed" then
				local h = hungerSum()
				if h < minHunger then minHunger = h end
				done = countPetFood() < baseFood or h > minHunger + 0.5
			elseif id == "chicken" then
				-- เปิดหน้าต่างไก่อันไหนก็ได้ (ร้าน/เล้า/ราง/แผงไข่) · ระบบไก่ปิดซ่อนอยู่ = ผ่านเลย
				local cg = player.PlayerGui:FindFirstChild("ChickenGui")
				done = not ChickenConfig.Enabled or (cg ~= nil and cg.Enabled)
			elseif id == "chickenBuy" then
				done = not ChickenConfig.Enabled or (chk.info ~= nil and #(chk.info.Chickens or {}) >= 1)
			elseif id == "chickenFeed" then
				done = not ChickenConfig.Enabled or (chk.info ~= nil and (chk.info.TroughBags or 0) >= 1)
			elseif id == "chickenBroom" then
				done = not ChickenConfig.Enabled or hasBroom()
			elseif id == "chickenEggs" or id == "chickenHatch" then
				done = not ChickenConfig.Enabled or (chk.openedAt[CHICKEN_MODE[id]] or 0) > stepStartAt
			elseif id == "petUse" then
				done = nearestPet() ~= nil -- ผ่านขั้นนี้เมื่อมีสัตว์ของเราอยู่ในโลก (พาออกมาแล้ว)
			elseif id == "fish" then
				done = caught
			elseif id == "gachaBuy" then
				done = normalTickets() > baseTickets
			elseif id == "gachaRoll" then
				-- ใช้สัญญาณจากเซิร์ฟเวอร์หลังสุ่มสำเร็จ; เช็กจำนวนตั๋วไว้รองรับเซิร์ฟเวอร์/ข้อมูลเก่า
				done = player:GetAttribute("TutorialGachaRollDone") == true or normalTickets() < baseTickets
			end
			if done then completionDetected = true end
			if completionDetected then
				if fishConn then fishConn:Disconnect(); fishConn = nil end
				if advance(step) then return end
				task.wait(2) -- ขั้นยังไม่ถูกเซฟ: คงสถานะสำเร็จไว้แล้วลองบันทึกซ้ำ
			end
			-- เป้าหมาย (อัปเดตเป็นระยะ ตัวละครเดินไปมา)
			if os.clock() - lastTargetUpdate > 2 then
				lastTargetUpdate = os.clock()
				if id == "buy" or id == "sell" then
					local p = shopPos()
					setTarget(p, info.mark)
				elseif id == "foodInsert" then
					setTarget(machinePos(), info.mark)
				elseif id == "gachaBuy" or id == "gachaRoll" then
					setTarget(gachaPos(), info.mark)
				elseif id == "foodCollect" then
					local ready = (player:GetAttribute("PetFoodReady") or 0) > 0
					setTarget(machinePos(), ready and tr("✅ เสร็จแล้ว! กด E รับอาหาร", "✅ Done! Press E to collect") or tr("⏳ เครื่องกำลังทำ...", "⏳ Machine working..."))
					textLabel.Text = ready and tr("อาหารสัตว์เสร็จแล้ว! กด E ที่เครื่อง แล้วกด \"รับอาหาร\"", "The pet food is ready! Press E at the machine and tap \"Collect\"") or info.text
				elseif id == "feed" then
					local pet = nearestPet()
					setTarget(pet and pet:GetPivot().Position - Vector3.new(0, 1, 0), info.mark)
				elseif id == "chicken" then
					-- ตำแหน่งลุงไข่ขายไก่ ChickenService ตั้งไว้ที่ ReplicatedStorage (ลานอาจยังไม่ stream มาตอนอยู่ไกล)
					local p = ReplicatedStorage:GetAttribute("ChickenShopPos")
					setTarget(typeof(p) == "Vector3" and p - Vector3.new(0, 2, 0) or nil, info.mark)
				elseif CHICKEN_PROMPT[id] and id ~= "chicken" then
					setTarget(chickenGoal(id), info.mark)
				elseif id == "petUse" then
					setTarget(nil)
				elseif id == "plant" then
					setTarget(nearestSoil(), info.mark)
				elseif id == "harvest" then
					myCrop = findMyCrop() -- ต้นที่โตแล้วมาก่อน (อันที่ชี้อยู่อาจยังไม่โต)
					if myCrop then
						local prompt = myCrop:FindFirstChildOfClass("ProximityPrompt")
						local ready = prompt and prompt.Enabled
						setTarget(myCrop.Position, ready and tr("✅ โตแล้ว! กด E เก็บ", "✅ Grown! Press E") or tr("⏳ กำลังโต...", "⏳ Growing..."))
						textLabel.Text = ready and tr("ต้นโตแล้ว! เดินไปกด E ค้างที่ต้นเพื่อเก็บเกี่ยว", "It's grown! Walk up and hold E on the plant to harvest") or info.text
					else
						setTarget(nil)
						textLabel.Text = tr("ไม่เจอต้นของคุณแถวนี้ ลองปลูกใหม่อีกต้น แล้วรอต้นโต", "Can't find your plant nearby. Plant another one and wait for it to grow")
					end
				elseif id == "fish" then
					if not currentWater or (rootPart() and (rootPart().Position - currentWater).Magnitude > 200) then
						currentWater = tutorialFishingWater()
					end
					setTarget(currentWater, info.mark)
				end
			end
			task.wait(0.5)
		end
		if fishConn then fishConn:Disconnect() end
	end)
	-- ขั้นเปลี่ยน: นำทางอย่างเดียว = หยุดเดินไปเป้าเก่า / AUTO = ทำขั้นใหม่ต่อเลย
	if autoMode then
		task.spawn(startAutoStep, step, token)
	elseif stopNav then
		stopNav()
	end
end

-- ============ นำทาง + AUTO (2026-10-24) ============
-- 🧭 นำทาง (หรือแตะการ์ด) = ตัวละครเดินไปเป้าของขั้นนั้นเอง (PathfindingService ข้ามสะพาน เลี่ยงน้ำ)
-- ▶ AUTO = เดินไป + ทำให้: ปลูก (ถือเมล็ดแล้วยิง PlantByClick ตัวเดียวกับคลิก) · เก็บ (กดป้าย E ของต้นเรา) · ตกปลา (หันหน้าหาน้ำแล้วถือเบ็ด = เหวี่ยงเอง)
--   ขั้นที่เป็นหน้าต่าง (ขาย/ซื้อ/ตู้สุ่ม/เครื่องอาหาร/ไก่) เดินไปแล้วกดป้าย E เปิดหน้าต่างให้ ปุ่มในหน้าต่างผู้เล่นกดเอง (ได้เรียนรู้)
--   ผู้เล่นขยับเอง (WASD/จอย/ปุ่มบังคับ) = หยุดทั้งนำทางและ AUTO · เดินไม่ถึง 3 รอบ หรือไกลเกิน WARP_DISTANCE = วาปไปที่เป้า
--   ใช้ remote/ป้ายเดิมที่ผู้เล่นใช้อยู่แล้ว เซิร์ฟเวอร์เช็กระยะ/โควต้าเหมือนเดิม · ใช้ได้เฉพาะตอนมีภารกิจบทเรียน (ไม่ใช่บอทฟาร์ม)
local PathfindingService = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local FarmGridConfig = require(ReplicatedStorage:WaitForChild("FarmGridConfig"))
local plantByClick = remoteEvents:WaitForChild("PlantByClick")
local WARP_DISTANCE = 180 -- ไกลกว่านี้วาปเลย ไม่เดิน
local AUTO_PLANT_MAX = 5 -- AUTO ปลูกทีละกี่ต้น (เมล็ดฟรี 5 ถุง โควต้าเริ่มต้น 10)

local navToken = 0
local navBusy = false -- กำลังเดินเองอยู่
local actionBusy = false -- AUTO กำลังปลูกชุดอยู่ (ขั้นปลูกผ่านตั้งแต่ต้นแรก ขั้นถัดไปต้องรอปลูกครบก่อนเดินออก)

local playerControls
task.spawn(function()
	local ps = player:WaitForChild("PlayerScripts", 10)
	local pm = ps and ps:WaitForChild("PlayerModule", 10)
	if pm then pcall(function() playerControls = require(pm):GetControls() end) end
end)
local function humanoid()
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end
local function flatDist(a, b)
	return ((a - b) * Vector3.new(1, 0, 1)).Magnitude
end
local function playerSteering()
	if not playerControls then return false end
	local ok, v = pcall(function() return playerControls:GetMoveVector() end)
	return ok and typeof(v) == "Vector3" and v.Magnitude > 0.2
end
local function faceToward(pos)
	local root = rootPart()
	if root then root.CFrame = CFrame.lookAt(root.Position, Vector3.new(pos.X, root.Position.Y, pos.Z)) end
end

-- ป้าย E ที่ขึ้นให้ผู้เล่นอยู่ตอนนี้ (อันที่กด E แล้วจะทำงาน)
local shownPrompt
-- shownSet = ป้ายทั้งหมดที่ขึ้นอยู่ตอนนี้ (2026-10-24: ป้าย E กับ F ขึ้นพร้อมกันได้ เช่นลุงไข่ E + อุ้มไก่ F แต่ shownPrompt เก็บแค่อันที่ขึ้นหลังสุด AUTO เลยพลาดกดป้ายที่ต้องการ)
local shownSet = {}
ProximityPromptService.PromptShown:Connect(function(p) shownPrompt = p shownSet[p] = true end)
ProximityPromptService.PromptHidden:Connect(function(p) shownSet[p] = nil if shownPrompt == p then shownPrompt = nil end end)
local function pressPrompt(prompt)
	if not (prompt and prompt.Parent and prompt.Enabled) then return false end
	if not pcall(function() prompt:InputHoldBegin() end) then return false end
	task.wait(prompt.HoldDuration + 0.15)
	pcall(function() prompt:InputHoldEnd() end)
	return true
end
local function promptPosition(prompt)
	local p = prompt.Parent
	if p and p:IsA("BasePart") then return p.Position end
	if p and p:IsA("Attachment") then return p.WorldPosition end
	if p and p:IsA("Model") then return p:GetPivot().Position end
	return nil
end
-- มีหน้าต่างใหญ่ของเกมเปิดอยู่แล้ว (ร้าน/ตู้สุ่ม ฯลฯ) = ไม่ต้องกดป้ายซ้ำ (เกณฑ์เดียวกับ windowCoversCard)
-- ป้ายที่ขึ้นอยู่ใกล้ pos ที่สุด (ไม่เกิน radius) ข้ามป้ายชื่อ skipName
local function shownNear(pos, radius, skipName)
	local best, bestD
	for p in pairs(shownSet) do
		if p.Parent and p.Enabled and p.Name ~= skipName then
			local pp = promptPosition(p)
			local d = pos and pp and (Vector3.new(pp.X, 0, pp.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
			if d and d <= radius and (not bestD or d < bestD) then best, bestD = p, d end
		end
	end
	return best
end
local function bigWindowOpen()
	for _, sg in ipairs(player.PlayerGui:GetChildren()) do
		if sg:IsA("ScreenGui") and sg ~= gui and sg.Enabled and sg.Name ~= "TouchGui" then
			for _, f in ipairs(sg:GetChildren()) do
				if f:IsA("GuiObject") and f.Visible and f.BackgroundTransparency < 0.9 and f.AbsoluteSize.X >= 260 and f.AbsoluteSize.Y >= 200 then return true end
			end
		end
	end
	return false
end

stopNav = function()
	navToken += 1
	local hum, root = humanoid(), rootPart()
	if navBusy and hum and root then hum:MoveTo(root.Position) end
	navBusy = false
	if refreshNavButtons then refreshNavButtons() end
end

local function warpTo(goal)
	local character, root = player.Character, rootPart()
	if not (character and root) then return end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
	local at = goal + Vector3.new(0, 3.5, 0)
	character:PivotTo(CFrame.lookAt(at, at + look.Unit))
end

-- เดินไปให้ห่างเป้า (แนวราบ) ไม่เกิน stopDist · คืน "arrived" / "steer" (ผู้เล่นขยับเอง) / "cancelled" / "failed"
local function walkTo(goal, stopDist)
	navToken += 1
	local token = navToken
	navBusy = true
	if refreshNavButtons then refreshNavButtons() end
	local function finish(result)
		if navToken == token then
			navBusy = false
			if refreshNavButtons then refreshNavButtons() end
		end
		return result
	end
	for _ = 1, 3 do
		local root, hum = rootPart(), humanoid()
		if not (root and hum and hum.Health > 0) then return finish("failed") end
		if flatDist(root.Position, goal) <= stopDist then return finish("arrived") end
		if flatDist(root.Position, goal) > WARP_DISTANCE then break end
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 6, Costs = { Water = 100 } })
		local ok = pcall(function() path:ComputeAsync(root.Position, goal) end)
		if navToken ~= token then return finish("cancelled") end
		local points = (ok and path.Status == Enum.PathStatus.Success) and path:GetWaypoints() or {}
		table.insert(points, { Position = goal, Action = Enum.PathWaypointAction.Walk }) -- ปิดท้ายด้วยเป้าจริง (หาทางไม่เจอ = เดินตรงไปเลย)
		local stuck = false
		local lastPos, movedAt = root.Position, os.clock()
		for i, wp in ipairs(points) do
			if i > 1 or flatDist(wp.Position, root.Position) > 2 then
				if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
				hum:MoveTo(wp.Position)
				local started = os.clock()
				while true do
					task.wait(0.1)
					if navToken ~= token then return finish("cancelled") end
					if playerSteering() then return finish("steer") end
					root = rootPart()
					if not root or hum.Health <= 0 then return finish("failed") end
					if flatDist(root.Position, goal) <= stopDist then
						hum:MoveTo(root.Position)
						return finish("arrived")
					end
					if flatDist(root.Position, wp.Position) < 2 then break end
					if (root.Position - lastPos).Magnitude > 0.8 then
						lastPos, movedAt = root.Position, os.clock()
					elseif os.clock() - movedAt > 1 then
						hum.Jump = true -- ติดขอบ/รั้วเตี้ยๆ ลองกระโดด
					end
					if os.clock() - movedAt > 3 or os.clock() - started > 7 then stuck = true break end
				end
			end
			if stuck then break end
		end
	end
	local root = rootPart()
	if root and flatDist(root.Position, goal) <= stopDist + 2 then return finish("arrived") end
	-- เดินไม่ถึง 3 รอบ / ไกลเกิน = วาปไปที่เป้าเลย (ผู้เล่นใหม่ไม่ต้องติดอยู่กับที่)
	if navToken ~= token then return finish("cancelled") end
	warpTo(goal)
	task.wait(0.3)
	return finish("arrived")
end

-- ---- ตัวช่วย AUTO ----
local function isSeed(t)
	return t:GetAttribute("CropType") and not t:GetAttribute("IsProduce") and not t:GetAttribute("IsBooster") and not t:GetAttribute("IsFishingRod")
end
local function isRod(t) return t:GetAttribute("IsFishingRod") == true end
-- ถือของที่ตรงเงื่อนไข (ถืออยู่แล้ว = ใช้อันนั้น)
local function equip(pred)
	local hum = humanoid()
	if not hum then return nil end
	local held = player.Character:FindFirstChildOfClass("Tool")
	if held and pred(held) then return held end
	for _, t in ipairs(allTools()) do
		if pred(t) then
			hum:EquipTool(t)
			task.wait(0.25)
			return t
		end
	end
	return nil
end

-- ปลูกในช่องว่างใกล้ตัว (ช่องที่มีต้น = มี PlantSlot<ลำดับ> อยู่ใต้ Soil) เว้นระยะต้นละ 3 สตั๊ด คืนจำนวนที่ส่งปลูก
local function autoPlant(soil)
	local root = rootPart()
	if not (soil and soil.Parent and root) then return 0 end
	local taken = {}
	for _, c in ipairs(soil:GetChildren()) do
		local idx = tonumber(c.Name:match("^PlantSlot(%d+)$"))
		if idx then taken[idx] = true end
	end
	local free = {}
	for i, offset in ipairs(FarmGridConfig.ComputeSlotOffsets(soil)) do
		if not taken[i] then
			local d = (FarmGridConfig.GetSlotWorldPosition(soil, offset) - root.Position).Magnitude
			if d <= 9 then table.insert(free, { offset = offset, d = d }) end
		end
	end
	table.sort(free, function(a, b) return a.d < b.d end)
	local picks = {}
	for _, f in ipairs(free) do
		if #picks >= AUTO_PLANT_MAX then break end
		local p = FarmGridConfig.GetSlotSurfacePoint(soil, f.offset)
		local spaced = true
		for _, q in ipairs(picks) do
			if (q - p).Magnitude < 3 then spaced = false break end
		end
		if spaced then table.insert(picks, p) end
	end
	local sent = 0
	for _, p in ipairs(picks) do
		if not autoMode then break end
		if not equip(isSeed) then break end
		faceToward(p)
		plantByClick:FireServer(soil, p)
		sent += 1
		task.wait(0.4)
	end
	return sent
end

-- ขั้นขาย/ซื้อ (2026-10-24 ผู้ใช้ขอให้ AUTO ขายให้เลย): ยิง remote ตัวเดียวกับปุ่มใน ShopGui
-- ขายเฉพาะผลผลิตข้าวสาลีที่ไม่ติดดาว (ที่ได้จากบทเรียน) ไม่ใช้ "ขายทั้งหมด" กันผู้เล่นเก่าที่เริ่มบทเรียนใหม่เสียผลผลิตที่เก็บไว้ทำอาหารสัตว์
-- ไม่มีข้าวสาลี = ขายผลผลิตอื่น 1 ชิ้น · ซื้อ = เมล็ดข้าวสาลี AUTO_BUY_SEEDS ถุง (เงินไม่พอ = 1 ถุง)
local sellCropRemote = remoteEvents:WaitForChild("SellCrop")
local buySeedRemote = remoteEvents:WaitForChild("BuySeed")
local AUTO_BUY_SEEDS = 5
local WHEAT_SEED_PRICE = 8 -- ต้องตรงกับราคาใน ShopSystem (ใช้แค่เลือกจำนวน เซิร์ฟเวอร์คิดเงินเอง)
local function autoShop(id)
	if id == "sell" then
		local sold = 0
		for _, t in ipairs(allTools()) do
			if t:GetAttribute("IsProduce") and t:GetAttribute("CropType") == "Wheat" and not t:GetAttribute("Starred") then
				sellCropRemote:FireServer("Wheat", t:GetAttribute("Star"), t:GetAttribute("Count") or 1)
				sold += 1
			end
		end
		if sold == 0 then
			for _, t in ipairs(allTools()) do
				if t:GetAttribute("IsProduce") and t:GetAttribute("CropType") and not t:GetAttribute("Starred") then
					sellCropRemote:FireServer(t:GetAttribute("CropType"), t:GetAttribute("Star"), 1)
					break
				end
			end
		end
	elseif id == "buy" then
		buySeedRemote:FireServer("Wheat", coins() >= WHEAT_SEED_PRICE * AUTO_BUY_SEEDS and AUTO_BUY_SEEDS or 1)
		-- ซื้อเสร็จปิดร้าน (เหมือนปุ่ม X ใน ShopGui) ไม่งั้นหน้าต่างค้างตอนเดินไปตกปลา และขั้นตู้สุ่มคิดว่ามีหน้าต่างเปิดอยู่แล้วเลยไม่เปิดตู้
		task.delay(1.5, function()
			local shop = player.PlayerGui:FindFirstChild("ShopGui")
			local frame = shop and shop:FindFirstChild("Frame")
			if frame and frame:IsA("GuiObject") then frame.Visible = false end
		end)
	end
end

-- ขั้นตู้สุ่ม (2026-10-24 ผู้ใช้ขอ): สั่ง GachaGui ผ่าน BindableEvent "TutorialAuto" (ทางเดียวกับปุ่ม ได้แอนิเมชันเปิดตัว)
-- ซื้อ = ตั๋วธรรมดา 1 ใบ (ใบแรกฟรี ไม่มีสิทธิ์ฟรี = เหรียญ) · สุ่ม = 1 ครั้ง · สั่งซ้ำเฉพาะตอนจำนวนตั๋วไม่เปลี่ยนใน 8 วิ (สูงสุด 3 รอบ) กันซื้อเกิน
local function autoGacha(id, alive)
	for _ = 1, 3 do
		local g = player.PlayerGui:FindFirstChild("GachaGui")
		local ev = g and g:FindFirstChild("TutorialAuto")
		local t = 0
		while not (g and g.Enabled and ev) and t < 4 and alive() do
			t += task.wait(0.3)
			g = player.PlayerGui:FindFirstChild("GachaGui")
			ev = g and g:FindFirstChild("TutorialAuto")
		end
		if not (g and g.Enabled and ev and alive()) then return end
		task.wait(1) -- ให้เห็นหน้าตู้ก่อน
		local before = normalTickets()
		ev:Fire(id == "gachaBuy" and "buy1" or "roll1")
		local w = 0
		while alive() and normalTickets() == before and w < 8 do w += task.wait(0.3) end
		if not alive() or normalTickets() ~= before then return end
	end
end

-- ขั้นทำอาหารสัตว์ (2026-10-24 AUTO เดิมแค่เปิดหน้าต่างเครื่อง ไม่ใส่/ไม่รับให้): ยิง PetFoodRequest ตัวเดียวกับปุ่มใน PetFoodGui
-- ใส่ = 1 ถุง จากผลผลิตที่ไม่ติดดาว (เซิร์ฟเวอร์ไม่ส่งกองที่ติดดาวมา) เลือกข้าวสาลีก่อน แล้วดาวต่ำสุด · รับ = รอถุงเสร็จแล้วกดรับ
local petFoodRequest = remoteEvents:WaitForChild("PetFoodRequest")
local function autoPetFood(id, alive)
	if id == "foodInsert" then
		local ok, res = pcall(function() return petFoodRequest:InvokeServer("info") end)
		local info = ok and res and res.info
		if not (info and alive()) then return end
		if (info.Queued or 0) > 0 or (info.ReadyTotal or 0) > 0 then return end -- มีของในเครื่องแล้ว
		local best
		for _, s in ipairs(info.Stacks) do
			if not s.IsFish and s.Count >= info.PerBag then
				local function rank(x) return (x.CropType == "Wheat" and 0 or 10) + x.Star end
				if not best or rank(s) < rank(best) then best = s end
			end
		end
		if not best then
			textLabel.Text = tr("AUTO: ไม่มีผลผลิตพอ (ต้อง 2 ชิ้นดาวเดียวกัน) เก็บเกี่ยวเพิ่มแล้วกด ▶ AUTO ใหม่", "AUTO: not enough produce (need 2 of the same star). Harvest more, then tap ▶ AUTO again")
			return
		end
		task.wait(1)
		if alive() then pcall(function() petFoodRequest:InvokeServer("insert", best.CropType, best.Star, 1) end) end
	elseif id == "foodCollect" then
		while alive() do
			local ok, res = pcall(function() return petFoodRequest:InvokeServer("info") end)
			if ok and res and res.info and (res.info.ReadyTotal or 0) > 0 and alive() then
				pcall(function() petFoodRequest:InvokeServer("collect") end)
				return
			end
			task.wait(2)
		end
	end
end

local setAuto
local autoRunId = 0 -- AUTO รอบล่าสุด (เริ่มใหม่ = รอบเก่าเลิกทำ ไม่แย่งกันสั่งเดิน)
-- AUTO ของขั้นนี้ (เรียกจาก runStep ตอนขั้นเปลี่ยน และตอนกดเปิด AUTO) ขั้นผ่านแล้ว runStep เรียกขั้นถัดไปเอง
startAutoStep = function(step, token)
	local info = stepData(step)
	if not info then return end
	autoRunId += 1
	local myRun = autoRunId
	local function alive()
		return autoMode and myRun == autoRunId and currentStep == step and stepToken == token
	end
	while (popup.Visible or actionBusy) and alive() do task.wait(0.3) end
	task.wait(0.6) -- ให้ลูปขั้นตอนหาเป้าก่อน (goalPos)
	if not alive() then return end
	local id = info.id
	local function go(pos, dist)
		if not pos then return false end
		local r = walkTo(pos, dist)
		if r == "steer" then setAuto(false, true) end
		return r == "arrived" and alive()
	end
	if id == "plant" then
		-- ปลูกไม่ได้ (ไม่มีเมล็ด/ช่องเต็ม/สัตว์เลี้ยงเอาเมล็ดไปปลูกก่อน) = บอกบนการ์ด แล้วลองใหม่ทุก 3 วิ (ปลูกได้ต้นแรก = ขั้นผ่าน ลูปจบเอง)
		while alive() do
			local pos, soil = nearestSoil()
			if not go(pos, 2) then break end
			actionBusy = true
			local ok, sent = pcall(autoPlant, soil)
			actionBusy = false
			if ok and sent == 0 and alive() then
				textLabel.Text = tr("AUTO: ไม่มีเมล็ดหรือช่องว่างแถวนี้ มีเมล็ดเมื่อไหร่จะปลูกให้เอง (หรือกดช่อง 1 แล้วคลิกดิน)", "AUTO: no seeds or free spots here. It will plant as soon as you have seeds (or tap slot 1 and click the soil)")
			end
			task.wait(3)
		end
	elseif id == "harvest" then
		while alive() do
			local crop = findMyCrop() -- หาใหม่ทุกรอบ: ต้นที่โตแล้วก่อน
			local prompt = crop and crop:FindFirstChildOfClass("ProximityPrompt")
			if prompt and prompt.Enabled and go(crop.Position, 1.5) then
				-- InputHoldBegin ใช้ได้เฉพาะป้ายที่ Roblox แสดงอยู่ (ปุ่ม E แสดงทีละป้าย) ทดสอบ 2026-10-24
				-- ยืนทับต้นแล้วป้ายที่แสดงเป็นต้นของเราต้นไหนก็ได้ = กดอันนั้น
				faceToward(crop.Position)
				local t = 0
				while t < 1.5 and not (shownPrompt and shownPrompt.Parent and shownPrompt.Parent:GetAttribute("OwnerUserId") == player.UserId) do t += task.wait(0.2) end
				local target = shownPrompt
				if target and target.Parent and target.Parent:GetAttribute("OwnerUserId") == player.UserId then pressPrompt(target) end
			end
			task.wait(1) -- รอต้นโต (ป้าย E ขึ้นตอนโตครบเท่านั้น)
		end
	elseif id == "fish" then
		local spot = tutorialFishingWater()
		if go(spot, 1.5) then
			-- หันหน้าหาน้ำ (จุดบทเรียน = น้ำอยู่ทาง +X) แล้วถือเบ็ดใหม่ = FishingClient เหวี่ยงให้เอง
			local water = (spot == TUTORIAL_FISH_SPOT) and (spot + Vector3.new(10, 0, 0)) or nearestWater()
			while alive() do
				if water then faceToward(water) end
				local hum = humanoid()
				if hum then hum:UnequipTools() end
				task.wait(0.3)
				if not equip(isRod) then
					textLabel.Text = tr("AUTO: ไม่เจอเบ็ด เปิดกระเป๋า 🎒 แล้วกด \"ใช้\" ที่เบ็ด", "AUTO: no rod found. Open your bag 🎒 and tap \"Use\" on a rod")
					break
				end
				-- รอปลาติด (ตกออโต้) นานเกิน 90 วิ = ถือเบ็ดใหม่เผื่อเหวี่ยงไม่ออก
				local waited = 0
				while waited < 90 and alive() do
					if playerSteering() then setAuto(false, true) break end
					waited += task.wait(0.5)
				end
			end
		end
	elseif CHICKEN_PROMPT[id] then
		-- 2026-10-24 ภารกิจบ้านไก่: เดินไปที่ป้ายของขั้น กดป้าย E (เปิดหน้าต่างให้เห็น) แล้วสั่ง ChickenRequest แทนปุ่มในหน้าต่าง (ซื้อไก่ / เทอาหารลงราง / หยิบไม้กวาด) ลองซ้ำทุก 2 วิ จนขั้นผ่าน
		local tries = 0
		while alive() and tries < 12 do
			tries += 1
			local prompt = chickenPrompt(CHICKEN_PROMPT[id])
			local pos = chickenPromptPos(prompt) or goalPos
			if go(pos, 3.5) and alive() then
				prompt = chickenPrompt(CHICKEN_PROMPT[id]) or prompt
				-- หน้าต่างไก่ขั้นก่อนยังเปิดอยู่ = ปิดก่อน ไม่งั้นกดป้ายขั้นนี้แล้วหน้าต่างใหม่ไม่ขึ้นให้เห็น
				local cg = player.PlayerGui:FindFirstChild("ChickenGui")
				if cg and cg:IsA("ScreenGui") and cg.Enabled then cg.Enabled = false task.wait(0.3) end
				if prompt and prompt.Enabled and not bigWindowOpen() then
					local t = 0
					while not shownSet[prompt] and t < 3 and alive() do t += task.wait(0.2) end
					if shownSet[prompt] and alive() then pressPrompt(prompt) end
				end
				task.wait(1)
				local i = chk.info or {}
				local action, arg
				if id == "chickenBuy" and #(i.Chickens or {}) == 0 then action = "buyChicken"
				elseif id == "chickenFeed" and (i.TroughBags or 0) == 0 then action, arg = "deposit", 0
				elseif id == "chickenBroom" and not hasBroom() then action = "takeBroom" end
				if action and chk.req and alive() then
					local ok, res = pcall(function() return chk.req:InvokeServer(action, arg) end)
					if ok and type(res) == "table" then
						if res.info and res.info.Loaded then chk.info = res.info end
						if res.ok == false and res.message and alive() then textLabel.Text = "AUTO: " .. res.message end
					end
				end
			end
			task.wait(2)
		end
	elseif id == "petUse" or id == "feed" then
		-- ขั้นนี้ทำผ่านเมนู/กด F กับสัตว์เลี้ยง ผู้เล่นทำเอง (ป้อนอาหาร = เดินไปหาสัตว์ให้)
		if id == "feed" then
			-- 2026-10-24: ถืออาหารสัตว์ เดินไปหาสัตว์ แล้วกดป้าย F ที่ขึ้นใกล้สัตว์ให้ (ลองซ้ำทุก 2 วิ จนขั้นผ่าน)
			local tries = 0
			while alive() and tries < 8 do
				tries += 1
				if not equip(function(t) return t:GetAttribute("IsPetFood") == true end) then
					textLabel.Text = tr("AUTO: ไม่เจออาหารสัตว์ในกระเป๋า ทำอาหารสัตว์ก่อน แล้วกด ▶ AUTO ใหม่", "AUTO: no pet food in your bag. Make some first, then tap ▶ AUTO again")
					break
				end
				if go(goalPos, 3) then
					local t = 0
					local sp = goalPos and shownNear(goalPos, 12)
					while not sp and t < 2 and alive() do
						t += task.wait(0.2)
						sp = goalPos and shownNear(goalPos, 12)
					end
					if sp and alive() then pressPrompt(sp) end
				end
				task.wait(2)
			end
		end
	else
		-- ขั้นหน้าต่าง: เดินไปแล้วกดป้าย E ที่ขึ้นอยู่ใกล้เป้าให้ (หน้าต่างเปิดอยู่แล้ว เช่นขายเสร็จต่อซื้อ = ไม่กดซ้ำ)
		local waited = 0
		while not goalPos and waited < 4 and alive() do waited += task.wait(0.3) end
		local pos = goalPos
		local arrived = go(pos, 5)
		if arrived and not bigWindowOpen() then
			local t = 0
			while not shownPrompt and t < 2 do t += task.wait(0.2) end
			local pp = shownPrompt and promptPosition(shownPrompt)
			if pp and flatDist(pp, pos) < 20 and alive() then pressPrompt(shownPrompt) end
		end
		if arrived and (id == "sell" or id == "buy") then
			task.wait(1.2) -- ให้เห็นหน้าร้านก่อนขาย/ซื้อ
			if alive() then autoShop(id) end
		elseif arrived and (id == "gachaBuy" or id == "gachaRoll") then
			autoGacha(id, alive)
		elseif arrived and (id == "foodInsert" or id == "foodCollect") then
			autoPetFood(id, alive)
		end
	end
end

setAuto = function(on, byPlayer)
	autoMode = on
	if not on then
		stopNav()
		if byPlayer and currentStep > 0 then
			textLabel.Text = tr("⏸ หยุด AUTO แล้ว (คุณขยับเอง) · กด ▶ AUTO เพื่อให้ทำต่อ", "⏸ AUTO stopped (you moved) · tap ▶ AUTO to continue")
		end
	end
	refreshNavButtons()
	if on and currentStep > 0 then task.spawn(startAutoStep, currentStep, stepToken) end
end

-- ปุ่มบนการ์ด (แถวล่าง) + แตะตรงไหนก็ได้บนการ์ด = นำทาง
local cardTap = Instance.new("TextButton")
cardTap.Name = "CardTap"
cardTap.Text = ""
cardTap.BackgroundTransparency = 1
cardTap.Size = UDim2.fromScale(1, 1)
cardTap.ZIndex = 0 -- ใต้ปุ่มอื่นบนการ์ด (ข้าม / นำทาง / AUTO ได้คลิกก่อน)
cardTap.Selectable = false
cardTap.Parent = card
local navButton = button(card, "", Color3.fromRGB(255, 236, 190))
navButton.Name = "NavButton"
navButton.TextSize = 16
navButton.Position = UDim2.new(0, 86, 0, 112)
navButton.Size = UDim2.new(0, 130, 0, 30)
local autoButton = button(card, "", GOLD)
autoButton.Name = "AutoButton"
autoButton.TextSize = 16
autoButton.Position = UDim2.new(0, 224, 0, 112)
autoButton.Size = UDim2.new(0, 180, 0, 30)
local autoStroke = Instance.new("UIStroke"); autoStroke.Thickness = 2; autoStroke.Color = Color3.fromRGB(200, 130, 20); autoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; autoStroke.Parent = autoButton
refreshNavButtons = function()
	local moving = navBusy or autoMode
	navButton.Text = moving and tr("⏹ หยุด", "⏹ Stop") or tr("🧭 นำทาง", "🧭 Guide me")
	navButton.Visible = moving or goalPos ~= nil
	autoButton.Text = autoMode and tr("🤖 AUTO กำลังทำ...", "🤖 AUTO running...") or tr("▶ AUTO ทำให้เลย", "▶ AUTO do it")
	autoButton.BackgroundColor3 = autoMode and Color3.fromRGB(110, 200, 120) or GOLD
	autoButton.Position = UDim2.new(0, navButton.Visible and 224 or 86, 0, 112)
end
refreshNavButtons()
local function onNav()
	if navBusy or autoMode then
		setAuto(false)
		return
	end
	if goalPos then task.spawn(walkTo, goalPos, 4) end
end
navButton.Activated:Connect(onNav)
cardTap.Activated:Connect(function()
	if not (navBusy or autoMode) then onNav() end -- แตะการ์ดตอนกำลังเดิน = ไม่หยุด (กันแตะพลาด) หยุดด้วยปุ่ม ⏹
end)
autoButton.Activated:Connect(function() setAuto(not autoMode) end)
-- ตาย/เกิดใหม่ระหว่าง AUTO: เริ่มขั้นเดิมต่อจากตัวใหม่
player.CharacterAdded:Connect(function()
	if autoMode and currentStep > 0 then
		task.wait(1.5)
		if autoMode then task.spawn(startAutoStep, currentStep, stepToken) end
	end
end)

local welcomed = false
local function onStepChanged()
	local step = player:GetAttribute("TutorialStep")
	if step == nil then return end
	helpButton.Visible = step > 0 and step <= LAST_STEP
	if step == 0 or step > LAST_STEP then
		currentStep = 0
		stepToken += 1
		autoMode = false
		if stopNav then stopNav() end
		card.Visible = false
		setTarget(nil)
		return
	end
	if step == currentStep then return end
	currentStep = step
	if player:GetAttribute("TutorialNewQuests") and not welcomed then
		-- จบบทเรียนไปแล้ว แต่เกมเพิ่มภารกิจใหม่ = แจ้งแล้วทำต่อจากขั้นใหม่
		-- 2026-10-25 ภารกิจบ้านไก่สำหรับผู้เล่นเก่า (TutorialService เสนอ 1 ครั้ง) · รอประกาศตอนเข้าเกม (LoginAnnouncementGui) ปิดก่อน ไม่เด้งทับกัน
		welcomed = true
		card.Visible = false
		local chickenQuest = step >= 12
		local title = chickenQuest and tr("มีภารกิจใหม่: ฟาร์มไก่! 🐔", "New quests: Chicken Farm! 🐔") or tr("มีภารกิจใหม่!", "New quests!")
		local body = chickenQuest
			and tr("ฟาร์มไก่เปิดแล้ว! มาเรียนเลี้ยงไก่กัน 6 ขั้นสั้นๆ\n🐔 ซื้อไก่ → 🥣 เติมอาหาร → 🧹 กวาดเล้า → 🥚 เก็บไข่ → 🐣 ฟักไข่\nไข่ออกเองแม้ออกเกม สะสมไก่ครบสมุดรับ 1,000,000 เหรียญ!\nกดปุ่ม ❓ มุมขวาบนเพื่อซ่อน/แสดงการ์ดภารกิจ",
				"The Chicken Farm is open! Learn to raise chickens in 6 short steps\n🐔 Buy → 🥣 Feed → 🧹 Clean → 🥚 Eggs → 🐣 Hatch\nChickens lay even while you're offline; complete the book for 1,000,000 coins!\nTap the ❓ button at the top right to hide/show the quest card")
			or string.format(tr("เกมเพิ่มภารกิจใหม่ ทำต่อจากขั้นที่ %d/%d ได้เลย\nกดปุ่ม ❓ มุมขวาบนเพื่อซ่อน/แสดงการ์ดภารกิจ", "New quests were added, continue from step %d/%d\nTap the ❓ button at the top right to hide/show the quest card"), step, LAST_STEP)
		task.spawn(function()
			local waitUntil = os.clock() + 90
			while player.PlayerGui:FindFirstChild("LoginAnnouncementGui") and os.clock() < waitUntil do task.wait(0.5) end
			if currentStep ~= step then return end -- ระหว่างรอขั้นเปลี่ยนไปแล้ว (เช่น กดข้าม)
			showPopup(chickenQuest and "🐔" or "✨", title, body, tr("ไปเลย!", "Go!"), true, function() runStep(step) end)
		end)
	elseif false then -- 2026-10-18 เอาหน้าต่างต้อนรับ "เริ่มเลย/ข้าม" ออก (คนกดข้ามทันทีเยอะ) การ์ดภารกิจขึ้นทันที ปุ่มข้ามอยู่บนการ์ด
		welcomed = true
		card.Visible = false
		showPopup("🌾", tr("ยินดีต้อนรับสู่ฟาร์ม!", "Welcome to the farm!"),
			tr("มาเรียนวิธีเล่นกัน 12 ขั้นสั้นๆ\n🛒 ซื้อเมล็ด → 🌱 ปลูก → 🌾 เก็บเกี่ยว → 💰 ขาย\n→ 🥫 ทำ/รับอาหาร → 🎣 ตกปลา → 🎰 สุ่มสัตว์\n→ 🐾 พาสัตว์ออกมาใช้ → 🍖 ให้อาหาร\n\nทำครบรับ ", "Let's learn the game in 12 short steps\n🛒 Buy seeds → 🌱 Plant → 🌾 Harvest → 💰 Sell\n→ 🥫 Make/collect food → 🎣 Fish → 🎰 Roll for a pet\n→ 🐾 Bring it out and use it → 🍖 Feed it\n\nFinish it all to get ") .. REWARD_TEXT .. tr(" + ตั๋วสุ่มฟรี! (กดข้ามก็รับเหรียญเช่นกัน)", " + a free gacha ticket! (Skipping gives you the coins too)"),
			tr("เริ่มเลย!", "Let's go!"), true, function() runStep(step) end)
	else
		runStep(step)
	end
end
player:GetAttributeChangedSignal("TutorialStep"):Connect(onStepChanged)
task.defer(onStepChanged)

local function skip()
	popup.Visible = false
	popupHandler = nil
	pcall(function() request:InvokeServer("skip") end)
end
skipButton.Activated:Connect(skip)
popSkip.Activated:Connect(skip)
-- เมนูเพิ่มเติม (MoreMenuGui) ยิง OpenTutorial: กำลังทำอยู่ = ซ่อน/แสดงการ์ดภารกิจ (เหมือน ❓) / จบหรือข้ามไปแล้ว = เริ่มบทเรียนใหม่
-- (ผู้เล่นเก่าที่เคยกดข้ามกลับมาทำให้ครบได้ ถ้ายังไม่เคยได้รางวัล 100,000 เหรียญ จะได้ตอนทำครบ)
local openTutorialEvent = Instance.new("BindableEvent")
openTutorialEvent.Name = "OpenTutorial"
openTutorialEvent.Parent = gui
openTutorialEvent.Event:Connect(function()
	if currentStep > 0 then
		questHidden = not questHidden
		helpButton.BackgroundColor3 = questHidden and Color3.fromRGB(255, 205, 90) or Color3.fromRGB(255, 240, 200)
		card.Visible = not questHidden
		if questHidden then setTarget(nil) end
	else
		questHidden = false
		pcall(function() request:InvokeServer("restart") end) -- เซิร์ฟเวอร์ตั้งขั้น 1 แล้ว Attribute TutorialStep เปลี่ยน หน้าจอเริ่มเอง
	end
end)
-- ❓ ระหว่างทำภารกิจ: ซ่อน/แสดงการ์ดภารกิจ + เส้นนำทาง (ไม่เริ่มใหม่ ความคืบหน้าไม่หาย)
helpButton.Activated:Connect(function()
	if currentStep <= 0 then return end
	questHidden = not questHidden
	helpButton.BackgroundColor3 = questHidden and Color3.fromRGB(255, 205, 90) or Color3.fromRGB(255, 240, 200)
	card.Visible = not questHidden
	if questHidden then setTarget(nil) end -- แสดงอีกครั้ง: เส้นนำทางกลับมาเองในรอบอัปเดตถัดไป
end)

-- ============ จอย: ป๊อปอัปต้อนรับ/จบบทเรียน ============
-- ขึ้นมาตอนใช้จอย = เลือกปุ่มหลัก (เริ่มเลย / เล่นต่อเลย) ให้เลย · ◀▶ ไปปุ่ม "ข้ามบทเรียน" · A กด
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
popup.SelectionGroup = true
popup.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
popup.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
popup.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
popup.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
popup:GetPropertyChangedSignal("Visible"):Connect(function()
	local sel = GuiService.SelectedObject
	if popup.Visible then
		if UserInputService:GetLastInputType().Name:find("Gamepad") then
			task.defer(function() if popup.Visible then GuiService.SelectedObject = popMain end end)
		end
	elseif sel and sel:IsDescendantOf(popup) then
		GuiService.SelectedObject = nil
	end
end)
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.fromScale(1, 1)
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = selectBox
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 190, 40); st.Thickness = 3.5; st.Parent = selectBox
end
for _, b in ipairs({ popMain, popSkip, skipButton, navButton, autoButton }) do b.SelectionImageObject = selectBox end
