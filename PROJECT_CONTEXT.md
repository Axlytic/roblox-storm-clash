# 🌪️ PROJECT DOSSIER: STORM CLASH (Hybrid Anime Combat Engine)
*Dokumen Pemisahan Proyek & Rangkuman Konteks Menyeluruh dari Percakapan Sebelumnya*

---

## 📌 1. Pemisahan Proyek (Project Separation)

* **Proyek Sebelumnya (Telah Selesai & Ditutup)**:
  * **Nama**: *Roblox Dilemma Royale* (`d:\VIBE CODE\roblox-dilemma-royale`)
  * **Genre**: Social Deduction, Voting System, Prisoner's Dilemma Battle Royale.
  * **Status**: Ditutup secara resmi pada *Step 422* di percakapan sebelumnya setelah seluruh sistem dan perbaikan bug berhasil diselesaikan.
* **Proyek Baru Saat Ini (Fokus Aktif)**:
  * **Nama**: **STORM CLASH** (`d:\VIBE CODE\Combat`)
  * **Genre**: 3D Fast-Paced Anime Fighting Arena / Battlegrounds.
  * **Karakteristik**: Menggabungkan 3 pilar game pertarungan legendaris:
    1. **Naruto Shippuden: Ultimate Ninja Storm 4 / Connections**: 3D Lock-on orbital camera, Homing Ninja Dash, Shinobi Run Blending (28° Torso lean, -65° Arms sweep), Shuriken/Jutsu jarak jauh, Chakra Charge & Cinematic Ultimate Secret Technique (Ougi), Assist Striker, Leader Swap.
    2. **Tekken**: Technical Stance Defense (High Guard vs Low Guard), 3D Sidestep Evasion, Guard Health Meter with Guard Crush Stun, 180ms Just-Frame Parry Counter, Tekken Rage Mode (saat HP < 30%).
    3. **Jump Force MUGEN 14 & Anime Mega-Roster**: 24 Playable Anime Legends across major Shonen Jump and anime franchises with complete procedural 3D visual morphs, custom projectiles, and dedicated movesets.

---

## 🎮 2. Skema Kontrol Terkini (Otentik Naruto Storm 4 + Tekken + Mobile + Gamepad)

### 💻 Keyboard PC, Gamepad (PlayStation / Xbox) & Mobile
| Tombol Keyboard | Gamepad | Mobile Touch | Aksi Mekanik Storm 4 | Deskripsi & Interaksi Game Feel |
| :---: | :---: | :---: | :--- | :--- |
| **`E` / `Q`** | **`L2` / `LT`** | **`[🪵 SUB]`** | **Substitution Jutsu (Kawarimi)** | Menghilang dalam asap, meninggalkan balok kayu 3D, dan teleportasi 8 stud di **belakang musuh**! Menggunakan 1 dari 4 stok substitusi. |
| **`J`** | **`Square` / `X`** | **`[⚔️ PUNCH]`** | **Neutral Combo (4-Hit)** | Rangkaian pukulan cepat beruntun yang diakhiri hantaman *Wall Splat / Heavy Knockdown*. |
| **`W + J`** | **`Up + Square`** | **`[⚔️ PUNCH]` (Maju)** | **Up Combo (Air Launcher)** | Pukulan uppercut beruntun yang melontarkan musuh ke udara (LiftY = +38) untuk serangan *Air Chase*. |
| **`S + J` / `K`** | **`Down + Square`** | **`[⚡ LOW]`** | **Down Combo (Ground Bounce)** | Sapuan bawah dan tebasan ke tanah yang membanting musuh hingga memantul (*Rebound Bounce*). |
| **Air + `J`** | **Air + `Square`** | **`[⚔️ PUNCH]` (Udara)** | **Air Combo (Dive Spike)** | Rangkaian 3 serangan udara berkecepatan tinggi yang diakhiri *Dive Spike* ke tanah. |
| **`F + J`** | **`R2 + Square`** | **`[🛡️]+[⚔️]`** | **Storm 4 Counter Attack** | Mengambil kuda-kuda *counter stance* (0.35s). Memantulkan musuh yang menyerang hingga terpental 55 stud + stun 1.3s! |
| **`I` (Tap)** | **`Triangle` / `Y`** | **`[🔥 CHAKRA]` (Tap)** | **Chakra Load** | Masuk ke mode *Chakra Loaded* (aura bola biru berkilau). Membuka akses Ninjutsu dan Chakra Dash. |
| **`I` (Tap) + `J`** | **`Triangle + Square`** | **`[🔥] + [⚔️]`** | **Character Ninjutsu** | Melepaskan jurus ikonik karakter berkecepatan 90-110 studs/s. |
| **`I` (Tap) + `Shift`** | **`Triangle + X`** | **`[🔥] + [💨]`** | **Chakra Dash (CDC)** | Melesat 112 studs/s membelah proyektil. Membatalkan *attack recovery* (Chakra Dash Cancel) untuk kombo tak terbatas! |
| **`I` (Hold $\ge 0.6$s)** | **`Hold Triangle`** | **`[🔥 CHAKRA]` (Hold)** | **Ultimate Secret Technique** | Mengisi Chakra hingga 100%, lalu meluncurkan *Cinematic Finisher 52 DMG* dengan Letterbox 21:9 & dynamic camera. |
| **`L`** | **`Square` / `B`** | **`[🌀 RANGED]`** | **Shuriken / Jutsu Jarak Jauh** | Melempar proyektil khas (Rasen-Shuriken, Bola Api, Tinju Karet, Tebasan Phoenix, Petir, Ki Blast). |
| **`F` (Hold)** | **`R1` / `R2`** | **`[🛡️ GUARD]` (Hold)** | **High Guard Defense** | Menahan serangan depan (Reduksi 80% damage). Guard Bar berkurang saat diserang. |
| **`S + F`** | **`Down + R1`** | **`[🛡️ GUARD]` (Nunduk)**| **Low Guard Defense** | Menangkis sapuan bawah musuh. |
| **`Shift` / `Spasi x2`**| **`Circle` / `B`** | **`[💨 DASH]`** | **Homing Ninja Dash** | Meluncur cepat (85 studs/s) mengunci dan mengejar musuh. |
| **`Double-tap A/D`** | **`DPad L/R x2`** | **Swipe Layar** | **3D Sidestep Evasion** | Menghindar menyamping cepat dengan jejak siluet cyan khas Tekken. |
| **`T`** | **`L1` / `LB`** | **`[⚡ ASSIST]`** | **Support Assist Striker** | Memanggil rekan tim untuk melepaskan tembakan bantuan dari samping. |
| **`U` / `G`** | **`L2` / `LT` (Lobi)**| **`[🔄 SWAP]`** | **Leader Swap** | Bertukar posisi menjadi karakter utama di tengah-tengah pertarungan. |
| **`B`** | **`Select / Touchpad`** | **`[👥 ROSTER]`** | **Character Selection Modal** | Membuka UI Roster interaktif dengan 24 karakter, stats live preview, dan tech showcase. |

