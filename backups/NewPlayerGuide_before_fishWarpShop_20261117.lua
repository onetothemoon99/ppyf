-- Backup (full Source) of game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide before the fish-lesson warp button / shop highlight / sell-caught-fish change, 2026-11-17
-- Restore: paste everything below this header over the script's Source in Studio.
-- NewPlayerGuide (2026-11-13 ผู้ใช้ขอ "ทำลูกศร 3 ขั้น"): นำทางผู้เล่นใหม่ ซื้อเมล็ด → ปลูก → เก็บ → ขาย → ไปหาหุ่นนกฮูก (ขั้นนกฮูกเพิ่มวันเดียวกัน · ขั้นซื้อเมล็ดเพิ่ม 2026-11-15)
--   4 หุ่นนกฮูก = หน้าต่างบทเรียน (PlayerGui.LessonNpcGui ของสคริปต์ LessonNpcGui) ถูกเปิด · เป้า = Workspace.GuideNPC · ไม่มี GuideNPC = ข้ามขั้นนี้
-- นำทางไปจุดเดียว ("พาไป" ของบทเรียน): BindableEvent NewPlayerGuideGui.GuideTo:Fire({ pos = Vector3, title, text, mark, arriveDist?, doneText?, stay? }) ถึงจุดแล้วจบเอง
-- เสียงสำเร็จ (2026-11-14 ผู้ใช้สั่ง "เพิ่มเสียงตอนทำสำเร็จทุกอัน"): ผ่านขั้น/ถึงจุด = เสียงติ๊ง · จบบทเรียน (finish / GuideTo big = true) = เสียงเลเวลอัป
--   สคริปต์อื่นเล่นได้ด้วย BindableEvent NewPlayerGuideGui.PlaySuccess:Fire(big?) (LessonNpcGui ใช้ตอนตกปลาได้ / รับรางวัล)
--   stay = true (2026-11-14 บทตกปลาต่อกัน): ถึงจุดแล้วการ์ด doneText ค้างไว้ ไม่ซ่อนเอง จนกว่าจะมี GuideTo/StartGuide ใหม่ หรือกด X (ผู้เรียกส่งขั้นต่อไปเอง)
-- ทำงานฝั่งเครื่องผู้เล่นอย่างเดียว: ไม่มีเซิร์ฟเวอร์ / DataStore / รางวัล · ไม่เกี่ยวกับ TutorialService / TutorialGui เดิม (ปิดถาวร 2026-11-01)
-- เริ่มเอง: ผู้เล่นใหม่ (Attribute IsNewPlayer จาก LeaderstatsSetup = บัญชีที่ยังไม่มีข้อมูลเหรียญ มีแค่รอบแรกที่เข้าเกม) หลังเข้า AUTO_START_DELAY วิ
-- เริ่มเองได้ทุกคน: ปุ่ม "เริ่มนำทาง" ในแผงวิธีเล่น (HowToPlayGui) ยิง BindableEvent NewPlayerGuideGui.StartGuide · กด X บนการ์ด = หยุด
-- สิ่งที่แสดง: การ์ดมุมขวาบน (ขั้น n/3 + สิ่งที่ต้องทำ + ระยะ) · เส้นทองจากตัวผู้เล่นไปเป้าหมาย (Beam) · ลูกศร ▼ เด้งเหนือเป้าหมายพร้อมป้ายชื่อ
-- ตรวจว่าผ่านขั้น (ทุก 0.3 วิ):
--   1 ปลูก  = Attribute PlantCount เพิ่มจากตอนเริ่มขั้น · เป้า = จุดบนแปลงดิน (FarmPlots ... Soil) ที่ใกล้ผู้เล่นที่สุด
--   2 เก็บ  = PlantCount ลดลงจากค่าสูงสุดที่เห็นในขั้นนี้ · เป้า = ต้นของเรา (Soil.PlantSlot<n> ที่ OwnerUserId = เรา ต้นที่โตแล้วมาก่อน)
--   3 ขาย  = เหรียญ (leaderstats "เหรียญ") เพิ่มจากตอนเริ่มขั้น · เป้า = พื้นหน้าร้านเมล็ด (workspace.Shops.Shop)
-- ข้อควรรู้: บัญชีที่มีสัตว์เลี้ยงช่วยปลูก/เก็บ ขั้น 1-2 อาจผ่านเอง (PlantCount นับของสัตว์ด้วย) · เหรียญที่เพิ่มจากทางอื่นในขั้น 3 ก็นับผ่าน
-- เกร็ดจากบทเรียนเดิม: BillboardGui ที่สร้างฝั่งเครื่องต้องอยู่ใน PlayerGui + ตั้ง Adornee · AlwaysOnTop = true ทำให้ไม่แสดงในเกมนี้ · ใช้ตัวอักษร "▼" แทนอิโมจิ
-- ทดสอบใน Studio: ตอน Play ตั้ง Attribute IsNewPlayer = true บนผู้เล่นฝั่ง Client (เริ่มเอง) หรือกดปุ่ม "เริ่มนำทาง" ในแผง "?"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 2026-11-14: ระบบสอนเล่นปิด (LessonConfig.DEV_ONLY บนเซิร์ฟจริง) = ไม่มีลูกศรนำทาง ไม่เริ่มเองกับผู้เล่นใหม่ (ไม่มีโมดูล/โหลดไม่ได้ = ปิดด้วย)
do
	local module = ReplicatedStorage:WaitForChild("LessonConfig", 10)
	local ok, config = pcall(function() return module and require(module) end)
	if not (ok and type(config) == "table" and config.ENABLED) then return end
end

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local function tr(th, en)
	return Localization.Pick(Localization.GetLanguage(player), th, en)
end

local AUTO_START_DELAY = 4 -- วินาทีหลังรู้ว่าเป็นผู้เล่นใหม่ แล้วเริ่มนำทางเอง
local CHECK_INTERVAL = 0.3
local FINISH_SHOW_TIME = 7 -- วินาทีที่การ์ด "เก่งมาก" ค้างไว้หลังจบ
local STEP_SOUND_ID = "rbxassetid://135847024228435" -- steam-achievement (มีในเกมแล้ว WishingPondGui/RestartNoticeGui) ผ่านขั้น
local FINISH_SOUND_ID = "rbxassetid://371274037" -- เสียงเลเวลอัป (LevelGui) จบบทเรียน / รับรางวัล

local COLOR_BG = Color3.fromRGB(255, 250, 245)
local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
local COLOR_SUB = Color3.fromRGB(130, 100, 90)
local COLOR_BORDER = Color3.fromRGB(140, 100, 65)
local COLOR_GOLD = Color3.fromRGB(255, 205, 80)

-- ข้อความของแต่ละขั้น (แก้ได้ที่นี่ที่เดียว)
-- 2026-11-15 ผู้ใช้สั่ง: ขั้นแรก = ซื้อเมล็ด (ผู้เล่นใหม่ไม่มีเมล็ดติดตัว เดิมขั้นปลูกทำไม่ได้) · เริ่มตอนมีเมล็ดอยู่แล้ว = ข้ามไปขั้นปลูก
--   ผ่านเมื่อจำนวนเมล็ดในกระเป๋า (seedCount) เพิ่มจากตอนเริ่มขั้น · เป้า = หน้าร้านเมล็ด (ร้านเดียวกับขั้นขาย)
local STEPS = {
	{ id = "buy", th = "ไปร้านเมล็ด แล้วซื้อเมล็ด 10 เมล็ด", en = "Go to the seed shop and buy 10 seeds",
		markTh = "ร้านเมล็ด", markEn = "Seed shop" },
	{ id = "plant", th = "กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน", en = "Tap slot 1 (seeds), then tap the soil",
		markTh = "แปลงดิน", markEn = "Soil plot" },
	{ id = "harvest", th = "รอต้นโต แล้วกดปุ่มเก็บที่ต้น", en = "Wait for it to grow, then press harvest",
		markTh = "กำลังโต...", markEn = "Growing...", readyTh = "โตแล้ว! กดเก็บ", readyEn = "Ready! Harvest" },
	{ id = "sell", th = "ไปร้านเมล็ด แล้วขายผลผลิต", en = "Go to the seed shop and sell your crops",
		markTh = "ร้านเมล็ด", markEn = "Seed shop" },
	{ id = "npc", th = "ไปคุยกับหุ่นนกฮูก มีอย่างอื่นให้ลองอีก", en = "Talk to the Robot Owl for more to try",
		markTh = "หุ่นนกฮูก", markEn = "Robot Owl" },
}

