-- BACKUP of game.StarterPlayer.StarterPlayerScripts.RodShowcaseFx (Studio Source, byte-exact, len 5217 hash 643213239)
-- Restore: paste everything below this header into game.StarterPlayer.StarterPlayerScripts.RodShowcaseFx.Source in Studio.
-- RodShowcaseFx: ตู้โชว์เบ็ดข้างร้านตกปลา (workspace.RodShowcase) ฝั่งผู้เล่น
--   ป้ายบนตู้: ชื่อ / โชค / ระยะ / ปลากินเร็วขึ้น % (เทียบเบ็ดไม้ไผ่ สูตรเดียวกับหน้าร้านตกปลา) / จุดเด่น / ราคา อ่านจาก FishingConfig ตามภาษาผู้เล่น
--   ปุ่มหน้าตู้: "ซื้อ R$ .." หรือ "มีแล้ว ✓" ถ้ามีเบ็ดนั้นในกระเป๋า
--   เบ็ดในตู้ (RodShowcase ฝั่งเซิร์ฟเวอร์วางไว้) หมุนช้าๆ รอบแกนตั้ง เฉพาะตอนอยู่ใกล้
--   เกมเปิด StreamingEnabled: ตู้ตั้งเป็น ModelStreamingMode Persistent แล้ว แต่ยังเช็กซ้ำทุก 1 วิ เผื่อของโหลดมาทีหลัง

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local tr, lang = require(ReplicatedStorage:WaitForChild("Localization")).Tr()
local player = Players.LocalPlayer

local SPIN_SPEED = math.rad(22) -- องศา/วินาที
local NEAR = 110
local gate = require(ReplicatedStorage:WaitForChild("FxThrottle")).Gate() -- ระดับต่ำ = หมุนน้อยครั้งลง / ต่ำสุด = หยุด (2026-10-24)
local BASE_BITE = (Config.Rods.Bamboo.BiteTime[1] + Config.Rods.Bamboo.BiteTime[2]) / 2
local EXTRA = {
	SunBee = { "⭐ ปลา 3 ดาวขึ้นไปทุกตัว", "⭐ Every fish 3★ or better" },
	NightMoth = { "🎣 ได้ปลาทุกระดับ ถึงระดับลับ", "🎣 Catches every tier, even Secret" },
}

local function ownsRod(rodId)
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, t in ipairs(loc and loc:GetChildren() or {}) do
			if t:IsA("Tool") and t:GetAttribute("RodId") == rodId then return true end
		end
	end
	return false
end

local function setText(label, text)
	if label and label.Text ~= text then label.Text = text end
end

local function refreshCase(case)
	local rodId = case:GetAttribute("RodId")
	local rod = rodId and Config.Rods[rodId]
	if not rod then return end
	local board = case:FindFirstChild("SignBoard")
	local gui = board and board:FindFirstChild("SignGui")
	if gui then
		local avg = (rod.BiteTime[1] + rod.BiteTime[2]) / 2
		local faster = math.floor((1 - avg / BASE_BITE) * 100 + 0.5)
		local extra = EXTRA[rodId]
		setText(gui:FindFirstChild("Title"), rod.Icon .. " " .. Config.RodName(rodId, lang))
		setText(gui:FindFirstChild("Luck"), tr("🍀 โชค x", "🍀 Luck x") .. tostring(rod.Luck))
		setText(gui:FindFirstChild("Range"), tr("📏 ระยะเหวี่ยง ", "📏 Cast range ") .. tostring(rod.CastDistance))
		setText(gui:FindFirstChild("Bite"), string.format(tr("⏱️ ปลากินเร็วขึ้น %d%%", "⏱️ Bites %d%% faster"), faster))
		setText(gui:FindFirstChild("Extra"), extra and tr(extra[1], extra[2]) or "")
		setText(gui:FindFirstChild("Price"), rod.RobuxPrice and ("R$ " .. rod.RobuxPrice) or "")
	end
	local prompt = case:FindFirstChild("BuyRodPrompt", true)
	if prompt then
		local obj = rod.Icon .. " " .. Config.RodName(rodId, lang)
		local action
		if ownsRod(rodId) then
			action = tr("มีแล้ว ✓", "Owned ✓")
		elseif rod.OnSale == false or (tonumber(rod.ProductId) or 0) <= 0 then
			action = tr("ยังไม่เปิดขาย", "Not for sale yet")
		else
			action = tr("ซื้อ R$ ", "Buy R$ ") .. tostring(rod.RobuxPrice)
		end
		if prompt.ObjectText ~= obj then prompt.ObjectText = obj end
		if prompt.ActionText ~= action then prompt.ActionText = action end
	end
end

task.spawn(function()
	while true do
		local showcase = workspace:FindFirstChild("RodShowcase")
		if showcase then
			for _, case in ipairs(showcase:GetChildren()) do
				if case:IsA("Model") then refreshCase(case) end
			end
		end
		task.wait(1)
	end
end)

-- หมุนเบ็ดในตู้
RunService.RenderStepped:Connect(function(dt)
	dt = gate(dt)
	if not dt then return end
	local showcase = workspace:FindFirstChild("RodShowcase")
	local cam = workspace.CurrentCamera
	if not (showcase and cam) then return end
	-- 2026-10-08 ตู้แยกซ้าย-ขวาร้านตกปลา แต่ละตู้มีแท่น (Platform) ของตัวเอง
	for _, case in ipairs(showcase:GetChildren()) do
		local rod = case:FindFirstChild("ShowcaseRod")
		local center = rod and rod:GetAttribute("SlotCenter")
		if center and (cam.CFrame.Position - center).Magnitude <= NEAR then
			rod:PivotTo(CFrame.new(center) * CFrame.Angles(0, SPIN_SPEED * dt, 0) * CFrame.new(-center) * rod:GetPivot())
		end
	end
end)
