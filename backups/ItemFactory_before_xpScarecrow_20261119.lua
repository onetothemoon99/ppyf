-- BACKUP of ServerScriptService.ItemFactory before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into ServerScriptService.ItemFactory.Source in Studio
-- bytes=40470 sum=17582741
-- ItemFactory: สร้าง Tool ของเมล็ด/ผลผลิต/หุ่นเพิ่มดวง ให้หน้าตาเหมือนกันทุกจุดที่เรียกใช้
-- (ร้านค้าตอนซื้อ, ตอนเก็บเกี่ยว, และตอนโหลดกระเป๋าคืนให้ตอนเข้าเกมใหม่) รวมไว้ที่เดียวกันไม่ให้แต่ละจุดสร้างเพี้ยนกัน

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolVisualHelper = require(ServerStorage:WaitForChild("ToolVisualHelper"))
-- ซองเมล็ด 3D (ตอนถือ + รูป SeedPacket_<พืช> ในร้าน/กระเป๋า/แถบ 6 ช่อง) 2026-10-31
local SeedPacketBuilder = require(ServerStorage:WaitForChild("SeedPacketBuilder"))
-- ผลไม้หน้าซองที่ดูเล็กเกิน (กล่องครอบรวมเถา/ก้าน) ขยายเพิ่ม
local SEED_FRUIT_BOOST = { Pumpkin = 1.35, Wheat = 1.35 }
-- ผลไม้หน้าซองที่ทำแยกไว้ (มี = ใช้แทน HeldFruit) เช่นข้าวสาลีมัดโบว์ 2026-10-31
local seedPacketFruits = ServerStorage:FindFirstChild("SeedPacketFruits")
local function seedFruitFor(cropType)
	local override = seedPacketFruits and seedPacketFruits:FindFirstChild(cropType)
	if override then return override end
	local template = ServerStorage:WaitForChild("CropTemplates"):FindFirstChild(cropType) -- local cropTemplates ประกาศทีหลังฟังก์ชันนี้
	return template and template:FindFirstChild("HeldFruit")
end
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))
-- สีออร่าตามดาว ใช้ชุดเดียวกับออร่าต้นในแปลง (CropAura) จะได้สีตอนถือกับตอนอยู่ในแปลงตรงกัน
local CropAuraConfig = require(ReplicatedStorage:WaitForChild("CropAuraConfig"))
-- ผักกลายพันธุ์ (2026-10-30): ชื่อมีคำนำหน้า + หน้าตาตอนถือต่างจากปกติ (ดู applyMutationLook)
local MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))
local cropTemplates = ServerStorage:WaitForChild("CropTemplates")
local boosterTemplateModel = ServerStorage:WaitForChild("BoosterTemplates"):WaitForChild("QualityBoosterTemplate")
local petFoodTemplate = ServerStorage:WaitForChild("PetFoodTemplates"):WaitForChild("PetFood")
local fishingTemplates = ServerStorage:WaitForChild("FishingTemplates")
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local fishModels = ServerStorage:WaitForChild("FishModels")

-- รูปถุงอาหารในช่องไอเทม/กระเป๋า (ItemPreview ใช้ชื่อ "PetFood") โฟลเดอร์เดียวกับที่ BoosterPlacementSystem ใส่รูปหุ่น
do
	local previewFolder = ReplicatedStorage:FindFirstChild("ItemPreviewModels")
	if not previewFolder then
		previewFolder = Instance.new("Folder")
		previewFolder.Name = "ItemPreviewModels"
		previewFolder.Parent = ReplicatedStorage
	end
	if not previewFolder:FindFirstChild("PetFood") then
		petFoodTemplate:Clone().Parent = previewFolder
	end
	-- รูปปลาแต่ละชนิด (ItemPreview ใช้ชื่อ "Fish_<id>")
	-- ปลาชุดใหม่ที่ยังซ่อน (FISH_V2 ปิด) ไม่ต้องส่งโมเดลไปเครื่องผู้เล่น (2026-10-08)
	for _, model in ipairs(fishModels:GetChildren()) do
		local def = FishingConfig.Fish[model.Name]
		if not (def and def.Hidden) and not previewFolder:FindFirstChild("Fish_" .. model.Name) then
			local copy = model:Clone()
			copy.Name = "Fish_" .. model.Name
			copy.Parent = previewFolder
		end
	end
	-- รูปพืชในร้าน/กระเป๋า/ฮอตบาร์ (ItemPreview ใช้ชื่อ CropType) เฉพาะพืชที่อีโมจิแสดงไม่ได้ (2026-10-14 ผู้ใช้ขอ: เบอร์รี่แม่มดขึ้นเป็นกล่องว่าง ให้โชว์โมเดล)
	-- ใช้ HeldFruit เป็นรูป ทั้งช่องเมล็ดและช่องผลผลิต พืชอื่นยังใช้อีโมจิเหมือนเดิม
	for _, cropName in ipairs({ "WitchBerry" }) do
		local template = cropTemplates:FindFirstChild(cropName)
		local held = template and template:FindFirstChild("HeldFruit")
		if held and not previewFolder:FindFirstChild(cropName) then
			local copy = held:Clone()
			copy.Name = cropName
			copy.Parent = previewFolder
		end
	end
	-- รูปซองเมล็ดทุกพืช (ItemPreview ใช้ชื่อ "SeedPacket_<CropType>") 2026-10-31
	for _, template in ipairs(cropTemplates:GetChildren()) do
		local held = seedFruitFor(template.Name)
		local previewName = "SeedPacket_" .. template.Name
		if held and not previewFolder:FindFirstChild(previewName) then
			SeedPacketBuilder.BuildPreviewModel(previewName, held, SEED_FRUIT_BOOST[template.Name]).Parent = previewFolder
		end
	end
	-- รูปกระปุกเหยื่อ (ItemPreview ใช้ชื่อ "Bait")
	local baitTemplate = fishingTemplates:FindFirstChild("Bait")
	if baitTemplate and not previewFolder:FindFirstChild("Bait") then
		baitTemplate:Clone().Parent = previewFolder
	end
	-- รูปเบ็ดแต่ละขั้น (ItemPreview ใช้ชื่อ "Rod_<id>")
	for rodId in pairs(FishingConfig.Rods) do
		local template = fishingTemplates:FindFirstChild("Rod_" .. rodId)
		if template and not previewFolder:FindFirstChild(template.Name) then
			local copy = template:Clone()
			-- ให้กล้อง ItemPreview มองจากด้านข้างคัน (เห็นทั้งคัน ไม่ใช่มองจากปลายด้าม)
			if copy.PrimaryPart then copy.PrimaryPart.PivotOffset = CFrame.Angles(0, math.rad(90), 0) end
			copy.Parent = previewFolder
		end
	end
