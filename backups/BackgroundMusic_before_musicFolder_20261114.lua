-- BACKUP 2026-11-14, before adding music/ folder songs (Lanterns at Twilight, River of Woven Light, Sky Witches)
-- Studio path: game.StarterPlayer.StarterPlayerScripts."BackgroundMusic " (LocalScript, note the trailing space in the name)
-- Restore: open that script in Studio, select all, paste everything below this header (or set .Source to it), then save.
-- Original Source: 65032 chars.

-- BackgroundMusic: เล่นเพลงพื้นหลังวนไปเรื่อยๆ สลับเพลงในลิสต์แบบสุ่ม
-- + UI สไตล์แผงเพลง (ไอคอนลอยมุมจอ กดเปิดแผงโชว์ชื่อเพลง/ไทม์ไลน์/สไลเดอร์เสียงลากได้)

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local TopbarRow = require(script.Parent:WaitForChild("TopbarRow"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local LANG = Localization.GetLanguage(player)
local audioSettingsSave = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AudioSettingsSave", 30)
local function readSavedVolume(attributeName, fallback)
	local value = player:GetAttribute(attributeName)
	return type(value) == "number" and math.clamp(value, 0, 1) or fallback
end
local initialMusicVolume = readSavedVolume("SavedMusicVolume", 0.25)
local initialEffectVolume = readSavedVolume("SavedEffectVolume", 0.4)
-- 2026-10-08 เอาปุ่มปิด Music Box คนอื่นทั้งหมดออกแล้ว (ผู้เล่นขอ) ค่านี้เป็น false เสมอ คนที่เคยปิดไว้จะได้ยินกลับมา (ปิดรายคนยังทำได้)
local muteOtherBoomboxes = false
local remoteBoomboxVolumes = setmetatable({}, { __mode = "k" })
local mutedBoomboxUserIds = {}
local refreshOtherBoomboxButton
local refreshOtherPlayersList
local setOtherBoomboxMuted
local setOtherPlayerBoomboxMuted
local applyingLoadedSettings = false
local requestSaveAudioSettings
local audioSaveToken = 0

-- ปรับเสียง Boombox ของผู้เล่นอื่นเฉพาะเครื่องนี้ ไม่แตะเสียงของตัวเอง
local function shouldMuteOtherBoombox(userId)
	return muteOtherBoomboxes or mutedBoomboxUserIds[userId] == true
end

local function applyRemoteBoomboxMute(sound, entry)
	if not sound.Parent then return end
	if shouldMuteOtherBoombox(entry.userId) then
		if not entry.applying and sound.Volume > 0 then entry.volume = sound.Volume end
		if sound.Volume ~= 0 then
			entry.applying = true
			sound.Volume = 0
			entry.applying = false
		end
	elseif sound.Volume == 0 then
		entry.applying = true
		sound.Volume = entry.volume
		entry.applying = false
	end
end

local function applyOtherBoomboxSound(sound, otherPlayer)
	if not sound:IsA("Sound") or sound.Name ~= "BoomboxSound" then return end
	local entry = remoteBoomboxVolumes[sound]
	if not entry then
		entry = { volume = sound.Volume, userId = otherPlayer.UserId, applying = false }
		remoteBoomboxVolumes[sound] = entry
		entry.volumeConnection = sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if entry.applying or not sound.Parent then return end
			if shouldMuteOtherBoombox(entry.userId) then
				if sound.Volume > 0 then entry.volume = sound.Volume end
				entry.applying = true
				sound.Volume = 0
				entry.applying = false
			else
				entry.volume = sound.Volume
			end
		end)
	end
	applyRemoteBoomboxMute(sound, entry)
end

local function watchOtherCharacter(otherPlayer, character)
	if otherPlayer == player then return end
	for _, descendant in ipairs(character:GetDescendants()) do
		applyOtherBoomboxSound(descendant, otherPlayer)
	end
	character.DescendantAdded:Connect(function(descendant)
		applyOtherBoomboxSound(descendant, otherPlayer)
	end)
end

local function watchOtherPlayer(otherPlayer)
	if otherPlayer == player then return end
	otherPlayer.CharacterAdded:Connect(function(character)
		watchOtherCharacter(otherPlayer, character)
	end)
	if otherPlayer.Character then
		watchOtherCharacter(otherPlayer, otherPlayer.Character)
	end
end

for _, otherPlayer in ipairs(Players:GetPlayers()) do watchOtherPlayer(otherPlayer) end
Players.PlayerAdded:Connect(watchOtherPlayer)

setOtherBoomboxMuted = function(muted)
	muteOtherBoomboxes = false -- ปุ่มเอาออกแล้ว ไม่ปิดทั้งหมดอีก (ค่าเก่าที่เซฟ true จะถูกทับเป็น false ตอนบันทึกครั้งถัดไป)
	for sound, entry in pairs(remoteBoomboxVolumes) do
		applyRemoteBoomboxMute(sound, entry)
	end
	if refreshOtherBoomboxButton then refreshOtherBoomboxButton() end
end

setOtherPlayerBoomboxMuted = function(userId, muted)
	userId = tonumber(userId)
	if not userId or userId == player.UserId then return end
	mutedBoomboxUserIds[userId] = muted and true or nil
	for sound, entry in pairs(remoteBoomboxVolumes) do
		if entry.userId == userId then applyRemoteBoomboxMute(sound, entry) end
	end
	if refreshOtherPlayersList then refreshOtherPlayersList() end
end

-- ใส่เพลงที่หามาได้ในนี้ ใส่กี่เพลงก็ได้ (อย่างน้อย 1 เพลง) แต่ละเพลงตั้งชื่อเองได้ตามใจ
local PLAYLIST = {
	{ id = "rbxassetid://106354030433248", name = "First Day of Spring" },
	{ id = "rbxassetid://71481369309220", name = "The Orchards Wake" },
	{ id = "rbxassetid://117058241364150", name = "Sunrise Over Mae Sa" },
	{ id = "rbxassetid://87859669153529", name = "Morning in the Orchard" },
	{ id = "rbxassetid://100113261871829", name = "The Fence Line Waltz" },
	{ id = "rbxassetid://81266497481410", name = "Moonlight On The Porch" },
	{ id = "rbxassetid://91317689301085", name = "Resting After the_Harvest" },
	{ id = "rbxassetid://136661978986543", name = "ใต้แสงกระทง" },
	{ id = "rbxassetid://84561776337465", name = "Khomloy Lanna" },
	
}

-- เพลงเลือกตามเวลาในเกม: กลางวัน 07:00-17:00, เย็น 17:00-19:00, ค่ำ 19:00-07:00
-- ใช้รายการเพลงเดิมและตั้งกลุ่มตามชื่อ/บรรยากาศเพลง
local TIME_PLAYLISTS = {
	Day = { PLAYLIST[9],PLAYLIST[8],PLAYLIST[1], PLAYLIST[2], PLAYLIST[3], PLAYLIST[4] },
	Evening = { PLAYLIST[9],PLAYLIST[8],PLAYLIST[5],PLAYLIST[3] },
	Night = { PLAYLIST[9],PLAYLIST[8],PLAYLIST[6], PLAYLIST[6], PLAYLIST[7] }, -- 2026-10-15 ผู้ใช้ขอ: Moonlight On The Porch ใส่ซ้ำ = เล่นบ่อยขึ้น (เพลงที่ใส่ซ้ำเล่นต่อกันได้)
}

-- เพลงกลางคืนช่วงเทศกาล (2026-10-18 ผู้ใช้ขอ: เพลงฮาโลวีน เปิดแค่กลางคืน) เทศกาลเปิดอยู่ (SeasonConfig.IsActive) + ช่วง Night = เล่นรายการนี้แทน Night ปกติ
-- เกมเป็นกลางวันตลอด กลางคืน = ผู้เล่นเลือกช่วง "ตอนค่ำ" ในเมนูเวลาในเกม · เทศกาลจบ = กลับไปเพลงกลางคืนปกติเอง
local SeasonConfig = require(ReplicatedStorage:WaitForChild("SeasonConfig"))
local SEASON_NIGHT = {
	Halloween2026 = { { id = "rbxassetid://91061903312421", name = "Lanterns by the Harvest Gate" } },
}

local function getTimePeriod(clockTime)
	if clockTime >= 17 and clockTime < 19 then return "Evening" end
	if clockTime >= 19 or clockTime < 7 then return "Night" end
	return "Day"
end

local function getMusicClockTime()
	-- PersonalTimeGui ตั้งเวลาภาพเฉพาะผู้เล่นไว้ใน Attribute นี้
	local selectedTime = player:GetAttribute("PersonalVisualClockTime")
	return type(selectedTime) == "number" and selectedTime or Lighting.ClockTime
end

local function tracksForCurrentPeriod()
	local period = getTimePeriod(getMusicClockTime())
	if period == "Night" then
		for seasonId, list in pairs(SEASON_NIGHT) do
			if SeasonConfig.IsActive(seasonId) then return list end
		end
	end
	return TIME_PLAYLISTS[period] or PLAYLIST
end

local DEFAULT_VOLUME = 0.25 -- เพลงพื้นหลังควรเบากว่าเสียงเอฟเฟกต์ในเกม
local EFFECT_DEFAULT_VOLUME = 0.4

local COLOR_PANEL_BG = Color3.fromRGB(25, 25, 28)
local COLOR_TRACK_BG = Color3.fromRGB(70, 70, 75)
local COLOR_FILL = Color3.fromRGB(240, 240, 240)
local COLOR_ICON_BG = Color3.fromRGB(35, 35, 38)

-- กลุ่มลดเสียงชั่วคราว (2026-10-18): สคริปต์อื่นปรับ SoundService.BackgroundMusicDuck.Volume ได้ (เช่น เพลง Happy Birthday ของ WishingPondGui)
-- แยกจาก musicFadeGroup ที่ใช้เฟดตอนเปลี่ยนเพลง จะได้ไม่เขียนทับกัน (SoundGroup ซ้อนกัน = ความดังคูณกัน)
local musicDuckGroup = Instance.new("SoundGroup")
musicDuckGroup.Name = "BackgroundMusicDuck"
musicDuckGroup.Volume = 1
musicDuckGroup.Parent = SoundService

local musicFadeGroup = Instance.new("SoundGroup")
musicFadeGroup.Name = "BackgroundMusicFade"
musicFadeGroup.Volume = 1
musicFadeGroup.Parent = musicDuckGroup

local musicSound = Instance.new("Sound")
musicSound.Name = "BackgroundMusic"
musicSound.Volume = initialMusicVolume
musicSound.SoundGroup = musicFadeGroup
musicSound.Looped = false -- ไม่วนเพลงเดิมซ้ำ จะสลับไปเพลงถัดไปแทน
musicSound.Parent = SoundService

local volumeBeforeMute = initialMusicVolume > 0 and initialMusicVolume or DEFAULT_VOLUME

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

local function pickNextTrack(excludeId)
	local tracks = tracksForCurrentPeriod()
	if #tracks == 0 then return nil end
	if #tracks == 1 then return tracks[1] end

	-- เพลงที่ใส่ไว้หลายครั้งในรายการ = ตั้งใจให้เล่นบ่อย อนุญาตให้เล่นต่อกันได้
	local copies = {}
	for _, t in ipairs(tracks) do copies[t.id] = (copies[t.id] or 0) + 1 end

	local track
	repeat
		track = tracks[math.random(1, #tracks)]
	until track.id ~= excludeId or copies[track.id] > 1 -- กันสุ่มเพลงเดิมซ้ำติดกันภายในช่วงเวลาเดียวกัน

	return track
end

-- ============ UI ============

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MusicPlayerGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.Parent = playerGui

-- ไอคอนเพลง (กดเปิด/ปิดแผงเพลง) อยู่ในแถบบนของ Roblox ต่อจากปุ่มไมค์ ในแถว TopbarRow
-- เดียวกับกล่องเหรียญ/เลเวล (แถวจัดตำแหน่งและเรียงต่อให้เอง ดูโมดูล TopbarRow)
-- แผงเพลงต้องใช้พื้นที่เต็มจอ จึงยังอยู่ใน screenGui หลัก ไม่ย้ายมาที่นี่
-- ปุ่มปิดเสียงด่วนเอาออกแล้ว ปิดเสียงได้จากไอคอนลำโพงในแผงเพลง
local topbarRow = TopbarRow.Get()

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 44, 0, 44) -- เท่าปุ่มของ Roblox
-- หน้าตาเดียวกับปุ่มกลมมุมขวาบน (📖 🐾 🎒 🛒): พื้นครีม ขอบน้ำตาล ไอคอนขนาด 24
-- เดิม TextScaled ไม่มีพื้น อีโมจิโตเต็มปุ่ม ดูใหญ่กว่าไอคอนอื่น (ผู้เล่นแจ้ง 2026-10-01)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 250, 230)
toggleButton.BackgroundTransparency = 0
toggleButton.Text = "🎵"
toggleButton.TextScaled = false
toggleButton.TextSize = 24
toggleButton.Font = Enum.Font.GothamBold
toggleButton.AutoButtonColor = true
toggleButton.Selectable = true
toggleButton.Name = "MusicButton"
toggleButton.LayoutOrder = 1
toggleButton.Parent = topbarRow
toggleButton.Visible = false -- ย้ายไปอยู่ในเมนูเพิ่มเติม (MoreMenuGui) 2026-10-02 เปิดแผงด้วย BindableEvent "OpenMusic" ด้านล่าง
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(140, 100, 65)
toggleStroke.Thickness = 2
toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
toggleStroke.Parent = toggleButton

-- แผงเพลงหลัก
local panel = Instance.new("Frame")
panel.Name = "MusicPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.62, 0)
panel.Size = UDim2.new(0, 430, 0, 220)
panel.BackgroundColor3 = COLOR_PANEL_BG
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.SelectionGroup = true -- จอย: การเลือกวนอยู่ในแผงเพลง
panel.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
panel.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingLeft = UDim.new(0, 20)
panelPadding.PaddingRight = UDim.new(0, 20)
panelPadding.PaddingTop = UDim.new(0, 14)
panelPadding.PaddingBottom = UDim.new(0, 14)
panelPadding.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, 20, 0, -10)
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundTransparency = 0.85
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.AutoButtonColor = false
closeButton.Selectable = true
closeButton.Parent = panel
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(1, 0)

