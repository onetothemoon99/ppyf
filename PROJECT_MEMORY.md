# Project memory (exported 2026-10-23)

Notes about this Roblox game so another machine does not have to re-read the code. Index first, then one section per topic. Source: Claude auto-memory.

## Index

- [multi_edit first-match gotcha](roblox-multiedit-gotcha.md) — anchor edits on unique text; short call anchors hit function definitions
- [Terrace zone](terrace-zone.md) — FarmPlot22 rice terraces over the whole east hill + stream: generation method, multi-Soil code, terrain backups
- [Sea and beach](sea-and-beach.md) — sea fill + beach/palms around farm island (2026-09-26), undo data, remaining polish list
- [Pet auto-feed plan](pet-auto-feed-plan.md) — pet food + converter + Robux auto-feeder (steps 1-3 done, in QuickShop too); gift to a friend (product 3715846020, 2026-10-02, not live-tested)
- [Fishing plan](fishing-plan.md) — fishing decisions, 7-step build order, all 7 steps done 2026-09-27 (rods, fish, minigame/auto, shop+bait, fish index, otter, announce+event fish); otter now needs the whole book (2026-10-01); AUTO-ONLY since 2026-10-18 (no minigame)
- [Live session overlap](live-session-overlap.md) — user may be playing LIVE on the same account during Studio tests; check before DataStore snapshot/restore
- [Pet gacha plan](pet-gacha-plan.md) — design, build order + progress of the pet gacha machine (all 6 steps done 2026-09-24; open: pricing, UNLOCK_ALL before publish)
- [Tutorial](tutorial.md) — ⛔ DISABLED 2026-10-27 (both scripts Enabled=false, TutorialGate.ENABLED=false, 📘 off the ☰ menu; StarterGift now gives new players 5 wheat seeds + booster at once) · new-player tutorial (TutorialService/TutorialGui); v2 since 2026-10-18 = 8 core + 3 bonus steps · 🧭 guide + ▶ AUTO buttons 2026-10-24, free seeds, eye-level 3D arrow, TutorialGate holds join popups, per-step `times` stats
- [VIP title system](vip-title-system.md) — VIP Game Pass overhead title (VipService/VipGui/PlayerNameTags), pass 2001938429; VIP gift to a friend via Developer Product 3715821322 (2026-10-01, NOT yet live-tested by the user)
- [Sultan pack](sultan-pack.md) — 999 R$ pass above VIP (id 2002700579): contents + build notes; all done, live purchase confirmed 2026-09-30; gift to a friend (product 3715827793) added 2026-10-01, not live-tested
- [Luck balance](luck-balance.md) — scarecrow luck 20 / 50; pet luck sultan dragon 50 / fox 30 / legendary 15 (2026-10-02); real-luck formula; golden scarecrow gift to a friend (product 3715868092, 2026-10-02, not live-tested)
- [Gamepad UI](gamepad-ui.md) — every window supports a gamepad (user confirmed on a real controller) + the shared pattern
- [Last position](last-position.md) — rejoin where you left (LastPosition script, safe-spot checks, first spawn only)
- [AFK rejoin](afk-rejoin.md) — 19-min idle → countdown → rejoin same server + fishing-rod resume via TeleportData (both live confirmed); 2026-10-20 BUSIEST server (ServerBrowserService list) only when alone/restarting, normal = same server — not published
- [Weather](weather.md) — rain system (WeatherService/Client/Config), +25% crop / +20% fish bonus, particle gotchas
- [Pet slots](pet-slots.md) — Game Pass 2001134393 "ช่องสัตว์ +1" (3rd pet), PetSlots attr, slot positions; gift to a friend (product 3715828318, 2026-10-01, not live-tested)
- [Planting click + perf](planting-click-and-perf.md) — click-to-plant fix (CanQuery blockers, shared ground-point math) + measured part/FPS budget and steps 2-4; quota gift to a friend (product 3715853171, 2026-10-02, not live-tested)
- [Hotbar layout](hotbar-layout.md) — 6-slot hotbar (slot 6 = rod, slots 1-2 seeds ONLY, new seeds auto-go to 1/2 since 2026-10-16), inventory "ใช้" button, layout saved across rejoin (HotbarLayout DataStore)
- [Warp menu](warp-menu.md) — warp spots (WarpConfig/WarpService/WarpGui, 9 spots) + the "เมนูเพิ่มเติม" ☰ menu (MoreMenuGui) that now holds music, warp, fish book and VIP status (2026-10-02)
- [Graphics settings](graphics-settings.md) — in-game กราฟิก menu (4 levels, FPS, device default, saved), built 2026-10-03; auto-warn toast deferred
- [Typing indicator](typing-indicator.md) — "กำลังพิมพ์..." above the head while chatting (TypingReporter + PlayerNameTags, 2026-10-03, not live-tested); also notes the unclear FPS/crop request
- [Emote system](emote-system.md) — 💃 dance/emote panel (EmoteConfig + EmoteGui, G key, 92 Roblox animations with real names via Animate.PlayEmote), 2026-10-03; click a friend → "เต้นตาม" dance sync (EmoteSync + PlayerClickMenu, not tested with 2 real players)
- [Carry system](carry-system.md) — click a friend → 🤲 แบก (piggyback / ขี่คอ / อุ้มเจ้าหญิง), friend must accept; CarryService/CarryClient; joints are AnimationConstraint not Motor6D (2026-10-03, not tested with 2 players)
- [Far mountains removed](far-mountains-removed.md) — 2 far snowy peaks east flattened 2026-10-03 (hollow terrain shells!), backup TerrainRegion + moved HikingMap items, restore steps
- [Play area walls](play-area-walls.md) — invisible fence (PlayArea module + workspace.PlayAreaWalls) blocks the 2 grey mountains + plain behind, into the sea both ends (2026-10-03)
- [Photo mode](photo-mode.md) — 📷 hide-all-UI mode (☰ menu / P), phase 1 done 2026-10-03; also the Studio level-reset incident (level 161 restored, XP progress lost)
- [Star lock](star-lock.md) — ⭐ button on bag cards: starred produce/fish stacks are not sold, not put in the pet-food machine, not made into bait (2026-10-03, sell path not live-tested)
- [Thai/English i18n](i18n-thai-english.md) — auto language by Roblox LocaleId (Localization.Tr/Pick, PromptLocalizer, DevForceLang Studio switch); phase 1 done 2026-10-03 (fishing/warp/emote/carry/photo/tutorial…), gacha/pets/VIP still Thai
- [Voice indicator](voice-indicator.md) — REMOVED 2026-10-03 (Roblox already shows its own mic indicator); backup in ServerStorage
- [Level/inventory load guard](level-load-guard.md) — LevelSystem + InventorySystem no longer save before a successful load (published 2026-10-04); audit of other stores; a_valinnn set to L30; PENDING: restore his bag when offline, decide on newbierainnii
- [Sun Bee rod](sunbee-rod.md) — "เบ็ดผึ้งน้อย" (SunBee, 199 R$, product 3717142136) + "เบ็ดผีเสื้อ" (NightMoth, 99 R$), on sale; ★3+ guaranteed; junk on ALL rods; showcase cases + otter display NPCs (hold only); only SunBee has a foot aura (2026-10-08)
- [Coin trade](coin-trade.md) — click friend → 💰 เทรดเงิน, 200k/day + 3% tax (CoinTradeService/Config/Gui, 2026-10-08, not tested with 2 players)
- [Day only](day-only.md) — game is daytime only (DayCycle block 9↔15h, Lanternfish no longer night-only), how to restore night (2026-10-03)
- [Promo codes](promo-codes.md) — all redeem codes go through SultanService.redeemPromoCode; WELCOMEBETA = 400k coins; per-type modules incl. witch MG- codes (2026-10-14)
- [Seat drag bug](seat-drag-bug.md) — PivotTo on a seated character drags the invisible Seat → "auto-sit" at warp spots; WarpService.leaveSeat + SeatGuard (2026-10-08)
- [Rotated/buried plots](rotated-plots.md) — farm grid must use soil.CFrame; FarmPlot50-54 rotated/buried under grass, crops sit on grass inside footprint (2026-10-08)
- [Boombox gift](boombox-gift.md) — 🎁 Music Box gift to a friend (product 3717169834, BoomboxGift → BoomboxPromoEntitlements_v1), 2026-10-08, not live-tested
- [Craft bench](craft-bench.md) — โต๊ะช่างนากน้อย pink otter workbench by the fishing shop; phase 1 coming-soon window (2026-10-08), phase 2 = craft/upgrade rods
- [Pumpkin vine](pumpkin-vine.md) — pumpkin = vine on a trellis + one jack-o'-lantern fruit (PumpkinVineGen module, template rebuilt 2026-10-09, not published)
- [Fish v2 (40 species)](fish-v2.md) — fish expansion: FISH_V2 switch (off = old game), Hidden/Retired, book v2 rewards, AI model pipeline, progress per zone (2026-10-08)
- [execute_luau require gotcha](studio-require-gotcha.md) — require() in execute_luau = separate module copy (empty state); dragon-not-planting-after-levelup investigation, root cause unknown, safety nets added 2026-10-09
- [DevPetKeyOverride gotcha](dev-pet-key-override-gotcha.md) — overriding to a real UserId WRITES into that player's pets (Sultan dragon leaked to ju3Lek 2026-10-09); use a fake key
- [Compensation system](compensation-system.md) — CompensationConfig/Service/Gui claim window per Id; round 2 comp-20261013 = 500k coins + golden scarecrow + 5 premium tickets (13–14 Oct, Enabled in Studio, not published); claim tested 2026-10-13
- [Fish skip pass](fish-skip-pass.md) — "⚡ ผ่านทันที" Game Pass in the fish book (unlock all fish + rewards), built 2026-10-10; GAMEPASS_ID still 0, waiting for the user's id
- [Ban system](ban-system.md) — BanService /ban /unban (Bans_v1, cross-server kick + announce), 2026-10-10 not published; MRPTXYZ cheater: ban seeded, data reset PENDING (must be offline), harvest stage-check hole unfixed
- [Booster seasonal skins](booster-seasonal-skins.md) — Halloween 2026 skin for หุ่นฟางดวงดี (LuckConfig.BoosterSkins, Enabled = false, user does NOT want it released yet), built 2026-10-11
- [Seasonal events](seasonal-events.md) — SeasonConfig one-switch festivals + Halloween 2026 map decorations (SeasonalDecor loader, kit, HalloweenDecorGen), switch OFF, DevForceSeason set in Studio (2026-10-11)
- [Sound groups](sound-groups.md) — 4 volume sliders (music / EffectSounds / NatureSounds / Music Box); every new Sound must join a group; nature slider added 2026-10-11
- [Cheat watch](cheat-watch.md) — CheatWatch flags (CheatFlags_v1, /flags, owner toast) + XP cap/lifetime check in LevelSystem (2026-10-11, not published); gacha audit: no result-picking hole, likely cheated coins + pity
- [Streaming: atomic models](streaming-atomic-models.md) — StreamingEnabled: multi-part models need ModelStreamingMode Atomic or weak phones get them incomplete (pets fixed 2026-10-12, unconfirmed on device)
- [Server crash diagnosis](server-crash-diagnosis.md) — how to investigate a live server drop (DisconnectLogs_v1 scan + public Roblox APIs); incident 2026-10-13 03:49, cause unconfirmed
- [Auto restart](auto-restart.md) — scheduled soft restart 01:00/09:00/17:00 via transit place (AutoRestart, RestartScheduleConfig, transit/RestartTransit.server.lua), built 2026-10-14, inactive until TransitPlaceId set, real teleport untested
- [Admin commands](admin-give.md) — /give (coins/x100/x50/tickets, cross-server, AdminGrants_v1 queue+log) and /restart; owner-only, 2026-10-10, not play-tested
- [Scarecrow ghost pet](scarecrow-ghost-pet.md) — Secret pet ผีน้อยนักปักหุ่น (Halloween 2026 gacha event, ScarecrowPlacer ability places scarecrows from the bag), season-gated, built 2026-10-11, real pet flow untested
- [Boat seats](boat-seats.md) — lake rowboats sittable via "นั่งเรือ" prompt (BoatSeats script, 2 seats/boat), 2026-10-12, prompt press not hand-tested
- [Studio camera restore gotcha](studio-camera-restore-gotcha.md) — stuck Scriptable edit camera (no right-click rotate): execute_luau reverts CameraType at command end, fix with task.delay
- [Trash event](trash-event.md) — ทะเลสาบวิกฤต junk event at Misty Lake (TrashEventConfig/Service/Gui, 3 rounds/day, +30 pts junk, missions), built 2026-10-12, ENABLED = true, not published, 3D look unverified
- [Boxing ring](boxing-ring.md) — สนามมวยนากบัญชา on the south beach (BoxingConfig/Service/Client, loser staggers 60 s), 2026-10-12; not tested with 2 players or on mobile
- [UIScale canvas gotcha](uiscale-canvas-gotcha.md) — ScrollingFrame under UIScale: divide AbsoluteContentSize by the scale or phones can't scroll to the end (Music Box + pet-menu fish book fixed 2026-10-12, untested)
- [Island rebuild plan](island-rebuild-plan.md) — user chose to rebuild the whole island after a concept picture (10 plots + moats, shops on the south edge, pier); decisions + survey 2026-10-13, nothing built yet
- [Beach bar](beach-bar.md) — เวทีริมหาด + บาร์เสิร์ฟเครื่องดื่ม (IslandDecor.BeachStage, BarConfig/BarService/BarGui, 8 drinks held in hand), built 2026-10-13, not published
- [Level board](level-board.md) — ป้ายอันดับเลเวลสูงสุดทั้งเกม สีเขียวอ่อน (workspace.LevelBoard, LevelLeaderboard_v1), built 2026-10-13, not published
- [Premium witch pet](premium-witch-pet.md) — แม่มดน้อย LittleWitch, Premium tier, Robux-only (+1 Lv per purchase to 15), plants 2 per cast; product 3718537123, 450 R$; gift to a friend product 3718617176 (2026-10-15, not purchase-tested)
- [Witch Berry crop](witch-berry-crop.md) — Halloween seasonal crop WitchBerry (lv30, 80 s, season-gated seeds) + list of the 11 scripts to edit when adding a crop (2026-10-14, not published)
- [Mount gacha plan](mount-gacha-plan.md) — ตู้สุ่มสัตว์ขี่ + ของแต่ง + ของตกแต่ง (bag tabs, furniture placing, glass showcase case), coins only; ENABLED again 2026-10-19 night (after an evening disable) — not published; rates in MOUNT_GACHA.md; llama Game Pass 2039540565; llama gift to a friend product 3719679834 (2026-10-19, not purchase-tested)
- [Community reward](community-reward.md) — 👥 join group 642396060 → 5 Premium tickets once (CommunityReward/CommunityRewardGui), 2026-10-15, not published
- [Player behavior analysis](player-behavior-analysis.md) — retention from DataStores (method + gotchas); 2026-10-16: new-player median playtime fell ~30 → ~3 min after Oct 12, new joins 82/day → ~10-20
- [Tester accounts](tester-accounts.md) — CtrlZ_2 (11611605711) is a tester: its cheat flags are expected, don't investigate
- [Voice check](voice-check.md) — new-player mic diagnosis + hint cards (VoiceHint/VoiceCheckReport → DisconnectLogs health.voice), 2026-10-27, not play-tested, not published
- [Wishing pond](wishing-pond.md) — lotus lake dock: throw 8 produce → fairy → Birthday/Creative wish (cosmetic, can target a friend in the server; birthday = gifts + song), 2026-10-18, not published, not tested with 2 players
- [LoadCharacter bag wipe](loadcharacter-bag-wipe.md) — LoadCharacter() empties the bag (no Died snapshot) → cause of owner bag loss 2026-10-15; DevInventoryKeyOverride set to fake key; both bag guards built 2026-10-15 (respawn restore + shrink block), not published
- [Birthday event](birthday-event.md) — 🎂 อรพรวันเกิด 2026-10-19 17:00–24:00: gift box + countdown, wish VXLLLYN at pond → rewards, navigation; HIDDEN 2026-10-21 (Enabled = false, dev switches removed)
- [Chicken farm plan](chicken-farm-plan.md) — chicken system phases 1-5 built 2026-10-20 (shared yard, breeding, book, show yard, upgrades, Robux ids); phase 6 (contest + hall of fame) + contest board + tutorial step 12 built 2026-10-22 untested; re-ENABLED 2026-10-23 (after a 10-22 evening hide); gift auto-feed / instant-hatch to a friend built 2026-10-23 (products 3721246128 / 3721246800, not purchase-tested); coop cleaning (dirt slows eggs, broom hold E) built 2026-10-23
- [Daniweii3 bag loss](daniweii3-bag-loss.md) — bag wipe 10-20/21 cause unknown, merge-restored; JoeZaika087/EIMUUNOII suspicious; DataStore versions hourly + Studio List throttle gotcha
- [Custom matchmaking](custom-matchmaking.md) — Occupancy 10 / play history 0 etc. applied live 2026-10-22 11:06 to stop new players landing in empty servers; verify via solo 1-player servers
- [Zukzon dog pet](zukzon-dog-pet.md) — ซุกซน chihuahua, owner-only tier ลึกลับ (Mythic); built 2026-10-22 (since 10-23 no abilities, no luck — only owner hug +10%, free slot, sit/sleep; /give zukzon), not published
- [Donation announce](donation-announce.md) — donate + message shown on every server 12 s (DonationAnnounceConfig/DonationAnnounce/DonationAnnounceGui), built 2026-10-24, not published, real purchase untested


---

## admin-give

- `/give <username|UserId> <coins|x100|x50|ticket|premium|feeder|vip> <amount> [reason]` (feeder = permanent auto feeder via AutoFeederGift_v1 to_<id>; vip (2026-10-14, amount optional) = permanent VIP via VipGift_v1 to_<id> + attr AdminVipGranted that VipService listens to) — ServerScriptService.AdminGive. Queue in DataStore `AdminGrants_v1` key "u<userId>" {pending, log(50)}; MessagingService "AdminGrant" wakes the server the player is in; offline players get it on next join. Built for compensating kwanindy27 (~300k coins lost 2026-10-10 02:53 by the stale-load-on-rejoin bug).
- `/restart N` / `/restart cancel` — ServerScriptService.RestartNotice (countdown banner with otter head + pre-save at 45 s). Owner presses Shut Down in the Dashboard.
- Admins = 9360333174 (One_moretime91) + game.CreatorId; both scripts have their own ADMINS table.

**Why:** the user wanted to fix player issues without asking me to edit DataStores by hand.
**How to apply:** suggest these commands for compensation/restarts; check the `AdminGrants_v1` log to see what was given. Not play-tested at creation. Related: [[compensation-system]].


---

## afk-rejoin

User request 2026-09-30: after 19 minutes idle, make the player rejoin, since Roblox kicks at 20 minutes. The game is AFK-focused.

Client StarterPlayerScripts.AfkRejoinClient:
- Idle = max(own timer, Roblox's timer from Player.Idled).
- The own timer resets on InputBegan, mouse move/wheel/touch InputChanged, and thumbsticks above 0.25.
- At 19 minutes, a 10-s countdown card appears (AfkRejoinGui, DisplayOrder 30, scaled 0.75 on screens under 500 px) with a "✋ ยังอยู่" button. Any input cancels.
- At 0 it fires RemoteEvent RemoteEvents.AfkRejoin. The "sent" phase gives up after 25 s or on input.
- On arrival, GetLocalPlayerTeleportData().afkRejoin shows a "เข้าเกมใหม่อัตโนมัติแล้ว" card.
- Studio test hook: player attr AfkTestRejoinAfter (seconds), Studio only.

Server ServerScriptService.AfkRejoin:
- 20-s cooldown per player.
- TeleportAsync to the same JobId (skipped for private servers), with TeleportData { afkRejoin = true }.
- If that fails (pcall error or TeleportInitFailed), it tries any server once.
- In Studio it only notifies ("studio" reply), because teleports don't work there.
- LastPosition ([[last-position]]) puts them back at the same spot.

Tested in Studio: the countdown, the request reaching the server, key-press cancel, and a stuck "sent" state (fixed). The user CONFIRMED the live 19-minute rejoin works (2026-09-30).

Fishing resume (2026-09-30, user request):
- AfkRejoin server: takeFishingSnapshot when the request arrives. If the character holds a Tool with IsFishingRod, it records {rodId, auto = FishingAuto attr, bait = FishingBait attr}, and TeleportData becomes {afkRejoin, fishing}.
- LastPosition sets player attr "SpawnPlaced" after the first-character placement (moved or not).
- AfkRejoinClient.resumeFishing on arrival:
  - Waits for SpawnPlaced (25 s) + 1.5 s, then waits (30 s) for the rod with the same RodId in the backpack.
  - Humanoid:EquipTool, then FishingBait:FireServer(bait), then FishingAuto:FireServer(true) if it was auto. FishingClient's tryAutoCast then casts at the water ahead (LastPosition restored the yaw).
  - Shows the card "🎣 กลับมาตกปลาต่อที่เดิมแล้ว".
- Studio hook: PlayerGui.AfkRejoinGui.TestResume:Fire({rodId, auto, bait}).
- Tested at the lake dock: the Bamboo rod was equipped, auto turned on and the bobber was cast.
- The user CONFIRMED fishing resume works on the live server (2026-09-30).

Fishing resume after a SERVER RESTART (2026-10-03, user: "รีเซิร์ฟเวอร์ ตอนตกปลาออโต้อยู่ กลับมายืนตัวเปล่า"): TeleportData doesn't exist after a shutdown, so AfkRejoin (server) now also uses DataStore "FishingResume_v1" (key = userId, {rodId, auto, bait, t}).
- fishingCache[player] = takeFishingSnapshot, refreshed on rod equip/unequip (character ChildAdded/ChildRemoved), FishingAuto/FishingBait attribute changes and every 5 s. Needed because in PlayerRemoving the character is often already gone.
- saveResume(player) runs in PlayerRemoving (and BindToClose for anyone left, which then waits up to 8 s). Skipped if the player made an AFK-rejoin request in the last 60 s (TeleportData already carries it). Side effect (intended): leaving the game yourself while fishing and coming back within RESUME_WINDOW = 600 s also resumes.
- On join: GetAsync (3 tries) → RemoveAsync (one use) → if age ≤ 600 s set player attrs ResumeAuto, ResumeBait, ResumeRodId (last). AfkRejoinClient.checkRestartResume (attr listener, once) calls the same resumeFishing() as the AFK path (waits SpawnPlaced, equips the same rod, sends bait, turns auto on).
- Studio: disabled unless workspace attr DevFishingResumeTest = true (stopping Play = shutdown). Removed after testing.
- Verified in Studio: record written on stop; next Play → log "รีเซิร์ฟเวอร์ตอน … ตกปลาอยู่ = ให้ตกต่อ (Bamboo, ออโต้)", back at the beach, rod equipped, auto on, and it really caught a Clownfish ★2 (I removed it from the stack 3→2; a little auto XP stayed). Equip-then-stop within 0.5 s also saved after the event-driven cache fix. Test records removed, character put back at (372,23,142).
- Backups _Backup_20261003.AfkRejoin/AfkRejoinClient_before_restartresume. Needs Publish; not tested on a real server restart.

2026-10-10:
- Seat resume: snapshot has seat {x,y,z} (TeleportData + FishingResume_v1); on arrival resitLater() waits SpawnPlaced then Seat:Sit on the free Seat/VehicleSeat within 1.5 studs. Save verified, the actual re-sit NOT verified (Play hung).
- Player report "stuck on loading screen after AFK": likely same-JobId teleport when the player was alone (server empties and shuts down mid-teleport; TeleportInitFailed can't fire after they left). Now sameServerOk(): same server only if other players remain and no RestartEndsAt pending; else public-server teleport. Not testable in Studio.
- LastPosition: death/Reset now respawns at the last safe sample; Reset again within 15 s = normal spawn.
- FishingNoPush: collision groups PlayerChars / FishingChars (rod holders don't collide with other players).

2026-10-12 (user report twice: after the AFK rejoin the character holds the rod but does not auto-fish):
- Cause (reproduced in Studio): FishingClient.findWater auto-casts only at water straight ahead of the HRP (or mouse.Hit), and casting never turns the character. A player who cast by tapping water to the side comes back facing no water → idle forever.
- Fix: snapshot carries `cast` = bobber position (`castInfo`/`lastCast` in AfkRejoin; attr `ResumeCast` on the restart path); AfkRejoinClient.resumeFishing fires `FishingCast` at that point if no `<Name>_Bobber` after 3 s (5 tries).
- Studio test via TestResume, facing away from the canal at (129.5, 6, -18): without `cast` no bobber for 12 s; with `cast` bobber within 6 s. Not verified on a live server; publish not confirmed. If the report continues AFTER a publish, look elsewhere (LastPosition checkSpot rejecting the spot, snapshot auto=false).

2026-10-17 incident: CtrlZ_2 (11611605711) got error 279 on the same-server AFK teleport at 01:57 (server 305e9060 healthy; 3 others rejoined fine that minute) → client-side network failure; came back by hand 12.6 min later. Gap found: saveResume is SKIPPED when an AFK request was made <60 s before leaving, and RESUME_WINDOW = 600 s → after a failed AFK teleport + manual rejoin >10 min, fishing/seat resume is lost. Plan proposed to the user (NOT built, user said plan only): (1) measure AFK success rate from DisconnectLogs_v1 (attempt → next arrival within ~30 s), (2) always save FishingResume_v1 on AFK request + longer window for AFK-failure case, consumed on successful arrival, (3) optional "หลุด 279 กดลองอีกครั้ง" tip, (4) maybe test whether a LocalScript can keep Roblox's idle timer alive without teleporting (feasibility/ToS unknown).
Step 1 done 2026-10-17 (measured from DisconnectLogs_v1, all 353 keys, only the last 12 sessions per user are kept): 306 AFK attempts by 60 players since 2026-10-09 22:12 → 304 back automatically (median 1.5 s, max 6.6 s; 302 same server), 1 failed + manual return (CtrlZ_2 17/10 01:56), 1 never came back (u7834361268 10/10 06:35, failed or quit). Success ≈ 99.3%. Steps 2-4 not started.
Step 2 BUILT 2026-10-17 (Studio, not published): saveResume no longer skips AFK leaves — writes FishingResume_v1 with `afk = true` (snapshot = fishingSnap from the request), window AFK_FAIL_WINDOW 1800 s; onPlayerAddedResume: TeleportData.afkRejoin arrival → no resume from the record, drops afk records older than join (after DataLoadRetry.Load wait, again at +30 s). Verified: save with afk=true. NOT verified: resume on a late manual join (Studio Play hung on start), success-path deletion (needs live). Test hook: workspace attr DevFishingResumeTest=true, set record t back 900 s, Play. Backup _Backup_20261017.AfkRejoin_before_failresume.
2026-10-17 later: late-manual-join resume VERIFIED in Studio (afk record 900 s old → server log "ย้ายเซิร์ฟตอน AFK ไม่สำเร็จ แต่ … ให้ตกต่อ (NightMoth)", rod held at the end). Success-path deletion still live-only. Gotcha that day: after one Play stop the MCP start_stop_play got stuck ("Start play hasn't finished yet"/timeout) even after a Studio restart; the user pressing Play manually works, and get_console_output still shows the Play log afterwards (MCP can't attach to the Server/Client DMs then).

2026-10-20 BUSIEST-SERVER target (Studio, not published): after the 09:00 restart players split into 3 servers. DisconnectLogs showed why: during the /restart countdown sameServerOk()=false → public-server AFK teleports (valynlnwza 08:58 → new 664b9333; newbierainnii 08:51 + CtrlZ_2 08:53 → d89fd55e, arriving only ~09:01), then Roblox's restart put the remaining 4 into a separate replacement server 89a7f974 (Roblox keeps each old server's players together, but always in a NEW server). Fix: ServerBrowserService records now carry PlaceVersion + Restarting; AfkRejoin.pickBusiestServer() picks the fullest other server (newest version, not restarting, fresh ≤40 s, ≥2 free slots) and goes there if the own server can't be used, is outdated, or the other has more players than remain here; else old path. Target label "busiest-server". Logic verified with mocked lists only; real teleport live-only. Check after publish: next restart should end in 1–2 servers; DisconnectLogs afkRejoinTarget=busiest-server arrivals.
UPDATE same day (user: "ไม่อยากให้กระทบของเดิม"): busiest-server is now used ONLY when sameServerOk() is false (alone / restart countdown) — i.e. only where the old code went public-server. Normal AFK rejoin = same server exactly as before. Reason: LevelSystem's pendingLeaveSaves wait (load waits for the leave save) only works inside the same server; no session lock across servers. Dropped the "other server has more players" and "outdated" rules.

2026-10-20 mount resume (user: rode the llama while AFK-fishing, came back on foot): snapshot now has `mount` (RidingMount) → TeleportData.fishing.mount + FishingResume_v1 `mount`; arrival `rideLater` (waits SpawnPlaced + 0.8 s; skipped when seated/already riding/carried) invokes ServerStorage.MountRideRequest (new BindableFunction in MountService). Seat resume wins over mount. Studio hook ServerStorage.AfkArrivalTest:Fire(player, td) + PlayerGui.AfkRejoinGui.TestResume. Simulated: riding at 1 s, rod 2 s, auto+bobber 3 s. Real teleport untested; not published.


---

## auto-restart

Built 2026-10-14 at the user's request (restart every day 01:00 / 09:00 / 17:00 Thai to test whether crashes stop; see [[server-crash-diagnosis]]).

- `ServerScriptService.RestartScheduleConfig`: Enabled, TransitPlaceId (0 = does nothing), TimesTH, CountdownMinutes 5, SkipIfUptimeUnderMinutes 0 (user wants it as an option, off by default), StaggerMaxSeconds 180, PostponeDuringTrashEvent.
- `ServerScriptService.AutoRestart`: countdown via `RestartNoticeLocal` (new BindableEvent in RestartNotice) → teleport everyone to the transit place in batches of 25 with TeleportData softRestartHops → transit sends them back to the main place (new server). Late joiners to a closing server are forwarded (max 3 hops). 2 failed moves → Kick with a rejoin message. Owner chat: `/autorestart now [min]`, `cancel`, `status`. Studio test: `workspace.DevAutoRestartNow = <seconds>` (no real teleport in Studio).
- Transit place script lives in the repo at `transit/RestartTransit.server.lua` (waits 6 s, sends back in groups, 3 tries, then Kick). The user chose a separate Place (option A) so no game systems/DataStore loads run in transit.
- Fishing resume and position need nothing new: AfkRejoin saves FishingResume_v1 on pre-save/leave, LastPosition saves on leave; AfkRejoin.sameServerOk already avoids the same server while RestartEndsAt is set.

**Paused by the user 2026-10-14** ("ยังไม่ต้องทำ") before creating the transit place; they restart by hand (`/restart 5` + Shut Down). The scripts stay in the place and are inert while TransitPlaceId = 0. The user once sent the MAIN PlaceId (75556752635760) thinking it was the transit id — the transit must be a different Place.

**Status 2026-10-14:** Studio-tested countdown only. NOT tested: real teleport, transit place (not created yet), multiple servers. Next: user creates the Place, I/they put the script in, publish transit, set TransitPlaceId, publish main, live test `/autorestart now 1` at a quiet time.


---

## ban-system

`ServerScriptService.BanService` (2026-10-10, compiled only, not play-tested, needs Publish): owner commands `/ban <username|UserId> [reason]`, `/unban <name>`. DataStore `Bans_v1` key `u<userId>` (Studio play uses `studio:u<id>`). Calls `Players:BanAsync` (universe, alts), MessagingService topic `BanNotice` kicks on every server + HarvestNotify toast announcement (TH/EN) to everyone. Join check kicks banned players; a record with `announced=false` (seeded from Studio) is announced once on the first join attempt. Read failure = let the player in.

Case MRPTXYZ (UserId 11581203142): first joined 2026-10-09 17:12 UTC, 352 min playtime, level 515 (13.28M XP = ≥265k harvests), coins 65k → 9.89M in the last 12 min, no Robux purchases. User decision 2026-10-10: reset to a new player + ban + announce in servers.
- Done: ban record seeded in the real `Bans_v1["u11581203142"]`.
- DONE 2026-10-10: the user published BanService and ran `/ban MRPTXYZ` live (14:58 UTC; record shows `official=true`, `announced=true` → BanService works in the live game). Data reset at 15:01 UTC after confirming >5 min since his last save: level 1, coins 0, bag = Bamboo rod only, pets/shards empty, gacha tickets/pity 0, coin-bought plant quota 0. At ban time he was L560 with 322k pumpkin seeds + 312k pumpkins. Restorable from DataStore version history for 30 days. Case closed.
- FIXED in Studio 2026-10-10 (compiled, not play-tested, not published): `doHarvest` now checks `slot.stage == 5`; harvest prompt goes through a server distance check (`HARVEST_PROMPT_MAX_DISTANCE = 30`). The vector itself was never proven (code reading only).
- Also fixed: NaN from the client passes `math.clamp` and every `<`/`>` check ("not enough coins" always passes) — guarded in ShopSystem buySeed/sellCrop, GachaService buyWithCoins, FishingShop makeBait, PetFoodConverter insert, PetOwnership.UseDupes. Any new remote taking a number must reject `x ~= x`.
- Option 3 (scan other players for level vs playtime) not done.
- Tool gotcha: a `multi_edit` with `replace_all` + trailing newline reported "applied" but changed nothing — verify edits with a find afterwards.

Case Weparit (UserId 1319168118, display name "MRP", 2026-10-10): same pattern (L9 → L255 in 4 h, coins 14 → 4.37M in 1 h) and sent 200k coins to MRPTXYZ at 16:18 TH, 8 min before that account started pumping — likely the same person. User ran `/ban Weparit` live (22:10 TH) and asked for both accounts to be reset to beginners; done 22:17 TH. Full reset list used: PlayerLevel, PlayerCoins, PlayerInventory (Bamboo only), PetOwnership, PetSettings, GachaTickets (keep receipts), PlantBoostPurchases, FishIndex, FishingShop (Bamboo only), HotbarLayout. Left alone: Tutorial, StarterGift, PlaytimeRewards, LastPosition, CoinTradeDaily. When checking a suspect, look at `CoinTradeDaily_v1` for links to other accounts.

Case HJOPPOU (UserId 11589860981, display "BANGUDI", 2026-10-11): L11 → L813 in 7.5 h (10 Oct 21:46 – 11 Oct 05:16 TH), coins to 49M, coin-bought plant quota x3 with <9k saved coins. He pumped AFTER the MRPTXYZ ban, so the exploit was still live then — whether the harvest/NaN fixes are published was not confirmed (ask the user). User banned live 13:37 TH and asked for a reset; done 13:56 TH with the same list. Sent 100k to Namo_dln (7812929697, looked normal, not deep-checked).

Whole-server scan method (2026-10-11): enumerate players from OrderedDataStore `PlaytimeLeaderboard_v1` (256 players), read level + coins per player, sort; do it from the Play Server datamodel (Get budget ~2000, refills ~100/min; bursts of 80 parallel players throttle). The user interrupted a long scan and asked for just the top-10 level / coins lists — prefer that quick ranking first. Not yet checked: PeaUzi01 (L542, 27M) and 0xoARESox0 (L505, 19.9M), both with 115–125 h playtime.

Cheater records: the user keeps a list in `D:\one_project\Dontae\CHEATERS.md` (summary table + per-player section with evidence, timeline, actions; Thai time). Add new cases there and update the status rows when a ban/reset is carried out.

Investigation tips: `GetVersionAtTimeAsync` uses the GetVersion budget (130) and works when `ListVersionsAsync`/`ListKeysAsync` are throttled — the Studio List budget is tiny (~22); a loop of ListKeysAsync over many stores exhausts it for a long time. Playtime per player = OrderedDataStore `PlaytimeLeaderboard_v1` (minutes). See [[admin-give]] for the shared owner-command pattern.


---

## beach-bar

2026-10-13, user requests: "เพิ่มเวทีร้องเพลงตรงหาดนี้ ลานบาร์", then "อยากให้บาร์สามารถเสิร์ฟน้ำได้ เลือกเครื่องดื่มได้ และตอนนั่งให้หันหน้าเข้าหาบาร์".

- Scenery: `workspace.IslandDecor.BeachStage` (part-built): Stage x 118..134, z −387..−357 facing −X, DanceFloor, Bar at (104,−338), 5 parasol tables, 20 Seats, 4 torches. Stage is decor only (no music/karaoke system).
- Drinks: `ReplicatedStorage.BarConfig` (8 drinks with En, Color, Cup, Top = straw/umbrella/cream; COOLDOWN 2, DURATION 300, MAX_DISTANCE 45, PROMPT_TAG "BarPrompt"), `ServerScriptService.BarService` (RemoteEvent `RemoteEvents.BarOrder`: drink id or "none"; builds Model `BarDrink` welded to RightHand at RightGripAttachment + plays Roblox toolnone anim 507768375 (R6 182393478); cleared on timeout, when a Tool is equipped, on CharacterRemoving), `StarterPlayerScripts.BarGui` (WarpGui-style list window, gamepad + Thai/English, BindableEvent `BarGui.OpenBar` for tests, opens from the tagged ProximityPrompt on `Bar.CounterTop`). PromptLocalizer got the two prompt strings.
- **CORRECTION 2026-10-13 (user bug report: "ตอนถือแก้ว เมื่อถือไอเทมต้องอยู่ในช่องใช้ไอเทม"):** the welded-to-hand version above was wrong for this game — anything a player holds MUST be a real Tool that lives in the 6-slot hotbar. Now BarService gives a `Tool` (attrs IsDrink, DrinkId, DrinkIcon; root part "Handle", identity Grip → cup upright) into Backpack; BarGui.placeDrink waits for it, calls `HotbarState.UseTool` and equips it. HotbarState.CanPlaceInSlot keeps IsDrink out of slots 1–2; CustomHotbar/FullInventoryGui got an IsDrink icon/strip branch. IsDrink is deliberately NOT in HotbarState KEY_ATTRIBUTES, so its layout key is "" (never saved, no ghost reservation) and a new drink returns to the same slot. InventorySystem does not scan the Backpack, so the tool is not saved. Verified in Play with a real click on the menu button (slot 4, held, swap, return). Backups `*_before_drink`. Rule for future held props: make a Tool + hotbar slot, never weld to the hand.
- Drinkable 2026-10-13 (user: "ทำให้กินได้ด้วย"): click/tap while holding (Tool.Activated, hooked in BarGui) → client computes the hand→mouth offset in the grip frame from its real pose (rim 1.3 above Handle, tilt 38°) and fires `BarOrder("sip", offsetCFrame)`; server tweens `Tool.Grip = offset:Inverse()` 0.3 s, plays a gulp sound (ProSoundEffects 9114171955 / 9114172114 / 9114171960, group EffectSounds), shrinks the `Liquid` part (toggle its WeldConstraint off/on around the CFrame write), tweens back; BarConfig.SIPS = 6 then the tool is removed. No drink animation exists (I cannot upload animations) — the cup moves, the arm does not; offer to swap in an animation id if the user supplies one. Verified numerically in Play via `tool:Activate()` (rim 2.15 → 0.66 studs from head centre, 6 sips empties). Not seen by eye / heard.
- My defaults, not confirmed by the user: free, cosmetic only, no sip animation, not saved.
- A seated character faces the Seat's LookVector: use `CFrame.lookAt(seatPos, target)` to aim seats (bar stools → counter, table stools → their table).
- Tested in Play via remotes (seat facing, window, give / swap / return, no errors). Not tested: real prompt press, Tool-equip clearing, timeout, phone/gamepad, second player's view, the cup's look.

Related: [[island-rebuild-plan]], [[gamepad-ui]], [[i18n-thai-english]].

2026-10-14: user reported the Thai tea and Blue Hawaii soda icons showed as squares. Cause: newer emoji (🧋 U+1F9CB, 🫧 U+1FAE7) are not in Roblox's font. Changed to 🥤 and 🍹 in `BarConfig.Drinks`. Rule: only use older emoji (other known boxes in this game: 🪱, 🪙). Not confirmed in Play that 🥤 renders (🥥 from the same Unicode version does).
2026-10-14: user said the orange juice cup was ugly and asked for a new model. Cause seen in a side-by-side capture: the white Glass cup at transparency 0.35 washes the liquid to cream, and the "umbrella" is just a pink disc. New `Top = "orange"` branch in BarService.buildDrink (clear glass 0.6, thick base, orange slice on the rim, green straw, mint leaves; `Liquid` part unchanged so sips still lower it). The other 7 drinks still use the old milky cup and look washed out too — offered, not changed. Not ordered/held in Play.
2026-10-14 later (user: "จัดไป"): all 8 cups rebuilt. BarService now has a `DECOR` table keyed by `drink.Top` then `drink.Id` (coconut shell, foam + ice, fruit wheels, cream toppings…), clear glass for every drink, and floating pieces (ice, foam) carry attribute `FloatCF` so `setLiquid` lowers them with the liquid. `BarConfig` Cup/Top values of the old style no longer matter (only Color). Previewed in Edit by loadstring-ing the builder block out of the script (parts must be re-placed manually: setting a welded part's CFrame in Edit does not move the rest). Backups `_Backup_20261014.*_before_newcups`. Not held/sipped in Play.
2026-10-14 (user: show the drink MODEL in the item slot): BarService builds `ItemPreviewModels.Drink_<Id>` at startup from buildDrink; `ItemPreview.GetToolModelName` returns that name for IsDrink tools, so hotbar / bag / drag previews pick it up with no other change. Tip: StarterGui ScreenGuis render in Edit-mode screen captures, so ItemPreview viewports can be checked in Edit (ReplicatedStorage.ItemPreviewModels exists in Edit too — mark temp models and remove only those).


---

## birthday-event

Built 2026-10-19 (user request). Window 19/10/69 17:00 → 20/10/69 00:00 Thai (unix 1792404000 → 1792429200).
- Tasks: go to the lotus pond → throw 8 produce ([[wishing-pond]]) → Birthday wish for VXLLLYN. Rewards once per account: 5 Premium tickets, quota +5 ×1 (PlantQuotaPromoGrant), 555,555 coins, permanent VIP unless already VIP/Sultan (VipGift_v1 "to_<id>" + AdminVipGranted, see [[vip-title-system]]).
- WishingPond: targetId "bday" = honoree row (works when VXLLLYN is offline, party plays on the wisher with her name on the banner); fires BindableEvent ServerScriptService.WishingPondWished.
- Box workspace.BirthdayEventGift is created/destroyed by the server; the client adds the countdown + window + 🧭 navigation (beam + arrow, auto-off within 14 studs).
- Studio switch: workspace attr DevBirthdayForce = true (1 h window). Claims in BirthdayEvent_v1 "<Id>:<uid>" ("studio:" prefix).
- Gotcha: 🪷 does not render in Roblox fonts (box) → use 🌸.
- Tested in Play: box, countdown, window, navigation, arrival. NOT tested: the real 8-throw → wish → reward grant.
- An earlier unused attempt exists: ServerScriptService.EventPromoCodes (code version of the same rewards).
- Dev test switches (2026-10-19, Studio only, all set in workspace): DevBirthdayForce, DevBirthdayRepeat (+ DevBirthdayReset during Play), DevBirthdaySimulate (no real items), DevWishThrowsNeeded = 1 (WishingPond). Full flow verified in Play with simulate on; a REAL grant is still untested.
- 2026-10-21: user said tests passed → HIDDEN: BirthdayEventConfig.Enabled = false, Studio switches DevBirthdayForce/Repeat/Simulate + DevWishThrowsNeeded removed from workspace. Code kept for reuse (set Enabled + new StartsAt/EndsAt).


---

## boat-seats

User request 2026-10-12: make the rowboats sittable. The 3 `Workspace.RestSpots.LakeLife.Rowboat` models are one non-collidable AI MeshPart each (`body.body_geom`, long axis = local Z, bow = +Z), floating in the lake, so touch-to-sit can't work.

Built (Studio only, not published): per boat 2 invisible anchored Seats `BoatSeatMid` (local y 0.70, z 1.05) and `BoatSeatStern` (y 0.55, z -1.9), attr `BoatSeat`, CanTouch off, facing the bow, each with ProximityPrompt `SitPrompt` ("🚣 เรือพาย" / "นั่งเรือ", distance 9). `ServerScriptService.BoatSeats` does `Seat:Sit` on trigger and hides the prompt while occupied. English strings in `PromptLocalizer`.

Tested with server-side `Seat:Sit` only (sit, prompt hide, jump off). Not tested: pressing the prompt by hand / on mobile, seat height by eye (pets blocked the screenshot). Seat offsets came from raycasting a Default-fidelity collision copy, so adjust y if the user says the character floats or sinks. Related: [[seat-drag-bug]] (SeatGuard tracks these anchored seats), [[afk-rejoin]] (seat resume works with any Seat).


---

## boombox-gift

2026-10-08: the user asked for a 🎁 button on the Music Box card in the special shop and gave product id 3717169834.

It follows the other gift features ([[pet-slots]], [[vip-title-system]], [[sultan-pack]]):
- `BoomboxConfig.GIFT_PRODUCT_ID`.
- ServerScriptService.BoomboxGift: RemoteFunction BoomboxGiftRequest `giftSelect`, registered with PurchaseRouter.
- Grants by writing `owned = true` into DataStore BoomboxPromoEntitlements_v1, the same store as the Boombox redeem codes, which BoomboxService already reads on join. If the receiver is online, it also sets attribute BoomboxPromoOwned.
- Pending receiver is stored in BoomboxGift_v1.
- Client: PlantLimitGui GiftBoomboxButton → VipGui OpenBoomboxGift → gift kind "boombox".

Not live-tested with two real players. NOT yet published as of 2026-10-08 (the user published the other four changes of that day without it).

## Model (2026-10-11)
The penguin is built in code: ServerScriptService.ItemFactory `CreateBoomboxAccessory` (not a stored model). User asked for a nicer look with cute speaker ears → headphone-style speaker cups on both sides of the head + pink headband, eye shine, cheeks, tuft (37 parts). Gotcha: a Part with Shape Ball always renders as a uniform sphere — use Block + SpecialMesh Sphere for squashed shapes (`roundBoomboxPart`). Preview method that worked: build anchored copy in workspace in Edit mode + screen_capture with camera args. Backup _Backup_20261011.ItemFactory_before_boomboxlook. Not published.
Same day: the on-screen 🐧 button icon is now the real model in a ViewportFrame (BoomboxService puts `ReplicatedStorage.BoomboxIconModel` at server start from the same builder; BoomboxBackClient `PenguinIcon`, emoji fallback); the special-shop card (PlantLimitGui `BoomboxCard`) uses the same model icon. screen_capture also works during Play (shows the game UI).

## Playlist names (2026-10-11)
Playlist rows show title + "artist · ID" (BoomboxBackClient renderPlaylist; server already sent title/artist/loading). `BoomboxConfig.DEFAULT_PLAYLIST` entries may be `{ id, title, artist }` (or a plain id string); BoomboxService pre-fills audioMetadataCache from them. Categories (2026-10-11, user's design): tabs 🏠 หน้าแรก (home = songs the player added) / 🎵 ทั่วไป (general = `DEFAULT_PLAYLIST`) / 🎧 Remix (`REMIX_PLAYLIST`, 26 songs added 2026-10-11 with the user's own titles and no artist; all uploaded by DistrokidOfficial; 4 titles differ from the Roblox file names, noted in the config comments). One server list per player, category derived from the id (`presetCategory`); next/shuffle/auto-advance play only the category SELECTED in the panel (user corrected my first version, which followed the playing song's category) — client sends `playlistCategory`, server keeps `selectedCategory[player]`, empty category = no change + message; the 20-song cap counts only player-added songs. Stars: ☆/★ on game songs (`playlistStar`), starred songs also show in Home, saved in DataStore `BoomboxStars_v1` (list of ids; save verified, and reload on a new session seen 2026-10-11 with the user's own two stars); shuffle on an empty Home = shuffle all categories (next on empty Home just says the category is empty). Row of the playing song shows a ■ stop button (client reads BoomboxSound.Playing + BoomboxCurrentAudioId). Panel is 518 tall (scales down to ~0.59 on a 749x381 phone).
User's rules for DEFAULT_PLAYLIST songs: show name + artist only (no ID), no remove button (server also refuses `playlistRemove` for them); header is just "รายการเพลง" (no x/20). Current defaults: 96447789651909 "ก่อนเคยเป็น (Cover)" / VeLASinG, 95573299499123 "บ่ต้องใส่ใจ (Don't Mind)" / VeLA, 119404019834322 "ยินดีที่ไม่คิดถึง" / VeLA, 113735034666395 "Fly (บิน)" / VeLA, 105000336008351 "ไทม์ แมชชีน (Cover)" / VeLASinG, 116780512392827 "ช่วยตัวเองทุกคืน (Cover)" / VeLASinG (the 7 uploaded by CtrlZ_2; user 2026-10-11: artist is "VeLASinG" for every one of THOSE, even when the file name says "VeLA"; 12 more general songs added later the same day are DistrokidOfficial uploads with the user's titles and no artist — general now has 19) — for each new id the user sends: probe-load in Edit mode, then add with title/artist. Every "playlist" FireClient must go through `sendPlaylist` (a raw-list send lost the names). Studio gotcha: after a start_stop_play call times out, later start calls answer "Start play hasn't finished yet" until the user presses Play/Stop by hand.

## Music Box stow/use buttons (2026-10-08)
Panel row = ONE toggle button (shows "เก็บ" when in use, "ใช้งาน" when stowed; reads attr BoomboxStowed) + ■ หยุด; Enter in the Audio ID box plays that ID. Server BoomboxService actions `stow` (stop + destroy PenguinBoomboxOnBack, attr BoomboxStowed) and `use` (GiveBoombox + play typed id or playlist). Stowed state was session-only until 2026-10-11: now saved in DataStore `BoomboxStow_v1` (key UserId = true while stowed, key removed on use; loaded before the penguin is granted). Save path verified, the rejoin path NOT seen yet (Studio start-play got stuck); not published. The playlist is also in-memory only (lost on rejoin) and BoomboxService already validates added IDs with validatePlayableAudio (permission check), so an ID that fails permission was probably played through the typed-ID "play" path, which does not validate. Backup _Backup_20261008.BoomboxService_before_stowuse. Not published yet.

2026-10-12 bug (user screenshot: empty song list): `playlistGet` sat below the "needs the penguin accessory" guard in BoomboxService, so a player who joined STOWED (state is saved now) got no list in any tab. Moved `playlistGet` above the guard. Any new read-only panel action must go above that guard. Play-tested stowed: 19 rows shown; not published.


---

## booster-seasonal-skins

User 2026-10-11: wants a cute Halloween skin for "หุ่นฟางดวงดี" (x50 booster), shown during the Halloween festival as the "Halloween 2026 patch", and explicitly NOT released yet.

- `LuckConfig.BoosterSkins.Halloween2026`: `Enabled = false` (master switch, flip to true to release), window 2026-10-24 00:00 → end of 2026-11-02 Thai time (stored as UTC via `DateTime.fromUniversalTime`; the dates were my choice, not the user's). Only `Tiers.x50` has a skin; x100 clover is unchanged.
- `LuckConfig.GetActiveBoosterSkin(tierId)` is resolved SERVER side only: BoosterPlacementSystem (placed model + the `ItemPreviewModels.QualityBooster` shop/bag picture, built once at server start), ItemFactory.CreateBoosterTool (held model + effect colour), QualityBoosterVisual (`AuraColor2` attribute = fireflies alternate two colours). No client script changed. Only the look changes; luck, radius, lifetime, price, item name stay.
- Template: `ServerStorage.BoosterTemplates.HalloweenScarecrowTemplate` (single AI mesh, pumpkin head, purple witch hat, ghost on the arm; pivot at base, face = LookVector). Alternative with a toothy grin: `ServerStorage._Backup_20261011.HalloweenScarecrow_alt_grin`.
- Studio preview without enabling: attribute `DevForceBoosterSkin = "Halloween2026"` on ReplicatedStorage before Play (Studio only). The user asked to turn it on in dev (2026-10-11), so the attribute is now SET in the place file; the live game is unaffected (IsStudio check, Enabled still false).
- 2026-10-11 later: user asked to reduce the sparkle around the placed skin → `SparkleRate = 3` on the x50 skin (QualityBoosterVisual uses a ParticleEmitter instead of `Sparkles`, which has no rate). Then asked for an x100 skin: `Tiers.x100` → `BoosterTemplates.HalloweenCloverTemplate` (the same clover character as a little witch: purple hat, bat wings, tiny pumpkin; scaled 1.2), rainbow aura kept, held light purple. Alternative golden pumpkin-king model: `_Backup_20261011.HalloweenGolden_alt_pumpkinking`. The current x100 model is a green CLOVER character, not a scarecrow, so skins should restyle the clover.
- Same day, user on the x100 skin: "turn the effects off, the face looks scary". Template replaced by a new mesh (big sparkly eyes, open smile, no bat wings, scaled 1.4; old one in `_Backup_20261011.HalloweenClover_alt_batwings`) and `NoBodyFx = true` (no Sparkles / rainbow sparkles server side, no Highlight outline / orbiting stars in client `BoosterRainbowFx`; radius firefly ring + light kept). Shortly after, the user said "turn the effects on for now" → `NoBodyFx = false` (code support kept; current state = effects ON, decision still open). Taste note: this user leans toward fewer effects and clearly cute faces (big round eyes, open smile, blush); small dot eyes or carved jack-o'-lantern faces read as scary. Ask for the face explicitly in the mesh prompt.
- SUPERSEDED the same day: the Enabled switch, the date window and the dev attribute moved to `ReplicatedStorage.SeasonConfig` (attribute is now `DevForceSeason`), see [[seasonal-events]]. `LuckConfig.BoosterSkins.Halloween2026` only holds `Tiers`.
- 2026-10-13 (user: the x20 and x100 Halloween skins have the same hat, make them differ): x100 clover KEEPS the purple witch hat (the ghost pet holds a mini of it); `HalloweenScarecrowTemplate` (x50 tier, luck 20) replaced by a new AI mesh with a straw farmer hat + bat (scaled to 7.6 tall). Old one: `_Backup_20261013.HalloweenScarecrow_before_strawhat`. I only saw the new one side-on; front face and in-game look NOT confirmed by me or the user yet. A fresh generate_mesh model arrives with an arbitrary yaw: the face is along the MeshPart's LookVector, set WorldPivot from that.
- Gotcha: `screen_capture` returns an all-white view (only the view cube / topbar drawn), in Edit AND Play, whenever the Studio window is not in front on the user's PC; it works again when they bring Studio forward. Not a tab problem.
- To add another festival: new entry in `BoosterSkins` + a template in BoosterTemplates.
- generate_mesh gotcha: prompt over roughly 300 characters fails with "Character limit exceeded"; a sync call can time out while the model still arrives in workspace (named after the prompt).
- Not tested: a real buy/place through the player's hand (placement was simulated to avoid touching the real account's bag, see [[live-session-overlap]]). Related: [[luck-balance]], [[pumpkin-vine]].


---

## boxing-ring

User request 2026-10-12: cute "สนามมวยนากบัญชา" muay kard-chuek ring; players press to join a match; the loser staggers for 1 minute. User chose: on the beach, real-time punch buttons, no rewards.

Built (Studio only, not published):
- `Workspace.BoxingRing` (178 parts, Atomic) on the south beach, centre (-298, 6, 341), floor y 8. Join stands `CornerRed`/`CornerBlue` (`JoinPrompt`) on the north side, invisible `Walls`, markers `SpawnRed/Blue`, `ExitRed/Blue`, `ScoreAnchor` (server builds the scoreboard BillboardGui at runtime).
- `ReplicatedStorage.BoxingConfig` (all tuning + `ENABLED`), `ServerScriptService.BoxingService` (server-authoritative; phases idle/waiting/countdown/fight/ending; state in `ReplicatedStorage.BoxingState` attributes + `RedChar`/`BlueChar` ObjectValues because the ring may not be streamed in), `StarterPlayerScripts.BoxingClient` (HUD, punch F/click/ButtonX, guard Q/ButtonB, dizzy sway).
- Loser: player attr `BoxingDizzyUntil` (server time), stars billboard tagged `BoxingDizzyStars`, can't rejoin while dizzy; not saved across rejoin.
- Studio test bot: workspace attr `DevBoxingBot = true` (currently SET; Studio-only).

Gotchas:
- This game has NO `PlayerScripts.PlayerModule` to require. The dizzy sway reads `Humanoid.MoveDirection` in a RenderStep at `Input + 10` and calls `Humanoid:Move(rotated * DIZZY_SPEED)` (guards against re-reading its own output with `lastOut`/`lastRaw`). Fixed and tested 2026-10-12 (keyboard): speed 16 -> 8.8 with `DIZZY_SPEED = 0.55`, direction swings about +-70 deg.
- Dizzy stars sit at world offset 1.4 above the head (user asked to lift them off the head); the name tag starts at 1.9, so keep them under that.
- Triggering a ProximityPrompt in tests: stand next to it and send a held `E` with user_keyboard_input.
- After a parallel start/stop mix-up Studio stayed in Play and MCP stop did nothing; the user had to press Stop.

Not tested: 2 real players, mobile, gamepad, guard, draw/time-out, punch/guard animation by eye. Related: [[boat-seats]], [[streaming-atomic-models]], [[i18n-thai-english]].

2026-10-12 later: user reported the punch button overlapping the sprint button (`SprintGui.SprintButton`, bottom-right: PC centre (1,-52, 1,-110) 62 px; mobile above the jump button). BoxingClient `layout()` now anchors punch/guard to the LEFT of the real sprint button, bottoms aligned. Verified on a 1334x449 PC viewport; not on a phone. Any new bottom-right button must check SprintGui too.

2026-10-12 later: the user MOVED `Workspace.BoxingRing` away from the south beach to about (52, 4, -477) (canvas position). The service reads positions from the model's own parts at server start, so it still works; don't assume the old (-298, 6, 341) spot. The south beach spot is now covered by hidden plot FarmPlot58.

2026-10-13 stats + board (user: "ตอนชกมวยชนะบันทึกสถิติ และเพิ่มบอร์ดรายชื่อ ชกกี่ครั้ง ชนะกี่ครั้ง แพ้กี่ครั้ง เอาผู้ชนะมากที่สุด บอร์ดอยู่ตรงสนามมวย"):
- `ServerScriptService.BoxingStats` (ModuleScript): OrderedDataStore `BoxingRecord_v1`, one value per user = wins×1e8 + (9999−losses)×1e4 + draws (sorted by wins, then fewer losses). `Record(userIdA, userIdB, winner 1/2/0)` (nil id = skip that side), `GetTop(n)`, `Decode/Encode`, shared BindableEvent instance `ServerScriptService.BoxingStatsChanged`.
- BoxingService: fighters carry `userId`; `finish()` records both corners (KO, time, draw, forfeit). Bot fights are not recorded unless Studio + workspace attr `DevBoxingRecordBot = true` (removed after the test; `DevBoxingBot` is still set).
- `workspace.BoxingRing.StatsBoard` (inside the ring model so it moves with it; cream/pink-red recolour of the LevelBoard shell) + `ServerScriptService.BoxingBoard` (title "🏆 ทำเนียบนักมวย 🏆", rows "🥊 fights ✅ wins ❌ losses", refresh 60 s and 2 s after a recorded fight). Draws are stored and counted in fights but not shown separately.
- Tested in Play: simulated records and one REAL bot fight (join with a held E via user_keyboard_input while standing 3 studs outside CornerRed, then fire BoxingAction "punch" from the client facing the bot) → auto-recorded, board updated; test records removed with RemoveAsync both times. `ProximityPrompt:InputHoldBegin()` from execute_luau did NOT trigger the join. Not tested with 2 real players. Adding the board changed the ring's bounding-box centre — use the pivot/Canvas, not the bbox, for ring maths. See also [[level-board]].
- 2026-10-13: topper `BoxingRing.StatsBoard.ChampionOtter` (user: otter wearing a champion belt, arms raised like a winner): AI mesh (async generate_mesh; wait_job_finished timed out but the model appeared at the workspace root), scaled 1.2, on the HeaderBar. NOT verified by eye — edit-mode screen_capture returned a white view (Studio viewport on another tab); its facing was set by the same rule as the LevelBoard otter (mesh front opposite the pivot LookVector). Ask the user to confirm look + facing; flip 180° if it shows its back.
- 2026-10-13: the user looked at ChampionOtter and replied "ได้แล้ว" (accepted; look and facing OK as placed).


---

## carry-system

User 2026-10-03: "ตอนคลิกที่เพื่อน เพิ่มเมนู แบก พอกดมีท่าแบกให้เลือก และกดเลือกก็จะแบกตามท่าที่แบก". I added a consent step myself (anti-grief): the friend must press ยอมรับ.

- `ReplicatedStorage.CarryConfig`: RANGE 15 studs, REQUEST_TIMEOUT 15 s, ASK_COOLDOWN 3 s. Styles: piggyback 🎒 แบกหลัง (Up 0.35, Back 1.0), shoulders 🦒 ขี่คอ (Up 1.7, Back 0.35 — the sit pose drops the body ~0.8 so it must sit above the head), princess 👸 อุ้มเจ้าหญิง (Up 0.4, Back −1.3, Yaw 90, Tilt 60). Up/Back are multiples of the carrier's root→head height (scales with avatar size). Arms = carrier joint angles (deg) per style. Offset() builds the CFrame. Tuned visually in Studio with a dummy.
- `ServerScriptService.CarryService`: RemoteEvents CarryRequest ("ask", targetUserId, styleId) / ("answer", fromUserId, bool) / ("release") and CarryPrompt (server→target: fromPlayer, styleId, timeout / "closed"). Attach = Weld (Part0 carrier HRP, C0 = offset) + every rider BasePart Massless/CanCollide false/CanTouch false/CollisionGroup "CarryRider" (collides with nothing), rider Humanoid.PlatformStand forced true; seat welds broken first. Release restores the saved part props, PivotTo 3 studs right of the carrier, SetNetworkOwner(rider). Auto-release on death / CharacterRemoving / PlayerRemoving / weld removed. Attributes: carrier CarryingUserId + CarryStyle, rider CarriedBy + CarryStyle. Notices via HarvestNotify.
- `StarterPlayerScripts.CarryClient`: request card top-centre (ขอแบกคุณ / ท่า…, countdown, ยอมรับ / ไม่เอา, gamepad selects ยอมรับ), bottom pill (carrier: "กำลังแบก X (ท่า) · แตะเพื่อปล่อยลง", rider: "X กำลังแบกคุณ (ท่า) · แตะหรือกระโดดเพื่อลง"), JumpRequest = get down, rider plays Animate.sit (Action4, looped) on itself and stops any emote (EmoteGui.StopSync). Carrier arm pose: every client sets joint .Transform in RunService.PreSimulation for every player with CarryingUserId.
- GOTCHA: this game's characters use the new physics rig — shoulder/elbow joints are **AnimationConstraint**, not Motor6D (RightUpperArm.RightShoulder). Code that looks for Motor6D finds nothing. Transform still works.
- `PlayerClickMenu`: "🤲 แบก ▼" button expands the 3 styles (→ "ask"); "⬇️ ปล่อยลง" when you carry that player; greyed "(เพื่อนไม่ว่าง)" / "(ปล่อย/ลงก่อน)" when busy. WarpService refuses while CarriedBy (carrier can warp, rider follows). EmoteGui refuses emotes while carried.
- Studio hooks: player attr `DevCarryDummy` = styleId (server clones your character as a dummy and you carry it; "" releases and destroys it), `DevCarryPrompt` = styleId shows the request card. execute_luau cannot require ModuleScripts or fire Remotes/Bindables (capability error) — tune via the weld C0 directly.
- Verified in Studio: all 3 styles positions/screenshots, carrier walking + jumping keeps the rider, release clears everything, menu + style list, request card. NOT verified: two real players (consent flow, ownership/physics on a live server, rider jump-to-get-down, release placement, phone). Needs Publish.
- 2026-10-03 later (user screenshot): bottom pill → transparent background, white bold text with dark TextStroke, no border (same style as notifications); the "🔗 ทำท่าตาม" pill in EmoteGui got the same style. User: "ในวง() ไม่ต้องเอาแล้ว ยาวไป" → pills are now "🎒 X กำลังแบกคุณ · แตะหรือกระโดดเพื่อลง" / "🎒 กำลังแบก X · แตะเพื่อปล่อยลง" and the ask notice "🎒 ขอแบก X แล้ว รอเพื่อนกดยอมรับ" (no style name in parentheses; the style shows only as the icon). Keep these texts short.
- The place was renamed "[BETA] พักผ่อนหย่อนฟาร์ม" (same placeId); Studio id changes often (1aa2bdb0-… on 2026-10-03).
- Studio crashed/reconnected once during this work (studio id changed to 2353092b-…); nothing was lost.
- MULTI-CARRY (2026-10-03, user: "แบกเพื่อนได้หลายคน"): `CarryConfig.MAX_RIDERS = 10` (user asked for 10 right after; was 3; with 10 dummies the towers are piggyback ~13 studs, shoulders ~19, princess ~10 high, all attach/release cleanly); each style has `Stack = {Up, Back}` (extra Up/Back per additional rider, ×head height) and `Offset(style, headHeight, index)`. Server: `carrierLinks[carrier] = {link,…}` (ordered), `layoutCarrier()` re-indexes + re-sets weld C0 + sets attrs CarryingUserId (= first rider), CarryStyle, CarryCount whenever someone joins/leaves. Rider 2+ always uses the style of rider 1 (carrier arm pose is one). Carrier can keep asking (button "🤲 แบกเพิ่ม", client sends ("ask", target, own CarryStyle)); "release" with a userId drops just that rider, without one drops all (carrier pill tap = all; clicking a carried friend → ⬇️ ปล่อยลง = only that one); released riders are placed alternating right/left of the carrier. Pill: "กำลังแบกเพื่อน N คน · แตะเพื่อปล่อยทั้งหมด". Studio hook: `DevCarryDummy = "piggyback:3"` carries 3 dummies. Verified with dummies: stacked welds (0,0.5,1.0)(0,1.9,1.2)(0,3.3,1.4), one dies → re-layout to 2, release all clears, screenshot of 3-high tower OK. NOT checked: shoulders/princess stacks visually, real players. Backups `_Backup_20261003.<CarryService|CarryConfig|CarryClient|PlayerClickMenu>_before_multicarry`. Needs Publish.
- Related: [[emote-system]] (PlayerClickMenu is shared).

2026-10-20: riding + carrying allowed (user request). CarryService.attach only dismounts the carried friend (not the carrier); MountService.ride blocks only CarriedBy (not CarryingUserId). Tested with DevCarryDummy on WildHorse both orders (piggyback, princess); flying mounts / shoulders style / 2 real players untested. Not published.


---

## cheat-watch

Built 2026-10-11 after the user asked "ดักเรื่องเลเวล" (Studio only, not published at creation).

- `ServerScriptService.CheatWatch` (ModuleScript): `Flag(player, kind, detail)` → DataStore `CheatFlags_v1` (`u<userId>` last 20 flags, `recent` last 30 names; Studio keys prefixed `studio:`), MessagingService topic `CheatFlag` toasts the owner on any server, 30-min cooldown per player+kind. Owner commands `/flags` and `/flags <name|UserId>`. Never bans/kicks by itself — the owner decides and uses `/ban` ([[ban-system]]).
- `LevelSystem.AddXP`: cap per 10 min = PlantLimit × 6000 + 20000 (50 XP/harvest, fastest grow cycle ~5 s); over the cap = XP dropped + flag `xp_rate`. Autosave loop flags `xp_lifetime` when total XP / PlaytimeTotal minutes > 4000 (was 3000; raised 2026-10-28 because 24/7 AFK player 0xoARESox0 averaged ~3,140 and was re-flagged every 30 min — not a cheater, Studio only) (level ≥ 50, ≥ 10 min). Reference numbers: owner ~640 XP/min lifetime; cheaters 13.5k–73k XP/min. Studio test switch: attribute `DevXpLimit` on ServerScriptService.
- Tested only through a separate module copy (cap + flag record). Not tested: real harvest hitting the cap, lifetime check, `/flags`, cross-server toast.
- Added same day: `watchCoins` inside CheatWatch (positive coin deltas after `CoinsLoaded`, > 3M in 10 min → flag `coin_rate`, tested); GachaService flags `gacha_coin_tickets` (≥ 150 coin-bought tickets per server session) and `gacha_secret` (≥ 2 Secret results per session) — both flag-only and NOT tested (would spend the owner's real tickets/coins). Admins are never flagged outside Studio.
- New hooks should call `CheatWatch.Flag`. All thresholds are my own picks, not user-confirmed.

Gacha audit 2026-10-11 (user reported "someone hacked the gacha, gets only the showcase pet"): code reading found no way to choose the result (rolls, tickets, pity, shard exchange, pet equip all server-checked). Likely path = cheated coins → unlimited 20k-coin Normal tickets → Secret pity every 200 rolls (4M coins per NineTailFox), announced cross-server. A daily cap on coin-bought tickets was offered, user has not decided. See [[pet-gacha-plan]].

Tool gotcha: `execute_luau` output that cuts Thai text mid-character (`string.sub` on script lines) makes the call time out — return whole lines.

2026-10-12 — confirmed live: the user published CheatWatch (real `recent` had 8 flags that day: Ponggin4, PeaUzi01, 0xoARESox0, 1427JT — coin_rate / gacha flags, no xp flags). Same day added (Studio only, not published at creation):
- Temporary suspension, OWNER-TRIGGERED ONLY (user chose "ฉันกดระงับเอง", no auto-suspend) and "cannot enter the game": keys `s<userId>` + index `suspended` in CheatFlags_v1; join/live → frozen + full-screen notice ("ตรวจพบการเล่นที่ผิดปกติ … รอการตรวจจากทีมผู้พัฒนา 3-7 วัน") + kick after 15 s; MessagingService `CheatSuspend`. Commands `/suspend` `/unsuspend`; `/flags` now opens an admin window instead of toasts (user: toasts were hard to read and vanished).
- `StarterPlayerScripts.CheatWatchGui`: suspension notice + admin window (suspended list, recent flags, history per player, suspend/unsuspend with double-click confirm). Remotes `CheatAdminRequest` / `CheatAdminOpen`. Studio test switch: workspace attr `DevSuspendTest` (lets the owner be suspended).
- Tested: admin list, suspend → notice → kick. Not tested: rejoin while suspended, unsuspend, history view, chat commands, cross-server.


---

## chicken-farm-plan

2026-10-20 the user asked to plan a chicken system (buy coop → buy chicken → feed → eggs → sell) and wants it to be END GAME. User said "เก็บไว้ก่อน" (park it) and moved to farming end game ([[farming-endgame-plan]]). Nothing built.

User's 2 options: (1) one coop per player (30 coops), (2) one shared chicken house, each player sees only their own chickens.
My recommendation: option 2 + a public "show yard" (Legendary+/one showcase chicken per player visible to all) + leaderboard. Reason: perf budget ([[planting-click-and-perf]]), one map spot; client renders own chickens, server owns data, os.time offline eggs, server validates everything ([[cheat-watch]]).

End-game ideas proposed: genes + breeding + mutations (core), feed made from crops/fish (keeps farming/fishing useful), egg uses (hatch, golden-egg bait, beach-bar recipes), chicken book like fish book, coop upgrades (slots, incubator, cleanliness), Robux auto-feed/collect + gift like [[pet-auto-feed-plan]], weekly chicken contest, retire → hall of fame permanent buff. Eggs = mid income only, value in rarity.

Partner-facing plan doc (Thai, plain language): https://claude.ai/code/artifact/36d5319f-0b9a-4ba5-98fc-0c0d737090ef — has breeding/mutation details section.

DECIDED 2026-10-20: option 2 + show yard; basic unlock Lv 2, breeding Lv 20; build breeding + mutations.
Proposed numbers (in doc, awaiting OK): 3 abilities 1–5 stars (fast eggs / big eggs / golden eggs) + coat colour; child takes each from a random parent, then +1 star 20% / −1 star 10%; new colour 3% (gold 1%); hatch 30 min, chick grows 1 h, parent rest 2 h; mutations glow 3% x1.5, fire 1% x2, crystal 0.5% x3, rainbow 0.1% x5, seasonal 2% x2; inherit 25% (both parents same 50%); premium feed x1.5 mutation chance; pity glow at 50 breeds; scarecrow/pet luck does NOT apply.

2026-10-20 user OK'd the numbers. Technical phase-1 plan written to `CHICKEN_FARM.md` in the project (scripts, `ChickenFarm_v1` schema, settle logic, save order, tests). Coop model already placed by another session at `workspace.FarmProps.ChickenCoop` (102, 4.8, 131) next to the hay cart; template at `ServerStorage.ChickenCoop`.

2026-10-20 PHASE 1 BUILT in Studio (not published): ChickenConfig, ChickenFarm.ChickenData/ChickenService, ChickenGui, ChickenYardClient, ChickenTemplates.Chicken, FarmProps.ChickenYard (fence + CoopPrompt). Feed = pet-food bags, eggs in coop basket. Prices: chicken 300, slot 4 = 2,000 ×1.6 each, egg 8–45 by food star × size mult, gold egg 500. Settle logic unit-tested in Edit. Play test was aborted because the user was live (AFK) on the same account — UI/buy/sell/walking chickens NOT play-tested yet.

2026-10-20 later: PLAY-TESTED OK (buy/slot/deposit/eggs/sell/save-fail rollback/rejoin persistence/offline eggs/walking avoids coop). Studio bag already uses DevInventoryKeyOverride = InvTest_20261015a (fake), so pet-food used in tests is not the real bag; coins ARE real. Not yet tried: phone screen, gamepad, 2 players. MCP start_stop_play sometimes hangs ("Start play hasn't finished yet"); a Play the user starts by hand is not visible to MCP.

2026-10-20 UI split into map spots (merchant NPC mesh stall, trough, egg basket, coop, incubator) and PHASE 3 breeding/mutations BUILT (MakeChild, incubator, chicks, mutation FX) — PLAY-TESTED OK 2026-10-20 (breed/hatch/chick grow/odds 200k rolls/mutation FX via fake client sync). Edit-mode require caches old modules: test with a temp copy whose require points to a cloned config. Mutation visuals not eyeballed (Studio viewport went white). PHASE 4 BUILT + play-tested 2026-10-20: ChickenLooks module, book 25 entries + rewards, ShowYard (8 pedestals, server models) + ChickenBoard (OrderedDataStore ChickenFarmRank_v1, not written in Studio with the dev key). Chickens are chibi AI meshes now (ChickenLooks: White = original texture, others plain colour). PHASE 5 BUILT + play-tested 2026-10-20: coin upgrades (hatch/basket/trough), auto-feed + auto-sell Game Passes and instant-hatch product — IDs still 0 in ChickenConfig (proposed 199/149/25 R$), Studio test switch workspace DevChickenPasses. The whole yard was moved (coop now ~(60,147)) by someone outside this session — code reads positions from map parts so it still works. Remaining: phase 6 (weekly contest + hall of fame). Nothing published yet.

2026-10-21: (later the same day RE-ENABLED, Enabled = true) HIDDEN for the next patch — ChickenConfig.Enabled = false → ChickenService moves FarmProps.ChickenYard + ChickenCoop to ServerStorage.ChickenFarmHidden at runtime, skips data load/save; ShowYard/Board scripts return early. Re-enable = Enabled true. Later changes that day: max 10 slots (start 3, 2,000×1.6 prices), egg prices ~3× (25/40/60/90/140, gold 1,500), egg tray = coin upgrade, auto-sell disabled (AUTO_SELL_ENABLED false), auto-feed pass 2039699230 = 180 R$, instant hatch product 3720361557 = 23 R$, FootOffset fixed to 0.615.

2026-10-21 CARRY CHICKENS built (not play-tested, user was live): prompt "อุ้มไก่" (F / gamepad Y) on own birds → ChickenService action pickup/putdown makes a Tool IsHeldChicken (ChickenId, ChickenLook = color, Mut; model "HeldChicken" welded to Handle, Grip guessed — may need tuning); carrying[player] not saved, CarriedId in snapshot hides that bird; preview models ItemPreviewModels.HeldChicken_<Color>.

2026-10-22 later: RE-ENABLED (Enabled = true); contest board ChickenContestBoard (x 92, z 117, script ChickenFarm.ChickenContestBoard) + tutorial bonus step 12 added, announcements per language. Earlier: 2026-10-22 HIDDEN AGAIN by the user (ChickenConfig.Enabled = false) right after phase 6 was built. 2026-10-22 PHASE 6 BUILT (not play-tested, Studio kept disconnecting): weekly contest (week = Mon 00:00 Thai, 5 rotating themes, OrderedDataStore ChickenContest_v1_w<week>, Studio uses ChickenContestDev_v1_w…, claim next week: #1 5 premium tickets+100k, #2-3 3+50k, #4-10 1+20k, entrants 5k) + Hall of Fame (retire 5/5/5 adult, +2% egg price each, max 10). Mutation FX now = PetFireflyRing via CollectionService tag "FireflyRing" (ChickenLooks.setRing). Studio often times out while a Play session is running — stop Play before editing.

2026-10-22 evening: HIDDEN AGAIN by the user (ChickenConfig.Enabled = false), after the timing fixes. 2026-10-23: RE-ENABLED (Enabled = true) by the user.

2026-10-23 SAVE SPACING: Roblox allows 1 write per key per 6 s. ChickenData.CanWriteNow/SaveLater/SaveNow (gap 6.5 s); ChickenService.commit saves first only when the gap is open, otherwise applies + coalesces into one later save. strict = commit(..., true) for book/contest claims; strictSave[player] set inside grantLocked (Robux grants, gift delivery) → always real save first. Harness-tested with a fake store, not Play-tested. Trade-off: hard crash within ~6 s after fast taps can lose those taps.

2026-10-23 COOP CLEANING built (user picked gentle + free hold-E): data.dirt/dirtAt, grows only while laying (24 h to 100%), >50% stretches egg time up to x1.5; action "clean" at workspace.FarmProps.ChickenYard.CleanBroom.CleanAnchor.CleanPrompt (hold 3 s, client hides it <5% and sets text), 5 coins per 1%; client dirt piles in workspace.MyCoopDirt; "CoopDirt" card first in My chickens. Logic-tested in Edit, not Play-tested, visuals not eyeballed.

2026-10-23 GIFTS built (not published, not Play/purchase-tested; logic harness-tested in Edit): 🤖 auto-feed gift (sets data.giftFeed = permanent, counts like the pass; player attr ChickenAutoFeed) + ⚡ instant-hatch coupon gift (+1 hatchTokens, stackable). Inside ChickenService (MountGift-style inbox, DataStore ChickenGift_v1, action "giftSelect" {kind, userId} bypasses buyer checks), VipGui kinds chickenfeed/chickenhatch + BindableEvent OpenChickenGift(which), ChickenGui shop cards 8/9. Product IDs set 2026-10-23: AUTO_FEED_GIFT_PRODUCT_ID = 3721246128 (R$ 199), INSTANT_HATCH_GIFT_PRODUCT_ID = 3721246800 (R$ 29, Dashboard name has a typo "ของวัญ"). Studio now opens the real prompt unless player attr DevGiftSimulate.

2026-10-22 audit + timing fixes in ChickenService (not Play-tested, logic-tested with a harness in Edit): Robux grants go through `grantLocked` (shares the `busy` lock); coin-drop-after-save uses `undoPaid(before)` + immediate save (`commit` now returns true, nil, before). Backup `_Backup_20261022.ChickenService_before_timingfix`. Audit notes left open: gold eggs ignore size/mutation mult; contest entry is a snapshot (sold chicken still ranks).

**How to apply (old note, done):** Play-test after the user leaves the live game (check DisconnectLogs_v1 "u9360333174" for an active non-Studio session first, see [[live-session-overlap]]); DevChickenKeyOverride is set so chicken data uses a fake key, but coins/bag still belong to the real account. Then phase 2 is already covered by pet-food bags → phase 3 breeding next. Robux prices still open.


---

## coin-trade

User 2026-10-08: click a friend → "เทรดเงิน" with a number-entry UI; max 200,000 per day, sender pays 3% tax (send 100 = pay 103).

- `ReplicatedStorage.CoinTradeConfig`: DAILY_LIMIT 200000 (per sender, amount only, tax not counted), TAX_PERCENT 3 (ceil, integer math; tax is burned), day = midnight Thai time (UTC+7), helpers Tax/Total/DayKey/MaxAffordable/Format.
- `ServerScriptService.CoinTradeService`: RemoteFunctions `CoinTrade(targetUserId, amount)` and `CoinTradeInfo()`. Checks both CoinsLoaded, balance, 1.5 s gap, then reserves quota in DataStore `CoinTradeDaily_v1` {day, sent, log[≤50]} via UpdateAsync, re-checks, moves coins (`leaderstats.เหรียญ`), refunds quota if it fails, notifies both via HarvestNotify, fires `LeaderstatsSetup.SaveCoinsNow` (BindableEvent added for this) for both.
- `StarterPlayerScripts.CoinTradeGui` (BindableEvent `CoinTradeGui.Open`, fired by the 💰 button in PlayerClickMenu). Emoji 🪙 renders as a box in Roblox — use 💰.
- Studio test: player attrs `DevTradeSelf = true` + `DevOpenPlayerMenu = true` → trade with yourself. Tested 100 → −103/+100 OK; test coins and record restored.
- NOT tested: two real players, phone, gamepad. No anti-alt protection (receiver limit / account age) — offer if abuse appears. Needs Publish.

2026-10-13 (user: "เพิ่มสิทธิของสุลต่าน ตอนเลเวล 300 จะสามารถเทรดเงินสูงสุด 1000000 และเพิ่มในรายละเอียดทุกที่"): `CoinTradeConfig.SULTAN_DAILY_LIMIT = 1000000`, `SULTAN_LEVEL = 300`, `LimitFor(isSultan, level)`; CoinTradeService `limitOf(sender)` (IsSultan attr + leaderstats เลเวล, only when LevelDataLoaded). I read "สูงสุด 1,000,000" as the DAILY limit (same tax 3%). Shown in SultanShopGui (Localization `Sultan_Perk10_*`), QuickShop SultanCard text, and a hint line in CoinTradeGui. Compiled only — not play-tested (a live session of the owner's account was running). The Game Pass description on the Roblox page is the user's to edit. See [[sultan-pack]].


---

## community-reward

User 2026-10-15: "เพิ่มปุ่มเข้าร่วมชุมชน ถ้าเข้าแล้วจะได้รางวัลตั๋วพรีเมียม 5 ตั๋ว".
- The game is owned by group 642396060 "Chilling At Farm" (game.CreatorType = Group); that is the community.
- Server `ServerScriptService.CommunityReward`: RemoteFunction RemoteEvents.CommunityReward ("claim"); membership checked fresh (IsInGroupAsync → GroupService:GetGroupsAsync; Player:IsInGroup is cached at join, so don't use it); DataStore `CommunityReward_v1` key UserId (`studio_` prefix in Studio) reserve-then-grant via GachaTickets.Add(…, "Premium", 5, "community_<token>"), release on failure; attr `CommunityRewardClaimed`.
- Client `StarterPlayerScripts.CommunityRewardGui`: 👥 round button in TopbarRow (LayoutOrder 3) with a bouncing "💎5" badge, hidden once claimed; GroupService:PromptJoinAsync then claim; own toast under the top bar.
- Tested with the owner account (already a member): claim + second-claim refusal + button visibility. Test tickets reverted (snapshot StringValue `_Backup_20261015.GachaTickets_owner_before_communitytest`). Not tested: a non-member joining through the real prompt, phone layout.
- Server messages are Thai only.
- 2026-10-15: its toast was a cream box → user asked for a transparent background; now white text + dark stroke (TextStrokeTransparency 0.2, size 20) like HarvestNotifyGui. **Rule (since 2026-10-02): every notification/toast in this game has NO background box** — any new toast must follow HarvestNotifyGui's style or use HarvestNotify.


---

## compensation-system

Built 2026-10-10 after the restart/throttle problems. One claim per account per `Id`.
- Config: ReplicatedStorage.CompensationConfig (Enabled, Id, StartsAt/EndsAt unix, Coins, Boosters {Tier, Amount}, Title/Message TH+EN). New round = new Id + window + rewards, then Publish.
- Server: ServerScriptService.CompensationService, DataStore `CompensationClaims_v1` key "<Id>:<userId>" (Studio prefixes "studio:"); a record counts as claimed only if it has `token` ({released} = grant failed, can claim again). Studio switch `workspace.DevCompensationForce`.
- Client: StarterPlayerScripts.CompensationGui (announcement style with the otter head), shows after LoginAnnouncementGui closes.
- "หุ่นทองคำนำโชค" in this game = booster tier **x100**; x50 is "หุ่นฟางดวงดี". The user once wrote "หุ่นทองคำนำโชค x50" and meant the golden x100 one — ask when names and tiers conflict.

**Status 2026-10-10:** Enabled = false (user: not compensating yet); when enabling, also move StartsAt/EndsAt.

**Review 2026-10-13 (code read only; Studio Play would not start, so the claim is STILL untested end to end):** Enabled = false, window ended 2026-10-13 00:00 Thai, `CompensationClaims_v1` has 0 keys (nobody ever claimed, not even in Studio). Dependencies exist (SaveCoinsNow, SaveInventoryNow, ItemFactory.GiveBoosterTool(player, amount, tier), Localization keys). Weak points found, not fixed: (1) `InventoryLoaded` attr is set even when the bag load failed, so under DataStore throttling the booster can be given, not saved, and lost if the player leaves before the background load, while the claim is used up; (2) players already in a server when the window opens have `claimed = nil` and cannot claim until they rejoin (set StartsAt ≤ publish time); (3) closing with X = window only returns on next join; (4) EndsAt is sent to the client but not shown.

**Fixed + tested 2026-10-13 (not published):** weak point (1) — InventorySystem now sets player attr `InventoryReady = true` only on a successful DataStore read; CompensationService.waitReady waits for it. First real claim test passed in Studio (claim from the client remote: +10,000 coins, 1 golden scarecrow, record written, second claim "already", refused when `ServerScriptService.DevFailInventoryLoad = 12`); test rewards and key removed. Same `InventoryLoaded` hole still exists in StarterGift, LuckBoosterGift, AdminGive (not fixed). Gotcha: `Source:match("Enabled = ...")` hits the header comment first — check line 7.

**Round 2 set up 2026-10-13 (Enabled = TRUE in Studio, not published):** Id `comp-20261013`, 500,000 coins + 1 golden scarecrow (x100) + 5 Premium gacha tickets, window 2026-10-13 00:00 → 2026-10-15 00:00 Thai. Service now supports `Config.Tickets = { { Type = "Premium"|"Normal", Amount } }` via GachaTickets.Add with reference `comp_<Id>_<i>` (Studio prefixes `studio_<token>_`). Claim tested in Studio and fully reverted. The user called the golden scarecrow "โทเท็มดวงดี" this time (asked, confirmed x100). After the window: set Enabled = false. Studio test gotcha: the owner's ticket receipts list is full (50), so a test Add pushes out the oldest receipt — snapshot `GachaTickets_v1` before and restore.

**Why:** the user wanted to compensate players for the 2026-10-09 restart issues.
**How to apply:** reuse this for future compensation; not play-tested yet at creation. Related: [[restart-notice]], [[luck-balance]].


---

## craft-bench

User choices (2026-10-08):
- placed on the sand between the fishing shop and the dock
- otter smith: yes
- colour: pink
- prompt opens a "เร็วๆ นี้" window
- name: "โต๊ะช่างนากน้อย"

Built (Studio):
- workspace.OtterCraftBench (Persistent, base (-410,6,26), faces the fishishop warp point)
  - folders: Table, Pegboard, Awning, Sign (FishBody.SignGui.Title), Props, OtterSmith (Otter x2 on a pink Stool + goggles/apron/hammer), PromptPart
- ServerScriptService.CraftBench: prompt → RemoteEvent CraftBenchOpen
- StarterPlayerScripts.CraftBenchGui: window, EN sign text, otter bob + hammer tap on the client
- PromptLocalizer: EN entries

Phase 2 plan, not started:
- materials: fish by rarity, junk (now drops on every rod), coins
- craft-only rods
- rod upgrades +1..+5 (luck/range/bite speed), level saved per account (probably FishingShop_v1)
- 2-tab window: สร้างเบ็ด / อัพเกรด
- everything decided on the server

Related: [[fishing-plan]], [[sunbee-rod]].

Phase 2 decisions (user, 2026-10-08) — PLAN ONLY, user said "อย่าพึ่งทำ":
- 3 craftable rods: (1) เบ็ดรักโลก (player rod) = NightMoth tier table 52/34/12/2 but Luck 4, CastDistance 25, bites 45% faster (BiteTime avg 5.5 vs Bamboo 10 → {3.5,7.5}), HookWindow 2.6, ZoneBonus 0.09; (2)+(3) two "เบ็ดของน้องนาก" rods for the fishing pet (I proposed designs).
- Upgrades +1..+5: postponed. Robux rods: no crafting/upgrade for now. Phase 2 launches together with fish v2 (FISH_V2).
- Pet fishing today: FishingSystem helper uses the owner's rod Luck/RodId, PET_BITE_TIME {20,35} / pet speed, mini Rod_Bamboo in the pet's hand (attachPetRod). Junk base chance JUNK.Chance 0.12.
- User 2026-10-08 answers: pet rods named เบ็ดหอยน้อย 🐚 (pet bites 25% faster, pet luck +1, hunger −20% while fishing) and เบ็ดดาวทะเล ⭐ (40% faster, luck +2, pet catches always ★2+, 10% double catch) — approved; recipes must be HARDER (proposed ~2x: EarthLove ~11 h junk grind + 4 diamond/6 ruby + 200k; Shell ~2x commons + 100k; Starfish legendaries x4 each + 3 any-secret + 8 diamond/12 ruby + 500k); Starfish does NOT require Shell. Owned pet rods: best one used automatically. Still waiting for the user's go before building.
- 2026-10-09 step 2 DONE (Studio): CraftConfig (recipes/PetRods/ENABLED=FISH_V2), FishingConfig.Rods.EarthLove (Craft=true, OnSale=false), templates Rod_EarthLove/PetRod_Shell/PetRod_Starfish in FishingTemplates, CraftBench server (CraftBenchRequest, CraftBench_v1 store, attr PetRodBest, DevCraftSimulate true/"deduct"), InventorySystem.SaveInventoryNow, CraftBenchGui craft window (CraftBenchCraftGui). Tested OK. NEXT = step 3: FishingSystem helper must use PetRodBest (BiteMult/Luck/HungerMult/MinStar/DoubleChance) + show the pet rod model instead of mini Rod_Bamboo.
- Testing gotcha: with DevFishV2 on, the user's real pet catches new fish into the real account (+FirstCatch bonus) — remove items/bonus afterwards, or disable the pet's Fisher ability during tests.
- 2026-10-09 step 3 code DONE (FishingSystem petRodOf/attachPetRod swap/BiteMult/Luck/MinStar/DoubleChance, PetManager onHelp(mult), FishingClient x2). User changed: Starfish REQUIRES Shell (CraftConfig Requires = "PetShell", server rejects, GUI "🔒 ต้องมี🐚"). Test switch workspace.DevCraftOn (Studio only). Live verification of the otter holding the new rod still pending (Play hung).
- 2026-10-10 REDESIGN (user): pet rods are separate, player chooses. Shell = luck x2, hunger -20%, x2 fish always (DiamondShard 5 + Scallop 50 + Straw 50 + 500k). Starfish = luck x2, hunger -20%, 50% faster (RubyShard 5 + SeaUrchin 50 + Straw 50 + 500k). No Requires. Both let the otter reach Secret (CraftConfig.PET_TIER_WEIGHTS when owner's rod has no Secret). Need full fish book (FishIndex.GetProgress). Unequipped owned pet rods are Tools in the bag (IsPetRod, recreated by CraftBench; not saved by InventorySystem); bag "ใช้" → equipPetRod; pet menu ability tab has the otter rod slot (PetRodSlot) with "ถอดเบ็ดเข้ากระเป๋า". CraftBench_v1 { petRods, equipped }. Tested in Play with simulate mode.

**2026-10-10 otter-rod additions (Studio only, not published):** pet-menu rod slot is clickable → inline picker of otter rods in the bag (`PetHelperToggleButton.addPetRodSlot`). Otter's held rod + bobber now swap immediately on equip (`FishingSystem.refreshHelperRod` / `makePetBobber`). Per-rod bobber via `CraftConfig.PetRods[id].Bobber`: Shell = `Bobber_PetShell` (round red clam), Starfish = `Bobber_PetPuffer` (red pufferfish). Gotcha: `castHelper` calls `ScaleTo(0.8)` absolutely, so to resize a bobber template re-parent its parts into a fresh Model after scaling.

2026-10-14 (user: "ตอนคราฟเบ็ดอยากให้ไม่ต้องติดดาวก็คราฟได้กันผู้เล่นเผลอไปขาย" — I read it as: starred materials should be usable without un-starring): CraftBench `fishStacks` now includes ⭐ starred stacks; `takeMaterial` uses unstarred stacks first, then starred, lowest star first; refund re-stars a stack that was fully consumed. Selling / pet food / bait still skip starred stacks (see [[star-lock]]). Risk to remember: a starred high-star Scallop/SeaUrchin can now be consumed by a pet-rod recipe if the unstarred ones run out. Compiled, not play-tested. Backups `_Backup_20261014.*_before_starredcraft`.

2026-10-16 (user: "คราฟเสร็จก็เปลี่ยนให้เลย"): crafting now auto-equips. Player rod: server returns `rodId`, CraftBenchGui.equipCraftedRod waits ≤8 s for the tool then HotbarState.UseTool (slot 6, holds the new rod if the old one was held). Pet rod: CraftBench.craft calls setEquipped right after grant (fallback = bag + old message). Client path tested with a stubbed OnServerInvoke (account already owns all 3 crafts, so a real craft is refused); server pet-rod auto-equip compiled only. Backups `_Backup_20261016.*_before_autoequip`. Not published.


---

## custom-matchmaking

**Problem (2026-10-22 morning, from DisconnectLogs):** 6 new players each landed in their own EMPTY server and left within 8 s – 6 min. The main server had 6/30 players at the time.

**Setting applied:** The user applied a custom matchmaking config live in Creator Dashboard → การกำหนดค่า → การค้นหาแมตช์แบบกำหนดเอง ("Unnamed Custom Configuration", applied to the root place, enabled for everyone at 22/10/2569 11:06:13). Weights (old → new):

| Signal | Old | New |
|---|---|---|
| Occupancy | 2 | 10 |
| Age | 1 | 1 |
| Language | 2 | 1 |
| Latency | 3 | 2 |
| Friends | 15 | 15 |
| Device | 0 | 0 |
| Voice | 1 | 1 |
| Play history | 2 | 0 |
| Text chat | 3 | 1 |

**Not the fix:** "Social slots" (place → การเข้าถึง) is still Roblox optimized. It only matters when a server is near full.

**How to verify:** In the ServerHealth_v1 list, look for 1-player servers lasting 1–6 min. Scan DisconnectLogs for new players whose jobId is a fresh server while the main server had room. Compare against the pre-change morning: 06:05, 06:51, 06:56, 07:11, 08:05, 08:31, 08:48 solo servers.

**Rollback:** the ⊖ button in the "สถานที่ที่ใช้" table on that page.

**Fallback idea, not built:** an in-game "join the busier server" prompt, using the ServerBrowserService list.


---

## daniweii3-bag-loss

2026-10-21 Daniweii3 (8000224846) reported "fish don't go into the bag". The bag lost 242 fish, 43 produce, 88 seeds and 1 booster between the 10-20 23:59 snapshot and the 00:38:50 save. It was not a sale: coins dropped 106k→83k. No InventoryGuardLog, no CheatFlags; fishing worked again later. Cause UNKNOWN (no live logs).
The owner had already /give'n 1,000,000 coins + premium tickets (~00:52). Restore done 01:4x while he was offline: UpdateAsync merge of the old snapshot + current bag (stacks summed) → Fish 298, Seed 152, Booster 4, Produce 269.
Scan of 154 players active in the last 30 h (current vs GetVersionAtTime at -2/-8/-26 h, flag <50%): 10 flagged, most look like selling. Suspicious, not acted on: JoeZaika087 (3044971674: fish 603 + produce 1969 → 0, coins 50k→25k), EIMUUNOII (9440251112: only PetFood 60 + Bait 6 left; may be the pet-food machine/bait).
Gotchas:
- DataStore versions are HOURLY snapshots; later writes within the hour replace that hour's version, so "no versions" ≠ "no saves".
- Studio Edit hit StandardListGameServerThrottled for ListKeys/ListVersions for 30+ min after heavy scans. A Play Server DM has its own fresh budget. GetVersionAtTimeAsync is not a List call and kept working in Edit.
Related: [[loadcharacter-bag-wipe]] [[level-load-guard]]
Follow-up the same night: both "suspicious" players lost their items in the same window, the 01:00 restart on 10-20 (v2228, the publish that brought the mount gacha). Their items dropped AND their coins dropped (JoeZaika 337,780 → 25,343; EIMUUNOII 88,926 → 32,788). Both left about 10 minutes later and never came back. Both now own mount-gacha items (JoeZaika: MoonSwing + PinkBow; EIMUUNOII: CalmTurtle + FlowerCrown). Gacha = 100k coins/roll. Coin saves have a load guard (LeaderstatsSetup coinsLoaded) and there are no guard logs.
My reading: they sold produce/fish and spent the coins on the new mount gacha = normal play, NOT a wipe. Not provable: there is no sell/roll transaction log. The user said not to restore anything.
2nd report, 2026-10-21 ~15:00 ("fish gone again"). Probably a SALE, not a wipe:
- 13:30 snapshot (= his 13:16 leave save): 474 fish worth 51,137 + 883 produce. Next session 15:14. By 16:30: fish 192, produce 773, coins +78,505 (≈ value of his fish + produce).
- He fished/harvested ~400/h afterwards, so 192 fish + 773 produce is about one hour of new catches after the sale.
- Fits the MAIN shop "💰 ขายทั้งหมด": ShopSystem SellAllCrops also sells FISH, but its text says "ผลผลิตทั้งหมด N ชิ้น" (produce) → misleading.
- A 2nd sale at ~19:00 (fish 858 worth 81.7k → 27, produce kept, coins +101k) = fishing-shop sell-all.
- There is no sell log, so this is not provable. No fix made yet; proposed: relabel / confirm dialog / exclude fish / log sells.
Decision 2026-10-21 night: the user says the player misunderstood (he sold the fish himself). No change to the sell-all button for now; don't re-propose unless new reports come in.


---

## day-only

User 2026-10-03: "ปรับให้มีแต่กลางวัน".
- Workspace.DayCycle (a Sandboxed script with all capabilities; cannot be cloned/reparented from execute_luau, only edited with multi_edit): a block was inserted BEFORE the original `while true do -- Day` loop: makeDay(), ClockTime = 9, then an endless loop tweening ClockTime 9 -> 15 -> 9 (600 s per leg, linear tween helper). The original day/dusk/night/dawn loop is still below it but unreachable; makeDusk/makeNight/makeDawn kept. To bring the night back: delete the inserted block (marked with the 2026-10-03 comment, local DAY_ONLY_SWING_TIME).
- 9..15 is inside the daytime window of NightLights (lamps off), AmbientSounds (night sounds silent) and AmbientCritters (no fireflies). Verified in Play: ClockTime 9.226 -> 9.426 in 20 s, 0 lamps on.
- FishingConfig: removed `Night = true` from Lanternfish (sea, Legendary 450) so it is catchable any time; otherwise the fish book (and the otter reward, which needs every species) could never be completed. FishIndexGui no longer shows "🌙 ออกกลางคืน" for it; WarpGui's per-zone best fish now may include it (it filters on `not fish.Night`). To restore: put `Night = true` back on that line.
- Since ~2026-10-04 "night" exists only as the per-player preset "ตอนค่ำ" in `StarterPlayerScripts.PersonalTimeGui` (attr `PersonalVisualClockTime` = 19); lamps for it are driven client-side by `NightLightsClient` (server `NightLights` stays in day state). 2026-10-13: user said the evening was far too dark (mountains/trees invisible) → preset brightened (old values in the line comment); and reported lanterns blinking / some off → NightLightsClient now compares real glass/brightness state each pass + applies on tag-added (my theory: lanterns re-streamed with the server's day state; I could NOT reproduce the blink, fix unconfirmed).
- 2026-10-18 SKIN-NEUTRAL LIGHTING (user: "สีผิวตัวละครโดนเปลี่ยน"): skin data was identical to the avatar; the tint came from lighting. DayCycle makeDay ColorShift now white, ColorCorrection Saturation 0 / Contrast 0 / Tint white. PersonalTimeGui `SKIN_SAFE = true` converts each preset's ambient/outdoor/ColorShift/tint to equal-luminance grey and forces saturation 0 (sky/atmosphere/rays/time/brightness unchanged), so golden hour is orange only in the sky/haze now. Set SKIN_SAFE = false to bring the colored light back. Note: the server DayCycle tween replicates over a personal preset's Ambient/ColorShift a few seconds after join (pre-existing). Not published.
- No backup clones: Studio thread could not clone DayCycle/reparent into ServerStorage this session (capability errors). The edit is additive and described above. Needs Publish.
- Studio id 2026-10-03 later: b5c81737-8e9d-4c56-82dd-9133b99fad2b. The user also toggled Play in the same Studio while I was editing (Edit blocked), so I stopped Play ([[live-session-overlap]]).


---

## dev-pet-key-override-gotcha

Setting workspace attr `DevPetKeyOverride` to a REAL player's UserId is not read-only. PetOwnership.keyOf() redirects every save, so SultanService (the Studio account owns the Sultan pack) granted SultanDragon into ju3Lek's real record (3008847780) on 2026-10-09 21:54 during a menu test.

2026-10-22: even with a FAKE key, `PetManager` still loads/saves `PetSettings_v1` under the real `player.UserId` (active pets, hunger). Studio Play runs with the fake key overwrote the owner's real active list (ghost/dragon/witch → rabbit only, then the test pets). DataStore versions (ListVersionsAsync, hourly) showed the old value.

**Why:** the user's live data got changed by tests; fixing it needs a DataStore edit the user must approve.
**How to apply:** use a fake key (e.g. "test_<id>") for ownership, and for pet-flow tests prefer a spawned test model (attrs PetId/OwnerUserId) over PetSelect; if PetSelect is needed, say first that it rewrites the real active-pet list. Related: [[live-session-overlap]], [[level-load-guard]], [[zukzon-dog-pet]].


---

## emote-system

User 2026-10-03: "ทำระบบท่าเต้น หรือ ท่าทางต่างๆ วางแผนแล้วทำได้เลย".

- `ReplicatedStorage.EmoteConfig` (ModuleScript): 3 categories (เต้น 27 / ท่าทาง 21 / อารมณ์ 10 = 58). Entry = {Cat, Icon, Name (Thai), Builtin = "dance"/"dance2"/"dance3"/"wave"/"point"/"laugh"/"cheer"} OR {Anim = animation id}. HOTKEY = G.
- Anim ids are the ANIMATION inside each Roblox catalog emote (InsertService:LoadAsset(emoteId) → Animation "<Name> Face", e.g. Hype Dance emote 3696757129 → 10714369624), not the catalog id. Plus Roblox-owned animation assets (type 24: happy 4841405708, sad, agree, floss 5917459365...). All created by Roblox, so they play in any game. Several are paid catalog emotes (Robux), given free in-game here (allowed: game-played animations). All 53 loaded with Length > 0 (checked 2026-10-03).
- `StarterPlayerScripts.EmoteGui` (LocalScript): 💃 button in TopbarRow (LayoutOrder 2, next to ☰), panel on the right-middle (stays open while dancing), tabs, 3-column grid, ⏹ หยุดท่า + status line. Plays through `character.Animate.PlayEmote:Invoke(nameOrAnimation)` (the default Animate script: only when pose == "Standing", walking stops it, one-shot moves return to idle). Stop = invoke the Animate idle Animation (Animate has no stop call). Tapping the active card again stops. Active card = green ActiveStroke, cleared on track.Stopped. Gamepad: opens with the first card selected, B closes; the top-row gamepad nav picks up the button automatically. BindableEvent `EmoteGui.OpenEmotes`.
- Scaling: scale = clamp(min(vp.Y/600, vp.X*0.5/330), 0.8, 1) and the panel height shrinks instead (list scrolls) so text stays readable on phones.
- No server script: own-character animations replicate (verified: the server Animator listed 10714369624 while dancing).
- Verified in Studio Play (PC): open via button and G, dance/builtin/gesture/mood, stop button, walking stops, one-shot ends to idle, server sees the track, no errors. NOT verified: real phone layout, real gamepad, what other players see live. Needs Publish.
- Round 2 same day (user: "เพิ่มท่าเต้นอีกได้หรือไม่"): +38 → 96 total (dance 51 / gesture 31 / mood 14), no duplicate ids. Source list: client `AvatarEditorService:SearchCatalogAsync` (AssetTypes EmoteAnimation, CreatorName "Roblox") returns ~80 emotes; keyword searches found nothing more, so Roblox-made dances are now essentially all in. Skipped: Line Dance 10714383856 (same as 4049037604), Shrek roar (IP). Some new ones are artist collab emotes (Twenty One Pilots, KSI, Royal Blood, Chappell Roan "Hot To Go") shown under neutral Thai names. All loaded (Length > 0); Swan Dance tested in Play.
- Dance SYNC with a friend (2026-10-03, user: "คลิกที่ตัวเพื่อนแล้วมีเมนูให้เลือกซิงค์ท่าเต้น"):
  - Server `ServerScriptService.EmoteSync`: RemoteEvent `EmoteState` (index, startServerTime; 0 = stop, 8/s limit) → player attrs `EmoteIndex` / `EmoteStart` (cleared on respawn). Only emotes started from the 💃 panel are reported (Roblox's own "." emote wheel / "/e dance" are not).
  - `EmoteGui`: startEmote(index, start) reports state; a follower forwards the LEADER's start time, so chains (A follows B follows C) stay on the same beat; when joining late it jumps TimePosition = elapsed % Length. Builtins now play Animate.<name>.Animation1 (not random variants) so everyone gets the same move. Sync mode: follows changes, waits when the friend stops, ends when I walk / pick a move / press stop / tap the bottom pill "🔗 เต้นตาม X · … (แตะเพื่อเลิก)" (EmoteSyncGui) / friend leaves / respawn. BindableEvents EmoteGui.SyncWith(player) / StopSync. Local attr EmoteSyncTarget = userId.
  - `StarterPlayerScripts.PlayerClickMenu`: short tap/click (<0.35 s, <12 px) on another player's character (raycast, walks up to the character model) → popup (headshot, name, what they dance, "🕺 เต้นตาม (ซิงค์ท่าเต้น)" / "⏹ เลิกเต้นตาม"), closes on tap outside / X / B / 12 s. Not while holding a fishing rod or booster (their clicks do other things). Gamepad: D-pad ◀ with nothing selected = menu of the nearest player within 25 studs. Built to take more actions later.
  - Studio-only hooks: server sets player attr `DevSyncWithFake` = name of an instance in ReplicatedStorage with attrs DevFakeEmotePlayer/EmoteIndex/EmoteStart (fake friend); `DevOpenPlayerMenu` = true opens the menu on yourself. (execute_luau can't Fire BindableEvents/Remotes — capability error.)
  - Verified in Studio with the fake friend: report/stop attrs, sync position 4.37 vs expected 4.40 s, follower's start == leader's, switch/stop/restart follow, walking ends sync, pill tap ends, menu layout. NOT verified: clicking a real other player (needs 2 players), the headshot image, phone/gamepad. Backup `_Backup_20261003.EmoteGui_before_sync`.
  - Same day (user: "รวมถึงซิงค์ตามท่าทางและอารมณ์ด้วย"): sync always covered all 3 categories (it syncs EmoteIndex); texts renamed to "ทำท่าตาม (ซิงค์ท่า)" / "เลิกทำท่าตาม" / pill "🔗 ทำท่าตาม X" / "รอเพื่อนเริ่มทำท่า"; menu status verb by category (กำลังเต้น / กำลังทำท่า / กำลังแสดงอารมณ์). Fix: joining a ONE-SHOT move after it already ended now calls stopEmote() (a track stopped before it really played never fires Stopped, state stayed stuck). Tested with the fake friend: gesture loop/one-shot, builtin wave, mood loop/one-shot, late one-shot skipped, mood joined 2 s late.
  - "✕" (U+2715) renders as a box in Gotham — use "X" or words.
- Real names (2026-10-03, user: "เอาชื่อของท่าจริงมาแสดงได้หรือไม่"): every entry has `En` = official Roblox catalog name (Hype Dance, Swan Dance, Hello, Power Blast…; builtins Dance/Dance 2/Dance 3/Wave/Point/Cheer/Laugh). Card shows En as the main label (TextScaled 8–12) with the Thai `Name` small underneath; status / pill / click-menu show En. Removed 4 duplicates found while naming (same move, same Length, different asset): Zombie KeyframeSequence 4210116953 (was "มึนงง"), hadouken 4841403964 (= Power Blast), RockerDance 5915714366 (= Rock On), Clap 5915693819 (= Applaud, was wrongly called "ตะโกน") → 92 emotes (dance 49 / gesture 30 / mood 13). Some names are my best guess: "Line Dance 2" (5915712534, a second line-dance file), Happy/Sad/Agree/Disagree/Sleep/Bored/Cower/Jumping Wave/Confused are the catalog emotes of those animation files. Backup `_Backup_20261003.EmoteConfig_before_realnames`. Emote indexes shifted (fine: everyone gets the same config on publish).
- 2 categories (2026-10-03, user screenshot: title "เหลือแค่ เต้น", "จัดหมวดหมู่ มีแค่ DANCE และ POSE"): panel title "💃 เต้น"; Categories = {dance "DANCE", pose "POSE"} (no icons in the tabs); every gesture + mood entry is now Cat = "pose" (gestures first, then moods). Counts: DANCE 50 / POSE 42 (= 92). PlayerClickMenu verbs: dance "กำลังเต้น", pose "กำลังทำท่า". Backup `_Backup_20261003.EmoteConfig_before_2cats`. (Earlier counts in this note were off by one: after the dedupe it was dance 50 / gesture 30 / mood 12.)
- Speed slider + keep dancing while moving (2026-10-03, user screenshot of a "2.11x" slider; "ตอนเดินวิ่งขยับก็ยังทำท่าอยู่ไม่หยุด ต้องกดปุ่มหยุดถึงจะหยุด"):
  - EmoteGui NO LONGER uses Animate.PlayEmote. It loads the track itself (`Animator:LoadAnimation`, Priority = Action4, `Play(0.15, 1, speed)`), so walking/running/jumping/holding a tool keep the move; only ⏹ / tapping the same card / picking another / respawn stops it. Builtins still use Animate.<name>.Animation1. Old tracks are Stop()+Destroy()ed.
  - "ความเร็ว" row above the stop button: slider 0.25x–3x, step 0.05 (drag/tap the bar; tap the number = 1x; gamepad: select the bar, ◀ ▶ = ±0.25). Grid height is now 1,-190.
  - Sync math: position = (serverNow − start) × speed (looped: % Length). Changing speed rebases start = now − TimePosition/speed so the beat doesn't jump; reports are throttled to every 0.25 s while dragging.
  - EmoteSync: 3rd arg speed (clamp 0.25..3) → attr `EmoteSpeed` (nil when 1). Followers copy the leader's speed (slider shows it), adjust in place when only speed/start changes. Walking no longer ends sync; dragging my own slider does. Click menu shows "(1.50x)" when not 1x.
  - Verified in Studio: Hype Dance kept playing (Action4) through 1.5 s of walking + a jump; slider click 1.65x and drag 2.40x applied to the track and the server; reset to 1x; synced to a fake friend at 2x (pos 1.27 vs 1.28), friend changed to 0.5x mid-dance (1.51 vs 1.50) while I walked; stop clears everything. Side effect: an emote now also overrides the fishing-rod hold pose while it plays. Backup `_Backup_20261003.EmoteGui_before_speed`.
  - Test-tool note: user_mouse_input x/y are offset by the topbar inset (58 px) vs GUI AbsolutePosition — use y = AbsolutePosition.Y (no inset) … mouse lands at +58.
- Ideas not done: VIP/Sultan-only dances (config flag), favorites, sync dancing with friends.
- 2026-10-03 later (user: "ท่าเต้นหรือโพส ไม่ต้องแสดงภาษาไทยแล้ว"): the cards show ONLY the English `En` name (13 pt, TextScaled 8–13, up to 2 lines); the small Thai label (ThaiName) was removed from EmoteGui. `Name` (Thai) stays in EmoteConfig as a fallback/for searching. A new emote MUST have `En`. Other UI text (panel title "เต้น", "ความเร็ว", status lines) is still Thai.
- 2026-10-08 Sit pose (user: "ถ้าอยากทำท่านั่งต้องทำไง" → "ทำให้เลย"): EmoteConfig entry `{ Cat="pose", En="Sit", Sit=true }` = first card of POSE. EmoteGui handles `entry.Sit` in startEmote by setting Humanoid.Sit = true (no AnimationTrack, no EmoteSync report, `sitting`/`sitConn` state); stop/tap again/jump stands up; picking another emote stands up first. Backup _Backup_20261008.EmoteGui_before_sit. Not tested on phone/gamepad; not published yet.


---

## far-mountains-removed

User 2026-10-03: "ลบภูเขาที่อยู่ด้านหลังไกลฟาร์ม สำรองไฟล์ไว้ด้วย". I showed a view from the farm; the user chose "เฉพาะยอดไกล 2 ลูก" (not all grey mountains, not the whole east side).

East terrain (all Terrain, not models): terrace hill x 120–500 (keep), right grey mountain x 400–700 z 200–400 (~225, kept), left grey mountain x 700–1000 z −500..−200 (~310, kept), centre snowy peak x 1100–1600 z −200..300 (~410, REMOVED), Summit peak x 1700–2000 z 200–600 (~510, REMOVED). Small far peaks at (1500,−600) ~205 and (2100,−400) ~257 were left (not chosen; still faintly visible).

What was done:
- Radial masks: centre (1350,50) core r250 → 0 at r450; Summit (1850,380) core r230 → 0 at r420 (smoothstep). New surface = old − w·(old − 16); top cells LeafyGrass where w > 0.35. Ground at both peaks is now y 16.
- GOTCHA: these mountains are HOLLOW shells with no ground underneath — just cutting the top leaves a hole to the baseplate. The working pass also fills every column from y −8 up to the new surface (Ground inside).
- GOTCHA: in Edit mode, workspace:Raycast against just-edited terrain is stale (missed / old heights) — verify with Terrain:ReadVoxels instead.
- HikingMap items now floating were moved (not deleted) to ServerStorage `_Backup_20261003_Mountains.HikingMapItems` (each has attr OriginalPath = old parent full name): 207 items in pass 1 (ferns, shrubs, BigLeaf, TreeFerns, Forest pines, Emergent/Canopy trees, the Summit model) + 92 single boulders from Boulders_km4..7 (those groups span the trail, so each boulder is checked alone). DON'T split tree models into parts (I did once by accident with a "bigger than 60 studs → recurse" rule; undone with ChangeHistoryService:Undo(), which worked).
- Terrain backup: `_Backup_20261003_Mountains.TerrainBefore` (TerrainRegion, cells 250,−6,−100 .. 575,133,190 = world x 1000–2304, y −24–536, z −400–764). Restore: `workspace.Terrain:PasteRegion(f.TerrainBefore, Vector3int16.new(f:GetAttribute("CornerX"), f:GetAttribute("CornerY"), f:GetAttribute("CornerZ")), true)` then move HikingMapItems children back by OriginalPath.
- Same day, round 2 (user "ลบได้"): the 2 small far peaks (1500,−600) and (2100,−400) were flattened the same way (backup `TerrainBefore_SmallPeaks`, cells 312,−6,−222 .. 592,80,−38), 181 floating items moved.
- Round 3 (user: "รวมถึงต้นไม้ลบไปก่อน ทำให้เป็นราบมีแต่หญ้าเฉยๆ ไปก่อน"): EVERYTHING east of x 1160 is now a flat LeafyGrass plain at y 16 (blend slope x 1040→1160; water columns skipped; low spots filled up to 16), and every HikingMap item with centre x ≥ 1080 (+3 floating in the blend) was moved to HikingMapItems → store now 6,394 items / 29,125 parts; workspace.HikingMap went 49,102 → 19,976 parts (big perf win). Kept: left grey mountain (x 700–1000), right grey mountain (x 400–700), the jungle between them and the terrace hill. Backup of the state just before round 3: `TerrainBefore_FlatPlain` (cells 260,−6,−224 .. 594,90,204). Full restore order: paste TerrainBefore_FlatPlain, then TerrainBefore_SmallPeaks, then TerrainBefore, then move items back.
- Round 4 (user screenshot: faint rings / a ledge / bumpy patch, "ปรับให้พื้นที่เรียบเท่ากันหมด"): rewrote every column exactly — surface at y 16 on a voxel boundary (cell 12–16 occ 1, two LeafyGrass cells, Ground below down to −8, air above). Flat zone: x ≥ 1150 (all z), plus x ≥ 1000 for z ≥ 0 (bumps 16–29 there), west blend x 950–1000 (z ≥ 0); z < 0 keeps the slope x 1040–1150 into the left mountain; a pit at (1200..1300, −600) was filled. Verified 20,387 points every 10 studs: all exactly 16, all LeafyGrass. Backup before this: `TerrainBefore_Smooth` (cells 235,−6,−202 .. 577,90,202). Loop gotcha: `for z0=-808,680,128` stops at 600 — make sure the chunk loop reaches the far edge.
- Round 5 (user top-down screenshot "ตำแหน่งนี้ด้วย"): the south foothill band between the left grey mountain and the south map edge (x 500–1160, z ≤ −600, heights 9–38) is now exactly flat 16 LeafyGrass; blends: west x 430–500, north z −600..−540 (lower/raise toward the mountain foot, mountain kept). 80 HikingMap items in x 470–1160, z ≤ −585 moved to HikingMapItems (store 6,474). Backup `TerrainBefore_SouthFoothills` (cells 100,−6,−206 .. 300,90,−125).
- Round 6 (user: "แถวนี้ด้วย", north side): the north foothill band of the RIGHT grey mountain (x 330–1000, z ≥ 530 to the north edge, heights 0–38 with square Grass-material pits) is flat 16 LeafyGrass; blends: south z 470–530 toward the mountain foot, west x 280–330 toward the beach side (x < 280 untouched). 2 boulders moved (store 6,476). Backup `TerrainBefore_NorthFoothills` (cells 66,−6,113 .. 254,70,205). Nothing else was in that box.
- The plain runs to the terrain edge (x ≈ 2300, z ±800) where it just ends (it did before too, hidden by the mountains) — a candidate for sea fill later ([[sea-and-beach]]).
- GOTCHA (user couldn't right-click-rotate the Studio camera afterwards): screen_capture with camera_position leaves workspace.CurrentCamera.CameraType = Scriptable if it times out. Fix in Edit: CameraType = Fixed (Studio default). After any camera_position capture, check/reset this.
- 2026-10-13: the user DELETED `_Backup_20261003_Mountains.HikingMapItems` from the place (and `_Backup_20261003_terrace_crops`) to cut server instances (ServerStorage 110,529 → 20,299); they say both were saved to local .rbxm files first (not seen by me). The 6 TerrainBefore* regions + CornerX/Y/Z attrs are still in the folder. Restoring the items now needs the user's .rbxm or the place version history (≤ v1837).
- No runtime script uses HikingMap (only the generators ServerStorage.HikingMapProps / JungleForest). Needs Publish. Not checked in Play / on a phone.


---

## fishing-plan

User decisions (2026-09-26):
1. No fish traps. AFK = "leave the rod cast" (auto fishing).
2. Both a minigame and auto fishing. I plan auto to be slower / slightly less rare than manual.
3. Fish can be sold, fed to pets, and recorded in a fish index.
4. Rods are bought with coins for now; better rods also add luck.
5. New pet (otter or kingfisher, ask which at step 6) with a "ช่วยตกปลา" ability.
6. Fishing income ≈ farming income.

Spots:
- Terrain Water surfaces: sea, lake, and canals at y 0; terrace pond at y 4; stream at y 16.
- Lake dock: RestSpots.LakeDock at x -392, z 5..-30, top y 3.3.
- Zones planned: sea, lake, canal, terrace stream/pond, plus day/night fish.

Build order:
1. Rod + cast + bobber + bite.
2. Fish data + inventory + selling.
3. Minigame + auto mode.
4. Rod tiers + bait + shop.
5. Fish index.
6. Fishing pet + feeding fish to pets.
7. Announcements, event fish, polish.

Step 1 DONE 2026-09-26:
- Config: ReplicatedStorage.FishingConfig (Rods.Bamboo: CastDistance 14, BiteTime 6-14 s, HookWindow 1.6 s, Luck 1; MAX_LINE_DISTANCE 55).
- Templates: ServerStorage.FishingTemplates.Rod_Bamboo (part-built; invisible Handle; pole tilted 35° up-forward; Attachment "RodTip" on the Pole) and Bobber (Attachment "LineAttach").
- Items: ItemFactory.CreateRodTool / GiveRod (attrs IsFishingRod, RodId); InventorySystem kind "Rod".
- UI: hotbar blue strip "เบ็ด"; inventory tab = booster tab; reserved seed slots 1-2 blocked; ItemPreview "Rod_<id>".
- Server: ServerScriptService.FishingSystem. RemoteEvents FishingCast(target) / FishingReel / FishingState(state, data). It validates the held rod, range, and water, builds the bobber + Beam line, and schedules the bite. A missed bite = fish escapes and waiting continues. It auto-stops on unequip / too far / death.
- Client: StarterPlayerScripts.FishingClient (click water or auto-find water ahead; hint label above hotbar; ❗ billboard on bite).
- Catching currently only shows a message.
- The user's test account keeps a Bamboo rod so they can try it (no shop yet).

Step 2 DONE 2026-09-26:
- Fish data in FishingConfig.Fish: 17 fish (canal 3, lake 5, stream 3, sea 6 incl. night-only Lanternfish).
- Rolls: RarityWeights C75/R22/L3 with luck (Rare × √luck, Legendary × luck). Size is skewed u^1.6, then StarFromFraction, then price = base × STAR_PRICE {1,1.3,1.6,2,2.5}.
- Zones (FishingSystem.getZone): surface y > 2 = stream; lake = circle (-398,-50) r50; sea = ServerStorage.FishingTemplates.SeaMask (rows = Z, cols = X, Min -1104, Step 16); otherwise canal.
- Fish items: ItemFactory CreateFishTool / GiveFish (attrs IsFish/FishId/Star/Count); InventorySystem kind "Fish".
- UI: inventory tab "🐟 ปลา"; hotbar teal strip. Fish are not auto-assigned to the hotbar and are blocked from slots 1-2.
- Selling: ShopSystem sell list entries CropType "Fish_<id>" with Name/Icon/PreviewModel; SellAll includes fish; ShopGui uses item.Name/Icon/PreviewModel.
- Catch card: FishingClient CatchCard shows the 3D preview.
- Models: ServerStorage.FishModels.<id> (AI meshes rotated so the body length is along X; ItemPreview camera looks from -Z). Catfish/GiantCatfish are cat-faced chibi fish. Previews are copied to ItemPreviewModels "Fish_<id>" by ItemFactory.
- AI generate_mesh: 17 parallel async jobs hit rate limits (11 failed). Generate one at a time.
- Fixed bug: FullInventoryGui CATEGORY_ORDER / counts lacked new categories, so sort compared nil and the whole inventory showed empty. It had been broken since the petfood tab. Now it defaults to 99 and builds counts from the tabs.

Rarity update 2026-09-26 (user request):
- Fish tiers are ธรรมดา/หายาก/ตำนาน/ลับ, using the PetRarity names/colors. I kept "ธรรมดา"; the user wrote "ปกติ" and I offered to rename.
- Added Secret fish RainbowWhale (sea, price 2500, weight 0.3, × luck) with an AI model.
- ReplicatedStorage.RarityFrame: rarity-colored border overlay (Frame "RarityFrame", rainbow spin for Secret). Used for fish in CustomHotbar slots, FullInventoryGui cards, and ShopGui sell rows (server sends item.Rarity).

Step 3 DONE 2026-09-26 (minigame + auto):
- Config: FishingConfig.Minigame[rarity] = {ZoneSize, FishSpeed, FishJump}; MINIGAME {FillRate .30, DrainRate .20, StartProgress .3, TimeLimit 20, MinTime 1.8}; AUTO {BiteTimeMult 1.5, RareMult 0.5, CatchDelay 1}.
- Server protocol: FishingReel(action nil=stop/"hook"/"win"/"lose"); a "win" before MinTime is rejected. FishingAuto(on) sets player attr FishingAuto (not saved). FishingState: waiting / bite{window,rarity | auto} / minigame{rarity,params,rules} / escaped / caught{...,auto} / idle(reason). In auto mode the line stays in the water after a catch.
- Client FishingClient: click on a bite = "hook". Minigame bar: hold (mouse/touch/Space/ButtonA/R2) pushes the green catcher right; the fish icon swims to random targets; 1 s grace before the progress drains. Button "🤖 ออโต้: เปิด/ปิด" next to the hint. ❗ colored by the bitten fish's rarity.
- Tested in Play: manual catch via the minigame and auto 2 catches in 24 s; test fish removed, Bamboo rod kept.
- Can't screenshot fast UI (capture lags ~5 s): clone the frame into a temp ScreenGui to snapshot it. Runtime edits to a server-required config table from execute_luau did NOT affect the running scripts.

Step 4 DONE 2026-09-26 (rod tiers + bait + shop; user asked for cute rods):
- Rods (FishingConfig.Rods, RodList()): Bamboo free / Carrot 8k / Kitty 30k / Candy 120k / Rainbow 450k. Luck 1/1.25/1.6/2.2/3, CastDistance 14-24, BiteTime avg 10 to 6 s, HookWindow 1.6-2.5, ZoneBonus 0-0.08 (wider minigame catcher). Prices are my proposal; the user hasn't confirmed them.
- Models: part-built in ServerStorage.FishingTemplates.Rod_<id>, same skeleton as Bamboo (Handle at origin, pole axis = Bamboo Pole rotation, "RodTip" attachment on Pole). Carrot: leaf tuft; Kitty: cat head at butt, paw reel, bell; Candy: red/white stripes, lollipop reel, heart tip; Rainbow: 7-color bands, neon star tip + light + sparkles. ItemFactory sets PivotOffset 90° on preview copies so ItemPreview shows the rod side-on.
- Bait: FishingConfig.Bait[star] {BiteMult .95-.75, Luck +.1-+.75}, BAIT_PER_PRODUCE 2. Tool attrs IsBait/Star/Count, ItemFactory Create/Give/TakeBait, InventorySystem kind "Bait", template FishingTemplates.Bait (AI blue jar + part-built pink worms). One bait is used per bite (luck applies at the roll; the bite speed-up applies to the wait). Player attr FishingBait (nil = best, 0 = off, 1-5), set via RemoteEvent FishingBait; HUD button "🐛" cycles the choice. Bait lives in the inventory fish tab, is not auto-assigned to the hotbar, and is blocked from slots 1-2.
- Shop: workspace.FishingShop (AI round pastel kiosk with a pink fish on top, at -407,*,12 on the sand by the lake dock, BillboardGui sign). Server ServerScriptService.FishingShop: RemoteFunction FishingShopRequest (info/buyRod/makeBait), RemoteEvent FishingShopOpen via ProximityPrompt. DataStore "FishingShop_v1" {rods={id=true}} (UpdateAsync merge). Flow: take coins, save, then give; if the save fails, refund. 15 s after join it re-gives owned rods missing from the inventory; InventorySystem skips duplicate rods. Client LocalScript FishingShopGui has tabs for rods and bait.
- Emoji 🪱 renders as a box in Roblox, so use 🐛.
- Tested buy, duplicate, not-enough-coins, makeBait, bait consumption and zone 0.32. Restored the user: coins 138,077, Carrot + bait removed, FishingShop_v1 record removed. The user's own Mackerel/Seabass ★2 were kept.

Step 5 DONE 2026-09-26 (fish index "สมุดสะสมปลา"):
- Config: FishingConfig.ZONE_ORDER, IndexList(zone) (sorted by zone, then rarity, then price), INDEX.
  - First-catch bonus: Common 100 / Rare 500 / Legendary 2,000 / Secret 10,000.
  - Zone reward: canal 3k, lake 8k, stream 5k, sea 20k.
  - AllReward 50k.
  - These are my proposed values; the user hasn't confirmed them.
- Server: ModuleScript ServerScriptService.FishIndex, required by FishingSystem.
  - giveCatch calls pcall(FishIndex.Record); the result goes to the "caught" data as `index` {isNew, bonus, newRecord, zoneDone, zoneReward, allDone, allReward}.
  - DataStore "FishIndex_v1" {fish={id={n,size,star,t}}, zones={}, all}, saved with an UpdateAsync merge.
  - Save timing: immediate on a new species, every 60 s when dirty, and on leave.
  - Catches made before the data loads are queued.
  - RemoteFunction FishIndexRequest("info"); player attribute FishIndexCount.
- Client: LocalScript FishIndexGui.
  - 📖 button in the top-right row at (1,-224,0,34), next to donation -172, pets -120, bag -68, cart -16. A red dot shows when a new species is added.
  - Window has zone tabs with counts, a reward line, and a card grid (RarityFrame border; ViewportFrame with ImageColor3 black for uncaught silhouettes).
  - FishingClient CatchCard.Badge shows "🆕 ปลาใหม่! +X" or "🏆 ตัวใหญ่สุด!"; zone/all completion shows as a hint.
- Tested one catch (Tilapia, new, +100), then cleaned up: record removed, fish removed, coins back to 138,077.

Step 6 DONE 2026-09-27 (user chose otter as a fish-index reward: "ปรับเพิ่มรางวัลเป็นนาก"):
- I read that as completing the whole book (all 18, including the Secret whale) granting 50k + the otter. Later moved to 10 species (see Decisions 2026-09-27).
- PetDefinitions.Otter "นากน้อยนักตกปลา":
  - Legendary, NotInGacha (GachaService buildState skips it), UnlockHint shown on the locked row of the 🐾 menu.
  - Abilities {"Fisher"} (+ Lucky from rarity), FishBiteMult 0.85, FishBonusChance 0.12.
  - BoneNames without ears (the ears are part of the head mesh).
- Template ServerStorage.PetTemplates.Otter: AI mesh, segmentation explicit (head, torso, arms, legs, tail), rigged by hand with Motor6Ds computed from world joint points (C0 = p0:ToObjectSpace(jointCF)). Has a part-built pink shell on the belly. Faces +Z like the other pets.
- Ability module PetSystem.Abilities.Fisher is passive. Bridge ModuleScript ServerScriptService.FishingPetBonus: PetManager registers a provider returning {petId, name, chance = FishBonusChance x efficiency x GetSpeed, biteMult, onHelp (hunger JOB_COST)}.
- FishingSystem:
  - scheduleBite multiplies by biteMult and sets player attr FishingPetHelper ("name N%"), which is shown in the hint.
  - giveCatch rolls the chance for an extra fish (rollFish same zone, rod luck) and sends caught.petBonus.
- FishIndex allDone: result.pet = "Otter" and PetOwnership.Grant runs in task.spawn. It retries 15 s after join if the book is complete but the otter isn't owned.
- Feeding fish to pets: PetManager accepts IsFish, gain = PET_FOOD_BY_STAR[star] x PetHunger.FISH_RARITY_MULT {1, 1.5, 2.5, 4}. PetHungerClient counts fish as food. ActivePetsHud label "🎣 ตกปลา".
- Gotchas:
  - require() from execute_luau gets a SEPARATE module instance. PetOwnership.Grant from the command bar saves to the DataStore, but the running game doesn't see it until you rejoin (restart Play).
  - The game keeps running between my turns (auto-fishing and the auto-feeder keep going), so check the state again before cleaning up.
  - Emoji 🦦 🐛 📖 🎣 🐟 all render.
- Tested: spawn/walk, the Fisher hint (12%), a bonus Featherback, feeding a fish (91→100%).
- Restored the user: otter removed from PetOwnership_v1, FishIndex_v1 removed, test fish removed, coins 138,077, AutoFeeder food[5] back to 92, active pets NineTailFox + NineLivesCat. DEBUGPET print removed.

Step 7 DONE 2026-09-27 (announcements, event fish, sell at the fishing shop) — all 7 fishing steps are complete:
- Announcements: FishingSystem announceCatch fires the existing RemoteEvent GachaAnnounce to all clients for Legendary/Secret fish, payload {Kind="Fish", PetName=fish name, Rarity, Detail="120.0 ซม. ★★★★★"}.
  - Secret catches are also published to MessagingService topic "GachaAnnounce_v1"; the GachaService subscriber forwards Kind/Detail.
  - GachaAnnouncer shows "🎣 ข่าวดีจากริมน้ำ!" and "ตกได้ปลา<tier> ...". A chat message is shown; there is no machine burst for fish.
- Event fish: FishingConfig.Fish.NineTailKoi "ปลาคาร์ปเก้าหาง" (Legendary, Zone "any", Price 800, EventOnly).
  - It is active while the GachaConfig event lists it in `Fish` (NineTailFox_2026_09 has Fish={"NineTailKoi"}).
  - Helpers: FishingConfig.ActiveEventFish() and EventFishList(). IndexList excludes EventOnly fish, so they don't count toward the book.
  - FishIndexGui has a "🎉 อีเวนต์" tab.
  - Model ServerStorage.FishModels.NineTailKoi: AI koi with fox ears, rotated 90° so the length is along X; pivot reset to the Koi reference orientation.
- Studio-only test hook: server sets player attr DevForceFish = fishId, and the next bite is that fish at max size, ★5.
- FishingShop has a "💰 ขายปลา" tab: actions sellFish(fishId, star) / sellAllFish, at the FishingConfig.GetPrice price (same as the main shop), with info.Fish stacks.
- Tested: forced NineTailKoi, then the banner, event tab and sell tab.
- The user played between my turns: the fish book had their real Mackerel/Seabass catches and coins were 138,277. Cleanup removed only my test data (NineTailKoi removed from FishIndex_v1). I also re-enabled their Planter ability, which my pet swapping had turned off.
- Lesson: before cleaning up, snapshot the user's real state at the start of each Play test (they may play between turns). Only remove the specific test items; never wipe whole records.

Pet food machine accepts fish (done 2026-09-27, see [[pet-auto-feed-plan]]). Possible later: more event fish per future event.

Related: [[pet-auto-feed-plan]] (the pet food machine could later take fish).

Decisions 2026-09-27 (user): rod prices confirmed (8k/30k/120k/450k). The otter now comes EARLIER: FishingConfig.INDEX.PetReward = {Count = 10, Pet = "Otter"} (10 non-event species; the record flag is petReward). The full book gives 50k coins only. Also fixed: event fish (Zone "any") no longer trigger a zone-complete result, and the stray zones.any was removed from the user's record. Tested with the book preset to 9 species (snapshot/restore pattern): the 10th catch granted the otter and showed the hint; the user's data was restored afterwards.
Minigame made VERTICAL 2026-09-27 (user request, Stardew-style):
- Panel "Minigame" (150x330) sits right of the character at (0.5,110,0.5,-20). Holding pushes the green catcher UP; releasing lets it fall. catcherPos/fishPos 0 = bottom, rendered as 1-pos.
- The progress bar is vertical and fills bottom-up.
- UIScale fits the screen height (baseScale, clamped 0.55-1). The pop tween goes to baseScale.
- The user plays in Studio between my turns. To edit scripts I had to stop their Play session; restore only my own test catch.
Fishing HUD redesigned 2026-09-27 (user reference: round mobile-game buttons):
- FishingHud.FishControls (190x136, bottom-right; on touch-only devices it moves to (1,-128) to clear the Roblox jump button; UIScale by screen height).
- CastButton (104px round, dark navy): icon/caption change by phase: 🎣 เหวี่ยง / ⏳ รอปลา / ❗ เกี่ยว! (red, pulsing) / 💪 กดค้าง! / 🤖 ออโต้. It does nothing while waiting or reeling. Holding it during the minigame counts as holding.
- BaitButton is a pill badge on the CastButton corner ("🐛 ★3 x12"); tapping it cycles the bait.
- ReelButton ↩️ "เก็บเบ็ด" fires reel("stop"). AutoButton 🔁 "ออโต้" turns green when on.
- Hint is now a small status pill above the buttons.
- Test tip: user_mouse_input by instance_path is flaky and "mouseButtonClick" can error "duplicate button state". Use moveTo x,y (AbsolutePosition center, no GuiInset added) plus explicit mouseButtonDown/Up.
Junk added 2026-09-27 (user: "ได้ขยะจากน้ำจริงๆ"):
- FishingConfig.Fish entries with Junk=true, Rarity "Junk", Zone "any", star always 1:
  - OldBoot รองเท้าเก่า 4
  - TinCan กระป๋องเปล่า 2
  - PlasticBottle ขวดพลาสติก 2
  - OldTire ยางรถเก่า 6
  - TornNet แหขาด 3
- Roll: JUNK.Chance 0.12 / luck (rod + bait) happens first in rollFish; the normal pool excludes Junk. Minigame.Junk is easy. No first-catch bonus, no announcement.
- Helpers: JunkList(); IndexList excludes Junk. JUNK.Color (150,115,80) and name "ขยะ"; the clients special-case tierColor for "Junk" (it is not in PetRarity).
- Items: ItemFactory sets tool attr IsJunk. GetFishName shows no star for junk. PetManager refuses to feed junk ("ขยะกินไม่ได้นะ!"); PetFoodConverter and PetHungerClient skip junk.
- UI: hotbar/bag show a brown "ขยะ" strip. The catch card says "ได้ขยะ! ช่วยเก็บน้ำให้สะอาด 🌊", and the badge says "🆕 ของใหม่ในสมุด!" when the bonus is 0. The fish book has a "🗑️ ขยะ" tab.
- Models: AI meshes in ServerStorage.FishModels via a finalize helper (rotate so length is on X, scale to a target length, reset pivot rotation). New AI meshes may render blank in ViewportFrames for a few seconds while they load.
Auto-cast 2026-09-27: in FishingClient, tryAutoCast(silent) casts when auto is on, phase is idle and the rod is held (it finds water ahead). It runs when auto turns on (with a warning hint if there's no water), 0.6 s after equipping, and every 2 s silently (recasts after walking back to water or a broken line). reelInByPlayer (ReelButton, or clicking water while waiting) also turns auto off so it doesn't recast. Tested; the test SilverBarb was removed.
Auto-catch reel-up animation 2026-09-27: after an auto catch, FishingSystem fires RemoteEvent FishingFx:FireAllClients("autoReel", {userId, bobber, fishId, landing}).
- LocalScript StarterPlayerScripts.FishingFx (runs within 150 studs):
  - Splash, then the rod tilts up: tween the character's RightGrip C1 by Angles(-40°,0,0). Negative raises the tip; +40 lowered it.
  - The bobber arcs from the water to 2.2 studs below the RodTip. A clone of ItemPreviewModels.Fish_<id> hangs head-up and wiggles, then shrinks away.
  - Then it re-casts along an arc to the landing point with a splash.
  - Total ~2.15 s. The bobber moves only locally, then is put back.
- Studio-only: workspace attr FishFxSlow = time multiplier, for screenshots.
- Tested with a Koi; the test catches (Koi, TornNet, GiantCatfish, SilverBarb, NineTailKoi) were removed and coins restored to 138,777. The user has since fished a lot at sea (36 fish, book: Mackerel, Seabass, Clownfish).
Manual catches animate too (2026-09-27): on a minigame "win", the server detaches st.bobber before stopFishing, fires FishingFx "manualReel" and destroys the bobber after 1.8 s. The client reelUp(data, recast=false) runs the same pull-up/hang/pop but no re-cast. Note: FishFxSlow can't be used for manualReel, because the server deletes the bobber at 1.8 s real time; verify with a position log instead.
Lesson: forced test catches (DevForceFish = max size) overwrite the user's size record in FishIndex. The Seabass record became 80 cm from my test (their true best was unknown, >=75). Next time snapshot the FishIndex record before forcing a species the user already has, or force a species they don't have.
Collector rewards page 2026-09-27 (user: "แถบรางวัลนักสะสม ทำเด่นๆ"):
- FishIndexGui header has a gold "🏆 รางวัลนักสะสม" button (moving gradient shine + pulse; the progress bar is shortened to 120) that sets currentTab = "rewards".
- RewardsPage ScrollingFrame (same rect as the grid), built by renderRewards():
  - Big otter card: rainbow rotating stroke, gold glow circle, a 3D otter from ReplicatedStorage.PetPreviewModels.Otter swaying in a ViewportFrame, perks, progress x/10, and a pill "อีก N ชนิด!" or "✅ ได้รับแล้ว!".
  - 4 zone cards with bars and rewards, a full-book card (50,000), and a first-catch bonus line.
- FishIndex info now returns petReward.
- Gotcha hit: renderRewards was first defined above `local info` / caughtCount, so it called nil upvalues (runtime error "attempt to call a nil value"). Define functions after the locals they use.
Otter REALLY fishes 2026-09-28 (user request; replaced the old 12% bonus / 15% faster bite):
- FishingPetBonus is now provider + jobs. The provider returns {petId, name, model, speed = level speed x max(0.3, hunger eff), onHelp}. SetJob/GetJob(player) = {waterPoint, reach}.
- Abilities.Fisher.GetTarget returns (waterPoint, reach, nil): the PetController walks the pet toward the water point and stops `reach` away, facing it; with no callback it just stands.
- FishingSystem helper system (Heartbeat every 0.25 s):
  - While the owner has a bobber in the water, it picks a water point 5 studs (or 3/7) to the side of the owner's bobber (terrain water raycast) and sets the job.
  - Once the pet is within reach+2 it attaches "PetFishingRod" (Rod_Bamboo scaled 0.5, welded to the RightArm, pointing at the water) and casts "<name>_PetBobber" (scaled 0.8) with a Beam from the rod tip.
  - Bites come every 20-35 s / speed. After a 1 s dip: rollFish(zone, owner's rod luck, not auto), then GiveFish, FishIndex.Record, announceCatch and onHelp (hunger). It fires FishingFx autoReel {tip, pet=true} and FishingState "petCaught" (owner hint "🦦 ...จับได้: X").
  - It stops when the owner stops fishing, the pet is gone/hungry/ability off, the owner's bobber moves >30 studs away, or the pet can't arrive within 12 s. Player attr FishingPetHelper = pet name (hint shows "🦦 <name>ช่วยตก").
- FishingFx supports data.tip/data.pet (no owner rod tilt, hangDrop 1.3, fish scale 0.8).
- Tested at the lake dock: the otter stood on the dock edge with its rod and caught a Tilapia with the hanging-fish animation; reeling in removed its rod and bobber.
- Restored: FishIndex from a JSON snapshot, otter removed from PetOwnership_v1, inventory restored to the snapshot (166 fish), coins 198,941, pets fox + cat.
- Gotcha: writing a DataStore key right after stopping Play can hit "request rate exceeds" (the game just saved on leave). Wait ~8 s and retry.
Starter rod 2026-09-28: FishingShop.giveStarterRod runs on join after the character spawns + 4 s. If the player has no Bamboo tool it gives one; the first time (FishingShop_v1 rods.Bamboo not recorded) it also sends HarvestNotify "🎣 ได้รับเบ็ดไม้ไผ่ฟรี! ไปตกปลาที่ทะเลสาบข้างท่าเรือได้เลย". It then records Bamboo so the 15 s restore loop re-gives it if lost. InventorySystem skips duplicate rods, so a late inventory restore can't duplicate it. Tested by removing the Rod entry from the user's PlayerInventory_v1 (JSON snapshot); after the test the saved inventory was identical to the original.
Otter SOLO fishing 2026-09-29 (user: fish even when the player isn't fishing):
- FishingSystem updateHelpers has two modes.
  - "owner": the owner has a bobber, so the otter fishes beside it (as before).
  - "solo": the owner isn't fishing. findShoreWater(owner pos) marches 16 directions in 2-stud steps up to SOLO_RADIUS 35; the first water sample after land is the shore, water point = 3 studs further into the water, and the closest direction wins.
- Solo rules:
  - Re-search when the owner moves more than SOLO_LEAVE 30 from the anchor. If no water is found, retry every 3 s (the otter just follows).
  - Luck = the best rod in the bag (bestRodLuck).
  - HarvestNotify only for Rare+ or a new species (commons/junk go in silently).
  - The mode switches automatically when the owner starts or stops fishing.
- Texts updated (PetDefinitions description, PetHelperToggleButton note, FishIndexGui perks).
- Tested: beach by the fishing shop (junk + mackerel), no water near the seed shop (follows), farm canal (-238,*,-192).
- NOTE: the user legitimately earned the otter by 2026-09-29 (11 species incl. RainbowWhale, petReward = true). NEVER remove Otter from PetOwnership in cleanups now. The test data was restored from snapshots; the otter was kept.
2026-09-29: the user asked the otter to be 10% slower. PET_BITE_TIME {20, 35} -> {22, 38.5}, so the otter averages ~31 s per fish (Lv1, full). Player auto with Bamboo is ~16 s (BiteTime avg 10 x 1.5 + 1 s), with Rainbow ~10 s. Auto halves rare+ odds; the otter doesn't. Rain affects both.
BUG FIX 2026-09-29 (user: "นากตกปลาช้าผิดปกติ"):
- Measured: solo/idle ~34 s per fish (as designed: 22-38.5 s / speed + 1 s).
- But while the owner fished MANUALLY the otter caught 0 in 150 s. Every owner catch removes the owner's bobber, so updateHelpers flipped owner->solo->owner and stopHelper/recast twice, resetting the bite timer every ~13 s.
- Fix: an existing helper keeps fishing wherever it is regardless of the owner fishing or not. It only restarts if the owner walks > SOLO_LEAVE + reach from h.waterPoint. New helpers still choose beside-bobber (owner fishing) or shore (solo). Verified: 4 otter catches during 11 manual owner catches.
- Test hygiene lesson: take Edit-mode snapshots BEFORE starting Play (the _G snapshots made in Play are lost on stop). This time I had to remove the test lake fish by first-catch timestamp and deduct the 700 first-catch bonus (Featherback 500 + SilverBarb + Tilapia). About 6 junk items from the first test couldn't be told apart from the user's own and were left.
2026-09-29 later: user asked the otter to be 10% FASTER again, so PET_BITE_TIME is back to {20, 35} (~28.5 s avg, ~125 fish/h at Lv1 full).
Inventory flicker fix 2026-09-30 (user screenshot: fish tab flickering, blank cards): FullInventoryGui.refreshInventory ran every 0.5 s and destroyed/recreated every card and its ItemPreview ViewportFrame, so heavy fish meshes never finished rendering.
- Now it builds a layoutKey (activeCategory + pending tool id + shown tool ids + equipped flag). If unchanged, it only updates each card's count label (cardCountLabels[tool]) and skips the rebuild; isOpening / tab click still force a rebuild.
- Verified: 22 fish cards, 0 rebuilds in 5 s, all previews visible.

Fish weight display (2026-09-30, user: show กก. instead of ซม.):
- Data is still stored as `size` (cm): stars, FishIndex records and DataStore are unchanged.
- FishingConfig has a WEIGHT_KG table giving every fish a `Weight = {minKg, maxKg}`.
- WeightKg maps size linearly from the Size range into the Weight range.
- FormatWeight(fishId, size) gives "0.35 กก." / "4.2 กก." / "1,250 กก."; it falls back to ซม. if a fish has no weight.
- Used by the catch card (FishingClient "⚖️"), the FishIndexGui card detail, and the FishingSystem legendary announce Detail. The server print still logs cm.
- A NEW fish needs a WEIGHT_KG entry too.
- Backups *_before_weight.

Mobile fishing controls above the jump button (2026-09-30, user: they covered the right end of the 9 slots):
- FishingClient.placeControls, touch-only: FishControls (AnchorPoint 1,1) right edge = JumpButton right edge, bottom = 10 px above the jump top (abs coords minus FishingHud.AbsolutePosition).
- Falls back to (1,-16,1,-120). Re-placed every 2 s in Heartbeat. Desktop keeps (1,-18,1,-18).
- The sprint button (SprintController) already hides while FishControls is visible, so the spot is free.
- Studio's phone emulator reports KeyboardEnabled = true, so the touch branch can't run there. Verified by applying the same math by hand: on 801x392, controls y 139-234, jump top 244, no overlap with the hotbar.
- Backup FishingClient_before_abovejump.

Otter needs the WHOLE book again (2026-10-01, user: "ให้นาก ต้องสะสมปลาครบทุกตัวถึงจะได้"; supersedes the 10-species rule):
- FishingConfig sets `INDEX.PetReward.Count = #IndexList()` at the end of the file (18 now; event fish and junk excluded; grows automatically with new fish). The table literal holds a 999 placeholder.
- Players who already earned the otter keep it: FishIndex.onPlayerAdded retries the grant when `petReward` is already true OR the count is reached.
- Texts: Otter Description / UnlockHint ("จับปลาให้ครบทุกชนิด"), FishingClient hints (the full-book hint also mentions the otter), FishIndexGui (bar full when done, "ครบทุกชนิดได้นาก").
- Tested: a 17/18 record without petReward stays ungranted on join; rewards page shows 17/18 "อีก 1 ชนิด!".
- Backups _Backup_20261001.*_before_otterall. Needs Publish.
- See [[live-session-overlap]]: the user was fishing in the LIVE game during this test.

Fish announcements are private (2026-10-01, user request):
- FishingSystem.announceCatch now does GachaAnnounce:FireClient(player) only: no FireAllClients, no MessagingService.
- GachaService's cross-server subscriber drops Kind == "Fish" messages (from old-version servers).
- Gacha pet announcements are unchanged (still server-wide, and cross-server for Secret).
- Tested: a forced GiantCatfish on auto at the dock (-392,6.5,-27 facing -Z toward the lake), and the catcher's client got the banner.
- Test cleanup: removed the fish item, -2000 coins (first-catch bonus), and FishIndex_v1 fish.GiantCatfish (the user had not caught it before).
- Gotcha: DevForceFish test catches write real data (index + first-catch bonus). Check whether the species is new first.
- Backups FishingSystem_before_privateannounce, GachaService_before_nofishrelay.

Auto-fishing "stops by itself" (2026-10-01, user report; they suspected fish escapes):
- No server crash was found (config fuzz clean; 10 auto catches in a Studio run with no warnings). Likely causes found by reading the code:
  - A single world tap/click while waiting in auto mode turned auto OFF and reeled in (onActivated). Easy to hit by accident on mobile.
  - If that tap landed while the server was already in "bite", auto went off but the line stayed (reel with action nil hit `st.deadline` nil → error), so every later bite was a manual one that escaped: "ปลาหลุด" forever.
- Fix, FishingClient: in auto + waiting, the first tap only shows "🤖 ตกออโต้อยู่ แตะอีกครั้งเพื่อเก็บเบ็ด"; a second tap within STOP_CONFIRM (2 s) sends auto off + reel "stop" (works in any phase). The ↩️ button and the auto button are unchanged. Manual mode is unchanged (one click reels in).
- Fix, FishingSystem (anti-stall): the auto catch is pcall'd and always returns to "waiting" + scheduleBite; onBite runs under pcall and reschedules on error; nil guards for `st.deadline` and Config.Bait; a watchdog in the auto-stop Heartbeat uses st.biteAt / st.biteStart / st.reelStart (bite overdue by 5 s → reschedule; "bite" > 8 s or "reeling" > TimeLimit + 6 → escape) and warns "FishingSystem: ..." in the log.
- Tested: 10 auto catches, single click keeps fishing, double click stops. Test fish counts restored from a snapshot (FishIndex n counts +10 left; no new species, no bonus).
- During the test the character moved and swapped tools by itself for ~15 s: the user was probably at the keyboard in my Play session. Check for that before driving the character.
- Backups _Backup_20261001.FishingSystem_before_autostall / FishingClient_before_autostall. Needs Publish. If the user still sees stops on live, ask what the screen showed (auto button still green? bobber in the water? after ~19 min = [[afk-rejoin]] resume).

Catch card smaller on phones (2026-10-01, user: "ใหญ่ไปมาก" on mobile):
- FishingClient: `cardBase = clamp(ViewportSize.Y / 600, 0.65, 1)` via fitCatchCard (re-run on ViewportSize change); showCatch tweens catchScale 0.4*cardBase → cardBase. Phone landscape (~390 high) = 65% (208x62); screens ≥ 600 high are unchanged.
- Only checked on a desktop viewport (scale 1) plus a 0.7 clone for looks; not seen on a real phone. If the user wants it smaller/bigger, change the 0.65 floor.
- Backup _Backup_20261001.FishingClient_before_cardscale. Needs Publish.

Zone map fix (2026-10-01, user: "ตรวจสอบสถานที่ตกปลาและป้ายว่าตรงกับที่ตกจริง"):
- Found: SeaMask was a copy of SeaFillMask (every cell that got sea water), which includes the farm canals. So the central canal, the side canals and the east river all showed "🌊 ทะเล" and gave sea fish; only a few stray cells were "คลอง". The lake circle was right.
- Fix: FishingTemplates.SeaMask rebuilt from live terrain. Grid Min -1120, Step 8, 281x281. Method: sea-level water (y <= 2) → distance to land → core = more than 5 cells (40 studs) from land → flood from the map border through core → geodesic dilate 5 cells through water. '1' = open sea; narrow inland water (< ~88 studs wide) = canal.
- FishingSystem.isSea now returns true outside the grid (was canal). Step/Min are read from the attributes, so no other code changed.
- Verified by real casts: dock → lake, central canal / near lake / N-S canal (x 16) / east river (x 94) → canal, west beach and south coast → sea. Hint showed "🏞️ คลอง" and "🌊 ทะเล".
- Rebuild the mask the same way after any terrain change to coasts or canals.
- RESOLVED (see the next section; the user chose to make it a lake zone): HikingMap.LakeViewpoint sign says "ทะเลสาบหมอกเช้า" (437,19,-128) but that hill water (x 416..536, z -252..-144, surface y 4) is zone "stream" (ลำธาร), because all water above y 2 is stream. There are no other zone signs in the world.
- Backups _Backup_20261001.SeaMask_before_canalfix / FishingSystem_before_canalfix. Needs Publish.

Hill lake = lake zone (2026-10-01, user chose option 2 "2 เลยก็ได้"):
- FishingSystem.getZone checks HILL_LAKE_CENTER (468,-201) / HILL_LAKE_RADIUS 66 FIRST and returns "lake", before the `surfaceY > 2 → stream` rule. The water body is x 406..526, z -262..-142, surface y 4 ("ทะเลสาบหมอกเช้า").
- The outflow stream west of it (x <= 376, z -214..-196, y 4) is outside the circle and stays "stream"; so do the terrace pond and the y 16 stream.
- Verified by real casts: bobber (470,-156) → hint "🛶 ทะเลสาบ"; bobber (300,-208) → "⛰️ ลำธาร". No test catches.
- The otter helper uses the same getZone, so it follows.
- Backup _Backup_20261001.FishingSystem_before_hilllake. Needs Publish.

No weight when a fish is caught (2026-10-02, user: "ปรับ ui ตอนตกปลาได้ ไม่ต้องแสดงน้ำหนักปลา"): the catch card (FishingClient showCatch catchSize) now shows only the stars, and the Legendary/Secret announce Detail (FishingSystem announceCatch) is only the stars. Weight is STILL shown in the fish book card (FishIndexGui detail "⚖️ <weight> · 🎣 xN") as a record; ask the user if they want it removed there too. FishingConfig.FormatWeight is unchanged. Backups _Backup_20261001.FishingClient/FishingSystem_before_noweight. Needs Publish.

No price on the catch card (2026-10-02, user: "ตอนตกปลาได้ไม่ต้องแสดงราคา"): FishingClient catch card hides the "💰 ขายได้ N เหรียญ" row (catchPrice.Visible = false, the label is kept so nothing breaks) and the 3 remaining rows (name / rarity+zone / stars) moved down 6 px to sit centred. The card now shows only name, rarity · zone and stars (the weight was removed earlier the same day). Backup _Backup_20261001.FishingClient_before_noprice. Needs Publish. The fish index and the shops still show prices.

Fishing XP (2026-10-03, user: "ปรับการตกปลาก็ได้เลเวลด้วย"): FishingConfig.XP {Junk 5, ByRarity Common 15 / Rare 30 / Legendary 60 / Secret 150, PerStar 5, AutoMult 0.5} + FishingConfig.CatchXP(fishId, star, auto) (min 1). FishingSystem requires LevelSystem: giveCatch → LevelSystem.AddXP (pcall; auto catch = half) and sends xp in the "caught" payload; helperCatch (otter) → half XP. FishingClient catch card line = stars + "  +N XP". Reference: planting harvest = star × 10 (Common 3★ fish = 30 = 3★ crop). Verified: compile, CatchXP numbers, Play starts without errors. NOT verified: a real catch in Play (didn't want to add real fish/XP to the live save). Backups _Backup_20261003.FishingConfig/FishingSystem/FishingClient_before_xp. Needs Publish.
Side finding: LevelSystem saves only on PlayerRemoving and does not guard against a failed load (GetAsync fails → level stays default, then saved over the real one) — same class of bug as the pet-settings one ([[pet-slots]]); flagged to the user, not fixed.

Rod tier caps (2026-10-03, user: "ปรับเบ็ด limit ระดับปลา เช่น เบ็ดไม้ไผ่ ธรรมดา–ยาก เท่านั้น เป็นขั้นบันไดแต่ละเบ็ด"): each rod has `TierWeights` in FishingConfig.Rods; a tier missing from the table = impossible. Bamboo C85/R15; Carrot C78/R22 (Rare max); Kitty C68/R28/Legendary 4; Candy C62/R30/L8 (no Secret); Rainbow C56/R33/L10/Secret 1. `FishingConfig.RodWeights(rodId, luck)` replaces WeightsWithLuck in rollFish (new 4th arg rodId): bait luck only multiplies tiers the rod already has (m = totalLuck / rod.Luck: Rare x sqrt(m), Legendary/Secret x m). Junk chance unchanged (still luck-based). Auto-fishing RareMult still applies. Otter (helperCatch) uses the equipped rod, else the best rod in the bag. Shop rod Descriptions got a "ได้ปลาถึงระดับ ..." suffix. NOTE zones: the canal only has Common + Rare fish, so every rod is capped at Rare there; Legendary needs sea/lake/stream pools. Simulated 20k rolls per rod/zone (matches; sea Rainbow Secret ~1%). Backups _Backup_20261003.FishingConfig/FishingSystem_before_tiers. Needs Publish; NOT tested with a real catch.

AUTO-ONLY fishing 2026-10-18 (user: minigame too hard for players; chose "same as manual" rates): FishingSystem.isAuto returns true always (hook/minigame code kept but unreachable), player XP full (otter still half), FishingConfig.AUTO BiteTimeMult/RareMult = 1. FishingClient: auto button hidden, local `autoPaused` (เก็บเบ็ด → no auto-recast until cast pressed / rod re-equipped). Shop + bag rod details no longer show hook window / minigame zone; tutorial text updated. Tested auto cast→bite→catch in Play (1 real MudCarp kept); reel button not hand-tested. Backups _Backup_20261018.*_before_autoonly. Needs Publish.

SeaMask rebuilt again 2026-10-12 (user: south coast showed "คลอง" but must be sea): coast reshaped after 2026-10-01 was missing from the mask. Same method via terrain raycasts (281x281, step 8, erode 5 / flood from border / dilate 5); +724 sea cells (south coast z >= 640, x 108..800; north coast z ~ -800); old sea cells that are still water kept. Backup ServerStorage._Backup_20261012.SeaMask_before_coastfix. Rebuild the mask after ANY coastline terrain change. Not verified by a real cast. Needs Publish.


---

## fish-skip-pass

Fish book skip pass (user request 2026-10-10): a Robux Game Pass button on the collector-rewards page that unlocks every fish and gives every reward at once.

- Config: `FishingConfig.INDEX.SkipPass.GAMEPASS_ID` (0 = not on sale, button hidden). Set to **2026238507** on 2026-10-11 (pass "สะสมปลาครบ 40", 435 R$, user's own, on sale). Not published / no real purchase tested yet. The pass name says 40 fish but FISH_V2 is still off in live.
- Server: `ServerScriptService.FishIndex` `unlockAll` / `ownsSkipPass` / `applySkipPass`. Pass-unlocked fish are stored with `n = 0`. Gives first-catch bonuses for missing fish + zone rewards + full-book reward + otter. Waits for the `CoinsLoaded` attribute before adding coins. Runs on purchase and on every join.
- User decisions: pass owners keep a complete book forever (new fish added later unlock too, incl. book v2 rewards); first-catch bonuses ARE included.
- Client: `FishIndexGui` button `SkipPassButton` in the otter card (shown when book incomplete + no pass + id > 0); cards with n = 0 show "⚡ ปลดล็อกด้วยพาส".
- Studio hooks: player attr `DevFishSkipPass` (server; writes the REAL account's book — see [[live-session-overlap]]) and `DevFishSkipPreview` (client; only shows the button).
- 2026-10-11: the owner account (9360333174) ALREADY owns the pass, so the buy button never shows for it and unlockAll runs on every join. For a test the user asked me to make the book incomplete: removed 6 fish + zones2 canal/lake/stream + all2 from `FishIndex_v1` via UpdateAsync in Edit mode (allowed this time); original record in `backups/FishIndex_v1_9360333174_before_skiptest_2026-10-11.json`. FishIndex saves MERGE (union, max n), so editing the book only works while no session of that account is running, and an active live session would merge the fish back.
- Studio purchase-test mode (2026-10-11): workspace attr `DevFishSkipTest` = true makes FishIndex treat the player as NOT owning the pass until the purchase prompt closes (then attr `DevFishSkipBought`, any prompt result counts). It is currently SET in the place file (Studio-only, harmless live) — remove it when the user is done testing. With it on, the book stayed 34/40 on join (verified).
- Button layout (2026-10-11, user drew where): `SkipPassButton` is a big 164x92 gold button at the top-right of the otter card (Title / Price / Note labels). To screenshot the rewards page from MCP: fire `PlayerGui.FishIndexGui.OpenFishIndex`, then click `Main.RewardsButton` with user_mouse_input (instance_path) — that tool works for clicking UI. The pass price read 599 R$ that day (user changed it from 435).
- Tested by simulation + button preview only. NOT tested: a real purchase, an account with an incomplete book. Not published.
- Empty v2 book (40 species) pays 283,200 coins in total — relevant when the user sets the Robux price.

Related: [[fishing-plan]], [[fish-v2]].


---

## fish-v2

## User decisions (2026-10-08)
- \* = Secret.
- ปลาบึก stays Legendary. Its Secret slot became ปลาเสือตอ (TigerFish).
- ปลาช่อน is Retired and replaced by ปลากัด (Betta).
- ปลากด was dropped so the book is exactly 40.
- The otter needs the whole book.
- Zone and full-book rewards can be claimed again for book v2: 6000 / 15000 / 8000 / 40000, full book 100000.

## Code
- `FishingConfig.FISH_V2 = false` keeps the game exactly as before, so it is safe to publish other work. To test in Studio, set workspace attribute `DevFishV2 = true`.
- Flip FISH_V2 to true only when every new fish has a model and `Hidden = false`.
- Per-fish `Hidden` (no model yet) and `Retired` (Snakehead) are skipped by rollFish, IndexList, JunkList and WarpGui.
- `HasHidden(zone)` blocks zone / full-book / otter rewards.
- FishIndex keys: v1 = zones/all (untouched), v2 = zones2/all2.
- Junk: `JunkWeight` + `PickJunk`. DiamondShard (0.15) and RubyShard (0.25) are Valuable, meant for future craft-bench materials.

- **2026-10-12: user said he is publishing → `FISH_V2 = true` set in code** (backup _Backup_20261012.FishingConfig_before_v2live) and news item V1.1.6 added (Id farm-news-20261012a; V1.1.5 had been used by the user for the AFK/respawn fixes). Publish itself not yet confirmed. To roll back: FISH_V2 = false.

## Event fish (Halloween, 2026-10-13)
- User approved 3 event fish, released WITH the ghost pet (gacha event `Halloween_2026`, switch `GhostGacha2026`, 15 Oct – 2 Nov): `PumpkinGoldfish` (Rare, any, 120), `GhostSquid` (Legendary, sea, 800), `CandyBatRay` (Secret, any, 2600). Later the same day the user added a 4th: `VampireFish` ปลาแวมไพร์ (Secret, any, 2600; first mesh had no vampire cues, the "dressed as Dracula, cape, bat wings, tiny fangs" prompt worked). Models in FishModels, config + `GachaConfig` event `Fish` list done; NOT play-tested, prices not simulated. "Cute, not scary" was stressed again.
- Event fish = `EventOnly` (+ optional `Season`, hides it from the book's 🎉 event tab until `SeasonConfig.HasStarted`). They never count for the 40-book / zone / otter rewards. Tier chance is unchanged by event fish; they only share the tier's pool (uniform pick inside a tier).
- Flat creatures (rays) need a hand-set tilt instead of `_FishFinalize` (it only snaps yaw). Fish preview convention: camera at -Z looking +Z, head toward +X (screen-left).

## Models
- AI `generate_mesh` (async, one at a time, ~5–6 min each; the wait often times out, so call wait_job_finished again).
- Prompt style: "cute chibi cartoon …, big round shiny eyes, happy smile, glossy kawaii game item, side profile, head pointing left", segmentation none, maxTriangles 3000.
- Finalize with ServerStorage._FishFinalize (snap yaw, anchor, scale longest dimension to the target, pivot at the bbox centre, save to ServerStorage.FishModels).
- Photo board: workspace._FishLineup at (-495, 18, 100); camera from z 92 looking +Z.

## Progress
- All 28 models are done and Hidden = false (2026-10-08). FISH_V2 is still false, so the live game is unchanged.
- Redone: DragonLobster (first came out as a dragon) and Sunfish (first was not round). The old versions are in _Backup_20261008.
- Crab, SeaUrchin, Scallop and OldPhone were rotated so they face the -Z camera.
- Studio test with DevFishV2: book 40, previews ok, book UI ok. The pet caught WaterStrider + SwampEel on the user's real account; the items were removed but the index records stay.
- Balance sim (avg coins per catch): canal +166% (Rainbow) / +311% (SunBee); stream −21% for Bamboo; sea about the same. Waiting on the user's balance decision.
- 2026-10-08 release prep was done in Studio (then switched OFF again, see below): balance tweak (RiverPrawn 1600, RainbowGuppy 1700, Leech 12 — canal now below sea for every rod), FISH_V2 = true, V1.1.4 news added (Id farm-news-20261008c), _FishLineup moved to ServerStorage._Backup_20261008. Waiting for a Play test + the user's Publish. To roll back before publish: set FISH_V2 = false.

- 2026-10-09: at the user's request (test fish v2 "in dev only") workspace attr `DevFishV2 = true` is now SET in the place. It only works when `RunService:IsStudio()`, so a Publish leaves the live game on v1 (FISH_V2 in code is still false). Side effects in Studio runs: CraftConfig.ENABLED follows FISH_V2, and Studio sessions touch the REAL account's data (coins from first-catch / book v2 rewards, FishIndex `fish` + zones2/all2, inventory) — see [[live-session-overlap]]. Only PetOwnership has a fake-key override (`DevPetKeyOverride`); FishIndex/coins/inventory have none.

Related: [[fishing-plan]], [[craft-bench]].
- 2026-10-08 later: user asked to set **FISH_V2 = false again** (afraid of publishing by accident) and the V1.1.4 news was removed (Id back to farm-news-20261008b). When the user says to launch: set FISH_V2 = true, then put this item at the top of LoginAnnouncementConfig.Updates.Items and change Id (e.g. farm-news-2026MMDD):
- 2026-10-09: V1.1.4 is now taken by the pet shard level-up / aura / disconnect news (Id farm-news-20261009a). Use **V1.1.5** for the fish v2 news below.
  TH "ปลาใหม่ 23 ชนิด รวม 40 ชนิด (มีตัวลับ!) + ขยะมีค่า เศษเพชร/เศษทับทิม, สมุดปลาชุดใหม่ รับรางวัลได้อีกครั้ง, ส่งเบ็ดผีเสื้อ/ผึ้งน้อย/Music Box เป็นของขวัญให้เพื่อนได้, ท่านั่งพื้น, โต๊ะช่างนากน้อย (เร็วๆ นี้)"
  EN "23 new fish, 40 in total (with secrets!) + valuable junk: diamond and ruby shards, new fish book set with rewards to claim again, gift the Butterfly Rod / Little Bee Rod / Music Box to a friend, new sit pose, Otter's Workshop (coming soon)"
  (drop the gift/sit/bench parts if those were already published in an earlier version.)
- 2026-10-08: the user published with FISH_V2 = false (answered "เรียบร้อย"). ItemFactory now skips `Hidden` fish when copying previews to ReplicatedStorage.ItemPreviewModels (so the 28 new meshes are not sent to players yet; Studio-only, needs another Publish). Flipping FISH_V2 makes them copy automatically.
- 2026-10-10: user asked Secret tier 20% harder to catch → `FishingConfig.SECRET_CHANCE_MULT = 0.8` applied in `RodWeights` (all rods/baits). Per-fish Secret chance now Rainbow 0.80%, NightMoth/EarthLove 1.61%, SunBee 2.41%. Studio only, not published; backup `_Backup_20261010.FishingConfig_before_secret80`.
- 2026-10-12: user asked Legendary tier 20% harder → `FishingConfig.LEGENDARY_CHANCE_MULT = 0.8` (RodWeights + TierWeightsFrom). Legendary now Rainbow 8.18%, SunBee 13.31% (Secret rises slightly: 0.82% / 2.49%). Studio only; backup `_Backup_20261012.FishingConfig_before_legend80`.
- 2026-10-12 round 2 (user confirmed a second 20%): `LEGENDARY_CHANCE_MULT = 0.64`. Legendary now Rainbow 6.65%, SunBee 10.94%; Secret 0.83% / 2.56%. Studio only.


---

## gamepad-ui

Gamepad support done:
- Hotbar (CustomHotbar).
- Pet HUD (ActivePetsHud; D-pad right enters it).
- AutoFeederGui, FishingShopGui, PetFoodGui, VipGui.
- Pet menu (PetHelperToggleButton; LB/RB tabs; ActivePetsHud petMenuWindow close=nil).
- GachaGui (2026-09-30):
  - LB/RB cycle tabs; A/B skip the capsule reveal via skipReveal.
  - The results overlay is its own SelectionGroup (OK only); B = OK.
  - padHint label.
  - Backup: _Backup_20260930.GachaGui_before_gamepad.
  - Roll lock 2026-09-30: from pressing roll until the results are dismissed, `rolling` = true. The X is hidden, anything that sets Enabled = false gets re-enabled, B does nothing, and E again doesn't clear the results. Player attr GachaBusy is set meanwhile; TutorialGui waits on it (up to 180 s) before closing the gacha for its finish popup. Before this, the tutorial closed the gacha 3 s after the reveal and the player never saw the results.

- QuickShop (PlantLimitGui) DONE 2026-09-30:
  - closeButton ("Close") and buyButton are Selectable (the cards clone buyButton, so all card buttons are); all MouseButton1Click became Activated.
  - Panel SelectionGroup + Stop; gold selectBox.
  - On Visible with a gamepad: selects the top card's button (lowest card LayoutOrder = SultanCard).
  - B (selection inside) closes.
  - Backup _Backup_20260930.PlantLimitGui_before_quickshoppad.
  - BIG CENTERED REDESIGN 2026-09-30 (user: "เต็มจอ เด่นๆ ดูง่ายทุก device"; supersedes the scroll-only version below):
    - Panel AnchorPoint (0.5, 0.5), Position (0.5, 0, 0.5, 30), design size 720x400.
    - UIScale = clamp(min((W-24)/720, (H-84)/400), 0.5, 1.25): 0.77 on 801x392, 1.25 on desktop.
    - Header 40 px, title 22, close 36.
    - CardList is a ScrollingFrame (1, 0, 1, -48) with a UIGridLayout of 2 columns, cell (0.5, -6, 0, 100).
    - Dim overlay TextButton "QuickShopDim" (ZIndex 0, tap closes), visible with the panel.
    - PlantLimitGui DisplayOrder 2 → 8 (above the HUD at 2, below SultanShopGui at 9).
    - Backup _before_bigshop.
  - Mobile readability 2026-09-30 (earlier step): all cards now live in ScrollingFrame panel.CardList (LayoutOrder 1, header fixed).
    - fitPanel: scale = clamp(screenH/620, 0.85, 1); CardList height = min(content, (screenH - 88)/scale - 62).
    - The old full-panel scale-to-fit went down to 0.51 on 801x392. Now 0.85 plus scrolling.
    - Gamepad firstCardButton reads cardList; a SelectedObject handler scrolls cards into view.
    - SprintController hides the 🏃 button while the QuickShop / PetMenu / Donation panels are open (RIGHT_PANELS in fishingControlsOpen).

- FishIndexGui DONE 2026-09-30:
  - Tabs (Tab_<id>), RewardsButton and CloseButton are Selectable + Activated.
  - Fish cards (Frames, named by fishId) and reward rows are Selectable, so selecting scrolls the list (scrollIntoView / UIScale).
  - LB/RB cycle tabs plus "rewards"; B closes; on open with a gamepad it selects the current tab button.
  - Heartbeat restore by lastName after render destroys the cards.
  - Tested via user_mouse_input clicking the open button (the mouse still works): 18 cards selectable, selecting the last one scrolled the canvas to 324.
  - Backup _before_gamepad.

- DonationGui DONE 2026-09-30:
  - Close + Donate_<amount> buttons are Selectable + Activated; panel SelectionGroup.
  - On open with a gamepad it selects the first amount (Donate_10); B closes.
  - Tested: a mouse click opens it, all 8 buttons are selectable, no errors.

All main windows now support a gamepad. Final items DONE 2026-09-30:
- TutorialGui: button() now makes Selectable = true (popMain / popSkip / card skipButton); 3 clicks became Activated; popup is a SelectionGroup and selects popMain when shown with a gamepad.
- "BackgroundMusic " (trailing space):
  - toggleButton renamed "MusicButton"; close / volume icon / knob are Selectable + Activated; panel SelectionGroup.
  - On open with a gamepad it selects volumeKnob; ◀▶ on the knob = volume ±10% (knob NextSelectionLeft/Right = itself); B closes.
- TopMenuGamepad also collects buttons in TopbarRowGui.Row, so the row is now MusicButton → VIP → FishIndex → Donation → PetMenu → Inventory → QuickShop.
- Every UI in the game now has gamepad support. The user CONFIRMED on a real controller (2026-09-30) that all of it works, including the top-row D-pad up shortcut.
- Top-right row shortcut DONE 2026-09-30 (LocalScript TopMenuGamepad):
  - D-pad up (when nothing is selected and no TextBox is focused) collects the visible top-right GuiButtons (direct ScreenGui children, height 28-60, AbsolutePosition.Y <= 30, X > half the screen), sorted by X.
  - It saves their Selectable / SelectionImageObject / NextSelection*, makes them selectable with a gold ring, and links ◀ ▶ (up/down stay put).
  - It starts on the last-used button, and shows a hint "◀ ▶ เลือกเมนู · A เปิด · B ออก" at (1, -16, 0, 62).
  - It exits (restoring everything) on B, when the selection leaves the row (a window that selects its own button), or when input switches away from gamepad.
  - Studio can't send DPadUp ("bound to a CoreGUI core action"). Test via PlayerGui.TopMenuGamepadHint.TestEnter / TestExit (Studio only).
  - The open buttons of QuickShop, Donation, FishIndex, Tutorial help and the inventory prompt were switched from MouseButton1Click to Activated.
  - CustomHotbar hint now includes "⬆️ เมนู".
  - Verified row order: VIP → FishIndex → Donation → PetMenu → Inventory → QuickShop.
- Already done by an earlier session: ShopGui (seed shop), FullInventoryGui (inventory, Y opens).
- No gamepad needed: CurrencyGui toggle (mobile only), SprintController (L3).

Shared pattern:
- Buttons are Selectable and use Activated (not MouseButton1Click).
- The window Frame has SelectionGroup + SelectionBehavior* = Stop.
- B closes (UserInputService.InputBegan KeyCode ButtonB).
- When the gui is disabled, clear GuiService.SelectedObject if it is inside.
- Gold SelectionImageObject (a Frame with UICorner + UIStroke 255,190,40, thickness 3.5), applied via DescendantAdded.
- On open with a gamepad (GetLastInputType is Gamepad1-4), select the main button.
- Lists that are rebuilt: give buttons unique Names, remember the last selected name, and re-select it in Heartbeat when the selection is lost or hidden. Fall back to the first row by LayoutOrder (AbsolutePosition isn't updated right after a rebuild).
- Scroll into view manually, dividing by UIScale.

Studio VirtualInput can't send gamepad buttons, so the user tests on a real controller. They confirmed hotbar, pet HUD, feeder, fishing shop and pet food; pet menu and gacha are not confirmed yet.

Keyboard hotkeys vs chat (2026-10-01 bug: typing "b" in chat opened the inventory):
- GetFocusedTextBox() can't see the Roblox chat bar. Chat typing arrives as InputBegan with gameProcessed = true.
- Fixed: FullInventoryGui B (skips keyboard input when gameProcessed; gamepad Y unaffected), CustomHotbar number keys (return if gameProcessed), SprintController Shift (ignored when processed).
- Any NEW keyboard hotkey must check gameProcessed.
- VirtualInput can't send keys while the chat has focus, or number keys at all (bound to CoreGUI), so this can't be simulated in Studio.
- Backups *_before_chatkeys.


---

## graphics-settings

User request 2026-10-03 (after perf investigations showed little measurable gain from scene tweaks): "ออกแบบ ตั้งค่าให้คนที่มือถือหรือคอมเก่าปรับต่ำสุดได้" → approved design "ตามนี้ได้เลย". Auto "device looks slow" toast was DEFERRED by the user ("เพิ่มทีหลังได้").

Files:
- ReplicatedStorage.GraphicsConfig: levels high/mid/low/lowest (Shadows, Bloom/SunRays/DoF, MaxAuras 40/20/8/0, MaxGlows 12/6/0/0, WaterReflectance x1/0.5/0/0, Critters 1/1/0.4/0). DefaultFor(device): mobile→low, console→mid, pc→high. Attributes on the Player: GraphicsQuality (the bus), GraphicsChosen, GraphicsSaved, GraphicsLoaded.
- StarterPlayerScripts.GraphicsQuality (LocalScript): applies Lighting.GlobalShadows / Terrain.WaterReflectance / Bloom+SunRays+DoF locally (not replicated); waits up to 6 s for GraphicsLoaded.
- ServerScriptService.GraphicsPrefs: DataStore "GraphicsQuality_v1" key=UserId {level}; RemoteEvents.GraphicsSave; 1 s min gap, 3 s debounced save, flush on leave.
- StarterPlayerScripts.GraphicsGui: window with live FPS (green >=45, yellow >=25, red below), 4 level cards, BindableEvent OpenGraphics; gamepad support (B closes). Entry "⚙️ กราฟิก" added to MoreMenuGui (see [[warp-menu]] for the menu, [[gamepad-ui]] for the pattern).
- CropAura and AmbientCritters read the level (aura/glow caps, butterflies/birds/fireflies factor).
- Localization: Graphics_* keys th+en.

2026-10-11: the window also has two toggles — 👤 ชื่อบนหัว / 💬 สถานะบนหัว (show/hide, this device only). LocalScript `NameTagPrefs` hides rows of the server-made `PlayerNameTag` (name = Icons, VipBadge, PlayerName; status = Title, Typing) using attributes `HideNameTags` / `HideStatusTags`; saved in the same `GraphicsQuality_v1` record (`hideNames`, `hideStatus`, remote `TagPrefsSave`). Hide/show verified on the own tag; the SAVE path was not verified (GraphicsPrefs missed players who joined before the script started in Studio — fixed with a loop over existing players, untested). Not published.

Same day: the personal time-of-day choice (PersonalTimeGui presets morning/noon/afternoon/golden/evening) is also saved in that record (`time`, remote `TimePrefSave`, attr `SavedPersonalTime`) — compiled only, NOT play-tested (Studio start-play was stuck); verify save + restore together with the tag toggles.

Verified in Play: window opens, real click applies lowest (shadows off, effects off), aura/critter counts scale per level (12 anchors: high 12 aura/12 glow, mid 12/6, low 8/0, lowest 0/0; butterflies 40/40/16/0, birds 18/18/8/0), night fireflies 6/6 zones on high/low (Rate 81→32), 0 on lowest, save → DataStore level=low → rejoin loads Saved=low, Chosen=true, applied. Test key removed, no console errors.

Caveats: only GlobalShadows-off showed a clear measured gain (~2x) in Studio; the rest is unmeasured and Studio fps is noisy. Not tested on a phone or real gamepad. Lighting.Technology / Terrain.Decoration are not scriptable. Needs Publish. Backups ServerStorage._Backup_20261003.*_before_graphics (MoreMenuGui, CropAura, AmbientCritters, Localization). Studio id 8e91c8ca-512d-4758-8362-6f7f5b06fb65.

CropLod (2026-10-03, user screenshot: MicroProfiler ~50 ms/frame next to a big corn field; user said "จัดไป"):
- Cause found by counting triangles (EditableMesh faces) in ServerStorage.CropTemplates: Corn Stage5 ≈10,200 tris/plant (husk 3,888, kernel 3,568, silk 960), Wheat ≈16k, Watermelon ≈20k, Potato ≈2k; all parts CastShadow=true, RenderFidelity Automatic. A field of hundreds of corn = millions of tris per frame (+ shadow pass). The aura Highlights (max 12) are minor. NOT measured as fps, only inferred from counts.
- StarterPlayerScripts.CropLod (new LocalScript): PlantingSystem tags each stage model "CropModel" (buildStageModel). Client re-checks distance every 0.4 s: > level.CropShadowDist → CastShadow off; > level.CropDetailDist → parts with Attribute LodDetail get LocalTransparencyModifier 1 (corn husk/kernel/silk, wheat spike/grain/awn on every stage; only those two crops are marked). 150 changes/tick budget, 4-stud hysteresis. Distances in GraphicsConfig: high 60/90, mid 40/60, low 0/35 (no crop shadows), lowest 0/20.
- Verified in Play with 4 cloned test corn at ~20/50/75/120 studs on all 4 levels (states switch as expected, restores on high). Not verified: real fps gain, how it looks, other crops' LOD (watermelon/pineapple only lose shadows). Next option if still slow: lower-poly corn/wheat/watermelon meshes (husk 3.9k tris is overkill).
- Backups _Backup_20261003.PlantingSystem / GraphicsConfig _before_croplod. Needs Publish.

CropLod update 2026-10-03 (user: "ตรงแถบนี้ไม่ต้องเอาพืชไปแสดงแล้ว ให้เหลือแต่แปลง" on the same corn-field screenshot; I read it as the FAR rows of the field): new state 3 = hide the whole plant (LocalTransparencyModifier 1 on every part) beyond level.CropHideDist, leaving only the soil plot. Distances now shadow/detail/hide: high 40/50/80, mid 30/40/60, low 0/30/45, lowest 0/20/30 (studs from the camera). CropAura only draws auras within min(MaxDistance, CropHideDist). Verified with test corn at 20/45/70/100 on all 4 levels. If the user meant a specific fixed zone (not distance), ask; easy to tune in GraphicsConfig.Levels. Hidden plants still exist (prompts/harvest/auto-harvest unaffected), only not drawn. Studio note: from this session `require` of ReplicatedStorage modules inside execute_luau fails with a Capabilities error; use attributes or read Source instead.

Low-end round 2 (2026-10-24, user approved plan steps 1+2; Studio only, not published):
- Measuring: HealthReporter sends a 4th arg {tris, draws, cpu, gpu, lvl, dev, rq}; DisconnectLogger session `health` gets trisK/draws/cpuMs/gpuMs/gfx/device/robloxQ; ServerHealthLogger `sample.cl["mobile/lowest"] = {n,fps,tris(k),draws,cpu,gpu}`. RenderCPU/GPU read 0 in Studio (real devices unknown). Read these from ServerHealth_v1 / DisconnectLogs_v1 after publish to compare levels.
- SceneLod (LocalScript): 48-stud cells, LocalTransparencyModifier 1 beyond `SceneHideDist` (low 220 / lowest 140), whitelist of scenery roots + loose decor models + SeasonalDecor_/SeasonalSkin_ + PlacedFurniture; skips parts > 60 studs, invisible parts, Attribute KeepVisible. Plaza measure: tris 1.40M high → 0.96M low → 0.84M lowest; draw calls only 747 → 667.
- FxThrottle module (`Gate()` / `Paused()`, `DecorFps` low 20 / lowest 0) used by 9 stationary-decor scripts; NOT for things that follow a character/rod/pet (NightMoth, SunBee, PetFireflyRing) — pausing those leaves them floating. ToyHammer wobble always runs full.
- lowest `SkyOff`: Terrain.Clouds off + WaterWaveSize 0.
- Found: `Workspace.Model` at the seed shop is a 2-stud NPC made of 952 Parts + 4,482 ManualWelds (6.4k instances) — candidate to replace with one mesh.
- Others' mounts deliberately not hidden (rider would float).
- Step 3 done same day (Studio only): AvatarLod (others' Accessory handles LTM 1 beyond AvatarDetailDist low 60 / lowest 35; PlayerNameTag MaxDistance = min(90, NameTagDist low 60 / lowest 40)); WeatherClient RainDrops factor (low 0.4 / lowest 0); RarityFrame spins only gradients actually on screen + FxThrottle; ActivePetsHud rainbow, TrashEventGui floats, CraftBenchGui otter via FxThrottle; AmbientCritters returns early at factor 0; GraphicsQuality uses per-instance Enabled signals instead of the 1.5 s full rescan. UI audit: most windows already gate their loops on Visible/Enabled; FishingFx line sag and MountFx legs left as is (gameplay-visible). AvatarLod NOT tested with a 2nd real player.
- Step 4 done same day (Studio only): crops show 3 looks (PlantingSystem `VISUAL_STAGE` {1,1,3,3,5}; user chose B; set {1,2,3,4,5} to restore); seed-shop cat NPC renamed `Workspace.ShopCatNpc`, 4,484 useless welds removed (all parts anchored); `SlowDeviceHint` toast (FPS < 25 twice in 30 s windows, once per session, opens GraphicsGui; Studio test switch `workspace.DevSlowHint`). Lighter crop meshes skipped by user (would need Blender + manual Studio import). Live baseline before B: 7 players ≈ 16.5 stage models/s (ServerHealth_v1 crop.m). 3-stage NOT play-tested with a real plant (test bag had no seeds).


---

## hotbar-layout

User request 2026-09-30: add a rod (เบ็ด) tab in the inventory. Also, a rod put in the bag came back into the 9 slots after a rejoin.

Before this, the hotbar layout was client-only and not saved. Every join, and every respawn, recreated the tools, so AutoAssignNew put them back into slots.

**Rod tab**
- FullInventoryGui: CATEGORY_TABS gains { id = "rod", key = "Inventory_TabRod" }.
- getCategory returns "rod" for IsFishingRod (it used to be the booster tab).
- Localization: th "🎣 เบ็ด", en "🎣 Rods".

**Layout saving**
- Server Script ServerScriptService.HotbarLayout:
  - DataStore HotbarLayout_v1 stores { slots = { 9 keys, "" = empty } }.
  - RemoteEvent RemoteEvents.HotbarLayoutSave; the server validates only string length, since this is layout data, not items.
  - On join it sets player attrs HotbarLayout (JSON) and HotbarLayoutLoaded.
  - Saves on leave, on BindToClose and every 120 s. Skips saving if the load failed.
- Client HotbarState:
  - Tool key: ToolKey(tool) is built from whitelisted attrs (Is*, CropType, Star, RodId, BoosterTier, FishId), not Count.
  - Join: AutoAssignNew waits until HotbarLayoutLoaded + InventoryLoaded (+1 s, 25 s timeout), then tryRestore. Saved keys go back to their slots. Every other tool present stays in the bag. With no saved layout, the old auto-assign applies.
  - Memory: `remembered[key]` holds each kind's last slot, or 0 for the bag. A new tool with a known slot goes back to it if that slot is empty.
  - Respawn: in the 8 s after CharacterAdded, a tool remembered as 0 stays in the bag.
  - Sending: syncLayout sends keys when they change and have been stable for 1.5 s. It skips the respawn window.
- Tested in Studio: rod to bag → rejoin → rod still in the bag, other slots the same → death/respawn keeps the layout → rod tab shows the rod. I put the user's Rainbow rod back into slot 5 afterwards.
- Backups *_before_rodtab, HotbarState_before_layoutsave.

Gotcha: require(HotbarState) from execute_luau gives a separate instance. Read the CustomHotbar Slot<i>.CategoryStrip.StripLabel UI to check slots.

Rod look (2026-09-30, user: rods in the 9 slots were too small to tell apart):
- FishingConfig.RodStyle {Strip, Bg} per RodId: Bamboo green, Carrot orange, Kitty pink, Candy red, Rainbow purple.
- Helpers GetRodStyle and RodShortName (DisplayName without the "เบ็ด" prefix).
- CustomHotbar rod slot: strip = the short name, bg = the rod colour, bottom-right badge = rod.Icon (🎋🥕🐱🍬🌈).
- FullInventoryGui rod card: strip "icon + short name" in the rod colour.
- A new rod needs a RodStyle entry, otherwise it falls back to the old blue.
- Backups *_before_rodstyle.

Inventory full width (2026-09-30, user: "เต็มแนวนอน ทุก device"):
- FullInventoryGui.applyResponsiveLayout: width = screen - 24.
- Top = just below the 🎒 button row (promptLabel abs bottom + 6, converted to screenGui space).
- Bottom = above the hotbar (now converted with screenGui.AbsolutePosition too).
- Height max 520.
- Category tabs get UISizeConstraint MaxSize.X = 130.
- Backup FullInventoryGui_before_fullwidth.
- The Studio id changes whenever Studio restarts (2026-09-30 now 68c1ec9b-a00a-4d94-ad9b-414fa71c5a3a). Always call list_roblox_studios after a "not connected" error.

"Use" button model (2026-10-01, user request) — replaces click-to-hold, 🔀 and drag from the inventory:
- FullInventoryGui cards (cell 72x100): a green "ใช้"/"Use" button at the bottom calls useTool → HotbarState.UseTool(tool).
  - The card itself is not clickable or selectable. The gamepad selects the Use button (cardTools maps the button to the tool).
  - When full, a red notice shows in the hint line for 2.5 s via showNotice.
  - Remove an item with × on the slot (as before). Dragging between hotbar slots still works and obeys the rules.
- Slot rules (HotbarState.CanPlaceInSlot):
  - Slot 9 (HotbarState.ROD_SLOT) = rods only, and rods only fit in slot 9.
  - Slots 1-2 = no booster/food/fish/bait (as before).
  - CleanupInvalid relocates misplaced items; with no valid slot they go to the bag. UseTool on a rod replaces slot 9, and if the old rod was held, the new one is equipped.
- CustomHotbar: an empty slot 9 shows a faint 🎣 (rodHint).
- Localization Inventory_Hint was updated (th/en).

Restore rewrite (the same day, after a slow Studio start >25 s made the old code fall back to default and SAVE OVER the layout):
- tryRestore waits only for HotbarLayoutLoaded (30 s) and then fills remembered[key] = slot.
- Join window: until InventoryLoaded + 2 s, max 120 s. During it, new tools go to their saved slot (or the correct slot if the old one breaks the rules, e.g. a rod saved in slot 4), unknown tools stay in the bag, remembered is not overwritten with 0, and syncLayout does not send.
- Verified: layout restored correctly after rejoin.
- Note: live servers running OLD code keep saving layouts in the old format. Rods saved in slot 4 get migrated to slot 9 by the new code.
- Backups: HotbarState_before_usebutton/_before_joinwindow, FullInventoryGui_before_usebutton, CustomHotbar_before_usebutton, Localization_before_usebutton.
- User data check the same day: PetOwnership_v1 intact (all 9 pets, levels fine). A SultanService "ให้มังกร…(saved=true)" log on the slow start was a timing race; nothing was lost.

Purchases go to the bag (2026-10-01, user request): new tools are no longer auto-assigned to the hotbar.
- Buying more of a stack already in the hotbar just raises Count (same Tool) and it stays in the hotbar.
- A known kind (remembered slot > 0, e.g. seeds that ran out and were rebought) still returns to its old slot if free.
- Only exception: the join window of a player WITHOUT a saved layout (new/legacy player) auto-fills as before (autoFill).
- The TutorialGui plant/feed/fish step texts now mention opening 🎒 and pressing "ใช้".
- Tested: giving a Corn seed tool mid-session left the hotbar unchanged and the item went to the bag.

Gamepad (same day):
- Inventory: A on the Use button.
- X = hotbar mode. RemoveSelectionGroup("InventoryGuiSelection"), then AddSelectionParent("InventoryHotbarSelection", hotbar frame), then select the first visible RemoveButton. RemoveButtons are Selectable only while the inventory is open, with a gold ring.
- In hotbar mode: A removes the item; a Heartbeat re-selects the next ×, and when none are left it goes back to the cards. X/B = back to cards; B otherwise closes.
- The hint line switches to a gamepad text when the last input is a gamepad (defaultHint()).
- VirtualInput can't send gamepad buttons, so this is untested in Studio.
- Backups *_before_buytobag, *_before_padremove.

Gotchas:
- script_read returned a STALE FullInventoryGui source that day. Verify with execute_luau Source:find instead.
- Returning a byte-sliced Thai string (src:sub) from execute_luau can hang/timeout (split UTF-8). Return whole lines.

**2026-10-01: the hotbar is now 6 slots (was 9). Slot 6 = rod (ROD_SLOT = MAX_SLOTS).** Earlier notes saying "slot 9 = rod" / "9 slots" are superseded.
- MAX_SLOTS = 6 in both HotbarState and CustomHotbar (keep them equal). Number keys 7-9 are ignored.
- CanPlaceInSlot returns false for index > MAX_SLOTS.
- tryRestore reads all saved keys (old 9-slot saves). Items remembered at 7-9 go to a free valid slot or the bag. A rod saved at 9 moves to 6 (verified).
- The server HotbarLayout still accepts/pads 9 entries (harmless).
- User-facing strings "9 ช่อง" / "ช่อง 9" / "Slot 9" became 6 in FullInventoryGui, Localization and TutorialGui.
- Backups *_before_6slots.

**2026-10-11 — user report: after a server restart seeds in slots 1-2 end up elsewhere, so pets stop planting.** Two holes found (not reproduced live; the user's own saved layout was all 9 slots empty): (1) server HotbarLayout gave up after 3 failed reads but still set HotbarLayoutLoaded → client auto-filled and saved over the layout; (2) client sent the layout from live tools, so tools vanishing at shutdown/respawn saved an empty bar. Fix (not published): server loads with DataLoadRetry.Load, ignores client layouts until loaded, leave-save retries + BindToClose wait + PreRestartSave; client `lateRestore` (wait for a late layout, no auto-fill, no sync) and `ghostKeys` (slot keeps its reserved key when the tool is temporarily gone; cleared by Unassign). Only the normal path + save-on-stop were verified; the simulated-failure run (workspace attrs DevFailDataLoad="HotbarLayout", DevFailDataLoadCount=5) could not be started — rerun it. Test account had no seeds.

Bait in the rod tab (2026-10-02, user: "ย้ายเหยื่อตกปลาให้ไปอยู่ที่เดียวกับเบ็ด"): FullInventoryGui.getCategory returns "rod" for IsBait (it was "fish"). The tab label is now "🎣 เบ็ด/เหยื่อ" (en "🎣 Rods/Bait", Localization Inventory_TabRod). Within the tab rods (no Star) sort before bait (by Star). The fish tab shows only fish. Verified with a temporary ★3 bait x5 (removed afterwards; the account has 0 bait). Backups _Backup_20261001.FullInventoryGui/Localization_before_baitwithrod. Needs Publish. Gotcha for tests: to open the bag in Studio press B (key_code "B"); selecting the 🎒 prompt with GuiService + Return activated a stale selection instead.

**2026-10-18 — rods auto-go to slot 6** (user: new players shouldn't have to open the bag): AutoAssignNew puts an unassigned rod into ROD_SLOT when it's empty (not during join/respawn/lateRestore; skipped if that rod kind is remembered as 0 = player moved it to the bag). Fixes the starter Bamboo arriving after the join window and landing in the bag. Tutorial fish text now says "กดช่อง 6". Tested in Play with a temporary Kitty rod (removed; NightMoth restored to slot 6). Side effect: a veteran who keeps slot 6 empty may get a rod put there after a rejoin. Backups _Backup_20261018.*_before_rodslot6. Not published.

**2026-10-16 — slots 1-2 = seeds ONLY; new seeds go to slot 1/2 first** (user: so new players aren't confused). Supersedes "purchases go to the bag" for seeds only.
- HotbarState.IsSeed(tool) = CropType and not IsProduce and not IsBooster. CanPlaceInSlot(index<=2) returns IsSeed.
- AutoAssignNew: weak table seedCounts[tool]; a seed tool that is new or whose Count rose (buying into a bag stack) goes to the first free of slots 1,2, otherwise the bag. Skipped while joining/respawning/lateRestore so saved layouts still restore.
- CustomHotbar: empty slots 1-2 show a faint 🌱 (reuses the rodHint label).
- TutorialGui buy/plant texts now say seeds are in slot 1/2 (no bag "ใช้" step). Localization Inventory_Hint adds "ช่อง 1-2 = เมล็ด".
- Tested in Play with server-created seeds (Wheat→1, Corn→2, Carrot→bag; Wheat gone + Carrot Count up → slot 1). Not tested: a real shop purchase, dragging a non-seed onto slots 1-2, mobile. Backups _Backup_20261016.*_before_seedslots. Not published.

**2026-10-19 — fix: new players' starter rod never reached slot 6** (user: had to open the bag and press "ใช้"). Cause: the rod arrives inside the 8 s respawn window; the remember loop wrote remembered[rodKey] = 0 (no saved layout → the old `joining and hasSavedLayout` guard didn't apply), and the slot-6 auto step skips kinds remembered as 0. Fix: remember loop now `if slot or not (joining or respawning)`. Verified by a simulation trick: loadstring(HotbarState.Source) + setfenv with a fake `game` (Players.LocalPlayer = table with GetAttribute/CharacterAdded) and fake `os.clock`, then call AutoAssignNew at chosen times — reusable for any hotbar logic test without a real new account. Not tested on a real new account. Not published.


---

## i18n-thai-english

User 2026-10-03: "ปรับให้รองรับหลายภาษา ให้มีแค่ไทยกับอังกฤษก่อน" → answers: language = automatic only (Roblox LocaleId th* → Thai, anything else → English), scope = most visible / new UI first (phase 1).

How it works:
- `ReplicatedStorage.Localization`: existing STRINGS th/en + `GetLanguage(player)`, `T`, `F`; NEW `Pick(lang, th, en)` and `Tr()` (LocalScript helper: `local tr, lang = require(RS.Localization).Tr()` then `tr("ไทย","English")`). Server: `Localization.Pick(Localization.GetLanguage(player), th, en)`.
- Studio-only test switch: attribute `DevForceLang` = "en"/"th" on ReplicatedStorage forces the language (only when RunService:IsStudio()). Set it in Edit BEFORE pressing Play, clear it afterwards (I cleared it 2026-10-03).
- Data modules got `En` fields + helpers: FishingConfig (`FishName/ZoneName/RodName/RodDesc/RodShort/JunkName`, `FormatWeight(id,size,lang)`, fish/zone/rod English names), PetRarity (`NameOf(rarityId, lang)` incl. "Junk"), WarpConfig (`NameOf/DescOf/TitleOf`), CarryConfig (`NameOf`), GachaConfig event `NameEn`. New fish/rods/zones/spots/carry styles MUST get `En`.
- `StarterPlayerScripts.PromptLocalizer` (new LocalScript): English clients rewrite ProximityPrompt ObjectText/ActionText (server prompts are shared, can't be per player) from a Thai→English dictionary + patterns ("ต้นของ X", "เก็บเกี่ยว ⭐"), and the "กำลังพิมพ์..." name-tag row → "Typing...". Add new prompt texts to its OBJECT/ACTION tables.
- ItemFactory tool names (fish/bait/rod) now take a lang (`GetFishName/CreateFishTool/GetBaitName/CreateBaitTool(..., lang)`); callers (InventorySystem, ShopSystem, PetFoodConverter, FishingShop) pass `Localization.GetLanguage(player)`.

Done in phase 1 (client text + server notices): MoreMenuGui, WarpGui/WarpService/WarpConfig, EmoteGui (emote names were already English), PlayerClickMenu, CarryClient/CarryService/CarryConfig, PhotoModeGui, FishingClient, FishingShopGui, FishIndexGui, FishingSystem (notices, announce fish name), FishingShop (messages), FullInventoryGui (rod short name, junk, star notice), CustomHotbar (rod short name), AfkRejoinClient, TutorialGui, PromptLocalizer. Backups `_Backup_20261003.<Script>_before_i18n` exist for 11 of them (not for the later ones).

NOT yet translated (still Thai): GachaGui/GachaService/GachaAnnouncer/GachaShowcaseClient, PetHelperToggleButton (pet menu), PetFoodGui, AutoFeederGui, VipGui/VipService/VipConfig, SultanShopGui, ActivePetsHud, PlantLimitGui, DonationGui partly, PetHungerClient ("หิวจนไม่ทำงาน"), pet names (PetDefinitions DisplayName), TutorialService/AfkRejoin server notices, LevelSystem notices, TypingReporter, WeatherClient/Config texts, MusicPlayer names, GraphicsGui (already has Localization keys), leaderstat names ("เหรียญ" etc. fixed Thai), Roblox game name/description (store page, not code).

Tested in Play with DevForceLang = "en": all phase-1 GUIs show English, prompts translated, no errors in the client/server logs, fish/bait/rod tool names English. NOT tested: a real English-locale account, server notices triggered by real actions (warp cooldown, carry requests…), phone layout (English strings are longer: check cards/buttons for overflow on phones).

Gotchas:
- MoreMenuGui's i18n edit was lost once (the file reverted to Thai) and had to be redone — re-check it after any Studio reconnect.
- execute_luau sometimes times out right after big script edits; retry with a trivial call first.
- LESSON: in a Play test with the real account, don't Destroy() a tool returned by ItemFactory.GiveX — it may be an existing stack (I destroyed the user's 319 two-star bait stack and had to recreate it with GiveBait(p, 2, 319) before stopping Play; inventory saves on exit).


---

## island-rebuild-plan

2026-10-13: the user sent an illustrated top-down map and chose to **rebuild the whole island to match it** (my option C, which I had advised against). Analysis only so far; nothing was changed in Studio.

User decisions (their words, 2026-10-13):
- Fishing shop: move again to the corner as in the picture (even though they moved it to the boxing ring on 2026-10-12).
- Plots: "ลบไปก่อนให้เหลือแค่ 10 แปลงหลักไปก่อน" — keep only 10 main plots for now.
- No in-game map image needed yet.

FINAL ORIENTATION (2026-10-13, from the user's own top-view screenshot — supersedes both paragraphs below): **picture top = +X** (grey mountain top-left, river/waterfall coming down into the central canal), picture right = +Z, picture left = −Z, picture bottom = −X (lake end). The island is a peninsula with sea on three sides, like the picture, so NOTHING is cut to sea; the whole interior (all plots 1–21, 53/54, beach and terrace soils, animal pen, windmill, sunflowers, sala) is cleared and re-laid. Blockout v2 in `workspace._IslandBlockout` (40 parts): moat x −196..12, z −216..256; islands 80×72 (soil 68×60), top row x −72..0 = plots 1–5 from −Z to +Z, bottom row x −184..−112 = plots 6–10, causeway x −100..−84; seed shop x 28..76, z −180..−90; fishing shop x 28..76, z 110..200; river in = top of the old central canal (z −64..−32); canal fishing pond x −330..−236, z −130..190; sea pier z 340..440 at x −120; new stream hill x −200..−60, z −310..−250. To capture in the user's orientation: camera slightly at −X of the target (e.g. cam (−131,640,30) look (−130,0,30)). LESSON: ask for / take a top view in the user's orientation before mapping a concept picture.

ROUND 1 BUILT 2026-10-13 (Studio only, NOT play-tested — I did not start Play because of [[live-session-overlap]]; not published):
- User tweaks: fishing shop flush right on the beach; no new stream hill (use the existing terrace stream).
- Backup `ServerStorage._Backup_20261013_IslandRebuild`: `Terrain_island_before` (PasteCorner −112,−10,−88), OldPlots (35), FarmDressing, FarmFlora/Lights/FarmProps/Tree/Scenery items, Loose, `_IslandBlockout`, `WarpConfig_before_rebuild`; moved instances carry `OriginalParent`; moved shop items carry `PosBeforeRebuild`.
- New `FarmPlot1`–`10` (Soil 60×68, top y 4.2; 18,000 slots), moat/paths/pond terrain, `workspace.FarmBridges` (12 planks), seed shop at (58,−135) facing −X with spawn (34,−135), gacha (46,−162), pet food (46,−106), boards along x 66; fishing shop (52,300), craft bench (52,272). WarpConfig shop/fishshop/canal updated.
- TERRAIN FACT: a full-occupancy top voxel renders its surface 2 studs ABOVE the cell top (cell 0..4 full → surface y 6). Surface ≈ cellBottom + 4·occ + 2, so occ 0.5 gives y 4; bank cells next to water use 0.3 (≈ y 2.8). Put Ground (not Grass) under Soil parts or grass blades poke through.
- Studio tool timeouts: `game:GetDescendants()` and very high top-down captures (cam y 600) time out; keep calls small.
- Left to do: sea pier + lighthouse, pond docks/sala, fences/trees/flowers/lanterns around plots, zone signs, Halloween decor re-layout (still on the old layout), AmbientCritters coordinates, cleanup of leftovers outside the zone (old animal-pen plateau, sunflower field, sala, LakeDock), tutorial text check, Play test of plots/warps/fishing zones.

ROUND 2 2026-10-13: user said keep ONLY the sala and the lake dock among the leftovers, and "all island water must be canal, not lake" → FishingSystem.getZone no longer returns "lake" for LAKE_CENTER (hill mist lake still "lake"; backup `FishingSystem_before_rebuild`). Sunflower field + old animal-pen plateau removed/flattened. One short Play test (user said OK): server enabled 10 plots, no script errors, all 6 warp spots have ground and the 4 fishing spots have water in range. Real planting / fishing / menu warp still untested. Each new plot = 40×45 = 1,800 slots.

ROUND 3 2026-10-13 (decor, Studio only): `workspace.IslandDecor` = PlotFences + PlotNumbers (370 non-colliding parts), SeaPier (2 LakeDock clones at x −120, z 352..422 + Lighthouse), PondDocks (2 docks z −105 / 130 + PondSala at −222,60), ZoneSigns (4 TerraceSign clones, Thai/English). 26 trees + 20 shrubs back from the backup into workspace.FarmFlora; 23 lanterns in workspace.Lights (attr IslandRebuild). Still open: Halloween decor re-layout (some old pieces sit on the new soil), AmbientCritters coordinates, stream/mountain signs, walking test in Play.

ROUND 4 2026-10-13 (Halloween re-layout, set still OUT in `Workspace.Halloween2026` — see [[seasonal-events]]): ShopArea + ShopExtra moved with the seed shop (20 kept), SouthBeach shop pieces (10) moved with the fishing shop to the right beach, ring pieces left. Stashed to `_Backup_20261013_IslandRebuild.Halloween_removed` (attrs OriginalParent, CFBeforeRebuild): SpawnExtra 16, old FishingArea 23 + FishingExtra 25 (my call — the user had never been asked about those orphans), Scattered 9 + FarmExtra 36 inside rebuilt areas, 3 shop pieces. Added 33 pumpkins (new lantern bases + one per plot gate) to Extra.FarmExtra. The runtime plot-edging skin now has nothing to skin (FarmDressing.RaisedBeds is gone). Not asked/unknown: whether the user's earlier "publish เรียบร้อย" today went out with the set in Workspace.

ROUND 5 2026-10-13: Halloween set put back to ServerStorage (user: "เก็บกลับก่อน"). AmbientCritters butterflies → plot corners, firefly zones → pond / moat / river-in (backup `AmbientCritters_before_rebuild`). Stream + Mountain signs added. Play test: real WarpRequest to shop/fishshop/canal/stream lands correctly; FindSoilAt/GetNearestSlot/GetSlotSurfacePoint pass on all 10 plots; SeasonalDecor spawns from storage, 23/23 new lanterns skinned. STILL UNTESTED (ask the user to try): real planting/harvest, real fishing in moat/pond (zone label), climbing out of the moat (bank ≈ 2.8 above water), mobile. Nothing published.

2026-10-13 plaza (user: brick floor + a bit wider): seed-shop plaza is now Brick terrain x 24..88, z −228..−84 (12 studs of the canal behind the shop filled); shop stall row + boards moved +8 X (stall now ≈ x 66–70), stored Halloween shop pieces with x ≥ 50 moved +8 too.

2026-10-13 later: user asked for the terrace plots back → `FarmPlot22` (19 soils, 1,632 slots) restored from OldPlots into workspace.FarmPlots (11 plots total now); StreamSign moved to (176,116). Also filled leftover old-canal water the user circled (puddle at −242,198; strip x −256..−248, z −240..−132). After a rebuild, scan for isolated water components and old side-canal stubs before showing the user.

2026-10-13 terrace slope (user circled the bare slope between the upper terraces and the pond-row soils): 3 new treads cut + 3 soils added to FarmPlot22 (attr `AddedSlope20261013`): 28×12 at (256,208) y 30.4, 16×12 at (214,208) y 18.4, 28×8 at (260,186) y 38.4 (+314 slots → 22 soils, 1,946 slots) with 12 Levee parts; terrain backup `Terrain_terrace_slope_before` (PasteCorner 48,0,43). Terrace treads = top voxel cell FULL (surface = cell top + 2), soil part 2 thick with top 0.4 above the tread, levees 0.8 wide × 1.4 high Grass parts around each soil. Walking up to the new treads not tested.

GOTCHA 2026-10-13: `FarmFlora.Flowers.WildflowerPatch` models have a pivot far from their mesh, so pivot-based area filters miss them (user found flowers left on plot 5; 110 stashed to `FarmFlora_zoneLeftovers`). Filter decor by a BasePart position, not GetPivot. Decor is CanQuery=false, so GetPartBoundsInBox does not see it either. The user also hand-moves things in Studio between my turns (FarmPlot5 Soil was at y 4.5, not my 3.7) — re-read positions before editing.

2026-10-13 beach plots back (user: "ให้หาดทะเลปลูกพืชได้เหมือนเดิม"): FarmPlot55–62 restored from OldPlots (19 plots total: 1–10, 22, 55–62; beach 4,094 slots, YieldMult 0.8). Sand re-raised to y 6 over 61/62; FarmPlot60 split into 2 Soils around the sea-pier ramp (x −127..−113 free). The user has hand-edited ZoneSigns: only SeedShopSign (73,−139), FishShopSign (45,270), CanalSign (−226,−14) remain — the sea / stream / mountain signs were deleted by the user, do not re-add.

2026-10-13 fountain (user asked for a pretty, cute one in the river-in next to the plaza): `IslandDecor.Fountain` at (54,−48), part-built 3 tiers cream/pink, 3 ducks + 6 lotus from ServerStorage.FarmFlora templates, 3 ParticleEmitters, `FountainSound` (9119646672) in NatureSounds. Particles/sound not checked in Play.

2026-10-13 beach stage (user: "เพิ่มเวทีร้องเพลงตรงหาดนี้ ลานบาร์"): `IslandDecor.BeachStage` (119 parts, part-built pastel): Stage x 118..134, z −387..−357 facing −X (sea), DanceFloor, Bar at (104,−338), 5 parasol tables, 20 Seats, 4 torches. Decor only — no music/karaoke system yet (possible phase 2). PoolSet was moved by the user to (43,−332).

2026-10-13 windmill landmark (user: "เพิ่มกังหันลม น่ารักๆ สำหรับเป็นแลนด์มาร์กถ่ายรูป" with a screenshot of the open lawn): `IslandDecor.CuteWindmill` at (−278, 244) (lawn between the pond end and the beach; the user's screenshots of that corner have image-left = +X, up = +Z). AI mesh with explicit parts "tower, blades" (generate_mesh partNames) so the blades can spin: `StarterPlayerScripts.WindmillSpin` rotates parts tagged `WindmillBlades` about their own centre (attrs SpinAxis, SpinSpeed). Scaled to ≈27×38×21, 12 wildflower patches ringed around it. The old realistic Windmill (215 parts) is still in the backup `Loose` folder, not used. The user has also reshaped the pond/moat since round 1 (pond now x −320..−240, z −128..192) — re-survey before placing things.

2026-10-13 windmill REDO: the first windmill, its flower ring and the WindmillSpin script vanished from the place (the user undid them) and the user sent a ground-level view from the pond side looking out to sea / the lighthouse: "ทำใหม่ให้หันมาตรงประมาณนี้". New `IslandDecor.CuteWindmill` at (−252, 256), regenerated mesh scaled 1.9 (≈35×46×27), front facing the viewer spot (−264, 200), set left of the sight line so the lighthouse (user moved it to (−298, 446)) stays in frame; WindmillSpin recreated; 12 flowers ringed. The earlier position (−278, 244) / facing in the paragraph above is superseded. To match a user's Studio view, read `workspace.CurrentCamera.CFrame` in Edit.

2026-10-13 windmill clipping (user: "กังหันไม่สมจริง ทะลุ"): the AI "blades" part sat ~4.5 studs inside the tower, so spinning swept it through the walls. Fixed by moving the blades 5.5 studs out along the spin axis + a wooden `Shaft` cylinder, SpinSpeed 22 → 14. LESSON for any spinning AI part: before animating, test the swept poses — set both parts to PreciseConvexDecomposition, rotate the part through 24 angles and call `workspace:GetPartsInPart` (old pose 24/24 hits, new 0/24); find the hub with raycasts (most-forward hit points) instead of assuming the bbox centre. The user also moves the windmill by hand (tower was near z 285 by then).

SUPERSEDED — earlier wrong attempts kept for history. ORIENTATION (corrected 2026-10-13): my first "rotate 180°" mapping was WRONG. A Studio top-down capture with screen-up = +Z shows −X (sea) on the RIGHT, so the picture maps directly: picture top = +Z, picture right = −X. I had told the user "cut the north half"; the half that is really cut is the −Z side (FarmPlot10–21). Don't call directions north/south/east/west with the user — say "ฝั่งร้านค้า" (+Z) / "ฝั่งแปลงเล็ก 2 แถว" (−Z).

Layout in `workspace._IslandBlockout` (43 flat marker parts, delete before publish): moat x −356..52, z 8..140; 10 islands 72×44 (soil 64×36) in 2 rows (z 88..132 = plots 1–5 from +X to −X, z 16..60 = plots 6–10), causeway z 68..80; seed shop area x −30..50, z 164..216; fishing shop x −310..−230, z 164..216; canal fishing = existing central canal z −80..−16; land strip to z −144, new beach to −176, sea beyond (x −400..80); sea pier at x −500..−404, z 60..72.

More user decisions 2026-10-13: cut to sea as in the picture; pending work was published and backed up by the user; rebuild BEFORE Halloween.

Risk checks done: LastPosition.checkSpot falls back to the normal spawn when the saved spot is water/no ground; scarecrows are runtime only (expire 5/15 min); crops are not saved. FishingSystem.getZone uses ServerStorage templates `SeaMask` (must be regenerated after the cut), LAKE_CENTER (−398,−50) r 50, surfaceY > 2 = stream, else canal — new moats at sea level count as canal.

Survey facts: island flat area x −384..96, z −272..304; east canal x 80..112; soil area share north1–9 45%, south10–21 25%, beach55–62 13%, extra50–54 12%, terrace 5%; GridSpacing 1.5; BASE_PLANT_LIMIT 10. Scripts find shops/machines by name; hardcoded coordinates only in WarpConfig (6), AmbientCritters (19), TrashEventConfig (2). Plot names are referenced in TutorialGui (FarmPlot3, RestSpots.LakeDock), FarmGridConfig (FarmPlot50–52), PlantingSystem (FarmPlot55).

Not yet checked: whether placed scarecrows save a position, how FishingSystem decides the water zone, LastPosition behaviour when the saved spot becomes sea.

**How to apply:** move removed things to ServerStorage backups, never destroy; save a copy of the place file before starting. Related: [[warp-menu]], [[rotated-plots]], [[terrace-zone]], [[sea-and-beach]], [[seasonal-events]], [[last-position]].


---

## last-position

ServerScriptService.LastPosition, DataStore "LastPosition_v1" {x, y, z, yaw}:
- Every 5 s it keeps the last SAFE HRP position (FloorMaterial not Air/Water, not Swimming/Freefall/Jumping, not Sit, alive, |x|,|z| < 1100, -20 < y < 400).
- It saves on PlayerRemoving + BindToClose.

On join, only the FIRST character is moved (death/Reset = normal SpawnLocation at -94, 1.5, 39):
- Wait up to 10 s for the load.
- Skip if within 15 studs of spawn.
- checkSpot: a raycast down from +4 must hit within 14 studs, not terrain Water, with no collidable part within 5 studs above.
- Then player:RequestStreamAroundAsync (StreamingEnabled) → PivotTo with the saved yaw, plus a notify saying Reset goes back to spawn.

Later changes (verify in the script):
- 2026-10-10: death/Reset also respawns at the last safe spot (`st.last`); a second Reset within 15 s (RESPAWN_ESCAPE) = normal spawn.
- 2026-10-11 (user: changing avatar in-game sometimes spawns at the wrong place): CharacterRemoving checks whether the old character died. Not dead (avatar switch / LoadCharacter) = sample the spot right then, respawn there, no notify, not counted for the Reset-twice escape. `st.placing` blocks sampling while a character is being moved. Tested only with `LoadCharacter`; NOT verified with the real Roblox avatar switcher (if it kills the humanoid first, the escape rule still misfires). Not published.
- 2026-10-11 (user: dying in water sent him to spawn): death while in water (swimming, or terrain water at the body) → `nearestPlotSpot` = edge of the nearest `workspace.FarmPlots.*.Soil` (3 studs in, facing the water), tries 4 plots, falls back to `st.last`. Tested at 2 canal spots; not published.
- 2026-10-11 user report (live): after an avatar change + respawn some players can't see others / themselves ("loads too late"). Could NOT reproduce in Studio; no script hides characters. Mitigations (unverified, not published): respawn placement skips `RequestStreamAroundAsync` when the old character was within 120 studs of the target (`st.prevCharPos`, `STREAMED_NEAR`), and new LocalScript `AvatarPreload` (ContentProvider:PreloadAsync on every character). If the report continues, next idea = per-player RespawnLocation so the character never appears at the spawn point first.
- **2026-10-12 — second live report** (avatar change → spawn point / no auto-respawn / others can't see the switched player / can't see self). Facts: Roblox's in-experience Avatar Switcher works by RESPAWN, so the character really DIES (my 10-11 "not dead = avatar switch" assumption was wrong; that branch only covers LoadCharacter); the player can also choose "apply on next respawn" (likely the "doesn't respawn by itself" report). The old "Reset twice within 15 s = spawn" rule therefore sent quick double switches to the spawn point.
  Rewrite (not published): per-player invisible `SpawnLocation` in `workspace.PlayerRespawnSpots` (`Spot_<UserId>`, Neutral=false, TeamColor = player's → neutral players never pick it; verified) + `player.RespawnLocation`, updated by the 5 s sampler (`spotFromLast`) and at death (`decideRespawn`). The character now appears at the right spot from the first frame; PivotTo is only a fallback when it lands >12 studs away (`SPAWN_MISS`). Character root spawns ~3 studs above the part centre (`SPOT_DROP`), facing the part's LookVector. `RESPAWN_ESCAPE` 15 → 6 s. First character on join still uses the old PivotTo path. Invisible-character cause still unknown — check live after publish.
- **2026-10-18 third report** (avatar change → sometimes spawn point, sometimes a spot from hours ago). Cause: respawn used `st.last`, sampled only while standing on solid ground; riding a mount (RidingMount attr) / sitting / jumping for a long time froze it. Fix (not published): `groundUnder(character, pos, yaw)` = raycast 60 studs down (RespectCanCollide, all characters excluded so mounts welded in the character are skipped, not water, 5-stud headroom). decideRespawn now uses ground under the DEATH position first (non-water deaths), then st.last. safeSample uses groundUnder when riding/sitting/airborne (swimming still skipped). Verified in Play: stand at A 7 s → move to B → die within 1 s → respawned exactly at B. Backup _Backup_20261018.LastPosition_before_groundunder.
- Play tests here overwrite the user's own LastPosition_v1 key and DataStore writes from Edit-mode execute_luau get denied by the permission classifier — snapshot can't be restored; warn the user.

Tested 2026-09-30:
- The sala spot (-330, 8, 60) restored with the correct facing.
- Reset → spawn.
- A sea spot → rejected → spawn.
- Pets follow (2.9–5.5 studs).
- The user CONFIRMED it works on the live server (2026-09-30).
- The user's test key was removed afterwards (clear with RemoveAsync while Play is stopped: the BindToClose save can race a clear done right after stopping).
- **2026-10-19 fourth report** (same symptoms). Fix (not published): `spotAt(character, pos, yaw)` = groundUnder with lowOk (no headroom check) → inWater → nearestPlotSpot → raw position; used for non-water deaths (skips checkSpot) and the not-died CharacterRemoving branch when safeSample fails (boat/AFK fishing on water was the likely "hours-old spot" cause). Escape rule now has an exception: Died stores `st.deathLook = lookSignature()` (HumanoidDescription ids); if the escape fires but the new character's look differs (after HasAppearanceLoaded, ≤6 s) → PivotTo `st.escapeAlt` (quick avatar switches). Tested in Play with LoadCharacter at sea/mid-air and CharacterAppearanceId = 1 to fake a look change; quick same-look resets still escape. Real Roblox avatar switcher still untested. Backup _Backup_20261019.LastPosition_before_avatarspot.


---

## level-board

User request 2026-10-13: "ทำบอร์ดเลเวลสูงสุดในเซิฟ สีเขียวอ่อน". I asked whether "ในเซิฟ" meant the current server (A) or the whole game (B); the user answered **B = whole game, all servers**.

- Model `workspace.LevelBoard` at (73.7, −224) on the seed-shop plaza, next to PlaytimeBoard (−200) and DonorBoard (−176), same facing: a recoloured clone of PlaytimeBoard without its Clock (frame 126,214,160; header/caps/scallops 176,236,196; screen 232,252,240). The brick plaza was extended to z −240 for it.
- Script `ServerScriptService.LevelBoard` (copy of the PlaytimeBoard pattern: SurfaceGui built at runtime on `Screen`, 10 rows, refresh 60 s). It owns its data: OrderedDataStore `LevelLeaderboard_v1` (key UserId, value level), written from the script itself every 120 s when the level changed and on PlayerRemoving, only when player attr `LevelDataLoaded == true`, via UpdateAsync that never lowers a value. LevelSystem was not touched.
- The board only knows players who joined after it shipped. Banned players cannot join, so they never appear; a cheater who is not banned would — there is no exclude list yet.
- Tested in Play: row "🥇 OneMore ⭐ Lv. 494", store value 494 (this wrote the owner's real level into the real store). Not seen by eye, not tested with several players.

- 2026-10-13: topper `LevelBoard.OtterMascot` (user: an otter farming + fishing, like the Clock on PlaytimeBoard): one AI mesh from generate_mesh (segmentation none, maxTriangles 8000; straw hat, rod with fish, carrot, basket), scaled 1.25, sits 0.3 into the HeaderBar. generate_mesh returned "Request timed out" but the model WAS created at the workspace root named after the prompt — look for it (tag AssistantAIGeneratedAsset) before retrying. This mesh's front was the opposite of its pivot LookVector: check by screenshot and rotate.

Related: [[level-load-guard]], [[cheat-watch]], [[ban-system]].


---

## level-load-guard

Fixes the incident in [[photo-mode]] (level 161 overwritten by a default level 1 after a failed load). User said "จัดไป" on 2026-10-03, so I did it directly instead of the spawned chip task (task_66b934e6 is now redundant — ignore/dismiss it).

`ServerScriptService.LevelSystem` (ModuleScript):
- `loaded[userId]` is set only after a successful DataStore read (an empty result = real new player, also counts). Until then: `AddXP` does nothing, `savePlayerLevel` is skipped with a warn.
- `loadPlayerLevel` retries forever: waits 2·n s for the first 5 tries, then every 15 s; the player stays at the default level 1 meanwhile and snaps to the real level when a read succeeds.
- Save uses `UpdateAsync` and refuses to write when the stored Level is higher than the one being saved (levels never go down normally). If you ever need to LOWER someone's level on purpose, write the store directly (not through this module).
- NEW: autosave every 120 s for loaded players + `BindToClose` save (before, only PlayerRemoving saved).
- Studio test switch: attribute `DevFailLevelLoad = true` on ServerScriptService simulates a failed read (clear it afterwards; cleared 2026-10-03).
- Verified in Play: with the failure switch on, level stayed 1; switching it off → ~10 s later level 165 loaded; after a whole Play session with failing loads the store stayed {Level 165, XP 13531} (not overwritten). Backup `_Backup_20261003.LevelSystem_before_loadguard`. Needs Publish.
- Other stores with the same pattern (default on failed load, then save over it) were NOT audited: PlayerInventory_v1 (InventorySystem restore just returns on failure but saves on exit — a failed load + exit would overwrite the bag with an empty one!), FishingShop_v1, PetFoodConverter_v1, GachaTickets, HotbarLayout, FishIndex etc. Worth checking next.

AUDIT 2026-10-04 (user: "ตรวจกระเป๋าไอเทมและระบบเซฟอื่น"):
- FOUND + FIXED `InventorySystem`: a failed GetAsync was ignored, but the bag was still saved on exit/every 5 min → real bags overwritten with an (almost) empty one. Now `invLoaded[player]` (set only after a successful read) gates saves; load retries 4× then every 15 s in the background and gives the stored items back when it finally succeeds (`InventoryLoaded` attr is still set after the first attempts so other scripts don't wait). Studio switch: attribute `DevFailInventoryLoad = N` on ServerScriptService = next N reads fail (cleared 2026-10-04). Verified: 4 failed reads → later the 40 stacks came back; 100000 failed reads → no new DataStore version was written on exit. Backup `_Backup_20261004.InventorySystem_before_loadguard`. Needs Publish.
- Already safe (guarded by loaded flags / UpdateAsync merge): PlayerCoins (LeaderstatsSetup `coinsLoaded`, but no background retry: after 3 failed reads that session's coins are never saved), PetFoodConverter, FishingShop (union UpdateAsync), AutoFeeder, HotbarLayout, PetSettings (PetManager), PetOwnership, GachaTickets / FishIndex / PlaytimeRewards (UpdateAsync), TutorialService (not published when load fails).
- Version-history scan of PlayerInventory_v1 (8 keys): bag wipes found — 11645900198: 62→1 entries on 10-01 17:45 UTC; 11646315279: 18→3 on 09-30 21:43 and 63→1 on 10-03 11:56; the owner's account (9360333174): several earlier wipes 09-18/09-19/09-22 and a 93→2 at 10-03 16:57 that the live session overwrote back at 17:55 (probably fine). Restoring other players' bags (merge the pre-wipe version into the current one) NOT done yet — waiting for the user's decision; do it only after Publish (a live session overwrites with its in-memory bag on exit). Also level drop for 11646315279 (21→4 on 10-03 13:53 UTC, now ~16) — restore XP total ≈ level 26 XP 220 not done yet.

2026-10-04: the user published the guard and had a_valinnn (UserId 11646315279, display name VanillaMochi) leave/rejoin. User decision: compensate with LEVEL 30 (instead of my computed L27 XP 1138). Wrote {Level 30, XP 0, Restored = true} to PlayerLevel_v1 via UpdateAsync (was L17 XP 1642). He was online in a session holding L17 in memory; the new guard refuses to save a lower level, so he gets L30 when he rejoins. A first attempt was blocked by the permission classifier (writing another player's DataStore) until the user explicitly confirmed. His bag (63 entries wiped on 10-03 11:56 UTC) is NOT restored yet: do it only when he is offline (live session overwrites the store with its in-memory bag). Same for newbierainnii (62→1 on 10-01) if the user asks. Check afterwards that his level is still 30 (an old-code server would overwrite it).

PENDING / TO REMEMBER (written 2026-10-04 at the user's request "จดไว้เลย"):
1. a_valinnn (11646315279): level set to 30 (done). TODO when he is OFFLINE (no new coin/inventory saves for >10 min): restore his bag — merge the last PlayerInventory_v1 version before the 63→1 wipe (10-03 ~11:56 UTC, version just before it has 63 entries) into the current bag (add counts per kind + fishId/cropType/star/tier; rods/starred keep one). Ask the user before writing. Afterwards re-check his level is still 30.
2. newbierainnii (11645900198, RainBerry): bag 62→1 on 10-01 17:45 UTC, current 12 entries, level 51 — NOT compensated; ask the user whether to restore/compensate (he has been offline since 10-03 18:22 UTC).
3. Coins: LeaderstatsSetup has no background retry (after 3 failed reads that session's coins are not saved) — optional improvement.
4. Writing other players' DataStore data needs the user's explicit OK in chat each time (the permission classifier blocks it otherwise).
5. The InventorySystem + LevelSystem guards were published by the user on 2026-10-04.

2026-10-07 (user): all pending items above are CLOSED — the user restored a_valinnn's bag, decided newbierainnii, and fixed bigboon654's level themselves. Nothing left to do there. Language phase 2 (gacha/pets/VIP/Sultan) is on hold until the user brings it up. CHANGELOG.md backfill for the 2026-10-03/04 work (i18n phase 1, 10-rider carry, always-on Lucky + auto-enable pet abilities, Level/Inventory load guards, a_valinnn L30 data write) was offered but not yet answered.


---

## live-session-overlap

The user sometimes AFK-fishes in the published game (same account, UserId 9360333174) while I work in Studio. Found 2026-10-01: during a FishIndex test the stored record kept changing (lake fish counts rising, petReward flipped back to true, a new GiantCatfish) because a live server was saving every 60 s.

**Why:** a snapshot → SetAsync(test record) → Play → SetAsync(snapshot) cycle can overwrite newer live data, and a Studio Play session loads/saves the same keys as the live session. This time nothing was lost only because FishIndex saves merge (max counts, OR flags) from the live server's memory.

**How to apply:**
- Before a DataStore-editing test, read the key twice ~70 s apart (or compare `DataStoreKeyInfo.UpdatedTime` with os.time). If it changes, the user is live: avoid writing that key, or ask them to leave the live game first.
- Prefer tests that don't rewrite the user's records (Dev* attributes, read-only checks).
- Never restore an old snapshot over a key that a live session is updating, unless the store merges.
- Pet state seen in Studio (active pets, ability toggles) may differ from what the user has live.
- 2026-10-09: I started a Studio Play (AutoFeeder UI test) while the user was live on ff93be56 even though I had checked. Play is NOT read-only: pets auto-harvested, the otter fished (v2 fish via DevFishV2) and the leave-save at 22:38:38 wrote coins/level/inventory/FishIndex/PetSettings/converter/playtime/LastPosition. If the user is live, do NOT start Play at all — test UI with fake client data or ask them to leave first.
- 2026-10-15 INCIDENT: the owner's bag (PlayerInventory_v1 9360333174) was wiped to rods + 16 fish by a LIVE leave-save at 13:57:49 UTC, right after a Studio Play session (13:49–13:53, probably the mount-gacha session's tests) — Studio Play sessions on the owner's account alternated with live sessions all afternoon (DisconnectLogs_v1 "u<id>" shows each session; jobId "" = Studio). Restored from the 12:55 version merged with current at 14:14 UTC after the user left the game. DataStore keeps only ~1 version per hour per key, so writes inside an hour are lost. Lesson: InventorySystem uses SetAsync of the in-memory Backpack, so ANY session whose Backpack lost tools (Studio tests, deaths without Died, etc.) overwrites the real bag; don't Play-test on the owner's account while they are live, and check the bag summary after test sessions.


---

## loadcharacter-bag-wipe

2026-10-15 root cause of the owner's bag wipe (see [[live-session-overlap]], [[level-load-guard]]): a Studio Play test (PlayerCleanup work) ran `plr:LoadCharacter()` on the owner's character. LoadCharacter does NOT fire Humanoid.Died, and Roblox destroys all Backpack tools + replaces the Backpack BEFORE CharacterRemoving fires, so InventorySystem has no snapshot. FishingShop re-gives the owned rods → bag = rods only → leave-save wrote it. Reproduced on a fake key.

**Why:** InventorySystem SetAsyncs whatever is in the Backpack; any respawn without Died silently empties the saved bag.

**How to apply:**
- Never call LoadCharacter / replace the character in Play tests on a real account; kill with `Humanoid.Health = 0` instead (Died path restores).
- Studio switch `workspace.DevInventoryKeyOverride` (string) = fake PlayerInventory_v1 key. Set to "InvTest_20261015a" (copy of the real bag) on 2026-10-15 and LEFT SET so Studio Play can't write the real bag; clear it before Publish? (Studio-only, harmless live).
- BOTH GUARDS BUILT 2026-10-15 (user: "2เลย"), Studio only, not published: InventorySystem hookContainer/onToolLeft (0.5 s re-check: source container replaced → respawnLost → given back 1 s after CharacterAdded unless a Died snapshot exists; else → explainedLoss) + Count-decrease tracking; checkShrink before save: unexplained loss ≥ 50% of last saved (≥ 20 items, rods excluded) → no save, attr InventorySaveBlocked, log DataStore InventoryGuardLog_v1 (u<id> / studio:u<id>). Studio test switch ServerScriptService.DevSkipRespawnRestore. Verified on fake key (restore, real death no dupes, legit destroy saves, wipe blocked incl. leave-save). Watch after publish: any InventoryGuardLog_v1 entries = a legit bulk removal the tracker misses, or a new wipe cause.
- 2026-10-15 14:45 I started Play while the user was live (joined 14:32) — check DisconnectLogs right before EVERY Play, not once per task.
- Coins 59.6m → 36.8m in the same hour: not explained, not caused by LoadCharacter.


---

## luck-balance

2026-09-30, user: "หุ่น x100 เป็น 50x และ หุ่น 50x ปรับเป็น 20". Only the LuckConfig values changed:
- BoosterTiers.x50.Luck is now 20 (coin straw scarecrow, 500 coins, radius 15, 5 min).
- BoosterTiers.x100.Luck is now 50 (Robux golden clover, radius 30, 15 min).
- DEFAULT_BOOSTER_LUCK is now 20.

Seen 2026-10-13: `BoosterTiers.x100.Luck` is 100 in LuckConfig (changed back from 50 at some point, not by me in a remembered session); x50 tier still 20.

The tier ids "x50" / "x100" are internal keys saved in player inventories (BoosterTier attr). They were NOT renamed.
- All UI text reads Luck from config via Shop_BoosterInfo / QuickShop_LuckDesc.
- Only SultanService's bundle notice had a hard-coded "x100"; it now reads the value.

5★ quality chance: x1 3%, x20 20%, x50 30%, x100 37%.

Pet luck (2026-10-01, user: "จิ้งจอกเก้าหาง 20 → 40, มังกรแดงสุลต่าน 20 → 40, ตัวอื่นเหมือนเดิม"):
- Set as explicit `Luck = 40` on NineTailFox and SultanDragon in PetDefinitions. LuckConfig.PetLuckByRarity was NOT changed (Secret 20, Sultan 20, Legendary 10, Rare 5, Common 2), so a future Secret pet still defaults to 20.
- Hard-coded "นำโชค x40" text: both pets' Description in PetDefinitions and the dragon perk row in SultanShopGui. Other displays read def.Luck.
- Real pet luck = def.Luck × hunger% summed over active pets with Lucky on (player attr PetLuck); Combine adds scarecrow luck, then ×2 for IsSultan. Verified live: fox + dragon + rabbit at ~83% hunger = 68.6, final x137.
- Later the same day the user raised SultanDragon again: 40 → 50 (fox stays 40). Text "นำโชค x50" in its Description and SultanShopGui. Verified by requiring a clone of PetDefinitions in Edit (no Play, see [[live-session-overlap]]). Backups *_before_dragon50. Needs Publish.
- 2026-10-02 (user): NineTailFox 40 → 30 (explicit `Luck = 30`, text "นำโชค x30"), and the whole Legendary tier 10 → 15 via `LuckConfig.PetLuckByRarity.Legendary = 15` (NineLivesCat, WhiteTiger, Otter; texts "นำโชค x15" in their PetDefinitions descriptions/comments and the FishIndexGui otter card). Current pet luck: dragon 50, fox 30, legendary 15, rare 5, common 2. Verified by source grep only (another session was toggling Play in the same Studio, so execute_luau timed out and an Edit-mode clone-require returned stale values). Backups _Backup_20261002.*_before_fox30 / *_before_legend15. Needs Publish.
- Backups: ServerStorage._Backup_20261001.*_before_luck40.
- The user published and confirmed it works on 2026-10-01 (this publish also carries the gifted VIP for a_valinnn, see [[vip-title-system]]).
Backups: _Backup_20260930.*_before_luckbalance. Related: [[sultan-pack]] (the bundle gives 3 x100-tier scarecrows, luck 50).

Gift "หุ่นทองคำนำโชค" (x100 booster) (2026-10-02, user: "ทำส่งของขวัญหุ่นทองคำนำโชคต่อ"). **The gift product id is SET: 3715868092** (`LuckConfig.BoosterTiers.x100.GiftProductId`, given by the user 2026-10-02 after I refused to reuse the self-purchase ProductId 3714157810; the gift page showed R$ 25 per friend; NOT live-tested). If it is ever 0, the 🎁 buttons are hidden in the live game and only appear in Studio (simulated).
- ServerScriptService.LuckBoosterGift (Script): RemoteFunction RemoteEvents.LuckGiftRequest ("giftSelect", targetUserId); DataStore "LuckGift_v1" with `inbox_<targetId>` {count, delivered, receipts, fromName} and `pending_<buyerId>`; PurchaseRouter.Register(GiftProductId, grantGift).
- It is an ITEM, so it goes through a mailbox: the grant increments the target's inbox (UpdateAsync, receipt "gift_<PurchaseId>" deduped), then `deliver(player)` waits for the target's InventoryLoaded and does an UpdateAsync that sets delivered = count BEFORE ItemFactory.GiveBoosterTool(player, n, "x100") (record first, then give, like SultanService.claim). deliver also runs at join, so a target who left still gets the item next time. Gifts stack into one tool.
- The target must be in the same server with InventoryLoaded set; no "already has" rule; self-gift is rejected.
- UI: VipGui GiftPage kind "luck" (BindableEvent OpenLuckGift); a 🎁 pill on the QuickShop LuckBoosterCard (card 92 high; the buy button stays at y 14, the pill at y 58).
- Verified in Studio: validation, simulated purchase writes the inbox, delivery of a 2-gift inbox at join (1 tool "x2", delivered = 2), page and card layout. Test data removed: the test tool destroyed (the account had 0 x100 before, 0 after a rejoin), the inbox keys removed.
- Not verified: the real prompt and a real friend.
- Backups _Backup_20261001.LuckConfig/VipGui/PlantLimitGui_before_luckgift.

2026-10-03 (user: "สัตว์เลี้ยงนำโชค ทำให้ปิดไม่ได้ ถ้าใครปิดอยู่บังคับให้เปิด"): the pet ability "Lucky" (นำโชค) is now ALWAYS ON. `PetManager`: `ALWAYS_ON_ABILITIES = { Lucky = true }` + `forceAlwaysOn(player)` (sets enabledAbilities + attr AbilityOn_Lucky + tells the client) called at the top of `sendAbilitiesInfo` (runs on every spawn/restore, so anyone who saved it OFF is switched back on when they join) and from the toggle handler, which now ignores toggles of those abilities (re-sends "on"). Client: Lucky buttons in PetHelperToggleButton and ActivePetsHud do nothing and have no press effect (they still show "เปิด"/"✓" as before). Add other always-on abilities in that table. Verified in Play: toggling Lucky keeps it true, forced-false attribute snaps back to true, Planter still toggles. Backups: none made for PetManager this time. Needs Publish.

2026-10-03 later (user: "ตอนใช้ ให้เปิดความสามารถได้ใช้ทันที ถึงแม้เคยปิดไว้ก็ให้เปิดทันที"): in `PetManager.spawnPetFor` every ability of a pet being used (summoned / restored at login) is now switched ON immediately, ignoring the saved/last state, and for the same ability on the player's OTHER active pets too (one button controls all holders). Toggling off afterwards still works (except Lucky = always on). Verified: Harvester/Planter toggled off, re-using the Nine-Tail Fox turned Harvester back on. Side effect: anyone who turned an ability off on purpose gets it back each time they re-summon/rejoin. Needs Publish.


---

## mount-gacha-plan

2026-10-15 the user asked for a mount gacha machine. PLANNING ONLY — user said "วางแผนก่อนนะอย่าพึ่งทำ". Nothing built.

User decisions:
- Roll with COINS only (no Robux).
- Machine stands next to the pet gacha (workspace.GachaMachine pivot ≈ (27, 4, −110)).
- 8 mounts (below). Duplicate roll → refund HALF the roll price in coins.

Mounts (rarity, speed multiplier, perk):
- เต่าผู้ใจเย็น (Common, ×0.9, never knocked over)
- กระต่ายขนปุย (Common, ×1.15, jump ×1.5, bouncy walk)
- แกะปุยเมฆ (Uncommon, ×1.15, slow glide when falling)
- ม้าผู้พยศ (Rare, ×1.4, rears up on mount)
- คาปิบาร่าสายชิล (Rare, ×1.4, swims on sea/lake while mounted, yuzu on head)
- กวางซากุระ (Epic, ×1.6, petal trail)
- ยูนิคอร์นสายรุ้ง (Legendary, ×1.8, double jump, rainbow trail)
- ไม้กวาดแมวเหมียวแม่มด (Secret, Halloween only via SeasonConfig Halloween2026, ×1.7, hovers, glides over water, purple stars + tiny bats; cute not scary)

Proposed (not confirmed): rates Common 55 / Uncommon 25 / Rare 15 / Epic 4 / Legendary 1 (+ Secret 0.5 during Halloween taken from Common); price 15,000 coins (dupe 7,500 back), 1× and 10× buttons.

2026-10-16 user changed the price to 100,000 per roll (MountConfig.RollPrice; dupe refund auto = half = 50,000). 2026-10-15 user accepted ALL proposed values (15k price, 1×/10× no discount, no pity, speeds as listed, ride anywhere incl. plots, mounts kept forever).

Progress: step 1 DONE 2026-10-15 (Studio only) — `ReplicatedStorage.MountConfig` (Mounts table, RollPrice, DupeRefund, RarityRates, InPool/CurrentRarityRates/CurrentPool/RarityRank), `ServerScriptService.MountSystem.MountOwnership` (DataStore MountOwnership_v1 {owned, equipped}; Load/WaitLoaded/IsLoaded/Owns/GetOwned/GetEquipped/GrantBatch→{mountId,isNew} or nil/SetEquipped (debounced 5 s save)/Unload; attrs MountOwned_<id>, MountEquipped, MountDataLoaded; test key attr `DevMountKeyOverride`), `MountSystem.MountDataLoader`. Tested in Play with a fake key. Step 2 DONE 2026-10-15 (Studio only): `MountSystem.MountGachaService` — RemoteFunction RemoteEvents.MountGachaRequest(action "info"/"roll", count 1|10) returns {ok, results[{MountId, Rarity, IsNew, Refund}], spent, refund, info{Price, DupeRefund, MultiCount, Pool[{Id,Rarity,Chance}], Owned, Equipped}}; RemoteEvents MountGachaAnnounce (payload {UserId, Name, MountId, Rarity, IsNew, OtherServer}) for Epic+, Secret also cross-server topic MountGachaAnnounce_v1; MountGachaOpen created but unused. Tested with fake key + coins restored. Gotcha: setting the owner's coins back in Studio trips CheatWatch coin_rate (studio: key).
Step 3 DONE 2026-10-15 (Studio only): workspace.MountGachaMachine (single AI MeshPart body.body_geom, 11 studs beside the pet machine at (30.1,4,-120.5), prompt MountGachaPrompt made by MountGachaService), StarterPlayerScripts.MountGachaGui (attrs MountGachaBusy / MountGachaRevealing; uses ReplicatedStorage.MountPreviewModels.<id> for 3D pictures if that folder exists, else MountConfig Icon emoji) + MountGachaAnnouncer (banner at y 80). Gotcha: Roblox fonts lack 🪙 and 🦫 (use 💰 / 🐹); test a glyph via TextBounds width (31 = missing, 42 = ok at size 30). Window has a "riding coming soon" hint line to remove in step 4.
Step 4 BUILT 2026-10-15, only partly tested: MountSystem.MountService (MountRequest ride/toggle/dismount; Weld under HRP, HipHeight = SeatHeight + 0.3; template ServerStorage.MountTemplates.<id> = Model, PrimaryPart "MountRoot" at ground centre, front -Z, attr SeatHeight; else block placeholder; attrs RidingMount/MountSpeed/MountJump; BindableEvent ServerStorage.MountDismount for other systems) + StarterPlayerScripts.MountClient (sit anim Action4, JumpHeight, H key, window MountGui with BindableEvent OpenMount opened from MoreMenuGui entry "mount") + SprintController multiplies by MountSpeed. Verified: riding the horse sets speed 22.4 / jump 7.92 / sit anim. Measured sit pose: thigh bottom ≈ HRP bottom − 0.28. The sit pose puts legs straight forward (may need a straddle pose with real models). NOT verified: new hip formula, H key, picker, dismount, death. Studio test key `DevMountKeyOverride` = "MountTest_20261015d" (seeded with all 8 mounts) is STILL SET on workspace — clear it when testing is done. Studio Play rendered 3D as all white that session and the next Play start hung (fixed after the user restarted Studio twice).

Step 4 VERIFIED + Step 5 DONE 2026-10-15 (Studio only): 8 AI-mesh templates in ServerStorage.MountTemplates (MountRoot + MeshPart "Body", front -Z, SeatHeight via raycast) + copies in ReplicatedStorage.MountPreviewModels; AI source meshes all came out facing +Z (rotate 180°). Bunny/deer first came out as upright figurines and the first broom had bristles pointing up — prompts that worked: "crouching low on all four paws ... long horizontal back you can sit on, side view quadruped" and "broom lying perfectly horizontal like a bench". generate_mesh: 4 parallel jobs → one failed "Too Many Requests"; 2 at a time is safe. Play test: thigh bottom = SeatHeight exactly with HipHeight = SeatHeight + 0.3; switch/dismount/death all restore. Not tried: real H key, phone, gamepad, 2 players.
Step 6 DONE 2026-10-15 (Studio only): BodyWeld (Weld) + model attr Perk + server emitters "MountFx" (attr Always on broom) + unicorn Trail; StarterPlayerScripts.MountFx animates BodyWeld.C0 for all players; MountClient perks (Steady/SlowFall/DoubleJump/Hover water pad/Swim half-sunk pad/water dismount + MountToast gui). Verified in Play except the capybara half-sink change. Test tricks: JumpRequest only fires from real input → user_keyboard_input Space works; deep sea test spot (-400, 0, -600) depth 32 (beach water is too shallow to swim). Studio "start play" via MCP hangs every few runs (needs the user to restart Studio).
User feedback 2026-10-15: rider sat in front of the saddle → templates now shift Body forward (horse 0.9, capybara 1.2, unicorn 0.9, deer 0.5); find saddles via a raycast height profile on the ORIGINAL source mesh (templates have Box collision; changing CollisionFidelity on a clone is async and returns box hits). Sheep remade without black eye patches (user disliked them). Step 7 DONE: auto-dismount on fishing cast / emote start / boxing join / carry (both sides) via ServerStorage.MountDismount; no riding while BoxingSide; seats dismount via Sit; warp keeps the mount. All 7 steps built; NOT published; DevMountKeyOverride still set. Straddle pose DONE (MountFx sets leg joint .Transform in PreSimulation for all riders; Studio tune attr ReplicatedStorage.DevMountLegPose; RIDER_LIFT 0.05) + summon sounds (horse neigh 3165902128, broom meow 135082616547404, others Power_Up 3406813517, EffectSounds). Turtle 2026-10-15: Speed 0.54 + RunSpeed 16/26 (attr MountRunSpeed, SprintController uses it when running). Unicorn legs 2026-10-15: segment_mesh (max 5 parts; result Model nests the parts one level down — use GetDescendants; GOTCHA: the output mesh was flipped 180° (head moved to +Z) while LookVector stayed -Z → check head side with a raycast height profile and rotate back; user caught "front/back swapped") → Body + LegFL/FR/BL/BR with attrs Hinge/Front/Left, model attr Jointed; MountFx.animateLegs (diagonal walk, gallop ≥ 24). Seams fixed by stretching each leg 0.4 studs up into the body (hinge kept) + MAX_SWING 18°; gait = smoothed speed, diagonal trot only. User approved the unicorn walk 2026-10-15. Later 2026-10-15 user said legs "ไม่เนียน": back-leg pieces include the hip chunk (gold ring) and the 0.4 stretch pushed their torn top rim out of the rump → back legs un-stretched (attr BackUnstretched), Hinge = top − 0.3, MountFx BACK_SWING_SCALE 0.55; a white filler ball at the hip does NOT work (pokes through the thin rump). Hairline crack remains at full swing. User: "ยังเห็นรอยต่ออยู่" → real cause: segment_mesh parts are OPEN hollow shells (leg rim = body hole rim exactly), so any rigid rotation shows a gap. FINAL FIX: MountFx bends leg vertices client-side via EditableMesh (CreateEditableMeshAsync → CreateMeshPartAsync → ApplyMesh; ApplyMesh WIPES TextureContent, restore it), only below leg attr BendTop (leg-local Y; smoothstep over 0.7 studs), fallback = old rigid swing. Verified seamless in Edit renders; Play: meshes swap OK, no errors. Unknown: whether EditableMesh is allowed in the live game (may need Game Settings → Security mesh/image API toggle) — fallback covers it. Same recipe works for any segmented mount. Body holes (4 open loops, seen through from below → rider's shirt visible) are capped client-side too: Body attr CapHoles = loops "x,y,z;...|u,v" joined by "#" (mesh space, boundary winding; cap tri = (next, cur, centroid)), MountFx.capBody uses CreateEditableMeshAsync(..., {FixedSize=false}) + AddVertex/AddTriangle/SetFaceUVs. Verified in Play 2026-10-15. THEN REPLACED (user still saw seams, chose "original + new front-right leg"): unicorn template is now the ORIGINAL single closed mesh (MountRoot + Body) with Body attrs LegRig (per leg "name,front,left,axX,axZ,hipY,hipZ,fullY,topY" body-local) + MirrorFront ("zMax,yMax,snap,whiteX,Y,Z"); MountFx.makeSkinned: EditableMesh(FixedSize=false) → mirrorFrontLeft (delete faces x>0,z<zMax,y<yMax; add mirrored copies of x<0 faces with reversed winding + same UV ids; snap new seam verts to old seam verts <0.15; fan-cap leftovers with one white UV) → vertex skinning (hip rotation, weight = radial(0.45→0.72 from leg axis) × height fade) — seamless, verified in Play. Old jointed template in _Backup_20261015.RainbowUnicorn_jointed_before_skin. Gotchas: EditableMesh:RaycastLocal returns (faceId, point, ...) — point is the 2nd value; knee/fetlock straightening of the AI's raised leg crumpled the hoof (don't retry); Studio Edit viewport can render all white after a restart — screen_capture in Play still works; generate_mesh only runs in Edit (not Play). MountPreviewModels.RainbowUnicorn still the jointed version. 2026-10-16 seam rework (user CONFIRMED no hole in Play): MirrorFront now "z1,y1,z2,y2,snap[,xMargin]" = two boxes chosen where left/right are symmetric (front y<1.95 model + low y<1.35), weld = project seam verts onto the other side's edge polyline both ways, copied faces get mirrored normals + seam corners reuse old normals, flipped faces removed, small holes filled by shortest-cycle search (≤8 edges, after cancelling coincident opposite edge pairs), then every open edge gets a tangential "flap" (0.07 studs out along the surface, sunk 0.015) — inward skirts do NOT hide in-surface slits. NEVER fan-cap the whole seam (made shards/black triangles). xMargin>0 left old raised-leg strips visible (keep 0). Debug trick: find holes by ray grid from the camera with em:RaycastLocal and flag back-face first hits. Studio "white 3D view" in screenshots was only the capture tool (user's own view was fine); loadstring works in Edit execute_luau to test LocalScript functions. Same recipe can give other mounts moving legs if the user asks. 2026-10-16: user said hide the machine + mount menu for now → switch MountConfig.Enabled = false / IsEnabled() (Studio test: ReplicatedStorage attr DevMountOn = true); the machine stays in workspace in the file and the server moves it to ServerStorage at start — do NOT move it out in Edit. Other sessions that day: price 100k, broom free flight, unicorn chest-hole fixes; an unused AI unicorn with explicit leg parts is parked in MountModelSources_AI. 2026-10-16 Robux shop mount "ลามะไม่ลานะ" (MagicLlama): rarity Premium, def.Shop = { GamePassId = 2039540565 (user made a GAME PASS "ลามะไม่ใช่ลามะ" 540 R$, not a dev product; user chose to keep it), PriceRobux = 540 }, not in the gacha; MountShopService (MountShopBuy → PromptGamePassPurchase, PromptGamePassPurchaseFinished + join-time UserOwnsGamePassAsync grant; Studio sim attr DevMountShopSim). The owner account owns the pass automatically, so the llama is now in the owner's real mount data; QuickShop card in PlantLimitGui; Perk MagicTrail = stars + lantern light (server) + client sprouts (MountFx). Tested with a fake key, cleaned up. 2026-10-16 rates harder: Common 80 / Rare 15 / Epic 4 / Legendary 1, no Uncommon (sheep → Rare), MountConfig.Items RubyShard 30 + DiamondShard 20 in Common (1 per hit via ItemFactory.GiveFish, no refund), ~50% chance of a mount per roll; roll requires InventoryReady. Later 2026-10-16: shards REPLACED by "เกือกม้านำโชค" (Items.Horseshoe Common weight 50, 1–3 per hit) stored as MountOwnership record field `horseshoes` (attr MountHorseshoes); exchange costs Common 15 / Rare 60 / Epic 150 / Legendary 400 (Secret + shop mounts not exchangeable); bunny moved to Rare (weight 6). FINAL 2026-10-16: exchange REMOVED (user wants mounts hard + a coin sink against inflation): ExchangeCost = {}, ExchangeCostOf → nil; consolation item = LuckyScarecrow (Currency "Booster", x50 scarecrow ×1 to bag via ItemFactory.GiveBoosterTool, 60.2%); leftover `horseshoes` in records is unused. Remaining: real-device tests, publish (clear DevMountKeyOverride first). 2026-10-15 Play showed the owner's coins 36.8m (was 59.6m earlier that day) and hotbar slots 1-5 empty — not investigated, told the user. (old next-step note follows) step 7 integrations (auto-dismount for fishing/carry/boxing/warp/emote/boat, CheatWatch speed).

Checked 2026-10-15: no existing mount/ride system in the place; pet Normal ticket = 20,000 coins.

**Why:** plan agreed in chat; build order and open questions are in the plan shown to the user that day.

**How to apply:** when the user says go, follow the build order: data → roll service → machine+UI → riding core → 8 models → perks → integrations. Related: [[pet-gacha-plan]], [[seasonal-events]], [[carry-system]], [[seat-drag-bug]], [[level-load-guard]], [[streaming-atomic-models]].

**Mount accessories (2026-10-16, not published):** 6 head accessories in the pool (MountConfig.Accessories: PinkBow/FlowerCrown 10 Common, TinyTopHat 7 Rare, GoldCrown 1.6 Epic, AngelHalo 0.4 Legendary, PumpkinWitchHat Secret Halloween 0.5) → pool = scarecrow 46.4 / mounts 24.3 / accessories 29.3. Dupe accessory = 1 Lucky Scarecrow, no exchange anywhere (user rule). Saved in MountOwnership_v1 `accessories` + `accessory`; models ServerStorage.MountAccessories (pivot = bottom centre), placed at mount attr HeadPoint (+Float). Picker row in MountClient. Tested in Play: equip/switch/refuse/roll dupe ok; visual fit on all 9 mounts NOT checked yet. Gotcha: never select models by name — "pumpkin" grabbed a map model (restored as "pumpkin_seedling", original name lost); use CollectionService tags from generate results.

**Summon button (2026-10-16, not published):** MountClient end → `MountSummonGui.MountSummonButton` 🐴 = "toggle"; shown on PC too (user asked; caption "ขี่ H"/"ลง H", phone "ขี่"/"ลง"), needs any MountOwned_; stacked above SprintGui.SprintButton, or above GhostPlaceGui.Holder when that shows (both live above the run button; ⬇ broom fly-down is left of the run button). Ghost stacking verified in Play; PC version not Play-tested (Play start hung).

**Furniture (ของตกแต่ง) in the mount machine — plan 2026-10-16, step 1 of 5 done:** MountConfig.Furniture (MushroomStool C11, FlowerHammock R2.2 Lie, CapyBeanbag R1.8 2 seats, PicnicSet E1.2 4 seats, MoonSwing L0.3 Swing); mounts cut to ~15.6% (user: "ลดสัตว์ขี่อีกเพื่อให้ได้ยาก"). Saved MountOwnership_v1 `furniture`, attr MountFurnOwned_<id>, dupe = scarecrow. User decisions: TEMPORARY placement next to you (1 at a time, anyone may sit, vanishes when owner leaves), menu ☰ → 🪑 ของตกแต่ง; sitting + AFK fishing must keep fishing, and after the 19-min AFK rejoin the furniture is re-placed and the player re-seated (via TeleportData). Remaining: 2 AI models with Seats (ServerStorage.MountFurniture), 3 place/pick-up system + window (gamepad), 4 AFK rejoin restore, 5 test. Check SeatGuard (seat-drag-bug) before step 3.
Furniture step 2 done 2026-10-16: templates ServerStorage.MountFurniture.<id> (Root PrimaryPart at bottom centre, front -Z, invisible Seat1..n, attrs FurnId/Pose, mesh parts non-collide/non-query) + previews in MountPreviewModels. Gotcha: generate_mesh output arrives with a RANDOM yaw on the MeshPart (124°, -55°…) — reset each MeshPart to yaw 180 before measuring, and raycasts need CanQuery on.
Furniture step 3 done 2026-10-16 (user changed the plan: furniture AND mounts live in the BAG as new tabs, not a ☰ furniture window; the ☰ "สัตว์ขี่" entry was REMOVED 2026-10-16 at user request): FullInventoryGui tabs "mount"/"furn" (renderMountTab, OpenTab BindableEvent; MountClient OpenMount → bag tab), FurnitureService (FurnitureRequest place/pickup, workspace.PlacedFurniture.<UserId>, E-prompt sit, seats CanTouch off, player attr PlacedFurniture). Not tested: phone, 2 players, capy/swing sitting, swing has no real swinging. Remaining: step 4 AFK-rejoin restore (re-place + re-seat via TeleportData), then final test.
Furniture step 4 done 2026-10-16: AFK rejoin carries TeleportData.furniture {id, cf[12], seat} (AfkRejoin → ServerStorage.FurnitureSnapshot); FurnitureService.restoreAfterRejoin re-places + re-seats after MountOwnership loaded + SpawnPlaced, ≤30 studs from player. Studio test hook ServerStorage.FurnitureRestoreTest:Fire(player, snap). Simulated test passed; real server AFK rejoin untested; AutoRestart soft restart does NOT carry furniture. All 4 furniture steps done; only live test left.
Furniture as a hotbar tool (2026-10-16, user request, not published): bag furn card = "ใช้" → FurnitureRequest("tool", id) gives a handle-less Tool (attrs IsFurniture/FurnId, not saved by InventorySystem) → HotbarState.UseTool (slots 3-5); card then "ถือ"/"เก็บ". StarterPlayerScripts.FurniturePlacer = ghost (MountPreviewModels clone + Highlight + neon footprint) + top guide panel (rotate/place/pickup buttons); PC click / R, touch = TouchTapInWorld moves ghost + ✔ button, pad = in front, R2/RB. Server "place" takes (id, pos, yaw), range 24 / step 8. Tools re-given on CharacterAdded (heldFurn) and on join from HotbarLayoutQuery keys "FurnId=". HotbarState KEY_ATTRIBUTES gained IsFurniture/FurnId; ItemPreview "Furn:<id>". Fonts lack "↻" (shows a box). User then wanted the guide = title "กำลังวาง: ชื่อ" only, transparent bg → status/hint/note hidden, button row only on touch (validity = ghost colour only). Tested on PC in Play; mobile/pad/rejoin untested; owner's real layout now has the stool in slot 4.
Roll animation = spinning WHEEL (2026-10-16, user request, replaced the capsule): MountGachaGui.playReveal builds a CanvasGroup wheel (≤12 slots, won item + shuffled pool, silhouettes via ViewportFrame.ImageColor3 dark), positions slots manually each frame (child GuiObjects don't inherit Rotation), easeOutQuart 3.6 s / 5 turns, lands on the won item (10× = best rarity), then colour + big model + name/rarity, then the old results cards. Studio-only hook `script.RevealTest:Fire(results)` (fake results, no coins) — owner's real data is used in Play, so never real-roll to test. Verified in Play 2026-10-16 (1× fake results): silhouettes render inside the CanvasGroup and the spin/stop/reveal work, BUT ViewportFrames ignore GroupTransparency → wheel is now hidden (Visible=false) 0.3 s after the fade (not re-checked yet). screen_capture lags ~1 s behind the real UI — log states with a script instead. Studio pattern: the first Play after a Studio restart starts, the next MCP start hangs. 10× reveal not yet viewed.
Broom flight buttons (2026-10-16, user: "only up, no down"): MountClient shows on-screen ⬆/⬇ (MountToast.FlyUp/FlyDown, x = right −165, y −300/−235) on ALL devices while Perk Hover; PC shows key captions Space/Q. 2026-10-17: user said hide it, not releasing yet → MountConfig.Enabled = false (backup _Backup_20261017.MountConfig_before_hide); FurnitureService.giveTool now returns nil while disabled. Verified in Play: no machine, buttons, tabs, llama card, furniture tools; server refuses roll/ride. To re-open: Enabled = true. Same day the user said the hidden version was published and asked to open it → Enabled = true again in Studio (verified in Play: machine, buttons, tabs, llama card, roll info, ride all back); live game stays hidden until the user publishes again.
Broom cat REPLACED (2026-10-17, user: the cover looked bad → "use the new hatless cat"): template = MountRoot + Body (AI hatless cat, offset (0,3.15,−1.05), head turned ~45° left) + Model DefaultHat (AI purple witch hat, FollowBody) ; attrs Hover, SeatHeight 2.65, HeadPoint (−0.33,4.85,−2.16), AccessoryScale 1.45. MountService.attachAccessory hides DefaultHat parts (Transparency 1, BaseTransparency attr) while any accessory is worn, and multiplies by model AccessoryScale. Cover attrs removed (cover code kept, unused). Verified in Play after a Studio restart: pumpkin hat centred and sized right with the default hat hidden; removing the accessory brings the default hat back. Old broom in _Backup_20261017.WitchCatBroom_*_before_newcat.
Broom cat hat cover (2026-10-17, user: wearing a hat must replace the cat's own witch hat, not stack): the purple hat is fused with the head (segment_mesh twice → hat always came with the head; 4 hatless AI regenerations were poor). User chose "cover": accessories with `Hat = true` (TinyTopHat, PumpkinWitchHat) on a mount with attrs HatCoverPoint/HatCoverSize scale up to cover and sit at the point (MountService.attachAccessory). Broom: point (0,3.5,−1.2), size (2.0,1.2,1.85); bigger covers the eyes; the top hat still shows a thin purple strip. Alternates kept in MountModelSources_AI.WitchCatBroom_alt_*. Owner now owns the broom (rode it in Play).
Broom cat 4 eyes (2026-10-16): AI cat had side eyes → repainted on the texture: find eye spots by clustering faces whose UV colour is near-white (UV v NOT flipped: pixel y = uv.Y*1024), paint region-face UV triangles (+2px dilation) with the shell's average fur colour; preview via TextureContent = Content.fromObject(EditableImage). Persisting: AssetService:CreateAssetAsync is "not available yet" → export pixels by HttpService POST (needs HttpEnabled, ask the user, restore to false) to a local python server (scratchpad texserver/server.py writes PNG + serves GET) → mcp upload_image http://127.0.0.1:8765/x.png → rbxassetid. New broom texture rbxassetid://100735654228554 (old 102033944399898). Same recipe can remove texture features on any AI model.
Unicorn HeadPoint (2026-10-16, user: hat sat on the horn): moved (0,5.15,−3.25) → (0,4.95,−2.2) on template + preview (horn spans z −2.9…−3.7). Find a HeadPoint via an EditableMesh top-height profile along z, then eyeball a test hat (anchor the test clone's parts or it falls). Accessory placement = root-local HeadPoint + (0, Float − 0.08, 0).
Bunny eyes (2026-10-16, user: "กระต่ายไม่มีตา"): AI bunny had a blank face → EyeL/EyeR 0.4 + shines 0.13 (FollowBody) at body-local (±0.4, y≈−0.03 from body centre, on the face surface) on template + preview; plain smooth faces take stuck-on eyes fine (the llama's fringe/texture didn't — that one needed a remodel). Check a mount's sides for AI side-eyes before adding front eyes (4-eyes complaint).
Llama flies too (2026-10-16, user: it's sold for Robux): MountConfig.Mounts.MagicLlama.Fly = true; MountClient.canFly() = Perk Hover OR def.Fly drives flight, ⬆/⬇ buttons and water-OK — give any future mount flight with Fly = true. Test trick without owning the broom: on the Client set player attr RidingMount = "WitchCatBroom" locally (currentPerk reads it), then clear it.
Llama eyes (2026-10-16, user: "ไม่มีตา"): ball parts EyeL/EyeR + EyeShineL/R (attr FollowBody) on MagicLlama template + preview, at body-local face spot found via EditableMesh RaycastLocal (templates collide as Box). MountService.makeModel welds FollowBody parts to Body (not MountRoot) so they follow MountFx BodyWeld animation — use this for any extra part added to a mount. The AI mesh still has black blobs on the head sides (its original side eyes). SUPERSEDED same day: user said the face wasn't smooth → llama REMODELLED (AI v2, user picked design 2: lantern, red-green checker blanket, one eye pair): Body offset (0, size.Y/2−0.1, −1.0), SeatHeight 2.6, HeadPoint (0,4.92,−2.4); no separate eye parts. I first installed the WRONG design (design 1 had 4 eyes, side pair) — GOTCHA: with screen_capture looking +Z, screen-right is world −X, so "left/right" in a comparison shot is mirrored vs world X; label candidates in the picture itself. Old model in _Backup_20261016.MagicLlama_*_before_remodel; sources ServerStorage.MountModelSources_AI.MagicLlama_v2_used (design 2) / MagicLlama_v2_design1_fourEyes. Ride + hat verified in Play.
2026-10-16: Lucky Scarecrow item Amount 1 → 10 and dupe accessory/furniture consolation = MountConfig.DupeScarecrowAmount (10), user's call. Gotcha hit: an inline edit put "-- comment" mid-line and silently commented out Currency/BoosterTier/Amount (scarecrow refunded full price) — when editing config lines, put comments at the END and re-require the module to check fields.
2026-10-17: the 41% "Lucky Scarecrow ×10" item was replaced by `CoinPrize` (10,000 coins, Currency "Coins", MountGachaService adds them after refunds). Dupe accessory/furniture consolation is still 10 scarecrows (DupeScarecrowAmount). Not published.
2026-10-17: PumpkinWitchHat SeasonRate 0.5 → 0.07. Gotcha: seasonal Secret items share the Secret tier and split it by Weight, so Weight must equal SeasonRate (broom Weight 0.5, hat 0.07) or a rate change spreads across both. Not published.
2026-10-17 rates from the user's marked-up table: every item Weight = its exact % (Common 1 each, Rare 0.8/0.7, Epic 0.5, Legendary 0.2, seasonal Secret 0.2 each incl. hat), tiers 92.7/5.2/1.5/0.6, and the remainder (user chose) goes to CoinPrize via MountConfig.FillerItem (seasonal Secret is taken only from the filler). Coins 88.3% in Halloween / 88.7% off. Not published.
2026-10-17 round 2 rates (user: coins 70%, Secret 0.5%, Legendary 0.2%, rest spread by tier — I picked Common 4% each, Rare 1.6% acc/furn & 1.4% mounts, Epic 0.7/0.7/0.6 deer): tiers 87/10.4/2/0.6, CoinPrize Weight 71 (filler → 70% in Halloween). Supersedes the earlier 88.3% table. Not published.
2026-10-17 round 3: Legendary 0.5% each, seasonal Secret 0.2% each, tiers 86.1/10.4/2/1.5, CoinPrize Weight 70.1 (69.7% in Halloween). Current as of this date; not published.
2026-10-17: turtle 4% → 10% taken from coins (CoinPrize Weight 64.1 → 63.7% in Halloween). Not published.
2026-10-17: per-mount accessory placement — MountService.attachAccessory reads template attrs AccPos_<accId> (CFrame vs MountRoot, accessory pivot = bottom centre) and AccScale_<accId>; set on FluffyBunny for PinkBow (forehead) and AngelHalo (×0.65, above forehead in front of ears). Mesh raycasts only hit the box collision, so position by screenshots (front + side) on a template copy at y≈500; attrs set during Play are lost on Stop — set them in Edit.
2026-10-17: CloudSheep AccPos_PinkBow = (0, 3.0, -2.08) tilt -15° (forehead), not visually checked. Tip: AssetService:CreateEditableMeshAsync(Content.fromUri(body.MeshId)) + GetVertices/GetPosition (scale by Size/mesh bounds) gives the real surface profile when raycasts only hit the box.
2026-10-17: CloudSheep AccPos_PinkBow corrected to (0, 2.35, -2.12) tilt +8° (positive X tilt = top leans back toward the head; negative leans forward/floats) — confirmed visually in a live ride. The sheep's face is lower than the mesh "front profile" suggests (wool cap above y≈2.8). Live-preview trick: move only the AccessoryWeld.C0 using the accessory TEMPLATE pivot (the cloned model's WorldPivot is stale).
2026-10-17: WildHorse AccPos_PinkBow = (0, 4.12, -3.55) tilt +22° (forehead, in front of the forelock — user asked to move it out of the mane), confirmed in a live ride. Bow placement done for bunny, sheep, horse; other mounts/accessories still use HeadPoint and may need the same treatment when the user reports them.
2026-10-17: ChillCapybara AccPos_PinkBow = (0, 2.68, -3.3) tilt +35° (front of head, ahead of the yuzu), NOT visually checked (3D view white when Studio isn't in front). The capybara mesh has a yuzu/orange baked on top of its head (single MeshPart); user finds it not cute — removal options pending (regenerate model vs. leave).
2026-10-17: ChillCapybara model replaced (no yuzu on head; user disliked it). New AI mesh (caramel, sleepy, small saddle) ×1.2, Body at root+(0, 1.81, -1.0) so the saddle is over the root; SeatHeight 2.65, HeadPoint (0, 3.58, -1.85), AccPos_PinkBow (0, 3.02, -2.99) tilt 40°. Old template + preview in ServerStorage._Backup_20261017 (*_before_noyuzu). Swim perk not re-tested with the new model.
2026-10-17: SakuraDeer AccPos_PinkBow = (0, 3.97, -2.73) tilt +32° (forehead under the flower crown), checked on a template copy (front + side). Bow now custom on bunny, sheep, horse, capybara (new model), deer; turtle + unicorn + broom + llama still use HeadPoint.
2026-10-17: RainbowUnicorn AccPos_PinkBow = (0, 3.95, -3.42) tilt +8° — forehead under the horn, above the eyes (user first said horn base, then "down to the forehead"). Side-of-horn and behind-horn looked bad. Turtle, broom, llama still on HeadPoint for the bow.
2026-10-17: RainbowUnicorn AccPos_PumpkinWitchHat = (0, 5.02, -2.2) (4.87 sank into the mane, 5.17 floated — user feedback both ways), checked live.
2026-10-17: machine in the map is now a clear glass dome with spinning mini real models (user chose dome + top items): segment_mesh split the single AI mesh into MachineBase/MachineTopper (dome-with-balls deleted), added GlassDome + Showcase (Turntable + Mini_<id> from MountPreviewModels: unicorn, deer, horse, broom, moon swing, halo), LocalScript MountShowcaseSpin rotates locally and hides seasonal minis out of season. Backup: ServerStorage._Backup_20261017.MountGachaMachine_before_cleardome. segment_mesh REPLACES the source MeshPart in place (back up first).
2026-10-17: all mounts except the turtle ×0.9 (user: 10% harder) — rare mounts 1.26%, deer 0.54%, unicorn 0.45%, broom 0.18%; tiers 86.77/9.84/1.94/1.45, CoinPrize Weight 64.77 (64.39% in Halloween). Not published.
2026-10-17: machine topper creature removed (user: dome only); GlassDome Transparency 0.55. Machine = MachineBase + GlassDome + Showcase.
2026-10-17: showcase changed again — square GlassCase (5.2×5.4×5.2, pastel posts/lid/floor) replaces the dome; minis ~2.4 tall, mounts + furniture only (unicorn, deer, horse, broom, moon swing, capy sofa; halo removed). Dome version backed up as MountGachaMachine_before_squarecase.
2026-10-17: machine window no longer shows odds (%) or collection (X/Y, ✅) — user's call; heading "ของในตู้". Roblox requires odds disclosure for paid random items (Robux, or currency buyable with Robux): if coins ever become buyable with Robux, the % must come back.
2026-10-18: all mounts (incl. turtle this time) + all furniture ×0.9 (user: 10% harder): turtle 9%, rare mounts 1.134%, deer 0.486%, unicorn 0.405%, broom 0.162%, stool 3.6%, hammock/sofa 1.44%, picnic 0.63%, swing 0.45%; tiers 87.813/9.016/1.816/1.355; CoinPrize Weight 67.213 (66.85% in Halloween). Backup in ServerStorage._Backup_20261018. Not published.
2026-10-19: DISABLED again (MountConfig.Enabled = false) before the user's publish — "not ready yet". Verified in Play that machine, window, 🐴 button, H key, bag tabs, ☰ entry and llama card are all hidden. To release: set Enabled = true and publish.
2026-10-19 (later): ENABLED again (MountConfig.Enabled = true, user: "เปิดให้ที"), verified in Play. Not published yet.
2026-10-19: duplicate FURNITURE now refunds DupeRefund (50,000 coins) like a duplicate mount; duplicate ACCESSORIES still give 10 scarecrows. Tested with a fake key.
2026-10-19: flying mounts (broom, llama) steer up/down by camera pitch while moving forward: LookVector.Y > 0 climbs, < -0.35 dives, between = level (default camera looks slightly down); running + looking up takes off; Space/Q/⬆/⬇ still override. MountClient constants PITCH_LEVEL_TOP/BOTTOM/FULL. Tested by simulated input; phone/gamepad not tried.
2026-10-19: llama gift to a friend — Developer Product 3719679834 (R$ 270, MountConfig.Mounts.MagicLlama.Shop.GiftProductId), server MountSystem.MountGift (inbox pattern from PremiumPetGift, DataStore MountGift_v1, remote MountGiftRequest), VipGui gift kind "llama" + OpenLlamaGift, 🎁 pill on the llama shop card. Simulated purchase tested; real Robux purchase and 2-player flow NOT tested.
2026-10-19: MagicLlama template scaled ×1.2 (user: rider looked too big on it) — SeatHeight 3.12, HeadPoint (0, 5.904, -2.88), AccessoryScale 1.2; backup MagicLlama_before_scale12. Not yet seen in Play after the change (Play start hung).
2026-10-19: the llama ×1.2 scale was REVERTED (user: "not that, undo") — llama back to original (seat 2.6). The user's "riding pose looks weird on a big character" complaint is still open; need a screenshot to know what they mean.
2026-10-19: WitchCatBroom AccPos_PinkBow = CFrame (-0.82, 4.35, -2.48) * yaw 49° * tilt +20° (user then said (-0.9,4.15,-2.55) tilt 25 was too low on the forehead; now front of head between the ears, tails clear of the eyes, facing the cat's turned face; user: bow was floating at HeadPoint = old hat base). Checked live in Play. Live-preview trick that worked: on Server, set each accessory part's AccessoryWeld.C0 = bodyLocal⁻¹ * L * (curPivotLocal⁻¹ * bodyLocal * origC0), where bodyLocal = template root→Body. Turtle + llama still use HeadPoint for the bow.
2026-10-19 (evening): DISABLED again (MountConfig.Enabled = false; user: "ปิดพวกสัตว์ขี่กับของตกแต่งไปก่อน ยังไม่เอาเข้าตอนนี้"). Not Play-verified this time (Studio execute_luau was timing out). To release: Enabled = true + publish.
2026-10-19 (night): ENABLED again (MountConfig.Enabled = true, user: "เปิดระบบสัตว์ขี่และของตกแต่งให้ที"); verified in Play (machine, 🐴 button, bag tabs). Not published.
2026-10-19: toy hammer (ค้อนยาง) by the machine for fun: workspace.ToyHammerStand (prompt "หยิบค้อน"), template ServerStorage.ToyHammer (parts-only Tool, attr IsToyHammer, not saved), server MountSystem.ToyHammerService (Slash toolanim, hit if ≤9 studs from machine bbox, RemoteEvent ToyHammerBonk; unequip / >60 studs away = hammer destroyed; hidden when MountConfig disabled), client wobble + squeak/boing + stars + "โป๊ก!" live in MountShowcaseSpin (wobble must happen before the minis are placed each frame). Gotcha: moving the test character right after Play start gets undone by LastPosition's first-spawn placement — wait for it or re-pivot. Not published.
2026-10-19: user says the llama price must be 299. MountConfig fallback PriceRobux 540 → 299; all llama price labels now read the real Game Pass price via GetProductInfo. Checked on Roblox that day: pass 2039540565 = 270 R$ and gift product 3719679834 = 270 R$ — the user must change them on Creator Hub (not done as of this note).
2026-10-20: fishing on a mount allowed (user: "อยากตกปลาบนหลังสัตว์"): FishingSystem cast no longer fires MountDismount. Carry also works while riding (see [[carry-system]]). Not Play-verified after the change (Play start hung). Test shore spot: stand (14, 6, -200) facing -X, water at x ≤ 6.
2026-10-20: furniture AFK-resume re-tested in Studio Play (user: sitting on furniture must survive AFK and keep fishing): MushroomStool placed at shore (12.5, -200) yaw 90° (seat faces water), sit + Bamboo auto-fish, snapshot via ServerStorage.FurnitureSnapshot, then cleared and fired FurnitureRestoreTest + PlayerGui.AfkRejoinGui.TestResume together → seated after 1 s, rod after 2 s, auto + bobber after 3 s, stable 14 s. No code change needed. Still untested: a real server AFK teleport (Studio can't teleport); furniture is only live once MountConfig.Enabled is published.
2026-10-20: duplicate ACCESSORY now refunds DupeRefund (50,000 coins) like duplicate mounts/furniture — no more lucky scarecrows anywhere in the mount gacha (user: "อันไหนได้หุ่นดวงดี ให้เปลี่ยนเป็นเงิน 50% ของค่าสุ่ม"). DupeScarecrowAmount unused. Tested with fake key (dup FlowerCrown → +50,000). Not published.
2026-10-20 saddle fit (user: rider sits behind the saddle on horse + llama): measured saddle by texture colour along the back top (|x|<0.5, top 0.25 studs) — horse saddle z −1.0..+0.5, llama blanket −1.0..+0.35; rider hips at root z≈0 (LowerTorso). Shifted every non-root part of both templates +0.5 Z (body back → rider forward): horse Body z −0.4, llama −0.5; HeadPoint/AccPos_* shifted with them; horse SeatHeight 3.0. Recipe works for any mount (EditableMesh + EditableImage ReadPixelsBuffer per UV). Live preview of rider offset = MountRoot.MountWeld.C0 (Part0 = HRP). Not seen in Play after the change.
2026-10-20: user CONFIRMED in Play that the horse and llama riders now sit on the saddle (+0.5 shift, horse SeatHeight 3.0).
2026-10-20 rider-size scaling (user chose "scale the mount to the character" over pose tweaks): MountService.ride → scaleMount(model, clamp(standingHip / REF_HIP 2.0, 0.8, 1.5)) right after makeModel; R6 = 1. ScaleTo around MountRoot + multiplies SeatHeight, HeadPoint, HatCoverPoint/Size, AccPos_* positions, AccessoryScale, unicorn Body LegRig fields 4-12 and MirrorFront; model attr RiderScale. REF_HIP 2.0 = owner's avatar (default Roblox avatar = 2.19 → ×1.095). Tested in Play with ApplyDescription HeightScale 1.3 (hip 2.6 → ×1.3, horse/llama/unicorn fine, no errors) and the owner's real avatar (×1.0). New mounts need no extra work unless they store stud positions in new attributes (add them to scaleMount).
2026-10-20 furniture lost after AFK (user report): cause = restoreAfterRejoin required the player within RESTORE_RANGE 30 (placed it, AFK'd elsewhere → dropped) + only 60 s total wait. Now: always re-place at the old spot if ground/no water/no solid overlap; re-seat only when within 30; WaitLoaded 90 s; prints the reason when skipped. Verified with FurnitureRestoreTest (59 studs away → placed; near → placed + seated). Still NOT covered: server restart / failed AFK teleport (no TeleportData) — would need a DataStore record like FishingResume_v1. Server GetJoinData().TeleportData is documented as supported.

2026-10-23: turtle swims (user: it sank in deep water). MountConfig CalmTurtle `Swim = true`; MountClient `canSwim()` = Perk Swim OR def.Swim → half-sunk water pad + no water dismount. Give any future mount water ability with Swim = true. Verified in Play at (-400,0,-600) depth 32: floated at y 4.4, still mounted. Not published.


---

## pet-auto-feed-plan

**2026-10-09 bowl auto-fill cap:** machine → bowl auto transfer now pauses while the bowl holds >= `AutoFeederConfig.AUTO_FILL_BELOW` (3000) bags (AutoFeeder bridge "space" returns 0), so finished food waits at the machine for manual collect; resumes automatically below 3000. Manual deposit stays unlimited; bowl count still includes everything. PetFoodGui note shows the bowl count. Below-3000 branch not play-tested (Studio play start hung). Needs Publish.

**2026-10-09 pet picker while holding pet food:** PetHungerClient builds ScreenGui `PetFeedPicker` (chips per active pet, above the hotbar); tapping fires `PetFeed(petId, "call")` → PetManager.callPetToEat → PetController `CallToEat` (pet drops its job, runs beside the owner, then `feedPet(player, petId, true)`; 12 s timeout). The otter's fishing helper stops while called (provider skips pets with `IsCalled()`). The F ProximityPrompt path is unchanged. Not wired for gamepad. Announced in LoginAnnouncementConfig V1.1.4 (Id bumped to farm-news-20261009b). Needs Publish.

Requested by the user 2026-09-26: an auto-feeding system for pets, sold for Robux only, plus a machine that converts produce into pet food. The fishing-system plan was put on hold for this. Fishing plan (not built): spots = sea/beach, lake + LakeDock, canals, terrace stream/pond; rod tiers, bait from crops, reel minigame, fish index, AFK fish traps. The user has not answered its 6 questions yet.

Agreed build order:
1. Pet-food item + manual feeding.
2. Converter machine (queue, works offline).
3. Auto-feeder (ownership check, storage, auto-eat when hungry).
4. Eat visuals + HUD bowl icon + low-food warning.
5. Balance from playtest.

Open decisions I asked the user and they have NOT answered yet:
1. Portable vs placed bowl (I recommended portable).
2. Game Pass vs timed dev product, and price.
3. Conversion recipe.
4. Whether the feeder also accepts raw produce (I recommended food only).
5. One shared converter vs one per player, and coin upgrades.
6. Special buff foods now or later.

Step 1 DONE 2026-09-26:
- Pet food is a Tool with attrs IsPetFood / Star / Count and no CropType.
- ItemFactory: CreatePetFoodTool / GivePetFood / GetPetFoodName. It also copies the model into ReplicatedStorage.ItemPreviewModels.PetFood.
- Template: ServerStorage.PetFoodTemplates.PetFood (AI pink paw-print bag, rotated so the paw faces LookVector).
- PetHunger.PET_FOOD_BY_STAR = 15/22/30/45/60 (1.5x raw produce).
- Code touched: PetManager feed handler accepts pet food; InventorySystem saves kind "PetFood"; Localization keys Item_PetFood / Inventory_TabPetFood / Hotbar_PetFood.
- UI: FullInventoryGui has a 5th tab "🥫 อาหาร"; CustomHotbar shows a pink strip; HotbarState blocks pet food from reserved seed slots 1-2; PetHungerClient shows the feed prompt when holding food.
- There is no in-game source of pet food yet; step 2 (converter) provides it.

Step 2 DONE 2026-09-26 (user chose: 2 produce same star = 1 bag; one shared machine with per-player queues; speed upgrades with coins):
- Config: ReplicatedStorage.PetFoodConfig (PRODUCE_PER_BAG 2, MAX_QUEUE 100, SpeedLevels 20/15/11/8/5 s at costs 0/10k/30k/80k/200k).
- Server: ServerScriptService.PetFoodConverter, DataStore "PetFoodConverter_v1" {level, queue {star,bags} FIFO, cursor unix seconds, ready[1..5]}. settle() works from real time, so it keeps running offline. It saves before changing inventory/coins and rolls back on failure.
- RemoteFunction PetFoodRequest (info/insert/collect/upgrade); RemoteEvent PetFoodOpen fires from the ProximityPrompt on workspace.PetFoodMachine (AI mint machine at -122,5,62 between shop and gacha, facing spawn).
- Player attrs PetFoodQueue / PetFoodReady.
- Client: LocalScript PetFoodGui (window + local-only billboard above the machine + machine wobble while working). Map streaming: wait for the machine's parts before using them.
- Tested: insert, clamping, collect, upgrade, offline completion. The test account was reset afterwards.

Step 3 DONE 2026-09-26 (user chose: portable bowl, Game Pass, created at 149 R$, ID 1998260629):
- Config: ReplicatedStorage.AutoFeederConfig (CAPACITY 100, thresholds 30/50/70/90 with default 50, FEED_COOLDOWN 2.5 s, LOW_WARNING 5).
- Server: ServerScriptService.AutoFeeder, DataStore "AutoFeeder_v1" {food[1..5], enabled, threshold, order low/high, off[petId]}.
- Ownership: UserOwnsGamePassAsync on join + PromptGamePassPurchaseFinished. The creator account owns the pass automatically. A Studio-only override is available: set player attr DevGrantAutoFeeder from the server.
- Behaviour: feeds active pets (workspace models with OwnerUserId) one bag at a time while hunger < threshold, restores NineLives lives, and shows a bowl part + chew sound + "+X% 🍖" billboard. Warns once when the bowl is low or empty.
- RemoteFunction AutoFeederRequest (info/deposit/withdraw/setting); player attrs HasAutoFeeder / AutoFeederFood / AutoFeederOn.
- Client: LocalScript AutoFeederGui (sell page with live price + owned page), opened via BindableEvent OpenAutoFeeder. ActivePetsHud has a "🥣" button under the pet cards.
- Tested: deposit, auto-eat, NineLives restore, withdraw. The test account was reset.
- Remaining: step 4 polish (eat animation / low-food HUD mostly done) and step 5 balance. Game Pass icon DONE 2026-09-29: SVG drawn by hand (pink bowl, overflowing kibble, fish treat, paw print, "AUTO" pill badge; all content inside the circle crop) rendered to a 512×512 PNG with headless Edge (`msedge --headless=new --screenshot=... --window-size=512,512 file:///x.svg`), then uploaded by the user. Reuse this approach for other pass icons.

Converter accepts fish (2026-09-27): PetFoodConfig.FISH_BAGS {Common 1, Rare 2, Legendary 4, Secret 8}; 1 fish = that many bags of the fish's star. The client sends CropType "Fish_<id>" and the count means number of fish (clamped to have and to queue space / per). Stacks info has IsFish/BagsPer; fish rows are listed after produce (light blue, "ใส่ 1 ตัว (+N ถุง)"). Tested with a test Catfish; the converter record was restored from a JSON snapshot taken before the test (the good pattern for converter tests).

**Why:** the game is AFK-focused and hunger is what limits AFK, so an auto-feeder is a strong Robux product.
**How to apply:** continue with step 2 after the user answers the open decisions (ask again if they skip them). Related: [[pet-gacha-plan]].

Feeding rule change 2026-09-29 (user): pets can ONLY be fed pet food (IsPetFood). Produce and fish must first go through the converter.
- PetManager petFeed rejects anything else with "🥫 สัตว์กินได้เฉพาะอาหารสัตว์ · เอาผลผลิตหรือปลาไปทำที่เครื่องทำอาหารสัตว์".
- PetHungerClient shows the F prompt / hunger bar-on-hold only for pet food.
- PetHunger.FOOD_BY_STAR and FISH_RARITY_MULT were removed; only PET_FOOD_BY_STAR {15, 22, 30, 45, 60} remains (also used by AutoFeeder).
- Tested produce (rejected), fish (rejected) and pet food (+ bag -1); the test bag and cat hunger were restored.

Gamepad support in PetFoodGui 2026-09-29 (the user confirmed it works on a real controller):
- Same pattern as AutoFeederGui / FishingShopGui: buttons Selectable + Activated; main.SelectionGroup + Stop behaviours; B closes; gold SelectionImageObject.
- Buttons are named Close / Collect / Upgrade / One_<CropType>_<Star> / All_<CropType>_<Star>.
- The list is rebuilt every 3 s, so renderStatic re-selects by name, falling back to firstStackButton() (lowest-LayoutOrder row, because AbsolutePosition isn't updated yet right after a rebuild).
- On open with a gamepad, it selects Collect if food is ready, otherwise the first "ใส่ 1" button.

Auto-fill from converter 2026-09-29/30 (user: bowl owners get finished pet food straight into the bowl):
- AutoFeeder: data.autoFill (default true), setting key "autoFill", info.AutoFill. BindableFunction ServerScriptService.AutoFeederBridge:
  - Invoke("space", player) -> free capacity (0 if no pass / not loaded / autoFill off).
  - Invoke("add", player, {s1,s2,s3,s4,s5}) -> must be a dense 5-array with total > 0, else false. Saves immediately.
- PetFoodConverter transferToBowl: take ready (low star first) up to space, save the converter (revert on fail), then add to the bowl (on fail put back into ready). Runs from the 2 s loop when ready > 0 and HasAutoFeeder: retry after 2 s if something moved, else 10 s. The queue-done notify mentions how much went to the bowl. PetFoodGui recipe line shows "🥣 มีชามอาหารอัตโนมัติ: ...".
- AutoFeederGui: "🔄 ดึงอาหารจากเครื่องทำอาหารเข้าชามเอง: เปิด/ปิด" row under the main toggle.
- BUG hit in the first test: a sparse table {[5]=42} passed through BindableFunction arrived without key 5, so "add" added 0, returned true and 100 bags vanished. Restored from the Edit-mode snapshot (_ConvSnap/_BowlSnap in ServerStorage). ALWAYS pass dense arrays across Bindables/Remotes.
- Verified after the fix: 158 total conserved (bowl 100, machine 58), autoFill off blocks transfers, on refills.

2026-10-01: ActivePetsHud retired at the user's request (right-side "สัตว์เลี้ยงที่ใช้อยู่" panel).
- The LocalScript is Disabled = true. Copy in _Backup_20260930.ActivePetsHud_before_retire; set Disabled = false to bring it back.
- The food bowl moved into the pet menu (PetHelperToggleButton): "FeederRow" TextButton at LayoutOrder 0 at the top of PetList (not in petRows, so clearPetRows keeps it).
  - Same look/badges as the old HUD card.
  - Click: closes the pet menu and fires AutoFeederGui.OpenAutoFeeder.
- Replacement warning: a red "!" AlertDot on the 🐾 button when an active pet's hunger is ≤ 20 or the bowl is low (on and ≤ LOW_WARNING).
- Lost with the HUD: the D-pad right shortcut and the per-card ability pills (the abilities tab in the pet menu still has the toggles).
- Backup PetHelperToggleButton_before_feederrow.
- 2026-10-01 pet-menu order: FeederRow (0), then active pets, then owned by rarity, then locked.
- Pressing a pet's เลือก/เลิกใช้ sets pendingScrollPetId. After the petListInfo rebuild the list scrolls to the top and flashes that row if it is now active. The user asked for this because the list used to stay scrolled down.
- Backup PetHelperToggleButton_before_scrolltop.
- 2026-10-01: the FeederRow is now STICKY.
  - Parented to PetMenuFrame (not PetList) at (10, CONTENT_TOP), size (1,-28,0,50).
  - PetList moved down by FEEDER_BAR_H = 58 and its height reduced to match.
  - showTab hides it on the abilities tab.
  - Verified: scrolling the list leaves the bowl in place.
  - Backup PetHelperToggleButton_before_stickyfeeder.
- 2026-10-01 pet row layout:
  - The LevelPill moved to the card's top-left corner (parent row, pos (4,4), ZIndex 3, overlapping the preview).
  - The green LuckPill next to the name was removed; luck is appended to the ability line as "🍀 โชค xN".
  - Backup PetHelperToggleButton_before_lvtopleft.
- 2026-10-01: the pet-menu special description (orange line) is trimmed client-side by trimPetDescription.
  - It drops "นำโชค xN", skill names (ช่วยเก็บเกี่ยว/ปลูกผัก/ตกปลา) and "…ผลผลิต xN", because the skill line already shows them.
  - PetDefinitions.Description is unchanged, so other UIs still show it in full.
  - Backup PetHelperToggleButton_before_desctrim.

Pet book tab (2026-10-02, user request: don't show unowned pets in "สัตว์เลี้ยงของฉัน"; put them in a pet book instead):
- PetHelperToggleButton has a 3rd tab, BookTab "📖 สมุด". Tabs are 1/3 width, TextScaled, max 14.
- BookList ScrollingFrame + BookHeader "📖 สะสมแล้ว x/y ชนิด". createBookRow / rebuildBook show ALL pets sorted by rarity.
  - Owned: preview, name, rarity badge, "✅ มีแล้ว", abilities + luck.
  - Unowned: silhouette "???", "🔒 ยังไม่มี", and UnlockHint or "🐾 ได้จากตู้สุ่มสัตว์เลี้ยง".
- The pets tab now lists owned pets only: petList is filtered after rebuildBook. The title still shows owned/total.
- showTab handles pets/abilities/book and tracks currentTab.
- Gamepad: LB/RB cycle the 3 tabs (TAB_ORDER). Book rows are Selectable TextButtons so the list scrolls.
- Tested with a fake PetListInfo:FireClient list (4 unowned), with no data writes.
- Emoji 🎰 renders as a broken box in Roblox; 🐾 is used instead.
- Backup _Backup_20261001.PetHelperToggleButton_before_petbook.
- 2026-10-02 book rows now show abilities for unowned pets too. The user wants players to see the perks and want the pet.
  - Layout: "Abilities" label (one per line: skill, then "🍀 โชค xN"), orange "Special" line (trimPetDescription), and for unowned a blue "HowToGet" line.
  - Row height = max(80, content): 132 with special + hint, 112 with special only.
  - Name and silhouette stay hidden ("???") for unowned.
  - Backup PetHelperToggleButton_before_bookabilities.

Feeding notices without a box (2026-10-01, user: "ปรับการแจ้งเตือนให้อาหาร ไม่เอาพื้นหลัง ปรับเป็นโปร่งใส"):
- Feed messages were going through HarvestNotifyGui.showSimpleMessage, which draws a red rounded box with a "⚠️ " prefix.
- HarvestNotifyGui now has SOFT_PREFIXES = 🍖 😋 🥫 🔮 🥣 (PetManager feed results / full / not pet food / nine-lives restored, AutoFeeder bowl low / thanks). Messages starting with one of them use showSoftMessage: white text with a dark stroke, no frame and no ⚠️, 20 px, stacked in SoftStack at the top centre (AutomaticSize, so several never overlap), 2.2 s then fade.
- All other custom messages keep the red box. A new feed-related message must start with one of those emojis to get the soft style (or add a prefix).
- Tested in Play with fake messages. Backup _Backup_20261001.HarvestNotifyGui_before_softfeed. Needs Publish.

Gift "ชามอาหารอัตโนมัติ" (2026-10-02, user: send to a friend; Developer Product id 3715846020 = AutoFeederConfig.GIFT_PRODUCT_ID). NOT live-tested by the user, same as the VIP / Sultan / pet-slot gifts (see [[vip-title-system]], [[sultan-pack]], [[pet-slots]]).
- AutoFeeder (Script): the gift section before onPlayerAdded. DataStore "AutoFeederGift_v1" (`pending_<buyerId>` / `to_<targetId>` {from, fromName, t, receipt, seen}); AutoFeederRequest action "giftSelect" (handled before the loaded/owned checks, so non-owners can send); PurchaseRouter.Register(GIFT_PRODUCT_ID, grantGift). A gift to an online target sets st.owned = true and publishes HasAutoFeeder. At join, checkGift runs BEFORE checkOwnership, and checkOwnership now does `st.owned = owns or st.owned` (it used to overwrite with false).
- The target must be in the same server, with HasAutoFeeder non-nil (loaded) and not true.
- UI: VipGui GiftPage kind "autofeeder" (BindableEvent OpenAutoFeederGift); a 🎁 pill under the price button on the QuickShop AutoFeederCard (added at the END of the card section so the cloned VIP / slot / Sultan cards don't inherit it; each has exactly one pill); a 🎁 button beside the buy button on the AutoFeederGui sell page (buy button 186 wide).
- The gift page shows R$ 149 per friend (the pass price).
- Verified in Studio: validation, simulated purchase, page + confirm flow, join path (seen = true), the pill counts. Not verified: the real prompt and a real friend. Test records were removed from AutoFeederGift_v1.
- Backups _Backup_20261001.AutoFeederConfig/AutoFeeder/VipGui/PlantLimitGui/AutoFeederGui_before_feedergift.
- The Studio id changed (now fb69c70e-8ccb-47ad-ab37-df76d8e94e26 on 2026-10-02).

All notifications transparent (2026-10-02, user: "ปรับการแจ้งเตือนทุกอย่างพื้นหลังโปร่งใส"; extends the feed-notice change above):
- HarvestNotifyGui: the red-box showSimpleMessage was deleted. EVERY custom message now goes through showSoftMessage (white text, dark stroke, stacked at the top centre). The SOFT_PREFIXES list is gone. withWarnIcon adds "⚠️ " only when the text starts with a Thai/Latin/digit character (codepoint < 0x2000), because messages that start with an emoji already carry their own icon.
- DonationGui showThanks: no green box, 22 px white text with a green stroke (still slides in at y 72, so it can overlap the soft stack if both fire at once).
- FishingClient hint pill: BackgroundTransparency 1 + text stroke; the state colour passed to setHint now tints the text (lerped 55% to white) instead of the background.
- NOT changed on purpose (designed banners/cards, tell the user): GachaAnnouncer banner, the Sultan join banner (VipGui SultanBanner), the fish CatchCard, the TutorialGui card, FullInventoryGui showNotice (it is only red text on the hint line).
- Tested in Play with fake messages + the DonationThanks remote + the rod hint. Backups _Backup_20261001.HarvestNotifyGui/DonationGui/FishingClient_before_alltransparent. Needs Publish.

Leaderboard without playtime (2026-10-03, user: "ปรับตารางอันดับไม่แสดงเวลาเล่น"): PlaytimeRewards no longer creates the "เวลาเล่น" StringValue in leaderstats (updatePlaytimeStat / formatPlaytime removed). The player list now shows only เลเวล and เหรียญ. Accumulated playtime is still counted and saved: free tickets, the world PlaytimeBoard (OrderedDataStore "PlaytimeLeaderboard_v1") and the PlaytimeTotal row in the status panel (attr PlaytimeTotal) are unchanged. NOTE: the PlaytimeRewards script has sandbox Capabilities, so it can't be cloned into _Backup_20261001; its previous source is saved as the StringValue "PlaytimeRewards_before_nostat_SOURCE" in that folder. Needs Publish. (This file is the wrong topic, kept here only because the notes index has no playtime file.)


---

## pet-gacha-plan

Pet gacha machine for the Roblox farm game (placeId 75556752635760). Planned 2026-09-22/23, built step by step from 2026-09-24 (see Progress).

Decisions the user made:
- Existing players keep every pet they already used (only a few testers) + everyone gets the rabbit (PastelPinkRabbit) as starter.
- Duplicates: player chooses per duplicate — "เศษวิญญาณ" (shards, exchange for a chosen pet) OR level-up. Max level 15; level-up improves BOTH hunger rate and work speed (proposed −2%/+2% per level). Need a default setting for 10-rolls; at max level duplicates auto-convert to shards.
- Two roll buttons: coins and Robux (via "ตั๋วสุ่ม" tickets). Ticket prices not decided.
- First Legendary pet: แมวเก้าชีวิต (nine-lives cat), ability changed by user on 2026-09-23 from Harvester to **ช่วยปลูก (Planter)**. **Built 2026-09-23** (PetDefinitions.NineLivesCat, template ServerStorage.PetTemplates.NineLivesCat): 9 purple spirit flames orbit (= lives left), revives itself to 50% at 0% hunger up to 9 times, feeding restores all lives. User set Legendary HungerRate = 0.75 (hungers 25% slower) on 2026-09-24.
- User wants a slow/new player to get ~1 pet per hour.

Proposed (not yet confirmed): rates Common 70 / Rare 24 / Legendary 5.5 / Secret 0.5 %, pity system, daily free ticket, daily cap on coin-bought tickets.

**Why:** economy estimate from code — new player ~3k coins/h, mid ~20–30k/h, fully maxed (NineTailFox ×2 + boosters + 5★ watermelon) ~330k/h, so a flat 3,000-coin ticket would let maxed players roll ~110×/h. Numbers are code estimates, should be measured in playtests before pricing.

**Progress:** step 1 (ownership) DONE 2026-09-24 — module ServerScriptService.PetSystem.PetOwnership (DataStore "PetOwnership_v1", merge-only UpdateAsync; Grant(player, petId) -> isNew, saved; Changed event; UNLOCK_ALL switch). Menu shows unowned pets as black silhouettes "???" + 🔒 and "(owned/total)" in title. Test account One_moretime91 owns all 6.
Step 2 DONE 2026-09-24: ServerScriptService.PurchaseRouter owns MarketplaceService.ProcessReceipt (Register(productId, {name, grant, allowOffline, trackReceipt}); receipt log DataStore "PurchaseReceipts_v1"). Donations/x100/plant-quota moved there (quota now UpdateAsync + receipts, fixed overwrite-on-failed-load bug). Ticket products in ReplicatedStorage.GachaConfig.TicketProducts (1 Premium ticket = 3714474158, 10 = 3714474283), registered by GachaService (old GachaTicketService deleted in step 3). Gotcha: editing a script via .Source then via multi_edit reverted the .Source change — use ScriptEditorService:UpdateSourceAsync or only one method per script. Also, calling UpdateSourceAsync on the same script several times in one execute_luau call, each re-reading script.Source, silently drops earlier patches (.Source is stale right after an update). This lost the PetHunger require on 2026-09-24. Accumulate all edits in one local string and call UpdateSourceAsync once per script.

Step 3 DONE 2026-09-24: two ticket types in GachaConfig.TicketTypes — Normal (3000 coins, odds 80/17/2.8/0.2) and Premium (Robux products, odds 60/30/8/2); no daily limit. GachaTickets stores counts per type (attrs GachaTickets_Normal/_Premium). ServerScriptService.GachaService: RemoteFunction GachaRequest(action "info"/"buyCoins"/"roll"), RemoteEvent GachaOpen; rolls server-side, spends tickets first, refunds if grant fails; duplicates counted in PetOwnership record `dupes` via GrantBatch; PolicyService blocks Premium where paid random items restricted. Machine = workspace.GachaMachine (AI mesh, pink cat capsule machine near shop). Client UI = StarterPlayerScripts.GachaGui. Robux prices shown live from Dashboard (were 39/390 R$ on 2026-09-24). Step 4 DONE 2026-09-24 (duplicates):
- Config: ReplicatedStorage.PetLevelConfig. MAX 15; each level +2% work speed and −2% hunger. Shard value per duplicate: Common 1 / Rare 5 / Legendary 25 / Secret 60. Shard cost per pet: 20 / 60 / 200 / 500. Rarities are pinned — not user-confirmed.
- Data: the PetOwnership record gained `levels` and `shards`; attrs PetLevel_<id>, PetDupes_<id>, PetShards.
- New PetOwnership functions: UseDupes (level / shards) and ExchangeShards. A duplicate of a maxed pet auto-converts to shards in GrantBatch.
- Level effects: PetHunger.GetSpeed / Consume use the level; PetController's work duration is divided by the speed.
- GachaService actions: levelUp / toShards / exchange. Exchange is allowed only for pets in the current pool, so Secret only during events.
- UI: GachaGui "💠 ตัวซ้ำ & เศษ" tab. The pet menu shows "Lv.X ⬆️dupes" pills.
- The test account One_moretime91 had 40 real duplicates from the user's own rolls; tests were restored from a snapshot. Backups are in ServerStorage._Backup_20260924_step4.

Step 6 DONE 2026-09-24 — all gacha plan steps are now complete:
- Reveal: GachaGui playReveal is a 2D capsule (CanvasGroup halves). It drops and shakes; shake 2 hints the best tier's color; shake 3 adds rays for Legendary+. It pops with a flash and big text, is skippable by tap, and sets the local attr GachaRevealing.
- Announce: GachaService announceRoll fires RemoteEvent GachaAnnounce to all clients for Legendary+. Secret is also published via MessagingService topic "GachaAnnounce_v1", which ignores the server's own JobId.
- LocalScript GachaAnnouncer shows the top banner queue, a TextChatService RBXGeneral system message, and a sparkle burst at the machine. For the player's own roll, it waits until the reveal ends.

User decisions on 2026-09-24 after step 6:
- Normal ticket costs 20,000 coins.
- Premium 10-pack gets a 5% discount. Advised R$370 vs R$39×10; the user sets it in the Dashboard, and the GUI shows "(-X%)" computed from live prices.
- Shard values accepted, but the Secret tier cannot be bought with shards (ShardCost has no Secret key); Secret duplicates can still become 60 shards.
- Event dates are kept.
- New players start with the rabbit only (UNLOCK_ALL stays false).

Playtime tickets (2026-09-24):
- Rules: 1 Normal ticket per 60 min online, max 5 per day (resets at Thai midnight). Progress persists across sessions. Daily coin milestones: 10 min = 1,000 and 30 min = 3,000.
- AFK counts on purpose: the user said the game is designed for AFK play, so there is no anti-AFK. Don't add it.
- Files: ReplicatedStorage.PlaytimeConfig, ServerScriptService.PlaytimeRewards (DataStore "PlaytimeRewards_v1"), LocalScript PlaytimeGui (row LayoutOrder 5 in CurrencyGui.StatusPanel).
- Ticket delivery: via GachaTickets.Add with idempotent receipt "PT-<day>-<n>"; the earned state is saved before delivery, with an `undelivered` retry list.
- Total playtime: `totalOnline` seconds (all-time, counted from 2026-09-24 only) is exposed as attribute PlaytimeTotal (minutes). It shows as "⏱️ N" right-aligned on CurrencyGui.StatusPanel.LevelRow, abbreviated k/m/b and rounded down.

Change on 2026-09-24 (user request): a duplicate now auto-levels the pet by +1 immediately (GrantBatch; ExchangeShards on an owned pet also gives +1 level). At Lv.15 a duplicate becomes shards. There is no manual level/shard choice anymore. Old pending `dupes` are converted on Load by applyPendingDupes (levels first, overflow to shards) with a notify. The GachaGui tab is renamed "💠 เลเวล & เศษ" and shows levels plus the shard-exchange button only. Also on 2026-09-24: ChibiFox changed to Rare + Planter.

Showcase (2026-09-24): GachaService clones the top-tier pet (currently NineTailFox), scale 1.8, anchored, as workspace.GachaShowcase above the machine; a BillboardGui "ShowcaseLabel" on the machine shows the tier, the per-pet chance for coin/Robux tickets, the name in a rainbow gradient, and the perks. LocalScript GachaShowcaseClient makes it bob, sway and cycle rainbow colors; PetFireflyRing supports the FireflyScale attr. Event + pity (2026-09-24, user-specified): the Secret tier appears only during GachaConfig.Events (first event: NineTailFox, 24 Sep – 15 Oct 2026, Thai time; switches automatically). Normal ticket rates: event 94.1/5.1/0.6/0.2, off-event 94.3/5.1/0.6. Premium: event 91/7/1.5/0.5, off-event 91.5/7/1.5. Pity per ticket type — Normal: Rare+ every 10, Legendary within 90, Secret within 200; Premium: 10/50/100. The Secret counter only advances during events and carries across events; a Secret result also resets the Legendary counter. Pity is stored in the GachaTickets_v1 record `pity`, spent and updated atomically in GachaTickets.SpendAndRoll, and restored by Refund. The GUI shows the pity table, the player's remaining rolls, and simulated "≈ rate including pity"; results show 🛡️ for guaranteed rolls. The coin price of 3000 is temporary. Simulated mouse clicks in Studio are unreliable (hit wrong buttons, bought tickets) — verify via server calls instead.

Shard level-up for non-exchangeable pets (2026-10-08, user request): Otter 200 / Secret-tier 500 / Sultan-tier 750 shards = +1 level, only if the pet is already owned (otherwise "ไม่สามารถอัพเลเวลได้"; no shards taken). Config PetLevelConfig.LevelUpCostByPet/ByRarity + LevelUpCostOf; PetOwnership.LevelUpWithShards; GachaService action `shardLevelUp` + info `LevelUpCost`; GachaGui dupes tab button "⬆️ อัพเลเวล". Exchange of new copies stays blocked for those pets. Studio test trick: workspace attr `DevPetKeyOverride` = fake DataStore key + mock player table (no real data touched). Needs Publish.

**How to apply:** build order agreed: 1) pet ownership system + migrate old players, 2) make ProcessReceipt (lives in PlantingSystem, shared with donations/x100 booster/plant-quota) handle ticket products, 3) tickets + machine + shown odds (required by Roblox for paid random items; hide Robux machine via PolicyService where restricted), 4) duplicates shards/level-up, 5) nine-lives cat, 6) egg animation + server announce + pity. Related: [[nine-tail-fox-design]].


---

## pet-slots

User chose to sell the 3rd active-pet slot as a Game Pass (option 2 of: level unlock / Game Pass / both). Game Pass ID 2001134393, price set by the user at R$299.

- Config: ReplicatedStorage.PetSlotConfig {GAMEPASS_ID, BASE_SLOTS 2, BONUS_SLOTS 1}.
- Server PetManager:
  - checkPetSlots(player) runs BEFORE applySavedSettings in setupPlayer (UserOwnsGamePassAsync, 3 tries) and sets player attr PetSlots (2/3). Studio test: player attr DevGrantPetSlot = true.
  - PromptGamePassPurchaseFinished sets it to 3 and notifies.
  - maxActivePets(player) replaced MAX_ACTIVE_PETS.
  - When full, it removes the OLDEST pet (petInstance.spawnedAt) instead of an arbitrary one. Without the pass it shows a one-time hint (attr PetSlotHintShown).
  - The slot is the lowest free number (the old rabbit-specific rule was removed).
- PetController.SlotSide(ownerCF, slot): 1 = right, 2 = left, 3 = behind (-LookVector). Used by the 3 follow/spawn spots + PetManager.gatherPets.
- UI:
  - PetHelperToggleButton SlotBar at the bottom of the pets tab: "🐾 พาออกมา x/y ตัว" + BuySlotButton ("🔓 ช่องสัตว์ +1 · R$299" / "✓ ช่องสัตว์ +1"). Only visible on the pets tab; petListFrame is shortened by 48.
  - PlantLimitGui QuickShop "PetSlotCard" (LayoutOrder 5), cloned from AutoFeederCard.
- ActivePetsHud with 3 cards + feeder fits on the 1008x567 test screen.
- Tested: the creator auto-owns it (PetSlots = 3); the no-pass simulation (PetSlots = 2) dropped the oldest pets and showed the price/hint; positions right/left/behind. The user's pets were restored to NineTailFox + NineLivesCat.
- Earlier impact analysis (for the user): pet luck is additive (Common 2 / Rare 5 / Legendary 10 / Secret 20); the best 3-pet luck is x40 vs x30. Food use +50%. Server pet cost +50%.

Gift "ช่องสัตว์ +1" (2026-10-01, user: send to a friend; Developer Product id 3715828318 = PetSlotConfig.GIFT_PRODUCT_ID). NOT live-tested by the user, same as the VIP and Sultan gifts (see [[vip-title-system]], [[sultan-pack]]).
- ServerScriptService.PetSlotGift (ModuleScript, required at the top of PetManager so it always runs): DataStore "PetSlotGift_v1" (`pending_<buyerId>` / `to_<targetId>` {from, fromName, t, receipt, seen}), RemoteFunction RemoteEvents.PetSlotGiftRequest ("giftSelect", targetUserId), PurchaseRouter.Register(GIFT_PRODUCT_ID, grantGift). A successful gift for an online target sets the player attr PetSlots = BASE + BONUS directly; PetManager.checkPetSlots also calls PetSlotGift.HasGift(player) at join (owns = pass OR gift record; the first time after an offline gift it notifies after 8 s and sets seen).
- The target must be in the same server and have no extra slot (PetSlots <= BASE; PetSlots nil = still loading).
- UI: VipGui GiftPage kind "petslot" (BindableEvent OpenPetSlotGift); 🎁 pill under the price button on the QuickShop PetSlotCard; a 🎁 button left of the buy button on the pet menu slot bar (it closes the pet menu first).
- The gift page showed R$ 299 per friend (the pass price).
- Studio hooks: DevGiftSimulate / DevGiftOffline (server attrs), DevGiftFakeFriends (client attr). Test records were removed from PetSlotGift_v1.
- Verified: validation, simulated purchase saves `to_` and clears pending, page and confirm flow, HasGift (first call true and marks seen, second true, no record false), pet menu button. Not verified: the real prompt and a real friend.
- Backups _Backup_20261001.PetSlotConfig/PetManager/VipGui/PlantLimitGui/PetHelperToggleButton_before_petslotgift.

2026-10-02 (user: "ในสัตว์เลี้ยงของฉัน ไม่เอาส่งของขวัญ"): the 🎁 button on the pet menu slot bar (GiftSlotButton in PetHelperToggleButton) was REMOVED. The pet-slot gift is now only reachable from the 🎁 pill on the QuickShop PetSlotCard (VipGui kind "petslot" / OpenPetSlotGift unchanged). Backup _Backup_20261001.PetHelperToggleButton_before_nogiftbtn. Needs Publish. Don't re-add gift buttons inside the pet menu.

BUG "after a server restart players only get the rabbit" (2026-10-02, user report) — causes found + fix in PetManager (backup _Backup_20261001.PetManager_before_savesafety):
- Likely cause 1 (reproduced in Studio): the saved settings (PetSettings_v1: active pets list, abilities, hunger, lives) could not be LOADED at join (DataStore throttled when many players rejoin after a restart; applySavedSettings returned false after ONE failed GetAsync) → the rabbit was spawned as the fallback → the 5 s periodic save (scheduleSave) then OVERWROTE the real list with just the rabbit (and reset hunger to full). That is permanent.
- Likely cause 2 (code reading, not reproduced): on shutdown PlayerRemoving saves and then removeAllPets, and BindToClose saved AGAIN for players still listed → an EMPTY pets list overwrote the good one → next join gets the rabbit (`#data.pets == 0` → default).
- Fix: (a) applySavedSettings retries GetAsync 4 times (waits 2/4/6 s); if it still fails it sets settingsLoadFailed[player], the rabbit is spawned, saveSettings REFUSES to save for that player, and setupPlayer keeps retrying every 20 s (LOAD_RETRY_SECONDS) until it loads, then restores the saved pets (the rabbit, the oldest, is dropped when over the slot limit) and refreshes the pet menu. (b) finalSaved flag (weak table) set in PlayerRemoving right after the final save; saveSettings returns if it is set, so BindToClose can't overwrite.
- Studio test hook: workspace attribute DevFailPetLoad = N makes the next N GetAsync attempts fail (set it in Edit mode, remove it afterwards). Tested with 4: the rabbit was the only pet during the failure window, the saved list and its UpdatedTime stayed unchanged, and ~20 s later the 3 saved pets came back with the log "โหลดการตั้งค่า … ได้แล้ว". Data after a normal Play stop was intact.
- Players who were already hit by the overwrite lost their saved active list (they keep all OWNED pets: PetOwnership is a separate DataStore that only merges); they just need to pick their pets again. Hunger/lives of pets may have reset to full.
- Same class of risk to remember for other per-player stores: never save after a failed load (HotbarLayout and LeaderstatsSetup already guard against it).
- Needs Publish.

NO starter rabbit for new players (2026-10-02, user: "สัตว์เลี้ยงผู้เล่นใหม่จะไม่แจกกระต่ายแล้ว"):
- PetOwnership: the rabbit (STARTER_PET_ID) is no longer owned by everyone. Owns() has no free pass; normalize()/markOwned()/Load() no longer force it. A BRAND-NEW player (no PetOwnership record AND PetSettings legacy data == nil) starts with no pets: Load saves an empty record right away (saveMerge(player, {})) so later joins never take the migration path (without it, the PetSettings that exist after their first session would count as "legacy" and hand out the rabbit).
- Existing players KEEP the rabbit: players with a record already have it in `owned` (every old normalize() forced it); players with legacy settings but no record (migration) still get the rabbit + the pets they used.
- The rabbit is not NotInGacha, so a new player can still win it from the gacha. PetManager needed no change: its fallbacks call ensurePet(DEFAULT_PET_ID), which returns when the player doesn't own it.
- UI: PetHelperToggleButton shows an "EmptyHint" in the pets tab when no pet is owned ("ยังไม่มีสัตว์เลี้ยง · สุ่มได้ที่ตู้สุ่ม (☰ → วาปไปจุดต่างๆ) · ดูในแท็บสมุด"). TutorialGui: the "feed" step completes by itself when the player owns no pet (no PetLevel_* attribute), so a new player isn't stuck at step 7; the first pet comes from the gacha steps (9-10, free first Normal ticket).
- Studio test hook: workspace attribute DevPetKeyOverride = fake key makes PetOwnership use that DataStore key instead of the UserId (Edit mode, remove afterwards). Tested with cloned module instances: brand-new → no rabbit, empty record saved; after Grant(ChibiCat) owns only the cat; rejoin with a legacy table → still no rabbit; legacy migration → rabbit + used pet; existing record → rabbit kept. Test keys removed.
- Not tested with a real brand-new account. Things that may still assume a pet at the start: nothing else found by grep (only PetManager/PetOwnership referenced STARTER_PET_ID / DEFAULT_PET_ID). Backups _Backup_20261001.PetOwnership/PetHelperToggleButton/TutorialGui_before_nostarter. Needs Publish.


---

## photo-mode

User 2026-10-03: "โหมดถ่ายภาพ เคลียร์หน้าจอ UI ต่างๆ ซ่อนได้" → planned 3 phases, user chose "ทำเฟส 1". Phase 2 (capture button via Roblox Captures, zoom/FOV) and 3 (colour filters, hide pets/character, emote panel inside) NOT done.

- `StarterPlayerScripts.PhotoModeGui` (LocalScript): enter via ☰ → "📷 โหมดถ่ายภาพ (P)" (MoreMenuGui entry id photo, BindableEvent PhotoModeGui.OpenPhoto) or key P (toggle; not while typing); exit via bar button, P, or gamepad B.
- Hides: every ScreenGui in PlayerGui (original Enabled saved, restored on exit; includes TouchGui thumbstick/jump; a listener re-hides any GUI a script turns back on; new GUIs added meanwhile are hidden too), CoreGui Chat/PlayerList/Backpack/EmotesMenu/Health via SetCoreGuiEnabled (restored only if they were on), and overhead BillboardGui "PlayerNameTag" (default hidden; toggle button "ป้ายชื่อ: ซ่อน/แสดง"). Roblox's own top-left menu button can't be hidden. The game keeps running (auto fishing etc.).
- Bottom bar (CanvasGroup, DisplayOrder 1000): "ออกจากโหมดถ่ายภาพ" + names toggle; shows 3 s on enter, fades, any click/tap/gamepad button brings it back for 3 s.
- Verified in Studio Play (PC): enter from the menu and with P, 24 GUIs hidden, name tag hidden, bar fades after 3 s, tap shows it, exit restores all 24 GUIs. NOT verified: phone (touch controls), real gamepad, the names toggle button click (test path hit the exit button), CoreGui hiding (not visible in screenshots). Backup _Backup_20261003.MoreMenuGui_before_photo (without the new entry). Needs Publish.

INCIDENT same day: during this test the Studio account's level showed 1 — PlayerLevel_v1 for 9360333174 was {Level 1, XP 76}; the real level was 161. A Studio Play session with a failed/throttled level load saved the default over it (the LevelSystem bug already flagged and spun off as a task: no retry, no save guard). I set leaderstats level 161 during Play and stopped: stored now {Level 161, XP 76}. The old XP progress within level 161 (the bar was ~70% of 16,100 earlier) is lost. LESSON: after several quick Play start/stops check PlayerLevel_v1 and other stores; the LevelSystem guard task should be done soon.

2026-10-09 bug fix: entering disabled CoreGuiType.All but exit restored only 5 types, so Roblox's Captures (photo) menu, SelfView, AvatarSwitcher, ExperienceShop stayed hidden after exit. CORE_TYPES is now every CoreGuiType except All (state saved and restored per type). Tested with P in/out: all types restored. Studio-only until published.

2026-10-09 phases 2+3 DONE (Studio): two-row bar with named buttons (Shot/Filter/ZoomOut/ZoomIn/Pets/People/Poses/Names/Exit): CaptureService screenshot + PromptSaveCapturesToGallery (untested, needs live), 7 ColorCorrection filters (Lighting.PhotoModeFilter), FOV 20-100, hide pets / people modes (local Transparency/Enabled store, re-check 0.5 s), EmoteGui allowed while active, gamepad X/Y/LB/RB/DPad. Labels button hides ALL BillboardGuis (workspace + PlayerGui) except RodHalo/RainbowStar; ProximityPromptService off; mouse icon hidden when bar fades; held tool ManualActivationOnly; player attrs PhotoMode / PhotoHidePets read by PlantSlotGuide, BoosterPlacer, PetFireflyRing. 🐾 emoji renders blank in Roblox fonts (use 🐶). Testing tip: click bar buttons with user_mouse_input instance_path "LocalPlayer.PlayerGui.PhotoModeGui.Bar.Row1.<Name>" (coordinates from screenshots are offset); click the screen first if the bar faded.


---

## planting-click-and-perf

Click-to-plant felt "off target / sometimes dead" because the mouse ray was blocked, not because planting was slow. Measured round trip click→plant is only 34-53 ms.

Fixed 2026-10-01 (step 1 of 4): `FarmGridConfig.ResolveSoil` + `GetAimedGroundPoint` (ray-plane intersect with the soil top) are now shared by `SeedClickPlanter` and `PlantSlotGuide`, and `CanQuery = false` is set on slot anchors and on every cloned crop part. Result: aiming at 81 slots around a mature watermelon went 51/81 → 81/81 plantable, guide drift 4.7 studs → 0.

**Why:** aiming at a slot centre often hit the invisible 0.2-stud `PlantSlot` anchor (21% of clicks at a flat camera angle) or crop leaves (27/81 under one watermelon canopy); `SeedClickPlanter` only accepted `target.Name == "Soil"` and bailed silently, and the guide computed its slot from the leaf-surface hit point.

**How to apply:** when something "does not react to clicks" here, check CanQuery blockers and whether the client picks the soil from the raw hit instead of a projected ground point.

Measured budget while testing (Studio play, so FPS is pessimistic but counts are real): client 71,522 parts / 4.5 GB, 15 fps; workspace 156k instances, 101k parts — HikingMap 49,402, FarmPlots 24,053 (≈24,012 invisible slot anchors), TerraceDressing 21,986. Slot anchor positions match `FarmGridConfig` exactly on all 41 soil plates, so anchors can be derived instead of pre-created.

Remaining plan: step 2 create slot anchors lazily on plant (touches [[terrace-zone]] soils, FarmSlotRegistry and pet abilities that read `slot.anchor.Position`); step 3 clone only the visible stage instead of all 5 (watch the dawn aura Highlight that adorns Stage5); step 4 map-wide part budget for HikingMap/TerraceDressing + streaming.

Gift "โควต้าปลูก +5" (2026-10-02, user: "บอกผิดทำส่งของขวัญของเพิ่มโควต้าปลูก" after I wrongly rebuilt the feeder gift). **The gift product id is SET: 3715853171** (PlantingSystem `GIFT_PRODUCT_ID`, given by the user 2026-10-02; the gift page showed R$ 50 per friend; NOT live-tested). The user must create a separate product "ของขวัญโควต้าปลูก +5" (do NOT reuse BOOST_PRODUCT_ID 3712426475, the receipt can't tell a gift from a self purchase) and give me the id; then set the constant. (If it is ever set back to 0, the 🎁 buttons are hidden in the live game and only appear in Studio, simulated.)
- PlantingSystem "ของขวัญโควต้าปลูก" section (before MAX_PLANT_DISTANCE): RemoteFunction RemoteEvents.PlantQuotaGiftRequest ("giftSelect", targetUserId), DataStore "PlantQuotaGift_v1" (only `pending_<buyerId>` keys), PurchaseRouter.Register(GIFT_PRODUCT_ID, grantQuotaGift). The grant does UpdateAsync on the TARGET's key in boostDataStore ("PlantBoostPurchases_v1"): count += 1, receipt "gift_<PurchaseId>" (dedupe, max 50 receipts). So it works even if the target left, and gifts stack (each +BOOST_AMOUNT = 5 plants). An online target gets boostPurchaseCount updated + notifyPlantLimit + a notice.
- No "already has" rule (stackable); the target must be in the same server with boostPurchaseCount loaded (non-nil). Self-gift is rejected (it points to the shop).
- The id is published to clients as attribute GiftProductId on RemoteEvents.PromptPlantBoost (next to ProductId / BoostAmount).
- UI: VipGui GiftPage kind "quota" (BindableEvent OpenQuotaGift); a 🎁 pill on the QuickShop BoostCard. That card is 72 high (the others 84), so its buy button is at y 4 and the pill at y 46, 22 high.
- Verified in Studio (simulated): validation, `to` key got {count 1, receipts [gift_studio_…]}, own record untouched, pending cleared, page + pill layout. Test keys removed from the DataStores. Not verified: the real prompt and a real friend.
- Backups _Backup_20261001.PlantingSystem/VipGui/PlantLimitGui_before_quotagift.
- The Studio id changed again (58bdfdb8-229e-4b22-ae2c-137d1c1b1905 on 2026-10-02).

Perf baseline 2026-10-13 after the island rebuild ([[island-rebuild-plan]]), Studio Play, Halloween dev-forced ON: workspace in Edit = 16,978 instances / 7,067 parts (HikingMap 2,229, loose "Model" 1,002, Beach 798, IslandDecor 603, Lights 444); client in Play ≈ 8,500 parts (RainDrops 380 and RodShowcase 373 are runtime-made). Server heartbeat 1.3–1.8 ms, physics 0.9 ms → scripts are not the bottleneck. Client: 14–18 fps, FrameTime 59 ms, RenderCPU 56 ms, GPU 37 ms; triangles 0.36M (pond/terrace) to 1.0M (seed-shop plaza), draw calls 200–430. A/B at the plaza (hide one group client-side, read `Stats.SceneTriangleCount`): HikingMap −232k tris / −131 draw calls, Halloween decor −80k, Halloween skin −35k, PlaytimeBoard −19k, FarmFlora −15k, Shops −15k, TrashEventSign −8.6k; ≈580k left = terrain + water + grass + characters (not separable from script). Studio fps was also ~15 on 2026-10-01 with 71k parts, so Studio fps on this PC does not track part count — do not use it as proof of lag; ask for real-device numbers. `Stats.SceneTriangleCount / SceneDrawcallCount / RenderCPUFrameTime / RenderGPUFrameTime / HeartbeatTime` are readable from a client execute_luau; `workspace.StreamingMinRadius`, `Lighting.Technology`, `Terrain.Decoration` are not.

Status check 2026-10-13: steps 2 (anchors only while a plant exists, `slot.position` replaces `anchor.Position`) and 3 (one stage model at a time) are DONE in PlantingSystem; edit-mode workspace is ~10k parts (HikingMap 2,247, FarmPlots 53, TerraceDressing 98). Streaming settings review still open. Pumpkin optimisation follow-ups are tracked in [[pumpkin-vine]].
Debug log switch (2026-10-14): PlantingSystem per-plant prints now run only when workspace Attribute `DebugPlanting = true` (`debugOn()`); off by default. Use it when chasing harvest/planting bugs instead of re-adding prints.

Crop optimisation round 2 (2026-10-14, user approved steps 0+1 of my plan; Studio only, not published):
- Done: Stat attributes on PlantingSystem script (StatPlanted/StatHarvested/StatStageModels) logged as `sample.crop {p,h,m}` by ServerHealthLogger; crop sounds via RemoteEvent CropSound → CropSoundClient (no server Part/Sound); anchor PlantSlotN IS the wet patch now (on the surface, rotated with soil; WetPatch gone; CropAura +0.48 height compensation; models pivot from slotPosition); ProximityPrompt only created at stage 5 (ensurePrompt); PlayerRemoving per-slot pcall. Play-tested one pumpkin, OK.
- Not done: Studio soak test (needs the owner NOT live, see [[live-session-overlap]]).
- Plan step 2 still open, user to choose: A = client-side crop rendering (server keeps 1 part + attributes; touches CropAura, CropLod, PetWorkEffects, click/guide), B = 3 visible stages instead of 5 (~40% fewer clones). Decide after live data from step 0. Stage swaps destroy+clone the model every 3.3–16 s per plant — that churn is the main server cost.


---

## play-area-walls

User 2026-10-03 (top-view screenshot of the two grey mountains): "ไม่ให้ผู้เล่นขึ้นไปบนเขาสองลูก และไม่ให้ไปโซนข้างหลังเขา".

- `ServerScriptService.PlayArea` (ModuleScript): `Points` = fence polyline {x,z} from the north sea (370, 1800) along the farm-side foot of the right (north) massif and the left snow mountain to the south sea (780, −1800); `FenceX(z)`, `IsBlocked(x,z)` (east of the line = blocked), `BuildWalls(parent)` rebuilds `workspace.PlayAreaWalls`.
- `workspace.PlayAreaWalls`: 21 anchored Parts, y −40..360, 4 thick, Transparency 1, CanCollide true, **CanQuery false** (camera, clicks, fishing raycasts pass through), CanTouch false, Locked. Static in the place (built once in Edit). If Points change: `require(PlayArea).BuildWalls(workspace)` in Edit.
- Farm side kept: terrace hill, stream (warp 360,−191), mistlake (470,−135) + LakeViewpoint (446,−148), RestCamp (408,109), the small south hill, the west part of the south band (x < 780) and the strip x < 370 of the north band. Blocked: both grey mountains, the hiking trail up them, the east plain, the rest of the north/south bands.
- The walls reach z ±1800 where the sea ends (water ends at ±1792; beyond is void), so swimming around is blocked too ([[sea-and-beach]]).
- LastPosition: `validPoint` also requires `not PlayArea.IsBlocked` → a saved spot behind the wall is not stored / not restored (backup `_Backup_20261003.LastPosition_before_playarea`).
- Verified in Play: walking + jumping toward the wall at z 300 stops at x 327.6 (fence 330); swimming at z 1000 stops at x 366.6 (fence 370). I moved the test character back to spawn before stopping Play so LastPosition saved the spawn. Screenshot with the walls temporarily red showed the line; they were set back to invisible.
- Related: [[far-mountains-removed]] (what's behind the wall). Needs Publish.


---

## player-behavior-analysis

Done 2026-10-16 at the user's request ("ผู้เล่นเริ่มหาย ช่วยตรวจพฤติกรรมผู้เล่น"). Read-only, nothing changed.

Method (Studio execute_luau, background task.spawn + results kept in `shared`, polled with short calls):
- `PlaytimeLeaderboard_v1` (OrderedDataStore) = total minutes per user (AFK time included). 337 users had >0.
- Per user: `PlaytimeRewards_v1` (.day = last Thai day played, DayNumber today = 20742 on 10-16), `Tutorial_v1` (step 13 = finished, done+step<=12 = skipped, not done = stuck), `PlayerLevel_v1`, `PlayerCoins_v1`, `DisconnectLogs_v1`.
- First-play date = `PlayerLevel_v1` GetAsync keyInfo.CreatedTime; last activity = UpdatedTime. 406 level keys = all players ever.
- Coins exactly 101,050 = took the 100k welcome gift + 1,000 skip reward and did nothing else.
- Gotchas: the user toggles Play/Edit often; a Server-DM task dies on Stop but an Edit-DM task keeps running through Play. Dump results in chunks as you go. Whole-game GetDescendants scans dropped the MCP connection twice. Budget in Edit ~0.6 users/s (5 Gets each).

Findings 2026-10-16:
- New players per day (first-play date): 10-04 26, 10-05 39, 10-06 26, 10-07 20, 10-08 31, 10-09 54, 10-10 82, 10-11 37, 10-12 31, 10-13 22, 10-14 8, 10-15 18, 10-16 4 (partial).
- Median playtime of each day's new players: 10-07 149, 10-08 48, 10-09 33, 10-10 27, 10-11 12, 10-12 4, 10-13 4, 10-14 2, 10-15 3 min. Came back another day: 10-07 75%, 10-10 37%, 10-12 10%, 10-13 9%.
- Tutorial: ~75% of new players skip it every day, before and after the drop, so a change in skipping does NOT explain the drop. 185 of 337 players are level 1-4; 90 of the 110 who played under 5 min are still level 1.
- Core: 42 players with 10h+ total; 26 of them played today or yesterday. Mid players (5 min to 3 h) mostly gone by day 3-7.
- Public API: visits 6,559, 10 favorites, 17 up / 0 down votes, genre "Utility & Other" (bad for discovery).
- 24 users made developer-product purchases (597 receipts; Game Passes not counted).
- Timing matches the ~10-12 changes (island/map rebuild, shops moved, fish v2 enabled, camera zoom reduced) and the server crash/memory-leak days 10-12 to 10-15 (fixed 10-16). Cause NOT proven; the next step suggested to the user was to play a brand-new account's first 5 minutes on a phone and check the Creator Dashboard retention/session graphs.
Re-check 2026-10-19 23:20 (user asked "new players: how many, who, playtime"): 569 level keys total. New per day 10-16 7, 10-17 26, 10-18 50, 10-19 84 (big jump on the [[birthday-event]] day). Median playtime 10-17 1, 10-18 2, 10-19 5 min; 10-19 had 21 players ≥30 min, 13 ≥60 min (top JularatBowzi 339, ojolopo2 286, miku_zx72 282). 10-18 mapaow_05 1,762 min / L128 (AFK included). About 25 per day have no PlaytimeLeaderboard entry = left in under 1 min. The tutorial is still mostly skipped. Took ~7 min for the 569 CreatedTime Gets + ~3 min for 167×3 Gets (Edit DM, survives Play).
Related: [[tutorial]], [[server-crash-diagnosis]], [[island-rebuild-plan]].


---

## premium-witch-pet

User 2026-10-14 (with a reference picture: chibi witch on a broom, purple hat with moon/stars, satchel, wand with glowing purple orb, purple magic swirls/stars/runes): new pet "แม่มดน้อย", tier "พรีเมียม", Robux only; level only by buying again (+1 per purchase, can't buy at Lv.15), no spirit-shard exchange/level-up; ability: plant 2 at a time; casts magic at the plot it plants, aura like the picture.

- Config `ReplicatedStorage.PremiumPetConfig.Pets.LittleWitch = { ProductId = 3718537123, MaxLevel = 15 }` (product "แม่มดน้อย", 450 R$, set 2026-10-14); price shown in-game comes from GetProductInfo. Icon for the product: `product_icons/little_witch_icon.png`.
- `ServerScriptService.PremiumPetService`: RemoteEvent `PremiumPetBuy(petId)` → level/open-prompt checks → PromptProductPurchase; grant via PurchaseRouter → `PetOwnership.GrantPremium`. Studio sim when ProductId = 0: workspace attr `DevPremiumPetSim = true` (writes real data unless `DevPetKeyOverride` is set to a FAKE key — see [[dev-pet-key-override-gotcha]]).
- Rarity `Premium` in PetRarity (Order 4.5). No ShardCost / LevelUpCost → shards can't touch it; `NotInGacha`.
- Ability = existing `Planter` with def fields `PlantBatch = 2`, `CastReach = 6`, `CastFx = true` (Planter branches on these; other pets unchanged). Hunger: one job per cast.
- Buy UI: GachaGui 💠 "เลเวล & เศษ" tab row button (GachaService sends `Premium = { ProductId, Price, MaxLevel, OnSale }`). Also a card `LittleWitchCard` in the QuickShop "ร้านค้าสุดพิเศษ" (PlantLimitGui, LayoutOrder 2, next to the Sultan card), added 2026-10-14.
- Template `PetTemplates.LittleWitch`: single AI mesh (2nd try; the 1st had dot eyes + red lips = scary for this user), faces -Z with the broom sideways, HRP + RootJoint + Humanoid + AuraHighlight + ghost's sparkle emitters.
- Tested: fake-key purchase flow 1 → 2 → 15 → refused. NOT tested: bringing the witch out (PetSelect writes the real account's pet settings), real 2-plant cast + FX in Play, real Robux prompt, menu previews.
- 2026-10-14 later: user wants the witch released WITH Halloween → `PetDefinitions.LittleWitch.Season = "Halloween2026"` (removed from the table until HasStarted; owners keep it after the event), `PremiumPetConfig.Season` + `IsReleased()`, QuickShop card only built when released. Live = Halloween2026 Enabled + 24 Oct 00:00 Thai; long-running servers need a restart to get her.
- 2026-10-14: user set witch luck = 30 (same as Secret pets: ghost / nine-tail fox) → `Luck = 30` in her def (Lucky ability auto-added), card + description mention "นำโชค x30". Studio id changed again that day (e8a8baa9-…); unsaved work survived.
- 2026-10-14 cast timing (user): wand-raise pre-time 2.0 s at Lv.1 shrinking linearly to 1.0 s at Lv.15 (`castPreTime` in Planter), with a charging orb (`chargeStart`) during it; then the soft translucent cast FX (ForceField halo/rings/light column, fades in/out). Estimated Lv.1 ≈ 35–40 plants/min, Lv.15 ≈ 60–70 (computed, not timed).
- 2026-10-14 final cast timing (user chose option B): pre-time 1.5 s at Lv.1 → 0.75 s at Lv.15 (`CAST_PRE_MAX/MIN`). Estimated Lv.1 ≈ 44 plants/min, Lv.15 ≈ 69 (normal planters ~35–40, Sultan dragon ~100–113). Superseded the 2.0 → 1.0 note above.
- 2026-10-15 back of head looked bald/blobby (AI texture paints it skin-pale) → added `BackHair` model in the template: brown ball cap (138,90,60) + 2 small pigtails with orange ties, Welds to Torso (offsets in Torso space). Backup `ServerStorage._Backup_20261015.LittleWitch_before_backhair`. Checked on a preview copy (back/front/side), not yet on the real following pet. Same day the user picked "long braids both sides": pigtails replaced by 5-segment zigzag braids to the shoulders + orange tie + tip (15 parts total); short-pigtail version backed up as `_Backup_20261015.LittleWitch_short_pigtails`.
- 2026-10-15 later: user disliked both hair patches → regenerated the whole witch (generate_mesh, 4 tries A–D, kept in `ServerStorage.WitchOptions`); user picked D (brown shoulder bob + bangs, satchel, side-saddle broom). Template Torso now mesh 85394140576155 / tex 137525248171638, size 2.43×2.94×2, RootJoint.C1 = identity (mesh front = its LookVector), BackHair removed. Backups: `_Backup_20261015.LittleWitch_long_braids`, `LittleWitch_before_backhair` (original). Product icon still shows the old witch. Gotchas: generate_mesh fails in Play mode ("should only be called from the server") — stop Play first; ApplyMesh works from execute_luau in Edit; generate_texture refused ("not authorized to access Asset").
- 2026-10-15 final (so far): user wanted the original's long-broom sitting pose → generated E/F, user picked **E** (brown bob, sits upright on a long broom, feet hanging). Template Torso mesh 112189549146900 / tex 132779301182003, size 2.76×2.60×2, RootJoint.C1 identity. D backed up as `_Backup_20261015.LittleWitch_optionD`; A–F in `ServerStorage.WitchOptions`. User checked E in Play and approved it (2026-10-15). Shop/product icon still shows the old witch. Not published.
- 2026-10-15 gift to a friend (user: "ทำส่งของขวัญของแม่มดน้อย เดี๋ยว id เอามาให้"): GiftProductId = 3718617176 ("ของขวัญแม่มดน้อย", 450 R$, set same day). Server `ServerScriptService.PremiumPetGift` (mailbox like LuckBoosterGift: DataStore PremiumPetGift_v1 inbox_/pending_, delivers one unit at a time via PetOwnership.GrantPremium, rolls back delivered on save failure, refuses self / target at Lv.15 / not released). Client: VipGui kind `witch` + `OpenWitchGift`, PlantLimitGui `GiftWitchButton` under the price button. Tested select/mailbox with a fake UserId only; real delivery to a player and real prompt untested.


---

## promo-codes

Redeem NPC (2026-10-18): workspace.RedeemCodeNPC (AI otter mail carrier by spawn, prompt "RedeemPrompt") opens the same SultanRedeemGui window via ProximityPromptService.PromptTriggered. User checked its look and approved (2026-10-18). Not published.

All codes typed in เมนู → 🎟️ แลกโค้ด (StarterPlayerScripts.SultanRedeemGui) go to ServerScriptService.SultanService `redeemPromoCode`, which checks these modules in order:
- `ServerScriptService.PromoCodes` — coin codes `{ rewardCoins, durationSeconds }`, one claim per account (DataStore PromoCodeAccountClaims_v1). The window starts at the first live server boot (PromoCodeActivation_v1), shared by all servers; **coin codes always fail in Studio by design**.
- SultanPromoCodes (Sultan pack, 1 user per code), BoomboxPromoCodes, AutoFeederPromoCodes, LuckBoosterPromoCodes (each code is single-use game-wide).

- `ButterflyRodPromoCodes` (added 2026-10-08, `BF-XXXXXX`, 10 codes, each single-use game-wide): grants the NightMoth rod permanently via the BindableFunction `ServerScriptService.FishingRodPromoGrant` (FishingShop); claims in DataStore ButterflyRodPromoCodeClaims_v1. A player who already owns the rod does NOT burn the code. Studio test switch: server attr `DevRodPromoSimulate`. Needs Publish; the code values are only in that module (not in CHANGELOG).

- `SunBeeRodPromoCodes` (added 2026-10-08, `BE-XXXXXX`, 20 codes, single-use game-wide): same mechanism for the SunBee rod (claims in SunBeeRodPromoCodeClaims_v1). SultanService now has one shared `redeemRodPromoCode(player, code, rodId, claimStore, rodName)`; to add another rod's codes, add the rod to `PROMO_RODS` in FishingShop + a codes module + a claims store + one hook line in `redeemPromoCode`. SultanPromoCodes now holds 25 `ST-` codes (15 added 2026-10-08; 2 of the first 10 were already claimed).

- `PetSlotPromoCodes` (added 2026-10-09, `PT-XXXXXX`, 20 codes (10 more added same day), single-use game-wide): pet slot +1 (3 pets) via `redeemPetSlotPromoCode` in SultanService; claims in PetSlotPromoCodeClaims_v1; the entitlement is written to PetSlotGift_v1 "to_<userId>" (promoCodes + seen) so PetSlotGift.HasGift makes it permanent. Players already at 3 slots don't burn the code. Not play-tested; needs Publish.

WELCOMEBETA = 400,000 coins, once per account, 30 days. Added and published 2026-10-05 (CHANGELOG lines ~108-110), so it expires around 2026-11-04.

**Why:** on 2026-10-08 I wrongly told the user WELCOMEBETA wasn't implemented, because I didn't know about PromoCodes.
**How to apply:** check these modules and the CHANGELOG before saying a code doesn't exist. The login news (LoginAnnouncementConfig) advertises WELCOMEBETA.

- `WitchPromoCodes` (added 2026-10-14, `MG-XXXXXX`, 20 codes, single-use game-wide): one code = one แม่มดน้อย purchase (new → Lv.1, owned → +1 level) via BindableFunction `PremiumPetPromoGrant` (PremiumPetService, check/grant); claims in WitchPromoCodeClaims_v1 with `granted = true` after the grant. Lv.15 or before Halloween2026 starts = code not burned. Not redeem-tested; needs Publish.

- `LlamaMountPromoCodes` (added 2026-10-19, `RM-XXXXXX`, 10 codes, single-use game-wide): ลามะไม่ใช่ลามะ (MagicLlama mount) via `redeemLlamaPromoCode` → BindableFunction `ServerScriptService.MountPromoGrant` (created in MountSystem.MountGift; "disabled"/"loading"/true/false on check, GrantBatch on grant); claims LlamaMountPromoCodeClaims_v1; already owned or MountConfig disabled = not burned. Compiles; not redeem-tested; needs Publish.

- `WitchMaxPromoCodes` (added 2026-10-15, `MMG-XXXXXX`, 5 codes, single-use game-wide): แม่มดน้อย straight to **Lv.15** (new → Lv.15, owned → set to 15, already 15 = not burned). Same `redeemWitchPromoCode` with params (claims store WitchMaxPromoCodeClaims_v1, action `grantMax` on PremiumPetPromoGrant → `PetOwnership.GrantPremium(..., setLevel)`). Compiles; not redeem-tested; needs Publish.


---

## pumpkin-vine

User 2026-10-09 (two reference images): pumpkin should grow as a vine on a stake with only one fruit, and the fruit must be a Halloween jack-o'-lantern (triangle eyes/nose, jagged glowing mouth).

- Built with `ServerStorage.PumpkinVineGen` (ModuleScript, Studio tool only, run via `loadstring(Source)()`). `Builder.Stage(model, 1..5)` and `Builder.Fruit(model, cf, scale, withFace)`. It rewrote `ServerStorage.CropTemplates.Pumpkin.Stage1..Stage5` and `HeldFruit` (all parts, no AI mesh). Old template backup: `ServerStorage._Backup_20261009.Pumpkin_before_vine`.
- Parts per stage: 8 / 22 / 32 / 49 / 77 (HeldFruit 21). Stage5 is about 4.8 x 6.2 x 4.6 studs (was a sprawling 11 stud vine). Stage4 shows a small green baby pumpkin, Stage5 the ripe fruit at scale 1.25 (3.1 studs wide), trellis behind it at z = -2.2, fruit face toward +Z of the stage model.
- 2026-10-09 later (user: thinner stake, more prominent fruit): posts 0.14, slats 0.10, trellis width ±0.85, TRELLIS_Z -2.6, FRUIT_S 1.55 (fruit about 3.9 studs wide), body colour (255,124,22). Change these constants at the top of the module and rebuild Stage1-5 + HeldFruit (destroy the old ones first).
- HeldFruit is rotated 180 degrees about Y so the face looks away from the holder (Handle -Z is the character's forward).
- Gotchas learned: `Part.Shape = Ball` renders a sphere from the smallest axis, so ellipsoids need a Block + `SpecialMesh` Sphere; a `local` constant declared AFTER the function using it becomes a nil global (the error showed up as a tool timeout); `Wood` material makes light colours look black.
- Side effects handled: `PetWorkEffects.makeProduceModel` uses `HeldFruit` for Pumpkin (it used to clone Stage5, which would now be a whole plant); `ItemFactory.HELD_SCALE.Pumpkin` 1.2 -> 1.1.
- Not touched: harvest/growth timing, CropAura (the glow Highlight now adorns the whole plant), the old `Stagebg`, `Stage5backup`, `HeldFruitHaa` models left in the template.
- Related: [[planting-click-and-perf]] (CropModel tag, CanQuery false on clones).

2026-10-12 — crop optimisation step 1 (user approved the plan, "ปรับ ขั้น 1 ก่อนได้เลย"):
- Stage1–5 are now UnionOperations: groups Frame / Leaves / Fruit / Glow, parts 8/22/32/49/77 → 2/2/2/3/4, tris 480/1,610/2,610/4,990/7,938. Built with `ServerStorage.CropUnionTool` (`Convert(model)`, Studio-only). Backup `_Backup_20261012.Pumpkin_before_union`. If PumpkinVineGen is ever re-run, run CropUnionTool on the result again.
- Tool gotchas: CSG ignores SpecialMesh, so ellipsoids are replaced by a sphere union (432 tris) resized non-uniformly, thin ones by a resized cylinder disc; a union takes the MAIN part's orientation, so the main part is a tiny axis-aligned dummy (otherwise the model bounding box grows and PlantingSystem's bottom-of-bbox ground alignment makes the plant float).
- Found and fixed a pre-existing bug: Stage2–4 had a rotated model pivot (16,117,43), so those stages leaned in game since 2026-10-09; pivots are now upright.
- Remaining plan (not started): step 2 lighter wheat/corn meshes (~16k/10k tris), step 3 fewer extras per plant (anchor + wet patch + prompt), step 4 remove per-plant debug prints / batch pet planting, step 0 FPS baseline was skipped because Play would not start. Not play-tested, not published.

2026-10-13 (user: "ลดขนาดพักทอง ลง 20% ช่วงโตพร้อมเก็บเกี่ยว"): Stage5 `Fruit` + `Glow` unions scaled x0.8 about the fruit base (fruit 3.88 → 3.10 wide); trellis/leaves and Stage1-4/HeldFruit untouched. I read "pumpkin" as the fruit, not the whole plant. Backup `_Backup_20261013.Pumpkin_Stage5_before_shrink20`. If PumpkinVineGen is re-run, the equivalent is FRUIT_S 1.55 → 1.24 (then CropUnionTool). Gotcha: a UnionOperation's Position is NOT the centre of its geometry (the mesh is offset from the part CFrame), so measure real extents with raycasts before scaling about a point. Not seen by eye (white screen capture), not play-tested.

2026-10-14 (user asked again "ปรับพักทองตอนโตขนาดลดลง 20%"): Fruit + Glow shrunk another x0.8 about the same base pivot (≈(0.02,0.04,-0.37)) via a temp Model ScaleTo → fruit 2.48 wide (≈64% of original, FRUIT_S equivalent ≈0.99). Backup `_Backup_20261014.Pumpkin_Stage5_before_shrink20b`. Studio only.
2026-10-14 later: Frame + Leaves of Stage5 also x0.8 about the same pivot → whole Stage5 3.64×4.98×3.84 (was 4.55×6.22). Backup `_Backup_20261014.Pumpkin_Stage5_before_frame_shrink20`. Stage1-4 NOT shrunk, so Stage4→5 may now look like a size drop. Studio only.
2026-10-14 later: Stage1-4 also x0.8 (about bbox bottom-centre), then Stage2-5 shifted in XZ so Frame sits at Stage1 Frame XZ (-0.68, -2.564) in every stage. Whole pumpkin now 80% (fruit 64%). Backups `_Backup_20261014.Pumpkin_StageN_before_shrink20`. HeldFruit unchanged.
- 2026-10-15: all Stage1–5 shrunk another x0.9 (ScaleTo around each stage's pivot = the planting anchor, bottom kept) — Stage5 now 3.27×4.48×3.45. Planting places the stage pivot at the slot then snaps the bbox bottom to the ground, so scale around the pivot to keep the trellis aligned across stages. Backup `_Backup_20261015.Pumpkin_Stages_before_shrink10`.


---

## roblox-multiedit-gotcha

Roblox Studio MCP `multi_edit` replaces the first occurrence of old_string. Twice in ActivePetsHud (2026-09-27, 2026-09-29) an anchor like `updateHeader()\n` / `applyCollapsed()\n` matched the function's own definition line (`local function applyCollapsed()`), which renamed the function or inserted code inside its body.

**Why:** the anchor was a substring of an earlier line; the edit reported success silently.
**How to apply:** always anchor on text that occurs exactly once (include the previous line or indentation, or append at the true end by matching the last 2-3 lines). After any edit anchored on a short call, grep the source for the anchor to confirm where it landed.


---

## rotated-plots

2026-10-08 bug: pets planted outside FarmPlot50–54.
- **Rotation:** FarmGridConfig used `soil.Position + offset` (world axes). Rotated soils (51 at −85.6°, 52 rotated and tilted 5°, 53/54 at −90°) put slots across the plot and outside it.
- **Buried soil:** the Soil parts of 50 and 54 are entirely under terrain grass; 51 and 52 partly.

User decision: planting on grass is fine, but only inside the plot's footprint.

Fix (published 2026-10-08; user confirmed live that pets plant inside the plots and crops are not buried):
- FarmGridConfig is now CFrame-aware: GetSlotWorldPosition, GetSlotGroundCFrame, GetSlotSurfacePoint (terrain surface up to 3 studs above the soil), FindSoilAt, ResolveSoilFromMouse, IsInsideSoil.
- GetNearestSlot also returns the offset.
- Users: PlantingSystem (createSlot, tryPlant footprint check), SeedClickPlanter, PlantSlotGuide.

**How to apply:** any new grid/slot code must go through soil.CFrame, never soil.Position + offset. Related: [[planting-click-and-perf]], [[terrace-zone]].

2026-10-12 (user: hidden plots on the beach so players can plant there): added `FarmPlot55/56/57` on the WEST beach strip — clones of FarmPlot54, Soil 15 wide (x -410.5..-395.5), top at y 5.6 under sand at y 6.0, z 50..126 / 146..214 / 236..300 (1,370 slots), attr `BeachPlot`. No script change. Verified in Play: server set up 30 plots, surface point y 6.0, FindSoilAt on sand finds the plot. NOT verified: an actual plant (seeds are not Tools in the backpack, so a quick test needs the bag UI). Not published. No visible marker tells players the sand is plantable (only the slot guide while holding seeds).
- 2026-10-12 later: SOUTH beach hidden plots `FarmPlot58`–`62` (z 331..349, soil top 5.6; x -336..-256, -240..-164, -140..-100, -36..48, 52..130; 2,868 slots). Server reports 35 plots. Gaps left at hammocks/palms and where sand dips below 5.9 (a soil top at 5.6 would show through). Actual planting still not hand-tested; not published.
- 2026-10-12: user asked beach plots to give 50% yield → `PlantingSystem.doHarvest` multiplies by attribute `YieldMult` (on the Soil or the plot model, default 1; fractional part rounds up at random). FarmPlot55–62 have `YieldMult = 0.8` (user changed 50% → 20% reduction the same day). Star quality and XP unchanged. Compiles; harvest NOT play-tested; not published. Any future "worse/better soil" zone = just set this attribute.


---

## scarecrow-ghost-pet

User 2026-10-11: new Secret-tier pet "ผีน้อยนักปักหุ่น" from a reference picture (white ghost, purple witch hat), holding the existing golden lucky scarecrow (they said not to sculpt a new one). Their choices (asked): ability = place scarecrows FROM THE OWNER'S BAG automatically; obtained from the gacha during the Halloween event.

- `PetDefinitions.ScarecrowGhost`: Secret, `Flying`, abilities `ScarecrowPlacer` + Lucky (x20 from rarity), `Season = "Halloween2026"`. End of PetDefinitions removes any def whose `Season` has not started (`SeasonConfig.HasStarted`: Enabled and past StartUtc, ignores the end date; Studio `DevForceSeason` counts) → invisible everywhere before release, still usable by owners after the event.
- Template `ServerStorage.PetTemplates.ScarecrowGhost`: AI mesh (explicit segmentation gave hat / body / two fragments of ONE arm / doll); joints RootJoint, Neck, `LeftWing` (free arm) and `RightWing` (a mini clone of the HalloweenCloverTemplate mesh — the user first accepted the normal golden clover, then asked for the Halloween skin on 2026-10-11) so the dragon's fly animation waves them. Model front is -Z, so `FacingOffset` is identity (other pets face +Z and use 180°).
- Ability `PetSystem.Abilities.ScarecrowPlacer`: every 2 s, if the owner is within 14 studs of a Soil plot and `ServerStorage.PetBoosterPlace:Invoke(player, "query")` lists a tier (tool in bag + none of that tier active), target = 4.5 studs beside the owner; work fn invokes `"place"`. Both tiers get placed (x100 too — the ability toggle is the way to keep golden ones).
- `BoosterPlacementSystem` was refactored: `spawnBooster(player, tool, tierId, tier, position, facingPos)` shared by the player RemoteEvent and the BindableFunction.
- Gacha: `GachaConfig.Events` entry `Halloween_2026` with `Season`; `GetActiveEvent` checks season-bound events first via `SeasonConfig.IsActive`. In Studio with DevForceSeason the gacha IS in Halloween mode, and Studio rolls write to the real account.
- Gacha showcase (2026-10-11, user sent a picture of the ghost showing its back): `GachaService.placeShowcase` now faces the pet along `machine:GetPivot().LookVector` (the machine's visual front, pointing west) instead of toward the SpawnLocation; applies to every showcased pet.
- 2026-10-11 later (user asked, then chose in a question): the ghost must be rollable right after the fox event → its own switch `SeasonConfig.Seasons.GhostGacha2026` (Enabled = false, 2026-10-15 00:00 → end of 2026-11-02 Thai time); the pet def `Season` and the gacha event `Season` point to it, NOT to Halloween2026 (decor/skins still start 10-24 on the Halloween switch). `DevForceSeason` now takes a comma list and is set to "Halloween2026,GhostGacha2026". To release: set that Enabled to true and publish before 10-15; servers alive across the start need a restart to know the pet. Earlier lines here that say the pet is tied to Halloween2026 are superseded.
- Menu previews: every client window builds its camera assuming pets face +Z (FacingOffset 180°). `PetManager` now rotates the PARTS of a preview clone when a def's FacingOffset differs (pivot kept), so the ghost shows its face in the pet menu / book / gacha / active-pets HUD. A future pet whose model faces -Z needs nothing extra.
- The user obtained the ghost on their own account on 2026-10-11 (they rejected my tool call that was about to look at ownership data — don't touch their pet data when they already have what they asked for).
- Balance (2026-10-11): the user wants the ghost on par with the nine-tail fox (it was weaker). Luck set to explicit `Luck = 30` (text "นำโชค x30"). I listed 10 ability ideas (straw scarecrow lasts 2x, no hunger, wider radius, 2 straw at once, blessed straw x40, grow +20%, min ★2, 20% bonus produce in radius, x1.5 yield in radius; my pick: luck 30 + 2x straw duration + 20% bonus produce, never multiplying with the fox's x2, straw only so golden-scarecrow Robux sales are not cut). The user then chose "x1.5 yield when harvesting inside OUR straw scarecrow's radius" (built the same day): `StrawYieldBonus = 0.5` on the def → PetController sets player attr `PetStrawYieldBonus` while the ghost is out → `PlantingSystem.doHarvest` applies x1.5 when the slot is within an x50 booster owned by that player (golden and other players' scarecrows do not count), takes max with the harvesting pet's multiplier (no stacking with the fox x2 — my rule, the user did not object), fractional part rounds up randomly. Base Yield per star is 2/3/4/5/5. Compiles and the rounding was simulated; a real in-game harvest with the ghost out was NOT tested.
- Aura (2026-10-11, user sent the reference picture again and asked for its aura): template has `AuraHighlight` (lavender outline) + emitters `StarsWarm` / `StarsPurple` / `Glitter` on Torso. Particle texture `rbxassetid://615529588` rendered NOTHING here; `rbxasset://textures/particles/sparkles_main.dds` works. `Model:ScaleTo` scales emitters, and ApplyRarityGlow multiplies rate/size and dims Highlights (Secret: rate x1.3, size x1.15, AuraDim 0.64). A client `RenderStepped` loop that sets CameraType Scriptable + CFrame every frame is the reliable way to hold a camera for a Play screenshot.
- 2026-10-12 (user: the ghost places scarecrows "มั่ว"; wants a button + guide ring to ORDER the spot, no order = no placing): the "owner near a plot, place beside the owner" rule is GONE. `StarterPlayerScripts.GhostPlaceGui` (left-centre purple button, shown only while a pet with ScarecrowPlacer is out; aim mode = purple firefly ring radius 15 following `mouse.Hit`, click/tap ground → RemoteEvent `GhostPlaceOrder`); server (in BoosterPlacementSystem) validates ≤ 60 studs + ground + not water and sets player attr `GhostPlaceSpot` (session only); the ability places x50 exactly there (x100 offset 3 studs) while the owner is within 90 studs. Marker + label at the spot are client-only. Real click/tap in aim mode, mobile and gamepad were NOT tested (I fired the remote directly).
- 2026-10-12 later (user asked): the button moved from left-centre to the RIGHT, above the jump button, icon only (scarecrow ItemPreview viewport, no text). It stacks above `SprintGui.SprintButton` (which already sits above the jump button), or above `FishingHud.FishControls` when that is open. State = colour (purple / green = spot set / grey + X = aiming); small X clear button is left of it. Seen in Play on PC only; mobile and rod-held layout not checked.
- Client labels added in PetHelperToggleButton (ABILITY_ICONS, BOOK_ABILITY_ICONS, description table) and ActivePetsHud — a new ability id needs these four spots.
- Tested only through module copies (PetController.Spawn + ability functions) to avoid touching the account's pet data. NOT tested: real PetManager flow (menu, hunger, toggle), a real gacha roll, the showcase on the machine, golden scarecrow placement by the pet.
- Related: [[seasonal-events]], [[booster-seasonal-skins]], [[pet-gacha-plan]], [[dev-pet-key-override-gotcha]].
- 2026-10-14 (user: "ใช้หุ่นจาก hot key เท่านั้น ไม่เอาในกระเป๋า"): hotbar vs bag is CLIENT layout only (both are Tools in Backpack), so the server now reads the layout the client already syncs: `HotbarLayout` exposes BindableFunction `ServerStorage.HotbarLayoutQuery` → slot keys; `BoosterPlacementSystem.findToolOfTier` (pet path only) accepts a booster that is held or whose key (copy of `HotbarState.ToolKey` KEY_ATTRIBUTES — keep both in sync) is in a slot. Tested in Studio Play by sending a layout without the scarecrow (query {} / place false, nothing consumed) and restoring it. Player hand-placing is unchanged.
- 2026-10-14 model fix (user: "แขนข้างเดียว หุ่นไม่ตรงมือ ขยับแขนแปลก"): the old template had ONE arm (LeftWing+LeftWingB) and the RightWing motor flapped the floating doll. Now `RightArm`/`RightArmB` = left arm mirrored (rotate 180° about Y + mirror x across the torso centre — MeshParts can't be negatively scaled), RightWing motor drives RightArm from a mirrored shoulder, doll renamed `HeldScarecrow` and welded to RightArm. PetAnimator.buildFly reads model attrs FlapAmp/FlapSpeed/FlapBias/RightFlapScale (ghost 0.22/0.4/0.05/0.45; absent = dragon defaults). Tested with a temporary spawned copy (attrs PetId/OwnerUserId=1/FacingOffset/AnimFlying + anchored HRP) — a safe way to check pet animation without touching the owner's pets. Backup `_Backup_20261014.ScarecrowGhost_before_twoarms`.
- 2026-10-14 later (user: arms unbalanced, seam visible, not smooth): the OLD body mesh itself had an arm sculpted across the belly, so separate arms could never fix it. Replaced Torso + Head with a new AI mesh (explicit segmentation ["hat","body"], prompt "cute chibi white ghost with NO arms…" — it still came out with two small symmetric arm stubs molded into the body, which looks good). Template now: HumanoidRootPart, Torso (body), Head (hat), HeldScarecrow; motors RootJoint, Neck, RightWing (sways the doll ±7° at the right hand; attrs FlapAmp 0.12 / FlapSpeed 0.35 / FlapBias 0 / RightFlapScale 1). No LeftWing, no separate arms. Generated meshes come in with a random yaw and odd part names (quotes/brackets) — rename before FindFirstChild; after `PivotTo(CFrame.new(pos))` on a temp model the yaw resets, so check the face direction in a capture. Backups `_Backup_20261014.ScarecrowGhost_before_newbody` / `_before_twoarms`.
- 2026-10-15 (user): ghost levels no longer add work speed; instead the straw-radius yield bonus scales x1.5 (Lv.1) → x1.8 (Lv.15) linearly. Data in `PetLevelConfig.LevelPerks` (`StrawYieldAt`, `LevelSpeedOn`, `SpeedMultiplier(level, petId)`); PetController re-applies `PetStrawYieldBonus` on `PetLevel_<id>` change. GachaGui level & shards rows now have a 3rd purple "⬆️ อัพเลเวล" line per pet (generic speed/hunger, or the ghost perk + next level). Real harvest at higher level and mobile layout untested.
- 2026-10-15 (user): extra ability — crops inside the owner's OWN straw (x50) scarecrow radius grow 10% faster while the ghost is out: def `StrawGrowBoost = 0.1` → attr `PetStrawGrowBoost` (PetController) → `PlantingSystem.growPlant` multiplies each stage wait by 0.9 via `inOwnStrawRadius(owner)` (checked at the start of each stage; stacks multiplicatively with rain and the Sultan dragon). Not level-scaled. Attr confirmed in Play; real timed growth untested.
- 2026-10-15 (user: ghost stops placing after AFK): cause = `GhostPlaceSpot` was session-only, AfkRejoin (19 min) / restart = new session = no spot. Now persisted in DataStore `GhostPlaceSpot_v1` (BoosterPlacementSystem: save 3 s after change, X = remove, restore on join if not already set). Save verified in Play; the restore-on-join path NOT seen (Studio start-play got stuck). If the user still reports it after publishing, check hunger 0 (canWork) and the hotbar-layout query (`HotbarLayoutQuery`) right after rejoin.


---

## sea-and-beach

Map edges used to show the dark-grey Baseplate3 (y -32). Fixed 2026-09-26 by filling terrain Water from y -36 to 0 in every 16-stud cell reachable from the map edge through low ground (flood fill), sea level 0 = canal level. Then a sand beach only along the real sea coast of the farm island (x -560..130): coast = land cells next to "open sea" (reachable from edge WITHOUT passing through existing water, so canals/rivers are excluded), plus FillBall sand spits and FillCylinder shelves (top ~2.2 and ~0.3) for a continuous curved shoreline. 20 palms (clones of Scenery.Foliage.Palm, scale ~0.5) in workspace.Beach. Terrain Sand color set to (226,205,150); old color in _Backup_20260926 attribute SandColorBefore.

Farm interior (x -300..60, z ±240) must have 0 Sand voxels — earlier attempts sanded canal banks (originally Mud) and were reverted with ChangeHistoryService:Undo (each execute_luau = one "Assistant N" waypoint; Undo worked for terrain here).

**Why:** user's farm-polish list item 1 ("ขอบแมพโผล่เป็นพื้นเทา").
**How to apply:** data in ServerStorage._Backup_20260926: SeaGrid (Min=-1104, Step=16, N=139; cell values b/n/wH/height), SeaFillMask (cells that got water), SandSpits. Item 2 done 2026-09-26: workspace.FarmFlora (Trees 118 incl. 13 path-side shade trees, Shrubs 165, Flowers 260), templates in ServerStorage.FarmFlora (MangoTree, PinkTree, YellowTree generated meshes; FarmTree = Tree_2 clone; GreenShrub, HibiscusBush, WildflowerPatch). All decor parts CanCollide/CanQuery false; trees have invisible TrunkCollider. Kept clear: spawn, shop, gacha, animal pen, paths, canals. Item 3 done: animal pen plateau Ground→Grass (inside fence LeafyGrass lawn, Mud patches at troughs/barn), canal-side cobblestone wall above y4 → Grass, troughs Concrete→WoodPlanks (OrigMaterial/OrigColor attrs); terrain backup Terrain_animalpen_before (PasteRegion at Vector3int16(-74,-2,51)). Items 4-5 done: workspace.RestSpots — RestSala (Thai sala at -350,*,106, mesh non-colliding + FloorCollider + 6 Seats), SunflowerField (600 sunflowers x -380..-318 z 18..92, dirt path at x -350), LakeBench1/2 (lake north shore ~-376/-366, z 10, face lake), FieldBench1/2 (-324/-336, z 14, face field), BeachHammock (-402,*,64, HammockSeat). Generated-mesh "front" for benches needed an extra -90° yaw. Templates Sala/Bench/Hammock/Sunflower in ServerStorage.FarmFlora. Item 7 done: workspace.Lights = 26 part-built lanterns (template ServerStorage.FarmFlora.Lantern; glass part tagged "NightLight" with PointLight); ServerScriptService.NightLights turns them on when ClockTime >=18.2 or <6.3. workspace.FarmProps = HayCart x2, Well, BarrelStack x3. Fixed DayCycle night bug (tween ClockTime 19→5 ran backwards through midday; ClockTime clamps >24 to 0, so it now tweens a NumberValue 19→29 and sets ClockTime = v % 24); old script in _Backup_20260926.DayCycle_before_nightfix. Lantern template pivot = base bottom (PrimaryPart nil) — earlier PrimaryPart=rotated cylinder post laid every lamp flat; fixed 2026-09-26. Item 6 done: RestSpots.LakeDock (part-built pier at x -392 from z 5 to -30, TOP 3.3, 2 DockSeats, lamp), RestSpots.LakeLife (3 Rowboats, 34 Lotus, 6 Ducks animated by StarterPlayerScripts.LakeDucks via SwimCenter/SwimRadius/SwimSpeed/Phase attrs; duck mesh front = -X). Lake = west end of central canal, water top y≈0. Item 8 done: StarterPlayerScripts.AmbientCritters (client-only, creates workspace.AmbientCritters folder): 40 part-built butterflies (sunflower field, random wildflowers, terraces), 3 bird flocks (18 birds) circling, 6 firefly ParticleEmitter zones (lake, field, sala, canals, terrace stream); butterflies/birds by day (6.2–18.3), fireflies by night; BulkMoveTo + distance cull. Note: Studio minimized ⇒ screen_capture white + FPS throttled to ~15 — restore window via PowerShell SetForegroundWindow/ShowWindow(9) before judging performance. Item 9 done: Lighting had 2 Sky objects; "Dune Sky " (painted sky with baked sun/stars/sunset — clashed with day/night) moved to _Backup_20260926, kept plain "Sky"; Terrain Clouds added (Cover 0.58, Density 0.62). Item 10 done: StarterPlayerScripts.AmbientSounds — 2D looped sounds in SoundService: AmbientBirds 9112831284 (vol 0.18 by day) / AmbientNight 9117114084 Night Jungle 6 (vol 0.14 at night), crossfade 17–19 and 5–7 (music is 0.25). Remaining polish items from the plan: sky (two Sky objects) + clouds, ambience sounds, leftovers (empty Gate folder, Scenery._Review part, orange log near shop). Related: [[terrace-zone]].

2026-10-03 sea edge fix (user screenshot: grey rim around the map, visible from the farm and walkable): Baseplate3 (2048x16x2048, top y −32) stuck out past the old sea (sea only reached ~x −1000 / z ±800). Filled terrain Water y −36..0 in every column of x −1792..2816, z −1792..1792 that has NO solid terrain from y −28 up to 60 (so the island, the east plain and inland pits are untouched); only Air cells were changed (≈6.4M cells). The sea now surrounds everything incl. the east plain (ends ~x 2300). Baseplate3 recoloured to seabed sand (Material Sand, 122,116,92), now fully underwater. Backup: ServerStorage `_Backup_20261003_SeaEdge` (TerrainRegion SeaLayerBefore = cells −448,−10,−448 .. 704,−1,448; attrs OrigColor/OrigMaterial of the baseplate). Water ends at ±1792 (visible only from very high up; hazy). Verified by screenshots from high above and from the farm. Needs Publish.
- Same day follow-up (user screenshot of a dry pit below sea level at the south coast, ~x 200, z −840, under a rock overhang): the edge fill had skipped it because the column had land above (the overhang). Fixed with a 3-D flood fill from existing sea water through Air cells (y −36..0) inside box x 40..360, z −980..−740 → 1,876 cells, now a cove. Backup `SouthCoastPitBefore` in `_Backup_20261003_SeaEdge` (cells 10,−10,−245 .. 90,2,−185).
- GOTCHA: the edge fill rule ("no solid from −28 to 60") also put water INSIDE the hollow grey mountains (shell only above y 60). Removed: water at y −36..0 in columns covered by solid at y ≥ 8 within x 376..1376, z −704..728 (78,606 cells). Mistlake (open to sky) kept its water. ~283 other covered water columns elsewhere are natural sea caves / under bridges — left alone. Next time use a flood fill from the sea, not a per-column rule.

2026-10-12 (user screenshot: a white curved "wave" line on the water in the south bay, ~x 160, z -790): cause = Water voxels below sea level with partial occupancy lying in an arc (leftover of an earlier fill), which creases the water surface. Fix: set occupancy 1 on water cells with no solid 6-neighbour (421 cells, all in x 0..512, z -1024..-768; a scan of the whole sea found no others). Backup TerrainRegion `_Backup_20261012.SouthSeaWaterRidgeBefore` (attr PasteCorner 0,-10,-256). If a white line on the sea is reported again, scan for partial-occupancy water first.


---

## seasonal-events

User 2026-10-11: wants Halloween decorations in the farm that can be turned on/off in ONE go when the festival passes; heavy around the seed shop and the fishing shop, only small touches elsewhere. Still not to be released yet.

- **One switch for the whole patch:** `ReplicatedStorage.SeasonConfig.Seasons.Halloween2026 = { Enabled = false, StartUtc, EndUtc }` (2026-10-24 → end of 2026-11-02 Thai time; dates are my choice) + `IsActive(id)`. It drives both the booster skins ([[booster-seasonal-skins]], `LuckConfig.BoosterSkins` now only holds `Tiers`) and the decorations. Release = set `Enabled = true` and publish; it ends by itself.
- Studio preview: attribute `DevForceSeason = "Halloween2026"` on ReplicatedStorage (replaces the old `DevForceBoosterSkin`). It is SET in the place file because the user asked to have it on in dev; Studio only.
- `ServerScriptService.SeasonalDecor`: clones `ServerStorage.SeasonalDecor.<seasonId>` into workspace as `SeasonalDecor_<seasonId>` while active, removes it when not (checks every 60 s).
- Set `ServerStorage.SeasonalDecor.Halloween2026` (110 parts; all Anchored, CanCollide/CanQuery/CanTouch false so nothing blocks walking, planting clicks or booster placement): sub-models ShopArea, FishingArea, Scattered.
- Kit (9 single AI meshes: Arch, LanternPost, PumpkinPile, Pumpkin, Cauldron, CandyBucket, Tombstone, Ghost, Bat) in `ServerStorage.SeasonalDecorKit.Halloween2026`. Layout tool `ServerStorage.HalloweenDecorGen` (edit the `LAYOUT` table, run `loadstring(Source)()`; `TO_WORKSPACE = true` previews in workspace). face angle: 0 = -Z, 90 = -X, 180 = +Z.
- `StarterPlayerScripts.SeasonalDecorFx`: parts tagged `SeasonBob` (ghosts, bats) bob client-side within 220 studs.
- Geometry facts: seed shop plaza is flat brick terrain at y 4, stall at x -137..-123, z 77..86, front faces -Z. Fishing shop sand at y 6, shop at (-425, 2), front faces +Z, otters stand x -439..-416, z 1..11.
- Gotcha (2026-10-11): after many edit-mode `screen_capture` calls with camera_position, `workspace.CurrentCamera.CameraType` was left `Scriptable`, so the user could not rotate the Studio camera with right-click. After a capture session, check it and set it back to `Fixed`.
- Gotchas: edit-mode `screen_capture` with a far-away camera shows terrain at low LOD (ground looks bulged, object bases look buried) — verify in Play instead. Several parallel `screen_capture` calls time out; do them one at a time. 3 parallel generate_mesh jobs worked.
- 2026-10-11: at the user's request I started Play and left their character auto-fishing (SunBee rod) on the beach by the fishing shop, via `PlayerGui.AfkRejoinGui.TestResume:Fire({rodId, auto = true})`.
- 2026-10-11: the set was out in `Workspace.Halloween2026` for hand edits, then put BACK into `ServerStorage.SeasonalDecor` when the user said "เก็บกลับ" (447 parts; the user had removed 5 pieces by hand, so the stored set is the source of truth, not the generators). The user's phrases: "เอาออกมาให้แก้" = move it to Workspace, "เก็บกลับ" = move it back. Whenever it is out, it must go back before any Publish (it would go live ungated); check where it is before saying a publish is safe. Pre-edit copy: `_Backup_20261011.SeasonalDecor_Halloween2026_before_manualedit`. After manual edits do NOT re-run HalloweenDecorGen (it overwrites them).
- 2026-10-11 later: user said the decorations felt too few → added sub-model `Extra` (220 parts, set total 330) via `ServerStorage.HalloweenDecorExtraGen` (rebuilds ONLY `Extra`): 3 new kit meshes (BlackCat, SpookyTree, HayStack); ShopExtra / FishingExtra / SpawnExtra (lantern posts + bunting gate at spawn) / FarmExtra (a pumpkin at each of the 42 Lantern bases, cats on benches, pumpkins by hammocks and the campfire). The user has not yet said whether this amount is enough.
- 2026-10-11 (user: "make all lanterns change with the festival" + "the farm plots too"): `SeasonConfig` season entries now also take `Lanterns = { Head, LightColor }` and `Plots = { Topper, BeamColor, PostColor, SignColor }`. `SeasonalDecor` applies them at RUNTIME only and keeps undo closures: the 40 `Lantern` models (workspace + workspace.Lights; parts Bottom/Frame/Glow/Cap made transparent, a pumpkin head from `ServerStorage.SeasonalProps.<season>.LanternHead` hung at Glow, light recoloured) and the 21 `FarmDressing.RaisedBeds.*_Edging` models (Beam / CornerPost / Sign recoloured, `PostTopper` on 2 diagonal posts + the sign). Added pieces live in `workspace.SeasonalSkin_<season>`. Soil and crops untouched; plots without edging (22, 50-54) unchanged. Restore-on-season-end is written but NOT tested.
- 2026-10-11 trees (user: "next adjust the trees", then mid-task: "ไม่เอาน่ากลัวนะ เอาแบบน่ารักๆ ตามธีมเกม" — NOT scary, cute, matching the game's theme; applies to the whole Halloween patch: no carved/dark faces, prefer candy, stars, pastel, smiling round-eyed faces): `SeasonConfig...Trees = { [original MeshId] = prop name }`; `applyTrees` hides the original MeshPart (Transparency 1) and puts a same-size clone of `SeasonalProps.<season>.<prop>` at its CFrame. Mango tree → `Tree_Candy`, Pink tree → `Tree_PurpleStar` (35 + 29 trees); YellowTree and FarmTree unchanged.
- Tool facts: `generate_texture` on an existing MeshPart creates a NEW MeshId + TextureID (the new texture is garbage on the old mesh, so runtime TextureID swap does not work; MeshId is not scriptable at runtime → swap whole parts). Passing a Model path replaces the Model with a bare MeshPart. It fails/time-outs often; check the instance afterwards. If edit-mode `screen_capture` returns a white view with a "Bottom" view cube, the Studio viewport is on another tab — view things in Play instead (the game camera script overrides a Scriptable camera, so move the character, not the camera).
- 2026-10-11 beach + shops (user asked for Halloween decor at the beach/sea and themed shop, merchant, fishing shop): sub-model `Beach` (122 parts, set total 452) via `ServerStorage.HalloweenDecorBeachGen` (rebuilds only `Beach`): around all 21 Palms + `workspace.PoolSet`, plus floating `GhostFloat` / pumpkins on the water (tag SeasonBob). New kit meshes GhostFloat, Sandcastle. Shop reskins are retextured copies in `SeasonalProps.Halloween2026` (Shop_Awning, Shop_Counter, Shop_Merchant, Fish_Stall) swapped through `SeasonConfig...Swaps` (same swapper as trees; roots FarmFlora / Shops / FishingShop). The merchant is animated client-side by `ShopMerchantFx` (turns to the player), so its swap uses `Follow = true`: the copy carries ObjectValue `SeasonSource` + tag `SeasonFollow` and `SeasonalDecorFx` copies the hidden original's CFrame every frame. Not checked up close: merchant follow, fishing shop look, sea floaters.
- 2026-10-11: GachaMachine + PetFoodMachine also reskinned (`Gacha_Machine`, `PetFood_Machine` props, `Follow = true`, both added to `SWAP_ROOTS` in SeasonalDecor). Each machine is a single `body.body_geom` MeshPart. Rolling the gacha / converting food while skinned was NOT tried.
- 2026-10-13: the user toggles Halloween in dev on request ("ปิด/เปิดเทศกาลฮาโลวีนใน dev") = `DevForceSeason` `"GhostGacha2026"` (off, ghost pet/gacha kept on) ↔ `"Halloween2026,GhostGacha2026"` (on). Last state that day: ON. "dev" for this user = Studio Play; the published game ignores the attribute.
- 2026-10-13 (evening): the set was re-laid for the rebuilt island ([[island-rebuild-plan]], round 4) and then PUT BACK into `ServerStorage.SeasonalDecor.Halloween2026` when the user said "เก็บกลับก่อน" (264 parts; FishingArea is now empty, shop decor follows the new seed shop at (58,−135), fishing decor is in SouthBeach at the right beach (52,300)). Geometry notes further up (old plaza / old fishing shop positions) are stale.
- (history) 2026-10-13 earlier: the set was OUT in `Workspace.Halloween2026` (447 parts) at the user's request ("นำออกมาให้แก้ใน workspace"); "เก็บกลับ" = move it back to `ServerStorage.SeasonalDecor.Halloween2026`. Moving it in one parent write is heavy: move sub-models one at a time with task.wait (Extra/Beach in batches of 40 children).
- 2026-10-13 plaza tidy (user: the seed-shop plaza looked cluttered, wants "เป็นระเบียบ เรียบง่าย น่ารัก"): 25 pieces taken out of ShopArea / Extra.ShopExtra (2 SpookyTrees, 4 extra buntings, 1 lantern post, 4 tombstones, 4 ghosts, 4 bats, 6 small pumpkins) into `_Backup_20261013.Halloween_plaza_removed`; the rest arranged symmetrically about x ≈ -130.5. Pre-tidy copies: `_Backup_20261013.Halloween_ShopArea_before_plazatidy` / `..._ShopExtra_...`. Taste: fewer pieces, symmetric, open floor; the user had not reacted yet when this was written. Real plaza is smaller than the brick terrain reading suggests (decor fits x -150..-110, z 55..78).
- 2026-10-13 beach tidy (user sent a picture of the chair/umbrella set `Workspace.PoolSet`, "แก้บริเวณนี้ด้วย"): 10 Beach pieces out to `_Backup_20261013.Halloween_beach_removed` (4 were sitting on the hidden beach plot FarmPlot52, soil x 144..177, z -374..-278 — keep decor off x ≥ 144 there); ghosts over the umbrellas, one castle+pumpkin+cat per palm, sea = 1 ghost float + 4 pumpkins in an arc. Pre-tidy copy `_Backup_20261013.Halloween_Beach_before_tidy`. Other beach stretches (other palms) untouched.
- 2026-10-13 new sub-model `SouthBeach` (22 pieces, placed by an inline script, no generator saved): the fishing shop now stands on the south beach at (136, -489) facing -X (otters at z -499 / -480, craft bench (138, -519)), boxing ring at (50, -479) with steps on the +X side. Piles/buckets/ghosts flank the otter row, 2 lantern-post pairs line the walk to the ring, piles/ghosts/bats at the ring. The OLD fishing-shop decor (`FishingArea`, `Extra.FishingExtra`) still sits at the shop's former place around x -425 — orphaned, user not asked yet.
- Not done / ideas: no Halloween music, no decorations on the terraces/hiking map, shop arch passage is narrow (no collision so it does not block).
- 2026-10-13 anchoring (user: "ของตกแต่งฮาโลวีนไปไว้กับสกินของร้าน เวลาย้ายจะไม่กระทบ" — the user keeps hand-moving the shops): `SeasonalDecor.applyAnchors` moves every child of a sub-model that has attributes `AnchorPath` (path under workspace, e.g. "Shops.FarmStall") + `AnchorCFrame` (the anchor's pivot when the group was laid out) by `anchorNow * AnchorCFrame:Inverse()` when the set is cloned in. Groups: ShopArea + Extra.ShopExtra → Shops.FarmStall; FishingArea → FishingShop; CraftBenchArea (new) → OtterCraftBench. After hand-editing an anchored group, reset its AnchorCFrame to the anchor's current pivot. Lantern-base pumpkins are now made at RUNTIME in applyLanterns from `SeasonalProps.Halloween2026.LanternBase` (pivot = bottom; BASE_OFFSET (−1.9,0,−1.2); raycast to terrain, skipped on water or if ground differs > 1.5) — the 35 static ones were stashed. Verified once in Play with faked anchor shifts (+10 X, 30° yaw): pieces landed exactly as computed. The last lantern-pumpkin raycast edit was NOT re-run (start_stop_play timed out). Backup script `SeasonalDecor_before_anchor`, set copy `Halloween_before_anchor` in `_Backup_20261013_IslandRebuild`. Kit attributes named `RBX_AI_GENERATED` cannot be cleared from execute_luau (CoreScript permission) — skip attributes starting with "RBX".
- 2026-10-13 (later): boxing-ring decor anchored too (user: "ปรับสนามมวยให้เป็นสกินฮาโลวีนเหมือนกัน เวลาย้ายจะไม่ส่งผลกระทบ"): `SouthBeach` (12 pieces) has AnchorPath "BoxingRing"; the 4 lantern posts that used to line the walk from the OLD fishing-shop spot became 2 gate pairs in front of the ring steps (24 / 34 studs from the ring centre, ±7 sideways). Ring centre was (52.6,−491.9) that day (user had moved it, not rotated). GOTCHA: the ring's steps sit 1.9 studs off the ring's centre line, so the average step offset is NOT a rotation — derive yaw only from the dominant axis (or the pivot), I rotated the set 8° by mistake first and had to restore from `Halloween_SouthBeach_before_ringanchor`. Not viewed in Play. The Studio id changed again that evening (0e24ae48-…): always re-list studios after a "not connected" error.
- 2026-10-13 (night) plot skin for the REBUILT island (user: "ทำสกินเทศกาลฮาโลวีนของแปลงผัก"): `SeasonalDecor.applyPlots` now also skins `workspace.IslandDecor.PlotFences.Fence<n>` (Rail = BeamColor purple, Post = PostColor orange, `PostTopper` pumpkin on the 4 corner posts) and `PlotNumbers.PlotNumber<n>` (Board = SignColor, Post orange, pumpkin on the board) — runtime only with undo, same `SeasonConfig...Plots` values. Verified in Studio Play (50/50 rails, 300 posts, 50 toppers, one screenshot). Unfenced plots (22, 55–62) unchanged; restore-on-season-end still untested; the user had not reacted yet. Backup `_Backup_20261013.SeasonalDecor_before_fenceskin`.
- 2026-10-13 (night) craft-bench skin (user: "ทำสกินฮาโลวีนโต๊ะช่างนากน้อย"): the bench is PART-BUILT (no single mesh), so mesh swap does not apply → new `SeasonalDecor.applyRecolors` + `SeasonConfig...Recolors = { { Path, Colors = { ["r,g,b"] = Color3 }, ByName = { [partName] = {...} }, Topper, TopperScale, TopperOn = { [partName] = true }, FrontPart } }` (runtime, undo, skips MeshParts). OtterCraftBench: pink → orange, deep pink → purple, light pink → lavender, white awning/drape stripes → purple, small pumpkins on the 2 awning post caps. Verified in Studio Play + one screenshot; season-end restore untested. Reuse `Recolors` for any other part-built prop.
- 2026-10-13 (night) photo spot (user: "จัดเป็นบูธหรือสิ่งตกแต่งสำหรับไว้ถ่ายภาพฮาโลวีน ตรงหาดฝั่งร้านตกปลา"): sub-model `PhotoBooth` (57 parts) in the stored set, centre (80, 2, 345) on flat sand, front faces −Z (toward the fishing shop, which was at (61, 280) that night). Kit Arch ×2.4 as the backdrop (it is a purple gate with half-open doors), part-built round rug, moon disk, bunting (rope + flag parts), bilingual sign off to the −X side. Not anchored to anything; hidden beach plot FarmPlot61 (x −52..32, z 332..350) is next to it — keep clear. Built in Workspace for screenshots, then moved into the set. Not seen in Play. SurfaceGui gotcha: TextScaled + TextWrapped=false collapsed the text to ~8 px in Edit; use a fixed TextSize for one-line labels.
- 2026-10-13 (night): the set was taken OUT to `Workspace.Halloween2026` (284 parts) and PUT BACK the same night on "เก็บกลับ" (284 parts, anchors reset) — current home: `ServerStorage.SeasonalDecor.Halloween2026`. The user published by accident once that day while unsure where the set was, so always check its location before calling a Publish safe. When taking it out, apply each anchored group's delta and reset `AnchorCFrame` so the user sees pieces where they will really appear (nothing had moved this time). When putting it back, reset `AnchorCFrame` of anchored groups to the anchor's current pivot.
- 2026-10-14: taken OUT to Workspace (284 parts) and PUT BACK the same day on "ย้ายฮาโลวีนย้อนกลับ" (368 parts incl. new PlazaLandmark + BeachStageArea, anchors reset). Current home: `ServerStorage.SeasonalDecor.Halloween2026`.
- 2026-10-14 seed-shop plaza landmark (user: "ลานกิจกรรม ไม่ต้องรกมาก แลนด์มาร์คถ่ายรูปน่ารักๆ"): sub-model `PlazaLandmark` (43 parts) — AI mesh pumpkin house with a smiling face + purple witch hat (scaled ×1.3, ~20×23×15) first at (44, 4, −211), then MOVED by the user's request to where their character stood: house (36.3, −236.5) at the plaza's south edge, whole group shifted by (−7.7, −25.5) (rug ≈ (36.3, −219.5)); facing +Z, small pumpkins in a back arc, 2 lantern posts + bunting, 2 ghosts, 2 bats, bilingual sign. Plaza = brick x 24..88, z −228..−84; boards along x 74 (z −176/−200/−224), spawn (31, −163), stall (73, −152) facing −X. Not anchored. Built while the set was OUT in Workspace. The user liked the "pumpkin + witch hat + big round eyes" look before; the AI mesh came out cute on the first try with that prompt.
- 2026-10-14 the whole set (out in Workspace) got lifted +4.7 studs — almost certainly the user dragged the `Halloween2026` model while selecting/moving the landmark. Fixed by shifting every group's children −4.70 and snapping 5 leftovers to terrain. Audit recipe: per piece, bbox bottom vs a raycast (exclude the set + characters) from just above the bottom; skip SeasonBob / Bat / Ghost / Bunting / Rope / Flag / Moon / Sign / Rug; sea floaters vs water surface. If the user reports "everything floats", check for one uniform offset first.
- 2026-10-14 beach stage + bar skin (user: "เพิ่มสกินฮาโลวีนให้ลานเวทีและบาร์ น่ารักๆ"): `Recolors` entry `IslandDecor.BeachStage` (blue → purple, mint → lime, pink → orange, yellow → yellow-orange; wood/thatch/signs untouched) + sub-model `BeachStageArea` (41 parts, AnchorPath "IslandDecor.BeachStage"): bunting across the stage front, pumpkins on the stage edge + piles at its corners, 2 ghosts, 2 bats, bucket + pumpkin on the bar counter, black cat, a tiny pumpkin on each of the 5 tables. Stage geometry that day: platform x 118..134, z −387..−357 facing −X, dance floor x 91..113, bar counter x 96..112 at z −338, tables x 67..86. Verified in Studio Play + one overview screenshot.

2026-10-14 LAUNCH: user said "เปิดเทศกาลได้เลย", will Publish at midnight. SeasonConfig Halloween2026 Enabled = true and StartUtc moved 24 Oct → 15 Oct 00:00 Thai (= GhostGacha2026 start); GhostGacha2026 Enabled = true. Both end 2 Nov. Booster skins now go live with it (they follow Halloween2026). Backup _Backup_20261014.SeasonConfig_before_launch. Publish itself not confirmed by me.

2026-10-14: Halloween decor now SOLID for 135 ground pieces (user asked "ไม่ให้เดินทะลุ"): CanCollide true + attribute HalloweenCollide; meshes Hull, Arch + PumpkinHouse PreciseConvexDecomposition; floating (SeasonBob), flat, small, and pieces inside beach FarmPlot55/58/59/61 stay pass-through. CanQuery still false. New decor pieces placed later need the same treatment.

- 2026-10-18 Halloween night music: BackgroundMusic `SEASON_NIGHT.Halloween2026` = "Lanterns by the Harvest Gate" (91061903312421, uploaded by the user that day) plays alone on repeat when the season is active AND the player's time is Night (19:00-07:00 = the personal "ตอนค่ำ" preset; the server is day-only). Add other festivals' night songs to SEASON_NIGHT. Verified in Play. Not published.

- 2026-10-19 Halloween default time: PersonalTimeGui `SEASON_DEFAULT_TIME = { Halloween2026 = "evening" }` applies (not saved) when SavedPersonalTime == "" (never chose). "Follow game time" now saves "game" (GraphicsPrefs VALID_TIMES has game). Players who pressed follow-game-time before this update look like "never chose" and also get evening. Logic simulated, not Play-tested with a fresh account. Not published.
- 2026-10-19: set taken OUT to `Workspace.Halloween2026` again (368 parts, anchors all 0 shift, AnchorCFrames reset) on "ย้ายออกมาที่ work space ก่อน แก้ไขแปป". The empty `ServerStorage.SeasonalDecor.Halloween2026` folder was destroyed — recreate it as a Model when putting back. MUST go back before any Publish.
- 2026-10-20: PUT BACK into `ServerStorage.SeasonalDecor.Halloween2026` (368 parts, anchors reset) after the user's hand edits. Workspace.Halloween2026 gone. Current home: ServerStorage.


---

## seat-drag-bug

Bug reported 2026-10-08: players warp and sit down by themselves at warp spots.

Cause: SeatWeld joins an Anchored Seat to the character as one assembly, so `character:PivotTo` moves the seat too. The client then breaks the weld and the invisible seat (RestSpots benches/sala/hammock, Transparency 1) stays at the warp spot. `humanoid.Sit = false` on the server is not enough.

Fix (published 2026-10-08, user confirmed live that sit-then-warp works):
- WarpService `leaveSeat` destroys the joints between the seat and the character.
- If the player was seated, wait 0.35 s, then PivotTo, then re-check after 0.5 s. Without the wait, the client's position overrode the first warp: the player stood up but stayed at the bench.
- New ServerScriptService.SeatGuard: snaps any anchored Seat that drifts more than 1 stud back to its start CFrame every 2 s.

**Why:** any future server teleport of a character has the same trap.
**How to apply:** cut seat joints before moving a seated character (CarryService release, LastPosition, new teleports). Related: [[warp-menu]], [[carry-system]].


---

## server-crash-diagnosis

How to investigate "server หลุด / error 279" without Dashboard access:

- DataStore `DisconnectLogs_v1` (key `u<userId>`, last 12 sessions, written by ServerScriptService.DisconnectLogger) is readable from Studio edit mode. Each entry has jobId, joinedAt/leftAt (ms), status, pingMs, AFK-rejoin flags. Studio sessions have jobId "".
  - A server where many players are still `status = "active"` (no leave record) died without running PlayerRemoving = crash/hang, not players leaving.
  - Scanning all keys (~300) takes ~100 s: run it in `task.spawn`, keep results in `shared`, and poll with short execute_luau calls (one long call times out).
- Public, no login: `https://games.roblox.com/v1/games/75556752635760/servers/Public?limit=100` (live servers: JobId, players, fps, ping) and `https://games.roblox.com/v1/games?universeIds=10765716288` (`updated` = last publish/save time, playing).
- MemoryStore (`LivePublicServers_v1`) in Studio is isolated from live: useless for this.
- Creator Dashboard needs the user's login; the built-in browser is not logged in. Its Performance page shows NO graphs for this game yet ("stats appear when the experience grows"), so there is no memory history there. Error Report (under การติดตาม) works but showed no crash-causing server error.
- `ServerScriptService.ServerHealthLogger` (built 2026-10-13, needs Publish, untested live): every 5 min writes memory / Lua heap / instance count / server FPS / per-tag memory to DataStore `ServerHealth_v1`, key `s_<JobId>` ({startedAt, placeVersion, recent[60], hourly[72]}). After the next crash, read the dead server's key to see whether memory climbed.
- ServerHealthLogger is LIVE since 2026-10-13 05:11 Thai (server 0b2a32e6, place version 1831). Baseline at 60 s uptime, 4 players: total 992.6 MB, Lua 99.3 MB, 152,603 instances, 59.4 FPS. Compare later samples against this to judge a leak. Read keys with ListKeysAsync on `ServerHealth_v1` (small calls; whole-game source scans from execute_luau time out).
- 2026-10-13 also switched StarterGift / LuckBoosterGift / AdminGive / SultanService to wait for `InventoryReady` (real bag load) instead of `InventoryLoaded`; done ~05:15, after the live publish, so probably needs another Publish.
- Side finding from the Error Report: heavy DataStore throttling (GetAsync on AudioSettings_v1, BoomboxPromoEntitlements_v1; UpdateAsync) and 30× "InventorySystem: ข้ามการเซฟกระเป๋า" (load failed → no save). Investigated 2026-10-13 (code scan, no fix made): one join makes ~43 DataStore requests (~37 reads + ~6 UpdateAsync) across ~35 stores; 8 of them are "pending gift" stores that are almost always empty, and BoomboxPromoEntitlements_v1 is read twice per join (BoomboxService + BoomboxGift). Steady AFK rejoins (~1 join/min) fit the budget; my inference is that throttling comes from mass joins (new server after restart/crash). Most loaders already retry forever via DataLoadRetry; InventorySystem retries in the background too, so "ข้ามการเซฟกระเป๋า" = player left/autosaved before the load succeeded. Budget-delta measurement in Studio Play does not work (starting budget unknown, Studio budgets differ from live). Correction: only ~5 join-time gift checks exist (AutoFeeder, VIP, Sultan, PetSlot, Boombox); rod/quota/luck gift GetAsync are purchase-time.
- Done 2026-10-13 (user chose "delay non-critical first"; not published): `DataLoadRetry.Defer(player, label)` (2–6 s, then waits while GetAsync/UpdateAsync budget < 20, max 45 s) called in DisconnectLogger join write, BoomboxGift, LuckBoosterGift.deliver, StarterGift, AdminGive.deliver. VIP/Sultan/AutoFeeder gift checks left alone (chained with ownership checks). Unknown: whether the live budget API matches the new limiter. Not done: merging gift stores into one inbox.
- Also fixed: InventorySystem had no catch-up loop for players who joined before its top-level requires finished (seen once in Studio: bag never loaded, no warning). Untested after the fix (Studio Play would not start).

Best evidence source found later the same day: the Creator Dashboard server list (the user reached it under การกำหนดค่า → การจัดการเซิร์ฟเวอร์; columns: status, place version, engine version, players, FPS, memory, start, end, uptime). For the dead server it showed: status "หยุดทำงาน" (my reading: crashed; there is a separate filter chip that looks like out-of-memory, not confirmed), v1781, engine 0.742, 15/30 players, 60 FPS, 2,458 MB, started 2026-10-12 16:23, ended 2026-10-13 03:54, uptime 11 h 30 m. New server v1831, engine 0.743, 4 players, 1,081 MB at 43 min. So memory was ~2.4 GB at death, FPS fine: out-of-memory looks unlikely, an engine/host crash more likely (not proven).

The same list showed only 3 stopped servers in total (so the list is crashes, not normal shutdowns — my inference: ~14 other servers closed that night and are not listed): (a) 2026-10-07 04:34→08:06, 3 h 32 m, 6 players, 1,113 MB, v1346, engine 0.741; (b) 2026-10-08 19:21→10-09 05:37, 10 h 15 m, 6 players, 1,592 MB, v1490, engine 0.742; (c) the 10-13 one above. All 60 FPS, memory far below any limit, uptimes differ → not memory, not a fixed uptime. Three crashes in 6 days suggests something in the game trips an engine crash (unproven). Weak leak signal: same 6 players, 1,113 MB at 3.5 h vs 1,592 MB at 10 h ≈ +70 MB/h.

Optimization finding 2026-10-13 (measured in Edit, nothing deleted, awaiting the user's decision): ServerStorage holds 110,529 instances vs 21,138 in Workspace; 69 `_Backup_*` folders hold 103,116 of them. Two folders are 90k: `_Backup_20261003_terrace_crops` (46,472: WheatView + CornView, 21.9k parts) and `_Backup_20261003_Mountains` (43,765, almost all in `HikingMapItems`; the TerrainBefore* regions are tiny). These load on every live server (live reported 152,603 instances at start). Done by the user the same day: both removed (terrain regions kept), ServerStorage now 20,299 instances; not published yet, live memory effect not measured (compare the next server's first health sample with 992.6 MB / 152,603 instances). Gotcha: whole-game scans from execute_luau coincided with Studio disconnecting twice — count per service/per folder with task.wait() between, and warn the user first.

LEAK CONFIRMED by ServerHealth_v1, server 0b2a32e6 (v1831) on 2026-10-13, 05:12 → 20:44 (15.5 h): total 992.6 → 2,406 MB (~90 MB/h), never drops when players leave. Tags (MB) at 05:12 / 13:13 / 20:44: PhysicsParts 161 / 460 / 746, Internal 227 / 427 / 585, Instances 13 / 71 / 127, Animation 4 / 51 / 94, Signals 10 / 40 / 72, LuaHeap 112 / 145 / 161 (flat-ish), Terrain flat. Instance count 152,603 → 272,505; with the same 11 players it still rose 200k → 219k in 4 h. So parts/instances (with animators + connections) accumulate — NOT a Lua table leak. Source not found yet; my guess is something per join/rejoin or per crop/pet that is never destroyed (AFK rejoins ≈ 50/h). Next step: in a long Studio Play or on live, count instances per container (workspace children, nil-parented) over time. `workspace.PlayerCharacterDestroyBehavior` no longer exists as a property, so that known cause can't be checked that way.
Cleanup result measured: server 7277862f (v1852, after removing the 2 backup folders) started at 778.4 MB / 56,677 instances vs 992.6 MB / 152,603 before.

2nd data-confirmed crash 2026-10-14: server d6c14acc (v1914, started 00:31) last health sample 08:07:51 (9 players, 1,805 MB, 60 FPS, 143,406 inst), then silence; owner session left "active" → died 08:08–08:13 after 7.6 h. Same abrupt pattern. Leak again in v1914: players 21 → 9 while instances 104k → 143k, PhysicsParts 89 → 449 MB, Animation 7 → 63 MB. Abrupt deaths so far (Thai time): 10-07 08:06 (unverified), 10-09 05:37 (unverified), 10-13 03:49–03:54, 10-14 ~08:10; memory at death 1.1 / 1.6 / 2.46 / 1.8 GB.
Caveat learned 10-13 late: the Dashboard list's "หยุดทำงาน" also shows a Team Create (Studio) session that simply closed, so it may just mean "stopped", not "crashed"; the third filter chip is "หน่วยความจำไม่เพียงพอ" (out of memory) and none of ours had it.
ServerHealthLogger got `countGroups()` on 2026-10-14 (hourly `sample.groups`: ws top-14 by child name, svc per service, dm, orphan = InstanceCount − dm); needs Publish + a new server. Read `hourly[i].groups` to see which group grows. LIVE since v1928 (server 6c5b96c3, started 2026-10-14 10:20). Baseline at 1 min, 7 players: 897.8 MB, 73,162 inst, crops 70, cropsOffline 0, (characters) 4,498, Players svc 10,331, ServerStorage 26,113, orphan 8,857, wsTotal 25,126. Also has groups.crops / cropsOffline (added same day).

User's experiment from 2026-10-14: manual server restart every day at 01:00, 09:00 and 17:00 Thai (8 h max uptime) to see whether crashes stop. No overlap with trash-event rounds (12:00/18:00/21:00/00:00, 30 min). Caveat told to the user: crashes happened at 3.5 h and 7.6 h uptime too, so this may not prevent all of them. When judging results, a restart shows as a normal shutdown (not listed as "หยุดทำงาน"); a crash shows as "หยุดทำงาน" + health log stopping mid-interval.

ORPHAN LEAK (2026-10-14, from groups.orphan = InstanceCount − counted DataModel): the only group that only ever grows. Server 6c5b96c3 (5–7 players): 8,857 → 23,890 in 6 h (~2,600/h). Server 02f95f87 (8–10 players): 7,680 → 22,175 in 3 h (~4,800/h) → scales with player count, roughly ~500 orphans per player-hour. Crops, cropsOffline (always 0), characters and Players-service counts follow the player count, so they are NOT the leak. Static checks done: no player-keyed table left uncleared (PetManager.finalSaved is weak-keyed), only one server LoadAnimation (CarryService). Next: Studio soak test with features toggled — only when the owner is NOT live (owner plays on the same account).
Restart log 2026-10-14: 6c5b96c3 last sample 16:57 → 02f95f87 started 17:00 (planned 17:00 restart); 02f95f87 last 20:31 → d70116dd (v1964) started 20:35 (looked like a publish + restart; not confirmed by the user). 2026-10-15: d70116dd last 23:56 → 0a716c93 (v1968) 00:00 (publish); user restarted ~02:27 → 6f08b1e4 (v1978). No crash 10-14 20:35 → 10-15 02:41; orphan leak still ~4,000/h with 8–11 players. 6f08b1e4 ran 02:27→08:59 (6.5 h) with no crash: 954→1,364 MB, orphan 10k→42k (worst ~7,800/h at 05–06 with 8–10 players). ~08:54–08:58 two v1980 servers started (d8b74884, 955d640b; 2–3 players each, ~800 MB) — user says it was their timed 09:00 restart. 2026-10-15 leak hunt: on 6f08b1e4 orphan growth/h did NOT follow player leaves (from DisconnectLogs scan) nor crop stage models (4–10%, noisy) → not mainly characters/Players. Built ServerScriptService.LeakTracker (weak-table watch of removed roots per container, probe-destroy check at scan, labels "Class Name < origin"), ServerHealthLogger writes groups.leak (top 12) + groups.leakSum hourly; needs Publish. Gotchas: this place uses DEFERRED events (handler sees Parent already nil → hook per container); setting Parent=nil on a destroyed instance does NOT error (probe by parenting into an out-of-game Folder instead). Studio Play was stuck at 13:00 (cause unknown; console showed "One_moretime91 joined live editing session" — One_moretime91 IS the owner account 9360333174, not another person). User published ~17:00 (v1994). ROOT CAUSE FOUND 18:04 by groups.leak: leaked roots are Player objects of players who LEFT (~900–1,800 inst each) + their old characters (~350–450 each), never destroyed, still referenced by scripts (e.g. 6808073f: 10 Players 18,229 inst + 11 chars). FIX BUILT 2026-10-15 20:30 (Studio only, not published): ServerScriptService.PlayerCleanup — leave: wait ≥180 s + until DataLoadRetry.PendingLeaveSaves(userId) == 0 (new helper, max 600 s), then Destroy Player + last character; respawn: Destroy old character after 30 s. workspace attr PlayerCleanupFast (Studio) shortens waits. Play-tested respawn path (control with script off: engine does NOT destroy old chars); leave path untested (solo Play ends). After publish: verify groups.leak only shows Players < ~3 min old and orphan stops growing. PUBLISHED 2026-10-16 01:32 (server b60ba89c, v2053; first restart at 01:15 still ran old v1994 — user had restarted without publishing). VERIFIED ON LIVE 02:33: groups.leak = 1 root / 1 inst (vs 21 roots / 22,348 inst in the first hour before the fix); memory flat ~1,000 MB with 8 players 02:18–02:43. Orphan still 7,089 → 12,574 while players went 4 → 8 — watch 3–6 h to see if it tracks time or only player count. 08:38 (7 h uptime): memory FLAT ~1,000 MB (5–8 players), PhysicsParts flat ~75 MB, Animation ~9 MB → memory leak FIXED. Leftover: ~7 destroyed-but-referenced Players/h (1 inst each, negligible); InstanceCount/orphan still +~5,700/h with flat memory = lightweight never-parented instances (tweens?), not seen by LeakTracker — low priority. Earlier note (in-game AutoRestart still inactive: TransitPlaceId = 0, so the restart came from outside the game code).

2026-10-17: a2e96762 (v2111, 09:01→18:01) → 459f623c started 18:01:43 = the user's 17:00 restart done late (user confirmed). Players' sessions closed as "left", so a manual restart looks like a clean leave in DisconnectLogs.

Incident 2026-10-13: server f50f10a0 (up since ≥17:45 on 10-12, 15 players, pings 30–50 ms) stopped between 03:48:57 and 03:53:49 Thai time; all 15 sessions left "active". New server 3222f179 started 03:55:12; game `updated` 03:55:14. Cause not confirmed (asked the user whether they published/shut down; otherwise suspect a crash after 10 h uptime, e.g. memory). PlayerExitReason is always "Unknown" in the logs, so it does not help.


---

## sound-groups

The "เพลงและเสียง" panel (`StarterPlayerScripts."BackgroundMusic "`, note the trailing space in the script name) has four sliders:
- 🎵 music: `musicSound.Volume` directly.
- ✨ effects: `SoundService.EffectSounds` (planting, fishing, shop, level-up, pet, booster thud...).
- 🌿 nature (added 2026-10-11, user asked for a separate control): `SoundService.NatureSounds` — birds/night insects (`AmbientSounds`), pond/stream/waterfall Sounds in the map, rain + thunder (`WeatherClient`). Rain being "nature" was my call.
- 🐧 Music Box: `BoomboxLocalSounds`.

Saved by `ServerScriptService.AudioPrefs` in `AudioSettings_v1` {music, effects, nature, boomboxVolume, ...}; nature uses RemoteEvent `NatureSettingsSave` + attr `SavedNatureVolume` (same pattern as the Music Box slider). A player with no saved `nature` inherits their effects value.

**How to apply:** any new `Sound` (script-created or placed in the map) must set `SoundGroup` to EffectSounds or NatureSounds, otherwise the user will report "the slider does not control it" (found 2026-10-11: booster thud and the bird ambience were ungrouped). Group default is 0.4, so a grouped sound plays at Volume × 0.4 at default — compensate the Sound's own Volume if it must stay as loud. Campfire Sounds in the map are ungrouped but not playing.

Ducking (2026-10-18): BackgroundMusic now nests `SoundService.BackgroundMusicDuck` (Volume 1) above `BackgroundMusicFade` (the track-crossfade group). Other scripts lower the game music temporarily by tweening BackgroundMusicDuck.Volume (WishingPondGui does it to 0 during the Happy Birthday song, see [[wishing-pond]]); never touch musicSound.Volume (that is the player's saved slider).

Not tested: dragging the nature slider and the value surviving a rejoin; gamepad on the new row.


---

## star-lock

User 2026-10-03: "อยากให้ในกระเป๋ามีระบบติดดาวได้ด้วย และปรับตอนขายจะไม่ขายตัวที่ติดดาวด้วย".

- Data: Tool attribute `Starred = true` (nil = off) on PRODUCE and FISH stacks only (not junk/bait/seeds/rods). A stack = one (type, star-level) pair, so starring locks the whole stack; new items of the same type+star merge into it (ItemFactory/PlantingSystem find an existing stack) and become locked too.
- UI: `FullInventoryGui` card gets a round ⭐ button (top right under the strip, 24 px): grey/transparent = off, gold = on; tapping toggles it and shows a notice line. Gamepad: Selectable (blue frame on the card).
- Server: `InventorySystem` RemoteEvent `RemoteEvents.InventoryStar(tool, bool)` (validates tool ownership + type, 0.15 s throttle) sets/clears the attribute; save/restore keeps it (`starred = true` in the Fish/Produce entries of PlayerInventory_v1, set again in giveItems).
- Enforced in: ShopSystem (findProduceTool/findFishTool → sell list, sellCrop, "ขายทั้งหมด" skips Starred), FishingShop (usableTools: bait making + sellFish/sellAllFish; stacks list hides starred), PetFoodConverter (produceStacks skips Starred → not shown/insertable). NOT covered: other future sinks (add the check there too), PetSeedSlots/Tutorial reads.
- Verified in Studio: scripts compile; 80 star buttons drawn; clicking one set Starred on the server (a ⭐4 watermelon stack) and showed the notice. NOT verified: the sell screens actually hiding it (the Studio shop UI test path was flaky; I did not run a real sale on the live save), restart persistence, phone/gamepad. I removed the test star before stopping Play. Backups _Backup_20261003.ShopSystem/FishingShop/PetFoodConverter/InventorySystem/FullInventoryGui_before_star. Needs Publish.


---

## streaming-atomic-models

The place has StreamingEnabled. With `ModelStreamingMode = Default` the parts of a model are streamed to each client one by one, so low-memory phones can end up with incomplete models.

2026-10-12 user report: Android Infinix Hot 40i — WhiteTiger had no eyes, the fox had no ears. Tiger eyes are plain Parts inside the nested sub-model `Face`; fox ears are in sub-models `left ear` / `right ear` (pet models have 7–10 nested sub-models). Not an asset-download problem.

Fix (not published, not confirmed on that phone): all 10 `ServerStorage.PetTemplates` set to Atomic, and `PetSystem.PetController` sets `pet.ModelStreamingMode = Atomic` after cloning.

The player was on the in-game "ต่ำสุด" level (which hides only OTHER players' pets, whole). Second mitigation the same day: all 85 MeshParts in PetTemplates set `RenderFidelity = Precise` (tiger eyes are 0.06-stud discs on the head surface; a reduced-detail head mesh on a weak device could cover them). Could NOT reproduce on PC at Roblox quality Level01 (both Automatic and Precise looked complete), so the real cause is still unknown.

2026-10-12 later: user says it still happens, even on "ต่ำสุด": characters load but pets are sometimes invisible and a freshly placed scarecrow sometimes does not show. Analysis given (nothing changed, nothing measured): main suspect = replication congestion from the vine pumpkin ([[pumpkin-vine]]). Each pumpkin stage is parts-only 8/22/32/49/77 parts (+SpecialMeshes), `setStage` destroys the old stage and clones the next, then `PivotTo` twice AFTER parenting; one plant = ~270 instances created and destroyed per 65 s cycle, so a 160-plot pumpkin farmer churns ~650 instances/s and pumpkin is the meta crop. Graphics levels (incl. CropLod hiding) only change rendering, not instance count/replication. Scarecrow template = 1 MeshPart (Default mode), so Atomic is irrelevant there. No client preload of pet/scarecrow meshes exists (AvatarPreload only preloads characters). Workspace streaming radii / StreamOutBehavior cannot be read from execute_luau or inspect_instance — ask the user to read them in Properties. Proposed order: (1) merge pumpkin stages into a few MeshParts and pivot before parenting, (2) preload pet + scarecrow meshes at join, (3) review streaming settings, (4) ask reporters whether it is their own pet or others' (lowest hides others' pets by design). Waiting for the user's choice.

2026-10-12 evening — MEASURED in Studio Play (client `Stats.Network.ServerStatsItem["Receive kBps"]`), nothing changed in the project: the pets themselves are the heavy replication source, not proven to be the pumpkin. `PetController` animates on the SERVER every Heartbeat (Motor6D.C0 in setupWalkAnimation/setupTailFan/setupFlyAnimation + `pet:PivotTo` in updateFollow). The user's 3 idle pets = ~75 KB/s to the client, pets moved to ServerStorage = 1 KB/s (~25 KB/s per pet). Rig of fox clones: 10 = 550, 30 = 1,650, 90 = ~2,500 KB/s (saturates); split per pet: motors ~29 KB/s, PivotTo 60 Hz ~19 KB/s, PivotTo 10 Hz ~3 KB/s. The "ต่ำสุด" level only hides other pets locally, the data still arrives. Studio (localhost) showed no arrival delay for new parts even at 90 rigs, so the invisible pet/scarecrow/avatar itself was NOT reproduced — the link to the symptoms is inference (real links can't carry it → new instances queue late). Pumpkin churn remains unmeasured.

FIX BUILT 2026-10-12 (user: "ลงมือแก้ไขได้เลย ไม่ต้องแยกเป็นสองขั้น"), not published: `PetController` keeps the position per frame in `simCF` but calls `PivotTo` only every 0.1 s when it moved (adopts external moves such as `PetManager.gatherPets`), sets attributes `AnimBones` (JSON) / `AnimFlying` / `RainbowAura` / `FacingOffset` / `WorkAnim` ("mode;serverTime;length"); fire breath stays on the server. New LocalScript `StarterPlayerScripts.PetAnimator` does joints, work bob, flying hover, rainbow and position smoothing (snapshot interpolation with a render delay — the first "restart the lerp on each arrival" version stuttered at low FPS). `ReplicatedStorage.PetRenderState[model]` = drawn CFrame; per-frame client followers (PetFireflyRing) must read it, not `GetPivot()` (the server value overwrites the model between RenderStepped and Heartbeat ~10x/s). Measured after: idle 75 → ~4 KB/s, 60 clones walking ~105 KB/s (was ~2,900). Gotchas: to measure what is drawn, take the FIRST PrimaryPart CFrame change per frame; Studio was throttled to 15 fps so FPS numbers mean nothing. Not tested: real harvest/plant work, 2+ real players, phones, and the last edit (skip PivotTo when unchanged + half-rate joints beyond 35 studs — compile-checked only, Studio start-play got stuck). Backup `_Backup_20261012.PetController_before_clientanim`.

**How to apply:** any new model that must always appear whole (pets, NPCs, display props made of many parts) → set Atomic. If the report continues after publish, check other composite models and the device's graphics level (see [[graphics-settings]]); related report about avatars not appearing after an avatar change is in [[last-position]].


---

## studio-camera-restore-gotcha

In Edit mode, `execute_luau` puts the camera's `CameraType` back to what it was when the command started. If the Studio camera is stuck on `Scriptable` (user cannot right-click rotate / move the view — happened 2026-10-12, left over from screenshot work), setting `Fixed` inside the command looks fine in the return value but reverts the moment the command ends.

**Why:** two direct fixes "succeeded" and the user still could not rotate; a property-changed watcher showed the flip back at command end.

**How to apply:** set it after the command returns: `task.delay(2, function() cam.CameraType = Enum.CameraType.Fixed; cam.Focus = cam.CFrame * CFrame.new(0,0,-20) end)`, wait ~5 s outside Studio (no execute_luau in between), then verify in a new call. After any screenshot work that sets `Scriptable`, restore `Fixed` the same way. Related: [[studio-require-gotcha]].

Happened again 2026-10-14 after `screen_capture` with camera_position: I had "restored" it with `task.delay(0.5…)` + `task.wait(1.2)` + return inside the SAME command, which reported Fixed but it was Scriptable again afterwards. Verify only in a separate, later call; a delay-and-check inside one command proves nothing.

Happened a 3rd time 2026-10-18 after several `screen_capture` calls with camera_position (witch/sky screenshots). The task.delay(2) Fixed + separate verify call fixed it at once. Do this restore proactively at the end of any session that used screen_capture with camera_position.

5th time 2026-10-20 (banana grove + chicken coop screenshots) — user reported "คลิกขวาปรับมุมมองกล้องไม่ได้"; same fix worked. STILL forgetting: make the restore call the last step of any screenshot task, before wrap-up.

4th time 2026-10-19 (after hammer/sign screenshots with camera_position). The stuck Scriptable camera even SURVIVED a Studio restart (it is saved with the place). Same task.delay(2) Fixed fix + separate verify call worked. I forgot the proactive restore this time — always do it before ending a turn that used screen_capture with camera_position.


---

## studio-require-gotcha

`require(game.ServerScriptService.X)` / `require(...HotbarState)` inside `execute_luau` (Server or Client datamodel) returns a fresh copy of the module, NOT the one the running game scripts use. Seen 2026-10-09: FarmSlotRegistry.Slots was empty and HotbarState slots were all nil in my copy, so "the dragon does not plant" tests using them were invalid.

**Why:** cost a long detour while debugging the Sultan dragon not planting after a gacha level-up.
**How to apply:** test module-backed behaviour through the real inputs (e.g. Client DM `ReplicatedStorage.RemoteEvents.PetSeedSlots:FireServer(seedTool,false)` in a loop to fake hotbar slot 1, since CustomHotbar re-reports every 10 s) and observe real effects (seed Count attribute dropping, plants appearing), not by reading module tables.

Pet planter stuck (user report 2026-10-09: dragon stops planting after levelling at the gacha machine, re-equip fixes it): root cause NOT found. Verified clean: level-up path only sets PetLevel_/PetShards attrs; walking to the machine and back keeps planting. Added safety nets (PetController reachInFlight watchdog/token + pcall Consume, Planter target timeout 25 s + boosted-target owner-distance drop, GachaGui main.Active = true). If it recurs ask the user: does the dragon stand still or follow, does the 🌱 pill show ✓, are seeds still in hotbar slots 1-2. See [[pet-gacha-plan]].


---

## sultan-pack

User decisions 2026-09-30 ("pack suratarn" = สุลต่าน, "better than VIP"):
- Price 999 R$. A one-time Game Pass.
- It includes all VIP perks automatically. VIP buyers get no discount (Roblox can't discount per player).
- Cosmetics:
  - A "✨👑 สุลต่าน✨" badge (gold→purple animated) instead of the VIP badge.
  - Exclusive title colours (gold shimmer, galaxy).
  - A toggleable gold aura.
  - A [สุลต่าน] chat tag.
  - A server-wide join announcement.
- One-time bundle on purchase: 10 Premium tickets, 500,000 coins, 3 x100 scarecrows.
- Permanent perks (user: "ตามนั้นไปก่อน"): sell +20% (produce + fish), luck x2, faster pet-food machine, 1 free Premium ticket daily.
- Exclusive Sultan pet (not in the gacha): the user chose a RED DRAGON (มังกรแดง), 2026-09-30.
  - Look: chibi, red scales, gold belly and horns, small gold crown with a ruby.
  - Proposed: a new rarity "สุลต่าน" above Secret; ability Harvester + luck x20 + sell +10%. Not confirmed.
  - Rod / flying carpet are later.

Game Pass created 2026-09-30: ID 2002700579 "แพ็กสุลต่าน(SULTAN PACK)", 999 R$, and it was already ON SALE while steps 3-7 were unfinished. I warned the user and suggested Off Sale. The icon is scratchpad sultan_icon.svg (chibi red dragon + crown, "สุลต่าน / SULTAN" badge). The creator account owns it automatically, so Studio playtests grant the real bundle to the user.

Build order:
1. SultanConfig + SultanService: ownership, DevGrantSultan, IsSultan attr, VIP perks via VipService.
2. One-time bundle (DataStore flag) + daily ticket.
3. Perks: sell +20%, luck x2, machine speed.
4. Cosmetics: nametag badge, colours, chat tag, aura, join announcement.
5. Sultan pet.
6. Sell UI (window + QuickShop) + Game Pass icon; the user creates the pass and gives the ID.
7. Full test.

Progress:
- Steps 1-2 DONE 2026-09-30:
  - ReplicatedStorage.SultanConfig (GAMEPASS_ID 0 until the user creates the pass; BUNDLE; SELL_BONUS 0.2; LUCK_MULT 2; MACHINE_TIME_MULT 0.7; DAILY 1; DayIndex = Thai-time day).
  - ServerScriptService.SultanService:
    - DataStore Sultan_v1 {bundleGiven, lastDaily}.
    - claim() via UpdateAsync happens before granting.
    - The bundle waits for player attrs CoinsLoaded + InventoryLoaded, which I added to LeaderstatsSetup and InventorySystem.
    - Tickets use GachaTickets.Add with receipt ids "sultan_bundle" / "sultan_daily_<day>".
    - A daily re-check runs every 5 min.
    - Player attr IsSultan; DevGrantSultan works in Studio.
  - VipService grants VIP when IsSultan is set.
  - Also fixed a LeaderstatsSetup bug: a failed coin load used to save 50 over the real coins. It now retries 3x and skips saving if the load failed.
  - Tested: grant, no duplicate on rejoin. The user's data was restored: coins 860,502, x100 = 1, Premium 0, the sultan_* receipts removed from GachaTickets_v1, and the Sultan_v1 key removed.
  - Test-restore gotcha: sultan_* receipt ids must be removed from GachaTickets_v1.receipts, otherwise a real later grant is blocked as a duplicate.
- Step 3 DONE 2026-09-30:
  - Sell: SultanConfig.SellMultiplier / ApplySell(player, unitPrice) = +SELL_BONUS if IsSultan, plus player attr PetSellBonus (for the dragon later). Applied at the unit-price level in ShopSystem (3 display + 4 sell paths) and FishingShop (display + sell).
  - Luck: LuckConfig.Combine(booster, pet, player) multiplies by LUCK_MULT if IsSultan. LuckSystem.GetLuck and client LuckGui pass player.
  - Machine: PetFoodConverter data.timeMult (persisted, so offline too); per = Seconds * timeMult; applied on the IsSultan attr (true = 0.7, false = reset, nil = unknown so no change). SultanService sets IsSultan = false when the check says not owned. Info Seconds may be fractional; PetFoodGui uses secs() formatting plus a 👑 mark.
  - Verified: sell 100 → 120, luck 1 → 2, machine Lv4 8 s → 5.6 s, fish shop price x1.2, no errors.
  - The creator account got the REAL bundle this session (owner auto-owns the pass); intentionally not reverted.
- Step 4 DONE 2026-09-30:
  - VipConfig.COLORS gains goldshine / galaxy (sultan = true, gradient) plus SULTAN_BADGE / SULTAN_TEXT. VipService.save rejects sultan colours unless IsSultan.
  - PlayerNameTags: IsSultan swaps VipBadge text to "สุลต่าน" (GothamBlack, gold→purple gradient tagged VipShimmer). The Title gets a "Shimmer" gradient for sultan colours, falling back to default if not a sultan. Listens to IsSultan. VIP_BADGE_PINK constant.
  - VipGui:
    - A VipShimmer offset animator (plus localShimmers).
    - Chat tag [👑 สุลต่าน].
    - preview.setSultan().
    - 11 swatches (26 px, 👑 lock for non-sultans).
    - Aura toggle button (SultanRequest "aura").
    - Header "ฉายาสุลต่านของฉัน".
    - SultanBanner + DisplaySystemMessage on SultanAnnounce.
  - SultanService:
    - Aura = HRP Attachment "SultanAura" (2 sparkle emitters with rbxasset sparkles_main.dds + PointLight); player attr SultanAura (Sultan_v1.aura).
    - RemoteFunction SultanRequest; RemoteEvent SultanAnnounce.
    - grant(player, st, reason): "join" announces after 5 s, but not again within 30 min per server (AFK rejoin); "purchase" announces after 1 s.
  - Verified in Play: badge, aura on/off persisted, banner "👑 ท่านสุลต่าน OneMore เข้าสู่ฟาร์มแล้ว!", no errors.
- Step 5 DONE 2026-09-30 (Sultan Red Dragon):
  - Template ServerStorage.PetTemplates.SultanDragon:
    - AI mesh generated with explicit parts (body / left wing / right wing / tail), renamed Torso / LeftWing / RightWing / Tail.
    - HumanoidRootPart (1.2 cube) at Torso; Motor6D RootJoint.
    - Wing motors hinge at the inner edge (C1 = ±0.45*sizeX); Tail hinge C1 = +0.4*sizeZ. Front = +Z, so FacingOffset 180.
    - Effects: AuraLight + AuraEmitter embers, TailFlame fire_main, Mouth attachment + FireBreath (Enabled = false).
  - PetRarity.Tiers.Sultan: Order 5, red→gold gradient, HungerRate 0.5. LuckConfig.PetLuckByRarity.Sultan = 20.
  - PetDefinitions.SultanDragon:
    - NotInGacha, UnlockHint "👑 ได้จากแพ็กสุลต่านเท่านั้น".
    - Flying {Height 1.8, WorkHeight 0.7}, SellBonus 0.10, GrowBoost 0.15, Luck 20, Harvester.
  - PetController:
    - setupFlyAnimation: wing flap about Z, tail swish, FireBreath:Emit bursts every 10-18 s.
    - updateFollow: hover added to desiredY (lower while working), bob + nose-down + bank when Flying.
    - Spawn adds player attrs PetSellBonus / PetGrowBoost and removes them on pet.Destroying. Generic, so any def with SellBonus / GrowBoost works.
  - PlantingSystem growPlant: stage wait × RAIN_GROW_MULT (if raining) × (1 - owner PetGrowBoost). This also FIXES the old rain bonus, which was never applied.
  - SultanService.giveSultanPet: waits for player attr PetLevel_PastelPinkRabbit (PetOwnership loaded), then PetOwnership.Grant + notify.
  - GachaService pets list gains UnlockHint; GachaGui dupes tab shows it with "แลกด้วยเศษไม่ได้".
  - Verified in Play: granted and saved, spawn, hover about 3.9 studs above ground, wings moving, bonuses 0.1 / 0.15 set and cleared on unselect, sell mult 1.3, menu badge "✨ สุลต่าน ✨", no errors. The user's active pets are now NineLivesCat, Otter and SultanDragon (the dragon replaced the oldest one).
  - Gotcha: require() from the execute_luau command context gives a SEPARATE module instance (PetOwnership.Owns returned false). Check player attributes instead.
- Step 6 DONE 2026-09-30 (selling UI):
  - LocalScript SultanShopGui (ScreenGui "SultanShopGui", BindableEvent OpenSultanShop):
    - Layout 580x370 royal purple, gold gradient stroke; left: spinning dragon ViewportFrame + buy button (live price; owned shows "✔️ คุณเป็นสุลต่านแล้ว"); right: 8 perk rows built from SultanConfig/LuckConfig values.
    - Gamepad: SelectionGroup, selects Buy on open, B closes.
  - QuickShop (PlantLimitGui): SultanCard, cloned from feederCard, at LayoutOrder 1 (header moved to 0); dragon ViewportFrame icon; the button opens SultanShopGui.
  - QuickShop also gained a UIScale fit ((vp.Y - 132) / content height). It used to overflow phones; on 801x392 it is now 0.51.
  - VipGui: sell page "👑 ดูแพ็กสุลต่าน (ได้ VIP ด้วย)" (LayoutOrder 4); edit page "👑 อัปเกรดเป็นสุลต่าน" (LayoutOrder 10, hidden if IsSultan).
  - Emoji 🐉 renders as a GREEN dragon in Roblox, so red-dragon text uses 🔥 / 👑 instead.
- Step 7 DONE 2026-09-30: the user tested a real purchase with an alt account and CONFIRMED it works ("สุลต่าน เรียบร้อย"). The whole pack is complete. Related: [[vip-title-system]].
- 2026-09-30 later: the user asked for the overhead badge in English. VipConfig.SULTAN_TEXT = "SULTAN" and the font is FredokaOne (like VIP): size 26 in PlayerNameTags, 27 in the VipGui preview. Backups *_before_sultanEN. Chat tag changed to [👑 SULTAN] too (VipGui OnIncomingMessage, backup VipGui_before_chatSULTAN). The join banner "ท่านสุลต่าน ..." is still Thai.
- 2026-10-01 join-announce toggle, for sultans only:
  - SultanService stores Sultan_v1.announce and player attr "SultanJoinAnnounce" (default on). announce() skips "join" when it is false; "purchase" always announces. SultanRequest("announce", bool) saves it.
  - VipGui edit page has a "📣/🔕 ประกาศตอนเข้าเซิร์ฟ" button (LayoutOrder 8; save → 9, status → 10, upgrade → 11).
  - Tested: off → rejoin → no banner.
  - The user's own setting was turned back ON after the test (verified: attr true, saved).
  - Backups *_before_joinannounce.
- 2026-10-02 (user: "ปรับมังกรสุลต่านจากช่วยเก็บเป็นช่วยปลูก"): PetDefinitions.SultanDragon.Abilities = { "Planter" } (was Harvester; Lucky is still auto-added, luck 50). Texts "ช่วยปลูกผัก" in its Description and the SultanShopGui dragon row.
  - No migration on purpose: ability toggles are one switch per ability for all pets, so auto-enabling Planter could make a player's other Planter pets start using seeds. Existing owners must turn on "ช่วยปลูก" once (and put seeds in hotbar slots 1-2).
  - Verified only by requiring a clone of PetDefinitions in Edit (Planter+Lucky); the dragon actually planting while flying was NOT play-tested.
  - Backups _Backup_20261002.*_before_dragonplanter. Needs Publish.
- 2026-10-01 fixed: "ได้มังกรแดงสุลต่าน" re-granted on every join.
  - Cause: PetManager.setupPlayer ran twice on a slow start (PlayerAdded + the existing-players loop). The second PetOwnership.Load reset owned[player] to {starter} while awaiting the DataStore, so SultanService saw Owns = false (the attrs were already set by the first load) and granted it again.
  - Fix: PetManager uses a setupDone guard, and PetOwnership.Load keeps the existing set instead of replacing it.
  - Verified: owns = true on join, no grant. Data was never lost (saveMerge only adds).
  - Backups *_before_doubleload.

- 2026-10-01 plant quality floor (user: "ตอนปลูก การันตีขั้นต่ำ 3 ดาว ให้สมกับเป็นสุลต่าน"):
  - SultanConfig.MIN_PLANT_QUALITY = 3 and MinPlantQuality(player) (3 if IsSultan, else 1).
  - PlantingSystem.plantCrop: `slot.quality = math.max(MinPlantQuality(plantingPlayer), rollPlantQuality(luck))`. It is a FLOOR (a 1-2 star roll becomes 3), not a re-roll, so the 4/5-star odds are unchanged. It follows the planting owner, so the Planter pet's plants count too. The harvest star roll (HARVEST_ODDS by planted star) is unchanged, so a 3-star plant harvests 3-star mostly (5/20/50/20/5).
  - Odds with the floor (planted quality 1-5, %): luck x2 (Sultan base) 0/0/85/10/5 (was 42/25/18/10/5); luck 40 0/0/47/25/27; luck 90 0/0/36/28/36. A 3-star plant yields 4 produce (STAR_CONFIG), a 1-star plant 2.
  - UI: SultanShopGui perk row "🌟 ปลูกผักได้ ⭐3 ขึ้นไปเสมอ"; QuickShop SultanCard description adds "ปลูกผักได้ ⭐3 ขึ้นไป".
  - Tested: the odds by simulation with the live formula; two live plants by the account showed 3★ and 5★ (none below 3). Not tested live by the user. Needs Publish. Backups _Backup_20261001.*_before_minquality.
  - The user seemed to be playing inside my Play session (the seed count dropped by 5 by itself and the held tool changed): I did not plant test seeds myself.

- 2026-10-01 Sultan GIFT (user: "ทำส่งของขวัญของสุลต่านต่อ", Developer Product id 3715827793 = SultanConfig.GIFT_PRODUCT_ID). NOT live-tested by the user, the same as the VIP gift (see [[vip-title-system]] "VIP gift").
  - Same pattern as the VIP gift. SultanService "ของขวัญแพ็กสุลต่าน" section: DataStore "SultanGift_v1" keys `pending_<buyerId>` / `to_<targetId>` {from, fromName, t, receipt, seen}; SultanRequest action "giftSelect" (allowed for non-sultans); PurchaseRouter.Register(GIFT_PRODUCT_ID, grantGift); checkGift runs BEFORE checkOwnership at join (so IsSultan is never briefly false); grant(target, st, "purchase") gives the full pack (bundle + dragon + daily + VIP) and the server-wide "ได้เป็นสุลต่านแล้ว" banner.
  - The recipient must be in the same server and not IsSultan. The buyer can already be a sultan.
  - UI: VipGui GiftPage is shared (GIFT_KINDS vip/sultan; BindableEvents OpenVipGift / OpenSultanGift on VipGui; opened from outside, "← กลับ"/B closes the window). Pink 🎁-only buttons: SultanShopGui (beside the buy button, left panel) and PlantLimitGui SultanCard (pill under the button).
  - The gift product costs 2999 R$ (the pass is 999) ON PURPOSE for now (user, 2026-10-01: keep 2999, will find a suitable price later). Don't flag it again. The price is read live from Roblox, so changing it in the Dashboard needs no code change.
  - Studio test hooks as for the VIP gift: DevGiftSimulate / DevGiftOffline (server attrs on the player), DevGiftFakeFriends (client attr). Test records were removed from SultanGift_v1.
  - Verified: validation, simulated purchase saves `to_` and clears pending, page + confirm flow, join path (a record for the account: IsSultan true, seen = true, no bundle repeat). Not verified: the real prompt and a real friend.
  - Backups _Backup_20261001.SultanConfig/SultanService/VipGui/SultanShopGui/PlantLimitGui_before_sultangift.
- 2026-10-01 dragon re-grant race (found while testing: the log "ให้มังกรแดงสุลต่าน" came back at join):
  - Cause: PetOwnership.publish sets the PetLevel_<starter> attribute on ANY save (e.g. FishIndex's otter grant, or an early saveMerge) before Load has finished filling `owned[player]`; SultanService waited for that attribute and then saw Owns(dragon) = false.
  - Fix: PetOwnership.Load is now a wrapper that sets loadedOwnership[player]; PetOwnership.WaitLoaded(player, timeout). SultanService.giveSultanPet and FishIndex.grantRewardPet call it before checking Owns. Any new code that grants a pet or checks Owns at join must call WaitLoaded first.
  - Verified: a join with the gift record, no dragon grant log. Backups *_before_waitloaded.
- 2026-10-02 check "how does a Sultan plant now" (user asked; read-only report, no code change). Real Play measurement on the user's account (IsSultan = true), 24 watermelon seeds planted via the PlantByClick remote:
  - Luck: pets NineTailFox + NineLivesCat + SultanDragon (hunger ~80-90%) gave PetLuck 79.7; Sultan x2 → final luck ≈ 159. Expected planted-quality odds at that luck (1-5★): 4.5/7.9/16.9/28/42.7 %; with the floor 0/0/29/28/43 %.
  - Observed (from the harvest log lines, all 24): planted 3★ 7, 4★ 8, 5★ 9 (none below 3, matches). Harvest stars 2★ 1, 3★ 8, 4★ 9, 5★ 6. Yields 4-10 per plant (the Harvester pets double the yield: 5★ plant = 10).
  - PetGrowBoost 0.15 (dragon) and PetSellBonus 0.1 were set. The Harvester pets harvest ripe plants by themselves, so the ripe-plant prompt stars can't be read for long: read the "เก็บเกี่ยว X (ปลูกได้ N ดาว)" server log lines instead (PlantingSystem prints them).
  - Test hygiene: this cost real data. I removed the 170 produce I created (watermelon 2★ -8, 3★ -62, 4★ -61, 5★ -39), returned the 24 seeds, restored coins (offset trick: I deducted 480 first because leaving with unfinished plants refunds seed money, then the pets harvested them, so I added it back) and zeroed the CropStats counter. LevelSystem has no remove-XP: ~920 XP stayed (24 harvests). LESSON: before planting tests, snapshot all produce stack counts of that crop, and expect Harvester pets to harvest within ~35 s.
  - The user seemed to be playing in my Play session again (seed count dropped by 6 on its own).
- 2026-10-02 (user, on the status-edit page: "ไม่เอาออร่าทองรอบตัวและส่ง vip ให้เพื่อนแล้ว"):
  - The golden aura around the Sultan is REMOVED as a feature: the "✨ ออร่าทองรอบตัว" toggle button and its handler are gone from VipGui; SultanService.applyAura now has `local want = false`, so the aura attachment is never created (and an existing one is destroyed). The "aura" action / SultanAura attribute / Sultan_v1.aura data still exist, unused. To bring it back: restore the `want` line (the old expression is in the code comment) and re-add the button (backup _Backup_20261001.VipGui_before_noauragift).
  - The SultanShopGui perk text no longer says "ออร่าทอง".
  - The "🎁 ส่ง VIP ให้เพื่อน" button was removed from the status EDIT page only. The VIP gift is still reachable from the sell page (non-owners) and the 🎁 pill on the QuickShop VipCard. giftEditButton references are gone (B / back go to giftSellButton).
  - Verified in Play: no aura attachment on the character, no errors, the edit page lists preview, input, colours, show toggle, join-announce toggle and save.

- 2026-10-13 `ServerScriptService.TempSultan` (owner chat command `/tempsultan <name>` / `/tempsultan <name> off`): session-only IsSultan attribute for testing, no DataStore writes, no bundle/dragon/daily. Built because the user asked to "give Sultan to @CtrlZ_2 and revert later" — any real grant path (gift record, `promoSultan`, pass) hands out 500k coins + tickets + scarecrows + the dragon and can't be cleanly undone. Compiled, not typed in game. Same day I set and then reverted @CtrlZ_2's level (PlayerLevel_v1 back to {Level 8, XP 716}); writing another player's data was blocked by the permission classifier until the user typed an explicit confirmation naming the account. Team Test ("dev") shares the live DataStores.


---

## sunbee-rod

User 2026-10-08 sent a reference image (clover-wrapped branch, honeycomb, bees, sunflower bobber): 199 Robux, luck 5, guaranteed ★3+; I chose the rest.

- FishingConfig.Rods.SunBee: Luck 5, CastDistance 28, BiteTime {3,6}, HookWindow 2.9, ZoneBonus 0.12, TierWeights 45/36/16/3, `MinStar = 3`, `NoJunk = true`, RobuxPrice 199, **ProductId = 0, OnSale = false** → the user must create a 199 R$ Developer Product and give the ID; then set ProductId + OnSale = true (FishingShop registers every rod with RobuxPrice+ProductId>0 automatically).
- FishingSystem: rollFish handles MinStar (remaps size fraction into the ★3+ band) and NoJunk; `ROD_BOBBER` table gives per-rod bobber template/scale/lift/rot + line/aura colours (NightMoth + SunBee); SunBee held aura = golden Highlight "SunBeeAura" + PointLight.
- Models: FishingTemplates.Rod_SunBee (built from the NightMoth branch; vine "Vine*", clovers, BigClover*, HiveBulge/HoneyCell*/Bee*, Pole particles BeeSwarm/HoneyBits/GoldSparkles/GoldHalo) and Bobber_SunBee (sunflower, PrimaryPart "Center" with PivotOffset so pivot rotation is identity — needed, the centre cylinder is rotated).
- Textures: bee flipbook rbxassetid://104123192533627, honeycomb 108901434195529, glow dot 100881846134039.
- Tested: auto-fishing in Play gave 6 fish all ★3–★5; test fish removed. Not published.
- Aura upgrade (user: "น่าเกรงขามและน่าซื้อสุดๆ"): client LocalScript StarterPlayerScripts.SunBeeAuraFx — ground magic circle (SurfaceGui on an invisible pad, raycast to ground each frame, 2 images counter-rotating, Brightness 1.1 — higher washes into a blob with bloom), sunburst BillboardGui behind the body, rising gold motes + sunflower petals, pulses the rod Highlight/PointLight locally. Textures: circle 128255122232475, sunburst 140103725080553, petal 91306079180953.
- Showcase (2026-10-08): workspace.RodShowcase next to the fishing shop (Persistent streaming — the game has StreamingEnabled, client scripts must not assume far parts exist), ServerScriptService.RodShowcase places template rods in the cases + buy prompts, StarterPlayerScripts.RodShowcaseFx fills signs from FishingConfig every 1 s and spins the rods.
- SunBeeAuraFx now handles both rods via a STYLES table (SunBee gold + petals, NightMoth purple + butterfly flipbook 137826566831606). Otter NPC circles: put them on flat sand — the lake bank north of the shop is ~33–55° steep between z 1–4.
- Trial-holding ("ทดลองถือ") was started then cancelled by the user — don't re-add. Instead: 2 otter NPCs fishing at the lake shore in front of the fishing shop (workspace.FishingOtters + workspace.OtterDemo_<RodId>_Bobber, client StarterPlayerScripts.FishingOtterFx animates bite/catch, decorative only).
- 2026-10-08 later: user set ProductId 3717142136 (199 R$) → SunBee OnSale = true, Luck 8. NightMoth: Luck 5, price 99 R$ (dashboard updated by the user), OnSale = true. LESSON: never put a `--` comment in the middle of a config line (it commented out BiteTime/HookWindow and broke the fishing shop GUI).
- 2026-10-08 latest: user wants **junk catchable on every rod** — NoJunk removed from SunBee (the rollFish NoJunk check still exists; don't re-add the flag). Otters now only **stand holding the rod** in front of each case (no fishing, bobbers deleted); FishingOtterFx is hold-only (backup ServerStorage._Backup_20261008.FishingOtterFx_before_holdonly). The cases were moved: Case_NightMoth (-431.5,-1.3) left of the shop, Case_SunBee (-419.5,7.6) right; case front = PromptPart − Platform (≈(-0.6,0,0.8)), not the old f.
- User says the real Butterfly rod has **no foot aura**: Otter_NightMoth CirclePad deleted and NightMoth commented out of SunBeeAuraFx STYLES (backup SunBeeAuraFx_before_nomothcircle). Only SunBee has the ground circle. Display models must match what buyers really get.
- 2026-10-11: user asked aura light −15% → `dim = 0.85` in SunBeeAuraFx STYLES.SunBee (circle/motes/pulse), FishingSystem light 1.53 + highlight 0.847/0.278, template + Otter_SunBee brightness ×0.85 (backups _Backup_20261011.*_before_dim15). Lowest graphics (FxOff) now draws NO foot aura (user confirmed that reading: "ต่ำสุด = ปิดออร่าที่เท้า"). Not published. Same day: another −15% (dim 0.7225, server light 1.3, highlight 0.87/0.386, template/otter ×0.85 again), then −5% more (dim 0.686, server light 1.235, highlight 0.877/0.417) — each "ลดอีก N%" was applied on the current value, total ≈69% of original; a "light radius −30%" request was cancelled by the user (Range untouched).
- 2026-10-08 gift: Butterfly rod (NightMoth, GiftProductId 3717189301) and Little Bee rod (SunBee, GiftProductId 3717189349) can be gifted to a friend — FishingShop `FishingRodGiftRequest` + DataStore FishingRodGift_v1 (pending); 🎁 button on its row in FishingShopGui; VipGui kind `rod_<RodId>` (OpenRodGift:Fire(rodId)). Any Robux rod with a GiftProductId gets it automatically. Not live-tested with 2 players, not published yet.


---

## terrace-zone

Rice terraces "นาขั้นบันได" cover the east hill (x 140–300, z -40–244, peak ≈57). Generated by quantizing the natural hill height into 12-stud levels (tread tops y≈6/18/30/42/54, 4-stud voxel grid) so treads follow the contours; 2-cell blend next to kept-natural strips. Kept natural: hiking trail corridor (118,62)→(222,58)→(236,46)→(334,-52) ±11, access lanes z 92–100 and 192–200 (Ground paths), east trail area x>292.

Left side (from the farm view = south, z < 92) is decorative only since 2026-09-25: re-cut with 8-stud rise (HillPlan attr LeftRise=8), 75 paddies filled with 2,132 decorative 5-star Wheat Stage5 clones in TerraceDressing.WheatView (WheatSpot anchors tagged CropAura, AuraStar=5, Decorative=true; CropAura client script adds +30 distance penalty to Decorative so real crops keep aura priority; old script in backup CropAura_before_decorative). Crop template Stage5 models have Model scale ≈5 — use GetScale()*factor, never ScaleTo(factor). Rice mesh template kept in ServerStorage.TerraceAssets; its 12 old Soils + levees are in _Backup_20260925.FarmPlot22_left_soils. User calls this side "ฝั่งซ้าย"; right side (north, playable, stream) must stay unchanged.

Further left (z -176..-40, x 140..300, west of the trail at x≈312–336, north of the river at z≈-190): decorative CORN terraces (user swapped strawberry→corn), 8-stud rise, 78 beds / 1,189 Corn Stage5 clones (Model scale 4, ~10 studs tall, spacing 3.4) in TerraceDressing.CornView (CornSpot anchors, same 5-star Decorative aura tags). Plan in HillPlan2 / HillHeights2 (X0=132, Z0=-180); terrain backup Terrain_strawberry_site_before (PasteRegion at Vector3int16(32,-3,-48)).

FarmPlot22 = 20 parts all named "Soil" (≈1,712 slots, right side only), auto-packed rectangles on tread cells. Decor in workspace.TerraceDressing: Levees, Stream (4 FallSheet/FallLip/FallMist cascades at x 180/204/224/252, channel z 136–144, pond at x 132–148), PaddyHut (250,*,214), PaddyHut2 (220,*,10), TerraceSign (140,*,88).

Code: PlantingSystem.setupFarmPlot loops every child named "Soil"; PlantSlotGuide.resolveSoil returns the Soil actually aimed at. Soils must be axis-aligned; decor must not go inside a FarmPlot model.

Terrain gotchas: edits must be voxel-aligned or smooth terrain melts them; raycasts lag terrain edits (use Terrain:ReadVoxels to verify); FillBlock Water only fills empty space (clear to Air first).

**Why:** user chose option B (new zone, keep old plots) from a Thai rice-terrace photo, then asked to fill the whole hill + add a stream.
**How to apply:** backups in ServerStorage._Backup_20260925: Terrain_whole_hill_before (PasteRegion at Vector3int16(32,-3,-16)), HillHeights / HillPlan StringValues (cell grid X0=132,Z0=-60; plan cells "h:kind:L", kind t/b/x/s), removed foliage in TerraceSite_removed_foliage (OriginalParent attr). Water sound done: WaterfallSound (9120552671) on each FallMist, StreamSound (9119646672) on Stream.SoundAnchors; lotus ponds' archived 1730497309 swapped to 9119646409 (old id kept in OriginalSoundId attr). Not done yet: rice crop, level gate.

2026-10-03 (user, with an aerial screenshot of the terraces: "พืชในแปลงนาขั้นบันไดที่มีผลิตแสดงอยู่ อยากลบออกไปเลย"): the decorative crops were REMOVED from the game. TerraceDressing.WheatView (75 beds, 2,132 wheat, 13,167 parts) and TerraceDressing.CornView (78 beds, 1,189 corn, 8,713 parts) were moved (not destroyed) to ServerStorage._Backup_20261003_terrace_crops (attribute OriginalParent = Workspace.TerraceDressing). To undo: set their Parent back to workspace.TerraceDressing. Terrain beds, Levees, Stream, huts, sign and the real FarmPlot22 soils stay. Client part count in Play went to ~36k (was ~71k earlier). Verified: client CropAura tagged = 0 decorative anchors, FarmPlot22 present. Needs Publish. This makes the Decorative CropAura penalty code in CropAura unused (left in place).


---

## tester-accounts

CtrlZ_2 (UserId 11611605711, display XxLemoNxX) is a tester (user said 2026-10-17). Its CheatFlags_v1 entries (xp_lifetime L300 in 154 min, coin_rate 5.55M/10 min) are from testing.

**Why:** the user said not to investigate it further.
**How to apply:** don't treat this account as a cheater suspect in [[cheat-watch]] / [[ban-system]] reviews. Disconnect checks like [[server-crash-diagnosis]] are still fine when asked.


---

## trash-event

User request 2026-10-12: event where fishing gives more junk at a lake, otter can't keep up, announcement with the otter holding a trash picker, floating trash + an aura visible from the sky.

User decisions (2026-10-12):
- +30 percentage points flat for every rod (not x1.3).
- Location = the hill lake "ทะเลสาบหมอกเช้า" (same circle as HILL_LAKE in FishingSystem: centre 468,-201 r 66, water y 4), NOT the dock lake.
- Rounds at 12:00 / 18:00 / 21:00 / 00:00 Thai (the user corrected my proposed 12:30 to 12:00 on 2026-10-13; 30 min each since 2026-10-13); 00:00 was, added by the user later the same day (4 rounds a day; new rounds are appended to TIMES because the index is the clear-bonus key).
- Personal missions 10 / 25 / 50 junk = 2,000 / 5,000 / 12,000 coins, counted per Thai day; shards x1.5; server goal clears the floating trash, aura turns blue, helpers get 3,000; the junk bonus stays until time is up. Faster crafting (junk = craft materials, see [[craft-bench]]) was accepted by the user.

Build:
- `ReplicatedStorage.TrashEventConfig` (all numbers, `ENABLED`, `Schedule`, `InArea`, NPC position).
- `ServerScriptService.TrashEventService`: schedule loop, `workspace.TrashEvent` (Beacon = Persistent model, Floaters, OtterNpc) only while a round runs, BindableEvent child `JunkCaught` fired by FishingSystem, DataStore `TrashEvent_v1` {day, count, claimed, clear} (Studio key `studio:<userId>`), rewards reserved with UpdateAsync before paying.
- `StarterPlayerScripts.TrashEventGui`: card, pill at (12, 88), NPC billboard (client-made, in PlayerGui), bobbing for tag `TrashFloat`.
- `ReplicatedStorage.TrashEventAssets.OtterCleaner` / `Platform` (part-built net and sack on the pet otter mesh, scaled 2.2).
- Hooks: FishingSystem `rollFish(..., pos)` + `reportJunk`; `FishingConfig.PickJunk(r, valuableMult)`.
- Server goal = 20 x players who contributed in that round (I changed it from "players in the server" so quiet servers can finish).
- Studio switch: workspace attr `DevTrashEvent` = true / false, `DevTrashSeconds`.

Verified in Play 2026-10-12: round start, 40 floaters, card + pill, warp button, counting, milestones, clear bonus, one real forced TinCan catch counted. NOT verified: any 3D look (screen captures showed a white 3D view), the otter in the card viewport, real +30 rate, scheduled start, round end, mobile, gamepad, multiplayer.

Gotchas from this session:
- execute_luau times out when it does string work on the Source of big scripts (FishingSystem, InventorySystem); use script_read / script_grep instead.
- I started Play without checking [[live-session-overlap]] first. The Studio bag showed only 13 tools while PlayerInventory_v1 had 77 entries, and the otter fished the whole time. The saved bag was unchanged after stopping. Check for a live session BEFORE Play.

2026-10-12 later: the user's own Play connected to an external server (looked like Team Test: server datamodel unreachable from MCP, start_stop_play could not stop it, `DevTrashEvent` ignored because the server is not Studio). Added owner chat command `/trash [minutes]` / `/trash stop` in TrashEventService (this server only, works outside Studio); compiled, not tested by typing. `DevTrashEvent` was removed from workspace later that day (the user asked why the event started on every Play); use `/trash` to start a test round.

User feedback from their own test 2026-10-12 (they saw the card with the otter rendering fine, and the lake NPC): "ตอนเกิด event แค่ประกาศ พอ" — NO auto pop-up card at round start, only a HarvestNotify announcement (server `announceStart`, also 12 s after a mid-round join). The card opens only from the pill or the NPC prompt. Pill text was blurry because a UIStroke on a TextButton strokes the TEXT (Contextual): set `ApplyStrokeMode = Border` for border strokes on text buttons/labels.
Then the user asked for the start announcement to be "the otter comes out and then the text appears": TrashEventGui `Announce` banner (top centre, otter viewport pops in, speech bubble with typewriter text, 9 s, tap = open card); the server no longer sends a start HarvestNotify. Built 2026-10-12, compiled, not seen in Play by me.
Announcement sounds added 2026-10-12 (user request): splash when the otter pops, two-note ping when the bubble shows; built-in `rbxasset://sounds/...` files, group EffectSounds. No notification chime asset existed in the game to reuse. Not heard in Play by me.
2026-10-12 more user tweaks: bite speed +10% ONLY in the event lake during a round (`TrashEventConfig.BITE_BONUS/BITE_MULT`, applied in FishingSystem scheduleBite + scheduleHelperBite, stacks with rain); the pill must look like the rain pill (transparent, no border, white text with dark-blue TextStroke, size 14) and sits at y 92 under the rain pill (y 64). Compiled, bite time not measured in Play. Studio was reopened mid-session (new MCP studio id; work was intact) — call list_roblox_studios again when the id stops responding.

2026-10-12 late (user): "ไม่เอาแจกยกเซิฟแล้ว" → `CLEAR_BONUS = 0` (I read it as: no 3,000-coin server-goal bonus; floaters vanishing + blue aura on goal kept — confirm if they meant removing the server goal entirely). New permanent sign `workspace.TrashEventSign` (wooden board, SurfaceGui `Board.Face.Paper`, 3D `OtterFigure` on a `Shelf`, tag `TrashEventSign`; TrashEventGui fills texts from config + live status). The user moved it by hand to about (-78, 8, 73) facing -X — don't reposition it. Gotcha: a ViewportFrame inside a workspace SurfaceGui showed nothing, and parts inside it move with the model's PivotTo; use a real 3D figure. Edit-mode screen_capture worked again after Studio was reopened.

2026-10-13 (user: "ปรับระยะเวลาอีเวนขยะ เป็น 30 นาที ไม่จำกัดขยะแล้วกัน"): `DURATION = 30 * 60`; `GOAL_ENABLED = false` (my reading of "unlimited trash": no server goal, the 40 floaters stay the whole round, no cleared state / blue aura; UI shows only the total collected). Set `GOAL_ENABLED = true` to get the old goal back. Compiled, not play-tested.


---

## tutorial

Built 2026-09-28 at the user's request ("ระบบแนะนำผู้เล่นตอนเข้ามาเล่นครั้งแรก สอนซื้อของ ปลูก เก็บ และ ตกปลา"). I added a sell step; there are 5 steps.

Server ServerScriptService.TutorialService:
- DataStore "Tutorial_v1" {step, done, rewarded}. Player attr TutorialStep (0 = none, 1..5).
- RemoteFunction TutorialRequest: advance(step) only if it equals the current step; skip; restart.
- Reward: 1,000 coins once, after step 5.
- New record + (level >= 5 or coins >= 5,000, checked 6 s after leaderstats appear) = auto-done. This keeps existing players from seeing it; the level loads late, so the delay is needed.

Client StarterPlayerScripts.TutorialGui:
- Welcome popup with "เริ่มเลย!" / "ข้ามบทเรียน", a gold quest card at the top (0.5,0,0,84) with a skip button, and a finish popup with tips.
- Guidance: a gold curved Beam from HRP attachment "TutorialAttach" to a local TutorialTarget part, plus a bouncing ⬇️ billboard with a label.
- ❓ HelpButton in the top-right row at (1,-276,0,34) replays the tutorial.
- Step detection every 0.5 s, compared with baselines taken at step start:
  1. Seed count up (target: workspace.Shops.Shop).
  2. PlantCount attr up (target: nearest point on the nearest FarmPlots Soil).
  3. Produce count up (target: nearest PlantSlot with OwnerUserId = me via GetPartBoundsInRadius 40; label "⏳ กำลังโต..." -> "✅ โตแล้ว! กด E เก็บ" when its ProximityPrompt is enabled).
  4. Produce down + coins up, or no produce at the start (target: shop).
  5. FishingState "caught" (target: nearest terrain water by ring raycasts, fallback RestSpots.LakeDock).

Tested: auto-skip for the level-76 test account, the ❓ restart, the welcome popup, and steps 1-4 simulated. The user played along live (planted the test seed, then finished step 5 and got the 1,000 coins).

Fixes 2026-09-28:
- The start button moves left (0.5,-150) when the skip button shows, and is centered otherwise.
- Marker: a client-created BillboardGui must be parented to PlayerGui with Adornee set (under a workspace part it doesn't render).
- AlwaysOnTop = true made the billboard NOT render at all in this game (tested with plain Frames; with AlwaysOnTop = false it shows). So the marker is occluded by props, but visible.
- The arrow is the text "▼" (gold with stroke) because emoji ⬇️ didn't show.
- The shop target is the ground below workspace.Shops.Shop (a raycast), because that part sits at roof height.
- The user's record is restored to done via skip; rewarded stays true.

Related: [[fishing-plan]] (the starter rod is given on join, so step 5 always has a rod).

Resume + ❓ change 2026-09-30 (user: "ทำครบแล้วหายไป มีเควสใหม่ค่อยแสดงและทำต่อจากเดิม"):
- Tutorial_v1 gains `completed` (steps finished or skipped).
  - Legacy done records count as LEGACY_DONE_STEPS = 10 (never change this).
  - Skip and veteran auto-done set completed = LAST_STEP.
- On load, done and completed < LAST_STEP means the player continues at completed + 1, and the server sets player attr TutorialNewQuests, which shows the "✨ มีภารกิจใหม่!" popup.
- To add quests: append to STEPS in BOTH scripts and raise LAST_STEP.
- The ❓ HelpButton is visible only while TutorialStep is 1..LAST.
  - Clicking it toggles questHidden (hides the card + guide), instead of restarting from step 1.
  - VipGui's 👑 moves from -328 to -276 when TutorialStep is 0.
- Mobile (viewport Y < 500): the quest card is scaled 0.7 and sits under CurrencyGui.StatusPanel. (2026-10-24: card moved to the RIGHT on all screens, anchor (1,0) at (1,-12,0,84), compact 0.7 at (1,-12,0,62); statusPanelSpot removed.)
- gui.DisplayOrder drops to 1 while an opaque window of 260x200 or larger overlaps the card (TouchGui is skipped).
- Fixed: `beam.TextureOffset` (not a Beam property) errored every frame.
- Backups: _Backup_20260930.TutorialService_before_resume / TutorialGui_before_resume / _before_mobilefit.

Expanded to 8 steps 2026-09-29 (after pets became pet-food-only): buy, plant, harvest, sell, foodInsert, foodCollect, feed, fish.
- Client STEPS entries now have an `id`; detection and targets switch on id.
  - foodInsert: PetFoodQueue or PetFoodReady attr increased; target = PetFoodMachine bounding-box bottom.
  - foodCollect: pet food count up; label switches "⏳ เครื่องกำลังทำ..." -> "✅ เสร็จแล้ว! กด E รับอาหาร" by PetFoodReady.
  - feed: pet food count down; target = nearest own pet.
- Server TutorialService: LAST_STEP 8. onEnterStep(player, step) runs on advance, restart, and 15 s after join if mid-tutorial.
  - Step 5: if no produce stack has >= 2, gives 2 Wheat ★1 (+ notify).
  - Step 7: if all active pets are >= 95% hunger, sets the first to 85 so the F prompt appears.
- Tested steps 5 -> 8 with simulated queue/collect, a real feed, and the hunger bump; the user's data was restored (hungers, food, coins, tutorial done).

Expanded to 10 steps 2026-09-29: +gachaBuy (9), +gachaRoll (10), targets = GachaMachine bounding-box bottom.
- Free first Normal ticket:
  - Entering step 9, TutorialService sets player attr FreeNormalTicket if the record's freeTicketUsed is false.
  - GachaService.buyWithCoins charges 0 for Normal x1 while the attr is set; it restores the attr on a save failure.
  - On success it sets FreeTicketClaimed, which TutorialService saves as freeTicketUsed (Tutorial_v1). Skip clears the attr.
  - GachaGui buy1 shows "1 ใบ\n✨ ฟรี!".
- Detection: GachaTickets_Normal attr up (buy) / down (roll).
- Before the finish popup: waits for GachaRevealing to end + 3 s, then closes GachaGui (the popup was overlapping).
- 🎁 renders as a red "T" in this game; use ✨.
- Test: the free buy worked for real (coins unchanged, tickets 4 -> 5); the roll was simulated. Restored GachaTickets_v1 Normal to 4 and Tutorial_v1 freeTicketUsed cleared.

2026-10-01: the CurrencyGui StatusPanel (coins/level/luck) now sits bottom-left on phones too, same as PC, at the user's request.
- The IS_MOBILE branch in updatePanelPosition was removed. The user then wanted it (and approved the result on 2026-10-01) flush in the bottom-left corner (16 px margin) on every device, NOT lifted above the thumbstick. LIFT_ABOVE_THUMBSTICK = false (set true to bring the lift back).
- Phones still start collapsed.
- TutorialGui compact card (short screens): if the panel bottom is in the lower half of the screen, the card goes top-left at (12, 62) instead of under the panel.
- The Studio emulator reports MouseEnabled = true, so it never takes the IS_MOBILE path. It verified the touch path: panel bottom 234 < thumbstick top 241 on 801x392.
- Backups *_before_mobilebottomleft.

New-player welcome gift (2026-10-02, user: "ตอนเข้ามาครั้งแรก แจกเหรียญ 100000 เบ็ดไม้ไผ่เหมือนเดิม หุ่นทองคำนำโชค 1 อัน"):
- ServerScriptService.StarterGift (new Script): waits for CoinsLoaded + InventoryLoaded, requires player attr IsNewPlayer, claims DataStore "StarterGift_v1" {given} with UpdateAsync BEFORE giving, then +100,000 coins, ItemFactory.GiveBoosterTool(player, 1, "x100"), saves the coins at once (PlayerCoins_v1 SetAsync), and after 6 s sends a HarvestNotify "🎁 ของขวัญต้อนรับ! …". The bamboo rod is NOT given here: FishingShop.giveStarterRod already does it on every new join (unchanged).
- New player = LeaderstatsSetup sets attr IsNewPlayer when the coin load SUCCEEDED but returned nil (no record). Existing players never get it. A player who joined before this existed and never saved would count as new (very unlikely).
- TutorialService: the veteran auto-skip rule (coins >= 5,000, 6 s after join) now subtracts the attr StarterGiftCoins, which StarterGift sets before adding the coins, so a new player still gets the tutorial. Level >= SKIP_LEVEL still skips.
- Studio test hook: workspace attribute DevStarterGiftTest = true (set it in Edit mode, remove it afterwards) pretends the player is new and uses the key "test_<userId>" without touching the real key or saving coins. Tested: +100,000 coins, 1 x100 booster, test key set, real key untouched, then reverted (coins -100,000, booster removed, key removed); a normal Play without the hook gave nothing.
- Backups _Backup_20261001.LeaderstatsSetup/TutorialService_before_newplayer. Needs Publish. Not tested with a real brand-new account.

Veteran gift (2026-10-02, user: "อยากให้ผู้เล่นเก่าก็ได้นะ 10000"): StarterGift now also gives EXISTING players (IsNewPlayer ~= true) a one-time 💰 10,000 coins (no booster, no rod) with the message "🎁 ขอบคุณที่เล่นกับเรา! …". StarterGift_v1 record: {given = true} for new players, {veteran = true} for existing ones; anyone with either field gets nothing more (a new player never also gets the 10k). It also sets StarterGiftCoins (10,000) so the tutorial's coin>=5,000 veteran rule can't be tripped by the gift.
- IMPORTANT: StarterGift does NOTHING in Studio unless the test hook is set (so the developer account's one-time claim isn't eaten by Studio Plays; it is paid on the first LIVE join after Publish). Hook: workspace attribute DevStarterGiftTest = "new" or "veteran" (Edit mode, remove afterwards; uses the key test_<userId>, doesn't save coins).
- Tested with "veteran": +10,000 coins, no booster, test key {veteran=true}, real key untouched, then reverted. The 2026-10-02 user message before this one ("เควสสำหรับผู้เล่นใหม่ตอนกดข้าม…") was ambiguous; I asked which of 3 readings and the user answered only with the veteran request, so the tutorial skip/reward behaviour is UNCHANGED (skip pays nothing; the 1,000 tutorial reward only on completing all 10 steps). Backup _Backup_20261001.StarterGift_before_veteran. Needs Publish.

EVERYONE gets the welcome gift (2026-10-02, user: "อยากให้ทุกคนได้ไม่ว่าใหม่หรือเก่า"; supersedes the new/veteran split above): StarterGift gives every account, new or old, once: 💰 100,000 coins + 🍀 1 golden luck scarecrow (x100) (+ the bamboo rod that FishingShop.giveStarterRod already gives). The 10,000 veteran tier was removed. Auto-grant on the first live join after Publish; message "🎁 ของขวัญสำหรับคุณ! …". One record per user in StarterGift_v1 ({given = true}; an old {veteran = true} record also blocks it). It was built as an automatic grant, not a "claim" button (the wording "ให้มีของขวัญให้รับ" could also mean a button: ask if they want one). IsNewPlayer is still set by LeaderstatsSetup but no longer used here. StarterGiftCoins (100,000) still keeps the tutorial's coin>=5,000 veteran rule from skipping the tutorial. Studio rule unchanged: nothing is granted in Studio without workspace attr DevStarterGiftTest = true (test key). Tested (existing account): +100,000, 1 booster, real key untouched, reverted. Backup _Backup_20261001.StarterGift_before_everyone. Needs Publish.

⚠️ BUG I CAUSED + FIXED (2026-10-02): my edit for the welcome gift put a `-- comment` in the MIDDLE of the veteran `if` line in TutorialService (`... >= 5000) -- comment then`), which swallowed the `then` → the whole TutorialService script failed to COMPILE ("Expected 'then' when parsing if statement") → no tutorial at all for anyone in that build (the user reported "ช่วยสอนหายไป"). Fixed by moving the comment to its own line (backup _Backup_20261001.TutorialService_before_syntaxfix holds the broken version). LESSON: never put `--` comments inside an edited condition line; after EVERY script edit run a compile check over all scripts: `for each LuaSourceContainer: loadstring(s.Source)` (works in execute_luau Edit mode; 115 scripts all compile now). The edit helper I use should call loadstring on the new source BEFORE writing it (I do this now).

Skip pays + restart (2026-10-02, user: "กดข้ามแล้วยังได้เงินอยู่ / ผู้เล่นเก่าที่เคยกดข้าม ให้กลับทำให้ครบได้"):
- TutorialService "skip": if not rewarded → rewarded = true + 1,000 coins (+ HarvestNotify "🎁 รางวัลบทเรียน 💰 1000 เหรียญ"), saved BEFORE paying and reverted if the save fails; response {ok, step = 0, reward}. Once per account (the flag is shared with completing all 10 steps, so a restart + skip/finish never pays twice).
- Player attr TutorialRewarded (set in publish). The welcome popup text adds "(กดข้ามก็รับเหรียญเช่นกัน)".
- Restart for old skippers: the More menu (☰) has a 📘 entry (MoreMenuGui ENTRIES id "tutorial" → TutorialGui BindableEvent OpenTutorial). Text by state: in progress "ซ่อน/แสดงภารกิจ" (toggles the card like ❓), done and TutorialRewarded == false "ทำบทเรียน · รับ 1,000", done and rewarded "เรียนวิธีเล่นอีกครั้ง". When done/skipped it calls TutorialRequest("restart") (step 1, shows the welcome popup again if not shown this session). Old skippers/veterans have rewarded = false, so finishing all 10 steps (or skipping again) pays them the 1,000 once. The MoreMenu panel is now 250 wide.
- Tested with the user's record temporarily set to rewarded=false: entry text "ทำบทเรียน · รับ 1,000", restart → step 1 + welcome popup, skip → +1,000 and rewarded=true, a second restart+skip → +0. The record and coins were restored (snapshot) and the temp snapshot removed. Needs Publish.

TUTORIAL v2 (2026-10-18, user approved a plan from stats; SUPERSEDES the step lists above): 8 core steps plant, harvest, sell, buy, fish, gachaBuy, gachaRoll, petUse (reward 1,000 + new-player booster when step 8 completes, `coreDone` in the advance response → reward popup), then 3 bonus steps foodInsert, foodCollect, feed (LAST_STEP 11, CORE_LAST 8 in BOTH scripts). Step 1 gives 5 Wheat seeds once (record `starterSeedsGiven`). No welcome popup. Records have `v = 2`; old unfinished records restart at step 1. `times` = unix time per completed step + `start`, `skip`, `skipAt` (for future drop-off stats). New players (attr IsNewPlayer) start immediately. GachaService signals the roll at TutorialStep == 7. ReplicatedStorage.TutorialGate.Wait(player) holds LoginAnnouncementGui/CompensationGui while TutorialStep is 1..3. Guide is eye-level: beam from chest (attach Y +1.2) to target +3 studs, plus a neon 3D chevron arrow (Model under CurrentCamera) above head height in front of the player with "label · N ม." billboard, hidden within 9 studs. Gotcha: on an account with planting pets the plant step completes by itself (PlantActionCount counts pet planting). Stats baseline (343 new players since 10-08): 42 finished, 129 skipped at step 1, 52 left stuck at step 1 within ~1 min. Raised-arrow tweak not seen in Play; not tested with a real new account or phone. Backups _Backup_20261018.*_before_tutorialv2. Needs Publish. Fish step target is FIXED (user picked it): TUTORIAL_FISH_SPOT (86, 4, -124) = brick plaza edge behind the seed shop / pet food machine, water at x >= 89 (falls back to nearest water if that stops being water).

2026-10-23: tutorial reward raised 1,000 → 100,000 coins at the user's request (TutorialService REWARD_COINS, TutorialGui REWARD_TEXT, MoreMenuGui label). Skip still pays it (once per account), so any account with rewarded = false can get 100k via ☰ → 📘 restart → skip. Not published.

2026-10-22: bonus step 12 "chicken" (visit the chicken coop) appended after feed — LAST_STEP 12 in BOTH scripts; done = any ChickenGui window opened, auto-passes when ChickenConfig.Enabled is false; arrow target = ReplicatedStorage attr ChickenShopPos (set by ChickenService). Not play-tested.

2026-10-13 audit after the island rebuild ([[island-rebuild-plan]]): the tutorial now has 12 steps (buy, plant, harvest, sell, foodInsert, foodCollect, petIntro, fish, gachaBuy, gachaRoll, petUse, feed). All targets are found by instance name, so they survived the rebuild. Two fixes in TutorialGui (backup `TutorialGui_before_newmap`): `nearestSoil` now aims at the soil edge beside the nearest `workspace.FarmBridges` part of that plot (plots are moat islands; the straight beam used to cross 12 studs of water), and `tutorialFishingWater` uses the water nearest the PLAYER instead of FarmPlot3 (was ~160 studs away); step text says "ริมน้ำใกล้ๆ". Checked by re-running the same math in Edit; the 12 steps were NOT played through (a restart rewrites the user's Tutorial_v1 record — snapshot/restore first if asked). I now run the all-scripts loadstring compile check after script edits (196 scripts, 0 errors that day).

AUTO + guide buttons (2026-10-24, user approved phases 1+2 of a plan; Studio only, not published, AUTO not yet seen working in Play): TutorialGui card is 124 high with 🧭 NavButton + ▶ AutoButton (and a full-card CardTap = guide). Section "นำทาง + AUTO" (before onStepChanged): walkTo = PathfindingService (Water cost 100) + Humanoid:MoveTo per waypoint, jump when stuck, 3 tries then PivotTo the goal (also when > WARP_DISTANCE 180); stops when ControlModule:GetMoveVector() > 0.2. MoveTo works on the local character with the default controls still enabled (tested). AUTO per step id: plant = PlantByClick on up to 5 free slots (taken = Soil children named PlantSlot<index>, index = ComputeSlotOffsets order), harvest = crop ProximityPrompt InputHoldBegin/End, fish = face water + re-equip rod (FishingClient auto-casts on equip), GUI steps = press the prompt shown near the goal (ProximityPromptService.PromptShown) unless a big window is already open; petUse nothing, feed walk only. autoRunId stops older AUTO loops; actionBusy makes the next step wait for planting. Plan phases 3 (highlight/auto-press GUI buttons) and 4 (bigger AUTO on step 1, autoUsed stats) not done. Gotcha: the developer account's Tutorial_v1 is NOT done (was step 1 after a ☰ restart) so Play tests really advance and save it.
AUTO test results 2026-10-24: plant (walk ~90 studs + 5 plants) and sell (walk + ShopGui opened) work in Play. Gotchas found: (1) `ProximityPrompt:InputHoldBegin()` only works on the prompt Roblox is currently SHOWING (one per key), so AUTO harvest stands on the crop and presses `shownPrompt` if it's ours; (2) PlantSlot anchors are CanQuery = false, so GetPartBoundsInRadius never finds crops; findMyCrop now scans Soil children; (3) the developer account's pets plant the test seeds and harvest the crops before AUTO does, which hides AUTO results (use a pet-less test or watch ProximityPromptService.PromptTriggered); (4) Studio Play often hangs on "Start play hasn't finished yet" after a Stop; reopening Studio clears it. Harvest fix, fish, gacha and phone NOT yet tested.
AUTO sell/buy 2026-10-24 (user asked AUTO to actually sell): autoShop fires SellCrop for every non-starred Wheat produce stack (else 1 other produce) and BuySeed("Wheat", 5), then hides ShopGui.Frame (ShopGui closeShop only does Frame.Visible = false). Play-tested sell -> buy -> fish (caught in 5 s) in one run; a shop window left open blocks the next GUI step because bigWindowOpen() skips pressing the prompt.
AUTO gacha 2026-10-24: GachaGui has BindableEvent GachaGui.TutorialAuto ("buy1" = buyTickets(1) on the Normal tab, "roll1" = doRequest("roll", 1)); TutorialGui autoGacha fires it at steps 6/7 and refires only if Normal tickets did not change in 8 s (max 3). Free first ticket comes from FreeNormalTicket as before; otherwise it pays 20,000 coins. Play-tested both paid and free paths. AUTO waits while the TutorialGui popup (e.g. core-done) is visible; on the dev account step 8 petUse passes at once because pets already exist.

TUTORIAL DISABLED 2026-10-27 (user: "ปรับยกเลิกระบบสอนบทเรียนใหม่ ที่เกียวข้องทั้งหมด"; this replaces everything above as the live behaviour). Nothing was deleted and Tutorial_v1 was not touched.
- TutorialService + TutorialGui: Enabled = false (the first-line comment says how to re-enable). TutorialStep is no longer set, so there is no reward, no free first gacha ticket and no TutorialRequest remote.
- TutorialGate.ENABLED = false, so Wait() returns at once. IMPORTANT: without this, LoginAnnouncementGui / CompensationGui / SlowDeviceHint wait 25 s for a TutorialStep that never comes.
- MoreMenuGui: the 📘 entry is commented out (updateTutorialEntry does nothing without its label).
- StarterGift: new players (IsNewPlayer) get 5 Wheat seeds (giveStarterSeeds, merged into an existing wheat seed stack) and the x100 booster at once (the booster used to wait for tutorial completion). The new-player message is Thai/English via Localization.Pick.
- Leftovers that do nothing now and are safe: GachaService TutorialStep==7 signal + FreeNormalTicket path, GachaGui TutorialAuto, VipGui (TutorialStep or 0), ChickenYardClient step-15 check.
- To re-enable: Enabled = true on both scripts, TutorialGate.ENABLED = true, restore the MoreMenuGui ENTRIES line. Also decide about StarterGift: TutorialService still gives 5 seeds at step 1 (once per account, starterSeedsGiven), so a new player would get 10, and the booster would come twice.
- Backups ServerStorage._Backup_20261027.*_before_tutorialoff. Play-tested: no tutorial UI, the gate returns at once, the menu is fine, no errors. The StarterGift seed path was not tested with a real new account. Not published.


---

## typing-indicator

User request 2026-10-03: other players should see that a name is typing in chat.

- Client `StarterPlayerScripts.TypingReporter` (LocalScript): watches `TextChatService.ChatInputBarConfiguration.IsFocused` + `.TextBox` (rebinds when TextBox changes). Typing = focused AND (TextBox nil OR text non-empty). Fires RemoteEvent `ReplicatedStorage.RemoteEvents.ReportTyping` (true/false), re-sends true every 8 s while typing.
- Server `PlayerNameTags`: creates the remote, sets player attr `IsTyping` (throttle 0.2 s, boolean only, auto-clear after 20 s without a refresh), tag row `Typing` (LayoutOrder 0, top of the billboard, text "กำลังพิมพ์..." pale yellow) toggled by updateTag. Text is Thai only (tag is shared by everyone, like the VIP texts).
- Verified in Studio: scripts compile, attr -> tag row visible/hidden, no console errors. NOT verified: the real chat bar (in the Studio test the chat UI is not rendered: ChatInputBarConfiguration.TextBox stays nil, IsFocused false) and the client->server remote (Studio sandbox blocks firing it from execute_luau). Needs a live test with 2 players.
- Backup: StringValue `_Backup_20261003.PlayerNameTags_before_typing` in ServerStorage. Needs Publish.
- Same day: I wrongly "removed crop models" (PlantingSystem SHOW_CROP_MODELS) after the user's FPS/MicroProfiler message, user said "ไม่ใช่", reverted fully. The FPS/crop request is STILL UNCLEAR (maybe only the pink Highlight glow of 4-5★ plants, CropAuraConfig.MaxGlows/GlowTag) — ask before touching crops again. See [[planting-click-and-perf]].


---

## uiscale-canvas-gotcha

When a ScrollingFrame sits inside a panel with a `UIScale` (most windows here shrink on small screens), `UIListLayout.AbsoluteContentSize` is in screen pixels AFTER scaling, while `CanvasSize` offsets are in units BEFORE scaling. Setting `CanvasSize = AbsoluteContentSize.Y + pad` makes the canvas too short by the scale factor.

**Why:** user report 2026-10-12 — on a phone the Music Box list could not scroll to the last songs. Measured in the user's Play session: viewport 749x381, panel scale 0.593, 26 rows, canvas 714 but 1,200 needed. `AutomaticCanvasSize` has the same problem under UIScale (the pet-menu fish book hit it on 2026-10-11 and was "fixed" with the same wrong formula).

**How to apply:** use `math.ceil(layout.AbsoluteContentSize.Y / uiScale.Scale) + pad` and recompute on both `AbsoluteContentSize` and `UIScale.Scale` changes. Fixed in `BoomboxBackClient.updatePlaylistCanvas` and `PetHelperToggleButton.syncBookCanvas` (not play-tested after the fix, not published). Other windows using `AutomaticCanvasSize = Y` under a UIScale (shop, bag, fish book, gacha…) may have the same issue with long lists — check on a small viewport when a "can't scroll to the bottom" report comes in. Related: [[boombox-gift]], [[gamepad-ui]].


---

## vip-title-system

User decisions (2026-09-29): VIP = one Game Pass at 199 R$. It gives a custom overhead title (editable; emoji allowed; 20 chars, Thai vowel/tone marks not counted), 9 title colours including animated rainbow, a crown 👑 + gold name, and a [VIP] chat tag.

Built:
- ReplicatedStorage.VipConfig: GAMEPASS_ID, COLORS, RAINBOW, CountChars, Clean.
- ServerScriptService.VipService: DataStore "VipTitle_v1" {title raw, color, show}. Every display goes through the TextService filter (GetNonChatStringForBroadcastAsync); on join it re-filters. 10 s edit cooldown. RemoteFunction RemoteEvents.VipRequest (info/save). Player attrs IsVip / VipTitle (filtered) / VipTitleColor. Studio-only test: set player attr DevGrantVip = true from the server.
- PlayerNameTags: BillboardGui 240x100 with SizeOffset (0, 0.5) and StudsOffset 1.9 (bottom-anchored), UIListLayout rows Icons / VipBadge (✨👑 VIP✨, FredokaOne PINK gradient 255,228,242→255,125,190→232,62,145, stroke 125,20,75; changed from gold at the user's request) / PlayerName (gold for VIP) / Title (plain text under the name). The user asked for this layout from a reference image on 2026-09-29; the first version (title pill above the name) was replaced. The rainbow is a UIGradient tagged "VipRainbow"; it is animated client-side.
- StarterPlayerScripts.VipGui: 👑 button at (1, -328) in the top-right row (spacing 52), window with a sell page and an edit page (live preview, counter, swatches, show toggle, save), gamepad (SelectionGroup, B closes), TextChatService.OnIncomingMessage for [VIP] (the only chat hook in the game).
- Icon: scratchpad vip_icon.svg → PNG via headless Edge.

Pass created 2026-09-29: ID 2001938429, name "บัตร vip". It is 10 R$ on the Dashboard ON PURPOSE (user, 2026-10-01: lowered to 10 to attract players; the original plan was 199). Don't flag it again. VipConfig.PRICE_HINT (fallback text) is now 10; the live price comes from GetProductInfo. The creator account owns it (verified: IsVip = true in Play). The buy button shows the live price from GetProductInfo. Related: [[pet-auto-feed-plan]].

Gifted VIP 2026-09-30: VipService has a server-side GIFTED_VIP = { [userId] = "name" } table; listed users are granted VIP in onPlayerAdded (same grant() as the pass/Sultan). First entry: 11646315279 a_valinnn (user request); 2026-10-14 added 11611605711 CtrlZ_2 (tester; also given live right away via a VipGift_v1 `to_11611605711` record, fromName "ทีมงาน" — remove both to revoke). Takes effect in the live game only after the user publishes.

VIP card in QuickShop / "ร้านสุดพิเศษ" (2026-10-01):
- PlantLimitGui VipCard: cloned from feederCard, LayoutOrder 2, right of SultanCard; the other cards shifted +1.
- Pink style. Desc counts the non-sultan colours from VipConfig.
- Not owned: price from GetProductInfo(GamePass); the button calls PromptGamePassPurchase.
- Owned (IsVip or IsSultan): "มีแล้ว ✓", and the button fires VipGui's new BindableEvent "OpenVip" to open the title editor.
- Tested: activating the selected button with Return closes the shop and opens VipWindow on the EditPage.
- Backups *_before_vipcard.

Gotcha: user_mouse_input with an instance_path or x/y is off by the 58 px topbar inset for DeviceSafeInsets GUIs, so clicks land on the wrong buttons. For GUI tests, set GuiService.SelectedObject and use user_keyboard_input keyPress key_code "Return".

Wording 2026-10-01: the user asked for "สถานะ" instead of "ฉายา" everywhere the player can see it.
- All occurrences were replaced in VipGui (18), SultanShopGui (2), PlantLimitGui (3) and VipService messages (6). Backups *_before_status.
- VipConfig and PlayerNameTags only have it in comments, so they are unchanged.
- New UI text must use "สถานะ".
- The VIP sell page colour count now excludes the 2 sultan-only colours (shows 9).

Fully-filtered status (2026-10-02): the user's status "ผู้ทดสอบหมายเลข0" showed as "##############" on the LIVE game.
- Cause: Roblox's broadcast text filter blocked the whole string, likely because of the digit. Studio never filters, so it looked fine there. It can't and must not be bypassed.
- VipService now has fullyBlocked(text) (only # and spaces):
  - publish() sets VipTitle "" (no label) and notifies the owner once (BLOCKED_MESSAGE, after 8 s).
  - save() rejects a fully-blocked text with a message.
- Partially filtered text still shows with ###.
- Not testable in Studio (no filtering). Backup _Backup_20261001.VipService_before_blockedtitle.

VIP gift (2026-10-01, user: "ส่งของขวัญให้เพื่อน ... เริ่มจาก vip ก่อน"; Sultan and other items not done yet):
- Roblox can't buy a Game Pass for someone else, so the gift is a Developer Product: VipConfig.GIFT_PRODUCT_ID = 3715821322 (the user's "ของขวัญ VIP"). The Dashboard price is 10 R$, same as the pass (the user keeps both at 10 on purpose). If the VIP price changes, change the pass and this product together.
- Flow (VipService "ของขวัญ VIP" section, RemoteFunction VipRequest action "giftSelect", targetUserId): the target must be in the same server and not VIP/Sultan. It saves `pending_<buyerId>` {to,toName} in DataStore "VipGift_v1" and calls PromptProductPurchase. PurchaseRouter.Register(GIFT_PRODUCT_ID, grantGift) then writes `to_<targetId>` {from, fromName, t, receipt, seen} and, if the target is online, calls grant() + notifies both. Roblox retries the receipt if the save fails (NotProcessedYet); a closed prompt clears the pending state (PromptProductPurchaseFinished).
- Recipient: checkGift runs at join (st.owned = true if a `to_` record exists, so VIP survives rejoin); announceGift notifies once after 8 s if seen = false and sets seen = true. VIP gifted offline is not possible in the UI (the target is chosen from the server list); the code handles a buyer reconnecting after paying.
- VipGui: "🎁 ส่ง VIP ให้เพื่อน" button on the sell page and the edit page, plus a GiftPage (list of players, 2-step confirm "ยืนยัน ✔" within 5 s, "มี VIP แล้ว ✓" rows, gamepad selection, B = back). BindableEvent OpenVipGift opens it. PlantLimitGui VipCard has a small pink "🎁 ส่งให้เพื่อน" pill under the price button (buy button moved up). VipWindow scale now fits the real window height (the Sultan edit page + gift button is ~600 px tall at scale 1).
- Studio test hooks (server player attrs): DevGiftSimulate = true (simulate payment instead of PromptProductPurchase; also automatic when the product id is 0), DevGiftOffline = true (allow a fake userId target), client attr DevGiftFakeFriends = true (3 fake rows in the list). Verified: validation, simulated grant, record saved/pending cleared, second gift right after, recipient join path (seen flag), page rows + confirm flow, QuickShop card. Test records were removed from VipGift_v1.
- NOT verified (needs a live second player + real Robux): the real purchase prompt, a real friend receiving it in the same server.
- Backups _Backup_20261001.VipConfig/VipService/VipGui/PlantLimitGui_before_vipgift. Needs Publish. Sultan/other gifts would need their own products and the same pattern.

**OPEN: the VIP gift is NOT confirmed on the live game** (user, 2026-10-01: "ยังไม่ได้ทดสอบจริง จำให้ที"). Studio tests passed, but the real Robux prompt and a real friend receiving it have never been tried. Treat it as untested: don't call it done, and ask the user for the result after they publish and try it with a second player. If a report comes in, check the log lines "VipService:" / "PurchaseRouter:" and the VipGift_v1 keys `to_<id>` / `pending_<id>`. Don't build Sultan/other gifts until this is confirmed.

2026-10-01: the QuickShop VIP card gift pill (PlantLimitGui GiftVipButton) is now ONLY the 🎁 icon (no text), TextSize 22, 84x26 under the price button (user: "ไม่เอาข้อความ เอาแค่ icon กล่องของขวัญใหญ่ขึ้น"). The VipGui sell/edit-page gift buttons still say "🎁 ส่ง VIP ให้เพื่อน" (not asked to change).

VIP no longer shows the crown (2026-10-02, user: "ปรับ vip ไม่แสดง icon มงกุฎแล้ว"):
- The overhead badge "✨👑 VIP✨" is now "✨ VIP ✨" for VIP-only players. The crown part (PlayerNameTags badge part named "Crown", and the VipGui preview crownPart) is shown ONLY for Sultans (updateTag: Crown.Visible = isSultan; the preview toggles it in setSultan).
- Texts changed: the VIP sell-page perk "👑 มงกุฎ + ชื่อสีทองเหนือหัว" → "✨ ป้าย VIP + ชื่อสีทองเหนือหัว"; the QuickShop VIP card desc lost "มงกุฎ".
- NOT changed (I read the request as the overhead badge; ask if they meant more): the 👑 button in the top-right row, the 👑 in the VIP window title / buy button / QuickShop card title, the sultan colour lock crowns, the Sultan badge/chat tag. VipConfig.CROWN is still used by those.
- Verified in Play with a cloned tag (VIP look without the crown next to the real Sultan tag with the crown). Backups _Backup_20261001.PlayerNameTags/VipGui/PlantLimitGui_before_nocrownvip. Needs Publish.

VIP has NO icons anywhere (2026-10-02, user: "อยากให้เหลือแค่ vip ไม่ต้องมี icon แล้วทุกที่"; supersedes the previous crown-only note above):
- Overhead badge: VIP-only = just "VIP" (gradient text). The sparkles (SparkleL/SparkleR) and the crown (Crown) show only for Sultans (PlayerNameTags.updateTag; VipGui preview setSultan).
- The top-right button is now the TEXT "VIP" (GothamBlack 15) instead of 👑 (same button for Sultans). VIP window header "VIP" (owned: "สถานะ VIP ของฉัน", Sultan keeps "👑 สถานะสุลต่านของฉัน"), buy button "ซื้อ VIP R$ …", the 4 perk lines have no emoji bullets, QuickShop VipCard icon box = the text "VIP" and title "VIP".
- VipService messages: the welcome notice and the gift notices say "ปุ่ม VIP" (no 👑). The BLOCKED_MESSAGE has no emoji and gets "⚠️" automatically.
- HarvestNotifyGui.withWarnIcon: a message that starts with U+200B (zero-width space) skips the automatic "⚠️ " (it strips the 3 bytes). Use `"\u{200B}…"` for a happy/neutral plain-text notice that must not show a warning icon.
- Kept on purpose: 🎁 gift buttons/messages (gift icon), the Sultan crown/sparkles/tag/pack, VipConfig.CROWN (Sultan uses it).
- Verified in Play: the real top button shows "VIP", a cloned VIP tag shows plain "VIP" beside the Sultan tag with the crown, the welcome notice has no ⚠️ and a normal warning does. Backups _Backup_20261001.PlayerNameTags/VipGui/PlantLimitGui/VipService/HarvestNotifyGui_before_novipicons. Needs Publish.

2026-10-02 REVERT of one spot (user: "ตรงอยากปรับให้กลับมาเหมือนเดิม" after seeing the "VIP" text button): the top-right VIP button (VipGui openButton / crownIcon label) is the crown 👑 again (Config.CROWN, size 24). Everything else from "VIP has NO icons anywhere" stays as it was (overhead badge text only, window titles, buy button, QuickShop VipCard, perk lines, notices). Don't turn the button into text again unless asked.

Gift windows stack ON TOP of the shop (2026-10-02, user: "ส่งของขวัญทุกอันเปิดซ้อนหน้าต่างมาอีกได้เลย และยังแสดงร้านค้าสุดพิเศษอยู่ไม่ต้องปิด"):
- The 🎁 pills on the 6 QuickShop cards (PlantLimitGui: VIP, pet slot, Sultan, auto-feeder, quota, golden scarecrow) no longer call setPanelOpen(false); the Sultan pack window (SultanShopGui GiftSultan) no longer calls close(); the AutoFeederGui sell-page 🎁 no longer hides the bowl window. The shop stays open under the gift window.
- VipGui DisplayOrder 7 → 11 (above QuickShop 8, Sultan pack 9, seed shop 10) so the VipWindow/GiftPage is drawn on top. Other order values: Gacha/Warp/FishIndex/inventory 8, Tutorial 9, TopMenuGamepad hint 12, GachaAnnouncer 20.
- The QuickShop dim (tap outside closes the shop) now ignores taps while VipGui.VipWindow is visible, so closing the gift window by tapping outside doesn't close the shop too. The gift window's "← กลับ"/B closes only itself (the shop's B handler needs selectionInside).
- Verified in Play: the VIP card's 🎁 opened the gift page with the shop panel still visible. Not tested on a real gamepad (B behaviour) or phone. Backups _Backup_20261001.PlantLimitGui/VipGui/SultanShopGui/AutoFeederGui_before_giftstack. Needs Publish.
- 2026-10-18 bug fix (user: overhead status sometimes hidden until toggled off/on): StarterPlayerScripts.NameTagPrefs re-evaluated rows only on Visible changes; if Title.Visible=true replicated before the owner's VipTitle attribute, it hid the row for good. Now it also listens to owner attrs IsVip/IsSultan/VipTitle/IsTyping, re-applies after 0.3 s, and re-applies all tags every 3 s. Verified by replaying the race in Play. Backup _Backup_20261018.NameTagPrefs_before_statusrace. Needs Publish.
- Test gotcha: the top-right buttons have Selectable = false, so GuiService.SelectedObject + Return did nothing / hit a stale selection. Set Selectable = true on the button first (runtime only).

2026-10-21: user report "status not shown after switching device / new login until I press Save" → join-time TextService filter failures (Studio never filters, so invisible there). VipService.publish now schedules background retries (3,5,10,20,30,60,120 s) when filtering returns nil (`scheduleRetry`, st.retrying). Verified with a harness (real publish code + fake TextService failing 3×). Not live-tested; not published.


---

## voice-indicator

User asked for a mic icon above the head while someone speaks, I built `StarterPlayerScripts.VoiceIndicator` (AudioDeviceInput → AudioAnalyzer PeakLevel, green 🎤 bubble in the PlayerNameTag), then the same day: "ตอนพูดไม่ต้องขึ้นแล้ว ฉันลืมไประบบมีให้อยู่แล้ว" — Roblox's built-in voice chat already shows its own indicator, so the script was deleted.

- Source kept in ServerStorage as StringValue `_Backup_20261003.VoiceIndicator_removed` (can be restored if ever wanted; ~6 KB).
- Lesson: for voice/chat/emote-wheel type features check whether Roblox already provides it before building.


---

## warp-menu

User request 2026-10-02: "ทำวาปไปยังสถานที่ตกปลา ร้านค้า ร้านตกปลา และทุกแหล่ง เช่น ลำธาร ทะเล".

Files:
- ReplicatedStorage.WarpConfig: COOLDOWN 4 s, Categories shop / fish, Destinations {Id, Cat, Zone?, Icon, Name, Desc, Pos, Look}.
- ServerScriptService.WarpService (Script): RemoteEvent RemoteEvents.WarpRequest (id string). Checks id, alive, attr GachaBusy, cooldown; Sit = false; raycasts down from Pos + 40 (excluding characters; water → fallback to the config Y) and lifts by HipHeight + HRP/2 + 0.2; PivotTo(lookAt). Feedback via HarvestNotify custom messages ("🧭 วาปไป X แล้ว").
- StarterPlayerScripts.WarpGui (LocalScript): 🧭 button in TopbarRow (LayoutOrder 2, after the music button), window 400x470 with a scroll list, 🏡/🛒 and 🎣 sections, "ไป" buttons; fishing rows show the zone and the best fish from FishingConfig. Gamepad: SelectionGroup, first "ไป" selected on open, B closes, gold selection box. TopMenuGamepad picks the button up automatically (it collects TopbarRowGui.Row buttons).

Destinations: farm (-94,39), shop (-126,40), fishshop (-399,12 facing -X, next to the stall), gacha (-98.8,43), petfood (-110.8,52.9); fishing: lake dock (-392,-27 on the deck), canal (-150,-23), stream (360,-191), mistlake (470,-135; zone lake), sea (west beach -421,70 facing -X).
- Fishing spots were computed from the real water: from a water point walk back along the facing direction to the first land, then 2-5 studs further, so the water is ~3 studs ahead.

Verified in Play: all 10 warps land on the ground; every fishing spot has water within the Bamboo cast range (14 studs); the pets (3) arrived within 6 studs even after a ~900 stud warp; with the rod held and auto on, the bobber was cast at the new spot (mistlake → "🛶 ทะเลสาบ" hint). Studio test put the user's position back at -427.8, 9, -6.1. CORRECTION: the auto-fishing test DID catch 2 fish (Catfish ★3, SilverBarb ★5, lake, auto) before I unequipped; I stopped Play, started it again and removed those 2 items (each was a new stack of 1). FishIndex counts +1 each (no new species, no new record) were left. LESSON: when testing auto-cast, unequip the rod within ~3 s of the cast (the bite can come in 6-10 s), and check the Fishing log lines BEFORE stopping Play.
- Not tested on a phone or a real gamepad. Needs Publish.
- To add a spot: append to WarpConfig.Destinations (Pos/Look; for fishing add Zone), the list and server pick it up. Re-check spots after any shoreline terrain change.

2026-10-02 later: the "จุดเริ่มต้นฟาร์ม" (farm / spawn) destination was REMOVED at the user's request ("ไม่เอาจุดเกิด"). 9 spots remain: shop, fishshop, gacha, petfood, lake, canal, stream, mistlake, sea. Only the WarpConfig entry was removed (the list and the server read it). Backup _Backup_20261001.WarpConfig_before_nofarm. Needs Publish. The Studio id changed again (8e91c8ca-512d-4758-8362-6f7f5b06fb65).

2026-10-03 (user: "ลบตู้สุ่มสัตว์เลี้ยง เครื่องทำอาหารสัตว์ และท่าเรือทะเลสาบ"): removed the gacha, petfood and lake-dock entries from WarpConfig → 6 spots: shop, fishshop, canal, stream, mistlake (zone lake), sea. Old values in ServerStorage `_Backup_20261003.WarpConfig_before_trim`. The PetHelperToggleButton empty-pets hint no longer says to warp to the machine: "สุ่มได้ที่ตู้สุ่มสัตว์เลี้ยง ข้างร้านค้า (กด ☰ → วาปไปจุดต่างๆ → ร้านค้า)" (backup `_Backup_20261003.PetHelperToggleButton_before_warphint`). Don't re-add those 3 spots. Needs Publish.

"เมนูเพิ่มเติม" (More menu) 2026-10-02 (user: one menu icon; move music/volume, warp, fish book and VIP status into it):
- StarterPlayerScripts.MoreMenuGui (new LocalScript): a round "☰" button (3 bars drawn with Frames) in TopbarRow (LayoutOrder 1, left top) opens a dropdown panel parented to TopbarRowGui (same coordinate space as the row, placed under the button) with 4 entries: 🎵 เพลงและเสียง, 🧭 วาปไปจุดต่างๆ, 📖 สมุดสะสมปลา, 👑 ตั้งสถานะ. A transparent full-screen catcher (ScreenGui MoreMenuDim, DisplayOrder 4) closes it on an outside tap; B closes on a gamepad; the first entry is selected on open with a gamepad (TopMenuGamepad picks the button up automatically).
- Each entry fires a BindableEvent in the target script's ScreenGui: MusicPlayerGui.OpenMusic (BackgroundMusic: toggles the music panel), WarpGui.OpenWarp, FishIndexGui.OpenFishIndex (toggles), VipGui.OpenVip (opens only if closed).
- The old buttons are hidden with Visible = false (MusicButton, WarpButton in the left row; OpenFishIndexButton and OpenVipButton at the top right), not deleted: their windows are unchanged. This SUPERSEDES the earlier "VIP button is the crown again" for visibility: the 👑 survives only as the menu entry icon. TopMenuGamepad skips invisible buttons.
- The red dot for new fish moved: FishIndexGui sets attribute HasNew on its ScreenGui; MoreMenuGui shows the dot on the ☰ button and on the 📖 entry.
- Right-hand row now keeps donation, pets, bag, shop (positions unchanged, so there is a gap where the fish book / VIP buttons were).
- Verified in Play: all 4 old buttons hidden, the 4 events exist, the panel opens under the button, and each entry opens its window and closes the menu (warp window, music panel, fish index, VIP window). Not tested on a phone or a real gamepad.
- Backups _Backup_20261001.BackgroundMusic /WarpGui/FishIndexGui/VipGui_before_moremenu (MoreMenuGui is new). Needs Publish. To restore a button: set its Visible back to true in its script.

2026-10-03 (user phone screenshot: ☰ menu cut off at the bottom, "ขยายความกว้าง ปรับเป็น 2 คอลัมน์"): MoreMenuGui panel now uses a UIGridLayout ("EntryGrid", cell 238x46, padding 4). applyColumns() (called in openMenu): ViewportSize.Y < 560 (phone landscape / short screens) → 2 columns, cell width = clamp((topGui width − 16 − 12 − 4)/2, 150, 205), height 42, label text 14 with AtEnd truncation, panel width = 2 cells + gap + padding; otherwise 1 column as before. On a 997x460 test viewport all 7 entries fit in 4 rows. Studio hooks: player attr DevTwoCol (force 2 columns) and DevOpenMoreMenu (open the menu; clicks through the test tool don't reach it on the emulated phone). Backup _Backup_20261003.MoreMenuGui_before_2col. Needs Publish; not tried on a real phone/gamepad (gamepad selection should follow the grid).

2026-10-03 later (user: "ปรับ ui ของวาปไปจุดต่างๆ เหลือแค่วาป ..."): window title "🧭 วาป" and the ☰ menu entry "วาป" (pet-menu hint text also says วาป). Fishing rows show only icon + short name (no fish list, no zone suffix, no desc; row height 52; shop rows keep their desc, height 64). Names: คลอง (Pos 30,8,-132 facing −X = west edge of FarmPlot15, canal water 4 studs ahead, surface y ≈ 0), ลำธาร (Pos 190,14,128 facing +Z = in front of the terrace stream channel z 136–144; the ground there is a FarmPlot22 Soil, stream surface y ≈ 16, ~8 studs ahead; zone "stream"), ทะเลสาบ (mistlake, unchanged spot), ทะเล (unchanged). The old stream spot (360,−191) is gone. 6 entries total. Verified in Play: all four land on ground with water ahead. Backups _Backup_20261003.WarpConfig/WarpGui/MoreMenuGui/PetHelperToggleButton_before_simple/_warpname. Needs Publish.

2026-10-12 (user screenshot, "ปรับให้วาปทะเลมายังตำแหน่งนี้"): sea warp moved from (-421, 8, 70, facing -X) to (-401.7, 7, 329.6, Look -0.82, 0, 0.57) — SW beach, water 2 studs ahead. Verified in Play (lands on sand). Needs Publish. Note: a 2-player Studio test session cannot be stopped or reached (Server datamodel) through the MCP tools — ask the user to press Stop.

2026-10-12: the user MOVED the fishing shop themselves to the beach in front of `workspace.BoxingRing` (stall at 141, -490, front faces -X; otters x ~134.6 z -497/-482, RodShowcase x 140, OtterCraftBench at 137, -519; sand y 2). They reported "ร้านตกปลา วาปมาจุดนี้ อยู่หน้าเวทีมวย" → `fishshop` warp now (123, 3, -490) facing +X (was -399, 6, 12). Not warp-tested in Play. Older notes placing the fishing shop at (-425, 2) are stale; the Halloween `FishingArea` decor is still laid out around the OLD position (not moved, user not yet asked).


---

## weather

Built 2026-09-28 (user: "อยากให้มีสภาพอากาศฝนตกเพิ่ม").

Config: ReplicatedStorage.WeatherConfig
- CLEAR_MINUTES {20, 40}, RAIN_MINUTES {3, 5}.
- RAIN_GROW_MULT 0.8 (crops +25%), RAIN_BITE_MULT 0.83 (fish +20%).
- IsRaining() reads workspace attr Weather.

Server: ServerScriptService.WeatherService
- Sets workspace attrs Weather ("Clear"/"Rain") and WeatherEndsAt (unix).
- Announces rain start/stop via HarvestNotify:FireAllClients.
- Studio-only test switch: workspace attr DevRain = true/false.

Hooks:
- PlantingSystem.growPlant multiplies each stage wait when raining.
- FishingSystem scheduleBite multiplies bite time, and the otter helper's bite time too.
- AmbientSounds fades the birds to 0 while raining.

Client: StarterPlayerScripts.WeatherClient
- Rain drops: 380 anchored thin Parts (0.08 x 2.6, light blue, transparency 0.3, slight tilt) in workspace.RainDrops, moved every frame with BulkMoveTo in a 38-stud radius around the camera. The number of active drops = count x level.
- Dim sky: a local ColorCorrection "RainTint" plus Terrain Clouds cover/density/color lerp (client-only).
- Sounds: rain loop rbxassetid://1516791621 (Roblox). Thunder 139319051979882 / 136909414800877 with a LightningFlash ColorCorrection every 25-55 s.
- Everything fades over 4 s.
- Pill "🌧️ ฝนตก · พืชโต +25% · ปลากิน +20% · m:ss" in WeatherGui at (0,12,0,64).

Gotchas:
- ParticleEmitter rain failed here: Squash/orientation combos gave horizontal or invisible streaks depending on camera, and a decal id used as Texture fails to load (ContentProvider Failure). Use thin parts + BulkMoveTo.
- The DayCycle script tweens Atmosphere/Bloom/ColorCorrection server-side, so weather tint uses its own client ColorCorrection; the Atmosphere is not touched.
- Fog is ignored while an Atmosphere exists.
- Audio from other creators all loaded (tested IsLoaded / TimeLength).
- 2026-10-01: the rain pill (WeatherClient "RainPill", top-left) is now transparent at the user's request: no background, border or padding. White text with a dark-blue TextStroke, size 14. Backup WeatherClient_before_clearpill.


---

## wishing-pond

User 2026-10-18 (pointed at the lotus lake + LakeDock pier): throw produce into the water, after 8 a fairy rises and grants a wish; wishes for now = พรวันเกิด, งานสร้างสรรค์. User said "ไปก่อน" and left me to decide details.

My choices (tell the user, they may change them): wishes are cosmetic only (5-min sparkle aura + chat announce + effects), no coins/items; counter is per server session (attr WishThrows, not saved); 1 produce per prompt press, held produce first else lowest-star stack, Starred stacks never thrown (see [[star-lock]]).

Pieces: ReplicatedStorage.WishingPondConfig (positions, THROWS_NEEDED, Wishes list — add new wishes here), ServerScriptService.WishingPond (prompt part workspace.WishingPondPrompt created at runtime), StarterPlayerScripts.WishingPondGui, ReplicatedStorage.WishingFairy (AI mesh, face = model -Z), RemoteEvents.WishingPondEvent. Sounds use EffectSounds ([[sound-groups]]).

Birthday party (user asked same day): Birthday wish also rains 18 decorative gift boxes around the player, plays APM "Happy Birthday Party (d)" rbxassetid://9043577511 (~27 s) and shows a rainbow "Happy Birthday <name>!" banner; gifts pop when the song ends. Water-gift-never-pops bug fixed and verified in Play.

Wish for a friend (same day): after picking a wish card, page 2 lists "ตัวเอง" + everyone in the server (Roblox friends first, 💛); FireServer("wish", id, targetUserId); aura/party/banner go to the target, target gets a 💝 notice. Tested solo only — NOT tested with 2 real players.

Tested in Play once (8 throws → fairy → window → Birthday aura). Not yet seen: the new fairy position/scale in Play, the fairy speech bubble (didn't show in the test screenshot), Creative wish, mobile, gamepad. Not published.

2026-10-19: user asked to keep ONLY the Birthday wish → Creative entry commented out in WishingPondConfig.Wishes (restore by uncommenting). Not published.


---

## witch-berry-crop

User chose 1 of my 3 proposed Halloween crops (2026-10-14): WitchBerry. Candy Corn / Ghost Mushroom / white-pumpkin rare drop were declined for now.

- 2026-10-17 (user): level lowered 30 → 5 so new players can join the event; shop card shows "🎃 พืชกิจกรรม ·" (ShopSystem buy data has `Event = entry.Season ~= nil`, ShopGui prefixes infoText). Not published.
- Values: level 30 (now 5), seed 32, BASE_PRICE 16, 80 s grow (20/stage), icon 🫐, colour (160,100,215). Seed price = 2x base like other crops.
- Seasonal gating: ShopSystem SHOP_ITEMS entry has `Season = "Halloween2026"`; `seasonOpen()` hides it from the buy list and rejects BuySeed when `SeasonConfig.IsActive` is false. Produce sells forever; seeds already owned still plant. Studio forces the season via ReplicatedStorage attribute `DevForceSeason` (currently "Halloween2026,GhostGacha2026").
- Model: CropTemplates.WitchBerry (Model), one AI MeshPart per stage, base-centre at the model pivot; HeldFruit is at real held size (HELD_SCALE 1).
- Adding any new crop means editing these lists (no central config yet; I offered to centralise): PlantingSystem (SEED_PRICE, STAGE_DURATION_BY_CROP, CROP_STAT_NAME), LeaderstatsSetup CROPS, ShopSystem (CROP_MIN_LEVEL, SHOP_ITEMS, CROPS, BASE_PRICE), ItemFactory (CROP_COLOR, CROP_ICON, HELD_SCALE), Localization Crop_<id> th/en, client icon tables in ShopGui (+grow time), HarvestNotifyGui, CustomHotbar, FullInventoryGui (+CROP_ORDER), PetFoodGui, FishingShopGui.
- Tested in Play 2026-10-14 (buy gate, plant, grow, auto-harvest). Not tested: shop/bag UI by eye, pets planting it. Not published.
- Related: [[seasonal-events]], [[pumpkin-vine]].


---

## zukzon-dog-pet

User 2026-10-22 sent photos of their real dog + a "Zukzone บันทึกสุขภาพ" logo; wanted pet "ซุกซน", tier "ลึกลับ", only the creator has it or gives it away. Photo 3's brown long-haired chihuahua is a different dog, not built.

Built 2026-10-22 (Studio only):
- `PetRarity.Mythic` "ลึกลับ" Order 6. `PetDefinitions.Zukzon`: NotInGacha, `HiddenUnlessOwned` (filtered in PetManager.buildPetList + GachaService pets list), Abilities {} and Luck = 0 — Harvester, TreasureDigger and Lucky all removed by user 2026-10-23 (only the hug button left).
- Template `PetTemplates.Zukzon`: AI mesh (generate_mesh explicit 7 parts, option 2), turned to face +Z, ScaleTo 1.25; motors Neck/Left|Right Shoulder (front legs)/Left|Right Hip/Tail/RootJoint; ears are in the head mesh (no ear motors). Patches = sphere-mesh parts welded to Torso (raycast onto torso surface) in model `Patches`. Model attr `AnimGait = "Trot"` → PetAnimator diagonal trot + faster wag. Drafts in `ServerStorage.ZukzonOptions` (DogOpt1 plain white face, DogOpt2 cream eye patches = chosen).
- 2026-10-22 later: user disliked the AI model → rebuilt in Blender by script (ellipsoid unions + voxel remesh, colour shells for patches), file `assets/zukzon/Zukzon.fbx/.blend`; user imported it (Studio MCP cannot import files — ask the user to use Import 3D). Template now = Blender model (19 MeshParts colored in Studio, ear motors). Old AI template = `ZukzonOptions.AI_Template_old`.
- Later 2026-10-22 tweaks on the template: chubbier torso (1.25/1.14/1.06), ears and tail x0.8, patches redone from the user's top-view photo (withers + rear heart + tail base; `ZukzonPatches.fbx`). Sleep: def `SleepAfter = 25` → PetController stops wander + attr `Sleeping`; PetAnimator curl pose when model attr `SleepPose = "Curl"` (+ 💤). Blender MCP may disconnect — headless `blender.exe -b file.blend --python script.py` works (renders need Cycles CPU; workbench crashes).
- Hug is now a TOGGLE (user 2026-10-22: hold until put down): player attr `ZukzonHolding`, pet attr `HeldByOwner` (PetController skips work), auto put-down on death/seat/carry/pet removed; buff granted on pick-up only if expired. Tested in Play. 2026-10-23: hold survives AFK rejoin/respawn — DataStore ZukzonHold_v1 ("studio:" prefix in Studio), cleared only by the put-down button or putting the pet away; a 1.5 s loop silently re-picks (no buff, no toast).
- Sleep now swaps to a separate Blender curled model `PetTemplates.Zukzon.SleepModel` (parts attr `SleepPart`, Transparency 1, welded to HRP); PetAnimator hides normal parts via LocalTransparencyModifier when the lie-down blend finishes. Blender script `scratchpad/zk_sleep.py` built it (collection ZukzonSleep in Zukzon.blend).
- `Abilities.TreasureDigger`: 180 s → 120 s at Lv15; loot coins/petfood/bait/x50/Normal ticket (no seeds: no seed-give API). Dig fx via extras.onWork. Seen working in Play.
- User choice: other players can NOT pat; instead OWNER "🤗 กอด" button: `ZukzonService` + `ZukzonHugClient`, held copy welded to UpperTorso facing outward, attr `ZukzonHugEnd` (scene) / `HugLuckUntil` (+10% via `LuckConfig.HUG_LUCK_MULT` in Combine, 5 min, no re-hug while active). Buff verified in Play.
- Owners auto-granted on join (9360333174 + CreatorId). `/give <name> zukzon` (or `pet zukzon`) in AdminGive → GrantPremium (new = announce all servers via ServerStorage.ZukzonAnnounce → GachaAnnounce Kind "Gift"; owned = +1 level). Command not tested.
- During the test the user brought Zukzon out themself in Studio (fake key DevPetKeyOverride, since cleared) — their real PetSettings_v1 may list Zukzon as active.

**How to apply:** look/patch tweaks go on the template + `Patches`; hug pose = `HOLD_OFFSET` in ZukzonService and `HUG_POSE` in the client. Related: [[admin-give]], [[carry-system]], [[dev-pet-key-override-gotcha]], [[scarecrow-ghost-pet]].

## donation-announce

Built 2026-10-24 (Studio only, not published). It reuses the existing donation window and its 7 Developer Products (DonationConfig); there are no new products.
- `ReplicatedStorage.DonationAnnounceConfig`: Enabled, MAX_LENGTH 80, SHOW_TIME 12, COOLDOWN 60, PENDING_TIME 300, TOPIC "DonationAnnounce_v1", `HasLink` (lowercased, spaces removed; http/www/.com/.gg/.co/.th…, discord/youtu/tiktok, ดอทคอม/จุดคอม, plus any `%w.%a%a`), `Clean`, `Length` (utf8).
- `ServerScriptService.DonationAnnounce` (ModuleScript, required by PlantingSystem next to DonorRecords): RemoteFunction `DonationAnnounceRequest` actions check(text, productId) / clear / status.
  - check: length, link, cooldown, `TextChatService:CanUserChatAsync`, filter (GetNonChatStringForBroadcastAsync), reject if more than half is `#`. On success it stores pending[userId] = {text, productId}.
  - `OnDonated(receiptInfo, donor, spent)` is called from the donation grant only when DonorRecords says the receipt is new. It announces only if the pending productId matches.
  - Fires RemoteEvent `DonationAnnounce` to all + MessagingService (own server skipped by JobId).
  - Log: DataStore DonationAnnounce_v1 key `log` (last 200) and `settings` {off}. Studio keys are prefixed `studio:`.
  - Owner commands /announceoff /announceon /clearannounce (cross-server).
  - Pending messages and cooldowns are per server, in memory.
- `StarterPlayerScripts.DonationAnnounceGui`: banner with a dark purple box and a rotating gold-pink UIStroke gradient. The user asked for it to stand out (2026-10-24), so it is the one exception to the no-background notification rule. Width fits the text (340–620). It also has a queue, chat system message; {Clear=true} hides it. Position (2026-10-24, user asked it to fit the restart notice): DeviceSafeInsets like RestartNoticeGui, y 59 = the restart panel's line, under the centre music button; while `RestartEndsAt` is set it moves to y 107 under the restart card (and re-tweens if that attribute changes while showing). The donate button icon is 📢 (TextLabel `Icon`), not the Robux icon.
- Top-centre overlap fix (2026-10-24): the banner shares the top centre with HarvestNotifyGui's SoftStack (y 20, CoreUI insets) and DonationGui's thanks toast (y 72). DonationAnnounceGui sets client-side player attributes `TopBannerBottom` (banner bottom in AbsolutePosition px, 0 = none) and `TopBannerUserId`; SoftStack and the thanks toast move to `bottom - theirGui.AbsolutePosition.Y + 6` while it shows. The header reads "💖 ขอบคุณ <name> ที่สนับสนุน X R$", and the donor's own thanks toast is skipped while their banner shows (DonationGui waits 0.6 s, because the server sends thanks before the announcement). Any new top-centre notice should follow `TopBannerBottom` too.
- `DonationGui`: an amount button opens `AnnouncePopup` (Header, MessageBox, Buttons.AnnounceButton / Buttons.DonateOnlyButton). "Donate only" calls clear first, so an old pending message is not used.
- Studio test: `ServerStorage.DonationAnnounceTest:Fire(player, amount)` fakes a receipt for the pending message (firing it from execute_luau on the Server works). The Studio purchase prompt blocks clicks on the game UI until it is closed. Backups `_Backup_20261024.*_before_donateannounce`.
- Tested in Play: popup, link block, check → prompt, banner, cooldown. Not tested: real purchase, cross-server, phone, gamepad, admin commands, the filter in the live game.


## voice-check

Report 2026-10-27: new players "open the mic but friends can't hear". Inspection: VoiceChatService EnableDefaultVoice=true, UseAudioApi=Enabled, DefaultDistanceAttenuation=Legacy (silent beyond 80 studs); in Play Roblox creates Player.AudioDeviceInput, character AudioEmitter, Camera AudioListener, SoundService.AudioDeviceOutput; no game script touches voice. Likely causes: >80 studs apart, different servers, Roblox voice eligibility / OS mic permission.

Built (Studio only, not published, not play-tested):
- `StarterPlayerScripts.VoiceHint` (IsNewPlayer only): reports state, wires own AudioDeviceInput → AudioAnalyzer; card "hint" when still muted after 45 s; card "far" after 3 s of speech with nobody within 80 studs (kinds alone / friend / none). Once each per session, same look as SlowDeviceHint, waits while that card is up. Studio: `workspace.DevVoiceCheck` = true / "hint" / "far".
- `ServerScriptService.VoiceCheckReport` → player attr `VoiceCheckLog` (max 16 events; server measures near/in/n itself) → `DisconnectLogger` stores it in `entry.health.voice` on leave (no extra DataStore writes).

**How to apply:** to diagnose, read `health.voice` of new players in DisconnectLogs_v1: en=0 = no Roblox voice for that account; dev=0 / nodev = no mic device; mute stays 1 = never unmuted; silent = unmuted but no signal (OS mic permission / broken mic); talk near>80 or far k=alone = distance / different server. Related: [[custom-matchmaking]], [[voice-indicator]].

## beach-piano

2026-10-29 (user: "เพิ่มเปียโนบริเวณบาร์หรือโซนร้องเพลง ให้สามารถเล่นได้ด้วย"): playable grand piano on the beach stage, Studio only, not published.
- Model `workspace.IslandDecor.BeachStage.Piano` (part-built, Atomic, 63 parts) at the back-right of the stage (keys along X at z −374.9..−376.2, x 126.15..131.85; pianist on `PianoSeat` faces −Z; lid hinged on +X so it opens toward the audience on −X). Keys `Keys.Key_<offset>` 0..24 = C3..C5 with attrs Offset/Black. `PromptPart.PianoPrompt` (tag `PianoPrompt`), `SoundBox` = 3D sound source.
- `ReplicatedStorage.PianoConfig` (samples C2..C6 by I_AmKota, `SampleFor(note)` → nearest C + PlaybackSpeed; PC_KEYS; limits), `ServerScriptService.PianoService` (claim/release, `PianoPlayer` attr = UserId or 0, RemoteEvent `PianoNotes`: client "notes" {{note,on,dt}} / "leave"; server → FireClient(model, pos, events) to players within 140), `StarterPlayerScripts.PianoGui` (bottom keyboard panel, CAS priority 3000 sinks piano keys incl. 2/3/5/6/7 so the hotbar does not switch, ducks `BackgroundMusicDuck` to 0.25 — sets it back to 1 on close, no shared counter with WishingPondGui).
- Gotcha met while building: a shared opts table passed to a helper that sets `opts.shape` turned later boxes into cylinders — copy opts per part.
- Not tested: 2 real players, phone, real gamepad, real prompt press. Phase 2 idea (offered, not built): preset songs / falling-note mode.
- Phase 2 done 2026-10-29 (user: "Add songs"): 5 public-domain songs in `PianoConfig.SONGS` (twinkle, odetojoy, furelise, birthday, jinglebells), token format "Note/beats", "+" chord, "R" rest, multiple Tracks; `ParseSong` → sorted {t, note, on} (notes held 92% of their length). PianoGui "🎵 เพลง" button → SongPanel grid → Heartbeat autoplay through the same startNote/queue path as manual play; stop button / stand up stops it. Verified: Für Elise 53/53 notes reached the server in order; nobody has listened to the melodies by ear yet.
- Bug fixed 2026-10-29: Photo Mode (P) restores saved ScreenGui.Enabled on exit, so leaving the piano during photo mode left PianoGui stuck open; PianoGui now forces Enabled=false whenever not seated. Re-test in Play pending (Studio start-play hung).
- Keyboard v2 2026-10-29 (user sent a reference picture): 36 on-screen keys C3..B5, PC row layout q..p z../ white + 2 3 5 6 7 9 0 s d f h j l ; ' black (i = C4, red dot), keycap-style tags, red felt strip; while seated P is a note (no photo mode) and the chat key moves from / to Enter (setChatKey in PianoGui); C7 sample added; 3D model still 25 keys (setKey3D wraps). Not yet Play-tested (Studio start-play hung); camera keys i/o/,/. not checked.
- 2026-10-29 Roblox keys while seated: camera keys (i/o zoom, ,/. rotate) live inside Roblox's built-in camera (no PlayerModule in PlayerScripts) and ignore CAS sinks → PianoGui sets the camera Scriptable at a fixed over-the-shoulder view while seated. ChatInputBarConfiguration.KeyboardKeyCode cannot be changed by a script (Roblox resets it to Slash at once) → PianoGui disables the chat input bar while seated, with a 💬 toggle button; must look up ChatInputBarConfiguration lazily (missing at script start).
- 2026-10-29: note keys are read from UserInputService InputBegan/Ended (Roblox's camera grabbed i/o before ContextActionService); CAS binding now only sinks. Verified all 35 keys in Play. Studio start-play hangs about every second start via MCP (needs the user to clear it).
- 2026-10-29 real-keyboard finding: in Studio Play, i and o deliver only InputEnded (no InputBegan) — swallowed above the game (likely camera zoom keys). PianoGui now polls IsKeyDown each Heartbeat and, as a fallback, plays a 0.3 s note when a release arrives with no press. Not yet confirmed on a real keyboard whether IsKeyDown sees i/o.
- 2026-10-29: C4/D4 moved from i/o to 8/k (user's choice) because Roblox's engine camera zoom swallows i/o — confirmed with real-keyboard logging (no press signal; release only sometimes). Never map i or o in game key layouts.
- 2026-10-29 (later): user changed it to skip i/o — C4 = p, D4 = [, E4 = ]; final white row q w e r t y u p [ ] z x c v b n m , . /.
- 2026-10-29 (later): black keys C#4 = -, D#4 = = (were 9 / 0). Full map C3..A#5: q 2 w 3 e r 5 t 6 y 7 u p - [ = ] z s x d c f v b h n j m , l . ; / '.

## mountain-waterfall

2026-10-29 (user sent a photo of a wide jungle waterfall: "ปรับภูเขาให้เป็นน้ำตก" + "ลำธารกว้างขึ้นอีกนิด ซึ่งเป็นน้ำที่ไหลมาจากน้ำตก"; chose: players can walk to the pool, 4 falls, stream ~14). Studio only, not published.
- Mountain = the north grey mountain behind the terraces (peak ~240). Bowl centre B = (456, 234), opening D = (-0.826, -0.564) toward the hut; bowl radius 46, cliff ring to 58, corridor half-width 32 to along 80, flanks to 52. Floor/water top y 52 (= top of the old stream). Pool = r < 43 from B (depth 4/8/12). Hollow mountain filled with Rock below the old surface in the edited columns.
- The mountain foot was ~35 studs BELOW the stream top (valley at x 300–400), so a grass ridge was built along polyline (404,199) → (350,165) → (305,142) → (256,140), top y 52, water |d| < 8.5, flanks blend over 18–46; FarmPlot22 soils/levees protected (no edits within 1–3 studs).
- `workspace.MountainFalls`: Fall1–4 (angles -48/-18/12/40 from the back direction, widths 12/22/18/12) + Trickle1–4; each = Sheet (Transparency 0.55, Texture FlowA/FlowB with Attribute ScrollSpeed, image rbxassetid://138175470560716 made by me in Python and uploaded), Lip (LipFoam), Splash (Splash + WaterfallSound on Fall2/3), PoolMist, Greenery (51 clones of HikingMap JungleTree/TreeFern/BigLeafPlant/Fern). Creator Store decals did NOT render (decal asset id ≠ image id) — use uploaded images.
- `StarterPlayerScripts.MountainFallsFx` scrolls the textures (FxThrottle). Scroll direction NOT verified in Play (flip the sign if the water runs upward).
- Stream widened: water copied from z 136/140 cells to 132/144 (now z 132–148), beds' levees touch the water edge by ~2 studs. Cascade parts Z 7.4 → 15.4, their emitter rates x1.8.
- PlayArea Points: { 320, 250 }, { 372, 240 }, { 425, 234 }, { 446, 205 }, { 448, 160 }, { 470, 100 } (was { 370, 200 }, { 420, 150 }); walls rebuilt. Players reach the south/front half of the pool.
- Backup `ServerStorage._Backup_20261029_Waterfall`: TerrainBefore (x 120–560, y -12–272, z 60–340; restore `Terrain:PasteRegion(f.TerrainBefore, Vector3int16.new(CornerX, CornerY, CornerZ), true)`), StreamBefore, PlayAreaWallsBefore, PlayAreaModuleBefore, MovedItems (9 HikingMap plants, Attribute OriginalParent). Moved-up/down plants carry Attribute WaterfallMovedY.
- Not done: Play test (Studio start-play hung), FPS on mobile, sound check, a warp spot / sign (none added).