end

local ItemFactory = {}

-- 2026-11-18 หากระเป๋าแบบปลอดภัย (เดิม player.Backpack ตรงๆ พังตอนเกิดใหม่/กำลังออกเกม เคส kwanindy27 ถุงอาหารหาย)
-- FindBackpack: ไม่รอ (ให้คนเรียกเช็กก่อนหักเงิน/เซฟ) · GetBackpack: รอสูงสุด 5 วิ ไม่มีจริง = error
-- Give* เรียก GetBackpack ก่อนแตะของใดๆ พัง = ยังไม่ได้ให้อะไร (คนเรียกที่เซฟ/หักไปแล้ว ต้องคืนเอง)
function ItemFactory.FindBackpack(player)
	return player and player.Parent and player:FindFirstChildOfClass("Backpack") or nil
end
function ItemFactory.GetBackpack(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local waitUntil = os.clock() + 5
	while not backpack and player.Parent and os.clock() < waitUntil do
		task.wait(0.2)
		backpack = player:FindFirstChildOfClass("Backpack")
	end
	if not backpack then error("ItemFactory: no Backpack for " .. player.Name) end
	return backpack
end

local CROP_COLOR = {
	Strawberry = Color3.fromRGB(220, 90, 100),
	Corn = Color3.fromRGB(230, 180, 60),
	Wheat = Color3.fromRGB(235, 205, 110),
	Onion = Color3.fromRGB(190, 140, 200),
	Watermelon = Color3.fromRGB(70, 160, 90),
	Pineapple = Color3.fromRGB(235, 195, 40),
	Potato = Color3.fromRGB(180, 130, 80),
	Cucumber = Color3.fromRGB(95, 165, 70),
	Eggplant = Color3.fromRGB(120, 75, 160),
	Pumpkin = Color3.fromRGB(255, 220, 50),
	WitchBerry = Color3.fromRGB(160, 100, 215),
	Carrot = Color3.fromRGB(255, 140, 40),
	Sunflower = Color3.fromRGB(250, 200, 40),
	Chili = Color3.fromRGB(215, 40, 35),
}

local CROP_ICON = {
	Strawberry = "🍓",
	Corn = "🌽",
	Wheat = "🌾",
	Onion = "🧅",
	Watermelon = "🍉",
	Pineapple = "🍍",
	Potato = "🥔",
	Cucumber = "🥒",
	Eggplant = "🍆",
	Pumpkin = "🎃", WitchBerry = "🍇",
	Carrot = "🥕",
	Sunflower = "🌻",
	Chili = "🌶️",
}

-- (สีออร่าตามดาวย้ายไปอยู่ ReplicatedStorage.CropAuraConfig แล้ว ใช้ร่วมกับออร่าต้นในแปลง)

local HELD_SCALE = {
	Strawberry = 15,
	Corn = 7,
	Wheat = 10,
	Onion = 10,
	Watermelon = 1, -- โมเดลแตงโมใหญ่กว่าผลอื่นมากอยู่แล้ว (สูง 2.6 studs) เลยไม่ต้องขยายอีก เดิมคูณ 5 ทำให้สูงเกือบ 13 studs บังจอ
	Pineapple = 6,
	Potato = 1, -- HeldFruit ของมันฝรั่งสูง 1 stud อยู่แล้ว ไม่ต้องขยาย (พืชอื่นโมเดลจิ๋วเลยต้องขยายหลายเท่า)
	Cucumber = 1.3, -- HeldFruit ยาว 1.4 stud x1.3 = ราว 1.8 (แตงกวาเป็นผลทรงยาว ถือแล้วเห็นชัดกว่าทรงกลม)
	Eggplant = 1.3, -- HeldFruit ยาว 1.4 stud เท่าแตงกวา ใช้ตัวคูณเท่ากัน
	Pumpkin = 1.1, -- ผลฮาโลวีนใหม่กว้างราว 1.2 studs (เดิม HeldFruit 1.1 x 1.2)
	WitchBerry = 1, -- HeldFruit ทำขนาดตอนถือจริงไว้แล้ว
	Carrot = 1, -- HeldFruit ทำขนาดตอนถือจริงไว้แล้ว
	Sunflower = 1,
	Chili = 1,
}
-- ลดแสงของผลผลิตที่ถือ (ตัวคูณรัศมีไฟ/ความสว่างไฟ/ละออง) ฟักทอง 0.5 (ผู้เล่นขอ 2026-10-09) ชนิดอื่น = 1
local HELD_FX_DIM = { Pumpkin = 0.5 }

local BOOSTER_COLOR = Color3.fromRGB(255, 221, 89) -- ทอง-เหลือง ให้ตรงกับ QualityBoosterVisual

-- ใส่เอฟเฟกต์ (แสง+ประกาย+หิ่งห้อยจิ๋วรอบตัว) ให้กับตอนถือหุ่นในมือ เหมือนตอนปักลงดิน
local function attachHeldBoosterEffects(handle, color)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 8
	light.Brightness = 1.6
	light.Parent = handle

	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = color
	sparkles.Parent = handle

	local fireflyCount = 6
	local radius = 1.2

	for i = 1, fireflyCount do
		local angle = (i / fireflyCount) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * radius, 0.3 + math.random() * 0.5, math.sin(angle) * radius)

		local bug = Instance.new("Part")
		bug.Name = "HeldFirefly"
		bug.Shape = Enum.PartType.Ball
		bug.Material = Enum.Material.Neon
		bug.Color = color
		bug.Size = Vector3.new(0.12, 0.12, 0.12)
		bug.CanCollide = false
		bug.CanQuery = false
		bug.Massless = true
		bug.CFrame = handle.CFrame * CFrame.new(offset)
		bug.Parent = handle

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = bug
		weld.Parent = bug

		local bugLight = Instance.new("PointLight")
		bugLight.Color = color
		bugLight.Range = 4
		bugLight.Brightness = 1.2
		bugLight.Parent = bug

		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(color)
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Rate = 3
		sparkle.Speed = NumberRange.new(0.1, 0.3)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.LightEmission = 1
		sparkle.Parent = bug
	end
