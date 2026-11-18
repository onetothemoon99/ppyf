# หุ่น EXP (ซื้อด้วยเหรียญ) — แผนงาน

สถานะ: **ทำใน Studio แล้ว · เปิดเฉพาะ dev (`LuckConfig.XP_BOOSTER_DEV_ONLY = true` เซิร์ฟจริงไม่มีหุ่น EXP) · ยังไม่ Publish** (2026-11-19) — รายละเอียดใน CHANGELOG · ระดับ Robux (หุ่น EXP ทอง) ทำทีหลัง

## กติกา
- ปักแล้วเกิดวงรัศมี 15 อยู่ 5 นาที ปักได้ทีละ 1 ตัวต่อคน (นับแยกจากหุ่นโชค ปักคู่กันได้)
- **นับตามตัวคนที่ยืนในวง** ตอนได้ XP (ไม่ใช่ตามต้นผัก) → ใช้กับตกปลาได้
- เจ้าของหุ่น **x1.5** (+50%) · คนอื่นในวง **x1.25** (+25% = ได้เพิ่มครึ่งหนึ่งของเจ้าของ, ผู้ใช้ยืนยัน 2026-11-19) · อยู่หลายวง = เอาค่าสูงสุดค่าเดียว (ไม่บวกกัน)
- ราคา **40,000 เหรียญ** (ผู้ใช้สั่ง 2026-11-19)
- โมเดล: หุ่นเสื้อแดงชูป้าย "x1.5" (`ServerStorage.BoosterTemplates.XpScarecrowTemplate`, asset 71052820069959, สคริปต์ `art/xp_scarecrow/build_xp_scarecrow.py`)
- ไม่มีผลกับโชค ดาว หรือผลผลิต
- ปักได้ทุกที่ภายใน 20 studs จากตัว (ระบบเดิมไม่ล็อกว่าต้องเป็นแปลง) → ปักที่ท่าเรือได้

## XP ที่ได้โบนัส / ไม่ได้
| ได้ ✅ (ทำซ้ำได้) | ไม่ได้ ❌ (ครั้งเดียว / ก้อนใหญ่) |
|---|---|
| เก็บผัก `PlantingSystem:1067` | บทเรียน `LessonService:299` |
| ตกปลา `FishingSystem:382` | ปลูกต้นสวนผลไม้ `OrchardService:835` |
| นากตกให้ `FishingSystem:868` (ต้องยืนในวง) | ไก่: ช่องสมุดใหม่ / ฟัก / ผสม / ปลดเกษียณ |
| ไก่: ขายไข่ `ChickenService:521`, กวาดดิน `:1312` | |

## ⚠️ จุดที่ต้องกันไม่ให้หุ่น EXP ทำตัวเป็นหุ่นโชค
หุ่นที่ปักทุกตัวอยู่ใน `workspace.QualityBoosters` และหลายระบบนับ "หุ่นทุกตัวในโฟลเดอร์นี้" ถ้าไม่กรองจะได้ผลหุ่นโชคฟรี:
1. `LuckConfig.GetBoosterLuckAt` — ระดับที่ไม่มี `Luck` จะตกไปใช้ค่าเริ่มต้น **20** → ต้องตั้ง `Luck = 0` และข้ามหุ่นชนิด Xp
2. `FarmSlotRegistry.getActiveBoosters` — ใช้กับ `IsSlotBoosted` (ปลูกในวงหุ่น = ได้อย่างน้อย 3 ดาว) และสัตว์เลี้ยงเลือกช่องปลูก → ต้องข้ามหุ่นชนิด Xp
3. `ItemFactory.BOOSTER_NAME_KEY` / `GiveBoosterTool` — ระดับที่ไม่อยู่ในรายการจะถูกเปลี่ยนเป็น x50 (ตอนโหลดกระเป๋าคืนก็ผ่านตรงนี้) → ต้องเพิ่มระดับใหม่ ไม่งั้นหุ่น EXP กลายเป็นหุ่นโชค
4. `BoosterPlacementSystem.TIER_NAME_KEY` — ชื่อหลังปัก
5. ผีน้อยนักปักหุ่น (`PetBoosterPlace` query วนทุกระดับ) → จะปักหุ่น EXP ให้ด้วย (แนะนำให้ปัก)
- ที่กรองอยู่แล้ว ไม่ต้องแก้: `PlantingSystem.inOwnStrawRadius` และโบนัสผลผลิตผีน้อย (เช็ค `== "x50"`), ShopSystem ขายคืน (เฉพาะ x50)

