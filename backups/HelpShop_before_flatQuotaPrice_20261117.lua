-- Backup 2026-11-17 before flatQuotaPrice (partial: 3 lines)
-- Restore:
-- ===== game.ReplicatedStorage.OrchardConfig (HelpShop.Items, ~line 157) =====
		{ Id = "PlantQuota", Tab = "items", Icon = "🌱", NameTh = "แปลงปลูกผัก +5 (ถาวร)", NameEn = "Crop slots +5 (permanent)", Prices = { 40, 60, 80, 100, 120 }, Grant = "quota" },
-- ===== game.ServerScriptService.Orchard.OrchardService shopPrice (~line 1588) =====
local function shopPrice(it, shop)
	if it.Prices then return it.Prices[(shop.quota or 0) + 1] end -- nil = ซื้อครบทุกขั้นแล้ว
	return it.Price
end
-- ===== OrchardService shop info (~line 1683) =====
			SoldOut = (price == nil) or nil, Step = it.Prices and (shop.quota or 0) or nil, Steps = it.Prices and #it.Prices or nil,
