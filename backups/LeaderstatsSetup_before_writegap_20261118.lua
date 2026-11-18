-- BACKUP 2026-11-18 of game.ServerScriptService.LeaderstatsSetup before fix: DataStore write gap (request added to queue warning)
-- Restore: paste everything below this header into ServerScriptService.LeaderstatsSetup Source
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local coinsDataStore = DataStoreService:GetDataStore("PlayerCoins_v1")
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local DEFAULT_STARTING_COINS = 50
-- บัญชีใหม่จริง (โหลดสำเร็จแต่ไม่มีบันทึกเงิน) เริ่มที่จำนวนนี้ (ผู้ใช้สั่ง 2026-11-01) · แยกจาก DEFAULT ที่เป็นแค่ค่าชั่วคราวระหว่างรอโหลด
-- ของขวัญต้อนรับ StarterGift 100,000 ยังให้แยกต่างหาก
local NEW_ACCOUNT_COINS = 100000
local AUTOSAVE_INTERVAL = 300 -- เซฟเงินอัตโนมัติทุก 5 นาที กันข้อมูลหายถ้าเซิร์ฟเวอร์ล่มกะทันหัน (นอกจากเซฟตอนออกอยู่แล้ว)

local CROPS = { "Strawberry", "Corn", "Wheat", "Onion", "Watermelon", "Pineapple", "Potato", "Cucumber", "Eggplant", "Pumpkin", "WitchBerry", "Carrot", "Sunflower", "Chili" }

local function getCoinsValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("เหรียญ")
end

local coinsLoaded = {} -- [player] = true เมื่อโหลดเงินจาก DataStore สำเร็จ (โหลดไม่ได้ = ห้ามเซฟทับ ไม่งั้นเงินจริงหายเหลือค่าเริ่มต้น)
local lastSavedCoins = {}
local savingCoins = {}

local function saveCoins(player)
	local coins = getCoinsValue(player)
	if not coins or not coinsLoaded[player] then return end
	local value = coins.Value
	if value == lastSavedCoins[player] then return end -- เงินไม่เปลี่ยน ไม่ใช้คิว DataStore
	if savingCoins[player] then
		local deadline = os.clock() + 12
		repeat task.wait(0.1) until not savingCoins[player] or os.clock() >= deadline
		if savingCoins[player] then return end
		return saveCoins(player) -- เซฟค่าใหม่หลังงานก่อนหน้าเสร็จ
	end
	savingCoins[player] = true
	local ok, err = false, nil
	for attempt = 1, 3 do
		ok, err = pcall(function()
			coinsDataStore:SetAsync(tostring(player.UserId), value)
		end)
		if ok then break end
		if attempt < 3 then task.wait((2 ^ (attempt - 1)) + math.random()) end
	end
	savingCoins[player] = nil
	if ok then
		lastSavedCoins[player] = value
	else
		warn("LeaderstatsSetup: เซฟเงินไม่สำเร็จสำหรับ " .. player.Name .. " หลังลอง 3 ครั้ง: " .. tostring(err))
	end
end

