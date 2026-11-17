-- Backup 2026-11-16 before confirmText (partial: only the changed lines; script is ~33k chars)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.PetFoodGui (LocalScript)
-- Restore: put these 4 askConfirm(...) lines back (line ~394, ~403, ~411, ~420) and delete the
-- "local function plainName" helper added right after "local function starText".

				askConfirm(string.format(tr("ใส่ 🐟 %s %s จำนวน %d ตัว\nได้อาหาร %d ถุง", "Put in 🐟 %s %s × %d\nMakes %d bags of food"), s.Name, starText(s.Star), amount, amount * s.BagsPer),
				askConfirm(string.format(tr("ใส่ 🐟 %s %s ทั้งหมด %d ตัว\nได้อาหาร %d ถุง", "Put in all 🐟 %s %s (%d)\nMakes %d bags of food"), s.Name, starText(s.Star), maxFish, maxFish * s.BagsPer),
			askConfirm(string.format(tr("ใส่ %s %s %s %d ชิ้น\nได้อาหาร %d ถุง", "Put in %s %s %s × %d\nMakes %d bags of food"), CROP_ICON[s.CropType] or "🌱", s.Name, starText(s.Star), amount * info.PerBag, amount),
			askConfirm(string.format(tr("ใส่ %s %s %s ทั้งหมด %d ชิ้น\nได้อาหาร %d ถุง", "Put in all %s %s %s (%d)\nMakes %d bags of food"), CROP_ICON[s.CropType] or "🌱", s.Name, starText(s.Star), maxBags * info.PerBag, maxBags),
