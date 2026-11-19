-- Patch 2026-11-19 (user approved the plan, "ตามแผนเลย"): krathong pray pose = sit folded to the side (พับเพียบ)
--   and hold the krathong in both palms at chest/chin level with the head bowed a little (user's reference photo).
-- Target: StarterPlayerScripts.KrathongClient (Studio). NOT applied yet — written while Studio MCP could not connect.
-- Before applying: read the LIVE Source, save it to backups/KrathongClient_before_seatedPray_20261119.lua,
--   and check that the 3 blocks below still match the live code (the live script may be newer than
--   patches/KrathongClient_poseLive_20261116.lua).
-- All angles are first guesses; tune them in Play from front + side screenshots.

---------------------------------------------------------------------------
-- (1) REPLACE the block from "local KNEEL_DROP = 0.9" down to the closing "}" of local POSES
---------------------------------------------------------------------------
-- ท่าลอยกระทง (2026-11-19 ผู้ใช้ส่งรูปอ้างอิง): นั่งพับเพียบ ขาพับไปทางขวาของตัว ลำตัวตรง ก้มหน้านิดๆ
--   ประคองกระทงสองมือระดับอก/คาง (เดิม 2026-11-07: คุกเข่า + ยกกระทงจรดหน้าผาก)
local KNEEL_DROP = 1.6 -- ลดสะโพกลงตอนนั่งพับเพียบ (สตั๊ด) · คุกเข่าเดิม 0.9 · จูนจากภาพด้านข้าง: ก้นแตะพื้น ขาไม่จม
local SIDE_YAW = 35 -- องศาที่ขาพับไปทางขวาของตัว (บวก = ขวา ถ้าออกมาผิดข้างให้กลับเครื่องหมาย)
local function rx(d) return CFrame.Angles(math.rad(d), 0, 0) end
local function ry(d) return CFrame.Angles(0, math.rad(d), 0) end
local function rz(d) return CFrame.Angles(0, 0, math.rad(d)) end
-- ขาพับเพียบ: ต้นขายื่นไปข้างหน้าและเบนไปทางขวา เข่างอมากให้แข้งพับกลับ · สะโพกหมุนตามขา เอวบิดกลับให้อกหันหน้าตรง
local SIT_LEGS = {
	RightUpperLeg = ry(-SIDE_YAW) * rx(80), LeftUpperLeg = ry(-SIDE_YAW) * rx(80),
	RightLowerLeg = rx(-145), LeftLowerLeg = rx(-145),
}
local function seated(spec, torsoPitch)
	spec.LowerTorso = CFrame.new(0, -KNEEL_DROP, 0) * ry(SIDE_YAW * 0.4)
	spec.UpperTorso = ry(-SIDE_YAW * 0.4) * rx(torsoPitch or 0)
	for k, v in pairs(SIT_LEGS) do spec[k] = v end
	return spec
end
local POSES = {
	-- นั่งพับเพียบ ถือกระทงต่ำระดับท้อง/อก
	hold = seated({
		RightUpperArm = rx(40) * rz(10), LeftUpperArm = rx(40) * rz(-10),
		RightLowerArm = rx(60), LeftLowerArm = rx(60) }, 0),
	-- นั่งพับเพียบ ประคองกระทงสองมือระดับอก/คาง ก้มหน้านิดๆ (อธิษฐาน)
	wish = seated({
		RightUpperArm = rx(65) * rz(6), LeftUpperArm = rx(65) * rz(-6),
		RightLowerArm = rx(75), LeftLowerArm = rx(75),
		Head = rx(-15) }, -6),
	-- นั่งพับเพียบ โน้มตัวไปข้างหน้า ยื่นแขนวางกระทงลงน้ำ
	place = seated({
		RightUpperArm = rx(80) * rz(8), LeftUpperArm = rx(80) * rz(-8),
		RightLowerArm = rx(10), LeftLowerArm = rx(10),
		Head = rx(-10) }, -35),
}

---------------------------------------------------------------------------
-- (2) In local POSE_JOINT add the neck (joint lives in the Head part):
---------------------------------------------------------------------------
--	Head = "Neck",

---------------------------------------------------------------------------
-- (3) In the RunService.Stepped pray branch REPLACE the two position lines:
---------------------------------------------------------------------------
--   old:	local chest = (flat * CFrame.new(0, -1.15, -1.05)).Position
--   old:	local brow = (flat * CFrame.new(0, 0.35, -1.0)).Position -- จรดหน้าผาก
--   new:
			local chest = (flat * CFrame.new(0, -1.35, -1.0)).Position -- ถือต่ำระดับท้อง/อก (ตอนนั่งลง)
			local brow = (flat * CFrame.new(0, -0.8, -0.95)).Position -- ประคองระดับอก/คาง (เดิมจรดหน้าผาก 0.35) ชื่อตัวแปรคงเดิม
-- Everything else (timings KNEEL_T / WISH_T / PLACE, stand-up, lantern/hang poses) stays the same.