local trackNameLabel = Instance.new("TextLabel")
trackNameLabel.Size = UDim2.new(1, 0, 0, 20)
trackNameLabel.Position = UDim2.new(0, 0, 0, 0)
trackNameLabel.BackgroundTransparency = 1
trackNameLabel.Text = Localization.T("Music_Loading", LANG)
trackNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
trackNameLabel.TextScaled = true
trackNameLabel.Font = Enum.Font.GothamBold
trackNameLabel.Parent = panel
local trackNameSizeConstraint = Instance.new("UITextSizeConstraint")
trackNameSizeConstraint.MaxTextSize = 16
trackNameSizeConstraint.Parent = trackNameLabel

-- แถวไทม์ไลน์ (เวลาปัจจุบัน - แถบ - เวลารวม)
local timelineRow = Instance.new("Frame")
timelineRow.Size = UDim2.new(1, 0, 0, 20)
timelineRow.Position = UDim2.new(0, 0, 0, 34)
timelineRow.BackgroundTransparency = 1
timelineRow.Parent = panel

local elapsedLabel = Instance.new("TextLabel")
elapsedLabel.Size = UDim2.new(0, 36, 1, 0)
elapsedLabel.Position = UDim2.new(0, 0, 0, 0)
elapsedLabel.BackgroundTransparency = 1
elapsedLabel.Text = "0:00"
elapsedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
elapsedLabel.TextScaled = true
elapsedLabel.Font = Enum.Font.Gotham
elapsedLabel.Parent = timelineRow

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(0, 36, 1, 0)
totalLabel.Position = UDim2.new(1, -36, 0, 0)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = "0:00"
totalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
totalLabel.TextScaled = true
totalLabel.Font = Enum.Font.Gotham
totalLabel.Parent = timelineRow

local progressTrack = Instance.new("Frame")
progressTrack.Size = UDim2.new(1, -88, 0, 6)
progressTrack.Position = UDim2.new(0, 44, 0.5, -3)
progressTrack.BackgroundColor3 = COLOR_TRACK_BG
progressTrack.BorderSizePixel = 0
progressTrack.Parent = timelineRow
Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = COLOR_FILL
progressFill.BorderSizePixel = 0
progressFill.Parent = progressTrack
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

local progressKnob = Instance.new("Frame")
progressKnob.AnchorPoint = Vector2.new(0.5, 0.5)
progressKnob.Position = UDim2.new(0, 0, 0.5, 0)
progressKnob.Size = UDim2.new(0, 12, 0, 12)
progressKnob.BackgroundColor3 = COLOR_FILL
progressKnob.BorderSizePixel = 0
progressKnob.Parent = progressTrack
Instance.new("UICorner", progressKnob).CornerRadius = UDim.new(1, 0)

