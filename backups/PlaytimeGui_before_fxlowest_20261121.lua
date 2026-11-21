-- BACKUP of StarterPlayer.StarterPlayerScripts.PlaytimeGui taken 2026-11-21 before the B3 per-frame lowest-graphics change.
-- Restore: in Studio open StarterPlayer.StarterPlayerScripts.PlaytimeGui, select all, paste everything BELOW the next line.
-- ===== original Source (5250 bytes, hash 1361073330) =====
-- PlaytimeGui: แถว "ตั๋วฟรีจากเวลาเล่น" ในกล่องสถานะมุมล่างซ้าย (ต่อจากแถวโชค)
--   + เวลาเล่นสะสมทั้งหมด (นาที) ด้านขวาของแถวเลเวล เช่น ⏱️ 60 = เล่นมา 1 ชั่วโมง, เลขเยอะย่อเป็น 1.2k / 3.4m / 1b
-- นับถอยหลังลื่นๆ ฝั่งผู้เล่นเอง เซิร์ฟเวอร์ส่งค่าจริงมาทุก 5 วิ (PlaytimeRewards)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("PlaytimeConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local tr = Localization.Tr()

local player = Players.LocalPlayer
local panel = player:WaitForChild("PlayerGui"):WaitForChild("CurrencyGui"):WaitForChild("StatusPanel")

local TICKET_SECONDS = Config.TICKET_MINUTES * 60
local COLOR_TEXT = Color3.fromRGB(150, 80, 110)
local COLOR_BAR = Color3.fromRGB(255, 150, 190)
local COLOR_DONE = Color3.fromRGB(130, 130, 130)

-- แถวในกล่องสถานะ: TopRow 1, เส้นคั่น 2, เลเวล 3, โชค 4 -> ตั๋วฟรี 5
local row = Instance.new("Frame")
row.Name = "PlaytimeRow"
row.LayoutOrder = 5
row.Size = UDim2.new(1, 0, 0, 26)
row.BackgroundTransparency = 1
row.Visible = false
row.Parent = panel

local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Size = UDim2.new(1, 0, 0, 18)
text.Font = Enum.Font.GothamBold
text.TextSize = 13
text.TextColor3 = COLOR_TEXT
text.TextXAlignment = Enum.TextXAlignment.Left
text.Parent = row

local barBack = Instance.new("Frame")
barBack.Position = UDim2.new(0, 0, 0, 20)
barBack.Size = UDim2.new(1, 0, 0, 5)
barBack.BackgroundColor3 = Color3.fromRGB(235, 220, 225)
barBack.BorderSizePixel = 0
barBack.Parent = row
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = COLOR_BAR
bar.BorderSizePixel = 0
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

-- ============ เวลาเล่นสะสม (แถวเลเวล ชิดขวา) ============
local function short(n)
	n = math.floor(n)
	local units = { { 1e9, "b" }, { 1e6, "m" }, { 1e3, "k" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			local v = n / u[1]
			local s = v >= 100 and string.format("%d", math.floor(v)) or string.format("%.1f", math.floor(v * 10) / 10)
			return (s:gsub("%.0$", "")) .. u[2]
		end
	end
	return tostring(n)
end

local levelRow = panel:WaitForChild("LevelRow", 30)
if levelRow then
	local totalLabel = Instance.new("TextLabel")
	totalLabel.Name = "PlaytimeTotal"
	totalLabel.BackgroundTransparency = 1
	totalLabel.AnchorPoint = Vector2.new(1, 0)
	totalLabel.Position = UDim2.new(1, 0, 0, 0)
	totalLabel.Size = UDim2.new(0.5, 0, 0, 18)
	totalLabel.Font = Enum.Font.GothamBold
	totalLabel.TextSize = 14
	totalLabel.TextColor3 = Color3.fromRGB(110, 90, 80)
	totalLabel.TextXAlignment = Enum.TextXAlignment.Right
	totalLabel.Text = ""
	totalLabel.Parent = levelRow
	local function updateTotal()
		local minutes = player:GetAttribute("PlaytimeTotal")
		totalLabel.Text = minutes and ("⏱️ " .. short(minutes)) or ""
	end
	player:GetAttributeChangedSignal("PlaytimeTotal"):Connect(updateTotal)
	updateTotal()
end

local serverProgress, receivedAt = nil, os.clock()
local function onProgress()
	serverProgress = player:GetAttribute("PlaytimeProgress")
	receivedAt = os.clock()
end
player:GetAttributeChangedSignal("PlaytimeProgress"):Connect(onProgress)
onProgress()

local function mmss(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local lastText
RunService.Heartbeat:Connect(function()
	local today = player:GetAttribute("PlaytimeTicketsToday")
	if not serverProgress or not today then
		row.Visible = false
		return
	end
	row.Visible = true
	local cap = Config.DAILY_TICKET_CAP
	local newText
	if today >= cap then
		newText = string.format(tr("🎟️ ตั๋วฟรีวันนี้ครบแล้ว %d/%d", "🎟️ Daily free tickets done %d/%d"), today, cap)
		bar.Size = UDim2.new(1, 0, 1, 0)
		bar.BackgroundColor3 = COLOR_DONE
	else
		-- ต่อจากค่าล่าสุดของเซิร์ฟเวอร์ (ไม่เกินอีก 1 รอบนับ กันวิ่งเลยตอนเน็ตกระตุก)
		local progress = math.min(serverProgress + math.min(os.clock() - receivedAt, 6), TICKET_SECONDS)
		newText = string.format(tr("🎟️ ตั๋วฟรีใน %s  (%d/%d)", "🎟️ Free ticket in %s  (%d/%d)"), mmss(TICKET_SECONDS - progress), today, cap)
		bar.Size = UDim2.new(progress / TICKET_SECONDS, 0, 1, 0)
		bar.BackgroundColor3 = COLOR_BAR
	end
	if newText ~= lastText then
		text.Text = newText
		lastText = newText
	end
end)
