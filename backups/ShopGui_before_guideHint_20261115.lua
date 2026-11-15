-- Backup (sections only — the rest of the script was not touched)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.ShopGui (LocalScript)
-- Change (2026-11-15): add names/attributes so NewPlayerGuide can highlight the Buy/Sell tab and the right button in the seed shop.
-- Restore: put these lines back where the new ones are. Added lines are marked "GuideHint" in the live script — remove them all.

-- (1) line ~166
local mainFrame = Instance.new("Frame")

-- (2) line ~282 / ~297 / ~327 (no .Name lines before)
local buyTabButton = Instance.new("TextButton")
local sellTabButton = Instance.new("TextButton")
local scrollFrame = Instance.new("ScrollingFrame")

-- (3) renderBuyTab, end of the item loop
		firstSelectable = firstSelectable or actionButton
	end

-- (4) renderSellTab, end of the item loop
		firstSelectable = firstSelectable or actionButton
	end

-- (5) setActiveTab start
local function setActiveTab(tab, keepPosition)
	activeTab = tab

-- (6) requestShopOpen handler start
requestShopOpen.OnClientEvent:Connect(function(buyItems, sellItems, coinAmount, shopKind)
	titleLabel.Text = Localization.T(shopKind == "orchard" and "OrchardShop_Title" or "Shop_Title", LANG)
