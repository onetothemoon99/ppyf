# ❄️ เสือดาวหิมะ — แผนสัตว์เลี้ยงระดับลับ (2026-11-27)

สถานะ: โมเดล Blender รอบ 4 **ผู้ใช้ผ่านแล้ว** (2026-11-27) อัปโหลดแล้ว · template สร้างแล้วใน Studio (ยังไม่ได้ Publish) · ภาพต้นแบบ `art/snow_leopard_pet/ref_concept.png`

## ตัวนี้คืออะไร
- ชื่อ: เสือดาวหิมะ (PetId `SnowLeopard`) · ระดับ **ลับ** · โชค x30
- ความสามารถ: **ช่วยปลูก** (Planter แบบเดียวกับแมวเก้าชีวิต/ผึ้งราชินี)
- ได้จาก: ตู้สุ่มสัตว์เลี้ยง · อีเวนต์เปิดตัว **1–15 ธ.ค. 2026** แล้วอยู่ในตู้**ถาวร** (`AlwaysInGacha` แบบจิงโจ้) (ผู้ใช้ตอบ 2026-11-27)
- ความสามารถเสริม: แปลงที่มันปลูก **พืชโตเร็วขึ้นอีก 10%** (ผู้ใช้ตอบ 2026-11-27)
- ของเข้าชุด: ยังไม่มี

## หน้าตา (ตามภาพ)
- ตัวขาวเทา ลายวงจุด ตาโต แก้มชมพู หางยาวฟูมีลาย
- ผ้ากันเปื้อนเอี๊ยมสีน้ำตาล มีพลั่วจิ๋วในกระเป๋า
- ตะกร้าผัก (แครอท/ผักใบ) สะพายข้าง + ตะเกียงม่วงห้อย
- มือขวาถือบัวรดน้ำทองแดง · **มือซ้ายหงายชูผลผลิตที่กำลังปลูก** (เปลี่ยนตามพืช, ผู้ใช้สั่ง 2026-11-27)
- ⚠️ ต้องต่างจาก **เสือพยัคฆ์ขาว** ให้ชัด: ตัวเล็กกว่า ลายเป็นจุดวงไม่ใช่ลายทาง หางฟูใหญ่

## เอฟเฟกต์
- เกล็ดหิมะ + ดาวสีพาสเทลลอยวนรอบตัว (เบา ๆ ไม่ใช้ Highlight เพราะชนเพดาน 255)
- ตอนปลูก: เทบัวรดน้ำแล้วมีละอองม่วงกับโน้ตดนตรีลอยขึ้น
- รอยเท้าน้ำแข็งเรืองแสงบนแปลงที่ปลูก (หายไปเองใน 3 วิ) = สัญลักษณ์ว่าแปลงนี้โตเร็วขึ้น 10%
- ตอนพัก: นอนขดเอาหางพันตัว

## ขั้นตอนทำ
1. โมเดล: ทำใน Blender (ค่าเริ่มต้นที่เลือก ผู้ใช้ยังไม่ได้ตอบ) (ตัว / หัว / แขน / ขา / หาง / ตะกร้า / บัวรดน้ำ แยกชิ้น) → GLB → อัปโหลด
   - อีกทาง: generate_mesh ใน Studio แบบจิงโจ้ (เร็วกว่า แต่คุมหน้าตาได้น้อยกว่า)
   - อัปโหลดแล้ว 2026-11-27 (กลุ่ม 642396060, ผ่าน moderation ทุกชิ้น, จาก `art/snow_leopard_pet/v4/`):
     Body 114339424451757 · Head 108025062940591 · ArmL 93313155569403 · ArmR 85693059430113 · LegL 117625903417276 · LegR 70382392329095 · Tail 108921892546896