-- แถวเสียง (ไอคอนปิดเสียง + สไลเดอร์ลากได้)
local volumeRow = Instance.new("Frame")
volumeRow.Size = UDim2.new(1, 0, 0, 24)
volumeRow.Position = UDim2.new(0, 0, 0, 66)
volumeRow.BackgroundTransparency = 1
volumeRow.Parent = panel

local volumeIconButton = Instance.new("TextButton")
volumeIconButton.Size = UDim2.new(0, 24, 0, 24)
volumeIconButton.Position = UDim2.new(0, 0, 0, 0)
volumeIconButton.BackgroundTransparency = 1
volumeIconButton.Text = "🔊"
volumeIconButton.TextScaled = true
volumeIconButton.AutoButtonColor = false
volumeIconButton.Selectable = true
volumeIconButton.Parent = volumeRow

local volumeTrack = Instance.new("Frame")
volumeTrack.Size = UDim2.new(1, -34, 0, 6)
volumeTrack.Position = UDim2.new(0, 34, 0.5, -3)
volumeTrack.BackgroundColor3 = COLOR_TRACK_BG
volumeTrack.BorderSizePixel = 0
volumeTrack.Parent = volumeRow
Instance.new("UICorner", volumeTrack).CornerRadius = UDim.new(1, 0)

local volumeFill = Instance.new("Frame")
volumeFill.Size = UDim2.new(initialMusicVolume, 0, 1, 0)
volumeFill.BackgroundColor3 = COLOR_FILL
volumeFill.BorderSizePixel = 0
volumeFill.Parent = volumeTrack
Instance.new("UICorner", volumeFill).CornerRadius = UDim.new(1, 0)

local volumeKnob = Instance.new("TextButton")
volumeKnob.AnchorPoint = Vector2.new(0.5, 0.5)
volumeKnob.Position = UDim2.new(initialMusicVolume, 0, 0.5, 0)
volumeKnob.Size = UDim2.new(0, 14, 0, 14)
volumeKnob.BackgroundColor3 = COLOR_FILL
volumeKnob.BorderSizePixel = 0
volumeKnob.Text = ""
volumeKnob.AutoButtonColor = false
volumeKnob.Selectable = true
volumeKnob.Parent = volumeTrack
Instance.new("UICorner", volumeKnob).CornerRadius = UDim.new(1, 0)

-- แถวเสียงเอฟเฟกต์รวม (✨ สไลเดอร์ควบคุม SoundGroup "EffectSounds" — รวมตกปลา ปลูกผัก ฝนตก ฯลฯ)
local effectSoundGroup = SoundService:FindFirstChild("EffectSounds")
if effectSoundGroup then effectSoundGroup.Volume = initialEffectVolume end

local effectLabel = Instance.new("TextLabel")
effectLabel.Size = UDim2.new(0, 100, 0, 20)
effectLabel.Position = UDim2.new(0, 0, 0, 96)
effectLabel.BackgroundTransparency = 1
effectLabel.Text = "✨ เสียงเอฟเฟกต์"
effectLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
effectLabel.TextScaled = true
effectLabel.Font = Enum.Font.GothamBold
effectLabel.TextXAlignment = Enum.TextXAlignment.Left
effectLabel.Parent = panel
local effectLabelConstraint = Instance.new("UITextSizeConstraint")
effectLabelConstraint.MaxTextSize = 12
effectLabelConstraint.Parent = effectLabel

local effectVolumeRow = Instance.new("Frame")
effectVolumeRow.Size = UDim2.new(1, 0, 0, 24)
effectVolumeRow.Position = UDim2.new(0, 0, 0, 116)
effectVolumeRow.BackgroundTransparency = 1
effectVolumeRow.Parent = panel

local effectVolumeIconButton = Instance.new("TextButton")
effectVolumeIconButton.Size = UDim2.new(0, 24, 0, 24)
effectVolumeIconButton.Position = UDim2.new(0, 0, 0, 0)
effectVolumeIconButton.BackgroundTransparency = 1
effectVolumeIconButton.Text = "🔊"
effectVolumeIconButton.TextScaled = true
effectVolumeIconButton.AutoButtonColor = false
effectVolumeIconButton.Selectable = true
effectVolumeIconButton.Parent = effectVolumeRow

local effectVolumeTrack = Instance.new("Frame")
effectVolumeTrack.Size = UDim2.new(1, -34, 0, 6)
effectVolumeTrack.Position = UDim2.new(0, 34, 0.5, -3)
effectVolumeTrack.BackgroundColor3 = COLOR_TRACK_BG
effectVolumeTrack.BorderSizePixel = 0
effectVolumeTrack.Parent = effectVolumeRow
Instance.new("UICorner", effectVolumeTrack).CornerRadius = UDim.new(1, 0)

local effectVolumeFill = Instance.new("Frame")
effectVolumeFill.Size = UDim2.new(initialEffectVolume, 0, 1, 0)
effectVolumeFill.BackgroundColor3 = COLOR_FILL
effectVolumeFill.BorderSizePixel = 0
effectVolumeFill.Parent = effectVolumeTrack
Instance.new("UICorner", effectVolumeFill).CornerRadius = UDim.new(1, 0)

local effectVolumeKnob = Instance.new("TextButton")
effectVolumeKnob.AnchorPoint = Vector2.new(0.5, 0.5)
effectVolumeKnob.Position = UDim2.new(initialEffectVolume, 0, 0.5, 0)
effectVolumeKnob.Size = UDim2.new(0, 14, 0, 14)
effectVolumeKnob.BackgroundColor3 = COLOR_FILL
effectVolumeKnob.BorderSizePixel = 0
effectVolumeKnob.Text = ""
effectVolumeKnob.AutoButtonColor = false
effectVolumeKnob.Selectable = true
effectVolumeKnob.Parent = effectVolumeTrack
Instance.new("UICorner", effectVolumeKnob).CornerRadius = UDim.new(1, 0)

local otherBoomboxButton = Instance.new("TextButton")
otherBoomboxButton.Name = "OtherBoomboxSoundToggle"
otherBoomboxButton.Size = UDim2.new(1, 0, 0, 26)
otherBoomboxButton.Position = UDim2.new(0, 0, 0, 148)
otherBoomboxButton.BackgroundColor3 = Color3.fromRGB(55, 65, 72)
otherBoomboxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
otherBoomboxButton.Font = Enum.Font.GothamBold
otherBoomboxButton.TextSize = 12
otherBoomboxButton.AutoButtonColor = true
otherBoomboxButton.Selectable = true
otherBoomboxButton.Parent = panel
Instance.new("UICorner", otherBoomboxButton).CornerRadius = UDim.new(0, 8)

local chooseBoomboxPlayersButton = Instance.new("TextButton")
chooseBoomboxPlayersButton.Name = "ChooseBoomboxPlayers"
chooseBoomboxPlayersButton.Size = UDim2.new(1, 0, 0, 26)
chooseBoomboxPlayersButton.Position = UDim2.new(0, 0, 0, 180)
chooseBoomboxPlayersButton.BackgroundColor3 = Color3.fromRGB(70, 80, 87)
chooseBoomboxPlayersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
chooseBoomboxPlayersButton.Font = Enum.Font.GothamBold
chooseBoomboxPlayersButton.TextSize = 12
chooseBoomboxPlayersButton.Text = LANG == "th" and "👥 ตั้งค่าเสียงแยกตามผู้เล่น" or "👥 Set sound per player"
chooseBoomboxPlayersButton.AutoButtonColor = true
chooseBoomboxPlayersButton.Selectable = true
chooseBoomboxPlayersButton.Parent = panel
Instance.new("UICorner", chooseBoomboxPlayersButton).CornerRadius = UDim.new(0, 8)

