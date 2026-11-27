-- BACKUP of game.ServerScriptService.FishingSystem (full Source, 65556 bytes) taken 2026-11-26 before the Sakura Jellyfish rod.
-- Restore: in Studio open game.ServerScriptService.FishingSystem, select all, paste everything below this header.
-- FishingSystem: ตกปลา (ฝั่งเซิร์ฟเวอร์ ตัดสินทุกอย่างที่นี่) ค่าต่างๆ ดู ReplicatedStorage.FishingConfig
-- เหวี่ยงเบ็ดลงน้ำ -> ทุ่น + สายเบ็ด (ทุกคนเห็น) -> ปลากินตามเวลาสุ่ม (สุ่มตัวปลาตอนนี้เลย)
--   ตกเอง: ทุ่นจม ❗ -> กดเกี่ยวทันเวลา -> มินิเกม (ความยากตามระดับปลา) -> ชนะ = ได้ปลา, แพ้ = ปลาหลุด รอตัวใหม่ต่อ
--   ตกออโต้ (Attribute "FishingAuto" บนตัวผู้เล่น): ปลากินช้าลง โอกาสปลาหายากขึ้นไปลดลง ดึงให้เอง สายอยู่ในน้ำต่อ
-- ปลาที่ได้: ตามแหล่งน้ำตรงทุ่น (getZone) + โชคของเบ็ด + กลางวัน/กลางคืน ขนาดสุ่ม -> ดาว -> ราคา (FishingConfig.Fish)
-- ผู้เล่นส่งมาแค่ "จุดที่อยากเหวี่ยง" / "เกี่ยว" / "ผลมินิเกม" เซิร์ฟเวอร์เช็กว่าถือเบ็ดจริง จุดเป็นน้ำจริง อยู่ในระยะ ทันเวลา
--   และมินิเกมต้องใช้เวลาไม่น้อยกว่า MinTime (หลอดเต็มเร็วกว่านี้ไม่ได้จริง)

local dprint = require(game:GetService("ReplicatedStorage"):WaitForChild("DevLog")) -- per-action logs: Studio only / DevLog attr (2026-11-21)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local CraftConfig = require(ReplicatedStorage:WaitForChild("CraftConfig")) -- เบ็ดของน้องนาก (โต๊ะช่างนากน้อย 2026-10-09)
-- เบ็ดนากที่เจ้าของใส่ช่องเบ็ดนากไว้ (Attribute PetRodBest จาก CraftBench = คันที่เลือกใช้ 2026-10-10) ระบบคราฟยังปิด = ไม่มีผล
local function petRodOf(player)
	if not CraftConfig.ENABLED or not player then return nil end
	local id = player:GetAttribute("PetRodBest")
	return id and CraftConfig.PetRods[id] or nil
end
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local templates = ServerStorage:WaitForChild("FishingTemplates")
local ItemFactory = require(game:GetService("ServerScriptService"):WaitForChild("ItemFactory"))
local FishIndex = require(game:GetService("ServerScriptService"):WaitForChild("FishIndex"))
local Achievement = require(game:GetService("ServerScriptService"):WaitForChild("AchievementService")) -- เหรียญตรา Roblox: นับยอดตกปลาสะสม ไม่นับขยะ (2026-11-04)
local FishingPetBonus = require(game:GetService("ServerScriptService"):WaitForChild("FishingPetBonus"))
local WeatherConfig = require(ReplicatedStorage:WaitForChild("WeatherConfig")) -- ฝนตก = ปลากินเร็วขึ้น
local LevelSystem = require(game:GetService("ServerScriptService"):WaitForChild("LevelSystem")) -- ตกปลาได้ XP (Config.CatchXP)
-- อีเวนต์เก็บขยะที่ทะเลสาบหมอกเช้า (2026-10-12): ระหว่างรอบ ตกในทะเลสาบนั้น = ขยะเพิ่ม + ขยะมีค่าออกบ่อยขึ้น (rollFish)
--   ได้ขยะแล้วแจ้ง TrashEventService (BindableEvent JunkCaught) ให้นับภารกิจ ระบบนั้นพัง/ไม่มี = ตกปลาปกติ
local TrashEvent = require(ReplicatedStorage:WaitForChild("TrashEventConfig"))
local function reportJunk(player, pos, amount)
	pcall(function()
		local service = game:GetService("ServerScriptService"):FindFirstChild("TrashEventService")
		local event = service and service:FindFirstChild("JunkCaught")
		if event and pos then event:Fire(player, pos, amount or 1) end
	end)
end

local rng = Random.new()

local mothOrbitEffects = {}
local mothEffectTime = 0


local function makeMoth(parent, color)
 local model = Instance.new("Model")
 model.Name = "OrbitingButterfly"
 local function p(name, size, mat)
  local x = Instance.new("Part")
  x.Name, x.Shape, x.Size, x.Color, x.Material = name, Enum.PartType.Ball, size, color, mat
  x.Anchored, x.CanCollide, x.CanTouch, x.CanQuery, x.CastShadow = true, false, false, false, false
  x.Parent = model
  return x
 end
 local a=p("WingL",Vector3.new(.18,.04,.14),Enum.Material.Neon)
 local b=p("WingR",Vector3.new(.18,.04,.14),Enum.Material.Neon)
 local c=p("Body",Vector3.new(.04,.12,.04),Enum.Material.SmoothPlastic)
 model.Parent=parent
 return {model=model,a=a,b=b,c=c,phase=math.random()*6.28}
end


local function updateNightMothLight(parent, name, color, brightness, range, enabled)
 local light = parent:FindFirstChild(name)
 if not light then light = Instance.new("PointLight") light.Name = name light.Parent = parent end
 light.Color, light.Brightness, light.Range, light.Shadows, light.Enabled = color, brightness, range, false, enabled
 return light
end