2. ริก Motor6D + วางไว้ที่ `ServerStorage.PetTemplates.SnowLeopard` หันหน้า -Z
   - ✅ ทำแล้ว 2026-11-27 (Studio เท่านั้น): 50 MeshPart สีจาก COLORS, ScaleTo 1.2 (สูง ~2.9), หันหน้า -Z (`FacingOffset` = identity แบบจิงโจ้)
   - ชิ้นหลัก Torso/Head/LeftArm/RightArm/LeftLeg/RightLeg/Tail + HRP + Humanoid · Motor6D: RootJoint, Neck, Left/Right Shoulder, Left/Right Hip, Tail · ชิ้นอื่น WeldConstraint ติดชิ้นหลัก (Massless)
   - Attachment: `HoldL` (LeftArm, วางผลผลิต), `CanSpout` (RightArm, ปากบัวรดน้ำ), `LanternAttachment`, `AuraAttachment` (Torso)
   - gotcha: importer หมุนทุกชิ้น 180° รอบ Y → หมุนกลับในที่ ตรวจด้วย raycast (ปากบัว/หาง) เพราะ screen_capture ได้ภาพขาวล้วน
3. `PetDefinitions.SnowLeopard`: ระดับลับ, Planter, Luck 30, เริ่มด้วย `NotInGacha` + `HiddenUnlessOwned`
   - ✅ ทำแล้ว 2026-11-27 (Studio เท่านั้น): ซ่อนไว้ชั่วคราว (NotInGacha + HiddenUnlessOwned), ชื่ออังกฤษ "Snow Leopard", ค่า `PlantGrowBoost = 0.1`
   - ✅ โตเร็ว 10% ต่อแล้ว 2026-11-27: Planter ส่ง `plantCrop(crop, player, {growBoost})` → `slot.petGrowBoost` → growPlant คูณเวลาทุกช่วง x0.9 (ไม่ขึ้นกับว่าสัตว์ยังอยู่ไหม) · Planter ตั้ง Attribute `PlantedFx` = "พืช;x,y,z;เวลา" บนตัวสัตว์ ไว้ให้ SnowLeopardFx วาดผลผลิตบนมือ/รอยเท้า
   - ความสามารถเสริม: ใส่เครื่องหมายไว้บนแปลงที่มันปลูก ให้พืชโตเร็วขึ้น x1.1 (ต้องหาจุดคำนวณเวลาโตในระบบปลูก)
4. สคริปต์เอฟเฟกต์ `SnowLeopardFx` (หิมะ, ละอองตอนรดน้ำ, รอยเท้า)
   - ✅ ทำแล้ว 2026-11-27 (Studio เท่านั้น ยังไม่ได้ทดสอบ Play):
     - ผลผลิตบนมือ: ฝั่งเซิร์ฟเวอร์ `Abilities.Planter` holdCrop (def `HoldCrop = "HoldL"`) โคลน `CropTemplates.<พืช>.HeldFruit` ด้านยาวสุด 0.5 x สเกล วางบนฝ่ามือ เชื่อม WeldConstraint · ทดสอบใน Edit: แตงโม/สตรอว์เบอร์รี/ข้าวสาลี/ข้าวโพด ก้นผลอยู่บนฝ่ามือพอดี
     - template: emitter `SnowAura`/`StarAura` (AuraAttachment), `WaterSpray`/`MagicMotes`/`Notes` (CanSpout), PointLight `LanternLight` ม่วง, Attribute `SnowLeopardFx`
     - `StarterPlayerScripts.SnowLeopardFx`: เปิดหิมะ/ดาวเมื่ออยู่ใกล้กล้อง (ปิดเมื่อ FxOff/ซ่อนสัตว์), ตอน `PlantedFx` เปลี่ยน = ปล่อยละออง + รอยเท้าน้ำแข็ง 2 รอย 3 วิ
     - texture: เกล็ดหิมะ 119401271727601, รอยเท้า 84809451380488 (`art/snow_leopard_pet/make_fx_textures.py`), โน้ตใช้ของเบ็ดกบ 133885060410368
   - ของในมือซ้าย: ตอนปลูก โคลนโมเดลผลผลิตของพืชนั้น (`CropTemplates.<พืช>` ชิ้น HeldFruit) วางที่จุด `HoldL` บนฝ่ามือ · ยังไม่เคยปลูก = มือว่าง · ปลูกแล้วถือพืชล่าสุดไว้