-- สคริปต์อื่นสั่งเซฟเงินทันทีได้ (เช่น CoinTradeService หลังเทรดเงิน เซฟทั้งคนส่งและคนรับ ไม่รอรอบ 5 นาที) 2026-10-08
local saveNowEvent = Instance.new("BindableEvent")
saveNowEvent.Name = "SaveCoinsNow"
saveNowEvent.Parent = script
saveNowEvent.Event:Connect(function(player)
	if typeof(player) == "Instance" and player:IsA("Player") and player.Parent then task.spawn(saveCoins, player) end
end)
-- เซฟล่วงหน้าก่อนรีเซิร์ฟ (ServerScriptService.RestartNotice ยิงทีละคน) ตอนปิดจริงเงินไม่เปลี่ยน = ไม่เขียนซ้ำ (lastSavedCoins) 2026-10-09
task.spawn(function()
	local ev = game:GetService("ServerScriptService"):WaitForChild("PreRestartSave", 60)
	if ev then ev.Event:Connect(function(player)
		if typeof(player) == "Instance" and player:IsA("Player") and player.Parent then task.spawn(saveCoins, player) end
	end) end
end)

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local level = Instance.new("IntValue")
	level.Name = "เลเวล"
	level.Value = 1
	level.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "เหรียญ"
	coins.Value = DEFAULT_STARTING_COINS
	coins.Parent = leaderstats

	-- โหลดเงินที่เคยเก็บไว้จาก DataStore (ผู้เล่นใหม่ที่ยังไม่เคยมีข้อมูล จะใช้ค่าเริ่มต้นด้านบนแทน)
	local ok, savedCoins
	-- หลุดแล้วเข้าเซิร์ฟเดิมทันที: รอเซฟเงินของรอบก่อนเสร็จก่อนค่อยอ่าน (เคส kwanindy27 เห็น 900k แทน 1.2M) 2026-10-10
	DataLoadRetry.WaitLeaveSaves(player)
	for attempt = 1, 3 do
		DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
		ok, savedCoins = pcall(function()
			return coinsDataStore:GetAsync(tostring(player.UserId))
		end)
		if ok then break end
		warn("LeaderstatsSetup: โหลดเงินไม่สำเร็จ (ครั้งที่ " .. attempt .. ") " .. player.Name .. ": " .. tostring(savedCoins))
		if attempt < 3 then task.wait((2 ^ (attempt - 1)) + math.random()) end
	end
	if ok and savedCoins ~= nil then
		coins.Value = savedCoins
	end
	-- โหลดสำเร็จแต่ไม่มีข้อมูลเลย = ผู้เล่นใหม่ (StarterGift แจกของขวัญต้อนรับเฉพาะคนนี้)
	if ok and savedCoins == nil then
		coins.Value = NEW_ACCOUNT_COINS
		player:SetAttribute("IsNewPlayer", true)
	end
	if ok then
		coinsLoaded[player] = true
		if savedCoins ~= nil then lastSavedCoins[player] = coins.Value end
		player:SetAttribute("CoinsLoaded", true) -- สคริปต์อื่นที่จะเพิ่มเงินตอนเข้าเกม (เช่น แพ็กสุลต่าน) รอตัวนี้ก่อน
	else
		-- โหลดไม่ได้ 3 ครั้ง (DataStore throttle ตอนคนเข้าพร้อมกัน): ลองต่อเบื้องหลังจนได้ (2026-10-09)
		-- เดิมค้างเงินเริ่มต้น 50 ทั้งรอบ (ไม่เซฟทับ เงินไม่หาย แต่ผู้เล่นตกใจ) · ได้แล้ว = เงินจริง + ส่วนที่ได้/จ่ายระหว่างรอ (เทียบกับ 50)
		DataLoadRetry.Background(player, "LeaderstatsSetup", DataLoadRetry.Get(coinsDataStore, tostring(player.UserId)), function(saved)
			if coinsLoaded[player] or not coins.Parent then return end
			local delta = coins.Value - DEFAULT_STARTING_COINS
			if saved ~= nil then
				coins.Value = math.max(0, math.floor(tonumber(saved) or 0) + delta)
				lastSavedCoins[player] = saved
			else
				coins.Value = math.max(0, NEW_ACCOUNT_COINS + delta)
				player:SetAttribute("IsNewPlayer", true)
			end
			coinsLoaded[player] = true
			player:SetAttribute("CoinsLoaded", true)
		end)
	end

	-- ตัวนับจำนวนพืชที่เก็บเกี่ยวได้ แยกไว้คนละโฟลเดอร์กับ leaderstats โดยตั้งใจ
	-- (ถ้าใส่ไว้ใน leaderstats กระดานคะแนนของ Roblox จะโชว์ทุกช่องอัตโนมัติ ทำให้กระดานรกเกินไป)
	local cropStats = Instance.new("Folder")
	cropStats.Name = "CropStats"
	cropStats.Parent = player

	local strawberries = Instance.new("IntValue")
	strawberries.Name = "สตรอว์เบอร์รี่"
	strawberries.Value = 0
	strawberries.Parent = cropStats

	local corns = Instance.new("IntValue")
	corns.Name = "ข้าวโพด"
	corns.Value = 0
	corns.Parent = cropStats

	local wheats = Instance.new("IntValue")
	wheats.Name = "ข้าวสาลี"
	wheats.Value = 0
	wheats.Parent = cropStats

	local onions = Instance.new("IntValue")
	onions.Name = "หัวหอม"
	onions.Value = 0
	onions.Parent = cropStats

	local watermelons = Instance.new("IntValue")
	watermelons.Name = "แตงโม"
	watermelons.Value = 0
	watermelons.Parent = cropStats

	local pineapples = Instance.new("IntValue")
	pineapples.Name = "สับปะรด"
	pineapples.Value = 0
	pineapples.Parent = cropStats

	local potatoes = Instance.new("IntValue")
	potatoes.Name = "มันฝรั่ง"
	potatoes.Value = 0
	potatoes.Parent = cropStats

	local cucumbers = Instance.new("IntValue")
	cucumbers.Name = "แตงกวา"
	cucumbers.Value = 0
	cucumbers.Parent = cropStats

	local eggplants = Instance.new("IntValue")
	eggplants.Name = "มะเขือยาว"
	eggplants.Value = 0
	eggplants.Parent = cropStats

	-- คลังผลผลิตแยกตามชนิดพืช + ดาว (เช่น Strawberry_3 = สตรอว์เบอร์รี่ 3 ดาว)
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	for _, crop in ipairs(CROPS) do
		for star = 1, 5 do
			local val = Instance.new("IntValue")
			val.Name = crop .. "_" .. star
			val.Value = 0
			val.Parent = inventory
		end
	end

	-- เซฟเงินอัตโนมัติเป็นระยะๆ ตลอดที่ผู้เล่นยังอยู่ในเกม (เผื่อออกแบบไม่ปกติ/เซิร์ฟเวอร์ล่ม)
	task.spawn(function()
		task.wait(math.random(5, 40)) -- กระจายรอบเซฟของผู้เล่นที่เข้าใกล้กัน
		while player.Parent do
			task.wait(AUTOSAVE_INTERVAL + math.random(0, 30))
			if player.Parent then
				saveCoins(player)
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	DataLoadRetry.BeginLeaveSave(userId) -- รอบใหม่ที่เข้ามาเร็วจะรอเซฟนี้เสร็จก่อนโหลด
	task.wait() -- ให้สคริปต์อื่นที่ผูกกับ PlayerRemoving เหมือนกัน (เช่น PlantingSystem คืนเงินค่าเมล็ดให้อัตโนมัติ) ทำงานเสร็จก่อน แล้วค่อยเซฟ กันเงินตกหล่น
	pcall(saveCoins, player)
	DataLoadRetry.EndLeaveSave(userId)
	coinsLoaded[player] = nil
	lastSavedCoins[player] = nil
end)

-- เผื่อเซิร์ฟเวอร์ถูกปิด/รีสตาร์ทกะทันหัน เซฟเงินของทุกคนที่ยังออนไลน์อยู่ก่อนปิดจริง
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveCoins(player)
	end
end)