-- Backup (sections only — the rest of the script was not touched)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.NewPlayerGuide (LocalScript)
-- Change (2026-11-15): highlight the tab/button to tap inside the seed shop (buy/sell steps) and the fishing shop (fish lesson sell).
-- Restore: put the blocks below back, then delete the whole "============ ไฮไลต์ปุ่มในร้าน" section and every `shopHint` line.

-- (1) state
local everStarted = false

-- (2) enterStep
local function enterStep(n)
	step = n
	basePlant = plantCount()
	maxPlant = basePlant
	baseCoins = coins()
	baseSeeds = seedCount()
	targetPos = nil
	local s = STEPS[n]

-- (3) stop
local function stop()
	runId += 1
	step = 0
	gui.Enabled = false
	hideWorld()
end

-- (4) finish
local function finish()
	runId += 1
	local myRun = runId
	step = 0
	hideWorld()

-- (5) guideTo
	step = -1
	targetPos = data.pos

-- (6) before
stopButton.Activated:Connect(stop)
