-- BACKUP of game.ServerScriptService.RodShowcase (full Source, 6637 bytes) taken 2026-11-26 before the Sakura Jellyfish rod.
-- Restore: in Studio open game.ServerScriptService.RodShowcase, select all, paste everything below this header.
-- RodShowcase: ตู้โชว์เบ็ด Robux ข้างร้านตกปลา (workspace.RodShowcase สร้างไว้ใน Studio 2026-10-08)
--   ตอนเริ่มเซิร์ฟเวอร์: เอาโมเดลเบ็ดจริงจาก ServerStorage.FishingTemplates.Rod_<RodId> มาวางลอยในตู้ (RodSlot) ตั้งเบ็ดชี้ขึ้น เอียงนิดๆ
--     (เทมเพลตเปลี่ยนหน้าตาเมื่อไหร่ ตู้โชว์เปลี่ยนตาม) หมุนช้าๆ + ป้ายค่าเบ็ด ทำฝั่งผู้เล่นใน StarterPlayerScripts.RodShowcaseFx
--   ปุ่ม "ซื้อ" หน้าตู้ (ProximityPrompt BuyRodPrompt): มีเบ็ดแล้ว = แจ้งว่ามีแล้ว / ปิดขาย = แจ้ง / ไม่งั้นเปิดหน้าต่างซื้อ Developer Product
--     (ให้ของหลังจ่ายเงินทำที่ FishingShop + PurchaseRouter เหมือนซื้อจากร้าน)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local templates = ServerStorage:WaitForChild("FishingTemplates")
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")
local showcase = workspace:WaitForChild("RodShowcase", 30)
if not showcase then return end

-- 2026-11-19 เบ็ด DevOnly (FishingConfig.IsHiddenRod) ในเซิร์ฟจริง: ลบตู้โชว์กับนากโชว์ของเบ็ดนั้นตอนเริ่มเซิร์ฟ (ใน Studio ยังอยู่ครบ)
for _, case in ipairs(showcase:GetChildren()) do
	if Config.IsHiddenRod(case:GetAttribute("RodId")) then case:Destroy() end
end
local otters = workspace:FindFirstChild("FishingOtters")
if otters then
	for _, npc in ipairs(otters:GetChildren()) do
		if Config.IsHiddenRod(npc:GetAttribute("RodId")) then npc:Destroy() end
	end
end

local TILT = math.rad(14) -- เอียงคันจากแนวตั้ง

local function placeRod(slot)
	local rodId = slot:GetAttribute("RodId")
	local template = rodId and templates:FindFirstChild("Rod_" .. rodId)
	if not template then return end
	local rod = template:Clone()
	rod.Name = "ShowcaseRod"
	rod:SetAttribute("RodId", rodId)
	for _, d in ipairs(rod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
		elseif d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	-- แกนคัน (ด้าม -> ปลาย) ให้ชี้ขึ้นเอียงไปด้านหลังตู้นิดๆ แล้ววางกึ่งกลางกรอบตรงจุด RodSlot
	local handle = rod:FindFirstChild("Handle")
	local tip = rod:FindFirstChild("RodTip", true)
	if handle and tip then
		local axis = (tip.WorldPosition - handle.Position).Unit
		local target = (slot.CFrame.UpVector * math.cos(TILT) - slot.CFrame.LookVector * math.sin(TILT)).Unit
		local cross = axis:Cross(target)
		local angle = math.acos(math.clamp(axis:Dot(target), -1, 1))
		if cross.Magnitude > 1e-4 then
			local pivot = rod:GetPivot()
			rod:PivotTo(CFrame.fromAxisAngle(cross.Unit, angle) * (pivot - pivot.Position) + pivot.Position)
		end
	end
	local cf, size = rod:GetBoundingBox()
	-- คันยาวเกินตู้ = ย่อให้พอดีความสูงกระจก
	local glass = slot.Parent:FindFirstChild("Glass")
	if glass and size.Y > glass.Size.Y - 0.4 then
		rod:ScaleTo(rod:GetScale() * (glass.Size.Y - 0.4) / size.Y)
		cf, size = rod:GetBoundingBox()
	end
	rod:PivotTo(rod:GetPivot() + (slot.Position - cf.Position))
	local accent = (rodId == "SunBee" and Color3.fromRGB(255, 200, 50)) or (rodId == "Phoenix" and Color3.fromRGB(255, 110, 40)) or (rodId == "Froggy" and Color3.fromRGB(120, 210, 90)) or Color3.fromRGB(165, 120, 255) -- Phoenix ส้มแดง (2026-11-19)
	local hl = Instance.new("Highlight")
	hl.Name = "ShowcaseGlow"
	hl.FillColor, hl.FillTransparency = accent, 0.8
	hl.OutlineColor, hl.OutlineTransparency = accent:Lerp(Color3.new(1, 1, 1), 0.5), 0.15
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = rod
	hl.Parent = rod
	rod:SetAttribute("SlotCenter", slot.Position)
	rod.Parent = slot.Parent
end

for _, d in ipairs(showcase:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "RodSlot" then
		local ok, err = pcall(placeRod, d)
		if not ok then warn("RodShowcase: วางเบ็ดในตู้ไม่สำเร็จ: " .. tostring(err)) end
	end
end

local function hasRod(player, rodId)
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, t in ipairs(loc and loc:GetChildren() or {}) do
			if t:IsA("Tool") and t:GetAttribute("IsFishingRod") and t:GetAttribute("RodId") == rodId then return true end
		end
	end
	return false
end

local lastPrompt = {}
for _, prompt in ipairs(showcase:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") and prompt.Name == "BuyRodPrompt" then
		prompt.Triggered:Connect(function(player)
			local rodId = prompt:GetAttribute("RodId")
			local rod = Config.Rods[rodId]
			if not rod then return end
			local now = os.clock()
			if now - (lastPrompt[player] or 0) < 1 then return end
			lastPrompt[player] = now
			local lang = Localization.GetLanguage(player)
			local name = Config.RodName(rodId, lang)
			if hasRod(player, rodId) then
				harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(lang, "✅ คุณมี" .. name .. "อยู่แล้ว (อยู่ในกระเป๋า)", "✅ You already own the " .. name))
				return
			end
			if rod.OnSale == false or not rod.RobuxPrice or (tonumber(rod.ProductId) or 0) <= 0 then
				harvestNotify:FireClient(player, nil, nil, nil, Localization.Pick(lang, "เบ็ดนี้ยังไม่เปิดขาย", "This rod is not for sale yet"))
				return
			end
			MarketplaceService:PromptProductPurchase(player, rod.ProductId)
		end)
	end
end
Players.PlayerRemoving:Connect(function(p) lastPrompt[p] = nil end)
