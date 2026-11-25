-- BACKUP of StarterPlayer.StarterPlayerScripts.PromptLocalizer before Thai/English world signs (i18n phase 4, 2026-11-23)
-- Restore: paste everything below this header into StarterPlayer.StarterPlayerScripts.PromptLocalizer.Source in Studio
-- PromptLocalizer: แปลงข้อความ ProximityPrompt (ป้าย E / "ปลูกผัก" / "เก็บเกี่ยว" ฯลฯ) เป็นอังกฤษให้ผู้เล่นที่ Roblox เป็นอังกฤษ (หลายภาษา 2026-10-03)
-- เหตุผล: ProximityPrompt เป็น Instance เดียวที่เซิร์ฟเวอร์สร้างให้ทุกคนเห็นข้อความเดียวกัน แยกภาษาต่อผู้เล่นจากเซิร์ฟเวอร์ไม่ได้
--   เซิร์ฟเวอร์ตั้งเป็นไทยไว้ ไคลเอนต์ภาษาอังกฤษแก้ข้อความบนเครื่องตัวเองเท่านั้น (ไม่กระทบคนอื่น)
-- เพิ่มป้ายใหม่: ใส่ข้อความไทย -> อังกฤษใน OBJECT / ACTION ด้านล่าง
-- ภาษาไทย = ไม่ทำอะไรเลย

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _, lang = require(ReplicatedStorage:WaitForChild("Localization")).Tr()
if lang ~= "en" then return end

local OBJECT = {
	["แปลงดิน"] = "Farm plot",
	["ป้ายผู้สนับสนุน"] = "Supporter board",
	["ร้านเมล็ดพันธุ์"] = "Seed Shop",
	["🎣 ร้านตกปลา"] = "🎣 Fishing Shop",
	["🎁 ตู้สุ่มสัตว์เลี้ยง"] = "🎁 Pet Gacha",
	["🐴 ตู้สุ่มสัตว์ขี่"] = "🐴 Mount Gacha",
	["🥫 เครื่องทำอาหารสัตว์"] = "🥫 Pet Food Maker",
	["🔨 โต๊ะช่างนากน้อย"] = "🔨 Otter's Workshop",
	["🚣 เรือพาย"] = "🚣 Rowboat",
	["🥊 สนามมวยนากบัญชา"] = "🥊 Otter Boxing Ring",
	["🦦 น้องนากเก็บขยะ"] = "🦦 Cleanup Otter",
	["🍹 บาร์ริมหาด"] = "🍹 Beach Bar",
	["น้องนากรับโค้ด"] = "Code Otter", -- NPC แลกโค้ด (2026-10-18)
	["🔨 ค้อนยาง"] = "🔨 Toy Hammer", -- แท่นค้อนหน้าตู้สุ่มสัตว์ขี่ (2026-10-19)
	["🏠 เล้าไก่"] = "🏠 Chicken Coop", -- ระบบเลี้ยงไก่ (2026-10-20)
	["🥣 รางอาหารไก่"] = "🥣 Feed Trough",
	["🥚 แผงเก็บไข่"] = "🥚 Egg Tray",
	["🐔 ลุงไข่ขายไก่"] = "🐔 Chicken Merchant",
	["🥚 ตู้ฟักไข่"] = "🥚 Incubator",
	["🧺 ร้านสวนผลไม้"] = "🧺 Orchard Stall", -- สวนผลไม้ (2026-10-25)
	["🥭 ร้านผลไม้ & อุปกรณ์"] = "🥭 Fruit & Tools", -- แผงทางเข้าสวนมะม่วง (2026-10-27)
	["🥭 มะม่วง"] = "🥭 Mango",
	["🍈 ทุเรียน"] = "🍈 Durian",
	["🎹 เปียโน"] = "🎹 Piano", -- เปียโนบนเวทีริมหาด (2026-10-29)
}
local ACTION = {
	["หยิบค้อน"] = "Grab hammer",
	["ดูไก่ของฉัน"] = "My chickens", -- บ้านไก่ (2026-10-20)
	["เติมอาหาร"] = "Add food",
	["ผสมพันธุ์ไก่"] = "Breed chickens",
	["ขายไข่"] = "Sell eggs",
	["ซื้อไก่"] = "Buy chickens",
	["ปลูกผัก"] = "Plant",
	["สนับสนุนเกม 💝"] = "Support the game 💝",
	["เปิดร้านค้า"] = "Open shop",
	["เปิดร้าน"] = "Open shop",
	["เปิดตู้สุ่ม"] = "Open gacha",
	["เปิดเครื่อง"] = "Open machine",
	["ให้อาหาร"] = "Feed",
	["เก็บเกี่ยว"] = "Harvest",
	["เปิดโต๊ะคราฟ"] = "Open workbench",
	["นั่งเรือ"] = "Sit",
	["ขึ้นชก มุมแดง"] = "Fight (red corner)",
	["ขึ้นชก มุมน้ำเงิน"] = "Fight (blue corner)",
	["คุยกับน้องนาก"] = "Talk",
	["สั่งเครื่องดื่ม"] = "Order a drink",
	["แลกโค้ด"] = "Redeem code",
	["เล่นเปียโน"] = "Play piano",
}

local function translateObject(s)
	if OBJECT[s] then return OBJECT[s] end
	local owner = s:match("^ต้นของ (.+)$")
	if owner then return owner .. "'s plant" end
	return s
end
local function translateAction(s)
	if ACTION[s] then return ACTION[s] end
	local rest = s:match("^เก็บเกี่ยว (.+)$") -- "เก็บเกี่ยว ⭐⭐⭐"
	if rest then return "Harvest " .. rest end
	return s
end

local function fix(prompt)
	local function apply()
		local o, a = translateObject(prompt.ObjectText), translateAction(prompt.ActionText)
		if o ~= prompt.ObjectText then prompt.ObjectText = o end
		if a ~= prompt.ActionText then prompt.ActionText = a end
	end
	apply()
	prompt:GetPropertyChangedSignal("ObjectText"):Connect(apply)
	prompt:GetPropertyChangedSignal("ActionText"):Connect(apply)
end

-- ป้ายชื่อเหนือหัว (PlayerNameTags สร้างจากเซิร์ฟเวอร์ ทุกคนเห็นแบบเดียวกัน): "กำลังพิมพ์..." -> "Typing..."
local function fixTag(d)
	if d:IsA("TextLabel") and d.Name == "Typing" and d.Parent and d.Parent.Name == "PlayerNameTag" then
		d.Text = "Typing..."
	end
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then fix(d) else fixTag(d) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then
		fix(d)
	elseif d:IsA("TextLabel") and d.Name == "Typing" then
		task.defer(fixTag, d) -- รอให้ได้พ่อ (PlayerNameTag) ก่อน
	end
end)
