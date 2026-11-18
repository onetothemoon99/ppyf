-- BACKUP of ReplicatedStorage.Localization before the EXP scarecrow change (2026-11-19)
-- Restore: paste everything below this 3-line header into ReplicatedStorage.Localization.Source in Studio
-- bytes=25524 sum=13164330
-- Localization: ศูนย์กลางคำแปลไทย/อังกฤษ ให้ทุกสคริปต์ดึงไปใช้แทนพิมพ์ข้อความตรงๆ
-- วางเป็น ModuleScript ไว้ใน ReplicatedStorage (ให้ทั้งฝั่งเซิร์ฟเวอร์และไคลเอนต์ require ได้)

local Localization = {}

local STRINGS = {
	th = {
		-- ชื่อพืช/ไอเทม
		Crop_Strawberry = "สตรอว์เบอร์รี่",
		Crop_Corn = "ข้าวโพด",
		Crop_Wheat = "ข้าวสาลี",
		Crop_Onion = "หัวหอม",
		Crop_Watermelon = "แตงโม",
		Crop_Pineapple = "สับปะรด",
		Crop_Potato = "มันฝรั่ง",
		Crop_Cucumber = "แตงกวา",
		Crop_Eggplant = "มะเขือยาว",
		Crop_Pumpkin = "ฟักทอง",
		Crop_WitchBerry = "เบอร์รี่แม่มด",
		Crop_Carrot = "แครอท",
		Crop_Sunflower = "ดอกทานตะวัน",
		Crop_Chili = "พริกขี้หนู",

		-- เมนูกราฟิก (GraphicsGui)
		Graphics_Title = "⚙️ กราฟิก",
		Graphics_FPS = "FPS ตอนนี้",
		Graphics_Recommended = "แนะนำสำหรับเครื่องนี้",
		Graphics_InUse = "✓ กำลังใช้",
		Graphics_Auto = "ระบบเลือกให้ตามเครื่องคุณ กดเลือกระดับอื่นได้เลย",
		Graphics_Saved = "บันทึกแล้ว เข้าเกมครั้งหน้าจะใช้ค่านี้",
		Graphics_Hint = "ถ้ายังหน่วง ลองปรับกราฟิกของ Roblox เองด้วย: กด Esc → Settings → Graphics",
		Graphics_Note = "ตั้งค่านี้มีผลกับเครื่องของคุณเท่านั้น ผู้เล่นคนอื่นไม่เห็นผล",
		Graphics_high_Name = "สูง",
		Graphics_high_Desc = "ภาพสวยครบ เหมาะกับคอมทั่วไป",
		Graphics_mid_Name = "กลาง",
		Graphics_mid_Desc = "ลดออร่าต้นพืชและการสะท้อนน้ำลงครึ่งหนึ่ง",
		Graphics_low_Name = "ต่ำ",
		Graphics_low_Desc = "ปิดแสงฟุ้ง แสงไฟ และการเรืองแสง ลดออร่า ผีเสื้อ-นกน้อยลง เหมาะกับมือถือ",
		Graphics_lowest_Name = "ต่ำสุด",
		Graphics_lowest_Desc = "ปิดเงา แสง ออร่าทุกอย่าง และซ่อนสัตว์เลี้ยงของคนอื่น เฟรมลื่นที่สุด ภาพจะแบนลง",
		Item_Booster = "หุ่นฟางดวงดี",
		Item_PetFood = "อาหารสัตว์",
		Hotbar_PetFood = "อาหาร",
		Hotbar_Rod = "เบ็ด",
		Hotbar_Fish = "ปลา",
		Item_BoosterX100 = "หุ่นทองคำนำโชค",

		-- ค่าโชค (LuckGui / ร้านค้า / สัตว์เลี้ยง)
		Luck_Label = "🍀 โชค %s",
		Shop_BoosterInfo = "🍀 โชค x%d · รัศมี %d · %d นาที · %d เหรียญ",
		Pet_LuckyNote = "🍀 %s นำโชค x%d (ลดตามความหิว)",

		-- ร้านค้า (ShopGui)
		Shop_Title = "🌾  ร้านเมล็ดพันธุ์",
		OrchardShop_Title = "🥭  ร้านผลไม้ & อุปกรณ์", -- แผงทางเข้าสวนมะม่วง (2026-10-27)
		Shop_BuyTab = "🛒 ซื้อเมล็ดพันธุ์",
		Shop_SellTab = "💰 ขายผลผลิต",
		Shop_YourCoins = "เหรียญของคุณ",
		Shop_Buy = "ซื้อ",
		Shop_Sell = "ขาย",
		Shop_Max = "MAX",
		Shop_NotEnoughMoney = "เงินไม่พอ",
		Shop_PricePerUnit = "ราคา %d / ชิ้น",
		Shop_MaxAffordable = "ราคา %d / ชิ้น (ซื้อได้สูงสุด %d)",
		Shop_CantAfford = "ราคา %d / ชิ้น (เงินไม่พอ)",
		Shop_HaveCount = "มี %d ชิ้น | %d / ชิ้น",
		Shop_SeedName = "เมล็ด%s",
		Shop_LevelRequired = "ต้องเลเวล %d ขึ้นไป",
		Level_Label = "เลเวล %d",
		Level_UpNotify = "🎉 ยินดีด้วย! คุณเลื่อนเป็นเลเวล %d แล้ว",
		Shop_NoSeedsForSale = "ไม่มีเมล็ดพันธุ์ขายตอนนี้",
		Shop_NoProduceToSell = "ยังไม่มีผลผลิตให้ขาย",
		Shop_SellAll = "💰 ขายทั้งหมด",
		Shop_SellAllInfo = "ผลผลิตทั้งหมด %d ชิ้น · ได้ %d เหรียญ",
		Shop_SoldAll = "💰 ขายผลผลิต %d ชิ้น ได้ %d เหรียญ",

		-- แถบ 6 ช่อง / กระเป๋าเต็ม
		Hotbar_Seed = "🌱 เมล็ด",
		Hotbar_Produce = "ผล",
		Hotbar_Booster = "🎃 หุ่นวาง",
		Inventory_Title = "🎒  กระเป๋า",
		Inventory_TabAll = "ทั้งหมด",
		Inventory_TabSeed = "🌱 เมล็ด",
		Inventory_TabProduce = "🧺 ผลผลิต",
		Inventory_TabBooster = "🎃 หุ่น",
		Inventory_TabPetFood = "🥫 อาหาร",
		Inventory_TabFish = "🐟 ปลา",
		Inventory_TabRod = "🎣 เบ็ด/เหยื่อ",
		Inventory_Empty = "ไม่มีไอเทมในหมวดนี้",
		Inventory_Hint = "กด B เพื่อปิด | กด \"ใช้\" เพื่อนำลงแถบ 6 ช่อง | กด × ที่ช่องเพื่อเก็บคืน | ช่อง 1-2 = เมล็ด · ช่อง 6 = เบ็ด",
		Inventory_OpenPromptKeyboard = "🎒 กด B เปิดกระเป๋า",
		Inventory_OpenPromptGamepad = "🎒 กด Y เปิดกระเป๋า",
		Inventory_OpenPromptTouch = "👆 แตะเปิดกระเป๋า",

		-- ระบบปลูก/เก็บเกี่ยว (PlantingSystem)
		Plant_NeedSeed = "กรุณาถือเมล็ดพันธุ์ก่อนปลูก",
		Plant_IsProduceNotSeed = "นี่คือผลผลิต ไม่ใช่เมล็ดพันธุ์ เอาไปขายที่ร้านได้เลย",
		Plant_CantPlantThis = "ไอเทมนี้ปลูกไม่ได้",
		Plant_TooFar = "ไกลเกินไป เข้าใกล้จุดที่จะปลูกอีกหน่อย",
		Plant_SlotOccupied = "จุดนี้มีต้นปลูกอยู่แล้ว เก็บเกี่ยวก่อนถึงจะปลูกใหม่ตรงนี้ได้",
		Plant_LimitReached = "ปลูกได้สูงสุด %d ต้นในเวลาเดียวกัน ซื้อ Game Pass เพิ่มโควต้าปลูกได้ในร้านค้า",
		Harvest_ActionText = "เก็บเกี่ยว",
		Harvest_ObjectText = "แปลงดิน",
		Harvest_OwnerObjectText = "ต้นของ %s",
		Harvest_NotYours = "ต้นนี้เป็นของ %s เก็บเกี่ยวได้เฉพาะต้นที่คุณปลูกเอง",
		Harvest_OtherPlayer = "ผู้เล่นคนอื่น",

		-- หุ่นเพิ่มดวง
		Booster_LimitReached = "ปักหุ่นได้สูงสุด %d ตัวต่อคน อีก %d:%02d จะปักตัวใหม่ได้",
		Booster_PurchaseSuccess = "ซื้อโควต้าปลูกเพิ่มสำเร็จ! ตอนนี้ปลูกได้สูงสุด %d ต้น",
		Booster_BuyButton = "ซื้อเพิ่มโควต้าปลูก",

		-- จำนวนต้น/เหรียญ
		PlantCount_Label = "ต้นไม้: %d / %d",
		Currency_Label = "เหรียญของคุณ: %d",
		Common_Loading = "กำลังโหลด...",
		Music_Loading = "กำลังโหลดเพลง...",
		Music_NoTracks = "ไม่มีเพลงในลิสต์",
		Music_UnknownTrack = "เพลงไม่ทราบชื่อ",

		-- บริจาค (DonationGui)
		Donate_Title = "💝  สนับสนุนเกมและประกาศข้อความ",
		Donate_Subtitle = "ขอบคุณทุกการสนับสนุน! เลือกจำนวนแล้วพิมพ์ข้อความประกาศให้ทุกเซิร์ฟเวอร์เห็น",
		Donate_Thanks = "💝 ขอบคุณที่บริจาค %d Robux นะ!",
		Donate_NotReady = "ปุ่มนี้ยังไม่พร้อมใช้งาน",

		-- ร้านค้าด่วน (PlantLimitGui)
		QuickShop_Title = "🛒  ร้านค้าสุดพิเศษ",
		QuickShop_BoostName = "เพิ่มโควต้าปลูก +%d",
		QuickShop_BoostDesc = "ปลูกพร้อมกันได้เพิ่มอีก %d ต้น (ตอนนี้ %d ต้น)",
		QuickShop_LuckDesc = "🍀 โชค x%d · รัศมี %d · %d นาที · ทุกคนในวงได้ด้วย",
		QuickShop_LuckOdds = "โอกาสคุณภาพต้น: ★5 %d%% · ★4 %d%% · ★3 %d%% · ★2 %d%% · ★1 %d%%",

		-- ร้านแผงลอย + พ่อค้า (ShopMerchantFx)
		Stall_Sign = "🌱 ร้านเมล็ดพันธุ์",
		Merchant_Name = "🧑‍🌾 ลุงพ่อค้า",
		Merchant_Greet1 = "สวัสดีจ้า! มีเมล็ดดีๆ มาใหม่นะ",
		Merchant_Greet2 = "เอาผลผลิตมาขายได้เลย ลุงรับซื้อหมด!",
		Merchant_Greet3 = "หุ่นฟางดวงดี ช่วยให้ได้ดาวเยอะขึ้นนะ",
		Merchant_Greet4 = "อากาศดีแบบนี้ ปลูกผักสบายเลย~",
		OrchardKeeper_Name = "🥭 ป้าแตงไทย",
		OrchardKeeper_Greet1 = "มะม่วงหวานๆ มาแล้วจ้า~",
		OrchardKeeper_Greet2 = "เมล็ดมะม่วงปลูกได้ เก็บได้ 2 รอบนะหลานๆ",
		OrchardKeeper_Greet3 = "มีผลไม้เอามาขายป้าได้เลยจ้า",
		OrchardKeeper_Greet4 = "ระวังคนแอบขโมยผลไม้ด้วยนะ!",

		-- แพ็กสุลต่าน (SultanShopGui)
		Sultan_Title = "👑 แพ็กสุลต่าน",
		Sultan_TitleWith = "👑 แพ็ก%s · SULTAN PACK",
		Sultan_PetName = "🔥 มังกรแดงสุลต่าน",
		Sultan_Buy = "👑 ซื้อ R$ %s",
		Sultan_Owned = "✔️ คุณเป็นสุลต่านแล้ว",
		Sultan_BuyNote = "ซื้อครั้งเดียว ใช้ได้ถาวร",
		Sultan_BuyNoteOwned = "ขอบคุณที่สนับสนุนเกม 💖",
		Sultan_Perk1_Title = "มังกรแดงสุลต่าน",
		Sultan_Perk1_Desc = "สัตว์เลี้ยงช่วยปลูก หาจากตู้ไม่ได้  · นำโชค x50 · ขายได้เงิน +10% · พ่นไฟให้ผักโตเร็วขึ้น 15%",
		Sultan_Perk2_Title = "ของขวัญทันที",
		Sultan_Perk2_Desc = "💎 ตั๋วพรีเมียม %d ใบ · 💰 %s เหรียญ · 🍀 หุ่นทองคำนำโชค (x%d) %d อัน",
		Sultan_Perk3_Title = "ตั๋วพรีเมียมฟรีทุกวัน",
		Sultan_Perk3_Desc = "วันละ %d ใบ ขึ้นวันใหม่ตอนเที่ยงคืน (เวลาไทย)",
		Sultan_Perk4_Title = "ขายผลผลิต & ปลา +%d%% ถาวร",
		Sultan_Perk4_Desc = "ทุกชิ้นที่ขาย ทั้งร้านหลักและร้านตกปลา",
		Sultan_Perk5_Title = "โชคปลูกผัก %dเท่า ถาวร",
		Sultan_Perk5_Desc = "คูณกับโชคทุกแหล่ง (หุ่น + สัตว์เลี้ยง) ได้ผักดาวสูงบ่อยขึ้น",
		Sultan_Perk6_Title = "ปลูกผักได้ ⭐%d ขึ้นไปเสมอ",
		Sultan_Perk6_Desc = "ต้นที่ปลูกไม่มีวันต่ำกว่า %d ดาว ได้ผลผลิตต่อต้นเยอะขึ้น และเก็บเกี่ยวได้ดาวสูงบ่อยขึ้น",
		Sultan_Perk7_Title = "เครื่องทำอาหารสัตว์เร็วขึ้น %d%%",
		Sultan_Perk7_Desc = "ทำอาหารเร็วขึ้นทุกเลเวล แม้ออกเกมอยู่",
		Sultan_Perk8_Title = "หน้าตาสุลต่าน",
		Sultan_Perk8_Desc = "ป้าย 👑 สุลต่านเหนือหัว · สีสถานะพิเศษ 2 สี · แท็กแชต · ประกาศตอนเข้าเกม",
		Sultan_Perk9_Title = "รวมสิทธิ์ VIP ทั้งหมด",
		Sultan_Perk9_Desc = "ตั้งสถานะเหนือหัวได้เอง ไม่ต้องซื้อ VIP แยก",
		Sultan_Perk10_Title = "เลเวล %d เทรดเหรียญได้วันละ %s · เลเวล %d วันละ %s",
		Sultan_Perk10_Desc = "สุลต่านที่เล่นจนเลเวลถึงเท่านั้น (ปกติวันละ %s) · ภาษี %d%% เท่าเดิม",
	},

	en = {
		-- Crop / item names
		Crop_Strawberry = "Strawberry",
		Crop_Corn = "Corn",
		Crop_Wheat = "Wheat",
		Crop_Onion = "Onion",
		Crop_Watermelon = "Watermelon",
		Crop_Pineapple = "Pineapple",
		Crop_Potato = "Potato",
		Crop_Cucumber = "Cucumber",
		Crop_Eggplant = "Eggplant",
		Crop_Pumpkin = "Pumpkin",
		Crop_WitchBerry = "Witch Berry",
		Crop_Carrot = "Carrot",
		Crop_Sunflower = "Sunflower",
		Crop_Chili = "Bird's Eye Chili",

		-- Graphics menu (GraphicsGui)
		Graphics_Title = "⚙️ Graphics",
		Graphics_FPS = "Current FPS",
		Graphics_Recommended = "Recommended for this device",
		Graphics_InUse = "✓ In use",
		Graphics_Auto = "Picked automatically for your device. Tap another level any time.",
		Graphics_Saved = "Saved. Next time you join this level will be used.",
		Graphics_Hint = "Still laggy? Also try Roblox's own setting: Esc → Settings → Graphics",
		Graphics_Note = "This only affects your own device. Other players are not affected.",
		Graphics_high_Name = "High",
		Graphics_high_Desc = "Full visuals, for regular PCs",
		Graphics_mid_Name = "Medium",
		Graphics_mid_Desc = "Half the plant auras and water reflection",
		Graphics_low_Name = "Low",
		Graphics_low_Desc = "No bloom, lights or glow, fewer auras and critters. Good for phones",
		Graphics_lowest_Name = "Lowest",
		Graphics_lowest_Desc = "No shadows, lights, auras or effects, and other players' pets hidden. Smoothest, looks flatter",
		Item_Booster = "Lucky Straw Scarecrow",
		Item_PetFood = "Pet Food",
		Hotbar_PetFood = "Food",
		Hotbar_Rod = "Rod",
		Hotbar_Fish = "Fish",

		-- Shop (ShopGui)
		Shop_Title = "🌾  Seed Shop",
		OrchardShop_Title = "🥭  Fruit & Tools",
		Shop_BuyTab = "🛒 Buy Seeds",
		Shop_SellTab = "💰 Sell Produce",
		Shop_YourCoins = "Your Coins",
		Shop_Buy = "Buy",
		Shop_Sell = "Sell",
		Shop_Max = "MAX",
		Shop_NotEnoughMoney = "Not enough coins",
		Shop_PricePerUnit = "Price %d / each",
		Shop_MaxAffordable = "Price %d / each (max %d)",
		Shop_CantAfford = "Price %d / each (not enough coins)",
		Shop_HaveCount = "Have %d | %d / each",
		Shop_SeedName = "%s Seed",
		Shop_LevelRequired = "Requires level %d+",
		Level_Label = "Level %d",
		Level_UpNotify = "🎉 Congrats! You reached Level %d",
		Shop_NoSeedsForSale = "No seeds for sale right now",
		Shop_NoProduceToSell = "No produce to sell yet",
		Shop_SellAll = "💰 Sell All",
		Shop_SellAllInfo = "All produce: %d items · %d coins",
		Shop_SoldAll = "💰 Sold %d items for %d coins",

		-- Hotbar / inventory
		Hotbar_Seed = "🌱 Seed",
		Hotbar_Produce = "Yield",
		Hotbar_Booster = "🎃 Placeable",
		Inventory_Title = "🎒  Inventory",
		Inventory_TabAll = "All",
		Inventory_TabSeed = "🌱 Seeds",
		Inventory_TabProduce = "🧺 Produce",
		Inventory_TabBooster = "🎃 Scarecrows",
		Inventory_TabPetFood = "🥫 Pet Food",
		Inventory_TabFish = "🐟 Fish",
		Inventory_TabRod = "🎣 Rods/Bait",
		Inventory_Empty = "No items in this category",
		Inventory_Hint = "Press B to close | Tap \"Use\" to put it on the hotbar | Tap × on a slot to put it back | Slots 1-2 = seeds · Slot 6 = rod",
		Inventory_OpenPromptKeyboard = "🎒 Press B to open bag",
		Inventory_OpenPromptGamepad = "🎒 Press Y to open bag",
		Inventory_OpenPromptTouch = "👆 Tap to open bag",

		-- Planting / harvesting
		Plant_NeedSeed = "Hold a seed before planting",
		Plant_IsProduceNotSeed = "This is produce, not a seed. Sell it at the shop instead.",
		Plant_CantPlantThis = "This item can't be planted",
		Plant_TooFar = "Too far away, get closer to plant here",
		Plant_SlotOccupied = "Something is already planted here. Harvest it first.",
		Plant_LimitReached = "Max %d plants at once. Buy a Game Pass in the shop for more slots.",
		Harvest_ActionText = "Harvest",
		Harvest_ObjectText = "Farm plot",
		Harvest_OwnerObjectText = "%s's plant",
		Harvest_NotYours = "This plant belongs to %s. You can only harvest what you planted.",
		Harvest_OtherPlayer = "another player",

		-- Booster
		Booster_LimitReached = "Max %d placed per player. %d:%02d until you can place another.",
		Booster_PurchaseSuccess = "Purchase successful! You can now plant up to %d crops.",
		Booster_BuyButton = "Buy More Plant Slots",

		-- Counters
		PlantCount_Label = "Plants: %d / %d",
		Currency_Label = "Coins: %d",
		Common_Loading = "Loading...",
		Music_Loading = "Loading track...",
		Music_NoTracks = "No tracks in the playlist",
		Music_UnknownTrack = "Unknown track",

		-- Donation
		Donate_Title = "💝  Support & Announce",
		Donate_Subtitle = "Thank you for your support! Pick an amount and post a message every server can see",
		Donate_Thanks = "💝 Thank you for donating %d Robux!",
		Donate_NotReady = "This option isn't available yet",

		-- Luck
		Item_BoosterX100 = "Golden Lucky Scarecrow",
		Luck_Label = "🍀 Luck %s",
		Shop_BoosterInfo = "🍀 Luck x%d · radius %d · %d min · %d coins",
		Pet_LuckyNote = "🍀 %s Luck x%d (drops when hungry)",

		-- Quick shop
		QuickShop_Title = "🛒  Special Shop",
		QuickShop_BoostName = "Plant Slots +%d",
		QuickShop_BoostDesc = "Grow %d more crops at once (now %d)",
		QuickShop_LuckDesc = "🍀 Luck x%d · radius %d · %d min · shared with everyone nearby",
		QuickShop_LuckOdds = "Plant quality odds: ★5 %d%% · ★4 %d%% · ★3 %d%% · ★2 %d%% · ★1 %d%%",

		-- Market stall + merchant
		Stall_Sign = "🌱 Seed Shop",
		Merchant_Name = "🧑‍🌾 Uncle Merchant",
		Merchant_Greet1 = "Howdy! Fresh seeds just came in!",
		Merchant_Greet2 = "Bring your harvest here, I'll buy it all!",
		Merchant_Greet3 = "A Lucky Scarecrow helps you get more stars!",
		Merchant_Greet4 = "Lovely weather for farming today~",
		OrchardKeeper_Name = "🥭 ป้าแตงไทย",
		OrchardKeeper_Greet1 = "Sweet mangoes are here, dear~",
		OrchardKeeper_Greet2 = "Mango seeds give 2 harvests each!",
		OrchardKeeper_Greet3 = "Got fruit? Auntie will buy it!",
		OrchardKeeper_Greet4 = "Watch out for fruit thieves!",

		-- Sultan pack (SultanShopGui)
		Sultan_Title = "👑 Sultan Pack",
		Sultan_TitleWith = "👑 %s Pack · SULTAN PACK",
		Sultan_PetName = "🔥 Red Sultan Dragon",
		Sultan_Buy = "👑 Buy R$ %s",
		Sultan_Owned = "✔️ You're already a Sultan",
		Sultan_BuyNote = "Buy once, yours forever",
		Sultan_BuyNoteOwned = "Thanks for supporting the game 💖",
		Sultan_Perk1_Title = "Red Sultan Dragon",
		Sultan_Perk1_Desc = "Farm helper pet, gacha-exclusive · Luck x50 · +10% sell bonus · Fire breath speeds crops 15%",
		Sultan_Perk2_Title = "Instant Gifts",
		Sultan_Perk2_Desc = "💎 Premium Tickets %d · 💰 %s coins · 🍀 Golden Lucky Scarecrow (x%d) x%d",
		Sultan_Perk3_Title = "Free Premium Tickets Daily",
		Sultan_Perk3_Desc = "%d per day, resets at midnight (ICT)",
		Sultan_Perk4_Title = "Permanent +%d%% Sell Bonus",
		Sultan_Perk4_Desc = "On everything you sell, both the main shop and fishing shop",
		Sultan_Perk5_Title = "Permanent %dx Farm Luck",
		Sultan_Perk5_Desc = "Multiplies all luck sources (scarecrows + pets), more high-star crops",
		Sultan_Perk6_Title = "Always ⭐%d+ Crops",
		Sultan_Perk6_Desc = "Crops never go below %d stars, more yield per plant and higher star ratings",
		Sultan_Perk7_Title = "Pet Food Machine %d%% Faster",
		Sultan_Perk7_Desc = "Faster food production at every level, even while offline",
		Sultan_Perk8_Title = "Sultan Appearance",
		Sultan_Perk8_Desc = "👑 Sultan crown above head · 2 special status colors · chat tag · join announcement",
		Sultan_Perk9_Title = "Includes All VIP Perks",
		Sultan_Perk9_Desc = "Set your own status above head, no need to buy VIP separately",
		Sultan_Perk10_Title = "Level %d: trade %s coins a day · level %d: %s a day",
		Sultan_Perk10_Desc = "Only for Sultans who have reached that level (normally %s a day) · same %d%% tax",
	},
}

