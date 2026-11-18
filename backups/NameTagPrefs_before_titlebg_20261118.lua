-- BACKUP of StarterPlayer.StarterPlayerScripts.NameTagPrefs (LocalScript) before the title-background change, 2026-11-18
-- Restore: paste everything below the "-- ==== SOURCE ====" line into the script's Source in Studio.
-- ==== SOURCE ====
-- NameTagPrefs: แสดง/ซ่อน "ชื่อบนหัว" และ "สถานะบนหัว" ของผู้เล่นทุกคน เฉพาะบนเครื่องนี้ (2026-10-11 ผู้ใช้ขอ ปุ่มอยู่ในหน้าต่างกราฟิก)
-- ป้ายเหนือหัวสร้างโดยเซิร์ฟเวอร์ (ServerScriptService.PlayerNameTags: BillboardGui "PlayerNameTag" ใน Head)
--   ชื่อ   = แถว Icons (ธง+อุปกรณ์), VipBadge (ป้าย VIP/สุลต่าน), PlayerName
--   สถานะ = แถว Title (สถานะ/ฉายาที่ผู้เล่นตั้ง), Typing ("กำลังพิมพ์...")
-- สวิตช์ = Attribute บนตัวผู้เล่น (ตั้งฝั่งผู้เล่น): HideNameTags / HideStatusTags · GraphicsGui เป็นคนเปลี่ยน · ค่าที่จำไว้มาจาก GraphicsPrefs
-- เซิร์ฟเวอร์เป็นคนตั้ง Visible ของแต่ละแถว ฝั่งนี้จึงคำนวณ "ควรแสดงไหม" จาก Attribute ของเจ้าของป้ายเอง (กติกาเดียวกับ updateTag)
-- แล้วคูณกับสวิตช์ — เปิดคืนแล้วได้ค่าที่ถูกเสมอ · เซิร์ฟเวอร์เปลี่ยน Visible ทีหลัง = คำนวณซ้ำ

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GraphicsConfig = require(ReplicatedStorage:WaitForChild("GraphicsConfig"))

local player = Players.LocalPlayer
local TAG_NAME = "PlayerNameTag"
local NAME_ROWS = { "Icons", "VipBadge", "PlayerName" }
local STATUS_ROWS = { "Title", "Typing" }

local hooked = setmetatable({}, { __mode = "k" }) -- [tag] = owner player
local applying = false

local function wanted(owner, tag, rowName)
	local isVip = owner:GetAttribute("IsSultan") == true or owner:GetAttribute("IsVip") == true
	if rowName == "PlayerName" then return true end
	if rowName == "VipBadge" then return isVip end
	if rowName == "Icons" then
		local icons = tag:FindFirstChild("Icons")
		return icons ~= nil and icons.Text ~= ""
	end
	if rowName == "Title" then return isVip and (owner:GetAttribute("VipTitle") or "") ~= "" end
	if rowName == "Typing" then return owner:GetAttribute("IsTyping") == true end
	return true
end

local function applyTag(tag, owner)
	if applying then return end
	applying = true
	local hideNames = player:GetAttribute("HideNameTags") == true
	local hideStatus = player:GetAttribute("HideStatusTags") == true
	for _, rowName in ipairs(NAME_ROWS) do
		local row = tag:FindFirstChild(rowName)
		if row then row.Visible = (not hideNames) and wanted(owner, tag, rowName) end
	end
	for _, rowName in ipairs(STATUS_ROWS) do
		local row = tag:FindFirstChild(rowName)
		if row then row.Visible = (not hideStatus) and wanted(owner, tag, rowName) end
	end
	applying = false
end