end

-- สร้าง Tool เมล็ดพันธุ์ (กล่องสีธรรมดา+ไอคอน) ไม่ parent ให้เอง คนเรียกต้องเอาไป .Parent = player.Backpack เอง
function ItemFactory.CreateSeedTool(cropType, count)
	local seedTool = Instance.new("Tool")
	seedTool.Name = cropType .. " x" .. count
	seedTool.RequiresHandle = true
	seedTool:SetAttribute("CropType", cropType)
	seedTool:SetAttribute("Count", count)

	-- ซองเมล็ด 3D มีผลไม้จิ๋วหน้าซอง (2026-10-31) พืชที่ไม่มี HeldFruit ใช้กล่องสี+อีโมจิแบบเดิม
	local held = seedFruitFor(cropType)
	local handle
	if held then
		handle = SeedPacketBuilder.BuildHandle(held, SEED_FRUIT_BOOST[cropType])
	else
		local color = CROP_COLOR[cropType] or Color3.fromRGB(200, 200, 200)
		local icon = CROP_ICON[cropType] or "🌱"
		handle = ToolVisualHelper.BuildColorBox(color, icon)
	end
	handle.Parent = seedTool

	return seedTool
end

-- คำนวณแค่ชื่อที่ควรใช้ (ไม่ต้องสร้าง Tool จริง) ใช้ตอนอัปเดตจำนวนของที่มีอยู่แล้วในกระเป๋า
-- mutation = กลายพันธุ์ (MutationConfig) มี = นำหน้าด้วย "🌟ทอง "
function ItemFactory.GetProduceName(cropType, star, count, lang, mutation)
	local label = Localization.T("Crop_" .. cropType, lang or "th")
	local starText = string.rep("⭐", star)
	local prefix = MutationConfig.Get(mutation) and (MutationConfig.Label(mutation, lang) .. " ") or ""
	return prefix .. label .. " " .. starText .. " x" .. count
end

-- หน้าตาผักกลายพันธุ์ตอนถือ (ขนาดยักษ์คิดตอน BuildHandle แล้ว)
local RAINBOW = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 230, 70), Color3.fromRGB(110, 220, 110), Color3.fromRGB(80, 170, 255), Color3.fromRGB(170, 110, 255) }
local function applyMutationLook(tool, handle, mutation)
	if mutation == "Golden" or mutation == "Rainbow" then
		local i = 0
		for _, p in ipairs(tool:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HeldFirefly" then
				i += 1
				if p:IsA("MeshPart") then p.TextureID = "" end -- ลายเดิมทับสีใหม่
				if mutation == "Golden" then
					p.Color = Color3.fromRGB(255, 200, 50)
					p.Material = Enum.Material.Foil
				else
					p.Color = RAINBOW[(i - 1) % #RAINBOW + 1]
					p.Material = Enum.Material.SmoothPlastic
				end
			end
		end
		local sparkles = Instance.new("Sparkles")
		sparkles.Name = "MutationSparkles"
		sparkles.SparkleColor = mutation == "Golden" and Color3.fromRGB(255, 225, 120) or Color3.fromRGB(255, 255, 255)
		sparkles.Parent = handle
		if mutation == "Rainbow" then
			local hl = Instance.new("Highlight")
			hl.Name = "MutationGlow"
			hl.FillTransparency = 1
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.OutlineTransparency = 0.3
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = tool
		end
	elseif mutation == "Wet" then
		-- หยดน้ำหยดจากผล
		local drops = Instance.new("ParticleEmitter")
		drops.Name = "MutationDrops"
		drops.Texture = "rbxassetid://100881846134039"
		drops.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255))
		drops.Size = NumberSequence.new(0.08)
		drops.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		drops.Lifetime = NumberRange.new(0.5, 0.9)
		drops.Rate = 6
		drops.Speed = NumberRange.new(0.2, 0.5)
		drops.SpreadAngle = Vector2.new(60, 60)
		drops.Acceleration = Vector3.new(0, -8, 0)
		drops.LightEmission = 0.4
		drops.Parent = handle
	end
