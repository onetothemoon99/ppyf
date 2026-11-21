-- BACKUP of ServerScriptService.WeatherService taken 2026-11-21 before the log trim / lowest-graphics change.
-- Restore: in Studio open ServerScriptService.WeatherService, select all, paste everything BELOW the next line.
-- ===== original Source (2301 bytes, hash 776262527) =====
-- WeatherService: สุ่มสลับฟ้าใส / ฝนตก ทั้งเซิร์ฟเวอร์เหมือนกัน (ค่าต่างๆ ดู ReplicatedStorage.WeatherConfig)
-- ภาพ/เสียงฝนทำฝั่งผู้เล่น (WeatherClient) โบนัสพืชโต/ปลากินอ่านจาก WeatherConfig.IsRaining() ใน PlantingSystem / FishingSystem
-- ทดสอบใน Studio: ตั้ง Attribute "DevRain" ของ workspace = true (ฝนตกทันที) / false (หยุดทันที)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("WeatherConfig"))
local harvestNotify = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HarvestNotify")

local rng = Random.new()

local function setWeather(kind, seconds, announce)
	workspace:SetAttribute("Weather", kind)
	workspace:SetAttribute("WeatherEndsAt", os.time() + math.floor(seconds))
	if announce then
		if kind == "Rain" then
			harvestNotify:FireAllClients(nil, nil, nil, "🌧️ ฝนตกแล้ว! พืชโตเร็วขึ้น 25% · ปลากินเร็วขึ้น 20%")
		else
			harvestNotify:FireAllClients(nil, nil, nil, "☀️ ฝนหยุดแล้ว ฟ้าใสอีกครั้ง")
		end
	end
	print(string.format("🌦️ Weather: %s %d วินาที", kind, seconds))
end

local function minutes(range) return rng:NextNumber(range[1], range[2]) * 60 end

setWeather("Clear", minutes(Config.CLEAR_MINUTES), false)

if RunService:IsStudio() then
	workspace:GetAttributeChangedSignal("DevRain"):Connect(function()
		local v = workspace:GetAttribute("DevRain")
		if v == true then
			setWeather("Rain", minutes(Config.RAIN_MINUTES), true)
		elseif v == false then
			setWeather("Clear", minutes(Config.CLEAR_MINUTES), true)
		end
		workspace:SetAttribute("DevRain", nil)
	end)
end

while true do
	task.wait(1)
	if os.time() >= (workspace:GetAttribute("WeatherEndsAt") or 0) then
		if Config.IsRaining() then
			setWeather("Clear", minutes(Config.CLEAR_MINUTES), true)
		else
			setWeather("Rain", minutes(Config.RAIN_MINUTES), true)
		end
	end
end
