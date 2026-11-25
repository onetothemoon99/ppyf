-- BACKUP of ServerScriptService.CommunityReward before Thai/English gift messages (i18n phase 2, 2026-11-23)
-- Restore: paste everything below this header into ServerScriptService.CommunityReward.Source in Studio
-- CommunityReward: ปุ่ม "เข้าร่วมชุมชน" (กลุ่ม Roblox เจ้าของเกม) เข้ากลุ่มแล้วได้ตั๋วพรีเมียม 5 ใบ บัญชีละครั้ง (2026-10-15 ผู้ใช้ขอ)
-- หน้าจอ (StarterPlayerScripts.CommunityRewardGui) เปิดหน้าเข้ากลุ่มของ Roblox (GroupService:PromptJoinAsync) แล้วขอรับรางวัลผ่าน RemoteFunction RemoteEvents.CommunityReward ("claim")
-- เซิร์ฟเวอร์เช็กเองว่าเป็นสมาชิกจริง (ไม่เชื่อฝั่งผู้เล่น): IsInGroupAsync → GroupService:GetGroupsAsync (ไม่ใช้ IsInGroup เพราะจำค่าตอนเข้าเกม เพิ่งเข้ากลุ่มจะยังได้ false)
-- รับได้ครั้งเดียว: DataStore "CommunityReward_v1" key = UserId { token, t, tickets } จองก่อน (UpdateAsync) แล้วค่อยให้ตั๋ว ให้ตั๋วไม่สำเร็จ = คืนสิทธิ์ (กดรับใหม่ได้)
--   ใน Studio key ขึ้นต้น "studio_" (ทดสอบไม่กินสิทธิ์เกมจริง) · ออกจากกลุ่มแล้วเข้าใหม่ = ไม่ได้ซ้ำ
--   Attribute "CommunityRewardClaimed" บนผู้เล่น = รับแล้ว (หน้าจอซ่อนปุ่ม)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GachaTickets = require(ServerScriptService:WaitForChild("GachaTickets"))

local GROUP_ID = 642396060 -- กลุ่ม "Chilling At Farm" เจ้าของเกม (game.CreatorId)
local TICKET_TYPE = "Premium"
local TICKET_AMOUNT = 5

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local remote = remoteEvents:FindFirstChild("CommunityReward")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "CommunityReward"
	remote.Parent = remoteEvents
end
remote:SetAttribute("GroupId", GROUP_ID)
remote:SetAttribute("Tickets", TICKET_AMOUNT)

local store = DataStoreService:GetDataStore("CommunityReward_v1")
local busy = {}
local lastTry = {}

local function keyOf(player)
	return (RunService:IsStudio() and "studio_" or "") .. tostring(player.UserId)
end

-- เป็นสมาชิกกลุ่มไหม (อ่านสด) คืน true / false / nil = เช็กไม่ได้
local function isMember(player)
	local ok, res = pcall(function() return player:IsInGroupAsync(GROUP_ID) end)
	if ok and type(res) == "boolean" then return res end
	local ok2, groups = pcall(function() return GroupService:GetGroupsAsync(player.UserId) end)
	if ok2 and type(groups) == "table" then
		for _, g in ipairs(groups) do
			if g.Id == GROUP_ID then return true end
		end
		return false
	end
	return nil
end