local mothEffectConnection = RunService.Heartbeat:Connect(function(dt)
 mothEffectTime += dt
 local equipped = {}
 for _, plr in ipairs(Players:GetPlayers()) do
  local char=plr.Character
  if char then for _, tool in ipairs(char:GetChildren()) do
   -- 2026-10-08 เบ็ดผึ้งตะวันฉาย: แสงสีทอง + ไฮไลต์เหลืองอร่ามครอบทั้งคัน (ผึ้งบิน/ประกายเป็น ParticleEmitter ในเทมเพลต Rod_SunBee)
   -- 2026-10-11 ลดแสงลง 15% (ผู้เล่นขอ): ไฟ 1.8 -> 1.53, ไฮไลต์ 0.82/0.15 -> 0.847/0.278 · รอบ 2 ลดอีก 15%: ไฟ 1.3, ไฮไลต์ 0.87/0.386 · รอบ 3 ลดอีก 5%: ไฟ 1.235, ไฮไลต์ 0.877/0.417
   if tool:IsA("Tool") and tool:GetAttribute("RodId")=="SunBee" then
    local grip = tool:FindFirstChild("Grip", true) or tool:FindFirstChild("Handle", true)
    if grip and grip:IsA("BasePart") then
     updateNightMothLight(grip, "SunBeeAuraGold", Color3.fromRGB(255,205,80), 1.235, 10, true)
     local aura = tool:FindFirstChild("SunBeeAura")
     if not aura then aura = Instance.new("Highlight") aura.Name = "SunBeeAura" aura.Parent = tool end
     aura.Adornee, aura.FillColor, aura.FillTransparency = tool, Color3.fromRGB(255,195,40), 0.877
     aura.OutlineColor, aura.OutlineTransparency, aura.Enabled = Color3.fromRGB(255,235,130), 0.417, true
     aura.DepthMode = Enum.HighlightDepthMode.Occluded
    end
   end
   if tool:IsA("Tool") and tool:GetAttribute("RodId")=="NightMoth" then
    local isNight = Lighting.ClockTime >= 18 or Lighting.ClockTime < 6
    local grip = tool:FindFirstChild("Grip", true) or tool:FindFirstChild("Handle", true)
    if grip and grip:IsA("BasePart") then
     -- 2026-10-08 ออร่าม่วงตามภาพต้นแบบ: เปิดตลอด (เกมเป็นกลางวันอย่างเดียว เดิมเปิดเฉพาะกลางคืนเลยไม่เคยขึ้น) + ไฮไลต์ครอบทั้งคัน
     updateNightMothLight(grip, "NightMothAuraPurple", Color3.fromRGB(176,126,255), 1.8, 9, true)
     updateNightMothLight(grip, "NightMothAuraWhite", Color3.fromRGB(246,239,255), 0.85, 6, isNight)
     local aura = tool:FindFirstChild("NightMothGripAura")
     if not aura then aura = Instance.new("Highlight") aura.Name = "NightMothGripAura" aura.Parent = tool end
     aura.Adornee, aura.FillColor, aura.FillTransparency = tool, Color3.fromRGB(150,85,255), 0.8
     aura.OutlineColor, aura.OutlineTransparency, aura.Enabled = Color3.fromRGB(205,160,255), 0.15, true
     aura.DepthMode = Enum.HighlightDepthMode.Occluded
    end    local tip=tool:FindFirstChild("RodTip",true)
    if tip and tip:IsA("Attachment") then
     equipped[tool]=tip
     if not mothOrbitEffects[tool] then
      local folder=Instance.new("Folder")
      folder.Name="NightMothButterflies_"..plr.UserId
      folder.Parent=workspace
      local bugs={}
      -- 2026-10-07 เลิกผีเสื้อบินวน (เดิม 3 ตัว เรนเดอร์เป็นจุดกลม) ใช้ ParticleEmitter Pole.ButterflyAura ในเทมเพลตแทน
      for n=1,0 do local colors={Color3.fromRGB(220,170,255),Color3.fromRGB(255,190,240),Color3.fromRGB(185,145,255)} bugs[n]=makeMoth(folder,colors[n]) end
      mothOrbitEffects[tool]={folder=folder,bugs=bugs}
     end
    end
   end
  end end
 end
 local isNight = Lighting.ClockTime >= 18 or Lighting.ClockTime < 6
 for _, candidate in ipairs(workspace:GetChildren()) do
  if candidate:IsA("Model") and candidate:GetAttribute("NightMothBobber") then
   local glow = candidate:FindFirstChild("NightMothFloatGlow", true)
   if glow and glow:IsA("PointLight") then glow.Enabled = isNight end
  end
 end
 for tool, fx in pairs(mothOrbitEffects) do
  local tip=equipped[tool]
  if not tip or not tip.Parent then fx.folder:Destroy() mothOrbitEffects[tool]=nil
  else for n, bug in ipairs(fx.bugs) do
   local t=mothEffectTime*1.8+bug.phase
   local center=tip.WorldPosition+Vector3.new(math.cos(t)*(.55+n*.10),.62+math.sin(t*1.35)*.22,math.sin(t)*(.55+n*.10))
   local f=CFrame.new(center)*CFrame.Angles(0,-t,0)
   local flap=math.sin(mothEffectTime*13+bug.phase)*.65
   bug.a.CFrame=f*CFrame.new(-.07,0,0)*CFrame.Angles(0,0,flap)
   bug.b.CFrame=f*CFrame.new(.07,0,0)*CFrame.Angles(0,0,-flap)
   bug.c.CFrame=f*CFrame.new(0,0,-.02)
  end end
 end
end)
-- ============ แหล่งน้ำ ============
-- ทะเลสาบ = แอ่งกลมปลายคลองกลาง (มีท่าเรือ) / ลำธาร = น้ำที่สูงกว่าระดับทะเล (บ่อ+ลำธารนาขั้นบันได)
-- ทะเล = ทะเลเปิด (SeaMask: แถว = Z, คอลัมน์ = X ขนาดช่องดู Attribute Step) / ที่เหลือ = คลอง
-- 2026-10-01 สร้าง SeaMask ใหม่จากน้ำจริง: น้ำระดับทะเลที่ต่อถึงขอบแผนที่ผ่านช่องกว้าง (ห่างฝั่งเกิน 40) = ทะเล
--   ทางน้ำแคบในเกาะ (คลองกลาง คลองซอย แม่น้ำฝั่งตะวันออก) = คลอง (เดิมใช้ช่องที่ถมน้ำทะเล ซึ่งรวมคลองไปด้วย คลองเลยขึ้นว่า "ทะเล")
local LAKE_CENTER, LAKE_RADIUS = Vector2.new(-398, -50), 50
-- ทะเลสาบหมอกเช้า (บนเขาในแมพเดินเขา มีป้ายชื่อ ผิวน้ำ y 4): นับเป็นโซนทะเลสาบตามป้าย (2026-10-01 เดิมเป็นลำธารเพราะน้ำสูงกว่าระดับทะเล)
-- ลำธารที่ไหลออกทางตะวันตก (x <= 376) อยู่นอกวงนี้ ยังเป็นลำธารเหมือนเดิม
-- 2026-11-08 ผังเกาะตามรูป: ทะเลสาบหมอกถมแล้ว ใช้ทะเลสาบใหม่ขวาบน (วงรี 62x74 กลาง 282, 405 ผิวน้ำ y 8) แทน · ค่าเดิม (468, -201), 66
-- 2026-11-08 เกาะสร้างใหม่ ×2: ทะเลสาบวงรี กลาง (276, 440) รัศมี x 90 z 176 ผิวน้ำ y 4 → เช็กแบบวงรี (เผื่อขอบ 6) · ค่าก่อนหน้า วงกลม (282, 405) r 80
-- SeaMask สร้างใหม่จากเส้นชายฝั่งเกาะใหม่ (นอกชายฝั่ง = ทะเล) ค่าเดิมดู ServerStorage._IslandKit_20261108.SeaMask_before_rebuild
-- 2026-11-08 ย้อนเกาะเป็น 1:1: ทะเลสาบกลาง (138, 220) รัศมี 45×88 (+เผื่อขอบ 3) · เกาะ ×2 เดิม (276, 440), 96, 182 · SeaMask สร้างใหม่จากชายฝั่งเกาะ 1:1 (ของ ×2 อยู่ ServerStorage._IslandKit_x2_20261108.Scripts.SeaMask)
-- 2026-11-08 ปรับเกาะตามภาพ (ขั้น 2): ทะเลสาบใหญ่ขึ้น กลาง (160, 180) รัศมี 58×98 (+เผื่อขอบ 3) · ก่อนหน้า (138, 220), 48, 91
-- 2026-11-08 เกาะ v5 (ภาพสี ×2): ทะเลสาบกลาง (290, 370) น้ำ 100×150 (+เผื่อขอบ 3) · SeaMask สร้างใหม่จากชายฝั่ง v5 (ของ v4 อยู่ ServerStorage._IslandV5_Parked.SeaMask_v4) · ก่อนหน้า (160, 180), 61, 101
local HILL_LAKE_CENTER, HILL_LAKE_RX, HILL_LAKE_RZ = Vector2.new(290, 370), 103, 153
local seaMask = templates:WaitForChild("SeaMask")
local seaRows = string.split(seaMask.Value, ";")
local MASK_MIN, MASK_STEP = seaMask:GetAttribute("Min"), seaMask:GetAttribute("Step")
local function isSea(x, z)
	local row = seaRows[math.floor((z - MASK_MIN) / MASK_STEP) + 1]
	local col = math.floor((x - MASK_MIN) / MASK_STEP) + 1
	if not row or col < 1 or col > #row then return true end -- นอกตาราง = ทะเลเปิดรอบแผนที่
	return row:sub(col, col) == "1"
end
local function getZone(pos, surfaceY)
	local flat = Vector2.new(pos.X, pos.Z)
	local d = flat - HILL_LAKE_CENTER
	if (d.X / HILL_LAKE_RX) ^ 2 + (d.Y / HILL_LAKE_RZ) ^ 2 <= 1 then return "lake" end
	if surfaceY > 2 then return "stream" end
	-- 2026-10-13 ผังเกาะใหม่ (ผู้ใช้ขอ): น้ำในเกาะฟาร์มนับเป็น "คลอง" ทั้งหมด แอ่งปลายคลอง (LAKE_CENTER) ไม่นับเป็นทะเลสาบแล้ว — ทะเลสาบเหลือแค่ทะเลสาบหมอกเช้าบนเขา
	if isSea(pos.X, pos.Z) then return "sea" end
	return "canal"
end

