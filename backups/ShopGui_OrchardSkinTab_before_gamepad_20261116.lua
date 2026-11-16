-- Backup 2026-11-16 before "orchard shop gamepad support"
-- (A) game.StarterPlayer.StarterPlayerScripts.ShopGui — pieces that changed (restore by putting these back over the new versions):
-------- (A1) skin tab button (new version adds makeGamepadSelectable(skinTabButton) after Parent) --------
local skinTabButton = sellTabButton:Clone()
skinTabButton.Name = "SkinTab"
skinTabButton.Text = Localization.Pick(LANG, "🎀 แต่งแปลง", "🎀 Plot Skins")
skinTabButton.Visible = false
skinTabButton.Parent = tabBar
-------- (A2) gamepad B handler (new version: B closes the skin popup first, L1/R1 switch tabs) --------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not mainFrame.Visible then return end
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonB then
		closeShop()
	end
end)

-- (B) game.ReplicatedStorage.OrchardSkinTab — pieces that changed (restore by putting these back over the new versions;
--     also delete the new helpers focusStroke / isGamepad / SkinTab.ClosePopup and the returnTo variable):
-------- (B1) closePopup --------
local function closePopup()
	if popup then popup:Destroy(); popup = nil end
end
-------- (B2) end of openConfirm --------
	local cancel = button(T("ยกเลิก", "Cancel"), Color3.fromRGB(190, 175, 160), 0.27)
	local buy = button(T("ซื้อเลย", "Buy"), Color3.fromRGB(120, 190, 110), 0.73)
	cancel.Activated:Connect(closePopup)
	buy.Activated:Connect(function()
		closePopup()
		send("buySkin", def)
	end)

	for _, d in ipairs(dim:GetDescendants()) do
		if d:IsA("GuiObject") then d.ZIndex = Z + 1 + (d:IsA("TextButton") and 1 or 0) end
	end
	GuiService.SelectedObject = buy
	gui:GetPropertyChangedSignal("Enabled"):Connect(function() if not gui.Enabled then closePopup() end end)
end
-------- (B3) makeCard action button --------
	local bl = Instance.new("UITextSizeConstraint"); bl.MaxTextSize = 17; bl.Parent = btn
	btn.Activated:Connect(function() onCardButton(def, btn) end)