local playerMutePanel = Instance.new("Frame")
playerMutePanel.Name = "BoomboxPlayerMutePanel"
playerMutePanel.AnchorPoint = Vector2.new(0.5, 0.5)
playerMutePanel.Position = UDim2.new(0.5, 0, 0.62, 0)
playerMutePanel.Size = UDim2.new(0, 430, 0, 220)
playerMutePanel.BackgroundColor3 = COLOR_PANEL_BG
playerMutePanel.BackgroundTransparency = 0.1
playerMutePanel.Visible = false
playerMutePanel.Parent = screenGui
Instance.new("UICorner", playerMutePanel).CornerRadius = UDim.new(0, 14)
local playerMuteTitle = Instance.new("TextLabel")
playerMuteTitle.BackgroundTransparency = 1
playerMuteTitle.Position = UDim2.fromOffset(18, 8)
playerMuteTitle.Size = UDim2.new(1, -64, 0, 26)
playerMuteTitle.Font = Enum.Font.GothamBold
playerMuteTitle.TextSize = 15
playerMuteTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerMuteTitle.TextXAlignment = Enum.TextXAlignment.Left
playerMuteTitle.Text = LANG == "th" and "เสียง Music Box แยกตามผู้เล่น" or "Music Box by player"
playerMuteTitle.Parent = playerMutePanel
local playerMuteBack = Instance.new("TextButton")
playerMuteBack.Position = UDim2.new(1, -44, 0, 7)
playerMuteBack.Size = UDim2.fromOffset(28, 26)
playerMuteBack.Text = "‹"
playerMuteBack.TextSize = 22
playerMuteBack.Font = Enum.Font.GothamBold
playerMuteBack.TextColor3 = Color3.fromRGB(255, 255, 255)
playerMuteBack.BackgroundColor3 = Color3.fromRGB(70, 80, 87)
playerMuteBack.Parent = playerMutePanel
Instance.new("UICorner", playerMuteBack).CornerRadius = UDim.new(0, 7)
local playerMuteList = Instance.new("ScrollingFrame")
playerMuteList.Name = "Players"
playerMuteList.Position = UDim2.fromOffset(14, 42)
playerMuteList.Size = UDim2.new(1, -28, 1, -54)
playerMuteList.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
playerMuteList.BorderSizePixel = 0
playerMuteList.ScrollBarThickness = 5
playerMuteList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerMuteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerMuteList.ScrollingDirection = Enum.ScrollingDirection.Y
playerMuteList.Parent = playerMutePanel
Instance.new("UICorner", playerMuteList).CornerRadius = UDim.new(0, 8)
local playerMuteLayout = Instance.new("UIListLayout")
playerMuteLayout.Padding = UDim.new(0, 4)
playerMuteLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerMuteLayout.Parent = playerMuteList
local playerMutePadding = Instance.new("UIPadding")
playerMutePadding.PaddingTop = UDim.new(0, 5)
playerMutePadding.PaddingBottom = UDim.new(0, 5)
playerMutePadding.PaddingLeft = UDim.new(0, 5)
playerMutePadding.PaddingRight = UDim.new(0, 5)
playerMutePadding.Parent = playerMuteList

-- ============ ตรรกะ UI ============

local function updateVolumeIcon()
	if musicSound.Volume <= 0 then
		volumeIconButton.Text = "🔇"
	elseif musicSound.Volume < 0.4 then
		volumeIconButton.Text = "🔉"
	else
		volumeIconButton.Text = "🔊"
	end
end

local targetMusicVolume = initialMusicVolume

local function setVolume(newVolume)
	newVolume = math.clamp(newVolume, 0, 1)
	targetMusicVolume = newVolume
	musicSound.Volume = newVolume
	volumeFill.Size = UDim2.new(newVolume, 0, 1, 0)
	volumeKnob.Position = UDim2.new(newVolume, 0, 0.5, 0)
	updateVolumeIcon()
	if not applyingLoadedSettings and requestSaveAudioSettings then requestSaveAudioSettings() end
end

setVolume(DEFAULT_VOLUME)

-- ลากสไลเดอร์เสียง (กดค้างที่ปุ่มกลม หรือคลิกตรงไหนบนแถบก็ได้)
local draggingVolume = false

local function volumeFromPointerX(x)
	local trackPos = volumeTrack.AbsolutePosition.X
	local trackWidth = volumeTrack.AbsoluteSize.X
	if trackWidth <= 0 then return musicSound.Volume end
	return (x - trackPos) / trackWidth
end

local function beginVolumeDrag(input)
	draggingVolume = true
	setVolume(volumeFromPointerX(input.Position.X))
end

volumeKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginVolumeDrag(input)
	end
end)

volumeTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginVolumeDrag(input)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingVolume then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		setVolume(volumeFromPointerX(input.Position.X))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingVolume = false
		if requestSaveAudioSettings then requestSaveAudioSettings() end
	end
end)

-- ไอคอนปิดเสียงในแผงเพลง สลับ mute/unmute
local function toggleMute()
	if musicSound.Volume > 0 then
		volumeBeforeMute = musicSound.Volume
		setVolume(0)
	else
		setVolume(volumeBeforeMute > 0 and volumeBeforeMute or DEFAULT_VOLUME)
	end
end

volumeIconButton.Activated:Connect(toggleMute)

-- ============ เสียงเอฟเฟกต์รวม ============
local function updateEffectVolumeIcon()
	if not effectSoundGroup or effectSoundGroup.Volume <= 0 then
		effectVolumeIconButton.Text = "🔇"
	elseif effectSoundGroup.Volume < 0.4 then
		effectVolumeIconButton.Text = "🔉"
	else
		effectVolumeIconButton.Text = "🔊"
	end
end

local function setEffectVolume(newVolume)
	newVolume = math.clamp(newVolume, 0, 1)
	if effectSoundGroup then effectSoundGroup.Volume = newVolume end
	effectVolumeFill.Size = UDim2.new(newVolume, 0, 1, 0)
	effectVolumeKnob.Position = UDim2.new(newVolume, 0, 0.5, 0)
	updateEffectVolumeIcon()
	if not applyingLoadedSettings and requestSaveAudioSettings then requestSaveAudioSettings() end
end

local effectVolumeBeforeMute = initialEffectVolume > 0 and initialEffectVolume or EFFECT_DEFAULT_VOLUME
requestSaveAudioSettings = function()
	if not audioSettingsSave then return end
	audioSaveToken += 1
	local token = audioSaveToken
	task.delay(0.35, function()
		if token ~= audioSaveToken or not player.Parent then return end
			local mutedUsers = {}
			for userId, muted in pairs(mutedBoomboxUserIds) do
				if muted then mutedUsers[tostring(userId)] = true end
			end
			audioSettingsSave:FireServer(musicSound.Volume, effectSoundGroup and effectSoundGroup.Volume or initialEffectVolume, muteOtherBoomboxes, mutedUsers)
	end)
end

local function applyLoadedAudioSettings()
	if player:GetAttribute("AudioSettingsLoaded") ~= true then return end
	local savedMusic = readSavedVolume("SavedMusicVolume", DEFAULT_VOLUME)
	local savedEffects = readSavedVolume("SavedEffectVolume", EFFECT_DEFAULT_VOLUME)
	applyingLoadedSettings = true
	setVolume(savedMusic)
	setEffectVolume(savedEffects)
	local encodedMutedUsers = player:GetAttribute("MutedBoomboxUserIds")
	local decodedMutedUsers = {}
	if type(encodedMutedUsers) == "string" then
		local ok, result = pcall(function() return HttpService:JSONDecode(encodedMutedUsers) end)
		if ok and type(result) == "table" then
			for userId, muted in pairs(result) do
				local numericId = tonumber(userId)
				if numericId and numericId > 0 and numericId ~= player.UserId and muted == true then
					decodedMutedUsers[numericId] = true
				end
			end
		end
	end
	mutedBoomboxUserIds = decodedMutedUsers
	if setOtherBoomboxMuted then setOtherBoomboxMuted(player:GetAttribute("MuteOtherBoomboxes") == true) end
	if refreshOtherPlayersList then refreshOtherPlayersList() end
	volumeBeforeMute = savedMusic > 0 and savedMusic or DEFAULT_VOLUME
	effectVolumeBeforeMute = savedEffects > 0 and savedEffects or EFFECT_DEFAULT_VOLUME
	applyingLoadedSettings = false
end

if player:GetAttribute("AudioSettingsLoaded") == true then
	applyLoadedAudioSettings()
else
	local loadedConnection
	loadedConnection = player:GetAttributeChangedSignal("AudioSettingsLoaded"):Connect(function()
		if player:GetAttribute("AudioSettingsLoaded") == true then
			if loadedConnection then loadedConnection:Disconnect() end
			applyLoadedAudioSettings()
		end
	end)
end

local function toggleEffectMute()
	if effectSoundGroup and effectSoundGroup.Volume > 0 then
		effectVolumeBeforeMute = effectSoundGroup.Volume
		setEffectVolume(0)
	else
		setEffectVolume(effectVolumeBeforeMute > 0 and effectVolumeBeforeMute or EFFECT_DEFAULT_VOLUME)
	end
end

effectVolumeIconButton.Activated:Connect(toggleEffectMute)