-- ชุดขั้นที่ 2: บทสัตว์เลี้ยง (2026-11-15 ผู้ใช้สั่ง ต่อจากตกปลา) เริ่มด้วย StartGuide:Fire("pet") (ปุ่มบท pet ในหน้าต่างหุ่นนกฮูก/แผง "?")
--   ข้อความการ์ดเปลี่ยนตามสถานะใน checkPetStep (th/en ตรงนี้ใช้ตอนเข้าขั้น) · รางวัลตรวจที่เซิร์ฟเวอร์ (LessonService หัวข้อ "บทสัตว์เลี้ยง")
local PET_STEPS = {
	{ id = "gacha", hint = "gacha", th = "ไปตู้สุ่มสัตว์เลี้ยง กด E ซื้อตั๋วแล้วสุ่ม", en = "Go to the pet capsule machine, press E, buy a ticket and roll",
		markTh = "ตู้สุ่มสัตว์", markEn = "Pet machine" },
	{ id = "petUse", hint = "petMenu", th = "กดปุ่ม 🐾 แล้วกด \"เลือก\" พาสัตว์ตัวใหม่ออกมา", en = "Tap 🐾, then \"Select\" to bring your new pet out",
		markTh = "", markEn = "" },
	{ id = "food", hint = "petFood", th = "ไปเครื่องทำอาหารสัตว์ ใส่ผลผลิตทำอาหาร", en = "Go to the pet food machine and put in crops",
		markTh = "เครื่องทำอาหารสัตว์", markEn = "Pet food machine" },
	{ id = "feed", hint = "feed", th = "ถืออาหารสัตว์ แล้วให้อาหารสัตว์เลี้ยง", en = "Hold the pet food and feed your pet",
		markTh = "สัตว์เลี้ยง", markEn = "Your pet" },
}
local steps = STEPS -- ชุดที่กำลังทำ (STEPS = บทแรก / PET_STEPS = บทสัตว์เลี้ยง)
-- 2026-11-15 ผู้ใช้สั่ง "บังคับให้ซื้อสัก 10 อัน": ขั้นซื้อผ่านเมื่อซื้อเมล็ดรวม BUY_SEEDS เมล็ดในขั้นนี้ (ซื้อหลายรอบรวมกันได้)
--   นับเฉพาะเมล็ดที่เพิ่มตอนร้านเมล็ดเปิดอยู่ (เมล็ดฟรี 5 ถุงจาก StarterGift ที่มาระหว่างเดินไม่นับ) · เอาไปปลูกระหว่างทางยอดที่ซื้อแล้วไม่ลด
--   Attribute GuideBuyQty (ฝั่งเครื่องเรา) = จำนวนที่ยังขาด ให้ ShopGui ตั้งช่องจำนวนไว้ให้ · เริ่มบทตอนมีเมล็ด >= BUY_SEEDS อยู่แล้ว = ข้ามขั้นซื้อ
local BUY_SEEDS = 10
local baseBasic = 0 -- Lesson_basic ตอนเข้าขั้น (ขั้นขาย 2026-11-16)
local lastSeeds, boughtSeeds = 0, 0
local function seedShopOpen()
	local sg = playerGui:FindFirstChild("ShopGui")
	local main = sg and sg:FindFirstChild("Main")
	return main ~= nil and main.Visible and main:GetAttribute("ShopKind") == "seed"
end

local function corner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0); c.Parent = obj; return c end

-- ============ เสียงสำเร็จ (สร้างฝั่งเครื่องเรา ได้ยินคนเดียว) ============
local function makeSound(name, id, volume)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = volume
	s.Parent = game:GetService("SoundService")
	return s
end
local stepSound = makeSound("GuideStepSound", STEP_SOUND_ID, 0.6)
local finishSound = makeSound("GuideFinishSound", FINISH_SOUND_ID, 0.6)
local function playSuccess(big)
	local s = big and finishSound or stepSound
	s.TimePosition = 0
	s:Play()
end

-- ============ การ์ดมุมขวาบน (ใต้แถวปุ่มไอคอน) ============
local gui = Instance.new("ScreenGui")
gui.Name = "NewPlayerGuideGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3 -- ต่ำกว่าหน้าต่างร้าน/กระเป๋า หน้าต่างจะบังการ์ดได้
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Enabled = false
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -12, 0, 64)
card.Size = UDim2.fromOffset(264, 62)
card.AutomaticSize = Enum.AutomaticSize.Y -- 2026-11-15 ข้อความยาว 3 บรรทัด (บทสัตว์เลี้ยง) การ์ดสูงตามข้อความ ไม่ตัดทิ้ง
card.BackgroundColor3 = COLOR_BG
card.Parent = gui
corner(card, 12)
do local pad = Instance.new("UIPadding"); pad.PaddingBottom = UDim.new(0, 6); pad.Parent = card end
do
	local st = Instance.new("UIStroke"); st.Color = COLOR_GOLD; st.Thickness = 3; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = card
end

local cardTitle = Instance.new("TextLabel")
cardTitle.Name = "Title"
cardTitle.BackgroundTransparency = 1
cardTitle.Position = UDim2.new(0, 10, 0, 5)
cardTitle.Size = UDim2.new(1, -52, 0, 18)
cardTitle.Font = Enum.Font.GothamBold
cardTitle.TextSize = 13
cardTitle.TextColor3 = COLOR_SUB
cardTitle.TextXAlignment = Enum.TextXAlignment.Left
cardTitle.Parent = card

local cardText = Instance.new("TextLabel")
cardText.Name = "Text"
cardText.BackgroundTransparency = 1
cardText.Position = UDim2.new(0, 10, 0, 23)
cardText.Size = UDim2.new(1, -20, 0, 34)
cardText.Font = Enum.Font.GothamBold
cardText.TextSize = 14
cardText.TextColor3 = COLOR_TEXT
cardText.TextXAlignment = Enum.TextXAlignment.Left
cardText.TextYAlignment = Enum.TextYAlignment.Top
cardText.TextWrapped = true
cardText.AutomaticSize = Enum.AutomaticSize.Y -- สูงตามข้อความ (ดู card.AutomaticSize)
cardText.Parent = card

local stopButton = Instance.new("TextButton")
stopButton.Name = "Stop"
stopButton.AnchorPoint = Vector2.new(1, 0)
stopButton.Position = UDim2.new(1, -4, 0, 2) -- กรอบกด 36x26 (ตัว X เล็ก แต่พื้นที่กดกว้าง)
stopButton.Size = UDim2.fromOffset(36, 26)
stopButton.BackgroundTransparency = 1
stopButton.Text = "X"
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.TextColor3 = COLOR_SUB
stopButton.Parent = card

-- ============ เป้าหมายในโลก: ชิ้นส่วนล่องหน + เส้นทอง + ลูกศร ============
local targetPart = Instance.new("Part")
targetPart.Name = "NewPlayerGuideTarget"
targetPart.Anchored = true
targetPart.CanCollide = false
targetPart.CanQuery = false
targetPart.CanTouch = false
targetPart.Transparency = 1
targetPart.Size = Vector3.new(1, 1, 1)
local targetAttach = Instance.new("Attachment")
targetAttach.Position = Vector3.new(0, 3, 0) -- ปลายเส้นลอยเหนือเป้า 3 สตั๊ด (ระดับสายตา)
targetAttach.Parent = targetPart