5. `/give <ชื่อ> snowleopard` ใน AdminGive สำหรับทดสอบ ✅ ทำแล้ว 2026-11-27 (ไม่ประกาศทุกเซิร์ฟ `NoAnnounce`)
6. อีเวนต์ `SnowLeopard_2026_12` (1–15 ธ.ค.) ใน `GachaConfig.Events` + สวิตช์ `SeasonConfig` (ปิดไว้ก่อน) · หลัง 15 ธ.ค. ใส่ `AlwaysInGacha = true`
   - ⚠️ ตัวลับที่อยู่ตู้ถาวรแบ่งเรตลับกัน: หลัง 15 ธ.ค. จิงโจ้กับเสือดาวหิมะได้ตัวละ 0.1% / 0.25%
6b. **ตัวหน้าตู้ได้ง่ายกว่า** (ผู้ใช้เลือก 2026-11-27: แบบ B + การันตีหน้าตู้)
   - อีเวนต์ใส่ `Featured = "SnowLeopard"` · GachaService: ได้ระดับลับ → ตัวหน้าตู้ 75% / ตัวลับอื่นแบ่ง 25%
   - ช่วง 1–15 ธ.ค.: เสือ 0.15% / 0.375% · จิงโจ้ 0.05% / 0.125% (ธรรมดา / พรีเมียม) · ลับรวมเท่าเดิม 0.2% / 0.5%
   - การันตีลับ (200 / 100 ครั้ง) → ได้ตัวหน้าตู้แน่นอน
   - หน้าต่างเรตต้องโชว์ % ต่อตัวตามจริง (กฎ Roblox) · อัปเดตตาราง `PET_GACHA.md`
   - หลัง 15 ธ.ค. ไม่มีตัวหน้าตู้ → กลับไปเท่ากัน 50/50
   - ✅ ทำแล้ว 2026-11-27 (Studio): `SeasonConfig.SnowLeopardGacha2026` (Enabled = false, 1–15 ธ.ค.), `GachaConfig.Events` SnowLeopard_2026_12 (`Featured`, `FeaturedShare = 0.75`), `GachaService` buildState shares + pickInTier + การันตีลับ = ตัวหน้าตู้, `GachaGui` โชว์ % ต่อตัว + ⭐, `PetDefinitions.SnowLeopard` เปลี่ยนจากซ่อนเป็น `Season` + `AlwaysInGacha`
   - จำลองด้วยโค้ดจริง: 1–15 ธ.ค. เสือ 75% / จิงโจ้ 25% ของลับ, การันตีได้เสือทุกครั้ง · หลัง 15 ธ.ค. 50/50
   - ⚠️ ตอนนี้ (สวิตช์ปิด) เสือดาวหิมะไม่มีในเกมเลย รวม /give → ทดสอบใน Studio: Attribute `DevForceSeason` บน ReplicatedStorage ใส่ `SnowLeopardGacha2026`
   - ✅ 2026-11-27 ผู้ใช้สั่ง "เปิดแค่ใน dev ก่อน": `PetDefinitions.SnowLeopard.DevOnly = true` → เกมจริง: ไม่มีใครเห็น ไม่อยู่ในตู้ แต่แอดมิน `/give` ตัวเองได้ (แล้วเห็นเพราะมีแล้ว) · Studio: `DevForceSeason` มี `SnowLeopardGacha2026` แล้ว = ทำงานครบ (ตู้/ตัวหน้าตู้) · ปล่อยจริง = ลบบรรทัด DevOnly + เปิด `SnowLeopardGacha2026.Enabled`
   - ทดสอบอีเวนต์ใน Studio ก่อน 1 ธ.ค.: ต้องใส่ `DevDisableSeason` = `PlatypusGacha2026` ด้วย (อีเวนต์ตุ่นยังเปิดถึง 30 พ.ย. และมาก่อนในลิสต์)
7. ทดสอบใน Studio (ดูด้วยภาพเท่านั้น ห้ามกดจริงในโหมด Play) → เปิดสวิตช์ → Publish

## คำถามรอผู้ใช้ตอบ
- ทำโมเดลทางไหน: Blender (ค่าเริ่มต้น) หรือ generate_mesh?
