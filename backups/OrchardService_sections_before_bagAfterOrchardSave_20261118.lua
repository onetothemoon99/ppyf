-- SECTION BACKUP of ServerScriptService.Orchard.OrchardService (Studio), 2026-11-18, before "bagAfterOrchardSave".
-- Script length before the change: 230186 chars. Only the 3 sections below were changed.
-- Restore: in Studio open ServerScriptService.Orchard.OrchardService and put each section back as it is here
--   (1) replace the saveBag function + the new saveBagAfterFruitSaved block with section 1,
--   (2) in actions.harvest replace the "if not isFake(player) ... saveBag(player)" block with section 2,
--   (3) in steal() replace the "if not isFake(owner) ... saveBag(thief)" block with section 3.

-- ===== Section 1 (was lines 128-130) =====
local function saveBag(player)
	if saveInventoryNow then saveInventoryNow:Fire(player) end
end

-- ===== Section 2 (actions.harvest, was lines 948-953) =====
	if not isFake(player) then
		OrchardData.MarkUnsavedFruit(player, player)
		OrchardData.SaveLater(player)
	end
	if got > 0 then OrchardItems.Give(player, OrchardItems.FRUIT, kind, got, lang(player)) end
	saveBag(player)

-- ===== Section 3 (steal(), was lines 2684-2689) =====
	if not isFake(owner) then
		OrchardData.SaveLater(owner)
		OrchardData.MarkUnsavedFruit(thief, owner) -- 2026-11-18 (instantHarvest): ผลที่ขโมยขายไม่ได้จนกว่าสวนเจ้าของเซฟสำเร็จ
	end
	OrchardItems.Give(thief, OrchardItems.FRUIT, kind, 1, lang(thief))
	saveBag(thief)