refreshOtherPlayersList = function()
	for _, child in ipairs(playerMuteList:GetChildren()) do
		if child ~= playerMuteLayout and child ~= playerMutePadding then child:Destroy() end
	end
	local others = {}
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then table.insert(others, otherPlayer) end
	end
	table.sort(others, function(a, b)
		return string.lower(a.DisplayName) < string.lower(b.DisplayName)
	end)
	if #others == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "NoPlayers"
		empty.Size = UDim2.new(1, -8, 0, 34)
		empty.BackgroundTransparency = 1
		empty.TextColor3 = Color3.fromRGB(130, 100, 90)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 13
		empty.Text = LANG == "th" and "ยังไม่มีผู้เล่นอื่นในเซิร์ฟเวอร์" or "No other players in this server"
		empty.Parent = playerMuteList
		return
	end
	for index, otherPlayer in ipairs(others) do
		local userId = otherPlayer.UserId
		local row = Instance.new("Frame")
		row.Name = "Player_" .. tostring(userId)
		row.LayoutOrder = index
		row.Size = UDim2.new(1, -8, 0, 38)
		row.BackgroundColor3 = Color3.fromRGB(255, 250, 245)
		row.BorderSizePixel = 0
		row.Parent = playerMuteList
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)
		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.fromRGB(225, 200, 170)
		rowStroke.Thickness = 1.5
		rowStroke.Parent = row
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(8, 0)
		name.Size = UDim2.new(1, -112, 1, 0)
		name.Font = Enum.Font.Gotham
		name.TextSize = 12
		name.TextColor3 = Color3.fromRGB(80, 50, 40)
		name.Font = Enum.Font.GothamBold
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Text = otherPlayer.DisplayName .. "  @" .. otherPlayer.Name
		name.Parent = row
		local toggle = Instance.new("TextButton")
		toggle.Name = "MuteToggle"
		toggle.AnchorPoint = Vector2.new(1, 0.5)
		toggle.Position = UDim2.new(1, -5, 0.5, 0)
		toggle.Size = UDim2.fromOffset(98, 30)
		toggle.Font = Enum.Font.GothamBold
		toggle.TextSize = 11
		toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
		local isMuted = mutedBoomboxUserIds[userId] == true
		toggle.BackgroundColor3 = isMuted and Color3.fromRGB(240, 120, 110) or Color3.fromRGB(0, 176, 111)
		toggle.Text = isMuted
			and (LANG == "th" and "🔇 ปิดเสียง" or "🔇 Muted")
			or (LANG == "th" and "🔊 เปิดเสียง" or "🔊 Audible")
		toggle.Parent = row
		Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 7)
		toggle.Activated:Connect(function()
			setOtherPlayerBoomboxMuted(userId, not mutedBoomboxUserIds[userId])
			if not applyingLoadedSettings and requestSaveAudioSettings then requestSaveAudioSettings() end
		end)
	end
end

Players.PlayerAdded:Connect(function()
	task.defer(function() if refreshOtherPlayersList then refreshOtherPlayersList() end end)
end)
Players.PlayerRemoving:Connect(function()
	task.defer(function() if refreshOtherPlayersList then refreshOtherPlayersList() end end)
end)

refreshOtherBoomboxButton = function()
	if muteOtherBoomboxes then
		otherBoomboxButton.Text = LANG == "th" and "🔇 Music Box คนอื่น: ปิด" or "🔇 Others' Music Box: Off"
		otherBoomboxButton.BackgroundColor3 = Color3.fromRGB(240, 120, 110)
	else
		otherBoomboxButton.Text = LANG == "th" and "🔊 Music Box คนอื่น: เปิด" or "🔊 Others' Music Box: On"
		otherBoomboxButton.BackgroundColor3 = Color3.fromRGB(0, 176, 111)
	end
end

otherBoomboxButton.Activated:Connect(function()
	setOtherBoomboxMuted(not muteOtherBoomboxes)
	if not applyingLoadedSettings and requestSaveAudioSettings then requestSaveAudioSettings() end
end)
chooseBoomboxPlayersButton.Activated:Connect(function()
	panel.Visible = false
	playerMutePanel.Visible = true
	if refreshOtherPlayersList then refreshOtherPlayersList() end
end)
playerMuteBack.Activated:Connect(function()
	playerMutePanel.Visible = false
	panel.Visible = true
end)
refreshOtherBoomboxButton()
effectVolumeIconButton.NextSelectionDown = otherBoomboxButton
otherBoomboxButton.NextSelectionUp = effectVolumeIconButton
otherBoomboxButton.NextSelectionDown = chooseBoomboxPlayersButton
chooseBoomboxPlayersButton.NextSelectionUp = otherBoomboxButton
chooseBoomboxPlayersButton.NextSelectionDown = closeButton

-- ลากสไลเดอร์เสียงเอฟเฟกต์
local draggingEffectVolume = false
local function effectVolumeFromPointerX(x)
	local trackPos = effectVolumeTrack.AbsolutePosition.X
	local trackWidth = effectVolumeTrack.AbsoluteSize.X
	if trackWidth <= 0 then return effectSoundGroup and effectSoundGroup.Volume or 0 end
	return (x - trackPos) / trackWidth
end
local function beginEffectVolumeDrag(input)
	draggingEffectVolume = true
	setEffectVolume(effectVolumeFromPointerX(input.Position.X))
end
effectVolumeKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginEffectVolumeDrag(input)
	end
end)
effectVolumeTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginEffectVolumeDrag(input)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not draggingEffectVolume then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		setEffectVolume(effectVolumeFromPointerX(input.Position.X))
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingEffectVolume = false
		if requestSaveAudioSettings then requestSaveAudioSettings() end
	end
end)

-- เปิด/ปิดแผงเพลง
toggleButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)
local openMusicEvent = Instance.new("BindableEvent")
openMusicEvent.Name = "OpenMusic" -- MoreMenuGui เรียก: เปิด/ปิดแผงเพลงแทนปุ่ม 🎵 เดิม
openMusicEvent.Parent = screenGui
openMusicEvent.Event:Connect(function()
	panel.Visible = not panel.Visible
end)

-- อัปเดตไทม์ไลน์เรื่อยๆ ระหว่างเล่นเพลง
task.spawn(function()
	while true do
		task.wait(0.5)
		if musicSound.IsPlaying and musicSound.TimeLength > 0 then
			local ratio = math.clamp(musicSound.TimePosition / musicSound.TimeLength, 0, 1)
			progressFill.Size = UDim2.new(ratio, 0, 1, 0)
			progressKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
			elapsedLabel.Text = formatTime(musicSound.TimePosition)
			totalLabel.Text = formatTime(musicSound.TimeLength)
		end
	end
end)

-- ============ เล่นเพลง ============

local FIRST_TRACK_NAME = "First Day of Spring" -- เพลงที่จะเล่นเป็นเพลงแรกเสมอทุกครั้งที่เข้าเกม ที่เหลือสุ่มตามปกติ

local function playTrack(track)
	musicSound.SoundId = track.id
	musicSound.TimePosition = 0 -- เพลงเดิมซ้ำต่อกัน (ใส่ซ้ำในรายการ) ต้องเริ่มต้นเพลงใหม่
	musicSound:Play()
	trackNameLabel.Text = track.name or Localization.T("Music_UnknownTrack", LANG)
end

local transitionVersion = 0
local activeMusicTween
local function switchTrack(track)
	if not track or musicSound.SoundId == track.id then return end
	transitionVersion += 1
	local myVersion = transitionVersion
	if activeMusicTween then activeMusicTween:Cancel() end

	local fadeOut = TweenService:Create(musicFadeGroup, TweenInfo.new(1.2), { Volume = 0 })
	activeMusicTween = fadeOut
	fadeOut.Completed:Connect(function(playbackState)
		if myVersion ~= transitionVersion or playbackState ~= Enum.PlaybackState.Completed or not player.Parent then return end
		musicSound:Stop()
		playTrack(track)

		local fadeIn = TweenService:Create(musicFadeGroup, TweenInfo.new(1.5), { Volume = 1 })
		activeMusicTween = fadeIn
		fadeIn.Completed:Connect(function()
			if activeMusicTween == fadeIn then activeMusicTween = nil end
		end)
		fadeIn:Play()
	end)
	fadeOut:Play()
end

local function playNext()
	local nextTrack = pickNextTrack(musicSound.SoundId)
	if not nextTrack then
		trackNameLabel.Text = Localization.T("Music_NoTracks", LANG)
		return
	end
	playTrack(nextTrack)
end

musicSound.Ended:Connect(playNext)

