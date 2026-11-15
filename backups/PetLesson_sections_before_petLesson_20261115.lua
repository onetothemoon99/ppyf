-- Backup 2026-11-15 before adding the "pet" lesson (sections only — everything else in these scripts was not touched).
-- To undo: put each block back where its new version is. New code is marked "บทสัตว์เลี้ยง" / "petLesson" in the live scripts.

-- ===== game.ReplicatedStorage.LessonConfig =====
LessonConfig.Order = { "basic", "fish", "chicken" }
LessonConfig.Rewards = {
	basic = 10000,
	fish = 10000,
	chicken = 10000,
}
LessonConfig.XpRewards = {
	basic = 300,
	fish = 300,
	chicken = 300,
}

-- ===== game.ReplicatedStorage.LessonContent =====
-- (the pet lesson entry was inserted between the "fish" and "chicken" entries of LessonContent.LESSONS; delete it to undo)

-- ===== game.ServerScriptService.LessonService =====
local NAMES = {
	basic = { th = "ซื้อเมล็ด ปลูก เก็บ ขาย", en = "Buy, plant, harvest, sell" }, -- ชื่อตรง LessonContent 2026-11-15
	fish = { th = "ตกปลา", en = "Fishing" },
	chicken = { th = "เลี้ยงไก่", en = "Chickens" },
}
local function normalize(d)
	if type(d) ~= "table" then d = {} end
	d.ready = type(d.ready) == "table" and d.ready or {}
	d.claimed = type(d.claimed) == "table" and d.claimed or {}
	return d
end
-- save(): inside UpdateAsync
			for id in pairs(snapshot.ready) do old.ready[id] = true end
			for id in pairs(snapshot.claimed) do old.claimed[id] = true end
			return old
-- onPlayerAdded tail
	st.data = normalize(data)
	st.loaded = true
	publish(player, st)
end
-- (new section "บทสัตว์เลี้ยง" before "============ รับรางวัล" was added; delete it to undo)

-- ===== game.StarterPlayer.StarterPlayerScripts.LessonNpcGui (runLesson) =====
		local ev = guide and guide:FindFirstChild("StartGuide")
		if ev then ev:Fire() end

-- ===== game.StarterPlayer.StarterPlayerScripts.GachaGui (refresh start) =====
local function refresh()
	for id, b in pairs(tabButtons) do

-- ===== game.StarterPlayer.StarterPlayerScripts.PetHelperToggleButton (pet row select button) =====
	if activePetIds[petInfo.Id] then
		selectButton.Text = tr("เลิกใช้", "Unequip")

-- ===== game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide =====
-- The STEPS table, state, enterStep/finish/start, checkStep and findHintTarget were extended for a 2nd step set (PET_STEPS).
-- Versions before this change: backups/NewPlayerGuide_before_buyStep_20261115.lua + backups/NewPlayerGuide_before_shopHint_20261115.lua
-- Key lines before:
--   cardTitle.Text = tr("สอนเล่น", "Guide") .. " " .. n .. "/" .. #STEPS
--   local function start()  ...  enterStep(seedCount() > 0 and 2 or 1)
--   startEvent.Event:Connect(start)
