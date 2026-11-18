-- reset_studio_test_player.lua (2026-11-17)
-- Wipes ALL saved game data of the Studio fake test player (Local Server "Player1" = UserId -1)
-- so the next Local Server test starts as a brand-new player (new-player guide, starter coins, graphics picker...).
-- Run it in Studio's Command Bar in EDIT mode (not during Play). It never touches a real account:
-- it refuses any UserId above 0. Change FAKE_ID to -2 for "Player2".
-- Keys follow each script's own key function (see CHANGELOG 2026-11-17 "Studio fake player reset").

local FAKE_ID = -1
assert(FAKE_ID < 0, "Only Studio fake players (negative UserId) may be reset")

local DSS = game:GetService("DataStoreService")
local id = tostring(FAKE_ID)
local inv = workspace:GetAttribute("DevInventoryKeyOverride")
local orch = workspace:GetAttribute("DevOrchardKeyOverride")
local compId = "?"
pcall(function() compId = tostring(require(game.ReplicatedStorage:WaitForChild("CompensationConfig", 2)).Id) end)

local plain = { -- key = UserId
	"PlayerCoins_v1", "PlayerLevel_v1", "PlayerInventory_v1", "PetSettings_v1", "PetOwnership_v1", "MountOwnership_v1",
	"ChickenFarm_v1", "Orchard_v1", "Tutorial_v1", "StarterGift_v1", "GraphicsQuality_v1", "AudioSettings_v1",
	"HotbarLayout_v1", "LastPosition_v1", "FishIndex_v1", "FishingShop_v1", "FishingResume_v1", "GachaTickets_v1",
	"PetFoodConverter_v1", "AutoFeeder_v1", "CraftBench_v1", "PlaytimeRewards_v1", "LoginAnnouncementDismissals_v1",
	"Sultan_v1", "VipTitle_v1", "CoinTradeDaily_v1", "BoomboxStars_v1", "BoomboxStow_v1", "GhostPlaceSpot_v1",
	"PlantBoostPurchases_v1", "PlantQuotaGift_v1", "BirthdayEvent_v1", "CropBook_v1", "OrderBoard_v1",
	"BoomboxPromoEntitlements_v1", "CropContest_v1",
}
local gifts = { -- keys to_/inbox_/pending_<id>
	"AutoFeederGift_v1", "BoomboxGift_v1", "FishingRodGift_v1", "PetSlotGift_v1", "PremiumPetGift_v1", "LuckGift_v1",
	"MountGift_v1", "MountBundleGift_v1", "NineTailFoxGift_v1", "ScarecrowGhostGift_v1", "SultanGift_v1", "VipGift_v1",
	"ChickenGift_v1", "PlantQuotaGift_v1", "AutoFeederGift_v1",
}
local special = {
	{ "PlayerInventory_v1", type(inv) == "string" and inv ~= "" and (inv .. "_" .. id) or nil },
	{ "Orchard_v1", orch and ("dev_" .. tostring(orch) .. "_" .. id) or nil },
	{ "Lessons_v1", "StudioTest_" .. id },
	{ "Achievement_v1", "StudioTest_" .. id },
	{ "StarterGift_v1", "test_" .. id },
	{ "TrashEvent_v1", "studio:" .. id },
	{ "CommunityReward_v1", "studio_" .. id },
	{ "CompensationClaims_v1", "studio:" .. compId .. ":" .. id },
	{ "CoinLedger_v1", "studio:u" .. id },
	{ "ZukzonHold_v1", "studio:" .. id },
	{ "DisconnectLogs_v1", "u" .. id },
}
local ordered = { "PlaytimeLeaderboard_v1", "LevelLeaderboard_v1", "ChickenFarmRank_v1", "BoxingRecord_v1" }

local jobs = {}
for _, s in ipairs(plain) do table.insert(jobs, { s, id }) end
for _, s in ipairs(gifts) do
	for _, p in ipairs({ "to_", "inbox_", "pending_" }) do table.insert(jobs, { s, p .. id }) end
end
for _, j in ipairs(special) do if j[2] then table.insert(jobs, j) end end

local removed, failed = {}, {}
for i, j in ipairs(jobs) do
	local ok, old = pcall(function() return DSS:GetDataStore(j[1]):RemoveAsync(j[2]) end)
	if not ok then table.insert(failed, j[1] .. "/" .. j[2] .. ": " .. tostring(old))
	elseif old ~= nil then table.insert(removed, j[1] .. "/" .. j[2]) end
	if i % 10 == 0 then task.wait(1) end -- stay under the DataStore write budget
end
for _, s in ipairs(ordered) do
	local ok, err = pcall(function() DSS:GetOrderedDataStore(s):RemoveAsync(id) end)
	if not ok then table.insert(failed, s .. ": " .. tostring(err)) end
end
print(string.format("[ResetTestPlayer] UserId %s: %d keys checked, %d had data and were removed, %d failed", id, #jobs, #removed, #failed))
for _, r in ipairs(removed) do print("  removed " .. r) end
for _, f in ipairs(failed) do warn("  failed " .. f) end
return string.format("checked %d, removed %d, failed %d", #jobs, #removed, #failed)
