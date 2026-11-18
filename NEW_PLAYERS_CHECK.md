# เช็กผู้เล่นใหม่ + เช็กเซิร์ฟล่ม (จาก DataStore)

สคริปต์ทั้งสองในไฟล์นี้**อ่านข้อมูลอย่างเดียว** ไม่เขียนหรือลบอะไรใน DataStore

## ขั้นตอน

1. เปิด Studio เกม พักผ่อนที่ฟาร์ม ในโหมด **Edit** (ไม่ต้องกด Play; ถ้ากด Play แล้ว Stop ระหว่างรัน สคริปต์จะหยุดกลางทาง)
2. ต้องเปิด **Game Settings → Security → Enable Studio Access to API Services** ไว้
3. เปิด **View → Command Bar** แล้ววางโค้ดทั้งก้อน กด Enter
4. ดูผลในหน้าต่าง **Output**

---

## 1) ผู้เล่นใหม่ตั้งแต่วันที่กำหนด

ใช้เวลาประมาณ 2–3 นาที (สแกนผู้เล่นทั้งหมดราว 1,200 คน) แก้วันที่เริ่มได้ที่บรรทัด `SINCE` (เวลาไทย)

```lua
-- ผู้เล่นใหม่ตั้งแต่วันที่กำหนด (เวลาไทย) : อ่านอย่างเดียว ไม่เขียนข้อมูล
local SINCE = {year=2026, month=11, day=16, hour=0}   -- << แก้วันที่ตรงนี้

local DSS     = game:GetService("DataStoreService")
local Level   = DSS:GetDataStore("PlayerLevel_v1")
local Lessons = DSS:GetDataStore("Lessons_v1")
local Coins   = DSS:GetDataStore("PlayerCoins_v1")
local Play    = DSS:GetOrderedDataStore("PlaytimeLeaderboard_v1")
local sinceMs = DateTime.fromUniversalTime(SINCE.year, SINCE.month, SINCE.day, SINCE.hour - 7, 0, 0).UnixTimestampMillis
local function th(ms) return DateTime.fromUnixTimestampMillis(ms + 7*3600000):FormatUniversalTime("MM-DD HH:mm", "en-us") end
local function get(fn) for _ = 1, 4 do local ok, a, b = pcall(fn) if ok then return a, b end task.wait(2) end return "ERR" end

task.spawn(function()
	-- 1) รายชื่อคีย์ทั้งหมด
	local keys, pages = {}, Level:ListKeysAsync()
	while true do
		for _, k in ipairs(pages:GetCurrentPage()) do table.insert(keys, k.KeyName) end
		if pages.IsFinished then break end
		pages:AdvanceToNextPageAsync()
	end
	print("ทั้งหมด", #keys, "คีย์ กำลังสแกน...")

	-- 2) หาคีย์ที่สร้างหลังวันที่กำหนด (4 งานพร้อมกัน)
	local new, idx, fin = {}, 0, 0
	for _ = 1, 4 do task.spawn(function()
		while true do
			idx += 1; local i = idx; if i > #keys then break end
			local val, info = get(function() return Level:GetAsync(keys[i]) end)
			if typeof(info) == "Instance" and info.CreatedTime >= sinceMs then
				table.insert(new, {key = keys[i], created = info.CreatedTime, lv = type(val) == "table" and val.Level or val})
			end
		end
		fin += 1
	end) end
	while fin < 4 do task.wait(1) end
	table.sort(new, function(a, b) return a.created < b.created end)

	-- 3) รายละเอียดแต่ละคน
	print(("ผู้เล่นใหม่ %d คน"):format(#new))
	for _, r in ipairs(new) do
		local name = get(function() return game.Players:GetNameFromUserIdAsync(tonumber(r.key)) end)
		local les  = get(function() return Lessons:GetAsync(r.key) end)
		local min  = get(function() return Play:GetAsync(r.key) end)
		local coin = get(function() return Coins:GetAsync(r.key) end)
		local done, got = {}, {}
		if type(les) == "table" then
			for id in pairs(les.ready or {}) do table.insert(done, id) end
			for id in pairs(les.claimed or {}) do table.insert(got, id) end
		end
		print(("%s | เข้า %s | Lv%s | เล่น %s นาที | เหรียญ %s | บทเรียนผ่าน: %s | รับรางวัลแล้ว: %s"):format(
			tostring(name), th(r.created), tostring(r.lv), tostring(min or "<1"), tostring(coin),
			#done > 0 and table.concat(done, ",") or "-", #got > 0 and table.concat(got, ",") or "-"))
		task.wait(0.3)
	end
	print("เสร็จแล้ว")
end)
```

### อ่านผลยังไง

