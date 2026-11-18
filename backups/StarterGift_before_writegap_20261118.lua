-- BACKUP 2026-11-18 of game.ServerScriptService.StarterGift before fix: DataStore write gap (request added to queue warning)
-- Restore: paste everything below this header into ServerScriptService.StarterGift Source
-- StarterGift: เงินเริ่มต้น 100,000 เหรียญ ให้ครั้งเดียวต่อบัญชี
-- 2026-10-27 ปิดบทเรียนผู้เล่นใหม่: ทุกคนได้หุ่นทองคำนำโชค x100 ทันที (เดิมผู้เล่นใหม่ได้หลังทำบทเรียนครบ)
--   ผู้เล่นใหม่ (IsNewPlayer) ได้เมล็ดข้าวสาลี STARTER_SEEDS ถุงด้วย (เดิม TutorialService แจกตอนขั้นปลูก)
-- DataStore "StarterGift_v1": { given = true } คนที่รับเงินเริ่มต้นแล้วไม่รับซ้ำ
--   จดว่าแจกแล้วด้วย UpdateAsync ก่อนให้ของ (หลายเซิร์ฟเวอร์พร้อมกันก็ได้ครั้งเดียว)
-- บทเรียน (TutorialService) ข้ามผู้เล่นที่มีเงิน >= 5,000: ตั้ง Attribute "StarterGiftCoins" ก่อนเติมเงิน ให้ TutorialService หักออกก่อนเทียบ
-- ใน Studio ไม่แจกของจริง (กันกินสิทธิ์ครั้งเดียวของบัญชีนักพัฒนาตอนกดเล่นทดสอบ จะได้ในเกมจริงแทน)
--   ทดสอบ: ตั้ง Attribute บน workspace (ใน Edit mode แล้วลบทิ้งหลังทดสอบ) "DevStarterGiftTest" = true
--   ใช้คีย์ "test_<userId>" ไม่แตะบันทึกจริง ไม่เซฟเงินจริง
-- (เดิมแยกผู้เล่นใหม่ 100,000 / ผู้เล่นเก่า 10,000 ด้วย Attribute IsNewPlayer ของ LeaderstatsSetup ตอนนี้ไม่ต้องแยกแล้ว Attribute ยังตั้งอยู่เผื่อใช้ต่อ)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ItemFactory = require(ServerScriptService:WaitForChild("ItemFactory"))
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local COINS = 100000
local BOOSTER_TIER = "x100"
local BOOSTER_COUNT = 1
local STARTER_SEEDS = 5

local store = DataStoreService:GetDataStore("StarterGift_v1")
local coinsStore = DataStoreService:GetDataStore("PlayerCoins_v1")

local function waitFor(player, attr, timeout)
	local waited = 0
	while player.Parent and not player:GetAttribute(attr) and waited < timeout do waited += task.wait(0.5) end
	return player.Parent ~= nil and player:GetAttribute(attr) ~= nil
end

local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))