-- แปลง locale ของผู้เล่น (เช่น "th-th", "en-us") เป็นภาษาที่รองรับ ("th" หรือ "en")
-- ตอนนี้รองรับแค่ไทย/อังกฤษ ถ้าเจอ locale อื่นจะ fallback ไปอังกฤษ
function Localization.GetLanguage(player)
	-- ทดสอบใน Studio เท่านั้น: ตั้ง Attribute DevForceLang = "en" / "th" บน ReplicatedStorage (ตั้งตอนยังไม่กด Play เพื่อให้ทุกสคริปต์เห็นตั้งแต่เริ่ม) บังคับภาษา
	if game:GetService("RunService"):IsStudio() then
		local forced = game:GetService("ReplicatedStorage"):GetAttribute("DevForceLang")
		if forced == "en" or forced == "th" then return forced end
	end
	local ok, localeId = pcall(function()
		return player.LocaleId
	end)

	if ok and localeId and localeId:sub(1, 2):lower() == "th" then
		return "th"
	end

	return "en"
end

-- ดึงคำแปลจากคีย์ ใส่ lang เป็น "th" หรือ "en" (ไม่ใส่ = ใช้ไทยเป็นค่าเริ่มต้น)
-- ถ้าไม่เจอคีย์ในภาษานั้น จะลองหาในไทยก่อน แล้วค่อย fallback เป็นคีย์เปล่าๆ กันสคริปต์พัง
function Localization.T(key, lang)
	lang = lang or "th"
	local langTable = STRINGS[lang] or STRINGS.th
	return langTable[key] or STRINGS.th[key] or key