## งานทีละขั้น
1. **Config** `ReplicatedStorage.LuckConfig.BoosterTiers.xp`
   `{ Kind = "Xp", Luck = 0, XpMult = 1.5, XpMultOther = 1.25, Price = 40000, Radius = 15, Lifetime = 300, MaxActive = 1, Template = "XpScarecrowTemplate", PreviewName = "XpBooster", AuraColor = ฟ้า }`
   + ฟังก์ชัน `LuckConfig.GetXpBonusAt(position, userId)` (ใช้ได้ทั้งสองฝั่ง เผื่อ UI)
2. **กรองหุ่น Xp ออก** จาก `GetBoosterLuckAt` + `FarmSlotRegistry.getActiveBoosters`
3. **ไอเทม** `ItemFactory` (ชื่อ/สร้าง/รวมกอง) + `Localization` คีย์ `Item_BoosterXp` (ไทย/อังกฤษ) + `BoosterPlacementSystem.TIER_NAME_KEY` + เช็ค `InventorySystem` โหลดคืนเป็นระดับ xp
4. **โมเดล** `ServerStorage.BoosterTemplates.XpScarecrowTemplate` (pivot ที่ฐาน หน้า = LookVector) — Blender MCP ต่อไม่ติดวันนี้
5. **ร้าน** `ShopSystem.SHOP_ITEMS` แถวใหม่ `CropType = "XpBooster"` + ทางซื้อ + `ShopGui` (รูป 3D / ไอคอน / ข้อความ +50%)
6. **คิด XP** `LevelSystem.AddXP(player, amount, opts)` — `opts.boost = true` = คูณโบนัสจากตำแหน่ง HumanoidRootPart
   - **เพดานกันโกงนับจาก XP ก่อนคูณ** (ไม่งั้นคนเล่นจริงโดนจดชื่อ)
   - คืนค่า XP ที่ได้จริง ให้ผู้เรียกเอาไปโชว์
7. **ผู้เรียก** ใส่ `{ boost = true }` ตามตารางด้านบน + โชว์ XP ที่ได้จริง (ตกปลาส่ง `xp` ไปหน้าจอแล้ว, ไก่ต่อท้าย " · +N XP")
8. **ทดสอบ** ด้วย `execute_luau` เรียกฟังก์ชันตรง (ห้ามกดซื้อจริงใน Play — บัญชีจริง + DataStore)
9. บันทึก `CHANGELOG.md` + `PROJECT_MEMORY.md`

## Backup ก่อนแก้ (backups/<Script>_before_xpScarecrow_20261119.lua) — ทำแล้ว hash ตรง
LuckConfig, FarmSlotRegistry, ItemFactory, BoosterPlacementSystem, Localization, ShopSystem, ShopGui, LevelSystem, PlantingSystem, FishingSystem, ChickenService, ScarecrowPlacer (InventorySystem ไม่ต้องแก้) · ใหม่: XpBuffGui

## ตัดสินแล้ว
- ราคา 40,000 เหรียญ · ขายคืนได้ครึ่งราคา (20,000) · หน้าตา = หุ่นเสื้อแดงชูป้าย x1.5 (Blender) · ป้ายบัฟมุมซ้ายบนแบบฝนตก (XpBuffGui)

## ยังไม่ได้ทดสอบ
- ซื้อ/ขายในร้าน · ปักหุ่น · ป้ายบัฟบนจอ · กระเป๋าเซฟ/โหลดคืน · XP เพิ่มจริงตอนเก็บผัก/ตกปลา

