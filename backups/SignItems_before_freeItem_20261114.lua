-- BACKUP 2026-11-14 before free reusable sign item (no shop)
-- Studio path: game.ServerScriptService.Sign.SignItems (ModuleScript)
-- Restore: paste everything below this header into that script's Source in Studio

-- SignItems (2026-11-14): ป้ายเขียนข้อความในกระเป๋า (Tool IsSign) อันละ 1 ชิ้น ไม่รวมกอง (แต่ละอันมีข้อความของตัวเอง)
-- เซฟกับกระเป๋าปกติ: InventorySystem kind "Sign" { text = ข้อความที่พิมพ์จริง } (กรองใหม่ทุกครั้งที่โหลด แบบ VipService)
-- ข้อความดิบเก็บฝั่งเซิร์ฟเท่านั้น (rawOf) บน Tool มีแต่ Attribute SignText = ข้อความที่กรองแล้ว เซิร์ฟตั้ง TextLabel เอง ทุกคนเห็นเหมือนกัน
-- ป้ายที่ปักอยู่ (SignService) นับเป็นของในกระเป๋าด้วย (PlacedEntries) ออกเกมตอนปักอยู่ = กลับมาอยู่ในกระเป๋า

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Config = require(ReplicatedStorage:WaitForChild("SignConfig"))
local models = ReplicatedStorage:WaitForChild("SignModels")

local SignItems = {}
SignItems.ATTR = "IsSign"

local rawOf = setmetatable({}, { __mode = "k" }) -- [tool] = ข้อความดิบ (เซิร์ฟเท่านั้น)
SignItems.placed = {} -- [userId] = { { model, raw }, ... } ป้ายที่ปักอยู่ (SignService ดูแล)

-- รูปในกระเป๋า/แถบไอเทม (ItemPreview ชื่อ "Sign")
do
	local previewFolder = ReplicatedStorage:FindFirstChild("ItemPreviewModels")
	if previewFolder and not previewFolder:FindFirstChild("Sign") then
		local m = models.Sign:Clone()
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("TextLabel") then d.Text = "ABC" end
		end
		m.Parent = previewFolder
	end
end

-- กรองข้อความให้ทุกคนเห็น (แบบ VipService) คืน nil ถ้ากรองไม่สำเร็จ · Studio ไม่กรองจริง (คืนข้อความเดิม)
function SignItems.Filter(player, text)
	if text == "" then return "" end
	for attempt = 1, 2 do
		local ok, result = pcall(function()
			local filtered = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
			return filtered:GetNonChatStringForBroadcastAsync()
		end)
		if ok and type(result) == "string" then return result end
		warn("SignItems: กรองข้อความไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(result))
		task.wait(1)
	end
	return nil
end

local function toolName(shown, lang)
	if shown == nil or shown == "" then
		return lang == "en" and "Blank sign" or "ป้ายเปล่า"
	end
	return (lang == "en" and "Sign: " or "ป้าย: ") .. shown
end

-- ตั้งข้อความที่แสดง (กรองแล้วเท่านั้น) บน Tool หรือ Model ป้ายที่ปัก
function SignItems.SetShown(obj, shown, lang)
	shown = shown or ""
	obj:SetAttribute("SignText", shown)
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("TextLabel") and d.Name == "SignText" then d.Text = shown end
	end
	if obj:IsA("Tool") then obj.Name = toolName(shown, lang) end
end

-- กรอง raw แล้วตั้งข้อความ (รอได้) กรองไม่ได้/โดนปิดหมด = แสดงเป็นป้ายเปล่า (ข้อความดิบยังเก็บไว้ ลองกรองใหม่รอบหน้า)
function SignItems.ApplyRaw(player, obj, raw, lang)
	if raw == nil or raw == "" then
		SignItems.SetShown(obj, "", lang)
		return ""
	end
	local filtered = SignItems.Filter(player, raw)
	if filtered == nil or Config.FullyBlocked(filtered) then
		SignItems.SetShown(obj, "", lang)
		return filtered
	end
	if obj.Parent ~= nil then SignItems.SetShown(obj, filtered, lang) end
	return filtered
end

-- สร้าง Tool ไม่ parent ให้เอง · raw ไม่ว่าง = กรองเบื้องหลังแล้วค่อยขึ้นข้อความ (ตอนโหลดกระเป๋าไม่รอตัวกรอง)
function SignItems.Create(player, raw, lang)
	raw = type(raw) == "string" and raw or ""
	local tool = Instance.new("Tool")
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute(SignItems.ATTR, true)
	tool:SetAttribute("Count", 1)
	local copy = models.Sign:Clone()
	local handle = copy.Handle
	for _, p in ipairs(copy:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
		end
	end
	for _, p in ipairs(copy:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = handle, p
			w.Parent = p
			p.Parent = tool
		end
	end
	handle.Parent = tool
	copy:Destroy()
	-- จับเสาช่วงล่าง แผ่นป้ายชูเหนือหัว (เสาแกนยาว = Y ของ Handle)
	tool.Grip = Config.GRIP or CFrame.new(0, -1.1, 0)
	rawOf[tool] = raw
	SignItems.SetShown(tool, "", lang)
	if raw ~= "" then
		task.spawn(SignItems.ApplyRaw, player, tool, raw, lang)
	end
	return tool
end

function SignItems.RawOf(tool)
	return rawOf[tool] or ""
end

function SignItems.SetRaw(tool, raw)
	rawOf[tool] = raw
end

function SignItems.Give(player, raw, lang)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return nil end
	local tool = SignItems.Create(player, raw, lang)
	tool.Parent = backpack
	return tool
end

-- ป้ายทั้งหมดที่ถือ/อยู่ในกระเป๋า
function SignItems.Tools(player)
	local out = {}
	for _, loc in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if loc then
			for _, t in ipairs(loc:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute(SignItems.ATTR) then table.insert(out, t) end
			end
		end
	end
	return out
end

function SignItems.Held(player)
	local t = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
	return (t and t:GetAttribute(SignItems.ATTR)) and t or nil
end

function SignItems.PlacedCount(player)
	local list = SignItems.placed[player.UserId]
	return list and #list or 0
end

-- สำหรับ InventorySystem: ป้ายที่ปักอยู่นับเป็นของในกระเป๋า (เซฟตอนออกเกมแล้วกลับมาอยู่ในกระเป๋า)
function SignItems.PlacedEntries(player)
	local out = {}
	for _, rec in ipairs(SignItems.placed[player.UserId] or {}) do
		table.insert(out, { kind = "Sign", text = rec.raw or "", count = 1 })
	end
	return out
end

return SignItems