end

-- สร้าง Tool ผลผลิตที่เก็บเกี่ยวได้ (โมเดลจริง+ออร่าตามดาว) lang = "th"/"en" ของผู้เล่นคนที่จะได้ของชิ้นนี้
-- mutation = กลายพันธุ์ (nil = ผักปกติ) ตั้ง Attribute "Mutation" = แยกกองจากผักปกติชนิด+ดาวเดียวกัน
function ItemFactory.CreateProduceTool(cropType, star, count, lang, mutation)
	if not MutationConfig.Get(mutation) then mutation = nil end
	local tool = Instance.new("Tool")
	tool.Name = ItemFactory.GetProduceName(cropType, star, count, lang, mutation)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsProduce", true)
	tool:SetAttribute("CropType", cropType)
	tool:SetAttribute("Star", star)
	tool:SetAttribute("Count", count)
	if mutation then tool:SetAttribute("Mutation", mutation) end

	local cropTemplate = cropTemplates:FindFirstChild(cropType)
	local heldFruit = cropTemplate and cropTemplate:FindFirstChild("HeldFruit")

	if heldFruit then
		local scale = (HELD_SCALE[cropType] or 0.8) * ((MutationConfig.Get(mutation) and MutationConfig.Get(mutation).heldScale) or 1)
		local handle = ToolVisualHelper.BuildHandle(heldFruit, scale)
		handle.Parent = tool
		if mutation then applyMutationLook(tool, handle, mutation) end

		local auraConfig = CropAuraConfig.Stars[star]
		if auraConfig then
			ToolVisualHelper.AttachAura(handle, auraConfig.ColorA, auraConfig.ColorB, auraConfig.Light, auraConfig.Glow, HELD_FX_DIM[cropType])
		end
	else
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.6, 0.6, 0.6)
		handle.BrickColor = BrickColor.new("Bright orange")
		handle.Parent = tool
	end

	return tool
end

-- ============ อาหารสัตว์เลี้ยง (แปลงจากผลผลิต ป้อนสัตว์ได้อิ่มกว่าผลผลิตดิบ ดู PetHunger.PET_FOOD_BY_STAR) ============
function ItemFactory.GetPetFoodName(star, count, lang)
	return Localization.T("Item_PetFood", lang or "th") .. " " .. string.rep("⭐", star) .. " x" .. count
end

-- Tool ถุงอาหาร (ไม่มี CropType ระบบเมล็ด/ผลผลิตจึงไม่นับเป็นของตัวเอง) ออร่าตามดาวเหมือนผลผลิต
function ItemFactory.CreatePetFoodTool(star, count, lang)
	star = math.clamp(math.floor(tonumber(star) or 1), 1, 5)
	local tool = Instance.new("Tool")
	tool.Name = ItemFactory.GetPetFoodName(star, count, lang)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsPetFood", true)
	tool:SetAttribute("Star", star)
	tool:SetAttribute("Count", count)

	local handle = ToolVisualHelper.BuildHandle(petFoodTemplate, 1.2)
	handle.Parent = tool
	local auraConfig = CropAuraConfig.Stars[star]
	if auraConfig then
		ToolVisualHelper.AttachAura(handle, auraConfig.ColorA, auraConfig.ColorB, auraConfig.Light, auraConfig.Glow)
	end
	return tool
end