local beam = Instance.new("Beam")
beam.Name = "GuideBeam"
beam.Color = ColorSequence.new(COLOR_GOLD)
beam.Transparency = NumberSequence.new(0.2)
beam.LightEmission = 0.7
beam.Width0 = 0.7
beam.Width1 = 0.7
beam.FaceCamera = true
beam.Segments = 1
beam.Attachment1 = targetAttach
beam.Parent = targetPart

local marker = Instance.new("BillboardGui")
marker.Name = "NewPlayerGuideMarker"
marker.Size = UDim2.fromOffset(220, 74)
marker.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
marker.AlwaysOnTop = false -- true = ไม่แสดงในเกมนี้ (บทเรียนเดิมเจอมาแล้ว)
marker.MaxDistance = 2000
marker.ResetOnSpawn = false
marker.Enabled = false
marker.Adornee = targetPart
marker.Parent = playerGui
local markerLabel = Instance.new("TextLabel")
markerLabel.BackgroundTransparency = 1
markerLabel.Size = UDim2.new(1, 0, 0, 30)
markerLabel.Font = Enum.Font.GothamBold
markerLabel.TextSize = 18
markerLabel.TextColor3 = Color3.new(1, 1, 1)
markerLabel.TextStrokeColor3 = COLOR_TEXT
markerLabel.TextStrokeTransparency = 0
markerLabel.Parent = marker
local markerArrow = Instance.new("TextLabel")
markerArrow.BackgroundTransparency = 1
markerArrow.Position = UDim2.new(0, 0, 0, 28)
markerArrow.Size = UDim2.new(1, 0, 0, 44)
markerArrow.Font = Enum.Font.GothamBlack
markerArrow.TextSize = 40
markerArrow.Text = "▼"
markerArrow.TextColor3 = COLOR_GOLD
markerArrow.TextStrokeColor3 = COLOR_TEXT
markerArrow.TextStrokeTransparency = 0
markerArrow.Parent = marker

-- ============ ค่าที่ใช้ตรวจ ============
local function rootPart()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function plantCount()
	return tonumber(player:GetAttribute("PlantCount")) or 0
end
-- จำนวนเมล็ดทั้งหมดที่ถือ/อยู่กระเป๋า (นิยามเดียวกับ HotbarState.IsSeed: มี CropType ไม่ใช่ผลผลิต/หุ่น) นับ Count ของแต่ละถุง
local function seedCount()
	local total = 0
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if loc then
			for _, t in ipairs(loc:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("CropType") ~= nil and not t:GetAttribute("IsProduce") and not t:GetAttribute("IsBooster") then
					total += tonumber(t:GetAttribute("Count")) or 1
				end
			end
		end
	end
	return total
end
local function coins()
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("เหรียญ")
	return c and c.Value or 0
end

-- จุดบนแผ่นดินที่ใกล้ผู้เล่นที่สุด (แปลงใหญ่ไม่ต้องเดินไปกลางแปลง)
local function nearestSoil()
	local root = rootPart()
	local plots = workspace:FindFirstChild("FarmPlots")
	if not (root and plots) then return nil end
	local best, bestD
	for _, d in ipairs(plots:GetDescendants()) do
		if d.Name == "Soil" and d:IsA("BasePart") then
			local lp = d.CFrame:PointToObjectSpace(root.Position)
			local hx, hz = math.max(d.Size.X / 2 - 2, 0), math.max(d.Size.Z / 2 - 2, 0)
			local p = d.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -hx, hx), d.Size.Y / 2, math.clamp(lp.Z, -hz, hz)))
			local dist = (p - root.Position).Magnitude
			if not bestD or dist < bestD then best, bestD = p, dist end
		end
	end
	return best
end

-- ต้นของเรา: Soil.PlantSlot<n> ที่ OwnerUserId = เรา (ช่องปลูก CanQuery = false จึงไล่ดูลูกของ Soil แทนการค้นรัศมี) ต้นที่โตแล้วมาก่อน แล้วค่อยดูต้นที่ใกล้สุด
-- คืน (ตำแหน่ง, โตแล้วหรือยัง)
local function findMyCrop()
	local root = rootPart()
	local plots = workspace:FindFirstChild("FarmPlots")
	if not (root and plots) then return nil, false end
	local best, bestScore, bestReady
	for _, soil in ipairs(plots:GetDescendants()) do
		if soil.Name == "Soil" and soil:IsA("BasePart") then
			for _, part in ipairs(soil:GetChildren()) do
				if part:IsA("BasePart") and part.Name:sub(1, 9) == "PlantSlot" and part:GetAttribute("OwnerUserId") == player.UserId then
					local prompt = part:FindFirstChildOfClass("ProximityPrompt")
					local ready = prompt ~= nil and prompt.Enabled
					local score = (part.Position - root.Position).Magnitude - (ready and 100000 or 0)
					if not bestScore or score < bestScore then best, bestScore, bestReady = part.Position, score, ready end
				end
			end
		end
	end
	return best, bestReady == true
end

-- พื้นใต้ป้ายร้านเมล็ด (ชิ้น Shop อยู่ระดับหลังคา)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local function shopPos()
	local shops = workspace:FindFirstChild("Shops")
	local shop = shops and shops:FindFirstChild("Shop")
	if not (shop and shop:IsA("BasePart")) then return nil end
	groundParams.FilterDescendantsInstances = { player.Character, shop }
	local hit = workspace:Raycast(shop.Position + Vector3.new(0, 2, 0), Vector3.new(0, -40, 0), groundParams)
	return hit and hit.Position or (shop.Position - Vector3.new(0, 6, 0))
end

-- ============ สถานะ ============
local step = 0 -- 0 = ไม่ได้นำทาง, 1..#STEPS = กำลังทำขั้นนั้น, -1 = นำทางไปจุดเดียว (GuideTo)
local runId = 0 -- เพิ่มทุกครั้งที่เริ่ม/หยุด ลูปเก่าเห็นค่าไม่ตรงแล้วเลิกเอง
local basePlant, maxPlant, baseCoins = 0, 0, 0
local baseSeeds = 0 -- ขั้นซื้อเมล็ด (2026-11-15)
local targetPos -- Vector3 ของเป้าหมายปัจจุบัน (nil = ยังหาไม่เจอ ซ่อนเส้น/ลูกศร)
local markText = ""
local everStarted = false
local shopHint -- nil / "buy" / "sell" / "fishSell" / "gacha" / "petMenu" / "petFood" / "feed" = ไฮไลต์ปุ่ม (ดูหัวข้อ "ไฮไลต์ปุ่มในร้าน")
local pet = {} -- ค่าตั้งต้นของขั้นบทสัตว์เลี้ยง (enterStep ตั้งใหม่ทุกขั้น)