-- เปลี่ยนเพลงเมื่อเวลาเกมหรือเวลาเฉพาะผู้เล่นข้ามช่วง พร้อมเฟดเสียงเข้า/ออก
local musicStarted = false -- ยังไม่เริ่มเพลงแรก = ไม่สลับเพลง (เพลงแรกเลือกจากช่วงเวลาตอนเริ่มจริง)
local currentPeriod = getTimePeriod(getMusicClockTime())
local function refreshMusicPeriod()
	if not musicStarted then return end
	local newPeriod = getTimePeriod(getMusicClockTime())
	if newPeriod == currentPeriod then return end
	currentPeriod = newPeriod
	task.spawn(switchTrack, pickNextTrack(musicSound.SoundId))
end
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshMusicPeriod)
player:GetAttributeChangedSignal("PersonalVisualClockTime"):Connect(refreshMusicPeriod)

-- เริ่มเกมด้วยเพลงประจำช่วงเวลา; กลางวันใช้ First Day of Spring เป็นเพลงแรกเหมือนเดิม
-- 2026-11-01 ผู้ใช้แจ้ง: เลือกค่ำไว้ แต่เพลงเช้าดังก่อน → รอ PersonalTimeGui ใช้ช่วงที่จำไว้เสร็จ (Attribute PersonalTimeReady) ก่อนเล่น รอสูงสุด FIRST_TRACK_WAIT วิ
local FIRST_TRACK_WAIT = 15
task.spawn(function()
	local deadline = os.clock() + FIRST_TRACK_WAIT
	while player.Parent and player:GetAttribute("PersonalTimeReady") ~= true and os.clock() < deadline do task.wait(0.2) end
	currentPeriod = getTimePeriod(getMusicClockTime())
	local firstTrack = nil
	if currentPeriod == "Day" then
		for _, track in ipairs(TIME_PLAYLISTS.Day) do
			if track.name == FIRST_TRACK_NAME then
				firstTrack = track
				break
			end
		end
	end
	musicStarted = true
	if firstTrack then
		playTrack(firstTrack)
	else
		playNext()
	end
end)
-- ============ จอย ============
-- เปิดแผงเพลงด้วยจอย (⬆️ เข้าแถวเมนูแล้วกด A ที่ 🎵) = เลือกปุ่มกลมบนแถบเสียง · ◀▶ ปรับเสียงทีละ 10% · ⬆️⬇️ ไปปุ่มปิดเสียง/ปิดแผง · B ปิด
local GuiService = game:GetService("GuiService")
volumeKnob.NextSelectionLeft = volumeKnob -- ◀▶ ใช้ปรับเสียง ไม่ย้ายการเลือก
volumeKnob.NextSelectionRight = volumeKnob
volumeKnob.NextSelectionUp = closeButton
volumeKnob.NextSelectionDown = effectVolumeKnob
effectVolumeKnob.NextSelectionLeft = effectVolumeKnob
effectVolumeKnob.NextSelectionRight = effectVolumeKnob
effectVolumeKnob.NextSelectionUp = volumeKnob
effectVolumeKnob.NextSelectionDown = effectVolumeIconButton
effectVolumeIconButton.NextSelectionRight = effectVolumeKnob
volumeIconButton.NextSelectionRight = volumeKnob
local function selectionInside()
	local sel = GuiService.SelectedObject
	return sel ~= nil and sel:IsDescendantOf(panel)
end
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		if UserInputService:GetLastInputType().Name:find("Gamepad") then
			task.defer(function() if panel.Visible then GuiService.SelectedObject = volumeKnob end end)
		end
	elseif selectionInside() then
		GuiService.SelectedObject = nil
	end
end)
UserInputService.InputBegan:Connect(function(input)
	if not panel.Visible then return end
	local key = input.KeyCode
	if GuiService.SelectedObject == volumeKnob and (key == Enum.KeyCode.DPadLeft or key == Enum.KeyCode.DPadRight) then
		local step = key == Enum.KeyCode.DPadRight and 0.1 or -0.1
		setVolume(math.floor((musicSound.Volume + step) * 10 + 0.5) / 10)
	elseif GuiService.SelectedObject == effectVolumeKnob and (key == Enum.KeyCode.DPadLeft or key == Enum.KeyCode.DPadRight) then
		local step = key == Enum.KeyCode.DPadRight and 0.1 or -0.1
		local cur = effectSoundGroup and effectSoundGroup.Volume or 0
		setEffectVolume(math.floor((cur + step) * 10 + 0.5) / 10)
	elseif key == Enum.KeyCode.ButtonB and selectionInside() then
		panel.Visible = false
	end
end)
local selectBox = Instance.new("Frame")
selectBox.BackgroundTransparency = 1
selectBox.Size = UDim2.new(1, 8, 1, 8)
selectBox.Position = UDim2.new(0, -4, 0, -4)
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = selectBox
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 190, 40); st.Thickness = 3; st.Parent = selectBox
end
for _, b in ipairs({ closeButton, volumeIconButton, volumeKnob, effectVolumeIconButton, effectVolumeKnob, otherBoomboxButton, chooseBoomboxPlayersButton, playerMuteBack }) do b.SelectionImageObject = selectBox end

