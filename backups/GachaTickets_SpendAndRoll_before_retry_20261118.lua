-- Section backup (2026-11-18) before change "retry" (safe retry on DataStore InternalServerError).
-- Studio path: game.ServerScriptService.GachaTickets -> function GachaTickets.SpendAndRoll
-- To restore: paste this function over the new SpendAndRoll in Studio (the rest of the script is unchanged).
-- This already includes the earlier 2026-11-18 "rollErrorMsg" change (6th return value = error text).

function GachaTickets.SpendAndRoll(player, typeId, amount, rollFn)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 or not isType(typeId) then return false, nil, 0 end
	local spent, counts, allPity, results, before, after = false, nil, nil, nil, nil, nil
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			local data = normalize(old)
			counts, allPity = data.counts, data.pity
			if data.counts[typeId] < amount then
				spent = false
				return nil
			end
			before = copyPity(data.pity[typeId])
			local working = copyPity(before)
			results = rollFn(working)
			data.pity[typeId] = working
			after = working
			data.counts[typeId] -= amount
			spent = true
			return data
		end)
	end)
	if not ok then
		warn("GachaTickets: หักตั๋ว/สุ่ม " .. player.Name .. " ไม่สำเร็จ: " .. tostring(err))
		-- ตัวที่ 6 = ข้อความ error (2026-11-18): ผู้เรียกแยกได้ว่า "เซฟ/สุ่มพัง" ไม่ใช่ "ตั๋วไม่พอ" (เดิมขึ้น "ตั๋วไม่พอ (มี 40 ใบ)" ทั้งที่มีตั๋ว)
		return false, nil, GachaTickets.Get(player, typeId), nil, nil, tostring(err)
	end
	if counts then publish(player, counts, allPity) end
	if not spent then return false, nil, counts and counts[typeId] or 0 end
	return true, results, counts[typeId], before, copyPity(after)
end