-- ============ ค่าที่ใช้ตรวจบทสัตว์เลี้ยง ============
local function normalTickets() return tonumber(player:GetAttribute("GachaTickets_Normal")) or 0 end
local function allTools()
	local list = {}
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if loc then for _, t in ipairs(loc:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end end
	end
	return list
end
local function petFoodCount()
	local n = 0
	for _, t in ipairs(allTools()) do if t:GetAttribute("IsPetFood") then n += tonumber(t:GetAttribute("Count")) or 1 end end
	return n
end
local function holdingPetFood()
	local t = player.Character and player.Character:FindFirstChildOfClass("Tool")
	return t ~= nil and t:GetAttribute("IsPetFood") == true
end
-- เครื่องทำอาหารใส่ได้ไหม: ผลผลิตชนิด+ดาวเดียวกันรวม >= 2 ชิ้น (PetFoodConfig.PRODUCE_PER_BAG) หรือมีปลา (ไม่นับขยะ)
local function hasFoodIngredients()
	local groups = {}
	for _, t in ipairs(allTools()) do
		if t:GetAttribute("IsFish") and not t:GetAttribute("IsJunk") then return true end
		if t:GetAttribute("IsProduce") then
			local key = tostring(t:GetAttribute("CropType")) .. "_" .. tostring(t:GetAttribute("Star") or 1)
			groups[key] = (groups[key] or 0) + (tonumber(t:GetAttribute("Count")) or 1)
			if groups[key] >= 2 then return true end
		end
	end
	return false
end
-- สัตว์ของเราที่อยู่ในโลก (พาออกมาแล้ว) = โมเดลใน workspace ที่ OwnerUserId = เรา + มี PetId
local function myPets()
	local list = {}
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("OwnerUserId") == player.UserId and m:GetAttribute("PetId") then table.insert(list, m) end
	end
	return list
end
local function petIdSet()
	local set = {}
	for _, m in ipairs(myPets()) do set[m:GetAttribute("PetId")] = true end
	return set
end
local function hungerSum()
	local s = 0
	for _, m in ipairs(myPets()) do s += tonumber(player:GetAttribute("PetHunger_" .. tostring(m:GetAttribute("PetId")))) or 100 end
	return s
end
local function allPetsFull()
	local list = myPets()
	if #list == 0 then return false end
	for _, m in ipairs(list) do
		if (tonumber(player:GetAttribute("PetHunger_" .. tostring(m:GetAttribute("PetId")))) or 100) < 100 then return false end
	end
	return true
end
local function nearestPetPos()
	local root = rootPart()
	local best, bestD
	for _, m in ipairs(myPets()) do
		local p = m:GetPivot().Position
		local d = root and (p - root.Position).Magnitude or 0
		if not bestD or d < bestD then best, bestD = p, d end
	end
	return best and best - Vector3.new(0, 1, 0)
end
local function modelFloor(name)
	local m = workspace:FindFirstChild(name)
	if not (m and m:IsA("Model")) then return nil end
	local cf, size = m:GetBoundingBox()
	return cf.Position - Vector3.new(0, size.Y / 2, 0)
end
local function petMenuSelectButtons() -- ปุ่ม "เลือก" ของสัตว์ที่ยังไม่ได้พาออกมา (PetHelperToggleButton ติด PetActive ไว้), จำนวนปุ่มทั้งหมด
	local menu = playerGui:FindFirstChild("PetMenuGui")
	local list = menu and menu:FindFirstChild("PetList", true)
	local free, total = {}, 0
	if not list then return free, 0 end
	for _, d in ipairs(list:GetDescendants()) do
		if d.Name == "SelectButton" and d:IsA("GuiButton") then
			total += 1
			if d:GetAttribute("PetActive") == false then table.insert(free, d) end
		end
	end
	return free, total
end
local function petMenuOpen()
	local menu = playerGui:FindFirstChild("PetMenuGui")
	local frame = menu and menu:FindFirstChild("PetMenuFrame", true)
	return frame ~= nil and frame.Visible and menu.Enabled
end
local ticketPrice
do
	local ok, cfg = pcall(function() return require(ReplicatedStorage:WaitForChild("GachaConfig", 10)) end)
	ticketPrice = ok and type(cfg) == "table" and cfg.TicketTypes and cfg.TicketTypes.Normal and cfg.TicketTypes.Normal.CoinPrice or 20000
end
local function commas(n)
	local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (s:gsub("^,", ""))
end
local function setCardText(text)
	if cardText.Text ~= text then cardText.Text = text end
end

local function ensureRootAttach()
	local root = rootPart()
	if not root then return nil end
	local a = root:FindFirstChild("NewPlayerGuideAttach")
	if not a then
		a = Instance.new("Attachment")
		a.Name = "NewPlayerGuideAttach"
		a.Position = Vector3.new(0, 1.2, 0) -- ระดับอก
		a.Parent = root
	end
	return a
end

local function hideWorld()
	targetPart.Parent = nil
	marker.Enabled = false
end
local function showWorld()
	if not targetPos then hideWorld() return end
	targetPart.Position = targetPos
	targetPart.Parent = workspace
	beam.Attachment0 = ensureRootAttach()
	marker.Enabled = true
end

local function enterStep(n)
	step = n
	basePlant = plantCount()
	maxPlant = basePlant
	baseCoins = coins()
	baseSeeds = seedCount()
	lastSeeds, boughtSeeds = baseSeeds, 0
	baseBasic = tonumber(player:GetAttribute("Lesson_basic")) or 0
	targetPos = nil
	local s = steps[n]
	player:SetAttribute("GuideBuyQty", (steps == STEPS and s.id == "buy") and BUY_SEEDS or nil)
	shopHint = (s.id == "buy" or s.id == "sell") and s.id or s.hint
	cardTitle.Text = (steps == PET_STEPS and tr("สัตว์เลี้ยง", "Pets") or tr("สอนเล่น", "Guide")) .. " " .. n .. "/" .. #steps
	cardText.Text = tr(s.th, s.en)
	markText = tr(s.markTh, s.markEn)
	if steps == PET_STEPS then
		pet = { maxTickets = normalTickets(), pets = petIdSet(), food = petFoodCount(), minHunger = hungerSum(), lesson = tonumber(player:GetAttribute("Lesson_pet")) or 0 }
	end
end

local function stop()
	runId += 1
	step = 0
	shopHint = nil
	player:SetAttribute("GuideBuyQty", nil)
	gui.Enabled = false
	hideWorld()
end

local function finish()
	runId += 1
	local myRun = runId
	step = 0
	shopHint = nil
	player:SetAttribute("GuideBuyQty", nil)
	hideWorld()
	playSuccess(true)
	if steps == PET_STEPS then
		cardTitle.Text = tr("สัตว์เลี้ยง", "Pets") .. " " .. #steps .. "/" .. #steps
		cardText.Text = tr("เก่งมาก! จบบทสัตว์เลี้ยงแล้ว ไปรับรางวัลที่หุ่นนกฮูก", "Well done! Pet lesson complete. Claim your reward from the Robot Owl")
	else
		cardTitle.Text = tr("สอนเล่น", "Guide") .. " " .. #steps .. "/" .. #steps
		cardText.Text = tr("เก่งมาก! จบบทเรียนแรกแล้ว", "Well done! First lesson complete")
	end
	task.delay(FINISH_SHOW_TIME, function()
		if runId == myRun then gui.Enabled = false end
	end)
end

-- ตรวจขั้นปัจจุบัน 1 ครั้ง: อัปเดตเป้าหมาย แล้วคืน true ถ้าผ่านขั้น
-- บทสัตว์เลี้ยง: ตรวจ 1 ครั้ง อัปเดตเป้า/ข้อความ/โหมดไฮไลต์ตามสถานะ คืน true = ผ่านขั้น
local function checkPetStep(s)
	if s.id == "gacha" then
		-- ผ่าน = ตั๋วลดลงจากค่าสูงสุดที่เห็นในขั้นนี้ (สุ่มไปแล้ว) · ซื้อตั๋วก่อน = ค่าสูงสุดขยับตาม
		local n = normalTickets()
		if n > pet.maxTickets then pet.maxTickets = n end
		if n < pet.maxTickets then return true end
		targetPos = modelFloor("GachaMachine")
		if n > 0 then
			setCardText(tr("มีตั๋วแล้ว! กด E ที่ตู้สุ่ม แล้วกด \"สุ่ม 1 ครั้ง\"", "You have a ticket! Press E at the machine and tap \"Roll x1\""))
		elseif player:GetAttribute("FreeNormalTicket") == true then
			setCardText(tr("ไปตู้สุ่มสัตว์เลี้ยง กด E แล้วซื้อตั๋ว 1 ใบ (ใบแรกฟรี!)", "Go to the pet machine, press E and buy 1 ticket (first one free!)"))
		elseif coins() >= ticketPrice then
			setCardText(tr("ไปตู้สุ่มสัตว์เลี้ยง กด E แล้วซื้อตั๋ว 1 ใบ (", "Go to the pet machine, press E and buy 1 ticket (") .. commas(ticketPrice) .. tr(" เหรียญ)", " coins)"))
		else
			setCardText(tr("ตั๋วสุ่มใบละ ", "A ticket costs ") .. commas(ticketPrice) .. tr(" เหรียญ หาเหรียญเพิ่ม หรือเล่นครบชั่วโมงรับตั๋วฟรี", " coins. Earn more, or play an hour for a free ticket"))
		end
		return false
	elseif s.id == "petUse" then
		targetPos = nil -- ทำบนจอ ไม่มีเป้าในโลก
		for id in pairs(petIdSet()) do
			if not pet.pets[id] then return true end -- มีสัตว์ตัวใหม่ออกมา
		end
		local free, total = petMenuSelectButtons()
		if petMenuOpen() and total > 0 and #free == 0 then return true end -- ทุกตัวออกมาอยู่แล้ว (เช่นสุ่มได้ตัวซ้ำ)
		local gacha = playerGui:FindFirstChild("GachaGui")
		if gacha and gacha.Enabled then
			setCardText(tr("ปิดตู้สุ่ม (X) แล้วกดปุ่ม 🐾 พาสัตว์ตัวใหม่ออกมา", "Close the machine (X), then tap 🐾 to bring your new pet out"))
		else
			setCardText(tr(s.th, s.en))
		end
		return false
	elseif s.id == "food" then
		local now = petFoodCount()
		if now > pet.food or pet.food > 0 then return true end -- ได้อาหารเพิ่ม หรือมีอยู่แล้วตั้งแต่เริ่ม = ไปขั้นให้อาหาร
		local queued = (tonumber(player:GetAttribute("PetFoodQueue")) or 0) + (tonumber(player:GetAttribute("PetFoodReady")) or 0)
		if queued > 0 then
			shopHint = "petFood"
			targetPos = modelFloor("PetFoodMachine")
			markText = tr(s.markTh, s.markEn)
			if (tonumber(player:GetAttribute("PetFoodReady")) or 0) > 0 then
				setCardText(tr("อาหารสัตว์เสร็จแล้ว! กด E ที่เครื่อง แล้วกดเก็บ", "Pet food is ready! Press E at the machine and collect it"))
			else
				setCardText(tr("เครื่องกำลังทำอาหาร รอสักครู่ แล้วกดเก็บที่เครื่อง", "The machine is making food. Wait a moment, then collect it"))
			end
		elseif hasFoodIngredients() then
			shopHint = "petFood"
			targetPos = modelFloor("PetFoodMachine")
			markText = tr(s.markTh, s.markEn)
			setCardText(tr("ไปเครื่องทำอาหารสัตว์ กด E แล้วกด \"ใส่\" (ผลผลิตดาวเดียวกัน 2 ชิ้น = 1 ถุง)", "Go to the pet food machine, press E and tap \"Insert\" (2 crops of the same star = 1 bag)"))
		elseif seedCount() > 0 or findMyCrop() ~= nil then
			-- ยังไม่มีผลผลิตพอ: พาไปปลูก/เก็บก่อน (ผู้ใช้สั่ง 2026-11-15)
			shopHint = nil
			local pos, ready = findMyCrop()
			if pos then
				targetPos = pos
				markText = ready and tr("โตแล้ว! กดเก็บ", "Ready! Harvest") or tr("กำลังโต...", "Growing...")
				setCardText(tr("ยังไม่มีผลผลิตทำอาหาร รอต้นโตแล้วเก็บ ให้ได้ผลผลิต 2 ชิ้น", "No crops for food yet. Wait for your plants to grow and harvest 2 crops"))
			else
				targetPos = nearestSoil()
				markText = tr("แปลงดิน", "Soil plot")
				setCardText(tr("ยังไม่มีผลผลิตทำอาหาร ไปปลูกผักก่อน: กดช่อง 1 (เมล็ด) แล้วแตะแปลงดิน", "No crops for food yet. Plant first: tap slot 1 (seeds), then tap the soil"))
			end
		else
			shopHint = "buy" -- ไม่มีเมล็ดด้วย = ไปซื้อเมล็ด (ไฮไลต์เดียวกับบทแรก)
			targetPos = shopPos()
			markText = tr("ร้านเมล็ด", "Seed shop")
			setCardText(tr("ยังไม่มีผลผลิตและเมล็ด ไปซื้อเมล็ดที่ร้านเมล็ดก่อน", "No crops or seeds yet. Buy seeds at the seed shop first"))
		end
		return false
	else -- feed: ถุงอาหารลดลง หรือความอิ่มรวมเพิ่มจากค่าต่ำสุดที่เห็น (แบบเดียวกับ TutorialGui เดิม)
		local h = hungerSum()
		if h < pet.minHunger then pet.minHunger = h end
		-- 2026-11-16: เลิกนับ "ถุงอาหารลด" (ไก่ให้อาหารอัตโนมัติ/เติมชามก็ทำให้ลด บทสอนผ่านทั้งที่ไม่ได้ป้อน)
		-- ผ่าน = ความอิ่มรวมเพิ่ม หรือเซิร์ฟยืนยันว่าป้อนแล้ว (Lesson_pet เปลี่ยนจากตอนเริ่มบท เช่น TODO → READY)
		if h > pet.minHunger + 0.5 or (tonumber(player:GetAttribute("Lesson_pet")) or 0) > pet.lesson then return true end
		targetPos = nearestPetPos()
		if allPetsFull() then
			setCardText(tr("สัตว์ยังอิ่มอยู่ (100%) รอให้หิวสักพัก แล้วค่อยให้อาหาร", "Your pet is still full (100%). Wait until it gets hungry, then feed it"))
		elseif holdingPetFood() then
			setCardText(tr("แตะชื่อสัตว์ที่ป้ายเหนือแถบช่อง (หรือเดินไปใกล้สัตว์แล้วกด F)", "Tap your pet on the label above the hotbar (or walk up to it and press F)"))
		else
			setCardText(tr("กดช่องอาหารสัตว์ 🥫 ในแถบด้านล่างเพื่อถือ (ไม่เจอ? เปิดกระเป๋า 🎒 กด \"ใช้\")", "Tap the pet food 🥫 slot on the bottom bar to hold it (not there? open the bag 🎒 and tap \"Use\")"))
		end
		return false
	end
end

local function checkStep()
	local s = steps[step]
	if steps == PET_STEPS then return checkPetStep(s) end
	if s.id == "buy" then
		if not targetPos then targetPos = shopPos() end
		local now = seedCount()
		if now > lastSeeds and seedShopOpen() then boughtSeeds += now - lastSeeds end
		lastSeeds = now
		local left = BUY_SEEDS - boughtSeeds
		if left <= 0 then return true end
		if player:GetAttribute("GuideBuyQty") ~= left then player:SetAttribute("GuideBuyQty", left) end
		setCardText(tr("ไปร้านเมล็ด แล้วซื้อเมล็ด ", "Go to the seed shop and buy ") .. BUY_SEEDS
			.. tr(" เมล็ด (ซื้อแล้ว ", " seeds (bought ") .. boughtSeeds .. "/" .. BUY_SEEDS .. ")")
		return false
	elseif s.id == "plant" then
		targetPos = nearestSoil()
		if plantCount() > basePlant then return true end
		-- 2026-11-16: มีเมล็ดแต่ไม่อยู่ช่อง 1-2 (ช่องเต็ม/อยู่กระเป๋า) = บอกให้เปิดกระเป๋ากด "ใช้" · อยู่ช่องแล้ว = ข้อความเดิม
		local okHs, hs = pcall(require, script.Parent:FindFirstChild("HotbarState"))
		local inSlot = false
		if okHs and type(hs) == "table" then
			for i = 1, 2 do
				local t = hs.GetSlotTool(i)
				if t and hs.IsSeed(t) then inSlot = true end
			end
		else
			inSlot = true -- อ่านช่องไม่ได้ = ใช้ข้อความเดิม
		end
		if not inSlot and seedCount() > 0 then
			setCardText(tr("เมล็ดอยู่ในกระเป๋า เปิด 🎒 แล้วกด \"ใช้\" ที่เมล็ด จากนั้นแตะแปลงดิน", "Your seeds are in the bag. Open 🎒, tap \"Use\" on the seeds, then tap the soil"))
		else
			setCardText(tr(s.th, s.en))
		end
		return false
	elseif s.id == "harvest" then
		local pos, ready = findMyCrop()
		targetPos = pos
		markText = ready and tr(s.readyTh, s.readyEn) or tr(s.markTh, s.markEn)
		local now = plantCount()
		if now > maxPlant then maxPlant = now end
		return now < maxPlant
	elseif s.id == "sell" then
		if not targetPos then targetPos = shopPos() end
		-- 2026-11-16: ผ่านเมื่อเซิร์ฟยืนยันว่าขายผลผลิตจริง (Lesson_basic เปลี่ยนจากตอนเข้าขั้น) · เดิมนับเงินเพิ่ม = ขายเมล็ดก็ผ่านทั้งที่ไม่ได้รางวัล
		-- เคยทำบทนี้แล้ว (READY/CLAIMED) หรือเซิร์ฟโหลดบทเรียนไม่ได้ = ใช้เงินเพิ่มแบบเดิม
		if (tonumber(player:GetAttribute("Lesson_basic")) or 0) > baseBasic then return true end
		if baseBasic >= 1 or player:GetAttribute("LessonsLoaded") ~= true then return coins() > baseCoins end
		return false
	else -- npc: ผ่านเมื่อเปิดหน้าต่างบทเรียนของหุ่นนกฮูก · ไม่มี NPC ในแมพ = ผ่านเลย
		local npc = workspace:FindFirstChild("GuideNPC")
		if not npc then return true end
		local cf, size = npc:GetBoundingBox()
		targetPos = cf.Position - Vector3.new(0, size.Y / 2, 0)
		local lessons = playerGui:FindFirstChild("LessonNpcGui")
		return lessons ~= nil and lessons.Enabled
	end
end

local function start(set)
	runId += 1
	local myRun = runId
	everStarted = true
	steps = set == "pet" and PET_STEPS or STEPS -- "pet" = บทสัตว์เลี้ยง (2026-11-15) · อื่นๆ/ไม่ใส่ = บทแรก
	-- บทแรก: มีเมล็ดอยู่แล้ว (เช่นผู้เล่นเก่ากด "เริ่มนำทาง") = ข้ามขั้นซื้อเมล็ด เริ่มที่ปลูก
	enterStep((steps == STEPS and seedCount() >= BUY_SEEDS) and 2 or 1)
	gui.Enabled = true
	task.spawn(function()
		while runId == myRun do
			if checkStep() then
				if step >= #steps then
					finish()
					return
				end
				playSuccess(false)
				enterStep(step + 1)
				checkStep() -- หาเป้าหมายของขั้นใหม่ทันที
			end
			showWorld()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

-- นำทางไปจุดเดียว (ปุ่ม "พาไป" ในหน้าต่างบทเรียน): การ์ด + เส้น + ลูกศรชุดเดียวกัน ถึงระยะ arriveDist แล้วแสดง doneText และจบเอง
-- data = { pos = Vector3, title = string, text = string, mark = string, arriveDist = number?, doneText = string?, stay = boolean? } (ข้อความแปลมาแล้วจากผู้เรียก)
-- stay = true: ถึงแล้วการ์ดค้างที่ doneText (เส้น/ลูกศรหาย) รอขั้นถัดไปจากผู้เรียก · ไม่ใส่ = ค้าง FINISH_SHOW_TIME วิแล้วซ่อนเอง
local function guideTo(data)
	if type(data) ~= "table" or typeof(data.pos) ~= "Vector3" then return end
	runId += 1
	local myRun = runId
	everStarted = true -- ผู้เล่นใหม่ที่กด "พาไป" ก่อนถึงเวลาเริ่มเอง = ไม่แทรกด้วยขั้น 1
	step = -1
	targetPos = data.pos
	shopHint = data.shopHint == "fishSell" and "fishSell" or nil -- บทตกปลาขั้นขายปลา (LessonNpcGui)
	markText = tostring(data.mark or "")
	cardTitle.Text = tostring(data.title or "")
	cardText.Text = tostring(data.text or "")
	gui.Enabled = true
	local arriveDist = tonumber(data.arriveDist) or 12
	task.spawn(function()
		while runId == myRun do
			local root = rootPart()
			if root and (targetPos - root.Position).Magnitude <= arriveDist then
				runId += 1
				local doneRun = runId
				step = 0
				hideWorld()
				playSuccess(data.big == true)
				if data.doneText and data.stay == true then
					cardText.Text = tostring(data.doneText)
				elseif data.doneText then
					cardText.Text = tostring(data.doneText)
					task.delay(FINISH_SHOW_TIME, function()
						if runId == doneRun then gui.Enabled = false end
					end)
				else
					gui.Enabled = false
				end
				return
			end
			showWorld()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

-- ลูกศรเด้ง + ระยะทาง ทุกเฟรม (เฉพาะตอนกำลังนำทางและมีเป้าหมาย)
RunService.RenderStepped:Connect(function()
	if step == 0 or not targetPos or not marker.Enabled then return end
	marker.StudsOffsetWorldSpace = Vector3.new(0, 6 + math.sin(os.clock() * 4) * 0.6, 0)
	local root = rootPart()
	if root then
		local dist = math.floor((targetPos - root.Position).Magnitude + 0.5)
		markerLabel.Text = markText .. " · " .. dist .. " " .. tr("ม.", "m")
	end
end)
-- เกิดใหม่: ตัวละครใหม่ยังไม่มี Attachment ลูปตรวจจะสร้างให้ในรอบถัดไป (showWorld)

-- ============ ไฮไลต์ปุ่มในร้าน (2026-11-15 ผู้ใช้สั่ง "ตอนเข้าร้านไฮไลต์บอกว่ากดตรงไหน") ============
-- shopHint "buy"/"sell" = ขั้นซื้อ/ขายของบทสอน (ร้านเมล็ด ShopGui) · "fishSell" = บทตกปลาขั้นขายปลา (ร้านตกปลา FishingShopGui ส่งมาทาง GuideTo.shopHint)
-- ร้านเปิดอยู่ + การ์ดนำทางยังเปิด = กรอบทองกะพริบรอบแท็บ/ปุ่มที่ต้องกด + ป้าย 👆 (ไม่บังการกด)
-- วาดใน ScreenGui ของเราเอง ไม่ใส่ Frame ใน ShopGui (FullInventoryGui ถือว่า Frame ตัวเดียวในนั้นคือกรอบร้าน) · ตั้ง ScreenInsets/IgnoreGuiInset ตามร้าน พิกัดจะตรงกัน
-- ปุ่มใน ShopGui ติดชื่อ/Attribute ไว้ (ค้นคำ GuideHint ใน ShopGui) · FishingShopGui มีชื่อ Main / Tab_sell / Page_sell / SellAllButton อยู่แล้ว
local hintGui = Instance.new("ScreenGui")
hintGui.Name = "GuideShopHintGui"
hintGui.ResetOnSpawn = false
hintGui.DisplayOrder = 20 -- เหนือร้านเมล็ด (10) / ร้านตกปลา (8)
hintGui.Enabled = false
hintGui.Parent = playerGui

local hintBox = Instance.new("Frame")
hintBox.Name = "Box"
hintBox.BackgroundTransparency = 1
hintBox.Active = false
hintBox.ZIndex = 50
hintBox.Parent = hintGui
corner(hintBox, 10)
local hintStroke = Instance.new("UIStroke")
hintStroke.Color = COLOR_GOLD
hintStroke.Thickness = 4
hintStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hintStroke.Parent = hintBox

local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "Bubble"
hintLabel.AutomaticSize = Enum.AutomaticSize.X
hintLabel.Size = UDim2.fromOffset(0, 28)
hintLabel.BackgroundColor3 = COLOR_GOLD
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 15
hintLabel.TextColor3 = COLOR_TEXT
hintLabel.ZIndex = 51
hintLabel.AutoLocalize = false -- ข้อความแปลเองแล้ว (แปลอัตโนมัติเคยเปลี่ยนคำจนล้นป้าย)
hintLabel.Parent = hintGui
corner(hintLabel, 8)
do
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 10); p.Parent = hintLabel
	local st = Instance.new("UIStroke"); st.Color = COLOR_TEXT; st.Thickness = 2; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = hintLabel
end

-- ปุ่มมองเห็นอยู่จริง (ตัวมันและพ่อทุกชั้น Visible + ScreenGui เปิด)
local function shownOnScreen(obj)
	local o = obj
	while o and not o:IsA("LayerCollector") do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return o ~= nil and o.Enabled
end
-- ปุ่มที่มี Attribute นี้ ค่าน้อยสุด (= แถวบนสุด)
local function firstTagged(list, attr)
	local best, bestN
	for _, d in ipairs(list:GetDescendants()) do
		local n = d:GetAttribute(attr)
		if n and d:IsA("GuiButton") and (not bestN or n < bestN) then best, bestN = d, n end
	end
	return best
end

-- คืน (ปุ่มที่ต้องกด, ข้อความป้าย) · ไม่ต้องไฮไลต์ = nil
local function findHintTarget()
	if not shopHint or not gui.Enabled then return nil end
	-- ===== บทสัตว์เลี้ยง (2026-11-15) =====
	if shopHint == "gacha" then -- ตู้สุ่ม (GachaGui): แท็บตั๋วธรรมดา → ซื้อ 1 ใบ / สุ่ม 1 ครั้ง · กำลังเปิดแคปซูล = ไม่ไฮไลต์
		if player:GetAttribute("GachaRevealing") then return nil end
		local gg = playerGui:FindFirstChild("GachaGui")
		local main = gg and gg.Enabled and gg:FindFirstChild("Main")
		if not main then return nil end
		if main:GetAttribute("CurrentType") ~= "Normal" then return main:FindFirstChild("Tab_Normal", true), tr("👆 กดแท็บตั๋วธรรมดา", "👆 Tap the Normal tab") end
		if normalTickets() > 0 then return main:FindFirstChild("Roll1", true), tr("👆 กดสุ่ม 1 ครั้ง", "👆 Tap Roll x1") end
		return main:FindFirstChild("Buy1", true), tr("👆 กดซื้อตั๋ว 1 ใบ", "👆 Tap to buy 1 ticket")
	elseif shopHint == "petMenu" then -- ปุ่ม 🐾 → ปุ่ม "เลือก" ของสัตว์ที่ยังไม่ออกมา (ตู้สุ่มยังเปิด = รอปิดก่อน)
		local gg = playerGui:FindFirstChild("GachaGui")
		if gg and gg.Enabled then return nil end
		if not petMenuOpen() then
			return playerGui:FindFirstChild("OpenPetMenuButton", true), tr("👆 กดเปิดเมนูสัตว์", "👆 Open the pet menu")
		end
		-- ปุ่ม "เลือก" ตัวบนสุดที่เห็นอยู่ในรายการ · ทุกปุ่มเลื่อนพ้นจอ (สัตว์ที่ใช้อยู่เรียงบนสุด) = ไฮไลต์ทั้งรายการ บอกให้เลื่อนลง
		local best, list
		for _, b in ipairs((petMenuSelectButtons())) do
			list = list or b:FindFirstAncestorOfClass("ScrollingFrame")
			local inView = true
			if list then
				local cy = b.AbsolutePosition.Y + b.AbsoluteSize.Y / 2
				inView = cy >= list.AbsolutePosition.Y and cy <= list.AbsolutePosition.Y + list.AbsoluteSize.Y
			end
			if inView and shownOnScreen(b) and (not best or b.AbsolutePosition.Y < best.AbsolutePosition.Y) then best = b end
		end
		if best then return best, tr("👆 กดเลือก", "👆 Tap Select") end
		if list and shownOnScreen(list) then return list, tr("👇 เลื่อนลงหาปุ่ม \"เลือก\"", "👇 Scroll down to a \"Select\" button") end
		return nil
	elseif shopHint == "petFood" then -- เครื่องทำอาหาร (PetFoodGui): มีของเสร็จ = ปุ่ม Collect · ไม่งั้น = ปุ่ม "ใส่" (One_) แถวบนสุด
		local pg = playerGui:FindFirstChild("PetFoodGui")
		local main = pg and pg.Enabled and pg:FindFirstChild("Main")
		if not main then return nil end
		if (tonumber(player:GetAttribute("PetFoodReady")) or 0) > 0 then
			local c = main:FindFirstChild("Collect", true)
			if c then return c, tr("👆 กดเก็บอาหาร", "👆 Tap Collect") end
		end
		local best
		for _, d in ipairs(main:GetDescendants()) do
			if d:IsA("GuiButton") and d.Name:sub(1, 4) == "One_" and shownOnScreen(d) and (not best or d.AbsolutePosition.Y < best.AbsolutePosition.Y) then best = d end
		end
		return best, tr("👆 กดใส่", "👆 Tap Insert")
	elseif shopHint == "feed" then -- ถืออาหารอยู่ = ป้ายสัตว์ (PetFeedPicker) · ไม่ได้ถือ = ช่องอาหารสัตว์บนแถบช่อง (CustomHotbar)
		if allPetsFull() then return nil end
		if holdingPetFood() then
			local picker = playerGui:FindFirstChild("PetFeedPicker")
			if not (picker and picker.Enabled) then return nil end
			for _, d in ipairs(picker:GetDescendants()) do
				if d:IsA("GuiButton") and d.Name:sub(1, 5) == "Chip_" then return d, tr("👆 แตะสัตว์ให้มากิน", "👆 Tap your pet") end
			end
			return nil
		end
		local hb = playerGui:FindFirstChild("CustomHotbar")
		if not hb then return nil end
		local want = Localization.T("Hotbar_PetFood", Localization.GetLanguage(player))
		local clip = hb:FindFirstChild("PageClip", true)
		for _, d in ipairs(hb:GetDescendants()) do
			if d.Name == "StripLabel" and d:IsA("TextLabel") and d.Text:sub(1, #want) == want then
				local o = d.Parent
				while o and not o.Name:match("^Slot%d+$") do o = o.Parent end
				local onPage = true -- ช่องอยู่หน้าแถบที่เห็นอยู่ (หน้าอื่นถูก PageClip ตัดออก)
				if o and clip and o:IsA("GuiObject") then
					local cx = o.AbsolutePosition.X + o.AbsoluteSize.X / 2
					onPage = cx >= clip.AbsolutePosition.X and cx <= clip.AbsolutePosition.X + clip.AbsoluteSize.X
				end
				if o and o:IsA("GuiObject") and onPage and shownOnScreen(o) then return o, tr("👆 กดถืออาหารสัตว์", "👆 Tap to hold pet food") end
			end
		end
		return nil
	end
	if shopHint == "fishSell" then
		local fg = playerGui:FindFirstChild("FishingShopGui")
		local main = fg and fg.Enabled and fg:FindFirstChild("Main")
		if not main then return nil end
		local page = main:FindFirstChild("Page_sell")
		if page and page.Visible then
			return page:FindFirstChild("SellAllButton"), tr("👆 กดขายทั้งหมด", "👆 Tap Sell All")
		end
		return main:FindFirstChild("Tab_sell"), tr("👆 กดแท็บขายปลา", "👆 Tap Sell Fish")
	end
	local sg = playerGui:FindFirstChild("ShopGui")
	local main = sg and sg:FindFirstChild("Main")
	if not (main and main.Visible and main:GetAttribute("ShopKind") == "seed") then return nil end -- ร้านผลไม้ (orchard) ไม่ไฮไลต์
	local tab = main:GetAttribute("ActiveTab")
	local list = main:FindFirstChild("List")
	if shopHint == "buy" then
		if tab ~= "buy" then return main:FindFirstChild("BuyTab", true), tr("👆 กดแท็บซื้อ", "👆 Tap the Buy tab") end
		local want = player:GetAttribute("GuideBuyQty")
		if want then return list and firstTagged(list, "GuideBuySeed"), tr("👆 กดซื้อ (", "👆 Tap Buy (") .. want .. tr(" เมล็ด)", " seeds)") end
		return list and firstTagged(list, "GuideBuySeed"), tr("👆 กดซื้อเมล็ด", "👆 Tap Buy")
	end
	if tab ~= "sell" then return main:FindFirstChild("SellTab", true), tr("👆 กดแท็บขาย", "👆 Tap the Sell tab") end
	-- 2026-11-16 ผู้ใช้สั่ง: ไม่ชี้ "ขายทั้งหมด" แล้ว ชี้ปุ่มขายของผลผลิตแถวบนสุด (GuideSellCrop เลขน้อยสุด · แถวเมล็ดไม่มีป้ายนี้ ขายเมล็ดไม่นับบทเรียน)
	return list and firstTagged(list, "GuideSellCrop"), tr("👆 กดขาย", "👆 Tap Sell")
end

-- หาปุ่มทุก 0.2 วิ · ตามตำแหน่งปุ่มทุกเฟรม (เลื่อนรายการ/ย่อจอแล้วกรอบตามไป)
local hintTarget, hintText, hintNextFind = nil, "", 0
local HINT_PAD = 4
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if now >= hintNextFind then
		hintNextFind = now + 0.1
		local target, text = findHintTarget()
		hintTarget = target
		hintText = text or ""
	end
	local t = hintTarget
	local tg = t and t.Parent and t:FindFirstAncestorOfClass("ScreenGui")
	if not (tg and shownOnScreen(t)) then
		if hintGui.Enabled then hintGui.Enabled = false end
		hintNextFind = 0 -- ปุ่มเดิมหายไป (ปิดร้าน/เปลี่ยนแท็บ) = หาใหม่เฟรมถัดไป ไม่ค้างที่เดิม
		return
	end
	local pos, size = t.AbsolutePosition, t.AbsoluteSize
	-- ปุ่มเลื่อนพ้นกรอบรายการ = ไม่ไฮไลต์ (ไม่ให้กรอบลอยอยู่นอกร้าน)
	local scroll = t:FindFirstAncestorOfClass("ScrollingFrame")
	if scroll then
		local cy = pos.Y + size.Y / 2
		if cy < scroll.AbsolutePosition.Y or cy > scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y then
			if hintGui.Enabled then hintGui.Enabled = false end
			return
		end
	end
	if hintGui.ScreenInsets ~= tg.ScreenInsets then hintGui.ScreenInsets = tg.ScreenInsets end
	if hintGui.IgnoreGuiInset ~= tg.IgnoreGuiInset then hintGui.IgnoreGuiInset = tg.IgnoreGuiInset end
	local wantOrder = math.max(20, tg.DisplayOrder + 1) -- หน้าต่างบางอันอยู่สูงมาก (เครื่องทำอาหาร 9999) ไฮไลต์ต้องอยู่เหนือเสมอ
	if hintGui.DisplayOrder ~= wantOrder then hintGui.DisplayOrder = wantOrder end
	local rel = pos - tg.AbsolutePosition
	hintBox.Position = UDim2.fromOffset(rel.X - HINT_PAD, rel.Y - HINT_PAD)
	hintBox.Size = UDim2.fromOffset(size.X + HINT_PAD * 2, size.Y + HINT_PAD * 2)
	hintStroke.Transparency = 0.5 - 0.5 * math.sin(now * 6) * 0.8
	local bob = math.sin(now * 5) * 3
	-- ปุ่มในรายการ (ซื้อ/ขายรายแถว): ป้ายอยู่ซ้ายปุ่ม 👉 ไม่บังปุ่ม −/จำนวน/+ ที่อยู่เหนือปุ่ม (ผู้ใช้เห็นป้ายบัง 2026-11-15) · อื่นๆ = เหนือ/ใต้ปุ่ม 👆
	-- ซ้ายปุ่ม: ปุ่มในรายการของร้านเมล็ด (เหนือปุ่มคือตัวปรับจำนวน) หรือปุ่มชิดขอบบนขวา (ปุ่ม 🐾: ใต้ปุ่มคือการ์ดนำทาง) · เครื่องทำอาหารซ้ายปุ่มคือช่องจำนวน = เหนือปุ่ม
	local leftSide = rel.X > 150 and ((scroll ~= nil and tg.Name == "ShopGui") or rel.Y <= 40)
	local wantText = leftSide and (hintText:gsub("^👆", "👉")) or hintText
	if hintLabel.Text ~= wantText then hintLabel.Text = wantText end
	if leftSide then
		hintLabel.AnchorPoint = Vector2.new(1, 0.5)
		hintLabel.Position = UDim2.fromOffset(rel.X - HINT_PAD - 4 + bob, rel.Y + size.Y / 2)
	elseif rel.Y > 40 then -- ป้ายอยู่เหนือปุ่ม · ปุ่มชิดขอบบน = ใต้ปุ่ม
		hintLabel.AnchorPoint = Vector2.new(0.5, 1)
		hintLabel.Position = UDim2.fromOffset(rel.X + size.X / 2, rel.Y - HINT_PAD - 4 + bob)
	else
		hintLabel.AnchorPoint = Vector2.new(0.5, 0)
		hintLabel.Position = UDim2.fromOffset(rel.X + size.X / 2, rel.Y + size.Y + HINT_PAD + 4 + bob)
	end
	if not hintGui.Enabled then hintGui.Enabled = true end
end)

stopButton.Activated:Connect(stop)

local startEvent = Instance.new("BindableEvent")
startEvent.Name = "StartGuide"
startEvent.Parent = gui
startEvent.Event:Connect(start)

local guideToEvent = Instance.new("BindableEvent")
guideToEvent.Name = "GuideTo"
guideToEvent.Parent = gui
guideToEvent.Event:Connect(guideTo)

local successEvent = Instance.new("BindableEvent")
successEvent.Name = "PlaySuccess"
successEvent.Parent = gui
successEvent.Event:Connect(function(big) playSuccess(big == true) end)

-- ผู้เล่นใหม่: เริ่มเอง 1 ครั้งต่อรอบที่เล่น (IsNewPlayer มาช้าหลังโหลดเหรียญ จึงฟังการเปลี่ยนด้วย)
local autoQueued = false
local function maybeAutoStart()
	if autoQueued or everStarted or player:GetAttribute("IsNewPlayer") ~= true then return end
	autoQueued = true
	task.delay(AUTO_START_DELAY, function()
		if not everStarted then start() end
	end)
end
player:GetAttributeChangedSignal("IsNewPlayer"):Connect(maybeAutoStart)
maybeAutoStart()
