-- Backup 2026-11-22 before "gamepad X rides / gets off a mount"
-- Studio path: game.StarterPlayer.StarterPlayerScripts.MountClient
-- Restore: put these 3 pieces back over the new versions.

-------- (1) input handler (~line 104) --------
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end -- พิมพ์แชทอยู่
	if input.KeyCode == Enum.KeyCode.H then
		send("toggle")
	end
end)

-------- (2) footer in render() (~line 410) --------
	footer.Text = UserInputService.KeyboardEnabled and tr("⌨️ กด H เพื่อขึ้น/ลงตัวที่ขี่ล่าสุด", "⌨️ Press H to ride / get off your last mount") or ""

-------- (3) renderSummon (~line 849) --------
local function renderSummon()
	local riding = player:GetAttribute("RidingMount") ~= nil
	local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	summonCaption.Text = touch and (riding and tr("ลง", "Off") or tr("ขี่", "Ride"))
		or (riding and tr("ลง H", "Off (H)") or tr("ขี่ H", "Ride (H)"))
	summonButton.BackgroundColor3 = riding and Color3.fromRGB(255, 205, 150) or Color3.fromRGB(255, 248, 230)
end
