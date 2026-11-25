-- BACKUP of ServerScriptService.LoginAnnouncementService before Thai/English remaining screens (i18n final pass, 2026-11-25)
-- Restore: paste everything below this header into ServerScriptService.LoginAnnouncementService.Source in Studio
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage:WaitForChild("LoginAnnouncementConfig"))
local store = DataStoreService:GetDataStore("LoginAnnouncementDismissals_v1")
local DataLoadRetry = require(ServerScriptService:WaitForChild("DataLoadRetry"))
local remote = ReplicatedStorage:FindFirstChild("LoginAnnouncementRequest")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "LoginAnnouncementRequest"
	remote.Parent = ReplicatedStorage
end

local cache = {}
local busy = {}
local function todayKey()
	return math.floor((os.time() + 7 * 60 * 60) / 86400)
end

local function readRecord(player)
	if cache[player] then return cache[player], true end
	DataLoadRetry.WaitReadBudget(player) -- รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if ok then
		cache[player] = type(data) == "table" and data or {}
		return cache[player], true
	end
	warn("LoginAnnouncement: โหลดการข้ามประกาศไม่สำเร็จ " .. player.Name .. ": " .. tostring(data))
	return {}, false
end

remote.OnServerInvoke = function(player, action)
	if action == "get" then
		if not Config.Enabled then return { show = false } end
		local record, loaded = readRecord(player)
		local day = todayKey()
		if loaded and record.skipDay == day and record.announcementId == Config.Id then
			return { show = false }
		end
		return {
			show = true,
			id = Config.Id,
			titleTH = Config.TitleTH,
			titleEN = Config.TitleEN,
			detailsTH = Config.DetailsTH,
			detailsEN = Config.DetailsEN,
		}
	elseif action == "skipToday" then
		if busy[player] then return { ok = false, message = "กำลังบันทึก ลองอีกครั้ง" } end
		busy[player] = true
		local day = todayKey()
		local ok, data = pcall(function()
			return store:UpdateAsync(tostring(player.UserId), function(old)
				old = type(old) == "table" and old or {}
				old.skipDay = day
				old.announcementId = Config.Id
				old.updatedAt = os.time()
				return old
			end, { player.UserId })
		end)
		busy[player] = nil
		if not ok or type(data) ~= "table" then
			warn("LoginAnnouncement: บันทึกการข้ามประกาศไม่สำเร็จ " .. player.Name .. ": " .. tostring(data))
			return { ok = false, message = "บันทึกไม่สำเร็จ กรุณาลองอีกครั้ง" }
		end
		cache[player] = data
		return { ok = true }
	end
	return { ok = false }
end

Players.PlayerRemoving:Connect(function(player)
	cache[player] = nil
	busy[player] = nil
end)
