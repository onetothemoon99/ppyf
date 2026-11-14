-- BACKUP 2026-11-14 before sign item (ป้ายเขียนข้อความ)
-- Studio path: game.ReplicatedStorage.ItemPreview (ModuleScript)
-- Restore: paste everything below this header into that script's Source in Studio

-- ItemPreview: โชว์โมเดล 3D ของไอเทมใน UI (ViewportFrame) แทนไอคอนอีโมจิ
-- โมเดลมาจาก ReplicatedStorage.ItemPreviewModels ชื่อต้องตรงกับ CropType ของไอเทม
-- (ตอนนี้มีแค่หุ่นข้าวโพด QualityBooster ที่ BoosterPlacementSystem สำเนามาให้)
-- ใช้ใน ShopGui, CustomHotbar, FullInventoryGui และรูปตอนลากไอเทม (HotbarState)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PREVIEW_FOV = 30 -- มุมมองแนวตั้ง (FieldOfView ของ Roblox เป็นแนวตั้ง)
local FIT_MARGIN = 1.05 -- เว้นขอบรอบโมเดลนิดเดียว (1 = ชิดขอบกรอบพอดี)

local ItemPreview = {}

-- ชื่อโมเดลของ Tool ในกระเป๋า (หุ่นไม่มี CropType จึงใช้ชื่อเดียวกับสินค้าในร้าน)
function ItemPreview.GetToolModelName(tool)
	if tool:GetAttribute("IsPetFood") then return "PetFood" end -- ถุงอาหารสัตว์ (ItemFactory ใส่รูปไว้)
	if tool:GetAttribute("IsFishingRod") then return "Rod_" .. tostring(tool:GetAttribute("RodId")) end -- เบ็ดตกปลา
	if tool:GetAttribute("IsPetRod") then return "PetRod_" .. tostring(tool:GetAttribute("PetRodId")) end -- เบ็ดนาก (โต๊ะช่างนากน้อย)
	if tool:GetAttribute("IsFish") then return "Fish_" .. tostring(tool:GetAttribute("FishId")) end -- ปลา
	if tool:GetAttribute("IsBait") then return "Bait" end -- กระปุกเหยื่อ
	if tool:GetAttribute("IsFurniture") then return "Furn:" .. tostring(tool:GetAttribute("FurnId")) end -- ของตกแต่ง (รูปจาก MountPreviewModels) 2026-10-16
	if tool:GetAttribute("IsDrink") then return "Drink_" .. tostring(tool:GetAttribute("DrinkId")) end
	if tool:GetAttribute("IsHeldBroom") then return "HeldBroom" end
	if tool:GetAttribute("IsOrchardTool") then return "OrchardTool_" .. tostring(tool:GetAttribute("OrchardToolId")) end -- ขวาน / บัวรดน้ำ (โมเดล AI) 2026-11-02
	if tool:GetAttribute("IsOrchardMat") then return "OrchardMat_" .. tostring(tool:GetAttribute("MatId")) end -- ท่อนไม้ / ปุ๋ยไม้ผล (OrchardItems สร้างรูป) 2026-11-02
	if tool:GetAttribute("IsKrathong") then return "Krathong_" .. tostring(tool:GetAttribute("KrathongId")) end -- กระทง (KrathongItems สำเนารูปให้) 2026-11-07
	if tool:GetAttribute("IsSlapHand") then return "SlapHand" end -- มือตบ (ItemPreviewModels.SlapHand) 2026-10-29
	if tool:GetAttribute("IsStealHand") and tool:GetAttribute("StealTier") == "Bandit" then return "BanditPicker" end -- ตะกร้อจอมโจร ดำทอง (ItemPreviewModels.BanditPicker) 2026-11-02
	if tool:GetAttribute("IsStealHand") then return "StealPicker" end -- ตะกร้อขโมย (ItemPreviewModels.StealPicker เอียงเฉียง ก๊อปจาก OrchardTemplates) 2026-10-29 -- ไม้กวาดกวาดเล้าไก่ (ItemPreviewModels.HeldBroom) 2026-10-23
	if tool:GetAttribute("IsHeldChicken") then return "HeldChicken_" .. tostring(tool:GetAttribute("ChickenLook")) end -- ไก่ที่อุ้มอยู่ (ChickenService สร้างโมเดลตัวอย่างตามสี+พันธุ์) 2026-10-21 -- แก้วจากบาร์ริมหาด (BarService สร้างโมเดลตัวอย่างไว้ให้) 2026-10-14
	if tool:GetAttribute("IsBooster") then
		-- หุ่นแต่ละระดับใช้โมเดลคนละตัว (x50 = หุ่นข้าวโพด, x100 = หุ่นโคลเวอร์) ดู PreviewName ใน LuckConfig
		local LuckConfig = require(ReplicatedStorage:WaitForChild("LuckConfig"))
		return LuckConfig.GetBoosterTier(tool:GetAttribute("BoosterTier")).PreviewName or "QualityBooster"
	end
	-- เมล็ด = ซองเมล็ด 3D (ItemFactory / OrchardItems สร้างโมเดล "SeedPacket_<พืช>") 2026-10-31
	if tool:GetAttribute("IsOrchardSeed") then return "SeedPacket_" .. tostring(tool:GetAttribute("FruitKind")) end
	if tool:GetAttribute("IsOrchardFruit") then return "OrchardFruit_" .. tostring(tool:GetAttribute("FruitKind")) end -- ผลไม้สวน (OrchardItems สร้างรูป แทนอีโมจิสีแดง) 2026-11-06
	if tool:GetAttribute("CropType") and not tool:GetAttribute("IsProduce") then
		return "SeedPacket_" .. tool:GetAttribute("CropType")
	end
	return tool:GetAttribute("CropType")