-- ============ ธีมเกม + ความดัง Music Box (2026-10-08) ============
-- แผงเดิมเป็นแผงดำ ปรับเป็นครีม-ขอบน้ำตาลแบบหน้าต่างวาป/ร้านค้า แบ่งเป็นการ์ด มี % บอกทุกแถบ
-- เพิ่มการ์ด "🐧 เสียง Music Box": ความดัง Music Box ทุกเครื่อง (ของเราและคนอื่น) ที่ได้ยินบนเครื่องนี้เท่านั้น ใครก็ปรับได้ (ไม่ต้องมี Music Box)
--   ใช้ SoundGroup "BoomboxLocalSounds" + ค่าที่จำ SavedBoomboxVolume (RemoteEvent BoomboxSettingsSave) เดียวกับแถบในแผง Music Box (BoomboxBackClient) สองที่ตรงกันเสมอ
local function applyGameTheme()
	local COLOR_BG = Color3.fromRGB(255, 250, 245)
	local COLOR_CARD = Color3.fromRGB(255, 240, 225)
	local COLOR_CARD_LINE = Color3.fromRGB(230, 205, 175)
	local COLOR_TEXT = Color3.fromRGB(80, 50, 40)
	local COLOR_SUB = Color3.fromRGB(130, 100, 90)
	local COLOR_BORDER = Color3.fromRGB(140, 100, 65)
	local COLOR_TRACK = Color3.fromRGB(235, 218, 196)
	local COLOR_MUSIC = Color3.fromRGB(0, 176, 111)
	local COLOR_EFFECT = Color3.fromRGB(255, 160, 50)
	local COLOR_BOX = Color3.fromRGB(80, 170, 230)
	local COLOR_NATURE = Color3.fromRGB(120, 190, 80)
	local PANEL_W, PANEL_H = 430, 408 -- 2026-10-11 สูงขึ้น 60 รับการ์ดเสียงธรรมชาติ
	local function th(thai, english) return LANG == "th" and thai or english end

	local function stroke(obj, color, thickness)
		local s = obj:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
		s.Color = color
		s.Thickness = thickness
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = obj
		return s
	end
	local function label(parent, text, pos, size, textSize, color, bold, align)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = pos
		l.Size = size
		l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		l.TextSize = textSize
		l.TextColor3 = color
		l.TextXAlignment = align or Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = text
		l.Parent = parent
		return l
	end
	local function card(name, y, h)
		local c = Instance.new("Frame")
		c.Name = name
		c.Position = UDim2.new(0, 0, 0, y)
		c.Size = UDim2.new(1, 0, 0, h)
		c.BackgroundColor3 = COLOR_CARD
		c.BorderSizePixel = 0
		c.Parent = panel
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12)
		stroke(c, COLOR_CARD_LINE, 1.5)
		return c
	end
	local function styleSlider(track, fill, knob, color)
		track.BackgroundColor3 = COLOR_TRACK
		track.Size = UDim2.new(1, -34, 0, 8)
		track.Position = UDim2.new(0, 34, 0.5, -4)
		fill.BackgroundColor3 = color
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.Size = UDim2.new(0, 18, 0, 18)
		stroke(knob, color, 2.5)
	end
	local function sliderCard(name, y, title, row, fill)
		local c = card(name, y, 54)
		label(c, title, UDim2.new(0, 12, 0, 5), UDim2.new(1, -84, 0, 16), 13, COLOR_TEXT, true)
		local pct = label(c, "", UDim2.new(1, -64, 0, 5), UDim2.new(0, 52, 0, 16), 12, COLOR_SUB, true, Enum.TextXAlignment.Right)
		local function update() pct.Text = string.format("%d%%", math.floor(fill.Size.X.Scale * 100 + 0.5)) end
		fill:GetPropertyChangedSignal("Size"):Connect(update)
		update()
		row.Parent = c
		row.Position = UDim2.new(0, 10, 0, 24)
		row.Size = UDim2.new(1, -20, 0, 24)
		return c
	end

	-- ตัวแผง (แผงเพลง + แผงตั้งเสียงรายคน) ย่อตามจอเล็ก
	for _, p in ipairs({ panel, playerMutePanel }) do
		p.BackgroundColor3 = COLOR_BG
		p.BackgroundTransparency = 0
		p.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
		p.Position = UDim2.new(0.5, 0, 0.5, 18)
		stroke(p, COLOR_BORDER, 3)
		local corner = p:FindFirstChildOfClass("UICorner")
		if corner then corner.CornerRadius = UDim.new(0, 18) end
		local scale = Instance.new("UIScale")
		scale.Parent = p
		local function fit()
			local cam = workspace.CurrentCamera
			if not cam then return end
			local vp = cam.ViewportSize
			scale.Scale = math.clamp(math.min((vp.Y - 70) / PANEL_H, (vp.X - 20) / PANEL_W), 0.5, 1)
		end
		fit()
		if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	end

	label(panel, th("🎵 เพลงและเสียง", "🎵 Music & Sound"), UDim2.new(0, 2, 0, -2), UDim2.new(1, -44, 0, 26), 19, COLOR_TEXT, true)
	closeButton.BackgroundColor3 = Color3.fromRGB(240, 120, 110)
	closeButton.BackgroundTransparency = 0
	closeButton.Text = "X" -- ✕ ไม่มีในฟอนต์ Gotham (ขึ้นเป็นกล่อง)
	closeButton.TextScaled = false
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, 6, 0, -6)

	-- การ์ดเพลงที่กำลังเล่น
	local nowCard = card("NowPlaying", 30, 62)
	trackNameLabel.Parent = nowCard
	trackNameLabel.Position = UDim2.new(0, 12, 0, 8)
	trackNameLabel.Size = UDim2.new(1, -24, 0, 20)
	trackNameLabel.TextColor3 = COLOR_TEXT
	trackNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	timelineRow.Parent = nowCard
	timelineRow.Position = UDim2.new(0, 12, 0, 34)
	timelineRow.Size = UDim2.new(1, -24, 0, 20)
	elapsedLabel.TextColor3 = COLOR_SUB
	totalLabel.TextColor3 = COLOR_SUB
	progressTrack.BackgroundColor3 = COLOR_TRACK
	progressFill.BackgroundColor3 = COLOR_MUSIC
	progressKnob.BackgroundColor3 = COLOR_MUSIC

	-- เพลงพื้นหลัง / เสียงเอฟเฟกต์
	sliderCard("MusicCard", 100, th("🎵 เพลงพื้นหลัง", "🎵 Background music"), volumeRow, volumeFill)
	styleSlider(volumeTrack, volumeFill, volumeKnob, COLOR_MUSIC)
	effectLabel.Visible = false
	sliderCard("EffectCard", 160, th("✨ เสียงเอฟเฟกต์", "✨ Sound effects"), effectVolumeRow, effectVolumeFill)
	styleSlider(effectVolumeTrack, effectVolumeFill, effectVolumeKnob, COLOR_EFFECT)

	-- เสียง Music Box (ใหม่)
	local boxRow = Instance.new("Frame")
	boxRow.Name = "BoomboxVolumeRow"
	boxRow.BackgroundTransparency = 1
	local boxIcon = Instance.new("TextButton")
	boxIcon.Name = "BoomboxMuteIcon"
	boxIcon.Size = UDim2.new(0, 24, 0, 24)
	boxIcon.BackgroundTransparency = 1
	boxIcon.Text = "🔊"
	boxIcon.TextScaled = true
	boxIcon.AutoButtonColor = false
	boxIcon.Selectable = true
	boxIcon.Parent = boxRow
	local boxTrack = Instance.new("Frame")
	boxTrack.BorderSizePixel = 0
	boxTrack.Active = true
	boxTrack.Parent = boxRow
	Instance.new("UICorner", boxTrack).CornerRadius = UDim.new(1, 0)
	local boxFill = Instance.new("Frame")
	boxFill.BorderSizePixel = 0
	boxFill.Parent = boxTrack
	Instance.new("UICorner", boxFill).CornerRadius = UDim.new(1, 0)
	local boxKnob = Instance.new("TextButton")
	boxKnob.Name = "BoomboxVolumeKnob"
	boxKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	boxKnob.Text = ""
	boxKnob.AutoButtonColor = false
	boxKnob.Selectable = true
	boxKnob.Parent = boxTrack
	Instance.new("UICorner", boxKnob).CornerRadius = UDim.new(1, 0)
	styleSlider(boxTrack, boxFill, boxKnob, COLOR_BOX)
	sliderCard("BoomboxCard", 280, th("🐧 เสียง Music Box", "🐧 Music Box volume"), boxRow, boxFill)

	local boxGroup = SoundService:FindFirstChild("BoomboxLocalSounds") -- BoomboxBackClient สร้างและใส่เสียง Music Box ทุกเครื่องเข้ากลุ่มนี้
	local boxSave = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("BoomboxSettingsSave")
	local boxVolume = readSavedVolume("SavedBoomboxVolume", 1)
	local boxBeforeMute = boxVolume > 0 and boxVolume or 1
	local boxDragging = false
	local boxSaveToken = 0
	local function setBoxVolume(v, save)
		v = math.clamp(v, 0, 1)
		boxVolume = v
		if boxGroup then boxGroup.Volume = v end
		boxFill.Size = UDim2.new(v, 0, 1, 0)
		boxKnob.Position = UDim2.new(v, 0, 0.5, 0)
		boxIcon.Text = v <= 0 and "🔇" or (v < 0.4 and "🔉" or "🔊")
		if save and boxSave then
			boxSaveToken += 1
			local token = boxSaveToken
			task.delay(0.6, function()
				if token == boxSaveToken and player.Parent then boxSave:FireServer(boxVolume) end
			end)
		end
	end
	setBoxVolume(boxVolume, false)
	if not boxGroup then
		task.spawn(function()
			boxGroup = SoundService:WaitForChild("BoomboxLocalSounds", 30)
			if boxGroup then boxGroup.Volume = boxVolume end
		end)
	end
	player:GetAttributeChangedSignal("SavedBoomboxVolume"):Connect(function()
		if boxDragging then return end
		setBoxVolume(readSavedVolume("SavedBoomboxVolume", boxVolume), false)
	end)
	local function boxFromX(x)
		local w = boxTrack.AbsoluteSize.X
		if w <= 0 then return boxVolume end
		return (x - boxTrack.AbsolutePosition.X) / w
	end
	for _, target in ipairs({ boxKnob, boxTrack }) do
		target.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				boxDragging = true
				setBoxVolume(boxFromX(input.Position.X), true)
			end
		end)
	end
	UserInputService.InputChanged:Connect(function(input)
		if boxDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setBoxVolume(boxFromX(input.Position.X), true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if boxDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			boxDragging = false
			setBoxVolume(boxVolume, true)
		end
	end)
	boxIcon.Activated:Connect(function()
		if boxVolume > 0 then
			boxBeforeMute = boxVolume
			setBoxVolume(0, true)
		else
			setBoxVolume(boxBeforeMute > 0 and boxBeforeMute or 1, true)
		end
	end)

	-- เสียงธรรมชาติ (2026-10-11): นกร้อง/แมลงกลางคืน (AmbientSounds) น้ำบ่อบัว/ลำธาร/น้ำตก ฝนและฟ้าร้อง (WeatherClient)
	--   SoundGroup "NatureSounds" + ค่าที่จำ SavedNatureVolume (RemoteEvent NatureSettingsSave ใน AudioPrefs) แยกจากเสียงเอฟเฟกต์
	--   คนที่ยังไม่เคยตั้ง เซิร์ฟเวอร์ส่งค่าเสียงเอฟเฟกต์มาเป็นค่าเริ่มต้น
	local natureRow = Instance.new("Frame")
	natureRow.Name = "NatureVolumeRow"
	natureRow.BackgroundTransparency = 1
	local natureIcon = Instance.new("TextButton")
	natureIcon.Name = "NatureMuteIcon"
	natureIcon.Size = UDim2.new(0, 24, 0, 24)
	natureIcon.BackgroundTransparency = 1
	natureIcon.Text = "🔊"
	natureIcon.TextScaled = true
	natureIcon.AutoButtonColor = false
	natureIcon.Selectable = true
	natureIcon.Parent = natureRow
	local natureTrack = Instance.new("Frame")
	natureTrack.BorderSizePixel = 0
	natureTrack.Active = true
	natureTrack.Parent = natureRow
	Instance.new("UICorner", natureTrack).CornerRadius = UDim.new(1, 0)
	local natureFill = Instance.new("Frame")
	natureFill.BorderSizePixel = 0
	natureFill.Parent = natureTrack
	Instance.new("UICorner", natureFill).CornerRadius = UDim.new(1, 0)
	local natureKnob = Instance.new("TextButton")
	natureKnob.Name = "NatureVolumeKnob"
	natureKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	natureKnob.Text = ""
	natureKnob.AutoButtonColor = false
	natureKnob.Selectable = true
	natureKnob.Parent = natureTrack
	Instance.new("UICorner", natureKnob).CornerRadius = UDim.new(1, 0)
	styleSlider(natureTrack, natureFill, natureKnob, COLOR_NATURE)
	sliderCard("NatureCard", 220, th("🌿 เสียงธรรมชาติ", "🌿 Nature sounds"), natureRow, natureFill)

	local natureGroup = SoundService:FindFirstChild("NatureSounds")
	local natureSave = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("NatureSettingsSave", 10)
	local natureVolume = readSavedVolume("SavedNatureVolume", initialEffectVolume)
	local natureBeforeMute = natureVolume > 0 and natureVolume or EFFECT_DEFAULT_VOLUME
	local natureDragging = false
	local natureSaveToken = 0
	local function setNatureVolume(v, save)
		v = math.clamp(v, 0, 1)
		natureVolume = v
		if natureGroup then natureGroup.Volume = v end
		natureFill.Size = UDim2.new(v, 0, 1, 0)
		natureKnob.Position = UDim2.new(v, 0, 0.5, 0)
		natureIcon.Text = v <= 0 and "🔇" or (v < 0.4 and "🔉" or "🔊")
		if save and natureSave then
			natureSaveToken += 1
			local token = natureSaveToken
			task.delay(0.6, function()
				if token == natureSaveToken and player.Parent then natureSave:FireServer(natureVolume) end
			end)
		end
	end
	setNatureVolume(natureVolume, false)
	player:GetAttributeChangedSignal("SavedNatureVolume"):Connect(function()
		if natureDragging then return end
		setNatureVolume(readSavedVolume("SavedNatureVolume", natureVolume), false)
	end)
	local function natureFromX(x)
		local w = natureTrack.AbsoluteSize.X
		if w <= 0 then return natureVolume end
		return (x - natureTrack.AbsolutePosition.X) / w
	end
	for _, target in ipairs({ natureKnob, natureTrack }) do
		target.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				natureDragging = true
				setNatureVolume(natureFromX(input.Position.X), true)
			end
		end)
	end
	UserInputService.InputChanged:Connect(function(input)
		if natureDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setNatureVolume(natureFromX(input.Position.X), true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if natureDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			natureDragging = false
			setNatureVolume(natureVolume, true)
		end
	end)
	natureIcon.Activated:Connect(function()
		if natureVolume > 0 then
			natureBeforeMute = natureVolume
			setNatureVolume(0, true)
		else
			setNatureVolume(natureBeforeMute > 0 and natureBeforeMute or EFFECT_DEFAULT_VOLUME, true)
		end
	end)

	-- ปุ่มล่าง: ตั้งเสียงรายคน (ซ้าย) + ยืนยัน (ขวา กดแล้วปิดหน้าต่าง) ปุ่ม Music Box คนอื่นเอาออก (2026-10-08)
	otherBoomboxButton:Destroy()
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Position = UDim2.new(0.5, 4, 0, 342)
	confirmButton.Size = UDim2.new(0.5, -4, 0, 36)
	confirmButton.BackgroundColor3 = COLOR_MUSIC
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextSize = 14
	confirmButton.Text = th("ยืนยัน", "Confirm")
	confirmButton.AutoButtonColor = true
	confirmButton.Selectable = true
	confirmButton.SelectionImageObject = selectBox
	confirmButton.Parent = panel
	Instance.new("UICorner", confirmButton).CornerRadius = UDim.new(0, 12)
	confirmButton.Activated:Connect(function()
		if requestSaveAudioSettings then requestSaveAudioSettings() end
		panel.Visible = false
	end)
	chooseBoomboxPlayersButton.Position = UDim2.new(0, 0, 0, 342)
	chooseBoomboxPlayersButton.Size = UDim2.new(0.5, -4, 0, 36)
	chooseBoomboxPlayersButton.TextWrapped = true
	chooseBoomboxPlayersButton.TextSize = 12
	chooseBoomboxPlayersButton.Text = th("👥 ตั้งเสียงรายคน", "👥 Per player")
	chooseBoomboxPlayersButton.BackgroundColor3 = COLOR_CARD
	chooseBoomboxPlayersButton.TextColor3 = COLOR_TEXT
	stroke(chooseBoomboxPlayersButton, COLOR_CARD_LINE, 1.5)
	local cc = chooseBoomboxPlayersButton:FindFirstChildOfClass("UICorner") if cc then cc.CornerRadius = UDim.new(0, 12) end
	refreshOtherBoomboxButton()

	-- แผงตั้งเสียงรายคน
	playerMuteTitle.TextColor3 = COLOR_TEXT
	playerMuteTitle.TextSize = 17
	playerMuteBack.BackgroundColor3 = COLOR_CARD
	playerMuteBack.TextColor3 = COLOR_TEXT
	stroke(playerMuteBack, COLOR_CARD_LINE, 1.5)
	playerMuteList.BackgroundColor3 = COLOR_CARD
	playerMuteList.ScrollBarImageColor3 = COLOR_BORDER

	-- จอย: แถบ Music Box ต่อจากเสียงเอฟเฟกต์ ◀▶ ปรับทีละ 10%
	boxKnob.NextSelectionLeft = boxKnob
	boxKnob.NextSelectionRight = boxKnob
	boxKnob.NextSelectionUp = effectVolumeKnob
	boxKnob.NextSelectionDown = confirmButton
	boxIcon.NextSelectionRight = boxKnob
	boxIcon.NextSelectionUp = effectVolumeIconButton
	boxIcon.NextSelectionDown = chooseBoomboxPlayersButton
	effectVolumeKnob.NextSelectionDown = boxKnob
	effectVolumeIconButton.NextSelectionDown = boxIcon
	chooseBoomboxPlayersButton.NextSelectionRight = confirmButton
	chooseBoomboxPlayersButton.NextSelectionUp = boxIcon
	chooseBoomboxPlayersButton.NextSelectionDown = chooseBoomboxPlayersButton
	confirmButton.NextSelectionLeft = chooseBoomboxPlayersButton
	confirmButton.NextSelectionUp = boxKnob
	confirmButton.NextSelectionDown = confirmButton
	confirmButton.NextSelectionRight = confirmButton
	boxIcon.SelectionImageObject = selectBox
	boxKnob.SelectionImageObject = selectBox
	UserInputService.InputBegan:Connect(function(input)
		if not panel.Visible or GuiService.SelectedObject ~= boxKnob then return end
		if input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.DPadRight then
			local step = input.KeyCode == Enum.KeyCode.DPadRight and 0.1 or -0.1
			setBoxVolume(math.floor((boxVolume + step) * 10 + 0.5) / 10, true)
		end
	end)

	-- จอย: แถบเสียงธรรมชาติอยู่ระหว่างเสียงเอฟเฟกต์กับ Music Box ◀▶ ปรับทีละ 10%
	natureKnob.NextSelectionLeft = natureKnob
	natureKnob.NextSelectionRight = natureKnob
	natureKnob.NextSelectionUp = effectVolumeKnob
	natureKnob.NextSelectionDown = boxKnob
	natureIcon.NextSelectionRight = natureKnob
	natureIcon.NextSelectionUp = effectVolumeIconButton
	natureIcon.NextSelectionDown = boxIcon
	effectVolumeKnob.NextSelectionDown = natureKnob
	effectVolumeIconButton.NextSelectionDown = natureIcon
	boxKnob.NextSelectionUp = natureKnob
	boxIcon.NextSelectionUp = natureIcon
	natureIcon.SelectionImageObject = selectBox
	natureKnob.SelectionImageObject = selectBox
	UserInputService.InputBegan:Connect(function(input)
		if not panel.Visible or GuiService.SelectedObject ~= natureKnob then return end
		if input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.DPadRight then
			local step = input.KeyCode == Enum.KeyCode.DPadRight and 0.1 or -0.1
			setNatureVolume(math.floor((natureVolume + step) * 10 + 0.5) / 10, true)
		end
	end)
end
applyGameTheme()
