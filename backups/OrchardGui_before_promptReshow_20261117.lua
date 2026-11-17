-- Backup 2026-11-17 before promptReshow (partial: 3 small sections inside the "ปุ่ม E หน้าตาเอง" block)
-- Studio path: game.StarterPlayer.StarterPlayerScripts.OrchardGui (LocalScript)
-- Restore: replace the matching sections with the text below (and delete "local onScreen" + "local function reshow").

	local watched = {} -- [prompt] = true
	local function check(p)
		local want = iconOf(p.ObjectText) ~= nil or iconOf(p.ActionText) ~= nil
		local style = want and CUSTOM or DEFAULT
		if p.Style ~= style then p.Style = style end
	end

	PPS.PromptShown:Connect(function(p, inputType)
		if p.Style ~= CUSTOM or not watched[p] then return end

	PPS.PromptHidden:Connect(function(p)
		if shown[p] then shown[p]() end
	end)