-- บั๊ก 2026-10-18 (ผู้ใช้: สถานะบนหัวบางทีไม่แสดงทั้งที่เปิดอยู่ ต้องปิดเปิดใหม่):
--   เดิมคำนวณใหม่เฉพาะตอน Visible ของแถวเปลี่ยน ถ้า Visible = true มาถึงก่อน Attribute VipTitle/IsVip ของเจ้าของป้าย
--   จะคำนวณว่า "ไม่มีสถานะ" แล้วซ่อนทิ้งค้าง (Attribute มาทีหลังไม่มีอะไรสั่งคำนวณใหม่)
--   แก้: ฟัง Attribute ของเจ้าของป้ายด้วย + คำนวณซ้ำอีกทีหลังเฟรมถัดไป + ตรวจซ้ำทุกป้ายทุก 3 วิ (กันพลาดทุกกรณี)
local OWNER_ATTRS = { "IsVip", "IsSultan", "VipTitle", "IsTyping" }
local function hook(tag, owner)
	if hooked[tag] then return end
	hooked[tag] = owner
	local function reapply()
		if not tag.Parent then return end
		applyTag(tag, owner)
		task.delay(0.3, function() if tag.Parent then applyTag(tag, owner) end end) -- ค่าที่มาคนละจังหวะกัน (Visible ก่อน Attribute)
	end
	local conns = {}
	for _, attr in ipairs(OWNER_ATTRS) do
		table.insert(conns, owner:GetAttributeChangedSignal(attr):Connect(reapply))
	end
	tag.AncestryChanged:Connect(function()
		if not tag:IsDescendantOf(game) then
			for _, c in ipairs(conns) do c:Disconnect() end
			table.clear(conns)
		end
	end)
	for _, list in ipairs({ NAME_ROWS, STATUS_ROWS }) do
		for _, rowName in ipairs(list) do
			local row = tag:FindFirstChild(rowName)
			if row then
				row:GetPropertyChangedSignal("Visible"):Connect(reapply)
				if rowName == "Icons" then row:GetPropertyChangedSignal("Text"):Connect(reapply) end
			end
		end
	end
	applyTag(tag, owner)
end

local function applyAll()
	for tag, owner in pairs(hooked) do
		if tag.Parent then applyTag(tag, owner) end
	end
end

-- หาป้ายใหม่เป็นระยะ (ตัวละครเกิดใหม่ / โหลดเข้ามาทีหลังเพราะแมพโหลดทีละส่วน) ผู้เล่นไม่เกิน 30 คน = งานเล็ก
local function scan()
	for _, owner in ipairs(Players:GetPlayers()) do
		local character = owner.Character
		local head = character and character:FindFirstChild("Head")
		local tag = head and head:FindFirstChild(TAG_NAME)
		if tag and not hooked[tag] and tag:FindFirstChild("PlayerName") and tag:FindFirstChild("Title") then
			hook(tag, owner)
		end
	end
end

player:GetAttributeChangedSignal("HideNameTags"):Connect(applyAll)
player:GetAttributeChangedSignal("HideStatusTags"):Connect(applyAll)

task.spawn(function()
	local tick = 0
	while true do
		scan()
		tick += 1
		if tick % 3 == 0 then applyAll() end -- ตรวจซ้ำทุก 3 วิ (ผู้เล่นไม่เกิน 30 คน งานเล็ก)
		task.wait(1)
	end
end)

-- ค่าที่เคยตั้งไว้ (GraphicsPrefs ตั้ง SavedHide... ก่อน GraphicsLoaded) ผู้เล่นกดเองไปก่อนแล้ว = ไม่ทับ
local deadline = os.clock() + 8
while not player:GetAttribute(GraphicsConfig.LOADED_ATTRIBUTE) and os.clock() < deadline do task.wait(0.2) end
if player:GetAttribute("HideNameTags") == nil then
	player:SetAttribute("HideNameTags", player:GetAttribute("SavedHideNameTags") == true)
end
if player:GetAttribute("HideStatusTags") == nil then
	player:SetAttribute("HideStatusTags", player:GetAttribute("SavedHideStatusTags") == true)
end