| ที่เห็น | ความหมาย |
|---|---|
| **บทเรียนผ่าน** `basic` | ทำบท ซื้อเมล็ด → ปลูก → เก็บ → ขาย ครบ |
| **บทเรียนผ่าน** `fish` | ทำบทตกปลาครบ |
| **บทเรียนผ่าน** `pet` | ทำบทสัตว์เลี้ยงครบ |
| ผ่านแล้วแต่ไม่อยู่ใน **รับรางวัลแล้ว** | ทำครบแล้ว แต่ยังไม่ได้ไปกดรับที่หุ่นนกฮูก |
| **เหรียญ 200000** | เข้ามาแล้วยังไม่ได้ทำอะไร (เงินเริ่ม 100,000 + ของขวัญต้อนรับ 100,000) |
| **เหรียญ 199,9xx** | ซื้อเมล็ดแล้ว แต่ยังไม่ได้ขายผลผลิต |
| **เหรียญ 100000** | ออกไปก่อนของขวัญต้อนรับจะเข้า |
| **เล่น `<1` นาที** | ไม่มีข้อมูลเวลาเล่น = ออกภายในไม่ถึง 1 นาที |

- ระบบ**ไม่ได้เซฟ**ว่าผู้เล่นเดินตามลูกศรสอนถึงขั้นไหน ดูได้แค่ว่าผ่านบทไหนแล้ว แล้วเดาจากเหรียญกับเลเวล
- ถ้า Output ขึ้นว่าอ่านถี่เกินกำหนด (`Throttled`) ไม่ต้องตกใจ สคริปต์ลองอ่านใหม่เองสูงสุด 4 ครั้ง แต่อาจตกหล่นได้ 1–2 คน
- เวลาเล่นนับรวมเวลายืน AFK ด้วย

---

## 2) เซิร์ฟล่มไหม (เซิร์ฟที่เปิดในช่วงที่กำหนด)

ใช้เวลาประมาณ 1 นาที เซิร์ฟเกมจริงทุกตัวบันทึกสุขภาพทุก 5 นาทีลง `ServerHealth_v1` (`ServerScriptService.ServerHealthLogger`)

```lua
-- เซิร์ฟที่บันทึกตั้งแต่วันที่กำหนด (เวลาไทย) : อ่านอย่างเดียว
local SINCE = {year=2026, month=11, day=16, hour=0}   -- << แก้วันที่ตรงนี้

local st = game:GetService("DataStoreService"):GetDataStore("ServerHealth_v1")
local sinceMs = DateTime.fromUniversalTime(SINCE.year, SINCE.month, SINCE.day, SINCE.hour - 7, 0, 0).UnixTimestampMillis
local function th(s) if not s then return "?" end if s > 1e11 then s = s / 1000 end
	return DateTime.fromUnixTimestamp(math.floor(s) + 7*3600):FormatUniversalTime("MM-DD HH:mm", "en-us") end

task.spawn(function()
	local keys, pages = {}, st:ListKeysAsync()
	while true do
		for _, k in ipairs(pages:GetCurrentPage()) do table.insert(keys, k.KeyName) end
		if pages.IsFinished then break end
		pages:AdvanceToNextPageAsync()
	end
	local rows = {}
	for _, k in ipairs(keys) do
		for _ = 1, 3 do
			local ok, v, info = pcall(function() return st:GetAsync(k) end)
			if ok then
				if info and info.UpdatedTime >= sinceMs and type(v) == "table" then table.insert(rows, v) end
				break
			end
			task.wait(2)
		end
	end
	table.sort(rows, function(a, b) return (a.startedAt or 0) < (b.startedAt or 0) end)
	for _, v in ipairs(rows) do
		local rec, gaps = v.recent or {}, {}
		for i = 2, #rec do
			if (rec[i].t or 0) - (rec[i-1].t or 0) > 420 then table.insert(gaps, th(rec[i-1].t) .. "→" .. th(rec[i].t)) end
		end
		local first, last = (v.hourly or {})[1] or rec[1] or {}, rec[#rec] or {}
		print(("v%s | %s → %s | ผู้เล่นตอนท้าย %s | %d MB | FPS %s | ช่วงขาด: %s"):format(
			tostring(v.placeVersion), th(first.t), th(last.t), tostring(last.players),
			math.floor(last.memMb or 0), tostring(last.fps and math.floor(last.fps)),
			#gaps > 0 and table.concat(gaps, "; ") or "-"))
	end
	print("เสร็จแล้ว")
end)
```

### อ่านผลยังไง

- แต่ละบรรทัดคือเซิร์ฟ 1 ตัว: เวลาเริ่ม → บันทึกครั้งสุดท้าย
- **ปกติ**: เซิร์ฟตัวเก่าจบแล้วตัวใหม่เริ่มภายใน 1–2 นาที ตรงกับรอบรีสตาร์ท 01:00 / 09:00 / 17:00 หรือตอน Publish (เลขเวอร์ชัน `v` จะเปลี่ยน)
- **น่าสงสัยว่าล่ม**: เซิร์ฟจบกลางรอบ (ไม่ใช่เวลารีสตาร์ท) เวอร์ชันไม่เปลี่ยน หรือมี **ช่วงขาด** (บันทึกหายเกิน 7 นาที)
- หน่วยความจำปกติราว 0.9–1.1 GB ถ้าไต่ขึ้นเรื่อยๆ ถึง 2 GB ขึ้นไป แปลว่ามีอาการรั่ว
- บันทึกละเอียด (ทุก 5 นาที) เก็บย้อนหลังได้แค่ 5 ชั่วโมงสุดท้ายของแต่ละเซิร์ฟ ช่วงก่อนหน้านั้นเหลือแค่รายชั่วโมง
