-- Backup (sections only — the rest of the script was not touched)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.LessonNpcGui (LocalScript)
-- Change: lesson window cards show title + reward only; claimed lesson = "Done" badge, no restart button (2026-11-15)
-- Restore: replace the matching sections in the live script with the blocks below
--   (A) constants under "หน้าต่างบทเรียน", (B) card build from `local name = Instance.new("TextLabel")` to table.insert(cards…),
--   (C) linesHeight function, (D) the `for _, c in ipairs(cards)` loop inside layout.

-- ===== (A) constants =====
local WIDTH = 430
local HEADER = 52 -- หัวหน้าต่าง (ชื่อ + ปุ่ม X) เหนือรายการการ์ด
local LINES_TOP = 44 -- วิธีเล่นเริ่มใต้ชื่อบทเรียน/ปุ่มในการ์ด
local LINES_TEXT_SIZE = 16
local LINES_LINE_HEIGHT = 1.15
local LINES_WIDTH = WIDTH - 20 - 24 - 8 -- การ์ดกว้างหน้าต่าง -20 · ข้อความ -24 · เผื่อแถบเลื่อน 8
local CARD_MIN_HEIGHT = 96

-- ===== (B) card build (inside `for _, lesson in ipairs(LESSONS) do`) =====
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 8, 0, 4)
	icon.Size = UDim2.fromOffset(30, 28)
	icon.Text = lesson.icon
	icon.TextSize = 22
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLOR_TEXT
	icon.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 44, 0, 4)
	name.Size = UDim2.new(1, -150, 0, 28)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 17
	name.TextColor3 = COLOR_TEXT
	name.TextXAlignment = Enum.TextXAlignment.Left
	-- 2026-11-15 ป้าย "ชื่อ · เหรียญ + EXP" ยาวเกินช่อง: ย่อตัวหนังสือให้พอดี (ใหญ่สุด 17 เท่าเดิม)
	name.TextScaled = true
	do local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 17; c.MinTextSize = 9; c.Parent = name end
	name.Parent = card

	local go = Instance.new("TextButton")
	go.Name = "Go"
	go.AnchorPoint = Vector2.new(1, 0)
	go.Position = UDim2.new(1, -8, 0, 6)
	go.Size = UDim2.fromOffset(92, 36)
	go.BackgroundColor3 = COLOR_GO
	go.Font = Enum.Font.GothamBold
	go.TextSize = 15
	go.TextColor3 = Color3.new(1, 1, 1)
	go.Selectable = true
	go.Parent = card
	corner(go, 10)

	local lines = Instance.new("TextLabel")
	lines.Name = "Lines"
	lines.BackgroundTransparency = 1
	lines.Position = UDim2.new(0, 12, 0, LINES_TOP)
	lines.Size = UDim2.new(1, -24, 1, -LINES_TOP - 2)
	lines.Font = Enum.Font.Gotham
	lines.TextSize = LINES_TEXT_SIZE
	lines.LineHeight = LINES_LINE_HEIGHT
	lines.TextColor3 = COLOR_SUB
	lines.TextXAlignment = Enum.TextXAlignment.Left
	lines.TextYAlignment = Enum.TextYAlignment.Top
	lines.TextWrapped = true
	lines.Parent = card
	-- (go.Activated handler unchanged)
	table.insert(cards, { lesson = lesson, frame = card, name = name, lines = lines, go = go })

-- ===== (C) linesHeight =====
-- ความสูงของวิธีเล่น (หลายบรรทัด ตัดคำตามความกว้างการ์ด) · GetTextSize ไม่คิด LineHeight จึงคูณเอง
local function linesHeight(text)
	local ok, size = pcall(function()
		return TextService:GetTextSize(text, LINES_TEXT_SIZE, Enum.Font.Gotham, Vector2.new(LINES_WIDTH, 10000))
	end)
	if not ok then return LINES_TEXT_SIZE * 3 * LINES_LINE_HEIGHT end
	return math.ceil(size.Y * LINES_LINE_HEIGHT)
end

-- ===== (D) layout loop =====
	for _, c in ipairs(cards) do
		local show = c.lesson.available == nil or c.lesson.available() == true
		c.frame.Visible = show
		if show then
			c.lines.Text = tr(c.lesson.thLines, c.lesson.enLines)
			local cardHeight = math.max(CARD_MIN_HEIGHT, LINES_TOP + linesHeight(c.lines.Text) + 4)
			c.frame.Size = UDim2.new(1, -20, 0, cardHeight)
			c.frame.Position = UDim2.new(0, 10, 0, y)
			y += cardHeight + 6
			-- ชื่อบทเรียน + รางวัล/สถานะในบรรทัดเดียวกัน · ปุ่มเปลี่ยนตามสถานะ
			local state, coins = lessonReward(c.lesson.id)
			local nameText = tr(c.lesson.th, c.lesson.en)
			local canGo = c.lesson.getPos ~= nil or c.lesson.startGuide == true
			if state == STATE_READY then
				c.name.Text = nameText .. " · 💰 " .. rewardText(c.lesson.id, coins)
				c.go.Text = tr("รับรางวัล", "Claim")
				c.go.BackgroundColor3 = COLOR_GOLD
				c.go.TextColor3 = COLOR_TEXT
				c.go.Visible = true
			else
				if state == STATE_CLAIMED then
					c.name.Text = nameText .. " · ✅ " .. tr("รับแล้ว", "Claimed")
				elseif state then
					c.name.Text = nameText .. " · 💰 " .. rewardText(c.lesson.id, coins)
				else
					c.name.Text = nameText
				end
				c.go.Text = c.lesson.startGuide and tr("เริ่มนำทาง", "Start") or tr("พาไป", "Take me")
				c.go.BackgroundColor3 = COLOR_GO
				c.go.TextColor3 = Color3.new(1, 1, 1)
				c.go.Visible = canGo
			end
			if not firstGo and c.go.Visible then firstGo = c.go end
		end
	end