end

-- สร้าง ViewportFrame เต็ม parent คืน viewport หรือ nil ถ้าไม่มีโมเดลชื่อนี้
-- zoom (ไม่ใส่ = 1): มากกว่า 1 ซูมเข้าเกินกรอบได้ (ขอบบน-ล่างของโมเดลอาจโดนตัด) ใช้กับช่องเล็กๆ
-- folderOverride (ไม่ใส่ = ItemPreviewModels): โฟลเดอร์อื่น เช่น MountPreviewModels (แท็บสัตว์ขี่/ของตกแต่งในกระเป๋า 2026-10-16)
function ItemPreview.Create(parent, modelName, zoom, folderOverride)
	local folder = folderOverride or ReplicatedStorage:FindFirstChild("ItemPreviewModels")
	-- "Furn:<id>" = ของตกแต่งในแถบช่องด่วน ใช้โมเดลจาก MountPreviewModels
	if type(modelName) == "string" and string.sub(modelName, 1, 5) == "Furn:" then
		modelName = string.sub(modelName, 6)
		folder = ReplicatedStorage:FindFirstChild("MountPreviewModels")
	end
	local template = folder and modelName and folder:FindFirstChild(modelName)
	if not template then return nil end

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ItemPreview"
	viewport.Size = UDim2.new(1, 0, 1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = parent

	local model = template:Clone()
	model.Parent = viewport

	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = boxCFrame.Position
	local halfHeight = boxSize.Y / 2
	local halfWidth = math.max(boxSize.X, boxSize.Z) / 2 -- มองเฉียง เผื่อด้านที่กว้างกว่า
	-- หน้าหุ่นหันไปทาง LookVector ของ pivot เยื้องมุมนิดหน่อยให้ดูมีมิติ
	local pivot = model:GetPivot()
	local viewDirection = (pivot.LookVector + pivot.RightVector * 0.35).Unit

	local camera = Instance.new("Camera")
	camera.FieldOfView = PREVIEW_FOV
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- จัดระยะกล้องให้โมเดลเต็มกรอบพอดีตามสัดส่วนกรอบ (ช่อง hotbar กว้างกว่าสูง หุ่นทรงสูงจึงชนขอบบน-ล่าง)
	local tanVertical = math.tan(math.rad(PREVIEW_FOV / 2))
	local function fitCamera()
		local size = viewport.AbsoluteSize
		local aspect = (size.X > 0 and size.Y > 0) and (size.X / size.Y) or 1
		local tanHorizontal = tanVertical * aspect
		local distance = math.max(halfHeight / tanVertical, halfWidth / tanHorizontal) * FIT_MARGIN / (zoom or 1)
		-- ตอนซูมเกินกรอบ เลื่อนจุดมองขึ้นให้หัวยังอยู่ครบ ส่วนที่โดนตัดไปอยู่ด้านล่างแทน
		local focus = center + Vector3.new(0, halfHeight * (1 - 1 / (zoom or 1)), 0)
		camera.CFrame = CFrame.lookAt(focus + viewDirection * distance + Vector3.new(0, halfHeight * 0.15, 0), focus)
	end
	fitCamera()
	viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCamera)
	return viewport
end

return ItemPreview