-- ให้อาหารสัตว์กับผู้เล่น ถ้ามีดาวเดียวกันอยู่แล้วบวกจำนวนเข้ากองเดิม คืนค่า Tool ที่ได้
function ItemFactory.GivePetFood(player, star, amount)
	star = math.clamp(math.floor(tonumber(star) or 1), 1, 5)
	amount = amount or 1
	local lang = Localization.GetLanguage(player)
	local backpack = ItemFactory.GetBackpack(player) -- 2026-11-18 ดู GetBackpack
	for _, location in ipairs({ backpack, player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsPetFood") and item:GetAttribute("Star") == star then
					local newCount = (item:GetAttribute("Count") or 1) + amount
					item:SetAttribute("Count", newCount)
					item.Name = ItemFactory.GetPetFoodName(star, newCount, lang)
					return item
				end
			end
		end
	end
	local tool = ItemFactory.CreatePetFoodTool(star, amount, lang)
	tool.Parent = backpack
	return tool
end

-- ============ ปลา (ตกได้จาก FishingSystem) ซ้อนกองตามชนิด + ดาว (ขยะแยกกองตามสถานะติดดาว) ============
function ItemFactory.GetFishName(fishId, star, count, lang)
	local fish = FishingConfig.Fish[fishId]
	local name = fish and FishingConfig.FishName(fishId, lang or "th") or fishId
	if fish and fish.Junk then return name .. " x" .. count end -- ขยะไม่มีดาว
	return name .. " " .. string.rep("⭐", star) .. " x" .. count
end

function ItemFactory.CreateFishTool(fishId, star, count, lang)
	star = math.clamp(math.floor(tonumber(star) or 1), 1, 5)
	local tool = Instance.new("Tool")
	tool.Name = ItemFactory.GetFishName(fishId, star, count, lang)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsFish", true)
	tool:SetAttribute("FishId", fishId)
	if FishingConfig.Fish[fishId] and FishingConfig.Fish[fishId].Junk then tool:SetAttribute("IsJunk", true) end -- ขยะ (สัตว์กินไม่ได้)
	tool:SetAttribute("Star", star)
	tool:SetAttribute("Count", count)
	local model = fishModels:FindFirstChild(fishId)
	local handle
	if model then
		handle = ToolVisualHelper.BuildHandle(model, 1.1)
		local auraConfig = CropAuraConfig.Stars[star]
		if auraConfig then
			ToolVisualHelper.AttachAura(handle, auraConfig.ColorA, auraConfig.ColorB, auraConfig.Light, auraConfig.Glow)
		end
	else
		handle = ToolVisualHelper.BuildColorBox(Color3.fromRGB(120, 190, 230), "🐟")
	end
	handle.Parent = tool
	return tool
end

local function mergeJunkStack(player, fishId, star, amount, lang)
	local unstarredStack, starredStack
	local matchingStacks = {}
	for _, location in ipairs({ ItemFactory.GetBackpack(player), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsFish") and item:GetAttribute("IsJunk")
					and item:GetAttribute("FishId") == fishId and item:GetAttribute("Star") == star then
					local isStarred = item:GetAttribute("Starred") == true
					if isStarred then
						starredStack = starredStack or item
					else
						unstarredStack = unstarredStack or item
					end
					table.insert(matchingStacks, item)
				end
			end
		end
	end
	local target = unstarredStack or starredStack
	if not target then return nil end
	local targetIsStarred = target:GetAttribute("Starred") == true
	local newCount = (target:GetAttribute("Count") or 1) + amount
	for _, item in ipairs(matchingStacks) do
		if item ~= target and (item:GetAttribute("Starred") == true) == targetIsStarred then
			newCount += item:GetAttribute("Count") or 1
			item:Destroy()
		end
	end
	target:SetAttribute("Count", newCount)
	target.Name = ItemFactory.GetFishName(fishId, star, newCount, lang)
	return target
end

function ItemFactory.GiveFish(player, fishId, star, amount)
	star = math.clamp(math.floor(tonumber(star) or 1), 1, 5)
	amount = amount or 1
	local lang = Localization.GetLanguage(player)
	local fishDef = FishingConfig.Fish[fishId]
	local isJunk = fishDef and fishDef.Junk == true
	if isJunk then
		-- รวมกองสถานะเดียวกันทั้งหมด เลือกกองไม่ติดดาวก่อน; หากมีแต่กองติดดาวให้ใช้กองนั้น
		local merged = mergeJunkStack(player, fishId, star, amount, lang)
		if merged then return merged end
	else
		for _, location in ipairs({ ItemFactory.GetBackpack(player), player.Character }) do
			if location then
				for _, item in ipairs(location:GetChildren()) do
					if item:IsA("Tool") and item:GetAttribute("IsFish") and item:GetAttribute("FishId") == fishId and item:GetAttribute("Star") == star then
						local newCount = (item:GetAttribute("Count") or 1) + amount
						item:SetAttribute("Count", newCount)
						item.Name = ItemFactory.GetFishName(fishId, star, newCount, lang)
						return item
					end
				end
			end
		end
	end
	local tool = ItemFactory.CreateFishTool(fishId, star, amount, lang)
	tool.Parent = ItemFactory.GetBackpack(player)
	return tool
end

-- ============ เบ็ดตกปลา (ระบบตกปลา FishingSystem / FishingClient) ============
-- ไม่ซ้อนกอง (1 Tool = 1 คัน) ปลายคันมี Attachment "RodTip" ไว้ผูกสายเบ็ด
function ItemFactory.CreateRodTool(rodId, lang)
	local rod = FishingConfig.Rods[rodId] and rodId or FishingConfig.DEFAULT_ROD
	local def = FishingConfig.GetRod(rod)
	local template = fishingTemplates:FindFirstChild("Rod_" .. rod) or fishingTemplates:FindFirstChild("Rod_" .. FishingConfig.DEFAULT_ROD)
	local tool = Instance.new("Tool")
	tool.Name = "🎣 " .. FishingConfig.RodName(rod, lang or "th")
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsFishingRod", true)
	tool:SetAttribute("RodId", rod)
	tool:SetAttribute("Count", 1)
	local model = template:Clone()
	local mothSwarm = model:FindFirstChild("NightMothSwarm")
	for _, d in ipairs(model:GetChildren()) do
		d.Parent = tool
	end
	model:Destroy()
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") and not (mothSwarm and d:IsDescendantOf(mothSwarm)) then d.Anchored = false end
	end
	return tool
end

-- ให้เบ็ดกับผู้เล่น (มีเบ็ดขั้นนี้อยู่แล้ว = ไม่ให้ซ้ำ) คืนค่า Tool
function ItemFactory.GiveRod(player, rodId)
	for _, location in ipairs({ ItemFactory.GetBackpack(player), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsFishingRod") and item:GetAttribute("RodId") == rodId then
					return item
				end
			end
		end
	end
	local tool = ItemFactory.CreateRodTool(rodId, Localization.GetLanguage(player))
	tool.Parent = ItemFactory.GetBackpack(player)
	return tool
end

-- ============ เหยื่อตกปลา (ทำจากผลผลิตที่ร้านตกปลา) ซ้อนกองตามดาว ============
function ItemFactory.GetBaitName(star, count, lang)
	return Localization.Pick(lang or "th", "เหยื่อตกปลา ", "Fishing Bait ") .. string.rep("⭐", star) .. " x" .. count
end

function ItemFactory.CreateBaitTool(star, count, lang)
	star = math.clamp(math.floor(tonumber(star) or 1), 1, 5)
	local tool = Instance.new("Tool")
	tool.Name = ItemFactory.GetBaitName(star, count, lang)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsBait", true)
	tool:SetAttribute("Star", star)
	tool:SetAttribute("Count", count)
	local template = fishingTemplates:FindFirstChild("Bait")
	local handle
	if template then
		handle = ToolVisualHelper.BuildHandle(template, 1)
		local auraConfig = CropAuraConfig.Stars[star]
		if auraConfig then
			ToolVisualHelper.AttachAura(handle, auraConfig.ColorA, auraConfig.ColorB, auraConfig.Light, auraConfig.Glow)
		end
	else
		handle = ToolVisualHelper.BuildColorBox(Color3.fromRGB(240, 160, 180), "🐛")
	end
	handle.Parent = tool
	return tool
end

function ItemFactory.GiveBait(player, star, amount)
	star = math.clamp(math.floor(tonumber(star) or 1), 1, 5)
	amount = amount or 1
	local lang = Localization.GetLanguage(player)
	for _, location in ipairs({ ItemFactory.GetBackpack(player), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsBait") and item:GetAttribute("Star") == star then
					local newCount = (item:GetAttribute("Count") or 1) + amount
					item:SetAttribute("Count", newCount)
					item.Name = ItemFactory.GetBaitName(star, newCount, lang)
					return item
				end
			end
		end
	end
	local tool = ItemFactory.CreateBaitTool(star, amount, lang)
	tool.Parent = ItemFactory.GetBackpack(player)
	return tool
end

-- ใช้เหยื่อ 1 ชิ้นจากกอง (หมดกอง = ลบ Tool) คืน true ถ้าใช้ได้
function ItemFactory.TakeBait(player, tool)
	if not (tool and tool.Parent and tool:GetAttribute("IsBait")) then return false end
	local count = (tool:GetAttribute("Count") or 1) - 1
	if count <= 0 then
		tool:Destroy()
	else
		tool:SetAttribute("Count", count)
		tool.Name = ItemFactory.GetBaitName(tool:GetAttribute("Star") or 1, count, Localization.GetLanguage(player))
	end
	return true
end

-- สร้าง Tool หุ่น (โมเดลจริง+เอฟเฟกต์+ท่าถือแบบแบก)
-- tierId: "x50" (หุ่นข้าวโพดดวงดี ค่าเริ่มต้น) / "x100" (หุ่นทองคำนำโชค ซื้อด้วย Robux) ค่าต่างๆ อยู่ใน ReplicatedStorage.LuckConfig
local BOOSTER_NAME_KEY = { x50 = "Item_Booster", x100 = "Item_BoosterX100" }

function ItemFactory.CreateBoosterTool(count, lang, tierId)
	tierId = (tierId and BOOSTER_NAME_KEY[tierId]) and tierId or "x50"
	local tier = LuckConfig.GetBoosterTier(tierId)

	local boosterTool = Instance.new("Tool")
	boosterTool.Name = Localization.T(BOOSTER_NAME_KEY[tierId], lang or "th") .. " x" .. count
	boosterTool.RequiresHandle = true
	boosterTool:SetAttribute("IsBooster", true)
	boosterTool:SetAttribute("BoosterTier", tierId)
	boosterTool:SetAttribute("Count", count)

	-- โมเดลตอนถือตามระดับ (x100 = หุ่นโคลเวอร์) หาไม่เจอใช้หุ่นข้าวโพดแทน
	local templateModel = (tier.Template and boosterTemplateModel.Parent:FindFirstChild(tier.Template)) or boosterTemplateModel
	-- สกินเทศกาลที่กำลังแสดงอยู่ (LuckConfig.BoosterSkins) เปลี่ยนโมเดลตอนถือ + สีเอฟเฟกต์
	local skin = LuckConfig.GetActiveBoosterSkin(tierId)
	local skinTemplate = skin and boosterTemplateModel.Parent:FindFirstChild(skin.Template)
	if skinTemplate then templateModel = skinTemplate else skin = nil end
	local handle = ToolVisualHelper.BuildHandle(templateModel, 1)
	attachHeldBoosterEffects(handle, (skin and skin.AuraColor) or tier.AuraColor or BOOSTER_COLOR)
	handle.Parent = boosterTool

	boosterTool.GripPos = Vector3.new(0, 1.0, 0)
	boosterTool.GripForward = Vector3.new(0, 0, -1)
	boosterTool.GripRight = Vector3.new(1, 0, 0)
	boosterTool.GripUp = Vector3.new(0, 1, 0)

	return boosterTool
end

-- ให้หุ่นกับผู้เล่น ถ้ามีหุ่นระดับเดียวกันอยู่แล้วบวกจำนวนเข้าไป (x50 กับ x100 แยกกองกัน)
-- ใช้ทั้งร้านเมล็ดพันธุ์ (x50 ซื้อด้วยเหรียญ) และ ProcessReceipt ใน PlantingSystem (x100 ซื้อด้วย Robux)
function ItemFactory.GiveBoosterTool(player, amount, tierId)
	amount = amount or 1
	tierId = (tierId and BOOSTER_NAME_KEY[tierId]) and tierId or "x50"
	local lang = Localization.GetLanguage(player)

	for _, location in ipairs({ ItemFactory.GetBackpack(player), player.Character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsBooster")
					and (item:GetAttribute("BoosterTier") or "x50") == tierId then
					local newCount = (item:GetAttribute("Count") or 1) + amount
					item:SetAttribute("Count", newCount)
					item.Name = Localization.T(BOOSTER_NAME_KEY[tierId], lang) .. " x" .. newCount
					return item
				end
			end
		end
	end

	local boosterTool = ItemFactory.CreateBoosterTool(amount, lang, tierId)
	boosterTool.Parent = ItemFactory.GetBackpack(player)
	return boosterTool
end

-- ============ Boombox เพนกวินสะพายบ่าขวา (สิทธิ์ถาวรตรวจจาก Game Pass ใน BoomboxService) ============
-- ทรงกลมแบบบีบ/ยืดได้: Part ทรง Ball วาดเป็นลูกกลมเท่ากันทุกด้านเสมอ จึงใช้ Block + SpecialMesh ทรงกลมแทน (2026-10-11)
local function roundBoomboxPart(part)
	part.Shape = Enum.PartType.Block
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
end

local function makeBoomboxPart(name, shape, size, color, material, handle, offset, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	if shape == Enum.PartType.Ball then roundBoomboxPart(part) end
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Anchored = false
	part.CFrame = handle.CFrame * offset
	part.Parent = handle.Parent
	local weld = Instance.new("Weld")
	weld.Name = name .. "Weld"
	weld.Part0 = handle
	weld.Part1 = part
	weld.C0 = offset
	weld.C1 = CFrame.identity
	weld.Parent = part
	return part
end

function ItemFactory.CreateBoomboxAccessory(lang)
	lang = lang or "th"
	local accessory = Instance.new("Model")
	accessory.Name = "PenguinBoomboxOnBack"
	accessory:SetAttribute("IsBoombox", true)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.95, 1.15, 0.72)
	roundBoomboxPart(handle)
	handle.Color = Color3.fromRGB(40, 91, 124)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Anchored = false
	handle.Parent = accessory

	-- 2026-10-11 ปรับหน้าตา (ผู้ใช้ขอ): ตัวเป็นทรงไข่จริง มีตาวาว แก้มชมพู ปอยผม และ "หู" เป็นลำโพงแบบหูฟังครอบหู (ดอกลำโพงหันออกด้านข้าง) มีคาดหัวสีชมพู
	local SP, NEON = Enum.Material.SmoothPlastic, Enum.Material.Neon
	local Ball, Cyl = Enum.PartType.Ball, Enum.PartType.Cylinder
	local navy, navyDark = Color3.fromRGB(40, 91, 124), Color3.fromRGB(38, 77, 105)
	local white, ink = Color3.fromRGB(245, 250, 255), Color3.fromRGB(15, 24, 35)
	local sky, ice = Color3.fromRGB(83, 190, 232), Color3.fromRGB(180, 239, 255)
	local gold, pink = Color3.fromRGB(255, 221, 130), Color3.fromRGB(255, 170, 190)

	makeBoomboxPart("Belly", Ball, Vector3.new(0.68, 0.80, 0.30), white, SP, handle, CFrame.new(0, -0.12, -0.235))
	makeBoomboxPart("Beak", Ball, Vector3.new(0.17, 0.10, 0.17), Color3.fromRGB(255, 166, 61), SP, handle, CFrame.new(0, 0.20, -0.32))
	makeBoomboxPart("Tuft", Ball, Vector3.new(0.09, 0.18, 0.09), navy, SP, handle, CFrame.new(0.03, 0.60, -0.12) * CFrame.Angles(math.rad(-30), 0, math.rad(-12)))
	for _, side in ipairs({ -1, 1 }) do
		local n = side < 0 and "Left" or "Right"
		makeBoomboxPart("Eye" .. n, Ball, Vector3.new(0.12, 0.15, 0.08), ink, SP, handle, CFrame.new(side * 0.15, 0.30, -0.275))
		makeBoomboxPart("EyeShine" .. n, Ball, Vector3.new(0.045, 0.05, 0.03), white, NEON, handle, CFrame.new(side * 0.15 + 0.022, 0.335, -0.31))
		makeBoomboxPart("Cheek" .. n, Ball, Vector3.new(0.13, 0.08, 0.05), pink, SP, handle, CFrame.new(side * 0.27, 0.19, -0.25))
		makeBoomboxPart("Wing" .. n, Ball, Vector3.new(0.18, 0.44, 0.30), navyDark, SP, handle, CFrame.new(side * 0.47, -0.16, 0) * CFrame.Angles(0, 0, math.rad(side * 16)))
		makeBoomboxPart("Foot" .. n, Ball, Vector3.new(0.27, 0.12, 0.36), Color3.fromRGB(255, 157, 48), SP, handle, CFrame.new(side * 0.19, -0.56, -0.10) * CFrame.Angles(0, math.rad(-side * 12), 0))
		-- หูลำโพง: ตัวครอบ + ขอบขาว + ดอกลำโพงเรืองแสง + วงแหวน + จุกกลางสีทอง (ทรงกระบอกแกน X = หันออกด้านข้างพอดี)
		local ear = CFrame.new(side * 0.455, 0.31, 0)
		makeBoomboxPart("SpeakerEar" .. n, Cyl, Vector3.new(0.16, 0.40, 0.40), sky, SP, handle, ear)
		makeBoomboxPart("SpeakerEarRim" .. n, Cyl, Vector3.new(0.05, 0.45, 0.45), white, SP, handle, ear * CFrame.new(side * 0.07, 0, 0))
		makeBoomboxPart("SpeakerEarCone" .. n, Cyl, Vector3.new(0.03, 0.33, 0.33), ice, NEON, handle, ear * CFrame.new(side * 0.095, 0, 0))
		makeBoomboxPart("SpeakerEarRing" .. n, Cyl, Vector3.new(0.02, 0.22, 0.22), sky, SP, handle, ear * CFrame.new(side * 0.108, 0, 0))
		makeBoomboxPart("SpeakerEarCenter" .. n, Ball, Vector3.new(0.10, 0.13, 0.13), gold, NEON, handle, ear * CFrame.new(side * 0.10, 0, 0))
	end
	-- คาดหัวสีชมพูโค้งข้ามหัว เชื่อมหูลำโพงสองข้าง
	local bandRadius, bandSegments = 0.49, 9
	for i = 0, bandSegments do
		local a = math.rad(28 + (124 * i / bandSegments))
		makeBoomboxPart("Headband" .. i, Cyl, Vector3.new(0.17, 0.085, 0.085), pink, SP, handle, CFrame.new(math.cos(a) * bandRadius, 0.14 + math.sin(a) * bandRadius * 1.08, 0) * CFrame.Angles(0, 0, a + math.rad(90)))
	end

	-- ลำโพงที่พุง
	makeBoomboxPart("SpeakerRim", Cyl, Vector3.new(0.05, 0.36, 0.36), sky, SP, handle, CFrame.new(0, -0.26, -0.37) * CFrame.Angles(0, math.rad(90), 0))
	local speaker = makeBoomboxPart("Speaker", Cyl, Vector3.new(0.06, 0.28, 0.28), Color3.fromRGB(110, 218, 255), NEON, handle, CFrame.new(0, -0.26, -0.378) * CFrame.Angles(0, math.rad(90), 0))
	makeBoomboxPart("SpeakerCenter", Ball, Vector3.new(0.11, 0.11, 0.07), gold, NEON, handle, CFrame.new(0, -0.26, -0.40))
	speaker.Transparency = 0.15
	local light = Instance.new("PointLight")
	light.Name = "SoftBlueAura"
	light.Color = Color3.fromRGB(115, 205, 255)
	light.Range = 7
	light.Brightness = 0.85
	light.Shadows = false
	light.Parent = handle
	return accessory
end

function ItemFactory.GiveBoombox(player)
	local character = player.Character
	if not character then return nil end

	local existing = character:FindFirstChild("PenguinBoomboxOnBack")
	if existing and existing:IsA("Model") and existing:GetAttribute("IsBoombox") == true then return existing end
	if existing then existing:Destroy() end

	-- ลบ Tool รุ่นก่อน ถ้าเหลืออยู่ในเซสชันระหว่างเปลี่ยนจากถือมือเป็นติดหลัง
	for _, location in ipairs({ player:FindFirstChildOfClass("Backpack"), character }) do
		if location then
			for _, item in ipairs(location:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsBoombox") then item:Destroy() end
			end
		end
	end

	local accessory = ItemFactory.CreateBoomboxAccessory(Localization.GetLanguage(player))
	local handle = accessory:FindFirstChild("Handle")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	if not (handle and torso) then
		accessory:Destroy()
		return nil
	end

	-- สะพายบนไหล่ขวาและหันหน้าเพนกวินไปด้านหน้า
	local shoulderOffset = CFrame.new(1.0, 1.38, 0.18)
	handle.CFrame = torso.CFrame * shoulderOffset
	local backWeld = Instance.new("Weld")
	backWeld.Name = "BoomboxRightShoulderWeld"
	backWeld.Part0 = torso
	backWeld.Part1 = handle
	backWeld.C0 = shoulderOffset
	backWeld.C1 = CFrame.identity
	backWeld.Parent = handle
	accessory.Parent = character
	return accessory
end

return ItemFactory