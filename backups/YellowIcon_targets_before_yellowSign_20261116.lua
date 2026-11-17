-- Backup 2026-11-16 before yellowSign (shop sign / keeper name / shop title use the yellow mango picture)
-- New ModuleScript ReplicatedStorage.YellowIcon is added (delete it to undo).
-- The other changes are one-line inserts; restore = delete the line marked "YellowIcon" in each script:
--   game.StarterPlayer.StarterPlayerScripts.OrchardKeeperFx  (after: makeLabel(nameGui, Localization.T("OrchardKeeper_Name", LANG), 34))
--   game.StarterPlayer.StarterPlayerScripts.ShopGui          (after: titleLabel.Parent = titleBar   at line ~222)
--   game.StarterPlayer.StarterPlayerScripts.OrchardGui       (block "ป้ายร้านผลไม้: มะม่วงเหลือง" after the yellow prompt block)
-- Original lines (unchanged by this edit):
makeLabel(nameGui, Localization.T("OrchardKeeper_Name", LANG), 34)
titleLabel.Parent = titleBar
-- The sign text in workspace.Orchard.Decor.FruitShop.SignBoard (both SurfaceGuis) is NOT edited in the place;
-- the client strips the emoji at runtime only.