local function claim(player)
	if player:GetAttribute("CommunityRewardClaimed") == true then
		return { ok = false, claimed = true, message = "รับรางวัลเข้าร่วมชุมชนไปแล้ว ขอบคุณที่เป็นส่วนหนึ่งของเรา 💖" }
	end
	local member = isMember(player)
	if member == nil then return { ok = false, message = "ตรวจสอบการเข้ากลุ่มไม่สำเร็จ ลองใหม่อีกครั้ง" } end
	if not member then return { ok = false, message = "ยังไม่ได้เข้ากลุ่ม กด \"เข้าร่วม\" ในหน้าต่างของ Roblox ก่อนนะ" } end

	-- จองสิทธิ์ก่อน (หลายเซิร์ฟพร้อมกันก็ได้ครั้งเดียว)
	local token = game:GetService("HttpService"):GenerateGUID(false)
	local okClaim, record = pcall(function()
		return store:UpdateAsync(keyOf(player), function(old)
			if type(old) == "table" and old.token then return nil end
			return { token = token, t = os.time(), tickets = TICKET_AMOUNT }
		end, { player.UserId })
	end)
	if not okClaim then return { ok = false, message = "ระบบบันทึกไม่ตอบสนอง ลองใหม่อีกครั้ง" } end
	if type(record) ~= "table" or record.token ~= token then
		player:SetAttribute("CommunityRewardClaimed", true)
		return { ok = false, claimed = true, message = "บัญชีนี้รับรางวัลเข้าร่วมชุมชนไปแล้ว" }
	end

	local after = GachaTickets.Add(player, TICKET_TYPE, TICKET_AMOUNT, "community_" .. token)
	if not after then
		-- ให้ตั๋วไม่สำเร็จ: คืนสิทธิ์ กดรับใหม่ได้
		pcall(function()
			store:UpdateAsync(keyOf(player), function(old)
				if type(old) == "table" and old.token == token then return { released = os.time() } end
				return nil
			end)
		end)
		return { ok = false, message = "ส่งตั๋วไม่สำเร็จ ลองกดรับใหม่อีกครั้ง" }
	end
	player:SetAttribute("CommunityRewardClaimed", true)
	print("👥 CommunityReward: " .. player.Name .. " เข้ากลุ่ม ได้ตั๋วพรีเมียม " .. TICKET_AMOUNT .. " ใบ (ตอนนี้ " .. tostring(after) .. ")")
	return { ok = true, claimed = true, message = "🎉 ขอบคุณที่เข้าร่วมชุมชน! ได้รับตั๋วพรีเมียม " .. TICKET_AMOUNT .. " ใบ 💎 ใช้ได้ที่ตู้สุ่มสัตว์เลี้ยง" }
end

remote.OnServerInvoke = function(player, action)
	if action ~= "claim" then return { ok = false, message = "คำขอไม่ถูกต้อง" } end
	if busy[player] then return { ok = false, message = "กำลังตรวจสอบ รอสักครู่" } end
	local now = os.clock()
	if now - (lastTry[player] or 0) < 3 then return { ok = false, message = "รอสักครู่แล้วลองใหม่" } end
	lastTry[player] = now
	busy[player] = true
	local ok, res = pcall(claim, player)
	busy[player] = nil
	if not ok then
		warn("CommunityReward: " .. tostring(res))
		return { ok = false, message = "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง" }
	end
	return res
end

-- เข้าเกม: บอกหน้าจอว่ารับไปแล้วหรือยัง (อ่านไม่ได้ = ไม่ตั้ง ปุ่มยังขึ้น กดแล้วเซิร์ฟเช็กซ้ำอยู่ดี)
local DataLoadRetry = require(game:GetService("ServerScriptService"):WaitForChild("DataLoadRetry"))
local function checkClaimed(player)
	-- ไม่เร่งด่วน: หลีกทางให้ของสำคัญโหลดก่อน + รอโควต้าอ่าน กัน StandardReadGameServerThrottled (2026-10-20)
	if not DataLoadRetry.Defer(player, "CommunityReward") then return end
	DataLoadRetry.WaitReadBudget(player)
	local ok, record = pcall(function() return store:GetAsync(keyOf(player)) end)
	if ok and player.Parent then
		player:SetAttribute("CommunityRewardClaimed", type(record) == "table" and record.token ~= nil)
	end
end
Players.PlayerAdded:Connect(function(player) task.spawn(checkClaimed, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(checkClaimed, player) end
Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
	lastTry[player] = nil
end)