-- เมล็ดเริ่มต้นผู้เล่นใหม่ (ย้ายมาจาก TutorialService.onEnterStep ขั้นปลูก) มีถุงข้าวสาลีอยู่แล้ว = รวมเข้าถุงเดิม
local function giveStarterSeeds(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end
	for _, loc in ipairs({ backpack, player.Character }) do
		for _, t in ipairs(loc and loc:GetChildren() or {}) do
			if t:IsA("Tool") and t:GetAttribute("CropType") == "Wheat" and not t:GetAttribute("IsProduce") then
				local n = (t:GetAttribute("Count") or 1) + STARTER_SEEDS
				t:SetAttribute("Count", n)
				t.Name = "Wheat x" .. n
				return
			end
		end
	end
	ItemFactory.CreateSeedTool("Wheat", STARTER_SEEDS).Parent = backpack
end
local function giveStarterGift(player)
	local testMode = RunService:IsStudio() and workspace:GetAttribute("DevStarterGiftTest") == true
	if RunService:IsStudio() and not testMode then return end
	if not (waitFor(player, "CoinsLoaded", 90) and waitFor(player, "InventoryReady", 90)) then return end
	-- ไม่เร่งด่วน: หลีกทางให้ของสำคัญโหลดก่อน (2026-10-13)
	if not DataLoadRetry.Defer(player, "StarterGift") then return end
	-- 2026-11-18 เช็กเงิน+กระเป๋าก่อนจดว่าแจกแล้ว (เดิมจดก่อน แล้วไม่มีเงิน/ให้หุ่นพัง = สิทธิ์หาย)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("เหรียญ")
	if not coins or not ItemFactory.FindBackpack(player) then return end

	local key = (testMode and "test_" or "") .. tostring(player.UserId)
	local claimed = false
	local ok, err
	for attempt = 1, 3 do
		ok, err = pcall(function()
			store:UpdateAsync(key, function(old)
				if type(old) == "table" and (old.given or old.veteran) then claimed = false return nil end
				claimed = true
				return { given = true, t = os.time() }
			end)
		end)
		if ok then break end
		warn("StarterGift: จดว่าแจกแล้วไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(err))
		task.wait(2)
	end
	if not ok or not claimed then return end

	-- หุ่นก่อน (พังได้ถ้ากระเป๋าหาย) พัง = คืนสิทธิ์ (given = false) ยังไม่ให้เงิน ได้ครบตอนเข้าเกมครั้งถัดไป
	local okGive, gErr = false, "player left"
	if player.Parent then okGive, gErr = pcall(ItemFactory.GiveBoosterTool, player, BOOSTER_COUNT, BOOSTER_TIER) end
	if not okGive then
		local okBack, bErr = pcall(function()
			store:UpdateAsync(key, function(old)
				if type(old) == "table" and old.veteran then return nil end
				return { given = false, t = os.time() }
			end)
		end)
		warn("StarterGift: ให้หุ่นไม่สำเร็จ " .. player.Name .. " (" .. tostring(gErr) .. ") คืนสิทธิ์: " .. (okBack and "สำเร็จ" or ("ไม่สำเร็จ " .. tostring(bErr))))
		return
	end
	player:SetAttribute("StarterGiftCoins", COINS) -- ก่อนเติมเงิน: TutorialService หักออกตอนเช็กว่าเป็นผู้เล่นเก่าไหม
	coins.Value += COINS
	if player:GetAttribute("IsNewPlayer") == true then giveStarterSeeds(player) end
	if not testMode then
		-- เซฟเงินทันที (ไม่รอเซฟอัตโนมัติ 5 นาที) กันเซิร์ฟเวอร์ล่มแล้วของขวัญหายทั้งที่จดว่าแจกแล้ว
		pcall(function() coinsStore:SetAsync(tostring(player.UserId), coins.Value) end)
	end
	-- รอหน้าจอผู้เล่นโหลดก่อนค่อยแจ้ง
	task.wait(6)
	if player.Parent then
		local message = player:GetAttribute("IsNewPlayer") == true
			and Localization.Pick(Localization.GetLanguage(player),
				"🎁 ของขวัญต้อนรับ! 💰 100,000 เหรียญ · 🍀 หุ่นทองคำนำโชค 1 อัน · 🌱 เมล็ดข้าวสาลี " .. STARTER_SEEDS .. " ถุง · 🎣 เบ็ดไม้ไผ่ (ดูในกระเป๋า 🎒)",
				"🎁 Welcome gift! 💰 100,000 coins · 🍀 1 golden luck scarecrow · 🌱 " .. STARTER_SEEDS .. " wheat seeds · 🎣 bamboo rod (check your bag 🎒)")
			or "🎁 ของขวัญสำหรับคุณ! 💰 100,000 เหรียญ · 🍀 หุ่นทองคำนำโชค 1 อัน · 🎣 เบ็ดไม้ไผ่ (ดูในกระเป๋า 🎒)"
		harvestNotify:FireClient(player, nil, nil, nil, message)
	end
	print("🎁 StarterGift: แจกของขวัญให้ " .. player.Name .. (testMode and " (ทดสอบ)" or ""))
end

Players.PlayerAdded:Connect(function(player) task.spawn(giveStarterGift, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(giveStarterGift, player) end