---

## 👥 3. Roster 24 Karakter Anime Otentik (`CombatConfig.luau` & `StormCharacterMorphServer.luau`)

| # | Karakter | Seri Anime | Archetype | Senjata / Gaya | Ranged Skill [L] | Ninjutsu [I+J] | Ultimate Technique |
| :---: | :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| **1** | **Naruto Uzumaki** | Naruto Shippuden | Rushdown | Taijutsu & Clones | Rasen-Shuriken (Disc) | Rasengan | Rasenshuriken Blast |
| **2** | **Sasuke Uchiha** | Naruto Shippuden | Zoner | Kusanagi & Sharingan | Fireball Goukakyuu (Ball) | Chidori (1000 Birds) | Kirin Lightning Strike |
| **3** | **Kakashi Hatake** | Naruto Shippuden | Balanced | Copy Ninja / Raikiri | Lightning Hound (Bolt) | Lightning Blade | Kamui Raikiri Slash |
| **4** | **Madara Uchiha** | Naruto Shippuden | Zoner | Gunbai & Susanoo | Majestic Destroyer (Ball) | Susanoo Ribcage | Tengai Shinsei Dual Meteors |
| **5** | **Monkey D. Luffy** | One Piece | Grappler | Gomu-Gomu & Haki | Gum-Gum Pistol (Fist) | Gum-Gum Red Hawk | Gear 4th: King Kong Gun |
| **6** | **Roronoa Zoro** | One Piece | Sword | Santoryu (3 Katanas) | 36 Pound Phoenix (Slash) | Oni Giri Demon Slash | Billion-Fold Trichiliocosm |
| **7** | **Vinsmoke Sanji** | One Piece | Rushdown | Black Leg Style | Diable Jambe Poêle (Ball) | Flambage Shot | Ifrit Jambe: Bœuf Burst |
| **8** | **Trafalgar Law** | One Piece | Trickster | Kikoku Nodachi & ROOM| Takt Debris Launch (Slash)| Shock Wille Internal | Puncture Wille Heart Destroyer |
| **9** | **Son Goku** | Dragon Ball | Balanced | Turtle Hermit Kung Fu| Ki Blast Volley (Ball) | Super Kamehameha | Dragon Fist Explosion |
| **10** | **Vegeta** | Dragon Ball | Rushdown | Royal Saiyan Combat | Big Bang Attack (Ball) | Galick Gun | Final Flash Explosion |
| **11** | **Future Trunks** | Dragon Ball | Sword | Shining Broadsword | Burning Attack (Ball) | Shining Slash Rush | Heat Dome Attack |
| **12** | **Ichigo Kurosaki**| Bleach | Rushdown | Zangetsu Cleaver | Getsuga Tensho (Slash) | Black Getsuga | Mugetsu: Final Getsuga |
| **13** | **Sosuke Aizen** | Bleach | Trickster | Kyoka Suigetsu | Kurohitsugi Coffin (Slash)| Shunpo Flash Thrust | Hogyoku Fragor |
| **14** | **Byakuya Kuchiki**| Bleach | Sword | Senbonzakura Blades | Senbonzakura Shikan (Slash)| Utsusemi Flash Step | Senbonzakura Gokei |
| **15** | **Ryomen Sukuna** | Jujutsu Kaisen | Rushdown | Malevolent Cleaves | Dismantle Air Slash (Slash)| Cleave (Hachigire) | Malevolent Shrine Fuga |
| **16** | **Satoru Gojo** | Jujutsu Kaisen | Zoner | Limitless Infinity | Cursed Technique: Blue | Cursed Technique: Red| Hollow Technique: Purple |
| **17** | **Yuji Itadori** | Jujutsu Kaisen | Rushdown | Divergent Fist | Cursed Shockwave (Ball) | Black Flash (Kokusen) | Consecutive Black Flash |
| **18** | **Megumi Fushiguro**| Jujutsu Kaisen | Trickster| Ten Shadows Divine Dog| Nue Lightning Volley (Bolt)| Totality Claws | Chimera Shadow Garden |
| **19** | **Killua Zoldyck** | Hunter x Hunter | Trickster | Assassin Claws & Yo-Yo| Thunderbolt Narukami (Bolt)| Godspeed Lightning | Godspeed Whirlwind |
| **20** | **Gon Freecss** | Hunter x Hunter | Grappler | Enhancer Nen Martial | Jajanken: Paper (Ball) | Jajanken: Scissors | Jajanken: Rock (Max Power) |
| **21** | **Tanjiro Kamado** | Demon Slayer | Sword | Water & Sun Breathing | 4th Form Striking Tide (Slash)| Hinokami Blue Sky | Hinokami Flame Dance (Enbu) |
| **22** | **Zenitsu Agatsuma**| Demon Slayer | Trickster| Thunder Breathing | Thunder Spark Shuriken (Bolt)| Hekireki Issen | 7th Form Flaming Thunder God |
| **23** | **Izuku Midoriya** | My Hero Academia| Rushdown| Shoot Style & OFA | Delaware Smash (Fist) | St. Louis Smash Kick | OFA 100% United States Smash|
| **24** | **Katsuki Bakugo** | My Hero Academia| Rushdown| Explosion Gauntlets | Stun Grenade (Ball) | AP Shot Piercing Blast| Howitzer Impact Detonation |