end

-- เหมือน T() แต่ใส่ตัวแปรแทนที่ %d/%s ในข้อความได้เลย เช่น Localization.F("Shop_PricePerUnit", lang, 10)
function Localization.F(key, lang, ...)
	local template = Localization.T(key, lang)
	local ok, result = pcall(string.format, template, ...)
	return ok and result or template
end

-- เลือกข้อความไทย/อังกฤษแบบคู่ในบรรทัด (เพิ่ม 2026-10-03 สำหรับข้อความที่ไม่คุ้มค่าในตาราง STRINGS): Localization.Pick(lang, "ไทย", "English")
-- ภาษาเลือกอัตโนมัติจาก Roblox LocaleId เท่านั้น (ไม่มีปุ่มสลับ ผู้เล่นเลือก 2026-10-03)
-- Pick2 = คืน th/en อย่างเดียวกัน แต่ตัวย่อสำหรับฝั่งไคลเอนต์: Localization.Pick(Localization.GetLanguage(player), ...)
function Localization.Pick(lang, th, en)
	if lang == "th" then return th end
	return en or th
end

-- ภาษาของผู้เล่นที่อยู่ฝั่งไคลเอนต์ (LocalPlayer) สะดวกใช้ใน LocalScript: local tr = Localization.Tr()  →  tr("ไทย", "English")
function Localization.Tr()
	local Players = game:GetService("Players")
	local lang = Localization.GetLanguage(Players.LocalPlayer)
	return function(th, en)
		if lang == "th" then return th end
		return en or th
	end, lang
end

return Localization