-- Backup (changed sections only) of game.ServerScriptService.Orchard.UncleManao before "chibi model like ป้าแตงไทย", 2026-11-17
-- The old uncle was an R15 copy of ServerStorage.OrchardTemplates.FakeGuard (lime torso) that walked to the thief and swung its arm.
-- Restore: put these 3 sections back in place of the new spawnUncle / say / uncleSlap, delete StarterPlayerScripts.UncleManaoFx,
--   and in OrchardGui put "UncleManao" back into the guard-name list next to "OrchardFakeGuard" (slap arm swing).

-- [1] spawnUncle
local uncle
local home = ground(SPOT.uncle) + Vector3.new(0, 3, 0)
local function spawnUncle()
	local template = templates:FindFirstChild("FakeGuard")
	if not template then return end
	local g = template:Clone()
	g.Name = "UncleManao"
	g.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local hum = g:FindFirstChildOfClass("Humanoid")
	hum.DisplayName = "👨‍🌾 ลุงมะนาว"
	hum.WalkSpeed = 24
	hum.NameDisplayDistance = 80
	local colors = g:FindFirstChildOfClass("BodyColors")
	if colors then colors.TorsoColor3 = Color3.fromRGB(150, 200, 60) end
	for _, n in ipairs({ "UpperTorso", "LowerTorso" }) do
		local part = g:FindFirstChild(n)
		if part then part.Color = Color3.fromRGB(150, 200, 60) end
	end
	g:PivotTo(CFrame.lookAt(home, Vector3.new(SPOT.uncleLook.X, home.Y, SPOT.uncleLook.Z)))
	g.Parent = workspace
	local root = g:FindFirstChild("HumanoidRootPart")
	if root then pcall(function() root:SetNetworkOwner(nil) end) end
	hum.Died:Connect(function()
		task.wait(3)
		if uncle == g then g:Destroy() spawnUncle() end
	end)
	uncle = g
end
spawnUncle()

-- [2] say(text): BillboardGui "UncleSay" on uncle.Head (StudsOffset 0, 4.2, 0), same as now otherwise.

-- [3] uncleSlap(player): walked with hum:MoveTo up to SLAP_CHASE s until within SLAP_REACH, faced the thief,
--     set g:SetAttribute("SlapAt", server time), waited 0.18 s, then: clear OrchardPickAt, UnequipTools,
--     OrchardAlert "stun" { seconds = Steal.StunSeconds, from = root.Position }, 👋💥 billboard 2 s, toast; waited 1.5 s; hum:MoveTo(home).