---

## 🏛️ 4. Arsitektur Folder & Modul Script (`d:\VIBE CODE\Combat`)

```
d:\VIBE CODE\Combat\
├── default.project.json                       # Konfigurasi sync Rojo
├── MasterCombatInstaller.luau                 # Installer all-in-one (350 KB)
├── batch1.luau ~ batch5.luau                  # Installer bertahap (bebas limit string Roblox)
├── installers\                                # Modul script installer satuan (19 files)
│   ├── CombatConfig.luau                      # Shared config 24 karakter
│   ├── CombatServerMaster.luau                # Server hitboxes, projectiles, substitution
│   ├── LobbyManagerServer.luau                # 16 Mannequin amphitheater & portal
│   ├── StormCharacterMorphServer.luau         # 24 Procedural 3D Anime Morphs
│   ├── StormWeaponServer.luau                 # Katana 3D dengan slash trail
│   ├── TrainingDummySpawner.luau              # Training dummy dengan AI guard modes
│   ├── CombatComboController.luau             # 4-hit strings & air combos
│   ├── MobileCombatHUD.luau                   # Strict Landscape orientation & touch cluster
│   ├── PerformanceSettingsManager.luau        # 60FPS optimizer toggle
│   ├── StormAnimationController.luau          # Procedural dual joint engine (Motor6D + AnimationConstraint)
│   ├── StormAssistController.luau             # Assist striker & leader swap
│   ├── StormCameraController.luau             # Dynamic 3D lock-on dual target camera
│   ├── StormCharacterSelectHUD.luau           # UI roster 24 fighter scrolling list & stats dossier
│   ├── StormMatchHUD.luau                     # Healthbar ghost damage, chakra meter, sub stocks
│   ├── StormMovementController.luau           # Orbital strafe, ninja dash & sidestep
│   ├── StormRangedController.luau             # Proyektil shuriken / jutsu jarak jauh
│   ├── StormUltimateController.luau           # Charge chakra, cutscene 21:9 & Tekken rage
│   └── TekkenDefenseController.luau           # High/Low guard, guard crush, parry
```

---

## 🎨 5. Spesifikasi Prosedural 3D Morph Karakter (100% Asset-Independent)
Semua 24 model anime dirancang murni secara prosedural menggunakan `Part`, `WedgePart`, `Cylinder`, `ParticleEmitter`, dan `SurfaceGui`:
* **Bebas Error HTTP 403**: Tidak bergantung pada asset mesh ID luar yang rawan dihapus atau gagal dimuat di mobile client.
* **Performa Ringan**: Dihitung instan di server dengan `WeldConstraint` non-collidable (`Massless = true`, `CastShadow = false`).
* **Visual Otentik**: Rambut anime bersudut runcing (spiky anime cluster), aksesoris khas (ikat kepala Konoha dengan lambang spiral, topi jerami jerami Mugiwara dengan pita merah, 3 katana di pinggang Zoro, syal pirus Byakuya, penutup mata Gojo, tato Sukuna, gauntlet granat Bakugo).