-- ============ สุ่มปลา ============
local TIER_ORDER = { "Secret", "Legendary", "Rare", "Common" }
local function rollFish(zone, luck, auto, rodId, extraMinStar, tierOverride, pos, player) -- player = เจ้าของ (บัฟลอยกระทง) / extraMinStar = ดาวขั้นต่ำจากเบ็ดนาก / tierOverride = { weights, luck } ตารางระดับของเบ็ดนาก / pos = จุดที่ทุ่นอยู่ (อีเวนต์เก็บขยะ)
	local rodDef = Config.Rods[rodId]
	-- อีเวนต์เก็บขยะ: ทุ่นอยู่ในทะเลสาบที่มีอีเวนต์ = โอกาสขยะบวกเพิ่มตรงๆ (เท่ากันทุกเบ็ด) + ขยะมีค่าออกบ่อยขึ้น
	local trashEvent = pos ~= nil and TrashEvent.IsActive() and TrashEvent.InArea(pos)
	local junkChance = Config.JunkChance(luck) + (trashEvent and TrashEvent.JUNK_BONUS or 0)
	-- ได้ขยะแทนปลา (เบ็ด/เหยื่อดี = ขยะน้อยลง) เบ็ดที่ตั้ง NoJunk (ผึ้งตะวันฉาย) ไม่ได้ขยะเลย
	if not (rodDef and rodDef.NoJunk) and rng:NextNumber() < junkChance then
		local junkId = Config.PickJunk(rng:NextNumber(), trashEvent and TrashEvent.VALUABLE_MULT or 1) -- สุ่มตาม JunkWeight (ขยะมีค่าออกยาก) เดิมสุ่มเท่ากันทุกชิ้น
		local j = Config.Fish[junkId]
		local size = math.floor((j.Size[1] + (j.Size[2] - j.Size[1]) * rng:NextNumber()) * 10 + 0.5) / 10
		return { fishId = junkId, size = size, star = 1, rarity = j.Rarity }
	end
	local night = Config.IsNight(Lighting.ClockTime)
	local eventFish = Config.ActiveEventFish()
	local pool = {}
	for fishId, fish in pairs(Config.Fish) do
		if (fish.Zone == zone or fish.Zone == "any") and (not fish.Night or night) and (not fish.EventOnly or eventFish[fishId]) and not fish.Junk
			and not fish.Hidden and not fish.Retired then -- Hidden = ปลาใหม่ที่ยังไม่เปิด / Retired = เลิกออกแล้ว (ปลาช่อน)
			pool[fish.Rarity] = pool[fish.Rarity] or {}
			table.insert(pool[fish.Rarity], fishId)
		end
	end
	local weights = tierOverride and Config.TierWeightsFrom(tierOverride.weights, tierOverride.luck, luck)
		or Config.RodWeights(rodId, luck) -- บันไดระดับปลาตามเบ็ด (เบ็ดต่ำไม่มีทางได้ปลาระดับสูง)
	-- 2026-11-20 ZoneLuck (เบ็ดแมลงปอน้อย = { stream = 1.5 }): ตกในแหล่งน้ำนั้น น้ำหนักปลาหายากขึ้นไปคูณเท่านี้ (ไม่เปลี่ยนระดับที่เบ็ดไม่มี)
	local zoneLuck = rodDef and rodDef.ZoneLuck and rodDef.ZoneLuck[zone]
	if zoneLuck and zoneLuck ~= 1 then
		weights = table.clone(weights)
		for _, t in ipairs({ "Rare", "Legendary", "Secret" }) do
			if weights[t] then weights[t] *= zoneLuck end
		end
	end
	if auto then -- ตกออโต้: ปลาดีออกยากขึ้น
		for _, t in ipairs({ "Rare", "Legendary", "Secret" }) do
			if weights[t] then weights[t] *= Config.AUTO.RareMult end
		end
	end
	local total = 0
	for _, tier in ipairs(TIER_ORDER) do
		if pool[tier] then total += weights[tier] end
	end
	local r = rng:NextNumber(0, total)
	local tier = "Common"
	for _, t in ipairs(TIER_ORDER) do
		if pool[t] then
			r -= weights[t]
			if r <= 0 then tier = t break end
		end
	end
	local list = pool[tier] or pool.Common
	-- บัฟลอยกระทง (KrathongService 2026-11-07): โอกาส KrathongEventBonus ได้ปลาอีเวนต์ในระดับเดียวกับที่สุ่มได้ (ไม่เพิ่มโอกาสระดับสูง) ไม่มีปลาอีเวนต์ระดับนั้น = ไม่มีผล
	if player and pool[tier] then
		local bonus = tonumber(player:GetAttribute("KrathongEventBonus")) or 0
		if bonus > 0 and os.time() < (tonumber(player:GetAttribute("KrathongBuffUntil")) or 0) and rng:NextNumber() < bonus then
			local ev = {}
			for _, id in ipairs(pool[tier]) do
				if Config.Fish[id].EventOnly then table.insert(ev, id) end
			end
			if #ev > 0 then list = ev end
		end
	end
	table.sort(list)
	local fishId = list[rng:NextInteger(1, #list)]
	local fish = Config.Fish[fishId]
	local frac = rng:NextNumber() ^ Config.SIZE_SKEW
	-- เบ็ดที่ตั้ง MinStar (ผึ้งตะวันฉาย = 3): บีบขนาดให้อยู่ในช่วงของดาวนั้นขึ้นไป (ตัวเล็กยังออกบ่อยกว่าตัวใหญ่เหมือนเดิม)
	local minStar = rodDef and rodDef.MinStar
	if extraMinStar and (not minStar or extraMinStar > minStar) then minStar = extraMinStar end
	if minStar and minStar > 1 and Config.STAR_BANDS[minStar - 1] then
		local lo = Config.STAR_BANDS[minStar - 1]
		frac = lo + frac * (1 - lo)
	end
	local size = math.floor((fish.Size[1] + (fish.Size[2] - fish.Size[1]) * frac) * 10 + 0.5) / 10
	local star = Config.StarFromFraction(frac)
	if minStar then star = math.max(star, minStar) end
	return { fishId = fishId, size = size, star = star, rarity = fish.Rarity }
end

-- ============ Remote ============
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getRemote(name)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end
local castRemote = getRemote("FishingCast")   -- ผู้เล่น -> เซิร์ฟเวอร์: (จุดเป้าหมาย)
local reelRemote = getRemote("FishingReel")   -- ผู้เล่น -> เซิร์ฟเวอร์: ("hook" / "win" / "lose" / "stop")
local autoRemote = getRemote("FishingAuto")   -- ผู้เล่น -> เซิร์ฟเวอร์: (เปิด/ปิด ตกออโต้)
local stateRemote = getRemote("FishingState") -- เซิร์ฟเวอร์ -> ผู้เล่น: (สถานะ, ข้อมูล)
local baitRemote = getRemote("FishingBait")
local fxRemote = getRemote("FishingFx")         -- เซิร์ฟเวอร์ -> ทุกคน: เอฟเฟกต์ (ดึงเบ็ดขึ้นตอนตกออโต้ได้ปลา)   -- ผู้เล่น -> เซิร์ฟเวอร์: (เลือกเหยื่อ -1 = ดีสุด / 0 = ไม่ใช้ / 1-5 = ดาวนั้น)

local SPLASH_SOUND = "rbxasset://sounds/impact_water.mp3"
local fishingSoundGroup = SoundService:FindFirstChild("EffectSounds")

-- ============ แบนเนอร์ปลาตำนาน/ลับ (ใช้แบนเนอร์เดียวกับตู้สุ่ม GachaAnnouncer) ============
-- 2026-10-01 ผู้เล่นขอ: ไม่ประกาศให้ทุกคนเห็นแล้ว (เดิม ตำนานขึ้นไป = ทั้งเซิร์ฟ / ลับ = ข้ามเซิร์ฟด้วย)
-- ตอนนี้ขึ้นเฉพาะจอของคนที่ตกได้เท่านั้น ไม่ส่งข้ามเซิร์ฟเวอร์
local gachaAnnounce = getRemote("GachaAnnounce")
local ANNOUNCE_TIERS = { Legendary = true, Secret = true }
local function announceCatch(player, fishId, size, star)
	local fish = Config.Fish[fishId]
	if not (fish and ANNOUNCE_TIERS[fish.Rarity]) then return end
	local payload = {
		UserId = player.UserId, Name = player.DisplayName, PetName = Config.FishName(fishId, Localization.GetLanguage(player)), Rarity = fish.Rarity,
		Kind = "Fish", Detail = string.rep("★", star), -- ไม่ใส่น้ำหนัก (ผู้เล่นขอไม่ให้แสดงน้ำหนักตอนตกได้)
	}
	if player.Parent then gachaAnnounce:FireClient(player, payload) end
end

-- [player] = { bobber, tool, phase = "waiting"/"bite"/"reeling", token, deadline, surfaceY, zone, pending, reelStart }
local fishing = {}

local function playSound(parentPart, volume, speed)
	local sound = Instance.new("Sound")
	sound.SoundId = SPLASH_SOUND
	sound.Volume = volume or 0.6
	sound.PlaybackSpeed = speed or 1
	sound.RollOffMaxDistance = 70
	sound.SoundGroup = fishingSoundGroup
	sound.Parent = parentPart
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function heldRod(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("IsFishingRod") then return tool end
	return nil
end

-- 2026-10-18 ผู้ใช้สั่ง: ตกปลามีแต่แบบออโต้ ไม่มีมินิเกมแล้ว (ผู้เล่นเล่นยาก) ทุกคนนับเป็นออโต้เสมอ
-- (เดิมอ่าน Attribute FishingAuto โค้ดมินิเกม/เกี่ยวเองด้านล่างยังอยู่แต่ไม่ถูกใช้ คืนได้ด้วยการให้ฟังก์ชันนี้อ่าน Attribute เหมือนเดิม)
local function isAuto(player)
	return true
end

-- ============ เหยื่อ ============
-- Attribute "FishingBait" บนตัวผู้เล่น: ไม่มี = ใช้ดาวสูงสุดที่มี / 0 = ไม่ใช้ / 1-5 = ใช้ดาวนั้น
local function findBait(player)
	local choice = player:GetAttribute("FishingBait")
	if choice == 0 then return nil end
	local best
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, tool in ipairs(loc and loc:GetChildren() or {}) do
			if tool:IsA("Tool") and tool:GetAttribute("IsBait") and (tool:GetAttribute("Count") or 0) > 0 then
				local star = tool:GetAttribute("Star") or 1
				if choice == star then return tool end
				if choice == nil and (not best or star > (best:GetAttribute("Star") or 1)) then best = tool end
			end
		end
	end
	return best
end

local function stopFishing(player, reason)
	local st = fishing[player]
	if not st then return end
	fishing[player] = nil
	if st.bobber then st.bobber:Destroy() end
	if player.Parent then stateRemote:FireClient(player, "idle", reason) end
end

-- ทุ่น/สายพิเศษตามเบ็ด (ไม่มีในตาราง = ทุ่นแดงธรรมดา สายขาว)
-- template = ชื่อใน FishingTemplates, scale = ScaleTo, lift = ลอยเหนือน้ำ, rot = หมุนทุ่น, line/aura = สีสาย (สองสีไล่จากปลายคันไปทุ่น)
local ROD_BOBBER = {
	NightMoth = {
		template = "Bobber_NightMoth", scale = 0.1111158, lift = 0.22, rot = CFrame.Angles(math.rad(90), 0, 0), attr = "NightMothBobber",
		width = 0.025, line = { Color3.fromRGB(207, 165, 255), Color3.fromRGB(145, 92, 255) },
		aura = { Color3.fromRGB(218, 177, 255), Color3.fromRGB(151, 100, 255) },
	},
	SunBee = { -- 2026-10-08 ทุ่นดอกทานตะวัน (สร้างไว้ขนาดจริงแล้ว ไม่ต้องย่อ) สายทองเรืองแสง
		template = "Bobber_SunBee", lift = 0.06,
		width = 0.025, line = { Color3.fromRGB(255, 236, 140), Color3.fromRGB(255, 190, 40) },
		aura = { Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 180, 30) },
	},
	Phoenix = { -- 2026-11-19 ทุ่นไข่ไฟ (สร้างไว้ขนาดจริงแล้ว จุด pivot = ผิวน้ำ) สายส้มแดงเรืองแสง
		template = "Bobber_Phoenix", lift = 0.03,
		width = 0.025, line = { Color3.fromRGB(255, 210, 110), Color3.fromRGB(240, 80, 30) },
		aura = { Color3.fromRGB(255, 170, 70), Color3.fromRGB(230, 50, 20) },
	},
	Froggy = { -- 2026-11-19 ทุ่นใบบัวมีกบจิ๋ว (สร้างไว้ขนาดจริงแล้ว จุด pivot = ผิวน้ำ) สายเขียวอ่อน
		template = "Bobber_Froggy", lift = 0.01,
		width = 0.025, line = { Color3.fromRGB(200, 245, 160), Color3.fromRGB(110, 200, 90) },
		aura = { Color3.fromRGB(190, 245, 170), Color3.fromRGB(120, 210, 110) },
	},
	Dragonfly = { -- 2026-11-20 ทุ่นดอกบัวสีฟ้ามีแมลงปอเกาะ (ขนาดจริง pivot = ผิวน้ำ) สายสีฟ้าอ่อน
		template = "Bobber_Dragonfly", lift = 0.01,
		width = 0.025, line = { Color3.fromRGB(210, 245, 255), Color3.fromRGB(110, 190, 230) },
		aura = { Color3.fromRGB(200, 240, 255), Color3.fromRGB(150, 160, 255) },
	},
	EarthLove = { -- 2026-10-11 ทุ่นยางรถสีแดง (สร้างไว้ขนาดจริงแล้ว สายขาวธรรมดา)
		template = "Bobber_EarthLove", lift = 0.05,
	},
}

local function bobberUp(st)
	local ball = st.bobber and st.bobber.PrimaryPart
	if ball then
		local pivot = st.bobber:GetPivot()
		local style = st.tool and ROD_BOBBER[st.tool:GetAttribute("RodId")]
		local lift = style and style.lift or 0.05
		st.bobber:PivotTo(CFrame.new(ball.Position.X, st.surfaceY + lift, ball.Position.Z) * pivot.Rotation)
	end
end

-- ให้ปลาที่สุ่มไว้ + แจ้งหน้าจอ
local function giveCatch(player, st, auto)
	local c = st.pending
	st.pending = nil
	if not c then return end
	ItemFactory.GiveFish(player, c.fishId, c.star, 1)
	local fish = Config.Fish[c.fishId]
	if fish.Junk then reportJunk(player, st.bobber:GetPivot().Position, 1) end -- อีเวนต์เก็บขยะ
	if not fish.Junk then pcall(Achievement.Add, player, "fish", 1) end
	playSound(st.bobber.PrimaryPart, 0.8, 0.9)
	local ok, index = pcall(FishIndex.Record, player, c.fishId, c.size, c.star) -- สมุดสะสมปลา (พังก็ไม่ให้การตกปลาพัง)
	if not ok then warn("FishingSystem: บันทึกสมุดปลาไม่สำเร็จ: " .. tostring(index)) index = nil end
	announceCatch(player, c.fishId, c.size, c.star)
	-- XP เลเวล (ตกออโต้ได้ครึ่งเดียว) พังก็ไม่ให้การตกปลาพัง
	local xp = Config.CatchXP(c.fishId, c.star, false) -- ตกออโต้ (แบบเดียวที่เหลือ) ได้ XP เต็ม (2026-10-18) นากยังได้ครึ่งเดียวเหมือนเดิม
	local okXp, errXp = pcall(LevelSystem.AddXP, player, xp, { boost = true }) -- boost = หุ่น EXP (2026-11-19) คืน XP ที่ได้จริง
	if not okXp then warn("FishingSystem: ให้ XP ไม่สำเร็จ: " .. tostring(errXp)) xp = 0
	elseif type(errXp) == "number" then xp = errXp end
	stateRemote:FireClient(player, "caught", {
		fishId = c.fishId, name = fish.Name, rarity = fish.Rarity, size = c.size, star = c.star,
		price = Config.GetPrice(c.fishId, c.star), zone = st.zone, auto = auto, index = index, xp = xp,
	})
	dprint(string.format("🎣 Fishing: %s ตกได้ %s %.1f ซม. ★%d (%s%s)", player.Name, c.fishId, c.size, c.star, st.zone, auto and ", ออโต้" or ""))
end

local scheduleBite

-- ปลาหลุด: สายยังอยู่ในน้ำ รอตัวใหม่ต่อ
local function escape(player, st)
	st.phase = "waiting"
	st.pending = nil
	bobberUp(st)
	stateRemote:FireClient(player, "escaped")
	scheduleBite(player)
end

-- ปลากิน: สุ่มตัวปลาไว้เลย (มินิเกมยากตามระดับ)
local function onBite(player, token)
	local st = fishing[player]
	if not st or st.token ~= token or st.phase ~= "waiting" then return end
	local rod = Config.GetRod(st.tool:GetAttribute("RodId"))
	local auto = isAuto(player)
	local luck = rod.Luck
	local baitTool = st.baitStar and findBait(player)
	if baitTool and baitTool:GetAttribute("Star") == st.baitStar and ItemFactory.TakeBait(player, baitTool) then
		local bait = Config.Bait[st.baitStar]
		if bait then luck += bait.Luck end
	end
	st.pending = rollFish(st.zone, luck, auto, st.tool:GetAttribute("RodId"), nil, nil, st.bobber:GetPivot().Position, player)
	-- ทดสอบใน Studio เท่านั้น: ตั้ง Attribute "DevForceFish" = fishId บนตัวผู้เล่น (จากเซิร์ฟเวอร์) ตัวถัดไปจะเป็นปลานี้
	local forced = RunService:IsStudio() and player:GetAttribute("DevForceFish")
	if forced and Config.Fish[forced] then
		player:SetAttribute("DevForceFish", nil)
		local f = Config.Fish[forced]
		st.pending = { fishId = forced, size = f.Size[2], star = f.Junk and 1 or 5, rarity = f.Rarity }
	end
	local ball = st.bobber.PrimaryPart
	local pivot = st.bobber:GetPivot()
	st.bobber:PivotTo(CFrame.new(ball.Position.X, st.surfaceY - 0.25, ball.Position.Z) * pivot.Rotation) -- ทุ่นจมโดยคงแนวปีก
	playSound(ball, 0.7, 1.2)

	if auto then
		-- ตกออโต้: ดึงให้เองแล้วรอตัวใหม่ต่อ (สายอยู่ในน้ำตลอด)
		st.phase = "bite"
		st.biteStart = os.clock()
		stateRemote:FireClient(player, "bite", { bobber = st.bobber, rarity = st.pending.rarity, auto = true })
		task.delay(Config.AUTO.CatchDelay, function()
			local now = fishing[player]
			if now and now.token == token and now.phase == "bite" then
				local fishId = now.pending and now.pending.fishId
				-- กันค้าง: ให้ปลาพังกลางทางก็ต้องกลับไปรอตัวใหม่เสมอ (เดิมถ้าพังจะค้างที่ "ปลากิน" ตลอดไป = ออโต้หยุดเงียบๆ)
				local okCatch, errCatch = pcall(giveCatch, player, now, true)
				if not okCatch then
					warn("FishingSystem: ให้ปลา (ออโต้) ไม่สำเร็จ: " .. tostring(errCatch))
					stateRemote:FireClient(player, "escaped")
				end
				now.phase = "waiting"
				now.pending = nil
				bobberUp(now)
				-- ทุกคนเห็นท่าดึงเบ็ดขึ้น (ปลาห้อยปลายสาย) แล้วเหวี่ยงกลับลงจุดเดิม (ทำฝั่งผู้เล่นให้ลื่น)
				fxRemote:FireAllClients("autoReel", {
					userId = player.UserId, bobber = now.bobber, fishId = fishId,
					landing = now.bobber:GetPivot().Position,
				})
				scheduleBite(player)
			end
		end)
		return
	end

	st.phase = "bite"
	st.biteStart = os.clock()
	st.deadline = os.clock() + rod.HookWindow
	stateRemote:FireClient(player, "bite", { bobber = st.bobber, window = rod.HookWindow, rarity = st.pending.rarity })
	task.delay(rod.HookWindow + 0.15, function()
		local now = fishing[player]
		if now and now.token == token and now.phase == "bite" then escape(player, now) end
	end)
end

scheduleBite = function(player)
	local st = fishing[player]
	if not st then return end
	st.token += 1
	local token = st.token
	local rod = Config.GetRod(st.tool:GetAttribute("RodId"))
	local mult = isAuto(player) and Config.AUTO.BiteTimeMult or 1
	-- เหยื่อที่จะใช้รอบนี้ (หักตอนปลากิน) ทำให้ปลากินเร็วขึ้น
	local baitTool = findBait(player)
	st.baitStar = baitTool and baitTool:GetAttribute("Star") or nil
	local bait = st.baitStar and Config.Bait[st.baitStar]
	if bait then mult *= bait.BiteMult end
	if WeatherConfig.IsRaining() then mult *= WeatherConfig.RAIN_BITE_MULT end
	-- อีเวนต์เก็บขยะ: ทุ่นอยู่ในทะเลสาบที่มีอีเวนต์ = ปลากินเร็วขึ้น (TrashEventConfig.BITE_MULT)
	if st.bobber and TrashEvent.IsActive() and TrashEvent.InArea(st.bobber:GetPivot().Position) then mult *= TrashEvent.BITE_MULT end
	local wait = rng:NextNumber(rod.BiteTime[1], rod.BiteTime[2]) * mult
	st.biteAt = os.clock() + wait -- เวลาที่ปลาควรกิน (ตัวกันค้างด้านล่างใช้เช็ก)
	task.delay(wait, function()
		-- กันค้าง: onBite พังกลางทาง = ไม่มีใครนัดปลากินรอบถัดไป ให้กลับไปรอตัวใหม่
		local ok, err = pcall(onBite, player, token)
		if ok then return end
		warn("FishingSystem: ปลากินผิดพลาด: " .. tostring(err))
		local now = fishing[player]
		if now and now.token == token then
			now.phase = "waiting"
			now.pending = nil
			pcall(bobberUp, now)
			scheduleBite(player)
		end
	end)
end

castRemote.OnServerEvent:Connect(function(player, target)
	if typeof(target) ~= "Vector3" or target ~= target then return end
	if fishing[player] then return end
	local tool = heldRod(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (tool and root and humanoid and humanoid.Health > 0) then return end
	-- 2026-10-20 ตกปลาบนหลังสัตว์ขี่ได้ (ผู้ใช้ขอ) เดิมเหวี่ยงเบ็ด = ลงจากสัตว์ก่อน (ServerStorage.MountDismount)
	local rod = Config.GetRod(tool:GetAttribute("RodId"))
	-- ต้องอยู่ในระยะเหวี่ยงของเบ็ด (เผื่อเน็ตหน่วงนิดหน่อย)
	local flat = (target - root.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > rod.CastDistance + 6 then return end
	-- จุดนั้นต้องเป็นน้ำจริง (ยิงลงจากด้านบน)
	local params = RaycastParams.new()
	params.IgnoreWater = false
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(Vector3.new(target.X, root.Position.Y + 20, target.Z), Vector3.new(0, -60, 0), params)
	if not (hit and hit.Material == Enum.Material.Water) then
		stateRemote:FireClient(player, "idle", "notwater")
		return
	end
	local tip = tool:FindFirstChild("RodTip", true)
	-- ทุ่นตามเบ็ด (ROD_BOBBER) เทมเพลตหาไม่เจอ = ทุ่นธรรมดา
	local style = ROD_BOBBER[tool:GetAttribute("RodId")]
	local styleTemplate = style and templates:FindFirstChild(style.template)
	if not styleTemplate then style = nil end
	local bobber = (styleTemplate or templates.Bobber):Clone()
	bobber.Name = player.Name .. "_Bobber"
	if style and style.attr then bobber:SetAttribute(style.attr, true) end
	if style then
		if style.scale then bobber:ScaleTo(style.scale) end -- ผีเสื้อราตรี: 2026-10-07 ย่อ 10% แล้วอีก 20% (0.1543275 → 0.13889475 → 0.1111158)
		bobber:PivotTo(CFrame.new(hit.Position + Vector3.new(0, style.lift or 0.05, 0)) * (style.rot or CFrame.identity))
	else
		bobber:PivotTo(CFrame.new(hit.Position + Vector3.new(0, 0.05, 0)))
	end
	local line = Instance.new("Beam")
	line.Name = "FishingLine"
	line.Attachment0 = tip
	line.Attachment1 = bobber:FindFirstChild("LineAttach", true)
	line.Width0, line.Width1 = 0.03, 0.03 -- 2026-10-08 บางลงให้ดูเป็นสายเบ็ดจริง (เดิม 0.04 / ผีเสื้อราตรี 0.035) ความหย่อนของสายทำฝั่งผู้เล่น (FishingFx)
	if style and style.line then
		line.Width0, line.Width1 = style.width or 0.025, style.width or 0.025
		line.Color = ColorSequence.new(style.line[1], style.line[2])
		line.LightEmission = 1
		line.Transparency = NumberSequence.new(0.2)
	else
		line.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
		line.Transparency = NumberSequence.new(0.2)
	end
	line.FaceCamera = true
	line.Segments = 12
	line.CurveSize0 = -1.5 -- สายหย่อนนิดๆ
	line.CurveSize1 = 0
	line.LightInfluence = 0
	line.Parent = bobber.PrimaryPart
	if style and style.aura then
		-- ลำแสงชั้นนอกโปร่งแสงทำเป็นฮาโลรอบสายแกน (ผีเสื้อราตรี = ม่วง, ผึ้งตะวันฉาย = ทอง)
		local auraLine = Instance.new("Beam")
		auraLine.Name = "FishingLineAura"
		auraLine.Attachment0 = tip
		auraLine.Attachment1 = line.Attachment1
		auraLine.Width0, auraLine.Width1 = 0.07, 0.07
		auraLine.Color = ColorSequence.new(style.aura[1], style.aura[2])
		auraLine.Transparency = NumberSequence.new(0.82)
		auraLine.LightEmission = 1
		auraLine.LightInfluence = 0
		auraLine.FaceCamera = true
		auraLine.Segments = 12
		auraLine.CurveSize0 = -1.5
		auraLine.CurveSize1 = 0
		auraLine.Parent = bobber.PrimaryPart
	end
	bobber:SetAttribute("OwnerUserId", player.UserId)
	bobber.Parent = workspace
	playSound(bobber.PrimaryPart, 0.45, 1.4)

	local zone = getZone(hit.Position, hit.Position.Y)
	fishing[player] = { bobber = bobber, tool = tool, phase = "waiting", token = 0, surfaceY = hit.Position.Y, zone = zone }
	stateRemote:FireClient(player, "waiting", { bobber = bobber, zone = zone, auto = isAuto(player) })
	scheduleBite(player)
end)

reelRemote.OnServerEvent:Connect(function(player, action)
	local st = fishing[player]
	if not st then return end
	if action == nil or action == "hook" then
		if st.phase == "bite" and not isAuto(player) and os.clock() <= (st.deadline or 0) + 0.25 then -- เผื่อเน็ตหน่วง 0.25 วิ
			-- เกี่ยวติด: เริ่มมินิเกม (ความยากตามระดับปลาที่สุ่มไว้)
			st.phase = "reeling"
			st.reelStart = os.clock()
			local token = st.token
			local rarity = st.pending.rarity
			local base = Config.Minigame[rarity] or Config.Minigame.Common
			local rod = Config.GetRod(st.tool:GetAttribute("RodId"))
			stateRemote:FireClient(player, "minigame", {
				rarity = rarity, rules = Config.MINIGAME,
				params = { ZoneSize = base.ZoneSize + (rod.ZoneBonus or 0), FishSpeed = base.FishSpeed, FishJump = base.FishJump },
			})
			task.delay(Config.MINIGAME.TimeLimit + 1.5, function()
				local now = fishing[player]
				if now and now.token == token and now.phase == "reeling" then escape(player, now) end
			end)
		elseif st.phase == "waiting" and action == nil then
			stopFishing(player, "reeled") -- คลิกระหว่างรอ = เก็บเบ็ด
		end
	elseif action == "win" then
		if st.phase == "reeling" and os.clock() - st.reelStart >= Config.MINIGAME.MinTime then
			local fishId = st.pending and st.pending.fishId
			giveCatch(player, st, false)
			-- เก็บทุ่นไว้ให้ท่าดึงปลาขึ้น (FishingFx "manualReel") เล่นจบก่อนค่อยลบ
			local bobber = st.bobber
			st.bobber = nil
			stopFishing(player, "caught")
			if bobber then
				fxRemote:FireAllClients("manualReel", {
					userId = player.UserId, bobber = bobber, fishId = fishId, landing = bobber:GetPivot().Position,
				})
				task.delay(1.8, function() bobber:Destroy() end)
			end
		elseif st.phase == "reeling" then
			escape(player, st) -- ชนะเร็วผิดปกติ ไม่นับ
		end
	elseif action == "lose" then
		if st.phase == "reeling" then escape(player, st) end
	elseif action == "stop" then
		stopFishing(player, "reeled")
	end
end)

autoRemote.OnServerEvent:Connect(function(player, on)
	player:SetAttribute("FishingAuto", on == true)
	-- เปิดออโต้ระหว่างปลากิน/เล่นมินิเกมอยู่ ให้จบรอบนั้นเป็นปลาหลุดแล้วรอแบบออโต้ต่อ
	local st = fishing[player]
	if st and (st.phase == "bite" or st.phase == "reeling") and on == true then escape(player, st) end
end)

baitRemote.OnServerEvent:Connect(function(player, choice)
	choice = math.floor(tonumber(choice) or -1)
	if choice < 0 or choice > 5 then
		player:SetAttribute("FishingBait", nil)
	else
		player:SetAttribute("FishingBait", choice)
	end
end)

-- ============ สัตว์ช่วยตกปลา (นาก): เดินไปยืนริมน้ำข้างเจ้าของ ถือเบ็ดของตัวเอง ตกปลาเข้ากระเป๋าเจ้าของ ============
-- ทำงานเฉพาะตอนเจ้าของกำลังตกปลาอยู่ (มีทุ่นในน้ำ) เจ้าของเก็บเบ็ด/เดินไป = เก็บเบ็ดตาม
local PET_BITE_TIME = { 20, 35 } -- ปลากินทุกกี่วินาที (หารด้วยความเร็วสัตว์ = เลเวล x ความอิ่ม) 2026-09-29: ช้าลง 10% (22-38.5) แล้วผู้เล่นขอเร็วขึ้น 10% กลับมา 20-35
local PET_CATCH_DELAY = 1.0      -- ทุ่นจมแล้วดึงขึ้นหลังกี่วินาที
local PET_SIDE = 5               -- จุดตกของสัตว์ห่างจากทุ่นเจ้าของไปด้านข้าง
local PET_ROD_SCALE = 0.5
local helpers = {} -- [player] = { pet, model, waterPoint, surfaceY, zone, bobber, rod, tip, phase = "walk"/"wait"/"bite", token, side }

local helperParams = RaycastParams.new()
helperParams.IgnoreWater = false
helperParams.FilterType = Enum.RaycastFilterType.Exclude
local function waterAt(pos)
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	helperParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 30, pos.Z), Vector3.new(0, -70, 0), helperParams)
	return hit and hit.Material == Enum.Material.Water and hit.Position or nil
end

local function stopHelper(player)
	local h = helpers[player]
	if not h then return end
	helpers[player] = nil
	h.token += 1
	if h.bobber then h.bobber:Destroy() end
	if h.rod then h.rod:Destroy() end
	FishingPetBonus.SetJob(player, nil)
	if player.Parent then player:SetAttribute("FishingPetHelper", nil) end
end

-- ============ นากตกเอง (เจ้าของไม่ได้ตกปลา) ============
-- หาริมน้ำใกล้เจ้าของ: เดินเส้นตรง 16 ทิศออกจากตัวเจ้าของ จุดแรกที่เป็นน้ำ (ถัดจากพื้นดิน) = ริมฝั่ง เลือกทิศที่ใกล้สุด
local SOLO_RADIUS = 35     -- หาน้ำในระยะนี้รอบตัวเจ้าของ
local SOLO_LEAVE = 30      -- เจ้าของเดินห่างจุดที่นากตกเกินนี้ = เก็บเบ็ดแล้วหาจุดใหม่
local SOLO_RETRY = 3       -- ไม่เจอน้ำ ลองหาใหม่ทุกกี่วินาที
local soloSearchAt = {}    -- [player] = เวลาที่หาได้อีกครั้ง
local harvestNotify = remoteEvents:WaitForChild("HarvestNotify")

local function findShoreWater(center)
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	helperParams.FilterDescendantsInstances = ignore
	local best
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local prevLand
		for d = 2, SOLO_RADIUS, 2 do
			local p = center + dir * d
			local hit = workspace:Raycast(Vector3.new(p.X, center.Y + 30, p.Z), Vector3.new(0, -70, 0), helperParams)
			if not hit then break end
			if hit.Material == Enum.Material.Water then
				if prevLand and (not best or d < best.dist) then
					local w = waterAt(p + dir * 3) or hit.Position -- ลงไปในน้ำอีกนิด ไม่ให้ทุ่นเกยฝั่ง
					best = { water = w, land = prevLand, dist = d }
				end
				break
			end
			prevLand = hit.Position
		end
	end
	return best
end

local function startSolo(player, pet, root)
	local shore = findShoreWater(root.Position)
	if not shore then
		soloSearchAt[player] = os.clock() + SOLO_RETRY
		return
	end
	local w = shore.water
	local reach = math.max(2, ((w - shore.land) * Vector3.new(1, 0, 1)).Magnitude)
	helpers[player] = {
		mode = "solo", anchor = root.Position,
		pet = pet, model = pet.model, waterPoint = w, surfaceY = w.Y, zone = getZone(w, w.Y),
		reach = reach, phase = "walk", token = 0, walkStart = os.clock(),
	}
	FishingPetBonus.SetJob(player, { waterPoint = w, reach = reach })
	player:SetAttribute("FishingPetHelper", pet.name)
end

-- โชคของเบ็ดที่ดีที่สุดในกระเป๋า (ตอนเจ้าของไม่ได้ถือเบ็ด)
local function bestRodLuck(player)
	local best = Config.GetRod(nil).Luck
	local bestId = Config.DEFAULT_ROD
	for _, loc in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, t in ipairs(loc and loc:GetChildren() or {}) do
			if t:IsA("Tool") and t:GetAttribute("IsFishingRod") then
				local rod = Config.GetRod(t:GetAttribute("RodId"))
				if rod.Luck > best then best = rod.Luck; bestId = t:GetAttribute("RodId") end
			end
		end
	end
	return best, bestId
end

-- เลือกจุดตกของสัตว์: ข้างทุ่นเจ้าของ ต้องเป็นน้ำจริง
local function startHelper(player, st, pet)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (root and st.bobber and st.bobber.PrimaryPart) then return end
	local bobberPos = st.bobber.PrimaryPart.Position
	local dir = (bobberPos - root.Position) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
	local sideVec = dir:Cross(Vector3.yAxis)
	for _, sgn in ipairs({ 1, -1 }) do
		for _, k in ipairs({ PET_SIDE, PET_SIDE * 0.6, PET_SIDE * 1.4 }) do
			local w = waterAt(bobberPos + sideVec * sgn * k)
			if w then
				-- จุดยืน: ข้างเจ้าของฝั่งเดียวกัน -> ระยะยืนห่างจากจุดในน้ำ
				local stand = root.Position + sideVec * sgn * 3
				local reach = math.max(2.5, ((w - stand) * Vector3.new(1, 0, 1)).Magnitude)
				helpers[player] = {
					mode = "owner",
					pet = pet, model = pet.model, waterPoint = w, surfaceY = w.Y, zone = getZone(w, w.Y),
					reach = reach, phase = "walk", token = 0, walkStart = os.clock(),
				}
				FishingPetBonus.SetJob(player, { waterPoint = w, reach = reach })
				player:SetAttribute("FishingPetHelper", pet.name)
				return
			end
		end
	end
end

-- เบ็ดจิ๋วในมือสัตว์ (ย่อจากเบ็ดไม้ไผ่ ชี้ไปทางที่สัตว์หันหน้า) เจ้าของมีเบ็ดนาก (หอยน้อย/ดาวทะเล) = ถือคันนั้นแทน
local function attachPetRod(h)
	local model = h.model
	local arm = model:FindFirstChild("RightArm", true) or model:FindFirstChild("Right Arm", true)
	if not arm or not arm:IsA("BasePart") then arm = model.PrimaryPart end
	local petRod = petRodOf(h.owner)
	h.rodTemplate = petRod and templates:FindFirstChild(petRod.Template) and petRod.Template or "Rod_Bamboo"
	local rod = templates:FindFirstChild(h.rodTemplate):Clone()
	rod.Name = "PetFishingRod"
	rod:ScaleTo(PET_ROD_SCALE)
	local forward = (h.waterPoint - arm.Position) * Vector3.new(1, 0, 1)
	forward = forward.Magnitude > 0.1 and forward.Unit or Vector3.new(0, 0, -1)
	local hand = arm.Position - Vector3.new(0, arm.Size.Y * 0.3, 0)
	rod:PivotTo(CFrame.lookAt(hand, hand + forward))
	for _, d in ipairs(rod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = rod.PrimaryPart or rod:FindFirstChild("Handle")
	weld.Parent = weld.Part1
	rod.Parent = model
	h.rod = rod
	h.tip = rod:FindFirstChild("RodTip", true)
end

-- ทุ่นของนาก + สายเบ็ดจากปลายคัน (h.tip) เบ็ดนากบางคันมีทุ่นของตัวเอง: CraftConfig.PetRods[id].Bobber (เบ็ดหอยน้อย = หอยสีแดง 2026-10-10)
local function makePetBobber(player, h)
	local petRod = petRodOf(player)
	local template = petRod and petRod.Bobber and templates:FindFirstChild(petRod.Bobber) or templates.Bobber
	local bobber = template:Clone()
	bobber.Name = player.Name .. "_PetBobber"
	bobber:ScaleTo(0.8)
	bobber:PivotTo(CFrame.new(h.waterPoint + Vector3.new(0, 0.05, 0)))
	local line = Instance.new("Beam")
	line.Name = "FishingLine"
	line.Attachment0 = h.tip
	line.Attachment1 = bobber:FindFirstChild("LineAttach", true)
	line.Width0, line.Width1 = 0.03, 0.03
	line.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
	line.Transparency = NumberSequence.new(0.2)
	line.FaceCamera = true
	line.Segments = 12
	line.CurveSize0 = -1
	line.LightInfluence = 0
	line.Parent = bobber.PrimaryPart
	bobber:SetAttribute("OwnerUserId", player.UserId)
	bobber.Parent = workspace
	h.bobber = bobber
	return bobber
end

local scheduleHelperBite

-- เจ้าของคราฟ/ใส่/ถอดเบ็ดนากระหว่างที่นากกำลังตกปลา: เปลี่ยนเบ็ดในมือทันที (สายเบ็ดย้ายไปผูกปลายคันใหม่)
-- เรียกทั้งตอนได้ปลา และทุกรอบ updateHelpers (เดิมเปลี่ยนแค่ตอนได้ปลาตัวถัดไป ดูเหมือนใส่เบ็ดแล้วไม่เปลี่ยน 2026-10-10)
local function refreshHelperRod(player, h)
	local wantRod = petRodOf(player)
	wantRod = wantRod and templates:FindFirstChild(wantRod.Template) and wantRod.Template or "Rod_Bamboo"
	if h.rodTemplate and h.rodTemplate ~= wantRod and h.model and h.model.Parent then
		if h.rod then h.rod:Destroy() end
		h.owner = player
		attachPetRod(h)
		-- ทุ่นเปลี่ยนตามเบ็ดด้วย (สร้างใหม่ที่จุดเดิม ผูกสายกับปลายคันใหม่)
		local oldBobber = h.bobber
		if oldBobber and h.tip then
			makePetBobber(player, h)
			oldBobber:Destroy()
		end
	end
end

local function helperCatch(player, h, token)
	if helpers[player] ~= h or h.token ~= token then return end
	refreshHelperRod(player, h)
	local st = fishing[player]
	local petRod = petRodOf(player) -- เบ็ดนาก: โชค x / ได้ถึงระดับลับ / โอกาสได้ 2 ตัว
	local ownerLuck = st and Config.GetRod(st.tool:GetAttribute("RodId")).Luck or bestRodLuck(player)
	local luck = ownerLuck * (petRod and petRod.LuckMult or 1) + (petRod and petRod.Luck or 0)
	local _, bestRodId = bestRodLuck(player)
	local ownerRodId = st and st.tool:GetAttribute("RodId") or bestRodId
	-- เบ็ดเจ้าของไม่มีระดับลับ = เบ็ดนากใช้ตารางของตัวเอง (ถึงลับ) / มีอยู่แล้ว = ใช้ของเจ้าของ (ไม่แย่ลง)
	local tierOverride
	local ownerRod = Config.Rods[ownerRodId]
	if petRod and not (ownerRod and ownerRod.TierWeights and (ownerRod.TierWeights.Secret or 0) > 0) then
		tierOverride = { weights = CraftConfig.PET_TIER_WEIGHTS, luck = CraftConfig.PET_TIER_LUCK }
	end
	local c = rollFish(h.zone, luck, false, ownerRodId, petRod and petRod.MinStar, tierOverride, h.waterPoint, player)
	local fish = Config.Fish[c.fishId]
	local amount = (petRod and petRod.DoubleChance and rng:NextNumber() < petRod.DoubleChance) and 2 or 1
	ItemFactory.GiveFish(player, c.fishId, c.star, amount)
	if fish.Junk then reportJunk(player, h.waterPoint, amount) end -- อีเวนต์เก็บขยะ (นากเก็บให้ก็นับ)
	if not fish.Junk then pcall(Achievement.Add, player, "fish", amount) end
	pcall(LevelSystem.AddXP, player, Config.CatchXP(c.fishId, c.star, true), { boost = true }) -- นากตกให้ = XP แบบตกออโต้ (ครึ่งเดียว) · เจ้าของยืนในวงหุ่น EXP = คูณด้วย (2026-11-19)
	local okIndex, index = pcall(FishIndex.Record, player, c.fishId, c.size, c.star)
	-- เจ้าของไม่ได้ถือเบ็ด (ไม่เห็นข้อความบนปุ่มตกปลา): แจ้งเฉพาะปลาหายากขึ้นไป / ชนิดใหม่
	local rarityRank = ({ Rare = 1, Legendary = 2, Secret = 3 })[fish.Rarity]
	local isNew = okIndex and index and index.isNew
	if h.mode == "solo" and (rarityRank or isNew) then
		local lang = Localization.GetLanguage(player)
		harvestNotify:FireClient(player, nil, nil, nil, string.format(Localization.Pick(lang, "🦦 %sตกได้: %s %s%s", "🦦 %s caught: %s %s%s"), h.pet.name, Config.FishName(c.fishId, lang),
			(fish.Junk and "" or string.rep("⭐", c.star)) .. (amount > 1 and " x2" or ""), isNew and " 🆕" or ""))
	end
	announceCatch(player, c.fishId, c.size, c.star)
	if h.pet.onHelp then pcall(h.pet.onHelp, petRod and petRod.HungerMult or 1) end -- เบ็ดหอยน้อย: หิวช้าลง
	local ball = h.bobber.PrimaryPart
	h.bobber:PivotTo(CFrame.new(ball.Position.X, h.surfaceY + 0.05, ball.Position.Z))
	playSound(ball, 0.6, 1)
	h.phase = "wait"
	-- ทุกคนเห็นนากดึงเบ็ดขึ้น (ปลาห้อย) แล้วเหวี่ยงกลับจุดเดิม
	fxRemote:FireAllClients("autoReel", {
		userId = player.UserId, bobber = h.bobber, fishId = c.fishId, landing = h.bobber:GetPivot().Position,
		tip = h.tip, pet = true,
	})
	stateRemote:FireClient(player, "petCaught", {
		petName = h.pet.name, fishId = c.fishId, name = fish.Name, star = c.star, rarity = fish.Rarity, count = amount,
	})
	dprint(string.format("🦦 Fishing: นากของ %s ตกได้ %s ★%d x%d (%s)%s", player.Name, c.fishId, c.star, amount, h.zone, petRod and (" เบ็ดนาก " .. tostring(player:GetAttribute("PetRodBest"))) or ""))
	scheduleHelperBite(player, h)
end

scheduleHelperBite = function(player, h)
	h.token += 1
	local token = h.token
	local speed = math.max(0.3, h.pet.speed or 1)
	local rain = WeatherConfig.IsRaining() and WeatherConfig.RAIN_BITE_MULT or 1
	-- อีเวนต์เก็บขยะ: นากตกในทะเลสาบที่มีอีเวนต์ก็เร็วขึ้นเท่ากัน
	if h.waterPoint and TrashEvent.IsActive() and TrashEvent.InArea(h.waterPoint) then rain *= TrashEvent.BITE_MULT end
	local petRod = petRodOf(player)
	local rodMult = petRod and petRod.BiteMult or 1 -- เบ็ดนาก: ปลากินเร็วขึ้น
	task.delay(rng:NextNumber(PET_BITE_TIME[1], PET_BITE_TIME[2]) / speed * rain * rodMult, function()
		if helpers[player] ~= h or h.token ~= token or not h.bobber or not h.bobber.Parent then return end
		h.phase = "bite"
		local ball = h.bobber.PrimaryPart
		h.bobber:PivotTo(CFrame.new(ball.Position.X, h.surfaceY - 0.25, ball.Position.Z)) -- ทุ่นจม
		playSound(ball, 0.5, 1.3)
		task.delay(PET_CATCH_DELAY, helperCatch, player, h, token)
	end)
end

local function castHelper(player, h)
	h.owner = player
	attachPetRod(h)
	if not h.tip then stopHelper(player) return end
	local bobber = makePetBobber(player, h)
	playSound(bobber.PrimaryPart, 0.35, 1.5)
	h.phase = "wait"
	scheduleHelperBite(player, h)
end

local function updateHelpers()
	for _, player in ipairs(Players:GetPlayers()) do
		local st = fishing[player]
		local pet = FishingPetBonus.Get(player)
		local h = helpers[player]
		local ownerFishing = st and st.bobber and st.bobber.Parent
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not (pet and root) then
			if h then stopHelper(player) end
			continue
		end
		if h and (h.pet.petId ~= pet.petId or h.model ~= pet.model or not h.model.Parent) then
			stopHelper(player)
			continue
		end
		-- ตกอยู่แล้ว = ตกต่อที่เดิม (ไม่รีเซ็ตเวลารอปลากิน) ต่อให้เจ้าของเก็บเบ็ด/เหวี่ยงใหม่/สลับตกเอง-ไม่ตก
		-- ย้ายที่เฉพาะตอนเจ้าของเดินห่างจุดตกของนากเกิน SOLO_LEAVE
		-- (เดิมสลับโหมด owner/solo ทุกครั้งที่เจ้าของเก็บเบ็ด: ตกเองทีละตัว = นากเก็บเบ็ด-เหวี่ยงใหม่ทุกตัว ไม่เคยได้ปลา)
		if h then
			local far = ((root.Position - h.waterPoint) * Vector3.new(1, 0, 1)).Magnitude > SOLO_LEAVE + h.reach
			if far then
				stopHelper(player)
				h = nil
				soloSearchAt[player] = os.clock() + 1
			end
		end
		if not h then
			if ownerFishing then
				startHelper(player, st, pet) -- เจ้าของตกอยู่: มายืนตกข้างทุ่นเจ้าของ
			elseif os.clock() >= (soloSearchAt[player] or 0) then
				startSolo(player, pet, root) -- เจ้าของไม่ได้ตก: หาริมน้ำใกล้ๆ ตกเอง
			end
			continue
		end
		h.pet = pet -- ค่าความเร็ว/ความอิ่มล่าสุด
		if h.rod and h.rod.Parent then refreshHelperRod(player, h) end -- เจ้าของเปลี่ยนเบ็ดนาก = เปลี่ยนในมือทันที
		if h.phase == "walk" then
			local flat = (h.model:GetPivot().Position - h.waterPoint) * Vector3.new(1, 0, 1)
			if flat.Magnitude <= h.reach + 2 then
				castHelper(player, h)
			elseif os.clock() - h.walkStart > 12 then
				stopHelper(player) -- ไปไม่ถึง (ติดอะไรอยู่) ลองใหม่รอบหน้า
				soloSearchAt[player] = os.clock() + SOLO_RETRY
			end
		end
	end
end

local helperTimer = 0
RunService.Heartbeat:Connect(function(dt)
	helperTimer += dt
	if helperTimer >= 0.25 then
		helperTimer = 0
		local ok, err = pcall(updateHelpers)
		if not ok then warn("FishingSystem: สัตว์ช่วยตกปลาผิดพลาด: " .. tostring(err)) end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	stopHelper(player)
	soloSearchAt[player] = nil
end)

-- เก็บเบ็ดอัตโนมัติ: ไม่ได้ถือเบ็ดแล้ว / เดินห่างเกิน / ตาย / ออกเกม
RunService.Heartbeat:Connect(function()
	for player, st in pairs(fishing) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and humanoid and humanoid.Health > 0) or st.tool.Parent ~= character then
			stopFishing(player, "unequipped")
		elseif not st.bobber.Parent or (root.Position - st.bobber:GetPivot().Position).Magnitude > Config.MAX_LINE_DISTANCE then
			stopFishing(player, "toofar")
		else
			-- กันค้าง (สายอยู่ในน้ำแต่ไม่มีอะไรเกิดขึ้น): เลยเวลาปลากิน / ค้างที่ปลากิน / ค้างที่มินิเกม นานผิดปกติ = เริ่มรอตัวใหม่
			local t = os.clock()
			if st.phase == "waiting" and st.biteAt and t > st.biteAt + 5 then
				st.biteAt = t + 5
				warn("FishingSystem: ปลาไม่กินตามเวลา นัดใหม่ให้ " .. player.Name)
				pcall(scheduleBite, player)
			elseif st.phase == "bite" and st.biteStart and t > st.biteStart + 8 then
				st.biteStart = t
				warn("FishingSystem: ค้างที่ปลากิน เริ่มรอตัวใหม่ให้ " .. player.Name)
				pcall(escape, player, st)
			elseif st.phase == "reeling" and st.reelStart and t > st.reelStart + Config.MINIGAME.TimeLimit + 6 then
				st.reelStart = t
				warn("FishingSystem: ค้างที่มินิเกม เริ่มรอตัวใหม่ให้ " .. player.Name)
				pcall(escape, player, st)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player) stopFishing(player, "left") end)
